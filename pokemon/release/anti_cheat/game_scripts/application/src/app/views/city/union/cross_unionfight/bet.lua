-- @date:   2021-09-10
-- @desc:   1.竞猜界面

local SHOW_TYPE = {
	showIcon = 1,
	showPanel = 2,
	hide = 3,
}

local ViewBase = cc.load("mvc").ViewBase
local BetView = class("BetView", ViewBase)

BetView.RESOURCE_FILENAME = "cross_union_fight_bet.json"
BetView.RESOURCE_BINDING = {
	["leftPanel.leftItem"] = "leftItem",
	["leftPanel.text1"] = "text1",
	["leftPanel.text2"] = "text2",
	["leftPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("select")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
						panel:get("subTxt"):text(v.subName)
					end
					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.cellClick, k, v.name)}})
					if v.lock then
						uiEasy.updateUnlockRes(nil, normal, {pos = cc.p(290, 120)})
					end
				end,
			},
			handlers = {
				cellClick = bindHelper.self("onLeftItemClick"),
			},
		},
	},
	["rightPanel.txt1"] = "txt1",
	["leftPanel.textTime"] = {
		binds = {
			event = "effect",
			data = {
				color = cc.c4b(107, 238, 107, 255),
				outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["rightPanel.ruleBtn"] = {
		varname = "ruleBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleBtnClick")},
		},
	},
	["item"] = "item",
	["rightPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData"),
				showTab = bindHelper.self("showTab"),
				--isGray = bindHelper.self("grayData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("unionIcon", "unionName", "serverKey", "fightingPoint", "panel", "iconBg", "bg", "line")
					childs.iconBg:hide()
					childs.panel:show()
					if v.bet == SHOW_TYPE.showIcon then
						childs.iconBg:show()
						childs.panel:hide()
					elseif v.bet == SHOW_TYPE.hide then
						childs.iconBg:hide()
						childs.panel:hide()
					else
						childs.iconBg:hide()
						childs.panel:show()
					end
					childs.panel:get("costNum"):text(v.cost[1].num)
					childs.unionName:text(v.union_name)
					childs.serverKey:text(getServerArea(v.server_key, false))
					childs.fightingPoint:text(v.fighting_point)
					cache.setShader(childs.panel:get("btn"), false, v.grayData and  "hsl_gray" or  "normal")
					bind.touch(list, childs.panel:get("btn"), {methods = {ended = functools.partial(list.clickGuess, v.union_db_id)}})
					adapt.oneLineCenterPos(cc.p(childs.panel:get("btn"):x(), childs.panel:get("btn"):y() + 80), {childs.panel:get("icon"), childs.panel:get("costNum")}, cc.p(10, 0))
					childs.unionIcon:texture(csv.union.union_logo[v.union_logo].icon)
					if k % 2 == 0 then
						childs.bg:color(cc.c4b(255, 252, 237, 128))
					else
						childs.bg:color(cc.c4b(238, 231, 215, 153))
					end
					if k >= 4 then
						childs.line:hide()
					end
				end,
			},
			handlers = {
				clickGuess = bindHelper.self("onGuessBtnClick"),
			},
		},
	},
	["rightPanel.topPanel.stateTxt"] = "topStateTxt",
	["rightPanel.topPanel.unionIcon"] = "unionIcon",
	["rightPanel.topPanel.unionName"] = "unionName",
	["rightPanel"] = "rightPanel"
}

function BetView:onCreate(data, rankData)
	gGameUI.topuiManager:createView("union", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.guess, subTitle = "BET"})
	self.data = data
	self.rankData = rankData
	self.originBet = data.bets
	self.betData = {}
	self:initModel()
	self.item:hide()
	self.leftItem:hide()
	self.showTab = idler.new(1)
	self.showData = idlertable.new({})
	self:handleBetData()
	self.grayData = false
	self.leftDatas = idlers.newWithMap({
		{name = gLanguageCsv.easternConstructionGroup, subName = "Eastern"},
		{name = gLanguageCsv.westernConstructionGroup, subName = "Western"},
		{name = gLanguageCsv.southernConstructionGroup, subName = "Southern"},
		{name = gLanguageCsv.northernConstructionGroup, subName = "Northern "},
		{name = gLanguageCsv.finalMatch, subName = "FinalMatch", lock = true},
	})

	self.showTab:addListener(function(val, oldval)
		self.leftDatas:atproxy(oldval).select = false
		self.leftDatas:atproxy(val).select = true
		self:handleBetData()
		self:refreshTopIcon()
		self:setButtonStatus(self.status:read(), val)
	end)
	idlereasy.when(self.status,function(_, status)
		local show = userDefault.getForeverLocalKey("crossUnionFightShowed", {})
		if status == "start" or status == "prePrapare" or status == "preStart" or status == "preBattle" or status == "preOver" or status == "preAward"  then
			self.leftDatas:atproxy(5).lock = true
		elseif status == "topPrepare" or  status == "topStart"  or  status == "topBattle" or status == "topOver" or status == "closed" then
			self.leftDatas:atproxy(5).lock = false
		end

		local getRightStatus = function(st)
			return (st == "preAward" or st == "topPrepare" or
					st== "topStart"  or  st == "topBattle" or
					st == "topOver" or st == "closed") and true or false
		end
		self:handleBetData()
		if not itertools.isempty(show) and itertools.size(self.bet) > 0 then
			local num = tonumber(time.getTodayStr()) - show.time
			if num < 28 then
				if show.type == 1 and getRightStatus(status)  then
					userDefault.setForeverLocalKey("crossUnionFightShowed", {})
					gGameUI:stackUI("city.union.cross_unionfight.bet_result", nil, nil, self.bet, show.type+3)

				elseif show.type == 2 and status == "closed" then
					userDefault.setForeverLocalKey("crossUnionFightShowed", {})
					gGameUI:stackUI("city.union.cross_unionfight.bet_result", nil, nil, self.bet, show.type+3)
				end
			end
		end
		self:setButtonStatus(status, self.showTab:read())
	end)

	self.text1:text(gLanguageCsv.crossUnionFightBetTips1)
	self.text2:text(gLanguageCsv.crossUnionFightBetTips2)
	self:addTabListClipping()
end

function BetView:setButtonStatus(status, showTab)
	local nowTime = time.getTime()
	local startTime = time.getNumTimestamp(tonumber(time.getTodayStr()), 9, 0)
	if status == "prePrepare" and nowTime > startTime then
		self.grayData = false
	elseif status == "topPrepare" and showTab == 5 then
		self.grayData = false
	else
		self.grayData = true
	end
	if showTab == 5 then
		for i, v in pairs(self.topData) do
			v.grayData = self.grayData
		end
		self.showData:set(self.topData ,true)
	else
		for i, v in pairs(self.preData[showTab]) do
			v.grayData = self.grayData
		end
		self.showData:set(self.preData[showTab], true)
	end
end

function BetView:refreshTopIcon()
	local dt = self.showTab:read() == 5 and self.topData or self.preData[self.showTab:read()]
	local betUnion = nil
	for k, v in ipairs(dt) do
		if v.bet == SHOW_TYPE.showIcon then
			betUnion = v
			self.unionIcon:show()
			self.unionIcon:texture(csv.union.union_logo[v.union_logo].icon)
			self.topStateTxt:text(gLanguageCsv.beted)
			self.unionName:text(v.union_name)
			text.addEffect(self.topStateTxt, {color=cc.c4b(74, 148, 205, 255)})
			break
		end
		self.unionIcon:hide()
		text.addEffect(self.topStateTxt, {color=cc.c4b(151, 143, 137, 255)})
		self.unionName:text("")
		self.topStateTxt:text(gLanguageCsv.notBet)
	end

	if self.rankData and self.rankData.last_ranks then
		local rank = self.rankData.last_ranks[self.showTab:read()]
		if rank and betUnion and rank[1]then
			if rank[1].union_db_id == betUnion.union_db_id then
				self.topStateTxt:text(gLanguageCsv.betSuccess)
				text.addEffect(self.topStateTxt, {color=cc.c4b(255, 125, 29, 255)})
			else
				self.topStateTxt:text(gLanguageCsv.betFail)
				text.addEffect(self.topStateTxt, {color=cc.c4b(113, 119, 153, 255)})
			end
			self.unionIcon:texture(csv.union.union_logo[rank[1].union_logo].icon)
			self.unionName:text(rank[1].union_name)
		end
	end
end

function BetView:handleBetData()
	local sd = self.showTab:read() == 5 and self.topData or (self.preData[self.showTab:read()] or {})
	for k, v in ipairs(sd) do
		v.cost = self.showTab:read() == 5 and dataEasy.getItemData(csv.cross.union_fight.base[1].top4BetCost) or dataEasy.getItemData(csv.cross.union_fight.base[1].preBetCost)
	end
	local bat = self.originBet[self.showTab:read()] or {}
	local data = self.showTab:read() ~= 5 and self.preData[self.showTab:read()] or self.topData
	for k, v in pairs(bat) do
		for nk, nv in pairs(v.role_keys) do
			if nv[2] == self.userId then
				for fk, fv in ipairs(data) do
					fv.bet = SHOW_TYPE.hide
					if k == fv.union_db_id then
						fv.bet = SHOW_TYPE.showIcon
					end
				end
			end
		end
	end
	if self.showTab:read() == 5 then
		self.showData:set(self.topData ,true)
	else
		self.showData:set(self.preData[self.showTab:read()], true)
	end

	--guess_win界面数据处理
	local t = {}
	if not itertools.isempty(self.preData) then
		for k, v in pairs(self.preData) do
			for nk, nv in ipairs(v) do
				table.insert(t, nv)
			end
		end
	end
	if not itertools.isempty(self.topData) then
		for k, v in pairs(self.topData) do
			table.insert(t, v)
		end
	end
	local data = {}
	for gk, gv in pairs(self.originBet) do
		for uk, uv in pairs(gv) do
			for rk, rv in pairs(uv.role_keys) do
				if rv[2] == self.userId then
					for fk, fv in ipairs(t) do
						if uk == fv.union_db_id then
							data[gk] = {union_db_id = uk, success = uv.success, union_name = fv.union_name, union_logo = fv.union_logo}
						end
					end

				end
			end
		end
	end
	self.bet = data
end

function BetView:initModel()
	self.preData = gGameModel.cross_union_fight:read("pre_battle_groups") or {{},{},{},{}}
	self.status = gGameModel.cross_union_fight:getIdler("status")
	self.topData = gGameModel.cross_union_fight:read("top_battle_groups") or {}
	if self.status:read() == "closed" then
		self.lastBattle = gGameModel.cross_union_fight:read("last_battle_groups") or {}
		self.unions = gGameModel.cross_union_fight:read("unions") or {}
		local preData, topData = {{},{},{},{}}, {}
		for i, v in ipairs(self.lastBattle) do
			if i == 5 then
				for key, val in pairs(v) do
					topData[key] = self.unions[val]
				end
			else
				for key, val in pairs(v) do
					preData[i][key] = self.unions[val]
				end
			end

		end
		self.preData = preData
		self.topData = topData
	end
	self.userId = gGameModel.role:read("id")
	self.preData = itertools.isempty(self.preData) and {{},{},{},{}} or self.preData

	for i, v in pairs(self.topData) do
		v.grayData = true
	end
	for i, v in pairs(self.preData) do
		for key, val in pairs(v) do
			val.grayData = true
		end
	end

end

function BetView:onRuleBtnClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1326})
end

function BetView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rule)
		end),
		c.noteText(125601, 125699),
	}
	return context
end

function BetView:onGuessBtnClick(node, id)
	local function cb()
		local cost = {}
		if self.showTab:read() == 5 then
			for k, v in csvMapPairs(csv.cross.union_fight.base[1].top4BetCost) do
				cost[k] = v
			end
		else
			for k, v in csvMapPairs(csv.cross.union_fight.base[1].preBetCost) do
				cost[k] = v
			end
		end
		--公会币不够
		local can = false
		for k, v in pairs(cost) do
			local num = dataEasy.getNumByKey(k)
			if num < v then
				gGameUI:showTip(gLanguageCsv.cuildCurrencyNotEnough)
				can = false
				break
			end
			can = true
		end
		if can then
			gGameApp:requestServer("/game/cross/union/fight/bet", function (tb)
				self.originBet = tb.view.bets
				self:handleBetData()
				self:refreshTopIcon()
				userDefault.setForeverLocalKey("crossUnionFightShowed", {type = self.showTab:read() ~= 5 and 1 or 2, time = tonumber(time.getTodayStr())})
			end, self.showTab:read(), id)
		end
	end
	local str = self.showTab:read() == 5 and string.format(gLanguageCsv.finalMatchTip, dataEasy.getItemData(csv.cross.union_fight.base[1].top4BetCost)[1].num)
		or string.format(gLanguageCsv.preliminaryMatchTip, dataEasy.getItemData(csv.cross.union_fight.base[1].preBetCost)[1].num)
	local key = "crossUnionFightBet"
	local state = userDefault.getCurrDayKey(key, "first")
	if state == "first" then
		state = "true"
		userDefault.setCurrDayKey(key, state)
	end
	local nowTime = time.getTime()
	local startTime = time.getNumTimestamp(tonumber(time.getTodayStr()), 9, 0)
	if (self.status:read() == "prePrepare" and nowTime > startTime) or (self.status:read() == "topPrepare" and self.showTab:read() == 5) then
		if state == "first" or state == "true" then
			if self.status:read() == "topPrepare" and self.showTab:read() == 5 then
				gGameUI:showDialog({content = str, cb = cb, isRich = true, btnType = 2, fontSize = 40, align = "center"})
			else
				gGameUI:showDialog({content = str, cb = cb, isRich = true, btnType = 2, selectKey = key, selectType = 2, fontSize = 40, align = "center"})
			end
		else
			cb()
		end
	else
		gGameUI:showTip(gLanguageCsv.crossUnionFightDoNotBet)
	end
end

function BetView:onLeftItemClick(list, index, str)
	--初赛阶段,决赛锁住
	if self.leftDatas:at(index):read().lock then
		if self.leftDatas:at(5).oldval.lock then
			gGameUI:showTip(gLanguageCsv.finalMatchNotStart)
		end
	else
		self.showTab:set(index)
		self.txt1:text(str)
	end
end

-- 页签 list 裁剪处理
function BetView:addTabListClipping()
	local list = self.list
	list:retain()
	list:removeFromParent()
	local size = list:size()
	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(cc.rect(48, 0, size.width, size.height), "city/union/cross_unionfight/box_jc_mask.png")
	mask:size(size)
		:anchorPoint(0, 0)
		:xy(list:xy())
	cc.ClippingNode:create(mask)
	  :setAlphaThreshold(0.1)
	  :add(list)
	  :addTo(self.rightPanel, list:z())
	list:release()
end

return BetView