local Gate = require "app.views.city.test.gate.gate"
local Prefab = require "app.views.city.test.model.prefab"

local BraveChallengeGate = class("BraveChallengeGate", Gate)

-- 属性默认显示的值
local DefaultAttr = {
	star = 12,
	classify = 0,
	level = 90,
	hp = 100000,
	mp1 = 1000,
	mp2 = 1,
	hpRecover = 1,
	mp1Recover = 1,
	mp2Recover = 1,
	damage = 10000,
	specialDamage = 10000,
	defence = 3000,
	specialDefence = 3000,
	defenceIgnore = 1,
	specialDefenceIgnore = 1,
	speed = 14,
	strike = 1,
	strikeDamage = 15000,
	strikeResistance = 1,
	block = 1,
	breakBlock = 1,
	blockPower = 1,
	dodge = 1,
	hit = 10000,
	damageAdd = 1,
	damageSub = 1,
	ultimateAdd = 0,
	ultimateSub = 0,
	damageDeepen = 1,
	damageReduce = 1,
	suckBlood = 0,
	rebound = 0,
	cure = 1,
	natureRestraint = 1,
	gatePer = 1,
	immuneGate = 1,
	skills = {},
	passive_skills = {},
	ex_skills = {},
	fightPoint = 0,
	controlPer = 0,
}

-- 预处理
function BraveChallengeGate:preTreat()
	local csvCards = csv.cards

	self.playerCards = {}
	self.monsterCards = {}
	self.badgesSkills = {}
	self.rdBadgesSkills = {}
	for k, v in pairs(csv.brave_challenge.cards) do
		if type(v) == "table" and v.cardID then  -- __size  __default
			local roleData = clone(DefaultAttr)
			roleData.roleId = csvCards[v.cardID].unitID

			-- 加技能
			for _, skillID in pairs(csvCards[v.cardID].skillList) do
				roleData.skills[skillID] = v.level
			end

			if v.groupID >= 10 and v.groupID <= 11 then -- 测试组
				table.insert(self.playerCards, roleData)
			elseif v.groupID > 100 then
				self.monsterCards[k] = roleData
			end
		end
	end

	for k, v in pairs(csv.brave_challenge.badge) do
		if type(v) == "table" and v.skillIDs and v.skillIDs[1] then
			self.badgesSkills[k] = v.skillIDs[1]
			table.insert(self.rdBadgesSkills, v.skillIDs[1])
		end
	end
end

function BraveChallengeGate:addSelfRoles()
	local roles = {}
	for k = 1, 6 do
		local index = math.random(1, #self.playerCards)
		local skillIndex = math.random(1, #self.rdBadgesSkills)
		local skillID = self.rdBadgesSkills[skillIndex]
		roles[k] = self.playerCards[index]
		roles[k].skills[skillID] = roles[k].level
		table.insert(roles[k].ex_skills, skillID)
	end
	return roles
end

-- 具体战斗
function BraveChallengeGate:specificBattle()
	local roles = {}

	-- 开启具体战斗 下面四个需要修改
	local switch = false -- 是否开启具体战斗检测
	local monsterId = 98008 -- 对应关卡monsterId
	local leftRoleId = {1261, 741, 2013, 3611, 333, 493} -- 左边精灵Id
	local leftExSkill = {5002711, 5003306, 5006702, 5006715, 5009713, 5004702} -- 左边额外加技能Id

	-- 左边
	for k, roleId in ipairs(leftRoleId) do
		for _, v in ipairs(self.playerCards) do
			if roleId == v.roleId then
				roles[k] = v
				roles[k].skills[leftExSkill[k]] = roles[k].level
				table.insert(roles[k].ex_skills, leftExSkill[k])
				break
			end
		end
	end
	-- 右边
	for k, v in pairs(csv.brave_challenge.monster) do
		if type(v) == "table" and v.cards and v.badges then
			local cards = v.cards
			local badges = v.badges
			if k == monsterId and cards and badges then
				for index, cardId in pairs(cards) do
					if cardId ~= 0 then
						local roleData = self.monsterCards[cardId]
						roleData.key = k

						if badges[index] ~= 0 then
							local badgeSkillID = self.badgesSkills[badges[index]]
							if badgeSkillID then
								roleData.skills[badgeSkillID] = roleData.level
								table.insert(roleData.ex_skills, badgeSkillID)
							end
						end
						roles[index + 6] = roleData
					end
				end
				break
			end
		end
	end

	return switch, {roles}
end

function BraveChallengeGate:getFightRoleData()
	self:preTreat()
	local isNeed, specificRoleOut = self:specificBattle()
	if isNeed then return specificRoleOut end

	local roleOut = {}
	for k, v in pairs(csv.brave_challenge.monster) do
		if type(v) == "table" and v.cards and v.badges then
			local cards = v.cards
			local badges = v.badges
			if cards and badges then
				local roles = self:addSelfRoles()
				for index, cardId in pairs(cards) do
					if cardId ~= 0 then
						local roleData = self.monsterCards[cardId]
						roleData.key = k

						if badges[index] ~= 0 then
							local badgeSkillID = self.badgesSkills[badges[index]]
							if badgeSkillID then
								roleData.skills[badgeSkillID] = roleData.level
								table.insert(roleData.ex_skills, badgeSkillID)
							end
						end
						roles[index + 6] = roleData
					end
				end
				table.insert(roleOut, roles)
			end
		end
	end
	return roleOut
end

return BraveChallengeGate