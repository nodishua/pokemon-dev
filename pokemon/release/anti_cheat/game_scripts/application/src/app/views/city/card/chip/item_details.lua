-- @date 2021-5-16
-- @desc 学习芯片道具详情

local ViewBase = cc.load("mvc").ViewBase
local ChipItemDetailsView = class("ChipItemDetailsView", ViewBase)

ChipItemDetailsView.RESOURCE_FILENAME = "chip_item_details.json"
ChipItemDetailsView.RESOURCE_BINDING = {
	["panel"] = "panel",
	["panel.btnReset"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onResetClick")}
		}
	},
	["panel.btnOK"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOKClick")}
		}
	},
	["panel.btnOK.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["panel.sliderPanel"] = "sliderPanel",
	["panel.sliderPanel.subBtn"] = {
		varname = "sliderSubBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["panel.sliderPanel.addBtn"] = {
		varname = "sliderAddBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["panel.sliderPanel.slider"] = "slider",
}

-- @params {id, num, maxNum, pos, align, changeCb, cb}
function ChipItemDetailsView:onCreate(params)
	self.cb = params.cb
	self.changeCb = params.changeCb
	self.originNum = params.num
	self.maxNum = params.maxNum
	self.ownNum = dataEasy.getNumByKey(params.id)
	self.chipCfg = csv.chip.chips[params.chipId]
	self.clientChipLevel = params.clientChipLevel
	self.clientChipLevelExp = params.clientChipLevelExp
	self:enableSchedule()

	bind.extend(self, self.panel:get("icon"), {
		class = 'icon_key',
		props = {
			noListener = true,
			data = {
				key = params.id,
			},
		},
	})
	uiEasy.setIconName(params.id, nil, {node = self.panel:get("name")})
	adapt.oneLinePos(self.panel:get("gainExpText"), self.panel:get("gainExp"))

	self.singleItemExp = csv.items[params.id].specialArgsMap.chipExp
	self.num = idler.new(self.originNum)
	idlereasy.when(self.num, function(_, num)
		self.changeCb(num)
		self.panel:get("gainExp"):text(math.max(num, 1) * self.singleItemExp)
		text.addEffect(self.panel:get("gainExp"), {color = num > 0 and cc.c4b(96, 196, 86, 255) or cc.c4b(183, 176, 158, 255)})
		self.panel:get("cost"):text(string.format("%s: %d/%d", gLanguageCsv.cost, num, self.ownNum))

		cache.setShader(self.sliderSubBtn, false, num > 0 and "normal" or "hsl_gray")
		cache.setShader(self.sliderAddBtn, false, num < self.maxNum and "normal" or "hsl_gray")
		-- 非拖动时才设置进度
		local percent = math.floor(num / self.maxNum * 100)
		self.slider:setPercent(percent)
	end)
	self.showedTip = false

	self.slider:addEventListener(function(sender,eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			self:unScheduleAll()
			local percent = sender:getPercent()
			local num = math.ceil(self.maxNum * percent * 0.01)
			if not self.showedTip and num > self.maxNum then
				self.showedTip = true
				gGameUI:showTip(gLanguageCsv.chipExpMax)
			end
			num = cc.clampf(num, 0, math.max(self.maxNum, 0))
			self.num:set(num, true)
		end
	end)
end

function ChipItemDetailsView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

function ChipItemDetailsView:onIncreaseNum(step)
	self.num:modify(function(num)
		return true, cc.clampf(num + step, 0, math.max(self.maxNum, 0))
	end)
end

function ChipItemDetailsView:onChangeNum(node, event, step)
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

function ChipItemDetailsView:onResetClick()
	self.num:set(0)
end

-- 修改为下一级
function ChipItemDetailsView:onOKClick()
	if self.clientChipLevel:read() >= self.chipCfg.maxLevel then
		gGameUI:showTip(gLanguageCsv.chipExpMax)
		return
	end
	if self.num:read() >= self.maxNum then
		gGameUI:showTip(gLanguageCsv.inadequateProps)
		return
	end
	local nextLevelExp = csv.chip.strength_cost[self.clientChipLevel:read()]["levelExp" .. self.chipCfg.strengthSeq] - self.clientChipLevelExp:read()
	local num = math.min(self.num:read() + math.ceil(nextLevelExp/self.singleItemExp), self.maxNum)
	self.num:set(num)
end

return ChipItemDetailsView