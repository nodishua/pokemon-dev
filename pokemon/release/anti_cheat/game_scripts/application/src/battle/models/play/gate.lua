--
-- 回合制玩法
-- 进行回合制逻辑
--

-- 站位
--[[
4 1    7 10
5 2 vs 8 11
6 3    9 12
]]--


local Gate = class("Gate")
battlePlay.Gate = Gate

Gate.ForceNumber = 6 -- 6人一组
Gate.ObjectNumber = 12 -- 2*ForceNumber

-- 战斗模式设置 (各战斗子类中修改) -- 自动/全手动， 能否暂停， 能否加速, 能否跳过
Gate.OperatorArgs = {
	isAuto 			= true,
	isFullManual	= false,
	canHandle 		= false,
	canPause 		= false,
	canSpeedAni 	= false,
	canSkip 		= false,
}

local EmptyAction = {0,0,0}

local SpecModuleFuncMap = {
	craftMods = {
		refreshUIHp = function(self)
			local selfHpRatio,enemyHpRatio = -1,-1
			local me = self.scene:getObject(self.forceToObjId[1])
			local enemy = self.scene:getObject(self.forceToObjId[2])
			if me then
				selfHpRatio = me:hp() / me:hpMax()
			end
			if enemy then
				enemyHpRatio = enemy:hp() / enemy:hpMax()
			end
			battleEasy.deferNotify(nil, "changeHpMp",{
				selfHpRatio = selfHpRatio,
				enemyHpRatio = enemyHpRatio,
			})
		end,
		refreshUIMp = function(self)
			local selfMpRatio,enemyMpRatio = -1,-1
			local me = self.scene:getObject(self.forceToObjId[1])
			local enemy = self.scene:getObject(self.forceToObjId[2])
			if me then
				selfMpRatio = me:mp1() / me:mp1Max()
			end
			if enemy then
				enemyMpRatio = enemy:mp1() / enemy:mp1Max()
			end
			battleEasy.deferNotify(nil, "changeHpMp",{
				selfMpRatio = selfMpRatio,
				enemyMpRatio = enemyMpRatio,
			})
		end,
		newWaveAddObjsStrategy = function(gate)
			if gate.curWave == 1 then
				battleEasy.deferNotify(nil, "initPvp")
			end
			gate:refreshUIHp()
			gate:refreshUIMp()
		end
	}
}

Gate.CommonArgs = {
	AntiMode = battle.GateAntiMode.Normal	-- 是否需要记录操作
}

Gate.UIOpition = {
	craftMods = false
}

Gate.PlayCsvFunc = {}
Gate.SpecEndRuleCheck = {}
Gate.SpecEndRuleCheckArgs = {}
-- 暂停重开相关逻辑
-- battle\view下的是否是PVPScene相关逻辑

function Gate:ctor(scene)
	self.scene = scene
	self.waveCount = scene.sceneConf.sceneCount
	self.roundLimit = scene.sceneConf.roundLimit

	self.curWave = 0 -- 波数
	self.curRound = 0 -- 大回合数(用作显示和当前回合判定)
	self.curBattleRound = 0 -- 战斗回合数
	self.totalRound = 0 --用于计算BUFF周期和跨波次技能
	self.totalRoundBattleTurn = 0

	self.curHero = nil -- 当前战斗回合英雄
	self.nextHeros = {} -- 额外回合指定英雄 现在用于反击
	self.roundHasAttackedHeros = {} -- 已经出手的序列
	self.roundLeftHeros = {} -- 大回合未出手对象{{obj:obj, reset:buffid, atOnce:buffid, ...}, ...}
	self.roundHasAttackedHistory = {} -- 已经出手的记录
	self.attackerArray = {} -- 排序后的攻击者序列 {obj, ...}
	self.result = nil -- 结果
	self.nowChooseID = nil --保存当前选择的目标,给某些技能选目标时作为参照物
	self.curBattleRoundAttack = false
	self.seeBoss = false	-- 是否见到了boss
	self.showBossInfo = false -- 是否显示BOSS详情面板
	self.battleTurnInfoTb = {}	-- 用于汇总记录到每个turn中的数据, 新turn时清空 (如果是不需要清空的数据,就不放这个里面了)

    self.speedSortRule = {}

	self.statsRecordTb = {}		--	用于记录数据, 格式: {key={{force1的}, {force2的}}}
								-- 一般是留给结束或者给服务器用的,不要和scene里的记录混了
	self.forceAdd = {}			-- 用于记录单位的进场，每次使用后重置
	self.recoverMp2RoundLimit = 3 -- 限定三回合 每回合回蓝add
	self.operateForce = scene.data.operateForce or 1 		--操作阵营
	self.handleInput = {}
	self.ruleRecordData = {}
	self.curHeroRoundInfo = {} -- 当前回合出手单位的排序信息 格式同roundLeftHeros
	self.attackSign = {}
	self.hasAttackedSign = {}
	self.lethalDatas = {}  -- 记录致死保护的单位
	self.actionSend = {}
	self.specModuleFunc = nil
	self.battleRoundTriggerId = nil -- 标记特殊回合对应的buff,被动技能触发表id
end

function Gate:initFightOperatorMode()
	local opeArgs = {}
	local lockAutoFight = self.scene.sceneTag or {}
	for k,v in pairs(self.OperatorArgs) do
		opeArgs[k] = v
	end
	-- 配表设置 关卡是否锁定自动战斗
	opeArgs.canHandle = battleEasy.ifElse(lockAutoFight.canHandle~=nil,lockAutoFight.canHandle,opeArgs.canHandle)
	opeArgs.isAuto = battleEasy.ifElse(lockAutoFight.isAuto~=nil,lockAutoFight.isAuto,opeArgs.isAuto)

	-- 战斗模式设置1 默认为全自动
	self.scene:setAutoFight(opeArgs.isAuto)
	-- 战斗模式设置2 全手动
	self.scene:setFullManual(opeArgs.canHandle and opeArgs.isFullManual)
	gRootViewProxy:notify('setOperators', opeArgs)
end


-- 设置界面的初始化数据 (先隐藏第一个攻击者角色的技能栏和行动条, 这两个在战斗开始时设置完再显示)
-- 一些入场动画也放在这里播放,
function Gate:init(data)
	self.data = data

	-- 初始化界面显示数据			-- todo
	self:initFightOperatorMode()

	self:initSpecModule()
	-- self:initCommonPanels()
	-- 附属界面的设置
	-- 总波数显示  total wave
	gRootViewProxy:notify('setWaveNumber', self.curWave, self.waveCount)
	-- 场景ui显示
	gRootViewProxy:proxy():showMainUI(true)

	-- 先获取下场景配表中的星数条件
	-- self:initStarConditions()
end

function Gate:initSpecModule()
	if self.UIOpition.craftMods then
		gRootViewProxy:proxy():addSpecModule(battleModule.craftMods)
		self.specModuleFunc = SpecModuleFuncMap.craftMods
	end

	self:notifyToSpecModule("init")
end

function Gate:notifyToSpecModule(msg, ...)
	if not self.specModuleFunc then return end
	local func = self.specModuleFunc[msg]
	if func then func(self, ...) end
end

function Gate:checkSpecModule(msg)
	return self.UIOpition[msg] or false
end

-- 需要自己手动构造各波怪物数据
function Gate:getEnemyRoleOutT(waveId)
	-- 构造数据
	local enemiesData = {}
	local monsterCfg = self:getMonsterCsv(self.scene.sceneID,waveId)
	if not monsterCfg then return {} end
	self.showBossInfo = monsterCfg.showInfo
	local bossInfos = self.scene.sceneConf.boss
	for idx, unitId in ipairs(monsterCfg.monsters) do
		if unitId > 0 then
			local isBoss = false
			if monsterCfg.bossMark and monsterCfg.bossMark[idx] == 1 then	-- 需要保证只有一个boss
				self.seeBoss = true
				isBoss = true
			end
			local roleData = {
				roleId = unitId,
				level = self.scene.sceneLevel,
				skillLevel = self.scene.skillLevel,
				showLevel = self.scene.showLevel,
				roleForce = 2,
				isMonster = true,
				isBoss = isBoss,
				advance = 0,
			}
			enemiesData[idx+self.ForceNumber] = roleData
		end
	end
	return {[waveId]=enemiesData}
end

-- 添加卡牌角色
function Gate:addCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	local forces = self.scene:getHerosMap((force == self.operateForce) and 1 or 2)
	for _, obj in forces:order_pairs() do
		if not onlyDelDead or obj:isDeath() then
			self.scene:onObjDel(obj)	-- 先删除旧的
		end
	end
	if not onlyDelDead then
		forces:clear()
	end
	self.scene.herosOrder = nil

	local datas = roleOutT or self.data.roleOut
	local wavesData = waveId and datas[waveId] or datas
	local datas2 = roleOutT2 or self.data.roleOut2
	local wavesData2 = waveId and datas2[waveId] or datas2

	local stepNum = (force == 1) and 0 or self.ForceNumber
	local count = 0
	for idx=1+stepNum, self.ForceNumber+stepNum do
		local roleData = wavesData[idx]
		local seat = self.operateForce == 2 and battleEasy.mirrorSeat(idx) or idx
		if roleData then
			count = count + 1
			-- print("!!! TODO addCardRoles dataIdx:",idx,",seat:",seat,",force:",force,forces)
			local obj = self:createObjectModel(force, seat)
			if wavesData2 and next(wavesData2) then
				roleData.role2Data = wavesData2[idx]
			end
			obj:init(roleData)
			forces:insert(obj.id, obj)
			if obj.isBoss then
				self:setBoss(obj)
			end
		end
	end


	if (force == self.operateForce) and (not waveId or waveId == 1) then	-- 记录第一波时的人数
		self.scene.forceRecordTb[1]["herosStartCount"] = count
	end

	self.scene:createGroupObj(force, battle.SpecialObjectId.teamShiled)

	-- 记录本次添加了某一阵营的单位
	table.insert(self.forceAdd, force)
end

function Gate:addCardRole(seat, roleData, onlyDelDead, backStageForce)
	local old = self.scene:getObjectBySeatExcludeDead(seat)
	local oldExtra = self.scene:getObjectBySeatExcludeDead(seat, battle.ObjectType.SummonFollow)
	local isFollowMode = roleData.isFollowMode
	if isFollowMode and oldExtra then return end

	local force = seat > 6 and 2 or 1
	if isFollowMode then
		force = backStageForce
	else
		if old then
			-- 如果需要删除要在添加前将单位设置死亡
			if onlyDelDead then
				self.scene:onObjDel(old)
			else
				return
			end
		end

		-- 添加场外单位
		if backStageForce then
			force = backStageForce
			seat = -1
		end
	end

	if roleData then
		local obj
		if isFollowMode then
			obj = self:createExtraObjectModel(force, seat)
			obj:init(roleData)
			self.scene:addExtraObj(force, obj)
		else
			obj = self:createObjectModel(force, seat)
			obj:init(roleData)
			if backStageForce then
				obj.force = force
				obj.view:proxy():updateFaceTo(obj.force)
				self.scene:addBackStageObj(obj)
			else
				self.scene:addObj(force, obj)
			end
		end
		if obj.isBoss then
			self:setBoss(obj)
		end
		return obj
	end
end

function Gate:setBoss(obj)
	self.curBoss = obj
end

function Gate:createObjectModel(force, seat)
	return ObjectModel.new(self.scene, seat)
end

function Gate:createExtraObjectModel(force, seat)
	return ObjectExtraModel.new(self.scene, seat)
end

-- 关卡属性修正
-- 关卡属性修正
function Gate:doObjsAttrsCorrect(isLeftC, isRightC)
	local sceneID = self.scene.sceneID
	if isLeftC then
		self.scene.forceRecordTb[1]["totalFightPoint"] = self.scene:getTotalForceFightPoint(1)
	end
	-- 场景波次属性修正
	if isRightC then
		local cfg = self:getMonsterCsv(sceneID,self.curWave)
		if cfg then
			for _, obj in self.scene:ipairsHeros() do
				if obj:serverForce() == 2 then
					obj:objAttrsCorrectMonster(cfg)
				end
			end
		end
		self.scene.forceRecordTb[2]["totalFightPoint"] = self.scene:getTotalForceFightPoint(2)
	end

	-- 场景属性修正 -- todo 需要考虑双方是否重置过, 若未重置时不需要再继续修正了
	local cfgl = gSceneAttrCorrect[sceneID]
	local cfgr = gSceneAttrCorrect[-sceneID]

	for _, obj in self.scene:ipairsHeros() do
		if (isLeftC and obj:serverForce() == 1) or (isRightC and obj:serverForce() == 2) then
			local cfg = obj:serverForce() == 1 and cfgl or cfgr
			if cfg then
				obj:objAttrsCorrectScene(cfg)
			end

			-- 战力属性修正
			local objTotalCP = self.scene.forceRecordTb[obj.force]["totalFightPoint"] or 0
			local objEnemyTotalCP = self.scene.forceRecordTb[3-obj.force]["totalFightPoint"] or 0

			if objTotalCP < objEnemyTotalCP then
				obj:objAttrsCorrectCP(objTotalCP, objEnemyTotalCP)
			end
		end

		if not obj:isAlreadyDead() then
            local key = obj.seat
			self.scene.extraRecord:addExRecord(battle.ExRecordEvent.totalHp, obj:hpMax(), key)
		end
	end
end

-- 触发被动技能
function Gate:triggerAllPassiveSkills()
	self.scene:onAllPassive(battle.PassiveSkillTypes.enter)
	for _, obj in self.scene:ipairsHeros() do
		if not obj:isAlreadyDead() then
			obj:initedTriggerPassiveSkill(true)
		end
	end

	self.scene:updateBuffEveryRound(battle.BuffTriggerPoint.onHolderAfterEnter)
end

-- 战斗单位 object 的排序的记录table, 可以直接给 {[1]=obj1,[2]=obj2, ... }用, 不需要每次都排序了
function Gate:getSortOrderTb()
	if self.sortOrderTb then
		return self.sortOrderTb
	end
	return {1,2,3,4,5,6,  7,8,9,10,11,12}	-- 默认的排序
end

-- 使用gate的统一遍历顺序
-- 注意: 这个函数只对战场上的【全体目标】排序时使用, 其它地方不要用这个函数
function Gate:ipairsByGateOrder()
	local order = self:getSortOrderTb()
	local i = 0
	return function()
		i = i + 1
		local idx = order[i]
		local k = idx and i
		return k, idx
	end
end

-- 每一波添加双方角色的设置, 根据不同场景会有不同的变化
-- 具体在各个关卡里面去设置,这里只留着打印信息吧
function Gate:newWaveAddObjsStrategy()
	-- 打印属性
	lazylog.battle.gate.newWave(" ---- 每一波开始时, 打印双方角色未触发被动之前的原始数据(已计算场景修正)：", function()
		for _, obj in self.scene.heros:order_pairs() do
			printDebug(' -- 己方: id=%s, hp=%s, haMax=%s, atk=%s, def=%s, speed=%s',
					obj.id, obj:hp(), obj:hpMax(), obj:damage(), obj:defence(), obj:speed())
		end
		for _, obj in self.scene.enemyHeros:order_pairs() do
			printDebug(' -- 敌方: id=%s, hp=%s, haMax=%s, atk=%s, def=%s, speed=%s',
					obj.id, obj:hp(), obj:hpMax(), obj:damage(), obj:defence(), obj:speed())
		end
	end)

	self:notifyToSpecModule("newWaveAddObjsStrategy")
end


-- 新一波时的动画 等待
-- 流程在下面那个onNewWave()前面
function Gate:onNewWavePlayAni()
	self.curWave = self.curWave + 1		-- 波数增加
	self.curRound = 0					-- 回合数重置
	self.totalRoundBattleTurn = 0
	-- wave的波数设置
	gRootViewProxy:notify('setWaveNumber', self.curWave, self.waveCount)
	gRootViewProxy:notify('playWaveAni', self.curWave, self.waveCount)
	battleEasy.queueEffect('delay', {lifetime=300})

	self.scene:waitNewWaveAniDone()
end

function Gate:playEnterAnimation(cb)
	local selfAdd, enemyAdd = false,false
	for _, f in pairs(self.forceAdd) do
		if f == 1 then
			selfAdd = true
		elseif f == 2 then
			enemyAdd = true
		end
	end
	self.forceAdd = {}
	battleEasy.queueNotify('enterAnimation',
		selfAdd and self.scene:getForceIDs(1) or nil,
		enemyAdd and self.scene:getForceIDs(2) or nil,
		true
	)
	-- cb有model流程不能交给view来控制
	self.scene:insertPlayCustomWait('enter_animation', cb)
end

function Gate:onNewWave()
	-- 初始化双方角色
	battleEasy.queueEffect('delay', {lifetime=1000})

	-- boss 提示和 信息界面(这里放到了加载角色后面,目前角色是直接出现的)
	if self.seeBoss then
		local timeScale = display.director:getScheduler():getTimeScale()
		display.director:getScheduler():setTimeScale(battle.SpeedTimeScale.single)
		battleEasy.queueNotify('showBossComeView', self.showBossInfo)

		self.scene:insertPlayCustomWait('new_wave_see_boss', function()
			display.director:getScheduler():setTimeScale(timeScale)
			self:newWaveAddObjsStrategy()
			self:playEnterAnimation(function()
				self:newWaveGoon()			-- 使用回调的方式来保障入场动画播放完才继续战斗
			end)
		end)
	else
		--TODO:修改buff清理位置，否则会导致event事件报错
		self:newWaveAddObjsStrategy()
		self:playEnterAnimation(function()
			self:newWaveGoon()			-- 使用回调的方式来保障入场动画播放完才继续战斗
		end)
	end
end

-- 新的一波的内容的继续, 上面因为有boss展示信息的存在, 所以要中断下
function Gate:newWaveGoon()
	self:checkGuide(function()
		self.scene:cleanInWaveGoon()

		-- 角色数据重置下
		-- self.scene.buffGlobalManager:cleanBuffTriggerTimeRecord()

		for _,obj in self.scene:ipairsHeros() do
			obj:onNewWave()
		end

		self:newWaveGoonAfter()

	end, {round = battle.GuideTriggerPoint.Wave + self.curWave})
end

function Gate:newWaveGoonAfter()
	--站位的位置数据初始化
	self.scene:resetPlaceIdInfo(1)
	self.scene:resetPlaceIdInfo(2)
	self.scene.realDeadCounter = 1

	-- 清空额外回合数据
	self.nextHeros = {}
	--表现效果播放
	gRootViewProxy:proxy():flushCurDeferList()

	return self.scene:newRound()
end


function Gate:onNewRound()
	self.curRound = self.curRound + 1
	self.totalRound = self.totalRound + 1
	self.curBattleRound = 0
	self.curHero = nil

	-- 第一回合开始 触发进场被动
	if self.curRound == 1 then
		self:triggerAllPassiveSkills()
	end

	self.hasAttackedSign = {}
	-- 每回合剩余英雄数量
	self.roundHasAttackedHeros = {}		-- 每大回合内已经行动过的
	self.roundLeftHeros = {}			-- 每大回合内剩余的
	self.roundHasAttackedHistory = {}
	for _, obj in self.scene:ipairsHeros() do
		if obj and not obj:isRealDeath() then
			table.insert(self.roundLeftHeros, {obj=obj})
		end
	end

	--新回合时也都从新初始化当前的位置,可能某些被动或者buff会在newRound时触发
	self.scene:resetPlaceIdInfo(1)
	self.scene:resetPlaceIdInfo(2)

	-- 在这里开始算下一回合开始, scene 中的 newround() 时, curRound数值还没有+1
	--清除每回合触发次数限制

	for _,obj in self.scene:ipairsHeros() do
		obj:onNewRound()
	end
	-- for _, obj in self.scene.enemyHeros:order_pairs() do
	-- 	obj:onNewRound()
	-- end

	self.scene:updateBuffEveryRound(battle.BuffTriggerPoint.onRoundStart)

	-- 检测目标是否死亡
	self.scene:checkObjsDeadState()

	-- 表现效果播放
	gRootViewProxy:proxy():flushCurDeferList()


	-- 开始新的一回合战斗中的各个单位行动的顺序轮次
	self.scene:newRoundBattleTurn()
end

function Gate:getObjectBaseSpeedRankSortKey(obj)
	return obj.id
end

--速度排序
function Gate:speedRankSort()
	-- 获取存活对象
	local tobeDel = {}
	local curLefts = itertools.filter(self.roundLeftHeros, function(id, data)
		local obj = data.obj
		if not obj or obj:isRealDeath() then
			table.insert(tobeDel, id)
			return nil
		end
		return data
	end)
	for i=table.length(tobeDel),1,-1 do
		table.remove(self.roundLeftHeros, tobeDel[i])
	end
	if not next(curLefts) then
		return false
	end
	-- 速度排序 不对obj组成的table直接排序 因为可能存在引用值导致排序出错
	local tbForSort = {}
	for k,v in ipairs(curLefts) do
		local obj = v.obj
		local relatively = v.another and (obj.unitID % 2 == 0)
		table.insert(tbForSort, {
			key = k,
			speedPriority = obj.speedPriority,
			speed = battleEasy.ifElse(relatively, obj:speed(0), obj:speed()),
			objId = self:getObjectBaseSpeedRankSortKey(obj),
			reset = v.reset,
			atOnce = v.atOnce,
			buffCfgId = v.buffCfgId,
			force = obj.force,
			geminiSpecialDeal = relatively and 1 or 2
		})
	end
	local function more(a, b)
		return a > b
	end
	local function less(a, b)
		return a < b
	end
	-- 1.resetBattleRound 2.atOnceBattleRound 3.speedPriority 4.speed 5.objid
	local sortFuncs = {
		{name = "reset", checkFunc = more},
		{name = "atOnce", checkFunc = more},
		{name = "speedPriority", checkFunc = more},
		{name = "speed", checkFunc = more},
		{name = "objId", checkFunc = less},
		{name = "geminiSpecialDeal", checkFunc = more},
	}
	table.sort(tbForSort, function(a, b)
		for k,v in ipairs(sortFuncs) do
			local val1,val2 = a[v.name],b[v.name]
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
	-- 0.changeSpeedPriority
	for k,v in ipairs(self.speedSortRule) do
        v.sort(tbForSort)
	end

	-- dump(tbForSort)
	-- for k,v in ipairs(tbForSort) do
	-- 	print("########", curLefts[v.key].obj.seat, curLefts[v.key].obj.star)
	-- end

	local added = {}
	local sorted = {}
	self.attackSign = {}
	for k,v in ipairs(tbForSort) do
		local obj = curLefts[v.key].obj
		table.insert(sorted,obj)
		local unitID = 0
		local exUnitID = 0
		if obj.multiShapeTb then
			unitID = battleEasy.ifElse(obj.orginUnitId % 2 ~= 0, obj.orginUnitId, obj.data.role2Data.roleId)
			if not curLefts[v.key].another and (obj.multiShapeTb[1] % 2) == obj.orginUnitId % 2 then
				exUnitID = unitID
			end
		end
		if not curLefts[v.key].another then unitID = 0
		else exUnitID = unitID end
		local key = tostring(obj.id) .. tostring(exUnitID)
		if not added[key] then
			table.insert(self.attackSign, unitID)
			added[key] = true
		end
	end

	--记录出手队列第一个单位在roundLeftHeros中的位置
	local firstData = tbForSort[1] and curLefts[tbForSort[1].key]
	if not next(self.nextHeros) then
		self.extraBattleRoundData = firstData
		self.extraBattleRoundData.mode = firstData.mode or battle.ExtraBattleRoundMode.normal
		self.battleRoundTriggerId = battleEasy.getRoundTriggerId(firstData.buffCfgId)
	else
		self.extraBattleRoundData = nil
	end
	self:setLeftHerosIndex(firstData)
	-- 按可行动状态再次排序
	-- (现在又要求不检查当前能否行动了,以便让某些当前不能行动的目标在它的回合前触发被动或者buff,然后再变得可以行动,呵~)
	self.attackerArray = sorted
	return true
end

-- 指定目标的额外回合
function Gate:getExtraBattleRoundData(name)
	if self.extraBattleRoundData then
		return self.extraBattleRoundData[name]
	end
end

function Gate:setLeftHerosIndex(firstData)
	self.leftHerosFirstIndex = nil
	for id, data in ipairs(self.roundLeftHeros) do
		if firstData == data then
			self.leftHerosFirstIndex = id
			break
		end
	end
end

function Gate:getTopCardsAttrAvg(num)
	if not self.topCardsAttrAvg then
		self.topCardsAttrAvg = {}
		local attrTab = {"speed","damage","specialDamage","hp","defence","specialDefence"}
		local topCards = self.data.top_cards_data and self.data.top_cards_data["top_cards"] or {}
		local card,attr
		for k,dbid in ipairs(topCards) do
			if k > num then break end
			attr = self.data.top_cards_data["card_attrs"][dbid]

			for _,attrName in ipairs(attrTab) do
				self.topCardsAttrAvg[attrName] = (self.topCardsAttrAvg[attrName] or 0) + attr[attrName]
				if k == num then
					self.topCardsAttrAvg[attrName] = self.topCardsAttrAvg[attrName] / num
				end
			end
		end
	end

	return self.topCardsAttrAvg
end

-- for view
function Gate:getSpeedRankArray()
	-- return arraytools.merge({self.attackerArray, {{seat=9999}}, self.roundHasAttackedHeros})
	-- 去重
	local added, attackerTb = {}, {}
	for k,obj in ipairs(self.attackerArray) do
		if not added[obj.id] or self.attackSign[k] ~= 0 then
			table.insert(attackerTb, obj)
			added[obj.id] = true
		end
	end
	-- {seat=99999} SpeedRank分割用
	local speedRankSign = arraytools.merge({self.attackSign, {0}, self.hasAttackedSign})
	return arraytools.merge({attackerTb,{{seat=99999}}, self.roundHasAttackedHeros}), speedRankSign
end

function Gate:getSpeedRankArrayDeduplication()
	local added, ret, exObj = {}, {}
	local array = self:getSpeedRankArray()
	for _, obj in ipairs(array) do
		if not added[obj.seat] and obj.seat <= self.ObjectNumber then
			table.insert(ret, obj)
			exObj = self.scene:getObjectBySeatExcludeDead(obj.seat, battle.ObjectType.SummonFollow)
			if exObj then table.insert(ret, exObj) end
			added[obj.seat] = true
		end
	end
	return ret
end

-- 像是活动副本敌方不攻击时,它们也不会在行动队列中,所以某些地方的设置需要再手动处理下
function Gate:getObjsNotInSpeedRank()
	local hashTb = {}
	for _, obj in ipairs(self:getSpeedRankArray()) do
		if obj and obj.seat <= self.ObjectNumber then
			hashTb[obj.seat] = true
		end
	end
	local tb = {}
	for _, obj in self.scene:ipairsHeros() do
		if not obj:isAlreadyDead() and not hashTb[obj.seat] then
			table.insert(tb, obj)
		end
	end
	return tb
end

-- 注意: 这里修改了以前的函数名字, 按策划的设计, 应该是每一回合(round)内, 场上的所有可行动目标会先排序,然后按顺序依次行动(turn),
function Gate:onNewBattleTurn()
	self.battleRoundTriggerId = nil
	self.curBattleRound = self.curBattleRound + 1
	self.totalRoundBattleTurn = self.totalRoundBattleTurn + 1
	self.handleInput = nil 			-- 新回合需要清空手动目标选择

	log.battle.gate.onNewBattleTurn('---------- gate onNewBattleTurn() ---------- =', self.curBattleRound,self.totalRoundBattleTurn)
	-- 旧数据清理
	self.battleTurnInfoTb = {}		-- 用于汇总记录到每个turn中的数据, 新turn时清空
	self:onTurnStartSupply()
	-- 把上一次的行动目标加入到已攻击过的记录中,部分buff会重置当前单位到未攻击队列
	-- 需要判断当前单位是否在未攻击队列,才能加入已攻击队列
	if not itertools.include(self.roundLeftHeros,function(data) return self.curHero and data.obj.id == self.curHero.id end)
	and not itertools.include(self.roundHasAttackedHeros,self.curHero)
	and not itertools.include(self.scene.backHeros, self.curHero)
	and not itertools.include(self.scene.extraHeros, self.curHero) then
		table.insert(self.roundHasAttackedHeros, self.curHero)
		table.insert(self.hasAttackedSign, self.curHero and 0)
	end
	-- 记录出手的单位队列 可以是多次出手
	if self.curHero and not self.scene:beInExtraAttack() then
		-- 缺少唯一标识来记录
		table.insert(self.roundHasAttackedHistory, {
			id = self.curHero.id,
			force = self.curHero.force
		})
	end

	-- 双生加入已出手队列处理
	if self.curHero then
		local notExistLeftHeros = not itertools.include(self.roundLeftHeros,function(data) return data.obj.id == self.curHero.id end)
		local notExistHasAttackedHeross = not itertools.include(self.roundHasAttackedHeros,self.curHero)
		if self.curHero.multiShapeTb and (notExistLeftHeros or notExistHasAttackedHeross) then
			local unitID = battleEasy.ifElse(self.curHero.orginUnitId % 2 ~= 0, self.curHero.data.role2Data.roleId, self.curHero.orginUnitId)
			if not notExistHasAttackedHeross then
				unitID = battleEasy.ifElse(self.curHero.orginUnitId % 2 == 0, self.curHero.data.role2Data.roleId, self.curHero.orginUnitId)
			end
			local isSecond = (self.curHero.multiShapeTb[1] % 2) == self.curHero.orginUnitId % 2
			if (isSecond and notExistHasAttackedHeross) or notExistLeftHeros then
				table.insert(self.roundHasAttackedHeros, self.curHero)
				table.insert(self.hasAttackedSign, unitID)
			end
		end
	end

	-- 行动排序
	local hasHero = self:speedRankSort()
	self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onBattleTurnStart)

	--每次攻击时都从新初始化当前的位置
	self.scene:resetPlaceIdInfo(1)
	self.scene:resetPlaceIdInfo(2)
	if not hasHero and not next(self.nextHeros) then
		self:checkBattleState()
		return
	end

	self:setCurHero()
	--表现效果播放
	gRootViewProxy:proxy():flushCurDeferList()

	-- local curHeroId = self.curHero.id
	logf.battle.gate.curHero(' 当前行动者: curHero: %d:', self.curHero.seat)
	self.curHero.isInBattleTurn = true	--标记下处于攻击中
	-- 目标在行动前的触发
	for i, obj in ipairs(self:getSpeedRankArrayDeduplication()) do
		obj:onNewBattleTurn()
	end

	-- 检测目标是否死亡
	self.scene:checkObjsDeadState()
	-- 再次更新技能状态 回合开始的节点之后一些技能禁用buff可能结束
	self.curHero:updateSkillState(true)
	self.curBattleRoundAttack = self.curHero:canAttack()

	self.scene:onSubModulesNewBattleTurn()
	--表现效果播放
	gRootViewProxy:proxy():flushCurDeferList()
	self.scene:onSubModulesNewBattleTurn2()
	--设置一下当前的自选目标
	self:autoChoose()

	self.scene:waitNewBattleRoundAniDone()
end

function Gate:newBattleTurnGoon()
	-- 每个角色行动前引导检测，包括敌方行动和死亡等有配置则先显示引导
	self:checkGuide(function()
		-- 战斗过程
		if self.curHero and not self.curHero:isAlreadyDead() then
			self:onceBattle()
		else
			self:checkBattleState()
		end
	end, {heroId = self.curHero.seat})
end

function Gate:setCurHero()
	self.curHero = nil
	self.curHeroRoundInfo = {}
	-- 优先走nextHeros逻辑
	while not self.curHero and next(self.nextHeros) do
		self.curHero = self.scene:getObjectExcludeDead(self.nextHeros[1])
		table.remove(self.nextHeros,1)
	end

	if not self.curHero then
		self.curHero = self.attackerArray[1]
		if self.leftHerosFirstIndex then
			self.curHeroRoundInfo = self.roundLeftHeros[self.leftHerosFirstIndex]
			table.remove(self.roundLeftHeros, self.leftHerosFirstIndex)
			self.leftHerosFirstIndex = nil
		end
	end
end

function Gate:isPlaying()
	return self.result == nil
	-- return self.result == nil and self.curBattleRound > 0
end

-- 当前是否是左侧方单位在行动
function Gate:isMyTurn()
	return self.curHero and self.curHero.force == 1
end

-- 当前轮次是不是自动攻击
function Gate:isNowTurnAutoFight()
	if self.scene.autoFight then return true end
	if not self:isMyTurn() and not self.scene.fullManual then return true end
    if self.curHero then
        if self.curHero:isSelfChargeOK() or self.curHero:isNeedAutoFightByBuff() then
            return true
        end
    end
end

function Gate:beginBattleTurn()
	return self.curHero:canAttack() -- 检测 自身的状态能不能攻击 和 有没有可用的技能
end

function Gate:runBattleTurn(attack, target) -- attack: {skill=xxx} skill--是skillId
	self.curHero:toAttack(attack, target)
end

-- 结束当前战斗回合,每个战斗回合结束时都需要从这个函数执行一次
function Gate:endBattleTurn(target)
	local obj = self.curHero

	-- TODO: 额外回合
	-- if obj:hasExtraBattleRound() then
	-- 	self.nextHero = obj
	-- end

	gRootViewProxy:proxy():pushDeferList('playInEndBattleTurn')

	-- 战斗回合结束时触发
	for _, obj in ipairs(self:getSpeedRankArrayDeduplication()) do
		obj:onBattleTurnEnd()
	end

	self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onBattleTurnEnd)

	local playInEndBattleTurn = gRootViewProxy:proxy():popDeferList("playInEndBattleTurn")
	-- 先播放效果 后删除单位
	-- gRootViewProxy:proxy():flushCurDeferList()
	-- 保证战斗回合结束的逻辑在技能后执行
	battleEasy.queueEffect(function()
		battleEasy.queueEffect(function()
			gRootViewProxy:proxy():runDefer(playInEndBattleTurn)
		end)
	end)

	self.scene:endBattleTurn()

	if not self.curBattleRoundAttack then
		battleEasy.queueEffect('delay', {lifetime=300})
	end
	--表现效果播放
	-- battleEasy.queueEffect(function()
	-- 	gRootViewProxy:proxy():flushCurDeferList()
	-- end)

	self.curHero.curTargetId = nil
	self.curHero.isInBattleTurn = false
	-- 战斗结束的补充
	self:onTurnEndSupply()
	--每个目标一轮结束就进行一次 战斗结束的 检测
	self:checkBattleState()
end

-- 一次战斗过程,包括开始 中间 结束，开始条件不满足时,中间不执行,结束无论如何都会执行一次
function Gate:onceBattle(targetId, skillId)
	-- 手动才有targetId
	-- 记录原始操作数据
	if skillId and self.CommonArgs.AntiMode == battle.GateAntiMode.Operate then
		table.set(self.actionSend, self.curRound, self.curBattleRound, {
			self.curHero.seat,	-- 当前单位
			targetId,			-- 选中目标
			skillId,		-- 选中技能id, 0 表示自动
		})
	end

	return self:_onceBattle(targetId, skillId)
end

function Gate:_onceBattle(targetId, skillId)
	self.curHero.handleChooseTarget = nil
	local attack, target
	-- 检测开始的条件
	if self.waitInput or self:beginBattleTurn() then
		-- 条件满足时,获取攻击指令和攻击目标
		-- local attack, target
		-- 如果是手动选择,需要等待指令传入:使用的技能、要攻击的目标
		-- 如果是手动时,对于随机类的单位,则最终的攻击目标就是这个选择的目标
		-- 补充:充能满了的状态,直接释放操作,不需要玩家手动操作
        if self.curHero and self.curHero:isNeedAutoFightByBuff() then
            attack, target = self:autoAttack()
		elseif self.curHero and self.curHero:isSelfChargeOK() then
			local sId = self.curHero.curSkill.id
            target = self.scene:getObjectExcludeDead(self.curHero.chargeSkillTargetId)
            if not target or (target and target:isAlreadyDead()
				or target:isLogicStateExit(battle.ObjectLogicState.cantBeAttack,{fromObj = self.curHero}))
			then
                target = self:autoChoose(sId)
            end
			attack = {skill = sId}
		-- 是(己方出手 or 全手动) 并且 不是自动攻击 才会中断
		elseif (self:isMyTurn() or self.scene.fullManual) and not self.scene.autoFight then		-- (先注释掉,策划要测试两边都手动战斗的)
			self.waitInput = true
			if not (targetId and skillId) then
				return
			end

			if targetId == 0 and skillId == 0 then
				attack, target = self:autoAttack()
			else
				attack = {skill = skillId}
				target = self.scene:getObjectBySeatExcludeDead(targetId)
				self.curHero.handleChooseTarget = target
				self.nowChooseID = targetId
			end
			-- 如果是自动选择,
		else
			attack, target = self:autoAttack() --自动选择时,需要自动选择技能,目标为当前技能对应的克性目标
		end

		self.waitInput = nil

		if self.scene.cowEnableCount > 0 then
			cow.proxyWatchBegin()
			self.preCalcLethalDatas = {{},{}} -- [1]:死亡且有致死保护的 [2]:死亡且没有致死保护的 {{objId:true,...},{objId1,objId2,...}}
			self.scene.play:runBattleTurn(attack, target)
			local lethalDatas = clone(self.preCalcLethalDatas)
			self.preCalcLethalDatas = nil
			-- revert cow proxy
			local revert = (next(lethalDatas[1]) or table.length(lethalDatas[2]) > 0)
			cow.proxyWatchEnd(revert)
			if revert then
				for _, objId in ipairs(lethalDatas[2]) do
					local obj = self.scene:getObjectExcludeDead(objId)
					if obj then
						obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderLethal)
					end
				end
				self.lethalDatas = lethalDatas[1]
				self.scene.play:runBattleTurn(attack, target)
				self.lethalDatas = {}
			end
		else
			self.scene.play:runBattleTurn(attack, target)
		end
	end
	-- 结束判断
	self:endBattleTurn(target)
end

function Gate:autoAttack()
	gRootViewProxy:notify('selectedHero')

	local enemyForce = self:isMyTurn() and 2 or 1
	--自动攻击时,先判断技能,根据技能再选择目标
	-- 先大招,再各种加特殊buff的技能, 再常规技能, 再普攻(目前暂时是有大招放大招没有大招随机一个能用的)
	local skillID
	--local mainSkill = "1"		-- 大招
	--local midSkill = "2"			-- 二技能
	--local normalAttack = "3"	-- 普攻

	local ret = {}
	-- local canUse
	for id, skill in self.curHero:iterSkills() do
		if skill.skillType2 ~= battle.MainSkillType.PassiveSkill and skill:canSpell() then
			-- if skill.skillType2 == battle.MainSkillType.BigSkill then
			-- 	ret[mainSkill] = id
			-- elseif skill.skillType2 == battle.MainSkillType.NormalSkill then
			-- 	ret[normalAttack] = id
			-- else
			-- 	ret[midSkill] = id
			-- end
			ret[skill.skillType2 + 1] = id
			-- if id == self.curHero.exAttackSkillID then
			-- 	canUse = true
			-- end
		end
	end

	if not next(ret) then return end

	if ret[battle.MainSkillType.BigSkill + 1] then
		skillID = ret[battle.MainSkillType.BigSkill + 1]		-- 大招最优先
	elseif ret[battle.MainSkillType.SmallSkill + 1] then
		skillID = ret[battle.MainSkillType.SmallSkill + 1]			-- 二技能其次
	else
		skillID = ret[battle.MainSkillType.NormalSkill + 1]		-- 最后普攻
	end

	if self.curHero.exAttackSkillID then
		skillID = self.curHero.exAttackSkillID
	elseif self.curHero.exAttackArgs then
		if self.curHero.exAttackArgs.skillPowerMap then
			skillID = battleEasy.getItemInPowerMap(ret,self.curHero.exAttackArgs.skillPowerMap)
		end
	else
		local newSkillId = self:getExtraBattleRoundData("newSkillId")
		if newSkillId then
			if self.curHero.skillsMap[newSkillId] then
				skillID = newSkillId
			else
				local cfg = csv.skill[newSkillId]
				local skillType2 = cfg and cfg.skillType2
				if skillType2 and ret[skillType2 + 1] then
					skillID = ret[skillType2 + 1]
				end
			end
		end
	end

	skillID = self.curHero.skillsMap[skillID] or skillID

	if not skillID then return end

	-- 获得技能目标
	local target = self:autoChoose(skillID)

	logf.battle.gate.autoAttack(" autoAttack, choose skillId= %d, attackId= %d", skillID or 999999, target and target.id or 999999)
	return {skill=skillID}, target
end

local AUTO_CHOOSE_STEP = {
	-- 1.嘲讽判断 被嘲讽 只能攻击嘲讽者
	[1] = function(self, skillId, enemyForce, _)
		local autoSkill = csv.skill[skillId]
		if skillId and autoSkill then
			if autoSkill.hintTargetType == 1 then
				local sneerAtMeObj
				local curAttackObj = self.curHero
				if curAttackObj then
					sneerAtMeObj = curAttackObj:getSneerObj()
					if sneerAtMeObj and sneerAtMeObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect,{fromObj = curAttackObj}) then
						sneerAtMeObj = curAttackObj:getCanAttackObjs(sneerAtMeObj.force)
						local retLength = table.length(sneerAtMeObj)
						sneerAtMeObj = (retLength > 0) and sneerAtMeObj[ymrand.random(1, retLength)]
					end
				end

				if sneerAtMeObj and not sneerAtMeObj:isAlreadyDead() then
					return true, sneerAtMeObj
				end
			else
				-- 判断技能当前选择的阵营
				-- stepNum = (enemyForce == 2) and 0 or self.ForceNumber
				enemyForce = 3 - enemyForce
			end
		end
		return false, enemyForce
	end,

	-- 1.5 额外行动的技能
	[2] = function(self, skillId, enemyForce, _)
		local curAttackObj = self.curHero
		-- 无法攻击无法选择的目标 会额外选择目标
		if curAttackObj and curAttackObj.exAttackTargetID then --反击id
			local tar = self.scene:getFilterObject(curAttackObj.exAttackTargetID, {fromObj = curAttackObj},
				battle.FilterObjectType.noAlreadyDead,
				battle.FilterObjectType.excludeObjLevel1
			)
			if tar then
				return true, tar
			end

			if curAttackObj.exAttackArgs and curAttackObj.exAttackArgs.isFixedForce then
				enemyForce = curAttackObj.exAttackArgs.targetForce or enemyForce
			end
		end
		return false, enemyForce
	end,

	-- 额外普通回合附带目标
	[3] = function(self, skillId, enemyForce, _)
		local curAttackObj = self.curHero
		-- 无法攻击无法选择的目标 会额外选择目标
		if curAttackObj then --反击id
			local targetId = self:getExtraBattleRoundData("targetId")
			local tar = self.scene:getFilterObject(targetId, {fromObj = curAttackObj},
				battle.FilterObjectType.noAlreadyDead,
				battle.FilterObjectType.excludeObjLevel1
			)
			if tar then
				return true, tar
			end
		end
		return false, enemyForce
	end,

	-- 2.根据配表进行配置 把符合配表要求的目标都选出来 放到一起
	[4] = function(self, skillId, enemyForce, _)
		if skillId then
			local autoSkill = self.curHero.skills[skillId] or self.curHero.passiveSkills[skillId] or self.curHero.curSkill
			if autoSkill then
				-- 混合类型 阵营应该是全体
				if autoSkill.skillFormulaType == battle.SkillFormulaType.fix then
					enemyForce = 3
				end
				-- 自动攻击目标存在
				-- 新自动攻击公式生效的前提是能够攻击
				local targets = autoSkill:getTargetsHint(autoSkill.cfg.autoHintChoose)
				return false, enemyForce, targets
			end
		end

		return false, enemyForce
	end,

	-- 存在curHero不存在的时候 即入场调用被动时触发的autoChoose
	[5] = function(self, skillId, enemyForce, targets)
		local autoSkill
		if skillId then
			autoSkill = self.curHero.skills[skillId] or self.curHero.passiveSkills[skillId] or self.curHero.curSkill
		end
		local allCanAttackTargets = self.scene:getFilterObjects(enemyForce,
			{
				fromObj = self.curHero,
				skillFormulaType = autoSkill and autoSkill.skillFormulaType
			},
			battle.FilterObjectType.excludeEnvObj,
			battle.FilterObjectType.noAlreadyDead,
			battle.FilterObjectType.excludeObjLevel1
		)
		if targets then
			local hash = itertools.map(targets, function(_, obj) return obj.id, true end)
			targets = {}
			for _, obj in ipairs(allCanAttackTargets) do
				if hash[obj.id] then
					table.insert(targets, obj)
				end
			end
			if not itertools.isempty(targets) then
				allCanAttackTargets = targets
			end
		end

		return false, enemyForce, allCanAttackTargets
	end,
}

--自动选择目标,以当前行动目标为参照,找它的可攻击目标
function Gate:autoChoose(skillId, force)
	local enemyForce = force or (self:isMyTurn() and 2 or 1)

	local flag, targetOrForce, targets
	for _, func in ipairs(AUTO_CHOOSE_STEP) do
		flag, targetOrForce, targets = func(self, skillId, enemyForce, targets)
		if flag == true then
			return targetOrForce
		end
		-- next iterator
		enemyForce = targetOrForce
	end

	-- 存在retT为空的可能，等待checkBattleState检查结束
	if itertools.isempty(targets) then
		printWarn("%s autoChoose no any target", tostring(skillId))
		self.nowChooseID = 0
		return
	end

	-- 策划想要简化自动选择的逻辑 原代码 绕开但保留
	-- 以下为简化后
	local randIdx = ymrand.random(1, table.length(targets))
	local target = targets[randIdx]
	self.nowChooseID = target.seat
	return target
end


function Gate:checkBothAllRealDead()
	return self:checkForceAllRealDead(1) and self:checkForceAllRealDead(2)
end

-- 检查死亡函数
function Gate:checkForceAllRealDead(force)
	--全死的情况下特殊处理
	-- if not noCheckAllDead and self:checkBothAllRealDead() and table.length(self.scene.realDeathRecordTb) > 0 then
	-- 	local maxOrderInfo
	-- 	for k,v in ipairs(self.scene.realDeathRecordTb) do
	-- 		if not maxOrderInfo or (maxOrderInfo and maxOrderInfo.order < v.order) then
	-- 			maxOrderInfo = {
	-- 				order = v.order,
	-- 				force = v.force,
	-- 				id = v.id
	-- 			}
	-- 		end
	-- 	end
	-- 	-- print("!!!!!!!!!! checkForceAllRealDead ",force,maxOrderInfo.force,maxOrderInfo.id)
	-- 	return maxOrderInfo.force ~= force
	-- end
	local forces = self.scene:getHerosMap(force)
	local hasAlive = itertools.include(forces, function(obj)
		return obj and (not obj:isRealDeath())
	end)
	return not hasAlive
end

function Gate:getRoundLeftHerosCount()
	local n = 0
	for _, nextHero in ipairs(self.nextHeros) do
		if nextHero and self.scene:getObjectExcludeDead(nextHero) then
			n = n + 1
		end
	end

	for _, roundLeftHero in ipairs(self.roundLeftHeros) do
		if roundLeftHero and roundLeftHero.obj and not roundLeftHero.obj:isRealDeath() then
			n = n + 1
		end
	end
	return n
end


--检查round结束
function Gate:checkRoundEnd()
	local n = self:getRoundLeftHerosCount()
	if n <= 0 then
		return true
	end
	return false
end

-- 判断 wave 结束 todo
function Gate:checkWaveEnd()
	if (self.curWave < self.waveCount) and self:checkForceAllRealDead(2) then
		return true
	end
	return false
end

function Gate:condition()
	local allDead = self:checkForceAllRealDead(1) or self:checkForceAllRealDead(2)
	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not allDead then
		return true
	end
	return false
end

local specEndRuleLogicTb = {
	[battle.EndSpecialCheck.ForceNum] = function(self)
		if self:condition() then
			local forceNum = {0,0}
			for _,obj in self.scene:ipairsHeros() do
				if obj and not obj:isAlreadyDead() and self:checkObjCanToServer(obj) then
					forceNum[obj.force] = forceNum[obj.force] + 1
				end
			end
			if battleEasy.numEqual(forceNum[1],forceNum[2]) then return false, 'fail' end
			local res = battleEasy.ifElse(forceNum[1] > forceNum[2], "win", "fail")
			return true, res
		end
		return false
	end,
	[battle.EndSpecialCheck.HpRatioCheck] = function(self)
		if self:condition() then
			self.scene:overAssignTypeBuffs('markId')
			local hpRatio = {0, 0}
			for _,obj in self.scene:ipairsHeros() do
				if self:checkObjCanToServer(obj) then
					hpRatio[obj.force] = hpRatio[obj.force] + (obj:hp() / obj:hpMax())
				end
			end
			if battleEasy.numEqual(hpRatio[1],hpRatio[2]) then return false, 'fail' end
			local res = battleEasy.ifElse(hpRatio[1] > hpRatio[2], "win", "fail")
			return true, res
		end
		return false
	end,
	[battle.EndSpecialCheck.TotalHpCheck] = function(self)
		if self:condition() then
			local totalHp = {0, 0}
			for _,obj in self.scene:ipairsHeros() do
				if obj and not obj:isAlreadyDead() and self:checkObjCanToServer(obj) then
					totalHp[obj.force] = totalHp[obj.force] + obj:hp()
				end
			end
			if battleEasy.numEqual(totalHp[1],totalHp[2]) then return false, 'fail' end
			local res = battleEasy.ifElse(totalHp[1] > totalHp[2], "win", "fail")
			return true, res
		end
		return false
	end,
	[battle.EndSpecialCheck.AllHpRatioCheck] = function(self)
		if self:condition() then
			self.scene:overAssignTypeBuffs('markId')
			self.enemyDeadHpMaxSum = self.enemyDeadHpMaxSum or 0
			self.myDeadHpMaxSum = self.myDeadHpMaxSum or 0
			local hpMax = {self.myDeadHpMaxSum, self.enemyDeadHpMaxSum}
			local hp = {0, 0}
			for _,obj in self.scene:ipairsHeros() do
				if self:checkObjCanToServer(obj) then
					hpMax[obj.force] = hpMax[obj.force] + obj:hpMax()
					hp[obj.force] = hp[obj.force] + obj:hp()
				end
			end
			local res
			if hpMax[1] == 0 or hpMax[2] == 0 then	-- 有一方是召唤物之类的没有计算到hpMax内
				res = battleEasy.ifElse(hpMax[2] == 0, "win", "fail")
				return true, res
			end
			if battleEasy.numEqual(hp[1]/hpMax[1],hp[2]/hpMax[2]) then return false, 'fail' end
			res = battleEasy.ifElse(hp[1]/hpMax[1] > hp[2]/hpMax[2], "win", "fail")
			return true, res
		end
		return false
	end,
	[battle.EndSpecialCheck.FightPoint] = function(self)
		if self:condition() then
		    local fightPointSum ={0, 0}
		    for _, obj in self.scene:ipairsHeros() do
				if self:checkObjCanToServer(obj) then
					fightPointSum[obj.force] =  fightPointSum[obj.force] + obj.fightPoint
				end
			end
			if battleEasy.numEqual(fightPointSum[1],fightPointSum[2]) then return false, 'fail' end
		    local res = battleEasy.ifElse(fightPointSum[1] > fightPointSum[2], "win", "fail")
			return true, res
		end
		return false
	end,
	[battle.EndSpecialCheck.CumulativeSpeedSum] = function(self)
		local speedSum ={0, 0}
		for _, obj in self.scene:ipairsHeros() do
			if self:checkObjCanToServer(obj) then
				speedSum[obj.force] =  speedSum[obj.force] + obj:speed()
			end
		end
		if battleEasy.numEqual(speedSum[1],speedSum[2]) then return false, 'fail' end
		local res = battleEasy.ifElse(speedSum[1] > speedSum[2], "win", "fail")
		return true, res
	end,
	[battle.EndSpecialCheck.SoloSpecialRule] = function(self)     --单挑判定用
		if not self.forceToObjId then return false end
		local me = self.scene:getObject(self.forceToObjId[1])
		local enemy = self.scene:getObject(self.forceToObjId[2])
		if not me or not enemy then
			return false
		end
		if me.markID ~= enemy.markID then
			return false
		end
		if not gCraftSpecialRules[me.markID] then
			return false
		end
		local specBuffType = gCraftSpecialRules[me.markID]
		local buffGlobalMgr = self.scene.buffGlobalManager
		local meTriggerTime = buffGlobalMgr:getBuffTriggerTime(me.id,specBuffType)
		local enemyTriggerTime = buffGlobalMgr:getBuffTriggerTime(enemy.id,specBuffType)
		if meTriggerTime == enemyTriggerTime then
			return false
		end
		if meTriggerTime > 1e-6 and enemyTriggerTime > 1e-6 then
			return false
		end
		local res = battleEasy.ifElse(meTriggerTime < enemyTriggerTime, "win", "fail")
		return true,res
	end,
	[battle.EndSpecialCheck.LastWaveTotalDamage] = function(self)
		local totalDamage ={0, 0}
		for _, obj in self.scene:ipairsHeros() do
			if self:checkObjCanCalcDamage(obj) then
				local damage = 0
				for k,v in pairs(battle.DamageFrom) do
					local curDamage = obj.totalDamage[v] and obj.totalDamage[v]:get(1) or 0
					damage = damage + curDamage
				end
				totalDamage[obj.force] =  totalDamage[obj.force] + damage - (obj.lastWaveTotalDamage or 0)
			end
		end
		if battleEasy.numEqual(totalDamage[1],totalDamage[2]) then return false, 'fail' end
		local res = battleEasy.ifElse(totalDamage[1] > totalDamage[2], "win", "fail")
		return true, res
	end,
	[battle.EndSpecialCheck.DirectWin] = function(self)
		local forceNums = {{0, 0}, {0, 0}}
		for _, obj in self.scene:ipairsHeros() do
			-- if obj:checkOverlaySpecBuffExit("directWin") then
			-- 	forceNum[obj.force] = forceNum[obj.force] + 1
			-- end
			for _, data in obj:ipairsOverlaySpecBuff("directWin") do
				forceNums[obj.force][data.mode] = forceNums[obj.force][data.mode] + 1
			end
		end
		local res
		if forceNums[1][1] ~= forceNums[2][1] then  -- 胜利作为判定标准
			res = battleEasy.ifElse(forceNums[1][1] > forceNums[2][1], "win", "fail")
			return true, res
		end
		if forceNums[1][2] ~= forceNums[2][2] then  -- 失败作为判定标准
			res = battleEasy.ifElse(forceNums[1][2] > forceNums[2][2], "fail", "win")
			return true, res
		end
		return false
	end,
	[battle.EndSpecialCheck.EnemyOnlySummonOrAllDead] = function(self)
		local function isOnlySummonOrAllDead()
			-- 敌方全死了或者只有召唤物
			local enemies = self.scene:getHerosMap(2)
			for _, obj in enemies:order_pairs() do
				if obj and not obj:isAlreadyDead() and self:checkObjCanToServer(obj) then
					return false
				end
			end

			return true
		end

		if ((self.curRound >= self.roundLimit and self:checkRoundEnd()) or self:checkForceAllRealDead(1)) and isOnlySummonOrAllDead() then
			-- 超过回合数或己方全部死了，对面只有召唤物或全死，判自己胜利
			return true, "win"
		end

		return false
	end,
	[battle.EndSpecialCheck.BothDead] = function(self, result)
		if self:checkBothAllRealDead() then
			return true, result or "win"
		end
		return false
	end,
}


function Gate:specialEndCheck()
	local func, argsFunc
	for k,typ in ipairs(self.SpecEndRuleCheck) do
		func = specEndRuleLogicTb[typ]
		if func then
			argsFunc = self.SpecEndRuleCheckArgs[typ] or function() end
			local isEnd,result = func(self, argsFunc())
			if isEnd or k == table.length(self.SpecEndRuleCheck) and result then
				return true, result
			end
		end
	end
end

function Gate:bothRealDeadSpecCheck()
	local maxOrderInfo
	for k,v in ipairs(self.scene.realDeathRecordTb) do
		if not maxOrderInfo or (maxOrderInfo and maxOrderInfo.order < v.order) then
			maxOrderInfo = {
				order = v.order,
				force = v.force,
				id = v.id
			}
		end
	end
	-- 最后死亡的单位不是左边阵营,说明左边阵营单位先死亡,返回失败结果
	return true, maxOrderInfo.force ~= 1 and "fail" or "win"
end

-- 判断当前战斗是否结束 true 结束 false 胜利
function Gate:checkBattleEnd()
	local isEnd,result = self:specialEndCheck()
	if isEnd then
		return isEnd,result
	end

	local allDead = self:checkForceAllRealDead(1)
	local enemyAllDead = self:checkForceAllRealDead(2)

	if allDead and enemyAllDead and table.length(self.scene.realDeathRecordTb) > 0 then
		return self:bothRealDeadSpecCheck()
	end

	-- 1.先判断己方死光了没 默认全死为fail
	if allDead then
		return true, "fail"
	end
	-- 2.然后判断回合数是否超了
	-- FIX: 增加checkForceAllRealDead判断，否则我方最后一个精灵出手杀死对方会判负
	if self.curRound >= self.roundLimit and self:checkRoundEnd() and (not enemyAllDead) then
		return true, "fail"
	end
	-- 3.波数判断, 超过波数上限时就结束
	if self.curWave > self.waveCount then
		return true, "fail"
	end
    -- 4.判断敌方死光了没 波次是否到最后一波 额外条件是否满足
	local enemyAllDeadInEnd = (self.curWave == self.waveCount) and enemyAllDead
	local hasEx, exDone = self:checkExEndConditions()	-- 4.各子类型副本的补充条件
	local isEnd = (not hasEx and enemyAllDeadInEnd) or (hasEx and exDone)
	local allWin = isEnd and (not hasEx or exDone)

	if isEnd then
		return true, allWin and "win" or "fail"
	end
	return false
end

-- 检查战斗中各种状态的跳转
function Gate:checkBattleState()
	local objRoundEnd = function ()
		for _, obj in self.scene:ipairsHeros() do
			if not obj:isAlreadyDead() then
				obj:onEndRound()
			end
		end
		-- onEndRound中导致死亡的动画表现
		local deletedCount = 0
		for _, obj in pairs(self.scene.deadObjsToBeDeleted) do
			self.scene:onObjDeath(obj)
			deletedCount = deletedCount + 1
		end
		if deletedCount > 0 then
			self.scene.deadObjsToBeDeleted = {}
		end
	end
	--每个目标一轮结束就进行一次 战斗结束的 检测
	local checkBattleEnd = function()
		local isEnd, result = self:checkBattleEnd()
		if isEnd then
			self:runGameEnd(result)
		end
		return isEnd
	end

	if checkBattleEnd() then
		return
	elseif self:checkWaveEnd() then
		-- 新的wave 也必将触发新的round
		-- 因此会触发roundEnd
		objRoundEnd()
		if not checkBattleEnd() then
			self:onWaveEndSupply()
			self.scene:newWave()
		end
	elseif self:checkRoundEnd() then
		objRoundEnd()
		if not checkBattleEnd() then
			self:onRoundEndSupply()
			self.scene:newRound()
		end
	else
	 	self.scene:newBattleTurn()
	end
end

function Gate:runGameEnd(result)
	self:recordDamageStats()
	self:recordCampDamageStats()
	self.result = result
	self:onBattleEndSupply()
	self.scene:overAssignTypeBuffs('markId')
-- 胜负结算前的引导
	self:checkGuide(function()
		gRootViewProxy:notify('sceneOver', self.result)
		self.scene:over()
	end, {round = self.result == "win" and battle.GuideTriggerPoint.Win or battle.GuideTriggerPoint.Fail})
end

function Gate:onOver()
	self:makeEndViewInfos()

	-- 角色的胜负动作状态
	battleEasy.queueEffect(function()
		display.director:getScheduler():setTimeScale(1)
		battleEasy.queueEffect(function()
			self.scene:setAutoFight(false)
			gRootViewProxy:notify('sceneEndPlayAni', self.result)	--播放胜利或者死亡动作
			if self.endAnimation then
				local args = {
					delay = 0,
					offsetX=0,
					offsetY=0,
					zorder=0,
					aniName=self.endAnimation.aniName,
					scale = 0.5,
					aniloop=false,
					screenPos = 0,
					addTolayer = 1
				}
				battleEasy.queueEffect('effect', {effectType = 1,effectRes = self.endAnimation.res,effectArgs = args ,faceTo = 1})
			end
			--延迟 2秒吧
			battleEasy.queueEffect('delay', {lifetime=2000 + (self.endMoreDelayTime or 0)})
		end)
	end)

	self.scene:playEnd()
end

-- 条件检测 (这个先放在基类吧,可能后面的其它的pve类型的也需要这个星级条件吧)
local starConditionCheckTb = {
	[1] = function(gate, params)			-- 关卡胜利
		local c = (gate.result == 'win')
		return c, c and 1 or 0
	end,
	[2] = function(gate, params)			-- 阵亡数少于
		local startCount = gate.scene.forceRecordTb[1]["herosStartCount"]
		local count = 0
		for _, obj in gate.scene.heros:order_pairs() do
			if obj and not obj:isRealDeath() then
				count = count + 1
			end
		end
		return (startCount - count) <= params, (startCount - count)
	end,
	[3] = function(gate, params)			-- boss战回合数少于
		return not gate.seeBoss or (gate.curRound <= params), gate.seeBoss and gate.curRound or 0
	end,
	[4] = function(gate, params)			-- 上阵精灵数少于
		local startCount = gate.scene.forceRecordTb[1]["herosStartCount"]
		return startCount <= params, startCount
	end,
	[5] = function(gate, params)		-- 上阵精灵数大于
		local startCount = gate.scene.forceRecordTb[1]["herosStartCount"]
		return startCount >= params, startCount
	end,
}

-- 星级条件存储: 排序
function Gate:initStarConditions()
	if not self.starConditionTb then
		local starsCfg = self.scene.sceneConf.stars or {}
		local conditionTb = {}
		for _, cfg in csvPairs(starsCfg) do	-- 按条件类型id大小排, 貌似应该不会超过10个条件的
			table.insert(conditionTb, {cfg.key, cfg.value})
			if table.length(conditionTb) >= 3 then
				self.starConditionTb = conditionTb
				break
			end
		end
	end
end

function Gate:getStarConditions()
	return self.starConditionTb
end

-- 获取结束界面需要的信息(子类中去实现)
-- function Gate:makeEndViewInfos()
-- 	return {result = self.result}
-- end

-- 与服务器数据做比对
function Gate:compareRecrodResult(result)
	local ret = self:makeEndViewInfos()
	return ret.result == result
end

-- 这个也用来作为关卡中暂停时显示的星级的检测
function Gate:getGateStar()
	if not self.starConditionTb then return end
	-- 星数 评分
	local conditionTb = self.starConditionTb
	local totalCount = 0
	local tb = {{false, 0}, {false, 0}, {false,0}}		-- 3个的记录
	for i=1, 3 do
		local infos = conditionTb[i]
		local func = starConditionCheckTb[infos[1]]
		if func then
			tb[i][1], tb[i][2] = func(self, infos[2])
		end
		if tb[i][1] then
			totalCount = totalCount + 1
		end
	end
	return totalCount, tb
end

-- 获取当前选择的目标
-- function Gate:getCurChooseObj(skillId)
-- 	local obj = self.scene:getObjectExcludeDead(self.nowChooseID)
-- 	if not obj then
-- 		obj = self:autoChoose(skillId)
-- 	end
-- 	return obj
-- end

function Gate:postEndResultToServer(cb)
	cb(self:makeEndViewInfos(), nil)
end

-- 副本结束前最后一击的子弹时间
function Gate:checkBulletTimeShow()
	if not self.showedBulletTime then
		battleEasy.deferCallback(function()
			if self.result then
				gRootViewProxy:proxy():bulletTimeShow()
			end
		end)
		battleEasy.queueEffect(function()
			if self.result then
				self.showedBulletTime = true
				gRootViewProxy:proxy():onEventEffectQueueFront('delay', {lifetime = 900})
			end
		end)
	end
end

-- 从记录的数据中获取某一部分数据
-- 阵营中伤害最高的单位
function Gate:whoHighestDamageFromStats(force,group)
	local maxDmg = 0
    local CardIn = 1
	local posID
	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.unitsDamage)
	for k = 1, (group or 1) do
		local ret = {}
		if group then
			ret = tb[force][k]
		else
			ret = tb[force]
		end

		if ret then
			itertools.each(ret, function(id, t)
				if t.damageVal > maxDmg then
					maxDmg = t.damageVal
					posID = t.posId
					CardIn = k
				end
			end)
		end
	end
	return CardIn, posID
end

-- 副本结束条件 checkExEndConditions  返回值: true/false, result
function Gate:checkExEndConditions()
	local exConditions = self.scene.sceneConf.finishPoint
	if exConditions then
		for key, val in pairs(exConditions) do
			if key == "killNumber" then		-- 暂时只有这一个条件
				local killNumber = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.killNumber,"Val") or 0
				if killNumber >= val then
					return true, true
				end
			end
		end
		return true, false
	end
	return false, false
end

function Gate:checkObjCanToServer(obj)
	return obj.type ~= battle.ObjectType.Summon and obj.type ~= battle.ObjectType.SummonFollow
end

function Gate:checkObjCanCalcDamage(obj)
	if (obj.type == battle.ObjectType.Summon or obj.type == battle.ObjectType.SummonFollow)
		and not obj.summonCalDamage then
		return false
	end
	return true
end

-- 数据记录
function Gate:recordDamageStats()
	for _, obj in self.scene:ipairsHeros() do
		if self:checkObjCanCalcDamage(obj) then
			local totalDamage = 0
			for k,v in pairs(obj.totalDamage) do
				totalDamage = totalDamage + v:get(battle.ValueType.normal)
			end
			local key = obj.force
			local id = obj.id
			local data ={
				posId = obj.seat,
				damageVal = totalDamage
			 }
			self.scene.extraRecord:addExRecord(battle.ExRecordEvent.unitsDamage, data, key, id)
		end
	end
end

function Gate:recordCampDamageStats()
	local myDamage = 0
	local enemyDamage = 0
	local myDamageTb = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.unitsDamage,1)
	local enemyDamageTb = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.unitsDamage,2)
	if myDamageTb and enemyDamageTb then
	    for _,v in pairs(myDamageTb) do
		    myDamage = v.damageVal + myDamage
	    end
	    for _,v in pairs(enemyDamageTb) do
	    	enemyDamage = v.damageVal + enemyDamage
    	end
    end
	self.scene.extraRecord:addExRecord(battle.ExRecordEvent.campDamage, myDamage, 1)
	self.scene.extraRecord:addExRecord(battle.ExRecordEvent.campDamage, enemyDamage, 2)
end

function Gate:recordScoreStats(attacker, score)

end


-- 流程补充部分：用于子gate做扩展
-- 每波开始
-- function Gate:onWaveStartSupply()
-- 	-- body
-- end
-- -- 每回合开始
-- function Gate:onRoundStartSupply()
-- 	-- body
-- end
-- -- 每轮 开始 turn
function Gate:onTurnStartSupply()
	-- body
end
-- turn 结束
function Gate:onTurnEndSupply()
	-- body
end
-- -- 回合结束
function Gate:onRoundEndSupply()
	-- body
end
-- -- 波结束
function Gate:onWaveEndSupply()
	-- body
end
-- 战斗结束时
function Gate:onBattleEndSupply()
	-- body
end
-- 监听单位刷新血量
function Gate:refreshUIHp()
	self:notifyToSpecModule("refreshUIHp")
end
-- 监听单位刷新怒气
function Gate:refreshUIMp()
	self:notifyToSpecModule("refreshUIMp")
end

-- 获取怪物信息 可重写
function Gate:getMonsterCsv(sceneId,waveId)
	sceneId = sceneId or self.scene.sceneID
	return csvClone(gMonsterCsv[sceneId][waveId])
end

-- 获取引导信息
function Gate:getMonsterGuideCsv(sceneId, waveId)
	return gMonsterCsv[sceneId] and self:getMonsterCsv(sceneId, waveId)
end

-- 本波次的战斗回合数
function Gate:getTotalBattleTurnCurWave()
	return self.totalRoundBattleTurn
end

-- 所有波次的大回合数
function Gate:getTotalRounds()
	return self.totalRound
end
-- 导出玩法特有的公式
function Gate:excutePlayCsv(func_name)
	if self.PlayCsvFunc[func_name] then
		return functools.partial(self.PlayCsvFunc[func_name],self)
	end
end

function Gate:runOneFrame()
	return
end

function Gate:setAttack(seat, skillId)
	--self.handleInput = {skill=skillId, target=targetId}

	self.handleInput = {seat, skillId}
	--这里顺便要设置一下当前攻击目标
	if seat ~= 0 then
		self.nowChooseID = seat
	end
	logf.battle.scene.setAttack(' 操作输入 player inputs: targetSeat= %d, skillId= %d', seat, skillId)
end

function Gate:sendActionParams()
	local actionSend = self.actionSend
	local xMax = table.maxn(actionSend)
	for i = 1, xMax do
		local arr = actionSend[i]
		if arr == nil then
			actionSend[i] = {}
		else
			local yMax = table.maxn(arr)
			for j = 1, yMax do
				if arr[j] == nil then
					arr[j] = EmptyAction
				end
			end
		end
	end
	return actionSend
end

function Gate:checkGuide(func, data)
	self.scene.guide:checkGuide(func, data)
end

function Gate:makeEndViewInfos(data)
	local info = {result = self.result}
	if data then
		if data.gateStar then
			info.gateStar = 0
			if self.result == "win" then
				info.gateStar, info.gateStarTb = self:getGateStar()
			end
			info.conditionTb = self.starConditionTb
		end
	end

	return info
end

-- 流程扩充2:
-- 当非gate自身元素需要在某个/类gate中处理一些事情时,可以补充如下函数 (具体可看 daily_activity_gate 中的用法)
-- 主要是让非gate元素不需要去做判断gate类型的逻辑, 这些判断放到gate自身去处理, 这样方便查找和查看
-- function ChildGate:gateDoOnElementXxxx( ... )
--  	-- body
-- end