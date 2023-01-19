-- @date:   2021-04-07
-- @desc:   z觉醒主界面

local zawakeTools = require "app.views.city.zawake.tools"
local BACKGROUNDWIDTH = 3120
-- 置顶按钮零界点
local SHOW_LEFT_POSX = -1000
-- npc移动速度
local MOVE_SPEED = 1300

local ViewBase = cc.load("mvc").ViewBase
local ZawakeView = class("ZawakeView", ViewBase)

ZawakeView.RESOURCE_FILENAME = "zawake.json"
ZawakeView.RESOURCE_BINDING = {
	["bgMap"] = "bgMap",
	["bgMap.mainPanel"] = "mainPanel",
	["bgMap.mainPanel.topPanel"] = "topPanel",
	["bgMap.mainPanel.cardIcon"] = {
		varname = "cardIcon",
		binds = {
			event = "click",
			method = bindHelper.self("onReplaceClick")
		}
	},
	["rightPanel.btnRule.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["rightPanel.btnPreview.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["rightPanel.btnReset.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["bgMap.npcPanel"] = {
		varname = "npcPanel",
		binds = {
			event = "click",
			method = bindHelper.self("onAwakeClick"),
		}
	},
	["rightPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")}
		}
	},
	["rightPanel.btnPreview"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPreviewClick")}
		}
	},
	["rightPanel.btnReset"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onResetClick")}
		}
	},
	["rightPanel.toLastStageBtn.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(236, 78, 87)}},
		}
	},
	["leftPanel.toLeftBtn.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(236, 78, 87)}},
		}
	},
	["rightPanel.toLastStageBtn"] = {
		varname = "toLastStageBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onJumpToLastStageClick")}
		}
	},
	["leftPanel.toLeftBtn"] = {
		varname = "toLeftBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onJumpToLeftClick")}
		}
	},
	["bgMap.mainPanel.btnReplace"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReplaceClick")}
		}
	},
	["bgMap.mainPanel.btnReplace.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
}

function ZawakeView:onCreate(params)
	local params = params or {}
	self.params = params
	-- 根据战力降序，再判断激活的
	local zawakeID = params.zawakeID or zawakeTools.getFightPointMaxCard()
	self.zawakeID = idler.new(zawakeID)
	self:initModel()
	self:initStagePanel()
	self:initBgMap()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.zawake, subTitle = "ZAWAKE"})

	self.zawakeID:addListener(function(zawakeID, oldval)
		local cardData = zawakeTools.getCardByZawakeID(zawakeID)
		local unitCsv = csv.unit[cardData.cfg.unitID]
		local childs = self.topPanel:multiget("icon", "name")
		childs.icon:texture(ui.RARITY_ICON[unitCsv.rarity])
		childs.name:text(cardData.cfg.name)
		self.cardIcon:removeAllChildren()
		local cardSprite = widget.addAnimation(self.cardIcon, unitCsv.unitRes, "standby_loop", 5)
			:xy(self.cardIcon:width()/2, 0)
			:scale(unitCsv.scaleU*2.3)
			:setSkin(unitCsv.skin)
		self:updateAllStage()
		if zawakeID ~= oldval then
			self:updateMainSpine(true)
		end
	end)

	idlereasy.when(self.zawake, function (_, zawake)
		-- print_r(zawake)
		zawake = zawake or {}
		self:updateAllStage(zawake)
	end)
	self.showStageID:addListener(function(val, oldval)
		self.npcPanel:stopAllActions()
		local startPosX = self.npcPanel:x()
		local posY = self.npcPanel:y()
		local endPosX = self.stagPanels[val]:x() + 20
		local len = math.abs(startPosX - endPosX)
		local time = len/MOVE_SPEED
		local maxLen = BACKGROUNDWIDTH - 500
		local speedScale = len > maxLen and 2 or 1
		time = len > maxLen and time/2 or time
		local action = transition.sequence({
			cc.MoveTo:create(time, cc.p(endPosX, posY)),
			cc.CallFunc:create(function()
				self:updateNpcSpine("standby_loop")
			end)
		})
		self:updateNpcSpine("run_loop", val < oldval, speedScale)
		self.npcPanel:runAction(action)
	end)
end

function ZawakeView:initModel()
	self.zawake = gGameModel.role:getIdler("zawake")
	self.showStageID = idler.new(1)
	self.npcIsMove = false
	self.npcWidth = self.npcPanel:width()
end

function ZawakeView:initBgMap()
	self.bgMap:setScrollBarEnabled(false)
	self.bgMap:width(display.sizeInViewRect.width)
	local container = self.bgMap:getInnerContainer()
	self.bgMap:onScroll(function(event)
		if event.name == "CONTAINER_MOVED" then
			self.toLastStageBtn:visible(container:x() > SHOW_LEFT_POSX)
			self.toLeftBtn:visible(container:x() <= SHOW_LEFT_POSX)
			self:setShowStageID(container:x())
		end
	end)
	self:onJumpToLeftClick()
	self:updateLianjieSpine(self.bgMap)
	self:updateMainSpine()
end

function ZawakeView:initStagePanel()
	self.stagPanels = {}
	self.stagPanelsPosX = {}
	for k=1, zawakeTools.MAXSTAGE do
		local panel = self.bgMap:get("stagePanel"..k)
		table.insert(self.stagPanels, panel)
		table.insert(self.stagPanelsPosX, panel:x())
		local infoPanel = panel:get("infoPanel")
		text.addEffect(infoPanel:get("textStage"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
		text.addEffect(infoPanel:get("textLevel0"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
		text.addEffect(infoPanel:get("textLevel1"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
		text.addEffect(infoPanel:get("textLevel2"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
		local closePanel = panel:get("closePanel")
		text.addEffect(closePanel:get("txt"), {outline = {color = cc.c4b(71, 66, 71, 255)}})
		closePanel:get("bg"):width(closePanel:get("txt"):width() + 50)
		bind.click(self, panel:get("spineNode"), {method = function()
			self:onStageClick(k)
        end})
	end
end

function ZawakeView:updateMainSpine(isExchange)
	local effectName = isExchange and "qiehuan" or "standby_loop"
	local posY = 65
	local effectBottom = widget.addAnimationByKey(self.mainPanel, "zawake/jixiebi.skel", "effectBottom", effectName.."_hou", 5)
	effectBottom:scale(2)
	effectBottom:xy(self.mainPanel:width()/2, posY)
	effectBottom:play(effectName.."_hou")

	local effectTop = widget.addAnimationByKey(self.mainPanel, "zawake/jixiebi.skel", "effectTop", effectName.."_qian", 15)
	effectTop:scale(2)
	effectTop:xy(self.mainPanel:width()/2, posY)
	effectTop:play(effectName.."_qian")
	if isExchange then
		self.cardIcon:hide()
		performWithDelay(self.cardIcon, function()
			self.cardIcon:show()
		end, 0.75)
		effectBottom:setTimeScale(2)
		effectBottom:setSpriteEventHandler(function(event, eventArgs)
			effectBottom:play("standby_loop_hou")
			effectBottom:setTimeScale(1)
		end, sp.EventType.ANIMATION_COMPLETE)
		effectTop:setTimeScale(2)
		effectTop:setSpriteEventHandler(function(event, eventArgs)
			effectTop:play("standby_loop_qian")
			effectTop:setTimeScale(1)
		end, sp.EventType.ANIMATION_COMPLETE)
	end
end

function ZawakeView:setShowStageID(containerX)
	if self.npcIsMove then return end
	self.npcIsMove = true
	containerX = math.abs(containerX)
	local nowPosX = self.stagPanelsPosX[self.showStageID:read()]
	if nowPosX < containerX or nowPosX > containerX + display.sizeInViewRect.width - self.npcWidth then
		local stageID = 1
		for k=1, zawakeTools.MAXSTAGE do
			if containerX < self.stagPanelsPosX[k] then
				stageID = k
				break
			end
		end
		if stageID ~= self.showStageID:read() then
			self.showStageID:set(stageID)
		end
	end
	self.npcIsMove = false
end

function ZawakeView:updateAllStage(zawake)
	zawake = zawake or self.zawake:read() or {}
	local stage = zawake[self.zawakeID:read()] or {}
	for stageID = 1, zawakeTools.MAXSTAGE do
		self:updateStagePanel(stageID, stage[stageID] or 0)
		local infoPanel = self.stagPanels[stageID]:get("infoPanel")
        bind.extend(self, infoPanel, {
			class = "red_hint",
			props = {
				listenData = {
					stageID = stageID,
					zawakeID = self.zawakeID:read()
				},
				specialTag = "canZawakeByStage",
				onNode = function(panel)
					panel:xy(340, 110)
				end,
			},
		})
	end
end

function ZawakeView:updateNpcSpine(effectName, isFlip, speedScale)
	local speedScale = speedScale or 1
	local effect = widget.addAnimationByKey(self.npcPanel, "zawake/meilutan.skel", "effect", effectName, 2)
	effect:scaleX(isFlip and -2 or 2)
	effect:setTimeScale(speedScale)
	effect:scaleY(2)
	effect:play(effectName)
	effect:xy(self.npcWidth/2, 0)
end

function ZawakeView:updateStageSpine(parent, stageID)
	parent:removeChildByName("img")
	local zawake = self.zawake:read() or {}
	local stage = zawake[self.zawakeID:read()] or {}
	local level = stage[stageID] or 0
	local spineName = string.format("zawake/jiqi_%s.skel", stageID)
	local effectName = "effect_posun_loop"
	if level > 0 then
		effectName = "effect_xiufu_loop"..level
	end
	local effect = widget.addAnimationByKey(parent, spineName, "effect", effectName, 5)
	effect:scale(2)
	effect:play(effectName)
	effect:xy(parent:width()/2, 0)
	if stageID == 4 then
		local houEffect = widget.addAnimationByKey(parent, spineName, "houEffect", "effect_hou_loop", 2)
		houEffect:scale(2)
		houEffect:play("effect_hou_loop")
		houEffect:xy(parent:width()/2, 0)
	elseif stageID == 7 then
		local houEffect = widget.addAnimationByKey(parent, "zawake/jiqi_7_hou.skel", "houEffect", effectName, 2)
		houEffect:scale(2)
		houEffect:play(effectName)
		houEffect:xy(parent:width()/2, 0)
	end
end

function ZawakeView:updateLianjieSpine(parent, stageID)
	-- 层级关系，部分spine需要加到相邻机器底下
	if stageID == 4 then
		self:updateLianjieSpine(parent, 3)
	elseif stageID == 6 then
		self:updateLianjieSpine(parent, 5)
	end
	local pos = {{500, 215}, {733, 23}, {-480, 37}, {647, 141}, {-530, 177}, {420, 95}, {488, 112}, {370, 169}}
	local effectName = "effect_boliguandao_kaiqi_loop"
	if stageID then
		local zawake = self.zawake:read() or {}
		local stage = zawake[self.zawakeID:read()] or {}
		local level = stage[stageID] or 0
		effectName = string.format("effect_chuansongdai_%d_guanbi_loop", stageID)
		if level == zawakeTools.MAXLEVEL then
			effectName = string.format("effect_chuansongdai_%d_kaiqi_loop", stageID)
		end
	end
	local effect = widget.addAnimationByKey(parent, "zawake/lianjie_1.skel", "chuansongdai"..(stageID or 0), effectName, 3)
	effect:scale(2)
	effect:play(effectName)
	if stageID then
		effect:xy(pos[stageID][1], pos[stageID][2])
	else
		effect:xy(1260, 405)
	end
end

function ZawakeView:onJumpToLeftClick()
	local percent = math.max((BACKGROUNDWIDTH - display.sizeInViewRect.width)/2, 0) / (self.bgMap:getInnerContainerSize().width - display.sizeInViewRect.width) * 100
	self.bgMap:scrollToPercentHorizontal(percent, 0.5, true)
	self.toLastStageBtn:show()
	self.toLeftBtn:hide()
end

function ZawakeView:onJumpToLastStageClick()
	local zawake = self.zawake:read() or {}
	local stages = zawake[self.zawakeID:read()] or {}
	local datas = {}
	for stage, level in pairs(stages) do
		table.insert(datas, {stage = stage, level = level})
	end
	table.sort(datas, function(a, b)
		return a.stage > b.stage
	end)
	local lastStage = 1
	if #datas > 0 then
		lastStage = datas[1].stage
	end
	self:moveToByStage(lastStage)
end

function ZawakeView:onStageClick(stage)
	local stageCfg, zawakeData = zawakeTools.getStagesCfg(self.zawakeID:read(), stage)

	if stageCfg.isOpen ~= zawakeTools.STAGE_OPEN_STATE.open then
		gGameUI:showTip(gLanguageCsv.comingSoon)
		return
	end
	local isUnlock, labelDatas = zawakeTools.isUnlockByStage(stageCfg, self.zawakeID:read())
	if isUnlock then
		gGameUI:stackUI("city.zawake.stage", nil, {backGlass = true}, {stage = stage, zawakeID = self.zawakeID:read()})
		return
	end
	gGameUI:stackUI("city.zawake.unlock_tips", nil, nil, {labelDatas = labelDatas, stageID = stage})
end

function ZawakeView:moveToByStage(stage, isJump)
	local panel = self.stagPanels[stage]
	local bgMapWidth = self.bgMap:getInnerContainerSize().width
	local percent = math.max(panel:x() + panel:width()/2 - display.sizeInViewRect.width/2, 0) / (bgMapWidth - display.sizeInViewRect.width)* 100
	if isJump then
		self.bgMap:jumpToPercentHorizontal(percent)
	else
		self.bgMap:scrollToPercentHorizontal(percent, 0.5, true)
	end
end

function ZawakeView:updateStagePanel(stageID, level)
	local panel = self.stagPanels[stageID]
	local infoPanel = panel:get("infoPanel")
	if level == zawakeTools.MAXLEVEL then
		text.addEffect(infoPanel:get("textLevel1"), {color = ui.COLORS.NORMAL.WHITE})
	else
		text.addEffect(infoPanel:get("textLevel1"), {color = ui.COLORS.NORMAL.RED})
	end
	infoPanel:get("textLevel1"):text(level)
	infoPanel:get("textStage"):text(string.format("%s%s", gLanguageCsv.effortAdvance, gLanguageCsv['symbolRome'..stageID]))
	adapt.oneLineCenterPos(cc.p(infoPanel:width()/2, infoPanel:height()/2), {infoPanel:get("textStage"), infoPanel:get("textLevel0"), infoPanel:get("textLevel1"), infoPanel:get("textLevel2")}, cc.p(3, 0))
	infoPanel:get("bg"):width(infoPanel:get("textStage"):width() + infoPanel:get("textLevel0"):width() + infoPanel:get("textLevel1"):width() + infoPanel:get("textLevel2"):width() + 70)
	if zawakeTools.isOpenByStage(self.zawakeID:read(), stageID) then
		self:updateStageSpine(panel:get("spineNode"), stageID)
		infoPanel:show()
	else
		infoPanel:hide()
	end
	local lockPanel = panel:get("lockPanel")
	local cfg, zawakeData = zawakeTools.getStagesCfg(self.zawakeID:read(), stageID)
	self.stagPanels[stageID].isOpen = cfg.isOpen
	panel:get("closePanel"):visible(cfg.isOpen ~= zawakeTools.STAGE_OPEN_STATE.open)
	lockPanel:hide()
	if cfg.isOpen == zawakeTools.STAGE_OPEN_STATE.open then
		local isUnlock, labelDatas = zawakeTools.isUnlockByStage(cfg, self.zawakeID:read())
		self.stagPanels[stageID].isUnlock = isUnlock
		self.stagPanels[stageID].labelDatas = labelDatas
		lockPanel:visible(not isUnlock)
	end
	if stageID == 3 or stageID == 5 then return end
	self:updateLianjieSpine(panel:get("spineNode"), stageID)
end

function ZawakeView:onAwakeClick()
	gGameUI:stackUI("city.zawake.force")
end

-- 预览
function ZawakeView:onPreviewClick()
	local zawakeID = self.zawakeID:read()
	local zawake = gGameModel.role:read("zawake") or {}
	local stage = zawake[zawakeID] or {}
	local data = {}
	for stageID=1, zawakeTools.MAXSTAGE do
		for lv = 1, zawakeTools.MAXLEVEL do
			local cfg = zawakeTools.getLevelCfg(zawakeID, stageID, lv)
			if cfg and cfg.skillID > 0 then
				local skillCfgs = zawakeTools.getSkillCfg(zawakeID, cfg.skillID)
				if skillCfgs then
					gGameUI:stackUI("city.zawake.preview", nil, nil, zawakeID)
					return
				end
			end
		end
	end
	gGameUI:showTip(gLanguageCsv.zawakeNoPreviewSkill)
end

function ZawakeView:onResetClick()
	local zawake = self.zawake:read() or {}
	local stage = zawake[self.zawakeID:read()] or {}
	for stage, level in pairs(stage) do
		if level > 0 then
			gGameUI:stackUI("city.zawake.reset", nil, nil, self.zawakeID:read())
			return
		end
	end
	gGameUI:showTip(gLanguageCsv.zawakeResetTips)
end

function ZawakeView:onReplaceClick()
	gGameUI:stackUI("city.zawake.replace", nil, nil, {zawakeID = self.zawakeID})
end

function ZawakeView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function ZawakeView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.zawake)
		end),
		c.noteText(124001, 124051),
	}
	return context
end

function ZawakeView:onClose()
	local cb = self.params.cb
	if cb and self.params.zawakeID ~= self.zawakeID:read() then
		-- zawakeID 发生变动，对应精灵存在，选最高战力精灵
		local data = zawakeTools.getCardByZawakeID(self.zawakeID:read())
		if data.dbId then
			cb(data.dbId)
		end
	end
	gGameApp:requestServer("/game/card/zawake/quit")
	ViewBase.onClose(self)
end

return ZawakeView