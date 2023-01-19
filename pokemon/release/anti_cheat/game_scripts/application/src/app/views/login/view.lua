-- @desc 登录界面

-- 线上渠道帐号
local ONLINE_USER_NAME = dev.ONLINE_USER_NAME

if dev.LOGIN_ACCOUNT then
	userDefault.setForeverLocalKey("account", dev.LOGIN_ACCOUNT, {rawKey = true})
end
if dev.LOGIN_SERVER_KEY then
	userDefault.setForeverLocalKey("serverKey", dev.LOGIN_SERVER_KEY, {rawKey = true})
end

require "battle.app_views.battle.battle_entrance.include"

local LoginView = class("LoginView", cc.load("mvc").ViewBase)
local halloweenMessages = require("app.views.city.halloween_messages"):getInstance()

LoginView.RESOURCE_FILENAME = "login.json"
LoginView.RESOURCE_BINDING = {
	["leftPanel"] = "leftPanel",
	["leftPanel.btnProtocol"] = "btnProtocol",
	["leftPanel.btnUser"] = "btnUser",
	["leftPanel.btnNotice"] = {
		varname = "btnNotice",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlacardClick")},
		},
	},
	["leftPanel.btnNotice.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["midPanel.btnLogin"] = {
		varname = "btnLogin",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("onLoginClick")},
		},
	},
	["midPanel.server"] = {
		varname = "loginServer",
		binds = {
			event = "click",
			method = bindHelper.self("onChooseServer"),
		},
	},
	["midPanel.server.chooseServer"] = {
		varname = "chooseServer",
		binds = {
			event = "click",
			method = bindHelper.self("onChooseServer"),
		},
	},
	["midPanel.server.status"] = {
		varname = "statusColor",
		binds = {
			event = "text",
			idler = bindHelper.self("serverStatus"),
		},
	},
	["midPanel.server.currServer"] = "currentServer",
	["midPanel.server.bg"] = "serverBg",
	["version"] = {
		binds = {
			{
				event = "text",
				data = APP_VERSION,
			}, {
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
			},
		},
	}
}

local input = {}
input.RESOURCE_FILENAME = "login_input.json"
input.RESOURCE_BINDING = {
	account = "account",
	txtAccount = "txtAccount",
}

local STATUS = {
	[1] = gLanguageCsv.hot,
	[2] = gLanguageCsv.fluency,
	[3] = gLanguageCsv.preserve,
}

local STATUSCOLOR = {
	[1] = ui.COLORS.NORMAL.RED,
	[2] = cc.c4b(107, 201, 145, 255),
	[3] = cc.c4b(187, 187, 187, 255),
}

function LoginView:onCreate()
	self.userName = nil

	-- TODO 玩家版本暂时隐藏
	self.btnUser:hide()
	self.btnProtocol:hide()

	-- login spine 背景
	local loginSpine = "login/login.skel"
	local isOpen, res = dataEasy.isDisplayReplaceHuodong("loginSpine")
	if isOpen then
		loginSpine = res
	end
	-- QQ登录界面特殊处理
	if APP_TAG:find("_qq") then
		local effect = cc.Sprite:create("login/qq_bg.png")
		effect:setScale(2)
		effect:setPosition(cc.p(display.sizeInView.width/2, display.sizeInView.height/2))
		self:getResourceNode():addChild(effect, 0)
	else
		widget.addAnimation(self:getResourceNode(), loginSpine, "effect_loop", 0)
			:scale(2)
			:xy(display.sizeInView.width/2, display.sizeInView.height/2)
			:name("loginSpine")
	end

	self.serverStatus = idler.new("serverStatus")
	self.currentServer:text("currentServer")
	if (APP_CHANNEL =="none" or APP_CHANNEL =="luo") then
		local pos = gGameUI:getConvertPos(self.loginServer)
		self.inputWidget = gGameUI:createSimpleView(input, self):init()
		local size = self.inputWidget:getResourceNode():size()
		self.inputWidget:xy(pos.x - size.width/2, pos.y - size.height/2)
		local account = userDefault.getForeverLocalKey("account", "", {rawKey = true})
		self.inputWidget.txtAccount:setText(account)
		self.inputWidget.txtAccount:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)

		if dev.ONLINE_VERSION_LANGUAGE and ONLINE_USER_NAME then
			self.inputWidget.txtAccount:setString(ONLINE_USER_NAME)
		end

		adapt.oneLinePos(self.inputWidget.account, self.inputWidget.txtAccount, cc.p(15, 0))
	end

	if not dev.IGNORE_POPUP_BOX then
		local currTime = os.date("%Y%m%d", os.time())
		local data = userDefault.getForeverLocalKey("placardStatusDay", {}, {rawKey = true, rawData = true})
		-- 配置list管理打开的界面
		local list = {
			{
				key = data[currTime],
				cb = function(f)
					self:showPlacard()
				end
			}
		}
		-- 腾讯隐私政策和用户协议
		if APP_TAG:find("_qq") then
			local protocolSign = userDefault.getForeverLocalKey("protocalStatusSign", false, {rawKey = true, rawData = true})
			table.insert(list, 1, {
				key = protocolSign,
				cb = function(f)
					gGameUI:stackUI("login.protocol",{cb = f})
				end
			})
		end
		self:managerOpenView(list, 1)
	end

	audio.playMusic("login.mp3")

	userDefault.setForeverLocalKey("posterLoginShow", false, {rawKey = true})

	sdk.trackEvent(2)

	self:additionForCN()
	self:additionForKR()
	self:additionForEN()

	halloweenMessages:clear()

	self:testInLogin()
end

function LoginView:createSupportLabel(parent, text, fontSize, onClick)
	local lbl = label.create(text, {
		fontPath = "font/youmi1.ttf",
		fontSize = fontSize,
		color = ui.COLORS.NORMAL.WHITE,
		pos = cc.p(parent:getContentSize().width/2, -20),
		effect = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
	}):addTo(parent)
	bind.touch(self, parent, {methods = {ended = onClick}})
	return lbl
end

function LoginView:additionForCN()
	if not checkLanguage("cn") then
		return
	end

	local startPos = cc.p(self.btnNotice:getPosition())
	startPos.x = startPos.x + 130
	startPos.y = startPos.y - 20
	local btn = cc.Sprite:create("login/icon_cadpa.png")
		:setPosition(startPos)
		:addTo(self.leftPanel)
end

function LoginView:additionForKR()
	if not matchLanguage({"kr"}) then
		return
	end

	local btnInfo = {
		[1] = {
			name = "개인정보",
			resPath = "login/icon_grqb.png",
		},
		[2] = {
			name = "운영정책",
			resPath = "login/icon_yyzc.png",
		},
		[3] = {
			name = "이용약관",
			resPath = "login/icon_yhxy.png",
		},
		[4] = {
			name = "고객센터",
			resPath = "login/icon_kfzx.png",
		},
	}
	local rightPanel = ccui.Layout:create()
		:setAnchorPoint(cc.p(1, 1))
		:setPosition(cc.p(display.sizeInView.width, display.sizeInView.height))
		:size(cc.size(200,600))
		:addTo(self:getResourceNode())
	adapt.dockWithScreen(rightPanel, "left", "up")

	local btn = ccui.Button:create(btnInfo[4].resPath)
		:setPosition(cc.p(self.btnProtocol:getPosition()))
		:addTo(self.leftPanel)
		:scale(0.9)
	self:createSupportLabel(btn, btnInfo[4].name, 32, functools.partial(self.onAdditionBtnClick, self, 4))

	for i = 1, 3 do
		btn = ccui.Button:create(btnInfo[i].resPath)
			:setPosition(cc.p(100, i * 170))
			:addTo(rightPanel)
			:scale(0.9)
		self:createSupportLabel(btn, btnInfo[i].name, 32, functools.partial(self.onAdditionBtnClick, self, i))
	end
end

function LoginView:additionForEN()
	if not matchLanguage({"en"}) then
		return
	end

	local btn
	local startPos = cc.p(self.btnProtocol:getPosition())
	btn = ccui.Button:create("login/icon_kfzx.png")
		:setPosition(startPos)
		:addTo(self.leftPanel)
		:scale(0.83)
	self:createSupportLabel(btn, "Support", 38, functools.partial(self.onAdditionBtnClick, self, 4))

	startPos.y = startPos.y - 160
	btn = ccui.Button:create("login/icon_discord.png")
		:setPosition(startPos)
		:addTo(self.leftPanel)
		:scale(0.83)
	self:createSupportLabel(btn, "Discord", 38, functools.partial(self.onAdditionBtnClick, self, 5))
end

function LoginView:onAdditionBtnClick(tag)
	if matchLanguage({"kr"}) then
		if tag == 1 then
			-- 个人情报
			sdk.commitRoleInfo(51,function()
				print("sdk commitRoleInfo self infomation")
			end)
		elseif tag == 2 then
			-- 运营政策
			sdk.commitRoleInfo(52,function()
				print("sdk commitRoleInfo policy")
			end)
		elseif tag == 3 then
			-- 用户协议
			sdk.commitRoleInfo(53,function()
				print("sdk commitRoleInfo user protocol")
			end)
		elseif tag == 4 then
			-- 客服中心
			sdk.commitRoleInfo(54,function()
				print("sdk commitRoleInfo customerService")
			end)
		end
	elseif matchLanguage({"en"}) then
		if tag == 4 then
			cc.Application:getInstance():openURL(SUPPORT_URL)
		elseif tag == 5 then
			cc.Application:getInstance():openURL(DISCORD_URL)
		end
	end
end

-- 测试用
function LoginView:testInLogin()
	if device.platform == "windows" then
		local testInject = require "app.views.login.test"
		testInject(LoginView)

		self:createTestScene()
	end

	if APP_CHANNEL == "none" and false then
		local testInject = require "app.views.login.test"
		testInject(LoginView)

		performWithDelay(self, handler(self, "showBenchmark"), 4)
	end
end

function LoginView:onPlacardClick()
	self:showPlacard()
end

function LoginView:onChooseServer()
	gGameUI:stackUI("login.server", {
		setServerInfo = self:createHandler("setServerInfo"),
	}, nil, self.servers)
end

function LoginView:onLoginClick(node, event)
	if self.serverSelected and self.servers then
		sdk.trackEvent(20)
		local server = self.servers[self.serverSelected]
		print("selected server", self.serverSelected, dumps(server))

		gGameApp:requestServerCustom("/login/enter_server")
			:params(server)
			:onErrCall(function(err)
				if err.servers and #err.servers > 0 then
					self:setServers(err.servers)
				end
				if err.err == "register_disable" then
					local function autoChooseNew()
						local server = self.servers[self:selectServerIdx()]
						self:setServerInfo(server)
						gGameUI:showTip(gLanguageCsv.serverAutoChooseNew .. getServerName(server.key, true))
					end
					gGameUI:showDialog({
						title = gLanguageCsv.tips,
						content = gLanguageCsv.serverRegisterDisable,
						dialogParams = {clickClose = false},
						cb = autoChooseNew,
						closeCb = autoChooseNew,
					})
				else
					gGameUI:showDialog({
						title = gLanguageCsv.tips,
						content = gLanguageCsv[err.err] or err.err,
						dialogParams = {clickClose = false},
					})
				end
			end)
			:doit(function(tb)
				gGameApp:setGameServerAddr(server)
				gGameApp:requestServer("/game/login", function(tb)
					userDefault.setForeverLocalKey("serverKey", self.servers[self.serverSelected].key, {rawKey = true})
					local fps = userDefault.getForeverLocalKey("fps", 60, {rawKey = true})
  					cc.Director:getInstance():setAnimationInterval(1.0 / fps)
					-- -2.特殊隐藏左上角15次跳过引导, -1. 第一次新手战斗, 1. 选形象名字, 2.选初始卡牌
					if gGameUI.guideManager:checkFinished(1) and gGameUI.guideManager:checkFinished(2) then
						-- 2. 去城镇
						sdk.commitRoleInfo(1,function()
							print("sdk commitRoleInfo and go to city")
						end)--进入游戏为1
						gGameUI:switchUI("city.view")
					else
						dataEasy.isSkipNewbieBattle(function()
							if not gGameUI.guideManager:checkFinished(-1) then
								gGameApp:requestServer("/game/role/guide/newbie", nil, -1)
							end
							gGameUI:switchUI("new_character.view")
						end, function()
							self:newbieBattle()
						end)
					end
				end)
			end)
	else
		sdk.trackEvent(19)
		local userName = ""
		if (APP_CHANNEL == "none" or APP_CHANNEL == "luo") then
			userName = self.inputWidget.txtAccount:getString()
			if userName == "" then
				gGameUI:showDialog{content='name_can_not_empty'}
				return
			end
			if not dev.ONLINE_VERSION_LANGUAGE then
				userDefault.setForeverLocalKey("account", userName, {rawKey = true})
			end
			self:onServerLogin(userName)
		else
			sdk.login(function(code, info)
				printInfo('LoginView:sdkLogin %s %s', code, info)
				if code == 0 then
					self:onServerLogin(info)

					-- sdk.openCustomerService(function()
					-- 	printInfo('LoginView:openCustomerService')
					-- end)
				end
			end)
		end
	end

	-- 引擎之前没有在updater更新后重新获取patch，导致平台显示的patch有延后，这里再重新设置下
	local versionPlist = cc.FileUtils:getInstance():getValueMapFromFile('res/version.plist')
	ymdump.setUserInfo("patch", tostring(versionPlist.patch))
end

-- [{"id":1,"name":"S1","key":"game.shenhe.1","status":2,"addr":"172.81.227.66:10888"},{"id":1,"name":"xxx","key":"game.cn.1","status":2,"addr":"212.64.40.75:10888"}]
-- 20.3.18 由服务器根据 channel 做过滤，客户端只用判 shenhe 的
local function filterServer(info)
	local key = info.key
	-- none 全显示
	-- luo 裸包看配置
	if APP_CHANNEL == "none" then
		return true
	end

	local isShenheServer = key:find("game.shenhe.") ~= nil
	if FOR_SHENHE then
		return isShenheServer
	end

	return not isShenheServer
end

function LoginView:showServerTip()
	local title = gLanguageCsv.serverOpenTime
	if APP_CHANNEL == "tc_beta" then
		title = gLanguageCsv.serverCloseTime
	end
	gGameUI:showDialog({
		title = gLanguageCsv.tips,
		content = title,
		dialogParams = {clickClose = false},
	})
end

-- 用服务器数据获得服务器列表
function LoginView:setServers(serversStr)
	local servers = json.decode(serversStr)
	collectgarbage()

	self.servers = {}
	SERVERS_INFO = {}
	for k, v in ipairs(servers) do
		-- 后续有双平台，server.id 会重复，使用 server.key
		SERVERS_INFO[v.key] = v
		if filterServer(v) then
			table.insert(self.servers, v)
		else
			printDebug("the server %s be ignore", dumps(v))
		end
	end
	table.sort(self.servers, function(a, b)
		local tagA = string.split(a.key, ".")[2]
		local tagB = string.split(b.key, ".")[2]
		local orderA = SERVER_MAP[tagA] and SERVER_MAP[tagA].order or math.huge
		local orderB = SERVER_MAP[tagB] and SERVER_MAP[tagB].order or math.huge
		if orderA ~= orderB then
			return orderA < orderB
		end
		return a.id < b.id
	end)
end

-- 选择流畅服下标
function LoginView:selectServerIdx()
	local t = {}
	for i, v in ipairs(self.servers) do
		if v.status == 2 then
			table.insert(t, i)
		end
	end
	if #t > 0 then
		return t[math.random(1, #t)]
	end
	return #self.servers
end

function LoginView:onServerLogin(userName)
	-- 防止重复通知导致的多次login请求
	if userName == self.userName then
		printWarn("onServerLogin %s too much", userName)
		return
	end
	self.userName = userName

	gGameApp:requestServerCustom("login")
		:onErrClose(function()
				self.userName = nil
			end)
		:params(userName)
		:doit(function(tb)
			self:setServers(tb.servers)
			if #self.servers == 0 then
				self:showServerTip()
				self.userName = nil
				return
			end

			-- get serverSelected
			local serverKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
			if serverKey then
				self.serverSelected = itertools.first(self.servers, function(v)
					return v.key == serverKey
				end)
			else
				self.serverSelected = userDefault.getForeverLocalKey("serverId", nil, {rawKey = true})
			end
			if not self.servers[self.serverSelected] then
				self.serverSelected = self:selectServerIdx()
			end

			if dev.ONLINE_VERSION_LANGUAGE then
				-- 内网登录线上服默认读取已有最高等级的帐号区服
				local roleInfos = gGameModel.account:read("role_infos")
				local maxLevel = 0
				for k, v in ipairs(self.servers) do
					if roleInfos[v.key] and roleInfos[v.key].level > maxLevel then
						maxLevel = roleInfos[v.key].level
						self.serverSelected = k
					end
				end
			end

			local current = self.servers[self.serverSelected]
			self:setServerInfo(self.servers[self.serverSelected])
			self:showLoginServer()
		end)
end


function LoginView:showPlacard()
	sdk.trackEvent(17)
	gGameApp:getNotice(function(ret)
		gGameUI:stackUI("login.placard", nil, nil, ret.notice)
	end)
end

function LoginView:showLoginServer()
	if (APP_CHANNEL =="none" or APP_CHANNEL =="luo") then
		self.inputWidget:onClose()
	end
	self.loginServer:show()
end

function LoginView:setServerInfo(server)
	self.serverStatus:set(STATUS[server.status])
	self.currentServer:text(string.format("%s %s", getServerArea(server.key, nil, true), getServerName(server.key, true)))
	text.addEffect(self.statusColor, {["color"] = STATUSCOLOR[server.status]})
	self.serverSelected = itertools.first(self.servers, function(v)
		return v.key == server.key
	end)
	local maxWidth = math.max(self.currentServer:width() + self.statusColor:width() + self.chooseServer:width() + 150, 823)
	self.serverBg:width(maxWidth)
	adapt.oneLineCenterPos(cc.p(self.serverBg:xy()), {self.statusColor, self.currentServer, self.chooseServer}, cc.p(50, 0))
end

-- 新号登录战斗界面
function LoginView:newbieBattle()
	local data = {
		sceneID = 1,			-- 新手关卡id
		roleOut = csvClone(csv.role_out_init),
		randSeed = 123456,
		moduleType = 1, 	-- 战斗选择类型默认为 1: 常规  2: 全手动
		roleLevel = 1,

		names = {gLanguageCsv.newbieName1, gLanguageCsv.newbieName2},
		levels = {99, 99},
		logos = {1, 31},
		preData = {},
	}
	printInfo("in newbieBattle")
	-- print_r(data.roleOut)

	local view = gGameUI:switchUIAndStash("battle.loading", data, data.sceneID, {baseMusic = "battle4.mp3"}, {})
	-- 视频第 53 秒播放背景音乐
	performWithDelay(view, function()
		if gGameUI.isPlayVideo then
			view:onPlayMusic("battle4_pre.mp3")
		end
	end, 53)
	performWithDelay(view, function()
		if gGameUI.isPlayVideo then
			view:onPlayMusic()
		end
	end, 53 + 8)
	gGameUI:playVideo("new.mp4", function ()
		view:onLoadOver()
	end)
end


function LoginView:managerOpenView(list, num)
	local data = list[num]
	if not data then return end
	if not data.key  then
		data.cb(self:createHandler("managerOpenView", list, num+1))
	else
		self:managerOpenView(list, num+1)
	end
end

return LoginView
