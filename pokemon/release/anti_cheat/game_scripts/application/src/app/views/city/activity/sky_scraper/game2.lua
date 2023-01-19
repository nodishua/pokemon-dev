-- @date 2021-1-28
-- @desc 叠高楼

local DEBUG_SHOW
if device.platform == "windows" then
	-- DEBUG_SHOW = true
end

-- 钩子范围
local HOOK_RANGE = {-100, 1100}
local HOUSE_AREA = {width = 400/1.2, height = 230/1.2}
-- 每步的操作时间
local PROGRESS_TIME_STEP = 5
-- 显示层数，超过下移，可以为小数
local SHOW_FLOOR = 2.2
-- 第几层开始计算晃动
local SWING_MIN_FLOOR = 5
-- 晃动中心点取最后第X层 （如5）
local SWING_ROOT_FLOOR = 5
-- 晃动数据计算取最后Y层 （如4），完全重合为0，左为负数，则为
local SWING_CAL_FLOOR = 5
-- 幅度配置 K
local K = 1/10
-- 回弹比例 Q = 0.2
local Q = 0.8
-- 晃动比重 计算平均基础面积系数, 默认1
local SWING_POW = {3, 2}
-- 晃动力度，单边，(100% - 平均接触面积) 的倍数
local SWING_WIDTH = 500
-- 最大晃动宽度, 单边
local MAX_SWING_WIDTH = 200
-- 一定范围晃动可忽略
local INGORE_SWING_RANGE = 30
-- 掉落速度
local DROP_SPEED = 800
-- 屏幕下移速度
local FLOOR_DOWN_SPEED = 1000
-- 晃动速度
local SWING_SPEED = 40
-- 晃动周期时间
local SWING_TIME = 1.5
-- 钩子晃动角度
local HOOK_ANGLE = 20

local STATE = {
	READY = 0, -- 游戏开始准备
	MOVE = 1, -- 移动
	DROP = 2, -- 掉落
	GAME_OVER = 3, -- 游戏结束
}

local ViewBase = cc.load("mvc").ViewBase
local SkyScraperGameView = class("SkyScraperGame2View",ViewBase)

SkyScraperGameView.RESOURCE_FILENAME = "sky_scraper_game.json"
SkyScraperGameView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["panelCountDown"] = "panelCountDown",
	-----------------------rightPanel---------------------------------
	["info"] = "info",
	["info.imgSm"] = "imgSm",
	["info.score"] = {
		varname = "score",
		binds = {
			event = "text",
			idler = bindHelper.self("point")
		}
	},
	----------------------leftPanel----------------------------
	["rolePanel.world"] = "world",
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
			methods = {ended = bindHelper.self("onBtnDown")}
		},
	},
	["centerPanel.basePanel"] = "basePanel",
}

function SkyScraperGameView:onCreate(activityId)
	-- cc.Director:getInstance():setAnimationInterval(1.0 / 40)
	-- display.director:getScheduler():setTimeScale(3)
	-- self:getResourceNode():scale(0.5)

	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.skyScraper, subTitle = "SKY SCRAPER"})

	self.activityId = activityId
	self:enableSchedule()

	self:initLife()
	self:initModel()
	self:onStartCount()
end

function SkyScraperGameView:onUpdate(delta)
	if self.state ~= STATE.GAME_OVER then
		self.gameTime = self.gameTime + delta
	end
	if self.state ~= STATE.READY and self.state ~= STATE.GAME_OVER then
		self.btnDown:visible(self.state == STATE.MOVE)
		self:onProcessTime(delta)
		self:onSwing(delta)
		self:onTopHook(delta)
		self:onTopHouse(delta)
		self:onFloorDown(delta)
	end
end

function SkyScraperGameView:initModel()
	self.btnDown:hide()
	self.state = STATE.READY
	self.gameTime = 0
	self.progressTime = PROGRESS_TIME_STEP
	self.hookPos = cc.p(HOOK_RANGE[1], 1290)
	self.hookDir = 1
	self.houseData = {
		hookDy = -75, -- 放钩子的偏移y
	}
	self.basePanel:size(0, 0)
	if DEBUG_SHOW then
		-- 辅助 画点
		local point = cc.DrawNode:create()
		point:drawPoints({cc.p(0, 0)}, 1, 5, cc.c4f(1,0,0,1))
		point:addTo(self.basePanel, 10000, "testPoint")
	end

	self.baseData = {
		maxBasePanelY = self.basePanel:y() + (SHOW_FLOOR - 0.5) * HOUSE_AREA.height, -- 最高顶面
		basePanelY = self.basePanel:y(),
		swingFloor = 0, -- 当前晃动的最上层
		swingRootFloor = 0, -- 当前晃动锚点层
		swingDir = 0, -- 当前晃动方向
		swingDx = 0, -- 当前晃动距离
		swingRangeX = {0, 0}, -- 晃动X范围
		nextSwingFloor = 0,
		nextSwingRangeX = {0, 0}, -- 当晃动回正的时候再修改中心点和晃动范围
	}
	if DEBUG_SHOW then
		-- 辅助 画线
		local line = cc.DrawNode:create()
		line:drawLine(cc.p(0, self.baseData.maxBasePanelY), cc.p(self.centerPanel:width(), self.baseData.maxBasePanelY), cc.c4f(1,0,0,1))
		line:addTo(self.centerPanel, 100, "testLineMax")
	end

	self.hook:xy(self.hookPos)

	self.point = idler.new(0) --分数
	self.floor = idler.new(0) --层数
	self.curPagePro = idler.new(0)
	self.hookSpeed = idler.new(1)
	self.myLife = idler.new(3)
	self.perfectNum = 0
	local yyhuodongs = gGameModel.role:read("yyhuodongs")
	local yydata = yyhuodongs[self.activityId] or {}
	self.highpoint = yydata.info.high_points or 0
	local yyCfg = csv.yunying.yyhuodong[self.activityId]

	self.floorCfg = {} -- 每层的数值配置
	self.awardFloor = {} --奖励楼层
	local floor = 0
	local speed = 1
	for k,v in orderCsvPairs(csv.yunying.skyscraper_floors) do
		if v.huodongID == yyCfg.huodongID then
			if v.range[1] then
				for i = floor, v.range[1] - 1 do
					self.floorCfg[i] = {
						hookSpeed = speed
					}
				end
				floor = v.range[1]
			end
			if v.range[2] then
				for i = floor, v.range[2] do
					self.floorCfg[i] = {
						hookSpeed = v.hookSpeed
					}
				end
				if csvSize(v.awards) > 0 then
					local floor = math.random(v.range[1], v.range[2] - 1)
					self.awardFloor[floor] = {res = v.awardsIcon}
				end
			end
		end
	end
	self.accessmentCfg = {}
	for k,v in orderCsvPairs(csv.yunying.skyscraper_accessment) do
		if v.huodongID == yyCfg.huodongID then
			table.insert(self.accessmentCfg, v)
		end
	end
	table.sort(self.accessmentCfg, function(a, b)
		return a.contactRange > b.contactRange
	end)
	idlereasy.when(self.myLife, function(_, myLife)
		for i = myLife + 1, 3 do
			if self.tImgSm[i] then
				self.tImgSm[i]:texture("activity/sky_scraper/icon_mjh.png")
			end
		end
		if myLife == 0 then
			self:onGameOver()
		end
	end)
	idlereasy.when(self.floor, function(_, floor)
		self.floorTxt:text(floor .. gLanguageCsv.skyScraperFloor)
		if floor >= yyCfg.paramMap.maxFloor then
			self:onGameOver()
			return
		end
		if floor > 0 then
			self.baseData.basePanelY = math.min(self.baseData.basePanelY, self.baseData.maxBasePanelY - ((floor - math.max(1, self.baseData.swingRootFloor)) + 0.5) * HOUSE_AREA.height)
		end

		if DEBUG_SHOW then
			-- 辅助 画线
			self.centerPanel:removeChildByName("testLine")
			local line = cc.DrawNode:create()
			line:drawLine(cc.p(0, self.baseData.basePanelY), cc.p(self.centerPanel:width(), self.baseData.basePanelY), cc.c4f(0,1,0,1))
			line:addTo(self.centerPanel, 100, "testLine")
		end

		-- 不同层数晃动幅度系统配置
		if floor >= SWING_MIN_FLOOR then
			self.baseData.nextSwingFloor = floor
			self.baseData.nextSwingRangeX = self:calculateSwing()
		end
		-- 移动速度
		self.hookSpeed:set(self.floorCfg[floor].hookSpeed)
		-- 随机奖励楼层 可能是spine修改
		if self.awardFloor[floor] then
			local house = self.basePanel:get("house" .. floor)
			cc.Sprite:create(self.awardFloor[floor].res)
				:anchorPoint(0.5, 0)
				:xy(HOUSE_AREA.width/2, HOUSE_AREA.height)
				:addTo(house, 2, "award")
		end
	end)
end

-- 计算晃动范围
function SkyScraperGameView:calculateSwing()
	local floor = self.floor:read()
	-- 按比重取平均和
	local sum = 0
	-- 最低第2层与第1层有接触面积
	local minFloor = math.max(2, floor - SWING_CAL_FLOOR + 1)
	local n = floor - minFloor + 1
	local idx = 0
	for i = floor, minFloor, -1 do
		idx = idx + 1
		sum = sum + math.abs(self.floorCfg[i].calcRange) * (SWING_POW[idx] or 1)
		n = n + (SWING_POW[idx] or 1) - 1
	end
	local dx = sum / n
	local b = math.min(MAX_SWING_WIDTH, (100 - dx) / 100 * SWING_WIDTH)
	local a = -b
	if self.basePanel:get("house" .. floor):x() > 0 then
		a = a * Q
	else
		b = b * Q
	end
	if DEBUG_SHOW then
		printInfo("平均接触面积(%s), 晃动范围[%s, %s]", dx, a, b)
	end
	return {a, b}
end

--倒计时321
function SkyScraperGameView:onStartCount()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	self.panelCountDown:show()
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
			self:onGameStart()
			return false
		end
	end, 1, 0, 663)
end

function SkyScraperGameView:onGameStart()
	self.panelCountDown:hide()
	self.state = STATE.MOVE
end

-- 右上角生命显示信息
function SkyScraperGameView:initLife()
	local imgSm = self.imgSm
	self.tImgSm = {[1] = self.imgSm}
	for i = 2, 3 do
		local newImg = imgSm:clone():addTo(imgSm:getParent())
			:xy(imgSm:x() + 140 * (i - 1), imgSm:y())
		table.insert(self.tImgSm, newImg)
	end
end

-- 下方时间进度条
function SkyScraperGameView:onProcessTime(delta)
	if self.state == STATE.MOVE then
		self.progressTime = math.max(self.progressTime - delta, 0)
		self.curPagePro:set(100 * self.progressTime / PROGRESS_TIME_STEP)
		if self.progressTime <= 0 then
			self.state = STATE.DROP
		end
	end
end

-- 晃动显示处理
function SkyScraperGameView:onSwing(delta)
	local len = self.baseData.swingRangeX[2] - self.baseData.swingRangeX[1]
	local dx = (delta * len / SWING_TIME)
	local oldSwingDx = self.baseData.swingDx
	if self.baseData.swingDir ~= 0 then
		local len = self.baseData.swingRangeX[2] - self.baseData.swingRangeX[1]
		dx = dx % len
		self.baseData.swingDx = self.baseData.swingDx + self.baseData.swingDir * dx
		local function calcX()
			if self.baseData.swingDir == 1 then
				if self.baseData.swingDx > self.baseData.swingRangeX[2] then
					self.baseData.swingDx = self.baseData.swingRangeX[2] - (self.baseData.swingDx - self.baseData.swingRangeX[2])
					self.baseData.swingDir = -1
				end
			else
				if self.baseData.swingDx < self.baseData.swingRangeX[1] then
					self.baseData.swingDx = self.baseData.swingRangeX[1] - (self.baseData.swingDx - self.baseData.swingRangeX[1])
					self.baseData.swingDir = 1
				end
			end
		end
		-- 先取余，来回最多计算2次
		calcX()
		calcX()
	end
	if self.baseData.nextSwingFloor > self.baseData.swingFloor then
		-- 当移动修正的时候再赋值为新的晃动数据
		if self.baseData.swingDx * oldSwingDx <= 0 then
			self.baseData.swingFloor = self.baseData.nextSwingFloor
			self.baseData.swingRangeX = self.baseData.nextSwingRangeX

			-- 新的锚点选取
			local newSwingRootFloor = math.max(1, self.baseData.swingFloor - SWING_ROOT_FLOOR + 1)
			if newSwingRootFloor > self.baseData.swingRootFloor then
				self.basePanel:rotate(0)
				self.baseData.swingRootFloor = newSwingRootFloor
				local x, y = self.basePanel:get("house" .. self.baseData.swingRootFloor):xy()
				self.basePanel:xy(self.basePanel:x() + x, self.basePanel:y() + y)
				for i = self.baseData.swingFloor, self.baseData.swingRootFloor, -1 do
					local house = self.basePanel:get("house" .. i)
					house:xy(house:x() - x, house:y() - y)
				end
				for i = self.baseData.swingRootFloor - 1, 1, -1 do
					local house = self.basePanel:get("house" .. i)
					if not house then
						break
					end
					house:removeFromParent()
				end
			end
			self.baseData.basePanelY = self.baseData.maxBasePanelY - ((self.floor:read() - math.max(1, self.baseData.swingRootFloor)) + 0.5) * HOUSE_AREA.height

			-- 小于一定范围则不晃动
			local len = self.baseData.swingRangeX[2] - self.baseData.swingRangeX[1]
			if math.abs(len) < INGORE_SWING_RANGE * 2 then
				self.baseData.swingDir = 0
				self.baseData.swingDx = 0

			elseif self.baseData.swingDir == 0 then
				if self.basePanel:get("house" .. self.floor:read()):x() > 0 then
					self.baseData.swingDir = 1
				else
					self.baseData.swingDir = -1
				end
			end

			if DEBUG_SHOW then
				-- 辅助 画线
				self.centerPanel:removeChildByName("testLine")
				local line = cc.DrawNode:create()
				line:drawLine(cc.p(0, self.baseData.basePanelY), cc.p(self.centerPanel:width(), self.baseData.basePanelY), cc.c4f(0,1,0,1))
				line:addTo(self.centerPanel, 100, "testLine")
			end
		end
	end
	self.basePanel:rotate(math.deg(math.atan(self.baseData.swingDx/(self.baseData.maxBasePanelY - self.basePanel:y()))))
end

--上方钩子运动
function SkyScraperGameView:onTopHook(delta)
	-- 4秒移动一个完整方向
	local len = HOOK_RANGE[2] - HOOK_RANGE[1]
	local dx = (delta * self.hookSpeed:read() * len / 2) % (len * 2)
	if self.hookDir == 1 then
		self.hookPos.x = self.hookPos.x + dx
	else
		self.hookPos.x = self.hookPos.x - dx
	end
	local function calcX()
		if self.hookDir == 1 then
			if self.hookPos.x > HOOK_RANGE[2] then
				self.hookPos.x = HOOK_RANGE[2] - (self.hookPos.x - HOOK_RANGE[2])
				self.hookDir = -1
			end
		else
			if self.hookPos.x < HOOK_RANGE[1] then
				self.hookPos.x = HOOK_RANGE[1] - (self.hookPos.x - HOOK_RANGE[1])
				self.hookDir = 1
			end
		end
	end
	-- 先取余，来回最多计算2次
	calcX()
	calcX()
	self.hook:x(self.hookPos.x)
	if self.house then
		local effect = self.house:get("effect")
		local d1 = self.hookPos.x - HOOK_RANGE[1]
		local d2 = HOOK_RANGE[2] - self.hookPos.x
		local ratio = 0.4
		local angle = HOOK_ANGLE / ratio
		local anglePow = 5
		if self.hookDir == 1 then
			local r = d1/len
			if r <= ratio/anglePow then
				effect:rotate(angle * r * anglePow)
			elseif r <= ratio then
				effect:rotate(angle * (ratio - r) * anglePow / (anglePow - 1))
			else
				effect:rotate(0)
			end
		else
			local r = 1 - d1/len
			if r <= ratio/anglePow then
				effect:rotate(-angle * r * anglePow)
			elseif r <= ratio then
				effect:rotate(-angle * (ratio - r) * anglePow / (anglePow - 1))
			else
				effect:rotate(0)
			end
		end
	end
end

--上方钩子的房子
function SkyScraperGameView:onTopHouse(delta)
	local floor = self.floor:read()
	if self.state == STATE.MOVE then
		if not self.house then
			self.house = ccui.Layout:create()
				:anchorPoint(0.5, 0.5)
				:size(HOUSE_AREA)
				:xy(self.hook:width()/2, self.houseData.hookDy)
				:addTo(self.hook, 1000, "house" .. (floor + 1))

			-- TODO 还需要加判断来随机房子房顶
			local idx = math.random(1, 15)
			cc.Sprite:create("activity/sky_scraper/img_fz" .. idx .. ".png")
				:alignCenter(HOUSE_AREA)
				:anchorPoint(0.5, 1)
				:y(HOUSE_AREA.height)
				:addTo(self.house, 1, "effect")
				:scale(1.5/1.2)
		end
	elseif self.state == STATE.DROP then
		if self.house then
			local house = self.house
			self.house = nil
			house:retain()
			local pos = gGameUI:getConvertPos(house, self.centerPanel)
			house:removeFromParent()
			house:addTo(self.centerPanel, self.hook:z() + 1)
				:xy(pos)
			house:release()
			self.houseData.obj = house
			self.houseData.x = pos.x
			self.houseData.y = pos.y
			self.houseData.calcRange = nil -- 标记是否计算过与下层接触面积 (-100, 100) 0 为无接触，负为接触偏左，正为偏右
			self.houseTime = 0.1
			self.houseDir = self.hookDir
			house:get("effect"):runAction(cc.EaseBackInOut:create(cc.RotateTo:create(1, 0)))
		end
		local dx = self.houseDir * delta * 200 * self.hookSpeed:read()
		local dy = 0.1 * DROP_SPEED * (math.pow(self.houseTime + delta, 2) * math.pow(self.houseTime, 2)) -- delta * DROP_SPEED
		self.houseTime = self.houseTime + delta
		local house = self.houseData.obj
		if not self.houseData.calcRange then
			-- 有晃动，获取晃动的实时位置
			local topHousePos
			if floor > 0 then
				local topHouse = self.basePanel:get("house" .. floor)
				local x, y = topHouse:xy()
				y = y + HOUSE_AREA.height/2
				local pos = topHouse:parent():convertToWorldSpace(cc.p(x, y))
				topHousePos = self.centerPanel:convertToNodeSpace(pos)
			else
				topHousePos = cc.p(self.houseData.x, self.basePanel:y() - HOUSE_AREA.height/2)
			end
			-- 掉落底与屋顶距离
			local dis = self.houseData.y - HOUSE_AREA.height/2 - topHousePos.y
			if dis <= dy then
				-- 如果掉落横向偏移，需要重新计算x
				local x = self.houseData.x + dx * dis / math.abs(dy)
				local sign = x >= topHousePos.x and 1 or -1
				local len = math.max(0, HOUSE_AREA.width - math.abs(x - topHousePos.x))
				self.houseData.calcRange = sign * len * 100 / HOUSE_AREA.width
				if self:calculateIsContact() then
					local pos = cc.p(x, self.houseData.y - dis)
					if floor > 0 then
						pos = cc.p(topHousePos.x + sign * (HOUSE_AREA.width - len), topHousePos.y + HOUSE_AREA.height/2)
					end
					pos = self.centerPanel:convertToWorldSpace(pos)
					pos = self.basePanel:convertToNodeSpace(pos)
					-- 高度修正, 计算逻辑高度值
					if floor > 0 then
						pos.y = (floor + 1 - math.max(1, self.baseData.swingRootFloor)) * HOUSE_AREA.height
					end
					house:get("effect"):rotate(0)
					house:retain()
					house:removeFromParent()
					house:addTo(self.basePanel)
						:xy(pos)
					house:release()
					local topHouse = self.basePanel:get("house" .. floor)
					if topHouse and topHouse:get("award") then
						topHouse:get("award"):hide()
					end
					self.floorCfg[floor + 1].calcRange = self.houseData.calcRange

					self.state = STATE.MOVE
					self.progressTime = PROGRESS_TIME_STEP
					self.floor:modify(function(floor)
						return true, floor + 1
					end)
					return true
				end
			end
		end
		self.houseData.y = self.houseData.y - dy
		house:y(self.houseData.y)
		self.houseData.x = self.houseData.x + dx
		house:x(self.houseData.x)
		-- 移动到边界外则消失
		if self.houseData.y < -HOUSE_AREA.height/2 then
			house:removeFromParent()
			self.state = STATE.MOVE
			self.progressTime = PROGRESS_TIME_STEP
		end
	end
end

--背景以及下方房子移动
function SkyScraperGameView:onFloorDown(delta)
	local y = self.basePanel:y()
	if y > self.baseData.basePanelY then
		local dy = delta * FLOOR_DOWN_SPEED
		y = math.max(self.baseData.basePanelY, y - dy)
		self.basePanel:y(y)
	end
end

--按钮
function SkyScraperGameView:onBtnDown()
	if self.state == STATE.MOVE then
		self.state = STATE.DROP
	end
end

-- 计算接触面 判断是否掉落
function SkyScraperGameView:calculateIsContact()
	local floor = self.floor:read()
	if floor == 0 then
		return true
	end
	local range = math.abs(self.houseData.calcRange)
	for _, v in ipairs(self.accessmentCfg) do
		if range >= v.contactRange then
			if v.type == 3 then
				self.perfectNum = self.perfectNum + 1
			end
			self.point:modify(function(point)
				return true, point + v.points
			end)
			return true
		end
	end
	self.myLife:modify(function(myLife)
		return true, myLife - 1
	end)
	return false
end

--游戏结束
function SkyScraperGameView:onGameOver()
	--补充
	self.state = STATE.GAME_OVER
	local floor = self.floor:read()
	local showNew =  self.point:read() > self.highpoint
	local awardFloor = {}
	for k, v in pairs(self.awardFloor) do
		if floor > k then
			table.insert(awardFloor, k)
		end
	end
	gGameApp:requestServer("/game/yy/skyscraper/end", function(tb)
		gGameUI:stackUI("city.activity.sky_scraper.game_over", nil, {full = true}, self:createHandler("onClose"), self.activityId, self.point:read(), self.floor:read() + 1, showNew, tb)
	end, self.activityId, self.point:read(), floor, self.perfectNum, self.gameTime, 1, awardFloor)
end

return SkyScraperGameView