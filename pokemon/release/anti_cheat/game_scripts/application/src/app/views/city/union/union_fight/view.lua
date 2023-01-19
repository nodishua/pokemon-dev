-- @date:   2020-02-25
-- @desc:   公会战界面
local viewBase = cc.load("mvc").ViewBase
local unionTools = require "app.views.city.union.tools"
local UnionFightView = class("UnionFightView", viewBase)


local function hideChildren(node)
	for _, child in pairs(node:getChildren()) do
		child:hide()
	end
end

local DAILY_STATE = {
	["signup"] = "signup",		-- 报名中
	["prepare"] = "prepare",	-- 准备阶段
	["battle"] = "battle",		-- 战斗中
	["over"] = "over",			-- 结束
	["closed"] = "closed",		-- 关闭
}

local WEEK_STATE_FUNC = {
	[1] = function(self) -- 新一轮预告阶段
			self.btnBM:hide()
			self.vipShow:hide()
			self.leftUnionPanel:hide()
			self:addChildView("city.union.union_fight.closed_view", self:createHandler("onRefesh"))
		end,
	[2] = function(self) -- 预选赛
			local round = self.unionFight.round:read()
			local signUp = self.dailyRecord.signUp:read()
			-- round = DAILY_STATE.signup
			-- signUp = false

			self.btnBM:hide()
			self.vipShow:hide()
			self.leftUnionPanel:show()
			self.dialogPanel:hide()
			self.childPanel:hide()
			if round == DAILY_STATE.signup then
				self.imgYxs:show()
				self.btnBM:visible(not signUp)
				self.vipShow:visible(not signUp)
				self.readyYxs:visible(signUp)
				self:clearCenterPanel()
			elseif round == DAILY_STATE.battle
			or round == DAILY_STATE.prepare then
				self.imgYxs:hide()
				self.btnBM:hide()
				self.vipShow:hide()
				self.rightPanel:hide()
				self:addChildView("city.union.union_fight.fighting_list.yxs", self:createHandler("onRefesh"), self._roundResults)
				self._roundResults = nil
			elseif round == DAILY_STATE.over then
				self.imgYxs:hide()
				self.leftUnionPanel:hide()
				self.rightPanel:hide()
				self.battleInfoPanel:hide()
				self:addChildView("city.union.union_fight.daily_over")
			elseif round == DAILY_STATE.closed then
				self.btnBM:hide()
				self.vipShow:hide()
				self.leftUnionPanel:hide()
				self:addChildView("city.union.union_fight.closed_view", self:createHandler("onRefesh"))
			end
		end,
	[6] = function(self) -- 决赛
			local round = self.unionFight.round:read()
			local signUp = self.dailyRecord.signUp:read()
			local top8 = gGameModel.union_fight:read("top8_vs_info") or {}
			-- round = DAILY_STATE.battle
			-- signUp = false

			self.leftUnionPanel:show()
			self.imgYxs:hide()
			self.btnBM:visible(not signUp and round == DAILY_STATE.signup)
			self.vipShow:visible(not signUp and round == DAILY_STATE.signup)
			self.dialogPanel:hide()
			self.childPanel:hide()

			local isInclude = itertools.include(top8, function(v) -- 是否晋级
				return v[1] == self.unionId
			end)
			if round == DAILY_STATE.closed then
				self.btnBM:hide()
				self.leftUnionPanel:hide()
				self:addChildView("city.union.union_fight.closed_view", self:createHandler("onRefesh"))
			elseif round == DAILY_STATE.over then
				self.battleInfoPanel:hide()
				self.leftUnionPanel:hide()
				local nowTime = time.getNowDate()
				local isFriday = true
				local h, m = dataEasy.getTimeStrByKey("unionFight", "signUpStart", true)
				if nowTime.hour > h or (nowTime.hour == h and nowTime.min >= m) then
					isFriday = false
				end
				if isFriday then
					self.imgYxs:hide()
					self.rightPanel:hide()
					self:addChildView("city.union.union_fight.daily_over")
				else
					self:addChildView("city.union.union_fight.final_over", self:createHandler("addDialogView"))
				end
			elseif isInclude or round == DAILY_STATE.signup then -- 报名阶段 或已晋级
				self:addChildView("city.union.union_fight.finals_view",
					self:createHandler("addDialogView"),
					isInclude,
					self:createHandler("onRefesh")
				)
				if not isInclude then
					self.btnBM:hide()
					self.vipShow:hide()
				end
			else
				-- 其他阶段但是未晋级
				local view = self:addChildView("city.union.union_fight.top8_info_view", true, true, self:createHandler("addDialogView"))
				view:x(600)
			end
		end,
	[7] = function(self) -- 展示期
			local round = self.unionFight.round:read()
			self.btnBM:hide()
			self.imgYxs:hide()
			self.leftUnionPanel:hide()
			self.battleInfoPanel:hide()
			if round == DAILY_STATE.closed then
				self:addChildView("city.union.union_fight.closed_view", self:createHandler("onRefesh"))
			else
				self:addChildView("city.union.union_fight.final_over", self:createHandler("addDialogView"))
			end
		end,
}

-- 固定每天的几个时间点刷新
local REFRESH_TIME_TABLE = {
	{hour = matchLanguage({"en"}) and 11 or 9, min = 30},
	{hour = matchLanguage({"en"}) and 22 or 20, min = 30},
	{hour = matchLanguage({"en"}) and 22 or 20, min = 50},
	{hour = matchLanguage({"en"}) and 23 or 21, min = 00},
	{hour = matchLanguage({"en"}) and 23 or 21, min = 45},
	{hour = matchLanguage({"en"}) and 24 or 22, min = 00},
}

WEEK_STATE_FUNC[5] = WEEK_STATE_FUNC[2]
WEEK_STATE_FUNC[4] = WEEK_STATE_FUNC[2]
WEEK_STATE_FUNC[3] = WEEK_STATE_FUNC[2]

UnionFightView.RESOURCE_FILENAME = "union_fight_main.json"
UnionFightView.RESOURCE_BINDING = {
	["bottomPanel"] = "bottomPanel",
	["bottomPanel.btnStar.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(141, 100, 66, 255)}},
		},
	},
	["bottomPanel.btnRule.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(141, 100, 66, 255)}},
		},
	},
	["bottomPanel.btnRank.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(141, 100, 66, 255)}},
		},
	},
	["bottomPanel.btnReplay.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(141, 100, 66, 255)}},
		},
	},
	["bottomPanel.btnBet.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(141, 100, 66, 255)}},
		},
	},
	["bottomPanel.btnShop.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(141, 100, 66, 255)}},
		},
	},
	["rightPanel.text1"] = {
		varname = "text001",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 4}},
		},
	},
	["imgYxs"] = "imgYxs",
	["imgYxs.ready"] = "readyYxs",
	["imgYxs.text"] = {
		varname = "leftTimeText",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(166, 105, 38, 255), size = 8}},
		},
	},
	["imgYxs.vipShow"] = {
		varname = "vipShow",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(166, 105, 38, 255), size = 8}},
		},
	},
	["childPanel"] = "childPanel",
	["dialogPanel"] = "dialogPanel",
	["bottomPanel.btnTeam"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnTeamClick")}
		},
	},
	["bottomPanel.btnStar"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnStarClick")}
		},
	},
	["bottomPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRuleClick")}
		},
	},
	["bottomPanel.btnRank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRankClick")}
		},
	},
	["bottomPanel.btnReplay"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnReplayClick")}
		},
	},
	["bottomPanel.btnBet"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBetClick")}
		},
	},
	["bottomPanel.btnShop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnShopClick")}
		},
	},
	["battleInfoPanel"] = "battleInfoPanel",
	["battleInfoPanel.before.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("applyClick")}
		},
	},
	["leftUnionPanel"] = "leftUnionPanel",
	["rightPanel"] = "rightPanel",
	["btnBM"] = {
		varname = "btnBM",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBMClick")}
		},
	},
	["rightPanel.item"] = "natureLimitItem",
	["rightPanel.list"] = {
		varname = "natureLimitList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("natureLimitData"),
				item = bindHelper.self("natureLimitItem"),
				onItem = function(list, node, k, v)
					node:texture(ui.ATTR_ICON[v])
				end,
			},
		},
	},
	["leftUnionPanel.item"] = "unionPanelItem",
	["leftUnionPanel.list"] = {
		varname = "unionPanelList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("unionPanelData"),
				item = bindHelper.self("unionPanelItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local children = node:multiget("name", "text1", "text2")
					children.name:text(v.name)
					children.text1:text(v.num)
					children.text2:text("/"..v.max)
				end,
			},
		},
	},
}
UnionFightView.RESOURCE_STYLES = {
	full = true,
}

function UnionFightView:onCreate(data)
	self.text001:getVirtualRenderer():setLineSpacing(-15)
	adapt.setAutoText(self.text001, nil, 650)
	adapt.centerWithScreen("left", "right", nil, {
		{self.bottomPanel, "pos", "left"},
		{self.btnBM, "pos", "right"},
		{self.rightPanel, "pos", "right"},
		{self.imgYxs:get("ready"), "pos", "right"},
	})

	gGameUI.topuiManager:createView("union", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.guild, subTitle = "UNIONFIGHT"})

	self.unionPanelData = idlertable.new({})
	self.weekNatureTb = {}
	for idx, v in csvPairs(csv.union_fight.nature_limit or {}) do
		self.weekNatureTb[v.weekDay] = v.natureLimit
	end

	self.jsAttrData = idlertable.new({})
	self:initModel()
	self:startRefreshTime()
	-- self:refreshCenterPanel()
	self:onReCleanup()
end

function UnionFightView:getWDay()
	local wday = time.getNowDate().wday -- 星期
	wday = wday == 1 and 7 or wday - 1
	-- wday = 6
	return wday
end

function UnionFightView:startRefreshTime()
	local checkTime = function()
		local curTb = time.getNowDate()
		local curTime = time.getTimestamp(curTb)
		for idx, t in ipairs(REFRESH_TIME_TABLE) do
			curTb.hour = t.hour
			curTb.min = t.min
			curTb.sec = 0
			local targetTime = time.getTimestamp(curTb)
			local delta = math.abs(targetTime - curTime)
			if delta <= 1 then
				return true
			end
		end
		return false
	end
	local function updateLeftTimeStr()
		local isSignup = gGameModel.daily_record:read("union_fight_sign_up")
		local curTb = time.getNowDate()
		local curTime = time.getTimestamp(curTb)
		local strFirst =  gLanguageCsv.startTime
		local signUpEndHour, signUpEndMin = dataEasy.getTimeStrByKey("unionFight", "signUpEnd", true)
		if not isSignup and curTb.hour < signUpEndHour or (curTb.hour == signUpEndHour and curTb.min < signUpEndMin) then
			strFirst =  gLanguageCsv.endSignUpTime
		end
		curTb.hour = signUpEndHour
		curTb.min = signUpEndMin
		curTb.sec = 0
		local endTime = time.getTimestamp(curTb)
		local delta = endTime - curTime
		if delta < 1 then
			return true
		end
		self.leftTimeText:text(string.format("%s  %s ", strFirst, time.getCutDown(delta).str))
		return false
	end
	local tag = 03031825
	local delay = 2 * 60 -- 固定时间刷新一次(秒)
	local count = 0
	self:enableSchedule():unSchedule(tag)
	self:enableSchedule()
		:schedule(function(dt)
			count = count + 1
			if checkTime() or count >= delay then
				count = 0 -- 防止重复刷新
				self:onRefesh(function()
					self:refreshCenterPanel()
				end)
			end
		end, 1, 0, tag)

	if matchLanguage({"en"}) and self.unionFight.round:read() == DAILY_STATE.signup then
		tag = 20210519
		self:enableSchedule():unSchedule(tag)
		self:enableSchedule()
			:schedule(function(dt)
				updateLeftTimeStr()
			end, 1, 0, tag)
	end
end

function UnionFightView:initModel()
	local unionFight = gGameModel.union_fight
	self.unionFight = {
		round = unionFight:getIdler("round"),
		signs = unionFight:getIdler("signs"),
		info = unionFight:getIdler("info"),
	}
	local dailyRecord = gGameModel.daily_record
	self.dailyRecord = {
		signUp = dailyRecord:getIdler("union_fight_sign_up")
	}

	local lastRound
	self.unionId = gGameModel.role:read("union_db_id")
	idlereasy.any({self.unionFight.round, self.unionFight.signs, self.unionFight.info, self.dailyRecord.signUp},
		function(_, round, signs, info, signup)
			if self.refreshCenterPanel then
				if lastRound ~= round then -- round发生变化
					self:clearCenterPanel()
				end
				lastRound = round
				self:refreshCenterPanel()
			end
		end):anonyOnly(self, "unionFightMainLoop")

	idlereasy.when(gGameModel.union_fight:getIdler("union_info"), function(_, unionInfo)
		if self.refreshBattleInfo then
			self:refreshBattleInfo(unionInfo)
		end
	end):anonyOnly(self, "unionFightInfoLoop")
end

function UnionFightView:clearCenterPanel()
	if self.view then
		self.view:onClose()
		self.view = nil
	end
	if self.dialogView then
		self.dialogView:onClose()
		self.dialogView = nil
	end
	self.dialogPanel:hide()
	self.childPanel:hide()
end

function UnionFightView:refreshCenterPanel()
	if self.dialogView then return end

	local wday = self:getWDay()
	if wday ~= self.wday then -- 日期发生变化
		self:clearCenterPanel()
	end

	self.wday = wday

	-- 属性限制相关
	self.natureLimitData = self.weekNatureTb[wday] or {}
	self.rightPanel:visible(itertools.size(self.natureLimitData) > 0)

	-- 左侧公会信息刷新
	local signs = self.unionFight.signs:read()
	local t = {}
	local idx = 0
	for k, v in pairs(signs or {}) do
		idx = idx + 1
		table.insert(t, {
			idx = idx,
			num = v[1],
			max = v[2],
			name = v[3],
		})
	end

	table.sort(t, function (a,b)
		if a.num ~= b.num then
			return a.num > b.num
		end
		if a.max ~= b.max then
			return a.max > b.max
		end
		return a.idx < b.idx
	end)

	self.unionPanelData:set(t)

	-- 主界面刷新
	self.vipShow:text(string.format(gLanguageCsv.vipSignupShow, csv.union_fight.base[1].autoSignVIP))
	WEEK_STATE_FUNC[wday](self)
end

function UnionFightView:onReCleanup()
	if self._curViewName then
		self:addChildView(self._curViewName, unpack(self._curViewArgs))
		self._curViewName = nil
	end
	if self._curDialogName then
		self:addDialogView(self._curDialogName, unpack(self._curDialogArgs))
		self._curDialogName = nil
	end
end

function UnionFightView:onCleanup()
	if self.view then
		self._roundResults = self.view.roundResults
	end
	self._curViewName = self.curViewName
	self.curViewName = nil
	self._curViewArgs = self.curViewArgs
	self._curDialogName = self.curDialogName
	self.curDialogName = nil
	self._curDialogArgs = self.curDialogArgs
	self:clearCenterPanel()
	viewBase.onCleanup(self)
end

-- 用子页面的形式打开某个工程
function UnionFightView:addChildView(viewPath, ...)
	if self.curViewName == viewPath and self.view then
		self.childPanel:show()
		self.view:show()
		return self.view
	end
	if self.view then
		self.view:onClose()
		self.view = nil
		self.curViewName = nil
		self.curViewArgs = nil
	end
	local pos = gGameUI:getConvertPos(self, self.childPanel)
	self.view = gGameUI:createView(viewPath):init(...)
		:addTo(self.childPanel, 999)
		:xy(pos)
	self.childPanel:show()
	self.curViewName = viewPath
	self.curViewArgs = {...}
	return self.view
end

-- 用弹窗的形式打开某个工程
function UnionFightView:addDialogView(viewPath, ...)
	if self.curDialogName == viewPath and self.dialogView then
		self.childPanel:show()
		self.dialogView:show()
		return self.dialogView
	end
	if self.dialogView then
		self.dialogView:onClose()
		self.dialogView = nil
		self.curDialogName = nil
		self.curDialogArgs = nil
	end
	self.curDialogName = viewPath
	self.curDialogArgs = {...}
	self.childPanel:hide()
	self.dialogPanel:show()
	local pos = gGameUI:getConvertPos(self, self.dialogPanel)
	local view = gGameUI:createView(viewPath):init(...)
		:addTo(self.dialogPanel, 999)
		:xy(pos)
	self.dialogView = view
	return view
end

function UnionFightView:refreshBattleInfo(unionInfo)
	local round = self.unionFight.round:read()
	self.battleInfoPanel:visible((self.wday ~= 6 and self.wday ~= 7) and round ~= DAILY_STATE.over)
	local round = self.unionFight.round:read()
	local signUp = self.dailyRecord.signUp:read()
	local isBefore = round == "signup"
	local bPanel = self.battleInfoPanel:get("before"):hide()
	local aPanel = self.battleInfoPanel:get("after"):hide()
	local panel = isBefore and bPanel:show() or aPanel:show()
	local children = panel:multiget("note1", "text1", "note2", "text2", "note3", "text3", "btn")
	local empty = gLanguageCsv.emptyInfo
	local text1, text2, text3
	if isBefore then
		text1 = unionInfo.cur_point -- 当前积分
		text2 = unionInfo.cur_rank -- 当前排名
		text3 = unionInfo.sign_num.."/"..unionInfo.member_num -- 报名人数

		text2 = text2 == 0 and empty or text2
	else
		text1 = unionInfo.live_num.."/"..unionInfo.sign_num -- 存活人数
		text3 = unionInfo.last_role_name -- 最高战绩
		text2 = unionInfo.sign_num.."/"..unionInfo.member_num -- 报名人数

		text3 = text3 == "" and empty or text3
	end
	children.text1:text(text1)
	children.text2:text(text2)
	children.text3:text(text3)
	children.note1:setAnchorPoint(cc.p(0,0.5))
	adapt.oneLinePos(children.note1, {children.text1,children.note2,children.text2,children.note3,children.text3, children.btn}, {cc.p(10,0), cc.p(30,0), cc.p(10,0),cc.p(30,0), cc.p(10,0), cc.p(30,0)})
end

-- 我的队伍
function UnionFightView:onBtnTeamClick()
	local combat = gGameModel.union_fight:read("round")
	local apply = gGameModel.daily_record:read("union_fight_sign_up")
	if combat == "over" then
		gGameUI:showTip(gLanguageCsv.unionNoTime)
		return
	end
	if not apply then
		gGameUI:showTip(gLanguageCsv.notSignUp)
		return
	elseif self.wday == 1 then
		gGameUI:showTip(gLanguageCsv.unionUpcoming)
		return
	else
		gGameUI:stackUI("city.union.union_fight.embattle")
	end
end

-- 战斗之星
function UnionFightView:onBtnStarClick()
	local combat = gGameModel.union_fight:read("round")
	local numStarAll = gGameModel.union_fight:read("union_info").battle_star_num
	if numStarAll <= 0 then
		gGameUI:showTip(gLanguageCsv.combatStar)
		return false
	end
	if self.wday ~= 6 or combat ~= "signup" then
		gGameUI:showTip(gLanguageCsv.useCombetStar)
		return false
	end
	gGameUI:stackUI("city.union.union_fight.union_combat_star")
end

-- 规则
function UnionFightView:onBtnRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function UnionFightView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(112),
		c.noteText(20001, 20099),
		c.noteText(125),
		c.noteText(21001, 21099),
		c.noteText(128),
		c.noteText(22001, 22099),
		c.noteText(129),
		c.noteText(22101, 22199),
		c.noteText(130),
		c.noteText(22201, 22299),
		c.noteText(131),
		c.noteText(23001, 23099),
		c.noteText(141),
		c.noteText(22301, 22399),
		c.noteText(132),
	}
	for k, v in orderCsvPairs(csv.union_fight.finalrank) do
		table.insert(context, c.clone(view.awardItem, function(item)
			local childs = item:multiget("text", "list")
			if v.range[2] - v.range[1] == 1 then
				childs.text:text(string.format(gLanguageCsv.rankSingle, v.range[1]))
			else
				childs.text:text(string.format(gLanguageCsv.rankMulti, v.range[1], v.range[2]))
			end
			uiEasy.createItemsToList(view, childs.list, v.award)
		end))
	end
	table.insert(context, c.noteText(133))
	for k, v in orderCsvPairs(csv.union_fight.prerank) do
		table.insert(context, c.clone(view.awardItem, function(item)
			local childs = item:multiget("text", "list")
			if v.range[2] - v.range[1] == 1 then
				childs.text:text(string.format(gLanguageCsv.rankSingle, v.range[1]))
			else
				childs.text:text(string.format(gLanguageCsv.rankMulti, v.range[1], v.range[2]))
			end
			uiEasy.createItemsToList(view, childs.list, v.award)
		end))
	end
	return context
end
-- 排名
function UnionFightView:onBtnRankClick()
	-- body
	gGameUI:stackUI("city.union.union_fight.union_rank")
end
-- 上期回顾
function UnionFightView:onBtnReplayClick()
	local round = self.unionFight.round:read()
	if round == DAILY_STATE.prepare or round == DAILY_STATE.battle or round == DAILY_STATE.closed then
		gGameUI:showTip(gLanguageCsv.unionfightYesterdayLimit)
		return
	end
	if self.wday == 1 or self.wday == 7 then -- 周一周日不让看
		gGameUI:showTip(gLanguageCsv.unionfightYesterdayLimit)
		return
	end
	if self.wday == 2 and round ~= DAILY_STATE.over then -- 周二不打完也不让看
		gGameUI:showTip(gLanguageCsv.unionfightYesterdayLimit)
		return
	end
	if self.wday == 6 and round == DAILY_STATE.over then -- 周六已打完也不让看
		gGameUI:showTip(gLanguageCsv.unionfightYesterdayLimit)
		return
	end
	gGameApp:requestServer("/game/union/fight/yesterday/battle", function(tb)
		if not next(tb.view.round_results or {}) then
			gGameUI:showTip(gLanguageCsv.unionFightNoReplay)
			return
		end
		self:addDialogView("city.union.union_fight.fighting_list.battle_review", tb.view.round_results, tb.view.union_info)
	end)
end
-- 押注
function UnionFightView:onBtnBetClick()
	local combat = gGameModel.union_fight:read("round")
	if self.wday ~= 6 or combat ~= "signup" then
		gGameUI:showTip(gLanguageCsv.union_bet)
		return
	else
		gGameApp:requestServer("/game/union/fight/bet/info",function(tb)
			gGameUI:stackUI("city.union.union_fight.union_bet",nil, nil, tb.view)
		end)
	end
end

-- 商店
function UnionFightView:onBtnShopClick()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/union/shop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.UNION_FIGHT_SHOP)
		end)
	end
end
-- 报名按钮
function UnionFightView:onBtnBMClick()
	-- local applyTab = gGameModel.role:read("union_fight_sign_cards_check")
	-- if self.wday ~= 1 then
	-- 	if applyTab[self.wday] then
	-- 		gGameApp:requestServer("/game/union/fight/signup", function(tb) end)
	-- 	else
	-- 		gGameUI:showTip(gLanguageCsv.unionFightCardNotEnough)
	-- 	end
	-- else
	-- 	gGameUI:showTip(gLanguageCsv.unionFightCardNotEnough)
	-- 	return
	-- end
	gGameApp:requestServerCustom("/game/union/fight/signup")
		:onErrCall(function(err)
			if gLanguageCsv[err.err] then
				gGameUI:showTip(gLanguageCsv[err.err])
			end
		end)
		:params()
		:doit(function(tb)
		end)
	return
end

function UnionFightView:onRefesh(cb)
	if self.inRefresh then return end
	self.inRefresh = true
	gGameApp:requestServer("/game/union/fight/battle/main", function(tb)
		if cb then cb() end
		self.inRefresh = nil
	end)
end

function UnionFightView:onClose()
	if self.dialogView then
		self.dialogView:onClose()
		self.dialogView = nil
		self.dialogPanel:hide()
		if self.view then
			self.childPanel:show()
		end
		self.curDialogName = nil
		self.curDialogArgs = nil
	else
		if self.view then
			self.view:onClose()
			self.view = nil
		end
		viewBase.onClose(self)
	end
end

--查看公会报名情况
function UnionFightView:applyClick()
	gGameUI:stackUI("city.union.union_fight.union_apply")
end

return UnionFightView