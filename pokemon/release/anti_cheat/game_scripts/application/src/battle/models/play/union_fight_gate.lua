
local UnionFightGate = class("UnionFightGate", battlePlay.Gate)
battlePlay.UnionFightGate = UnionFightGate

-- 战斗模式设置 全自动
UnionFightGate.OperatorArgs = {
	isAuto 			= true,
	isFullManual 	= false,
	canHandle 		= false,
	canPause 		= false,
	canSpeedAni 	= true,
	canSkip 		= true,
}

UnionFightGate.SpecEndRuleCheck ={
	battle.EndSpecialCheck.TotalHpCheck,
	battle.EndSpecialCheck.ForceNum,
	battle.EndSpecialCheck.FightPoint,
}

function UnionFightGate:init(data)
	battlePlay.Gate.init(self, data)
	self.dbIDtb = {}
	self.endAnimation = {res = "xianshipvp/jinjichang.skel",aniName = ""}
	self:playStartAni()
end

-- 加个宝可梦开场和进场的动画
function UnionFightGate:playStartAni()
	gRootViewProxy:notify('showVsPvpView',1)
end

function UnionFightGate:newWaveAddObjsStrategy()
	self:addCardRoles(1)
	self:addCardRoles(2)
	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function UnionFightGate:doObjsAttrsCorrect(isLeftC,isRightC)
	battlePlay.Gate.doObjsAttrsCorrect(self,isLeftC,isRightC)
	for i=1, self.ObjectNumber do
		local obj = self.scene:getObjectBySeatExcludeDead(i)
		if obj then
			obj:setHP(obj:hpMax()*obj.hpScale,obj:hpMax()*obj.hpScale)
			obj:setMP1(obj:mp1Max()*obj.mp1Scale+obj:initMp1(),obj:mp1Max()*obj.mp1Scale+obj:initMp1())
		end
	end
	self.states = {}
	self:setdbidTb()
end
--总血量-人数-战斗力
function UnionFightGate:checkBattleEnd()
	-- 0.有假死精灵再续一回合
	if self:checkHaveFakeDead() then return false end
	return battlePlay.Gate.checkBattleEnd(self)
end

function UnionFightGate:checkWaveEnd()
	if self:checkHaveFakeDead() then return false end
	if self.curRound >= self.roundLimit and self:checkRoundEnd()
	or (self:checkForceAllRealDead(1) or self:checkForceAllRealDead(2)) then
		return true
	end
	return false
end

function UnionFightGate:onBattleEndSupply()
	local _,result = self:checkBattleEnd()
	if result == 'win' then self.endAnimation.aniName = "effect_l"
	elseif result == 'fail' then self.endAnimation.aniName = "effect_r" end
end

function UnionFightGate:checkHaveFakeDead()
	for i = 1, self.ObjectNumber do
		local obj = self.scene:getObjectBySeat(i)
		if obj and obj:isFakeDeath() then
			return true
		end
	end
	return false
end

function UnionFightGate:setdbidTb()
	for i = 1, self.ObjectNumber do
		local obj = self.scene:getObjectBySeat(i)
		if obj and self:checkObjCanToServer(obj) then
			self.dbIDtb[i] = obj.dbID
		end
	end
end

function UnionFightGate:setCardStates()
	local winForce = 2
	if self.result == 'win' then
		winForce = 1
	end
	for i = 1, self.ObjectNumber do
		local obj = self.scene:getObjectBySeat(i)
		if obj and self:checkObjCanToServer(obj) then
			if not self.states[obj.dbID] then
				self.states[obj.dbID] = {}
			end
			local hpRatio,mpRatio = obj:hp() / obj:hpMax(), obj:mp1() / obj:mp1Max()
			if obj.force ~= winForce then
				hpRatio,mpRatio = 0,0
			end
			self.states[obj.dbID][1] = hpRatio
			self.states[obj.dbID][2] = mpRatio
		elseif self.dbIDtb[i] then
			if not self.states[self.dbIDtb[i]] then
				self.states[self.dbIDtb[i]] = {}
			end
			self.states[self.dbIDtb[i]][1] = 0
			self.states[self.dbIDtb[i]][2] = 0
		end
	end
end
-- 没有星级 有胜负
function UnionFightGate:makeEndViewInfos()
	self:setCardStates()
	return {
		result = self.result,
		states = self.states
	}
end