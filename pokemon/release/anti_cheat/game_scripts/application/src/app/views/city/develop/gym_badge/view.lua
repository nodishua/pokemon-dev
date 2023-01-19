-- @Date:   2020-08-3
-- @Desc: 徽章界面
local ViewBase = cc.load("mvc").ViewBase
local gymBadgeView = class("gymBadgeView", ViewBase)

local posTable = {
	[4] ={cc.p(625, 757), cc.p(739, 789), cc.p(748, 566), cc.p(710, 413), cc.p(559, 321), cc.p(456, 519), cc.p(606, 577)},
	[5] ={cc.p(494, 989), cc.p(514, 906), cc.p(375, 773), cc.p(426, 573), cc.p(319, 537), cc.p(226, 402), cc.p(197, 683), cc.p(312, 870)},
	[2] ={cc.p(739, 784), cc.p(834, 924), cc.p(1005, 678), cc.p(900, 629), cc.p(762, 629)},
	[1] ={cc.p(506, 980), cc.p(654, 998), cc.p(826, 926), cc.p(738, 796), cc.p(622, 766), cc.p(536, 838)},
	[3] ={cc.p(748, 499), cc.p(872, 391), cc.p(890, 296), cc.p(740, 195), cc.p(510, 186), cc.p(555, 314), cc.p(717, 404)},
	[6] ={cc.p(512, 923), cc.p(528, 836), cc.p(618, 757), cc.p(602, 584), cc.p(447, 525), cc.p(382, 775)},
	[8] ={cc.p(764, 625), cc.p(906, 620), cc.p(1007, 674), cc.p(996, 478), cc.p(897, 305), cc.p(877, 388),cc.p(748, 501)},
	[7] ={cc.p(427, 566), cc.p(550, 316), cc.p(494, 186), cc.p(332, 269), cc.p(229, 402), cc.p(325, 532)},
}

local effectTable = {
	[4] = {effectName  = "huo_effect", loopName = "huo_loop", x = 603, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[5] = {effectName  = "long_effect", loopName = "long_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[2] = {effectName  = "shui_effect", loopName = "shui_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[1] = {effectName  = "yan_effect", loopName = "yan_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[3] = {effectName  = "cao_effect", loopName = "cao_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[6] = {effectName  = "e_effect", loopName = "e_loop", x = 597, y = 630, scale = 2, point = cc.p(0.5, 0.5)},
	[8] = {effectName  = "yao_effect", loopName = "yao_loop", x = 599, y = 632, scale = 2, point = cc.p(0.5, 0.5)},
	[7] = {effectName  = "du_effect", loopName = "du_loop", x = 597, y = 629, scale = 2, point = cc.p(0, 0)},
}

gymBadgeView.RESOURCE_FILENAME = "gym_badge.json"
gymBadgeView.RESOURCE_BINDING = {
	["centerPanel"] = "centerPanel",
	-- ["centerPanel.bgBtn"] = "badge",
	["bg"] = "bg",
	["rule"] = "rule",
	["centerPanel.bg"] = "badge",
	["gymBtn"] = {
		varname = "gymBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGym")}
		},
	},
	["rule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		},
	},
	["rule.text"] = {
		binds = {
			event = "effect",
			data = {outline={color = cc.c4b(90, 84, 91, 255), size = 4}},
		}
	},
}

function gymBadgeView:onCreate()
	self:initModel()
	adapt.centerWithScreen("left", "right", nil, {
		{self.rule, "pos", "left"},
		{self.gymBtn, "pos", "right"},
	})
	--是否在当前界面
	self.isView = idler.new(true)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.badgeTitle, subTitle = "GYMBADGE"})
	for i = 1, 8 do
		self.centerPanel:get("name"..i):setColor(cc.c3b(128, 128, 128))
	end
	--之前徽章开启状态
	self.lastBadge = userDefault.getForeverLocalKey("gymBadge", {})
	userDefault.setForeverLocalKey("gymBadge")
	-- 现在徽章开启的状态
	self.nowBadge = {}
	--徽章开启的状态
	local hasData = false
	idlereasy.any({self.badges, self.isView}, function(_, badges, isView)
		for k, v in orderCsvPairs(csv.gym_badge.badge) do
			if v.preBadgeID then
				local preBadgeData = badges and badges[v.preBadgeID] or {}

				if v.preBadgeType == 1 then
					local awake = preBadgeData.awake or 0
					if awake >= v.preLevel then
						self.nowBadge[k] = 1
					end
				else
					local index = csv.gym_badge.badge[v.preBadgeID].talentIDs[6]
					local talents = badges[v.preBadgeID] and badges[v.preBadgeID].talents
					local talent = talents and talents[index] or 0
					if talent >= v.preLevel then
						self.nowBadge[k] = 1
					end
				end
			else
				--没有前置
				self.nowBadge[k] = 1
				if badges[k] then
					hasData = true
				end
			end
		end
	end)
	if hasData then
		self.lastBadge = clone(self.nowBadge)
	end

	self:playLoopEff()
	idlereasy.when(self.isView, function(_, isView)
		if isView then
			self:playEffect()
		end
	end)
	self.centerPanel:onTouch(functools.partial(self.showBadge, self))
end

function gymBadgeView:initModel()
	self.badges = gGameModel.role:getIdler("badges")
end

function gymBadgeView:onGym()
	jumpEasy.jumpTo("gymChallenge")
end

function gymBadgeView:showBadge(event)
	local pos = event.target:convertToNodeSpace(event)
	if event.name == "began" then
		self.touchIndex = dataEasy.checkInRect(posTable, pos)
		if self.touchIndex then
			if self.centerPanel:getChildByName("spine"..self.touchIndex) then
				self.centerPanel:getChildByName("spine"..self.touchIndex):scale(1.9)
			else
				self.centerPanel:get("name"..self.touchIndex):scale(1.9)
			end
		end
	elseif (event.name == "ended" or event.name == "cancelled") then
		if self.touchIndex == nil then
			return
		end
		if self.centerPanel:getChildByName("spine"..self.touchIndex) then
			self.centerPanel:getChildByName("spine"..self.touchIndex):scale(2)
		else
			self.centerPanel:get("name"..self.touchIndex):scale(2)
		end
		if self.touchIndex == dataEasy.checkInRect(posTable, pos) then
			if self.nowBadge[self.touchIndex] == 1 then
				self.isView:set(false)
				gGameUI:stackUI("city.develop.gym_badge.talent", nil, {full = true}, {badgeNumb = self.touchIndex, isView = self.isView})
			else
				self:showUnlockTips(self.touchIndex)
			end
		end
	end
end

function gymBadgeView:showUnlockTips(badgeNumb)
	local csvBadge = csv.gym_badge.badge
	local preBadgeID = csvBadge[badgeNumb].preBadgeID
	local preBadgeType = csvBadge[badgeNumb].preBadgeType
	if preBadgeType == 1 then
		gGameUI:showTip(string.format(gLanguageCsv.noOpenPleaseToGymView1, csvBadge[preBadgeID].name,csvBadge[badgeNumb].preLevel))
	else
		gGameUI:showTip(string.format(gLanguageCsv.noOpenPleaseToGymView2, csvBadge[preBadgeID].name,csvBadge[badgeNumb].preLevel))
	end
end

-- 显示规则文本
function gymBadgeView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function gymBadgeView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.badgeExplain)
		end),
		c.noteText(111001, 111011),
	}
	return context
end
-- 播放解锁动画
function gymBadgeView:playEffect()
	-- 动画过程中限制进入徽章升级界面(音效问题)，点击加速播放
	if not self.maskPanel then
		self.maskPanel = ccui.Layout:create()
			:size(display.sizeInView)
			:x(-display.uiOrigin.x)
			:addTo(self, 99999, "maskPanel")
		self.maskPanel:setTouchEnabled(true)
		self.maskPanel:onClick(function()
			self:stopAllActions()
			self:handlerShowItem(0.1)
		end)
	end
	self.maskPanel:show()
	self.aniIndex = 1
	self.aniData = {}
	for k, v in  ipairs(csv.gym_badge.badge) do
		if self.lastBadge[k] ~= 1 and self.nowBadge[k] == 1 then
			table.insert(self.aniData, {id = k})
		end
	end
	self:handlerShowItem(2)
	userDefault.setForeverLocalKey("gymBadge", self.nowBadge)
end

function gymBadgeView:handlerShowItem(aniDelay)
	local index = self.aniIndex
	local data = self.aniData[index]
	if not data then
		self.maskPanel:hide()
		return
	end
	local delay = index == 1 and 0.1 or aniDelay
	performWithDelay(self, function()
		local k = data.id
		self.lastBadge[k] = 1
		local x, y = self.centerPanel:get("name"..k):xy()
		local spine = widget.addAnimationByKey(self.centerPanel, "daoguanhuizhang/dghz.skel", "spine"..k, effectTable[k].effectName, 100)
			:xy(x,y)
			:scale(2)
		spine:setSpriteEventHandler(function(event, eventArgs)
			spine:setSpriteEventHandler(nil, sp.EventType.ANIMATION_COMPLETE)
			spine:play(effectTable[k].loopName)
			self.centerPanel:get("name"..k):hide()
		end, sp.EventType.ANIMATION_COMPLETE)

		self.aniIndex = self.aniIndex + 1
		self:handlerShowItem(aniDelay)
	end, delay)
end

--播放已解锁循环动画
function gymBadgeView:playLoopEff()
	for k, v in  ipairs(csv.gym_badge.badge) do
		if self.lastBadge[k] == 1 then
			local x, y = self.centerPanel:get("name"..k):xy()
			local spine = widget.addAnimationByKey(self.centerPanel, "daoguanhuizhang/dghz.skel", "spine"..k, effectTable[k].loopName, 100)
				:xy(x,y)
				:scale(2)
			self.centerPanel:get("name"..k):hide()
		end
	end
end

function gymBadgeView:onCleanup()
	if self.maskPanel then
		self.maskPanel:removeFromParent()
		self.maskPanel = nil
	end
	ViewBase.onCleanup(self)
end

return gymBadgeView