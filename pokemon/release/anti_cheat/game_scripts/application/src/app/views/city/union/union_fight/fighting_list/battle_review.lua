-- @date:   2020-02-25
-- @desc:   公会战上期回顾战斗界面

local unionTools = require "app.views.city.union.tools"
local UnionFightListReView = class("UnionFightListReView", cc.load("mvc").ViewBase)

UnionFightListReView.RESOURCE_FILENAME = "union_fight_battle_review.json"
UnionFightListReView.RESOURCE_BINDING = {
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
	["leftUnionPanel"] = "leftUnionPanel",
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

function UnionFightListReView:onCreate(roundResults, unionInfo)
	self.role_id = gGameModel.role:read("id")
	local showSelf = userDefault.getForeverLocalKey("jsShowSelf", false)
	self.showSelf = idler.new(showSelf)
	local showSelf = userDefault.setForeverLocalKey("jsShowSelf", false)
	self.unionInfo = unionInfo
	self.hasSelfData = false
	self.roundResults = {}
	self.roundResultsIsShow = {}
	local func = function(roundResults)
		if not self.roundResults then return end
		for r, results in pairs(roundResults) do
			if r and not self.roundResults[r] then
				self.roundResults[r] = results
			end
		end
		self:refreshRoundResult()
		self:setAllBattleEnd(not unionInfo.is_out, unionInfo.last_role_name)
	end

	func(roundResults)

	local container = self.list:getInnerContainer()
	self.list:setRenderHint(1)
	self.list:onScroll(function(event)
		if self.inReq then
			return
		end
		if event.name == "AUTOSCROLL_ENDED" or container:getPositionY() == 0 then
			if self.minRound > 1 then
				if not self.curSendRound or self.curSendRound <= self.minRound - 1 then
					self.curSendRound = self.minRound - 1
					self.inReq = true
					gGameApp:requestServer("/game/union/fight/yesterday/battle", function(tb)
						self.inReq = nil
						self.curSendRound = nil
						local roundResults = tb.view.round_results
						func(roundResults)
					end, self.curSendRound)
				end
			end
		end
	end)

	self.leftUnionPanel:get("icon"):texture(gUnionLogoCsv[gGameModel.union:read("logo")])
	self.leftUnionPanel:get("name"):text(gGameModel.union:read("name"))
	-- self.leftUnionPanel:get("text1"):text(unionInfo.live_num .."/".. unionInfo.signs)
	self.leftUnionPanel:get("text2"):text(unionInfo.last_role_name)
	self.leftUnionPanel:get("text3"):text(unionInfo.signs .."/".. unionInfo.members)
end

function UnionFightListReView:setAllBattleEnd(isWin, lastRoleName)
	-- if self.isEnd then return end
	-- self.isEnd = true

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

function UnionFightListReView:refreshRoundResult()
	self.maxRound, self.minRound = self.maxRound or 0, self.minRound or math.huge

	local func = function(round, results)
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
		for round, results in pairs(roundResults) do
			if round <= self.minRound and round >= minRound then
				minRound = round
				minResults = results
			end
		end
		if not minResults then break end
		func(minRound, minResults)
		roundResults[minRound] = nil
	end
end

function UnionFightListReView:showOldBattleResult(round, results)
	self:setRoundNum(round, true)
	self:roundEnd(true, round, true)
	for idx, result in ipairs(results) do
		if self.showSelf:read()  == true then
			if result.left.role_id == self.role_id or result.right.role_id == self.role_id then
				self.hasSelfData = true
				self:insertBattleInfo(result, true)
			end
		else
			self:insertBattleInfo(result, true)
		end
	end
end

function UnionFightListReView:showNewBattleResult(round, results)
	self:setRoundNum(round)
	for idx, result in ipairs(results) do
		if self.showSelf:read()  == true then
			if result.left.role_id == self.role_id or result.right.role_id == self.role_id then
				self.hasSelfData = true
				self:insertBattleInfo(result)
			end
		else
			self:insertBattleInfo(result)
		end
	end
	self:roundEnd(true, round)
end

function UnionFightListReView:roundEnd(win, round, isBack)
	win = win or true -- todo
	local str = string.format(gLanguageCsv.unionFightBattleWinTip, round)
	if not win then
		str = gLanguageCsv.unionFightBattleLoseTip
	end
	local item = self:insertTip(str, isBack)
	if not self.maxRound or round >= self.maxRound then
		self.lastTipItem = item
	end
end

function UnionFightListReView:setRoundNum(n, isBack)
	local item = self.itemRound:clone()
	local children = item:get("baseNode"):multiget("text")
	children.text:text(string.format(gLanguageCsv.unionFightRound, n))
	if isBack then
		self.list:pushBackCustomItem(item)
	else
		self.list:insertCustomItem(item, 0)
	end
	return item
end

function UnionFightListReView:insertBattleInfo(result, isBack)
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
	if isBack then
		self.list:pushBackCustomItem(item)
	else
		self.list:insertCustomItem(item, 1)
	end
	return item
end

function UnionFightListReView:insertTip(tip, isBack)
	local item = self.itemTip:clone()
	local children = item:get("baseNode"):multiget("text")
	children.text:text(tip)
	if isBack then
		self.list:pushBackCustomItem(item)
	else
		self.list:insertCustomItem(item, 1)
	end
	return item
end

function UnionFightListReView:onReplayClick(playId, exChange)
	userDefault.setForeverLocalKey("jsShowSelf", self.showSelf:read())
	if exChange then exChange = 1
	else exChange = 0 end
	local interface = "/game/union/fight/playrecord/get"
	gGameModel:playRecordBattle(playId, nil, interface, exChange, nil)
end

function UnionFightListReView:onShowSelf()
	local function changeShowSelf()
		self.showSelf:modify(function(showSelf)
			return true, not showSelf
		end)
		self.list:removeAllChildren()
		self.maxRound, self.minRound = 0, math.huge
		self.roundResultsIsShow = {}
		self:refreshRoundResult()
		self:setAllBattleEnd(not self.unionInfo.is_out, self.unionInfo.last_role_name)
		self.list:jumpToTop()
	end

	if not self.hasSelfData and self.showSelf:read() == false then
		gGameApp:requestServer("/game/union/fight/rank", function(data)
			local max = 0
			for k,v in csvMapPairs(data.view) do
				max = math.max(k, max)
			end
			if data.view[max].my_rank[2] == 0 then
				gGameUI:showTip(gLanguageCsv.UFRecordNoSelfData)
				return
			else
				changeShowSelf()
			end
		end)
	else
		changeShowSelf()
	end
end

return UnionFightListReView