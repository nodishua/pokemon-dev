--奖券兑换
local Double11Lottery = class("Double11Lottery", Dialog)

local CARD_STATUS = {
    CAN_OPEN = 1,
    OPENED = 2,
    GOTTEN_AWARD = -1,
}

Double11Lottery.RESOURCE_FILENAME = "double_11_lottery.json"
Double11Lottery.RESOURCE_BINDING = {
	["rightPanel1"] = "rightPanel1",
	["rightPanel2"] = "rightPanel2",
    ["rightPanel1.list2"] = "innerList",
    ["rightPanel1.item"] = "item",
    ["rightPanel1.list1"] = {
        varname = "list",
        binds = {
            event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("lotteryData"),
				item = bindHelper.self('innerList'),
				cell = bindHelper.self('item'),
				columnSize = 2,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					node:get("textName"):text(v.name)
					node:get("textProbability"):text("("..gLanguageCsv.double11Probability..v.weight.."%)")
					node:get("textNum"):text(string.format(gLanguageCsv.double11Num,v.num))
					uiEasy.createItemsToList(list, node:get("awardList"), v.award, {scale = 0.9})
				end,
			}
        },
    },
    ["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["leftItem"] = "leftItem",
	["leftList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnsAttr"),
				item = bindHelper.self("leftItem"),
				padding = 5,
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
						panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					else
						selected:hide()
						panel = normal:show()
						panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					end

					local maxHeight = panel:size().height - 20
					adapt.setAutoText(panel:get("txt"), v.name, maxHeight)

					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftButtonClick"),
			},
		}
	},
	["rightPanel2.item"] = "recordItem",
	["rightPanel2.list1"] = {
        binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("record"),
				item = bindHelper.self("recordItem"),
				padding = 10,
				onItem = function(list, node, k, v)
					node:get("textName"):text(string.format(gLanguageCsv.double11IndexAward, v.index))
					node:get("textProbability"):text("")
					local str = ""
					if v.num and v.awardName then
						str = string.format(gLanguageCsv.double11AwardTips1, v.num, v.num, v.awardName)
					elseif v.num then
						str = string.format(gLanguageCsv.double11AwardTips2, v.num)
					else
						str = string.format(gLanguageCsv.double11AwardTips3)
					end
					local richText = rich.createByStr(string.format(str, 40))
						:addTo(node, 10)
						:xy(node:get("textProbability"):x(), node:get("textProbability"):y())
						:anchorPoint(cc.p(0.5, 0.5))
						:formatText()
                end,
                dataOrderCmp = function (a, b)
					return a.index > b.index
				end,
			},
		}
    },
}

function Double11Lottery:onCreate(huodongID, nowGameIndex, activityId, datas, csvId)
	Dialog.onCreate(self)
	self.nowGameIndex = nowGameIndex
	self.activityId = activityId
	self.csvId = csvId
	self:initGameCfg()
	self:initData(huodongID, datas)
	self:initModel()
	self:showScratch()
end

function Double11Lottery:initGameCfg()
    self.gameCfg = {}
    for k, cfg in orderCsvPairs(csv.yunying.double11_game) do
        if cfg.huodongID == csv.yunying.yyhuodong[self.activityId].huodongID then
            self.gameCfg[cfg.game] = {itemId = cfg.itemID, csvId = k}
        end
    end
end

function Double11Lottery:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.record = idlers.new()
	self.tabIndex = idler.new(1)
	self.cardNum = nil
	self.win = false
	self.btnsAttr = idlers.newWithMap(
		{{name = gLanguageCsv.double11Award, select = true},
		{name = gLanguageCsv.double11Record,  select = false},}
	)

	self.tabIndex:addListener(function (val, oldval, idler)
		self.btnsAttr:atproxy(oldval).select = false
		self.btnsAttr:atproxy(val).select = true
		if val== 1 and oldval == 1 then
			self["rightPanel2"]:hide()
			self["rightPanel1"]:show()
		else
			self["rightPanel"..oldval]:hide()
			self["rightPanel"..val]:show()
		end
	end)
	idlereasy.when(self.yyhuodongs,function(_, yyhuodong)
		local record = {}
		local yydata = yyhuodong[self.activityId] and yyhuodong[self.activityId].double11
		if yydata then
			if yydata[self.csvId] and yydata[self.csvId].card_num then
				self.cardNum = yydata[self.csvId].card_num
			end
			if yydata[self.csvId] and yydata[self.csvId].lottery_csv_id > 0 then
				self.win = true
			end
			for i = 1, #self.gameCfg do
				local csvId = self.gameCfg[i].csvId
				if i <= self.nowGameIndex then
					if yydata[csvId] then
						local lottery_csv_id = yydata[csvId].lottery_csv_id
						if yydata[csvId].card_status ~= CARD_STATUS.CAN_OPEN and csv.yunying.double11_lottery[lottery_csv_id] then
							table.insert(record, {
								index = i,
								awardName = csv.yunying.double11_lottery[lottery_csv_id].name,
								num = yydata[csvId].card_num
							})
						else
							table.insert(record, {
								index = i,
								num = yydata[csvId].card_num
							})
						end
					else
						table.insert(record, {
							index = i,
						})
					end
				end
			end
		else
			for i = 1, #self.gameCfg do
				if i < self.nowGameIndex then
					table.insert(record, {
						index = i,
					})
				end
			end
		end
		self:initUI()
		self.record:update(record)
		self.rightPanel2:get("duckPanel"):setVisible(#record == 0)
	end)
end

function Double11Lottery:initData(huodongID, datas)
	local lottery = csv.yunying.double11_lottery
	self.lotteryData = {}
	if datas then
		for k, v in orderCsvPairs(lottery) do
			if v.huodongID == huodongID then
				local data = table.shallowcopy(v)
				data.num = datas[k]
				table.insert(self.lotteryData, data)
			end
		end
	end
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local gameTime = yyCfg.paramMap.gameTime
	local oneDayCount = 0
    for index, times in orderCsvPairs(gameTime) do
        oneDayCount = oneDayCount + 1
	end

	local todayIndex = self.nowGameIndex % oneDayCount == 0 and oneDayCount or self.nowGameIndex % oneDayCount--当天场次
	local hour, min = time.getHourAndMin(gameTime[todayIndex][2])
	self.timeStr = hour .. ":" .. min
end

function Double11Lottery:initUI(huodongID, datas)
	local imgTicket = self.rightPanel1:get("imgTicket")
	local imgNoTicket = self.rightPanel1:get("imgNoTicket")
	local textTip1 = self.rightPanel1:get("textTip1") --需要参与本场天降豪礼活动后才可获得奖券！
	local textTip2 = self.rightPanel1:get("textTip2") --很遗憾，您未中奖！
	local textTip3 = self.rightPanel1:get("textTip3") --恭喜中奖！
	local textTip4 = self.rightPanel1:get("textTip4") --奖励将在 18:30 统一邮件发放
	if self.cardNum then
		imgTicket:show()
		imgTicket:get("textNote"):text(string.format(gLanguageCsv.double11Num,self.cardNum))
		imgNoTicket:hide()
		textTip1:hide()
		if self.win then
			textTip2:hide()
			textTip3:show()
			textTip4:show():text(string.format(gLanguageCsv.doubleAwardTime,self.timeStr))
		else
			textTip2:show()
			textTip3:hide()
			textTip4:hide()
		end
	else
		imgTicket:hide()
		imgNoTicket:show()
		textTip1:show()
		textTip2:hide()
		textTip3:hide()
		textTip4:hide()
	end
end

function Double11Lottery:showScratch(list, index)
	local yydata = self.yyhuodongs:read()[self.activityId] and self.yyhuodongs:read()[self.activityId].double11
	local index = self.nowGameIndex
	if self.nowGameIndex > #self.gameCfg then
		index = #self.gameCfg
	end
	local csvId = self.gameCfg[index].csvId
	if yydata and yydata[csvId] and yydata[csvId].card_status == CARD_STATUS.CAN_OPEN then
		local num = yydata[csvId].card_num
		gGameUI:stackUI("city.activity.double11.scratch", nil, nil, self.activityId, csvId, num)
	end
end
function Double11Lottery:onLeftButtonClick(list, index)
	self.tabIndex:set(index)
end

return Double11Lottery