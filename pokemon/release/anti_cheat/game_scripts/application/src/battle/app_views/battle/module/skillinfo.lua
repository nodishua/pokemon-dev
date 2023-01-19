--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- 技能信息，3个小技能，1个大招。
local SkillInfo = class('SkillInfo', battleModule.CBase)

local _format = string.format
local widgetEffectNames = {
	hou = "dazhao_hou_loop",
	qian = "dazhao_qian_loop",
	shui = "dazhao_shui_loop",
	shan = "dazhao_shan",
	man = "dazhao_man_loop",
	mankuang = "dazhao_mankuang",
	mankuang_l = "dazhao_mankuang_loop",
}

-- 根据自身配表 查询本次obj的大招是否是第一次充满，（使用后重置）
function SkillInfo:selectIsFirstMainCharge(model, state)
	self.skillMainTb = self.skillMainTb or {}

	local key = tostring(model)

	if self.skillMainTb[key] ~= state and state then
		self.skillMainTb[key] = state
		return true
	end

	self.skillMainTb[key] = state
	return false
end

function SkillInfo:playMainSkillEffect(widget, state, model)
	if not widget.mpWater then
		error("water effect not exist")
	end

	local wsize = widget:size()
	if not widget.kuang then
		widget.kuang = newCSprite("effect/dz_ice.skel")
		widget:z(6):add(widget.kuang)
		widget.kuang:setPosition(cc.p(wsize.width/2 - 3, 5))
	end

	widget.kuang:visible(state)

	-- 使特效直接到达指定位置
	if state then
		widget.mpWater:play(self:getEffectName(widget, "shan"))
		widget.mpWater:addPlay(self:getEffectName(widget, "man"))
		if self:selectIsFirstMainCharge(model, state) then
			widget.kuang:z(10):play(self:getEffectName(widget, "mankuang"))
			widget.kuang:z(8):addPlay(self:getEffectName(widget, "mankuang_l"))
		else
			widget.kuang:play(self:getEffectName(widget, "mankuang_l"))
		end
	else
		widget.mpWater:play(self:getEffectName(widget, "shui"))
	end
end

function SkillInfo:getEffectName(widget, name, useDefault)
	local widgetEffects = widget.widgetEffects
	local effectName = widgetEffectNames[name]
	if widgetEffects and widgetEffects[name] then
		effectName = widgetEffects[name]
	end
	return effectName
end

function SkillInfo:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.widgets = {
		self.parent.UIWidgetBottomRight:get("skill1"),		-- 技能按钮 1~4
		self.parent.UIWidgetBottomRight:get("skill2"),
		self.parent.UIWidgetBottomRight:get("skill3"),
		self.parent.UIWidgetBottomRight:get("skill4"),
	}
	for _, v in ipairs(self.widgets) do
		v:hide()
	end
	self.cardClipping = self.parent.UIWidgetBottomRight:get("cardClipping")
	self.cardClipping:hide()
	self.cardClipping:setClippingEnabled(true)
	self.cardPx, self.cardPy = self.cardClipping:xy()
	self.cardPHalfWidth = self.cardClipping:size().width/2
	self.heroIcon = self.cardClipping:get("halfHeroIcon")		-- 角色半身像
	self.curSkill = nil
	self.skillWidgetMap = {}					-- 记录技能id对应哪个技能面板位置的： {[skillID] = panelId}
	self.originWidigetY = self.widgets[1]:getPositionY()
	-- 技能描述信息等的面板
	local infoPanel = self.parent.UIWidgetBottomRight:get("skillInfo")
	infoPanel:hide()
	self.infoPanelSize = infoPanel:getContentSize()	-- 先记录原始的大小方便调整回去
	self.skillCdMap = {} --把技能id和对应的冷却回合数的放进来做下记录 格式{[skillID] = leftCd}
end

-- 每个技能面板的初始化 widget, skillID, canSpell, leftCd, model
-- 如果是大招面板需要再做一些处理，面板id 1 是大招，其他是普通
function SkillInfo:skillInit(args, needMove)
	local orderId = args.orderId
	local widget = args.widget
	local skillID = args.skillID
	-- local canSpell = args.canSpell
	local leftCd = args.leftCd
	local model = args.model
	local precent = args.precent
	local costMp1 = args.costMp1
	local skillCfg = csv.skill[skillID]
	-- 技能名 伤害类型 技能属性类型
	widget:get("skillName"):setString(skillCfg.skillName)
	-- 存在技能伤害类型icon
	if skillCfg.skillDamageTypeIcon then
		widget:get("damageType"):loadTexture(skillCfg.skillDamageTypeIcon)
	else
		widget:get("damageType"):loadTexture(skillCfg.skillDamageType == battle.SkillDamageType.Physical and 'battle/icon_w.png' or 'battle/icon_t.png')
	end
	-- 策划那边说没有伤害的被动技能是没有自然属性的
	if game.NATURE_TABLE[args.natureType] ~= nil then
		widget:get("skillAttribute"):setVisible(true)
		widget:get("skillAttribute"):loadTexture(ui.ATTR_ICON[args.natureType])
	else
		widget:get("skillAttribute"):setVisible(false)
	end

	widget:setTouchEnabled(true)

	local zSkillCfg, isZawake = self:isZawakeSkill(skillCfg, model)
	-- TODO: 后期拓展
	widget:get("bgLogo"):setVisible(zSkillCfg ~= nil)

	-- 大招面板动画: 有个水的动画效果
	if orderId == 1 then
		local cdPercent = math.floor(100 * precent)
		cdPercent = math.min(math.max(0, cdPercent), 100)
		widget.widgetEffects = skillCfg.widgetEffects or {}
		local wsize = widget:size()
		-- 若没有 则新建一个
		if not widget.mpWater then
			widget:get('bg'):hide()
			local spr = newCSprite('battle/btn_skill_2.png')
				:addTo(widget,3)
				:xy(wsize.width/2, wsize.height/2)
			local mpHou = newCSprite("effect/dz_ice.skel")
			mpHou:play(self:getEffectName(widget, "hou"))
			mpHou:setPosition(cc.p(wsize.width/2 - 3 , 5))
			widget:add(mpHou, 2)
			widget.mpHou = mpHou
			local mpBall = newCSprite("effect/dz_ice.skel")
			mpBall:play(self:getEffectName(widget, "qian"))
			mpBall:setPosition(cc.p(wsize.width/2 - 3, 5))
			widget:add(mpBall, 4)
			widget.mpBall = mpBall
			local mpWater = newCSprite("effect/dz_ice.skel")
			mpWater:play(self:getEffectName(widget, "shui"))
			local bgWidget = cc.Sprite:create('battle/btn_skill.png')
			bgWidget:anchorPoint(0, 0):scale(0.98)
			local clipNode = cc.ClippingNode:create(bgWidget)
			clipNode:setAlphaThreshold(0.2)
			widget:add(clipNode)
			clipNode:add(mpWater)
			widget.mpWater = mpWater
		end
		local pos = cc.p(150, 200*cdPercent/100 -75)
		-- widget.mpWater:play("dazhao_shui_loop")
		widget.mpWater:stopAllActions()
		if needMove then
			widget.mpWater:setPosition(pos)
			-- 使特效直接到达指定位置
			self:playMainSkillEffect(widget, cdPercent >= 100, model)
		else
			-- 使特效移动到达指定位置
			local time = 0.6
			transition.executeSequence(widget.mpWater)
				:moveTo(time, 150, pos.y)
				:delay(0.01)
				:func(function ()
					self:playMainSkillEffect(widget, cdPercent >= 100, model)
				end)
				:done()
		end
		if costMp1 and costMp1 == 0 and not args.canSpell then
			widget:get('bg'):show()
			self:playMainSkillEffect(widget, false, model)
			widget.mpWater:hide()
			widget.mpHou:hide()
			widget.mpBall:hide()
		else
			widget:get('bg'):hide()
			widget.mpWater:show()
			widget.mpHou:show()
			widget.mpBall:show()
		end
	end

	-- 技能CD显示相关
	local roundLabel = widget:get("round")			-- 回合
	roundLabel:hide()
	roundLabel:scale(2.5)
	roundLabel:opacity(0)
	-- 在技能面板上加一层遮罩
	local skillCdBg = widget:get("cdBg")
	skillCdBg:hide()
	-- widget:get('bg'):loadTexture('battle/btn_skill.png')
	-- 技能进入cd后，显示回合数
	if not args.canSpell then
		if leftCd and leftCd > 0 and leftCd < 100 then
			skillCdBg:show()
			roundLabel:setVisible(true)
			roundLabel:setString(leftCd) -- 剩余回合数
			if not next(self.skillCdMap) or self.skillCdMap[skillID] ~= leftCd then --技能不同或者相同技能不同冷却回合播冷却特效
				transition.executeParallel(roundLabel)
					:fadeTo(0.5,255)
					:scaleTo(0.5, 1)
				self.skillCdMap[skillID] = leftCd
			else
				roundLabel:scale(1)
				roundLabel:opacity(255)
			end
			local cdPercent
			-- 这里的滚动条需要做一个更新,不是大招看cd回合，大招则看能量条百分比
			cdPercent = (1 - leftCd / skillCfg.cdRound) * 100
		end
	end
end

function SkillInfo:isZawakeSkill(skillCfg, model)
	local zawakeID = skillCfg.zawakeEffect[1]
	if zawakeID and model.tagSkills[zawakeID] then
		return csv.skill[zawakeID], skillCfg and skillCfg.zawakeEffect[2] == 1
	end
end

function SkillInfo:getSkillName(skillCfg, model)
	local skillName = skillCfg.skillName
	local zSkillCfg = self:isZawakeSkill(skillCfg, model)
	-- Z觉醒逻辑
	if zSkillCfg then
		return zSkillCfg.skillName .. skillName
	end
	return skillName
end

-- 按钮点击效果集中设置
function SkillInfo:skillButtonInit(args)
	local orderId = args.orderId
	local widget = args.widget
	local skillID = args.skillID
	-- local canSpell = args.canSpell
	local leftCd = args.leftCd
	local leftStartRound = args.leftStartRound
	local model = args.model
	local skillCfg = csv.skill[skillID]

	local clickFrame = widget:get("clickFrame")		-- 选中时的外边框
	clickFrame:hide()

	-- 显示技能面板信息  --isShow: true显示，false: 不显示
	local longTouchTriggered = false
	local function showSkillInfo(isShow)
		longTouchTriggered = isShow
		local skillInfo = self.parent.UIWidgetBottomRight:get("skillInfo")
		local container = skillInfo:get("container")
		local skillDescribe = container:get("skillDescribe")
		skillInfo:show()
		if not isShow then
			skillInfo:hide()
			skillDescribe:removeAllChildren()
			return
		end

		-- 设置技能信息显示在技能面板上
		local skillPosX, skillPosY= widget:getPosition()
		local wsize = widget:getBoundingBox()
		local offx = (orderId == 1) and -160 or 0			-- 在第一个技能处需要向左偏移
		skillInfo:setPosition(cc.p(skillPosX + offx, skillPosY + wsize.height/2 + 15))
		skillInfo:setLocalZOrder(99999)
		skillInfo:setVisible(true)

		local skillName = container:get("skillName")	-- 技能名
		skillName:setString(self:getSkillName(skillCfg, model))
		-- text.addEffect(skillName, {color=cc.c4b(75,75,77,255)})
		local targetDesc = nodetools.get(container, "skillrange")
		targetDesc:setString(skillCfg.targetTypeDesc)

		-- 添加富文本描述信息
		local descSize = skillDescribe:getContentSize()
		local widthAdapt = math.max(0, skillName:getContentSize().width + targetDesc:getContentSize().width - descSize.width)

		-- 多语言适配 cn, tw, kr, en
		local offsetValue = 0
		if matchLanguage({"en"}) then offsetValue = 150 end
		self.descSizeWidth = descSize.width + widthAdapt + offsetValue

		local describe = skillCfg.describe
		local isZawakeReplaceStarDesc = false
		local zSkillCfg = self:isZawakeSkill(skillCfg, model)
		-- Z觉醒逻辑
		if zSkillCfg then
			-- 替换星级效果
			if skillCfg.zawakeEffect[2] == 1 then
				isZawakeReplaceStarDesc = true
			else
				describe = skillCfg.zawakeEffectDesc
			end
		end

		-- #C0x之后跟的是富文本的颜色
		local skillLv = args.level
		local str = uiEasy.getStarSkillDesc({
			skillLevel = skillLv,
			skillId = skillID,
			star = model:getStar(),
			isZawake = isZawakeReplaceStarDesc
		})
		local skillContent = rich.createWithWidth(string.format("#C0x5b545b#%s", eval.doMixedFormula(describe,{skillLevel = skillLv or 1,math = math},nil) or "no desc")..str, 40, nil, self.descSizeWidth)
		skillContent:setAnchorPoint(cc.p(0, 1))	-- 左上角
		skillContent:setPosition(cc.p(0, 0))	--
		skillDescribe:addChild(skillContent, 99)

		-- 调整底图大小, container的位置
		local textHeight = skillContent:getContentSize().height
		local offy = math.max(0, textHeight - descSize.height)
		local newWidth = self.infoPanelSize.width + widthAdapt
		local newHeight = self.infoPanelSize.height + offy
		skillInfo:get("bg"):setContentSize(cc.size(newWidth + offsetValue, newHeight))	-- 底图大小修改
		targetDesc:setPosition(cc.p(self.infoPanelSize.width/2 + widthAdapt + offsetValue / 2, targetDesc:getPositionY()))
		container:setPosition(cc.p(self.infoPanelSize.width/2 - widthAdapt/2 - offsetValue / 2, newHeight))	-- 容器层位置调整
	end

	-- widget:setTouchEnabled(true)
	local action
	local nodeSize = widget:getContentSize()
	local rect = cc.rect(0, 0, nodeSize.width, nodeSize.height)
	widget:addTouchEventListener(function(sender, eventType)
		-- 引导过程忽略长按
		if self.parent.guideManager:isInGuiding() then
			showSkillInfo(false)
			if action then
				widget:stopAction(action)
				action = nil
			end
			return
		end
		if eventType == ccui.TouchEventType.began then
			if action then -- 防止stopAction时 action == nil
				widget:stopAction(action)
				action = nil
			end
			showSkillInfo(false)
			action = performWithDelay(widget, function()
				action = nil
				showSkillInfo(not self.parent.guideManager:isInGuiding())
			end, 0.3)

		elseif eventType == ccui.TouchEventType.moved then
			local touchPos = sender:getTouchMovePosition()
			local pos = widget:convertToNodeSpace(touchPos)
			-- 触摸点离开了技能面板就关闭展示信息
			if not cc.rectContainsPoint(rect, pos) then
				widget:stopAction(action)
				action = nil
				showSkillInfo(false)
			end
		elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
			widget:stopAction(action)
			action = nil
			showSkillInfo(false)
		end
	end)

	-- 点击 选中技能面板/取消选中
	widget:onClick(function()
		if longTouchTriggered then return end
		if self.cannotClick then return end
		local selectedSkill = model.skills[skillID]
		-- http://172.81.227.66:1104/crashinfo?_id=11140&type=1
		if not selectedSkill then
			errorInWindows("selectedSkill is nil model unitID(%s), orginUnitId(%s), skillID(%s), skillsOrder(%s)", model.unitID, model.orginUnitId, skillID, dumps(model.skillsOrder or {}))
			return
		end
		model.curSelectSkill = selectedSkill
		local canSelectObjNums = table.length(selectedSkill:getTargetsHint())
		-- 不能点击时的提示
		if not args.canSpell then
			local str
			if leftCd > 0 or leftStartRound > 0 then
				str = gLanguageCsv.skillCannotSpell
			elseif (model:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {skillType2 = battle.MainSkillType.BigSkill}) and skillCfg.skillType2 == battle.MainSkillType.BigSkill)
				or (model:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {skillType2 = battle.MainSkillType.SmallSkill}) and skillCfg.skillType2 == battle.MainSkillType.SmallSkill)
				or (model:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {skillType2 = battle.MainSkillType.NormalSkill}) and skillCfg.skillType2 == battle.MainSkillType.NormalSkill)
				or (model:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {skillId = skillID})) then
				str = gLanguageCsv.objectInControl
			elseif model:isBeInSneer() then
				str = gLanguageCsv.objectInSneer
			elseif canSelectObjNums == 0 then
				str = gLanguageCsv.canNotSelect
			else	-- mp 不满足需求
				str = gLanguageCsv.mpNotEnough
			end
			if str then
				gGameUI:showTip(str)		-- 提示
			end
			return
		end	-- 不能释放时, 返回
		-- 先清理下之前可能残留的技能目标的提示
		self:notify("selectedHero")
		-- 技能面板的移动
		if self.curSkill then	-- 如果之前已经点击过面板, 则需要把之前的面板移动回来
			local preBox = self.widgets[self.skillWidgetMap[self.curSkill]]
			preBox:get("clickFrame"):hide()
			transition.executeParallel(preBox):moveBy(0.02, 0, -10)
			if self.curSkill == skillID then	-- 如果点击的是同一个面板时, 表示要取消当前的选择, 此时可以再次查看属性面板了
				self:call("resetHitPanelStateToShowAttrsPanel")
				self.curSkill = nil
				return
			end
		end
		-- 选择技能目标
		self:notify("selectSkill", selectedSkill, args.exactImmuneInfos)
	end)
end

function SkillInfo:onSelectSkill(skill)
	local skillID = skill.id
	local widget = self.widgets[self.skillWidgetMap[skillID]]
	if not self.skillWidgetMap[skillID] or not widget then
		return
	end
	local clickFrame = widget:get("clickFrame")
	transition.executeParallel(widget)
		:moveBy(0.02, 0, 10)
	clickFrame:setVisible(true)
	self.curSkill = skillID
end

-- 技能信息数据刷新
-- 每回合时刷新一下, 放过技能后可能也要刷新下(目前每个战斗回合只放一次技能,倒是不用那这么频繁刷新)
-- model:放技能的目标，skillsOrder:目标拥有的所有技能的id记录表(按id大小正序排序的), skills:所有技能对象实例
-- 开场的被动技能流程下skillsOrder 和skillsStateInfoTb 有可能为空 先跳过处理
function SkillInfo:onSkillRefresh(model, skillsOrder, skillsStateInfoTb, immuneInfos)
	if (not skillsOrder or not next(skillsOrder)) or (not skillsStateInfoTb or not next(skillsStateInfoTb)) then
		return
	end
	local play = model.scene.play
	if not play:isPlaying() then
		self.cannotClick = true
		return
	end
	-- 自动攻击时技能面板无法被点击
	if play:isNowTurnAutoFight() then
		self.cannotClick = true
	end
	-- 刷新技能信息
	-- 技能位置对应顺序要转换一下
	-- (技能面板顺序是： 1-最右侧大招, 2-技能 3-普攻  技能配置id的大小顺序是：普攻 < 技能 < 大招)
	local skillsOrderLen = table.length(skillsOrder)
	-- table.sort(skillIdsTb, function(id1, id2)
	-- 	return id1 > id2
	-- end)
	-- local nowRound = play.curRound or 1

	local ret = {}
	-- 从最右侧面板的位置开始设置
	for i, skillID in ipairs(skillsOrder) do
		if i <= table.length(self.widgets) then
			skillID = model.skillsMap[skillID] or skillID
			local skillStateInfo = skillsStateInfoTb[skillID].stateInfoTb			-- 技能对象
			local args = {
				orderId = i,
				skillID = skillID,
				widget = self.widgets[i],									-- 技能UI
				-- canSpell = (model.force == 1) and skill:canSpell(),
				canSpell =  skillStateInfo.canSpell,						-- 允许释放
				-- leftCd = (model.force == 1) and skill:getLeftCDRound(),
				leftCd = skillStateInfo.leftCd,								-- 冷却剩余时间
				leftStartRound = skillStateInfo.leftStartRound,             -- 技能初始冷却
				precent = skillStateInfo.precent,
				level = skillStateInfo.level,
				model = model,												-- 当前行动单位
				costMp1 = skillsStateInfoTb[skillID].costMp1,               -- 消耗mp
				exactImmuneInfos = immuneInfos[skillID],
				natureType = skillsStateInfoTb[skillID]:getSkillNatureType()
			}
			ret[i] = args
			self:skillInit(args, true)
			self.skillWidgetMap[skillID] = i
			self.widgets[i]:setVisible(true)
			self.widgets[i]:setTouchEnabled(false)
			performWithDelay(self.widgets[i], function()
				self.widgets[i]:setTouchEnabled(true)
			end, 0)
		else
			-- error(string.format("too many skills skillId: %s, index: %s", skillID, i))
		end
	end

	-- 设置施法者的半身像位置
	self.heroIcon:loadTexture(model.unitCfg.show)		-- 角色半身像
	self.heroIcon:scale(model.unitCfg.bansxScale)
	local fixPos = model.unitCfg.bansxPosC
	self.heroIcon:xy(self.cardPHalfWidth + (fixPos.x or 0), fixPos.y or 0)
	self.heroIcon:setVisible(false)
	-- 只有三个技能的时候隐藏一个技能面板
	-- local widgetWidth = self.widgets[1]:getContentSize().width
	if skillsOrderLen < table.length(self.widgets) then
		for i = skillsOrderLen + 1, table.length(self.widgets) do
			self.widgets[i]:hide()
		end
	end
	-- self.skillMp1bar:setVisible(true)
	local newX = self.widgets[math.min(skillsOrderLen, table.length(self.widgets))]:getPositionX()
	self.cardClipping:xy(newX - 40 - self.cardPHalfWidth, self.cardPy)		-- 头像相对于技能面板左移

	for i, args in ipairs(ret) do
		self:skillButtonInit(args)
	end
	-- 恢复按钮状态
	for i,_ in pairs(self.widgets) do					-- 都坐下
		self.widgets[i]:setPositionY(self.originWidigetY)
	end
end

function SkillInfo:onNewBattleRound(args)
	self.curSkill = nil
	self.skillWidgetMap = {}
	self.cannotClick = nil		-- 禁止点击标签

	--自动战斗的时候，把面板都隐藏了
	if args.obj.scene.autoFight or args.isTurnAutoFight then
		self:hideAll()
	else
		self:onSkillRefresh(args.obj, args.skillsOrder, args.skillsStateInfoTb, args.immuneInfos)
	end
end

function SkillInfo:onBattleTurnEnd()
	self:hideAll()
end

function SkillInfo:onAutoSelectSkill(seat, skillId)
	local spr = self:call("getSceneObjBySeat", seat)
	if spr then
		self:onSelectObj(spr, skillId)
	end
end

function SkillInfo:onSelectObj(spr, skillID)
	local skillID = skillID or self.curSkill
	if self.curSkill == nil then
		if not skillID then
			return
		end
		self:onSelectSkill({id = skillID})
	end
	--选中之后隐藏选中光圈 (放技能spellAttack时,那边会做全部隐藏,所以在那边加了一个判断剔除当前选中的目标)
	self:notify("selectedHero") 	-- 先都隐藏, 选中的额外多放一会
	spr.natureQuan:show()
	transition.executeSequence(spr.natureQuan)
		:delay(0.5)
		:func(function ()
			spr.natureQuan:hide()
		end)
		:done()
	transition.executeSequence(spr.groundRing)
		:delay(0.5)
		:func(function ()
			spr.groundRing:hide()
		end)
		:done()

	self.curSkill = nil
	self.skillWidgetMap = {}
	for i, widget in ipairs(self.widgets) do
		widget:setTouchEnabled(false)
	end
	-- 传攻击指令
	self.parent:handleOperation(battle.OperateTable.attack, spr.model.seat, skillID)
	-- 选择目标之后隐藏技能面板
	-- self:hideAll()
	-- 选择目标之后禁止再次点击技能面板进行选择
	self.cannotClick = true
end


function SkillInfo:onClose()
end

-- 隐藏所有的技能面板包括宝可梦的半身像,并设置技能面板到底部
function SkillInfo:hideAll()
	for _,v in ipairs(self.widgets) do
		-- 屏幕会震动 多藏起来一截
		v:setPositionY(-self.originWidigetY-100)
		v:setVisible(false)
	end
	self.heroIcon:hide()
end

return SkillInfo
