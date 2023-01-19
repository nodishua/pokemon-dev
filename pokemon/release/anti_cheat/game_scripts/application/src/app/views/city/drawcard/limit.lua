local t = {}

local drawCardTools = require "app.views.city.drawcard.tools"

function t.initPageItemFunc(self, curType, goldCount, diamondCount, allCount, half, trainerCount, equipCount, drawEquipCount)
	local efcBg = self:addEffectInRect("effect/xianshichouka.skel")
	self.isLimitDraw:set(true)
	self.isCutDown:set(false)
	self.isFree:set(false)
	self.isCost:set(true)
	local paramMap = csv.yunying.yyhuodong[self.limitDataId].paramMap
	local clientParam = csv.yunying.yyhuodong[self.limitDataId].clientParam

	local onePath = "common/icon/icon_diamond.png"
	local tenPath = "common/icon/icon_diamond.png"
	local costOnece = paramMap.RMB1
	local costTen = paramMap.RMB10
	local equipCard = dataEasy.getNumByKey(game.ITEM_TICKET.limitCard)
	if not isFree and equipCard > 0 then
		onePath = dataEasy.getIconResByKey(game.ITEM_TICKET.limitCard)
		costOnece = string.format("%s/%s", equipCard, 1)
	end
	if equipCard >= 10 then
		tenPath = dataEasy.getIconResByKey(game.ITEM_TICKET.limitCard)
		costTen = string.format("%s/%s", equipCard, 10)
	end
	self.oneIconPath:set(onePath)
	self.tenIconPath:set(tenPath)
	self.drawOnceCost:set(costOnece)
	self.drawTenCost:set(costTen)

	-- 设置时间
	local limitPanel = self.limitPanel
	limitPanel:removeChildByName("richText")
	self:initCountDown(limitPanel)
	-- 设置中间精灵信息
	local cfg = csv.yunying.draw_limit[clientParam.limitId]
	local isSingle = true
	if cfg.card2 or cfg.res2 then
		isSingle = false
	end
	local cardIds = {}
	limitPanel:get("single"):visible(isSingle)
	limitPanel:get("double"):visible(not isSingle)
	if isSingle then
		self:initCardData(cfg, limitPanel:get("single"), 1, cardIds)
	else
		efcBg:play("effect2_loop")
		local t = {"left", "right"}
		for i=1,#t do
			local targetPanel = limitPanel:get("double"):get(t[i])
			self:initCardData(cfg, targetPanel, i, cardIds)
			if t[i] == "right" then
				adapt.oneLinePos(targetPanel:get("info.img2"), targetPanel:get("info.img1"), cc.p(25, 0), "right")
			end
			adapt.oneLinePos(targetPanel:get("info.img2"), targetPanel:get("info.btnJump"), cc.p(10, 0))
		end
	end
	-- 设置title
	local strTab = {}
	local cardCsv = csv.cards
	for _,v in ipairs(cardIds) do
		table.insert(strTab, cardCsv[v].name)
	end
	limitPanel:get("title.textNote2"):text(table.concat(strTab, gLanguageCsv.symbolComma))
	local titlePanel = limitPanel:get("title")
	adapt.oneLineCenterPos(cc.p(titlePanel:get("imgBg"):xy()), {titlePanel:get("textNote1"), titlePanel:get("textNote2")})
	titlePanel:get("imgBg"):width(titlePanel:get("textNote1"):width() + titlePanel:get("textNote2"):width() + 40)
end

function t:initCountDown(limitPanel)
	local yyCfg = csv.yunying.yyhuodong[self.limitDataId]
	local hour, min = time.getHourAndMin(yyCfg.endTime)
	local endTime = time.getNumTimestamp(yyCfg.endDate,hour,min)
	local timePanel = limitPanel:get("time")
	bind.extend(self, timePanel:get("textTime"), {
		class = 'cutdown_label',
		props = {
			tag = 1,
			endTime = endTime + 1,
			callFunc = function()
				adapt.oneLineCenterPos(cc.p(timePanel:get("imgBg"):xy()), {timePanel:get("textNote"), timePanel:get("textTime")})
				timePanel:get("imgBg"):width(timePanel:get("textNote"):width() + timePanel:get("textTime"):width() + 40)
			end,
			endFunc = function()
				self.limitId:set(nil)
			end,
			onNode = function(panel)
			end
		}
	})
end

function t.isEnoughToDrawFunc(self, isTen)
	local myNumOne = self.rmb:read()
	local myNumTen = myNumOne
	local paramMap = csv.yunying.yyhuodong[self.limitDataId].paramMap
	local once = paramMap.RMB1
	local ten = paramMap.RMB10
		-- 代金券
	local target = dataEasy.getNumByKey(game.ITEM_TICKET.limitCard)
	if target > 0 then-- 至少有一张
		once = 1
		myNumOne = target
		if target >= 10 then-- 满足十连
			ten = 10
			myNumTen = target
		end
	end

	-- return myNum >= once, myNum >= ten
	if isTen then
		return myNumTen >= ten
	else
		return myNumOne >= once
	end
end

function t.drawOneClickFunc(self)
	-- 代金券
	local target = dataEasy.getNumByKey(game.ITEM_TICKET.limitCard)

	local function cb()
		gGameApp:requestServer("/game/yy/award/draw", function(tb)
			self.topView:hide()
			audio.pauseMusic()
			-- audio.playEffectWithWeekBGM("drawcard_one.mp3")
			self.isShowEffect:set(true)
			self.effectView:removeAllChildren()
			local sprite = widget.addAnimationByKey(self.effectView, "effect/xianshichouka.skel", "effect", "effect_danchou", 10)
				:scale(2)
				:alignCenter(self.effectView:size())
			local ret, spe, isFull = dataEasy.getRawTable(tb)
			local items = dataEasy.getItems(ret, spe)
			local yyCfg = csv.yunying.yyhuodong[self.limitDataId]
			local isSingle = yyCfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.timeLimitDraw
			local effectName = isSingle and "effect_bj_houduan" or "effect_bj_houduan2"
			local params = {
				items = items,
				drawType = "limit",
				times = 1,
				isFree = false,
				yyId = self.limitDataId,
				closeCb = function()
					self.isShowEffect:set(true)
					self.effectView:removeAllChildren()
					local effectBg = widget.addAnimationByKey(self.effectView, "effect/xianshichouka.skel", "effectBlack", effectName, 999)
						:scale(2)
						:alignCenter(self.effectView:size())
					effectBg:setSpriteEventHandler(function(event, eventArgs)
						self.isShowEffect:set(false)
						self.topView:show()
					end, sp.EventType.ANIMATION_COMPLETE)
				end,
			}

			local hasCard, cards = drawCardTools.hasCard(items[1])
			drawCardTools.addLight(self, {
				parent = self.effectView,
				parentEffect = sprite,
				datas = items[1],
				count = 1,
				cloneItem = self.item
			})
			performWithDelay(self.effectView, function()
				local delay = 0
				if hasCard then
					sprite:play("effect_zhanshi")
					local cardTime = drawCardTools.addCardImg(cards, self.effectView)
					delay = 70 / 30 + cardTime
				end
				performWithDelay(self, function()
					self.isShowEffect:set(false)
					gGameUI:stackUI("city.drawcard.result", nil, nil, params)
				end, delay)
			end, 35 / 30)
		end, self.limitDataId, "limit_rmb1")
	end

	if target > 0 then
		cb()
	else
		local paramMap = csv.yunying.yyhuodong[self.limitDataId].paramMap
		dataEasy.sureUsingDiamonds(cb, paramMap.RMB1)
	end
end

function t.drawTenClickFunc(self)
	local bUseDiamond = false --是否消耗钻石抽卡
	if dataEasy.getNumByKey(game.ITEM_TICKET.limitCard) < 10 then
		bUseDiamond = true
	end
	local function requesetServer()
		gGameApp:requestServer("/game/yy/award/draw", function(tb)
			self.topView:hide()
			audio.pauseMusic()
			-- audio.playEffectWithWeekBGM("drawcard_ten.mp3")
			self.isShowEffect:set(true)
			self.effectView:removeAllChildren()
			local sprite = widget.addAnimationByKey(self.effectView, "effect/xianshichouka.skel", "effect", "effect_shilianchou", 10)
				:scale(2)
				:alignCenter(self.effectView:size())

			local ret, spe, isFull = dataEasy.getRawTable(tb)
			local items = dataEasy.getItems(ret, spe)
			local yyCfg = csv.yunying.yyhuodong[self.limitDataId]
			local isSingle = yyCfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.timeLimitDraw
			local effectName = isSingle and "effect_bj_houduan" or "effect_bj_houduan2"
			local params = {
				items = items,
				drawType = "limit",
				times = 10,
				isFree = false,
				yyId = self.limitDataId,
				closeCb = function()
					self.isShowEffect:set(true)
					self.effectView:removeAllChildren()
					local effectBg = widget.addAnimationByKey(self.effectView, "effect/xianshichouka.skel", "effectBlack", effectName, 999)
						:scale(2)
						:alignCenter(self.effectView:size())
					effectBg:setSpriteEventHandler(function(event, eventArgs)
						self.isShowEffect:set(false)
						self.topView:show()
					end, sp.EventType.ANIMATION_COMPLETE)
				end,
			}
			local hasCard, cards = drawCardTools.hasCard(items[1])
			drawCardTools.addLight(self, {
				parent = self.effectView,
				parentEffect = sprite,
				datas = items[1],
				count = 10,
				cloneItem = self.item
			})
			performWithDelay(self.effectView, function()
				local delay = 0
				if hasCard then
					sprite:play("effect_zhanshi")
					-- 目前最多只会有一个精灵
					local cardTime = drawCardTools.addCardImg(cards, self.effectView)
					delay = 70 / 30 + cardTime
				end
				performWithDelay(self, function()
					self.isShowEffect:set(false)
					gGameUI:stackUI("city.drawcard.result", nil, nil, params)
				end, delay)
				if bUseDiamond then
					userDefault.setCurrDayKey("limitDrawTip", 0)
				end
			end, 110 / 30)
		end, self.limitDataId, "limit_rmb10")
	end
	if bUseDiamond and matchLanguage({"kr"}) or (userDefault.getCurrDayKey("limitDrawTip", 1) == 1 and dataEasy.isUnlock("limitDrawTips")) then
		local cost = csv.yunying.yyhuodong[self.limitDataId].paramMap.RMB10
		gGameUI:showDialog{content = string.format(gLanguageCsv.draw10CardTips, cost), cb = function()
			requesetServer()
		end, btnType = 2, clearFast = true, isRich = true}
	else
		requesetServer()
	end
end
-- 奖励预览
function t:onPerviewClick()
	gGameUI:stackUI("city.drawcard.preview", nil, {blackLayer = true, clickClose = true}, self.curType:read(), self.limitDataId)
end

return t