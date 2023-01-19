-- @date:   2021-04-20
-- @desc:   z觉醒培养界面

local zawakeTools = require "app.views.city.zawake.tools"

local ViewBase = cc.load("mvc").ViewBase
local ZawakeStageView = class("ZawakeStageView", ViewBase)
ZawakeStageView.RESOURCE_FILENAME = "zawake_stage.json"
ZawakeStageView.RESOURCE_BINDING = {
	["leftPanel"] = "leftPanel",
	["rightPanel"] = "rightPanel",
	["rightPanel.infoPanel"] = "infoPanel",
	["rightPanel.effectItem"] = "effectItem",
	["rightPanel.effectInnerList"] = "effectInnerList",
	["rightPanel.effectPanel"] = "effectPanel",
	["rightPanel.skillPanel"] = "skillPanel",
	["rightPanel.activateItem"] = "activateItem",
	["rightPanel.activatePanel"] = "activatePanel",
	["rightPanel.costItem"] = "costItem",
	["rightPanel.costPanel"] = "costPanel",
	["rightPanel.infoPanel.list"] = "list",
	["rightPanel.infoPanel.titlePanel"] = "titlePanel",
	["rightPanel.infoPanel.downPanel"] = "downPanel",
	["rightPanel.infoPanel.bg"] = "bg",
	["rightPanel.infoPanel.downPanel.awakeImg"] = "awakeImg",
	["rightPanel.infoPanel.downPanel.txt"] = "awakeTxt",
	["rightPanel.infoPanel.downPanel.awakeBtn"] = {
		varname = "awakeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAwakeClick")}
		}
	}
}

function ZawakeStageView:onCreate(params)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.zawakeDevelop, subTitle = "AWAKENING TRAINING"})
	self:initModel()

	self.zawakeID = params.zawakeID
	self.stageID = params.stage
	self.levelCfg = {}
	for k=1, zawakeTools.MAXSTAGE do
		local panel = self.leftPanel:get("stage"..k)
		if self.stageID == k then
			panel:show()
			self.stagePanel = panel
			for lv=1, zawakeTools.MAXLEVEL do
				local item = panel:get("level"..lv):get("item")
				item:get("select"):hide()
				item:get("icon"):texture(string.format("city/zawake/machine/icon_0%s_machine%s.png", lv, k))
				item:get("icon"):scale(1.6)

				local num = label.create(lv, {
					color = ui.COLORS.NORMAL.WHITE,
					fontSize = 38,
					fontPath = "font/youmi1.ttf",
					effect = {outline = {color=ui.COLORS.NORMAL.DEFAULT, size = 3}},
				})
				num:addTo(item, 15, "num")
					:xy(item:width()/2, 30)
				bind.click(self, item, {method = function()
					self:onSelectClick(lv)
				end})
				self.levelCfg[lv] = zawakeTools.getLevelCfg(self.zawakeID, self.stageID, lv)
			end
		else
			panel:hide()
		end
	end
	self.list:setScrollBarEnabled(false)

	idlereasy.when(self.zawake, function(_, zawake)
		zawake = zawake or {}
		local stage = zawake[self.zawakeID] or {}
		-- 判断阶段解锁条件
		local level = stage[self.stageID] or 0
		self.level = level
		self:updateSpine(self.stagePanel:get("pos"), level)
		for k=1, zawakeTools.MAXLEVEL do
			self:updateLevelPanel(k)
		end
		if self.selectLevel:read() == 0 then
			self:onSelectClick(zawakeTools.MAXLEVEL)
		end
	end)

	self.selectLevel:addListener(function(val, oldval)
		-- print(val, oldval)
		if oldval > 0 then
			self.stagePanel:get("level"..oldval):get("item.select"):hide()
		end
		if val > 0 then
			self.stagePanel:get("level"..val):get("item.select"):show()
		end
	end)
end

function ZawakeStageView:updateLevelPanel(k)
	local level = self.level
	local levelPanel = self.stagePanel:get("level"..k)
	levelPanel:get("line1"):visible(k<=level)
	local item = levelPanel:get("item")
	local nextDi1 = item:get("nextDi1")
	item:get("nextDi"):visible(k<=level)
	item:get("mask"):visible(k>level)
	nextDi1:stopAllActions()
	local awakenable = item:get("awakenable")
	awakenable:hide()
	awakenable:removeChildByName("effect")
	if k == level+1 then
		if self.selectLevel:read() == 0 then
			self:onSelectClick(k)
		end
		nextDi1:show()
		local sequence = transition.sequence({
			cc.FadeTo:create(1, 50),
			cc.FadeTo:create(1, 255),
		})
		local action = cc.RepeatForever:create(sequence)
		nextDi1:runAction(action)
		-- 判断下一等级是否满足可觉醒条件
		if zawakeTools.canAwake(self.zawakeID, self.stageID, k) then
			awakenable:show()
			self:createAwakenabelSpine(awakenable)
		end
	else
		nextDi1:hide()
	end
end

function ZawakeStageView:initModel()
	self.zawake = gGameModel.role:getIdler("zawake")
	self.items = gGameModel.role:getIdler("items")
	self.frags = gGameModel.role:getIdler("frags")
	self.zfrags = gGameModel.role:getIdler("zfrags")
	self.listHeight = idler.new(0)
	self.selectLevel = idler.new(0)
	self.level = 0
end

function ZawakeStageView:onUpdateLevelInfo(level)
	local zawake = self.zawake:read() or {}
	local stage = zawake[self.zawakeID] or {}
	self.infoPanel:get("titlePanel.txt"):text(gLanguageCsv['symbolRome'..self.stageID])
	self.infoPanel:get("titlePanel.txtLevel"):text(string.format("- %s", level))
	adapt.oneLinePos(self.infoPanel:get("titlePanel.txt"), self.infoPanel:get("titlePanel.txtLevel"), cc.p(-7, 0))

	-- 1、已觉醒，2、可觉醒，3、不可觉醒条件
	local str
	-- 连续升级
	if self.stageID ~= 1 or level ~= 1 then
		local tmpStageID = self.stageID
		local tmpLevel = level - 1
		if tmpLevel == 0 then
			tmpStageID = tmpStageID - 1
			tmpLevel = zawakeTools.MAXLEVEL
		end
		local stageLevel = stage[tmpStageID] or 0
		if stageLevel < tmpLevel then
			str = string.format("%s- %s", gLanguageCsv['symbolRome'..tmpStageID], tmpLevel)
		end
	end
	itertools.invoke({self.awakeImg, self.awakeBtn, self.awakeTxt}, "hide")
	if str then
		self.awakeTxt:show():text(string.format(gLanguageCsv.zawakeLevelCondition, str))
	else
		local stageLevel = stage[self.stageID] or 0
		if level <= stageLevel then
			self.awakeImg:show()
		else
			self.awakeBtn:show()
		end
	end
	self.list:removeAllItems()
	self:updateListHeight(0, true)
	self:updateEffectPanel(level)
	self:updateSkillAttrPanel(level)
	self:updateActivatePanel(level)
	self:updateCostPanel(level)
	self:adaptBgPanel()
end

function ZawakeStageView:updateListHeight(height, cover)
	if cover then
		self.listHeight:set(height, true)
	else
		self.listHeight:modify(function(val)
			return true, val + height
		end)
	end
end

function ZawakeStageView:adaptBgPanel()
	local h = self.listHeight:read()
	local extraHeight = self.downPanel:height() + self.titlePanel:height() + 20
	local panelHeight = math.min(h + extraHeight, 1250)
	h = panelHeight - extraHeight
	self.list:height(h)
	self.bg:height(panelHeight)
	self.infoPanel:height(panelHeight)
	self.infoPanel:y(50 + (1250 - panelHeight)/2)
	self.titlePanel:y(1155 - (1250 - panelHeight))
end

function ZawakeStageView:updateEffectPanel(level)
	local effectPanel = self.effectPanel:clone():show()
	effectPanel:get("titlePanel.txt"):text(zawakeTools.getAttrAddTypeStr(self.levelCfg[level].attrAddType, self.levelCfg[level].natureType))

	local data = {}
	for k=1, math.huge do
		local attrType = self.levelCfg[level]["attrType"..k]
		local attrNum = self.levelCfg[level]["attrNum"..k]
		if attrType == nil or attrType == 0 then break end
		table.insert(data, {key = getLanguageAttr(attrType), val = "+"..dataEasy.getAttrValueString(attrType, attrNum)})
	end
	local h = math.ceil(#data/2)*self.effectInnerList:height()
	local list = effectPanel:get("list")
	local titlePanel = effectPanel:get("titlePanel")
	local titlePanelH = titlePanel:height()
	list:height(h)
	titlePanel:y(h + titlePanelH)
	effectPanel:height(h + titlePanelH + 20)
	bind.extend(self, effectPanel:get("list"), {
		class = "tableview",
		props = {
			data = data,
			item = bindHelper.self("effectInnerList"),
			cell = bindHelper.self("effectItem"),
			columnSize = 2,
			onCell = function(list, node, k, v)
				local keyText = node:get("keyText")
				keyText:text(v.key)
				local valText = node:get("valText")
				valText:text(v.val)
				adapt.oneLinePos(keyText, valText, cc.p(10, 0))
			end,
		},
	})
	self.list:pushBackCustomItem(effectPanel)
	self:updateListHeight(effectPanel:height())
end

function ZawakeStageView:updateSkillAttrPanel(level)
	local cfg = self.levelCfg[level]
	local skillCfgs = zawakeTools.getSkillCfg(self.zawakeID, cfg.skillID)
	if skillCfgs then
		for _, skillCfg in ipairs(skillCfgs) do
			local skillPanel = self.skillPanel:clone():show()
			self.list:pushBackCustomItem(skillPanel)
			local skillChilds = skillPanel:multiget("title", "skill", "skillText", "name", "iconUp", "infoBtn")
			uiEasy.setSkillInfoToItems({
				name = skillChilds.name,
				icon = skillChilds.skill,
				type1 = skillChilds.skillText,
			}, skillCfg.cfg)
			skillChilds.name:text(csv.skill[cfg.skillID].skillName .. skillChilds.name:text())
			adapt.setTextScaleWithWidth(skillChilds.name, nil, 230)

			adapt.oneLinePos(skillChilds.title, skillChilds.skill, cc.p(5, 0))
			adapt.oneLinePos(skillChilds.skill, skillChilds.skillText, cc.p(60, 0))
			adapt.oneLinePos(skillChilds.skillText, skillChilds.name, cc.p(20, 0))
			adapt.oneLinePos(skillChilds.name, skillChilds.infoBtn, cc.p(10, 0))
			skillChilds.iconUp:x(skillChilds.skill:x() + 60)
			self:updateListHeight(skillPanel:height())
			bind.touch(self, skillChilds.infoBtn, {methods = {ended = function()
				local view = gGameUI:stackUI("common.skill_detail", nil, {clickClose = true, dispatchNodes = list}, {
					skillId = skillCfg.id,
					skillLevel = 1,
					cardId = skillCfg.cardId,
					star = 12,
					isZawake = true,
				})
				local panel = view:getResourceNode()
				local x, y = panel:xy()
				panel:xy(x + 1020, y)
			end}})
		end
	end
	if csvSize(cfg.extraAttrs) > 0 then
		local effectPanel = self.effectPanel:clone():show()
		effectPanel:get("titlePanel.txt"):hide()
		local str = ""
		if cfg.extraScene[1] == 0 then
			effectPanel:get("titlePanel.title"):text(gLanguageCsv.zawakeExtraAttr)
		else
			effectPanel:get("titlePanel.title"):text(gLanguageCsv.zawakeExtraScene)
			local t = {}
			for _, id in ipairs(cfg.extraScene) do
				table.insert(t, gLanguageCsv[game.SCENE_TYPE_STRING_TABLE[id]])
			end
			str = table.concat(t, gLanguageCsv.symbolComma) .. "\n"
		end
		local t = {}
		for k, v in csvMapPairs(cfg.extraAttrs) do
			table.insert(t, getLanguageAttr(k) .. "+" .. dataEasy.getAttrValueString(k, v))
		end
		str = string.format("#C0xF76B45#\t%s\t%s", str, table.concat(t, "  "))
		local list = effectPanel:get("list")
		local titlePanel = effectPanel:get("titlePanel")
		local titlePanelH = titlePanel:height()
		local _, h = beauty.textScroll({
			list = list,
			strs = str,
			isRich = true,
			fontSize = 40,
		})
		list:setTouchEnabled(false)
		list:height(h)
		titlePanel:y(h + titlePanelH)
		effectPanel:height(h + titlePanelH + 20)
		self.list:pushBackCustomItem(effectPanel)
		self:updateListHeight(effectPanel:height())
	end
end

function ZawakeStageView:updateActivatePanel(level)
	local cfg = self.levelCfg[level]
	local _, labelDatas = zawakeTools.getActiveCondition(self.zawakeID, self.stageID, cfg)
	if itertools.isempty(labelDatas) then
		return
	end

	local titleText = gLanguageCsv.zawakeActivateAttrs
	if cfg.skillID > 0 then
		titleText = gLanguageCsv.zawakeActivateSkillID
	elseif cfg.extraScene[1] ~= 0 then
		titleText = gLanguageCsv.zawakeActivateScene
	end
	local activatePanel = self.activatePanel:clone():show()
	activatePanel:get("titlePanel.title"):text(titleText)
	local titlePanel = activatePanel:get("titlePanel")
	local titlePanelH = titlePanel:height()
	local listHeight = 0
	bind.extend(self, activatePanel:get("list"), {
		class = "listview",
		props = {
			data = labelDatas,
			item = bindHelper.self("activateItem"),
			onItem = function(list, node, k, v)
				local rich = rich.createWithWidth(v, 42, nil, 920)
					:anchorPoint(0, 0.5)
					:x(0)
					:addTo(node)
				local height = rich:height() + 8
				node:height(height)
				rich:y(node:height()/2)
				listHeight = listHeight + node:height()
			end,
			onAfterBuild = function(list)
				list:height(listHeight)
				titlePanel:y(listHeight + titlePanelH)
				activatePanel:height(listHeight + titlePanelH + 20)
				self:updateListHeight(activatePanel:height())
				self:adaptBgPanel()
			end,
		}
	})
	self.list:pushBackCustomItem(activatePanel)
end

function ZawakeStageView:updateCostPanel(level)
	if level <= self.level then return end
	local costPanel = self.costPanel:clone():show()
	self.list:pushBackCustomItem(costPanel)
	self:updateListHeight(costPanel:height())
	idlereasy.any({self.zfrags, self.items, self.frags}, function (obj, zfrags, items, frags)
		local data = {}
		for key, val in csvMapPairs(self.levelCfg[level].costItemMap) do
			table.insert(data, {key = key, needVal = val, val = dataEasy.getNumByKey(key), showBtn = dataEasy.isZawakeFragment(key)})
		end
		table.sort(data, function(a, b)
			if a.showBtn ~= b.showBtn then
				return a.showBtn
			end
			return dataEasy.sortItemCmp(a, b)
		end)
		bind.extend(self, costPanel:get("list"), {
			class = "listview",
			props = {
				data = data,
				item = bindHelper.self("costItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "addPanel", "exchangeBtn")
					local showAddBtn = (v.val < v.needVal)
					childs.addPanel:visible(showAddBtn)
					childs.exchangeBtn:visible(v.showBtn)
					bind.extend(list, childs.icon, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.val,
								targetNum = v.needVal,
							},
							noListener = true,
							grayState = showAddBtn and 1 or 0,
							onNode = function(panel)
								panel:setTouchEnabled(false)
							end,
						},
					})
					childs.icon:setTouchEnabled(true)
					bind.click(list, childs.icon, {method = function(view, node, event)
						gGameUI:stackUI("common.gain_way", nil, nil, v.key, nil, v.needVal)
					end})
					bind.touch(list, childs.exchangeBtn, {methods = {ended = function(view, node, event)
						gGameUI:stackUI("city.zawake.debris", nil, nil, {fragID = v.key, needNum = v.needVal})
					end}})
				end,
			}
		})
		-- 道具变动，刷新可觉醒位置状态
		self:updateLevelPanel(math.min(self.level+1, zawakeTools.MAXLEVEL))
	end):anonyOnly(self)
end

function ZawakeStageView:createAwakenabelSpine(parent)
	local size = parent:size()
	local effect = widget.addAnimationByKey(parent, "zawake/zujian.skel", "effect", "effect_loop", 2)
	effect:play("effect_loop")
	effect:xy(size.width/2, size.height/2)
end

function ZawakeStageView:updateSpine(parent, level)
	local stageScale = {2.35, 1.7, 2.2, 2.1, 2, 2, 2, 1.7}
	local stageY = {0, 100, 0, 100, 90, 110, 100, 0}
	local spineName = string.format("zawake/jiqi_%s.skel", self.stageID)
	local effectName = "effect_posun_loop"
	if level > 0 then
		effectName = "effect_xiufu_loop"..level
	end
	local effect = widget.addAnimationByKey(parent, spineName, "effect", effectName, 5)
	effect:scale(stageScale[self.stageID])
	effect:play(effectName)
	effect:xy(0, stageY[self.stageID])
	if self.stageID == 4 then
		local houEffect = widget.addAnimationByKey(parent, spineName, "houEffect", "effect_hou_loop", 2)
		houEffect:scale(stageScale[self.stageID])
		houEffect:play("effect_hou_loop")
		houEffect:xy(0, stageY[self.stageID])
	elseif self.stageID == 7 then
		local houEffect = widget.addAnimationByKey(parent, "zawake/jiqi_7_hou.skel", "houEffect", effectName, 2)
		houEffect:scale(stageScale[self.stageID])
		houEffect:play(effectName)
		houEffect:xy(0, stageY[self.stageID])
	end
end

function ZawakeStageView:onSelectClick(level)
	self.selectLevel:set(level)
	self:onUpdateLevelInfo(level)
end

function ZawakeStageView:onAwakeClick()
	if not zawakeTools.canAwake(self.zawakeID, self.stageID, self.selectLevel:read()) then
		gGameUI:showTip(gLanguageCsv.zawakeItemsLess)
		return
	end
	local level = self.level
	local nextLevel = math.min(level+1, zawakeTools.MAXLEVEL)
	local nextSelectLevel = math.min(level+2, zawakeTools.MAXLEVEL)
	gGameApp:requestServer("/game/card/zawake/strength", function(tb)
		-- 觉醒成功界面
		local params = {
			zawakeID = self.zawakeID,
			level = level,
			stageID = self.stageID,
			cfg = self.levelCfg[nextLevel],
			cb = function ()
				self:onSelectClick(nextSelectLevel)
			end
		}
		gGameUI:stackUI("city.zawake.awake_success", nil, {blackLayer = true}, params)
	end, self.zawakeID, self.stageID, nextLevel)
end

return ZawakeStageView