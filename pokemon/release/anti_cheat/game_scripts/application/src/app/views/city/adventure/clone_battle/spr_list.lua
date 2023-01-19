-- @date:   2019-10-16
-- @desc:   克隆战(元素挑战)元素展示

local CloneBattleSpriteList = class("CloneBattleSpriteList", Dialog)

CloneBattleSpriteList.RESOURCE_FILENAME = "clone_battle_spr_show.json"
CloneBattleSpriteList.RESOURCE_BINDING = {
	["item"] = "item",
	["item.spr1.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["item.spr2.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["item.spr3.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["showPanel"] = "showPanel",
	["showPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("natureDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local natureId = v.natureId
					local children = node:multiget("natureImg", "text", "spr1", "spr2", "spr3")
					children.natureImg:texture(ui.SKILL_ICON[natureId])
					children.text:text(gLanguageCsv[game.NATURE_TABLE[natureId]]..gLanguageCsv.talentElement)
					text.addEffect(children.text, {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 4 }, color = ui.COLORS.ATTR[natureId]})

					local pokedex = gGameModel.role:read("pokedex")
					local marks = {}
					for cardId, time in pairs(pokedex) do
						local cardCsv = csv.cards[cardId]
						marks[cardCsv.cardMarkID] = true
					end

					for i = 1, 3 do
						local tb = v.spriteTb[i]
						local imgItem = children["spr"..i]
						imgItem:visible(tb and true or false)
						if tb then
							imgItem:texture(tb.config.iconSimple)
							imgItem:get("text"):text(tb.config.name)

							if not tb.inBox then
								cache.setShader(imgItem, false, "hsl_gray")
							end
						end
					end
				end,
			},
		},
	}
}

function CloneBattleSpriteList:onCreate(data, posX, posY)
	self.natureDatas = data

	local dataCount = #data
	local height = self.item:size().height		-- 每个item 的高度
	local targetH = (height + 20) * dataCount - 20		-- 全高
	self.list:height(targetH):xy(50, 50)
	self.showPanel:height(targetH + 98)
		:xy(posX - self.showPanel:size().width - 70, 1000 - (targetH - height - 20))

	Dialog.onCreate(self, {
		clickClose = true,
		noBlackLayer = true,
	})
end

return CloneBattleSpriteList





