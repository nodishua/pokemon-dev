-- @date 2019-7-10
-- @desc 派遣任务 （通用方法）

local dispatchtaskTools = {}

local function createRichTxt(str, parent)
	local fontSize = matchLanguage({"kr"}) and 36 or 40
	local richText = rich.createByStr(str, fontSize, nil, nil, cc.p(0, 0.5))
		:anchorPoint(0, 0.5)
		:addTo(parent, 6)
	richText:formatText()
	richText:y(richText:size().height/2)
end
local CONDITION_TYPE = {
	{name = "star", note = gLanguageCsv.manyStars},
	{name = "advance", note = gLanguageCsv.manyClasses},
	{name = "rarity", note = gLanguageCsv.manyQualifications}
}
local function setConditionText(txtNode, str, state, typ)
	local color = ui.COLORS.NORMAL.DEFAULT
	if typ ~= 2 then
		color = state and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE
	end
	text.addEffect(txtNode, {color = color})
	if str ~= "" then
		txtNode:text(str)
	end
end
--普通条件2
local function setCondition2(txtNode, cardNums, csvTask, status)
	txtNode:removeAllChildren()
	if status ~= 2 then
		local str = string.format(gLanguageCsv.troopsOnTheBattlefield, csvTask.cardNums)
		setConditionText(txtNode, str, cardNums >= csvTask.cardNums, status)
	else
		txtNode:text("")
		local str = string.format("#C0x5b545b#"..gLanguageCsv.troopsOnTheBattlefield, "#C0xF76B45#"..csvTask.cardNums.."#C0x5b545b#")
		createRichTxt(str, txtNode)
	end
end
--额外条件1
local function setExtraCondition1(txtNode, condition1Num, csvTask, status)
	txtNode:removeAllChildren()

	local name = CONDITION_TYPE[csvTask.condition1].name
	local level, num = csvNext(csvTask.condition1Arg)
	local colorNum = "#C0xF76B45#"
	local colorNote = "#C0x5b545b#"
	if status ~= 2 then
		local color = condition1Num >= num and "#C0x60C456#" or "#C0xF76B45#"
		colorNum = color
		colorNote = color
	end
	local firStr = colorNum..level..colorNote
	if name == "advance" then
		local quality, numStr = dataEasy.getQuality(level, true)
		level = gLanguageCsv[ui.QUALITY_COLOR_TEXT[quality]]
		level = level .. numStr
		firStr = ui.QUALITY_OUTLINE_COLOR[quality] .. level .. colorNote
	end
	txtNode:text("")
	local str
	local textNote = CONDITION_TYPE[csvTask.condition1].note

	if name ~= "rarity" then
		local typStr = string.format(textNote, firStr)
		str = string.format(colorNote..gLanguageCsv.conditionsForBattle, colorNum..num..colorNote, typStr)
	else
		local icon = string.format("#I%s-60-60#", ui.RARITY_ICON[level])
		str = string.format(colorNote..textNote, icon, colorNum..num..colorNote)
	end
	createRichTxt(str, txtNode)
end
--额外条件2
local function setExtraCondition2(childs, cardNatures, attrItem, taskData, condition1Num, csvTask)
	local attrState = 0
	childs.attrList:removeAllChildren()
	for k,v in pairs(cardNatures) do
		local item = attrItem:clone():show()
		item:get("img"):visible(v.state)
		item:get("attrIcon"):texture(ui.ATTR_ICON[v.attr])
		local grayState = (v.state or taskData.status == 2) and cc.c3b(255, 255, 255) or cc.c3b(150, 150, 150)
		item:get("attrIcon"):color(grayState)
		if v.state then
			attrState = attrState + 1
		end
		childs.attrList:pushBackCustomItem(item)
	end
	local attrNum = itertools.size(cardNatures)
	setConditionText(childs.extraCondition2, "", attrState >= attrNum, taskData.status)
	--设置几率
	local gainChance = taskData.extraAwardPoint
	if gainChance == 0 then
		local level, num = csvNext(csvTask.condition1Arg)
		gainChance = (attrState / attrNum)*csvTask.cardNatureRate + 0.05 + ((condition1Num >= num) and csvTask.rate1 or 0)
	end
	childs.gainChance:visible(taskData.status ~= 2)
	gainChance = math.floor(gainChance*10)/10
	setConditionText(childs.gainChance, string.format(gLanguageCsv.gainChance,gainChance.."%"), gainChance >= 60, taskData.status)
end
--设置条件显示
function dispatchtaskTools.setItemCondition(conditionPanel, v, attrItem, typ)
	local childs = conditionPanel:multiget(
		"condition1",
		"condition2",
		"extraCondition1",
		"extraCondition2",
		"attrList",
		"gainChance"
	)
	local cardNums = 0
	local fight = 0
	local cardNatures = {}
	local csvTask = v.cfg
	local condition1Num = 0
	--条件1的条件和数量
	local level, num = csvNext(csvTask.condition1Arg)
	if typ ~= "main" then
		for k,v in pairs(csvTask.cardNatures) do
			cardNatures[v] = {attr = v, state = false}
		end
		for i,dbid in ipairs(v.cardIDs) do
			local cardData = gGameModel.cards:find(dbid):read("card_id", "advance", "fighting_point", "star")
			local cardCfg = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCfg.unitID]
			cardData.rarity = unitCsv.rarity
			cardNums = cardNums + 1
			fight = fight + cardData.fighting_point
			if cardNatures[unitCsv.natureType] then
				cardNatures[unitCsv.natureType].state = true
			end
			if unitCsv.natureType2 and cardNatures[unitCsv.natureType2] then
				cardNatures[unitCsv.natureType2].state = true
			end
			if cardData[CONDITION_TYPE[csvTask.condition1].name] >= level then
				condition1Num = condition1Num + 1
			end
		end
	else
		cardNums = csvTask.cardNums
		fight = v.taskData.reach_fighting_point or 0
		for k,v in pairs(v.taskData.reach or {}) do
			if k == 1 and v == 1 then
				condition1Num = num
			end
		end
		local hash = itertools.map(v.taskData.reach_natures or {}, function(k, v) return v, k end)
		for k,v in pairs(csvTask.cardNatures) do
			cardNatures[v] = {attr = v, state = hash[v] ~= nil}
		end
	end
	--条件1
	local condition1Str = string.format(gLanguageCsv.forceRequirement, fight, v.fightingPoint)
	setConditionText(childs.condition1, condition1Str, fight >= v.fightingPoint, v.status)
	--条件2
	setCondition2(childs.condition2, cardNums, csvTask, v.status)
	--额外条件1
	setExtraCondition1(childs.extraCondition1, condition1Num, csvTask, v.status)
	--额外条件2
	setExtraCondition2(childs, cardNatures, attrItem, v, condition1Num, csvTask)
end
--设置奖励物品
function dispatchtaskTools.setRewardPanel(list, rewardPanel, award, name, typ)
	-- 通用排序
	local awardDatas = {}
	for k,v in csvMapPairs(award) do
		table.insert(awardDatas, {
			key = k,
			num = v,
		})
	end
	table.sort(awardDatas, dataEasy.sortItemCmp)

	local i = 1
	local awardNum = #awardDatas
	for k,v in ipairs(awardDatas) do
		local num
		local index = i
		if (awardNum == 3 and typ == "main") then
			index = index == 1 and 3 or index - 1
		end
		local panel = rewardPanel:get(name..index)
		bind.extend(list, panel, {
			class = "icon_key",
			props = {
				data = {
					key = v.key,
				},
				onNode = function(node)
					local scale = typ == "main" and 0.6 or 0.7
					node:scale(scale)
					local box = node:box()
					local size = panel:size()
					local cfg = dataEasy.getCfgByKey(v.key)
					local quality = cfg.quality
					panel:removeChildByName("num")
					local num = cc.Label:createWithTTF(v.num, ui.FONT_PATH, 32)
						:align(cc.p(1, 0), size.width/2 + box.width/2 - 30*scale, size.height - box.height + 14*scale)
						:addTo(panel, 10, "num")
					text.addEffect(num, {outline={color=ui.COLORS.QUALITY_OUTLINE[quality]}})
				end,
			},
		})
		i = i + 1
	end
	if typ == "main" then
		local y = rewardPanel:get("bgLeft"):y() - 10
		local x = rewardPanel:get(name..3):x()
		if awardNum == 1 then
			rewardPanel:get(name..1):xy(x,y)
		end
		if awardNum == 2 then
			rewardPanel:get(name..1):xy(x - 70, y)
			rewardPanel:get(name..2):xy(x + 70, y)
		end
		if awardNum == 3 then
			rewardPanel:get(name..3):xy(x, y + 90)
			rewardPanel:get(name..2):xy(x - 80, y - 20)
			rewardPanel:get(name..1):xy(x + 80, y - 20)
		end
		rewardPanel:get(name..2):visible(awardNum > 1)
		rewardPanel:get(name..3):visible(awardNum > 2)
	else
		if awardNum == 1 then
			rewardPanel:get(name..1):x(rewardPanel:get(name..2):x())
		end
		if awardNum == 2 then
			local x = rewardPanel:get(name..2):x()
			rewardPanel:get(name..1):x(x - 100)
			rewardPanel:get(name..2):x(x + 100)
		end
	end
end
return dispatchtaskTools