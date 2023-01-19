-- @date 2021-6-8
-- @desc 学习芯片装备存在界面提示

local ViewBase = cc.load("mvc").ViewBase
local ChipPlanEquipView = class("ChipPlanEquipView", Dialog)

ChipPlanEquipView.RESOURCE_FILENAME = "chip_plan_equip_tip.json"
ChipPlanEquipView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["tip"] = "tip",
	["btnCancel"] = {
		varname = "btnCancel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnOk"] = {
		varname = "btnOk",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickOk")}
		},
	},
	["btnOk.title"] = {
		varname = "btnText",
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["item"] = "item",
	["list"] = {
		binds = {
			event = 'extend',
			class = 'listview',
			props = {
				data = bindHelper.self('data'),
				item = bindHelper.self('item'),
				onItem = function(list, node, k, v)
					bind.extend(list, node:get("chip"), {
						class = 'icon_key',
						props = {
							noListener = true,
							data = {
								key = v.chipId,
								dbId = v.dbId,
							},
							specialKey = {
								lv = v.level,
							},
							onNode = function(panel)
								panel:get("box"):hide()
								panel:get("imgFG"):hide()
								panel:get("defaultLv"):anchorPoint(0.5, 0)
									:xy(panel:width()/2, 30)
								panel:scale(1.1)
							end,
						},
					})
					if v.cardDBID then
						node:get("line"):texture("city/card/chip/bar_1.png")
						node:get("card.icon"):hide()
						node:get("card.txt"):hide()
						local card = gGameModel.cards:find(v.cardDBID)
						local cardDatas = card:read("card_id", "skin_id", "level", "star", "advance")
						local cardCfg = csv.cards[cardDatas.card_id]
						local unitCfg = csv.unit[cardCfg.unitID]
						local unitId = dataEasy.getUnitId(cardDatas.card_id, cardDatas.skin_id)
						bind.extend(list, node:get("card"), {
							class = "card_icon",
							props = {
								unitId = unitId,
								advance = cardDatas.advance,
								rarity = unitCfg.rarity,
								star = cardDatas.star,
								levelProps = {
									data = cardDatas.level,
								},
								onNode = function(panel)
									panel:alignCenter(node:get("card"):size()):scale(0.9)
								end,
							}
						})
					else
						node:get("line"):texture("city/card/chip/bar_0.png")
						node:get("card.icon"):show()
						node:get("card.txt"):show()
					end
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end,
			},
		}
	},
}

-- params {cb, chips}
function ChipPlanEquipView:onCreate(params)
	self.params = params
	local data = {}
	local count = 0
	for i = 1, table.maxn(params.chips) do
		local dbId = params.chips[i]
		if dbId then
			local chip = gGameModel.chips:find(dbId)
			local chipData = chip:read("chip_id", "card_db_id", "level")
			if chipData.card_db_id then
				count = count + 1
			end
			table.insert(data, {
				dbId = dbId,
				chipId = chipData.chip_id,
				level = chipData.level,
				cardDBID = chipData.card_db_id,
			})
		end
	end
	self.data = data
	self.tip:text(string.format(gLanguageCsv.chipPlanUsedTip, count))

	Dialog.onCreate(self)
end

function ChipPlanEquipView:onClickOk()
	self:addCallbackOnExit(self.params.cb)
	self:onCloseFast()
	return self
end

return ChipPlanEquipView