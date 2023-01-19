-- @date:   2019-06-04
-- @desc:   公会创建、加入界面

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

local BTNSTATETEXT = {
	gLanguageCsv.approve,
	gLanguageCsv.approveCancle,
	gLanguageCsv.joinIn,
}

local ViewBase = cc.load("mvc").ViewBase
local UnionJoinView = class("UnionJoinView", Dialog)

UnionJoinView.RESOURCE_FILENAME = "union_join.json"
UnionJoinView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["noUnionInfo"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowTip"),
		},
	},"noUnionInfo",
	["title.textNote1"] = "textNote1",
	["title.textNote2"] = "textNote2",
	["item"] = "item",
	["list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("unionDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local children = node:multiget("head", "textName", "textLvNum", "textCount", "textState", "textLimitLv", "btnRight")
					children.head:get("imgIcon"):texture(csv.union.union_logo[v.logo].icon)
					children.textName:text(v.name)
					children.textLvNum:text(v.level)
					children.textCount:text(string.format("%d/%d", v.members, v.member_max))
					children.textState:text(STATES[v.join_type])
					children.textLimitLv:text(v.join_level)
					local str = gLanguageCsv.approve
					if v.isApprove and v.join_type == JOINTYPE.APPROVEJOIN then
						str = gLanguageCsv.approveCancle
					elseif v.join_type == JOINTYPE.DIRECTJOIN then
						str = gLanguageCsv.joinIn
					end
					adapt.setTextScaleWithWidth(children.btnRight:get("textNote"), str, 240)
					text.addEffect(children.btnRight:get("textNote"), {glow={color=ui.COLORS.GLOW.WHITE}})
					bind.touch(list, node, {methods = {
						ended = functools.partial(list.onClickCell, k, v)
					}})
					bind.touch(list, children.btnRight, {methods = {
						ended = functools.partial(list.onBtnClick, k, v)
					}})
				end,
			},
			handlers = {
				onClickCell = bindHelper.self("onItemClick"),
				onBtnClick = bindHelper.self("onBtnClick"),
			},
		},
	},
	["down.textInput"] = "textInput",
	["down.btnChange"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeUnion")},
		},
	},
	["down.btnCreate"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCreateUnion")},
		},
	},
	["down.btnCreate.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["down.btnJoin"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onJoinUnion")},
		},
	},
	["down.btnJoin.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["down.btnFind"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onFindUnion")},
		},
	},
	["down.btnClear"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClearInput")},
		},
	},
}

function UnionJoinView:onCreate(listDatas)
	self.oldApproveTab = {}
	adapt.oneLinePos(self.textNote1, self.textNote2, nil, "left")
	self.textInput:setPlaceHolderColor(ui.COLORS.DISABLED.WHITE)
	self.textInput:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	self:initModel()
	self.offset = 11
	self.dbIdTab = {}
	local hashMap = itertools.map(self.unionJoinQue:read() or {}, function(k, v) return v, 1 end)
	for k,v in pairs(listDatas) do
		if hashMap[v.id] then
			listDatas[k].isApprove = true
		else
			listDatas[k].isApprove = false
		end
		self.dbIdTab[v.id] = k
	end

	self.isShowTip = idler.new(itertools.size(listDatas) <= 0)
	self.unionDatas = idlertable.new(listDatas)
	self.canQuickJoin = false
	idlereasy.when(self.unionDatas, function(_, unionDatas)
		for k,v in pairs(unionDatas) do
			if v.join_type == JOINTYPE.DIRECTJOIN then
				self.canQuickJoin = true
				break
			end
		end
	end)
	idlereasy.when(self.unionJoinQue, function(_, unionJoinQue)
		local oldSize = itertools.size(self.oldApproveTab or {})
		local curSize = itertools.size(unionJoinQue)
		if oldSize >= 3 and curSize >= 3 then
			local oldHashMap = itertools.map(self.oldApproveTab, function(k, v) return v, k end)
			for k,v in pairs(unionJoinQue) do
				local idx = oldHashMap[v]
				if idx then
					self.oldApproveTab[idx] = nil
				end
			end
			local _, dbid = next(self.oldApproveTab)
			local dataIdx = self.dbIdTab[dbid]
			if dataIdx then
				self.unionDatas:proxy()[dataIdx].isApprove = false
			end
		end
	end)
	Dialog.onCreate(self)
end

function UnionJoinView:initModel()
	self.unionJoinQue = gGameModel.role:getIdler("union_join_que")
end

function UnionJoinView:onItemClick(listview, k, v)
	gGameUI:stackUI("city.union.join.detail", nil, nil, k, v, self:createHandler("onChangeData"), self:createHandler("onCloseFast"))
end

function UnionJoinView:onChangeData(idx)
	self.unionDatas:proxy()[idx].isApprove = not self.unionDatas:proxy()[idx].isApprove
end

function UnionJoinView:onBtnClick(listview, k, v)
	if v.members >= v.member_max then
		gGameUI:showTip(gLanguageCsv.unionMemberMax)
		return
	end
	local url = "/game/union/join"
	local unionJoinType = v.join_type
	if v.isApprove then
		url = "/game/union/join/cancel"
	else
		local size = itertools.size(self.unionJoinQue:read())
		if size >= 3 then
			gGameUI:showTip(gLanguageCsv.approveMax)
			self.oldApproveTab = table.deepcopy(self.unionJoinQue:read(), true)
		end
	end
	gGameApp:requestServer(url,function (tb)
		if unionJoinType == JOINTYPE.DIRECTJOIN then
			gGameApp:requestServer("/game/union/get",function (tb)
				self:onCloseFast()
			end)
		end
		self:onChangeData(k)
	end, v.id)
end

function UnionJoinView:onCreateUnion()
	gGameUI:stackUI("city.union.join.create", nil, nil, self:createHandler("onCloseFast"))
end

function UnionJoinView:onFindUnion()
	local uid = self.textInput:text() or ""
	if string.len(uid) < 1 then
		return
	end
	gGameApp:requestServer("/game/union/find",function (tb)
		self.unionDatas:set(tb.view)
	end, uid)
end

function UnionJoinView:onChangeUnion()
	local hashMap = itertools.map(self.unionJoinQue:read() or {}, function(k, v) return v, 1 end)
	gGameApp:requestServer("/game/union/list",function (tb)
		local size = itertools.size(tb.view.unions)
		self.isShowTip:set(self.offset == 1 and size <= 0)
		if size > 0 then
			local datas = tb.view.unions
			for k,v in pairs(datas) do
				if hashMap[v.id] then
					datas[k].isApprove = true
				else
					datas[k].isApprove = false
				end
			end
			self.unionDatas:set(datas)
			self.offset = size < 10 and 1 or self.offset + 10
		end
		self.listview:jumpToTop()
		gGameUI:showTip(gLanguageCsv.refreshUnionList)
	end, self.offset, 10)
end

function UnionJoinView:onJoinUnion()
	if not self.canQuickJoin then
		gGameUI:showTip(gLanguageCsv.noUnionToJoin)
		return
	end
	-- 快速加入之后获取下公会信息然后进入主界面
	gGameApp:requestServer("/game/union/fast/join",function (tb)
		gGameApp:requestServer("/game/union/get",function (tb)
			self:onCloseFast()
		end)
	end)
end

function UnionJoinView:onClearInput()
	self.textInput:text("")
end

function UnionJoinView:onCloseFast()
	Dialog.onCloseFast(self)
	jumpEasy.jumpTo("union")
end

return UnionJoinView