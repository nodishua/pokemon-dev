-- @date 2021-06-10
-- @desc 沙滩排球 精灵
local AI_TICK = 20

local spriteModel = class("spriteModel")

function spriteModel:ctor(netPos, netSize, data, force)
	self.netPos = netPos
	self.netSize = netSize
	self.image = nil

	self.tick = AI_TICK
	self.updateRate = 0
	self.turn = (force == 1) and 1 or -1
	self.force = force  -- 阵营
	self.floorY = 170   -- 地面高度
	self.hitBallY = 350 -- 撞击高度
	self.speed = cc.p(0, 0) -- 速度
	self.optimalFallArea = {350, 500} -- 最佳落点区域

	self.slowSpeedSign = false -- 减速标记
	self.slowSpeedRate = 1     -- 减速比例
	self.stockpileSign = false -- 蓄力标记
	self.stockpileForce = 0    -- 蓄力力度
	self.skillHitTimes = {0, 0} -- 技能命中次数

	self.batSign = false -- 击球标记
	self.batTimes = 0    -- 击球次数
	self.spikeSwitch = false -- 扣球开关

	self.pos = cc.p(0, 0)   -- 位置
	self.offset = cc.p(self.turn * data.hitOffsetPos.x, data.hitOffsetPos.y) -- 精灵与球的偏移量
	self.headCenterPos = cc.pAdd(self.pos, self.offset) -- 头部中心位置

	self.data = data
	self.res = data.res						-- 资源
	self.scale = data.scale  				-- 缩放
	self.power = data.power                 -- 力量
	self.gravity = data.gravity             -- 重力
	self.hitRadius = data.hitRadius 	    -- 撞击半径
	self.lrSpeedDelta = data.lrSpeedDelta   -- 移动速度
	self.udSpeedDelta = data.udSpeedDelta   -- 跳起速度
	self.failRate = data.failRate			-- 回球失误率

	self.operateAni = "run_loop"
end

function spriteModel:createImage(node, stockPile, stockPilePro)
	local spriteZ = (self.force == 1) and 9 or 7
	local x, y = self.netPos.x - self.turn * 800, self.floorY
	self.originPos = cc.p(x, y)
	self.image = widget.addAnimationByKey(node, self.res, self.force .. "image", "run_loop", spriteZ)
		:xy(x, y)
		:scaleX(self.turn * self.scale)
		:scaleY(self.scale)
		:anchorPoint(0.5, 0.5)

	self.pos = cc.p(x, y)
	self.headCenterPos = cc.pAdd(self.pos, self.offset)

	self.stockPile = stockPile
	self.stockPilePro = stockPilePro

	self.stockPileEffect = widget.addAnimationByKey(node, "volleyball_xuli/xuli.skel", self.force .. "stockEffect", "xuli_loop", 10)
		:xy(self.pos.x, self.floorY)
		:scale(1.5)
		:anchorPoint(0.5, 0.5)
		:hide()

	self.controlEffect = widget.addAnimationByKey(node, "volleyball_buff/buff.skel", self.force .. "controlEffect", "jiansu_loop", 15)
		:xy(self.pos.x, self.floorY)
		:scale(1.5)
		:anchorPoint(0.5, 0.5)
		:hide()
	-- 测试绘制
	-- self.drawDrop = cc.DrawNode:create()
	-- self.drawDrop:addTo(node, 10)
	-- self.drawCircle = cc.DrawNode:create()
	-- self.drawCircle:addTo(node, 10)
end

function spriteModel:deleteImage()
	self.image:removeSelf()
	self.stockPile:hide()
	-- self.drawDrop:removeSelf()
	-- self.drawCircle:removeSelf()
end

function spriteModel:reset()
	self.pos = cc.p(self.initPos.x, self.initPos.y)
	self.headCenterPos = cc.pAdd(self.pos, self.offset)
	self.speed = cc.p(0, 0)
	self.batTimes = 0
	self.hitRadius = self.data.hitRadius
	self.slowSpeedRate = 1
	self.slowSpeedSign = false
	self.stockpileForce = 0
	self.stockpileSign = false
	self.controlEffect:hide()
	self.stockPileEffect:hide()
end

-- 蓄力
function spriteModel:stockpile()
	if self.stockpileSign then
		self.stockPile:show()
		self.stockPileEffect:show()
		self.stockpileForce = math.min(math.max(self.stockpileForce, 0) + 0.1, 4)
	else
		self.stockpileForce = math.max(self.stockpileForce - 0.03, 0)
		if self.stockpileForce == 0 then
			self.stockPile:hide()
			self.stockPileEffect:hide()
		end
	end
end

-- 重置扣球
function spriteModel:resetSpike()
	if not self.spikeSwitch then
		self.spikeSwitch = true
		self.lrSpeedDelta = 8
		self.udSpeedDelta = 24
		self.hitBallY = 525
	else
		self.spikeSwitch = false
		self.lrSpeedDelta = self.data.lrSpeedDelta
		self.udSpeedDelta = self.data.udSpeedDelta
		self.hitBallY = self.data.hitBallY
	end
end

function spriteModel:updateView()
	self.headCenterPos = cc.pAdd(self.pos, self.offset)
	if self.force == 1 then
		self.image:x(self.pos.x)
	else
		self.image:xy(self.pos)
	end
	self.stockPilePro:set(self.stockpileForce / 4 * 100)
	self.stockPile:setPosition(cc.p(self.headCenterPos.x, self.headCenterPos.y + 100))
	self.stockPileEffect:xy(self.pos.x, self.floorY)
	self.controlEffect:xy(self.pos.x, self.followSelf and self.pos.y or self.floorY)
	-- self.drawCircle:clear()
	-- self.drawCircle:drawCircle(self.headCenterPos, self.hitRadius, 180, 1000, false, 1.0, 1.0, cc.c4f(255, 255, 255, 1))
end

-- 移动
function spriteModel:move()
	local force = self.force
	local x, y = self.pos.x, self.pos.y
	local slowRate = 1
	if self.stockpileSign then slowRate = 0.5 end

	if force == 2 then slowRate = self.slowSpeedRate end

	local nx, ny = x + slowRate * self.speed.x, y + self.speed.y

	if force == 1 then
		local bonePos = self.image:getBonePosition("tou")
		local dy = bonePos.y - self.initBonePos.y
		dy = (dy > 0) and dy or 0
		ny = self.initPos.y + 1.45 * dy
	else
		self.speed.y = self.speed.y + self.gravity
	end

	-- 下落检测
	if y <= self.floorY and self.speed.y < 0 then
		ny = self.floorY
		self.speed.y = 0
	end

	-- 移动范围检测
	local border = (force == 1) and 0 or 1560
	border = border + self.turn * 100
	if force == 1 then
		if nx <= border then
			nx = border + 1
			self.speed.x = 0
		elseif nx >= self.netPos.x - self.netSize.width / 2 - 2 * self.hitRadius then
			nx = self.netPos.x - self.netSize.width / 2 - 2 * self.hitRadius - 1
			self.speed.x = 0
		end
	else
		if nx >= border then
			nx = border - 1
			self.speed.x = 0
		elseif nx <= self.netPos.x + self.netSize.width / 2 + 2 * self.hitRadius then
			nx = self.netPos.x + self.netSize.width / 2 + 2 * self.hitRadius + 1
			self.speed.x = 0
		end
	end


	self.pos = cc.p(nx, ny)
	self.headCenterPos = cc.pAdd(self.pos, self.offset)

	if force == 2 and not self.isHideState then self:moveAuto() end
end

-- 自动移动
function spriteModel:moveAuto()
	self.updateRate = self.updateRate + 1
	if self.updateRate < self.tick then
		return
	end
	self.updateRate = 0

	if self.lastUpdateFunc then
		local old = self.lastUpdateFunc
		if self:lastUpdateFunc(self) == false and old == self.lastUpdateFunc then
			self.lastUpdateFunc = nil
			self.tick = AI_TICK
		end
	else
		self:randomMove()
	end
end

-- 随机跳动
function spriteModel:randomMove()
	if math.random(3) == 1 and self.speed.y == 0 then
		self.speed.y = self.udSpeedDelta / 1.5
	end
	if math.random(3) == 1 then
		self.speed.x = self.lrSpeedDelta / 5
	else
		self.speed.x = -self.lrSpeedDelta / 5
	end
end

function spriteModel:runUntil(f)
	self.tick = 0
	self.lastUpdateFunc = f
end

-- 计算向上跳到某高度的时间(以头部中心为基准)
function spriteModel:calJumpUpTime(height)
	local minHeight = self.headCenterPos.y
	-- 到达最高点时间
	local t = self.udSpeedDelta / (-self.gravity)
	local maxHeight = minHeight + self.udSpeedDelta * t + 1 / 2 * self.gravity * t * t

	-- t = (-b + sqrt(b^2 - 4*a*c)) / (2*a)
	local deltaH = height - minHeight
	local ft = (-self.udSpeedDelta + math.sqrt(self.udSpeedDelta * self.udSpeedDelta + 2 * self.gravity * deltaH)) / self.gravity
	return ft
end

function spriteModel:onEvent_hit(ball, event)
	if self.force == 2 and self.slowSpeedRate == 0 then return end
	-- in air
	if self.speed.y > 0 then
		return self:runUntil(function()
			if self.speed.y <= 0 then
				self.speed.y = 0
				self:onEvent_hit(ball, event)
				return false
			end
		end)
	end

	-- 球碰撞时的位置
	local dropX, dropY = ball:calBallFallCoordinate(self.hitBallY)
	if not dropX then
		dropX, dropY = ball:calBallFallCoordinate(self.data.hitBallY)
		if not dropX then return end
		if event.hitForce == 2 then self:resetSpike() end
	end

	-- 未过网
	if dropX < self.netPos.x then
		return
	end

	-- self.drawDrop:clear()
	-- self.drawDrop:drawCircle(cc.p(dropX, dropY), 5, 180, 1000, false, 1.0, 1.0, cc.c4f(255, 1, 1, 1))

	local dx = dropX - self.headCenterPos.x
	self.speed.x = (dx < 0 and -1 or 1) * self.lrSpeedDelta

	local jumpUpTime = self:calJumpUpTime(dropY - (self.hitRadius + ball.radius))

	if jumpUpTime then
		jumpUpTime = math.floor(jumpUpTime + 0.5)
		-- 失误
		local ranFailRate = math.random(0, 100)
		local diffValue = (ranFailRate < self.failRate and self.batTimes >= 1) and 200 or 0
		local ballMarkX = dropX - jumpUpTime * ball.speed.x - diffValue

		self:runUntil(function()
			if math.abs(self.headCenterPos.x - dropX) < self.lrSpeedDelta then
				self.headCenterPos.x = dropX
				self.pos.x = self.headCenterPos.x - self.offset.x
				self.speed.x = 0
			end

			if math.abs(ball.pos.x - ballMarkX) < self.lrSpeedDelta then
				self.speed.x = 0
				self.speed.y = self.udSpeedDelta
				return false
			end
		end)
	end
end

function spriteModel:opAniAction(ani)
	if tolua.isnull(self.image) then
		return
	end
	-- 跳 动画执行的优先级最高
	if self.operateAni == "effect_daqiu1" then
		if ani == "run_loop" then
			self.image:play(ani)
			self.operateAni = ani
		end
	elseif ani ~= self.operateAni then
		self.image:play(ani)
		self.operateAni = ani
	end
end

function spriteModel:onEvent_playPreHitAni(ball, event)
	if self.stockpileSign and self.operateAni ~= "effect_daqiu2" then
		self:opAniAction("effect_daqiu2")
		performWithDelay(event.node, function()
			self:opAniAction("run_loop")
		end, 0.8)
	end
end

function spriteModel:onEvent_playHitAni(ball, event)
	if not self.stockpileSign and ball.speed.x * self.turn < 0 then
		self:opAniAction("hit")
		performWithDelay(event.node, function()
			self:opAniAction("run_loop")
		end, 0.6)
	end
end

function spriteModel:onEvent_playJumpAni(ball, event)
	if self.operateAni ~= "effect_daqiu1" then
		self:opAniAction("effect_daqiu1")
		performWithDelay(event.node, function()
			self:opAniAction("run_loop")
		end, 0.7)
	end
end

function spriteModel:onEvent_playSkillAni(ball, event)
	if self.slowSpeedRate == 0 then
		self.controlEffect:play("shufu_loop")
		self.followSelf = true
	else
		self.controlEffect:play("jiansu_loop")
		self.followSelf = false
	end
	self.controlEffect:show()
end

function spriteModel:onEvent_palsy(ball, event)
	if self.batTimes >= 6 then
		self.batTimes = 0
		self.slowSpeedRate = 0
	elseif self.batTimes >= 3 then
		self.batTimes = self.batTimes - 3
		self.slowSpeedRate = 0.25
	end
end

return spriteModel