
local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}

local ActivitySevenDayLoginDialog = class("ActivitySevenDayLoginDialog", Dialog)

ActivitySevenDayLoginDialog.RESOURCE_BINDING = {
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["textCountDown"] = {
		varname = "textCountDown",
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(132, 29, 31, 255), size = 3}},
			},
		}
	},
	["textCountDown1"] = "textCountDown1",
	["item"] = "item",
	["iconItem"] = "iconItem",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemsData"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					list.initItem(node, k, v)
				end,
				asyncPreload = 4,
			},
			handlers = {
				initItem = bindHelper.self("initItem"),
			},
		},
	},
}

function ActivitySevenDayLoginDialog:onCreate( activityId )
	Dialog.onCreate(self,{blackType = 1})
	self.activityId = activityId
	self:initModel()
	self:initData()
	self:initCountDown()
	gGameModel.currday_dispatch:getIdlerOrigin("newPlayerWeffare"):set(true)
end

-- 初始化model
function ActivitySevenDayLoginDialog:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.itemsData = idlertable.new({}) -- 存放 奖励和领取状态
	self.date = idler.new("")  -- 活动时间
end
--初始化界面
function ActivitySevenDayLoginDialog:initData()
	-- 每日奖励数据
	local loginwealData = {}
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local huodongID = yyCfg.huodongID
	for k, v in csvPairs(csv.yunying.loginweal) do
		if v.huodongID == huodongID then
			loginwealData[v.daySum] = {award = v.award, id = k}
		end
	end
	idlereasy.when(self.yyhuodongs,function(_, yyhuodong)
		local yydata = yyhuodong[self.activityId]
		local itemsData = {}
		for daySum, wealData in pairs(loginwealData) do
			if yydata.stamps[wealData.id] == nil then
				itemsData[daySum] = {award = wealData.award, id = wealData.id, getType = GET_TYPE.CAN_NOT_GOTTEN}
			else
				itemsData[daySum] = {award = wealData.award, id = wealData.id, getType = yydata.stamps[wealData.id]}
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.itemsData:set(itemsData)
	end)
	-- 活动日期
	local _, beginMonth, beginDay = time.getYearMonthDay(yyCfg.beginDate)
	local _, endMonth, endDay = time.getYearMonthDay(yyCfg.endDate)
	self.date:set(beginMonth.."."..beginDay.."-"..endMonth.."."..endDay)

	-- 春节活动特殊处理 TODO 特殊在继承view里处理
	if self.springFestival then
		local pnode = self:getResourceNode()
		widget.addAnimationByKey(pnode, "login_gift_spring_festival/chunjieqiridenglu.skel","bg", "effect_h_loop", 0)
		:xy(pnode:width()/2, pnode:height()/2 + 50)
		:anchorPoint(cc.p(0.5,0.5))
		:scale(2)

		widget.addAnimationByKey(pnode, "login_gift_spring_festival/chunjieqiridenglu.skel", "detail","effect_q_loop", 4)
		:xy(pnode:width()/2, pnode:height()/2 + 50)
		:anchorPoint(cc.p(0.5,0.5))
		:scale(2)
		-- self.list:y(100)
	end
end

--倒计时
function ActivitySevenDayLoginDialog:initCountDown()
	local textTime = self.textCountDown
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local hour, min = time.getHourAndMin(yyCfg.endTime)
	local endTime = time.getNumTimestamp(yyCfg.endDate,hour,min)
	local function setLabel()
		local remainTime = time.getCutDown(endTime - time.getTime())
		textTime:text(remainTime.str)
		if self.textCountDown1 then
			adapt.oneLinePos(self.textCountDown1,textTime, cc.p(5,0))
		end
		if endTime - time.getTime() <= 0 then
			textTime:text(gLanguageCsv.activityOver)
			self:unSchedule(1)
			return false
		end
		return true
	end
	self:enableSchedule()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, 1)
end

--初始化list的item
function ActivitySevenDayLoginDialog:initItem(list, node, k, itemData)
	local childs = node:multiget("textDay", "btnGet","list","imgBg","imgDayBg")
	-- 天数
	local dayNum = childs.textDay:setString(k)
	--奖励
	local awards = itemData.award
	local param = {}
	if self.springFestival then
		param = {
			onNode = function(panel, v )
				if v.key ~= "card" then
					panel:get("box"):texture("activity/spring_festival/box_cjhd.png")
					panel:get("imgFG"):hide()
					text.addEffect(panel:get("num"), {outline={color=cc.c4b(204, 61, 73,255)}})
				else
					panel.panel:get("imgBG"):texture("activity/spring_festival/box_cjhd.png")
					panel.panel:get("imgFG"):hide()
				end

			end
		}
	end
	uiEasy.createItemsToList(list, childs.list, awards,param)

	--按钮限时处理
	if itemData.getType == GET_TYPE.CAN_NOT_GOTTEN then
		-- 未达成
		adapt.setTextScaleWithWidth(childs.btnGet:get("textGet"), gLanguageCsv.haveNotLogin, 250)
		childs.btnGet:setEnabled(false)
		if self.springFestival then
			childs.imgDayBg:texture("activity/spring_festival/tip_2.png")
			childs.btnGet:get("textGet"):setTextColor(cc.c4b(156, 33, 51, 255))
			childs.textDay:setTextColor(cc.c4b(156, 33, 51,255))
			childs.imgBg:texture("activity/spring_festival/panel_qr0.png")
		else
			childs.btnGet:get("textGet"):setTextColor(cc.c4b(196, 92, 82, 255))
			childs.textDay:setTextColor(ui.COLORS.WHITE)
			childs.imgBg:texture("activity/seven_day_login/panel_qr0.png")
		end
	elseif itemData.getType == GET_TYPE.CAN_GOTTEN then
		-- 可领取
		adapt.setTextScaleWithWidth(childs.btnGet:get("textGet"), gLanguageCsv.spaceReceive, 250)
		childs.btnGet:get("textGet"):setTextColor(cc.c4b(102, 36, 47, 255))
		childs.btnGet:setEnabled(true)
		if self.springFestival then
			childs.imgBg:texture("activity/spring_festival/panel_qr1.png")
		else
			childs.imgBg:texture("activity/seven_day_login/panel_qr1.png")
		end
	elseif itemData.getType == GET_TYPE.GOTTEN then
		--已领取
		childs.btnGet:get("textGet"):setString(gLanguageCsv.received)
		if self.springFestival then
			childs.btnGet:get("textGet"):setTextColor(cc.c4b(156, 33, 51, 255))
			childs.imgDayBg:texture("activity/spring_festival/tip_2.png")
			childs.textDay:setTextColor(cc.c4b(156, 33, 51,255))
			childs.imgBg:texture("activity/spring_festival/panel_qr0.png")
		else
			childs.btnGet:get("textGet"):setTextColor(cc.c4b(196, 92, 82,255))
			childs.textDay:setTextColor(ui.COLORS.WHITE)
			childs.imgBg:texture("activity/seven_day_login/panel_qr0.png")
		end
		childs.btnGet:setEnabled(false)
	end

	local centerPos = cc.p(node:get("imgDayBg"):xy())
	adapt.oneLineCenterPos(centerPos, {node:get("textDi"), node:get("imgDayBg"), node:get("textTian")}, cc.p(5, 0))
	bind.touch(self, childs.btnGet, {methods = {ended = functools.partial(self.sendGetAward, self, itemData.id)}})
	childs.textDay:x(node:get("imgDayBg"):x())
end
-- 发送领取
function ActivitySevenDayLoginDialog:sendGetAward(id)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId,id)
end


return ActivitySevenDayLoginDialog










