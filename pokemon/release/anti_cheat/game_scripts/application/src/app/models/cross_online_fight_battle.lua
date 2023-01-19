--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
--  实时对战数据源
--

local BaseBattleModel = require("app.models.battle")
local BattleModel = class("BattleModel", BaseBattleModel)

BattleModel.DefaultGateID = game.GATE_TYPE.crossOnlineFight

local gsyncSceneState = game.SYNC_SCENE_STATE

function BattleModel:getData()
	local data = BaseBattleModel.getData(self)
	if self.limited_card_deck == nil then -- 只有公平赛才有玩法天赋加成
		return data
	end
	-- 实时对战天赋加成
	initOnlineFightTalent()
	for pos, roleOut in pairs(data.roleOut) do
		local nature = csv.unit[roleOut.roleId].natureType
		local idx = game.TALENT_TYPE.battleFront
		if (pos > 3 and pos < 7) or (pos > 9 and pos < 13) then
			idx = game.TALENT_TYPE.battleBack
		end
		for attr, _ in pairs(gOnlineFightTalentAttrs) do
			local key = game.ATTRDEF_TABLE[attr]
			if roleOut[key] ~= nil then
				local const, percent = 0, 0
				-- 前后排
				if gOnlineFightTalentPositions[idx][attr] ~= nil then
					const = const + gOnlineFightTalentPositions[idx][attr][1]
					percent = percent + gOnlineFightTalentPositions[idx][attr][2]
				end
				-- 自然属性
				if gOnlineFightTalentNatures[nature][attr] ~= nil then
					const = const + gOnlineFightTalentNatures[nature][attr][1]
					percent = percent + gOnlineFightTalentNatures[nature][attr][2]
				end
				if percent > 0 then
					roleOut[key] = roleOut[key] * (1 + percent / 100.0)
				end
				if const > 0 then
					roleOut[key] = roleOut[key] + const
				end
			end
		end
	end
	return data
end

function BattleModel:getPreDataForEnd(roleOut)
	return {}
end

local CrossOnlineFightBattleModel = class("CrossOnlineFightBattleModel")

function CrossOnlineFightBattleModel:ctor(game)
	self.battle = BattleModel.new(game)
	self.battle.operateForceSwitch = true
	self.roles = {} -- 区分两个谁在左谁在右
	self.doCallbacks = {} -- {type: function}
	self.scene = nil -- 上层处理
	if game.battle then
		self.state = game.battle.state or idler.new(0)
		self.error = game.battle.error or idler.new('')
	else
		self.state = idler.new(0)
		self.error = idler.new('') -- 重连失败之后会set
	end

	self.inputs = {} -- local inputs
	self.locals = {
		frame_id = 0,
		who = 0,
		state = 0,
	}
	self.remote = {
		frame_id = 0,
		who = 0, -- 当前出手者
		state = 0,
		time = 0,
		offline = {}, -- 记录是否掉线
		countdown = 0,
		countdown_timestamp = 0,
		frames = {},
		hero_status = {}, -- 精灵状态同步，记录为frame执行结束时候的状态, {frame_id: {hp, mp, state}}
	}

	self.rand_counts = {}
end

function CrossOnlineFightBattleModel:init(tb)
	self.battle:init(tb)
	self.cheat = {
		tb = tb,
	}
	return self
end

function CrossOnlineFightBattleModel:getData()
	local datas = self.battle:getData()
	datas.role_key = self.battle.role_key
	datas.defence_role_key = self.battle.defence_role_key
	datas.role_frames = {self.battle.frame, self.battle.defence_frame}
	datas.game_keys = {self.battle.role_key[1], self.battle.defence_role_key[1]}

	if datas.operateForce == 2 then
		datas.role_key, datas.defence_role_key = datas.defence_role_key, datas.role_key
		table.swapvalue(datas.role_frames,1,2)
		table.swapvalue(datas.game_keys,1,2)
	end
	datas.frames = self.battle.attack_frames
	datas.result = self.battle.results[datas.operateForce]

	datas.limited_card_deck = self.battle.limited_card_deck
	datas.banpick_input_steps = self.battle.banpick_input_steps
	-- self.result = datas.results[datas.operateForce]

	datas.play_record_id = self.play_record_id
	datas.cross_key = self.cross_key
	datas.record_url = self.record_url

	return datas
end

function CrossOnlineFightBattleModel:setRoles(role1, role2)
	self.roles = {role1, role2}
end

function CrossOnlineFightBattleModel:setSceneModel(scene)
	self.scene = scene
end

function CrossOnlineFightBattleModel:fromServer(d,rand_counts)
	printDebug(' ***************************** CrossOnlineFightBattleModel.fromServer(d) !!!! ')
	printDebug(' --- who =%s, state= %s, frame_id=%s', d.who, d.state, d.frame_id, d.countdown, d.countdown_timestamp, d.time)
	printDebug('%s,%s',d.offline[1],d.offline[2])
	if rand_counts then
		printDebug('%s,%s',rand_counts[1],rand_counts[2])
	end

	self.remote.frame_id = d.frame_id
	self.remote.who = d.who
	self.remote.state = d.state
	self.state:set(d.state)
	self.remote.time = d.time
	self.remote.offline = d.offline
	self.remote.countdown = d.countdown
	self.remote.countdown_timestamp = d.countdown_timestamp

	self.rand_counts = rand_counts
	local lastframeid = 0
	local lastframe = self.remote.frames[#self.remote.frames]
	if lastframe then
		-- print('lastframe')
		-- print_r(lastframe)
		lastframeid = lastframe.input[1]
	end
	for _, frame in ipairs(d.frames) do -- frame = {input={frame_id, current, target, skill}}
		-- print('!!!')
		-- print_r(frame)
		if frame.input[1] > lastframeid then
			table.insert(self.remote.frames, frame)
			lastframeid = lastframeid + 1
		end
	end
	-- print('frames length', #self.remote.frames)
	if d.hero_status then
		self.remote.hero_status[d.frame_id] = d.hero_status
	end

	if self:isRegistered(self.remote.state) then
		self.doCallbacks[self.remote.state]()
	end
end

function CrossOnlineFightBattleModel:ready()
	local task = {
		ready = true,
	}
	self:sendPacket('/onlinefight/input', task)
end

function CrossOnlineFightBattleModel:giveup()
	local task = {
		giveup = true,
	}
	self:sendPacket('/onlinefight/input', task)
end

function CrossOnlineFightBattleModel:flee()
	local onlineFightFleeTime = userDefault.getForeverLocalKey("onlineFightFleeTime", {})
	if #onlineFightFleeTime >= 3 then
		for i = 1, 2 do
			onlineFightFleeTime[i] = onlineFightFleeTime[i+1]
		end
		onlineFightFleeTime[3] = time.getTime()
	else
		onlineFightFleeTime[#onlineFightFleeTime + 1] =  time.getTime()
	end
	userDefault.setForeverLocalKey("onlineFightFleeTime", onlineFightFleeTime)
	local task = {
		flee = true,
	}
	self:sendPacket('/onlinefight/input', task)
end

function CrossOnlineFightBattleModel:attack(frame_id,current, target, skill)
	self.locals.frame_id = frame_id
	self.locals.who = current
	table.insert(self.inputs, {frame_id, current, target, skill})
	-- TODO: 后续可以进行按帧优化批量发送
	self:toServer()
end

function CrossOnlineFightBattleModel:toServer()
	local task = {
		inputs = self.inputs,
		locals = self.locals,
		rand_count = ymrand.randCount
	}
	self.inputs = {}
	self:sendPacket('/onlinefight/attack', task)
end

local exitGameError = {
	["no battle"] = true,
	["no session"] = true,
}

function CrossOnlineFightBattleModel:sendPacket(url,data)
	gGameApp:requestPacket(url, function(ret, err)
		if err then
			if exitGameError[err.err] then
				gGameUI:showDialog({content = gLanguageCsv.curBattleOver, cb = function()
					gGameUI:switchUI("city.view")
				end, btnType = 1, clearFast = true})
			else
				errorInWindows("CrossOnlineFightBattleModel %s",err.err)
			end
		end
	end, data)
end

function CrossOnlineFightBattleModel:sendRandomCount()
	local task = {
		rand_count = ymrand.randCount,
	}
	self:sendPacket('/onlinefight/input', task)
end

function CrossOnlineFightBattleModel:register(callbacks)
	for k, v in pairs(callbacks) do
		self.doCallbacks[k] = v
	end
end

function CrossOnlineFightBattleModel:isRegistered(callbackKey)
	return self.doCallbacks[callbackKey] ~= nil
end

function CrossOnlineFightBattleModel:isLocalSlow(frame_id)
	if self.remote.frame_id == 0 then
		return
	end
	-- if frame_id < #self.remote.frames then
	-- 	return true
	-- end
	if (self.remote.frame_id - frame_id) > gCommonConfigCsv.onlineFightLateFrameLimit then
		return self.remote.frame_id - frame_id
	end
	return
end

function CrossOnlineFightBattleModel:getFrameInRemote(frame_id)
	--
	local data = self.remote.frames[frame_id]
	if data then
		data = data.input
		return {
			frame_id = data[1],
			who = data[2],
			target = data[3],
			skill = data[4],
			hero_status = self.remote.hero_status[frame_id+1]
		}
	-- elseif frame_id < self.remote.frame_id then
	end
end

function CrossOnlineFightBattleModel:checkCheat()
	return self.battle:checkCheat()
end

-- function CrossOnlineFightBattleModel:isRemoteOver()
-- 	return self.remote.state == gsyncSceneState.battleover
-- end

-- function CrossOnlineFightBattleModel:isRemoteStart()
-- 	return self.remote.state == gsyncSceneState.battleover
-- end

-- function CrossOnlineFightBattleModel:runOneFrame(play)
-- 	-- TODO:
-- 	if self.remote.state == gsyncSceneState.unknown or self.remote.state == gsyncSceneState.waitloading then
-- 		return
-- 	end

-- 	play:runOneFrame()
-- end

return CrossOnlineFightBattleModel