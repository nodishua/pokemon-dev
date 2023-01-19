-- @date:   2020-06-17
-- @desc:   钓鱼场景选择界面
local fishingTools = require "app.views.city.adventure.fishing.tools"
local SenceSelectView = class("SenceSelectView", cc.load("mvc").ViewBase)

-- 钓鱼大赛提前一天预告
local FISING_GAME_PRE_TIME = 24 * 3600

SenceSelectView.RESOURCE_FILENAME = "fishing_main.json"
SenceSelectView.RESOURCE_BINDING = {
	["imgBg"] = "imgBg",
	["right"] = "right",
	["right.scenePanel"] = "scenePanel",
	["right.underRight.tip"] = "tip",
	["right.underRight.time"] = "time",
	["right.underRight.times"] = "times",
	["right.underRight.numTip"] = "numTip",
	["right.scenePanel.item"] = "item",
	["right.scenePanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("fishShow"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						event = "extend",
						class = "fish_icon",
						props = {
							data = {key = v},
							onNodeClick = true,
							lock = true,
						},
					})
				end,
			},
		},
	},
	["right.time.txt1"] = "refreshTimeTxt",
	["right.time.txt2"] = {
		varname = "refreshTime",
		binds = {
			event = "text",
			idler = bindHelper.self("deltaTime"),
			method = function(val)
				local tab = time.getCutDown(val)
				return tab.str
			end,
		},
	},
	["right.underLeft.btnLv"] = {
		varname = "btnLv",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnLv")}
		},
	},
	["right.underLeft.btnHandbook"] = {
		varname = "btnHandbook",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnHandbook")}
		},
	},
	["right.underLeft.btnShop"] = {
		varname = "btnShop",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnShop")}
		},
	},
	["right.underLeft.btnTools"] = {
		varname = "btnTools",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnTools")}
		},
	},
	["right.underLeft.btnRank"] = {
		varname = "btnRank",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRank")}
		},
	},
	["right.underRight.btnCatch"] = {
		varname = "btnCatch",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnCatch")}
		},
	},
	["right.underRight.btnEnter"] = "btnEnter",
	["btn"] = "btnItem",
	["left.listview"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				dataOrderCmp = function(a, b)
					if a.sort ~= b.sort then
						return a.sort > b.sort
					end
					return a.csvId < b.csvId
				end,
				data = bindHelper.self("btnDatas"),
				item = bindHelper.self("btnItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local normal = node:get("btnNormal")
					local selected = node:get("btnSelected")
					local lock = normal:get("lock")
					lock:visible(v.myLv < v.needLv or v.lock == 0)
					if k == game.FISHING_GAME then
						normal:loadTextureNormal("city/adventure/fishing/tab_dyds.png")
						selected:loadTextureNormal("city/adventure/fishing/tab_selected_dyds.png")
						if matchLanguage({"en"}) then
							adapt.setTextScaleWithWidth(normal:get("textNote"), v.name, node:width() - 170)
							adapt.setTextScaleWithWidth(selected:get("textNote"), v.name, node:width() - 150)
							normal:get("waiting"):width(220)
							selected:get("waiting"):width(220)
							normal:get("waiting.txt"):x(100)
							selected:get("waiting.txt"):x(100)
						end
					end

					selected:visible(v.selected)
					normal:visible(not v.selected)
					normal:get("textNote"):text(v.name)
					selected:get("textNote"):text(v.name)
					local crossFishingRound = gGameModel.role:getIdler("cross_fishing_round")
					idlereasy.when(crossFishingRound, function(_, crossFishing)
						local show = (k == game.FISHING_GAME and v.preTime and v.preTime < FISING_GAME_PRE_TIME) or false
						selected:get("waiting"):visible(show and crossFishing == "closed")
						normal:get("waiting"):visible(show and crossFishing == "closed")
					end):anonyOnly(list)

					if matchLanguage({"kr"}) then
						selected:get("waiting"):width(200)
						normal:get("waiting"):width(200)
						selected:get("waiting"):x(300)
						normal:get("waiting"):x(300)
						selected:get("waiting.txt"):x(100)
						normal:get("waiting.txt"):x(100)
					end
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onSelectClick"),
			},
		},
	},
	["right.scenePanel.txt"] = {
		varname = "txtCommon",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["right.underLeft.btnLv.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["right.underLeft.btnHandbook.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["right.underLeft.btnShop.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["right.underLeft.btnTools.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["right.underLeft.btnRank.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
}

function SenceSelectView:onCreate()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
	:init({title = gLanguageCsv.angling, subTitle = "FISHING"})

	self:enableSchedule()
	self:initModel()
	self:initBgMask()
	self.oldLv = self.fishLevel:read()

	adapt.centerWithScreen("left", "right", nil, {
		{self.scenePanel:get("bg"), "width"},
		{self.mask1, "width"},
		{self.list, "width"},
		{self.right:get("tip.bg"), "width"},
		{self.right:get("time.bg"), "width"},
	})

	self.showTab = idler.new(self.crossFishingRound:read() == "start" and game.FISHING_GAME or 1)
	self.fishShow = idlers.new({})
	-- 钓鱼大赛开启倒计时
	self.deltaTime = idler.new(0)

	-- 常见鱼相关信息
	local btnDatas = {}
	for k,v in csvPairs(csv.fishing.scene) do
		btnDatas[k] = {
			csvId = k,
			name = v.name,
			res = v.res,
			typ = v.type,
			needLv = v.needLv,
			priview = v.priview,
			lock = v.lock,
			myLv = 1,
			selected = false,
			sort = 0,
		}
	end
	self.btnDatas = idlers.newWithMap(btnDatas)
	idlereasy.any({self.fishLevel, self.fishCounter, self.targetCounter, self.fishingCounter, self.isAuto, self.selectScene, self.crossFishingRound}
		, function(_, fishLevel,fishCounter,targetCounter,fishingCounter,isAuto,selectScene,crossFishingRound)
		-- 钓鱼大赛crossFishingRound = start为开始   = closed 为未开始
		self.right:get("tip"):visible(isAuto)

		for csvId, v in csvPairs(csv.fishing.scene) do
			self.btnDatas:at(csvId):modify(function(data)
				data.myLv = fishLevel
				if data.typ == 2 then
					data.sort = crossFishingRound == "start" and 1 or 0
					data.preTime = self:getFishingGamePreTime()
				end
			end, true)
		end

		dataEasy.tryCallFunc(self.btnList, "filterSortItems", true)

		self.nowCounter = gCommonConfigCsv.fishingDailyTimes - fishingCounter
		self.times:text(self.nowCounter.."/"..gCommonConfigCsv.fishingDailyTimes)

		bind.touch(self, self.btnEnter, {methods = {ended = function()
			self:onBtnEnter(self.showTab:read(), selectScene)
		end}})

		self.showTab:addListener(function(val, oldval, idler)
			local btnData = self.btnDatas:atproxy(val)
			self.btnDatas:atproxy(oldval).selected = false
			self.btnDatas:atproxy(val).selected = true

			-- 场景鱼预览
			local fishShow = {}
			for k,v in orderCsvPairs(btnData.priview) do
				table.insert(fishShow, v)
			end
			self.fishShow:update(fishShow)
			self.btnEnter:setTouchEnabled(btnData.myLv >= btnData.needLv)
			self.btnCatch:setTouchEnabled(btnData.myLv >= btnData.needLv)
			self.tip:visible(btnData.myLv < btnData.needLv)

			if val == game.FISHING_GAME then
				local isUnlock = dataEasy.isUnlock(gUnlockCsv.gameCatch)
				self.btnCatch:visible(btnData.myLv >= btnData.needLv and isUnlock == true)
			else
				local isUnlock = dataEasy.isUnlock(gUnlockCsv.catch)
				self.btnCatch:visible(btnData.myLv >= btnData.needLv and isUnlock == true)
			end

			self.numTip:visible(btnData.myLv < btnData.needLv)
			self.numTip:text(btnData.needLv)
			adapt.oneLinePos(self.tip, self.numTip, cc.p(0, 0), "left")
			cache.setShader(self.btnEnter, false, btnData.myLv >= btnData.needLv and "normal" or "hsl_gray")
			cache.setShader(self.btnCatch, false, btnData.myLv >= btnData.needLv and "normal" or "hsl_gray")
			self.right:get("time"):hide()
			if val == game.FISHING_GAME and crossFishingRound == "closed" then
				self:fishingGameTimer(self.btnDatas:atproxy(game.FISHING_GAME).preTime)
			end
			self.btnTools:visible(btnData.myLv >= btnData.needLv or val == game.FISHING_GAME)
			self.btnLv:visible(btnData.myLv >= btnData.needLv or val == game.FISHING_GAME)
			self.btnHandbook:visible(btnData.myLv >= btnData.needLv or val == game.FISHING_GAME)
			self.btnShop:visible(btnData.myLv >= btnData.needLv or val == game.FISHING_GAME)
			self.time:visible(btnData.myLv >= btnData.needLv)
			self.times:visible(btnData.myLv >= btnData.needLv)
			if val == game.FISHING_GAME and crossFishingRound == "closed" then
				self.btnEnter:setTouchEnabled(false)
				cache.setShader(self.btnEnter, false, "hsl_gray")
				self.right:get("tip"):hide()
			else
				if self.isAuto:read() == true then
					self.right:get("tip"):show()
				end
			end

			-- 设置场景动画
			local clippingNode = self.scenePanel:get("pos.clippingNode")
			clippingNode:removeAllChildren()
			self.btnRank:visible(val == game.FISHING_GAME)
			self.right:get("fishingGameTag"):visible(val == game.FISHING_GAME and crossFishingRound == "start")
			widget.addAnimationByKey(clippingNode, btnData.res, 'diaoyuBg', "effect_loop", 1)
				:scale(1.5)
			if val == game.FISHING_GAME then
				widget.addAnimationByKey(self.scenePanel:get("pos.clippingNode.diaoyuBg"), "fishing/diaoyudasai.skel", 'diaoyudasai', "effect_loop", 2)
					:xy(-300, 90)
			end
		end)
	end)
end

-- 钓鱼大赛倒计时
function SenceSelectView:fishingGameTimer(delta)
	self:unSchedule(7000)
	self.deltaTime:set(0)
	self.right:get("time"):hide()
	if not delta then
		return
	end
	self.deltaTime:set(delta)
	self.right:get("time"):visible(delta > 0 and delta < FISING_GAME_PRE_TIME)
	self:schedule(function()
		delta = delta - 1
		if delta <= 0 or delta > FISING_GAME_PRE_TIME then
			self.right:get("time"):hide()
		end
		self.deltaTime:set(delta)
		adapt.oneLineCenterPos(cc.p(400, self.refreshTimeTxt:y()), {self.refreshTimeTxt, self.refreshTime})
	end, 1, 0, 7000)
end

function SenceSelectView:initModel()
	self.fishLevel = gGameModel.fishing:getIdler("level")
	self.fishCounter = gGameModel.fishing:getIdler("fish_counter")
	self.targetCounter = gGameModel.fishing:getIdler("target_counter")
	self.fishingCounter = gGameModel.daily_record:getIdler('fishing_counter')
	self.selectScene = gGameModel.fishing:getIdler("select_scene")
	self.isAuto = gGameModel.fishing:getIdler("is_auto")
	self.crossFishingRound = gGameModel.role:getIdler("cross_fishing_round")
	self.selectRod = gGameModel.fishing:getIdler("select_rod")
	self.selectBait = gGameModel.fishing:getIdler("select_bait")
	self.items = gGameModel.role:getIdler("items")
end

-- 场景遮罩图片
function SenceSelectView:initBgMask()
	self.mask1 = ccui.Scale9Sprite:create()
	self.mask1:initWithFile(cc.rect(50, 50, 1, 1), "city/adventure/fishing/mask_dy_bgpre.png")
	self.mask1:size(cc.size(1858, 888))
	local clippingNode = cc.ClippingNode:create(self.mask1)
		:setAlphaThreshold(0.1)
		:addTo(self.scenePanel:get("pos"), 1, "clippingNode")
end

-- 点击场景页签
function SenceSelectView:onSelectClick(list, index, val)
	-- 选择的场景
	if val.lock ~= 0 then
		self.showTab:set(index)
	else
		gGameUI:showTip(gLanguageCsv.pleaseWaitOpen)
		return
	end

	if index == game.FISHING_GAME and self.crossFishingRound:read() == "closed" then
		gGameUI:showTip(gLanguageCsv.fishGameNotStart)
	end
end

-- 获取钓鱼大赛预告时间，1、servers 未配置跨服组{}, 找满足开服天数的；2、配置了跨服组，找对应服务器
function SenceSelectView:getFishingGamePreTime()
	-- 获取当前服务器时间后最近的钓鱼跨服组配置
	local id = dataEasy.getCrossServiceData("crossfishing", csv.cross.fishing.base[1].servOpenDays)
	if id then
		local date = csv.cross.service[id].date
		return time.getNumTimestamp(date, 5) - time.getTime()
	end
end

-- 等级
function SenceSelectView:onBtnLv()
	gGameUI:stackUI("city.adventure.fishing.level")
end

-- 图鉴
function SenceSelectView:onBtnHandbook()
	gGameUI:stackUI("city.adventure.fishing.book")
end

-- 商店
function SenceSelectView:onBtnShop()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fishing/shop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.FISHING_SHOP)
		end)
	end
end

-- 渔具界面
function SenceSelectView:onBtnTools()
	if self.crossFishingRound:read() == "closed" and self.showTab:read() == game.FISHING_GAME then
		gGameUI:showTip(gLanguageCsv.fishGameNotStart)
		return
	end
	if self.isAuto:read() == true and self.showTab:read() == gGameModel.fishing:read("select_scene") then
		if self.showTab:read() == gGameModel.fishing:read("select_scene") then
			gGameUI:stackUI("city.adventure.fishing.bag", nil, nil, 1, self.showTab:read())
		else
			gGameApp:requestServer("/game/fishing/prepare",function (tb)
				gGameUI:stackUI("city.adventure.fishing.bag", nil, nil, 1, self.showTab:read())
			end, "scene", self.showTab:read())
		end
	elseif self.isAuto:read() == true and self.showTab:read() ~= gGameModel.fishing:read("select_scene") then
		gGameUI:stackUI("city.adventure.fishing.auto", nil, {blackLayer = true, clickClose = false}, idx, self:createHandler("onOpenView"))
	elseif self.isAuto:read() == false then
		if self.showTab:read() == gGameModel.fishing:read("select_scene") then
			gGameUI:stackUI("city.adventure.fishing.bag", nil, nil, 1, self.showTab:read())
		else
			gGameApp:requestServer("/game/fishing/prepare",function (tb)
				gGameUI:stackUI("city.adventure.fishing.bag", nil, nil, 1, self.showTab:read())
			end, "scene", self.showTab:read())
		end
	end
end

-- 钓鱼大赛排行榜
function SenceSelectView:onBtnRank()
	gGameApp:requestServer("/game/cross/fishing/rank",function (tb)
		gGameUI:stackUI("city.adventure.fishing.rank", nil, nil, tb.view)
	end)
end

-- 一键捕捞
function SenceSelectView:onBtnCatch()
	if self.showTab:read() == game.FISHING_GAME and self.crossFishingRound:read() == "closed" then
		gGameUI:showTip(gLanguageCsv.fishGameNotStart)
		return
	end
	local selectBait = self.selectBait:read()
	local selectRod = self.selectRod:read()
	local baitCfg = csv.fishing.bait[selectBait]
	local baitCount = 0
	if baitCfg then
		if self.items:read()[baitCfg.itemId] == nil then
			baitCount = 0
		else
			baitCount = self.items:read()[baitCfg.itemId]
		end
	end
	local times = self.nowCounter > baitCount and baitCount or self.nowCounter

	if selectRod == 0 then
		gGameUI:showTip(gLanguageCsv.noRod)
		return
	elseif selectBait == 0 then
		gGameUI:showTip(gLanguageCsv.noBait)
		return
	elseif selectBait then
		local map = itertools.map(baitCfg.scene, function(_, v) return v, true end)
		if not map[self.showTab:read()] then
			gGameUI:showTip(gLanguageCsv.noBait)
			return
		end
		if baitCount == 0 then
			gGameUI:showTip(gLanguageCsv.noBaitCount)
			return
		end
	end
	if self.nowCounter <= 0 then
		gGameUI:showTip(gLanguageCsv.fishNoTimes)
		return
	end
	if self.isAuto:read() == true then
		gGameUI:stackUI("city.adventure.fishing.auto", nil, {blackLayer = true, clickClose = false}, nil, self:createHandler("autoLvUp"))
		return
	end

	if self.showTab:read() ~= gGameModel.fishing:read("select_scene") then
		gGameApp:requestServer("/game/fishing/prepare",nil, "scene", self.showTab:read())
	end

	local old = self.fishLevel:read()
	gGameUI:showDialog{
		strs = {
			string.format(gLanguageCsv.catchTip, times, baitCfg.name, times)
		},
		cb = function()
			gGameApp:requestServer("/game/fishing/onekey",function (tb)
				if tb.view.fish == nil and tb.view.award == nil then
					gGameUI:showTip(gLanguageCsv.catchLoseFishRunAway)
				else
					gGameUI:stackUI("city.adventure.fishing.award", nil, {blackLayer = true, clickClose = true}, tb.view, self.showTab:read(), old)
				end
			end)
		end,
		isRich = true,
		fontSize = 42,
		btnType = 2,
		clearFast = true,
	}
end

-- 进入钓鱼场景
function SenceSelectView:onBtnEnter(idx, scene)
	if self.isAuto:read() == true and idx == scene then
		if scene == game.FISHING_GAME then
			gGameApp:requestServer("/game/cross/fishing/rank",function (tb)
				gGameUI:stackUI("city.adventure.fishing.view", nil, {full = true}, idx, tb.view)
			end)
		else
			gGameUI:stackUI("city.adventure.fishing.view", nil, {full = true}, idx)
		end

	elseif self.isAuto:read() == true and idx ~= scene then
		gGameUI:stackUI("city.adventure.fishing.auto", nil, {blackLayer = true, clickClose = false}, idx, self:createHandler("fishSprite"))

	elseif self.isAuto:read() == false then
		gGameApp:requestServer("/game/fishing/prepare",function (tb)
			if idx == game.FISHING_GAME then
				gGameApp:requestServer("/game/cross/fishing/rank",function (tb)
					gGameUI:stackUI("city.adventure.fishing.view", nil, {full = true}, idx, tb.view)
				end)
			else
				gGameUI:stackUI("city.adventure.fishing.view", nil, {full = true}, idx)
			end
		end, "scene", idx)
	end
end

function SenceSelectView:autoLvUp()
	if self.fishLevel:read() > self.oldLv then
		gGameUI:stackUI("city.adventure.fishing.upgrade")
	end
end

function SenceSelectView:fishSprite()
	if self.fishLevel:read() > self.oldLv then
		gGameUI:stackUI("city.adventure.fishing.upgrade", nil, nil, self:createHandler("onOpenView"))
	else
		self:onOpenView()
	end
end

function SenceSelectView:onOpenView()
	if self.showTab:read() == game.FISHING_GAME and self.crossFishingRound:read() == "closed" then
		gGameUI:showTip(gLanguageCsv.fishGameNotStart)
		return
	end
	gGameApp:requestServer("/game/fishing/prepare",function (tb)
		if self.showTab:read() == game.FISHING_GAME then
			gGameApp:requestServer("/game/cross/fishing/rank",function (tb)
				gGameUI:stackUI("city.adventure.fishing.view", nil, {full = true}, self.showTab:read(), tb.view)
			end)
			return
		end
		gGameUI:stackUI("city.adventure.fishing.view", nil, {full = true}, self.showTab:read())
	end, "scene", self.showTab:read())
end

return SenceSelectView