-- @date 2018-12-23
-- @desc 道具兑换 (限时兑换)

-- 可兑换，未达成 (不可兑换)，已兑换
local STATE_TYPE = {
	canExchange = 1,
	noReach = 2,
	exchanged = 3,
}

local ActivityItemExchangeView = class("ActivityItemExchangeView", cc.load("mvc").ViewBase)

ActivityItemExchangeView.RESOURCE_FILENAME = "activity_item_exchange.json"
ActivityItemExchangeView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("list", "item", "img", "checkPanel", "exchangebtn", "exchanged", "times")
					childs.list:size(1100, 200)
					uiEasy.createItemsToList(list, childs.list, v.costMap, {padding = 5})

					local centerPos = cc.p(100, 100)
					local x, y = childs.list:xy()
					local dx = x + math.min(childs.list:getInnerItemSize().width, childs.list:size().width)
					childs.img:x(dx + 150)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num
							},
							onNode = function(node)
								node:xy(dx + 300 + centerPos.x, y + centerPos.y)
									:z(5)
							end,
						},
					})

					itertools.invoke({childs.checkPanel, childs.exchangebtn, childs.times}, "visible", v.state ~= STATE_TYPE.exchanged)
					childs.exchanged:visible(v.state == STATE_TYPE.exchanged)
					childs.checkPanel:get("checkBox"):setSelectedState(v.remind)
					childs.checkPanel:onClick(functools.partial(list.remindClick, k, v))
					childs.times:text(string.format(gLanguageCsv.canExchangeTImes, cfg.exchangeTimes - v.cnt, cfg.exchangeTimes))
					if matchLanguage({"en"}) then
						childs.times:x(childs.times:x() - 60)
					end
					if v.state == STATE_TYPE.canExchange then
						cache.setShader(childs.exchangebtn, false, "normal")
						text.addEffect(childs.exchangebtn:get("label"), {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})

					elseif v.state == STATE_TYPE.noReach then
						cache.setShader(childs.exchangebtn, false, "hsl_gray")
						text.deleteAllEffect(childs.exchangebtn:get("label"))
						text.addEffect(childs.exchangebtn:get("label"), {color = ui.COLORS.DISABLED.WHITE})
					end
					bind.touch(list, childs.exchangebtn, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 5,
			},
			handlers = {
				remindClick = bindHelper.self("onRemindClick"),
				clickCell = bindHelper.self("onExchangeClick"),
			},
		},
	},
}

function ActivityItemExchangeView:onCreate(activityId)
	self.activityId = activityId
	self:initModel()
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	self.datas = idlers.new()
	self.remind = idler.new(false)
	idlereasy.any({self.yyhuodongs, self.remind}, function(_, yyhuodongs)
		local data = userDefault.getForeverLocalKey("activityItemExchange", {})
		self.remindData = data[activityId] or {}
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.itemexchange) do
			if v.huodongID == huodongID then
				local state = STATE_TYPE.noReach
				local cnt = stamps[k] or 0
				local ok = true
				local costMap = {}
				for k, v in csvMapPairs(v.costMap) do
					local num = dataEasy.getNumByKey(k)
					table.insert(costMap, {key = k, num = num, targetNum = v})
					if num < v then
						ok = false
					end
				end
				if cnt >= v.exchangeTimes then
					state = STATE_TYPE.exchanged
				elseif ok then
					state = STATE_TYPE.canExchange
				end
				local key, num = csvNext(v.items)
				table.insert(datas, {csvId = k, cfg = v, key = key, num = num, state = state, cnt = cnt, cost = v.costMap, costMap = costMap, remind = self.remindData[k] or false})
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.datas:update(datas)
	end)
end

function ActivityItemExchangeView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityItemExchangeView:onRemindClick(list, k, v)
	local remind = not v.remind
	local data = userDefault.getForeverLocalKey("activityItemExchange", {})
	self.remindData[v.csvId] = remind
	data[self.activityId] = self.remindData
	gGameModel.forever_dispatch:getIdlerOrigin("activityItemExchange"):set(data, true)
	self.datas:atproxy(k).remind = remind
end

function ActivityItemExchangeView:onExchangeClick(list, k, v)
	if v.state == STATE_TYPE.canExchange then
		-- maxNum 最大数量
		local maxNum = v.cfg.exchangeTimes - v.cnt

		gGameUI:stackUI("common.buy_info", nil, nil, v.cost, {id = v.key, num = v.num}, {maxNum = maxNum, flag = "exchange", contentType = "num"}, self:createHandler("getBuyInfoCb", v.csvId))
	elseif v.state == STATE_TYPE.noReach then
		gGameUI:showTip(gLanguageCsv.exchangeItemNotEnough)
	end
end

function ActivityItemExchangeView:getBuyInfoCb(csvId, num)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId, num)
end

function ActivityItemExchangeView:remindUpdata()
	self.remind:set(true, true)
end

return ActivityItemExchangeView