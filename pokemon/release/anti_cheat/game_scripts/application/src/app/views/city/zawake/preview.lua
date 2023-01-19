-- @date:   2021-04-21
-- @desc:   z觉醒预览界面

local SKILL_TYPE_HASH = itertools.map(battle.MainSkillType, function(k, v) return v, k end)

local zawakeTools = require "app.views.city.zawake.tools"
local ViewBase = cc.load("mvc").ViewBase
local ZawakePreviewView = class("ZawakePreviewView", Dialog)

local STAGE_POSX = {0, 0, 0, 0, 0, 0, 0, -35}
local STAGE_POSY = {15, 15, 5, 15, 10, 30, 10, 10}
local STAGE_SCALE = {0.6, 0.5, 0.6, 0.7, 0.6, 0.7, 0.6, 0.5}

local function updateSpine(parent, stageID, level)
	local spineName = string.format("zawake/jiqi_%s.skel", stageID)
	local effectName = "effect_posun_loop"
	if level > 0 then
		effectName = "effect_xiufu_loop"..level
	end
	local effect = widget.addAnimationByKey(parent, spineName, "effect", effectName, 5)
	effect:scale(STAGE_SCALE[stageID])
	effect:play(effectName)
	effect:xy(parent:width()/2 + STAGE_POSX[stageID], STAGE_POSY[stageID])
	if stageID == 4 then
		local houEffect = widget.addAnimationByKey(parent, spineName, "houEffect", "effect_hou_loop", 2)
		houEffect:scale(STAGE_SCALE[stageID])
		houEffect:play("effect_hou_loop")
		houEffect:xy(parent:width()/2 + STAGE_POSX[stageID], STAGE_POSY[stageID])
	elseif stageID == 7 then
		local houEffect = widget.addAnimationByKey(parent, "zawake/jiqi_7_hou.skel", "houEffect", effectName, 2)
		houEffect:scale(STAGE_SCALE[stageID])
		houEffect:play(effectName)
		houEffect:xy(parent:width()/2 + STAGE_POSX[stageID], STAGE_POSY[stageID])
	end
end

ZawakePreviewView.RESOURCE_FILENAME = "zawake_preview.json"
ZawakePreviewView.RESOURCE_BINDING = {
	["bgPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				backupCached = false,
				onBeforeBuild = function(list)
					list:setRenderHint(0)
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg1", "name", "fullAwake", "ruleBtn", "attrPanel", "skillPanel", "emptyPanel", "icon")
					childs.name:text(string.format("%s%s- %s", gLanguageCsv.effortAdvance, gLanguageCsv['symbolRome'..v.stageID], v.cfg.level))
					childs.name:setFontSize(40)
					local isZawake = v.level >= v.cfg.level
					local color = isZawake and ui.COLORS.NORMAL.ALERT_ORANGE or ui.COLORS.NORMAL.DEFAULT
					text.addEffect(childs.name, {color = color})

					itertools.invoke({childs.bg1, childs.fullAwake, childs.attrPanel, childs.skillPanel, childs.emptyPanel, childs.ruleBtn}, "hide")
					if v.isOpen == zawakeTools.STAGE_OPEN_STATE.open then
						updateSpine(childs.icon, v.stageID, v.level)
						if isZawake then
							itertools.invoke({childs.bg1, childs.fullAwake}, "show")
						end
						if not itertools.isempty(v.labelDatas) then
							childs.ruleBtn:show()
							local rect = list:box()
							local listPos = list:parent():convertToWorldSpace(cc.p(rect.x, rect.y))
							local pos = {x = listPos.x + childs.ruleBtn:x() - childs.ruleBtn:width()/2}
							bind.touch(list, childs.ruleBtn, {methods = {ended = functools.partial(list.clickUnlock, k, v, pos)}})
						end
					else
						local img = ccui.ImageView:create(string.format("city/zawake/img_jq%d.png", v.stageID))
						img:anchorPoint(0.5, 0)
						img:xy(childs.icon:width()/2 + STAGE_POSX[v.stageID], STAGE_POSY[v.stageID])
						img:scale(STAGE_SCALE[v.stageID])
						img:addTo(childs.icon, 5, "img")
						cache.setColor2Shader(img, false, cc.vec4(0.75, 0.75, 0.75, 1))
						if v.isOpen == zawakeTools.STAGE_OPEN_STATE.close then
							childs.emptyPanel:show()
						end
					end
					if v.isOpen ~= zawakeTools.STAGE_OPEN_STATE.close then
						local function addNoActiveTip(node, name, func)
							node:removeChildByName("noActiveTip")
							local tip
							local fontSize = 30
							local color = ui.COLORS.NORMAL.RED
							if v.isOpen ~= zawakeTools.STAGE_OPEN_STATE.open then
								tip = gLanguageCsv.zawakeNotOpen
								fontSize = 40
								color = ui.COLORS.NORMAL.ALERT_ORANGE
							else
								if not v.active then
									tip = gLanguageCsv.zawakeNoActiveTip
								end
							end
							if tip then
								if func then
									func()
								end
								local noActiveTip = label.create(tip, {
									color = color,
									fontPath = "font/youmi1.ttf",
									fontSize = fontSize,
								})
								local box = name:box()
								noActiveTip:addTo(node, 10, "noActiveTip")
									:anchorPoint(0, 0)
									:xy(box.x + box.width, box.y)
								return true
							end
							return false
						end
						if v.skillID > 0 then
							childs.skillPanel:show()
							local skillChilds = childs.skillPanel:multiget("title", "list", "skill", "skillText", "name", "iconUp")
							local skillCsv = v.skillCfg.cfg
							uiEasy.setSkillInfoToItems({
								name = skillChilds.name,
								icon = skillChilds.skill,
								type1 = skillChilds.skillText,
							}, skillCsv)
							skillChilds.name:text(csv.skill[v.skillID].skillName .. skillChilds.name:text())
							adapt.setTextScaleWithWidth(skillChilds.name, nil, 600)

							adapt.oneLinePos(skillChilds.title, skillChilds.skill, cc.p(5, 0))
							adapt.oneLinePos(skillChilds.skill, skillChilds.skillText, cc.p(60, 0))
							adapt.oneLinePos(skillChilds.skillText, skillChilds.name, cc.p(20, 0))
							skillChilds.iconUp:x(skillChilds.skill:x() + 60)

							local isStarEffrct = skillCsv.zawakeEffect[2] == 1
							local desc = isStarEffrct and skillCsv.describe or skillCsv.zawakeEffectDesc
							local starStr = uiEasy.getStarSkillDesc({skillId = v.skillCfg.id, cardId = v.skillCfg.cardId, star = 12, isZawake = true})
							local str = eval.doMixedFormula(desc, {skillLevel = 1,math = math},nil) .. starStr

							if skillCsv.zawakeSimpleDesc and skillCsv.zawakeSimpleDesc ~= "" then
								local skillType2 = SKILL_TYPE_HASH[skillCsv.skillType2]
								local simpleTitle1 = ""
								if skillType2 then
									simpleTitle1 = gLanguageCsv["zawake" .. skillType2]
								end
								local simpleTitle2 = skillCsv.zawakeSimpleType == 1 and gLanguageCsv.zawakeSimpleType1 or gLanguageCsv.zawakeSimpleType2
								local simpleColor = skillCsv.zawakeSimpleType == 1 and "#C0x5c9970#" or "#C0x5B545B#"
								str = string.format("#C0xE69900#[%s%s%s]:\n#F20# \n#F40#\t%s%s", simpleTitle1, isStarEffrct and gLanguageCsv.star or "", simpleTitle2, simpleColor, skillCsv.zawakeSimpleDesc)
							end
							beauty.textScroll({
								list = skillChilds.list,
								strs = "#C0x5B545B#" .. str,
								isRich = true,
								fontSize = 40,
							})
							-- skillChilds.list:setItemAlignCenter()
							addNoActiveTip(childs.skillPanel, skillChilds.name, function()
								adapt.setTextScaleWithWidth(skillChilds.name, nil, 400)
							end)

						else
							childs.attrPanel:show()
							local list = childs.attrPanel:get("list")
							local title = childs.attrPanel:get("title")
							local str = ""
							if v.cfg.extraScene[1] == 0 then
								title:text(gLanguageCsv.zawakeExtraAttr)

							else
								title:text(gLanguageCsv.zawakeExtraScene)
								local t = {}
								for _, id in ipairs(v.cfg.extraScene) do
									table.insert(t, gLanguageCsv[game.SCENE_TYPE_STRING_TABLE[id]])
								end
								str = table.concat(t, gLanguageCsv.symbolComma) .. "\n"
							end
							local t = {}
							for k, v in csvMapPairs(v.cfg.extraAttrs) do
								table.insert(t, getLanguageAttr(k) .. "+" .. dataEasy.getAttrValueString(k, v))
							end
							str = "#C0xF76B45#" .. str .. table.concat(t, "  ")
							beauty.textScroll({
								list = list,
								strs = str,
								isRich = true,
								fontSize = 40,
							})

							addNoActiveTip(childs.attrPanel, title)
						end
					end
				end,
			},
			handlers = {
				clickUnlock = bindHelper.self("onUnlockInfoClick"),
			}
		}
	}
}

function ZawakePreviewView:onCreate(zawakeID)
	Dialog.onCreate(self)
	self.zawakeID = zawakeID
	self:initModel()
	local zawake = self.zawake or {}
	local stage = zawake[zawakeID] or {}
	local data = {}
	for stageID=1, zawakeTools.MAXSTAGE do
		for lv = 1, zawakeTools.MAXLEVEL do
			local cfg = zawakeTools.getLevelCfg(zawakeID, stageID, lv)
			if cfg then
				if csvSize(cfg.extraAttrs) > 0 or cfg.skillID > 0 then
					local stagesCfg = zawakeTools.getStagesCfg(zawakeID, stageID)
					local level = stage[stageID] or 0
					local active, labelDatas = zawakeTools.getActiveCondition(zawakeID, stageID, cfg)
					if cfg.skillID > 0 then
						local skillCfgs = zawakeTools.getSkillCfg(zawakeID, cfg.skillID)
						if skillCfgs then
							for _, skillCfg in ipairs(skillCfgs) do
								table.insert(data, {cfg = cfg, stageID = stageID, level = level, skillID = cfg.skillID, skillCfg = skillCfg, isOpen = stagesCfg.isOpen, showUnlockBtn = showUnlockBtn, active = active, labelDatas = labelDatas})
							end
						end
					else
						table.insert(data, {cfg = cfg, stageID = stageID, level = level, skillID = cfg.skillID, skillCfg = nil, isOpen = stagesCfg.isOpen, showUnlockBtn = showUnlockBtn, active = active, labelDatas = labelDatas})
					end
				end
			end
		end
	end
	self.listDatas:update(data)
end

function ZawakePreviewView:initModel()
	self.zawake = gGameModel.role:read("zawake")
	self.listDatas = idlers.newWithMap({})
end

function ZawakePreviewView:onUnlockInfoClick(list, k, v, pos)
	if itertools.isempty(v.labelDatas) then
		return
	end
	local align = "left"
	gGameUI:stackUI("city.zawake.unlock_tips", nil, nil, {title = gLanguageCsv.zawakeStageLevelAwake, labelDatas = v.labelDatas, align = align, pos = pos, stageID = v.stageID})
end

return ZawakePreviewView

