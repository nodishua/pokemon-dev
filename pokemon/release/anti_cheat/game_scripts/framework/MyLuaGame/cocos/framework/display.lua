--[[

Copyright (c) 2014-2017 Chukong Technologies Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

-- 分配率适配定义
-- 标准屏: 出血线+边距border
local STANDARD_BLEEDING_LINE = 60
local STANDARD_BORDER = 32
-- 全面屏:（分辨率比大于等于2） 安全区+出血线+边距
local FULLSCREEN_SAFEAREA = 114
local FULLSCREEN_BLEEDING_LINE = 60
local FULLSCREEN_BORDER = 66

local display = {}

local director = cc.Director:getInstance()
local view = director:getOpenGLView()
display.director = director
display.textureCache = director:getTextureCache()

if not view then
	local width = 1280
	local height = 720
	if CC_DESIGN_RESOLUTION then
		if CC_DESIGN_RESOLUTION.width then
			width = CC_DESIGN_RESOLUTION.width
		end
		if CC_DESIGN_RESOLUTION.height then
			height = CC_DESIGN_RESOLUTION.height
		end
	end
	view = cc.GLViewImpl:createWithRect("Cocos2d-Lua", cc.rect(0, 0, width, height))
	director:setOpenGLView(view)
end

local framesize = view:getFrameSize()
local textureCache = director:getTextureCache()
local spriteFrameCache = cc.SpriteFrameCache:getInstance()
local animationCache = cc.AnimationCache:getInstance()

-- auto scale
local function checkResolution(r)
	r.width = checknumber(r.width)
	r.height = checknumber(r.height)
	r.autoscale = string.upper(r.autoscale)
	assert(r.width > 0 and r.height > 0,
		string.format("display - invalid design resolution size %d, %d", r.width, r.height))
end

local function setDesignResolution(r, framesize)
	if r.autoscale == "FILL_ALL" then
		r.policy = cc.ResolutionPolicy.FILL_ALL
		view:setDesignResolutionSize(framesize.width, framesize.height, cc.ResolutionPolicy.FILL_ALL)
	else
		local scaleX, scaleY = framesize.width / r.width, framesize.height / r.height
		local width, height = framesize.width, framesize.height
		if r.autoscale == "FIXED_WIDTH" then
			width = framesize.width / scaleX
			height = framesize.height / scaleX
			r.policy = cc.ResolutionPolicy.NO_BORDER
			view:setDesignResolutionSize(width, height, cc.ResolutionPolicy.NO_BORDER)
		elseif r.autoscale == "FIXED_HEIGHT" then
			width = framesize.width / scaleY
			height = framesize.height / scaleY
			r.policy = cc.ResolutionPolicy.NO_BORDER
			view:setDesignResolutionSize(width, height, cc.ResolutionPolicy.NO_BORDER)
		elseif r.autoscale == "EXACT_FIT" then
			r.policy = cc.ResolutionPolicy.EXACT_FIT
			view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.EXACT_FIT)
		elseif r.autoscale == "NO_BORDER" then
			r.policy = cc.ResolutionPolicy.NO_BORDER
			view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.NO_BORDER)
		elseif r.autoscale == "SHOW_ALL" then
			r.policy = cc.ResolutionPolicy.SHOW_ALL
			view:setDesignResolutionSize(r.width, r.height, cc.ResolutionPolicy.SHOW_ALL)
		else
			printError(string.format("display - invalid r.autoscale \"%s\"", r.autoscale))
		end
	end
end

local function setConstants(configs)
	local sizeInPixels = view:getFrameSize()
	display.sizeInPixels = {width = sizeInPixels.width, height = sizeInPixels.height}

	-- FIXED_HEIGHT viewsize will be > configs.size, see setDesignResolution, viewsize = configs.size + border size
	local viewsize = director:getWinSize()
	display.sizeInView         = {width = viewsize.width, height = viewsize.height}
	-- board_left and board_right x position relative to viewLayer
	display.board_left         = -display.uiOrigin.x
	display.board_right        = configs.width + display.uiOrigin.x
	-- our art design size, see cocos studio UI canvas
	display.contentScaleFactor = director:getContentScaleFactor()
	display.size               = {width = configs.width, height = configs.height}
	display.width              = display.size.width
	display.height             = display.size.height
	display.maxWidth           = configs.maxWidth
	display.cx                 = display.width / 2
	display.cy                 = display.height / 2
	display.c_left             = -display.width / 2
	display.c_right            = display.width / 2
	display.c_top              = display.height / 2
	display.c_bottom           = -display.height / 2
	display.left               = 0
	display.right              = display.width
	display.top                = display.height
	display.bottom             = 0
	display.center             = cc.p(display.cx, display.cy)
	display.left_top           = cc.p(display.left, display.top)
	display.left_bottom        = cc.p(display.left, display.bottom)
	display.left_center        = cc.p(display.left, display.cy)
	display.right_top          = cc.p(display.right, display.top)
	display.right_bottom       = cc.p(display.right, display.bottom)
	display.right_center       = cc.p(display.right, display.cy)
	display.top_center         = cc.p(display.cx, display.top)
	display.bottom_center      = cc.p(display.cx, display.bottom)
	-- 设备会有超过最大设计分辨率的，可见区域设置
	display.sizeInViewRect     = cc.rect(display.uiOrigin.x - display.uiOriginMax.x, 0, display.width + display.uiOriginMax.x * 2, display.height)

	local safeAreaRect = display.director:getSafeAreaRect()
	display.fullScreenSafeArea = FULLSCREEN_SAFEAREA
	-- 若安全区域 x 大于等于 FULLSCREEN_SAFEAREA ，则用默认的安全区域
	if safeAreaRect.x >= FULLSCREEN_SAFEAREA then
		-- display.fullScreenSafeArea = safeAreaRect.x
		display.isNotchSceen = 1
	end
	display.fullScreenDiffX = display.fullScreenSafeArea + FULLSCREEN_BLEEDING_LINE + FULLSCREEN_BORDER - (STANDARD_BLEEDING_LINE + STANDARD_BORDER)
	-- 刘海屏补差，sdk 接入后设置
	display.notchSceenSafeArea = 0
	display.notchSceenDiffX = 0
	local flag = cc.UserDefault:getInstance():getBoolForKey("isNotchScreen", false)
	if device.model == "iphone x" or flag then
		display.notchSceenSafeArea = display.fullScreenSafeArea
		display.notchSceenDiffX = display.fullScreenDiffX
	end

	printInfo("# display.sizeInPixels         = {width = %0.2f, height = %0.2f}", display.sizeInPixels.width, display.sizeInPixels.height)
	printInfo("# display.sizeInView           = {width = %0.2f, height = %0.2f}", display.sizeInView.width, display.sizeInView.height)
	printInfo("# display.size                 = {width = %0.2f, height = %0.2f}", display.size.width, display.size.height)
	printInfo("# display.sizeInViewRect       = {x = %0.2f, y = %0.2f, width = %0.2f, height = %0.2f}", display.sizeInViewRect.x, display.sizeInViewRect.y, display.sizeInViewRect.width, display.sizeInViewRect.height)
	printInfo("# display.maxWidth             = %0.2f", display.maxWidth)
	printInfo("# display.board_left           = %0.2f", display.board_left)
	printInfo("# display.board_right          = %0.2f", display.board_right)
	printInfo("# display.contentScaleFactor   = %0.2f", display.contentScaleFactor)
	printInfo("# display.width                = %0.2f", display.width)
	printInfo("# display.height               = %0.2f", display.height)
	printInfo("# display.cx                   = %0.2f", display.cx)
	printInfo("# display.cy                   = %0.2f", display.cy)
	printInfo("# display.left                 = %0.2f", display.left)
	printInfo("# display.right                = %0.2f", display.right)
	printInfo("# display.top                  = %0.2f", display.top)
	printInfo("# display.bottom               = %0.2f", display.bottom)
	printInfo("# display.c_left               = %0.2f", display.c_left)
	printInfo("# display.c_right              = %0.2f", display.c_right)
	printInfo("# display.c_top                = %0.2f", display.c_top)
	printInfo("# display.c_bottom             = %0.2f", display.c_bottom)
	printInfo("# display.center               = {x = %0.2f, y = %0.2f}", display.center.x, display.center.y)
	printInfo("# display.left_top             = {x = %0.2f, y = %0.2f}", display.left_top.x, display.left_top.y)
	printInfo("# display.left_bottom          = {x = %0.2f, y = %0.2f}", display.left_bottom.x, display.left_bottom.y)
	printInfo("# display.left_center          = {x = %0.2f, y = %0.2f}", display.left_center.x, display.left_center.y)
	printInfo("# display.right_top            = {x = %0.2f, y = %0.2f}", display.right_top.x, display.right_top.y)
	printInfo("# display.right_bottom         = {x = %0.2f, y = %0.2f}", display.right_bottom.x, display.right_bottom.y)
	printInfo("# display.right_center         = {x = %0.2f, y = %0.2f}", display.right_center.x, display.right_center.y)
	printInfo("# display.top_center           = {x = %0.2f, y = %0.2f}", display.top_center.x, display.top_center.y)
	printInfo("# display.bottom_center        = {x = %0.2f, y = %0.2f}", display.bottom_center.x, display.bottom_center.y)

	printInfo("# display.uiOrigin             = {x = %0.2f, y = %0.2f}", display.uiOrigin.x, display.uiOrigin.y)
	printInfo("# display.uiOriginMax          = {x = %0.2f, y = %0.2f}", display.uiOriginMax.x, display.uiOriginMax.y)
	printInfo("# display.fullScreenSafeArea   = %d", display.fullScreenSafeArea)
	printInfo("# display.fullScreenDiffX      = %d", display.fullScreenDiffX)
	printInfo("# display.notchSceenSafeArea   = %d", display.notchSceenSafeArea)
	printInfo("# display.notchSceenDiffX      = %d", display.notchSceenDiffX)
	printInfo("# director:getSafeAreaRect     = {x = %0.2f, y = %0.2f, width = %0.2f, height = %0.2f}", safeAreaRect.x, safeAreaRect.y, safeAreaRect.width, safeAreaRect.height)
	printInfo("#")
end

function display.setAutoScale(configs)
	if type(configs) ~= "table" then return end

	checkResolution(configs)
	if type(configs.callback) == "function" then
		local c = configs.callback(display, framesize)
		for k, v in pairs(c or {}) do
			configs[k] = v
		end
		checkResolution(configs)
	end

	setDesignResolution(configs, framesize)

	printInfo("# design resolution size       = {width = %0.2f, height = %0.2f}", configs.width, configs.height)
	printInfo("# design resolution autoscale  = %s", configs.autoscale)
	setConstants(configs)
end

if type(CC_DESIGN_RESOLUTION) == "table" then
	display.setAutoScale(CC_DESIGN_RESOLUTION)
end

display.COLOR_WHITE = cc.c3b(255, 255, 255)
display.COLOR_BLACK = cc.c3b(0, 0, 0)
display.COLOR_RED   = cc.c3b(255, 0, 0)
display.COLOR_GREEN = cc.c3b(0, 255, 0)
display.COLOR_BLUE  = cc.c3b(0, 0, 255)

display.AUTO_SIZE      = 0
display.FIXED_SIZE     = 1
display.LEFT_TO_RIGHT  = 0
display.RIGHT_TO_LEFT  = 1
display.TOP_TO_BOTTOM  = 2
display.BOTTOM_TO_TOP  = 3

display.CENTER        = cc.p(0.5, 0.5)
display.LEFT_TOP      = cc.p(0, 1)
display.LEFT_BOTTOM   = cc.p(0, 0)
display.LEFT_CENTER   = cc.p(0, 0.5)
display.RIGHT_TOP     = cc.p(1, 1)
display.RIGHT_BOTTOM  = cc.p(1, 0)
display.RIGHT_CENTER  = cc.p(1, 0.5)
display.CENTER_TOP    = cc.p(0.5, 1)
display.CENTER_BOTTOM = cc.p(0.5, 0)

display.SCENE_TRANSITIONS = {
	CROSSFADE       = {cc.TransitionCrossFade},
	FADE            = {cc.TransitionFade, cc.c3b(0, 0, 0)},
	FADEBL          = {cc.TransitionFadeBL},
	FADEDOWN        = {cc.TransitionFadeDown},
	FADETR          = {cc.TransitionFadeTR},
	FADEUP          = {cc.TransitionFadeUp},
	FLIPANGULAR     = {cc.TransitionFlipAngular, cc.TRANSITION_ORIENTATION_LEFT_OVER},
	FLIPX           = {cc.TransitionFlipX, cc.TRANSITION_ORIENTATION_LEFT_OVER},
	FLIPY           = {cc.TransitionFlipY, cc.TRANSITION_ORIENTATION_UP_OVER},
	JUMPZOOM        = {cc.TransitionJumpZoom},
	MOVEINB         = {cc.TransitionMoveInB},
	MOVEINL         = {cc.TransitionMoveInL},
	MOVEINR         = {cc.TransitionMoveInR},
	MOVEINT         = {cc.TransitionMoveInT},
	PAGETURN        = {cc.TransitionPageTurn, false},
	ROTOZOOM        = {cc.TransitionRotoZoom},
	SHRINKGROW      = {cc.TransitionShrinkGrow},
	SLIDEINB        = {cc.TransitionSlideInB},
	SLIDEINL        = {cc.TransitionSlideInL},
	SLIDEINR        = {cc.TransitionSlideInR},
	SLIDEINT        = {cc.TransitionSlideInT},
	SPLITCOLS       = {cc.TransitionSplitCols},
	SPLITROWS       = {cc.TransitionSplitRows},
	TURNOFFTILES    = {cc.TransitionTurnOffTiles},
	ZOOMFLIPANGULAR = {cc.TransitionZoomFlipAngular},
	ZOOMFLIPX       = {cc.TransitionZoomFlipX, cc.TRANSITION_ORIENTATION_LEFT_OVER},
	ZOOMFLIPY       = {cc.TransitionZoomFlipY, cc.TRANSITION_ORIENTATION_UP_OVER},
}

display.TEXTURES_PIXEL_FORMAT = {}

display.DEFAULT_TTF_FONT        = "Arial"
display.DEFAULT_TTF_FONT_SIZE   = 32

local PARAMS_EMPTY = {}
local RECT_ZERO = cc.rect(0, 0, 0, 0)

local sceneIndex = 0
function display.newScene(name, params)
	params = params or PARAMS_EMPTY
	sceneIndex = sceneIndex + 1
	local scene
	if not params.physics then
		scene = cc.Scene:create()
	else
		scene = cc.Scene:createWithPhysics()
	end
	scene.name_ = string.format("%s:%d", name or "<unknown-scene>", sceneIndex)

	if params.transition then
		scene = display.wrapSceneWithTransition(scene, params.transition, params.time, params.more)
	end

	return scene
end

function display.wrapScene(scene, transition, time, more)
	local key = string.upper(tostring(transition))

	if key == "RANDOM" then
		local keys = table.keys(display.SCENE_TRANSITIONS)
		key = keys[math.random(1, #keys)]
	end

	if display.SCENE_TRANSITIONS[key] then
		local t = display.SCENE_TRANSITIONS[key]
		local cls = t[1]
		time = time or 0.2
		more = more or t[2]
		if more ~= nil then
			scene = cls:create(time, scene, more)
		else
			scene = cls:create(time, scene)
		end
	else
		error(string.format("display.wrapScene() - invalid transition %s", tostring(transition)))
	end
	return scene
end

function display.runScene(newScene, transition, time, more)
	if director:getRunningScene() then
		if transition then
			newScene = display.wrapScene(newScene, transition, time, more)
		end
		director:replaceScene(newScene)
	else
		director:runWithScene(newScene)
	end
end

function display.getRunningScene()
	return director:getRunningScene()
end

function display.newNode()
	return cc.Node:create()
end

function display.newLayer(...)
	local params = {...}
	local c = #params
	local layer
	if c == 0 then
		-- /** creates a fullscreen black layer */
		-- static Layer *create();
		layer = cc.Layer:create()
	elseif c == 1 then
		-- /** creates a Layer with color. Width and height are the window size. */
		-- static LayerColor * create(const Color4B& color);
		layer = cc.LayerColor:create(cc.convertColor(params[1], "4b"))
	elseif c == 2 then
		-- /** creates a Layer with color, width and height in Points */
		-- static LayerColor * create(const Color4B& color, const Size& size);
		--
		-- /** Creates a full-screen Layer with a gradient between start and end. */
		-- static LayerGradient* create(const Color4B& start, const Color4B& end);
		local color1 = cc.convertColor(params[1], "4b")
		local p2 = params[2]
		assert(type(p2) == "table" and (p2.width or p2.r), "display.newLayer() - invalid paramerter 2")
		if p2.r then
			layer = cc.LayerGradient:create(color1, cc.convertColor(p2, "4b"))
		else
			layer = cc.LayerColor:create(color1, p2.width, p2.height)
		end
	elseif c == 3 then
		-- /** creates a Layer with color, width and height in Points */
		-- static LayerColor * create(const Color4B& color, GLfloat width, GLfloat height);
		--
		-- /** Creates a full-screen Layer with a gradient between start and end in the direction of v. */
		-- static LayerGradient* create(const Color4B& start, const Color4B& end, const Vec2& v);
		local color1 = cc.convertColor(params[1], "4b")
		local p2 = params[2]
		local p2type = type(p2)
		if p2type == "table" then
			layer = cc.LayerGradient:create(color1, cc.convertColor(p2, "4b"), params[3])
		else
			layer = cc.LayerColor:create(color1, p2, params[3])
		end
	end
	return layer
end

function display.newSprite(source, x, y, params)
	local spriteClass = cc.Sprite
	local scale9 = false

	if type(x) == "table" and not x.x then
		-- x is params
		params = x
		x = nil
		y = nil
	end

	local params = params or PARAMS_EMPTY
	if params.scale9 or params.capInsets then
		spriteClass = ccui.Scale9Sprite
		scale9 = true
		params.capInsets = params.capInsets or RECT_ZERO
		params.rect = params.rect or RECT_ZERO
	end

	local sprite
	while true do
		-- create sprite
		if not source then
			sprite = spriteClass:create()
			break
		end

		local sourceType = type(source)
		if sourceType == "string" then
			if string.byte(source) == 35 then -- first char is #
				-- create sprite from spriteFrame
				if not scale9 then
					sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2))
				else
					sprite = spriteClass:createWithSpriteFrameName(string.sub(source, 2), params.capInsets)
				end
				break
			end

			-- create sprite from image file
			if display.TEXTURES_PIXEL_FORMAT[source] then
				cc.Texture2D:setDefaultAlphaPixelFormat(display.TEXTURES_PIXEL_FORMAT[source])
			end
			if not scale9 then
				sprite = spriteClass:create(source)
			else
				sprite = spriteClass:create(source, params.rect, params.capInsets)
			end
			if display.TEXTURES_PIXEL_FORMAT[source] then
				cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
			end
			break
		elseif sourceType ~= "userdata" then
			error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
		else
			sourceType = tolua.type(source)
			if sourceType == "cc.SpriteFrame" then
				if not scale9 then
					sprite = spriteClass:createWithSpriteFrame(source)
				else
					sprite = spriteClass:createWithSpriteFrame(source, params.capInsets)
				end
			elseif sourceType == "cc.Texture2D" then
				sprite = spriteClass:createWithTexture(source)
			else
				error(string.format("display.newSprite() - invalid source type \"%s\"", sourceType), 0)
			end
		end
		break
	end

	if sprite then
		if x and y then sprite:setPosition(x, y) end
		if params.size then sprite:setContentSize(params.size) end
	else
		error(string.format("display.newSprite() - create sprite failure, source \"%s\"", tostring(source)), 0)
	end

	return sprite
end

function display.newSpriteFrame(source, ...)
	local frame
	if type(source) == "string" then
		if string.byte(source) == 35 then -- first char is #
			source = string.sub(source, 2)
		end
		frame = spriteFrameCache:getSpriteFrame(source)
		if not frame then
			error(string.format("display.newSpriteFrame() - invalid frame name \"%s\"", tostring(source)), 0)
		end
	elseif tolua.type(source) == "cc.Texture2D" then
		frame = cc.SpriteFrame:createWithTexture(source, ...)
	else
		error("display.newSpriteFrame() - invalid parameters", 0)
	end
	return frame
end

function display.newFrames(pattern, begin, length, isReversed)
	local frames = {}
	local step = 1
	local last = begin + length - 1
	if isReversed then
		last, begin = begin, last
		step = -1
	end

	for index = begin, last, step do
		local frameName = string.format(pattern, index)
		local frame = spriteFrameCache:getSpriteFrame(frameName)
		if not frame then
			error(string.format("display.newFrames() - invalid frame name %s", tostring(frameName)), 0)
		end
		frames[#frames + 1] = frame
	end
	return frames
end

local function newAnimation(frames, time)
	local count = #frames
	assert(count > 0, "display.newAnimation() - invalid frames")
	time = time or 1.0 / count
	return cc.Animation:createWithSpriteFrames(frames, time),
		   cc.Sprite:createWithSpriteFrame(frames[1])
end

function display.newAnimation(...)
	local params = {...}
	local c = #params
	if c == 2 then
		-- frames, time
		return newAnimation(params[1], params[2])
	elseif c == 4 then
		-- pattern, begin, length, time
		local frames = display.newFrames(params[1], params[2], params[3])
		return newAnimation(frames, params[4])
	elseif c == 5 then
		-- pattern, begin, length, isReversed, time
		local frames = display.newFrames(params[1], params[2], params[3], params[4])
		return newAnimation(frames, params[5])
	else
		error("display.newAnimation() - invalid parameters")
	end
end

function display.loadImage(imageFilename, callback)
	if not callback then
		return textureCache:addImage(imageFilename)
	else
		textureCache:addImageAsync(imageFilename, callback)
	end
end

local fileUtils = cc.FileUtils:getInstance()
function display.getImage(imageFilename)
	-- local fullpath = fileUtils:fullPathForFilename(imageFilename)
	return textureCache:getTextureForKey(imageFilename)
end

function display.removeImage(imageFilename)
	textureCache:removeTextureForKey(imageFilename)
end

function display.loadSpriteFrames(dataFilename, imageFilename, callback)
	if display.TEXTURES_PIXEL_FORMAT[imageFilename] then
		cc.Texture2D:setDefaultAlphaPixelFormat(display.TEXTURES_PIXEL_FORMAT[imageFilename])
	end
	if not callback then
		spriteFrameCache:addSpriteFrames(dataFilename, imageFilename)
	else
		spriteFrameCache:addSpriteFramesAsync(dataFilename, imageFilename, callback)
	end
	if display.TEXTURES_PIXEL_FORMAT[imageFilename] then
		cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_BGR_A8888)
	end
end

function display.removeSpriteFrames(dataFilename, imageFilename)
	spriteFrameCache:removeSpriteFramesFromFile(dataFilename)
	if imageFilename then
		display.removeImage(imageFilename)
	end
end

function display.removeSpriteFrame(imageFilename)
	spriteFrameCache:removeSpriteFrameByName(imageFilename)
end

function display.setTexturePixelFormat(imageFilename, format)
	display.TEXTURES_PIXEL_FORMAT[imageFilename] = format
end

function display.setAnimationCache(name, animation)
	animationCache:addAnimation(animation, name)
end

function display.getAnimationCache(name)
	return animationCache:getAnimation(name)
end

function display.removeAnimationCache(name)
	animationCache:removeAnimation(name)
end

function display.removeUnusedSpriteFrames()
	spriteFrameCache:removeUnusedSpriteFrames()
	textureCache:removeUnusedTextures()
end

return display
