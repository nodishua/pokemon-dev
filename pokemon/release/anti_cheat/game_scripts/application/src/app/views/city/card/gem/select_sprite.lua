
local getMaskSprite = function(node,size)
	local tempSprite = ccui.Scale9Sprite:create()
	tempSprite:initWithFile(cc.rect(60, 60, 1, 1), "common/box/mask_panel_exercise.png")
	tempSprite:size(size.width - 20, size.height - 20)
		:alignCenter(node:size())
	return tempSprite
end

--# 符石选择精灵界面
local GemSelectSpriteView = class("GemSelectSpriteView", Dialog)
local GemTools = require('app.views.city.card.gem.tools')

GemSelectSpriteView.RESOURCE_FILENAME = "gem_select_sprite.json"
GemSelectSpriteView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["lineList"] = "lineList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("data"),
				item = bindHelper.self("lineList"),
				cell = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				asyncPreload = 9,
				columnSize = 3,
				topPadding = 10,
				leftPadding = 10,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					bind.extend(list, node:get('item'), {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
							end,
						}
					})
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, node, k, v)}})
					local card = gGameModel.cards:find(v.dbid)
					local unitCsv = csv.unit[v.unitId]
					local size = node:get('bg'):getContentSize()

					local mask = getMaskSprite(node,size)
					local sp = cc.Sprite:create(unitCsv.cardShow):setOpacity(36)

					local spSize = sp:size()
					local soff = cc.p(-80, 0)
					local ssize = size
					local rect = cc.rect((spSize.width-ssize.width)/2-soff.x, (spSize.height-ssize.height)/2-soff.y, ssize.width, ssize.height)
					sp:alignCenter(size)
						:setTextureRect(rect)

					local width  = node:size().width - 20
					local height = node:size().height - 14
					cc.ClippingNode:create(mask)
						:setAlphaThreshold(0.1)
						:size(size)
						:alignCenter({width = width, height = height})
						:add(sp)
						:addTo(node, 2)

					if v.isCur then
						node:add(getMaskSprite(node,size), 90)
					end

					node:get('isCur'):visible(v.isCur)

					local gems = card:read('gems')
					for i = 1, 9 do
						local isLocked, lockedStr = GemTools.isSlotLocked(v.dbid, i)
						if isLocked then
							node:get('icon'..i):texture('city/card/gem/btn_lock2.png'):scale(0.6)
						elseif gems[i] then
							local gem = gGameModel.gems:find(gems[i])
							local gem_id = gem:read('gem_id')
							local cfg = dataEasy.getCfgByKey(gem_id)
							node:get('icon'..i):texture(cfg.icon)
						else
							node:get('icon'..i):visible(false)
						end
					end
					node:get('num'):setString(v.qualityNum)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},

	["panel404"] = "panel404",
	["title"] = "title",
	["num"] = "num",
}

function GemSelectSpriteView:onCreate(cardId, cb)
	self.cb = cb
	self.item:visible(false)
	local all = {}
	local info = true
	local cards = gGameModel.role:read("cards")
	for _, dbid in ipairs(cards) do
		local card = gGameModel.cards:find(dbid)
		local cardDatas = card:read("card_id","skin_id", "fighting_point", "level", "star", "advance")
		local id = gGameModel.cards:find(dbid):read("card_id")
		info = false
		local cardCsv = csv.cards[cardDatas.card_id]
		local unitCsv = csv.unit[cardCsv.unitID]

		local gems = card:read('gems')
		local qualityNum = 0
		for i = 1, 9 do
			if gems[i] then
				local gem = gGameModel.gems:find(gems[i])
				local gem_id = gem:read('gem_id')
				local level = gem:read('level')
				local quality = csv.gem.gem[gem_id].quality
				quality = "qualityNum"..quality
				qualityNum = csv.gem.quality[level][quality] + qualityNum
			end
		end

		all[dbid] = {
			id = cardDatas.card_id,
			unitId = dataEasy.getUnitId(cardDatas.card_id,cardDatas.skin_id),
			rarity = unitCsv.rarity,
			attr1 = unitCsv.natureType,
			attr2 = unitCsv.natureType2,
			fight = cardDatas.fighting_point,
			level = cardDatas.level,
			star = cardDatas.star,
			dbid = dbid,
			advance = cardDatas.advance,
			isCur = cardId == dbid,
			qualityNum = qualityNum
		}
	end
	self.cardid = cardId

	self.data = idlers.newWithMap(all)
	self.panel404:visible(info)

	Dialog.onCreate(self)
end

function GemSelectSpriteView:onSortCards(list)
	return function(a, b)
		if a.qualityNum ~= b.qualityNum then
			return a.qualityNum > b.qualityNum
		end
		return a.fight > b.fight
	end

end

--跟换角色
function GemSelectSpriteView:onItemClick(list, node, k, v)
	if self.cardid == v.dbid then
		return
	end
	self.cardid = v.dbid
	self:onClose()
end

function GemSelectSpriteView:onClose()
	if self.cb then
		self.cb(self.cardid)
	end
	Dialog.onClose(self)
end

return GemSelectSpriteView
