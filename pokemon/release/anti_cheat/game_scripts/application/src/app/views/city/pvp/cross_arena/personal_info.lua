-- @date:   2020-05-25
-- @desc:   跨服竞技场个人信息

local CrossArenaPersonalInfoView = class("CrossArenaPersonalInfoView", cc.load("mvc").ViewBase)

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
CrossArenaPersonalInfoView.RESOURCE_FILENAME = "cross_arena_personal_info.json"
CrossArenaPersonalInfoView.RESOURCE_BINDING = {
	["baseNode.top.textName"] = "textName",
	["baseNode.top.imgVip"] = "imgVip",
	["baseNode.top.head"] = {
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				level = false,
				logoId = bindHelper.self("logoId"),
				frameId = bindHelper.self("frameId"),
				vip = false,
				onNode = function(panel)
					panel:scale(0.85)
				end,
			}
		},
	},
	["baseNode.top.stage"] = {
		varname = "stage",
		binds = {
			event = "extend",
			class = "stage_icon",
			props = {
				rank = bindHelper.self("rank"),
				showStageBg = false,
				showStage = false,
				onNode = function(panel)
					panel:y(40)
						:scale(1)
				end
			}
		},
	},

	["baseNode.top.textRank"] = {
		varname = "textRank",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["baseNode.top.head.textLv"] = {
		varname = "textLv",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},

	["baseNode.top.head.textNoteLv"] = {
		varname = "textNoteLv",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["baseNode.top.textRankNote"] = "textRankNote",
	["baseNode.top.textStage"] = "textStage",
	["baseNode.top.textServer"] = "textServer",
	["item"] = "item",
	["baseNode.down1"] = "down1",
	["baseNode.down2"] = "down2",
	["baseNode.down1.list1"] = {
		varname = "list",
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
		varname = "list",
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
		varname = "list",
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
		varname = "list",
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
}

function CrossArenaPersonalInfoView:onCreate(personalInfo)
	self.roleId = personalInfo.role_db_id
	self.rank = idler.new(personalInfo.rank)
	self.fightPoint = idler.new(0)
	self.logoId = idler.new(personalInfo.role_logo)
	self.frameId = idler.new(personalInfo.role_frame)
	self.personalInfo = personalInfo
	self.team1 = {}
	self.team2 = {}
	self.team3 = {}
	self.team4 = {}

	self.textName:text(personalInfo.role_name)
	self.imgVip:visible(personalInfo.role_vip > 0)
	if personalInfo.role_vip > 0 then
		self.imgVip:texture(string.format("common/icon/vip/icon_vip%d.png", personalInfo.role_vip))
	end

	self.textLv:text(personalInfo.role_level)
	adapt.oneLineCenterPos(cc.p(100, 25), {self.textNoteLv, self.textLv},cc.p(0, 5))
	self.textRank:text(dataEasy.getCrossArenaStageByRank(personalInfo.rank).rank)
	self.textStage:text(dataEasy.getCrossArenaStageByRank(personalInfo.rank).stageName)
	self.textServer:text(string.format(gLanguageCsv.brackets, getServerArea(personalInfo.game_key, true)))

	adapt.oneLinePos(self.textName, {self.textServer, self.imgVip}, {cc.p(10,0), cc.p(5,0)})


	local team = {[1] = {[1] = {}, [2] = {}},
				[2] = {[1] = {}, [2] = {}}}
	local zl1 =0
	local zl2 =0
	local attrs ={[1] = {}, [2] = {}}

	local csvTab = csv.cards
	local unitTab = csv.unit
	for i = 1, 2 do
		for j = 1, 6 do
			local id = personalInfo.defence_cards[i][j]
			if id then
				local cardInfo = personalInfo.defence_card_attrs[id]
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
	self.down1:get("imgBg.textZl"):text(zl1)
	self.down2:get("imgBg.textZl"):text(zl2)

	self.down1:get("imgBg.imgBuf"):texture(dataEasy.getTeamBuff(attrs[1]).imgPath)
	self.down2:get("imgBg.imgBuf"):texture(dataEasy.getTeamBuff(attrs[2]).imgPath)

	adapt.oneLinePos(self.down1:get("imgBg.textNote"), self.down1:get("imgBg.textZl"))
	adapt.oneLinePos(self.down2:get("imgBg.textNote"), self.down2:get("imgBg.textZl"))
	if matchLanguage({"en"}) then
		adapt.setAutoText(self.down1:get("textNote1"), nil, 120)
		adapt.setAutoText(self.down1:get("textNote2"), nil, 120)
		adapt.setAutoText(self.down2:get("textNote1"), nil, 120)
		adapt.setAutoText(self.down2:get("textNote2"), nil, 120)
	end

	self.team1 = team[1][1]
	self.team2 = team[1][2]
	self.team3 = team[2][1]
	self.team4 = team[2][2]
end

return CrossArenaPersonalInfoView