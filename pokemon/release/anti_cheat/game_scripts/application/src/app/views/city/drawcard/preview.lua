-- @date:   2019-05-14
-- @desc:   预览界面
-- todo 这个界面不止抽卡界面在使用
local TITLE = {
	card = gLanguageCsv.card,
	item = gLanguageCsv.res,
	desc = gLanguageCsv.probability,
	equip = gLanguageCsv.carryItem
}

local DRAWTYPE = {
	gold = 1,
	diamond = 2,
	component = 3,
	equip = 4,
	limit_sprite = 5,
	limit = 6,
	diamond_up = 7,
	lucky_egg = 8,
	self_choose = 9,
}

local DrawCardPreviewView = class("DrawCardPreviewView", cc.load("mvc").ViewBase)

DrawCardPreviewView.RESOURCE_FILENAME = "drawcard_preview.json"
DrawCardPreviewView.RESOURCE_BINDING = {
	["textItem"] = "textItem",
	["innerList"] = "innerList",
	["roleItem"] = "roleItem",
	["item"] = "item",
	["innerList"] = "innerList",
	["textInnerList"] = "textInnerList",
	["list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showDatas"),
				item = bindHelper.self("item"),
				roleItem = bindHelper.self("roleItem"),
				asyncPreload = 7,
				textItem = bindHelper.self("textItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					if v.type == "title" then
						node:size(1950, 60)
						itertools.invoke({node:get("textNote"), node:get("list"), node:get("textInnerList")}, "hide")
						node:get("title"):y(30)
						node:get("title.textTitle"):text(TITLE[v.title])
						adapt.oneLineCenter(node:get("title.textTitle"), node:get("title.imgLeft"), node:get("title.imgRight"), cc.p(10, 0))
					else
						itertools.invoke({node:get("textNote"), node:get("title"), node:get("textInnerList")}, "hide")
						local size = cc.size(1950, 195)
						local targetList = node:get("list")
						local innerItem = list.roleItem
						if v.type == "desc" then
							size = cc.size(1950, 60)
							node:get("textInnerList"):visible(true)
							node:get("list"):visible(false)
							targetList = node:get("textInnerList")
							innerItem = list.textItem
						end
						node:size(size)
						targetList:y(0)

						local binds = {
							class = "listview",
							props = {
								data = v.items,
								item = innerItem,
								onItem = function(innerList, cell, kk ,vv)
									if v.type == "desc" then
										cell:get("textName"):text(gLanguageCsv[vv.text])
										adapt.setTextScaleWithWidth(cell:get("textName"), nil, 380)
										cell:get("textVal"):text(vv.val .. "%")
										adapt.oneLinePos(cell:get("textName"), cell:get("textVal"), cc.p(10, 0), "left")
									else
										bind.extend(innerList, cell, {
											class =  TITLE[v.type] and "icon_key" or "explore_icon",
											props = {
												data = vv,
											},
										})

									end
									if vv.up == true then
										local upIcon = cc.Sprite:create("city/drawcard/draw/txt_up.png")
										upIcon:addTo(cell)
											:xy(cc.p(cell:size().width-40,cell:size().height-17))
											:z(5)
									end
									cell:visible(true)
								end,
							}
						}
						bind.extend(list, targetList, binds)

					end
				end,
			},
		},
	},
}

function DrawCardPreviewView:onCreate(drawType, limitId, selfChooseId)
	drawType = DRAWTYPE[drawType] or 1
	local showDatas = {}
	self.showDatas = {}

	-- 活动数据过滤
	showDatas = self:initModel(drawType,limitId,selfChooseId)
	self:initUI(drawType,showDatas,limitId,selfChooseId)

end

function DrawCardPreviewView:initModel(drawType, limitId, selfChooseId)
	local showDatas = {}
	if drawType == DRAWTYPE.limit or
		drawType == DRAWTYPE.diamond_up or
		drawType == DRAWTYPE.limit_sprite or
		drawType == DRAWTYPE.lucky_egg then
		local priview = csv.yunying.yyhuodong[limitId].clientParam
		if priview.priviewId and csv.draw_preview[priview.priviewId] then
			showDatas = csv.draw_preview[priview.priviewId]
		end
	elseif drawType == DRAWTYPE.self_choose then
		local choose = self:getPreviewId(selfChooseId)
		showDatas = csv.draw_preview[choose]
	else
		showDatas = gDrawPreviewCsv[drawType][1]
	end

	return showDatas
end

function DrawCardPreviewView:initUI(drawType, showDatas, limitId, selfChooseId)
	-- 卡牌id
	self:card(drawType, showDatas, limitId, selfChooseId)
	-- 携带道具id
	self:heldItem(showDatas)
	-- 物品id
	self:itemId(showDatas)
	-- 概率描述
	self:description(showDatas)
end

-- 卡牌id
function DrawCardPreviewView:card(drawType, showDatas, limitId, selfChooseId)
	if showDatas.card and csvSize(showDatas.card) > 0 then
		local data = {}
		for i,v in ipairs(showDatas.card) do
			local up = false
			if drawType == DRAWTYPE.diamond_up then
				-- 限时轮换钻石抽卡UP标志
				local upCards = csv.yunying.yyhuodong[limitId].clientParam.up
				for _, upCardId in csvPairs(upCards) do
					if v == upCardId then
						up = true
						break
					end
				end
			end

			if drawType == DRAWTYPE.self_choose then
				local upCards = {}
				for k,v in csvMapPairs(csv.draw_card_up_group) do
					if k == selfChooseId then
						upCards = v.cards
						break
					end
				end
				for _, upCardId in csvPairs(upCards) do
					if v == upCardId then
						up = true
						break
					end
				end
			end
			table.insert(data, {key = "card", num = v, up = up})
		end
		if drawType == DRAWTYPE.diamond_up or drawType == DRAWTYPE.self_choose then
			table.sort(data, function(a, b)
				local cfgA = csv.unit[csv.cards[a.num].unitID]
				local cfgB = csv.unit[csv.cards[b.num].unitID]
				if a.up == b.up then
					if cfgA.rarity ~= cfgB.rarity then
						return cfgA.rarity >= cfgB.rarity
					end
					return cfgA.cardID < cfgB.cardID
				elseif a.up == true and b.up == false then
					return true
				elseif a.up == false and b.up == true  then
					return false
				end
				return false
			end)
		else
			table.sort(data, function(a, b)
				local cfgA = csv.unit[csv.cards[a.num].unitID]
				local cfgB = csv.unit[csv.cards[b.num].unitID]
				if cfgA.rarity ~= cfgB.rarity then
					return cfgA.rarity > cfgB.rarity
				end
				return cfgA.cardID < cfgB.cardID
			end)
		end

		table.insert(self.showDatas, {type = "title", title = "card"})
		local t = {}
		for i,v in ipairs(data) do
			if i % 9 == 1 and i > 9 then
				table.insert(self.showDatas, {type = "card", items = t})
				t = {}
			end
			table.insert(t, v)
		end
		if #t > 0 then
			table.insert(self.showDatas, {type = "card", items = t})
		end
	end
	-- body
end

-- 携带道具id
function DrawCardPreviewView:heldItem(showDatas)
	if showDatas.helditem and csvSize(showDatas.helditem) then
		local data = {}
		for i,v in ipairs(showDatas.helditem) do
			table.insert(data, {key = v, num = 0})
		end
		table.sort(data, dataEasy.sortItemCmp)
		table.insert(self.showDatas, {type = "title", title = "equip"})
		local t = {}
		for i,v in ipairs(data) do
			if i % 9 == 1 and i > 9 then
				table.insert(self.showDatas, {type = "equip", items = t})
				t = {}
			end
			table.insert(t, v)
		end
		if #t > 0 then
			table.insert(self.showDatas, {type = "equip", items = t})
		end
	end
end

-- 物品id
function DrawCardPreviewView:itemId(showDatas)
	if showDatas.item and csvSize(showDatas.item) > 0 then
		local data = {}
		for i,v in ipairs(showDatas.item) do
			table.insert(data, {key = v, num = 0})
		end
		table.sort(data, dataEasy.sortItemCmp)
		table.insert(self.showDatas, {type = "title", title = "item"})
		local t = {}
		for i,v in ipairs(data) do
			if i % 9 == 1 and i > 9 then
				table.insert(self.showDatas, {type = "item", items = t})
				t = {}
			end
			table.insert(t, v)
		end
		if #t > 0 then
			table.insert(self.showDatas, {type = "item", items = t})
		end
	end
end

-- 概率描述
function DrawCardPreviewView:description(showDatas)
	if showDatas.desc and csvSize(showDatas.desc) then
		local data = {}
		for i,v in ipairs(showDatas.desc) do
			local idx = math.ceil(i / 4)
			if not data[idx] then
				data[idx] = {}
			end
			table.insert(data[idx], {text = v[1], val = v[2]})
		end
		table.insert(self.showDatas, {type = "title", title = "desc"})
		for i,v in ipairs(data) do
			table.insert(self.showDatas, {type = "desc", items = v})
		end
	end
end

function DrawCardPreviewView:getPreviewId(choose)
	local preview = 0
	for k,v in csvMapPairs(csv.draw_card_up_group) do
	 	if k == choose then
	 		preview = v.priviewId
	 		break
	 	end
	end
	return preview
end

return DrawCardPreviewView