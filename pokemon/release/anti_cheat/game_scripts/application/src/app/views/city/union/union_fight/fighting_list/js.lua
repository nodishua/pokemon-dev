-- @date:   2020-02-25
-- @desc:   公会战决赛战斗界面

local unionTools = require "app.views.city.union.tools"
local UnionFightListJSView = class("UnionFightListJSView", cc.load("mvc").ViewBase)
local MAX_LOAD_NUM = 5 -- 一次加载的数量

UnionFightListJSView.RESOURCE_FILENAME = "union_fight_fighting_list_dialog.json"
UnionFightListJSView.RESOURCE_BINDING = {
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
	["leftUnionPanel.union1"] = "union1",
	["leftUnionPanel.union2"] = "union2",
	["leftUnionPanel.union1.lv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(72, 2, 1, 255)}},
		},
	},
	["leftUnionPanel.union1.level"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(72, 2, 1, 255)}},
		},
	},
	["leftUnionPanel.union2.lv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(72, 2, 1, 255)}},
		},
	},
	["leftUnionPanel.union2.level"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(72, 2, 1, 255)}},
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

local MY_ENEMY_UNION_NAME = "" -- 保存当前敌方公会名字 若不同 强制播放一次动画 同一次登录有效
function UnionFightListJSView:onCreate(data, unions, dontPlayAni)
	self.role_id = gGameModel.role:read("id")
	local showSelf = userDefault.getForeverLocalKey("jsShowSelf", false)
	self.showSelf = idler.new(showSelf)
	local showSelf = userDefault.setForeverLocalKey("jsShowSelf", false)
	local unionId = gGameModel.role:read("union_db_id")
	if unions.left.id ~= unionId and unions.right.id ~= unionId then--不是自己的公会参战 不显示查看自己
		self.btnShowSelf:hide()
	end
	self.data = data
	self.insertItemsTb = {}
	local isAniOpen = self:checkAniOpen(unions.right.name)
	if dontPlayAni then -- 强制关闭动画播放
		isAniOpen = false
	end
	if isAniOpen then
		self:showAllBattleResultWithAni(data)
		self:startRefreshTime()
	else
		self:showAllBattleResult(data)
	end

	local function setIcons(v, node)
		node:get("icon"):texture(gUnionLogoCsv[v.icon])
		node:get("name"):text(v.name)
		node:get("win"):visible(v.isWin)
		node:get("level"):text(v.level)
	end
	setIcons(unions.left, self.union1)
	setIcons(unions.right, self.union2)

	local container = self.list:getInnerContainer()
	self.list:onScroll(function(event)
		if event.name == "AUTOSCROLL_ENDED" or container:getPositionY() == 0 then
			if isAniOpen then return end
			if self.minRound and self.minRound > 0 then
				self:showAllBattleResult(data)
			end
		end
	end)
end

-- 检查是否播放动画
function UnionFightListJSView:checkAniOpen(enemyUnionName)
	if MY_ENEMY_UNION_NAME == enemyUnionName then
		return false
	end

	MY_ENEMY_UNION_NAME = enemyUnionName
	return true
end

-- 静态展开战斗结果
function UnionFightListJSView:showAllBattleResult(roundResults)
	self.minRound = self.minRound or math.huge

	local lastIndex = 0
	for idx, result in ipairs(roundResults) do
		lastIndex = math.max(lastIndex, idx)
	end

	self.minRound = math.min(self.minRound, lastIndex)

	-- 如果没有显示战斗结果 则先显示出来
	if not self.roundEndItem then
		local lastResult = roundResults[lastIndex]
		local left = lastResult.left
		local right = lastResult.right
		local isLastWin = lastResult.result == "win"
		local winner = isLastWin and left or right
		local loser = isLastWin and right or left

		self:roundEnd(winner, loser)
	end

	local minRound = math.huge
	for i = self.minRound, self.minRound - MAX_LOAD_NUM, -1 do
		local result = roundResults[i]
		if result then
			self:insertBattleInfo(result, nil, true)
			minRound = math.min(minRound, i)
		else
			break
		end
	end
	self.minRound = minRound - 1
end

-- 将战斗结果加入队列 通过动画展开
function UnionFightListJSView:showAllBattleResultWithAni(roundResults)
	local lastIndex = 0
	local resultTop8 = 1
	local roundFunc = function (result, idx, info)
		local item = self.itemRound:clone():retain()
		local num = info and result or result - 1
		item:get("baseNode"):get("text"):text(string.format(gLanguageCsv.roundNumber, num))
		resultTop8 = result
		table.insert(self.insertItemsTb, {
			item = item,
			delay = 0.4,
			index = 0,
		})
		if not info then
			lastIndex = math.max(lastIndex, idx)
		end
	end
	for idx, result in ipairs(roundResults) do
		if result.top8_3v3_round ~= resultTop8 then
			roundFunc(result.top8_3v3_round, idx)
		end
		table.insert(self.insertItemsTb, {
			item = self:insertBattleInfo(result, true):retain(),
			delay = 0.4,
			index = 0,
		})
		lastIndex = math.max(lastIndex, idx)
	end
	roundFunc(resultTop8, nil, true)

	local lastResult = roundResults[lastIndex]
	local left = lastResult.left
	local right = lastResult.right
	local isLastWin = lastResult.result == "win"
	local winner = isLastWin and left or right
	local loser = isLastWin and right or left

	table.insert(self.insertItemsTb, {
		item = self:roundEnd(winner, loser, true):retain(),
		delay = 0.3,
		index = 0,
	})
end

-- win true 赢了 false 输了 nil 自己公会没有参与
function UnionFightListJSView:roundEnd(winner, loser, noInsert)
	local unionId = gGameModel.role:read("union_db_id")
	local isMyWin
	if winner.union_id == unionId then
		isMyWin = true
	elseif loser.union_id == unionId then
		isMyWin = false
	end

	local str = ""
	local color
	if isMyWin == true then
		str = gLanguageCsv.unionFightFinalWin
	elseif isMyWin == false then
		color = cc.c4b(219, 212, 189, 255)
		str = gLanguageCsv.unionFightFinalLose
	else
		str = string.format(gLanguageCsv.unionFightOtherBattle, loser.union_name, winner.union_name)
	end
	local item = self:insertTip(str, color, noInsert)
	self.roundEndItem = item
	return item
end

--结果加入队列
function UnionFightListJSView:insertBattleInfo(result, noInsert, isBack)
	self.resultTop8 = self.resultTop8 or result.top8_3v3_round and self.resultTop8
	local showBattleItem = true
	if self.showSelf:read() then
		if self.role_id ~= result.left.role_id and self.role_id ~= result.right.role_id then
			showBattleItem = false
		end
	end
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
	if not noInsert then
		if isBack then
			if self.resultTop8 ~= result.top8_3v3_round then
				local item2 = self.itemRound:clone()
				item2:get("baseNode"):get("text"):text(string.format(gLanguageCsv.roundNumber, result.top8_3v3_round))
				self.list:pushBackCustomItem(item2)
				self.resultTop8 = result.top8_3v3_round
			end
			if showBattleItem then
				self.list:pushBackCustomItem(item)
			end
		else
			if showBattleItem then
				self.list:insertCustomItem(item, 0)
			end
		end
	end
	return item
end

function UnionFightListJSView:insertTip(tip, color, noInsert)
	local item = self.itemTip:clone()
	local children = item:get("baseNode"):multiget("text")
	children.text:text(tip)
	if color then
		text.addEffect(children.text, {color = color})
	end
	self.lastTipItem = item
	if not noInsert then
		self.list:insertCustomItem(item, 0)
	end
	return item
end

function UnionFightListJSView:onReplayClick(playId, exChange)
	userDefault.setForeverLocalKey("jsShowSelf", self.showSelf:read())
	if exChange then exChange = 1
	else exChange = 0 end
	local interface = "/game/union/fight/playrecord/get"
	gGameModel:playRecordBattle(playId, nil, interface, exChange, nil)
end

function UnionFightListJSView:addNewBattleInfo()
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

function UnionFightListJSView:startRefreshTime()
	local tag = 03031825
	local delay = 0.5 -- 固定时间刷新一次(秒)
	self:enableSchedule():unSchedule(tag)
	self:enableSchedule()
		:schedule(function(dt)
			if self:addNewBattleInfo() then
				self:enableSchedule():unSchedule(tag)
			else
				return
			end 			-- 正在动画中
		end, delay, 0, tag)
end

function UnionFightListJSView:onShowSelf()
	local hasSelfData = false
	for idx, result in ipairs(self.data) do
		if result.left.role_id == self.role_id or result.right.role_id == self.role_id then
			hasSelfData = true
		end
	end
	if not hasSelfData then
		gGameUI:showTip(gLanguageCsv.UFRecordNoSelfData)
		return
	end
	self.showSelf:modify(function(showSelf)
		return true, not showSelf
	end)
	self:enableSchedule():unScheduleAll()
	self.insertItemsTb = {}
	self.list:removeAllChildren()
	self.minRound = math.huge
	self:showAllBattleResult(self.data)
	self.list:jumpToTop()
end

return UnionFightListJSView