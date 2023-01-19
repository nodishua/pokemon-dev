-- @date:   2020-01-20
-- @desc:   图鉴拓展界面

local ViewBase = cc.load("mvc").ViewBase
local handbookTools = require "app.views.city.handbook.tools"
local HandbookDetailView = class("HandbookDetailView", Dialog)
HandbookDetailView.RESOURCE_FILENAME = "handbook_detail.json"
HandbookDetailView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["pageItem"] = "pageItem",
	["leftPanel"] = "leftPanel",
	["leftPanel.pageList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("evolutionDatas"),
				item = bindHelper.self("pageItem"),
				onItem = function(list, node, k, v)
					node:get("normal"):visible(v.select ~= true)
					node:get("select"):visible(v.select == true)
				end,
				asyncPreload = 15,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["starItem"] = "starItem",
	["rightPanel"] = "rightPanel",
	["rightPanel.btnDetail"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnDetail")}
		}
	},
	["rightPanel.addPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("starDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("icon"):texture(v.icon)
				end,
			},
		},
	},
	["rightPanel.nextAddPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("nextStarDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("icon"):texture(v.icon)
				end,
			},
		},
	},
	["rightPanel.nextAddPanel.btnGoto"] = {
		varname = "btnGoto",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnGotoClick")}
		}
	},
	["rightPanel.nextAddPanel.btnGoto.textTitle"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["mask"] = "mask",
}

function HandbookDetailView:onCreate(cardId, cb)
	self.cb = cb
	self:initModel()
	if not cardId then
		local card = gGameModel.cards:find(self.cards:read()[1])
		cardId = card:read("card_id")
	end
	self.cardId = cardId
	local cardCsv = csv.cards[self.cardId]
	self.cardMarkID = cardCsv.cardMarkID

	self.starDatas = idlertable.new({})
	self.nextStarDatas = idlertable.new({})
	self:setRightPanel()

	local myMaxStar, existCards, dbid = dataEasy.getCardMaxStar(self.cardMarkID)
	--进化链数据
	self.evolutionDatas = idlers.new({})
	local evolutionDatas = {}
	for id,v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) and  v.cardMarkID == cardCsv.cardMarkID and v.canDevelop then
			table.insert(evolutionDatas, {
				existCards = existCards,
				selectDevelop = v.develop,
				cfg = v,
				id = id
			})
		end
	end
	table.sort(evolutionDatas,function(a,b)
		return a.id < b.id
	end)
	self.evolutionDatas:update(evolutionDatas)

	local selectEvolution = 0
	for i,v in ipairs(evolutionDatas) do
		if v.id == cardCsv.id then
			selectEvolution = i
		end
	end
	self.selectEvolution = idler.new(selectEvolution)
	self.selectEvolution:addListener(function(val, oldval)
		local evolutionDatas = self.evolutionDatas:atproxy(val)
		local oldEvolutionDatas = self.evolutionDatas:atproxy(oldval)
		if oldEvolutionDatas then
			oldEvolutionDatas.select = false
		end
		if evolutionDatas then
			self:setLeftPanel(evolutionDatas)
			evolutionDatas.select = true
		end
	end)
	--切换精灵
	self:initPrivilegeListener()
	Dialog.onCreate(self)
end

function HandbookDetailView:initModel()
	self.items = gGameModel.role:getIdler("items")
	self.cards = gGameModel.role:getIdler("cards")
	--level level_exp
	self.cardFeels = gGameModel.role:getIdler("card_feels")
	self.gold = gGameModel.role:getIdler("gold")
end
--左侧面板
function HandbookDetailView:setLeftPanel(evolutionDatas)
	local childs = self.leftPanel:multiget(
		"cardIcon",
		"iconRarity",
		"textCardName",
		"iconAttr1",
		"iconAttr2",
		"btnSelectItem"
	)
	local unitCsv = csv.unit[evolutionDatas.cfg.unitID]
	local size = childs.cardIcon:size()
	local STATE_ACTION = {"standby_loop", "attack", "win_loop", "run_loop"}
	childs.cardIcon:removeAllChildren()
	local cardSprite = widget.addAnimation(childs.cardIcon, unitCsv.unitRes, STATE_ACTION[1], 5)
		:xy(size.width/2, 0)
		:scale(unitCsv.scaleU*2.3)
	cardSprite:setSkin(unitCsv.skin)
	childs.iconAttr1:texture(ui.ATTR_ICON[unitCsv.natureType])
	childs.iconAttr2:hide()
	if unitCsv.natureType2 then
		childs.iconAttr2:texture(ui.ATTR_ICON[unitCsv.natureType2]):show()
	end
	childs.textCardName:text(evolutionDatas.cfg.name)
	childs.iconRarity:texture(ui.RARITY_ICON[unitCsv.rarity])
	adapt.oneLinePos(childs.textCardName, childs.iconRarity, cc.p(8,0), "right")
	adapt.oneLinePos(childs.textCardName, {childs.iconAttr1, childs.iconAttr2}, cc.p(8,0))
end

--右侧面板
function HandbookDetailView:setRightPanel()
	-- 背包里的最大星级，当前存在的卡牌
	local myMaxStar, existCards, dbid = dataEasy.getCardMaxStar(self.cardMarkID)
	self.dbid = dbid

	local attrIcon, attrName, currentAttrNum = handbookTools.getStarAttrData(self.cardMarkID)
	-- 下一阶段加成
	local nextAttrNum
	local nextStar = 0
	for star,v in orderCsvPairs(gPokedexDevelop[self.cardMarkID]) do
		if currentAttrNum ~= v.attrValue1 and star > myMaxStar then
			nextAttrNum = v.attrValue1
			nextStar = star
			break
		end
	end
	handbookTools.setAttrPanel(self.rightPanel:get("addPanel"), attrIcon, attrName..":", currentAttrNum)
	if nextAttrNum ~= nil then
		handbookTools.setAttrPanel(self.rightPanel:get("nextAddPanel"), attrIcon, attrName..":", nextAttrNum)
	end
	self.rightPanel:get("nextAddPanel"):visible(nextAttrNum ~= nil)
	self.rightPanel:get("ImgMax"):scale(2):visible(nextAttrNum == nil)
	self.btnGoto:visible(myMaxStar > 0)

	self.starDatas:set(dataEasy.getStarData(myMaxStar))
	self.nextStarDatas:set(dataEasy.getStarData(nextStar))

end
--切换精灵
function HandbookDetailView:initPrivilegeListener()
	uiEasy.addTouchOneByOne(self.mask, {ended = function(pos, dx, dy)
		if math.abs(dx) > 100 and math.abs(dx) > math.abs(dy) then
			local dir = dx > 0 and -1 or 1
			self.selectEvolution:modify(function(val)
				val = cc.clampf(val + dir, 1, self.evolutionDatas:size())
				return true, val
			end)
		end
	end})
end
function HandbookDetailView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end
function HandbookDetailView:onBtnGotoClick()
	gGameUI:stackUI("city.card.strengthen", nil, nil, 1, self.dbid, self:createHandler("setRightPanel"))
end
--规则
function HandbookDetailView:onBtnDetail()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1220})
end
function HandbookDetailView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.descriptionCultureAddition)
		end),
		c.noteText(72001, 72004),
	}
	return context
end
return HandbookDetailView