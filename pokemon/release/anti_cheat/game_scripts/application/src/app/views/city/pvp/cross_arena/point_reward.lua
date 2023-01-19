-- @date:   2020-05-22
-- @desc:   跨服竞技场-积分奖励

local function setBtnState(btn, state)
	btn:setTouchEnabled(state)
	cache.setShader(btn, false, state and "normal" or "hsl_gray")
	if state then
		text.addEffect(btn:get("txt"), {glow={color=ui.COLORS.GLOW.WHITE}})
	else
		text.deleteAllEffect(btn:get("txt"))
		text.addEffect(btn:get("txt"), {color = ui.COLORS.DISABLED.WHITE})
	end
end

local CrossArenaPointRewardView = class("CrossArenaPointRewardView", Dialog)

CrossArenaPointRewardView.RESOURCE_FILENAME = "cross_arena_stage_reward.json"
CrossArenaPointRewardView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
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
								onNode = function (red)
									red:xy(node:width() - 10, node:height() - 5)
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
	["rewardPanel"] = "rewardPanel",
	["rewardPanel.btnAllGet"] = {
		varname = "getBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onNextGetBtn()
			end)}
		},
	},
	["rewardPanel.btnAllGet.txt"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["rewardPanel.rankItem"] = "rankItem",
	["rewardPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 5,
				data = bindHelper.self("pointDatas1"),
				item = bindHelper.self("rankItem"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("txtRank", "btnGet", "list")
					childs.txtRank:text(v.point)
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, {scale = 0.9, margin = 20})
					end
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					--0已领取，1可领取
					childs.btnGet:get("txt"):text((v.pointAwardState == 0) and gLanguageCsv.received or gLanguageCsv.spaceReceive)
					setBtnState(childs.btnGet, v.pointAwardState == 1)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onitemClick"),
			},
		},
	},
	["rewardPanel1"] = "rewardPanel1",
	["rewardPanel1.rankItem"] = "rankItem1",
	["rewardPanel1.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 5,
				data = bindHelper.self("pointDatas2"),
				item = bindHelper.self("rankItem1"),
				itemAction = {isAction = true},
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				onItem = function(list, node, k, v)
					local childs = node:multiget("state", "btnGet", "list")
					bind.extend(list, childs.state, {
						event = "extend",
						class = "stage_icon",
						props = {
							rank = v.point,
							showStageBg = false,
							showStage = true,
							onNodeClick = nil,
							onNode = function(node)
								node:xy(92, 100)
									:z(6)
									:scale(1)
							end,
						}
					})
					if next(v.award) ~= nil then
						uiEasy.createItemsToList(list, childs.list, v.award, {scale = 0.9, margin = 20})
					end
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					--0已领取，1可领取
					childs.btnGet:get("txt"):text((v.pointAwardState == 0) and gLanguageCsv.received or gLanguageCsv.spaceReceive)
					setBtnState(childs.btnGet, v.pointAwardState == 1)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onitemNextClick"),
			},
		},
	},
	["rewardPanel2"] = "rewardPanel2",
	["rewardPanel2.txt"] = "txtPeriod",
	["rewardPanel2.rankItem"] = "rankItem2",
	["rewardPanel2.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rewardData"),
				item = bindHelper.self("rankItem2"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("list", "stageIcon", "imgBg", "imgBg1", "txtRank", "txt", "rankIcon")
					childs.txtRank:hide()
					childs.txt:hide()
					childs.imgBg1:hide()
					childs.rankIcon:show()
					childs.imgBg:show()
					bind.extend(list, childs.stageIcon, {
						event = "extend",
						class = "stage_icon",
						props = {
							rank = v.rank,
							showStageBg = false,
							showStage = v.cfg.stageID ~= dataEasy.getCrossArenaStageByRank(1),
							onNodeClick = nil,
							onNode = function(node)
								node:xy(92, 100)
									:z(6)
									:scale(1)
							end,
						}
					})
					local stageData = dataEasy.getCrossArenaStageByRank(v.rank)
					uiEasy.createItemsToList(list, childs.list, v.cfg.periodAward, {scale = 0.9, margin = 20})
					if v.cfg.stageID == dataEasy.getCrossArenaStageByRank(1).stageID then
						childs.txtRank:show()
						childs.txt:show()
						childs.rankIcon:hide()
						if tonumber(v.cfg.range[1]) == tonumber(v.cfg.range[2] - 1) then
							childs.txtRank:text(v.cfg.range[1])
						else
							childs.txtRank:text(v.cfg.range[1].."-"..v.cfg.range[2] - 1)
						end
						childs.list:xy(childs.list:x() + 100, childs.list:y())
						childs.imgBg:hide()
						childs.imgBg1:show()
						if v.isCurRank then
							childs.imgBg1:texture("city/pvp/cross_arena/box_wz_2.png")
						else
							childs.imgBg1:texture("city/pvp/cross_arena/box_wz_1.png")
						end
					else
						if v.isCurRank then
							childs.imgBg:texture("city/pvp/cross_arena/dwjl_bg_list_1.png")
						else
							childs.imgBg:texture("city/pvp/cross_arena/dwjl_bg_list.png")
						end
					end
				end,
				preloadCenter = bindHelper.self("lastIdx"),
				asyncPreload = 5,
			},
		},
	},
	["rewardPanel3"] = "rewardPanel3",
	["rewardPanel3.txt"] = "txtStage",
	["rewardPanel3.rankItem"] = "rankItem3",
	["rewardPanel3.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rewardData1"),
				item = bindHelper.self("rankItem3"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("list", "stageIcon", "imgBg", "imgBg1", "txtRank", "txt", "rankIcon")
					childs.txtRank:hide()
					childs.txt:hide()
					childs.rankIcon:show()
					childs.imgBg:show()
					childs.imgBg1:hide()
					bind.extend(list, childs.stageIcon, {
						event = "extend",
						class = "stage_icon",
						props = {
							rank = v.rank,
							showStageBg = false,
							showStage = v.cfg.stageID ~= dataEasy.getCrossArenaStageByRank(1),
							onNodeClick = nil,
							onNode = function(node)
								node:xy(92, 100)
									:z(6)
									:scale(1)
							end,
						}
					})
					uiEasy.createItemsToList(list, childs.list, v.cfg.finishAward, {scale = 0.9, margin = 20})
					if v.cfg.stageID == dataEasy.getCrossArenaStageByRank(1).stageID then
						childs.txtRank:show()
						childs.txt:show()
						childs.rankIcon:hide()
						if tonumber(v.cfg.range[1]) == tonumber(v.cfg.range[2] - 1) then
							childs.txtRank:text(v.cfg.range[1])
						else
							childs.txtRank:text(v.cfg.range[1].."-"..v.cfg.range[2] - 1)
						end
						childs.list:xy(childs.list:x() + 100, childs.list:y())
						childs.imgBg:hide()
						childs.imgBg1:show()
						if v.isCurRank then
							childs.imgBg1:texture("city/pvp/cross_arena/box_wz_2.png")
						else
							childs.imgBg1:texture("city/pvp/cross_arena/box_wz_1.png")
						end
					else
						if v.isCurRank then
							childs.imgBg:texture("city/pvp/cross_arena/dwjl_bg_list_1.png")
						else
							childs.imgBg:texture("city/pvp/cross_arena/dwjl_bg_list.png")
						end
					end
				end,
				preloadCenter = bindHelper.self("lastIdx1"),
				asyncPreload = 5,
			},
		},
	},

}

function CrossArenaPointRewardView:onCreate()
	self.rewardPanel:hide()
	self.rewardPanel1:hide()
	self.rewardPanel2:hide()
	self.rewardPanel3:hide()
	self:initModel()
	self.pointDatas1 = idlers.new()

	self.sevenTime = 0
	if self.round == "start" then
		self.sevenTime = time.getNumTimestamp(self.date, 22) + 6 * 24 * 3600 -- 七日奖励当天
	end

	idlereasy.when(self.pointAward, function(_, pointAward)
		pointAward = pointAward or {}
		local pointDatas1 = {}
		local canOneKeyReceive = false
		for k,v in csvPairs(csv.cross.arena.daily_award) do
			if pointAward[k] == 1 then
				canOneKeyReceive = true
			end
			pointDatas1[k] = {
				id = k,
				award = v.award,
				point = v.pwTime,
				pointAwardState = pointAward[k],
			}
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.pointDatas1:update(pointDatas1)
		setBtnState(self.getBtn, canOneKeyReceive)
	end)

	self.pointDatas2 = idlers.new()
	idlereasy.when(self.datas, function(_, datas)
		local pointDatas2 = {}
		local preStageID = 0
		for k,v in orderCsvPairs(csv.cross.arena.stage) do
			if v.version == self.version then
				if v.stageID ~= preStageID then
					pointDatas2[k] = {
						id = k,
						award = v.award,
						point = v.range[1],
						pointAwardState = datas.stage_awards and datas.stage_awards[k],
					}
					preStageID = v.stageID
				end
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.pointDatas2:update(pointDatas2)
	end)

	self.lastIdx = idler.new(1)
	self.lastIdx1 = idler.new(1)
	local isLessSevenDay = false
	if time.getTime() < self.sevenTime then
		isLessSevenDay = true
	end
	local data = {}
	for k, v in orderCsvPairs(csv.cross.arena.stage) do
		if v.version == self.version then
			-- 段位判断，7天前的读 self.role.rank, 7天后读 sevenAwardStage
			local isCurRank = false
			if isLessSevenDay then
				if self.role then
					if self.role.rank >= v.range[1] and self.role.rank < v.range[2] then
						isCurRank = true
					end
				end
			else
				local stageData = dataEasy.getCrossArenaStageByRank(v.range[1])
				if self.sevenAwardStage == k then
					isCurRank = true
				end
			end
			table.insert(data, {cfg = v, rank = v.range[1], isCurRank = isCurRank})
		end
	end
	self.rewardData = itertools.reverse(data)
	for k, v in ipairs(self.rewardData) do
		if v.isCurRank == true then
			self.lastIdx:set(k)
		end
	end

	local rewardData1 = {}
	for k, v in orderCsvPairs(csv.cross.arena.stage) do
		if v.version == self.version then
			--段位判断, 结束前读 self.role.rank, 结束后读 finishAwardStage
			local isCurRank = false
			if self.round ~= "closed" then
				if self.role then
					if self.role.rank >= v.range[1] and self.role.rank < v.range[2] then
						isCurRank = true
					end
				end
			else
				local stageData = dataEasy.getCrossArenaStageByRank(v.range[1])
				if self.finishAwardStage == k then
					isCurRank = true
				end
			end
			table.insert(rewardData1, {cfg = v, rank = v.range[1], isCurRank = isCurRank})
		end
	end
	self.rewardData1 = itertools.reverse(rewardData1)
	for k, v in ipairs(self.rewardData1) do
		if v.isCurRank == true then
			self.lastIdx1:set(k)
		end
	end

	self.panel = {
		{
			node = self.rewardPanel,
		}, {
			node = self.rewardPanel1,
		},{
			node = self.rewardPanel2,
		},{
			node = self.rewardPanel3,
		}
	}

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.dailyReward, redHint = "crossArenaPointAward"},
		[2] = {name = gLanguageCsv.stateAward, redHint = "crossArenaRankAward"},
		[3] = {name = gLanguageCsv.periodAward},
		[4] = {name = gLanguageCsv.finishAward},
	})

	self.showTab = idler.new(1)
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self.panel[oldval].node:hide()
		self.panel[val].node:show()
	end)

	if self.sevenAwardStage ~= 0 or time.getTime() > self.sevenTime then
		self.txtPeriod:text(gLanguageCsv.stageAwardNote)
	else
		self.txtPeriod:text(gLanguageCsv.showPeriodNote)
	end
	if self.round == "closed" then
		self.txtStage:text(gLanguageCsv.stageAwardNote)
	else
		self.txtStage:text(gLanguageCsv.showStageNote)
	end

	Dialog.onCreate(self)
end

function CrossArenaPointRewardView:initModel()
	self.datas = gGameModel.role:getIdler("cross_arena_datas")
	self.pointAward = gGameModel.daily_record:getIdler("cross_arena_point_award")
	local cfg = csv.cross.service[game.crossArenaCsvId]
	self.version = cfg and cfg.version or nil
	self.role = gGameModel.cross_arena:read("role")
	self.date = gGameModel.cross_arena:read("date")
	--七日奖励是否发放
	self.sevenAwardStage = self.datas:read().seven_award_stage
	--最终奖励是否发放
	self.finishAwardStage = self.datas:read().finish_award_stage
	self.round = gGameModel.cross_arena:read("round")
end

function CrossArenaPointRewardView:onTabClick(list, index)
	self.showTab:set(index)
end

function CrossArenaPointRewardView:onitemClick(list, k, v)
	self:onNextGetBtn(v.id)
end

function CrossArenaPointRewardView:onitemNextClick(list, k, v)
	self:onGetBtn(v.id)
end

function CrossArenaPointRewardView:onNextGetBtn(csvID)
	gGameApp:requestServer("/game/cross/arena/daily/award",function (tb)
		gGameUI:showGainDisplay(tb)
	end,csvID)
end

function CrossArenaPointRewardView:onGetBtn(stageID)
	gGameApp:requestServer("/game/cross/arena/stage/award",function (tb)
		gGameUI:showGainDisplay(tb)
	end,stageID)
end

function CrossArenaPointRewardView:onSortCards(list)
	return function(a, b)
		local va = a.pointAwardState or 0.5
		local vb = b.pointAwardState or 0.5
		if va ~= vb then
			return va > vb
		end
		return a.id < b.id
	end
end

return CrossArenaPointRewardView
