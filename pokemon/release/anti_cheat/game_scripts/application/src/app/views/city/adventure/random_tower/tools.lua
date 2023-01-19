-- @date 2019-11-1
-- @desc 随机塔 （通用方法）

local randomTowerTools = {}
--前置条件（1-有精灵残血；2-有精灵怒气没达到1000；3-有精灵死亡）
local CONDITION = {
	buffCardHp = 1,
	buffCardMp = 2,
	buffCardDead = 3
}
--符合条件的卡牌为true {condition补给条件, cardState卡牌状态}
function randomTowerTools.reachCondition(condition, cardState, selectDbId)
	local card = gGameModel.cards:find(selectDbId)
	if card:read("level") < 10 then
		return false
	end
	if condition == CONDITION.buffCardHp then
		return cardState and cardState[1] > 0 and cardState[1] < 1
	end
	if condition == CONDITION.buffCardMp then
		return not cardState or (cardState and cardState[2] < 1 and cardState[1] > 0)
	end
	if condition == CONDITION.buffCardDead then
		return cardState and cardState[1] <= 0
	end
	return true
end
--supplyTarget 补给对象（1-选择一只；2-上阵精灵；3-全体符合条件精灵）
function randomTowerTools.getCards(supplyTarget)
	local cards = gGameModel.role:read("cards")
	if supplyTarget == 2 then
		--可能是空
		local battleCardIDs = table.deepcopy(gGameModel.role:read("huodong_cards")[game.EMBATTLE_HOUDONG_ID.randomTower], true)
		cards = battleCardIDs or {}
	end
	return cards
end
function randomTowerTools.setEffect(parent, effectName, spineName, offy)
	local spineName = not spineName and "random_tower/baoxiang.skel" or spineName
	local offy = offy or 0
	local effect = parent:get("effect")
	if not effect then
		widget.addAnimationByKey(parent, spineName, "effect", effectName, 0)
			:xy(parent:width()/2, parent:height()/2 - offy)
			:scale(2)
	else
		effect:play(effectName)
	end
end

function randomTowerTools.calcFightingPointFunc()
	local buffs = {} -- {attr: {const, percent},}
	for _, id in ipairs(gGameModel.random_tower:read("buffs")) do
		local cfg = csv.random_tower.buffs[id]
		if cfg.buffType == 1 then -- BUFF_TYPE.attr
			for i=1, 99 do
				local typ = cfg["attrType"..i]
				if typ == nil or typ == 0 then
					break
				end
				local attr = game.ATTRDEF_TABLE[typ]
				local num, numtype = dataEasy.parsePercentStr(cfg["attrNum"..i])
				if buffs[attr] == nil then
					buffs[attr] = {0, 0}
				end
				if numtype == game.NUM_TYPE.number then
					buffs[attr][1] = buffs[attr][1] + num
				else
					buffs[attr][2] = buffs[attr][2] + num
				end
			end
		end
	end

	return function(dbId)
		local card = gGameModel.cards:find(dbId):read("card_id", "level", "skills", "attrs", "attrs2")
		local cardcfg = csv.cards[card["card_id"]]
		local attrs = maptools.extend({card.attrs, card.attrs2})
		for attr, t in pairs(buffs) do
			local val = attrs[attr]
			local const, percent = t[1], t[2]
			if const > 0 then
				val = val + const
			end
			if percent > 0 then
				val = val * (1 + percent / 100.0)
			end
			attrs[attr] = val
		end
		local point = dataEasy.calcFightingPoint(card.card_id, card.level, attrs, card.skills)
		return point
	end
end
function randomTowerTools.getCanPassMaxRoom()
	local level = gGameModel.role:read("level")
	local vipLevel = gGameModel.role:read("vip_level")
	local room = gGameModel.random_tower:read("room")
	local lastRoom = gGameModel.random_tower:read("last_room")
	local historyRoom = gGameModel.random_tower:read("history_room")
	local lastPassRoom = lastRoom > 0 and csv.random_tower.tower[lastRoom].canPass or 0
	local historyPassRoom = historyRoom > 0 and csv.random_tower.tower[historyRoom].canPass or 0
	-- 历史最高保底碾压
	local basePassRoom = 0
	for _, v in orderCsvPairs(csv.random_tower.can_pass) do
		if level >= v.level and vipLevel >= v.vip then
			basePassRoom = math.max(basePassRoom, v.canPass)
		end
	end
	local max = math.max(math.min(basePassRoom, historyPassRoom), lastPassRoom)
	return max
end

function randomTowerTools.getCanJumpMaxRoom()
	local level = gGameModel.role:read("level")
	local vipLevel = gGameModel.role:read("vip_level")
	local max = 0
	for _, v in orderCsvPairs(csv.random_tower.can_jump) do
		if level >= v.level and vipLevel >= v.vip then
			max = math.max(max, v.canJump)
		end
	end
	return max
end
return randomTowerTools