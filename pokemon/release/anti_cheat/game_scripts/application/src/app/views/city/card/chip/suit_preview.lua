--共鸣效果
local ChipSuitPreView = class("ChipSuitPreView", Dialog)

ChipSuitPreView.RESOURCE_FILENAME = "chip_suit_preview.json"
ChipSuitPreView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["downList"] = {
		varname = "downList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("suitData"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:get("icon"):texture(v.icon)
					node:get("select"):visible(v.select)
					node:onTouch(functools.partial(list.clickCell, node, k, v))
				end,
			},
			handlers = {
				clickCell = bindHelper.self("btnSuitFunc"),
			},
		}
	},
	["icon1"] = {
		varname = "icon1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(2)
			end)}
		},
	},
	["icon2"] = {
		varname = "icon2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(3)
			end)}
		},
	},
	["icon3"] = {
		varname = "icon3",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(4)
			end)}
		},
	},
	["icon4"] = {
		varname = "icon4",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(5)
			end)}
		},
	},
	["icon5"] = {
		varname = "icon5",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:atrributeBtn(6)
			end)}
		},
	},
	["name"] = "name",
	["icon"] = "icon",

	["suit1"] = "suit1",
	["suit3"] = "suit3",

	["suitList"] = {
		varname = "suitList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("suitAttrDatas"),
				item = bindHelper.self("suit3"),
				item01 = bindHelper.self("suit1"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local listW = list:size().width
					node:removeAllChildren()
					if v.sign == 1 then
						node:size(cc.size(listW, 80))
						local cell = list.item01:clone()
							:anchorPoint(cc.p(0, 0.5))
							:xy(0, 40)
							:addTo(node)
							:show()
						cell:get("txt"):text(v.str)

					else
						node:size(cc.size(listW, 80))
						local richText = rich.createWithWidth(v.str, 40, nil, 1039, nil, cc.p(0, 0))
							:anchorPoint(cc.p(0, 1))
							:xy(10, 70 )
							:addTo(node)
					end
				end,
			},
		}
	},
}

function ChipSuitPreView:onCreate()
	self.suitID        = idler.new(1)
	self.quality       = idler.new(2)
	self.suitData      = idlers.new({})
	self.suitAttrDatas = idlertable.new({})

	self:onSetSuitData()

	self.suitID:addListener(function(val, oldval)
		self.suitData:atproxy(oldval).select = false
		self.suitData:atproxy(val).select = true

		self:initSelectUI(val)
		self:updateSuitAttrs()
	end)

	self.quality:addListener(function(val, oldVal)

		self:updateQualityBtn(val)
		self:updateSuitAttrs()
	end)

	Dialog.onCreate(self)
end

function ChipSuitPreView:onSetSuitData()
	local suitID = self.suitID:read()
	local suitDatas = {}
	for index, cfg in ipairs(csv.chip.suits) do
		local tempData = {}
		if not suitDatas[cfg.suitID] then
			tempData.id = cfg.suitID
			tempData.icon = cfg.suitIcon
			tempData.name = cfg.suitName
			tempData.select = suitID == cfg.suitID

			suitDatas[cfg.suitID] = tempData
		end
	end
	self.suitData:update(suitDatas)
end

function ChipSuitPreView:initSelectUI(val)
	local suitData = self.suitData:atproxy(val)
	self.name:text(suitData.name)
	self.icon:texture(suitData.icon)
end

function ChipSuitPreView:updateQualityBtn(val)
	for index = 2, 6 do
		self["icon"..(index-1)]:get("select"):visible(index == val)
	end
end

function ChipSuitPreView:updateSuitAttrs()
	local suitID = self.suitID:read()
	local quality = self.quality:read()
	local suitData = gChipSuitCsv[suitID][quality]

	local attrs = {}
	for val, cfg in pairs(suitData) do
		table.insert(attrs, {sign = 1, str = string.format("%s%s",gLanguageCsv["symbolNumber"..val], gLanguageCsv.emboitement)})

		local str = ""
		if cfg.skillID and cfg.skillID ~= 0 then
			str = "#C0x5B545B#"..csv.skill[cfg.skillID].describe
		else

			for index = 1, math.huge do
				local attrT = cfg["attrType"..index]
				if attrT and attrT ~= 0 then
					local attrN = dataEasy.getAttrValueString(attrT, cfg["attrNum"..index])
					str = str .. string.format(gLanguageCsv.chipSuit02, getLanguageAttr(attrT), attrN)
				end

				local nextAttrT = cfg["attrType"..(index + 1)]
				if nextAttrT and nextAttrT ~= 0 then
					str =str.."#C0x5B545B#, "
				else
					break
				end
			end
		end
		table.insert(attrs, {sign = 2, str = str})
	end

	self.suitAttrDatas:set(attrs)
end

--选择品质
function ChipSuitPreView:atrributeBtn(color)
	self.quality:set(color)
end

--选择套装
function ChipSuitPreView:btnSuitFunc(node, panel, k, v)
	self.suitID:set(v.id)
end



return ChipSuitPreView
