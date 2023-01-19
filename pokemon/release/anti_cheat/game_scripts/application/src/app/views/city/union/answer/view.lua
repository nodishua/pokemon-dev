-- @date:   2020-12-23
-- @desc:   精灵问答主界面
local ViewBase = cc.load("mvc").ViewBase
local UnionAnswerView = class("UnionAnswerView", ViewBase)

local function setBtnState(btn, state)
	cache.setShader(btn, false, state and "normal" or "hsl_gray")
	if state then
		text.addEffect(btn:get("text"), {glow={color=ui.COLORS.GLOW.WHITE}})
	else
		text.deleteAllEffect(btn:get("text"))
		text.addEffect(btn:get("text"), {color = ui.COLORS.DISABLED.WHITE})
	end
end

UnionAnswerView.RESOURCE_FILENAME = "union_answer.json"
UnionAnswerView.RESOURCE_BINDING = {
	["rank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankClick")},
		},
	},
	["rule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")},
		},
	},
	["battomPanel.startBtn"] = {
		varname = "startBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")},
		},
	},
	["battomPanel.addIcon"] = {
		varname = "addIcon",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")},
		},
	},
	["rank.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(252, 251, 223, 255)}},
		},
	},

	["rule.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(252, 251, 223, 255)}},
		},
	},
	["empty"] = "empty",
	["topPanel"] = "topPanel",
	["topPanel.battom"] = "topBattom",
	["topPanel.item"] = "item",
	["topPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("rank", "name", "num")
					childs.rank:text(k)
					childs.name:text(v.name)
					childs.num:text(v.num)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["battomPanel"] = "battomPanel",
	["topPanel.unionBtn"] = {
		varname = "unionBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onunionClick")},
		},
	},
	["topPanel.personBtn"] = {
		varname = "personBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onpersonClick")},
		},
	},
	["topPanel.title"] = "topTitle",
	["battomPanel.text1"] = "text1",
	["battomPanel.text2"] = "text2",
	["battomPanel.textNum"] = "textNum",
	["timePanel"] = "timePanel",
	["timePanel.timeNum"] = "timeNum",
	["timePanel.timeTxt"] = "timeTxt",
	["timePanel.title"] = "titleIcon",
}

function UnionAnswerView:onCreate(tb)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.pokemonAnswer, subTitle = "POKEMONANSWER"})

	self:enableSchedule()
	self:initModel()
	self.data = tb.view
	local round = self.data.round
	self.round = idler.new(round)
	self.roleData = idlers.new({})
	self.unionData = idlers.new({})
	self.myRoleData = idlers.new({})
	self.myUnionData = idlers.new({})
	self.roleData:update(self.data.role_ranks or {})
	self.unionData:update(self.data.union_ranks or {})
	self.myRoleData:update(self.data.my_rank or {})
	self.myUnionData:update(self.data.my_union_rank or {})
	self.servers = self.data.servers
	self.rankType = idler.new(1)
	self.tabDatas = idlers.new({})
	self.list:setScrollBarEnabled(true)
	self.qaAnswerTimes = gCommonConfigCsv.unionQATimes
	local buyTimes = gCommonConfigCsv.unionQABuyTimes
	local timePosX = self.timeNum:x()

	idlereasy.any({self.rankType, self.roleData, self.round, self.unionData}, function (_, rankType, roleData, round, unionData)
		self.data.role_ranks = roleData
		self.data.union_ranks = unionData
		self.unionBtn:setBright(rankType == 1)
		self.personBtn:setBright(rankType == 1)
		text.addEffect(self.unionBtn:get("text"), {color = rankType == 1 and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED})
		text.addEffect(self.personBtn:get("text"), {color = rankType == 1 and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.WHITE})
		local tabDatas = {}
		if rankType == 1 then
			for k, v in ipairs(unionData) do
				table.insert(tabDatas, {name = v:read().name, num = v:read().score})
			end
			if round == "start" then
				self.topTitle:text(gLanguageCsv.unionRank)
			else
				self.topTitle:text(gLanguageCsv.preUnionRank)
			end
		else
			for k, v in ipairs(roleData) do
				table.insert(tabDatas, {name = v:read().name, num = v:read().score})
			end
			if round == "start" then
				self.topTitle:text(gLanguageCsv.personalRank)
			else
				self.topTitle:text(gLanguageCsv.prePersonalRank)
			end
		end
		self.tabDatas:update(tabDatas)

		if not itertools.isempty(unionData) then
			self.empty:hide()
			self.unionBtn:show()
			self.personBtn:show()
		else
			self.empty:show()
			self.unionBtn:hide()
			self.personBtn:hide()
		end
	end)

	idlereasy.any({self.rankType, self.myUnionData, self.myRoleData}, function(_, rankType, myUnionData, myRoleData)
		self.data.my_rank = myRoleData
		self.data.my_union_rank = myUnionData
		if rankType == 1 then
			if myUnionData.rank and myUnionData.rank:read() ~= 0 then
				self.topBattom:show()
				local childs = self.topBattom:multiget("num", "rank", "name")
				if myUnionData.score then
					childs.num:text(myUnionData.score:read())
				end
				if myUnionData.rank then
					childs.rank:text(myUnionData.rank:read())
				end
				if myUnionData.name then
					childs.name:text(myUnionData.name:read())
				end
			else
				self.topBattom:hide()
			end
		else
			if myRoleData.rank and myRoleData.rank:read() ~= 0 then
				self.topBattom:show()
				local childs = self.topBattom:multiget("num", "rank", "name")
				if myRoleData.score then
					childs.num:text(myRoleData.score:read())
				end
				if myRoleData.rank then
					childs.rank:text(myRoleData.rank:read())
				end
				if myRoleData.name then
					childs.name:text(self.roleId)
				end
			else
				self.topBattom:hide()
			end
		end
	end)

	self.text2:text(string.format(gLanguageCsv.unionAnswerShowTimes, gCommonConfigCsv.unionQATimes + gCommonConfigCsv.unionQABuyTimes))

	idlereasy.any({self.qaTimes, self.qaBuyTimes}, function (_, qaTimes, qaBuyTimes)
		self.qaAnswerTimes = gCommonConfigCsv.unionQATimes + qaBuyTimes - qaTimes
		self.textNum:text(self.qaAnswerTimes)
		if qaTimes - gCommonConfigCsv.unionQATimes - gCommonConfigCsv.unionQABuyTimes >= 0 then
			setBtnState(self.startBtn, false)
		else
			setBtnState(self.startBtn, true)
		end
		if qaBuyTimes >= gCommonConfigCsv.unionQABuyTimes then
			self.addIcon:hide()
		else
			self.addIcon:show()
		end
		adapt.oneLineCenterPos(cc.p(1205, 155), {self.text1, self.textNum, self.addIcon}, cc.p(15, 0))
	end)

	idlereasy.when(self.round, function(_, round)
		if round == "start" then
			self.battomPanel:show()
			self:initCountDown()
			self.timeTxt:show()
			self.startBtn:show()
			self.titleIcon:texture("city/union/answer/txt_jlwdjxz.png")
		else
			self.battomPanel:hide()
			self.timeTxt:hide()
			self:timeToOpen()
			self.startBtn:hide()
			self.titleIcon:texture("city/union/answer/txt_jlwdcbz.png")
		end
	end)
end

function UnionAnswerView:initModel()
	self.qaTimes = gGameModel.daily_record:getIdler("union_qa_times")
	self.qaBuyTimes = gGameModel.daily_record:getIdler("union_qa_buy_times")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.roleId = gGameModel.role:read("name")
end

function UnionAnswerView:onunionClick()
	self.rankType:set(1)
end

function UnionAnswerView:onpersonClick()
	self.rankType:set(2)
end

function UnionAnswerView:initCountDown()
	local textTime = self.timeNum
	local today = time.getTodayStrInClock(0)
	local nowDate = time.getNowDate()
	local endStamp = 0

	if nowDate.wday == 1 then -- 周日
		endStamp = time.getNumTimestamp(today, 5) + 19*3600

	elseif nowDate.wday == 7 then -- 周六
		endStamp = time.getNumTimestamp(today, 5) + 24 * 3600 + 19*3600
	end
	local function setLabel()
		local remainTime = time.getCutDown(endStamp - time.getTime())
		textTime:text(remainTime.str)
		if endStamp - time.getTime() <= 0 then
			return false
		end
		adapt.oneLineCenterPos(cc.p(350, 94), {self.timeTxt, self.timeNum}, cc.p(15, 0))
		return true
	end
	self:enableSchedule():schedule(function(dt)
		if not setLabel() then
			self:unSchedule("CountDown1")
			return false
		end
	end, 1, 0, "CountDown1")
end

function UnionAnswerView:timeToOpen()
	local day = csv.cross.union_qa.base[1].servOpenDays
		local isUnionAnswerDay = dataEasy.serverOpenDaysLess(day)
		if isUnionAnswerDay then
			local str = string.format(gLanguageCsv.unlockServerOpen, day)
			gGameUI:showTip(str)
			return
		end
	local serverId = dataEasy.getCrossServiceData("crossunionqa", csv.cross.union_qa.base[1].servOpenDays)
	if serverId then
		local _, todayM, todayD = time.getYearMonthDay(csv.cross.service[serverId].date)
		local _, endStampM , endStampD = time.getYearMonthDay(csv.cross.service[serverId].endDate)
		self.timeNum:text(string.format(gLanguageCsv.unionAnswerOpenTimeShow, todayM, todayD, endStampM, endStampD))
	else
		self.timeNum:text(gLanguageCsv.comingSoon)
	end
	adapt.oneLineCenterPos(cc.p(350, 94), {self.timeTxt, self.timeNum}, cc.p(15, 0))
end

function UnionAnswerView:onSureClick()
	if self.qaAnswerTimes > 0 then
		gGameApp:requestServer("/game/union/qa/prepare",function (tb)
			self.tbData = tb.view
			gGameUI:stackUI("city.union.answer.problem", nil, {full = true}, self:createHandler("sendParams"))
		end)
	else
		local buyTimes = gCommonConfigCsv.unionQABuyTimes
		if buyTimes - self.qaBuyTimes:read() > 0 then
			local cost = gCommonConfigCsv.unionQABuyCost
			local content = "#C0x5b545b#"..string.format(gLanguageCsv.pokemonAnswerBuyTimes, cost)
			gGameUI:showDialog({content = content, cb = function()
				if self.rmb:read() >= cost then
					gGameApp:requestServer("/game/union/qa/buy", function (tb)
						gGameApp:requestServer("/game/union/qa/prepare",function (tb)
							self.tbData = tb.view
							gGameUI:stackUI("city.union.answer.problem", nil, {full = true}, self:createHandler("sendParams"))
						end)
					end)
				else
					uiEasy.showDialog("rmb", nil, {dialog = true})
				end
			end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
		else
			gGameUI:showTip(gLanguageCsv.unionAnswerTipsText2)
		end
	end
end

function UnionAnswerView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function UnionAnswerView:onRankClick()
	if self.round:read() ~= "" then
		gGameApp:requestServer("/game/union/qa/rank",function (tb)
			gGameUI:stackUI("city.union.answer.rank", nil, nil ,tb)
		end)
	else
		gGameUI:showTip(gLanguageCsv.unionAnswerRankTipsText)
	end
end

function UnionAnswerView:onAddClick()
	local buyTimes = gCommonConfigCsv.unionQABuyTimes
	local cost = gCommonConfigCsv.unionQABuyCost
	if buyTimes - self.qaBuyTimes:read() > 0 then
		local content = "#C0x5b545b#"..string.format(gLanguageCsv.pokemonAnswerBuyTimes, cost)
		gGameUI:showDialog({content = content, cb = function()
			if self.rmb:read() >= cost then
				gGameApp:requestServer("/game/union/qa/buy",function (tb)
					gGameUI:showTip(gLanguageCsv.unionAnswerTipsText)
				end)
			else
				uiEasy.showDialog("rmb", nil, {dialog = true})
			end
		end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
	else
		gGameUI:showTip(gLanguageCsv.unionAnswerTipsText1)
	end
end

function UnionAnswerView:getRuleContext(view)
	local nowAwardData
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.unionAnswerRule)
		end),
		c.noteText(112001, 112100),
	}
	local servers = self.servers
	if servers then
		local t = arraytools.map(getMergeServers(servers), function(k, v)
			return string.format(gLanguageCsv.brackets, getServerArea(v, nil, true))
		end)
		if self.round:read() == "start" then
			table.insert(context, 2, "#C0x5B545B#" .. gLanguageCsv.currentServers .. table.concat(t, ","))
		else
			table.insert(context, 2, "#C0x5B545B#" .. gLanguageCsv.preServers .. table.concat(t, ","))
		end
	end
	local qaUnionRank = csv.cross.union_qa.union_rank
	local qaRoleRank = csv.cross.union_qa.role_rank
	for k, v in orderCsvPairs(qaUnionRank) do
		table.insert(context, c.clone(view.awardItem, function(item)
			local preRoleRank = qaUnionRank[k - 1] and qaUnionRank[k - 1].rankMax or 0
			local childs = item:multiget("text", "list")
			if v.rankMax - preRoleRank == 1 then
				childs.text:text(string.format(gLanguageCsv.rankSingle, v.rankMax))
			else
				childs.text:text(string.format(gLanguageCsv.rankMulti, preRoleRank + 1, v.rankMax))
			end
			uiEasy.createItemsToList(view, childs.list, v.award)
		end))
	end
	table.insert(context, c.noteText(112101))
	for k, v in orderCsvPairs(qaRoleRank) do
		table.insert(context, c.clone(view.awardItem, function(item)
			local preUnionRank = qaRoleRank[k - 1] and qaRoleRank[k - 1].rankMax or 0
			local childs = item:multiget("text", "list")
			if v.rankMax - preUnionRank == 1 then
				childs.text:text(string.format(gLanguageCsv.rankSingle, v.rankMax))
			else
				childs.text:text(string.format(gLanguageCsv.rankMulti, preUnionRank + 1, v.rankMax))
			end
			uiEasy.createItemsToList(view, childs.list, v.award)
		end))
	end
	return context
end

function UnionAnswerView:sendParams(branch)
	return self.tbData, self.roleData, self.unionData, self.myRoleData, self.myUnionData
end

return UnionAnswerView