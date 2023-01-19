-- @desc: 	activity-限时通行证-购买通行证

local ViewBase = cc.load("mvc").ViewBase
local ActivityPassportBuyView = class("ActivityPassportBuyView", Dialog)

local LOGO_RES = {
	[0] = {name = gLanguageCsv.discount, logo = "common/icon/sign_blue.png"}, -- 折
	[1] = {name = gLanguageCsv.hotness, logo = "common/icon/sign_orange.png"}, -- 热
	[2] = {name = gLanguageCsv.limit, logo = "common/icon/sign_purple.png"}, -- 限
	[3] = {name = gLanguageCsv.new, logo = "common/icon/sign_green.png"}, -- 新
}

ActivityPassportBuyView.RESOURCE_FILENAME = "activity_passport_buy.json"
ActivityPassportBuyView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["bg4"] = "bg4",
	["item"] = "item",
	["itemList"] = {
		varname = "itemList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("item"),
				backupCached = false,
				-- itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("imgTitle", "btnBuy", "txtList", "imgState", "txtDiscount", "line", "originalPrice", "icon")
					childs.imgTitle:texture(cfg.res)
					if matchLanguage({"kr"}) then
						childs.imgTitle:scale(1.9)
					end
					childs.icon:texture(cfg.icon)

					local rechargesCfg = csv.recharges
					local price = 0  -- 价格
					for id,recharges in orderCsvPairs(rechargesCfg) do
						if id == cfg.rechargeID then
							price = recharges.rmbDisplay
							childs.btnBuy:getChildByName("txtNode"):text(string.format(gLanguageCsv.symbolMoney, recharges.rmbDisplay))
							break
						end
					end

					childs.originalPrice:visible(cfg.logo == 0)
					childs.line:visible(cfg.logo == 0)
					if cfg.logo then
						childs.imgState:texture(LOGO_RES[cfg.logo].logo)
						if cfg.logo == 0 then
							local discount = string.format(gLanguageCsv.discount, cfg.discountValue)
							childs.txtDiscount:text(discount)
							childs.originalPrice:text(string.format(gLanguageCsv.symbolMoney, price/cfg.discountValue*10)) --计算原价
							childs.line:width(childs.originalPrice:width() + 20)
						else
							childs.txtDiscount:text(LOGO_RES[cfg.logo].name)
						end
					else
						childs.imgState:hide()
						childs.txtDiscount:hide()
					end

					beauty.textScroll({
						list = childs.txtList,
						strs = cfg.desc,
						align = "left",
						isRich = true,
						verticalSpace = 20,
					})
					bind.touch(list, childs.btnBuy, {clicksafe = true, methods = {ended = functools.partial(list.clickCell, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
			},
		},
	},
}

function ActivityPassportBuyView:onCreate(activityId, cb)
	self:initModel()
	self.cb = cb
	local yyCfg = csv.yunying.yyhuodong[activityId]
	self.endDate = yyCfg.endDate
	self.activityId = activityId
	self.itemDatas = idlers.newWithMap({})
	local rechargeCfg = csv.yunying.passport_recharge
	local itemDatas = {}
	for k,v in orderCsvPairs(rechargeCfg) do
		if v.type == 1 then
			table.insert(itemDatas, {cfg = v, csvId = k})
		end
	end
	self.itemDatas:update(itemDatas)

	local richText = rich.createWithWidth(gLanguageCsv.passportBuyText, 35, nil, 1250)
		:addTo(self.bg4, 10)
		:anchorPoint(0.5, 0.5)
		:xy(345, 48)
		:scale(0.5)
		:formatText()
	if matchLanguage({"kr"}) then
		richText:scale(0.44)
		richText:xy(290, 48)
	end

	Dialog.onCreate(self, {blackType = 1})
end

function ActivityPassportBuyView:initModel()

end

function ActivityPassportBuyView:onBuyClick(list, v)
	local lastTime = time.getNumTimestamp(self.endDate) - time.getTime()
	local time1, time2 = math.modf(lastTime / (3600 * 24))
	local title = gLanguageCsv.passwordTitleTip
	local str = gLanguageCsv.passwordBuyVipNote
	local buyVip = function()
		gGameApp:payDirect(self, {rechargeId = v.cfg.rechargeID, yyID = self.activityId, csvID = v.csvId, name = v.cfg.name, buyTimes = 0})
			:sdkLongTimeCb()
			:serverCb(function()
				self:onClose()
			end)
			:doit()
	end

	if lastTime < 14 * 24 * 3600 then
		str = string.format(gLanguageCsv.passwordBuyVipTips, time1)
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
end

function ActivityPassportBuyView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return ActivityPassportBuyView