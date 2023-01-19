--
-- 模块分发
--

local caption = string.caption

local CNotify = class("CNotify")
battleModule.CNotify = CNotify

function CNotify:ctor(view)
	self.view = view
	self.mods = {}
	self.msgMap = {}
end

function CNotify:init()
	for i, cls in ipairs(battleModule.mods) do
		table.insert(self.mods, cls.new(self.view))
	end
end

function CNotify:addSpec(specMods)
	for i, cls in ipairs(specMods) do
		table.insert(self.mods, cls.new(self.view))
	end
end

-- @comment: 广播给所有消息接收者
function CNotify:notify(msg, ...)
	log.battle.notify(msg, lazydumps({...}))
	for _, f in ipairs(self:getMsgMap(msg)) do
		-- f(...)
		f.func(self.mods[f.index], ...)
	end
end

-- @comment: 只执行第一个消息接收者，并返回值
-- 现在只在model.object中添加view proxy的地方使用
function CNotify:call(msg, ...)
	for _, f in ipairs(self:getMsgMap(msg, true)) do
		-- return f(...)
		return f.func(self.mods[f.index], ...)
	end
end

-- isCall: true, 调用msg同名函数
--       : false, 调用on..captain(msg)函数
function CNotify:getMsgMap(msg, isCall)
	local fName = isCall and msg or ('on' .. caption(msg))
	local map = self.msgMap[fName]
	if map == nil then
		map = {}
		for i, mod in ipairs(self.mods) do
			local f = mod[fName]
			if f then
				-- table.insert(map, function(...)
				-- 	return f(mod, ...)
				-- end)
				-- 问题：闭包+cow之前进行的缓存导致cow监听不到notify的信息
				table.insert(map, {
					func = f,
					index = i,
				})
			end
		end
		if table.length(map) == 0 then
			printWarn("no module handler for msg %s", msg)
		end
		self.msgMap[fName] = map
	end
	return map
end

function CNotify:close()
	for i, mod in ipairs(self.mods) do
		mod:onClose()
	end
	self.mods = {}
	self.msgMap = {}
end

return CNotify