local PropertySwapView = require("app.views.city.card.property_swap.view")


local PropertySwapChooseView = class("PropertySwapChooseView", Dialog)
local SWAP_TYPE = PropertySwapView.SWAP_TYPE

PropertySwapChooseView.RESOURCE_FILENAME = "card_property_swap_choose.json"
PropertySwapChooseView.RESOURCE_BINDING = {
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				columnSize = 3,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCardList", true),	--排序
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local children = node:multiget("cardItem", "name", "txtValueTitle", "txtValue")
					uiEasy.setIconName("card", v.id, {node = children.name, name = v.name, advance = v.advance, space = true})
					children.txtValueTitle:text(v.title)
					children.txtValue:text(v.value)
					adapt.oneLinePos(children.txtValueTitle, children.txtValue, {cc.p(-10, 0)}, "left")
					bind.extend(list, children.cardItem, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							star = v.star,
							rarity = v.rarity,
							lock = v.lock,
							selected = v.isSel,
							levelProps = {
								data = v.level,
							},
							params = {
								starScale = 0.85,
								starInterval = 12.5,
							},
							onNode = function(panel)
								panel:xy(0, 0)
									:scale(1)
								panel:get("frame"):scale(1.07)
								panel:get("rarity")
									:align(cc.p(0.5, 0.5))
									:xy(30, 165)
									:scale(0.71)
								panel:get("imgSel")
									:scale(0.94)
							end,
						}
					})
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.itemClick,node, k, v)
						}
					})
				end,
				asyncPreload = 12,
			},
			handlers = {
				itemClick = bindHelper.self("onItemChoose"),
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["empty"] = "empty",
	["empty.txtEmpty"] = "txtEmpty"
}

-- @param params 依次为继承类型(idler)，继承精灵dbid，被继承精灵dbid(idler)
function PropertySwapChooseView:onCreate(showTab, selectDbId, cb)
	self.cb = cb
	self.cardDatas = idlers.new()--卡牌数据

	adapt.setTextAdaptWithSize(self.txtEmpty, {size = cc.size(550, 200), vertical = "center", horizontal = "center"})
	self.pokedex = gGameModel.role:getIdler("pokedex")
	local cardFeels = gGameModel.role:read("card_feels")
	local selectCardCfg = csv.cards[gGameModel.cards:find(selectDbId):read("card_id")]
	local selectMarkID = selectCardCfg.cardMarkID
	local selectUnitCfg = csv.unit[csv.cards[selectMarkID].unitID]
	local selectRarity = selectUnitCfg.rarity
	local selectFeelItems = selectCardCfg.feelItems
	self.showTab = showTab
	local tmpCardDatas = {}
	local tmpSize = 0
	local isNature = showTab == SWAP_TYPE.NATURE -- 是性格页面
	local isNvalue = showTab == SWAP_TYPE.NVALUE -- 是个体值页面
	local isEffort = showTab == SWAP_TYPE.EFFORTVALUE -- 是努力值页面
	local isFeel = showTab == SWAP_TYPE.FEEL -- 是好感度页面
	if isFeel then
		self.txtEmpty:text(gLanguageCsv.noSpiritCondition)
	end
	if not isFeel then
		for k, dbid in ipairs(gGameModel.role:read("cards")) do
			local cardData = gGameModel.cards:find(dbid):read("card_id","skin_id" ,"level", "star", "advance", "locked", "name", "nvalue", "effort_values", "character")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			-- title 交换属性名称  value交换属性值
			local title = ""
			local value = 0
			if isNature then
				title = gLanguageCsv.nature..": "
				value = csv.character[cardData.character].name
			elseif isNvalue then
				title = gLanguageCsv.nvalue..": "
				-- 计算个体值总和
				for k,v in pairs(cardData.nvalue) do
					value = value + v
				end
			elseif isEffort then
				title = gLanguageCsv.effortvalue..": "
				-- 计算努力值总和
				for k,v in pairs(cardData.effort_values) do
					if k ~= "specialDamage" then
						value = value + v
					end
				end
			end

			local unitId = dataEasy.getUnitId(cardData.card_id,cardData.skin_id)
			-- markID 要一致
			if selectDbId ~= dbid and (selectMarkID == csv.cards[cardData.card_id].cardMarkID or isEffort) then
				tmpCardDatas[dbid] = {
					id = cardData.card_id,
					unitId = unitId,
					name = cardCsv.name,
					rarity = unitCsv.rarity,
					level = cardData.level,
					star = cardData.star,
					dbid = dbid,
					advance = cardData.advance,
					-- lock = cardData.locked or false,
					isSel = false,
					title = title,
					value = value,
				}
				tmpSize = tmpSize + 1
			end
		end
	else
		-- 好感度同系列消耗拥有的最高形态
		local finalEvolution = {}
		local pokedex = self.pokedex:read()
		for markId, datas in pairs(gCardsCsv) do
			local handbookData
			for develop, data in pairs(datas) do
				for branch, card in pairs(data) do
					if pokedex[card.id] then
						if not handbookData or handbookData.id < card.id then
							handbookData = card
						end
					end
				end
			end
			if handbookData then
				local cardCsv = csv.cards[handbookData.id]
				local cardMarkCsv = csv.cards[cardCsv.cardMarkID]
				local unitCsv = csv.unit[cardMarkCsv.unitID]
				local feelItems = cardMarkCsv.feelItems
				if handbookData.cardMarkID ~= selectMarkID and unitCsv.rarity == selectRarity and feelItems[1] == selectFeelItems[1] and feelItems[2] == selectFeelItems[2] and feelItems[3] == selectFeelItems[3] then
					table.insert(finalEvolution, handbookData)
				end
			end
		end
		for k, v in pairs(finalEvolution) do
			local cardCsv = csv.cards[v.id]
			local unitCsv = csv.unit[cardCsv.unitID]
			local cardFeel = cardFeels[cardCsv.cardMarkID] or {}
			local feelLevel = cardFeel.level or 0
			tmpCardDatas[k] = {
				id = v.id,
				unitId = cardCsv.unitID,
				name = cardCsv.name,
				rarity = unitCsv.rarity,
				level = nil,
				star = nil,
				dbid = v.id,
				advance = nil,
				isSel = false,
				-- title 交换属性名称  value交换属性值
				title = gLanguageCsv.feelValue..": ",
				value = feelLevel,
			}
			tmpSize = tmpSize + 1
		end
	end

	self.empty:setVisible(tmpSize <= 0)
	self.cardDatas:update(tmpCardDatas)

	Dialog.onCreate(self)
end

function PropertySwapChooseView:onItemChoose(list, node, k, v)
	self.cb(v.dbid)
	self:onClose()
end

function PropertySwapChooseView:onSortCardList(list)
	return function(a, b)
		-- 优先个体值、努力值排序
		if a.value ~= b.value then
			return a.value > b.value
		end

		-- 稀有度排序
		if a.rarity ~= b.rarity then
			return a.rarity > b.rarity
		end

		return a.id < b.id
	end
end

return PropertySwapChooseView
