--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- Tasks
--

local Tasks = class("Tasks", require("app.models.base"))

local TaskDefs = game.TARGET_TYPE

local function nil_arg(...)
	return 0
end

local function one_arg(...)
	return 1
end

-- {model, colomn, 显示参数}
local WatchTargetMap = {
	[TaskDefs.Level] = {'role', 'level'},
	[TaskDefs.Gate] = {'role', 'gate_star', function (gate_star, arg)
		local t = gate_star or {}
		local v = t[arg] or {}
		if v.star and v.star > 0 then
			return 1
		end
		return 0
	end},
	[TaskDefs.CardsTotal] = {'role', 'cards', function (cards, arg)
		return itertools.size(cards)
	end},
	[TaskDefs.CardGainTotalTimes] = {'role', 'card_gain_times'},
	[TaskDefs.Vip] = {'role', 'vip_level'},
	[TaskDefs.EquipAdvanceCount] = {'role', 'equips', nil_arg},
	[TaskDefs.CardAdvanceTotalTimes] = {'role', 'card_advance_times'},
	[TaskDefs.GateStar] = {'role', 'gate_star_sum'},
	[TaskDefs.CardAdvanceCount] = {'cards', nil, function (cards, arg)
		local ret = 0
		for _ ,card in cards:pairs() do
			if card:read('advance') >= arg then
				ret = ret + 1
			end
		end
		return ret
	end},
	[TaskDefs.UnlockPokedex] = {'role', 'pokedex', function(pokedex, arg)
		return itertools.size(pokedex)
	end},

	[TaskDefs.GateChanllenge] = {'daily_record', 'gate_chanllenge'},
	[TaskDefs.HeroGateChanllenge] = {'daily_record', 'hero_gate_chanllenge'},
	[TaskDefs.HuodongChanllenge] = {'daily_record', 'huodong_chanllenge'},
	[TaskDefs.EndlessChallenge] = {'daily_record', 'endless_challenge'},
	[TaskDefs.ArenaBattle] = {'daily_record', 'pvp_pw_times'},
	[TaskDefs.DrawCard] = {'daily_record', 'draw_card'},
	[TaskDefs.WorldBossBattleTimes] = {'daily_record', 'boss_gate'},
	[TaskDefs.EquipStrength] = {'daily_record', 'equip_strength'},
	[TaskDefs.EquipAdvance] = {'daily_record', 'equip_advance'},
	[TaskDefs.CardSkillUp] = {'daily_record', 'skill_up'},
	[TaskDefs.LianjinTimes] = {'daily_record', 'lianjin_times'},
	[TaskDefs.DrawGem] = {'daily_record', 'draw_gem'},
	[TaskDefs.FishingTimes] = {'daily_record', 'fishing_counter'},
	[TaskDefs.FishingWinTimes] = {'daily_record', 'fishing_win_counter'},

	[TaskDefs.CompleteImmediate] = {'role', 'last_time', one_arg},
	[TaskDefs.CardAdvance] = {'daily_record', 'card_advance_times'},
	[TaskDefs.BuyStaminaTimes] = {'daily_record', 'buy_stamina_times'},
	[TaskDefs.CostRmb] = {'daily_record', 'consume_rmb_sum'},
	[TaskDefs.CardLevelUp] = {'daily_record', 'level_up'},
	[TaskDefs.CloneBattleTimes] = {'daily_record', 'clone_times'},
	[TaskDefs.NightmareGateChanllenge] = {'daily_record', 'nightmare_gate_chanllenge'},
	[TaskDefs.UnionContrib] = {'daily_record', 'union_contrib_times'},
	[TaskDefs.YYHuodongOpen] = {'role', 'yyhuodongs', nil_arg},
}

	-- _mem+main+1300+1 [number 1301]
	--     |    |    +2 [number 1]
	--     |    +1100+1 [number 1101]
	--     |    |    +2 [number 0]
	--     |    +1000+1 [number 1001]
	--     |    |    +2 [number 0]
	--     |    +1200+1 [number 1201]
	--     |         +2 [number 0]
	--     +daily+5003 [number 0]
	--           +5001 [number 0]
	--           +5002 [number 0]

function Tasks:init(t)
	-- the model only had two name daily and main
	local idlerMap = {}
	if t._mem then
		for name, v in pairs(t._mem) do
			local tasks = {}
			for id, tt in pairs(v) do
				if type(tt) == 'table' then -- main
					tasks[id] = {id=tt[1], flag=tt[2], arg=0}
				else -- daily
					tasks[id] = {id=id, flag=tt, arg=0}
				end
			end
			idlerMap[name] = idlereasy.new(tasks, name)
		end
	end
	self.__idlers = idlers.newWithMap(idlerMap, tostring(self))
	self._notify = {}
	return self
end

function Tasks:updSync(tb, tbnew)
	for name, v in pairs(tb) do
		local tasks = {}
		for id, tt in pairs(v) do
			if type(tt) == 'table' then -- main
				tasks[id] = {id=tt[1], flag=tt[2], arg=0}
			else -- daily
				tasks[id] = {id=id, flag=tt, arg=0}
			end
		end
		if itertools.size(tasks) > 0 then
			local idler = self.__idlers:at(name)
			idler:modify(function(val)
				for k, v in pairs(tasks) do
					val[k] = v
				end
				return true, val
			end, false) -- will notify in afterSync
			self._notify[name] = true
		end
	end
end

function Tasks:delSync(tb)
	for name, v in pairs(tb) do
		local tasks = {}
		for id, _ in pairs(v) do
			table.insert(tasks, id)
		end
		if #tasks > 0 then
			local idler = self.__idlers:at(name)
			idler:modify(function(val)
				for _, id in ipairs(tasks) do
					val[id] = nil
				end
				return true, val
			end, false) -- will notify in afterSync
			self._notify[name] = true
		end
	end
end

function Tasks:afterSync(upd)
	if self.__idlers == nil then return end -- in login without tasks
	for name, idler in self.__idlers:pairs() do
		idler:modify(function(val)
			for _, task in pairs(val) do
				local id = task.id
				local cfg = csv.tasks[id]
				if cfg then
					local target, targetArg = cfg.targetType, cfg.targetArg
					if WatchTargetMap[target] then
						local model, key, func = unpack(WatchTargetMap[target])
						local arg = 0
						local obj = self.game[model]
						if key then
							local v = obj:getValue_(key)
							arg = func and func(v, targetArg) or v
						else
							arg = func(obj, targetArg)
						end
						if task.arg ~= arg then
							task.arg = arg
							self._notify[name] = true
						end
					else
						error('task target ' .. target .. ' not watched!')
					end
				else
					printWarn("task %d not existed in csv", id)
				end
			end
			return true, val
		end, false)

		if self._notify[name] then
			self._notify[name] = nil
			idler:notify()
		end
	end
end

return Tasks
