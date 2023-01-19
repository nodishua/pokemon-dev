--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- battle相关全局变量
--

-- for keep fix value in code safe
globals.ConstSaltNumbers = table.salttable({
	wan = 10000.0,
	neg1 = -1.0,
	dot05 = 0.05,
	dot01 = 0.01,
	dot1 = 0.1,
	zero = 0,
	one = 1,
	dot96 = 0.96,
	one15 = 1.15,
})


local battle = {}
globals.battle = battle

-- 加速, 默认一倍速是：1.1， 两倍速是：1.6
battle.SpeedTimeScale = {
	single = 1.1,
	double = 1.6,
	triple = 2.5,
	ultAcc = 10,

	[1] = 1.1,
	[2] = 1.6,
	[3] = 2.5,
}

local StandingPos = {
	[1] = {x = 956, y = 826 - display.fightLower},
	[2] = {x = 792, y = 592 - display.fightLower},
	[3] = {x = 640, y = 348 - display.fightLower},
	[4] = {x = 600, y = 826 - display.fightLower},
	[5] = {x = 430,  y = 592 - display.fightLower},
	[6] = {x = 244,  y = 348 - display.fightLower},

    [13] = {x = display.width/2, y = 826 - display.fightLower},
	[14] = {x = display.width/2, y = 826 - display.fightLower},

	[99] = {x = 0, y = 9999}
}
battle.StandingPos = StandingPos

-- 暂停不展示星级条件的关卡玩法类型
battle.PauseNoShowStarConditionsGateType = {
	[game.GATE_TYPE.endlessTower] = true,
	[game.GATE_TYPE.test] = true,
	[game.GATE_TYPE.arena] = true,
	[game.GATE_TYPE.crossArena] = true,
	[game.GATE_TYPE.randomTower] = true,
	[game.GATE_TYPE.crossOnlineFight] = true,
	[game.GATE_TYPE.gym] = true,
	[game.GATE_TYPE.gymLeader] = true,
	[game.GATE_TYPE.crossMine] = true,
	[game.GATE_TYPE.crossMineBoss] = true,
	[game.GATE_TYPE.braveChallenge] = true,
	[game.GATE_TYPE.hunting] = true,
	[game.GATE_TYPE.summerChallenge] = true,
}

battle.EndSpecialCheck = {
	ForceNum = 1,
	HpRatioCheck = 2,
	TotalHpCheck = 3,
	AllHpRatioCheck = 4,
	FightPoint = 5,
	CumulativeSpeedSum = 6,
	SoloSpecialRule = 7,
	LastWaveTotalDamage = 8,
	DirectWin = 9,
	EnemyOnlySummonOrAllDead = 10,
	BothDead = 11,
}

battle.MainSkillType = {
	NormalSkill = 0, --普通攻击
	SmallSkill = 1, --小技能
	BigSkill = 2, --大招
	PassiveSkill = 3, --被动技能

	TagSkill = 99, -- 标记技能
}

battle.SkillType = {
	NormalSkill = 0, -- 常规技能
	PassiveAdd = 1, -- 被动技件增加
	PassiveAura = 2,-- 被动技件光环
	PassiveSkill = 3, -- 被动技件触发
	PassiveSummon = 4,
	PassiveCombine = 5
}

battle.SkillAddBuffType = {
	Before = 1,--技能效果前
	After = 2,--技能效果后
	InPlay = 3--显示在第一段 实际逻辑在技能效果前
}
-- 技能攻击类型
battle.SkillFormulaType = {
	damage = 1,
	resumeHp = 2,
	fix = 3,
}

battle.SkillSegType = {
	damage = "damage",
	resumeHp = "resumeHp",
	buff = "buff",
}

-- 13是屏幕中央
-- 14是原地不动
battle.AttackPosIndex = {
	center = 13,
	selfPos = 14,
}

battle.AttackPos = {
	[1] = {x = StandingPos[1].x + 100*2, y = StandingPos[1].y},
	[2] = {x = StandingPos[2].x + 100*2, y = StandingPos[2].y},
	[3] = {x = StandingPos[3].x + 100*2, y = StandingPos[3].y},
	[4] = {x = StandingPos[4].x + 100*2, y = StandingPos[4].y},
	[5] = {x = StandingPos[5].x + 100*2, y = StandingPos[5].y},
	[6] = {x = StandingPos[6].x + 100*2, y = StandingPos[6].y},

	[13] = {x = display.width/2, y = StandingPos[2].y}, -- 屏幕中央
}

battle.ProtectPosIdx = {
	centerLeft = 13,
	centerRight = 14
}
battle.ProtectPos = {
	[1] = {x = StandingPos[1].x + 150, y = StandingPos[1].y},
	[2] = {x = StandingPos[2].x + 150, y = StandingPos[2].y},
	[3] = {x = StandingPos[3].x + 150, y = StandingPos[3].y},
	[4] = {x = StandingPos[4].x + 150, y = StandingPos[4].y},
	[5] = {x = StandingPos[5].x + 150, y = StandingPos[5].y},
	[6] = {x = StandingPos[6].x + 150, y = StandingPos[6].y},

	[13] = {x = (display.width/2) - 150, y = StandingPos[2].y},
	[14] = {x = (display.width/2) + 150, y = StandingPos[2].y}
}

battle.SpriteRes = {
	natureQuan = "effect/xuanzhongkuang.skel",
	natureQuanTxtDi = "battle/logo_gray.png",

	groundRing = "effect/jiaodixzk.skel",
	mainSkill = "effect/dz_ice.skel",
	fireShield = "koudai_yuanshiguladuo/guladuo_mega.skel"
}

-- 特殊个体id 需要留一位
battle.SpecialObjectId = {
    teamShiled = 13,
    --enemyTeamShiled = 14,
}

-- onShowHeadNumber伤害数字等资源
battle.ShowHeadNumberRes = {
	txtStrong = "battle/txt/txt_xgbq.png",
	txtWeak = "battle/txt/txt_sxsw.png",
	txtFullweak = "battle/txt/txt_myxg.png",

	txtXx = "battle/txt/txt_xx.png",
	txtFs = "battle/txt/txt_fs.png",
	txtSb = "battle/txt/txt_sb.png",
	txtGd = "battle/txt/txt_gd.png",
	txtBj = "battle/txt/txt_bj.png",
	txtFj = "battle/txt/txt_fj.png",

	txtBjDi = "battle/txt/bg_bj_di.png",
	txtPtshDi = "battle/txt/bg_ptsh_di.png",
	txtKzDi = "battle/txt/bg_kz_di.png",
	txtZlszDi = "battle/txt/bg_zlsz_di.png",

	txtPhysicalImmune = "battle/txt/txt_wgshmy.png",
	txtSpecialImmune = "battle/txt/txt_tgshmy.png",
	txtAllImmune = "battle/txt/txt_mysh.png",

	fontBj = "bj",
	fontPtsh = "ptsh",
	fontZlsz = "zlsz",
	fontKz = "kz",

	txtTypeImmune = "battle/txt/txt_my%s.png",
}

-- MainArea资源
battle.MainAreaRes = {
	txtZsh = "battle/txt/txt_zsh.png",
	txtZzl = "battle/txt/txt_zzl.png",
	diZzl = "battle/txt/bg_zzl_di.png",
	txtNqz = "battle/txt/txt_nqjl.png",
	fontNqz = "font/digital_nqjl.png",
	waveDiTu = "battle/img_pc.png",

	fontZsh = "zsh",
	fontZzl = "zzl",
}

-- Stage资源
battle.StageRes = {
	cutRes = "effect/cutscreen4.skel",
	daZhaoBJ = "effect/dazhao_bj.skel",
}

-- 特效层级控制表 越高越在上层
battle.SpriteLayerZOrder = {
	ground = 9,			-- 脚下光圈
	selfSpr = 10,		-- 自身单位
	lifebar = 12,		-- 生命值条
	-- buff = 13,			-- buff特效 buff表deepCorrect替代
	quan = 14,			-- 选中框
	mainSkill = 15,		-- 大招特效
	qipao = 9500,		-- 气泡
}

-- gameLayer中的z层级
battle.GameLayerZOrder = {
	icon = 8000, -- + BattleSprite.posZ
	overlay = 8500, -- + BattleSprite.posZ
	text = 9999,
}

battle.AssignLayer = {
	stageLayer = 0, 	 	-- 背景层
	roleLayer = 1,			-- 角色层
	gameLayer = 2,			-- 游戏层
	effectLayerLower = 3,	-- 大招特效层
	effectLayer = 4,		-- 特效层
	frontStageLayer = 5,	-- 前景层
}

-- 表现的优先级
battle.EffectZOrder = {
	none = 0,
	dead = 9999,
}

battle.LoopActionMap = {
	standby_loop = true,
	run_loop = true,
	stun_loop = true,
	win_loop = true,
}

-- key与effect_factory里的type对应
battle.EffectEventArgFields = {
	sound = {'sound'},
	shaker = {'shaker','segInterval'},
	music = {'music'},
	move = {'move'},
	show = {'show'},
	damageSeg = {'damageSeg', 'segInterval'},
	hpSeg = {'hpSeg', 'segInterval'},
	effect = {'effectType', 'effectRes', 'effectArgs'},
	zOrder = {'zOrder'},
	follow = {'follow'},
	jump = {'jumpFlag'},
    control = {'control'},
}

battle.FilterDeferListTag = {
	none = 0,
	cantJump = 1,
	cantClean = 2,
}

-- 动作表
battle.SpriteActionTable = {
	standby = "standby_loop",
	run = "run_loop",
	attack = "attack",
	hit = "hit",
	charging = "charging",		-- 充能动作 --todo 可能不叫这个名字
	death = "death",			-- 死亡动作 目前已知只有金币本BOSS有
}

-- 战斗内操作
battle.OperateTable = {
	skill = 1,
	pause = 2,
	timeScale = 3,
	autoFight = 6,
	story = 7,
	choose = 8,
	attack = 9,
	helper = 10,
	noAttack = 11,
	pass = 12,
	runAway = 13,
	fullManual = 14,
	ultAcc = 15,
	ultAccEnd = 16,
	passOneWave = 17,
}


-- battle loading和view的一些参数
battle.DefaultModes = {
	baseMusic = nil,
	isRecord = nil,				-- 是战报
	noShowEndRewards = nil,		-- 不显示战斗奖励
	nextShowStageUp = nil,      -- 下一步显示段位提升
}


-- 0.自动触发
-- 1.第几回合触发
-- 2.每隔几回合触发 (策划说 是在自己的攻击回合)
-- 3.死亡触发
-- 4.假死触发（自身带有复活技未使用时死亡）
-- 5.濒死（受到致死伤害）触发
-- 6:受击触发
-- 7.进入战场触发
-- 8.攻击触发
-- 9.回合结束触发  (补充: 0自己的攻击回合/1大回合结束)
-- 10.击杀触发
-- 11.受到特定属性的攻击触发
-- 12.受到暴击伤害触发
-- 13.受到属性相克的伤害触发
-- 14.受到非属性相克的伤害触发
-- 15.满HP受到伤害触发
-- 16.受到物理攻击类型伤害触发
-- 17.受到特殊攻击类型伤害触发
-- 18.HP低于xx%时触发
-- 19.友方队伍存在指定数量、特定属性的宝可梦触发
-- 20.战场为xx天气时触发
-- 21.被施加特定buff
-- 22.身上的可携带道具被消耗触发
-- 23.攻击回合开始触发
-- 24.自身HP低于xx%时触发buff，且实时监测血量变化，不满足时取消buff
-- 25.若己方队伍存在HP低于xxx的精灵，触发的buff
-- 26.主动释放治疗技能时触发的buff
-- 27.释放技能成功后附加指定buff时，对目标额外添加buff
-- 28.若己方队伍存在HP低于xxx的精灵，触发的buff, 且实时监测hp变化，不满足时取消buff
-- 29.大回合开始前
battle.PassiveSkillTypes = {
	create = 0,
	round = 1,
	cycleRound = 2,
	realDead = 3,
	fakeDead = 4,
	beDeathAttack = 5,
	beAttack = 6,
	enter = 7,
	attack = 8,
	roundEnd = 9,
	kill = 10,
	beSpecialNatureDamage = 11,
	beStrike = 12,
	beNatureDamage = 13,
	beNonNatureDamage = 14,
	beDamageIfFullHp = 15,
	beDamage = 16,
	beSpecialDamage = 17,
	hpLess = 18,
	beSpeciaSelfForce = 19, -- 待添加
	beWeather = 20, -- 待添加
	beSpeciaBuff = 21, -- 待添加
	beToolsComsumed = 22, -- 待添加
	roundStartAttack = 23,
	dynamicHpLess = 24, -- like 18, bug
	teamHpLess = 25,
	recoverHp = 26,
	additional = 27,
	dynamicTeamHpLess = 28, -- like 25, bug
    roundStart = 29,

	-- reAttack = 99, -- 反击，待定
}

-- 针对PassiveSkillTypes.roundEnd的参数
-- 0自己的攻击回合/1大回合结束
battle.PassiveRoundEndFlag = {
	SelfBattleTurn = 0,
	Round = 1,
}

-- 支持修改的技能属性类型, cdRound等参数在程序内有使用到，且涉及面比较多
battle.SkillAttrsInCsv = {
	"cdRound",
	"skillHit",
	"startRound",
	"skillPower",
	"skillNatureType",
}

-- 控制类型的buff记录
battle.ControllBuffType = {
	['stun'] 		= true,
	['changeImage'] = true, -- 当前变形象是用stun做的
	['sleepy']		= true,
	['silence']		= true,
	['sneer']		= true,
	['freeze']		= true,
	['leave']		= true,
	-- ['confusion']	= true,		-- 混乱可能不算是控制类型的buff,还是能行动
}

-- 显示被攻击时对敌方技能的克制状态
battle.RestraintTypeIcon = {
	-- normal = {nil, ""},
	strong = "battle/logo_kz.png",
	weak = "battle/logo_dk.png",
	fullweak = "battle/logo_myxg.png",

	physical = "battle/txt_mywg.png",
	special = "battle/txt_mytg.png",
	allimmune = "battle/txt_mysh.png",
}

battle.BuffTriggerPoint = {
	onNodeCall = 0,			-- buff内部的节点间调用(这种只在内部调用,外部一般不会用到该字段,主要是给配表用)
	onBuffCreate = 1,		-- 指buff自身，下同
	onBuffOver = 2,

	onRoundStart = 3,			-- 回合开始
	onRoundEnd = 4,				-- 回合结束

	onHolderBattleTurnStart = 5,		-- holder在一个回合的行动顺序中，轮到它的顺序开始战斗时
	onHolderBattleTurnEnd = 6,			-- holder在一个回合的行动顺序中，轮到它战斗, 战斗结束时 暂时注掉

	onHolderAttackBefore = 7, 	-- 指buff添加到的对象，下同
	onHolderAttackEnd = 8,
	onHolderBeHit = 9,
	onHolderFinallyBeHit = 10, 	-- 被攻击的最后那一下时 (区分多段的伤害) --todo

	onHolderKillTarget = 11, 	-- 击杀目标时，一般是配合技能使用的
	onHolderDeath = 12,			-- 常规死亡, 真死假死都会触发的
	onHolderRealDeath = 13, 	-- 真死亡时
	onHolderBeforeBeHit = 14, 	-- holder被攻击前  --todo
	onHolderKillHandleChooseTarget = 15,	-- 击杀技能当前手动选择的目标

	onHolderMateKilledBySkill = 16,	-- 自己的阵营伙伴被技能击杀时, 自己触发buff效果 (简写类型, 自己和伙伴都在技能的这次攻击之中)
	onHolderAfterBeHit = 17,	--holder被攻击后 -- todo

	onHolderHpChange = 18,	--holder的hp变动

	onBuffOverNormal = 19,	--buff生命周期自然结束
	onBuffOverDispel = 20,  --buff结束 驱散
	onBuffOverlay = 21,		--buff结束 叠加/覆盖
	onBuffControlEnd = 22,	--冰冻被打爆 睡眠被打醒

	onHolderCounterAttack = 23,  --反击节点

	onHolderToAttack = 24, -- 选择完技能点击目标时触发

	onHolderBeForeSkillSpellTo = 25, -- 确定能释放技能

	onHolderReborn = 26, -- 复活后触发

	onHolderHpAdd = 27,	--holder的hp增加

	onBuffTrigger = 28, --特殊buff触发的节点 免死,锁血,复活,转移,复制,驱散

	onBuffBeAdd = 29, --buff 被添加事件

	onHolderAfterRefreshTargets = 30, -- 攻击目标前 刷新目标后

	onHolderFakeDeath = 31,  -- 触发假死的时候

	onBattleTurnStart = 32,  -- 每个小回合开始，在5之前

	onHolderShieldBreak = 33,   -- 护盾破裂节点

	onHolderMp1Change = 34,	--holder的mp1变动

	onHolderBackStage = 35, --holder从场外被召唤回场内

	onHolderAfterHit = 36, --holder攻击后

	onHolderMakeTargetRealDeath = 37, -- holder通过任意伤害让target致死

	onHolderAfterEnter = 38, -- 召唤、变身、正常入场都能触发 （全部入场后）

	onHolderLethal = 39, -- 受到致死攻击且没有致死保护

	onHolderCalcDamageProb = 40, -- holder预计算damageProcess的damageHit和strikeBlock

	onHolderShieldChange = 41, -- holder的护盾被攻击发生变化

	onBattleTurnEnd = 42, -- 每个小回合结束，在6之后

	onChargeBeInterrupted = 43, -- 蓄力被打断

	onHolderMp1Overflow = 44, --holder的mp1溢出
}

-- 被控制类型的状态,不能进行攻击
-- battle.BeControlled = {
-- 	"beStunned",
-- 	"beInSleeping",
-- 	"freezeHp",
-- 	"isLeave"
-- }

-- 伤害主要来源
battle.DamageFrom = {
    buff = 1, -- 来自buff
    rebound = 2, -- 来自反伤
    skill = 3, -- 来自技能
}

-- 伤害来源拓展，依赖伤害主要来源
battle.DamageFromExtra = {
	allocate = 201, --伤害分摊
	link = 202, --伤害链接
	protect = 203, --保护
}

-- 回血来源
battle.ResumeHpFrom = {
    buff = 101, -- 来自buff
    skill = 102, -- 来自技能
    suckblood = 103, -- 来自吸血
}

-- buff extraTargets 配置表
battle.BuffExtraTargetType = {
    holder = 1, -- holder
    caster = 2, -- caster
    holderForceNoDeathRandom = 3, -- holder阵容的随机一个目标（个数由策划配置）
    surroundHolderNoDath = 4, -- holder周围，值得是受到buff影响的目标周围
    holderForce = 5, -- holder阵容的全体目标
    lastProcessTargets = 6, -- 对caster而言的技能前一段的目标类型（或者是input和process的组合）
    holderBeAttackFrom = 7, -- 当前攻击holder的目标
    skillAllDamageTargets = 8, -- 当前holder释放技能中攻击伤害的目标
    casterForceNoDeathRandom = 9, -- caster阵容的随机一个目标（个数由策划配置）
    surroundCasterNoDath = 10, -- caster周围，值得是受到buff影响的目标周围
    casterForce = 11, -- caster阵容的全体目标
    overLayBuffCaster = 12, -- 存储可叠加buff的caster 作为castBuff中buff的holder
    holderEnemyForce = 13, -- holder的敌对全体
	casterEnemyForce = 14, -- caster的敌对全体
	skillOwner = 15,     -- 技能持有对象 适用节点:7,14,17,10,8,15,11,16
	killHolder = 16,     -- 杀死holder的目标
	casterEnemyForceRandom = 17,	--caster敌对阵容随机目标
	segProcessTargets = 18,          -- onHolderAfterRefreshTargets
	surroundHolderKill = 19,		-- holder杀死目标周围
	triggerObject = 20, -- 场地buff 触发28节点的单位
}

-- copyOrTransferBuff 特殊目标类型 注意不要和BuffExtraTargetType重复
battle.copyOrTransferSpecType = {
	eachCaster = 100,  -- 每个buff的caster
}

--UI计时器tag
battle.UITag = {
	passCD = 1,
	pvpOpening = 2,
}

--伤害类型 物理/特殊/真伤
battle.SkillDamageType = {
	Physical = 0,
	Special = 1,
	True = 2
}

-- 反击模式
battle.CounterAttackMode = {
	onlyAttack = 1,
	smallSkill = 2,
	bigSkill = 3
}

-- 数值类型
battle.ValueType = {
	normal = 1, -- 正常
	overFlow = 2, -- 溢出
	valid = 3, -- 有效
}

-- 伤害过程段
battle.DamageProcess = {
	"damageHit",
	"nature",
	"damageAdd",
	"damageDeepen",
	"dmgDelta",
	"natureDelta",
	"gateDelta",
	"reduce",
	"strikeBlock",
	-- "block",
	"extraAdd",
	"fatal",
	"behead",
	"damageByHpRate",
	"finalSkillAdd",
	"ultimateAdd",
	"skillPower",
	"buffAdd",
	"randFix",
	"limit",
	"calcInternalDamageFinish",
	"ignoreRoundDamage",
	-- "skillMiss",
	-- "stealth",
	-- "leave",
	"immuneAllDamage",
	"immuneDamage",
	"immunePhysicalDamage",
	"immuneSpecialDamage",
	"keepHpUnChanged",
	"groupShield",
	"delayDamage",
	"damageAllocate",
	"damageLink",
	"protection",
	"shield",
	"freeze",
	"finalRate",
	"lockHp",
	"rebound",
	"suckblood",
	"result"
}

-- 预计算概率过程段
battle.DamageProbProcessId = 18

battle.ExtraAttackMode = {
	counter = 1,
	combo = 2,
	syncAttack = 3,
	inviteAttack = 4,
	assistAttack = 5,
}

battle.ExtraBattleRoundMode = {
	normal = 0, -- 默认类型
	reset = 1,  -- 重置额外回合
	atOnce = 2, -- 立即额外回合
	gemini = 3, -- 双子额外回合
}

battle.JumpAllDamageProcessId = 9

battle.BuffOverType = {
	clean = 0, -- 清理结束
	normal = 1, -- 生命周期结束
	dispel = 2, -- 驱散
	overlay = 3, -- 叠加/覆盖
}

battle.SkillInterruptType = {
	charge = 1, -- 蓄力
}

battle.OverlaySpecBuff = {
	syncAttack = "syncAttack", --协战
	inviteAttack = "inviteAttack", --邀战
	lockHp = "lockHp", --锁血
	keepHp = "keepHpUnChanged", --免死
	reborn = "reborn", -- 复活
	sleepy = "sleepy", -- 睡眠
	transformAttrBuff = "transformAttrBuff", -- 变换属性buff
	delayDamage = "delayDamage", --延迟伤害
	freeze = "freeze", --冰冻
	counterAttack = "counterAttack", --反击
	extraSkillWeightValueFix = "extraSkillWeightValueFix", -- 额外技能权重修正
	atOnceBattleRound = "atOnceBattleRound", -- 立刻获得额外回合
	sneer = "sneer", -- 嘲讽
	opGameData = "opGameData",

	immuneDamage = "immuneDamage", -- 免伤
	lethalProtect = "lethalProtect", -- 致死保护
	healTodamage = "healTodamage", -- 治疗转化为伤害
	changeBuffLifeRound = "changeBuffLifeRound", -- 修改buff生命周期

	changeObjNature = "changeObjNature", -- 修改精灵自然属性
	changeSkillNature = "changeSkillNature", -- 修改技能自然属性
	allocate = "damageAllocate", -- 伤害分摊
	protection = "protection", -- 保护
	prophet = "prophet", -- 先知打断出手
}

battle.ObjectState = {
	none = 1,
	normal = 2,
	dead = 3,
	realDead = 4,
	reborn = 5, -- 处于dead状态
}

battle.ObjectLogicState = {
	cantBeSelect = 1,  -- 无法被选中 技能指示器 getTargetsHint
	cantAttack = 2, -- 无法攻击 isSelfControled
	cantBeAddBuff = 3, -- 无法添加buff object:checkBuffCanBeAdd
	cantBeAttack = 4, -- 无法被攻击 技能伤害段
	cantUseSkill = 5, -- 无法使用技能 spellTo 不生效
}

battle.ExRecordEvent = {
	spellNormalSkill = 1, -- 施放普通攻击 obj
	spellSmallSkill = 2, -- 施放小技能 obj
	spellBigSkill = 3, -- 施放大招 obj
	dispelSuccessCount = 4, -- 驱散成功次数 obj
	copySucessCount = 5, -- 复制buff成功次数 obj
	transferSucessCount = 6, -- 转移buff成功次数 obj
	rebornRound = 7, -- 复活回合数 obj
	lostHp = 8, -- 损失的血量 obj
	comboProcessTotalNum = 9, -- 多段攻击成功次数 obj
	sputtering = 10, -- 溅射伤害比例 obj
	penetrate = 11, -- 穿刺伤害比例 obj
	roundSyncAttackTime = 12, -- 大回合协战出手次数
	unitsDamage = 13, -- 每个角色造成的伤害
	campDamage = 14,  -- 对应阵营的总伤害
	totalHp = 15,  -- 每一波的怪物总血量
	killNumber = 16,  -- 击败怪物数量
	score = 17, -- 得到的分数
	roundAttackTime = 18, --单位全场出手次数
	momentBuffDamage = 19, -- buff每次触发的伤害
	skillEffectLimit = 20, -- 技能最多生效次数
	spellSkillTotal = 21,  -- 释放技能总次数 obj
	chargeStateBeforeWave = 22, -- 在换波前是否处于蓄力状态 obj
	possessTarget = 23, -- 附身目标 obj
	extraBattleRound = 24, -- 额外战斗回合 obj
	protectTarget = 25, -- 保护自己的目标 obj

	lockHpDamage = 1000, -- 记录锁血期间的血量 buff
	lockHpTriggerTime = 1001, -- 锁血触发次数 buff
	dispelSuccess = 1002, -- 驱散成功 buff
	dispelBuffCount = 1003, -- 驱散数量 buff
	copyOrTransferBuff = 1004, -- 复制转移buff buff
	sucessCount = 1005, -- 单次转移或复制成功的个数 buff
	transferState = 1006, -- 当前转移buff的状态 buff
	copyState = 1007, -- 当前复制buff的状态 buff
	effectHpMax = 1008, -- 修改的血上限 buff
	effectHp = 1009, -- 修改的当前血量 buff
	lockHpTriggerState = 1010, -- 锁血触发状态 buff
	keepHpUnChangedTriggerState = 1011, -- 免死触发状态 buff
}

battle.TimeIntervalType = {
	wave = 1, -- 波
	round = 2, -- 大回合
	battleRound = 3, -- 战斗回合
}

battle.TimeIntervalType = {
	wave = 1, -- 波
	round = 2, -- 大回合
	battleRound = 3, -- 战斗回合
}

-- 筛选单位类型
battle.FilterObjectType = {
	noAlreadyDead = 1,  -- 没有死亡 包括假死
	noRealDeath = 2,    -- 没有真正死亡 不包括假死
	noBeSelectHint = 3, -- 无法被技能指示器选中
	-- noBeAttack = 4,     -- 无法被攻击
	excludeEnvObj = 4,  -- env为object时剔除使用


	-- 过滤buff组合
	excludeObjLevel1 = 100,  -- 只过滤击飞 强控制？
}

-- 合体技类型判断
battle.CombineSkillType = {
	smallRoundStart = 1,
	smallRoundEnd = 2,
	bigRoundStart = 3,
	spellBigSkill = 4
}

-- 效果触发控制类型
battle.EffectPowerType = {
	killAddMp1 = "killAddMp1",
	triggerPoint = "triggerPoint",
	passiveSkill = "passiveSkill"
}

battle.BuffOverlayType = {
	Normal 				= 0, -- 无法叠加
	Cover 				= 1, -- 覆盖
	Overlay 			= 2, -- 叠加 刷新生命周期 层数满了后继续刷新生命周期
	CoverValue 			= 3, -- 数值大的覆盖
	CoverLifeRound 		= 4, -- 生命周期长的覆盖
	IndeLifeRound       = 5, -- 独立生命周期
	Coexist 			= 6, -- 同id共存
	OverlayDrop 		= 7, -- 叠加到上限不刷新生命周期 丢弃
	CoexistLifeRound 	= 8, -- 刷新生命周期
}

battle.BuffEffectOverlayType = {
	Normal 				= 0, -- 同effect 超出上限时删除当前buff
	PopTop 				= 1, -- 同effect 超出上限时删除头部
	SameMode			= 2, -- 相同mode 超出上限时删除
}

battle.BuffEffectAniType = {
	Normal               = 0, -- 默认类型 直接选择第一个
	OverlayCount         = 1, -- 层数
}

battle.SneerType = {
	Normal = 0, -- 默认类型 普通嘲讽
	Duel = 1, -- 决斗类型
}

battle.SneerArgType = {
	NoSpread = 0, -- 完全不波及
	DamageSpread = 1, -- 伤害波及
	BuffSpread = 2, -- buff波及
	AllSpread = 3, -- 完全波及
}

battle.lifeRoundType = {
	battleTurn = 1,    -- 小回合时
	round = 2,         -- 大回合时
	pureBattleTurn = 3 -- 不受额外回合影响的小回合
}

battle.ObjectType = {
	Normal = 0,
	Summon = 1,
	SummonFollow = 2,
}

-- 策划配置字符串转战斗通用方法 类似术语配置
-- iter后缀 适用exitInArray
battle.CsvStrToMap = {
	checkRealDeathIter = function(obj) return obj:isRealDeath() end
}

battle.TriggerEnvType = {
	PassiveSkill = 1
}

battle.GuideTriggerPoint = {
	Start = 0,	-- 入场 单位还没创建
	Wave = 1000,	-- 波数 第一波是1001 预留(1000+最大波数)

	Fail = 97, -- 失败
	Win = 98, -- 胜利 失败同级
	End = 99, -- 结束 失败胜利后
}


battle.GateAntiMode = {
	Normal = 0, -- 没有反作弊
	Operate = 1, -- 记录操作
}

battle.SpriteType = {
	Normal = 0,
	Possess = 1,
	Follower = 2,
}

