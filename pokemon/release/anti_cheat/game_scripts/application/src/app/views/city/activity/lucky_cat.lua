-- @Date:   2019-06-18
-- @Desc:
-- @Last Modified time: 2019-07-02

local ActivityView = require "app.views.city.activity.view"
local ActivityLuckyCat = class("ActivityLuckyCat", Dialog)

local MAX_NUM = 6
local LEFT_SHOW_NUM = 5
ActivityLuckyCat.RESOURCE_FILENAME = "activity_lucky_cat.json"
ActivityLuckyCat.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {

			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnSure"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function (view)
				view:onSure(1)
			end)}
		},
	},

	["numItem"] = "numItem",
	["mask"] = "mask",
	["item"] = "item",
	["txt"] = "txt",
	["max"] = "max",
	["cost"] = "cost",
	["have"] = "have",
	["icon1"] = "icon1",
	["icon2"] = "icon2",
	["txt2"] = "txt2",
	["txt3"] = "txt3",
	["txt4"] = "txt4",
	["icon3"] = "icon3",
	["txtVipTips"] = "txtVipTips",
	["iconVipTips"] = "iconVipTips",
	["times"] = "times",
	["timesLabel"] = "timesLabel",
	["timeLabel"] = {
		varname = "timeLabel",
		binds = {
			event = "effect",
			data = {shadow = {color = cc.c4b(0, 0, 0, 100), offset = cc.size(3, -3), size = 3}},
		},
	},
	["time"] = {
		varname = "time",
		binds = {
			event = "effect",
			data = {shadow = {color = cc.c4b(0, 0, 0, 100), offset = cc.size(3, -3), size = 3}},
		},
	},
	["title"] = {
		varname = "title",
		binds = {
			event = "effect",
			data = {shadow = {color = cc.c4b(0, 0, 0, 100), offset = cc.size(8, -8), size = 8}},
		},
	},
	["dialogPanel"] = "dialogPanel",
	["dialogPanel.vip5"] = "vipIcon",
	["dialogPanel.list"] = "vipList",
	["leftList"] = "leftList",
}

function ActivityLuckyCat:onCreate(activityId, tb)
	local data = tb.view.luckycat_message_rmb
	gGameModel.currday_dispatch:getIdlerOrigin("luckyCat"):set(true)
	self.activityId = activityId
	self:initModel()
	self.originData = {}
	local iconVip = {}
	for i,v in orderCsvPairs(csv.yunying.luckycat) do
		local cfg = csv.yunying.yyhuodong[self.activityId]
		if cfg.huodongID == v.huodongID then
			table.insert(self.originData, v)
			table.insert(iconVip, v.vip)
		end
	end
	self.data1 = arraytools.first(data, LEFT_SHOW_NUM)

	--vip展示内容
	for k, v in ipairs(iconVip) do
		if v ~= 0 then
			local item = self.vipIcon:clone()
			item:texture("common/icon/vip/icon_vip"..v..".png")
			self.vipList:addChild(item)
			item:show()
		end
	end
	self.vipList:setItemAlignCenter()
	self.vipList:setScrollBarEnabled(false)

	self.showItemIdx = 1
	self.maxIdx = 0

	self.leftList:setTouchEnabled(false)
	self.leftList:setScrollBarEnabled(false)

	self.leftDatas = idlertable.new(#data > 0 and data or {})

	idlereasy.when(self.leftDatas, function (_, data)
		self.leftList:removeAllItems()
		local function insertItem(v)
			local node = self.item:clone()
			node:show()
			local label = node:get("label")
			local richText = rich.createWithWidth(string.format(gLanguageCsv.congratulationGetDianomd, v[1], v[2]), label:getFontSize(), nil, node:size().width - 10)
				:anchorPoint(0, 1)
				:addTo(label)
			if richText:size().height > node:size().height then
				node:size(cc.size(node:size().width, richText:size().height + 10))
			end
			label:y(node:size().height - 5)
			self.leftList:pushBackCustomItem(node)
		end
		local scrollStartItem = 0
		for k, val in pairs(data) do
			insertItem(val)
			self.leftList:refreshView()
			local innerHeight = self.leftList:getInnerContainer():size().height
			if scrollStartItem == 0 and innerHeight > self.leftList:size().height then
				scrollStartItem = k
			end
		end
		self.maxIdx = #data
		if scrollStartItem > 0  then
			for i = 1, scrollStartItem do
				insertItem(data[i])
			end
		end
	end)
	self.node = self:getResourceNode()
	for i = 1, MAX_NUM do
		self.node:get("list"..i):setScrollBarEnabled(false)
	end
	self.currId = idler.new(self.originData[1].drawID)
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		self.currId:set(yydata.info.count)
	end)
	self.curState = idler.new(false)
	idlereasy.any({self.curState, self.rmb, self.vip}, function (_, val, rmb, vip)
		if val == true then
			self:rollCb()
		end
	end)
	ActivityView.setCountdown(self, self.activityId, self.timeLabel, self.time, {labelChangeCb = function()
		adapt.oneLinePos(self.timeLabel, self.time, cc.p(15, 0))
	end})
	self:rollCb()
	self:originRoll()
	local begin = 0
	local index = 0
	self:enableSchedule()
	self:schedule(function()
		if self.maxIdx > 0 then
			self.leftList:scrollToItem(self.showItemIdx, cc.p(1, 1), cc.p(1, 1))
			if self.showItemIdx >= self.maxIdx then
				self.showItemIdx = 0
				performWithDelay(self, function()
					self.leftList:jumpToItem(0, cc.p(1, 1), cc.p(1, 1))
				end, 0.9)
			end
			self.showItemIdx = self.showItemIdx + 1
		end
	end, 1, 1, 4)
	Dialog.onCreate(self, {blackType = 1})
end

function ActivityLuckyCat:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.vip  = gGameModel.role:getIdler("vip_level")
end

function ActivityLuckyCat:rollCb()
	self.have:text(self.rmb:read())
	local vip = self.vip:read()
	adapt.oneLinePos(self.txt3, {self.have, self.icon3}, {cc.p(0, 0), cc.p(0, 0)}, "left")
	self.totalTimes = 0
	for i,v in ipairs(self.originData) do
		if vip >= v.vip then
			self.totalTimes = self.totalTimes + 1
		end
	end
	local id = self.currId:read()
	local data = self.originData[math.min(id + 1, #self.originData)]
	self.max:text(data.rmbRndMax)
	adapt.oneLinePos(self.max, self.icon1, cc.p(10, 0), "left")
	self.needCost = data.rmbCost
	self.cost:text(data.rmbCost)
	adapt.oneLinePos(self.txt2, {self.cost, self.icon2}, {cc.p(0, 0), cc.p(0, 0)}, "left")
	self.remainTime = self.totalTimes - id
	self.times:text(self.totalTimes - id.."/"..self.totalTimes)
	adapt.oneLinePos(self.timesLabel, self.times,cc.p(0,0), "left")

	self.txtVipTips:visible(data.vip>0)
	self.iconVipTips:visible(data.vip>0)
	self.iconVipTips:texture(ui.VIP_ICON[data.vip])
	adapt.oneLinePos(self.txtVipTips, self.iconVipTips,cc.p(0,0), "right")

	if id >= #self.originData then     -- 达到最大招财次数后隐藏右侧信息，改变左侧信息
		self.txt:visible(false)
		self.txt2:visible(false)
		self.txt3:visible(false)
		self.max:visible(false)
		self.txt4:visible(true)
		self.cost:visible(false)
		self.have:visible(false)
		self.icon2:visible(false)
		self.icon3:visible(false)
		self.icon1:visible(false)
		self.txtVipTips:visible(false)
		self.iconVipTips:visible(false)
	end
end

function ActivityLuckyCat:originRoll()
	local numbers = self:getNumbers(0)
	for i=1,MAX_NUM do
		self:setNumber(false, true, i, numbers)
	end
	self:numberRoll(MAX_NUM, 0, 0.1)
end

function ActivityLuckyCat:getNumbers(number)
	local numbers = {}
	for i=MAX_NUM, 1, -1 do
		table.insert(numbers, math.floor(number/10^(i-1)))
		if i - 1 > 1 then
			number = number % 10^(i-1)
		else
			table.insert(numbers, number % 10)
			break
		end
	end
	return numbers
end

function ActivityLuckyCat:setNumber(isRoll,isClear, index, numbers, time)
	if isClear then
		self.node:get("list"..index):removeAllChildren()
	end

	if isRoll then
		local number = math.random(0, 9)
		local max = 12
		for k = 1, max do
			self:addList(self.node:get("list"..index), (number+k)%10, k)
		end
		self:addList(self.node:get("list"..index), numbers[index], max + 1)
		self.node:get("list"..index):scrollToPercentVertical(100, time, false)
	else
		self:addList(self.node:get("list"..index),numbers[index], 0)
	end
end

function ActivityLuckyCat:addList(list,number,z)
	local panel = self.numItem:clone()
	panel:setVisible(true)
	list:insertCustomItem(panel, z)
	panel:get("num"):text(number)
end

function ActivityLuckyCat:numberRoll(index, number, time, tb)
	local numbers = self:getNumbers(number)
	if time == 0.1 then
		performWithDelay(self, function()	-- 这里不延迟一下，就播不了滚动的动画
			for i=1,MAX_NUM do
				self:setNumber(true, false, i , numbers, 1)
			end
			self.mask:hide()
		end, 1/60)
	else
		self.mask:show()
		for i=1,MAX_NUM do
			self:setNumber(true, false, i , numbers, time)
		end
		performWithDelay(self, function()
			if tb then
				self.leftDatas:set(tb.view.luckycat_message_rmb, true)
				self:originRoll()
				self:rollCb()
				gGameUI:showGainDisplay(tb)
			end
		end, time+0.6) --策划要求，最后数字展示0.6s
	end
end

function ActivityLuckyCat:onSure(time)
	if self.rmb:read() < self.needCost and self.remainTime > 0 then
		self.curState:set(true)
		uiEasy.showDialog("rmb", {titleName = gLanguageCsv.luckyCat})
		return
	end
	if self.totalTimes < #self.originData and self.remainTime == 0 then
		self.curState:set(true)
		local content = {gLanguageCsv.luckyMax, string.format(gLanguageCsv.commonVipIncrease, gLanguageCsv.luckyCat)}
		uiEasy.showDialog("vip", {titleName = gLanguageCsv.luckyCat, content = content})
		return
	end
	if self.currId:read() >= #self.originData then
		gGameUI:showTip(gLanguageCsv.luckyMax)
		return
	end

	self.curState:set(false)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		local key, value = next(tb.view.result)
		self:numberRoll(MAX_NUM, value, time, tb)
	end, self.activityId)
end

return ActivityLuckyCat
