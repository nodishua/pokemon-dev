require "battle.app_views.battle.stage"
require "battle.app_views.battle.module.include"

require "battle.views.sprite"
require "battle.views.sprite_possess"
require "battle.views.sprite_follower"
require "battle.views.event_effect.include"

local FPSCheckMax = 5

local ViewBase = cc.load("mvc").ViewBase
globals.BattleView = class("BattleView", ViewBase)
local BattleModel = require("battle.app_views.battle.model")

local battleUIWidget = {}
battleUIWidget.RESOURCE_FILENAME = "battle.json"
battleUIWidget.RESOURCE_BINDING = {
	["topLeftPanel"] = "topLeftPanel",
	["topRightPanel"] = "topRightPanel",
	["midPanel"] = "midPanel",
	["bottomLeftPanel"] = "bottomLeftPanel",
	["bottomRightPanel"] = "bottomRightPanel",
	["leftGroupPanel"] = "leftGroupPanel",
	["rightGroupPanel"] = "rightGroupPanel",
	["topLeftPanel.infoPVP.line"] = {
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(92,84,92,255)}}
		}
	},
	["topRightPanel.infoPVP.line"] = {
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(92,84,92,255)}}
		}
	},
}

local gateEndStyles = {clickClose = true}

function BattleView:onCreate(data, sceneID, modes, entrance)
	self._model = nil
	self._scene = nil -- readOnly by getSceneModel
	self._play = nil -- readOnly by getPlayModel
	self.modelWaitType = nil

	self.stage = nil --背景对象 CStageModel
	self.stageLayer = nil -- 背景层
	self.effectLayerLower = nil -- 特效层,处于角色层下面,给技能中的大招背景用
	self.gameLayer = nil -- 游戏层
	self.effectLayer = nil -- 特效层
	self.effectLayerNum = nil -- 伤害数字显示层
	self.frontStageLayer = nil -- 前景层
	self.weatherLayer = nil  -- 天气特效层
	self.layer = nil -- UI层
	self.sceneID = nil -- 关卡ID
	self.isGuideScene = nil
	self.gateType = nil -- 关卡类型
	self.tick = 0 -- 计时器
	self.deathCache = {} -- 缓存死亡特效
	self.modes = modes or clone(battle.DefaultModes)
	-- self.baseMusic = self.modes.baseMusic
	self.timeScale = battle.SpeedTimeScale.single
	self.ultAccEnable = false
	self.inUltAcc = false
	self.effectManager = cow.proxyObject("effectManager", battleEffect.Manager.new('BattleView'))

	self.guideManager = require("battle.app_views.battle.guide").new(self)

	self.subModuleNotify = cow.proxyObject("subModuleNotify", battleModule.CNotify.new(self))

	self.effectDebug = {}
	self.buffEffectsMap = {}
	self.buffEffectsSelfMap = {}
	self.buffEffectsEnemyMap = {}
	self.buffEffectsRef = {}
	self.buffEffectsSelfRef = {}
	self.buffEffectsEnemyRef = {}
	self.buffEffectsToHide = {}

	-- scene的curViewEffectPlayFuncsTb和viewEffectPlayFuncsTb先迁移到BattleView
	-- 先保留viewEffectPlayFuncsTb缓存队列功能
	self.deferListMap = CVector.new() -- {}
	self.curDeferList = nil
	self.filterMap = {}

	-- 跳过大招 effect缓存
	self.effectJumpCache = {}
	self.effectEventEnable = true
	self:initBattle(data, sceneID, self.modes.isRecord)
	self.modelPauseTimer = {}
	self.onceEffectWaitCount = 0  -- 等待一次性动画播放结束计数

	-- 入口闭包
	self.entrance = entrance

	-- 降帧
	self.fpsSum = 0
	self.fpsCount = 0
	self.lastLowFPSCount = 0
	self.fpsMax = userDefault.getForeverLocalKey("fps", 60, {rawKey = true})
	if self.fpsMax > 30 then
		-- schedule(self, function()
		-- 	self:onCheckFPS()
		-- end, 2)
	end
end

function BattleView:onClose()
	self:cleanUp()
	self._model = nil
	self._scene = nil
	self._play = nil

	-- 释放所有组件
	battleComponents.clearAll()

	-- sdk 包直接注销帐号 时清除引导
	if self.guideManager:isInGuiding() then
		self.guideManager:onClose()
	end

	-- 异常应用控制球关闭时, 恢复界面响应计数
	gGameUI:removeAllDelayTouchDispatch()

	-- 有资源预加载
	-- 新手战斗后强制清理内存
	cache.onBattleClear(self.sceneID == 1)

	-- 预加载公共资源
	cache.texturePreload("common_ui")

	-- 战斗配表卸载
	battleEntrance.unloadConfig()

	ViewBase.onClose(self)

	display.director:resume()
	-- 需要恢复时间倍率的不止结算界面 因此保留这段 防止出问题
	display.director:getScheduler():setTimeScale(1)
	local fps = userDefault.getForeverLocalKey("fps", 60, {rawKey = true})
	display.director:setAnimationInterval(1.0 / fps)
	if display.director.isSpineThreadDrawEnabled then
		display.director:setSpineThreadDrawEnabled(false)
	end

	-- later on GameApp:onCleanCache, here only for test
	-- printInfo("BattleView:onClose - before collect %f KB", collectgarbage("count"))
	-- collectgarbage("collect")
	-- printInfo("BattleView:onClose - after collect %f KB", collectgarbage("count"))
	-- clearAllSaltNumber()
end

function BattleView:cleanUp()
	if self._model then
		self._model:cleanUp()
	end
end

function BattleView:reset()
	self:cleanUp()

	self._model = BattleModel.new()
	self._scene = nil
	self._play = nil
	self.tick = 0
end

function BattleView:initBattle(data, sceneID, isRecord)
	self:reset()

	self.data = data
	self.sceneID = sceneID or data.sceneID
	self.gateType = data.gateType or csv.scene_conf[sceneID].gateType

	-- 创建界面
	self:add(self:createLayerStage())
		:add(self:createLayerBelowGameLayer())
		:add(self:createLayerGame())
		:add(self:createLayerUpGameLayer())
		:add(self:createLayerEffect())
		:add(self:createWeatherLayer())
		:add(self:createUILayer())
		:add(self:createEffectLayerNum())
		:add(self:createFrontLayerStage())
		:add(self:createDeleteObjLayer())

	self.subModuleNotify:init()

	-- 界面隐藏处理
	self:showMainUI(false)

	self.deferListMap = CVector.new() -- {}
	self.curDeferList = nil
	self:pushDeferList() -- global

	self:initStage()

	-- some play could be add some spec ui in here
	self._model:reset(data, sceneID, isRecord)

	self:onViewProxyNotify("initBattle")

	self.timeScale = battle.SpeedTimeScale.single
	display.director:resume()
	display.director:getScheduler():setTimeScale(self.timeScale)
	if display.director.isSpineThreadDrawEnabled then
		display.director:setSpineThreadDrawEnabled(false)
	end

	collectgarbage("stop")
end

-- 扩展以支持各类战斗独立设置自己的战斗背景图片
local gateStageFuncs = {
	-- test也是默认方法
	[game.GATE_TYPE.test] = function(self)
		return gMonsterCsv[self.sceneID][1].bkCsv
	end,
	[game.GATE_TYPE.randomTower] = function(self)
		local room_info = self.data.gamemodel_data and self.data.gamemodel_data.room_info
		local enemyId = room_info and room_info.enemy[room_info.board_id].id or 1001
		local csvCfg = csv.random_tower.monsters[enemyId]
		return csvCfg.backGround
	end,
	[game.GATE_TYPE.braveChallenge] = function(self)
		local csvCfg = csv.brave_challenge.floor[self.data.floorID]
		return csvCfg.scene
	end,
	[game.GATE_TYPE.hunting] = function(self)
		local gateID = self.data.gateID
		local csvCfg = csv.cross.hunting.gate[gateID]
		return csvCfg.backGround
	end,
	[game.GATE_TYPE.summerChallenge] = function(self)
		local gateID = self.data.gateID
		local csvCfg = csv.summer_challenge.gates[gateID]
		return csvCfg.scene
	end,
}

function BattleView:initStage()
	local func = gateStageFuncs[self.gateType] or gateStageFuncs[game.GATE_TYPE.test]
	if self.modes.fromRecordFile then
		func = gateStageFuncs[game.GATE_TYPE.test]
	end
	self.stage = CStageModel.new(self)		-- switchUI中的init()调用比 gRootViewProxy的赋值要早了,所以这里改成手动传参吧
	self.stage:init(func(self))
end

-- create map
function BattleView:createLayerStage()
	local layer = cc.Layer:create() --("stageLayer")
	layer:name("stageLayer")
	self.stageLayer = layer
	return layer
end

function BattleView:createFrontLayerStage()
	local layer = cc.Layer:create() --("frontStageLayer")
	layer:name("frontStageLayer")
	self.frontStageLayer = layer
	return layer
end

function BattleView:createDeleteObjLayer()
	local layer = cc.Layer:create() --("deleteObjLayer")
	layer:name("deleteObjLayer"):setVisible(false)
	self.deleteObjLayer = layer
	return layer
end


-- 在角色层下面一层, 显示特殊大招的遮盖背景层
function BattleView:createLayerBelowGameLayer()
	local layer = cc.Layer:create() --("effectLayerLower")
	layer:name("effectLayerLower")
	self.effectLayerLower = layer
	return layer
end

function BattleView:createLayerGame()
	local layer = cc.Layer:create() --("gameLayer")
	layer:name("gameLayer")
	layer:setPosition(cc.p(0, display.fightLower))
	self.gameLayer = layer
	return layer
end

-- 在角色层上面一层, 显示特殊大招背景中需要在角色层上面的特效
function BattleView:createLayerUpGameLayer()
	local layer = cc.Layer:create() --("effectLayerUpper")
	layer:name("effectLayerUpper")
	self.effectLayerUpper = layer
	return layer
end

-- create effect 主要的特效显示层 如buff等
function BattleView:createLayerEffect()
	local layer = cc.Layer:create() --("effectLayer")
	layer:name("effectLayer")
	layer:setPosition(cc.p(0, display.fightLower))
	self.effectLayer = layer
	return layer
end

-- 天气特效层
function BattleView:createWeatherLayer()
	local layer = cc.Layer:create() --("weatherLayer")
	layer:name("weatherLayer")
	self.weatherLayer = layer
	return layer
end

function BattleView:createEffectLayerNum()
	local layer = cc.Layer:create() --("effectLayer")
	layer:name("effectLayerNum")
	layer:setPosition(cc.p(0, display.fightLower))
	self.effectLayerNum = layer
	return layer
end

function BattleView:createUILayer()
	self.layer = cc.Layer:create() --("layer")
	self.layer:name("UILayer")

	self.UIWidget = gGameUI:createSimpleView(battleUIWidget, self.layer):init(self)
	-- 主要UI部分
	self.UIWidgetLeft = self.UIWidget.topLeftPanel
	self.UIWidgetRight = self.UIWidget.topRightPanel
	self.UIWidgetMid = self.UIWidget.midPanel
	self.UIWidgetBottomLeft = self.UIWidget.bottomLeftPanel
	self.UIWidgetBottomRight = self.UIWidget.bottomRightPanel

	--跨服竞技场相关部分
	self.UIWidgetGroupLeft = self.UIWidget.leftGroupPanel
	self.UIWidgetGroupRight = self.UIWidget.rightGroupPanel

	self.UIWidgetMid:get("widgetPanel.speedRank"):setVisible(false)
	self.UIWidgetBottomRight:setVisible(false)

	-- 界面上的初始显示隐藏设置: (放这里统一设置吧,方便不同场景玩法做对比修改)
	-- pve 关卡显示： 波数、回合数、天气效果, 不显示左右双方头像
	if self:isPVEScene() then
		self.UIWidgetLeft:get("infoPVP"):setVisible(false)
		self.UIWidgetRight:get("infoPVP"):setVisible(false)
	-- pvp 关卡显示: 显示左右双方头像、回合数、天气效果，不显示波数
	elseif self:isPVPScene() then
		self.UIWidgetMid:get("widgetPanel.wavePanel"):setVisible(false)
		--限时PVP也不显示头像
		if self:isSepcPVPScene() then
			self.UIWidgetLeft:get("infoPVP"):setVisible(false)
			self.UIWidgetRight:get("infoPVP"):setVisible(false)
		end
	end

	-- 不显示波数
	if self.gateType == game.GATE_TYPE.dailyGold
	   or self.gateType == game.GATE_TYPE.dailyExp
	   or self:getGymDeployType() == game.DEPLOY_TYPE.OneByOneType then
		self.UIWidgetMid:get("widgetPanel.wavePanel"):setVisible(false)
	end

	-- 非跨服竞技场不显示队伍
	if (self.gateType ~= game.GATE_TYPE.crossArena and self.gateType ~= game.GATE_TYPE.crossMine)
	   or self:getGymDeployType() == game.DEPLOY_TYPE.WheelType then
		self.UIWidgetGroupLeft:hide()
		self.UIWidgetGroupRight:hide()
	end
	-- 角色属性查看通用面板
	self.objAttrPanel = gGameUI:createView("battle.attr_panel", self.layer):init(self)
	self.objAttrPanel:hide():z(999)
	-- self.UIWidgetMid:onClick(function()
	-- 	if self.ultAccEnable and (dataEasy.isUnlock(gUnlockCsv.ultraAcc) or self.gateType == game.GATE_TYPE.test) and not userDefault.getForeverLocalKey("mainSkillPass", false) then
	-- 		self:handleOperation(battle.OperateTable.ultAcc)
	-- 	end
	-- end)
	return self.layer
end

function BattleView:showMainUI(isShow)
	self.UIWidget:setVisible(isShow)
end

function BattleView:clearDeleteObjLayer()
	self.deleteObjLayer:removeAllChildren()
end

function BattleView:showSpeedRank(isShow)
	self.UIWidgetMid:get("widgetPanel.speedRank"):setVisible(isShow)
end

-- ui工程里用的几个通用判断：如果某个场景中出现界面上的某个/些通用控件找不到,一般都是这里没加
-- pve 场景通用的设置
local pveScenes = {
	[game.GATE_TYPE.normal] = true,
	[game.GATE_TYPE.dailyGold] = true,
	[game.GATE_TYPE.dailyExp] = true,
	[game.GATE_TYPE.unionFuben] = true,
	[game.GATE_TYPE.endlessTower] = true,
	[game.GATE_TYPE.gift] = true,
	[game.GATE_TYPE.fragment] = true,
	[game.GATE_TYPE.simpleActivity] = true,
	[game.GATE_TYPE.friendFight] = true,
	[game.GATE_TYPE.randomTower] = true,
	[game.GATE_TYPE.clone] = true,
	[game.GATE_TYPE.worldBoss] = true,
	[game.GATE_TYPE.huoDongBoss] = true,
	[game.GATE_TYPE.gym] = true,
	[game.GATE_TYPE.crossMineBoss] = true,
	[game.GATE_TYPE.braveChallenge] = true,
	[game.GATE_TYPE.hunting] = true,
	[game.GATE_TYPE.summerChallenge] = true,
}
function BattleView:isPVEScene()
	return pveScenes[self.gateType]
end

local bossScenes = {
	[game.GATE_TYPE.dailyGold] = true,
	[game.GATE_TYPE.worldBoss] = true,
	[game.GATE_TYPE.unionFuben] = true,
	-- [game.GATE_TYPE.crossMineBoss] = true
}

function BattleView:isBossScene()
	return bossScenes[self.gateType]
end

-- pvp 场景通用的设置
local pvpScenes = {
	[game.GATE_TYPE.newbie] = true,
	[game.GATE_TYPE.test] = true,
	[game.GATE_TYPE.arena] = true,
	[game.GATE_TYPE.crossArena] = true,
	[game.GATE_TYPE.unionFight] = true,
	[game.GATE_TYPE.crossUnionFight] = true,
	[game.GATE_TYPE.crossOnlineFight] = true,
	[game.GATE_TYPE.gymLeader] = true,
	[game.GATE_TYPE.crossGym] = true,
	[game.GATE_TYPE.crossMine] = true
}
function BattleView:isPVPScene()
	return pvpScenes[self.gateType] or self:isSepcPVPScene()
end

-- pvp 特殊模式下 1v1
local specPVPScenes = {
	[game.GATE_TYPE.craft] = true,
	[game.GATE_TYPE.crossCraft] = true,
}
function BattleView:isSepcPVPScene()
	-- 跨服公会战的1v1赛程
	if self.gateType == game.GATE_TYPE.crossUnionFight then
		return self.data.battleType == 3
	end
	return specPVPScenes[self.gateType]
end

-- 这里只是通知到view，现在model运行到哪个环节
-- wait状态由SceneModel维护
function BattleView:onModelWait(type)
	log.battle.battleView.wait(type)

	self.modelWaitType = type
	self._model:setModelEnable(false)
	self.modelPauseTimer[1] = os.clock()

end

function BattleView:onModelResume()
	self.modelWaitType = nil
	self._model:setModelEnable(true)
	self.modelPauseTimer = {}
end

function BattleView:onCheckFPS()
	local fps = 1. / display.director:getSecondsPerFrame()
	self.fpsSum = self.fpsSum + fps
	self.fpsCount = self.fpsCount + 1
	-- print('!!! onCheckFPS', fps, self.fpsSum / self.fpsCount)
	if self.fpsCount >= FPSCheckMax then
		local avg = self.fpsSum / self.fpsCount
		self.fpsCount = 0
		self.fpsSum = 0
		fps = 60
		if avg < 30 and self.lastLowFPSCount < 3 then
			fps = 40
			self.lastLowFPSCount = self.lastLowFPSCount + 1
		else
			-- revert back for test high fps
			self.lastLowFPSCount = 0
		end
		-- print('!! changeFPS', math.min(fps, self.fpsMax))
		display.director:setAnimationInterval(1.0 / math.min(fps, self.fpsMax))
	end
end

local longTimeToWait
local debugQueHead, debugQueTail
function BattleView:onUpdate(delta)
	if not self.gameLayer then return end

	updateSaltNumber(delta)

	delta = delta * 1000
	-- wait all queued effect over
	if self.modelWaitType then
		self.modelPauseTimer[2] = os.clock()
		if self.modelPauseTimer[2] - self.modelPauseTimer[1] > 1000 then
			if longTimeToWait ~= self.modelWaitType then
				longTimeToWait = self.modelWaitType
				printWarn("Model Disable Time too Long, modelWaitType:"..self.modelWaitType)
			end
		end
		if self.effectManager:queueSize() == 0 and self.onceEffectWaitCount <= 0 then
			log.battle.battleView.resume(self.modelWaitType)
			if self.modelWaitType == "guiding" then
				self.guideManager:update(delta)
			else
				self:onModelResume()
			end
		else
			if device.platform == "windows" then
				if debugQueHead ~= self.effectManager.queHeadID or debugQueTail ~= self.effectManager.queTailID then
					lazylog.battle.battleView.wait(self.modelWaitType, function()
						return dumps(self.effectManager:queueInfo())
					end)
					debugQueHead = self.effectManager.queHeadID
					debugQueTail = self.effectManager.queTailID
				end
			end
		end

	end

	self.tick = self.tick + delta

	cache.onBattleUpdate(delta)

	-- effect更新
	self.effectManager:update(delta)

	-- 通知各模块的onUpdate
	self:onViewProxyNotify("update", delta)

	self._model:update(delta)

	self:onViewProxyNotify("updateOver", delta)

	collectgarbage("step", 10)
end

function BattleView:getSceneModel()
	if not self._scene then
		self._scene = readOnlyProxy(self._model.scene)
	end
	return self._scene
end

function BattleView:getPlayModel()
	if not self._play then
		self._play = readOnlyProxy(self._model.scene.play)
	end
	return self._play
end

local operators = {
	-- 加速
	[battle.OperateTable.timeScale] = function(self, num)
		self.timeScale = battle.SpeedTimeScale[num]
		display.director:getScheduler():setTimeScale(self.timeScale)
	end,
	[battle.OperateTable.ultAcc] = function(self)
		self.inUltAcc = true
		display.director:getScheduler():setTimeScale(battle.SpeedTimeScale['ultAcc'])
	end,
	[battle.OperateTable.ultAccEnd] = function(self)
		self.inUltAcc = false
		display.director:getScheduler():setTimeScale(self.timeScale)
	end,
	[battle.OperateTable.pass] = function(self, ...)
		self:stopAllActions()
		self:disableUpdate()
		return self._model:handleOperation(battle.OperateTable.pass, ...)
	end,
}

function BattleView:handleOperation(_type, ...)
	local f = operators[_type]
	if f then
		return f(self, ...)
	else
		return self._model:handleOperation(_type, ...)
	end
end

-- 剧情引导数据
function BattleView:setGuideData(cfgIds)
	self.guideManager:setData(cfgIds)
end

function BattleView:setGuideClickCall(f)
	self.guideManager:setChoicesFunc(f)
end

-- 子弹时间
function BattleView:bulletTimeShow()
	display.director:getScheduler():setTimeScale(battle.SpeedTimeScale.single*0.25)
	performWithDelay(self, function()
		display.director:getScheduler():setTimeScale(1)
	end, 0.25)
end

-- 结束界面处理 (view里就不再继承了,只有少量的地方要修改,分发一下就好了)
function BattleView:_onShowArenaEndView(results)
	-- 回放，无领取奖励时
	if self.modes.noShowEndRewards or self.modes.isRecord then
		local isWin = results.result == "win"
		-- 胜负结果对于导向的界面不同
		if isWin and not self.modes.isRecord then
			gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
		end
	else
		-- 回放, 有领取奖励
		self.modes.noShowEndRewards = true
		gGameUI:stackUI("battle.battle_end.pvp_reward", {showEndView = self:createHandler("_onShowArenaEndView", results, true)}, gateEndStyles, results):z(999)
	end
end

-- 跨服竞技场结束界面处理
function BattleView:_onShowCrossArenaEndView(results)
	results.flag = "crossArena"

	if results.serverData == nil then
		gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
		return
	end

	local isWin = results.result == "win"
	local serverDataView = results.serverData.view
	local curRank = serverDataView.rank
	local preRank = curRank + serverDataView.rank_move
	local predata = dataEasy.getCrossArenaStageByRank(preRank)
	local curdata = dataEasy.getCrossArenaStageByRank(curRank)

	local csvId = gGameModel.cross_arena:read("csvID")
	local version = csv.cross.service[csvId].version

	if isWin and not self.modes.isRecord then
		if not self.modes.nextShowStageUp then
			if curdata.stageName == predata.stageName then
				gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
				results.backCity = true
			else
				gGameUI:stackUI("battle.battle_end.pvp_win", {showEndView = self:createHandler("_onShowCrossArenaEndView", results, true)}, gateEndStyles, self.sceneID, self.data, results):z(999)
				self.modes.nextShowStageUp = true
			end
		else
			gGameUI:stackUI("battle.battle_end.pvp_stage_up", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		end
	else
		gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
	end
end

-- 道馆馆主结束界面处理
function BattleView:_onShowGymLeaderEndView(results)
	if self.modes.isRecord then
		gGameUI:switchUI("city.view")
		return
	end

	results.flag = "gymLeader"
	results.gymName = csv.gym.gym[gGameModel.battle.gym_id].name
	if results.result == "win" then
		gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
	else
		gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
	end
end


local gateEndFuncs = {
	[game.GATE_TYPE.newbie] = function(self, results)
		gGameUI:switchUI("new_character.view")
	end,
	[game.GATE_TYPE.test] = function(self, results)
		gGameUI:switchUI("city.view")
	end,
	[game.GATE_TYPE.normal] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.win", nil, gateEndStyles, self, results):z(999)
			self:showCaptureTips(results.oldCapture)
		else
			self:jumpToPveFailView(results, 1)
		end
	end,
	[game.GATE_TYPE.arena] = function(self, results)
		return self:_onShowArenaEndView(results)
	end,
	[game.GATE_TYPE.crossArena] = function(self, results)
		return self:_onShowCrossArenaEndView(results)
	end,
	[game.GATE_TYPE.friendFight] = function(self, results)
		gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
	end,
	[game.GATE_TYPE.randomTower] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.random_win", nil, gateEndStyles, self, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,

	-- 活动结束界面
	[game.GATE_TYPE.dailyGold] = function(self, results)
		-- 没有败北，只有胜利展示
		gGameUI:stackUI("battle.battle_end.daily_activity", nil, gateEndStyles, self.sceneID, results):z(999)
	end,
	[game.GATE_TYPE.endlessTower] = function(self, results)
		if self.modes.noShowEndRewards or self.modes.isRecord then
			gGameUI:switchUI("city.view")
		elseif results.result == "win" then
			gGameUI:stackUI("battle.battle_end.endless_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			gGameUI:stackUI("battle.battle_end.endless_fail", nil, gateEndStyles, self, results, 1):z(999)
		end
	end,
	[game.GATE_TYPE.unionFuben] = function(self, results)
		gGameUI:stackUI("battle.battle_end.daily_activity", nil, gateEndStyles, self.sceneID, results):z(999)
	end,
	[game.GATE_TYPE.gift] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.simple_activity_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
    [game.GATE_TYPE.clone] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.clone_win", nil, nil, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
	[game.GATE_TYPE.worldBoss] = function(self, results)
		gGameUI:stackUI("battle.battle_end.world_boss_win", nil, gateEndStyles, self.sceneID, results):z(999)
	end,
	[game.GATE_TYPE.crossOnlineFight] = function(self, results)
		if results.showReward then
			gGameUI:stackUI("battle.battle_end.reward", nil, gateEndStyles, self:createHandler("_onShowRewardEndView", results), results):z(999)
			return
		end

		if results.result == "win" then
			if results.showMvpView then
				gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles,self.sceneID,self.data, results):z(999)
			else
				gGameUI:stackUI("battle.battle_end.jf", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
			end
		else
			gGameUI:stackUI("battle.battle_end.jf", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		end
	end,
	[game.GATE_TYPE.gym] = function(self, results)
		if gGameModel.battle.gym_id and csv.gym.gate[gGameModel.battle.gate_id].npc then
			self.data.actions = results.actions
			return self:_onShowGymLeaderEndView(results)
		end
		if results.result == "win" then
			results.flag = "gym"
			gGameUI:stackUI("battle.battle_end.simple_activity_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
	[game.GATE_TYPE.gymLeader] = function(self, results)
		return self:_onShowGymLeaderEndView(results)
	end,
	[game.GATE_TYPE.crossGym] = function(self, results)
		local crossGymRoles = gGameModel.gym:getIdler("crossGymRoles"):read()
		local gymLeader = crossGymRoles and crossGymRoles[gGameModel.battle.gym_id][1]
		if not gymLeader or gymLeader.record_id ~= gGameModel.battle.defence_record_id then
			results.gymMember = true
		end
		return self:_onShowGymLeaderEndView(results)
	end,
	[game.GATE_TYPE.crossMine] = function(self, results)
		results.flag = "crossMine"
		if results.result == "win" then
			if self.modes.isRecord then
				gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
			else
				gGameUI:stackUI("battle.battle_end.pvp_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
			end
		else
			gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
		end
	end,
	[game.GATE_TYPE.crossMineBoss] = function(self, results)
		gGameUI:stackUI("battle.battle_end.daily_activity", nil, gateEndStyles, self.sceneID, results):z(999)
	end,
	[game.GATE_TYPE.braveChallenge] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.brave_challenge_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
	[game.GATE_TYPE.summerChallenge] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.activity_challenge_win", nil, gateEndStyles, self.sceneID, self.data, results):z(999)
		else
			gGameUI:stackUI("battle.battle_end.pvp_fail", nil, gateEndStyles, self.sceneID, self.data, results):z(999):initModes(self.modes)
		end
	end,
	[game.GATE_TYPE.hunting] = function(self, results)
		if results.result == "win" then
			gGameUI:stackUI("battle.battle_end.hunting_win", nil, gateEndStyles, self, self.sceneID, self.data, results):z(999)
		else
			self:jumpToPveFailView(results, 3)
		end
	end,
}
gateEndFuncs[game.GATE_TYPE.dailyExp] = gateEndFuncs[game.GATE_TYPE.dailyGold]
gateEndFuncs[game.GATE_TYPE.fragment] = gateEndFuncs[game.GATE_TYPE.gift]
gateEndFuncs[game.GATE_TYPE.simpleActivity] = gateEndFuncs[game.GATE_TYPE.gift]
gateEndFuncs[game.GATE_TYPE.huoDongBoss] = gateEndFuncs[game.GATE_TYPE.gift]

local gateEndErrorFuncs = {
	backToView = function()
		gGameUI:switchUI("city.view")
	end
}

function BattleView:_onShowRewardEndView(results)
	results.showReward = false
	gateEndFuncs[self.gateType](self, results)
end

function BattleView:postEndResultToServer(url, cbOrT, ...)
	checkGGCheat()

	if type(cbOrT) == "function" then
		local cb = cbOrT
		return gGameApp:requestServer(url, function(tb)
			cb(tb)
		end, ...)
	end

	local req = gGameApp:requestServerCustom(url):params(...)
	local cb = cbOrT.cb
	cbOrT.cb = nil
	cbOrT.onErrClose = cbOrT.onErrClose or gateEndErrorFuncs.backToView
	-- see requestFuncs
	-- {onErrClose = f} -> req.onErrClose(req, f)
	for k, v in pairs(cbOrT) do
		req[k](req, v)
	end
	return req:doit(cb)
end

function BattleView:showEndView(results)
	-- 战斗结算界面时间倍率应该维持正常值
	display.director:getScheduler():setTimeScale(1)

	audio.stopMusic()		-- 进入结算界面 停止战斗的背景音乐

	-- 隐藏界面ui和角色等
	self:showMainUI(false)
	self.gameLayer:setVisible(false)
	self.effectLayer:setVisible(false)
	self:onViewProxyNotify("showSpec", false)

	-- 如果在onUpdate里removeSelf会导致崩溃
	-- 先unscheduleUpdate，然后延迟到下帧进行switchUI
	self:disableUpdate()
	performWithDelay(self, function()
		if gateEndFuncs[self.gateType] and not self.modes.fromRecordFile then --本地保存战报直接切回主场景
			gateEndFuncs[self.gateType](self, results)
		else
			gateEndFuncs[game.GATE_TYPE.test](self, results)
		end
	end, 0)
end

-- 显示精灵捕捉提示
function BattleView:showCaptureTips(oldCapture)
	if not dataEasy.isUnlock(gUnlockCsv.limitCapture) then
		return
	end
	local newCapture = gGameModel.capture:read("limit_sprites")
	for i, capture in pairs(newCapture) do
		--新的精灵
		if not itertools.equal(capture, oldCapture[i]) then
			gGameUI:stackUI("common.capture_tips")
			break
		end
	end
end

function BattleView:newbieEndPlayAni()
	display.director:getScheduler():setTimeScale(1)
	--隐藏界面UI
	self:showMainUI(false)
	local function addEffect(name, action, zOrder)
		return widget.addAnimationByKey(self.frontStageLayer, name, "effect" .. zOrder, action, zOrder)
			:xy(display.center)
			:scale(2)
	end
	audio.playEffectWithWeekBGM("newbie_finish.mp3")
	addEffect("koudai_beijing/huangtu.skel", "gaoguangshike", 1)
	addEffect("koudai_beijing/changguan.skel", "gaoguangshike", 2)
	addEffect("koudai_beijing/huangtu.skel", "gaoguangshike_qian", 3)
	addEffect("koudai_beijing/shuizhu.skel", "gaoguangshike", 4)
	addEffect("newguide/gaoguangshike.skel", "gaoguangshike", 5)
	addEffect("koudai_beijing/shuizhu.skel", "gaoguangshike_qian", 6)
end

function BattleView:getEffectEventEnable()
	return self.effectEventEnable
end

function BattleView:closeEffectEventEnable()
	self.effectEventEnable = false
	return self.effectEventEnable
end

function BattleView:resetEffectEventEnable()
	self.effectEventEnable = true
	return self.effectEventEnable
end

function BattleView:hasGuide()
	if self.isGuideScene ~= nil then return self.isGuideScene end
	local cfg = gMonsterCsv[self.sceneID][1]
	self.isGuideScene = battleEasy.ifElse(cfg.storys,true,false)
	return self.isGuideScene
end

function BattleView:getGymDeployType()
	if self.gymDeployType then
		return self.gymDeployType
	end
	self.gymDeployType = -1
	if self.gateType == game.GATE_TYPE.gym then
		local cfg = csv.gym.gate[self.sceneID]
		self.gymDeployType = cfg and cfg.deployType
	end
	return self.gymDeployType
end

-- function BattleView:isOperateForceMirror()
-- 	return self:getPlayModel().operateForce == 2
-- end

-- mode {
-- 	1 三按钮模式
-- 	2 双按钮模式
-- 	3 点击背景退出
-- }
function BattleView:jumpToPveFailView(results, mode)
	gGameUI:stackUI("battle.battle_end.pve_fail", nil, gateEndStyles, self, results, mode):z(999)
end

function BattleView:getAssignLayer(assignLayer)
	local AssignLayer = {
		[battle.AssignLayer.stageLayer] = self.stageLayer,
		[battle.AssignLayer.gameLayer] = self.gameLayer,
		[battle.AssignLayer.effectLayerLower] = self.effectLayerLower,
		[battle.AssignLayer.effectLayer] = self.effectLayer,
		[battle.AssignLayer.frontStageLayer] = self.frontStageLayer,
	}
	return AssignLayer[assignLayer]
end

-- 跳过一波
function BattleView:onPassOneWaveClean()
	self:flushAllDeferList()
	for k,v in ipairs(self.effectJumpCache) do
		self:onEventEffectCancel(v)
	end
	self.effectJumpCache = {}

	self.effectManager:passOneWaveClear()
end

function BattleView:forceClearBuffEffects()
	local buffEffectLists = {
		self.buffEffectsSelfMap,
		self.buffEffectsEnemyMap,
		self.buffEffectsMap,
	}
	for _, list in ipairs(buffEffectLists) do
		for key, sprite in pairs(list) do
			sprite.buffUseSameResCount = 0
			removeCSprite(sprite)
		end
		list = {}
	end
	self.buffEffectsRef = {}
	self.buffEffectsSelfRef = {}
	self.buffEffectsEnemyRef = {}
end

require "battle.app_views.battle.view_effect"
require "battle.app_views.battle.view_proxy"

return BattleView
