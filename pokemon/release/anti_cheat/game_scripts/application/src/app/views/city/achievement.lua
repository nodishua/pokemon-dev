-- @desc:   成就主界面
-- @data:	2019-12-16 11:37:03

local PAGENAME = {
	ACHIEVEMENTALL = 1,
	manGrow = 2,
	CARDSGET = 3,
	CARDSGROW = 4,
	BATTLEACTIVITY = 5,
	PVPCHALLENGR = 6,
	SOCIALCONTACK = 7,
	UNVISLBLEACHIEVEMENT = 8,
}

local PAGETYPE = {
	ACHIEVEMENTALL = 0,
	manGrow = 1,
	CARDSGET = 2,
	CARDSGROW = 3,
	BATTLEACTIVITY = 4,
	PVPCHALLENGR = 5,
	SOCIALCONTACK = 6,
	UNVISLBLEACHIEVEMENT = 7,
}

local TASKPAGESTATE = {
	FINISH = 1,
	WILLBE = 2,
}

local TASKSTATE = {
	DOING = 2,
	GET = 1,
	FINISHED = 0,
}

local BOXTYPE = {
	PAGE1 = 1,
	OTHER = 2,
}

local SPECIALTYPE = {
	[48] = true, -- 竞技场排名,
}

-- 成就等级图标，待机特效动作名称
local ACTION_STANDBY = {
	jinjie4_effect = "effect_loop",
	jinjie5_effect = "effect_loop1",
}

-- spine 帧数
local DELAY = {
	levelUp = 55/30,
}

local function getNextLvReward(pageType, curLv)
	local nextCfg = gAchievementLevelCsv[pageType][curLv + 1]
	if not nextCfg then
		return
	end

	return nextCfg.award
end

local function isMaxLevel(pageType, curLv)
	-- 默认是从0开始的 所以要减去1
	return curLv >= itertools.size(gAchievementLevelCsv[pageType]) - 1
end

-- boxDatas {csvId:falg} flag 1:可领取 0已领取
local function hasReward(pageType, boxDatas)
	local csvTab = csv.achievement.achievement_level
	local t = {}
	for k,v in pairs(boxDatas) do
		local cfg = csvTab[k]
		if v == 1 and cfg.type == pageType then
			local data = {}
			data.cfg = cfg
			data.csvId = k
			table.insert(t, data)
		end
	end
	table.sort(t, function(a, b)
		return a.cfg.level < b.cfg.level
	end)

	return t[1]
end

local function onInitItem(list, node, k, v)
	local children = node:multiget("textCount", "textNote1", "textNote2", "list", "textPro", "btnGet", "btnGo", "imgGot")
	children.textNote1:text(v.cfg.title)
	local desc = v.cfg.desc
	-- children.textNote2:text(desc)
	children.textNote2:hide()
	node:removeChildByName("descRichText")

	local descRichText, height = beauty.textScroll({
		size = cc.size(660, 110),
		strs = desc,
		fontSize = children.textNote2:getFontSize()
	})
	local y = 15
	if height < 110 then
		y = 15 - (110 - height) / 2
	end
	descRichText:xy(275, y)
		:addTo(node, children.textNote2:z(), "descRichText")
	children.textCount:text(v.cfg.point)

	children.imgGot:visible(v.flag == TASKSTATE.FINISHED)
	children.btnGet:visible(v.flag == TASKSTATE.GET)
	children.btnGo:visible(v.flag == TASKSTATE.DOING and v.cfg.jumpTo ~= "")
	children.textPro:visible(v.flag ~= TASKSTATE.FINISHED)

	local color = ui.COLORS.NORMAL.FRIEND_GREEN
	if v.flag == TASKSTATE.DOING then
		color = ui.COLORS.NORMAL.ALERT_ORANGE
	end
	text.addEffect(children.textPro, {color = color})

	local curPro = v.count or 0
	children.textPro:text(curPro .. "/" .. mathEasy.getShortNumber(v.cfg.targetArg, 2))

	local itemSize = node:size()
	children.textPro:y(itemSize.height / 2)
	if v.flag == TASKSTATE.GET or v.cfg.jumpTo ~= "" then
		children.textPro:y(173)
	end

	uiEasy.createItemsToList(list, children.list, v.cfg.award, {scale = 0.8})

	bind.touch(list, children.btnGet, {methods = {ended = functools.partial(list.clickGet, k, v)}})
	bind.touch(list, children.btnGo, {methods = {ended = functools.partial(list.clickJump, v)}})
end

local ViewBase = cc.load("mvc").ViewBase
local achievementView = class("achievementView", ViewBase)

achievementView.RESOURCE_FILENAME = "achievement_main.json"
achievementView.RESOURCE_BINDING = {
	["rightAll"] = {
		varname = "rightAll",
		binds = {
			event = "visible",
			idler = bindHelper.self("selIdx"),
			method = function(val)
				return val == PAGENAME.ACHIEVEMENTALL
			end,
		},
	},
	["right"] = {
		varname = "right",
		binds = {
			event = "visible",
			idler = bindHelper.self("selIdx"),
			method = function(val)
				return val ~= PAGENAME.ACHIEVEMENTALL
			end,
		},
	},
	["left"] = "leftPanel",
	["btn"] = "btnItem",
	["left.listview"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnDatas"),
				item = bindHelper.self("btnItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local normalBtn = node:get("btnNormal")
					local selBtn = node:get("btnSelected")
					selBtn:visible(v.isSel)
					normalBtn:visible(not v.isSel)
					normalBtn:get("textNote"):text(v.txt)
					normalBtn:get("textNote1"):text(v.enTxt)
					selBtn:get("textNote"):text(v.txt)

					bind.extend(list, node, {
						class = "red_hint",
						props = {
							state = v.isSel ~= true,
							listenData = {
								curType = v.type,
							},
							specialTag = {
								"achievementTask",
								"achievementBox",
							},
							onNode = function(panel)
								panel:xy(335, 145)
							end,
						},
					})

					bind.touch(list, normalBtn, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onClickBtn"),
			},
		},
	},
	["rightAll.btnFinish.textNote"] = "btnTextNote1",
	["rightAll.btnFinish"] = {
		varname = "btnFinish",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onChangeListPage(TASKPAGESTATE.FINISH)
				end)}
			},
			{
				state = bindHelper.self("isFinishedPage"),
				listenData = {
					curType = 0,
				},
				specialTag = "achievementTask",
				onNode = function(panel)
					panel:xy(280, 110)
				end,
			},
		},
	},
	["rightAll.btnWillBe.textNote"] = "btnTextNote2",
	["rightAll.btnWillBe"] = {
		varname = "btnWillBe",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onChangeListPage(TASKPAGESTATE.WILLBE)
			end)}
		},
	},
	["rightAll.btnRank"] = {
		varname = "btnRank",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRank")}
		},
	},
	["item"] = "item",
	["rightAll.list"] = {
		varname = "allPanelList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("threeDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					onInitItem(list, node, k, v)
				end,
			},
			handlers = {
				clickGet = bindHelper.self("onClickGet"),
				clickJump = bindHelper.self("onClickJump"),
			},
		},
	},
	["infoItem"] = "infoItem",
	["rightAll.allInfo.list"] = {
		varname = "allInfoList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("taskItems"),
				item = bindHelper.self("infoItem"),
				onItem = function(list, node, k, v)
					node:get("imgIcon"):texture(v.icon)
					node:get("textName"):text(v.name)
					node:get("textPro"):text(v.progress)
				end,
			},
		},
	},
	["rightAll.info"] = "rightAllInfo",
	["rightAll.allInfo"] = "allInfo",
	["rightAll.info.textPro"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("curPoints"),
		},
	},
	["rightAll.info.textLv"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(153, 119, 9, 255), size = 4}}
			},
			{
				event = "text",
				idler = bindHelper.self("curLv"),
			},
		},
	},
	["rightAll.info.progress"] = {
		varname = "rightAllProgressBar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("curPagePro"),
				-- maskImg = "common/icon/mask_bar_red.png"
			},
		}
	},
	["right.leftInfo"] = "leftInfo",
	["right.leftInfo.textNote1"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("curPageName")
		},
	},
	["right.leftInfo.textNote2"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("curPageNameEn")
		},
	},
	["right.pageInfo.textPro"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("curPoints"),
		},
	},
	["right.pageInfo.textName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("curPageName"),
		},
	},
	["right.pageInfo.progress"] = {
		varname = "rightProgressBar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("curPagePro"),
				-- maskImg = "common/icon/mask_bar_red.png"
			},
		}
	},
	["normal"] = "rightNormal",
	["normal.textNote"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("normalText"),
		},
	},
	["right.list"] = {
		varname = "rightList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightDatas"),
				item = bindHelper.self("item"),
				-- asyncPreload = 5,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					onInitItem(list, node, k, v)
				end,
			},
			handlers = {
				clickGet = bindHelper.self("onClickGet"),
				clickJump = bindHelper.self("onClickJump"),
			},
		},
	},
	["right.pageInfo"] = {
		varname = "rightPageInfo",
		binds = {
			event = "visible",
			idler = bindHelper.self("selIdx"),
			method = function(val)
				return val ~= PAGENAME.UNVISLBLEACHIEVEMENT and val ~= PAGENAME.ACHIEVEMENTALL
			end,
		},
	},
	["right.pageInfo.box"] = {
		varname = "rightBox",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("isShowBox"),
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "achievementBox",
					listenData = {
						curType = bindHelper.self("curSelType"),
					},
					onNode = function(node)
						node:xy(140, 110)
					end,
				},
			},
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onGetBoxGift(BOXTYPE.OTHER)
				end)}
			},
		},
	},
	["right.pageInfo.box.imgBox"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("boxPath"),
		},
	},
	["rightAll.info.box"] = {
		varname = "rightAllBox",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.defer(function(view)
					view:onGetBoxGift(BOXTYPE.PAGE1)
				end)}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "achievementBox",
					listenData = {
						curType = 0
					},
					onNode = function(node)
						node:xy(140, 110)
					end,
				}
			},
			{
				event = "visible",
				idler = bindHelper.self("isShowBox"),
			},
		},
	},
	["rightAll.info.box.imgBox"] = {
		binds = {
			{
				event = "texture",
				idler = bindHelper.self("boxPath"),
			},
		},
	},
	["rightAll.info.imgIcon"] = {
		varname = "imgIcon",
		binds = {
			event = "texture",
			idler = bindHelper.self("imgLvBg"),
		},
	},
}

function achievementView:onCreate(idx)
	local itemAdapt = self.item:multiget("imgBg")
	local itemAdaptPos1 = self.item:multiget("imgIcon", "textCount", "textNote1", "textNote2")
	local itemAdaptPos2 = self.item:multiget("list", "btnGet", "btnGo", "textPro", "imgGot")
	adapt.centerWithScreen("left", "right", nil, {
		{self.leftPanel, "pos", "left"},
		{self.allPanelList, "width"},
		{self.rightList, "width"},
		{itemAdapt, "width"},
		{itemAdaptPos1, "pos", "left"},
		{itemAdaptPos2, "pos", "right"},
		{{self.leftInfo, self.rightList, self.allPanelList, self.allInfo, self.btnFinish, self.btnWillBe}, "pos", "left"},
		{{self.rightPageInfo, self.btnRank, self.rightAllInfo}, "pos", "right"},
	})

	idx = idx or PAGENAME.ACHIEVEMENTALL
	self:initModel()

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.achievement, subTitle = "ACHIEVEMENT"})

	self.isFinishedPage = idler.new(true)
	-- 当前成就点
	self.curPoints = idler.new("")
	-- 页签名字
	self.curPageName = idler.new("")
	-- 页签名字english
	self.curPageNameEn = idler.new("")
	-- 箱子资源
	self.boxPath = idler.new("")
	-- 等级背景
	self.imgLvBg = idler.new("")
	-- normal tip
	self.normalText = idler.new(gLanguageCsv.noUnvisibleTasks)
	-- 是否显示宝箱
	self.isShowBox = idler.new(true)
	self.curLv = idler.new(0)
	-- 当前页签进度条进度
	self.curPagePro = idler.new(0)

	self.selIdx = idler.new(self._selIdx or idx)
	local btnDatas = {
		{txt = gLanguageCsv.allAchievement, enTxt = "Overview", idx = 1, type = 0, isSel =false},
		{txt = gLanguageCsv.manGrow, enTxt = "Develop", idx = 2, type = 1, isSel =false},
		{txt = gLanguageCsv.cardsGet, enTxt = "Collect", idx = 3, type = 2, isSel =false},
		{txt = gLanguageCsv.strengthen, enTxt = "Training", idx = 4, type = 3, isSel =false},
		{txt = gLanguageCsv.battleActivity, enTxt = "Gate", idx = 5, type = 4, isSel =false},
		{txt = gLanguageCsv.pvpChallenge, enTxt = "Sports", idx = 6, type = 5, isSel =false},
		{txt = gLanguageCsv.socialContact, enTxt = "Social", idx = 7, type = 6, isSel =false},
	}
	local unVisibleItem = {txt = gLanguageCsv.unvislbleAchievement, enTxt = "Hide", idx = 8, type = 7, isSel =false}

	btnDatas[self.selIdx:read()].isSel = true
	self.curSelType = idler.new(btnDatas[self.selIdx:read()].type)
	self.btnDatas = idlers.newWithMap(btnDatas)

	self.taskItems = {}
	for i,v in orderCsvPairs(csv.achievement.achievement) do
		if i > 6 then
			break
		end
		if not self.taskItems[i] then
			self.taskItems[i] = {}
		end
		self.taskItems[i].icon = v.icon
		self.taskItems[i].name = v.name
	end
	self.taskItems = idlers.newWithMap(self.taskItems)

	local csvTaskTab = csv.achievement.achievement_task
	local allTasks = {}
	local allTasksCount = {}
	for k, v in orderCsvPairs(csvTaskTab) do
		if not allTasks[v.type] then
			allTasks[v.type] = {}
		end
		if not allTasks[v.type][v.targetType2] then
			allTasks[v.type][v.targetType2] = {}
		end
		local data = {cfg = v, csvId = k}
		table.insert(allTasks[v.type][v.targetType2], data)
		allTasksCount[v.type] = (allTasksCount[v.type] or 0) + 1
	end

	for _,datas in ipairs(allTasks) do
		for taskType,tab in ipairs(datas) do
			table.sort(tab, function(a, b)
				return a.cfg.sort < b.cfg.sort
			end)
		end
	end

	self.allListPageIdx = idler.new(1)--最近达成/即将达成
	self.threeDatas = idlers.newWithMap({})
	self.rightDatas = idlers.newWithMap({})
	local params = {self.selIdx, self.allListPageIdx, self.tasks, self.points, self.boxAward}
	idlereasy.any(params, function(_, selIdx, allListPageIdx, tasks, points, boxAward)
		tasks = tasks or {}
		points = points or {}
		boxAward = boxAward or {}

		local curType = self.btnDatas:atproxy(selIdx).type
		local curLv, targetPoint = self:getCurLvAndNextExp()
		local curPoints = (points[curType] or 0)
		if selIdx == PAGENAME.ACHIEVEMENTALL then
			curPoints = 0
			for k,v in pairs(points) do
				curPoints = curPoints + v
			end
		end
		self.curPoints:set(string.format("%s/%s", curPoints, targetPoint)) --当前成就点
		self.curPageName:set(self.btnDatas:atproxy(selIdx).txt) -- 页签名字
		self.curPageNameEn:set(self.btnDatas:atproxy(selIdx).enTxt)	-- 页签名字english
		self.curPagePro:set(math.min(100, curPoints / targetPoint * 100))
		self.curLv:set(curLv)
		self.curSelType:set(curType, true)

		self:updateBox(curType, boxAward, curLv)
		self:addUnVisibleItem(btnDatas, tasks)

		if selIdx ~= PAGENAME.ACHIEVEMENTALL then
			local myTasks = allTasks[curType] or {}
			dataEasy.tryCallFunc(self.rightList, "updatePreloadCenterIndex")
			local rightDatas, count = self:getRightDatas(selIdx, tasks, myTasks)
			self.rightDatas:update(rightDatas)
			self.rightNormal:xy(1670, 640)
			self.normalText:set(gLanguageCsv.noUnvisibleTasks)
			self.rightNormal:visible(count == 0)
			self.rightList:visible(count ~= 0)
		else
			self:addAllAchievementEffect(curType, curLv, allListPageIdx)
			local t, taskTypes, finishedCount = self:getAllAchievementDatas(tasks, allTasksCount)
			local threeTab, count = self:getThreeTabs(t, tasks, allListPageIdx, allTasks, taskTypes)

			self.rightNormal:xy(1500, 400)
			self.normalText:set(gLanguageCsv.noFinishedTasks)
			self.rightNormal:visible(count == 0)
			self.threeDatas:update(threeTab)
			-- 总览里面的任务计数
			for i,v in ipairs(allTasksCount) do
				if self.taskItems:atproxy(i) then
					self.taskItems:atproxy(i).progress = string.format("%s/%s", (finishedCount[i] or 0), v)
				end
			end
		end
		self.isFinishedPage:set(allListPageIdx ~= 1)

	end)
end

function achievementView:updateBox(curType, boxAward, curLv)
	self.curBoxReward = hasReward(curType, boxAward)
	self.rightAllBox:removeChildByName("effect")
	self.rightBox:removeChildByName("effect")
	if self.curBoxReward then
		local targetPanel = curType == PAGETYPE.ACHIEVEMENTALL and self.rightAllBox or self.rightBox
		local pos = curType == PAGETYPE.ACHIEVEMENTALL and cc.p(85, -10) or cc.p(65, -20)
		widget.addAnimationByKey(targetPanel, "effect/jiedianjiangli.skel", "effect", "effect_loop", 1)
			:xy(pos)
	end
	local curTypeDatas = gAchievementLevelCsv[curType] or {}
	local cfgInfo = self.curBoxReward or {cfg = curTypeDatas[curLv + 1]}
	local isShowBox = false
	local boxPath = ""
	if cfgInfo and not itertools.isempty(cfgInfo) then
		boxPath = cfgInfo.cfg.boxIcon
		isShowBox = true
	end
	self.boxPath:set(boxPath)
	self.isShowBox:set(isShowBox)
end

function achievementView:addAllAchievementEffect(curType, curLv, allListPageIdx)
	-- 等级背景
	local curTypeDatas = gAchievementLevelCsv[curType] or {}
	local cfg = curTypeDatas[curLv] or {}
	self.imgLvBg:set(cfg.icon)

	self:showLevelSpine()
	local isFinished = allListPageIdx == TASKPAGESTATE.FINISH
	self.btnFinish:setTouchEnabled(not isFinished)
	self.btnWillBe:setTouchEnabled(isFinished)
	self.btnFinish:setBright(not isFinished)
	self.btnWillBe:setBright(isFinished)
	text.deleteAllEffect(self.btnTextNote1)
	text.deleteAllEffect(self.btnTextNote2)

	local color1 = ui.COLORS.NORMAL.RED
	local color2 = ui.COLORS.NORMAL.WHITE
	local targetNode = self.btnTextNote2
	if allListPageIdx == TASKPAGESTATE.FINISH then
		color1 = ui.COLORS.NORMAL.WHITE
		color2 = ui.COLORS.NORMAL.RED
		targetNode = self.btnTextNote1
	end
	text.addEffect(self.btnTextNote1, {color = color1})
	text.addEffect(self.btnTextNote2, {color = color2})
	text.addEffect(targetNode, {glow = {color = ui.COLORS.GLOW.WHITE}})
end

function achievementView:getAllAchievementDatas(tasks, allTasksCount)
	local t = {}
	local taskTypes = {}
	-- 总览里面的任务计数
	local finishedCount = {}
	local count = 0
	local csvTaskTab = csv.achievement.achievement_task
	for csvId,v in pairs(tasks or {}) do
		local cfg = csvTaskTab[csvId]
		local taskType = cfg.targetType2
		local targetArg = cfg.targetArg
		if not t[taskType] then
			table.insert(taskTypes, taskType)
			t[taskType] = {}
		end
		table.insert(t[taskType], {csvId = csvId, cfg = cfg, state = v[1], finishTime = v[2]})
		-- 总览里面的任务计数
		if v[1] == TASKSTATE.FINISHED or v[1] == TASKSTATE.GET then
			finishedCount[cfg.type] = (finishedCount[cfg.type] or 0) + 1
		end
	end
	table.sort(taskTypes, function(a, b)
		return a < b
	end)
	for _, data in pairs(t) do
		table.sort(data, function(a, b)
			-- 1:可领取
			if a.state == b.state and a.state == 1 then
				return a.cfg.sort < b.cfg.sort
			end
			if a.state ~= b.state then
				return a.state == 1
			end
			if a.finishTime ~= b.finishTime then
				return a.finishTime > b.finishTime
			end
			return a.csvId < b.csvId
		end)
	end
	return t, taskTypes, finishedCount
end

function achievementView:getThreeTabs(t, tasks, allListPageIdx, allTasks, taskTypes)
	local csvTaskTab = csv.achievement.achievement_task
	local count = 0
	local threeTab = {}
	if allListPageIdx == TASKPAGESTATE.WILLBE then
		local tab = {}
		for _,tasks in pairs(allTasks) do
			for taskType, vv in pairs(tasks) do
				local data, curCount
				for i,v in ipairs(vv) do
					if v.cfg.isShow and not SPECIALTYPE[taskType] then
						curCount = gGameModel.role:getAchievement(v.csvId)
						if curCount < v.cfg.targetArg then
							data = v
							break
						end
					end
				end
				if data then
					local percent = curCount / data.cfg.targetArg * 100
					local info = tasks[data.csvId] or {}
					local t = {
						flag = info[1] or TASKSTATE.DOING,
						count = curCount,
						cfg = data.cfg,
						csvId = data.csvId,
						percent = percent,
					}
					table.insert(tab, t)
					count = count + 1
				end
			end
		end
		table.sort(tab, function(a, b)
			return a.percent > b.percent
		end)
		--隐藏成就
		for i = 1, #tab do
			if tab[i].cfg.type ~= PAGETYPE.UNVISLBLEACHIEVEMENT then
				table.insert(threeTab,tab[i])
			end
			if #threeTab >= 3 then
				break
			end
		end
	else
		local tab = {}
		for _,taskType in ipairs(taskTypes) do
			local data = t[taskType][1]
			table.insert(tab, data)
		end
		table.sort(tab, function(a, b)
			return a.finishTime > b.finishTime
		end)

		for i,v in ipairs(tab) do
			if count >= 3 then
				break
			end
			local t = {}
			local cfg = csvTaskTab[v.csvId]
			t.cfg = cfg
			t.csvId = v.csvId
			local info = tasks[v.csvId]
			t.flag = info[1]
			t.count = gGameModel.role:getAchievement(v.csvId)
			table.insert(threeTab, t)
			count = count + 1
		end
	end
	return threeTab, count
end
function achievementView:addUnVisibleItem(btnDatas, tasks)
	local csvTaskTab = csv.achievement.achievement_task
	for i,v in ipairs(btnDatas) do
		if v.type == PAGETYPE.UNVISLBLEACHIEVEMENT then
			return
		end
	end
	for csvId,v in pairs(tasks) do
		local cfg = csvTaskTab[csvId]
		if cfg.type == PAGETYPE.UNVISLBLEACHIEVEMENT then
			table.insert(btnDatas, {txt = gLanguageCsv.unvislbleAchievement, enTxt = "Hide", idx = 8, type = 7, isSel =false})
			self.btnDatas:update(btnDatas)
			break
		end
	end
end

function achievementView:getRightDatas(selIdx, tasks, myTasks)
	local unVisibleTasks = {}
	local count = 0
	local rightDatas = {}
	-- 等价替换 逻辑简化
	local function isOK(taskType, curCount, finishInfo, targetArg)
		if not SPECIALTYPE[taskType] then
			if curCount < targetArg or finishInfo[1] == 1 then
				return true
			end
			return false
		end
		if curCount == 0 or curCount > targetArg or finishInfo[1] == 1 then
			return true
		end
		return false
	end
	local function getData(datas)
		local data
		local len = #datas
		for i,v in ipairs(datas) do
			local curCount = gGameModel.role:getAchievement(v.csvId)
			local finishInfo = tasks[v.csvId] or {}
			local isShows = v.cfg.type ~= 7 and v.cfg.isShow or false
			if isShows or (finishInfo[1] == TASKSTATE.GET or finishInfo[1] == TASKSTATE.FINISHED) then
				-- SPECIALTYPE 特殊判断的类型 竞技场的排名判断 相对其他的收集类判断是相反的
				if isOK(taskType, curCount, finishInfo, v.cfg.targetArg) then
					return v
				end
				data = v
			end
		end
		return data
	end
	for taskType, datas in pairs(myTasks) do
		local data = getData(datas)
		if data then
			local info = tasks[data.csvId] or {}
			local t = {}
			t.flag = info[1] or TASKSTATE.DOING
			t.count = gGameModel.role:getAchievement(data.csvId)
			t.cfg = data.cfg
			t.csvId = data.csvId
			table.insert(rightDatas, t)
			if selIdx ~= PAGENAME.UNVISLBLEACHIEVEMENT then
				count = count + 1
			elseif not itertools.isempty(info) then
				count = count + 1
				table.insert(unVisibleTasks, t)
			end
		end
	end
	if selIdx == PAGENAME.UNVISLBLEACHIEVEMENT then
		rightDatas = unVisibleTasks
	end
	table.sort(rightDatas, function(a, b)
		if a.flag == b.flag then
			return a.csvId < b.csvId
		elseif a.flag ~= TASKSTATE.FINISHED and b.flag ~= TASKSTATE.FINISHED then
			return a.flag < b.flag
		else
			return a.flag ~= TASKSTATE.FINISHED
		end
	end)
	return rightDatas, count
end

function achievementView:initModel()
	-- {csvId:state} 1可领取 0 已领取
	self.boxAward = gGameModel.role:getIdler("achievement_box_awards")
	-- {type:num}
	self.points = gGameModel.role:getIdler("achievement_points")
	-- {csvId:{[1] = flag, [2] = time}} flag:1可领取 0 已领取
	self.tasks = gGameModel.role:getIdler("achievement_tasks")
end

function achievementView:getCurLvAndNextExp(curPage)
	curPage = curPage or self.selIdx:read()
	local curLv = 0
	local targetPoint = 0
	if curPage == PAGENAME.UNVISLBLEACHIEVEMENT then
		return curLv, targetPoint
	end
	local curType = self.btnDatas:atproxy(curPage).type
	-- 默认是从0 开始的 所以要减去1
	local maxLv = itertools.size(gAchievementLevelCsv[curType]) - 1
	local targetPoint = (self.points:read() or {})[curType] or 0
	if curPage == PAGENAME.ACHIEVEMENTALL then
		targetPoint = 0
		for k,v in pairs(self.points:read() or {}) do
			targetPoint = targetPoint + v
		end
	end
	for i,v in ipairs(gAchievementLevelCsv[curType]) do
		if v.point > targetPoint then
			curLv = i - 1
			targetPoint = v.point
			break
		end
		if i == maxLv then
			curLv = i
			targetPoint = v.point
		end
	end

	return curLv, targetPoint
end

function achievementView:onClickBtn(list, k, v)
	self.selIdx:modify(function(oldVal)
		self.btnDatas:atproxy(oldVal).isSel = false
		self.btnDatas:atproxy(k).isSel = true
		return true, k
	end)
end

function achievementView:onChangeListPage(pageIdx)
	self.allListPageIdx:set(pageIdx)
end

function achievementView:onShowRank()
	gGameApp:requestServer("/game/rank",function (tb)
		gGameUI:stackUI("city.achievement_rank", nil, nil, tb.view.rank)
	end, "achievement", 0, 50)
end

function achievementView:onClickJump(list, v)
	if v.cfg.jumpTo == "" then
		return
	end
	jumpEasy.jumpTo(v.cfg.jumpTo)
end

function achievementView:onClickGet(list, k, v)
	local oldLv = self:getCurLvAndNextExp(PAGENAME.ACHIEVEMENTALL)
	local datas = gAchievementLevelCsv[self.btnDatas:atproxy(PAGENAME.ACHIEVEMENTALL).type]
	local spine1 = datas[oldLv].spine
	local showOver = {false}
	gGameApp:requestServerCustom("/game/role/achievement/task/award/get")
		:params(v.csvId)
		:onResponse(function (tb)
			local curLv = self:getCurLvAndNextExp(PAGENAME.ACHIEVEMENTALL)
			local spine2 = datas[curLv].spine
			local delay = 0
			if spine1 ~= spine2 then
				self.isLvUp = true
				if self.selIdx:read() == PAGENAME.ACHIEVEMENTALL then
					self:showLevelSpine()
					delay = DELAY.levelUp
				end
			end
			performWithDelay(self, function ()
				showOver[1] = true
			end, delay)
		end)
		:wait(showOver)
		:doit(function (tb)
			gGameUI:showGainDisplay(tb)
		end)
end

function achievementView:showLevelSpine()
	local curType = self.btnDatas:atproxy(self.selIdx).type
	local curTypeDatas = gAchievementLevelCsv[curType] or {}
	local curLv = self:getCurLvAndNextExp()
	local cfg = curTypeDatas[curLv] or {}
	local effectName = cfg.spine
	local actionStandbyName = ACTION_STANDBY[effectName]
	self.imgIcon:visible(not actionStandbyName)
	if not self.rightAllInfo:getChildByName("flag") and actionStandbyName then
		widget.addAnimationByKey(self.rightAllInfo, "chengjiu/chengjiutubiaotexiao.skel", "flag", actionStandbyName, 1)
			:scale(2)
			:xy(196, 100)
	end
	if self.isLvUp then
		self.isLvUp = false
		local effect = self.rightAllInfo:getChildByName("effect")
		if not effect then
			effect = widget.addAnimationByKey(self.rightAllInfo, "chengjiu/chengjiutubiaotexiao.skel", "effect", effectName, 6)
				:scale(2)
				:xy(196, 100)
		else
			effect:show()
			effect:play(effectName)
		end
		effect:setSpriteEventHandler(function(event, eventArgs)
			effect:hide()
		end, sp.EventType.ANIMATION_COMPLETE)
	end
end

function achievementView:onGetBoxGift(pageIdx)
	if not self.curBoxReward then
		local curType = self.btnDatas:atproxy(self.selIdx:read()).type
		local curLv, nextLvPoint = self:getCurLvAndNextExp()
		local isMax = isMaxLevel(curType, curLv)
		local str = string.format(gLanguageCsv.needTargetAchievementLv, curLv + 1)
		if BOXTYPE.OTHER == pageIdx then
			str = string.format(gLanguageCsv.needTargetAchievementPoint, nextLvPoint)
		end
		if not isMax then
			local reward = getNextLvReward(curType, curLv)
			gGameUI:showBoxDetail({
				data = reward,
				content = str,
				state = 1
			})
		end
		return
	end
	gGameApp:requestServer("/game/role/achievement/box/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.curBoxReward.csvId)
end

function achievementView:onCleanup()
	self._selIdx = self.selIdx:read()
	ViewBase.onCleanup(self)
end


return achievementView
