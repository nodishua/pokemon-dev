-- @Date:   2021-10-18
-- @Desc:    定制礼包选择物品
local ActivityCustomizeGiftSelectDialog = class("ActivityCustomizeGiftSelectDialog",Dialog)
local function bindIcon(list, node, data, touch)
	bind.extend(list, node , {
		class = "icon_key",
		props = {
			data = data,
			onNode = function(panel)
				panel:setTouchEnabled(touch)
			end
		},
	})
end

ActivityCustomizeGiftSelectDialog.RESOURCE_FILENAME = "activity_customize_gift_select.json"
ActivityCustomizeGiftSelectDialog.RESOURCE_BINDING = {
	["title"] = "title",
	["iconItem"] = "iconItem",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("selectListData"),
				columnSize = bindHelper.self("midColumnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("iconItem"),
				leftPadding =0,
				topPadding = 20,
				xMargin = 20,
				yMargin = 0,
				onCell = function(list, node, k, v)
					local childs = node:multiget("pic", "select")
					childs.select:visible(v.choose)
					bindIcon(list, node:get("pic"), dataEasy.getItemData(v.detail)[1], v.choose)	
					if not v.choose then 
						bind.touch(list, node:get("pic"), {clicksafe = false, methods = {ended = functools.partial(list.clickSelectIcon, v.num, v)}})
					end
				end,
			},		
			handlers = {
				clickSelectIcon = bindHelper.self("clickSelectIcon"),
			},
		}
	},
	["slotIcon"] = "slotIcon",
	["slotList"] ={
		varname = "slotList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("slotListData"),
				item = bindHelper.self("slotIcon"),					
				margin = 30,
				--paddings = 10,
				onItem = function(list, node, k, v)
					local childs = node:multiget("pic", "select", "add")
					childs.select:visible(v.select)
					childs.add:visible(not v.detail)
					if v.detail then 
						bindIcon(list, node:get("pic"), dataEasy.getItemData(v.detail)[1], false)
					end
						bind.touch(list, node:get("pic"), {clicksafe = false, methods = {ended = functools.partial(list.clickSlotIcon, k, v)}})
					end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end,
			},
			handlers = {
				clickSlotIcon = bindHelper.self("clickSlotIcon"),
			},
		}
	},
	["tip1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(239, 97, 97, 255), size = 4}}
		},
	},
	["tip2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(239, 133, 97, 255), size = 4}}
		},
	},
	["btn"] =  {
		varname = "btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("clickSureBtn")}
		},
	},
	["close"] =  {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},

}

function ActivityCustomizeGiftSelectDialog:onCreate(activityId,v, slotNums, selectNum, data, choose)
	self.activityId = activityId
	self:initModel(v, slotNums, selectNum, data, choose)
	Dialog.onCreate(self)
end

function ActivityCustomizeGiftSelectDialog:calcuteSelectState(data)
	local isAllChoose = true
	local zeroOptionNums = 0   --未选择的自选槽数量
	local  zeroOptionNum = 0
	for k,v in ipairs(data) do 
		if v == 0 then
			isAllChoose = false
			zeroOptionNums = zeroOptionNums + 1
			zeroOptionNum = k
		end
	end
	self.selectState = {isAllChoose,zeroOptionNums,zeroOptionNum}
	return isAllChoose,zeroOptionNums,zeroOptionNum
end

function ActivityCustomizeGiftSelectDialog:initModel(v, slotNums, selectNum, data, choose)
	self.midColumnSize = 5
	self.selectPanelData = {}	-- 界面内所有数据
	self.originalSelectPanelChooseData = {}  -- 初始界面选择数据
	self.selectPanelChooseData = idlertable.new({})  -- 以数组方式存储的界面选择数据，不选则设置为0 
	self.selectState = {false,0,0} -- 前者为是否全部选择，后者为未选中的自选槽数量,其中一个为空自选槽

	self.slotListData =  idlertable.new({})	--自选槽list 的数据
	self.selectListData = idlers.new()         -- tableview 需要的数据
	self.chooseIconNum = idler.new(0)          -- 当前自选槽 
	self.chooseSlotNum = idler.new(1)
	self.csvId = v.csvId
	self:initData(v, data, selectNum, choose)

	self.chooseSlotNum:set(selectNum)   	    --选择可选槽     

	self.chooseIconNum:set(choose)      --选择icon    
	
	idlereasy.when(self.selectPanelChooseData, function(_, selectPanelChooseData)
		local isAllChoose,optionNum,zeroNum = self:calcuteSelectState(selectPanelChooseData)
		local isOnlyNowSelect = optionNum == 1 and zeroNum == self.chooseSlotNum:read()
		self.btn:setTouchEnabled(not isOnlyNowSelect)
		if isOnlyNowSelect then 
			cache.setShader(self.btn, false, "hsl_gray")
			text.deleteEffect(self.btn:get("label"), {"outline"})
			text.addEffect(self.btn:get("label"), {color = cc.c4b(222, 218, 209, 255)})
			cache.setShader(self.btn:get("label"), false, "hsl_gray")
		else
			cache.setShader(self.btn, false, "normal")
			text.addEffect(self.btn:get("label"), {color = ui.COLORS.WHITE,
													outline = {color = cc.c4b(239, 133, 97, 255), size = 4}})
		end

		
		if optionNum > 1 or (optionNum == 1 and zeroNum ~= self.chooseSlotNum:read()) then
			self.btn:get("label"):text(gLanguageCsv.nextOneChoose)
		else 
			self.btn:get("label"):text(gLanguageCsv.chooseLock)
		end

	end)

	self.chooseSlotNum:addListener(function(val, oldval)
		if  (val ~= oldval) and (val > 0) then
			if oldval > 0 then 
				self.slotListData:proxy()[oldval].select = false 
			end
			self.slotListData:proxy()[val].select = true
		end
		self.selectListData:update(self.selectPanelData[val])
		self.chooseIconNum:set(self.selectPanelChooseData:proxy()[val])
	end)

	self.chooseIconNum:addListener(function(val, oldval)
		local slotNum = self.chooseSlotNum:read()
		if  val > 0 then
			if oldval > 0 then
				if self.selectListData:atproxy(oldval) then
					self.selectListData:atproxy(oldval).choose = false
				end
			end
			self.selectListData:atproxy(val).choose = true
			if self.selectPanelData[slotNum][val] then 
				self.slotListData:proxy()[slotNum].detail = self.selectPanelData[slotNum][val].detail
			end
		end
		for k,v in ipairs(self.selectPanelData[slotNum]) do 
			v.choose = k == val 
		end

		self.selectPanelChooseData:proxy()[slotNum] = val
	end)

end

function ActivityCustomizeGiftSelectDialog:initData(v, data, selectNum)
	local selectPanelData = {}
	local selectPanelChooseData = {}
	local slotListData = {}
	local selectListData = {}
	for k, v in ipairs(v.awards) do
		local slotTable = {}
		if  not v.isFixAwards then
			local selectChoose = 0
			for key, value in ipairs(v.showAwards) do
				local choose = false
				if v.choose ~= nil then
					choose = v.choose == key
				end
				if choose then 
					selectChoose = key
				end
				table.insert(slotTable, {
					num = key,
					detail = value,
					choose = choose,	
				})
			end

			table.insert(slotListData, {
				detail = v.showAwards[selectChoose],
				select = selectNum == v.optionSlotNum,
			})
			table.insert(selectPanelChooseData, selectChoose)
			table.insert(selectPanelData, slotTable)
		end
	end

	for k, v in ipairs(data) do
		table.insert(selectListData, {
			num = k,
			detail = v,
			choose = k == choose,
		})
	end

	self.originalSelectPanelChooseData = table.deepcopy(selectPanelChooseData,true)
	self.selectPanelChooseData:set(selectPanelChooseData)
	self.selectPanelData = selectPanelData
	self.slotListData:set(slotListData)
	self.selectListData:update(selectListData)
end

function ActivityCustomizeGiftSelectDialog:findNextZeroValue()
	for k, v in self.selectPanelChooseData:ipairs() do 
		if k > self.chooseSlotNum:read() and v == 0 then
			return k
		end
	end
	for k, v in self.selectPanelChooseData:ipairs() do 
		if v == 0 then
			return k
		end
	end
end

function ActivityCustomizeGiftSelectDialog:clickSureBtn()
	if self.selectState[1] then 
		self:onClose()
	end
	
	if self.selectState[2] > 1 or (self.selectState[2] == 1 and self.selectState[3] ~= self.chooseSlotNum:read()) then 
		self.chooseSlotNum:set(self:findNextZeroValue()) 
	end
	
end


function ActivityCustomizeGiftSelectDialog:clickSlotIcon(node, k)
	self.chooseSlotNum:set(k)
end

function ActivityCustomizeGiftSelectDialog:clickSelectIcon(node, k)
	self.chooseIconNum:set(k)
end

function ActivityCustomizeGiftSelectDialog:isDataChange()
	local passData = {}
	local hasChange = false 
	for k, v in self.selectPanelChooseData:ipairs() do 
		if self.originalSelectPanelChooseData[k] ~= v then
			hasChange = true
		end
		passData[k] = v
	end
	return hasChange,passData
end



function ActivityCustomizeGiftSelectDialog:onClose()
	local isDataChange,data = self:isDataChange()

	if not isDataChange then
		Dialog.onClose(self)
		return 
	end
	gGameApp:requestServer("/game/yy/customize/gift", function(tb)
		Dialog.onClose(self)
	end, self.activityId, self.csvId, data)
end



return ActivityCustomizeGiftSelectDialog