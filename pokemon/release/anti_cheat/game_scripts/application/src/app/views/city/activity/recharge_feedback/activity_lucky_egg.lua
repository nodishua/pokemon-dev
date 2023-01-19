-- @date: 2020-01-02 21:34:34
-- @desc: 扭蛋机

local LuckyEggView = class("LuckyEggView", cc.load("mvc").ViewBase)

LuckyEggView.RESOURCE_FILENAME = "activity_lucky_egg.json"
LuckyEggView.RESOURCE_BINDING = {
	["btnRule.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(252, 247, 219, 255)}},
		}
	},
	["btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRule")}
		}
	},
	["btnAward.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(252, 247, 219, 255)}},
		}
	},
	["btnAward"] = {
		-- binds = {
		-- 	event = "touch",
		-- 	methods = {ended = bindHelper.self("onAwardShow")}
		-- }
	},
	["mainPanel.drawOnePanel"] = "drawOnePanel",
	["mainPanel.drawTenPanel"] = "drawTenPanel",
	["mainPanel.drawOnePanel.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(241, 116, 47, 255)}},
		}
	},
	["mainPanel.drawTenPanel.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(241, 116, 47, 255)}},
		}
	},
	["mainPanel.drawOnePanel.btn"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onDrawOne")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "luckyEggDrawCardFree",
				}
			}
		}
	},
	["mainPanel.drawOnePanel.limitPanel.limitText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(244, 125, 55, 255)}},
		}
	},
	["mainPanel.drawOnePanel.limitPanel.limitNum"] = {
		varname = "limitOneNum",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(244, 125, 55, 255)}},
		}
	},
	["mainPanel.drawTenPanel.limitPanel.limitText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(242, 83, 98, 255)}},
		}
	},
	["mainPanel.drawTenPanel.limitPanel.limitNum"] = {
		varname = "limitTenNum",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(242, 83, 98, 255)}},
		}
	},
	["mainPanel.drawOnePanel.costPanel"] = "oneCostPanel",
	["mainPanel.drawOnePanel.freePanel"] = "freePanel",
	["mainPanel.drawTenPanel.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDrawTen")}
		}
	},
	["mainPanel.aniPanel"] = "aniPanel",
	["mainPanel.drawTenPanel.costPanel"] = "tenCostPanel",
	["mainPanel.timeText1"] = {
		varname = "timeText1",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(255, 249, 218, 255)}},
		}
	},
	["mainPanel.timeText2"] = {
		varname = "timeText2",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(255, 249, 218, 255)}},
		}
	},
	["mainPanel.btnSkip"] = {
		varname = "btnSkip",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSkipClick")}
		}
	},
	["mainPanel.btnSkip.img"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isSkip"),
		}
	},
	["awardPanel.tip"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(244, 77, 87, 255)}},
		}
	},
	["awardPanel.item"] = "awardItem",
	["awardPanel.list"] = {
		varname = "awardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listItems"),
				item = bindHelper.self("awardItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local data = {
						key = v,
						num = 0,
					}
					if type(v) == "table" then
						data.key = "card"
						data.num = v.card
					end
					node:scale(0.89)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = data,
						},
					})
				end,
			}
		}
	},
	["awardPanel.btnShop"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onShop")}
			},
		}
	},
	["awardPanel.text"] = "awardText",
	["awardPanel.icon"] = "awardIcon",
}

local IS_SKIP = false

function LuckyEggView:onCreate(activityId, data)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.luckyEggTitle, subTitle = "LUCKY_EGG"})
	self.activityId = activityId
	self:initModel()

	local csvCfg = csv.yunying.yyhuodong[activityId]

	self.huodongId = csvCfg.huodongID
	local items = {}
	for k, v in csvPairs(csvCfg.clientParam.awards) do
		items[k] = v
	end
	self.listItems = items

	self:resetTimeLabel()
	self:initAni()
end

function LuckyEggView:resetTimeLabel()
	local getHuodongEndTime = gGameModel.role:read("yy_endtime")[self.activityId]
	local timeT = getHuodongEndTime - time.getTime()
	local textNode = self.timeText1
	local textLabel = self.timeText2
	local centerPos = cc.p((textNode:x() + textLabel:x()) / 2, textLabel:y())
	local function setLabel()
		if timeT <= 0 then
			textLabel:text(gLanguageCsv.activityOver)
			adapt.oneLineCenterPos(centerPos, {textNode, textLabel}, cc.p(10, 0))
			return false
		end

		timeT = timeT - 1
		-- 时间大于一小时 时间充足
		local timeEnough = timeT > 3600
		local color = timeEnough and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE
		text.addEffect(textLabel, {color=color})
		textLabel:text(time.getCutDown(timeT).str)
		adapt.oneLineCenterPos(centerPos, {textNode, textLabel}, cc.p(10, 0))
		return true
	end

	setLabel()
	local scheduleTag = tag or 100-- 定时器tag
	-- 移除上次的刷新定时器
	self:enableSchedule():unSchedule(scheduleTag)
	self:schedule(function()
		return setLabel()
	end, 1, 1, scheduleTag)-- 1秒钟刷新一次
end

function LuckyEggView:initModel()
	self.isSkip = idler.new(IS_SKIP)
	self.isFree = idler.new(false)
	self.rmb = gGameModel.role:getIdler("rmb")
	self.items = gGameModel.role:getIdler("items")
	self.activityScore = idler.new(0)																-- 积分
	self.drawCardNum = idler.new(0)																	-- 抽卡券
	self.drawFreeCount = gGameModel.daily_record:getIdler("lucky_egg_free_counter")					-- 免费抽卡次数
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

	idlereasy.when(self.items, function(_, items)
		self.drawCardNum:set(dataEasy.getNumByKey(game.ITEM_TICKET.luckyEggCard))
		self.awardText:text(dataEasy.getNumByKey(game.ITEM_TICKET.luckyEggScore))
		adapt.oneLineCenterPos(cc.p(960, 250), {self.awardIcon, self.awardText}, cc.p(15, 0))
	end)

	idlereasy.any({self.rmb, self.drawCardNum, self.drawFreeCount, self.yyhuodongs}, function(_, rmb, drawCardNum, drawFreeCount, yyhuodongs)
		local csvCfg = csv.yunying.yyhuodong[self.activityId]
		local yydata = yyhuodongs[self.activityId] or {}
		local paramMap = csvCfg.paramMap
		local info = yydata.info or {}
		self.limitOneMax = csvCfg.paramMap.RMB1LIMIT or 0
		self.limitTenMax = csvCfg.paramMap.RMB10LIMIT or 0
		self.myOneTims = info.lucky_egg_draw1_times or 0
		self.myTenTims = info.lucky_egg_draw10_times or 0
		if self.limitOneMax > 0 then -- 有上限
			self.limitOneNum:text(self.myOneTims .. "/" .. self.limitOneMax)
			self.drawOnePanel:get("limitPanel"):show()
			self.canDrawOne = self.myOneTims < csvCfg.paramMap.RMB1LIMIT
		else
			self.canDrawOne = true
			self.drawOnePanel:get("limitPanel"):hide()
		end
		if self.limitTenMax > 0 then
			self.limitTenNum:text(self.myTenTims .. "/" .. self.limitTenMax)
			self.drawTenPanel:get("limitPanel"):show()
			self.canDrawTen = self.myTenTims < csvCfg.paramMap.RMB10LIMIT
		else
			self.canDrawTen = true
			self.drawTenPanel:get("limitPanel"):hide()
		end
		local setText = function(textItem, iconItem, drawNum)
			drawNum = tonumber(drawNum)
			local textNum = 0
			local textColor = cc.c4b(254, 249, 238, 255) -- 基础白色
			local iconPath = dataEasy.getIconResByKey("rmb")
			if drawCardNum >= drawNum then
				-- textNum = string.format("%s/%s", drawNum, drawCardNum)
				textNum = drawNum
				iconPath = dataEasy.getIconResByKey(game.ITEM_TICKET.luckyEggCard)
			else
				textNum = paramMap["RMB"..drawNum]
				if rmb < paramMap["RMB"..drawNum] then
					textColor = cc.c4b(197, 72, 38, 255)
				end
			end
			textItem:text(textNum)
			iconItem:texture(iconPath)
			adapt.oneLinePos(textItem, iconItem, cc.p(10, 0))
			text.addEffect(textItem, {color = textColor})
		end

		-- 对于单抽
		local isFree = drawFreeCount < 1
		self.isFree:set(isFree)
		self.freePanel:visible(isFree)
		self.oneCostPanel:visible(not isFree)
		if not isFree then
			setText(self.oneCostPanel:get("text"), self.oneCostPanel:get("icon"), 1)
		end

		-- 对于十连
		setText(self.tenCostPanel:get("text"), self.tenCostPanel:get("icon"), 10)
	end)
end

-- 初始化动画模块
function LuckyEggView:initAni()
	local path = "niudan/niudan.skel"
	local spine = widget.addAnimation(self.aniPanel, path, "effect_loop", 99)
					:scale(2)
	spine:setSpriteEventHandler(function(event, eventArgs)
		spine:play("effect_loop")
	end, sp.EventType.ANIMATION_COMPLETE)

	self.spine = spine
end

-- 播放抽卡动画 返回动画时间
function LuckyEggView:playAni()
	if self.isSkip:read() then return 0 end
	self.spine:play("effect")
	local oneX,oneY = self.drawOnePanel:xy()
	local tenX,tenY = self.drawTenPanel:xy()
	local skipX,skipY = self.btnSkip:xy()
	local sequenceOne = cc.Sequence:create(
			cc.DelayTime:create(0.1),
			cc.MoveTo:create(0.04, cc.p(oneX + 10, oneY)),
			cc.MoveTo:create(0.04, cc.p(oneX - 10, oneY)),
			cc.MoveTo:create(0.04, cc.p(oneX, oneY))
		)
		-- self.drawOnePanel:runAction(cc.RepeatForever:create(sequenceOne))
		self.drawOnePanel:runAction(cc.RepeatForever:create(sequenceOne))
	local sequenceTen = cc.Sequence:create(
			cc.DelayTime:create(0.1),
			cc.MoveTo:create(0.04, cc.p(tenX + 10, tenY)),
			cc.MoveTo:create(0.04, cc.p(tenX - 10, tenY)),
			cc.MoveTo:create(0.04, cc.p(tenX, tenY))
		)
	self.drawTenPanel:runAction(cc.RepeatForever:create(sequenceTen))
	performWithDelay(self, function()
		self.drawOnePanel:stopAllActions()
		self.drawTenPanel:stopAllActions()
	end, 1.8)
	return 100 / 30
end

-- 跳过按钮
function LuckyEggView:onSkipClick()
	local isSkip = self.isSkip:read()
	self.isSkip:set(not isSkip)
	IS_SKIP = not isSkip
end

-- 展示结果页面
function LuckyEggView:showDrawCardResult(times, isFree, yyId, bgm, tb)
	self.inAnimation = false
	audio.pauseMusic()
	audio.playEffectWithWeekBGM("drawcard_one.mp3")
	local limitMax = times == 1 and self.limitOneMax or self.limitTenMax
	local myTimes = times == 1 and self.myOneTims or self.myTenTims 
	local ret, spe, isFull = dataEasy.getRawTable(tb)
	local items = dataEasy.getItems(ret, spe)
	local params = {
		items = items,
		drawType = "lucky_egg",
		times = times,
		isFree = isFree,
		yyId = yyId,
		limitMax = limitMax > 0 and limitMax - myTimes or -1,
	}
	gGameUI:stackUI("city.drawcard.result", nil, nil, params)
end

-- 判断是否能抽卡 不能抽给出提示
function LuckyEggView:isCanDrawCard(drawType)
	if self.inAnimation then return false end
	local rmb = self.rmb:read()
	local card = self.drawCardNum:read()
	local rmbCost = csv.yunying.yyhuodong[self.activityId].paramMap["RMB"..drawType]
	-- 检测背包
	local bagFull = gGameModel.role:read("card_capacity") - itertools.size(gGameModel.role:read("cards")) < drawType
	if bagFull then
		-- 背包已满
		gGameUI:showDialog{content = gLanguageCsv.cardBagHaveBeenFullDraw, cb = function()
			gGameUI:stackUI("city.card.bag", nil, {full = true})
		end, btnType = 2, clearFast = true}
		return false
	end

	-- 不是单抽 或者 不是免费
	if drawType ~= 1 or not self.isFree:read() then
		-- 检测抽卡券 or 检测钻石
		if card >= drawType or rmb >= rmbCost then

		else
			uiEasy.showDialog("rmb")
			return false
		end
	end

	if drawType == 1 and self.drawFreeCount:read() >= 1 and not self.canDrawOne then
		gGameUI:showTip(gLanguageCsv.luckyEggDrawOneMax)
		return false
	elseif drawType == 10 and not self.canDrawTen then
		gGameUI:showTip(gLanguageCsv.luckyEggDrawTenMax)
		return false
	end

	self.inAnimation = true
	return true
end

-- 单抽
function LuckyEggView:onDrawOne()
	if not self:isCanDrawCard(1) then return end
	local yyId = self.activityId
	local isFree = self.isFree:read()
	local str = isFree and "lucky_egg_free1" or "lucky_egg_rmb1"
	local rmbCost = csv.yunying.yyhuodong[self.activityId].paramMap["RMB1"]
	local function cb()
		local showOver = {false}
		gGameApp:requestServerCustom("/game/yy/lucky/egg/draw")
			:params(yyId, str)
			:onResponse(function (tb)
				performWithDelay(self, function()
					showOver[1] = true
				end, self:playAni())
			end)
			:wait(showOver)
			:doit(function(tb)
				self:showDrawCardResult(1, isFree, yyId, "drawcard_one.mp3", tb)
			end)
	end
	if isFree then
		cb()
	else
		dataEasy.sureUsingDiamonds(cb, rmbCost, function ()
			self.inAnimation = false
		end)
	end
end

-- 十连
function LuckyEggView:onDrawTen()
	if not self:isCanDrawCard(10) then return end
	local yyId = self.activityId
	local str = "lucky_egg_rmb10"
	local rmbCost = csv.yunying.yyhuodong[self.activityId].paramMap["RMB10"]
	dataEasy.sureUsingDiamonds(function()
		local showOver = {false}
		gGameApp:requestServerCustom("/game/yy/lucky/egg/draw")
			:params(yyId, str)
			:onResponse(function (tb)
				performWithDelay(self, function()
					showOver[1] = true
				end, self:playAni())
			end)
			:wait(showOver)
			:doit(function(tb)
				self:showDrawCardResult(10, false, yyId, "drawcard_ten.mp3", tb)
			end)
	end, rmbCost, function ()
			self.inAnimation = false
		end)
end

-- 商店按钮
function LuckyEggView:onShop()
	gGameUI:stackUI("city.activity.recharge_feedback.activity_lucky_egg_shop", nil, {blackLayer = true}, self.activityId, self.huodongId)
end

-- 奖励预览
function LuckyEggView:onAwardShow()
	gGameUI:stackUI("city.drawcard.preview", nil, {blackLayer = true, clickClose = true}, "lucky_egg", self.activityId)
end

-- 规则按钮
function LuckyEggView:onRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function LuckyEggView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.luckyEggRuleTitle)
		end),
		-- c.noteText(123),
		c.noteText(70001, 70006),
	}
	return context
end

return LuckyEggView