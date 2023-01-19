

local env = maptools.extend({battleTarget.input, battleTarget.input.decorator, battleTarget.process})
-- setfenv for all functions
-- NOTE: if the f used by other env, setfenv will be replace the old one
for k, f in pairs(env) do
	if type(f) == "function" then
		setfenv(f, env)
	end
end
env.battle = battle

local FindBaseEnv = protectedEnv(env)

-- limit(1) | random -> random(limit(1))
-- random | limit(1) -> limit(1, random())
--
-- input: enemy, process: column(self.id)
-- ->
-- column(self.id, enemy())
--
-- pipe-like配置形式转成函数调用形式
-- @param: input 自定义的字符串,用来当作上面函数中的targets传参用的
-- 不能提取i==1 公式 selfforce|selfforce => selfforce(selfforce)
-- local function conv2funcStr(s, input)
-- 	s = string.trim(s)
-- 	if s:sub(1,1) == "|" then s = s:sub(2) end
-- 	local segs = string.split(s, "|")
-- 	local funcStr = input or ""
-- 	for i, seg in ipairs(segs) do
-- 		seg = string.trim(seg)
-- 		local len = -2
-- 		local patten = "%s,%s)"
-- 		local ps, _ = string.find(seg, '%(%s*%)')
-- 		if ps then						-- random( )
-- 			patten = i == 1 and "%s)" or "%s%s)"
-- 		elseif seg:sub(-1) ~= ")" then 	-- random
-- 			patten = "%s(%s)"
-- 			len = -1
-- 		elseif i == 1 then				-- random( 1 )
-- 			patten = "%s%s)" -- 公式段里最后一个公式时 不需要逗号
-- 		end
-- 		funcStr = string.format(patten, seg:sub(1, len), funcStr)
-- 	end
-- 	p_print("111111111111111",funcStr)
-- 	return funcStr
-- end

local function conv2funcStr(s, input)
	if s:sub(1,1) == "|" then s = s:sub(2) end
	local segs = string.split(s, "|")
	local funcStr = input or ""
	for i, seg in ipairs(segs) do
		local nullInfo, _ = string.find(seg,"%(.+%)") -- 存在内容 (0)
		local ps, _ = string.find(seg,"%(.*%)") -- 存在括号 ()
		local patten = ""
		local len = -2
		-- 没有括号要优先加括号 enemyForce -> enemyForce()
		if not ps then
			seg = seg .. "()"
		end

		if funcStr == "" then
			funcStr = seg
		else
			-- 有内容要 enemyForce(0) -> enemyForce(0,%s)
			-- 没有内容 enemyForce() -> enemyForce(%s)
			seg = seg:sub(1, len) .. (nullInfo and ",%s)" or "%s)")
			funcStr = string.format(seg, funcStr)
		end
		-- print("conv2funcStr",funcStr,seg,nullInfo,ps)
		-- print(i,patten,seg:sub(1, len),funcStr)
		-- funcStr = string.format(patten, seg:sub(1, len), funcStr)
	end
	return funcStr
end

-- pipe-like目标查找函数
function battleTarget.targetFinder(caster, selectedObj, config, args)
	local funcStr = config.input
	if config.process and config.process ~= '' then
		funcStr = string.format("%s|%s", config.input, config.process)
	end
	funcStr = conv2funcStr(funcStr)
	log.targetFinder.funcStr('目标查找函数', funcStr)

	local env = battleCsv.makeFindEnv(caster, selectedObj, args)
	-- local ret = battleCsv.doFormula(funcStr, battleCsv.fillFuncEnv(protected, env))
	-- TODO: funcStr大部分是程序内部定义，且使用battleTarget的导出函数，所以暂时不用battleCsv
	-- TODO: 但这里缺失了互操作性和统一性
	local ret = battleCsv.doFormula(funcStr, FindBaseEnv:fillEnv(env))
	FindBaseEnv:resetEnv()

	log.targetFinder.find('查找到目标', lazydumps(ret, function()
		local size = 0
		for k, obj in pairs(ret) do
			print(string.format("%s:\t%s %d", k, tostring(obj), obj.seat))
			size = size + 1
		end
		return string.format("%s 个", size)
	end))
	return ret
end


--------------------------------------------
-- for tset

-- local config = {
-- 	input = "myself()|nodead",			-- myself()|nodead  这种也支持下,免得可能多写了括号时,不好查找原因
-- 	process = "limit(5)|random(1)",		-- process里面,基本都是需要带参数的,targets参数可以不填,需要注意参数的位置,如果有多个参数,target放到最后
-- }

-- local retT = targetFinder_new(config)

-- for i, obj in pairs(retT) do
-- 	print('---- ', i, obj.id)
-- end