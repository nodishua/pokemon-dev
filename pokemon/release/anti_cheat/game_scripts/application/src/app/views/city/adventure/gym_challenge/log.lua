--道馆日志
local ViewBase = cc.load("mvc").ViewBase
local GymLog = class("GymLog", ViewBase)

local onelineHeight = 46
local fontSize = 40
local itemHeight = 80

local LOG_TYPE = {
	["gymReset"] = 1,
 	["gymClosed"]= 19,
}

local LOG_LANGUGE = {
	[1]	= "gymReset",
	[2]	= "gymFubenPass",
	[3]	= "gymAllPass",
	[4]	= "gymOccupy",
	[5]	= "gymLeaderWin",
	[6]	= "gymLeaderFail",
	[7]	= "crossGymLeaderOccupy",
	[8]	= "crossGymOccupy",
	[9]	= "crossGymLeaderWin",
	[10] = "crossGymWin",
	[11] = "crossGymLeaderFail",
	[12] = "crossGymFail",
	[13] = "gymLeaderDefenceWin",
	[14] = "gymLeaderDefenceFail",
	[15] = "crossGymLeaderDefenceWin",
	[16] = "crossGymLeaderDefenceFail",
	[17] = "crossGymDefenceWin",
	[18] = "crossGymDefenceFail",
	[19] = "gymClosed",
	[20] = "gymGarrison1",
	[20] = "gymGarrison2",
	[21] = "gymPassGate1",
	[21] = "gymPassGate2",
}

GymLog.RESOURCE_FILENAME = "gym_log.json"
GymLog.RESOURCE_BINDING = {
	["item"] = "item",
	["recordList"] = {
		varname = "recordList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("logDatas"),
				item = bindHelper.self("item"),
				time = bindHelper.self("lastTime"),
				preloadCenterIndex = bindHelper.self("preloadCenterIndex"),
				itemAction = {isAction = true},
				preloadBottom = bindHelper.self("preloadBottom"),
				onItem = function(list, node, k, v)
					local height = itemHeight
					local timeStamps = v.time
					local hour, min = time.getHourAndMin(v.time)
					local t = time.getDate(v.time)
					node:get("textTime"):text(string.format("[%02d:%02d]", t.hour, t.min))
					local str = ""
					local urlData = {}
					if LOG_LANGUGE[v.type] == "gymClosed" then
						if v.pass_num > 0 then
							str = gLanguageCsv[LOG_LANGUGE[v.type]] .."\n".. string.format(gLanguageCsv.gymPassGate1, v.pass_num)
						else
							str = gLanguageCsv[LOG_LANGUGE[v.type]] .."\n".. string.format(gLanguageCsv.gymPassGate2, v.pass_num)
						end
						if v.leader_gym_id then
							local name = csv.gym.gym[v.leader_gym_id].name
							local color = csv.gym.gym[v.leader_gym_id].fontColor
							str = str .."\n" .. string.format(gLanguageCsv.gymGarrison1, color..name.."#C0x5B545B#", "#T44-0.8#")
						end
						if v.cross_leader_gym_id then
							local name = csv.gym.gym[v.cross_leader_gym_id].name
							local color = csv.gym.gym[v.cross_leader_gym_id].fontColor
							str = str .."\n"..string.format(gLanguageCsv.gymGarrison1, color..gLanguageCsv.crossServer..name.."#C0x5B545B#", "#T45-0.8#")
						end
						if v.cross_gym_id then
							local name = csv.gym.gym[v.cross_gym_id].name
							local color = csv.gym.gym[v.cross_gym_id].fontColor
							str = str .."\n"..string.format(gLanguageCsv.gymGarrison2, color..gLanguageCsv.crossServer..name.."#C0x5B545B#", "#T45-0.8#")
						end
					elseif v.gym_id then
						local color = csv.gym.gym[v.gym_id].fontColor
						local name = csv.gym.gym[v.gym_id].name
						if string.find(LOG_LANGUGE[v.type], "cross") then
							str = string.format(gLanguageCsv[LOG_LANGUGE[v.type]], color..gLanguageCsv.crossServer..name.."#C0x5B545B#")
						else
							str = string.format(gLanguageCsv[LOG_LANGUGE[v.type]], color..name.."#C0x5B545B#")
						end
						str = string.format(str, color..name.."#C0x5B545B#")
						if v.gym_battle_history then
							str = str .. "#LULgymLog##Icommon/btn/img_ckxq.png-182-54#"
							urlData = v.gym_battle_history
						end
					else
						str = gLanguageCsv[LOG_LANGUGE[v.type]]
					end
					local richText = rich.createWithWidth(str, 40, nil, 2000, 34)
						:addTo(node, 10, "text")
						:anchorPoint(cc.p(0, 1))
						:xy(cc.p(330,40))
						:formatText()
					uiEasy.setUrlHandler(richText, urlData)

					local textHeight = richText:height()
					height = height - onelineHeight + richText:height()
					richText:xy(330, (itemHeight - onelineHeight)/2 + textHeight)
					node:get("textTime"):y((itemHeight - onelineHeight)/2 + textHeight - onelineHeight/2)
					if v.showDate then
						node:get("textDate"):text(t.month.."."..t.day)
						node:get("imgSlider1"):show()
						height = height + 100
						node:get("textDate"):y(height - 100/2)
						node:get("imgSlider1"):y(height - 100/2)

					else
						node:get("textDate"):hide()
						node:get("imgSlider1"):hide()
					end
					if v.showTitle then
						node:get("imgWeek"):y(height + 10)
						height = height + 60
						node:get("imgWeek"):show()
						if v.weekType == 1 then
							node:get("imgWeek.textNote"):text(gLanguageCsv.lastWeek)
						else
							node:get("imgWeek.textNote"):text(gLanguageCsv.thisWeek)
						end
					end
					node:height(height)
					node:get("imgSlider2"):height(height)

					if list.time < timeStamps and k > #list.data - 5 then
						node:get("imgNew"):y((itemHeight - onelineHeight)/2 + textHeight - onelineHeight/2)
							:show()
					end
				end,
			},
			handlers = {
				detailClick = bindHelper.self("onDetailClick"),
			},
		},
	},
}

function GymLog:onCreate()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.gymLogs, subTitle = "CHALLENGE LOG"})
	self:initData()
	self.lastTime = userDefault.getForeverLocalKey("gymLogOpenTime", 0)
	if self.preloadCenterIndex then
		dataEasy.tryCallFunc(self.recordList, "updatePreloadCenterIndex")
	else
		self.preloadBottom = true
	end
end

function GymLog:onCleanup()
	local currentItem = self.recordList:getCenterItemInCurrentView()
	if currentItem then
		self.preloadCenterIndex = self.recordList:getIndex(currentItem) + 1
	end
	self.preloadBottom = nil
	ViewBase.onCleanup(self)
end

function GymLog:initData( )
	local modelRecord = gGameModel.gym:read("record")
	local lastLogs = modelRecord.last_logs or {}
	local curLogs = modelRecord.logs or {}
	local closeInfo = modelRecord.gym_close_info or {}
	local lastCloseInfo = modelRecord.last_gym_close_info or {}
	local logs = {}
	for i, log in pairs(lastLogs) do
		local log = table.shallowcopy(log)
		log.weekType = 1
		table.insert(logs, log)
	end

	for i, log in pairs(curLogs) do
		local log = table.shallowcopy(log)
		log.weekType = 2
		table.insert(logs, table.shallowcopy(log))
	end

	--添加重置日志
	local refreshDayTime = time.getNumTimestamp(time.getWeekStrInClock(5))
	local timeReset1 = refreshDayTime + 5 * 3600 - 7 * 24 * 3600
	table.insert(logs, {time = timeReset1, type = LOG_TYPE.gymReset, weekType = 1, showTitle = true})

	local timeReset2 = refreshDayTime + 5 * 3600
	table.insert(logs, {time = timeReset2, type = LOG_TYPE.gymReset, weekType = 2, showTitle = true})

	-- 添加结束日志 21:45
	local time1 = refreshDayTime - 2 * 3600 - 15 * 60
	if time.getTime() > time1 then
		table.insert(logs,
		{
			time = time1,
			type = LOG_TYPE.gymClosed,
			weekType = 1,
			pass_num = lastCloseInfo.pass_num or 0,
			leader_gym_id = lastCloseInfo.leader_gym_id,
			cross_leader_gym_id = lastCloseInfo.cross_leader_gym_id,
			cross_gym_id = lastCloseInfo.cross_gym_id,
		})
	end

	local time1 = refreshDayTime + 7 * 24 * 3600 - 2 * 3600 - 15 * 60
	if time.getTime() > time1 then
		table.insert(logs,
		{
			time = time1,
			type = LOG_TYPE.gymClosed,
			weekType = 2,
			pass_num = closeInfo.pass_num or 0,
			leader_gym_id = closeInfo.leader_gym_id,
			cross_leader_gym_id = closeInfo.cross_leader_gym_id,
			cross_gym_id = closeInfo.cross_gym_id,
		})
	end
	table.sort(logs, function(a, b)
		if a.time == b.time then
			return a.type < b.type
		else
			return a.time < b.time
		end
	end)

	for k, v in ipairs(logs) do
		if k == 1 then
			v.showDate = true
		elseif time.getDate(v.time).yday ~= time.getDate(logs[k-1].time).yday then
			v.showDate = true
		else
			v.showDate = false
		end
	end
	self.logDatas = idlers.newWithMap(logs)
end

return GymLog
