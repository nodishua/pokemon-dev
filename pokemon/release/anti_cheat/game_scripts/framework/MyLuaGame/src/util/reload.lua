--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- eg. reload_require("notice_factory","lua/notice_factory.lua")
--function reload_require(moduleName , pathname)
function reload_require() --全部重加载
    -- if pathname == nil then
    --     if moduleName ==nil then
    --         return false
    --     else
    --         package.loaded[moduleName] = nil
    --         require(moduleName)
    --         return true
    --     end
    -- end
    -- local old_mod = package.loaded[moduleName]
    -- --需要已经修改原来已经 require的函数

    -- local func, err = loadfile(pathname)
    -- if not func then
    --     print("@ERROR: " .. err)
    --     return false
    -- end

    -- local  new_mod  = func()
    -- for k,v in pairs(new_mod) do
    --     --保险起见只有函数热更新
    --     if type(v) == "function" then
    --         old_mod[k] = v
    --     end
    -- end
    -- print("reload \""..moduleName.."\" success!!!!!!!!!")
    -- return true
    local canRequired = {["algorithm%."]=true,
    ["base%."]=true,
    ["config%."]=true,
    ["game_model%."]=true,
    ["luastl%."]=true,
    ["model%."]=true,
   -- ["net%."]=true,
    ["ui%."]=true,
    ["util%."]=true,
    ["view%."]=true,
    ["game_C"]=true,
    ["game_S"]=true,
    ["game_ui"]=true,}
    for k,v in pairs(package.loaded) do
        local flag = false
        for k1,v1 in pairs(canRequired) do
            if string.find(k, k1) then
                flag = true
                break
            end
        end
        if flag then
            --第一种方法 简单粗暴
            package.loaded[k] = nil
            require(k)
            -- 第二种方法,适用于lua5.2版本
            -- local old_mod = package.loaded[k]
            -- --需要已经修改原来已经 require的函数
            -- local path = string.gsub(k,"%.","/")
            -- local func, err = loadfile("./scripts/"..path..".lua")
            -- if not func then
            --     print("@ERROR: " .. err)
            -- else
            --     local  new_mod  = func()
            --     以下需要lua5.2版本
                -- if new_mod then
                --     for k1,v1 in pairs(new_mod) do
                --         --保险起见只有函数热更新
                --         if type(v1) == "function" then
                --             old_mod[k1] = v1
                --         end
                --     end
                -- end

                print("SUCCESS REQUIRED:  " .. k)
            -- end
        end
    end
end