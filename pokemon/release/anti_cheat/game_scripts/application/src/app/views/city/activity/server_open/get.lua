-- @Date:   2019-05-28
-- @Desc:
-- @Last Modified time: 2019-08-23

-- 可领取，未达成 (不可领取)，已领取
local STATE_TYPE = {
	canReceive = 1,
	noReach = 2,
	received = 3,
}
local activityTexture = {
	vacation = {
		iconBg = "activity/server_open/summer_vacation/btn_sqqtl_1.png"
	},
}
local function setTextPos(childs)
	local basePos =  childs.num:x()
	local textWidth = childs.num:size().width + childs.desc:size().width
	if textWidth > 400 then
		childs.desc:x(basePos - textWidth - 10)
		childs.img:size(textWidth + 54, 45)
	else
		childs.img:size(520, 45)
	end
end
local ServerOpenGetView = class("ServerOpenGetView", cc.load("mvc").ViewBase)
ServerOpenGetView.RESOURCE_FILENAME = "activity_server_open_get.json"
ServerOpenGetView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true, alwaysShow = true},
				asyncPreload = 4,
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					return a.id < b.id
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("list", "num", "receivebtn", "received", "desc", "img")
					uiEasy.createItemsToList(list, childs.list, cfg.award)
					childs.desc:text(cfg.desc)
					childs.num:text("")
					text.addEffect(childs.num, {color = ui.COLORS.NORMAL.FRIEND_GREEN})
					if v.progress then
						childs.num:text(string.format("%d/%d", v.progress[1], v.progress[2]))
					end
					setTextPos(childs)
					if v.clientType then
						for i, data in pairs(activityTexture) do
							if i == v.clientType then
								childs.receivebtn:loadTextureNormal(data.iconBg)
								childs.receivebtn:scale(2)
								childs.receivebtn:size(135, 55)
								childs.receivebtn:get("label"):scale(0.5)
								childs.receivebtn:get("label"):xy(67, 27)
							end
						end
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
			},
			handlers = {
				clickCell = bindHelper.self("onReceiveClick"),
			},
		},
	},
}

function ServerOpenGetView:onCreate(activityId, data, params)
	self:initModel()
	self.data = data
	self.currDay, self.showTab, self.tabIndex = params()
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	if not self.datas then
		self.datas = idlers.new()
	end
	self.activityId = activityId
	self.clientType = csv.yunying.yyhuodong[activityId].clientParam.type
	idlereasy.any({self.yyhuodongs, self.currDay, self.showTab, self.tabIndex}, function(_, yyhuodongs, day, tab, tabIndex)
		if tabIndex == -1 then
			return
		end
		local yydata = yyhuodongs[self.activityId] or {}
		local stamps = yydata.stamps or {}
		local data = clone(self.data[tab][tabIndex])
		if data then
			local yyProgress = gGameModel.role:getYYHuoDongTasksProgress(self.activityId) or {}
			for i = 1, #data do
				local state = STATE_TYPE.noReach
				if data[i].cfg.taskType == game.TARGET_TYPE.CompleteImmediate then
					if day < tab then
						data[i].progress = {0, 1}
					else
						data[i].progress = {1, 1}
					end
				else
					if yyProgress[data[i].id] then
						data[i].progress = yyProgress[data[i].id]
					end
				end
				if not stamps[data[i].id] then
					data[i].state = STATE_TYPE.noReach
				elseif stamps[data[i].id] == 1 then
					data[i].state = STATE_TYPE.canReceive
				elseif stamps[data[i].id] == 0 then
					data[i].state = STATE_TYPE.received
				end
				data[i].clientType = self.clientType
			end
			self.datas:update(data)
		end
	end)
end

function ServerOpenGetView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ServerOpenGetView:onReceiveClick(list, k, v)
	if v.state == STATE_TYPE.canReceive then
		dataEasy.tryCallFunc(self.list, "setItemAction", {isAction = false})
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			gGameUI:showGainDisplay(tb, {cb = function()
				performWithDelay(self, function()
					dataEasy.tryCallFunc(self.list, "setItemAction", {isAction = true, alwaysShow = true})
				end, 0.1)
			end})
		end, self.activityId, v.id)

	elseif v.state == STATE_TYPE.noReach then
		gGameUI:showTip(gLanguageCsv.notReachedCannotGet)
	end
end

return ServerOpenGetView