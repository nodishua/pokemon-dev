-- @desc 选服界面

-- 每个页签的区服最大数量
local AREA_NUM = 10

local STATUS_ICON = {
	[1] = "login/tag_hot_server.png",
	[2] = "login/tag_new_server.png",
	[3] = "login/tag_maintain_server.png",
}

local CIRCLE_ICON = {
	[1] = "login/logo_red.png",
	[2] = "login/logo_green.png",
	[3] = "login/logo_gray.png",
}
local LoginServerView = class("LoginServerView", Dialog)

LoginServerView.RESOURCE_FILENAME = "login_server.json"
LoginServerView.RESOURCE_BINDING = {
	["title"] = "title",
	["subTitle"] = "subTitle",
	["leftItem"] = "leftItem",
	["chooseText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.RED}}
		}
	},
	["leftPanel"] = "leftPanel",
	["leftPanel.leftList"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("areaList"),
				item = bindHelper.self("leftItem"),
				asyncPreload = 8,
				padding = 10,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
						text.addEffect(panel:get("name"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					else
						selected:hide()
						panel = normal:show()
					end
					local name = panel:get("name")
					if v.isMyServer then
						name:setFontSize(v.isMyServer and 50 or 40)
						name:text(gLanguageCsv.myServer)
					else
						local channelName = SERVER_MAP[v.tag] and SERVER_MAP[v.tag].name or ""
						name:setFontSize(40)
						name:text(string.format("%s %d-%d %s", channelName, v.leftIdx, v.leftIdx + v.count - 1, gLanguageCsv.serverArea))
					end
					bind.click(list, node, {method = functools.partial(list.clickCell, k)})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onChooseArea")
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["subList"] = "subList",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("serverList"),
				columnSize = 2,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				asyncPreload = 12,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					-- 根据服务器传过来的数据区别化显示区服信息
					local server = v.server
					local userData = v.userData
					node:get("tag"):texture(STATUS_ICON[server.status])
					node:get("circle"):texture(CIRCLE_ICON[server.status])
					if matchLanguage({"kr"}) then
						node:get("name"):text(string.format("%s-%s", getServerArea(server.key, nil, true), getServerName(server.key, true)))
					else
						node:get("name"):text(string.format("%s\n%s", getServerArea(server.key, nil, true), getServerName(server.key, true)))
					end
					if userData then
						node:get("tag"):visible(false)
						bind.extend(list, node, {
							event = "extend",
							class = "role_logo",
							props = {
								logoId = userData.logo,
								frameId = userData.frame,
								level = math.max(userData.level, 1),
								vip = userData.vip,
								onNode = function(panel)
									panel:xy(680, node:height()/2)
										:scale(0.75)
										:z(6)
									panel:get("vip"):xy(160, 20)
								end,
							}
						})
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onChooseServer"),
			},
		},
	},
	["topPanel"] = {
		varname = "topPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChooseDefaultServer")}
		},
	},
	["bottomPanel"] = "bottomPanel",
	["hideIcon"] = {
		varname = "hideIcon",
		binds = {
			event = "click",
			method = bindHelper.self("onCheckBox")
		},
	},
	["hideTip"] = {
		varname = "hideTip",
		binds = {
			event = "click",
			method = bindHelper.self("onCheckBox")
		},
	},
}

-- show current serverInfo
function LoginServerView:onCreate(servers)
	adapt.oneLinePos(self.title, self.subTitle, cc.p(4, 0))
	self.listOriginY = self.list:y()
	self.servers = servers
	self:initModel()

	self:initData()
	self.serverList = idlereasy.new()
	self.showTab = idler.new(1)
	self.showTab:addListener(function(val, oldval, idler)
		self.areaList:atproxy(oldval).select = false
		self.areaList:atproxy(val).select = true
		self:resetList(val)
		self.serverList:set(self:getServerData(val))
	end)
	uiEasy.addTabListClipping(self.leftList, self.leftPanel, {mask = "common/box/box_xzfwq.png", rect = cc.rect(187, 60, 1, 1), offsetX = 12})
	Dialog.onCreate(self)
end

function LoginServerView:initModel()
	self.roleInfos = gGameModel.account:read("role_infos")
end

function LoginServerView:onChooseArea(list, k)
	self.showTab:set(k)
end

function LoginServerView:onChooseServer(list, data)
	self.setServerInfo(data.server)
	-- 点击之后修改选择服务器,显示和数据同时修改,idler绑定之后实现监听
	self:onClose()
end

function LoginServerView:onChooseDefaultServer()
	if self.lastChooseServer then
		self:onChooseServer(nil, {server = self.lastChooseServer})
	end
end

function LoginServerView:initData()
	local data = userDefault.getForeverLocalKey("hideLevelStatus", false, {rawKey = true})
	self.checkStatusVisible = data ~= false
	userDefault.setForeverLocalKey("hideLevelStatus", self.checkStatusVisible, {rawKey = true})
	self.hideIcon:texture(self.checkStatusVisible and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")

	self.topPanel:hide()
	self.lastChooseServer = nil

	local serverKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	if serverKey then
		itertools.first(self.servers, function(v)
			if v.key == serverKey then
				self.lastChooseServer = v
				self.topPanel:get("img.circle"):texture(CIRCLE_ICON[v.status])
				local name = string.format("%s %s", getServerArea(v.key, nil, true), getServerName(v.key, true))
				name = string.format(gLanguageCsv.brackets, name)
				if self:getRoleInfo(self.roleInfos[v.key]) then
					name = name .. " " .. self.roleInfos[v.key].name
				end
				self.topPanel:get("name"):text(name)
				adapt.oneLinePos(self.topPanel:get("name"), self.topPanel:get("img"), nil, "right")
				self.topPanel:show()
				return true
			end
		end)
	end
	local areaList = {}

	for i,v in ipairs(self.servers) do
		if self:getRoleInfo(self.roleInfos[v.key]) then
			table.insert(areaList, {
				isMyServer = true,
			})
			break
		end
	end
	local tmp = {}
	local leftId = 1 -- servers id
	local leftIdx = 1 -- show idx
	local maxId = #self.servers
	local lastTag
	while leftId <= maxId do
		local tag1 = getServerTag(self.servers[leftId].key)
		local count = 1
		for idx = math.min(AREA_NUM-1, maxId - leftId), 1, -1 do
			local tag2 = getServerTag(self.servers[leftId+idx].key)
			if SERVER_MAP[tag1] == SERVER_MAP[tag2] then
				count = idx + 1
				break
			end
		end
		if tag1 ~= lastTag then
			lastTag = tag1
			leftIdx = 1
		end
		table.insert(tmp, {
			count = count,
			leftId = leftId,
			leftIdx = leftIdx,
			tag = tag1,
			server = self.servers[leftId],
		})
		leftId = leftId + count
		leftIdx = leftIdx + count
	end
	for i = #tmp, 1, -1 do
		table.insert(areaList, tmp[i])
	end
	self.areaList = idlers.newWithMap(areaList)
end

function LoginServerView:onCheckBox()
	self.checkStatusVisible = not self.checkStatusVisible
	local t = {}
	userDefault.setForeverLocalKey("hideLevelStatus", self.checkStatusVisible, {rawKey = true})
	self.hideIcon:texture(self.checkStatusVisible and "common/icon/radio_selected.png" or "common/icon/radio_normal.png")
	self.serverList:set(self:getServerData(self.showTab:read()))
end

function LoginServerView:getRoleInfo(data)
	-- if itertools.isempty(data) then
	-- 	return
	-- end
	-- -- 不显示角色等级为0的
	-- if data.level == 0 then
	-- 	return
	-- end
	return data
end

function LoginServerView:resetList(idx)
	local data = self.areaList:atproxy(idx)
	local y = self.listOriginY
	local height = 900
	if not self.lastChooseServer then
		height = height + 140
	end
	if not data.isMyServer then
		y = y + 60
		self.bottomPanel:show()
	else
		height = height + 60
		self.bottomPanel:hide()
	end
	self.list:y(y)
	self.list:height(height)
end

function LoginServerView:getServerData(idx)
	local data = self.areaList:atproxy(idx)
	self.hideIcon:visible(false)
	self.hideTip:visible(false)
	if data.isMyServer then
		self.hideIcon:visible(true)
		self.hideTip:visible(true)
		local t = {}
		for i,v in ipairs(self.servers) do
			if self:getRoleInfo(self.roleInfos[v.key]) then
				if self.checkStatusVisible and self.roleInfos[v.key].level <= 1 then
				else
					table.insert(t, {
						id = i,
						server = v,
						userData = self.roleInfos[v.key],
					})
				end
			end
		end
		table.sort(t, function(a, b)
			if a.userData.level ~= b.userData.level then
				return a.userData.level > b.userData.level
			end
			if a.userData.vip ~= b.userData.vip then
				return a.userData.vip > b.userData.vip
			end
			return a.id < b.id
		end)
		return t
	end
	local t = {}
	for i = data.leftId, data.leftId + data.count - 1 do
		table.insert(t, {
			server = self.servers[i]
		})
		local roleInfo = self.roleInfos[self.servers[i].key]
		if self:getRoleInfo(roleInfo) then
			t[#t].userData = roleInfo
		end
	end
	return t
end

return LoginServerView