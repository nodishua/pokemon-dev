local CrossUnionFightTools = {}

--计算玩家是否存活
function CrossUnionFightTools.WhetherLive(cardData)
	local count = 0
	local hpAll = 0
	for k,v in pairs(cardData or {}) do
		count = count + 1
		hpAll = v[1] + hpAll
	end

	if hpAll == 0 then
		return 0
	end
	return mathEasy.getPreciseDecimal(hpAll/count, 1, false)
end


--公会成员状态
function CrossUnionFightTools.unionMembersState(model, id, data, round, all)
	data = data or {}
	if round < 0 then round = 0 end
	if not model then return data end
	for i=1, 3 do
		if model[i] then
			for j, vv in ipairs(model[i] or {}) do
				if round >= vv.round or all then
					if id == vv.left.union_db_id then
						if not data[vv.left.role_db_id] then data[vv.left.role_db_id] = {} end
						if not data[vv.left.role_db_id].troop_card_state then data[vv.left.role_db_id].troop_card_state = {} end
						data[vv.left.role_db_id].troop = vv.left.troop or 1
						for i, v in pairs(vv.left.troop_card_state) do
							data[vv.left.role_db_id].troop_card_state[i]= v
						end
					elseif id == vv.right.union_db_id then
						if not data[vv.right.role_db_id] then data[vv.right.role_db_id] = {} end
						if not data[vv.right.role_db_id].troop_card_state then data[vv.right.role_db_id].troop_card_state = {} end
						data[vv.right.role_db_id].troop = vv.right.troop or 1
						for i, v in pairs(vv.right.troop_card_state) do
							data[vv.right.role_db_id].troop_card_state[i]= v
						end
					end
				end
			end
		end
	end
	return data
end

--筛选战报(这里只筛选是否是自己/自己公会)
function CrossUnionFightTools.comparison(state, data, unionId, roleId)
	if not state[1] and not state[2] then
		if not data.left.role_db_id or not data.right.role_db_id then
			return false
		end
	end


	if state[1] then
		if unionId == data.left.union_db_id or unionId == data.right.union_db_id then
			return true
		else
			return false
		end
	end

	if state[2] then
		if roleId == data.left.role_db_id or roleId == data.right.role_db_id then
			return true
		else
			return false
		end
	end

	return true
end

--判断自己是否死亡
function CrossUnionFightTools.roleDie(data, roleId, group)
	if (roleId == data.left.role_db_id and data.left.troop == group) then
		return CrossUnionFightTools.WhetherLive(data.left.troop_card_state) == 0
	elseif roleId == data.right.role_db_id and data.right.troop == group then
		return CrossUnionFightTools.WhetherLive(data.right.troop_card_state)
	end
	return false
end

-- 粗略判断初赛和决赛（请求用）
function CrossUnionFightTools.getNowMatch(now)
	local preStatus = {"start","prePrepare", "preStart", "preBattle", "preOver", "preAward"}
	local topStatus = {"topPrepare", "topStart", "topBattle", "topOver", "closed"}
	if itertools.include(preStatus, now) then
		return 1
	end
	if itertools.include(topStatus, now) then
		return 2
	end
	return 1 -- 异常之外的状态，返回初赛
end

function CrossUnionFightTools.whetherCloseShowUI(csvId)
	local status = gGameModel.role:read("cross_union_fight_status")
	if status == "closed" then
		local id
		if csvId and csvId ~= 0 then
			id = csvId
		else
			id = dataEasy.getCrossServiceData("crossunionfight", false, -6 * 86400) 
		end
		if id then
			local cfg = csv.cross.service[id]
			local startTime = time.getNumTimestamp(cfg.date, time.getRefreshHour()) + 3 * 24 * 3600
			local endTime = startTime + 3 * 24 * 3600
			if time.getTime() >= startTime and time.getTime() <= endTime then
				return true
			end
		end
	end
	return false
end

function CrossUnionFightTools.battleStateView(select, status)
	if CrossUnionFightTools.getNowMatch(status) == 1 then
		if select then
			if status == "preOver" or status == "preAward" then
				return true
			end
		else
			if status ~= "preOver" and status ~= "preAward" then
				return true
			end
		end
	else
		if select then
			if status == "topOver" or status == "closed" then
				return true
			end
		else
			if status ~= "topOver" and status ~= "closed" then
				return true
			end
		end
	end

	return false
end

--
function CrossUnionFightTools.onInitItem(list, node, v, self, mainRound, playback)
	local tag = 50
	mainRound = mainRound or self.status:read()
	local unionId, roles, slider = self.unionId, self.roles, self.slider
	local itemHeight = 272
	if v.time then --开赛倒计时
		node:get("itmeTime"):visible(not v.itemUp)
		node:get("itmeTime"):text(gLanguageCsv.battleBeginning)
		node:get("upItem"):visible(v.itemUp)
		if v.title then
			node:get("upItem.title"):show()
			node:get("upItem.title"):text(v.title)
			node:get("upItem.time"):hide()
		end
		node:get("upItem.bg"):scale(2)
		itemHeight = v.itemUp and node:get("upItem"):height() or node:get("itmeTime"):height()
		node:get("upItem"):y(node:get("upItem"):height()/2)
		node:get("itmeTime"):y(node:get("itmeTime"):height()/2)
	elseif v.anima then
		if v.unionAlive or v.condition or v.finish then	--公会淘汰
			node:get("upItem"):show()
			node:get("upItem.bg"):scale(2)
			node:get("upItem.title"):show()
			local str
			if v.finish then
				str = gLanguageCsv.crossUnionUnionBattleSucceed
			else
				str = v.unionAlive and gLanguageCsv.crossUnionUnionBattleFailure or gLanguageCsv.crossUnionBattleFailure
			end
			node:get("upItem.title"):text(str)
			node:get("upItem.time"):hide()
			node:get("upItem"):y(node:get("upItem"):height()/2)
			itemHeight = node:get("upItem"):height()
		else
			node:get("itemAnima"):show()
			node:get("itemAnima"):y(node:get("itemAnima"):height()/2 - 80)
			local anima = widget.addAnimation(node:get("itemAnima"), "cross_union/dazuozhan.skel", "ruchang", 25)
			anima:xy(900, 44)
			anima:scale(2)
			anima:setSpriteEventHandler(function(event, eventArgs)
				anima:play("zhandou_loop")
			end, sp.EventType.ANIMATION_COMPLETE)
			node:get("itemAnima"):height(270)
			itemHeight = node:get("itemAnima"):height()+100
		end

	elseif v.roundTime then --当前轮次战斗倒计时
		if v.numRoundBattle then --第几轮战报
			node:get("itmeTime"):show()
			node:get("itmeTime"):text(string.format(gLanguageCsv.roundBattle, v.round))
			node:get("itmeTime"):y(node:get("itmeTime"):height()/2)
			itemHeight = node:get("itmeTime"):height()
		else
			--下个轮次的战报倒计时
			node:get("round"):show()
			node:get("round.round"):text(string.format(gLanguageCsv.roundBattle, v.round))
			node:get("round.over"):text(gLanguageCsv.afterFinish)
			adapt.oneLinePos(node:get("round.round"), {node:get("round.time"), node:get("round.over")}, cc.p(10, 0), "left")
			node:get("round"):y(node:get("round"):height()/2)
			itemHeight = node:get("round"):height()
		end

	else
		-- 由于是单个数据给过来的，单次判断左右两个是不是本公会的，是且在右边置换结果
		node:get("panel"):show()
		node:get("panel"):y(node:get("panel"):height()/2)
		itemHeight = node:get("panel"):height() - 10
		local rounds = v.round
		local roles = self.roles.oldval
		local function setResultPanel(panel, battle, direction, bg, result)
			local paneltNode = panel:multiget("roleIcon", "level", "name", "unionName", "team", "hpText", "hpBar", "win")
			local info = roles[battle.role_db_id] or battle
			bind.extend(self, paneltNode.roleIcon, {
				event = "extend",
				class = "role_logo",
				props = {
					logoId = info.role_logo or 1,
					frameId = info.role_frame or 1,
					vip = false,
					level = false,
				}
			})

			paneltNode.roleIcon:scale(0.85)
			paneltNode.level:text(info.role_level)
			text.addEffect(paneltNode.level, {outline = {color = ui.COLORS.NORMAL.DEFAULT, size = 4}})
			paneltNode.name:text(info.role_name)
			paneltNode.unionName:text(battle.union_name)
			paneltNode.win:show()
			paneltNode.team:text(string.format(gLanguageCsv.unionFightTeam, battle.troop))
			local hp = CrossUnionFightTools.WhetherLive(battle.troop_card_state)
			hp = hp * 100
			local str
			if (result == "win" and direction == "left") or (result == "fail" and direction == "right") then
				if result == "fail" then
					bg:texture("city/union/cross_unionfight/panel_bldzz_05.png")
				end
				paneltNode.win:texture("city/pvp/craft/icon_win.png")
				str = string.format(gLanguageCsv.unionFightHpText, hp.."%")
			else
				str = gLanguageCsv.unionFightDead
			end

			paneltNode.hpText:text(str)
			adapt.oneLinePos(paneltNode.team, paneltNode.hpText, cc.p(1, 0), direction)
			paneltNode.hpBar:setPercent(hp)
		end

		local left = v.left
		local right = v.right
		local result = v.result
		-- 发现本公会在右，置换本公会
		if v.right.union_db_id == unionId then
			left = v.right
			right = v.left
			result = v.result == "win" and "fail" or "win"
		end
		node:get("panel.centerJs"):show()
		if left.role_db_id then
			setResultPanel(node:get("panel.left"), left, "left", node:get("panel.bg"), result)
		else
			node:get("panel.bg"):texture("city/union/cross_unionfight/panel_bldzz_05")
			node:get("panel.left"):hide()
			node:get("panel.leftInexistence"):show()
			node:get("panel.leftInexistence.title"):text(gLanguageCsv.curRoundNoEnemy)
			node:get("panel.centerJs"):hide()
		end

		if right.role_db_id then
			setResultPanel(node:get("panel.right"), right, "right", node:get("panel.bg"), result)
		else
			node:get("panel.right"):hide()
			node:get("panel.rightInexistence"):show()
			node:get("panel.rightInexistence.title"):text(gLanguageCsv.curRoundNoEnemy)
			node:get("panel.centerJs"):hide()
		end

		if not (left.role_db_id and right.role_db_id) then
			node:get("panel.left.win"):hide()
			node:get("panel.right.win"):hide()
		end

		bind.touch(list, node:get("panel.centerJs"), {methods = {ended = function()
			self:battleReport(list, node, v)
		end}})
	end
	local CrossUnionMainView = require "app.views.city.union.cross_unionfight.view"
	node:size(1837, itemHeight)
	-- self:unSchedule(tag)
	self:enableSchedule()
	-- self:unSchedule(tag)
	local roundStatus = {
		["countDown"] = function()
			--开赛倒计时
			node:get("upItem.time"):show()
			text.addEffect(node:get("upItem.time"), {outline = {color = cc.c4b(139, 119, 84, 255)}})
			local delta = CrossUnionMainView:countDown(mainRound)
			node:get("upItem.time"):text(time.getCutDown(delta).min_sec_clock)
			self:schedule(function()
				local delta = CrossUnionMainView:countDown(mainRound)
				if delta <= 0 then
					return
				end
				if node and node:get("upItem") then
					node:get("upItem.time"):text(time.getCutDown(delta).min_sec_clock)
				end
			end, 1, 0, tag)
			return
		end,
		["roundCountDown"] = function()
			--轮次倒计时
			local delta = self.model.countDown
			node:get("round.time"):text(time.getCutDown(delta).min_sec_clock)
			self:schedule(function()
				local delta = self.model.countDown
				if delta <= 0 or not node then
					return
				end
				if node and node:get("round") then
					node:get("round.time"):text(time.getCutDown(delta).min_sec_clock)
					adapt.oneLinePos(node:get("round.round"), {node:get("round.time"), node:get("round.over")}, cc.p(10, 0), "left")
				end
			end, 1, 0, tag)
			return
		end
	}

	local listSize = list:size()
	local listX, listY = list:xy()
	local size = self.slider:size()
	self.slider:x(listX + listSize.width - size.width)
	local x, y = self.slider:xy()
	self.slider:show()
	list:setScrollBarEnabled(true)
	list:setScrollBarColor(cc.c3b(241, 59, 84))
	list:setScrollBarOpacity(255)
	list:setScrollBarAutoHideEnabled(false)
	list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x, (listSize.height - size.height) / 2 + 5))
	list:setScrollBarWidth(size.width)
	list:refreshView()

	if not playback then
		if roundStatus[v.roundTime] then
			roundStatus[v.roundTime]()
			return
		end
	end
end

local oneDay = 24 * 3600
local nineClock = 21 * 3600
local eightFifty = 3600 * (8 + 50 / 60)
local statusTime = {
	start = eightFifty + oneDay,
	prePrepare = eightFifty + 12 * 3600 + oneDay,
	preStart = nineClock + 0.5 * 3600 + oneDay,
	preBattle = nineClock + 0.5 * 3600 + oneDay,
	preOver = nineClock + 0.5 * 3600 + oneDay,
	preAward = nineClock - 12 * 3600 + oneDay * 3,
	topPrepare = eightFifty + 12 * 3600 + oneDay * 3,
	topStart = nineClock + 0.5 * 3600 + oneDay * 3,
	topBattle = nineClock + 0.5 * 3600 + oneDay * 3,
	topOver = nineClock + 0.5 * 3600 + oneDay * 3

}
function CrossUnionFightTools.getNextStateTime(status, startDate)
	local now = time.getTime()
	local getToday = time.getNumTimestamp(startDate)
	return getToday + (statusTime[status] or 0) - now
end

function CrossUnionFightTools.getDistribute(data, userId, types)
	for i, v in pairs(data) do
		if i == userId then
			return v.projects[types]
		end
	end
end

return CrossUnionFightTools