--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 外置IUP编辑器
-- http://webserver2.tecgraf.puc-rio.br/iup/
--

require "iuplua"

local iupeditor = {}

function iupeditor:init(scene)
	print('iupeditor:init')
	if self.scene == nil then
		self.scene = scene
		self:initNodeStack()
		self:initBattleStack()
	end
end

local stackModule = require "editor.win32.nodestack"
for k, v in pairs(stackModule) do
	iupeditor[k] = v
end

local stackModule = require "editor.win32.battlestack"
for k, v in pairs(stackModule) do
	iupeditor[k] = v
end

return iupeditor