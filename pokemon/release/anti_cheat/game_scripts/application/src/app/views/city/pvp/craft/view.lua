-- @date:   2019-9-26 11:33:34
-- @desc:   限时PVP 石英大会主界面

local NEED_CARDS = 10
local DELAY = 10

local CraftMainView = class("CraftMainView", cc.load("mvc").ViewBase)

CraftMainView.RESOURCE_FILENAME = "craft_main.json"
CraftMainView.RESOURCE_BINDING = {
	["btnMyTeam"] = {
		varname  = "btnMyTeam",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSignup")},
		},
	},
	["btns.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRule")},
		},
	},
	["btns.btnRule.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["btns.btnRankReward"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnReward")},
		},
	},
	["btns.btnRankReward.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["btns.btnRecord"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRecord")},
		},
	},
	["btns.btnRecord.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["btns.btnBet"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBet")},
		},
	},
	["btns.btnBet.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["btns.btnShop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnShop")},
		},
	},
	["btns.btnShop.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["down.btnOk"] = {
		varname = "btnOk",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSignup")},
		},
	},
	["down.btnOk.textNote"] = {
		varname = "btnOkText",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("btnText"),
			},
			{
				event = "effect",
				data = {glow = {color = ui.COLORS.GLOW.WHITE}},
			},
		},
	},
	["down.btnOk.mask"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("round"),
			method = function(val)
				return val == "closed"
			end,
		},
	},
	["down.imgFlag"] = "imgFlag",
	["down.vipShow"] = {
		varname = "vipShow",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["down.textTime"] = {
		varname = "textTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["down.textTimeNote"] = "textTimeNote",
	["special"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("hasSpecial")
		},
	},
	["item"] = "item",
	["special.list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					for i=1,2 do
						node:get("icon" .. i):hide()
					end
					local count = 0
					for i,v in ipairs(v.natureTypes) do
						node:get("icon" .. i):texture(ui.ATTR_ICON[v])
						node:get("icon" .. i):show()
						count = count + 1
					end
					local attrName = game.ATTRDEF_TABLE[v.attrType]
					local str = "attr" .. string.caption(attrName)
					node:get("textName"):text(gLanguageCsv[str])
					local val = dataEasy.getAttrValueString(v.attrType, v.attrNum)
					node:get("textVal"):text("+" .. val)
					text.addEffect(node:get("textName"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}})
					text.addEffect(node:get("textVal"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}})
					local target = count == 1 and node:get("icon1") or node:get("icon2")
					adapt.oneLinePos(target, {node:get("textName"), node:get("textVal")}, cc.p(10, 0))
				end,
			},
		},
	},
	["top1"] = {
		varname = "top1",
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onShowInfo(1)
			end),
		},
	},
	["top2"] = {
		varname = "top2",
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onShowInfo(2)
			end),
		},
	},
	["top3"] = {
		varname = "top3",
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onShowInfo(3)
			end),
		},
	},
	["top1.down.textLv"] = "top1Lv",
	["top1.down.textName"] = "top1Name",
	["top1.down.textFightPoint"] = "top1FightPoint",
	["top2.down.textLv"] = "top2Lv",
	["top2.down.textName"] = "top2Name",
	["top2.down.textFightPoint"] = "top2FightPoint",
	["top3.down.textLv"] = "top3Lv",
	["top3.down.textName"] = "top3Name",
	["top3.down.textFightPoint"] = "top3FightPoint",
	["top1.down"] = {
		varname = "down1",
		binds = {
			event = "visible",
			idler = bindHelper.self("hasHistoryData"),
		},
	},
	["top2.down"] = {
		varname = "down2",
		binds = {
			event = "visible",
			idler = bindHelper.self("hasHistoryData"),
		},
	},
	["top3.down"] = {
		varname = "down3",
		binds = {
			event = "visible",
			idler = bindHelper.self("hasHistoryData"),
		},
	},
	["top1.noOne"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("hasHistoryData"),
			method = function(val)
				return not val
			end,
		},
	},
	["top2.noOne"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("hasHistoryData"),
			method = function(val)
				return not val
			end,
		},
	},
	["top3.noOne"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("hasHistoryData"),
			method = function(val)
				return not val
			end,
		},
	},
	["marqueePanel"] = {
		varname = "marqueePanel",
		binds = {
			event = "extend",
			class = "marquee",
		}
	}
}

function CraftMainView:onCreate()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.craft, subTitle = "INDIGO PLATEAU CONFERENCE"})

	self.topData = {}
	self:initModel()
	-- 右上角 属性奖励
	self.attrDatas = idlers.newWithMap({})
	-- 右上角 是否有特殊奖励
	self.hasSpecial = idler.new(false)

	local buffCsv = csv.craft.buffs
	self.delta = DELAY
	self.btnText = idler.new(gLanguageCsv.signup)
	adapt.setTextScaleWithWidth(self.btnOkText, gLanguageCsv.signup, 380)
	idlereasy.any({self.isSignup, self.round, self.time, self.buffs}, function(_, isSignup, round, stateTime, buffs)
		if round == "prepare" then
			gGameUI:goBackInStackUI("city.adventure.pvp")
			gGameUI:stackUI("city.pvp.craft.myschedule", nil, {full = true})
			return
		end
		local signupSucc = isSignup and round == "signup"
		self.btnMyTeam:visible(signupSucc)
		self.imgFlag:visible(signupSucc)
		self.vipShow:text(string.format(gLanguageCsv.vipSignupShow, csv.craft.base[1].autoSignVIP))
		self.vipShow:visible(false)
		self.btnOk:visible(not signupSucc)
		local str = gLanguageCsv.signTime
		local strTime = string.format("%s-%s", dataEasy.getTimeStrByKey("craft", "signUpStart"), dataEasy.getTimeStrByKey("craft", "signUpEnd"))
		local cenPos = cc.p(240, 200)
		if signupSucc then
			str = gLanguageCsv.startTime
			strTime = dataEasy.getTimeStrByKey("craft", "matchStart")
			cenPos = cc.p(226, 200)
		end
		self.textTime:text(strTime)
		adapt.oneLineCenterPos(cenPos, {self.textTimeNote, self.textTime}, cc.p(6, 0))

		local t = {}
		local count = 0
		for i,v in ipairs(buffs) do
			count = count + 1
			local data = {}
			local cfg = buffCsv[v]
			data.natureTypes = cfg.natureTypes
			data.attrType = cfg.attrType
			data.attrNum = cfg.attrNum
			table.insert(t, data)
		end
		self.attrDatas:update(t)
		self.hasSpecial:set(count > 0)

		local btnStr = gLanguageCsv.signup
		if round == "signup" then
			local signUpEndHour, signUpEndMin = dataEasy.getTimeStrByKey("craft", "matchStart", true)
			local t = time.getNowDate()
			t.hour = signUpEndHour
			t.min = signUpEndMin
			t.second = 0
			self.delta = time.getTimestamp(t) - time.getTime()
			self.vipShow:visible(not signupSucc)
		elseif round == "over" or round == "closed" then
			self.delta = self:getNextStartTime()
			btnStr = gLanguageCsv.craftNotOpen
		end
		if matchLanguage({"en"}) then
			if round == "signup" and not signupSucc then
				str = gLanguageCsv.endSignUpTime
			elseif round == "over" or round == "closed" then
				str = gLanguageCsv.startSignUpTime
			end
		end
		self.textTimeNote:text(str)
		self.btnText:set(btnStr)
		adapt.setTextScaleWithWidth(self.btnOkText, btnStr, 380)
	end)

	self:enableSchedule():schedule(function()
		self.delta = self.delta - 1
		if self.delta < 0 then
			self.delta = DELAY
			gGameApp:requestServer("/game/craft/battle/main")

		elseif matchLanguage({"en"}) or (self.isSignup:read() and self.round:read() == "signup") then
			local t = time.getCutDown(self.delta)
			self.textTime:text(t.str)
			adapt.oneLineCenterPos(cc.p(226, 200), {self.textTimeNote, self.textTime}, cc.p(6, 0))
		end
	end, 1, 0)
end

function CraftMainView:initItem(parent, data)
	parent:removeChildByName("card")
	parent:removeChildByName("figure")

	local roleFigure = gRoleFigureCsv
	local cardsCfg = csv.cards
	local unitCfg = csv.unit

	local cardID = data.display.top_card
	local skinID = data.display.skin_id
	local unit = dataEasy.getUnitCsv(cardID, skinID)
	local figureCfg = roleFigure[data.figure]
	local size = parent:size()
	local cardSprite = widget.addAnimationByKey(parent, unit.unitRes, "card", "standby_loop", -1)
		:xy(size.width / 2 + 100, size.height / 4 + 10)
		:scale(unit.scale * 1.4)
	cardSprite:setSkin(unit.skin)

	if string.len(figureCfg.resSpine or "") > 0 then
		widget.addAnimationByKey(parent, figureCfg.resSpine, "figure", "standby_loop1", 3)
			:xy(size.width / 2 - 100, size.height / 4 + 10)
			:scale(figureCfg.scale)
	end
	if data.title > 0 then
		bind.extend(self, parent, {
			event = "extend",
			class = "role_title",
			props = {
				data = data.title,
				onNode = function(panel)
					panel:xy(size.width / 2, size.height - 100)
					panel:scale(1.2)
					panel:z(3)
				end,
			},
		})
	end
end

function CraftMainView:initModel()
	self.vip = gGameModel.role:getIdler("vip_level")
	self.cards = gGameModel.role:getIdler("cards")
	self.hasHistoryData = idler.new(false)
	local dailyRecord = gGameModel.daily_record
	-- 是否报名
	self.isSignup = dailyRecord:getIdler("craft_sign_up")
	local craftData = gGameModel.craft
	self.round = craftData:getIdler("round")
	self.buffs = craftData:getIdler("buffs")
	-- 总报名数量
	self.signup = craftData:read("signup")
	self.history = craftData:getIdler("history")
	self.time = craftData:getIdler("time")
	self.top8Plays = craftData:getIdler("top8_plays")
	self.battleMessages = craftData:getIdler("battle_messages")
	local yesterdayTop = craftData:getIdler("yesterday_top8_plays")
	idlereasy.when(yesterdayTop, function(_, topData)
		if not topData then
			return
		end
		local champion = topData.champion
		local third = topData.third
		local hasHistoryData = false
		if champion and third then
			hasHistoryData = true
			self.topData = {}
			local top1Data = champion.result == "win" and champion.role1 or champion.role2
			local top2Data = champion.result == "win" and champion.role2 or champion.role1
			local top3Data = third.result == "win" and third.role1 or third.role2
			table.insert(self.topData, top1Data)
			table.insert(self.topData, top2Data)
			table.insert(self.topData, top3Data)
			for i,v in ipairs(self.topData) do
				self["top" .. i .. "Lv"]:text("Lv" .. v.level)
				self["top" .. i .. "Name"]:text(v.name)
				self["top" .. i .. "FightPoint"]:text(v.display.fighting_point)
				self:initItem(self["top" .. i], v)
			end
		end
		self.hasHistoryData:set(hasHistoryData)
	end)
end

function CraftMainView:onShowInfo(from)
	if not self.topData[from] then
		return
	end
	gGameApp:requestServer("/game/craft/battle/enemy/get",function (tb)
		gGameUI:stackUI("city.pvp.craft.enemy_embattle", nil, nil, tb.view, 2)
	end, self.topData[from].role_db_id, self.topData[from].record_db_id)
end

function CraftMainView:onBtnRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function CraftMainView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(112),
		c.noteText(39001, 39010),
		c.noteText(113),
		c.noteText(40001, 40005),
		c.noteText(114),
		c.noteText(41001, 41004),
		c.noteText(115),
		c.noteText(42001, 42004),
	}
	return context
end

function CraftMainView:getNextStartTime()
	local round = self.round:read()
	local delta = 0
	if round ~= "closed" and round ~= "over" then
		return delta
	end
	local curTime = time.getTime()
	local t = time.getDate(curTime)
	local wday = t.wday == 1 and 7 or t.wday - 1
	local cfg = csv.craft.base[1]
	local cur = tonumber(string.format("%02d%02d", t.hour, t.min))

	local isIntab = itertools.include(cfg.openWeekday, wday)
	local hour, min = dataEasy.getTimeStrByKey("craft", "signUpStart", true)
	if isIntab and cur < hour*100+min  then
		t.hour = hour
		t.min = 0
		t.sec = 0
		delta = time.getTimestamp(t) - curTime
	else
		local targetWday = cfg.openWeekday[1]
		for _,v in ipairs(cfg.openWeekday) do
			if v > wday then
				targetWday = v
				break
			end
		end
		local day = targetWday - wday
		-- 下周
		if day < 0 then
			day = day + 7 - 1
		end
		local cloneT = clone(t)
		cloneT.hour = 24
		cloneT.min = 24
		cloneT.sec = 24
		delta = time.getTimestamp(cloneT) - curTime
		delta = delta + day * 24 * 3600 + hour * 3600
	end

	return delta
end

function CraftMainView:onBtnReward()
	gGameApp:requestServer("/game/rank",function (tb)
		gGameUI:stackUI("city.pvp.craft.rank", nil, nil, tb.view)
	end, "craft", 0, 50)
end

function CraftMainView:onBtnRecord()
	if not self.hasHistoryData:read() then
		return
	end
	-- gGameUI:stackUI("city.pvp.craft.myschedule", nil, {full = true}, true)
	gGameUI:stackUI("city.pvp.craft.mainschedule_eight", nil, {full = true}, true)
end

function CraftMainView:onBtnBet()
	gGameApp:requestServer("/game/craft/bet/info",function (tb)
		gGameUI:stackUI("city.pvp.craft.bet", nil, nil, tb.view)
	end)
end

function CraftMainView:onBtnShop()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fixshop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.CRAFT_SHOP)
		end)
	end
end

function CraftMainView:canSignUp()
	local result = false
	local cards = self.cards:read()
	local size = itertools.size(cards)
	if size < 10 then
		return result
	end
	local csvTab = csv.cards
	local t = {}
	local count = 0
	for i,dbId in ipairs(cards) do
		local cardId = gGameModel.cards:find(dbId):read("card_id")
		local cfg = csvTab[cardId]
		local cardMarkID = cfg.cardMarkID
		if not t[cardMarkID] then
			t[cardMarkID] = true
			count = count + 1
		end
		if count >= 10 then
			result = true
			break
		end
	end

	return result
end

function CraftMainView:onSignup()
	local round = self.round:read()
	if self.round:read() == "closed" or self.round:read() == "over" then
		local endTime = self.time:read()
		local t = time.getDate(endTime)
		t.hour = 0
		t.min = 0
		t.sec = 0
		local endDay = time.getTimestamp(t)
		local curTime = time.getTime()
		local str = gLanguageCsv.battleIsOver
		if curTime > endDay + 29 * 3600 then
			str = gLanguageCsv.battleNotOpen
		end
		gGameUI:showTip(str)
		return
	end
	local result = self:canSignUp()
	if not result then
		gGameUI:showTip(gLanguageCsv.cardNotEnough)
		return
	end
	local cfg = csv.craft.base[1]
	local maxNum = cfg.numMax
	local minVip = cfg.autoSignVIP
	if self.vip:read() < minVip and self.signup >= maxNum then
		gGameUI:showTip(gLanguageCsv.signupNumIsMax)
		return
	end

	-- 服务器数据存在异常，卡牌被分解掉的情况
	local isCardError = false
	local craftCards = gGameModel.craft:read("info").cards
	for _, dbId in pairs(craftCards) do
		local card = gGameModel.cards:find(dbId)
		if not card then
			isCardError = true
			break
		end
	end
	if isCardError or itertools.size(craftCards) < NEED_CARDS then
		local cardEnough = false
		-- 上阵精灵需满足不重复10只
		local cards = gGameModel.role:read("cards")
		local newCards = {}
		if itertools.size(cards) >= 10 then
			local oneKeyAllCards = {}
			for _, dbid in ipairs(cards) do
				local card = gGameModel.cards:find(dbid)
				local cardDatas = card:read("card_id", "fighting_point")
				local cardCfg = csv.cards[cardDatas.card_id]
				local unitCfg = csv.unit[cardCfg.unitID]
				table.insert(oneKeyAllCards, {
					id = dbid,
					fighting_point = cardDatas.fighting_point,
					rarity = unitCfg.rarity,
				})
			end
			table.sort(oneKeyAllCards, function(a, b)
				if a.fighting_point ~= b.fighting_point then
					return a.fighting_point > b.fighting_point
				end
				return a.rarity > b.rarity
			end)
			local hash = {}
			local count = 0
			for _, data in ipairs(oneKeyAllCards) do
				local dbId = data.id
				local cardId = gGameModel.cards:find(dbId):read("card_id")
				local cfg = csv.cards[cardId]
				local cardMarkID = cfg.cardMarkID
				if not hash[cardMarkID] then
					hash[cardMarkID] = true
					table.insert(newCards, dbId)
					count = count + 1
				end
				if count >= NEED_CARDS then
					cardEnough = true
					break
				end
			end
		end
		if not cardEnough then
			gGameUI:showTip(gLanguageCsv.cardNotEnough)
			return
		end
		local isSignup = gGameModel.daily_record:read("craft_sign_up")

		local url = "/game/craft/battle/deploy"
		local tipStr = gLanguageCsv.battleResetSuccess
		if not isSignup then
			url = "/game/craft/signup"
			tipStr = gLanguageCsv.signUpSuccess
		end
		gGameApp:requestServer(url, function(tb)
			gGameUI:stackUI("city.pvp.craft.embattle", nil, {full = true})
			gGameUI:showTip(tipStr)
		end, newCards)
		return
	end
	local isSignup = gGameModel.daily_record:read("craft_sign_up")
	if not isSignup then
		gGameApp:requestServer("/game/craft/signup", function(tb)
			gGameUI:stackUI("city.pvp.craft.embattle", nil, {full = true})
			gGameUI:showTip(gLanguageCsv.signUpSuccess)
		end, craftCards)
		return
	end
	gGameUI:stackUI("city.pvp.craft.embattle", nil, {full = true})
end

return CraftMainView