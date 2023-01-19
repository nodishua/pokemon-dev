-- @date:   2019-05-21
-- @desc:   无限塔主界面

local BG_PATH = {
	"city/adventure/endless_tower/bg_1.jpg",
	"city/adventure/endless_tower/bg_2.jpg",
	"city/adventure/endless_tower/bg_3.jpg",
}
local BG_WIDTH = display.maxWidth
local ICON_WIDTH = 110

local ViewBase = cc.load("mvc").ViewBase
local EndlessTowerView = class("EndlessTowerView", ViewBase)

EndlessTowerView.RESOURCE_FILENAME = "endless_tower.json"
EndlessTowerView.RESOURCE_BINDING = {
	["effectPanel"] = "effectPanel",
	["bgItem"] = "bgItem",
	["item"] = "item",
	["scroll"] = "scroll",
	["downScroll"] = "downScroll",
	["leftDown.btnRank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankShow")},
		}
	},
	["leftDown.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleShow")},
		}
	},
	["rightDown.btnSweep"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSweep")},
		}
	},
	["rightDown.btnSweep.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["rightDown.btnReset"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReset")},
		}
	},
	["rightDown.btnReset.textNote"] = "textNote",
	["rightDown.btnReset.textNum"] = "textNum",
	["marqueePanel"] = {
		varname = "marqueePanel",
		binds = {
			event = "extend",
			class = "marquee",
		}
	}
}

function EndlessTowerView:onCreate()
	self.scroll:size(display.sizeInViewRect):x(display.sizeInViewRect.x)
	self.downScroll:size(display.sizeInViewRect):x(display.sizeInViewRect.x)
	self:initModel()

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.endlessTower, subTitle = "UNLIMITED CHALLENGE"})

	self.selEffect = CSprite.new("level/xuanguan.skel")
	self.selEffect:play("effect_loop")
	self.selEffect:scale(1.3)
	self.selEffect:visible(false)
	self.selEffect:retain()

	self.bgEffect = CSprite.new("effect/wuxianguanqia.skel")
	self.bgEffect:scale(2)
	self.bgEffect:play("standby_loop")
	self.bgEffect:xy(1280, 690)

	self.bossEffect = CSprite.new("huoyankuang/huoyankuang.skel")
	self.bossEffect:play("effect_loop")
	self.bossEffect:visible(false)
	self.bossEffect:retain()

	self.effectPanel:add(self.bgEffect)

	self.scroll:setScrollBarEnabled(false)
	self.downScroll:setScrollBarEnabled(false)

	self.selIdx = 0
	--设置scroll大小
	self:buildScroll()

	self.selGateIdx = idler.new(0)

	self:buildItem()
	idlereasy.when(self.selGateIdx, function(_, selGateIdx)
		local item = self.scroll:getChildByName("gate"..selGateIdx)
		if not item then
			return
		end
		item:get("baseNode.info.mask"):hide()
		if not self.isMax then
			item:get("baseNode.imgFlag"):hide()
		else
			item:get("baseNode.imgFlag"):show()
		end
		local parent = self.selEffect:getParent()
		if parent then
			self.selEffect:removeFromParent()
			self.bossEffect:removeFromParent()
		end
		local pos = cc.p(200, 150)
		if selGateIdx % 5 == 0 then
			pos = cc.p(225, 260)
			self.bossEffect:addTo(item:get("baseNode"), 1)
			self.bossEffect:xy(cc.p(225, 280))
			self.bossEffect:visible(true)
		end
		self.selEffect:addTo(item, 100)
		self.selEffect:xy(pos)
		self.selEffect:visible(true)
		self.selIdx = selGateIdx
	end)

	idlereasy.when(self.resetCount, function(_, resetCount)
		local max = gVipCsv[self.vip:read()].endlessTowerResetTimes
		local leftCount = max - self.resetCount:read()
		self.textNum:text(string.format("%d/%d", leftCount, max))
		adapt.oneLineCenterPos(cc.p(161, 61), {self.textNote, self.textNum}, cc.p(0, 0))
	end)

	idlereasy.when(self.curChallengeId, function(_, curChallengeId)
		local selGateIdx
		if curChallengeId == 0 then
			selGateIdx = 1
		else
			local idx = 0
			for i,v in orderCsvPairs(csv.endless_tower_scene) do
				idx = idx + 1
				if curChallengeId > 0 and i == curChallengeId then
					selGateIdx = idx
					break
				end
			end
			-- 最大关卡了
			if not selGateIdx then
				selGateIdx = idx
			end
		end
		self.selGateIdx:set(selGateIdx)
		self.curGateIdx = selGateIdx
		self:jumpScroll()
	end)

	self:enableMessage():registerMessage("nextGate", functools.partial(self.onNextGate, self))
	self:quickFor()
end

function EndlessTowerView:initModel()
	self.roleLv = gGameModel.role:getIdler("level")
	self.vip = gGameModel.role:getIdler("vip_level")
	self.maxChallengeGate = gGameModel.role:getIdler("endless_tower_max_gate") --已挑战的最大关卡id
	self.curChallengeId = gGameModel.role:getIdler("endless_tower_current") --当前挑战的关卡id
	local dailyRecord = gGameModel.daily_record
	self.resetCount = dailyRecord:getIdler("endless_tower_reset_times") -- 重置次数
	self.rmb = gGameModel.role:getIdler("rmb")
	self:initData()
end

function EndlessTowerView:initData()
	local maxChallengeGate = self.maxChallengeGate:read()
	local curChallengeId = self.curChallengeId:read()
	local dataMaxIdx = 0 -- 需要读取的数据长度 （默认多读取两个 至少显示五个）
	if maxChallengeGate == 0 then
		self.curMaxIdx = 0 -- 最大已通关idx
		dataMaxIdx = 5
	end
	local t = {}
	local idx = 0
	local isNotInsert = false
	self.factIndex = 0
	local maxSize = csvSize(csv.endless_tower_scene)
	for i,v in orderCsvPairs(csv.endless_tower_scene) do
		idx = idx + 1
		local data = {}
		data.cfg = v
		data.csvId = i
		if maxChallengeGate > 0 and i == maxChallengeGate then
			dataMaxIdx = math.max(idx + 2, 5) --至少显示五个
			dataMaxIdx = math.min(maxSize, dataMaxIdx)
			self.curMaxIdx = idx
		end
		if not isNotInsert then
			table.insert(t, data)
		end
		if i == curChallengeId then
			self.curGateIdx = idx
			self.factIndex = math.max(idx + 2, 5)
			self.factIndex = math.min(maxSize, self.factIndex)
			if curChallengeId > maxChallengeGate then
				self.factIndex = math.min(self.factIndex, dataMaxIdx)
			end
		end
		if self.factIndex ~= 0 and idx == self.factIndex then
			isNotInsert = true
		end
		if idx == dataMaxIdx then
			break
		end
	end
	if self.factIndex == 0 and curChallengeId then
		self.factIndex = maxSize
		self.curGateIdx = self.factIndex
		self.isMax = true
	else
		self.isMax = false
	end
	self.gateInfos = t
	self.dataLenght = #t
end

function EndlessTowerView:addBgAndGrid(col)
	local size = self.scroll:size()
	local x = math.abs(self.scroll:getInnerContainer():x())
	local idx = math.floor(x / BG_WIDTH)
	-- 背景图片首次创建就在可见位置 不然jump后会闪一下
	for i=1,2 do
		local bg2 = ccui.ImageView:create(BG_PATH[i])
		bg2:scale(2)
		local bg2Size = bg2:size()
		bg2:xy(BG_WIDTH / 2 + (i - 1 + idx) * BG_WIDTH, bg2Size.height)
		self.downScroll:addChild(bg2, -1, "bgDown"..i)
	end

	for w=1,col do
		local item = self.bgItem:clone()
		item:xy(ICON_WIDTH / 2 + (w - 1) * ICON_WIDTH, size.height / 2)
		self.scroll:addChild(item, 0, "item"..w)
		item:show()
	end
end

function EndlessTowerView:addItem(data, i, state)
	local size = self.scroll:size()
	local distance = (size.width - 50 - 450) / 4 -- 减去一页左右两侧item的边距
	local item = self.item:clone()
	local idx = i % 3
	local y = idx == 1 and 850 or 434
	local x = 250 + (i - 1) * distance
	local offx = (1 - idx) * 50
	item:xy(x + offx, y)
	local isBoss = false
	if i % 5 == 0 then
		isBoss = true
		item:get("baseNode.info"):scale(1.2)
		item:size(450, 320)
		item:get("baseNode.textGate"):xy(225, 103)
		item:get("baseNode.imgRedPoint"):xy(225, 36)
		item:get("baseNode.info"):xy(225, 283)
		item:get("baseNode.imgFlag"):y(394)
	end
	self.scroll:addChild(item, i, "gate"..i)
	item:get("baseNode.textGate"):text(data.cfg.sceneName)
	item:get("baseNode.imgFlag"):visible(self.isMax or self.curGateIdx > i)
	item:get("baseNode.info.imgSel"):visible(i == self.curGateIdx)
	local path = "city/adventure/endless_tower/panel_icon_7.png"
	local bossPath = "city/adventure/endless_tower/panel_icon_boss0.png"
	if state then
		path = "city/adventure/endless_tower/panel_icon_6.png"
		bossPath = "city/adventure/endless_tower/panel_icon_boss1.png"
		item:get("baseNode.info.mask"):hide()
	else
		item:get("baseNode.imgFlag"):hide()
		item:get("baseNode.info.mask"):show()
	end
	item:get("baseNode.imgBoss"):texture(bossPath)
	item:get("baseNode.imgBoss"):visible(isBoss)
	item:get("baseNode.info.imgBG"):texture(path)
	item:get("baseNode.info.imgIcon"):texture(data.cfg.icon)
	item:show()
	bind.touch(self, item:get("baseNode"), {methods = {ended = function(view, node, event)
		self:onItemClick(i, data)
	end}})

	if i == self.curGateIdx then
		self.selGateIdx:set(i, true)
	end

	self:addCurItemDirection(item, i, state)

	return item
end

function EndlessTowerView:addCurItemDirection(item, idx, state)
	if idx >= self.dataLenght then
		return
	end
	local path = "city/adventure/endless_tower/icon_arrow0.png"
	if state then
		path = "city/adventure/endless_tower/icon_arrow.png"
	end
	local val = idx % 3
	local rotation = 0
	local pos = cc.p(520, 50)
	if val == 1 then
		rotation = 45
		pos = cc.p(380, -140)
	elseif val == 0 then
		rotation = -45
		pos = cc.p(480, 240)
	end
	local spr = cc.Sprite:create(path)
	spr:setRotation(rotation)
	spr:xy(pos)
	item:addChild(spr, -1)
end

function EndlessTowerView:onItemClick(idx, data)
	if idx > self.curGateIdx then
		gGameUI:showTip(gLanguageCsv.challengeLastGate)
		return
	end
	local item = self.scroll:getChildByName("gate"..self.selIdx)
	if item then
		item:get("baseNode.info.imgSel"):visible(false)
	end
	item = self.scroll:getChildByName("gate"..idx)
	if item then
		item:get("baseNode.info.imgSel"):visible(true)
	end
	self.selIdx = idx
	gGameUI:stackUI("city.adventure.endless_tower.gate_detail", nil, nil, idx, data.csvId, self:createHandler("refreshGateState"))
end

function EndlessTowerView:buildItem()
	-- 添加关卡
	self:addItem(self.gateInfos[self.curGateIdx], self.curGateIdx, self.curGateIdx <= self.factIndex)
	local function asyncLoad()
		local leftIdx, rightIdx = self.curGateIdx - 1, self.curGateIdx + 1
		local maxIdx = math.min(self.factIndex, csvSize(csv.endless_tower_scene))
		while (leftIdx > 0 or rightIdx <= maxIdx) do
			if leftIdx > 0 then
				self:addItem(self.gateInfos[leftIdx], leftIdx, leftIdx <= self.curGateIdx)
				leftIdx = leftIdx - 1
			end
			if rightIdx <= maxIdx then
				self:addItem(self.gateInfos[rightIdx], rightIdx, rightIdx <= self.curGateIdx)
				rightIdx = rightIdx + 1
			end
			coroutine.yield()
		end
	end
	self:enableAsyncload()
		:asyncFor(asyncLoad, nil, 4)
end

function EndlessTowerView:buildScroll()
	local size = self.scroll:size()
	local col = math.ceil(size.width / 110)
	local IconLength = 110 * col
	local distance = (size.width - 50 - 450) / 4 -- 减去一页左右两侧item的边距
	local maxNum = math.min(csvSize(csv.endless_tower_scene), self.factIndex)
	local endPosx = 250 + (maxNum - 1) * distance
	-- local offx = (1 - (self.curMaxIdx + 2) % 3) * 50
	-- 总长度上暂时不加off 预留了400的长度
	local width, height = endPosx + 300, size.height
	width = math.max(width, size.width)
	local container = self.scroll:getInnerContainer()
	container:size(width, height)
	self.downScroll:getInnerContainer():size(width, height)
	self.scroll:setTouchEnabled(not (width == size.width))
	--增加网格和背景图片
	self:addBgAndGrid(col)
	local leftIdx, rightIdx = 1, col
	local dir, idx, lastPercent
	self.scroll:onEvent(function(event)
		if event.name == "CONTAINER_MOVED" then
			local percent = self.scroll:getScrolledPercentHorizontal()
			lastPercent = lastPercent or percent
			self.downScroll:jumpToPercentHorizontal(percent)
			if lastPercent - percent > 0 then
				dir = "right"-- 手指滑动方向
				idx = rightIdx
			elseif lastPercent - percent < 0 then
				dir = "left"
				idx = leftIdx
			else
				local beganPos = event.target:getTouchBeganPosition()
				local endPos = event.target:getTouchMovePosition()
				if endPos.x - beganPos.x > 0 then
					dir = "right"-- 手指滑动方向
					idx = rightIdx
				elseif (endPos.x - beganPos.x < 0) or (beganPos.x == 0 and endPos.x == 0) then
					-- 都为0 jump时候触发 目前只有jumpToRight 默认就是left
					dir = "left"
					idx = leftIdx
				end
			end
			if not dir then
				lastPercent = nil
				idx = nil
				return
			end
			lastPercent = percent
			local lx = math.abs(container:x())
			local rx = lx + size.width

			--  刷新左右编号
			local function calculatelIdx(dir, num)
				local dt = num
				if dir ~= "left" then
					dt = col - num
				end
				leftIdx = (dt + leftIdx - 1) % col + 1
				rightIdx = (dt + rightIdx - 1) % col + 1
			end
			local function calculateRewardItem(num)
				for i=1,num do
					local itemIdx = dir == "left" and (idx + i - 1) % col or (idx - i + 1) % col
					itemIdx = itemIdx == 0 and col or itemIdx
					local cItem = self.scroll:getChildByName("item"..itemIdx)
					if cItem then
						if dir == "left" then
							cItem:x(cItem:x() + IconLength)
						else
							cItem:x(cItem:x() - IconLength)
						end
					end
				end
			end

			local item = self.scroll:getChildByName("item" .. idx)
			-- 改变item的位置
			if item then
				local x = item:x()
				x = dir == "left" and x - ICON_WIDTH / 2 or x + ICON_WIDTH / 2 -- 隐藏边界值
				-- 往做移 并且最左边的一列已经不可见
				if dir == "left" and lx > x + ICON_WIDTH then
					-- 这里需要计算下需要移动多个列 不一定是一列
					local num = math.ceil((lx - (x + ICON_WIDTH)) / ICON_WIDTH)
					calculatelIdx(dir, num)
					calculateRewardItem(num)
					idx = leftIdx

				elseif dir == "right" and rx < x - ICON_WIDTH then
					local num = math.ceil(((x - ICON_WIDTH) - rx) / ICON_WIDTH)
					calculatelIdx(dir, num)
					calculateRewardItem(num)
					idx = rightIdx
				end
			end

			-- 改变背景图位置
			local bg1 = self.downScroll:getChildByName("bgDown1")
			local bg2 = self.downScroll:getChildByName("bgDown2")
			local bg1x, bg2x = bg1:x(), bg2:x()
			-- 两张图片的左边界和右边界
			local bglx = math.min(bg1x, bg2x) - BG_WIDTH / 2
			local bgrx = math.max(bg1x, bg2x) + BG_WIDTH / 2
			local bgDownTarget = self.downScroll:getChildByName("bgDown1")
			local bgDownOther = self.downScroll:getChildByName("bgDown2")
			local needChange = false
			-- 左移
			if rx > bgrx then
				needChange = true
				if bg1x > bg2x then
					local centerParam = bgDownTarget
					bgDownTarget = bgDownOther
					bgDownOther = centerParam
				end
				-- jump 的时候会要移动超过一个位置
				-- 超过一个位置的时候需要把另一张图片也重新设置位置不然数据会错乱
				local num = math.ceil((rx - bgrx) / BG_WIDTH)
				bgDownTarget:x(bgDownTarget:x() + BG_WIDTH * (num + 1))
				bgDownOther:x(bgDownOther:x() + BG_WIDTH * (num - 1))
			end
			-- 右移
			if lx < bglx then
				needChange = true
				if bg1x < bg2x then
					local centerParam = bgDownTarget
					bgDownTarget = bgDownOther
					bgDownOther = centerParam
				end
				local num = math.ceil((bglx - lx) / BG_WIDTH)
				bgDownTarget:x(bgDownTarget:x() - BG_WIDTH * (num + 1))
				bgDownOther:x(bgDownOther:x() - BG_WIDTH * (num - 1))
			end
			if needChange then
				needChange = false
				local bgIdx = math.ceil(bgDownTarget:x() / BG_WIDTH) % 3
				bgIdx = bgIdx == 0 and 3 or bgIdx
				bgDownTarget:texture(BG_PATH[bgIdx])

				bgIdx = math.ceil(bgDownOther:x() / BG_WIDTH) % 3
				bgIdx = bgIdx == 0 and 3 or bgIdx
				bgDownOther:texture(BG_PATH[bgIdx])
			end

		elseif event.name == "AUTOSCROLL_ENDED" or event.name == "SCROLLING_ENDED" then
			dir = nil
			idx = nil
			lastPercent = nil
		end
	end)
end

function EndlessTowerView:refreshGateState()
	self.scroll:removeAllChildren()
	self:initData()
	self:buildItem()
	self:buildScroll()
	self:jumpScroll()
end

function EndlessTowerView:onReset()
	local max = gVipCsv[self.vip:read()].endlessTowerResetTimes
	if max - self.resetCount:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.resetTimesNotEnough)
		return
	end
	if self.curGateIdx == 1 then
		gGameUI:showTip(gLanguageCsv.cannotResetGate)
		return
	end
	local count = math.min(self.resetCount:read()+1, table.length(gCostCsv.endless_tower_reset_times_cost))
	local cost = gCostCsv.endless_tower_reset_times_cost[count]
	local params = {
		cb = function()
			if cost > 0 and self.rmb:read() < cost then
				uiEasy.showDialog("rmb")
				return
			end
			gGameApp:requestServer("/game/endless/reset", function()
				self:refreshGateState()
			end)
		end,
		isRich = cost ~= 0,
		btnType = 2,
		content = cost == 0 and gLanguageCsv.resetGate or string.format(gLanguageCsv.endlessTowerResetCost, cost),
		clearFast = true,
		dialogParams = {clickClose = false},
	}
	gGameUI:showDialog(params)
end

function EndlessTowerView:onSweep()
	if self.curGateIdx > self.curMaxIdx or self.isMax then
		gGameUI:showTip(gLanguageCsv.cannotSweep)
		return
	end
	local oldCapture = gGameModel.capture:read("limit_sprites")
	local params = {
		cb = function()
			local curChallengeId = self.curChallengeId:read()
			local oldval = self.curGateIdx
			gGameApp:requestServer("/game/endless/saodang", function(tb)
				local datas = {}
				for i,v in ipairs(tb.view.result) do
					local t = {items = {}}
					for key,vv in pairs(v) do
						if key ~= "gold" then
							t.items[key] = vv
						else
							t.gold = vv
						end
					end
					table.insert(datas, t)
				end
				-- 计算总计获得，放入最后一项
				local t = {items = {}, isTotal = true}
				for key,value in ipairs(dataEasy.mergeRawDate(tb.view.result)) do
					if value.key ~= "gold" then
						t.items[value.key] = value.num
					else
						t.gold = value.num
					end
				end
				table.insert(datas, t)
				self:refreshGateState()
				gGameUI:stackUI("city.gate.sweep", nil, nil, {
					sweepData = datas,
					oldRoleLv = self.roleLv:read(),
					showType = 2,
					hasExtra = false,
					startGateId = curChallengeId,
					from = "endlessTower",
					oldCapture = oldCapture,
					isDouble = dataEasy.isDoubleHuodong("endlessSaodang"),
				})

			end)
		end,
		isRich = false,
		btnType = 2,
		clearFast = true,
		content = string.format(gLanguageCsv.sweepGate, self.curMaxIdx),
	}
	gGameUI:showDialog(params)
end

function EndlessTowerView:jumpScroll()
	local selGateIdx = self.selGateIdx:read()
	local item = self.scroll:getChildByName("gate"..selGateIdx)
	if not item then
		return
	end
	local x = item:x()
	local size = self.scroll:getInnerContainer():size()
	local scrollWidth = self.scroll:size().width
	local percent = (x - scrollWidth / 2)  / (size.width - scrollWidth) * 100
	percent = math.min(percent, 100)
	percent = math.max(percent, 0)
	self.scroll:scrollToPercentHorizontal(percent, 0.01, false)
end

function EndlessTowerView:onRankShow()
	gGameApp:requestServer("/game/rank",function (tb)
		gGameUI:stackUI("city.adventure.endless_tower.rank", nil, nil, tb.view.rank)
	end, "endless", 0, 50)
end

function EndlessTowerView:onCleanup()
	if self.selEffect then
		self.selEffect:release()
	end
	if self.bossEffect then
		self.bossEffect:release()
	end
	ViewBase.onCleanup(self)
end

function EndlessTowerView:onNextGate(idx)
	return self:onItemClick(idx, self.gateInfos[idx])
end

function EndlessTowerView:onRuleShow()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function EndlessTowerView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(57001, 57005),
	}
	return context
end

return EndlessTowerView