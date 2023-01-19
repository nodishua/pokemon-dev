--
-- @Data 2019-2-15 18:31:22
-- @desc 跳转
--

local unionTools = require "app.views.city.union.tools"

local jumpEasy = {}
globals.jumpEasy = jumpEasy

local SHOP_GET_PROTOL = game.SHOP_GET_PROTOL
local SHOP_UNLOCK_KEY = game.SHOP_UNLOCK_KEY

local function enterUnionOrChildView(cb, notRequest)
	local result = true
	local unionId = gGameModel.role:read("union_db_id")
	local url = "/game/union/get"
	local viewName = "city.union.view"
	local styles = {full = true}
	local requestParams = {}
	if not unionId then
		result = false
		url = "/game/union/list"
		viewName = "city.union.join.join"
		styles = {}
		requestParams = {0, 10}
	end
	local params = {result = result, unionId = unionId, viewName = viewName, cb = cb, styles = styles}
	-- 当有公会的时候才可以选择不进入主界面
	if notRequest and unionId then
		if cb then
			cb(result)
		end
		return
	end
	gGameApp:requestServer(url, function (tb)
		local params = {}
		if not unionId then
			table.insert(params, tb.view.unions)
		end
		if gGameUI:goBackInStackUI(viewName) then
			if cb then
				cb(result)
			end
			return
		end
		gGameUI:stackUI(viewName, nil, styles, unpack(params), tb.view)
		if cb then
			cb(result)
		end
	end, unpack(requestParams))
end

local jumpInfos = {
	shop = {
		-- 商店
		key = "shop",
		viewName = "city.shop",
		styles = {full = true},
		func = function(cb, param)
			param = param or 1
			local key = SHOP_UNLOCK_KEY[param].unlockKey
			if key and not dataEasy.isUnlock(key) then
				gGameUI:showTip(gLanguageCsv.shopNotOpen)
				return
			end
			if SHOP_GET_PROTOL[param] then
				gGameApp:requestServer(SHOP_GET_PROTOL[param], function(tb)
					cb()
				end)
			else
				cb()
			end
		end,
	},
	activity = {
		-- 活动界面
		key = "activity",
		viewName = "city.activity.view",
		styles = {full = true},
		func = function(cb, style)
			gGameApp:requestServer("/game/yy/active/get", function(tb)
				cb(style)
			end)
		end,
	},
	roleLogo = {
		-- 头像界面
		key = "roleLogo",
		viewName = "city.personal.role_logo",
	},
	figure = {
		-- 个人形象界面
		key = "figure",
		viewName = "city.personal.figure",
	},
	gainGold = {
		-- 点金界面
		key = "gainGold",
		viewName = "common.gain_gold",
	},
	recharge = {
		-- 充值界面
		key = "recharge",
		viewName = "city.recharge",
		styles = {full = true},
	},
	gainStamina = {
		-- 购买体力
		key = "gainStamina",
		viewName = "common.gain_stamina",
	},
	friend = {
		-- 好友界面
		key = "friend",
		viewName = "city.friend",
		func = function(cb)
			local friendView = require "app.views.city.friend"
			local showType, param = friendView.initFriendShowType()
			friendView.sendProtocol(showType, param, cb)
		end,
	},
	gate = {
		-- 关卡界面
		key = "gate",
		viewName = "city.gate.view",
		styles = {full = true},
	},
	cardBag = {
		-- 背包界面
		key = "cardBag",
		viewName = "city.card.bag",
		styles = {full = true},
	},
	strengthen = {
		-- 还有培养界面
		key = "strengthen",
		viewName = "city.card.strengthen",
		styles = {full = true},
	},
	handbook = {
		-- 图鉴界面
		key = "handbook",
		viewName = "city.handbook.view",
		styles = {full = true},
	},
	arena = {
		-- 竞技场
		key = "arena",
		viewName = "city.pvp.arena.view",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/pw/battle/get", function(tb)
				cb()
			end)
		end,
	},
	drawCard = {
		-- 抽卡
		key = "drawCard",
		viewName = "city.drawcard.view",
		styles = {full = true},
	},
	cloneBattle = {
		key = "cloneBattle",
		unlockKey = "cloneBattle",
		viewName = "city.adventure.clone_battle.base",
		styles = {full = true},
		func = function (cb)
			gGameApp:requestServer("/game/clone/get", function (tb)
				cb(tb.view)
			end)
		end,
	},
	-- 公会
	union = {
		key = "union",
		unlockKey = "union",
		func = function ()
			enterUnionOrChildView()
		end
	},
	redpacket = {
		key = "redpacket",
		func = function ()
			enterUnionOrChildView(function(result)
				if not result then
					-- union list view
					return
				end
				local canEnter = unionTools.canEnterBuilding("redpacket", true)
				if not canEnter then
					return
				end
				gGameApp:requestServer("/game/union/redpacket/info",function (tb)
					gGameUI:stackUI("city.union.redpack.view", nil, {full = true}, tb.view)
				end)
			end, true)
		end
	},
	contribute = {
		key = "contribute",
		func = function ()
			enterUnionOrChildView(function(result)
				if not result then
					-- union list view
					return
				end
				local canEnter = unionTools.canEnterBuilding("contribute")
				if not canEnter then
					return
				end
				gGameUI:stackUI("city.union.contrib.view")
			end)
		end
	},
	fuben = {
		key = "fuben",
		func = function ()
			enterUnionOrChildView(function(result)
				if not result then
					-- union list view
					return
				end
				local canEnter = unionTools.canEnterBuilding("fuben")
				if not canEnter then
					return
				end
				gGameApp:requestServer("/game/union/fuben/get",function (tb)
					gGameUI:stackUI("city.union.gate.view", nil, nil, tb.view)
				end)
			end)
		end
	},
	training = {
		key = "training",
		func = function ()
			enterUnionOrChildView(function(result)
				if not result then
					-- union list view
					return
				end
				local canEnter = unionTools.canEnterBuilding("training")
				if not canEnter then
					return
				end
				gGameApp:requestServer("/game/union/training/open",function (tb)
					gGameUI:stackUI("city.union.train.view", nil, nil, tb)
				end)
			end)
		end
	},
	unionQA = {
		key = "unionQA",
		func = function ()
			enterUnionOrChildView(function(result)
				if not result then
					-- union list view
					return
				end
				local canEnter = unionTools.canEnterBuilding("unionqa")
				if not canEnter then
					return
				end
				gGameApp:requestServer("/game/union/qa/main",function (tb)
					gGameUI:stackUI("city.union.answer.view", nil, {full = true}, tb)
				end)
			end, true)
		end
	},
	-- 限时pvp
	craft = {
		key = "craft",
		unlockKey = "craft",
		styles = {full = true},
		func = function()
			gGameApp:requestServer("/game/craft/battle/main", function(tb)
				-- 是否报名
				-- local isSignup = gGameModel.daily_record:read("craft_sign_up")
				local round = gGameModel.craft:read("round")
				local viewName = "city.pvp.craft.myschedule"
				if round == "over" or round == "closed" or round == "signup" then
					viewName = "city.pvp.craft.view"
				end
				if gGameUI:goBackInStackUI(viewName) then
					return
				end
				gGameUI:stackUI(viewName, nil, {full = true})
			end)
		end,
	},
	-- 任务
	task = {
		key = "task",
		viewName = "city.task",
		styles = {full = true},
	},
	-- 天赋
	talent = {
		key = "talent",
		unlockKey = "talent",
		viewName = "city.develop.talent.view",
		styles = {full = true},
	},
	-- 探险器
	explorer = {
		key = "explorer",
		unlockKey = "explorer",
		viewName = "city.develop.explorer.view",
		styles = {full = true},
	},
	-- 派遣任务
	dispatchTask = {
		key = "dispatchTask",
		unlockKey = "dispatchTask",
		viewName = "city.adventure.dispatch_task.view",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/dispatch/task/refresh", function (tb)
				cb()
			end, false)
		end,
	},
	-- 随机塔
	randomTower = {
		key = "randomTower",
		unlockKey = "randomTower",
		viewName = "city.adventure.random_tower.view",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/random_tower/prepare", function (tb)
				cb()
			end)
		end,
	},
	-- 无限塔
	endlessTower = {
		key = "endlessTower",
		unlockKey = "endlessTower",
		viewName = "city.adventure.endless_tower.view",
		styles = {full = true},
	},
	-- 每日副本
	activityGate = {
		key = "activityGate",
		unlockKey = "activityGate",
		viewName = "city.adventure.daily_activity.view",
		styles = {full = true},
		func = function(cb, _type)
			gGameApp:requestServer("/game/huodong/show", function(tb)
				if _type then
					cb(tb.view)
				else
					cb("", tb.view)
				end
			end)
		end,
	},
	-- 冒险执照
	trainer = {
		key = "trainer",
		viewName = "city.develop.trainer.view",
		styles = {full = true},
	},
	-- 携带道具
	heldItem = {
		key = "heldItem",
		viewName = "city.card.helditem.bag",
		func = function(cb)
			if not gGameUI:goBackInStackUI("city.card.strengthen") then
				gGameUI:stackUI("city.card.strengthen")
			end
			cb()
		end,
	},
	-- 好感度
	feel = {
		key = "feel",
		viewName = "city.card.feel.view",
		func = function(cb)
			if not gGameUI:goBackInStackUI("city.card.strengthen") then
				gGameUI:stackUI("city.card.strengthen")
			end
			cb()
		end,
	},
	-- 继承
	propertySwap = {
		key = "propertySwap",
		viewName = "city.card.property_swap.view",
		func = function(cb)
			if not gGameUI:goBackInStackUI("city.card.strengthen") then
				gGameUI:stackUI("city.card.strengthen")
			end
			cb()
		end,
	},
	explorerDraw = {
		key = "explorerDraw",
		unlockKey = "explorer",
		viewName = "city.develop.explorer.draw_item.view",
		styles = {full = true},
	},
	--公会战
	unionFight = {
		key = "unionFight",
		unlockKey = "unionFight",
		styles = {full = true},
		func = function()
			local canEnter = unionTools.canEnterBuilding("unionFight")
			if not canEnter then
				return
			end
			if not gGameUI:goBackInStackUI("city.union.union_fight.view") then
				gGameApp:requestServer("/game/union/fight/battle/main", function(tb)
					gGameUI:stackUI("city.union.union_fight.view", nil, {full = true})
				end)
			end
		end,
	},
	-- 跨服pvp（跨服石英大会）
	crossCraft = {
		key = "crossCraft",
		unlockKey = "crossCraft",
		styles = {full = true},
		func = function()
			gGameApp:requestServer("/game/cross/craft/battle/main", function(tb)
				local viewName = "city.pvp.cross_craft.view"
				if gGameUI:goBackInStackUI(viewName) then
					return
				end
				gGameUI:stackUI(viewName, nil, {full = true})
			end)
		end,
	},
	--捕捉
	capture = {
		key = "capture",
		unlockKey = "limitCapture",
		styles = {full = true},
		func = function()
			gGameUI:stackUI("city.capture.capture_limit", nil, nil)
		end,
	},
	--符石主界面
	gemTitle = {
		key = "gemTitle",
		unlockKey = "gem",
		styles = {full = true},
		func = function()
			gGameUI:stackUI("city.card.gem.view", nil, nil)
		end,
	},
	--符石抽取
	gemDraw  = {
		key = "gemDraw",
		unlockKey = "gem",
		styles = {full = true},
		func = function()
			gGameUI:stackUI("city.card.gem.draw")
		end,
	},

	--芯片抽取
	chipDraw  = {
		key = "chipDraw",
		unlockKey = "chip",
		styles = {full = true},
		func = function()
			gGameUI:stackUI("city.card.chip.draw")
		end,
	},
	--芯片背包
	chipBag  = {
		key = "chipBag",
		unlockKey = "chip",
		styles = {full = true},
		viewName = "city.card.chip.bag",
	},

	-- 跨服竞技场
	crossArena = {
		key = "crossArena",
		unlockKey = "crossArena",
		styles = {full = true},
		func = function()
			local cards = gGameModel.role:read("cards")
			if table.length(cards) < 2 then
				gGameUI:showTip(gLanguageCsv.crossArenaCardNotEnoughTip)
				return
			end
			gGameApp:requestServer("/game/cross/arena/battle/main", function(tb)
				local viewName = "city.pvp.cross_arena.view"
				if gGameUI:goBackInStackUI(viewName) then
					return
				end
				gGameUI:stackUI(viewName, nil, {full = true},tb.view)
			end)
		end,
	},
	-- 超进化
	cardMega = {
		key = "cardMega",
		unlockKey = "mega",
		viewName = "city.card.mega.view",
		styles = {full = true},
	},
	--	超级石转化
	megaStone = {
		key = "megaStone",
		unlockKey = "mega",
		viewName = "city.card.mega.conversion",
	},
	--	钥石转化
	keyStone = {
		key = "keyStone",
		unlockKey = "mega",
		viewName = "city.card.mega.conversion",
	},
	-- 钓鱼
	fishing = {
		key = "fishing",
		unlockKey = "fishing",
		styles = {full = true},
		func = function()
			gGameUI:stackUI("city.adventure.fishing.sence_select")
		end,
	},
	-- 狩猎地带
	hunting = {
		key = "hunting",
		unlockKey = "hunting",
		styles = {full = true},
		func = function()
			gGameApp:requestServer("/game/hunting/main", function(tb)
				gGameUI:stackUI("city.adventure.hunting.view")
			end)
		end,
	},
	-- 狩猎地带进阶路线
	specialHunting = {
		key = "specialHunting",
		unlockKey = "specialHunting",
		styles = {full = true},
		func = function()
			gGameApp:requestServer("/game/hunting/main", function(tb)
				gGameUI:stackUI("city.adventure.hunting.view")
			end)
		end,
	},

	-- 跨服竞技场
	onlineFight = {
		key = "onlineFight",
		unlockKey = "onlineFight",
		styles = {full = true},
		func = function()
			local cards = gGameModel.role:read("cards")
			if table.length(cards) < 12 then
				gGameUI:showTip(gLanguageCsv.onlineFightNotEnoughCards)
				return
			end
			-- 断线重连
			if gGameModel.role:read("in_cross_online_fight_battle") then
				gGameUI:showDialog({
					content = "#C0x5B545B#" .. gLanguageCsv.onlineFightReconnection,
					isRich = true,
					cb = function()
						dataEasy.onlineFightLoginServer()
					end,
					btnType = 2,
					clearFast = true,
				})
			else
				gGameApp:requestServer("/game/cross/online/main", function(tb)
					gGameUI:stackUI("city.pvp.online_fight.view", nil, {full = true})
				end)
			end
		end,
	},
	reunion = {
		key = "reunion",
		viewName = "city.activity.reunion.view",
		styles = {full = true},
		func = function (cb)
			local reunion = gGameModel.role:read("reunion")
			local reunionBindRoleId = gGameModel.reunion_record:read("bind_role_db_id")
			local roleID = ""
			if reunion.role_type == 1 then
				roleID = reunionBindRoleId or ""
			elseif reunion.role_type == 2 then
				roleID = reunion.info.role_id
			end
			if roleID ~= "" then
				gGameApp:requestServer("/game/role_info", function (tb)
					local info = tb.view
					local params = {info = info}
					if reunion.role_type == 2 then
						gGameApp:requestServer("/game/yy/reunion/record/get", function(tb)
								params = {info = info, reunionRecord = tb.view.reunion_record}
								if cb then
									cb(params)
								end
							end, roleID)
					else
						if cb then
							cb(params)
						end
					end
				end, roleID)
			else
				cb({})
			end
		end,
	},
	-- 道馆挑战
	gymChallenge = {
		key = "gymChallenge",
		unlockKey = "gym",
		styles = {full = true},
		func = function()
			gGameApp:requestServer("/game/gym/main", function(tb)
				local viewName = "city.adventure.gym_challenge.view"
				if gGameUI:goBackInStackUI(viewName) then
					return
				end
				gGameUI:stackUI(viewName, nil, {full = true})
			end)
		end,
	},
	-- 跨服资源战
	crossMine = {
		key = "crossMine",
		unlockKey = "crossMine",
		styles = {full = true},
		func = function()
			local cards = gGameModel.role:read("cards")
			if table.length(cards) < 3 then
				gGameUI:showTip(gLanguageCsv.crossMineCardNotEnoughTip)
				return
			end
			gGameApp:requestServer("/game/cross/mine/main", function(tb)
				local viewName = "city.pvp.cross_mine.view"
				if gGameUI:goBackInStackUI(viewName) then
					return
				end
				gGameUI:stackUI(viewName, nil, {full = true})
			end)
		end,
	},
	-- 跨服资源战
	crossMineBoss = {
		key = "crossMine",
		unlockKey = "crossMine",
		styles = {full = true},
		func = function()
			local cards = gGameModel.role:read("cards")
			if table.length(cards) < 3 then
				gGameUI:showTip(gLanguageCsv.crossMineCardNotEnoughTip)
				return
			end
			gGameApp:requestServer("/game/cross/mine/main", function(tb)
				local viewName = "city.pvp.cross_mine.view"
				if gGameUI:goBackInStackUI(viewName) then
					return
				end
				gGameUI:stackUI(viewName, nil, {full = true}, {isShowBoss = true})
			end)
		end,
	},
	-- 日常小助手
	dailyAssistant = {
		key = "dailyAssistant",
		unlockKey = "dailyAssistant",
		styles = {full = true},
		func = function()
			local dailyAssistantTools = require "app.views.city.daily_assistant.tools"
			local isOpen = dailyAssistantTools.getUnionFubenIsOpen()
			local function callBack()
				local viewName = "city.daily_assistant.view"
				if gGameUI:goBackInStackUI(viewName) then
					return
				end
				gGameUI:stackUI(viewName, nil, {full = true})
			end
			if isOpen then
				gGameApp:requestServer("/game/union/fuben/get",function (tb)
					callBack()
				end)
			else
				callBack()
			end

		end,
	},
	--	专属z觉醒碎片转换
	zawakeFragExclusive = {
		key = "zawakeFragExclusive",
		unlockKey = "zawake",
		viewName = "city.zawake.debris",
	},
	--	通用z觉醒碎片转换
	zawakeFragCurrency = {
		key = "zawakeFragCurrency",
		unlockKey = "zawake",
		viewName = "city.zawake.debris",
	},
	-- 宝可梦挑战（循环勇者挑战，开2周，休息1周）
	normalBraveChallenge = {
		key = "normalBraveChallenge",
		unlockKey = "normalBraveChallenge",
		viewName = "city.activity.brave_challenge.view",
		styles = {full = true},
		func = function(cb, params)
			gGameApp:requestServer("/game/brave_challenge/main", function(tb)
				cb(0, 2)
			end)
		end,
	},
}

function jumpEasy.isJumpUnlock(target, isShowTip, ...)
	target = target or ""
	local params = {...}
	local arr = string.split(target, "-")
	for i=2,#arr do
		local val = tonumber(arr[i]) or arr[i]
		table.insert(params, val)
	end
	local info = jumpInfos[arr[1]]
	local gateID = tonumber(arr[1])
	if gateID then
		local gateOpen = gGameModel.role:read("gate_open") -- 开放的关卡列表
		local mapOpen = gGameModel.role:read("map_open") -- 开放的章节ID key是下标没啥用
		local openType = {} -- 开放的类型（普通 精英）
		local worldMapCsv = csv.world_map
		local maxRoleLv = table.length(gRoleLevelCsv)
		for _,chapterId in ipairs(mapOpen) do
			if worldMapCsv[chapterId].openLevel <= maxRoleLv then
				local chapterType = worldMapCsv[chapterId].chapterType
				openType[chapterType] = true
			end
		end
		if not itertools.include(gateOpen, gateID) then
			local _type, charterId, id = dataEasy.getChapterInfoByGateID(gateID)
			-- 类型关卡没开放
			if not openType[_type] then
				if isShowTip then
					-- 精英关卡
					if _type == 2 then
						gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.heroGate))

					-- 噩梦关卡
					elseif _type == 3 then
						gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.nightmareGate))
					end
				end
				return false
			end
			-- 开放了类型关卡 但是关卡还没到目标关卡
			gateID = _type * 10000
			if id == 0 then
				gateID = gateID + charterId * 100
			end
		end
		info = jumpInfos.gate
		table.insert(params, gateID)
	end
	if info.key == "strengthen" then
		if params and params[1] == "ability" then
			local cardAbilityCan = dataEasy.getListenUnlock(gUnlockCsv.cardAbility)
			-- local cardAbilityShow = dataEasy.getListenShow(gUnlockCsv.cardAbility)
			if not cardAbilityCan:read() then
				gGameUI:showTip(dataEasy.getUnlockTip("cardAbility"))
				-- params[1] = "attribute"
				return false
			end
		elseif params and params[1] == "effortvalue" then
			local cardEffortCan = dataEasy.getListenUnlock(gUnlockCsv.cardEffort)
			-- local cardEffortShow = dataEasy.getListenShow(gUnlockCsv.cardEffort)
			if not cardEffortCan:read() then
				gGameUI:showTip(dataEasy.getUnlockTip("cardEffort"))
				-- params[1] = "attribute"
				return false
			end
		end
	end
	if not info then
		return false
	end
	if info.unlockKey then
		if not dataEasy.isUnlock(info.unlockKey) then
			if isShowTip then
				gGameUI:showTip(dataEasy.getUnlockTip(info.unlockKey))
			end
			return false
		end
		local state, day = dataEasy.judgeServerOpen(info.unlockKey)
		if not state and day then
			gGameUI:showTip(string.format(gLanguageCsv.unlockServerOpen, day))
			return
		end
	end


	return true, info, params
end

function jumpEasy.jumpTo(target, ...)
	if target == "gainWay" then
		gGameUI:stackUI("common.gain_way", nil, nil, ...)
		return
	end

	local isUnlock, info, params = jumpEasy.isJumpUnlock(target, true, ...)
	if not isUnlock then
		return
	end

	if info.viewName and gGameUI:goBackInStackUI(info.viewName) then
		return
	end
	local function jump(...)
		local nargs = select("#", ...)
		local t = {...}
		local len = #params
		for i=1, nargs do
			len = len + 1
			params[len] = t[i]
		end
		gGameUI:stackUI(info.viewName, nil, info.styles, unpack(params, 1, len))
	end
	if info.func then
		info.func(jump, unpack(params))
	else
		jump()
	end
end

return jumpEasy