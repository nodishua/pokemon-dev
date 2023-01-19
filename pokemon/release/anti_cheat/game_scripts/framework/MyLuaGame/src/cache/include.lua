--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- 各种缓存的导出接口
--

local cache = {}
globals.cache = cache

local insert = table.insert
local remove = table.remove

local textureCache = display.director:getTextureCache()

local widgetCache = require("cache.widget")
local cspriteCache = require("cache.sprite").new()
local shaderCache = require("cache.shader")
local texCache = require("cache.texture")
local redHintCache = require("cache.red_hint").new()
local userDefaultCache = require("cache.user_default").new()


function cache.init()
	shaderCache.init()
	redHintCache:init()
end

--
-- widget
--

function cache.createWidget(res)
	return widgetCache.getWidget(res)
end

--
-- formula
--

local formulaCache = {}
function cache.createFormula(s, key)
	if s == nil then return nil end
	local formula = key and formulaCache[key]
	if formula == nil then
		if s:find("return ") then
			formula = assert(loadstring(s))
		else
			formula = assert(loadstring("return ".. s))
		end
		if key then
			formulaCache[key] = formula
		end
	end
	return formula
end

--
-- CSprite
--

function cache.addCSprite(sprite, autoRelease)
	return cspriteCache:insert(sprite, autoRelease)
end

function cache.getCSprite(spriteID)
	return cspriteCache:find(spriteID)
end

function cache.eraseCSprite(sprite, cb)
	cspriteCache:erase(sprite.spriteID, cb)
end

function cache.setCSpriteLifeTime(sprite, time)
	cspriteCache:setLifeTime(sprite.spriteID, time)
end

--
-- shader
--

function globals.shaderReloadForAndroid()
	print("---- shaderReloadForAndroid ----")
	shaderCache.reload()
end

function cache.setHSLShader(sprite, isSpine, hue, saturation, brightness, alpha, time, switch, samp)
	local state = shaderCache.getShader(isSpine, "hsl")

	state:setUniformFloat("fhue", hue)
	state:setUniformFloat("saturation", saturation)
	state:setUniformFloat("brightness", brightness)
	state:setUniformFloat("alpha", alpha or 1)
	state:setUniformFloat("time", time or 1)
	state:setUniformInt("programSwitch", switch or 1)

	cache.setShader(sprite, isSpine, nil, state)

	return state
end

function cache.setShihuaShader(sprite, isSpine, brightness)
	local state = shaderCache.getShader(isSpine, "shihua", true)
	-- 石化效果
	local texture = display.director:getTextureCache():addImage("battle/wenli/shihua.png")
	state:setUniformTexture("u_texture", texture)
	state:setUniformFloat("brightness", brightness or 1)
	state:setUniformVec2("samp", cc.vertex2F(40,30))

	cache.setShader(sprite, isSpine, nil, state)

	return state
end

function cache.setColor2Shader(sprite, isSpine, color)
	local state = shaderCache.getShader(isSpine, "color2")
	state:setUniformVec4("color", color)
	cache.setShader(sprite, isSpine, nil, state)
	return state
end

function cache.setShader(sprite, isSpine, shaderName, state)
	state = state or shaderCache.getShader(isSpine, shaderName)
	-- for Button
	if sprite.getRendererNormal then
		sprite:getRendererNormal():setGLProgramState(state)
	else
		sprite:setGLProgramState(state)
	end

	local children = sprite:getChildren()
	for k, v in pairs(children) do
		cache.setShader(v, isSpine, shaderName, state)
	end
	return state
end

cache.getShader = shaderCache.getShader


--
-- texture
--

cache.getTextureAsync = texCache.getAsync
cache.getTexture = texCache.get
cache.addTexturePreload = texCache.addPreload
cache.resetTexturePreload = texCache.resetPreload
cache.texturePreload = texCache.preload

--
-- red_hint
--

cache.queryRedHint = handler(redHintCache, "query")
cache.updateRedHint = handler(redHintCache, "update")

--
-- user_default
--

cache.queryUserDefault = handler(userDefaultCache, "query")
cache.updateUserDefault = handler(userDefaultCache, "update")
cache.cleanUserDefault = handler(userDefaultCache, "clean")
cache.userDefaultCache = userDefaultCache

--
-- common
--

local simpleCache = {}
function cache.addByKey(key, obj)
	if obj.retain then
		obj:retain()
	end
	if simpleCache[key] then
		insert(simpleCache[key], obj)
	else
		simpleCache[key] = {obj}
	end
	log.cache.addByKey(key, tostring(obj))
end

function cache.popByKey(key)
	if simpleCache[key] then
		local obj = remove(simpleCache[key])
		if obj then
			log.cache.popByKey(key, tostring(obj))
			if obj.autorelease then
				obj:autorelease()
			end
		end
		return obj
	end
	return nil
end

function cache.onBattleClear(remove)
	-- print('------ onBattleClear begin', remove)
	-- print(display.textureCache:getCachedTextureInfo())

	-- newCSprite只用于战斗
	cspriteCache:clear()
	for k, t in pairs(simpleCache) do
		for _, obj in ipairs(t) do
			log.cache.onBattleClear(k, tostring(obj), obj.getReferenceCount and obj:getReferenceCount())
			if obj.autorelease then
				obj:autorelease()
			end
		end
	end
	simpleCache = {}

	-- see onCleanCache
	-- 某些spine仍然有引用，等几帧再清理，0.1s只是预估值
	if remove then
		performWithDelay(gGameUI.scene, function()
			display.textureCache:removeUnusedTextures()
			-- print(display.textureCache:getCachedTextureInfo())
			-- print('------ onBattleClear end')
		end, 1)
	end
end

function cache.onBattleUpdate(delta)
	cspriteCache:update(delta)
end

function cache.onBackLogin()
	redHintCache:clean()
	userDefaultCache:clean()
	cache.onBattleClear(true)

	-- pay attention to here
	-- processRenderCommand no retain the cc.GLProgramState
	-- http://172.81.227.66:1104/crashinfo?_id=76048&type=-1
	-- cc.GLProgramStateCache:getInstance():removeUnusedGLProgramState()
end
