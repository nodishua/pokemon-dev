
--@desc: 选择卡牌或者碎片

local ViewBase = cc.load("mvc").ViewBase
local MegaFragmentSelectView = class("MegaFragmentSelectView", Dialog)

MegaFragmentSelectView.RESOURCE_FILENAME = "card_mega_fragment_select.json"
MegaFragmentSelectView.RESOURCE_BINDING = {
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
					uiEasy.setIconName(v.id, nil, {node = node:get("name")})
					adapt.setTextScaleWithWidth(node:get("name"), nil, 240)
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
function MegaFragmentSelectView:onCreate(data, cb)
	self.data = data
	self.item:visible(false)
	self.list:setScrollBarEnabled(false)
	self.innerList:setScrollBarEnabled(false)
	self.showData = idlers.new({})
	self.cb = cb
	self.showTip = idler.new(false)
	local cfg = csv.card_mega_convert[data.csvId]
	local text = gLanguageCsv.fragment
	idlereasy.any({gGameModel.role:getIdler("frags"), gGameModel.role:getIdler("zfrags")}, function(_, frags, zfrags)
		local fragInfos = {}
		for id, v in pairs(frags) do
			local fragCsv = csv.fragments[id]
			if fragCsv.type == 1 then
				local cardCsv = csv.cards[fragCsv.combID]
				local unitCsv = csv.unit[cardCsv.unitID]
				local quality = dataEasy.getCfgByKey(id).quality
				if cfg.needFrags1[1] == quality then
					for i = 1, math.huge do
						local needFrags = cfg["needFrags" .. i]
						if itertools.isempty(needFrags) then
							break
						end
						if needFrags[2] == -1 or unitCsv.natureType == needFrags[2] or (unitCsv.natureType2 and unitCsv.natureType2 == needFrags[2]) then
							table.insert(fragInfos, {
								id = id,
								num = v,
								itemNum = needFrags[3],
								cardType = cardCsv.cardType
							})
							break
						end
					end
				end
			end
		end
		zfrags = zfrags or {}
		for id, v in pairs(zfrags) do
			local fragCsv = csv.zawake.zawake_fragments[id]
			local quality = fragCsv.quality
			if cfg.type == 1 and fragCsv.type == 5 or fragCsv.type == 6 then
				-- 通用用于钥石
				if cfg.needFrags1[1] == quality then
					for i = 1, math.huge do
						local needFrags = cfg["needFrags" .. i]
						if itertools.isempty(needFrags) then
							break
						end
						if needFrags[2] == -1 then
							table.insert(fragInfos, {
								id = id,
								num = v,
								itemNum = needFrags[3],
								cardType = 0,
							})
							break
						end
					end
				end
			elseif cfg.type == 2 and fragCsv.type == 5 then
				-- 专属用于进化石
				if cfg.needFrags1[1] == quality then
					local cardCsv = csv.cards[fragCsv.cardID]
					local unitCsv = csv.unit[cardCsv.unitID]
					for i = 1, math.huge do
						local needFrags = cfg["needFrags" .. i]
						if itertools.isempty(needFrags) then
							break
						end
						if needFrags[2] == -1 or unitCsv.natureType == needFrags[2] or (unitCsv.natureType2 and unitCsv.natureType2 == needFrags[2]) then
							table.insert(fragInfos, {
								id = id,
								num = v,
								itemNum = needFrags[3],
								cardType = 0,
							})
							break
						end
					end
				end
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
		self.textTip:text(gLanguageCsv.fragMentNotNum)
		self.showTip:set(#fragInfos == 0)
	end)

	self.title:get("textNote2"):text(text)

	Dialog.onCreate(self)
end


function MegaFragmentSelectView:onItemClick(list, k, v)
	self.data.selectId = v.id
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return MegaFragmentSelectView