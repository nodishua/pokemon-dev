--
-- 对象查找
--

local battleTarget = {}
globals.battleTarget = battleTarget


require "battle.models.target.target2"
require "battle.models.target.target"


--[[
0-屏幕中央	移动到屏幕中心
1-单体	移动到逻辑允许的指定单位前方;攻击指定单位 input: selected
2-横排前排	在前排有单位的情况下会移动到前排横排中央，在前排没有单位的情况下会移动到后排横排中央;攻击敌方前排单位，前排没有单位的情况下攻击敌方后排 process: rowfront
3-横排后排	在后排有单位的情况下会移动到后排横排中央，在后排没有单位的情况下会移动到前排横排中央;攻击敌方后排单位，前排没有单位的情况下攻击敌方前排 process: rowback
4-竖排	移动到指定的竖排;攻击自身前方的竖排单位 process: column
5-原地 input: myself

11-敌方或者我方全体	全体单位 input: selfForce or enemyForce
12-单体溅射	单体溅射逻辑：攻击主要单位时，与之横排和纵排相距一格的单位会受到溅射伤害
13-固定位置 input: object(id)
14-自身	自己本身（多用于buff） input: myself
15-自身范围1格内 process: near
16-自身所在竖排
17-自身所在横排
18-敌方目标周围一格单位	敌方目标周围一格单位（主目标在技能上已经确定）
19-杀死自身的目标	杀死自身的目标
20-友方全体随机
21-敌方全体随机
]]--


local skillConfigTypeTb		-- skillTarget 对应的类型配置
local specialAttrChooseTyTb		-- specialChoose 对应的特殊属性类型



-- @param: chooseType 技能过程表中配置的类型
-- @param: args中保留当前过程表的几个常用参数, {friendOrEnemy=num, specialChoose=num}
-- @param: cfg中为配表中手填的 input/process 参数 {input="myself()|nodead", process="limit(5)|random(1)"}
-- 为了方便区分,暂定在使用手填的类型时,直接忽略掉常用参数和基础类型,也就是当使用手动填写时,写全一些
function globals.newTargetFinder(caster, selectedObj, chooseType, args, cfg)
	log.targetFinder.choose(' newTargetFinder: self, selected, chooseType ',caster.seat, selectedObj and selectedObj.seat, chooseType)

	local easyCfg = {}
	if cfg and next(cfg) then
		easyCfg = cfg
		if args and args.allProcessesTargets then
			easyCfg.process = battleTarget.otherProcessFinder(easyCfg.process,args.allProcessesTargets)
		end
	else
		if skillConfigTypeTb[chooseType] == nil then
			printWarn("chooseType %d no implement in skillConfigTypeTb", chooseType)
		end
		easyCfg = skillConfigTypeTb[chooseType](args)
		-- 让全部类型都支持下 specialChoose, 特殊单体的就不再判断了
		if args and args.specialChoose and easyCfg.process then
			local attrFuncStr = specialAttrChooseTyTb[args.specialChoose]
			local pstr = string.format('%s|%s', easyCfg.process, attrFuncStr)
			if easyCfg.process == "" then
				pstr = attrFuncStr
			end
			easyCfg.process = pstr
		end
		-- 随机目标简易配置支持
		if args and args.targetLimit and easyCfg.process then
			local pstr = string.format('%s|random(%s)', easyCfg.process, args.targetLimit)
			easyCfg.process = pstr
		end
	end

	if easyCfg.input and args then
		if args.skillType == battle.SkillType.PassiveSkill and caster and battleEasy.isCompleteLeave(caster) then
			args.inputExtraStr = string.format("leaveExtraDeal({casterId=%s})", caster.id)
		end
		if args.inputExtraStr then
			easyCfg.input = easyCfg.input.."|"..args.inputExtraStr
		-- elseif args.filterNoBeAttacked then
		-- 	easyCfg.input = easyCfg.input..string.format("|nobeattacked")
		end
	end

	if not easyCfg.input and not easyCfg.process then return {} end
	return battleTarget.targetFinder(caster, selectedObj, easyCfg, args)
end

function globals.newTargetTypeFinder(chooseType, parms)
	return skillConfigTypeTb[chooseType](parms)
end

function battleTarget.findOtherProcessParams(src,ctrl)
	src = string.trim(src)
	local _,otherProcessStart = string.find(src,ctrl)
	if otherProcessStart then
		local otherProcessEnd = string.find(src,'%)')
		local nums = src:sub(otherProcessStart+1,otherProcessEnd-1)
		local numSegs = string.split(nums, ",")
		return numSegs
	else
		return nil
	end
end

-- otherProcessExcept(59121)|attr("mp1","max",1)
-- useOtherProcess(201122)
function battleTarget.otherProcessFinder(process,allTargets)
	local s = process
	if not s or s == "" then
		return ""
	end
	s = string.trim(s)
	if s:sub(1,1) == "|" then s = s:sub(2) end
	local segs = string.split(s, "|")
	local result = {}
	for i, seg in ipairs(segs) do
		local expectTarget = {}
		local hasOtherExcept = battleTarget.findOtherProcessParams(seg,'otherProcessExcept%(')
		if hasOtherExcept then
			for k,v in ipairs(hasOtherExcept) do
                local processId = tonumber(v)
				if allTargets[processId] then
                    for k2,v2 in ipairs(allTargets[processId]) do
					    table.insert(expectTarget, v2.seat)
				    end
                end
			end
			table.insert(result, string.format("exclude({%s})", table.concat(expectTarget, ",")))
		else
			local useOtherProcess = battleTarget.findOtherProcessParams(seg,'useOtherProcess%(')
			if useOtherProcess then
				for k,v in ipairs(useOtherProcess) do
                    local processId = tonumber(v)
				    if allTargets[processId] then
                        for k2,v2 in ipairs(allTargets[processId]) do
						    table.insert(expectTarget, v2.seat)
					    end
                    end
				end
				table.insert(result, string.format("include({%s})", table.concat(expectTarget, ",")))
			else
				table.insert(result, seg)
			end
		end
	end
	return table.concat(result, "|")
end

--判断根据配置是不是单体目标(配置非单体目标但是实际根据场上人数因素造成实际选择后目标为单体不算)
local targetSingleTb1 = { --固定为单体
	[1] = true,
	--7 = true,
	[13] = true,
	[14] = true,
	[19] = true
}

local targetSingleTb2 = { --随机 可能存在随机数量为一个
	[20] = true,
	[21] = true,
	[22] = true
}
function globals.isProcessTargetSingle(processCfg)
	if targetSingleTb1[processCfg.skillTarget] then
		return true
	elseif targetSingleTb2[processCfg.skillTarget] and processCfg.targetLimit <= 1 then
		return true
	end
	return false
end

local forceNoDead = {
	[0] = "selfForce|nodead",
	[1] = "enemyForce|nodead",
	[2] = "all|nodead"
}

skillConfigTypeTb = {
	[1] = function(args)		--单体目标,
		local easyCfg = {
			input = 'selected',
			process = nil,
		}
		return easyCfg
	end,
	[2] = function(args)		--横排前排,
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local easyCfg = {
			input = str,
			process = 'rowfront',
		}
		return easyCfg
	end,
	[3] = function(args)		--横排后排,
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local easyCfg =	{
			input = str,
			process = 'rowback',
		}
		return easyCfg
	end,
	[4] = function(args)		--竖排,
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local easyCfg =	{
			input = str,
			process = 'column',
		}
		return easyCfg
	end,
	[11] = function(args)		--敌方或者我方所有目标,
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local easyCfg =	{
			input = str,
			process = '',
		}
		return easyCfg
	end,
	[12] = function(args)		--单体溅射
		local easyCfg =	{
			input = 'enemyForce|nodead',
			process = 'near',
		}
		return easyCfg
	end,
	[13] = function(args)		--固定位置,
		local easyCfg =	{
			input = string.format('object(%d)', args.specialChoose),
			process = nil,
		}
		return easyCfg
	end,
	[14] = function(args)		--自身,
		local easyCfg =	{
			input = 'myself',
			process = nil,
		}
		return easyCfg
	end,
	[15] = function(args)		--自身范围1格,
		local easyCfg =	{
			input = 'myself|selfForce',
			process = 'near',
		}
		return easyCfg
	end,
	[16] = function(args)		--自身所在竖排,
		local easyCfg =	{
			input = 'selfForce',
			process = 'selfColumn',
		}
		return easyCfg
	end,
	[17] = function(args)		--自身所在横排,(这个可能有点问题,自身所在横排是前还是后此时并不知道)
		local easyCfg =	{
			input = 'selfForce()|nodead',
			process = 'selfRow',
		}
		return easyCfg
	end,
	[18] = function(args)		--敌方目标1格,
		local easyCfg =	{
			input = 'selected|nodead',
			process = 'near',
		}
		return easyCfg
	end,
	[19] = function()			--杀死自己的目标,
		local easyCfg =	{
			input = 'whokill|nodead',
			process = nil,
		}
		return easyCfg
	end,
	[20] = function(args)			--友方/敌方全体随机
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local limit = 1
		if args and args.targetLimit then
			limit = args.targetLimit
		end
		local easyCfg =	{
			input = str,
			process = 'random('..limit..')',
		}
		return easyCfg
	end,
	[21] = function(args)			--前排随机
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local limit = 1
		if args and args.targetLimit then
			limit = args.targetLimit
		end
		local easyCfg =	{
			input = str,
			process = 'frontRowRandom('..limit..')',
		}
		return easyCfg
	end,
	[22] = function(args)			--后排随机
		local str = args and forceNoDead[args.friendOrEnemy] or ""
		local limit = 1
		if args and args.targetLimit then
			limit = args.targetLimit
		end
		local easyCfg =	{
			input = str,
			process = 'backRowRandom('..limit..')',
		}
		return easyCfg
	end,
	[23] = function(args)			--阵容单位
		local easyCfg =	{
			input = string.format('objectEx(%d,%d)', args.friendOrEnemy, args.specialChoose),
			process = nil,
		}
		return easyCfg
	end,
	[24] = function(args)		--特殊目标,公式外定义,
		return {}
	end,
	[25] = function(args)		--己方全体加敌方列排,
		local input1 = "selfForce()"
		local input2 = "enemyRow(1, true)"
		local easyCfg = {
			input = 'And('..input1..','..input2..')',
			process = nil,
		}
		return easyCfg
	end,
}

specialAttrChooseTyTb = {
	[1] = 'hpMax',
	[2] = 'hpMin',
	[3] = 'attackDamageMax',
	[4] = 'attackDamageMin',
	[5] = 'defenceMax',
	[6] = 'defenceMin',
	[7] = 'mp1Max',
	[8] = 'mp1Min',
	[9] = 'specialDamageMax',
	[10] = 'specialDamageMin',
	[11] = 'speedMax',
	[12] = 'speedMin',
    [13] = 'specialDefenceMax',
    [14] = 'specialDefenceMin',
    [15] = 'hpRatioMax',
    [16] = 'hpRatioMin',
    [17] = 'mp1RatioMax',
    [18] = 'mp1RatioMin',
}
