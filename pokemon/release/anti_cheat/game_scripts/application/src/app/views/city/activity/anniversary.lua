-- @date 2021-3-17
-- @desc 周年庆整合入口

local ActivityAnniversaryView = class("ActivityAnniversaryView", cc.load("mvc").ViewBase)

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE

local function setLabel(ui, delta)
	local ret = time.getCutDown(delta, true, true)
	if matchLanguage({"en"}) then
		adapt.setTextScaleWithWidth(ui, gLanguageCsv.activityTime .. ret.daystr.." "..ret.hourstr.. " " ..ret.minstr,600)
	else
		adapt.setTextScaleWithWidth(ui, gLanguageCsv.activityTime .. ret.date_str, 450)
	end
end

ActivityAnniversaryView.RESOURCE_FILENAME = "activity_anniversary.json"
ActivityAnniversaryView.RESOURCE_BINDING = {
	["braveChallenge"] = "braveChallenge",
	["horseRace"] = "horseRace",
	["signIn"] = "signIn",
	["shop"] = "shop",
	["gridWalk"] = "gridWalk",
	["countdownPanel"] = "countdownPanel",
	["countdownPanel.time"] = "countdown",
}
ActivityAnniversaryView.RESOURCE_STYLES = {
	full = true,
}

function ActivityAnniversaryView:onCreate(params)
	self:createTitle()
	self:enableSchedule()
	self.isRunning = true
	local effect = widget.addAnimation(self:getResourceNode(), "activityheji/znqrk.skel", "effect_ruchang", 0)
		:scale(2)
		:alignCenter(display.sizeInView)
	effect:addPlay("effect_loop")

	self:createTable()

	local loginGiftData = nil
	for _, v in ipairs(params) do
		local cfg = csv.yunying.yyhuodong[v.id]
		if self.tb[cfg.type] then
			self.tb[cfg.type].data = v

		-- 登录奖励
		elseif cfg.type == YY_TYPE.LoginGift then
			local countdown = 0
			local id = v.id
			local yyEndtime = gGameModel.role:read("yy_endtime")
			if yyEndtime[id] then
				countdown = yyEndtime[id] - time.getTime()
			end
			if countdown > 0 then
				-- 每日奖励数据
				local loginwealData = {}
				local huodongID = csv.yunying.yyhuodong[id].huodongID
				for k, v in csvPairs(csv.yunying.loginweal) do
					if v.huodongID == huodongID then
						loginwealData[v.daySum] = {award = v.award, id = k}
					end
				end
				local yyhuodongs = gGameModel.role:read("yyhuodongs")
				local yydata = yyhuodongs[id] or {}
				local stamps = yydata.stamps or {}
				if loginwealData[1] and stamps[loginwealData[1].id] == 1 then
					loginGiftData = {
						data = loginwealData[1].award,
						cb = function()
							gGameApp:requestServer("/game/yy/award/get", function(tb)
								gGameUI:showGainDisplay(tb)
							end, id, loginwealData[1].id)
						end,
					}
				end
			end
		end
	end
	self:refreshPanel()
	for k, v in pairs(self.tb) do
		v.node:hide()
	end
	self.countdownPanel:hide()
	effect:setTimeScale(0)
	performWithDelay(self, function()
		effect:setTimeScale(1)
	end, 1/60)
	performWithDelay(self, function()
		for k, v in pairs(self.tb) do
			v.node:show()
		end
		if loginGiftData then
			gGameUI:stackUI("city.activity.anniversary_login_gift", nil, {blackLayer = true}, loginGiftData)
		end
	end, 20/30)
	performWithDelay(self, function()
		self.countdownPanel:scaleY(0.3):show()
		transition.executeSequence(self.countdownPanel)
			:easeBegin("ELASTICOUT")
				:scaleTo(2, 1, 1)
			:easeEnd()
			:done()
	end, 1.3)
end

function ActivityAnniversaryView:refreshPanel()
	local maxDelta
	local minDelta
	for k, v in pairs(self.tb) do
		local node = v.node
		local icon = node:get("icon")
		if not v.iconPos then
			v.iconPos = cc.p(icon:xy())
		end
		icon:stopAllActions()
		icon:xy(v.iconPos)
		icon:removeChildByName("lock")
		local lock = ccui.ImageView:create("activity/anniversary/logo_lock.png")
			:anchorPoint(0.5, 0.5)
			:scale(0.5)
			:xy(v.redHintPos.x - 10, v.redHintPos.y - 10)
			:addTo(icon, 2, "icon")
			:hide()

		if v.data then
			local countdown = 0
			local id = v.data.id
			local yyEndtime = gGameModel.role:read("yy_endtime")
			if yyEndtime[id] then
				countdown = yyEndtime[id] - time.getTime()
			end
			if countdown <= 0 then
				v.isOver = true
				lock:show()
			else
				minDelta = not minDelta and countdown or math.min(minDelta, countdown)
				maxDelta = not maxDelta and countdown or math.max(maxDelta, countdown)
				local x, y = v.iconPos.x, v.iconPos.y
				self:iconRunAction(icon, x, y)
				if v.data.redHint then
					v.data.redHint.props.onNode = function(node)
						node:scale(0.5)
							:xy(180, 100)
						if v.redHintPos then
							node:xy(v.redHintPos)
						end
					end
					bind.extend(self, icon, v.data.redHint)
				end
			end
		else
			lock:show()
		end
		self:bindClick(node, v.data, v.isOver)
	end
	self:unSchedule(1)
	if not maxDelta then
		self.countdown:text(gLanguageCsv.activityOver)
	else
		setLabel(self.countdown, maxDelta)
		self:schedule(function()
			if maxDelta <= 0 then
				self:refreshPanel()
				return false
			end
			setLabel(self.countdown, maxDelta)
			maxDelta = maxDelta - 1
		end, 1, 0, 1)
		performWithDelay(self.countdown, function()
			self:refreshPanel()
		end, minDelta)
	end
end

function ActivityAnniversaryView:createTitle()
	local topUI = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.anniversary, subTitle = "ANNIVERSARY"})
end

function ActivityAnniversaryView:iconRunAction(icon, x, y)
	if self.isRunning then
		local time = 3
		local dy = 10
		local sequence = cc.Sequence:create(
			cc.MoveTo:create(time/4, cc.p(x, y + dy)),
			cc.MoveTo:create(time/2, cc.p(x, y - dy)),
			cc.MoveTo:create(time/4, cc.p(x, y))
		)
		icon:runAction(cc.RepeatForever:create(sequence))
	end
end

function ActivityAnniversaryView:bindClick(node, data, isOver)
	bind.click(self, node, {method = function()
		if data then
			if isOver then
				gGameUI:showTip(gLanguageCsv.activityOver)
			else
				self:onItemClick(data)
			end
		else
			gGameUI:showTip(gLanguageCsv.huodongNoOpen)
		end
	end})
end

function ActivityAnniversaryView:createTable()
	self.tb = {
		[YY_TYPE.gridWalk] = {
			node = self.gridWalk,
			redHintPos = cc.p(155, 82),
		},
		[YY_TYPE.braveChallenge] = {
			node = self.braveChallenge,
			redHintPos = cc.p(160, 86),
		},
		[YY_TYPE.horseRace] = {
			node = self.horseRace,
			redHintPos = cc.p(170, 88),
		},
		[YY_TYPE.itemBuy2] = {
			node = self.shop,
			redHintPos = cc.p(154, 78),
		},
		[YY_TYPE.playPassport] = {
			node = self.signIn,
			redHintPos = cc.p(162, 74),
		},
	}
end

function ActivityAnniversaryView:onItemClick(v)
	if v.func then
		v.func(function(...)
			local params = clone(v.params or {})
			for _,v in ipairs({...}) do
				table.insert(params, v)
			end
			gGameUI:stackUI(v.viewName, nil, v.styles, unpack(params))
		end, v.params or {})

	elseif v.viewName then
		gGameUI:stackUI(v.viewName, nil, v.styles, unpack(v.params or {}))
	end
end

return ActivityAnniversaryView