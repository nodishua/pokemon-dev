-- @date:   2019-06-05
-- @desc:   公会申请条件状态

local UnionCurrentStateView = class("UnionCurrentStateView", Dialog)

UnionCurrentStateView.RESOURCE_FILENAME = "union_current_state.json"
UnionCurrentStateView.RESOURCE_BINDING = {
	["btnClose"] = {
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
	["free.checkBox"] = "freeCheckBox",
	["free"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onFree")}
		},
	},
	["needRequest.checkBox"] = "needRequestCheckBox",
	["needRequest"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onNeedRequest")}
		},
	},
	["refuse.checkBox"] = "refuseCheckBox",
	["refuse"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRefuse")}
		},
	},
	["limitLevelPanel.btnSub"] = "btnSub",
	["limitLevelPanel.btnAdd"] = "btnAdd",
	["limitLevelPanel.txt"] = "limitTxt",
	["inputPanel.textInput"] = "textInput",
}

function UnionCurrentStateView:onCreate()
	self:initModel()
	self:enableSchedule()
	self.selectJoinType = idler.new(self.joinType:read())
	self.textInput:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
	local desc = string.len(self.joinDesc:read()) > 0 and self.joinDesc:read() or gLanguageCsv.unionJoinupDesc
	self.textInput:text(desc)
	blacklist:addListener(self.textInput)
	self.limitNum = idler.new(self.joinLevel:read())
	self.maxLimitNum = table.length(gRoleLevelCsv)
	idlereasy.any({self.limitNum, self.selectJoinType},function(_,limitNum, selectJoinType)
		self.freeCheckBox:setSelectedState(selectJoinType == 1)
		self.needRequestCheckBox:setSelectedState(selectJoinType == 0)
		self.refuseCheckBox:setSelectedState(selectJoinType == 2)

		self.limitTxt:text(limitNum == 0 and gLanguageCsv.noLimitNoBrackets or limitNum)
		local coinColor = (limitNum == 0) and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.DEFAULT
		text.addEffect(self.limitTxt, {color = coinColor})

		local canSub = limitNum > 0 and selectJoinType ~= 2
		local canAdd = limitNum < self.maxLimitNum and selectJoinType ~= 2
		cache.setShader(self.btnSub, false, canSub and "normal" or  "hsl_gray")
		self.btnSub:setTouchEnabled(canSub)
		cache.setShader(self.btnAdd, false, canAdd and "normal" or  "hsl_gray")
		self.btnAdd:setTouchEnabled(canAdd)
	end)
	bind.touch(self, self.btnSub, {longtouch = true, method = function(view, node, event)
		return self:onLevelChangeTouch(event, -1)
	end})
	bind.touch(self, self.btnAdd, {longtouch = true, method = function(view, node, event)
		return self:onLevelChangeTouch(event, 1)
	end})
	Dialog.onCreate(self)
end
function UnionCurrentStateView:initModel()
	local unionInfo = gGameModel.union
	self.joinDesc = unionInfo:getIdler("join_desc")
	self.joinLevel = unionInfo:getIdler("join_level")
	self.joinType = unionInfo:getIdler("join_type")
end
--ok按钮
function UnionCurrentStateView:onClickOK()
	local text = self.textInput:text()
	if uiEasy.checkText(text) then
		gGameApp:requestServer("/game/union/join/modify", function (tb)
			gGameUI:showTip(gLanguageCsv.modifySuccessful)
			self:onClose()
		end, self.selectJoinType, self.limitNum, text)
	end
end
--自由加入复选框
function UnionCurrentStateView:onFree()
	self.selectJoinType:set(1)
end
--需要申请复选框
function UnionCurrentStateView:onNeedRequest()
	self.selectJoinType:set(0)
end
--拒绝加入复选框
function UnionCurrentStateView:onRefuse()
	self.selectJoinType:set(2)
end

--加减等级按钮
function UnionCurrentStateView:onLevelChange(step)
	local num = self.limitNum:read()
	self.limitNum:set(cc.clampf(num+step, 0, self.maxLimitNum))
end

function UnionCurrentStateView:onLevelChangeTouch(event, step)
	if event.name == "click" then
		self:unScheduleAll()
		self:onLevelChange(step)

	elseif event.name == "began" then
		self:schedule(function(dt)
			self:onLevelChange(step)
		end, 0.05, 0, 1)

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

return UnionCurrentStateView