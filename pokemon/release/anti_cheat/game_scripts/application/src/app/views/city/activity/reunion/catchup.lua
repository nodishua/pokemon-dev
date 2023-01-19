-- @date 2020-8-31
-- @desc 训练家重聚 进度赶超

-- 活动加成类型(1天数;2次数)
local STATE_TYPE = {
	days = 1,
	times = 2,
}

--显示状态 (1前往，2已完成)
local STATE_TYPE_SHOW = {
	goJump = 1,
	finished = 2,
}

local ReunionCatchUpView = class("ReunionCatchUpView", cc.load("mvc").ViewBase)

ReunionCatchUpView.RESOURCE_FILENAME = "reunion_catch.json"
ReunionCatchUpView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				dataOrderCmp = function(a, b)
					return a.csvId < b.csvId
				end,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("list", "title", "label1", "time", "bodyList", "remarkList", "goPanel", "completed")

					childs.completed:visible(v.state == STATE_TYPE_SHOW.finished)
					childs.goPanel:visible(v.state == STATE_TYPE_SHOW.goJump)
					if cfg.goto == "" then
						childs.goPanel:visible(false)
					end
					bind.touch(list, childs.goPanel, {methods = {ended = functools.partial(list.clickCell, cfg.goto)}})

					childs.title:text(cfg.title)
					if cfg.addType == STATE_TYPE.days then
						childs.label1:text(gLanguageCsv.reunionCatchUpCutdown)
						local countdown = time.getNumTimestamp(v.finishTimes, time.getRefreshHour()) - time.getTime()
						ReunionCatchUpView.setCountdown(list, countdown, childs.time, childs.completed, childs.goPanel, {tag = k, v = v})
					elseif cfg.addType == STATE_TYPE.times then
						childs.label1:text(gLanguageCsv.reunionCatchUpTimes)
						childs.time:text(string.format(gLanguageCsv.reunionCatchUpText, cfg.addNum, v.finishTimes))
					end

					beauty.textScroll({
						list = childs.bodyList,
						strs = cfg.desc,
						fontSize = 36,
					})

					beauty.textScroll({
						list = childs.remarkList,
						strs = '#C0xFF5B545B#' .. cfg.remark,
						isRich = true,
						verticalSpace = 10,
						fontSize = 36,
					})

				end,
				asyncPreload = 3,
			},
			handlers = {
				clickCell = bindHelper.self("onJumpTo"),
			},
		},
	},
}

function ReunionCatchUpView:onCreate(yyID)
	local cfg = csv.yunying.yyhuodong[yyID]
	self:initModel()

	self.datas = idlers.new()
	idlereasy.when(self.reunion, function(_, reunion)
		local catchup = reunion.catchup or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.reunion_catchup) do
			if v.huodongID == cfg.huodongID then
				local state = STATE_TYPE_SHOW.goJump
				local finishTimes = 0
				if v.addType == STATE_TYPE.times and catchup[k] then
					if catchup[k] >= v.addNum then
						state = STATE_TYPE_SHOW.finished
					end
					finishTimes = catchup[k]
				elseif v.addType == STATE_TYPE.days then
					local endTime = tonumber(self:getStrInClock(math.floor(reunion.info.reunion_time))) + v.addNum
					local curTime = tonumber(time.getTodayStrInClock())
					if endTime <= curTime then
						state = STATE_TYPE_SHOW.finished
					end
					finishTimes = endTime
				end
				table.insert(datas, {csvId = k, cfg = v, state = state, finishTimes = finishTimes})
			end
		end
		self.datas:update(datas)
	end)
end

function ReunionCatchUpView:getStrInClock(timestamp) -- str 20150612
	local T = timestamp and time.getDate(timestamp) or time.getTimeTable()
	local freshHour = time.getRefreshHour()
	local freshMin = 0
	if T.hour * 100 + T.min < freshHour * 100 + freshMin then
		local t = timestamp - 24*3600
		T = time.getDate(t)
	end
	return string.format("%04d%02d%02d",T.year,T.month,T.day)
end

function ReunionCatchUpView:initModel()
	self.reunion = gGameModel.role:getIdler("reunion")
end

function ReunionCatchUpView:onJumpTo(list, goto)
	if goto ~= "" then
		jumpEasy.jumpTo(goto)
	end
end

-- @param params: {tag, labelChangeCb}
function ReunionCatchUpView.setCountdown(view, countdown, uiTime, completed, goPanel, params)
	params = params or {}
	local tag = params.tag or 1
	view:enableSchedule():unSchedule(tag)
	countdown = countdown > 0 and countdown or 0

	bind.extend(view, uiTime, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = tag,
			strFunc = function(t)
				return t.str
			end,
			callFunc = function()
			end,
			endFunc = function()

				countdown = params.v.finishTimes +  params.v.cfg.addNum * 86400 - time.getTime()
				if countdown > 0 then
					performWithDelay(view, function()
						ReunionCatchUpView.setCountdown(view, countdown, uiTime, completed, goPanel, params)
					end, 1)
				else
					uiTime:text(gLanguageCsv.activityOver)
					completed:visible(true)
					goPanel:visible(false)
				end
			end,
			onNode = function(node)
			end
		}
	})
end

return ReunionCatchUpView