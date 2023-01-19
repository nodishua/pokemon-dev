-- @date: 2021-04-08
-- @desc: z觉醒选择精灵界面

local zawakeTools = require "app.views.city.zawake.tools"
local ViewBase = cc.load("mvc").ViewBase
local ZawakeReplaceView = class("ZawakeReplaceView", Dialog)

ZawakeReplaceView.RESOURCE_FILENAME = "zawake_choose_card.json"
ZawakeReplaceView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["tipPanel"] = "tipPanel",
	["item"] = "item",
	["innerList"] = "innerList",
	["list"] = {
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				columnSize = 3,
				asyncPreload = 12,
				onCell = function(list, node, k, v)
					local childs = node:multiget("icon", "textFightPoint", "textLevel", "textStage", "txt1", "maskPanel")
					childs.maskPanel:visible(v.isSelf)
					childs.textFightPoint:text(v.maxFightPoint)
					childs.textLevel:text(string.format("(%s/8)", v.level))
					childs.textStage:text(gLanguageCsv.effortAdvance .. gLanguageCsv['symbolRome'..v.stage])
					adapt.oneLinePos(childs.textStage, childs.textLevel, cc.p(10, 0))
					local cfg = csv.cards[v.cfg.id]
					local unitCfg = csv.unit[cfg.unitID]
					local rarity = unitCfg.rarity
					bind.extend(list, childs.icon, {
						class = "card_icon",
						props = {
							cardId = v.cfg.id,
							rarity = rarity,
						}
					})
					node:onClick(functools.partial(list.clickSelect, k, v))
				end,
			},
			handlers = {
				clickSelect = bindHelper.self("onSelectClick"),
			},
		},
	},
}

function ZawakeReplaceView:onCreate(params)
	Dialog.onCreate(self)
	self.zawakeID = params.zawakeID
	-- self.cb = params.cb
	self:initModel()
	self:updateCards()
end

function ZawakeReplaceView:updateCards()
	local cards = zawakeTools.getAllCards()
	local datas = {}
	for zawakeID, data in pairs(cards) do
		local stage, level = zawakeTools.getMaxStageLevel(zawakeID)
		if not stage then
			stage = 1
			level = 0
		end
		table.insert(datas, {
			zawakeID = zawakeID,
			stage = stage,
			level = level,
			cfg = data.cfg,
			maxFightPoint = data.maxFightPoint,
			isSelf = self.zawakeID:read() == zawakeID
		})
	end
	table.sort(datas, function(a, b)
		return a.maxFightPoint > b.maxFightPoint
	end)
	self.tipPanel:visible(#datas == 0)
	self.cardDatas:update(datas)
end

function ZawakeReplaceView:initModel()
	self.zawake = gGameModel.role:read("zawake") or {}
	self.cardDatas = idlers.newWithMap({})
end

function ZawakeReplaceView:onSelectClick(list, k, v)
	self.zawakeID:set(v.zawakeID)
	self:onClose()
end

return ZawakeReplaceView