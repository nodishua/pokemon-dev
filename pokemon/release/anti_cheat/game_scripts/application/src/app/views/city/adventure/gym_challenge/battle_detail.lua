
local GymBattleDetail =  class("GymBattleDetail", Dialog)


local function initItem(list, node, k, v)
	if not v.card_id then
		node:get("emptyPanel"):show()
		return
	end
	node:get("emptyPanel"):hide()
	local unitId = dataEasy.getUnitId(v.card_id, v.skin_id)
	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = unitId,
			advance = v.advance,
			rarity = v.rarity,
			star = v.star,
			levelProps = {
				data = v.level,
			},
			onNode = function(node)
				node:xy(0, -6)
				:scale(0.8)
			end,
		}
	})
end

GymBattleDetail.RESOURCE_FILENAME = "gym_battle_detail.json"
GymBattleDetail.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["left.textLv"] = {
		varname = "textLvL",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["left.textNote3"] = {
		varname = "textNote3L",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["right.textLv"] = {
		varname = "textLvR",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["right.textNote3"] = {
		varname = "textNote3R",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["item"] = "item",
	["left.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("team1"),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["left.list2"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("team2"),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["right.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("team3"),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["right.list2"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("team4"),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["left"] = "left",
	["right"] = "right",
	["imgBG.btnReplay"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReplay")}
		},
	},
	["imgBG.img"] = "img",
	["imgBG.btnReplay.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(254, 253, 236, 255)}}
		},
	},

	["left.head"] = {
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				level = false,
				logoId = bindHelper.self("logoId1"),
				frameId = bindHelper.self("frameId1"),
				vip = false,
				onNode = function(panel)
					panel:scale(1.2)
				end,
			}
		},
	},
	["right.head"] = {
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				level = false,
				logoId = bindHelper.self("logoId2"),
				frameId = bindHelper.self("frameId2"),
				vip = false,
				onNode = function(panel)
					panel:scale(1.2)
				end,
			}
		},
	},
	['left.textName'] = {
		binds ={
			event = "text",
			idler = bindHelper.self("name1"),
		}
	},
	['right.textName'] = {
		binds ={
			event = "text",
			idler = bindHelper.self("name2"),
		}
	},
}

function GymBattleDetail:onCreate(data)
	Dialog.onCreate(self)
	self:initRole(data)
	self:initCardData(data)
	self.recordID = data.play_record_id
	self.crossKey = data.cross_key
end

function GymBattleDetail:initRole(data)
	self.logoId1 = idler.new(data.logo)
	self.logoId2 = idler.new(data.defence_logo)
	self.frameId1 = idler.new(data.frame)
	self.frameId2 = idler.new(data.defence_frame)
	self.name1 = idler.new(data.name)
	self.name2 = idler.new(data.defence_name)

	self.left:get("textLv"):text(data.level)
	adapt.oneLineCenterPos(cc.p(250, 543), {self.left:get("textNote3"), self.left:get("textLv")},cc.p(2, 3))

	self.right:get("textLv"):text(data.defence_level)
	adapt.oneLineCenterPos(cc.p(250, 543), {self.right:get("textNote3"), self.right:get("textLv")},cc.p(2, 3))
	if data.role_key ~= "" then
		self.left:get("textService"):text(getServerArea(data.role_key))
	else
		self.left:get("textService"):hide()
	end
	if data.defence_role_key ~= "" then
		self.right:get("textService"):text(getServerArea(data.defence_role_key))
	else
		self.right:get("textService"):hide()
	end


	local my = gGameModel.role:read("id")
	if (my == data.role_id and data.result == "win") or (my ~= data.role_id and data.result ~= "win") then
		self.left:get("head.imgResult"):texture("city/pvp/craft/icon_win.png")
		self.right:get("head.imgResult"):texture("city/pvp/craft/icon_lose.png")
		self.img:texture("city/adventure/gym_challenge/bg_1.png")
	else
		self.right:get("head.imgResult"):texture("city/pvp/craft/icon_win.png")
		self.left:get("head.imgResult"):texture("city/pvp/craft/icon_lose.png")
		self.img:texture("city/adventure/gym_challenge/bg_2.png")
	end

	if matchLanguage({"en"}) then 
		adapt.setAutoText(self.left:get("textNote1"), nil, 120)
		adapt.setAutoText(self.left:get("textNote2"), nil, 120)
		adapt.setAutoText(self.right:get("textNote1"), nil, 120)
		adapt.setAutoText(self.right:get("textNote2"), nil, 120)
	end
end

function GymBattleDetail:initCardData(data)
	self.team1 = {}
	self.team2 = {}
	self.team3 = {}
	self.team4 = {}
	local unitTab = csv.unit
	local csvTab = csv.cards
	for i = 1, 6 do
		if i <= 3 then
			local dbId1 = data.cards[i]
			if dbId1 then
				local cardInfo = table.shallowcopy(data.card_attrs[dbId1])
				self.team1[i] = cardInfo
				local unitID = csvTab[cardInfo.card_id].unitID
				self.team1[i].rarity = unitTab[unitID].rarity
			else
				self.team1[i] = {}
			end
			local dbId2 = data.defence_cards[i]
			if dbId2 then
				local cardInfo = table.shallowcopy(data.defence_card_attrs[dbId2])
				self.team3[i] = cardInfo
				local unitID = csvTab[cardInfo.card_id].unitID
				self.team3[i].rarity = unitTab[unitID].rarity
			else
				self.team3[i] = {}
			end
		else
			local dbId1 = data.cards[i]
			if dbId1 then
				local cardInfo = table.shallowcopy(data.card_attrs[dbId1])
				self.team2[i - 3] = cardInfo
				local unitID = csvTab[cardInfo.card_id].unitID
				self.team2[i - 3].rarity = unitTab[unitID].rarity
			else
				self.team2[i - 3] = {}
			end
			local dbId2 = data.defence_cards[i]
			if dbId2 then
				local cardInfo = table.shallowcopy(data.defence_card_attrs[dbId2])
				self.team4[i - 3] = cardInfo
				local unitID = csvTab[cardInfo.card_id].unitID
				self.team4[i - 3].rarity = unitTab[unitID].rarity
			else
				self.team4[i - 3] = {}
			end
		end
	end
	--战斗力
	local fightPoint1 = 0
	for i = 1, 3 do
		print("---",self.team1[i].fighting_point, self.team1[i].fighting_point or 0)
		fightPoint1 = fightPoint1 + (self.team1[i].fighting_point or 0)
		fightPoint1 = fightPoint1 + (self.team2[i].fighting_point or 0)
	end

	local fightPoint2 = 0
	for i = 1, 3 do
		fightPoint2 = fightPoint2 + (self.team3[i].fighting_point or 0)
		fightPoint2 = fightPoint2 + (self.team4[i].fighting_point or 0)
	end
	self.left:get("imgBg.textZl"):text(fightPoint1)
	self.right:get("imgBg.textZl"):text(fightPoint2)

	--属性
	local attrs1 = {}
	local attrs2 = {}
	for i = 1, 3 do
		local cardInfo1 = self.team1[i]
		if cardInfo1.card_id then
			local cardCfg = csv.cards[cardInfo1.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			if cardInfo1.nature_choose == 1 then
				attrs1[i] = unitCfg.natureType
			else
				attrs1[i] = unitCfg.natureType2
			end
		end
		local cardInfo2 = self.team2[i]
		if cardInfo2.card_id  then
			local cardCfg = csv.cards[cardInfo2.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			if cardInfo2.nature_choose == 1 then
				attrs1[i + 3] = unitCfg.natureType
			else
				attrs1[i + 3] = unitCfg.natureType2
			end
		end

		local cardInfo3 = self.team3[i]
		if cardInfo3.card_id then
			local cardCfg = csv.cards[cardInfo3.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			if cardInfo3.nature_choose == 1 then
				attrs2[i] = unitCfg.natureType
			else
				attrs2[i] = unitCfg.natureType2
			end
		end

		local cardInfo4 = self.team4[i]
		if cardInfo4.card_id then
			local cardCfg = csv.cards[cardInfo4.card_id]
			local unitCfg = csv.unit[cardCfg.unitID]
			if cardInfo4.nature_choose == 1 then
				attrs2[i + 3] = unitCfg.natureType
			else
				attrs2[i + 3] = unitCfg.natureType2
			end
		end
	end
	self.left:get("imgBg.imgBuf"):texture(dataEasy.getTeamBuff(attrs1).imgPath)
	self.right:get("imgBg.imgBuf"):texture(dataEasy.getTeamBuff(attrs2).imgPath)
end

function GymBattleDetail:onReplay()
	local interface = "/game/gym/playrecord/get"
	gGameModel:playRecordBattle(self.recordID, self.crossKey, interface, 0, nil)
end

return GymBattleDetail