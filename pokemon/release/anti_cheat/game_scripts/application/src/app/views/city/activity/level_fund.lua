-- @Date:   2019-05-09
-- @Desc: 等級基金
-- @Last Modified time: 2019-05-09

-- 可领取，未达成 (不可领取)，已领取
local STATE_TYPE = {
	canReceive = 1,
	noReach = 2,
	received = 3,
}

local ActivityLevelFund = class("ActivityLevelFund", cc.load("mvc").ViewBase)

ActivityLevelFund.RESOURCE_FILENAME = "activity_level_fund.json"
ActivityLevelFund.RESOURCE_BINDING = {
	["item"] = "item",
	["buyBtn"] = {
		varname = "buyBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuyFundClick")},
		},
	},
	["buyBtn.label"] = "buyLabel",
	["diamondNum"] = {
		varname = "diamondNum",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(243, 146, 101, 255)}}
		}
	},
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				level = bindHelper.self("level"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("list", "num", "receivebtn", "received", "desc")
					uiEasy.createItemsToList(list, childs.list, cfg.award)
					childs.desc:text(cfg.desc)
					text.addEffect(childs.num, {color = ui.COLORS.NORMAL.FRIEND_GREEN})
					childs.num:text(string.format("%d/%d", list.level, cfg.needLevel))
					childs.receivebtn:visible(v.state ~= STATE_TYPE.received)
					childs.received:visible(v.state == STATE_TYPE.received)
					childs.receivebtn:setTouchEnabled(false)
					cache.setShader(childs.receivebtn, false, "normal")
					local receiveLabel = childs.receivebtn:get("label")
					if v.state == STATE_TYPE.canReceive then
						childs.receivebtn:setTouchEnabled(true)
						text.addEffect(receiveLabel, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
						bind.touch(list, childs.receivebtn, {methods = {ended = functools.partial(list.clickCell, k, v)}})

					elseif v.state == STATE_TYPE.noReach then
						text.addEffect(childs.num, {color = ui.COLORS.NORMAL.ALERT_ORANGE})
						cache.setShader(childs.receivebtn, false, "hsl_gray")
						text.deleteAllEffect(receiveLabel)
						text.addEffect(receiveLabel, {color = ui.COLORS.DISABLED.WHITE})
					end
				end,
				asyncPreload = 5,
			},
			handlers = {
				clickCell = bindHelper.self("onReceiveClick"),
			},
		},
	},
	["tipsPanel"] = "tipsPanel",
	["tipsBg1"] = "tipsBg1",
	["tipsBg2"] = "tipsBg2",
}

function ActivityLevelFund:onCreate(activityId)
	self.activityId = activityId
	self:initModel()
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	self.diamondNum:text(yyCfg.paramMap.rmb)

	local totalRmb = 0 -- 总钻石
	for k, v in csvPairs(csv.yunying.levelfund) do
		if v.huodongID == huodongID then
			if v.award.rmb then
				totalRmb = totalRmb + v.award.rmb
			end
		end
	end

	-- 富文本创建提示语
	local richText = rich.createByStr(string.format(gLanguageCsv.levelFundTitle1, yyCfg.paramMap.rmb, totalRmb), 40) -- fontSize 40
		:anchorPoint(0, 0.5)
		:xy(self.tipsBg1:x() + 20, self.tipsBg1:y()) -- +20, 富文本和背景相比较，后撤20像素显示
		:addTo(self:getResourceNode())
		:z(10)
	local richText2 = rich.createByStr(string.format(gLanguageCsv.levelFundTitle2, ui.VIP_ICON[yyCfg.paramMap.vip]), 40) -- fontSize 40
		:anchorPoint(0, 0.5)
		:xy(self.tipsBg2:x() + 20, self.tipsBg2:y()) -- +20, 富文本和背景相比较，后撤20像素显示
		:addTo(self:getResourceNode())
		:z(10)
	richText:formatText()
	richText2:formatText()
	self.tipsBg1:width(richText:width() + 40) -- 动态设置底图大小，左右各空出20像素
	self.tipsBg2:width(richText2:width() + 40) -- 动态设置底图大小，左右各空出20像素

	self.datas = idlers.new()
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local yydata = yyhuodongs[activityId] or {}
		if not yydata.buy then
			self.buyBtn:setTouchEnabled(true)
			self.buyLabel:text(gLanguageCsv.buy)
			text.addEffect(self.buyLabel, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
		else
			self.buyBtn:setTouchEnabled(false)
			cache.setShader(self.buyBtn, false, "hsl_gray")
			text.deleteAllEffect(self.buyLabel)
			self.buyLabel:text(gLanguageCsv.hasBuy)
			text.addEffect(self.buyLabel, {color = ui.COLORS.DISABLED.WHITE})
		end
		local stamps = yydata.stamps or {}
		local yyProgress = gGameModel.role:getYYHuoDongTasksProgress(activityId) or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.levelfund) do
			if v.huodongID == huodongID then
				local state = STATE_TYPE.noReach
				-- yydata.stamps[k] : 1:可领取，0：已领取，其他：不可领取
				if stamps[k] == 1 then
					state = STATE_TYPE.canReceive

				elseif stamps[k] == 0 then
					state = STATE_TYPE.received
				end
				table.insert(datas, {csvId = k, cfg = v, state = state, progress = yyProgress[k]})
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.datas:update(datas)
	end)
end

function ActivityLevelFund:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.level = gGameModel.role:read("level")
end

function ActivityLevelFund:onReceiveClick(list, k, v)
	if v.state == STATE_TYPE.canReceive then
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.activityId, v.csvId)

	elseif v.state == STATE_TYPE.noReach then
		gGameUI:showTip(gLanguageCsv.notReachedCannotGet)
	end
end

function ActivityLevelFund:onBuyFundClick()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local rmb = gGameModel.role:read("rmb")
	local vip = gGameModel.role:read("vip_level")
	if vip < yyCfg.paramMap.vip then
		gGameUI:showDialog({title = "", content = gLanguageCsv.fundVipNotEnough, cb = function()
			gGameUI:stackUI("city.recharge", nil)
		end, btnType = 2, btnStr = gLanguageCsv.showVip, isRich = true, clearFast = true, dialogParams = {clickClose = false}})
		return
	elseif rmb < yyCfg.paramMap.rmb then
		uiEasy.showDialog("rmb")
		return
	end
	gGameUI:showDialog({title = "", content = gLanguageCsv.fundBuyConfirm, cb = function()
		gGameApp:requestServer("/game/yy/levelfund/buy", function(tb)
			gGameUI:showTip(gLanguageCsv.buySuccess)
		end, self.activityId)
	end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
end

return ActivityLevelFund