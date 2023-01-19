local RechargeView = class("RechargeView", cc.load("mvc").ViewBase)

local function createPrivilegeLabel(desc, fontSize, width)
	local richText = rich.createWithWidth("#C0x5B545B#" .. desc, fontSize, nil, width)
		:align(cc.p(0, 0), 0, 0)
	local height = richText:size().height
	local item = ccui.Layout:create()
		:size(width, height)
		:add(richText)
	return item
end

local function isVipDistinguishedOpen(vipSum)
	-- 语言为其他语言时，若有礼包，则显示按钮
	local roleVip = gGameModel.monthly_record:read("vip")
	return matchLanguage({"cn"}) and vipSum >= gCommonConfigCsv.rechargeVip and dataEasy.isUnlock(gUnlockCsv.vipDistinguished)
			or (not matchLanguage({"cn"}) and (csvSize(gVipCsv[roleVip].monthGift) >= 1))
end

RechargeView.RESOURCE_FILENAME = "recharge.json"
RechargeView.RESOURCE_BINDING = {
	["topPanel.btn"] = {
		varname = "topPanelBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		},
	},
	["topPanel.btnVip"] = { 	-- 尊贵Vip弹窗
		varname = "btnVip",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onVipClick")}
			},
			{
				event = "visible",
				idler = bindHelper.self("vipSum"),
				method = function(vipSum)
					return isVipDistinguishedOpen(vipSum)
				end,
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "onHonourableVip",
					onNode = function(node)
						node:xy(170, 170)
					end,
				}
			},
		},
	},
	["topPanel.btn.label"] = {
		binds = {
			{
				event = "effect",
				data = {glow = {color = ui.COLORS.GLOW.WHITE}},
			},{
				event = "text",
				idler = bindHelper.self("selectRecharge"),
				method = function(val)
					if val then
						return gLanguageCsv.spacePrivilege
					end
					return gLanguageCsv.spaceRecharge
				end,
			},
		}
	},
	["topPanel.barBg"] = "barBg",
	["topPanel.bar"] = {
		varname = "topBar",
		binds = {
			event = "extend",
 			class = "loadingbar",
			props = {
				data = bindHelper.self("expProgress"),
				maskImg = "common/icon/mask_bar_red.png",
			},
		},
	},
	["topPanel.barNum"] = {
		varname = "barNum",
		binds = {
			event = "text",
			idler = bindHelper.self("expProgressNum")
		}
	},
	["topPanel.normalPanel"] = "topNormalPanel",
	["topPanel.maxPanel"] = "topMaxPanel",
	["rechargePanel"] = "rechargePanel",
	["rechargePanel.item"] = "rechargeItem",
	["rechargePanel.list"] = {
		varname = "rechargeList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rechargeDatas"),
				item = bindHelper.self("rechargeItem"),
				asyncPreload = 6,
				backupCached = false,
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.sortValue ~= b.sortValue then
						return a.sortValue > b.sortValue
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, csvId, v)
					local cfg = v.cfg
					node:get("icon"):texture(cfg.icon)
					node:get("price"):text(string.format(gLanguageCsv.symbolMoney, cfg.rmbDisplay))
					text.addEffect(node:get("price"), {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
					node:get("gain"):text(cfg.rmb)
					node:get("extraInfo"):text(string.format(gLanguageCsv.rechargeFirstExtra, cfg.firstPresent))
					node:get("extraInfo"):visible(v.rechargeBuyTimes == 0 and cfg.firstPresent ~= 0)
					node:get("doublePanel"):visible(v.rechargeBuyTimes == 0 and cfg.firstPresent ~= 0)
					bind.touch(list, node, {clicksafe = true, methods = {ended = functools.partial(list.clickCell, csvId, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onRechargeClick"),
			},
		},
	},
	["privilegePanel"] = "privilegePanel",
	["privilegePanel.bg"] = "privilegePanelBg",
	["privilegePanel.panel"] = "privilegeItem",
	["privilegePanel.pageView"] = {
		varname = "pageView",
		binds = {
			event = "extend",
			class = "pageview",
			props = {
				data = bindHelper.self("privilegeDatas"),
				item = bindHelper.self("privilegeItem"),
				onItem = function(list, node, k, v)
					idlereasy.if_(v.show, function ()
						local richTextList = node:get("list")
						local size = richTextList:size()
						richTextList:setScrollBarEnabled(false)
						richTextList:setItemsMargin(15)
						richTextList:removeAllChildren()
						for i = 1, math.huge do
							local desc = v.vipDescCfg["desc" .. i]
							if desc == nil or desc == "" then break end
							local item = createPrivilegeLabel(desc, 40, size.width)
							richTextList:pushBackCustomItem(item)
						end
						richTextList:adaptTouchEnabled()

						node:get("name"):text(string.format("V%d %s", k, gLanguageCsv.privilege))
						uiEasy.createItemsToList(list, node:get("propList"), v.vipCfg.gift, {scale = 1, margin = 0})

						node:get("oldPrice"):text(v.vipCfg.oldPrice)
						node:get("line"):size(100 + node:get("oldPrice"):size().width, node:get("line"):size().height)
						node:get("price"):text(v.vipCfg.newPrice)
						bind.touch(list, node:get("btn"), {methods = {ended = functools.partial(list.clickCell, k, v)}})

						idlereasy.any({v.hasBuy, v.vipLevelEnough, v.roleLevelEnough}, function(_, hasBuy, vipLevelEnough, roleLevelEnough)
							local btn = node:get("btn")
							local label = btn:get("label")
							cache.setShader(btn, false, "hsl_gray")
							text.deleteAllEffect(label)
							text.addEffect(label, {color = ui.COLORS.DISABLED.WHITE})
							if hasBuy then
								label:text(gLanguageCsv.hasBuy)
								btn:setTouchEnabled(false)
							else
								label:text(gLanguageCsv.spaceBuy)
								btn:setTouchEnabled(true)
								if vipLevelEnough and not roleLevelEnough then
									label:text(string.format(gLanguageCsv.lvnCanBuy, v.vipCfg.giftLevelLimit))
								elseif vipLevelEnough then
									cache.setShader(btn, false, "normal")
									text.addEffect(label, {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
								end
							end
						end):anonyOnly(list, k)
					end)
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onPrivilegeGiftBuy"),
				afterBuild = bindHelper.self("onPrivilegeAfterBuild"),
			},
		},
	},
	["privilegePanel.leftBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPrivilegeLeftBtnClick")}
		}
	},
	["privilegePanel.rightBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPrivilegeRightBtnClick")}
		}
	},
	["privilegePanel.mask"] = "mask",
}

-- params: {showPrivilege, privilegeIndex(int)}
function RechargeView:onCreate(params)
	self:enableSchedule()
	adapt.centerWithScreen("left", "right", nil, {
		{self.rechargeList, "width"},
		{self.rechargeList, "pos", "left"},
		{self.privilegePanelBg, "width"},
	})
	params = params or {}
	gGameModel.currday_dispatch:getIdlerOrigin("vipGift"):set(true)
	self:initModel()
	gGameUI.topuiManager:createView("recharge", self, {onClose = self:createHandler("onClose")})
		:init()

	self.pageView:setTouchEnabled(false)
	self.privilegePanel:get("panel.list"):setScrollBarEnabled(false)
	self.privilegePanel:get("panel.propList"):setScrollBarEnabled(false)
	self:setBarSize()

	-- 充值数据
	self.selectRecharge = idler.new(not (params.showPrivilege or params.privilegeIndex))
	local data = {}
	for k,v in orderCsvPairs(csv.recharges) do
		if matchLanguage(v.languages) and v.type == 1 then
			data[k] = {csvId = k, cfg = v, rechargeBuyTimes = 0}
		end
	end
	self.rechargeDatas = idlers.newWithMap(data)
	idlereasy.when(self.recharges, function(_, recharges)
		for csvId, data in self.rechargeDatas:pairs() do
			local v = data:proxy()
			v.rechargeBuyTimes = self:getRechargeBuyTimes(csvId)
			-- v.sortValue = v.cfg.sortValue + (v.rechargeBuyTimes == 0 and 100 or 0)
			v.sortValue = v.cfg.sortValue
		end
		if self.rechargeList.sortItems then
			self.rechargeList:sortItems()
		end
	end)

	-- 进度条
	self.expProgress = idler.new(0)
	self.expProgressNum = idler.new("")

	-- 初始特权页面数据, 无指定 privilegeIndex，则显示为进入时的vip对应特权
	if params.showPrivilege or params.privilegeIndex then
		local vipGift = self.vipGift:read()
		local vipLevel = self.vipLevel:read()
		local maxNoBuyGift = math.min(vipLevel + 1, game.VIP_LIMIT)
		for i = vipLevel, 1, -1 do
			if vipGift[i] ~= 0 then
				maxNoBuyGift = i
				break
			end
		end
		self.showPrivilegeIndex = maxNoBuyGift
	else
		self.showPrivilegeIndex = self.vipLevel:read()
	end
	self.showPrivilegeIndex = cc.clampf(self.showPrivilegeIndex, 1, game.VIP_LIMIT)
	self.privilegeIndex = idler.new(self.showPrivilegeIndex)
	local data = {}
	for i = 1, game.VIP_LIMIT do
		data[i] = {
			show = idler.new(i == self.showPrivilegeIndex),
			vipDescCfg = csv.vip_desc[i+1],
			vipCfg = gVipCsv[i],
			hasBuy = idler.new(false),
			vipLevelEnough = idler.new(false),
			roleLevelEnough = idler.new(false)
		}
	end
	self.privilegeDatas = data

	-- idler 监听触发
	idlereasy.any({self.vipLevel, self.vipSum}, function(_, vipLevel, vipSum)
		local curVip = math.min(vipLevel, game.VIP_LIMIT)
		local nextVip = curVip
		if curVip == game.VIP_LIMIT then
			self.topNormalPanel:hide()
			self.topMaxPanel:show()
			self.topMaxPanel:get("vipIcon"):texture(ui.VIP_ICON[curVip])
		else
			nextVip = curVip + 1
			self.topMaxPanel:hide()
			self.topNormalPanel:show()
			local childs = self.topNormalPanel:multiget("label1", "vipIcon1", "label2", "diamondIcon", "num", "label3", "vipIcon2")
			childs.num:text(gVipCsv[nextVip].upSum - vipSum)
			childs.vipIcon2:texture(ui.VIP_ICON[nextVip])
			if curVip < 1 then
				itertools.invoke({childs.label1, childs.vipIcon1}, "hide")
				childs.label2:x(childs.label1:x())
				adapt.oneLinePos(childs.label2, {childs.diamondIcon, childs.num, childs.label3, childs.vipIcon2}, cc.p(10, 0))
			else
				itertools.invoke({childs.label1, childs.vipIcon1}, "show")
				childs.vipIcon1:texture(ui.VIP_ICON[curVip])
				adapt.oneLinePos(childs.label1, {childs.vipIcon1, childs.label2, childs.diamondIcon, childs.num, childs.label3, childs.vipIcon2}, cc.p(10, 0))
			end
		end

		-- 第一次达到尊贵Vip要求，自动弹出尊贵Vip弹窗
		if isVipDistinguishedOpen(vipSum) and not userDefault.getForeverLocalKey("rechargeVip", false)
			and self:isShowVipGift() then
			self:onVipClick()
			userDefault.setForeverLocalKey("rechargeVip", true)
		end

		self:setBarSize()  --防止首次vip至尊时，服务器数据未及时同步
		self.expProgress:set(math.min(100 * vipSum / gVipCsv[nextVip].upSum, 100))
		self.expProgressNum:set(string.format("%d/%d", vipSum, gVipCsv[nextVip].upSum))
	end)
	idlereasy.when(self.vipLevel, function(_, vipLevel)
		for k, v in ipairs(self.privilegeDatas) do
			v.vipLevelEnough:set(vipLevel >= k)
		end
	end)
	idlereasy.when(self.roleLevel, function(_, roleLevel)
		for k, v in ipairs(self.privilegeDatas) do
			v.roleLevelEnough:set(roleLevel >= v.vipCfg.giftLevelLimit)
		end
	end)

	idlereasy.when(self.vipGift, function(_, vipGift)
		for i, v in pairs(vipGift) do
			local data = self.privilegeDatas[i]
			if data then data.hasBuy:set((v == 0) and true or false) end
		end
	end)
	idlereasy.when(self.selectRecharge, function(_, selectRecharge)
		if selectRecharge == true then
			gGameUI.topuiManager:updateTitle(gLanguageCsv.recharge, "RECHARGE")
			self.rechargePanel:show()
			self.privilegePanel:hide()
		else
			gGameUI.topuiManager:updateTitle(gLanguageCsv.privilege, "PRIVILEGE")
			self.rechargePanel:hide()
			self.privilegePanel:show()
		end
	end)
	idlereasy.when(self.privilegeIndex, function(_, privilegeIndex)
		privilegeIndex = cc.clampf(privilegeIndex, 1, game.VIP_LIMIT)
		self.privilegePanel:get("leftBtn"):visible(privilegeIndex > 1)
		self.privilegePanel:get("rightBtn"):visible(privilegeIndex < game.VIP_LIMIT)
		self:showPrivilegePage(privilegeIndex)
		self.pageView:setCurrentPageIndex(privilegeIndex - 1)
	end)

	self:initPrivilegeListener()

	widget.addAnimationByKey(self.btnVip, "effect/guizu.skel", "efc1", "effect_loop", 6)
		:alignCenter(self.btnVip:size())

	self.btnVip:setEnabled(self:isShowVipGift())
end

function RechargeView:initModel()
	self.recharges = gGameModel.role:getIdler("recharges")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.vipSum = gGameModel.role:getIdler("vip_sum")
	self.vipGift = gGameModel.role:getIdler("vip_gift")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.roleLevel = gGameModel.role:getIdler("level")
end

function RechargeView:initPrivilegeListener()
	uiEasy.addTouchOneByOne(self.mask, {ended = function(pos, dx, dy)
		if not self.selectRecharge:read() then
			if math.abs(dx) > 100 and math.abs(dx) > math.abs(dy) then
				local dir = dx > 0 and -1 or 1
				self.privilegeIndex:modify(function(val)
					val = cc.clampf(val + dir, 1, game.VIP_LIMIT)
					return true, val
				end)
			end
		end
	end})
end

function RechargeView:getRechargeBuyTimes(rechargeID)
	-- # 0 表示 没重置过，也没活动ID
	-- # >0 表示 新的重置活动ID
	-- # <0 表示 重置过的活动ID
	local recharge = self.recharges:read()[rechargeID]
	if recharge then
		local reset = recharge.reset or 0
		if reset > 0 then
			return 0
		end
		return recharge.cnt
	end
	return 0
end

function RechargeView:onPrivilegeAfterBuild(list)
	list:setCurrentPageIndex(self.showPrivilegeIndex - 1)
end

function RechargeView:onChangeClick()
	self.selectRecharge:modify(function(val)
		return true, not val
	end)
end

function RechargeView:onRechargeClick(list, rechargeId, v)
	gGameApp:payCustom(self)
		:params({rechargeId = rechargeId})
		:wait(5) -- 直充最多等待拦截5s
		:doit()
end

function RechargeView:onPrivilegeGiftBuy(list, k, v)
	local vipLevelEnough = v.vipLevelEnough:read()
	if not vipLevelEnough then
		gGameUI:showTip(gLanguageCsv.vipNotEnough)
	elseif not v.roleLevelEnough:read() then
		gGameUI:showTip(string.format(gLanguageCsv.lvnCanBuy, v.vipCfg.giftLevelLimit))
	else
		local function cb()
			local rmb = self.rmb:read()
			if rmb < v.vipCfg.newPrice then
				gGameUI:showTip(gLanguageCsv.noDiamondGoRecharge)
			else
				gGameApp:requestServer("/game/role/vipgift/buy", function(tb)
					gGameUI:showGainDisplay(tb)
				end, k)
			end
		end
		if matchLanguage({"kr"}) then
			dataEasy.sureUsingDiamonds(cb, v.vipCfg.newPrice, nil, string.format(gLanguageCsv.sureBuyVipGift, k))
		else
			gGameUI:showDialog({content = string.format(gLanguageCsv.sureBuyVipGift, k), cb = cb, btnType = 2, dialogParams = {clickClose = false}, clearFast = true})
		end
	end
end

function RechargeView:onPrivilegeLeftBtnClick()
	self.privilegeIndex:modify(function(val)
		return true, val - 1
	end)
end

function RechargeView:onPrivilegeRightBtnClick()
	self.privilegeIndex:modify(function(val)
		return true, val + 1
	end)
end

function RechargeView:showPrivilegePage(index)
	if index >= 1 and index <= game.VIP_LIMIT then
		local data = self.privilegeDatas[index]
		data.show:set(true)
		return true
	end
end

function RechargeView:isShowVipGift()
	local roleVip = gGameModel.monthly_record:read("vip")
	return  matchLanguage({"cn"}) or csvSize(gVipCsv[roleVip].monthGift) >= 1
end

function RechargeView:onVipClick()
	if matchLanguage({"cn"}) then
		gGameUI:stackUI("city.recharge_vip")
	else
		gGameUI:stackUI("city.vip_distinguished")
	end
end

-- @desc 设置bar的长度，主要是在有尊贵Vip按钮和没有的状态下长度不一样
function RechargeView:setBarSize()
	local distance = 62  -- 间距62像素
	local barBgScale = self.barBg:scale()
	local btnVipScale =  self.btnVip:scale()
	local barBgwidth = (self.topPanelBtn:x() - self.barBg:x() - self.topPanelBtn:width()/2 - distance)/barBgScale
	local vipSum = self.vipSum:read()
	if vipSum >= gCommonConfigCsv.rechargeVip and isVipDistinguishedOpen(vipSum) then
		barBgwidth = (barBgwidth*barBgScale - self.btnVip:width()*btnVipScale - distance)/barBgScale
	end
	local barPos = self.barBg:x() + barBgwidth*barBgScale/2
	self.barBg:width(barBgwidth)
	self.topBar:setContentSize(barBgwidth, self.topBar:height())
	self.topBar:x(barPos)
	self.barNum:x(barPos)
end

return RechargeView

