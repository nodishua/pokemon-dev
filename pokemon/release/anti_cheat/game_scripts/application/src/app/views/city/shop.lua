-- @date:   2018-10-16
-- @desc:

local MonthCardView = require "app.views.city.activity.month_card"

local SHOP_REFRESH_PERIODS = {9, 12, 18, 21}

local LIMIT = 16

local LINE_NUM = 4


local SHOP_PROTOCOL = {
	[1] = "/game/fixshop/buy",
	[2] = "/game/union/shop/buy",
	[3] = "/game/frag/shop/buy",
	[4] = "/game/pw/shop/buy",
	[5] = "/game/explorer/shop/buy",
	[6] = "/game/random_tower/shop/buy",
	[7] = "/game/craft/shop/buy",
	[8] = "/game/equipshop/buy",
	[9] = "/game/union/fight/shop/buy",
	[10] = "/game/cross/craft/shop/buy",
	[11] = "/game/cross/arena/shop/buy",
	[12] = "/game/fishing/shop/buy",
	[13] = "/game/cross/online/shop/buy",
	[15] = "/game/cross/mine/shop",
	[16] = "/game/hunting/shop",
}

local SHOP_REFRESH_PROTOL = {
	[1] = "/game/fixshop/refresh",
	[2] = "/game/union/shop/refresh",
	[3] = "/game/frag/shop/refresh",
	[5] = "/game/explorer/shop/refresh",
	[6] = "/game/random_tower/shop/refresh",
	[12] = "/game/fishing/shop/refresh",
}

local SHOP_TYPE = gShopType
local SHOP_GET_PROTOL = game.SHOP_GET_PROTOL
local SHOP_INIT = game.SHOP_INIT

local REFRESHKEYS = {
	[3] = "fragShopRefreshLimit",
	[5] = "explorerShopRefreshLimit",
	[12] = "fishingShopRefreshLimit",
}


local MOUTHREFRESHKEYS = {
	[3] = "fragShopRefreshLimit",
}

local function isPvpShop(index)
	local pvpShop = {
		SHOP_INIT.PVP_SHOP,
		SHOP_INIT.CRAFT_SHOP,
		SHOP_INIT.UNION_FIGHT_SHOP,
		SHOP_INIT.CROSS_CRAFT_SHOP,
		SHOP_INIT.CROSS_ARENA_SHOP,
		SHOP_INIT.ONLINE_FIGHT_SHOP,
		SHOP_INIT.CROSS_MINE_SHOP,
		SHOP_INIT.HUNTING_SHOP,
	}
	return itertools.include(pvpShop, index)
end

local function protocolParams(index, ...)
	if isPvpShop(index) then
		local params = {...}
		return params[1], params[4]
	else
		return ...
	end
end

local function setUnlockIcon(isLocked, item, params)
	item:removeChildByName("_lock_res_")
	if not isLocked then
		return
	end
	local size = item:size()
	local defaultPos = cc.p(size.width * 0.5, size.height * 0.5)
	params = params or {}
	local res = ccui.ImageView:create(params.res or "common/btn/btn_lock1.png")
		:xy(params.pos or defaultPos)
		:scale(params.scale or 1)
		:addTo(item, params.zOrder or 10, "_lock_res_")
	return res
end

-- 是否显示, 满足条件，不满足条件加锁显示
local function isShowCondition(cfg)
	local level = gGameModel.role:read("level")
	local vipLevel = gGameModel.role:read("vip_level")
	local condition = vipLevel >= cfg.vipStart and level >= cfg.levelRange[1] and level <= cfg.levelRange[2]
	return condition or cfg.showUnable
end

local function getShopItems(csvShop, shopType, shopTime)
	local level = gGameModel.role:read("level")
	local vipLevel = gGameModel.role:read("vip_level")
	local t = {}
	for i,v in orderCsvPairs(csvShop) do
		local show = isShowCondition(v)
		if matchLanguage(v.languages) and show then
			local itemID, count = csvNext(v.itemMap)
			table.insert(t, {csvID = i, type = shopType, level = level, vip = vipLevel, itemID = itemID, count = count})
		end

		if shopTime and v.beginDate ~= 0 and v.endDate ~= 0 then
			shopTime[i] = v
		end
	end
	return t
end

local function onInitItem(list, node, index, v)
	local childList = node:get("list")
	local img1 = node:get("img1")
	local normalBtn = node:get("normal")
	local selectBtn = node:get("selected")

	if v.select == true then
		local width = list.childItem:size().width
		local height = list.childItem:size().height * #v.data

		node:size(node:size().width, height + 160)
		img1:y(height)
		normalBtn:hide()
		selectBtn:y(height + 160/2)

		childList:size(width,height)
		childList:anchorPoint(cc.p(0, 1))
		childList:y(height)

		bind.extend(list, childList, {
			event = "extend",
			class = "listview",
			props = {
				data = v.data,
				item = list.childItem,
				onItem = function(childList, item, k, v)
					idlereasy.when(list.showTab, function (_, showTab)
						if not tolua.isnull(item) then
							local normal = item:get("normal")
							local selected = item:get("selected")
							local panel
							if v.tabIndex == showTab then
								normal:hide()
								panel = selected:show()
							else
								selected:hide()
								panel = normal:show()
							end
							panel:scale(1)
							panel:get("txt"):setFontSize(v.fontSize)
							panel:get("txt"):text(v.name)
							panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
							selected:setTouchEnabled(false)
							if k == #childList.data then
								normal:loadTextureNormal("city/shop/btn_w_3.png")
								selected:loadTextureNormal("city/shop/btn_r_3.png")
							end
							setUnlockIcon(v.isLocked and not v.select, normal, {pos = cc.p(300, 105)})
							bind.touch(childList, normal, {methods = {ended = functools.partial(list.clickChildCell, v.tabIndex, v)}})
						end
					end):anonyOnly(list, "childItem"..v.tabIndex)
				end,
			},
		})
	else
		childList:hide()
		img1:hide()

		node:size(node:size().width, 160)
		normalBtn:y(160/2)
		selectBtn:hide()
	end
end


local function initShopItemOne(list, node, k ,v)
	local specialKey = {}
	if dataEasy.isUnlock(gUnlockCsv.fragShopMaxStar) then
		specialKey["maxStar"] = true
	end
	node:get("limit"):hide()
	if v.isLimit and v.type == SHOP_INIT.EQUIP_SHOP then
		node:get("limit"):show()
		if not matchLanguage({"cn", "tw"}) then
			node:get("limit.textNote"):hide()
			node:get("limit.imgBg"):loadTexture("common/icon/sign_purple_en.png")
		end
	end
	local discount = MonthCardView.getPrivilegeAddition("fixShopDiscount") or 0
	node:get("discount"):hide()
	if v.type == 1 and discount ~= 0 then
		node:get("discount"):show()
		if matchLanguage({"cn", "tw"}) then
			node:get("discount.textNote"):text(string.format(gLanguageCsv.discount, (1 - discount) * 10))
		else
			node:get("discount.textNote"):text(string.format(gLanguageCsv.discount, tostring(discount*100)))
			node:get("discount.textNote"):scale(0.8)
		end
	end
	local childs = node:multiget("name", "icon", "num", "recoverPanel", "btnBuy", "maskPanel")
	local newChilds = childs.maskPanel:multiget("lockTxt", "lock", "lockCondition", "txt")
	itertools.invoke({newChilds.lockTxt, newChilds.lock, newChilds.lockCondition}, "hide")
	local shopDetail = SHOP_TYPE[v.type][v.csvID]
	local buys = childs.btnBuy:multiget("txt", "icon")
	local isLimit = shopDetail.limitType ~= 0
	local maxLimit = shopDetail.limitTimes
	childs.recoverPanel:get("recover"):visible(false)
	-- idx == 1 购买次数  idx == 2 购买时间 例如 201910910
	v.shopLimit = v.shopLimit or {}
	local item = dataEasy.getCfgByKey(v.itemID)
	childs.icon:hide()
	-- node:removeChildByName("clipper")
	if item then
		bind.extend(list, node, {
			class = "icon_key",
			props = {
				data = {
					key = v.itemID,
				},
				specialKey = specialKey,
				simpleShow = true,
				onNode = function(node)
					node:setTouchEnabled(false)
					node:xy(childs.icon:xy())
						:scale(1.5)
						:z(3)
				end,
			},
		})
		local name = uiEasy.setIconName(v.itemID, nil, {node = childs.name})
		local textMaxWidth = node:width() - 150
		if matchLanguage({"en", "kr"}) then
        	adapt.setTextAdaptWithSize(childs.name, {size = cc.size(node:width() - 150, 120), vertical = "center", horizontal = "center", margin = -5, maxLine= 2})
		else
			adapt.setTextScaleWithWidth(childs.name, childs.name:text(), node:width() - 150)
		end
		local targetNum = shopDetail.itemCount
		if (not targetNum or targetNum == 0) then
			targetNum = v.count
		end
		childs.num:text("x".. mathEasy.getShortNumber(targetNum))
		local key, val = csvNext(shopDetail.costMap)
		local cost = dataEasy.getCfgByKey(key)
		buys.icon:texture(dataEasy.getIconResByKey(key))
		val = v.type == 1 and math.ceil((1 - discount) * tonumber(val)) or val
		buys.txt:text(val)
		local iconSize = buys.icon:getBoundingBox()
		local txtSize = buys.txt:size()
		buys.icon:x(childs.btnBuy:width()/2 - iconSize.width - txtSize.width / 2 + 20)
		adapt.oneLinePos(buys.icon, buys.txt, cc.p(10, 0), "left")
	end

	local lockShow = v.lockShow
	local lockShowStr
	if not lockShow and shopDetail and shopDetail.fishingLevelRange then
		local fishLevel = gGameModel.fishing:read("level")
		if fishLevel < shopDetail.fishingLevelRange[1] or fishLevel > shopDetail.fishingLevelRange[2] then
			lockShow = true
			lockShowStr = gLanguageCsv.angling .. string.format(gLanguageCsv.reachLevelCanBuy, shopDetail.fishingLevelRange[1])
		end
	end
	if not lockShow and v.type == game.SHOP_INIT.ONLINE_FIGHT_SHOP and shopDetail and shopDetail.topScore then
		local onlineFightInfo = gGameModel.role:read("cross_online_fight_info")
		local maxScore = math.max(onlineFightInfo.unlimited_top_score, onlineFightInfo.limited_top_score)
		if maxScore < shopDetail.topScore then
			lockShow = true
			lockShowStr = string.format(gLanguageCsv.onlineFightShopCanBuy, shopDetail.topScore)
		end
	end

	itertools.invoke({newChilds.lockTxt, newChilds.lock, newChilds.lockCondition}, "visible", lockShow == true)
	if lockShow then
		childs.maskPanel:show()
		newChilds.txt:hide()
		childs.btnBuy:hide()
		if lockShowStr then
			if matchLanguage({"en"}) then
				newChilds.lockCondition:anchorPoint(0.5,0.4)
			end
			newChilds.lockCondition:text(lockShowStr)
		end
		if v.level < shopDetail.levelRange[1] or v.level > shopDetail.levelRange[2] then
			newChilds.lockCondition:text(string.format(gLanguageCsv.reachLevelCanBuy, shopDetail.levelRange[1]))
		end
		if v.vip < shopDetail.vipStart then
			newChilds.lockCondition:text(string.format(gLanguageCsv.reachVipLevelCanBuy, shopDetail.vipStart))
		end
		return
	end
	if isLimit then
		childs.maskPanel:hide()
		childs.recoverPanel:show()
		if childs.recoverPanel:get("emm") then
			childs.recoverPanel:get("emm"):removeFromParent()
		end
		local str
		local lastTime
		-- 周期限购商品
		if shopDetail.limitType == 1 then
			lastTime = maxLimit
			if tonumber(v.shopLimit[2]) == tonumber(time.getTodayStr()) then
				lastTime = math.max(maxLimit - (v.shopLimit[1] or 0), 0)
			end
			str = string.format(gLanguageCsv.currDayBuyLimit, lastTime, maxLimit)

		elseif shopDetail.limitType == 2 then
			lastTime = maxLimit
			if tonumber(v.shopLimit[2]) == tonumber(time.getWeekStrInClock()) then
				lastTime = math.max(maxLimit - (v.shopLimit[1] or 0), 0)
			end
			str = string.format(gLanguageCsv.currWeekBuyLimit, lastTime, maxLimit)

		elseif shopDetail.limitType == 3 then
			lastTime = maxLimit
			if tonumber(v.shopLimit[2]) == tonumber(time.getMonthStrInClock()) then
				lastTime = math.max(maxLimit - (v.shopLimit[1] or 0), 0)
			end
			str = string.format(gLanguageCsv.currMonthBuyLimit, lastTime, maxLimit)

		else
			lastTime = math.max(v.shopLimit[1] and maxLimit - v.shopLimit[1] or maxLimit, 0)
			str = string.format(gLanguageCsv.foreverBuyLimit, lastTime, maxLimit)
		end
		childs.maskPanel:visible(lastTime == 0)

		local rich = rich.createByStr(str, 40)
		rich:formatText()
		rich:addTo(childs.recoverPanel, 10, "emm")
			:alignCenter(childs.recoverPanel:size())
			:y(30)
		node:setTouchEnabled(true)
		cache.setShader(childs.btnBuy, false, lastTime == 0 and "hsl_gray" or "normal")
		cache.setShader(buys.icon, false, lastTime == 0 and "hsl_gray" or "normal")

	elseif shopDetail.exchangeLimit then
		childs.maskPanel:hide()
		if shopDetail.exchangeLimit == -1 then
			childs.recoverPanel:hide()
		else
			if childs.recoverPanel:get("emm") then
				childs.recoverPanel:get("emm"):removeFromParent()
			end
			local buyTimes = v.buyTimes or 0
			local recoverTime = v.recoverTimes or shopDetail.exchangeLimit - buyTimes
			local currTime = cc.clampf(recoverTime, 0, shopDetail.exchangeLimit)
			childs.recoverPanel:show()
			local isCountdown = recoverTime < shopDetail.exchangeLimit
			childs.recoverPanel:get("recover"):visible(isCountdown)

			local color = currTime >= 1 and "#C0x60C456#" or "#C0xF76B45#"
			local str
			if isCountdown and v.timeStr then
				str = string.format(gLanguageCsv.shopBuyLimit, color, currTime, shopDetail.exchangeLimit, v.timeStr)
			else
				str = string.format(gLanguageCsv.shopBuyLimitNoDay, color, currTime, shopDetail.exchangeLimit)
			end
			local rich = rich.createByStr(str, 40)
			rich:formatText()
			rich:addTo(childs.recoverPanel, 10, "emm")
				:alignCenter(childs.recoverPanel:size())
				:y(30)
			node:setTouchEnabled(recoverTime >= 1)
		end

	else
		childs.recoverPanel:hide()
		childs.maskPanel:visible(v.buyTimes == true)
		cache.setShader(childs.btnBuy, false, v.buyTimes and "hsl_gray" or "normal")
		cache.setShader(buys.icon, false, v.buyTimes and "hsl_gray" or "normal")
		if v.buyTimes then
			text.addEffect(buys.txt, {color = ui.COLORS.DISABLED.WHITE})
		else
			text.addEffect(buys.txt, {color = ui.COLORS.NORMAL.WHITE})
		end
		node:setTouchEnabled(v.buyTimes ~= true)
	end

	bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, list:getIdx(k), v)}})
end

local function initShopItemTwo(list, node, k , v)
	local childs  = node:multiget("bg","btnBuy","imageAdd","maskPanel","txtName")

	nodetools.map({childs.imageAdd,childs.maskPanel}, "visible", false)

	local size = childs.bg:size()
	local maskValue = 80 			-- 部分遮罩不覆盖的地方 需要手动设置遮罩 0-255
	local mask = ccui.Scale9Sprite:create()

	mask:initWithFile(cc.rect(82, 82, 1, 1), "common/icon/mask_card.png")
	mask:size(size.width - 39, size.height - 39)
		:alignCenter(size)

	local skinCsv = gSkinCsv[v.skinId]
	local unitId = dataEasy.getUnitId(nil, v.skinId)
	local unitCsv = csv.unit[unitId]

	local sp     = cc.Sprite:create(unitCsv.cardShow)
	local spSize = sp:size()
	local soff   = cc.p(unitCsv.cardShowPosC.x/unitCsv.cardShowScale, -unitCsv.cardShowPosC.y/unitCsv.cardShowScale)
	local ssize  = cc.size(size.width/unitCsv.cardShowScale, size.height/unitCsv.cardShowScale)
	local rect   = cc.rect((spSize.width-ssize.width)/2-soff.x, (spSize.height-ssize.height)/2-soff.y, ssize.width, ssize.height)

	sp:alignCenter(size)
		:scale(unitCsv.cardShowScale + 0.2)
		:setTextureRect(rect)

	childs.bg:removeChildByName("clipping")
	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:size(size)
		:alignCenter(childs.bg:size())
		:add(sp)
		:addTo(childs.bg,1, "clipping")

	childs.txtName:text(skinCsv.name)
	childs.bg:texture(skinCsv.skinFrameRes)

	local buys = childs.btnBuy:multiget("txt", "icon")
	local key, val = csvNext(v.costMap)
	local cost = dataEasy.getCfgByKey(key)
	buys.icon:texture(dataEasy.getIconResByKey(key))
	buys.txt:text(val)
	local iconSize = buys.icon:getBoundingBox()
	local txtSize = buys.txt:size()
	buys.icon:x(childs.btnBuy:width()/2 - iconSize.width - txtSize.width / 2 + 20)
	adapt.oneLinePos(buys.icon, buys.txt, cc.p(10, 0), "left")

	if v.isHave then
		childs.maskPanel:visible(true)
		cache.setShader(childs.btnBuy, false, "hsl_gray")
		cache.setShader(buys.icon, false,"hsl_gray")
		childs.bg:texture("city/drawcard/draw/panel_card_gh.png")
		return
	end

	if v.extraItem and csvSize(v.extraItem) == 1 then
		childs.imageAdd:visible(true)

		local key, num= csvNext(v.extraItem)
		local itemCsv = csv.items[key]
		local imgIcon     = cc.Sprite:create(itemCsv.icon)
		imgIcon:alignCenter(imgIcon:size())
			:scale(1.2)
			:xy(cc.p(80,80))
			:addTo(childs.imageAdd)
	end

	bind.touch(list, node, {methods = {ended = functools.partial(list.itemSkinClick, k, v)}})
end


local ViewBase = cc.load("mvc").ViewBase
local ShopView = class("ShopView", ViewBase)
ShopView.RESOURCE_FILENAME = "shop.json"
ShopView.RESOURCE_BINDING = {
	["leftPanel.item"] = "leftItem",
	["leftPanel.list"] = {
		binds = {
			{
				event = "extend",
				class = "listview",
				props = {
					data = bindHelper.self("leftDatas"),
					item = bindHelper.self("leftItem"),
					preloadCenter = bindHelper.self("showTab"),
					itemAction = {isAction = true},
					onItem = function(list, node, k, v)
						local normal = node:get("normal")
						local selected = node:get("selected")
						local panel
						if v.select then
							normal:hide()
							panel = selected:show()
						else
							selected:hide()
							panel = normal:show()
							panel:get("subTxt"):text(v.subName)
						end
						panel:scale(1)
						local maxWidth = panel:size().width - 50
						adapt.setTextScaleWithWidth(panel:get("txt"), v.name, maxWidth)

						selected:setTouchEnabled(false)
						setUnlockIcon(v.isLocked and not v.select, normal, {pos = cc.p(300, 130)})
						bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					end,
				},
				handlers = {
					clickCell = bindHelper.self("onLeftItemClick"),
				},
			},
			{
				event = "visible",
				idler = bindHelper.self("isShopClassity"),
				method = function(val)
					return val == false
				end,
			},
		},
	},
	["leftPanel.itemParent"] = "itemParent",
	["leftPanel.itemChild"] = "itemChild",
	["leftPanel.listClassify"] = {
		varname = "leftList",
		binds = {
			{
				event = "extend",
				class = "listview",
				itemAction = {isAction = true},
				props = {
					data = bindHelper.self("newLeftDatas"),
					item = bindHelper.self("itemParent"),
					childItem = bindHelper.self("itemChild"),
					preloadCenter = bindHelper.self("classifyShowTab"),
					showTab = bindHelper.self("showTab"),
					onItem = function(list, node, k, v)
						onInitItem(list, node, k, v)
						if v.select == true then
							bind.touch(list, node:get("selected"), {methods = {ended = functools.partial(list.clickCell, k, v)}})
						else
							bind.touch(list, node:get("normal"), {methods = {ended = functools.partial(list.clickCell, k, v)}})
						end
						adapt.setTextScaleWithWidth(node:get("selected"):get("txt"), v.name, node:get("selected"):width() - 20)
						adapt.setTextScaleWithWidth(node:get("normal"):get("txt"), v.name, node:get("normal"):width() - 20)
						list:forceDoLayout()
					end,
				},
				handlers = {
					clickCell = bindHelper.self("onNewLeftItemClick"),
					clickChildCell = bindHelper.self("onLeftItemClick")
				},
			},
			{
				event = "visible",
				idler = bindHelper.self("isShopClassity"),
			},
		},
	},

	["item"] = "item",
	["rightPanel"] = "rightPanel",
	["rightPanel.subList"] = "subList",
	["rightPanel.slider"] = "slider",
	["rightPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("shopData"),
				columnSize = bindHelper.self("rightColumnSize"),
				sliderBg = bindHelper.self("slider"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				btnIdx = bindHelper.self("showTab"),
				asyncPreload = bindHelper.self("rightAsyncPreload"),
				itemAction = {isAction = true, actionTime = 0.2, duration = 0.1},
				onCell = function(list, node, k, v)

					local childs = node:multiget("item1", "item2")
					local sign = (v.type == SHOP_INIT.SKIN_SHOP)
					childs.item1:visible(not sign)
					childs.item2:visible(sign)

					if sign then
						initShopItemTwo(list, childs.item2, k ,v)
					else
						initShopItemOne(list, childs.item1, k ,v)
					end

				end,
				onBeforeBuild = function(list)
					if list.sliderBg:visible() then
						list.sliderShow = true
						list.sliderBg:hide()
					end
					if #list.data <= 2 * list.columnSize then
						list:setScrollBarEnabled(false)
						list:setTouchEnabled(false)
					else
						list:setTouchEnabled(true)
					end
				end,
				onAfterBuild = function(list)
					if list.sliderShow then
						list.sliderBg:show()
						list.sliderShow = false
					end
					if #list.data <= 2 * list.columnSize then
						list.sliderBg:hide()
						list:setScrollBarEnabled(false)
						list:setTouchEnabled(false)
					else
						list.sliderBg:show()
						list:setTouchEnabled(true)
						local listX, listY = list:xy()
						local listSize = list:size()
						local x, y = list.sliderBg:xy()
						local size = list.sliderBg:size()
						list:setScrollBarEnabled(true)
						list:setScrollBarColor(cc.c3b(241, 59, 84))
						list:setScrollBarOpacity(255)
						list:setScrollBarAutoHideEnabled(false)
						list:setScrollBarPositionFromCorner(cc.p(25, (listSize.height - size.height) / 2 + 5))
						list.sliderBg:x(listX + listSize.width - 25)
						list:setScrollBarWidth(size.width)
						list:refreshView()
					end


				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
				itemSkinClick = bindHelper.self("onItemSkinClick"),
			},
		},
	},
	["rightPanel.bottomPanel.btnRefresh"] = {
		varname = "btnRefresh",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					return view:onRefreshClick()
				end)}
			},
		},
	},
	["rightPanel.bottomPanel.refreshTime"] = "refreshTime",
	["rightPanel.bottomPanel.cost"] = {
		varname = "bottomCost",
		binds = {
			event = "text",
			idler = bindHelper.self("textFixShopRefreshCost")
		}
	},
	["rightPanel.bottomPanel.times"] = {
		varname = "textTimes",
		binds = {
			event = "text",
			idler = bindHelper.self("textFixShopRefreshTimes"),
		}
	},
	["rightPanel.bottomPanel.txt"] = "txt",
	["rightPanel.bottomPanel.txt2"] = "txt2",
	["rightPanel.bottomPanel.txt3"] = "txt3",
	["rightPanel.bottomPanel.icon"] = "fixDiamond",
	["rightPanel.bottomPanel"] = "rightBottomPanel",
	["rightPanel.bottomPanel.txt4"] = "txt4",
	["rightPanel.bottomPanel.icon1"] = "icon1",
	["rightPanel.bottomPanel.num"] = "numTxt",
	["rightPanel.bottomPanel.btn"] = {
		varname = "btn",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					return view:onRefreshClick(true)
				end)}
			},
		},
	},
}

function ShopView:initIndexModel(index)
	local children = self.rightBottomPanel:getChildren()
	itertools.invoke(children, "hide")
	self.rightBottomPanel:get("refreshTime"):show()
	if isPvpShop(index) then
		local datas = {
			[SHOP_INIT.PVP_SHOP] = {
				shop = self.pvpShop,
				shopItems = self.pvpShopItems,
				title = "pvp_shop",
			},
			[SHOP_INIT.CRAFT_SHOP] = {
				shop = self.craftShop,
				shopItems = self.craftShopItems,
				title = "craft_shop",
			},
			[SHOP_INIT.UNION_FIGHT_SHOP] = {
				shop = self.union_shop,
				shopItems = self.unionItems,
				title = "union_fight_shop",
			},
			[SHOP_INIT.CROSS_CRAFT_SHOP] = {
				shop = self.crossCraftShop,
				shopItems = self.crossCraftShopItems,
				title = "cross_craft_shop",
			},
			[SHOP_INIT.CROSS_ARENA_SHOP] = {
				shop = self.crossArenaShop,
				shopItems = self.crossArenaShopItems,
				title = "cross_arena_shop",
			},
			[SHOP_INIT.ONLINE_FIGHT_SHOP] = {
				shop = self.onlineFightShop,
				shopItems = self.onlineFightShopItems,
				title = "cross_online_fight_shop",
			},
			[SHOP_INIT.CROSS_MINE_SHOP] = {
				shop = self.crossMineShop,
				shopItems = self.crossMineShopItems,
				title = "cross_mine_shop",
			},
			[SHOP_INIT.HUNTING_SHOP] = {
				shop = self.huntingShop,
				shopItems = self.huntingShopItems,
				title = "hunting_shop",
			},
		}

		idlereasy.any({datas[index].shop, datas[index].shopItems, self.shopLimit, self.vipLevel, self.level}, function (obj, data, items, shopLimit, vipLevel, level)
			local index = self.showTab:read()
			if isPvpShop(index) then
				local refresh = clone(items)
				local sortValue
				for i=1,#refresh do
					local refData = refresh[i]
					local csvID = refData.csvID
					if SHOP_TYPE[index].sortValue then
						refData.sortValue = SHOP_TYPE[index].sortValue
						sortValue = true
					end
					if data[csvID] then
						local t = data[csvID]
						refData.buyTimes = t[1]
						refData.lastRecoverTime =t[2]
						if refData.lastRecoverTime then
							local cfg = SHOP_TYPE[refData.type][refData.csvID]
							local cfgTime = cfg.regainHour * 60 * 60
							local buyTimes = refData.buyTimes or 0
							local lastTimes = cfg.exchangeLimit -refData.buyTimes
							refData.lastRecoverTime = math.floor(refData.lastRecoverTime)
							local time1 = time.getTime() - refData.lastRecoverTime
							local times = math.floor(time1 / cfgTime)
							local currTotalTime = times + lastTimes
							if currTotalTime >= cfg.exchangeLimit then
								refData.timeStr = nil
							else
								refData.timeStr = time.getCutDown(math.abs(math.floor((times + 1) * cfgTime - time1))).str
							end
							if refData.recoverTimes ~= currTotalTime then
								refData.recoverTimes = currTotalTime
							end
						end
					end
					local title = datas[index].title or ""
					if shopLimit[title] and shopLimit[title][csvID] then
						refData.shopLimit = shopLimit[title][csvID]
					end
				end
				if sortValue then
					table.sort(refresh, function(a, b)
						if a.sortValue ~= b.sortValue then
							return a.sortValue < b.sortValue
						end
						return a.csvID < b.csvID
					end)
				end
				dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
				self.shopData:update(refresh)
			end
		end):anonyOnly(self)

	elseif index == SHOP_INIT.EQUIP_SHOP then
		gGameApp:requestServer(SHOP_GET_PROTOL[index], function()
			local idlerData = self.idlerDatas[index]
			local shopItems = gGameModel[idlerData.modelType]:getIdler("items")
			local shopBuy = gGameModel[idlerData.modelType]:getIdler("buy")
			idlereasy.any({shopItems, self.showTab, shopBuy, self.shopLimit, self.vipLevel, self.level}, function (obj, items, showTab, buyDict, shopLimit, vip, level)
				local equipShopLimit = shopLimit.equip_shop or {}
				local prevDay
				self:enableSchedule():schedule(function()
					if showTab ~= SHOP_INIT.EQUIP_SHOP then
						return
					end

					local sortDatas = {}
					local count = 0
					local currDay = tonumber(time.getTodayStr())
					for csvID, v in orderCsvPairs(csv.equip_shop) do
						local show = isShowCondition(v)
						if matchLanguage(v.languages) and v.type == 1 and show and
							((v.beginDate == 0 and v.endDate == 0) or (currDay >= v.beginDate and currDay <= v.endDate)) then
							local itemID, num = csvNext(v.itemMap)
							table.insert(sortDatas, {
								shopLimit = equipShopLimit[csvID] or {},
								index = v.position,
								csvID = csvID,
								type = SHOP_INIT.EQUIP_SHOP,
								level = level,
								vip = vip,
								itemID = itemID,
								count = num,
							})
							count = count + 1
						end
					end

					for i, v in pairs(items) do
						count = count + 1
						local csvID, itemID = v[1], v[2]
						table.insert(sortDatas, {
							csvID = csvID,
							itemID = itemID,
							index = i,
							buyTimes = buyDict[i],
							type = index,
							shopLimit = equipShopLimit[csvID] or {},
							vip = vip,
							level = level,
							isLimit = true
						})
					end
					table.sort(sortDatas, function (a, b)
						return a.index < b.index
					end)
					if prevDay ~= currDay then
						self.shopData:update(sortDatas)
						prevDay = currDay
					end
				end, 1, 0, "equipShop")
			end):anonyOnly(self)

			local children = self.rightBottomPanel:getChildren()
			itertools.invoke(children, "hide")
			self.rightBottomPanel:get("refreshTime"):show()
		end)
	elseif index == SHOP_INIT.SKIN_SHOP then
		idlereasy.any({self.skins, self.showTab,self.vipLevel}, function(_, skins, showTab, vipLevel)
			if showTab ~= SHOP_INIT.SKIN_SHOP then
				return
			end
			local sortData = {}
			for index, v in pairs(gSkinShopCsv) do
				local itemId  = csvNext(v.itemMap)
				local itemCsv = csv.items[itemId]
				local skinId  = itemCsv.specialArgsMap.skinID
				local skinCsv = gSkinCsv[skinId]
				local data = {
					id             = index,
					skinId         = skinId,
					itemId         = itemId,
					costMap        = v.costMap,
					litSkinNum     = v.litSkinNum,
					vipStart       = v.vipStart,
					startTime      = v.beginDate,
					endTime        = v.endDate,
					extraItem      = v.extraItem,
					isHave         = skins[skinId] == 0,
					type           = SHOP_INIT.SKIN_SHOP,
					showUnable     = v.showUnable,
					rank           = skinCsv.rank,
				}

				sortData[#sortData + 1] = data
			end
			table.sort(sortData,function(v1,  v2)
				local a = v1.isHave and 1 or 0
				local b = v2.isHave and 1 or 0
				a = a*100000 + v1.rank
				b = b*100000 + v2.rank
				return a < b
			end)

			self.shopData:update(sortData)

	end):anonyOnly(self)

	else
		if self.pageIdx ~= index and SHOP_GET_PROTOL[index] then
			gGameApp:requestServer(SHOP_GET_PROTOL[index], function()
				self:initIdler(index)
			end)
		else
			self:initIdler(index)
		end
	end
end

function ShopView:initIdler(index)
	local idlerData = self.idlerDatas[index]
	local shopItems = gGameModel[idlerData.modelType]:getIdler("items")
	local shopBuy = gGameModel[idlerData.modelType]:getIdler("buy")
	local hash = itertools.map(game.SHOP_INIT, function(k, v) return v, k end)
	idlereasy.any({shopItems, self.showTab, shopBuy, self.shopLimit, self.vipLevel, self.level, self.fishLevel}, function (obj, items, showTab, buyDict, shopLimit, vip, level)
		if showTab == index then
			local title = string.lower(hash[index])
			self:initData(index, items, buyDict, shopLimit[title], vip, level)
		end
	end):anonyOnly(self)
	idlereasy.any({idlerData.refreshShopTime, self.vipLevel, self.showTab, self.items}, function (obj, times, vipLevel, showTab, items)
		for k,v in pairs(self.idlerDatas) do
			local vipCfg = gVipCsv[vipLevel]
			v.allNum = vipCfg[REFRESHKEYS[k] or "shopRefreshLimit"]

			if MOUTHREFRESHKEYS[k] then
				v.allNum = v.allNum + (MonthCardView.getPrivilegeAddition(MOUTHREFRESHKEYS[k]) or 0)
			end
		end

		local children = self.rightBottomPanel:getChildren()
		itertools.invoke(children, "hide")
		if showTab == SHOP_INIT.EQUIP_SHOP or showTab == SHOP_INIT.ONLINE_FIGHT_SHOP then
			self.rightBottomPanel:get("refreshTime"):show()
		else
			itertools.invoke(children, "show")
			local useTime = times or 0
			local allNum = idlerData.allNum
			local leftTimes = allNum - useTime
			if not self.shopRefreshLeftTimes then
				self.shopRefreshLeftTimes = {}
			end
			self.shopRefreshLeftTimes[showTab] = leftTimes
			self.textFixShopRefreshTimes:set(leftTimes .. "/" .. allNum)
			self.textTimes:text(leftTimes .. "/" .. allNum)
			text.addEffect(self.textTimes, {color = leftTimes == 0 and ui.COLORS.NORMAL.ALERT_ORANGE or ui.COLORS.NORMAL.FRIEND_GREEN})
			local costIndex = math.min(useTime + 1, table.length(idlerData.refreshCost))
			self.textFixShopRefreshCost:set(idlerData.refreshCost[costIndex])
			self.bottomCost:text(idlerData.refreshCost[costIndex])
			self.fixDiamond:show()
			local count = items[game.ITEM_TICKET.shopRefresh] or 0
			self.numTxt:text("x"..count)
			itertools.invoke({self.btn, self.numTxt, self.icon1, self.txt4}, "visible", count ~= 0)
			adapt.oneLinePos(self.btnRefresh, {self.txt, self.textTimes, self.txt2, self.bottomCost, self.fixDiamond, self.txt3}, {cc.p(5, 0),cc.p(5, 0),cc.p(5, 0),cc.p(30, 0),cc.p(0, 0),cc.p(0, 0)}, "right")
			adapt.oneLinePos(self.refreshTime, {self.txt4, self.icon1, self.numTxt, self.btn}, {cc.p(30, 0),cc.p(0, 0),cc.p(0, 0),cc.p(0,0)}, "left")
		end
	end):anonyOnly(self)
end

function ShopView:initData(index, items, buyDict, shopLimit, vip, level)
	local buyDict = buyDict or {}
	local sortDatas = {}
	local shopLimit = shopLimit or {}
	self.max = self.max or {}
	if not isPvpShop(index) and not self.max[index] then
		self.max[index] = {}
		for k, v in orderCsvPairs(SHOP_TYPE[index]) do
			local id = csvNext(v.itemWeightMap)
			self.max[index][v.position] = {pos = false, itemID = id, csvID = k, showUnable = v.showUnable, type = v.type}
		end
	end
	for i, v in pairs(items) do
		self.max[index][i].pos = true
		table.insert(sortDatas, {csvID = v[1], itemID = v[2], index = i, buyTimes = buyDict[i], type = index, shopLimit = shopLimit[i], vip = vip, level = level})
	end
	if not isPvpShop(index) and self.max[index] then
		for k,v in pairs(self.max[index]) do
			if not v.pos and v.showUnable then
				table.insert(sortDatas, {index = k, type = index, itemID = v.itemID, csvID = v.csvID, lockShow = true, vip = vip, level = level, count = v.count})
			end
		end
	end
	table.sort(sortDatas, function (a, b)
		return a.index < b.index
	end)
	dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
	self.shopData:update(sortDatas)

	return sortDatas
end

function ShopView:getTimeShow()
	local showTab = self.showTab:read()
	if showTab == SHOP_INIT.ONLINE_FIGHT_SHOP then
		return math.huge
	end
	if showTab == SHOP_INIT.EQUIP_SHOP then
		local date = time.getNumTimestamp(tonumber(self.equipShopRefresh), time.getRefreshHour())
		local cur = time.getTime()

		return date + gCommonConfigCsv.equipShopRefreshDays * 24 * 3600 - cur
	end
	local currTime = time.getNowDate()
	local index = 0
	for i, v in ipairs(SHOP_REFRESH_PERIODS) do
		if currTime.hour < v then
			index = i
			break
		end
	end
	local isNextDay = index == 0
	index = index == 0 and 1 or index
	local t = {
		year = currTime.year,
		month = currTime.month,
		day = isNextDay and currTime.day + 1 or currTime.day,
		hour = showTab ~= SHOP_INIT.FISHING_SHOP and SHOP_REFRESH_PERIODS[index] or time.getRefreshHour()
	}
	local time = time.getTimestamp(t) - time.getTime()
	return time
end

function ShopView:onCreate(pageIdx)
	local itemWidth = self.item:size().width
	local count = 0
	adapt.centerWithScreen("left", "right", nil, {
		{self.subList, "width"},
		{self.list, "width", function(width)
			count = math.floor(width/itemWidth)
			local dw = (width - count * itemWidth)/2
			self.list:x(self.list:x() + dw)
			self.refreshTime:x(self.refreshTime:x() + dw)
			self.btnRefresh:x(self.btnRefresh:x() + width)
			adapt.oneLinePos(self.btnRefresh, {self.txt, self.textTimes, self.txt2, self.bottomCost, self.fixDiamond, self.txt3, self.btn, self.numTxt, self.icon1, self.txt4}, {cc.p(15, 0),cc.p(15, 0),cc.p(25, 0),cc.p(50, 0),cc.p(0, 0),cc.p(0, 0),cc.p(20, 0),cc.p(0, 0),cc.p(0, 0),cc.p(0,0)}, "right")
			return count * itemWidth + dw
		end},
		{self.rightPanel, "width"},
		{self.rightPanel, "pos", "left"},
	})

	self.rightColumnSize = LINE_NUM + count
	self.rightAsyncPreload = self.rightColumnSize * 3
	self:initModel()

	self.specialTime = {}
	self.unionTime = {}
	self.specialTimeCraft = {}
	self.specialTimeCrossCraft = {}
	self.specialTimeCrossArena = {}
	self.specialTimeCrossMine = {}
	self.specialTimeHunting = {}
	self.specialTimeOnlineFight = {}
	self.shopRefreshLeftTimes = {}

	self.pvpShopItems = idlertable.new(getShopItems(csv.pwshop, SHOP_INIT.PVP_SHOP, self.specialTime))
	self.unionItems = idlertable.new(getShopItems(csv.union_fight.shop, SHOP_INIT.UNION_FIGHT_SHOP, self.unionTime))
	self.craftShopItems = idlertable.new(getShopItems(csv.craft.shop, SHOP_INIT.CRAFT_SHOP, self.specialTimeCraft))
	self.crossCraftShopItems = idlertable.new(getShopItems(csv.cross.craft.shop, SHOP_INIT.CROSS_CRAFT_SHOP, self.specialTimeCrossCraft))
	self.crossArenaShopItems = idlertable.new(getShopItems(csv.cross.arena.shop, SHOP_INIT.CROSS_ARENA_SHOP, self.specialTimeCrossArena))
	self.onlineFightShopItems = idlertable.new(getShopItems(csv.cross.online_fight.shop, SHOP_INIT.ONLINE_FIGHT_SHOP, self.specialTimeOnlineFight))
	self.crossMineShopItems = idlertable.new(getShopItems(csv.cross.mine.shop, SHOP_INIT.CROSS_MINE_SHOP, self.specialTimeCrossMine))
	self.huntingShopItems = idlertable.new(getShopItems(csv.cross.hunting.shop, SHOP_INIT.HUNTING_SHOP, self.specialTimeHunting))

	self.isShopClassity = dataEasy.getListenShow(gUnlockCsv.shopClassity)
	self.shopData = idlers.new()
	self.textFixShopRefreshTimes = idler.new("")
	self.textFixShopRefreshCost = idler.new(0)
	self.textRefreshTimes = idler.new(0)
	local leftDatas = {
		[1] = {tabIndex = 1,name = gLanguageCsv.spaceHandpick, subName = "HandPick", show = true, topui = "default", rightBottomShow = true},
		[2] = {tabIndex = 2,unlockKey = "unionShop", name = gLanguageCsv.spaceGuild, subName = "Union", show = true, topui = "union", rightBottomShow = true, isLocked = not self.unionId:read()},
		[3] = {tabIndex = 3,unlockKey = "fragmentShop", name = gLanguageCsv.spaceFragment, subName = "Fragment", show = true, topui = "fragment", rightBottomShow = true},
		[4] = {tabIndex = 4,unlockKey = "arenaShop", name = gLanguageCsv.spacePvp, subName = "Arena", show = true, topui = "arena"},
		[5] = {tabIndex = 5,unlockKey = "explorer", name = gLanguageCsv.explorer, subName = "Explorer", show = true, topui = "explorer", rightBottomShow = true},
		[6] = {tabIndex = 6,unlockKey = "randomTower", name = gLanguageCsv.randomTower, subName = "AetherParadise", show = true, topui = "random_tower", rightBottomShow = true},
		[7] = {tabIndex = 7,unlockKey = "craft", name = gLanguageCsv.craft, subName = "Craft", show = true, topui = "craft"},
		[8] = {tabIndex = 8,unlockKey = "drawEquip", name = gLanguageCsv.equipShop, subName = "Accessories", show = true, topui = "drawcard", rightBottomShow = true},
		[9] = {tabIndex = 9,unlockKey = "unionFight", name = gLanguageCsv.unionCombet, subName = "UnionCombet", show = true, topui = "union_combet", isLocked = not self.unionId:read()},
		[10] = {tabIndex = 10,unlockKey = "crossCraft", name = gLanguageCsv.crossCraft, subName = "CrossCraft", show = true, topui = "cross_craft"},
		-- [11] = {tabIndex = 11,unlockKey = "crossArena", name = gLanguageCsv.crossArena, subName = "CrossArena", show = true, topui = "cross_arena"},
		[12] = {tabIndex = 12,unlockKey = "fishing", name = gLanguageCsv.fishing, subName = "fishing", show = true, rightBottomShow = true, topui = "fishing"},
		[13] = {tabIndex = 13,unlockKey = "onlineFight", name = gLanguageCsv.onlineFight, subName = "battleArena", show = true, rightBottomShow = true, topui = "online_fight"},
		[14] = {tabIndex = 14,unlockKey = "skinShop", name = gLanguageCsv.skin, subName = "skin", show = true, topui = "card_skin"},
		[15] = {tabIndex = 15,unlockKey = "crossMine", name = gLanguageCsv.crossMine, subName = "CrossMine", show = true, topui = "cross_mine"},
		[16] = {tabIndex = 16,unlockKey = "hunting", name = gLanguageCsv.huntingArea, subName = "Hunting", show = true, topui = "hunting"},
	}
	--保存解锁状态
	local leftDatasUnlock = {
		[1] = true,
	}
	for k, v in pairs(leftDatas) do
		if v.unlockKey then
			dataEasy.getListenUnlock(v.unlockKey, functools.partial(function(tabIdx, isUnlock)
				if isUnlock then
					if dataEasy.judgeServerOpen(v.unlockKey) then
						leftDatasUnlock[tabIdx] = true
						return
					end
				end
				leftDatasUnlock[tabIdx] = false
			end, k))
		end
	end
	local data = {}
	for k, v in pairs(leftDatasUnlock) do
		if v == true then
			data[k] = leftDatas[k]
		end
	end
	self.leftDatas = idlers.new()
	self.leftDatas:update(data)

	--新的分类
	local newData = {}
	for k,v in orderCsvPairs(csv.shop) do
		if leftDatas[k] then
			leftDatas[k].shopType = v.group
			leftDatas[k].fontSize = v.fontSize
		end
	end
	for k, v in pairs(leftDatasUnlock) do
		if v == true then
			local type = leftDatas[k].shopType or 1
			newData[type] = newData[type] or {name = gLanguageCsv["shopTab"..type]}
			newData[type].data = newData[type].data or {}
			table.insert(newData[type].data,leftDatas[k])
		end
	end

	self.newLeftDatas = idlers.new()
	self.newLeftDatas:update(newData)
	local classifyShowTab = 1
	self.pageIdx = self._pageIdx or pageIdx or 1
	-- 若跳转的页签未开放，这显示为第一个页签
	if not leftDatasUnlock[self.pageIdx] then
		self.pageIdx = 1
	end
	for k, v in pairs(leftDatas) do
		if k == self.pageIdx then
			classifyShowTab = v.shopType
			break
		end
	end

	self.classifyShowTab = idler.new(classifyShowTab)
	self.classifyShowTab:addListener(function(val, oldVal, _)
		if oldVal ~= 0 then
			self.newLeftDatas:atproxy(oldVal).select = false
		end
		if val ~= 0 then
			self.newLeftDatas:atproxy(val).select = true
		end

		performWithDelay(self, function()
			self.leftList:refreshView()
			 local width = self.leftList:size().height
			 local innterWidth = self.leftList:getInnerContainerSize().height
			 local pos = self.leftList:getInnerContainerPosition()

			if width == innterWidth and pos.y ~= 0 then
				self.leftList:jumpToTop()
			end
		end, 0.01)
	end)

	self.showTab = idler.new(self.pageIdx)
	self.textFixShopRefreshTime = idler.new(self:getTimeShow())
	self.showTab:addListener(function(val, oldval, idler)
		self.textFixShopRefreshTime:set(self:getTimeShow())
		self.rightBottomPanel:visible(self.leftDatas:atproxy(val).rightBottomShow == true)
		if self.leftDatas:atproxy(val).show then
			if self.topView then
				gGameUI.topuiManager:removeView(self.topView)
			end
			self.list:show()
			self.list:jumpToTop()
			dataEasy.tryCallFunc(self.list, "setItemAction", {isAction = true, actionTime = 0.2, duration = 0.1})
			self:initIndexModel(val)
			self.topView = gGameUI.topuiManager:createView(self.leftDatas:atproxy(val).topui, self, {onClose = self:createHandler("onClose")})
				:init({title = gLanguageCsv.supermarket, subTitle = "SUPERMARKET"})
			if self.leftDatas:atproxy(val).isRefresh then
				self.leftDatas:atproxy(val).isRefresh = false
				if SHOP_GET_PROTOL[val] then
					gGameApp:requestServer(SHOP_GET_PROTOL[val])
				end
			end
		else
			self.list:hide()
		end
		self.leftDatas:atproxy(oldval).select = false
		self.leftDatas:atproxy(val).select = true
	end)

	idlereasy.any({self.showTab, self.textFixShopRefreshTime}, function(_, showTab, val)
		local str
		if showTab == SHOP_INIT.ONLINE_FIGHT_SHOP then
			str = gLanguageCsv.onlineFightShopTip

		elseif showTab == SHOP_INIT.EQUIP_SHOP then
			str = string.format(gLanguageCsv.limitItemSchedule, time.getCutDown(val).str)
		else
			str = string.format(gLanguageCsv.nextRefreshTime, time.getCutDown(val).str)
		end
		self.refreshTime:text(str)
		adapt.oneLinePos(self.refreshTime, {self.txt4, self.icon1, self.numTxt, self.btn}, {cc.p(30, 0),cc.p(0, 0),cc.p(0, 0),cc.p(0,0)}, "left")
	end)

	performWithDelay(self, function()
		self:enableSchedule():schedule(function ()
			self.textFixShopRefreshTime:modify(function (val)
				if val == 0 then
					local protocol = SHOP_GET_PROTOL[self.showTab:read()]
					if protocol then
						gGameApp:requestServer(protocol)
					end
					return true, self:getTimeShow()
				end
				return true, val - 1
			end)

			local function refreshShopItem(specialTime, shopItems, csvShop, shopType)
				local timeOver = {}
				for k,v in pairs(specialTime) do
					local begin = tonumber(v.beginDate)
					local over = tonumber(v.endDate)
					local currDay = tonumber(time.getTodayStr())
					if begin > currDay or over < currDay then
						timeOver[k] = true
						specialTime[k] = nil
					end
				end
				idlereasy.do_(function (val, vip, level)
					if itertools.size(timeOver) > 0 then
						local t = {}
						for i = 1, #val do
							if not timeOver[val.csvID] then
								table.insert(t, val[i])
							end
						end
						shopItems:set(newVal)
					end
					local newShopItems = getShopItems(csvShop, shopType)
					if not itertools.equal(val, newShopItems) then
						shopItems:set(t)
					end
				end, shopItems, self.vipLevel, self.level)
			end
			refreshShopItem(self.specialTime, self.pvpShopItems, csv.pwshop, SHOP_INIT.PVP_SHOP)
			refreshShopItem(self.unionTime, self.unionItems, csv.union_fight.shop, SHOP_INIT.UNION_FIGHT_SHOP)
			refreshShopItem(self.specialTimeCraft, self.craftShopItems, csv.craft.shop, SHOP_INIT.CRAFT_SHOP)
			refreshShopItem(self.specialTimeCrossCraft, self.crossCraftShopItems, csv.cross.craft.shop, SHOP_INIT.CROSS_CRAFT_SHOP)
			refreshShopItem(self.specialTimeCrossArena, self.crossArenaShopItems, csv.cross.arena.shop, SHOP_INIT.CROSS_ARENA_SHOP)
			refreshShopItem(self.specialTimeCrossMine, self.crossMineShopItems, csv.cross.mine.shop, SHOP_INIT.CROSS_MINE_SHOP)
			refreshShopItem(self.specialTimeHunting, self.huntingShopItems, csv.cross.hunting.shop, SHOP_INIT.HUNTING_SHOP)

			for i=1,self.shopData:size() do
				local data = self.shopData:atproxy(i)
				if data.lastRecoverTime then
					local cfg = SHOP_TYPE[data.type][data.csvID]
					local cfgTime = SHOP_TYPE[data.type][data.csvID].regainHour * 60 * 60
					local buyTimes = data.buyTimes or 0
					local lastTimes = cfg.exchangeLimit - data.buyTimes
					local time1 = time.getTime() - data.lastRecoverTime
					local times = math.floor(time1 / cfgTime)
					local currTotalTime = times + lastTimes
					if currTotalTime >= cfg.exchangeLimit then
						data.timeStr = nil
					else
						data.timeStr = time.getCutDown(math.abs(math.floor((times + 1) * cfgTime - time1))).str
					end
					if data.recoverTimes ~= currTotalTime then
						data.recoverTimes = currTotalTime
					end
				end
			end
		end, 1, 0, "ShopView")
	end, 1)


end

function ShopView:onCleanup()
	self._pageIdx = self.showTab:read()
	ViewBase.onCleanup(self)
end

function ShopView:initModel()
	self.rmb = gGameModel.role:getIdler("rmb")
	self.gold = gGameModel.role:getIdler("gold")
	self.skins = gGameModel.role:getIdler("skins")
	self.equipAwakeFrag = gGameModel.role:getIdler("equip_awake_frag")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.pvpShop = gGameModel.role:getIdler("pvp_shop")
	self.craftShop = gGameModel.role:getIdler("craft_shop")
	self.union_shop = gGameModel.role:getIdler("union_fight_shop")
	self.crossCraftShop = gGameModel.role:getIdler("cross_craft_shop")
	self.crossArenaShop = gGameModel.role:getIdler("cross_arena_shop")
	self.crossMineShop = gGameModel.role:getIdler("cross_mine_shop")
	self.huntingShop = gGameModel.role:getIdler("hunting_shop")
	self.onlineFightShop = gGameModel.role:getIdler("cross_online_fight_shop")
	self.level = gGameModel.role:getIdler("level")
	self.shopLimit = gGameModel.role:getIdler("shop_limit")
	self.unionId = gGameModel.role:getIdler("union_db_id")
	self.items = gGameModel.role:getIdler("items")
	self.equipShopRefresh = gGameModel.global_record:read("equip_shop_refresh")
	self.fishLevel = gGameModel.fishing:getIdler("level")
	local curVipLevel = self.vipLevel:read()
	self.idlerDatas = {
		[1] = {
			modelType = "fix_shop",
			refreshShopTime = gGameModel.daily_record:getIdler("fix_shop_refresh_times"),
			refreshCost = gCostCsv.fixshop_refresh_cost,
			allNum = gVipCsv[curVipLevel].shopRefreshLimit,
		},
		[2] = {
			modelType = "union_shop",
			refreshShopTime = gGameModel.daily_record:getIdler("union_shop_refresh_times"),
			refreshCost = gCostCsv.unionshop_refresh_cost,
			allNum = gVipCsv[curVipLevel].shopRefreshLimit,
		},
		[3] = {
			modelType = "frag_shop",
			refreshShopTime = gGameModel.daily_record:getIdler("frag_shop_refresh_times"),
			refreshCost = gCostCsv.fragshop_refresh_cost,
			allNum = gVipCsv[curVipLevel].fragShopRefreshLimit + (MonthCardView.getPrivilegeAddition("fragShopRefreshLimit") or 0),
		},
		[5] = {
			modelType = "explorer_shop",
			refreshShopTime = gGameModel.daily_record:getIdler("explorer_shop_refresh_times"),
			refreshCost = gCostCsv.explorershop_refresh_cost,
			allNum = gVipCsv[curVipLevel].explorerShopRefreshLimit,
		},
		[6] = {
			modelType = "random_tower_shop",
			refreshShopTime = gGameModel.daily_record:getIdler("randomTower_shop_refresh_times"),
			refreshCost = gCostCsv.randomTowerShop_refresh_cost,
			allNum = gVipCsv[curVipLevel].shopRefreshLimit,
		},
		[8] = {
			modelType = "equip_shop",
			allNum = gVipCsv[curVipLevel].shopRefreshLimit,
		},
		[12] = {
			modelType = "fishing_shop",
			refreshCost = gCostCsv.fishingshop_refresh_cost,
			refreshShopTime = gGameModel.daily_record:getIdler("fishing_shop_refresh_times"),
			allNum = gVipCsv[curVipLevel].fishingShopRefreshLimit,
		},
	}
end

function ShopView:onLeftItemClick(list, index, v)
	if (index == SHOP_INIT.UNION_SHOP or index == SHOP_INIT.UNION_FIGHT_SHOP) and v.isLocked then
		gGameUI:showTip(gLanguageCsv.canUsedEnteringGuild)
		return
	end
	self.showTab:set(index)
end

function ShopView:onNewLeftItemClick(list, index, v)
	if not v.select  then
		self.classifyShowTab:set(index)
		for k, v in pairs( v.data) do
			self.showTab:set(v.tabIndex)
			break
		end
	else
		self.classifyShowTab:set(0)
	end
end

function ShopView:onRefreshClick(isUseBall)
	local index = self.showTab:read()
	if isUseBall then
		local str = gLanguageCsv.ballRefreshShop
		gGameUI:showDialog{strs = {"#C0x5B545B#"..str, gLanguageCsv.ballNotCostTime}, cb = function ()
			gGameApp:requestServer(SHOP_REFRESH_PROTOL[index],function (tb)
				gGameUI:showTip(gLanguageCsv.refreshSuccessful)
			end, true)
		end, btnType = 2, isRich = true, dialogParams = {clickClose = false}}
		return
	end
	if self.shopRefreshLeftTimes[index] <= 0 then
		gGameUI:showTip(gLanguageCsv.refreshLimit)
		return
	end
	if self.rmb:read() < self.textFixShopRefreshCost:read() then
		uiEasy.showDialog("rmb")
		return
	end
	local str = string.format(gLanguageCsv.shopRefreshCommonBox, self.textFixShopRefreshCost:read())
	gGameUI:showDialog{strs = "#C0x5B545B#"..str, cb = function ()
		gGameApp:requestServer(SHOP_REFRESH_PROTOL[index],function (tb)
			gGameUI:showTip(gLanguageCsv.refreshSuccessful)
		end, false)
	end, btnType = 2, isRich = true, dialogParams = {clickClose = false}}
end

function ShopView:onItemClick(list, t, v)
	local data = self.shopData:atproxy(t.k)
	self.data = data
	local shopDetail = SHOP_TYPE[v.type][data.csvID]
	local targetNum = shopDetail.itemCount
	if (not targetNum or targetNum == 0) then
		targetNum = v.count
	end
	self.num = targetNum
	local maxNum = 1 -- 购买上限，默认1，(基本商店的通用规则，一次只能购买一个，到一定时间刷新, 竞技场商店和石英大会除外)
	local contentType -- 进度条是否显示, 默认不显示
	local maxLimit = shopDetail.limitTimes
	local shopT = {
		SHOP_INIT.PVP_SHOP,
		SHOP_INIT.CRAFT_SHOP,
		SHOP_INIT.UNION_FIGHT_SHOP,
		SHOP_INIT.CROSS_CRAFT_SHOP,
		SHOP_INIT.CROSS_ARENA_SHOP,
		SHOP_INIT.CROSS_MINE_SHOP,
		SHOP_INIT.HUNTING_SHOP
	}
	if itertools.include(shopT, self.showTab:read()) then
		contentType = "num"
		if shopDetail.exchangeLimit == -1 then
			maxNum = math.huge
		else
			local buyTimes = v.buyTimes or 0
			local recoverTime = v.recoverTimes or shopDetail.exchangeLimit - buyTimes
			local currTime = math.min(recoverTime, shopDetail.exchangeLimit)
			maxNum = currTime
		end
	end

	-- 饰品商店
	if self.showTab:read() == SHOP_INIT.EQUIP_SHOP then
		contentType = "num"
		if shopDetail.type == 1 then
			maxNum = math.huge
		else
			maxNum = shopDetail.itemCount
		end
	end

	-- 周期限购商品(对所有商店适用，且覆盖exchangeLimit参数效用)
	if shopDetail.limitType == 1 then
		maxNum = maxLimit
		if tonumber(v.shopLimit[2]) == tonumber(time.getTodayStr()) then
			maxNum = maxLimit - (v.shopLimit[1] or 0)
		end
		contentType = "num"

	elseif shopDetail.limitType == 2 then
		maxNum = maxLimit
		if tonumber(v.shopLimit[2]) == tonumber(time.getWeekStrInClock()) then
			maxNum = maxLimit - (v.shopLimit[1] or 0)
		end
		contentType = "num"

	elseif shopDetail.limitType == 3 then
		maxNum = maxLimit
		if tonumber(v.shopLimit[2]) == tonumber(time.getMonthStrInClock()) then
			maxNum = maxLimit - (v.shopLimit[1] or 0)
		end
		contentType = "num"

	elseif shopDetail.limitType == 4 then
		maxNum = maxLimit - (v.shopLimit[1] or 0)
		contentType = "num"
	end

	-- 精选商店折扣计算(其它商店目前暂无折扣)
	local discount = (v.type == SHOP_INIT.FIX_SHOP) and (1 - (MonthCardView.getPrivilegeAddition("fixShopDiscount") or 0)) or 1
	gGameUI:stackUI("common.buy_info", nil, nil, shopDetail.costMap, {id = data.itemID, num = self.num}, {maxNum = maxNum, discount = discount, contentType=contentType}, self:createHandler("showBuyInfo"))
end


function ShopView:onItemSkinClick(list,k, v)

	local str = gLanguageCsv.skinTip01
	local key, num = csvNext(v.costMap)
	local sign = true

	str = str..string.format("%d#I%s-56-56#",num,dataEasy.getIconResByKey(key))

	if dataEasy.getNumByKey(key) < num then
		sign = false
	end

	local skinCsv = gSkinCsv[v.skinId]
	local id,num = csvNext(v.extraItem)
	local award = {{v.itemId, 1}}
	if id then
		award[#award+1] = {id, num}
	end

	if sign then
		gGameUI:showDialog({
			strs = string.format(gLanguageCsv.skinTip02,str,skinCsv.name),
			cb = function()
				gGameApp:requestServer("/game/card/skin/shop/buy",function (tb)
					gGameUI:showGainDisplay(award, {raw = false})
				end, v.id, 1)
			end,
			isRich = true,
			btnType = 2,
			dialogParams = {clickClose = false},
		})
	else
		uiEasy.showDialog(key)

	end
end

function ShopView:showBuyInfo(num)
	gGameApp:requestServer(SHOP_PROTOCOL[self.data.type], function(tb)
		gGameUI:showGainDisplay({{self.data.itemID, self.num * num}}, {raw = false})
	end, protocolParams(self.data.type,
		not isPvpShop(self.data.type) and self.data.index or self.data.csvID,
		self.data.csvID,
		self.data.itemID,
		num)
	)
end

return ShopView

