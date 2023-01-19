--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 界面特效相关
--

globals.effect = {}

-- 静态的毛玻璃模糊效果
function effect.blurGlassScreen()
	local node = gGameUI.uiRoot
	local size = display.sizeInView
	local scale = 0.5
	local sp = cc.utils:captureNodeSprite(node, cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565, scale, display.uiOrigin.x, 0)
	sp:setScale(1.0 / scale)
	sp:setAnchorPoint(0.5, 0.5)

	-- cc.utils:captureNode(sp):saveToFile("Screen.png")

	-- 毛玻璃效果, 高斯模糊
	cache.setShader(sp, false, "gaussian_blur"):setUniformVec3("iResolution", cc.Vertex3F(size.width * scale, size.height * scale, 0))

	-- cc.utils:captureNode(sp):saveToFile("blurGlassScreen.png")

	sp:xy(display.center):addTo(node, 9999)

	local staicSP = cc.utils:captureNodeSprite(node, cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565, scale, display.uiOrigin.x, 0)
	staicSP:setScale(1.0 / scale)
	staicSP:setAnchorPoint(0.5, 0.5)
	sp:removeSelf()

	-- cc.utils:captureNode(staicSP):saveToFile("staicSP.png")

	return staicSP
end

function effect.captureNodeSprite(format, visit, after)
	-- cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565
	-- cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888
	-- cc.TEXTURE2_D_PIXEL_FORMAT_RG_B888
	-- local rt = cc.RenderTexture:create(display.sizeInView.width, display.sizeInView.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)
	local rt = cc.RenderTexture:create(display.sizeInPixels.width, display.sizeInPixels.height, format)
	rt:setKeepMatrix(true)
	rt:begin()
	visit()
	rt:endToLua()
	rt:drawOnce(true)
	if after then after() end
	-- rt:saveToFile("1111.png", true)
	-- rt:getSprite():getTexture():setAliasTexParameters()
	local sx = display.sizeInView.width / display.sizeInPixels.width
	local sy = display.sizeInView.height / display.sizeInPixels.height
	return rt:getSprite():scale(sx, sy):x(-display.uiOrigin.x):removeSelf()
end

function effect.captureForBackgroud(parent, ...)
	local nodes = {...}
	performWithDelay(parent, function()
		local bgSprite = effect.captureNodeSprite(cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565, function()
			for _, node in ipairs(nodes) do
				node:visit()
			end
		end)
		for _, node in ipairs(nodes) do
			node:hide()
		end
		parent:add(bgSprite, -9999)
	end, 2)
end