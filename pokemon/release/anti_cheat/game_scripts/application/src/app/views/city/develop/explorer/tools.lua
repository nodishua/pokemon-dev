-- @date 2019-6-28 11:13:00
-- @desc 携带道具工具类 （通用方法）

local ExplorerTools = {}

function ExplorerTools.effectShow(mainList, extraList, data)
	local skillLevel = math.max(1, data.advance)
	local mainStrs = {}
	for k,v in pairs(data.cfg.effect) do
		local effect = csv.explorer.explorer_effect[v]
		local str
		if effect.skillID then
			local skillCsv = csv.skill[effect.skillID]
			local currStr = string.format(effect.effectDesc, eval.doMixedFormula(skillCsv.describe, {skillLevel = skillLevel,math = math}, nil))
			str = "#C0x5B545B#" .. currStr
		else
			if effect.attrType1 and effect.attrType2 and effect.attrType3 and effect.attrType4 and effect.attrType5 and effect.attrType6 then
				local attrNum = dataEasy.getAttrValueString(effect.attrType1, effect.attrNum1[skillLevel])
				str = string.format(effect.effectDesc, attrNum)
			else
				local params = {}
				for i = 1, 6 do
					if effect["attrType"..i] and effect["attrNum"..i] then
						local attrType = getLanguageAttr(effect["attrType"..i])
						local attrNum = dataEasy.getAttrValueString(effect["attrType"..i], effect["attrNum"..i][skillLevel])
						table.insert(params,attrType)
						table.insert(params,attrNum)
					end
				end
				str = string.format(effect.effectDesc, unpack(params))
			end
		end
		table.insert(mainStrs, {str = str})
	end
	--主要效果
	beauty.textScroll({
		list = mainList,
		effect = {color=ui.COLORS.NORMAL.DEFAULT},
		strs = mainStrs,
		isRich = true,
		margin = 20,
		align = "left",
	})


	local strs = {}
	for i,v in ipairs(data.cfg.extraEff) do
		local effect = csv.explorer.explorer_effect[v]
		if effect.skillID then
			local skillCsv = csv.skill[effect.skillID]
			local currStr = string.format(str, eval.doMixedFormula(skillCsv.describe, {skillLevel =  skillLevel,math = math}, nil))
			table.insert(strs, {str = "#C0x5B545B#" .. currStr})
		else
			local params = {}
			for i = 1, 6 do
				if effect["attrType"..i] and effect["attrNum"..i] then
					local attrType = getLanguageAttr(effect["attrType"..i])
					local attrNum = dataEasy.getAttrValueString(effect["attrType"..i], effect["attrNum"..i][skillLevel])
					table.insert(params,attrType)
					table.insert(params,attrNum)
				end
			end
			local str = string.format(effect.effectDesc, unpack(params))
			table.insert(strs, {str = str})
		end
	end
	--额外效果
	beauty.textScroll({
		list = extraList,
		effect = {color=ui.COLORS.NORMAL.DEFAULT},
		strs = strs,
		isRich = true,
		margin = 20,
		align = "left",
	})
	for i,v in ipairs(strs) do
		local label = extraList:get(i, "label")
		label:setCascadeOpacityEnabled(true)
		if skillLevel >= data.cfg.extraEffCod[i] then
			label:setOpacity(255)
		else
			label:setOpacity(130)
		end
	end
end

function ExplorerTools.getMinComponentLevel(components)
	local minLevel = 100
	for i,v in ipairs(components) do
		minLevel = math.min(minLevel, v.level)
	end
	return minLevel
end

return ExplorerTools