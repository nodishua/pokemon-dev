------------------------
-- Hook module, creates debug hook used by LuaCov.
-- @class module
-- @name luacov.hook
local hook = {}

----------------------------------------------------------------
--- Creates a new debug hook.
-- @param runner runner module.
-- @return debug hook function that uses runner fields and functions
-- and sets `runner.data`.
function hook.new(runner)
   local _msgpack = require '3rd.msgpack'
   _msgpack.set_string('binary')
   _msgpack.set_number('double')

   local msgpack = _msgpack.pack
   local msgunpack = _msgpack.unpack

   local lnconv
   if runner.configuration.csmode then
      lnconv = require 'net.lnconv'
   end

   local ignored_files = {}
   local steps_after_save = 0
   local ticks_after_save = os.clock()

   return function(_, line_nr, level)
      -- Do not use string metamethods within the debug hook:
      -- they may be absent if it's called from a sandboxed environment
      -- or because of carelessly implemented monkey-patching.
      level = level or 2
      if not runner.initialized then
         return
      end

      -- Get name of processed file.
      local name = debug.getinfo(level, "S").source
      -- local prefixed_name = string.match(name, "^@(.*)")
      local isfile = name:sub(#name - 3) == ".lua"
      if isfile then
         -- pass
      elseif prefixed_name then
         name = prefixed_name
      elseif not runner.configuration.codefromstrings then
         -- Ignore Lua code loaded from raw strings by default.
         return
      end

      local data = runner.data
      local file = data[name]

      if not file then
         -- New or ignored file.
         if ignored_files[name] then
            return
         elseif runner.file_included(name) then
            file = {min = 1e99, max = 0, max_hits = 0}
            data[name] = file
            if not runner.configuration.onlysummary then
               print('=== LuaCov new_files', name)
            end
         else
            ignored_files[name] = true
            if not runner.configuration.onlysummary then
               print('=== LuaCov ignored_files', name)
            end
            return
         end
      end

      if line_nr > file.max then
         file.max = line_nr
      end
      if line_nr < file.min then
         file.min = line_nr
      end

      local hits = (file[line_nr] or 0) + 1
      file[line_nr] = hits

      if hits > file.max_hits then
         file.max_hits = hits
      end

      if runner.tick then
         steps_after_save = steps_after_save + 1
         if steps_after_save >= runner.configuration.savestepsize then
            steps_after_save = 0
            if os.clock() - ticks_after_save >= runner.configuration.savetick then
				if not runner.paused then
               if runner.configuration.csmode and runner.sock then
                  local data_buf = {}
                  for k, v in pairs(runner.data) do
                     local fileinfo = {
                        file = k,
                        lines = {},
                        segs = {},
                     }
                     local prev = v.min
                     for i = v.min, v.max + 1 do
                        if v[i] == nil then
                           if prev then
                              if prev == i - 1 then
                                 table.insert(fileinfo.lines, prev)
                              else
                                 table.insert(fileinfo.segs, {prev, i - 1})
                              end
                              prev = nil
                           end
                        else
                           if prev == nil then
                              prev = i
                           end
                        end
                     end
                     local pdata = msgpack({
                        type = "cov",
                        cov = fileinfo,
                     })
                     table.insert(data_buf, lnconv.lton(#pdata, 4))
                     table.insert(data_buf, pdata)
                  end

                  local pdata = table.concat(data_buf)
                  local index, err, lastIndex = runner.sock:send(pdata)
                  print('=== LuaCov send', #pdata, index, err, lastIndex)
                  -- if no gc, it will be crash. otherwise, it good to test in mem tight
                  local mem1 = collectgarbage('count')
                  collectgarbage()
                  local mem2 = collectgarbage('count')
                  print('=== LuaCov gc', mem2 - mem1, mem2)
                  if err then
                     runner.sock:close()
                     runner.sock = nil
                  end

               else
                  -- no c/s, only local file
                  runner.save_stats()
               end

               runner.data = {}
				end
				ticks_after_save = os.clock()
			end
         end
      end
   end
end

return hook
