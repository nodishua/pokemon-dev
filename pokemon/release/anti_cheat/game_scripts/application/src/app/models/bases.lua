--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- GameModelsBase
--


local GameModelsBase = class("GameModelsBase", CMap)

function GameModelsBase:ctor(game)
	self.game = game

	CMap.ctor(self)
end

function GameModelsBase:init(t)
	for k, v in pairs(t) do
		local model = self:find(k)
		if model ~= nil then
			model:syncFrom(v)
		else
			model = self:newModel(v)
			self:insert(k, model)
		end
	end
	return self
end

function GameModelsBase:newModel(t)
	error("need be implement!!!")
end

function GameModelsBase:getIdler(id, name)
	if id == nil then
		error('GameModelsBase not __idlers')
	end
	return self:find(id):getIdler(name)
end

function GameModelsBase:syncFrom(t, new)
	for k, v in pairs(t) do
		local model = self:find(k)
		if model ~= nil then
			model:syncFrom(v, new and new[k])
		else
			model = self:newModel(v)
			self:insert(k, model)
		end
	end
end

function GameModelsBase:syncDel(t)
	for k, v in pairs(t) do
		if v == false then
			self:erase(k)
		else
			local model = self:find(k)
			model:syncDel(v)
		end
	end
end

return GameModelsBase