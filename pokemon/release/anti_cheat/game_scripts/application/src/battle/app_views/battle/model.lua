--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

require "battle.models.include"

local BattleModel = class("BattleModel")


function BattleModel:ctor()
	self.scene = nil

	self.updateFrame = nil
	self.updateDelta = nil
	self.battleData = nil
	self.battleSceneID = nil
	self.modelEnable = true
	self.modelPause = false
end

function BattleModel:init()
	cow.battleModelInit()
end

function BattleModel:cleanUp()
	self.scene = nil

	self.battleData = nil
	self.battleSceneID = nil
	self.updateFrame = nil
	self.updateDelta = nil

	cow.battleModelDestroy()
end

function BattleModel:reset(data, sceneID, isRecord)
	self:cleanUp()

	cow.battleModelInit()

	self.scene = cow.proxyObject("scene", SceneModel.new())

	self.updateDelta = 0
	self.updateFrame = 0
	self.modelPause = false
	self.modelEnable = true
	self.battleData = data
	self.battleSceneID = sceneID
	self.battleIsRecord = isRecord
end

function BattleModel:onInitInUpdate()
	local data, sceneID, isRecord = self.battleData, self.battleSceneID, self.battleIsRecord
	self.battleData = nil -- TEST:
	self.battleSceneID = nil
	self.battleIsRecord = nil

	local title = string.format("\n\n\t\tbattle %s start - seed=%s, scene=%s\n\n", isRecord and "record" or "", data.randSeed, sceneID)
	printInfo(title)
	log.battle(title)

	ymrand.randomseed(data.randSeed)
	ymrand.randCount = 0

	self.scene:init(sceneID, data, isRecord)
end

function BattleModel:update(delta)
	if not self.modelEnable or self.modelPause then return end
	if self.scene.isBattleAllEnd then return end

	self.updateDelta = self.updateDelta + delta
	self.updateFrame = self.updateFrame + 1
	--first update
	if self.updateFrame == 1 then
		self:onInitInUpdate()
	end
	if self.updateFrame <= 5 then return end


	--反作弊frametick需要固定
	local frametick = game.FRAME_TICK
	if self.updateDelta < frametick then
		return
	end

	local frames = math.floor(self.updateDelta / frametick)
	for i = 1, frames do
		if not self.modelEnable or self.modelPause then break end
		self.scene:update(frametick)
		self.updateDelta = self.updateDelta - frametick
	end
end

function BattleModel:setModelEnable(v)
	self.modelEnable = v
end

function BattleModel:runUntilEnd()
	self.modelPause = false
	self.modelEnable = true
	-- gRootViewProxy:modelOnly()
	ViewProxy.allModelOnly()

	--自动模式打完战斗
	self.scene:setAutoFight(true)
	while true do
		if self.scene.isBattleAllEnd then
			break
		end
		-- model的更新频率
		self:update(game.FRAME_TICK)
	end

	self.modelEnable = false
end

function BattleModel:runUnitlNextWave()
	self.modelPause = false
	self.modelEnable = true
	-- 清空多余的帧数 保证波次结束可以跳出
	self.updateDelta = 0

	ViewProxy.allModelOnly()
	local isAuto = self.scene.autoFight
	self.scene:setAutoFight(true)
	while true do
		if self.scene.isBattleAllEnd then
			self.modelEnable = false
			break
		end
		if self.scene.play.isWaveEnd then
			self.scene:setAutoFight(isAuto)
			ViewProxy.allModelResum()
			break
		end
		-- model的更新频率
		self:update(game.FRAME_TICK)
	end
end

local operators = {
	[battle.OperateTable.skill] = function(self, seat)
		--竞技场不能手动控制
		if self.scene.gateType == game.GATE_TYPE.arena then
			return
		end

		local hero = self.scene.heros:find(seat)
		if hero and hero:isCanHandSkill() and not self.scene.inMainSkill then
			hero:handSkill()
		end
	end,

	[battle.OperateTable.attack] = function(self, seat, skillID)
		self.scene.play:setAttack(seat, skillID)
	end,

	[battle.OperateTable.noAttack] = function(self)
		self.scene:setNoAttackFlag()
	end,

	-- [battle.OperateTable.helper] = function(self, id, )
	-- 	self.scene:addHelper()
	-- end,

	[battle.OperateTable.autoFight] = function(self, flag)
		self.scene:setAutoFight(flag)
	end,

	-- [battle.OperateTable.choose] = function(self, id)
	-- 	self.scene:choose(id)
	-- end,

	-- [battle.OperateTable.runAway] = function(self, id)
	-- 	self.scene:runAway(id)
	-- end,

	[battle.OperateTable.pass] = function(self)
		self:runUntilEnd()
	end,

	[battle.OperateTable.passOneWave] = function(self)
		self.scene.play:onPassOneWave(function ()
			self:runUnitlNextWave()
		end)
	end,

	-- 是否开启全手动操作
	[battle.OperateTable.fullManual] = function(self)
		self.scene:setFullManual(self.battleData.moduleType == 2)
	end,
}

function BattleModel:handleOperation(_type, ...)
	if self.scene == nil then return end
	local f = operators[_type]
	if f then
		return f(self, ...)
	end
end


return BattleModel