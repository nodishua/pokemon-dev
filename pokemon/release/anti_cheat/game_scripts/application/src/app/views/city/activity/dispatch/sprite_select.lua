-- @date:   2021-04-21
-- @desc:   派遣任务-选择精灵界面
local ActiviytDispatchSpriteSelect = class("ActiviytDispatchSpriteSelect", Dialog)


-- 任务服务器 1: 派遣中; 2: 未派遣
-- 卡牌status 1 不可派遣 2 可派遣
local function getCardState(dispatchTasks)
	local status = {}
	for _,v in pairs(dispatchTasks) do
		for _, card in pairs(v.cards or {}) do
			if v.status == 1 then
				status[card.id] = 1
			end
			if v.status == 2 then
				status[card.id] = 2
			end
		end
	end
	return status
end

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
local function addAllCount(getCountFunc, taskCardDatas1, taskCardDatas2)
	local allCount = 0
	allCount = allCount + getCountFunc(taskCardDatas1:atproxy(1))
	for i = 1, 3 do
		allCount =  allCount + getCountFunc(taskCardDatas2:atproxy(i))
	end
	return allCount >= params[1], allCount
end
--计算是否复合条件(11 返回值特殊 为table)
local checkMeetConditions = {
	[1] = function(params, taskCardDatas1, taskCardDatas2)
		--精灵数量
		local function getCount(data)
			if data.selectState then
				return 1
			end
			return 0
		end
		return addAllCount(getCount, taskCardDatas1, taskCardDatas2)
	end,
	[2] = function(params, taskCardDatas1, taskCardDatas2)
		-- = "精灵元素属性为%s%s个",
		local function getCount(data)
			if data.selectState and (data.attr1 == params[1] or data.attr2 == params[1]) then
				return 1
			end
			return 0
		end
		return addAllCount(getCount, taskCardDatas1, taskCardDatas2)
	end,
	[3] = function(params, taskCardDatas1, taskCardDatas2)
		 --指定markID卡牌领队;
		if taskCardDatas1:atproxy(1).selectState then
			local cardId = taskCardDatas1:atproxy(1).id
			local csvCards = csv.cards[cardId]
			local markId = csvCards.cardMarkID
			return markId == params[1]
		end
		return false
	end,
	[4] = function(params, taskCardDatas1, taskCardDatas2)
		-- 精灵性别为%s%s个,
		local function getCount(data)
			if data.selectState then
				local gender = data.gender
				for k = 1, itertools.size(params) - 1 do
					if gender == params[k] then
						return 1
					end
				end
			end
			return 0
		end
		return addAllCount(getCount, taskCardDatas1, taskCardDatas2)
   end,
   [5] = function(params, taskCardDatas1, taskCardDatas2)
		-- 身高x及以上的精灵y个;
		local function getCount(data)
			if data.selectState then
				local height = gHandbookCsv[data.id].heightAndWeight[1] or 0
				if height >= params[1] then
					return 1
				end
			end
			return 0
		end
		return addAllCount(getCount, taskCardDatas1, taskCardDatas2)
	end,
	[6] = function(params, taskCardDatas1, taskCardDatas2)
		--身高x及以下的精灵y个;
		local function getCount(data)
			if data.selectState then
				local height = gHandbookCsv[data.id].heightAndWeight[1] or 0
				if height <= params[1] then
					return 1
				end
			end
			return 0
		end
		return addAllCount(getCount, taskCardDatas1, taskCardDatas2)
	end,
	[7] = function(params, taskCardDatas1, taskCardDatas2)
		--体重x及以上的精灵y个;
		local function getCount(data)
			if data.selectState then
				local height = gHandbookCsv[data.id].heightAndWeight[2] or 0
				if height >= params[1] then
					return 1
				end
			end
			return 0
		end
		return addAllCount(getCount, taskCardDatas1, taskCardDatas2)
	end,
	[8] = function(params, taskCardDatas1, taskCardDatas2)
		-- 体重x及以下的精灵y个;
		local function getCount(data)
			if data.selectState then
				local height = gHandbookCsv[data.id].heightAndWeight[2] or 0
				if height <= params[1] then
					return 1
				end
			end
			return 0
		end
		return addAllCount(getCount, taskCardDatas1, taskCardDatas2)
	end,
	[9] = function(params, taskCardDatas1, taskCardDatas2)
		-- 好感度x及以上的精灵y个;
		local function getCount(data)
			if data.selectState then
				local cardId = data.id
				local csvCards = csv.cards[cardId]
				local markId = csvCards.cardMarkID
				local cardFeels = gGameModel.role:read("card_feels")
				local cardFeel = cardFeels[markId] or {}
				local level = cardFeel.level or 0
				if level >= params[1] then
					return 1
				end
			end
			return 0
		end
		return addAllCount(getCount, taskCardDatas1, taskCardDatas2)
	end,
	[10] = function(params, taskCardDatas1, taskCardDatas2)
		-- 稀有度x以上的精灵y个;
		local function getCount(data)
			if data.selectState and (data.rarity >= params[1]) then
				return 1
			end
			return 0
		end
		return addAllCount(getCount, taskCardDatas1, taskCardDatas2)
	end,
	[11] = function(params, taskCardDatas1, taskCardDatas2)
		-- 元素满足多个
		local check = {}
		local checkFunc = function(data, v)
			if data.selectState then
				local attr1 = data.attr1
				local attr2 = data.attr2
				return attr1 == v or attr2 == v
			end
			return false
		end
		for k, v in ipairs(params) do
			check[k] = false
			while true do
				if checkFunc(taskCardDatas1:atproxy(1)) then
					check[k] = true
					break
				end
				for i = 1, 3 do
					if checkFunc(taskCardDatas2:atproxy(i)) then
						check[k] = true
					end
				end
				break
			end
		end
		return check
	end,
}


ActiviytDispatchSpriteSelect.RESOURCE_FILENAME = "activity_dispatch_sprite_select.json"
ActiviytDispatchSpriteSelect.RESOURCE_BINDING = {
	["bg"] = "bg",
	["leftPanel"] = "leftPanel",
	["leftPanel.empty"] = "empty",
	["item"] = "item",
	["leftPanel.subList"] = "subList",
	["leftPanel.filter"] = "filter",
	["btnClose"] = {
		varname = "btnClose",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["rightPanel.btnDispatch"] = {
		varname = "btnDispatch",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnDispatch")}
		},
	},
	["rightPanel.btnStart"] = {
		varname = "btnStart",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnStart")}
		},
	},
	["rightPanel.btnStop"] = {
		varname = "btnStop",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnStop")}
		},
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.title"] = "title",
	["rightPanel.img"] = "titleImg",
	["rightPanel.conditionPanel.taskDesc"] = "taskDesc",
	["rightPanel.awardList"] = "awardList",
	["imgExtra"] = "imgExtra",
	["leftPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				dataFilterGen = bindHelper.self("onFilterCards", true),
				columnSize = 5,
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				empty = bindHelper.self("empty"),
				itemAction = {isAction = true},
				xMargin = 10,
				yMargin = 10,
				onCell = function(list, node, k, v)
					setCardIcon(list, node, v)
					node:get("icon"):setVisible(v.recommend)
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
	["leftPanel.cardPanel.list1"] = {
		varname = "taskCardList1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("taskCardDatas1"),
				item = bindHelper.self("item"),
				margin = 5,
				onItem = function(list, node, k, v)
					setCardIcon(list, node, v, true)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k, v)}})
					node:get("mask"):visible(false)
					node:get("icon"):visible(false)
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onTaskItemClick1"),
			},
		},
	},
	["leftPanel.cardPanel.list2"] = {
		varname = "taskCardList2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("taskCardDatas2"),
				item = bindHelper.self("item"),
				margin = 5,
				onItem = function(list, node, k, v)
					setCardIcon(list, node, v, true)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k, v)}})
					node:get("mask"):visible(false)
					node:get("icon"):visible(false)
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onTaskItemClick2"),
			},
		},
	},
	["rightPanel.dispatchedPanel"] = "dispatchedPanel",
	["rightPanel.dispatchedPanel.list1"] = {
		varname = "dispatchList1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("disptachedData1"),
				item = bindHelper.self("item"),
				margin = 5,
				onItem = function(list, node, k, v)
					setCardIcon(list, node, v, true)
					node:get("mask"):visible(false)
					node:get("icon"):visible(false)
				end,
			},
		},
	},
	["rightPanel.dispatchedPanel.list2"] = {
		varname = "dispatchList2",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("disptachedData2"),
				item = bindHelper.self("item"),
				margin = 5,
				onItem = function(list, node, k, v)
					setCardIcon(list, node, v, true)
					node:get("mask"):visible(false)
					node:get("icon"):visible(false)
				end,
			},
		},
	},
	["rightPanel.conditionPanel"] = "conditionPanel",
	["rightPanel.conditionPanel.attrList"] = "attrList",
	["rightPanel.conditionPanel.attrList1"] = "attrList1",
	["rightPanel.textTimes"] = "textTimes",
	["rightPanel.imgTimes"] = "imgTimes",

	["attrItem"] = "attrItem",
}
function ActiviytDispatchSpriteSelect:getConditionStr(conditionsIndex, params, index)
	local str = index .."."..gLanguageCsv["dispatchCondition"..conditionsIndex]
	local check, count = checkMeetConditions[conditionsIndex](params, self.taskCardDatas1, self.taskCardDatas2)
	local color = ""
	if check then
		color = "#C0x62C558#"
	else
		color = "#C0xF7734E#"
	end
	local desc = params[1]

	if conditionsIndex == 1 then--个数
		str = color .. string.format(str, count..'/'..params[1])
	elseif conditionsIndex == 2 then--元素属性
		local icon = "#I" .. ui.ATTR_ICON[params[1]].. "-50-50#"
		str = color .. string.format(str, icon, count..'/'..params[2])
	elseif conditionsIndex == 3 then--markId
		local markId = params[1]
		local name = csv.cards[markId].name
		str = color.. string.format(str, string.format(gLanguageCsv.selectTypeCardFragments, name))
	elseif conditionsIndex == 4 then--性别
		local desc = ""
		for i = 1, itertools.size(params) - 1 do
			if i == itertools.size(params) - 1 then
				desc = desc .. gLanguageCsv["sex"..params[i]]
			else
				desc = desc .. gLanguageCsv["sex"..params[i]] .. gLanguageCsv["or"]
			end
		end
		str = color .. string.format(str, desc, count..'/'..params[itertools.size(params)])
	elseif conditionsIndex == 5 or conditionsIndex == 6  or conditionsIndex == 7 or conditionsIndex == 8 then--身高体重
		str = color .. string.format(str, params[1], count..'/'..params[2])
	elseif conditionsIndex == 9 then --好感度
		str = color .. string.format(str, params[1], count..'/'..params[2])
	elseif conditionsIndex == 10 then--稀有度
		local icon = "#I" .. ui.RARITY_ICON[params[1]].. "-50-50#"
		str = color .. string.format(str, icon, count..'/'..params[2])
	elseif conditionsIndex == 11 then--属性
		return str, check
	end
	return str, check
end

function ActiviytDispatchSpriteSelect:showAward(showExtra)
	local data = csv.yunying.dispatch[self.id]
	if showExtra then
		--额外奖励
		local awardData = table.shallowcopy(data.award)
		for k,v in pairs(data.extraAward) do
			awardData[k] = v
		end
		uiEasy.createItemsToList(self, self.awardList, awardData,
		{
			scale = 0.9,
			onAfterBuild = function()
				self.awardList:setItemAlignCenter()
			end,
			sortFunc = function(a, b)
				if data.extraAward[a.key] and not data.extraAward[b.key] then
					return false
				elseif not data.extraAward[a.key] and data.extraAward[b.key] then
					return true
				else
					return dataEasy.sortItemCmp(a, b)
				end
			end,
			onNode = function(node,v)
				if data.extraAward[v.key] then
					local img = self.imgExtra:clone():addTo(node)
						:xy(157,185)
						:z(10)
						:scale(1.1)
						:show()
				end
			end,
		})
	else
		uiEasy.createItemsToList(self, self.awardList, data.award, {scale = 0.9, onAfterBuild = function()
			self.awardList:setItemAlignCenter()
		end})
	end

end

function ActiviytDispatchSpriteSelect:refreshRight( )
	local data = csv.yunying.dispatch[self.id]
	--基础条件
	local canStart = true
	for i =1, 3 do
		self.conditionPanel:removeChildByName("rich"..i)
		local conditionsIndex = data["target"..i]
		if conditionsIndex ~= 0 then
			local params = data["params"..i]
			local str, check = self:getConditionStr(conditionsIndex, params, i)
			if conditionsIndex == 11 then
				for _, v in ipairs(check) do
					if not v then
						canStart = false
					end
				end
			else
				if check == false then
					canStart = false
				end
			end

			if conditionsIndex == 11 then --11特殊处理
				local label = cc.Label:createWithTTF(str, ui.FONT_PATH, 40)
					:name("rich"..i)
					:anchorPoint(cc.p(0,1))
					:xy(self.conditionPanel:get("conditionNote"):x(), 745 - 52 * i)
					:text(str)
					:z(10)
					:addTo(self.conditionPanel)
				local allCheck = true
				for _, v in ipairs(check) do
					if not v then
						allCheck = false
					end
				end
				self.attrList:removeAllChildren()
				self.attrList:setScrollBarEnabled(false)
				self.attrList:scale(0.8)
				for k, v in ipairs(params) do
					local item = self.attrItem:clone():show()
					item:get("attrIcon"):texture(ui.ATTR_ICON[v])
					item:get("img"):setVisible(check[k])
					self.attrList:pushBackCustomItem(item)
				end
				label:setTextColor(allCheck and cc.c4b(98, 197, 88, 255) or cc.c4b(247, 115, 78, 255))
				self.attrList:xy(label:x() + label:width() + 5,label:y() - 45)
			else
				local richText = rich.createWithWidth(str, 40, nil, 1000, nil, cc.p(0, 0.5))
					:xy(610, 745 - 52 * i)
					:addTo(self.conditionPanel)
					:name("rich"..i)
					:show()
					:z(10)
			end
		end
	end
	uiEasy.setBtnShader(self.btnDispatch, self.btnDispatch:get("title"), canStart and 1 or 2)
	--加分条件
	local text3 = self.conditionPanel:get("extraCondition")
	local conditionsIndex = data.spTarget
	self.conditionPanel:removeChildByName("rich")
	local params = data.spParams
	local showExtra = false
	if conditionsIndex ~= 0  then
		local str, check = self:getConditionStr(conditionsIndex, params, 1)
		self.conditionPanel:get("extraConditionNote"):show()
		if conditionsIndex == 11 then
			local label = cc.Label:createWithTTF(str, ui.FONT_PATH, 40)
				:name("rich")
				:anchorPoint(cc.p(0,1))
				:xy(self.conditionPanel:get("extraCondition"):x(), 490)
				:text(str)
				:z(10)
				:addTo(self.conditionPanel)
			local allCheck = true
			for _, v in ipairs(check) do
				if not v then
					allCheck = false
				end
			end
			self.attrList1:removeAllChildren()
			self.attrList1:setScrollBarEnabled(false)
			self.attrList1:scale(0.8)
			for k, v in ipairs(params) do
				local item = self.attrItem:clone():show()
				item:get("attrIcon"):texture(ui.ATTR_ICON[v])
				item:get("img"):setVisible(check[k])
				self.attrList1:pushBackCustomItem(item)
			end
			label:setTextColor(allCheck and cc.c4b(98, 197, 88, 255) or cc.c4b(247, 115, 78, 255))
			self.attrList1:xy(label:x() + label:width() + 5,label:y() - 45)
		else
			local richText = rich.createWithWidth(str, 40, nil, 1000, nil, cc.p(0, 0.5))
				:xy(610, 490)
				:addTo(self.conditionPanel)
				:name("rich")
				:show()
				:z(10)
		end

		--加分
		if data.extraTime ~= 0 then
			text3:text(string.format(gLanguageCsv.dispatchAddition, tostring(mathEasy.getPreciseDecimal(data.extraTime / 60, 2, false))))
		else
			text3:hide()
		end

		--已派遣状态

		local yydata = self.yyhuodongs:read()[self.activityId] or {}
		local dispatch = yydata.dispatch or {}
		if not dispatch[self.id] or dispatch[self.id].status == 2 then
			self:showAward(true)
		elseif dispatch[self.id].status == 1 and dispatch[self.id].extra then
			self:showAward(true)
		else
			self:showAward(false)
		end
	else
		self.conditionPanel:get("extraConditionNote"):hide()
		text3:hide()
		self:showAward(false)
	end
end

function ActiviytDispatchSpriteSelect:initModel( )
	self.cards = gGameModel.role:getIdler("cards")--卡牌
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.cardDatas = idlers.new()
	self.filterCondition = idlertable.new()
	self.selectIdx = idler.new(0)--dbid
	--派遣的精灵
	self.taskCardDatas1 = idlers.new()
	self.taskCardDatas1:update({{}})

	self.taskCardDatas2 = idlers.new()
	local taskCardDatas2 = {}
	for i=1,3 do
		taskCardDatas2[i] = {}
	end
	self.taskCardDatas2:update(taskCardDatas2)

	--已派遣的精灵
	self.disptachedData1 = idlers.newWithMap({
		{}
	})
	self.disptachedData2 = idlers.newWithMap({
		{}, {}, {}
	})

	--界面状态 1 接受委托界面 2.派遣选择精灵界面 3.派遣ing 4.派遣结束 5 预览
	self.dispatchStatus = idler.new(0)
end

function ActiviytDispatchSpriteSelect:initDispatchedShow(dispatch)
	self.dispatchedPanel:show()
	self.conditionPanel:hide()
	local datas = {}
	for i = 1, 4 do
		local cardData = dispatch[self.id].cards[i]
		if cardData then
			local id = dispatch[self.id].cards[i].id
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
				dbid = id,
				selectState = true,
			}
			datas[i] = tmpCardInfo
		end
	end

	self.disptachedData1:update({datas[1]})
	self.disptachedData2:update({datas[2], datas[3], datas[4]})
end


function ActiviytDispatchSpriteSelect:onCreate(activityId, id)
	self.activityId = activityId
	self.id = id
	self.allDispatchNum = 0
	self:initModel()
	self:initFilter()
	self.dispatchTimes = 0
	self.endTime = 0
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	local actionPointKey = csv.yunying.yyhuodong[self.activityId].paramMap.item
	self.actionPoint = idler.new(dataEasy.getNumByKey(actionPointKey))
	local taskData = csv.yunying.dispatch[id]
	self.bg:texture(taskData.frameType)
	self.title:text(taskData.name)
	adapt.oneLineCenterPos(cc.p(550,self.title:y()),{self.titleImg,self.title}, cc.p(5, 0))
	self.taskDesc:text(taskData.desc)
	self.titleImg:texture(taskData.iconSpecial)
	local actionPointKey = csv.yunying.yyhuodong[self.activityId].paramMap.item
	local str = string.format(gLanguageCsv.dispatchCost, tostring(mathEasy.getPreciseDecimal(taskData.duration / 60, 2, false)), taskData.cost[actionPointKey])
	local richText = rich.createByStr(str, 40, nil, nil, cc.p(0, 0))
		:addTo(self.conditionPanel:get("imgBg"), 100)
		:anchorPoint(cc.p(0, 0.5))
		:xy(self.conditionPanel:get("imgBg.text"):xy())
		:formatText()
	self.conditionPanel:get("imgBg.text"):hide()

	if taskData.times > 1 then
		self.imgTimes:show()
		self.textTimes:show()
	else
		self.imgTimes:hide()
		self.textTimes:hide()
	end
	idlereasy.when(self.yyhuodongs,function(_, yyhuodongs)
		--界面状态 1 接受委托界面 2.派遣选择精灵界面 3.派遣ing 4.派遣结束 5.预览
		local yydata = yyhuodongs[self.activityId] or {}
		local dispatch = yydata.dispatch or {}
		self.dispatchTimes = dispatch[self.id] and dispatch[self.id].times or 0
		if not dispatch[self.id] then--预览
			self.dispatchStatus:set(5)
		elseif dispatch[self.id].status == 1 then --派遣中
			if dispatch[self.id].end_time < time.getTime() then
				--派遣成功结束
				self.dispatchStatus:set(4)
			else
				--派遣ing
				self.dispatchStatus:set(3)
			end
		else
			if time.getTime() < dispatch[self.id].cd_time then
				self.dispatchStatus:set(5)
			else
				self.dispatchStatus:set(1)
			end
		end
		self.allDispatchNum = 0
		for taskId, v in pairs(dispatch) do
			if dispatch[taskId] and dispatch[taskId].status == 1 then
				self.allDispatchNum = self.allDispatchNum + 1
			end
		end
		self.textTimes:text(string.format(gLanguageCsv.dispatchTips, csv.yunying.dispatch[self.id].times - self.dispatchTimes))
		self.endTime = dispatch[self.id] and dispatch[self.id].end_time or 0
	end)
	idlereasy.when(self.dispatchStatus, function(_, status)
		local yydata = self.yyhuodongs:read()[self.activityId] or {}
		local dispatch = yydata.dispatch or {}
		if status == 1 then
			--未派遣
			self.disptachedData1:update({})
			self.disptachedData2:update({})
			self.leftPanel:show()
			self.dispatchedPanel:hide()
			self.conditionPanel:show()
			self.btnDispatch:hide()
			self.btnStart:show()
			self.btnStop:hide()
			self.leftPanel:hide()
			self.bg:width(1156)
			self.rightPanel:x(self.bg:x())
			self.btnClose:x(self.bg:x() +607)
			uiEasy.setBtnShader(self.btnStart, self.btnStart:get("title"), 1)
		elseif status == 2 then
			--选择精灵
			self.leftPanel:show()
			self.bg:width(2304)
			self.rightPanel:x(530 + display.sizeInViewRect.width/2)
			self.btnClose:x(1137 + display.sizeInViewRect.width/2)
			self.dispatchedPanel:hide()
			self.conditionPanel:show()
			self.btnDispatch:show()
			self.btnStart:hide()
			self.btnStop:hide()
		elseif status == 3 then
			--派遣ing
			self.leftPanel:hide()
			self.bg:width(1156)
			self.rightPanel:x(self.bg:x())
			self.btnClose:x(self.bg:x() +607)
			self:initDispatchedShow(dispatch)

			self.btnDispatch:hide()
			self.btnStart:hide()
			self.btnStop:show()
			self:initCountDown(dispatch[self.id].end_time)
		elseif status == 4 then
			self.leftPanel:hide()
			self.bg:width(1156)
			self.rightPanel:x(self.bg:x())
			self.btnClose:x(self.bg:x() +607)
			self.btnDispatch:hide()
			self.btnStart:hide()
			self.btnStop:show()
			self:initDispatchedShow(dispatch)
			--派遣结束
			self.dispatchedPanel:get("textNote"):text(gLanguageCsv.dispatchComplete)
			self.dispatchedPanel:get("textCountDown"):text("")
			adapt.oneLineCenterPos(cc.p(500, 520), {self.dispatchedPanel:get("textCountDown"), self.dispatchedPanel:get("textNote")}, cc.p(0, 0))
			self.btnStop:get("title"):text(gLanguageCsv.completeDispatch)
		elseif status == 5 then
			self.leftPanel:hide()
			self.bg:width(1156)
			self.rightPanel:x(self.bg:x())
			self.btnClose:x(self.bg:x() +607)
			self.btnDispatch:hide()
			self.btnStart:show()
			self.btnStop:hide()
			self.dispatchedPanel:hide()
			-- self.dispatchedPanel:get("textNote"):text(gLanguageCsv.dispatchComplete)
			-- self.dispatchedPanel:get("textCountDown"):text("")
			adapt.oneLineCenterPos(cc.p(500, 520), {self.dispatchedPanel:get("textCountDown"), self.dispatchedPanel:get("textNote")}, cc.p(0, 0))
			uiEasy.setBtnShader(self.btnStart, self.btnStart:get("title"), 3)
		end
	end)
	idlereasy.any({self.cards, self.yyhuodongs},function(_, cards, yyhuodongs)
		local yydata = yyhuodongs[self.activityId] or {}
		local dispatch = yydata.dispatch or {}
		local cardStatus = getCardState(dispatch)
		local cardInfos = {}
		for i,v in pairs(cards) do
			local card = gGameModel.cards:find(v)
			local cardData = card:read("card_id", "skin_id","name","fighting_point", "level", "star", "advance", "gender")
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
				gender =  cardData.gender,
				fight = cardData.fighting_point,
				dbid = v,
				selectState = false,
				-- status 1派遣中 2未派遣
				status = cardStatus[v] or 0,
				atkType = cardCsv.atkType,

			}
			tmpCardInfo.recommend = self:checkRecommend(tmpCardInfo)
			cardInfos[v] = tmpCardInfo
		end
		self.cardDatas:update(cardInfos)
	end)

	idlereasy.when(self.selectIdx, function(_, selectIdx)
		if selectIdx == 0 then
			self:refreshRight()
			return
		end
		local cardDatas = self.cardDatas:atproxy(selectIdx)
		--取消选择
		if cardDatas.selectState then
			local taskCardDatas1 = self.taskCardDatas1:atproxy(1)
			if cardDatas.dbid == taskCardDatas1.dbid then
				taskCardDatas1.selectState = false
				cardDatas.selectState = false
			else
				for i = 1, 3  do
					local taskCardData = self.taskCardDatas2:atproxy(i)
					if cardDatas.dbid == taskCardData.dbid then
						taskCardData.selectState = false
						cardDatas.selectState = false
					end
				end
			end
		else
			local function chooseCard(taskCardData, cardDatas)
				taskCardData.selectState = true
				taskCardData.id = cardDatas.id
				taskCardData.unitId = cardDatas.unitId
				taskCardData.rarity = cardDatas.rarity
				taskCardData.attr1 = cardDatas.attr1
				taskCardData.attr2 = cardDatas.attr2
				taskCardData.level = cardDatas.level
				taskCardData.star = cardDatas.star
				taskCardData.advance = cardDatas.advance
				taskCardData.gender =  cardDatas.gender
				taskCardData.fight = cardDatas.fight
				taskCardData.dbid = cardDatas.dbid
				cardDatas.selectState = true
			end

			local taskCardDatas1 = self.taskCardDatas1:atproxy(1)
			local check = false
			if not taskCardDatas1.selectState then
				chooseCard(taskCardDatas1, cardDatas)
			else
				for i = 1, 3 do
					local taskCardDatas2 = self.taskCardDatas2:atproxy(i)
					if not taskCardDatas2.selectState then
						chooseCard(taskCardDatas2, cardDatas)
						break
					end
				end
			end
		end
		self:refreshRight()
	end)
end
function ActiviytDispatchSpriteSelect:onSortCards(list)
	return function(a, b)
		if a.status ~= b.status then
			return a.status < b.status
		else
			return a.fight > b.fight
		end

	end
end


function ActiviytDispatchSpriteSelect:initFilter( )
	local pos = self.filter:parent():convertToWorldSpace(self.filter:box())
	pos = self:convertToNodeSpace(pos)
	gGameUI:createView("city.card.bag_filter", self.filter):init({
		cb = self:createHandler("onBattleFilter"),
		others = {
			width = 221,
			height = 102,
			panelOffsetX = 940,
			panelOffsetY = 450,
			panelOrder = true,
			btn = self.filter:get("btnFilter"),
			x = gGameUI:getConvertPos(self.filter, self:getResourceNode()),
		}
	}):xy(-pos.x, -pos.y)
	self.filter:z(1000)
	idlereasy.any({self.filterCondition}, function()
		dataEasy.tryCallFunc(self.list, "filterSortItems", false)
	end)
end


--筛选
function ActiviytDispatchSpriteSelect:onBattleFilter(attr1, attr2, rarity, atkType)
	self.filterCondition:set({attr1 = attr1, attr2 = attr2, rarity = rarity, atkType = atkType}, true)
end

function ActiviytDispatchSpriteSelect:onFilterCards(list)
	local filterCondition = self.filterCondition:read()
	local condition = {
		{"rarity", (filterCondition.rarity < ui.RARITY_LAST_VAL) and filterCondition.rarity or nil},
		{"attr2", (filterCondition.attr2 < ui.ATTR_MAX) and filterCondition.attr2 or nil},
		{"attr1", (filterCondition.attr1 < ui.ATTR_MAX) and filterCondition.attr1 or nil},
		{"atkType", filterCondition.atkType},
	}
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
	return function(dbid, card)
		for i = 1, #condition do
			local cond = condition[i]
			if cond[2] then
				if not isOK(card, cond[1], cond[2]) then
					return false
				end
			end
		end
		return true, dbid
	end
end

--开始任务
function ActiviytDispatchSpriteSelect:onBtnDispatch()
	local data = csv.yunying.dispatch[self.id]
	for i =1, 3 do
		local conditionsIndex = data["target"..i]
		if conditionsIndex ~= 0 then
			local params = data["params"..i]
			if not checkMeetConditions[conditionsIndex](params, self.taskCardDatas1, self.taskCardDatas2) then
				gGameUI:showTip(gLanguageCsv.dispatchMismatchCondition)
				return
			end
		end
	end
	if not self.taskCardDatas1:atproxy(1).selectState then
		gGameUI:showTip(gLanguageCsv.dispatchWithoutLeader)
		return
	end

	local actionPointKey = csv.yunying.yyhuodong[self.activityId].paramMap.item
	local actionPoint = dataEasy.getNumByKey(actionPointKey)
	local data = csv.yunying.dispatch[self.id]
	local cost = data.cost[actionPointKey]

	if actionPoint < cost then
		gGameUI:showTip(gLanguageCsv.actionPointNotEnough)
		return
	end

	local cardIDs = {self.taskCardDatas1:atproxy(1).dbid}
	for i = 1, 3 do
		local cardData = self.taskCardDatas2:atproxy(i)
		if cardData.selectState then
			table.insert(cardIDs, cardData.dbid)
		end
	end
	gGameApp:requestServer("/game/yy/dispatch/begin", function (tb)
		self:addCallbackOnExit(function()
			gGameUI:stackUI("city.activity.dispatch.suc", nil, {clickClose = true})
		end)
		self:onClose()
	end, self.activityId, self.id, cardIDs)
end

--放弃委托
function ActiviytDispatchSpriteSelect:onBtnStop()
	if self.dispatchStatus:read() == 4 then
		self.dispatchStatus:shutup()
		gGameApp:requestServer("/game/yy/dispatch/end", function (tb)
			self:addCallbackOnExit(function()
				gGameUI:showGainDisplay(tb)
			end)
			self:onClose()
		end, self.activityId, self.id, false)
	else
		gGameUI:showDialog({ content = gLanguageCsv.endDispatchTip, closeTime = self.endTime, btnType = 2,cb = function()
			self.dispatchStatus:shutup()
			gGameApp:requestServer("/game/yy/dispatch/end", function (tb)
				self:addCallbackOnExit(function()
					gGameUI:showTip(gLanguageCsv.dispatchFailTip)
				end)
				self:onClose()
			end, self.activityId, self.id, true)
		end})
	end
end

--接受委托
function ActiviytDispatchSpriteSelect:onBtnStart()
	local yydata = self.yyhuodongs:read()[self.activityId] or {}
	local dispatch = yydata.dispatch or {}
	if not dispatch[self.id] then
		gGameUI:showTip(gLanguageCsv.dispatchLockTips)
		return
	end
	if time.getTime() < dispatch[self.id].cd_time then
		gGameUI:showTip(gLanguageCsv.dispatchCdTips)
		return
	end
	local maxDispatchNum = csv.yunying.yyhuodong[self.activityId].paramMap.number
	if self.allDispatchNum >= maxDispatchNum then
		gGameUI:showTip(gLanguageCsv.dispatchNumOver)
		return
	end

	local actionPointKey = csv.yunying.yyhuodong[self.activityId].paramMap.item
	local actionPoint = dataEasy.getNumByKey(actionPointKey)
	local data = csv.yunying.dispatch[self.id]
	local cost = data.cost[actionPointKey]
	if actionPoint < cost then
		gGameUI:showTip(gLanguageCsv.actionPointNotEnough)
		return
	end
	if self.dispatchStatus:read() == 1 then
		self.dispatchStatus:set(2)
	end
end

--点击卡牌上下阵
function ActiviytDispatchSpriteSelect:onCardItemClick(list, t, v)
	self.selectIdx:set(v.dbid, true)
end

--点击已上阵的 进行下阵
function ActiviytDispatchSpriteSelect:onTaskItemClick1(list, k, v)
	if not v.selectState then
		return
	end
	self.taskCardDatas1:atproxy(k).selectState = false
	self.selectIdx:set(v.dbid, true)
end

--点击已上阵的 进行下阵
function ActiviytDispatchSpriteSelect:onTaskItemClick2(list, k, v)
	if not v.selectState then
		return
	end
	self.taskCardDatas2:atproxy(k).selectState = false
	self.selectIdx:set(v.dbid, true)
end

function ActiviytDispatchSpriteSelect:checkRecommend(cardData)
	--基础
	local data = csv.yunying.dispatch[self.id]
	local check = function(cardData, i)
		local index = data["target"..i]
		local params = data["params"..i]
		if i == 4 then
			index = data.spTarget
			params = data.spParams
		end
		if index ~= 0 then
			if index == 1 then
				return 0
			elseif index == 2 then -- = "精灵元素属性为%s%s个",
				if cardData.attr1 == params[1] or cardData.attr2 == params[1] then
					return true, index
				end
				return false, index
			elseif index == 3 then --指定markID卡牌领队;
				local csvCards = csv.cards[cardData.id]
				local markId = csvCards.cardMarkID
				return markId == params[1], index
			elseif index == 4 then -- "精灵性别为%s%s个",
				for i = 1, itertools.size(params) - 1 do
					if cardData.gender == params[i] then
						return true
					end
				end
				return false
			elseif index == 5 then -- 身高x及以上的精灵y个;
				local height = gHandbookCsv[cardData.id].heightAndWeight[1] or 0
				return height >= params[1], index
			elseif index == 6 then --身高x及以下的精灵y个;
				local height = gHandbookCsv[cardData.id].heightAndWeight[1] or 0
				return height <= params[1], index
			elseif index == 7 then --体重x及以上的精灵y个;
				local height = gHandbookCsv[cardData.id].heightAndWeight[2] or 0
				return height >= params[1], index
			elseif index == 8 then -- 体重x及以下的精灵y个;
				local height = gHandbookCsv[cardData.id].heightAndWeight[2] or 0
				return height <= params[1], index
			elseif index  == 9 then -- 好感度x及以上的精灵y个;
				local csvCards = csv.cards[cardData.id]
				local markId = csvCards.cardMarkID
				local cardFeels = gGameModel.role:read("card_feels")
				local cardFeel = cardFeels[markId] or {}
				local level = cardFeel.level or 0
				return level >= params[1], index
			elseif index == 10 then-- 稀有度x以上的精灵y个;
				return cardData.rarity >= params[1], index
			elseif index == 11 then -- 元素满足多个
				for k, v in ipairs(params) do
					if cardData.attr1 == v or cardData.attr2 == v then
						return true, index
					end
				end
				return false, index
			end
		end
		return false, 0
	end
	for i = 1, 4 do
		local result, index = check(cardData, i)
		if result == true then
			return true
		end
	end
end


--倒计时
function ActiviytDispatchSpriteSelect:initCountDown(endTime)
	adapt.oneLineCenterPos(cc.p(500, 520), {self.dispatchedPanel:get("textCountDown"), self.dispatchedPanel:get("textNote")}, cc.p(0, 0))
    bind.extend(self, self.dispatchedPanel:get("textCountDown"), {
		class = 'cutdown_label',
		props = {
			endTime = endTime,
			str_key = "str",
			endFunc = function(node)
				self.dispatchStatus:set(4)
			end,
			callFunc = function (node)
				adapt.oneLineCenterPos(cc.p(500, 520), {self.dispatchedPanel:get("textCountDown"), self.dispatchedPanel:get("textNote")}, cc.p(0, 0))
			end
		}
	})
end

--倒计时
function ActiviytDispatchSpriteSelect:initCdCountDown(endTime)
	self:enableSchedule()
	self:schedule(function(dt)
		if time.getTime() > endTime then
			self.dispatchStatus:set(1)
			return false
		end
	end, 1)
end


return ActiviytDispatchSpriteSelect