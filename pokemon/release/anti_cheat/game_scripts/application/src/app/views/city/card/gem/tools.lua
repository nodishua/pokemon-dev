local GemTools = {}

function GemTools.equipGem(carddbid, slotIdx, dbid, cb)
	if GemTools.isSlotLocked(carddbid, slotIdx) then
		gGameUI:showTip(gLanguageCsv.notUnlock)
		return
	end
	local gem_id = gGameModel.gems:find(dbid):read('gem_id')
	local cfg = dataEasy.getCfgByKey(gem_id)
	local gemMap = GemTools.suitTypeMap(carddbid)
	local carddbidnew = gGameModel.gems:find(dbid):read('card_db_id')
	if not carddbidnew
		and (gemMap[cfg.suitID] and gemMap[cfg.suitID][cfg.suitNo])
		or gemMap[gem_id] then
		gGameUI:showTip(gLanguageCsv.sameGemID)
		return
	end
	gGameApp:requestServer('/game/gem/equip', function(tb)
		if cb then
			cb()
		end
		gGameUI:showTip(gLanguageCsv.inlaySuccess)
	end, carddbid, dbid, slotIdx)
end

function GemTools.swapGem(carddbid, slotIdx, new)
	if GemTools.isSlotLocked(carddbid, slotIdx) then
		gGameUI:showTip(gLanguageCsv.notUnlock)
		return
	end
	local old = gGameModel.cards:find(carddbid):read('gems')[slotIdx]
	local gem_id = gGameModel.gems:find(new):read('gem_id')
	local cfg = dataEasy.getCfgByKey(gem_id)
	local carddbid = gGameModel.gems:find(old):read('card_db_id')
	local map = GemTools.suitTypeMap(carddbid)

	local carddbidnew = gGameModel.gems:find(new):read('card_db_id')
	if not carddbidnew
		and (map[cfg.suitID]
			and map[cfg.suitID][cfg.suitNo]
			and map[cfg.suitID][cfg.suitNo] ~= slotIdx)
		or map[gem_id] then
		gGameUI:showTip(gLanguageCsv.sameGemID)
		return
	end
	gGameApp:requestServer('/game/gem/swap', function()
		gGameUI:showTip(gLanguageCsv.exchange2Success)
	end, old, new)
end

function GemTools.unEquipGem(carddbid, slotIdx)
	local gems = gGameModel.cards:find(carddbid):read('gems')
	gGameApp:requestServer('/game/gem/unload', function()
		gGameUI:showTip(gLanguageCsv.dischargeSuccess)
	end, {gems[slotIdx]})
end

function GemTools.suitTypeMap(carddbid)
	local gems = gGameModel.cards:find(carddbid):read('gems')
	local gemMap = {}
	for i, gemid in pairs(gems) do
		local gem_id = gGameModel.gems:find(gemid):read('gem_id')
		local cfg = dataEasy.getCfgByKey(gem_id)
		if cfg.suitID and cfg.suitNo then
			if not gemMap[cfg.suitID] then
				gemMap[cfg.suitID] = {}
			end
			gemMap[cfg.suitID][cfg.suitNo] = i
		else
			gemMap[gem_id] = i
		end
	end
	return gemMap
end

function GemTools.isSlotLocked(carddbid, slotIdx)
	local cardCfg = csv.cards[gGameModel.cards:find(carddbid):read('card_id')]
	local condition = gGemPosCsv[cardCfg.gemPosSeqID][slotIdx].openCondition
	if condition[1] == 1 then
		local role_level = gGameModel.role:read('level')
		if role_level < condition[2] then
			return true, string.format(gLanguageCsv.openLv, condition[2])
		end

	elseif condition[1] == 2 then
		local quality, space = dataEasy.getQuality(condition[2])
		return true, string.format(gLanguageCsv.openAdvance, gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]]..space)
	end

	return false
end

function GemTools.moveGem(carddbid, slotIdx, gemid, errCb)
	if GemTools.isSlotLocked(carddbid, slotIdx) then
		gGameUI:showTip(gLanguageCsv.notUnlock)
		if errCb then
			errCb()
		end
		return
	end
	gGameApp:requestServer('/game/gem/pos/change', function()
		gGameUI:showTip(gLanguageCsv.exchange2Success)
	end, gemid, slotIdx)
end

return GemTools