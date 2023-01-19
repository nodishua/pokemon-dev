

local HeldItemAdvanceSelectView = class("HeldItemAdvanceSelectView", Dialog)

HeldItemAdvanceSelectView.RESOURCE_FILENAME = "held_item_advance_select.json"
HeldItemAdvanceSelectView.RESOURCE_BINDING = {
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas"),
				columnSize = 5,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local childs = node:multiget(
						"mask"
					)
					childs.mask:visible(v.selectState == true)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.csvId,
								dbId = v.dbId,
							},
							specialKey = {
								lv = v.orderType ~= 1 and v.lv or nil,
							},
							grayState = v.selectState == true and 1 or 0,
							onNode = function(panel)
								panel:setTouchEnabled(false)
							end
						}
					})
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick,list:getIdx(k), v)}})
				end,
				asyncPreload = 20,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["textNum"] = "textNum",
	["btnSure"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")}
		}
	},
	["btnSure.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["empty"] = "empty",
	["empty.text"] = "txtEmpty",
}

function HeldItemAdvanceSelectView:onCreate(dbId, selectId, selectMaxNum, cb)
	self.selectMaxNum = selectMaxNum
	self.cb = cb
	adapt.setTextAdaptWithSize(self.txtEmpty, {size = cc.size(520, 200), vertical = "center", horizontal = "center"})
	self:initModel()
	self.itemDatas = idlers.new()
	idlereasy.any({self.heldItems, self.items}, function(_, heldItems, items)
		local itemDatas = {}
		for _,v in pairs(heldItems) do
			local heldItem = gGameModel.held_items:find(v)
			if heldItem then
				local itemData = heldItem:read("held_item_id", "advance", "sum_exp", "card_db_id", "level", "exist_flag")
				if itemData.exist_flag and v ~= dbId and itemData.held_item_id == selectId then
					--万能突破道具(品质升序) > 未装备（按照等级升序） > 已装备（按照等级升序）
					table.insert(itemDatas, {
						csvId = itemData.held_item_id,
						dbId = v,
						lv = itemData.level,
						advance = itemData.advance,
						cardDbId = itemData.card_db_id,
						quality = 1,
						orderType = itemData.card_db_id and 3 or 2
					})
				end
			end
		end
		local helditemCsv = csv.held_item.items[selectId]
		local universalItems = helditemCsv.universalItems
		for k,v in pairs(universalItems) do
			local num = items[v] or 0
			for i=1,num do
				local itemsCsv = csv.items[v]
				table.insert(itemDatas, {
					csvId = v,
					quality = itemsCsv.quality,
					lv = 1,
					orderType = 1
				})
			end
		end
		table.sort(itemDatas,function(a,b)
			if a.orderType ~= b.orderType then
				return a.orderType < b.orderType
			end
			if a.lv ~= b.lv then
				return a.lv < b.lv
			end
			return a.quality < b.quality
		end)
		self.empty:visible(itertools.size(itemDatas) == 0)
		self.itemDatas:update(itemDatas)
	end)
	self.selectIdx = idler.new()
	self.selectNum = 0
	idlereasy.when(self.selectIdx, function(_, selectIdx)
		self.textNum:text(self.selectNum.."/"..selectMaxNum)
		if self.itemDatas:atproxy(selectIdx) then
			local itemData = self.itemDatas:atproxy(selectIdx)
			if self.selectNum >= selectMaxNum and itemData.selectState ~= true then
				return
			end
			itemData.selectState = not itemData.selectState
			local selectNum = 0
			for i = 1, self.itemDatas:size() do
				local itemDatas = self.itemDatas:atproxy(i)
				if itemDatas.selectState == true then
					selectNum = selectNum + 1
				end
			end
			self.selectNum = selectNum
			self.textNum:text(selectNum.."/"..selectMaxNum)
		end
	end)
	Dialog.onCreate(self, {noBlackLayer = true, clickClose = true, blackType = 1})
end

function HeldItemAdvanceSelectView:initModel()
	self.heldItems = gGameModel.role:getIdler("held_items")
	self.items = gGameModel.role:getIdler("items")

end

--点击选择
function HeldItemAdvanceSelectView:onItemClick(list, k, v)
	if self.selectMaxNum <= self.selectNum and v.selectState ~= true then
		gGameUI:showTip(gLanguageCsv.numberSelectedHasMet)
		return
	end
	local function lvTip()
		if (v.lv and v.lv > 1) or (v.advance and v.advance > 1) then
			gGameUI:showDialog({content = gLanguageCsv.heldItemAdvanceLvTip, cb = function()
				self.selectIdx:set(k.k, true)
			end, btnType = 2, isRich = true, clearFast = true})
		else
			self.selectIdx:set(k.k, true)
		end
	end
	if v.selectState ~= true then
		if v.cardDbId then
			local card = gGameModel.cards:find(v.cardDbId)
			local advance = card:read("advance")
			local name = card:read("name")
			local cardId = card:read("card_id")
			if name == "" then
				name = csv.cards[cardId].name
			end
			local quality, numStr = dataEasy.getQuality(advance)
			local cardStr = ui.QUALITYCOLOR[quality]..name..numStr
			gGameUI:showDialog({content = string.format(gLanguageCsv.heldItemAdvanceDressTip, cardStr), cb = function()
				gGameApp:requestServer("/game/helditem/unload", function()
					local itemData = self.itemDatas:atproxy(k.k)
					itemData.cardDbId = nil
					lvTip()
				end, v.dbId)
			end, btnType = 2, isRich = true, clearFast = true})
		else
			lvTip()
		end
	else
		self.selectIdx:set(k.k, true)
	end
end
--点击确定
function HeldItemAdvanceSelectView:onSureClick()
	local costItemIDs = {}
	local costHeldItemIDs = {}
	for i,v in self.itemDatas:pairs() do
		local v = v:proxy()
		if v.selectState and v.dbId ~= nil then
			table.insert(costHeldItemIDs, v.dbId)
		end
		if v.selectState and not v.dbId then
			if not costItemIDs[v.csvId] then
				costItemIDs[v.csvId] = 0
			end
			costItemIDs[v.csvId] = costItemIDs[v.csvId] + 1
		end
	end
	self.cb(costHeldItemIDs, costItemIDs)
	self:onClose()
end

return HeldItemAdvanceSelectView