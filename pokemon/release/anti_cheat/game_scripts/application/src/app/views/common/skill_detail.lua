--@date 2019-4-8 16:57:41
--@desc 技能界面详情

local SkillDetailView = class("SkillDetailView", Dialog)

SkillDetailView.RESOURCE_FILENAME = "common_skill_detail.json"
SkillDetailView.RESOURCE_BINDING = {
	["imgBg"] = "imgBg",
	["panel"] = "panel",
	["panel.imgType"] = "imgType",
	["panel.imgIcon"] = "imgIcon",
	["panel.textName"] = "skillName",
	["panel.textNoteType"] = "attackType",
	["panel.textLevel"] = "skillLv",
	["panel.textNote"] = "skillType",
	["panel.textSkillPower"] = "textSkillPower",
	["panel.textNum"] = "powerNum",
	["list"] = "list",
}

-- @params {skillId, skillLevel, cardId, star, skillIcon, ignoreStar, hideSkillLevel, isZawake}
function SkillDetailView:onCreate(params, typ)
	params.skillLevel = params.skillLevel or 1
	local skillCsv = csv.skill[params.skillId]
	if params.hideSkillLevel then
		self.skillLv:hide()
	else
		self.skillLv:text("Lv."..params.skillLevel)
	end

	itertools.invoke({self.textSkillPower, self.powerNum}, "hide")
	-- if skillCsv.skillType == battle.SkillType.NormalSkill then
		-- 技能威力先隐藏
		-- local skillPower = eval.doMixedFormula(tostring(skillCsv.skillPower),{skillLevel = params.skillLevel,math = math},nil)
		-- self.powerNum:text(skillPower)
		-- adapt.oneLinePos(self.textSkillPower, self.powerNum, cc.p(10, 0), "left")
	-- end

	uiEasy.setSkillInfoToItems({
		name = self.skillName,
		icon = self.imgIcon,
		type1 = self.imgType,
		type2 = self.skillType,
		target = self.attackType,
	}, skillCsv)
	if params.skillIcon then
		self.imgIcon:texture(params.skillIcon)
	end
	if params.isZawake then
		ccui.ImageView:create("city/drawcard/draw/txt_up.png")
			:scale(1.2)
			:align(cc.p(1, 1), 200, 190)
			:addTo(self.imgIcon, 1, "zawakeUp")
		local zawakeEffectID = csv.skill[params.skillId].zawakeEffect[1]
		self.skillName:text(csv.skill[zawakeEffectID].skillName .. self.skillName:text())
	end

	local desc = skillCsv.describe
	if params.isZawake and skillCsv.zawakeEffect[1] and skillCsv.zawakeEffect[2] ~= 1 then
		desc = skillCsv.zawakeEffectDesc
	end
	local starStr = params.ignoreStar and "" or uiEasy.getStarSkillDesc(params, typ)

	local list, height = beauty.textScroll({
		list = self.list,
		strs = "#C0x5B545B#" .. eval.doMixedFormula(desc,{skillLevel = params.skillLevel,math = math},nil) .. starStr,
		isRich = true,
		fontSize = 40,
	})
	local diffHeight = cc.clampf(height, 250, 750) - 250
	self.imgBg:size(self.imgBg:size().width, self.imgBg:size().height + diffHeight)
	self.panel:y(self.panel:y() + diffHeight/2)
	list:size(list:size().width, 250 + diffHeight)
	list:y(list:y() - diffHeight/2)

	Dialog.onCreate(self, {noBlackLayer = true, clickClose = false})
end

return SkillDetailView
