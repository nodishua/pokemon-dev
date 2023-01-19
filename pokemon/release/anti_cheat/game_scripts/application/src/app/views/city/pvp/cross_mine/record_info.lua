-- @date:   2020-07-16
-- @desc:   跨服竞技场战斗信息

local CrossMinePersonalRecordInfoView = class("CrossMinePersonalRecordInfoView", cc.load("mvc").ViewBase)

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
CrossMinePersonalRecordInfoView.RESOURCE_FILENAME = "cross_mine_record_info.json"
CrossMinePersonalRecordInfoView.RESOURCE_BINDING = {
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
	["baseNode.down5"] = "down5",
	["baseNode.down6"] = "down6",
	["baseNode.down1.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[1][2]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
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
				data = bindHelper.defer(function(view)
					return view.team[1][1]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
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
				data = bindHelper.defer(function(view)
					return view.team[2][2]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
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
				data = bindHelper.defer(function(view)
					return view.team[2][1]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
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
				data = bindHelper.defer(function(view)
					return view.team[3][2]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
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
				data = bindHelper.defer(function(view)
					return view.team[3][1]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
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
				data = bindHelper.defer(function(view)
					return view.team[4][2]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
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
				data = bindHelper.defer(function(view)
					return view.team[4][1]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["baseNode.down5.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[5][2]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["baseNode.down5.list2"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[5][1]
				end),
				item = bindHelper.self("item"),
				asyncPreload =2,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["baseNode.down6.list1"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[6][2]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
	["baseNode.down6.list2"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.defer(function(view)
					return view.team[6][1]
				end),
				item = bindHelper.self("item"),
				asyncPreload = 2,
				onItem = function(list, node, k, v)
					initItem(list, node, k, v)
				end,
			},
		},
	},
}

function CrossMinePersonalRecordInfoView:onCreate(personalInfo)
	self.fightPoint = idler.new(0)
	self.logoId = idler.new(personalInfo.logo)
	self.logoId1 = idler.new(personalInfo.defence_logo)
	self.frameId = idler.new(personalInfo.frame)
	self.frameId1 = idler.new(personalInfo.defence_frame)
	self.personalInfo = personalInfo

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

	self.team = {
		[1] = {[1] = {}, [2] = {}},
		[2] = {[1] = {}, [2] = {}},
		[3] = {[1] = {}, [2] = {}},
		[4] = {[1] = {}, [2] = {}},
		[5] = {[1] = {}, [2] = {}},
		[6] = {[1] = {}, [2] = {}},
	}

	local zl  = {0,0,0,0,0,0}


	for i ,infos in pairs(self.team) do
		for j , data in ipairs(infos) do
			data[1] = {isInfo = false}
			data[2] = {isInfo = false}
		end
	end


	local csvTab = csv.cards
	local unitTab = csv.unit
	for i = 1, 3 do
		local infos = personalInfo.cards[i]
		local index = 0
		if infos then
			for _, id in pairs(infos) do
				local cardInfo = personalInfo.card_attrs[id]
				local cardCfg = csv.cards[cardInfo.card_id]
				local unitCfg = csv.unit[cardCfg.unitID]
				if csvTab[cardInfo.card_id] then
					cardInfo.rarity = unitTab[csvTab[cardInfo.card_id].unitID].rarity
					cardInfo.isInfo = true
					index = index + 1
					if index <= 2 then
						self.team[i][1][index] = cardInfo
					else
						self.team[i][2][index - 2] = cardInfo
					end

					zl[i] = zl[i] + cardInfo.fighting_point
				end
			end
		end
	end
	for i = 1, 3 do
		local infos = personalInfo.defence_cards[i]
		local index = 0
		if infos then
			for _, id in pairs(infos) do
				local cardInfo = personalInfo.defence_card_attrs[id]
				local cardCfg = csv.cards[cardInfo.card_id]
				local unitCfg = csv.unit[cardCfg.unitID]
				if csvTab[cardInfo.card_id] then
					cardInfo.rarity = unitTab[csvTab[cardInfo.card_id].unitID].rarity
					cardInfo.isInfo = true
					index = index + 1
					if index <= 2 then
						self.team[i+3][1][index] = cardInfo
					else
						self.team[i+3][2][index - 2] = cardInfo
					end

					zl[i+3] = zl[i+3] + cardInfo.fighting_point
				end
			end
		end
	end


	local panel = {
		self.down1,
		self.down2,
		self.down3,
		self.down4,
		self.down5,
		self.down6,
	}

	for index  = 1, 3 do
		local sign = personalInfo.stats[index]
		if sign  then
			if sign == "win" then
				panel[index]:get("img"):texture("city/pvp/craft/icon_win.png")
			else
				panel[index]:get("img"):texture("city/pvp/craft/icon_lose.png")
			end

		else
			panel[index]:visible(false)
			panel[index+3]:visible(false)
		end
	end

	for index = 1, 6 do
		panel[index]:get("textZl"):text(zl[index])
	end

	if personalInfo.result == "win" then
		self.img:texture("city/pvp/craft/icon_win.png")
		self.img1:texture("city/pvp/craft/icon_lose.png")
	else
		self.img:texture("city/pvp/craft/icon_lose.png")
		self.img1:texture("city/pvp/craft/icon_win.png")
	end
end

return CrossMinePersonalRecordInfoView