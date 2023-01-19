--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
--
-- 场景
-- 管理object生命周期
-- 维护一些全局对象
--


globals.SceneModel = class("SceneModel")

function SceneModel:ctor()
	self.framesInScene = 0 -- 只是记录用，不要用于逻辑

	self.heros = CMap.new()  --只有友方主角
	self.enemyHeros = CMap.new() --只有敌方主角
	self.backHeros = CMap.new() -- 离场的单位
	self.extraHeros = CMap.new() -- 额外单位
	self.herosOrder = nil -- force 1和2 的 order

	self.autoFight = false -- 是否自动战斗
	self.sceneID = nil -- 场景ID, csv.scene_conf
	self.play = nil -- 战斗玩法(关卡，活动，pvp)
	self.inputs = {} -- 玩家操作输入 {{skill=1, target=7}, }
	self.guide = nil -- 引导
	self.updateResumeStack = {}
	self.isFirstLoad = true

	self.placeIdInfoTb = {} --保存角色的位置信息 {[id]={}，}
	self.deadObjsToBeDeleted = {} --保存回合内要删除的角色, 在回合结束时删除 {obj, obj}
	self.deferListInBattleTurn = {}

	self.allBuffs = self:createBuffCollection()	-- 保存所有的buff, buff.id排序
	self.fieldBuffs = self:createBuffCollection()  -- 保存所有场地buff
	self.needToDelBuffIDs = {}	-- 只保存要删除的buff的CntId的

	self.totalDamage = {}	-- 记录目标受到的累计伤害,用来统计用 格式:{[wave]={[objId]=val}} (暂时没加,后面加)

	self.forceRecordTb = {{},{}}		-- 保存阵营相关的一些记录,方便使用的,且可以少设置一些变量. 比如全队共享护盾的buff,可以记录到这里面
	self.buffGlobalManager = BuffGlobalModel.new() --buff相关的全局逻辑 比如一场战斗同cfgID限定的触发次数
	self.forceRecordObject = {}
	self.deferBeAttackList = {}
	self.beAttackZOrder = 0
	self.realDeathRecordTb = {} -- 死亡顺序
	self.extraRecord = BattleExRecord.new()
	self.extraRoundMode = nil

	self.replaceGroupBuffIdMap = nil
	self.maxReplaceGroupBuffId = -1

	self.cowEnableCount = 0 --cow生效计数
	self.hasSendRecord = false
end

function SceneModel:init(sceneID, data, isRecord)
	self.isRecord = isRecord
	self.data = data or {}
	self.battleID = data.battleID
	self.sceneID = sceneID
	self.gateType = data.gateType or csv.scene_conf[sceneID].gateType
	self.sceneConf = csv.scene_conf[sceneID] or csv.endless_tower_scene[sceneID]
	self.sceneTag = self.sceneConf.tag or {}
	self.sceneLevel = self.sceneConf.sceneLevel
	self.showLevel = self.sceneConf.showLevel
	self.skillLevel = self.sceneConf.skillLevel
	self.closeRandFix = data.closeRandFix
	if self.sceneConf.sceneLevelCorrect then
		local cfg = csv.scene_level_correct[data.levels[1]]
		if cfg[self.sceneConf.sceneLevelCorrect] then
			self.sceneLevel = cfg[self.sceneConf.sceneLevelCorrect]
		end
	end

	-- gate
	if isRecord then
		self.play = newRecordPlayModel(self, self.gateType)
	else
		self.play = newPlayModel(self, self.gateType)
	end
	self.play:init(self.data)

	self.guide = BattleGuideModel.new(self)
	self.guide:init(self.play)

	gRootViewProxy:proxy():showMainUI(false)
	-- 等待上面的动画完成后再更新model
	self:waitInitAniDone()
end

function SceneModel:modelWait(type, f)
	log.battle.scene.wait(type)

	table.insert(self.updateResumeStack, {
		type = type,
		resume = f,
	})
	gRootViewProxy:proxy():onModelWait(type)
end

function SceneModel:modelResume()
	local size = table.length(self.updateResumeStack)
	if size > 0 then
		local wait = self.updateResumeStack[size]
		local resume = wait.resume
		table.remove(self.updateResumeStack)
		log.battle.scene.resume(wait.type, size - 1)
		if size > 1 then
			wait = self.updateResumeStack[size-1]
			-- gRootViewProxy:proxy():onModelWait(wait.type)
		end
		resume(self, true)
		return true
	end
	return false
end

function SceneModel:insertPlayCustomWait(type, resume)
	self:modelWait(type, function(self, continue)
		if continue then
			return resume()
		end
	end)
end


-- 让时间停一会儿
function SceneModel:waitInitAniDone(continue)
	-- wait view
	if not continue then
		return self:modelWait('scene_init', self.waitInitAniDone)
	end

	self:start()
end

-- 获取单方阵营数据map
-- @param: force 1己方 2敌方
function SceneModel:getHerosMap(force)
	return (force == 1) and self.heros or self.enemyHeros
end

function SceneModel:getHerosMapBySeat(seat)
	return seat > 6 and self.enemyHeros or self.heros
end


-- 获取object 原 getObjectIncludeDeadById
function SceneModel:getObject(id)
	local obj = self.heros:find(id) or self.enemyHeros:find(id) or self.extraHeros:find(id)
	return obj
end

-- 返回存活目标 原 getObjectById
function SceneModel:getObjectExcludeDead(id)
	local obj = self:getObject(id)
	if obj and not obj:isAlreadyDead() then
		return obj
	end
end

-- 通过单位位置获取单位 原 getObjectIncludeDead
function SceneModel:getObjectBySeat(seat, type)
	local maps
	type = type or battle.ObjectType.Normal
	if type == battle.ObjectType.SummonFollow then -- extraHeros
		maps = self.extraHeros
	else	-- heros enemyHeros
		maps = self:getHerosMapBySeat(seat)
	end
	for _, obj in maps:order_pairs() do
		if obj.seat == seat then
			return obj
		end
	end
end

-- 通过单位位置获取存活单位 原 getObject
function SceneModel:getObjectBySeatExcludeDead(seat, type)
	local obj = self:getObjectBySeat(seat, type)
	if obj and not obj:isAlreadyDead() then
		return obj
	end
end

-- 获取单方阵营存活的object数量
function SceneModel:getForceNum(force)
	local map = self:getHerosMap(force)
	local ret = 0
	for _, obj in map:order_pairs() do
		if obj and not obj:isAlreadyDead() then
			ret = ret + 1
		end
	end
	return ret
end

-- 获取单方阵营的object数量
function SceneModel:getForceNumIncludeDead(force)
	local map = self:getHerosMap(force)
	local ret = 0
	for _, obj in map:order_pairs() do
		if obj then
			ret = ret + 1
		end
	end
	return ret
end

function SceneModel:getForceIDs(force)
	local forces = self:getHerosMap(force)
	return itertools.keys(forces)
end

-- 获取单方阵营存活的某特定natureType的object数量 双属性只要一个符合就好
function SceneModel:getForceNumWithSpecNatureType(force,natureType)
	local map = self:getHerosMap(force)
	local ret = 0
	local function hasNatureType(obj,natureType)
		return (obj:getNatureType(1) == natureType) or (obj:getNatureType(2) == natureType)
	end
	for _, obj in map:order_pairs() do
		if obj and not obj:isAlreadyDead() and hasNatureType(obj,natureType)  then
			ret = ret + 1
		end
	end
	return ret
end

-- 当前处于额外回合
function SceneModel:beInExtraAttack()
	return self.extraRoundMode
end
-- 某一竖排剩余角色数 row = 1 前排 2后排
function SceneModel:getRowRemain(force,row)
	local map = self:getHerosMap(force)
	local ret = {}
	local tb = {
		{{min = 1,max = 3},{min = 4,max = 6}},
		{{min = 7,max = 9},{min = 10,max = 12}}
	}
	for _, obj in map:order_pairs() do
		local rowRange = tb[force][row]
		if obj and not obj:isAlreadyDead() and (obj.seat <= rowRange.max and obj.seat >= rowRange.min) then
			table.insert(ret, obj)
		end
	end
	return table.length(ret), ret
end

-- 某一横排剩余角色数 column从1到3代表屏幕从上往下
function SceneModel:getColumnRemain(force,column)
	local map = self:getHerosMap(force)
	local ret = {}
	for _, obj in map:order_pairs() do
		if obj and not obj:isAlreadyDead() and ((obj.seat + 2)%3 == (column - 1)) then
			table.insert(ret, obj)
		end
	end
	return table.length(ret), ret
end

--某一阵营的战斗力总和
function SceneModel:getTotalForceFightPoint(force)
	local heros = self:getHerosMap(force)
	local ret = 0
	for _, obj in heros:order_pairs() do
		ret = ret + obj.fightPoint
	end
	return ret
end

-- 玩家操作输入
-- @param: input {skill=1, target=7}
function SceneModel:addInput(input)
	if self.play:isMyTurn() or self.fullManual then
		table.insert(self.inputs, input)
	end
end

function SceneModel:start()
	self:newWave()
end

function SceneModel:over(continue)
	if not continue then
		return self:modelWait('battle_over', self.over)
	end

	self.guide:checkGuide(function()
		self.play:onOver()
	end, {round = battle.GuideTriggerPoint.End})
end

function SceneModel:newWave(continue)
	log.battle.scene(' ______________________________________ scene newWave =', self.play.curWave, continue, self.play:isPlaying())

	-- wait view
	if not continue and self.play:isPlaying() then
		return self:modelWait('new_wave', self.newWave)
	end

	gRootViewProxy:proxy():clearDeleteObjLayer()
	-- 隐藏ui面板
	gRootViewProxy:proxy():showMainUI(false)
	self.play:onNewWavePlayAni()
end

function SceneModel:waitNewWaveAniDone(continue)
	-- wait view
	if not continue and self.play:isPlaying() then
		return self:modelWait('new_wave_play_ani', self.waitNewWaveAniDone)
	end

	gRootViewProxy:proxy():showMainUI(true)
	gRootViewProxy:notify('showMain', false)				-- 增加一条隐藏技能栏 技能栏会在之后的逻辑中重新出现
	gRootViewProxy:proxy():showSpeedRank(false)

	-- 每个波次显示后，角色未入场前引导检测
	self.guide:checkGuide(function()
		self.play:onNewWave()
	end, {round = battle.GuideTriggerPoint.Start})
end

function SceneModel:newRound(continue)
	log.battle.scene(' ______________________________________ scene newRound =', self.play.curRound, continue, self.play:isPlaying())

	--表现效果播放 此时是上回合结束时的一些表现
	-- self:pushCurPlayFuncsToQueue()
	gRootViewProxy:proxy():flushAllDeferList()

	-- wait view
	if not continue and self.play:isPlaying() then
		return self:modelWait('new_round', self.newRound)
	end
	-- 新的一回合时, 清掉记录
	self.deadObjsToBeDeleted = {}

	-- 打印属性
	lazylog.battle.scene("newRound objs", function()
		for _, obj in self.heros:order_pairs() do
			printDebug(' --- 己方: id=%s, hp=%s, atk=%s, def=%s', obj.id, obj:hp(), obj:damage(), obj:defence())
		end
		for _, obj in self.enemyHeros:order_pairs() do
			printDebug(' --- 敌方: id=%s, hp=%s, atk=%s, def=%s', obj.id, obj:hp(), obj:damage(), obj:defence())
		end
	end)


	-- 触发回合被动技能
	-- 触发每回合的 buff (回合结束和回合开始时是连续的)
	if self.play.curRound > 0 then
		self:updateBuffEveryRound(battle.BuffTriggerPoint.onRoundEnd)
	end
	-- 检测目标是否死亡
	self:checkObjsDeadState()

	--表现效果播放
	gRootViewProxy:proxy():flushAllDeferList()

	self.play:onNewRound()
end

function SceneModel:newRoundBattleTurn(continue)
	if not continue and self.play:isPlaying() then
		return self:modelWait('new_round_battle_turn', self.newRoundBattleTurn)
	end

	-- 每个回合角色入场后引导检测
	self.guide:checkGuide(function()
		self:newBattleTurn()
	end)
end

-- 一回合战斗中的各个单位行动的顺序轮次
-- 每一回合场上的单位都会按顺序排序后依次进行攻击
function SceneModel:newBattleTurn(continue)
	log.battle.scene(' ______________________________________ scene newBattleTurn =', self.play.curBattleRound, continue, self.play:isPlaying())

	gRootViewProxy:proxy():flushAllDeferList()

	-- wait view
	if not continue and self.play:isPlaying() then
		return self:modelWait('new_battle_turn', self.newBattleTurn)
	end

	-- 新的战斗回合时, 清掉记录
	self.deadObjsToBeDeleted = {}
	self.realDeathRecordTb = {}

	self.inputs = {}

	-- 打印属性
	lazylog.battle.scene("newBattleTurn objs", function()
		for _, obj in self.heros:order_pairs() do
			print(' --- 己方:', obj.id, obj:hp())
		end
		for _, obj in self.enemyHeros:order_pairs() do
			print(' --- 敌方:', obj.id, obj:hp())
		end
	end)

	self.play:onNewBattleTurn()

	gRootViewProxy:proxy():flushAllDeferList()
end

-- 等待小回合开始节点因buff触发死亡的精灵动画播放完
function SceneModel:waitNewBattleRoundAniDone(continue)
	-- wait view
	if not continue and self.play:isPlaying() then
		return self:modelWait('new_battle_turn_play_ani', self.waitNewBattleRoundAniDone)
	end

	self.play:newBattleTurnGoon()
end

function SceneModel:onSubModulesNewBattleTurn2()
	gRootViewProxy:notify("playExplorer")
end

function SceneModel:onSubModulesNewBattleTurn()
	local obj = self.play.curHero
	local args = {
		totalWave = self.play.waveCount,
		wave = self.play.curWave,
		roundLimit = self.play.roundLimit,
		curRound = self.play.curRound,
		curTurn = self.play.curTurn, 		-- 需要修改 curBattleRound

		battleRound = self.play.curBattleRound,			-- 准备去掉
		round = self.play.curRound,						-- 准备去掉

		obj = obj,
		skillsOrder = obj.skillsOrder,
		immuneInfos = self:immuneInfosToCurHeroSkills(),
		skillsStateInfoTb = obj.skills,		-- 每回合技能状态数据
		isTurnAutoFight = self.play:isNowTurnAutoFight(), 	-- 是否自动攻击
	}

	-- 战斗回合开始前收集的表现播放
	for _,v in ipairs(self.deferListInBattleTurn) do
		-- battleEasy.deferCallback(v.func)
		-- 后续flushCurDeferList会导致二次排队了
		battleEasy.effect(nil,v.func)
	end
	self.deferListInBattleTurn = {}
	battleEasy.queueNotify('newBattleRound', args) --对所有battle/view的子模块进行广播
	battleEasy.queueNotify("showSpec", true)
	-- battleEasy.queueEffect('delay', {lifetime=150})
end

-- 对于curHero的技能 其他objs的免疫信息
function SceneModel:immuneInfosToCurHeroSkills()
	local ret = {}
	local curHero = self.play.curHero
	for _, skillID in ipairs(curHero.skillsOrder) do
		skillID = curHero.skillsMap[skillID] or skillID
		ret[skillID] = {}
		for _, obj in self:ipairsHeros() do
			ret[skillID][obj.id] = obj:selectTextImmuneInfo(skillID)
		end
	end
	return ret
end

function SceneModel:addObjToBeDeleted(obj)
	self.deadObjsToBeDeleted[obj.id] = obj
end

function SceneModel:addObjViewToBattleTurn(obj,msg, ...)
	local f = functools.handler((obj and obj.view or gRootViewProxy), "notify", msg, ...)
	table.insert(self.deferListInBattleTurn, {func = f,source = (obj and obj.id or "global")})
end

function SceneModel:addCallBackToBattleTurn(f)
	table.insert(self.deferListInBattleTurn, {func = f,source = "global"})
end

function SceneModel:addListViewToBattleTurn(obj, list)
	-- 防止只跑逻辑时 报错
	battleEasy.effect(nil,function()
		if not list then return end
		for k,v in list:ipairs() do
			table.insert(self.deferListInBattleTurn, {func = v.func,source = (obj and obj.id or "global")})
		end
	end)
end

function SceneModel:setDeathRecord(obj,order)
	local objStr = tostring(obj)
	for _,v in ipairs(self.realDeathRecordTb) do
		if v.tag == objStr and order < v.order then
			-- print("!!!!!!!!!!!! update setDeathRecord",obj.id,order)
			v.order = order
			return
		end
	end
	-- print("!!!!!!!!!!!! setDeathRecord",obj.id,order)
	table.insert(self.realDeathRecordTb,{
		order = order,
		tag = objStr,
		id = obj.id,
		force = obj.force
	})
end

function SceneModel:endBattleTurn()
	--battleEasy.queueNotify("playExplorer")
	--收集死亡表现应该在battleTurn表现完成之后
	battleEasy.queueEffect(function()
		-- 战斗回合收集的表现播放
		for _,v in ipairs(self.deferListInBattleTurn) do
			battleEasy.deferCallback(v.func)
		end
		self.deferListInBattleTurn = {}
		gRootViewProxy:proxy():flushAllDeferList()
	end)

	-- 处理死亡
	local deletedCount = 0
	for _, obj in pairs(self.deadObjsToBeDeleted) do
		self:onObjDeath(obj)
		deletedCount = deletedCount + 1
	end

	self:checkBackStageObjs()

	-- -- 刷新光环
	-- for _, buff in self.allBuffs:order_pairs() do
	-- 	if buff.isAuraType then
	-- 		buff:refreshAuraRef(-buff.auraRef)
	-- 		buff:overClean()
	-- 	end
	-- end

	for _, obj in self:ipairsHeros() do
		obj:onPassive("Aura")
	end

	-- 有角色死亡时
	if deletedCount > 0 then
		self.deadObjsToBeDeleted = {}
	end

	battleEasy.queueNotify('battleTurnEnd')

	battleEasy.logHerosInfo(self)
end

function SceneModel:onObjDeath(obj)
	local objMap = self:getHerosMap(obj.force)
	local ret = objMap:erase(obj.id) or obj.seat > 12
	if ret then
		self.herosOrder = nil
		battleEasy.queueEffect(function()
			if obj.seat > 12 then
				self:onGroupObjDead(obj)
			else
				battleEasy.queueZOrderNotify('sceneDeadObj',battle.EffectZOrder.dead, tostring(obj), obj)
			end
		end)
	end
	local exRet = self.extraHeros:erase(obj.id)
	if exRet then
		battleEasy.queueEffect(function()
			battleEasy.queueZOrderNotify('sceneDeadObj',battle.EffectZOrder.dead, tostring(obj), obj)
		end)
	end
end

function SceneModel:onGroupObjDead(obj)
	battleEasy.queueEffect(function()
		obj:playStateView()
	end,{zOrder = battle.EffectZOrder.dead})
end

-- 直接删除角色,用于波次刷新把场上旧的目标清除掉时(这里不需要加入队列)
function SceneModel:onObjDel(obj)
	local objMap = self:getHerosMap(obj.force)
	if objMap:erase(obj.id) then
		self.herosOrder = nil
		obj:processRealDeathClean()

		-- 组件清理
		-- 后续无法接受和产生event
		battleComponents.unbindAll(obj)
		gRootViewProxy:notify('sceneDelObj', tostring(obj))
	end
end

function SceneModel:addObj(force, obj)
	self.herosOrder = nil
	self:getHerosMap(force):insert(obj.id, obj)
end

function SceneModel:addExtraObj(force, obj)
	self.extraHeros:insert(obj.id, obj)
end

function SceneModel:addBackStageObj(obj)
	self.herosOrder = nil
	self.backHeros:insert(obj.id, obj)
end

-- 战斗结束
function SceneModel:playEnd(continue)
	if not continue then
		return self:modelWait('play_end', self.playEnd)
	end

	printInfo("\n\n\t\tbattle %s over - id=%s, scene=%s, frame=%s, rndcnt=%s, result=%s, star=%s\n\n", self.isRecord and "record" or "", stringz.bintohex(self.battleID or ""), self.sceneID, self.framesInScene, ymrand.randCount, self.play.result, self.play.gateStar)
	ymrand.randCount = 0

	-- 部分数据清理 -- 貌似也不用清理,每场战斗都是独立的
	self.isBattleAllEnd = true

	-- 战斗结束的时候再保存界面引导，战斗中杀进程重进重新执行之前的引导
	gGameUI.guideManager:battleStageSave(function()
		-- 需不需要发送数据，跟scene没毛线关系
		self.play:postEndResultToServer(functools.partial(self.showBattleEndView, self))
	end)
end

function SceneModel:showBattleEndView(endInfos, serverData, oldCapture)
	-- 复制结束时的数据
	local resultsData = endInfos or {}
	resultsData.serverData = serverData
	resultsData.oldCapture = oldCapture
	-- 显示结束界面
	-- 如果有view情况下，必然用raw()来显式界面，不管是不是modelOnly
	-- 反作弊下v=nil，会用vproxy跳过
	gRootViewProxy:raw():showEndView(resultsData)
end

--每帧主循环更新，维护各阶段状态的更新以及战斗UI等状态更新
function SceneModel:update(delta)
	self.framesInScene = self.framesInScene + 1

	-- 预先清理下buff
	self:preDelBuff()

	if self:modelResume() then
		return
	end

	if not self.play:isPlaying() then
		return
	end

	if self.play:runOneFrame() then
		return
	end

	-- if gGameModel.battle and gGameModel.battle.runOneFrame then
	-- 	gGameModel.battle:runOneFrame(self.play)
	-- 	return
	-- end

	if self.play:isMyTurn() or self.fullManual then
		-- wait input
		if self.autoFight then
			-- self.handleInput = {0,0}
			self.play:setAttack(0,0)
			-- self.play:onceBattle()
		-- elseif self.handleInput then --接受输入
		-- 	self.play:onceBattle(self.handleInput[1], self.handleInput[2])
		-- 	self.handleInput = nil
		end

		if self.play.handleInput then --接受输入
			self.play:onceBattle(self.play.handleInput[1], self.play.handleInput[2])
			self.play.handleInput = nil
		end
	end
end

-- 点击自动按钮触发
-- 如果在己方手动攻击状态，则马上触发自动逻辑 把未攻击的玩家加到攻击队列
-- 如果在己方自动攻击状态，则不能马上切回手动，需等下回合开始才能切换为手动状态
function SceneModel:setAutoFight(flag)
	self.autoFight = flag
end

function SceneModel:setFullManual(flag)
	self.fullManual = flag
end

-- 计算阵营中单位的位置信息中的行列值  PlaceId:1,2,3,4,5,6  7,8,9,10,11,12
function SceneModel:resetPlaceIdInfo(force)
	local retT0 = {}	-- 保存每个位置的信息：1前排，2后排，列1，列2，列3
	local retT = {}		-- 保存阵营中当前还存活的单位
	local heros = self:getHerosMap(force)

	for _, obj in heros:order_pairs() do
		if obj and not obj:isAlreadyDead() then
			retT[obj.seat] = obj
		end
	end

	local hasOnlyOneRow = {false, false}
	local hasOnlyOneColumn = {false, false, false}

	itertools.each(retT, function(seat, _)
		local rowNum = (math.floor((seat+2)/3)-1)%2+1	-- 行数
		local columnNum = (seat-1)%3+1	-- 列数
		retT0[seat] = {}
		retT0[seat].row1 = (rowNum == 1) and 1 or nil
		retT0[seat].row2 = (rowNum == 2) and 2 or nil
		retT0[seat].column1 = (columnNum == 1) and 1 or nil
		retT0[seat].column2 = (columnNum == 2) and 2 or nil
		retT0[seat].column3 = (columnNum == 3) and 3 or nil

		hasOnlyOneRow[1] = retT0[seat].row1 and true or hasOnlyOneRow[1]
		hasOnlyOneRow[2] = retT0[seat].row2 and true or hasOnlyOneRow[2]
		hasOnlyOneColumn[1] = retT0[seat].column1 and true or hasOnlyOneColumn[1]
		hasOnlyOneColumn[2] = retT0[seat].column2 and true or hasOnlyOneColumn[2]
		hasOnlyOneColumn[3] = retT0[seat].column3 and true or hasOnlyOneColumn[3]
	end)

	if not (hasOnlyOneRow[1] and hasOnlyOneRow[2]) then	-- 只有1行时
		itertools.each(retT, function(seat, _)
			retT0[seat].row1 = 1
			retT0[seat].row2 = 2
		end)
	end

	if (hasOnlyOneColumn[1] and not hasOnlyOneColumn[2] and not hasOnlyOneColumn[3]) or
	   (not hasOnlyOneColumn[1] and hasOnlyOneColumn[2] and not hasOnlyOneColumn[3]) or
	   (not hasOnlyOneColumn[1] and not hasOnlyOneColumn[2] and hasOnlyOneColumn[3]) then	-- 只有1列时
		itertools.each(retT, function(seat, _)
			retT0[seat].column1 = 1
			retT0[seat].column2 = 2
			retT0[seat].column3 = 3
		end)
	end
	-- 默认顺便保存一下位置信息
	local startNum = (force == 1) and 0 or self.play.ForceNumber
	for i=1+startNum, self.play.ForceNumber+startNum do
		self.placeIdInfoTb[i] = retT0[i] or {}	-- 保存下当前阵营的位置信息
	end
	return retT0, retT
end

-- 删除某个buff, 先记录起来, 不会立即删除
function SceneModel:deleteBuff(buffID)
	table.insert(self.needToDelBuffIDs, buffID)
end

-- 预先处理buff的删除清理工作
function SceneModel:preDelBuff()
	-- 清理scene中记录所有buff的 buffMap
	for _, buffID in ipairs(self.needToDelBuffIDs) do
		local buff = self.allBuffs:erase(buffID)
		self.fieldBuffs:erase(buffID)
		if buff then
			-- 一般从属于object的，应该已经over过了
			-- 这里只是保证和清理不属于object的
			buff:overClean()
		end
	end
	self.needToDelBuffIDs = {}	--置空
end

function SceneModel:updateBuffByNode(triggerPoint)
	for _, buff in self.allBuffs:order_pairs() do
		buff:update(triggerPoint)
	end
end

-- triggerPoint: 触发点 (见buff中的定义)
-- triggerPriority:优先级区分，可以填数值或者表，数值会自动转为{}
function SceneModel:updateBuffEveryRound(triggerPoint, triggerPriorityRange)
	self:updateBuffByNode(triggerPoint)
end

function SceneModel:updateBuffEveryTurn(triggerPoint)
	self:updateBuffByNode(triggerPoint)
end

-- 触发场上所有单位的被动
function SceneModel:onAllPassive(typ)
	local allPassiveSkills = {}
	local objs = {}
	for _, obj in self:ipairsHeros() do
		if not obj:isAlreadyDead() then
			for _, skill in pairs(obj.passiveSkills) do
				table.insert(allPassiveSkills, skill)
			end
			table.insert(objs, obj)
			obj.triggerEnv[battle.TriggerEnvType.PassiveSkill]:push_back(typ)
		end
	end
	self:sortPassiveSkills(allPassiveSkills)

	for _, skill in ipairs(allPassiveSkills) do
		skill.owner:onOnePassiveTrigger(skill, typ)
	end

	for _, obj in ipairs(objs) do
		obj.triggerEnv[battle.TriggerEnvType.PassiveSkill]:pop_back()
	end
end

-- 根据 被动类型>被动优先级>owner.id>skillID
function SceneModel:sortPassiveSkills(skillList)
	local function more(a, b)
		return a > b
	end
	local function less(a, b)
		return a < b
	end

	local sortFuncs = {
		{getVal = function(skill) return skill.skillType end, checkFunc = less},
		{getVal = function(skill) return skill.cfg.passivePriority end, checkFunc = less},
		{getVal = function(skill) return skill.owner.id end, checkFunc = less},
		{getVal = function(skill) return skill.id end, checkFunc = less},
	}

	table.sort(skillList, function(a, b)
		for k,v in ipairs(sortFuncs) do
			local val1,val2 = v.getVal(a), v.getVal(b)
			if k == #sortFuncs then
				return v.checkFunc(val1,val2)
			end
			if val1 and val2 then
				if val1 ~= val2 then
					return v.checkFunc(val1,val2)
				end
			elseif val1 then
				return true
			elseif val2 then
				return false
			end
		end
	end)
end

-- 检测目标死亡的 (在回合前触发buff或者触发被动技能时,可能有残血目标因此而死亡)
function SceneModel:checkObjsDeadState()
	local hasObj = false
	for _, obj in self:ipairsHeros() do
		if obj then
			hasObj = true
			if obj:isRealDeath() then	-- 真死
				self:onObjDeath(obj)
			end
			local exObj = self:getObjectBySeat(obj.seat, battle.ObjectType.SummonFollow)
			if exObj and exObj:isRealDeath() then
				self:onObjDeath(exObj)
			end
		end
	end

	self:ipairGroupObject(function(obj)
		if self.deadObjsToBeDeleted[obj.id] then
			self:onObjDeath(obj)
			self.deadObjsToBeDeleted[obj.id] = nil
		end
	end)
	self:checkBackStageObjs()

	if hasObj then
		self.play:checkBattleEnd()
	end
end

function SceneModel:getSceneAttrCorrect(force)
	return gSceneAttrCorrect[self.force == 1 and self.sceneID or -self.sceneID] or {}
end

-- 是否是车轮战战斗模式
function SceneModel:isCraftGateType()
	return self.gateType == game.GATE_TYPE.craft
		or self.gateType == game.GATE_TYPE.crossCraft
		or self.gateType == game.GATE_TYPE.crossArena
end

-- 创建 groupObject
function SceneModel:createGroupObj(force, seat)
    self.forceRecordObject[force] = self.forceRecordObject[force] or {}
	if self.forceRecordObject[force][seat] then
		return self.forceRecordObject[force][seat]
	end

    self.forceRecordObject[force][seat] = GroupObjectModel.new(self,force)
	self.forceRecordObject[force][seat]:init()
	self.forceRecordObject[force][seat]:initView()
	return self.forceRecordObject[force][seat]
end

function SceneModel:ipairGroupObject(f)
	for i=battle.SpecialObjectId.teamShiled,battle.SpecialObjectId.teamShiled do
        for force=1,2 do
            local obj = self:getGroupObj(force,i)
			if obj then
				f(obj)
            end
        end
    end
end

-- 获取 groupObject
function SceneModel:getGroupObj(force,seat)
    if self.forceRecordObject[force] then
        return self.forceRecordObject[force][seat]
    end
end
--执行 groupObject 相关的函数
function SceneModel:excuteGroupObjFunc(force,seat,funcName,...)
    local obj = self:getGroupObj(force,seat)
    if obj and obj[funcName] and type(obj[funcName]) == "function" then
        return obj[funcName](obj,...)
    end
    return nil
end
--判断当前buff是否需要走groupObject的逻辑
function SceneModel:getGroupBuffId(easyEffectFunc)
    return ({
        ["teamShield"] = 13
    })[easyEffectFunc]
end
--初始化groupObject
function SceneModel:initGroupObj(buff)
    local force = buff.caster.force
    local specialId = self:getGroupBuffId(buff.csvCfg.easyEffectFunc)
	local obj = self:getGroupObj(force,specialId)
    --buff.unitRes = csvCfg.effectResPath
    local curHero = self.play.curHero
    if curHero then
		buff.isSelfTurn = (curHero.id == buff.holder.id)
	end
    obj:reloadUnit(buff)
end

-- 是否拥有某种类型的buff
function SceneModel:hasTypeBuff(buffType)
	return not self.allBuffs:getQuery()
		:group("easyEffectFunc", buffType)
		:empty()
end
function SceneModel:addObjToExtraRound(obj,order)
	local index = math.max(table.length(self.play.nextHeros) + 1,1)
	table.insert(self.play.nextHeros,(order or index),obj.id)
end

function SceneModel:cleanObjInExtraRound(obj)
	for i=table.length(self.play.nextHeros),1,-1 do
		if self.play.nextHeros[i] == obj.id then
			table.remove(self.play.nextHeros,i)
		end
	end
end

function SceneModel:mergeDeferBeAttack(ret)
	local tempRef = {}

	local function getKey(attackInfo)
		local key1 = attackInfo.attacker and attackInfo.attacker.id
		local key2 = attackInfo.target and attackInfo.target.id
		return key1..key2..attackInfo.damageArgs.skillDamageId
	end

	for i = table.length(ret), 1, -1 do
		local attackInfo = ret[i]
		if attackInfo.canMerge and attackInfo.damageArgs.skillDamageId then
			local key = getKey(attackInfo)
			if not tempRef[key] then
				tempRef[key] = attackInfo
			else
				if attackInfo.damageArgs.isBeginDamageSeg then
					tempRef[key].damageArgs.isBeginDamageSeg = true
				end
				tempRef[key].damage = tempRef[key].damage + attackInfo.damage
				tempRef[key].damageArgs.leftDamage = tempRef[key].damage
				table.remove(ret, i)
			end
		end
	end
end

function SceneModel:deferBeAttack(id,attacker,target,damage,processID,damageArgs, canMerge)
	local attackInfo = {
		attacker = attacker,
		target = target,
		damage = damage,
		processID = processID,
		damageArgs = damageArgs,
		canMerge = canMerge
	}
	if not self.deferBeAttackList[id] then
		self.deferBeAttackList[id] = {}
	end
	damageArgs.beAttackZOrder = damageArgs.beAttackZOrder + 0.5
	table.insert(self.deferBeAttackList[id],attackInfo)
end

function SceneModel:runBeAttackDefer(id)
	self:checkDeferAttackOnDeath(id)
	if self.deferBeAttackList[id] then
		local t = self.deferBeAttackList[id]
		self.deferBeAttackList[id] = {}
		local rebound, others = {}, {}
		for _, attackInfo in ipairs(t) do
			if attackInfo.damageArgs.from == battle.DamageFrom.rebound then
				table.insert(rebound, attackInfo)
			else
				table.insert(others, attackInfo)
			end
		end
		self:mergeDeferBeAttack(others)
		local sortT = arraytools.merge({rebound, others})
		for _,attackInfo in ipairs(sortT) do
			local target = attackInfo.target
			local attacker = attackInfo.attacker
			local damage = attackInfo.damage
			local processID = attackInfo.processID
			local damageArgs = attackInfo.damageArgs
			damageArgs.isDefer = true
			if damageArgs.from == battle.DamageFrom.rebound then
				damage = math.min(damage, target:hp() - 1)
				damage = math.max(damage, 0)
			end
			target:beAttack(attacker,damage,processID,damageArgs)
		end
	end
end

function SceneModel:deleteBeAttackDefer(id, DamageFromExtraType, damageId)
	if self.deferBeAttackList[id] then
		local t = self.deferBeAttackList[id]
		for k = table.length(t), 1, -1 do
			local attackInfo = t[k]
			if attackInfo.damageArgs.fromExtra[DamageFromExtraType] and damageId == attackInfo.damageArgs.damageId then
				table.remove(t, k)
			end
		end
	end
end

-- 死亡触发deferAttack之前
-- 调整对每个单位最后一次伤害参数中isLastDamageSeg为true
-- 否则可能因为deferAttack最后一段丢失无法setDead
function SceneModel:checkDeferAttackOnDeath(id)
	if self.deferBeAttackList[id] then
		local t = self.deferBeAttackList[id]
		local targetMark = {}
		for i=table.length(t),1,-1 do
			local attackInfo = t[i]
			-- rebound伤害都是最后一段 不需要调整
			if attackInfo.damageArgs.from ~= battle.DamageFrom.rebound then
				local target = attackInfo.target
				if not targetMark[target.id] then
					attackInfo.damageArgs.isLastDamageSeg = true
					targetMark[target.id] = true
				end
			end
		end
	end
end

function SceneModel:cleanInWaveGoon()
	if self.play.curWave == 1 then return end
	-- 换波时清除buff
	for _, buff in self.allBuffs:order_pairs() do
		if not buff.isAuraType and not buff.csvCfg.waveInherit then
			buff:overClean()
		end
	end

	self:ipairGroupObject(function(obj)
		if not obj:isDeath() then
			obj.viewAniList:push_back(battle.ObjectState.realDead)
			self:onGroupObjDead(obj)
		end
		obj:init()
	end)

	self.extraRecord:refreshEventRecord(battle.TimeIntervalType.wave)
	-- TODO: 是否清理 或者全部打完?
	-- 切换波次时清理延迟伤害
	self.deferBeAttackList = {}

	gRootViewProxy:proxy():flushCurDeferList()
end

function SceneModel:recordSceneAlterBuff(buffId, buffCfgId)
	if self.replaceGroupBuffIdMap == nil then
		self.replaceGroupBuffIdMap = {
			map = {},
			cache = {}
		}
	end
	self.replaceGroupBuffIdMap.map[buffId] = buffCfgId
	-- buffId be deleted
	if buffCfgId == nil then
		self.maxReplaceGroupBuffId = -1
	else
		if not self.replaceGroupBuffIdMap.cache[buffCfgId] then
			local stageArgs = csv.buff[buffCfgId].stageArgs
			local ret = {}
			if stageArgs[1].buffGroupId then
				for _,v in ipairs(stageArgs[1].buffGroupId[1]) do
					ret[v] = true
				end
				self.replaceGroupBuffIdMap.cache[buffCfgId] = {
					assignGroup = ret,
					convertGroup = stageArgs[1].buffGroupId[2],
				}
			end
		end
		if buffId > self.maxReplaceGroupBuffId then
			self.maxReplaceGroupBuffId = buffId
		end
	end

	-- 因为buffgroup可能发生变化, 所有obj的免疫buff都要刷新
	for _, obj in self.backHeros:order_pairs() do
		obj:clearBuffImmune()
	end
	for _, obj in self:ipairsHeros() do
		obj:clearBuffImmune()
	end
end

function SceneModel:getExistLastSceneAlterBuff()
	if self.replaceGroupBuffIdMap == nil then return -1 end
	if self.maxReplaceGroupBuffId ~= -1 then
		local cfgId = self.replaceGroupBuffIdMap.map[self.maxReplaceGroupBuffId]
		return cfgId,self.replaceGroupBuffIdMap.cache[cfgId]
	end

	-- 获取存在且最新的场景更换buffid
	local maxBuffID = -1
	local buffCfgId = -1
	for k, v in pairs(self.replaceGroupBuffIdMap.map) do
		if k > maxBuffID then
			maxBuffID = k
			buffCfgId = v
		end
	end
	self.maxReplaceGroupBuffId = maxBuffID
	return buffCfgId,self.replaceGroupBuffIdMap.cache[buffCfgId]
end

function SceneModel:updateBeAttackZOrder()
	self.beAttackZOrder = self.beAttackZOrder + 1
end

local FilterObjectMap = {
	[battle.FilterObjectType.noAlreadyDead] = function(obj) return obj and obj:isAlreadyDead() end,
	[battle.FilterObjectType.noRealDeath] = function(obj) return obj and obj:isRealDeath() end,
	-- [battle.FilterObjectType.noBeSelectHint] = function(obj,env)
	-- 	return obj and env and not obj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect,{fromObj = env})
	-- end,
	[battle.FilterObjectType.excludeEnvObj] = function(obj,env)
		if obj and env.fromObj then
			if not env.skillFormulaType or env.skillFormulaType == battle.SkillFormulaType.damage then
				return obj.id == env.fromObj.id
			end
		end
	end,
	[battle.FilterObjectType.excludeObjLevel1] = function(obj,env)
		-- return obj and not obj:checkOverlaySpecBuffExit("leave")
		return obj and obj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect,env)
	end,
}

-- env: 参数 fromObj(筛选发起的对象)
function SceneModel:getFilterObjects(force, env, ...)
	local ret = {}
	-- 遍历全体
	if force == 3 then
		force = 1
		ret = self:getFilterObjects(3-force, env, ...)
	end

	local heros = self:getHerosMap(force)
	for _, obj in heros:order_pairs() do
		local fObj = self:getFilterObject(obj.id, env, ...)
		if fObj then table.insert(ret, fObj) end
	end

	table.sort(ret, function(o1, o2)
		return o1.id < o2.id
	end)

	return ret
end

function SceneModel:getFilterObject(id, env, ...)
	local obj = self:getObject(id)
	local filters = {...}

	if table.length(filters) == 1 and type(filters[1]) == "table" then
		filters = filters[1]
	end

	for _, i in ipairs(filters) do
		-- 满足条件无法添加
		if FilterObjectMap[i](obj, env or {}) then
			return
		end
	end
	return obj
end

function SceneModel:ipairsHeros()
	if self.herosOrder == nil then
		local iter1 = itertools.iter(self:getHerosMap(1):pairs())
		local iter2 = itertools.iter(self:getHerosMap(2):pairs())
		self.herosOrder = itertools.values(itertools.chain({iter1, iter2}))
		table.sort(self.herosOrder, function(o1, o2)
			return o1.id < o2.id
		end)
	end

	return ipairs(self.herosOrder)
end

function SceneModel:createBuffCollection()

	local ret = CCollection.new()
	-- order: iterBuffs
	ret:add_index(CCollection.index.new("buff")
		:order(BuffModel.BuffCmp)
		:default())

	-- hash: buff.csvCfg.easyEffectFunc
	ret:add_index(CCollection.index.new("easyEffectFunc")
		:hash({"csvCfg", "easyEffectFunc"}))

	-- hash: buff.csvCfg.group
	ret:add_index(CCollection.index.new("groupID")
		:hash({"csvCfg", "group"}))

	-- hash: buff.cfgId
	ret:add_index(CCollection.index.new("cfgId")
		:hash("cfgId"))

	return ret
end

function SceneModel:createBuffMap()
	return CMap.new(BuffModel.BuffCmp)
end

-- 检查场外单位是否能进场
function SceneModel:checkBackStageObjs()
	for _, obj in self.backHeros:order_pairs() do
		if obj.frontStageTarget then
			local target = self:getObjectBySeatExcludeDead(obj.frontStageTarget)
			if not target then
				self:addObj(obj.force, obj)
				self.backHeros:erase(obj.id)

				obj:doFrontStage()
			end
		end
	end
end

function SceneModel:overAssignTypeBuffs(type)
	local flag
	if type == 'markId' then
		for _, obj in self:ipairsHeros() do
			local csv = gGameEndSpeRuleCsv[obj.markID]
			if csv then
				for _, cfgId in ipairs(csv.buffID) do
					local buff = obj:getBuff(cfgId)
					if buff then
						if not buff.csvCfg.waveInherit then
							buff:overClean()
						end
					end
				end
			end
		end
	end
end

function SceneModel:waitJumpOneWave(continue)
	if not continue then
		return self:modelWait('jump_wave', self.waitJumpOneWave)
	end
	self.play:onWaveEffectClean()
end

function SceneModel:tirggerFieldBuffs(triggerObject, triggerBuff)
	local triggerPoint = battle.BuffTriggerPoint.onBuffTrigger
	local function triggerFieldBuffOnPoint(buff, obj)
		local trigger = {
			buffId = buff.id,
			obj = obj
		}
		if buff:isTrigger(triggerPoint, trigger) then
			buff:updateWithTrigger(triggerPoint, trigger)
		end
	end

	if triggerObject then
		for _, buff in self.fieldBuffs:order_pairs() do
			triggerFieldBuffOnPoint(buff, triggerObject)
		end
	end
	if triggerBuff then
		for _, obj in self:ipairsHeros() do
			if not obj:isAlreadyDead() and not obj:isLeaveField() then
				triggerFieldBuffOnPoint(triggerBuff, obj)
			end
		end
	end
end

function SceneModel:getExtraBattleRoundMode()
	if self.play.extraBattleRoundData then
		return self.play.extraBattleRoundData.mode
	end
	return nil
end

-- cache.assignGroup = {buff.group: true}
-- cache.convertGroup = int
function SceneModel:getConvertGroupCache()
	-- 场景更换buff效果: 1. 更换场景 2.将属于指定buff组的buff更换组别
	local buffCfgId, cache = self:getExistLastSceneAlterBuff()
	if buffCfgId ~= -1 and cache then
		return cache
	end
	return nil
end

function SceneModel:checkCowWithBuff(buff)
	local result = false
	if buff then
		if not itertools.include(gFormulaConst.Lethalcheck(), buff:group()) then
			return
		end
		result = buff.isOver
	end
	self.cowEnableCount = self.cowEnableCount + battleEasy.ifElse(result, -1, 1)
end

function SceneModel:setCsvObject(obj)
	self.csvObject = obj
end

function SceneModel:getCsvObject()
	return self.csvObject
end

local SceneSendMark = setmetatable({}, {__mode = "k"})
function SceneModel:battleReport(desc, traceback)
	if ANTI_AGENT then return end
	if device.platform == "windows" then return end
	if SceneSendMark[self] or self.isRecord then return end

	SceneSendMark[self] = true

	local record = table.shallowcopy(self.data)
	record.sceneID = self.sceneID or 0
	record.gateType = self.gateType or 0

	battleReport({
		play_record = record,
		traceback = traceback or "",
		desc = desc or "",
	})
end