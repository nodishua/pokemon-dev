--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- cc.ParticleSystemQuad原生类的扩展
--

local ParticleSystemQuad = cc.ParticleSystemQuad
local create = ParticleSystemQuad.create

local insert = table.insert

local ACTION_TAG = 100
local POSITION_TAG = 101
local SCALE_TAG = 102
local OPACITY_TAG = 103
local PROPS_NAME = {"x", "y", "scale", "scaleX", "scaleY", "opacity"}
local MAP_PROPS_NAME = itertools.map(PROPS_NAME, function(k, v) return v, v end)
local COMPS_NAME = {
	"angle", "angleVar", "duration", "emissionRate", "endColor", "endColorVar","endRadius", "endRadiusVar", "endSize", "endSizeVar",
	"endSpin", "endSpinVar", "gravity", "life", "lifeVar", "posVar", "positionType", "radialAccel", "radialAccelVar", "rotationIsDir",
	"rotatePerSecond", "rotatePerSecondVar", "sourcePostion", "speed", "speedVar", "startColor", "startColorVar", "startRadius",
	"startRadiusVar", "startSize", "startSizeVar", "startSpin", "startSpinVar", "tangentialAccel", "tangentialAccelVar",
}
local COMPS_SPECIAL_NAME = {
	rotatePerS = "setRotatePerSecond",
	rotatePerSVar = "setRotatePerSecondVar",
	sourcePos = "setSourcePosition"
}
local MAP_COMPS_NAME = itertools.map(COMPS_NAME, function(k, v) return v, "set" .. string.caption(v) end)
arraytools.merge_inplace(MAP_COMPS_NAME, {COMPS_SPECIAL_NAME})

local function getPropData(base, map, params)
	params = params or {}
	local data = {}
	for props, t in pairs(base) do
		if not map[props] then
			printWarn("!!!particleSystemEasy not define props [%s]", props)
		else
			for _, v in ipairs(t) do
				insert(data, {
					props = props,
					name = map[props],
					frame = v.frame,
					value = v.value,
				})
				if params.type == "props" then
					-- 要设置变更到下个属性的动画
					if #data > 1 then
						data[#data - 1].nextFrame = v.frame
						data[#data - 1].nextValue = v.value
					end
				end
			end
		end
	end
	return data
end

local function getData(particlesystem)
	local data = {}
	if particlesystem then
		local props = particlesystem.props
		if props then
			arraytools.merge_inplace(data, {getPropData(props, MAP_PROPS_NAME, {type = "props"})})
		end
		local comps = particlesystem.comps and particlesystem.comps["cc.ParticleSystem"]
		if comps then
			arraytools.merge_inplace(data, {getPropData(comps, MAP_COMPS_NAME, {type = "comps"})})
		end
	end
	return data
end

local function checkSetAni(particleNode, props, nodeProps, dt, nextValue)
	if props == "x" or props == "y" then
		if props == "x" then
			nodeProps.x = nextValue

		elseif props == "y" then
			nodeProps.y = nextValue
		end
		particleNode:stopAllActionsByTag(POSITION_TAG)
		local action = cc.Sequence:create(cc.MoveTo:create(dt, cc.p(nodeProps.x, nodeProps.y)))
		action:setTag(POSITION_TAG)
		particleNode:runAction(action)

	elseif props == "scale" or props == "scaleX" or props == "scaleY" then
		if props == "scale" then
			nodeProps.scaleX = nextValue
			nodeProps.scaleY = nextValue

		elseif props == "scaleX" then
			nodeProps.scaleX = nextValue

		elseif props == "scaleY" then
			nodeProps.scaleY = nextValue
		end
		particleNode:stopAllActionsByTag(SCALE_TAG)
		local action = cc.Sequence:create(cc.ScaleTo:create(dt, nodeProps.scaleX, nodeProps.scaleY))
		action:setTag(SCALE_TAG)
		particleNode:runAction(action)

	elseif props == "opacity" then
		particleNode:stopAllActionsByTag(OPACITY_TAG)
		local action = cc.Sequence:create(cc.FadeTo:create(dt, nextValue))
		action:setTag(OPACITY_TAG)
		particleNode:runAction(action)
		return true
	end
	return false
end

-- 目前使用粒子系统没有spine表现会不连续，将渲染优化关掉
-- display.director:setDirtyDrawEnable(false)
function ParticleSystemQuad:create(plistFile, aniFile)
	local particleNode = create(self, plistFile)
	if aniFile then
		local filedata = cc.FileUtils:getInstance():getStringFromFile(aniFile)
		local aniData = json.decode(filedata)

		local data = {}
		arraytools.merge_inplace(data, {getData(aniData.curveData)})
		arraytools.merge_inplace(data, {getData(aniData.curveData.paths and aniData.curveData.paths.particlesystem)})
		table.sort(data, function(a, b)
			return a.frame < b.frame
		end)

		local index = 1
		-- 初始化设置
		while data[index] and data[index].frame == 0 do
			local name = data[index].name
			local value = data[index].value
			local func = particleNode[name]
			if func then
				func(particleNode, value)
			else
				printWarn("!!!particleSystemEasy not has node name [%s]", name)
			end
			index = index + 1
		end

		local nodeProps = {}
		nodeProps.x, nodeProps.y = particleNode:xy()
		nodeProps.scaleX, nodeProps.scaleY = particleNode:scaleX(), particleNode:scaleY()

		local curFrame = 0
		index = 1 -- 重新计数，第0帧也要设置移动动画表现
		schedule(particleNode, function()
			while data[index] and data[index].frame <= curFrame do
				local props = data[index].props
				local name = data[index].name
				local value = data[index].value
				local func = particleNode[name]
				if func then
					if data[index].nextFrame then
						local dt = data[index].nextFrame - data[index].frame
						local nextValue = data[index].nextValue
						if not checkSetAni(particleNode, props, nodeProps, dt, nextValue) then
							func(particleNode, value)
						end
					else
						func(particleNode, value)
					end
				else
					printWarn("!!!particleSystemEasy not has node name [%s]", name)
				end
				index = index + 1
			end
			if not data[index] then
				return false
			end
			curFrame = curFrame + 1/60
		end, 1/60)
	end
	return particleNode
end