-- @Date:   2021-04-17
-- @Desc:    尊享活动


local YY_TYPE =  game.YYHUODONG_TYPE_ENUM_TABLE
local ActivityView = require "app.views.city.activity.view"

local STATE_TYPE = {
	CAN_BUY = 0,--可购买
	BOUGHT = 1, --以售罄
	CAN_NOT_BOUGHT = 2, --未完成
}

local ActivityExclusiveLimitDialog = class("ActivityExclusiveLimitDialog",Dialog)
ActivityExclusiveLimitDialog.RESOURCE_FILENAME = "activity_exclusive_limit.json"
ActivityExclusiveLimitDialog.RESOURCE_BINDING = {
	["close"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["rule"] = {
		varname = "rule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRules")}
		},
	},
	["title"] ={
		varname = "title",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(209, 50,18, 255), size = 5}}
		},
	},
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
				margin = 20,
				paddings = 10,
				dataOrderCmp = function(a, b)
					if a.boughtStatus ~= b.boughtStatus then
						return a.boughtStatus < b.boughtStatus
					end
					if a.isRMB ~= b.isRMB then
						return b.isRMB
					end
					return a.price < b.price
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("title","levelTitle","boxImage","listUp","listDown","price","mask","despLabel")
					local dataB = dataEasy.getItemData(v.cfg.item)
					local len = itertools.size(v.cfg.item)
					if len == 1 or len == 2 then
						uiEasy.createItemsToList(list, childs.listUp, dataB, {onAfterBuild = function()
							childs.listUp:setItemAlignCenter()
						end, scale = 0.6})
						childs.listDown:visible(false)
						childs.listUp:y(childs.listUp:y() - childs.listUp:height() / 2)
					else
						local t = {}
						local count = 0
						for i = len, 1, -1 do
							table.insert(t,dataB[i])
							table.remove(dataB, i)
							count = count + 1
							if (len == 3 or len == 4 ) and count == 2 then
								break
							elseif (len == 5 or len == 6) and count == 3 then
								break
							end
						end
							uiEasy.createItemsToList(list, childs.listUp, dataB, {onAfterBuild = function()
							childs.listUp:setItemAlignCenter()
						end, scale = 0.6})
						uiEasy.createItemsToList(list, childs.listDown, t, {onAfterBuild = function()
							childs.listDown:setItemAlignCenter()
						end, scale = 0.6})
					end
					childs.listUp:width(400)
					childs.listDown:width(400)
					childs.title:get("txt"):text(v.cfg.titleName)
					childs.levelTitle:get("txt"):text(v.cfg.name)

					-- adapt.oneLineCenterPos(cc.p(childs.price:width() / 2, childs.price:height() / 2), {childs.price:get("rmb")},cc.p(0, 0))

					local limitString = string.format(gLanguageCsv.exclusiveRestrictionBuyTime,v.cfg.limit)
					childs.despLabel:text(limitString)
					childs.boxImage:texture(v.cfg.icon)
					local btn = childs.price

					if v.isRMB then
						childs.price:get("dia"):hide()
						childs.price:get("diaPrice"):hide()
						childs.price:get("rmb"):show():text(string.format(gLanguageCsv.symbolMoney,csv.recharges[v.cfg.rechargeID].rmbDisplay))
					else
						childs.price:get("rmb"):hide()
						childs.price:get("dia"):show()
						childs.price:get("diaPrice"):show():text(v.cfg.rmbCost)
					end

					if v.cfg.limit > v.hasBoughtNum then
						btn:setTouchEnabled(true)
						bind.touch(list, btn, {clicksafe = false, methods = {ended = functools.partial(list.clickCell, k, v)}})
						childs.mask:hide()

					else
						childs.mask:get("title"):text(gLanguageCsv.sellout)
						btn:setTouchEnabled(false)
						childs.mask:setTouchEnabled(true)
						childs.mask:show()
					end

				end,
				asyncPreload = 4,
				itemAction = {isAction = false},
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},

			handlers = {
				 clickCell = bindHelper.self("clickCell"),
			},
		},
	},
	["timeLabel"] = "timeLabel",
}


function ActivityExclusiveLimitDialog:onCreate(activityId)
	gGameModel.forever_dispatch:getIdlerOrigin("exclusiveLimitDatas"):set(true)
	self.activityId = activityId
	self:initModel()
	self:initData()
	self:initUI()
	Dialog.onCreate(self,{blackType = 1})
end

function ActivityExclusiveLimitDialog:initModel()
	self.itemsData = idlers.new()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.product =  self.yyhuodongs:read()[self.activityId].stamps
	self.clientBuyTimes = idler.new(true)

	idlereasy.any({self.clientBuyTimes,self.yyhuodongs},function(_,clientBuyTimes, yyhuodongs)
		self.product =  yyhuodongs[self.activityId].stamps
		self:initData()
	end,true)
end

function ActivityExclusiveLimitDialog:initData()
	local itemsData = {}
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local huodongID = yyCfg.huodongID

	for id,num in pairs(self.product) do
		num = dataEasy.getPayClientBuyTimes("directBuyData", self.activityId, id, num)
		local cfg = csv.yunying.luxurydirectbuygift[id]
		local status = cfg.limit - num
		local isRMB = true
		local price = 0

		if cfg.limit - num > 0 then
			status = STATE_TYPE.CAN_BUY
		else
			status = STATE_TYPE.BOUGHT
		end

		if cfg.rechargeID ~= -1 then
			isRMB = true
			price = csv.recharges[cfg.rechargeID].rmb
		else
			isRMB = false
			price = cfg.rmbCost
		end
		table.insert(itemsData,{
			csvId = id,
			cfg = cfg,
			boughtStatus = status,
			isRMB = isRMB,
			price = price,
			hasBoughtNum = num,
		})
	end

	-- dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
	self.itemsData:update(itemsData)
end


function ActivityExclusiveLimitDialog:initUI()
	self.title:text(gLanguageCsv.exclusiveRestrictionTip)
	self.rule:hide()
	self:setTimeLabel()
end

function ActivityExclusiveLimitDialog:setTimeLabel()
	self.endTime = gGameModel.role:read("yy_endtime")[self.activityId]
	local  timeNum = self.endTime - time.getTime()
	if timeNum < 0 then
		self.timeLabel:text(gLanguageCsv.activityOver)
	end
	self:enableSchedule():schedule(function()
		timeNum = self.endTime - time.getTime()
		local tTime = time.getCutDown(timeNum)
		if timeNum <= 0 then
			self.timeLabel:text(gLanguageCsv.activityOver)
			return false
		else
			local str = ""
			if tTime.day >= 1 then
				str = tTime.str
			else
				str = tTime.clock_str
			end
			self.timeLabel:text(gLanguageCsv.exclusiveRestrictionClose .. str)
			return true
		end
	end, 1, 0)
end

function ActivityExclusiveLimitDialog:clickCell(list, k, v)
	if v.isRMB then
		gGameApp:payDirect(self, {rechargeId = v.cfg.rechargeID, yyID = self.activityId, csvID = v.csvId, name = v.cfg.titleName, buyTimes = v.hasBoughtNum}, self.clientBuyTimes)
			:serverCb(function()
				local cfg = csv.yunying.luxurydirectbuygift[v.csvId]
				gGameUI:showGainDisplay(cfg.item, {raw = false})
			end)
			:doit()
	else
		if gGameModel.role:read("rmb") < v.cfg.rmbCost then
			uiEasy.showDialog("rmb")
			return
		end
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			self.clientBuyTimes:notify()
			gGameUI:showGainDisplay(v.cfg.item, {raw = false})
		end, self.activityId, v.csvId)
	end
end

function ActivityExclusiveLimitDialog:onRules()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function ActivityExclusiveLimitDialog:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.giftRluer)
		end),
		c.noteText(123002, 123006),
	}
	return context
end

return ActivityExclusiveLimitDialog