local BASE_TIME = 0.08
-- @desc: 卡牌羁绊
local zawakeTools = require "app.views.city.zawake.tools"

local ViewBase = cc.load("mvc").ViewBase
local ZawakeAwakeSuccessView = class("ZawakeAwakeSuccessView", ViewBase)

ZawakeAwakeSuccessView.RESOURCE_FILENAME = "zawake_awake_success.json"
ZawakeAwakeSuccessView.RESOURCE_BINDING = {
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose"),
		},
	},
	["txt1"] = "txt1",
	["pos"] = "pos",
	["centerPos"] = "centerPos",
	["cardImg"] = "cardImg",
	["name1"] = "name1",
	["name2"] = "name2",
	["name11"] = "name11",
	["name21"] = "name21",
	["jiqi1"] = "jiqi1",
	["jiqi2"] = "jiqi2",
	["innerList"] = "innerList",
	["item"] = "item",
	["skillPanel"] = "skillPanel",
	["skillPanel.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.ALERT_ORANGE, size = 2}},
		}
	},
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("lableDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				columnSize = 3,
				onCell = function(list, node, k, v)
					node:get("keyText"):text(v.key)
					node:get("valText"):text(v.val)
					adapt.oneLinePos(node:get("keyText"), node:get("valText"))

					local idx = list:getIdx(k).k
					local baseDelay = BASE_TIME * (1 + idx)
					uiEasy.setExecuteSequence({node:get("keyText"), node:get("valText")}, {delayTime = baseDelay})
				end,
			},
		}
	}
}

function ZawakeAwakeSuccessView:onCreate(params)
	-- print_r(params)
	self.stageID = params.stageID
	local level = params.level
	self.cb = params.cb
	local cfg = params.cfg
	local zawakeID = params.zawakeID
	--title特效
	uiEasy.setTitleEffect(self.centerPos, "xjiesuan_juexingzi")

	local data = {}
	for k=1, math.huge do
		local attrType = cfg["attrType"..k]
		local attrNum = cfg["attrNum"..k]
		if attrType == nil or attrType == 0 then break end
		table.insert(data, {key = getLanguageAttr(attrType), val = "+"..dataEasy.getAttrValueString(attrType, attrNum)})
	end
	self.lableDatas = idlers.newWithMap(data)

	self:updateSpine(self.jiqi1, level)
	self:updateSpine(self.jiqi2, level+1)

	if level == 0 then
		self.name1:text(gLanguageCsv.noAwake)
		self.name11:hide()
	else
		self.name1:text(string.format(gLanguageCsv.zawakeStageLevel, gLanguageCsv['symbolRome'..self.stageID]))
		self.name11:show()
		self.name11:text("- " .. level)
		adapt.oneLinePos(self.name1, self.name11, cc.p(-4, 0))
	end
	self.name2:text(string.format(gLanguageCsv.zawakeStageLevel, gLanguageCsv['symbolRome'..self.stageID]))
	self.name21:text("- " .. level + 1)
	adapt.oneLinePos(self.name2, self.name21, cc.p(-4, 0))
	self.skillPanel:hide()
	local skillCfgs = zawakeTools.getSkillCfg(zawakeID, cfg.skillID)
	if skillCfgs then
		for i, skillCfg in ipairs(skillCfgs) do
			local skillPanel = self.skillPanel:clone()
			local skillChilds = skillPanel:multiget("skill", "skillText", "name", "iconUp")
			uiEasy.setSkillInfoToItems({
				name = skillChilds.name,
				icon = skillChilds.skill,
				type1 = skillChilds.skillText,
			}, skillCfg.cfg)
			skillChilds.name:text(csv.skill[cfg.skillID].skillName .. skillChilds.name:text())
			-- adapt.oneLinePos(skillChilds.title, skillChilds.skill, cc.p(5, 0))
			adapt.oneLinePos(skillChilds.skill, skillChilds.skillText, cc.p(60, 0))
			adapt.oneLinePos(skillChilds.skillText, skillChilds.name, cc.p(20, 0))
			skillChilds.iconUp:x(skillChilds.skill:x() + 60)
			uiEasy.setExecuteSequence(skillPanel, {delayTime = 10 * BASE_TIME})
			skillPanel:addTo(self.skillPanel:parent(), self.skillPanel:z())
				:xy(self.skillPanel:x(), self.skillPanel:y() - (i - 1) * self.skillPanel:height())
		end
	end

	--动画
	uiEasy.setExecuteSequence(self.cardImg)
	uiEasy.setExecuteSequence(self.jiqi2, {delayTime = BASE_TIME})
	uiEasy.setExecuteSequence(self.name2, {delayTime = BASE_TIME})
	uiEasy.setExecuteSequence(self.name21, {delayTime = BASE_TIME})
end


function ZawakeAwakeSuccessView:updateSpine(parent, level)
	local spineName = string.format("zawake/jiqi_%s.skel", self.stageID)
	local effectName = "effect_posun_loop"
	if level > 0 then
		effectName = "effect_xiufu_loop"..level
	end
	local effect = widget.addAnimationByKey(parent, spineName, "effect", effectName, 5)
	effect:scale(0.6)
	effect:play(effectName)
	effect:xy(parent:width()/2, 0)
	if self.stageID == 4 then
		local houEffect = widget.addAnimationByKey(parent, spineName, "houEffect", "effect_hou_loop", 2)
		houEffect:scale(0.6)
		houEffect:play("effect_hou_loop")
		houEffect:xy(parent:width()/2, 0)
	elseif self.stageID == 7 then
		local houEffect = widget.addAnimationByKey(parent, "zawake/jiqi_7_hou.skel", "houEffect", effectName, 2)
		houEffect:scale(0.6)
		houEffect:play(effectName)
		houEffect:xy(parent:width()/2, 0)
	end
end

function ZawakeAwakeSuccessView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return ZawakeAwakeSuccessView