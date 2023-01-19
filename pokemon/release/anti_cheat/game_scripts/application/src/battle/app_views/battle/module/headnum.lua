--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--

-- 优化管理head num显示和销毁
local HeadNum = class('HeadNum', battleModule.CBase)

local FadeOutTime = 1.2
-- 克制关系img
local RestraintTypeImg = {
	strong = battle.ShowHeadNumberRes.txtStrong,
	weak = battle.ShowHeadNumberRes.txtWeak,
	fullweak = battle.ShowHeadNumberRes.txtFullweak,
}

local GroupZ = {}
local GroupZCounter = 1

local function getGroupZ(spr, posZ)
	local key = spr.pathName or spr:getAni():getResourceName()
	if GroupZ[key] then
		return GroupZ[key] + posZ
	end
	GroupZCounter = GroupZCounter + 1
	local z = GroupZCounter * 10000
	GroupZ[key] = z
	return z + posZ
end


-- @parm numType: 1 伤害值， 2 加血量， 3 系数量
local function getIconLabelAtlas(view, number, icon, numType, delay)
	local convStr = tostring(number)
	if numType == 1 then	-- 伤害
		convStr = '-' .. convStr
	elseif numType == 2 then	-- 治疗
		convStr = '+' .. convStr
	end
	local tempLabel = ccui.Layout:create()
	bind.extend(view, tempLabel, {
		class = "text_atlas",
		props = {
			data = convStr,
			pathName = icon,
			isEqualDist = false,
			align = "center",
			onNode = function(node)
				node:setCascadeOpacityEnabled(true)
			end,
		}
	})
	return tempLabel
end

local function newBuffTxtInPlist(path)
	-- 改动需要和bufficon中同名函数同步
	local raw
	if path:find("battle/txt") then
		local shortName = path:sub(12)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrameByName(shortName)
		if frame then
			raw = cc.Sprite:createWithSpriteFrame(frame)
			raw:setScale(2)
		else
			errorInWindows("buff_txt not in batch %s", shortName)
		end
	end
	return CSprite.new(path, raw)
end

function HeadNum:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.layerDi = ccui.Layout:create()
	self.layerFont = ccui.Layout:create()
	self.layerTxt = ccui.Layout:create()
	self.layerTxtRestraint = ccui.Layout:create()

	self.showUnitSeg0Number = {}

	self.parent.effectLayerNum:add(self.layerDi, 1)
		:add(self.layerFont, 2)
		:add(self.layerTxt, 3)
		:add(self.layerTxtRestraint, 4)
end

-- 分为伤害数字 和 头顶飘字
local function isHideHeadNumber(num, segId, parms)
	-- 条件1 num < 0
	if num < 0 then
		return true
	end
	-- 条件2 吸血或复活 数字不大于0
	if num <= 0 and (parms.from == battle.DamageFrom.rebound or parms.from == battle.ResumeHpFrom.suckblood) then
		return true
	end
	if segId and segId > 1 then
		-- 条件3 miss数字只显示第一条
		if parms.miss then
			return true
		end
		-- 条件4 伤害和治疗为0 只显示第一条
		if num <= 0 then
			return true
		end
		if parms.immune then
			return true
		end
	end
	return false
end

-- 调整前后排伤害数字位置
function HeadNum:getHeadNumberPos(isFullweak, posZ, parms)
	local posX = 0 -- 累计X
	local posY = 0

	-- 添加字体并且设置位置
	-- 吸血 和 反伤 格挡
	local prefixRes
	local offPos = cc.p(-140,0)
	if parms.from == battle.ResumeHpFrom.suckblood then
		prefixRes = battle.ShowHeadNumberRes.txtXx
		offPos = cc.p(-150,65)
	elseif parms.from == battle.DamageFrom.rebound then
		prefixRes = battle.ShowHeadNumberRes.txtFs
		offPos = cc.p(-150,40)
	elseif parms.strike then
		prefixRes = battle.ShowHeadNumberRes.txtBj
		offPos = cc.p(-220,82)
	-- elseif parms.miss or parms.skillMiss then
	-- 	prefixRes = battle.ShowHeadNumberRes.txtSb
	elseif parms.block then
		prefixRes = battle.ShowHeadNumberRes.txtGd
		offPos = cc.p(-220,41)
	elseif parms.immune and parms.immune == 'all'then
		prefixRes = battle.ShowHeadNumberRes.txtAllImmune
	elseif parms.immune and parms.immune == 'special'then
		prefixRes = battle.ShowHeadNumberRes.txtSpecialImmune
	elseif parms.immune and parms.immune == 'physical'then
		prefixRes = battle.ShowHeadNumberRes.txtPhysicalImmune
	end

	local prefixSpr
	if prefixRes and not isFullweak then
		prefixSpr = newCSpriteWithFunc(prefixRes, newBuffTxtInPlist)
		local w = prefixSpr:getAni():getBoundingBox().width
		local offTxt = parms.block or parms.strike
		prefixSpr:addTo(self.layerTxt):xy(posX, posY + offPos.y):z(getGroupZ(prefixSpr, posZ))
		posX = posX + w + offPos.x
	end
	return posX, posY, prefixSpr
end

function HeadNum:getHeadNumberArray(typ, x, y, posZ, num, unit, parms)
	local natureFlag = parms.natureFlag  	-- 克制关系
	local nature = parms.nature  	--克制值
	local segId = parms.segId or 1 -- 伤害或加血时间间隔
	local delay = (parms.delay or 0)
	local seg0Height = self.showUnitSeg0Number
	local unitSeat = unit.model.seat
	local addNum = false
	local isFullweak = natureFlag and natureFlag == "fullweak"
	local numVec, numDiRes
	local natureVec, natureDiRes
	local numDiSpr, natureDiSpr
	local prefixSpr

	if not parms.miss and not isFullweak and not parms.immune then
		-- 调整前后排伤害数字位置
		local posX, posY = 0, 0
		posX, posY, prefixSpr = self:getHeadNumberPos(isFullweak, posZ, parms)
		-- 伤害数字
		if not isFullweak then
			if parms.strike then	-- 暴击
				numVec = getIconLabelAtlas(self.parent, num, battle.ShowHeadNumberRes.fontBj, 1, delay)
				numDiRes = battle.ShowHeadNumberRes.txtBjDi
			elseif typ == 0 then	-- 普通伤害
				numVec = getIconLabelAtlas(self.parent, num, battle.ShowHeadNumberRes.fontPtsh, 1, delay)
				numDiRes = battle.ShowHeadNumberRes.txtPtshDi
			elseif typ == 1 then	-- 治疗数字
				numVec = getIconLabelAtlas(self.parent, num, battle.ShowHeadNumberRes.fontZlsz, 2, delay)
				numDiRes = battle.ShowHeadNumberRes.txtZlszDi
			end
		end

		-- 克制系数
		if natureFlag and nature and natureFlag ~= 'normal' and natureFlag ~= "fullweak" then
			local natureNumber = string.format("(x%s)", nature)
			natureVec = getIconLabelAtlas(self.parent, natureNumber, battle.ShowHeadNumberRes.fontKz, 3, delay)
			natureDiRes = battle.ShowHeadNumberRes.txtKzDi
		end

		local function addNumSprite(numSpr, diRes, offx)
			local sizeNum = numSpr.panel:getContentSize()
			local diSpr = newCSpriteWithFunc(diRes, newBuffTxtInPlist)
			local sizeDi = diSpr:getAni():getContentSize()
			local scalex = 1
			if sizeNum.width > sizeDi.width then
				scalex = sizeNum.width/sizeDi.width
				diSpr:getAni():scaleX(scalex)
			end
			local nw = sizeDi.width*scalex
			local nh = sizeDi.height + (seg0Height[unitSeat] or 0)
			numSpr:addTo(self.layerFont):xy(nw/2 + posX, nh/2):z(getGroupZ(numSpr, posZ))
			diSpr:addTo(self.layerDi):xy(nw/2 + posX, nh/2):z(getGroupZ(diSpr, posZ))
			posX = posX + nw + (offx or 0)
			return diSpr
		end
		-- 若暴击了 再缩进一点60
		if numVec and numDiRes then
			numDiSpr = addNumSprite(numVec, numDiRes, parms.strike and -60)
			if segId == 1 then
				addNum = numDiSpr:getAni():getContentSize().height
				seg0Height[unitSeat] = seg0Height[unitSeat] or 0
				seg0Height[unitSeat] = seg0Height[unitSeat] + addNum + 2
			end
		end
		if natureVec and natureDiRes then
			natureDiSpr = addNumSprite(natureVec, natureDiRes, parms.strike and -60)
		end
	end

	local numData = {prefixSpr, numDiSpr, natureDiSpr, numVec, natureVec}
	local array = {}
	for i = 1, table.maxn(numData) do
		if numData[i] then
			table.insert(array, numData[i])
		end
	end
	return array, addNum
end

-- 表现函数，统一不写self. ,需要外部传入spriteView, 所有的表现, 将以spriteView的参照物
-- 表现函数		args: {typ=, num=, args=}
-- @parm: typ, 0:扣血， 1:加血, 2:吸收(这个类型可能没有定义过)
-- @parm: RestraintRelationship, normal:完全免疫  strong:克制  weak:抵抗
--  克制 > 1   0< 抵抗 < 1  完全免疫 = 0
function HeadNum:onShowHeadNumber(unit, args)
	local typ = args.typ
	local num = math.floor(args.num)
	local parms = args.args
	local natureFlag = parms.natureFlag  	-- 克制关系
	local nature = parms.nature  	--克制值
	local segId = parms.segId or 1 -- 伤害或加血时间间隔
	local delay = (parms.delay or 0)
	local isLastSeg = parms.isLastSeg --是否为最后一个过程段，控制显示克制关系文字，后续可能控制其他的
	local segCall = parms.call
	local seg0Height = self.showUnitSeg0Number
	local unitSeat = unit.model.seat

	if isHideHeadNumber(num, segId, parms) then
		return
	end

	-- 没有效果的时候，不加闪避，暴击等等效果的显示和判定！

	-- unit 的位置
	local x, y = unit:getCurPos()
	-- 伤害飘出的位置可以通过配表配置
	local headPos = unit.unitCfg.everyPos.headPos
	x = x + headPos.x - 60
	y = y + headPos.y + 25

	-- 层级显示
	local frontRow = display.height-y
	local backRow = frontRow - 1
	local rowNum = 2-(math.floor((unit.model.seat+2)/3))%2
	local posZ = rowNum == 1 and frontRow or backRow

	-- 设置宽度
	local dirIdx = (unit.model.seat <= 6) and -1 or 1 -- 阵营
	local segIdx = segId and segId-1 or 0 -- 间隔
	local fixPos = cc.p(0, 0)
	local pos = cc.p(x - segIdx*dirIdx*20 + dirIdx*fixPos.x, y - segIdx*40 + fixPos.y)

	-- 数字和底
	local array, addNum = self:getHeadNumberArray(typ, x, y, posZ, num, unit, parms)

	local function allSpriteDo(f)
		for _, obj in ipairs(array) do
			f(obj)
		end
	end

	allSpriteDo(function(spr)
		local x, y = spr:xy()
		spr:xy(x + pos.x, y + pos.y):show()
		spr:setScale(1)
		spr:setOpacity(255)
		spr:setCascadeOpacityEnabled(true)
	end)

	-- 我方伤害瓢字方向为左边，敌方为右边
	local moveDirectX = dirIdx*12

	-- 删除
	local isRemoved = false
	local callback = function()
		if isRemoved then return end
		isRemoved = true
		if addNum then
			seg0Height[unitSeat] = seg0Height[unitSeat] - addNum
		end
		allSpriteDo(function(spr)
			if isCSprite(spr) then
				removeCSprite(spr)
			else
				spr:removeFromParent()
			end
		end)
		if segCall then
			segCall()
		end
		if isLastSeg then
			unit.relationshipStatus = "showRelationship"
		end
	end

	-- 渐隐
	allSpriteDo(function(spr)
		transition.executeSequence(spr)
			:delay(delay)
			:scaleTo(0.15, 2)
			:scaleTo(0.1, 1)
			:moveBy(FadeOutTime, moveDirectX, 180)
			:func(callback)
			:done()

		transition.executeSequence(spr)
			:delay(delay)
			:fadeOut(FadeOutTime)
			:done()
	end)

	-- 克制效果的图
	if unit.relationshipStatus == "showRelationship" and natureFlag and nature and natureFlag ~= 'normal' then
		unit.relationshipStatus = "stop"

		-- 增加一个偏移量方便策划调整
		local natureNodeOffX = 0
		local natureNodeOffY = -60
		local natureNode = newCSpriteWithFunc(RestraintTypeImg[natureFlag], newBuffTxtInPlist)
		natureNode:setAnchorPoint(0.5, 0.5)
		natureNode:setPosition(cc.p(x + natureNodeOffX, y + natureNodeOffY))
		natureNode:setLocalZOrder(posZ + 1000)
		self.layerTxtRestraint:add(natureNode)

		-- 克制效果也添加一个动画
		transition.executeSequence(natureNode)
			:delay(delay)
			:scaleTo(0.2, 1.8)
			:scaleTo(0.1, 1)
			:delay(0.3)
			:moveBy(1, 0, 50)
			:func(function()
				removeCSprite(natureNode)
			end)
			:done()
	end
end

-- 显示头上的飘字 不依赖伤害
-- 临时处理 后期实现单独表现
function HeadNum:onShowHeadText(unit, args)
	local parms = args.args
	local isLastSeg = parms.segId == 1
	local prefixRes
	-- local delay = (parms.delay or 0)

	if parms.miss then
		prefixRes = battle.ShowHeadNumberRes.txtSb
	end

	if not prefixRes then return end
	if not isLastSeg then return end

	-- unit 的位置
	local x, y = unit:getCurPos()
	local effectPos = cc.p(x, y)
	local headPos = unit.unitCfg.everyPos.headPos
	effectPos = cc.pAdd(effectPos, headPos)
	-- 伤害飘出的位置可以通过配表配置
	-- 层级显示
	local frontRow = display.height-y
	local backRow = frontRow - 1
	local rowNum = 2-(math.floor((unit.model.seat+2)/3))%2
	local posZ = rowNum == 1 and frontRow or backRow

	local delay = 0

	local prefixSpr = newCSpriteWithFunc(prefixRes, newBuffTxtInPlist)
	prefixSpr:addTo(self.layerTxt):xy(effectPos.x, effectPos.y):z(getGroupZ(prefixSpr, posZ))

	-- 设置宽度
	-- local pos = cc.p(x + headPos.x - 120, y + headPos.y + 120)

	local array = {}
	if prefixSpr then table.insert(array, prefixSpr) end
	local function allSpriteDo(f)
		for _, obj in ipairs(array) do
			f(obj)
		end
	end

	allSpriteDo(function(spr)
		spr:show()
		spr:setScale(1)
		spr:setOpacity(255)
		spr:setCascadeOpacityEnabled(true)
	end)

	-- 删除
	local isRemoved = false
	local callback = function()
		if isRemoved then return end
		isRemoved = true
		allSpriteDo(function(spr)
			if isCSprite(spr) then
				removeCSprite(spr)
			else
				spr:removeFromParent()
			end
		end)
	end

	-- 渐隐
	allSpriteDo(function(spr)
		transition.executeSequence(spr)
			:delay(delay)
			:scaleTo(0.15, 2)
			:scaleTo(0.1, 1)
			:moveBy(FadeOutTime, 0, 180)
			:func(callback)
			:done()

		transition.executeSequence(spr)
			:delay(delay)
			:fadeOut(FadeOutTime)
			:done()
	end)
end


return HeadNum