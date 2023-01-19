
-- 战斗手册

local BattlsManualsView = class("BattlsManualsView", Dialog)

local url1 = "city/card/battle_manuals/title_zdsc1_ml.png"
local url2 = "city/card/battle_manuals/title_zdsc2_ml.png"

BattlsManualsView.RESOURCE_FILENAME = "card_battle_manuals.json"
BattlsManualsView.RESOURCE_BINDING = {
	["clickBg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["item2"] = "item2",
	["list"] = "list",
	["right"] = "right",
	["right.title.name"] = "rightName",
	["right.slider"] = "slider",
	["right.list"] = "rightList",
}

function BattlsManualsView:onCreate()
	gGameModel.forever_dispatch:getIdlerOrigin("battleManualDatas"):set(true)
	self.list:setScrollBarEnabled(false)
	self.item:get("list"):setScrollBarEnabled(false)
	local manuals = csv.combat_manual
	self.listData = idler.new(true)

	local operationItem = function(item1, k, v)
		item1:get("item"):get("bg"):texture("city/card/battle_manuals/title_zdsc1_mlxz.png")
		table.insert(self.itemTab, {k = k, item = item1:get("item"), order = 1})
		self:rightUpdata(k)
		--是否打开分支
		item1:get("list"):removeAllChildren()
		if v.contain and csvSize(v.contain) >= 1 and not item1.select then
			item1:get("list"):show()
			item1:get("item"):get("icon"):rotate(90)
			item1.select = true
			self:pushBackChild(item1, k)
		else
			item1.select = false
			item1:get("item"):get("icon"):rotate(0)
			item1:get("list"):hide()
		end
	end

	self.itemTabs = {}
	self.itemK = false
	idlereasy.when(self.listData, function (_, listData)
		self.itemTab = {}
		self.list:removeAllChildren()
		local num = 0
		for k,v in orderCsvPairs(manuals) do
			if v.catalogType == 1 then
				num = num + 1
				local item1 = self.item:clone():show()
				item1:get("item"):get("name"):text(v.name)
				local order = v.number < 10 and 0 .. v.number or v.number
				item1:get("item"):get("order"):text(order)
				self.list:pushBackCustomItem(item1)
				if self.itemK then
					if k == self.itemK then
						item1:get("item"):get("bg"):texture("city/card/battle_manuals/title_zdsc1_mlxz.png")
						self.itemDataTab = item1:get("item"):get("bg")
					end
				elseif csvSize(self.itemTabs) >= 1 then
					if self.itemTabs[k] then
						item1:get("item"):get("bg"):texture("city/card/battle_manuals/title_zdsc1_mlxz.png")
						item1:get("list"):hide()
						self.itemTabs[k] = k
						self:rightUpdata(k)
						operationItem(item1, k, v)
					end
				else
					if k == 1 then
						item1:get("item"):get("bg"):texture("city/card/battle_manuals/title_zdsc1_mlxz.png")
						item1:get("list"):hide()
						self.itemTabs[k] = k
						self:rightUpdata(k)
						operationItem(item1, k, v)
					end
				end
				if v.content ~= "FALSE" then
					item1:get("item"):get("icon"):visible(v.contain and csvSize(v.contain) >= 1)
					item1:get("item"):onClick(function()
						if v.contain and csvSize(v.contain) >= 1 then
							if not self.itemTabs[k] then
								self.itemTabs = {}
								self.itemTabs[k] = k
								self.itemK = false
								self.itemDataTab = nil
							else
								self.itemTabs = {}
								self.itemK = k
							end
							self.listData:set(true, true)
						else
							self.itemK = false
							if self.itemDataTab then
								self.itemDataTab:texture(url1)
								self.itemDataTab = nil
							end
							table.insert(self.itemTab, {k = k, item = item1:get("item"), order = 1})
							item1:get("item"):get("bg"):texture("city/card/battle_manuals/title_zdsc1_mlxz.png")
							self:rightUpdata(k)
						end
					end)
				end
			end
		end
		local ListX, listY, height
		if self.itemK then
			listY = self.itemK
		elseif csvSize(self.itemTabs) >= 1 then
			ListX, listY = csvNext(self.itemTabs)
		end
		if listY ~= 1 then
			if csvSize(manuals[listY].contain) >= 1 then
				local height1 = (self.item2:size().height * csvSize(manuals[listY].contain) + 116) + (num - 1) * self.item:size().height
				local height2 = listY * self.item:size().height
				height = (height2/height1) * 100
			else
				height = (listY/num) * 100
			end
			self.list:jumpToPercentVertical(height)
		else
			self.list:jumpToPercentVertical(0)
		end
	end)

	self.item:hide()
	self.item2:hide()
	Dialog.onCreate(self)
end
-- 加载子页签
function BattlsManualsView:pushBackChild(node, k)
	local width = self.item2:size().width
	local item = node:get("item")
	local manuals = csv.combat_manual
	local height = self.item2:size().height * csvSize(manuals[k].contain)
	node:height(height + 116)
	node:get("list"):size(width,height)
	node:get("list"):anchorPoint(cc.p(0, 1))
	node:get("list"):y(height)
	item:y(height + 116/2)

	for _, id in ipairs(manuals[k].contain) do
		local data = manuals[id]
		local item2 = self.item2:clone():show()
		item2:get("name"):text(data.name)
		node:get("list"):pushBackCustomItem(item2)
		if data.content ~= "FALSE" then
			item2:onClick(function()
				item2:get("bg"):texture("city/card/battle_manuals/title_zdsc2_xz.png")
				table.insert(self.itemTab, {k = id, item = item2, order = 2})
				self:rightUpdata(id)
			end)
		end
	end
end

--刷新右边内容
function BattlsManualsView:rightUpdata(k)
	-- 防止重复点击
	if not self.repetitionClick or self.repetitionClick ~= k then
		self.repetitionClick = k
	elseif self.repetitionClick == k then
		return
	end
	self.rightList:removeAllChildren()
	for i,v in pairs(self.itemTab) do
		if v.k ~= k and v.item then
			local url = v.order == 1 and url1 or url2
			v.item:get("bg"):texture(url)
			self.itemTab[i] = nil
		end
	end
	local manualsData = csv.combat_manual[k]
	self.rightName:text(manualsData.name)
	local color = "#C0x625C61#"
	local list, height = beauty.textScroll({
		list = self.rightList,
		strs = color .. manualsData.content .. color,
		isRich = true,
		fontSize = 40,
		align = "left",
		rightPadding = 80,
	})

	if height > list:size().height then
		local listX, listY = self.rightList:xy()
		local listSize = self.rightList:size()
		self.slider:visible(true)
		local x, y = self.slider:xy()
		local size = self.slider:size()
		self.rightList:setScrollBarEnabled(true)
		self.rightList:setScrollBarColor(cc.c3b(241, 59, 84))
		self.rightList:setScrollBarOpacity(255)
		self.rightList:setScrollBarAutoHideEnabled(false)
		self.rightList:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x,(listSize.height - size.height) / 2 + 15))
		self.rightList:setScrollBarWidth(size.width)
		self.rightList:jumpToPercentVertical(0)
		self.rightList:refreshView()
	else
		self.rightList:setScrollBarEnabled(false)
		self.slider:visible(false)
	end

end

return BattlsManualsView

