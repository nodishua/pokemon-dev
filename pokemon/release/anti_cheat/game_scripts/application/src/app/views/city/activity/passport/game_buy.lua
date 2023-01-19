-- @desc: 	activity-限时通行证-购买通行证

local ViewBase = cc.load("mvc").ViewBase
local ActivityGamePassportBuyView = class("ActivityGamePassportBuyView", Dialog)

ActivityGamePassportBuyView.RESOURCE_FILENAME = "activity_game_passport_buy.json"
ActivityGamePassportBuyView.RESOURCE_BINDING = {
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
				xMargin = 0,
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
	["list1"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas2"),
				columnSize = bindHelper.self("midColumnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				xMargin = 0,
				yMargin = 0,
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							onNode = function(node)
								local img = ccui.ImageView:create("common/btn/btn_lock1.png")
								:addTo(node, 1000, "img")
								:xy(160, 160)
							end,
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
		varname = "text1",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(251, 110, 70, 255),  size = 8}}
		}
	},
	["text1"] = {
		varname = "text2",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(97, 91, 97, 255),  size = 3}}
		}
	},
	["text2"] = {
		varname = "text3",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(97, 91, 97, 255),  size = 3}}
		}
	},
	["text3"] = {
		varname = "text4",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(97, 91, 97, 255),  size = 3}}
		}
	},
}

function ActivityGamePassportBuyView:onCreate(activityId, cb)
	self:initModel()
	self.cb = cb
	local yyCfg = csv.yunying.yyhuodong[activityId]
	self.endDate = yyCfg.endDate
	self.activityId = activityId
	self.itemDatas1 = idlers.newWithMap({})
	self.itemDatas2 = idlers.newWithMap({})
	self.midColumnSize = 4
	local itemDatas1 = {}
	local itemDatas2 = {}
	local rechargeCfg = csv.yunying.playpassport_recharge
	for k, v in csvMapPairs(rechargeCfg) do
		if v.huodongID == yyCfg.huodongID then
			self.csvId = k
		end
	end
	self.btn:get("txt"):text(string.format(gLanguageCsv.symbolMoney, csv.recharges[rechargeCfg[self.csvId].rechargeID].rmbDisplay))

	local level = self.yyhuodongs:read()[self.activityId].info.level

	local isHave = false
	for k, v in csvPairs(csv.yunying.playpassport_award) do
		if v.huodongID == yyCfg.huodongID and v.level <= level then
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
	self.itemDatas1:update(itemDatas1)

	for k, v in csvPairs(csv.yunying.playpassport_award) do
		if v.huodongID == yyCfg.huodongID and v.level > level then
			for key, val in csvMapPairs(v.eliteAward) do
				for key1, val1 in ipairs(itemDatas2) do
					if val1.key == key then
						val1.num = val1.num + val
						isHave = true
						break
					end
				end
				if isHave == false then
					table.insert(itemDatas2, {key = key, num = val})
				else
					isHave = false
				end
			end
		end
	end
	self.itemDatas2:update(itemDatas2)

	if itertools.isempty(itemDatas2) then
		self.list1:hide()
		self.text4:show()
		self.text4:text(gLanguageCsv.gamePassportBuyText)
	else
		self.list1:show()
		self.text4:hide()
	end

	-- local richText = rich.createWithWidth(gLanguageCsv.passportBuyText, 36, nil, 1250)
	-- 	:addTo(self.bg4, 10)
	-- 	:anchorPoint(0.5, 0.5)
	-- 	:xy(345, 48)
	-- 	:scale(0.5)
	-- 	:formatText()

	Dialog.onCreate(self)
end

function ActivityGamePassportBuyView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityGamePassportBuyView:onBuyClick()
	local lastTime = time.getNumTimestamp(self.endDate) - time.getTime()
	local time1, time2 = math.modf(lastTime / (3600 * 24))
	local title = gLanguageCsv.passwordTitleTip
	local str = gLanguageCsv.passwordBuyVipNote
	-- 在结束日期的几天之内会弹框提醒
	local lastDays = 7

	local buyVip = function()
		local rechargeCfg = csv.yunying.playpassport_recharge
		gGameApp:payDirect(self, {rechargeId = rechargeCfg[self.csvId].rechargeID, yyID = self.activityId, csvID = self.csvId, name = rechargeCfg[self.csvId].name, buyTimes = 0})
			:sdkLongTimeCb()
			:serverCb(function()
				self:onClose()
			end)
			:doit()
	end

	if lastTime < lastDays * 24 * 3600 then
		str = string.format(gLanguageCsv.playPasswordBuyVipTips, time1)
		if time1 < 1 then
			str = gLanguageCsv.passwordLastdayNote
		end
		local params = {
			title = title,
			cb = buyVip,
			isRich = false,
			btnType = 2,
			content = str,
			dialogParams = {clickClose = false},
		}
		gGameUI:showDialog(params)
	else
		buyVip()
	end
	-- buyVip()
end

function ActivityGamePassportBuyView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return ActivityGamePassportBuyView