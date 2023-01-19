--
-- @desc textAtlas 组件
--
local helper = require "easy.bind.helper"
local textAtlasHelper = require "app.easy.bind.helper.text_atlas"

local textAtlas = class("textAtlas", cc.load("mvc").ViewBase)

textAtlas.defaultProps = {
	-- type:string 、 number or idler
	data = nil,
	pathName = nil,
	-- 是否等距
	isEqualDist = false,
	onNode = nil,
	-- 默认左对齐 "left", "center", "right"
	align = "left",
}

function textAtlas:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end
	local panel = ccui.Layout:create()
		:setTouchEnabled(false)
		:addTo(self, 1, "_textAtlas_")
	self.panel = panel
	local anchorPoint = cc.p(0.5, 0.5)
	if self.align == "left" then
		anchorPoint.x = 0
	elseif self.align == "right" then
		anchorPoint.x = 1
	end
	panel:align(anchorPoint)

	local datas = textAtlasHelper.findFileInfoByPathName(self.pathName)
	if not datas then
		return
	end
	local width = datas.width
	local height = datas.height
	local rect = datas.rect or {}
	local changeText = datas.changeText or ''
	local path = string.format("font/digital_%s.png", self.pathName)

	helper.callOrWhen(self.data, function(data)
		self.panel:removeAllChildren()
		local panel = self.panel
		data = tostring(data)
		-- 顺序是根据ASCII码表进行排序的 转换成对应的ASCII
		for i=1,string.len(changeText) do
			local char = string.sub(changeText, i, i)
			local bt = string.byte(char)
			-- 除了a-z 和 A-Z之外的都加转义符
			if bt < 65 or (bt > 90 and bt < 97) or bt > 122 then
				char = "%" .. char
			end
			data = string.gsub(data, char, string.char(57 + i))
		end
		if self.isEqualDist then
			local label = cc.LabelAtlas:_create(data, path, width, height, string.byte('0'))
				:addTo(panel)
			panel:size(label:size())
		else
			local textWidth = 0
			for i=1,string.len(data) do
				local str = string.sub(data, i, i)
				local number = tonumber(str)
				local idx = number and number + 1 or string.byte(str) - string.byte(9) + 10
				local w = rect[str] or width
				-- < 0 其实就是数据错误 这里做个保护
				local distance = math.max(width - w, 0)
				local label = cc.Sprite:create(path)
					:setTextureRect(cc.rect((idx - 1) * width + distance / 2, 0, w , height))
					:align(cc.p(0, 0.5))
					:xy(cc.p(textWidth, height / 2))
					:addTo(panel)
				textWidth = textWidth + w
			end
			panel:size(cc.size(textWidth, height))
		end
		if self.onNode then
			self.onNode(panel)
		end
	end)
	return self
end

return textAtlas