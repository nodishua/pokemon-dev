-- @date:   2021-04-19
-- @desc:   狩猎地带主界面

local ROUTE_TYPE = {
    normal = 1,
    elite = 2,
}

local BLACK_BIND_EFFECT = {
	event = "effect",
	data = {outline = {color = cc.c4b(91, 84, 91, 255),  size = 4}}
}

local ORANGE_BIND_EFFECT = {
	event = "effect",
	data = {outline = {color = cc.c4b(255, 84, 0, 255),  size = 6}}
}

local WHITE_BIND_EFFECT = {
	event = "effect",
	data = {outline = {color = cc.c4b(255, 252, 237, 255),  size = 4}}
}


local ViewBase = cc.load("mvc").ViewBase
local HuntingView = class("HuntingView", ViewBase)

HuntingView.RESOURCE_FILENAME = "hunting.json"
HuntingView.RESOURCE_BINDING = {
    ["bg"] = "bg",
    ["centerPanel"] = "centerPanel",
    ["tip"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(208, 232, 152, 255),  size = 4}}
		}
	},
	----------------------------normalPanel------------------------------------
    ["centerPanel.normalPanel"] = "normalPanel",
	["centerPanel.normalPanel.btnNormal"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onNormalRouteClick")},
		},
	},
	["centerPanel.normalPanel.btnNormal.text"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["centerPanel.normalPanel.playing.txt1"] = {
		binds = ORANGE_BIND_EFFECT
	},
	["centerPanel.normalPanel.playing.txt2"] = {
		binds = ORANGE_BIND_EFFECT
	},
	----------------------------elitePanel------------------------------------
    ["centerPanel.elitePanel"] = "elitePanel",
    ["centerPanel.elitePanel.btnElite.lock"] = "eliteLock",
	["centerPanel.elitePanel.btnElite"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEliteRouteClick")},
		},
	},
	["centerPanel.elitePanel.btnElite.text"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["centerPanel.elitePanel.playing.txt1"] = {
		binds =ORANGE_BIND_EFFECT
	},
	["centerPanel.elitePanel.playing.txt2"] = {
		binds = ORANGE_BIND_EFFECT
	},
	---------------------------------------------------------------------------
    ["leftBottomPanel"] = "leftBottomPanel",
    ["leftBottomPanel.ruleBtn"] = "ruleBtn",
    ["leftBottomPanel.shopBtn.name"] = {
		binds = WHITE_BIND_EFFECT
	},
    ["leftBottomPanel.ruleBtn.name"] = {
		binds = WHITE_BIND_EFFECT
	},
	["leftBottomPanel.ruleBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")},
		},
	},
	["leftBottomPanel.shopBtn"] = {
		varname = "shopBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnShop")},
		},
	},
}

function HuntingView:onCreate(data)
	gGameUI.topuiManager:createView("hunting", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.huntingArea, subTitle = "HUNTINGAREA"})
    self:initModel()
	local baseCfg = csv.cross.hunting.base
	self.specialHuntingSign = dataEasy.isUnlock(gUnlockCsv.specialHunting)
	idlereasy.any({self.normalTimes, self.eliteTimes, self.routeInfo}, function(_, normalTimes, eliteTimes, routeInfo)
		self:initPanel()
		self.endTime1 = time.getNumTimestamp(self.routeInfo:read()[ROUTE_TYPE.normal].last_date, 5, 0, 0) + 24 * 60 * 60 * baseCfg[ROUTE_TYPE.normal].refreshDay
		if self.specialHuntingSign then
			self.endTime2 = time.getNumTimestamp(self.routeInfo:read()[ROUTE_TYPE.elite].last_date, 5, 0, 0) + 24 * 60 * 60 * baseCfg[ROUTE_TYPE.elite].refreshDay
		end
	end)
	self:initCountDown1()
	if self.specialHuntingSign then
		self:initCountDown2()
	end
	-- 特殊处理，若没有次数并且路线已结束，有引导则关闭引导
	performWithDelay(self, function()
		if gGameUI.guideManager:isInGuiding() and self.normalTimes:read() == 0 and self.routeInfo:read()[ROUTE_TYPE.normal].status == "closed" then
			gGameUI.guideManager:forceClose(nil, 'city.adventure.hunting.view')
		end
	end, 0)
end

function HuntingView:initModel()
	self.normalTimes = gGameModel.hunting:getIdler("battle_times")
	self.eliteTimes = gGameModel.hunting:getIdler("special_battle_times")
	self.routeInfo = gGameModel.hunting:getIdler("hunting_route")
	self.eliteLock:visible(not dataEasy.isUnlock(gUnlockCsv.specialHunting))
end

function HuntingView:initPanel()
	local baseCfg = csv.cross.hunting.base
	-- normal
	self.normalPanel:get("playing"):visible(self.routeInfo:read()[ROUTE_TYPE.normal].status == "starting")
	local normalColor = self.normalTimes:read() == 0 and "#C0xFC8628#" or "#C0x52D661#"
	local normalContent = string.format(gLanguageCsv.huntingTimes, normalColor, self.normalTimes:read(), baseCfg[ROUTE_TYPE.normal].battleLimit)

	self.normalPanel:get("times"):hide()
	self.normalPanel:removeChildByName("richText")
	local richText = rich.createByStr(normalContent, 56, nil)
		:xy(210, self.normalPanel:get("times"):y())
		:anchorPoint(0, 0.5)
		:addTo(self.normalPanel, 100, "richText")
		:formatText()

	self.elitePanel:get("playing"):visible(self.routeInfo:read()[ROUTE_TYPE.elite].status == "starting")
	local eliteColor = self.eliteTimes:read() == 0 and "#C0xFC8628#" or "#C0x52D661#"
	local normalContent = string.format(gLanguageCsv.huntingTimes, eliteColor, self.eliteTimes:read(), baseCfg[ROUTE_TYPE.elite].battleLimit)
	if self.specialHuntingSign then
		self.elitePanel:get("times"):hide()
		self.elitePanel:removeChildByName("richText")
		local richText = rich.createByStr(normalContent, 56, nil)
			:xy(210, self.elitePanel:get("times"):y())
			:anchorPoint(0, 0.5)
			:addTo(self.elitePanel, 100, "richText")
			:formatText()
	else
		local cfg = csv.unlock[gUnlockCsv.specialHunting]
		self.elitePanel:get("times"):text(string.format(gLanguageCsv.huntingLimitTip,cfg.startLevel ))
		local x, y = self.elitePanel:get("times"):xy()
		self.elitePanel:get("times"):xy(x, y - 20)
	end
end

function HuntingView:onNormalRouteClick()
	if self.routeInfo:read()[ROUTE_TYPE.normal].status == "starting" then
		self:startRoute(ROUTE_TYPE.normal)
	elseif self.normalTimes:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.huntingGameTimesNotEnough)
		return
	else
		self:startRoute(ROUTE_TYPE.normal)
	end
end

function HuntingView:onEliteRouteClick()
	if not self.specialHuntingSign then -- 到时候取反
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.specialHunting))
		return
	elseif self.routeInfo:read()[ROUTE_TYPE.elite].status == "starting" then
		self:startRoute(ROUTE_TYPE.elite)
	elseif self.eliteTimes:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.huntingGameTimesNotEnough)
		return
	else
		self:startRoute(ROUTE_TYPE.elite)
	end
end

--点击路线
function HuntingView:startRoute(route)
	if self.routeInfo:read()[route].status == "closed" then
		gGameApp:requestServer("/game/hunting/route/begin", function(tb)
			gGameUI:stackUI("city.adventure.hunting.route", nil, nil, route)
		end, route)
	else
		gGameUI:stackUI("city.adventure.hunting.route", nil, nil, route)
	end
end

-- 商店
function HuntingView:onBtnShop()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fixshop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.HUNTING_SHOP)
		end)
	end
end

-- 养成系统
function HuntingView:onEquipClick()

end

function HuntingView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function HuntingView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(124301, 124310),
	}
	return context
end

--倒计时
function HuntingView:initCountDown1()
	local battleLimit = csv.cross.hunting.base[ROUTE_TYPE.normal].battleLimit
	local function setLabel()
		self.normalPanel:removeChildByName("richTextTime")
		if self.normalTimes:read() >= battleLimit then
			return true
		end
		local str1 = string.format(gLanguageCsv.huntingReplyGameTimes, time.getCutDown(self.endTime1 - time.getTime()).str)
		local richText1 = rich.createByStr(str1, 40, nil)
			:xy(330, 45)
			:anchorPoint(0.5, 0.5)
			:addTo(self.normalPanel, 100, "richTextTime")
			:formatText()
		if self.endTime1 - time.getTime() <= 0 then
			gGameApp:requestServer("/game/hunting/main", function(tb)

			end)
		end
		return true
	end
	self:enableSchedule()
	self:schedule(function(dt)
		return setLabel()
	end, 1, 0, 1)
end

function HuntingView:initCountDown2()
	local battleLimit = csv.cross.hunting.base[ROUTE_TYPE.elite].battleLimit
	local function setLabel()
		self.elitePanel:removeChildByName("richTextTime")
		if self.eliteTimes:read() >= battleLimit  then
			return true
		end
		local str2 = string.format(gLanguageCsv.huntingReplyGameTimes, time.getCutDown(self.endTime2 - time.getTime()).str)
		local richText1 = rich.createByStr(str2, 40, nil)
			:xy(330, 45)
			:anchorPoint(0.5, 0.5)
			:addTo(self.elitePanel, 100, "richTextTime")
			:formatText()
		if self.endTime2 - time.getTime() <= 0  then
			gGameApp:requestServer("/game/hunting/main", function(tb)

			end)
		end
		return true
	end
	self:enableSchedule()
	self:schedule(function(dt)
		return setLabel()
	end, 1, 0, 2)
end

return HuntingView