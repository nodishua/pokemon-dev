-- @date 2019-11-5
-- @desc 卡牌特性 （通用方法）

local abilityStrengthenTools = {}
--
local CONDITION = {
	buffCardHp = 1,
	buffCardMp = 2,
	buffCardDead = 3
}

function abilityStrengthenTools.setEffect(params)
	--必填参数
	local parent = params.parent
	local spinePath = params.spinePath
	--选填参数
	local offsetX = params.offsetX or 0
	local offsetY = params.offsetY or 0
	local zOrder = params.zOrder or 10
	local scale = params.scale or 1
	local effectName = params.effectName or "effect"

	local size = parent:size()
	local effect = parent:get("effect")
	if not effect then
		effect = widget.addAnimationByKey(parent, spinePath, "effect", effectName, zOrder)
			:xy(size.width/2 + offsetX, size.height/2 + offsetY)
			:scale(scale)
	else
		effect:show():play(effectName)
	end
end

function abilityStrengthenTools.getConditionStr(selectDbId, abilityId)
	local conditionStr = {}
	local card = gGameModel.cards:find(selectDbId)
	if not card then
		return {}
	end
	local abilities = card:read("abilities")
	local cardLv = card:read("level")
	local advance = card:read("advance")

	local abilityCsv = csv.card_ability[abilityId]
	--激活条件(1-精灵等级 2-突破品质)
	local strengthCod1 = abilityCsv.strengthCod1
	if strengthCod1[1] == 1 and cardLv < strengthCod1[2] then
		table.insert(conditionStr, string.format(gLanguageCsv.needSpriteLevelAchieve, strengthCod1[2]))
	end
	if strengthCod1[1] == 2 and advance < strengthCod1[2] then
		local quality, numStr = dataEasy.getQuality(strengthCod1[2])
		table.insert(conditionStr, string.format(gLanguageCsv.needSpriteAdvanceAchieve, gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]]..numStr))
	end
	--激活非必需条件(前置特性等级)
	local strengthCod2 = abilityCsv.strengthCod2
	for k, preID in orderCsvPairs(abilityCsv.preAbilityID) do
		local preLv = abilities[preID] or 0
		if preLv >= strengthCod2 then
			break
		end
		if k == csvSize(abilityCsv.preAbilityID) then
			table.insert(conditionStr, string.format(gLanguageCsv.needPreSkillLevelAchieve, strengthCod2))
		end
	end
	return conditionStr
end



return abilityStrengthenTools