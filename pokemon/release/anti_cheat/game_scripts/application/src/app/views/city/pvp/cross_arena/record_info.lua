-- @date:   2020-07-16
-- @desc:   跨服竞技场战斗信息

local CrossArenaPersonalRecordInfoView = class("CrossArenaPersonalRecordInfoView", cc.load("mvc").ViewBase)

local function initItem(list, node, k, v)
	if not v.isInfo then
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
CrossArenaPersonalRecordInfoView.RESOURCE_FILENAME = "cross_arena_record_info.json"
CrossArenaPersonalRecordInfoView.RESOURCE_BINDING = {
	["baseNode.head"] = "head",
	["baseNode.head1"] = "head1",
	["baseNode.head.img"] = "img",
	["baseNode.head1.img"] = "img1",
	["baseNode.head.textName"] = "textName",
	["baseNode.head.head"] = {
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				level = false,
				logoId = bindHelper.self("logoId"),
				frameId = bindHelper.self("frameId"),
				vip = false,
				onNode = function(panel)
					panel:scale(1)
				end,
			}
		},
	},
	["baseNode.head1.textName"] = "textName1",
	["baseNode.head1.head"] = {
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				level = false,
				logoId = bindHelper.self("logoId1"),
				frameId = bindHelper.self("frameId1"),
				vip = false,
				onNode = function(panel)
					panel:scale(1)
				end,
			}
		},
	},
	["baseNode.head.textLv"] = {
		varname = "textLv",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["baseNode.head1.textLv"] = {
		varname = "textLv1",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["baseNode.head.textNoteLv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["baseNode.head1.textNoteLv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["item"] = "item",
	["baseNode.down1"] = "down1",
	["baseNode.down2"] = "down2",
	["baseNode.down3"] = "down3",
	["baseNode.down4"] = "down4",
	["baseNode.down1.list1"] = {
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
	["baseNode.down1.list2"] = {
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
	["baseNode.down2.list1"] = {
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
	["baseNode.down2.list2"] = {
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
	["baseNode.down3.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("team5"),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["baseNode.down3.list2"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("team6"),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["baseNode.down4.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("team7"),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["baseNode.down4.list2"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("team8"),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
}

function CrossArenaPersonalRecordInfoView:onCreate(personalInfo)
	self.fightPoint = idler.new(0)
	self.logoId = idler.new(personalInfo.logo)
	self.logoId1 = idler.new(personalInfo.defence_logo)
	self.frameId = idler.new(personalInfo.frame)
	self.frameId1 = idler.new(personalInfo.defence_frame)
	self.personalInfo = personalInfo
	self.team1 = {}
	self.team2 = {}
	self.team3 = {}
	self.team4 = {}
	self.team5 = {}
	self.team6 = {}
	self.team7 = {}
	self.team8 = {}

	if personalInfo.result =="win" then
		self.img:texture("city/pvp/craft/icon_win.png")
		self.img1:texture("city/pvp/craft/icon_lose.png")
	else
		self.img:texture("city/pvp/craft/icon_lose.png")
		self.img1:texture("city/pvp/craft/icon_win.png")
	end
	self.textLv:text(personalInfo.level)
	self.textLv1:text(personalInfo.defence_level)
	self.textName:text(personalInfo.name)
	self.textName1:text(personalInfo.defence_name)

	local team = {
		[1] = {[1] = {}, [2] = {}},
		[2] = {[1] = {}, [2] = {}},
		[3] = {[1] = {}, [2] = {}},
		[4] = {[1] = {}, [2] = {}},
	}
	local zl1 =0
	local zl2 =0
	local zl3 =0
	local zl4 =0
	local attrs ={[1] = {}, [2] = {}}
	local attrs1 ={[1] = {}, [2] = {}}

	local csvTab = csv.cards
	local unitTab = csv.unit
	for i = 1, 2 do
		for j = 1, 6 do
			local id = personalInfo.cards[i][j]
			if id then
				local cardInfo = personalInfo.card_attrs[id]
				local cardCfg = csv.cards[cardInfo.card_id]
				local unitCfg = csv.unit[cardCfg.unitID]
				if cardInfo.nature_choose == 1 then
					attrs[i][j] = unitCfg.natureType
				else
					attrs[i][j] = unitCfg.natureType2
				end

				if csvTab[cardInfo.card_id] then
					cardInfo.rarity = unitTab[csvTab[cardInfo.card_id].unitID].rarity
					cardInfo.isInfo = true
					if j <= 3 then
						team[i][1][j] = cardInfo
					else
						team[i][2][j - 3] = cardInfo
					end
					if i == 1 then
						zl1 = zl1 + cardInfo.fighting_point
					else
						zl2 = zl2 + cardInfo.fighting_point
					end
				end
			else
				if j <= 3 then
					team[i][1][j] = {isInfo = false}
				else
					team[i][2][j - 3] =  {isInfo = false}
				end
			end
		end
	end

	for i = 1, 2 do
		for j = 1, 6 do
			local id = personalInfo.defence_cards[i][j]
			if id then
				local cardInfo = personalInfo.defence_card_attrs[id]
				local cardCfg = csv.cards[cardInfo.card_id]
				local unitCfg = csv.unit[cardCfg.unitID]
				if cardInfo.nature_choose == 1 then
					attrs1[i][j] = unitCfg.natureType
				else
					attrs1[i][j] = unitCfg.natureType2
				end

				if csvTab[cardInfo.card_id] then
					cardInfo.rarity = unitTab[csvTab[cardInfo.card_id].unitID].rarity
					cardInfo.isInfo = true
					if j <= 3 then
						team[i + 2][1][j] = cardInfo
					else
						team[i + 2][2][j - 3] = cardInfo
					end
					if i == 1 then
						zl3 = zl3 + cardInfo.fighting_point
					else
						zl4 = zl4 + cardInfo.fighting_point
					end
				end
			else
				if j <= 3 then
					team[i + 2][1][j] = {isInfo = false}
				else
					team[i + 2][2][j - 3] =  {isInfo = false}
				end
			end
		end
	end
	self.down1:get("textZl"):text(zl1)
	self.down2:get("textZl"):text(zl2)
	self.down3:get("textZl"):text(zl3)
	self.down4:get("textZl"):text(zl4)

	self.down1:get("imgBuf"):texture(dataEasy.getTeamBuff(attrs[1]).imgPath)
	self.down2:get("imgBuf"):texture(dataEasy.getTeamBuff(attrs[2]).imgPath)
	self.down3:get("imgBuf"):texture(dataEasy.getTeamBuff(attrs1[1]).imgPath)
	self.down4:get("imgBuf"):texture(dataEasy.getTeamBuff(attrs1[2]).imgPath)

	self.team1 = team[1][2]
	self.team2 = team[1][1]
	self.team3 = team[2][2]
	self.team4 = team[2][1]
	self.team5 = team[3][2]
	self.team6 = team[3][1]
	self.team7 = team[4][2]
	self.team8 = team[4][1]
end

return CrossArenaPersonalRecordInfoView