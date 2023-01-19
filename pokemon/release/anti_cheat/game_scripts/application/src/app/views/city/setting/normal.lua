-- @date: 2019-07-03 17:15:34
-- @desc:设置常规界面

local SettingMainView = require("app.views.city.setting.view")
local BTN_TYPE = SettingMainView.BTN_TYPE
local BTN_DATA = SettingMainView.BTN_DATA

local STATE = {
	OPEN = 1,
	CLOSE = 2,
}

local pageListData = {
	[1] = {		-- 帧率控制
		name = gLanguageCsv.settingFPS,
		select1 = gLanguageCsv.settingFPSSelect1,
		select2 = gLanguageCsv.settingFPSSelect2,
		btnType = BTN_TYPE.RADIO,
		initFunc = function ()
			local fps = userDefault.getForeverLocalKey("fps", 60, {rawKey = true})
			local state = fps <= 30 and STATE.OPEN or STATE.CLOSE
			return state
		end,
		func = function (state)		-- state : true对应select1 false对应select2
			local fps = state and 30.0 or 60.0
			cc.Director:getInstance():setAnimationInterval(1.0 / fps)
			userDefault.setForeverLocalKey("fps", fps, {rawKey = true})
		end
	},
	[2] = {		-- 屏幕适配
		name = gLanguageCsv.settingScreen,
		select1 = gLanguageCsv.settingScreenSelect1,
		select2 = gLanguageCsv.settingScreenSelect2,
		btnType = BTN_TYPE.RADIO,
		initFunc = function ()
			local flag = cc.UserDefault:getInstance():getBoolForKey("isNotchScreen", false)
			return flag and STATE.CLOSE or STATE.OPEN
		end,
		func = function (state)
			local flag = cc.UserDefault:getInstance():getBoolForKey("isNotchScreen", false)
			if flag ~= state then return end-- 入口保护

			gGameUI:sendMessage("adapterNotchScreen", true)
			flag = not state 		-- 刘海屏设置 与上方注释相反
			cc.UserDefault:getInstance():setBoolForKey("isNotchScreen", flag)
			if flag then
				display.notchSceenSafeArea = display.fullScreenSafeArea
				display.notchSceenDiffX = display.fullScreenDiffX
			else
				display.notchSceenSafeArea = 0
				display.notchSceenDiffX = 0
			end
			gGameUI:sendMessage("adapterNotchScreen", false)
		end
	},
	[3] = {		-- vip显示 隐藏
		name = gLanguageCsv.settingVip,
		select1 = gLanguageCsv.settingHide,
		select2 = gLanguageCsv.settingShow,
		btnType = BTN_TYPE.RADIO,
		initFunc = function ()
			local vipDisplay = gGameModel.role:read("vip_hide")
			local state = not vipDisplay and STATE.CLOSE or STATE.OPEN
			return state
		end,
		func = function (state)
			local vipDisplay = gGameModel.role:read("vip_hide")
			if vipDisplay ~= state then
				gGameApp:requestServer("/game/role/vip/display/switch", function (tb)
				end, state)
			end
		end
	},
	-- TODO 现在固定关闭战斗设置
	-- [5] = {		-- 战斗设置
	-- 	name = gLanguageCsv.settingBattle,
	-- 	select1 = gLanguageCsv.settingBattleSelect1,
	-- 	select2 = gLanguageCsv.settingBattleSelect2,
	-- 	btnType = BTN_TYPE.BTN,
	-- 	needCallBack = function (btnNumber)
	-- 		return false
	-- 	end,
	-- 	initFunc = function (btnNumber,cb)
	-- 		return BTN_TYPE.OPEN
	-- 	end,
	-- 	func = function (state,btnNumber)
	-- 	end
	-- },
}

local function setNodeItem(parent,children,data)
	children.text:text(data.name)
	children.btnPanel1:get("text"):text(data.select1)
	children.btnPanel2:get("text"):text(data.select2)

	local setBtnSwitch = function (panel,btnNumber)
		local dt = BTN_DATA[data.btnType]
		local btn = panel:get("btn")
		local img = btn:get("btnImg")
		btn:texture(dt.resNormal)
		img:texture(dt.resBtnImg)

		img:xy(30,30)		-- 固定位置

		local btnState = idler.new()
		-- btn:get("btnImg"):y(btn:get("btnImg"):y() + 1)

		btnState:addListener(function(val, oldval)
			local state = val == STATE.OPEN
			btn:texture(state and dt.resSelected or dt.resNormal)

			if state then
				img:xy(100,30)		-- 固定位置
			else
				img:xy(30,30)		-- 固定位置
			end
			data.func(state,btnNumber)
		end,true)

		--如回需调则用回调的方式
		if data.needCallBack(btnNumber) then
			data.initFunc(btnNumber,function (state)
				btnState:set(state)
			end)
		else
			local state = data.initFunc()
			btnState:set(state)
		end

		bind.click(parent, panel, {method = function()
			local ty = btnState:read() == STATE.OPEN and STATE.CLOSE or STATE.OPEN
			btnState:set(ty)
		end})
	end

	-- OPEN:左边 CLOSE:右边
	local setBtnRadio = function (panel1,panel2)
		local dt = BTN_DATA[data.btnType]
		local btn1 = panel1:get("btn")
		local btn2 = panel2:get("btn")

		btn1:texture(dt.resNormal)
		btn1:get("btnImg"):texture(dt.resBtnImg)
		btn2:texture(dt.resNormal)
		btn2:get("btnImg"):texture(dt.resBtnImg)

		local btnState = idler.new()

		btnState:addListener(function(val, oldval)
			local state = val == STATE.OPEN
			btn1:get("btnImg"):visible(state)
			btn2:get("btnImg"):visible(not state)
			data.func(state)
		end,true)

		btnState:set(data.initFunc())

		local func1 = function()
			btnState:set(STATE.OPEN)
		end
		local func2 = function()
			btnState:set(STATE.CLOSE)
		end

		bind.click(parent, panel1, {method = function()
			btnState:set(STATE.OPEN)
		end})

		bind.click(parent, panel2, {method = function()
			btnState:set(STATE.CLOSE)
		end})
	end

	if data.btnType == BTN_TYPE.RADIO then
		setBtnRadio(children.btnPanel1,children.btnPanel2)
	else
		setBtnSwitch(children.btnPanel1,1)
		setBtnSwitch(children.btnPanel2,2)
	end
end

local SettingNormalView = class("SettingNormalView", cc.load("mvc").ViewBase)
SettingNormalView.RESOURCE_FILENAME = "setting_normal.json"
SettingNormalView.RESOURCE_BINDING = {
	["centerPanel"] = "centerPanel",
	["centerPanel.item"] = "listItem",
	["centerPanel.btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listData"),
				item = bindHelper.self("listItem"),
				margin = bindHelper.self("margin"),
				padding = 0,
				onItem = function(list, node, k, v)
					local children = node:multiget("text", "btnPanel1", "btnPanel2")
					setNodeItem(list, children, v)
				end,
				onAfterBuild = function(list)
					if itertools.size(list.data) == 1 then
						list:setItemAlignCenter()
					end
				end,
			},
		},
	},
	["centerPanel.bottomPanel"] = "bottomPanel",
	["centerPanel.bottomPanel.btnService"] = {
		varname = "btnService",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onService")},
		},
	},
	["centerPanel.bottomPanel.btnLogOut"] = {
		varname = "btnLogOut",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLogOut")},
		},
	},
	["centerPanel.bottomPanel.btnRedeemCode"] = {
		varname = "btnRedeemCode",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRedeemCode")},
		},
	},
	["centerPanel.bottomPanel.btnNotice"] = {
		varname = "btnNotice",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onNotice")},
		},
	},
	["centerPanel.bottomPanel.btnFeedback"] = {
		varname = "btnFeedback",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onFeedback")},
		},
	},
	["centerPanel.bottomPanel.btnTcPrivacy"] = {
		varname = "btnTcPrivacy",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTcPrivacy")},
		},
	},
	["centerPanel.bottomPanel.btnTcPermission"] = {
		varname = "btnTcPermission",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTcPermission")},
		},
	},
	["versionPanel"] = "versionPanel",
	["serverTimePanel"] = "serverTimePanel",

}

function SettingNormalView:onCreate()
	self.listData = clone(pageListData)
	-- TODO 玩家版本 暂时隐藏
	self.btnService:hide()
	self:judgeTc()
	self.versionPanel:get("version"):text(APP_VERSION)
	adapt.oneLinePos(self.versionPanel:get("version"), self.versionPanel:get("text"), nil, "right")
	self:enableSchedule():schedule(function()
		local date = time.getNowDate()
		if APP_CHANNEL == "none" or APP_CHANNEL == "luo" then
			-- 内网时间显示年月日
			self.serverTimePanel:get("time"):text(string.format("%s/%s/%s %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
		else
			self.serverTimePanel:get("time"):text(string.format("%02d:%02d:%02d", date.hour, date.min, date.sec))
		end
		adapt.oneLinePos(self.serverTimePanel:get("time"), self.serverTimePanel:get("text"), nil, "right")
	end, 1, 0, 1)

	-- vip是否显示
	if not dataEasy.isUnlock(gUnlockCsv.vipDisplaySwitch) then
		self.listData[3] = nil
	end

	-- 隐藏刘海屏设置
	local function hideNorchScreen()
		self.listData[2] = nil
	end
	if  display.sizeInPixels.width < display.sizeInPixels.height * 2 then
		hideNorchScreen()

	elseif device.platform == "windows" then
		if device.model == "iphone x" then
			hideNorchScreen()
		end
	else
		if display.isNotchSceen ~= 1 then
			hideNorchScreen()
		end
	end

	local margin = {0, 70, 30, 8}
	self.margin = margin[itertools.size(self.listData)]

	local antiCopy = 0
	self.versionPanel:onClick(function()
		antiCopy = antiCopy + 1
		if antiCopy % 10 == 0 then
			gGameUI:showTip("Copyright (c) 2020 HangZhou TianJi Information Technology Inc.")
		end
	end)

	self:setLoginProtocol()
end

-- 联系客服
function SettingNormalView:onService()
	-- TODO
end

-- 隐私和协议
function SettingNormalView:setLoginProtocol()
	-- 腾讯隐私政策和用户协议
	if not APP_TAG:find("_qq") then
		return
	end
	local url = "http://page.kuyangsh.cn/site/privacy?key=08a412053778cad3de9a8fcddb7e21582d3cfda0"
	local str = string.format("#C0xB7B09E##L00010100##LUL%s#隐私政策和用户协议", url)
	local richText = rich.createWithWidth(str, 36, nil, 1000)
		:setAnchorPoint(cc.p(0, 0.5))
		:addTo(self.bottomPanel, 5, "richText")

	adapt.oneLinePos(self.btnNotice, richText, cc.p(200, 40), "left")
end

-- 退出登录
function SettingNormalView:onLogOut()
	sdk.logout(function(info)
		print("sdk logout callback",info)
	end)
	sdk.commitRoleInfo(5,function()
		print("sdk commitRoleInfo logout")
	end)
	gGameApp:onBackLogin()
end

-- 公告
function SettingNormalView:onNotice()
	gGameApp:getNotice(function(ret)
		gGameUI:stackUI("login.placard", nil, nil, ret.notice)
	end)
end

-- 兑换码
function SettingNormalView:onRedeemCode()
	gGameUI:stackUI("city.setting.redeem_code")
end

-- 问题反馈
function SettingNormalView:onFeedback()
	if matchLanguage({"kr"}) then
		sdk.commitRoleInfo(54, function()
			print("sdk commitRoleInfo customerService")
		end)
		return
	end

	local count = userDefault.getCurrDayKey("feedBackDayCount", 0)
	if count >= gCommonConfigCsv.feedBackDayCount then
		gGameUI:showTip(gLanguageCsv.feedBackTooMany)
	else
		gGameUI:stackUI("city.setting.feed_back")
	end
end

function SettingNormalView:judgeTc()
	local judgeString = APP_TAG
	print("SettingNormalView:APP_TAG is ",judgeString)
	local replaceString = string.gsub(judgeString,"_"," ")
	local words = {}
	for _t in string.gmatch(replaceString,"%w+") do
		words[#words + 1] = _t
	end

	if LOCAL_LANGUAGE == 'cn' and words[1] and tonumber(words[3]) and words[1] == "a10054" and tonumber(words[3]) > 20210329 then
        self.btnTcPrivacy:show()
        self.btnTcPermission:show()
	else
		self.btnTcPrivacy:hide()
		self.btnTcPermission:hide()
	end
end

-- TC渠道隐私协议
function SettingNormalView:onTcPrivacy()
	sdk.openPrivacyProtocols()
end

--TC渠道权限设置
function SettingNormalView:onTcPermission()
	sdk.openPermissionSetting()
end


return SettingNormalView