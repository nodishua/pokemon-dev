--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- Role
--

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local Base = require("app.models.base")
local Role = class("Role", Base)

function Role:init(t)
	Base.init(self, t)

	self.yyhuodong_tasks = {}
	local yy_endtime = idlereasy.new({}, 'yy_endtime')
	self.__idlers:add('yy_endtime', yy_endtime)
	self:refreshYYEndTime()

	local active_logos = idlereasy.new({}, 'active_logos')
	self.__idlers:add('active_logos', active_logos)
	self:refreshActiveLogos()

	self:filterYYHuodongs()

	local buy_recharge = idlereasy.new({}, 'buy_recharge')
	self.__idlers:add('buy_recharge', buy_recharge)
	return self
end

local GeneralTaskDefs = game.TARGET_TYPE

-- {model, field, {当前进度，总进度}}
local YYHuoDongTasksWatchTargetMap = {
	[GeneralTaskDefs.Level] = {'role', 'level'},
	[GeneralTaskDefs.Gate] = {'role', 'gate_star', function(gate_star, arg, argsD, cache)
		local ret = 0
		if gate_star[arg] and gate_star[arg].star > 0 then
			ret = 1
		end
		return {ret, 1}
	end},
	[GeneralTaskDefs.CardsTotal] = {'role', 'cards', function(cards, arg, argsD, cache)
		-- itertools.size was O(N)
		cache.CardsTotal = cache.CardsTotal or itertools.size(cards)
		return {cache.CardsTotal, arg}
	end},
	-- [GeneralTaskDefs.Equip] = {nil, nil, nil}, -- todo
	[GeneralTaskDefs.Vip] = {'role', 'vip_level'},
	[GeneralTaskDefs.FightingPoint] = {'role', 'battle_fighting_point'},
	[GeneralTaskDefs.CardAdvanceTotalTimes] = {'role', 'card_advance_times'},
	[GeneralTaskDefs.GateStar] = {'role', 'gate_star_sum'},
	[GeneralTaskDefs.CardAdvanceCount] = {'cards', nil, function(cards, arg, argsD, cache)
		local num, adv = csvNext(argsD)
		local stat = cards:getStat()
		local ret = stat.advance_sum:sumRange(adv)
		return {ret, num}
	end},
	[GeneralTaskDefs.CardStarCount] = {'cards', nil, function(cards, arg, argsD, cache)
		local num, star = csvNext(argsD)
		local stat = cards:getStat()
		local ret = stat.star_sum:sumRange(star)
		return {ret, num}
	end},
	[GeneralTaskDefs.EquipAdvanceCount] = {'cards', nil, function(cards, arg, argsD, cache)
		local num, adv = csvNext(argsD)
		local stat = cards:getStat()
		local ret = stat.equip_advance_sum:sumRange(adv)
		return {ret, num}
	end},
	[GeneralTaskDefs.EquipStarCount] = {'cards', nil, function(cards, arg, argsD, cache)
		local num, star = csvNext(argsD)
		local stat = cards:getStat()
		local ret = stat.equip_star_sum:sumRange(star)
		return {ret, num}
	end},
	[GeneralTaskDefs.HadCard] = {'cards', nil, function(cards, arg, argsD, cache)
		local stat = cards:getStat()
		return {stat.card_id[arg] and 1 or 0, 1}
	end},
	[GeneralTaskDefs.GainCardTimes] = {},
	[GeneralTaskDefs.CompleteImmediate] = {nil, nil, function(...)
		return {1, 1}
	end},
	[GeneralTaskDefs.OnlineDuration] = {},
	[GeneralTaskDefs.LoginDays] = {},
	[GeneralTaskDefs.LianjinTimes] = {},
	[GeneralTaskDefs.GainGold] = {},
	[GeneralTaskDefs.CostGold] = {},
	[GeneralTaskDefs.CostRmb] = {},
	[GeneralTaskDefs.RechargeRmb] = {},
	[GeneralTaskDefs.ShareTimes] = {},
	-- [GeneralTaskDefs.KillMonster] = {},
	[GeneralTaskDefs.SigninTimes] = {},
	[GeneralTaskDefs.BuyStaminaTimes] = {},
	[GeneralTaskDefs.GiveStaminaTimes] = {},
	[GeneralTaskDefs.CostStamina] = {},
	[GeneralTaskDefs.GateChanllenge] = {},
	[GeneralTaskDefs.HeroGateChanllenge] = {},
	[GeneralTaskDefs.NightmareGateChanllenge] = {},
	[GeneralTaskDefs.HuodongChanllenge] = {},
	[GeneralTaskDefs.GateSum] = {},
	[GeneralTaskDefs.CardSkillUp] = {},
	[GeneralTaskDefs.CardAdvance] = {},
	[GeneralTaskDefs.CardLevelUp] = {},
	[GeneralTaskDefs.CardStar] = {},
	[GeneralTaskDefs.EquipStrength] = {},
	[GeneralTaskDefs.EquipAdvance] = {},
	[GeneralTaskDefs.EquipStar] = {},
	[GeneralTaskDefs.ArenaBattle] = {},
	[GeneralTaskDefs.ArenaBattleWin] = {},
	[GeneralTaskDefs.ArenaPoint] = {},
	[GeneralTaskDefs.ArenaRank] = {'role', 'pw_rank'},
	[GeneralTaskDefs.DrawCard] = {},
	[GeneralTaskDefs.DrawCardRMB10] = {},
	[GeneralTaskDefs.DrawCardRMB1] = {},
	[GeneralTaskDefs.DrawCardGold10] = {},
	[GeneralTaskDefs.DrawCardGold1] = {},
	[GeneralTaskDefs.DrawCardRMB] = {},
	[GeneralTaskDefs.DrawCardGold] = {},
	[GeneralTaskDefs.DrawEquip] = {},
	[GeneralTaskDefs.DrawEquipRMB10] = {},
	[GeneralTaskDefs.DrawEquipRMB1] = {},
	[GeneralTaskDefs.UnionContrib] = {},
	[GeneralTaskDefs.UnionSpeedup] = {},
	[GeneralTaskDefs.UnionSendPacket] = {},
	[GeneralTaskDefs.UnionRobPacket] = {},
	[GeneralTaskDefs.UnionFuben] = {},
	[GeneralTaskDefs.RandomTowerTimes] = {},
	[GeneralTaskDefs.RandomTowerBoxOpen] = {},
	[GeneralTaskDefs.RandomTowerPointDaily] = {'random_tower', 'day_point'},
	[GeneralTaskDefs.RandomTowerPoint] = {},
	[GeneralTaskDefs.RandomTowerFloorTimes] = {},
	[GeneralTaskDefs.WorldBossBattleTimes] = {},
	[GeneralTaskDefs.CloneBattleTimes] = {},
	[GeneralTaskDefs.RandomTowerFloorMax] = {},
	-- [GeneralTaskDefs.AllCanItems] = {},
	-- [GeneralTaskDefs.CardComb] = {},
	[GeneralTaskDefs.DailyTaskFinish] = {},
	[GeneralTaskDefs.DailyTaskAchieve] = {},
	[GeneralTaskDefs.ItemBuy] = {},
	[GeneralTaskDefs.YYHuodongOpen] = {},
	[GeneralTaskDefs.UnlockPokedex] = {'role', 'pokedex', function(pokedex, arg, argsD, cache)
		cache.UnlockPokedex = cache.UnlockPokedex or itertools.size(pokedex)
		return {cache.UnlockPokedex, arg}
	end},
	[GeneralTaskDefs.EndlessPassed] = {'role', 'endless_tower_max_gate', function(gate, arg, argsD, cache)
		local passed = gate >= arg and 1 or 0
		return {passed, 1}
	end},
	[GeneralTaskDefs.Friends] = {'society', 'friends', function(friends, arg, argsD, cache)
		cache.Friends = cache.Friends or itertools.size(friends)
		return {cache.Friends, arg}
	end},
	[GeneralTaskDefs.TrainerLevel] = {'role', 'trainer_level'},
	[GeneralTaskDefs.CaptureLevel] = {'capture', 'level'},
	[GeneralTaskDefs.CaptureSuccessSum] = {'capture', 'success_sum'},
	[GeneralTaskDefs.Explorer] = {'role', 'explorers', function(explorers, arg, argsD, cache)
		cache.Explorer = cache.Explorer or itertools.count(explorers, function(_, t) return t.advance > 0 end)
		return {cache.Explorer, arg}
	end},
	[GeneralTaskDefs.ExplorerComponentStrength] = {},
	[GeneralTaskDefs.ExplorerAdvance] = {},
	[GeneralTaskDefs.DispatchTaskDone] = {},
	[GeneralTaskDefs.DispatchTaskQualityDone] = {nil, nil, function(val, arg, argsD, cache)
		local num, quality = csvNext(argsD)
		return {val, num}
	end},
	[GeneralTaskDefs.HeldItemStrength] = {},
	[GeneralTaskDefs.HeldItemAdvance] = {},
	[GeneralTaskDefs.EffortTrainTimes] = {},
	[GeneralTaskDefs.EffortGeneralTrainTimes] = {},
	[GeneralTaskDefs.EffortSeniorTrainTimes] = {},
	[GeneralTaskDefs.CardAbilityStrength] = {},
	[GeneralTaskDefs.DrawItem] = {},
	[GeneralTaskDefs.DrawCardUp] = {},
	[GeneralTaskDefs.DrawCardUpAndRMB] = {},
	[GeneralTaskDefs.UnionFragDonate] = {},
	[GeneralTaskDefs.DrawGemRMB] = {},
	[GeneralTaskDefs.DrawGemGold] = {},
	[GeneralTaskDefs.DrawGem] = {},
	[GeneralTaskDefs.DrawGemUp] = {},
	[GeneralTaskDefs.DrawGemUpAndRMB] = {},
	[GeneralTaskDefs.FishingTimes] = {},
	[GeneralTaskDefs.FishingWinTimes] = {},
	[GeneralTaskDefs.RandomTowerFloorSum] = {},
	[GeneralTaskDefs.DrawChipRMB] = {},
	[GeneralTaskDefs.DrawChipItem] = {},
	[GeneralTaskDefs.DrawChip] = {},
}

local YYHuoDongTasksWatchModelFieldSet = {}
for _, watch in pairs(YYHuoDongTasksWatchTargetMap) do
	local model, field, func = unpack(watch)
	if model ~= nil then
		if field then
			if YYHuoDongTasksWatchModelFieldSet[model] == nil then
				YYHuoDongTasksWatchModelFieldSet[model] = {}
			end
			YYHuoDongTasksWatchModelFieldSet[model][field] = true
		else
			YYHuoDongTasksWatchModelFieldSet[model] = true
		end
	end
end

local YYHuoDongTypeUseTask = {
	[YY_TYPE.generalTask] = true, -- 14
	[YY_TYPE.serverOpen] = true, -- 15
	[YY_TYPE.livenessWheel] = true, -- 39
	[YY_TYPE.flipCard] = true, -- 48
	[YY_TYPE.flipNewYear] = true, -- 56
}

local YYHuoDongTypeTaskCsvMap = {
	[YY_TYPE.generalTask] = function()
		return csv.yunying.generaltask
	end,
	[YY_TYPE.serverOpen] = function()
		return csv.yunying.serveropen
	end,
	[YY_TYPE.livenessWheel] = function()
		return csv.yunying.generaltask
	end,
	[YY_TYPE.flipCard] = function()
		return csv.yunying.flop_task
	end,
	[YY_TYPE.flipNewYear] = function()
		return csv.yunying.jifu_task
	end,
}

local function isTargetChanged(db)
	-- special for yyhuodongs
	if db.yyhuodongs then
		for yyID, _ in pairs(db.yyhuodongs) do
			local cfg = csv.yunying.yyhuodong[yyID]
			if cfg and YYHuoDongTypeUseTask[cfg.type] then
				return true
			end
		end
	end
	return false
end

local function isTargetChangedByGame(gameDB)
	-- other watch
	for model, t in pairs(YYHuoDongTasksWatchModelFieldSet) do
		if gameDB[model] ~= nil and gameDB[model]._db ~= nil then
			if type(t) == "table" then
				for field, _ in pairs(t) do
					if gameDB[model]._db[field] ~= nil then
						return true
					end
				end
			else
				return true
			end
		end
	end
	return false
end

-- @param targetType: cfg.taskType
-- @param arg: cfg.taskParam
-- @param argsD: cfg.taskSpecialParam
-- @param cache: for batching and nil was ok
local function getTargetProgress(targetType, val, arg, argsD, cache)
	cache = cache or {}
	local model, field, func = unpack(YYHuoDongTasksWatchTargetMap[targetType])
	if model ~= nil then
		local obj = gGameModel[model]
		if field then
			local v = obj:getValue_(field)
			if v == nil then
				-- NOTE: 如果有unlock控制的系统，需要的数据需自己处理相关key为nil的情况
				return func and func(0, arg, argsD, cache) or {0, arg}
			end
			return func and func(v, arg, argsD, cache) or {v, arg}
		else
			return func(obj, arg, argsD, cache)
		end
	else
		return func and func(val, arg, argsD, cache) or {val, arg}
	end
end

-- two parts check
-- 1. role.yyhuodongs
-- 2. other model
function Role:checkTargetChanged(gameDB)
	if gameDB and isTargetChangedByGame(gameDB) then
		self:cleanYYHuoDongTasksProgress()
	end
end

function Role:getYYHuoDongTasksProgress(yyID)
	if self.yyhuodong_tasks[yyID] == nil then
		-- not use pairs(upd._db.yyhuodongs)
		-- yyhuodongs progress value not be changed in some type, like RandomTowerPointDaily
		-- so pairs all yyhuodongs in model
		local yyhuodongs = self:read('yyhuodongs')
		self:_syncYYHuoDongTasksProgress(yyID, yyhuodongs[yyID])
	end

	return self.yyhuodong_tasks[yyID]
end

function Role:_syncYYHuoDongTasksProgress(yyID, tb)
	-- http://172.81.227.66:1104/crashinfo?_id=6318&type=1
	-- bug on 5:00 AM
	if tb == nil then return end

	local cfg = csv.yunying.yyhuodong[yyID]
	if not (cfg and YYHuoDongTypeUseTask[cfg.type]) then
		return
	end

	local progress = {}
	self.yyhuodong_tasks[yyID] = progress
	local huodongID = cfg.huodongID
	local csvTasks = YYHuoDongTypeTaskCsvMap[cfg.type]()
	for k, v in csvPairs(csvTasks) do
		if v.huodongID == huodongID then
			if YYHuoDongTasksWatchTargetMap[v.taskType] then
				local val = tb.valsums and tb.valsums[k] or 0
				progress[k] = getTargetProgress(v.taskType, val, v.taskParam, v.taskSpecialParam, self._taskProgressCache)
			else
				error('yy genernal task target ' .. v.taskType .. ' not watched!')
			end
		end
	end
end

function Role:updSync(tb, tbnew)
	if tb.titles then
		self.title_queue = {}
		for k, _ in pairs(tb.titles) do
			self.title_queue[k] = true
		end
	end

	if tb.achievement_tasks then
		self.achievement_queue = {}
		for k, v in pairs(tb.achievement_tasks) do
			if v[1] == 1 then
				self.achievement_queue[k] = true
			end
		end
	end

	self:_updYYCoin()
	Base.updSync(self, tb, tbnew)
end

function Role:cleanYYHuoDongTasksProgress()
	self._taskProgressCache = {}
	self.yyhuodong_tasks = {}
end

function Role:afterSync(upd)
	if self.__idlers == nil then return end -- in login

	self.achievementCache = {}

	if upd and upd._db then
		if upd._db.explorers then
			self.explorersCache = {}
		end
		if upd._db.gate_star then
			self.gateStarCache = {}
		end
		if isTargetChanged(upd._db) then
			self:cleanYYHuoDongTasksProgress()
		end
		if upd._db.skins or upd._db.figures or upd._db.pokedex or upd._db.logos then
			self:refreshActiveLogos()
		end

		-- 同步服务器时间差值修正
		local last_time = upd._db.last_time
		if last_time then
			self.sync_last_time = self.sync_last_time or 0
			if math.abs(self.sync_last_time - last_time) > 3 and math.abs(time.getTime() - last_time) > 3 then
				self.sync_last_time = last_time
				gGameApp:slientRequestServer("/game/sync")
			end
		end
	end

	if upd and upd._mem then
		if upd._mem.yy_open then
			local opens = self:read('yy_open')
			local yy_open = {}
			for _, yyID in ipairs(opens) do
				if not self._disableYYIDs[yyID] then
					table.insert(yy_open, yyID)
				end
			end
			self:getOrNewRawIdler_('yy_open'):set(yy_open)
		end
		if upd._mem.yy_delta then
			self:refreshYYEndTime()
		end
	end
end

function Role:afterDelSync(del)
	if self.__idlers == nil then return end -- in login

	if del and del._db and del._db.skins then
		self:refreshActiveLogos()
	end
end

function Role:refreshYYEndTime()
	local t = time.getTime()
	local deltas = self:read('yy_delta')
	local endTime = {}
	for k, v in pairs(deltas) do
		endTime[k] = v + t
		-- kr 活动结束时间点会出现 周日 23:59:59, 大于23点59分的加上对应秒数时间到下一天
		local date = time.getDate(endTime[k])
		if date.hour * 100 + date.min > 2359 then
			date.min = date.min + 1
			date.sec = 0
			endTime[k] = time.getTimestamp(date)
		end
	end
	self:getOrNewRawIdler_('yy_endtime'):set(endTime)
end

function Role:refreshActiveLogos()
	local raw_logos = self:read("logos")
	local pokedex = self:read("pokedex")
	local figures = self:read("figures")
	local skins = self:read("skins")
	local logos = {}
	for k,v in pairs(gRoleLogoCsv) do
		if (v.cardID and pokedex[v.cardID]) or (v.itemID and raw_logos[k]) or (v.roleID and figures[v.roleID]) then
			logos[k] = 0
		elseif v.skinID and skins[v.skinID] then
			logos[k] = skins[v.skinID]
		end
	end
	self:getOrNewRawIdler_('active_logos'):set(logos)
end

local function isGetAllAwards(yyID, stamps, csvT)
	local huodongID = csv.yunying.yyhuodong[yyID].huodongID
	for k, v in orderCsvPairs(csvT) do
		if v.huodongID == huodongID and stamps[k] ~= 0 then
			return false
		end
	end
	return true
end

function Role:filterYYHuodongs()
	local yyhuodongs = self:read('yyhuodongs')
	self._disableYYIDs = {}
	for yyID, v in pairs(yyhuodongs) do
		local cfg = csv.yunying.yyhuodong[yyID]
		if cfg then
			if cfg.type == YY_TYPE.levelFund then
				if isGetAllAwards(yyID, v.stamps or {}, csv.yunying.levelfund) then
					self._disableYYIDs[yyID] = true
				end
			end
			-- generalTask 全部领取完后，不再显示
			if cfg.type == YY_TYPE.generalTask then
				if cfg.clientParam.generalTaskDisappear and isGetAllAwards(yyID, v.stamps or {}, csv.yunying.generaltask) then
					self._disableYYIDs[yyID] = true
				end
			end
		end
	end
end

function Role:getYYCoin(yyID)
	local cfg = csv.yunying.yyhuodong[yyID]
	if cfg == nil or self.yycoins[cfg.type] == nil or self.yycoins[cfg.type][1] ~= yyID then
		return 0
	end
	return self.yycoins[cfg.type][2]
end

function Role:setYYCoin(yyID)
	self.yycoinYYID = yyID
	self:_updYYCoin()
end

function Role:_updYYCoin()
	if self.yycoinYYID then
		self.yycoin = self:getYYCoin(self.yycoinYYID)
	end
end

-- {当前进度， 总进度}
function Role:getTitleProgress(targetType, arg1, arg2)
	if YYHuoDongTasksWatchTargetMap[targetType] then
		local val = 0
		if targetType == game.TARGET_TYPE.CostRmb then
			val = self:read('rmb_consume')
		elseif targetType == game.TARGET_TYPE.SigninTimes then
			val = self:read('sign_in_count')
		else
			val = self:read('title_counter')[targetType] or 0
		end
		return getTargetProgress(targetType, val, arg1, arg2)
	else
		error('title target' .. targetType .. 'not watched!')
	end
end

function Role:pushBuyRecharge(t)
	gGameApp:slientRequestServer("/game/sync")
	local idler = self:getOrNewRawIdler_('buy_recharge')
	idler:modify(function(val)
		table.insert(val, t)
	end, true)
end

local AchieveDefs = {

	-- 人物成长
	Level = 1,  -- 战队等级
	TrainerLevel = 2,  -- 冒险执照等级
	TrainerPrivilege = 3,  -- 冒险执照特权属性点累计等级

	TalentOne = 4,  -- 某个天赋类型投入了x点天赋点
	TalentAll = 5,  -- 总天赋投入了多少点天赋点
	ExplorerActiveCount = 6,  -- 已激活探险器数量
	ExplorerActive = 7,  -- 激活指定探险器
	ExplorerLevel = 8,  -- 任意探险器的等级达到多少
	FightingPoint = 9,  -- 战力达到多少
	GoldCount = 10,  -- 拥有多少数量金币
	CostGoldCount = 11,  -- 消耗多少数量金币
	RmbCount = 12,  -- 拥有多少数量钻石
	CostRmbCount = 13,  -- 消耗多少数量钻石

	-- 精灵收集
	CardCount = 14,  -- 精灵的收集数量（图鉴总数）
	CardNatureCount = 15,  -- x属性精灵的收集x个( 图鉴数量)

	-- 精灵成长
	CardLevelCount = 16,  -- x等级的卡牌有x个
	CardAdvanceCount = 17,  -- x品质的卡牌有x个
	CardStarCount = 18,  -- x星数的卡牌有x个
	EffortGeneralTrainTimes = 19,  -- 任意精灵努力值普通培养x次
	EffortSeniorTrainTimes = 20,  -- 任意精灵努力值高级培养x次
	EquipAdvanceCount = 21,  -- x品质饰品有x个
	EquipAwakeCount = 22,  -- x觉醒饰品有x个
	HeldItemLevelCount = 23,  -- x等级携带道具有x个
	HeldItemQualityCount = 24,  -- x品质携带道具有x个
	FeelLevelCount = 25,  -- x等级好感度有x个

	-- 副本活动
	GateChallenge = 26,  -- 挑战普通关卡次数
	GateStarCount = 27,  -- x星普通关卡x个
	GatePass = 28,  -- 关卡通关
	HeroGateChallenge = 29,  -- 挑战精英关卡次数
	HeroGateStarCount = 30,  -- x星精英关卡x个
	HeroGatePass = 31,  -- 某精英关卡通关
	GoldHuodongPassCount = 32,  -- 金币副本累计通关多少次
	ExpHuodongPassCount = 33,  -- 经验副本累计通关多少次
	GiftHuodongPassCount = 34,  -- 礼物副本累计通关多少次
	FragHuodongPassCount = 35,  -- 碎片副本累计通关多少次
	GoldHuodongPassType = 36,  -- 金币副本累计通关x难度
	ExpHuodongPassType = 37,  -- 经验副本累计通关x难度
	GiftHuodongPassType = 38,  -- 礼物副本累计通关x难度
	FragHuodongPassType = 39,  -- 碎片副本累计通关x难度
	EndlessTowerPass = 40,  -- 无尽塔通过第几关
	DispatchTaskCCount = 41,  -- C级派遣任务完成x次
	DispatchTaskBCount = 42,  -- B级派遣任务完成x次
	DispatchTaskACount = 43,  -- A级派遣任务完成x次
	DispatchTaskSCount = 44,  -- S级派遣任务完成x次
	DispatchTaskS2Count = 45,  -- S+级派遣任务完成x次

	-- PVP竞技
	ArenaBattle = 46,  -- 竞技场战斗次数
	ArenaCoin1Count = 47,  -- 拥有荣誉币数量
	ArenaRank = 48,  -- 竞技场排名
	CraftBattle = 49,  -- 石英大会参加次数
	CraftTop8Count = 50,  -- 石英大会进入8强次数  ---- 暂未实现

	-- 社交
	FriendCount = 51,  -- 好友数量
	FriendStaminaSend = 52,  -- 赠送多少次体力
	FriendStaminaRecv = 53,  -- 获赠多少次体力
	UnionContribGold = 54,  -- 公会金币捐赠累计次数
	UnionContribRmb = 55,  -- 公会钻石捐赠累计次数
	UnionGetRedPacketGold = 56,  -- 公会领取金币红包累计次数
	UnionGetRedPacketRmb = 57,  -- 公会领取钻石红包累计次数
	UnionGetRedPacketCoin3 = 58,  -- 公会领取公会币红包累计次数

	-- 隐藏成就
	DrawCardRMB10 = 59,  -- 抽卡钻石10连抽次数
	OnlineHours = 60,  -- 连续在线x小时  ---- 暂未实现
	DrawItem5 = 61,  -- 累积使用寻宝5次次数
	ShopRefresh = 62,  -- 任意商店刷新累计次数
	DrawCardGold10 = 63,  -- 累计金币十连抽次数
	TitleCount = 64,  -- 称号的个数
	FigureCount = 65,  -- 形象解锁数量
	FrameCount = 66,  -- 头像框解锁数量
	LogoCount = 67,  -- 头像解锁数量
	StaminaCount = 68,  -- 体力达到x值
	MailCount = 69,  -- 邮箱存有邮件数
	MiniQActive = 70,  -- 迷你Q点击次数
	WorldChatCount = 71,  -- 世界频道发言次数
	CitySpriteCount = 72,  -- 点击主城彩蛋次数
	DrawSCard2 = 73,  -- 钻石十连抽同时抽出2个S级精灵
	DrawSCard3 = 74,  -- 钻石十连抽同时抽出3个S级精灵
	LivePoint = 75,  -- 累计x天活跃度达到100
	DrawGemRMB = 76, --钻石抽符石次数
	DrawGemGold = 77, --金币抽符石次数

	FishCount = 78,  --累计钓到x鱼x条
	FishTypeCount = 79,  --累计钓到x类型的鱼x条
	FishingLevel = 80,  --钓鱼达到x级
	SignInDays = 81,  --连续签到x天
	CardNvalueCount = 82,  --拥有x个精灵六项个体值达到x以上
	UnionFragDonate = 83,  --许愿中心累计赠送x次碎片
	FixShopRefresh = 84,  --精选商店累计手动刷新x次
	MysteryShopRefresh = 85,  --神秘商店累计手动刷新x次
	BaiBianActive = 86,  --累计点击主城百变怪x次
	RedQualityGem = 87,  --累计获得x个红色符石
	CardGemQualitySum = 88,  --x个精灵的符石品质达到x
	GymGateAllPassTimes = 89,  --道馆副本全通关次数(不含npc馆主)
	HorseBetRightTimes = 90,  --赛马猜中第几名次数
	CardCsvIDCount = 91,  --指定cardID精灵的收集x个 ---- 图鉴数量 target只能配1
	CardMarkIDStar = 92,  --指定markID精灵的达到x星级
	HuntingPass = 93,  --远征普通线路通关次数
	HuntingSpecialPass = 94,  --远征进阶线路通关次数
	DrawChipRMB = 95, --钻石抽芯片次数
	DrawChipItem = 96, --道具抽芯片次数
}

local AchievementMap = {
	-- params :type table
	-- 角色等级
	[AchieveDefs.Level] = function(self)
		return self:read("level")
	end,
	-- 训练家等级
	[AchieveDefs.TrainerLevel] = function(self)
		return self:read("trainer_level")
	end,
	-- 冒险执照特权属性点累计等级
	[AchieveDefs.TrainerPrivilege] = function(self)
		local cache = self.achievementCache
		cache.TrainerPrivilege = cache.TrainerPrivilege or itertools.sum(self:read("trainer_attr_skills"))
		return cache.TrainerPrivilege
	end,
	-- 某个天赋类型投入了x点天赋点
	[AchieveDefs.TalentOne] = function(self, target, sp)
		local talent = self:read("talent_trees")[sp]
		return talent and talent.cost or 0
	end,
	-- 总天赋投入了多少点天赋点
	[AchieveDefs.TalentAll] = function(self)
		local cache = self.achievementCache
		cache.TalentAll = cache.TalentAll or itertools.sum(self:read("talent_trees"), function(_, t) return t.cost end)
		return cache.TalentAll
	end,
	-- 已激活探险器数量
	[AchieveDefs.ExplorerActiveCount] = function(self)
		local cache = self.explorersCache
		cache.ExplorerActiveCount = cache.ExplorerActiveCount or itertools.count(self:read("explorers"), function(_, t) return t.advance >= 1 end)
		return cache.ExplorerActiveCount
	end,
	-- 激活指定探险器
	[AchieveDefs.ExplorerActive] = function(self, target, sp)
		local t = self:read("explorers")[sp]
		if t and t.advance >= 1 then
			return 1
		end
		return 0
	end,
	-- 任意探险器的等级达到多少
	[AchieveDefs.ExplorerLevel] = function(self)
		local cache = self.explorersCache
		cache.ExplorerLevel = cache.ExplorerLevel or (itertools.max(self:read("explorers"), function(_, t) return t.advance end) or 0)
		return cache.ExplorerLevel
	end,
	-- 战力达到多少
	[AchieveDefs.FightingPoint] = function(self)
		return self:read("top6_fighting_point")
	end,
	-- 消耗多少数量钻石
	[AchieveDefs.CostRmbCount] = function(self)
		return self:read("rmb_consume")
	end,
	-- 精灵的收集数量（总数） ---- 图鉴数量
	[AchieveDefs.CardCount] = function(self)
		local cache = self.achievementCache
		cache.CardCount = cache.CardCount or itertools.size(self:read("pokedex"))
		return cache.CardCount
	end,
	-- x属性精灵的收集x个 ---- 图鉴数量
	[AchieveDefs.CardNatureCount] = function(self, target, sp)
		local cache = self.achievementCache
		if cache.CardNatureCount == nil then
			local hash = {}
			for cardID, v in pairs(self:read("pokedex")) do
				local unitID = csv.cards[cardID].unitID
				local cfg = csv.unit[unitID]
				hash[cfg.natureType] = (hash[cfg.natureType] or 0) + 1
				if cfg.natureType2 then
					hash[cfg.natureType2] = (hash[cfg.natureType2] or 0) + 1
				end
			end
			cache.CardNatureCount = hash
		end
		return cache.CardNatureCount[sp] or 0
	end,
	-- 指定cardID精灵的收集x个 ---- 图鉴数量 target只能配1
	[AchieveDefs.CardCsvIDCount] = function(self, target, sp)
		return self:read('pokedex')[sp] and 1 or 0
	end,
	-- x等级好感度有x个
	[AchieveDefs.FeelLevelCount] = function(self, target, sp)
		local cache = self.achievementCache
		if cache.FeelLevelCount == nil then
			local h = {}
			for k, v in pairs(self:read("card_feels")) do
				h[v.level] = (h[v.level] or 0) + 1
			end
			cache.FeelLevelCount = stat.summator.new(h)
		end
		return cache.FeelLevelCount:sumRange(sp)
	end,
	-- 无尽塔通过第几关
	[AchieveDefs.EndlessTowerPass] = function(self, target, sp)
		if self:read("endless_tower_max_gate") >= sp then
			return 1
		end
		return 0
	end,
	-- 好友数量
	[AchieveDefs.FriendCount] = function(self)
		local cache = self.achievementCache
		if cache.FriendCount == nil then
			cache.FriendCount = itertools.size(gGameModel.society:read('friends'))
		end
		return cache.FriendCount
	end,
	-- x等级的卡牌有x个
	[AchieveDefs.CardLevelCount] = function(self, target, sp)
		local stat = gGameModel.cards:getStat()
		return stat.level_sum:sumRange(sp)
	end,
	-- x品质的卡牌有x个
	[AchieveDefs.CardAdvanceCount] = function(self, target, sp)
		local stat = gGameModel.cards:getStat()
		return stat.advance_sum:sumRange(sp)
	end,
	-- x星数的卡牌有x个
	[AchieveDefs.CardStarCount] = function(self, target, sp)
		local stat = gGameModel.cards:getStat()
		return stat.star_sum:sumRange(sp)
	end,
	-- x品质饰品有x个
	[AchieveDefs.EquipAdvanceCount] = function(self, target, sp)
		local stat = gGameModel.cards:getStat()
		return stat.equip_advance_sum:sumRange(sp)
	end,
	-- x觉醒饰品有x个
	[AchieveDefs.EquipAwakeCount] = function(self, target, sp)
		local stat = gGameModel.cards:getStat()
		return stat.equip_awake_sum:sumRange(sp)
	end,
	-- x等级携带道具有x个
	[AchieveDefs.HeldItemLevelCount] = function(self, target, sp)
		local cache = self.achievementCache
		if cache.HeldItemLevelCount == nil then
			local h = {}
			for _, heldItem in gGameModel.held_items:pairs() do
				if heldItem:read('exist_flag') then
					local level = heldItem:read('level')
					h[level] = (h[level] or 0) + 1
				end
			end
			cache.HeldItemLevelCount = stat.summator.new(h)
		end
		return cache.HeldItemLevelCount:sumRange(sp)
	end,
	-- x品质携带道具有x个
	[AchieveDefs.HeldItemQualityCount] = function(self, target, sp)
		local cache = self.achievementCache
		if cache.HeldItemQualityCount == nil then
			local hash = {}
			for _, heldItem in gGameModel.held_items:pairs() do
				if heldItem:read('exist_flag') then
					local cfg = csv.held_item.items[heldItem:read('held_item_id')]
					hash[cfg.quality] = (hash[cfg.quality] or 0) + 1
				end
			end
			cache.HeldItemQualityCount = hash
		end
		return cache.HeldItemQualityCount[sp] or 0
	end,
	-- 某普通关卡通关
	[AchieveDefs.GatePass] = function(self, target, sp)
		local t = self:read("gate_star")[sp]
		if t and t.star >= 1 then
			return 1
		end
		return 0
	end,
	-- 某精英关卡通关
	[AchieveDefs.HeroGatePass] = function(self, target, sp)
		local t = self:read("gate_star")[sp]
		if t and t.star >= 1 then
			return 1
		end
		return 0
	end,
	-- 竞技场排名
	[AchieveDefs.ArenaRank] = function(self)
		return self:read("pw_rank")
	end,
	-- x星普通关卡x个
	[AchieveDefs.GateStarCount] = function(self, target, sp)
		local cache = self.gateStarCache
		if cache.GateStarCount == nil then
			local h = {}
			for gateID, v in pairs(self:read("gate_star")) do
				if csv.scene_conf[gateID].sceneType == 4 then
					h[v.star] = (h[v.star] or 0) + 1
				end
			end
			cache.GateStarCount = stat.summator.new(h)
		end
		return cache.GateStarCount:sumRange(sp)
	end,
	-- x星精英关卡x个
	[AchieveDefs.HeroGateStarCount] = function(self, target, sp)
		local cache = self.gateStarCache
		if cache.HeroGateStarCount == nil then
			local h = {}
			for gateID, v in pairs(self:read("gate_star")) do
				if csv.scene_conf[gateID].sceneType == 5 then
					h[v.star] = (h[v.star] or 0) + 1
				end
			end
			cache.HeroGateStarCount = stat.summator.new(h)
		end
		return cache.HeroGateStarCount:sumRange(sp)
	end,
	-- 金币副本累计通关x难度
	[AchieveDefs.GoldHuodongPassType] = function(self, target, sp)
		local index = self:read("huodongs_index")[1]
		if index ~= nil and (index+1)>=sp then
			return 1
		end
		return 0
	end,
	-- 经验副本累计通关x难度
	[AchieveDefs.ExpHuodongPassType] = function(self, target, sp)
		local index = self:read("huodongs_index")[2]
		if index ~= nil and (index+1)>=sp then
			return 1
		end
		return 0
	end,
	-- 礼物副本累计通关x难度
	[AchieveDefs.GiftHuodongPassType] = function(self, target, sp)
		local index = self:read("huodongs_index")[3]
		if index ~= nil and (index+1)>=sp then
			return 1
		end
		return 0
	end,
	-- 碎片副本累计通关x难度
	[AchieveDefs.FragHuodongPassType] = function(self, target, sp)
		local index = self:read("huodongs_index")[4]
		if index ~= nil and (index+1)>=sp then
			return 1
		end
		return 0
	end,
	-- 称号数量
	[AchieveDefs.TitleCount] = function(self)
		local cache = self.achievementCache
		if cache.TitleCount == nil then
			cache.TitleCount = itertools.size(gGameModel.role:read('titles'))
		end
		return cache.TitleCount
	end,
	-- 形象解锁数量
	[AchieveDefs.FigureCount] = function(self)
		local cache = self.achievementCache
		if cache.FigureCount == nil then
			cache.FigureCount = itertools.size(gGameModel.role:read('figures'))
		end
		return cache.FigureCount
	end,
	-- 头像框解锁数量
	[AchieveDefs.FrameCount] = function(self)
		local cache = self.achievementCache
		if cache.FrameCount == nil then
			cache.FrameCount = itertools.size(gGameModel.role:read('frames'))
		end
		return cache.FrameCount
	end,
	-- 头像解锁数量
	[AchieveDefs.LogoCount] = function(self)
		local cache = self.achievementCache
		if cache.LogoCount == nil then
			cache.LogoCount = itertools.size(self:read("active_logos"))
		end
		return cache.LogoCount
	end,
	-- 体力值达到x值
	[AchieveDefs.StaminaCount] = function(self)
		return self:read("stamina")
	end,
	-- 邮箱存有邮件数
	[AchieveDefs.MailCount] = function(self)
		local cache = self.achievementCache
		if cache.MailCount == nil then
			local value1 = itertools.size(self:read("mailbox"))
			local value2 = itertools.size(self:read("read_mailbox"))
			cache.MailCount = value1 + value2
		end
		return cache.MailCount
	end,
	-- 钓到x鱼数量
	[AchieveDefs.FishCount] = function(self, target, sp)
		local cache = self.achievementCache
		if cache.FishCount == nil then
			local f = {}
			local fish = gGameModel.fishing:read('fish')
			for fishId, record in pairs(fish) do
				f[fishId] = (f[fishId] or 0) + record['counter']
			end
			cache.FishCount = f
		end
		return cache.FishCount[sp] or 0
	end,
	-- 钓到x类型鱼数量
	[AchieveDefs.FishTypeCount] = function(self, target, sp)
		local cache = self.achievementCache
		if cache.FishTypeCount == nil then
			local f = {}
			local fish = gGameModel.fishing:read('fish')
			for fishId, record in pairs(fish) do
				local cfg = csv.fishing.fish[fishId]
				f[cfg.type] = (f[cfg.type] or 0) + record['counter']
				f['allType'] = (f['allType'] or 0) + record['counter']
			end
			cache.FishTypeCount = f
		end
		if sp then
			return cache.FishTypeCount[sp] or 0
		else
			return cache.FishTypeCount['allType'] or 0
		end
	end,
	-- 钓鱼等级达到x级
	[AchieveDefs.FishingLevel] = function(self)
		return gGameModel.fishing:read('level')
	end,
	-- 连续签到x天
	[AchieveDefs.SignInDays] = function(self)
		return self:read('sign_in_days')
	end,
	-- 拥有x个六项个体值x以上的精灵
	[AchieveDefs.CardNvalueCount] = function(self, targetType, sp)
		local cache = self.achievementCache
		local count = 0
		local checkNvalue = function (_, card)
			if card:read('exist_flag') then
				local nvalue = card:read('nvalue')
				for _, v in pairs(nvalue) do
					if v < sp then
						return false
					end
				end
				return true
			else
				return false
			end
		end
		cache.PerfectNvalueCount = cache.PerfectNvalueCount or itertools.count(gGameModel.cards, checkNvalue) or 0
		return cache.PerfectNvalueCount
	end,
	-- x个精灵宝石品质指数达到x
	[AchieveDefs.CardGemQualitySum] = function(self, target, sp)
		local cache = self.achievementCache
		if cache.CardGemQualitySum == nil then
			local ret = {}
			local qualityCsv, gemCsv = csv.gem.quality, csv.gem.gem
			for _, card in gGameModel.cards:pairs() do
				local gems = card:read('gems')
				local qualityNum = 0
				for k, dbid in pairs(gems) do
					local gem = gGameModel.gems:find(dbid)
					local level = gem:read('level')
					local gem_id = gem:read('gem_id')
					local quality = gemCsv[gem_id].quality
					quality = "qualityNum"..quality
					qualityNum = qualityCsv[level][quality] + qualityNum
				end
				if qualityNum >= sp then
					ret[sp] = (ret[sp] or 0) + 1
				end
			end
			cache.CardGemQualitySum = ret
		end
		return cache.CardGemQualitySum[sp] or 0
	end,
	-- 指定markID精灵的达到x星级 (target=星级、sp=markID)
	[AchieveDefs.CardMarkIDStar] = function(self, target, sp)
		local stat = gGameModel.cards:getStat()
		return stat.markID_star[sp] or 0
	end,
}

function Role:getAchievement(achievementID)
	local cfg = csv.achievement.achievement_task[achievementID]
	local group = cfg.targetType
	local target = cfg.targetArg
	local sp = cfg.targetArg2
	local current = 0

	local achievement_tasks = self:read("achievement_tasks") or {}
	if group == AchieveDefs.ArenaRank and achievement_tasks[achievementID] then
		return target
	end

	local func = AchievementMap[group]
	if func then
		current = func(self, target, sp)
		-- 已达成，但是出现重置（重生、分解）可能，展示上用达标值
		if achievement_tasks[achievementID] and current < target then
			current = target
		end
	elseif cfg.yyID then
		local yyhuodong = self:read("yyhuodongs")[cfg.yyID] or {}
		if group == AchieveDefs.HorseBetRightTimes then
			local horse_race = yyhuodong.horse_race or {}
			local achievement_counter = horse_race.achievement_counter or {}
			current = achievement_counter[sp] or 0
		end
	else
		local achievement_counter = self:read("achievement_counter") or {}
		current = achievement_counter[group] or 0
	end

	return current
end

return Role