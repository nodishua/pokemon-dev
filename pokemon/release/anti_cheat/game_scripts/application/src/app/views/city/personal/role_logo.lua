

local function setSelectState(val, oldval, data, selectIndex)
	for i, datas in data:ipairs() do
		local logoData = datas:proxy()
		if logoData.csvId == oldval then
			logoData.inUse = false
		end
		if logoData.csvId == val then
			logoData.inUse = true
			selectIndex:set(i)
		end
	end
end
local function setLogoFrame(list, node, logoId, frameId, scale)
	local props = {
		event = "extend",
		class = "role_logo",
		props = {
			logoId = logoId,
			level = false,
			vip = false,
			frameId = frameId,
			onNode = function(node)
				node:scale(scale or 1):z(3)
			end,
		}
	}
	bind.extend(list, node, props)
end

local function createRichTxt(str, x, y, parent)
	return rich.createWithWidth(str, 40, nil, 480)
		:anchorPoint(0.5, 0.5)
		:xy(x, y)
		:addTo(parent, 6)
end
local function getSortData(data)
	table.sort(data,function(a,b)
		if a.unlocked ~= b.unlocked then
			return a.unlocked < b.unlocked
		end
		return a.csvId < b.csvId
	end)
	return data
end
local PersonalRoleLogoView = class("PersonalRoleLogoView", Dialog)

PersonalRoleLogoView.RESOURCE_FILENAME = "personal_role_logo.json"
PersonalRoleLogoView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSaveClose")}
		}
	},
	["leftItem"] = "leftItem",
	["leftList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
						panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					else
						selected:hide()
						panel = normal:show()
					end
					local maxHeight = panel:getSize().height - 40
					adapt.setAutoText(panel:get("txt"),v.name, maxHeight)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftButtonClick"),
			},
		}
	},
	["title2"] = "logoTitle",
	["title3"] = "frameTitle",
	["subList1"] = "subList1",
	["subList2"] = "subList2",
	["itemLogo"] = "itemLogo",
	["itemFrame"] = "itemFrame",
	["logoPanel"] = "logoPanel",
	["logoList"] = {
		varname = "logoList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("logoData"),
				columnSize = 5,
				item = bindHelper.self("subList1"),
				cell = bindHelper.self("itemLogo"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					node:get("locked"):visible(v.unlocked == 2)
					node:get("used"):visible(v.inUse)
					node:get("selected"):visible(v.selectEffect or false)
					setLogoFrame(list, node, v.csvId, false, 1.1)
					bind.click(list, node, {method = functools.partial(list.itemClick, list:getIdx(k), v)})
				end,
				asyncPreload = 25,
			},
			handlers = {
				itemClick = bindHelper.self("onLogoItemClick"),
			},
		},
	},
	["frameList"] = {
		varname = "frameList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("frameData"),
				columnSize = 4,
				-- leftPadding = 10,
				-- topPadding = 10,
				item = bindHelper.self("subList2"),
				cell = bindHelper.self("itemFrame"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					node:get("locked"):visible(v.unlocked == 2)
					node:get("used"):visible(v.inUse)
					node:get("selected"):visible(v.selectEffect or false)
					setLogoFrame(list, node, false, v.csvId)
					bind.click(list, node, {method = functools.partial(list.itemClick, list:getIdx(k), v)})
				end,
				asyncPreload = 20,
			},
			handlers = {
				itemClick = bindHelper.self("onFrameItemClick"),
			},
		},
	},
	["name"] = "nodeName",
	["btnSave"] = {
		varname = "btnSave",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSaveClick")}
		}
	},
	["btnSave.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["title"] = "title",
	["title1"] = "title1",
	["condition"] = "condition",
}

function PersonalRoleLogoView:onCreate(cb)
	self.cb = cb
	self:initModel()
	self.leftDatas = idlers.newWithMap({
		{name = gLanguageCsv.roleLogo},
		{name = gLanguageCsv.roleLogoFrame},
	})
	self.selectFrame = idler.new(self.frame:read())
	self.selectLogo = idler.new(self.logo:read())
	self.csvIdLogo = idler.new(self.logo:read())
	self.csvIdFrame = idler.new(self.frame:read())
	self.showTab = idler.new(1)
	self.showTab:addListener(function(val, oldval, idler)
		self.leftDatas:atproxy(oldval).select = false
		self.leftDatas:atproxy(val).select = true
		if val == 1 then
			itertools.invoke({self.logoTitle, self.logoList}, "show")
			itertools.invoke({self.frameTitle, self.frameList}, "hide")
			self.title1:text(gLanguageCsv.roleLogo)
			self.selectLogo:set(self.selectLogo:read(), true)
		else
			itertools.invoke({self.logoTitle, self.logoList}, "hide")
			itertools.invoke({self.frameTitle, self.frameList}, "show")
			self.title1:text(gLanguageCsv.roleLogoFrame)
			self.selectFrame:set(self.selectFrame:read(), true)
		end
		adapt.oneLinePos(self.title,self.title1, cc.p(10,0),"left")
	end)
	self.logoData = idlers.new()
	idlereasy.when(self.activeLogos, function(_, activeLogos)
		local tmpData = {}
		for k,v in pairs(gRoleLogoCsv) do
			local inUse = (self.logo:read() == k)
			local unlocked = activeLogos[k] and 1 or 2
			table.insert(tmpData,{csvId = k, inUse = inUse, unlocked = unlocked, cfg = v})
		end
		self.logoData:update(getSortData(tmpData))
	end)

	self.frameData = idlers.new()
	idlereasy.when(self.frames, function(_, frames)
		local tmpData = {}
		for k,v in pairs(gRoleFrameCsv) do
			local inUse = (self.frame:read() == k)
			local unlocked = frames[k] and 1 or 2
			table.insert(tmpData,{csvId = k, inUse = inUse, unlocked = unlocked, cfg = v})
		end
		self.frameData:update(getSortData(tmpData))
	end)
	self.logo:addListener(function(val, oldval)
		setSelectState(val, oldval, self.logoData, self.selectLogo)
	end)

	self.frame:addListener(function(val, oldval)
		setSelectState(val, oldval, self.frameData, self.selectFrame)
	end)

	self.selectFrame:addListener(function(val, oldval)
		self:setRightPanel(val, oldval, self.frameData)
	end)

	self.selectLogo:addListener(function(val, oldval)
		self:setRightPanel(val, oldval, self.logoData)
	end)

	Dialog.onCreate(self)
end

function PersonalRoleLogoView:initModel()
	self.logo = gGameModel.role:getIdler("logo")
	self.logos = gGameModel.role:getIdler("logos")
	self.figures = gGameModel.role:getIdler("figures")
	self.frame = gGameModel.role:getIdler("frame")
	self.frames = gGameModel.role:getIdler("frames")
	self.pokedex = gGameModel.role:getIdler("pokedex")
	self.activeLogos = gGameModel.role:getIdler("active_logos")
end
--设置右侧面板selectData.cfg.unlockDesc or
function PersonalRoleLogoView:setRightPanel(val, oldval, data)
	local selectData = data:atproxy(val)
	self.condition:removeAllChildren()
	self.condition:text("")
	if selectData.unlocked == 2 then
		local str = selectData.cfg.unlockDesc
		self.condition:text(str)
		if self.condition:size().width > 480 then
			self.condition:text("")
			createRichTxt("#C0x5B545B#" .. str, 0, 0, self.condition)
		end
	end
	self.btnSave:visible(selectData.unlocked == 1)
	self.nodeName:text(selectData.cfg.name)
	if self.showTab:read() == 1 then
		setLogoFrame(self, self.logoPanel, selectData.csvId, self.csvIdFrame:read(), 1.5)
	else
		setLogoFrame(self, self.logoPanel, self.csvIdLogo:read(), selectData.csvId, 1.5)
	end
	local oldSelectData = data:atproxy(oldval)
	if oldSelectData then
		oldSelectData.selectEffect = false
	end
	selectData.selectEffect = true
end
--切换页签
function PersonalRoleLogoView:onLeftButtonClick(list, k)
	self.showTab:set(k)
end

function PersonalRoleLogoView:onFrameItemClick(list, t, v)
	self.selectFrame:set(t.k)
	self.csvIdFrame:set(v.csvId)
end

function PersonalRoleLogoView:onLogoItemClick(list, t, v)
	self.selectLogo:set(t.k)
	self.csvIdLogo:set(v.csvId)
end

function PersonalRoleLogoView:onSaveClick()
	if self.showTab:read() == 1 then
		local logoVal = self.selectLogo:read()
		local logo = self.logoData:atproxy(logoVal)
		if logo.unlocked == 2 then
			gGameUI:showTip(gLanguageCsv.logoNotUnlock)
			return
		end
		local saveData = {}
		if self.logo:read() == logo.csvId then
			gGameUI:showTip(gLanguageCsv.logoHasBeenSaved)
			return
		end
		gGameApp:requestServer("/game/role/logo",function()
			gGameUI:showTip(gLanguageCsv.logoWasSavedSuccessfully)
		end, logo.csvId)
		return
	end
	local frameVal = self.selectFrame:read()
	local frame = self.frameData:atproxy(frameVal)
	if frame.unlocked == 2 then
		gGameUI:showTip(gLanguageCsv.frameNotUnlock)
		return
	end
	if self.frame:read() == frame.csvId then
		gGameUI:showTip(gLanguageCsv.frameHasBeenSaved)
		return
	end
	gGameApp:requestServer("/game/role/frame",function()
		gGameUI:showTip(gLanguageCsv.frameWasSavedSuccessfully)
	end, frame.csvId)
end

function PersonalRoleLogoView:onSaveClose()
	local logoVal = self.selectLogo:read()
	local logo = self.logoData:atproxy(logoVal)
	local frameVal = self.selectFrame:read()
	local frame = self.frameData:atproxy(frameVal)
	local changesHaveLogo = (self.logo:read() ~= logo.csvId and logo.unlocked == 1) -- 头像框有改动
	if changesHaveLogo or (self.frame:read() ~= frame.csvId and frame.unlocked == 1) then
		local content = changesHaveLogo and gLanguageCsv.changesHaveBeenDetectedLogo or gLanguageCsv.changesHaveBeenDetectedFrame
		gGameUI:showDialog({content = content, cb = function()
			self:onClose()
		end, btnType = 2})
		return
	end
	self:onClose()
end

function PersonalRoleLogoView:onChangeClick(typ)
	self.selectPage:set(typ)
end

return PersonalRoleLogoView
