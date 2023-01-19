-- @Date:   2020-01-08
-- @Desc:
-- @Last Modified time: 2020-01-08

local tagModelHelpers = {
	-- role
	roleId = bindHelper.model("role", "id"),
	tasks = bindHelper.model("role", "achievement_tasks"),
	box = bindHelper.model("role", "achievement_box_awards"),
	yyHuodongs = bindHelper.model("role", "yyhuodongs"),
	commonBraveChallenge = bindHelper.model("role", "normal_brave_challenge"),
	yyOpen = bindHelper.model("role", "yy_open"),
	yyEndTime = bindHelper.model("role", "yy_endtime"),
	rolePassport = bindHelper.model("role", "passport"),
	pokedexAdvance = bindHelper.model("role", "pokedex_advance"),
	items = bindHelper.model("role", "items"),
	rmb = bindHelper.model("role", "rmb"),
	gold = bindHelper.model("role", "gold"),
	level = bindHelper.model("role", "level"),
	cards = bindHelper.model("role", "cards"),
	skillPoint = bindHelper.model("role", "skill_point"),
	cardFeels = bindHelper.model("role", "card_feels"),
	frags = bindHelper.model("role", "frags"),
	gateStar = bindHelper.model("role", "gate_star"),
	mapStar = bindHelper.model("role", "map_star"),
	talentTree = bindHelper.model("role", "talent_trees"),
	talentPoint = bindHelper.model("role", "talent_point"),
	dispatchTasks = bindHelper.model("role", "dispatch_tasks"),
	roleSignInGift = bindHelper.model("role", "sign_in_gift"),
	vipLevel = bindHelper.model("role", "vip_level"),
	mailBox = bindHelper.model("role", "mailbox"),
	explorers = bindHelper.model("role", "explorers"),
	unionId = bindHelper.model("role", "union_db_id"),
	memberRedPacket = bindHelper.model("role", "union_role_packet_can_rob"),
	systemRedPacket = bindHelper.model("role", "union_sys_packet_can_rob"),
	unionRedpackets = bindHelper.model("role", "union_redpackets"),
	allUnionTask = bindHelper.model("role", "union_contrib_tasks"),
	unionFbAward = bindHelper.model("role", "union_fb_award"),
	unionFbPassed = bindHelper.model("role", "union_fuben_passed"),
	heldItems = bindHelper.model("role", "held_items"),
	unionFragDonateAwards = bindHelper.model("role", "union_frag_donate_awards"),
	unionFightRoleRound = bindHelper.model("role", "union_fight_round"),
	battleCards = bindHelper.model("role", "battle_cards"),
	crossArenaDatas = bindHelper.model("role", "cross_arena_datas"),
	rankAward = bindHelper.model("role", "pw_rank_award"),
	onlineFightInfo = bindHelper.model("role", "cross_online_fight_info"),
	cloneRoomCreateTime = bindHelper.model("role", "clone_room_create_time"),
	cloneRoomDbid = bindHelper.model("role", "clone_room_db_id"),
	cloneBattleKickNum = bindHelper.model("role", "clone_daily_be_kicked_num"),
	crossCraftSignupDate = bindHelper.model("role", "cross_craft_sign_up_date"),
	crossCraftRound = bindHelper.model("role", "cross_craft_round"),
	craftRound = bindHelper.model("role", "craft_round"),
	huodongs = bindHelper.model("role", "huodongs"),
	dailyAssistant = bindHelper.model("role", "daily_assistant"),
	endlessTowerCurrent = bindHelper.model("role", "endless_tower_current"),
	endlessTowerMaxGate = bindHelper.model("role", "endless_tower_max_gate"),
	gridWalk = bindHelper.model("role", "grid_walk"),
	zfrags = bindHelper.model("role", "zfrags"),

	-- union
	unionLevel = bindHelper.model("union", "level"),
	chairmanId = bindHelper.model("union", "chairman_db_id"),
	joinNotes = bindHelper.model("union", "join_notes"),
	viceChairmans = bindHelper.model("union", "vice_chairmans"),
	unionTask = bindHelper.model("union", "contrib_tasks"),
	unionFbmembers = bindHelper.model("union", "members"),
	count = bindHelper.model("union", "training_count"),
	crossUnionFightStatus = bindHelper.model("role", "cross_union_fight_status"),
	crossUnionFightJoins = bindHelper.model("role", "in_cross_union_fight_join"),

	-- union_training
	slots = bindHelper.model("union_training", "slots"),
	opened = bindHelper.model("union_training", "opened"),

	-- tasks
	daily = bindHelper.model("tasks", "daily"),
	main = bindHelper.model("tasks", "main"),

	-- daily_record
	stageAward = bindHelper.model("daily_record", "liveness_stage_award"),
	staminaGain = bindHelper.model("daily_record", "friend_stamina_gain"),
	itemDC1FreeCounter = bindHelper.model("daily_record", "item_dc1_free_counter"),
	trainerGiftTimes = bindHelper.model("daily_record", "trainer_gift_times"),
	redPacketRobCount = bindHelper.model("daily_record", "redPacket_rob_count"),
	unionDailyGiftTimes = bindHelper.model("daily_record", "union_daily_gift_times"),
	unionTimes = bindHelper.model("daily_record", "union_contrib_times"),
	unionFbTime = bindHelper.model("daily_record", "union_fb_times"),
	rmbFreeCount = bindHelper.model("daily_record", "dc1_free_count"),
	goldFreeCount = bindHelper.model("daily_record", "gold1_free_count"),
	trainerCount = bindHelper.model("daily_record", "draw_card_gold1_trainer"),
	lastDrawTime = bindHelper.model("daily_record", "gold1_free_last_time"),
	equipFreeCount = bindHelper.model("daily_record", "eq_dc1_free_counter"),
	limitBoxFreeCounter = bindHelper.model("daily_record", "limit_box_free_counter"),
	sendredPacket = bindHelper.model("daily_record", "huodong_redPacket_send"),
	getredPacket = bindHelper.model("daily_record", "huodong_redPacket_rob"),
	sendredCrossPacket = bindHelper.model("daily_record", "huodong_cross_redPacket_send"),
	getredCrossPacket = bindHelper.model("daily_record", "huodong_cross_redPacket_rob"),
	luckyEggFreeCount = bindHelper.model("daily_record", "lucky_egg_free_counter"),
	unionFragDonateStartTimes =  bindHelper.model("daily_record", "union_frag_donate_start_times"),
	unionFightSignUpState =  bindHelper.model("daily_record", "union_fight_sign_up"),
	unionTrainingSpeedup =  bindHelper.model("daily_record", "union_training_speedup"),
	gemGoldFree = bindHelper.model("daily_record", "gem_gold_dc1_free_count"),
	gemRmbFree = bindHelper.model("daily_record", "gem_rmb_dc1_free_count"),
	bossGatePlay = bindHelper.model("daily_record", "boss_gate"),
	bossGateBuy = bindHelper.model("daily_record", "boss_gate_buy"),
	crossArenaPointAwardData = bindHelper.model("daily_record", "cross_arena_point_award"),
	gemUpRmbFree = bindHelper.model("daily_record", "limit_up_gem_free_count"),
	resultPointAward = bindHelper.model("daily_record", "result_point_award"),
	qaTimes = bindHelper.model("daily_record", "union_qa_times"),
	qaBuyTimes = bindHelper.model("daily_record", "union_qa_buy_times"),
	lianjinTimes = bindHelper.model("daily_record", "lianjin_times"),
	lianjinFreeTimes = bindHelper.model("daily_record", "lianjin_free_times"),
	endlessTowerResetTimes = bindHelper.model("daily_record", "endless_tower_reset_times"),
	craftSignup = bindHelper.model("daily_record", "craft_sign_up"),
	fishingCounter = bindHelper.model("daily_record", "fishing_counter"),

	-- currday_dispatch
	vipGiftClick = bindHelper.model("currday_dispatch", "vipGift"),
	firstRechargeClick = bindHelper.model("currday_dispatch", "firstRecharge"),
	luckyCatClick = bindHelper.model("currday_dispatch", "luckyCat"),
	goldLuckyCatClick = bindHelper.model("currday_dispatch", "goldLuckyCat"),
	currdayPassport = bindHelper.model("currday_dispatch", "passport"),
	directBuy = bindHelper.model("currday_dispatch", "activityDirectBuyGift"),
	serverOpenItemBuy = bindHelper.model("currday_dispatch", "serverOpenItemBuy"),
	randomTowerClick = bindHelper.model("currday_dispatch", "randomTower"),
	sendedRedPacket = bindHelper.model("currday_dispatch", "sendedRedPacket"),
	firstRechargeDailyClick = bindHelper.model("currday_dispatch", "firstRechargeDaily"),
	isHandBookNew = bindHelper.model("handbook", "isNew"),

	notifyShow = bindHelper.model("forever_dispatch", "activityItemExchange"),
	dispatchTasksNextAutoTime = bindHelper.model("forever_dispatch", "dispatchTasksNextAutoTime"),
	dispatchTasksRedHintRefrseh = bindHelper.model("forever_dispatch", "dispatchTasksRedHintRefrseh"),
	battleManualsClick = bindHelper.model("forever_dispatch", "battleManualDatas"),
	cloneBattleLookRobot = bindHelper.model("forever_dispatch", "cloneBattleLookRobot"),
	cloneBattleLookHistory = bindHelper.model("forever_dispatch", "cloneBattleLookHistory"),
	exclusiveLimitClick = bindHelper.model("forever_dispatch","exclusiveLimitDatas"),
	braveChallengeEachClick = bindHelper.model("forever_dispatch","braveChallengeEachClick"),
	customizeGiftClick = bindHelper.model("forever_dispatch","customizeGiftClick"),
	crossUnionFightTime = bindHelper.model("forever_dispatch","crossUnionFightTime"),

	randomTowerPointAward = bindHelper.model("random_tower", "point_award"),

	signInGift = bindHelper.model("monthly_record", "sign_in_gift"),
	signInMonthly = bindHelper.model("monthly_record", "sign_in"),
	signInAwards = bindHelper.model("monthly_record", "sign_in_awards"),
	currDay = bindHelper.model("monthly_record", "last_sign_in_day"),
	vipGiftData = bindHelper.model("monthly_record", "vip_gift"),

	friends = bindHelper.model("society", "friends"),
	staminaRecv = bindHelper.model("society", "stamina_recv"),
	friendAddReqs = bindHelper.model("society", "friend_reqs"),

	limitSprites = bindHelper.model("capture", "limit_sprites"),
	--gym
	gymDatas = bindHelper.model("role", "gym_datas"),
	--clone
	cloneRoomHistory = bindHelper.model("clone_room", "history"),
	reunion = bindHelper.model("role", "reunion"),
	reunionBindPlayer = bindHelper.model("forever_dispatch", "reunionBindPlayer"),

	qaround = bindHelper.model("global_record", "unionqa_round"),
	gCommonBraveChallenge = bindHelper.model("global_record", "normal_brave_challenge"),

	chipItemFree = bindHelper.model("daily_record", "chip_item_dc1_free_count"),
	chipRmbFree = bindHelper.model("daily_record", "chip_rmb_dc1_free_count"),
}

local tagModelIdlers = {}

local redHintHelperTags = {}
redHintHelperTags = setmetatable(redHintHelperTags, {
	__index = function(t, k)
		-- TODO: reduce model idlercomputer, one idlercomputer could be had many listeners
		-- local v = tagModelIdlers[k]
		-- if v then
		-- 	return v
		-- end
		local f = tagModelHelpers[k]
		if f then
			local v = f(nil)
			-- -- if model no existed in right now, u always got a idlercomputer instance
			-- if v:read() ~= nil then
			-- 	tagModelIdlers[k] = v
			-- end
			return v
		end
		return rawget(t, k)
	end,
})

redHintHelperTags.unionFightSignUp = {
	unionId = true,
	level = true,
	unionLevel = true,
	unionFightSignUpState = true,
	unionFightRoleRound = true,
	unlockKey = gUnlockCsv.unionFight,
}

redHintHelperTags.livenessWheel = {
	yyHuodongs = true,
}

redHintHelperTags.luckyEggDrawCardFree = {
	luckyEggFreeCount = true,
}

redHintHelperTags.luckyEggScoreShop = {
	items = true,
	yyHuodongs = true,
	yyOpen = true,
}

redHintHelperTags.festivalRedHint = {
	yyHuodongs = true,
	sendredPacket = true,
	getredPacket = true,
	vipLevel = true,
}

redHintHelperTags.crossFestivalRedHint = {
	yyHuodongs = true,
	sendredCrossPacket = true,
	getredCrossPacket = true,
	vipLevel = true,
}

redHintHelperTags.onceRechargeAward = {
	yyHuodongs = true,
}

redHintHelperTags.rechargeWheelFree = {
	yyHuodongs = true,
}

redHintHelperTags.rechargeWheel = {
	yyHuodongs = true,
}

redHintHelperTags.activityWeeklyCard = {
	yyHuodongs = true,
}

redHintHelperTags.activityWorldBoss = {
	bossGatePlay = true,
	bossGateBuy = true,
}

redHintHelperTags.gemUp = {
	gemUpRmbFree = true,
}

redHintHelperTags.activityRetrieve = {
	yyHuodongs = true,
}

redHintHelperTags.activityBuyGift = {
	yyOpen = true,
	directBuy = true,
	yyHuodongs = true,
}

redHintHelperTags.activityDirectBuyGift = {
	yyOpen = true,
	directBuy = true,
	yyHuodongs = true,
}

redHintHelperTags.activityDirectBuyGiftExternal = {
	yyHuodongs = true,
}

redHintHelperTags.activityItemExchange = {
	notifyShow = true,
	yyHuodongs = true,
}

redHintHelperTags.activityMonthlyCard = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.activityRegainStamina = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.activityGeneralTask = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.activityRechargeGift = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.activityLevelFund = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.totalActivityShow = {
	yyHuodongs = true,
	yyOpen = true,
	notifyShow = true,
	directBuy = true,
}

redHintHelperTags.cityTaskDaily = {
	daily = true,
	stageAward = true,
	unlockKey = gUnlockCsv.dailyTask,
}

redHintHelperTags.cityTaskMain = {
	main = true,
}

redHintHelperTags.passportCurrDay = {
	yyOpen = true,
	currdayPassport = true,
	rolePassport = true,
}

redHintHelperTags.passportReward = {
	yyOpen = true,
	rolePassport = true,
}

redHintHelperTags.passportTask = {
	yyOpen = true,
	rolePassport = true,
}

redHintHelperTags.luckyCat = {
	luckyCatClick = true,
}
redHintHelperTags.goldLuckyCat = {
	goldLuckyCatClick = true,
}

redHintHelperTags.serverOpen = {
	yyOpen = true,
	rmb = true,
	serverOpenItemBuy = true,
	yyHuodongs = true,
}

redHintHelperTags.serverOpenDay = {
	rmb = true,
	serverOpenItemBuy = true,
	yyHuodongs = true,
}

redHintHelperTags.vipGift = {
	vipGiftClick = true,
}

redHintHelperTags.firstRecharge = {
	yyHuodongs = true,
	firstRechargeClick = true,
	yyOpen = true,
}

redHintHelperTags.firstRechargeDaily = {
	yyHuodongs = true,
	yyOpen = true,
	firstRechargeDailyClick = true,
}

redHintHelperTags.exclusiveLimit = {
	exclusiveLimitClick = true,
}

redHintHelperTags.customizeGift = {
	customizeGiftClick  = true,
}

redHintHelperTags.battleManuals = {
	battleManualsClick = true,
}

redHintHelperTags.achievementTask = {
	tasks = true,
	box = true,
	unlockKey = gUnlockCsv.achievement,
}

redHintHelperTags.achievementBox = {
	box = true,
	unlockKey = gUnlockCsv.achievement,
}

redHintHelperTags.handbookAdvance = {
	pokedexAdvance = true,
	isHandBookNew = true,
	unlockKey = gUnlockCsv.handbook,
}

redHintHelperTags.nvalue = {
	items = true,
	gold = true,
	unlockKey = gUnlockCsv.cardNValueRecast,
}

redHintHelperTags.advance = {
	items = true,
}

redHintHelperTags.effortValue = {
	items = true,
	unlockKey = gUnlockCsv.cardEffort,
}

redHintHelperTags.equip = {
	gold = true,
	level = true,
	unlockKey = gUnlockCsv.equip,
}

redHintHelperTags.equipStar = {
	gold = true,
	unlockKey = gUnlockCsv.equipStarAdd,
}

redHintHelperTags.equipStrengthen = {
	gold = true,
	level = true,
	unlockKey = gUnlockCsv.equip,
}

redHintHelperTags.equipAwake = {
	gold = true,
	unlockKey = gUnlockCsv.equipAwak,
}

redHintHelperTags.equipSignet = {
	gold = true,
	unlockKey = gUnlockCsv.equipSignet,
}

redHintHelperTags.star ={
	cards = true,
}

redHintHelperTags.skill = {
	skillPoint = true,
	gold = true,
}

redHintHelperTags.cardFeel = {
	items = true,
	cardFeels = true,
	unlockKey = gUnlockCsv.cardLike,
}

redHintHelperTags.cardDevelop = {
	gold = true,
}

redHintHelperTags.bottomFragment = {
	frags = true,
}

redHintHelperTags.totalCard = {
	cards = true,
	items = true,
	gold = true,
	skillPoint = true,
	cardFeels = true,
	level = true,
}

redHintHelperTags.levelRightDownGift = {
	mapStar = true,
}

redHintHelperTags.levelRightBtnGift = {
	mapStar = true,
	gateStar = true,
}

redHintHelperTags.levelLeftBtnGift = {
	mapStar = true,
	gateStar = true,
}

redHintHelperTags.levelBtnJuQingGift = {
	gateStar = true,
	mapStar = true,
}

redHintHelperTags.levelBtnKunNanGift = {
	gateStar = true,
	mapStar = true,
}

redHintHelperTags.levelBtnNightMareGift = {
	gateStar = true,
	mapStar = true,
}

redHintHelperTags.cityTalent = {
	talentTree = true,
	talentPoint = true,
	unlockKey = gUnlockCsv.talent,
}

redHintHelperTags.pve = {
	gateStar = true,
	mapStar = true,
}

redHintHelperTags.dispatchTask = {
	unlockKey = gUnlockCsv.dispatchTask,
	dispatchTasks = true,
	dispatchTasksNextAutoTime = true,
	dispatchTasksRedHintRefrseh = true,
}

redHintHelperTags.randomTower = {
	unlockKey = gUnlockCsv.randomTower,
	randomTowerClick = true,
	randomTowerPointAward = true,
}

redHintHelperTags.randomTowerPoint = {
	unlockKey = gUnlockCsv.randomTower,
	randomTowerPointAward = true,
}

redHintHelperTags.signIn = {
	roleSignInGift = true,
	signInGift = true,
	vipLevel = true,
	currDay = true,
	signInMonthly = true,
	signInAwards = true,
}

redHintHelperTags.loginWealRedHint = {
	yyHuodongs = true,
}

redHintHelperTags.friendStaminaRecv = {
	friends = true,
	staminaRecv = true,
	staminaGain = true,
}

redHintHelperTags.friendReqs = {
	friendAddReqs = true,
}

redHintHelperTags.mail = {
	mailBox = true,
}

redHintHelperTags.explorerShow = {
	explorers = true,
	items = true,
	unlockKey = gUnlockCsv.explorer,
}

redHintHelperTags.explorerTotal = {
	explorers = true,
	items = true,
	itemDC1FreeCounter = true,
	unlockKey = gUnlockCsv.explorer,
}

redHintHelperTags.explorerFind = {
	itemDC1FreeCounter = true,
	unlockKey = gUnlockCsv.explorer,
}

redHintHelperTags.cityTrainer = {
	trainerGiftTimes = true,
	unlockKey = gUnlockCsv.trainer,
}

redHintHelperTags.serverOpenCurrDay = {
	yyHuodongs = true,
	rmb = true,
	serverOpenItemBuy = true,
}

redHintHelperTags.unionSystemRedPacket = {
	unionId = true,
	unionLevel = true,
	systemRedPacket = true,
}

redHintHelperTags.unionMemberRedPacket = {
	unionId = true,
	unionLevel = true,
	memberRedPacket = true,
	redPacketRobCount = true,
}

redHintHelperTags.unionSendedRedPacket = {
	unionId = true,
	unionLevel = true,
	sendedRedPacket = true,
	unionRedpackets = true,
}

redHintHelperTags.unionDailyGift = {
	unionId = true,
	unionLevel = true,
	unionDailyGiftTimes = true,
}

redHintHelperTags.unionLobby = {
	unionId = true,
	roleId = true,
	chairmanId = true,
	joinNotes = true,
	viceChairmans = true,
}

redHintHelperTags.unionContribute = {
	unionId = true,
	unionLevel = true,
	unionTimes = true,
	allUnionTask = true,
	unionTask = true,
}

redHintHelperTags.unionFragDonate = {
	unionId = true,
	unionLevel = true,
	unionFragDonateAwards = true,
	unionFragDonateStartTimes = true,
}

redHintHelperTags.unionFuben = {
	unionId = true,
	unionLevel = true,
	unionFbAward = true,
	unionFbPassed = true,
	unionFbTime = true,
}

redHintHelperTags.unionTraining = {
	unionId = true,
	unionLevel = true,
	level = true,
	slots = true,
	opened = true,
}

redHintHelperTags.loginGiftRedHint = {
	yyHuodongs = true,
}

redHintHelperTags.heldItemLevelUp = {
	heldItems = true,
	unlockKey = gUnlockCsv.heldItem,
}

redHintHelperTags.heldItemAdvanceUp = {
	heldItems = true,
	unlockKey = gUnlockCsv.heldItem,
}

redHintHelperTags.heldItem = {
	heldItems = true,
	unlockKey = gUnlockCsv.heldItem,
}

redHintHelperTags.limitCapture = {
	unlockKey = gUnlockCsv.capture,
	limitSprites = true,
}

redHintHelperTags.drawcardDiamondFree = {
	rmbFreeCount = true,
}

redHintHelperTags.drawcardGoldFree = {
	goldFreeCount = true,
	trainerCount = true,
	lastDrawTime = true,
}

redHintHelperTags.drawcardEquipFree = {
	unlockKey = gUnlockCsv.drawEquip,
	equipFreeCount = true,
}

redHintHelperTags.drawcardOnece = {
	rmbFreeCount = true,
	goldFreeCount = true,
	trainerCount = true,
	lastDrawTime = true,
	equipFreeCount = true,
}

redHintHelperTags.limitSpritesHasFreeDrawCard = {
	yyEndTime = true,
	limitBoxFreeCounter = true,
}

redHintHelperTags.limitSpritesHasBoxAward = {
	yyOpen = true,
	yyHuodongs = true,
	stamps = true,
}

redHintHelperTags.unionTrainPosition = {
	level = true,
	opened = true,
	slots = true,
}

redHintHelperTags.unionTrainSpeedUp = {
	unionTrainingSpeedup = true,
	count = true,
}

redHintHelperTags.gemFreeExtract = {
	gemGoldFree = true,
	gemRmbFree = true,
	unlockKey = gUnlockCsv.gem,
}

redHintHelperTags.crossArenaPointAward = {
	crossArenaPointAwardData = true,
}

redHintHelperTags.crossArenaRankAward = {
	crossArenaDatas = true,
}

redHintHelperTags.zongZiActivity = {
	items = true,
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.flipCardActivity ={
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.activityBoss ={
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.zongZiAward = {
	yyHuodongs = true,
	yyOpen = true,
}

redHintHelperTags.zongziUnused = {
	items = true,
}

redHintHelperTags.cardMega = {
	items = true,
	cards = true,
	gold = true,
	level = true,
}

redHintHelperTags.arenaAward = {
	resultPointAward = true,
	rankAward = true,
}

redHintHelperTags.crossArenaAward = {
	crossArenaPointAwardData = true,
	crossArenaDatas = true,
}

redHintHelperTags.onlineFightAward = {
	onlineFightInfo = true,
}

redHintHelperTags.gymChallenge = {
	unlockKey = gUnlockCsv.gym,
	gymDatas = true,
}

redHintHelperTags.onHonourableVip = {
	vipGiftData = true,
}

redHintHelperTags.cloneBattle = {
	cloneRoomCreateTime = true,
	cloneRoomDbid = true,
	cloneBattleKickNum = true,
	unlockKey = gUnlockCsv.unionFight,
	cloneBattleLookRobot = true,
}

redHintHelperTags.cloneBattleHistory = {
	cloneRoomHistory = true,
	cloneBattleLookHistory = true,
}

redHintHelperTags.reunionActivity = {
	reunion = true,
	reunionBindPlayer = true,
}

redHintHelperTags.reunionGift = {
	reunion = true,
}

redHintHelperTags.reunionSign = {
	reunion = true,
}

redHintHelperTags.reunionTask = {
	reunion = true,
	reunionBindPlayer = true,
}

redHintHelperTags.reunionBindGift = {
	reunion = true,
	reunionBindPlayer = true,
}

redHintHelperTags.doubleTicket = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.double11 = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.snowBall = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.snowballDailyCheck = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.snowballAwarding = {
	yyOpen = true,
	yyHuodongs = true,
}


redHintHelperTags.braveChallengeAch = {
	yyOpen = true,
	yyHuodongs = true,
	commonBraveChallenge = true,
	gCommonBraveChallenge = true,
	braveChallengeEachClick = true,
}

redHintHelperTags.unionAnswer = {
	qaTimes = true,
	qaBuyTimes = true,
	unionLevel = true,
	qaround = true,
}

redHintHelperTags.flipNewYear = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.skyScraper = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.skyScraperTask = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.skyScraperSetTask = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.skyScraperScoreTask = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.skyScraperPerfectStructures = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.rmbgoldReward = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.dailyAssistant = {
	unionId = true,
	unionLevel = true,
	unionDailyGiftTimes = true,
	systemRedPacket = true,
	trainerGiftTimes = true,
	unlockKey = gUnlockCsv.trainer,
	lianjinTimes = true,
	lianjinFreeTimes = true,
	rmbFreeCount = true,
	goldFreeCount = true,
	trainerCount = true,
	lastDrawTime = true,
	equipFreeCount = true,
	itemDC1FreeCounter = true,
	gemGoldFree = true,
	gemRmbFree = true,
	level = true,
	unionFightSignUpState = true,
	unionFightRoleRound = true,
	craftSignup = true,
	crossCraftSignupDate = true,
	crossCraftRound = true,
	craftRound = true,
	huodongs = true,
	dailyAssistant = true,
	endlessTowerCurrent = true,
	endlessTowerMaxGate = true,
	endlessTowerResetTimes = true,
	vipLevel = true,
	fishingCounter = true,
	unionTimes = true,
	unionFragDonateStartTimes = true,
	unionFbTime = true,
	unionTrainingSpeedup = true,
	unionFbAward = true,
	unionFbPassed = true,
}

redHintHelperTags.dailyAssistantReward = {
	unionId = true,
	unionLevel = true,
	unionDailyGiftTimes = true,
	systemRedPacket = true,
	trainerGiftTimes = true,
	unlockKey = gUnlockCsv.trainer,
	lianjinTimes = true,
	lianjinFreeTimes = true,
}

redHintHelperTags.dailyAssistantDrawCard = {
	rmbFreeCount = true,
	goldFreeCount = true,
	trainerCount = true,
	lastDrawTime = true,
	equipFreeCount = true,
	itemDC1FreeCounter = true,
	gemGoldFree = true,
	gemRmbFree = true,
}

redHintHelperTags.dailyAssistantSignup = {
	unionId = true,
	level = true,
	unionLevel = true,
	unionFightSignUpState = true,
	unionFightRoleRound = true,
	craftSignup = true,
	crossCraftSignupDate = true,
	crossCraftRound = true,
	craftRound = true,
}

redHintHelperTags.dailyAssistantAdventure = {
	huodongs = true,
	level = true,
	dailyAssistant = true,
	endlessTowerCurrent = true,
	endlessTowerMaxGate = true,
	endlessTowerResetTimes = true,
	vipLevel = true,
	fishingCounter = true,
	dailyAssistant = true,
}

redHintHelperTags.dailyAssistantUnion = {
	unionId = true,
	unionLevel = true,
	unionTimes = true,
	unionFragDonateStartTimes = true,
	unionFbTime = true,
	unionTrainingSpeedup = true,
	unionFbAward = true,
	unionFbPassed = true,
}

redHintHelperTags.playPassport = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.gridWalkMain = {
	gridWalk = true,
	yyHuodongs = true,
}

redHintHelperTags.gridWalkTask = {
	gridWalk = true,
	yyHuodongs = true,
}

redHintHelperTags.gridWalkAchievements = {
	gridWalk = true,
	yyHuodongs = true,
}

redHintHelperTags.horseRaceMain = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.horseRaceAward = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.horseRaceBetAward = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.horseRaceCanBet = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.dispatchTaskType = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.activityDispatch = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.shavedIce = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.canZawakeByStage = {
	zfrags = true,
	zawake = true,
	unlockKey = gUnlockCsv.zawake,
}

redHintHelperTags.canZawake = {
	zfrags = true,
	zawake = true,
	unlockKey = gUnlockCsv.zawake,
}

redHintHelperTags.cityChipFreeExtract = {
	chipItemFree = true,
	chipRmbFree = true,
	unlockKey = gUnlockCsv.chip,
}

redHintHelperTags.summerChallenge = {
	yyHuodongs = true,
}

redHintHelperTags.volleyball = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.volleyballDailyCheck = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.volleyballAwarding = {
	yyOpen = true,
	yyHuodongs = true,
}


redHintHelperTags.midAutumnDraw = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.midAutumnTaskAward = {
	yyOpen = true,
	yyHuodongs = true,
}

redHintHelperTags.crossUnionFight = {
	crossUnionFightStatus = true,
	unionId = true,
	level = true,
	unionLevel = true,
	crossUnionFightTime = true,
	crossUnionFightStatus = true,
	crossUnionFightJoins = true,
}

return redHintHelperTags