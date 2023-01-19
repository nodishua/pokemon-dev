--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- GameBattleModel
--

local function card2RoleOut(t, cardAttrs, cardStates,roleForce)
	local dbID, cardID, skinID
	if type(t) == 'table' then
		dbID, cardID, skinID = unpack(t, 1, 3)
	else
		dbID = t
	end
	if dbID == nil or dbID == 0 then
		return nil
	end
	local card = cardAttrs[dbID]
	cardID, skinID = card.card_id, card.skin_id
	local state = cardStates[dbID]

	local unitID = 0
	if card.unit_id and card.unit_id ~= 0 then -- 指定战斗用的unit_id, 不用cards表里的，夏日挑战会使用
		unitID = card.unit_id
	else
		unitID = csv.cards[cardID].unitID
		if skinID and skinID ~= 0 then
			unitID = csv.card_skin[skinID].unitIDs[cardID]
		end
	end

	local roleOut = {
		roleForce = roleForce,
		roleId = unitID,
		cardId = dbID,
		fightPoint = card.fighting_point,
		level = card.level,
		advance = card.advance,
		skills = card.skills,
		star = card.star,
		starEffect = card.star_effect,
		passive_skills = card.passive_skills or {},
		hpScale = state and state[1] or 1,
		mp1Scale = state and state[2] or 1,
	}

	-- roleOutT[group][idx].develop = csv.cards[card_id].develop
	-- roleOutT[group][idx].quality =  gGetAdvanceCfg(tonumber(cfg.cardMarkID), tonumber(card.advance)).quality

	-- attrs
	for k, v in pairs(card.attrs) do
		roleOut[k] = v
	end
	-- attrs2
	if card.attrs2 then
		for k, v in pairs(card.attrs2) do
			roleOut[k] = v
		end
	end
	return roleOut
end

local GameBattleModel = class("GameBattleModel")

GameBattleModel.card2RoleOut = card2RoleOut

function GameBattleModel:ctor(game)
	self.game = game
	self.operateForceSwitch = false
end

function GameBattleModel:init(tb)
	for k, v in pairs(tb) do
		self[k] = v
	end

	assert(self.level ~= nil, 'level is required')
	assert(self.cards ~= nil, 'cards is required')

	self:recordCheat(tb)
	return self
end

function GameBattleModel:sceneConf(sceneID)
	return csv.scene_conf[sceneID]
end

function GameBattleModel:getRoleOut()
	if self.MultipGroup then
		return self:getGroupRoleOut()
	end

	local roleOut = {}
	local idx = 1
	-- [1, 2, 3, nil, 4, 5] or [nil, nil, 1, 2, 3, nil]
	for i, t in maptools.order_pairs(self.cards) do
		local pos = self.OmitEmpty and idx or i
		roleOut[pos] = card2RoleOut(t, self.card_attrs, self.card_states or {},1)
		idx = idx + 1
	end

	if self.defence_cards then
		local idx = 1
		for i, t in maptools.order_pairs(self.defence_cards) do
			local pos = self.OmitEmpty and idx or i
			roleOut[6 + pos] = card2RoleOut(t, self.defence_card_attrs, self.defence_card_states or {},2)
			idx = idx + 1
		end
	end

	return roleOut
end

function GameBattleModel:getGroupRoleOut()
	local groupRoleOut = {{}, {}} -- { {{...}, {...}}, {{...}, {...}} }
	-- {[1, 2, 3, nil, 4, 5], [nil, nil, 1, 2, 3, nil]}
	for group, cards in ipairs(self.cards) do
		groupRoleOut[1][group] = groupRoleOut[1][group] or {}
		local idx = 1
		for i, t in maptools.order_pairs(cards) do
			local pos = self.OmitEmpty and idx or i
			groupRoleOut[1][group][pos] = card2RoleOut(t, self.card_attrs, self.card_states or {}, 1)
			idx = idx + 1
		end
	end

	if self.defence_cards then
		for group, cards in ipairs(self.defence_cards) do
			groupRoleOut[2][group] = groupRoleOut[2][group] or {}
			local idx = 1
			for i, t in maptools.order_pairs(cards) do
				local pos = self.OmitEmpty and idx or i
				groupRoleOut[2][group][6 + pos] = card2RoleOut(t, self.defence_card_attrs, self.defence_card_states or {}, 2)
				idx = idx + 1
			end
		end
	end

	return groupRoleOut
end

local function getDBId(t)
	local dbID = t
	if type(t) == 'table' then
		dbID = t[1]
	end
	return t
end

-- 第二套属性
function GameBattleModel:getRoleOut2()
	if self.MultipGroup then
		return self:getGroupRoleOut2()
	end

	local roleOut = {}
	local idx = 1
	-- [1, 2, 3, nil, 4, 5] or [nil, nil, 1, 2, 3, nil]
	if self.card_attrs2 then
		for i, t in maptools.order_pairs(self.cards) do
			if self.card_attrs2[getDBId(t)] then
				local pos = self.OmitEmpty and idx or i
				roleOut[pos] = card2RoleOut(t, self.card_attrs2, self.card_states or {},1)
			end
			idx = idx + 1
		end
	end

	if self.defence_card_attrs2 and self.defence_cards then
		local idx = 1
		for i, t in maptools.order_pairs(self.defence_cards) do
			if self.defence_card_attrs2[getDBId(t)] then
				local pos = self.OmitEmpty and idx or i
				roleOut[6 + pos] = card2RoleOut(t, self.defence_card_attrs2, self.defence_card_states or {},2)
			end
			idx = idx + 1
		end
	end

	return roleOut
end

function GameBattleModel:getGroupRoleOut2()
	local groupRoleOut = {{}, {}} -- { {{...}, {...}}, {{...}, {...}} }
	-- {[1, 2, 3, nil, 4, 5], [nil, nil, 1, 2, 3, nil]}
	if self.card_attrs2 then
		for group, cards in ipairs(self.cards) do
			groupRoleOut[1][group] = groupRoleOut[1][group] or {}
			local idx = 1
			for i, t in maptools.order_pairs(cards) do
				if self.card_attrs2[getDBId(t)] then
					local pos = self.OmitEmpty and idx or i
					groupRoleOut[1][group][pos] = card2RoleOut(t, self.card_attrs2, self.card_states or {}, 1)
				end
				idx = idx + 1
			end
		end
	end


	if self.defence_card_attrs2 and self.defence_cards then
		for group, cards in ipairs(self.defence_cards) do
			groupRoleOut[2][group] = groupRoleOut[2][group] or {}
			local idx = 1
			for i, t in maptools.order_pairs(cards) do
				if self.defence_card_attrs2[getDBId(t)] then
					local pos = self.OmitEmpty and idx or i
					groupRoleOut[2][group][6 + pos] = card2RoleOut(t, self.defence_card_attrs2, self.defence_card_states or {}, 2)
				end
				idx = idx + 1
			end
		end
	end

	return groupRoleOut
end

local swapKeysTb = {
	"levels",
	"names",
	"figures",
	"logos",
}

function GameBattleModel:getData()
	local sceneID = self.gate_id or self.DefaultGateID
	local roleOut = self:getRoleOut()
	local roleOut2 = self:getRoleOut2() -- 第二套属性使用
	local role_db_id = self.role_db_id or (self.role_key and self.role_key[2])
	local defence_role_db_id = self.defence_role_db_id or (self.defence_role_key and self.defence_role_key[2])
	local sceneConf = self:sceneConf(sceneID)
	local datas = {
		battleID = self.id,
		sceneID = sceneID,
		roleOut = roleOut,
		roleOut2 = roleOut2,
		randSeed = self.rand_seed,
		gateType = sceneConf.gateType,
		sceneTag = sceneConf.tag,

		names = {self.name, self.defence_name},
		levels = {self.level, self.defence_level},
		logos = {self.logo, self.defence_logo},
		figures = {self.figure, self.defence_figure},

		passive_skills = {self.passive_skills, self.defence_passive_skills},
		role_db_ids = {role_db_id, defence_role_db_id},
		preData = self:getPreDataForEnd(roleOut),
		multipGroup = self.MultipGroup,
		-- 当前玩家是防守方时 = 2
		-- 攻击方或者观察者时 = 1
		operateForce = (gGameModel.role:read('id') == defence_role_db_id) and 2 or 1,

		result = self.result, -- 战报的时候会有这项，其他都是nil值

		-- 回放相关
		play_record_id = self.play_record_id,
		cross_key = self.cross_key,
		record_url = self.record_url,
	}

	if not self.operateForceSwitch then
		datas.operateForce = 1
	end

	if datas.operateForce == 2 then
		for _,key in ipairs(swapKeysTb) do
			table.swapvalue(datas[key],1,2)
		end
	end

	if device.platform == "windows" then
		self:display(roleOut, roleOut2)
	end

	datas.top_cards_data = self:getTopCardsData()

	return datas
end

function GameBattleModel:getTopCardsData()
	local topCardsData = {}

	local topCards = gGameModel.role:read("top_cards") or {}
	topCardsData["top_cards"] = topCards

	topCardsData["card_attrs"] = {}
	for k,dbid in ipairs(topCards) do
		local card = gGameModel.cards:find(dbid)
		topCardsData["card_attrs"][dbid] = card:read("attrs")
	end

	return topCardsData
end

function GameBattleModel:getPreDataForEnd(roleOut)			-- 要在getData()之后
	local ret = {}
	local cardsInfo = {}	-- 放己方战斗卡牌信息的
	for id=1, 6 do
		local roleData = roleOut[id]
		if roleData then
			table.insert(cardsInfo, {
				id = id,
				unitId = roleData.roleId,
				level = roleData.level,
				advance = roleData.advance,
				star = roleData.star,
				rarity = csv.unit[roleData.roleId].rarity,
			})
		end
	end
	--
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

function GameBattleModel:recordCheat(tb)
	if ANTI_AGENT then return end

	-- tb存在外部view作为临时存储，会进行数据添加
	-- 所以这里clone，一般作弊修改会改全部，也会影响到这
	tb = clone(tb)
	self.cheat = {
		tb = tb,
		sum = csvNumSum(tb),
	}
end

function GameBattleModel:checkCheat()
	if ANTI_AGENT then return end

	local antiCheatNum = self.cheat.sum
	local num = csvNumSum(self.cheat.tb)
	if math.abs(antiCheatNum - num) > 1e-5 then
		errorInWindows('checkCheat %s %s %s', tostring(self), antiCheatNum, num)
		exitApp("close your cheating software")
	end
end

function GameBattleModel:display(roleOut, roleOut2)
	if self.MultipGroup == nil then
		local attrs = {
			{'hp', '生命'},
			{'speed', '速度'},
			{'damage', '物攻'},
			{'defence', '物防'},
			{'specialDamage', '特攻'},
			{'specialDefence', '特防'},
		}

		local t = {'名字'}
		for i = 1, 12 do
			local card = roleOut[i]
			if card ~= nil then
				table.insert(t, '' .. i .. '-' .. csv.unit[card.roleId].name .. '-' .. card.roleId)
			else
				table.insert(t, '')
			end
		end
		print(table.concat(t,"\t"))

		print('第一套属性')
		for _, v in ipairs(attrs) do
			local t = {v[2]}
			for i = 1, 12 do
				local card = roleOut[i]
				if card ~= nil then
					table.insert(t, card[v[1]])
				else
					table.insert(t, '')
				end
			end
			print(table.concat(t,"\t"))
		end

		print('第二套属性')
		for _, v in ipairs(attrs) do
			local t = {v[2]}
			for i = 1, 12 do
				local card = roleOut2[i]
				if card ~= nil then
					table.insert(t, card[v[1]])
				else
					table.insert(t, '')
				end
			end
			print(table.concat(t,"\t"))
		end
	end
end

return GameBattleModel
