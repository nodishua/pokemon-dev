--
-- Copyright (c) 2014 YouMi Technologies Inc.
--
-- Author: sir.huangwei@gmail.com
-- Date: 2014-06-18 20:09:25
--

require "battle.app_views.battle.stage_layer"

globals.CStageModel = class("CStageModel")

function CStageModel:ctor(battleView)
	self.battleView = battleView
	self.bkLayerMap = CMap.new()
end

function CStageModel:init(bkCsv)
	self.bkLayerMap:clear()
	local bkCfg = getCsv(bkCsv)
	for k,v in orderCsvPairs(bkCfg) do
		if v.resType == 1 or v.resType == 2 then --背景层或前景层
			local layer = CStageLayerModel.new(self.battleView, v)
			layer:init()
			self.bkLayerMap:insert(k, layer)
		end
	end

end

function CStageModel:update(delta)
	for k,v in pairs(self.bkLayerMap) do
		v:updateSelf(delta)
	end
end