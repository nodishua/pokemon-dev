--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--

local rankResTb = {
	red   = "battle/box_elves_red.png",
	green = "battle/box_elves_green.png",
	gray  = "battle/box_elves_gray.png"
}

local SpeedRank = class('SpeedRank', battleModule.CBase)

local RankLimit = 6
local touxiangScale = 0.9	-- 头像的缩放,和默认的精灵球缩放不一样的

function SpeedRank:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.widget = self.parent.UIWidgetMid:get("widgetPanel.speedRank")

	self.iconItem = self.widget:get("rankItem")
	self.backGound = self.widget:get("di")
	self.iconRange = self.widget:get("iconRange")
	self.barLength = self.iconRange:size().height
	self.minIconSpace = self.iconItem:size().height / 4

	self.iconItem:hide()

	self.newRanksInfo = {}		-- 本地保存的最新数据
	self.objWidget = {}			-- 每个单位对应一个widget
	self.firstObjPosY = 0 		-- 队列中 当前行动的单位 原本所处的高度 (现在所处的高度为0)
	self.posAddValue = 0 		-- 这个是位置补正 最近一个已经行动过的单位需位于队列最末尾
	self.refreshCount = 0

	self.specObjects = {}       -- 特殊单位 1.回合提示

	self:initSpecRoundObject()

	-- render target to capture the widget for reduce draw call
	self.roundWidget:show()
	self.captureSprite = CRenderSprite.newWithNodes(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444, self.widget)
	self.captureSprite:addTo(self.parent.UIWidgetMid:get("widgetPanel")):coverTo(self.widget)
	self.captureSprite:setCaptureOffest(cc.p(120, 0))
	self.roundWidget:hide()
end

function SpeedRank:onRankRefresh(newRanksInfo)
	self.refreshCount = self.refreshCount + 1

	local speedRankSign = {}
	--用于buff中产生的临时排序信息,因为速度buff可能会同时有多个,所以需要每次排序后将数据传过来
	if newRanksInfo then
		self.newRanksInfo = newRanksInfo
	else
		if self.parent then
			self.newRanksInfo, speedRankSign = self.parent:getPlayModel():getSpeedRankArray()
		else
			self.newRanksInfo, speedRankSign = {}, {}
		end
	end

	local maxSpeed = 0
	local minSpeed = math.huge
	local hasAttacked = false 		-- 标记该单位本回合是否已经行动过 gate传过来的 列表中是有分割的
	local notAttackedHeros = {} -- 尚未行动过的单位
	local hasAttackedHeros = {} -- 已经行动过的单位
	for idx, obj in ipairs(self.newRanksInfo) do
		if obj.isAlreadyDead and not obj:isAlreadyDead() then
			local curSpeed = obj:speed()
			local unitId = (speedRankSign[idx] ~= 0) and speedRankSign[idx]
			local unitIcon = unitId and csv.unit[unitId].icon or obj.unitCfg.icon
			if speedRankSign[idx] and speedRankSign[idx] ~= 0 then
				if not hasAttacked and (obj.unitID % 2 == 0) then curSpeed = obj:speed(0) end
				if hasAttacked and (obj.unitID % 2 ~= speedRankSign[idx] % 2) then curSpeed = obj:speed(0) end
			end

			local view = self:call('getSceneObjById', obj.id)
			local changeToEnemyData = obj:getOverlaySpecBuffByIdx("changeToRandEnemyObj")
			maxSpeed = math.max(maxSpeed, curSpeed)
			minSpeed = math.min(minSpeed, curSpeed)
			local tb = {
				objSeat = view.seat,
				dbID = tostring(obj)..tostring(unitIcon),
				speed = curSpeed,
				heroIcon = changeToEnemyData and changeToEnemyData.oldUnitCfg.icon or unitIcon, --有变身buff时不改变icon
				force = view.force,
				faceTo = view.faceTo,
				hasAttacked = hasAttacked,
				curHero = idx == 1,
			}
			if not hasAttacked then
				table.insert(notAttackedHeros, tb) -- 不同的表保存
			else
				table.insert(hasAttackedHeros, tb)
			end
		else
			hasAttacked = true 		-- 遇到分割线 之后的都是已经行动过的
		end
	end

	self.maxSpeed = maxSpeed
	self.minSpeed = minSpeed

	for idx, obj in ipairs(self.specObjects) do
		obj:sort(notAttackedHeros, hasAttackedHeros)
	end

	-- 对已行动的单位按速度排序
	table.sort(hasAttackedHeros, function(a, b)
		return a.speed > b.speed
	end)

	local speedRank =  arraytools.merge({notAttackedHeros, hasAttackedHeros})
	self.speedRankTb = speedRank

	self:setWidgetSpace()

	local curCount = self.refreshCount
	local widgetCount = 0
	local function onMoveDone()
		widgetCount = widgetCount - 1
		if widgetCount ~= 0 or curCount ~= self.refreshCount then return end

		-- capture static sprite by render target
		self.captureSprite:show()
	end

	-- remove static, show widget to show move
	self.captureSprite:hide()

	local startPosX = self.iconRange:size().width / 2 	--所有图标的X 平移
	local currentObjY = -146
	for i,v in pairs(self.speedRankTb) do
		widgetCount = widgetCount + 1
		local widget = self:getWidget(i, v.dbID, v.heroIcon, v.force, v.faceTo)
		local posY = 0
		if v.posY then
			posY = v.posY - self.firstObjPosY
			if posY < 0 then
				posY = posY + self.barLength + self.posAddValue
			end
		end
		if posY == 0 then -- 当前行动的单位 做区分
			widget:scale(1.65)
			transition.executeSequence(widget, true)
					:moveTo(0.2, startPosX, currentObjY)
					:func(onMoveDone)
					:done()
		else
			widget:scale(1)
			transition.executeSequence(widget, true)
					:moveTo(0.2, startPosX, posY)
					:func(onMoveDone)
					:done()
		end
	end
end

-- 计算间隔大小
function SpeedRank:setWidgetSpace()
	local maxSpeed = self.maxSpeed
	local minSpeed =  self.minSpeed
	local speedRankTb = self.speedRankTb
	local speedLength = maxSpeed - minSpeed 		-- 最大和最小速度差
	local minPosSpace = 50 -- 最小间隔

	minPosSpace = math.min(self.barLength / table.length(speedRankTb), minPosSpace) -- 最小间隔不能太大 至少要在范围内等分

	-- 计算两个单位间的间隔
	local function getSpace(obj1, obj2)
		local speed1 = obj1.speed
		local speed2 = obj2.speed
		local space = math.abs(speed1 - speed2) / speedLength * self.barLength
		return math.max(space, minPosSpace)
	end

	local spcaeRet = {}
	local spaceSum = 0
	local length = self.barLength -- 进度条总长度 用于计算比例值
	-- 建立一张表格 以保存各个单位的间隔 并计算间隔的总和
	for i = 1, table.length(speedRankTb) - 1 do
		local space = getSpace(speedRankTb[i], speedRankTb[i + 1])
		spcaeRet[i] = space
		if space > minPosSpace then
			spaceSum = spaceSum + space -- 计算没有到达最小值的间隔的总和
		else
			length = length - space -- 从长度中移除已经是最小值的部分 不加入计算
		end
	end
	-- 总和不能超过总长度 缩小距离 以适应总长度
	local nValue = spaceSum / length -- 比例值 如果比例大于1 表示实际长度超过了总长度 按比例缩短
	if nValue > 1 then
		for i,space in pairs(spcaeRet) do
			if space > minPosSpace then
				spcaeRet[i] = space / nValue
			end
		end
	end

	-- 乘以一个公式计算的固定值，上面密一些下面稀一些
	local fixTb = {}
	spaceSum = 0
	if table.length(spcaeRet) > 1 then
		local spaceSumBeforeFix = 0
		for i = 1, math.floor(#spcaeRet/2) do
			fixTb[i] = 1.8 - ((1.6 /(table.length(spcaeRet) -1)) * (i-1))
			fixTb[table.length(spcaeRet) - i + 1] = 0.2 + ((1.6 /(table.length(spcaeRet) -1)) * (i-1))
		end

		if (table.length(spcaeRet)%2 ~= 0) then
			fixTb[math.floor(table.length(spcaeRet)/2) + 1] = 1
		end
		for i = 1, table.length(speedRankTb) - 1 do
			spaceSumBeforeFix = spaceSumBeforeFix + spcaeRet[i]
			spcaeRet[i] = spcaeRet[i] * fixTb[i]
			-- 强制修正
			local obj1 = speedRankTb[i]
			local obj2 = speedRankTb[i + 1]
			if obj2.fixedSpacePrecent then
				spcaeRet[i] = obj2.fixedSpacePrecent[1] * self.barLength
			elseif obj1.fixedSpacePrecent then
				spcaeRet[i] = obj1.fixedSpacePrecent[2] * self.barLength
			end
			spaceSum = spaceSum + spcaeRet[i]
		end
		local ratio = spaceSumBeforeFix / spaceSum
		for i = 1, table.length(speedRankTb) - 1 do
			spcaeRet[i] = spcaeRet[i] * ratio
		end
	end

	local firstObjPosY = nil
	local posAddValue = 0
	local posY = 0
	for i = 1,table.length(speedRankTb) do
		local obj = speedRankTb[i]
		if i == 1 then
			posY = minPosSpace -- 第一个单位 没有间隔 起点的设定 决定了 该单位行动后 到队尾和最后的单位的距离
		else
			local space = spcaeRet[i - 1]
			posY = posY + space
		end
		if not obj.hasAttacked and not firstObjPosY then
			posAddValue = spcaeRet[i - 1] or posAddValue
			firstObjPosY = posY
		end

		obj.posY = posY
	end

	self.posAddValue = posAddValue
	self.firstObjPosY = firstObjPosY or self.firstObjPosY
end

function SpeedRank:getWidget(idx, dbID, iconRes, force, faceTo, zOrder)
	local zOrder = zOrder or table.length(self.speedRankTb) - idx
	if self.objWidget[dbID] then
		return self.objWidget[dbID]:z(zOrder):show()
	end

	local item = self.iconItem:clone()
	local icon = item:get("icon")

	item:loadTexture(force == 1 and rankResTb.green or rankResTb.red)
		:anchorPoint(0.5, 0.5)
		:addTo(self.iconRange, zOrder)
		:show()

	icon:loadTexture(iconRes)
		:scale(touxiangScale)

	self.objWidget[dbID] = item
	return item:show()
end

-- 在进度条中初始化回合单位
function SpeedRank:initSpecRoundObject()
	local obj = {
		speed = -100,
		icon = "battle/icon_sl.png",
		hasAttacked = false,
		fixedSpacePrecent = {0.15,0.15} -- 1: other <--> self 2: self <--> other 间距百分比
	}
	obj.dbID = tostring(obj)
	obj.sort = function(o, notAttackedHeros, hasAttackedHeros)
		table.insert(notAttackedHeros,o)
		-- o.speed = self.minSpeed - 500
		self.minSpeed = math.min(self.minSpeed,o.speed)
		self.objWidget[o.dbID]:get("round"):setText(self.parent:getPlayModel().curRound+1)
	end

	local item = self.iconItem:clone()
	local icon = item:get("icon")
	local tipSprite = newCSprite("city/embattle/logo_sxd.png")
	item:addChild(tipSprite)
	tipSprite:setAnchorPoint(cc.p(0,1))
	tipSprite:setPosition(cc.p(20-item:width(),item:height()-30))
	tipSprite:setScaleX(-1)
	tipSprite:setRotation(-30)

	local text = ccui.Text:create("1", "font/youmi1.ttf", 48)
	item:addChild(text,99,"round")
	text:setPosition(cc.p(20-item:width(),item:height()-30))
	-- gray 需要缩放
	item:loadTexture(rankResTb.gray)
		:anchorPoint(0.5, 0.5)
		:addTo(self.iconRange)
		:xy(cc.p(self.iconRange:size().width / 2,0))

	icon:loadTexture(obj.icon)
		:scale(-1,1)
		:xy(item:width()/2,item:height()/2)

	self.objWidget[obj.dbID] = item
	table.insert(self.specObjects, obj)

	self.roundWidget = item
end

function SpeedRank:onNewBattleRound(args)
	self.nowWave = self.nowWave or args.wave
	if args.wave > self.nowWave then
		self.nowWave = args.wave
		-- 新的波次 可以添加一个函数以清理weiget
	end
	for _, w in pairs(self.objWidget) do
		w:hide()
	end
	self.widget:show()
	self:onRankRefresh()
end

return SpeedRank

