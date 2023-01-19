--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- HuntingBattle 远征战斗
--

local GameBattleModel = require("app.models.battle")
local HuntingBattle = class("HuntingBattle", GameBattleModel)


HuntingBattle.DefaultGateID = game.GATE_TYPE.hunting

function HuntingBattle:getData()
	local sceneID = self.DefaultGateID
	local roleOut = self:getRoleOut()
	local roleOut2 = self:getRoleOut2() -- 第二套属性使用
	-- 狩猎根据cardid修正
	self:fixRoleOut(roleOut)
	self:fixRoleOut(roleOut2)
	local role_db_id = self.role_db_id or (self.role_key and self.role_key[2])
	local defence_role_db_id = self.defence_role_db_id or (self.defence_role_key and self.defence_role_key[2])
	local sceneConf = self:sceneConf(sceneID)
	local datas = {
		battleID = self.id,
		sceneID = sceneID,
		gateID = self.gate_id,
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

		route = self.route
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

	datas.gamemodel_data = datas.gamemodel_data or HuntingBattle.getGameModelData(self, datas.route)

	return datas
end

function HuntingBattle:getGameModelData(route)
	local hunting_gamemodel = {}
	local hunting_route = gGameModel.hunting:read("hunting_route")
	hunting_gamemodel["route_info"] = table.getraw(hunting_route[route])

	return hunting_gamemodel
end

function HuntingBattle:fixRoleOut(roleOut)
	local cfg = csv.cross.hunting.battle_fix
	for pos, roleData in maptools.order_pairs(roleOut) do
		if roleData.roleForce == 2 then -- 只对敌方修正
			local card = gGameModel.cards:find(roleData.cardId)
			if card then
				local cardId = card:read("card_id")
				if cfg[cardId] then
					for attr, data in pairs(roleData) do
						for k = 1, math.huge do
							local attrType = cfg[cardId]["attrType" ..k]
							if attrType and game.ATTRDEF_ENUM_TABLE[attr] == attrType then
								local attrFix = cfg[cardId]["attrFix" ..k]
								roleData[attr] = data * attrFix
							else
								break
							end
						end
					end
				end
			end
		end
	end
	return roleOut
end

function HuntingBattle:getPreDataForEnd(roleOut)
	return {}
end

return HuntingBattle