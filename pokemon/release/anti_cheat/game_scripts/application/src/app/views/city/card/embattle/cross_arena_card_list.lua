--
-- @desc 跨服竞技场布阵下边操作
--
local PRELOAD_COUNT = 13

local EmbattleCardList = require "app.views.city.card.embattle.embattle_card_list"
local CrossArenaEmbattleCardList = class("EmbattleCardList", EmbattleCardList)

CrossArenaEmbattleCardList.RESOURCE_FILENAME = "common_battle_card_list.json"
CrossArenaEmbattleCardList.RESOURCE_BINDING = {
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
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unit_id,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							grayState = v.battle > 0 and 1 or 0,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
								panel:xy(-2, -2)
							end,
						}
					})
					if v.battle == 1 then
						node:get("textNote"):show()
						node:get("textNote"):text(gLanguageCsv.firstTeam)
					elseif v.battle == 2 then
						node:get("textNote"):show()
						node:get("textNote"):text(gLanguageCsv.secondTeam)
					else
						node:get("textNote"):hide()
					end
					uiEasy.addTextEffect1(node:get("textNote"))
					node:onTouch(functools.partial(list.clickCell, v))
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
				asyncPreload = PRELOAD_COUNT,
			},
			handlers = {
				clickCell = bindHelper.self("onCardItemTouch",true),
				initItem = bindHelper.self("initItem",true),
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

function CrossArenaEmbattleCardList:onSortCards(list)
	local func = EmbattleCardList.onSortCards(self, list) -- 原始函数
	return function(a, b)
		if a.battle ~= b.battle then
			if a.battle ~= 0 and b.battle~= 0 then
				return a.battle < b.battle
			end
			return a.battle >= b.battle
		end
		return func(a,b)
	end
end
function CrossArenaEmbattleCardList:getBattle(i)
	if i and i~= 0 then
		return i <= 6 and 1 or 2
	else
		return 0
	end
end

return CrossArenaEmbattleCardList