-- @date 2018-12-23
-- @desc 月卡

local STATE_TYPE = {
	null = 0,
	buy = 1,
	max = 2,	--已达上限
}
local ActivityMonthCardView = class("ActivityMonthCardView", cc.load("mvc").ViewBase)

ActivityMonthCardView.RESOURCE_FILENAME = "activity_month_card.json"
ActivityMonthCardView.RESOURCE_BINDING = {
	["panel1"] = "panel1",
	["panel1.icon"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDetailClick(1)
			end)}
		},
	},
	["panel1.btn"] = {
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.defer(function(view)
				return view:onBtnClick(1)
			end)}
		},
	},
	["panel2"] = "panel2",
	["panel2.icon"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDetailClick(2)
			end)}
		},
	},
	["panel2.btn"] = {
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.defer(function(view)
				return view:onBtnClick(2)
			end)}
		},
	},
}

function ActivityMonthCardView:onCreate()
	userDefault.setCurrDayKey("notShowMonthCardRedhint",true)
	self:initModel()

	local activityIds = ActivityMonthCardView.getActivityIds()
	self.data = {}
	for idx, activityData in ipairs(activityIds) do
		local rechargeId = activityData.rechargeId
		local activityId = activityData.activityId
		local data = {rechargeId = rechargeId, activityId = activityId, state = idler.new(STATE_TYPE.null), day = idler.new(0)}
		self.data[idx] = data
		local rechargeCfg = csv.recharges[rechargeId]
		local yyCfg = csv.yunying.yyhuodong[activityId]
		local panel = self["panel" .. idx]
		local list = panel:get("list")
		local award = yyCfg.paramMap.award
		local maxMonthCard = yyCfg.paramMap.most
		local items = {{key = "rmb", num = award["rmb"]}}
		for key, num in csvMapPairs(award) do
			if key ~= "rmb" then
				table.insert(items, {key = key, num = num})
			end
		end

		data.privilegeId = yyCfg.paramMap.privilege
		data.list = list
		uiEasy.createItemsToList(self, list, items)

		panel:get("item4.num"):text(string.format(gLanguageCsv.day, rechargeCfg.param.days))
		idlereasy.any({data.state, data.day},function(_, state, day)
			local btn = panel:get("btn")
			local btnLabel = panel:get("btn.label")
			local dayLabel = panel:get("label")
			local dayNum = panel:get("num")
			cache.setShader(btn, false, "normal")
			btn:setTouchEnabled(true)
 			text.addEffect(btnLabel, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
			if state == STATE_TYPE.buy then
				btnLabel:text(string.format(gLanguageCsv.symbolMoney, rechargeCfg.rmbDisplay))
				btnLabel:setFontSize(60)
				btnLabel:alignCenter(btn:size())
				if day <= 0 then
					dayLabel:text(gLanguageCsv.monthCardNotHave)
					dayNum:text("")
				else
					dayLabel:text(gLanguageCsv.reveiveLeftDay)
					dayNum:text(string.format(gLanguageCsv.day, data.day:read()))
				end
				text.addEffect(panel:get("textHasNum"), {color = cc.c4b(92, 153, 112, 255)})
			elseif state == STATE_TYPE.max then
				dayLabel:text(gLanguageCsv.reveiveLeftDay)
				dayNum:text(string.format(gLanguageCsv.day, data.day:read() ))
				text.addEffect(panel:get("textHasNum"), {color = cc.c4b(92, 153, 112, 255)})
				btnLabel:text(gLanguageCsv.alreadyMax)
				btnLabel:setFontSize(50)
				btnLabel:alignCenter(btn:size())
				btn:setTouchEnabled(false)
				cache.setShader(btn, false, "hsl_gray")
				text.deleteAllEffect(btnLabel)
				text.addEffect(btnLabel, {color = ui.COLORS.NORMAL.WHITE})
				text.addEffect(panel:get("textHasNum"), {color = cc.c4b(230, 92, 92, 255)})
			end
			local day = data.day:read()
			local hasNums = math.ceil(day / 30)
			if day <= 0 then
				hasNums = 0
			end
			panel:get("textHasNum"):text(hasNums .."/"..maxMonthCard)
			adapt.oneLinePos(dayLabel, dayNum , cc.p(5, 0), "left")
			local tipText
			if hasNums == 0 then
				panel:get("textHas"):hide()
				panel:get("textHasNum"):hide()
				tipText = gLanguageCsv.monthCardAward1
			else
				panel:get("textHas"):show()
				panel:get("textHasNum"):show()
				tipText = gLanguageCsv.monthCardAwardNoToday
			end
			panel:removeChildByName("richText1")
			local richText1 = rich.createWithWidth(string.format(tipText, rechargeCfg.rmb), 34, nil, 660)
				:addTo(panel, 2, "richText1")
				:anchorPoint(0, 0.5)
				:xy(cc.p(75, 615))

			panel:removeChildByName("richText2")
			local richText2 = rich.createWithWidth(string.format(gLanguageCsv.monthCardAward2, award.rmb),  34, nil, 660)
				:addTo(panel, 2, "richText2")
				:anchorPoint(0, 0.5)
				:xy(cc.p(75, richText1:y() - richText1:height() - 5))
			if not matchLanguage({"cn", "tw"}) then
				richText2:xy(cc.p(75, richText1:y() - richText1:height() - 15))
			end

		end)
	end
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		for _, data in ipairs(self.data) do
			if yyhuodongs[data.activityId] then
				local lastday = yyhuodongs[data.activityId].lastday
				local enddate = yyhuodongs[data.activityId].enddate
				local today = tonumber(time.getTodayStrInClock())
				data.day:set(math.max(0, 1 + math.floor((time.getNumTimestamp(enddate) - time.getNumTimestamp(today)) / 24 / 3600)))
				local rechargeCfg = csv.recharges[data.rechargeId]

				local yyCfg = csv.yunying.yyhuodong[data.activityId]
				local maxMonthCard = yyCfg.paramMap.most
				if data.day:read() > rechargeCfg.param.days * (maxMonthCard - 1)  then
					data.state:set(STATE_TYPE.max)
				else
					data.state:set(STATE_TYPE.buy)
				end
			else
				data.state:set(STATE_TYPE.buy)
			end
		end
	end)
end

function ActivityMonthCardView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityMonthCardView:onDetailClick(idx)
	gGameUI:stackUI("city.activity.month_card_privilege", nil, nil, self.data[idx])
end

-- 未购买点击购买；未领取点击领取；已领取显示今日已领取
function ActivityMonthCardView:onBtnClick(idx)
	local data = self.data[idx]
	local state = data.state:read()
	local yyCfg = csv.yunying.yyhuodong[data.activityId]
	if state == STATE_TYPE.buy then
		gGameApp:payCustom(self)
			:params({rechargeId = data.rechargeId, yyID = data.activityId})
			:checkCanbuy()
			:serverCb(function()
				local rechargeCfg = csv.recharges[data.rechargeId]
				gGameUI:showGainDisplay({rmb = rechargeCfg.rmb}, {raw = false})
				gGameUI:showTip(gLanguageCsv.monthCardBuySuccess)
			end)
			:doit()
	end
end


-- @desc 获得所有月卡的基础数据
function ActivityMonthCardView.getActivityIds()
	local yyOpen = gGameModel.role:read("yy_open")
	local activityIds = {}
	for _, id in ipairs(yyOpen) do
		local yyCfg = csv.yunying.yyhuodong[id]
		if yyCfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.monthlyCard then
			table.insert(activityIds, {rechargeId = yyCfg.paramMap.rechargeID, activityId = id})
		end
	end
	table.sort(activityIds, function(a, b)
		return a.rechargeId < b.rechargeId
	end)
	return activityIds
end

-- @desc 根据 month_card_privilege 里的 key 和 月卡激活状态获得当前加成
function ActivityMonthCardView.getPrivilegeAddition(key)
	local activityIds = ActivityMonthCardView.getActivityIds()
	local ans = nil
	local yyhuodongs = gGameModel.role:read("yyhuodongs")
	for _, data in ipairs(activityIds) do
		local yyData = yyhuodongs[data.activityId]
		if yyData then
			local yyCfg = csv.yunying.yyhuodong[data.activityId]
			local hour, min = time.getHourAndMin(yyCfg.beginTime, true)
			local today = tonumber(time.getTodayStrInClock(hour, min))
			local enddate = yyData.enddate
			if today <= enddate then
				local cfg = csv.month_card_privilege[yyCfg.paramMap.privilege]
				if key == "pwNoCD" then
					if cfg[key] then
						return true
					end
				else
					ans = (ans or 0) + (tonumber(cfg[key]) or 0)
				end
			end
		end
	end
	return ans
end

return ActivityMonthCardView