--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2020 TianJi Information Technology Inc.
--

-- 优化管理buff icon显示和销毁
local BuffIcon = class('BuffIcon', battleModule.CBase)

local createNode = function()
	local node = cc.Node:create()
	node.prevVisible = nil
	return node
end

local setNodeVisible = function(node,visible)
	if node.prevVisible ~= visible then
		node:setVisible(visible)
		node.prevVisible = visible
	end
end

function BuffIcon:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	-- BattleSprite也在gameLayer
	self.layer = self.parent.gameLayer
	self.layerPos = self.layer:convertToWorldSpace(cc.p(0, 0))

	self.buffTexts = {}
	self.units = {}
end

function BuffIcon:getRecord(unit, newWhenNil)
	local key = tostring(unit)
	local t = self.units[key]
	if t == nil and newWhenNil then
		-- self.buffEffectsMap = {}		-- 保存下自身的effec和sprite的对应
		-- self.buffIconsCntIdTb = {}		-- 保存对应的icon id 格式：{cntid}
		t = {
			buffEffectsMap = {},
			buffLastIndex = 0,
			delArray = {},
			shadowNode = cc.Node:create(), -- addTo lifebar
			buffGroupNode = createNode(), -- addTo gameLayer
			buffOverlayNode = createNode(), -- addTo gameLayer
			buffTextNode = createNode(), -- addTo gameLayer
			visible = true,
			lineLimit = 5, -- 单列限制个数
		}
		self.units[key] = t
		t.shadowNode:addTo(unit.lifebar):xy(cc.pSub(unit.lifebar.buffAddFirstPos, self.layerPos))
		local startPos = t.shadowNode:convertToWorldSpace(cc.p(0, 0))
		t.buffGroupNode:addTo(self.layer, battle.GameLayerZOrder.icon + unit.posZ):xy(startPos)
		-- overlay会有层级问题，但牺牲显示照顾渲染批处理
		t.buffOverlayNode:addTo(self.layer, battle.GameLayerZOrder.overlay + unit.posZ):xy(startPos)
		-- startPos = unit:convertToWorldSpace(cc.p(0,0))
		t.buffTextNode:addTo(self.layer, battle.GameLayerZOrder.text):xy(cc.pAdd(cc.p(unit:getPosition()),unit.unitCfg.everyPos.headPos))
		local cb
		cb = t.shadowNode:onNodeEvent("exit", function()
			cb:remove()
			self.units[key] = nil
			for cfgId, sprite in pairs(t.buffEffectsMap) do
				removeCSprite(sprite)
				sprite:hide()
			end
			performWithDelay(self.layer, function()
				t.buffGroupNode:removeSelf()
				t.buffOverlayNode:removeSelf()
				t.buffTextNode:removeSelf()
			end, 0)
		end)

		-- 每帧刷新，暂时只跟踪pos和visible
		local prevPos = cc.p(0, 0)
		t.shadowNode:scheduleUpdate(function()
			local x, y = unit:getPosition()
			if prevPos.x ~= x or prevPos.y ~= y or unit.refreshBuffIconOnce then
				prevPos = cc.p(x, y)
				local startPos = t.shadowNode:convertToWorldSpace(cc.p(0, 0))
				t.buffGroupNode:setPosition(startPos)
				t.buffOverlayNode:setPosition(startPos)
				-- startPos = unit:convertToWorldSpace(cc.p(0,0))
				unit.refreshBuffIconOnce = false
				t.buffTextNode:setPosition(cc.pAdd(prevPos,unit.unitCfg.everyPos.headPos))
			end

			local visible = t.visible and unit:visible()
			setNodeVisible(t.buffTextNode, visible)

			visible = visible and unit.lifebar:visible()
			setNodeVisible(t.buffGroupNode, visible)
			setNodeVisible(t.buffOverlayNode, visible)
		end)
	end
	return t
end

-- icon坐标调整
local function updateIconPos(sprite,lineLimit)
	local buffIconIdx = sprite.firstIdx
	local box = sprite:getBoundingBox()
	local offX = (buffIconIdx-1)%lineLimit*(box.width + 5)
	local offY = math.floor((buffIconIdx-1)/lineLimit)*box.height
	local newPos = cc.p(offX, offY)
	sprite:setPosition(newPos)

	if sprite.overlayCountLabel and not sprite.overlayOnSprite then
		sprite.overlayCountLabel:setPosition(cc.pAdd(newPos, cc.p(box.width, -5)))
	end
end

local function newBuffTxtInPlist(path)
	-- 小图合并成大图，小图存在暂时只是防止大图没更新用
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

function BuffIcon:onShowBuffText(unit, textRes)
	if not textRes or textRes == "" then return end
	local t = self:getRecord(unit, true)

	self.buffTexts[unit.id] = self.buffTexts[unit.id] or {}
	local buffTexts = self.buffTexts[unit.id]
	if buffTexts[textRes] then return end

	local height,count,avg = 0,0,0
	for k,v in pairs(buffTexts) do
		height = height + v
		count = count + 1
	end

	if height + t.buffTextNode:getPositionY() > display.sizeInView.height then return end

	-- local sprite = newCSprite(textRes)
	local sprite = newCSpriteWithFunc(textRes, newBuffTxtInPlist)
	if not sprite then return end

	local box = sprite:getBoundingBox()
	avg = count == 0 and box.height or (height+box.height)/(count+1)
	-- 高度进行修正
	local newPos = cc.p(0, height + avg)
	buffTexts[textRes] = avg
	sprite:setPosition(newPos)

	t.buffTextNode:add(sprite)
	local function remove()
		buffTexts[textRes] = nil
		removeCSprite(sprite)
	end

	transition.executeSequence(sprite)
		:delay(1)
		--:moveBy(2, 0, 120)
		:fadeOut(0.25)
		:func(remove)
		:done()
end

-- 头顶上的buff图标们
function BuffIcon:onShowBuffIcon(unit, iconResPath, cfgId, overlayCount)
	local t = self:getRecord(unit, true)

	local sprite = t.buffEffectsMap[cfgId]
	if sprite == nil then return end

	--sprite复用时Label用的还是上次的数据，这里用显隐做下控制
	local overlayCountLabel = sprite.overlayCountLabel
	if overlayCountLabel and overlayCount and overlayCount <= 1 then
		overlayCountLabel:setVisible(false)
	end

	-- 层级 >1 时才显示
	if overlayCount and (overlayCount > 1) then
		if overlayCountLabel == nil then
			local label = cc.Label:createWithTTF(overlayCount, "font/youmi1.ttf", 30)
			label:enableOutline(cc.c4b(0, 0, 0, 255), 1)
			label:setAnchorPoint(cc.p(1, 0))
			if sprite.overlayOnSprite then
				local box = sprite:getBoundingBox()
				label:setPosition(cc.p(box.width, -5))
				sprite:addChild(label)
			else
				t.buffOverlayNode:addChild(label)
			end
			sprite.overlayCountLabel = label
			overlayCountLabel = label
		end
		overlayCountLabel:setString(overlayCount)
		overlayCountLabel:setVisible(true)
	end

	--坐标调整
	sprite:show()
	self:refreshBuffIcons(t)
	-- updateIconPos(sprite)
end

-- 上层逻辑存在立即删除的可能，但显示上又需要有一定的显示
function BuffIcon:refreshBuffIcons(t)
	local order = {}
	for id, spr in pairs(t.buffEffectsMap) do
		if spr:isVisible() then
			table.insert(order, spr)
		end
	end
	table.sort(order, function(a, b)
		return a.firstIdx < b.firstIdx
	end)
	for i, spr in ipairs(order) do
		spr.firstIdx = i
	end
	t.buffLastIndex = table.length(order)

	--重排列下图标位置
	for id, spr in pairs(t.buffEffectsMap) do
		updateIconPos(spr,t.lineLimit)
	end
end

-- 清理缓存删除组
function BuffIcon:clearDelArray(t)
	for _, cfgId in ipairs(t.delArray) do
		local sprite = t.buffEffectsMap[cfgId]
		if sprite and sprite.ref <= 0 then
			t.buffEffectsMap[cfgId] = nil
			if sprite.overlayCountLabel then
				sprite.overlayCountLabel:removeSelf()
				sprite.overlayCountLabel = nil
			end
			sprite:removeChildByName("iconFrame")
			removeCSprite(sprite)
		end
	end
	t.delArray = {}
end

-- 删除图标
function BuffIcon:onDelBuffIcon(unit, cfgId)
	local t = self:getRecord(unit)
	if t == nil then return end

	local sprite = t.buffEffectsMap[cfgId]
	if sprite == nil then return end

	sprite.ref = sprite.ref - 1
	if sprite.ref > 0 then return end

	sprite:hide()
	self:refreshBuffIcons(t)

	table.insert(t.delArray, cfgId)
	local mark = table.length(t.delArray)
	performWithDelay(t.shadowNode, function()
		if mark ~= table.length(t.delArray) then
			return
		end

		self:clearDelArray(t)
		-- self:refreshBuffIcons(t)
	end, 1)
end

local function newBuffIconInPlist(path)
	-- 小图合并成大图，小图存在暂时只是防止大图没更新用
	local raw
	if path:find("battle/buff_icon") then
		local shortName = path:sub(18)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrameByName(shortName)
		if frame then
			raw = cc.Sprite:createWithSpriteFrame(frame)
		else
			errorInWindows("buff_icon not in batch %s", shortName)
		end
	end
	return CSprite.new(path, raw)
end

function BuffIcon:onDealBuffEffectsMap(unit, iconResPath, cfgId, isIconFrame)
	local t = self:getRecord(unit, true)

	-- 重复添加时应该引用计数加1
	local sprite = t.buffEffectsMap[cfgId]
	if sprite then
		-- may be in delArray, recycle it back
		if sprite.ref < 0 then
			sprite.ref = 0
			-- sprite:hide()
			-- self:refreshBuffIcons(t)
		end
		sprite.ref = sprite.ref + 1
		return
	end

	-- create new icon sprite
	if iconResPath and iconResPath ~= '' then
		t.buffLastIndex = t.buffLastIndex + 1
		local idx = t.buffLastIndex

		sprite = newCSpriteWithFunc(iconResPath, newBuffIconInPlist)
		sprite.ref = 1
		sprite.cfgId = cfgId
		sprite.firstIdx = idx
		sprite.overlayCountLabel = nil

		-- 世界boss特殊处理
		sprite.overlayOnSprite = tj.type(self.parent:getPlayModel()) == "ActivityWorldBossGate"
		if sprite.overlayOnSprite and unit.seat > battlePlay.Gate.ForceNumber then
			sprite.overlayOnSprite = false
		end

		if isIconFrame == 1 then
			local frame = newCSpriteWithFunc("battle/buff_icon/box_selected.png", newBuffIconInPlist)
			sprite:addChild(frame, 99, "iconFrame")
			frame:setPosition(25, 25)
		end

		sprite:getAni():scale(1)
		sprite:getAni():setAnchorPoint(cc.p(0, 0))
		sprite:hide()

		t.buffGroupNode:add(sprite)
		t.buffEffectsMap[cfgId] = sprite 	--可能有使用相同图标的不同buff
	end
end

function BuffIcon:onSetBuffIconVisible(unit, flag)
	local t = self:getRecord(unit)
	if t == nil then return end

	t.visible = flag
end

return BuffIcon