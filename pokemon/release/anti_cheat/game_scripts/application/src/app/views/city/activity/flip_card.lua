--翻牌赢头奖

-- 未达成，已完成，达成部分
local STATE_TYPE = {
	unfinished = 1,
	finished = 2,
}

local STATE_CARD = {
	covered = 1 ,
	gain = 2,
}
local BIND_EFFECT= {
	event = "effect",
	data = {outline = {color = cc.c4b(221,77,47,255),  size = 4}}
}
local LINE_NUM = 4
local ITEM_BG = 16
local SHOW_NUM = 8
local ActivityFlipCardView = class("ActivityFlipCardView", Dialog)

ActivityFlipCardView.RESOURCE_FILENAME = "activity_flip_card.json"
ActivityFlipCardView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["bg.text"] = {
		binds = BIND_EFFECT,
    },
    ["leftPanel.time"] = {
		varname = "time",
		binds = BIND_EFFECT,
    },
    ["leftPanel.time1"] = {
		varname = "timeText",
		binds = BIND_EFFECT,
    },
    ["leftPanel.freeTextSy"] = {
		varname = "freeTextSy",
		binds = BIND_EFFECT,
    },
    ["leftPanel.text"] = {
		varname = "text",
		binds = BIND_EFFECT,
    },
    ["leftPanel.freeTextNum"] = {
		varname = "freeTextNum",
		binds = BIND_EFFECT,
    },
    ["rightPanel.taskTextNum"] = {
		varname = "taskTextNum",
		binds = BIND_EFFECT,
	},
	["rightPanel.taskText"] = {
		varname = "taskText",
		binds = BIND_EFFECT,
	},
	["rightPanel.noneItem"] = "noneItem",
	["coverPanel.finish"] = {
		varname = "finishText",
		binds = BIND_EFFECT,
    },
    ["leftPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRules")}
		}
    },
	["icon"] = "iconTJ",
	["coverPanel"] = "coverPanel",
	["coverPanel.btnNextRound"] = {
		varname = "btnNextRound",
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onNextRound')}
		}
	},
	["rightPanel.dailyTimes"] = "dailyTimes",
	["rightPanel.itemTJHX"] = "itemTJHX",
	["rightPanel.listHX"] = {
		varname = "listHX",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("itemTJHX"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
						}
					})
				end,
			}
		},
	},
	["rightPanel.itemTask"] = "itemTask",
	["rightPanel.textChallenge"] = "textChallenge",
	["rightPanel.taskList"] = {
		varname = "taskList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("teskDatas"),
				item = bindHelper.self("itemTask"),
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("text","textNum1","finish","go","bar")
					childs.text:text(v.text)
					childs.textNum1:text("+"..v.award)
					if v.state == STATE_TYPE.finished then
						childs.go:visible(false)
						childs.bar:visible(false)
						childs.finish:visible(true)
					else
						if v.jumpTo == "" then
							childs.go:visible(false)
						else
							childs.go:visible(true)
							bind.touch(list,node,{methods = {ended = functools.partial(list.clickCell, v.jumpTo)}})
						end
						childs.bar:visible(true)
						childs.finish:visible(false)
						childs.bar:text(v.cnt.."/"..v.taskTimes)
					end
				end,
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
				preloadCenter = 5,
				onCell = function(list, node, k, v)
					if v.isSelected == true then
						local j = list:getIdx(k)
						local childs = node:multiget("bg","itemPanel")
						local award = {}
						award[v.key] = v.num
						node:get("itemPanel"):visible(false)
						gGameUI:disableTouchDispatch(nil, false)
						node:runAction(cc.Sequence:create(
							cc.CallFunc:create(function()
								childs.bg:texture(v.res)
								childs.bg:visible(true)
								childs.itemPanel:visible(false)
							end),
							cc.ScaleTo:create(0.3, 0.01, 1),
							cc.CallFunc:create(function()
								childs.bg:visible(false)
							end),
							bind.extend(list, childs.itemPanel, {
								class = "icon_key",
								props = {
									data = {
										key = v.key,
										num = v.num or 0,
									},
									onNode = function(panel)
										panel:scale(1.1)
									end,
								},
							}),
							cc.CallFunc:create(function()
								childs.itemPanel:visible(true)
								widget.addAnimation(node,"xingyunlefantian/fanpai_gy.skel","effect",20)
									:xy(107,107)
							end),
							cc.ScaleTo:create(0.1, 1, 1)
						))
						childs.bg:visible(false)
					else
						if v.state == STATE_CARD.covered then
							node:get("bg"):texture(v.res)
							local j = list:getIdx(k)
							node:get("itemPanel"):setTouchEnabled(false)
							bind.touch(list,node,{methods = {ended = functools.partial(list.clickGet,node,j.k)}})
						elseif v.state == STATE_CARD.gain and v.isSelected ~= true then
							local childs = node:multiget("bg","itemPanel")
							childs.bg:visible(false)
							bind.extend(list, childs.itemPanel, {
								class = "icon_key",
								props = {
									data = {key = v.key, num = v.num},
									onNode = function(panel)
										panel:scale(1.1)
									end,
								},

							})
						end
					end
				end,
			},
			handlers = {
				clickGet = bindHelper.self("flipCard"),
			},
		},
	}
}
function ActivityFlipCardView:onCreate(activityId)
	self:initModel()
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	self.huodongID = huodongID
	self.yyCfg = yyCfg
	self.cloneIcon = nil

	self.activityId = activityId
	self.teskDatas = idlers.new()
	self.itemDatas = idlers.newWithMap({})
	self.showdata = idlers.newWithMap({}) -- 单个刷新
	local roundMax = 0
	for i,v in csvPairs(csv.yunying.flop_rounds) do
		if v.huodongID == huodongID and v.type == 1 then
			roundMax = roundMax + 1
		end
	end
	self.roundMax = roundMax
	local yyData = self.yyhuodongs:read()[activityId] or {}
	self.lastRoundId = yyData.info.roundID --上一轮id
	--时间
	self:updateTime()
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yyData = yyhuodongs[activityId] or {}
		self.yyData = yyData
		--当前轮次头奖
		self:updateFirstAward()
		--后续奖励
		-- self:updateSecondAward()
		local itemList ={}
		local num = 0
		if self.yyData.info.roundID + SHOW_NUM > self.roundMax then
			num = self.roundMax
		else
			num = self.yyData.info.roundID + SHOW_NUM
		end
		for t = yyData.info.roundID + 1,num do
			for i,v in csvPairs(csv.yunying.flop_rounds) do
				if v.type == 1 and v.huodongID == huodongID then
					for k,val in csvMapPairs(v.rounds) do
						if val == t then
							local key,num = next(v.award)
							table.insert(itemList,{
								id = t,
								key = key,
								num = num,
							})
						end
					end
				end
			end
		end
		self.itemTask:visible(false)
		if self.lastRoundId == yyData.info.roundID then
			self.itemDatas:update(itemList)
		end
		self.noneItem:visible(false)
		if #itemList == 0 and self.lastRoundId == yyData.info.roundID then
			self.noneItem:visible(true)
		end
		--免费和任务次数
		self:updateTask()
		--翻牌初始化
		self:updateFlipCard()

		self.itemSmall:visible(false)
		self.listCenter:xy(390,80)
		--轮次结束
		self:gameOver()
	end)
	Dialog.onCreate(self)
end

function ActivityFlipCardView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.clickId = idler.new(0)
end

function ActivityFlipCardView:onRules()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function ActivityFlipCardView:getRuleContext(view)
    local c = adaptContext
    local context = {
        c.clone(view.title, function(item)
            item:get("text"):text(gLanguageCsv.rules)
        end),
        c.noteText(149),
        c.noteText(104001, 104010),
    }
    return context
end

-- 点击发送翻牌消息
function ActivityFlipCardView:flipCard(list,node,id)
	self.id = id
	if self.freeTextNum:text() == "0" and self.taskTextNum:text() == "0" then
		gGameUI:showTip(gLanguageCsv.flipCardNoTimes)
		return
	end

	gGameApp:requestServer("/game/yy/award/get", function(tb)
		performWithDelay(self, function()
			gGameUI:disableTouchDispatch(nil, true)
			gGameUI:showGainDisplay(tb)
		end, 1)
		for i = 1,ITEM_BG do
			self.detail[i].isSelected = false
		end
		local data = dataEasy.getItemData(tb.view.result)[1]
		self.detail[id] = {id = id,key = data.key,num = data.num,state = STATE_CARD.gain,res = self.yyCfg.clientParam.res..id..".png",isSelected = true}
		self.showdata:update(self.detail)
		self.lastRoundId = self.yyData.info.roundID
	end, self.activityId,self.huodongID,id)
end

function ActivityFlipCardView:onJump(list,data)
	if data ~= nil then
		jumpEasy.jumpTo(data)
	end
end

--更新时间
function ActivityFlipCardView:updateTime()
	local yyEndtime = gGameModel.role:read("yy_endtime")
		local countdown = yyEndtime[self.activityId] - time.getTime()
		bind.extend(self, self.time, {
			class = 'cutdown_label',
			props = {
				time = countdown,
				endFunc = function()
					self:gameOver()
					self.time:text(gLanguageCsv.activityOver)
				end,
			}
		})
		adapt.oneLinePos(self.timeText, self.time, cc.p(15, 0))
end


--更新头奖
function ActivityFlipCardView:updateFirstAward()
	if self.lastRoundId == self.yyData.info.roundID then
		for i,v in orderCsvPairs(csv.yunying.flop_rounds) do
			if v.huodongID == self.huodongID and v.type == 1 then
				local k, val = next(v.rounds)
				if val == self.yyData.info.roundID then
					if self.cloneIcon then--不同卡 绑定同一个card_icon 会报错--todo
						self.cloneIcon:removeFromParent()
						self.cloneIcon = nil
					end
					self.cloneIcon = self.iconTJ:clone():addTo(self.iconTJ:getParent())
					self.cloneIcon:xy(self.iconTJ:xy())

					bind.extend(self, self.cloneIcon, {
						class = "icon_key",
						props = {
							data = dataEasy.getItemData(v.award)[1],
						}
					})

					if self.lastRoundId == 0 and self.lastRoundId == self.yyData.info.roundID - 1 then
						self.bigAward = v.award
					elseif self.lastRoundId == self.yyData.info.roundID then
						self.bigAward = v.award
					end
						return
				end
			end
		end
	end
end
--更新后续奖励
function ActivityFlipCardView:updateSecondAward()
	local itemList = {}
	local num = 0
	if self.yyData.info.roundID + SHOW_NUM > self.roundMax then
		num = self.roundMax
	else
		num = self.yyData.info.roundID + SHOW_NUM
	end
	for t = self.yyData.info.roundID + 1,num do
		for i,v in csvPairs(csv.yunying.flop_rounds) do
			if v.type == 1 and v.huodongID == self.huodongID then
				for k,val in csvMapPairs(v.rounds) do
					local key,num = next(v.award)
					if val == t then
						local data = dataEasy.getItemData(v.award)[1],
						table.insert(itemList,{
							id = t,
							key = key,
							num = num,
						})
					end
				end
			end
		end
	end
	self.itemDatas:update(itemList)
end
--任务更新
function ActivityFlipCardView:updateTask()
	self.freeTextNum:text(self.yyCfg.paramMap.free - self.yyData.info.cost_free_times)
	adapt.oneLinePos(self.freeTextSy,{self.freeTextNum,self.text},{cc.p(5,0),cc.p(10,0)})
	self.taskTextNum:text(self.yyData.info.task_times - self.yyData.info.cost_task_times)
	adapt.oneLinePos(self.taskText,self.taskTextNum,cc.p(3,0))
	--今日完成次数
	local content = "#C0x5C545C#("..gLanguageCsv.dailyTaskTimes.."#C0x36AB27#"
	--任务列表
	local task = {}
	local times = gGameModel.role:getYYHuoDongTasksProgress(self.activityId) or {}
	local finishedTime = self.yyData.valinfo or {}
	local taskSum = 0
	local taskFinishedTimes = 0
	for k, v in csvPairs(csv.yunying.flop_task) do
		if v.huodongID == self.huodongID then
			local state = STATE_TYPE.unfinished
			local cnt = times[k][1] or 0

			local finishedTimes = finishedTime[k] and finishedTime[k].count or 0
			local taskTimes = v.taskParam
			taskSum = taskSum + v.times
			taskFinishedTimes = taskFinishedTimes + finishedTimes
			if v.times > 1 then
				taskTimes = v.times
				if finishedTimes >= taskTimes then
					state = STATE_TYPE.finished
			end
				cnt = finishedTimes
			end
			if v.times == 1 then
				if cnt >= taskTimes then
					state = STATE_TYPE.finished
				end
			end
			table.insert(task,{csvId = k,text = v.desc,award = v.award,jumpTo = v.jumpTo,taskTimes = taskTimes,state = state,cnt = cnt})
		end
	end
	self.teskDatas:update(task)
	content = content..taskFinishedTimes.."/".."#C0x5C545C#"..taskSum..")"
	self.dailyTimes:removeChildByName("richText")
	local richText = rich.createWithWidth(content,40,nil,1100)
		:xy(-20,15)
		:anchorPoint(0, 0.5)
		:addTo(self.dailyTimes,1,"richText")
end
--活动结束
function ActivityFlipCardView:gameOver()
	if self.yyData.info.roundID > self.roundMax and self.lastRoundId == self.roundMax then
		performWithDelay(self, function()
			self.coverPanel:visible(true)
			bind.click(self, self.coverPanel, {method = function()
				gGameUI:showTip(gLanguageCsv.flipCardFinishedClickTip)
			end})
			self.taskList:setTouchEnabled(false)
			for _, child in pairs(self.taskList:getChildren()) do
				child:setTouchEnabled(false)
			end
			self.btnNextRound:visible(false)
			self.noneItem:visible(true)
			self.finishText:text(gLanguageCsv.flipCardFinished)
		end, 1)
	end
	if self.yyData.info.roundID > self.roundMax and self.lastRoundId == self.yyData.info.roundID then
		self.coverPanel:visible(true)
		bind.click(self, self.coverPanel, {method = function()
			gGameUI:showTip(gLanguageCsv.flipCardFinishedClickTip)
		end})
		self.noneItem:visible(true)
		self.btnNextRound:visible(false)
		self.finishText:text(gLanguageCsv.flipCardFinished)
		self.taskList:visible(false)
		self.textChallenge:visible(false)
		self.dailyTimes:visible(false)
		self.taskTextNum:visible(false)
		self.taskText:visible(false)
		self.freeTextNum:visible(false)
		self.freeTextSy:visible(false)
		self.text:visible(false)
	end
end

function ActivityFlipCardView:onNextRound()
	local t = {}
	for i=1,ITEM_BG do
		t[i] = {id = i,state = STATE_CARD.covered,res = self.yyCfg.clientParam.res..i..".png", isSelected = false}
	end
	self.coverPanel:visible(false)
	self.showdata:update(t)
	self.detail = t
	self:updateFirstAward()
	self:updateSecondAward()
end
--更新翻牌界面
function ActivityFlipCardView:updateFlipCard()
	local detail = {}
	for i=1,ITEM_BG do
		if self.yyData.info.roundID <= self.roundMax then
			if self.yyData.stamps and self.yyData.stamps[i] ~= nil then
				for k, v in csvPairs(csv.yunying.flop_rounds) do
					if v.huodongID == self.huodongID and k == self.yyData.stamps[i] then
						for key,num in csvMapPairs(v.award) do
							detail[i] = {id = i,key = key,num = num,state = STATE_CARD.gain,res = self.yyCfg.clientParam.res..i..".png"}
						end
					end
				end
			else
				detail[i] = {id = i,state = STATE_CARD.covered,res = self.yyCfg.clientParam.res..i..".png"}
			end
		else
			detail[i] = {id = i,state = STATE_CARD.covered,res = self.yyCfg.clientParam.res..i..".png"}
		end
	end
	if self.lastRoundId == self.yyData.info.roundID and self.yyData.info.roundID <= self.roundMax then
		self.showdata:update(detail)
		self.detail = detail
		self.coverPanel:visible(false)
	elseif self.lastRoundId < self.yyData.info.roundID and self.yyData.info.roundID == self.roundMax then
		performWithDelay(self, function()
			self.coverPanel:visible(true)
			self.btnNextRound:visible(true)
		end, 1)
	elseif self.lastRoundId < self.yyData.info.roundID and self.yyData.info.roundID < self.roundMax then
		performWithDelay(self, function()
			self.coverPanel:visible(true)
			self.btnNextRound:visible(true)
		end, 1)
	elseif self.lastRoundId == self.yyData.info.roundID and self.yyData.info.roundID > self.roundMax then
		self.showdata:update(detail)
		self.detail = detail
	end
end

return ActivityFlipCardView