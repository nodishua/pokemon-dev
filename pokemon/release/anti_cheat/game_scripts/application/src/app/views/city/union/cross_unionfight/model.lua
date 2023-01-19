--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--
-- 跨服公会战逻辑
--

local GROUP_TAB = {2, 3, 3}

local CrossUnionFightTools = require "app.views.city.union.cross_unionfight.tools"

local CrossUnionModel = class("CrossUnionModel")

CrossUnionModel.MatchStage = {
	Preliminary = 1,
	Final = 2,
}

function CrossUnionModel:ctor()
	self.rank = nil
	self.lastBattle = {} -- /game/cross/union/fight/last/battle返回的view数据

	self.countDown = 0		--战斗中轮次倒计时
	self.battleRound = 1	--战斗轮次
	self.finish = false		--当前状态战斗是否结束(初赛/决赛)
	self.unionAll = 0		--公会报名人数	
	self.unionState = {}	--不同分组的公会
	self.saveBattleData = {}
	self.localModel = {}	--记录其他组的战报
	for k=1, 4 do
		self.saveBattleData[k] = {}
		self.localModel[k] = self.localModel[k] or {}
		for i = 1, 3 do
			self.localModel[k][i] = {endFrameId = 0}
		end
	end
	self.distribute = 0		--玩家自己所在的战场
end

function CrossUnionModel:setLastBattle(data, idx)
	-- {组别: play}
	if idx then
		self.lastBattle[idx] = data
	else
		self.lastBattle = data
	end
end

function CrossUnionModel:getLastBattle(idx)
	return self.lastBattle[idx]
end

function CrossUnionModel:battleground(unionClassifyData, unionId, status)
	local id, start
	for i,v in ipairs(unionClassifyData or {}) do
		for j, vv in ipairs(v) do
			if vv.union_db_id == unionId then
				id = i
				break
			end
		end
	end

	if status == "preAward" or status == "topPrepare" or
		(status == "preOver" and self.finish) then
		start = true
	end
	return id, start
end

function CrossUnionModel:notRequireBattle()
	if self.status == "preBattle" or self.status == "preOver" or self.status == "topBattle" or self.status == "topOver" then
		return true
	end
	return false
end

function CrossUnionModel:notRequireRank()
	if self.status == "preBattle" or self.status == "preStart" or self.status == "topBattle" or self.status == "topStart" then
		return false
	end
	return true
end

function CrossUnionModel:calculationUnionPoint(group, cb, this)
	if not self:notRequireBattle() then
		if cb then cb() end
		return
	end

	if group == self.squad and not itertools.isempty(self.saveBattleData[group]) then
		self:getUnionInfo(cb, group)
		return
	end

	local tab = {}
	for i=1, 3 do
		tab[i] = self.localModel[group][i].endFrameId + 1
	end

	performWithDelay(this, function()
		gGameApp:requestServer("/game/cross/union/fight/battle/result", function (tb)
			if (tb.view.status == "preOver" or tb.view.status == "topOver") and not itertools.isempty(self.saveBattleData[group]) then
				self:getUnionInfo(cb, group)
				return 
			end

			local point = {}
			local satisfy, survive = false, false
			for i = 1, 3 do
				local gameModel = tb.view.results[i]
				if gameModel and #gameModel > 0 then
					self.localModel[group][i].endFrameId = #gameModel + self.localModel[group][i].endFrameId
					for _, v in ipairs(gameModel) do
						table.insert(self.saveBattleData[group], v)
					end
				end
			end
			self:getUnionInfo(cb, group)

		end, group, tab)
	end, 0)
end

--记录所有公会
function CrossUnionModel:differentUnion()
	local start = CrossUnionFightTools.getNowMatch(self.status)
	local unionData = start == 1 and self.unionClassifyData or self.top_battle_groups
	local unionState = {}
	for i, v in ipairs(unionData or {}) do
		if start == 1 then
			for k, data in ipairs(v) do
				unionState[data.union_db_id] = {}
			end
		else
			unionState[v.union_db_id] = {}
		end
	end
	self.unionState = unionState
end

--计算所有公会的实时存活人数和积分
function CrossUnionModel:getUnionInfo(cb, group)
	local battleRound = self.battleRound <= 1 and 0 or self.battleRound - 1
	for i, v in ipairs(self.saveBattleData[group] or {}) do
		if battleRound == v.round then
			if self.unionState[v.right.union_db_id] then
				self.unionState[v.right.union_db_id][1] = v.right.union_alive
				self.unionState[v.right.union_db_id][2] = v.right.union_point
			end
			if self.unionState[v.left.union_db_id] then
				self.unionState[v.left.union_db_id][1] = v.left.union_alive
				self.unionState[v.left.union_db_id][2] = v.left.union_point
			end
			if self.distribute and CrossUnionFightTools.roleDie(v, self.roleId, GROUP_TAB[self.distribute]) then
				self.condition = true
			end
		end
	end
	if cb then
		cb(true)
	end
end





return CrossUnionModel