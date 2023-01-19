--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- 这里的log都是调试用，release时都将无效
-- log = print
-- logf = print(format)
--

local upper = string.upper
local format = string.format
local insert = table.insert
local concat = table.concat

local disable = false
local log, logf, lazylog, lazylogf = {__tag = ""}, {__tag = ""}, {__tag = ""}, {__tag = ""}
globals.log, globals.logf, globals.lazylog, globals.lazylogf = log, logf, lazylog, lazylogf

local cache = {}
local cacheMax = 100
local logName = os.date('%Y%M%d_%H%M%S.log')
local logFile

local nullFunc = function() return true end

local iterInclude = function(t)
	return function(v)
		return itertools.include(t,v)
	end
end


local function logFlush()
	if disable or #cache == 0 then return end

	if logFile == nil then
		-- logFile = io.open(logName, "w+")
	end

	for i, t in ipairs(cache) do
		for j, v in ipairs(t) do
			t[j] = tostring(v)
		end
		cache[i] = concat(t, " ")
	end
	local s = concat(cache, "\r\n")
	if logFile then
		logFile:write(s) -- 打印到文件
		logFile:flush()
	end
	print(s) -- 打印到屏幕

	cache = {}
end

local function logPrint(...)
	-- 默认直接输出，日志多的时候可以延迟保存到文件里
	print(...)
	do return end
	insert(cache, {os.date('%H:%M:%S'), ...})

	if #cache >= cacheMax then
		logFlush()
	end
end

-- custom ignore by youself  格式: true--表示不显示该类型打印信息
-- tag 需要分比较细的粒度, 可以方便自由控制显示,
-- 如: log.battle.view.preload('sssss') 不要只写 log.battle('xxxxx')
-- 按层次缩进写, 表示作用域控制范围, 大的层级可以控制自己下面的层级的整体显示与否
-- 注意不要重名, 且大小写不敏感 log.battle = log.BaTTle
local ignoreTags = {
	app = true,
	alias = true,
	bind = true,
	cache = true,
	csprite = true,
	effect = true,
	guide = true,
	battleSprite = true,
	targetFinder = true,
	collectgarbage = true,
	battle = false,						-- 战斗相关的log标签 [超大类] 该值为true时,战斗内的log都不显示  ★★★★★(常用的)
		scene = true,					-- 场景信息 [大类]
			newRound = true,			-- 当前回合信息
			newBattleRound = true,		-- 当前小战斗回合信息
			setAttack = true,			-- 玩家操作数据, 点击目标id，使用技能id
			logHerosInfo = true,		-- 技能结束，小回合结束打印
			resume = true,				-- model resume
		gate = true,					-- 关卡信息
			onNewBattleRound = true,	-- 小战斗回合开始了！！！					★★
			curHero = true,				-- 当前进行攻击的单位是谁					★★
			autoAttack = true,			-- 当前处于自动攻击状态, 攻击者数据
			newWave = true,				-- 波次打印
			allHerosInfo = true,		-- 技能、小回合结束打印角色血量、怒气
		object = true,					-- 战斗单位 [大类]
			setHP = true,				-- 设置血量
			setMP1 = true,				-- 设置mp
			dead = true, 				-- 死亡信息
			resumeHp = true,			-- 回血													★★★★★
			beAttack = true,			-- 被攻击时数据, 谁打了谁, 之前血量 伤害 最终血量		★★★★★
			causeDamage = true,			-- 造成伤害记录
			calcInternalDamage = true,
			changeImage = true,			-- 变身
			replaceSkill = true,		-- 切换技能
			shield = true,              -- 护盾
			onPassive = true,           -- 触发被动
			isHit = true,               -- 是否命中
			toAttack = true,            -- 当前被攻击的目标
			rebound = true, 			-- 反伤
			suckHp = true,              -- 吸血
			resetHp = true,             -- 血量变化
			dead = true,                -- 死亡单位
		skill = true,					-- 技能 [大类]
			canSpellSkillId = true,		-- 判断能否放技能
			costMp1	= true,				-- 释放消耗mp
			skillCD	= true,				-- 技能cd
			curSkillId = true,			-- 当前攻击技能: 技能id 使用者id 目标id		★★★★★
			moveToTargetPos = true,		-- 技能移动到某个目标处						★★★
			processId = true,			-- 过程段id									★★★
			processSegId = true,		-- 过程段中的每一小段id
			damageFormula = true,		-- 技能表中的伤害或者加血的公式数据
			damageAdd = true,			-- 技能最后计算出来的伤害增幅
			skillEndRecoerMp1 = true,	-- 技能结束恢复怒气
			onSpellView = true,         -- 技能表现播放时
			passiveSkill = true,        -- 被动技能 trigger spellTo
			spellTo = true,             -- 技能过程段释放
			process = true,			-- 过程段信息
			processTargets = true,		-- 过程段目标
		target = true,					-- 目标选择 [大类]
		buff = true,					-- buff [大类]
			dispel = true,              -- buff驱散打印
			init = true,				-- buff初始化数据, 有此数据后表示buff已经创建成功		★★★★★
			takeEffect = true,			-- buff生效时打印，此数据表示buff已经生效
			over = true,				-- buff over时的数据									★★
			value = true,               -- buff的效果数值，配表值，加成值
			doEffect = true,            -- 执行buff效果
			overlay = true,				-- 覆盖buff信息
		battleView = true,				-- 战斗界面相关 [大类]
			preload = true,				-- 预加载资源内容
			wait = true,				-- 战斗model逻辑更新等待,只更新动画表现
		sprite = true,					-- 战斗中的角色资源相关 [大类]
			event = true,				-- spine event 数据
			notify = true,				-- 函数调用 程序用
			call = true,				-- 函数调用 程序用
		notify = true,					-- notify广播
		damage = true,					-- 伤害
			process = true,				-- 伤害组成
		event_effect = true,			-- 效果
			move = true					-- 移动
}

local filterTags = {
	battle = false,
		buff = false,
			dispel = {iterInclude({1961139,1961140})},
			overlay = {nil,nil,iterInclude({2,5,7,8})},
}

local tmp = {}
for k, v in pairs(ignoreTags) do
	tmp[upper(k)] = v
end
ignoreTags = tmp

tmp = {}
for k, v in pairs(filterTags) do
	tmp[upper(k)] = v
end
filterTags = tmp

local nulltb = {}
setmetatable(nulltb, {
	__index = function(t, k)
		rawset(t, k, nulltb)
		return nulltb
	end,
	__call = function(...)
	end
})

local function logDisable()
	disable = true
	local mods = {log, logf, lazylog, lazylogf}
	for _, l in ipairs(mods) do
		for k, v in pairs(l) do
			l[k] = nil
		end
	end
	for _, l in ipairs(mods) do
		setmetatable(l, {__index = function(t, k)
			rawset(l, k, nulltb)
			return nulltb
		end})
	end
end
log.disable, logf.disable, lazylog.disable, lazylogf.disable = logDisable, logDisable, logDisable, logDisable
log.flush = logFlush

-- lazy dumps(v), help some cost-heavy string cast
local lazytb = {__lazydumps = true}
function globals.lazydumps(v, f)
	if disable then return "" end
	f = f or dumps
	return setmetatable(lazytb, {__tostring = function()
		return f(v)
	end})
end

local function logIndex(setmeta)
	return function(t, k)
		local tag = upper(k)
		local tagPath = tag
		if #t.__tag > 0 then
			tagPath = format("%s %s", t.__tag, tag)
		end

		local taglog = setmeta({__tag = tagPath})
		if ignoreTags[tag] then
			taglog = nulltb
		end

		rawset(t, tag, taglog)
		rawset(taglog, "__curTag", tag)
		return taglog
	end
end

local function setLogMeta(t)
	return setmetatable(t, {
		__index = logIndex(setLogMeta),
		__call = function(t, ...)
			setLogColor(CONSOLE_COLOR.Light_Yellow)
			logPrint(format("<%s>", t.__tag), ...)
			setLogColor(CONSOLE_COLOR.Default)
		end
	})
end

local function setLogfMeta(t)
	return setmetatable(t, {
		__index = logIndex(setLogfMeta),
		__call = function(t, fmt, ...)
			local filterTab = filterTags[rawget(t,"__curTag")]
			if filterTab then
				local vargs = {...}
				for k,v in pairs(filterTab) do
					if not v(vargs[k]) then return end
				end
			end
			-- print(format("<%s> %s", t.__tag, format(fmt, unpack(vargs))))
			-- luajit支持format("%s", {}), lua不支持
			setLogColor(CONSOLE_COLOR.Light_Yellow)
			logPrint(format("<%s> %s", t.__tag, format(fmt, ...)))
			setLogColor(CONSOLE_COLOR.Default)
		end
	})
end

local function setLazyLogMeta(t)
	return setmetatable(t, {
		__index = logIndex(setLazyLogMeta),
		__call = function(t, ...)
			local vargs = {...}
			for i, v in ipairs(vargs) do
				if type(v) == "function" then
					vargs[i] = v()
				end
			end
			logPrint(format("<%s>", t.__tag), unpack(vargs))
		end
	})
end

local function setLazyLogfMeta(t)
	return setmetatable(t, {
		__index = logIndex(setLazyLogfMeta),
		__call = function(t, fmt, ...)
			local vargs = {...}
			for i, v in ipairs(vargs) do
				if type(v) == "function" then
					vargs[i] = v()
				end
			end
			logPrint(format("<%s> %s", t.__tag, format(fmt, unpack(vargs))))
		end
	})
end

setLogMeta(log)
setLogfMeta(logf)
setLazyLogMeta(lazylog)
setLazyLogfMeta(lazylogf)


