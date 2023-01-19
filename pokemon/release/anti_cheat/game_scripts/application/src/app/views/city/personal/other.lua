-- @date:   2018-12-27
-- @desc:他人信息
local PersonalOtherView = class("PersonalOtherView", Dialog)

PersonalOtherView.RESOURCE_FILENAME = "personal_other.json"
PersonalOtherView.RESOURCE_BINDING = {
	["leftPanel.bg"] = "bg",
	["leftPanel.cardImg"] = {
		binds = {
			event = "extend",
			class = "role_figure",
			props = {
				data = bindHelper.self("figureId"),
				onNode = function(node)
					node:z(7)
				end,
			},
		}
	},
	["rightPanel.upPanel.namePanel.txtContent"] = "nameTxt",
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["rightPanel.upPanel.headImg.vip"] = "vip",
	["rightPanel.upPanel.levelPanel.txtContent"] = "levelTxt",
	["rightPanel.upPanel.powerPanel.txtContent"] = "powerTxt",
	["rightPanel.upPanel.guildPanel.txtContent"] = "unionTxt",
	["rightPanel.upPanel.headImg"] = {
		varname = "headImg",
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = bindHelper.self("logoId"),
				frameId = bindHelper.self("frameId"),
				level = false,
				vip = bindHelper.self("vipLv"),
				onNode = function(node)
					node:scale(0.9)
				end,
			}
		},

	},
	["rightPanel.centerPanel.battleArrayPanel.list"] = {
		varname = "battleArrayList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
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
								node:scale(0.9)
							end,
						}
					})
					if v.unitId > 0 then
						bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onClickItem"),
			},
		},
	},
	["rightPanel.centerPanel.battleArrayPanel.txt"] = "txt",
	["rightPanel.centerPanel.unlockPanel.txtContent"] = "unlockTxt",
	["rightPanel.centerPanel.collectPanel.txtContent"] = "collectTxt",
	["rightPanel.downPanel.text"] = "signTxt",
	["rightPanel.upPanel.titlePanel.panel"] = {
		binds = {
			event = "extend",
			class = "role_title",
			props = {
				data = bindHelper.self("titleId")
			},
		}
	},
}

function PersonalOtherView:onCreate(personData)
	self.personData = personData
	self.levelTxt:text(personData.level)
	self.unionTxt:text(personData.union_name ~= "" and personData.union_name or gLanguageCsv.none)
	self.nameTxt:text(personData.name)
	local str = gLanguageCsv.soLazy
	if personData.level > gCommonConfigCsv.personalSignShowLevel and string.trim(personData.personal_sign) ~= "" then
		str = personData.personal_sign
	end
	self.signTxt:text(str)
	self.powerTxt:text(personData.battle_fighting_point)
	self.collectTxt:text(string.format("%.1f%%",personData.collect_num * 100 / table.length(gHandbookArrayCsv)))
	self.unlockTxt:text(personData.collect_num)
	self.figureId = idler.new(personData.figure)
	if matchLanguage({"cn", "tw", "kr"}) then
		self.txt:getVirtualRenderer():setMaxLineWidth(60)
		self.txt:getVirtualRenderer():setLineSpacing(-10)
	elseif matchLanguage({"en"}) then
		adapt.setAutoText(self.txt,self.txt:text(), 300)
	end
	local size = self.headImg:size()
	self.logoId = idler.new(personData.logo)
	self.frameId = idler.new(personData.frame)
	self.vipLv = idler.new(personData.vip_level)
	self.titleId = idler.new(personData.title_id)
	self.item = ccui.Layout:create():size(180, 180)
		:show()
		:setTouchEnabled(true)
		:retain()
	local t = {}
	for i, v in ipairs(personData.cards) do
		local cardCsv = csv.cards[v.card_id == 0 and 11 or v.card_id]
		local unitCsv = csv.unit[cardCsv.unitID]
		local unitId = dataEasy.getUnitId(v.card_id, v.skin_id)
		table.insert(t, {
			cardId = v.card_id == 0 and 11 or v.card_id,
			advance = v.advance,
			unitId = unitId,
			star = v.star,
			level = v.level,
			rarity = unitCsv.rarity,
			id = v.id,
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
	Dialog.onCreate(self)
end

function PersonalOtherView:onCleanup()
	if self.item then
		self.item:release()
		self.item = nil
	end
	Dialog.onCleanup(self)
end

function PersonalOtherView:onClickItem(list, k, v)
	if v.cardId == -1 then
		return
	end
	gGameApp:requestServer("/game/card_info", function (tb)
		gGameUI:stackUI("city.card.info", nil, nil, tb.view)
	end, v.id)
end

return PersonalOtherView