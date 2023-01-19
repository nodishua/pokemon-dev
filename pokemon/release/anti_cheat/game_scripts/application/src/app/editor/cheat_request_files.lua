-- 分不同界面显示不同命令集

local default = {
	{key = "/exp", desc = "增加经验2000"},
	{key = "/role", desc = "增加经验最大"},
	{key = "/need_cards", desc = "获得大部分卡"},
	{key = "/card_max", desc = "卡牌状态到最大"},
	{key = "/pass_gates", desc = "全通关"},
	{key = "/pass_endless", desc = "无尽塔通关"},
	{key = "/talent_full", desc = "天赋全满"},
	{key = "/trainer_full", desc = "冒险执照全满"},
	{key = "/refresh_random_tower", desc = "试练塔刷新"},
	{key = "/reset_endless", desc = "重置无尽塔"},
	{key = "/union_contrib 10000", desc = "公会加10000经验"},
	{key = "/town clearall", desc = "清除家园数据"},
	{key = "/town rest", desc = "家园卡牌休息"},
}

local dailyAssistant = {
	{key = "/assistant reset", desc = "日常小助手重置次数"},
	{key = "/assistant clear", desc = "重默认选择值清空"},
	{key = "/ufb_refresh", desc = "公会副本重置"},
}

local craft = {
	{key = "/craft quick", desc = "快速石英"},
	{key = "/craft normal", desc = "正常石英"},
	{key = "/craft next", desc = "石英下一步"},
	{key = "/craft cancel", desc = "石英清除"},
	{key = "/craft stop", desc = "石英暂停"},
	{key = "/craft resume", desc = "石英恢复(5秒后下阶段)"},
}

local crossCraft = {
	{key = "/cross_craft quick", desc = "快速跨服石英"},
	{key = "/cross_craft normal", desc = "正常跨服石英"},
	{key = "/cross_craft next", desc = "跨服石英下一步"},
	{key = "/cross_craft cancel", desc = "跨服石英清除"},
	{key = "/cross_craft stop", desc = "跨服石英暂停"},
	{key = "/cross_craft resume", desc = "跨服石英恢复(5秒后下阶段)"},
}

local crossArena = {
	{key = "/cross_arena quick", desc = "跨服竞技场开始"},
	{key = "/cross_arena closed", desc = "跨服竞技场关闭"},
	-- {key = "/cross_arena round", desc = "跨服竞技场状态"},
	{key = "/cross_arena sevenAward", desc = "跨服竞技场7日奖励"},
	{key = "/cross_arena history", desc = "跨服竞技场清除历史"},
	{key = "/cross_arena swap 1", desc = "跨服竞技场交换排名(输入指定排名)"},
}

local crossMine = {
	{key = "/cross_mine start", desc = "开资源战"},
	{key = "/cross_mine close", desc = "关资源战"},
	{key = "/cross_mine test_create_boss 11 100", desc = "创建 boss"},
	{key = "/cross_mine clear_daily_record", desc = "清理玩法相关的每日计数"},
}

local unionFight = {
	{key = "/uf_sign", desc = "公会战报名"},
	{key = "/uf_sign_auto", desc = "公会战自动报名"},
	{key = "/uf_clear", desc = "公会战清空数据"},
	{key = "/uf_clear_sign", desc = "公会战清理自己的报名状态"},
	{key = "/uf_prepare 2", desc = "公会战周二赛"},
	{key = "/uf_prepare 5", desc = "公会战周五赛"},
	{key = "/uf_prepare 6", desc = "公会战周六赛"},
}

local fishing = {
	{key = "/fishing start", desc = "钓鱼大赛开始"},
	{key = "/fishing close", desc = "钓鱼大赛关闭"},
	{key = "/fishing_reset_daily", desc = "重置每日钓鱼次数和记录"},
	{key = "/fishing_reset", desc = "重置钓鱼 model 数据"},
	{key = "/fishing_level_up 1", desc = "升多少级"},
	{key = "/fishing_add low 1", desc = "增加那种升级经验，low，middle，high，target"},
	{key = "/fishing_fish 1 1", desc = "增加对应钓鱼图鉴的鱼的次数"},
}

local onlineFight = {
	{key = "/cross_online_fight battle limited", desc = "公平赛机器人战斗"},
	{key = "/cross_online_fight battle unlimited", desc = "无限制赛机器人战斗"},
	{key = "/cross_online_fight point limited 100", desc = "公平赛积分"},
	{key = "/cross_online_fight point unlimited 100", desc = "无限制赛积分"},
}

local gymChallenge = {
	{key = "/gym quick", desc = "道馆开始"},
	{key = "/gym closed", desc = "道馆关闭"},
	{key = "/gym round", desc = "道馆状态"},
	-- {key = "/gym gate", desc = "副本关卡"},
	-- {key = "/gym main", desc = "main请求"},
	{key = "/gym model", desc = "model请求"},
	-- {key = "/gym occupy", desc = "馆主占坑"},
	-- {key = "/gym cross_occupy", desc = "跨服占坑"},
	-- {key = "/gym start", desc = "馆主开始"},
	-- {key = "/gym end", desc = "馆主结束"},
	-- {key = "/gym fuben_start", desc = "副本开始"},
	-- {key = "/gym fuben_end", desc = "副本结束"},
	-- {key = "/gym gym_datas", desc = "道馆数据"},

	{key = "/gym pass 1", desc = "副本通关"},
	{key = "/gym occupy 1", desc = "占领道馆"},
	{key = "/gym jump 1", desc = "副本关卡下一关"},
	{key = "/gym reset", desc = "道馆重置"},
	{key = "/gym delCD", desc = "道馆去除CD"},
	{key = "/gym time", desc = "道馆次数清除"},
	{key = "/gym logs", desc = "道馆日志"},
	{key = "/gym clear", desc = "道馆清除日志"},
}

local gym_badge  = {
	{key = "/badge level 1 100", desc = " 指定csvID=1的勋章升100级"},
	{key = "/badge awake 1 10", desc = "觉醒指定csvID=1的勋章"},
	{key = "/badge full", desc = "等级、觉醒全满"},
	{key = "/badge clear", desc = "清除数据"},
}

local dispatch  = {
	{key = "/dispatch reset", desc = " 重置"},
	{key = "/dispatch quick", desc = " 完场当前派遣 （可点击完成派遣状态）"},
	{key = "/dispatch finish", desc = " 完场当前派遣 "},
}

local hunting = {
	{key = "/hunting next 1", desc = " 指定线路1 跳过这一关"},
	{key = "/hunting add_count 1 5", desc = "线路1挑战次数加5"},
	{key = "/hunting add_buff 1", desc = "远征加buff"},
	{key = "/hunting clear_buff 1", desc = "远征清buff"},
}

local summerChallenge = {
	{key = "/sc reset", desc = "重置"},
	{key = "/sc jump 1", desc = "重置到第1关"},
	{key = "/sc jump 2", desc = "跳到第2关"},
	{key = "/sc jump 3", desc = "跳到第3关"},
	{key = "/sc jump 4", desc = "跳到第4关"},
	{key = "/sc jump 5", desc = "跳到第5关"},
	{key = "/sc jump 6", desc = "跳到第6关"},
	{key = "/sc jump 7", desc = "跳到第7关"},
	{key = "/sc jump 8", desc = "跳到第8关"},
	{key = "/sc jump 9", desc = "跳到第9关"},
	{key = "/sc jump 10", desc = "跳到第10关"},
	{key = "/sc jump 11", desc = "全通关"},
}

local braveChallenge = {
	{key = "/nbc reset", desc = "普通重置数据"},
	{key = "/nbc pass 1", desc = "普通跳到指定关卡"},
	{key = "/nbc gate 90001", desc = "普通指定关卡ID"},
	{key = "/nbc add_badge 1001", desc = "普通添加指定勋章ID"},
	{key = "/nbc all_badge", desc = "普通添加全部勋章"},
	{key = "/nbc add_times 1", desc = "普通增加挑战次数"},
	{key = "/bc reset", desc = "重置数据"},
	{key = "/bc pass 1", desc = "跳到指定关卡"},
	{key = "/bc gate 90001", desc = "指定关卡ID"},
	{key = "/bc add_badge 1001", desc = "添加指定勋章ID"},
	{key = "/bc all_badge", desc = "添加全部勋章"},
	{key = "/bc add_times 1", desc = "增加挑战次数"},
}

local clone = {
	{key = "/clone_refresh", desc = "元素挑战重置"},
	{key = "/clone_clean_cd", desc = "元素挑战cd"},
	{key = "/clone_set_play 3",	desc = "设置当前玩家的play次数3(1:1~3)"},
	{key = "/clone_clear_vote",	desc = "清除自己的投票，重新投"},
	{key = "/clone_play_time",	desc = "玩家在房间内停留满3小时"},
}

local crossUnionFight = {
	{key = "/cross_union_fight prepare", desc = "准备"},
	{key = "/cross_union_fight next", desc = "下一状态"},
	{key = "/cross_union_fight stop", desc = "暂停"},
	{key = "/cross_union_fight resume", desc = "恢复"},
	{key = "/cross_union_fight cancel", desc = "清除"},
	{key = "/cross_union_fight quick", desc = "快速一期"},
	{key = "/cross_union_fight status", desc = "状态显示"},
	{key = "/cross_union_fight genTop5", desc = "生成top5"},
}

return {
	["default"] = default,
	["city.pvp.craft.view"] = craft,
	["city.pvp.craft.myschedule"] = craft,
	["city.pvp.cross_craft.view"] = crossCraft,
	["city.pvp.cross_arena.view"] = crossArena,
	["city.union.union_fight.view"] = unionFight,
	["city.adventure.fishing.sence_select"] = fishing,
	["city.pvp.online_fight.view"] = onlineFight,
	["city.adventure.gym_challenge.view"] = gymChallenge,
	["city.develop.gym_badge.view"] = gym_badge,
	["city.pvp.cross_mine.view"] = crossMine,
	["city.activity.dispatch.view"] = dispatch,
	["city.adventure.hunting.route"] = hunting,
	["city.daily_assistant.view"] = dailyAssistant,
	["city.activity.summer_challenge.view"] = summerChallenge,
	["city.activity.brave_challenge.view"] = braveChallenge,
	["city.adventure.clone_battle.view"] = clone,
	["city.adventure.clone_battle.room"] = clone,
	["city.union.cross_unionfight.view"] = crossUnionFight,
}