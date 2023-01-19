--
-- 战斗玩法
--

local battlePlay = {}
globals.battlePlay = battlePlay

require "battle.models.play.gate"
require "battle.models.play.normal_gate"
require "battle.models.play.arena_gate"
require "battle.models.play.cross_arena_gate"
require "battle.models.play.newbie_gate"
require "battle.models.play.test_gate"
require "battle.models.play.skill_test_gate"
require "battle.models.play.daily_activity_gate"
require "battle.models.play.endless_gate"
require "battle.models.play.union_raid_gate"
require "battle.models.play.simple_activity_gate"
require "battle.models.play.world_boss_gate"
require "battle.models.play.huodong_boss_gate"
require "battle.models.play.sync_fight_gate"

require "battle.models.play.friend_gate"
require "battle.models.play.craft_gate"
require "battle.models.play.cross_craft_gate"
require "battle.models.play.random_gate"
require "battle.models.play.clone_gate"
require "battle.models.play.union_fight_gate"
require "battle.models.play.cross_union_fight_gate"
require "battle.models.play.gym_gate"
require "battle.models.play.cross_mine_gate"
require "battle.models.play.cross_mine_boss_gate"
require "battle.models.play.brave_challenge_gate"
require "battle.models.play.hunting_gate"
require "battle.models.play.activity_challenge_gate"

-- 分类原则, 以 GATE_TYPE 作为区分, 表示同一类型的玩法
-- 同 GATE_TYPE 不同 SCENE_TYPE 的, 则在具体的子gate文件中做判断区别(一般这种只是具体某一小部分功能有差别)
local map = {
	-- -- gate = battlePlay.Gate,		-- 作为基类来用, 一般不要直接用它
	[game.GATE_TYPE.test] = battlePlay.TestGate,			-- 测试副本 双方可控
	[game.GATE_TYPE.skillTest] = battlePlay.SkillTestGate,	-- 全自动技能测试
	[game.GATE_TYPE.newbie] = battlePlay.NewbieGate,		-- 新手本
	[game.GATE_TYPE.normal] = battlePlay.NormalGate,		-- 普通本
	[game.GATE_TYPE.arena] = battlePlay.ArenaGate,			    -- pvp
	[game.GATE_TYPE.crossArena] = battlePlay.CrossArenaGate,    -- 跨服pvp
	[game.GATE_TYPE.dailyGold] = battlePlay.DailyActivityGate, 	-- 日常活动本-金币本
	[game.GATE_TYPE.dailyExp] = battlePlay.DailyActivityGate, 	-- 日常活动本-经验本
	[game.GATE_TYPE.endlessTower] = battlePlay.EndlessGate,				-- 无尽之塔
	[game.GATE_TYPE.unionFuben] = battlePlay.UnionRaidGate,				-- 公会副本
	[game.GATE_TYPE.gift] = battlePlay.SimpleActivityGate,				-- 礼物本
	[game.GATE_TYPE.fragment] = battlePlay.SimpleActivityGate,			-- 碎片本
	[game.GATE_TYPE.simpleActivity] = battlePlay.SimpleActivityGate,	-- 简单活动本(不带修正)

	[game.GATE_TYPE.friendFight] = battlePlay.FriendGate,		-- 好友切磋
	[game.GATE_TYPE.randomTower] = battlePlay.RandomGate,		-- 随机试炼塔
	[game.GATE_TYPE.clone] = battlePlay.CloneGate,			    -- 元素
	[game.GATE_TYPE.worldBoss] = battlePlay.ActivityWorldBossGate,		 -- 世界boss
	[game.GATE_TYPE.huoDongBoss] = battlePlay.ActivityBossGate,		 -- 活动boss

	[game.GATE_TYPE.crossOnlineFight] = battlePlay.SyncFightGate,
	[game.GATE_TYPE.gym] = battlePlay.GymGate,		             -- 道馆
	[game.GATE_TYPE.gymLeader] = battlePlay.GymLeaderGate,		 -- 道馆馆主
	[game.GATE_TYPE.crossGym] = battlePlay.CrossGymGate,		 -- 跨服道馆馆主
	[game.GATE_TYPE.crossMine] = battlePlay.CrossMineGate,		 -- 跨服资源战
	[game.GATE_TYPE.crossMineBoss] = battlePlay.CrossMineBossGate,		 -- 跨服资源战boss
	[game.GATE_TYPE.braveChallenge] = battlePlay.BraveChallengeGate,     -- 勇者挑战
	[game.GATE_TYPE.hunting] = battlePlay.HuntingGate,		-- 狩猎地带
	[game.GATE_TYPE.summerChallenge] = battlePlay.ActivityChallengeGate,		-- 活动挑战
}

local recordMap = {
	[game.GATE_TYPE.arena] = battlePlay.ArenaGateRecord,				        -- pvp
	[game.GATE_TYPE.crossArena] = battlePlay.CrossArenaGateRecord,				-- 跨服pvp
	[game.GATE_TYPE.endlessTower] = battlePlay.EndlessGateRecord,				-- 无尽之塔
	[game.GATE_TYPE.craft] = battlePlay.CraftGateRecord,						-- 限时PVP
	[game.GATE_TYPE.crossCraft] = battlePlay.CrossCraftGateRecord,				-- 跨服限时PVP
	[game.GATE_TYPE.unionFight] = battlePlay.UnionFightGate,	                -- 公会战
	[game.GATE_TYPE.crossUnionFight] = battlePlay.CrossUnionFightGate,			-- 跨服公会战
	[game.GATE_TYPE.crossOnlineFight] = battlePlay.SyncFightGateRecord,
	[game.GATE_TYPE.gym] = battlePlay.GymGateRecord,
	[game.GATE_TYPE.gymLeader] = battlePlay.GymLeaderGateRecord,
	[game.GATE_TYPE.crossMine] = battlePlay.CrossMineGateRecord,
	[game.GATE_TYPE.crossMineBoss] = battlePlay.CrossMineBossGateRecord,
	[game.GATE_TYPE.braveChallenge] = battlePlay.BraveChallengeGateRecord,
	[game.GATE_TYPE.summerChallenge] = battlePlay.ActivityChallengeGateRecord,
}

function globals.newPlayModel(scene, gateType)
	local cls = map[gateType]
	if cls then
		return cls.new(scene)
	end
end

function globals.newRecordPlayModel(scene, gateType)
	local cls = recordMap[gateType] or map[gateType]
	if cls then
		return cls.new(scene)
	end
end