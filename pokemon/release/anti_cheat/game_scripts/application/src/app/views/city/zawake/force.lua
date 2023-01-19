-- @date:   2021-04-08
-- @desc:   z觉醒觉醒之力界面

local zawakeTools = require "app.views.city.zawake.tools"
local ViewBase = cc.load("mvc").ViewBase
local ZawakeForceView = class("ZawakeForceView", Dialog)

ZawakeForceView.RESOURCE_FILENAME = "zawake_force.json"
ZawakeForceView.RESOURCE_BINDING = {
	["bgPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")}
		}
	},
	["textLv"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("lvText"),
		},
	},
	["textExp"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("expText"),
		},
	},
	["expBar"] = {
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
	["item"] = "item",
	["rightList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listDatas"),
				item = bindHelper.self("item"),
				level = bindHelper.self("level"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("num", "txt")
					childs.txt:removeAllChildren()
					childs.num:text(string.format("Lv.%s:", v.level))
					local nowLevel = list.level:read()
					local isGray = false
					if nowLevel < v.level then
						text.addEffect(childs.num, {color = ui.COLORS.DISABLED.GRAY})
						isGray = true
					end
					local str = zawakeTools.getAttrStr(v.cfg, isGray)
					local richWidth = node:width() - childs.num:width() - childs.num:x() - 20
					local rich = rich.createWithWidth(str, 44, nil, richWidth)
					rich:anchorPoint(0, 0)
					rich:xy(0, 0)
					rich:addTo(childs.txt)

					node:height(rich:height() + 10)
					childs.num:y(node:height() - 30)
					adapt.oneLinePos(childs.num, childs.txt, cc.p(5, 0))
					childs.txt:y(5)
				end,
			},
		},
	},
	["leftInnerList"] = "leftInnerList",
	["leftItem"] = "leftItem",
	["leftList"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("attrCardDatas"),
				item = bindHelper.self("leftInnerList"),
				cell = bindHelper.self("leftItem"),
				columnSize = 6,
				onCell = function(list, node, k, v)
					local childs = node:multiget("icon", "txt")
					local data = {}
					for k, val in pairs(v.zawakeDate) do
						table.insert(data, {stage = k, level = val})
					end
					table.sort(data, function(a, b)
						return a.stage > b.stage
					end)
					childs.txt:text(string.format("%s%s", gLanguageCsv.effortAdvance, gLanguageCsv['symbolRome'..data[1].stage]))
					local cardCsv = csv.cards[v.cardId]
					local unitCsv = csv.unit[cardCsv.unitID]
					bind.extend(list, childs.icon, {
						class = "card_icon",
						props = {
							cardId = v.cardId,
							rarity = unitCsv.rarity,
							onNode = function(panel)
								panel:anchorPoint(0.5, 0.5)
								local size = childs.icon:size()
								panel:xy(size.width/2, size.height/2)
								panel:scale(0.7)
							end,
						}
					})
				end,
			},
		},
	},
	["downListTips"] = "downListTips",
}

function ZawakeForceView:onCreate()
	Dialog.onCreate(self)
	self:initModel()
	idlereasy.when(self.zawake, function(_, zawake)
		if zawake == nil then zawake = {} end
		local allExp = 0
		local nowExp = 0
		local levelAllExp = 0
		local nextExp = 0
		local level = 0
		local allCardsData = {}
		for zawakeID, zawakeDate in pairs(zawake) do
			for stageID, level in pairs(zawakeDate) do
				for i = 1, level do
					local cfg = zawakeTools.getLevelCfg(zawakeID, stageID, level)
					if not cfg then
						break
					end
					allExp = allExp + cfg.exp
				end
			end
			-- 根据zawakeID获取符合card
			local cardData = zawakeTools.getCardByZawakeID(zawakeID)
			cardData.zawakeDate = zawakeDate
			table.insert(allCardsData, cardData)
		end
		self.attrCardDatas:update(allCardsData)
		self.downListTips:visible(#allCardsData == 0)
		local datas = {}
		for k, cfg in csvPairs(csv.zawake.bonus) do
			table.insert(datas, {cfg = cfg, level = k})
		end
		table.sort(datas, function(a, b)
			return a.level < b.level
		end)
		-- print_r(datas)
		for k, val in ipairs(datas) do
			local cfg = val.cfg
			nextExp = cfg.exp
			levelAllExp = levelAllExp + nextExp
			nowExp = levelAllExp - allExp
			-- print("levelAllExp:", levelAllExp, cfg.exp, nowExp)
			if nowExp > 0 then
				level = val.level - 1
				break
			elseif k == csvSize(csv.zawake.bonus) and allExp >= levelAllExp then
				level = val.level
			end
		end
		self.level:set(level)
		self.listDatas:update(datas)
		self.lvText:set("Lv:"..level)
		self.expText:set(nowExp >= 0 and string.format("%s/%s", nextExp - nowExp, nextExp) or "Max")
		local percent = 100
		if (nextExp - nowExp) >= 0 then
			percent = cc.clampf(100 * (nextExp - nowExp) / nextExp, 0, 100)
		end
		self.expSlider:set(percent)
	end)
end

function ZawakeForceView:initModel()
	self.zawake = gGameModel.role:getIdler("zawake")
	self.attrCardDatas = idlers.newWithMap({})
	self.listDatas = idlers.newWithMap({})
	self.lvText = idler.new("")
	self.expText = idler.new("")
	self.level = idler.new(0)
	self.expSlider = idler.new(0)
end

function ZawakeForceView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function ZawakeForceView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.zawakeForceLevelTitle)
		end),
		c.noteText(124101, 124151),
	}
	return context
end

return ZawakeForceView