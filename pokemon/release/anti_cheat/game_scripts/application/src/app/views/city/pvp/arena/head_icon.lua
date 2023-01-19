-- @date:   2019-02-26
-- @desc:   竞技场更换形象界面

local ArenaHeadIconView = class("ArenaHeadIconView", Dialog)

ArenaHeadIconView.RESOURCE_FILENAME = "arena_head_icon.json"
ArenaHeadIconView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["title.textTitle1"] = "textTitle1",
	["title.textTitle2"] = "textTitle2",
	["item"] = "item",
	["innerList"] = "innerList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("icons"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				columnSize = 7,
				asyncPreload = 28,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					node:get("isUse"):visible(v.isUse)
					node:get("imgSel"):visible(v.isSel)
					local unit = csv.unit[v.unitID]
					node:get("imgTouxiang"):texture(unit.cardIcon)

					bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, k, v)
					}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
}

function ArenaHeadIconView:onCreate(handlerFunc, changeSpineCB,cardId)
	self:initModel()
	self.curSleInfo = {row = 1, col = 1} -- 现在没数据暂时写死
	self.handlerFunc = handlerFunc
	self.changeSpineCB = changeSpineCB
	self.icons = idlers.new()
	self.record = cardId
	local cardDatas = {}
	local idx = 0
	for i,v in ipairs(gHandbookArrayCsv) do
		if self.pokedex:read()[v.cardID] then
			idx = idx + 1
			local card = csv.cards[v.cardID]

			local isUse = v.cardID == self.record
			local itemData = {}

			itemData.isSel = isUse
			itemData.isUse = isUse
			itemData.unitID = card.unitID
			itemData.id = v.cardID
			table.insert(cardDatas, itemData)
			if isUse then
				local col = idx % 7 == 0 and 7 or idx % 7
				self.curSleInfo = {row = math.ceil(idx / 7), col = col}
			end
		end
	end

	for i, v in pairs(self.skins:read()) do
		if v == 0 then
			idx = idx + 1
			local id = i + game.SKIN_ADD_NUM
			local skin = gSkinCsv[i]
			local isUse = id == self.record
			local itemData = {}
			itemData.isSel = isUse
			itemData.isUse = isUse
			itemData.unitID = dataEasy.getUnitId(nil, i)
			itemData.id = id
			table.insert(cardDatas, itemData)
			if isUse then
				local col = idx % 7 == 0 and 7 or idx % 7
				self.curSleInfo = {row = math.ceil(idx / 7), col = col}
			end
		end
	end
	self.icons:update(cardDatas)

	adapt.oneLinePos(self.textTitle1, self.textTitle2, nil, "left")

	Dialog.onCreate(self)
end

function ArenaHeadIconView:initModel()
	self.pokedex = gGameModel.role:getIdler("pokedex")--卡牌
	self.skins = gGameModel.role:getIdler("skins")
	local arena = gGameModel.arena
end

function ArenaHeadIconView:onItemClick(list, k, v)
	gGameApp:requestServer("/game/pw/display", function(tb)
		local t = list:getIdx(k)
		local idx = mathEasy.getIndex(self.curSleInfo.row, self.curSleInfo.col, 7)
		self.icons:atproxy(idx).isSel = false
		self.icons:atproxy(idx).isUse = false
		self.icons:atproxy(t.k).isSel = true
		self.icons:atproxy(t.k).isUse = true
		self.curSleInfo = t
		self.handlerFunc(v.id)
		if self.changeSpineCB then
			self.changeSpineCB(v.id)
		end
	end, v.id)
end

return ArenaHeadIconView