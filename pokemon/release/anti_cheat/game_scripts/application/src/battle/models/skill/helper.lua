
-- 临时实现，后期整理

local skillHelper = {}
globals.skillHelper = skillHelper

-- 补充:双属性的单位克制计算, 双属性的克制计算规则 是把每个属性的克制计算后,再相乘
-- natureOrder:表示是第几号属性
function skillHelper.natureRestraint(skillNatureType, target, natureOrder, natureRestraintCEx, natureResistance)
	if not skillNatureType then return end
	local objNatureName = game.NATURE_TABLE[target:getNature(natureOrder)]
	return skillHelper.getNatureMatrix(skillNatureType,objNatureName,natureRestraintCEx, natureResistance)
end

local function checkNatureMatrixCheat(nature)
	if ANTI_AGENT then return end

	checkSpecificCsvCheat({"base_attribute", "nature_matrix"}, itertools.ivalues({nature}))
end

function skillHelper.getNatureMatrix(nature1,natureName,natureRestraintCEx,natureResistance)
	if nature1 and natureName and csv.base_attribute.nature_matrix[nature1] then
		checkNatureMatrixCheat(nature1)
		local baseValue = csv.base_attribute.nature_matrix[nature1][natureName]
		local fixValue = 0
		if baseValue > 1 then
			fixValue = math.max(-natureResistance, 1 - baseValue)
		end
		if baseValue > 1 or (nature1 == 1 and baseValue >= 1) then
			fixValue = fixValue + natureRestraintCEx
		end
		return baseValue + fixValue
	end
	return 1
end

function skillHelper.getNatureFlag(val)
	local absDelta = math.abs(val - 1)
	if absDelta < 0.01 then
		return 'normal', 1
	elseif val > 1 then
		return 'strong', string.format("%.2f",val)
	elseif val > 0 then
		return 'weak', string.format("%.2f",val)
	else
		return 'fullweak', 0
	end
end

function skillHelper.natureRestraintType(skillNatureType, target, natureRestraintCEx, natureResistance)
	local val
	natureRestraintCEx = natureRestraintCEx or 0 --额外修正值 由buff控制<natureRestraint>
	natureResistance = natureResistance or 0
	local resistVal1 = skillHelper.natureRestraint(skillNatureType, target, 1, natureRestraintCEx, natureResistance) or 1
	local resistVal2 = skillHelper.natureRestraint(skillNatureType, target, 2, natureRestraintCEx, natureResistance) or 1
	val = 1+(resistVal1-1) + (resistVal2-1)

	return skillHelper.getNatureFlag(val)
end

return skillHelper
