--
--@data: 2019-7-25 15:37:20
--@desc: 重生选择携带道具界面
--
local RebirthTools = require "app.views.city.card.rebirth.tools"
local HeldItemTools = require "app.views.city.card.helditem.tools"

local SELECTEDROLE = 1

local ChooseHeldItemView = class("ChooseHeldItemView", Dialog)

ChooseHeldItemView.RESOURCE_FILENAME = "rebirth_select_card.json"
ChooseHeldItemView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["innerList"] = "innerList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("heldItemDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				topPadding = 10,
				asyncPreload = 24,
				columnSize = 6,
				onCell = function(list, node, k, v)
					node:removeChildByName("name")
					node:get("icon.imgSel"):visible(v.isSel)
					bind.extend(list, node:get("icon"), {
						class = "icon_key",
						props = {
							data = {key = v.csvId, num = v.num, dbId = v.dbId},
							noListener = true,
							specialKey = {
								lv = v.lv,
							},
							onNode = function(panel)
								local t = list:getIdx(k)
								bind.click(list, panel, {method = functools.partial(list.clickCell, t, v)})
							end,
						}
					})
					local info = csv.held_item.items[v.csvId]
					local nameStr= info.name
					local quality= info.quality
					local label = beauty.singleTextLimitWord(nameStr, {fontSize = 40}, {width = 200})
						:xy(100, 17)
						:addTo(node, 2, "name")

					text.addEffect(label, {color= quality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[quality]})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onCellClick"),
			},
		},
	},
	["tipPanel.textTip"] = "textTip",
	["tipPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("showTip"),
		},
	},
}

function ChooseHeldItemView:onCreate(params)
	self.handlers = params.handlers
	local curSel = params.curSel
	self:initModel()
	adapt.setTextAdaptWithSize(self.textTip, {size = cc.size(500, 200), vertical = "center", horizontal = "center"})
	self.showTip = idler.new(false)
	self.heldItemDatas = idlers.newWithMap({})
	local datas = {}
	local count = 0
	local csvTab= csv.held_item.items
	for _,dbId in ipairs(self.myHeldItem:read()) do
		local heldItemData = gGameModel.held_items:find(dbId):read("exist_flag", "card_db_id", "advance", "level", "sum_exp", "held_item_id")
		if heldItemData.exist_flag and (heldItemData.sum_exp > 0 or heldItemData.advance > 0) then
			local cfg = csvTab[heldItemData.held_item_id]
			local data = {}
			data.cfg = cfg
			data.csvId = heldItemData.held_item_id
			data.dbId = dbId
			data.num = 1
			data.isSel = curSel == dbId
			data.cardDbID = heldItemData.card_db_id
			data.lv = heldItemData.level
			data.advance = heldItemData.advance
			local isDress, isExc = HeldItemTools.isExclusive(data)
			data.isDress = isDress
			data.isExc = isExc
			table.insert(datas, data)
			count = count + 1
		end
	end
	table.sort(datas, function(a, b)
		local qualityA = a.cfg.quality
		local qualityB = b.cfg.quality

		if qualityA ~= qualityB then
			return qualityA > qualityB
		end

		return a.csvId > b.csvId
	end)
	self.heldItemDatas:update(datas)
	self.showTip:set(count == 0)

	Dialog.onCreate(self)
end

function ChooseHeldItemView:initModel()
	self.myHeldItem = gGameModel.role:getIdler("held_items")
end

function ChooseHeldItemView:onCellClick(list, t, v)
	local function selectedItem()
		self.heldItemDatas:atproxy(t.k).isSel = true
		if self.handlers then
			self.handlers(self.heldItemDatas:atproxy(t.k))
		end
		self:onClose()
	end
	if v.isDress then
		local txt = uiEasy.getCardName(v.cardDbID)
		local str = string.format(gLanguageCsv.heldItemIsDress, txt)
		local params = {
			cb = function()
				selectedItem()
			end,
			btnType = 2,
			isRich = true,
			content = str,
		}
		gGameUI:showDialog(params)
	else
		selectedItem()
	end
end

return ChooseHeldItemView