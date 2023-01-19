-- @date:   2019-03-04
-- @desc:   日常副本界面

local DailyActivityView = class("DailyActivityView", cc.load("mvc").ViewBase)

local REWARD_TYPE = {
	-- 双倍奖励
	gLanguageCsv.doubleReward,
	-- 增加次数
	gLanguageCsv.additionalNumber
}

local function getHuodongTypeFlag(hType)
	local isShow = false
	-- 副本次数增加的查询string
	local tb = {
		[1] = "goldActivity",
		[2] = "expActivity",
		[3] = "giftActivity",
		[4] = "fragActivity",
	}
	local str = tb[hType]
	if not str then return false end
	local isDouble, paramMaps, count = dataEasy.isDoubleHuodong(str)
	return isDouble, 2, paramMaps, count
end

local function getIsDoubleAward(hType)
	local isDouble, paramMaps, count = dataEasy.isDoubleHuodong("gateDrop")
	if not isDouble then return false end
	local sceneConf = csv.scene_conf
	for _, paramMap in pairs(paramMaps) do
		local startId= tonumber(paramMap["start"])
		local startConf = sceneConf[startId]
		local gateType = startConf.gateType
		if (gateType == game.GATE_TYPE.dailyGold and hType == 1) or 	-- 金币本
			(gateType == game.GATE_TYPE.dailyExp and hType == 2) or 	-- 经验本
			(gateType == game.GATE_TYPE.gift and hType == 3) or 	-- 礼物本
			(gateType == game.GATE_TYPE.fragment and hType == 4) then -- 碎片本
			return true
		end
	end
	return false
end

DailyActivityView.RESOURCE_FILENAME = "daily_activity.json"
DailyActivityView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("gateDatas"),
				item = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				-- asyncPreload = 5,
				padding = 70,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:name("item" .. v.csvId)
					local childs = node:multiget(
						"imgBg",
						"textName",
						"imgIcon",
						"flagIcon",
						"black",
						"timeInfo",
						"textDesc",
						"leftUp",
						"doubleFlag"
					)
					childs.imgBg:texture(v.background)
					childs.imgIcon:texture(v.icon)
					childs.textName:text(v.title)
					childs.flagIcon:visible(v.flagIconShow)
					childs.flagIcon:get("textNote"):text(REWARD_TYPE[v.flagIconType])
					childs.black:visible(v.notOpen)
					childs.timeInfo:get("textTime"):text(v.openTime)
					childs.textDesc:text(v.desc)
					childs.leftUp:get("textTimes"):text(v.surplusTimes.."/"..v.times)
					childs.doubleFlag:visible(v.isDoubleAward)
					node:setTouchEnabled(not v.notOpen)
					local str = gLanguageCsv.notOpenToday
					if v.levelNotEnough then
						childs.flagIcon:visible(false)
						str = string.format(gLanguageCsv.arrivalLevelOpen, v.openLevel)
					end
					childs.black:get("textNote"):text(str)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
}

function DailyActivityView:onCreate(targetTab, datas)
	adapt.centerWithScreen({"left", nil, false}, {"right", nil, false}, nil, {
		{self.list, "width"},
		{self.list, "pos", "left"},
	})
	self:initModel()

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.transcriptTitle, subTitle = "TRANSCRIPT"})

	local view = datas
	self.gateDatas = idlers.new()
	local huodongType = {
		game.PRIVILEGE_TYPE.HuodongTypeGoldTimes,
		game.PRIVILEGE_TYPE.HuodongTypeExpTimes,
	}
	idlereasy.any({self.huodongs, self.roleLv, self.trainerLevel},function(_, huodongs, roleLv, trainerLevel)
		self.day = view.day
		local gateDatas = {}
		local targetData = nil
		for k,v in orderCsvPairs(csv.huodong) do
			-- 若是一次性活动并且未开放期间，不显示界面
			if v.openType ~= 0 or view.open[k] then
				local currType = huodongType[v.huodongType]
				local addTime =  currType and dataEasy.getPrivilegeVal(currType) or 0
				local flagShow, flagType, paramMaps, count = getHuodongTypeFlag(v.huodongType)
				if flagType == 2 and flagShow then
					-- 增加次数要在外部显示
					addTime = addTime + paramMaps[1].count or 0 -- 只读取一个
				end
				local surplusTimes = v.times + addTime
				local curDate = tonumber(time.getTodayStrInClock())
				if huodongs[curDate] and huodongs[curDate][k] then
					surplusTimes = surplusTimes - huodongs[curDate][k].times
				end
				surplusTimes = math.max(surplusTimes, 0)
				table.insert(gateDatas, {
					csvId = k,
					background = v.background,
					title = v.name,
					icon = v.icon,
					typBg = v.typBg,
					notOpen = view.open[k] ~= 1,
					levelNotEnough = roleLv < v.openLevel,
					openLevel = v.openLevel,
					openTime = v.openTimeDesc,
					desc = v.desc,
					times = v.times + addTime,
					surplusTimes = surplusTimes,
					flagIconShow = flagShow,
					flagIconType = flagType,
					flagIconParamMap = flagShow and paramMaps[1],
					isDoubleAward = getIsDoubleAward(v.huodongType),
					sortValue = v.sortValue,
				})
				if v.type == targetTab and self.lastCsvId == nil then
					targetData = gateDatas[#gateDatas]
				end
			end
		end
		self.gateDatas:update(gateDatas)
		if targetData then
			self:onItemClick(nil, nil, targetData)
		end
	end)
end

function DailyActivityView:initModel()
	self.huodongs = gGameModel.role:getIdler("huodongs")
	self.roleLv = gGameModel.role:getIdler("level")
	self.trainerLevel = gGameModel.role:getIdler("trainer_level")
end

function DailyActivityView:onItemClick(list, k, v)
	self.lastCsvId = v.csvId
	gGameUI:stackUI("city.adventure.daily_activity.gate_select", nil, {full = true}, v.csvId, {
		show = v.flagIconShow,
		type = v.flagIconType,
		paramMap = v.flagIconParamMap,
		isDoubleAward = v.isDoubleAward,
	})
end

function DailyActivityView:onSortCards(list)
	return function(a, b)
		if a.notOpen ~= b.notOpen then
			return b.notOpen
		end
		return a.sortValue < b.sortValue
	end
end

return DailyActivityView