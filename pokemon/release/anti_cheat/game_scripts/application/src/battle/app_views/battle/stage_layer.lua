--
-- Copyright (c) 2014 YouMi Technologies Inc.
--
-- Author: sir.huangwei@gmail.com
-- Date: 2014-06-20 14:47:19
--

globals.CStageLayerModel = class("CStageLayerModel")

function CStageLayerModel:ctor(battleView, csv)
	self.battleView = battleView
	self.csv = csv
	self.x = 0
	self.y = 0
	self.xloopCount = 1
	self.yloopCount = 1
	self.lastAddCount = 0
end

function CStageLayerModel:init()
	self.xtileSize = 1
	self.ytileSize = 1
	self.x = self.csv.x
	self.y = self.csv.y
	local xcount = math.ceil(CC_DESIGN_RESOLUTION.width / self.csv.xlength) + 1
	local ycount = math.ceil(CC_DESIGN_RESOLUTION.height / self.csv.ylength) + 1
	if self.csv.xloop == 0 then
		self.xtileSize = xcount
		self.xloopCount = -99999999
	elseif self.csv.xloop > 2 then
		local cc = xcount <= self.csv.xloop and xcount or self.csv.xloop
		self.xtileSize = cc
		self.xloopCount = cc
	elseif self.csv.xloop == 2 then
		self.xtileSize = 2
		self.xloopCount = 2
	end
	if self.csv.yloop == 0 then
		self.ytileSize = ycount
		self.yloopCount = -99999999
	elseif self.csv.yloop > 2 then
		local cc = ycount <= self.csv.yloop and ycount or self.csv.yloop
		self.ytileSize = cc
		self.yloopCount = cc
	elseif self.csv.yloop == 2 then
		self.ytileSize = 2
		self.yloopCount = 2
	end

	local arg = {id = tostring(self), config = self.csv, x = self.x, y = self.y,
		xtileSize = self.xtileSize,xlength = self.csv.xlength,
		ytileSize = self.ytileSize,ylength = self.csv.ylength}
	self.battleView:onViewProxyNotify('AddGround', arg)
end

function CStageLayerModel:updateSelf(delta)
	local dx = -self.csv.x_speed * delta / 1000
	local dy = -self.csv.y_speed * delta / 1000
	if dx == 0 and dy == 0 then return end
	self.x = self.x + dx
	self.y = self.y + dy
	--x轴循环
	if self.xloopCount < self.csv.xloop and -self.x >= self.csv.xlength then
		self.x = self.csv.xlength + self.x
		self.xloopCount = self.xloopCount + 1
	elseif self.xloopCount < self.csv.xloop and self.csv.x_speed < 0 and self.x >= self.csv.xlength then
		self.x = self.x - self.csv.xlength
		self.xloopCount = self.xloopCount + 1
	end
	--y轴循环
	if self.yloopCount < self.csv.yloop and -self.y >= self.csv.ylength then
		self.y = self.csv.ylength + self.y
		self.yloopCount = self.yloopCount + 1
	elseif self.yloopCount < self.csv.yloop and self.csv.y_speed < 0 and self.y >= self.csv.ylength then
		self.y = self.y - self.csv.ylength
		self.yloopCount = self.yloopCount + 1
	end
	local arg = {id = tostring(self), config = self.csv, x = self.x, y = self.y,
		xtileSize = self.xtileSize,xlength = self.csv.xlength,
		ytileSize = self.ytileSize,ylength = self.csv.ylength}
	self.battleView:onViewProxyNotify('MoveGround', arg)
end