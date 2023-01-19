
local vsh = 'shader/ver_shader.vsh'
local spineVsh = 'shader/ver_spine_shader.vsh'

--下标要与上面对应
local shaderMapFile = {
	-- frozen = {vsh, "shader/frozen_shader.fsh"},
	-- stone = {vsh, "shader/stone_shader.fsh"},
	-- flickering = {vsh, "shader/flickering.fsh"},
	-- flickering2 = {vsh, "shader/flickering2.fsh"},
	-- colorize = {vsh, "shader/colorize.fsh"},
	-- glow = {vsh, "shader/glow.fsh"},
	-- blur = {vsh, "shader/blur.fsh"},

	normal = {vsh, "shader/normal_shader.fsh"},
	gray = {vsh, "shader/gray_shader.fsh"},
	hsl_gray = {vsh, "shader/hsl_gray_shader.fsh"},
	hsl_gray_white = {vsh, "shader/hsl_gray_white_shader.fsh"},
	hsl_white = {vsh, "shader/hsl_white_shader.fsh"},
	hsl = {vsh, "shader/hsl_shader.fsh"},
	black = {vsh, "shader/black_shader.fsh"},
	color = {vsh, "shader/color.fsh"},
	color2 = {vsh, "shader/color2.fsh"},
	gaussian_blur = {vsh, "shader/gaussian_blur.fsh"},

	spine_normal = {spineVsh, "shader/normal_shader.fsh"},
	spine_black = {spineVsh, "shader/black_shader.fsh"},
	spine_hsl = {spineVsh, "shader/hsl_shader.fsh"},
	spine_shihua = {spineVsh, "shader/shihua_shader.fsh"},
	spine_gray = {spineVsh, "shader/gray_shader.fsh"},

	-- spine_flicker = {spineVsh, "shader/quick_flickering.fsh"},
	-- spine_fire = {spineVsh, "shader/fire.fsh"},
}

local ShaderCache = {}
local shaderMap = CMap.new()

function ShaderCache.init()
	if shaderMap:empty() then
		print("---- shaderInit ----")
		for k, v in pairs(shaderMapFile) do
			local program = cc.GLProgram:create(v[1], v[2])
			program:link()
			program:updateUniforms()
			shaderMap:insert(k, program)
		end
	end
end

function ShaderCache.reload()
	ShaderCache.init()
	for k, v in shaderMap:pairs() do
		v:reset()
		v:initWithFilenames(shaderMapFile[k][0], shaderMapFile[k][1])
		v:link()
		v:updateUniforms()
	end
end

function ShaderCache.getShader(isSpine, shaderName, needCreate)
	if not shaderName then return end

	ShaderCache.init()
	if isSpine then
		shaderName = 'spine_' .. shaderName
	end

	return needCreate and cc.GLProgramState:create(shaderMap:find(shaderName)) or cc.GLProgramState:getOrCreateWithGLProgram(shaderMap:find(shaderName))
end

--注意！！shaderMap增加一种新shader，HSLShader.fsh里也需要对应加上这shader，需要维护两套
--shader里的uniform状态不一样，就需要重新new个program出来
--优化一: 用到色相改变的 才用这个shader
--优化二: 建个弱表来维护program对应的sprite，以此来重用program
--优化三: 减少反复io，直接在代码里用char[]赋值shader/VerShader.vsh与shader/CommonShader.fsh --暂不考虑
--优化四: CCSprite 里重写onDraw方法??用同个program，但每帧需要设置uniform变量值?? --不考虑
-- local HSLSpriteMap = CMap.new('v')
-- local HSLShaderStateMap = CMap.new()
-- function getHSLShader(sprite)
-- 	if sprite.aniType == CSprite.spriteType.SPINE then
-- 		return getHSLShaderSpine(sprite)
-- 	end
-- 	for i = 1,9999 do
-- 		if HSLShaderStateMap:find(i) == nil then
-- 			local shaderName = 'HSL'
-- 			local state = cc.GLProgramState:create(shaderMap:find(proramStrHash[shaderName]))
-- 			HSLShaderStateMap:insert(i,state)
-- 		end
-- 		if HSLSpriteMap:find(i) == nil then
-- 			HSLSpriteMap:insert(i,sprite)
-- 			return HSLShaderStateMap:find(i)
-- 		end
-- 	end
-- 	cclogWarn("getHSLShader ERROR")
-- 	return nil
-- end

-- local HSLSpriteMapSpine = CMap.new('v')
-- local HSLShaderStateMapSpine = CMap.new()
-- function getHSLShaderSpine(sprite)
-- 	for i = 1,9999 do
-- 		if HSLShaderStateMapSpine:find(i) == nil then
-- 			local shaderName = 'spine_hsl'
-- 			local state = cc.GLProgramState:create(shaderMap:find(proramStrHash[shaderName]))
-- 			HSLShaderStateMapSpine:insert(i,state)
-- 		end
-- 		if HSLSpriteMapSpine:find(i) == nil then
-- 			HSLSpriteMapSpine:insert(i,sprite)
-- 			return HSLShaderStateMapSpine:find(i)
-- 		end
-- 	end
-- 	cclogWarn("getHSLShader Spine ERROR")
-- 	return nil
-- end
--glNode:getGLProgramState():setUniformVec2("resolution", resolution)

return ShaderCache