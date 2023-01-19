local BuffArgs = {}
globals.BuffArgs = BuffArgs

local BuffBaseCheckList = {
    "value",
    "buffValueFormula"
    -- "skillCfg", 可能为空
}

local CorTBuff1CheckList = arraytools.merge({
    BuffBaseCheckList,
    {
        "cfgId",
        "overlayCount",
        "id",
        "holderID",
        "casterID"
    }
})

local CorTBuff2CheckList = arraytools.merge({
    BuffBaseCheckList,
    {
        "prob",
        "lifeRound",
        -- "curSkill", curskill可能为空
        "overlayCount"
    }
})

local AtOnceTransform1CheckList = arraytools.merge({
    BuffBaseCheckList,
    {
        "value",
        "overlayCount",
        "cfgId",
        "oldBuff",
        "oldHolder",
        "targetType"
    }
})

local AtOnceTransform2CheckList = arraytools.merge({
    BuffBaseCheckList,
    {
        "prob",
        "lifeRound",
        "overlayCount"
    }
})

local SkillCheckList = {
    "buffValueFormula",

    "value",
    "fromSkillId",
    "skillLevel",
    "lifeRound",
    "prob",
    -- "lastProcessTargets", 可能为空
    "currentAttackTarget",
    "index",
    "skillCfg",
}

local fromInfoMap = {
    ["cfgId"] = "from buff cfgId = ",
    ["processId"] = "from skill processId = ",
}

local function check(t, list, args)
    if device.platform ~= "windows" then return t end

    local catchKey
    for k, v in pairs(fromInfoMap) do
        if args[k] then
            catchKey = v .. args[k]
            break
        end
    end

    for __, key in ipairs(list) do
        assert(t[key] ~= nil, key .. " is nil, " .. catchKey)
    end
    return t
end

local function addEnv(t, env)
    assertInWindows(type(env) == "table", "env is not table")

    t.buffValueFormulaEnv = env
    return t
end

function BuffArgs.fromCopyOrTransfer1(_buff)
    local t = {
        value = _buff.args.value,
        buffValueFormula = _buff.args.buffValueFormula,
        skillCfg = _buff.args.skillCfg,

        cfgId = _buff.cfgId,
        overlayCount = _buff:getOverLayCount(),
        id = _buff.id,
        holderID = _buff.holder.id,
        casterID = _buff.caster.id
    }

    t = addEnv(t, _buff.args.buffValueFormulaEnv)
    return check(t, CorTBuff1CheckList, {cfgId = _buff.cfgId})
end

function BuffArgs.fromCopyOrTransfer2(data, _lifeRound, _curSkill)
    local t = {
        value = data.value,
        buffValueFormula = data.buffValueFormula,
        skillCfg = data.skillCfg,

        prob = 1,
        lifeRound = _lifeRound,
        overlayCount = data.overlayCount,
        curSkill = _curSkill
    }

    t = addEnv(t, data.buffValueFormulaEnv)
    return check(t, CorTBuff2CheckList, {cfgId = data.cfgId})
end

function BuffArgs.fromAtOnceTransform1(_buff, _cfgId, _value, _targetType)
    local t = {
        value = _value,
        buffValueFormula = _buff.args.buffValueFormula,
        skillCfg = _buff.args.skillCfg,

        overlayCount = _buff:getOverLayCount(),
        cfgId = _cfgId,
        oldBuff = _buff,
        oldHolder = _buff.holder,
        targetType = _targetType
    }

    t = addEnv(t, _buff.args.buffValueFormulaEnv)
    return check(t, AtOnceTransform1CheckList, {cfgId = _cfgId})
end

function BuffArgs.fromAtOnceTransform2(data, _lifeRound)
    local t = {
        value = data.value,
        buffValueFormula = data.buffValueFormula,
        skillCfg = data.skillCfg,

        prob = 1,
        lifeRound = _lifeRound,
        overlayCount = data.overlayCount
    }

    t = addEnv(t, data.buffValueFormulaEnv)
    return check(t, AtOnceTransform2CheckList, {cfgId = data.cfgId})
end

function BuffArgs.fromSkill(_skill, _extraTarget, _obj, _processCfg, _buffCfg, _i)
    local extra
    if _extraTarget then
        extra = _extraTarget[1]
    end
    -- TODO: 临时修正,后续都迁移到damage_process
    _skill.protectedEnv:resetEnv()
    local env = battleCsv.fillFuncEnv(_skill.protectedEnv, {
        target = _obj,
        _extraTarget = extra or _skill.owner:getCurTarget(),
        lastMp1 = 'lastMp1',
    })
    local lifeRound = battleCsv.doFormula(_processCfg.buffLifeRound[_i], env)
    local prob = battleCsv.doFormula(_processCfg.buffProb[_i], env)
    local values = battleCsv.doFormula(_processCfg.buffValue1[_i], env)

    --如果是变身buff且有多个变身unitID则随机变一个
    local needChange = _buffCfg.easyEffectFunc == "changeImage" or _buffCfg.easyEffectFunc == "changeUnit"
    if type(values) == "table" and needChange then
        values = values[ymrand.random(1, table.length(values))]
    end

    local t = {
        buffValueFormula = _processCfg.buffValue1[_i],

        value = values,
        fromSkillId = _skill.id,
        skillLevel = _skill:getLevel(),
        lifeRound = lifeRound,
        prob = prob,
        lastProcessTargets = _extraTarget,
        currentAttackTarget = _skill.allDamageTargets,
        index = _i,
        skillCfg = _skill.cfg,
    }

    t = addEnv(t, env)
    return check(t, SkillCheckList, {processId = _processCfg.id})
end
