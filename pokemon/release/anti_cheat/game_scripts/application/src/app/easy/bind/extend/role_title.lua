-- 人物称号
local helper = require "easy.bind.helper"

local roleTitle = class("roleTitle", cc.load("mvc").ViewBase)

roleTitle.defaultProps = {
	-- number or idler
	data = 1,
	-- node function
	onNode = nil,
	isGray = false,
}

function roleTitle:showData(titleId)
	local panelName = "_roleTitle_"
	local panel = self:get(panelName)
	if not titleId or titleId <= 0 then
		if panel then
			panel:hide()
		end
		return
	end
	if not panel then
		panel = ccui.Layout:create()
			:addTo(self, 1, panelName)

		ccui.ImageView:create()
			:addTo(panel, 2, "titleImgBg")
		ccui.ImageView:create()
			:addTo(panel, 3, "titleImg")

		label.create("", {
			fontPath = "font/youmi1.ttf",
			anchorPoint = cc.p(0.5, 0.5),
			fontSize = 33,
			effect = {outline = {color = cc.c4b(202, 126, 25, 255)}}
		}):addTo(panel, 3, "titleTxt")
	end
	panel:show()
	local cfg = gTitleCsv[titleId]
	local res = cfg.res
	local resBg = cfg.resBg
	local txt = cfg.title
	local showType = cfg.showType
	local titleImg = panel:get("titleImg")
	local titleImgBg = panel:get("titleImgBg")
	local titleTxt = panel:get("titleTxt")
	titleTxt:hide()
	titleImg:hide()
	titleImgBg:hide()
	if panel:get("spine") then
		panel:get("spine"):removeFromParent()
	end
	if showType == "pic" then
		titleImg:texture(res):show()
		local size
		if resBg then
			titleImgBg:texture(resBg):show()
			size = titleImgBg:size()
		else
			size = titleImg:size()
		end
		panel:size(size)
		titleImgBg:alignCenter(size)
		titleImg:alignCenter(size)
		titleImg:y(titleImgBg:y() - 10)
		cache.setShader(titleImg, false, self.isGray and "hsl_gray" or "normal")
		cache.setShader(titleImgBg, false, self.isGray and "hsl_gray" or "normal")
	elseif showType == "txt" then
		titleTxt:text(txt):show()
		titleImgBg:texture(resBg):show()
		text.deleteAllEffect(titleTxt)
		local size = titleImgBg:size()
		panel:size(size)
		titleImgBg:alignCenter(size)
		titleTxt:alignCenter(size)
		titleTxt:y(titleImgBg:y() - 11)
		cache.setShader(titleImgBg, false, self.isGray and "hsl_gray" or "normal")
		if self.isGray then
			text.addEffect(titleTxt, {outline = {color = cc.c4b(99,97,97,255), size = 4}, color = cc.c4b(235,235,235,255)})
		else
			text.addEffect(titleTxt, {outline = {color = cc.c4b(cfg.color[1],cfg.color[2],cfg.color[3],255), size = 4}})
		end

	elseif showType == "spine" then
		local spine = widget.addAnimationByKey(panel, cfg.res, "spine", "effect_loop", 1)
		-- local size = spine:getBoundingBox()
		local size = cc.size(cfg.spineSize[1], cfg.spineSize[2])
		spine:alignCenter(size)
		panel:size(size)
		cache.setShader(spine, false, self.isGray and "hsl_gray" or "normal")
		if self.isGray then
			spine:setTimeScale(0)
		end
	end

	panel:alignCenter(self:size())
	if self.onNode then
		self.onNode(panel)
	end
end

function roleTitle:initExtend()
	helper.callOrWhen(self.data, functools.partial(self.showData, self))
	return self
end

return roleTitle
