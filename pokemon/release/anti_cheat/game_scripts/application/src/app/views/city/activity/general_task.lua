-- @date 2018-12-23
-- @desc 任务 (等级礼包)

-- 可领取，未达成 (不可领取)，已领取
local STATE_TYPE = {
	canReceive = 1,
	noReach = 2,
	received = 3,
}

local ActivityGeneralTaskView = class("ActivityGeneralTaskView", cc.load("mvc").ViewBase)

ActivityGeneralTaskView.RESOURCE_FILENAME = "activity_general_task.json"
ActivityGeneralTaskView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("list", "num", "receivebtn", "received", "desc", "img")
					uiEasy.createItemsToList(list, childs.list, cfg.award)
					local desc = cfg.desc
					childs.desc:text(desc)
					childs.num:text("")
					text.addEffect(childs.num, {color = ui.COLORS.NORMAL.FRIEND_GREEN})
					if v.progress then
						childs.num:text(string.format("%d/%d", v.progress[1], v.progress[2]))
					end
					local numWidth = childs.num:width()
					local descWidth = childs.desc:width()
					if numWidth + descWidth > 400 then
						childs.desc:x(childs.num:box().x - 20 - descWidth)
						childs.img:width(numWidth + descWidth + 70)
					else
						childs.desc:x(1436)
						childs.img:width(455)
					end
					childs.receivebtn:visible(v.state ~= STATE_TYPE.received)
					childs.received:visible(v.state == STATE_TYPE.received)
					childs.receivebtn:setTouchEnabled(false)
					cache.setShader(childs.receivebtn, false, "normal")
					local receiveLabel = childs.receivebtn:get("label")
					if v.state == STATE_TYPE.canReceive then
						childs.receivebtn:setTouchEnabled(true)
						text.addEffect(receiveLabel, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
						bind.touch(list, childs.receivebtn, {methods = {ended = functools.partial(list.clickCell, k, v)}})

					elseif v.state == STATE_TYPE.noReach then
						text.addEffect(childs.num, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
						cache.setShader(childs.receivebtn, false, "hsl_gray")
						text.deleteAllEffect(receiveLabel)
						text.addEffect(receiveLabel, {color = ui.COLORS.DISABLED.WHITE})
					end
				end,
				asyncPreload = 5,
			},
			handlers = {
				clickCell = bindHelper.self("onReceiveClick"),
			},
		},
	},
}

function ActivityGeneralTaskView:onCreate(activityId)
	self.activityId = activityId
	self:initModel()
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	self.datas = idlers.new()
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		local yyProgress = gGameModel.role:getYYHuoDongTasksProgress(activityId) or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.generaltask) do
			if v.huodongID == huodongID then
				local state = STATE_TYPE.noReach
				-- yydata.stamps[k] : 1:可领取，0：已领取，其他：不可领取
				if stamps[k] == 1 then
					state = STATE_TYPE.canReceive

				elseif stamps[k] == 0 then
					state = STATE_TYPE.received
				end
				table.insert(datas, {csvId = k, cfg = v, state = state, progress = yyProgress[k]})
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.datas:update(datas)
	end)
end

function ActivityGeneralTaskView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityGeneralTaskView:onReceiveClick(list, k, v)
	if v.state == STATE_TYPE.canReceive then
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.activityId, v.csvId)

	elseif v.state == STATE_TYPE.noReach then
		gGameUI:showTip(gLanguageCsv.notReachedCannotGet)
	end
end

return ActivityGeneralTaskView