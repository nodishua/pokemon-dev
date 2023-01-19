-- @date 2021-03-03
-- @desc 走格子主界面

local gridWalkTools = require "app.views.city.activity.grid_walk.tools"
-- npc人物状态
local NPC_STATE = {
	stand = "stand",
	run = "run",
}

local GEZI_TO_BOX_NAME_EVENT = {
	[0] = "effect_huang1",	-- 空格子 -->> 宝箱
	[3] = "effect_lv1",		-- 勋章+ -->> 宝箱
	[4] = "effect_zi1",		-- 勋章- -->> 宝箱
}

local BOX_TO_GEZI_NAME_EVENT = {
	[0] = "effect_huang2",	-- 宝箱 -->> 空格子
	[3] = "effect_lv2",		-- 宝箱 -->> 勋章+
	[4] = "effect_zi2",		-- 宝箱 -->> 勋章-
}

local EFFECT_DICE_NAME = {
	[gridWalkTools.DICE_ID[1]] = "effect_2_",
	[gridWalkTools.DICE_ID[2]] = "effect_1_",
	[gridWalkTools.DICE_ID[3]] = "effect_3_",
}

local RULE_ITEMS_SHOW = {
	[1] = gridWalkTools.ITEMS.normanlDice,
	[2] = gridWalkTools.ITEMS.strangeDice,
	[3] = gridWalkTools.ITEMS.medalDice,
	[4] = gridWalkTools.ITEMS.randomCard,
	[5] = gridWalkTools.ITEMS.voucher,
	[6] = gridWalkTools.ITEMS.sprintCard,
	[7] = gridWalkTools.ITEMS.steeringCard,
}
local ViewBase = cc.load("mvc").ViewBase
local GridWalkView = class("GridWalkView", ViewBase)
GridWalkView.RESOURCE_FILENAME = "grid_walk.json"
GridWalkView.RESOURCE_BINDING = {
	["rightPanel"] = "rightPanel",
	["leftPanel"] = "leftPanel",
	["touchPanel"] = "touchPanel",
	["tipPanel"] = "tipPanel",
	["treasuresPanel"] = "treasuresPanel",
	["itemPanel"] = "itemPanel",
	["item"] = "item",
	["item1"] = "item1",
	["leftPanel.oneLine"] = "oneLine",
	["leftPanel.allLine"] = "allLine",
	["leftPanel.oneLine.list"] = "historyOneList",
	["leftPanel.allLine.list"] = "historyList",
	["mapPanel"] = "mapPanel",
	["mapPanel.geziPanel"] = "geziPanel",
	["mapPanel.spinePanel"] = "spinePanel",
	["mapPanel.npcPanel"] = "npcPanel",
	["mapPanel.mapTouchClose"] = "mapTouchClose",
	["mapPanel.eventInfo"] = "eventInfo",
	["mapPanel.npcPanel.leftStepsToBox"] = "leftStepsToBox",
	["mapPanel.npcPanel.leftSteps"] = "leftSteps",
	["downPanel"] = "downPanel",
	["leftPanel.time"] = {
		varname = "showTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.DEFAULT}},
		},
	},
	["tipPanel.txt"] = {
		varname = "tipPanelTxt",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.BLACK, size = 8}},
		},
	},
	["item.jump.add"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(212, 102, 12)}},
		},
	},
	["item.jump.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(212, 102, 12)}},
		},
	},
	["LeftDownPanel.btnRule.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.DEFAULT}},
		},
	},
	["LeftDownPanel.btnTask.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.DEFAULT}},
		},
	},
	["LeftDownPanel.btnBag.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.DEFAULT}},
		},
	},
	["mapPanel.npcPanel.leftSteps.txt1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["mapPanel.npcPanel.leftSteps.txt2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["mapPanel.npcPanel.leftSteps.step"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["mapPanel.npcPanel.leftStepsToBox.txt1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["mapPanel.npcPanel.leftStepsToBox.txt2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["mapPanel.npcPanel.leftStepsToBox.txt3"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["mapPanel.npcPanel.leftStepsToBox.step"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}},
		},
	},
	["LeftDownPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")}
		},
	},
	["LeftDownPanel.btnTask"] = {
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onTaskClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "gridWalkMain",
					onNode = function (node)
						node:xy(150, 210)
					end
				},
			}
		},
	},
	["LeftDownPanel.btnBag"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBagClick")}
		},
	},
	["leftPanel.oneLine.img"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onHistoryClick(1)
			end),
		},
	},
	["leftPanel.allLine.selectPanel"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onHistoryClick(2)
			end),
		},
	},
	["rightPanel.btnDice.icon"] = {
		varname = "btnDiceIcon",
		binds = {
			event = "texture",
			idler = bindHelper.self("diceIcon"),
		},
	},
	["rightPanel.btnDice"] = {
		varname = "btnDice",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDiceClick")}
		},
	},
	["rightPanel.btnDice1"] = {
		varname = "btnDice1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDiceClick(1)
			end)}
		},
	},
	["rightPanel.btnDice2"] = {
		varname = "btnDice2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDiceClick(2)
			end)}
		},
	},
	["rightPanel.btnDice3"] = {
		varname = "btnDice3",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onDiceClick(3)
			end)}
		},
	},
	["downPanel.card1"] = {
		varname = "card1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onCardClick(1)
			end)}
		},
	},
	["downPanel.card2"] = {
		varname = "card2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onCardClick(2)
			end)}
		},
	},
	["downPanel.card3"] = {
		varname = "card3",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onCardClick(3)
			end)}
		},
	},
	["rightPanel.diceInfo"] = "diceInfo",
	["rightPanel.diceInfo.touchClose"] = "touchClose",
	["showDicePanel"] = "showDicePanel",
	["showDicePanel.step"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 6}},
		},
	},
}

function GridWalkView:onCreate()
	self:initModel()
	gGameUI.topuiManager:createView("grid_walk", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.gridWalk, subTitle = "CRAZY ADVENTURE", iconNum = self.iconNum})
	self:initMap()
	self:initNpc()
	self:initItems()
	self:initHistory()
	self:initTouchListener()

	self.mapPanel:setScrollBarEnabled(false)
	self.historyOneList:setScrollBarEnabled(false)
	self.historyList:setScrollBarEnabled(false)

	idlereasy.when(self.nowTowardsUp, function (_, nowTowardsUp)
		self:updateNpcTowardsUp()
		self:updateJumpGezi(nowTowardsUp)
		self:updateLeftStepsToBox()
	end)

	idlereasy.when(self.showHistory, function (_, showHistory)
		self.oneLine:visible(not showHistory)
		self.allLine:visible(showHistory)
	end)

	idlereasy.any({self.selectedDice, self.updateDice}, function(_, selectedDice, updateDice)
		local showDice = {}
		for k, dice in ipairs(self.diceTable) do
			dice:get("di.select"):hide()
			local num = tonumber(dice:get("txt"):text())
			if num > 0 then
				table.insert(showDice, k)
			end
		end
		if not itertools.isempty(showDice) then
			for k, v in ipairs(showDice) do
				if selectedDice == v then
					self.diceTable[v]:get("di.select"):show()
					self.selectedDiceID:set(v)
					return
				end
			end
			self.diceTable[showDice[1]]:get("di.select"):show()
			self.selectedDiceID:set(showDice[1])
		else
			self.selectedDiceID:set(0)
		end
	end)

	idlereasy.when(self.selectedDiceID, function(_, selectedDiceID)
		local id = selectedDiceID == 0 and 1 or selectedDiceID
		self.diceIcon:set(dataEasy.getIconResByKey(gridWalkTools.DICE_ID[id]))
	end)
end

function GridWalkView:initModel()
	self.gridWalk = gGameModel.role:getIdler("grid_walk")
	self.yyhuodongs = gGameModel.role:getIdler('yyhuodongs')
	self.endTime = gGameModel.role:getIdler("yy_endtime")

	self.updateDice = idler.new(false)
	self.showHistory = idler.new(false)
	self.nowIndex = idler.new(self.gridWalk:read().pos)
	self.nowTowardsUp = idler.new(self.gridWalk:read().direction_up and 1 or -1)
	self.selectedDice = idler.new(nil)
	self.selectedDiceID = idler.new(1)
	self.iconNum = idler.new(dataEasy.getNumByKey(gridWalkTools.BADGE_ID))
	self.offset = idler.new(0)
	self.diceIcon = idler.new("")
	self.leftStepsNum = 0
	self.yyId = self.gridWalk:read().yy_id
	self.huodongID = csv.yunying.yyhuodong[self.yyId].huodongID
	self.nowUsedCard = (self.gridWalk:read().action.die_used and self.gridWalk:read().action.die_used ~= 0) and 0 or (self.gridWalk:read().action.item_used or 0)
	self.npcNowState = NPC_STATE.stand
end

function GridWalkView:initHistory()
	self:updateHistory()
	if self.nowUsedCard > 0 then
		local event = {csv_id = self.nowUsedCard, is_event = false}
		self:updateHistory(event)
	end
end
function GridWalkView:updateNpcState(state)
	if state == NPC_STATE.run then
		if self.npcNowState == NPC_STATE.stand then
			self.npcPanel:get("spine"):play("run_loop")
			self.npcNowState = NPC_STATE.run
		end
	elseif state == NPC_STATE.stand then
		if self.npcNowState == NPC_STATE.run then
			self.npcPanel:get("spine"):play("standby_loop")
			self.npcNowState = NPC_STATE.stand
		end
	end
end
function GridWalkView:initItems()
	self.diceTable = {
		[1] = self.btnDice1,
		[2] = self.btnDice2,
		[3] = self.btnDice3,
	}
	self.cardTable = {
		[1] = self.card1,
		[2] = self.card2,
		[3] = self.card3,
	}
	for k, item in ipairs(self.diceTable) do
		item:get("di.icon"):texture(dataEasy.getIconResByKey(gridWalkTools.DICE_ID[k]))
		text.addEffect(item:get("txt"), {outline = {color = ui.COLORS.NORMAL.BLACK}})
		item:get("di"):setCascadeOpacityEnabled(true)
		item:get("di"):setCascadeColorEnabled(true)
	end
	for k, item in ipairs(self.cardTable) do
		local itemID = gridWalkTools.CARD_ID[k]
		local cfg = dataEasy.getCfgByKey(itemID)
		item:get("name"):text(cfg.name)
		text.addEffect(item:get("name"), {outline = {color = cc.c4b(206, 94, 25, 255)}})
		text.addEffect(item:get("txt"), {outline = {color = ui.COLORS.NORMAL.BLACK}})
	end
	self:updateAllItems()
	-- 骰子起伏动画
	local moveTime = 1.5
	local offsetY = 7
	local size = self.btnDice:size()
	local action = cc.Sequence:create(
		cc.MoveTo:create(moveTime, cc.p(size.width/2, size.height/2 + offsetY)),
		cc.MoveTo:create(moveTime, cc.p(size.width/2, size.height/2 - offsetY))
	)
	self.btnDiceIcon:runAction(cc.RepeatForever:create(action))
end

function GridWalkView:initTouchListener()
	self.touchClose:setTouchEnabled(false)
	local listener = cc.EventListenerTouchOneByOne:create()
	local eventDispatcher = self.touchClose:getEventDispatcher()
	local function onTouchBegan(touch, event)
		self.diceInfo:hide()
		self.eventInfo:hide()
		self.mapTouchClose:hide()
		return false
	end
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.touchClose)

	self.mapTouchClose:setTouchEnabled(false)
	local listener1 = cc.EventListenerTouchOneByOne:create()
	local eventDispatcher1 = self.mapTouchClose:getEventDispatcher()
	listener1:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	eventDispatcher1:addEventListenerWithSceneGraphPriority(listener1, self.mapTouchClose)
end

function GridWalkView:initMap()
	local bg1 = ccui.ImageView:create("activity/grid_walk/img_zgz1_bg.pvr.ccz"):scale(2):anchorPoint(0, 0):xy(0, 1440)
	bg1:addTo(self.mapPanel, 0)
	local bg2 = ccui.ImageView:create("activity/grid_walk/img_zgz2_bg.pvr.ccz"):scale(2):anchorPoint(0, 0):xy(0, 0)
	bg2:addTo(self.mapPanel, 0)
	self.mapDates = {}
	-- self.eventInfo:globalZ(1)
	local mapPos = gridWalkTools.getMapPos(self.item:size())
	for k, val in csvPairs(csv.yunying.grid_walk_map) do
		if val.huodongID == self.huodongID then
			self:createGezi(val, mapPos)
		end
	end
	-- 宝藏单独初始化，替代当前格子中的道具
	self:updateTreasure()
	-- time
	local countdown = self.endTime:read()[self.yyId] - time.getTime()
	self:setCountdown(countdown, self.showTime)

end

function GridWalkView:initNpc()
	self:createNpcSpine(self.npcPanel, gGameModel.role:read("figure"))
	local pos = self.mapDates[self.nowIndex:read()].pos
	self.npcPanel:xy(pos[1], pos[2])
	self:onUpdateListPercentVertical(self.nowIndex:read(), true)
	-- 添加剩余步数和离宝藏的剩余格子数文本
	self.leftStepsToBox:show()
	self.leftSteps:hide()
	self:updateLeftStepsToBox()
end

function GridWalkView:createGezi(mapCfg, mapPos)
	local cloneItem = self.item
	local pos = mapPos[mapCfg.index]
	if mapCfg.event == gridWalkTools.EVENTS.increase
		or mapCfg.event == gridWalkTools.EVENTS.reduce
		or mapCfg.event == gridWalkTools.EVENTS.goodLuck
		or mapCfg.event == gridWalkTools.EVENTS.badLuck
		or mapCfg.event == gridWalkTools.EVENTS.shop then
			cloneItem = self.item1
	end
	local item = cloneItem:clone():show()
	local actionEffect = nil
	if mapCfg.event > 0 then
		local eventCfg = gridWalkTools.getCfgByEventFromEvents(mapCfg.event, self.huodongID)
		item:get("img"):texture(eventCfg.resources[1], ccui.TextureResType.plistType)
		if mapCfg.event == gridWalkTools.EVENTS.shop then
			local xPos = gridWalkTools.getOutPosByIndex(mapCfg.index)
			local size = item:size()
			local x = xPos[1] * size.width
			local y = xPos[2] * size.height
			item:get("panel"):removeAllChildren()
			local panel = item:get("panel"):clone():xy(pos[1]+x, pos[2]+y)
			panel:addTo(self.spinePanel, 1,"spine"..mapCfg.index)
			panel:setTouchEnabled(true)
			bind.click(view, panel, {method = functools.partial(self.showEventsInfo, self, mapCfg.index)})
			actionEffect = self:createSpine(panel, "effect_shop_loop")
		elseif mapCfg.event == gridWalkTools.EVENTS.jump then
			item:get("jump"):hide()
			local jumpTxt = item:get("jump"):clone():show():xy(pos[1], pos[2])
			jumpTxt:get("txt"):text(eventCfg.params.num)
			jumpTxt:addTo(self.spinePanel, 1,"spine"..mapCfg.index)
			actionEffect = self:createSpine(jumpTxt, "effect_jiasuf_loop", nil, 1)
		elseif mapCfg.event == gridWalkTools.EVENTS.increase
			 or mapCfg.event == gridWalkTools.EVENTS.reduce then
			item:get("panel.img1"):texture(eventCfg.resources[2], ccui.TextureResType.plistType)
		elseif mapCfg.event == gridWalkTools.EVENTS.goodLuck
			 or mapCfg.event == gridWalkTools.EVENTS.badLuck then
			item:get("panel"):removeAllChildren()
			local panel = item:get("panel"):clone():xy(pos[1], pos[2])
			panel:addTo(self.spinePanel, 1, "spine"..mapCfg.index)
			local effectName = mapCfg.event == gridWalkTools.EVENTS.goodLuck and "effect_zhuanpan_loop" or "effect_eyun_loop"
			actionEffect = self:createSpine(panel, effectName, nil, nil, "gridwalk/dongxiao.skel")
		end
	end
	item:addTo(self.geziPanel, 1, "gezi"..mapCfg.index)
	item:xy(pos[1], pos[2])

	bind.click(view, item, {method = functools.partial(self.showEventsInfo, self, mapCfg.index)})

	self.mapDates[mapCfg.index] = {
		action = actionEffect,
		item = item,
		index = mapCfg.index,
		pos = pos,
		event = mapCfg.event,
	}
	return item
end

function GridWalkView:updateDiceFun()
	self.updateDice:notify()
end

function GridWalkView:updateNpcTowardsUp()
	local towardsUp = gridWalkTools.getTowardsUp(self.nowIndex:read(), self.nowTowardsUp:read())
	local endScale = 1.5 * towardsUp
	self.npcPanel:get("spine"):scaleX(endScale)
end

function GridWalkView:updateJumpGezi(nowTowardsUp)
	for k, val in pairs(self.mapDates) do
		if val.event == gridWalkTools.EVENTS.jump then
			-- 默认方向，自己和后面一格比较，反方向，自己和前面一格比较
			local posTowardsUp = gridWalkTools.getNextTowardsUp(val.index, nowTowardsUp)
			local item = val.item
			local cfg = gridWalkTools.getCfgByEventFromEvents(val.event, self.huodongID)
			local icon = cfg.resources[1]
			local scaleX = 2
			local effectName = "effect_jiasuf_loop"
			if posTowardsUp[1] < 0 and posTowardsUp[2] == 0 then
				scaleX = -2
			elseif posTowardsUp[1] == 0 and posTowardsUp[2] > 0 then
				icon = cfg.resources[2]
				effectName = "effect_jiasuu_loop"
			elseif posTowardsUp[1] == 0 and posTowardsUp[2] < 0 then
				icon = cfg.resources[3]
				effectName = "effect_jiasud_loop"
			end
			item:get("img"):scaleX(scaleX)
			item:get("img"):texture(icon, ccui.TextureResType.plistType)
			if val.action then
				val.action:scaleX(scaleX/2)
				val.action:play(effectName)
			end
		end
	end
end

function GridWalkView:updateTreasure(callBack)
	local index = self.gridWalk:read().treasure
	local data = self.mapDates[index]
	local mapPos = gridWalkTools.getMapPos(self.item:size())
	if data.event ~= gridWalkTools.EVENTS.treasures then
		local function createTreasure()
			self.geziPanel:removeChildByName("gezi"..index)
			-- self.spinePanel:removeChildByName("spine"..index)
			local item = self.item1:clone():show()
			item:addTo(self.geziPanel, 1, "gezi"..index)
			item:xy(mapPos[index][1], mapPos[index][2])
			local cfg = gridWalkTools.getCfgByEventFromEvents(gridWalkTools.EVENTS.treasures, self.huodongID)
			item:get("img"):texture(cfg.resources[1], ccui.TextureResType.plistType)
			local xPos = gridWalkTools.getOutPosByIndex(index)
			local size = item:size()

			item:get("panel"):removeAllChildren()
			local panel = item:get("panel"):clone()
			panel:setTouchEnabled(true)
			panel:addTo(self.spinePanel, 1, "spine"..index)
			bind.click(view, panel, {method = functools.partial(self.showEventsInfo, self, index)})
			bind.click(view, item, {method = functools.partial(self.showEventsInfo, self, index)})
			local actionEffect = self:createSpine(panel, "effect_bx_loop", "outBox")
			local box = actionEffect:box()
			local x = xPos[1] * size.width
			local y = xPos[2] * (box.height + 10)
			panel:xy(data.pos[1]+x, data.pos[2]+y)
			data.item = item
			data.action = actionEffect
			data.event = gridWalkTools.EVENTS.treasures
			return item
		end
		local needRemove = false
		for k, val in pairs(self.mapDates) do
			if val.event == gridWalkTools.EVENTS.treasures then
				self.geziPanel:removeChildByName("gezi"..val.index)
				self.spinePanel:removeChildByName("spine"..val.index)
				val.action = nil
				local cfg = gridWalkTools.getCfgByIndexFromMap(val.index, self.huodongID)
				val.event = cfg.event
				needRemove = true
				local item = self:createGezi(val, mapPos)
				item:hide()
				local function cb1()
					createTreasure()
					performWithDelay(self, function()
						self:onUpdateListPercentVertical(self.nowIndex:read())
						performWithDelay(self, callBack, gridWalkTools.MOVE_TIME + 0.1)
					end, 0.5)
				end
				local function cb()
					item:show()
					self:onUpdateListPercentVertical(index)
					performWithDelay(self, function()
						self.mapDates[index].item:hide()
						self:geziAndBoxFilp(index, cb1, true)
					end, gridWalkTools.MOVE_TIME)
				end
				self:geziAndBoxFilp(val.index, cb)
				break
			end
		end
		if not needRemove then
			createTreasure()
		end
	end
end

-- 刷新剩余步数
function GridWalkView:updateLeftSteps()
	local txt1 = self.leftSteps:get("txt1")
	local step = self.leftSteps:get("step")
	local txt2 = self.leftSteps:get("txt2")
	step:text(self.leftStepsNum + 1)
	local size = self.leftSteps:size()
	adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2), {txt1, step, txt2}, cc.p(5 ,0))
end

-- 刷新到宝箱的格数
function GridWalkView:updateLeftStepsToBox()
	local txt1 = self.leftStepsToBox:get("txt1")
	local img = self.leftStepsToBox:get("img")
	local step = self.leftStepsToBox:get("step")
	local txt3 = self.leftStepsToBox:get("txt3")
	step:text(self:getLeftBoxSteps())
	local size = self.leftStepsToBox:size()
	adapt.oneLineCenterPos(cc.p(size.width/2, size.height/2), {txt1, img, step, txt3}, cc.p(5 ,0))
end

function GridWalkView:updateAllItems()
	self:updateAllCards()
	self:updateAllDices()
	self:setBadgeOffset(0, true)
	self:updateIconNum(true)
end

function GridWalkView:updateAllCards()
	for k, card in ipairs(self.cardTable) do
		local num = dataEasy.getNumByKey(gridWalkTools.CARD_ID[k])
		self:updateCardNum(k, num)
	end
end

function GridWalkView:updateAllDices()
	for k, card in ipairs(self.diceTable) do
		local num = dataEasy.getNumByKey(gridWalkTools.DICE_ID[k])
		self:updateDiceNum(k, num)
	end
	self:updateDiceFun()
end

-- 刷新道具卡数量
function GridWalkView:updateCardNum(id, num, diff)
	local lastNum = num
	if diff then
		local n = tonumber(self.cardTable[id]:get("txt"):text())
		lastNum = math.max(lastNum + n, 0)
	end
	self.cardTable[id]:get("txt"):text(lastNum)
	if lastNum == 0 then
		text.addEffect(self.cardTable[id]:get("txt"), {color = cc.c4b(241, 59, 84, 255)})
	else
		text.addEffect(self.cardTable[id]:get("txt"), {color = cc.c4b(244, 215, 33, 255)})
	end
	return lastNum
end

-- 刷新骰子道具数量
function GridWalkView:updateDiceNum(id, num, diff)
	local lastNum = num
	if diff then
		local n = tonumber(self.diceTable[id]:get("txt"):text())
		lastNum = math.max(lastNum + n, 0)
	end
	self.diceTable[id]:get("txt"):text(lastNum)
	local grayState = cc.c3b(255, 255, 255)
	if lastNum == 0 then
		text.addEffect(self.diceTable[id]:get("txt"), {color = cc.c4b(241, 59, 84, 255)})
		grayState = cc.c3b(128, 128, 128)
	else
		text.addEffect(self.diceTable[id]:get("txt"), {color = cc.c4b(244, 215, 33, 255)})
	end
	self.diceTable[id]:get("di"):color(grayState)
	return lastNum
end

function GridWalkView:updateHistory(event)
	local function inPutOneList(str)
		beauty.singleTextAutoScroll({
			strs = str,
			fontSize = 40,
			isRich = true,
			list = self.historyOneList,
			align = "left",
			anchor = cc.p(0, 0.5),
			vertical = cc.VERTICAL_TEXT_ALIGNMENT_CENTER
		})
	end
	local function inPutAllList(str)
		local count = self.historyList:getChildrenCount()
		if count >= gridWalkTools.HISTORY_MAX then
			self.historyList:removeItem(0)
		end
		local label = rich.createWithWidth(str, 40, nil, self.historyList:width())
		self.historyList:pushBackCustomItem(label)
		self.historyList:jumpToBottom()
	end
	if event then
		local str = gridWalkTools.getLabelFromEvent(event)
		inPutOneList(str)
		inPutAllList(str)
	else
		local history = self.gridWalk:read().history
		if not itertools.isempty(history) then
			local lastEvent = nil
			for k, event in ipairs(history) do
				local str = gridWalkTools.getLabelFromEvent(event, lastEvent)
				inPutAllList(str)
				if k == itertools.size(history) then
					inPutOneList(str)
				end
				lastEvent = event
			end
		end
	end
end

-- 触发事件
function GridWalkView:triggerEvent(events, callBack)
	local event = events.event
	local csvId = event.csv_id
	local inputHistory = true
	if csvId ~= 0 then
		local cfg = csv.yunying.grid_walk_events[csvId]
		-- 1转盘2厄运卡3+活动币4-活动币5飞跃格6小店99宝藏点
		local type = cfg.type
		if type == gridWalkTools.EVENTS.goodLuck then
			inputHistory = false
			local function cb(badgeNum)
				callBack()
				self:updateHistory(event)
			end
			local params = {callBack = cb, event = event}
			gGameUI:stackUI("city.activity.grid_walk.wheel", nil, {blackLayer = true}, params)
		elseif type == gridWalkTools.EVENTS.badLuck then
			inputHistory = false
			local function cb(badgeNum)
				callBack()
				self:updateHistory(event)
			end
			local params = {callBack = cb, event = event, iconNum = self.iconNum:read()}
			gGameUI:stackUI("city.activity.grid_walk.scratch", nil, nil, params)
		elseif type == gridWalkTools.EVENTS.increase then
			local num = gridWalkTools.getCfgByEventFromEvents(type, self.huodongID).params.num
			self:eventUpdateitems(num, true)
			callBack()
		elseif type == gridWalkTools.EVENTS.reduce then
			local num = gridWalkTools.getCfgByEventFromEvents(type, self.huodongID).params.num
			self:eventUpdateitems(num, false)
			callBack()
		elseif type == gridWalkTools.EVENTS.jump then
			local jumpStep = gridWalkTools.getCfgByEventFromEvents(type, self.huodongID).params.num
			self.leftStepsNum = self.leftStepsNum + jumpStep
			local item = self.mapDates[self.nowIndex:read()].item
			performWithDelay(self, function()
				callBack()
			end, 1)
		elseif type == gridWalkTools.EVENTS.shop then
			inputHistory = false
			local function cb(params)
				local hasBuy, awards, effTreasure, iconOffset = params.hasBuy, params.awards, params.effTreasure, params.iconOffset
				if awards then
					for k, val in pairs(awards) do
						if k == gridWalkTools.ITEMS.normanlDice or k == gridWalkTools.ITEMS.strangeDice or k == gridWalkTools.ITEMS.medalDice then
							for k1, id in pairs(gridWalkTools.DICE_ID) do
								if id == k then
									self:updateDiceNum(k1, val, true)
									self:updateDiceFun()
									break
								end
							end
						elseif k == gridWalkTools.ITEMS.sprintCard or k == gridWalkTools.ITEMS.randomCard or k == gridWalkTools.ITEMS.steeringCard then
							for k1, id in pairs(gridWalkTools.CARD_ID) do
								if id == k then
									self:updateCardNum(k1, val, true)
									break
								end
							end
						end
					end
				end
				self:setBadgeOffset(0 - iconOffset)
				local historyEvent = table.deepcopy(event, true)
				if hasBuy then
					historyEvent.params.bought = 1
				end
				self:updateHistory(historyEvent)
				if effTreasure then
					for k, val in pairs(self.newEvents) do
						local csvId = val.event.csv_id
						if csvId > 0 then
							local cfg = csv.yunying.grid_walk_events[csvId]
							if cfg.type == gridWalkTools.EVENTS.treasures then
								self.newEvents[k].effTreasure = effTreasure
								break
							end
						end
					end
				end
				callBack()
			end
			local params = {callBack = cb, event = event, index = events.index, iconNum = self.iconNum}
			gGameUI:stackUI("city.activity.grid_walk.shop", nil, {blackLayer = true}, params)
		elseif type == gridWalkTools.EVENTS.treasures then
			local params = event.params
			local cfg = gridWalkTools.getCfgByEventFromEvents(type, self.huodongID)
			local awards = cfg.params.awards
			local datas = events.effTreasure or {}
			local function cb()
				self:updateTreasure(callBack)
			end
			local data = self.mapDates[self.nowIndex:read()]
			local outBox = data.action
			outBox:play("effect_bx")
			outBox:setSpriteEventHandler(function(event, eventArgs)
				self:onRewardCb(datas, cb)
			end, sp.EventType.ANIMATION_COMPLETE)
		end
	else
		callBack()
	end
	if inputHistory then
		self:updateHistory(event)
	end
end

-- 勋章缓存值
function GridWalkView:setBadgeOffset(num, cover)
	if cover then
		self.offset:set(num)
	else
		local oldVal = self.offset:read()
		self.offset:set(oldVal + num)
	end
	self:updateIconNum()
end

function GridWalkView:updateIconNum(cover)
	if cover then
		self.iconNum:set(dataEasy.getNumByKey(gridWalkTools.BADGE_ID))
	else
		local num = self.iconNum:read()
		num = math.max(num + self.offset:read(), 0)
		self.iconNum:set(num)
	end
end

function GridWalkView:eventUpdateitems(num, isIncrease)
	self.tipPanel:show()
	if isIncrease then
		self.tipPanelTxt:text("+"..num)
		-- self:setBadgeOffset(tonumber(num))
		text.addEffect(self.tipPanelTxt, {color = cc.c4b(155, 208, 71, 255)})
	else
		self.tipPanelTxt:text("-"..num)
		-- self:setBadgeOffset(-tonumber(num))
		text.addEffect(self.tipPanelTxt, {color = cc.c4b(252, 83, 106, 255)})
	end
	local PosY = self.tipPanel:y()
	self.tipPanel:y(PosY - 50)
	self.tipPanel:scale(0)
	self.tipPanel:runAction(cc.Sequence:create(
		cc.ScaleTo:create(0.2, 1.6),
		cc.ScaleTo:create(0.1, 1),
		cc.MoveTo:create(0.8, cc.p(self.tipPanel:x(), PosY + 50)),
		cc.DelayTime:create(0.1),
		cc.CallFunc:create(function()
			self.tipPanel:hide()
			self.tipPanel:y(PosY)
		end)))
end

function GridWalkView:createNpcSpine(node, figureOrRes)
	local spineRes = figureOrRes
	if type(figureOrRes) == "number" then
		local cfg = gRoleFigureCsv[figureOrRes]
		spineRes = cfg.crossMineResSpine
	end
	local npc = widget.addAnimationByKey(node, spineRes, "spine", "standby_loop", 1)
		:xy(node:width()/2, 0)
		:scale(1.5)
	return npc
end

function GridWalkView:npcMove(index, cb)
	self:updateNpcState(NPC_STATE.run)
	local endPos = self.mapDates[index].pos
	local towardsUp = gridWalkTools.getTowardsUp(index, self.nowTowardsUp:read())
	local nowX = self.npcPanel:x()
	local nowY = self.npcPanel:y()
	local scale = endPos[1] - nowX > 0 and 1.5 or nil
	scale = endPos[1] - nowX < 0 and -1.5 or scale
	if scale then
		self.npcPanel:get("spine"):scaleX(scale)
	end
	self.leftStepsToBox:hide()
	self.leftSteps:show()
	self:updateLeftStepsToBox()
	self:updateLeftSteps()
	self.npcPanel:runAction(cc.Sequence:create(
		cc.MoveTo:create(gridWalkTools.MOVE_TIME, cc.p(endPos[1], endPos[2])),
		cc.CallFunc:create(function()
			local endScale = 1.5 * towardsUp
			if scale ~= endScale then
				self.npcPanel:get("spine"):scaleX(endScale)
			end
			self.leftStepsToBox:show()
			self.leftSteps:hide()
			if cb then
				cb()
			end
		end)))
	self:onUpdateListPercentVertical(index)
end

function GridWalkView:onUpdateListPercentVertical(index, isJump)
	local endPosY = self.mapDates[index].pos[2]
	local height = 1440
	local percent = (math.max(height + 600 - endPosY, 0)) / height*100
	local percent = math.max(math.min(percent, 100), 0)
	if isJump then
		self.mapPanel:jumpToPercentVertical(percent)
	else
		self.mapPanel:scrollToPercentVertical(percent, gridWalkTools.MOVE_TIME, false)
	end
end

function GridWalkView:onCardClick(id)
	if self.nowUsedCard > 0 then
		gGameUI:showTip(string.format(gLanguageCsv.hasUsedNow, dataEasy.getCfgByKey(self.nowUsedCard).name))
		return
	end
	local itemID = gridWalkTools.CARD_ID[id]
	local function callBack()
		self:sendItemuse(itemID)
	end
	local num = dataEasy.getNumByKey(itemID)
	if num > 0 then
		local params = {callBack = callBack, itemID = itemID, card = self.cardTable[id], steps = self:getLeftBoxSteps(self.gridWalk:read().direction_up and -1 or 1)}
		gGameUI:stackUI("city.activity.grid_walk.confirmation_use_card", nil, {blackLayer = true}, params)
	else
		gGameUI:showTip(gLanguageCsv.inadequateProps)
	end
end


function GridWalkView:onDiceClick(id)
	local function showDiceInfo(id)
		local cfg = dataEasy.getCfgByKey(gridWalkTools.DICE_ID[id])
		local title = self.diceInfo:get("title")
		title:text(cfg.name)
		local txt = self.diceInfo:get("txt")
		txt:removeAllChildren()
		local richText = rich.createWithWidth("#C0x5b545b#" .. cfg.desc, 38, nil, 364)
			:anchorPoint(0, 0)
			:xy(0, 0)
			:addTo(txt)
		local size = richText:size()
		local bg = self.diceInfo:get("bg")
		title:y(txt:y() + size.height + 27)
		bg:height(size.height + 110)
		self.diceInfo:xy(self.diceTable[id]:x() - 10, self.diceTable[id]:y())
		self.diceInfo:show()
	end
	if type(id) == "number" then
		showDiceInfo(id)
		local num = dataEasy.getNumByKey(gridWalkTools.DICE_ID[id])
		if num == 0 then return end
		self:updateAllDices()
		self.selectedDice:set(id)
	else
		if self.selectedDiceID:read() > 0 then
			self:sendItemuse(gridWalkTools.DICE_ID[self.selectedDiceID:read()])
		else
			gGameUI:showTip(gLanguageCsv.gridWalkNoDice)
		end
	end
end

function GridWalkView:onHistoryClick(ptype)
	self.showHistory:set(ptype == 1)
end

function GridWalkView:onTaskClick()
	gGameUI:stackUI("city.activity.grid_walk.task", nil, nil, {callBack = self:createHandler("updateAllItems")})
end

function GridWalkView:onBagClick()
	gGameUI:stackUI("city.activity.grid_walk.bag")
end

function GridWalkView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function GridWalkView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.gridWalk)
		end),
		c.clone(self.treasuresPanel, function(item)
			local size = item:size()
			local str = string.format(gLanguageCsv.gridWalkRuleTips, self:getPastTreasuresTimes())
			local rich = rich.createByStr(str)
			rich:anchorPoint(0.5, 0.5)
			rich:xy(size.width/2, size.height/2)
			item:addChild(rich)
		end),
		c.noteText(162),
		c.noteText(120001, 120030),
		c.noteText(163),
	}
	for k, val in ipairs(RULE_ITEMS_SHOW) do
		table.insert(context, c.clone(self.itemPanel, function(item)
			local childs = item:multiget("icon", "txt")
			local cfg = dataEasy.getCfgByKey(val)
			childs.txt:text(cfg.name..": "..cfg.desc)
			local binds = {
				class = "icon_key",
				props = {
					data = {
						key = val,
					},
				},
			}
			bind.extend(view, childs.icon, binds)
		end))
	end
	return context
end

function GridWalkView:sendItemuse(itemID)
	if self.timeEnd then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end
	gGameApp:requestServer("/game/yy/gridwalk/itemuse", function(tb)
		local view = tb.view
		if view then
			if view.itemID == gridWalkTools.ITEMS.normanlDice
				or view.itemID == gridWalkTools.ITEMS.strangeDice
				or view.itemID == gridWalkTools.ITEMS.medalDice then
				self:setBadgeOffset(0, true)
				self:updateSteps(view)
				self.nowUsedCard = 0
				for k, id in pairs(gridWalkTools.DICE_ID) do
					if id == view.itemID then
						self:updateDiceNum(k, -1, true)
						self:updateDiceFun()
						break
					end
				end
			elseif view.itemID == gridWalkTools.ITEMS.sprintCard
				or view.itemID == gridWalkTools.ITEMS.randomCard
				or view.itemID == gridWalkTools.ITEMS.steeringCard then
				local event = {csv_id = view.itemID, is_event = false}
				self:updateHistory(event)
				gGameUI:showTip(dataEasy.getCfgByKey(view.itemID).name .. gLanguageCsv.useSuccess)
				self:updateAllCards()
				self.nowUsedCard = view.itemID

				if view.itemID == gridWalkTools.ITEMS.randomCard then
					self:randomCardJumpTo()
				elseif view.itemID == gridWalkTools.ITEMS.steeringCard then
					self.nowTowardsUp:set(self.gridWalk:read().direction_up and 1 or -1)
				end
			end
		end
	end, self.yyId, itemID)
end

function GridWalkView:updateSteps(view)
	self.touchPanel:show()
	self.newEvents = {}
	local action = self.gridWalk:read().action
	local events = action.events
	for k, event in pairs(events) do
		self.newEvents[event.index] = {event = event, index = k, effTreasure = view.effTreasure}
	end
	local function step1()
		if self.leftStepsNum == 0 then
			self:updateNpcState(NPC_STATE.stand)
			self.touchPanel:hide()
			self:updateAllItems()
			return
		end
		local nowIndex = self.nowIndex:read()
		if self.nowTowardsUp:read() == 1 then
			nowIndex = nowIndex + 1
			if nowIndex > 54 then nowIndex = 1 end
		else
			nowIndex = nowIndex - 1
			if nowIndex < 1 then nowIndex = 54 end
		end
		self.nowIndex:set(nowIndex)
		self.leftStepsNum = self.leftStepsNum - 1
		local function cb()
			if self.newEvents[nowIndex] then
				self:updateNpcState(NPC_STATE.stand)
				self:triggerEvent(self.newEvents[nowIndex], step1)
			else
				step1()
			end
		end
		self:npcMove(nowIndex, cb)
	end
	self.leftStepsNum = action.die_rolled
	if self.nowUsedCard == gridWalkTools.ITEMS.sprintCard then
		local printCardCfg = dataEasy.getCfgByKey(gridWalkTools.ITEMS.sprintCard)
		self.leftStepsNum = self.leftStepsNum + printCardCfg.specialArgsMap.steps
	end
	local function showDices()
		if view.itemID == gridWalkTools.ITEMS.medalDice then
			self:setBadgeOffset(action.die_rolled)
		end
		local event = {csv_id = action.die_used, is_event = false, params = {outcome = self.leftStepsNum}}
		self:updateHistory(event)
		self.showDicePanel:show()
		local cardPanel = self.showDicePanel:get("cardPanel"):hide()
		if action.item_used then
			cardPanel:show()
			local cardPos = cardPanel:get("cardPos")
			cardPos:removeAllChildren()
			local size = cardPos:size()
			for k, val in pairs(gridWalkTools.CARD_ID) do
				if action.item_used == val then
					local card = self.cardTable[k]:clone()
						:anchorPoint(0.5,0.5)
						:xy(size.width/2, size.height/2)
						:addTo(cardPos)
					card:get("txt"):hide()
				end
			end
		end
		local step = self.showDicePanel:get("step")
		self.showDicePanel:get("icon"):texture(dataEasy.getIconResByKey(action.die_used))
		step:text(self.leftStepsNum)
		adapt.oneLinePos(self.showDicePanel:get("txt1"), {step, self.showDicePanel:get("txt2")}, cc.p(10, 0))
		performWithDelay(self, function()
			self.showDicePanel:hide()
		end, 1)
		step1()
	end
	self:createDiceSpine(action.die_used, action.die_rolled, showDices)
end

function GridWalkView:randomCardJumpTo()
	self.npcPanel:hide()
	local function cb()
		self.nowIndex:set(self.gridWalk:read().pos)
		local pos = self.mapDates[self.gridWalk:read().pos].pos
		self.npcPanel:xy(pos[1], pos[2])
		self:onUpdateListPercentVertical(self.gridWalk:read().pos, true)
		self:updateNpcTowardsUp()
		self:createRandomSpine(self.mapDates[self.nowIndex:read()].pos, "end", function ()
			self:updateLeftStepsToBox()
			self.npcPanel:show()
			self.touchPanel:hide()
		end)
	end
	self:createRandomSpine(self.mapDates[self.nowIndex:read()].pos, "begin", cb)
	self.touchPanel:show()
end

function GridWalkView:getLeftBoxSteps(nowTowardsUp)
	local steps = 0
	local nowIndex = self.nowIndex:read()
	local treasureIndex = self.gridWalk:read().treasure
	nowTowardsUp = nowTowardsUp or self.nowTowardsUp:read()
	if nowTowardsUp == 1 then
		if nowIndex > treasureIndex then
			steps = treasureIndex - nowIndex + 54
		else
			steps = treasureIndex - nowIndex
		end
	else
		if nowIndex > treasureIndex then
			steps = nowIndex - treasureIndex
		else
			steps = 54 - treasureIndex + nowIndex
		end
	end
	return steps
end

function GridWalkView:onRewardCb(tb, cb)
	local params = nil
	if cb then
		params = {cb = cb}
	end
	gGameUI:showGainDisplay(tb, params)
end

function GridWalkView:getPastTreasuresTimes()
	local yyCfg = csv.yunying.yyhuodong[self.yyId]
	local huodongID = yyCfg.huodongID
	local yydata = self.yyhuodongs:read()[self.yyId]
	local valsums = yydata.valsums or {}
	for i, v in csvPairs(csv.yunying.grid_walk_tasks) do
		if v.huodongID == huodongID and v.taskType == 0 then
			if valsums[i] then
				return valsums[i]
			end
		end
	end
	return 0
end

function GridWalkView:showEventsInfo(index)
	local data = self.mapDates[index]
	if data.event == 0 then return end
	local cfg = gridWalkTools.getCfgByEventFromEvents(data.event, self.huodongID)
	local title = self.eventInfo:get("title")
	title:text(cfg.name)
	local txt = self.eventInfo:get("txt")
	txt:removeAllChildren()
	local richText = rich.createWithWidth("#C0x5b545b#" .. cfg.desc, 38, nil, 364)
		:anchorPoint(0, 0)
		:xy(0, 0)
		:addTo(txt)
	local size = richText:size()
	local bg = self.eventInfo:get("bg")
	title:y(txt:y() + size.height + 27)
	bg:height(size.height + 110)
	local pos = data.pos
	local anchorPointX = 0.5
	self.eventInfo:anchorPoint(anchorPointX, 0)
	self.eventInfo:xy(pos[1], pos[2] + 100)
	self.eventInfo:show()
	self.mapTouchClose:show()
end

function GridWalkView:geziAndBoxFilp(index, cb, isGeziToBox)
	local data = self.mapDates[index]
	local pos = data.pos
	local effectName = isGeziToBox and GEZI_TO_BOX_NAME_EVENT[data.event] or BOX_TO_GEZI_NAME_EVENT[data.event]
	if effectName == nil then
		return
	end
	local effect = self:createSpine(self.spinePanel, effectName, "fangezi", 3)
	effect:xy(pos[1], pos[2])
	effect:show()
	effect:setSpriteEventHandler(function(event, eventArgs)
		effect:hide()
		cb()
	end, sp.EventType.ANIMATION_COMPLETE)
end

function GridWalkView:createSpine(parent, effectName, key, zOrder, spineName)
	local name = spineName or "gridwalk/zougezi.skel"
	local effect = widget.addAnimationByKey(parent, name, key or effectName, effectName, zOrder or 10)
	effect:play(effectName)
	effect:show()
	effect:xy(parent:width()/2, parent:height()/2)
	return effect
end

function GridWalkView:createDiceSpine(id, index, cb)
	local effectName = EFFECT_DICE_NAME[id]..index
	local effect = widget.addAnimationByKey(self, "gridwalk/touzi.skel", "dice", effectName, 99)
	effect:scale(1.8)
	effect:xy(self.mapPanel:width()/2 - 300, self.mapPanel:height()/2)
	effect:setSpriteEventHandler(function(event, eventArgs)
		performWithDelay(self, function()
			cb()
			effect:removeSelf()
		end, 0)
	end, sp.EventType.ANIMATION_COMPLETE)
end

function GridWalkView:createRandomSpine(pos, state, cb)
	local effectName = state == "begin" and "effect_xiaoshi" or "effect_chuxian"
	local effect = widget.addAnimationByKey(self.spinePanel, "gridwalk/chuansong.skel", "chuansong", effectName, 10)
	effect:play(effectName)
	effect:show()
	effect:xy(pos[1], pos[2])
	effect:setSpriteEventHandler(function(event, eventArgs)
		effect:hide()
		cb()
	end, sp.EventType.ANIMATION_COMPLETE)
end

function GridWalkView:setCountdown(countdown, node)
	self:enableSchedule():unSchedule(1)
	countdown = math.max(countdown, 0)
	if countdown == 0 then
		self.timeEnd = true
		node:text(gLanguageCsv.activityOver)
		return
	end
	self.timeEnd = false
	bind.extend(self, node, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = 1,
			strFunc = function(t)
				return gLanguageCsv.activityTime .. t.str
			end,
			endFunc = function()
				countdown = self.endTime:read()[self.yyId] - time.getTime()
				performWithDelay(self, function()
					self:setCountdown(countdown, node)
				end, 1)
			end
		}
	})
end

-- function GridWalkView:onClose()
-- 	-- self.eventDispatcher:removeEventListener(self.eventListener)
-- 	ViewBase.onClose(self)
-- end

return GridWalkView