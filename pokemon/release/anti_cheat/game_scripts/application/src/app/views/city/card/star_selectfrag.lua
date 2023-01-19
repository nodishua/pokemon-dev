-- @date:   2021-04-26
-- @desc:   极限点碎片选择界面
local zawakeTools = require "app.views.city.zawake.tools"

local ViewBase = cc.load("mvc").ViewBase
local CardStarSelectFragView = class("CardStarSelectFragView", Dialog)

CardStarSelectFragView.RESOURCE_FILENAME = "zawake_choose_frag.json"
CardStarSelectFragView.RESOURCE_BINDING = {
	['title'] = "title",
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["innerList"] = "innerList",
	['list'] = {
		varname = "list",
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				columnSize = 6,
				data = bindHelper.self('showData'),
				item = bindHelper.self('innerList'),
				cell = bindHelper.self('item'),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					uiEasy.setIconName(v.id, nil, {node = node:get("name"), width = node:width()})
					bind.extend(list, node:get("icon"), {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
							},
							onNode = function(panel)
								panel:setTouchEnabled(false)
								if v.num == 0 then
									panel:get("num"):text(0)
								end
							end,
						},
					})
					bind.touch(list, node:get("icon"), {methods = {ended = functools.partial(list.itemClick, k, v)}})
				end
			},
			handlers = {
				itemClick = bindHelper.self('onItemClick')
			}
		}
	},
	["tipPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("showTip"),
		},
	},
	["tipPanel.textTip"] = "textTip",
}

-- fragment碎片
function CardStarSelectFragView:onCreate(params)
	self.selectedFragId = params.selectedFragId
	local cardId = params.cardId
	local cardCsv = csv.cards[cardId]
	local fragsId = cardCsv.fragID

	self.showData = idlers.new({})
	self.showTip = idler.new(false)

	local fragInfos = {}
	local fragNum = dataEasy.getNumByKey(fragsId)
	if fragNum > 0 then
		fragInfos[fragsId] = {
			id = fragsId,
			num = fragNum,
			itemNum = 1,
			cardType = cardCsv.cardType
		}
	end

	if dataEasy.isUnlock(gUnlockCsv.zawake) and cardCsv.zawakeFragID > 0 then
		local num = dataEasy.getNumByKey(cardCsv.zawakeFragID)
		if num > 0 then
			fragInfos[cardCsv.zawakeFragID] = {
				id = cardCsv.zawakeFragID,
				num = num,
				itemNum = 1,
				cardType = cardCsv.cardType
			}
		end
	end
	table.sort(fragInfos, function(a, b)
		if a.cardType ~= b.cardType then
			return a.cardType > b.cardType
		end
		if a.num ~= b.num then
			return a.num > b.num
		end
		return a.id < b.id
	end)
	self.showData:update(fragInfos)

	local cfg = csv.zawake.exchange[fragID]
	self.textTip:text(gLanguageCsv.fragMentNotNum)
	self.showTip:set(itertools.size(fragInfos) == 0)

	-- self.title:get("textNote2"):text(gLanguageCsv.fragment)

	Dialog.onCreate(self)
end


function CardStarSelectFragView:onItemClick(list, k, v)
	self.selectedFragId:set(v.id)
	ViewBase.onClose(self)
end

return CardStarSelectFragView