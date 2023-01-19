-- @Date:   2021-10-13
-- @Desc:   定制礼包

-- 计算有多少个可选奖励总数
local function optionNums(awards)
	local count = 0
	for k,v in ipairs(awards) do
		if not v.isFixAwards then 
			count = count + 1
		end
	end
	return count
end

local function bindIcon(list, node, data, touch)
	bind.extend(list, node:get("pic"), {
		class = "icon_key",
		props = {
			data = data,
			onNode = function(panel)
				panel:setTouchEnabled(touch)
				node:scale(0.9)
			end
		},
	})
end

local function setIcon(list, v, totalSlotNum, icon, value)
	icon:visible(true)
	if value.isFixAwards  then
		icon:get("add"):hide()
		icon:get("select"):hide()
		bindIcon(list, icon, dataEasy.getItemData(value.showAwards)[1], true)
	elseif value.choose and value.choose > 0   then
		icon:get("add"):hide()
		icon:get("select"):visible(v.isCanBuy)
		local award = value.showAwards[value.choose]
		bindIcon(list, icon, dataEasy.getItemData(award)[1],not v.isCanBuy)
		if v.isCanBuy then
			bind.touch(list, icon:get("pic"), {clicksafe = false, methods = {ended = functools.partial(list.clickCell, v, totalSlotNum, value.optionSlotNum, value.showAwards, value.choose)}})
		end
	else
		icon:get("add"):show()
		icon:get("select"):hide()
		icon:get("pic"):hide()
		bind.touch(list, icon:get("add"), {clicksafe = false, methods = {ended = functools.partial(list.clickCell, v, totalSlotNum, value.optionSlotNum, value.showAwards, 0)}})
	end
end

local ActivityCustomizeGiftDialog = class("ActivityCustomizeGiftDialog",Dialog)
ActivityCustomizeGiftDialog.RESOURCE_FILENAME = "activity_customize_gift.json"
ActivityCustomizeGiftDialog.RESOURCE_BINDING = {
	["close"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["tip"] ={
		varname = "tip",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(229, 69, 69, 255), size = 4}}
		},
	},
	["item"] = "item",
	["icon"] = "icon",
	["panel"] = "panel",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemsData"),
				item = bindHelper.self("panel"),
				itemAction = {isAction = false},
				margin = 0,
				paddings = 10,
				dataOrderCmp = function(a, b)
					if a.isCanBuy ~= b.isCanBuy then
						return  a.isCanBuy
					end
					if a.rmb ~= b.rmb then
						return a.rmb < b.rmb
					end
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "icon1", "icon2", "icon3", "icon4", "textContent", "btn")
					childs.name:text(v.name)
					childs.textContent:get("bg"):visible(not v.isCanBuy)
					childs.textContent:get("btn"):visible(v.isCanBuy)
					childs.textContent:get("btn"):get("red"):show()
					childs.textContent:get("limitLabel"):text(string.format(gLanguageCsv.foreverLimit, v.hasBoughtNum, v.buyTimes))
					if v.hasAllChoose then
						text.addEffect(childs.textContent:get("btn"):get("title"), {color = ui.COLORS.WHITE})
						cache.setShader(childs.textContent:get("btn"):get("red"), false, "normal")
					else
						text.addEffect(childs.textContent:get("btn"):get("title"), {color = cc.c4b(222, 218, 209, 255)})
						cache.setShader(childs.textContent:get("btn"):get("red"), false, "hsl_gray")
					end
					childs.textContent:get("btn"):get("title"):text(string.format(gLanguageCsv.symbolMoney,v.rmbDisplay))

					bind.touch(list, childs.textContent:get("btn"), {clicksafe = false, methods = {ended = functools.partial(list.clickBuy, v)}})

					local num = itertools.size(v.awards)
					for i = 1,4 do
						local localIcon = node:get("icon" .. i)
						localIcon:visible(false)
						if i <= num then
							setIcon(list, v, optionNums(v.awards), localIcon, v.awards[i])
					    end
					end
				end,
				asyncPreload = 4,
			},
			handlers = {
				clickCell = bindHelper.self("pushView"),
				clickBuy = bindHelper.self("clickBuy"),
		   },
		}
	},
	["timeLabel"] = {
		varname = "timeLabel",
	},
	["panel.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.WHITE, size = 3}}
		},
	}
}

function ActivityCustomizeGiftDialog:onCreate(activityId)
	gGameModel.forever_dispatch:getIdlerOrigin("customizeGiftClick"):set(true)
	self.activityId = activityId
	self.huodongID = csv.yunying.yyhuodong[self.activityId].huodongID
	self.timeout = false
	self:initModel()
	self:initData()
	self:initUI()
	Dialog.onCreate(self, {blackType = 1})
end

function ActivityCustomizeGiftDialog:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.itemsData = idlers.new()
	self.clientBuyTimes = idler.new(true)
end

function ActivityCustomizeGiftDialog:initData()
	idlereasy.any({self.yyhuodongs}, function(_, yyhuodong)
		-- dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		local itemData  = {}
		itemData = self:initCsv(yyhuodong[self.activityId])
		self.itemsData:update(itemData, function(v) return v.rechargeID end)
		dataEasy.tryCallFunc(self.list, "filterSortItems", true)
	end)
end

function ActivityCustomizeGiftDialog:initCsv(serverData)
	local itemsData = {}
	local yycfg = csv.yunying.customize_gift
	local awardsData = {}
	local optionAwards = {}

	local function getServerChoose(csvId, num)
		return  serverData and serverData.choose and serverData.choose[csvId] and serverData.choose[csvId][num]
	end

	local function getBuyTimes(csvId)
			return  serverData and serverData.stamps and serverData.stamps[csvId]
		and (serverData.stamps[csvId] > 0) and serverData.stamps[csvId]
	end

	-- 插入awards参数，isFisAwards为真，则是固定奖励，否为，可选奖励。
	-- 若为固定奖励，showAwards为特定奖励，否则为数组,包含所有可选奖励
	-- optionSlotNum 为第N个可选奖励Num,choose 为是否选中
	local function insertAwards(data, showAwards, isFixAwards, optionSlotNum, choose)
		if itertools.size(showAwards) > 0 then
			table.insert(data, {
				showAwards = showAwards,
				isFixAwards = isFixAwards,
				optionSlotNum = optionSlotNum,
				choose = choose,
			})
			if not choose or choose == 0 then
				return false
			else
				return true
			end
		end
		return true
	end

	-- 从配表中获取原始购买数据，然后和服务器选中数组比对，如果数组值不为空，就标记选中
	for key, data in pairs(yycfg) do
		if data.huodongID == self.huodongID then 
			local awardsData = {}
			local choose = {}
			local hasAllChoose = true
			local optionAwards = {data.optionalAwards1, data.optionalAwards2, data.optionalAwards3, data.optionalAwards4}

			insertAwards(awardsData, data.awards, true)
			for k, v in ipairs(optionAwards) do
				if not insertAwards(awardsData, v, false, k, getServerChoose(key, k)) then
					hasAllChoose = false
				end
			end

			local leftTime = data.buyTimes - (getBuyTimes(key) or 0)
			table.insert(itemsData,{
				awards = awardsData,
				buyTimes = data.buyTimes, --限购次数
				name = data.name,
				rechargeID = data.rechargeID,
				rmbDisplay = csv.recharges[data.rechargeID].rmbDisplay,
				rmb = csv.recharges[data.rechargeID].rmb,
				hasBoughtNum = getBuyTimes(key) or 0,
				isCanBuy = leftTime > 0 ,
				icon = data.icon,
				csvId = key,
				hasAllChoose = hasAllChoose,
			})
		end
	end
	return itemsData

end

function ActivityCustomizeGiftDialog:initUI()
	self:setTimeLabel()
end

function ActivityCustomizeGiftDialog:setTimeLabel()
	self.endTime = gGameModel.role:read("yy_endtime")[self.activityId]
	local  timeNum = self.endTime - time.getTime()
	if timeNum < 0 then
		self.timeLabel:text(gLanguageCsv.activityOver)
	end
	self:enableSchedule():schedule(function()
		timeNum = self.endTime - time.getTime()
		local tTime = time.getCutDown(timeNum)
		if timeNum <= 0 then
			self.timeout = true
			self.timeLabel:text(gLanguageCsv.activityOver)
			return false
		else
			local str = ""
			if tTime.day >= 1 then
				str = tTime.str
			else
				str = tTime.clock_str
			end
			self.timeLabel:text(gLanguageCsv.exclusiveRestrictionClose .. str)
			return true
		end
	end, 1, 0)
end

function ActivityCustomizeGiftDialog:pushView(list, v, slotNums, selectNum, data, choose)
	gGameUI:stackUI("city.activity.customize_gift_select", nil, nil, self.activityId, v, slotNums, selectNum, data, choose)
end

function ActivityCustomizeGiftDialog:clickBuy(list, v)
	if self.timeout then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end

	if not v.hasAllChoose then
		gGameUI:showTip(gLanguageCsv.selectGiftTip)
		return
	end

	local awards = {}
	for k, v in pairs(v.awards) do
		if v.isFixAwards then
			table.insert(awards, v.showAwards)
		else
			table.insert(awards, v.showAwards[v.choose])
		end
	end

	gGameApp:payDirect(self, {rechargeId = v.rechargeID, yyID = self.activityId, csvID = v.csvId, buyTimes = v.hasBoughtNum, name = v.name}, self.clientBuyTimes)
	:serverCb(function()
	--	gGameUI:showGainDisplay(awards, {raw = false})
	end)
	:doit()

end

return ActivityCustomizeGiftDialog