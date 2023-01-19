local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}
local ActitivyDispatchTask = class("ActitivyDispatchTask", Dialog)

ActitivyDispatchTask.RESOURCE_FILENAME = "activity_dispatch_task.json"
ActitivyDispatchTask.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},

	["btnOneKeyGet"] = {
		varname = "btnOneKeyGet",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKeyGetBtn")},
		},
	},

	["btnOneKeyGet.text"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},


	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatasIdlers"),
				item = bindHelper.self("tabItem"),
				showTab = bindHelper.self("showTab"),
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
					end
					if v.redHint then
						bind.extend(list, node, {
							class = "red_hint",
							props = {
								state = list.showTab:read() ~= k,
								specialTag = v.redHint,
								listenData = {
									activityId = v.id,
									type = v.type,
								},
								onNode = function (red)
									red:xy(node:width(), node:height())
								end
							},
						})
					end
					panel:get("txt"):text(v.name)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["rewardPanel1"] = "rewardPanel1",
	["rankItem"] = "rankItem",
	["rankItem.btnGet.text"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["rewardPanel1.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 5,
				data = bindHelper.self("achvDatas1"),
				item = bindHelper.self("rankItem"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("achvDesc", "btnGet", "list", "got", "txt", "btnGoto")
					childs.achvDesc:text(v.desc)
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, {scale = 0.8})
					end
					childs.list:setScrollBarEnabled(false)
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, v.csvId)}})
					bind.touch(list, childs.btnGoto, {methods = {ended = functools.partial(list.clickGotoCell, v.goTo)}})
					-- 0已领取，1可领取 2 未完成
					childs.txt:text(v.progress .. "/" .. v.taskParam)
					if v.achType == 1 then
						childs.txt:hide()
						childs.btnGet:y(120)
					end
					if v.get == GET_TYPE.GOTTEN then
						childs.btnGoto:hide()
						childs.btnGet:get("txt"):text(gLanguageCsv.received)
						childs.txt:setTextColor(cc.c4b(98, 197, 88, 255))

					elseif v.get == GET_TYPE.CAN_GOTTEN then
						childs.btnGoto:hide()
						childs.btnGet:get("txt"):text(gLanguageCsv.spaceReceive)
						childs.txt:setTextColor(cc.c4b(98, 197, 88, 255))
					else
						childs.btnGoto:hide()
						childs.btnGet:get("txt"):text(gLanguageCsv.spaceReceive)
						childs.txt:setTextColor(cc.c4b(247, 115, 78, 255))
						if v.achType == 5 then
							if v.goTo == "" then
								childs.btnGet:show()
								childs.btnGoto:hide()
							else
								childs.btnGet:hide()
								childs.btnGoto:show()
							end
						end
					end
					uiEasy.setBtnShader(childs.btnGet, childs.btnGet:get("txt"), v.get)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onGetBtn"),
				clickGotoCell = bindHelper.self("onGotoBtn"),
			},
		},
	},
}

function ActitivyDispatchTask:onCreate(id)
	self.activityId = id
	self.rewardPanel1:show()

	local tabId = 0
	for i, v in orderCsvPairs(csv.yunying.dispatch_task) do
		tabId = v.type
		break
	end

	self.showTab = idler.new(tabId)
	self:initModel()

	Dialog.onCreate(self)
end

function ActitivyDispatchTask:initModel()
	self.achvDatas1 = idlers.new()
	self.tabDatasIdlers = idlers.new()
	local tempDatas = {
		[1] = {name = gLanguageCsv.dispatchTaskType1, redHint = "dispatchTaskType",id = self.activityId, type = 1},
		[2] = {name = gLanguageCsv.dispatchTaskType2, redHint = "dispatchTaskType",id = self.activityId, type = 2},
		[3] = {name = gLanguageCsv.dispatchTaskType3, redHint = "dispatchTaskType",id = self.activityId, type = 3},
		[4] = {name = gLanguageCsv.dispatchTaskType4, redHint = "dispatchTaskType",id = self.activityId, type = 4},
		[5] = {name = gLanguageCsv.dispatchTaskType5, redHint = "dispatchTaskType",id = self.activityId, type = 5},
	}
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		local times = yydata.valsums or {}
		local tabDatas = {}
		self.datas = {}
		local onekeyEnabled = false
		for i, v in orderCsvPairs(csv.yunying.dispatch_task) do
			local data = table.shallowcopy(v)
			data.csvId = i
			local stamps = yydata.stamps or {}
			data.get = stamps[i]
			data.progress = times[i] or 0
			data.achType = v.type
			self.datas[v.type] = self.datas[v.type] or {}
			tabDatas[v.type] = tabDatas[v.type] or tempDatas[v.type]
			table.insert(self.datas[v.type], data)
			if data.get == GET_TYPE.CAN_GOTTEN then
				onekeyEnabled = true
			end
		end
		uiEasy.setBtnShader(self.btnOneKeyGet, self.btnOneKeyGet:get("txt"), onekeyEnabled == false and 2 or 1)
		self.achvDatas1:update(self.datas[self.showTab:read()])
		self.tabDatasIdlers:update(tabDatas)
	end)
	self.showTab:addListener(function(val, oldval)
		self.tabDatasIdlers:atproxy(oldval).select = false
		self.tabDatasIdlers:atproxy(val).select = true
		self.achvDatas1:update(self.datas[val])
	end)
end

function ActitivyDispatchTask:onTabClick(list, index)
	self.showTab:set(index)
end

function ActitivyDispatchTask:onGetBtn(list, csvId)
	gGameApp:requestServer("/game/yy/award/get",function (tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, csvId)
end

function ActitivyDispatchTask:onOneKeyGetBtn(list)
	gGameApp:requestServer("/game/yy/award/get/onekey",function (tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId)
end


function ActitivyDispatchTask:onGotoBtn(llist, goTo)
	jumpEasy.jumpTo(goTo)
end


function ActitivyDispatchTask:onSortCards(list)
	return function(a, b)
		local va = a.get or 0.5
		local vb = b.get or 0.5
		if va ~= vb then
			return va > vb
		end
		return a.csvId < b.csvId
	end
end

return ActitivyDispatchTask
