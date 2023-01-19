-- @date: 2018-11-6
-- @desc: 聚宝(点金)界面

local effectScale = {
	[1] = 0.38,
	[2] = 0.4,
	[3] = 0.5,
	[4] = 0.54,
	[5] = 0.58,
	[6] = 0.6,
}

local MonthCardView = require "app.views.city.activity.month_card"
local ViewBase = cc.load("mvc").ViewBase
local GainGoldView = class("GainGoldView", Dialog)

GainGoldView.RESOURCE_FILENAME = "common_gain_gold.json"
GainGoldView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["numPanel.doublePanel"] = "doublePanel",
	["numPanel.bg"] = "numPanelBg",
	["numPanel.info"] = "numPanelInfo",
	["numPanel.num1"] = "gainTimes1",
	["numPanel.num2"] = "gainTimes2",
	["goldPanel.bg"] = "goldPanelBg",
	["goldPanel.info"] = "goldPanelInfo",
	["goldPanel.num"] = "gainNum",
	["goldPanel.icon"] = "gainIcon",
	["refreshBg"]= "refreshBg",
	["refresh1"] = "refresh1",
	["refresh2"] = "refresh2",
	["refresh3"] = "refresh3",
	["refreshIcon"] = "refreshIcon",
	["boxPanel"] = "boxPanel",
	["boxPanel.bar"] = "boxBar",
	["onePanel"] = "onePanel",
	["onePanel.free"] = "free",
	["onePanel.icon"] = "icon",
	["onePanel.price"] = "price",
	["onePanel.priceNote"] = "priceNote",
	["tenPanel"] = "tenPanel",
	["onePanel.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onGainClick(1)
			end)}
		},
	},
	["tenPanel.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onGainClick(10)
			end)}
		},
	},
	["onePanel.btn.text"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["tenPanel.btn.text"] = {
		varname = "tenBtnText",
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["goldPanel"] = "goldPanel",
}

function GainGoldView:onCreate()
	self:initModel()
	self.refresh2:text(time.getRefreshHour())
	adapt.oneLinePos(self.refresh3, {self.refresh2, self.refresh1,self.refreshIcon},{cc.p(10,0), cc.p(10,0), cc.p(10,0)}, "right")
	self.refreshBg:width(self.refresh3:width() + self.refresh2:width() + self.refresh1:width() + self.refreshIcon:width() + 100)
	-- 如果vip达到上限，且今日点金次数已用完，则返回-1
	local progress = {17, 33, 53, 76}
	self.leftTimes = idlereasy.any({self.vipLevel, self.lianjinTimes, self.trainerLevel, self.trainerSkills},
	function(_, vipLevel, lianjinTimes, trainerLevel, skills)
		local times = gVipCsv[vipLevel].lianJinTimes
		times = times + (MonthCardView.getPrivilegeAddition("lianjinFreeTimes") or 0)
			+ dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.LianjinBuyTimes)
			+ dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.LianjinFreeTimes)
		self:refreshNumPanel(lianjinTimes, times)
		local leftTimes = times - lianjinTimes
		if leftTimes == 0 and vipLevel >= game.VIP_LIMIT then
			leftTimes = -1
		end
		-- 进度条显示
		local data = {}
		for num, _ in orderCsvPairs(gVipCsv[vipLevel].lianJinGift) do
			table.insert(data, num)
		end
		local percent = mathEasy.showProgress(progress, data, lianjinTimes)
		if not self.percent then
			self.percent = clone(percent)
			self.boxBar:setPercent(self.percent)
		else
			local interval = 0.01
			self:enableSchedule():schedule(function ()
				if interval > 0.0005 then
					interval = interval - 0.0005
				end
				self.percent = self.percent + 1
				self.boxBar:setPercent(math.min(percent, self.percent))
				if self.percent >= percent then
					self:unSchedule("GainGoldViewPercent")
				end
			end, interval, 0, "GainGoldViewPercent")
		end
		if self.goldPanel:get("privilege") then
			self.goldPanel:get("privilege"):removeSelf()
		end
		uiEasy.setPrivilegeRichText(game.PRIVILEGE_TYPE.LianjinDropRate, self.goldPanel, gLanguageCsv.gold, cc.p(20, 155), true)

		return true, leftTimes
	end)


	-- 点金次数变动时的处理
	-- lianjinFreeTimes 还原成监听项处理
	idlereasy.any({self.lianjinTimes, self.lianjinFreeTimes, self.leftTimes}, function(_, lianjinTimes, lianjinFreeTimes, leftTimes)
		-- local lianjinFreeTimes = self.lianjinFreeTimes:read()
		lianjinTimes = math.max(lianjinTimes - lianjinFreeTimes, 0)
		local lianjinFreeTimesTotal = (MonthCardView.getPrivilegeAddition("lianjinFreeTimes") or 0)
			+ dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.LianjinFreeTimes)
		local costSeq = gCostCsv.lianjin_cost
		local times = math.min(lianjinTimes+1, table.length(costSeq))
		self.cost = costSeq[times]
		if lianjinFreeTimes < lianjinFreeTimesTotal then
			self.cost = 0
		end
		local tenCost = 0
		local tenTimes = cc.clampf(leftTimes, 1, 10)
		local tenCostTime = tenTimes - math.max(lianjinFreeTimesTotal - lianjinFreeTimes, 0)
		for i = 1, tenCostTime do
			local n = math.min(lianjinTimes+i, table.length(costSeq))
			tenCost = tenCost + costSeq[n]
		end
		self.tenCost = tenCost
		self.free:visible(self.cost <= 0)
		self.icon:visible(self.cost > 0)
		self.price:visible(self.cost > 0):text(self.cost)
		self.priceNote:visible(self.cost > 0)
		self.tenPanel:get("price"):text(tenCost)
		self.tenBtnText:text(string.format(gLanguageCsv.gainGoldMoreTimes, tenTimes))
		adapt.oneLineCenterPos(cc.p(self.onePanel:size().width/2, self.price:y()), {self.priceNote, self.price, self.icon}, cc.p(15, 0))
		local childs = self.tenPanel:multiget("priceNote", "price", "icon")
		adapt.oneLineCenterPos(cc.p(self.tenPanel:size().width/2, childs.price:y()), {childs.priceNote, childs.price, childs.icon}, cc.p(15, 0))
	end)

	-- 显示下次获得的金币数量
	-- onegold = level.lianjinGold * 次数倍数
	-- multiple = 和vip相关的随机得到 + 月卡倍数 + 1（双倍情况）
	-- total = onegold * multiple
	idlereasy.any({self.lianjinTimes, self.lianjinFreeTimes, self.roleLevel}, function(_, lianjinTimes, lianjinFreeTimes, roleLevel)
		-- local lianjinFreeTimes = self.lianjinFreeTimes:read()
		lianjinTimes = math.max(lianjinTimes - lianjinFreeTimes, 0)
		local lianjinFreeTimesTotal = (MonthCardView.getPrivilegeAddition("lianjinFreeTimes") or 0)
			+ dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.LianjinFreeTimes)
		local costSeq = gCostCsv.lianjin_gold_rate
		local times = math.min(lianjinTimes + 1, table.length(costSeq))
		if lianjinFreeTimes < lianjinFreeTimesTotal then
			times = 1
		end
		local onegold = gRoleLevelCsv[roleLevel].lianJinGold * costSeq[times]
		local rate = MonthCardView.getPrivilegeAddition("lianjinRate")
		local multiple = 1
		if rate then
			multiple = multiple + rate
		end

		local total = math.floor(onegold * multiple)
		self.gainNum:text("+" .. total)
		adapt.oneLinePos(self.goldPanelInfo, {self.gainNum, self.gainIcon}, {cc.p(10, 0), cc.p(10, 0)})
		self.goldPanelBg:width(self.goldPanelInfo:width() + self.gainNum:width() + self.gainIcon:width() + 85)
	end)

	-- 箱子状态处理 lianjinGifts 1:表示可领，0:表示已领，不存在 key 表示不可领取
	idlereasy.any({self.vipLevel, self.lianjinGifts}, function(_, vipLevel, lianjinGifts)
		local idx = 0
		for num, gift in orderCsvPairs(gVipCsv[vipLevel].lianJinGift) do
			idx = idx + 1
			self.boxPanel:get("num" .. idx):text(num)
			text.addEffect(self.boxPanel:get("num" .. idx), {outline={color=ui.COLORS.NORMAL.DEFAULT}})
			local state = lianjinGifts[num]
			local box = self.boxPanel:get("box" .. idx)
				:texture(string.format("other/gain_gold/icon_box%s%d.png", state == 0 and "_open" or "", idx))

			if state == 1 then
				local effect = widget.addAnimationByKey(self.boxPanel, "effect/jiedianjiangli.skel", "gain_gold_box_effect"..idx , "effect_loop", box:z() - 1)
				local size = box:size()
				effect:scale(effectScale[idx])
					:x(box:x())
					:y(box:y() - 40)
				box.effectBox = effect
			else
				if box.effectBox then
					box.effectBox:hide()
					box.effectBox:removeFromParent()
					box.effectBox = nil
				end
			end

			uiEasy.addVibrateToNode(self, box, state == 1)

			bind.touch(self, box, {methods = {ended = functools.partial(self.onBoxClick, self, state, num, box)}})
		end
	end)

	Dialog.onCreate(self)
end

function GainGoldView:refreshNumPanel(lianjinTimes, times)
	self.gainTimes1:text(lianjinTimes)
	local color = lianjinTimes < times and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.DEFAULT
	text.addEffect(self.gainTimes1, {color = color})
	self.gainTimes2:text("/" .. times)
	adapt.oneLinePos(self.numPanelInfo, {self.gainTimes1, self.gainTimes2}, cc.p(5, 0))

	local isDouble, paramMaps = dataEasy.isDoubleHuodong("buyGold")

	self.doublePanel:visible(isDouble)
	self.numPanelBg:height(isDouble and 168 or 114)

	if matchLanguage({"en"}) then
		self.numPanelBg:width(isDouble and 375 or 360)
	elseif matchLanguage({"tw"}) then
		self.numPanelBg:width(isDouble and 390 or 310)
	elseif matchLanguage({"kr"}) then
		self.numPanelBg:width(isDouble and 460 or 400)
	end

	if isDouble then
		local text1 = self.doublePanel:get("text1")
		local text2 = self.doublePanel:get("text2")
		local text3 = self.doublePanel:get("text3")
		local maxTimes = paramMaps[1].count or 1 -- 只读取第一个
		local showCount = math.max(maxTimes - lianjinTimes, 0)
		color = showCount == 0 and ui.COLORS.NORMAL.ALERT_ORANGE or ui.COLORS.NORMAL.FRIEND_GREEN
		text.addEffect(text2, {color = color})
		text2:text(showCount)
		text3:text(string.format("/%s)", maxTimes))
		adapt.oneLinePos(text1, {text2, text3}, cc.p(0,0))
	end
end

function GainGoldView:initModel()
	self.rmb = gGameModel.role:getIdler("rmb")
	self.roleLevel = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.lianjinTimes = gGameModel.daily_record:getIdler("lianjin_times")
	self.lianjinFreeTimes = gGameModel.daily_record:getIdler("lianjin_free_times")
	self.lianjinGifts = gGameModel.daily_record:getIdler("lianjin_gifts")
	self.trainerLevel = gGameModel.role:getIdler("trainer_level")
	self.trainerSkills = gGameModel.role:getIdler("trainer_skills")
end

function GainGoldView:onGainClick(n)
	idlereasy.do_(function(leftTimes, rmb)
		if leftTimes == -1 then
			-- 已上限，明日再来
			gGameUI:showTip(gLanguageCsv.commonVipMax, gLanguageCsv.gainGold)
		elseif leftTimes == 0 then
			-- 已上限，提升vip
			uiEasy.showDialog("vip", {titleName = gLanguageCsv.gainGold})
		elseif self.cost > 0 and rmb < self.cost then
			uiEasy.showDialog("rmb")
		else
			local function gain_gold()
				gGameApp:requestServer("/game/role/lianjin", function(tb)
					gGameUI:stackUI("common.gain_gold_display", nil, nil, tb.view, n)
				end, n)
			end
			if (n == 1 and self.cost > 0) or n == 10 then
				local count = n == 1 and self.cost or self.tenCost
				dataEasy.sureUsingDiamonds(gain_gold, count)
			else
				gain_gold()
			end
		end
	end, self.leftTimes, self.rmb)
end

function GainGoldView:onBoxClick(state, num, box)
	if state == 1 then
		local showOver = {false}
		gGameApp:requestServerCustom("/game/role/lianjin/total_award")
			:params(num)
			:onResponse(function (tb)
				uiEasy.setBoxEffect(box, 1, function()
					showOver[1] = true
				end, -30, 20)
			end)
			:wait(showOver)
			:doit(function (tb)
				gGameUI:showGainDisplay(tb)
			end)
	elseif state == 0 then
		gGameUI:showBoxDetail({
			data = gVipCsv[self.vipLevel:read()].lianJinGift[num],
			content = "",
			state = 0
		})
	else
		gGameUI:showBoxDetail({
			data = gVipCsv[self.vipLevel:read()].lianJinGift[num],
			content = string.format(gLanguageCsv.canGetArriveAtJubaoNumber, num),
			state = 1
		})
	end
end

return GainGoldView
