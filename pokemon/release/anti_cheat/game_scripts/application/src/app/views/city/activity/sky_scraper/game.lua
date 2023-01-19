--盖楼
local ViewBase = cc.load("mvc").ViewBase
local SkyScraperGameView = class("SkyScraperGameView",ViewBase)

SkyScraperGameView.RESOURCE_FILENAME = "sky_scraper_game.json"
SkyScraperGameView.RESOURCE_BINDING = {
	["bgPanel"] = "background",
	["panelCountDown"] = "panelCountDown",
	-----------------------rightPanel---------------------------------
	["info"] = "info",
	["info.imgSm"] = "imgSm",
	["info.score"] = {
		varname = "scoreNum",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("point"),
			},
			{
				event = "effect",
				data = {outline = {color = cc.c4b(241, 61, 86, 255),  size = 4}}
			},
		},
	},
	["info.scoreText"] = {
		varname = "scoreText",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(241, 61, 86, 255),  size = 4}}
		},
	},
	----------------------leftPanel----------------------------
	["rolePanel.word"] = "word",
	["rolePanel.car.txt"] = "floorTxt",
	----------------------centerPanel--------------------------
	["centerPanel"] = "centerPanel",
	["centerPanel.bar"] = {
		varname = "bar",
		binds = {
		  		event = "extend",
		  		class = "loadingbar",
		  		props = {
				data = bindHelper.self("curPagePro"),
		  	},
		}
	  },
	["centerPanel.hook"] = "hook",
	["btnDown"] = {
		varname = "btnDown",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDown")}
		},
	},
	["centerPanel.basePanel"] = "basePanel",
}

local maxLife = 3 			--最大生命
local downSpeed = 900		--楼层掉落速度
local baseDownTime = 0.3	--视野上升时间
local waggleFloorNum = 12 	--影响晃动层数
local waggleTime = 0.8		--单次晃动时间
local offsetX = 120          --掉落X轴偏移系数
local houseScale = 1.5 -- 房子缩放
local floorHeight = 155 * houseScale --单层高度
local floorWidth = 271 * houseScale	--单层宽度
local beginMovewFloor = 3   --起始移动楼层
local backgroundWidth = 3120	--背景宽
local backgroundHeight = 1440	--背景高
local speedCoefficient = 400	--速度系数
local WORD_TYPE = {			--评分类型
	FAILURE = 0,
	GENERAL = 1,
	GOOD = 2,
	PERFECT = 3,
}

function SkyScraperGameView:onCreate(activityId)
	self.activityId = activityId
	self.gameEnd = false
	self.btnDown:z(15000)
	self:enableSchedule()
	self:initModel()
	self:addBackgroundSpine()
	self:startCount()
	self:initLife()
	self:createFirstFloor()
end

function SkyScraperGameView:initModel()
	self.point = idler.new(0) --分数
	self.floor = idler.new(0) --层数
	self.myLife = idler.new(maxLife)
	self.curPagePro = idler.new(0) --进度条
	self.perfectNum = 0
	self.moveSpeed = 1
	self.awardFloor = {} --奖励楼层
	self.maxRotate = 20		--最大晃动角度
	self.word:visible(false)
    local yyhuodongs = gGameModel.role:read("yyhuodongs")
	local yydata = yyhuodongs[self.activityId] or {}
	local yycfg = csv.yunying.yyhuodong[self.activityId]
	self.highpoint = yydata.info.high_points or 0
	self.huodongID = yycfg.huodongID
	self.tOverLap = {} 	-- 重叠样本
	self.overlap = 100 	-- 平均重叠
	self.hookDir = "right" -- 钩子移动方向
	adapt.oneLinePos(self.scoreText, self.scoreNum, cc.p(5,0), "left")
    idlereasy.when(self.myLife, function(_, myLife)
		for i = 1 , 3  do
			if i > myLife then
				-- self.tImgSm[i]:texture("activity/sky_scraper/icon_mjh.png")
				cache.setShader(self.tImgSm[i], false, "hsl_gray")
			end
		end
		if myLife == 0 then
			performWithDelay(self, function()
				self:gameOver(0)
			end, 0.8)
		end
	end)
	idlereasy.when(self.floor, function(_, floor)
		local yycfg = csv.yunying.yyhuodong[self.activityId]
		local paramMap = yycfg.paramMap or {}
		self.maxFloor = paramMap.maxFloor
		self.floorTxt:text(floor..gLanguageCsv.skyScraperFloor)
		if floor == self.maxFloor then
			performWithDelay(self, function()
				self:gameOver(0)
			end, 0.8)
		end
		--移动速度
		for k, v in orderCsvPairs(csv.yunying.skyscraper_floors) do
			if v.huodongID == self.huodongID then
				if v.range[1] <= floor and v.range[2] > floor then
					self.moveSpeed = v.hookSpeed * speedCoefficient
					self.maxRotate = v.maxRotate
				end
			end
		end
		--随机奖励楼层 可能是spine修改
		for k, v in pairs(self.awardFloor) do
			if floor == v.floor then
				if v.res ~= "" then
					local pos = self.basePanel:getChildByName("house"..floor - 1):box()
					self.award = cc.Sprite:create(v.res)
					self.award:addTo(self.basePanel,1000,"award"..floor)
						:xy(pos.x + pos.width * 0.5,pos.y + pos.height * 0.5 + 200)
						:scale(houseScale)
				end
				break
			elseif floor == v.floor + 1 then
				if self.award then
					self.award:removeSelf()
					self.award = nil
				end
			end
		end
	end)
end

--右上角生命显示信息
function SkyScraperGameView:initLife()
    local imgSm = self.imgSm
	self.tImgSm = {[1] = self.imgSm}
	for i = 2, 3  do
		local newImg = imgSm:clone():addTo(imgSm:getParent())
			:xy(imgSm:x() + 160 * (i - 1), imgSm:y())
		table.insert(self.tImgSm, newImg)
	end
end

function SkyScraperGameView:updateOverLap(res)
	--取偏移平均值
	local posY = self.basePanel:y()
	if #self.tOverLap >= waggleFloorNum then
		table.remove(self.tOverLap, 1)
	end
	table.insert(self.tOverLap, res)

	local overlap = 0
	for i, v in ipairs(self.tOverLap) do
		overlap = overlap + v
	end
	self.overlap = overlap / #self.tOverLap
end

--默认第一层
function SkyScraperGameView:createFirstFloor( )
	local floor = self.floor:read()
	local cfg = csv.yunying.skyscraper_resources
	local houseResource, resType
	for k, v in orderCsvPairs(cfg) do
		if v.huodongID == self.huodongID then
			if v.range[1] <= floor and v.range[2] > floor then
				if itertools.size(v.pngResource) == 0 then
					local len = itertools.size(v.spineResource)
					houseResource = v.spineResource[math.random(1, len)]
					resType = "spine"
				else
					local len = itertools.size(v.pngResource)
					houseResource = v.pngResource[math.random(1, len)]
					resType= "png"
				end
				break
			end
		end
	end
	local house
	local name = "house" .. self.floor:read()
	if resType == "png" then
		house = cc.Sprite:create(houseResource)
		house:xy(self.basePanel:width()/2 , 0)
			:anchorPoint(0.5, 0)
			:addTo(self.basePanel, 10000, name)
			:scale(houseScale)
	elseif self.topHouse.resType == "spine" then
		house = widget.addAnimationByKey(self.basePanel, houseResource, name, "effect_loop", 10)
		house:xy(self.basePanel:width()/2 , 0)
			:anchorPoint(0.5, 0)
			:scale(houseScale)
	end
	self.floor:set(self.floor:read() + 1)
end

-- 创建掉落房子
function SkyScraperGameView:createDroppingHouse()
	local topHouse = self.housePanel
	local anchorY = topHouse:anchorPoint().y
	local pos = topHouse:getParent():convertToWorldSpace(cc.p(topHouse:x(), topHouse:y() - floorHeight * anchorY))
	pos = self.centerPanel:convertToNodeSpace(pos)
	local droppingHouse = ccui.Layout:create()
		:size(floorWidth, floorHeight)
		:addTo(self.centerPanel, 0, "house" .. self.floor:read())
		:anchorPoint(0.5, 0)
		:xy(pos.x, pos.y)
	if self.topHouse.resType == "png" then
		local house = cc.Sprite:create(self.topHouse.houseResource)
		house:xy(pos.x , pos.y)
			:anchorPoint(0.5, 0.5)
			:addTo(droppingHouse)
			:xy(floorWidth/2, floorHeight/2)
			:scale(houseScale)
	elseif self.topHouse.resType == "spine" then
		local hosue  = widget.addAnimationByKey(droppingHouse, self.topHouse.houseResource, "house", "effect_loop", 10)
			:xy(floorWidth/2, floorHeight/2 - 120)
			:anchorPoint(0.5, 0.5)
			:scale(houseScale)
	end
	return droppingHouse
end

function SkyScraperGameView:createTopHousePanel()
	self.housePanel= ccui.Layout:create()
		:size(floorWidth, floorHeight)
		:addTo(self.hook, 0, "housePanel")
		:anchorPoint(0.5, 0.9)
		:xy(self.hook:width()/2, 30)
end

--上方钩子运动
function SkyScraperGameView:runTopHookAction()
	local moveTime = 1200 / self.moveSpeed -- 运动时间
	self.hook:stopActionByTag(888)
	self.housePanel:stopActionByTag(777)
	if self.hookDir == "right" then
		local actionMove = cc.MoveTo:create(moveTime, cc.p(1100, 1310))
		local action1 = cc.Sequence:create(cc.EaseSineInOut:create(actionMove), cc.CallFunc:create(function()
			self.hookDir = "left"
			self:runTopHookAction()
		end))
		local action2 = cc.EaseInOut:create(cc.RotateTo:create(moveTime, -10), moveTime)
		self.hook:runAction(action1)
		self.housePanel:runAction(action2)
		action1:setTag(888)
		action2:setTag(777)
	else
		local actionMove = cc.MoveTo:create(moveTime, cc.p(-100, 1310))
		local action1 = cc.Sequence:create(cc.EaseSineInOut:create(actionMove), cc.CallFunc:create(function()
			self.hookDir = "right"
			self:runTopHookAction()
		end))
		local action2 = cc.EaseInOut:create(cc.RotateTo:create(moveTime, 10), moveTime)
		self.hook:runAction(action1)
		self.housePanel:runAction(action2)
		action1:setTag(888)
		action2:setTag(777)
	end
end

--上方钩子的房子
function SkyScraperGameView:createTopHouse()
	--还需要加判断来随机房子房顶
	if self.floor:read() == self.maxFloor then
		return
	end
	--还需要加判断来随机房子房顶
	local floor = self.floor:read()
	local cfg = csv.yunying.skyscraper_resources
	local houseResource, resType
	for k, v in orderCsvPairs(cfg) do
		if v.huodongID == self.huodongID then
			if v.range[1] <= floor and v.range[2] > floor then
				if itertools.size(v.pngResource) == 0 then
					local len = itertools.size(v.spineResource)
					houseResource = v.spineResource[math.random(1, len)]
					resType = "spine"
				else
					local len = itertools.size(v.pngResource)
					houseResource = v.pngResource[math.random(1, len)]
					resType= "png"
				end
			end
		end
	end
	if self.topHouse then
		self.topHouse:removeSelf()
		self.topHouse = nil
	end
	if resType == "png" then
		self.topHouse = cc.Sprite:create(houseResource)
			:anchorPoint(0.5, 0.5)
			:addTo(self.housePanel)
			:xy(floorWidth/2, floorHeight/2)
			:scale(houseScale)
	else
		self.topHouse = widget.addAnimationByKey(self.housePanel, houseResource, "house", "effect_loop", 10)
			:xy(floorWidth/2, floorHeight/2 - 120)
			:anchorPoint(0.5, 0.5)
			:scale(houseScale)
	end
	self.topHouse.houseResource = houseResource
	self.topHouse.resType = resType
	self.topHouse:show()
end

--房子摇晃
function SkyScraperGameView:startWaggle(first)
	self.basePanel:stopActionByTag(666)
	local endRotate = nil
	if self.rotateDir == "right" then
		endRotate = - (100 - self.overlap) * self.maxRotate / 100
	else
		endRotate =(100 - self.overlap) * self.maxRotate / 100
	end
	local curRotate = self.basePanel:getRotation()
	local spendTime = first and waggleTime or waggleTime * 2
	if self.rotateDir == "right" then
		local rotateAction = cc.Sequence:create(cc.RotateTo:create(spendTime, endRotate), cc.CallFunc:create(function()
			self.rotateDir = "left"
			self:startWaggle(false)
		end))
		rotateAction:setTag(666)
		self.basePanel:runAction(cc.EaseInOut:create(rotateAction, spendTime))
	else
		local rotateAction = cc.Sequence:create(cc.RotateTo:create(spendTime, endRotate), cc.CallFunc:create(function()
			self.rotateDir = "right"
			self:startWaggle(false)
		end))
		rotateAction:setTag(666)
		self.basePanel:runAction(cc.EaseInOut:create(rotateAction, spendTime))
	end
end

--按钮
function SkyScraperGameView:onDown()
	--掉落期间不能按
	if (not self.topHouse:isVisible()) or self.gameEnd then
		return
	end

	self:unSchedule(100)
	self.topHouse:hide()
	local droppingHouse = self:createDroppingHouse()
	local floor = self.floor:read()

	local droppingFloor = floor --掉落的楼层
	if floor >  waggleFloorNum then
		droppingFloor = waggleFloorNum
	end
	local moveTime  = (droppingHouse:y() - (floorHeight * droppingFloor + self.basePanel:y())) / downSpeed

	local hookXOffset = (600 - math.abs(self.hook:x() - 500)) / 600 * (self.moveSpeed / speedCoefficient) * offsetX + 30
	local moveX = self.hookDir == "right" and  hookXOffset or - hookXOffset
	local moveXAction = cc.MoveBy:create(moveTime, cc.p(moveX, 0))
	local moveYAction = cc.MoveBy:create(moveTime, cc.p(0,  floorHeight * droppingFloor + self.basePanel:y() - droppingHouse:y()))
	droppingHouse:runAction(cc.Spawn:create(moveXAction, cc.EaseSineIn:create(moveYAction)))

	local rotateAction = cc.RotateTo:create(0.2, 0)
	droppingHouse:runAction(rotateAction)

	--延迟操作
	performWithDelay(self, function()
		local function newTurn()
			self:createTopHouse()
			self:updateTime()
		end
		if self:calculate() then
			local floor = self.floor:read() --总层数
			self.basePanel:height(floorHeight * floor)
			if floor >= waggleFloorNum then
				local anchorFloor = floor - waggleFloorNum --锚点所在楼层
				self.basePanel:anchorPoint(0.5, anchorFloor/ floor)
				self.basePanel:y(self.basePanel:y() + floorHeight)
			end

			if floor > 2 then
				--背景和楼层移动
				if floor == waggleFloorNum then
					self.basePanel:y(self.basePanel:y() - floorHeight)
				end
				if floor == beginMovewFloor then
					self.basePanel:y(self.basePanel:y() - floorHeight )
				end
				local endPos = self.basePanel:y()  - floorHeight
				local moveDown = cc.MoveTo:create(baseDownTime, cc.p(self.basePanel:x(), endPos))
				self.basePanel:runAction(cc.Sequence:create(moveDown, cc.CallFunc:create(function()
					newTurn()
				end)))
				local backgroundMoveDown =  -1 / self.maxFloor * self.background:height() * 0.75
				self.background:runAction(cc.MoveBy:create(baseDownTime, cc.p(0, backgroundMoveDown)))
			else
				newTurn()
			end
		end
	end, moveTime)
end

--灰尘
function SkyScraperGameView:addDroppingEffect(type, house)
	local x = 200
	local y = 220
	if self.topHouse.resType == "spine" then
		local effect1 = widget.addAnimationByKey(house, "skyscraper/floor_tx.skel", "bottom", "effecr_yanwu", 10)
			:xy(200, -20)
			:scale(houseScale)
	else
		local effect1 = widget.addAnimationByKey(house, "skyscraper/floor_tx.skel", "bottom", "effecr_yanwu", 10)
			:xy(200, 0)
			:scale(houseScale)
	end

	if 	type == WORD_TYPE.GENERAL then

	elseif type == WORD_TYPE.GOOD then
		if self.topHouse.resType == "spine" then
		end
		local effect = widget.addAnimationByKey(house, "skyscraper/floor_tx.skel", "word" ,"effect_good", 20)
			:xy(x, y)
			:scale(houseScale)
		self.word:visible(true)
		self.word:get("txt"):text(gLanguageCsv.skyscraperGood)
		performWithDelay(self, function()
			self.word:visible(false)
		end, 1)
	elseif type == WORD_TYPE.PERFECT then
		if self.topHouse.resType == "spine" then
			x = 0
		end
		local effect = widget.addAnimationByKey(house, "skyscraper/floor_tx.skel", "word" , "effect_perfect", 20)
			:xy(x, y)
			:scale(houseScale)
		self.word:visible(true)
		self.word:get("txt"):text(gLanguageCsv.skyscraperPerfect)
		performWithDelay(self, function()
			self.word:visible(false)
		end, 1)
		self.perfectNum = self.perfectNum + 1
	end
end

--计算接触面 判断是否掉落
function SkyScraperGameView:calculate()
	local house = self.centerPanel:getChildByName("house"..self.floor:read())
	local pos = house:getParent():convertToWorldSpace(cc.p(house:getPosition()))
	pos = self.basePanel:convertToNodeSpace(pos)

	local size = house:box()
	local lastHouse = self.basePanel:getChildByName("house"..(self.floor:read() - 1))
	local res =  (1 - math.abs((lastHouse:x() - pos.x)) / floorWidth ) * 100 --重叠率
	for k, v in orderCsvPairs(csv.yunying.skyscraper_accessment) do
		if v.huodongID == self.huodongID then
			if v.type == WORD_TYPE.FAILURE then
				--失败掉落
				if res <= v.contactRange then
					local endPosY = -300
					local moveTime = (house:y() - endPosY) / downSpeed * 0.75
					local moveDown = cc.MoveTo:create(moveTime, cc.p(house:x(), endPosY))
					house:runAction(cc.Sequence:create(moveDown, cc.CallFunc:create(function()
						house:removeSelf()
						self:updateTime()
						self:createTopHouse()
					end)))
					self.myLife:set(self.myLife:read() - 1)
					return false
				end
			elseif res <= v.contactRange then
				--掉落成功 把掉落的房子更改父节点到摇晃panel
				house:retain()
				house:removeFromParent()
				house:xy(pos.x , self.floor:read() * floorHeight)
				house:addTo(self.basePanel, 10000, "house" .. self.floor:read())
				house:release()
				self:addDroppingEffect(v.type, house)
				--删除看不到的房子
				if self.floor:read() > 5 then
					self.basePanel:removeChildByName("house" .. self.floor:read() - 5)
				end
				self:updateOverLap(res)
				self.point:set(self.point:read() + v.points)
				break
			end
		end
	end
	self.floor:set(self.floor:read() + 1)
	return true
end
--下方时间进度条
function SkyScraperGameView:updateTime()
	local time1 = 5
	local countdown = time1
	self:enableSchedule():unSchedule(100)
	self:schedule(function(dt)
		countdown = countdown - dt
		if countdown <= 0 then
			self:onDown()
			return false
		end
		self.curPagePro:set(math.min(countdown / time1) * 100,100)
	end, 0.01, 0, 100)
end
--防作弊
function SkyScraperGameView:checkCheat()
	local spendTime = 0
	local timeDelta = 20
	self:schedule(function(dt)
		spendTime = spendTime + 1
		self.playTime = time.getTime() - self.startTime
		if math.abs(self.playTime - spendTime) > timeDelta then
			gGameUI:showTip(gLanguageCsv.skyScraperTimeError)
			performWithDelay(self, function()
				-- self:gameOver(-1)
				self:onClose()
			end, 3)
			return false
		end
	end, 1, 0, 11)
end
--游戏中活动结束
function SkyScraperGameView:huodongTimeOut()
	local yyEndtime = gGameModel.role:read("yy_endtime")
	local endTime = yyEndtime[self.activityId]
	local spendTime = 0
	self:schedule(function(dt)
		spendTime = spendTime + 1
		if math.floor(endTime - time.getTime()) <= 0 then
			gGameUI:showTip(gLanguageCsv.flipCardFinishedClickTip)
			performWithDelay(self, function()
				self:onClose()
			end, 3)
			return false
		end
	end, 1, 0, 20)
end
--背景特效
function SkyScraperGameView:addBackgroundSpine()
	local effect = widget.addAnimationByKey(self.background:get("bg1"), "skyscraper/dieloufang_01.skel", "effect" , "effect_loop", 1)
			:anchorPoint(0.5, 0.5)
			:xy(780, 360)
	local effect1 = widget.addAnimationByKey(self.background:get("bg2"), "skyscraper/dieloufang_02.skel", "effect" , "effect_loop", 1)
			:anchorPoint(0.5, 0.5)
			:xy(780, 720)
	local effect2 = widget.addAnimationByKey(self.background:get("bg3"), "skyscraper/dieloufang_03.skel", "effect" , "effect_loop", 2)
			:anchorPoint(0.5, 0.5)
			:xy(780, 360)
	local effect3 = widget.addAnimationByKey(self.background:get("bg4"), "skyscraper/dieloufang_04.skel", "effect" , "effect_loop", 2)
			:xy(780, 0)
end
--倒计时321
function SkyScraperGameView:startCount()
    local yyCfg = csv.yunying.yyhuodong[self.activityId]
	self.panelCountDown:show()
	local num = 3
	local textNum = self.panelCountDown:get("textNum")
	textNum:text(num)
	self:createTopHousePanel()
	self:createTopHouse()
	adapt.oneLineCenterPos(cc.p(self.panelCountDown:width() / 2, self.panelCountDown:height() / 2), {self.panelCountDown:get("textNote"), self.panelCountDown:get("textNum")})
	self:schedule(function(dt)
		if num > 0 then
			self.btnDown:setTouchEnabled(false)
			local text = textNum
			textNum:text(num)
			textNum:scale(1.3)
			textNum:runAction(cc.ScaleTo:create(0.5, 1))
			adapt.oneLineCenterPos(cc.p(self.panelCountDown:width() / 2, self.panelCountDown:height() / 2), {self.panelCountDown:get("textNote"), self.panelCountDown:get("textNum")})
			num = num - 1
		else
			self:gameStart()
			self.btnDown:setTouchEnabled(true)
			return false
		end
	end, 1, 0, 663)
end

function SkyScraperGameView:gameStart()
	self.startTime = time.getTime()
	self.btnDown:setTouchEnabled(true)
	self.panelCountDown:hide()
	self:rangeFloor()
	self:runTopHookAction()
	self:updateTime()
	self:createTopHouse()
	self:startWaggle(true)
	self:checkCheat()
	self:huodongTimeOut()
end

function SkyScraperGameView:rangeFloor()
	for k, v in orderCsvPairs(csv.yunying.skyscraper_floors) do
		if v.huodongID == self.huodongID then
			local floor = math.random(v.range[1], v.range[2] - 1)
			table.insert(self.awardFloor, {floor = floor , res = v.awardsIcon} )
		end
	end
end
--游戏结束
function SkyScraperGameView:gameOver(cheat)
	self.hook:stopAllActions()
	self:enableSchedule():unSchedule(100)
	self.gameEnd = true
	--补充
	local showNew =  self.point:read() > self.highpoint
	local awardFloor = {}
	local count = 0
	for k, v in pairs(self.awardFloor) do
		if self.floor:read() > v.floor then
			table.insert( awardFloor,v.floor)
			if v.res ~= "" then
				count = count + 1
			end
		end
	end

	gGameApp:requestServerCustom("/game/yy/skyscraper/end")
		:onErrClose(function()
			self:onClose()
		end)
		:params( self.activityId, self.point:read(), self.floor:read(), self.perfectNum, 0, itertools.size(awardFloor))
		:doit(function(tb)
			gGameUI:stackUI("city.activity.sky_scraper.game_over", nil, {full = true}, self:createHandler("onClose"), self.activityId, self.point:read(), self.floor:read(), showNew, count, tb)
	end)
end

return SkyScraperGameView