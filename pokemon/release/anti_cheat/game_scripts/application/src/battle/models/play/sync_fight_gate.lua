
local SyncFightGate = class("SyncFightGate", battlePlay.Gate)
battlePlay.SyncFightGate = SyncFightGate

local gsyncSceneState = game.SYNC_SCENE_STATE

local playerState = {
	waitloading 	= 4,
	attack 			= 5,
	wait 			= 6,
	record          = 7,
}

-- gGameModel.battle => RealtimeBattleModel
-- 战斗模式设置 手动
SyncFightGate.OperatorArgs = {
	isAuto 			= false,
	isFullManual 	= true,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= false,
	canSkip 		= false,
}

SyncFightGate.SpecEndRuleCheck = {
	battle.EndSpecialCheck.HpRatioCheck,
	battle.EndSpecialCheck.ForceNum,
}

local transformActionTb = { 6,7,8,9,10,11,12,1,2,3,4,5,6 }

function SyncFightGate:ctor(scene)
	battlePlay.Gate.ctor(self, scene)

	self.locals = {
		frame_id	= 0,
		who		 	= 0,
		skill       = 0,
		target      = 0,
		state    	= playerState.waitloading,
		scene_state = gsyncSceneState.waitloading,
	}
	self.remote = {}
	self.nexts = {}
	self.waitRecv = true
	self.isBattleTurnEnd = false
	self.sortOrderTb = {1,2,3,4,5,6,  7,8,9,10,11,12}
	-- self.awardRemainTime = 3 -- 奖励剩余次数
	-- self.deadList = {} -- 死亡清单
	-- self.hpSumTab = {{},{}}
end

function SyncFightGate:init(data)
	battlePlay.Gate.init(self, data)

	self:initSyncFightData()


	self.locals.scene_state = gGameModel.battle.state:read()

	-- gRootViewProxy:notify("changeOnlineViewState",self.locals.scene_state)
	printDebug("operateForce %d",self.operateForce)
	gGameModel.battle:register({
		[gsyncSceneState.attack] = function()
			-- waitloading -> attack
			if self.locals.scene_state == gsyncSceneState.waitloading then
				self.locals.scene_state = gsyncSceneState.attack

				self:initLocalState()
				-- 存在出手英雄才能改变state  否则通过onNewBattleTurn修改
				battleEasy.queueNotify('playOnlineFightState')
				-- gRootViewProxy:notify("changeOnlineViewState",self.locals.scene_state)
				-- battlePlay.Gate.newWaveGoon(self)
			end
		end,
		-- [gsyncSceneState.battleover] = function()
		-- end,
	})

	idlereasy.when(gGameModel.battle.error,function(_,err)
		if err and err ~= "" then
			gGameUI:switchUI("city.view")
			gGameUI:showTip(gLanguageCsv.onlineFightBanError)
		end
	end)

	if self.locals.scene_state == gsyncSceneState.waitloading then
		gGameModel.battle:ready()
	end
	gRootViewProxy:notify('showVsPvpView',1)

	-- self.locals.state = gsyncSceneState.wait

		-- self.nexts[self.locals.frame_id] = 12
	-- gGameApp.net:sendPacket('/realtime/input', {fordev={next=12}})

end

function SyncFightGate:initSyncFightData()
	self.locals.frame_id = 1
	gRootViewProxy:proxy():addSpecModule(battleModule.onlineFightMods)

	-- speedSortRank objId 通过sortOrderTb判断
	local len,index = table.length(self.sortOrderTb)
	for i=1,table.length(self.sortOrderTb) do
		index = ymrand.random(1,len - i + 1)
		table.swapvalue(self.sortOrderTb,len - i + 1,index)
	end
end

function SyncFightGate:getObjectBaseSpeedRankSortKey(obj)
	local seat = self.operateForce == 2 and battleEasy.mirrorSeat(obj.seat) or obj.seat
	return self.sortOrderTb[seat]
	-- return obj.id
end

function SyncFightGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function SyncFightGate:playEnterAnimation(cb)
	battlePlay.Gate.playEnterAnimation(self,cb)
	battleEasy.queueEffect('delay', {lifetime=1000})
	battleEasy.queueNotify('playOnlineFightState')
end

function SyncFightGate:runOneFrame()
	if self:isRemoteNotStart() then
		return true
	end

	local remote = self:getFrameInRemote(self.locals.frame_id)
	-- 如果操作的是己方 并且落后
	-- if self:isMyTurn() and gGameModel.battle:isLocalSlow(self.locals.frame_id) then
	-- 	remote = gGameModel.battle:getFrameInRemote(self.locals.frame_id + 1)
	-- end
	-- 操作阶段结束
	if remote then
		-- self:checkSpeedUp()
		printDebug(string.format("SyncFightGate onceBattle %d use skill(%d) attack %d",remote.who ,remote.skill, remote.target))
		self:mirrorData(remote)

		if self:getCurHeroSeat() ~= remote.who then
			errorInWindows("SyncFightGate curHeroSeat(%d),remote who(%d) is not same",self:getCurHeroSeat(),remote.who)
			-- 战报 出手不一致的时候飘字 战斗结束
			if self.locals.state == playerState.record then
				gGameUI:showTip(gLanguageCsv.crossCraftPlayNotExisted)
				return self:runGameEnd()
			else
				-- print("gLanguageCsv.battleErrorReloadGame")
				-- gGameUI:showTip(gLanguageCsv.battleErrorReloadGame)
				-- self.result = "fail"
				self.scene.isBattleAllEnd = true
				gGameUI:showDialog({content = gLanguageCsv.battleErrorReloadGame, cb = function()
					gGameUI:switchUI("city.view")
				end, btnType = 1, clearFast = true})
				return
			end
		end

		-- self:randomCountCheck(self.operateForce)

		self.curHero = self.scene:getObjectBySeat(remote.who)
		self.remote = remote
		-- 隐藏字幕
		battleEasy.queueNotify('hideStateTips')

		self:onceBattle(remote.target,remote.skill)
		self.locals.frame_id = self.locals.frame_id + 1

		if not self:isRemoteOver() then
			self:sendRandomCount()
		-- else
		-- 	self:runGameEnd()
		end
		return true
	end

	-- 等待阶段结束
	if self:isRemoteOver() then
		self:runGameEnd()
		return true
	end

	-- self.waitInput or self:beginBattleTurn()
	-- 等到输入 并且 是自己的回合
	-- if self.waitInput and self:isMyTurn() then
	-- 	-- 只有自动和手动
	-- 	if self:isAutoFight() then -- 自动发送 {frame_id,curHeroId,0,0}
	-- 		-- self.locals.frame_id = self.locals.frame_id + 1
	-- 		self.locals.who = self.curHero.seat
	-- 		self.locals.skill = 0
	-- 		self.locals.target = 0
	-- 		self:syncAction()
	-- 	elseif self.scene.handleInput then
	-- 		-- self.locals.frame_id = self.locals.frame_id + 1
	-- 		self.locals.who = self.curHero.seat
	-- 		self.locals.target = self.scene.handleInput[1]
	-- 		self.locals.skill = self.scene.handleInput[2]
	-- 		self.scene.handleInput = nil
	-- 		self:syncAction()
	-- 	end
	-- end

	return false
end

function SyncFightGate:setAttack(seat, skillId)
	-- 攻击状态 输入变为true
	if not self.waitRecv and self.locals.state == playerState.attack then
		battlePlay.Gate.setAttack(self,seat, skillId)
		self.locals.who = self.curHero.seat
		self.locals.target = self.handleInput[1]
		self.locals.skill = self.handleInput[2]
		self.handleInput = nil
		self.waitRecv = true
		self:syncAction()
	end
end

-- function SyncFightGate:newWaveGoon()
-- 	if self.locals.state ~= playerState.waitloading then
-- 		battlePlay.Gate.newWaveGoon(self)
-- 	end
-- end

-- function SyncFightGate:checkBattleEnd()
-- 	local isEnd, result = battlePlay.Gate.checkBattleEnd(self)
-- 	print('[TODO: TempLog] checkBattleEnd',isEnd, result)
-- 	if self:isRemoteOver() then
-- 		isEnd, result = true, "fail"
-- 	end
-- 	return isEnd, result
-- end

function SyncFightGate:isNowTurnAutoFight()
	if self.scene.autoFight then return true end
	if not self:isMyTurn() then return true end
    if self.curHero then
        if self.curHero:isSelfChargeOK() or self.curHero:isNeedAutoFightByBuff() then
            return true
        end
	end
	if self:getFrameInRemote(self.locals.frame_id + 1) then return true end
end

function SyncFightGate:isAutoFight()
	if self.scene.autoFight then return true end
	if self.curHero and (self.curHero:isNeedAutoFightByBuff() or self.curHero:isSelfChargeOK()) then return true end
	return false
end

-- function SyncFightGate:getEnemyForceInMyTurn()
-- 	if not self.curHero then return 2 end
-- 	return self.curHero.force == 1 and 2 or 1
-- end

-- function SyncFightGate:_onceBattle(targetId, skillId)
-- 	battleEasy.queueNotify('hideStateTips')

-- 	battlePlay.Gate.onceBattle(self,targetId,skillId)
-- 	-- auto
-- 	-- if targetId == 0 and skillId == 0 then
-- 	-- 	self.scene:setAutoFight(true)
-- 	-- 	battlePlay.Gate.onceBattle(self)
-- 	-- else
-- 	-- 	self.scene:setAutoFight(false)

-- 	-- end
-- 	-- self.scene:setAutoFight(_autoFight)
-- 	-- local target = self.scene:getObject(targetId)
-- 	-- local attack = {skill = skillId}

-- 	-- battlePlay.Gate.runBattleTurn(self, attack, target)
-- 	-- self:endBattleTurn(target)
-- end

function SyncFightGate:onceBattle(targetId, skillId)
	local _autoFight = self.scene.autoFight

	self.scene.autoFight = false
	-- 永远中断
	battlePlay.Gate.onceBattle(self,targetId,skillId)

	if self.locals.state ~= playerState.record then
		if self.locals.scene_state == gsyncSceneState.attack then
			self:initLocalState()
		elseif self.locals.scene_state == gsyncSceneState.waitloading then
			battleEasy.queueEffect(function()
				gRootViewProxy:call("showSKillUIWidgets",false)
			end)
		end
	end

	-- 显示字幕
	if self.waitInput then
		battleEasy.queueNotify('playOnlineFightState')
	end

	self.scene.autoFight = _autoFight
end

function SyncFightGate:initLocalState()
	self.locals.state = self:isMyTurn() and playerState.attack or playerState.wait
	-- 攻击状态 输入前 waitRecv == false
	self.waitRecv = self.locals.state ~= playerState.attack
end

function SyncFightGate:onNewBattleTurn()
	battlePlay.Gate.onNewBattleTurn(self)
	-- if not self.nexts[self.locals.frame_id] then
	-- 	self.nexts[self.locals.frame_id] = self.curHero.seat
	-- 	-- if not self:isMyTurn() then
	-- 	-- 	self.locals.frame_id = self.locals.frame_id + 1
	-- 	-- end
	-- 	print("!!!!!!!!!! onNewBattleTurn",self.locals.frame_id,self.curHero.seat,debug.traceback())
	-- 	gGameApp.net:sendPacket('/onlinefight/control', {next=(self.operateForce == 2 and battleEasy.mirrorSeat(self.curHero.seat) or self.curHero.seat)})
	-- end

	-- 同步反作弊的数据和表现
	if self.remote.hero_status and next(self.remote.hero_status) then
		for i=1,12 do
			local obj = self.scene:getObject(i)
			local data = self:parseHeroStatus(self.remote.hero_status[i])
			self:syncObjViewFromServer(obj,data)
		end
	end



	-- 下次能出手要等待, 不能出手要走一次endBattleTurn
	-- if not (self.waitInput or self:beginBattleTurn()) then
	-- 	self:endBattleTurn()
	-- end
end

local operNumByFunc = function(funcName,isGet)
	return function(ret,...)
		if isGet then
			return ret[funcName](ret)
		else
			return ret[funcName](ret,...)
		end
	end
end

local operNumByVal = function(funcName,isGet)
	return function(ret,v)
		if isGet then
			return ret[funcName]
		else
			ret[funcName] = v
		end
	end
end

local syncAttr = {
	hp  = {sync = 1,get = operNumByFunc("hp",true),set = operNumByFunc("setHP",false)},
	mp1  = {sync = 2,get = operNumByFunc("mp1",true),set = operNumByFunc("setMP1",false)},
	state  = {sync = 3,get = operNumByVal("state",true),set = operNumByVal("state",false)},
}

function SyncFightGate:syncObjViewFromServer(obj,data)
	if obj and data then
		local dropError = false
		local isDeath = obj:isDeath()
		for attr,v in pairs(syncAttr) do
			if not battleEasy.numEqual(v.get(obj),data[attr]) then
				dropError = true
				v.set(obj,data[attr])
			end
		end

		if dropError then
			-- gGameUI:showTip(gLanguageCsv.stateChangedResetPos)
			-- gGameUI:switchUI("city.view")
			battleEasy.queueEffect(function()
				-- printDebug(" !!!!!!!!! sync obj ",obj.id,dump(data))
				obj.view:proxy():onUpdateLifebar({
					mpPer = obj:mp1()/obj:mp1Max()*100,
					hpPer = obj:hp()/obj:hpMax()*100
				})
			end,{zOrder = battle.EffectZOrder.sync})

			if isDeath ~= obj:isDeath() then
				obj:setDead()
			end
		end
	end
end

function SyncFightGate:parseHeroStatus(status)
	if not status then return end
	local ret = {}
	for k,v in pairs(syncAttr) do
		ret[k] = status[v.sync]
	end
	return ret
end

function SyncFightGate:syncAction()
	printDebug(string.format("!!!!!!!!! onceBattle send frame:%d, who:%d, target:%d, skill:%d",self.locals.frame_id ,self.locals.who,self.locals.target,self.locals.skill))
	-- self.locals.state = playerState.recvaction
	self:mirrorData(self.locals)
	gGameModel.battle:attack(self.locals.frame_id,self.locals.who,self.locals.target,self.locals.skill)
end

function SyncFightGate:sendExitGameMsg()
	local isGiveUp = self.curRound > gCommonConfigCsv.onlineFightFleeRoundLimit
	if isGiveUp then
		gGameModel.battle:giveup()
	else
		-- 逃跑无奖励
		gGameModel.battle:flee()
	end
end

function SyncFightGate:makeEndViewInfos()
	local dailyRecord = gGameModel.daily_record
	local _, mvpPosId = self:whoHighestDamageFromStats(1)
	return {
		result = self.result,
		awardRemainTime = math.max(csv.cross.online_fight.base[1].matchTime - dailyRecord:read('cross_online_fight_times'),0),
		recordType = "jf", -- default:rank
		flag = "onlineFight",
		-- showReward = true,--dailyRecord:getIdler("cross_online_fight_times") <= csv.cross.online_fight.base[1].matchTimeMax,
		mvpPosId = self.operateForce == 2 and battleEasy.mirrorSeat(mvpPosId) or mvpPosId
	}
end

function SyncFightGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()
	-- local tb = {
	-- 	role_id = 'dbid', -- 角色id
	-- 	pattern = 1, -- 模式 1-非限制赛,2-公平赛
	-- 	result = 'win', -- 自己的结果
	-- 	delta = 10, -- 积分变化
	-- 	top_move = true, -- 历史最高
	-- 	award = {}, -- 战斗奖励

	-- 	unlimited_rank = 10, -- 无限制排名
	-- 	unlimited_score = 200, -- 无限制积分
	-- 	unlimited_top_rank = 10, -- 无限制赛历史最高排名
	-- 	limited_rank = 10, -- 公平赛排名
	-- 	limited_score = 200, -- 公平赛积分
	-- 	limited_top_rank = 10, -- 公平赛历史最高排名
	-- }

	if not (ANTI_AGENT or self.locals.state == playerState.record) then
		gGameApp.net:doRealtimeEnd()
	end

	gRootViewProxy:raw():postEndResultToServer("/game/cross/online/battle/end", function(tb)
		if tb and tb.view then
			if tb.view.pattern == 1 then
				tb.view.score = tb.view.unlimited_score
				-- tb.view.rank = tb.unlimited_rank
				tb.view.topRank = tb.view.unlimited_top_score
			elseif tb.view.pattern == 2 then
				tb.view.score = tb.view.limited_score
				-- tb.view.rank = tb.limited_rank
				tb.view.topRank = tb.view.limited_top_score
			end
			-- 适应pvp_win
			tb.view.rank_move = tb.view.delta
			tb.view.rank = tb.view.score
			tb.view.top_move = battleEasy.ifElse(tb.view.top_move,1,0)


			self.result = tb.view.result
			endInfos.result = tb.view.result
			endInfos.showReward = tb.view.award ~= nil
			endInfos.showMvpView = (tb.view.enemy_result == "fail" or tb.view.enemy_result == "giveup") and endInfos.mvpPosId
		else
			endInfos.fromRecord = true
			endInfos.showMvpView = false
			endInfos.showReward = false
		end
		-- showReward
		cb(endInfos, tb)
	end)
end

-- function SyncFightGate:_postEndResultToServer(cb)
-- 	local endInfos = self:makeEndViewInfos()
-- 	local data = self.scene.data
-- 	gRootViewProxy:raw():postEndResultToServer("/game/cross/online/battle/end", function(tb)
-- 		cb(endInfos, tb)
-- 	end, endInfos.result)
-- end

function SyncFightGate:mirrorData(t)
	if self.operateForce == 1 then
		return
	end
	if t.who ~= 0 then t.who = battleEasy.mirrorSeat(t.who) end
	if t.target ~= 0 then t.target = battleEasy.mirrorSeat(t.target) end
end

function SyncFightGate:getCurHeroSeat()
	if self.curHero then return self.curHero.seat end
	return 0
end

function SyncFightGate:isRemoteOver()
	return gGameModel.battle.remote.state == gsyncSceneState.battleover
end

function SyncFightGate:isRemoteNotStart()
	return gGameModel.battle.remote.state == gsyncSceneState.unknown
		or gGameModel.battle.remote.state == gsyncSceneState.waitloading
		or self.totalRoundBattleTurn < 1
end

function SyncFightGate:getFrameInRemote(frameId)
	return gGameModel.battle:getFrameInRemote(frameId)
end

function SyncFightGate:getoffLineTb()
	return gGameModel.battle.remote.offline
end

function SyncFightGate:getCountDown()
	local delta = math.ceil(math.max(gGameModel.battle.remote.countdown - (time.getTime() - gGameModel.battle.remote.countdown_timestamp),0))
	return time.getCutDown(delta)
end

function SyncFightGate:onBattleEndSupply()
	battleEasy.queueNotify('hideStateTips')
end

function SyncFightGate:sendRandomCount()
	return gGameModel.battle:sendRandomCount()
end

function SyncFightGate:isLocalSlow()
	if self.locals.state == playerState.record then
		return
	end
	return gGameModel.battle:isLocalSlow(self.locals.frame_id)
end
-- 服务器使用
function SyncFightGate:isWonderfulRecord()
	local force = self.result == "win" and 1 or 2
	local heros = self.scene:getHerosMap(force)
	local sumHp = {0,0}
	for _, obj in heros:order_pairs() do
		sumHp[1] = sumHp[1] + obj:hp()
		sumHp[2] = sumHp[2] + obj:hpMax()
	end
	return self:getTotalRounds() > gCommonConfigCsv.onlineFightWdfRecordRound
		and sumHp[2] > 0 and ((sumHp[1] / sumHp[2]) > gCommonConfigCsv.onlineFightWdfRecordLimit)
end

-- 战报
local SyncFightGateRecord = class("SyncFightGateRecord", SyncFightGate)
battlePlay.SyncFightGateRecord = SyncFightGateRecord

-- 战斗模式设置 自动
SyncFightGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= true,
	canHandle 		= true,
	canPause 		= true,
	canSpeedAni 	= false,
	canSkip 		= true,
}

SyncFightGateRecord.SpecEndRuleCheck = {}

function SyncFightGateRecord:init(data)
	battlePlay.Gate.init(self, data)

	self.frames = data.frames or {}
	self.locals.state = playerState.record
	self:initSyncFightData()
end

function SyncFightGateRecord:syncAction()
end

function SyncFightGateRecord:sendExitGameMsg()
	gGameUI:switchUI("city.view")
end

function SyncFightGateRecord:isRemoteOver()
	return table.length(self.frames) < self.locals.frame_id or table.length(self.frames) == 0
end

function SyncFightGateRecord:runGameEnd(result)
	-- self.result = self.data.result
	battlePlay.Gate.runGameEnd(self,self.data.result)
end

function SyncFightGateRecord:isRemoteNotStart()
	return self.totalRoundBattleTurn < 1
end

function SyncFightGateRecord:getFrameInRemote(frameId)
	if self.frames[frameId] then
		local data = self.frames[frameId].input
		return {
			frame_id = data[1],
			who = data[2],
			target = data[3],
			skill = data[4]
		}
	end
end

function SyncFightGateRecord:getoffLineTb()
	return {false,false}
end

function SyncFightGateRecord:getCountDown()
	return {sec = 15,clock_str = 15,secstr = 15}
end

function SyncFightGateRecord:isNowTurnAutoFight()
	return true
end

function SyncFightGateRecord:sendRandomCount()
	return false
end



