--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- GymBattle 道馆副本战斗
--

local GameBattleModel = require("app.models.battle")
local GymBattle = class("GymBattle", GameBattleModel)

GymBattle.DefaultGateID = game.GATE_TYPE.gym

function GymBattle:init(tb)
	GameBattleModel.init(self, tb)
	local cfg = csv.gym.gate[tb.gate_id]
	GymBattle.MultipGroup = false
	if cfg.deployType == game.DEPLOY_TYPE.WheelType then
		-- 一维数组切割成多维 {} => {{},{}}
		local cardNumLimit = cfg.deployCardNumLimit -- 队伍数量
		local deployNum = cfg.deployNum
		self.cards = self:transform(deployNum, cardNumLimit, self.cards)
		if self.defence_cards then 
			self.defence_cards = self:transform(deployNum, cardNumLimit, self.defence_cards)
		end
		GymBattle.MultipGroup = true
	end
	return self
end

function GymBattle:transform(tbNum, num, cardIDs)
	local tempCardIDs = {}
	for i= 1, tbNum do 
		tempCardIDs[i] = {}
	end
	for i, t in maptools.order_pairs(cardIDs) do
		local tbIndex = math.ceil(i / 6)
		local index = i % 6 == 0 and 6 or i % 6
		tempCardIDs[tbIndex][index] = t
	end
	return tempCardIDs
end

function GymBattle:getPreDataForEnd(roleOut)
	local ret = {}
	local cardsInfo = {}	-- 放己方战斗卡牌信息的
	local roleList = self.MultipGroup and roleOut[1][1] or roleOut
	for id=1, 6 do
		local roleData = roleList[id]
		if roleData then
			table.insert(cardsInfo, {
				id = id,
				unitId = roleData.roleId,
				level = roleData.level,
				advance = roleData.advance,
				star = roleData.star,
				rarity = csv.unit[roleData.roleId].rarity,
				cardId = self.MultipGroup and roleData.cardId,
			})
		end
	end
	ret.cardsInfo = cardsInfo
	ret.drop = self.drop
	ret.roleInfo = {
		level = gGameModel.role:read("level"),						-- 等级
		level_exp = gGameModel.role:read("level_exp"),				-- 本级升级所需总经验
		sum_exp = gGameModel.role:read("sum_exp"),					-- 本级当前累计经验
	}
	local gateStar = gGameModel.role:read("gate_star")[self.gate_id]
	ret.dungeonStar = gateStar and gateStar.star or 0
	return ret
end

return GymBattle
