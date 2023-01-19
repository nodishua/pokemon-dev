-- @desc: 	activity-限时通行证-购买经验

local LOGO_RES = {
	[0] = {name = gLanguageCsv.discount, logo = "common/icon/sign_blue.png"}, -- 折
	[1] = {name = gLanguageCsv.hotness, logo = "common/icon/sign_orange.png"}, -- 热
	[2] = {name = gLanguageCsv.limit, logo = "common/icon/sign_purple.png"}, -- 限
	[3] = {name = gLanguageCsv.new, logo = "common/icon/sign_green.png"}, -- 新
}

local ActivityPassportBuyExpView = class("ActivityPassportBuyExpView", Dialog)
ActivityPassportBuyExpView.RESOURCE_FILENAME = "activity_passport_buy_exp.json"
ActivityPassportBuyExpView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},

	["item"] = "item",
	["itemList"] = "itemList",
	["expList"] = {
		varname = "expList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("expDatas"),
				item = bindHelper.self("itemList"),
				cell = bindHelper.self("item"),
				columnSize = 2,
				asyncPreload = 6,
				backupCached = false,
				-- itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("btnBuy", "txtExp", "imgState", "txtDiscount", "txtNode")
					childs.txtExp:text("+"..cfg.exp)
					if cfg.logo then
						childs.imgState:texture(LOGO_RES[cfg.logo].logo)
						if cfg.logo == 0 then
							local discount = string.format(gLanguageCsv.discount, cfg.discountValue)
							childs.txtDiscount:text(discount)
						else
							childs.txtDiscount:text(LOGO_RES[cfg.logo].name)
						end
					else
						childs.imgState:visible(false)
						childs.txtDiscount:visible(false)
					end
					for id,recharges in orderCsvPairs(csv.recharges) do
						if id == cfg.rechargeID then
							childs.btnBuy:getChildByName("txtNode"):text(string.format(gLanguageCsv.symbolMoney, recharges.rmbDisplay))
							break
						end
					end
					local totalExp = 0
					local nextLv = 1
					local huodongID = csv.yunying.yyhuodong[list.activityId()].huodongID
					for _,data in orderCsvPairs(csv.yunying.passport_award) do
						if data.huodongID == huodongID then
							totalExp = 	totalExp + data.needExp
							nextLv = data.level
							if (v.currentExp + cfg.exp) < totalExp then
								break
							end
						end
					end
					childs.txtNode:text(string.format(gLanguageCsv.buyToLevel, nextLv))
					bind.touch(list, childs.btnBuy, {clicksafe = true, methods = {ended = functools.partial(list.clickCell, v, v.currentExp + cfg.exp)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBuyClick"),
				activityId = bindHelper.self("activityId"),
			},
		},
	},
}

function ActivityPassportBuyExpView:onCreate(activityId)
	self:initModel()
	self.activityId = activityId
	self.expDatas = idlers.newWithMap({})

	idlereasy.when(self.passport, function(_, passport)
		local expDatas = {}
		for k,v in orderCsvPairs(csv.yunying.passport_recharge) do
			if v.type == 2 then
				table.insert(expDatas, {cfg = v, currentExp = passport.exp, csvId = k})
			end
		end
		self.expDatas:update(expDatas)
	end)

	Dialog.onCreate(self, {blackType = 1})
end

function ActivityPassportBuyExpView:initModel()
	self.passport = gGameModel.role:getIdler("passport")
end

-- @params exp 当前购买后的总经验值，用于判断是否溢出
function ActivityPassportBuyExpView:onBuyClick(list, v, exp)
	local totalExp = 0
	local huodongID = csv.yunying.yyhuodong[self.activityId].huodongID
	for id,data in orderCsvPairs(csv.yunying.passport_award) do
		if data.huodongID == huodongID then
			totalExp = 	totalExp + data.needExp
		end
	end

	local function pay()
		gGameApp:payCustom(self)
			:params({rechargeId = v.cfg.rechargeID, yyID = self.activityId, csvID = v.csvId, name = v.cfg.name})
			:serverCb(function()
				self:onClose()
			end)
			:doit()
	end

	if exp > totalExp then
		gGameUI:showDialog({title = "", content = gLanguageCsv.passportBuyExpOverflow, cb = pay, btnType = 2})
	else
		pay()
	end
end

function ActivityPassportBuyExpView:onClose()
	Dialog.onClose(self)
end

return ActivityPassportBuyExpView