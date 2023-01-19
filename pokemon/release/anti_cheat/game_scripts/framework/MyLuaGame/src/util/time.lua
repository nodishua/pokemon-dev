--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- time相关
--

local format = string.format
local floor = math.floor

local time = {}
globals.time = time

time.SERVER_TIMEKEY = "dayTime"

-- 根据时间戳，获取对应服务器时区时间的table
function time.getDate(timestamp)
	return os.date('!*t', timestamp + UNIVERSAL_TIMEDELTA)
end

-- 获取当前服务器时区时间的table
function time.getNowDate()
	return os.date('!*t', time.getTime() + UNIVERSAL_TIMEDELTA)
end

-- 根据服务器时间时区，delta是时间偏移，获取相应时间的table
function time.getDeltaDate(delta)
	return os.date('!*t', time.getTime() + delta + UNIVERSAL_TIMEDELTA)
end

-- 根据服务器时间的table，获取时间戳
function time.getTimestamp(t)
	t.isdst = false -- 一个布尔值，false 表示无夏令时, nil 会自动区分是否有夏令时
	local lt = os.time(t)
	if lt == nil then
		local str = {}
		for k, v in pairs(t or {}) do
			table.insert(str, tostring(k))
			table.insert(str, tostring(v))
		end
		local msg = table.concat(str, "|")
		printInfo("time.getTimestamp lt is nil: %s", msg)
		handleLuaException(msg)
		lt = 2e9
	end

	-- 不使用手机设置的时区
	local now = os.time()
	local ldelta = os.difftime(now, os.time(os.date("!*t", now)))
	return lt - UNIVERSAL_TIMEDELTA + ldelta
end

-- 根据服务器时间，获得对应格式的值
function time.getFormatValue(format, delta)
	delta = delta or 0
	return tonumber(os.date('!' .. format, time.getTime() + delta + UNIVERSAL_TIMEDELTA))
end

--time.dayTime = {flag=1,baseTime=0,isLoop=false} --游戏的day时间
--flag 1:正计时; 2:倒计时 . baseTime:基准时间 . isLoop:是否循环，一般用于倒计时
--倒计时的话 比如5分钟,现在还剩4分钟,basetime=4*60; recordTime=5*60
function time.registerTime(key,flag,baseTime,isLoop,recordTime)
	time[key] = {}
	time[key].flag = flag
	if flag == 1 then
		time[key].baseTime = baseTime - os.time()
	elseif flag == 2 then
		time[key].baseTime = baseTime + os.time()
		time[key].isLoop = isLoop
		if isLoop then
			time[key].record = recordTime --多少时间循环一次
		end
	end
end

--返回os.date,返回0表示倒计时结束
function time.getTimeTable(key,_noupdate)
	key = key or time.SERVER_TIMEKEY
	local info = time[key]
	if info == nil then return nil end
	local curTime = os.time()
	if info.flag == 1 then
		local fixTime = floor(info.baseTime + curTime)
		return time.getDate(fixTime)
	elseif info.flag == 2 then
		local fixTime = floor(info.baseTime - curTime)
		if fixTime <= 0 then
			if info.isLoop and _noupdate == nil then
				info.baseTime = info.baseTime + info.record
			end
			return 0
		else
			return {hour=floor(fixTime/3600),min=floor((fixTime%3600)/60),sec=time%60}
		end
	end
end

--返回没处理过的时间
function time.getTime(key)
	key = key or time.SERVER_TIMEKEY
	local info = time[key]
	if info == nil then return nil end
	local curTime = os.time()
	if info.flag == 1 then
		return floor(info.baseTime + curTime)
	elseif info.flag == 2 then
		return floor(info.baseTime - curTime)
	end
end

-- 自然日
function time.getTodayStr() --20150612
	local T = time.getTimeTable()
	return format("%04d%02d%02d",T.year,T.month,T.day)
end

-- 获取下次默认5点刷新时间
function time.getNextdayStrInClock(freshHour, freshMin)
	freshHour = freshHour or time.getRefreshHour()
	freshMin = freshMin or 0
	local T = time.getTimeTable()
	if T.hour * 100 + T.min > freshHour * 100 + freshMin then
		local t = time.getTimestamp(T) + 24*3600
		T = time.getDate(t)
	end
	return format("%04d%02d%02d",T.year,T.month,T.day)
end

-- 默认5点刷新时间
function time.getTodayStrInClock(freshHour, freshMin) -- str 20150612
	freshHour = freshHour or time.getRefreshHour()
	freshMin = freshMin or 0
	local T = time.getTimeTable()
	if T.hour * 100 + T.min < freshHour * 100 + freshMin then
		local t = time.getTimestamp(T) - 24*3600
		T = time.getDate(t)
	end
	return format("%04d%02d%02d",T.year,T.month,T.day)
end

-- 默认5点刷新时间, 获取周一的日期
function time.getWeekStrInClock(freshHour, freshMin) -- str 20150612
	freshHour = freshHour or time.getRefreshHour()
	freshMin = freshMin or 0
	local T = time.getTimeTable()
	if T.hour * 100 + T.min < freshHour * 100 + freshMin then
		local t = time.getTimestamp(T) - 24*3600
		T = time.getDate(t)
	end
	local wday = T.wday == 1 and 7 or T.wday - 1 -- Sunday is 1
	local t = time.getTimestamp(T) - 24*3600*(wday-1)
	T = time.getDate(t)
	return format("%04d%02d%02d",T.year,T.month,T.day)
end

-- 默认5点刷新时间, 获取1号的日期
function time.getMonthStrInClock(freshHour, freshMin) -- str 20150612
	local str = time.getTodayStrInClock(freshHour, freshMin)
	return string.sub(str, 1, 6) .. "01"
end

--获取倒计时
--@Param type 1 ret:hour:min:sec
function time.getCutDown(timeNum, noNegative, ignoreSec)
	-- 负数视为0处理
	if noNegative then
		timeNum = timeNum > 0 and timeNum or 0
	end

	local day,hour,min,sec
	day = floor(timeNum / 86400)
	hour = floor((timeNum % 86400 ) / 3600)
	min = floor((timeNum % 3600 ) / 60)
	sec = floor(timeNum % 60)

	local str = format("%02d:%02d:%02d", hour, min, sec)
	if day >= 1 then
		str = format(gLanguageCsv.day .. " %s", day, str)
	end
	local ret = {day = day, hour = hour, min = min, sec = sec, str = str}

	-- 时钟str 只显示hour-min-sec
	ret.clock_str = format("%02d:%02d:%02d", hour, min, sec)
	-- 只显示分秒的时钟
	ret.min_sec_clock = format("%02d:%02d", min, sec)
	-- 短时钟 当hour为0时只显示min-sec
	ret.short_clock_str = hour > 0 and ret.clock_str or ret.min_sec_clock

	local daystr = format(gLanguageCsv.day, day)
	local hourstr = format(gLanguageCsv.hour, hour)
	local minstr = format(gLanguageCsv.minute, min)
	local secstr = format(gLanguageCsv.second, sec)
	ret.daystr = daystr
	ret.hourstr = hourstr
	ret.minstr = minstr
	ret.secstr = secstr
	-- 日期文本
	ret.date_str = ignoreSec and daystr..hourstr..minstr or daystr..hourstr..minstr..secstr

	-- short_date_str 短日期文本，当不足一天则没有天，以此类推
	-- head_date_str 头日期文本，只显示不为0的最大单位日期
	if day > 0 then
		ret.short_date_str = ret.date_str
		ret.head_date_str = daystr
	elseif hour > 0 then
		ret.short_date_str = ignoreSec and hourstr..minstr or hourstr..minstr..secstr
		ret.head_date_str = hourstr
	elseif min > 0 then
		ret.short_date_str = ignoreSec and minstr or minstr..secstr
		ret.head_date_str = minstr
	else
		ret.short_date_str = ignoreSec and minstr or secstr
		ret.head_date_str = ret.short_date_str
	end

	return ret
end

--获取活动开放日期,以前的不用修改，接口主要提供给以后活动
function time.getActivityOpenDate(activityID)
	local cfg = csv.yunying.yyhuodong[activityID]
	local date = ""
	if cfg.openType == 0 or cfg.openType == 1 or cfg.openType == 2 then
		local startHour = time.getHourAndMin(cfg.beginTime)
		local endHour = time.getHourAndMin(cfg.endTime)
		local _, startMonth, startDay = time.getYearMonthDay(cfg.beginDate)
		local _, endMonth, endDay = time.getYearMonthDay(cfg.endDate)
		date = string.formatex(gLanguageCsv.timeString, {month = startMonth, day = startDay, hour = startHour}).."-"
			.. string.formatex(gLanguageCsv.timeString, {month = endMonth, day = endDay, hour = endHour})
		return date, time.getNumTimestamp(cfg.beginDate, time.getHourAndMin(cfg.beginTime, true))

	elseif cfg.openType == 3 or cfg.openType == 4 then
		local endTime = gGameModel.role:read("yy_endtime")[activityID] or 0
		local startTime = endTime - (cfg.relativeDayRange[2] - cfg.relativeDayRange[1] + 1) * 24 * 3600
		if endTime > 0 and startTime > 0 then
			local date1 = time.getDate(startTime)
			local date2 = time.getDate(endTime)
			local startMonth = format("%02d",date1.month)
			local startDay = format("%02d",date1.day)
			local endMonth = format("%02d",date2.month)
			local endDay = format("%02d",date2.day)
			date = string.formatex(gLanguageCsv.timeString, {month = startMonth, day = startDay, hour = date1.hour}).."-"
				.. string.formatex(gLanguageCsv.timeString, {month = endMonth, day = endDay, hour = date2.hour})
			return date, startTime
		end
	end

	return date
end

--获取年月日 return string
function time.getYearMonthDay(timeStr, toInt)
	timeStr = tostring(timeStr)
	local year, month, day = string.sub(timeStr, 1, 4), string.sub(timeStr, 5, 6), string.sub(timeStr, 7, 8)
	if toInt then
		return tonumber(year), tonumber(month), tonumber(day)
	end
	return year, month, day
end

--获取小时分钟 return string
function time.getHourAndMin(timeStr, toInt)
	timeStr = tonumber(timeStr)
	local hour, min = floor(timeStr / 100), timeStr % 100
	if toInt then
		return hour, min
	end
	return format("%02d", hour) , format("%02d", min)
end

-- 将20150612数字转成时间戳
function time.getNumTimestamp(timeNum, hour, min, sec)
	local t = {
		year = floor(timeNum/10000),
		month = floor((timeNum%10000)/100),
		day = floor(timeNum%100),
		hour = tonumber(hour) or 0,
		min = tonumber(min) or 0,
		sec = tonumber(sec) or 0
	}
	return time.getTimestamp(t)
end

-- 获取key，比较时间，如 timeT = {hour = 1, min = 20}, freshTime = {hour = 5}, 返回 2520
function time.getCmpKey(timeT, freshTime)
	freshTime = freshTime or {}
	local freshHour = freshTime.hour or 0
	local freshMin = freshTime.min or 0
	local hour = timeT.hour or 0
	local min = timeT.min or 0
	local key = hour * 100 + min
	if key < freshHour * 100 + freshMin then
		return key + 24 * 100
	end
	return key
end

-- kr 特殊 0 点刷新
function time.getRefreshHour()
	return matchLanguage({"kr", "en"}) and 0 or 5
end