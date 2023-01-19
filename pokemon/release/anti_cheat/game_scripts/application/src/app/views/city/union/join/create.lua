-- @date:   2019-06-04
-- @desc:   公会创建界面

local CREATE_COST = gCommonConfigCsv.unionCreateRMBCost

local UnionCreateView = class("UnionCreateView", Dialog)

UnionCreateView.RESOURCE_FILENAME = "union_create_box.json"
UnionCreateView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["textNote"] = {
		varname = "textNote",
		binds = {
			event = "visible",
			idler = bindHelper.self("vipEnough")
		}
	},
	["namePanel.textInput"] = "textInput",
	["head.imgIcon"] = {
		varname = "headIcon",
		binds = {
			event = "texture",
			idler = bindHelper.self("iconId"),
			method = function(iconId)
				local info = csv.union.union_logo[iconId] or {}
				return info.icon or {}
			end
		},
	},
	["btnChangeIcon"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeHeadUnion")},
		},
	},
	["cost"] = "cost",
	["cost.textCost"] = "textCost",
	["btnCreate"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCreateUnion")},
		},
	},
	["btnCreate.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["free"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStateChange")},
		},
	},
	["free.checkBox"] = "freeCheckBox",
	["needRequest.checkBox"] = "requestCheckBox",
	["needRequest"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStateChange")},
		},
	},
}

function UnionCreateView:onCreate(cb)
	self:initModel()
	self.cb = cb
	self.textInput:setPlaceHolderColor(ui.COLORS.DISABLED.WHITE)
	self.textInput:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	self.iconId = idler.new(1)
	self.vipEnough = idler.new(self.vip:read() < gCommonConfigCsv.unionCreateNeedVip)
	self.textNote:text(string.format(gLanguageCsv.unionCreateLimit, gCommonConfigCsv.unionCreateNeedVip))
	self.textCost:text(CREATE_COST)
	adapt.oneLineCenterPos(cc.p(self.cost:width()/2, self.cost:height()/2), {self.cost:get("textNote"), self.textCost, self.cost:get("imgIcon")}, cc.p(10, 0))
	self.freeState = idler.new(true)
	self.requestState = idler.new(false)
	idlereasy.any({self.freeState, self.requestState}, function(_, freeState, requestState)
		self.freeCheckBox:setSelectedState(freeState)
		self.requestCheckBox:setSelectedState(requestState)
	end)
	idlereasy.when(self.rmb, function(_, rmb)
		text.addEffect(self.textCost, {color = rmb < CREATE_COST and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT})
	end)
	blacklist:addListener(self.textInput, nil, functools.partial(self.nameAdapt, self))
	Dialog.onCreate(self)
end

function UnionCreateView:initModel()
	self.vip = gGameModel.role:getIdler("vip_level")
	self.rmb = gGameModel.role:getIdler("rmb")
end

function UnionCreateView:onStateChange()
	self.freeState:modify(function(oldval)
		return true, not oldval
	end)
	self.requestState:modify(function(oldval)
		return true, not oldval
	end)
end

function UnionCreateView:nameAdapt(txt)
	txt = txt or self.textInput:text()
	local str = beauty.singleTextLimitWord(txt, {fontSize = 40}, {width = 300, replaceStr = "", onlyText = true})
	self.textInput:text(str)
end

function UnionCreateView:onCreateUnion()
	self:nameAdapt()
	if self.vip:read() < gCommonConfigCsv.unionCreateNeedVip then
		gGameUI:showTip(gLanguageCsv.redPacketVipLimit)
		return
	end
	if self.rmb:read() < CREATE_COST then
		uiEasy.showDialog("rmb", nil, {dialog = true})
		return
	end
	local name = self.textInput:text()
	if string.len(name) < 1 then
		gGameUI:showTip(gLanguageCsv.unionNameIsEmpty)
		return
	end
	local joinType = self.freeState:read() and 1 or 0

	dataEasy.sureUsingDiamonds(function ()
		gGameApp:requestServer("/game/union/create",function (tb)
			gGameApp:requestServer("/game/union/get",function (tb)
				self:addCallbackOnExit(self.cb)
				self:onCloseFast()
			end)
		end, name, self.iconId, joinType)
	end, CREATE_COST)
end

function UnionCreateView:onChangeHeadUnion()
	gGameUI:stackUI("city.union.lobby.select_logo", nil, nil, {cb = self:createHandler("onChangeIconId"), id = self.iconId:read()})
end

function UnionCreateView:onChangeIconId(id)
	self.iconId:set(id)
end

function UnionCreateView:onClose(isFastClear)
	Dialog.onClose(self, isFastClear)
end

return UnionCreateView