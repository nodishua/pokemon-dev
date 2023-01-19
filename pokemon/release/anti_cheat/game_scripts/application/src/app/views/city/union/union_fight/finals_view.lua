-- @date:   2020-02-25
-- @desc:   公会战决赛界面

local unionTools = require "app.views.city.union.tools"
local UnionFightFinalsView = class("UnionFightFinalsView", cc.load("mvc").ViewBase)

local BATTLE_STATE = {
	prepare = 1, -- 战备状态
	fighting = 2, -- 战斗中
	winner = 3, -- 战斗胜利
	loser = 4, -- 战斗失败
	finalWin = 5, -- 最终胜利
}

local Pos2Key = {
	[18] = "group-a1",
	[27] = "group-b1",
	[36] = "group-b2",
	[45] = "group-a2",
	[1845] = "group-a3",
	[2736] = "group-b3",
	[-18452736] = "third",
	[18452736] = "champion",
}

UnionFightFinalsView.RESOURCE_FILENAME = "union_fight_finals_view.json"
UnionFightFinalsView.RESOURCE_BINDING = {
	["signPanel"] = "signPanel",
	["signPanel.ready"] = "ready",
	["signPanel.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(166, 105, 38, 255), size = 8}},
		},
	},
	["btnFightList"] = {
		varname = "btnFightList",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnFightListClick")}
		},
	},
	["btnAssign"] = {
		varname = "btnAssign",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnAssignClick")}
		},
	},
	["btnRange"] = {
		varname = "btnRange",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRangeClick")}
		},
	},
	["attrPanel"] = "attrPanel",
	["attrPanel.item"] = "signItem",
	["attrPanel.note"] = "attrNote",
	["attrPanel.list"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("signAttrData"),
				item = bindHelper.self("signItem"),
				onItem = function(list, node, k, v)
					local children = node:multiget("icon", "text1", "text2")
					children.icon:texture(ui.ATTR_ICON[v.natureId])
					local key = "attr" .. string.caption(game.ATTRDEF_TABLE[v.attrId])
					children.text1:text(gLanguageCsv[key])
					local str = v.value.."%"
					if tonumber(v.value) > 0 then
						str = "+"..str
					end
					children.text2:text(str)
					adapt.oneLinePos(children.text1, children.text2)
				end,
			},
		},
	},
	["mainPanel"] = "mainPanel",
	["battleInfoPanel"] = "battleInfoPanel",
	["btnPos"] = "btnPos",
	["mainPanel.rightUnionPanel.lv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(72, 2, 1, 255)}},
		},
	},
	["mainPanel.rightUnionPanel.level"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(72, 2, 1, 255)}},
		},
	},
	["mainPanel.leftUnionPanel.lv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(72, 2, 1, 255)}},
		},
	},
	["mainPanel.leftUnionPanel.level"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(72, 2, 1, 255)}},
		},
	},
}

local MY_ENEMY_UNION_NAME = "" -- 保存当前敌方公会名字 若不同 强制播放一次动画 同一次登录有效
function UnionFightFinalsView:onCreate(dialogHandler, isInclude, refreshHandler)
	adapt.centerWithScreen("left", "right", nil, {
		{self.signPanel:get("ready"), "pos", "right"},
		{self.btnPos, "pos", "right"}, -- btnPos是下面三个的校准点 其实只适配这一个就行了
		-- {self.btnAssign, "pos", "right"},
		-- {self.btnRange, "pos", "right"},
		-- {self.btnFightList, "pos", "right"},
	})
	self.dialogHandler = dialogHandler
	self.refreshHandler = refreshHandler
	self.isInclude = isInclude
	local unionFight = gGameModel.union_fight
	self.unionFight = {
		round = unionFight:getIdler("round"),
		signs = unionFight:getIdler("signs"),
		info = unionFight:getIdler("info"),
		stars = unionFight:getIdler("battle_stars"),
		starNum = unionFight:getIdler("battle_star_num"),
	}

	self.curState = idler.new(BATTLE_STATE.prepare) -- 战斗中时 用于判断状态
	self.isInBattle = false

	self:initModel()
	self.signAttrData = idlertable.new({})

	local leftUnionPanel = self.mainPanel:get("leftUnionPanel")
	leftUnionPanel:get("text"):text(gGameModel.union:read("name"))
	leftUnionPanel:get("icon"):texture(gUnionLogoCsv[gGameModel.union:read("logo")])
	leftUnionPanel:get("level"):text(gGameModel.union:read("level"))

	local count = 0
	idlereasy.any({self.unionFight.round, self.unionFight.signs, gGameModel.daily_record:getIdler("union_fight_sign_up")},
	function(_, round, signs, signUp)
		count = count + 1
		local c = count
		performWithDelay(self, function()
			if c ~= count then return end
			-- round = "battle"
			local isSignRound = round ~= "battle"
			self.signPanel:get("ready"):visible(signUp)
			self.signPanel:visible(isSignRound)
			self.mainPanel:visible(not isSignRound)
			if isSignRound then
				-- 报名阶段
				self.btnFightList:hide()
				self.btnRange:visible(isInclude and signUp or true)
				self.btnAssign:visible(isInclude and signUp)
			else
				-- 战斗阶段
				self.btnFightList:show()
				self.btnRange:show()
				self.btnAssign:show()
				self:getPrepareStateAndTime()
				-- 开始战斗循环
				self:startBattleLoop()
			end
			adapt.oneLinePos(self.btnPos, {self.btnAssign, self.btnRange, self.btnFightList}, cc.p(58, 0), "right")
		end, 0)
	end)

	idlereasy.any({self.unionFight.stars, self.unionFight.starNum}, function(_, stars, num)
		local attrTb = {}
		for natureId, value in pairs(stars or {}) do
			for attrId, value in pairs(value) do
				if tonumber(value) ~= 0 then
					table.insert(attrTb, {
						natureId = natureId,
						attrId = attrId,
						value = value,
					})
				end
			end
		end

		local count = itertools.size(attrTb)
		self.signAttrData:set(attrTb)
		self.attrPanel:visible(count > 0)

		local originX = 395
		local itemWidth = self.signItem:size().width
		self.attrList:x(originX + (4 - count) * itemWidth / 2)

		adapt.oneLinePos(self.attrList, self.attrNote, cc.p(5, 0), "right")
	end)

	local note1 = self.mainPanel:get("textNote1")
	local note2 = self.mainPanel:get("textNote2")
	local win1 = self.mainPanel:get("leftUnionPanel.win") -- 我方win标志
	local win2 = self.mainPanel:get("rightUnionPanel.win") -- 敌方win标志
	idlereasy.when(self.curState, function(_, state)
		if not state then return end
		if state == BATTLE_STATE.prepare then
			self:playAni(false)
			note1:show() -- 显示战备中
			note2:show() -- 显示倒计时
			win1:hide()
			win2:hide()

			-- 准备阶段的时候 切换右侧信息
			local rightUnionPanel = self.mainPanel:get("rightUnionPanel")
			rightUnionPanel:get("text"):text(self.enemyUnion.name)
			rightUnionPanel:get("icon"):texture(gUnionLogoCsv[self.enemyUnion.logo])
			rightUnionPanel:get("level"):text(self.enemyUnion.level)
		elseif state == BATTLE_STATE.fighting then
			self:playAni(true)
			win1:hide()
			win2:hide()
			note1:show() -- 显示对战中
			note2:hide() -- 隐藏倒计时
		elseif state == BATTLE_STATE.winner then
			self:playAni(false)
			win1:show()
			win2:hide()
			note1:hide() -- 隐藏对战中
			note2:show() -- 显示倒计时
		elseif state == BATTLE_STATE.loser then
			self:playAni(false)
			win1:hide()
			win2:show()
			note1:hide() -- 隐藏对战中
			note2:show() -- 显示倒计时
		elseif state == BATTLE_STATE.finalWin then
			self:playAni(false)
			win1:show()
			win2:hide()
			note1:hide() -- 隐藏对战中
			note2:show() -- 显示倒计时
		end
	end)
end

local function isAllDie(datas)
	local result = true
	for _,info in pairs(datas) do
		for _,team in ipairs(info.troops) do
			for _,card in pairs(team.cards) do
				if card[3] > 0 then
					return false
				end
			end
		end
	end

	return true
end

local ANI_NAME1 = "VS_ANIMATION1"
local ANI_NAME2 = "VS_ANIMATION2"
function UnionFightFinalsView:playAni(inBattle)
	local vsAni = self.mainPanel:get(ANI_NAME1)
	if not vsAni then
		local vsItem = self.mainPanel:get("vs"):hide()
		local size = self.mainPanel:size()
		local vsSize = vsItem:size()
		local spinePath = "union_fight/skeleton.skel"
		vsAni = widget.addAnimationByKey(self.mainPanel, spinePath, ANI_NAME1, "effect", 5)
			:xy(size.width / 2 - vsSize.width / 2 + 20, size.height / 2 + vsSize.height / 2)
			-- :scale(2)
	end
	vsAni:play("effect")
	vsAni:addPlay("effect_loop")

	-- 两边向内夹入的动画
	local MOVE_DIS = 2300
	local delay = 40 / 60
	local playEffect = function(panel, offX)
		local oriX, oriY = panel:xy()
		panel:x(oriX + offX)
		transition.executeSequence(panel)
			:easeBegin("EXPONENTIALOUT")
				:moveTo(delay, oriX, oriY)
			:easeEnd()
			:done()
	end
	playEffect(self.mainPanel:get("leftUnionPanel"), -MOVE_DIS)
	playEffect(self.mainPanel:get("rightUnionPanel"), MOVE_DIS)

	local shiyingVS = self.mainPanel:get(ANI_NAME2)
	if not shiyingVS then
		local textItem = self.mainPanel:get("textNote2"):hide()
		local size = self.mainPanel:size()
		local textSize = textItem:size()
		local spinePath = "union_fight/dz.skel"
		shiyingVS = widget.addAnimationByKey(self.mainPanel, spinePath, ANI_NAME2, "effect_loop", 5)
			:xy(size.width / 2 - textSize.width / 2 + 210, size.height / 2 + textSize.height / 2 - 150)
			-- :scale(1.5)
	end
	shiyingVS:addPlay("effect_loop")
	shiyingVS:visible(inBattle)
end

function UnionFightFinalsView:initModel()
	local unionInfo = gGameModel.union_fight:getIdler("union_info")
	idlereasy.when(unionInfo, function(_, unionInfo)
		self.roles = unionInfo.top8_deploy.roles
		self.rolesInfo = unionInfo.top8_deploy.role_info
		self.enemyUnion = unionInfo.top8_enemy_union
		self.unionInfo = unionInfo
		local children = self.battleInfoPanel:multiget("note1", "text1", "note2", "text2")
		local empty = gLanguageCsv.emptyInfo

		local text1 = unionInfo.cur_point -- 本轮积分
		local text2 = unionInfo.cur_rank -- 当前排名

		if not self.isInclude then
			text2 = gLanguageCsv.unionFightNotInFinal
		else
			text2 = text2 == 0 and empty or text2
		end

		children.text1:text(text1)
		children.text2:text(text2)
		adapt.oneLinePos(children.note1, {children.text1,children.note2,children.text2}, {cc.p(10,0), cc.p(30,0), cc.p(10,0)})
	end)

	-- 检查权限
	local roleId = gGameModel.role:read("id")
	--会长ID 长度12
	local chairmanId = gGameModel.union:read("chairman_db_id")
	--副会长ID 长度12
	local viceChairmans = gGameModel.union:read("vice_chairmans")
	local isChairmans = roleId == chairmanId or viceChairmans[roleId]  -- 是公会管理员
	if not isChairmans then
		 -- 不是公会管理员
		self.btnAssign:get("text"):text(gLanguageCsv.unionFightCheckBattleAssign)
	end
end

function UnionFightFinalsView:getPrepareStateAndTime()
	local prepareTime = gGameModel.union_fight:read("next_round_battle_time") or 0
	local battleTime = gGameModel.union_fight:read("next_round_prepare_time") or 0
	local curTime = time.getTimestamp(time.getNowDate())
	local t = nil
	if curTime <= prepareTime then -- 战备阶段
		if self.isInBattle then -- 状态由 战斗->战备
			self.curState:set(BATTLE_STATE.prepare)
		end
		self.isInBattle = false
		t = prepareTime
	elseif curTime <= battleTime then -- 对战阶段
		if not self.isInBattle then -- 状态由 战备->战斗
			self.curState:set(BATTLE_STATE.fighting)
		end
		self.isInBattle = true
		t = battleTime
	else -- 上面两个条件不对的话 说明服务器数据肯定有问题 但是此时刷新已经来不及了 报错吧
		self.isInBattle = false
		t = curTime
		-- errorInWindows("TIME ERROR, prepareTime:%s, battleTime:%s, curTime:%s", prepareTime, battleTime, curTime)
	end
	local str = self.isInBattle and gLanguageCsv.inBattle or gLanguageCsv.inPrepare
	self:setTestNote(1, str)
	return t - curTime
end

-- 一个小计时器 计时器不会互相抵消 只能等待上一个结束
function UnionFightFinalsView:startTimeLoop(timestamp, cb, cbForSec, loopTag)
	if self.inTimeLoop == loopTag then return end
	local tag = 03181536
	if self.isEnd then
		self:enableSchedule():unSchedule(tag)
		return
	end
	self.inTimeLoop = loopTag
	self:enableSchedule():unSchedule(tag)
	if cbForSec then cbForSec(timestamp) end
	self:enableSchedule()
		:schedule(function(dt)
			if self.isEnd then
				self:enableSchedule():unSchedule(tag)
				return
			end
			if gGameModel.union_fight:read("round") ~= "battle" then return end -- 不在战斗种 不执行这类计时器
			if cbForSec then cbForSec(timestamp) end
			timestamp = timestamp - 1
			if timestamp < 0 then
				if cb then cb() end
				self.inTimeLoop = nil
				self:enableSchedule():unSchedule(tag)
			end
		end, 1, 0, tag)
end

function UnionFightFinalsView:checkCurBattleOver()
	local unionInfo = self.unionInfo
	local enemyUnion = unionInfo.top8_enemy_union
	local eneKey = enemyUnion.top8_round_key
	local myKey = unionInfo.top8_round_key
	local key = myKey..eneKey
	if tonumber(eneKey) < tonumber(myKey) then
		key = eneKey..myKey
	end
	key = tonumber(key)
	local top8Data = gGameModel.union_fight:read("top8_vs_info") or {}
	if top8Data[key] then -- 战报已有 直接进入战斗列表 仅一次
		self.curBattleOver = true
		local winnerId = top8Data[key][1]
		local unionId = gGameModel.role:read("union_db_id")
		local isFinalFight = key >= 18000000
		if winnerId == unionId then
			if isFinalFight then
				self:setBattleOver(true)
				self.curState:set(BATTLE_STATE.finalWin) -- 最终胜利
			else
				self.curState:set(BATTLE_STATE.winner) -- 一般胜利
			end
		else
			self:setBattleOver(false)
			self.curState:set(BATTLE_STATE.loser) -- 战败
		end
		local enemyUnionName = self.unionInfo.top8_enemy_union.name
		if MY_ENEMY_UNION_NAME ~= enemyUnionName then
			MY_ENEMY_UNION_NAME = enemyUnionName
			self:onBtnFightListClick(nil, nil, nil, true)
		end
	else
		self.curBattleOver = false
	end
end

function UnionFightFinalsView:startBattleLoop()
	if self.inLoop then return end -- 防止重复进入 仅此而已
	self.inLoop = true

	local tag = 03181533
	local delay = 1 -- 固定时间刷新一次(秒)
	local count = 0
	self:checkCurBattleOver() -- 提前检测一次
	self:enableSchedule():unSchedule(tag)
	self:enableSchedule()
		:schedule(function(dt)
			if self.isEnd then
				self:enableSchedule():unSchedule(tag)
				return
			end
			if gGameModel.union_fight:read("round") ~= "battle" then return end -- 不在战斗种 不执行这类计时器
			-- 主循环loop
			if self.isInBattle then
				-- 战斗开始后 10分钟后 刷新数据 按道理应该已经恢复到准备阶段
				self:startTimeLoop(self:getPrepareStateAndTime(), function()
					self.refreshHandler()
				end, function(timestamp)
					-- 战斗开始后 不断请求服务器 刷新战斗数据
					count = count + 1
					if not self.curBattleOver and count >= 5 then
						count = 0
						self.refreshHandler(function()
							self:checkCurBattleOver()
						end)
					elseif self.curBattleOver then
						local cDown = time.getCutDown(timestamp)
						self:setTestNote(2, string.format(gLanguageCsv.unionFightFinalBattleWinTip, cDown.str))
					end
				end, "inBattleLoop")
			else
				-- 战斗准备阶段
				-- 准备阶段倒计时
				self.curBattleOver = false -- 回到准备状态时 恢复这个
				self:startTimeLoop(self:getPrepareStateAndTime() + 1,
					function()
						self.refreshHandler() -- 倒计时完 刷新页面
					end,
					function(timestamp)-- 显示战备倒计时
						local cDown = time.getCutDown(timestamp)
						self:setTestNote(2, string.format(gLanguageCsv.prepareTime, cDown.str))
					end, "inPrepareLoop")
			end
		end, delay, 0, tag)
end

-- 查看对战列表
function UnionFightFinalsView:onBtnRangeClick()
	gGameApp:requestServer("/game/union/fight/battle/main", function(tb)
		gGameUI:stackUI("city.union.union_fight.top8_info_view", nil, {clickClose = false})
	end)
end

function UnionFightFinalsView:setTestNote(num, str)
	if self.isEnd then return end
	self.mainPanel:get("textNote"..num):text(str)
end

-- 战报
function UnionFightFinalsView:onBtnFightListClick()
	local unionInfo = self.unionInfo
	local enemyUnion = unionInfo.top8_enemy_union
	local eneKey = enemyUnion.top8_round_key
	local myKey = unionInfo.top8_round_key
	local key = myKey..eneKey
	if tonumber(eneKey) < tonumber(myKey) then
		key = eneKey..myKey
	end
	key = tonumber(key)
	gGameApp:requestServer("/game/union/fight/top8/round/results", function(tb)
		local top8Data = gGameModel.union_fight:read("top8_vs_info") or {}
		local roundResults = gGameModel.union_fight:read("round_results")
		local unionId = gGameModel.role:read("union_db_id")
		local round, data = next(roundResults)
		local winner = top8Data[key]
		if not round or not winner then
			gGameUI:showTip(gLanguageCsv.notStartBattle)
			return
		end

		local winnerId = winner[1]
		local unions = {
			left = {
				id = unionId,
				name = gGameModel.union:read("name"),
				icon = gGameModel.union:read("logo"),
				level = gGameModel.union:read("level"),
				isWin = winnerId == unionId,
			},
			right = {
				id = enemyUnion.id,
				name = enemyUnion.name,
				icon = enemyUnion.logo,
				level = enemyUnion.level,
				isWin = winnerId == enemyUnion.union_id,
			},
		}
		self.dialogHandler("city.union.union_fight.fighting_list.js", data, unions)
	end, Pos2Key[tonumber(key)])
end

--判断队伍中是否有生还
function UnionFightFinalsView:isAllCardDie(datas)
	for _,data in ipairs(datas) do
		for _,card in pairs(data.cards) do
			if card[3] > 0 then
				return false
			end
		end
	end
	return true
end

-- 查看战斗布置
function UnionFightFinalsView:onBtnAssignClick()
	-- body
	-- if is fighting can not enter this view

	local count = 0
	for i,roleId in ipairs(self.roles) do
		local result = self:isAllCardDie(self.rolesInfo[roleId].troops)
		if not result then
			count = count + 1
		end
	end

	if self.isInBattle then
		gGameUI:showTip(gLanguageCsv.isFighttingNotShow)
		return
	end
	if count == 0 then
		gGameUI:showTip(gLanguageCsv.myTeamAllDie)
		return
	end
	-- local t = {
	-- 	level = 1,
	-- 	troops = {
	-- 		[1] = {cards = {{271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}}, troops_fp = 1000},
	-- 		[2] = {cards = {{271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}}, troops_fp = 1000},
	-- 		[3] = {cards = {{271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}}, troops_fp = 1000}
	-- 	},
	-- 	name = "name1",
	-- 	logo = 1,
	-- 	frame = 200,
	-- 	total_fp = 10000,
	-- }

	-- self.rolesInfo = {}
	-- self.roles = {}
	-- for i=1,40 do
	-- 	local t = {
	-- 		level = 1,
	-- 		troops = {
	-- 			[1] = {cards = {{271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}}, troops_fp = 1000},
	-- 			[2] = {cards = {{271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}}, troops_fp = 1000},
	-- 			[3] = {cards = {{271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}, {271, 1, 100, 91, 8, 11}}, troops_fp = 1000}
	-- 		},
	-- 		name = "name" .. i,
	-- 		logo = 1,
	-- 		frame = 200,
	-- 		total_fp = 10000,
	-- 	}
	-- 	table.insert(self.rolesInfo, t)
	-- 	table.insert(self.roles, i)
	-- end
	gGameUI:stackUI("city.union.union_fight.assign", nil, nil, {roles = self.roles, rolesInfo = self.rolesInfo})
end

function UnionFightFinalsView:setBattleOver(win)
	if win then
		self:setTestNote(2, gLanguageCsv.unionFightBattleFinalWinner)
	else
		self:setTestNote(2, gLanguageCsv.unionFightFinalBattleLoseTip)
	end
	self.isEnd = true
end

return UnionFightFinalsView