-- @date:   2019-07-08
-- @desc:   派遣任务-选择精灵界面
local dispatchtaskTools = require "app.views.city.adventure.dispatch_task.tools"
--筛选
local function filterData(data, condition)
	if next(data) == nil then
		return {}
	end
	if condition == nil or condition[2] == nil then
		return data
	end
	local function isOK(data, key, val)
		if data[key] == nil then
			if key ~= "attr2" or data.attr1 == val then
				return true
			end
		end
		if key == "atkType" then
			for k, v in ipairs(data.atkType) do
				if val[v] then
					return true
				end
			end
			return false
		end
		if data[key] == val then
			return true
		end
		return false
	end
	local tmp = {}
	for k,v in pairs(data) do
		if isOK(v, condition[1], condition[2]) then
			tmp[k] = v
		end
	end
	return tmp
end
local function setTaskCardDatas(cardNums, taskCardDatas, cardDatas)
	for i=1,cardNums do
		local taskCardData = taskCardDatas:atproxy(i)
		if not cardDatas.selectState then
			if cardDatas.dbid == taskCardData.dbid then
				taskCardData.selectState = false
				return i
			end
		else
			if cardDatas.dbid ~= taskCardData.dbid and not taskCardData.selectState then
				taskCardData.selectState = true
				taskCardData.id = cardDatas.id
				taskCardData.unitId = cardDatas.unitId
				taskCardData.rarity = cardDatas.rarity
				taskCardData.attr1 = cardDatas.attr1
				taskCardData.attr2 = cardDatas.attr2
				taskCardData.level = cardDatas.level
				taskCardData.star = cardDatas.star
				taskCardData.advance = cardDatas.advance
				taskCardData.fight = cardDatas.fight
				taskCardData.dbid = cardDatas.dbid
				return i
			end
			if cardDatas.dbid == taskCardData.dbid and not taskCardData.selectState then
				taskCardData.selectState = true
				return i
			end
		end
	end
	return 1
end

local function filterDo(data, conditions)
	local result = data
	for i = 1, #conditions do
		result = filterData(result, conditions[i])
	end
	return result
end

local CONDITION_TYPE = {
	{name = "star", note = gLanguageCsv.manyStars},
	{name = "advance", note = gLanguageCsv.manyClasses},
	{name = "rarity", note = gLanguageCsv.manyQualifications}
}
local function setCardIcon(list, node, v, typ)
	local grayState = 0
	if not typ then
		if v.selectState then
			grayState = 1

		elseif v.status ~= 0 then
			grayState = 2
		end
	end
	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = v.unitId,
			advance = v.advance,
			rarity = v.rarity,
			star = v.star,
			grayState = grayState,
			levelProps = {
				data = v.level,
			},
			onNode = function (panel)
				if typ then
					panel:visible(v.selectState == true)
				end
			end,
		}
	})
end
-- 任务服务器1已完成 2可接取 3进行中
-- 卡牌status 0没派遣 1派遣中 2休息中
local function getCardState(dispatchTasks, dispatchCardIDs)
	local status = {}
	for _,v in ipairs(dispatchTasks) do
		for _,cardDbid in pairs(v.cardIDs or {}) do
			if v.status == 1 then
				status[cardDbid] = 2
			end
			if v.status == 3 then
				status[cardDbid] = 1
			end
		end
	end
	for _,v in ipairs(dispatchCardIDs) do
		if not status[v] then
			status[v] = 2
		end
	end
	return status
end


local DispatchTaskSpriteSelectView = class("DispatchTaskSpriteSelectView", cc.load("mvc").ViewBase)
DispatchTaskSpriteSelectView.RESOURCE_FILENAME = "dispatch_task_sprite_select.json"
DispatchTaskSpriteSelectView.RESOURCE_BINDING = {
	["filter"] = "filter",
	["empty"] = "empty",
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				columnSize = 5,
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				empty = bindHelper.self("empty"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					setCardIcon(list, node, v)
					node:get("icon"):visible(v.weight > 0)
					local maskTxt = v.status == 2 and gLanguageCsv.restIn or gLanguageCsv.InDispatch
					if v.selectState or v.status == 0 then
						maskTxt = gLanguageCsv.inTheTeam
					end
					node:get("mask.imgMask"):hide()
					local textNote = node:get("mask.textNote")
					textNote:text(maskTxt)
					uiEasy.addTextEffect1(textNote)
					node:get("mask"):visible(v.selectState or v.status ~= 0)
					node:setTouchEnabled(v.status == 0)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick,list:getIdx(k), v)}})
				end,
				asyncPreload = 25,
				onBeforeBuild = function(list)
					list.empty:visible(itertools.size(list.data) == 0)
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onCardItemClick"),
			},
		},
	},
	["btnSort"] = {
		varname = "btnSort",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnSortClick")}
		},
	},
	["btnSort.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.cardPanel.list"] = {
		varname = "taskCardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("taskCardDatas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					setCardIcon(list, node, v, true)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k, v)}})
					node:get("mask"):visible(false)
					node:get("icon"):visible(false)
				end,
				asyncPreload = 5,
				-- preloadCenter = bindHelper.self("selectCsvId"),
			},
			handlers = {
				itemClick = bindHelper.self("onTaskItemClick"),
			},
		},
	},
	["rightPanel.cardPanel.btnOneKey"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onOneKeyClick")}
		},
	},
	["attrItem"] = "attrItem",
	["rightPanel.btnStart"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnStart")}
		},
	},
	["rightPanel.btnStart.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
}

function DispatchTaskSpriteSelectView:onCreate(taskData)
	self:initModel()
	self.taskData = taskData
	self.rightPanel:get("attrList"):setScrollBarEnabled(false)
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.dispatch, subTitle = "SEND"})

	self.filterCondition = idlertable.new()
	local pos = self.filter:parent():convertToWorldSpace(self.filter:box())
	pos = self:convertToNodeSpace(pos)
	gGameUI:createView("city.card.bag_filter", self.filter):init({
		cb = self:createHandler("onBattleFilter"),
		others = {
			width = 270,
			height = 122,
			panelOffsetX = 300,
			panelOffsetY = 5,
			panelOrder = true,
			x = gGameUI:getConvertPos(self.filter, self:getResourceNode()),
		}
	}):xy(-pos.x, -pos.y)
	self.filter:z(15)

	self.cardNatures = {}
	local csvTask = csv.dispatch_task.tasks[taskData.csvID]
	for k,v in pairs(csvTask.cardNatures) do
		self.cardNatures[v] = 1
	end
	local level, num = csvNext(csvTask.condition1Arg)
	self.condition1 = {
		typ = csvTask.condition1,
		level = level,
		num = num,
		typStr = CONDITION_TYPE[csvTask.condition1]
	}
	self.cardStateData = {}
	self.cardInfos = idlertable.new({})
	self.cardInfosOrder = {}
	idlereasy.any({self.cards, self.dispatchTasks, self.dispatchCardIDs},function(_, cards, dispatchTasks, dispatchCardIDs)
		local cardStatus = getCardState(dispatchTasks, dispatchCardIDs)
		local cardInfos = {}
		for i,v in pairs(cards) do
			local card = gGameModel.cards:find(v)
			local cardData = card:read("card_id", "skin_id","name","fighting_point", "level", "star", "advance")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
			local tmpCardInfo = {
				id = cardData.card_id,
				unitId = unitId,
				rarity = unitCsv.rarity,
				attr1 = unitCsv.natureType,
				attr2 = unitCsv.natureType2,
				level = cardData.level,
				star = cardData.star,
				advance = cardData.advance,
				fight = cardData.fighting_point,
				dbid = v,
				selectState = false,
				-- status 0没派遣 1派遣中 2休息中
				status = cardStatus[v] or 0,
				atkType = cardCsv.atkType,
			}
			--满足条件的权重
			local weight = 0
			if self.cardNatures[tmpCardInfo.attr1] == 1 then
				weight = 1
			end
			if tmpCardInfo.attr2 and self.cardNatures[tmpCardInfo.attr2] == 1 then
				weight = 1
			end
			tmpCardInfo.weight = weight
			table.insert(self.cardInfosOrder, tmpCardInfo)
			cardInfos[v] = tmpCardInfo
		end
		table.sort(self.cardInfosOrder,function(a,b)
			return a.fight > b.fight
		end)
		self.cardInfos:set(cardInfos)
	end)
	self.cardDatas = idlers.new()
	--true是降序，false升序
	self.sortOrder = idler.new(true)
	idlereasy.any({self.filterCondition, self.sortOrder, self.cardInfos}, function(_, filterCondition, sortOrder, cardInfos)
		local condition = {
			{"rarity", (filterCondition.rarity < ui.RARITY_LAST_VAL) and filterCondition.rarity or nil},
			{"attr2", (filterCondition.attr2 < ui.ATTR_MAX) and filterCondition.attr2 or nil},
			{"attr1", (filterCondition.attr1 < ui.ATTR_MAX) and filterCondition.attr1 or nil},
			{"atkType", filterCondition.atkType},
		}
		local filter = filterDo(clone(cardInfos), condition)
		self.btnSort:get("icon"):scaleY(sortOrder and -1.6 or 1.6)
		for i,v in pairs(filter) do
			v.selectState = self.cardStateData[v.dbid] and true or false
		end
		self.cardDatas:update(filter)
	end)

	self.taskCardDatas = idlers.new()
	local taskCardDatas = {}
	for i=1,csvTask.cardNums do
		taskCardDatas[i] = {}
	end
	self.taskCardDatas:update(taskCardDatas)
	self.selectIdx = idler.new(0)
	self.attrDatas = idlers.new()
	self:setRightPanel(csvTask)
	idlereasy.when(self.selectIdx, function(_, selectIdx)
		local cardDatas = self.cardDatas:atproxy(selectIdx)
		if cardDatas then
			cardDatas.selectState = not clone(cardDatas.selectState)
			self.cardStateData[cardDatas.dbid] = clone(cardDatas.selectState)
			local taskCardPos = setTaskCardDatas(csvTask.cardNums, self.taskCardDatas, clone(cardDatas))
			self.taskCardList:jumpToItem(taskCardPos, cc.p(1, 0), cc.p(1, 0))
		end
		self:setRightPanel(csvTask)
	end)
	--设置奖励面板
	dispatchtaskTools.setRewardPanel(self, self.rightPanel, csvTask.award, "icon")
	dispatchtaskTools.setRewardPanel(self, self.rightPanel, csvTask.extraAward, "extraIcon")
end

function DispatchTaskSpriteSelectView:initModel()
	self.cards = gGameModel.role:getIdler("cards")--卡牌
	self.dispatchTasks = gGameModel.role:getIdler("dispatch_tasks")
	local dailyRecord = gGameModel.daily_record
	self.dispatchCardIDs = dailyRecord:getIdler("dispatch_cardIDs")
end
--设置右侧面板
function DispatchTaskSpriteSelectView:setRightPanel(csvTask)
	local childs = self.rightPanel:multiget(
		"title",
		"taskDesc",
		"condition1",
		"condition2",
		"extraCondition1",
		"extraCondition2",
		"gainChance",
		"btnReward",
		"btnComplete",
		"attrList"
	)
	childs.title:text(csvTask.name)
	childs.taskDesc:text(csvTask.desc)
	local cardNums = 0
	local fight = 0
	local cardIDs = {}
	local condition1Num = 0
	for i,data in self.taskCardDatas:ipairs() do
		local cardData = data:proxy()
		if cardData.selectState then
			cardNums = cardNums + 1
			fight = fight + cardData.fight
			table.insert(cardIDs, cardData.dbid)
		end
	end
	local taskData = clone(self.taskData)
	taskData.cardIDs = cardIDs
	taskData.status = 1
	dispatchtaskTools.setItemCondition(self.rightPanel, taskData, self.attrItem)
	--战力足够
	self.fightEnough = fight >= self.taskData.fightingPoint
	self.numberEnough = cardNums >= csvTask.cardNums
	adapt.oneLinePos(childs.extraCondition2, childs.attrList, cc.p(5,0))
end
--点击卡牌上下阵
function DispatchTaskSpriteSelectView:onCardItemClick(list, t, v)
	local selectNum = 0
	for i,data in self.taskCardDatas:ipairs() do
		local cardData = data:proxy()
		if not cardData.selectState then
			break
		end
		selectNum = selectNum + 1
		if selectNum == self.taskCardDatas:size() and not v.selectState then
			return
		end
	end
	self.selectIdx:set(v.dbid, true)
end

--一键上阵
function DispatchTaskSpriteSelectView:onOneKeyClick()
	local cardNatures = {}
	local csvTask = self.taskData.cfg
	for k,v in pairs(csvTask.cardNatures) do
		cardNatures[v] = {attr = v, state = false}
	end
	local taskDatas = {}
	local condition1Num = 0
	--先判断第二个额外条件
	for i,data in ipairs(self.cardInfosOrder) do
		if itertools.size(taskDatas) >= csvTask.cardNums then
			break
		end
		if cardNatures[data.attr1]
			and not cardNatures[data.attr1].state
			and data.status == 0 then
				cardNatures[data.attr1].state = true
				taskDatas[data.dbid] = data
		end
		if data.attr2 and cardNatures[data.attr2]
			and not cardNatures[data.attr2].state
			and data.status == 0 then
				cardNatures[data.attr2].state = true
				taskDatas[data.dbid] = data
		end
	end
	--判断第一个额外条件
	for i,data in ipairs(self.cardInfosOrder) do
		if itertools.size(taskDatas) >= csvTask.cardNums then
			break
		end
		local level, num = csvNext(csvTask.condition1Arg)
		if data[CONDITION_TYPE[csvTask.condition1].name] >= level
			and condition1Num < num
			and data.status == 0 then
				taskDatas[data.dbid] = data
				condition1Num = condition1Num + 1
		end
	end
	--数量不足按战力补位
	for i,data in ipairs(self.cardInfosOrder) do
		if itertools.size(taskDatas) >= csvTask.cardNums then
			break
		end
		if not taskDatas[data.dbid] and data.status == 0 then
			taskDatas[data.dbid] = data
		end
	end
	if itertools.size(taskDatas) < csvTask.cardNums then
		gGameUI:showTip(gLanguageCsv.numberNotEnough)
		return
	end
	local taskCardDatas = {}
	for k,v in pairs(taskDatas) do
		v.selectState = true
		table.insert(taskCardDatas,v)
	end
	local notChange = true
	for i,v in ipairs(taskCardDatas) do
		local taskCardData = self.taskCardDatas:atproxy(i)
		if v.dbid ~= taskCardData.dbid or v.selectState ~= taskCardData.selectState then
			notChange = false
		end
	end
	if notChange then
		return
	end
	self.cardStateData = taskDatas
	self.taskCardDatas:update(clone(taskCardDatas))
	self:setRightPanel(csvTask)
	self.sortOrder:set(self.sortOrder:read(), true)
end
--点击已上阵的 进行下阵
function DispatchTaskSpriteSelectView:onTaskItemClick(list, k, v)
	if not v.selectState then
		return
	end
	self.taskCardDatas:atproxy(k).selectState = false
	self.selectIdx:set(v.dbid, true)
	self.cardStateData[v.dbid] = false
end
--开始任务
function DispatchTaskSpriteSelectView:onBtnStart()
	local selectTask = self.taskData
	local targetTask = self.dispatchTasks:read()[selectTask.dbid]
	if  (not targetTask) or not (selectTask.csvID == targetTask.csvID and targetTask.status == 2) then
		gGameUI:showTip(gLanguageCsv.currentTaskChanged)
		return
	end

	if not self.numberEnough then
		gGameUI:showTip(gLanguageCsv.numberNotEnough)
		return
	end
	if not self.fightEnough then
		gGameUI:showTip(gLanguageCsv.fightNotEnough)
		return
	end
	local cardIDs = {}
	for i,data in self.taskCardDatas:ipairs() do
		local cardData = data:proxy()
		if cardData.selectState then
			table.insert(cardIDs, cardData.dbid)
		end
	end
	gGameApp:requestServer("/game/dispatch/task/begin", function (tb)
		self:onClose()
	end, cardIDs, self.taskData.dbid)
end
--筛选
function DispatchTaskSpriteSelectView:onBattleFilter(attr1, attr2, rarity, atkType)
	self.filterCondition:set({attr1 = attr1, attr2 = attr2, rarity = rarity, atkType = atkType}, true)
end
--排序
function DispatchTaskSpriteSelectView:onBtnSortClick(panel, node, k, v)
	--频繁点击后期优化
	self.sortOrder:modify(function(val)
		return true, not val
	end)
end

function DispatchTaskSpriteSelectView:onSortCards(list)
	local sortOrder = self.sortOrder:read()
	return function(a, b)
		if a.status ~= b.status then
			return a.status < b.status
		end
		if sortOrder then
			return a.fight > b.fight
		else
			return a.fight < b.fight
		end
	end
end

return DispatchTaskSpriteSelectView