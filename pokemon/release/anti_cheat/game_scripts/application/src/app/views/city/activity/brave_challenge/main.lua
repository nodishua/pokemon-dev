-- @date:   2021-03-08
-- @desc:   勇者挑战
local BCAdapt = require("app.views.city.activity.brave_challenge.adapt")

local ACTION_TIME = 0.5
local BIND_EFFECT= {
	event = "effect",
	data = {outline = {color = cc.c4b(82, 76, 85, 255),  size = 4}}
}

local ViewBase = cc.load("mvc").ViewBase
local BraveChallengeMainView = class("BraveChallengeMainView",ViewBase)

BraveChallengeMainView.RESOURCE_FILENAME = "activity_brave_challenge_main.json"
BraveChallengeMainView.RESOURCE_BINDING = {
	-----------------------centerPanel-----------------------------
	["centerPanel"] = "centerPanel",
	["doorPanel"] ={
		varname = "doorPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlayGameClick")},
		},
	},
	["centerPanel.tipBg"] = "tipBg",
	["centerPanel.txtTimes"] = {
		varname = "txtCTimes",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT,  size = 4}}
			},
			{
				event = "text",
				idler = bindHelper.self("txtTimes"),

			}
		}
	},

	["centerPanel.btnGame"] = {
		varname = "btnGame",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlayGameClick")},
		},
	},
	["centerPanel.btnGame.img"] = "imgBtnGame",

	["centerPanel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")},
		},
	},
	-----------------------leftDownPanel---------------------------
	["leftDownPanel"] = "leftDownPanel",
	["leftDownPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")},
		},
	},
	["leftDownPanel.btnRank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankClick")},
		},
	},
	["leftDownPanel.btnAchievement"] = {
		binds = {
			{
			event = "touch",
			methods = {ended = bindHelper.self("onAchievementClick")},
			},
			-- 成就红点
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "braveChallengeAch",
					listenData = {
						activityId =  bindHelper.self("activityId"),
						sign = bindHelper.self("sign"),
					},
					onNode = function(node)
						node:scale(0.5)
						node:xy(100, 100)
					end,
				}
			}
		},
	},
	-----------------------rightDownPanel------------------------
	["rightDownPanel"] = "rightDownPanel",
	["rightDownPanel.timesNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("passTimes"),
		},
	},
	["rightDownPanel.roundNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("clearanceRoundNum"),
		},
	},
	["centerPanel.panelTime"] = "panelTime",
	["centerPanel.panelTime.txtTime"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT,  size = 3}}
		}
	}
}

-- 初始化
function BraveChallengeMainView:onCreate(params)
	self:initModel()

	self.parent = params.parent
	self.activityId = self.id:read()
	self.sign = BCAdapt.typ
	--游戏次数

	self.cost = 0
	self.clearanceTimesNum = idler.new()
	self.clearanceRoundNum = idler.new()
	self.txtTimes = idler.new()

	self:initReflushIdler()
	-- 回合数
	idlereasy.when(self.rank, function(obj, rank)
		self.clearanceRoundNum:set(rank.round)
	end)

	-- 通关次数
	idlereasy.when(self.passTimes, function(_, times)
		self.rightDownPanel:visible(times > 0)
	end)
	-- 状态变更
	idlereasy.when(self.status, function(_, status)

		self.imgBtnGame:texture( status == "start" and "activity/brave_challenge/txt_yztz_7.png"
			or "activity/brave_challenge/txt_yztz_3.png")
	end)

end

-- model初始化
function BraveChallengeMainView:initModel()
	self.passTimes = gGameModel.brave_challenge:getIdler("pass_times")
	self.rank = gGameModel.brave_challenge:getIdler("rank")
	self.status = gGameModel.brave_challenge:getIdler("status")

	self.id = gGameModel.brave_challenge:getIdler("yyID")
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

	self.commonBCData = gGameModel.role:getIdler("normal_brave_challenge")
end


--开始游戏按钮
function BraveChallengeMainView:onPlayGameClick()
	if self.parent.comingSoon then
		gGameUI:showTip(gLanguageCsv.comingSoon)
		return
	end
	local endTime = self.parent:getEndTime()
	if endTime == nil or math.floor(endTime - time.getTime()) <= 0 then
		gGameUI:showTip(gLanguageCsv.flipCardFinishedClickTip)
		return
	end
	if self.status:read() == "start" then
		 self.parent:openOtherView("city.activity.brave_challenge.challenge_gate", 3)
	else
		-- 次数判断，次数不足提示
		if self.remainTimes == 0 then
			gGameUI:showTip(gLanguageCsv.gameTimesLimit)
			return
		end
		-- 进入选牌界面
		gGameApp:requestServer(BCAdapt.url("preStart"), function(tb)
			self.parent:openOtherView("city.activity.brave_challenge.select_card", 2, false, tb.view)
		end, self.activityId)
	end
end

--进场动画
function BraveChallengeMainView:runStartAction()
	local view = self:getResourceNode()
	local fadeIn
	fadeIn = function(view)
		for _ , childView in pairs(view:getChildren()) do
			if childView:getChildrenCount()	== 0 then
				childView:runAction(cc.EaseOut:create(cc.FadeIn:create(ACTION_TIME), ACTION_TIME))
			else
				fadeIn(childView)
			end
		end
	end
	fadeIn(view)
end

-- 出场动画
function BraveChallengeMainView:runEndAction()
	local view = self:getResourceNode()
	local fadeOut
	fadeOut = function(view)
		for _ , childView in pairs(view:getChildren()) do
			if childView:getChildrenCount()	== 0 then
				childView:runAction(cc.EaseOut:create(cc.FadeOut:create(ACTION_TIME), ACTION_TIME))
			else
				fadeOut(childView)
			end
		end
	end
	fadeOut(view)
end

-- 购买次数 还未修改
function BraveChallengeMainView:onAddClick()
	if self.parent.comingSoon then
		gGameUI:showTip(gLanguageCsv.comingSoon)
		return
	end
	local endTime = self.parent:getEndTime()
	local spendTime = 0
	if endTime == nil or math.floor(endTime - time.getTime()) <= 0 then
		gGameUI:showTip(gLanguageCsv.flipCardFinishedClickTip)
		return
	end
	if self.canBuy == false then
		gGameUI:showTip(gLanguageCsv.buyTimesLimit)
		return
	end
	local strTips = gLanguageCsv.buyGameTimes
	gGameUI:showDialog({
		cb = function()
			if self.cost > gGameModel.role:read("rmb") then
				uiEasy.showDialog("rmb")
			else
				gGameApp:requestServer(BCAdapt.url("buy"), function(tb)
					gGameUI:showTip(gLanguageCsv.buySuccess)
				end, self.activityId)
			end
		end,
		title = gLanguageCsv.spaceTips,
		content = string.format(strTips, self.cost),
		isRich = true,
		btnType = 2,
		clearFast = true,
		dialogParams = {clickClose = false},
	})
end

--成就
function BraveChallengeMainView:onAchievementClick()
	if self.parent.comingSoon then
		gGameUI:showTip(gLanguageCsv.comingSoon)
		return
	end
	local info = self.parent:getBaseInfo()
	gGameUI:stackUI("city.activity.brave_challenge.achievement", nil, nil, self.activityId,info)
end

--排行榜
function BraveChallengeMainView:onRankClick()
	if self.parent.comingSoon then
		gGameUI:showTip(gLanguageCsv.comingSoon)
		return
	end
	gGameApp:requestServer(BCAdapt.url("rank"), function(tb)
		gGameUI:stackUI("city.activity.brave_challenge.rank", nil, nil, tb.view)
	end, self.activityId)
end

--规则 还未修改
function BraveChallengeMainView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end


-- 规则界面
function BraveChallengeMainView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(122001, 122030),
	}
	return context
end


--倒计时
function BraveChallengeMainView:initCountDown(sign, times)
	self.panelTime:visible(not sign)
	if sign then return end
	local info = self.parent:getBaseInfo()
	local addTimes = info.addTimes or 0
	times  = times > addTimes and addTimes or times

	self.downTime = time.getNumTimestamp(time.getNextdayStrInClock(), time.getRefreshHour())
	local function setLabel()
		local txtTime = self.panelTime:get("txtTime")
		local str1 = string.format(gLanguageCsv.braveChallengeRecoverTimeTip, time.getCutDown(self.downTime - time.getTime(), true).str, times)
		txtTime:text(str1)
		return true
	end
	setLabel()
	self:enableSchedule()
	self:schedule(function(dt)
		return setLabel()
	end, 1, 0, 1)

	self:requestMain(0)
end

function BraveChallengeMainView:requestMain(minDelay)
	self.downTime =  time.getNumTimestamp(time.getNextdayStrInClock(), time.getRefreshHour())
	local delay = math.max(self.downTime - time.getTime() + 1, minDelay)
	performWithDelay(self, function()
		gGameApp:requestServer(BCAdapt.url("main"), function()
			self:requestMain(10)
		end)
	end, delay)
end

----------------------------------------------------------------------------------------------------------
--adapt
-----------------------------------------------------------------------------------------------------
function BraveChallengeMainView:setCenterPanelVisible(state)
	self.centerPanel:visible(state)
end

function BraveChallengeMainView:initReflushIdler()

	local info = self.parent:getBaseInfo()
	local buyTimes = info.buyTimes or 0
	local dayTimes = info.timesLimit or 0
	local addTimes = info.addTimes or 0
	local buyCost = info.buyCost or {}

	 -- 周年庆
	if BCAdapt.typ == game.BRAVE_CHALLENGE_TYPE.anniversary then

		idlereasy.when(self.yyhuodongs, function(obj, yyhuodongs)
			local data = yyhuodongs[self.activityId]
			local buyTimes = data.info.buyTimes
			local gameTimes = data.info.times

			self.canBuy = buyTimes > buyTimes
			local time = buyTimes + 1 <= itertools.size(buyCost) and buyTimes + 1 or itertools.size(buyCost)
			self.cost = buyCost[buyTimes + 1]

			self.btnAdd:visible(buyTimes ~= 0)
			if buyTimes == 0 then
				self.txtCTimes:x(200)
			end

			self.remainTimes = dayTimes + buyTimes - gameTimes

			self.txtTimes:set(gLanguageCsv.braveChallengeGameTimes .. self.remainTimes)
			self:initCountDown(true)
		end)
	else

		idlereasy.when(self.commonBCData, function(obj, data)
			if not data.info then
				return
			end
			local buyTimes = data.info.buyTimes
			local gameTimes = data.info.times

			self.canBuy = buyTimes > buyTimes
			local time = buyTimes + 1 <= itertools.size(buyCost) and buyTimes + 1 or itertools.size(buyCost)
			self.cost = buyCost[buyTimes + 1]

			self.btnAdd:visible(buyTimes ~= 0)

			self.remainTimes = dayTimes + buyTimes - gameTimes
			local color = self.remainTimes >= dayTimes and "#C0xFFFFFF#" or "#C0x88C855#"
			local str = string.format(gLanguageCsv.braveChallengeRecoverTimeTip02, color, self.remainTimes, dayTimes)

			local parent = self.txtCTimes:parent()
			local richText = parent:get("richTimes")
			if richText then
				richText:removeFromParent()
			end
			richText = rich.createWithWidth(str, 40, nil, 250, nil, cc.p(0, 0.5))
				:anchorPoint(cc.p(0, 0.5))
				:xy(220, 90)
				:addTo(self.txtCTimes:parent())
				:name("richTimes")
			self.txtCTimes:visible(false)

			self:initCountDown(self.remainTimes >= dayTimes, dayTimes - self.remainTimes)
		end)
	end
end

return BraveChallengeMainView