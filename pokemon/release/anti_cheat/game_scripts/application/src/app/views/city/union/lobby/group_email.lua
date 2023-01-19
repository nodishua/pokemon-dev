-- @date:   2019-06-05
-- @desc:   公会群发邮件

local UnionGroupEmailView = class("UnionGroupEmailView", Dialog)

UnionGroupEmailView.RESOURCE_FILENAME = "union_group_email.json"
UnionGroupEmailView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["btnOK"] = {
		varname = "btnOK",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClickOK")}
		},
	},
	["btnCancel"] = {
		varname = "btnCancel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["textInput"] = "textInput",
	["textNum"] = "textNum",
	["textTimes"] = "textTimes",
}

function UnionGroupEmailView:onCreate(sendMailTimes)
	self:initModel()
	self.textNum:text("0/50")
	self.textTimes:text(math.max(2 - sendMailTimes, 0).."/2")
	self.textInput:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
	blacklist:addListener(self.textInput, "*", function(txt)
		local txt, textNum = string.utf8limit(txt, 50, true)
		self.textNum:text(textNum.."/50")
		self.textInput:text(txt)
	end)
	Dialog.onCreate(self)
end

function UnionGroupEmailView:initModel()
	--已发送邮件的次数
	self.dailyRecord = gGameModel.daily_record:getIdler("union_mail_send_count")
end

function UnionGroupEmailView:onClickOK()
	local txt = self.textInput:text()
	if uiEasy.checkText(txt) then
		gGameApp:requestServer("/game/union/send/mail",function (tb)
			gGameUI:showTip(gLanguageCsv.sendSuccessful)
			self:onClose()
		end, txt)
	end
end

return UnionGroupEmailView