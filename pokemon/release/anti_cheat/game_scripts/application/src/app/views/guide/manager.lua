-- @date: 2019-6-12
-- @desc: 通用引导 Manager

local insert = table.insert
local NextGuideActionTag = 1907061635

local GuideManager = class("GuideManager")
GuideManager.NextGuideActionTag = NextGuideActionTag

local GuideView = {}
GuideView.RESOURCE_FILENAME = "common_guide.json"
GuideView.RESOURCE_BINDING = {
	["skipBtn"] = "skipBtn",
	["btnL"] = "btnL",
	["btnR"] = "btnR",
	["box"] = "box",
}
GuideManager.GuideView = GuideView

local BattleStoryPanelView = {}
BattleStoryPanelView.RESOURCE_FILENAME = "battle_story_panel.json"
BattleStoryPanelView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["skipBtn"] = "skipBtn",
	["nameL"] = "nameL",
	["nameR"] = "nameR",
	["textBkg"] = "textBkg",
	["textAarea"] = "textAarea",
	["texL"] = "texL",
	["texR"] = "texR",
	["selectItem"] = "selectItem",
	["listSelect"] = "listSelect",
}
GuideManager.BattleStoryPanelView = BattleStoryPanelView

-- 个别界面下才检测是否有全局的引导
local CHECK_GUIDE_IN_VIEW = {
	["common.upgrade_notice"] = true,
	["battle.battle_end.random_win"] = true,
	["battle.battle_end.win"] = true,
}

function GuideManager:ctor()
	self.curGuideId = nil
	self.inGuiding = false -- 是否在新手引导
	self.guidePanel = nil
	self.ignoreGuide = false
	self.choicesFunc = nil
	self.guideCsv = csv.new_guide
	self.stageCsv = gGuideStageCsv
end

function GuideManager:setIgnoreGuide(flag)
	self.ignoreGuide = flag
	return self
end

-- 是否完成某阶段引导
function GuideManager:checkFinished(stageId)
	local guideIds = gGameModel.role:read("newbie_guide")
	for _, id in ipairs(guideIds) do
		if stageId == id then
			return true
		end
	end
	return false
end

function GuideManager:isInGuiding()
	return self.inGuiding, self.curGuideId
end

function GuideManager:onClose()
	gGameUI.scene:stopAllActionsByTag(NextGuideActionTag)
	self:cleanGuidePanel()
	self.inGuiding = false
	gGameUI.guideLayer:stopAllActions()
	gGameUI.guideLayer:hide()
end

-- 强制关闭引导界面，若stage有值，完成该条引导
function GuideManager:forceClose(stage, startSceen)
	self:onClose()
	gGameUI:removeAllDelayTouchDispatch()

	if startSceen then
		for _, v in orderCsvPairs(self.guideCsv) do
			if v.startSceen == startSceen then
				stage = v.stage
				break
			end
		end
	end
	if stage and not self:checkFinished(stage) then
		self:onSaveStage(nil, stage)
	end
end

function GuideManager:onCleanup()
	self.orderStageCsv = nil
end

function GuideManager:onSaveStage(cb, stage)
	gGameApp:requestServer("/game/role/guide/newbie", cb, stage)
end

-- 检测当前状态是否有引导
-- @param params {specialName(特殊场景), name(startSceen场景符合触发判断), awardCb, endCb}
function GuideManager:checkGuide(params)
	params = params or {}
	log.guide("check name:", params.name, "isInGuiding:", self:isInGuiding(), self.ignoreGuide, self.continueLastGuide)
	if dev.GUIDE_CLOSED or FOR_SHENHE or self.ignoreGuide then
		return
	end
	if gGameUI.rootViewName == "login.view" then
		return
	end
	local guideIds = gGameModel.role:read("newbie_guide")
	if not guideIds then
		return
	end
	if self:isInGuiding() then
		return
	end
	local specialName = params.specialName
	if not specialName then
		if self:checkFinished(-2) then
			return
		end
	end

	if self.continueLastGuide then
		self.curGuideId = self.continueLastGuide
		self.continueLastGuide = nil
		self.inGuiding = true
		self:nextGuide()
		return true
	end

	self.curGuideId = nil
	if not self.orderStageCsv then
		self.orderStageCsv = {}
		local hashIds = arraytools.hash(guideIds)
		for stage, v in pairs(self.stageCsv) do
			if not hashIds[stage] then
				insert(self.orderStageCsv, self.guideCsv[v.begin])
			end
		end
		table.sort(self.orderStageCsv, function(a, b)
			if a.order ~= b.order then
				return a.order < b.order
			end
			return a.stage < b.stage
		end)
	end
	-- 查找可以触发的引导
	for i, cfg in ipairs(self.orderStageCsv) do
		if self:canTriggerGuide(cfg, params) then
			table.remove(self.orderStageCsv, i)
			self:triggerGuide(cfg.id, params)
			return true
		end
	end
	if CHECK_GUIDE_IN_VIEW[params.name] then
		self:checkGuide({name = "all"})
	end
end

-- @desc 如果非特殊系统进入可触发引导，或者特殊系统符合 specialName 可触发
function GuideManager:canTriggerGuide(cfg, params)
	if self:checkFinished(cfg.stage) then
		return false
	end
	local stageCfg = self.stageCsv[cfg.stage]
	-- 非特殊场景，且配置非特殊场景 nil == nil
	-- 特殊场景，且配置特殊场景匹配
	if params.specialName ~= stageCfg.specialName then
		return false
	end
	if not params.specialName then
		if cfg.startSceen == "all" and params.name == "city.view" then
			-- check next
		elseif (cfg.startSceen or "city.view") ~= params.name then
			return false
		end
	end
	local level = gGameModel.role:read("level")
	local extendCondition = eval.doFormula(cfg.extendCondition, {finish = functools.partial(self.checkFinished, self)}, cfg.extendCondition)
	if not (cfg.id == stageCfg.begin and level >= cfg.startLevel and dataEasy.isGateFinished(cfg.startGate) and extendCondition ~= false) then
		return false
	end
	return true
end

-- 检查是否满足关卡条件
function GuideManager:checkGateCondition(condition)
	local gateStars = gGameModel.role:read("gate_star")
	local gateId = condition.startGate
	if not gateId or gateId == 0 then return true end
	if gateStars[gateId] and gateStars[gateId].star and gateStars[gateId].star > 0 then
		return true
	end
	return false
end

function GuideManager:triggerGuide(guideId, params)
	log.guide(params.log or "trigger:", guideId)
	if self.ignoreGuide then
		self:onClose()
		return
	end
	local cfg = self.guideCsv[guideId]
	self.curGuideId = guideId
	self.inGuiding = true
	self.continueLastGuide = nil
	if cfg.award or cfg.awardChoose then
		self:quiteGiveAward(cfg, guideId, params)
		return
	end
	gGameUI.guideLayer:show()

	if cfg.battleEnter then
		self:setBattleCardEnter(cfg.battleEnter)
	end

	-- 受 outDelay 和 界面缩圈等影响，指定恢复响应
	gGameUI:disableTouchDispatch(nil, false)
	if cfg.showType == 3 then
		if cfg.outDelay or 0 > 0 then
			printWarn("guide 检查id(%d), 不应配置outDelay，尝试使用多个空白条", guideId)
		end
		self.continueLastGuide = self.curGuideId
		self:onClose()
		gGameUI:disableTouchDispatch(nil, true)
	else
		transition.executeSequence(gGameUI.guideLayer, true)
			:delay(cfg.outDelay or 0)
			:func(function()
				if cfg.showType == 2 then -- 选项引导
					self:showDialog(cfg, function(params)
						self:nextGuide(params)
					end, params)
					gGameUI:disableTouchDispatch(nil, true)
				else
					self:showClickGuide(cfg, function()
						self:nextGuide(params)
					end)
					-- showClickGuide 缩圈后触发 gGameUI:disableTouchDispatch(nil, true)
				end
			end)
			:done()
	end
end

-- 目前这种回调只支持获得奖励那条数据字在引导的最后面(如果要出现获得弹框的话)
-- 不然会导致二级弹框出现之后引导还继续下去
function GuideManager:quiteGiveAward(cfg, guideId, params)
	-- 延迟一帧请求
	gGameUI:disableTouchDispatch(0.01)
	performWithDelay(gGameUI.scene, function()
		gGameApp:requestServerCustom("/game/role/guide/newbie/award")
			:onErrCall(function()
				self:forceClose()
			end)
			:params(guideId)
			:doit(function(tb)
				local function cb()
					if params.awardCb then
						params.awardCb()
					end
					-- 消息回调回来后，可能已经触发升级
					self:nextGuide(params)
				end
				if cfg.showAward then
					gGameUI.guideLayer:hide()
					gGameUI:showGainDisplay(tb, {cb = cb})
				else
					cb()
				end
			end)
	end, 0)
end

-- 进行下个引导, 触发下一个引导延迟，要在打开界面和请求回来后检测
function GuideManager:nextGuide(params)
	if self.ignoreGuide or not self.curGuideId then
		self:onClose()
		return
	end
	params = params or {}
	local lastCfg = self.guideCsv[self.curGuideId]
	local function cb()
		gGameUI:disableTouchDispatch(nil, true)
		if lastCfg.gotoScene ~= 0 then
			self:jumpScene(lastCfg)
		end
		if self.curGuideId then
			local nextId = params.nextId or (self.curGuideId + 1)
			local nextCfg = self.guideCsv[nextId]
			if nextCfg and lastCfg.stage == nextCfg.stage and nextId ~= params.endId then
				params.nextId = nil
				self:triggerGuide(nextId, params)
				return
			end
			if lastCfg.gotoStep then
				self:triggerGuide(lastCfg.gotoStep, params)
				return
			end
		end
		self:onClose()
		if params.endCb then
			params.endCb()
		else
			local _, name = gGameUI:getTopStackUI()
			self:checkGuide({name = name})
		end
	end
	-- 一些引导按钮点击的有请求，等待当前请求返回后继续下一步引导
	gGameUI:disableTouchDispatch(nil, false)
	local action = nil
	action = schedule(gGameUI.scene, function()
		if not gGameUI:isConnecting() and action then
			gGameUI.scene:stopAllActionsByTag(NextGuideActionTag)
			action = nil
			if lastCfg.service == 3 then
				-- 进战斗保存点特殊处理
				self.inBattleStage = lastCfg.stage
				self:onClose()
				gGameUI:disableTouchDispatch(nil, true)

			elseif lastCfg.service ~= 0 and not lastCfg.award and not lastCfg.awardChoose then
				self:onSaveStage(function()
					-- stage = 32 的 时候认为初步引导已完成
					if lastCfg.stage == 32 then
						sdk.commitRoleInfo(6,function()
							print("sdk newbiewGuide pass")
						end)
					end
					cb()
				end, lastCfg.stage)
			else
				cb()
			end
		end
	end, 0)
	action:setTag(NextGuideActionTag)
end

function GuideManager:battleStageSave(cb)
	if self.inBattleStage then
		-- 引导优化，优先处理战斗结算请求带上引导id
		gGameModel:setNewGuideID(self.inBattleStage)
		self.inBattleStage = nil
		cb()
	else
		cb()
	end
end

-- 手新引导时，强制卡牌上阵
function GuideManager:setBattleCardEnter(cardsEnter)
	local battleCards = table.deepcopy(gGameModel.role:read("battle_cards"), true)
	for k,v in csvMapPairs(cardsEnter) do
		if v == 0 then
			battleCards[k] = nil
		else
			local dbid = dataEasy.getCardById(v)
			if dbid then
				battleCards[k] = dbid
			end
		end
	end
	gGameApp:requestServer("/game/battle/card", nil, battleCards)
end

-- 1跳转转到主城 2跳转到关卡
function GuideManager:jumpScene(cfg)
	gGameUI:cleanStash()
	if cfg.gotoScene == 1 then
		self:gotoCity()

	elseif cfg.gotoScene == 2 then
		self:gotoBattleMap()

	elseif cfg.gotoScene >= 3 then
		self:gotoBattleMap(cfg.gotoScene)
	end
end

function GuideManager:gotoCity()
	gGameUI:switchUI("city.view")
end

function GuideManager:gotoBattleMap(chapterId)
	self:gotoCity()
	jumpEasy.jumpTo("gate", chapterId)
end

function GuideManager:cleanGuidePanel()
	if self.guideView then
		self.guideView:stopAllActions()
		self.guideView:unScheduleAll()
		self.guideView = nil
	end
	if self.guidePanel then
		self.guidePanel:removeFromParent()
		self.guidePanel = nil
	end
end

-- params {isBattle, skipCb}
function GuideManager:showDialog(cfg, cb, params)
	params = params or {}
	if not gGameUI.guideLayer:get("dialog") then
		self:cleanGuidePanel()
		self.guidePanel = ccui.Layout:create()
			:anchorPoint(0.5, 0.5)
			:size(display.sizeInView.width, display.sizeInView.height)
			:xy(display.size.width/2, display.size.height/2)
			:addTo(gGameUI.guideLayer, 1, "dialog")
		self.guidePanel:setBackGroundColorType(1)
		self.guidePanel:setBackGroundColor(cc.c3b(0, 0, 0))
		self.guidePanel:setBackGroundColorOpacity(150)
		self.guidePanel:setTouchEnabled(true)

		self.guideView = gGameUI:createSimpleView(BattleStoryPanelView, self.guidePanel):init()
		self.guideView:x(display.uiOrigin.x)
		self.guideView:enableSchedule()
		self.guideView.skipBtn:hide()
		text.addEffect(self.guideView.skipBtn:get("text"), {glow = {color = ui.COLORS.GLOW.WHITE}})

		local node = self.guideView:getResourceNode()
		node:setTouchEnabled(false)
		node:get("texL"):hide()
		node:get("texR"):hide()
		local x, y = node:get("texL"):xy()
		self.guideView.texLPos = cc.p(x, y)
		local x, y = node:get("texR"):xy()
		self.guideView.texRPos = cc.p(x, y)

		ccui.ImageView:create()
			:addTo(node, 0, "bgRes")
			:anchorPoint(0.5, 0.5)
			:xy(display.sizeInView.width/2, display.sizeInView.height/2)
			:scale(2)
			:hide()

	end

	local panel = self.guidePanel
	local view = self.guideView:show()
	local node = view:getResourceNode()

	if view.lastShowRecover then
		view.lastShowRecover()
	end

	if cfg.bgRes then
		node:get("bgRes"):show()
			:texture(cfg.bgRes)
	else
		node:get("bgRes"):hide()
	end

	local show = ""
	local name = ""
	local texScale = 1
	local texOffX = 0
	local texOffY = 0
	if cfg.useRoleFigure then
		local tb = cfg.useRoleFigure
		local figureId = tb[1]
		local resType = tb[2] or "res"
		if figureId == 0 then
			local playName = gGameModel.role:read("name") or ""
			local playFigureId = gGameModel.role:read("figure") or 1
			local roleTb = gRoleFigureCsv[playFigureId] or {}
			show = roleTb[resType]
			name = playName
		else
			local roleTb = gRoleFigureCsv[figureId] or {}
			show = roleTb[resType]
			name = roleTb.name
		end
		texScale = 1.3
	elseif cfg.unitId then
		local unitId = cfg.unitId
		local unitCfg = csv.unit[unitId] or {}
		show = unitCfg.show
		name = unitCfg.name
		texScale = 1.77
		texOffX = -108
		texOffY = 676
	else
		show = cfg.headRes
		name = cfg.roleName
		texScale = 1.3
	end
	local offPos = cfg.offPos or {}
	texOffX = texOffX + (offPos.x or 0)
	texOffY = texOffY + (offPos.y or 0)

	local isLeft = cfg.force == 1
	local lr = isLeft and "L" or "R"
	local rl = isLeft and "R" or "L"

	-- name
	view.nameL:hide()
	view.nameR:hide()
	if name and name ~= "" then
		node:get("name" .. lr):show()
		node:get("name" .. lr .. ".name"):text(name)
		adapt.setTextScaleWithWidth(node:get("name" .. lr .. ".name"), nil, 450)
	end

	-- texture
	local facing = isLeft and 1 or -1
	local pos = view["tex" .. lr .. "Pos"]
	if show and show ~= "" then
		node:get("tex" .. lr):show()
			:texture(show)
			:scale(facing * texScale * 1.1, texScale * 1.1)
			:xy(pos.x + texOffX * facing, pos.y + texOffY)
	else
		node:get("tex" .. lr):hide()
	end
	-- cache.setShader(node:get("tex" .. lr), false, "normal")
	-- cache.setShader(node:get("tex" .. rl), false, "hsl_gray")
	node:get("tex" .. lr):color(cc.c3b(255, 255, 255))
	node:get("tex" .. rl):color(cc.c3b(128, 128, 128))

	-- 下一个剧情的时候比例改回原比例
	view.lastShowRecover = function()
		node:get("tex" .. lr):scale(facing * texScale, texScale)
	end

	-- 对话
	local str = "#C0x5b545b##F50#" .. cfg.talkContent
	view.textAarea:removeChildByName("richText")
	local tsize = view.textAarea:size()
	local sRichText = StreamRichText.new(str, tsize.width)
	local richText = sRichText.raw
	local textLen = sRichText:getLen() + 20
	richText:ignoreContentAdaptWithSize(false)
	local rsize = richText:getVirtualRendererSize()
	richText:size(tsize.width, rsize.height)
		:xy(0, tsize.height - 20)
		:anchorPoint(0, 1)
		:addTo(view.textAarea, 3, "richText")
	view:unSchedule("write")

	--- 添加聊天框内容
	-- 1:初始，字打印中；2:内容加载完；3:界面隐藏
	local state = 1
	local function storyOver()
		if state == 1 then
			state = 2
			sRichText:showWithLen(textLen)
			richText:formatText()
			view:unSchedule("write")
		end
	end

	local function stroyClose(cb, params)
		if state < 3 then
			state = 3
			view.skipBtn:stopAllActions()
			view:unSchedule("write")
			view:hide()
			if cb then
				cb(params)
			end
		end
	end

	local i = 1
	sRichText:showWithLen(1)
	view:schedule(function()
		if i > textLen then
			storyOver()
			return false
		end
		i = i + 1
		sRichText:showWithLen(i)
		richText:formatText()
	end, 0.02, 0, "write") -- 0.02

	local showSelectPanel = type(cfg.choices) == "table" and table.length(cfg.choices) > 0

	self.guideView.bg:visible(not showSelectPanel)
	view.listSelect:visible(showSelectPanel)

	-- 是否存在选项
	if showSelectPanel and cfg.showType ~= 3 then
		local choicesDatas = {}
		for _, id in ipairs(cfg.choices) do
			local choicesCfg = csv.scene_story_choices[id]
			local text = choicesCfg.text

			local function onClickCallBack()
				if state == 2 then
					params.nextId = choicesCfg.startStoryID
					stroyClose(cb, params)
					if cb then
						self:runChoicesFunc(cfg, choicesCfg)
					end
				end
			end
			insert(choicesDatas, {text = text, onClickCallBack = onClickCallBack})
		end

		bind.extend(self.guideView, view.listSelect, {
			class = "listview",
			props = {
				data = choicesDatas,
				item = view.selectItem,
				onItem = function(list, node, k, v)
					node:get("textNum"):text(k)
					adapt.setTextAdaptWithSize(node:get("text"), {str = v.text})
					bind.click(list, node, {method = v.onClickCallBack})
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end,
			}
		})
	else
		self.guideView.bg:onClick(function()
			if state == 1 then
				storyOver()

			elseif state == 2 then
				stroyClose(cb, params)
			end
		end)

		if cfg.needAutoJump == 1 then
			performWithDelay(view.skipBtn, function()
				stroyClose(cb, params)
			end, cfg.lastTime / 1000)
		end
		view.skipBtn:visible(cfg.canSkip or false)

		if params.skipCb then
			bind.touch(view, view.skipBtn, {methods = {ended = function()
				stroyClose(params.skipCb, params)
			end}})
		end
	end
end

-- params {isBattle}
function GuideManager:showClickGuide(cfg, cb, params)
	params = params or {}
	self:cleanGuidePanel()
	self.guidePanel = ccui.Layout:create()
		:anchorPoint(0.5, 0.5)
		:size(display.sizeInView.width, display.sizeInView.height)
		:xy(display.size.width/2, display.size.height/2)
		:addTo(gGameUI.guideLayer, 1, "click")
	self.guidePanel:setTouchEnabled(false)

	local view = gGameUI:createSimpleView(GuideView, self.guidePanel):init()
		:x(display.uiOrigin.x)
		:z(10)
	self.guideView = view
	view:enableSchedule()
	view.skipBtn:hide()
	local childs = view.box:multiget("textBg", "textArea", "texL", "texR", "nameL", "nameR")
	local node = view:getResourceNode()
	node:setTouchEnabled(false)

	local clickCount = 0
	local specialClickCount = 0
	local maskPanel = ccui.Layout:create()
		:size(display.sizeInView.width, display.sizeInView.height)
		:alignCenter(display.sizeInView)
		:addTo(self.guidePanel, 1)
	maskPanel:setBackGroundColorType(1)
	maskPanel:setBackGroundColor(cc.c3b(0, 0, 0))
	maskPanel:setBackGroundColorOpacity(150)
	maskPanel:setTouchEnabled(true)
	local skipSeq = {1, 2, 3, 4, 1, 4, 3, 2, 1}
	local range = cc.size(800, 400)
	maskPanel:onClick(function(event)
		gGameUI:showTip(gLanguageCsv.guideTip)
		if not params.isBattle then
			clickCount = clickCount + 1
			-- TODO 不是跳过引导，执行下一步引导，较难实现，目前没有方案
			-- if clickCount >= 10 then
			-- 	self:cleanGuidePanel()
			--  	cb()
			-- 	return
			-- end
			local isLeftTop = event.x <= range.width and (event.y >= display.sizeInView.height - range.height)
			local isRightTop = (event.x >= display.sizeInView.width - range.width) and (event.y >= display.sizeInView.height - range.height)
			local isRightBottom = (event.x >= display.sizeInView.width - range.width) and event.y <= range.height
			local isLeftBottom = event.x <= range.width and event.y <= range.height
			local dir = {isLeftTop, isRightTop, isRightBottom, isLeftBottom}
			if specialClickCount < #skipSeq and dir[skipSeq[specialClickCount+1]] then
				specialClickCount = specialClickCount + 1
				if specialClickCount == #skipSeq then
					specialClickCount = 0
					-- 强制关闭普通引导
					self:onSaveStage(function(tb)
						self:onClose()
					end, -2)
				end
			else
				specialClickCount = 0
			end
		end
	end)

	-- btn
	local function chooseBtn(name)
		if name then
			self:onClose()
			jumpEasy.jumpTo(name)
			return
		end
		self:cleanGuidePanel()
		cb()
	end
	view.btnL:hide()
	view.btnR:hide()
	if cfg.chooseDesc1 then
		view.btnL:show()
		view.btnL:get("text"):text(cfg.chooseDesc1)
		text.addEffect(view.btnL:get("text"), {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
		bind.touch(view, view.btnL, {methods = {ended = functools.partial(chooseBtn, cfg.choose1)}})
	end
	if cfg.chooseDesc2 then
		view.btnR:show()
		view.btnR:get("text"):text(cfg.chooseDesc2)
		text.addEffect(view.btnR:get("text"), {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
		bind.touch(view, view.btnR, {methods = {ended = functools.partial(chooseBtn, cfg.choose2)}})
	end

	if cfg.talkContent ~= "" then
		-- texture name
		itertools.invoke({childs.texL, childs.texR, childs.nameL, childs.nameR}, "hide")
		local texShow = cfg.force == 1 and childs.texL or childs.texR
		texShow:show():texture(cfg.headRes)
		if cfg.roleName then
			local nameShow = cfg.force == 1 and childs.nameL or childs.nameR
			nameShow:show()
			nameShow:get("name"):text(cfg.roleName)
			nameShow:width(nameShow:get("name"):width() + 40 )
			nameShow:get("name"):alignCenter(nameShow:size())
		end
		childs.textBg:setFlippedX(cfg.force == 1)

		-- text
		local size = childs.textArea:size()
		local list = beauty.textScroll({
			size = size,
			fontSize = 50,
			strs = "#C0x5b545b#" .. cfg.talkContent,
			isRich = true,
		})
		list:addTo(childs.textArea)
		local dh = math.max(list:getInnerItemSize().height, 120) - 120
		list:height(childs.textArea:height() + dh)
		childs.textBg:height(childs.textBg:height() + dh)

		-- 引导员位置设置
		local offPos = cfg.offPos or {}
		local x, y = view.box:xy()
		view.box:xy(x + (offPos.x or 0), y + (offPos.y or 0))
	else
		view.box:hide()
	end

	local function targetNodeCb(targetNode)
		if targetNode then
			if not cfg.anyPosCancel and not targetNode:isTouchEnabled() then
				printWarn("guide targetNode:isTouchEnabled(目标控件定位可能存在问题) id(%s): <%s>", tostring(self.curGuideId), tostring(table.concat(cfg.tagName, ";")))
			end
			local size = targetNode:box()
			local pos = gGameUI:getConvertPos(targetNode)
			local anchorPoint = targetNode:anchorPoint()
			pos.x = pos.x - anchorPoint.x * size.width + display.uiOrigin.x
			pos.y = pos.y - anchorPoint.y * size.height

			-- 设置裁剪区域
			local bgRender = cc.RenderTexture:create(display.sizeInView.width, display.sizeInView.height)
				:addTo(self.guidePanel, 1, "bgRender")
			local colorLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 150), display.sizeInView.width, display.sizeInView.height)
			local stencil = ccui.Scale9Sprite:create()
			local lightSize = cfg.lightSize or {}
			local width = lightSize.width or size.width
			local height = lightSize.height or size.height
			colorLayer:retain()
			stencil:retain()
			stencil:initWithFile(cc.rect(80, 80, 1, 1), "other/guide/icon_mask.png")
			stencil:anchorPoint(0.5, 0.5)
				:size(width, height)
				:xy(pos.x+size.width/2+(lightSize.dx or 0), pos.y+size.height/2+(lightSize.dy or 0))
			stencil:setBlendFunc({src = GL_DST_ALPHA, dst = 0})

			-- 设置遮罩表现
			local scaleX = display.sizeInView.width*2/size.width
			local scaleY = display.sizeInView.height*2/size.height
			local scale = math.max(scaleX, scaleY)
			stencil:scale(scale)

			bgRender:begin()
			colorLayer:visit()
			stencil:visit()
			bgRender:endToLua()

			local isNormal = false
			local scaleDt = scale - 1
			view:schedule(function(dt)
				scale = scale - (dt / 0.3) * scaleDt
				if not isNormal then
					if scale <= 1 then
						scale = 1
						isNormal = true
					end
					stencil:scale(scale)
					bgRender:beginWithClear(0, 0, 0, 0)
					colorLayer:visit()
					stencil:visit()
					bgRender:endToLua()
				else
					colorLayer:release()
					stencil:release()
					-- 引导手指
					if cfg.animate then
						local animatePos = cfg.animatePos or {}
						local x = pos.x + size.width/2 + (animatePos.x or 0)
						local y = pos.y + size.height/2 + (animatePos.y or 0)
						local figureNode = ccui.Layout:create()
							:size(0, 0)
							:rotate(cfg.animateAngle)
							:xy(x, y)
							:addTo(self.guidePanel, 9)
						widget.addAnimation(figureNode, cfg.animate, "effect_loop")
						audio.playEffectWithWeekBGM("guide.mp3")
					end
					gGameUI:disableTouchDispatch(nil, true)
					return false
				end
			end, 1/30., 0, "guideCircleAni")

			maskPanel:setBackGroundColorOpacity(0)
			local clickLayer = cc.LayerColor:create(cc.c4b(255, 0, 255, 150), display.sizeInView.width, display.sizeInView.height)
				:addTo(self.guidePanel, 2)
			local isHit = false
			clickLayer:hide()
			local listener = cc.EventListenerTouchOneByOne:create()
			local eventDispatcher = clickLayer:getEventDispatcher()
			local touchBeganPos = cc.p(0, 0)
			local function transferTouch(event)
				listener:setEnabled(false)
				eventDispatcher:dispatchEvent(event)
				listener:setEnabled(true)
			end
			local function onTouchBegan(touch, event)
				touchBeganPos = touch:getLocation()
				isHit = targetNode:hitTest(touchBeganPos)
				-- if isHit then
				-- 	-- 取消蒙版响应
				-- 	maskPanel:setTouchEnabled(false)
				-- 	maskPanel:setTouchEnabled(true)
				-- end
				-- transferTouch(event)
				return true
			end
			local function onTouchMoved(touch, event)
				transferTouch(event)
			end
			local function onTouchEnded(touch, event)
				local pos = touch:getLocation()
				local dx = pos.x - touchBeganPos.x
				local dy = pos.y - touchBeganPos.y
				local afterEndedFlag = false
				local targetHit = targetNode:hitTest(pos)
				log.guide("touch end, hit:", isHit, "isTouchEnabled:", targetNode:isTouchEnabled(), "hitTest:", targetHit)
				if isHit and targetHit then
					-- 取消蒙版响应
					maskPanel:setTouchEnabled(false)
					maskPanel:setTouchEnabled(true)
				end
				-- 触发响应（began不放在前面放置触发按钮回弹和moved）
				event:setEventCode(ccui.TouchEventType.began)
				transferTouch(event)
				log.guide("touch end, lighted:", targetNode:isHighlighted())
				event:setEventCode(ccui.TouchEventType.ended)

				-- 若点击释放后的位置非点击区域，则消息下发到蒙版
				if not (isHit and targetHit) then
					transferTouch(event)
					return
				end
				-- 点击可点击的目标，但未点中，则消息下发到蒙版提示
				if targetNode:isTouchEnabled() and not targetNode:isHighlighted() then
					transferTouch(event)
					return
				end
				self:cleanGuidePanel()
				transferTouch(event)
				cb()
			end
			listener:setSwallowTouches(true)
			listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
			listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
			listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
			listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_CANCELLED)
			eventDispatcher:addEventListenerWithSceneGraphPriority(listener, clickLayer)

		else
			gGameUI:disableTouchDispatch(nil, true)
			if cfg.lightSize then
				maskPanel:setBackGroundColorOpacity(0)
			end
		end

		if cfg.anyPosCancel or not targetNode then
			-- maskPanel:setBackGroundColorOpacity(0)
			node:setTouchEnabled(true)
			node:onClick(function()
				self:cleanGuidePanel()
				cb()
			end)
		end
	end

	-- 选中控件
	local targetNode = self:findNodeByName(gGameUI.scene, cfg.tagName)
	if table.length(cfg.tagName) > 0 and not targetNode then
		-- 如果当前帧找不到控件，容差1秒内不断尝试查找
		local delta = 0
		view:schedule(function(dt)
			delta = delta + dt
			targetNode = self:findNodeByName(gGameUI.scene, cfg.tagName)
			if (targetNode or delta > 1) then
				if not targetNode then
					printWarn("guide id(%s) 检查控件配置当前状态定位不到: <%s>", tostring(self.curGuideId), tostring(table.concat(cfg.tagName, ";")))
				end
				-- 找到目标后但界面目标有跳转的，延迟一帧定位控件
				performWithDelay(view, function()
					targetNodeCb(targetNode)
				end, 0)
				return false
			end
		end, 1/30., 0, "findTargetNode")
	else
		targetNodeCb(targetNode)
	end
end

-- 节点存在时，广搜比深搜快，name越完整越快
-- 查找是否有 name 的节点, 如 login.view
function GuideManager:findNodeByName(node, tagName, name)
	local hasTagName = not itertools.isempty(tagName)
	if not name and not hasTagName then return nil end
	local queue = queue or {{node = node, layer = 1}}
	local idx = 1
	while idx <= #queue do
		local data = queue[idx]
		local node = data.node
		-- printInfo("layer: %-2s node: %-40s name: %-20s", data.layer, tostring(node), node:getName())
		if name and name == node:getName() then
			return true
		end
		if hasTagName then
			local curNode = nodetools.get(node, unpack(tagName))
			if curNode and curNode ~= node and curNode:isVisibleInGlobal() then
				return curNode
			end
		end
		idx = idx + 1
		for k, v in pairs(node:getChildren()) do
			if v:isVisible() then
				insert(queue, {node = v, layer = data.layer + 1})
			end
		end
	end
end


function GuideManager:setChoicesFunc(f)
	self.choicesFunc = f
end

function GuideManager:runChoicesFunc(...)
	if self.choicesFunc then
		self.choicesFunc(...)
	end
end

return GuideManager