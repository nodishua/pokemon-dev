--
-- @desc 公会战布阵下边操作
--
local PRELOAD_COUNT = 13
local EmbattleCardList = require "app.views.city.card.embattle.embattle_card_list"
local UnionFightEmbattleCardList = class("EmbattleCardList", EmbattleCardList)

UnionFightEmbattleCardList.RESOURCE_FILENAME = "common_battle_card_list.json"
UnionFightEmbattleCardList.RESOURCE_BINDING = {
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
					if v.battle >= 1 then
						node:get("textNote"):show()
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



-- 初始化所有cards
function UnionFightEmbattleCardList:initAllCards()
	idlereasy.any({self.battleCardsData, self.cards},function (_, orignBattleCards, cards)
		-- 过滤上阵阵容不满足条件的卡
		local battleCards = {{}, {}, {}}
		local hash = {}
		for k1, v1 in pairs(orignBattleCards) do
			for k2, data in pairs(v1) do
				local card = gGameModel.cards:find(data.dbid)
				if card then
					local cardDatas = card:read("card_id","skin_id", "fighting_point", "level", "star", "advance", "created_time", "nature_choose")
					if self.limtFunc(data.dbid, cardDatas.card_id, cardDatas.skin_id, cardDatas.fighting_point, cardDatas.level, cardDatas.star, cardDatas.advance, cardDatas.created_time, cardDatas.nature_choose, self:getBattle(k2)) then
						battleCards[k1] = battleCards[k1] or {}
						battleCards[k1][k2] = data
						hash[data.dbid] = 1
					end
				else
					battleCards[k1] = battleCards[k1] or {}
					battleCards[k1][k2] = data
					hash[data.dbid] = 1
				end
			end
		end


		local all = {}
		-- 注意闭包，要使用同一个变量值ok，不能放for里面
		local ok
		for k, dbid in ipairs(cards) do
			ok = (k == #cards)
			local card = gGameModel.cards:find(dbid)
			local cardDatas = card:read("card_id","skin_id", "fighting_point", "level", "star", "advance", "created_time", "nature_choose")
			all[dbid] = self.limtFunc(dbid, cardDatas.card_id, cardDatas.skin_id, cardDatas.fighting_point, cardDatas.level, cardDatas.star, cardDatas.advance, cardDatas.created_time, cardDatas.nature_choose, self:getBattle(hash[dbid]))
			dataEasy.tryCallFunc(self.cardList, "updatePreloadCenterIndex")
			if ok then
				-- 初始化和卡牌变动时只需要最后触发一次
				self.allCardDatas:update(all)
				self.clientBattleCards:set(battleCards, true)
			end
		end
	end)
end

return UnionFightEmbattleCardList