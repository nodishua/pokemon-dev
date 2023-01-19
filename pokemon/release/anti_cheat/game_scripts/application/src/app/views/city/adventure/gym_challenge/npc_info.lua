
local GymNpcInfoView =  class("GymNpcInfoView", Dialog)

GymNpcInfoView.RESOURCE_FILENAME = "gym_npc_info.json"
GymNpcInfoView.RESOURCE_BINDING = {
    ["imgBG.bg"] = "bg",
    ["imgBG.textName"] = "masterName",
    ["imgBG.textIntro1"] = "textIntro1",
	["imgBG.textIntro2"] = "textIntro2",
	["imgBG.attrItem"] = "attrItem",
    ["imgBG.arrList"] = {
		varname = "arrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrData"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(ui.ATTR_ICON[v])
				end,
				onAfterBuild = function(list)
					--右对齐
					local size = list.item:size()
					local count = csvSize(list.data)
					local width = size.width * count  + list:getItemsMargin() * (count - 1)
					list:setAnchorPoint(cc.p(1,0.5))
					list:width(width)
					list:xy(cc.p(1600,950))
				end
			}
		},
	},
    ["imgBG.figurePanel"] = {
		binds = {
			event = "extend",
			class = "role_figure",
			props = {
				data = bindHelper.self("figureId"),
				spine = true,
				onSpine = function(spine)
					spine:scale(2)
					:y(140)
				end,
			},
		}
    },
    ["imgBG.list"] = {
        varname = "battleArrayList",
        binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("monsterDatas"),
				item = bindHelper.self("item"),
				margin = 10,
				padding = 10,
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							levelProps = {
								data = v.level,
							},
							isBoss = v.isBoss,
							rarity = v.rarity,
							showAttribute = true,
							onNode = function(panel)
								local x, y = panel:xy()
								node:scale(v.isBoss and 0.72 or 0.7)
							end,
						}
					})
				end,
			},
		},
    },
    ["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
}
local function getCfgData(cfg, isBoss)
	local data = {}
	for _, v in ipairs(cfg) do
		local unitCfg = csv.unit[v.unitId]
		table.insert(data, {
			unitId = v.unitId,
			level = v.level,
			advance = v.advance,
			rarity = unitCfg.rarity,
			attr1 = unitCfg.natureType,
			attr2 = unitCfg.natureType2,
			isBoss = isBoss,
		})
	end
	table.sort(data, function(a,b)
		return a.advance > b.advance
	end )
	return data
end

function GymNpcInfoView:onCreate(id)
	self.id = id
	local npcID = csv.gym.gym[self.id].npcID
	local figure = csv.gym.npc[npcID].figure
	self.figureId = idler.new(figure)
	self.masterName:text(gRoleFigureCsv[figure].name)
	self.attrData= idlers.newWithMap(csv.gym.gym[id].limitAttribute)
	beauty.textScroll({
		list = self.textIntro1,
		strs = csv.gym.npc[npcID].expertise,
		isRich = false,
		fontSize = 40,
	})
	beauty.textScroll({
		list = self.textIntro2,
		strs = csv.gym.npc[npcID].desc,
		isRich = false,
		fontSize = 40,
	})

	self.item = ccui .Layout:create():size(180, 180)
		:show()
		:setTouchEnabled(true)
		:retain()
		:scale(0.8)
	local gateId = 0
	for i,v in csvPairs(csv.gym.gate) do
		if v.npc == true and v.gymID == self.id then
			gateId = i
		end
	end

	local sceneCsv = csv.scene_conf[gateId]
	local bossDatas = getCfgData(sceneCsv.boss, true)
	local monsterDatas = getCfgData(sceneCsv.monsters, false)
	self.monsterDatas = arraytools.merge({bossDatas, monsterDatas})

    Dialog.onCreate(self)
end

return GymNpcInfoView