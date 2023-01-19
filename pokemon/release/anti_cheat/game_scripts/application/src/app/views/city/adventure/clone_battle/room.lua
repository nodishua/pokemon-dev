-- @date:   2019-10-16
-- @desc:   克隆战(元素挑战)房间主页

local ViewBase = cc.load("mvc").ViewBase
local CloneBattleRoomView = class("CloneBattleRoomView", ViewBase)

local TEXT_OUTLINE = {
	binds = {
		event = "effect",
		data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
	}
}
local TEXT_GLOW = {
	binds = {
		event = "effect",
		data = {glow = {color=ui.COLORS.GLOW.WHITE}},
	}
}

CloneBattleRoomView.RESOURCE_FILENAME = "clone_battle_room.json"
CloneBattleRoomView.RESOURCE_BINDING = {
	["leftPanel.textPanel"] = "textPanel",
	["leftPanel.btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRule")},
		}
	},
	["leftPanel.btnRule.text"] = TEXT_OUTLINE,
	["leftPanel.btnRecord"] = {
		varname = "btnRecord",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onRecord")},
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = {
						"cloneBattleHistory",
					},
				}
			},
		}
	},
	["leftPanel.btnRecord.text"] = TEXT_OUTLINE,
	["leftPanel.natureArea"] = "natureArea",
	["leftPanel.spriteArea.text"] = TEXT_OUTLINE,
	["leftPanel.spriteArea.item"] = "sprItem",
	["leftPanel.spriteArea.list"] = {
		varname = "sprList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("monstersData"),
				item = bindHelper.self("sprItem"),
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local bNode = node:get("baseNode")
					local children = bNode:multiget("selected", "rarity", "bg", "text", "img", "maskLock", "maskOutBox")
					children.rarity:texture(ui.RARITY_ICON[cfg.rarity])
					children.text:text(cfg.name)
					text.addEffect(children.text, {outline={color=ui.COLORS.OUTLINE.WHITE}})
					children.img:texture(cfg.cardIcon2)
					children.selected:visible(v.selected)
					local num = v.selected and 1.1 or 1
					node:scale(num, 1)
					bNode:scale(1, num)
					if not v.selected then
						children.maskOutBox:visible(not v.inBox)
						children.maskLock:visible(v.inBox and v.locked)
						if v.inBox then
							bind.touch(list, node,{methods = {ended = functools.partial(list.clickCell, k, v)}})
						end
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTargetClick"),
			},
		},
	},
	["leftPanel.awardArea.item"] = "awardItem",
	["leftPanel.awardArea.list"] = {
		varname = "awardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("awardData"),
				item = bindHelper.self("awardItem"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = v,
						},
					})
				end,
			},
		},
	},
	["rightPanel.topPanel.attrText"] = {
		varname = "attrText",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["rightPanel.topPanel.item"] = "attrItem",
	["rightPanel.topPanel.list"] = "attrList",
	["rightPanel.topPanel.img"] = "topImg",
	["rightPanel.topPanel.text"] = {
		varname = "topText",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["rightPanel.bottomPanel.btnQuit"] = {
		varname = "btnQuit",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onQuitRoom")},
		}
	},
	["rightPanel.bottomPanel.btnRefresh"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRefresh")},
		}
	},
	["rightPanel.bottomPanel.btnKick"] = {
		varname = "btnKick",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onKick")},
		}
	},
	["rightPanel.bottomPanel.btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChallange")},
		}
	},
	["rightPanel.bottomPanel.btnQuit.text"] = TEXT_OUTLINE,
	["rightPanel.bottomPanel.btnRefresh.text"] = TEXT_OUTLINE,
	["rightPanel.bottomPanel.btnChallenge.text"] = TEXT_GLOW,
	["rightPanel.centerPanel"] = "centerPanel",
	["rightPanel.centerPanel.btnJoinItem"] = "btnJoinItem",
	["rightPanel.centerPanel.normalItem"] = "normalItem",
	["rightPanel.centerPanel.mainItem"] = "mainItem",
	["rightPanel.bottomPanel.btnRobot"] = {
		varname = "btnRobot",
		binds = {
			event = "click",
			method = bindHelper.self("onRobotEnable"),
		}
	},
	["rightPanel.topPanel.textNote"] = "timeNote",
	["rightPanel.topPanel.textTime"] = "textCd",
}

-- 为按钮设置倒计时
local function setBtnTime(self, btnOrStr, fmt, time)
	local t = 0
	local function getBtn()
		if type(btnOrStr) == "string" then
			return self[btnOrStr]
		else
			return btnOrStr
		end
	end

	local btn = getBtn()
	local pString = btn:get("text"):text()
	local scheduleName = btn:name() .. btn:tag()
	self:enableSchedule():schedule(function (dt)
		if t == 0 then
			cache.setShader(btn, false, "hsl_gray")
			btn:setTouchEnabled(false)
		end

		local str = string.format(fmt, math.floor(time - t))
		if btn ~= getBtn() then
			btn = getBtn()
			cache.setShader(btn, false, "hsl_gray")
			btn:setTouchEnabled(false)
		end

		btn:get("text"):text(str)
		t = t + dt

		if t > time then 		-- 计时结束
			cache.setShader(btn, false, "normal")
			btn:get("text"):text(pString)
			self:unSchedule(scheduleName)
			btn:setTouchEnabled(true)
		end
	end, 0.1, 0, scheduleName)
end

function CloneBattleRoomView:onCreate(baseView)
	self.cloneBattleWorningSee = userDefault.getForeverLocalKey("cloneBattleWorningSee", false)	--判断有没有弹窗提示过
	self.baseView = baseView
	self.manberCount = 1 -- 房间人数 至少一人
	gGameModel.forever_dispatch:getIdlerOrigin("cloneBattleLookHistory"):set(0)
	self:initModel()
	local richText = rich.createByStr(gLanguageCsv.elementChallengeTips, 40)
		:addTo(self.textPanel, 10)
		:anchorPoint(cc.p(0.5, 0.5))
	self:initCountDown()
	-- --从变更中退出来之后刷新红点
	-- self.refreshNumber = idler.new(0)
	-- idlereasy.when(self.refreshNumber, function(_, refreshNumber)
	-- 	if refreshNumber ~= 0 then
	-- 		self.baseView:refresh()
	-- 	end
	-- end)
end

function CloneBattleRoomView:initModel()
	--从变更中退出来之后刷新红点
	-- self.refreshNumber = idler.new(0)
	-- 一些基础信息的ilder
	self.beasIdler = {
		natureId = gGameModel.clone_room:getIdler("nature_id"),		-- 房间元素
		roomLeader = gGameModel.clone_room:getIdler("leader"),		-- 房主ID
		roomId = gGameModel.clone_room:getIdler("id"),				-- 房间唯一标识符
		date = gGameModel.clone_room:getIdler("date"),				-- 创建日期
		finishNum = gGameModel.clone_room:getIdler("finish_num"),	-- 目标完成人数
		monsters = gGameModel.clone_room:getIdler("monsters"),		-- 目标精灵表
		places = gGameModel.clone_room:getIdler("places"),			-- 房间成员信息
		fast = gGameModel.clone_room:getIdler("fast"),				-- 是否开启快速加入
		discard = gGameModel.clone_room:getIdler("discard"),		-- 房间是否失效
		createTime = gGameModel.clone_room:getIdler("create_time"),	-- 房间创建时间
		voteRound = gGameModel.clone_room:getIdler("vote_round"),	-- 投票
	}
	self.pokedex = gGameModel.role:getIdler("pokedex")				-- 已有精灵 cardIds
	self.monstersData = idlertable.new({})							-- 目标精灵信息(list用)
	self.monsterCur = idler.new(1)									-- 当前选择的目标精灵序号
	self.awardData = idlertable.new({})								-- 奖励列表

	idlereasy.when(self.beasIdler.natureId, function(_, nature_id)
		local natuteStr = game.NATURE_TABLE[nature_id]
		local roomStr = gLanguageCsv[natuteStr]..gLanguageCsv.natureRoom
		self.topText:text(roomStr)
		self.topImg:texture(string.format("city/adventure/clone_battle/bg_yuansu_%s.png",natuteStr))
		local textSize = self.topText:size()
		self.topImg:size(cc.size(textSize.width + 40, textSize.height + 13))
		adapt.oneLinePos(self.topImg, {self.timeNote, self.textCd}, cc.p(5, 0), "left")
		local size = self.natureArea:size()
		local csvCfg = csv.clone.nature[nature_id]
		local resPath = csvCfg.spine
		widget.addAnimation(self.natureArea, resPath, "effect2_"..nature_id.."_loop", 1)
			:scale(3)
			:xy(size.width / 2, size.height / 2 + 40)
		self:resetAttrList(csvCfg.recommendAttr)
	end)
	idlereasy.when(self.beasIdler.roomLeader, function(_, roomLeader)
		self.isLeader = roomLeader == gGameModel.role:read("id")
	end)
	idlereasy.any({self.beasIdler.places, self.beasIdler.voteRound, self.beasIdler.fast}, function(_, places, voteRound, fast)
		local selfId = gGameModel.role:read("id")
		local roleIdInRoom = {}		-- 记录当前房间内的玩家的ID
		self.battleCards = {}
		self.manberCount = 0
		for i = 1, 5 do
			local baseNode = self.centerPanel:get("pleace"..i)
			baseNode:removeAllChildren()
			local dt = places[i]
			if dt then
				local isLeader = i == 1
				local isMine = selfId == dt.id
				local item = isLeader and self.mainItem or self.normalItem
				self.manberCount = self.manberCount + 1
				roleIdInRoom[dt.id] = true
				item = item:clone()
				self:setItem(baseNode, item, i, dt, isMine)
				item:get("selfCheck"):visible(isMine)
				if isMine then self:initSelfInfo(dt) end
				if isLeader then
					-- 房主的item额外设置
					self.radioJoin = item:get("radioJoin")
					self.btnUnionInvited = item:get("btnUnionInvited")
					self.btnWorldInvited = item:get("btnWorldInvited")
					bind.touch(self, self.radioJoin, {methods = {ended = functools.partial(self.onFastJoin, self)}})
					bind.touch(self, self.btnWorldInvited, {methods = {ended = functools.partial(self.onWorldInvite, self, "btnWorldInvited")}})
					bind.touch(self, self.btnUnionInvited, {methods = {ended = functools.partial(self.onUnionInvite, self, "btnUnionInvited")}})
					if voteRound == "start" and self.isLeader then
						item:get("warnIcon1"):show()
						item:get("warnIcon2"):show()
						item:get("warnIcon"):show()
						item:get("icon"):hide()
						-- if self.isLeader then
						-- 	gGameUI:showDialog({title = "", content = gLanguageCsv.cloneBattleKickWorningTip, btnType = 1, isRich = true})
						-- end
						-- uiEasy.addVibrateToNode(self, item:get("sprImg"), true, item:get("sprImg"))
					else
						item:get("warnIcon1"):hide()
						item:get("warnIcon2"):hide()
						item:get("warnIcon"):hide()
						item:get("icon"):show()
					end
				end
			else
				local item = self.btnJoinItem:clone()
				local baseSize = baseNode:size()
				item:show()
				item:addTo(baseNode):xy(baseSize.width / 2, baseSize.height / 2)
				bind.touch(self, item, {methods = {ended = functools.partial(self.onPosItemClick, self, item, data)}})
			end
		end
		self:refreshTimeLabel()
		self.roleIdInRoom = roleIdInRoom
		self.radioJoin:get("radio.img"):visible(not fast)
	end)
	idlereasy.when(self.beasIdler.voteRound, function(_, voteRound)
		if self.isLeader then
			if voteRound == "start" and self.cloneBattleWorningSee == false then
				gGameUI:showDialog({title = "", content = "#C0x5b545b#"..gLanguageCsv.cloneBattleKickWorningTip, btnType = 1, isRich = true})
				userDefault.setForeverLocalKey("cloneBattleWorningSee", true)	--判断有没有弹窗提示过
			elseif voteRound ~= "start" then
				userDefault.setForeverLocalKey("cloneBattleWorningSee", false)
			end
		end
	end)
	idlereasy.any({self.pokedex, self.beasIdler.monsters, self.monsterCur}, function(_, pokedex, monsters, curIdx)
		local marks = {}
		for cardId, time in pairs(pokedex) do
			local cardCsv = csv.cards[cardId]
			marks[cardCsv.cardMarkID] = true
		end

		local data = {}
		for i, id in pairs(monsters) do
			local cardId = csv.clone.monster[id].cardID
			local csvCards = csv.cards[cardId]
			local unitId = csvCards.unitID
			local markId = csvCards.cardMarkID
			local cfg = csv.unit[unitId] or csv.unit[1]
			data[i] = {
				unitId = unitId,
				cardId = cardId,
				inBox = marks[markId] and true or false,
				cfg = cfg,
				selected = false,
				locked = self.curMonsterLock,
			}
			if curIdx == i and marks[markId] then
				data[i].selected = true
				self.cardName = cfg.name
			elseif curIdx == i then
				curIdx = math.min(curIdx + 1,#monsters)
			end
		end
		self.monsterCur:set(curIdx)
		self.monstersData:set(data)
	end)
	idlereasy.when(self.monsterCur, function(_, idx)
		local unitId = self.beasIdler.monsters:read()[idx]
		local tb = dataEasy.getItemData(csv.clone.monster[unitId].extraAward) or {}
		self.awardData:set(tb)

		local count = #tb
		local size = self.awardItem:size()
		local listSize = self.awardList:size()
		local origWidth = listSize.width
		local len = count * size.width + (count - 1) * 20
		self.awardList:size(len, size.height)
		self.awardList:x(self.awardList:x() - (len - origWidth) / 2)
	end)
	-- idlereasy.any({self.beasIdler.fast, self.beasIdler.places}, function(_, fast)
	-- 	self.radioJoin:get("radio.img"):visible(not fast)
	-- end)
	idlereasy.any({self.beasIdler.places, self.beasIdler.voteRound}, function(_, places, voteRound)
		local selfId = gGameModel.role:read("id")
		local playTimes = 0
		for k, v in pairs(places) do
			if v.id == selfId then
				playTimes = v.play
			end
		end
		if voteRound == "start" and playTimes >= 3 then
			self.btnKick:show()
		else
			self.btnKick:hide()
		end
	end)

	local tag = "Time_Robot_Schedule"
	self:enableSchedule():schedule(function (dt)
		if self:refreshTimeLabel() then
			self:enableSchedule():unSchedule(tag)
		end
	end, 1, nil, tag)
end

function CloneBattleRoomView:refreshTimeLabel()
	local createTime = self.beasIdler.createTime:read()
	local curTime = time.getTime()
	-- 机器人倒计时时间(秒)
	local timeSec = curTime - createTime
	-- 距离第二天刷新的5点 还有多久的倒计时(秒)
	local today12clock = time.getNumTimestamp(time.getTodayStrInClock(), 12, 0)
	local refreshSec = today12clock - curTime
	if refreshSec < 0 then
		refreshSec = refreshSec + 24 * 3600
	end

	local isCreateLongTime = timeSec >= (gCommonConfigCsv.cloneRobotTime * 60) 					-- 是否超时
	local isRefreshInComming = refreshSec <= (gCommonConfigCsv.cloneRobotRefreshTime * 60) 		-- 是否即将刷新
	local isRoomFull = self.manberCount >= 5 													-- 是否满员
	local isShow = isCreateLongTime or isRefreshInComming

	self.btnRobot:visible(isShow and not isRoomFull)
	-- userDefault.setForeverLocalKey("cloneBattleRobot", isShow and not isRoomFull)
	gGameModel.forever_dispatch:getIdlerOrigin("cloneBattleLookRobot"):set(isShow or isRoomFull) -- 判断是否查看过

	return isShow -- 返回值控制的是计时器 与是否满员无关
end

function CloneBattleRoomView:setItem(baseNode, item, i, data, isMine)
	local baseSize = baseNode:size()
	item:addTo(baseNode):xy(baseSize.width / 2, baseSize.height / 2)
	item:show()

	item:get("name"):text(data.name)
	if data.monster == -1 then
		item:get("playPanel.ready"):show()
	elseif data.play >= 3 then
		item:get("playPanel.complete"):show()
	else
		item:get("playPanel.fighting"):show()
		item:get("playPanel.fighting.text"):text(string.format(gLanguageCsv.challengeTime, data.play, 3))
		adapt.setTextScaleWithWidth(item:get("playPanel.fighting.text"), nil, 290)
	end

	local cardInfo = data.card
	local times = data.time
	local playTimes = data.play
	local cardsCsv = csv.cards[cardInfo.card_id]
	local unitCsv = csv.unit[cardsCsv.unitID]
	local unitId = dataEasy.getUnitId(cardInfo.card_id, cardInfo.skin_id)
	bind.extend(self, item:get("sprImg"), {
		class = "card_icon",
		props = {
			unitId = unitId,
			star = cardInfo.star,
			rarity = unitCsv.rarity,
			onNodeClick = function(node)
				self:onSpriteClick(item, data, isMine, i)
			end,
			onNode = function(panel)
				panel:anchorPoint(0.5,0.5)
				panel:xy(item:get("sprImg"):width()/2, item:get("sprImg"):height()/2)
			end,
		}
	})

	local text1 = item:get("text1")
	local text2 = item:get("text2")
	text2:text(cardInfo.fighting_point)
	local x1, y1 = text1:xy()
	local x2, y2 = text2:xy()
	local center = cc.p(baseSize.width / 2, (y1 + y2) / 2)
	adapt.oneLineCenterPos(center, {text1, text2}, cc.p(10, 0))

	-- if i == 1 then
	-- 	idlereasy.when(self.beasIdler.voteRound, function(_, voteRound)
			-- if voteRound == "start" then
			-- 	item:get("warnIcon1"):show()
			-- 	item:get("warnIcon2"):show()
			-- 	item:get("warnIcon"):show()
			-- 	item:get("icon"):hide()
			-- else
			-- 	item:get("warnIcon1"):hide()
			-- 	item:get("warnIcon2"):hide()
			-- 	item:get("warnIcon"):hide()
			-- 	item:get("icon"):show()
			-- end
	-- 	end)
	-- end

	self.battleCards[cardInfo.id] = cardInfo
end

-- 对我 自己 的独有信息进行设置
function CloneBattleRoomView:initSelfInfo(dt)
	local canBattle = dt.play < 3
	cache.setShader(self.btnChallenge, false, canBattle and "normal" or "hsl_gray")
	self.btnChallenge:setTouchEnabled(canBattle)
	self.btnChallenge:get("text"):text(canBattle and gLanguageCsv.startChallenge or gLanguageCsv.complete)

	adapt.setTextScaleWithWidth(self.btnChallenge:get("text"), nil, 280)

	if dt.monster ~= -1 then
		local monster = self.beasIdler.monsters:read()
		for i, unitId in pairs(monster) do
			if unitId == dt.monster then
				self.monsterCur:set(i)
				break
			end
		end
		self.btnQuit:visible(false)
		self.curMonsterLock = true
	end

	self.canBattle = canBattle 			-- 还能进行战斗
	self.monster = dt.monster 			-- (服务器认为已经)选定的怪物序号 如果有 就不能切换了
	self.curCardId = dt.card.id

	self.battle_deploy = {}
	for id, dbId in pairs(dt.battle_deploy or {}) do
		self.battle_deploy[dbId] = id
	end

	self.need_robot = dt.need_robot
	self.btnRobot:get("img"):visible(dt.need_robot == true)
end

-- 退出房间
function CloneBattleRoomView:onQuitRoom()
	gGameApp:requestServer("/game/clone/room/quit", function (tb)
		self.baseView:refreshView(tb.view)
	end)
end

-- 刷新
function CloneBattleRoomView:onRefresh()
	self.baseView:refresh()
end

-- 挑战按钮
function CloneBattleRoomView:onChallange()
	-- local selfId = gGameModel.role:read("id")
	-- local isInRoom = false
	-- for k, v in ipairs(self.beasIdler.places:read()) do
	-- 	if v.id == selfId then
	-- 		isInRoom = true
	-- 	end
	-- end
	-- if isInRoom == false then
	-- 	gGameUI:showTip(gLanguageCsv.cloneBattleKickWorningOVverTip)
	-- 	ViewBase.onClose(self)
	-- 	return
	-- end
	local statrFunc = function()
		local cards = {}
		local cardsInfo = {}
		local btCards = clone(self.battleCards)

		-- 先将已有的且已记忆位置的卡牌插入正确的位置
		for dbId, id in pairs(self.battle_deploy) do
			local info = btCards[dbId]
			if info then
				cards[id] = dbId
				cardsInfo[info.id] = info
				btCards[dbId] = nil
			end
		end

		local function insertToCards(tb)
			for i = 1, 6 do
				if not cards[i] then
					local dbId, info = next(tb)
					if dbId and info then
						cards[i] = dbId
						cardsInfo[info.id] = info
						tb[dbId] = nil
					end
				end
			end
		end

		self:sendServerRequest("/game/clone/battle/deploy/enter", nil, function(tb)
			local robots = clone(tb.robots)

			insertToCards(btCards)	-- 组装卡牌信息
			insertToCards(robots) 	-- 组装机器人信息

			gGameUI:stackUI("city.card.embattle.clone_battle", nil, {full = true},
					{
						fightCb = self:createHandler("startFighting"),
						inputCards = idlertable.new(cards),
						inputCardAttrs = idlertable.new(cardsInfo),
					})
		end)

	end

	if not self.curMonsterLock then
		gGameUI:showDialog({
			clearFast = true,
			btnType = 2,
			strs = string.format(gLanguageCsv.cloneBattleFightTip, self.cardName),
			cb = function()
				statrFunc()
			end,
		})
	else
		statrFunc()
	end
end

-- 开始战斗
function CloneBattleRoomView:startFighting(view, battleCards)
	local unitId = self.beasIdler.monsters:read()[self.monsterCur:read()]
	local cards = battleCards:read() or {}
	if not battleCards then
		for i=1,6 do
			cards[i] = self.battleCards[i] and self.battleCards[i].id or ""
		end
	end
	-- 防止schedule中有网络请求行为
	self:disableSchedule()
	battleEntrance.battleRequest("/game/clone/battle/start", unitId, cards)
		:onStartOK(function(data)
			if view then
				view:onClose(false)
				view = nil
			end
		end)
		:onRequestCustom(function(req)
			req:onErrClose(function()
				if view then
					view:onClose()
					view = nil
				end
				self:onRefresh()
			end)
		end)
		:show()
end

-- 右上角推荐属性列表刷新
function CloneBattleRoomView:resetAttrList(attrs)
	self.attrList:removeAllChildren()

	local count = csvSize(attrs)
	local width = self.attrItem:size().width
	local height = self.attrItem:size().height

	for idx, attr in orderCsvPairs(attrs) do
		local item = self.attrItem:clone()
		item:get("img"):texture(ui.ATTR_ICON[attr])
		self.attrList:insertCustomItem(item, 0)
	end

	self.attrList:size(cc.size(width * count, height))

	adapt.oneLinePos(self.attrList, self.attrText, cc.p(10, 0), "right")
end

--------------------------房主权限------------------------------
-- 快速加入按钮
function CloneBattleRoomView:onFastJoin()
	if not self.isLeader then
		gGameUI:showTip(gLanguageCsv.isNotLeader)
		return
	end
	local state = self.beasIdler.fast:read()
	self:sendServerRequest("/game/clone/room/join/fast/enable", nil, function (tb) end, not state)
end

-- 世界邀请
function CloneBattleRoomView:onWorldInvite(btnStr)
	if not self.isLeader then
		gGameUI:showTip(gLanguageCsv.isNotLeader)
		return
	end
	self:sendServerRequest("/game/clone/invite", nil, function (tb)
		setBtnTime(self, btnStr, "(%s S)", 30)
	end, "world")
end

-- 公会邀请
function CloneBattleRoomView:onUnionInvite(btnStr)
	if not self.isLeader then
		gGameUI:showTip(gLanguageCsv.isNotLeader)
		return
	end
	self:sendServerRequest("/game/clone/invite", nil, function (tb)
		setBtnTime(self, btnStr, "(%s S)", 30)
	end, "union")
end

-- 按位置邀请
function CloneBattleRoomView:onPosItemClick(item, data)
	if not self.isLeader then
		gGameUI:showTip(gLanguageCsv.isNotLeader)
		return
	end
	self:sendServerRequest("/game/clone/friend/online/list", nil, function (tb)
		local roles = clone(tb.view.roles)
		local size = tb.view.size

		for i = 1, size do
			local dt = roles[i]
			if self.roleIdInRoom[dt.id] then
				roles[i] = nil
				size = size - 1
			end
		end

		gGameUI:stackUI("city.adventure.clone_battle.invite", nil, nil, {roles = roles, size = size}, self:createHandler("inviteFunc"))
	end)
end

function CloneBattleRoomView:inviteFunc(data, view, btn)
	local role = {
		id = data.id,
		level = data.level,
		logo = data.logo,
		name = data.name,
		vip = data.vip_level,
		frame = data.frame,
	}

	self:sendServerRequest("/game/clone/invite", function()
		if view then
			view:onCloseFast()
		end
		self:onRefresh()
	end,
	function (tb)
		setBtnTime(view, btn, "(%s S)", 30)
	end, "friend", role)
end
---------------------------------------------------------------

-- 修改是否显示机器人
function CloneBattleRoomView:onRobotEnable()
	local state = not self.need_robot
	self:sendServerRequest("/game/clone/room/robot/enable", nil, function(tb)
		if state then
			gGameUI:showTip(gLanguageCsv.cloneRobotTextOn)
		else
			gGameUI:showTip(gLanguageCsv.cloneRobotTextOff)
		end
	end, state)
end

-- 精灵头像点击 切换出战精灵
function CloneBattleRoomView:onSpriteClick(node, data, isMine, i)
	if isMine then
		gGameUI:createView("city.adventure.clone_battle.choose", self):init(self.curCardId)
		return
	end

	local x, y = node:xy()
	local pos = node:getParent():convertToWorldSpace(cc.p(x, y))
	pos.x = pos.x - 1000
	local isKickNum = 0
	if i == 1 or self.isLeader then
		isKickNum = i
	end
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, {role = data}, {isKickNum = isKickNum, isLeader = self.isLeader})
end

-- 目标精灵选择
function CloneBattleRoomView:onTargetClick(node, k, v)
	if self.curMonsterLock then
		gGameUI:showTip(gLanguageCsv.cloneMonsterCannotChoose)
		return
	end
	if self.monsterCur:read() ~= k and v.inBox then
		self.monsterCur:set(k)
	end
end

-- 规则按钮
function CloneBattleRoomView:onRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function CloneBattleRoomView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.cloneBattleRuleTitle)
		end),
		c.noteText(111),
		c.noteText(62001, 62010),
	}
	if dataEasy.isUnlock(gUnlockCsv.cloneBattleKick) then
		table.insert(context, c.noteText(150))
		table.insert(context, c.noteText(105001, 105010))
	end
	return context
end

function CloneBattleRoomView:sendServerRequest(url, errCb, cb, ...)
	gGameApp:requestServerCustom(url)
		:onErrClose(errCb or function()
			self:onRefresh()
		end)
		:params(...)
		:doit(cb)
end

-- 记录按钮
function CloneBattleRoomView:onRecord()
	local history = gGameModel.clone_room:read("history") or {}
	local historyTab = {}
	for k, v in ipairs(history) do
		table.insert(historyTab, {time = v.time, name = v.name, type = v.type%7 == 0 and 7 or v.type%7})
	end
	gGameUI:stackUI("city.adventure.clone_battle.history", nil, nil, {historyTab = historyTab, refreshNumber = self.refreshNumber})
end



function CloneBattleRoomView:initCountDown( )
	local textTime = self.textCd
	local today = time.getTodayStrInClock(12)
	local endStamp = time.getNumTimestamp(today, 12) + 24 * 3600
	local function setLabel()
		local remainTime = time.getCutDown(endStamp - time.getTime())
		textTime:text(remainTime.str)
		adapt.oneLinePos(self.timeNote, textTime, cc.p(5,0))
		if endStamp - time.getTime() <= 0 then
			self.baseView:refresh()
			today = time.getTodayStrInClock(12)
		end
		return true
	end
	self:enableSchedule()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, 1)
end

-- 投票按钮
function CloneBattleRoomView:onKick()
	gGameUI:stackUI("city.adventure.clone_battle.vote", nil, {clickClose = true})
end

return CloneBattleRoomView
