local RebirthTools = {}

local EXPS = {16, 15, 14, 13, 12, 11}
local HELDITEMEXP = {2103, 2102, 2101}
local COIN_NUM = 12
local rebirthCostCsv = {}
for i,v in orderCsvPairs(csv.rebirth_rmb_cost) do
	if not rebirthCostCsv[v.type] then
		rebirthCostCsv[v.type] = {}
	end
	table.insert(rebirthCostCsv[v.type], {rmbPoint = v.rmbPoint, rmbRate = v.rmbRate})
end

local function isInUnion(dbId)
	local cardDeployment = gGameModel.role:read("card_deployment")
	for k,v in pairs(cardDeployment.union_training.cards or {}) do
		if v == dbId then
			return true
		end
	end
	return false
end

-- csv表遍历
local function calculateItems(list, key, val, items, costKey)
	for i, v1 in orderCsvPairs(list) do
		if i == val then
			break
		end

		if key then
			for k, v2 in csvMapPairs(v1["costItemMap"..key]) do
				items[k] = (items[k] or 0) + v2
			end
		end

		if costKey then
			local cost = v1["costGold"..costKey]
			items.gold = (items.gold or 0) + cost
		end
	end
end

-- 普通表遍历
local function calculateItemsCommon(list, key, val, items, costKey)
	for i, v1 in ipairs(list) do
		if i == val then
			break
		end

		if key then
			for k, v2 in csvMapPairs(v1["costItemMap"..key]) do
				items[k] = (items[k] or 0) + v2
			end
		end

		if costKey then
			local cost = v1["costGold"..costKey]
			items.gold = (items.gold or 0) + cost
		end
	end
end

-- _type 1: card  2； helditem
function RebirthTools.computeCost(items, _type)
	local cost = 0
	for _,data in ipairs(items) do
		if data.key == "gold" then
			cost = cost + math.ceil(data.val / gCommonConfigCsv.rebirthRMBCostByGold)

		elseif type(data.key) == "number" then
			local cfg = dataEasy.getCfgByKey(data.key)
			cost = cost + data.val * cfg.rebirthRMB
		end
	end
	local baseCost = cost
	local curTab = rebirthCostCsv[_type]
	local target = 0
	local lastPoint
	for i,v in ipairs(curTab) do
		if baseCost <= v.rmbPoint then
			target = target + cost * v.rmbRate
			break
		end
		local curPoint = v.rmbPoint
		if lastPoint then
			curPoint = v.rmbPoint - lastPoint
		end
		target = target + curPoint * v.rmbRate
		cost = cost - curPoint
		lastPoint = v.rmbPoint
	end
	local maxNum, minNum = gCommonConfigCsv.heldItemRebirthRMBCostLimit, gCommonConfigCsv.heldItemRebirthRMBCostMin
	if _type == 1 then
		maxNum, minNum = gCommonConfigCsv.rebirthRMBCostLimit, gCommonConfigCsv.cardRebirthRMBCostMin

	elseif _type == 3 then
		maxNum, minNum = gCommonConfigCsv.gemRebirthRMBCostLimit, gCommonConfigCsv.gemRebirthRMBCostMin

	elseif _type == 4 then
		maxNum, minNum = gCommonConfigCsv.chipRebirthRMBCostLimit, gCommonConfigCsv.chipRebirthRMBCostMin
	end

	return cc.clampf(math.ceil(target), minNum, maxNum)
end

function RebirthTools.computeCardReturnItem(dbId)
	local card = gGameModel.cards:find(dbId)
	local cardId = card:read("card_id")
	local skinId = card:read("skin_id")
	local cardLv = card:read("level")
	local star = card:read("star")
	local advance = card:read("advance")
	local skills = card:read("skills")
	local sumExp = card:read("sum_exp")
	local abilities = card:read("abilities")
	local itemsTab = csv.items
	local cardTab = csv.cards
	local skillTab =csv.skill
	local skillLvTab = csv.base_attribute.skill_level
	local expItems = {}
	local allExp = sumExp
	local len = table.length(gCardExpItemCsv)
	-- exp
	for i=len, 1, -1 do
		local specialArgsMap = gCardExpItemCsv[i].specialArgsMap
		local simpleExp = specialArgsMap.exp
		local num = math.floor(allExp / simpleExp)
		allExp = allExp - num * simpleExp
		if num > 0 then
			expItems[gCardExpItemCsv[i].id] = num
		end
	end
	-- advance
	local goldNum = 0
	local skill_point = 0
	local advanceItems = {}
	local cardInfo = cardTab[cardId]
	for i,v in ipairs(gCardAdvanceCsv[cardInfo.advanceTypeID]) do
		if i == advance then
			break
		end
		for k,v in csvMapPairs(v.itemMap) do
			advanceItems[k] = (advanceItems[k] or 0) + v
		end
		goldNum = goldNum + v.gold
	end
	-- skill
	for i, v in csvPairs(dataEasy.getCardSkillList(cardId,skinId)) do
		local skillLv = skills[v] or 1
		for k,vv in orderCsvPairs(skillLvTab) do
			if k == skillLv then
				break
			end
			goldNum = goldNum + vv["gold"..skillTab[v].costID]
		end
		-- skillPoint
		skill_point = skill_point + skillLv - 1
	end
	skill_point = math.ceil(skill_point * gCommonConfigCsv.rebirthRetrunProportion5)

	--ability
	local abilityItems = {}
	for pos, level in pairs(abilities) do
		local abilityCsv = gCardAbilityCsv[cardInfo.abilitySeqID][pos]
		local costDatas = {}
		local gold = 0
		for i=1,level do
			local costItemMap = csv.card_ability_cost[i]["costItemMap"..abilityCsv.strengthSeqID]
			for k,v in csvMapPairs(costItemMap) do
				if k == "gold" then
					goldNum = goldNum + v
				else
					abilityItems[k] = (abilityItems[k] or 0) + v
				end
			end
		end
	end
	goldNum = math.ceil(goldNum * gCommonConfigCsv.rebirthRetrunProportion1)
	local items = {}
	for k,v in pairs(expItems) do
		items[k] = items[k] or 0 + v
	end
	for k,v in pairs(advanceItems) do
		items[k] = items[k] or 0 + v
	end
	for k,v in pairs(abilityItems) do
		items[k] = items[k] or 0 + v
	end
	if goldNum > 0 then
		items.gold = (items.gols or 0) + goldNum
	end

	if skill_point > 0 then
		items.skill_point = (items.skill_point or 0) + skill_point
	end

	return items
end


function RebirthTools.computeEquipReturnItem(dbId)
	local equipTab = csv.equips
	local equipStrengthTab = csv.base_attribute.equip_strength
	local card = gGameModel.cards:find(dbId)
	local equips = card:read("equips")
	local items = {}

	local signetAdvanceList = {}
	for key, val in csvPairs(csv.base_attribute.equip_signet_advance) do
		signetAdvanceList[val.advanceIndex] = val
	end

	for _,equip in ipairs(equips) do
		local cfg =equipTab[equip.equip_id]

		-- level
		calculateItems(equipStrengthTab, nil, equip.level, items, cfg.strengthSeqID)

		-- advance
		calculateItemsCommon(gEquipAdvanceCsv[equip.equip_id], "", equip.advance, items, "")

		-- star
		calculateItems(csv.base_attribute.equip_star, cfg.starSeqID, equip.star, items)

		--ability
		calculateItems(csv.base_attribute.equip_ability, cfg.abilitySeqID, equip.ability, items)

		-- awake
		calculateItems(csv.base_attribute.equip_awake, cfg.awakeSeqID, equip.awake, items)

		-- awakeAbility
		calculateItems(csv.base_attribute.equip_awake_ability, cfg.awakeAbilitySeqID, equip.awake_ability, items)

		--signet
		calculateItems(csv.base_attribute.equip_signet, cfg.signetStrengthSeqID, equip.signet, items)

		--signetAdvance
		calculateItems(csv.base_attribute.equip_signet_advance_cost, signetAdvanceList[cfg.advanceIndex].advanceSeqID, equip.signet_advance, items)
	end

	if items.gold and items.gold > 0 then
		items.gold = math.ceil(items.gold * gCommonConfigCsv.rebirthRetrunProportion1)
	end

	return items
end

function RebirthTools.computeStarSkillPoints(dbId)
	--极限属性
	local card = gGameModel.cards:find(dbId)
	local items = {}
	if not card then
		return items
	end
	local cardId = card:read("card_id")
	local markId = csv.cards[cardId].cardMarkID
	local star_skill_points = 0
	local cardMarkID = csv.cards[cardId].cardMarkID
	local cardMarkCfg = csv.cards[cardMarkID]
	local starSkillSeqID = cardMarkCfg.starSkillSeqID
	local starSkill = csv.card_star_skill[starSkillSeqID].starSkillList
	local skills = card:read("skills")

	for k, v in ipairs(starSkill) do
		local skillLevel = skills[v] or 0
		local costId = csv.skill[v].costID
		for i = 1 ,skillLevel do
			if csv.base_attribute.skill_level[i - 1] then
				star_skill_points = star_skill_points + csv.base_attribute.skill_level[i - 1]["itemNum" .. costId]
			end
		end
	end
	star_skill_points =  math.ceil(star_skill_points * gCommonConfigCsv.rebirthRetrunProportion4)
	if star_skill_points > 0 then
		items["star_skill_points_"..markId] = (items["star_skill_points_"..markId] or 0) + star_skill_points
	end
	return items
end

function RebirthTools.getReturnItems(dbId)
	local item1 = RebirthTools.computeCardReturnItem(dbId)
	local item2 = RebirthTools.computeEquipReturnItem(dbId)
	local items = {}
	for k,v in pairs(item1) do
		items[k] = (items[k] or 0) + v
	end
	for k,v in pairs(item2) do
		items[k] = (items[k] or 0) + v
	end
	local targetItems = RebirthTools.sortItems(items)

	return targetItems, RebirthTools.computeCost(targetItems, 1)
end

function RebirthTools.isExpItem(key)
	if tonumber(key) and key >= 11 and key <= 16 then
		return true
	end
	return false
end

function RebirthTools.sortItems(items)
	local target = {}
	for k,v in pairs(items) do
		local val = v
		for i = 1, COIN_NUM do
			if k ~= "coin"..i then
				val = math.ceil(v * gCommonConfigCsv.rebirthRetrunProportion1)
			end
		end
		if k ~= "gold" and k ~= "skill_point" and k ~= "star_skill_points+"then
			val = math.ceil(v * gCommonConfigCsv.rebirthRetrunProportion1)
		end
		table.insert(target, {key = k, val = val})
	end
	-- 特殊物品顺序
	local typeOrder = {gold = 1, skill_point = 3, star_skill_points = 4}
	table.sort(target, function(a, b)
		local isFragA = dataEasy.isFragmentCard(a.key)
		local isFragB = dataEasy.isFragmentCard(b.key)
		if isFragA ~= isFragB then
			return isFragA
		elseif isFragA then
			local cfgA = dataEasy.getCfgByKey(a.key)
			local cfgB = dataEasy.getCfgByKey(a.key)
			local unitIDA = csv.cards[cfgA.combID].unitID
			local unitIDB = csv.cards[cfgB.combID].unitID
			local rA = csv.unit[unitIDA].rarity
			local rB = csv.unit[unitIDB].rarity
			return rA > rB
		end
		local orderA = typeOrder[a.key]
		local orderB = typeOrder[b.key]
		for i = 1, COIN_NUM do
			if a.key == "coin"..i then
				orderA = 2
			end
			if b.key == "coin"..i then
				orderB = 2
			end
		end
		if orderA == nil and string.find(a.key, "star_skill_points_%d+") then
			orderA = typeOrder["star_skill_points"]
		end
		if orderB == nil and string.find(b.key, "star_skill_points_%d+") then
			orderB = typeOrder["star_skill_points"]
		end
		if orderA and orderB then
			return orderA < orderB
		elseif orderA then
			return true
		elseif orderB then
			return false
		end

		local isExpA = RebirthTools.isExpItem(a.key)
		local isExpB = RebirthTools.isExpItem(b.key)
		if isExpA ~= isExpB then
			return isExpA
		elseif isExpA then
			local cfgA = csv.items[a.key]
			local cfgB = csv.items[b.key]
			return cfgA.quality > cfgB.quality
		end

		return a.key > b.key
	end)

	return target
end

-- 分解的消耗就是重生的消耗 分解本身是不消耗钻石的
function RebirthTools.computeDecomposeItems(dbIds)
	local cardsTab = csv.cards
	local rebirthItems, allItems = {}, {}
	-- 重生的消耗
	local allRMBCost = 0
	local goldCost = 0
	for _,data in pairs(dbIds or {}) do
		local dbId = data.dbid
		if not RebirthTools.isCardRebirthed(dbId) then
			local items, cost = RebirthTools.getReturnItems(dbId)
			allRMBCost = allRMBCost + cost
			for k,v in ipairs(items) do
				rebirthItems[v.key] = (rebirthItems[v.key] or 0) + v.val
			end
		end
		local card = gGameModel.cards:find(dbId)
		local baseStar = card:read("getstar")
		local csvId = card:read("card_id")
		local costUniversalCards = card:read("cost_universal_cards")
		local universalCardNum = 0
		for k,v in pairs(costUniversalCards or {}) do
			universalCardNum = universalCardNum + v
		end
		local cardInfo = cardsTab[data.id]
		local allCardNum = 0
		for i=baseStar,data.star - 1 do
			local costInfo = gStarCsv[cardInfo.starTypeID][i]
			goldCost = goldCost + costInfo.gold
			for k,v in csvMapPairs(costInfo.costItems) do
				allItems[k] = (allItems[k] or 0) + v
			end
			allCardNum = allCardNum + costInfo.costCardNum
		end
		local targetNum = allCardNum - universalCardNum
		-- 先乘系数
		local cfg = gStar2FragCsv[cardInfo.fragNumType]
		local baseFragNum = cfg[baseStar].baseFragNum
		local starFragNum = cfg[1].baseFragNum
		allItems[cardInfo.fragID] = (allItems[cardInfo.fragID] or 0) + (targetNum * starFragNum +  baseFragNum) * gCommonConfigCsv.rebirthRetrunProportion2

		local starSkillPoint = RebirthTools.computeStarSkillPoints(dbId)
		for k, v in pairs(starSkillPoint) do
			allItems[k] = (allItems[k] or 0) + v
		end
	end
	if goldCost > 0 then
		allItems.gold = math.ceil(goldCost * gCommonConfigCsv.rebirthRetrunProportion2)
	end
	for k,v in pairs(rebirthItems) do
		allItems[k] = (allItems[k] or 0) + v
	end
	--等价转化成其他物品
	local changeItems = {}
	for key,val in pairs(allItems) do
		if csv.fragments[key] then
			local equalItems = csv.fragments[key].decomposeGain
			for k,v in csvMapPairs(equalItems) do
				changeItems[k] = (changeItems[k] or 0) + v * val
			end
		else
			changeItems[key] = (changeItems[key] or 0) + val
		end
	end

	return RebirthTools.sortItems(changeItems), allRMBCost
end

function RebirthTools.computeHeldItemReturn(dbId)
	local heldItem = gGameModel.held_items:find(dbId)
	local advance = heldItem:read("advance")
	local csvId = heldItem:read("held_item_id")
	local level = heldItem:read("level")
	local allExp = heldItem:read("sum_exp")
	local costUniversalItems = heldItem:read("cost_universal_items")
	local lvTab = csv.held_item.level
	local info = csv.held_item.items[csvId]
	local itemsTab = csv.items
	local expItems = {}
	local gold = 0
	if allExp > 0 then
		gold = allExp * gCommonConfigCsv.heldItemExpNeedGold
		for i,v in ipairs(HELDITEMEXP) do
		 	local specialArgsMap = itemsTab[v].specialArgsMap
			local simpleExp = specialArgsMap.heldItemExp
			local num = math.floor(allExp / simpleExp)
			allExp = allExp - num * simpleExp
			if num > 0 then
				expItems[v] = num
			end
		end
	end
	local advanceItem = {}
	if advance > 0 then
		for i,v in orderCsvPairs(csv.held_item.advance) do
			if i == advance then
				break
			end
			for k,v in csvMapPairs(v["costItemMap" .. info.advanceSeqID]) do
				advanceItem[k] = (advanceItem[k] or 0) + v
			end
		end
	end
	local items = {}
	for k,v in pairs(expItems) do
		items[k] = math.ceil(v * gCommonConfigCsv.rebirthRetrunProportion3)
	end
	local universalItems = 0
	for k,v in pairs(costUniversalItems) do
		universalItems = universalItems + v
		local num = math.ceil(v * gCommonConfigCsv.rebirthRetrunProportion4)
		if num > 0 then
			items[k] =  num
		end
	end
	for k,v in pairs(advanceItem) do
		local itemNum = v
		if k <= game.HELD_ITEM_CSVID_LIMIT and k > game.FRAGMENT_CSVID_LIMIT then
			itemNum = v - universalItems
		end
		local num = math.ceil(itemNum * gCommonConfigCsv.rebirthRetrunProportion3)
		if num > 0 then
			items[k] =  num
		end
	end
	if gold > 0 then
		items.gold = math.ceil(gold * gCommonConfigCsv.rebirthRetrunProportion3)
	end
	local targetItems = RebirthTools.sortItems(items)

	return targetItems, RebirthTools.computeCost(targetItems, 2)
end

-- false: can rebirth
function RebirthTools.isCardRebirthed(dbId)
	if not dbId then
		return true
	end
	local card = gGameModel.cards:find(dbId)
	if not card then
		return true
	end
	local cardId = card:read("card_id")
	local cardLv = card:read("level")
	local equips = card:read("equips")
	local advance = card:read("advance")
	local skills = card:read("skills")
	local abilities = card:read("abilities")
	local result = true
	for i, v in csvPairs(csv.cards[cardId].skillList) do
		local skillLv = skills[v] or 1
		if skillLv > 1 then
			result = false
			break
		end
	end
	if not result then
		return result
	end
	if cardLv > 1 or advance > 1 then
		return false
	end

	for k,v in ipairs(equips) do
		if v.level > 1 or v.advance > 1 or v.star > 0 or v.awake > 0 or v.awake_ability > 0 or v.signet > 0 or v.signet_advance > 0 or v.ability > 0 then
			result = false
			break
		end
	end
	for _,level in pairs(abilities) do
		if level >= 1 then
			return false
		end
	end
	return result
end

-- false: can rebirth
function RebirthTools.isHeldItemRebirthed(dbId)
	if not dbId then
		return true
	end
	local heldItem = gGameModel.held_items:find(dbId)
	local advance = heldItem:read("advance")
	local sumExp = heldItem:read("sum_exp")
	if sumExp > 0 or advance > 0 then
		return false
	end

	return true
end

-- from:1 重生卡牌 2：分解
function RebirthTools.getSelectCard(from, curSle)
	curSle = curSle or {}
	local result = {}
	local csvTab = csv.cards
	local unitTab = csv.unit
	local hash = dataEasy.inUsingCardsHash()
	local cards = gGameModel.role:read("cards")--卡牌
	for i,v in ipairs(cards) do
		if from == 2 or (from == 1 and not RebirthTools.isCardRebirthed(v)) then
			local card = gGameModel.cards:find(v)
			local cardId = card:read("card_id")
			local skinId = card:read("skin_id")
			local cardCsv = csvTab[cardId]
			local unitCsv = unitTab[cardCsv.unitID]
			local unitId = dataEasy.getUnitId(cardId,skinId)
			local t = {
				id = cardId,
				unitId = unitId,
				rarity = unitCsv.rarity,
				fight = card:read("fighting_point"),
				level = card:read("level"),
				star = card:read("star"),
				advance = card:read("advance"),
				dbid = v,
				lock = card:read("locked"),
				battle = hash[v] and 1 or 2,
				battleType = hash[v],
				isUnion = isInUnion(v),
				isSel = itertools.include(curSle, v),
				markId = cardCsv.cardMarkID,
				cardType = cardCsv.cardType
			}
			table.insert(result, t)
		end
	end

	return result
end

function RebirthTools.isSingleInEvoLine(curDbId, selDbIds)
	selDbIds = selDbIds or {}
	local cardsCsv = csv.cards
	local selCardID = gGameModel.cards:find(curDbId):read('card_id')
	local cardMarkID = cardsCsv[selCardID].cardMarkID

	-- 当前选中的数量
	local sel = {}
	for _,dbId in pairs(selDbIds) do
		local cardID = gGameModel.cards:find(dbId):read('card_id')
		local markId = cardsCsv[cardID].cardMarkID
		if not sel[markId] then
			sel[markId] = {}
		end
		sel[markId][cardID] = (sel[markId][cardID] or 0) + 1
	end

	-- 当前选择的系列中一共有几个
	local t = {}
	local cards = gGameModel.role:read("cards")--卡牌
	for i,v in ipairs(cards) do
		local cardID = gGameModel.cards:find(v):read('card_id')
		local markId = cardsCsv[cardID].cardMarkID
		if markId == cardMarkID then
			if not t[markId] then
				t[markId] = {}
			end
			t[markId][cardID] = (t[markId][cardID] or 0) + 1
		end
	end

	-- 减去已选中的数量
	for cardId,num in pairs(sel[cardMarkID] or {}) do
		t[cardMarkID][cardId] = t[cardMarkID][cardId] - num
	end
	-- 减去当前选中的数量
	t[cardMarkID][selCardID] = t[cardMarkID][selCardID] - 1
	local result = true
	for cardId,num in pairs(t[cardMarkID]) do
		if num > 0 then
			result = false
			break
		end
	end

	return result
end

--符石重生
function RebirthTools.getReturnItemsGem(dbids)
	local data = {}
	local dataMap = {}
	local cost = 0
	local curData = {}
	local curDataMap = {}
	for _, dbid in pairs(dbids) do
		local gem = gGameModel.gems:find(dbid)
		local id = gem:read('gem_id')
		local level = gem:read('level')
		local cfg = dataEasy.getCfgByKey(id)
		curData = {}
		curDataMap = {}
		for i=1, level-1 do
			for key, num in csvMapPairs(csv.gem.cost[i]['costItemMap'..cfg.strengthCostSeq]) do
				if dataMap[key] then
					local tbl = data[dataMap[key]]
					tbl.val = tbl.val + num
				else
					table.insert(data, {key = key, val = num})
					dataMap[key] = #data
				end
				if curDataMap[key] then
					local tbl = curData[curDataMap[key]]
					tbl.val = tbl.val + num
				else
					table.insert(curData, {key = key, val = num})
					curDataMap[key] = #curData
				end
			end
		end
		cost = cost + RebirthTools.computeCost(curData, 3)
	end
	table.sort(data, function(a, b)
		if a.key == "gold" then
			return true
		elseif b.key == "gold" then
			return false
		else
			local qualityA = dataEasy.getCfgByKey(a.key).quality
			local qualityB = dataEasy.getCfgByKey(b.key).quality
			return qualityA >= qualityB
		end
	end)
	return data, cost
end


--芯片重生
function RebirthTools.getReturnItemsChip(dbids)

	local cost = 0
	local curData = {}
	local exp = 0
	local datas = {}
	local datasMap = {}
	local expDatas = {}

	for _, cfg in pairs(gChipExpCsv) do
		table.insert(expDatas, {id = cfg.id, num = cfg.specialArgsMap.chipExp})
	end
	table.sort(expDatas, function(v1, v2) return v1.num > v2.num end)

	local getCostItem = function(exp)
		local result = {}
		for _, data in ipairs(expDatas) do
			local count = math.floor(exp/data.num)
			exp = exp%data.num
			table.insert(result, {key = data.id, val = count})
		end
		return result
	end

	for _, dbid in pairs(dbids) do
		local chip = gGameModel.chips:find(dbid)
		local chipData = chip:read('chip_id', "level", "sum_exp")
		local exp = math.floor(chipData.sum_exp * gCommonConfigCsv.chipRebirthRetrunProportion)
		local curData = getCostItem(exp)
		table.insert(curData, {key = "gold", val = exp*gCommonConfigCsv.chipExpNeedGold})
		-- datasMap["gold"] = (datasMap["gold"] or 0) + exp*gCommonConfigCsv.chipExpNeedGold
		for index, data in pairs(curData) do
			datasMap[data.key] = (datasMap[data.key] or 0) + data.val
		end
		cost = cost + RebirthTools.computeCost(curData, 4)
	end

	for key, val in pairs(datasMap) do
		if val > 0 then
			table.insert(datas, {key = key, val = val})
		end
	end

	table.sort(datas, function(a, b)
		if a.key == "gold" then
			return true
		elseif b.key == "gold" then
			return false
		else
			local qualityA = dataEasy.getCfgByKey(a.key).quality
			local qualityB = dataEasy.getCfgByKey(b.key).quality
			return qualityA >= qualityB
		end
	end)
	return datas, cost
end
return RebirthTools