--粽子快速制作

local ViewBase = cc.load("mvc").ViewBase
local SpeedFabricationView = class("SpeedFabricationView", ViewBase)

local calculateItemFunc = function(list, node, k, v)
	local num = math.min(v.num1, v.num2)
	if num == 0 then
		node:get("add"):setTouchEnabled(false)
		node:get("sub"):setTouchEnabled(false)
		cache.setShader(node:get("add"), false, "hsl_gray")
		cache.setShader(node:get("sub"), false, "hsl_gray")
	end
	node:get("sub"):setTouchEnabled(v.number > 0)
	cache.setShader(node:get("sub"), false, v.number > 0 and "normal" or "hsl_gray")

	node:get("add"):onTouch(functools.partial(list.itemAddClick, node, v))
	node:get("sub"):onTouch(functools.partial(list.itemSubClick, node, v))
	node:get("select"):onTouch(functools.partial(list.itemClick, node, k, v))
end

SpeedFabricationView.RESOURCE_FILENAME = "activity_duanwu_fabrication.json"
SpeedFabricationView.RESOURCE_BINDING = {
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				asyncPreload = 9,
				columnSize = 3,
				data = bindHelper.self('showData'),
				item = bindHelper.self('subList'),
				cell = bindHelper.self('item'),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					node:get("name"):text(v.name)
					node:get("describe"):text(v.desc)
					node:get("item1"):texture(v.icon1)
					node:get("item2"):texture(v.icon2)
					node:get("select.select.icon"):visible(v.itemSelect)
					node:get("select.num"):text(v.number)
					bind.extend(list, node:get("icon"), {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
							},
						}
					})
					calculateItemFunc(list, node:get("select"), k, v)
				end
			},
			handlers = {
				itemClick = bindHelper.self('onItemClick'),
				itemAddClick = bindHelper.self('onItemAddClick'),
				itemSubClick = bindHelper.self('onItemSubClick'),
			}
		}
	},
	["btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnClick")}
		},
	},
	["down"] = "down",
	["panel"] = "panel",
}

function SpeedFabricationView:onCreate(activityID, cb)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.speedabrication, subTitle = "ACTIVITY"})

	local animaBg = widget.addAnimation(self.panel, "duanwuzongzi/dwj_bzz.skel", "effect_loop", 1)
		:alignCenter(self.panel:size())
		:scale(2)
	self.zongziData = {}
	self.zongziTab = {}
	self:enableSchedule()
	local huodongID = csv.yunying.yyhuodong[activityID].huodongID
	for i,v in orderCsvPairs(csv.yunying.bao_zongzi_recipe) do
		if v.huodongID == huodongID then
			local itemZ, _ = csvNext(v.mainItem)
			local itemF, _ = csvNext(v.minorItem)
			if not self.zongziTab[itemZ] then
				self.zongziTab[itemZ] = {}
			end
			self.zongziTab[itemZ][itemF] = 0
		end
	end

	self.cb = cb
	local stapleData = {6352, 6353, 6354} 		--主食材itemID
	local nonStapleData = {6355, 6356, 6357}	--副食材itemID
	self.item:visible(false)
	self.activityID = activityID
	self.select = idler.new(false)
	self.showData = idlers.newWithMap({})
	local items = csv.items
	self.itemSelectZ = {}
	self.itemSelectF = {}
	for i=1, 3 do
		self.down:get("icon" .. i):texture(items[stapleData[i]].icon)
		self.down:get("item" .. i):texture(items[nonStapleData[i]].icon)
		text.addEffect(self.down:get("icon" .. i):get("num"), {outline={color=cc.c4b(124, 117, 129, 255)}})
		text.addEffect(self.down:get("item" .. i):get("num"), {outline={color=cc.c4b(124, 117, 129, 255)}})
		self.itemSelectZ[stapleData[i]] = 0
		self.itemSelectF[nonStapleData[i]] = 0
	end
	self.itemDuanwuData = {{},{},{},{},{},{},{},{},{}}
	local textRed = cc.c4b(255, 79, 100, 255)
	idlereasy.any({gGameModel.role:getIdler("items"), self.select}, function(_, itemsData)
		local showDatas = {}
		for i=1, 3 do
			local num1, num2 = 0, 0
			if itemsData[stapleData[i]] then
				num1 = itemsData[stapleData[i]] - self.itemSelectZ[stapleData[i]]
			end
			if itemsData[nonStapleData[i]] then
				num2 = itemsData[nonStapleData[i]] - self.itemSelectF[nonStapleData[i]]
			end
			self.down:get("icon" .. i):get("num"):text(num1)
			self.down:get("icon" .. i):get("num"):color(num1 >=1 and ui.COLORS.NORMAL.WHITE or textRed)
			self.down:get("item" .. i):get("num"):text(num2)
			self.down:get("item" .. i):get("num"):color(num2 >=1 and ui.COLORS.NORMAL.WHITE or textRed)
		end

		for k,v in orderCsvPairs(csv.yunying.bao_zongzi_recipe) do
			if v.huodongID == huodongID then
				local itemIdZ, _ = csvNext(v.mainItem)
				local itemIdF, _ = csvNext(v.minorItem)
				local itemNumZ, itemNumF = itemsData[itemIdZ] or 0, itemsData[itemIdF] or 0
				local itemIconZ = items[itemIdZ].icon
				local itemIconF = items[itemIdF].icon
				local itemId, _ = csvNext(v.compoundItem)
				local name, desc = items[itemId].name, v.desc
				local itemSelect = self.itemDuanwuData[k] and self.itemDuanwuData[k].itemSelect or false
				local number = self.itemDuanwuData[k] and self.itemDuanwuData[k].number or 0
				local itemData = {
					csvId = k,
					icon1 = itemIconZ,
					icon2 = itemIconF,
					id1 = itemIdZ,
					id2 = itemIdF,
					key = itemId,
					name = name,
					num1 = itemNumZ,
					num2 = itemNumF,
					desc = desc,
					number = number,
					itemSelect = itemSelect,
				}
				table.insert(showDatas, itemData)
				self.itemDuanwuData[k] = itemData
			end
		end
		self.showData:update(showDatas)
	end)
end

--是否勾选
function SpeedFabricationView:onItemClick(list, node, k, v, event)
	if event.name == "ended" or event.name == "cancelled" then
		local num = math.min(v.num1, v.num2)
		if num == 0 then
			local str
			if v.num1 == 0 and v.num2 == 0 then
				str = csv.items[v.id1].name .. "," .. csv.items[v.id2].name
			elseif v.num1 == 0 then
				str = csv.items[v.id1].name
			else
				str = csv.items[v.id2].name
			end
			gGameUI:showTip(string.format(gLanguageCsv.ingredientInsufficient, str))
			return
		elseif v.number == 0 then
			gGameUI:showTip(gLanguageCsv.selectMaterials)
			return
		else
			if self.zongziData[v.csvId] then
				node:get("select.icon"):visible(false)
				self.zongziData[v.csvId] = nil
				self.itemDuanwuData[v.csvId].itemSelect = false
			else
				node:get("select.icon"):visible(true)
				self.zongziData[v.csvId] = self.zongziTab[v.id1][v.id2]
				self.itemDuanwuData[v.csvId].itemSelect = true
			end
		end
	end
end

function SpeedFabricationView:addItemFunc(node, v, event)
	if event.name == "began" then
		if self.itemSelectZ[v.id1] >= v.num1 and self.itemSelectF[v.id2] >= v.num2 then
			local str = csv.items[v.id1].name .. "," .. csv.items[v.id2].name
			gGameUI:showTip(string.format(gLanguageCsv.ingredientInsufficient, str))
			return
		end
		if self.itemSelectZ[v.id1] >= v.num1 then
			local str = csv.items[v.id1].name
			gGameUI:showTip(string.format(gLanguageCsv.ingredientInsufficient, str))
			return
		end
		if self.itemSelectF[v.id2] >= v.num2 then
			local str = csv.items[v.id2].name
			gGameUI:showTip(string.format(gLanguageCsv.ingredientInsufficient, str))
			return
		end
		local num = math.min(v.num1 - self.itemSelectZ[v.id1], v.num2 - self.itemSelectF[v.id2])
		if 1 <= num then
			self.itemSelectZ[v.id1] = self.itemSelectZ[v.id1] + 1
			self.itemSelectF[v.id2] = self.itemSelectF[v.id2] + 1
			self.zongziTab[v.id1][v.id2] = self.zongziTab[v.id1][v.id2] + 1
			self.itemDuanwuData[v.csvId].number = self.zongziTab[v.id1][v.id2]
			v.number = self.zongziTab[v.id1][v.id2]
			node:get("num"):text(self.zongziTab[v.id1][v.id2])
			if self.itemDuanwuData[v.csvId].number >= 1 and not self.zongziData[v.csvId] then
				node:get("select"):get("icon"):visible(true)
				self.zongziData[v.csvId] = self.zongziTab[v.id1][v.id2]
				self.itemDuanwuData[v.csvId].itemSelect = true
			end
			if self.zongziData[v.csvId] then
				self.zongziData[v.csvId] = self.zongziTab[v.id1][v.id2]
			end
		end
	elseif event.name == "ended" or event.name == "cancelled" then
		self.select:set(true, true)
	end
end

function SpeedFabricationView:onItemAddClick(list, node, v, event)
	if event.name == "click" then
		self:unScheduleAll()
		self:addItemFunc(node, v, event)
	elseif event.name == "began" then
		self:schedule(function()
			self:addItemFunc(node, v, event)
		end, 0.1, 0, 1)
	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
		self:addItemFunc(node, v, event)
	end
end


function SpeedFabricationView:subItemFunc(node, v, event)
	if event.name == "began" then
		if v.number == 1 then
			if self.zongziData[v.csvId] then
				node:get("select.icon"):visible(false)
				self.zongziData[v.csvId] = nil
				self.itemDuanwuData[v.csvId].itemSelect = false
			end
		elseif v.number == 0 then
			return
		end
		self.itemSelectZ[v.id1] = self.itemSelectZ[v.id1] - 1
		self.itemSelectF[v.id2] = self.itemSelectF[v.id2] - 1
		self.zongziTab[v.id1][v.id2] = self.zongziTab[v.id1][v.id2] - 1
		self.itemDuanwuData[v.csvId].number = self.zongziTab[v.id1][v.id2]
		node:get("num"):text(self.zongziTab[v.id1][v.id2])
		v.number = self.zongziTab[v.id1][v.id2]
		if self.zongziData[v.csvId] then
			self.zongziData[v.csvId] = self.zongziTab[v.id1][v.id2]
		end
	elseif event.name == "ended" or event.name == "cancelled" then
		self.select:set(true, true)
	end
end

function SpeedFabricationView:onItemSubClick(list, node, v, event)
	if event.name == "click" then
		self:unScheduleAll()
		self:subItemFunc(node, v, event)
	elseif event.name == "began" then
		self:schedule(function()
			self:subItemFunc(node, v, event)
		end, 0.1, 0, 1)
	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
		self:subItemFunc(node, v, event)
	end
end

--制作
function SpeedFabricationView:btnClick()
	if csvSize(self.zongziData) == 0 then
		gGameUI:showTip(gLanguageCsv.noSelectZongZi)
		return
	end
	if self.cb then
		self.cb("speedMake", self.zongziData)
		self.zongziData = {}
		self.zongziTab = {}
	end
end

return SpeedFabricationView