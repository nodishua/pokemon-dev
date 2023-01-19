-- @date 2021-06-01
-- @desc 沙滩排球 游戏

local Ball = require "app.views.city.activity.volleyball.ball"
local Sprite = require "app.views.city.activity.volleyball.sprite"

local GUIDE_CONFIG = {
	[1] = {nodeName = "cannonPanel1", content = gLanguageCsv.volleyballGuide1}, -- 左场地
	[2] = {nodeName = "cannonPanel2", content = gLanguageCsv.volleyballGuide2}, -- 右场地
	[3] = {nodeName = "cannonPanel3", content = gLanguageCsv.volleyballGuide7}, -- 左界外
	[4] = {nodeName = "cannonPanel4", content = gLanguageCsv.volleyballGuide8}, -- 右界外
	[5] = {nodeName = "movePanel", content = gLanguageCsv.volleyballGuide3}, -- 移动键
	[6] = {nodeName = "jump", content = gLanguageCsv.volleyballGuide6},	   -- 跳跃键
	[7] = {nodeName = "storage", content = gLanguageCsv.volleyballGuide4}, -- 蓄力键
	[8] = {nodeName = "skill", content = gLanguageCsv.volleyballGuide5},   -- 技能键
	[9] = {nodeName = "maskAttr", content = gLanguageCsv.volleyballGuide9},-- 技能键
	[10] = {nodeName = "btnRandom", content = gLanguageCsv.volleyballGuide10}, -- 技能键
}

local ViewBase = cc.load("mvc").ViewBase
local VolleyBallGame = class("VolleyBallGame", ViewBase)

VolleyBallGame.RESOURCE_FILENAME = "volleyball_game.json"
VolleyBallGame.RESOURCE_BINDING = {
	["bg"] = "bg",
	["bg.net"] = "net",
	["bg.leftCable1"] = "leftCable1",
	["bg.rightCable1"] = "rightCable1",
	["bg.leftCable2"] = "leftCable2",
	["bg.rightCable2"] = "rightCable2",
	["bg.stockPile1"] = "stockPile1",
	["bg.stockPile2"] = "stockPile2",
	["bg.stockPile1.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.DEFAULT, size = 4}}
		}
	},
	["bg.stockPile1.bar"] = {
		varname = "stockPile1Bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("stockPro1")
			}
		}
	},
	["bg.stockPile2.bar"] = {
		varname = "stockPile2Bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("stockPro2")
			}
		}
	},
	["scoreboard.self"] = "selfScorePanel",
	["scoreboard.enemy"] = "enemyScorePanel",
	["scoreboard.self.score"] = {
		varname = "selfScore",
		binds = {
			event = "effect",
			data = {color = cc.c4b(0, 193, 251, 255)}
		}
	},
	["scoreboard.enemy.score"] = {
		varname = "enemyScore",
		binds = {
			event = "effect",
			data = {color = cc.c4b(236, 91, 99, 255)}
		}
	},
	["operatePanel"] = "operatePanel",
	["operatePanel.skill"] = {
		varname = "skill",
		binds = {
			event = "touch",
			method = bindHelper.self("onFreedPalsy"),
		}
	},
	["operatePanel.storage"] = {
		varname = "storage",
		binds = {
			event = "touch",
			method = bindHelper.self("onStoragePower")
		}
	},
	["operatePanel.jump"] = {
		varname = "jump",
		binds = {
			event = "touch",
			method = bindHelper.self("onJump")
		}
	},
	["movePanel.leftMove"] = {
		varname = "leftMove",
		binds = {
			event = "touch",
			method = bindHelper.self("onLeftMove")
		}
	},
	["movePanel.rightMove"] = {
		varname = "rightMove",
		binds = {
			event = "touch",
			method = bindHelper.self("onRightMove")
		}
	},
	["movePanel"] = "movePanel",
	["cannonPanel1"] = "cannonPanel1",
	["cannonPanel2"] = "cannonPanel2",
	["cannonPanel3"] = "cannonPanel3",
	["cannonPanel4"] = "cannonPanel4",
	["mask"] = "mask",
	["mask.maskAttr"] = "maskAttr",
	["mask.maskAttr.fast"] = {
		varname = "fastAttr",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onFastAttr")}
		}
	},
	["mask.maskAttr.fast.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(40, 88, 187, 255), size = 4}, color = ui.COLORS.NORMAL.WHITE}
		}
	},
	["mask.maskAttr.power"] = {
		varname = "powerAttr",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPowerAttr")}
		}
	},
	["mask.maskAttr.power.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(221, 127, 5, 255), size = 4}, color = ui.COLORS.NORMAL.WHITE}
		}
	},
	["mask.maskAttr.size"] = {
		varname = "sizeAttr",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSizeAttr")}
		}
	},
	["mask.maskAttr.size.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(215, 69, 69, 255), size = 4}, color = ui.COLORS.NORMAL.WHITE}
		}
	},
	["mask.maskAttr.explain"] = "explain",
	["mask.random"] = "randomStart",
	["mask.random.btnRandom"] = {
		varname = "btnRandom",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("randomAnimation")}
		}
	},
	["mask.random.imgRandom"] = "imgRandom",
	["panelCountDown"] = "panelCountDown",
	["panelCountDown.textNum"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(118, 24, 0, 130), size = 8}, color = cc.c4b(255, 246, 61, 255)}
		}
	},
	["panelCountDown.victoryRule"] = "victoryRule",
	["mask.random.player"] = "randomPlayer",
	["mask.random.ai"] = "randomAi",
	["matchPoint"] = "matchPointMask",
}

function VolleyBallGame:onCreate(activityId, data)
	self.unitId = {}
	self.moveCount = {
		left = false,
		right = false,
	}
	self.activityId = activityId
	self:enableSchedule()
	gGameUI:setMultiTouches(true)

	self.isGuide = data == 0 and (not userDefault.getForeverLocalKey("volleyballGame", false))
	if self.isGuide then
		self.mask:hide()
		self:checkGuide(1)
	else
		gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
			:init({title = gLanguageCsv.volleyballGame})
	end
	self.stockPro1 = idler.new(0)
	self.stockPro2 = idler.new(0)
end

function VolleyBallGame:initData()
	self.score = {0, 0}
	self.matchPoint = {0, 0}
	self.matchPointEffect = {}
	self.gameOverSign = false
	self.outBoundTimes = {0, 0}

	self.netSize = self.net:size()
	self.netPos = {}
	self.netPos.x, self.netPos.y = self.net:getPosition()

	self.ball = Ball.new(self.netPos, self.netSize)
	local data = self:randomeExtract(1)
	self.player = Sprite.new(self.netPos, self.netSize, data, 1)

	data = self:randomeExtract(2)
	self.robot = Sprite.new(self.netPos, self.netSize, data, 2)
end

-- 创建资源
function VolleyBallGame:createSpriteRes()
	self.player:createImage(self.bg, self.stockPile1, self.stockPro1)
	self.robot:createImage(self.bg, self.stockPile2, self.stockPro2)

	local sx, sy = self.skill:getPosition()
	self.energyProgress = cc.ProgressTimer:create(cc.Sprite:create("activity/volleyball/btn_jn_q.png"))
		:setReverseDirection(false)
		:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
		:addTo(self.skill, 4)
		:alignCenter(self.skill:size())
		:scale(1)
		:anchorPoint(0.5, 0.5)

	local effectPanel = self.selfScore
	local effectAni = "effect_wofang_loop"
	-- 赛点特效
	for i = 1, 2 do
		local x, y = effectPanel:getPosition()
		if i == 2 then
			effectPanel = self.enemyScore
			effectAni = "effect_difang_loop"
			x, y = effectPanel:getPosition()
		end
		self.matchPointEffect[i] = widget.addAnimationByKey(effectPanel, "volleyball_saidian/saidian.skel", effectAni, effectAni, 10)
			:xy(x - 125, y - 35)
			:scale(2)
			:hide()
	end

	self.skillEffect = widget.addAnimationByKey(self.skill, "volleyball_skill/jineng.skel", "jineng", "effect_loop1", 10)
		:alignCenter(self.skill:size())
		:scale(0.5)
		:anchorPoint(0.5, 0.5)
		:hide()

end

function VolleyBallGame:createBallRes()
	local ballInitPos = {self.player.headCenterPos, self.robot.headCenterPos}
	self.robot.initPos = self.robot.pos
	self.player.initPos = self.player.pos
	self.player.initBonePos = self.player.image:getBonePosition("tou")
	self.ball:createImage(self.bg, ballInitPos)
end

function VolleyBallGame:randomeExtract(force)
	local units = {}
	for _, v in csvPairs(csv.volleyball_unit) do
		if force == 2 then
			for time = 1, v.ranWeight do
				table.insert(units, v)
			end
		elseif v.attrType == self.selectAttrType then
			table.insert(units, v)
		end
	end
	local k = math.random(1, table.length(units))
	self.unitId[force] = units[k].id
	-- if force == 1 then
	-- 	return csv.volleyball_unit[92]
	-- elseif force == 2 then
	-- 	return csv.volleyball_unit[92]
	-- end
	return units[k]
end

-- 精灵和球碰撞
function VolleyBallGame:collision(sprite)
	local function hitAngle(dx, dy, hitRadius)
		-- 圆心距的平方
		local d = (self.ball.radius + hitRadius) * (self.ball.radius + hitRadius) - dx * dx - dy * dy
		-- hit
		if d > 0 then
			local rad = math.atan2(dy, dx)
			local deg = math.deg(rad)
			-- upside
			if deg < 180 then return deg end
			-- downside
			-- avoid the ball speed too fast
			return deg - 180
		end
	end

	local ballX, ballY = self.ball.pos.x, self.ball.pos.y
	local headCenterX, headCenterY = sprite.headCenterPos.x, sprite.headCenterPos.y

	local angle = hitAngle(ballX - headCenterX, ballY - headCenterY, sprite.hitRadius)
	local preAngle = hitAngle(ballX - headCenterX, ballY - headCenterY, 5 * sprite.hitRadius)

	if preAngle then
		self:notifySprite(sprite, {
			name = "playPreHitAni",
			node = self
		})
	end

	if angle then
		-- printDebug("%s 碰撞角度: %.2f", sprite.force == 1 and "玩家" or "机器人", angle)
		self.robot.batSign = (sprite.force == 2)
		self.player.batSign = (sprite.force == 1)

		if sprite.force == 2 and sprite.slowSpeedSign == true then
			sprite.slowSpeedRate = self.player.slowSpeedRate
			sprite.slowSpeedSign = false
			self.player.slowSpeedRate = 1
			self:notifySprite(sprite, {
				name = "playSkillAni",
			})
			self:notifyBall(sprite, {
				name = "playSkillAni",
				reset = true
			})
		end

		self:notifySprite(sprite, {
			name = "playHitAni",
			node = self
		})
		self:notifyBall(sprite, {
			name = "collision",
		})
		self:notifySprite(self.robot, {
			name = "hit",
			hitForce = sprite.force,
		})
	end
end

function VolleyBallGame:notifyBall(sprite, event)
	local f = self.ball["onEvent_"..event.name]
	if f == nil then return end

	f(self.ball, sprite, event)
end

function VolleyBallGame:notifySprite(sprite, event)
	local f = sprite["onEvent_"..event.name]
	if f == nil then return end

	f(sprite, self.ball, event)
end

function VolleyBallGame:updateView()
	self.ball:updateView()
	self.robot:updateView()
	self.player:updateView()
	self.energyProgress:setPercentage(math.min(6, self.player.batTimes) * 100 / 6)
end

function VolleyBallGame:gameStart()
	gGameApp:requestServer("/game/yy/volleyball/start", function (tb)
		self:keyboardMonitor()
		self.panelCountDown:hide()
		self.bg:scheduleUpdate(function()
			-- 碰撞
			self:collision(self.robot)
			self:collision(self.player)

			-- 移动
			self.ball:move()
			self.robot:move()
			self.player:move()

			-- 蓄力
			self.robot:stockpile()
			self.player:stockpile()

			-- 更新view
			self:updateView()

			-- 更新分数
			self:updateScore()

			-- 胜负判定
			self:checkResult()
			if self.gameOverSign then return false end
		end)
		self.gameTime = 0
		self:schedule(function(dt)
			self.gameTime = self.gameTime + 0.1
		end, 0.1, 0, "gameTime")
	end, self.activityId)
end

function VolleyBallGame:updateScore()
	local netPos = self.netPos
	local netSize = self.netSize
	local netHeight = netPos.y + netSize.height / 2
	local ballX, ballY = self.ball.pos.x, self.ball.pos.y
	local ballSpX, ballSpY = self.ball.speed.x, self.ball.speed.y
	-- 落地判定
	if ballY <= self.ball.floorY then
		local winForce = 1
		if ballX > netPos.x and ballX < netPos.x + 570 then self.score[1] = self.score[1] + 1
		else
			winForce = 2
			-- 出界
			if ballX >= netPos.x + 570 or ballX <= netPos.x - 570 then
				self.outBoundTimes[1] = self.outBoundTimes[1] + 1
			end
			self.score[2] = self.score[2] + 1
		end
		self.selfScore:text(string.format("%d", self.score[1]))
		self.enemyScore:text(string.format("%d", self.score[2]))
		self:hideOpBtn()
		self.ball:reset(winForce)
		self.robot:reset()
		self.player:reset()
		self.skillEffect:hide()
	end
	-- 过网判定
	if ballX >= netPos.x and ballY > netHeight and ballSpX > 0 and self.player.batSign then
		self.player.batSign = false
		self.ball.serveAction = false
		self.player.batTimes = self.player.batTimes + 1
		if self.player.batTimes >= 6 then
			self.skillEffect:show()
			self.skillEffect:play("effect_loop2")
		elseif self.player.batTimes >= 3 then
			self.skillEffect:show()
			self.skillEffect:play("effect_loop1")
		end
	elseif ballX < netPos.x and ballY > netHeight and ballSpX < 0 and self.robot.batSign then
		self.robot.batSign = false
		self.ball.serveAction = false
		self.robot.batTimes = self.robot.batTimes + 1
	end
	-- 显示击球数
	-- self.textScore:text(string.format("%d : %d", self.player.batTimes, self.robot.batTimes))
end

function VolleyBallGame:checkResult()
	for i = 1, 2 do
		if self.score[i] == 2 and self.matchPoint[i] == 0 then
			local tmp = self.ball.gravity
			self.ball.gravity = 0
			self.ball.image:hide()
			self.ball.shadow:hide()
			self.robot.image:hide()
			self.robot.isHideState = true
			self.player.image:hide()
			self.matchPointMask:show()
			self.matchPointEffect[i]:show()
			performWithDelay(self, function()
				self.matchPointMask:hide()
				-- self.matchPointEffect[i]:hide()
				self.ball.image:show()
				self.robot.image:show()
				self.robot.isHideState = false
				self.player.image:show()
				self.ball.shadow:show()
				-- self.ball:reset()
				-- self.robot:reset()
				-- self.player:reset()
				self.ball.gravity = tmp
			end, 2)
			self.matchPoint[i] = 1
		end
	end

	if (self.score[1] >= 3 or self.score[2] >= 3) and not self.gameOverSign then
		self.gameOverSign = true
		self.player.image:play("win_loop")
		local tasks = {}
		tasks[102] = self.score[1]
		tasks[202] = self.unitId[2]
		tasks[203] = self.outBoundTimes[1]
		tasks[204] = self.unitId[1]
		tasks[206] = self.robot.skillHitTimes[1]
		tasks[207] = self.robot.skillHitTimes[2]
		self:gameOver()
		local result = (self.score[1] >= 3) and 1 or 0
		gGameApp:requestServerCustom("/game/yy/volleyball/end")
			:onErrClose(function() ViewBase.onClose(self) end)
			:params(self.activityId, (result == 1 and "win" or "fail"), self.gameTime, tasks)
			:doit(function(tb)
				self:showGameEnd(result, self.score, self.unitId[1])
			end)
	end
end

function VolleyBallGame:enterCourt()
	self.player.pos.x = self.player.pos.x + 6
	self.robot.pos.x = self.robot.pos.x - 6
	self.robot:updateView()
	self.player:updateView()
end

--倒计时
function VolleyBallGame:startCount()
	self.victoryRule:hide()
	local num = 60
	local textNum = self.panelCountDown:get("textNum")
	textNum:scale(1.5)
	textNum:text(num / 20)
	textNum:show()
	self:createSpriteRes()
	self:schedule(function (dt)
		if num > 0 then
			if num % 20 == 0 then
				local text = textNum
				textNum:text(num / 20)
				textNum:runAction(cc.ScaleTo:create(0.5, 1))
			end
			self:enterCourt()
			num = num - 1
		else
			self:createBallRes()
			self:gameStart()
			return false
		end
	end, 0.05, 0, 663)
end

function VolleyBallGame:gameOver()
	self.bg:unscheduleUpdate()
	self:disableSchedule()
end

function VolleyBallGame:onClose()
	if self.isGuide then
		--gGameUI:showTip(gLanguageCsv.guideTip)
		return
	end
	local function cb()
		gGameUI:setMultiTouches(false)
		self:gameOver()
		ViewBase.onClose(self)
	end
	if self.score and (self.score[1] >= 3 or self.score[2] >= 3) then
		cb()
	else
		gGameUI:showDialog({
			content = "#C0x5b545b#"..gLanguageCsv.confirmEndGame,
			cb = cb,
			btnType = 2,
			isRich = true,
			dialogParams = {clearFast = true, clickClose = false},
		})
	end
end

function VolleyBallGame:onFreedPalsy(sender, event)
	if not self.player or not self.robot then return end
	if event.name == "began" then
		-- self.skill:get("click"):show()
		self:notifySprite(self.player, {
			name = "palsy",
		})
		if self.player.slowSpeedRate < 1 then
			self.robot.slowSpeedSign = true
			self:notifyBall(self.player, {
				name = "playSkillAni",
				reset = false
			})
		end
		self.skillEffect:hide()
	elseif event.name == "cancelled" or event.name == "ended" then
		-- self.skill:get("click"):hide()
	end
end

function VolleyBallGame:onStoragePower(sender, event)
	if not self.player then return end
	if event.name == "began" then
		self.player.stockpileSign = true
		self.storage:get("click"):show()
	elseif event.name == "cancelled" or event.name == "ended" then
		self.player.stockpileSign = false
		self.storage:get("click"):hide()
	end
end

function VolleyBallGame:onLeftMove(sender, event)
	if not self.player then return end
	if event.name == "began" then
		self.player.speed.x = -self.player.lrSpeedDelta
		self.moveCount.left = true
		self.leftMove:get("click"):show()
	elseif event.name == "cancelled" or event.name == "ended" then
		self.moveCount.left = false
		if self.moveCount.right then
			self.player.speed.x = self.player.lrSpeedDelta
		else
			self.player.speed.x = 0
		end
		self.leftMove:get("click"):hide()
	end
end

function VolleyBallGame:onRightMove(sender, event)
	if not self.player then return end
	if event.name == "began" then
		self.player.speed.x = self.player.lrSpeedDelta
		self.moveCount.right = true
		self.rightMove:get("click"):show()
	elseif event.name == "cancelled" or event.name == "ended" then
		self.moveCount.right = false
		if self.moveCount.left then
			self.player.speed.x = -self.player.lrSpeedDelta
		else
			self.player.speed.x = 0
		end
		self.rightMove:get("click"):hide()
	end
end

function VolleyBallGame:onJump(sender, event)
	if not self.player then return end
	if event.name == "began" then
		if self.player.operateAni ~= "effect_daqiu1" then
			self:notifySprite(self.player, {
				name = "playJumpAni",
				node = self
			})
		end
		self.jump:get("click"):show()
		-- local player = self.player
		-- if player.pos.y <= player.floorY + 10 and not player.stockpileSign then
		-- 	player.speed.y = player.udSpeedDelta
		-- end
	elseif event.name == "cancelled" or event.name == "ended" then
		self.jump:get("click"):hide()
	end
end

function VolleyBallGame:hideOpBtn()
	self.leftMove:get("click"):hide()
	self.rightMove:get("click"):hide()
	self.jump:get("click"):hide()
	self.storage:get("click"):hide()
end

function VolleyBallGame:hideAttrBtn()
	self.randomPlayer:texture("config/big_hero/normal/img_25_pkq@.png")
	self.randomAi:texture("config/big_hero/normal/img_25_pkq@.png")
	cache.setShader(self.randomPlayer, false, "black")
	cache.setShader(self.randomAi, false, "black")
	self.maskAttr:hide()
	self.randomStart:show()
	if self.isGuide then
		self.randomStart:setTouchEnabled(false)
		self:createGuide(10, function()
			self.isGuide = false
			userDefault.setForeverLocalKey("volleyballGame", true)
			self.randomStart:setTouchEnabled(true)
			gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
				:init({title = gLanguageCsv.volleyballGame})
		end)
	end
end

function VolleyBallGame:onFastAttr()
	self.selectAttrType = 1
	self:hideAttrBtn()
end

function VolleyBallGame:onPowerAttr()
	self.selectAttrType = 2
	self:hideAttrBtn()
end

function VolleyBallGame:onSizeAttr()
	self.selectAttrType = 3
	self:hideAttrBtn()
end

function VolleyBallGame:onRandomStart()
	self.btnRandom:show()
	self.mask:hide()
	self.panelCountDown:show()
	self.panelCountDown:get("textNum"):hide()
	self.victoryRule:show()
	performWithDelay(self, function()
		self:startCount()
	end, 2)
end

-- 键盘移动
function VolleyBallGame:keyboardMonitor()
	if device.platform ~= "windows" then
		return
	end
	local player = self.player
	-- 键盘按键按下回调函数
	local function keyboardPressed(keyCode, event)
		-- 左
		if keyCode == 124 then
			self:onLeftMove(nil, {name = "began"})
		end
		-- 右
		if keyCode == 127 then
			self:onRightMove(nil, {name = "began"})
		end
		-- 上
		if keyCode == 146 and player.pos.y <= player.floorY + 10 and not player.stockpileSign then
			player.speed.y = player.udSpeedDelta
		end
		-- 开始蓄力
		if keyCode == 59 then
			player.stockpileSign = true
		end
		-- if player.stockpileSign then player.speed.x = player.speed.x / 2 end
	end

	-- 键盘按键松开回调函数
	local function keyboardReleased(keyCode, event)
		-- 结束蓄力
		if keyCode == 59 then
			player.stockpileSign = false

		elseif keyCode == 124 then
			self:onLeftMove(nil, {name = "ended"})

		elseif keyCode == 127 then
			self:onRightMove(nil, {name = "ended"})
		end
	end

	-- 注册键盘监听事件
	local listener = cc.EventListenerKeyboard:create()

	-- 绑定回调函数
	listener:registerScriptHandler(keyboardPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
	listener:registerScriptHandler(keyboardReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function VolleyBallGame:checkGuide(id)
	if id >= 9 then
		self.mask:show()
		self:createGuide(9)
		return
	end
	self:createGuide(id, function()
		self:checkGuide(id+1)
	end)
end

--初始化引导
function VolleyBallGame:createGuide(index, guideEndCb)
	local function createMask(pos, offsetX)
		if self:get("maskPanel") then
			self:get("maskPanel"):removeFromParent()
		end
		local maskPanel = ccui.Layout:create()
			:size(display.sizeInView.width, display.sizeInView.height)
			:anchorPoint(0.5,0.5)
			:xy(display.center)
			:addTo(self, 5, "maskPanel")
		local texR = ccui.ImageView:create("login/new_character/img_tjltm@.png")
			:xy(pos.x > display.sizeInView.width/2 and pos.x - offsetX - 150 or pos.x + offsetX + 850, pos.y >  display.sizeInView.height/2 and pos.y - 200 or pos.y + 200 )
			:addTo(maskPanel, 2)
		local textBg = ccui.ImageView:create("city/gate/bg_dialog.png")
		textBg:setScale9Enabled(true)
		textBg:setCapInsets({x = 77, y = 58, width = 1, height = 1})
		textBg:addTo(texR)
		textBg:xy(-160, 200)
		textBg:width(500)

		local txt = rich.createWithWidth("#C0x5b545b#" .. GUIDE_CONFIG[index].content, 40, nil, 450)
			:anchorPoint(0, 0)
			:addTo(textBg, 3, "talkContent")
			:xy(25, 50)
		textBg:height(txt:height() + 80)
		return maskPanel
	end

	local targetNode = GUIDE_CONFIG[index] and self[GUIDE_CONFIG[index].nodeName]
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
			if maskPanel and isNormal then
				if self:get("maskPanel") then
					self:get("maskPanel"):removeFromParent()
				end
				maskPanel = nil
			end
			if guideEndCb then
				guideEndCb(self)
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
		if guideEndCb then
			guideEndCb(self)
		end
	end

end

function VolleyBallGame:showGameEnd(result, score, unitId)
	local data = {
		res = self.player.res,
		result = result,
		score = score,
		unitId = unitId
	}
	gGameUI:stackUI("city.activity.volleyball.game_over", nil, nil, self, data)
end

function VolleyBallGame:resetGame()
	self:hideOpBtn()
	self:enableSchedule()
	self.ball:deleteImage()
	self.robot:deleteImage()
	self.player:deleteImage()
	self.energyProgress:removeSelf()
	self.mask:show()
	self.maskAttr:show()
	self.skillEffect:hide()
	self.randomStart:hide()
	self.panelCountDown:get("textNum"):text(3)
	self.selfScore:text(string.format("%d", 0))
	self.enemyScore:text(string.format("%d", 0))
	self.matchPointEffect[1]:hide()
	self.matchPointEffect[2]:hide()

	self.moveCount = {
		left = false,
		right = false,
	}
end

function VolleyBallGame:randomAnimation()
	self.btnRandom:hide()
	self.imgRandom:show()
	widget.addAnimationByKey(self.imgRandom, "volleyball_suijizhong/suijizhong.skel", "suijiEffect", "effect_loop", 10)
		:alignCenter(self.imgRandom:size())
		:scale(1.5)

	self:initData()
	local player, ai = self.unitId[1],self.unitId[2]
	local allData = {}
	for _, v in csvPairs(csv.volleyball_unit) do
		table.insert(allData, csv.unit[v.id].cardShow)
	end
	local showTime, mod , time, maxTime = 1, 1, 1, 4 * 4
	local num, count, imgChange = #allData, 1, 1
	self:enableSchedule()
	self:schedule(function(dt)
		if (count - showTime) == imgChange then
			if count < 60 then
				local sumPlayer = math.random(1, num)
				local sumAi = math.random(1, num)
				self.randomPlayer:texture(allData[sumPlayer])
				self.randomAi:texture(allData[sumAi])
			else
				self.randomPlayer:texture(csv.unit[player].cardShow)
				self.randomAi:texture(csv.unit[ai].cardShow)
			end
			cache.setShader(self.randomPlayer, false, "black")
			cache.setShader(self.randomAi, false, "black")
			showTime = count
		end
		--dts = dts%num + 1
		count = count + 1
		if count > 15 * mod then
			imgChange = 2 + imgChange
			mod = mod + 1
		end
		if count >= 75 then
			self.imgRandom:hide()
			self.randomPlayer:texture(csv.unit[player].cardShow)
			self.randomAi:texture(csv.unit[ai].cardShow)
			cache.setShader(self.randomPlayer, false, "normal")
			cache.setShader(self.randomAi, false, "normal")
			self:unSchedule("randomAnimation")
			 performWithDelay(self, function()
				 self:onRandomStart()
			 end, 2)
			return
		end
	end, 1/15, 0, "randomAnimation")
end

return VolleyBallGame