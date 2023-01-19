local function getCostGold(skillLevel, costID, fastUpgradeNum)
	local costGold = 0
	for i=1,fastUpgradeNum do
		if csv.base_attribute.skill_level[skillLevel + i - 1] then
			costGold = costGold + csv.base_attribute.skill_level[skillLevel + i - 1]["gold" .. costID]
		end
	end
	return costGold
end
local CardSkillView = class("CardSkillView", cc.load("mvc").ViewBase)

CardSkillView.RESOURCE_FILENAME = "card_skill.json"
CardSkillView.RESOURCE_BINDING = {
	["panel.btnAdd"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSkillAddClick")}
		}
	},
	["panel.textNum"] = "skillNum",
	["panel.textNote"] = "textNote",
	["panel.textFlag"] = {
		varname = "skillMax",
		binds = {
			event = "text",
			idler = bindHelper.self("skillPointState")
		},
	},
	["panel.fastUpgradePanel.btnPanel"] = "btnFastUpgrade",
	["panel.fastUpgradePanel"] = {
		varname = "fastUpgradePanel",
		binds = {
			event = "click",
			method = bindHelper.self("onFastUpgradeClick")
		},
	},
	["item"] = "item",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("skillData"),
				item = bindHelper.self("item"),
				cardLv = bindHelper.self("cardLv"),
				star = bindHelper.self("star"),
				cardId = bindHelper.self("cardId"),
				advance = bindHelper.self("advance"),
				zawakeSkills = bindHelper.self("zawakeSkills"),
				canFastUpgrade = bindHelper.self("canFastUpgrade"),
				itemAction = {isAction = true},
				dataOrderCmp = function (a,b)
					if a.skillPassive ~= b.skillPassive then
						return a.skillPassive < b.skillPassive
					end
					return a.skillId < b.skillId
				end,
				onItem = function(list, node, k, v)
					node:name("item" .. list:getIdx(k))
					local skillInfo = csv.skill[v.skillId]
					local cardLv = list.cardLv:read()
					local childs = node:multiget("textLvNum", "textCost", "textName", "imgType", "btnAdd", "imgIcon", "imgBG", "textFastUpgradeNum")
					childs.textLvNum:text(v.skillLevel)
					local skillGold = getCostGold(v.skillLevel, skillInfo.costID, v.fastUpgradeNum)
					local goldColor = (v.clientGold >= skillGold) and cc.c4b(91, 84, 91, 255) or cc.c4b(249,87,114,255)
					text.addEffect(childs.textCost, {color = goldColor})
					childs.textCost:text(skillGold)
					uiEasy.setSkillInfoToItems({
						name = childs.textName,
						icon = childs.imgIcon,
						type1 = childs.imgType,
					}, v.skillId)
					adapt.setTextScaleWithWidth(childs.textName, nil, 300)
					cache.setShader(childs.btnAdd, false,(v.skillLevel + v.fastUpgradeNum <= cardLv) and "normal" or "hsl_gray")
					childs.btnAdd:onTouch(functools.partial(list.clickCell, node, k, v))
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCellTip, k, v)}})

					local state = true
					local name = ""
					local title = "s%"
					if skillInfo.activeType == 1 then
						state = list.star:read() >= skillInfo.activeCondition
						title = gLanguageCsv.potentialIncreasedStarsUnlocked
						name = skillInfo.activeCondition
					elseif skillInfo.activeType == 2 then
						state = list.advance:read() >= skillInfo.activeCondition
						title = gLanguageCsv.skillBreakAdvanceUnlocked
						name = uiEasy.setIconName("card", list.cardId:read(), {node = node:get("textTip"), name = ui.QUALITY_COLOR_TEXT, advance = skillInfo.activeCondition, space = true})
						name = ui.QUALITYCOLOR[dataEasy.getQuality(skillInfo.activeCondition)] .. gLanguageCsv.symbolSquareBracketLeft .. name .. gLanguageCsv.symbolSquareBracketRight
					end

					childs.textFastUpgradeNum:text(string.format(gLanguageCsv.upLevelNumber, v.fastUpgradeNum))
						:visible(list.canFastUpgrade:read() and state)
					node:removeChildByName("activeCondition")
					local richText = rich.createWithWidth(string.format(title, name), 40, nil, 800)
					richText:anchorPoint(0, 1)
						:xy(205, 95)
						:visible(not state)
						:addTo(node, 2, "activeCondition")
					node:get("imgMask"):visible(not state)
					node:get("imgCostIcon"):visible(state)
					node:get("textCost"):visible(state)
					node:get("btnAdd"):visible(state)

					childs.imgBG:z(0)
					node:removeChildByName("zawakeBg")
					childs.imgIcon:removeChildByName("zawakeUp")
					if dataEasy.isZawakeSkill(v.skillId, list.zawakeSkills:read()) then
						ccui.ImageView:create("city/zawake/panel_z1.png")
							:alignCenter(node:size())
							:addTo(node, 1, "zawakeBg")
						ccui.ImageView:create("city/drawcard/draw/txt_up.png")
							:scale(1.2)
							:align(cc.p(1, 1), 200, 190)
							:addTo(childs.imgIcon, 1, "zawakeUp")
						local zawakeEffectID = csv.skill[v.skillId].zawakeEffect[1]
						childs.textName:text(csv.skill[zawakeEffectID].skillName .. childs.textName:text())
					end
				end,
				asyncPreload = 5,
			},
			handlers = {
				clickCell = bindHelper.self("onItemAddClick"),
				clickCellTip = bindHelper.self("onItemTipClick"),
			},
		},
	},
}

function CardSkillView:onCreate(dbHandler)
	self.selectDbId = dbHandler()
	self:initModel()
	self:enableSchedule()
	self.skillData = idlers.new()
	self.skillPointState = idler.new("")
	self.skillList = {}

	self.tmpSkillPoint = idler.new(0)
	self.refreshPoint = idler.new(true)
	self.serverSkillPoint = idler.new(0)
	local state = userDefault.getForeverLocalKey("skillFastUpgrade", false)
	self.btnFastUpgrade:get("checkBox"):setSelectedState(state)
	self.canFastUpgrade = idler.new(false)
	dataEasy.getListenUnlock(gUnlockCsv.fastUpgrade, function(isUnlock)
		self.canFastUpgrade:set(state and isUnlock)
		self.fastUpgradePanel:visible(isUnlock)
	end)
	idlereasy.any({self.cardId, self.skinId, self.zawakeSkills},function(_, cardId, skinId)
		local skillData = {}

		local list =  dataEasy.getCardSkillList(cardId,skinId)
		if not list then return end
		self.skillList = list

		for k,v in csvPairs(self.skillList) do
			local passive = 1 -- 被动技能标记，默认1，为被动技能时改为2
			if csv.skill[v].skillType2 == battle.MainSkillType.PassiveSkill then
				passive = 2
			end
			local skillLevel = self.skills:read()[v] or 1
			skillData[v] = {
				skillId = v,
				skillLevel = skillLevel,
				skillPassive = passive,
				clientGold = self.gold:read(),
				fastUpgradeNum = self:getFastUpgradeNum(skillLevel),
			}
		end
		self:unSchedule("skillLvUp")
		self.skillData:update(skillData)
		self.tmpSkillPoint:set(0)
	end)

	idlereasy.any({self.skills, self.cardLv},function(_, skills)
		for i, v in csvPairs(self.skillList) do
			self.skillData:at(v):modify(function(data)
				data.skillLevel = skills[v] or 1
				data.fastUpgradeNum = self:getFastUpgradeNum(data.skillLevel)
			end, true)
		end
	end)
	self.clientGold = idler.new(0)
	idlereasy.when(self.gold,function(_, gold)
		self.clientGold:set(gold)
	end)
	idlereasy.when(self.clientGold,function(_, clientGold)
		for i, v in csvPairs(self.skillList) do
			self.skillData:at(v):modify(function(data)
				data.clientGold = clientGold
			end, true)
		end
	end)
	--恢复时间间隔
	local csvRecoverTime = 0
	idlereasy.when(self.vipLevel,function(_, vipLevel)
		csvRecoverTime = gVipCsv[vipLevel].skillPointRecoverTime
	end)
	--最大技能点数量
	local skillPointMax = 0
	idlereasy.when(self.roleLv,function(_, roleLv)
		skillPointMax = dataEasy.getSkillPointMax(roleLv)
	end)

	local valTime = nil
	idlereasy.any({self.skillPointLast, self.skillPoint, self.tmpSkillPoint, self.refreshPoint},function(_, skillPointLast, skillPoint, tmpSkillPoint)
		valTime = math.max(time.getTime() - math.ceil(skillPointLast), 0)
		for i=0,skillPointMax do
			if skillPoint >= skillPointMax then
				valTime = csvRecoverTime
				break
			end
			if valTime >= csvRecoverTime then
				valTime = valTime - csvRecoverTime
				skillPoint = skillPoint + 1
			else
				valTime = csvRecoverTime - valTime
				self.skillPointState:set("("..time.getCutDown(valTime).min_sec_clock..")")
				break
			end
		end
		self.serverSkillPoint:set(skillPoint-tmpSkillPoint)
	end)
	self.timeStart = idler.new(true)
	idlereasy.when(self.timeStart,function(_, timeStart)
		if timeStart then
			self:schedule(function ()
				self.refreshPoint:set(not self.refreshPoint:read())
			end, 1, 0, "CardSkillView")
		else
			self:unSchedule("CardSkillView")
			self.skillPointState:set("(MAX)")
		end
	end)

	idlereasy.any({self.serverSkillPoint, self.canFastUpgrade}, function(_, serverSkillPoint)
		local notSkillPointMax = (serverSkillPoint < skillPointMax)
		self.timeStart:set(notSkillPointMax)
		self.addBtn:visible(false)
		self.skillNum:text(serverSkillPoint)

		if serverSkillPoint >= gCommonConfigCsv.skillPointLimitMax then
			self.skillPointState:set("("..gLanguageCsv.alreadyMax..")")
		elseif serverSkillPoint >= skillPointMax then
			self.skillPointState:set("(MAX)")
		end

		adapt.oneLinePos(self.textNote, {self.skillNum, self.skillMax}, cc.p(20, 0), "left")
		for i, v in csvPairs(self.skillList) do
			self.skillData:at(v):modify(function(data)
				data.fastUpgradeNum = self:getFastUpgradeNum(data.skillLevel)
			end, true)
		end
	end)
end

function CardSkillView:initModel()
	self.items = gGameModel.role:getIdler("items")
	self.skillPointLast = gGameModel.role:getIdler("skill_point_last_recover_time")
	self.skillPoint = gGameModel.role:getIdler("skill_point")
	self.roleLv = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.gold = gGameModel.role:getIdler("gold")
	idlereasy.when(self.selectDbId,function (_, selectDbId)
		local card = gGameModel.cards:find(selectDbId)
		self.cardId = idlereasy.assign(card:getIdler("card_id"), self.cardId)
		self.skinId = idlereasy.assign(card:getIdler("skin_id"), self.skinId)
		self.cardLv = idlereasy.assign(card:getIdler("level"), self.cardLv)
		self.skills = idlereasy.assign(card:getIdler("skills"), self.skills)
		self.star = idlereasy.assign(card:getIdler("star"), self.star)
		self.advance = idlereasy.assign(card:getIdler("advance"), self.advance)
		self.zawakeSkills = idlereasy.assign(card:getIdler("zawake_skills"), self.advance)
		dataEasy.tryCallFunc(self.list, "setItemAction", {isAction = true})
	end)
end

--选择卡牌分解提示
function CardSkillView:onFastUpgradeClick()
	local state = userDefault.getForeverLocalKey("skillFastUpgrade", false)
	self.btnFastUpgrade:get("checkBox"):setSelectedState(not state)
	userDefault.setForeverLocalKey("skillFastUpgrade", not state)
	self.canFastUpgrade:set(not state)
end

function CardSkillView:getFastUpgradeNum(skillLevel)
	local fast = self.canFastUpgrade:read()
	if not fast then
		return 1
	end
	local cardLv = self.cardLv:read()
	if skillLevel >= cardLv then
		return 5
	end
	local nowSkill = self.serverSkillPoint:read()
	if nowSkill == 0 then
		return 1
	end
	return math.min(cardLv - skillLevel, math.min(nowSkill, 5))
end

function CardSkillView:onItemAddClick(list, node, k, v, event)
	if event.name == "began" then
		self.tmpSkillPoint:set(0)
		local time = 0.4
		local speed = 0.6
		self.notMoved = true
		self.touchBeganPos = clone(event)
		self:enableSchedule():schedule(function (dt)
			-- 这里的 gGameUI:isConnecting() 不能去掉，实际技能点和临时花费技能点大于上限要先发请求，不然服务器不会恢复技能点，导致不一致
			if time <= 0 and not gGameUI:isConnecting() then
				speed = (speed <= 0.2) and 0.2 or (speed - 0.2)
				time = speed
				v.skillLevel = self.skillData:atproxy(k).skillLevel
				v.fastUpgradeNum = self.skillData:atproxy(k).fastUpgradeNum
				if self:canLevelUp(v, false) then
					local fastUpgradeNum = v.fastUpgradeNum
					self.tmpSkillPoint:modify(function(oldVal)
						return true, oldVal + fastUpgradeNum
					end)
					local skillGold = getCostGold(v.skillLevel, csv.skill[v.skillId].costID, fastUpgradeNum)
					self.clientGold:modify(function(oldVal)
						return true, oldVal - skillGold
					end)
					local skillLevel = self.skillData:atproxy(k).skillLevel + fastUpgradeNum
					self.skillData:atproxy(k).skillLevel = skillLevel
					self.skillData:atproxy(k).fastUpgradeNum = self:getFastUpgradeNum(skillLevel)
					--self.serverSkillPoint 实为客户端显示的技能点
					if ((self.serverSkillPoint:read() + self.tmpSkillPoint:read()) >= dataEasy.getSkillPointMax(self.roleLv:read())) and
						self.serverSkillPoint:read() < dataEasy.getSkillPointMax(self.roleLv:read()) then
						-- 按住期间技能点恢复到max以上 发送一次
						local num = self.tmpSkillPoint:read()
						gGameApp:requestServer("/game/card/skill/level/up",function (tb)
							self.tmpSkillPoint:modify(function(oldVal)
								return true, oldVal - num
							end)
						end, self.selectDbId, v.skillId, num)
					end
					for i=1,fastUpgradeNum do
						self:upgradeFloatingWord(node, v.skillId)
					end
					local size = node:get("imgIcon"):getContentSize()
					audio.playEffectWithWeekBGM("circle.mp3")
					widget.addAnimationByKey(node:get("imgIcon"), "effect/jineng.skel", nil, "effect", 555)
						:xy(size.width/2, size.height/2)
						:scale(1.3)
				end
			end
			time = time - dt
		end, 0.1, 0, "skillLvUp")

	elseif event.name == "moved" then
		local pos = event
		local deltaX = math.abs(pos.x - self.touchBeganPos.x)
		local deltaY = math.abs(pos.y - self.touchBeganPos.y)
		if deltaX >= ui.TOUCH_MOVE_CANCAE_THRESHOLD or deltaY >= ui.TOUCH_MOVE_CANCAE_THRESHOLD then
			self.notMoved = false
			self:unSchedule("skillLvUp")
		end

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unSchedule("skillLvUp")
		self:canLevelUp(v, true)
		if gGameUI:isConnecting() then
			return
		end
		if self.tmpSkillPoint:read() > 0 then
			gGameApp:requestServer("/game/card/skill/level/up",function (tb)
				self.tmpSkillPoint:set(0)
			end, self.selectDbId, v.skillId, self.tmpSkillPoint)
		else
			if self.notMoved then
				if not self:canLevelUp(v, false) then
					return
				end
				gGameApp:requestServer("/game/card/skill/level/up",function (tb)
					self.tmpSkillPoint:set(0)
				end, self.selectDbId, v.skillId, v.fastUpgradeNum)
				for i=1,v.fastUpgradeNum do
					self:upgradeFloatingWord(node, v.skillId)
				end
				local size = node:get("imgIcon"):getContentSize()
				audio.playEffectWithWeekBGM("circle.mp3")
				widget.addAnimationByKey(node:get("imgIcon"), "effect/jineng.skel", nil, "effect", 555)
					:xy(size.width/2, size.height/2)
					:scale(1.3)
			end
		end
	end
end

function CardSkillView:canLevelUp(v, isShowTip)
	local skillGold = getCostGold(v.skillLevel, csv.skill[v.skillId].costID, v.fastUpgradeNum)
	if v.skillLevel + v.fastUpgradeNum > self.cardLv:read() then
		self:showTip(gLanguageCsv.spriteLevelNotEnough, isShowTip)
		return  false
	end
	if self.serverSkillPoint:read() < v.fastUpgradeNum then
		self:onSkillAddClick(isShowTip)
		return  false
	end
	if self.clientGold:read() < skillGold then
		self:showTip(gLanguageCsv.skillLevelGoldNotEnough, isShowTip)
		return  false
	end
	return true
end

function CardSkillView:showTip(txt, isShowTip)
	if isShowTip then
		gGameUI:showTip(txt)
	end
end

function CardSkillView:upgradeFloatingWord(node, skillId)
	self.floatingWordData = self.floatingWordData or {}
	local floatingWordData = self.floatingWordData
	local data = string.split(csv.skill[skillId].upLvDesc, "|")
	for k,v in pairs(data) do
		if not floatingWordData[skillId] then
			floatingWordData[skillId] = {}
		end
		table.insert(floatingWordData[skillId],v)
	end
	if not self.oldselectDbId then
		self.oldselectDbId = self.selectDbId:read()
	end
	if not self.skillId then
		self.skillId = skillId
	end
	if self.skillId ~= skillId then
		self.skillId = skillId
		self.floatingWordIndex = false
	end
	if not self.floatingWordIndex then
		self.floatingWordIndex = true
		local i = 0
		self:enableSchedule():schedule(function (dt)
			if next(floatingWordData[skillId]) == nil then
				if not tolua.isnull(node) then
					for j=1,4 do
						local panel = node:get("num"..j)
						if panel then
							panel:hide()
						end
					end
				end
				self:unSchedule("upgradeFloatingWord"..skillId)
				self.floatingWordIndex = false

			elseif self.oldselectDbId ~= self.selectDbId:read() then
				self.oldselectDbId = self.selectDbId:read()
				-- 切换精灵时清空飘字
				for k, v in pairs(floatingWordData) do
					floatingWordData[k] = {}
				end
			else
				if tolua.isnull(node) then
					floatingWordData[skillId] = {}
					return
				end
				i = (i < 4) and (i + 1) or 1
				local panel = node:get("num"..i)
				if not panel then
					panel = cc.Label:createWithTTF(floatingWordData[skillId][1], ui.FONT_PATH, 50)
						:align(cc.p(0, 0.5), 300, 80)
						:addTo(node, 4000, "num"..i)
					text.addEffect(panel, {color=cc.c4b(92, 153, 113,255)})
				end
				panel:text(floatingWordData[skillId][1]):xy(300, 80):show():opacity(255)
				transition.executeSequence(panel)
					:moveBy(0.4, 0, 100)
					:fadeOut(0.3)
					:done()
				table.remove(floatingWordData[skillId],1)
			end
		end, 0.2, 0.2, "upgradeFloatingWord"..skillId)
	end
end

function CardSkillView:onSkillAddClick(isShowTip)
	if not isShowTip then
		return
	end
	gGameUI:stackUI("city.card.skill_buypoint", nil, nil, self:createHandler("getBuyInfoCb"))
end

function CardSkillView:getBuyInfoCb()
	if self.serverSkillPoint:read() >= dataEasy.getSkillPointMax(self.roleLv:read()) then
		gGameUI:showTip(gLanguageCsv.skillPointBuyNoNeed)
		return
	end
	gGameApp:requestServer("/game/role/skill/point/buy",function (tb)
		gGameUI:showTip(gLanguageCsv.hasBuy)
	end)
end

function CardSkillView:onItemTipClick(list, k, v)
	gGameUI:stackUI("common.skill_detail", nil, {clickClose = true, dispatchNodes = list}, {
		skillId = v.skillId,
		skillLevel = v.skillLevel,
		cardId = self.cardId:read(),
		star = self.star:read(),
		isZawake = dataEasy.isZawakeSkill(v.skillId, self.zawakeSkills:read())
	})
end

return CardSkillView
