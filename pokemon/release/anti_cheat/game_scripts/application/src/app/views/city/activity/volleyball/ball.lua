-- @date 2021-06-10
-- @desc 沙滩排球 球

local ballModel = class("ballModel")

function ballModel:ctor(netPos, netSize)
	self.netPos = netPos
	self.netSize = netSize
	self.radius = 40    -- 半径
	self.floorY = 200   -- 地面
	self.gravity = -0.2 -- 重力
	self.dropY = 650
	self.collisionForce = 7 -- 碰撞力度

	self.pos = cc.p(0, 0)    -- 位置
	self.speed = cc.p(0, 0)  -- 速度
	self.initPos = cc.p(0, 0)-- 初始位置

	self.image = nil    -- 球
	self.shadow = nil   -- 阴影
end

function ballModel:createImage(node, initPos)
	self.initPos = initPos
	self.serveAction = true
	local x, y = self.initPos[1].x + 1.3 * self.radius, self.dropY
	self.image = widget.addAnimationByKey(node, "volleyball_qiu/paiqiutexiao.skel", "volleyBall", "effect_xuanzhuan_loop", 11)
		:xy(x, y)
		:scale(2.1)
		:anchorPoint(0.5, 0.5)
	self.pos = cc.p(x, y)

	self.shadow = ccui.ImageView:create("activity/volleyball/yinying.png")
		:addTo(node, 4, "yinying")
		:xy(x, 170)
		:scale(0.7)
		:anchorPoint(0.5, 0.5)

end

function ballModel:deleteImage()
	self.image:removeSelf()
	self.shadow:removeSelf()
end

function ballModel:reset(winForce)
	local turn = winForce == 1 and 1 or -1
	self.pos = cc.p(self.initPos[winForce].x + turn * 1.3 * self.radius, self.dropY)
	self.serveAction = true
	self.speed = cc.p(0, 0)
	self.image:play("effect_xuanzhuan_loop")
end

function ballModel:updateView()
	self.image:xy(self.pos)
	self.shadow:x(self.pos.x)
end

-- 移动
function ballModel:move()
	local ballX, ballY = self.pos.x, self.pos.y
	self.speed.y = self.speed.y + self.gravity
	local nx, ny = ballX + self.speed.x, ballY + self.speed.y

	-- 落地检测
	if ny < self.floorY then
		ny = self.floorY
		self.speed.x = 0
		self.speed.y = 0
	end

	-- 碰网检测
	local netPosX = self.netPos.x
	local netWidth = self.netSize.width
	local netHeight = self.netPos.y + self.netSize.height / 2
	if ny <= netHeight then
		if (nx + self.radius) >= (netPosX - netWidth / 4) and (nx + self.radius) <= (netPosX + netWidth * 3 / 4) and self.speed.x > 0 then
			self.speed.x = -0.5
		elseif (nx - self.radius) >= (netPosX - netWidth / 2) and (nx - self.radius) <= (netPosX + netWidth / 4) and self.speed.x < 0 then
			local rd = math.random(0, 400) / 100
			self.speed.x = rd
		end
	end

	self.pos = cc.p(nx, ny)
end

-- 计算球下落到某高度坐标
function ballModel:calBallFallCoordinate(height)
	local ballX, ballY = self.pos.x, self.pos.y
	local deltaH = height - ballY
	local delta = self.speed.y * self.speed.y + 2 * self.gravity * deltaH
	-- x = v0*t + 1/2*a*t*t  t1 < t2
	local t1 = (-self.speed.y + math.sqrt(delta)) / self.gravity
	local t2 = (-self.speed.y - math.sqrt(delta)) / self.gravity

	-- 无解
	if delta < 0 or t2 < 0 then return end
	local ft = math.floor(t2)
	return ballX + self.speed.x * ft, ballY + self.speed.y * ft + 1 / 2 * self.gravity * ft * ft
end

-- 计算回球水平速度
function ballModel:calReturnBallSpeedX(sprite)
	-- 最佳落点范围
	local optimalFallArea = sprite.optimalFallArea
	local ballX, ballY = self.pos.x, self.pos.y
	-- 向上速度
	local v = self.collisionForce +  sprite.power + sprite.stockpileForce
	local deltaY = self.floorY - ballY
	-- x = v0*t + 1/2*a*t*t  t1 < t2
	local t1 = (-v + math.sqrt(v * v + 2 * self.gravity * deltaY)) / self.gravity
	local t2 = (-v - math.sqrt(v * v + 2 * self.gravity * deltaY)) / self.gravity
	local ft = math.floor(t2)

	local fv = {}
	for k = 1, 2 do
		fv[k] = math.abs((self.netPos.x - optimalFallArea[k]) - ballX) / ft
	end

	return math.random(fv[1], fv[2])
end

-- 响应事件
-- 球碰撞
function ballModel:onEvent_collision(sprite, event)
	if sprite.force == 2 and sprite.slowSpeedRate == 0 then return end

	local dx = self.pos.x - sprite.headCenterPos.x
	local dy = self.pos.y - sprite.headCenterPos.y
	local d = (self.radius + sprite.hitRadius) * (self.radius + sprite.hitRadius) - dx * dx - dy * dy
	-- 1.修正球位置防止穿模
	if d > 0 and math.sqrt(d) > 10 then
		if dy <= 0 then
			local vx = dx / math.abs(dx)
			self.pos.x = self.pos.x + vx / 2
		else
			local vy = dy / math.abs(dy)
			local sign = dx * dy < 0 and -1 or 1
			local ratio = sign * math.min(math.abs(dx / dy), 1)
			local vx = vy * ratio
			self.pos.y = self.pos.y + vy / 2
			self.pos.x = self.pos.x + vx / 2
		end
		self:onEvent_collision(sprite, event)
	end

	-- 2.调控球速度
	local isRobot = (sprite.force == 2)
	local turn = sprite.turn

	-- diff direction with forward
	if (dx < -1 and -1 or 1) ~= turn then
		if isRobot then
			-- robot cheat
			local rd = (math.random(-10, 10) + 100) / 100
			dx = rd * dy
		else
			-- 后脑勺45度修正
			local ratioXY = math.abs(dy / dx)
			if ratioXY >= 1 and dy > 0 then dx = dy end
			turn = dx < 0 and -1 or 1
		end
	end

	local collisionForce = self.collisionForce
	local speedX = turn * math.min(math.abs(collisionForce * dx / dy), collisionForce)
	local speedY = collisionForce + sprite.power + sprite.stockpileForce

	if isRobot then
		speedX = turn * self:calReturnBallSpeedX(sprite)
	elseif self.serveAction then
		speedY = math.min(1.5 * speedY, 10)
	end

	self.speed.x = speedX
	self.speed.y = speedY
end

function ballModel:onEvent_playSkillAni(sprite, event)
	local aniName = {
		"effect_bing",
		"effect_chaoneng",
		"effect_dian",
		"effect_yanshi"
	}
	local skillLevel = sprite.slowSpeedRate == 0 and 2 or 1
	if event.reset == true then
		sprite.skillHitTimes[skillLevel] = sprite.skillHitTimes[skillLevel] + 1
		self.image:play("effect_xuanzhuan_loop")
	else
		local ani = aniName[sprite.data.skillType] .. skillLevel .. "_loop"
		self.image:play(ani)
	end
end

return ballModel