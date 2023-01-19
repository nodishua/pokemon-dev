local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}

local function setBtnState(btn, state)
	btn:setTouchEnabled(state)
	cache.setShader(btn, false, state and "normal" or "hsl_gray")
	if state then
		text.addEffect(btn:get("txt"), {glow={color=ui.COLORS.GLOW.WHITE}})
	else
		text.deleteAllEffect(btn:get("txt"))
		-- text.addEffect(btn:get("txt"), {color = ui.COLORS.DISABLED.WHITE})
	end
end

local GridWalkTask = class("GridWalkTask", Dialog)

GridWalkTask.RESOURCE_FILENAME = "grid_walk_task.json"
GridWalkTask.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["item"] = "item",
	["tabItem"] = "tabItem",
	["tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				showTab = bindHelper.self("showTab"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("normal", "selected", "txt")
					childs.txt:text(v.name)
					childs.normal:visible(not v.selected)
					childs.selected:visible(v.selected)
					node:setTouchEnabled(not v.selected)
					text.deleteAllEffect(childs.txt)
					if v.selected then
						text.addEffect(childs.txt, {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
					else
						text.addEffect(childs.txt, {color = ui.COLORS.NORMAL.RED})
					end
					if v.redHint then
						bind.extend(list, node, {
							class = "red_hint",
							props = {
								state = list.showTab:read() ~= k,
								specialTag = v.redHint,
								onNode = function (red)
									red:xy(node:width(), node:height())
								end
							},
						})
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("taskData"),
				item = bindHelper.self("item"),
				padding = 4,
				itemAction = {isAction = true},
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				onItem = function(list, node, k, v)
					local childs = node:multiget("desc", "imgReceived", "num", "btnReceive", "itemsList", "btnGoto")
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.itemsList, v.award, {scale = 0.7, margin = 20})
					end
					childs.desc:text(v.desc)
					local had = v.val or 0
					childs.num:text(had.."/"..v.taskParam)
					-- 0已领取，1可领取
					if v.goTo == "" and not (v.get == GET_TYPE.CAN_GOTTEN) then
						childs.num:y(node:height()/2)
					end
					childs.num:visible(not (v.get == GET_TYPE.GOTTEN))
					childs.btnGoto:visible((not v.get or v.get == GET_TYPE.CAN_NOT_GOTTEN) and v.goTo ~= "")
					childs.btnReceive:visible(v.get == GET_TYPE.CAN_GOTTEN)
					childs.imgReceived:visible(v.get == GET_TYPE.GOTTEN)

					text.addEffect(childs.num, {color = had >= v.taskParam and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE})
					text.addEffect(childs.btnReceive:get("txt"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					text.addEffect(childs.btnGoto:get("txt"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					bind.touch(list, childs.btnReceive, {methods = {ended = functools.partial(list.clickCell, v.csvId)}})
					bind.touch(list, childs.btnGoto, {methods = {ended = functools.partial(list.clickGotoCell, v.goTo)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onGetBtn"),
				clickGotoCell = bindHelper.self("onGotoBtn"),
			},
		},
	},
	["btnOneKey"] = {
		varname = "btnOneKey",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKey")}
		},
	},
	["btnOneKey.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["label"] = "label",
}

function GridWalkTask:onCreate(params)
	self.callBack = params.callBack
	self:initModel()

	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.yyID] or {}
		self.yydata = yydata
		self:initRight()
	end)

	self.showTab:addListener(function(val, oldVal)
		self.tabDatas:atproxy(oldVal).selected = false
		self.tabDatas:atproxy(val).selected = true
		self.label:visible(val == 1)
		self:initRight()
	end)

	Dialog.onCreate(self)
end

function GridWalkTask:initModel()
	self.yyID = gGameModel.role:read("grid_walk").yy_id
	self.showTab = idler.new(1)
	self.taskData = idlers.newWithMap({})
	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.dailyTasks, redHint = "gridWalkTask", selected = true},
		[2] = {name = gLanguageCsv.treasureAchievements, redHint = "gridWalkAchievements", selected = false},
	})
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function GridWalkTask:onTabClick(list, index)
	self.showTab:set(index)
end

function GridWalkTask:initRight()
	local data1 = {}
	local data2 = {}
	local btnAllGetState = false
	local yyCfg = csv.yunying.yyhuodong[self.yyID]
	local huodongID = yyCfg.huodongID
	local stamps = self.yydata.stamps or {}
	local valsums = self.yydata.valsums or {}
	for i, v in csvPairs(csv.yunying.grid_walk_tasks) do
		if v.huodongID == huodongID then
			local data = table.shallowcopy(v)
			data.csvId = i
			data.get = stamps[i]
			data.val = valsums[i]
			if data.get == 1 then
				btnAllGetState = true
			end
			if v.taskType == 0 then
				table.insert(data2, data)
			else
				table.insert(data1, data)
			end
		end
	end
	if self.showTab:read() == 1 then
		self.taskData:update(data1)
	elseif self.showTab:read() == 2 then
		self.taskData:update(data2)
	end
	setBtnState(self.btnOneKey, btnAllGetState)
end

function GridWalkTask:onSortCards(list)
	return function(a, b)
		local va = a.get or 0.5
		local vb = b.get or 0.5
		if va ~= vb then
			return va > vb
		end
		return a.csvId < b.csvId
	end
end

function GridWalkTask:onGetBtn(list, csvId)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
		self.callBack()
	end, self.yyID, csvId)
end

function GridWalkTask:onOneKey()
	gGameApp:requestServer("/game/yy/award/get/onekey",function (tb)
		gGameUI:showGainDisplay(tb)
		self.callBack()
	end, self.yyID)
end

function GridWalkTask:onGotoBtn(llist, goTo)
	jumpEasy.jumpTo(goTo)
end
return GridWalkTask
