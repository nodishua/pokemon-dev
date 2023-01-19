-- @date:   2019-06-05
-- @desc:   公会修改公告

local UnionChangeNoticeView = class("UnionChangeNoticeView", Dialog)

UnionChangeNoticeView.RESOURCE_FILENAME = "union_change_notice.json"
UnionChangeNoticeView.RESOURCE_BINDING = {
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
}
function UnionChangeNoticeView:onCreate()
	self:initModel()
	self:initTxt(self.intro:read())
	self.textInput:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
	blacklist:addListener(self.textInput, "*", function(txt)
		self:initTxt(txt)
	end)
	Dialog.onCreate(self)
end

function UnionChangeNoticeView:initModel()
	local unionInfo = gGameModel.union
	self.intro = unionInfo:getIdler("intro")
end

function UnionChangeNoticeView:initTxt(txt)
	local txt, textNum = string.utf8limit(txt, 50, true)
	self.textNum:text(textNum.."/50")
	self.textInput:text(txt)
end

function UnionChangeNoticeView:onClickOK()
	local txt = self.textInput:text()
	if txt == self.intro:read() then
		gGameUI:showTip(gLanguageCsv.noChangeIntro)
		return
	end
	local needSpecialChar = LOCAL_LANGUAGE == 'en'
	if uiEasy.checkText(txt,nil,needSpecialChar) then
		gGameApp:requestServer("/game/union/intro/modify",function (tb)
			gGameUI:showTip(gLanguageCsv.modifySuccessful)
			self:onClose()
		end, txt)
	end
end
return UnionChangeNoticeView