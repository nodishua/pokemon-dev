-- @Date:   2019-05-23

local SelectCardView = class("SelectCardView", cc.load("mvc").ViewBase)

SelectCardView.RESOURCE_FILENAME = "character_select_card.json"
SelectCardView.RESOURCE_BINDING = {
	["leftPanel.textName"] = {
		binds = {
			event = "text",
			data = bindHelper.self("card"),
			method = function (card)
				return card.name
			end
		}
	},
	["leftPanel.rarity"] = {
		binds = {
			event = "texture",
			data = bindHelper.self("card"),
			method = function (card)
				local unit = csv.unit[card.unitID]
				return ui.RARITY_ICON[unit.rarity]
			end
		}
	},
	["leftPanel.attr1"] = {
		binds = {
			event = "texture",
			data = bindHelper.self("card"),
			method = function (card)
				local unit = csv.unit[card.unitID]
				return ui.ATTR_ICON[unit.natureType]
			end
		}
	},
	["leftPanel.attr2"] = "attr2",
	["leftPanel.attrPanel.hp.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("hpNum"),
		},
	},
	["leftPanel.attrPanel.attack.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("damageNum"),
		},
	},
	["leftPanel.attrPanel.special.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("specialDamageNum"),
		},
	},
	["leftPanel.attrPanel.phyFang.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("defenceNum"),
		},
	},
	["leftPanel.attrPanel.speFang.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("specialDefenceNum"),
		},
	},
	["leftPanel.attrPanel.speed.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("speedNum"),
		},
	},
	["leftPanel.attrPanel.hp.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("hpPercent"),
		},
	},
	["leftPanel.attrPanel.attack.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("damagePercent"),
		},
	},
	["leftPanel.attrPanel.special.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("specialDamagePercent"),
		},
	},
	["leftPanel.attrPanel.phyFang.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("defencePercent"),
		},
	},
	["leftPanel.attrPanel.speFang.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("specialDefencePercent"),
		},
	},
	["leftPanel.attrPanel.speed.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("speedPercent"),
		},
	},
	["leftPanel.attrPanel.textSum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("allVal"),
		}
	},
	["leftPanel.imgIcon"] = "imgIcon",
	["itemCard"] = "cardItem",
	["rightPanel.downPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("cardData"),
				item = bindHelper.self("cardItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("next", "rarity", "name", "attr1", "attr2",
						"iconPanel")
					local unit = csv.unit[v.unitID]
					childs.next:visible(k ~= 1)
					childs.rarity:texture(ui.RARITY_ICON[unit.rarity])
					childs.attr1:texture(ui.ATTR_ICON[unit.natureType])
					if unit.natureType2 then
						childs.attr2:texture(ui.ATTR_ICON[unit.natureType2])
					else
						childs.attr2:hide()
					end
					childs.name:text(v.name)
					local size = childs.iconPanel:size()
					local sprite2 = widget.addAnimation(childs.iconPanel, unit.unitRes, "standby_loop")
					sprite2:xy(size.width / 2, size.height / 3)
						:scale(2)
					sprite2:setSkin(unit.skin)
					adapt.oneLinePos(childs.name, childs.rarity, cc.p(25, 0), "right")
					adapt.oneLinePos(childs.name, {childs.attr1, childs.attr2}, {cc.p(25, 0), cc.p(5, 0)}, "left")
				end,
			},
		}
	},
	["itemSkill"] = "skillItem",
	["rightPanel.rightUp.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("skillData"),
				item = bindHelper.self("skillItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "iconTxt", "txt", "btn")
					uiEasy.setSkillInfoToItems({
						name = childs.txt,
						icon = childs.icon,
						type1 = childs.iconTxt,
					}, v.skillId)
					childs.btn:onClick(functools.partial(list.clickCell, k, v))
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onClickSkill"),
			}
		}
	},
	["rightPanel.leftUpPanel.txt"] = {
		binds = {
			event = "text",
			data = bindHelper.self("card"),
			method = function (card)
				return card.location
			end
		}
	},
	["rightPanel.leftUpPanel.stancePanel1"] = "stancePanel1",
	["rightPanel.leftUpPanel.stancePanel2"] = "stancePanel2",
	["rightPanel.leftUpPanel.stancePanel3"] = "stancePanel3",
	["leftPanel.btnChange"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["rightPanel.btnSure"] = {
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("onSure")}
		}
	},
}

SelectCardView.RESOURCE_STYLES = {
	full = true,
}

function SelectCardView:onCreate(index, cb)
	self.cb = cb
	local detail = csv.newbie_init[1].cards[index]
	self.id = detail.id
	local card = csv.cards[self.id]

	-- cards表里 种族值<顺序依次为:生命;速度;物攻;物防;特攻;特防;总和> 需要重新组合一下
	local specKeys = {"hp", "speed", "damage", "defence", "specialDamage", "specialDefence"}
	local specValues = {}
	for i=1,6 do
		specValues[specKeys[i]] = card.specValue[i]
	end

	self.skillData = {}
	for k,v in csvPairs(card.skillList) do
		table.insert(self.skillData,  {
			skillId = v,
			skillLevel = 1,
		})
		table.sort(self.skillData,function (a,b)
			return a.skillId < b.skillId
		end)
	end
	self.card = card
	local unit = csv.unit[card.unitID]
	for k,v in pairs(specValues) do
		self[k.."Num"] = idler.new(v)
		self[k.."Percent"] = idler.new(v / 255 * 100)
	end
	if unit.natureType2 then
		self.attr2:texture(ui.ATTR_ICON[unit.natureType2])
	else
		self.attr2:hide()
	end

	local specValue = card.specValue
	for i,v in ipairs(specValue) do
		if i > 6 then
			self.allVal= idler.new(v)
			break
		end
	end
	self.imgIcon:texture(unit.cardShow)
		:visible(true)
		-- :scale(unit.cardShowScale)
	self.cardData = {}
	for i,v in orderCsvPairs(csv.cards) do
		if v.cardMarkID == card.cardMarkID and v.develop < 4 then
			self.cardData[v.develop] = v
		end
	end

	self.stancePanel1:visible(index == 1)
	self.stancePanel2:visible(index == 2)
	self.stancePanel3:visible(index == 3)
end

function SelectCardView:onSure()
	gGameApp:requestServer("/game/role/newbie/card/choose", function()
		gGameUI:stackUI("new_character.gain_sprite", nil, nil, self.id, self.cb)
	end, 2, self.id)
end

function SelectCardView:onClickSkill(list, k, v)
	local view = gGameUI:stackUI("common.skill_detail", nil, {clickClose = true, dispatchNodes = list}, {
		skillId = v.skillId,
		skillLevel = v.skillLevel,
		cardId = self.id
	})
	local panel = view:getResourceNode()
	local x, y = panel:xy()
	panel:xy(x + 1140, y + 200)
end

return SelectCardView