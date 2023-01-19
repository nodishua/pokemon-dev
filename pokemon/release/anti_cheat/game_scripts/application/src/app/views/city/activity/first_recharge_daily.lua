-- @desc 每日充值活动
-- @desc generalTask 配置

-- 可领取，未达成 (不可领取)，已领取
local STATE_TYPE = {
	canReceive = 1,
	noReach = 0,
	received = 2,
}

local ActivityFirstRechargeDaily = class("ActivityFirstRechargeDaily", Dialog)

ActivityFirstRechargeDaily.RESOURCE_FILENAME = "activity_first_recharge_daily.json"
ActivityFirstRechargeDaily.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["buyBtn"] = {
		varname = "btn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuyClick")}
		},
	},
	["list"] = "list",
}

function ActivityFirstRechargeDaily:onCreate(activityId)
	gGameModel.currday_dispatch:getIdlerOrigin("firstRechargeDaily")
		:modify(function(data)
			data[activityId] = true
		end, true)
	self.activityId = activityId
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID

	-- 该活动 generaltask 只会配置1条
	for k, v in csvPairs(csv.yunying.generaltask) do
		if v.huodongID == huodongID then
			self.csvId = k
			uiEasy.createItemsToList(self, self.list, v.award, {
				onAfterBuild = function()
					self.list:setItemAlignCenter()
				end,
			})
			break
		end
	end
	self.state = STATE_TYPE.noReach
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[activityId] or {}
		local stamps = yydata.stamps or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.generaltask) do
			if v.huodongID == huodongID then
				-- yydata.stamps[k] : 1:可领取，0：已领取，其他：不可领取
				local btn = self.btn
				local label = btn:get("label")
				if stamps[k] == 1 then
					self.state = STATE_TYPE.canReceive
					label:text(gLanguageCsv.spaceReceive)
					cache.setShader(btn, false, "normal")
					text.addEffect(label, {glow = {color = ui.COLORS.GLOW.WHITE}})
					btn:setTouchEnabled(true)

				elseif stamps[k] == 0 then
					self.state = STATE_TYPE.received
					label:text(gLanguageCsv.received)
					text.deleteAllEffect(label)
					cache.setShader(btn, false, "hsl_gray")
					btn:setTouchEnabled(false)
				else
					self.state = STATE_TYPE.noReach
					label:text(gLanguageCsv.goToRecharge)
					cache.setShader(btn, false, "normal")
					text.addEffect(label, {glow = {color = ui.COLORS.GLOW.WHITE}})
					btn:setTouchEnabled(true)
				end
			end
		end
	end)

	Dialog.onCreate(self, {blackType = 1})
end

function ActivityFirstRechargeDaily:onBuyClick()
	if self.state == STATE_TYPE.noReach then
		gGameUI:stackUI("city.recharge", nil, {full = true})

	elseif self.state == STATE_TYPE.canReceive then
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.activityId, self.csvId)
	end
end

return ActivityFirstRechargeDaily