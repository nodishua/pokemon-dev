-- @date 2021-4-8
-- @desc z觉醒工具类 （通用方法）

local zawakeTools = {}

-- 属性加成类型
local ATTR_TYPE = {
	itself = 1,			--自身系列属性加成
	designated = 2, 	--指定元素精灵加成
	allTeam = 3 		--全体卡牌属性加成
}
zawakeTools.STAGE_OPEN_STATE = {
	open = 1,
	preview = 2,
	close = 3,
}

zawakeTools.MAXLEVEL = 8
zawakeTools.MAXSTAGE = 8

function zawakeTools.getLevelCfg(zawakeID, stageID, level)
	if gZawakeLevelsCsv[zawakeID] and gZawakeLevelsCsv[zawakeID][stageID] then
		return gZawakeLevelsCsv[zawakeID][stageID][level]
	end
end

-- 获取重生所有消耗
function zawakeTools.getResetCostItems(zawakeID, datas)
	local costDatas = {}
	for stageID, level in pairs(datas) do
		for i = 1, level do
			local cfg = zawakeTools.getLevelCfg(zawakeID, stageID, i)
			if not cfg then
				break
			end
			for key, val in csvMapPairs(cfg.costItemMap) do
				costDatas[key] = (costDatas[key] or 0) + val
			end
		end
	end
	for k, val in pairs(costDatas) do
		costDatas[k] = math.ceil(val * gCommonConfigCsv.zawakeResetOneKeyRatio)
	end
	return costDatas
end

-- 根据zawakeID获取对应card
function zawakeTools.getCardByZawakeID(zawakeID)
	local pokedex = gGameModel.role:read("pokedex")
	local cards = gGameModel.role:read("cards")
	local bagCardsHash = {}
	for _, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local fightPoint = card:read("fighting_point")
		local zawakeID = csv.cards[cardId].zawakeID
		if zawakeID > 0 then
			bagCardsHash[zawakeID] = bagCardsHash[zawakeID] or {}
			if not bagCardsHash[zawakeID].fightPoint or fightPoint > bagCardsHash[zawakeID].fightPoint then
				bagCardsHash[zawakeID].fightPoint = fightPoint
				bagCardsHash[zawakeID].dbId = v
				bagCardsHash[zawakeID].cardId = cardId
			end
		end
	end
	if bagCardsHash[zawakeID] then
		local cardId = bagCardsHash[zawakeID].cardId
		return {cardId = cardId, cfg = gCardsZawake[zawakeID][cardId], zawakeID = zawakeID, dbId = bagCardsHash[zawakeID].dbId}
	end
	local cardId
	for id, _ in pairs(gCardsZawake[zawakeID]) do
		if pokedex[id] then
			cardId = math.max(cardId or 0, id)
		end
	end
	return {cardId = cardId, cfg = gCardsZawake[zawakeID][cardId], zawakeID = zawakeID}
end

-- 获取拥有z觉醒的最大战力卡z觉醒ID
function zawakeTools.getFightPointMaxCard()
	local cards = gGameModel.role:read("cards")
	local allCards = {}
	local tFightPoint
	local tZawakeID
	for i, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local fightPoint = card:read("fighting_point")
		local zawakeID = csv.cards[cardId].zawakeID
		if zawakeTools.isOpenByStage(zawakeID) and (not tFightPoint or tFightPoint < fightPoint) then
			tFightPoint = fightPoint
			tZawakeID = zawakeID
		end
	end
	return tZawakeID
end

function zawakeTools.getAllCards()
	local cards = gGameModel.role:read("cards")
	local pokedex = gGameModel.role:read("pokedex")
	local allCards = {}
	local bagCardsHash = {}
	for _, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local fightPoint = card:read("fighting_point")
		local zawakeID = csv.cards[cardId].zawakeID
		if zawakeID > 0 then
			local maxFightPoint = bagCardsHash[zawakeID] and bagCardsHash[zawakeID].fightPoint or 0
			if fightPoint > maxFightPoint then
				bagCardsHash[zawakeID] = {cardId = cardId, fightPoint = fightPoint}
			end
		end
	end
	for zawakeID, zawakeDates in pairs(gCardsZawake) do
		if zawakeTools.isOpenByStage(zawakeID) then
			if bagCardsHash[zawakeID] then
				allCards[zawakeID] = {cfg = gCardsZawake[zawakeID][bagCardsHash[zawakeID].cardId], maxFightPoint = bagCardsHash[zawakeID].fightPoint}
			else
				local cardId
				for id, _ in pairs(zawakeDates) do
					if pokedex[id] then
						cardId = math.max(cardId or 0, id)
					end
				end
				if cardId then
					allCards[zawakeID] = {cfg = gCardsZawake[zawakeID][cardId], maxFightPoint = 0}
				end
			end
		end
	end
	return allCards
end

-- 获取觉醒效果加成类型
function zawakeTools.getAttrAddTypeStr(attrAddType, natureType)
	if attrAddType == ATTR_TYPE.designated then
		return string.format("[ %s ]", string.format(gLanguageCsv.zawakeFirstAttr, gLanguageCsv[game.NATURE_TABLE[natureType]]))
	end
	if attrAddType == ATTR_TYPE.allTeam then
		return string.format("[ %s ]", gLanguageCsv.allSprite)
	end
	return gLanguageCsv.skinBuff1
end

-- 获取觉醒之力对应等级加成描述
function zawakeTools.getAttrStr(cfg, isGray)
	local str = ""
	local scene = ""
	if cfg.attrAddType == ATTR_TYPE.designated then
		scene = gLanguageCsv[game.NATURE_TABLE[cfg.natureType]] .. gLanguageCsv.xi
	else
		scene = gLanguageCsv.allElves
	end

	local baseAttr = {}
	local allAttr = {}
	for _, id in pairs(game.ONESELF_NATURE_ENUM_TABLE) do
		baseAttr[id] = 0
	end
	for k=1, math.huge do
		local attrType = cfg["attrType" .. k]
		local attrNum = cfg["attrNum" .. k]
		if attrType == nil or attrType == 0 then break end
		allAttr[attrType] = attrNum
		baseAttr[attrType] = attrNum
	end
	local function valSame()
		local lastVal = -1
		for key, val in pairs(baseAttr) do
			if lastVal ~= -1 and lastVal ~= val then
				return false
			end
			lastVal = val
		end
		return true
	end
	if valSame() then
		if isGray then
			str = string.format("#C0xB7B09E#%s %s+%s", scene, gLanguageCsv.basicAttribute, cfg.attrNum1)
		else
			str = string.format("#C0x5B545B#%s %s#C0x60C456#+%s", scene, gLanguageCsv.basicAttribute, cfg.attrNum1)
		end
	else
		if isGray then
			str = str .. string.format("#C0xB7B09E#%s ", scene)
		else
			str = str .. string.format("#C0x5B545B#%s ", scene)
		end
		for k, num in pairs(allAttr) do
			if isGray then
				str = str .. string.format("#C0xB7B09E#%s+%s ", getLanguageAttr(k), dataEasy.getAttrValueString(k, num))
			else
				str = str .. string.format("#C0x5B545B#%s#C0x60C456#+%s ", getLanguageAttr(k), dataEasy.getAttrValueString(k, num))
			end
		end
	end
	return str
end

-- 根据阶段ID和zawakeID获取stages配表中相关信息
function zawakeTools.getStagesCfg(zawakeID, stageID)
	local zawakeData = zawakeTools.getCardByZawakeID(zawakeID)
	local zawakeID = zawakeData.cfg.zawakeID
	if gZawakeStagesCsv[zawakeID] and gZawakeStagesCsv[zawakeID][stageID] then
		return gZawakeStagesCsv[zawakeID][stageID], zawakeData
	end
	error(string.format("!!!csv.zawake.stages not exist zawakeID(%s), awakeSeqID(%s)", zawakeID, stageID))
end

function zawakeTools.isOpenByStage(zawakeID, stageID)
	if zawakeID == 0 then
		return false
	end
	stageID = stageID or 1
	local cfg = gZawakeStagesCsv[zawakeID] and gZawakeStagesCsv[zawakeID][stageID]
	if cfg and cfg.isOpen == zawakeTools.STAGE_OPEN_STATE.open then
		return true
	end
	return false
end

-- markID -1 为自身，读 zawakID 的精灵，否则读 markID 的精灵
function zawakeTools.isUnlockByKey(key, val, zawakeID, markID)
	markID = markID or -1
	local cardMarkID = markID
	if cardMarkID == -1 then
		local _, cfg = next(gCardsZawake[zawakeID])
		cardMarkID = cfg.cardMarkID
	end
	local bagCards = {}
	for _, v in ipairs(gGameModel.role:read("cards")) do
		local card = gGameModel.cards:find(v)
		local id = card:read("card_id")
		local cardCfg = csv.cards[id]
		if (markID ~= -1 and cardCfg.cardMarkID == markID) or (markID == -1 and cardCfg.zawakeID == zawakeID) then
			table.insert(bagCards, card)
		end
	end
	local function getCardAttrState(attrKey, val, isSum, secondKey, secondKey1)
		for _, card in ipairs(bagCards) do
			local attr = card:read(attrKey)
			if isSum then
				local sum = 0
				for k, v in pairs(attr) do
					sum = sum + (secondKey and v[secondKey] or v)
					if secondKey1 then
						sum = sum + v[secondKey1] or 0
					end
				end
				if sum >= val then
					return true
				end
			else
				if attr >= val then
					return true
				end
			end
		end
		return false
	end
	if key == "goodFeel" then
		-- 好感度等级
		local cardFeels = gGameModel.role:read("card_feels")
		local cardFeel = cardFeels[cardMarkID] or {}
		local level = cardFeel.level or 0
		if level >= val then
			return true
		end
	elseif key == "equipStarSum" then
		-- 饰品总星级
		return getCardAttrState("equips", val, true, "star", "ability")
	elseif key == "equipAwakeSum" then
		-- 饰品总觉醒
		return getCardAttrState("equips", val, true, "awake", "awake_ability")
	elseif key == "equipSignetAdvanceSum" then
		-- 饰品总刻印等级
		return getCardAttrState("equips", val, true, "signet_advance")
	elseif key == "zawakeStage" then
		-- Z觉醒阶段
		local zawake = gGameModel.role:read("zawake") or {}
		local stage = math.floor(val / 100)
		local level = val % 100
		for _, card in ipairs(bagCards) do
			local id = card:read("card_id")
			local cardCfg = csv.cards[id]
			local data = zawake[cardCfg.zawakeID] or {}
			if (data[stage] or 0) >= level then
				return true
			end
		end
	elseif key == "star" then
		-- 精灵星级
		return getCardAttrState("star", val)
	elseif key == "nvalueSum" then
		-- 个体值总和
		return getCardAttrState("nvalue", val, true)
	elseif key == "advance" then
		-- 突破阶段
		return getCardAttrState("advance", val)
	elseif key == "effort" then
		-- 精灵努力值阶段
		return getCardAttrState("effort_advance", val)
	elseif key == "gemQuality" then
		for _, card in ipairs(bagCards) do
			local qualityNum = dataEasy.getGemQualityIndex(card)
			if qualityNum >= val then
				return true
			end
		end
	end
	return false
end

-- 获取激活条件的描述
function zawakeTools.getLabelByLimit(key, val, state)
	local endStr = "#C0xF76B45#" .. gLanguageCsv.notFinished
	if state then
		endStr = " #Icity/card/evolution/logo_tick1.png-0.8#"
	end
	local numStr = val
	if key == "advance" then
		local quality, numStr1 = dataEasy.getQuality(val, true)
		numStr = ui.QUALITY_OUTLINE_COLOR[quality] .. gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]] .. numStr1
	else
		if key == "zawakeStage" then
			numStr = gLanguageCsv.effortAdvance .. gLanguageCsv['symbolRome'..math.floor(val/100)]
			if val%100 > 0 then
				numStr = numStr .. "- " .. val%100
			end
		elseif key == "effort" then
			numStr = gLanguageCsv.effortAdvance .. dataEasy.getRomanNumeral(val)

		elseif key == "star" then
			numStr = "x"..numStr
		end
		numStr = state and ("#C0x60C456#" .. numStr) or ("#C0xF76B45#" .. numStr)
	end
	return string.format(gLanguageCsv["zawakeAttr"..string.caption(key)], numStr) .. endStr
end

-- 获得解锁条件
function zawakeTools.getActiveCondition(zawakeID, stageID, cfg)
	if csvSize(cfg.extraAttrs) == 0 and cfg.skillID == 0 then return end
	local datas = {}
	local labelDatas = {}
	local active = true
	for key, val in csvMapPairs(cfg.activeReq) do
		local state = zawakeTools.isUnlockByKey(key, val, zawakeID)
		local str = "#C0x5B545B#·" .. zawakeTools.getLabelByLimit(key, val, state)
		table.insert(labelDatas, str)
		if state == false then
			active = false
		end
	end
	return active, labelDatas
end

-- 阶段解锁条件
function zawakeTools.isUnlockByStage(stageCfg, zawakeID)
	local labelDatas = {}
	local unlockDatas = {}
	local isSelf = false
	for k=1, 2 do
		local data = {}
		local firstText = gLanguageCsv.zawakeSelf
		local isSelf = true
		local cardMarkID = stageCfg["unlockType"..k]
		if cardMarkID ~= -1 then
			local card = zawakeTools.getMinCardCfgByMarkID(cardMarkID)
			firstText = string.format(gLanguageCsv.series, card.name)
			isSelf = false
		end
		for key, val in csvMapPairs(stageCfg["unlockLimit"..k]) do
			local state = zawakeTools.isUnlockByKey(key, val, zawakeID, cardMarkID)
			table.insert(data, {key = key, val = val, state = state})
		end

		if itertools.size(data) > 0 then
			unlockDatas[cardMarkID] = {firstText = firstText, data = data, isSelf = isSelf}
		end
	end
	local allUnlock = true
	for cardMarkID, limitDatas in pairs(unlockDatas) do
		for key, data in pairs(limitDatas.data) do
			local str = "#C0x5B545B#·" .. limitDatas.firstText .. zawakeTools.getLabelByLimit(data.key, data.val, data.state)
			table.insert(labelDatas, str)
			if data.state == false then
				allUnlock = false
			end
		end
	end
	return allUnlock, labelDatas
end


function zawakeTools.getStageIsUnlock(zawakeID, stageID)
	local cfg, zawakeData = zawakeTools.getStagesCfg(zawakeID, stageID)
	local isUnlock, labelDatas = zawakeTools.isUnlockByStage(cfg, zawakeID)
	return isUnlock
end

function zawakeTools.canAwake(zawakeID, stageID, level)
	if zawakeID == 0 then return false end
	if not zawakeTools.isOpenByStage(zawakeID, stageID) then return false end
	local levelCfg = zawakeTools.getLevelCfg(zawakeID, stageID, level)
	local zawake = gGameModel.role:read("zawake") or {}
	local stage = zawake[zawakeID] or {}
	local stageLevel = stage[stageID] or 0
	if level <= stageLevel then
		return false
	end
	local stageIsUnlock = zawakeTools.getStageIsUnlock(zawakeID, stageID)
	if stageIsUnlock and levelCfg then
		-- 判断解锁前置条件, 连续升级
		if stageID ~= 1 or level ~= 1 then
			local tmpStageID = stageID
			local tmpLevel = level - 1
			if tmpLevel == 0 then
				tmpStageID = tmpStageID - 1
				tmpLevel = zawakeTools.MAXLEVEL
			end
			local stageLevel = stage[tmpStageID] or 0
			if stageLevel < tmpLevel then
				return false
			end
		end
		-- 判断消耗材料
		for key, val in csvMapPairs(levelCfg.costItemMap) do
			local num = dataEasy.getNumByKey(key)
			if num < val then
				return false
			end
		end
	else
		return false
	end
	return true
end

-- 获取技能cfg
function zawakeTools.getSkillCfg(zawakeID, zawakeSkillID)
	if not zawakeSkillID or zawakeSkillID == 0 or zawakeID == 0 then
		return
	end
	local cardData = zawakeTools.getCardByZawakeID(zawakeID)
	local skillList = cardData.cfg.skillList
	-- 一个 zawakeID 会对应多个技能
	local ret = {}
	for _, id in csvMapPairs(skillList) do
		local zawakeEffect = csv.skill[id].zawakeEffect[1]
		if zawakeEffect and zawakeEffect == zawakeSkillID then
			table.insert(ret, {cfg = csv.skill[id], id = id, cardId = cardData.cardId})
		end
	end
	if #ret > 0 then
		return ret
	end
	printInfo("zawakeSkillID(%s) was not in cards zawakeID(%s)", zawakeSkillID, zawakeID)
end

function zawakeTools.getMinCardCfgByMarkID(markID)
	for branch, card in pairs(gCardsCsv[markID][1]) do
		return card
	end
end

function zawakeTools.getMaxStageLevel(zawakeID)
	local zawake = gGameModel.role:read("zawake") or {}
	local stage, level
	for k, v in pairs(zawake[zawakeID] or {}) do
		if (not stage or stage < k) and v > 0 then
			stage = k
			level = v
		end
	end
	return stage, level
end

return zawakeTools
