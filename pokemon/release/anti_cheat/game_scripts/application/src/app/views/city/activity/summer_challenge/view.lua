-- @date 2021-06-28
-- @desc 夏日挑战

-- 最大关卡数
local MAX_FLOOR = 10

local POS_TAB = {
	[1] = {cc.p(0, 954), cc.p(106, 880), cc.p(322, 1096), cc.p(502, 1064), cc.p(687, 930), cc.p(1120, 1136), cc.p(1362, 978), cc.p(1210, 890), cc.p(1330, 765), cc.p(1269, 714), cc.p(1005, 669), cc.p(594, 472), cc.p(719, 405), cc.p(397, 176), cc.p(658, 0), cc.p(0, 0)},
	[2] = {cc.p(0, 1440), cc.p(0, 954), cc.p(106, 880), cc.p(322, 1096), cc.p(502, 1064), cc.p(687, 930), cc.p(1120, 1136), cc.p(1280, 1250), cc.p(981, 1440)},
	[3] = {cc.p(981, 1440), cc.p(1280, 1250), cc.p(1120, 1136), cc.p(1362, 978), cc.p(1472, 1109), cc.p(1597, 1293), cc.p(1773, 1122), cc.p(2138, 1296), cc.p(2168, 1274), cc.p(2464, 1440)},
	[4] = {cc.p(3120, 1440), cc.p(2464, 1440), cc.p(2168, 1274), cc.p(2138, 1296), cc.p(1773, 1122), cc.p(1973, 1013), cc.p(2029, 1064), cc.p(2146, 1069), cc.p(2176, 928), cc.p(2389, 786), cc.p(2842, 968), cc.p(3120, 792)},
	[5] = {cc.p(3120, 0), cc.p(3120, 792), cc.p(2842, 968), cc.p(2389, 786), cc.p(2088, 621), cc.p(2200, 658), cc.p(2349, 594), cc.p(2434, 319), cc.p(2501, 279), cc.p(2488, 122), cc.p(2706, 0)},
	[6] = {cc.p(2706, 0), cc.p(2488, 122), cc.p(2501, 279), cc.p(2434, 319), cc.p(2349, 594), cc.p(2200, 658), cc.p(2088, 621), cc.p(2101, 528), cc.p(1933, 450), cc.p(1885, 410), cc.p(1904, 261), cc.p(2042, 165), cc.p(2040, 96), cc.p(1896, 0)},
	[7] = {cc.p(1896, 0), cc.p(2040, 96), cc.p(2042, 165), cc.p(1904, 261), cc.p(1885, 410), cc.p(1933, 450), cc.p(1762, 541), cc.p(1621, 594), cc.p(1528, 632), cc.p(1330, 765), cc.p(1269, 714), cc.p(1005, 669), cc.p(1093, 490), cc.p(1213, 394), cc.p(1253, 272), cc.p(1168, 162), cc.p(1200, 77), cc.p(1354, 0)},
	[8] = {cc.p(1354, 0), cc.p(1200, 77), cc.p(1168, 162), cc.p(1253, 272), cc.p(1213, 394), cc.p(1093, 490), cc.p(1005, 669), cc.p(594, 472), cc.p(719, 405), cc.p(397, 176), cc.p(658, 0)},
	[9] = {cc.p(1973, 1013), cc.p(2029, 1064), cc.p(2146, 1069), cc.p(2176, 928), cc.p(2389, 786), cc.p(2088, 621), cc.p(2101, 528), cc.p(1933, 450), cc.p(1762, 541), cc.p(1621, 594), cc.p(1578, 762), cc.p(1957, 896)},
	[10] = {cc.p(1957, 896), cc.p(1578, 762), cc.p(1621, 594), cc.p(1528, 632), cc.p(1330, 765), cc.p(1210, 890), cc.p(1362, 978), cc.p(1472, 1109), cc.p(1597, 1293), cc.p(1773, 1122), cc.p(1973, 1013)},
}

-- 关卡状态
local GATE_STATE = {
	LOCK = 1,
	CANT_CHALLENGE = 2,
	CAN_CHALLENGE = 3,
	PASSED = 4,
}

local function panelHide(Panel)
	Panel:hide()
	Panel:stopAllActions()
end

local function getMonthInEn(month)
	local monthArr = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sept","Oct","Nov","Dec"}
	return monthArr[tonumber(month)]
end

-- 关卡各状态显示
local GATE_STATE_FUN = {
	[GATE_STATE.LOCK] = function(state, light)
		panelHide(state)
		panelHide(light)
	end,
	[GATE_STATE.CANT_CHALLENGE] = function(state, light)
		panelHide(state)
		panelHide(light)
	end,
	[GATE_STATE.CAN_CHALLENGE] = function(state, light)
		state:show()
		state:opacity(255)
		state:texture("activity/summer_challenge/txt_xrtz_tzz.png")
		light:show()
		local lightAction = transition.sequence({
			cc.FadeTo:create(0.6, 70),
			cc.FadeTo:create(0.6, 255),
			cc.DelayTime:create(1.2),
		})
		local stateAction = transition.sequence({
			cc.FadeTo:create(0.6, 100),
			cc.FadeTo:create(0.6, 255),
			cc.DelayTime:create(1.2),
		})
		light:stopAllActions()
		state:stopAllActions()
		light:runAction(cc.RepeatForever:create(lightAction))
		state:runAction(cc.RepeatForever:create(stateAction))
	end,
	[GATE_STATE.PASSED] = function(state, light)
		state:show()
		state:texture("activity/summer_challenge/txt_xrtz_tzcg.png")
		state:opacity(255)
		state:stopAllActions()
		panelHide(light)
	end
}
local BLACK_EFFECT= {
	event = "effect",
	data = {outline = {color = cc.c4b(91, 84, 91, 255),  size = 4}}
}



local ViewBase = cc.load("mvc").ViewBase

local SummerChallengleView = class("SummerChallengleView", ViewBase)
SummerChallengleView.RESOURCE_FILENAME = "summer_challenge.json"
SummerChallengleView.RESOURCE_BINDING = {
	["mapPanel"] = "mapPanel",
	["leftPanel"] = "leftPanel",
	["leftPanel.btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")},
		},
	},
	["leftPanel.btnRule.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		}
	},
	["lightPanel.light1"] = "light1",
	["lightPanel.light2"] = "light2",
	["lightPanel.light3"] = "light3",
	["rightTimePanel"] = "rightTimePanel",
	["rightTimePanel.time"] = {
		varname = "time",
		binds = BLACK_EFFECT
	},
	["rightTimePanel.timeText"] = {
		varname = "timeText",
		binds = BLACK_EFFECT
	},
}

function SummerChallengleView:onCreate(yyID)
	self.yyID = yyID

	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.summerChallenge, subTitle = "SUMMER ADVENTURE"})

	local cfg = csv.yunying.yyhuodong[yyID]
	local beginTime = time.getNumTimestamp(cfg.beginDate, time.getHourAndMin(cfg.beginTime, true))
	self.endTime = time.getNumTimestamp(cfg.endDate, time.getHourAndMin(cfg.endTime, true))

	self:initModel()
	self:initGameTime(cfg)
	self:initMap(cfg)
	self:initLightAction()

	if self.selectIndex then
		performWithDelay(self, function()
			self:onGateDetail(self.selectIndex)
		end, 0)
	end
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yyData = yyhuodongs[yyID] or {}
		local stamps = yyData.stamps or {}
		local nowTime = time.getTime()
		local day = math.ceil((nowTime - beginTime)/86400)
		local info = yyData.info or {}
		local pass = info.all_pass
		self:updateMapItems(stamps, day)
		performWithDelay(self, function()
			self:triggerGuide()
			self:showAchievement(pass)
		end, 0)
	end)
end

function SummerChallengleView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

-- 游戏玩法持续时间
function SummerChallengleView:initGameTime(cfg)
	local startYear, startMonth, startDay = time.getYearMonthDay(cfg.beginDate)
	local endYear, endMonth, endDay = time.getYearMonthDay(cfg.endDate)
	if matchLanguage({"en"}) then
		startMonth = getMonthInEn(startMonth)
		endMonth = getMonthInEn(endMonth)
	end
	self.time:text(startYear .. "." .. startMonth .. "." .. startDay .. "-" .. endYear .. "." .. endMonth .. "." .. endDay)
	adapt.oneLinePos(self.time, self.timeText, cc.p(5, 0), "right")
end

function SummerChallengleView:initMap(cfg)
	local baseID = cfg.paramMap.base
	self.baseCsv = csv.summer_challenge.base[baseID]
	local gateSeqID = self.baseCsv.gateSeqID

	local gateCfgTab = {}
	for id, gateCfg in orderCsvPairs(csv.summer_challenge.gates) do
		if gateCfg.gateSeq == gateSeqID then
			gateCfgTab[gateCfg.floor] = {gateCfg = gateCfg, id = id}
		end
	end

	self.mapItems = {}
	for floor=1, MAX_FLOOR do
		local item = self.mapPanel:get("item"..floor)
		local infoPanel = item:get("infoPanel")
		local childs = infoPanel:multiget("title")
		local gateCfg = gateCfgTab[floor].gateCfg
		local gateID = gateCfgTab[floor].id
		if matchLanguage({"en"}) then
			infoPanel:get("state"):y(250)
		end

		text.addEffect(childs.title, {outline={color=ui.COLORS.NORMAL.DEFAULT}})
		self.mapItems[floor] = {gateID = gateID, floor = floor, item = item, gateCfg = gateCfg}
	end
	self.mapPanel:onTouch(functools.partial(self.onClickItem, self))
end

function SummerChallengleView:initLightAction()
	self.light1:setBlendFunc({src = GL_SRC_ALPHA, dst = GL_ONE})
	self.light2:setBlendFunc({src = GL_SRC_ALPHA, dst = GL_ONE})
	self.light3:setBlendFunc({src = GL_SRC_ALPHA, dst = GL_ONE})
	self.light1:opacity(255)
	self.light2:opacity(255)
	self.light3:setRotation(10)
	local action1 = transition.sequence({
		cc.FadeTo:create(1, 50),
		cc.FadeTo:create(1, 255),
	})
	local action2 = transition.sequence({
		cc.FadeTo:create(0.5, 50),
		cc.FadeTo:create(0.5, 255),
	})
	local action3 = transition.sequence({
		cc.RotateTo:create(3, -10),
		cc.RotateTo:create(3, 10),
	})
	self.light1:runAction(cc.RepeatForever:create(action1))
	self.light2:runAction(cc.RepeatForever:create(action2))
	self.light3:runAction(cc.RepeatForever:create(action3))
end

function SummerChallengleView:onClickItem(event)
	local pos = event.target:convertToNodeSpace(event)
	if event.name == "began" then
		self.touchIndex = dataEasy.checkInRect(POS_TAB, pos)
	elseif (event.name == "ended" or event.name == "cancelled") then
		if self.touchIndex == nil then
			return
		end
		if self.touchIndex == dataEasy.checkInRect(POS_TAB, pos) then
			-- test点位显示
			-- self:onTestDraw(self.touchIndex)
			local state = self.mapItems[self.touchIndex].state
			if state == GATE_STATE.LOCK then
				gGameUI:showTip(gLanguageCsv.gateLock)
			elseif state == GATE_STATE.CANT_CHALLENGE then
				gGameUI:showTip(gLanguageCsv.gateClosed)
			else
				self:onGateDetail(self.touchIndex)
			end
		end
	end
end

function SummerChallengleView:onGateDetail(index)
	self.selectIndex = index
	self.gateDetailView = gGameUI:stackUI("city.activity.summer_challenge.gate_detail", nil, nil, {yyID = self.yyID, data = self.mapItems[index], handler = self:createHandler("startFighting")})
end

function SummerChallengleView:updateMapItems(stamps, day)
	self.maxPassedFloor = self:getMaxPassedFloor(stamps)
	for _, data in ipairs(self.mapItems) do
		local gateID = data.gateID
		local floor = data.floor
		local item = data.item
		local gateCfg = data.gateCfg
		local isOpen = gateCfg.openDay <= day
		local isPassed = stamps[gateID] == 1
		-- 通关后清理缓存布阵数据
		if isPassed then
			local localKey = string.format("summerChallengeEmbattle%d", gateID)
			userDefault.setForeverLocalKey(localKey, nil)
		end
		local isNowFloor = (self.maxPassedFloor + 1) == floor

		local statePanel = item:get("infoPanel.state")
		local title = item:get("infoPanel.title")
		local light = item:get("light")
		item:get("mask"):visible(not isOpen)
		item:get("bg"):visible(isOpen)

		if isOpen then
			title:text(string.format("%s%s %s", gLanguageCsv.gate, floor, gateCfg.name))
		else
			local diffDays = gateCfg.openDay - day
			if diffDays == 1 then
				title:text(gLanguageCsv.openTomorrow)
			else
				title:text(string.format(gLanguageCsv.openDays, diffDays))
			end
		end
		if matchLanguage({"kr"}) then
			adapt.setTextAdaptWithSize(title, {size = cc.size(320, 58), vertical = "center", horizontal = "center", margin = -5, maxLine= 2})
		end

		local state = self:getGateState(isOpen, isPassed, isNowFloor)
		data.state = state
		GATE_STATE_FUN[state](statePanel, light)
	end
end

-- 触发关卡剧情
function SummerChallengleView:triggerGuide()
	local nowFloor = self.maxPassedFloor + 1
	-- 未全通关并存在剧情
	if nowFloor <= MAX_FLOOR and self.mapItems[nowFloor].gateCfg.beforePlot then
		local beforePlot = self.mapItems[nowFloor].gateCfg.beforePlot
		local csvCfg = gGameUI.guideManagerLocal.guideCsv[beforePlot]
		local specialKey = csvCfg.specialName
		if not specialKey then
			return false
		end
		local stageId = csvCfg.stage
		-- 可重复触发的删除对应记录
		if self.mapItems[nowFloor].gateCfg.beforePlotRepeat then
			gGameUI.guideManagerLocal:onDeleteStage(stageId)
		end
		-- 未触发过剧情的
		if not gGameUI.guideManagerLocal:checkFinished(stageId) then
			-- 若存在detail界面则清除
			if self.gateDetailView and gGameUI:findStackUI("city.activity.summer_challenge.gate_detail") then
				self.gateDetailView:onClose()
				self.gateDetailView = nil
			end
			-- 设置多选回调
			gGameUI.guideManagerLocal:setChoicesFunc(functools.partial(self.onChoose, self))
			-- 触发剧情
			gGameUI.guideManagerLocal:checkGuide({specialName = specialKey})
			return true
		end
	end
	return false
end

function SummerChallengleView:showAchievement(pass)
	if pass == 1 then
		local localPass = userDefault.getForeverLocalKey("SummerChallenglePass", false)
		if not localPass then
			-- 展示成就界面
			userDefault.setForeverLocalKey("SummerChallenglePass", true)
			gGameUI:stackUI("city.activity.summer_challenge.gain_achievement", nil, nil, {itemId = self.baseCsv.achievementID})
		end
	else
		userDefault.setForeverLocalKey("SummerChallenglePass", false)
	end
end

-- 获取关卡状态
function SummerChallengleView:getGateState(isOpen, isPassed, isNowFloor)
	local state = GATE_STATE.LOCK
	if isOpen then
		if isPassed then
			-- 已通关
			state = GATE_STATE.PASSED
		elseif not isNowFloor then
			-- 不可挑战
			state = GATE_STATE.CANT_CHALLENGE
		else
			-- 挑战中
			state = GATE_STATE.CAN_CHALLENGE
		end
	end
	return state
end

-- 获取当前最大关卡数
function SummerChallengleView:getMaxPassedFloor(stamps)
	local floor = 0
	for k, v in pairs(stamps) do
		floor = math.max(csv.summer_challenge.gates[k].floor, floor)
	end
	return floor
end

-- 显示规则文本
function SummerChallengleView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function SummerChallengleView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.summerChallenge)
		end),
		c.noteText(125001, 125020),
	}
	return context
end

-- 发起战斗
function SummerChallengleView:startFighting(view, view1, battleCards)
	-- 判断活动是否已结束
	if time.getTime() > self.endTime then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end

	-- 防止schedule中有网络请求行为
	self:disableSchedule()
	gGameUI.guideManagerLocal:setChoicesFunc()
	battleEntrance.battleRequest("/game/yy/summer_challenge/battle/start", self.yyID, self.mapItems[self.selectIndex].gateID, battleCards)
		:onStartOK(function(data)
			if view then
				view:onClose(false)
				view = nil
			end
			if view1 then
				view1:onClose(false)
				view1 = nil
			end
			self.gateDetailView = nil
		end)
		:onResult(function(data, results)
			if results.result == "win" then
				self.selectIndex = nil
			end
		end)
		:show()
end

function SummerChallengleView:onChoose(cfg, chooseCfg)
	gGameApp:requestServer("/game/yy/summer_challenge/choose", nil, self.yyID, chooseCfg.id)
end

function SummerChallengleView:onClose()
	gGameUI.guideManagerLocal:setChoicesFunc()
	ViewBase.onClose(self)
end

-- 点位显示
function SummerChallengleView:onTestDraw(index)
	if not self.drawNode then
		self.drawNode = cc.DrawNode:create()
		self.drawNode:xy(0,0)
			:addTo(self.mapPanel, 13)
	end
	self.drawNode:clear()
	self.drawNode:drawPolygon(POS_TAB[index], table.length(POS_TAB[index]), cc.c4f(241 / 255, 92 / 255, 98 / 255, 0.6), 0.5, cc.c4f(241 / 255, 92 / 255, 98 / 255, 0.6))
end

return SummerChallengleView