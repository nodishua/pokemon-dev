-- @date 2020-10-10
-- @desc 限时碎片转换

local ActivityView = require "app.views.city.activity.view"
local ActivityQualityExchangeFragmentView = class("ActivityQualityExchangeFragmentView", cc.load("mvc").ViewBase)

ActivityQualityExchangeFragmentView.RESOURCE_FILENAME = "activity_quality_exchange_fragment.json"
ActivityQualityExchangeFragmentView.RESOURCE_BINDING = {
	["rulePanel"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onRuleClick"),
		},
	},
	["detailPanel"] = {
		varname = "detailPanel",
		binds = {
			event = "click",
			method = bindHelper.self("onDetailPanelClick"),
		},
	},
	["descPanel"] = "descPanel",
	["leftPanel"] = "leftPanel",
	["rightPanel"] = "rightPanel",
	["sliderPanel"] = "sliderPanel",
	["sliderPanel.sub"] = {
		varname = "sliderSubBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["sliderPanel.add"] = {
		varname = "sliderAddBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["costPanel"] = "costPanel",
	["leftPanel.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLeftBtnClick")}
		},
	},
	["rightPanel.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRightBtnClick")}
		},
	},
	["btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnClick")}
		},
	},
	["btn.label"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["countdownText"] = "countdownText",
	["countdown"] = "countdown",
}

function ActivityQualityExchangeFragmentView:onCreate(activityId)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.qualityExchangeFragment, subTitle = "FRAGMENT EXCHANGE"})
	self.detailPanel:get("bg"):width(self.detailPanel:get("tip"):width() + 48)
	self:enableSchedule()

	self.bgEffect = widget.addAnimation(self:getResourceNode(), "effect/zhuanhuanzhuangzhi.skel", "right_loop", 1)
		:alignCenter(display.sizeInView)
		:scale(2)

	self.activityId = activityId
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.num = idler.new(0)
	self.maxNum = 0
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID

	self.datas = {} -- 道具id 对应 quality = {csvId}
	self.qualityData = {}
	self.detailItems = {} -- 可转换道具预览
	for k, v in orderCsvPairs(csv.yunying.qualityexchange) do
		if v.huodongID == huodongID then
			for idx, data in orderCsvPairs(v.items) do
				local key, num = next(data)
				table.insert(self.detailItems, {key = key})
				if not self.datas[key] then
					self.datas[key] = {}
				end
				self.datas[key][v.quality] = {csvId = k, cfg = v, key = key, num = num, idx = idx, rmb = v.costMap.rmb or 0}
			end
			self.qualityData[v.quality] = {leftTimes = 0}
		end
	end
	table.sort(self.detailItems, dataEasy.sortItemCmp)

	idlereasy.any({self.yyhuodongs, self.vipLevel}, function(_, yyhuodongs, vipLevel)
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		-- 可分解次数 = 活动表基础次数 + vip表对应品质的等级特权次数
		local vipCfg = gVipCsv[vipLevel]
		local leftTimes = {}
		for k, v in csvPairs(yyCfg.paramMap.quality) do
			table.insert(leftTimes, {quality = k, leftTimes = v + (vipCfg.fragExchangeTimes[k] or 0) - (stamps[k] or 0)})
		end
		table.sort(leftTimes, function(a, b)
			return a.quality > b.quality
		end)

		local strs = {}
		for _, v in ipairs(leftTimes) do
			if self.qualityData[v.quality] then
				self.qualityData[v.quality].leftTimes = v.leftTimes
			end
			table.insert(strs, {str = string.format(" #L00100010##LOC0xFFFCED##C0x%s#%s #L10##C0x5B545B#%s:#L10#%s%d#L10##C0x5B545B#%s", string.sub(ui.QUALITYCOLOR[v.quality], 5, 10),
				ui.RARITY_TEXT[v.quality - 2], gLanguageCsv.fragment, v.leftTimes > 0 and "#C0x60C456#" or "#C0xF13B54#", v.leftTimes, gLanguageCsv.times)})
		end
		beauty.textScroll({
			list = self.descPanel:get("list"),
			strs = strs,
			isRich = true,
			fontSize = 30,
			margin = 30,
		})
	end)

	self.leftId = idler.new()
	self.rightId = idler.new()
	idlereasy.any({self.leftId, self.rightId, self.num, self.rmb}, function(_, leftId, rightId, num, rmb)
		self:getSelectData()
		self.costPanel:hide()
		self.maxNum = 0
		if self.selectData then
			if num > 0 then
				local childs = self.costPanel:multiget("txt", "num", "icon")
				local cost = self.selectData.rmb * num
				childs.num:text(cost)
				text.addEffect(childs.num, {color = rmb >= cost and cc.c4b(249, 248, 200, 255) or ui.COLORS.NORMAL.RED})
				adapt.oneLineCenterPos(cc.p(200, 30), {childs.txt, childs.num, childs.icon}, cc.p(10, 0))
				self.costPanel:show()
			end

			local cfg = dataEasy.getCfgByKey(leftId)
			local hasNum = dataEasy.getNumByKey(leftId)
			self.maxNum = math.min(math.floor(hasNum/self.selectData.cfg.count), self.qualityData[cfg.quality].leftTimes)
		end
		self.sliderPanel:get("num"):text(num .. "/" .. self.maxNum)
		if num < 1 or num >= self.maxNum then
			self:unScheduleAll()
		end

		-- 非拖动时才设置进度
		if not self.sliderPanel:get("slider"):isHighlighted() then
			local percent = self.maxNum == 0 and 0 or num / self.maxNum
			self.sliderPanel:get("slider"):setPercent(percent * 100)
		end

		if not rightId then
			self:refreshPanel(1, false)
			self:refreshPanel(2, true)
			self:playBgEffect("right_loop")

		elseif not leftId then
			self:refreshPanel(1, true)
			self:refreshPanel(2, true, rightId)
			self:playBgEffect("left_loop")
		else
			self:refreshPanel(1, true, leftId)
			self:refreshPanel(2, true, rightId)
			self:playBgEffect("standby_loop")
		end
	end)
	self.sliderPanel:get("slider"):addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local num = cc.clampf(math.ceil(self.maxNum * percent * 0.01), 0, self.maxNum)
		self.num:set(num)
	end)

	local pos = cc.p(self.countdown:xy())
	ActivityView.setCountdown(self, activityId, self.countdownText, self.countdown, {labelChangeCb = function()
		adapt.oneLineCenterPos(pos, {self.countdownText, self.countdown}, cc.p(5, 0))
	end})
end

function ActivityQualityExchangeFragmentView:playBgEffect(name)
	if self.bgEffectName ~= name then
		self.bgEffectName = name
		self.bgEffect:play(self.bgEffectName)
	end
end

function ActivityQualityExchangeFragmentView:getSelectData()
	local leftId = self.leftId:read()
	local rightId = self.rightId:read()
	if leftId and rightId then
		local cfg = dataEasy.getCfgByKey(leftId)
		self.selectData = self.datas[rightId][cfg.quality]
	else
		self.selectData = nil
	end
end

function ActivityQualityExchangeFragmentView:refreshPanel(idx, canChoose, id)
	local panel = idx == 1 and self.leftPanel or self.rightPanel
	local childs = panel:multiget("btn", "text")
	childs.btn:visible(canChoose)
	childs.text:visible(canChoose)
	childs.btn:get("icon"):visible(id ~= nil)
	if id then
		local num = nil
		local targetNum = nil
		if self.selectData then
			local count = math.max(self.num:read(), 1)
			if idx == 1 then
				num = dataEasy.getNumByKey(id)
				targetNum = self.selectData.cfg.count *count
			else
				num = self.selectData.num * count
			end
		end
		bind.extend(self, childs.btn:get("icon"), {
			class = "icon_key",
			props = {
				data = {
					key = id,
					num = num,
					targetNum = targetNum,
				},
				onNode = function(panel)
					panel:setTouchEnabled(false)
				end,
			},
		})
	end
end

function ActivityQualityExchangeFragmentView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ActivityQualityExchangeFragmentView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(106001, 106099),
	}
	return context
end

function ActivityQualityExchangeFragmentView:onDetailPanelClick()
	gGameUI:stackUI("city.activity.quality_exchange_fragment_select", nil, nil, {data = self.detailItems, title = {gLanguageCsv.qualityExchangeFragmentTitle1, gLanguageCsv.qualityExchangeFragmentTitle2}})
end

function ActivityQualityExchangeFragmentView:getQualities()
	local qualities = {}
	for k, v in pairs(self.qualityData) do
		if v.leftTimes > 0 then
			qualities[k] = v.leftTimes
		end
	end
	return qualities
end

function ActivityQualityExchangeFragmentView:onBtnClick()
	if itertools.isempty(self:getQualities()) then
		gGameUI:showTip(gLanguageCsv.qualityExchangeFragmentTimes)
		return
	end
	local num = self.num:read()
	if not self.selectData then
		gGameUI:showTip(gLanguageCsv.qualityExchangeFragmentChooseTip1)
		return
	end
	if num <= 0 then
		gGameUI:showTip(gLanguageCsv.qualityExchangeFragmentChooseTip2)
		return
	end
	if self.rmb:read() < self.selectData.rmb * num then
		uiEasy.showDialog("rmb")
		return
	end
	local myCfg = dataEasy.getCfgByKey(self.leftId:read())
	local myName = string.format("#C0x%s#%s", string.sub(ui.QUALITYCOLOR[myCfg.quality], 5, 10), myCfg.name)
	local myDesc = string.format("%s(x%s)#C0x5B545B#", myName, self.selectData.cfg.count * num)
	local targetCfg = dataEasy.getCfgByKey(self.selectData.key)
	local targetDesc = string.format("#C0x%s#%s(x%s)#C0x5B545B#", string.sub(ui.QUALITYCOLOR[targetCfg.quality], 5, 10), targetCfg.name, self.selectData.num * num)
	local tip = string.format(gLanguageCsv.qualityExchangeFragmentExchangeTip,  myDesc, targetDesc, myName)
	gGameUI:showDialog({
		cb = function()
			local showOver = {false}
			gGameApp:requestServerCustom("/game/yy/award/exchange")
				:params(self.activityId, self.selectData.csvId, self.leftId:read(), self.selectData.idx, num)
				:onResponse(function (tb)
					self:playBgEffect("zhuanhuan")
					performWithDelay(self, function()
						showOver[1] = true
					end, 2)
				end)
				:wait(showOver)
				:doit(function (tb)
					self.leftId:set(nil)
					-- self.rightId:set(nil)
					self.num:set(0)
					gGameUI:showGainDisplay(tb)
				end)
		end,
		btnType = 2,
		isRich = true,
		content = "#C0x5B545B#" .. tip,
	})

end

function ActivityQualityExchangeFragmentView:onLeftBtnClick()
	local rightId = self.rightId:read()
	if not rightId  then
		return
	end
	-- 显示自己拥有满足条件的碎片，带数量
	local frags = gGameModel.role:read("frags")
	local data = {}
	for id, num in pairs(frags) do
		local cfg = dataEasy.getCfgByKey(id)
		if self.datas[rightId][cfg.quality] and id ~= rightId then
			table.insert(data, {key = id, num = num})
		end
	end
	table.sort(data, dataEasy.sortItemCmp)
	gGameUI:stackUI("city.activity.quality_exchange_fragment_select", nil, nil, {
		data = data,
		title = {gLanguageCsv.bag, gLanguageCsv.fragment},
		tip = gLanguageCsv.qualityExchangeFragmentLeftTip,
		cb = function(id)
			self.leftId:set(id)
			self.num:set(math.min(1, self.maxNum))
		end,
	})
end

function ActivityQualityExchangeFragmentView:onRightBtnClick()
	if itertools.isempty(self:getQualities()) then
		gGameUI:showTip(gLanguageCsv.qualityExchangeFragmentTimes)
		return
	end
	local hash = {}
	for key, data in pairs(self.datas) do
		for quality, _ in pairs(data) do
			if self.qualityData[quality] and self.qualityData[quality].leftTimes > 0 then
				hash[key] = true
			end
		end
	end
	local data = {}
	for key, _ in pairs(hash) do
		table.insert(data, {key = key})
	end
	table.sort(data, dataEasy.sortItemCmp)
	gGameUI:stackUI("city.activity.quality_exchange_fragment_select", nil, nil, {
		data = data,
		title = {gLanguageCsv.qualityExchangeFragmentTitle3, gLanguageCsv.qualityExchangeFragmentTitle4},
		tip = gLanguageCsv.qualityExchangeFragmentRightTip,
		cb = function(id)
			self.leftId:set(nil)
			self.num:set(0)
			self.rightId:set(id)
		end,
	})
end

function ActivityQualityExchangeFragmentView:onIncreaseNum(step)
	self.num:modify(function(num)
		return true, cc.clampf(num + step, 0, math.max(self.maxNum, 0))
	end)
end

function ActivityQualityExchangeFragmentView:onChangeNum(node, event, step)
	if event.name == "click" then
		self:unScheduleAll()
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 1)

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

return ActivityQualityExchangeFragmentView