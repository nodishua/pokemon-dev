-- @desc: 	activity-限时通行证-购买通行证

local ViewBase = cc.load("mvc").ViewBase
local ActivityGamePassportBuyExpView = class("ActivityGamePassportBuyExpView", Dialog)

ActivityGamePassportBuyExpView.RESOURCE_FILENAME = "activity_game_passport_buy_level.json"
ActivityGamePassportBuyExpView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas1"),
				columnSize = bindHelper.self("midColumnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				xMargin = 6,
				yMargin = 0,
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
						},
					})
				end,
			},
		},
	},
	["btn"] = {
		varname = "btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuyClick")}
		}
	},
	["text"] = {
		varname = "name",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(251, 110, 70, 255),  size = 8}}
		}
	},
	["barPanel"] = "barPanel",
	["barPanel.myFrags"] = "myFrags",
	["barPanel.needFrags"] = "needFrags",
	["barPanel.bar"] = "slider",
	["barPanel.subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["barPanel.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["text1"] = "text1",
	["text2"] = "text2",
	["text3"] = "text3",
	["text4"] = "text4",
}

function ActivityGamePassportBuyExpView:onCreate(activityId)
	self:initModel()
	self:enableSchedule()
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local dailyBuyTimes = yyCfg.paramMap.dailyBuyTimes
	self.activityId = activityId
	self.itemDatas1 = idlers.newWithMap({})
	self.midColumnSize = 8
	local type = yyCfg.paramMap.type
	-- self.btn:getChildByName("txtNode"):text(string.format(gLanguageCsv.symbolMoney, recharges.rmbDisplay))

	local level = self.yyhuodongs:read()[self.activityId].info.level or 0
	local buyTimes = self.yyhuodongs:read()[self.activityId].info.buy_times or 0
	local buyLevel = self.yyhuodongs:read()[self.activityId].info.buy_level or 0
	local isBuy = self.yyhuodongs:read()[self.activityId].info.elite_buy == 1
	local award = csv.yunying.playpassport_award
	local costTab = globals.gCostCsv["play_passport_buy_cost"..type]

	self.selectNum = idler.new(1)
	idlereasy.when(self.selectNum, function(_, selectNum)
		local itemDatas1 = {}
		local isHave = false
		self.canMaxNum = 0
		for k, v in csvPairs(award) do
			if v.huodongID == yyCfg.huodongID then
				if v.level > level and v.level <= level + selectNum then
					for key, val in csvMapPairs(v.normalAward) do
						for key1, val1 in ipairs(itemDatas1) do
							if val1.key == key then
								val1.num = val1.num + val
								isHave = true
								break
							end
						end
						if isHave == false then
							table.insert(itemDatas1, {key = key, num = val})
						else
							isHave = false
						end
					end
					if isBuy then
						for key, val in csvMapPairs(v.eliteAward) do
							for key1, val1 in ipairs(itemDatas1) do
								if val1.key == key then
									val1.num = val1.num + val
									isHave = true
									break
								end
							end
							if isHave == false then
								table.insert(itemDatas1, {key = key, num = val})
							else
								isHave = false
							end
						end
					end
				end
				self.canMaxNum = self.canMaxNum + 1
			end
		end
		self.canMaxNum = self.canMaxNum - level
		self.canMaxNum = math.min(self.canMaxNum, dailyBuyTimes - buyTimes)
		self.itemDatas1:update(itemDatas1)
		if not self.slider:isHighlighted() then
			local num = math.ceil(selectNum/self.canMaxNum*100)
			self.slider:setPercent(num)
		end
		uiEasy.setBtnShader(self.addBtn, nil, selectNum < self.canMaxNum and 1 or 2)
		uiEasy.setBtnShader(self.subBtn, nil, selectNum > 1 and 1 or 2)
		self.text2:text("Lv."..(level + selectNum))
		text.addEffect(self.text1, {outline={color=cc.c4b(255, 252, 237, 255), size = 3}})
		text.addEffect(self.text3, {outline={color=cc.c4b(255, 252, 237, 255), size = 3}})
		self.text1:text(gLanguageCsv.gamePassportBuyExpText1)
		self.text3:text(gLanguageCsv.gamePassportBuyExpText2)
		adapt.oneLineCenterPos(cc.p(1275, 1050), {self.text1, self.text2, self.text3}, cc.p(2, 0))
		-- self.text4:text(string.format(gLanguageCsv.gamePassportBuyExpText, selectNum, buyTimes, dailyBuyTimes))

		if self.richText then
			self.richText:removeSelf()
		end
		self.richText = rich.createWithWidth(string.format(gLanguageCsv.gamePassportBuyExpText, selectNum, buyTimes, dailyBuyTimes), 40, nil, 1250)
			:addTo(self.text4, 10)
			:anchorPoint(cc.p(0.5, 0.5))
			:xy(350, 5)
			:formatText()

		local rmb = 0
		local length = table.length(costTab)
		for i = 1, selectNum do
			rmb = rmb + costTab[math.min((i + buyLevel), length)]
		end
		self.cost = rmb
		self.btn:get("txt"):text(rmb)
	end)

	self.slider:addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local num = cc.clampf(math.ceil(self.canMaxNum * percent * 0.01), 1, self.canMaxNum)
		self.selectNum:set(num)
	end)

	Dialog.onCreate(self)
end

function ActivityGamePassportBuyExpView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.rmb = gGameModel.role:getIdler("rmb")
end

function ActivityGamePassportBuyExpView:onBuyClick()
	if self.rmb:read() < self.cost then
		uiEasy.showDialog("rmb", nil, {dialog = false})
		return
	else
		local title = gLanguageCsv.passwordTitleTip
		local buyExp = function()
			gGameApp:requestServer("/game/yy/playpassport/exp/buy", function(tb)
				gGameUI:showTip(gLanguageCsv.buySuccess)
				self:onClose()
			end, self.activityId, self.selectNum:read())
		end
		local params = {
			title = title,
			cb = buyExp,
			isRich = true,
			btnType = 2,
			content = string.format(gLanguageCsv.passportRmbCheck, self.cost),
			dialogParams = {clickClose = false},
		}
		gGameUI:showDialog(params)
	end
	-- gGameApp:requestServer("/game/yy/playpassport/exp/buy", function(tb)
	-- 	gGameUI:showTip(gLanguageCsv.buySuccess)
	-- 	self:onClose()
	-- end, self.activityId, self.selectNum:read())
end

function ActivityGamePassportBuyExpView:onChangeNum(node, event, step)
	if event.name == "click" then
		self:unScheduleAll()
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 100)

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

function ActivityGamePassportBuyExpView:onIncreaseNum(step)
	self.selectNum:modify(function(selectNum)
		return true, cc.clampf(selectNum + step, 1, self.canMaxNum)
	end)
end

return ActivityGamePassportBuyExpView