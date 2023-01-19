--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- sprite封装
--

globals.CSprite = class("CSprite", cc.Node)

CSprite.Types = {
	ARMATURE = 1, -- cocos studio 1.6制作的动画，已经废弃不用了
	SPRITE = 2, -- 普通的sprite
	SPINE = 3, -- spine json
	SPINEBIN = 4, -- spine skel
	PLIST = 5, -- plist粒子
}

local type = tolua and tolua.type or type
local findLast = string.findlastof

local function null_func()
end

--
-- globals
--

-- for debug
globals.SpineSpritesMap = setmetatable({}, {__mode = "kv"})

function globals.isPng(s)
	return s:sub(-4) == ".png" and s
end

function globals.isSpine(s)
	return s:sub(-5) == ".skel" and s
end

function globals.pngPath(s)
	local p = s:find('.skel')
	if p then
		return s:sub(1, p) .. 'png'
	end
	p = s:find('.png')
	if not p then
		-- define in text_atlas
		return string.format("font/digital_%s.png", s)
	end
	return s
end

-- 跟cache.newCSprite接口不要混用
-- 比如newCSprite和cache.removeCSprite错误搭配使用
-- 一般使用这里接口就足够了
-- 跟cache区别在于，这里接口可能会发生变动（cache策略）
-- 而使用cache说明是强制放入cache
local sum = 0

function globals.isCSprite(spr)
	return tj.type(spr) == "CSprite"
end

function globals.newCSprite(aniRes, ...)
	local new = function (...)
		-- add by CSprite.preLoad
		local obj = cache.popByKey(aniRes)
		if obj then return obj, true end
		return CSprite.new(aniRes, ...), false
	end

	-- local st = os.clock()

	local sprite, inCache = new(...)
	sprite:show()

	-- local dlt = os.clock() - st
	-- sum = sum + dlt
	-- log.new.CSprite(inCache and "cache" or "", aniRes, tostring(sprite), dlt, sum)

	return cache.addCSprite(sprite)
end

function globals.newCSpriteWithFunc(aniRes, newFunc, ...)
	local new = function (...)
		-- add by CSprite.preLoad
		local obj = cache.popByKey(aniRes)
		if obj then return obj, true end
		return newFunc(aniRes, ...), false
	end

	-- local st = os.clock()

	local sprite, inCache = new(...)
	sprite:show()

	-- local dlt = os.clock() - st
	-- sum = sum + dlt
	-- log.new.CSprite(inCache and "cache" or "", aniRes, tostring(sprite), dlt, sum)

	return cache.addCSprite(sprite)
end

-- no used
-- function globals.newAutoReleaseCSprite(aniRes, ...)
-- 	local sprite = CSprite.new(aniRes, ...)
-- 	return cache.addCSprite(sprite, true)
-- end

function globals.removeCSprite(sprite, cacheIt)
	if sprite == nil then return end
	if tj.type(sprite) ~= "CSprite" then
		error(string.format("sprite %s was not CSprite", tostring(sprite)))
	end

	local cb
	-- in battle, cache it by default
	if cacheIt == nil then
		cacheIt = true
	end
	-- cacheIt = false
	if cacheIt then
		cb = function()
			cache.addByKey(sprite.__aniRes, sprite)
		end
	end
	return cache.eraseCSprite(sprite, cb)
end


--
-- locals
--

local function parseResString(aniRes)
	if aniRes == nil or aniRes == "" then return end
	if device.platform == "windows" then
		assert(aniRes == string.trim(aniRes), aniRes .. " had space char")
	end

	local argsStr = nil
	local aniStr = nil
	local pos_ = string.find(aniRes,'%[')
	if pos_ ~= nil then
		aniStr = string.sub(aniRes,1,pos_ - 1)
		argsStr = string.sub(aniRes,pos_+1,string.len(aniRes)-1)
	else
		aniStr = aniRes
	end
	aniStr = string.gsub(aniStr, '\\', function(c)
        return '/'
    end)
    aniStr = string.gsub(aniStr, "//", function(c)
        return '/'
    end)
	return aniStr, argsStr
end

local function getResTypeAndPath(res)
	local aniStr, argsStr = parseResString(res)
	local typ, aniStr2
	local pos = string.find(aniStr, "%.skel")
	if pos then
		typ = CSprite.Types.SPINEBIN
		aniStr2 = string.sub(aniStr, 1, pos-1)..".atlas"
	end
	if typ == nil then
		pos = string.find(aniStr, "%.json")
		if pos then
			typ = CSprite.Types.SPINE
			aniStr2 = string.sub(aniStr, 1, pos-1)..".atlas"
		end
	end
	if typ == nil then
		pos = string.find(aniStr, "%.png") or string.find(aniStr, "%.jpg")
		if pos then
			typ = CSprite.Types.SPRITE
		end
	end
	if typ == nil then
		local pos = string.find(aniStr, "%.ExportJson")
		if pos then
			typ = CSprite.Types.ARMATURE
			local prePos = findLast(aniStr, "/")
			aniStr2 = string.sub(aniStr, prePos+1, pos-1)
		end
	end
	if typ == nil then
		pos = string.find(aniStr, "%.plist")
		if pos then
			typ = CSprite.Types.PLIST
		end
	end

	return typ, argsStr, aniStr, aniStr2
end

function CSprite:init(argsStr)
	if argsStr == nil or self.__ani == nil then return end
	local posbs = string.find(argsStr, "bs")
	local posrotate = string.find(argsStr, "rotate")
	local posalpha = string.find(argsStr, "alpha")
	local poshsl = string.find(argsStr, "hsl")
	local poshscc = string.find(argsStr, "hscc")  --命名中不能包含hsl 不然上面的poshsl也会有值
	if posbs ~= nil then
		local T = {}
		for arg in argsStr:sub(posbs):gmatch("[-.%d]+") do
			table.insert(T, tonumber(arg))
			if #T >= 2 then break end
		end
		if #T ~= 2 then return end
		self.__ani:setScale(T[1],T[2])
	end
	if posrotate ~= nil then
		for arg in argsStr:sub(posrotate):gmatch("[-.%d]+") do
			self.__ani:setRotation(tonumber(arg))
			break
		end
	end
	if posalpha ~= nil then
		for arg in argsStr:sub(posalpha):gmatch("[-.%d]+") do
			self.__ani:setOpacity(tonumber(arg) * 255)
			break
		end
	end
	if poshsl ~= nil then
		local T = {}
		for arg in argsStr:sub(poshsl):gmatch("[-.%d]+") do
			table.insert(T, tonumber(arg))
			if #T >= 3 then break end
		end
		if #T ~= 3 then return end
		self:setHSLShader(T[1], T[2], T[3], 1)
	end
	if poshscc ~= nil then
		local T = {}
		for arg in argsStr:sub(poshscc):gmatch("[-.%d]+") do
			table.insert(T, tonumber(arg))
			if #T >= 3 then break end
		end
		if #T ~= 3 then return end
		self:setHSLShader(T[1], T[2], T[3], 2)
	end
end

function CSprite:ctor(aniRes, raw)
	self.__ani = nil
	self.__aniType = nil
	self.__shaderName = nil
	self.__rawShaderState = nil
	self.__aniRes = aniRes

	if raw ~= nil then
		self.__ani = raw
		self.__aniType = CSprite.Types.SPRITE
		self:addChild(self.__ani)
		return
	end

	if aniRes == nil then
		-- CSprite只是当个cc.Node来使用
		-- CSprite.Types.SPRITE只能使用cc.Node提供的接口来实现相关功能
		-- 如果后续有要用到cc.Sprite特定功能，aniType就需要做分离
		self.__ani = self
		self.__aniType = CSprite.Types.SPRITE
		return
	end

	local typ, argsStr, aniStr, aniStr2 = getResTypeAndPath(aniRes)
	self.__aniType = typ

	-- print('!!!! CSprite', aniRes, typ, argsStr, aniStr, aniStr2)
	if typ == CSprite.Types.SPINE or typ == CSprite.Types.SPINEBIN then
		--改为A4后 内存压力确实小了很多，以后内存不是瓶颈的话，战斗开始和结束可以缓存着，到达一定量再释放!!!
		local atlas = aniStr2
		self.__ani = sp.SkeletonAnimation:create(aniStr, atlas)
		-- tint black color是通过shader实现
		-- 会影响batch，且有额外顶点变换，有性能影响，默认开启
		-- 详见SkeletonBatch.cpp和SkeletonTwoColorBatch.cpp

		local tintEnabled = true
		-- for test
		if gGameUI.rootViewName == "battle.view" then
			tintEnabled = false
		end
		self.__ani:setTwoColorTint(tintEnabled)

		SpineSpritesMap[self.__ani] = self

	elseif typ == CSprite.Types.SPRITE then
		self.__ani = cc.Sprite:create(aniStr)

	elseif typ == CSprite.Types.ARMATURE then
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(aniStr)
		self.__ani = ccs.Armature:create(aniStr2)

	elseif typ == CSprite.Types.PLIST then
		self.__ani = cc.ParticleSystemQuad:create(aniStr)
	end
	-- cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)

	if self.__ani then
		self:addChild(self.__ani)
	end

	--处理动画指令
	self:init(argsStr)
end

--预加载
function CSprite.preLoad(aniRes)
	if aniRes == nil or aniRes == "" then return end
	local typ, argsStr, aniStr, aniStr2 = getResTypeAndPath(aniRes)

	local ret
	if typ == CSprite.Types.SPINE or typ == CSprite.Types.SPINEBIN then
		--改为A4后 内存压力确实小了很多，以后内存不是瓶颈的话，战斗开始和结束可以缓存着，到达一定量再释放!!!
		ret = CSprite.new(aniRes)
		cache.addByKey(aniRes, ret)

	elseif typ == CSprite.Types.ARMATURE then
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(aniStr)

	elseif typ == CSprite.Types.SPRITE then
		display.textureCache:addImageAsync(aniStr, null_func)

	elseif typ == CSprite.Types.PLIST then
		cc.ParticleSystemQuad:create(aniStr)
	end

	return ret
end

function CSprite:isArmature()
	return self.__aniType == self.Types.ARMATURE
end

function CSprite:isSpine()
	return self.__aniType == self.Types.SPINE or self.__aniType == self.Types.SPINEBIN
end

function CSprite:isSprite()
	return self.__aniType == self.Types.SPRITE
end

function CSprite:setHSLShader(hue, saturation, brightness, alpha, time, switch)
	if self.__ani == nil then return end
	if self.__shaderName == "hsl" then return end
	self.__shaderName = "hsl" -- look shaderMapFile

	cache.setHSLShader(self.__ani, self:isSpine(), hue, saturation, brightness, alpha, time, switch)

	-- if self.inHSLShader then --子骨骼等共用同一个program，所以只需设置一次就ok
	-- 	self.__ani:getGLProgramState():setUniformInt("programIdx",programIdx)
	-- end
end

function CSprite:setShihuaShader(brightness)
	if self.__ani == nil then return end
	if self.__shaderName == "shihua" then return end
	self.__shaderName = "shihua" -- look shaderMapFile
	-- 石化效果
	cache.setShihuaShader(self.__ani, self:isSpine(), brightness)
end

function CSprite:setGLProgram(programName, state)
	if self.__ani == nil then return end
	if self.__shaderName == programName then return end
	self.__shaderName = programName

	if not self.__rawShaderState then
		self.__rawShaderState = self.__ani:getGLProgramState()
	end

	state = state or cache.getShader(self:isSpine(), programName)
	if state == nil and programName then return end

	if self:isSprite() then
		self.__ani:setGLProgramState(state)
		for k,v in pairs(self.__ani:getChildren()) do
			if iskindof(v, "cc.Sprite") then
				v:setGLProgramState(state)
			end
		end

	elseif self:isArmature() then
		self.__ani:setGLProgramState(state)
		for k,v in pairs(self.__ani:getChildren()) do
			if type(v) == "ccs.Bone" then
				local nodeList = v:getDisplayNodeList()  --默认都是sprite类型
				for k1,v1 in pairs(nodeList) do
					v1:setGLProgramState(state)
				end
			end
		end

	elseif self:isSpine() then
		self.__ani:setGLProgramState(state)
	end
	return state
end

function CSprite:setTextureRect(size,rotated)
	if self.__ani == nil then return end
	if self:isSprite() then
		for k,v in pairs(self.__ani:getChildren()) do
			if iskindof(v, "cc.Sprite") then
				local rect = v:getTextureRect()
				local _size = {}
				if size.width < rect.width then _size.width = size.width
				else _size.width = rect.width end
				if size.height < rect.height then _size.height = size.height
				else _size.height = rect.height end
				v:setTextureRect(cc.rect(rect.x,rect.y,_size.width,_size.height),rotated,_size)
			end
		end

	elseif self:isArmature() then
		for k,v in pairs(self.__ani:getChildren()) do
			if iskindof(v, "ccs.Bone") then
				local nodeList = v:getDisplayNodeList()  --默认都是sprite类型
				for k1,v1 in pairs(nodeList) do
					local rect = v1:getTextureRect()
					local _size = {}
					if size.width < rect.width then _size.width = size.width
					else _size.width = rect.width end
					if size.height < rect.height then _size.height = size.height
					else _size.height = rect.height end
					v1:setTextureRect(cc.rect(rect.x,rect.y,_size.width,_size.height),rotated,_size)
				end
			end
		end
	end
end

function CSprite:setLifeTime(time)
	return cache.setCSpriteLifeTime(self, time)
end

function CSprite:pause()
	if self.__ani == nil then return end
	if self:isArmature() then
		self.__ani:getAnimation():pause()

	elseif self:isSpine() then
		self.__ani:pause()
	end
end

function CSprite:resume()
	if self.__ani == nil then return end
	if self:isArmature() then
		self.__ani:getAnimation():resume()

	elseif self:isSpine() then
		self.__ani:resume()
	end
end

function CSprite:play(action, loop)
	local ok = false
	if self:isArmature() then
		ok = true
		if action then
			self.__ani:getAnimation():play(action)
		else
			self.__ani:getAnimation():playWithIndex(0)
		end

	elseif self:isSpine() then
		-- self.__ani:setDebugBonesEnabled(true)
		-- self.__ani:setToSetupPose()
		if loop or action:find("_loop") then
			ok = self.__ani:setAnimation(0, action, true)
		else
			ok = self.__ani:setAnimation(0, action, false)
			if not ok and action == "effect" then
				action = "effect_loop"
				ok = self.__ani:setAnimation(0, action, true)
			end
		end
		local soundRes = gSoundCsv and gSoundCsv[self.__aniRes] and gSoundCsv[self.__aniRes][action]
		if soundRes then
			performWithDelay(self, function()
				audio.playEffectWithWeekBGM(soundRes.res)
			end, soundRes.delay)
		end
	end
	return ok
end

function CSprite:addPlay(action)
	local ok = false
	if self:isSpine() then
		if action:find("_loop") then
			ok = self.__ani:addAnimation(0, action, true)
		else
			ok = self.__ani:addAnimation(0, action, false)
		end
	end
	return ok
end

function CSprite:removeAnimation()
	if self.__ani then
		self.__ani:removeFromParent()
		self.__ani = nil
		self.__aniRes = nil
	end
	self.__shaderName = nil
	self.__rawShaderState = nil
	return self
end

function CSprite:removeSelf()
	if self:isSpine() then
		-- clean event handler
		self:setSpriteEventHandler()
	end

	self:removeAnimation()
	self:removeFromParent()
	return self
end

function CSprite:removeSelfToCache()
	-- clean state in cache for reused
	if self.__rawShaderState then
		self:setGLProgram(nil, self.__rawShaderState)
		self.__rawShaderState = nil
	end
	if self:isSpine() then
		self.__ani:setToSetupPose()

		-- clean event handler
		self:setSpriteEventHandler()
	end
	self:removeFromParent()
	return self
end

-- @param isRelative true 表示speedScale为相对当前值的缩放
function CSprite:setAnimationSpeedScale(speedScale, isRelative)
	if self:isArmature() then
		local speed = isRelative and self.__ani:getAnimation():getSpeedScale() or 1
		self.__ani:getAnimation():setSpeedScale(speedScale * speed)

	elseif self:isSpine() then
		local speed = isRelative and self.__ani:getTimeScale() or 1
		self.__ani:setTimeScale(speedScale * speed)
	end
	return self
end

function CSprite:setSpriteEventHandler(handler, eventType)
	if self:isSpine() then
		-- local registerViewName = gGameUI.rootViewName
		-- NOTICE: must not watch ANIMATION_DISPOSE event
		-- ~LuaSkeletonAnimation
		-- removeObjectAllHandlers
		-- if ANIMATION_DISPOSE event be sent, no handle be invoke
		if eventType then
			self.__ani:unregisterSpineEventHandler(eventType)
			if handler then
				self.__ani:registerSpineEventHandler(function (event)
					-- if registerViewName and registerViewName ~= gGameUI.rootViewName and registerViewName == "battle.view" then
					-- 	registerViewName =  nil
					-- 	errorInWindows("sprite register in battle.view, now in %s, withType: %d, res: %s", gGameUI.rootViewName, eventType, self.__aniRes)
					-- end
					handler(eventType, event)
				end, eventType)
			end
		else
			for k, v in pairs(sp.EventType) do
				if v ~= sp.EventType.ANIMATION_DISPOSE then
					self.__ani:unregisterSpineEventHandler(v)
					if handler then
						self.__ani:registerSpineEventHandler(function (event)
							-- if registerViewName and registerViewName ~= gGameUI.rootViewName and registerViewName == "battle.view" then
							-- 	registerViewName =  nil
							-- 	errorInWindows("sprite register in battle.view, now in %s, res: %s", gGameUI.rootViewName, self.__aniRes)
							-- end
							handler(v, event)
						end, v)
					end
				end
			end
		end
	end
	return self
end

function CSprite:getAni()
	return self.__ani
end

function CSprite:getBoundingBox()
	-- box for self its meaningless
	return self.__ani:getBoundingBox()
end

function CSprite:getCascadeBoundingBox()
	return cc.utils:getCascadeBoundingBox(self)
end


---------------------
-- only for spine

function CSprite:setTimeScale(scale)
	if self:isSpine() then
		return self.__ani:setTimeScale(scale)
	end
	error("only spine had setTimeScale")
end

function CSprite:setSkin(name)
	if self:isSpine() then
		return self.__ani:setSkin(name)
	end
	error("only spine had setSkin")
end

function CSprite:getBonePosition(name)
	if self:isSpine() then
		return self.__ani:getBonePosition(name)
	end
	error("only spine had getBonePosition")
end

function CSprite:getBoneRotation(name)
	if self:isSpine() then
		return self.__ani:getBoneRotation(name)
	end
	error("only spine had getBoneRotation")
end

function CSprite:getBoneRotationX(name)
	if self:isSpine() then
		return self.__ani:getBoneRotationX(name)
	end
	error("only spine had getBoneRotationX")
end

function CSprite:getBoneRotationY(name)
	if self:isSpine() then
		return self.__ani:getBoneRotationY(name)
	end
	error("only spine had getBoneRotationY")
end

function CSprite:getBoneScaleX(name)
	if self:isSpine() then
		return self.__ani:getBoneScaleX(name)
	end
	error("only spine had getBoneScaleX")
end

function CSprite:getBoneScaleY(name)
	if self:isSpine() then
		return self.__ani:getBoneScaleY(name)
	end
	error("only spine had getBoneScaleY")
end

function CSprite:getBoneShearX(name)
	if self:isSpine() then
		return self.__ani:getBoneShearX(name)
	end
	error("only spine had getBoneShearX")
end

function CSprite:getBoneShearY(name)
	if self:isSpine() then
		return self.__ani:getBoneShearY(name)
	end
	error("only spine had getBoneShearY")
end



---------------------
-- only for vmproxy

function CSprite:modelOnly()
	self:stopAllActions()
	if self:isSpine() then
		for k, v in pairs(sp.EventType) do
			self.__ani:unregisterSpineEventHandler(v)
		end
	end
end
