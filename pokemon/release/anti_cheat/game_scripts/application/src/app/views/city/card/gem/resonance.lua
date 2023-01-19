--共鸣效果
local ResonanceView = class("ResonanceView", Dialog)

ResonanceView.RESOURCE_FILENAME = "gem_resonance.json"
ResonanceView.RESOURCE_BINDING = {
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
	["icon"] = "icon",
	["suitList"] = "suitList",
	["suit1"] = "suit1",
	["suit2"] = "suit2",
	["suitList2"] = "suitList2",
	["suit3"] = "suit3",
}

function ResonanceView:onCreate()
	self.suit2:hide()
	self.suit1:hide()
	self.suit3:hide()
	self.suitList:setScrollBarEnabled(false)
	self.suitList2:setScrollBarEnabled(false)
	self.quality = 2
	self.suitId = 1
	self.btnTab = idler.new(1)
	self.suitData = idlers.new({})
	local data = {}
	for i=1,9 do
		table.insert(data, {icon = ui.GEM_SUIT_ICON[i], select = false})
	end
	self.suitData:update(data)
	self.btnTab:addListener(function(val, oldval)
		self.suitData:atproxy(oldval).select = false
		self.suitData:atproxy(val).select = true
	end)

	self.icon:texture('city/card/gem/suit/icon_t1.png')
	self.icon1:get("select"):visible(true)

	self:suitUpdate(self.suitId, self.quality)
	self.item:visible(false)
	Dialog.onCreate(self)
end

--选择品质
function ResonanceView:atrributeBtn(color)
	for i=2,6 do
		self["icon"..(i-1)]:get("select"):visible(i == color)
	end
	if color ~= self.quality then
		self:suitUpdate(self.suitId, color)
		self.quality = color
	end
end

--选择套装
function ResonanceView:btnSuitFunc(node, panel, k, v, event)
	if event.name == 'began' then
		self.touchBeganPos = panel:getTouchBeganPosition()
		self.downList:setTouchEnabled(false)
		self.isClicked = true
	elseif event.name == 'moved' then
		local pos = event
		local deltaX = math.abs(pos.x - self.touchBeganPos.x)
		if deltaX >= ui.TOUCH_MOVED_THRESHOLD then
			self.isClicked = false
			self.downList:setTouchEnabled(true)
		end
	elseif event.name == 'ended' or event.name == 'cancelled' then
		if self.isClicked then
			self.btnTab:set(k)
			self.icon:texture(ui.GEM_SUIT_ICON[k])
			if self.suitId ~= k then
				self:suitUpdate(k, self.quality)
				self.suitId = k
			end
		end
	end
end

function ResonanceView:suitUpdate(suitId, quality)
	if not suitId then return end
	self.suitList:removeAllChildren()
	self.suitList2:removeAllChildren()
	local pushbackTab = function(suitNum)
		local tab = self.suit1:clone():show()
		tab:get("txt"):text(gLanguageCsv["symbolNumber" .. suitNum] .. gLanguageCsv.emboitement)
		self.suitList:pushBackCustomItem(tab)
	end
	local nameInfo = true
	for i = 1, 9 do
		local data = gGemSuitCsv[suitId][quality][i]
		if data then
			if nameInfo then
				nameInfo = false
				self.name:text(data.suitName)
				text.addEffect(self.name, {color=ui.COLORS.QUALITY[quality]})
			end
			pushbackTab(data.suitNum or 6)
			local suitList2
			for i = 1, math.huge do
				if data["attrType"..i] and data["attrType"..i] ~= 0 then
					if i % 3 == 1 then
						suitList2 = self.suitList2:clone()
						self.suitList:pushBackCustomItem(suitList2)
					end
					local attrTypeStr = game.ATTRDEF_TABLE[data["attrType"..i]]
					local name = gLanguageCsv["attr"..string.caption(attrTypeStr)]
					local suit2 = self.suit2:clone():show()
					suit2:get("txt"):text(name)
					suit2:get("num"):x(suit2:get("txt"):width()+suit2:get("txt"):x())
					suit2:get("num"):text('+'..dataEasy.getAttrValueString(data["attrType"..i], data["attrNum"..i]))
					suitList2:pushBackCustomItem(suit2)
				else
					break
				end
			end
			local suit3 = self.suit3:clone():show()
			self.suitList:pushBackCustomItem(suit3)
		end
	end
end

return ResonanceView
