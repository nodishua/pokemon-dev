-- @date:   2021-04-23
-- @desc:   z觉醒碎片选择界面

local ViewBase = cc.load("mvc").ViewBase
local ZawakeChoosFragmentView = class("ZawakeChoosFragmentView", Dialog)

ZawakeChoosFragmentView.RESOURCE_FILENAME = "zawake_choose_frag.json"
ZawakeChoosFragmentView.RESOURCE_BINDING = {
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
				dataOrderCmp = function(a, b)
					if a.cardType ~= b.cardType then
						return a.cardType > b.cardType
					end
					if a.num ~= b.num then
						return a.num > b.num
					end
					return a.id < b.id
				end,
				onCell = function(list, node, k, v)
					uiEasy.setIconName(v.id, nil, {node = node:get("name")})
					adapt.setTextScaleWithWidth(node:get("name"), nil, 260)
					bind.extend(list, node:get("icon"), {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
							},
							onNode = function(panel)
								panel:setTouchEnabled(false)
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
function ZawakeChoosFragmentView:onCreate(params)
	self.selectedFragId = params.selectedFragId
	local fragID = params.fragID

	self.showData = idlers.new({})
	self.showTip = idler.new(false)

	local cfg = csv.zawake.exchange[fragID]
	idlereasy.any({gGameModel.role:getIdler("frags"), gGameModel.role:getIdler("items")}, function(_, frags, items)
		local fragInfos = {}
		for id, v in pairs(frags) do
			if dataEasy.isFragmentCard(id) then
				local fragCsv = csv.fragments[id]
				if fragCsv.type == 1 then
					local cardCsv = csv.cards[fragCsv.combID]
					local unitCsv = csv.unit[cardCsv.unitID]
					local quality = dataEasy.getCfgByKey(id).quality
					for _, needFrag in csvMapPairs(cfg.needFrags) do
						if needFrag[1] == quality then
							if needFrag[2] == -1 or unitCsv.natureType == needFrag[2] or (unitCsv.natureType2 and unitCsv.natureType2 == needFrag[2]) then
								fragInfos[id] = {
									id = id,
									num = v,
									itemNum = needFrag[3],
									cardType = cardCsv.cardType
								}
							end
						end
					end
					for _, needFrag in csvMapPairs(cfg.needSpecialFrags) do
						if id == needFrag[1] then
							fragInfos[id] = {
								id = id,
								num = v,
								itemNum = needFrag[2],
								cardType = cardCsv.cardType
							}
						end
					end
				end
			end
		end
		-- 对应的万能碎片
		for _, needFrag in csvMapPairs(cfg.needSpecialFrags) do
			if not dataEasy.isFragmentCard(needFrag[1]) then
				local num = dataEasy.getNumByKey(needFrag[1])
				if num > 0 then
					fragInfos[needFrag[1]] = {
						id = needFrag[1],
						num = num,
						itemNum = needFrag[2],
						cardType = 5,
					}
				end
			end
		end
		self.showData:update(fragInfos)
		self.textTip:text(gLanguageCsv.fragMentNotNum)
		self.showTip:set(itertools.size(fragInfos) == 0)
	end)

	-- self.title:get("textNote2"):text(gLanguageCsv.fragment)

	Dialog.onCreate(self)
end


function ZawakeChoosFragmentView:onItemClick(list, k, v)
	self.selectedFragId:set(v.id)
	ViewBase.onClose(self)
end

return ZawakeChoosFragmentView