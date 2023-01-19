

local CrossCraftGateRecord = class("CrossCraftGateRecord", battlePlay.CraftGateRecord)
battlePlay.CrossCraftGateRecord = CrossCraftGateRecord

-- 战斗模式设置 全自动
CrossCraftGateRecord.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= false,
	canSpeedAni 	= true,
	canSkip 		= true,
}

function CrossCraftGateRecord:init(data)
	-- local val = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.BattleSkip)
	-- if val == game.GATE_TYPE.arena then
	-- 	self.OperatorArgs.canSkip = true
	-- end
	self.isFinal = true
	battlePlay.Gate.init(self, data)
	-- gRootViewProxy:proxy():addSpecModule(battleModule.craftMods)
	self.posByForce = {2,8}
	self.score = 0
	self.enemyScore = 0
	self.firstRoleout = {{},{}}

	self.backUp = {{},{}} -- 存roleOut 初始化
	self.waveResultList = {} --每轮次的结果 {1,2,1,2,1}
	self.loserRoleOut = {{},{}} --被淘汰的
	self.endAnimation = {res = "xianshipvp/jinjichang.skel",aniName = ""}
	-- key:buff.csvCfg.id value:AddBuffToHero()的次数
	self.craftBuffAddTimes = {}
	self.forceToObjId = {-1,-1}
	self:playStartAni()
end

function CrossCraftGateRecord:makeEndViewInfos()
	local ratio = csv.cross.craft.base[1].damageScoreRatio
	local score,enemyScore = 0,0
	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.score)
	if tb then
		tb[1] = tb[1] or 0
		tb[2] = tb[2] or 0
		score = math.floor(tb[1] / ratio)
		enemyScore = math.floor(tb[2] / ratio)
	end
	self.score = score
	self.enemyScore = enemyScore
	return {result = self.result,score = self.score}
end