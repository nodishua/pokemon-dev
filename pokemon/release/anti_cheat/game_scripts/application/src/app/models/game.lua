 --
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- GameModel
--

local INIT_KEY = {
	cards = "cards",
	held_items = "held_items",
	gems = "gems",
	chips = "chips",
	society = "society",
	tasks = "tasks",
	daily_record = "record",
	monthly_record = "record",
	lottery_record = "record",
	fix_shop = "shop",
	union_shop = "shop",
	mystery_shop = "shop",
	explorer_shop = "shop",
	frag_shop = "shop",
	random_tower_shop = "shop",
	equip_shop = "shop",
	fishing_shop = "shop",
	capture = "capture",
	fishing = "fishing",
	reunion_record = "reunion_record",
	union = "union",
	random_tower = "random_tower",
}

local REQUIRE_BATTLE = {
	"battle",
	"arena_battle",
	"qiecuo", -- 好友切磋 同 friend_battle
	"endless_battle", -- 无尽塔
	"random_tower_battle", -- 随机塔
	"union_fuben_battle", -- 公会副本战斗
	"clone_battle", -- 元素挑战
	"hunting_battle", -- 远征
	"cross_arena_battle", -- 跨服PVP（跨服竞技场）战斗
	"cross_mine_battle", -- 跨服PVP（跨服资源战）
	"cross_mine_boss_battle", -- 跨服PVP（跨服资源战）
	"cross_supremacy_battle", -- 跨服PVP（世界锦标赛）
	"world_boss_battle", -- 世界Boss战斗
	"huodongboss_battle", -- 活动Boss战斗
	"brave_challenge_battle", -- 勇者挑战战斗
	"cross_online_fight_battle", -- 实时对战
	"gym_battle", -- 道馆副本战斗
	"gym_leader_battle", -- 道馆馆主战斗
	"cross_gym_battle", -- 跨服道馆战斗
	"summer_challenge_battle", -- 夏日挑战战斗
}

local REQUIRE_SYNC = {
	"arena", -- 竞技场的model是由handler构建返回的
	"union_fuben", -- 公会副本
	"clone_room", -- 元素实验房间
	"brave_challenge", -- 勇者挑战
	"hunting", -- 远征
	"union_training", -- 公会训练营
	"craft", -- 限时PVP（王者）
	"union_fight", -- 公会战
	"cross_craft", -- 跨服PVP（跨服王者）战斗
	"cross_arena", -- 跨服PVP（跨服竞技场）
	"cross_mine", -- 跨服PVP（跨服资源战）
	"cross_supremacy", -- 跨服PVP（世界锦标赛）
	"cross_online_fight", -- 实时对战
	"gym", -- 道馆
	"town", -- 家园
	"cross_union_fight", -- 跨服PVP（跨服部屋大作战）
}

local PLAYRECORDS = {
	arena_playrecords = "arena_battle",
	endless_playrecords = "endless_battle",
	craft_playrecords = "craft_battle", -- 限时PVP（王者）战斗
	union_fight_playrecords = "union_fight_battle", -- 公会战战斗
	cross_craft_playrecords = "cross_craft_battle", -- 跨服PVP（跨服王者）战斗
	cross_arena_playrecords = "cross_arena_battle", -- 跨服PVP（跨服竞技场）战斗
	gym_playrecords = "gym_leader_battle", -- 跨服PVP（道馆）战斗
	cross_mine_playrecords = "cross_mine_battle", -- 跨服PVP（跨服资源战）战斗
	cross_supermacy_playrecords = "cross_supremacy_battle", -- 跨服PVP（世界锦标赛）战斗
	cross_online_fight_playrecords = "cross_online_fight_battle", -- 跨服PVP（跨服资源战）战斗
	cross_union_fight_playrecords = "cross_union_fight_battle", -- 跨服PVP（跨服部屋大作战）战斗
}

local BATTLE_RECORD_URL = {
	["/game/pw/playrecord/get"] = "arena_playrecords",
	["/game/craft/playrecord/get"] = "craft_playrecords",
	["/game/union/fight/playrecord/get"] = "union_fight_playrecords",
	["/game/cross/craft/playrecord/get"] = "cross_craft_playrecords",
	["/game/cross/arena/playrecord/get"] = "cross_arena_playrecords",
	["/game/cross/online/playrecord/get"] = "cross_online_fight_playrecords",
	["/game/gym/playrecord/get"] = "gym_playrecords",
	["/game/cross/mine/playrecord/get"] = "cross_mine_playrecords",
	["/game/cross/supremacy/playrecord/get"] = "cross_supremacy_playrecords",
	["/game/endless/play/detail"] = "endless_playrecords",
	["/game/cross/union/fight/playrecord/get"] = "cross_union_fight_playrecords",
}

local GameModel = class("GameModel")

function GameModel:ctor()
	globals.gGameModel = self

	self.delaySyncCallback = nil

	self.account = require("app.models.account").new(self)
	self.role = require("app.models.role").new(self)
	self.messages = require("app.models.message").new(self)
	self.handbook = require("app.models.handbook").new(self)
	for key, name in pairs(INIT_KEY) do
		self[key] = require("app.models." .. name).new(self)
	end

	--单纯前端派发。
	self.currday_dispatch = require("app.models.currday_dispatch").new(self)
	self.forever_dispatch = require("app.models.forever_dispatch").new(self)
	self.currlogin_dispatch = require("app.models.currlogin_dispatch").new(self)

	self.battle = nil -- 延迟创建
	for records, _ in pairs(PLAYRECORDS) do
		self[records] = CMap.new()
	end

	self.csvVersion = 0
	self.syncVersion = 0

	-- server global record
	self.globalRecordLastTime = 0
	self.global_record = require("app.models.global_record").new(self)

	self.guideID = 0
	self._sync = {}
end

function GameModel:setNewGuideID(guideID)
	if guideID ~= self.guideID then
		self.guideID = guideID
		if self._sync.role == nil then
			self._sync.role = {}
		end
		self._sync.role['guideID'] = guideID
	end
end

function GameModel:syncData()
	local sync = self._sync
	sync.csv = self.csvVersion
	sync.sync = self.syncVersion
	sync.msg = self.messages.msgID
	sync.global_record_last_time = self.globalRecordLastTime
	self._sync = {}
	return sync
end

function GameModel:delaySyncOnce()
	self.delaySyncCallback = function()
		self.delaySyncCallback = nil
		idlersystem.endIntercept()
	end
	return self.delaySyncCallback
end

function GameModel:destroy()
	for k, v in pairs(self) do
		self[k] = nil
	end
end

function GameModel:syncFromServer(t)
	-- print_r(t)
	idlersystem.beginIntercept()

	-- 同步服务器时间
	if t.server_time then
		time.registerTime(time.SERVER_TIMEKEY, 1, t.server_time)
		t.server_time = nil
	end

	-- 同步服务器开服时间
	if t.server_openTime then
		game.SERVER_OPENTIME = t.server_openTime
		t.server_openTime = nil
	end

	-- 配表刷新
	if t.csv then
		self:initCSV(t.csv)
		t.csv = nil
	end

	-- model init
	if t.model then
		if t.model.account then
			self.account:init(t.model.account)
		end
		if t.model.role then
			self.role:init(t.model.role)
			self.handbook:init(t.model.role)
			self.currday_dispatch:init({
				vipGift = false,
				activityDirectBuyGift = false,
				firstRecharge = false,
				luckyCat = false,
				goldLuckyCat = false,
				randomTower = false,
				passport = false,
				sendedRedPacket = false,
				serverOpenItemBuy = {}, 	-- 开服嘉年华，限时折扣是否查看过记录，以game.TARGET_TYPE.ItemBuy作为记录type
				newPlayerWeffare = false,
				firstRechargeDaily = {},  -- 每日直购礼包，会开多个，记录yyid是否每日点过
			})
			self.forever_dispatch:init({
				activityItemExchange = {},
				chatPrivatalyLastId = 0, -- 记录上次打开私聊时的显示的最后一条聊天的id
				dispatchTasksNextAutoTime = 0,		-- 记录最新一次打开派遣任务 下次自动刷新时间（目前仅在5时和18时刷新), 0表示暂无记录，当有自动刷新过，且未打开过派遣任务界面时，需要红点提示
				dispatchTasksRedHintRefrseh = false, -- 派遣任务红点刷新，配合dispatchTasksNextAutoTime 在线刷新，值并无实际意义，只是通过true/false的变动去检测红点状态
				battleManualDatas = false,
				exclusiveLimitDatas = false,
				customizeGiftClick = false,         -- 定制礼包首次红点提示
				cloneBattleLookRobot = false,        -- 判断元素挑战是否查看过
				cloneBattleLookHistory = 0,        		-- 判断元素挑战变更记录刷新
				reunionBindPlayer = 0, 				-- 判断回归玩家是否进入过绑定界面，记录当前活动ID
				braveChallengeEachClick = 0,		-- 循环勇者挑战周期玩法，每期开启的时候一次性红点提示
				crossUnionFightTime = 0					-- 跨服公会战周期玩法，每期开启的时候一布阵一次性提示
			})
			-- 本次登陆缓存数据
			self.currlogin_dispatch:init({
				rechargeWheelSkip = false,
				livenessWheelSkip = false,
			})
		end

		for key, _ in pairs(INIT_KEY) do
			if t.model[key] then
				self[key]:init(t.model[key])
			end
		end
		if t.model.cards then
			self.cards:initNewFlag()
		end

		for _, name in ipairs(REQUIRE_BATTLE) do
			if t.model[name] then
				self.battle = require("app.models." .. name).new(self):init(t.model[name])
			end
		end

		for _, name in ipairs(REQUIRE_SYNC) do
			if t.model[name] then
				if self[name] == nil then
					self[name] = require("app.models." .. name).new(self)
				end
				self[name]:syncFrom(t.model[name], true)
			end
		end

		for records, name in pairs(PLAYRECORDS) do
			if t.model[records] then
				for k, v in pairs(t.model[records]) do
					local battle = require("app.models." .. name).new(self):init(v)
					self[records]:insert(k, battle)
				end
			end
		end

		-- 实时对战
		if t.model.cross_online_fight_banpick then
			local banpick = require('app.models.cross_online_fight_banpick').new(self):init(t.model.cross_online_fight_banpick)
			self.cross_online_fight_banpick = banpick
		end

		self:afterSync(t.model)
		t.model = nil
	end

	-- model sync
	if t.sync then
		self:doSync(t.sync)
		t.sync = nil
	end

	-- messages
	if t.msg then
		self.messages:addMessage(t.msg)
		t.msg = nil
	end

	-- 服务器数据刷新
	if t.global_record then
		self.global_record:syncFrom(t.global_record, true)
		self.globalRecordLastTime = t.global_record.last_time
		t.global_record = nil
	end

	if not self.delaySyncCallback then
		idlersystem.endIntercept()
	end
	return t
end

function GameModel:doSync(sync)
	if sync.version then
		self.syncVersion = sync.version
	end
	-- 数据更新
	if sync.upd then
		local upd = sync.upd
		local new = sync.new or {}
		for model, data in pairs(upd) do
			if model == "role" then
				self.handbook:syncFrom(data, new[model])
				if data['_db'] and data['_db']['union_db_id'] ~= nil then -- 公会id变动，清理之前消息
					self.messages:resetChannel('union')
				end
			end
			self[model]:syncFrom(data, new[model])
		end
	end
	-- 数据删除
	if sync.del then
		for model, data in pairs(sync.del) do
			if model == "role" then
				self.handbook:syncDel(data)
				if data['_db'] and data['_db']['union_db_id'] ~= nil then -- 公会id变动，清理之前消息
					self.messages:resetChannel('union')
				end
			end
			self[model]:syncDel(data)
		end
	end

	if sync.upd then
		self:afterSync(sync.upd)
	end
	if sync.del then
		self.role:afterDelSync(sync.del.role)
	end
end

function GameModel:afterSync(upd)
	self.tasks:afterSync(upd.tasks)
	self.role:afterSync(upd.role)
	self.role:checkTargetChanged(upd)
end

function GameModel:initCSV(tb)
	if tb.version <= self.csvVersion then
		return
	end
	print('csv sync version', self.csvVersion, tb.version)
	self.csvVersion = tb.version
	-- 默认是简体中文
	if LOCAL_LANGUAGE ~= 'cn' then
		-- setRemoteL10nText(tb.data)
	end
	csv.yunying = tb.data.yunying
end

-- 特殊上层修改数据，没走通用处理
function GameModel:getEndlessPlayRecord(recordID)
	return self.endless_playrecords:find(recordID)
end

function GameModel:playRecordBattle(play_record_id, cross_key, interface, exChangeType, roleId)
	local key = BATTLE_RECORD_URL[interface]
	local battle = self[key]:find(play_record_id)
	if not battle then
		gGameApp:requestServer(interface, function(tb)
			battle = self[key]:find(play_record_id)
			if battle then
				self:playRecordBattle(play_record_id, cross_key, interface, exChangeType, roleId)
			end
		end, play_record_id, cross_key)
		return
	end

	battle.play_record_id = play_record_id
	battle.cross_key = cross_key
	battle.record_url = interface

	local data = battle:getData()
	if data.limited_card_deck and data.banpick_input_steps then
		gGameUI:stackUI("city.pvp.online_fight.ban_embattle", nil, {full = true}, {recordData = data, startFighting = functools.partial(self.onPlayRecord, self, battle)})
		return
	end

	self:onPlayRecord(battle)
end

function GameModel:onPlayRecord(battle)
	local data = battle:getData()
	local result = battle.result or data.result
	-- exChangeType 0.不换 1.必定换 2.根据roleId判断是否替换
	-- if (exChangeType == 1) or (exChangeType == 2 and data.role_db_ids[2] == roleId) then
	-- 	data = battleEntrance.exchangeLR(data)
	-- 	result = data.result
	-- end

	battleEntrance.battleRecord(data, result, {noShowEndRewards=true})
		:preCheck(nil, function()
			gGameUI:showTip(gLanguageCsv.crossCraftPlayNotExisted)
		end)
		:show()
end

function GameModel:playRecordDeployInfo(play_record_id, cross_key, interface, cbFunc)
	local key = BATTLE_RECORD_URL[interface]
	local battle = self[key]:find(play_record_id)
	if not battle then
		gGameApp:requestServer(interface, function(tb)
			battle = self[key]:find(play_record_id)
			if battle then
				return self:playRecordDeployInfo(play_record_id, cross_key, interface, cbFunc)
			end
		end, play_record_id, cross_key)
		return
	end

	cbFunc(battle.cheat.tb)
end


return GameModel
