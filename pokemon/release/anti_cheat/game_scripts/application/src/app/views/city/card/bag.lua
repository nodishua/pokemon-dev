local ViewBase = cc.load("mvc").ViewBase
local CardBagView = class("CardBagView", ViewBase)

local SHOW_TYPE = {
	CARD = 1,
	FRAGMENT = 2,
}
local SORT_DATAS = {
	{
		{name = gLanguageCsv.fighting, val = 1},
		{name = gLanguageCsv.level, val = 2},
		{name = gLanguageCsv.rarity, val = 3},
		{name = gLanguageCsv.star, val = 4},
		{name = gLanguageCsv.getTime, val = 5}
	}, {
		{name = gLanguageCsv.fighting, val = 1},
		{name = gLanguageCsv.level, val = 2},
		{name = gLanguageCsv.star, val = 4},
		{name = gLanguageCsv.getTime, val = 5}
	}, {
		{name = gLanguageCsv.rarity, val = 3},
		{name = gLanguageCsv.numberPieces, val = 6},
		{name = gLanguageCsv.collectDegrees, val = 7}
	}, {
		{name = gLanguageCsv.numberPieces, val = 6},
		--搜集度（当前碎片数量/可合成所需碎片数量）
		{name = gLanguageCsv.collectDegrees, val = 7}
	}
}

local totalSpecialTag =
{
	"advance",
	"effortValue",
	"equipStar",
	"equipStrengthen",
	"equipAwake",
	"equipSignet",
	"star",
	"skill",
	"nvalue",
	"cardFeel",
	"cardDevelop",
	"gemFreeExtract",
	"canZawake",
}

local starSpecialTag =
{
	"star",
}

--排序方法
local function sortData(data, index, order)
	if next(data) == nil then
		return {}
	end
	for k,v in pairs(data) do
		if v.num then
			v.numPercent = v.num / v.maxNum
		end
	end
	local condition = {"fight","level","rarity","star","getTime","num","numPercent"}
	if index == nil then
		table.sort(data, function(a, b)
			for i = 1, 4 do
				if a[condition[i]] ~= b[condition[i]] then
					return a[condition[i]] > b[condition[i]]
				end
			end
			return a[condition[5]] > b[condition[5]]
		end)
	else
		table.sort(data, function(a, b)
			if a.isBg ~= b.isBg then
				return a.isBg
			end
			if a[condition[index]] ~= b[condition[index]] then
				if order then
					return a[condition[index]] > b[condition[index]]
				else
					return a[condition[index]] < b[condition[index]]
				end
			end
			if a.markId ~= b.markId then
				return a.markId < b.markId
			end
			if a.fight and b.fight then
				return a.fight > b.fight
			end
			if a.id and b.id then
				return a.id > b.id
			end
			return false
		end)
	end
	return data
end

--筛选
local function filterData(data, condition)
	if next(data) == nil then
		return {}
	end
	if condition == nil or condition[2] == nil then
		return data
	end
	local function isOK(data, key, val)
		if data[key] == nil then
			if key ~= "attr2" or data.attr1 == val then
				return true
			end
		end
		if key == "atkType" then
			for k, v in ipairs(data.atkType) do
				if val[v] then
					return true
				end
			end
			return false
		end
		if data[key] == val then
			return true
		end
		return false
	end
	local tmp = {}
	for k,v in pairs(data) do
		if isOK(v, condition[1], condition[2]) then
			table.insert(tmp, v)
		end
	end
	return tmp
end

local function filterDo(data, conditions)
	local result = data
	for i = 1, #conditions do
		result = filterData(result, conditions[i])
	end
	return result
end

local function setListBar(list)
	list:setScrollBarEnabled(true)
	list:setScrollBarColor(cc.c3b(255,200,0))
	list:setScrollBarOpacity(255)
	list:setScrollBarWidth(10)
	list:setScrollBarPositionFromCorner(cc.p(100,40))
end

local function setItem(item, childs, v)
	local size = childs.bg:size()
	local maskValue = 80 			-- 部分遮罩不覆盖的地方 需要手动设置遮罩 0-255
	local mask = ccui.Scale9Sprite:create()
	local cardId = dataEasy.getCardIdAndStar(v.id)
	mask:initWithFile(cc.rect(82, 82, 1, 1), "common/icon/mask_card.png")
	mask:size(size.width - 39, size.height - 39)
		:alignCenter(size)
	-- 显示素材图标
	local cardCsv = csv.cards[cardId]
	childs.material:visible(cardCsv and cardCsv.cardType == 2)
	-- setRenderHint(1) 模式下，需要用 setTextureRect 裁剪超框部分
	local sp = cc.Sprite:create(v.icon)
	local spSize = sp:size()
	local soff = cc.p(v.posOffset.x/v.scale, -v.posOffset.y/v.scale)
	local ssize = cc.size(size.width/v.scale, size.height/v.scale)
	local rect = cc.rect((spSize.width-ssize.width)/2-soff.x, (spSize.height-ssize.height)/2-soff.y, ssize.width, ssize.height)

	sp:alignCenter(size)
		:scale(v.scale + 0.2)
		:setTextureRect(rect)

	item:removeChildByName("clipping")
	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:size(size)
		:alignCenter(item:size())
		:add(sp)
		:addTo(item, 5, "clipping")

	childs.qulityNumber:hide()
	-- local quality,numStr = dataEasy.getQuality(v.advance)
	-- local num = tonumber(numStr)
	-- if num then
	-- 	local str = ""
	-- 	-- 暂不显示
	-- 	for i = 1,num do
	-- 		str = str.."0"
	-- 	end
	-- 	local strPath = string.format("city/card/bag/icon_dian%d.png", quality)
	-- 	childs.qulityNumber:setProperty(str,strPath,33,38,'0')			-- 此处设置精灵头上的强化等级
	-- else
	-- 	childs.qulityNumber:hide()
	-- end
	-- 设置名字 暂不显示v.advance
	uiEasy.setIconName("card", cardId, {node = childs.levelNamePanel:get("name"), name = v.name, advance = 1, space = true})
	text.addEffect(childs.levelNamePanel:get("name"), {color = ui.COLORS.NORMAL.WHITE})
	-- 战斗力数字
	childs.fightPointPanel:get("fightPoint"):text(v.fight)
	-- 等级
	childs.levelNamePanel:get("level"):text(v.level)

	adapt.oneLineCenterPos(cc.p(200, -3), {childs.fightPointPanel:get("fightPointTxt"), childs.fightPointPanel:get("fightPoint")}, cc.p(15, 0))
	adapt.oneLineCenterPos(cc.p(200, 13), {childs.levelNamePanel:get("level"),childs.levelNamePanel:get("name")}, cc.p(15, 0))

	childs.bg:texture(string.format("common/icon/panel_card_%d.png", v.rarity+2))
	childs.bottomBg:texture(string.format("city/card/bag/box_bottom_d%d.png", v.rarity+2))
	childs.rarity:texture(ui.RARITY_ICON[v.rarity])
		:scale(1)
		-- :x(35)

	if v.isBg then
		widget.addAnimationByKey(childs.maskBg, "effect/duiwuzhong.skel", "effect", "effect_loop", 20)
			:xy(size.width/2 - 30, size.height/2 - 140)
	end

	childs.attr1:texture(ui.ATTR_ICON[v.attr1])
	if v.attr2 == nil then
		childs.attr2:hide()
	else
		childs.attr2:texture(ui.ATTR_ICON[v.attr2]):show()
	end
end

local function setItemChip(item, childs, v)
	local size = childs.maskBg:size()
	local mask = ccui.Scale9Sprite:create()
	local cfg = dataEasy.getCfgByKey(v.id)
	local quality = cfg.quality
	local name = uiEasy.setIconName(v.id)
	mask:initWithFile(cc.rect(82, 82, 1, 1), "common/icon/mask_card.png")
	mask:size(size.width - 20, size.height - 20)
		:alignCenter(size)
	-- 显示素材图标
	local cardCsv = csv.cards[cfg.combID]
	childs.material:visible(cardCsv and cardCsv.cardType == 2)
	-- setRenderHint(1) 模式下，需要用 setTextureRect 裁剪超框部分
	local sp = cc.Sprite:create(v.icon)
	local spSize = sp:size()
	local soff = cc.p(v.posOffset.x/v.scale, -v.posOffset.y/v.scale)
	local ssize = cc.size(size.width/v.scale, size.height/v.scale)
	local rect = cc.rect((spSize.width-ssize.width)/2-soff.x, (spSize.height-ssize.height)/2-soff.y, ssize.width, ssize.height)

	sp:alignCenter(size)
		-- :xy(size.width/2 + v.posOffset.x, size.height/2 + v.posOffset.y)
		:scale(v.scale + 0.2)
		:setTextureRect(rect)

	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:size(size)
		:alignCenter(item:size())
		:add(sp)
		:addTo(item, 5)

	childs.name:text(name)						-- 设置名字
	text.addEffect(childs.name, {color = ui.COLORS.NORMAL.WHITE})
	childs.numBg:get("num"):text(v.num.."/"..v.maxNum)

	adapt.oneLineCenterPos(cc.p(180, 68), {childs.numBg:get("numTitle"), childs.numBg:get("num")}, cc.p(2, 4))

	childs.rarity:texture(ui.RARITY_ICON[v.rarity])
	if v.isBg then
		childs.rarity:z(11)
			:color(cc.c3b(200, 200, 200))
	end


	childs.attr1:texture(ui.ATTR_ICON[v.attr1])
	if v.attr2 == nil then
		childs.attr2:hide()
	else
		childs.attr2:texture(ui.ATTR_ICON[v.attr2]):show()
	end
end

CardBagView.RESOURCE_FILENAME = "card_bag.json"
CardBagView.RESOURCE_BINDING = {
	["capacityPanel"] = {
		varname = "capacityPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("showBottomRight"),
		}
	},
	["capacityPanel.text"] = "capacityText",
	["capacityPanel.numText"] = "capacityNumText",
	["capacityPanel.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")}
		},
	},
	["btnBattleRecommend"] = {
		varname = "btnBattleRecommend",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBattleRecommendClick")}
		},
	},
	["panelBtn.btn1"] = {
		varname = "btnSprite",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
					return view:onChangeClick(1)
				end)}
		},
	},
	["panelBtn.btn2"] = {
		varname = "btnFragment",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					return view:onChangeClick(2)
				end)}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "bottomFragment",
					listenData = {
						type = bindHelper.self("type"),
					},
					onNode = function(panel)
						panel:xy(280, 120)
					end,
				}
			}
		},
	},
	["panelBtn.btn3"] = {
		varname = "btnDecompose",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onEnterDecompose")}
			},
			{
				event = "visible",
				idler = bindHelper.self("cardRebornListen")
			},
		},
	},
	["panelBtn.btn1.textNote"] = {
		varname = "textNoteSprite",
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["panelBtn.btn2.textNote"] = {
		varname = "textNoteFragment",
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["panelBtn.btn1.imgIcon"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("type"),
			method = function(val)
				local path = "city/card/bag/icon_jl1.png"
				if val == SHOW_TYPE.CARD then
					path = "city/card/bag/icon_jl.png"
				end

				return path
			end,
		},
	},
	["panelBtn.btn2.imgIcon"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("type"),
			method = function(val)
				local path = "city/card/bag/icon_sp1.png"
				if val == SHOW_TYPE.FRAGMENT then
					path = "city/card/bag/icon_sp.png"
				end

				return path
			end,
		},
	},
	["panelBtn.btn3.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["centerPanel"] = {
		varname = "centerPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("sortTabData"),
				showSelected = bindHelper.self("sortKey"),
				width = 310,
				height = 80,
				expandUp = true,
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				showSortList = bindHelper.self("isDownListShow"),
				onNode = bindHelper.self("onSortMenusNode", true),
			},
		}
	},
	["centerPanel.slider"] = "slider",
	["centerPanel.cardItem"] = "cardItem",
	["centerPanel.subList"] = "subList",
	["centerPanel.cardList"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				columnSize = bindHelper.self("columnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("cardItem"),
				sliderBg = bindHelper.self("slider"),
				itemAction = {isAction = true, alwaysShow = true, actionTime = 0.5, duration = 0.3},
				onCell = function(list, cell, k, v)
					local childs = cell:multiget("bg", "attr1", "attr2", "levelNamePanel", "material", "fightPointPanel", "rarity", "maskBg", "qulityNumber", "bottomBg", "imgLock")
					setItem(cell, childs, v)

					childs.imgLock:visible(v.lock)
					childs.maskBg:visible(v.isBg)
					cell:removeChildByName("isNew")
					if not v.isBg and v.isNew then
						ccui.ImageView:create("other/gain_sprite/txt_new.png")
							:alignCenter(cell:size())
							:addTo(cell, 11, "isNew")
					end
					local t = list:getIdx(k)
					cell:setName("cardItem" .. t.k)
					local props = {
						class = "red_hint",
						props = {
							state = v.selectEffect == nil,
							listenData = {
								selectDbId = v.dbid,
							},
							specialTag = v.isBg and totalSpecialTag or starSpecialTag ,
							onNode = function(panel)
								panel:xy(405, 495)
							end,
						}
					}
					bind.extend(list, cell, props)
					bind.touch(list, cell, {
						methods = {
							ended = functools.partial(list.itemClick, cell, t, v)
						}
					})
				end,
				onBeforeBuild = function(list)
					if list.sliderBg:visible() then
						local listX, listY = list:xy()
						local listSize = list:size()
						local x, y = list.sliderBg:xy()
						local size = list.sliderBg:size()
						list:setScrollBarEnabled(true)
						list:setScrollBarColor(cc.c3b(241, 59, 84))
						list:setScrollBarOpacity(255)
						list:setScrollBarAutoHideEnabled(false)
						list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x,(listSize.height - size.height) / 2 + 5))
						list:setScrollBarWidth(size.width)
						list:refreshView()
					else
						list:setScrollBarEnabled(false)
					end
				end,
				asyncPreload = 18,
				leftPadding = 5,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["centerPanel.fragItem"] = "fragItem",
	["centerPanel.fragList"] = {
		varname = "fragList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("fragDatas"),
				columnSize = bindHelper.self("columnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("fragItem"),
				sliderBg = bindHelper.self("slider"),
				itemAction = {isAction = true, alwaysShow = true, actionTime = 0.5, duration = 0.3},
				onCell = function(list, cell, k, v)
					local childs = cell:multiget("bg", "attr1", "attr2", "name", "rarity", "numBg", "maskBg", "fragBg", "bottomBg", "material")
					setItemChip(cell, childs, v)
					if v.isBg then
						childs.bg:texture("common/icon/panel_card_1.png")
						childs.maskBg:show()
						childs.bottomBg:show()
						-- nodetools.invoke(cell, {"numBg"}, "hide")
						local fragCfg = csv.fragments[v.id]
						local cardCfg = csv.cards[fragCfg.combID]
						childs.name:text(cardCfg.name)
						widget.addAnimationByKey(cell, "effect/jinglingbeibao.skel", 'jinglingbeibao', "effect_loop", 10)
							:anchorPoint(cc.p(0.5,0.5))
							:xy(cell:width() / 2 + 1, cell:height() / 2 + 1)
					else
						childs.bg:texture("common/icon/panel_card.png")
						childs.maskBg:hide()
						childs.bottomBg:hide()
					end
					local props = {
						class = "red_hint",
						props = {
							state = v.selectEffect == nil and v.isBg,
							onNode = function(panel)
								panel:xy(405, 495)
							end,
						}
					}
					bind.extend(list, cell, props)
					childs.fragBg:visible(not v.isBg)
					local t = list:getIdx(k)
					cell:setName("fragItem" .. t.k)
					bind.touch(list, cell, {
						methods = {
							ended = functools.partial(list.itemClick,cell, t, v)
						}
					})
				end,
				onBeforeBuild = function(list)
					if list.sliderBg:visible() then
						local listX, listY = list:xy()
						local listSize = list:size()
						local x, y = list.sliderBg:xy()
						local size = list.sliderBg:size()
						list:setScrollBarEnabled(true)
						list:setScrollBarColor(cc.c3b(241, 59, 84))
						list:setScrollBarOpacity(255)
						list:setScrollBarAutoHideEnabled(false)
						list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x,(listSize.height - size.height) / 2 + 5))
						list:setScrollBarWidth(size.width)
						list:refreshView()
					else
						list:setScrollBarEnabled(false)
					end
				end,
				asyncPreload = 18,
				leftPadding = 5,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["centerPanel.empty"] = "showEmpty",
}

function CardBagView:resetListSlider(typ)
	local size = typ == SHOW_TYPE.CARD and self.cardDatas:size() or self.fragDatas:size()
	local list = typ == SHOW_TYPE.CARD and self.cardList or self.fragList
	local sliderShow = (self.columnSize * 2) < size
	self.slider:setVisible(sliderShow)
	list:setScrollBarEnabled(sliderShow)
end

-- 精灵是1，碎片是2
function CardBagView:onCreate(bagType)
	self:initModel()
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.cardBag, subTitle = "PIXIE BACKPACK"})

	self.cardRebornListen = dataEasy.getListenShow(gUnlockCsv.cardReborn)

	self.attr1 = idler.new()--第一个属性
	self.attr2 = idler.new()--第二个属性
	self.rarity = idler.new() --品级
	self.atkType = idlertable.new({})
	self.isDownListShow = idler.new(false)
	self.refreshSign = true
	self.filterPanel = gGameUI:createView("city.card.bag_filter", self:getResourceNode())
		:init({
			cb = self:createHandler("onBagFilter"),
			showIdler = self:createHandler("isDownListShow"),
			others = {
				panelOffsetX = 330,
				panelOrder = true,
				x = 1889 + display.uiOrigin.x,
				y = 108,
			}
		})
		:x(display.uiOrigin.x)
		:z(100)
	local deltaWidth, count = adapt.centerWithScreen("left", "right", {
		itemWidth = self.cardItem:size().width,
		itemWidthExtra = 200,
	},{
		{self.btnSprite, "pos","left"},
		{self.btnFragment, "pos","left"},
		{self.btnDecompose, "pos","left"},
		{self.filterPanel.filterBtn, "pos","right"},
		{self.btnBattleRecommend, "pos","right"},
		{self.capacityPanel, "pos","right"},
		{self.slider, "pos", "right"},
		{self.centerPanel, "width"},
		{{self.subList, self.cardList, self.fragList}, "width"},
		{{self.subList, self.cardList, self.fragList}, "pos", "left"},
	})
	self.deltaWidth = deltaWidth or 0
	self.columnSize = 5 + count

	self.cardDatas = idlertable.new({})--显示卡牌
	self.fragDatas = idlertable.new({})--显示碎片
	self.showBottomRight = idler.new(true)--背包容量按钮

	self.sortOrder = idler.new(true) -- order
	self.type = idler.new(bagType or SHOW_TYPE.CARD) --1表示精灵,2表示碎片

	self.sortKey = idler.new(1) -- condition
	self.sortTabData = idlertable.new()--排序列表数据
	self.sortTabDataIndex = idler.new()

	idlereasy.when(self.type, function (obj, typ)
		self.cardList:visible(typ == SHOW_TYPE.CARD)
		self.fragList:visible(typ == SHOW_TYPE.FRAGMENT)

		self.slider:setVisible(true)

		self.btnSprite:setBright(not (typ == SHOW_TYPE.CARD))
		self.btnSprite:setTouchEnabled(not (typ == SHOW_TYPE.CARD))
		self.btnFragment:setBright(not (typ == SHOW_TYPE.FRAGMENT))
		self.btnFragment:setTouchEnabled(not (typ == SHOW_TYPE.FRAGMENT))
		local color1 = ui.COLORS.NORMAL.RED
		local color2 = ui.COLORS.NORMAL.RED
		if typ == SHOW_TYPE.CARD then
			color1 = ui.COLORS.NORMAL.WHITE
		end
		if typ == SHOW_TYPE.FRAGMENT then
			color2 = ui.COLORS.NORMAL.WHITE
		end
		text.addEffect(self.textNoteSprite, {color = color1})
		text.addEffect(self.textNoteFragment, {color = color2})
	end)

	idlereasy.any({self.type, self.rarity}, function (obj, typ, rarity)
		self.showBottomRight:set(typ == SHOW_TYPE.CARD)
		local newIndex = nil
		if typ == SHOW_TYPE.CARD then
			newIndex = ui.RARITY_ICON[rarity] and 2 or 1
		else
			newIndex = ui.RARITY_ICON[rarity] and 4 or 3
		end
		self.sortTabDataIndex:set(newIndex)
		local tmpSortTabData = {}
		for k,v in pairs(SORT_DATAS[newIndex]) do
			table.insert(tmpSortTabData, v.name)
		end
		self.sortTabData:set(tmpSortTabData)
		self.sortKey:set(1)
		self.sortOrder:set(true)
	end)

	idlereasy.any({self.cardCapacity, self.cards},function (obj, capacity, cards)
		self.capacityNumText:text(#cards.."/"..capacity)
		adapt.oneLinePos(self.capacityNumText, self.capacityText, cc.p(0,0), "right")
	end)

	self.cardInfos = idlertable.new({})
	local datas = {}
	local datasCount = 0
	idlereasy.any({self.cards, self.battleCards}, function(_, cards, battleCards)
		if self.refreshSign then
			self:refushBagData()
		end
	end)
	idlereasy.when(gGameModel.cards:getNewFlags(), function(_, flags)
		self.cardInfos:modify(function(cardInfos)
			local changed = false
			for _,v in ipairs(cardInfos) do
				local id = stringz.bintohex(v.dbid)
				local flag = flags[id] or false
				changed = changed or (v.isNew ~= flag)
				v.isNew = flag
			end
			return changed, cardInfos
		end)
	end, true)

	self.fragInfos = idlertable.new()
	idlereasy.when(self.frags, function(_, frags)
		local fragInfos = {}
		for i,v in pairs(frags) do
			local fragCsv = csv.fragments[i]
			if fragCsv.type == 1 then
				local cardCsv = csv.cards[fragCsv.combID]
				local unitCsv = csv.unit[cardCsv.unitID]
				table.insert(fragInfos, {
					id = i,
					name = uiEasy.setIconName(i),
					num = v,
					maxNum = fragCsv.combCount,
					maxNum1 = fragCsv.stackMax,
					rarity = unitCsv.rarity,
					isSprite = false,
					isBg = (v >= fragCsv.combCount),
					attr1 = unitCsv.natureType,
					attr2 = unitCsv.natureType2,
					icon = unitCsv.cardShow,
					scale = unitCsv.cardShowScale,
					posOffset = unitCsv.cardShowPosC,
					dbid = i,
					atkType = cardCsv.atkType,
				})
			end
		end
		self.fragInfosChange = true
		self.fragInfos:set(fragInfos)
	end)

	local resort = idler.new(true)
	local sortTriggers = idlereasyArgs.new(self, "sortTabDataIndex", "cardInfos", "fragInfos", "type", "sortKey", "sortOrder", "rarity", "attr1", "attr2", "atkType")
	local resortTimes = 0
	idlereasy.any(sortTriggers, function(...)
		resortTimes = resortTimes + 1
		-- 减少一帧内多次重排
		performWithDelay(self, function()
			if resortTimes > 0 then
				resort:notify()
				resortTimes = 0
			end
		end, 0)
	end)

	idlerflow.if_(resort):do_(function(vars)
		local data
		if vars.type == SHOW_TYPE.CARD then
			data = vars.cardInfos
		else
			data = vars.fragInfos
		end
		if SORT_DATAS[vars.sortTabDataIndex][vars.sortKey] then
			local tmpSortKey = SORT_DATAS[vars.sortTabDataIndex][vars.sortKey].val
			self:sortFilterData(vars.type, data, tmpSortKey, vars.sortOrder, {
				{"rarity", ui.RARITY_ICON[vars.rarity] and vars.rarity},
				{"attr2", ui.ATTR_ICON[vars.attr2] and vars.attr2},
				{"attr1", ui.ATTR_ICON[vars.attr1] and vars.attr1},
				{"atkType", vars.atkType},
			})
		end
	end, sortTriggers)
	uiEasy.updateUnlockRes(gUnlockCsv.cardReborn, self.btnDecompose, {pos = cc.p(self.btnDecompose:width() - 20, 100)})

	local nodes = nodetools.multiget(self:getResourceNode(), {"bg"})
	effect.captureForBackgroud(self, unpack(nodes))

	-- 阵容推荐Unlock
	dataEasy.getListenUnlock(gUnlockCsv.battleRecommend, function(isUnlock)
		self.btnBattleRecommend:visible(isUnlock)
	end)
end

function CardBagView:initModel()
	self.cards = gGameModel.role:getIdler("cards")--卡牌
	self.frags = gGameModel.role:getIdler("frags")--碎片
	self.cardCapacity = gGameModel.role:getIdler("card_capacity")--背包容量
	self.battleCards = gGameModel.role:getIdler("battle_cards")--队伍中的卡牌
	self.rmb = gGameModel.role:getIdler("rmb")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.cardCapacityTimes = gGameModel.role:getIdler("card_capacity_times")
	self.roleLv = gGameModel.role:getIdler("level")
end

function CardBagView:refushBagData()
	local cards = self.cards:read()
	local battleCards = self.battleCards:read()

	local hash = itertools.map(itertools.ivalues(battleCards), function(k, v) return v, k end)
	local datas = {}
	-- local datasCount = #cards
	-- idlereasy.any 时序问题，两个值都变动，但 battleCards 这个先到了，cards 还是旧数据
	for i,v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		if card then
			local cardData = card:read("card_id", "unit_id","skin_id", "fighting_point", "level", "star", "advance", "locked", "name", "created_time", "equips", "effort_values")
				local cardCsv = csv.cards[cardData.card_id]
				local unitCsv = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)
				datas[i] = {
					id = cardData.card_id,
					markId = cardCsv.cardMarkID,
					name = cardData.name,
					rarity = unitCsv.rarity,
					isSprite = true,
					isBg = hash[v] and true or false,
					isNew = gGameModel.cards:isNew(v),
					attr1 = unitCsv.natureType,
					attr2 = unitCsv.natureType2,
					fight = cardData.fighting_point,
					level = cardData.level,
					star = cardData.star,
					getTime = cardData.created_time,
					icon = unitCsv.cardShow,
					scale = unitCsv.cardShowScale,
					posOffset = unitCsv.cardShowPosC,
					advance = cardData.advance,
					dbid = v,
					lock = cardData.locked,
					equips = cardData.equips,
					effortValue = cardData.effort_values,
					atkType = cardCsv.atkType,
				}
		end
	end
	self.cardInfos:set(datas)
end
--刷新主面板显示筛选结果
function CardBagView:sortFilterData(typ, data, key, order, condition)
	local filter = filterDo(data, condition)
	local sortResult = sortData(filter, key, order)
	if next(sortResult) == nil then
		local txt = ((next(data) == nil) and (typ ~= SHOW_TYPE.CARD)) and gLanguageCsv.cardBagNoFrags or gLanguageCsv.filteringIsEmpty
		self.showEmpty:show()
		self.showEmpty:get("txt"):text(txt)
	else
		self.showEmpty:hide()
	end
	if typ == SHOW_TYPE.CARD then
		-- 特殊写法，不参考
		local preloadCenter = nil
		if self.cardCenterDbid then
			for k, v in ipairs(sortResult) do
				if v.dbid == self.cardCenterDbid then
					preloadCenter = k
					break
				end
			end
		end
		self.cardList.preloadCenterIndex = preloadCenter and math.ceil(preloadCenter/self.columnSize)
		self.cardDatas:set(sortResult, true)
	else
		if self.fragInfosChange then
			dataEasy.tryCallFunc(self.fragList, "updatePreloadCenterIndex")
		end
		self.fragDatas:set(sortResult, true)
	end
	self.fragInfosChange = false
	self:resetListSlider(typ)
end

--排序item点击 and
function CardBagView:onItemClick(list,item, t, v)
	if v.isSprite then
		gGameUI:stackUI("city.card.strengthen", nil, {full = true}, 1, v.dbid)
	else
		if v.isBg then
			-- 精灵背包满时提示无法合成
			if itertools.size(self.cards:read()) >= self.cardCapacity:read() then
				gGameUI:showTip(gLanguageCsv.cardBagHaveBeenFull)
				return
			end
			local fragCsv = csv.fragments[v.id]
			local cardCsv = csv.cards[fragCsv.combID]
			local strs = {
				string.format("#C0x5b545b#"..gLanguageCsv.wantConsumeFragsCombCard, fragCsv.combCount, "#C0x60C456#"..fragCsv.name.."#C0x5b545b#", "#C0x60C456#"..cardCsv.name)
			}
			gGameUI:showDialog({content = strs, cb = function()
				gGameApp:requestServer("/game/role/frag/comb",function (tb)
					gGameUI:stackUI("common.gain_sprite", nil, {full = true}, tb.view, nil, false, self:createHandler("setCardCenterDbid", tb.view.db_id))
				end,v.id)
			end, btnType = 2, isRich = true, clearFast = true})
		else
			gGameUI:stackUI("common.gain_way", nil, nil, v.id, nil, v.maxNum)
		end
	end
end

function CardBagView:setCardCenterDbid(dbId)
	self.cardCenterDbid = dbId
	performWithDelay(self, function()
		self.cardCenterDbid = nil
	end, 0.1)
	self.type:set(SHOW_TYPE.CARD)
end

--阵容推荐
function CardBagView:onBattleRecommendClick()
	gGameUI:stackUI("city.card.battle_recommend")
end
--增加容量
function CardBagView:onAddClick()
	gGameUI:stackUI("city.card.buy_capacity")
end

function CardBagView:buyCapacity()
	gGameApp:requestServer("/game/role/card_capacity/buy",function (tb)
		gGameUI:showTip(gLanguageCsv.hasBuy)
	end)
end

function CardBagView:onChangeClick(val)
	val = val or 1
	self.type:set(val)
end

function CardBagView:onBagFilter(attr1, attr2, rarity, atkType)
	self.attr1:set(attr1)
	self.attr2:set(attr2)
	self.rarity:set(rarity)
	self.atkType:modify(function()
		return true, atkType
	end)
end

function CardBagView:onSortMenusBtnClick(panel, node, k, v, oldval)
	if oldval == k then
		self.sortOrder:modify(function(val)
			return true, not val
		end)
	else
		self.sortOrder:set(true)
	end
	self.sortKey:set(k)
end

function CardBagView:onSortMenusNode(panel, node)
	node:xy(962 + self.deltaWidth, -431):z(20)
end

function CardBagView:onEnterDecompose()
	if not dataEasy.isUnlock(gUnlockCsv.cardReborn) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.cardReborn))
		return
	end
	if not gGameUI:goBackInStackUI("city.card.rebirth.view") then
		gGameUI:stackUI("city.card.rebirth.view", nil,  {full = true}, 2)
	end
end

-- pause aysncload when myself hide
function CardBagView:onStackHide(...)
	self.refreshSign = false
	return ViewBase.onStackHide(self, ...)
end

-- resume aysncload when myself show
function CardBagView:onStackShow()
	self.refreshSign = true
	self:refushBagData()
	return ViewBase.onStackShow(self)
end

return CardBagView