
local animaTab = {"diuqiu_effect", "cjq_diuqiu_effect", "dsq_diuqiu_effect"} --抛出小球
local animaWin = {"chenggong_effect", "cjq_chenggong_effect", "dsq_chenggong_effect"} --捕捉成功
local spriteBall = {"jinglinqiu_effect_loop", "cjq_jinglinqiu_effect_loop", "dsq_jinglinqiu_effect_loop"} --精灵球
local animaFailedBg = {"shibai1_effect", "shibai2_effect", "shibai3_effect"}			--失败背景效果
local animaFailed = {																	--捕捉失败
	{"shibai1_effect", "shibai2_effect", "shibai3_effect"},
	{"cjq_shibai1_effect", "cjq_shibai2_effect", "cjq_shibai3_effect"},
	{"dsq_shibai1_effect", "dsq_shibai2_effect", "dsq_shibai3_effect"}
}
local spriteAudio = {"capture/shibai1_effect.mp3", "capture/shibai2_effect.mp3", "capture/shibai3_effect.mp3"}


local ViewBase = cc.load("mvc").ViewBase
local CaptureSpriteView = class("CaptureSpriteView", ViewBase)

CaptureSpriteView.RESOURCE_FILENAME = "capture_sprite.json"
CaptureSpriteView.RESOURCE_BINDING = {
	["anima"] = "anima",
	["titleUp"] = "titleUp",
	["btn1"] = "btn1",
	["btn2"] = "btn2",
	["btn3"] = "btn3",
	["bg"] = "bg",
	["ball1"] = "ball1",
	["ball2"] = "ball2",
	["ball3"] = "ball3",
}
CaptureSpriteView.RESOURCE_STYLES = {
	full = true,
}

local function probabilityToStr(probability)
	for k, v in orderCsvPairs(csv.capture.probability) do
		if probability >= v.probability then
			return v.desc
		end
	end
	return ""
end

function CaptureSpriteView:initModel()
	self.level = gGameModel.capture:getIdler("level")
	self.captureNumber = gGameModel.role:getIdler("items")
	self.limit = gGameModel.capture:getIdler("limit_sprites")
	self.levelBall = gGameModel.role:getIdler("level")
	self.gold = gGameModel.role:getIdler("gold")
end

function CaptureSpriteView:onCreate(tab, gateId, cb)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.capture, subTitle = "CATCH"})

	self.cb = cb
	self.gateId = gateId
	self.captureTab = tab
	self.numberUsed = tab.sceneTimes
	self:initModel()
	self.itemMove = true
	self.ballData = true
	self.captureTabId = {523, 524, 525}
	self.timeTab = {5, 4, 3}
	local postab = {600, 100, -400}
	self.animaData = {
		btnClickState = 1, 	--动画：1默认 2点击小球 3抛出小球
		btnClickData = nil, --点击的小球的id
		closeDate = true,	--播放动画时不能退出
	}

	local unitId = csv.cards[tab.cardID].unitID
	local unitCfg = csv.unit[unitId]
	local spriteScale = unitCfg.scale * gCommonConfigCsv.captureSprite
	self.cardSprite = widget.addAnimation(self.anima:get("state"), unitCfg.unitRes, "standby_loop", 5)
		:alignCenter(self.anima:get("state"):size())
		:scale(spriteScale)
	self.cardSprite:setSkin(unitCfg.skin)

	self.captureBgAnima = widget.addAnimation(self.bg, "diuqiu/buzhuo_di.skel", "daiji_loop", 3)
		:alignCenter(self.bg:size())

	self.titleUp:get("number"):text(self.numberUsed.."/"..self.numberUsed)

	--小球次数
	idlereasy.when(self.captureNumber, function(_, mapOpen)
		local levelSuccess = csv.capture.level[self.level:read()].rateUp
		for i=1,3 do
			if self.captureNumber:read()[self.captureTabId[i]] then
				self["btn"..i]:get("title.number"):text('x '..self.captureNumber:read()[self.captureTabId[i]])
			else
				self["btn"..i]:get("title.number"):text('x '..0)
			end
		end
	end)
	--升级概率
	idlereasy.when(self.level, function(_, level)
		local levelSuccess = csv.capture.level[self.level:read()].rateUp --等级概率
		local probability
		if self.animaData.btnClickData then
			probability = math.floor(levelSuccess * tab["rate"..self.animaData.btnClickData])
			self["btn"..self.animaData.btnClickData]:get("success.success"):text(probabilityToStr(probability))
		else
			for i=1,3 do
				probability = math.floor(levelSuccess * tab["rate"..i])
				self["btn"..i]:get("success.success"):text(probabilityToStr(probability))
			end
		end
	end)

	for i=1, 3 do
		self["ball"..i]:addTouchEventListener(function(sender, eventType)
			if eventType == ccui.TouchEventType.began then
				self.ballNumber = self.captureNumber:read()[self.captureTabId[i]]
				if not self.ballNumber or self.ballNumber <= 0 then
					self.ballData = false
					self["btn"..i]:get("title.number"):text('x '..0)
					if i == 1 then
						gGameUI:showTip(gLanguageCsv.captureBallNotEnough)
						self:buyerBall(i)
					elseif i ==2 then
						gGameUI:showTip(gLanguageCsv.canBuyInBoutique)
					else
						gGameUI:showTip(gLanguageCsv.getInActOrMysteryShop)
					end
					return
				else
					self.ballData = true
				end

				if self.animaData.btnClickState == 1 then
					self["ball"..i]:setEnabled(false)
					self.animaData.btnClickState = 2
					self.animaData.btnClickData = i
					if not self.spriteBall and not self.guideBall then
						self.spriteBall = widget.addAnimation(self["ball"..i]:get("ball"), "diuqiu/buzhuo.skel", spriteBall[i], 3)
							:alignCenter(self["ball"..i]:get("ball"):size())
							:scale(1.8)
						self.guideBall = widget.addAnimation(self["ball"..i], "diuqiu/buzhuo.skel","yindao_effect_loop", 3)
							:xy(self.spriteBall:x()+260, self.spriteBall:y()+400)
							:scale(0.65)
					end
					self:captureChangeView(i, -1000)
				end
				self.touchBeganPos = sender:getTouchBeganPosition()
				self.btnClickView = false
			elseif eventType == ccui.TouchEventType.moved then
				if not self.ballData then return end
				if self.animaData.btnClickState ~= 2 then return end
				local pos = sender:getTouchMovePosition()
				local deltaY = pos.y - self.touchBeganPos.y
				if deltaY >= 20 then
					self.btnClickView = true
				else
					self.btnClickView = false
				end
			elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
				if self.animaData.btnClickState ~= 2 then return end
				if not self.btnClickView then
					self:captureChangeView(i, 0)
					return
				end
				if not self.ballData then return end
				self.animaData.closeDate = false
				audio.playEffectWithWeekBGM("capture/diuqiu_effect.mp3")
				if self.spriteBall or self.guideBall then
					self.spriteBall:hide()
					self.guideBall:hide()
				end
				self.animaData.btnClickState = 3
				self.castBallAnima = widget.addAnimation(self["ball"..i]:get("castAnima"), "diuqiu/buzhuo.skel", animaTab[i], 5)
					:xy(postab[i], 600)
					:scale(2)
				performWithDelay(self, function()
					self.anima:runAction(
						cc.Sequence:create(
							cc.ScaleBy:create(0.2, 0.3),
							cc.CallFunc:create(function()
								self.cardSprite:visible(false)
							end)
						)
					)
				end, 0.8)
				performWithDelay(self, function()
					if self.castBallAnima then
						self.castBallAnima:removeFromParent()
						self.castBallAnima = nil
					end
					self:onChangeClick(i)
				end, 1.3)
			end
		end)
	end
end

function CaptureSpriteView:captureChangeView(id, move)
	--双层保障快速滑动
	if (self.itemMove and move >= 0) or (not self.itemMove and move < 0) then
		return
	end
	for i=1,3 do
		self["btn"..i]:stopAllActions()
		if id ~= i then
			self["btn"..i]:runAction(cc.MoveTo:create(0.2, cc.p(self["btn"..i]:x(), 283 + move)))
			self["ball"..i]:visible(move >= 0)
		end
	end
	if move >= 0 then
		self["btn"..id]:visible(true)
		self["btn"..id]:scale(1)
		if self.spriteBall and self.guideBall then
			self.spriteBall:removeFromParent()
			self.spriteBall = nil
			self.guideBall:removeFromParent()
			self.guideBall = nil
		end
		self.animaData.closeDate = true
		self.itemMove = true
		self["ball"..id]:setEnabled(true)
		self.animaData.btnClickState = 1
	else
		self["btn"..id]:visible(false)
		self.itemMove = false
	end
end

function CaptureSpriteView:onChangeClick(data)
	local random = math.random(1,3)
	gGameApp:requestServer("/game/capture", function(tb)
		if csvNext(tb.view.result) then
			if not self.resultAnima then
				self.resultAnima = widget.addAnimation(self.anima, "diuqiu/buzhuo.skel", animaWin[data], 2)
					:scale(5)
					:alignCenter(self.anima:size())
				self.resultAnima:y(self.resultAnima:y()-40)
			else
				self.resultAnima:show():play(animaWin[data])
				self.resultAnima:scale(5)
			end
			self.captureBgAnima:play("chenggong_effect")
			audio.playEffectWithWeekBGM("capture/chenggong_effect.mp3")
			local info = {}
			info.db_id = tb.view.result.carddbIDs[1][1]
			info.first = tb.view.result.carddbIDs[1][2]
			performWithDelay(self, function()
				gGameUI:stackUI("common.gain_sprite", nil, {full = true}, info, nil, false, self:createHandler("captureWin"))
			end, 5.5)
		else
			audio.playEffectWithWeekBGM(spriteAudio[random])
			self.captureBgAnima:play(animaFailedBg[random])
			if not self.resultAnima then
				self.resultAnima = widget.addAnimation(self.anima, "diuqiu/buzhuo.skel", animaFailed[data][random], 2)
					:alignCenter(self.anima:size())
					:scale(5)
				self.resultAnima:y(self.resultAnima:y()-40)
			else
				self.resultAnima:show():play(animaFailed[data][random])
				self.resultAnima:scale(5)
			end
			performWithDelay(self, function()
				audio.playEffectWithWeekBGM("capture/fanhui_effect.mp3")
			end, self.timeTab[random] - 1)
			performWithDelay(self, function()
				self.titleUp:get("number"):text((self.numberUsed - tb.view.scene_times).."/"..self.numberUsed)
				self.resultAnima:scale(3)
				self.resultAnima:play("fanhui_effect")
				self.captureBgAnima:play("fanhui_effect")
				performWithDelay(self, function()
					self.cardSprite:visible(true)
					self.anima:scale(1)
				end, 0.3)
				performWithDelay(self, function()
					self.captureBgAnima:play("daiji_loop")
					self:captureChangeView(data, 0)
					if tb.view.scene_times == self.numberUsed then
						gGameUI:stackUI("city.capture.capture_over", nil, nil, self:createHandler("captSpriteCloseView"))
						return
					end
				end, 0.8)
			end, self.timeTab[random])
		end
	end, self.captureTab.type, self.gateId, self.captureTabId[data])
end

function CaptureSpriteView:captureWin()
	self:captureChangeView(self.animaData.btnClickData, 0)
	self:captSpriteCloseView()
	return
end

function CaptureSpriteView:buyerBall(data)
	if data ~= 1 then
		gGameUI:showTip(gLanguageCsv.captureBallNotEnough)
	 	return
	end
	--购买框
	local gold = csv.items[game.SPRITE_BALL_ID.normal].specialArgsMap.buy_gold
	local maxBuyNum = 100
		gGameUI:stackUI("common.buy_info", nil, nil,
			{gold = gold},
			{id = game.SPRITE_BALL_ID.normal},
			{maxNum = maxBuyNum, contentType = "num"},
			self:createHandler("showBuyInfo")
		)
end

function CaptureSpriteView:showBuyInfo(data)
	--等级是否满足购买道具
	if csv.items[game.SPRITE_BALL_ID.normal].specialArgsMap.buy_level > self.levelBall:read() then
		gGameUI:showTip(gLanguageCsv.buyItemLevelLimit)
		return
	else
		gGameApp:requestServer("/game/ball/buy_item", function(tb)
			gGameUI:showTip(gLanguageCsv.hasBuy)
		end, game.SPRITE_BALL_ID.normal, data)
	end
end

function CaptureSpriteView:onClose()
	if not self.animaData.closeDate then return end
	gGameUI:showDialog({title = gLanguageCsv.abandon, content = gLanguageCsv.spriteClose, cb = function()
		ViewBase.onClose(self)
	end, btnType = 2, clearFast = true})
end

function CaptureSpriteView:captSpriteCloseView(data)
	--次数用完未扑捉精灵不消失，扑捉精灵销毁精灵按钮节点
	if self.cb then
		self.cb(data)
	end
end

return CaptureSpriteView