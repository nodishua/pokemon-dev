--
-- @desc 以太布阵下边操作
--
local EmbattleCardList = require "app.views.city.card.embattle.embattle_card_list"

local RandomEmbattleCardList = class("EmbattleCardList", EmbattleCardList)
RandomEmbattleCardList.RESOURCE_FILENAME = "common_battle_card_list.json"
RandomEmbattleCardList.RESOURCE_BINDING = {
	["textNotRole"] = "emptyTxt",
	["item"] = "item",
	["list"] = "list",
	["list"] = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("allCardDatas"),
				item = bindHelper.self("item"),
				emptyTxt = bindHelper.self("emptyTxt"),
				dataFilterGen = bindHelper.self("onFilterCards", true),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				padding = 4,
				onItem = function(list, node, k, v)
					list.initItem(node, k, v)
				end,
				onBeforeBuild = function(list)
					list.emptyTxt:hide()
				end,
				onAfterBuild = function(list)
					local cardDatas = itertools.values(list.data)
					if #cardDatas == 0 then
						list.emptyTxt:show()
					else
						list.emptyTxt:hide()
					end
				end,
				asyncPreload = 12,
			},
			handlers = {
				clickCell = bindHelper.self("onCardItemTouch"),
				initItem = bindHelper.self("initItem"),
			},
		},
	},
	["btnPanel"] = {
		varname = "btnPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("sortDatas"),
				expandUp = true,
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				onNode = function(node)
					node:xy(-930, -480):z(18)
				end,
			},
		}
	},
}

function RandomEmbattleCardList:initItem(list, node, k, v)
	local size = node:size()
	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = v.unit_id,
			advance = v.advance,
			rarity = v.rarity,
			star = v.star,
			grayState = (v.battle == 1) and 1 or 0,
			levelProps = {
				data = v.level,
			},
			onNode = function(panel)
				panel:xy(-4, -4)
			end,
		}
	})
	local textNote = node:get("textNote")
	textNote:visible(v.battle == 1)
	uiEasy.addTextEffect1(textNote)
	local hpBar = node:get("hpBar"):show()
	local mpBar = node:get("mpBar"):show()
	hpBar:get("bar"):setPercent(v.states[1] * 100)
	mpBar:get("bar"):setPercent(v.states[2] * 100)

	-- 还存活的卡牌才可以点击
	if v.states[1] > 0 then
		node:onTouch(functools.partial(list.clickCell, v))
	else
		node:get("deadMask"):show()
	end
end

function RandomEmbattleCardList:onSortCards(list)
	local func = EmbattleCardList.onSortCards(self, list) -- 原始函数
	return function (a, b)
		local statesA = a.states
		local statesB = b.states
		if statesA[1] <= 0 then return false end
		if statesB[1] <= 0 then return true end

		return func(a,b)
	end
end


return RandomEmbattleCardList