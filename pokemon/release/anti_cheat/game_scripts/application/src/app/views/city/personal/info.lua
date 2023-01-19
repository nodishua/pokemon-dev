-- @date:   2018-12-26
-- @desc: 个人信息
local INPUT_LIMIT = 50
local ViewBase = cc.load("mvc").ViewBase
local PersonalInfoView = class("PersonalInfoView", ViewBase)

PersonalInfoView.RESOURCE_FILENAME = "personal_info.json"
PersonalInfoView.RESOURCE_BINDING = {
	["leftPanel.cardImg"] = {
		binds = {
			event = "extend",
			class = "role_figure",
			props = {
				data = bindHelper.model("role", "figure"),
				onNode = function(node)
					node:z(7)
						:y(580)
				end,
				spine = true,
				onSpine = function(spine)
					spine:scale(2)
						 :y(150)
				end,
			},
		}
	},
	["rightPanel.name"] = "rightPanelRoleName",
	["rightPanel.title"] = {
		varname = "title",
		binds = {
			event = "extend",
			class = "role_title",
			props = {
				data = bindHelper.model("role", "title_id")
			},
		},
	},
	["rightPanel.btnLogo"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeIconClick")}
		},
	},
	["rightPanel.btnName"] = {
		varname = "rightPanelBtnName",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeNameClick")}
		},
	},
	["rightPanel.btnTitle"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeTitleClick")}
		},
	},
	["leftPanel.btnChange"] = {
		varname = "btnChange",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeFigureClick")}
		},
	},
	["leftPanel.btnChange.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["rightPanel.uid"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", "uid"),
		},
	},
	["rightPanel.level"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", "level"),
		},
	},
	["rightPanel.union"] = "textUnionName",
	["rightPanel.power"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", "top6_fighting_point"),
		},
	},
	["rightPanel.bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("expSlider"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		}
	},

	["rightPanel.exp"] = "expNum",
	["rightPanel.needExp"] = "needExp",
	["rightPanel"] = "headImg",
	["rightPanel.name10"] = "txt",
	["rightPanel.list"] = {
		varname = "battleArrayList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				margin = 15,
				data = bindHelper.self("battleData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
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
								node:xy(10,0)
							end,
						}
					})
				end,
			},
		},
	},
	["rightPanel.unlock"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", "pokedex"),
			method = function(val)
				return itertools.size(val)
			end,
		}
	},
	["rightPanel.collect"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", "pokedex"),
			method = function(val)
				local num = itertools.size(val) * 100 / table.length(gHandbookArrayCsv)
				return string.format("%.1f%%", num >= 100 and 100 or num)
			end,
		}
	},
	["rightPanel.input"] = "input",
	["rightPanel.btnShare"] = "btnShare",
	["rightPanel.btnExp"] = {
		varname = "btnExp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("overflowExpExchangeListen")}
		}
	},
	["rightPanel.titleTxt"] = "titleTxt",
}

function PersonalInfoView:onCreate()
	self:initModel()
	self.input:text(self.personalSign:read())
	self.input:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
	self.input:setTextColor(ui.COLORS.NORMAL.DEFAULT)

	self.txt:getVirtualRenderer():setLineSpacing(-5)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.personalInfo, subTitle = "INFORMATION"})
	self.expSlider = idler.new(0)
	local maxRoleLv = table.length(gRoleLevelCsv)
	idlereasy.any({self.level, self.levelExp}, function(_, level, levelExp)
		local percent = 100
		if level < maxRoleLv then
			percent = cc.clampf(100 * levelExp / gRoleLevelCsv[level].levelExp, 0, 100)
		end
		self.expNum:text(levelExp)
		self.needExp:text("/"..gRoleLevelCsv[level].levelExp)
		adapt.oneLinePos(self.expNum, self.needExp, cc.p(0,0), "left")
		self.expSlider:set(percent)
	end)
	--根绝设置是否隐藏vip
	local vipLv = not self.vipDisplay and gGameModel.role:read("vip_level") or 0
	bind.extend(self, self.headImg,{
		class = "role_logo",
		props = {
			logoId = gGameModel.role:getIdler("logo"),
			frameId = gGameModel.role:getIdler("frame"),
			level = false,
			vip = vipLv,
			onNode = function (node)
				node:xy(157, 1030)
			end
		},
	})

	--# 经验溢出入口
	idlereasy.when(self.overflow_exp, function (_, overflow_exp)
		self.btnExp:visible(false)
		if dataEasy.isUnlock(gUnlockCsv.overflowExpExchange) then
			if maxRoleLv == self.level:read() or overflow_exp > 0 then
				self.btnExp:visible(true)
			end
		end
		local text = maxRoleLv == self.level:read() and "Max" or self.levelExp:read()
		self.expNum:text(text)
		adapt.oneLinePos(self.expNum, self.needExp, cc.p(0,0), "left")
		self.needExp:visible(maxRoleLv ~= self.level:read())
	end)

	self.item = ccui.Layout:create():size(200, 200)
	self.item:show()
	self.item:retain()
	self.battleArrayList:setScrollBarEnabled(false)
	idlereasy.any({self.battleCards, self.cards},function (obj, battleCards, cards)
		local t = {}
		for k, dbid in pairs(battleCards) do
			local card = gGameModel.cards:find(dbid)
			local cardData = card:read("card_id","skin_id", "fighting_point", "level", "star", "advance", "created_time")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
			table.insert(t, {
				cardId = cardData.card_id,
				unitId = unitId,
				advance = cardData.advance,
				star = cardData.star,
				level = cardData.level,
				rarity = unitCsv.rarity,
			})
		end
		if #t < 6 then
			local num = #t
			for i=num + 1, 6 do
				table.insert(t, {
					unitId = -1,
				})
			end
		end
		self.battleData = idlertable.new(t)
	end)

	blacklist:addListener(self.input, "*", function (text)
		self.input:text(string.utf8limit(text, INPUT_LIMIT, true))
		if self.input:text() ~= self.personalSign:read() then
			gGameApp:requestServer("/game/role/personal/sign", nil, self.input:text())
		end
	end)

	uiEasy.updateUnlockRes(gUnlockCsv.roleFigure, self.btnChange, {pos = cc.p(260, 90)})

	self:enableMessage():registerMessage("adapterNotchScreen", function(flag)
		adaptUI(self:getResourceNode(), "personal_info.json", flag)
	end)
	idlereasy.when(self.titleId, function (_, val)
		self.titleTxt:visible(val == -1)
	end)
	--公会名字
	idlereasy.any({self.unionId, self.unionName},function(_, unionId, unionName)
		local str = gLanguageCsv.none
		if unionId then
			str = unionName
		end
		self.textUnionName:text(str)
	end)
	local txt = self.headImg:get("name10")
	adapt.setAutoText(txt, txt:text())
end

function PersonalInfoView:overflowExpExchangeListen()
	gGameUI:stackUI("city.personal.overflow_exp", nil, {clickClose = true})
end

function PersonalInfoView:initModel()
	self.level = gGameModel.role:getIdler("level")
	self.levelExp = gGameModel.role:getIdler("level_exp")
	self.cards = gGameModel.role:getIdler("cards")
	self.battleCards = gGameModel.role:getIdler("battle_cards")
	self.personalSign = gGameModel.role:getIdler("personal_sign")
	self.logo = gGameModel.role:getIdler("logo")
	self.frame = gGameModel.role:getIdler("frame")
	self.figure = gGameModel.role:getIdler("figure")
	self.roleName = gGameModel.role:getIdler("name")
	self.renameCount = gGameModel.role:getIdler("rename_count")
	self.titleId = gGameModel.role:getIdler("title_id")
	self.unionId = gGameModel.role:getIdler("union_db_id")
	self.unionName = gGameModel.union:getIdler("name")
	self.overflow_exp = gGameModel.role:getIdler("overflow_exp")
	--通过设置可以关闭vip显示
	self.vipDisplay = gGameModel.role:read("vip_hide")
	idlereasy.when(self.roleName, function(_, name)
		self.rightPanelRoleName:text(name)
		local x = cc.clampf(self.rightPanelRoleName:x() + self.rightPanelRoleName:width() + 40, 820, 990)
		self.rightPanelBtnName:x(x)
	end)
end

function PersonalInfoView:onChangeIconClick()
	gGameUI:stackUI("city.personal.role_logo", nil, {clickClose = true})
end

function PersonalInfoView:onCleanup()
	if self.item then
		self.item:release()
		self.item = nil
	end
	ViewBase.onCleanup(self)
end

function PersonalInfoView:onChangeFigureClick()
	if not dataEasy.isUnlock(gUnlockCsv.roleFigure) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.roleFigure))
		return
	end
	gGameUI:stackUI("city.personal.figure", nil, {clickClose = true})
end

function PersonalInfoView:onChangeNameClick()
	gGameUI:stackUI("city.card.changename", nil, nil, {
		typ = "role",
		name = self.roleName:read(),
		cost = gCostCsv.rename_cost[math.min(self.renameCount:read() + 1, table.length(gCostCsv.rename_cost))],
		titleTxt = gLanguageCsv.roleRename
	})
end

function PersonalInfoView:onChangeTitleClick()
	if not dataEasy.isUnlock(gUnlockCsv.title) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.title))
	else
		gGameUI:stackUI("city.develop.title_book.view")
	end
end

return PersonalInfoView
