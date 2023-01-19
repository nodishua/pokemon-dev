--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- UI相关全局变量
--

local ui = {}
globals.ui = ui

ui.FONT_PATH = "font/youmi.ttf"
ui.FONT_SIZE = 40

ui.DEFAULT_OUTLINE_SIZE = 4
-- 拖动阈值设置
ui.TOUCH_MOVED_THRESHOLD = 10
-- 长按取消的阈值
ui.TOUCH_MOVE_CANCAE_THRESHOLD = 35

-- 常用颜色
ui.COLORS = {
	WHITE = cc.c4b(255, 255, 255, 255),				-- #FFFFFF
	BLACK = cc.c4b(0, 0, 0, 255),					-- #000000
	RED = cc.c4b(255, 0, 0, 255),					-- #FF0000
	GREEN = cc.c4b(0, 255, 0, 255),					-- #00FF00
	BLUE = cc.c4b(0, 0, 255, 255),					-- #0000FF
	YELLOW = cc.c4b(255, 255, 0, 255),				-- #FFFF00
	NORMAL = {
		DEFAULT = cc.c4b(91, 84, 91, 255),			-- #5B545B
		WHITE = cc.c4b(255, 252, 237, 255),			-- #FFFCED
		RED = cc.c4b(241, 59, 84, 255),				-- #F13B54
		GRAY = cc.c4b(183, 176, 158, 255),			-- #B7B09E
		LIGHT_GREEN = cc.c4b(174, 233, 126, 255),	-- #AEE97E
		FRIEND_GREEN = cc.c4b(96, 196, 86, 255),	-- #60C456
		ALERT_YELLOW = cc.c4b(236, 183, 42, 255),	-- #ECB72A
		ALERT_ORANGE = cc.c4b(247, 107, 69, 255),	-- #F76B45
		ALERT_GREEN = cc.c4b(174, 233, 126, 255),	-- #AEE97E
		PINK = cc.c4b(228, 82, 77, 255),            -- #E4524D
		GREEN = cc.c4b(136, 200, 85, 255),			-- #88C855
		CLARET = cc.c4b(139, 34, 16, 255),			-- #8B2210
		WARM_YELLOW = cc.c4b(241, 188, 76, 255),	-- #F1BC4C
		DULL_YELLOW = cc.c4b(175, 101, 14, 255),	-- #AF650E
		BLACK = cc.c4b(59, 51, 59, 255),			-- #3B333B
		BROWN = cc.c4b(86, 8, 2, 255),				-- #560802

	},
	GLOW = {
		WHITE = cc.c4b(255, 255, 255, 128),			-- #FFFFFF
		RED = cc.c4b(146, 12, 47, 153),				-- #920C1B
		YELLOW = cc.c4b(255, 234, 0, 255)			-- #ffea00
	},
	DISABLED = {
		WHITE = cc.c4b(222, 218, 208, 255),			-- #DEDAD1
		GRAY = cc.c4b(183, 176, 158, 255),			-- #B7B09E
		TITLE_GRAY = cc.c4b(159, 146, 141, 255),	-- #9F928D
		SUBTITLE_GRAY = cc.c4b(172, 172, 169, 255), -- #ACACA9
		YELLOW = cc.c4b(239, 95, 28, 255),			-- #EF5F1C
	},
	OUTLINE = {
		DEFAULT = cc.c4b(91, 84, 91, 255),			-- #5B545B
		RED = cc.c4b(124, 44, 52, 255),				-- #7C2C34
		GREEN = cc.c4b(77, 94, 67, 255),			-- #4D5E43
		WHITE = cc.c4b(255, 252, 237, 255),			-- #FFFCED
		BLUE = cc.c4b(28, 114, 154, 255),			-- #1C729A
		PURPLE = cc.c4b(126, 58, 222, 255),			-- #7E37DE
		ATROVIRENS = cc.c4b(19, 140, 104, 255),		-- #138C68
		ORANGE = cc.c4b(240, 75, 52, 255),			-- #CC4B34
	},
	-- 统一品质颜色
	QUALITY = {
		[1] = cc.c4b(153, 153, 153, 255),			-- #999999
		[2] = cc.c4b(92, 153, 112, 255),			-- #5C9970
		[3] = cc.c4b(61, 138, 153, 255),			-- #3D8A99
		[4] = cc.c4b(138, 92, 153, 255),			-- #8A5C99
		[5] = cc.c4b(230, 153, 0, 255),				-- #E69900
		[6] = cc.c4b(230, 116, 34, 255),			-- #E67422
		[7] = cc.c4b(241, 59, 84, 255),				-- #F13B54
	},
	-- 统一品质描边，名称
	QUALITY_OUTLINE = {
		[1] = cc.c4b(91, 84, 91, 255),				-- #5B545B
		[2] = cc.c4b(102, 128, 110, 255),			-- #66806E
		[3] = cc.c4b(76, 115, 153, 255),			-- #4C7399
		[4] = cc.c4b(115, 76, 128, 255),			-- #734C80
		[5] = cc.c4b(178, 119, 0, 255),				-- #B27700
		[6] = cc.c4b(178, 74, 45, 255),				-- #B24A2D
		[7] = cc.c4b(218, 60, 79, 255),				-- #DA3C4F
	},
	-- 暗底上品质颜色
	QUALITY_DARK = {
		[1] = cc.c4b(222, 218, 209, 255),			-- #DEDAD1
		[2] = cc.c4b(145, 225, 147, 255),			-- #91E1B1
		[3] = cc.c4b(139, 175, 223, 255),			-- #8BAFDF
		[4] = cc.c4b(203, 142, 222, 255),			-- #CB8EDE
		[5] = cc.c4b(236, 183, 42, 255),			-- #ECB72A
		[6] = cc.c4b(243, 137, 93, 255),			-- #F3895B
		[7] = cc.c4b(238, 115, 143, 255),			-- #EE738F
	},
	ATTR = {
		[game.NATURE_ENUM_TABLE.normal] = cc.c4b(170, 149, 137, 255),		-- #aa9589
		[game.NATURE_ENUM_TABLE.fire] = cc.c4b(233, 54, 68, 255),			-- #e93644
		[game.NATURE_ENUM_TABLE.water] = cc.c4b(125, 145, 243, 255),		-- #7d91f3
		[game.NATURE_ENUM_TABLE.grass] = cc.c4b(62, 194, 65, 255),			-- #3ec241
		[game.NATURE_ENUM_TABLE.electricity] = cc.c4b(255, 198, 0, 255),	-- #ffc600
		[game.NATURE_ENUM_TABLE.ice] = cc.c4b(73, 214, 236, 255),			-- #49d6ec
		[game.NATURE_ENUM_TABLE.combat] = cc.c4b(248, 115, 75, 255),		-- #f8734b
		[game.NATURE_ENUM_TABLE.poison] = cc.c4b(141, 93, 206, 255),		-- #8d5dce
		[game.NATURE_ENUM_TABLE.ground] = cc.c4b(133, 130, 96, 255),		-- #858260
		[game.NATURE_ENUM_TABLE.fly] = cc.c4b(76, 160, 243, 255),			-- #4ca0f3
		[game.NATURE_ENUM_TABLE.super] = cc.c4b(219, 91, 187, 255),			-- #db5bbb
		[game.NATURE_ENUM_TABLE.worm] = cc.c4b(195, 196, 14, 255),			-- #c3c40e
		[game.NATURE_ENUM_TABLE.rock] = cc.c4b(171, 136, 79, 255),			-- #ab884f
		[game.NATURE_ENUM_TABLE.ghost] = cc.c4b(74, 84, 93, 255),			-- #4a545d
		[game.NATURE_ENUM_TABLE.dragon] = cc.c4b(137, 111, 230, 255),		-- #896fe6
		[game.NATURE_ENUM_TABLE.evil] = cc.c4b(151, 116, 106, 255),			-- #97746a
		[game.NATURE_ENUM_TABLE.steel] = cc.c4b(111, 145, 156, 255),		-- #6f919c
		[game.NATURE_ENUM_TABLE.fairy] = cc.c4b(249, 104, 151, 255),		-- #f96897
	}
}

ui.ATTRCOLOR ={
	normal = "#C0xFFC6B6AC#",
	fire = "#C0xFFF76A6B#",
	water = "#C0xFF8DB9FC#",
	grass = "#C0xFF87DC87#",
	electricity = "#C0xFFE5CC3B#",
	ice = "#C0xFF6BDBEC#",
	combat = "#C0xFFF98562#",
	poison = "#C0xFFAE7EDE#",
	ground = "#C0xFFB8B7B1#",
	fly = "#C0xFF85CEFC#",
	super = "#C0xFFE76FD7#",
	worm = "#C0xFFC4D138#",
	rock = "#C0xFFBE9E6A#",
	ghost = "#C0xFF788797#",
	dragon = "#C0xFFABA2FF#",
	evil = "#C0xFFAF8B85#",
	steel = "#C0xFFA5B8BE#",
	fairy = "#C0xFFF96494#",
}

ui.QUALITYCOLOR = {
	"#C0x999999#",
	"#C0x5C9970#",
	"#C0x3D8A99#",
	"#C0x8A5C99#",
	"#C0xE69900#",
	"#C0xE67422#",
	"#C0xF13B54#",
}

ui.QUALITY_DARK_COLOR = {
	"#C0x999999#",
	"#C0x91E1B1#",
	"#C0x8BAFDF#",
	"#C0xCB8EDE#",
	"#C0xECB72A#",
	"#C0xF3895B#",
	"#C0xEE738F#",
}

ui.QUALITY_OUTLINE_COLOR = {
	"#C0x5B545B#",
	"#C0x66806E#",
	"#C0x4C7399#",
	"#C0x734C80#",
	"#C0xB27700#",
	"#C0xB24A2D#",
	"#C0xDA3C4F#",
}

ui.QUALITY_COLOR_SINGLE_TEXT = {"white", "green", "blue", "purple", "orange", "red", "rose"}
ui.QUALITY_COLOR_TEXT = {"whiteText", "greenText", "blueText", "purpleText", "orangeText", "redText", "roseText"}

-- 属性标识
ui.ATTR_LOGO = {
	hp = "common/icon/attribute/icon_life.png", --生命
	damage = "common/icon/attribute/icon_attack.png", -- 物攻
	specialDamage = "common/icon/attribute/icon_spattack.png", -- 特攻
	defence = "common/icon/attribute/icon_defense.png", -- 物防
	specialDefence = "common/icon/attribute/icon_spdefense.png", -- 特防
	speed = "common/icon/attribute/icon_speed.png", -- 速度
}

-- 卡牌属性
ui.ATTR_ICON = {}
ui.SKILL_ICON = {}
ui.SKILL_TEXT_ICON = {}
for i, v in ipairs(game.NATURE_TABLE) do
	ui.ATTR_ICON[i] = string.format("common/icon/attr/icon_%s.png", v)
	ui.SKILL_ICON[i] = string.format("common/icon/skill/icon_%s.png", v)
	ui.SKILL_TEXT_ICON[i] = string.format("common/icon/skill_text/icon_%s.png", v)
end
ui.ATTR_MAX = #ui.ATTR_ICON + 1 -- 包含特殊全部

-- 稀有度
ui.RARITY_ICON = {}
for i = 0, 5 do
	ui.RARITY_ICON[i] = string.format("common/icon/icon_rarity%d.png", i+1)
end
ui.RARITY_LAST_VAL = table.maxn(ui.RARITY_ICON) + 1 -- 包含特殊全部

ui.RARITY_TEXT = {
	[0] = "C",
	[1] = "B",
	[2] = "A",
	[3] = "S",
	[4] = "S+",
	[5] = "SS",
}

-- 稀有度筛选条件
-- 固定只显示 B ~ S+, 后续有扩张可以修改
ui.RARITY_DATAS = {}
for i = 1, 5 do
	table.insert(ui.RARITY_DATAS, {rarity = i})
end

-- 公共数值图标
ui.COMMON_ICON = {
	gold = "common/icon/icon_gold.png",
	rmb = "common/icon/icon_diamond.png",
	stamina = "common/icon/icon_stamina.png",
	coin1 = "common/icon/icon_ryb.png",
	coin2 = "common/icon/icon_ytjj.png",
	coin3 = "common/icon/icon_ghb.png",
	coin4 = "common/icon/icon_jxlj.png",
	coin5 = "common/icon/icon_frgitm.png",
	coin6 = "common/icon/icon_sydhdb1.png",
	coin7 = "common/icon/icon_sydhdb2.png",
	coin8 = "common/icon/icon_kfsydhdb1.png",
	coin9 = "common/icon/icon_kfsydhdb2.png",
	coin10 = "common/icon/icon_ghzb1.png",
	coin11 = "common/icon/icon_ghzb2.png",
	overflow_exp = "common/icon/icon_jyb.png", --经验溢出不是货币，他目前只在购买时的二次弹框上使用
}

-- 品质底图和框
ui.QUALITY_BOX = {}
ui.QUALITY_FRAME = {}
for i = 1, game.QUALITY_MAX do
	ui.QUALITY_BOX[i] = string.format("common/icon/panel_icon_%d.png", i)
	ui.QUALITY_FRAME[i] = string.format("common/icon/tag_digital%d.png", i)
end

ui.VIP_ICON = {}
for i = 1, 18 do
	ui.VIP_ICON[i] = string.format("common/icon/vip/icon_vip%d.png", i)
end

ui.RANK_ICON = {
	"city/rank/icon_jp.png",
	"city/rank/icon_yp.png",
	"city/rank/icon_tp.png",
	"common/icon/icon_four.png",
}

-- musicLens 音效时长，weekOpen是否削弱背景音乐
ui.SOUND_LIST = {
	["advance_suc.mp3"] = {musicLens = 2, weekOpen = true},
	["battle_false.mp3"] = {musicLens = 2, weekOpen = true},
	["card_gain.mp3"] = {musicLens = 4, weekOpen = true},
	["drawcard_one.mp3"] = {musicLens = 3, weekOpen = true},
	["drawcard_one2.mp3"] = {musicLens = 2, weekOpen = true},
	["drawcard_ten.mp3"] = {musicLens = 9, weekOpen = true},
	["drawcard_ten2.mp3"] = {musicLens = 2, weekOpen = true},
	["evolution.mp3"] = {musicLens = 13, weekOpen = true},
	["gate_win.mp3"] = {musicLens = 2, weekOpen = true},
	["item_gain.mp3"] = {musicLens = 2, weekOpen = true},
	["pve_win.mp3"] = {musicLens = 4, weekOpen = true},
	["pvp_win.mp3"] = {musicLens = 3, weekOpen = true},
	["qiangdilaixi.mp3"] = {musicLens = 2, weekOpen = true},
	["role_levelup.mp3"] = {musicLens = 3, weekOpen = true},
	["golden.mp3"] = {musicLens = 3, weekOpen = false}, 			-- 聚宝成功后金币散落
	["refinement.mp3"] = {musicLens = 3, weekOpen = false}, 		-- 个体值成功洗炼
	["star.mp3"] = {musicLens = 3, weekOpen = false}, 				-- 潜力值成功提升
	["formation.mp3"] = {musicLens = 3, weekOpen = false}, 		-- 成功上阵
	["equip.mp3"] = {musicLens = 3, weekOpen = false}, 			-- 携带道具成功装备
	["click.mp3"] = {musicLens = 3, weekOpen = false}, 			-- 通用一级按钮点击音效
	["circle.mp3"] = {musicLens = 3, weekOpen = false}, 			-- 饰品强化
	["flop.mp3"] = {musicLens = 3, weekOpen = true},				-- 竞技场挑战成功奖励翻牌动画
	["zaixianlibao.mp3"] = {musicLens = 5, weekOpen = true},
	["gem_draw_1.mp3"] = {musicLens = 3, weekOpen = true},
	["gem_diamond_10.mp3"] = {musicLens = 3, weekOpen = true},
	["gem_gold_10.mp3"] = {musicLens = 3, weekOpen = true},
}

ui.TOUCH_SOUND_LIST = {
	"click_1.mp3",
	"click_2.mp3",
}

-- 预加载音效
ui.PRELOAD_EFFECT_LIST = {
	"advance_suc.mp3",
	"item_gain.mp3",
	"iconpopup.mp3",
	"golden.mp3",
	"card_gain.mp3",
	"role_levelup.mp3",
	"popupopen.mp3",
	"popupclose.mp3",
	"click_1.mp3",
	"click_2.mp3",
	"newbie_finish.mp3",
	"drawcard_one.mp3",
	"drawcard_one2.mp3",
	"drawcard_ten.mp3",
	"drawcard_ten2.mp3",
	"zaixianlibao.mp3",
	"evolution.mp3",
	"gem_draw_1.mp3",
	"gem_gold_10.mp3",
	"gem_diamond_10.mp3",
}

ui.IGNORE_CLEAN_MAP = {
	["battle.view"] = true,
	["battle.loading"] = true,
}

ui.GEM_SUIT_ICON = {
	'city/card/gem/suit/icon_t1.png',
	'city/card/gem/suit/icon_t6.png',
	'city/card/gem/suit/icon_t9.png',
	'city/card/gem/suit/icon_t4.png',
	'city/card/gem/suit/icon_t7.png',
	'city/card/gem/suit/icon_t3.png',
	'city/card/gem/suit/icon_t2.png',
	'city/card/gem/suit/icon_t5.png',
	'city/card/gem/suit/icon_t8.png',
}

ui.CONSOLE_COLOR = {
	Dark_black 			= 0,
	Dark_Blue 			= 1,
	Dark_Green 			= 2,
	Dark_Blue_Green 	= 3,
	Dark_Red 			= 4,
	Dark_Purple 		= 5,
	Dark_Yellow 		= 6,
	Default 			= 7,
	Light_Black 		= 8,
	Light_Blue 			= 9,
	Light_Green 		= 10,
	Light_Blue_Green 	= 11,
	Light_Red 			= 12,
	Light_Purple 		= 13,
	Light_Yellow 		= 14,
	Light_White 		= 15,
}
ui.CARD_USING_TXTS = {
	battle = 'inCityTeam',
	unionTraining = 'inUnionTrain',
	arena = 'inArena',
	craft = 'inCraft',
	unionFight = 'inUnionCombat',
	cloneBattle = 'inCloneBattle',
	crossCraft = 'inCrossCraft',
	crossArena = 'inCrossArena',
	gymBadgeGuard = 'inGymBadgeGuard',
	gymLeader = "inGymEmbattle",
	crossGymLeader = "inCrossGymEmbattle",
	crossMine = "inCrossMine",
	crossunionfight = "inCrossUnionCombat"
}