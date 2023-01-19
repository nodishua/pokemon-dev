-- @date 2019-6-28 11:13:00
-- @desc 携带道具工具类 （通用方法）

local HeldItemTools = {}

-- data: {csvId, dbId}
function HeldItemTools.isExclusive(data)
	local isDress, isExclusive = false, false
	local dbId = type(data.dbId) == "table" and data.dbId[1] or data.dbId
	if dbId then
		local dbData = gGameModel.held_items:find(dbId)
		-- assertInWindows(dbData, "helditem dbId(%s) not in model.held_items", stringz.bintohex(dbId))
		if dbData and dbData:read("card_db_id") then
			isDress = true
		end
	end
	local heldItemInfo = csv.held_item.items[data.csvId]
	if heldItemInfo and itertools.size(heldItemInfo.exclusiveCards) > 0 then
		isExclusive = true
	end

	return isDress, isExclusive
end

function HeldItemTools.insertColor(str, color, isName, idx, single, defaultColor)
	defaultColor = defaultColor or "#C0x5B545B#"
	idx = idx or 1
	local isSingleSet = true
	local ts = ""
	local t = string.split(str, "%s")
	local len = #t
	for k,v in ipairs(t) do
		if ((single and isSingleSet) or not single) and k >= idx and k < len then
			ts = ts .. v .. color .."%s" .. defaultColor
			if single then
				isSingleSet = false
			end
		else
			ts = ts .. v .. "%s"
		end
	end
	ts = string.sub(ts, 1, string.len(ts) - 2)

	return ts
end

function HeldItemTools.getRellyAdvance(csvId, advance)
	local cfg = csv.held_item.items[csvId]
	if not cfg or not advance then
		return advance
	end
	local allAdv = {}
	for i=1,math.huge do
		if not cfg['effect'..i] or cfg['effect'..i] == 0 then
			break
		end
		local advanceTab = cfg[string.format("effect%dLevelAdvSeq", i)]
		for _,v in ipairs(advanceTab) do
			table.insert(allAdv, v)
		end
	end
	local state = itertools.include(allAdv, advance)
	if state then
		return advance
	end
	table.sort(allAdv)
	local result = advance
	for i,v in ipairs(allAdv) do
		if v > advance then
			result = allAdv[i - 1]
			break
		end
	end

	return result
end

function HeldItemTools.insertSkillDescColor(skillDesc, nomalColor, defaultColor)
	local list = string.split(skillDesc, "$")
	local desc = ""
	for i,v in pairs(list) do
		local str = clone(v)
		local pos = string.find(str,"skillLevel")
		if pos then
			local symbol = ""
			if list[i+1] and string.find(list[i+1],"^%%") then
				symbol = "%"
				list[i+1] = string.gsub(list[i+1],"^%%","")
			end
			str = string.format("%s$%s$%s%s", nomalColor, str, symbol, defaultColor)
		end
		desc = desc .. str
	end
	return desc
end

function HeldItemTools.getStrinigByData(i, data)
	local cfg = data.cfg
	local relAdvance = HeldItemTools.getRellyAdvance(data.csvId, data.advance)
	local effectId = cfg["effect" .. i]
	local efectVal = cfg[string.format("effect%dLevelAdvSeq", i)]
	local valIdx = 0
	local skillLv = relAdvance + 1 -- （技能等级 默认1级 然后和efectVal下标对应 增加数量 = idx - 1）
	local maxIdx = csvSize(efectVal)
	for k,v in ipairs(efectVal) do
		if relAdvance < v then
			valIdx = k - 1
			break
		elseif relAdvance == v or k == maxIdx then
			valIdx = k
			break
		end
	end
	local effectTab = csv.held_item.effect
	local efcInfo = effectTab[effectId]
	local str = efcInfo.desc
	local params = {}
	local startIdx = 1
	-- 是否专属
	if efcInfo.exclusiveCards[1] then
		-- 是专属的话 第一个参数就是英雄名字
		local markId = efcInfo.exclusiveCards[1]
		local cardMarkCfg = csv.cards[markId]
		local unitCfg = csv.unit[cardMarkCfg.unitID]
		table.insert(params, cardMarkCfg.name)
		local natureType = unitCfg.natureType
		local color = ui.ATTRCOLOR[game.NATURE_TABLE[natureType]]
		str = HeldItemTools.insertColor(str, color, true, startIdx, true)
		startIdx = startIdx + 1
	end
	local insertColor = "#C0x60c456#"--ui.QUALITYCOLOR[2]
	-- 属性类型
	if efcInfo.type == 1 then
		for i=1,100 do
			if not efcInfo["attrNum" .. i] then
				break
			end
			local efcVal = efcInfo["attrNum" .. i][valIdx]
			local efcType = efcInfo["attrType" .. i]
			table.insert(params, dataEasy.getAttrValueString(efcType, efcVal))
		end
	-- 技能类型
	elseif efcInfo.type == 2 then
		insertColor = ui.QUALITY_OUTLINE_COLOR[1]
		local desc = csv.skill[efcInfo.skillID].describe
		-- 技能描述是一长段话 需要对公式那部分单独处理颜色
		desc = HeldItemTools.insertSkillDescColor(desc, "#C0x60c456#", "#C0x5B545B#")
		table.insert(params, eval.doMixedFormula(desc, {skillLevel = skillLv, math = math}))
	end
	str = HeldItemTools.insertColor(str, insertColor, false, startIdx, false)
	local idx = string.find(str, "%%s")
	if #params <= 0 and idx then
		return
	end

	return string.format(str, unpack(params))
end

function HeldItemTools.getCardNameColor(cardDbId)
	local card = gGameModel.cards:find(cardDbId)
	local advance = card:read("advance")
	local quality, numStr = dataEasy.getQuality(advance)
	local color = ui.COLORS.QUALITY_OUTLINE[quality]
	local str = "#C0x"
	for _,v in ipairs({'r', 'g', 'b'}) do
		str = str .. string.sub(string.format("%#x",color[v]), 3, 4)
	end
	str = str .. '#'

	return str, numStr
end


return HeldItemTools