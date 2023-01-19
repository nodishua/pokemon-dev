--丢雪球
local ViewBase = cc.load("mvc").ViewBase
local SnowBallGame = class("SnowBallGame",ViewBase)

local guide_config = {
	[1] = {nodeName = "rockerBg", content = gLanguageCsv.snowBallGuide1},
	[2] = {nodeName = "timeGuidePanel", content = gLanguageCsv.snowBallGuide2},
	[3] = {nodeName = "cannonPanel1", content = gLanguageCsv.snowBallGuide3},
	[4] = {nodeName = "cannonPanel2", content = gLanguageCsv.snowBallGuide4},
}
SnowBallGame.RESOURCE_FILENAME = "snow_ball_game.json"
SnowBallGame.RESOURCE_BINDING = {
	["panelCountDown"] = "panelCountDown",
	["bg"] = "bg",
	["bg.cannonPanel1"] = "cannonPanel1",
	["bg.cannonPanel2"] = "cannonPanel2",
	["imgTimeBg"] = "imgTimeBg",
	["imgTimeBg.guidePanel"] = "timeGuidePanel",
	["imgTimeBg.textTime"] = "textCountDown",
	["rockerPanel"] = {
		varname = "rockerPanel",
        binds = {
			event = "touch",
			scaletype = 0,
			soundClose = true,
			methods = {
					began = bindHelper.self("createRocker"),
					ended = bindHelper.self("removeRocker"),
					cancelled = bindHelper.self("removeRocker"),
					moved = bindHelper.self("moveRocker")
				},
        },
	},
	["imgInfo.textScore"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("point"),
		},
	},
	["imgInfo.imgSm"] = "imgSm",
}

local endPos = cc.p(100,100)
local startPos = cc.p(1500,100)



--获取交点
local function getIntersection(line1, line2)
	local a =  line1[1]
	local b =  line1[2]
	local c =  line2[1]
	local d =  line2[2]
	local  denominator = (b.y - a.y) * (d.x - c.x) - (a.x - b.x) * (c.y - d.y);
	if denominator == 0 then
	  	return nil
	end
	-- 线段所在直线的交点坐标 (x , y)
	local x = ((b.x - a.x) * (d.x - c.x) * (c.y - a.y) + (b.y - a.y) * (d.x - c.x) * a.x - (d.y - c.y) * (b.x - a.x) * c.x) / denominator;
	local y = -((b.y - a.y) * (d.y - c.y) * (c.x - a.x)+ (b.x - a.x) * (d.y - c.y) * a.y - (d.x - c.x) * (b.y - a.y) * c.y) / denominator;
	-- /** 2 判断交点是否在两条线段上 **/
	if (x - a.x) * (x - b.x) <= 0 and (y - a.y) * (y - b.y) <= 0 and (x - c.x) * (x - d.x) <= 0 and (y - c.y) * (y - d.y) <= 0 then
		return cc.p(x, y)
	end
	return nil
end

local function getTimeBySocket()
    local ok, socket = pcall(function()
        return require("socket")
    end)
    if ok then
        return socket.gettime() * 1000
    else
        return os.time() * 1000
    end
end

function SnowBallGame:onCreate(activityId, csvId)
	self.tGift = {}
	self.tSnowBall = {}
	self:enableSchedule()
	self.panelCountDown:globalZ(1)
	self.activityId = activityId
	self.csvId = csvId
	local cfg = csv.yunying.snowball_element[csvId]
	self.attr = cfg.attr
	self.playTime = 0

	self:initLife()
	self:initModel()
	self:initMoveRect()
	self:startCount()
	self:createCannon()
end

function SnowBallGame:initModel( )
	self.point = idler.new(0)
	self.myLife = idler.new(self.attr.life)
	local yyhuodongs = gGameModel.role:read("yyhuodongs")
	local yydata = yyhuodongs[self.activityId] or {}
	self.topPoint = yydata.info.top_point or 0
	self.isGuide = yydata.info.isGuide
	idlereasy.when(self.myLife, function(_, myLife)
		for i = 1 , self.attr.life  do
			if i > myLife then
				self.tImgSm[i]:get("img"):hide()
			else
				self.tImgSm[i]:get("img"):show()
			end
		end
		if myLife == 0 and self.gaming == true then
			self:gameOver()
			local point = self.point:read()
			gGameApp:requestServer("/game/yy/snowball/end",function (tb)
				self:showGmameEnd(point)
			end, self.activityId, point, self.playTime, self.isGuide == 0 and 1 or 0, self.csvId)
		end
	end)
end
function SnowBallGame:initLife( )
	local imgSm = self.imgSm
	self.tImgSm = {[1] = self.imgSm}
	for i = 1 + 1, self.attr.life  do
		local newImg = imgSm:clone():addTo(imgSm:getParent())
			:xy(imgSm:x() + 49 * (i - 1), imgSm:y())
		table.insert(self.tImgSm, newImg)
	end
end

function SnowBallGame:createSprite()
	local posX = (self.posTable[1].x + self.posTable[3].x) / 2
	local posY = (self.posTable[1].y + self.posTable[3].y) / 2
	local scale = math.sqrt(self.attr.weight)
	self.spriteShadow = cc.Sprite:create("activity/snow_ball/img_xqdbs_ty.png")
		:addTo(self.bg)
		:xy(posX, posY)
		:z(10000 - posY)
		:scale(scale)

	local cardName = self.attr.cardName or self.attr.careName
	self.sprite = widget.addAnimation(self.spriteShadow, string.format("snow_ball/%s.skel",cardName), "shengdan_standby_loop", 5)
		:xy(self.spriteShadow:width()/2 , self.spriteShadow:height()/2)
		:scaleX(- 1)
		:scaleY(1)
		:name("imgSel")
end


function SnowBallGame:initMoveRect()
	self.posTable = {}
	for i = 1, 4 do
		self.posTable[i] = cc.p(self.bg:get("pos"..i):xy())
	end
	for i = 1, 4 do
		local ii = (i == 4) and 1 or (i + 1)
		local deltaX = self.posTable[ii].x - self.posTable[i].x
		local deltaY = self.posTable[ii].y - self.posTable[i].y
		local xie = math.sqrt(math.pow(deltaX, 2) + math.pow(deltaY , 2))
	end
end

--倒计时
function SnowBallGame:initCountDown()
	local beignTime = time.getTime()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local playTimeMax = yyCfg.paramMap.playTimeMax
	local timeDelta = yyCfg.paramMap.timeDelta
	local spendTime = 0
    bind.extend(self, self.textCountDown, {
		class = 'cutdown_label',
		props = {
			time = playTimeMax,
			str_key = "short_clock_str",
			endFunc = function()
				if self.gaming then
					self:gameOver()
					local point = self.point:read()
					gGameApp:requestServer("/game/yy/snowball/end",function (tb)
						self:showGmameEnd(point)
					end, self.activityId, point, playTimeMax, self.isGuide == 0 and 1 or 0, self.csvId)
				end
			end,
			callFunc = function()
				self.playTime = time.getTime() - beignTime
				spendTime = spendTime + 1
				if math.abs(self.playTime - spendTime) > timeDelta then
					gGameUI:showTip(gLanguageCsv.cheat_error)
					performWithDelay(self, function()
						self:gameOver()
						self:onClose()
					end, 3)
					return false
				end
			end
		}
	})
end

--引导的倒计时逻辑 与普通逻辑不通 正常游戏基于正常时间 引导会有暂停
function SnowBallGame:initGuideCountDown()
	local beignTime = time.getTime()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local playTimeMax = 30
    bind.extend(self, self.textCountDown, {
		class = 'cutdown_label',
		props = {
			time = playTimeMax,
			str_key = "short_clock_str",
			endFunc = function()
				if self.gaming then
					self:gameOver()
					local point = self.point:read()
					gGameApp:requestServer("/game/yy/snowball/end",function (tb)
						self:showGmameEnd(point)
					end, self.activityId, point, playTimeMax, self.isGuide == 0 and 1 or 0, self.csvId)
				end
			end,
			callFunc = function()
				self.playTime = time.getTime() - beignTime
			end
		}
	})
end

--倒计时
function SnowBallGame:startCount()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local playTimeMax = yyCfg.paramMap.playTimeMax
	if self.isGuide == 0 then
		playTimeMax = 30
	end
	self.textCountDown:text(time.getCutDown(playTimeMax).short_clock_str)
	self.panelCountDown:show()
	self.rockerPanel:hide()
	local num = 3
	local textNum = self.panelCountDown:get("textNum")
	textNum:text(num)
	adapt.oneLineCenterPos(cc.p(self.panelCountDown:width() / 2, self.panelCountDown:height() / 2), {self.panelCountDown:get("textNote"), self.panelCountDown:get("textNum")})
	self:schedule(function (dt)
		if num > 0 then
			local text = textNum
			textNum:text(num)
			textNum:scale(1.3)
			textNum:runAction(cc.ScaleTo:create(0.5, 1))

			adapt.oneLineCenterPos(cc.p(self.panelCountDown:width() / 2, self.panelCountDown:height() / 2), {self.panelCountDown:get("textNote"), self.panelCountDown:get("textNum")})
			num = num - 1
		else
			self:gameStart()
			return false
		end
	end, 1, 0, 663)
end

function SnowBallGame:gameStart()
	self.panelCountDown:hide()
	gGameApp:requestServer("/game/yy/snowball/start",function (tb)
		self.gaming = true

		self.rockerPanel:show()
		self:createSprite()
		self:createRocker()
		self:startSnowBallAndGift()
		if self.isGuide == 0 then
			self:createGuide(1,function() end)
			performWithDelay(self, function()
				self:createGuide(2, self.initGuideCountDown)
			end, 1)
		else
			self:initCountDown()
		end
	end, self.activityId, self.isGuide)
end

function SnowBallGame:gameOver( )
	self.gaming = false
	self.rockerPanel:hide()
	self.bg:stopAllActions()
	self:disableSchedule()
	self.rockerPanel:unscheduleUpdate()
	self:stopAllActions()
	for i = 1, 5 do
		self["cannon"..i]:stopAllActions()
		self["cannon"..i]:play("effect_loop")
	end
	--捡礼物
	for i, giftData in pairs(self.tGift) do
		giftData.lihe:stopAllActions()
	end
	--雪球碰撞
	for i, snowBallData in pairs(self.tSnowBall) do
		snowBallData.snowBall:stopAllActions()
		snowBallData.snowBallDi:stopAllActions()
	end
end

function SnowBallGame:showGmameEnd(point)
	local showNew =  point > self.topPoint
	gGameUI:stackUI("city.activity.snow_ball.game_over", nil, {blackLayer = true}, self, point, showNew, self.isGuide)
end

function SnowBallGame:startSnowBallAndGift( )
	local tData = {}
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local huodongID = yyCfg.huodongID
	for i, v in orderCsvPairs(csv.yunying.snowball_stage) do
		if  v.huodongID == huodongID then
			local data = csvClone(v.dropsTempo)
			data.timeScore = v.timeScore
			tData[v.timing] =data
		end
	end
	local timeStage = 0 --当前时间状态
	local starTime = 0 --起始时间
	local duration = 0 --持续时间

	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local playTimeMax = yyCfg.paramMap.playTimeMax
	local addPoint = 0
	self.ballGuideDelay = 0
	self.giftGuideDelay = 0
	self:schedule(function(dt)
		if self.playTime <= timeStage then
			return
		end
		local change = true
		starTime = timeStage
		for time = 1, playTimeMax do
			if tData[time] then
				if self.playTime > timeStage and self.playTime <= time then
					timeStage = time
					duration = timeStage - starTime
					break
				end
			end
		end

		local stageData = tData[timeStage] or {}
		self.point:modify(function(val)
			return true, val + addPoint
		end)
		addPoint = stageData.timeScore or 0
		for csvId, num in pairs(stageData) do
			if csvId ~= "effect" and csvId ~= "timeScore" then
				if csv.yunying.snowball_element[csvId].belongs == 1 then
					self:createSnow(num, csvId, duration)
				elseif csv.yunying.snowball_element[csvId].belongs == 2 then
					self:createGift(num, csvId, duration)
				end
			end
		end
		if math.abs(self.giftGuideDelay - self.ballGuideDelay) < 1 then
			if self.giftGuideDelay < self.ballGuideDelay then
				self.ballGuideDelay = self.ballGuideDelay + 1
			else
				self.giftGuideDelay = self.giftGuideDelay + 1
			end
		end
		if not self.hasGuide4 and self.isGuide == 0 then
			performWithDelay(self, function()
				self:createGuide(4, function() end)
			end, self.giftGuideDelay + 1)
			self.hasGuide4 = true
		end
		if not self.hasGuide3 and self.isGuide == 0 then
			performWithDelay(self, function()
				self:createGuide(3, function() end)
			end, self.ballGuideDelay + 1)
			self.hasGuide3 = true
		end


		if stageData.effect then
			self.cannon1:play(stageData.effect)
			performWithDelay(self.cannon2,function()
				self.cannon2:play(stageData.effect)
			end, 0.25)
			performWithDelay(self.cannon3,function()
				self.cannon3:play(stageData.effect)
			end, 0.5)
			self.cannon4:play("effect_loop")
			performWithDelay(self.cannon5,function()
				self.cannon5:play("effect_loop")
			end, 0.25)
		end
	end, 0.5, 0, 667)
end

function SnowBallGame:createCannon(num, csvId, duration)
	self.cannon1 = widget.addAnimationByKey(self.bg, "snow_ball/shengdan_tankemiaomiao.skel", nil, "standby_loop", 5)
		:xy(780, 650)
		:z(10000)
		:scale(1.1)
	self.cannon2 = widget.addAnimationByKey(self.bg, "snow_ball/shengdan_tankemiaomiao.skel", nil, "standby_loop", 5)
		:xy(660, 425)
		:z(10000)
		:scale(1.3)
	self.cannon3 = widget.addAnimationByKey(self.bg, "snow_ball/shengdan_tankemiaomiao.skel", nil, "standby_loop", 5)
		:xy(540, 200)
		:z(10000)
		:scale(1.5)
	self.cannon4 = widget.addAnimationByKey(self.bg, "snow_ball/shengdanxinshiniao.skel", nil, "standby_loop", 5)
		:xy(1150, 600)
		:z(10000)
		:scale(1.8)
	self.cannon5 = widget.addAnimationByKey(self.bg, "snow_ball/shengdanxinshiniao.skel", nil, "standby_loop", 5)
		:xy(1080, 350)
		:z(10000)
		:scale(2)
end

function SnowBallGame:createSnow(num, csvId, duration)
	self.ballGuideDelay = duration
	for i = 1, num do
		local delayTime = math.random(0, duration * 100) /100
		self.ballGuideDelay = math.min(delayTime, self.ballGuideDelay)
		local x, y = math.random(self.posTable[1].x, self.posTable[4].x), math.random(self.posTable[1].y, self.posTable[2].y)
		local delayAction = cc.DelayTime:create(delayTime)
		self.bg:runAction(cc.Sequence:create(delayAction,cc.CallFunc:create(
			function()
				local snowBall = widget.addAnimationByKey(self.bg, "snow_ball/shengdan_xueqiu.skel", nil, "effect", 5)
					:xy(x, y)
					:z(10000 - y)
					:scale(0.8)
				local snowBallDi = widget.addAnimationByKey(self.bg, "snow_ball/shengdan_xueqiu.skel", nil, "effect_di", 5)
					:xy(x, y)
					:z(10000 - y - 1)
					:scale(0.8)
				table.insert(self.tSnowBall, {snowBall = snowBall, snowBallDi = snowBallDi, x = x, y = y, time = getTimeBySocket()})
			end
		)))
	end
end

function SnowBallGame:createGift(num, csvId, duration)
	local stayTime = csv.yunying.snowball_element[csvId].attr.stayTime
	self.giftGuideDelay = duration
	for i = 1, num do
		local delayTime = math.random(0, duration * 100) / 100
		self.giftGuideDelay = math.min(delayTime, self.giftGuideDelay)
		local x, y = math.random(self.posTable[1].x, self.posTable[4].x), math.random(self.posTable[1].y, self.posTable[2].y)
		local delayAction = cc.DelayTime:create(delayTime)
		self.bg:runAction(cc.Sequence:create(delayAction,cc.CallFunc:create(
			function()
				local lihe = widget.addAnimationByKey(self.bg, "snow_ball/lihe.skel", nil, "effect", 5)
					:xy(x, y)
					:z(10000 - y)
				lihe:setSpriteEventHandler(function(event, eventArgs)
				lihe:play("standby_loop")
				end, sp.EventType.ANIMATION_COMPLETE)
				table.insert(self.tGift, {lihe = lihe, x = x, y = y, csvId = csvId, endTime = getTimeBySocket() + (stayTime + 1) * 1000, time = getTimeBySocket()})
			end
		)))
	end
end

function SnowBallGame:createRocker(sender, event)
	self.rockerXY = cc.p(600, 250) --未触摸的初始位置
	self.cos = 0
	self.sin = 0
	self.r = 0
	if not self.rockerBg then
		self.rockerBg = ccui.ImageView:create("activity/snow_ball/btn_xqdbs_yg1.png")
			:addTo(self.rockerPanel)
			:z(100)
			:anchorPoint(0.5,0.5)
		self.rocker = ccui.ImageView:create("activity/snow_ball/btn_xqdbs_yg2.png")
			:addTo(self.rockerBg)
			:alignCenter(self.rockerBg:size())
			:z(1)
			:anchorPoint(0.5,0.5)
	end
	if sender == nil then
		self.rockerBg:xy(self.rockerXY)
		local dx = adapt.dockWithScreen(self.rockerBg, "left", "down")
		self.sprite:play("shengdan_standby_loop")
	else
		self.startPos = self.rockerPanel:convertToNodeSpace(event)
		self.rockerBg:xy(self.startPos)
		self.sprite:play("shengdan_run_loop")
	end

	--碰撞检测
	local giftWidth = 130
	local snowWidth = 60
	local length = self.spriteShadow:getBoundingBox().width
	self.rockerPanel:scheduleUpdate(function(detal)
		self:moveSprite()
		local x, y = self.spriteShadow:xy()

		--礼物自动消失
		for i, giftData in pairs(self.tGift) do
			if getTimeBySocket() > giftData.endTime then
				giftData.lihe:removeSelf()
				self.tGift[i] = nil
				break
			end
		end
		--捡礼物
		for i, giftData in pairs(self.tGift) do
			local inTime = getTimeBySocket() - giftData.time > 800
			local gx, gy = giftData.x, giftData.y
			local distance = math.sqrt((gx - x) * (gx - x) + (gy - y) * (gy - y))
			if math.sqrt((gx - x) * (gx - x) + (gy - y) * (gy - y)) - length/2 < giftWidth/2 and inTime then
				self:getGift(giftData.csvId)
				self.tGift[i] = nil
				giftData.lihe:play("effect_zhakai")
				giftData.lihe:setSpriteEventHandler(function(event, eventArgs)
					performWithDelay(giftData.lihe,function(  )
						if giftData and giftData.lihe then
							giftData.lihe:removeSelf()
						end
					end,0)
				end, sp.EventType.ANIMATION_COMPLETE)
				break
			end
		end
		--雪球碰撞
		for i, snowBallData in pairs(self.tSnowBall) do
			local gx, gy = snowBallData.x, snowBallData.y
			if getTimeBySocket() - snowBallData.time > 2000 then
				snowBallData.snowBall:removeSelf()
				snowBallData.snowBallDi:removeSelf()
				self.tSnowBall[i] = nil
				break
			end
		end
		for i, snowBallData in pairs(self.tSnowBall) do
			local inTime = (getTimeBySocket() - snowBallData.time) > 1400 and (getTimeBySocket() - snowBallData.time) < 1600
			local gx, gy = snowBallData.x, snowBallData.y
			local distance = math.sqrt((gx - x) * (gx - x) + (gy - y) * (gy - y))
			if distance - length/2 < snowWidth/2 and inTime then
				snowBallData.snowBall:removeSelf()
				snowBallData.snowBallDi:removeSelf()
				self.tSnowBall[i] = nil
				self:beHit()
				break
			end
		end
	end)
end


function SnowBallGame:removeRocker( )
	self.rockerBg:xy(self.rockerXY)
	local dx = adapt.dockWithScreen(self.rockerBg, "left", "down")

	local centerX = self.rockerBg:width() /2
	local centerY = self.rockerBg:height() /2
	self.rocker:xy(centerX, centerY)
	self.cos = 0
	self.sin = 0
	self.sprite:play("shengdan_standby_loop")
end

function SnowBallGame:moveRocker(sender, event)
	local maxR = 135 --圆的最大半径
	local pos = self.rockerPanel:convertToNodeSpace(event)
	local deltaX = pos.x - self.startPos.x
	local deltaY = pos.y - self.startPos.y
	local xie = math.sqrt(math.pow(deltaX, 2) + math.pow(deltaY , 2))
	local r = math.min(xie, maxR)
	self.cos = deltaX / xie
	self.sin = deltaY / xie
	self.r = r / maxR
	local x = r * self.cos
	local y = r * self.sin
	local centerX = self.rockerBg:width() /2
	local centerY = self.rockerBg:height() /2
	self.rocker:xy(centerX + x, centerY + y)
end

function SnowBallGame:moveSprite()
	local moveSpeed = self.attr.speed
	local oriX, oriY = self.spriteShadow:xy()
	local moveX = moveSpeed * self.cos * self.r
	local moveY = moveSpeed * self.sin * self.r
	local x = oriX + moveX
	local y = oriY + moveY
	if moveX < 0 then
		self.spriteShadow:get("imgSel"):scaleX(-1)
	elseif moveX > 0 then
		self.spriteShadow:get("imgSel"):scaleX(1)
	end
	if dataEasy.checkInRect({[1] = self.posTable}, cc.p(x, y)) == 1 then
		self.spriteShadow:xy(x, y):z(10000- y)
	else
		--移出界外优化
		for i = 1, 4 do
			local ii = (i == 4) and 1 or (i + 1)
			local pos = getIntersection({cc.p(oriX, oriY), cc.p(x,y)},{self.posTable[i], self.posTable[ii]})
			if pos then
				if i == 1 then
					pos.y = pos.y + moveSpeed * self.sin
				elseif i == 2 then
					pos.x = pos.x + moveSpeed * self.cos
				elseif i == 3 then
					pos.y = pos.y + moveSpeed * self.sin
				else
					pos.x = pos.x + moveSpeed * self.cos
				end
				pos.x = math.max(self.posTable[1].x, pos.x)
				pos.x = math.min(self.posTable[3].x, pos.x)
				pos.y = math.min(self.posTable[1].y, pos.y)
				pos.y = math.max(self.posTable[3].y, pos.y)
				self.spriteShadow:xy(pos):z(10000- y)
			end
		end
	end
end
--被击中
function SnowBallGame:beHit()
	self.myLife:modify(function(val)
		return true, val - 1 < 0 and 0 or val - 1
	end)
	self.spriteShadow:runAction(cc.Sequence:create(cc.Blink:create(1, 5), cc.Show:create()))
	self.sprite:play("hit")
	self.sprite:setSpriteEventHandler(function(event, eventArgs)
		if self.rockerPanel:isVisible() and self.gaming then
			self.sprite:play("shengdan_run_loop")
		else
			self.sprite:play("shengdan_standby_loop")
		end
	end, sp.EventType.ANIMATION_COMPLETE)
end
--捡到礼物
function SnowBallGame:getGift(csvId)
	self.point:modify(function(val)
		return true, val + csv.yunying.snowball_element[csvId].attr.value
	end)
end

--初始化引导
function SnowBallGame:createGuide(index, guideEndCb)
	local function createMask(pos, offsetX)
		local maskPanel = ccui.Layout:create()
			:size(display.sizeInView.width, display.sizeInView.height)
			:anchorPoint(0.5,0.5)
			:xy(display.center)
			:addTo(self, 1)
		local texR = ccui.ImageView:create("login/new_character/img_tjltm@.png")
			:xy(pos.x + offsetX + 800, pos.y >  display.sizeInView.height/2 and pos.y - 200 or pos.y + 200)
			:addTo(maskPanel, 2)
		local textBg = ccui.ImageView:create("city/gate/bg_dialog.png")
		textBg:setScale9Enabled(true)
		textBg:setCapInsets({x = 77, y = 58, width = 1, height = 1})
		textBg:addTo(texR)
		textBg:xy(-160, 200)
		textBg:width(500)

		local txt = rich.createWithWidth("#C0x5b545b#" .. guide_config[index].content, 40, nil, 450)
			:anchorPoint(0, 0)
			:addTo(textBg, 3, "talkContent")
			:xy(25, 50)
		textBg:height(txt:height() + 80)
		return maskPanel
	end

	local targetNode = guide_config[index] and self[guide_config[index].nodeName]
	if targetNode then
		targetNode:show()
		local size = targetNode:box()
		local pos = gGameUI:getConvertPos(targetNode)
		local anchorPoint = targetNode:anchorPoint()
		pos.x = pos.x - anchorPoint.x * size.width + display.uiOrigin.x
		pos.y = pos.y - anchorPoint.y * size.height
		local maskPanel = createMask(pos, (1 - anchorPoint.x) * size.width)
		-- 设置裁剪区域
		local bgRender = cc.RenderTexture:create(display.sizeInView.width, display.sizeInView.height)
			:addTo(maskPanel, 1, "bgRender")
		local colorLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 150), display.sizeInView.width, display.sizeInView.height)
		local stencil = ccui.Scale9Sprite:create()
		local width = size.width
		local height = size.height
		colorLayer:retain()
		stencil:retain()
		stencil:initWithFile(cc.rect(80, 80, 1, 1), "other/guide/icon_mask.png")
		stencil:anchorPoint(0.5, 0.5)
			:size(width, height)
			:xy(pos.x+size.width/2, pos.y+size.height/2)
		stencil:setBlendFunc({src = GL_DST_ALPHA, dst = 0})

		-- 设置遮罩表现
		local scaleX = display.sizeInView.width*2/size.width
		local scaleY = display.sizeInView.height*2/size.height
		local scale = math.max(scaleX, scaleY)
		stencil:scale(scale)

		bgRender:begin()
		colorLayer:visit()
		stencil:visit()
		bgRender:endToLua()

		local isNormal = false
		local scaleDt = scale - 1
		self:schedule(function(dt)
			scale = scale - (dt / 0.3) * scaleDt
			if not isNormal then
				if scale <= 1 then
					scale = 1
					isNormal = true
					display.director:pause()
				end
				stencil:scale(scale)
				bgRender:beginWithClear(0, 0, 0, 0)
				colorLayer:visit()
				stencil:visit()
				bgRender:endToLua()
			else
				colorLayer:release()
				stencil:release()
				return false
			end
		end, 1/30, 0, "guideCircleAni")
		maskPanel:setBackGroundColorOpacity(0)
		local clickLayer = cc.LayerColor:create(cc.c4b(255, 0, 255, 150), display.sizeInView.width, display.sizeInView.height)
			:addTo(maskPanel, 2)
		local isHit = false
		clickLayer:hide()
		local listener = cc.EventListenerTouchOneByOne:create()
		local eventDispatcher = clickLayer:getEventDispatcher()
		local touchBeganPos = cc.p(0, 0)
		local function transferTouch(event)
			listener:setEnabled(false)
			eventDispatcher:dispatchEvent(event)
			listener:setEnabled(true)
		end
		local function onTouchBegan(touch, event)
			return true
		end
		local function onTouchMoved(touch, event)
			transferTouch(event)
		end
		local function onTouchEnded(touch, event)
			display.director:resume()
			guideEndCb(self)
			if maskPanel and isNormal then
				maskPanel:removeFromParent()
				maskPanel = nil
			end
		end
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
		listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
		listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
		listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_CANCELLED)
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, clickLayer)
	else
		createMask()
		guideEndCb(self)
	end

end

function SnowBallGame:onClose( )
	display.director:resume()
	ViewBase.onClose(self)
end
return SnowBallGame