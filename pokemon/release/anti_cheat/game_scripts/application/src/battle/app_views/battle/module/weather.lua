--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

-- 战斗中的天气情况, 同一时间最多存在一种天气, 没有天气时隐藏该模块

local WeatherInfo = class('WeatherInfo', battleModule.CBase)

function WeatherInfo:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.weatherLayer = self.parent.weatherLayer
	self.weatherInfo = self.parent.UIWidgetMid:get("widgetPanel.weatherInfo")
	self.weatherView = self.parent.UIWidgetMid:get("widgetPanel.topinfo.weather")
	self.effect = nil
	self.curWeatherId = nil
	self:init()
	
	self.originSize = self.weatherView:getContentSize()
end

function WeatherInfo:init()
	-- 默认天气详细信息是关闭的
	self.weatherInfo:setVisible(false)

	local action
	-- 长按天气面板显示天气信息
	self.weatherView:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			action = performWithDelay(self.weatherLayer, function()
				action = nil
				self:initInfoPanel(true)
				self.weatherInfo:setVisible(true)
			end, 0.4)
		elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
			self.weatherLayer:stopAction(action)
			action = nil
			self:initInfoPanel(false)
			self.weatherInfo:setVisible(false)
		end
	end)
end

-- 信息面板
function WeatherInfo:initInfoPanel(isShow)
	self.weatherInfo:setVisible(isShow)
	if not isShow then return end

	local cfg = csv.weather[self.curWeatherId]
	self.weatherInfo:get("name"):setString(cfg.name)
	if self.model.lifeRound > 99 then
		nodetools.get(self.weatherInfo, "desc"):setString(gLanguageCsv.forever)
	else
		nodetools.get(self.weatherInfo, "desc"):setString(string.format(gLanguageCsv.leftRounds, self.model.lifeRound))
	end

	local describe = self.weatherInfo:get("describe")
	describe:removeAllChildren()
	local descSize = describe:getContentSize()

	local richtext = rich.createWithWidth(string.format("#C0x5b545b#%s", cfg.describe), 42, nil, descSize.width)
	richtext:setAnchorPoint(cc.p(0, 1))
	describe:add(richtext)

	-- 底图修改大小
	local infoBg = self.weatherInfo:get("bg")
	local bgsize = infoBg:getContentSize()
	local textHeight = richtext:getContentSize().height
	local upheight = describe:getPositionY()
	local newHeight = upheight + textHeight + 5
	infoBg:setContentSize(cc.size(bgsize.width, (newHeight > self.originSize.height) and newHeight or self.originSize.height))
end

-- 刷新天气的显示
function WeatherInfo:onWeatherRefresh(model, buff)
	if not buff.isShow then
		self.weatherView:setVisible(false)
		if self.effect then
			self.effect:play("effect_danchu")
		end
		self.curWeatherId = nil
	else
		self.cfg = csv.weather[buff.weatherCfgId]
		if buff.weatherCfgId ~= self.curWeatherId then
			if self.effect then
				self.effect:play("effect_danchu")
				performWithDelay(self.weatherLayer, function()
					self:onShowWeatherAnimation(self.cfg.effectRes)
				end, 1)
			else
				self:onShowWeatherAnimation(self.cfg.effectRes)
			end
		end

		self.weatherView:get("icon"):loadTexture(self.cfg.iconRes)
		self.weatherView:setVisible(true)
		self.model = buff
		self.curWeatherId = self.model.weatherCfgId
		nodetools.get(self.weatherView, "weatherDesc"):setString(self.cfg and self.cfg.name)
		if self.model.lifeRound > 99 then
			nodetools.get(self.weatherView, "roundDesc"):setString(gLanguageCsv.forever)
		else
			nodetools.get(self.weatherView, "roundDesc"):setString(string.format(gLanguageCsv.leftRounds, self.model.lifeRound))
		end		
	end
end

-- 显示各种天气的特效
-- @parm res: 资源
-- @parm switch: 天气特效的开关， "xxx": 打开， nil: 关闭
function WeatherInfo:onShowWeatherAnimation(res)
	if self.effect then
		self.effect:removeFromParent()
	end
	if not res then return end

	self.effect = newCSprite(res)
	self.effect:xy(display.cx, display.cy):scale(2):play("effect_danru")
	performWithDelay(self.weatherLayer, function()
		self.effect:play("effect_loop")
	end, 1)

	self.weatherLayer:add(self.effect, 9999)
end

return WeatherInfo