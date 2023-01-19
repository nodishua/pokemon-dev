local desc = {
	title = "服务协议和隐私政策",
	info1 = "请你务必审慎阅读、充分理解“服务协议”和“隐私政策”各条款，包括但不限于：为了向你提供即时通讯，内容分享等服务，我们需要收集你的设备信息、操作日志等个人信息。你可以在“设置”中查看、变更、删除个人信息并管理你的授权。",
	info2 = "你可阅读",
	info3 = "《隐私政策和用户协议》",
	info6 = "了解详细信息。如你同意，请点击“同意”开始接受我们的服务。",
	url = "http://page.kuyangsh.cn/site/privacy?key=08a412053778cad3de9a8fcddb7e21582d3cfda0 "
}

local ViewBase = cc.load("mvc").ViewBase
local LoginProtocolView = class("LoginProtocolView", Dialog)

LoginProtocolView.RESOURCE_FILENAME = "login_protocol.json"

LoginProtocolView.RESOURCE_BINDING = {
	["btnDel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnDel")},
		},
	},
	["btnDel.text"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["btnAgree"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnAgree")},
		},
	},
	["btnAgree.text"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["labelTitle"] = "labelTitle"
}


function LoginProtocolView:onCreate()
	self.labelTitle:text(desc.title):setFontSize(60)
	local str = {
		string.format("#C0x5B545B##F50#%s\n", desc.info1),
		string.format("#C0x5B545B##F50#%s#C0x75C4FF##L00010100##LUL%s#%s#C0x5B545B#%s", desc.info2,
			desc.url, desc.info3, desc.info6),
	}

	local richText = rich.createWithWidth(table.concat(str),40,nil,1150)
		:anchorPoint(cc.p(0, 1))
		:xy(706 + display.uiOrigin.x, 920)
	self:getResourceNode():addChild(richText, 1, "richText")

	Dialog.onCreate(self, {clickClose = false,clearFast = true})
end


function LoginProtocolView:onBtnDel()
	display.director:endToLua()
end

function LoginProtocolView:onBtnAgree()
	self:addCallbackOnExit(self.cb)
	userDefault.setForeverLocalKey("protocalStatusSign", true, {rawKey = true})
	Dialog.onClose(self)
end

return LoginProtocolView