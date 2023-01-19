-- @date:   2019-1-17
-- @desc:   图鉴技能界面
-- @date:   2019-4-2 15:16:06
-- @desc    UI迭代

local HandbookSkillView = class("HandbookSkillView", cc.load("mvc").ViewBase)

HandbookSkillView.RESOURCE_FILENAME = "handbook_skill.json"
HandbookSkillView.RESOURCE_BINDING = {
	["skillItem"] = "skillItem",
	["panel"] = "panel",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("skillDatas"),
				item = bindHelper.self("skillItem"),
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, v)
					node:get("textLVNum"):text(v.skillLevel)
					uiEasy.setSkillInfoToItems({
						name = node:get("textSkillName"),
						icon = node:get("imgIcon"),
						type1 = node:get("imgFlag"),
					}, v.skillId)

					bind.touch(list, node:get("btnInfo"), {methods = {ended = functools.partial(list.clickItem, v)}})
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickItem, v)}})
				end,
			},
			handlers = {
				clickItem = bindHelper.self("onShowSkillInfo"),
			},
		},
	},
}

function HandbookSkillView:onCreate(params)
	self.cardIdIdler = params.selCardId()
	self.skillDatas = idlertable.new({})
	idlereasy.when(self.cardIdIdler, function(_, cardId)
		if cardId == 0 then
			return
		end
		local skillDatas = {}
		local cardcfg = csv.cards[cardId]
		for k,v in csvPairs(cardcfg.skillList) do
			local passive = 1 -- 被动技能标记，默认1，为被动技能时改为2
			if csv.skill[v].skillType2 == battle.MainSkillType.PassiveSkill then
				passive = 2
			end
			table.insert(skillDatas,{
				skillId = v,
				skillLevel = 1, -- 图鉴里面技能等级显示为1级，和卡牌无关
				skillPassive = passive,
			})
		end

		table.sort(skillDatas,function (a,b)
			if a.skillPassive ~= b.skillPassive then
				return a.skillPassive < b.skillPassive
			end
			return a.skillId < b.skillId
		end)

		self.skillDatas:set(skillDatas)
		local unitcfg = csv.unit[cardcfg.unitID]
		local natureAttr = {}
		table.insert(natureAttr, unitcfg["natureType"])
		if unitcfg["natureType2"] then
			table.insert(natureAttr, unitcfg["natureType2"])
		end
	end)
end

function HandbookSkillView:onShowSkillInfo(node, skillInfo)
	local view = gGameUI:stackUI("common.skill_detail", nil, {clickClose = true, dispatchNodes = self.list}, {
		skillId = skillInfo.skillId,
		skillLevel = skillInfo.skillLevel,
		cardId = self.cardIdIdler:read(),
		star = uiEasy.getMaxStar(self.cardIdIdler:read())
	}, "handbook")
	local panel = view:getResourceNode()
	local x, y = panel:xy()
	panel:x(x - 165)
end

return HandbookSkillView