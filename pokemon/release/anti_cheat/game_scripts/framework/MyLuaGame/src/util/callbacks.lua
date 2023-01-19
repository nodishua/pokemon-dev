--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 回调链，支持增删操作
--

local callbacks = {}
globals.callbacks = callbacks
callbacks.__index = callbacks

-- @param cb: function or callbacks object
-- @comment call the curf first
function callbacks.new(cb, curf)
	local obj = {
		__pre = cb,
		__cur = curf,
	}
	return setmetatable(obj, callbacks)
end

function callbacks:__call(...)
	if self.__cur then self.__cur(...) end
	return self.__pre(...)
end

-- remove curf
function callbacks:remove()
	self.__cur = nil
	return self
end

-- call the newest(the append one) first
-- like stack, LIFO
-- @param new: callable, may be function or table had __call
function callbacks:chain(new)
	if self.__cur == nil then
		self.__cur = new
		return self
	end
	return callbacks.new(self, new)
end

function callbacks:prev()
	return self.__pre
end

function callbacks:myself()
	return self.__cur
end

function callbacks:size()
	local ret, ptr = 0, self.__pre
	-- first is function
	while type(ptr) ~= "function" do
		ret = ret + 1
		ptr = ptr.__pre
	end
	ret = ret == 0 and 1 or ret
	-- last is nil or function
	ptr = self.__cur
	if type(ptr) == "function" then
		ret = ret + 1
	elseif ptr ~= nil then
		ret = ret + ptr:size()
	end
	return ret
end

return callbacks

-- -- 111 <- 222
-- local cb = callbacks.new(function ( ... )
-- 	print(111, ...)
-- 	return 111
-- end, function( ... )
-- 	print(222, ...)
-- 	return 222
-- end)

-- print(cb('hello', 'world'))
-- print('---------')
-- -- 111
-- cb:remove()
-- print(cb('after remove'))
-- -- 111 <- 333
-- local cb2 = cb:chain(function ( ... )
-- 	print(333, ...)
-- 	return 333
-- end)
-- print('---------')
-- print(cb('cb after chain'))
-- print('---------')
-- print(cb2('cb2'))
-- print('---------')
-- -- 111 <- 333 <- 444
-- local cb3 = cb:chain(function ( ... )
-- 	print(444, ...)
-- 	return 444
-- end)
-- print(cb('cb after chain'))
-- print('---------')
-- print(cb2('cb2'))
-- print('---------')
-- print(cb3('cb3'))
-- print('---------')
-- -- 111 <- 444
-- cb2:remove()
-- print(cb3('after remove 333'))
-- print('---------')
-- print(cb('cb'))
-- print('cb', cb:size())
-- print(cb2('cb2'))
-- print('cb2', cb2:size())
-- print(cb3('cb3'))
-- print('cb3', cb3:size())
-- print('---------')
-- -- endless loop: 111 <- [111 <- 444]
-- -- cb:chain(cb3)
-- -- print(cb('cb after chain'))
-- print('---------')
-- local newcb = callbacks.new(function ( ... )
-- 	print('new 111', ...)
-- 	return 'new_111'
-- end, cb3)
-- print(newcb('newcb <- cb3'))
-- print('newcb', newcb:size())
-- print('---------')
-- newcb:remove()
-- print(newcb('after remove cb3'))
-- print('newcb', newcb:size())
-- print('--------- tail test ---------')
-- local tail
-- tail = callbacks.new(function (a)
-- 	if a == 0 then
-- 		return 0
-- 	elseif a == 1 then
-- 		return 1
-- 	elseif a == 2 then
-- 		return 2
-- 	end
-- 	return tail(a-1)
-- end)
-- print(tail(1000000000))

--
-- output
--

-- 222     hello   world
-- 111     hello   world
-- 111
-- ---------
-- 111     after remove
-- 111
-- ---------
-- 333     cb after chain
-- 111     cb after chain
-- 111
-- ---------
-- 333     cb2
-- 111     cb2
-- 111
-- ---------
-- 333     cb after chain
-- 111     cb after chain
-- 111
-- ---------
-- 333     cb2
-- 111     cb2
-- 111
-- ---------
-- 444     cb3
-- 333     cb3
-- 111     cb3
-- 111
-- ---------
-- 444     after remove 333
-- 111     after remove 333
-- 111
-- ---------
-- 111     cb
-- 111
-- cb      1
-- 111     cb2
-- 111
-- cb2     1
-- 444     cb3
-- 111     cb3
-- 111
-- cb3     2
-- ---------
-- ---------
-- 444     newcb <- cb3
-- 111     newcb <- cb3
-- new 111 newcb <- cb3
-- new_111
-- newcb   3
-- ---------
-- new 111 after remove cb3
-- new_111
-- newcb   1
-- --------- tail test ---------