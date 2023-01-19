-- @date:   2019-07-08
-- @desc:   派遣任务-主界面
local dispatchtaskTools = require "app.views.city.adventure.dispatch_task.tools"
local QUALITY_IMG = {
	"common/icon/icon_rarity1.png",
	"common/icon/icon_rarity2.png",
	"common/icon/icon_rarity3.png",
	"common/icon/icon_rarity4.png",
	"common/icon/icon_rarity5.png"
}
local REFRESH_COST = gCommonConfigCsv.dispatchTaskRefreshCostRMB
local DONE_COST = gCommonConfigCsv.dispatchTaskDoneAtOnceCostRMB
local DONE_SECOND = gCommonConfigCsv.dispatchTaskDoneAtOnceSecond

local function getTimeStr(timeMin)
	local str = ""
	local t = time.getCutDown(timeMin*60)
	if t.day > 0 then
		str = str..string.format(gLanguageCsv.day, t.day)
	end
	if t.hour > 0 then
		str = str..string.format(gLanguageCsv.hour, t.hour)
	end
	if t.min > 0 then
		str = str..string.format(gLanguageCsv.minute, t.min)
	end
	return str
end
local function setCostTxt(panel, myCoin, needCoin, isFree, curRefreshTimes)
	local cost = panel:get("cost")
	if isFree then
		local freeNum = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DispatchTaskFreeRefreshTimes)
		needCoin = string.format("%s(%s/%s)", gLanguageCsv.free, freeNum - curRefreshTimes, freeNum)
	end
	cost:text(needCoin)
	local coinColor = ui.COLORS.NORMAL.WHITE
	if isFree then
		coinColor = ui.COLORS.NORMAL.FRIEND_GREEN
	elseif myCoin < needCoin then
		coinColor = ui.COLORS.NORMAL.RED
	end
	text.addEffect(cost, {color = coinColor})
	adapt.oneLinePos(panel:get("costIcon"), {cost, panel:get("costNote")}, cc.p(20, 0), "right")
	adapt.oneLinePos(panel:get("costNote"), {panel:get("taskNum"),panel:get("taskNumNote")}, {cc.p(80, 0),cc.p(5, 0)}, "right")

end
local function setSubTime(list, childs, v, k)
	local tmpTime = v.subTime
	list:enableSchedule():schedule(function ()
		tmpTime = tmpTime - 1
		if tmpTime <= 0 then
			if v.status == 3 then
				gGameApp:requestServer("/game/dispatch/task/refresh", nil, false)
				childs.btnReward:show()
				childs.imgCanGet:show()
				childs.btnComplete:hide()
				childs.timePanel:hide()
			end
			list:unSchedule(k)
		else
			childs.timePanel:get("textTime"):text(time.getCutDown(tmpTime).str)
		end
	end, 1, 0, "item" .. k)
end
local function setEffect(parent, quality)
	local effect = parent:get("effect")
	local size = parent:size()
	local effectName = quality == 1 and "effect" or "effect" .. (quality - 1)
	if not effect then
		effect = widget.addAnimationByKey(parent, "diban/diban.skel", "effect", effectName, -1)
			:xy(size.width/2 + 5, size.height/2 + 20)
			:scale(2)
	else
		effect:play(effectName)
	end
end

local DispatchTaskView = class("DispatchTaskView", cc.load("mvc").ViewBase)

DispatchTaskView.RESOURCE_FILENAME = "dispatch_task.json"
DispatchTaskView.RESOURCE_BINDING = {
	["attrItem"] = "attrItem",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				padding = 38,
				data = bindHelper.self("taskDatas"),
				item = bindHelper.self("item"),
				attrItem = bindHelper.self("attrItem"),
				-- dataOrderCmpGen = bindHelper.self("onSortCards", true),
				-- asyncPreload = 4,
				onItem = function(list, node, k, v)
					node:stopAllActions()
					node:removeChildByName("effect")
					node:setName("item" .. list:getIdx(k))
					local attrItem = list.attrItem
					local childs = node:multiget(
						"imgCanGet",
						"timePanel",
						"iconCompleted",
						"textTitle",
						"imgQuality",
						"timeNote",
						"time",
						"conditionPanel",
						"rewardPanel",
						"btnReward",
						"btnComplete",
						"timeNote"
					)
					setSubTime(list, childs, v, k)
					dispatchtaskTools.setRewardPanel(list, childs.rewardPanel, v.cfg.award, "icon", "main")
					dispatchtaskTools.setRewardPanel(list, childs.rewardPanel, v.cfg.extraAward, "extraIcon", "main")
					dispatchtaskTools.setItemCondition(childs.conditionPanel, v, attrItem, "main")
					childs.textTitle:text(v.cfg.name)
					childs.imgQuality:texture(QUALITY_IMG[v.quality])
					childs.time:text(getTimeStr(v.cfg.duration))
					adapt.oneLinePos(childs.timeNote, childs.time)
					text.addEffect(childs.btnReward:get("textNote"), {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
					itertools.invoke(childs, "hide")
					performWithDelay(node, function()
						setEffect(node, v.quality)
						local effect = node:get("effect")
						effect:setSpriteEventHandler(function(event, eventArgs)
							itertools.invoke(childs, "show")
							childs.imgCanGet:visible(v.status == 1)
							childs.iconCompleted:visible(v.status == 4)
							childs.btnReward:visible(v.status == 1)
							childs.btnComplete:visible(v.status == 3)
							childs.timePanel:visible(v.status == 3)
							effect:setSpriteEventHandler()
						end, sp.EventType.ANIMATION_COMPLETE)
					end, 0.2)
					performWithDelay(node, function()
						childs.btnReward:visible(v.status == 1)
						childs.btnComplete:visible(v.status == 3)
					end, 0.5)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					bind.touch(list, childs.btnReward, {methods = {ended = functools.partial(list.btnReward, k, v)}})
					bind.touch(list, childs.btnComplete, {methods = {ended = functools.partial(list.btnComplete, k, v)}})
				end,
				-- preloadCenter = bindHelper.self("selectIdx"),
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				clickCell = bindHelper.self("onItemClick"),
				btnReward = bindHelper.self("onBtnReward"),
				btnComplete = bindHelper.self("onBtnComplete"),
			},
		},
	},
	["bottomPanel"] = "bottomPanel",
	["bottomPanel.costIcon"] = "costIcon",
	["bottomPanel.btn"] = {
		varname = "bottomBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRefresh")}
		},
	},
	["bottomPanel.costNote"] = {
		varname = "costNote",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["bottomPanel.cost"] = {
		varname = "cost",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["bottomPanel.taskNumNote"] = {
		varname = "taskNumNote",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["bottomPanel.taskNum"] = {
		varname = "taskNum",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["bottomPanel.taskTimeNote"] = {
		varname = "taskTimeNote",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["bottomPanel.taskTime"] = {
		varname = "taskTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}, color = ui.COLORS.NORMAL.LIGHT_GREEN},
		},
	},
}

function DispatchTaskView:onCreate(datas)
	self:initModel()

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.dispatch, subTitle = "SEND"})

	adapt.centerWithScreen({"left", nil, false}, {"right", nil, false}, nil, {
		{self.taskTimeNote, "pos","left"},
		{self.taskTime, "pos","left"},
		{self.taskNum, "pos","right"},
		{self.taskNumNote, "pos","right"},
		{self.cost, "pos","right"},
		{self.costNote, "pos","right"},
		{self.costIcon, "pos","right"},
		{self.bottomBtn, "pos","right"},
		{self.list, "width"},
		{self.list, "pos","left"},
	})

	self.item:get("conditionPanel.attrList"):setScrollBarEnabled(false)
	-- self.item:get("conditionPanel.attrList"):width(640 - self.item:get("conditionPanel.extraCondition2"):width())
	adapt.oneLinePos(self.item:get("conditionPanel.extraCondition2"),self.item:get("conditionPanel.attrList"))
	self.taskDatas = idlertable.new({})

	--可接取数量
	self.accessibleNum = idler.new(0)
	idlereasy.any({self.dispatchTasks, self.vipLevel},function(_, dispatchTasks, vipLevel)
		-- 记录下次派遣任务自动刷新时间
		local curTime = time.getTime()
		local t = time.getTimeTable()
		local hour 		-- 计算下次刷新时间
		--5点和18点刷新
		if t.hour < 5 then
			hour = 5 - 1 - t.hour
		elseif  t.hour >= 18 then
			hour = 24 + 5 - 1 - t.hour
		else
			hour = 18 - 1 - t.hour
		end
		local nextTime = curTime + hour*3600 + (59-t.min)*60 + (59-t.sec) + 1
		gGameModel.forever_dispatch:getIdlerOrigin("dispatchTasksNextAutoTime"):set(nextTime) -- 存储下次自动刷新时间点

		--可领取数量
		self.canGetNum = 0
		self.selectIdx = 1
		local taskDatas = {}
		local accessibleNum = 0
		local canGetNum = 0
		for k,v in ipairs(dispatchTasks) do
			local cfg = csv.dispatch_task.tasks[v.csvID]
			local status = v.status
			local subTime = (v.ending_time or 0) - time.getTime()
			if status == 1 then
				status = 4
			end
			if status == 3 and subTime <= 0 then
				status = 1
			end
			if status == 2 then
				accessibleNum = accessibleNum + 1
			end
			if status == 1 then
				canGetNum = canGetNum + 1
			end
			table.insert(taskDatas, {
				dbid = k,
				csvID = v.csvID,
				fightingPoint = v.fighting_point,
				-- 客户端status1可领取 2可接取 3进行中 4已领取
				-- 服务器1已完成 2可接取 3进行中
				status = status,
				cardIDs = v.cardIDs or {},
				endingTime = v.ending_time,
				subTime = subTime,
				extraAwardPoint = v.extra_award_point or 0,
				cfg = cfg,
				quality = cfg.quality,
				taskData = v
			})
		end
		self.accessibleNum:set(accessibleNum)
		self.canGetNum = canGetNum
		self.bottomPanel:get("taskNum"):text(accessibleNum.."/"..gVipCsv[vipLevel].dispatchTaskCount)
		local color = accessibleNum == 0 and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.LIGHT_GREEN
		text.addEffect(self.bottomPanel:get("taskNum"), {color = color})
		table.sort(taskDatas, function(a, b)
			if a.status ~= b.status then
				return a.status < b.status
			end
			return a.quality > b.quality
		end)
		if self.showAcceptPos then
			for k,v in ipairs(taskDatas) do
				if 2 == v.status then
					self.selectIdx = k + 1
					break
				end
			end
		end
		self.taskDatas:set(taskDatas)
	end)
	--设置强化消耗的金币
	idlereasy.any({self.rmb, self.accessibleNum, self.freeRefreshTimes},function(_, rmb, accessibleNum, freeRefreshTimes)
		local freeNum = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DispatchTaskFreeRefreshTimes)
		local isFree = freeRefreshTimes < freeNum
		self.costIcon:visible(not isFree)
		setCostTxt(self.bottomPanel, rmb, accessibleNum*REFRESH_COST, isFree, freeRefreshTimes)
	end)
	DispatchTaskView.setRefreshTime(self, self.taskTime, {tag = "DispatchTaskView", cb = function ()
		self.showAcceptPos = true
	end, sendGameProtocol = true})
end

function DispatchTaskView:initModel()
	-- [{csvID:csvID, fighting_point:fightisngPoint, status:status, cardIDs:cardIDs, ending_time:endingTime}]
	self.dispatchTasks = gGameModel.role:getIdler("dispatch_tasks")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.last_time = gGameModel.role:getIdler("dispatch_task_last_time")
	self.freeRefreshTimes = gGameModel.daily_record:getIdler("dispatch_refresh_free_times")
end

--打开选择精灵界面
function DispatchTaskView:onItemClick(list, k, v)
	self.showAcceptPos = true
	local subTime = (v.endingTime or 0) - time.getTime()
	if v.status == 3 and subTime > 0 then
		gGameUI:showTip(gLanguageCsv.currentTaskDispatched)
		return
	end
	if v.status == 4 then
		gGameUI:showTip(gLanguageCsv.currentTaskCompleted)
		return
	end
	if v.status ~= 2 then
		return
	end
	if self.canGetNum >= 24 then
		gGameUI:showTip(gLanguageCsv.pleaseCollectCompletedReward)
		return
	end
	gGameUI:stackUI("city.adventure.dispatch_task.sprite_select", nil, {full = true}, v)
end
--领取奖励
function DispatchTaskView:onBtnReward(list, k, v)
	self.showAcceptPos = false
	gGameApp:requestServer("/game/dispatch/task/award", function (tb)
		gGameUI:showGainDisplay(tb)
	end, v.dbid, false)
end
--立即完成
function DispatchTaskView:onBtnComplete(list, k, v)
	self.showAcceptPos = false
	local cost = math.max(math.ceil(v.subTime / DONE_SECOND)-1, 0) * DONE_COST
	gGameUI:stackUI("city.develop.talent.reset", nil, {clickClose = true}, {
		from = "dispatch_task",
		cost = cost,
		title = gLanguageCsv.tips,
		txt1 = gLanguageCsv.consumptionOrNot,
		txt2 = gLanguageCsv.completeTheTaskImmediately,
		requestParams = {v.dbid, true},
		typ = "end",
		cb = self:createHandler("onBtnCompleteCb")
	})
end
function DispatchTaskView:onBtnCompleteCb(tb)
	gGameUI:showGainDisplay(tb)
end
--手动刷新任务
function DispatchTaskView:onRefresh()
	local freeNum = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DispatchTaskFreeRefreshTimes)
	if self.accessibleNum:read() <= 0 then
		gGameUI:showTip(gLanguageCsv.currentlyNoTasksRefresh)
		return
	end
	if self.freeRefreshTimes:read() < freeNum then
		self.showAcceptPos = true
		gGameApp:requestServer("/game/dispatch/task/refresh", nil, true)
		return
	end
	if self.accessibleNum:read()*REFRESH_COST > self.rmb:read() then
		gGameUI:showTip(gLanguageCsv.yuanzhengShopRefreshRMBNotEnough)
		return
	end
	self.showAcceptPos = true
	gGameUI:stackUI("city.develop.talent.reset", nil, {clickClose = true}, {
		from = "dispatch_task",
		cost = self.accessibleNum:read()*REFRESH_COST,
		title = gLanguageCsv.tips,
		txt1 = gLanguageCsv.consumptionOrNot,
		txt2 = gLanguageCsv.refreshTaskQuality
	})
end
--任务排序
function DispatchTaskView:onSortCards(list)
	return function(a, b)
		if a.status ~= b.status then
			return a.status < b.status
		end
		return a.quality > b.quality
	end
end
function DispatchTaskView:onAfterBuild()
	if self.selectIdx ~= nil then
		self.list:jumpToItem(self.selectIdx, cc.p(1, 0), cc.p(1, 0))
	end
end

-- @desc 设置刷新时间
-- @params:view:界面 uiTime:倒计时组件 params:相关参数 sendGameProtocol:是否需要发送刷新协议
function DispatchTaskView.setRefreshTime(view, uiTime, params)
	view:enableSchedule():schedule(function ()
		local t = time.getTimeTable()
		local hour
		--5点和18点刷新
		if t.hour < 5 then
			hour = 5 - 1 - t.hour
		elseif  t.hour >= 18 then
			hour = 24 + 5 - 1 - t.hour
		else
			hour = 18 - 1 - t.hour
		end
		if (t.hour == 5 or t.hour == 18) and t.min == 0 and t.sec == 0 then
			if params.cb then
				params.cb()
			end
			if params.sendGameProtocol then
				gGameApp:requestServer("/game/dispatch/task/refresh", nil, false)
			end
		end

		if uiTime then
			local str = string.format("%02d:%02d:%02d", hour, 59-t.min, 59-t.sec)
			uiTime:text(str)
		end
	end, 1, 0, params.flag)
end

return DispatchTaskView