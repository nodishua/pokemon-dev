-- @date:   2018-09-25
-- @desc:   任务初步显示

local BTN_STATE = {
	GET = 0,
	GO = 1,
	NONE = 2,
	GOT = 3,
}

local function itemShow(list, node, k, v)
	local cfg = v.cfg
	if cfg.vipReq then
		node:get("bg2"):visible(cfg.vipReq > 0)
	end
	local childs = node:multiget("textName", "textDesc", "list", "btnGet", "btnGo", "textNum", "imgGot", "imgIcon")
	childs.textName:text(cfg.title)
	childs.textDesc:text(cfg.desc)
	uiEasy.createItemsToList(list, childs.list, v.data, {scale = 0.8})
	childs.imgIcon:texture(cfg.icon)
	childs.btnGet:visible(v.state == BTN_STATE.GET)
	childs.btnGo:visible(v.state == BTN_STATE.GO)
	childs.imgGot:visible(v.state == BTN_STATE.GOT)
	childs.textNum:visible(v.state ~= BTN_STATE.GOT)
	text.addEffect(childs.btnGet:get("title"), {glow={color=ui.COLORS.GLOW.WHITE}})
	text.addEffect(childs.btnGo:get("title"), {glow={color=ui.COLORS.GLOW.WHITE}})
	bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCellGet, k, node)}})
	bind.touch(list, childs.btnGo, {methods = {ended = functools.partial(list.clickCellGo, k)}})
	childs.textDesc:text(cfg.desc)
	if v.progressCurr then
		local color = tonumber(v.progressCurr) >= tonumber(cfg.targetDisplay) and
			cc.c4b(96,196,86,255) or cc.c4b(247,107,69,255)
		local num = string.format("%s/%s", v.progressCurr, cfg.targetDisplay)
		childs.textNum:text(num)
		text.addEffect(childs.textNum,{color = color})
		if v.state == BTN_STATE.NONE then
			childs.textNum:y(110)
		else
			childs.textNum:y(165)
		end
	end
end

local TaskView = class("TaskView", cc.load("mvc").ViewBase)
TaskView.RESOURCE_FILENAME = "task.json"
TaskView.RESOURCE_BINDING = {
	["leftPanel"] = "leftPanel",
	["leftPanel.item"] = "leftItem",
	["leftPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
						panel:get("subTxt"):text(v.subName)
					end
					panel:get("txt"):text(v.name)
					panel:get("txt"):text(v.name)
					uiEasy.updateUnlockRes(v.unlockKey, panel, {justRemove = not v.unlockKey, pos = cc.p(60, 110)})
						:anonyOnly(list, list:getIdx(k))
					bind.extend(list, panel, {
						class = "red_hint",
						props = {
							state = v.select ~= true,
							specialTag = k == 1 and "cityTaskDaily" or "cityTaskMain",
							onNode = function(panel)
								panel:xy(346, 147)
							end,
						},
					})
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftItemClick"),
			},
		},
	},
	["itemTask"] = "itemTask",
	["rightPanel"] = "rightPanel",
	["rightPanel.dailyPanel.btnAll"] = {
		varname = "btnAll",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKeyClick")}
		},
	},

	["rightPanel.dailyPanel.btnAll.title"] = "oneKeyTxt",
	-- ["itemIcon"] = "itemIcon",
	["rightPanel.dailyPanel.dailyList"] = {
		varname = "dailyList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("dailyData"),
				item = bindHelper.self("itemTask"),
				asyncPreload = 4,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					itemShow(list, node, k, v)
				end,
			},
			handlers = {
				clickCellGet = bindHelper.self("onBtnGetDailyClick"),
				clickCellGo = bindHelper.self("onBtnGoDailyClick"),
			},
		},
	},
	["rightPanel.dailyPanel"] = "dailyPanel",
	["rightPanel.mainList"] = {
		varname = "mainList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("mainData"),
				item = bindHelper.self("itemTask"),
				asyncPreload = 4,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					itemShow(list, node, k, v)
				end,
			},
			handlers = {
				clickCellGet = bindHelper.self("onBtnGetMainClick"),
				clickCellGo = bindHelper.self("onBtnGoMainClick"),
			},
		},
	},
	["itemBox"] = "itemBox",
	["rightPanel.dailyPanel.boxList"] = {
		varname = "boxList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("boxData"),
				item = bindHelper.self("itemBox"),
				backupCached = false,
				onItem = function(list, node, k, v)
					local scoreEnough = v.scoreEnough == true
					local boxGet = v.boxGet == true
					local imgBox = node:get("icon")
					imgBox:texture("common/icon/icon_box"..k..(boxGet and"_open.png" or ".png"))
					bind.touch(list, imgBox, {methods = {ended = functools.partial(list.clickBoxGet, k, imgBox)}})
					node:get("bg"):texture(scoreEnough and "city/task/bg_huoyuedu1.png" or "city/task/bg_huoyuedu2.png")

					local boxCanOpen = scoreEnough and not boxGet
					if boxCanOpen then
						local effect = widget.addAnimation(node, "effect/jiedianjiangli.skel", "effect_loop", imgBox:z() - 1)
						local size = imgBox:size()
						local nSize = node:size()
						local scaleNum = math.max(size.width / nSize.width, size.height / nSize.height)
						scaleNum = math.min(scaleNum, 0.5)
						effect:scale(scaleNum)
							:x(imgBox:x())
							:y(imgBox:y() - 30)
						node.effectBox = effect
					elseif node.effectBox then
						node.effectBox:hide()
						node.effectBox:removeFromParent()
						node.effectBox = nil
					end
					uiEasy.addVibrateToNode(list,imgBox,boxCanOpen,node:getName()..k.."vibrate")
					node:get("num"):text(v.cfg.needPoint)
				end,
			},
			handlers = {
				clickBoxGet = bindHelper.self("onBoxGetClick"),
			},
		},
	},
	["rightPanel.dailyPanel.bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("livenessPoint1"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		}
	},
	["rightPanel.dailyPanel.num"] = "currLiveness",
	["rightPanel.dailyPanel.txt"] = "liveness",
	["rightPanel.dailyPanel.bg"] = "livenessBg",
	["rightPanel.dailyPanel.heart"] = "heart",
}

-- showTab 1:日常，2：主线
function TaskView:onCreate(showTab)
	local adaptPos = self.rightPanel:get("dailyPanel"):multiget("btnAll", "icon", "bg", "txt", "num", "barBg", "bar", "heart")
	local itemAdapt = self.itemTask:multiget("bg2", "bg")
	local itemAdaptPos1 = self.itemTask:multiget("imgIcon", "textName", "textDesc")
	local itemAdaptPos2 = self.itemTask:multiget("list", "textNum", "btnGet", "btnGo", "imgGot")
	adapt.centerWithScreen("left", "right", nil, {
		{self.leftPanel, "pos", "left"},
		{adaptPos, "pos", "right"},
		{self.boxList, "pos", "right"},
		{self.dailyList, "width"},
		{self.mainList, "width"},
		{self.mainList, "pos", "left"},
		{self.itemTask, "width"},
		{self.dailyList, "pos", "left"},
		{itemAdapt, "width"},
		{itemAdaptPos1, "pos", "left"},
		{itemAdaptPos2, "pos", "right"},
	})
	showTab = showTab or 1
	dataEasy.getListenUnlock(gUnlockCsv.dailyTask, function(isUnlock)
		if not isUnlock then
			showTab = 2
		end
	end)
	self:initModel()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.task, subTitle = "TASK"})

	self.dailyData = idlertable.new({})
	self.mainData = idlertable.new({})
	self.btnOneKeyGray = idler.new(false)
	idlereasy.when(self.btnOneKeyGray, function (obj, state)
		self.btnAll:setTouchEnabled(state)
		cache.setShader(self.btnAll, false, state and "normal" or "hsl_gray")
		if state then
			text.addEffect(self.oneKeyTxt, {glow = {color = ui.COLORS.GLOW.WHITE}, color = ui.COLORS.NORMAL.WHITE})
		else
			text.deleteAllEffect(self.oneKeyTxt)
			text.addEffect(self.oneKeyTxt, {color = ui.COLORS.DISABLED.WHITE})
		end
	end)
	idlereasy.any({self.tasksDaily, self.roleLv, self.vipLevel}, function (obj, dailyData, roleLv, vipLevel)
		local dailyTasks = {}
		local isNormal = false
		for k,v in pairs(dailyData) do
			local cfg = csv.tasks[v.id]
			if cfg.vipReq <= vipLevel and cfg.levelReq <= roleLv then
				local data = {}
				for k,v in csvMapPairs(cfg.awardArgs) do
					data[k] = v
				end
				if cfg.point > 0 then
					data[399] = cfg.point
				end
				local state = BTN_STATE.NONE
				if v.flag == 0 and cfg.goToPanel then
					state = BTN_STATE.GO
				elseif v.flag == 1 then
					state = BTN_STATE.GET
					isNormal = true
				elseif v.flag == 2 then
					state = BTN_STATE.GOT
				end
				table.insert(dailyTasks, {
					id = v.id,
					progressCurr = v.arg,
					data = data,
					state = state,
					cfg = cfg
				})
			end
		end
		self.btnOneKeyGray:set(isNormal)
		table.sort(dailyTasks, function (dailyDataA, dailyDataB)
			if dailyDataA.state == dailyDataB.state and dailyDataA.state ~= 3 then
				return dailyDataA.cfg.sortWeight > dailyDataB.cfg.sortWeight
			else
				return dailyDataA.state < dailyDataB.state
			end
		end)
		dataEasy.tryCallFunc(self.dailyList, "updatePreloadCenterIndex")
		self.dailyData:set(dailyTasks)
		return true
	end)
	idlereasy.any({self.tasksMain, self.roleLv, self.vipLevel}, function (obj, mainData, roleLv, vipLevel)
		local mainTasks = {}
		for k,v in pairs(mainData) do
			local cfg = csv.tasks[v.id]
			if v.flag ~= 2 and cfg.vipReq <= vipLevel and cfg.levelReq <= roleLv then
				local state = BTN_STATE.NONE
				if v.flag == 0 and cfg.goToPanel then
					state = BTN_STATE.GO

				elseif v.flag == 0 or v.flag == 2 then
					state = BTN_STATE.NONE
				else
					state = BTN_STATE.GET
				end
				local data = {}
				for key,val in csvMapPairs(cfg.awardArgs) do
					data[key] = val
				end
				table.insert(mainTasks, {
					id = v.id,
					progressCurr = v.arg,
					data = data,
					state = state,
					cfg = cfg
				})
			end
		end
		table.sort(mainTasks, function (mainDataA, mainDataB)
			if mainDataA.state == mainDataB.state and mainDataA.state ~= 3 then
				return mainDataA.cfg.sortWeight > mainDataA.cfg.sortWeight
			else
				return mainDataA.state < mainDataB.state
			end
		end)
		self.mainData:set(mainTasks)
		return true
	end)

	local leftDatas = {
		{name = gLanguageCsv.spaceDaily, unlockKey = "dailyTask", subName = "Daily"},
		{name = gLanguageCsv.spaceMainLine, subName = "Main"},
	}
	self.leftDatas = idlers.newWithMap(leftDatas)

	self.showTab = idler.new(showTab)
	self.showTab:addListener(function(val, oldval, idler)
		self.leftDatas:atproxy(oldval).select = false
		self.leftDatas:atproxy(val).select = true
		self.dailyPanel:visible(val == 1)
		self.mainList:visible(val ~= 1)
	end)
	local boxData = {}
	local newT = {}
	for i, v in orderCsvPairs(csv.livenessaward) do
		local data = {cfg = v}
		table.insert(boxData, data)
		table.insert(newT, v.needPoint)
	end
	self.livenessPoint1 = idler.new(0)
	self.boxData = idlertable.new(boxData)
	idlereasy.when(self.boxAward, function (obj, award)
		for i, v in ipairs(award) do
			if v == 2 then
				self.boxData:proxy()[i].boxGet = true
			end
		end
		return true
	end)

	local progress = {20, 40, 60, 80, 100}
	idlereasy.when(self.livenessPoint, function (obj, val)
		self.livenessPoint1:set(mathEasy.showProgress(progress, newT, val))
		local index = 0
		for i,v in ipairs(newT) do
			if val>= v then
				index = index + 1
			else
				break
			end
		end
		for i=1,index do
			self.boxData:proxy()[i].scoreEnough = true
		end
		self.currLiveness:text(val)
	end)

	self.params = {}
	self.roleLv:addListener(function(curval, oldval)
		if curval == oldval then
			return
		end
		self.params.cb = function ()
			gGameUI:stackUI("common.upgrade_notice", nil, nil, oldval)
		end
	end, true)
	if self.dailyPanel:get("privilege") then
		self.dailyPanel:get("privilege"):removeSelf()
	end
	uiEasy.setPrivilegeRichText(game.PRIVILEGE_TYPE.DailyTaskExpRate, self.dailyPanel, gLanguageCsv.exps, cc.p(7, 113))
end

function TaskView:initModel()
	self.tasksDaily = gGameModel.tasks:getIdler("daily")
	self.tasksMain = gGameModel.tasks:getIdler("main")
	self.livenessPoint = gGameModel.daily_record:getIdler("liveness_point")
	self.boxAward = gGameModel.daily_record:getIdler("liveness_stage_award")
	self.roleLv = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
end

function TaskView:onBtnGoMainClick(list, index)
	local data = self.mainData:proxy()[index]
	local cfg = csv.tasks[data.id]
	jumpEasy.jumpTo(cfg.goToPanel)
end

function TaskView:onBtnGetMainClick(list, index, item)
	local id = self.mainData:proxy()[index].id
	gGameApp:requestServer("/game/role/main_task/gain", function()
		local effect = item:get("effect")
		if effect then
			effect:removeFromParent()
		end
		local reward = {}
		for k, v in csvMapPairs(csv.tasks[id].awardArgs) do
			table.insert(reward, {k, v})
		end
		self:showGainDisplayThenLevel(reward, {raw = false})
	end, id)
end

function TaskView:onBtnGoDailyClick(list, index)
	local data = self.dailyData:proxy()[index]
	local cfg = csv.tasks[data.id]
	jumpEasy.jumpTo(cfg.goToPanel)
end

function TaskView:onBoxGetClick(list, index, box)
	local data = self.boxData:proxy()[index]
	if self.livenessPoint:read() >= data.cfg.needPoint and not data.boxGet then
		local showOver = {false}
		gGameApp:requestServerCustom("/game/role/liveness/stageaward")
			:params(index)
			:onResponse(function (tb)
				box:texture("common/icon/icon_box"..index.."_open.png")
				uiEasy.setBoxEffect(box, 0.5, function()
					showOver[1] = true
				end, -15, 10)
			end)
			:wait(showOver)
			:doit(function (tb)
				self:showGainDisplayThenLevel(tb)
				data.boxGet = true
			end)
	else
		gGameUI:showBoxDetail({
			data = data.cfg.award,
			content = string.format(gLanguageCsv.totalLivenessCanGetBox, data.cfg.needPoint),
			state = data.boxGet == true and 0 or 1
		})
	end
end

function TaskView:onBtnGetDailyClick(list, index, item)
	local id = self.dailyData:proxy()[index].id
	gGameApp:requestServer("/game/role/daily_task/gain", function(tb)
		local effect = item:get("effect")
		if effect then
			effect:removeFromParent()
		end
		local cfg = csv.tasks[id]
		local award = {}
		for k,v in pairs(tb.view.result) do
			award[k] = v
		end
		if cfg.point > 0 then
			award[399] = cfg.point
		end
		self:showGainDisplayThenLevel(award, {raw = false})
	end,id)
end

function TaskView:onOneKeyClick()
	local reward = {}
	local data = self.dailyData:read()
	local pointNum = 0
	for k, v in ipairs(data) do
		if v.state == BTN_STATE.GET then
			local cfg = csv.tasks[v.id]
			pointNum = pointNum + cfg.point
		end
	end
	if pointNum > 0 then
		reward[399] = pointNum
	end
	gGameApp:requestServer("/game/role/daily_task/allgain", function(tb)
		for key, value in pairs(tb.view.result) do
			if reward[key] then
				reward[key] = reward[key]+value
			else
				reward[key] = value
			end
		end
		self:showGainDisplayThenLevel(reward, {raw = false})
	end)
end

function TaskView:onLeftItemClick(list, index)
	if not dataEasy.isUnlock(gUnlockCsv.dailyTask) and index == 1 then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.dailyTask))
	else
		self.showTab:set(index)
	end
end

function TaskView:showGainDisplayThenLevel(data, params)
	if params then
		for k,v in pairs(params) do
			self.params[k] = v
		end
	end
	gGameUI:showGainDisplay(data, self.params)
	self.params = {}
end

return TaskView