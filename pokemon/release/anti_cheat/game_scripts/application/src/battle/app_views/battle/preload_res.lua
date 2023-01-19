
local unitHash = {}

local function loadBuffRes(resT,audioT,cfg)
	if cfg.buffId == nil then return end
	for k,v in pairs(cfg.buffId) do
		if type(v) == 'number' then
			local csvBuff = csv.buff[v]
			if not csvBuff then
				local err = string.format("error: 预加载 [buff] 表资源时出错, 试图在该表中查找一个不存在的buffId=%s", v)
				return errorInWindows(err)
			end
			if csvBuff.effectRes then resT[csvBuff.effectRes] = (resT[csvBuff.effectRes] or 0) + 1 end
			if csvBuff.textResPath then resT[csvBuff.textResPath] = (resT[csvBuff.textResPath] or 0) + 1 end
			if csvBuff.iconResPath then resT[csvBuff.iconResPath] = (resT[csvBuff.iconResPath] or 0) + 1 end
			if csvBuff.playEffect then resT[csvBuff.playEffect] = (resT[csvBuff.playEffect] or 0) + 1 end
			if csvBuff.fixShow then resT[csvBuff.fixShow] = (resT[csvBuff.fixShow] or 0) + 1 end
			if csvBuff.easyEffectFunc == "change" then
				loadHeroUnit(resT,audioT,cfg.buffValue1[1])
			end
		end
	end
end
local function loadSkillProcess(resT,audioT,processId)
	local cfg = csv.skill_process[processId]
	if not cfg then
		local err = string.format("error: 预加载 [skill_process] 表资源时出错, 试图在该表中查找一个不存在的processId=%s", processId)
		return errorInWindows(err)
	end
	--加载资源
	if cfg.effectRes then resT[cfg.effectRes] = (resT[cfg.effectRes] or 0) + 1 end
	if cfg.shotEffect then resT[cfg.shotEffect] = (resT[cfg.shotEffect] or 0) + 1 end

	--加载buff
	loadBuffRes(resT,audioT,cfg)

	--加载召唤
	if cfg.callerId ~= nil and cfg.callerId > 0 then
		loadHeroUnit(resT,audioT,cfg.callerId)
		if cfg.callerEffect then resT[cfg.callerEffect] = (resT[cfg.callerEffect] or 0) + 1 end
	end
end

local function loadSkillEvent(resT, audioT, eventID)
	local effectCfg = csv.effect_event[eventID]
	if not effectCfg then
		local err = string.format("error: 预加载 [effect_event] 表资源时出错, 试图在该表中查找一个不存在的eventID=%s", eventID)
		return errorInWindows(err)
	end
	--加载音效
	if effectCfg.sound then audioT[effectCfg.sound.res] = true end
	if effectCfg.music then audioT[effectCfg.music.res] = true end

	-- 加载资源
	if effectCfg.effectRes then resT[effectCfg.effectRes] = (resT[effectCfg.effectRes] or 0) + 1 end
	-- if effectCfg.effectArgs then T[effectCfg.effectArgs] = true end

end

local function loadHeroSkill(resT,audioT,skillId)
	local skillCfg = csv.skill[skillId]
	if not skillCfg then
		local err = string.format("error: 预加载 [skill] 表资源时出错, 试图在该表中查找一个不存在的skillId=%s", skillId)
		return errorInWindows(err)
	end

	-- TODO: skill->skill_process->effect_event
	-- 通过eventIDgroup加载所有资源
	-- if skillCfg.eventIDgroup then
	-- 	for _, v in pairs(skillCfg.eventIDgroup) do
	-- 		log.preload(" loadHeroSkill---->>> skillID", skillId)
	-- 		loadSkillEvent(T, S, v)
	-- 	end
	-- end

	if skillCfg.skillProcess then
		for k2,v2 in pairs(skillCfg.skillProcess) do
			loadSkillProcess(resT,audioT,v2)
		end
	end
	for _,v in ipairs(skillCfg.effectBigName) do
		local key = "config/big_hero/normal/"..v..".png"
		resT[key] = (resT[key] or 0) + 1
	end

	if skillCfg.sound then
		audioT[skillCfg.sound.res] = true
	end
end

local function loadHeroUnit(resT,audioT,unitId)
	-- if unitHash[unitId] then return end
	local cfg = csv.unit[unitId]
	if not cfg then
		local err = string.format("error: 预加载 [unit] 表资源时出错, 试图在该表中查找一个不存在的unitId=%s", unitId)
		return errorInWindows(err)
	end
	unitHash[unitId] = true

	resT[cfg.unitRes] = (resT[cfg.unitRes] or 0) + 1
	for i, skillId in ipairs(cfg.skillList) do
		loadHeroSkill(resT,audioT,skillId)
	end
	if cfg.deathSound then audioT[cfg.deathSound] = true end
end


function globals.visitFightResources(resT, audioT, monsterCfg, data)
	--1、加载天气
	if monsterCfg.weatherTypeId then
		local weatherId = monsterCfg.weatherTypeId
		local weather = csv.weather
		if weatherId and weather[weatherId] then
			if weather[weatherId].iconRes then
				resT[weather[weatherId].iconRes] = (resT[weather[weatherId].iconRes] or 0) + 1
			end
			if weather[weatherId].effectRes then
				resT[weather[weatherId].effectRes] = (resT[weather[weatherId].effectRes] or 0) + 1
			end
		end
	end

	--2、加载场景
	local bkCsv = getCsv(monsterCfg.bkCsv)
	for k,v in csvPairs(bkCsv) do
		resT[v.res] = (resT[v.res] or 0) + 1
	end

	--3、加载角色
	local count = 0
	unitHash = {}
	if data.multipGroup then
		for _,roleOut in ipairs(data.roleOut[1]) do
			for k,v in ipairs(roleOut) do
				loadHeroUnit(resT, audioT, v.roleId)
				count = count + 1
			end
		end
		for _,roleOut in ipairs(data.roleOut[2]) do
			for k,v in ipairs(roleOut) do
				loadHeroUnit(resT, audioT, v.roleId)
				count = count + 1
			end
		end
	else
		for k,v in pairs(data.roleOut) do
			loadHeroUnit(resT, audioT, v.roleId)
			count = count + 1
		end
	end

	for k,v in ipairs(monsterCfg.monsters) do
		if v > 0 then
			loadHeroUnit(resT, audioT, v)
			count = count + 1
		end
	end
	unitHash = nil

	-- skel
	resT["effect/death.skel"] = 1
	resT["effect/dazhao_bj.skel"] = 1

	-- BattleSprite:initNatureQuan
	-- BattleSprite:initGroundRing
	resT[battle.SpriteRes.natureQuan] = count > 0 and count - 1 or 0
	resT[battle.SpriteRes.groundRing] = count > 0 and count - 1 or 0
	resT["ruchang/ruchang.skel"] = count > 0 and count - 1 or 0

	-- res
	resT["img/dazhaodi.jpg"] = 1
end
