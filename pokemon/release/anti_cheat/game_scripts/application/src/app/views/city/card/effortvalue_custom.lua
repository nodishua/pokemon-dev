local STATE_TYPE = {
	ONE_AND_TEN = 1,
	ONE = 2,
	SAVE_AND_CANCEL = 3,
	SAVE = 4,
}

local TRAIN_TYPE = {
	ONE = 1,
	TEN = 2,
}

local CardCustomEffortvalueView = class("CardCustomEffortvalueView",Dialog)

CardCustomEffortvalueView.RESOURCE_FILENAME = "card_effortvalue_custom.json"
CardCustomEffortvalueView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["sliderNum"] = {
		varname = "sliderNumber",
		binds = {
			event = "text",
			idler = bindHelper.self("sliderNum")
		}
	},
	["slider"] = "slider",
	["btnSub"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["btnAdd"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["sureBtn.txt"] = {
		varname = "costTxt",
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["sureBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureClick")}
		},
	},
	["icon"] = "icon",
	["costText"] = "costText",
	["costNum"] = "costNum",
	["num"] = "num",
}

function CardCustomEffortvalueView:onCreate(idx,key,times,dbid,cb)
	self.dbid = dbid
	self.idx = idx
	self.cb = cb
	self.times = times
	self:initModel()
	self:enableSchedule()
	self.icon:texture(dataEasy.getCfgByKey(key).icon)
	self.costNum:text(3*(3-idx))
	self.costTxt:text(string.format(gLanguageCsv.customEffortTimes, self.selectNum:read()))
	self.slider:setPercent(0)
	adapt.oneLinePos(self.costText, {self.costNum,self.icon}, {cc.p(10,0),cc.p(10,0)})
	idlereasy.when(self.selectNum, function(_, selectNum)
		selectNum = (selectNum<times) and selectNum or times
		self.sliderNum:set(self.selectNum:read().."/"..self.times)
		-- 非拖动时才设置进度
		if not self.slider:isHighlighted() then
			local percent = math.ceil(selectNum/times*100)
			self.slider:setPercent(percent)
		end
		cache.setShader(self.addBtn, false, (selectNum >= times) and "hsl_gray" or  "normal")
		cache.setShader(self.subBtn, false, (selectNum <= 1) and "hsl_gray" or  "normal")
		self.addBtn:setTouchEnabled(selectNum < times)
		self.subBtn:setTouchEnabled(selectNum > 1)
		self.sliderNum:set(self.selectNum:read().."/"..self.times)
		self.costNum:text(3*(3-idx)*self.selectNum:read())
		self.costTxt:text(string.format(gLanguageCsv.customEffortTimes, self.selectNum:read()))
		adapt.oneLinePos(self.costText, {self.costNum,self.icon}, {cc.p(10,0),cc.p(10,0)})
		if selectNum == 1 then
			self:unScheduleAll()
		end
		adapt.oneLinePos(self.num,self.sliderNumber,cc.p(-10,0))
	end)
	self.slider:addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local maxtimes = times
		local selectLevel = math.ceil(maxtimes/100 * percent)
		local num  = math.max(math.min(maxtimes,selectLevel), 1)
		self.selectNum:set(num)
	end)
	Dialog.onCreate(self)
end
function CardCustomEffortvalueView:initModel()
	self.selectNum = idler.new(1)
	self.sliderNum = idler.new(self.selectNum:read().."/"..self.times)
end
function CardCustomEffortvalueView:onClose()
	Dialog.onClose(self)
end

function CardCustomEffortvalueView:onChangeNum(node, event, step)
	if event.name == "click" then
		self:unScheduleAll()
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 100)
	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

function CardCustomEffortvalueView:onIncreaseNum(step)
	self.selectNum:modify(function(num)
		return true, cc.clampf(num + step, 0, self.times)
	end)
end



function CardCustomEffortvalueView:onSureClick()
	if self.selectNum:read() == 0 then
		gGameUI:showTip(gLanguageCsv.pleaseSelectMaterials)
		return
	end

	gGameApp:requestServer("/game/card/effort/train",function (tb)
		if self.cb then
			self.cb(tb)
		end
		self:onClose()
	end, self.dbid, self.idx, self.selectNum:read())
end

return CardCustomEffortvalueView