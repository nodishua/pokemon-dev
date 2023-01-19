-- @date:   2020-07-16
-- @desc:   跨服竞技场战斗信息

local OnlineFightRecordInfoView = class("OnlineFightRecordInfoView", Dialog)

OnlineFightRecordInfoView.RESOURCE_FILENAME = "online_fight_record_info.json"
OnlineFightRecordInfoView.RESOURCE_BINDING = {
	["item"] = "item",
	["panel1"] = "panel1",
	["panel2"] = "panel2",
}

-- showTab 1.公平赛 2.无限制赛
function OnlineFightRecordInfoView:onCreate(info, showTab)
	Dialog.onCreate(self)
	local t = {
		[1] = {
			result = info.results[1] == "win",
			name = info.name,
			game_key = info.role_key[1],
			level = info.level,
			rank = info.rank,
			score = info.score,
			logo = info.logo,
			frame = info.frame,
			cards = info.cards,
			card_attrs = info.card_attrs,
			fighting_point = 0,
			teamBuffs = {},
		},
		[2] = {
			result = info.results[1] ~= "win",
			name = info.defence_name,
			game_key = info.defence_role_key[1],
			level = info.defence_level,
			rank = info.defence_rank,
			score = info.defence_score,
			logo = info.defence_logo,
			frame = info.defence_frame,
			cards = info.defence_cards,
			card_attrs = info.defence_card_attrs,
			fighting_point = 0,
			teamBuffs = {},
		},
	}
	for i = 1, 2 do
		local data = t[i]
		local panel = self["panel" .. i]
		local childs = panel:get("head"):multiget("img", "textNoteLv", "textLv", "textName", "head")
		bind.extend(self, childs.head, {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = data.logo,
				frameId = data.frame,
				level = false,
				vip = false,
			}
		})
		text.addEffect(childs.textNoteLv, {outline = {color=ui.COLORS.OUTLINE.DEFAULT}})
		text.addEffect(childs.textLv, {outline = {color=ui.COLORS.OUTLINE.DEFAULT}})
		childs.img:texture(data.result and "city/pvp/craft/icon_win.png" or "city/pvp/craft/icon_lose.png")
		childs.textName:text(data.name)
		childs.textLv:text(data.level)
		for j = 1, 2 do
			local cards = {}
			for k = 1, 3 do
				local index = (j - 1) * 3 + k
				local dbId = data.cards[index]
				if dbId then
					local cardInfo = data.card_attrs[dbId]
					local cardCfg = csv.cards[cardInfo.card_id]
					local unitCfg = csv.unit[cardCfg.unitID]
					if cardInfo.nature_choose == 1 then
						data.teamBuffs[index] = unitCfg.natureType
					else
						data.teamBuffs[index] = unitCfg.natureType2
					end
					local unitId = dataEasy.getUnitId(cardInfo.card_id, cardInfo.skin_id)
					cards[k] = {
						card_id = cardInfo.card_id,
						unitId = unitId,
						advance = cardInfo.advance,
						star = cardInfo.star,
						level = cardInfo.level,
						rarity = unitCfg.rarity,
					}
					data.fighting_point = data.fighting_point + cardInfo.fighting_point
				else
					cards[k] = {}
				end
			end
			bind.extend(self, panel:get("array.list" .. j), {
				class = "listview",
				props = {
					data = cards,
					item = self.item,
					onAfterBuild = function(list)
						list:setClippingEnabled(false)
					end,
					onItem = function(list, node, k, v)
						if itertools.isempty(v) then
							node:get("emptyPanel"):show()
							return
						end
						node:get("emptyPanel"):hide()
						bind.extend(list, node, {
							class = "card_icon",
							props = {
								unitId = v.unitId,
								advance = v.advance,
								rarity = v.rarity,
								star = v.star,
								levelProps = {
									data = v.level,
								},
								onNode = function(node)
									node:xy(0, -6):scale(0.8)
								end,
							}
						})
					end,
				}
			})
		end
		if showTab == 1 then
			panel:get("array.textArray"):show()
			panel:get("array.textFight"):hide()
			panel:get("array.textZl"):hide()
		else
			panel:get("array.textArray"):hide()
			panel:get("array.textFight"):show()
			panel:get("array.textZl"):show():text(data.fighting_point)
		end
		panel:get("array.imgBuf"):texture(dataEasy.getTeamBuff(data.teamBuffs).imgPath)
	end
end

return OnlineFightRecordInfoView