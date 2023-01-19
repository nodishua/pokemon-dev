-- @date:   2019-06-05
-- @desc:   公会提示弹窗

local TIP_TYPE = {
	--踢出
	["kick"] = "/game/union/kick",
	--转让
	["swap"] = "/game/union/chairman/swap",
	--升职
	["promote"] = "/game/union/chairman/promote",
	--降职
	["demote"] = "/game/union/chairman/demote",
	--解散
	["destroy"] = "/game/union/destroy",
	--退会
	["quit"] = "/game/union/quit",
	--招募
	["joinup"] = "/game/union/joinup"
}

local UnionPromptView = class("UnionPromptView", Dialog)

UnionPromptView.RESOURCE_FILENAME = "union_prompt.json"
UnionPromptView.RESOURCE_BINDING = {
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
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["mask"] = "mask",
	["pos"] = "pos",
	["txt"] = "txt",
}

-- typ, requestParams = {}, content, numTip, needConsider, cb
function UnionPromptView:onCreate(params)
	self.mask:hide()
	self.params = params
	if params.numTip then
		self.txt:text(params.numTip)
	end
	if params.needConsider then
		self:considerTime()
	end

	local size = cc.size(800, 460)
	local list, height = beauty.textScroll({
		size = size,
		fontSize = 50,
		effect = {color=ui.COLORS.NORMAL.DEFAULT},
		strs = params.content,
		verticalSpace = 10,
		isRich = true,
		margin = 20,
		align = "center",
	})
	local y = 0
	if height < size.height then
		y = -(size.height - height) / 2
	end
	list:addTo(self.pos, 3):xy(-size.width/2, -size.height/2 + y)

	Dialog.onCreate(self)
end

function UnionPromptView:onClickOK()
	gGameApp:requestServer(TIP_TYPE[self.params.typ], function(tb)
		local cb = self.params.cb
		self:onCloseFast()
		if cb then
			cb()
		end
	end, unpack(self.params.requestParams or {}))
end

function UnionPromptView:considerTime()
	self.btnOK:setEnabled(false)
		self.mask:show()
		local limitTime = 5
		self:enableSchedule():schedule(function (dt)
			self.mask:get("time"):text(limitTime)
			limitTime = limitTime - 1
			if limitTime < 0 then
				self.mask:hide()
				self.btnOK:setEnabled(true)
				self:unSchedule("attrLvUp")
			end
		end, 1, 0, "attrLvUp")
end

function UnionPromptView:onClose(isFastClear)
	Dialog.onClose(self, isFastClear)
end

return UnionPromptView