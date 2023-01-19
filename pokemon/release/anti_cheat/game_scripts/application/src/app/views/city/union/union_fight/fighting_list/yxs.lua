-- @date:   2020-02-25
-- @desc:   公会战预选赛战斗界面

local unionTools = require "app.views.city.union.tools"
local viewBase = cc.load("mvc").ViewBase
local UnionFightListYXSView = class("UnionFightListYXSView", viewBase)

UnionFightListYXSView.RESOURCE_FILENAME = "union_fight_fighting_list.json"
UnionFightListYXSView.RESOURCE_BINDING = {
	["list"] = "list",
	["itemBattle"] = "itemBattle",
	["itemTip"] = "itemTip",
	["itemRound"] = "itemRound",
	["itemRound.baseNode.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(59, 51, 59, 255)}},
		},
	},
	["itemTip.baseNode.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(59, 51, 59, 255)}},
		},
	},
	["itemBattle.baseNode.leftPanel.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(126, 60, 06, 255)}},
		},
	},
	["itemBattle.baseNode.leftPanel.lv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["itemBattle.baseNode.leftPanel.level"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["itemBattle.baseNode.leftPanel.team"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(59, 51, 59, 255)}},
		},
	},
	["itemBattle.baseNode.leftPanel.hpText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(238, 210, 171, 255)}},
		},
	},
	["itemBattle.baseNode.rightPanel.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(126, 60, 06, 255)}},
		},
	},
	["itemBattle.baseNode.rightPanel.lv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["itemBattle.baseNode.rightPanel.level"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["itemBattle.baseNode.rightPanel.team"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(59, 51, 59, 255)}},
		},
	},
	["itemBattle.baseNode.rightPanel.hpText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(238, 210, 171, 255)}},
		},
	},
	["itemBattle.baseNode.leftPanel.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
	["itemBattle.baseNode.rightPanel.self.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(130, 45, 19, 255)}},
		},
	},
	["itemBattle.baseNode.rightEmpty.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(126, 60, 6, 255)}},
		},
	},
	["itemBattle.baseNode.leftEmpty.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(126, 60, 6, 255)}},
		},
	},
	["btnShowSelf"] = {
		varname = "btnShowSelf",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowSelf")}
		},
	},
	["btnShowSelf.textNote"] = {
		varname = "btnShowSelf",
		binds = {
			event = "text",
			idler = bindHelper.self("showSelf"),
			method = function(showSelf)
				return showSelf and gLanguageCsv.UFShowAll or gLanguageCsv.UFShowSelf
			end,
		},
	},
}

function UnionFightListYXSView:onCreate(refreshHandle, _roundResults)
	self.role_id = gGameModel.role:read("id")

	local showSelf = userDefault.getForeverLocalKey("jsShowSelf", false)
	self.showSelf = idler.new(showSelf)
	local showSelf = userDefault.setForeverLocalKey("jsShowSelf", false)

	local unionFight = gGameModel.union_fight
	self.unionFight = {
		round = unionFight:getIdler("round"),
		signs = unionFight:getIdler("signs"),
		info = unionFight:getIdler("info"),
		roundResults = unionFight:getIdler("round_results"),
		unionInfo = unionFight:getIdler("union_info"),
		lastRoleName = unionFight:getIdler("last_role_name"),
		nextRoundResultTime = unionFight:getIdler("next_round_result_time"),
	}
	self.curRound = 0 -- 当前轮次 默认0开始
	self.refreshHandle = refreshHandle
	self.roundResults = _roundResults or {}
	self.roundResultsIsShow = {}
	self.insertItemsTb = {}

	self.curRoundType = ""
	local count = 0
	idlereasy.any({self.unionFight.round, self.unionFight.unionInfo, self.unionFight.roundResults, self.unionFight.lastRoleName},
		function(_, round, unionInfo, roundResults, lastRoleName)
			count = count + 1
			local c = count
			performWithDelay(self, function()
				if c ~= count or tolua.isnull(self) then
					return
				end
				self.isPrepare = round == "prepare"

				for r, results in pairs(roundResults) do
					if r and not self.roundResults[r] then
						self.roundResults[r] = results
					end
				end
				for r, results in pairs(self.roundResults) do
					self.curRound = math.max(self.curRound, r)
				end
				if not self.maxRound or not self.minRound then
					-- 第一次获取战斗数据 计算 最大值和最小值
					self.maxRound, self.minRound = 0, math.huge
					for r, _ in pairs(self.roundResults) do
						self.maxRound = math.max(self.maxRound, r)
						self.minRound = math.min(self.minRound, r)
					end
					self.minRound = math.max(self.minRound, self.maxRound - 1)
				end

				self:refreshRoundResult()
				if self.isEnd then return end
				if unionInfo.is_out then -- 已被淘汰
					self:setAllBattleEnd(false)
					return
				elseif lastRoleName ~= "" then
					self:setAllBattleEnd(true, lastRoleName)
					return
				end
			end, 0)
		end)

	local container = self.list:getInnerContainer()
	self.list:onScroll(function(event)
		if self.inReq then
			return
		end
		if event.name == "AUTOSCROLL_ENDED" or container:getPositionY() == 0 then
			if self.minRound > 1 then
				if not self.curSendRound or self.curSendRound <= self.minRound - 1 then
					self.curSendRound = self.minRound - 1
					self.inReq = true
					gGameApp:requestServer("/game/union/fight/battle/main", function(tb)
						self.inReq = nil
						self.curSendRound = nil
					end, self.curSendRound)
				end
			end
		end
	end)

	self:startRefreshTime()
end

function UnionFightListYXSView:setAllBattleEnd(isWin, lastRoleName)
	-- if self.isEnd then return end
	self.isEnd = true

	if not self.lastTipItem then return end
	local textItem = self.lastTipItem:get("baseNode.text")
	if isWin then
		local str = string.format(gLanguageCsv.unionFightBattleWinner, lastRoleName)
		textItem:text("")
		local richText = rich.createByStr(str, 52, nil, nil)
			:addTo(textItem, 10, "privilege")
			:anchorPoint(cc.p(0.5, 0.5))
			:xy(0, 0)
	else
		textItem:text(gLanguageCsv.unionFightBattleLoseTip)
		text.addEffect(textItem, {color = cc.c4b(219, 212, 189, 255)})
	end
end
function UnionFightListYXSView:refreshRoundResult()
	local func = function(round, results)
		if not results then return end
		if not self.roundResultsIsShow[round] then
			self.roundResultsIsShow[round] = true
			local func
			if round >= self.maxRound then  -- 最新的战斗
				func = self.showNewBattleResult
			elseif round <= self.minRound then -- 旧的战斗
				func = self.showOldBattleResult
			else
				func = self.showOldBattleResult
			end
			if func then
				self.maxRound = math.max(self.maxRound, round)
				self.minRound = math.min(self.minRound, round)
				func(self, round, results)
			end
		end
	end

	local roundResults = clone(self.roundResults)
	while next(roundResults) do
		local minRound = 0
		local minResults = nil
		local maxRound = math.huge
		local maxResults = nil
		for round, results in pairs(roundResults) do
			if self.roundResultsIsShow[round] then
				roundResults[round] = nil
			else
				if self.minRound >= round and round >= minRound then
					minRound = round
					minResults = results
				end
				if self.maxRound <= round and round <= maxRound then
					maxRound = round
					maxResults = results
				end
			end
		end
		func(maxRound, maxResults)
		roundResults[maxRound] = nil
		func(minRound, minResults)
		roundResults[minRound] = nil
	end
end

function UnionFightListYXSView:showOldBattleResult(round, results)
	self:setRoundNum(round, true)
	self:roundEnd(true, round, true)
	for idx, result in ipairs(results) do
		if self.showSelf:read()  == true then
			if result.left.role_id == self.role_id or result.right.role_id == self.role_id then
				self:insertBattleInfo(result, true)
			end
		else
			self:insertBattleInfo(result, true)
		end
	end
end

-- 预选赛需每日刷新这个字段 防止用户好几天不下线
local MAX_YXS_ROUND = -1 -- 保存当前最高轮次 若不同 强制播放一次动画 同一次登录有效
local CUR_W_DAY = -1
function UnionFightListYXSView:checkPlayAni(round)
	local wday = time.getNowDate().wday -- 星期
	wday = wday == 1 and 7 or wday - 1
	local day_change = false
	if CUR_W_DAY ~= wday then
		CUR_W_DAY = wday -- 记录日期
		MAX_YXS_ROUND = -1 -- 刷新round记录
	end

	if MAX_YXS_ROUND < round then
		MAX_YXS_ROUND = round
		return true
	end
	return false
end

function UnionFightListYXSView:showNewBattleResult(round, results)
	local isPlayAni = self:checkPlayAni(round)

	local insertItem = function(item, delay, index)
		if not isPlayAni then return end
		table.insert(self.insertItemsTb, {
			item = item:retain(),
			delay = delay,
			index = index,
		})
	end

	insertItem(self:setRoundNum(round, nil, isPlayAni), 0.3, 0)
	for idx, result in ipairs(results) do
		if self.showSelf:read()  == true then
			if result.left.role_id == self.role_id or result.right.role_id == self.role_id then
				insertItem(self:insertBattleInfo(result, nil , isPlayAni), 0.4, 1)
			end
		else
			insertItem(self:insertBattleInfo(result, nil , isPlayAni), 0.4, 1)
		end
	end
	insertItem(self:roundEnd(true, round, nil, isPlayAni), 0.3, 1)
end

function UnionFightListYXSView:startTimeLabel(timeTemp, cb)
	local tag = 3031507
	if self.roundItem then
		self.roundItem:removeFromParent()
		self.roundItem = nil
	end

	if timeTemp <= 0 then
		self.isSkip = nil
		self:enableSchedule():unSchedule(tag)
		return
	end

	if not self.roundItem then
		self.roundItem = self:setRoundNum(self.curRound + 1)
		self.roundItem:retain()
	end
	self.isSkip = true
	self:enableSchedule():unSchedule(tag)
	self:enableSchedule()
		:schedule(function(dt)
			if timeTemp <= 0 then
				self:removeTimeLabel()
				self.isSkip = nil
				if cb then
					cb()
				end
				return false
			end
			local cDown = time.getCutDown(timeTemp)
			timeTemp = timeTemp - 1
			self:showTimeLabel(cDown.str)
		end, 1, 0, tag)
end

function UnionFightListYXSView:roundEnd(win, round, isBack, noInsert)
	win = win or true -- todo
	local str = string.format(gLanguageCsv.unionFightBattleWinTip, round)
	if not win then
		str = gLanguageCsv.unionFightBattleLoseTip
	end
	local item = self:insertTip(str, isBack, noInsert)
	if not self.maxRound or round >= self.maxRound then
		self.lastTipItem = item
	end
	return item
end

function UnionFightListYXSView:setRoundNum(n, isBack, noInsert)
	local item = self.itemRound:clone()
	local children = item:get("baseNode"):multiget("text")
	children.text:text(string.format(gLanguageCsv.unionFightRound, n))

	if noInsert then -- 不预先插入
		return item
	end

	if isBack then
		self.list:pushBackCustomItem(item)
	else
		local index = 0
		if self.timeItem then index = index + 2 end
		self.list:insertCustomItem(item, index)
	end
	return item
end

function UnionFightListYXSView:insertBattleInfo(result, isBack, noInsert)
	local item = self.itemBattle:clone()
	local isEmpty = false
	local children = item:get("baseNode"):multiget("btnReplay", "leftPanel", "rightPanel", "leftEmpty", "rightEmpty")
	local function setResultPanel(panel, v, isWin, emptyPanel)
		if not v.role_id then
			isEmpty = true
			panel:hide()
			emptyPanel:show()
			return
		end

		local children = panel:multiget("roleIcon", "level", "name", "unionName", "team", "hpText", "hpBar", "win", "self")
		bind.extend(self, children.roleIcon, {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = v.role_logo,
				frameId = v.role_frame,
				vip = false,
				level = false,
			}
		})
		children.level:text(v.role_level)
		children.name:text(v.role_name)
		children.unionName:text(v.union_name)
		children.team:text(string.format(gLanguageCsv.unionFightTeam, v.troops))
		local str = v.hp > 0 and string.format(gLanguageCsv.unionFightHpText, v.hp.."%") or gLanguageCsv.unionFightDead
		children.hpText:text(str)
		children.self:visible(v.role_id == gGameModel.role:read("id"))
		bind.extend(self, children.hpBar, {
			event = "extend",
			class = "loadingbar",
			props = {
				data = v.hp,
				maskImg = "city/union/union_fight/jdt_1.png"
			},
		})
		children.hpBar:setPercent(v.hp)
		children.win:visible(isWin)
	end

	local unionId = gGameModel.role:read("union_db_id")
	local left = result.left
	local right = result.right
	local isWin = result.result == "win"
	local exChange = false
	if left.union_id and left.union_id ~= unionId then -- 左侧不是自己公会
		if right.union_id and right.union_id == unionId then -- 右侧是自己公会
			-- 左右交换
			left = result.right
			right = result.left
			isWin = not isWin
			exChange = true
		end
	end

	setResultPanel(children.leftPanel:show(), left, isWin, children.leftEmpty:hide())
	setResultPanel(children.rightPanel:show(), right, not isWin, children.rightEmpty:hide())

	if isEmpty then
		children.btnReplay:setTouchEnabled(false)
	else
		bind.touch(self.list, children.btnReplay, {methods = {ended = self:createHandler("onReplayClick", result.play_id, exChange)}})
	end

	if noInsert then -- 不预先插入
		return item
	end

	if isBack then
		self.list:pushBackCustomItem(item)
	else
		local index = 1
		if self.timeItem then index = index + 2 end
		self.list:insertCustomItem(item, index)
	end

	return item
end

function UnionFightListYXSView:insertTip(tip, isBack, noInsert)
	local item = self.itemTip:clone()
	local children = item:get("baseNode"):multiget("text")
	children.text:text(tip)
	if noInsert then -- 不预先插入
		return item
	end
	if isBack then
		self.list:pushBackCustomItem(item)
	else
		local index = 1
		if self.timeItem then index = index + 2 end
		self.list:insertCustomItem(item, index)
	end
	return item
end

function UnionFightListYXSView:showTimeLabel(t)
	t = t or "00:25"
	local str = string.format(gLanguageCsv.unionFightTimeText, t)
	if not self.timeItem then
		local item = self.itemTip:clone()
		local children = item:get("baseNode.text"):text(str)
		self.list:insertCustomItem(item, 1)
		self.timeItem = item
		self.timeItem:retain()
	else
		self.timeItem:get("baseNode.text"):text(str)
		-- 检查位置
		if self.roundItem and self.list:getIndex(self.roundItem) ~= 0 then
			self.list:removeItem(self.list:getIndex(self.roundItem))
			self.list:insertCustomItem(self.roundItem, 0)
		end
		if self.timeItem and self.list:getIndex(self.timeItem) ~= 1 then
			self.list:removeItem(self.list:getIndex(self.timeItem))
			self.list:insertCustomItem(self.timeItem, 1)
		end
	end
end

function UnionFightListYXSView:removeTimeLabel()
	if self.timeItem then
		self.timeItem:removeFromParent()
		self.timeItem = nil
	end
	if self.roundItem then
		self.roundItem:removeFromParent()
		self.roundItem = nil
	end
end

function UnionFightListYXSView:onReplayClick(playId, exChange)
	userDefault.setForeverLocalKey("jsShowSelf", self.showSelf:read())
	if exChange then exChange = 1
	else exChange = 0 end
	local interface = "/game/union/fight/playrecord/get"
	gGameModel:playRecordBattle(playId, nil, interface, exChange, nil)
end

function UnionFightListYXSView:startRefreshTime()
	local function getTimeTemp()
		local nowTime = time.getTimestamp(time.getNowDate())
		local tm1 = gGameModel.union_fight:read("prepare_end_time")
		local tm2 = gGameModel.union_fight:read("next_round_result_time")
		local tm = math.max(tm1, tm2)

		return tm - nowTime
	end

	local tag = 03031825
	local delay = 0.5 -- 固定时间刷新一次(秒)
	-- delay = 5
	self:enableSchedule():unSchedule(tag)
	self:enableSchedule()
		:schedule(function(dt)
			if not self:addNewBattleInfo() then return end 			-- 正在动画中
			if self.inAni then return end
			if self.isSkip then return end 			-- 已在另一个计时中 跳过
			-- self:removeTimeLabel()
			if self.isEnd then return false end 	-- 已经结束 跳过

			local timeTemp = getTimeTemp()

			if timeTemp <= 0 then
				self.refreshHandle()
				return
			end

			self:startTimeLabel(timeTemp, function()
				self.refreshHandle(function()
					-- self:addNewBattleInfo()
				end)
			end)
		end, delay, 0, tag)
end

function UnionFightListYXSView:addNewBattleInfo()
	if self.inAni then return false end
	if not self.insertItemsTb or not next(self.insertItemsTb) then
		self.inAni = false
		return true
	end

	local first = self.insertItemsTb[1]
	table.remove(self.insertItemsTb, 1)

	-- todo 开始动画效果 动画必须在下一次插入前播放完全
	local addItemFunc = function(item, index, delay)
		delay = math.min(delay, 0.3)
		local h = item:size().height
		local isInsert = false
		if self.list:getChildrenCount() <= index then
			self.list:insertCustomItem(item, index)
			self.inAni = false
			return
		end

		for idx, it in pairs(self.list:getChildren()) do
			if idx > index then
				local baseNode = it:get("baseNode")
				local x, y = baseNode:xy()
				baseNode:setTouchEnabled(false)
				transition.executeSequence(baseNode, true)
					:moveTo(delay, x, y - h)
					:func(function()
						baseNode:xy(x, y)
						baseNode:setTouchEnabled(true)
						if not isInsert then
							self.list:insertCustomItem(item, index)
							self.inAni = false
							isInsert = true
						end
					end)
					:done()
			end
		end
	end

	self.inAni = true
	addItemFunc(first.item, first.index, first.delay)
	return false
end
function UnionFightListYXSView:onShowSelf()
	if not gGameModel.daily_record:read("union_fight_sign_up") then
		gGameUI:showTip(gLanguageCsv.UFRecordNoSelfData)
		return
	end
	self.showSelf:modify(function(showSelf)
		return true, not showSelf
	end)
	self:removeTimeLabel()
	self.list:removeAllChildren()

	-- 第一次获取战斗数据 计算 最大值和最小值
	self.maxRound, self.minRound = 0, math.huge
	for r, _ in pairs(self.roundResults) do
		self.maxRound = math.max(self.maxRound, r)
		self.minRound = math.min(self.minRound, r)
	end
	self.minRound = math.max(self.minRound, self.maxRound - 1)

	self.roundResultsIsShow = {}
	self.insertItemsTb = {}

	self.isSkip = nil
	self:enableSchedule():unScheduleAll()
	self:startRefreshTime()

	self:refreshRoundResult()

	if self.unionFight.unionInfo:read().is_out then -- 已被淘汰
		self:setAllBattleEnd(false)
		return
	elseif self.unionFight.lastRoleName:read() ~= "" then
		self:setAllBattleEnd(true, self.unionFight.lastRoleName:read())
		return
	end
	self.list:jumpToTop()
end

return UnionFightListYXSView