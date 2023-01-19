-- @date:   2019-9-30 18:17:21
-- @desc:   限时PVP布阵主界面

local ViewBase = cc.load("mvc").ViewBase
local CraftEmbattleView = class("CraftEmbattleView", ViewBase)

local CONDITIONS = {
	{name = gLanguageCsv.fighting, attr = "fight"},
	{name = gLanguageCsv.level, attr = "level"},
	{name = gLanguageCsv.rarity, attr = "rarity"},
	{name = gLanguageCsv.star, attr = "star"},
	{name = gLanguageCsv.getTime, attr = "getTime"}
}

local CHANGE2BATTLE = -1
local DELAY = 10

local TIMES = {
	prepare = 10 * 60,
	pre = 4 * 60,
	final = 5 * 60,
}

local PROGRESS = {
	signup = 1,
	prepare = 2,
	pre = 3,
	final = 4,
	over = 5,
	closed = 6,
}

local IDXS = {
	[1] = {7, 8, 9},
	[2] = {4, 5, 6},
	[3] = {1, 2, 3},
}

local MAXROLENUM = 10

local function getDelta(round)
	local delta = 0
	if string.find(round, "prepare") then
		delta = TIMES.prepare
	elseif string.find(round, "pre") then
		delta = TIMES.pre
	elseif string.find(round, "final") then
		delta = TIMES.final
	elseif round == "signup" then
		local signUpStartHour, signUpStartMin = dataEasy.getTimeStrByKey("craft", "signUpStart", true)
		local signUpEndHour, signUpEndMin = dataEasy.getTimeStrByKey("craft", "signUpEnd", true)
		local curDate = time.getNowDate()
		curDate.hour = signUpEndHour
		curDate.min = signUpEndMin
		local endTime = time.getTimestamp(curDate)
		curDate.hour = signUpStartHour
		curDate.min = signUpStartMin
		local startTime = time.getTimestamp(curDate)
		delta = endTime - startTime
	end

	return delta
end

CraftEmbattleView.RESOURCE_FILENAME = "craft_battle.json"
CraftEmbattleView.RESOURCE_BINDING = {
	["up"] = "up",
	["down"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("round"),
			method = function(val)
				return val == "signup"
			end,
		},
	},
	["startDown"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("round"),
			method = function(val)
				return not (val == "signup")
			end,
		},
	},
	["startDown.btnSave"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSave")},
		},
	},
	["startDown.btnCancle"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["down.selTime"] = {
		varname = "selTime",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("sortDatas"),
				expandUp = true,
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				onNode = function(node)
					node:xy(-1120, -485):z(2)
				end,
			},
		}
	},
	["down.sel"] = "sel",
	["down.textTip"] = "textTip",
	["roleItem"] = "roleItem",
	["down.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("allCardDatas"),
				item = bindHelper.self("roleItem"),
				emptyTxt = bindHelper.self("textTip"),
				dataFilterGen = bindHelper.self("onFilterCards", true),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				onItem = function(list, node, k, v)
					node:setName("item" .. list:getIdx(k))
					local size = node:size()
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							grayState = (v.battle == 1) and 1 or 0,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
								panel:xy(-4, -4)
							end,
						}
					})
					local textNote = node:get("textNote")
					textNote:visible(v.battle == 1)
					uiEasy.addTextEffect1(textNote)
					node:onTouch(functools.partial(list.clickCell, list, node, k, v))
				end,
				onBeforeBuild = function(list)
					list.emptyTxt:hide()
				end,
				onAfterBuild = function(list)
					local cardDatas = itertools.values(list.data)
					if #cardDatas == 0 then
						list.emptyTxt:show()
					else
						list.emptyTxt:hide()
					end
				end,
				asyncPreload = 11,
			},
			handlers = {
				clickCell = bindHelper.self("onCardItemTouch"),
			},
		},
	},
	["imgStar"] = "imgStar",
	["up.state1"] = {
		varname = "state1",
		binds = {
			event = "visible",
			idler = bindHelper.self("curState"),
			method = function(val)
				return val ~= PROGRESS.final
			end,
		},
	},
	["up.state2"] = {
		varname = "state2",
		binds = {
			event = "visible",
			idler = bindHelper.self("curState"),
			method = function(val)
				return val == PROGRESS.final
			end,
		},
	},
	["up.state1.item1"] = "item1",
	["up.state1.item2"] = "item2",
	["up.state1.item3"] = "item3",
	["up.state1.item4"] = "item4",
	["up.state1.item5"] = "item5",
	["up.state1.item6"] = "item6",
	["up.state1.item7"] = "item7",
	["up.state1.item8"] = "item8",
	["up.state1.item9"] = "item9",
	["up.state1.item10"] = "item10",
	["up.state2.item1"] = "item21",
	["up.state2.item2"] = "item22",
	["up.state2.item3"] = "item23",
	["up.state2.item4"] = "item24",
	["up.state2.item5"] = "item25",
	["up.state2.item6"] = "item26",
	["up.state2.item7"] = "item27",
	["up.state2.item8"] = "item28",
	["up.state2.item9"] = "item29",
	["up.state2.item10"] = "item210",
	["up.spe"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("hasSpecial"),
		},
	},
	["item"] = "item",
	["up.spe.list"] = {
		varname = "speList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					for i=1,2 do
						node:get("imgIcon" .. i):hide()
					end
					local count = 0
					for i,v in ipairs(v.natureTypes) do
						node:get("imgIcon" .. i):texture(ui.ATTR_ICON[v])
						node:get("imgIcon" .. i):show()
						count = count + 1
					end
					local attrName = game.ATTRDEF_TABLE[v.attrType]
					local str = "attr" .. string.caption(attrName)
					node:get("textName"):text(gLanguageCsv[str])
					local val = dataEasy.getAttrValueString(v.attrType, v.attrNum)
					node:get("textVal"):text("+" .. val)
					text.addEffect(node:get("textName"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}})
					text.addEffect(node:get("textVal"), {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}})
					local target = count == 1 and node:get("imgIcon1") or node:get("imgIcon2")
					adapt.oneLinePos(target, {node:get("textName"), node:get("textVal")}, cc.p(10, 0))
				end,
			},
		},
	},
	["up.textTimeNote"] = {
		varname = "textTimeNote",
		binds = {
			{
				event  = "text",
				idler = bindHelper.self("stateTextNote"),
			},
			{
				event = "visible",
				idler = bindHelper.self("info"),
				method = function(val)
					return not val.isout
				end,
			},
		},
	},
	["up.textTime"] = {
		varname = "textTime",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("timeNote"),
				method = function(val)
					if not val then
						return ""
					end
					local t = time.getCutDown(val)
					return t.short_clock_str
				end,
			},
			{
				event = "visible",
				idler = bindHelper.self("info"),
				method = function(val)
					return not val.isout
				end,
			},
		},
	},
	["down.btnOneKeySet"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneKeyEmbattleBtn")}
		},
	},
	["down.btnSave"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSave")}
		},
	},
	["down.btnSave.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["down.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("roleNum"),
		},
	},
	["down.textTip2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
}

function CraftEmbattleView:onCreate()
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.formation, subTitle = "FORMATION"})
	self:enableSchedule()

	local worldPos = self:convertToWorldSpace(cc.p(self.up:x(), self.up:y()))
	self.offsetX = self.up:x() - worldPos.x
	self.offsetY = self.up:y() - worldPos.y

	self:initHeroSprite()
	-- 用于八强赛的时候 记录是否对调了队伍的顺序
	self.isChanged = false
	-- 用于比较队伍是否发生变化
	self.baseDatas = {}
	self.showDatas = idlertable.new({})
	self:initModel()
	self.roleNum = idler.new("")
	self.timeNote = idler.new()

	self.attrDatas = idlers.newWithMap({})
	self.hasSpecial = idler.new(false)

	local buffCsv = csv.craft.buffs
	local t = {}
	local count = 0
	for i,v in ipairs(self.buffs) do
		count = count + 1
		local data = {}
		local cfg = buffCsv[v]
		data.natureTypes = cfg.natureTypes
		data.attrType = cfg.attrType
		data.attrNum = cfg.attrNum
		table.insert(t, data)
	end
	self.attrDatas:update(t)
	self.hasSpecial:set(count > 0)

	self.sortDatas = idlertable.new(arraytools.map(CONDITIONS, function(i, v) return v.name end))
	self.allCardDatas = idlers.newWithMap({})
	--获取精灵数据
	idlereasy.when(self.cards, function (_, cards)
		local battleCards = self.showDatas:read()
		local hash = itertools.map(battleCards, function(k, v) return v.dbId, k end)
		local all = {}
		for k, dbid in ipairs(cards) do
			local card = gGameModel.cards:find(dbid)

			local cardDatas = card:multigetIdler("card_id", "skin_id","fighting_point", "level", "star", "advance", "created_time")
			idlereasy.any(cardDatas, function(_, card_id, skin_id, fighting_point, level, star, advance, created_time)
				local cardCsv = csv.cards[card_id]
				local unitCsv = csv.unit[cardCsv.unitID]
				local unitID = dataEasy.getUnitId(card_id,skin_id)
				-- 1 上阵
				local battle = hash[dbid] and 1 or 2
				all[dbid] = {
					id = card_id,
					unitId = unitID,
					rarity = unitCsv.rarity,
					attr1 = unitCsv.natureType,
					attr2 = unitCsv.natureType2,
					fight = fighting_point,
					level = level,
					star = star,
					getTime = created_time,
					dbid = dbid,
					advance = advance,
					battle = battle,
					atkType = cardCsv.atkType,
				}
				dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
				self.allCardDatas:update(all)
			end):anonyOnly(self, k)
		end
	end)

	self.filterCondition = idlertable.new()
	local pos = self.sel:parent():convertToWorldSpace(self.sel:box())
	pos = self:convertToNodeSpace(pos)
	gGameUI:createView("city.card.bag_filter", self.sel):init({
		cb = self:createHandler("onBattleFilter"),
		others = {
			width = 190,
			height = 122,
			panelOrder = true,
			x = gGameUI:getConvertPos(self.sel, self:getResourceNode()),
		}
	}):z(19):xy(-pos.x, -pos.y)
	self.sel:z(5)

	self.seletSortKey = idler.new(1)
	self.tabOrder = idler.new(true)
	idlereasy.any({self.filterCondition, self.seletSortKey, self.tabOrder}, function()
		dataEasy.tryCallFunc(self.list, "filterSortItems", false)
	end)

	self.curState = idler.new(PROGRESS.signup)
	self.stateTextNote = idler.new(gLanguageCsv.stateFighting .. ":")
	self.textTimeNote:text(gLanguageCsv.stateFighting .. ":")
	adapt.oneLinePos(self.textTimeNote, self.textTime)
	self.refresh = idler.new(false)
	idlereasy.any({self.round, self.stateTime, self.info, self.refresh}, function(_, round, stateTime, info)
		if round == "over" or round == "closed" then
			self:unScheduleAll()
			performWithDelay(self, function()
				ViewBase.onClose(self)
				gGameUI:showTip(gLanguageCsv.todayBattleOver)
			end, 0)
			return
		end
		local state
		local str = ""
		if round == "signup" then
			state = PROGRESS.signup
			str = gLanguageCsv.isSIgnUping
			CHANGE2BATTLE = -1

		elseif round == "prepare" then
			CHANGE2BATTLE = -1
			state = PROGRESS.prepare
			str = gLanguageCsv.isReading

		elseif string.find(round, "^pre%d") then
			state = PROGRESS.pre
			str = gLanguageCsv.stateFighting
			if not string.find(round, "_lock") then
				str = gLanguageCsv.stateReady
				CHANGE2BATTLE = -1
			end

		elseif string.find(round, "final") then
			self:changeHeroPos()
			state = PROGRESS.final
			str = gLanguageCsv.stateFighting
			if not string.find(round, "_lock") then
				str = gLanguageCsv.stateReady
				CHANGE2BATTLE = -1
			end
		end
		self.stateTextNote:set(str .. ":")
		self.textTimeNote:text(str .. ":")
		adapt.oneLinePos(self.textTimeNote, self.textTime)

		if state == PROGRESS.final and info.isout then
			self:onClose()
			return
		end
		-- 没修改一次round 就要刷新一下界面
		self.curState:set(state, true)
	end)

	idlereasy.any({self.showDatas, self.curState, self.info}, function(_, showDatas, curState, info)
		local count = 0
		for i=1,MAXROLENUM do
			if showDatas[i] then
				count = count + 1
				self:upHero(showDatas[i].dbId, false, i)
			end
		end
		self.roleNum:set(string.format("%s/%s", count, MAXROLENUM))
	end)

	local lastRequestTime = 0
	local function requestMain()
		-- 异常卡秒，连续请求间隔 DELAY
		if time.getTime() - lastRequestTime > DELAY then
			lastRequestTime = time.getTime()
			gGameApp:requestServer("/game/craft/battle/main", function()
				if self.refresh then
					self.refresh:set(not self.refresh:read())
				end
			end)
			return true
		end
	end
	local function setLabel(delta)
		local round = self.round:read()
		-- 不在报名和准备阶段的时候就只是单纯的-1操作
		if round ~= "signup" and round ~= "prepare" then
			-- 战斗时间下 round还不是战斗状态 并且可以发送请求 就请求一次改变round
			if delta <= 60 and not string.find(round, "_lock") then
				if CHANGE2BATTLE < 0 then
					-- 防止连续发送请求
					CHANGE2BATTLE = 10
					gGameApp:requestServer("/game/craft/battle/main", function()
						if self.refresh then
							self.refresh:set(not self.refresh:read())
						end
					end)
				else
					CHANGE2BATTLE = CHANGE2BATTLE - 1
				end
			end
			-- 备赛状态 减去60s （减去战斗时间）
			if delta > 60 then
				delta = delta - 60
			end
		end
		self.timeNote:set(delta)
	end
	setLabel(self:getTime())
	self:schedule(function()
		local round = self.round:read()
		if round == "over" or round == "closed" then
			return false
		end
		local delta = self:getTime()
		if delta < 0 then
			requestMain()
		else
			setLabel(delta)
		end
	end, 1, 0)
end

function CraftEmbattleView:changeHeroPos()
	if self.isChanged then
		return
	end
	self.showDatas:modify(function(showDatas)
		-- [7, 8, 9, 4, 5, 6, 1, 2, 3, 10]
		for i = 1, 3 do
			showDatas[i], showDatas[6 + i] = showDatas[6 + i], showDatas[i]
		end
		self.baseDatas = clone(showDatas)
		return true, showDatas
	end)

	self.isChanged = true
end

function CraftEmbattleView:initModel()
	local craftData = gGameModel.craft
	self.round = craftData:getIdler("round")
	self.perRound = self.round:read()
	self.stateTime = craftData:getIdler("time")
	self.cards = gGameModel.role:getIdler("cards")
	self.info = craftData:getIdler("info")
	self.cardAttrs = self.info:read().card_attrs
	self.history = craftData:getIdler("history")
	self.buffs = craftData:read("buffs")
	-- 是否报名
	self.isSignup = gGameModel.daily_record:read("craft_sign_up")
	local t = {}
	local count = 0
	local targetDatas = self.info:read().cards
	-- 去掉 cardAttrs 中不是 info:read().cards 的数据
	local hash = arraytools.hash(targetDatas)
	local newCardAttrs = {}
	for k, v in pairs(self.cardAttrs) do
		if hash[k] then
			newCardAttrs[k] = v
		end
	end
	self.cardAttrs = newCardAttrs
	for i=1,10 do
		local dbId = targetDatas[i]
		if dbId then
			count = count + 1
			local card = self.cardAttrs[dbId]
			local cardId
			if not card then
				card = gGameModel.cards:find(dbId)
				cardId = card:read("card_id")
			else
				cardId = card.card_id
			end
			local cfg = csv.cards[cardId]
			t[count] = {dbId = dbId, markId = cfg.cardMarkID}
		end
	end
	self.baseDatas = clone(t)
	self.showDatas:set(t)
end

-- 再战斗中 并且 history中有数据 不可移动
function CraftEmbattleView:isInBattle(idx)
	local round = self.round:read()
	local isFinal = string.find(round, "final")
	local isPre = string.find(round, "^pre%d+")
	local _, _, ss = string.find(round, "(%d+)")
	local curIdx = tonumber(ss)
	local result = false
	if curIdx then
		if isPre then
			if idx < curIdx then
				result = true
			elseif idx == curIdx then
				local delta = self:getTime()
				result = delta <= 60
			end
		elseif isFinal then
			local num = math.ceil(idx / 3)
			if num == 1 then
				num = 3
			elseif num == 3 then
				num = 1
			end
			if num < curIdx then
				result = true
			elseif num == curIdx then
				local delta = self:getTime()
				result = delta <= 60
			end
		end
	end

	return result
end

-- 给界面上的精灵添加拖拽功能
function CraftEmbattleView:initHeroSprite()
	for i = 1,MAXROLENUM do
		local beganPos, moveItem
		local function touchEvent(event)
			if self:isInBattle(i) then
				return
			end
			if event.name == "began" then
				beganPos = event.target:getTouchBeganPosition()
			elseif event.name == "moved" then
				local movePos = event.target:getTouchMovePosition()
				local deltaX = math.abs(movePos.x - beganPos.x)
				local deltaY = math.abs(movePos.y - beganPos.y)
				if (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) and not moveItem then
					moveItem = event.target:clone():addTo(self, 1000, "cloneRoleItem" .. i)
					local dbId = self.showDatas:read()[i].dbId
					local card = self.cardAttrs[dbId] -- 上下阵之后没有保存 （针对报名阶段）
					local cardId, advance,skinId
					if not card then
						card = gGameModel.cards:find(dbId)
						cardId = card:read("card_id")
						skinId = card:read("skin_id")
						advance = card:read("advance")
					else
						cardId = card.card_id
						skinId = card.skin_id
						advance = card.advance
					end
					local rarity = csv.unit[csv.cards[cardId].unitID].rarity
					local unitId = dataEasy.getUnitId(cardId, skinId)
					bind.extend(self, moveItem, {
						class = "card_icon",
						props = {
							unitId = unitId,
							rarity = rarity,
							advance = advance,
						}
					})
				end
				if moveItem then
					moveItem:xy(movePos.x + self.offsetX, movePos.y + self.offsetY)
				end

			elseif event.name == "ended" or event.name == "cancelled" then
				if moveItem then
					if event.y < 340 and self.round:read() == "signup" then
						self:downHero(self.showDatas:read()[i].dbId, true, i)
					else
						local targetIdx = self:whichEmbattleTargetPos(event.target:getTouchEndPosition())
						local isout = self.info:read().isout
						if targetIdx and not isout then
							self:changeHero(i, targetIdx)
						elseif targetIdx and isout then
							gGameUI:showTip(gLanguageCsv.isOutCantResetBattle)
						end
					end
					moveItem:removeFromParent()
					moveItem = nil
				-- click
				elseif self.showDatas:read()[i] and self.round:read() == "signup" then
					self:downHero(self.showDatas:read()[i].dbId, true, i)
				end
			end
		end
		self["item" .. i]:get("head"):onTouch(touchEvent)
		self["item2" .. i]:get("head"):onTouch(touchEvent)
	end
end

function CraftEmbattleView:onSortMenusBtnClick(panel, node, k, v, oldval)
	if oldval == k then
		self.tabOrder:modify(function(val)
			return true, not val
		end)
	else
		self.tabOrder:set(true)
	end
	self.seletSortKey:set(k)
end

function CraftEmbattleView:hasCommonCard(data)
	local markId = csv.cards[data.id].cardMarkID
	for k,v in self.showDatas:pairs() do
		if v.markId == markId then
			return k
		end
	end

	return false
end

function CraftEmbattleView:isInShowData(dbId)
	for k,v in self.showDatas:pairs() do
		if v.dbId == markId then
			return true
		end
	end

	return false
end

function CraftEmbattleView:getIdxByDbId(dbId)
	if not dbId then
		return
	end
	for k,v in self.showDatas:pairs() do
		if dbId == v.dbId then
			return k
		end
	end
end

function CraftEmbattleView:changeHero(idx1, idx2)
	if (not idx1 or not idx2) or idx1 == idx2 then
		return
	end
	local data1 = self.showDatas:read()[idx1]
	local data2 = self.showDatas:read()[idx2]
	if not data1 and not data2 then
		return
	end
	if not data1 then
		self:downHero(data2.dbId, false, idx2)
		self:upHero(data2.dbId, false, idx1)
	elseif not data2 then
		self:downHero(data1.dbId, false, idx1)
		self:upHero(data1.dbId, false, idx2)
	else
		self:downHero(data1.dbId, false, idx1)
		self:downHero(data2.dbId, false, idx2)
		self:upHero(data1.dbId, false, idx2)
		self:upHero(data2.dbId, false, idx1)
	end
end

function CraftEmbattleView:downHero(dbId, isShowTip, idx)
	if dbId then
		if self.allCardDatas:atproxy(dbId) then
			self.allCardDatas:atproxy(dbId).battle = 2
		end
		idx = idx or self:getIdxByDbId(dbId)
		if idx then
			self.showDatas:modify(function(showDatas)
				local changed = showDatas[idx] ~= nil
				showDatas[idx] = nil
				return changed, showDatas
			end)
		end
	end
	if not idx then
		return
	end

	local curState = self.curState:read()
	local item = curState == PROGRESS.final and self["item2" .. idx] or self["item" .. idx]
	local children = item:multiget("head", "textLv", "textNote", "textFightPoint", "imgAttr1", "imgAttr2")
	itertools.invoke(children, "hide")
	if curState ~= PROGRESS.final then
		item:get("btnAdd"):show()
		item:get("imgState"):hide()
		item:get("imgFlag"):hide()
	end
	for i=1,math.huge do
		local star = item:getChildByName("star" .. i)
		if not star then
			break
		end
		star:removeFromParent()
	end
	self.roleNum:set(string.format("%s/%s", self.showDatas:size(), MAXROLENUM))
	if isShowTip then
		gGameUI:showTip(gLanguageCsv.downToEmbattle)
	end
end

function CraftEmbattleView:upHero(dbId, isShowTip, idx)
	local autoIdx
	for i=1,MAXROLENUM do
		if idx then
			autoIdx = idx
			break
		end
		if not self.showDatas:read()[i] then
			autoIdx = i
			break
		end
	end
	idx = autoIdx
	if not idx then
		return
	end

	local card = self.cardAttrs[dbId] -- 上下阵之后没有保存 （针对报名阶段）
	local cardId, skinId, advance, level, fightingPoint, starNum
	if not card then
		card = gGameModel.cards:find(dbId)
		cardId = card:read("card_id")
		skinId = card:read("skin_id")
		advance = card:read("advance")
		level = card:read("level")
		fightingPoint = card:read("fighting_point")
		starNum = card:read("star")
	else
		cardId = card.card_id
		skinId = card.skin_id
		advance = card.advance
		level = card.level
		fightingPoint = card.fighting_point
		starNum = card.star
	end

	local cfg = csv.cards[cardId]
	self.showDatas:modify(function(val)
		local changed, old = false, val[idx]
		if old == nil or old.dbId ~= dbId then
			changed = true
			val[idx] = {dbId = dbId, markId = cfg.cardMarkID}
		end
		return changed, val
	end)
	if self.allCardDatas:atproxy(dbId) then
		self.allCardDatas:atproxy(dbId).battle = 1
	end

	local curState = self.curState:read()
	local item = curState == PROGRESS.final and self["item2" .. idx] or self["item" .. idx]
	local children = item:multiget("head", "textLv", "textNote", "textFightPoint", "imgAttr1", "imgAttr2")
	itertools.invoke(children, "show")
	if curState ~= PROGRESS.final then
		item:get("btnAdd"):hide()
		item:get("imgState"):hide()
		item:get("imgFlag"):hide()
	end
	-- show result and state
	if curState == PROGRESS.pre then
		local count = MAXROLENUM
		for i=1,MAXROLENUM do
			local data = self.history:read()[i]
			-- 没有数据 或者 还在进行当前场次就不显示结果
			if not data or self:isCurBattle(data.round) then
				count = i
				break
			end
			local path = data.result == "win" and "city/pvp/craft/icon_win.png" or "city/pvp/craft/icon_lose.png"
			local parent = curState == PROGRESS.final and self["item2" .. i] or self["item" .. i]
			parent:get("imgFlag"):texture(path)
			parent:get("imgFlag"):show()
			parent:removeChildByName("stateEffect")
		end
		for i=count,MAXROLENUM do
			self["item" .. i]:get("imgFlag"):hide()
			self["item" .. i]:get("imgState"):hide()
		end
		local delta = self:getTime()
		local nextItem = self["item" .. count]
		-- 没出局才显示下一句的状态
		if nextItem and not self.info:read().isout then
			nextItem:removeChildByName("stateEffect")
			if delta > 60 then
				widget.addAnimationByKey(nextItem, "kuafushiying/wz.skel", "stateEffect", "effect_bzz_loop", 10)
					:scale(0.8)
					:xy(nextItem:size().width/2 - 30, nextItem:size().height - 130)
			else
				widget.addAnimationByKey(nextItem, "kuafushiying/wz.skel", "stateEffect", "effect_zdz_loop", 10)
					:scale(0.8)
					:xy(nextItem:size().width/2 - 30, nextItem:size().height - 130)
			end
		end

	elseif curState == PROGRESS.final then
		local isout = self.info:read().isout
		local bgPath = "city/pvp/craft/box_bs.png"
		if isout then
			local str, state
			for i=1,3 do
				local data = self.history:read()[10 + i]
				if data and data.result then
					bgPath = "city/pvp/craft/box_jj.png"
					str = data.result == "win" and gLanguageCsv.jinji or gLanguageCsv.luobai
					state = "normal"
				else
					str = gLanguageCsv.notjinji
					bgPath = "city/pvp/craft/box_bs.png"
					state = "hsl_gray"
				end
				self.state2:get("state" .. i):get("textNote"):text(str)
				self.state2:get("state" .. i):get("imgBg"):texture(bgPath)
				self.state2:get("state" .. i):show()
				cache.setShader(self.state2:get("state" .. i), false, state)
			end
		else
			local round = self.round:read()
			local idx = tonumber(string.sub(round, string.find(round, "%d+")))
			for i=1,idx do
				-- 目前这场比赛 状态只会有 准备中或者战斗中
				local str = gLanguageCsv.beisai
				local bgPath = "city/pvp/craft/box_bs.png"
				local delta = self:getTime()
				local state = "normal"
				if i == idx and delta <= 60 then
					str = gLanguageCsv.zhandou
				-- 已比过的场次
				elseif i < idx then
					local data = self.history:read()[10 + i]
					if data and data.result then
						bgPath = "city/pvp/craft/box_jj.png"
						if data.result == "win" then
							str = gLanguageCsv.jinji
							state = "normal"
						else
							str = gLanguageCsv.luobai
							state = "hsl_gray"
						end
					end
				end
				self.state2:get("state" .. i):get("textNote"):text(str)
				self.state2:get("state" .. i):get("imgBg"):texture(bgPath)
				self.state2:get("state" .. i):show()
				cache.setShader(self.state2:get("state" .. i), false, state)
				if i == 3 then
					local fightData = self.history:read()[12]
					local path = "city/pvp/craft/myteam/txt_gjs.png"
					if fightData and fightData.result == "fail" then
						path = "city/pvp/craft/myteam/txt_jjs.png"
					end
					self.state2:get("img3"):texture(path)
				end
			end
			for i=idx + 1,3 do
				self.state2:get("state" .. i):hide()
				cache.setShader(self.state2:get("state" .. i), false, "normal")
			end
		end
	end

	local unitCfg = csv.unit[cfg.unitID]
	local rarity = unitCfg.rarity
	local unitId = dataEasy.getUnitId(cardId, skinId)
	bind.extend(self, children.head, {
		class = "card_icon",
		props = {
			unitId = unitId,
			rarity = rarity,
			advance = advance,
		}
	})
	local nature1 = unitCfg.natureType
	children.imgAttr1:texture(ui.ATTR_ICON[nature1])
	local nature2 = csv.unit[cfg.unitID].natureType2
	if nature2 then
		children.imgAttr2:texture(ui.ATTR_ICON[nature2])
	else
		children.imgAttr2:hide()
	end
	children.textLv:text("Lv" .. level)
	children.textFightPoint:text(fightingPoint)
	adapt.oneLinePos(children.textLv, {children.imgAttr1, children.imgAttr2}, cc.p(5, 0))
	if curState ~= PROGRESS.final then
		adapt.oneLineCenterPos(cc.p(160, 40), {children.textNote, children.textFightPoint}, cc.p(10, 0))
	end
	for i=1,math.huge do
		local star = item:getChildByName("star" .. i)
		if not star then
			break
		end
		star:removeFromParent()
	end
	for j=1,starNum do
		if j < 7 then
			local relNum = math.min(starNum, 6)
			local pos = curState == PROGRESS.final and cc.p(232 + (j - 1) * 40, 104) or cc.p(165 - 15 * (relNum + 1 - 2 * j), 85)
			local star = self.imgStar:clone()
				:xy(pos)
				:show()
				:addTo(item, 10, "star" .. j)
		else
			local idx = j % 6 == 0 and 6 or j % 6
			local star = item:getChildByName("star" .. idx)
			if star then
				star:texture("common/icon/icon_star_z.png")
			end
		end
	end
	self.roleNum:set(string.format("%s/%s", self.showDatas:size(), MAXROLENUM))
	if isShowTip then
		gGameUI:showTip(gLanguageCsv.addToEmbattle)
	end
end

-- 下边栏卡牌拖动响应
function CraftEmbattleView:onCardItemTouch(list, node, panel, k, v, event)
	if event.name == "began" then
		self.touchBeganPos = panel:getTouchBeganPosition()
		self.list:setTouchEnabled(false)

	elseif event.name == "moved" then
		local movedPos = panel:getTouchMovePosition()
		local pos = event
		local deltaX = math.abs(pos.x - self.touchBeganPos.x)
		local deltaY = math.abs(pos.y - self.touchBeganPos.y)
		if self.hasMovingItem == nil and
			(deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
			-- 斜率不够或对象数量不足列表长度，判定为选中对象
			self.hasMovingItem = false
			if deltaY > deltaX * 0.7 then
				self.hasMovingItem = true
				self.movePanel = self.roleItem:clone():addTo(self, 1000, "i")
				bind.extend(list, self.movePanel, {
					class = "card_icon",
					props = {
						unitId = v.unitId,
						advance = v.advance,
						rarity = v.rarity,
						star = v.star,
						levelProps = {
							data = v.level,
						},
						onNode = function(panel)
							panel:xy(-4, -4)
						end,
					}
				})
				self.movePanel:show()
				self.movePanel:get("textNote"):hide()
			end
		end
		self.list:setTouchEnabled(not self.hasMovingItem)
		if self.movePanel then
			self.movePanel:xy(movedPos.x + self.offsetX, movedPos.y + self.offsetY)
		end

	elseif event.name == "ended" or event.name == "cancelled" then
		local endPos = panel:getTouchEndPosition()
		local isFull, hasSame = false, false
		local len = self.showDatas:size()
		if len >= MAXROLENUM then
			isFull = true
		end
		if self:hasCommonCard(v) then
			hasSame = true
		end
		-- click
		if self.hasMovingItem == nil then
			-- 再阵容上 并且不再战斗中
			if v.battle == 1 then
				local battleIdx = self:getIdxByDbId(v.dbid)
				local isInBattle = self:isInBattle(battleIdx)
				if not isInBattle then
					self:downHero(v.dbid, true)
				end
			else
				if isFull then
					gGameUI:showTip(gLanguageCsv.battleCardCountEnough)
				elseif hasSame then
					gGameUI:showTip(gLanguageCsv.alreadyHaveSameSprite)
				else
					self:upHero(v.dbid, true)
				end
			end
		end
		self.hasMovingItem = nil
		if self.movePanel then
			local targetPos = self:whichEmbattleTargetPos(event)
			if targetPos then
				self:resetBattle(targetPos, v)
				audio.playEffectWithWeekBGM("formation.mp3")
			end
			self.movePanel:removeSelf()
		end
		self.movePanel = nil
	end
end

function CraftEmbattleView:resetBattle(targetIdx, data)
	local curData = self.showDatas:read()[targetIdx]
	if data.battle == 2 then
		local commonIdx = self:hasCommonCard(data)
		if commonIdx and commonIdx ~= targetIdx then
			gGameUI:showTip(gLanguageCsv.alreadyHaveSameSprite)
			return
		end
		if curData then
			self:downHero(curData.dbId, false, targetIdx)
		end
		self:upHero(data.dbid, true, targetIdx)
	else
		-- change 选中的精灵再队伍中 并且拖动到了已上阵精灵的位子
		if curData then
			local idx = self:getIdxByDbId(data.dbid)
			self:changeHero(targetIdx, idx)
		else
			self:downHero(data.dbid, false)
			self:upHero(data.dbid, false, targetIdx)
		end
	end
end

function CraftEmbattleView:oneKeyEmbattleBtn()
	local cardDatas = itertools.values(self.allCardDatas)
	table.sort(cardDatas, function (a,b)
		a, b = a:read(), b:read()
		if a.fight == b.fight then
			return a.rarity > b.rarity
		else
			return a.fight > b.fight
		end
	end)
	local hash = {}
	local newBattleCards = {}
	local i = 0
	for _, v in ipairs(cardDatas) do
		v = v:read()
		local card = gGameModel.cards:find(v.dbid)
		local cardID = card:read("card_id")
		local cardCsv = csv.cards[cardID]
		if not hash[cardCsv.cardMarkID] then
			i = i + 1
			newBattleCards[i] = {dbId = v.dbid, markId = cardCsv.cardMarkID}
			hash[cardCsv.cardMarkID] = true
			if i == MAXROLENUM then
				break
			end
		end
	end
	self.roleNum:set(string.format("%s/%s", i, MAXROLENUM))

	for idx, v in self.showDatas:pairs() do
		self:downHero(v.dbId, false, idx)
	end
	self.showDatas:set(newBattleCards)
end

function CraftEmbattleView:onBattleFilter(attr1, attr2, rarity, atkType)
	self.filterCondition:set({attr1 = attr1, attr2 = attr2, rarity = rarity, atkType = atkType}, true)
end

function CraftEmbattleView:onFilterCards(list)
	local filterCondition = self.filterCondition:read()
	local condition = {
		{"rarity", (filterCondition.rarity < ui.RARITY_LAST_VAL) and filterCondition.rarity or nil},
		{"attr2", (filterCondition.attr2 < ui.ATTR_MAX) and filterCondition.attr2 or nil},
		{"attr1", (filterCondition.attr1 < ui.ATTR_MAX) and filterCondition.attr1 or nil},
		{"atkType", filterCondition.atkType},
	}
	local function isOK(data, key, val)
		if data[key] == nil then
			if key ~= "attr2" or data.attr1 == val then
				return true
			end
		end
		if key == "atkType" then
			for k, v in ipairs(data.atkType) do
				if val[v] then
					return true
				end
			end
			return false
		end
		if data[key] == val then
			return true
		end
		return false
	end
	return function(dbid, card)
		for i = 1, #condition do
			local cond = condition[i]
			if cond[2] then
				if not isOK(card, cond[1], cond[2]) then
					return false
				end
			end
		end
		return true, dbid
	end
end

function CraftEmbattleView:onSortCards(list)
	local seletSortKey = self.seletSortKey:read()
	local attrName = CONDITIONS[seletSortKey].attr
	local tabOrder = self.tabOrder:read()
	return function(a, b)
		if a.battle ~= b.battle then
			return a.battle < b.battle
		end
		local attrA = a[attrName]
		local attrB = b[attrName]
		if attrA ~= attrB then
			if tabOrder then
				return attrA > attrB
			else
				return attrA < attrB
			end
		end

		return a.id < b.id
	end
end

function CraftEmbattleView:whichEmbattleTargetPos(p)
	-- 修正下偏移量
	p.x = p.x + self.offsetX
	p.y = p.y + self.offsetY
	for i = 1, MAXROLENUM do
		local item = self.curState:read() == PROGRESS.final and self["item2" .. i] or self["item" .. i]
		local box = item:box()
		local x, y = item:xy()
		local pos = self.up:convertToWorldSpace(cc.p(x, y))
		pos = self:convertToNodeSpace(pos)
		box.x = pos.x - box.width / 2
		box.y = pos.y - box.height / 2
		local isInBattle = self:isInBattle(i)
		if cc.rectContainsPoint(box, p) and not isInBattle then
			return i
		end
	end
end

function CraftEmbattleView:onSave()
	local len = self.showDatas:size()
	if len < MAXROLENUM then
		gGameUI:showTip(gLanguageCsv.numNotEnough)
		return
	end
	local _, needReset = self:checkBattlerPos()
	if needReset then
		return
	end
	local t = {}
	local d = self.showDatas:read()
	if self.isChanged then
		d = table.deepcopy(d, true)
		-- [7, 8, 9, 4, 5, 6, 1, 2, 3, 10]
		for i = 1, 3 do
			d[i], d[6 + i] = d[6 + i], d[i]
		end
	end
	for k,v in ipairs(d) do
	 	table.insert(t, v.dbId)
	end
	local url = "/game/craft/battle/deploy"
	local tipStr = gLanguageCsv.battleResetSuccess
	if not self.isSignup then
		url = "/game/craft/signup"
		tipStr = gLanguageCsv.signUpSuccess
	end
	gGameApp:requestServer(url, function(tb)
		self.showDatas:read(function(showDatas)
			self.baseDatas = clone(showDatas)
		end)
		self:onClose()
		gGameUI:showTip(tipStr)
	end, t)
end

function CraftEmbattleView:getTime()
	local t = getDelta(self.round:read())
	local currentTime = time.getTime()
	local delta = self.stateTime:read() + t - currentTime
	return delta
end

function CraftEmbattleView:isCurBattle(myRound)
	local round = self.round:read()
	local isLock = string.find(round, "_lock")
	if not isLock then
		return myRound == round
	else
		local _, _, s1 = string.find(round, "(%d+)")
		local _, _, s2 = string.find(myRound, "(%d+)")
		return s1 == s2
	end
end

function CraftEmbattleView:isChangedCardsPos()
	if self.showDatas:size() ~= MAXROLENUM then
		return true
	end
	local isChanged = false
	local pos = {}
	for k,v in self.showDatas:pairs() do
		if v.dbId ~= self.baseDatas[k].dbId then
			table.insert(pos, k)
			isChanged = true
		end
	end

	return isChanged, pos
end

function CraftEmbattleView:checkBattlerPos()
	local round = self.round:read()
	if round == "signup" or round == "prepare" then
		return
	end
	local isChanged, pos = self:isChangedCardsPos()
	local round = self.round:read()
	local _, _, idx = string.find(round, "(%d+)")
	idx = tonumber(idx)
	local needReset = false
	local isBattle = string.find(round, "_lock")
	if string.find(round, "pre") then
		for _,v in ipairs(pos) do
			if v < idx or (isBattle and v == idx) then
				needReset = true
				break
			end
		end
	else
		local eIdx = isBattle and idx or idx - 1
		local t = {}
		for i=1,eIdx do
			for _,v in ipairs(IDXS[i]) do
				table.insert(t, v)
			end
		end
		for _,v in ipairs(pos) do
			needReset = itertools.include(t, v)
			if needReset then
				break
			end
		end
	end
	if needReset then
		self.showDatas:set(self.baseDatas)
		gGameUI:showTip(gLanguageCsv.stateChangedResetPos)
		isChanged = false
	end

	return isChanged, needReset
end

function CraftEmbattleView:onClose()
	local isChanged = self:isChangedCardsPos()

	if isChanged then
		local params = {
			cb = function()
				self:onSave()
			end,
			cancelCb = function()
				ViewBase.onClose(self)
			end,
			btnType = 2,
			content = gLanguageCsv.isSaveCurBattle,
			clearFast = true,
		}
		gGameUI:showDialog(params)
	else
		ViewBase.onClose(self)
	end
end

return CraftEmbattleView