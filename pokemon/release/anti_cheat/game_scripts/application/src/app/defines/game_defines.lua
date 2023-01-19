--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- game相关全局变量
--


local game = {}
globals.game = game

game.GAME_SYNC_TIME = 25*60 -- 25分钟,服务器那边时间是30分钟，客户端要小点
game.VIP_LIMIT = 15 -- vip上限
game.STAMINA_LIMIT = 3000  -- 体力上限
game.STAMINA_COLD_TIME = 5*60 -- 体力CD 5分钟恢复一点
game.FRIEND_LIMIT = 60 -- 好友上限
game.FRIEND_STAMINA_GET_TIMES = 20 -- 好友中领取体力次数
game.MAIL_LIMIT = 60 --邮件里显示的邮件的上限 60 + 10
game.NVALUE_ATTR_LIMIT = 31  -- 洗练属性值上限
game.RACE_ATTR_LIMIT = 255  -- 种族属性值上限

game.FRAME_TICK = 1000/60
game.SERVER_OPENTIME = 0 -- 开服时间 timestamp

game.FISHING_GAME = 999 -- 钓鱼大赛场景
-- WEATHER  = true 开启天气， false 关闭天气
game.WEATHER  = true

game.SKIN_ADD_NUM = 100000

-- 类型属性
game.NATURE_ENUM_TABLE = {
	normal = 1,		-- 普
	fire = 2,		-- 火
	water = 3,		-- 水
	grass = 4,		-- 草
	electricity = 5,-- 电
	ice = 6,		-- 冰
	combat = 7,		-- 斗
	poison = 8,		-- 毒
	ground = 9,		-- 地
	fly = 10,		-- 飞
	super = 11,		-- 超
	worm = 12,		-- 虫
	rock = 13,		-- 岩
	ghost = 14,		-- 幽
	dragon = 15,	-- 龙
	evil = 16,		-- 恶
	steel = 17,		-- 钢
	fairy = 18,		-- 妖
}
game.NATURE_TABLE = {}
for k, v in pairs(game.NATURE_ENUM_TABLE) do
	game.NATURE_TABLE[v] = k
end

--自身类型属性
game.ONESELF_NATURE_ENUM_TABLE = {
	attrHp = 1,             	-- 生命
	attrDamage = 7,        		-- 物攻
	attrSpecialDamage = 8, 		-- 特攻
	attrDefence = 9,  			-- 物防
	attrSpecialDefence = 10, 	-- 特防
	attrSpeed = 13,         	-- 速度
}

-- 卡牌属性
game.ATTRDEF_ENUM_TABLE = {
	hp = 1, --生命
	mp1 = 2,
	initMp1 = 3, -- 初始MP1
	hpRecover = 4, -- HP恢复
	mp1Recover = 5, -- MP1回复
	mp2Recover = 6, -- MP2回复
	damage = 7, -- 物攻
	specialDamage = 8, -- 特攻
	defence = 9, -- 物防
	specialDefence = 10, -- 特防
	defenceIgnore = 11, -- 物理防御忽视
	specialDefenceIgnore = 12, -- 特殊防御忽视
	speed = 13, -- 速度
	strike = 14, -- 暴击
	strikeDamage = 15 , -- 暴击伤害
	strikeResistance = 16, -- 暴击抗性
	block = 17, -- 格挡等级
	breakBlock = 18, -- 破格挡等级
	blockPower = 19, -- 格挡强度
	dodge = 20, -- 闪避
	hit = 21, -- 命中
	damageAdd = 22, -- 最终伤害加成
	damageSub = 23, -- 最终伤害减免
	ultimateAdd = 24, -- 必杀加成
	ultimateSub = 25, -- 必杀抗性
	suckBlood = 26, -- 吸血
	rebound = 27, -- 反弹
	cure = 28, -- 治疗效果
	natureRestraint = 29, -- 属性克制
	damageDeepen = 30, -- 伤害加深     不同于伤害加成
	damageReduce = 31, -- 伤害降低      不同于伤害减免
	physicalDamageAdd = 32, -- 物理攻击伤害加成
	physicalDamageSub = 33, -- 物理攻击伤害减免
	specialDamageAdd = 34, -- 特殊攻击伤害加成
	specialDamageSub = 35, -- 特殊攻击伤害减免
	--自然属性伤害加成
	normalDamageAdd = 36,
	fireDamageAdd = 37,
	waterDamageAdd = 38,
	grassDamageAdd = 39,
	electricityDamageAdd = 40,
	iceDamageAdd = 41,
	combatDamageAdd = 42,
	poisonDamageAdd = 43,
	groundDamageAdd = 44,
	flyDamageAdd = 45,
	superDamageAdd = 46,
	wormDamageAdd = 47,
	rockDamageAdd = 48,
	ghostDamageAdd = 49,
	dragonDamageAdd = 50,
	evilDamageAdd = 51,
	steelDamageAdd = 52,
	fairyDamageAdd = 53,
	--自然属性伤害减免
	normalDamageSub = 54,
	fireDamageSub = 55,
	waterDamageSub = 56,
	grassDamageSub = 57,
	electricityDamageSub = 58,
	iceDamageSub = 59,
	combatDamageSub = 60,
	poisonDamageSub = 61,
	groundDamageSub = 62,
	flyDamageSub = 63,
	superDamageSub = 64,
	wormDamageSub = 65,
	rockDamageSub = 66,
	ghostDamageSub = 67,
	dragonDamageSub = 68,
	evilDamageSub = 69,
	steelDamageSub = 70,
	fairyDamageSub = 71,
	--自然属性治疗效果加成
	normalCure = 72,
	fireCure = 73,
	waterCure = 74,
	grassCure = 75,
	electricityCure = 76,
	iceCure = 77,
	combatCure = 78,
	poisonCure = 79,
	groundCure = 80,
	flyCure = 81,
	superCure = 82,
	wormCure = 83,
	rockCure = 84,
	ghostCure = 85,
	dragonCure = 86,
	evilCure = 87,
	steelCure = 88,
	fairyCure = 89,

	controlPer = 90,		-- 控制率
	immuneControl = 91,		-- 免控率

	pvpDamageAdd = 92,		-- PVP伤害加成
	pvpDamageSub = 93,		-- PVP伤害减免

	damageHit = 94, -- 伤害命中
	damageDodge = 95, -- 伤害闪避
}

game.ATTRDEF_TABLE = {}
for k, v in pairs(game.ATTRDEF_ENUM_TABLE) do
	game.ATTRDEF_TABLE[v] = k
end
-- 属性显示上以下为数值, 其余为百分比
game.ATTRDEF_SHOW_NUMBER = {
	[game.ATTRDEF_ENUM_TABLE.hp] = true,
	[game.ATTRDEF_ENUM_TABLE.mp1] = true,
	[game.ATTRDEF_ENUM_TABLE.initMp1] = true,
	[game.ATTRDEF_ENUM_TABLE.hpRecover] = true,
	[game.ATTRDEF_ENUM_TABLE.damage] = true,
	[game.ATTRDEF_ENUM_TABLE.specialDamage] = true,
	[game.ATTRDEF_ENUM_TABLE.defence] = true,
	[game.ATTRDEF_ENUM_TABLE.specialDefence] = true,
	[game.ATTRDEF_ENUM_TABLE.speed] = true,
}

--生命 特攻 特防 速度 物防 物攻
game.ATTRDEF_SIMPLE_ENUM_TABLE = {
	hp = 1,
	speed = 2,
	damage = 3,
	defence = 4,
	specialDamage = 5,
	specialDefence = 6,
}
game.ATTRDEF_SIMPLE_TABLE = {}
for k, v in pairs(game.ATTRDEF_SIMPLE_ENUM_TABLE) do
	game.ATTRDEF_SIMPLE_TABLE[v] = k
end

--性别(0-无性别；1-雄性；2-雌性)
game.GENDER_ENUM_TABLE = {
	none = 0,
	male = 1,
	female = 2,
}
game.GENDER_TABLE = {}
for k, v in pairs(game.GENDER_ENUM_TABLE) do
	game.GENDER_TABLE[v] = k
end

-- 服务器货币值对应客户端上显示的 csvId
game.ITEM_STRING_ENUM_TABLE = {
	role_exp = 400, -- 战队经验
	gold = 401, -- 金币
	rmb = 402, -- 钻石
	stamina = 403, -- 体力
	vip = 404, -- vip
	vip_exp = 405, -- vip经验
	talent_point = 406, -- 天赋点
	equip_awake_frag = 407, -- 觉醒碎片
	contrib = 408, -- 公会经验
	coin1 = 411, -- 荣誉币(竞技场)
	coin2 = 412, -- 试炼币(以太乐园)
	coin3 = 413, -- 公会币
	coin4 = 414, -- 寻宝币(探险器)
	coin5 = 415, -- 精灵魂石(碎片商店，精灵分解)
	coin6 = 416, -- 石英金币(craft)
	coin7 = 419, -- 石英银币(craft) no use
	coin8 = 420, -- 跨服石英金币
	coin9 = 421, -- 跨服石英银币 no use
	coin10 = 422,--公会战金币
	coin11 = 423, --公会战银币 no use
	skill_point = 424,--技能点
	coin12 = 425, -- 对战竞技场(实时匹配)
	gym_talent_point = 426, -- 道馆天赋点、
	coin13 = 427,   -- 跨服资源战货币
	coin14 = 428,   -- 远征货币
	coin15 = 429,   -- 世界锦标赛货币
}
game.ITEM_STRING_TABLE = {}
for k, v in pairs(game.ITEM_STRING_ENUM_TABLE) do
	game.ITEM_STRING_TABLE[v] = k
end
game.ITEM_STRING_ENUM_TABLE["recharge_rmb"] = 402 -- 直充钻石

game.ITEM_TICKET = {
	-- gold = "gold",
	-- rmb = "rmb",
	pvpTicket = 517, -- 竞技场挑战
	rmbCard = 519, -- 钻石抽卡券
	goldCard = 518, -- 金币抽卡券
	equipCard = 503, -- 饰品抽卡券
	limitCard = 526, -- 限时抽卡券
	diamondUpCard = 527,--限时轮换钻石抽卡券
	card4 = 520, -- 寻宝券
	shopRefresh = 522, -- 商店刷新
	luckyEggScore = 6321, -- 扭蛋机积分货币
	luckyEggCard = 6320, -- 扭蛋机抽卡券
	goldGem = 530, -- 金币抽符石券
	rmbGem = 531, -- 钻石抽符石券
	passportCoin = 532, --通行证冒险积分
	passportVipCoin = 533, --通行证大师积分
	skinCard = 536, -- 时装点券
	chipCard = 537, -- 芯片抽取券
}

-- 经验类物品
game.ITEM_EXP_HASH = arraytools.hash({399, "role_exp", "vip", "vip_exp", "contrib", 417})

-- 品质对应的第一个阶数
game.QUALITY_TO_FITST_ADVANCE = {1, 2, 5, 9, 14, 20, 26}
game.QUALITY_MAX = #game.QUALITY_TO_FITST_ADVANCE

game.ITEM_CSVID_LIMIT = 10000 -- 道具
game.EQUIP_CSVID_LIMIT = 20000 -- 装备/饰品
game.FRAGMENT_CSVID_LIMIT = 30000 -- 卡牌碎片和装备碎片
game.HELD_ITEM_CSVID_LIMIT = 40000 -- 携带道具
game.GEM_CSVID_LIMIT = 50000 -- 符石
game.ZAWAKE_FRAGMENT_CSVID_LIMIT = 60000 -- Z觉醒碎片
game.CHIP_CSVID_LIMIT = 70000 -- 学习芯片

-- 道具类型
game.ITEM_TYPE_ENUM_TABLE = {
	normal = 0, -- 普通道具
	cardExp = 1, -- 经验药水
	staminaRecover = 2, -- 体力恢复
	gift = 3, -- 礼包
	equipExp = 4, -- 装备强化经验道具
	material = 5, -- 材料
	key = 6, -- 钥匙
	randomGift = 7, -- 随机礼包
	equipStarUp = 8, -- 装备觉醒
	feelExp = 9,-- 好感度经验道具
	randomGiftOpen = 10, -- 直接打开的随机礼包
	skin = 15, -- 皮肤道具
	chooseGift = 16, -- 可选择的道具礼包
	roleDisplayType = 17, -- 角色头像，头像框，角色形象，称号通用获得道具
	aptitude = 17, -- 道具资质
	characterType = 18, -- 性格道具
}
--道具球（捕捉用到的）
game.SPRITE_BALL_ID = {
	normal = 523,
	hero = 524,
	nightmare = 525,
}

--#勇者挑战模式
game.BRAVE_CHALLENGE_TYPE = {
	anniversary = 1,
	common = 2,
}
-- 	# 活动类型
game.YYHUODONG_TYPE_ENUM_TABLE = {
	everyDayLogin = -1, -- # 每日登陆奖励
	doubleDrop = -2, -- # 双倍掉率，次数增加
	limitDrop = -3, -- # 限时掉落

	firstRecharge = 1,	-- # 首充礼包
	loginWeal = 2,	-- # 登录福利
	levelAward = 3,	-- # 冲级奖金
	rechargeGift = 4,	-- # 充值送礼
	timeLimitDraw = 5,	-- # 限时魂匣抽卡
	monthlyCard = 6,	-- # 月卡
	dinnerTime = 7,	-- # 开饭
	clientShow = 8,	-- # 活动展示
	gateAward = 9,	-- # 通关奖励
	vipAward = 10,	-- # VIP奖励
	-- allLifeCard =, 11	-- # 终身月卡（废弃，以每日任务形式）
	itemExchange = 12,	-- # 道具兑换 (限时兑换)
	rmbCost = 13,	-- # 钻石消耗
	generalTask = 14,	-- # 任务 (等级礼包)
	serverOpen = 15,	-- # 开服活动
	fightRank = 16,	-- # 战力排行
	luckyCat = 17,	-- # 招财猫
	collectCard = 18,	-- # 招募数码兽
	dailyBuy = 19,	-- # 每日折扣
	timeLimitBox = 20,	-- # 限时宝箱
	vipBuy = 21,	-- # VIP折扣
	levelFund = 22,	-- # 等级基金
	itemBuy = 23,	-- # 道具折扣 (折扣礼包)
	yyClone = 24,	-- # 特殊克隆人
	breakEgg = 25,	-- # 砸金蛋
	worldBoss = 26,	-- # 世界boss
	regainStamina = 27,	-- # 补领体力
	onceRechageAward = 28,	-- # 单笔充钻石返还
	game2048 = 29,	-- # 2048游戏
	gameEatGreenBlock = 30,	-- # 拯救鼻涕兽
	rechargeReset = 31,	-- # 首充双倍重置
	gameGoDown100 = 32,	-- # 下100层游戏
	directBuyGift = 33,	-- # 直购礼包
	limitBuyGift = 34, -- # 限时礼包
	passport = 35, -- # 限时通行证
	timeLimitUpDraw = 36, -- # 限时轮换钻石抽卡
	LoginGift = 37, -- #每日登录活动
	rechargeWheel = 38, -- # 充值大转盘(又名充值夺宝)
	livenessWheel = 39, -- # 活跃夺宝
	luckyEgg = 40, --扭蛋
	Retrieve = 41, --资源找回
	festival = 42, --# 春节活动
	weeklyCard = 43, -- # 周卡
	gemUp = 44,	-- # 符石抽卡up
	baoZongzi = 45, -- # 包粽子
	reunion = 46, -- # 训练家重聚
	qualityExchange = 47, -- # 品质兑换
	flipCard = 48, -- # 翻牌赢头奖
	huoDongBoss = 49, -- # 活动Boss
	halloween = 50, -- # 万圣节活动
	double11 = 51, -- # 双十一
	huoDongCloth = 52, -- # 活动装扮
	snowBall = 53, -- # 扔雪球
	spriteUnfreeze = 54, -- # 主城精灵解冻
	skyScraper = 55, -- # 摩天大楼
	flipNewYear = 56, -- # 集福迎新年
	huodongCrossRedPacket = 57, -- # 跨服活动红包
	rmbgoldReward = 58,	-- # 返利
	playPassport = 59, -- #主题通行证
	gridWalk = 60, -- #走格子
	braveChallenge = 61, -- #勇者挑战
	horseRace = 62, -- # 赛马
	itemBuy2 = 63, -- #道具商店(礼券商店)
	exclusiveLimit = 64, -- # 尊享限定
	dispatch = 65, -- #五一派遣
	shavedIce = 66, -- #沙滩刨冰
	summerChallenge = 67,  -- #夏日挑战
    volleyball = 68,  -- #沙滩排球
	midAutumnDraw = 69,  -- #中秋祈福
	customizeGift = 70, -- #定制礼包
}

-- 消息
game.MESSAGE_TYPE_DEFS = {
	normal = 0,
	unionJoinUp = 1, -- 公会招募
	cloneInvite = 2, -- 克隆人邀请
	roleUnion = 3, -- 个人公会消息
	unionPlay = 4, -- 公会游戏玩法消息(火神兽，雪球)
	breakEgg = 5, -- 砸金蛋消息
	worldChat = 6, -- 世界聊天
	unionChat = 7, -- 公会聊天
	roleChat = 8, -- 私聊
	news = 9, -- 新闻
	battleShare = 10, -- 战报分享
	worldCardShare = 11, -- 世界卡牌分享
	worldCloneInvite = 12, -- 元素实验世界邀请
	unionCloneInvite = 13, -- 元素实验公会邀请
	friendCloneInvite = 14, -- 元素实验好友邀请
	unionCardShare = 15, -- 公会卡牌分享
	yyHuoDongRedPacketType = 16, -- 运营活动红包
	marqueeType = 17, -- 跑马灯
	worldReunionInvite = 18, -- 重聚活动世界邀请
	recommendReunionInvite = 19, -- 重聚活动推荐邀请
}
-- 消息类型展示

game.MESSAGE_SHOW_TYPE = {
	--1.富文本展示, 2.正常人物聊天展示, 3.主城界面不需要名字显示, 4.富文本展示且正常人物聊天样式
	[game.MESSAGE_TYPE_DEFS.normal] = {1},
	[game.MESSAGE_TYPE_DEFS.unionJoinUp] = {1},
	[game.MESSAGE_TYPE_DEFS.cloneInvite] = {1},
	[game.MESSAGE_TYPE_DEFS.roleUnion] = {1},
	[game.MESSAGE_TYPE_DEFS.unionPlay] = {1},
	[game.MESSAGE_TYPE_DEFS.breakEgg] = {1},
	[game.MESSAGE_TYPE_DEFS.worldChat] = {2, 3},
	[game.MESSAGE_TYPE_DEFS.unionChat] = {2, 3},
	[game.MESSAGE_TYPE_DEFS.roleChat] = {2, 3},
	[game.MESSAGE_TYPE_DEFS.news] = {1},
	[game.MESSAGE_TYPE_DEFS.battleShare] = {4},
	[game.MESSAGE_TYPE_DEFS.worldCloneInvite] = {4},
	[game.MESSAGE_TYPE_DEFS.unionCloneInvite] = {4},
	[game.MESSAGE_TYPE_DEFS.friendCloneInvite] = {4},
	[game.MESSAGE_TYPE_DEFS.worldCardShare] = {4},
	[game.MESSAGE_TYPE_DEFS.unionCardShare] = {4},
	[game.MESSAGE_TYPE_DEFS.yyHuoDongRedPacketType] = {4},
	[game.MESSAGE_TYPE_DEFS.marqueeType] = {1},
	[game.MESSAGE_TYPE_DEFS.worldReunionInvite] = {4},
	[game.MESSAGE_TYPE_DEFS.recommendReunionInvite] = {4},
}

-- 关卡玩法类型(主要区分)
game.GATE_TYPE = {
	newbie		= 999,		-- 新手关卡
	skillTest	= 99,		-- 全自动技能测试
	test		= 0,		-- 手动测试用本
	normal		= 1,		-- 普通副本
	arena		= 2,		-- 竞技场
	dailyGold 	= 3,		-- 日常活动本-金币本
	dailyExp 	= 4,		-- 日常活动本-经验本
	endlessTower = 5,		-- 无尽之塔副本
	unionFuben 	= 6,		-- 公会副本
	gift = 7,				-- 礼物本
	fragment = 8,			-- 碎片本
	friendFight = 9,		-- 好友切磋
	craft = 10,				-- 限时PVP
	randomTower = 11,		-- 随机试炼塔
	clone = 12,				-- 元素实验
	unionFight = 13,        -- 公会战
	crossCraft = 14, 		-- 跨服PVP(跨服王者)
	worldBoss = 15,         -- 世界Boss
	simpleActivity = 16,    -- 简单活动本(不带修正)
	crossArena = 17, 		-- 跨服竞技场
	gym = 18, 				-- 道馆副本
	gymLeader = 19, 		-- 道馆馆主
	crossGym = 20, 			-- 跨服道馆
	crossOnlineFight = 21, 	-- 跨服实时对战
	huoDongBoss = 22,       -- 活动Boss
	crossMine = 23,      	-- 跨服资源战pvp
	crossMineBoss = 24,     -- 跨服资源战boss
	braveChallenge = 25,    -- 勇者挑战
	hunting = 26,   	 	-- 远征
	summerChallenge = 27,   -- 夏日挑战
	crossUnionFight = 28,   -- 跨服公会战
	crossSupremacy = 29,    -- 世界锦标赛
}


game.GATE_TYPE_STRING_TABLE = {}
for k, v in pairs(game.GATE_TYPE) do
	game.GATE_TYPE_STRING_TABLE[v] = k
end

-- SCENE_TYPE服务器用来判断类型，客户端用GATE_TYPE来区分
-- GATE_TYPE主要用于客户端战斗处理

-- 服务器场景定义，对应服务器上的定义(配表里面配置的场景一般会是这个)
-- 该定义与scene_conf表里的sceneType无关
game.SCENE_TYPE = {
	city = 0, -- 主城
	gate = 1, -- 关卡
	arena = 2, -- 竞技场
	huodongFuben = 3, -- 活动副本
	endlessTower = 4, -- 无尽之塔 （冒险之路）
	unionFuben = 5, -- 公会副本
	craft = 6, -- 限时PVP（王者）(石英大会)
	clone = 7, -- 元素挑战
	randomTower = 8, -- 随机试炼塔 （以太乐园
	unionFight = 9, -- 公会战
	crossCraft = 10, -- 跨服石英大会
	worldBoss = 11, -- 世界Boss
	crossArena = 12, -- 跨服竞技场
	crossOnlineFight = 13, -- 实时匹配对战
	gym = 14, --道馆挑战
	huoDongBoss = 15, --活动Boss
	gymPvp = 16, --道馆pvp
	crossMine = 17, -- 资源战 pvp
	crossMineBoss = 18, -- 资源战 boss
	braveChallenge = 19, -- 勇者挑战
	hunting = 20, -- 远征
	summerChallenge = 21, -- 夏日挑战
}

-- 天赋类型定义
game.TALENT_TYPE = {
	battleFront = 1, -- 上阵前排
	battleBack = 2, -- 上阵后排
	cardsAll = 3, -- 全体卡牌
	cardNatureType = 4, -- 指定属性卡牌
	sceneType = 6, -- 场景加成
}


-- 布阵数据来源
game.EMBATTLE_FROM_TABLE = {
	default = "default",		-- 默认
	arena = "arena",			-- pvp
	huodong = "huodong",		-- 活动
	input = "input",			-- 阵容由客户端输入
	gymChallenge = "gymChallenge",			-- 改为道馆专用 本地缓存
	onlineFight = "onlineFight",-- 实时匹配
	onekey = "onekey",			-- 一键布阵阵容
	huodongBoss = "huodongBoss", -- 节日Boss
	ready = "ready",  -- 预设修改队伍
	hunting = "hunting", -- 狩猎地带
}

game.SCENE_TYPE_STRING_TABLE = {}
for k, v in pairs(game.SCENE_TYPE) do
	game.SCENE_TYPE_STRING_TABLE[v] = k
end
-- 数字类型
game.NUM_TYPE = {
	percent = 0, -- 含%的数字
	number = 1, --不含%的数字
}

-- 售卖类型
game.SELL_TYPE = {
	hand = 0,
	auto = 1,
}

-- 通用目标类型（主线，日常任务，运营活动任务）
game.TARGET_TYPE = {
	Level = 1, -- 角色等级
	Gate = 2, -- 通过章节关卡
	CardsTotal = 3, -- 拥有卡牌数量
	CardGainTotalTimes = 4, -- 卡牌获得总次数
	Vip = 5, -- 达到vip等级
	FightingPoint = 6, -- 战力达到多少
	CardAdvanceTotalTimes = 7, -- 卡牌进阶总次数
	GateStar = 8, -- 副本总星数（主线，精英，噩梦）
	CardAdvanceCount = 9, -- 拥有某品质卡牌的数量
	CardStarCount = 10, -- 拥有某星数卡牌的数量
	EquipAdvanceCount = 11, -- 拥有某品质饰品的数量
	EquipStarCount = 12, -- 拥有某星数饰品的数量
	HadCard = 13, -- 拥有某卡牌
	GainCardTimes = 14, -- 获得某卡牌系列的次数
	CompleteImmediate = 15, -- 激活即完成（上线即完成）

	OnlineDuration = 16, -- 累计在线时间
	LoginDays = 17, -- 登录天数
	LianjinTimes = 18, -- 购买金币次数
	GainGold = 19, -- 获得金币
	CostGold = 20, -- 消耗金币
	CostRmb = 21, -- 消费钻石数量
	RechargeRmb = 22, -- 充值钻石
	ShareTimes = 23, -- 分享次数
	-- KillMonster = 24, -- 副本，爬塔，活动击杀怪物总数量
	SigninTimes = 25, -- 签到次数
	BuyStaminaTimes = 26, -- 购买体力次数
	GiveStaminaTimes = 27, -- 赠送好友体力
	CostStamina = 28, -- 消耗体力
	GateChanllenge = 29, -- 挑战普通关卡次数
	HeroGateChanllenge = 30, -- 挑战精英关卡次数
	NightmareGateChanllenge = 31, -- 挑战噩梦关卡次数
	HuodongChanllenge = 32, -- 挑战活动副本次数
	GateSum = 33, -- 累计打关卡数（普通，精英）

	CardSkillUp = 34, -- 卡牌技能升级次数
	CardAdvance = 35, -- 卡牌进阶次数
	CardLevelUp = 36, -- 卡牌升级次数
	CardStar = 37, -- 卡牌升星次数

	EquipStrength = 38, -- 装备强化（升级）次数
	EquipAdvance = 39, -- 装备进阶次数
	EquipStar = 40, -- 装备升星次数

	ArenaBattle = 41, -- 竞技场战斗次数
	ArenaBattleWin = 42, -- 竞技场胜利次数
	ArenaPoint = 43, -- 竞技场积分
	ArenaRank = 44, -- 竞技场排名

	DrawCard = 45, -- 金币钻石抽卡次数
	DrawCardRMB10 = 46, -- 抽卡钻石10连抽
	DrawCardRMB1 = 47, -- 抽卡钻石单抽
	DrawCardGold10 = 48, -- 抽卡金币十连抽
	DrawCardGold1 = 49, -- 抽卡金币单抽
	DrawCardRMB = 50, -- 钻石抽卡次数
	DrawCardGold = 51, -- 金币抽卡次数
	DrawEquip = 52, -- 装备抽取次数
	DrawEquipRMB10 = 53, -- 装备十连抽
	DrawEquipRMB1 = 54, -- 装备单抽

	UnionContrib = 55, -- 公会捐献次数
	UnionSpeedup = 56, -- 给公会成员成员加速次数
	UnionSendPacket = 57, -- 公会发红包次数
	UnionRobPacket = 58, -- 公会抢红包次数
	UnionFuben = 59, -- 公会副本次数

	RandomTowerTimes = 60, -- 随机试练塔通过房间数量
	RandomTowerBoxOpen = 61, -- 随机试炼宝箱开启次数
	RandomTowerPointDaily = 62, -- 随机试炼当日积分
	RandomTowerPoint = 63, -- 随机试炼积分
	RandomTowerFloorTimes = 64, -- 随机试炼塔累计通过层数
	WorldBossBattleTimes = 65, -- 世界boss战次数
	CloneBattleTimes = 66, -- 克隆人玩法次数

	RandomTowerFloorMax = 67, -- 随机试炼塔最高通过层数
	-- AllCanItems = 68, -- 万能碎片转换
	-- CardComb = 69, -- 合成卡牌次数

	DailyTaskFinish = 70, -- 日常任务完成（领奖励时计入）次数
	DailyTaskAchieve = 71, -- 完成日常任务到一定次数（完成就计数，不一定领奖励）
	ItemBuy = 72, -- 道具贩卖
	YYHuodongOpen = 73, -- 运营活动开启	(不计算该活动是否对某玩家激活)

	UnionDailyGiftTimes = 74, -- 公会领取礼包次数
	UnionContribSum = 75, -- 公会累计捐献经验

	UnlockPokedex = 76, -- 解锁图鉴数量
	EndlessPassed = 77, -- 无尽之塔通关第XX关 (配置关卡ID)
	Friends = 78, -- 好友数量

	TrainerLevel = 79,  -- 训练家等级
	CaptureLevel = 80, -- 捕捉等级
	CaptureSuccessSum = 81, -- 累计捕捉成功的次数
	Explorer = 82, -- 激活的探险器数量
	ExplorerComponentStrength = 83, -- 探险器组件升级次数
	ExplorerAdvance = 84, -- 激活/进阶探险器次数
	DispatchTaskDone = 85, -- 完成派遣任务次数
	DispatchTaskQualityDone = 86, -- 完成指定稀有度的派遣任务次数
	HeldItemStrength = 87, -- 携带道具强化次数
	HeldItemAdvance = 88, -- 携带道具突破次数
	EffortTrainTimes = 89, -- 努力值培养次数
	EffortGeneralTrainTimes = 90, -- 努力值普通培养次数
	EffortSeniorTrainTimes = 91, -- 努力值高级培养次数
	CardAbilityStrength = 92,  -- 特性（潜能）升级次数
	EndlessChallenge = 93, -- 无尽塔的任务
	DrawItem = 94, -- 探险器寻宝次数
	DrawCardUp = 95, -- UP 抽卡（限定抽卡）
	DrawCardUpAndRMB = 96, -- UP 抽卡和钻石抽卡
	Top6FightingPoint = 97, -- TOP6战力达到多少
	UnionFragDonate = 98, -- 公会碎片赠予
	TalentPointCost = 99, -- 累计天赋点使用
	RandomTowerBattleWin = 100, -- 以太乐园战斗胜利次数
	DispatchTask = 101, -- 派遣任务次数
	CraftSignup = 102, -- 报名石英大会，只记录手动报名
	DrawGemRMB = 103, -- 钻石抽符石次数
	DrawGemGold = 104, -- 金币抽符石次数
	DrawGem = 105, -- 符石抽取次数
	DrawGemUp = 106, -- 限定up符石
	DrawGemUpAndRMB = 107, -- 限时up符石和钻石抽符石
	FishingTimes = 108, -- 钓鱼次数
	FishingWinTimes = 109, -- 钓鱼成功次数
	CooperateClone = 110, -- 协同元素挑战次数
	ReunionFriend = 111, -- 添加绑定对象好友
	RandomTowerFloorSum = 112, -- 随机试炼塔通过指定层数的次数
	HuntingPass = 113, -- 远征普通线路通关次数
	HuntingSpecialPass = 114, -- 远征进阶线路通关次数
	DrawChipRMB = 115, -- 钻石抽芯片次数
	DrawChipItem = 116, -- 道具抽芯片次数
	DrawChip = 117, -- 抽芯片次数
}

game.EMBATTLE_HOUDONG_ID = {
	randomTower = -1, -- 随机塔
	nightmare = -2, -- 主线噩梦
	unionGate = -3, -- 公会副本
	worldBoss = -4, -- 世界Boss
	endlessTower = -5, -- 无限之塔
	crossMineBoss = -6 -- 跨服资源战boss
}

game.PRIVILEGE_TYPE = {
	FirstRMBDrawCardHalf = 1, -- 钻石扭蛋每日首次半价
	StaminaMax = 2, -- 体力上限+x (等级相关 + 月卡特权 + 训练师等级特权)
	StaminaBuyTimes = 3, -- 体力购买上限增加  (vip特权 + 训练师等级特权)
	LianjinBuyTimes = 4, -- 金币购买上限增加  (vip特权 + 训练师等级特权)
	BattleSkip = 5, -- 某些战斗情景可以跳过战斗 (配置 game.SCENE_TYPE)
	DailyTaskExpRate = 6, -- 日常任务获得经验增加(百分比) 增对日常任务奖励里面的 role_exp 增加
	HuodongTypeGoldTimes = 7, -- 金币副本次数增加  (配置次数 + 训练师等级特权 + 运营活动增加次数)
	HuodongTypeExpTimes = 8, -- 经验副本次数增加 (配置次数 + 训练师等级特权 + 运营活动增加次数)
	ExpItemCostFallRate = 9, -- 经验药水购买价格下降(百分比) (配置价格 * (1 - 下降比例))
	TrainerAttrSkills = 10,
	FreeGoldDrawCardTimes = 11, --  金币抽卡免费次数增加  (5 + 训练师等级特权)
	LianjinFreeTimes = 12, -- 点金免费次数增加 (月卡特权 + 训练师等级特权)
	LianjinDropRate = 13, -- 点金额外获得量(百分比) 一次炼金产出 * (正常暴击 + 月卡特权 + 训练师等级特权 + 双倍活动)
	StaminaGain = 14, -- 体力领取 (增加体力领取运营活动配置的 paramMap 加成)
	HuodongTypeGoldDropRate = 15, -- 金币副本产出增加(百分比) (正常产出 * (1 + 训练师等级加成 + 双倍掉落))
	HuodongTypeExpDropRate = 16, -- 经验副本产出(百分比) (正常产出 * (1 + 训练师等级加成 + 双倍掉落))
	UnionContribCoinRate = 17, -- 公会捐献时公会币获得增加(百分比) （正常产出 * ( 1 + 训练师等级加成)）
	GateGoldDropRate = 18, -- 普通副本金币获得量增加(百分比) (只增对scene_conf 里面配置的金币加成，掉落的不享受)
	HeroGateGoldDropRate = 19, -- 精英副本金币获得量增加(百分比) (只增对scene_conf 里面配置的金币加成，掉落的不享受)
	GateSaoDangTimes = 20, --# 副本扫荡次数开放(次数)
	DrawItemFreeTimes = 21, --# 探险器寻宝额外免费次数
	DispatchTaskFreeRefreshTimes = 22, --# 派遣任务免费刷新次数
	HuodongTypeGiftTimes = 23,  -- 礼物副本次数增加  (配置次数 + 训练师等级特权 + 运营活动增加次数)
	HuodongTypeGiftDropRate = 24, -- 礼物副本产出增加(百分比) (正常产出 * (1 + 训练师等级加成 + 双倍掉落))
	HuodongTypeFragTimes = 25, -- 碎片副本次数增加 (配置次数 + 训练师等级特权 + 运营活动增加次数)
	HuodongTypeFragDropRate = 26, -- 碎片副本产出(百分比) (正常产出 * (1 + 训练师等级加成 + 双倍掉落))
	FirstRMBDrawItemHalf = 27, -- 每日首次钻石寻宝1次特权半价（探险器功能里）
}

game.PRIVILEGE_TYPE_STRING_TABLE = {}
for k, v in pairs(game.PRIVILEGE_TYPE) do
	game.PRIVILEGE_TYPE_STRING_TABLE[v] = k
end

-- 双倍活动相关
game.DOUBLE_HUODONG = {
	gateDrop = 1,		-- 关卡掉落双倍
	goldActivity = 2,	-- 金币副本次数增加
	expActivity = 3,	-- 经验副本次数增加
	giftActivity = 4,	-- 礼物副本次数增加
	fragActivity = 5,	-- 碎片副本次数增加
	buyGold = 6,		-- 点金前N次双倍产出
	buyStamina = 7,		-- 体力购买前N次双倍产出
	heroGateTimes = 8,	-- 精英副本挑战次数增加
	endlessSaodang = 9,	-- 无尽之塔扫荡奖励双倍(首通不双倍)
	randomGold = 10,	-- 随机试炼塔金币双倍 gold字段
}

-- 进度赶超加成类型
game.REUNION_DOUBLE = {
	huodongCount = 1, 		-- 活动副本次数增加
	endlessSaodang = 2,		-- 冒险之路扫荡翻倍
	doubleDropGate = 3,		-- 关卡产出双倍
	doubleBuyStamina = 4,	-- 体力购买双倍
	doubleLianjin = 5,		-- 聚宝产出双倍
}

-- 双倍活动和进度赶超映射
game.NORMAL_TO_REUNION = {
	[game.DOUBLE_HUODONG.gateDrop] = game.REUNION_DOUBLE.doubleDropGate,
	[game.DOUBLE_HUODONG.endlessSaodang] = game.REUNION_DOUBLE.endlessSaodang,
	[game.DOUBLE_HUODONG.goldActivity] = game.REUNION_DOUBLE.huodongCount,
	[game.DOUBLE_HUODONG.expActivity] = game.REUNION_DOUBLE.huodongCount,
	[game.DOUBLE_HUODONG.giftActivity] = game.REUNION_DOUBLE.huodongCount,
	[game.DOUBLE_HUODONG.fragActivity] = game.REUNION_DOUBLE.huodongCount,
	[game.DOUBLE_HUODONG.buyStamina] = game.REUNION_DOUBLE.doubleBuyStamina,
	[game.DOUBLE_HUODONG.buyGold] = game.REUNION_DOUBLE.doubleLianjin,
}

-- 跨服石英各个round，按顺序
game.CROSS_CRAFT_ROUNDS = {
	"closed", "signup", "prepare",
	"pre11", "pre11_lock", "pre12", "pre12_lock", "pre13", "pre13_lock", "pre14", "pre14_lock",
	"pre21", "pre21_lock", "pre22", "pre22_lock", "pre23", "pre23_lock", "pre24", "pre24_lock",
	"halftime", "prepare2",
	"pre31", "pre31_lock", "pre32", "pre32_lock", "pre33", "pre33_lock", "pre34", "pre34_lock",
	"top64", "top64_lock", "top32", "top32_lock", "top16", "top16_lock",
	"final1", "final1_lock", "final2", "final2_lock", "final3", "final3_lock",
}
-- time:到下一阶段的持续时间
game.CROSS_CRAFT_ROUND_STATE = {
	closed		= {},
	signup		= {time = 8*3600 + 50*60},
	prepare		= {time = 10*60},
	pre11		= {time = 3*60},
	pre11_lock	= {time = 60},
	pre12		= {time = 3*60},
	pre12_lock	= {time = 60},
	pre13		= {time = 3*60},
	pre13_lock	= {time = 60},
	pre14		= {time = 3*60},
	pre14_lock	= {time = 60},
	pre21		= {time = 3*60},
	pre21_lock	= {time = 60},
	pre22		= {time = 3*60},
	pre22_lock	= {time = 60},
	pre23		= {time = 3*60},
	pre23_lock	= {time = 60},
	pre24		= {time = 3*60},
	pre24_lock	= {time = 60},
	-- 第一天19:32 - 第二天18:50
	halftime	= {time = 86400 - 42*60},
	prepare2	= {time = 10*60},
	pre31		= {time = 3*60},
	pre31_lock	= {time = 60},
	pre32		= {time = 3*60},
	pre32_lock	= {time = 60},
	pre33		= {time = 3*60},
	pre33_lock	= {time = 60},
	pre34		= {time = 3*60},
	pre34_lock	= {time = 60},
	top64		= {time = 4*60},
	top64_lock	= {time = 60},
	top32		= {time = 4*60},
	top32_lock	= {time = 60},
	top16		= {time = 4*60},
	top16_lock	= {time = 60},
	final1		= {time = 4*60},
	final1_lock	= {time = 60},
	final2		= {time = 4*60},
	final2_lock	= {time = 60},
	final3		= {time = 4*60},
	final3_lock	= {time = 60},
}

game.RANDOM_TOWER_JUMP_STATE = {
	BEGIN = 0,
	POINT = 1,
	BOX = 2,
	BUFF = 3,
	EVENT = 4,
	OVER = 5,
}

game.DEPLOY_TYPE = {
	GeneralType = 1, -- 常规
	OneByOneType = 2, -- 单挑
	WheelType = 3,-- 车轮战
}

game.SYNC_SCENE_STATE = {
	unknown             =	0,
	start               =	1,
	banpick             =	2, -- 双方选择
	deploy              =	3, -- 双方布阵 -- no use
	waitloading         =   4, -- 等待双方加载
	attack              =   5, -- 开始战斗
	waitresult          =   6, -- 等待结果 -- no use
	battleover          =   7, -- 战斗结束
}

game.SHOP_INIT = {
	FIX_SHOP = 1,
	UNION_SHOP = 2,
	FRAG_SHOP = 3,
	PVP_SHOP = 4,
	EXPLORER_SHOP = 5,
	RANDOM_TOWER_SHOP = 6,
	CRAFT_SHOP = 7,
	EQUIP_SHOP = 8,
	UNION_FIGHT_SHOP = 9,
	CROSS_CRAFT_SHOP = 10,
	CROSS_ARENA_SHOP = 11,
	FISHING_SHOP = 12,
	ONLINE_FIGHT_SHOP = 13,
	SKIN_SHOP  = 14,
	CROSS_MINE_SHOP  = 15,
	HUNTING_SHOP = 16,
}

game.SHOP_GET_PROTOL = {
	[1] = "/game/fixshop/get",
	[2] = "/game/union/shop/get",
	[3] = "/game/frag/shop/get",
	[5] = "/game/explorer/shop/get",
	[6] = "/game/random_tower/shop/get",
	[8] = "/game/equipshop/get",
	[12] = "/game/fishing/shop/get"
}

game.SHOP_UNLOCK_KEY = {
	[1] = {},
	[2] = {unlockKey = "unionShop", mustHaveUion = true},
	[3] = {unlockKey = "fragmentShop"},
	[4] = {unlockKey = "arenaShop"},
	[5] = {unlockKey = "explorer"},
	[6] = {unlockKey = "randomTower"},
	[7] = {unlockKey = "craft"},
	[8] = {unlockKey = "drawEquip"},
	[9] = {unlockKey = "unionFight" , mustHaveUion = true},
	[10] = {unlockKey = "crossCraft"},
	[12] = {unlockKey = "fishing"},
	[13] = {unlockKey = "onlineFight"},
	[14] = {unlockKey = "skinShop"},
	[15] = {unlockKey = "crossMine"},
	[16] = {unlockKey = "hunting"},
}

-- 服务器奖励model数据字段
game.SERVER_RAW_MODEL_KEY = {"carddbIDs", "card2fragL", "card2mailL", "chipdbIDs", "cards", "heldItemdbIDs", "gemdbIDs"}
