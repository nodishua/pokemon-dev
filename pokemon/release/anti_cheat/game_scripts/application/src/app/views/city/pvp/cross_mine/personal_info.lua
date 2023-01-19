-- @date:   2020-05-25
-- @desc:   跨服竞技场个人信息

local CrossMinePersonalInfoView = class("CrossMinePersonalInfoView", cc.load("mvc").ViewBase)

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


CrossMinePersonalInfoView.RESOURCE_FILENAME = "cross_mine_person_info.json"
CrossMinePersonalInfoView.RESOURCE_BINDING = {
	["top"] = "top",
	["top.textName"] = "textName",
	["top.head"] = {
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

	["top.textRank"] = {
		varname = "textRank",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["top.head.textLv"] = {
		varname = "textLv",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},

	["top.head.textNoteLv"] = {
		varname = "textNoteLv",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},

	["top.textProRate"] = "textProRate",
	["top.textPoints"] = "textPoints",
	["top.textServer"] = "textServer",
	["item"] = "item",
	["down1"] = "down1",
	["down2"] = "down2",
	["down3"] = "down3",
	["down1.list1"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[1][1]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["down1.list2"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[1][2]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["down2.list1"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[2][1]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["down2.list2"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[2][2]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["down3.list1"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[3][1]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["down3.list2"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[3][2]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 3,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
}

function CrossMinePersonalInfoView:onCreate(personalInfo)
	self.roleId = personalInfo.role_db_id
	self.rank = idler.new(personalInfo.rank)
	self.fightPoint = idler.new(0)
	self.logoId = idler.new(personalInfo.role_logo)
	self.frameId = idler.new(personalInfo.role_frame)
	self.personalInfo = personalInfo

	self.textName:text(personalInfo.role_name)

	self.textLv:text(personalInfo.role_level)
	adapt.oneLineCenterPos(cc.p(100, 25), {self.textNoteLv, self.textLv},cc.p(0, 3))
	self.textRank:text(personalInfo.rank)
	local speed = personalInfo.speed or 0
	self.textProRate:text(string.format(gLanguageCsv.crossMinePVPSpeed02, personalInfo.speed))

	local originC13 = personalInfo.coin13_origin or 0
	local coin13Diff = personalInfo.coin13_diff or 0

	local rankInfo = csv.cross.mine.rank[personalInfo.rank] or {}
	local str = string.format(gLanguageCsv.gameMineRankNum,rankInfo.point or 0)
	local richText = rich.createByStr(str, 40)
			:addTo(self.top, 100, "tip")
			:anchorPoint(0, 0.5)
			:xy(cc.p(567, 121))
			:formatText()

	self.textServer:text(string.format(gLanguageCsv.brackets, getServerArea(personalInfo.game_key, true)))

	adapt.oneLinePos(self.textName,self.textServer, cc.p(10,0))
	adapt.oneLinePos(self.textRank,richText, cc.p(20,0))

	self.team = {[1] = {[1] = {}, [2] = {}},
				[2] = {[1] = {}, [2] = {}},
				[3] = {[1] = {}, [2] = {}}}
	local zl1 =0
	local zl2 =0
	local zl3 =0
	local attrs ={[1] = {}, [2] = {}, [3] = {}}

	local csvTab = csv.cards
	local unitTab = csv.unit
	for i = 1, 3 do
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
						self.team[i][1][j] = cardInfo
					else
						self.team[i][2][j - 3] = cardInfo
					end
					if i == 1 then
						zl1 = zl1 + cardInfo.fighting_point
					elseif i == 2 then
						zl2 = zl2 + cardInfo.fighting_point
					else
						zl3 = zl3 + cardInfo.fighting_point
					end
				end
			else
				if j <= 3 then
					self.team[i][1][j] = {isInfo = false}
				else
					self.team[i][2][j - 3] =  {isInfo = false}
				end
			end
		end
	end
	self.down1:get("imgBg.textZl"):text(zl1)
	self.down2:get("imgBg.textZl"):text(zl2)
	self.down3:get("imgBg.textZl"):text(zl3)

	adapt.oneLinePos(self.down1:get("imgBg.textNote"), self.down1:get("imgBg.textZl"))
	adapt.oneLinePos(self.down2:get("imgBg.textNote"), self.down2:get("imgBg.textZl"))
	adapt.oneLinePos(self.down3:get("imgBg.textNote"), self.down3:get("imgBg.textZl"))
end

return CrossMinePersonalInfoView