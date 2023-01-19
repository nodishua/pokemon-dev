local PersonalSkillChooseView = class("PersonalSkillChooseView",Dialog)

local FIGURE_TYPE = {
	ALL = 1,		-- 	全局
	UNLOCKED = 2,	-- 已解锁
	CAN_UNLOCK = 3,	-- 可解锁
	NOT_UNLOCK = 4	-- 不能解锁
}

PersonalSkillChooseView.RESOURCE_FILENAME = "personal_skill_choose.json"
PersonalSkillChooseView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["skillPanel"] = "skillPanel",
	["btnSave.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["btnSave"] = {
		varname = "btnSave",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSaveClick")}
		},
	},
	["btnRemove.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["btnRemove"] = {
		varname = "btnRemove",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRemoveClick")}
		},
	},

	["subList"] = "skillSubList",
	["itemSkill"] = "skillItem",
	["leftList"] ={
		varname = "skillList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("skillDatas"),
				item = bindHelper.self("skillSubList"),
				cell = bindHelper.self("skillItem"),
				columnSize = 4,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local skillCsv = csv.skill[v.skillIdx]

					node:get("icon"):texture(skillCsv.iconRes)
					node:get("selected"):hide()
					node:get("used"):visible(v.inUse or v.isUse)
					node:get("locked"):visible(v.unlocked ~= FIGURE_TYPE.UNLOCKED)

					if v.isUse then
						node:get("used"):get("txt"):text(gLanguageCsv.haveUse)
					end
					node:get("selected"):visible(v.selectSign or false)

					bind.touch(list,node,{methods = {ended = functools.partial(list.clickCell,k,v)}})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onClickCell"),
			}
		}
	},
	["skillName"] = "skillName",
	["descList"] = "descList",
	["conditionList"] = "conditionList",
	["conditionRemove"] = "conditionRemove",
}

function PersonalSkillChooseView:onCreate(selectId, figureId, num)
	self.selectFigureId    = selectId     -- 当前所选形象ID
	self.num               = num          -- 当前点击技能栏号码

	self.selectSkill = idler.new(figureId)
	self.curfigureId = idler.new(figureId) -- 当前点击切换的技能的形象
	self.skillDatas  = idlers.new()

	self:initModel()

	-- 基本数据变动监听
	idlereasy.any({self.figures, self.figure, self.skillFigure, self.curfigureId},function(_, figures, figure, skillFigure,curfigureId)
		local skillDatas = {}
		local skillList = {}
		local figureSkills = skillFigure[selectId] or {selectId}

		for index, value in pairs(figureSkills) do
			skillList[value] = true
		end

		local sign = true
		local selectSkill = self.selectSkill:read()
		for k,v in csvPairs(gRoleFigureCsv) do

			if v.skills[1] and v.hide == 0 then

				local unlocked = figures[k] and FIGURE_TYPE.UNLOCKED or FIGURE_TYPE.NOT_UNLOCK
				local inUse  = k == curfigureId
				local isUse  = skillList[k] or false
				if inUse then
					isUse = false
				end

				if k == selectSkill then sign = false end

				table.insert(skillDatas, {id = k, unlocked = unlocked, inUse = inUse, isUse = isUse, showIdx = v.showIdx,skillIdx = v.skills[1]})
			end
		end
		table.sort(skillDatas, function(v1, v2)
				if v1.unlocked ~= v2.unlocked then
					return v1.unlocked < v2.unlocked
				end
				if v1.showIdx ~= v2.showIdx then
					return v1.showIdx > v2.showIdx
				end
				return v1.id < v2.id
			end)

		if sign then
			self.selectSkill:set(skillDatas[1].id)
		end
		self.skillDatas:update(skillDatas)
	end)

	-- 选中技能监听
	self.selectSkill:addListener(function(val, oldval)

		local value = nil
		for k, v in self.skillDatas:ipairs() do

			local info = v:proxy()
			if info.id == oldval then
				info.selectSign = false
			end

			if info.id == val then
				info.selectSign = true
				value = info
			end
		end

		self.skillDatas:notify()
		self:setSkillInfo(value)
	end)

	Dialog.onCreate(self)
end

-- 初始化model
function PersonalSkillChooseView:initModel()
	self.figure      = gGameModel.role:getIdler("figure")
	self.figures     = gGameModel.role:getIdler("figures")
	self.skillFigure = gGameModel.role:getIdler("skill_figures")
end

-- 设置技能信息
function PersonalSkillChooseView:setSkillInfo(value)
	local csvFigure  = gRoleFigureCsv[value.id]
	local cfg        = csv.skill[value.skillIdx]

	local figureName = csvFigure.name
	local content
	if value.unlocked == FIGURE_TYPE.UNLOCKED then
		content = string.format(gLanguageCsv.skillUseTip, figureName)
	else
		content = string.format(gLanguageCsv.skillActiveTip, figureName)
	end

	self.skillName:text(cfg.skillName)
	beauty.textScroll({
		list = self.descList,
		strs = "#C0x5B545B#" .. cfg.describe,
		isRich = true,
	})
	beauty.textScroll({
		list = self.conditionList,
		strs = "#C0x5B545B#" .. content,
		isRich = true,
		align = "center",
	})

	self.skillPanel:get("icon"):texture(cfg.iconRes)


	self.btnSave:visible((not value.isUse) and value.unlocked == FIGURE_TYPE.UNLOCKED )
	self.btnRemove:visible(value.inUse)
	self.conditionRemove:visible(false)
end

-- 添加或者替换
function PersonalSkillChooseView:onSaveClick()
	local selctSkill = self.selectSkill:read()

	gGameApp:requestServer("/game/role/figure/skill/switch",function(val)
		if val then
			self.curfigureId:set(selctSkill)
		end
		self:onClose()
	end, self.selectFigureId, selctSkill, self.num-1)
end

-- 移除
function PersonalSkillChooseView:onRemoveClick()
	gGameApp:requestServer("/game/role/figure/skill/switch",function(val)
		if val then
			self.curfigureId:set(-1)
		end
		self:onClose()
	end, self.selectFigureId, -1,self.num-1)
end

-- 技能选中
function PersonalSkillChooseView:onClickCell(list, k, v)
	self.selectSkill:set(v.id)
end

return PersonalSkillChooseView