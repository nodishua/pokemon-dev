

local CHANGE_TYPE = {
	--卡牌改名
	["card"] = "/game/card/rename",
	--训练家改名
	["role"] = "/game/role/rename",
	--公会改名
	["union"] = "/game/union/rename",
	--预设队伍改名
	["ready"] = "/game/ready/card/rename",
	-- 芯片方案改名
	["plan"] = "/game/chip/plan/edit",
}
local CardChangeNameView = class("CardChangeNameView", Dialog)

CardChangeNameView.RESOURCE_FILENAME = "card_changename.json"
CardChangeNameView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["cancelBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["sureBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")},
		},
	},
	["titleTxt"] = "titleTxt",
	["txt"] = {
		binds = {
			{
				event = "effect",
				data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
			},{
				event = "visible",
				idler = bindHelper.self("showCenterTxt"),
			}
		}
	},
	["bg.nameBg"] = "nameBg",
	["nameField"] = "nameField",
	["diamondNum"] = "diamondNum",
	["diamondImg"] = "diamondImg",
	["diamondTxt"] = "diamondTxt",
}

-- params.maxFontCount 显示最长中文个数，对应的长度限制
function CardChangeNameView:onCreate(params)
	self:initModel()
	self.params = params
	self.curName = params.name
	self.textWidth = params.maxFontCount and math.min(params.maxFontCount*40 , 300) or 300
	self.titleTxt:text(params.titleTxt)
	self.nameField:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
	self.nameField:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	self.nameField:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	if self.params.typ == "ready" or not params.cost then
		self.diamondTxt:visible(false)
		self.diamondNum:visible(false)
		self.diamondImg:visible(false)
		self:addListener(self.nameField, functools.partial(self.nameAdapt, self))
		self.nameBg:y(self.nameBg:y()-60)
		self.nameField:y(self.nameField:y()-60)
	else
		blacklist:addListener(self.nameField, nil, functools.partial(self.nameAdapt, self))
		self.diamondNum:text(params.cost)
		idlereasy.when(gGameModel.role:getIdler('rmb'), function(_, rmb)
			self.diamondNum:setTextColor((params.cost > 0 and params.cost > rmb) and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT)
		end)
		adapt.oneLinePos(self.diamondNum, self.diamondImg, cc.p(5, 0))
	end
	Dialog.onCreate(self, {clickClose = false})
end

function CardChangeNameView:initModel()
	self.rmb = gGameModel.role:getIdler("rmb")
	self.renameCount = gGameModel.role:getIdler("rename_count")
end

function CardChangeNameView:nameAdapt(txt)
	txt = txt or self.nameField:text()
	local str = beauty.singleTextLimitWord(txt, {fontSize = 40}, {width = self.textWidth, replaceStr = "", onlyText = true})
	self.nameField:text(str)
end

function CardChangeNameView:onSureClick()
	-- 华为浮框输入法可以不点确认输入，直接按游戏中的确认
	self:nameAdapt()
	local text = self.nameField:text()
	local params = {name = self.curName, cost = self.params.cost}
	params.noBlackList = self.params.noBlackList
	if self.params.typ == "ready" then
		params = {name = self.curName, cost = self.params.cost, noBlackList = true}
	end
	if uiEasy.checkText(text, params) then
		if not self.params.customCheck or self.params.customCheck(text) then
			local function cb()
				--修改角色名
				sdk.commitRoleInfo(8,function()
					print("sdk commitRoleInfo CardChangeName")
				end)
				local requestParams = self.params.requestParams or {}
				if not self.params.requestParamsCount then
					table.insert(requestParams, text)
				else
					requestParams[self.params.requestParamsCount + 1] = text
				end
				gGameApp:requestServer(CHANGE_TYPE[self.params.typ], function(tb)
					local cb = self.params.cb
					self:onClose()
					if self.params.typ=='role' then
						sdk.commitRoleInfo(8,function()
							print("sdk commitRoleInfo CardChangeName")
						end)
					end
					if cb then
						cb(self.nameField:text())
					end
				end, unpack(requestParams, 1, table.maxn(requestParams)))
			end
			if self.params.cost and self.params.cost > 0 then
				dataEasy.sureUsingDiamonds(cb, self.params.cost)
			else
				cb()
			end
		end
	end
end

local function listenerEventTigger(eventType)
	if eventType == ccui.TextFiledEventType.detach_with_ime then
		return true
	end
	if device.platform == "windows" then
		if eventType == ccui.TextFiledEventType.insert_text or eventType == ccui.TextFiledEventType.delete_backward then
			return true
		end
	end
end

-- 输入结束时处理回调 cb, 做一些显示处理
function CardChangeNameView:addListener(input, cb)
	input:addEventListener(function(sender, eventType)
		local name = input:text()
		if listenerEventTigger(eventType) then
			if cb then
				cb(name)
			end
		end
	end)
end

return CardChangeNameView
