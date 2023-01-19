-- @date:   2021-06-09
-- @desc:   沙滩刨冰

local moveTime = 1.5
local STATE_TYPE = {
	closed = 1,
	start = 2,	-- 开始游戏 开始制作之前
	play = 3,	-- 开始制作之后
	quit = 4,
}

local CHECK_TYPE = {	-- (1-完美;2-良好;3-错一个;4-错两个;-5-错三个)
	perfect = 1,
	good = 2,
	bad1 = 3,
	bad2 = 4,
	bad3 = 5,
}

local ACTION_TYPE = {
	[1] = "standby_loop",
	[2] = "run_loop",
}

local DIRECTION_TYPE = {
	right = 1,
	left = -1,
}

local EMOJI_TYPE = {	-- 1 完美 2 良好 3 差
	[1] = "activity/beach_ice/img_bq_wm.png",
	[2] = "activity/beach_ice/img_bq_lh.png",
	[3] = "activity/beach_ice/img_bq_xc.png",
	[4] = "activity/beach_ice/img_bq_xc.png",
	[5] = "activity/beach_ice/img_bq_xc1.png",
}

local ViewBase = cc.load("mvc").ViewBase
local BeachIceView = class("BeachIceView",ViewBase)

local WIHTE_EFFECT= {
	event = "effect",
	data = {outline = {color = cc.c4b(255, 252, 237, 255),  size = 4}}
}

local BLACK_EFFECT= {
	event = "effect",
	data = {outline = {color = cc.c4b(91, 84, 91, 255),  size = 4}}
}

local function getTimestamp(huodongDate, huodongTime)
	local hour, min = time.getHourAndMin(huodongTime)
	return time.getNumTimestamp(huodongDate, hour, min)
end

local function getMonthInEn(month)
	local monthArr = {"Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sept","Oct","Nov","Dec"}
	return monthArr[tonumber(month)]
end

BeachIceView.RESOURCE_FILENAME = "beach_ice_view.json"
BeachIceView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["timeBg"] = "timeBg",
	["mask"] = "mask",
	["gaizi"] = "gaizi",
	["huodongTimePanel"] = "huodongTimePanel",
    ["huodongTimePanel.timeText"] = {
		varname = "timeText",
		binds = BLACK_EFFECT
	},
    ["huodongTimePanel.time"] = {
		varname = "showTime",
		binds = BLACK_EFFECT
	},
	["addTime"] = {
		varname = "addTimeText",
	},
	["gameTime"] = {
		varname = "gameTimeText",
		binds = {
			event = "text",
			idler = bindHelper.self("gameTime"),
		},
	},
	["foodPanel"] = "foodPanel",
    ------------------------centerPanel--------------------------
	["btnMaking"] = {
        varname = "btnMaking",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onMakingClick")},
		},
	},
	["centerPanel"] = "centerPanel",
    ["centerPanel.btnGame"] = {
        varname = "btnGame",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlayGameClick")},
		},
	},
	["centerPanel.addPanel"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddClick")},
		},
	},
    ["centerPanel.btnGame.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["btnMaking.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
    ["centerPanel.textTipTime"] = "textTipTime",
	["centerPanel.tipTime"] = "tipTime",
    -----------------------leftDownPanel-------------------------
	["leftDownPanel"] = "leftDownPanel",
    ["leftDownPanel.rankPanel.txt"] = {
		binds = WIHTE_EFFECT
	},
	["leftDownPanel.rulePanel.txt"] = {
		binds = WIHTE_EFFECT
	},
    ["leftDownPanel.rankPanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankClick")},
		},
	},
	["leftDownPanel.rulePanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")},
		},
	},
	------------------------------demandPanel----------------------------------
	["demandPanel"] = "demandPanel",
	["demandPanel.countDownBg"] = "countDownBg",
	["demandPanel.countDownBg.bar"] = {
		varname = "bar",
		binds = {
		  		event = "extend",
		  		class = "loadingbar",
		  		props = {
				data = bindHelper.self("curPagePro"),
		  	},
		}
	},
	["demandPanel.bg"] = "demandPanelBg",
	["demandPanel.item"] = "demandItem",
	["demandPanel.demandList"] = {
        varname = "demandList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("demandDatas"),
                item = bindHelper.self("demandItem"),
				itemAction = {isAction = true},
                onItem = function(list, node, k, v)
					if v.visible then
						node:get("img"):texture(v.icon)
						node:get("mask"):hide()
						node:get("bg"):hide()
					elseif v.sel > 0 then
						node:get("img"):texture(v.choose)
						node:get("mask"):hide()
						node:get("bg"):hide()
					else
						node:get("img"):hide()
						node:get("mask"):show()
						node:get("bg"):show()
					end
				end,
            },
        },
    },
}
function BeachIceView:onCreate(activityID)
	self:enableSchedule()
	self.activityID = activityID
    gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
        :init({title = gLanguageCsv.beachIceShop, subTitle = "BEACH ICE"})
	self.gameTime = idler.new(60) --游戏时间
	self.addTime = 0 --奖励时间
	self.curPagePro = idler.new(0) --进度条
	self.demandDatas = idlers.newWithMap({}) -- 需求list
	self.clickData = idlertable.new() -- 选中材料
	self.canclick = idler.new(false) -- 可点击
	self.round = idler.new(0) -- 轮次
	self.oneTurnCostTime = 0	-- 游戏内每一轮花费时间
	self:initModel()
	self:initGameCount()
	self:initGameTime()
	self.gameState = idler.new(STATE_TYPE.closed)

	local gaizi = widget.addAnimationByKey(self.gaizi, "effect/shatanbaobing.skel", "gaizi", "gaizi_loop", 10)
		:xy(self.gaizi:width() / 2, self.gaizi:height() / 2 + 152)
		:anchorPoint(0.5, 0.5)
	local door = widget.addAnimationByKey(self.bg, "effect/shatanbaobing.skel", "door", "che_guanbi_loop", 5)
		:xy(self.bg:width() / 2, -20)
		:anchorPoint(0.5, 0.5)
		:scale(0.5)

	idlereasy.when(self.gameState, function(_, gameState)
		if gameState == STATE_TYPE.closed then
			self.foodPanel:hide()
			self.gaizi:hide()
			self.timeBg:hide()
			self.gaizi:get("gaizi"):play("gaizi_loop")
			self.round:set(-1)
			self.mask:show()
			if self.cardSpinePanel then
				self.cardSpinePanel:removeSelf()
				self.cardSpinePanel = nil
			end
			itertools.invoke({self.btnMaking, self.demandPanel, self.gameTimeText, self.addTimeText}, "hide")
			itertools.invoke({self.leftDownPanel, self.huodongTimePanel, self.centerPanel}, "show")
			self:resetClickData()

		elseif gameState == STATE_TYPE.start then
			itertools.invoke({self.leftDownPanel, self.huodongTimePanel, self.centerPanel}, "hide")
			self.btnMaking:show()
			self.btnMaking:setTouchEnabled(false)
			self:resetClickData()

		elseif gameState == STATE_TYPE.play then
			self.btnMaking:hide()
		end
	end)
	idlereasy.when(self.canclick, function(_, canclick)
		self.mask:visible(not canclick)
	end)
	idlereasy.when(self.clickData, function(_, clickData)
		for i = 1, itertools.size(clickData) do
			self.foodPanel:get("sel" .. i):visible(clickData[i] ~= 0)
		end
		if not self:isClosedOrQuit() then
			local count = 0
			local num = csv.yunying.shaved_ice_demand[self.demandData[self.round:read()].csvID].itemNum
			for i = 1, self.demandDatas:size() do
				if self.demandDatas:atproxy(i).sel ~= 0 then
					count = count + 1
				end
			end
			if count == num and self.cancheck then
				self:checkResult()
				self.cancheck = false
				self.canclick:set(false)
			end
		end
	end)
	-- 下一关
	idlereasy.when(self.round, function(_, round)
		if round > 0 and not self:isClosedOrQuit() then
			self:resetClickData()
			if self.gameState:read() == STATE_TYPE.start then -- 第一次
				performWithDelay(self, function()
					if self.gameState:read() == STATE_TYPE.start then
						self.timeBg:show()
						self.bg:get("door"):play("che_loop")
						self.foodPanel:show()
						self.gaizi:show()
						self:createCardSpine()
					end
				end, moveTime)
			else
				performWithDelay(self, function()
					self:createCardSpine()
				end, 1)
			end
			self.cancheck = true
		end
	end)
end

function BeachIceView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

-- 游戏玩法持续时间
function BeachIceView:initGameTime()
	local yycfg = csv.yunying.yyhuodong[self.activityID]
	self.beginTime = getTimestamp(yycfg.beginDate, yycfg.beginTime)
	self.endTime = getTimestamp(yycfg.endDate, yycfg.endTime)
	if time.getTime() < self.beginTime or time.getTime() > self.endTime then
		self.centerPanel:hide()
	else
		self.centerPanel:show()
	end
	local startYear, startMonth, startDay = time.getYearMonthDay(yycfg.beginDate)
	local endYear, endMonth, endDay = time.getYearMonthDay(yycfg.endDate)
	if matchLanguage({"en"}) then
		startMonth = getMonthInEn(startMonth)
		endMonth = getMonthInEn(endMonth)
	end
	self.showTime:text(startYear .. "." .. startMonth .. "." .. startDay .. "-" .. endYear .. "." .. endMonth .. "." .. endDay)

	adapt.oneLinePos(self.showTime, self.timeText, cc.p(5, 0), "right")
end

--游戏次数
function BeachIceView:initGameCount()
	local yycfg = csv.yunying.yyhuodong[self.activityID]
	local paramMap = yycfg.paramMap or {}
	local canbuy = paramMap.buyTimes or 0
	local dayTimes = paramMap.times or 0
	self.huodongID = yycfg.huodongID
	self.cost = 0
	self.buyCost = paramMap.buyCost or {}
	--购买次数
	idlereasy.any({self.yyhuodongs}, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.activityID] or {}
		local info = yydata.info or {}
		local hadPlayTimes = info.times or 0
		local hadBuyTimes = info.buy_times or 0

		self.canBuy = canbuy > hadBuyTimes

		local time = hadBuyTimes + 1 <= itertools.size(self.buyCost) and hadBuyTimes + 1 or itertools.size(self.buyCost)
		self.cost = self.buyCost[hadBuyTimes + 1]

		self.btnAdd:visible(canbuy ~= 0)
		self.remainTimes = dayTimes + hadBuyTimes - hadPlayTimes
	    self.tipTime:text(self.remainTimes.. "/" .. dayTimes)
	end)
end

-- 开始制作
function BeachIceView:onMakingClick()
	-- 翻布动画
	self:updateGameTime()
	self.gameState:set(STATE_TYPE.play)
	self.canclick:set(true)
	gGameApp:requestServer("/game/yy/shaved_ice/start", function(tb)
		self.startTime = socket.gettime()
		self.oneTurnCostTime = 0
		self:createGameTime()
		self:checkCheat()
	end, self.activityID, self.round:read())
end

-- 游戏开始
function BeachIceView:onPlayGameClick()
	-- 游戏次数X
	if self.remainTimes == 0 then
		gGameUI:showTip(gLanguageCsv.gameTimesLimit)
		return
	end
	-- 游戏活动结束
	local yyEndtime = gGameModel.role:read("yy_endtime")
	local endTime = yyEndtime[self.activityID]
	local spendTime = 0
	if endTime == nil or math.floor(endTime - time.getTime()) <= 0 then
		gGameUI:showTip(gLanguageCsv.flipCardFinishedClickTip)
		return
	end
	local yycfg = csv.yunying.yyhuodong[self.activityID]
	local paramMap = yycfg.paramMap or {}
	self.perfectNum = 0
	self.goodNum = 0
	self.badNum = 0
	self.gameTime:set(paramMap.playTime)
	gGameApp:requestServer("/game/yy/shaved_ice/prepare", function(tb)
		self.choices = tb.view and tb.view.choices or {}
		self.demandData = tb.view and tb.view.demands or {}
		-- 动画
		self.gameState:set(STATE_TYPE.start)
		self.bg:get("door"):play("che_effect")
		self.gaizi:get("gaizi"):play("gaizi_dakai")
		self.round:set(1, true)
		self:createFood()
	end, self.activityID)

end

-- 创建精灵
function BeachIceView:createCardSpine()
	if self.cardSpinePanel then
		self.cardSpinePanel:scaleX(-1)
		self.cardSpinePanel:xy(-100, 200)
	else
		self.cardSpinePanel = ccui.Layout:create()
			:size(500, 500)
			:addTo(self.bg, 3, "spine")
			:anchorPoint(0.5, 0.5)
			:xy(-100, 200)
	end
	self.cardSpinePanel:removeChildByName("card")
	self.cardSpinePanel:removeChildByName("iconBg")
	local unitId = self.demandData[self.round:read()].guest
	local cardSpine = widget.addAnimationByKey(self.cardSpinePanel, csv.unit[unitId].unitRes, "card", ACTION_TYPE[2], 10)
		:xy(300, 20)
		:anchorPoint(0.5, 0.5)
		:scale(2)
	cardSpine:setSkin(csv.unit[unitId].skin)

	self:moveCardSpine(DIRECTION_TYPE.right)
end

-- 选择归0
function BeachIceView:resetClickData()
	local clickData = {}
	for i = 1, 9 do
		clickData[i] = 0
	end
	self.clickData:set(clickData)
end

--初始化9种材料
function BeachIceView:createFood()
	local cfg = csv.yunying.shaved_ice_items
	for k, v in pairs(self.choices) do
		self.foodPanel:get("food" .. k):get("img"):texture(cfg[v].icon2)
		bind.touch(self, self.foodPanel:get("food" .. k), {methods = {ended = function()
			self:clickFood(k, v)
		end}})
	end
end

-- 精灵移动 作相应事件
function BeachIceView:moveCardSpine(tag, type)
	self.canclick:set(false)
	self.cardSpinePanel:scaleX(tag)
	self.cardSpinePanel:runAction(cc.MoveBy:create(moveTime, cc.p(580 * tag, 0)))
	if tag == DIRECTION_TYPE.right then -- 走进来
		performWithDelay(self, function()
			if self.gameState:read() == STATE_TYPE.start then -- 第一次游戏总时间开始显示
				self:updateGameTime()
				self.gameTimeText:show()

			elseif self.gameState:read() == STATE_TYPE.play then
				gGameApp:requestServer("/game/yy/shaved_ice/start", function(tb)
					self.startTime = socket.gettime()
					self.oneTurnCostTime = 0
				end, self.activityID, self.round:read())
			end
			self.cardSpinePanel:get("card"):play(ACTION_TYPE[1])
			self:modelDemanPanel()
			self:updateTime()
			self.canclick:set(false)
		end, moveTime)
	else -- 离开
		self:showEmoji(type)
		self.cardSpinePanel:get("card"):play(ACTION_TYPE[2])
		self.demandPanel:hide()
		performWithDelay(self, function()
			self.round:set(self.round:read() + 1)
		end, moveTime)
	end
end

-- 精灵表情
function BeachIceView:showEmoji(type)
	-- 头上图片
	local iconBg = cc.Sprite:create("activity/beach_ice/box_qp.png")
		:anchorPoint(0.5, 0.5)
		:addTo(self.cardSpinePanel, 10, "iconBg")
		:xy(150, 230)
		:scale(0.5)
		:scaleX(-0.5)
		:size(202,200)
	local iconPic = cc.Sprite:create(EMOJI_TYPE[type])
		:anchorPoint(0.5, 0.5)
		:addTo(iconBg, 10, "icon")
		:xy(iconBg:width() / 2, iconBg:height() / 2)
end

-- 刷新需求尺寸
function BeachIceView:modelDemanPanel()
	local len = itertools.size(self.demandData[self.round:read()].demand or {})
	local cfg = csv.yunying.shaved_ice_items
	self.demandPanel:get("bg"):width(78 + 190 * len)
	self.demandList:width(len * 190)
	self.demandPanel:get("countDownBg"):x(len * 90 + 100)

	local demandDatas = {}
	for k, v in ipairs(self.demandData[self.round:read()].demand) do
		demandDatas[k] = {
			key = v,
			icon = cfg[v].icon1,
			visible = true,
			sel = 0,
			choose = " ",
		}
	end
	self.demandDatas:update(demandDatas)
	self.demandPanel:show()
end

-- 记忆时间进度条
function BeachIceView:updateTime()
	local cfg = csv.yunying.shaved_ice_demand
	local time1 = cfg[self.demandData[self.round:read()].csvID].time
	local endTime = socket.gettime() + time1
	self:unSchedule(100)
	self:schedule(function(dt)
		if socket.gettime() >= endTime then
			for i = 1, self.demandDatas:size() do
				self.demandDatas:atproxy(i).visible = false
			end
			self.canclick:set(true)
			if self.gameState:read() == STATE_TYPE.start then -- 第一次
				self:unSchedule(66)
				-- self:unSchedule(100)
				self.btnMaking:setTouchEnabled(true)
				self.canclick:set(false)
			end
			return false
		end
		self.curPagePro:set(math.min(((endTime - socket.gettime()) / time1) * 100,100))
	end, 1/60, 0, 100)
end

-- 游戏总倒计时
function BeachIceView:updateGameTime()
	local countdown = self.gameTime:read()
	if self.addTime ~= 0 then
		countdown = countdown + self.addTime
		self.addTimeText:text("+" .. self.addTime)
		self.addTimeText:show()

		performWithDelay(self, function()
			self.addTimeText:hide()
		end, moveTime)
	end
	self.addTime = 0
	local endTime = time.getTime() + countdown
	self:unSchedule(66)
	self:schedule(function(dt)
		if time.getTime() >= endTime then
			-- 游戏结束
			self:gameover(1)
			return false
		end
		self.gameTime:set(endTime - time.getTime())
	end, 1, 0, 66)
end

-- 材料点击
function BeachIceView:clickFood(k, v)
	if self:isClosedOrQuit() then
		return
	end
	local cfg = csv.yunying.shaved_ice_items
	local clickData = table.shallowcopy(self.clickData:read())

	if clickData[k] ~= 0 then -- 已经选中了 做取消处理
		self.demandDatas:atproxy(clickData[k]).sel = 0
		clickData[k] = 0
	else	-- 未被选择 做添加处理
		for i = 1, self.demandDatas:size() do
			if self.demandDatas:atproxy(i).sel == 0 then -- 若果没被选
				self.demandDatas:atproxy(i).sel = k
				self.demandDatas:atproxy(i).choose = cfg[v].icon1
				clickData[k] = i
				break
			end
		end
	end
	self.clickData:set(clickData)
end

function BeachIceView:isClosedOrQuit()
	local gameState = self.gameState:read()
	return gameState == STATE_TYPE.closed or gameState == STATE_TYPE.quit
end

-- 核对结果
function BeachIceView:checkResult()
	if self.gameState:read() ~= STATE_TYPE.play then
		return
	end
	local mineChoose = {}
	local demand = {}
	for i = 1, self.demandDatas:size() do
		mineChoose[i] = self.choices[self.demandDatas:atproxy(i).sel]
		demand[i] = self.demandDatas:atproxy(i).key
	end
	gGameApp:requestServer("/game/yy/shaved_ice/end", function(tb)
		local type = tb.view.result and tb.view.result.type or CHECK_TYPE.bad3
		local score = tb.view.result and tb.view.result.score or 0
		self.addTime = tb.view.result.time
		if type == CHECK_TYPE.perfect then
			self.perfectNum = self.perfectNum + 1
		elseif type == CHECK_TYPE.good then
			self.goodNum = self.goodNum + 1
		else
			self.badNum = self.badNum + 1
		end
		self:updateGameTime()
		self.checkUi = gGameUI:stackUI("city.activity.beach_ice.check", nil, {clickClose = true, blackLayer = true}, {unitID = self.demandData[self.round:read()].guest, type = type, mineChoose = mineChoose, demand = demand, score = score, cb = self:createHandler("setCheckUi")})
		self:moveCardSpine(DIRECTION_TYPE.left, type)
	end, self.activityID, self.round:read(), mineChoose, self.oneTurnCostTime)
end


function BeachIceView:setCheckUi()
	self.checkUi = nil
end

-- 排行榜
function BeachIceView:onRankClick()
	if time.getTime() < self.beginTime or time.getTime() > self.endTime then
		gGameUI:showTip(gLanguageCsv.notRank)
		return
	end
	gGameApp:requestServer("/game/yy/shaved_ice/rank", function(tb)
		gGameUI:stackUI("city.activity.beach_ice.rank", nil, nil, tb.view, self.activityID)
	end, self.activityID)
end

-- 任务
function BeachIceView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function BeachIceView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(124801, 124820),
	}
	return context
end

-- 增加次数
function BeachIceView:onAddClick()
    local yyEndtime = gGameModel.role:read("yy_endtime")
	local endTime = yyEndtime[self.activityID]
	local spendTime = 0
	if endTime == nil or math.floor(endTime - time.getTime()) <= 0 then
		gGameUI:showTip(gLanguageCsv.flipCardFinishedClickTip)
		return
	end
    if self.canBuy == false then
        gGameUI:showTip(gLanguageCsv.buyTimesLimit)
        return
    end
    local strTips = gLanguageCsv.purchaseTimesTip
    gGameUI:showDialog({
        cb = function()
            if self.cost > gGameModel.role:read("rmb") then
                uiEasy.showDialog("rmb")
            else
                gGameApp:requestServer("/game/yy/shaved_ice/buy", function(tb)
                    gGameUI:showTip(gLanguageCsv.buySuccess)
                end, self.activityID)
            end
        end,
		title = gLanguageCsv.spaceTips,
		content = string.format(strTips, self.cost),
		isRich = true,
		btnType = 2,
		clearFast = true,
		size = {height = 450, width = 850},
		dialogParams = {clickClose = false},
	})
end

-- 游戏结束
function BeachIceView:gameover(flag) -- 1 进界面 2 需要做判断判断
	self:unScheduleAll()
	self:stopAllActions()
	self.canclick:set(false)
	self.gaizi:get("gaizi"):play("gaizi_guanbi")
	if not self:isClosedOrQuit() then
		self.gameState:set(STATE_TYPE.quit)

		gGameApp:requestServer("/game/yy/shaved_ice/quit", function(tb)
			self:changeGameState(false)
			if flag == 2 and (self.perfectNum + self.goodNum + self.badNum) == 0 then
				self.bg:get("door"):play("che_guanbi_loop")
			else
				gGameUI:stackUI("city.activity.beach_ice.game_over", nil, {blackLayer = true}, {perfectNum = self.perfectNum, goodNum = self.goodNum, badNum = self.badNum, huodongID = self.huodongID, award = tb.view.result or {}, cb = self:createHandler("changeGameState", true)})
			end
		end, self.activityID)
	end
end


function BeachIceView:changeGameState(tag)
	if tag then
		self.bg:get("door"):play("che_guanbi_loop")
	end
	self.gameState:set(STATE_TYPE.closed)
	if self.checkUi then
		self.checkUi:onClose()
		self.checkUi = nil
	end
end

function BeachIceView:onClose()
	if self.gameState:read() == STATE_TYPE.closed then
		ViewBase.onClose(self)
		return
	end
	local content = "#C0x5b545b#"..gLanguageCsv.exitDuringProductionTip
	if self.gameState:read() == STATE_TYPE.start then
		content = "#C0x5b545b#"..gLanguageCsv.firstExit
	end
	gGameUI:stackUI("city.activity.beach_ice.tips", nil, nil, {clearFast = true, content = content, state = self.gameState:read(), cb = function()
		self:gameover(2)
	end, time = self.gameTime:read() - 1})

end

--防作弊
function BeachIceView:checkCheat()
	local time1 = 5
	local countdown = time1
	local time2 = socket.gettime()
	self:unSchedule(718)
	self:schedule(function(dt)
		if countdown <= 0 then
			if math.abs(socket.gettime() - time2 - time1) > 3 then
				self:gameover(2)
				gGameUI:showDialog({
					content = gLanguageCsv.skyScraperTimeError,
					btnType = 1,
					clearFast = true,
					dialogParams = {clickClose = false}
				})
				return false
			else
				self:checkCheat()
			end
		end
		countdown = countdown - dt
	end, 1, 0, 718)
end

function BeachIceView:createGameTime()
	self:schedule(function(dt)
		self.oneTurnCostTime = self.oneTurnCostTime + 0.1
	end, 0.1, 0, 111111)
end

return BeachIceView