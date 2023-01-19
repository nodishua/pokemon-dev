-- @date 2018-12-19
-- @desc 活动主界面

local LOGO_RES = {
	[1] = "login/tag_hot.png", -- 热
	[2] = "login/tag_limtime.png", -- 限
	[3] = "login/tag_new.png", -- 新
}
local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

-- 0:限时活动，3:福利
local INDEPENDENT_STYLE = {
	main = {
		independent = {0, 4},
		leftBg = "activity/img_tag_d.png",
		tabSelectedBg = "login/tab_popupsel.png",
		tabLine = "login/box_tagline.png",
		tabNormalColor = ui.COLORS.NORMAL.DEFAULT,
		title = gLanguageCsv.activity,
		subTitle = "ACTIVITY",
	},
	award = {
		independent = {3, 5},
		leftBg = "activity/img_tag_d.png",
		tabSelectedBg = "login/tab_popupsel.png",
		tabLine = "login/box_tagline.png",
		tabNormalColor = ui.COLORS.NORMAL.DEFAULT,
		title = gLanguageCsv.welfare,
		subTitle = "WELFARE",
	},
}

local RED_HINTS = {
	[YY_TYPE.directBuyGift] = {
		specialTag = "activityBuyGift",
	},
	[YY_TYPE.itemExchange] = {
		specialTag = "activityItemExchange",
	},
	[YY_TYPE.monthlyCard] = {
		specialTag = "activityMonthlyCard",
	},
	[YY_TYPE.regainStamina] = {
		specialTag = "activityRegainStamina",
	},
	[YY_TYPE.generalTask] = {
		specialTag = "activityGeneralTask",
	},
	[YY_TYPE.rechargeGift] = {
		specialTag = "activityRechargeGift",
	},
	[YY_TYPE.levelFund] = { -- 等级基金红点
		specialTag = "activityLevelFund",
	},
	[YY_TYPE.Retrieve] = { -- 资源找回红点
		specialTag = "activityRetrieve",
	},
	[YY_TYPE.weeklyCard] = { -- 资源周卡红点
		specialTag = "activityWeeklyCard",
	},
}

local ActivityView = class("ActivityView", cc.load("mvc").ViewBase)
ActivityView.RESOURCE_FILENAME = "activity.json"
ActivityView.RESOURCE_BINDING = {
	["leftPanel"] = "leftPanel",
	["leftPanel.bg"] = {
		binds = {
			event = "texture",
			data = bindHelper.self("independentStyle"),
			method = function(val)
				return INDEPENDENT_STYLE[val].leftBg
			end,
		}
	},
	["leftPanel.item"] = "tabItem",
	["leftPanel.list"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				independentStyle = bindHelper.self("independentStyle"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.sortWeight ~= b.sortWeight then
						return a.sortWeight < b.sortWeight
					end
					return a.id < b.id
				end,
				onItem = function(list, node, id, v)
					local cfg = csv.yunying.yyhuodong[id]
					local style = INDEPENDENT_STYLE[list.independentStyle]
					if matchLanguage({"en"}) then
						adapt.setTextAdaptWithSize(node:get("name"), {str = cfg.desc, size = cc.size(node:width() - 50, 70), vertical = "center", horizontal = "center", margin = -8, maxLine = 2})
					else
						adapt.setTextScaleWithWidth(node:get("name"), cfg.desc, node:width() - 30)
					end
					node:get("line"):texture(style.tabLine):visible(not v.isLast)
					local yyType = cfg.type
					if RED_HINTS[yyType] then
						local props = RED_HINTS[yyType]
						props.state = not v.selected
						props.listenData = maptools.extend({
							props.listenData or {},
							{
								activityId = id,
							},
						})
						bind.extend(list, node, {
							class = "red_hint",
							props = props,
						})
					end
					node:get("selected"):texture(style.tabSelectedBg):visible(v.selected)
					if v.selected then
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						text.deleteAllEffect(node:get("name"))
						text.addEffect(node:get("name"), {color = style.tabNormalColor})
					end
					node:get("icon"):hide()
					if LOGO_RES[cfg.icon1] then
						node:get("icon")
							:texture(LOGO_RES[cfg.icon1])
							:show():scale(0.9)
					end
					bind.click(list, node, {method = functools.partial(list.clickCell, id, v)})
				end,
				asyncPreload = 8,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["rightPanel.topPanel"] = "rightTopPanel",
	["rightPanel.topPanel.name"] = {
		varname = "rightTopPanelName",
		binds = {
			{
				event = "effect",
				data = {
					outline = {color = cc.c4b(243,146,101,255)},
					shadow = {color = cc.c4b(153,67,28,102), offset = cc.size(0,-8), size = 8}
				},
			}
		}
	},
	["rightPanel.topPanel.title"] = {
		varname = "rightTopPaneltitle",
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(255,71,46,255), size = 3}},
			}
		}
	},
	["rightPanel.topPanel.iconAll"] = {
		varname = "iconAll",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneKeyiconAllBtn")},
		},
	},
}

-- 页签 list 裁剪处理
function ActivityView:addTabListClipping()
	local list = self.tabList
	list:retain()
	list:removeFromParent()
	local size = list:size()
	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(cc.rect(200, 49, size.width, size.height), "activity/mask_tab_activity.png")
	mask:size(size)
		:anchorPoint(0, 0)
		:xy(list:xy())
	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:add(list)
		:addTo(self.leftPanel, list:z())
	list:release()
end

function ActivityView:onCreate(independentStyle, yyId)
	gGameModel.currday_dispatch:getIdlerOrigin("activityDirectBuyGift"):set(true)
	self.independentStyle = independentStyle or "main"
	local style = INDEPENDENT_STYLE[self.independentStyle]
	self.yyOpen = gGameModel.role:read("yy_open")
	self.yyEndtime = gGameModel.role:read("yy_endtime")

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = style.title, subTitle = style.subTitle})

	self:addTabListClipping()


	-- showRightInfo: 显示右侧主面板信息
	self.viewDatas = {
		[YY_TYPE.monthlyCard] = {viewName = "city.activity.month_card", showRightInfo = false},
		[YY_TYPE.itemExchange] = {viewName = "city.activity.item_exchange", showRightInfo = true},
		[YY_TYPE.generalTask] = {viewName = "city.activity.general_task", showRightInfo = true},
		[YY_TYPE.itemBuy] = {viewName = "city.activity.item_buy", showRightInfo = true},
		[YY_TYPE.directBuyGift] = {viewName = "city.activity.buy_gift", showRightInfo = true},
		[YY_TYPE.clientShow] = {viewName = "city.activity.client_show", showRightInfo = false},
		[YY_TYPE.regainStamina] = {viewName = "city.activity.regain_stamina", showRightInfo = false},
		[YY_TYPE.levelFund] = {viewName = "city.activity.level_fund", showRightInfo = false},
		[YY_TYPE.rechargeGift] = {viewName = "city.activity.recharge_gift", showRightInfo = false},
		[YY_TYPE.Retrieve] =  {viewName = "city.activity.resource_retrieve", showRightInfo = true},
		[YY_TYPE.weeklyCard] =  {viewName = "city.activity.weekly_card", showRightInfo = false},
		[YY_TYPE.qualityExchange] =  {viewName = "city.activity.quality_exchange_helditem", showRightInfo = true},
	}
	self.subViews = {}
	self.activityId = idler.new()
	self.tabDatas = idlers.new()
	self:onTabData(1, yyId)

	self.activityId:addListener(function(val, oldval)
		if oldval then
			self.tabDatas:atproxy(oldval).selected = false
		end
		if val then
			self.tabDatas:atproxy(val).selected = true
		end
		if self.subViews[oldval] then
			self.subViews[oldval]:hide()
		end
		local cfg = csv.yunying.yyhuodong[val]
		if cfg then
			local viewData = self.viewDatas[cfg.type]
			if viewData then
				self.rightTopPanel:visible(viewData.showRightInfo)
				local topBgRes = cfg.clientParam.topBg or "activity/banner_activity@.png"
				self.rightTopPanel:get("bg"):texture(topBgRes)
				self.rightTopPanelName:text(cfg.desc)
				if not self.subViews[val] then
					self.subViews[val] = gGameUI:createView(viewData.viewName, self):init(val, unpack(viewData.params or {}))
				else
					self.subViews[val]:show()
					if self.subViews[val].onInit then
						self.subViews[val]:onInit()
					end
				end

				--12加了一个一键领取,14加了一个一键提醒
				local isHas = false
				if cfg.type == 12 or cfg.type == 14 then
					isHas = true
					self:estimateType(cfg.type)
				end
				self.iconAll:visible(isHas)
			else
				self.rightTopPanel:visible(false)
				printWarn("activityType(%d) was not define", cfg.type)
			end
			local uiTimeLabel = self.rightTopPanel:get("timeLabel")
			local uiTime = self.rightTopPanel:get("time")
			local uiTimeBg = self.rightTopPanel:get("timeBg")
			local isShowTime = cfg.clientParam.isShowCountDown ~= false
			uiTimeLabel:visible(isShowTime)
			uiTime:visible(isShowTime)
			uiTimeBg:visible(isShowTime)
			if isShowTime then
				ActivityView.setCountdown(self, val, uiTimeLabel, uiTime, {labelChangeCb = function()
					adapt.oneLinePos(uiTimeLabel, uiTime, cc.p(20, 0))
					self.rightTopPanel:get("timeBg"):size(uiTimeLabel:size().width  + uiTime:size().width + 35, 50)
				end})
			end
			local isShowTitle = cfg.clientParam.isShowTitle ~= false
			self.rightTopPanel:get("name"):setVisible(isShowTitle)
		end
	end)

	-- 活动刷新时，刷新活动的一键领取状态
	idlereasy.when(gGameModel.role:getIdler("yyhuodongs"), function(_, yyhuodongs)
		local types = csv.yunying.yyhuodong[self.activityId:read()].type
		if types == 14 then
			self:estimateType(14)
		end
	end)
end

function ActivityView:onTabClick(list, id, data)
	--活动类型是33的字体提示处理
	self.rightTopPaneltitle:visible(csv.yunying.yyhuodong[id].type == 33)
	self.activityId:set(id)
end

function ActivityView:onTabData(index, id)
	local datas = {} -- {id, sortWeight, selected}
	local keys = {}
	local isSelected = false
	for _,v in ipairs(self.yyOpen) do
		if ActivityView.isShow(v, self.independentStyle, self.yyEndtime) then
			local cfg = csv.yunying.yyhuodong[v]
			local sortWeight = cfg.sortWeight
			datas[v] = {id = v, sortWeight = sortWeight, selected = false}
			table.insert(keys, datas[v])
			if id and id == v then
				datas[v].selected = true
				isSelected = true
			end
		end
	end
	table.sort(keys, function(a, b)
		if a.sortWeight ~= b.sortWeight then
			return a.sortWeight < b.sortWeight
		end
		return a.id < b.id
	end)
	if #keys >= 1 then
		datas[keys[#keys].id].isLast = true
	end
	if not isSelected then
		index = math.min(index, #keys)
		if index <= 0 then
			id = nil
			printWarn("no open activity!!!")
		else
			local data = datas[keys[index].id]
			data.selected = true
			id = data.id
		end
	else
		for i, v in ipairs(datas) do
			if v.selected then
				index = i
				break
			end
		end
	end
	self.tabDatas:update(datas)
	self.rightTopPaneltitle:visible(csv.yunying.yyhuodong[id].type == 33)
	self.activityId:set(id)
end

function ActivityView.isShow(id, independentStyle, yyEndtime)
	local cfg = csv.yunying.yyhuodong[id]
	local independent = false
	for _, v in ipairs(INDEPENDENT_STYLE[independentStyle].independent) do
		if cfg.independent == v then
			independent = true
			break
		end
	end
	if independent == false then
		return false
	end
	-- 直购礼包抽出单独做一个入口
	-- if cfg.type == YY_TYPE.directBuyGift then
	-- 	return false
	-- end
	-- 只有当开饭<1,2,3,4>的任何一个满足的时候才会进入到 yy_open，可能会出现同时都不存在的情况。
	-- 补领体力<5>是判断开饭是否开启的yyid
	if cfg.type == YY_TYPE.dinnerTime then
		return false
	end
	-- 月卡只显示一个页签
	if cfg.type == YY_TYPE.monthlyCard and cfg.paramMap.rechargeID ~= 1 then
		return false
	end
	-- 活动结束
	-- yyEndtime 当前界面不应每次获取最新的值
	yyEndtime = yyEndtime or gGameModel.role:read("yy_endtime")
	if not yyEndtime[id] or yyEndtime[id] - time.getTime() <= 0 then
		return false
	end
	-- 资源找回
	if cfg.type == YY_TYPE.Retrieve then
		local yyhuodongs =  gGameModel.role:read("yyhuodongs")
		local retrieve = yyhuodongs[id]
		if retrieve == nil then
			return false
		end
		if retrieve.lastday ~= tonumber(time.getTodayStrInClock()) then
			return false
		end

		if retrieve.retrieve_award == nil then -- 没领取过
			return true
		end
		local lvl =  gGameModel.role:read("level")
		local retrieveDatas = csv.yunying.retrieve[lvl]
		local retrieveSize = 6
		local rmbRetrieve = 0
		for k, v in pairs(retrieve.retrieve_award) do
			if v.rmb == 1 then
				rmbRetrieve = rmbRetrieve + 1
			end
		end
		return rmbRetrieve <  retrieveSize
	end

	if cfg.type == YY_TYPE.weeklyCard then
		local yyhuodongs = gGameModel.role:read("yyhuodongs")
		local yydata = yyhuodongs[id] or {}
		local yyCfg = csv.yunying.yyhuodong[id]
		if yydata.buy == nil then
			local hour, min = time.getHourAndMin(yyCfg.beginTime)
			local buyDay = yyCfg.paramMap.buyDay
			local endTime = time.getNumTimestamp(yyCfg.beginDate,hour,min) + buyDay*24*60*60
			if endTime - time.getTime() <= 0 then
				return false
			end
		else
			local hour, min = time.getHourAndMin(yyCfg.endTime)
			local endTime = time.getNumTimestamp(yyCfg.endDate,hour,min)
			if endTime - time.getTime() <= 0 then
				return false
			end
		end
	end
	return true
end

-- 判断是否存在该风格的页签
function ActivityView.isDataExist(independentStyle)
	independentStyle = independentStyle or "main"
	local yyOpen = gGameModel.role:read("yy_open")
	for _,v in ipairs(yyOpen) do
		if ActivityView.isShow(v, independentStyle) then
			return true
		end
	end
	return false
end

-- @param params: {tag, labelChangeCb}
function ActivityView.setCountdown(view, id, uiTimeLabel, uiTime, params)
	params = params or {}
	local tag = params.tag or 1
	view:enableSchedule():unSchedule(tag)
	local cfg = csv.yunying.yyhuodong[id]
	local extraStr = ""
	if cfg.countType == 0 then
		extraStr = gLanguageCsv.activityDaily
	end
	local countdown = 0
	local yyEndtime = gGameModel.role:read("yy_endtime")
	if yyEndtime[id] then
		countdown = yyEndtime[id] - time.getTime()
	end

	bind.extend(view, uiTime, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = tag,
			strFunc = function(t)
				return t.str .. extraStr
			end,
			callFunc = function()
				if params.labelChangeCb then
					params.labelChangeCb()
				end
			end,
			endFunc = function()
				uiTimeLabel:text(gLanguageCsv.activityOver)
				if params.labelChangeCb then
					params.labelChangeCb()
				end
			end,
			onNode = function(node)
				uiTimeLabel:text(gLanguageCsv.activityLeftTime)
			end
		}
	})
end

--判断是那个类型
function ActivityView:estimateType(types)
	local activityId = self.activityId:read()
	if types == 14 then
		local huodongID = csv.yunying.yyhuodong[activityId].huodongID
		local yyhuodongs = gGameModel.role:read("yyhuodongs")
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		local number = 2
		for k, v in csvPairs(csv.yunying.generaltask) do
			if v.huodongID == huodongID and stamps[k] == 1 then
				number = 1
				break
			end
		end
		uiEasy.setBtnShader(self.iconAll, false, number)
		self.iconAll:get("txt"):text(gLanguageCsv.getAwardAll)

	else
		local data = userDefault.getForeverLocalKey("activityItemExchange", {})
		local remindData = data[activityId] or {}
		local isHas = false
		if remindData then
			for _, v in pairs(remindData) do
				if v then
					isHas = true
					break
				end
			end
		end
		uiEasy.setBtnShader(self.iconAll, false, 1)
		local strText = not isHas and gLanguageCsv.notRemind or gLanguageCsv.anewRemind
		self.iconAll:get("txt"):text(strText)
		return isHas
	end
end

--类型是14是一键领取，类型是12是活动提醒
function ActivityView:oneKeyiconAllBtn()
	local activityId = self.activityId:read()
	if self.subViews[activityId] and self.subViews[activityId]:isVisible() then
		local types = csv.yunying.yyhuodong[activityId].type
		if types == 14 then
			gGameApp:requestServer("/game/yy/award/get/onekey", function(tb)
				gGameUI:showGainDisplay(tb)
				self:estimateType(types)
			end, activityId)
		else
			-- isHas 为false表示不再提醒(点击按钮勾选上所有的)
			local isHas = self:estimateType(types)
			local huodongID = csv.yunying.yyhuodong[activityId].huodongID
			local data = userDefault.getForeverLocalKey("activityItemExchange", {})
			local remindData = data[activityId] or {}
			for k, v in csvPairs(csv.yunying.itemexchange) do
				if v.huodongID == huodongID then
					remindData[k] = not isHas and true or false
				end
			end
			data[activityId] = remindData
			gGameModel.forever_dispatch:getIdlerOrigin("activityItemExchange"):set(data, true)
			self.subViews[activityId]:remindUpdata()
			self:estimateType(types)
		end
	end
end

return ActivityView