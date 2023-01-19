-- @date:   2019-05-20
-- @desc:   冒险主界面

local DispatchTaskView = require("app.views.city.adventure.dispatch_task.view")

local RED_HINTS = {
	dispatchTask = {
		specialTag = "dispatchTask",
	},
	randomTower = {
		specialTag = "randomTower",
	},
	arena = {
		specialTag = "arenaAward",
	},
	crossArena = {
		specialTag = "crossArenaAward",
	},
	onlineFight = {
		specialTag = "onlineFightAward",
	},
	gym= {
		specialTag = "gymChallenge",
	},
	cloneBattle = {
		specialTag = "cloneBattle",
	},
	normalBraveChallenge = {
		specialTag = "braveChallengeAch",
		listenData = {
			sign = game.BRAVE_CHALLENGE_TYPE.common,
		},
	},
}

-- 代码上将活动id和双倍掉落活动type关联起来
-- key 是配表的unlockFeature
local ACTIVITY_DOUBLE_HUODONG = {
	endlessTower = {key = "endlessSaodang", res = "common/icon/double/label_sdsb.png"},
	randomTower = {key = "randomGold", res = "common/icon/double/label_jbsb.png"},
}

local function getCsv(csvName)
	if not csvName then
		return
	end
	return loadstring("return " .. csvName)()
end

-- @desc 判断系统是否开启
-- @return 1,x：开服天数未到 2,x：角色等级不足 3,x：公会等级不足 (x 表示需要条件,x 为nil 表示语言不支持)
local function judgeItemUnlock(cfg)
	--敬请期待
	if cfg.unlockFeature == "" then
		return "functionError", gLanguageCsv.comingSoon
	end

	if not dataEasy.isInServer(cfg.unlockFeature) then
		return "serverError", gLanguageCsv.comingSoon
	end

	if cfg.serverDayInfo then
		local lock = false -- 跨服天数不满足，则界面锁住状态
		local day = 0
		if cfg.serverDayInfo.funcType == "less" then

			day = getCsv(cfg.serverDayInfo.sevCsv)
			lock = dataEasy.serverOpenDaysLess(day)
		end
		if lock then
			return "openSevError", string.format(gLanguageCsv.unlockServerOpen, day)
		end
	end

	--判断unlock
	if not dataEasy.isUnlock(gUnlockCsv[cfg.unlockFeature]) then
		return "unlockError", dataEasy.getUnlockTip(gUnlockCsv[cfg.unlockFeature])
	end

	--处理玩家公会等级
	if cfg.unlockFeature == "unionFight" then
		local unionId = gGameModel.role:read("union_db_id")
		if not unionId then
			return "unionError", gLanguageCsv.nonunion
		end
		local level = gGameModel.role:read("union_level")
		if gUnionFeatureCsv[cfg.unlockFeature] > level then
			return "unionError", string.format(gLanguageCsv.unlockUnionLevel, gUnionFeatureCsv[cfg.unlockFeature])
		end
		if dataEasy.notUseUnionBuild() then
			return "unionQuitToday", gLanguageCsv.unlockUnionQuit
		end
	end

	return "succ"
end

local function setItem(list, node, v, redHintPos, lockImg, lockPos)
	node:get("baseNode.imgBG"):texture(v.cfg.lockbg1)
	if RED_HINTS[v.cfg.unlockFeature] then
		-- 先延迟处理，红点跟随面板
		performWithDelay(node, function()
			local props = RED_HINTS[v.cfg.unlockFeature]
			props.onNode = function (panel)
				panel:xy(redHintPos)
			end
			bind.extend(list, node:get("baseNode"), {
				class = "red_hint",
				props = props,
			})
		end, 0)
	end
	bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, v)}})
	local state, errorStr = judgeItemUnlock(v.cfg)
	node:get("baseNode.black"):visible(state ~= "succ")
	if state ~= "succ" then
		if node:get("baseNode.black.imgTextBG") then
			node:get("baseNode.black.imgTextBG"):hide()
		end
		if node:get("baseNode.black.textNote") then
			node:get("baseNode.black.textNote"):hide() --:text(errorStr)
		end
		local imgLock = node:get("baseNode.black.lockPanel.imgLock")
		local textNote = node:get("baseNode.black.lockPanel.textNote")
		local showTxt = errorStr
		if state == "unlockError" then
			local key = gUnlockCsv[v.cfg.unlockFeature]
			showTxt = string.format(gLanguageCsv.lvToUnlock, csv.unlock[key].startLevel)
		end
		textNote:text(showTxt)
		adapt.setTextScaleWithWidth(textNote, nil, 550)
		local size = node:get("baseNode.black.lockPanel"):size()
		adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2), {imgLock, textNote}, cc.p(15, 0))
	end
end

local AdventureView = class("AdventureView", cc.load("mvc").ViewBase)
AdventureView.RESOURCE_FILENAME = "adventure.json"
AdventureView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "pveList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("activityDatas"),
				item = bindHelper.self("item"),
				padding = 38,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:setName(v.cfg.unlockFeature)
					local cfg = v.cfg
					node:get("baseNode.textDesc"):text(cfg.desc)

					local tb = ACTIVITY_DOUBLE_HUODONG[v.cfg.unlockFeature]
					if tb then
						local state, paramMaps = dataEasy.isDoubleHuodong(tb.key)
						node:get("baseNode.flagImg"):visible(state)
						node:get("baseNode.flagImg"):texture(tb.res)
					end
					setItem(list, node, v, cc.p(730,1020), "", cc.p(325, 558))

					if v.cfg.unlockFeature == "activityGate" then
						local state, cfg = dataEasy.isShowDailyActivityIcon()
						if state then
							local icon = node:getChildByName("_icon_")
							if icon then
								return
							end
							local info = cfg.paramMap
							icon = ccui.ImageView:create(info.fbwkRes)
								:xy(node:width()/2 - 34, node:height()/2 + 10)
								:scale(2)
								:addTo(node, 999, "_icon_")
						else
							local icon = node:getChildByName("_icon_")
							if icon then
								icon:removeFromParent()
							end
						end
					end
					if v.cfg.unlockFeature == "fishing" then
						local imgFishingGame = ccui.ImageView:create("city/adventure/fishing/logo_dy_dydsrk.png")
							:anchorPoint(0, 1)
							:xy(23, node:height() + 5)
							:addTo(node:get("baseNode"), 5)

						local crossFishingRound = gGameModel.role:getIdler("cross_fishing_round")
						idlereasy.when(crossFishingRound, function(_, crossFishing)
							imgFishingGame:visible(crossFishing == "start")
						end):anonyOnly(node)
					end
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
					performWithDelay(list, function()
						local inGuiding, guideId = gGameUI.guideManager:isInGuiding()
						if inGuiding then
							local jumpToNode = csv.new_guide[guideId].jumpToNode
							if jumpToNode then
								for _, child in pairs(list:getChildren()) do
									if child:getName() == jumpToNode then
										list:jumpToItem(list:getIndex(child), cc.p(0.5, 0.5), cc.p(0.5, 0.5))
										break
									end
								end
							end
						end
					end, 0)
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["pvpItem"] = "pvpItem",
	["pvpList"] = {
		varname = "pvpList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("pvpDatas"),
				item = bindHelper.self("pvpItem"),
				padding = 110,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:setName(v.cfg.unlockFeature)
					setItem(list, node, v, cc.p(700,1090), "", cc.p(354, 552))
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["bg"] = "bg",
}

local viewsData = {
	activityGate = {
		viewName = "city.adventure.daily_activity.view",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/huodong/show", function(tb)
				cb("", tb.view)
			end)
		end,
	},
	endlessTower = {
		viewName = "city.adventure.endless_tower.view",
		styles = {full = true},
	},
	dispatchTask = {
		viewName = "city.adventure.dispatch_task.view",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/dispatch/task/refresh", function (tb)
				cb()
			end, false)
		end,
	},
	randomTower = {
		viewName = "city.adventure.random_tower.view",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/random_tower/prepare", function (tb)
				if tb.view.point_award_update then
					userDefault.setForeverLocalKey("isGetAward", {})
					userDefault.setForeverLocalKey("saveGetAward", {})
					userDefault.setForeverLocalKey("awardState", {isOpen = true})
				else
					userDefault.setForeverLocalKey("awardState", {})
				end
				cb()
			end)
		end,
	},
	arena = {
		viewName = "city.pvp.arena.view",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/pw/battle/get", function(tb)
				cb()
			end)
		end,
	},
	craft = {
		viewName = "city.pvp.craft.view",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/craft/battle/main", function(tb)
				local round = gGameModel.craft:read("round")
				if round == "over" or round == "closed" or round == "signup" then
					cb()
				else
					gGameUI:stackUI("city.pvp.craft.myschedule", nil, {full = true})
				end
			end)
		end,
	},
	cloneBattle = {
		viewName = "city.adventure.clone_battle.base",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/clone/get", function (tb)
				cb(tb.view)
			end)
		end,
	},
	unionFight = {
		viewName = "city.union.union_fight.view",
		styles = {full = true},
		func = function(cb)
			gGameApp:requestServer("/game/union/fight/battle/main", function(tb)
				cb()
			end)
		end,
	},
	crossCraft = {
		viewName = "city.pvp.cross_craft.view",
		styles = {full = true},
		func = function(cb)
			jumpEasy.jumpTo("crossCraft")
		end,
	},
	crossArena = {
		viewName = "city.pvp.cross_arena.view",
		styles = {full = true},
		func = function(cb)
			jumpEasy.jumpTo("crossArena")
		end,
	},
	crossMine = {
		viewName = "city.pvp.cross_mine.view",
		styles = {full = true},
		func = function(cb)
			jumpEasy.jumpTo("crossMine")
		end,
	},
	fishing = {
		viewName = "city.adventure.fishing.sence_select",
		styles = {full = true},
	},
	onlineFight = {
		viewName = "city.pvp.online_fight.view",
		styles = {full = true},
		func = function(cb)
			jumpEasy.jumpTo("onlineFight")
		end,
	},
	gymChallenge = {
		viewName = "city.adventure.gym_challenge.view",
		styles = {full = true},
		func = function(cb)
			jumpEasy.jumpTo("gymChallenge")
		end,
	},
	hunting = {
		func = function(cb)
			jumpEasy.jumpTo("hunting")
		end,
	},
	normalBraveChallenge = {
		func = function(cb)
			jumpEasy.jumpTo("normalBraveChallenge")
		end,
	},
}

function AdventureView:onCreate(from)
	adapt.centerWithScreen({"left", nil, false}, {"right", nil, false}, nil, {
		{self.pveList, "width"},
		{self.pveList, "pos", "left"},
		{self.pvpList, "width"},
		{self.pvpList, "pos", "left"},
	})
	from = from or "pve"
	self.pveList:visible(from == "pve")
	self.pvpList:visible(from == "pvp")
	local title = gLanguageCsv.adventure
	local subTitle = "ADVENTURE"
	if from == "pvp" then
		title = gLanguageCsv.spacePvp
		subTitle = "COMPETITION"
	else
		self.bg:visible(false)
		local pnode = self:getResourceNode()
		widget.addAnimationByKey(pnode, "effect/maoxianditu.skel", 'maoxianditu', "effect_loop", 1)
			:anchorPoint(cc.p(0.5,0.5))
			:scale(2)
			:xy(pnode:width()/2, pnode:height()/2)
	end
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = title, subTitle = subTitle})

	self.activityDatas = {}
	self.pvpDatas = {}
	self.data = idlers.newWithMap({})
	if from == "pve" then
		self.activityDatas = self.data
	elseif from == "pvp" then
		self.pvpDatas = self.data
	end

	local showData = {}
	local function refreshData(csvId, isShow)
		showData[csvId] = isShow
		local data = {}
		for csvId, v in pairs(showData) do
			if v == true then
				local cfg = csv.pvpandpve[csvId]
				table.insert(data, {cfg = cfg, unlockKey = cfg.unlockFeature, viewData = viewsData[cfg.goto]})
			end
		end
		table.sort(data, function(a, b)
			return a.cfg.sortIndex < b.cfg.sortIndex
		end)
		self.data:update(data)
	end
	for i,v in orderCsvPairs(csv.pvpandpve) do
		if v.type == from and v.flag == 0 then
			local unlockKey = gUnlockCsv[v.unlockFeature]
			if v.unlockFeature == "" then
				refreshData(i, true)
			else
				dataEasy.getListenShow(unlockKey, functools.partial(refreshData, i))
			end
		end
	end

	-- 派遣任务没有开启时，不会监听
	dataEasy.getListenUnlock(gUnlockCsv.dispatchTask, function(isUnlock)
		if isUnlock then
			DispatchTaskView.setRefreshTime(self, nil, {tag = "dispatchTaskRefresh", cb = function ()
				local dispatchTasksRedHintRefrseh = gGameModel.forever_dispatch:getIdlerOrigin("dispatchTasksRedHintRefrseh")
				dispatchTasksRedHintRefrseh:modify(function(val)
					return true, not val
				end)
			end})
		end
	end)
end

function AdventureView:onItemClick(list, v)
	local cfg = v.cfg
	local state, errorStr = judgeItemUnlock(cfg)
	if state ~= "succ" then
		gGameUI:showTip(errorStr)
		return
	end
	if v.unlockKey ~= "" and not dataEasy.isUnlock(v.unlockKey) then
		gGameUI:showTip(dataEasy.getUnlockTip(v.unlockKey))
		return
	end
	local viewData = v.viewData
	if not viewData then
		return
	end
	if viewData.func then
		viewData.func(function(...)
			local params = clone(viewData.params or {})
			for _,v in ipairs({...}) do
				table.insert(params, v)
			end
			gGameUI:stackUI(viewData.viewName, nil, viewData.styles, unpack(params))
		end)
	elseif viewData.viewName then
		gGameUI:stackUI(viewData.viewName, nil, viewData.styles, unpack(viewData.params or {}))
	end
end

return AdventureView