-- @date 2020-10-10
-- @desc 携带道具限时分解

local ActivityQualityExchangeHelditemView = class("ActivityQualityExchangeHelditemView", cc.load("mvc").ViewBase)

ActivityQualityExchangeHelditemView.RESOURCE_FILENAME = "activity_quality_exchange_helditem.json"
ActivityQualityExchangeHelditemView.RESOURCE_BINDING = {
	["numList"] = "numList",
	["btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnClick")}
		},
	},
	["btn.label"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["costPanel"] = "costPanel",
	["leftItem"] = {
		varname = "leftItem",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLeftItemClick")}
		},
	},
	["rightItem"] = "rightItem",
}

function ActivityQualityExchangeHelditemView:onCreate(activityId)
	self.activityId = activityId
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.rmb = gGameModel.role:getIdler("rmb")
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID

	self.datas = {}
	local rightKey
	for k, v in orderCsvPairs(csv.yunying.qualityexchange) do
		if v.huodongID == huodongID then
			local key, num = next(v.items[1])
			self.datas[v.quality] = {csvId = k, cfg = v, key = key, num = num, rmb = v.costMap.rmb or 0}
			if not rightKey then
				 rightKey = key
			end
		end
	end
	local rightData = idlereasy.new({key = rightKey})
	bind.extend(self, self.rightItem, {
		class = "icon_key",
		props = {
			data = rightData,
		},
	})

	idlereasy.any({self.yyhuodongs, self.vipLevel}, function(_, yyhuodongs, vipLevel)
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		-- 可分解次数 = 活动表基础次数 + vip表对应品质的等级特权次数
		local vipCfg = gVipCsv[vipLevel]
		local leftTimes = {}
		for k, v in csvPairs(yyCfg.paramMap.quality) do
			table.insert(leftTimes, {quality = k, leftTimes = v + (vipCfg.heldItemExchangeTimes[k] or 0) - (stamps[k] or 0)})
		end
		table.sort(leftTimes, function(a, b)
			return a.quality < b.quality
		end)

		local strs = {}
		for _, v in ipairs(leftTimes) do
			if self.datas[v.quality] then
				self.datas[v.quality].leftTimes = v.leftTimes
			end
			table.insert(strs, {str = string.format(gLanguageCsv.qualityExchangeHelditemDesc, ui.QUALITYCOLOR[v.quality],
				gLanguageCsv[ui.QUALITY_COLOR_TEXT[v.quality]], v.leftTimes > 0 and "#C0x60C456#" or "#C0xF13B54#", v.leftTimes)})
		end
		beauty.textScroll({
			list = self.numList,
			strs = strs,
			isRich = true,
			margin = 10,
		})
	end)

	self.selectId = idler.new()
	idlereasy.any({self.selectId, self.rmb}, function(_, selectId, rmb)
		self.costPanel:hide()
		self.selectData = nil
		if not selectId then
			self.leftItem:get("icon"):show()
			self.leftItem:get("add"):show()
			rightData:set({key = rightKey})
		else
			local heldItem = gGameModel.held_items:find(selectId)
			if heldItem then
				local itemData = heldItem:read("held_item_id", "advance", "card_db_id", "level")
				local quality = dataEasy.getCfgByKey(itemData.held_item_id).quality
				self.leftItem:get("icon"):hide()
				self.leftItem:get("add"):hide()
				bind.extend(self, self.leftItem, {
					class = "icon_key",
					props = {
						data = {
							key = itemData.held_item_id,
							num = 1,
						},
						specialKey = {
							lv = itemData.level,
						},
						noListener = true,
						onNode = function(panel)
							panel:setTouchEnabled(false)
						end,
					}
				})
				local quality = dataEasy.getCfgByKey(itemData.held_item_id).quality
				self.selectData = self.datas[quality]
				if self.selectData then
					rightData:set({key = self.selectData.key, num = self.selectData.num})

					local childs = self.costPanel:multiget("txt", "num", "icon")
					childs.num:text(self.selectData.rmb)
					text.addEffect(childs.num, {color = rmb >= self.selectData.rmb and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED})
					adapt.oneLineCenterPos(cc.p(200, 30), {childs.txt, childs.num, childs.icon}, cc.p(10, 0))
					self.costPanel:show()
				end
			end
		end
	end)
end

function ActivityQualityExchangeHelditemView:onInit()
	self.selectId:set()
end

function ActivityQualityExchangeHelditemView:getQualities()
	local qualities = {}
	for k, v in pairs(self.datas) do
		if v.leftTimes and v.leftTimes > 0 then
			qualities[k] = v.leftTimes
		end
	end
	return qualities
end

function ActivityQualityExchangeHelditemView:onLeftItemClick()
	local qualities = self:getQualities()
	if itertools.isempty(qualities) then
		gGameUI:showTip(gLanguageCsv.qualityExchangeHelditemTimes)
		return
	end
	gGameUI:stackUI("city.activity.quality_exchange_helditem_select", nil, nil, qualities, self:createHandler("onChooseItem"))
end

function ActivityQualityExchangeHelditemView:onChooseItem(id)
	self.selectId:set(id)
end

function ActivityQualityExchangeHelditemView:onBtnClick()
	if itertools.isempty(self:getQualities()) then
		gGameUI:showTip(gLanguageCsv.qualityExchangeHelditemTimes)
		return
	end
	if not self.selectData then
		gGameUI:showTip(gLanguageCsv.qualityExchangeFragmentChooseTip)
		return
	end
	if self.rmb:read() < self.selectData.rmb then
		uiEasy.showDialog("rmb")
		return
	end

	gGameUI:showDialog({
		cb = function()
			local selectId = self.selectId:read()
			local csvId = self.selectData.csvId
			gGameApp:requestServer("/game/yy/award/exchange", function(tb)
				self.selectId:set(nil)
				gGameUI:showGainDisplay(tb)
			end, self.activityId, csvId, selectId, 1, 1)
		end,
		btnType = 2,
		isRich = true,
		content = "#C0x5B545B#" .. gLanguageCsv.qualityExchangeHelditemExchangeTip,
	})
end

return ActivityQualityExchangeHelditemView