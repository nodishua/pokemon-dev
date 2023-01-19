-- @date: 2019-07-03 17:15:34
-- @desc:设置界面反馈弹窗

local SettingFeedBackView = class("SettingFeedBackView", Dialog)
SettingFeedBackView.RESOURCE_FILENAME = "setting_feed_back.json"
SettingFeedBackView.RESOURCE_BINDING = {
	["textField"] = "textField",
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["btnCancel"] = {
		varname = "btnCancel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["btnComfirm"] = {
		varname = "btnComfirm",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onConfirmBtn")},
		},
	},
	["btnRecharge"] = "btnRecharge",
	["btnBattle"] = "btnBattle",
	["btnBug"] = "btnBug",
	["btnRecommend"] = "btnRecommend",
}

function SettingFeedBackView:onCreate()
	self.checkState = idler.new("RechargeIssue")

	self.btnData = {
		["RechargeIssue"] = self.btnRecharge,
		["BattleIssue"] = self.btnBattle,
		["BugIssue"] = self.btnBug,
		["Recommand"] = self.btnRecommend,
	}

	self.checkState:addListener(function(val, oldval)
		for k,panel in pairs(self.btnData) do
			panel:get("btn"):get("btnImg"):visible(k == val)
		end
	end)

	for k,panel in pairs(self.btnData) do
		bind.click(self, panel, {method = function()
			self.checkState:set(k)
		end})
	end

	-- blacklist:addListener(self.textField)
	self.textField:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
	self.textField:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	-- self.textField:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)

	Dialog.onCreate(self, {clickClose = false})
end

function SettingFeedBackView:onConfirmBtn()
	if APP_CHANNEL == "none" or APP_CHANNEL == "luo" then
		-- 内网包反馈不发送到平台上
		self:onClose()
		return
	end

	local str = self.textField:getStringValue()
	if string.trim(str) == "" then
		gGameUI:showTip(gLanguageCsv.canNotEmpty)
		return
	end

	if string.find(FEED_BACK_URL, "dingtalk") then
		self:sendToDingDing(str)
	else
		self:sendToCrashPlatform(str, matchLanguage({"kr"}))
	end

	self:onClose()

	if matchLanguage({"kr"}) then
		sdk.commitRoleInfo(54, function()
			print("sdk commitRoleInfo customerService")
		end)
	end
end

function SettingFeedBackView:sendToCrashPlatform(str, notip)
	local data = {
		account_id = stringz.bintohex(gGameModel.account:read("id")),
		uid = gGameModel.role:read("uid"),
		game_server = gGameApp.net.gameSession.serverKey,
		role_name = gGameModel.role:read("name"),
		role_id = stringz.bintohex(gGameModel.role:read("id")),
		grade = gGameModel.role:read("level"),
		vip = gGameModel.role:read("vip_level"),
		classify = self.checkState:read(),
		issue = str,
	}

	gGameApp.net:sendHttpRequest("POST", FEED_BACK_URL,
		json.encode(data),
		cc.XMLHTTPREQUEST_RESPONSE_STRING,
		function(xhr)
			if not notip then
				if xhr.status == 200 then
					local count = userDefault.getCurrDayKey("feedBackDayCount", 0)
					userDefault.setCurrDayKey("feedBackDayCount", count + 1)
					gGameUI:showTip(gLanguageCsv.feedBackSuccess)
				else
					gGameUI:showTip(gLanguageCsv.feedBackFail)
				end
			end
		end
	)
end

local function sendDingDingRequest(reqBody)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
	xhr:open("POST", FEED_BACK_URL)
	xhr:setRequestHeader("Content-Type", "application/json")
	local function _onReadyStateChange(...)
		if xhr.status == 200 then
			local count = userDefault.getCurrDayKey("feedBackDayCount", 0)
			userDefault.setCurrDayKey("feedBackDayCount", count + 1)
		end
	end
	xhr:registerScriptHandler(_onReadyStateChange)
	xhr:send(reqBody)
end

function SettingFeedBackView:sendToDingDing(str)
	local text = string.format("反馈时间: %s\n\n问题类型: %s\n\n区服: %s\n\n角色名: %s\n\n角色ID: %s\n\n等级: %s\n\nvip: %s\n\n问题描述: %s\n\n",
		os.date(),
		self.checkState:read(),
		gGameApp.net.gameSession.serverKey,
		gGameModel.role:read("name"),
		stringz.bintohex(gGameModel.role:read("id")),
		gGameModel.role:read("level"),
		gGameModel.role:read("vip_level"),
		str
	)
	local data = {
		msgtype = "markdown",
		markdown = {
			title = "[口袋KR]" .. self.checkState:read(),
			text = text,
		}
	}
	sendDingDingRequest(json.encode(data))
end

return SettingFeedBackView
