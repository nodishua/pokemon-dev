local gridWalkTools = {}

local BOTTOM_WIDTH = 322
local LEFT_WIDTH = 380
-- 人物移动事件间隔
gridWalkTools.MOVE_TIME = 0.6

gridWalkTools.HISTORY_MAX = 6
-- 徽章ID
gridWalkTools.BADGE_ID = 8102

-- 地图位置，对应行列数
gridWalkTools.MAP = {
	{1,9},{2,9},{3,9},{4,9},{4,10},{4,11},{5,11},{6,11},{7,11},{8,11},{9,11},{10,11},{11,11},
	{12,11},{12,10},{12,9},{12,8},{11,8},{10,8},{9,8},{9,7},{9,6},{9,5},{10,5},{11,5},{12,5},{12,4},{12,3},
	{12,2},{11,2},{10,2},{9,2},{9,1},{8,1},{7,1},{6,1},{5,1},{4,1},{3,1},{2,1},
	{1,1},{1,2},{1,3},{2,3},{3,3},{4,3},{4,4},{4,5},{3,5},{2,5},{1,5},{1,6},{1,7},{1,8}
}

-- 事件
gridWalkTools.EVENTS = {
	goodLuck = 1,  -- 转盘
	badLuck = 2,  -- 厄运卡
	increase = 3,  -- +活动币
	reduce = 4,  -- -活动币
	jump = 5,  -- 飞跃格
	shop = 6,  -- 小店
	treasures = 99,  -- 宝藏点
}
-- 道具
gridWalkTools.ITEMS = {
	voucher = 8111,  -- 代金券
	normanlDice = 8112,  -- 普通的色子
	strangeDice = 8113,  -- 奇怪的色子
	medalDice = 8114,  -- 勋章色子
	sprintCard = 8115,  -- 冲刺卡
	randomCard = 8116,  -- 随意门
	steeringCard = 8117,  -- 转向卡
}

-- 骰子ID
gridWalkTools.DICE_ID = {
	gridWalkTools.ITEMS["normanlDice"],
	gridWalkTools.ITEMS["strangeDice"],
	gridWalkTools.ITEMS["medalDice"],
}

-- 道具卡
gridWalkTools.CARD_ID = {
	gridWalkTools.ITEMS["sprintCard"],
	gridWalkTools.ITEMS["randomCard"],
	gridWalkTools.ITEMS["steeringCard"],
}

-- 道具背包
gridWalkTools.CARDSBAG_ID = {
	gridWalkTools.ITEMS["sprintCard"],
	gridWalkTools.ITEMS["randomCard"],
	gridWalkTools.ITEMS["steeringCard"],
	gridWalkTools.ITEMS["voucher"],
}

function gridWalkTools.getCfgByIndexFromMap(index, huodongID)
	for k, cfg in csvPairs(csv.yunying.grid_walk_map) do
		if index == cfg.index and huodongID == cfg.huodongID then
			return cfg, k
		end
	end
end

function gridWalkTools.getCfgByEventFromEvents(event, huodongID)
	for k, cfg in csvPairs(csv.yunying.grid_walk_events) do
		if event == cfg.type and huodongID == cfg.huodongID then
			return cfg, k
		end
	end
end

function gridWalkTools.getMapPos(size)
	local arr = {}
	for k, pos in ipairs(gridWalkTools.MAP) do
		local x = LEFT_WIDTH + pos[1] * size.width - size.width/2
		local y = BOTTOM_WIDTH + pos[2] * size.height - size.height/2
		table.insert(arr, {x, y})
	end
	return arr
end

-- 根据是否反向获取当前格子的朝向
function gridWalkTools.getNextTowardsUp(index, nowTowardsUp)
	local nowPos = gridWalkTools.MAP[index]
	local num = index + 1 > 54 and index + 1 - 54 or index + 1
	if nowTowardsUp == -1 then
		num = index - 1 < 1 and index - 1 + 54 or index - 1
	end
	local nextPox = gridWalkTools.MAP[num]
	return {nextPox[1] - nowPos[1], nextPox[2] - nowPos[2]}
end

-- 获取默认朝向 当前位置和下个不同X坐标比较
function gridWalkTools.getTowardsUp(index, nowTowardsUp)
	local nowPos = gridWalkTools.MAP[index]
	if nowTowardsUp == 1 then
		for i=index+1, math.huge do
			local num = i > 54 and i-54 or i
			local nextPox = gridWalkTools.MAP[num]
			if nowPos[1] ~= nextPox[1] then
				return nextPox[1] > nowPos[1] and 1 or -1
			end
		end
	else
		for i=index-1, -54, -1 do
			local num = i < 1 and i+54 or i
			local nextPox = gridWalkTools.MAP[num]
			if nowPos[1] ~= nextPox[1] then
				return nextPox[1] > nowPos[1] and 1 or -1
			end
		end
	end
end

-- 根据前后格子位置，获取在格子外展示的道具的坐标
function gridWalkTools.getOutPosByIndex(index)
	local nowPos = gridWalkTools.MAP[index]
	local beforeIndex = index - 1 < 1 and 54 or index - 1
	local beforePos = gridWalkTools.MAP[beforeIndex]
	local nextIndex = index + 1 > 54  and 1 or index + 1
	local nextPos = gridWalkTools.MAP[nextIndex]
	-- print("beforePos:", beforeIndex, beforePos[1], beforePos[2])
	-- print("nowPos:", index, nowPos[1], nowPos[2])
	-- print("nextPos:", nextIndex, nextPos[1], nextPos[2])
	-- 判断前后的格子，前后格子y不变，则放上下；x不变，则放左右
	if nowPos[1] == beforePos[1] and nowPos[1] == nextPos[1] then
		if nowPos[1] > 6 then
			return {-1, 0}
		else
			return {1, 0}
		end
	elseif nowPos[2] == beforePos[2] and nowPos[2] == nextPos[2] then
		-- y一致的，暂定都放上面
		-- if nowPos[2] > 5 then
		-- 	return {0, -1}
		-- else
			return {0, 1}
		-- end
	elseif beforePos[2] > nowPos[2] or nextPos[2] > nowPos[2] then
		return {0, -1}
	elseif beforePos[2] < nowPos[2] or nextPos[2] < nowPos[2] then
		return {0, 1}
	elseif beforePos[1] > nowPos[1] or nextPos[1] > nowPos[1] then
		return {-1, 0}
	elseif beforePos[1] < nowPos[1] or nextPos[1] < nowPos[1] then
		return {1, 0}
	end
end

function gridWalkTools.getLabelFromEvent(event, lastEvent)
	local str = ""
	local csvId = event.csv_id
	if csvId == 0 then
		-- 空格子
		return gLanguageCsv.gridWalkHistory0
	else
		local isEvent = event.is_event
		if isEvent then
			-- 事件
			local eventCfg = csv.yunying.grid_walk_events[csvId]
			local params = eventCfg.params
			if eventCfg.type == gridWalkTools.EVENTS.goodLuck then
				-- 转盘
				local award = params.items[event.params.outcome + 1]
				local icon = dataEasy.getCfgByKey(award[1])
				return string.format(gLanguageCsv.gridWalkHistory1, icon.name, award[2])
			elseif eventCfg.type == gridWalkTools.EVENTS.badLuck then
				-- 厄运卡
				local award = params.items[event.params.outcome + 1]
				local icon = dataEasy.getCfgByKey(award[1])
				return string.format(gLanguageCsv.gridWalkHistory2, award[2], icon.name)
			elseif eventCfg.type == gridWalkTools.EVENTS.increase then
				-- +活动币
				return string.format(gLanguageCsv.gridWalkHistory3, params.num, params.num)
			elseif eventCfg.type == gridWalkTools.EVENTS.reduce then
				-- -活动币
				return string.format(gLanguageCsv.gridWalkHistory4, params.num, params.num)
			elseif eventCfg.type == gridWalkTools.EVENTS.jump then
				-- 飞跃格
				return string.format(gLanguageCsv.gridWalkHistory5, params.num)
			elseif eventCfg.type == gridWalkTools.EVENTS.shop then
				-- 小店
				if event.params.bought and event.params.bought > 0 then
					return gLanguageCsv.gridWalkHistory61
				else
					return gLanguageCsv.gridWalkHistory62
				end
			elseif eventCfg.type == gridWalkTools.EVENTS.treasures then
				-- 宝藏点
				return gLanguageCsv.gridWalkHistory99
			end
		else
			if csvId == gridWalkTools.ITEMS.normanlDice or csvId == gridWalkTools.ITEMS.strangeDice or csvId == gridWalkTools.ITEMS.medalDice then
				local count = event.params.outcome
				if lastEvent and lastEvent.csv_id == gridWalkTools.ITEMS.sprintCard then
					local printCardCfg = dataEasy.getCfgByKey(gridWalkTools.ITEMS.sprintCard)
					count = count + printCardCfg.specialArgsMap.steps
				end
				return string.format(gLanguageCsv.gridWalkHistory8, dataEasy.getCfgByKey(csvId).name, count)
			else
				-- 道具
				return string.format(gLanguageCsv.gridWalkHistory7, dataEasy.getCfgByKey(csvId).name)
			end
		end
	end
	return str
end

return gridWalkTools