--翻牌赢头奖

-- 未达成，已完成，达成部分
local STATE_TYPE = {
	geted = 0,
	unfinished = 0.5,
	finished = 1,
}

local STATE_CARD = {
	covered = 1 ,
	gain = 2,
}
local BIND_EFFECT= {
	event = "effect",
	data = {outline = {color = cc.c4b(130,33,30,255),  size = 3}}
}
local GIFTSTATE = {
	notGet = 1,
	get = 2,
}
local LINE_NUM = 4
local ITEM_BG = 16
local ActivityNewYearFlipCardView = class("ActivityNewYearFlipCardView", Dialog)

ActivityNewYearFlipCardView.RESOURCE_FILENAME = "activity_new_year_flip_card.json"
ActivityNewYearFlipCardView.RESOURCE_BINDING = {
	["bg.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["leftPanel"] = "leftPanel",
	["leftPanel.rulePanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRules")},
		},
	},
	["coverPanel"] = "coverPanel",
	["rightPanel"] = "rightPanel",
	["rightPanel.taskText"] = {
		varname = "taskText",
		binds = BIND_EFFECT,
	},
	["rightPanel.taskTextNum"] = {
		varname = "taskTextNum",
		binds = BIND_EFFECT,
	},
	["rightPanel.taskBar"] = {
		varname = "taskBar",
		binds = BIND_EFFECT,
	},
	["rightPanel.title"] = {
		varname = "title",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(255,248,230,255),  size = 8}}
		},
	},
	["rightPanel.title1"] = {
		varname = "title1",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(255,248,230,255),  size = 8}}
		},
	},
	["rightPanel.itemTask"] = "itemTask",
	["rightPanel.taskList"] = {
		varname = "taskList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("teskDatas"),
				-- asyncPreload = 4,
				item = bindHelper.self("itemTask"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("text", "icon", "itemList", "btn", "downIcon", "textBar")
					bind.touch(list,childs.btn,{methods = {ended = functools.partial(list.clickCell, k, v)}})
					uiEasy.createItemsToList(list, childs.itemList, v.award, {scale = 0.75, margin = 6})
					text.addEffect(childs.icon:get("num"), {outline = {color = cc.c4b(130,33,30,255), size = 3}})
					childs.icon:get("num"):text(v.id)
					childs.text:text(v.text)
					childs.downIcon:visible(v.state == STATE_TYPE.geted)
					childs.textBar:visible(v.state ~= STATE_TYPE.geted)
					childs.btn:visible(v.state ~= STATE_TYPE.geted)
					childs.textBar:text(v.num.."/"..v.allNum)
					if v.state == STATE_TYPE.finished then
						text.addEffect(childs.textBar, {color=cc.c4b(96,196,86,255)})
						childs.btn:get("text"):text(gLanguageCsv.commonTextGet)
					else
						if v.jumpTo == "" then
							childs.btn:hide()
							childs.textBar:y(100)
						else
							childs.btn:get("text"):text(gLanguageCsv.goTo)
						end
					end
				end,
				-- preloadCenterIndex = bindHelper.self("centerIndex"),
			},
			handlers = {
				clickCell = bindHelper.self("onJump"),
			},
		},
	},
	["leftPanel.list2"] = "subList",
	["leftPanel.item"] = "itemSmall",
	["leftPanel.list"] = {
		varname = "listCenter",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("showdata"),
				columnSize = LINE_NUM,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("itemSmall"),
				margin = 0,
				preloadCenter = 5,
				onCell = function(list, node, k, v)
					bind.touch(list,node,{methods = {ended = functools.partial(list.clickCell, v)}})
					local childs = node:multiget("bg", "bg1", "frame")
					childs.bg1:texture(v.res)
					childs.bg:get("num"):text(v.id)
					childs.frame:visible(v.isFrame)
					text.addEffect(childs.bg:get("num"), {outline = {color = cc.c4b(130,33,30,255), size = 3}})
					if v.isSelected == true and v.state ~= STATE_CARD.covered then
						local j = list:getIdx(k)
						childs.bg1:visible(false)
						gGameUI:disableTouchDispatch(nil, false)
						node:runAction(cc.Sequence:create(
							cc.CallFunc:create(function()
								childs.bg:visible(true)
								childs.bg1:visible(false)
							end),
							cc.ScaleTo:create(0.3, 0.01, 1),
							cc.CallFunc:create(function()
								childs.bg:visible(false)
							end),
							cc.CallFunc:create(function()
								childs.bg:visible(false)
								childs.bg1:visible(true)
							end),
							cc.ScaleTo:create(0.1, 1, 1)
						))
						childs.bg:visible(false)
					else
						if v.state == STATE_CARD.covered then
							childs.bg1:show()
							childs.bg:hide()
							node:setTouchEnabled(false)
						else
							node:setTouchEnabled(true)
							childs.bg:show()
							childs.bg1:hide()
						end
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("getTaskNum"),
			},
		},
	}
}
function ActivityNewYearFlipCardView:onCreate(activityId)
	self:initModel()
	self.yyCfg = csv.yunying.yyhuodong[activityId]
	self.huodongID = self.yyCfg.huodongID

	self.activityId = activityId
	self.teskDatas = idlers.new()
	self.showdata = idlers.newWithMap({}) -- 单个刷新
	self.taskData = csv.yunying.jifu_task
	local awarkData = csv.yunying.jifu_award
	-- local maxAward = dataEasy.getItemData(self.yyCfg.paramMap.maxAward)
	local maxAward = {}
	for k, v in csvMapPairs(self.yyCfg.paramMap.maxAward) do
		if k == "cards" then
			for _, id in ipairs(v) do
				table.insert(maxAward, {key = "card", num = id})
			end
		else
			table.insert(maxAward, {key = k, num = v})
		end
	end
	for i = 1, 4 do
		if maxAward[i].key == "card" then
			bind.extend(self, self.rightPanel:get("itemBg"..i), {
				class = "icon_key",
				props = {
					data = maxAward[i],
					-- noListener = true,
					onNode = function(node)
						node:scale(0.6)
					end,
				},
			})
		else
			bind.extend(self, self.rightPanel:get("itemBg"..i), {
				class = "icon_key",
				props = {
					data = {
						key = maxAward[i].key,
					},
					-- noListener = true,
					simpleShow = true,
					onNode = function(node)
						node:scale(0.8)
					end,
				},
			})
		end
	end
	-- --时间
	self:updateTime()

	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		self.yyData = yyhuodongs[activityId] or {}
		--领取奖励的个数
		local showEndGift = false
		for k, v in csvPairs(self.taskData) do
			if self.yyData.stamps and self.yyData.stamps[k] == 0 then
				showEndGift = true
			else
				showEndGift = false
				break
			end
		end
		if showEndGift and self.yyData.link_award[0] == 1 then
			self:showEnd()
		else
			self.coverPanel:hide()
		end
		for k, v in csvPairs(awarkData) do
			if v.huodongID == self.huodongID then
				self.leftPanel:get("btn"..v.awardID):setTouchEnabled(true)
				bind.touch(self.leftPanel,self.leftPanel:get("btn"..v.awardID),{methods = {ended = functools.partial(self.getLinkGift, self, k, v)}})
				if self.yyData.link_award and self.yyData.link_award[v.awardID] == 0 then
					cache.setShader(self.leftPanel:get("btn"..v.awardID), false, "gray")
					self.leftPanel:get("btn"..v.awardID):get("icon"):texture(v.icon..GIFTSTATE.notGet..".png")
				else
					cache.setShader(self.leftPanel:get("btn"..v.awardID), false, "normal")
					self.leftPanel:get("btn"..v.awardID):get("icon"):texture(v.icon..GIFTSTATE.get..".png")
					if self.yyData.link_award and self.yyData.link_award[v.awardID] == 1 then
						widget.addAnimationByKey(self.leftPanel:get("btn"..v.awardID), "effect/jiedianjiangli.skel", "rewardEffect"..v.awardID, "effect_loop", 1)
							:xy(62, 30)
							:scale(0.45)
					else
						self.leftPanel:get("btn"..v.awardID):get("icon"):texture(v.icon..GIFTSTATE.notGet..".png")
						if self.leftPanel:get("btn"..v.awardID):getChildByName("rewardEffect"..v.awardID) then
							self.leftPanel:get("btn"..v.awardID):getChildByName("rewardEffect"..v.awardID):removeSelf()
						end
					end
				end
			end
		end
		self:updateTask()
	end)
	self:updateFlipCard()
	Dialog.onCreate(self)
end

function ActivityNewYearFlipCardView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.clickId = 0
	self.task = {}
	--记录跳转时的位置
	self.jumpPos = 0
	-- self.centerIndex = 0
end

function ActivityNewYearFlipCardView:showEnd()
	self.coverPanel:show()
	self.coverPanel:get("icon"):texture(self.yyCfg.paramMap.maxAwardRes..GIFTSTATE.get..".png")
	widget.addAnimationByKey(self.coverPanel, "effect/jiedianjiangli.skel", "rewardEffect", "effect_loop", 1)
		:xy(510, 370)
		:scale(1)
		self.coverPanel:onClick(functools.partial(self.getLinkGift, self, nil, {awardID = 0}))
end

function ActivityNewYearFlipCardView:getTaskNum(list, v)
	if self.clickId ~= 0 then
		self.showdata:atproxy(self.clickId).isFrame = false
	end
	self.showdata:atproxy(v.id).isFrame = true
	self.clickId = v.id
	for key, val in ipairs(self.task) do
		if val.id == v.id then
			self.taskList:jumpToItem(key - 1, cc.p(0, 1), cc.p(0, 1))
			-- self.centerIndex = key
			-- self:updateTask()
			return
		end
	end
end

function ActivityNewYearFlipCardView:getLinkGift(k, v)
	if self.yyData.link_award and self.yyData.link_award[v.awardID] == 1 then
		gGameApp:requestServer("/game/yy/link/award/get", function(tb)
			if self.leftPanel:get("btn"..v.awardID) then
				if self.leftPanel:get("btn"..v.awardID):getChildByName("rewardEffect"..v.awardID) then
					self.leftPanel:get("btn"..v.awardID):getChildByName("rewardEffect"..v.awardID):removeSelf()
				end
			else
				if self.coverPanel:getChildByName("rewardEffect") then
					self.coverPanel:getChildByName("rewardEffect"):removeSelf()
				end
			end
			gGameUI:showGainDisplay(tb)
		end, self.activityId, v.awardID)
	elseif self.yyData.link_award and self.yyData.link_award[v.awardID] == 0 then
		gGameUI:showBoxDetail({
			data = v.award,
			content = gLanguageCsv.newYearFlipCardText,
			state = 0,
		})
	else
		gGameUI:showBoxDetail({
			data = v.award,
			content = gLanguageCsv.newYearFlipCardText,
			state = 1,
		})
	end
	-- self.coverPanel:show()
end

function ActivityNewYearFlipCardView:onRules()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function ActivityNewYearFlipCardView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(161),
        c.noteText(115001, 115015),
    }
    return context
end

function ActivityNewYearFlipCardView:onJump(list, k, v)
	if v.state == STATE_TYPE.finished then
		self.jumpPos = 0
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			self.showdata:atproxy(v.id).isSelected = true
			self.showdata:atproxy(v.id).isFrame = false
			performWithDelay(self, function()
				gGameUI:disableTouchDispatch(nil, true)
				self.showdata:atproxy(v.id).state = STATE_CARD.covered
				gGameUI:showGainDisplay(tb)
			end, 0.7)
		end, self.activityId, v.csvId)
	else
		self.jumpPos = v.id
		if v.jumpTo ~= nil then
			jumpEasy.jumpTo(v.jumpTo)
		end
	end
end

--更新时间
function ActivityNewYearFlipCardView:updateTime()
	local yyEndtime = gGameModel.role:read("yy_endtime")
	local countdown = yyEndtime[self.activityId] - time.getTime()
	bind.extend(self, self.taskTextNum, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			endFunc = function()
				self.taskTextNum:text(gLanguageCsv.activityOver)
			end,
		}
	})
end

--任务更新
function ActivityNewYearFlipCardView:updateTask()
	--任务列表
	local task = {}
	local valsums = gGameModel.role:getYYHuoDongTasksProgress(self.activityId) or {}
	-- local valsums = self.yyData.valsums or {}
	local stamps = self.yyData.stamps or {}
	local taskNum  = 0
	local taskDownNum = 0
	for k, v in csvPairs(self.taskData) do
		if v.huodongID == self.huodongID then
			taskNum = taskNum + 1
			local num = valsums[k][1] or 0
			local state = stamps[k] or 0.5
			table.insert(task,{csvId = k, text = v.desc, award = v.award, jumpTo = v.goTo, num = num, state = state, id = v.boardID, allNum = v.taskParam})
			if stamps[k] then
				taskDownNum = taskDownNum + 1
			end
		end
	end
	table.sort(task, function(a, b)
		if a.state ~= b.state then
			return a.state > b.state
		end
		return a.csvId < b.csvId
	end)
	self.task = task
	self.teskDatas:update(task)
	for key, val in ipairs(self.task) do
		if val.id == self.jumpPos then
			self.taskList:jumpToItem(key - 1, cc.p(0, 1), cc.p(0, 1))
			break
		end
	end
	self.taskBar:text(string.format(gLanguageCsv.taskRate, taskDownNum, taskNum))
end

--更新翻牌界面
function ActivityNewYearFlipCardView:updateFlipCard()
	local detail = {}
	local stamps = self.yyData.stamps or {}
	if self.task[1].state ~= STATE_TYPE.geted then
		self.clickId = self.task[1].id
	end
	for i=1, ITEM_BG do
		local csvId = self:getCsvId(i)
		if stamps[csvId] == STATE_TYPE.geted then
			table.insert(detail, {id = i, csvId = csvId, state = STATE_CARD.covered, res = self.yyCfg.paramMap.cardRes..i..".png", isSelected = true, isFrame = i == self.clickId})
		else
			table.insert(detail, {id = i, csvId = csvId, state = STATE_CARD.gain, res = self.yyCfg.paramMap.cardRes..i..".png", isSelected = false, isFrame = i == self.clickId})
		end
	end
	self.detail = detail
	self.showdata:update(detail)
end

function ActivityNewYearFlipCardView:getCsvId(i)
	for k, v in csvPairs(self.taskData) do
		if i == v.boardID then
			return k
		end
	end
end

return ActivityNewYearFlipCardView