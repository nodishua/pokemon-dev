-- @date: 2019-07-03 17:15:34
-- @desc:设置界面兑换码弹窗

local SettingRedeemCodeView = class("SettingRedeemCodeView", Dialog)
SettingRedeemCodeView.RESOURCE_FILENAME = "setting_redeem_code.json"
SettingRedeemCodeView.RESOURCE_BINDING = {
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
			methods = {ended = bindHelper.self("onCancelBtn")},
		},
	},
	["btnComfirm"] = {
		varname = "btnComfirm",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onConfirmBtn")},
		},
	},
}

-- ascii 是数字
local function isNumber(num)
	return num >= 48 and num <= 57
end
-- ascii 是大写字母
local function isUpper(num)
	return num >= 65 and num <= 90
end
-- ascii 是小写字母
local function isLower(num)
	return num >= 97 and num <= 122
end

-- 限定字符在指定范围内
local function limitLanguageWord(str)
	local flag = false -- 标记是否有字符超出限定范围
	local idx = 1
	while idx <= #str do
		local curByte = string.byte(str, idx)
		local num = string.utf8charlen(curByte)
		local character = ""
		for i = 1, num do
			character = character .. string.format("%x", string.byte(str, idx+i-1, idx+i-1))
		end
		local number = tonumber(character, 16)
		local valid = isNumber(number) or isUpper(number) or isLower(number)-- 是否有效区内的字符
		if not valid then
			return true, {idx}
		end
		idx = idx + num
	end
	return false
end

local function removeOtherFromString(str)
	local repStr = ""
	local flag, t = limitLanguageWord(str)
	if flag then
		table.sort(t, function(a, b)
			return a > b
		end)
		for _, v in ipairs(t) do
			local len = string.utf8charlen(string.byte(str, v))
			str = string.sub(str, 1, v-1) .. repStr .. string.sub(str, v+len)
		end
	end

	return str
end

function SettingRedeemCodeView:onCreate()
	local input = self.textField
	input:addEventListener(function(sender, eventType)
		if eventType == ccui.TextFiledEventType.insert_text then
			input:setText(removeOtherFromString(input:text()))
		end
	end)
	-- blacklist:addListener(self.textField)
	self.textField:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
	self.textField:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	self.textField:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	Dialog.onCreate(self, {clickClose = false})
end

function SettingRedeemCodeView:onConfirmBtn()
	local str = self.textField:getStringValue()
	gGameApp:requestServer("/game/gift",function (tb)
		gGameUI:showGainDisplay(tb.view.award)
	end,str)
end

function SettingRedeemCodeView:onCancelBtn()
	self:onClose()
end

return SettingRedeemCodeView