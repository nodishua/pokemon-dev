--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2019 TianJi Information Technology Inc.
--
--
-- 战斗逻辑引导
--

globals.BattleGuideModel = class("BattleGuideModel")

function BattleGuideModel:ctor(scene)
	self.scene = scene
end

function BattleGuideModel:init(play)
	self.play = play
end

function BattleGuideModel:checkGuide(cb, params)
	params = params or {}
	local round = params.round or self.play.curRound
	local heroId = params.heroId
	log.battle.guide("checkGuide: round", round, "sceneID", self.scene.sceneID, "curWave", self.play.curWave, "curRound", self.play.curRound, "heroId", heroId)
	local cfg = self.play:getMonsterGuideCsv(self.scene.sceneID, self.play.curWave)
	if not cfg then
		cb()
		return false
	end

	-- {round; storyId; heroId}
	-- round:99 表示本波最后的战斗结束时
	local function isOK(data)
		local storyCfg = csv.scene_monster_story[data[2]]
		if self.scene.gateType == game.GATE_TYPE.normal then
			local gateId = self.scene.sceneID
			local gateStar = gGameModel.role:read("gate_star") or {}
			local hasStar = gateStar[gateId] and gateStar[gateId].star and gateStar[gateId].star > 0
			if storyCfg.isFirstGate and hasStar then
				return false
			end
		end
		if data[1] == round and data[3] == heroId then
			return true
		end
		return false
	end

	local t = {}
	for _, story in ipairs(cfg.storys) do
		if isOK(story) then
			table.insert(t, story[2])
		end
	end
	if next(t) then
		gRootViewProxy:proxy():setGuideData(t)
		self.scene:modelWait("guiding", cb)
		return true
	end
	cb()
	return false
end
