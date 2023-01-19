-- @date:   2019-06-04
-- @desc:   公会信息界面

-- 0 审批加入 1 直接加入 2 拒绝加入
local JOINTYPE = {
	APPROVEJOIN = 0,
	DIRECTJOIN = 1,
	REFUSEJOIN = 2,
}

local STATES = {
	[0] = gLanguageCsv.needApply,
	[1] = gLanguageCsv.directJoin,
	[2] = gLanguageCsv.refuseJoin,
}

local ViewBase = cc.load("mvc").ViewBase
local UnionDetailView = class("UnionDetailView", Dialog)

UnionDetailView.RESOURCE_FILENAME = "union_info.json"
UnionDetailView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["title.textNote1"] = "textNote1",
	["title.textNote2"] = "textNote2",
	["head.imgIcon"] = "headIcon",
	["btnCancle"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["btnCancle.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["btnRequest"] = {
		varname = "btnRequest",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRequestJoin")},
		},
	},
	["btnRequest.textNote"] = {
		binds = {
			{
				event = "effect",
				data = {glow = {color = ui.COLORS.GLOW.WHITE}},
			},
			{
				event = "text",
				idler = bindHelper.self("showNote"),
			},
		},
	},
	["textUnionName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionName"),
		},
	},
	["textUnionID"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionID"),
		},
	},
	["textUnionBoss"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionBoss"),
		},
	},
	["textUnionPeople"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionPeople"),
		},
	},
	["textUnionNote"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionNote"),
		},
	},
	["textState1"] = {
		varname = "textState1",
		binds = {
			event = "text",
			idler = bindHelper.self("state1"),
		},
	},
}

function UnionDetailView:onCreate(idx, unionInfo, handler, cb)
	self.unionInfo = unionInfo
	self.handler = handler
	self.idx = idx
	self.cb = cb
	self:initModel()
	local showTxt = gLanguageCsv.approve
	if unionInfo.join_type == JOINTYPE.DIRECTJOIN then
		showTxt = gLanguageCsv.joinIn
	elseif unionInfo.isApprove then
		showTxt = gLanguageCsv.approveCancle
	end
	self.showNote = idler.new(showTxt)
	self.unionID = idler.new(unionInfo.uid)
	self.unionName = idler.new(unionInfo.name)
	self.unionBoss = idler.new(unionInfo.chairman_name)
	self.unionPeople = idler.new(string.format("%d/%d", unionInfo.members, unionInfo.member_max))
	local desc = string.len(unionInfo.join_desc) > 0 and unionInfo.join_desc or gLanguageCsv.unionJoinupDesc
	self.unionNote = idler.new(desc)
	local str = STATES[unionInfo.join_type]
	local color = ui.COLORS.NORMAL.DEFAULT
	if unionInfo.join_level > 0 then
		str = str .. string.format(gLanguageCsv.levelLimit, unionInfo.join_level)
		if self.level:read() < unionInfo.join_level then
			color = ui.COLORS.NORMAL.RED
		end
	else
		str = str .. gLanguageCsv.noLimit
	end
	self.state1 = idler.new(str)
	text.addEffect(self.textState1, {color=color})
	self.headIcon:texture(csv.union.union_logo[unionInfo.logo].icon)
	-- 已有公会按钮置灰
	uiEasy.setBtnShader(self.btnRequest, self.btnRequest:get("textNote"), not self.myUnionId and 1 or 2)
	Dialog.onCreate(self)
end

function UnionDetailView:initModel()
	self.level = gGameModel.role:getIdler("level")
	self.myUnionId = gGameModel.role:read("union_db_id")
end

function UnionDetailView:onRequestJoin()
	local url = "/game/union/join"
	if self.unionInfo.isApprove then
		url = "/game/union/join/cancel"
	end
	gGameApp:requestServer(url,function (tb)
		if self.handler then
			self.handler(self.idx)
		end
		if self.unionInfo.join_type == JOINTYPE.DIRECTJOIN then
			gGameApp:requestServer("/game/union/get",function (tb)
				self:addCallbackOnExit(self.cb)
				ViewBase.onClose(self)
			end)
		else
			local text = self.unionInfo.isApprove and gLanguageCsv.approveCancle or gLanguageCsv.approve
			self.showNote:set(text)
		end
	end, self.unionInfo.id)
end

return UnionDetailView