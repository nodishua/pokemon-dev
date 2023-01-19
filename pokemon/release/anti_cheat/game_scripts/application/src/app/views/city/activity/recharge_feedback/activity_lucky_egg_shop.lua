-- @date: 2020-01-02 21:34:34
-- @desc: 扭蛋机商店界面

local ITEM_TYPE = {
	vip = 1,
	level = 2,
	handbook = 3,
	head = 4,
	skin = 5,
}

local TIP_TYPE = {
	[1] = gLanguageCsv.luckyEggShopVipNotEnough,
	[2] = gLanguageCsv.luckyEggShopLevelNotEnough,
	[3] = gLanguageCsv.luckyEggShopNoCard,
	[4] = gLanguageCsv.luckyEggShopVipNotEnough,
	[5] = gLanguageCsv.luckyEggShopNoCard,
}

local LuckyEggShopView = class("LuckyEggShopView", cc.load("mvc").ViewBase)

LuckyEggShopView.RESOURCE_FILENAME = "activity_lucky_egg_shop.json"
LuckyEggShopView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["scorePanel.text"] = "scoreText",
	["subList"] = "subList",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("datas"),
				columnSize = 3,
				leftPadding = 1,
				xMargin = 67,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local children = node:get("baseNode"):multiget("text", "icon", "text2", "text3", "costPanel", "emptyPanel", "num")
					bind.extend(list, children.icon, {
						class = "icon_key",
						props = {
							data = {
								key = v.item.key,
								num = v.item.key == "card" and v.item.num or nil,
							},
							noListener = true,
						},
					})
					children.icon:get("_icon_"):setTouchEnabled(false)
					children.text:text(v.name)
					local num = v.item.key == "card" and 1 or v.item.num
					children.num:text("x".. mathEasy.getShortNumber(num, 2))
					children.text3:text(string.format("%s/%s", v.maxTime - v.step, v.maxTime))
					children.costPanel:get("img"):texture(dataEasy.getIconResByKey(v.cost.key))
					children.costPanel:get("text"):text(v.cost.num)
					adapt.oneLineCenterPos(cc.p(136, 40), {children.costPanel:get("img"), children.costPanel:get("text")}, cc.p(15, 0))
					if v.color then
						text.addEffect(children.costPanel:get("text"), {color=v.color})
					end
					if v.maxTime - v.step <= 0 then
						children.emptyPanel:get("tip"):hide()
						children.emptyPanel:show()
					elseif v.canBuy then
						children.emptyPanel:hide()
						bind.touch(list, node:get("baseNode"), {methods = {ended = functools.partial(list.clickCell, t, v)}})
						bind.touch(list, children.icon, {methods = {ended = functools.partial(list.clickCell, t, v)}})
					else
						if v.isHas then
							children.emptyPanel:show()
							children.emptyPanel:get("text"):text(gLanguageCsv.alreadyHas)
							children.emptyPanel:get("tip"):hide()
						else
							children.emptyPanel:show()
							children.emptyPanel:get("text"):text(gLanguageCsv.notUnlock)
							if v.limitKey == ITEM_TYPE[1] or v.limitKey == ITEM_TYPE[2] then
								children.emptyPanel:get("tip"):text(string.format(TIP_TYPE[v.limitKey], v.limitID)):show()
							else
								children.emptyPanel:get("tip"):text(TIP_TYPE[v.limitKey]):show()
							end
							children.costPanel:hide()
							children.text3:hide()
							children.text2:hide()
						end
					end
				end,
				asyncPreload = 9,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
}

function LuckyEggShopView:onCreate(activityId, huodongId)
	self.activityId = activityId
	self.huodongId = huodongId
	self.items = gGameModel.role:getIdler("items")
	self.scoreNum = 0
	idlereasy.when(self.items, function(_, items)
		self.scoreNum = items[game.ITEM_TICKET.luckyEggScore] or 0
		self.scoreText:text(self.scoreNum)
	end)

	self.datas = idlers.new({})
	idlereasy.when(gGameModel.role:getIdler("yyhuodongs"), function(_, yyhuodongs)
		local yyhuodong = yyhuodongs[activityId] or {}
		local steps = yyhuodong.stamps or {}
		local datas = {}
		for k, cfg in csvPairs(csv.yunying.itemexchange) do
			if cfg.huodongID == huodongId then
				local key, num = csvNext(cfg.items)
				local cKey, cNum = csvNext(cfg.costMap)
				local canCost = self.scoreNum >= cNum
				local limitKey, limitID = csvNext(cfg.limit)
				local canBuy = true
				local isHas = false
				if limitKey == ITEM_TYPE.vip then
					canBuy = gGameModel.role:read("vip_level") > limitID
				elseif limitKey == ITEM_TYPE.level then
					canBuy = gGameModel.role:read("level") > limitID
				elseif limitKey == ITEM_TYPE.handbook and not gGameModel.role:read("pokedex")[limitID] then
					canBuy = false
					isHas = false
				elseif limitKey == ITEM_TYPE.head and gGameModel.role:read("logos")[limitID] then
					canBuy = false
					isHas = true
				elseif limitKey == ITEM_TYPE.skin then
					local skinCfg = csv.card_skin[limitID]
					local markID = skinCfg.markID
					if gGameModel.role:read("skins")[limitID] and gGameModel.role:read("skins")[limitID] == 0 then
						canBuy = false
						isHas = true
					end
				end
				local name = cfg.desc
				if key == "card" then
					name = csv.cards[num.id].name
				else
					name = dataEasy.getCfgByKey(key).name
				end
				table.insert(datas, {
					csvId = k,
					name = name,
					item = {key = key, num = num},
					cost = {key = cKey, num = cNum},
					maxTime = cfg.exchangeTimes,
					limitKey = limitKey,
					limitID = limitID,
					canBuy = canBuy,
					isHas = isHas,
					step = steps[k] or 0,
					color = canCost and ui.COLORS.NORMAL.DEFAULT or nil,
				})
			end
		end

		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndexAdaptFirst")
		self.datas:update(datas)
	end)
end

function LuckyEggShopView:onItemClick(list, k, v)
	gGameUI:stackUI("common.buy_info", nil, nil,
		{[v.cost.key] = v.cost.num}, {id = v.item.key, num = v.item.num}, {maxNum = v.maxTime - v.step, flag = "exchange", contentType = "num"},
		self:createHandler("itemBuy", v.csvId, v.cost.num))
end

function LuckyEggShopView:itemBuy(csvId, cost, num)
	if self.scoreNum < cost then
		gGameUI:showTip(gLanguageCsv.luckyEggTip)
		return
	end

	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId, num)
end

return LuckyEggShopView