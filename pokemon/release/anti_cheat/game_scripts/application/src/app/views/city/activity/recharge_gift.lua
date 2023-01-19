-- @Date:   2019-05-30
-- @Desc:
local STATE_TYPE = {
	canReceive = 1,
	noReach = 2,
	received = 3,
}
local ActivityView = require "app.views.city.activity.view"
local ActivityRechargeGift = class("ActivityRechargeGift", cc.load("mvc").ViewBase)
local multiple = matchLanguage({"cn"}) and 10 or 1
local function createForeverAnim(x, y)
	return cc.RepeatForever:create(
		cc.Sequence:create(
			cc.DelayTime:create(0.1),
			cc.MoveTo:create(0.3, cc.p(x, y + 10)),
			cc.DelayTime:create(0.1),
			cc.MoveTo:create(0.3, cc.p(x, y))
		)
	)
end
ActivityRechargeGift.RESOURCE_FILENAME = "activity_recharge_gift.json"
ActivityRechargeGift.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				dataOrderCmp = dataEasy.sortItemCmp,
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = v,
							onNode = function(panel)
								panel:y(185)
							end
						},
					})
					node:get("name"):text(uiEasy.setIconName(v.key, v.num))
					node:get("name"):getVirtualRenderer():setLineSpacing(-15)
					text.addEffect(node:get("name"), {outline = {color = ui.COLORS.OUTLINE.WHITE}})
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end
			},
		},
	},
	["bigTarget"] = "icon",
	["target"] = {
		binds = {
			event = "extend",
			class = "icon_key",
			props = {
				data = bindHelper.self("targetData"),
			},
		}
	},
	["rmb"] = "rmb",
	["txtBg"] = "txtBg",
	["itemBox"] = "boxItem",
	["boxList"] = {
		varname = "boxList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("boxData"),
				item = bindHelper.self("boxItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("icon", "select", "light")
					childs.select:visible(v.selected == true)
					childs.icon:texture("common/icon/icon_signin_box2"..((v.state == STATE_TYPE.received) and "_open.png" or ".png"))
					local boxCanOpen = v.state == STATE_TYPE.canReceive
					if boxCanOpen then
						local effect = widget.addAnimation(node, "effect/jiedianjiangli.skel", "effect_loop", childs.icon:z() - 1)
						local size = childs.icon:size()
						effect:scale(0.5)
							:x(childs.icon:x() - size.width / 2 + 35)
							:y(childs.icon:y() - 16)
						node.effectBox = effect
					elseif not boxCanOpen then
						if node.effectBox then
							node.effectBox:hide()
							node.effectBox:removeFromParent()
							node.effectBox = nil
						end
					end
					childs.light:hide()
					bind.touch(list, childs.icon, {methods = {ended = functools.partial(list.clickBox, k, v, node)}})
					if not v.originY then
						v.originX, v.originY = childs.select:xy()
					end
					v.action = v.action or createForeverAnim(v.originX, v.originY)
					childs.select:stopAction(v.action)
					if v.selected then
						v.action = createForeverAnim(v.originX, v.originY)
						childs.select:runAction(v.action)
					end
				end,
			},
			handlers = {
				clickBox = bindHelper.self("onBoxClick"),
			},
		},
	},
	["timeTxt"] = {
		varname = "timeLabel",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 4}}
			},
		}
	},

	["time"] = {
		varname = "time",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 4}}
			},
		}
	},
	["bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("barPoint"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		}
	},
	["barBg"] = "barBg",
	["recieveBtn"] = {
		varname = "recieveBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRecieveClick")}
		}
	},
	["rechargeBtn"] = {
		varname = "rechargeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRechargeClick")}
		}
	},
	["recievedBtn"] = "recievedBtn",
}

function ActivityRechargeGift:onCreate(activityID)
	self.activityID = activityID
	local yyCfg = csv.yunying.yyhuodong[activityID]
	local yyHdid = gGameModel.role:read("yy_hdid") or {}
	local huodongID = yyHdid[activityID] or yyCfg.huodongID

	self.originX = self.list:x()
	self.boxData = idlers.new()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.boxIndex = idler.new(1)
	self.currDay = idler.new(0)
	self.rechargeNum = idler.new(0) --已经充值  ***cn为充值金额 海外为钻石数***
	local progress = {15, 35, 55, 75, 100}
	self.barPoint = idler.new(0)
	idlereasy.when(self.yyhuodongs, function (_, yyhuodongs)
		local yydata = yyhuodongs[activityID] or {}
		local stamps = yydata.stamps or {}
		local rechargenum = yydata.info.rechargesum or 0
		self.rechargeNum:set(rechargenum / multiple)
		local datas = {}
		local num = 0
		local lastdaysum = yydata.info.lastdaysum or 0
		local daysum = yydata.info.daysum or 0
		-- if self.currDay:read() > 5 then self.currDay:set(5) end

		for k, v in orderCsvPairs(csv.yunying.rechargegift) do
			if v.huodongID == huodongID then
				local state = STATE_TYPE.noReach
				-- yydata.stamps[k] : 1:可领取，0：已领取，其他：不可领取
				if stamps[k] == 1 then
					state = STATE_TYPE.canReceive
				elseif stamps[k] == 0 then
					state = STATE_TYPE.received
				end
				self.money = v.amount / multiple --需要充值的总 ***cn为充值金额 海外为钻石数***
				if csvNext(v.special) then
					local id, num = csvNext(v.special)
					self.targetData = idlertable.new({key = id, num = num})
				end
				table.insert(datas, {csvId = k, cfg = v, state = state})
			end
		end
		table.sort(datas, function (data1, data2)
			return data1.cfg.daySum < data2.cfg.daySum
		end)
		local maxDaysum = #datas
		local curDays = lastdaysum ~= daysum and daysum or lastdaysum + 1
		self.currDay:set(math.min(curDays,maxDaysum))
		if daysum ~= lastdaysum then
			if datas[daysum].state == STATE_TYPE.noReach then
				self.barPoint:set(mathEasy.showProgress(progress, {1,2,3,4,5}, daysum - 1))
			else
				self.barPoint:set(mathEasy.showProgress(progress, {1,2,3,4,5}, daysum))
			end
		else
			self.barPoint:set(mathEasy.showProgress(progress, {1,2,3,4,5}, daysum))
		end
		self.boxData:update(datas)
		self.boxIndex:set(self.currDay:read(), true)
	end)
	self.boxIndex:addListener(function (val, oldval)
		self.boxData:atproxy(oldval).selected = false
		self.boxData:atproxy(val).selected = true
	end)

	idlereasy.any({self.currDay, self.boxIndex}, function (_, day, index)
		local itemData = {}
		local proxy = self.boxData:atproxy(index)
		for k, v in csvMapPairs(proxy.cfg.award) do
			if k == "cards" then
				for _, id in ipairs(v) do
					table.insert(itemData, {key = "card", num = id})
				end
			else
				table.insert(itemData, {key = k, num = v})
			end
		end
		self.list:setItemsMargin(#itemData == 3 and 50 or 20)
		if not self.datas then
			self.datas = idlers.newWithMap(itemData)
		else
			self.datas:update(itemData)
		end

		itertools.invoke({self.recieveBtn, self.rechargeBtn, self.recievedBtn}, "hide")
		if proxy.state == STATE_TYPE.canReceive then
			self.recieveBtn:show()
			text.addEffect(self.recieveBtn:get("label"),{glow = {color = ui.COLORS.GLOW.WHITE}})
		elseif proxy.state == STATE_TYPE.noReach then
			if index == day then
				self.rechargeBtn:show()
				text.addEffect(self.rechargeBtn:get("label"), {glow = {color = ui.COLORS.GLOW.WHITE}})
			else
				self.recievedBtn:show()
				self.recievedBtn:get("label"):text(gLanguageCsv.notOpen)
				text.addEffect(self.recievedBtn:get("label"),{color = cc.c4b(249,159,126,255), outline = {color = ui.COLORS.OUTLINE.WHITE, size = 8}})
			end
		else
			self.recievedBtn:show()
			self.recievedBtn:get("label"):text(gLanguageCsv.received)
			text.addEffect(self.recievedBtn:get("label"),{color = cc.c4b(249,159,126,255), outline = {color = ui.COLORS.OUTLINE.WHITE, size = 8}})
		end
	end)
	idlereasy.when(self.rechargeNum, function (_, val)
		if self.txtBg:get("txt") then
			self.txtBg:get("txt"):removeFromParent()
		end
		local richTxt = rich.createByStr(string.format(gLanguageCsv.activityRechargeGift, self.money - val >= 0 and self.money - val or 0), 40)
			:addTo(self.txtBg, 10, "txt")
			:alignCenter(self.txtBg:size())
	end)

	if matchLanguage({"cn"}) then
		self.rmb:texture(string.format("activity/recharge_gift/txt_%dy.png", self.money))
	else
		self.rmb:texture(string.format("activity/recharge_gift/txt_%d.png", self.money))
			:scale(1.6)
	end
	self.icon:texture(yyCfg.clientParam.hero):scale(2)
	ActivityView.setCountdown(self, activityID, self.timeLabel, self.time, {labelChangeCb = function()
		adapt.oneLinePos(self.timeLabel, self.time, cc.p(15, 0))
	end})
end

function ActivityRechargeGift:onBoxClick(list, index, data)
	self.boxIndex:set(index)
end

function ActivityRechargeGift:onRecieveClick()
	local boxIndex = self.boxIndex:read()
	local showOver = {false}
	gGameApp:requestServerCustom("/game/yy/award/get")
		:params(self.activityID, self.boxData:atproxy(self.boxIndex:read()).csvId)
		:onResponse(function (tb)
			local box = self.boxList:getChildren()[boxIndex]
			uiEasy.setBoxEffect(box, 1, function()
				showOver[1] = true
			end, 35, 5)
		end)
		:wait(showOver)
		:doit(function (tb)
			gGameUI:showGainDisplay(tb)
		end)
end

function ActivityRechargeGift:onRechargeClick()
	gGameUI:stackUI("city.recharge", nil, {full = true})
end

return ActivityRechargeGift
