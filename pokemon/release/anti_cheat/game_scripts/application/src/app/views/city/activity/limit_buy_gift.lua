-- @desc: 	activity-限时直购礼包

local GIFTSTATE = {
	CANBUY = 1,
	BOUGHT = 2, -- 已购买
	TIMEOUT = 3, -- 已过期
}

local ActivityView = require "app.views.city.activity.view"
local ActivityLimitBuyGiftView = class("ActivityLimitBuyGiftView", Dialog)

ActivityLimitBuyGiftView.RESOURCE_FILENAME = "activity_limit_buy_gift.json"
ActivityLimitBuyGiftView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["leftPanel.item"] = "item",
	["leftPanel.list"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local btn = node:get("btn")
					btn:get("selected"):visible(v.select)
					btn:get("normal"):visible(not v.select)
					btn:get("name"):text(v.cfg.name)
					ActivityLimitBuyGiftView.setCountdown(list, btn:get("countTime"), {info = v, tag = v.csvId, cb = function ()
						if v.state ~= GIFTSTATE.BOUGHT then
							v.state = GIFTSTATE.TIMEOUT  -- 倒计时结束状态改为已过期
						end
					end})
					btn:setTouchEnabled(not v.select)
					bind.touch(list, btn, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
				asyncPreload = 8,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["rightPanel"] = "rightPanel",
	["rightPanel.list"] = "rewardList",
	["rightPanel.listBg"] = "rewardListBg",
	["rightPanel.bg"] = "rightBg",
	["rightPanel.countPanel"] = "countPanel",
	["rightPanel.countPanel.countTimeBg"] = "countTimeBg",
	["rightPanel.countPanel.countTimeNode"] = "countTimeNode",
	["rightPanel.countPanel.countTime"] = "countTime",
	["rightPanel.lv"] = "lv",
	["rightPanel.btnBuy"] ={
		varname = "btnBuy",
		binds = {
			event = "touch",
			clicksafe = true,
			methods = {ended = bindHelper.self("onBtnBuy")}
		},
	},
	 ["rightPanel.btnBuy.price"] = "price",
}

function ActivityLimitBuyGiftView:onCreate()
	self:enableSchedule()
	self:initModel()
	local datas = {}
	self.datas = datas
	for _, yyId in ipairs(gGameModel.role:read('yy_open')) do
		local cfg = csv.yunying.yyhuodong[yyId]
		if cfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.limitBuyGift then
			for k,v in orderCsvPairs(csv.yunying.limitbuygift) do
				if v.huodongID == cfg.huodongID then
					if datas[k] then
						printWarn("yyId(%s) yunying.limitbuygift k(%d) is already in yyId(%s)", yyId, k, datas[k].yyId)
					else
						datas[k] = {cfg = v, csvId = k, yyId = yyId}
					end
				end
			end
		end
	end

	self.tabDatas = idlers.newWithMap({})
	self.clientBuyTimes = idler.new(true)
	self.showTab = idler.new(1)             -- 初始停留在第一页
	local datat = table.deepcopy(self.yyhuodongs:read(), true)
	idlereasy.any({self.yyhuodongs, self.clientBuyTimes}, function (_, yyhuodongs)
		yyhuodongs = datat
		self:unSchedule(9999999)
		local tabDatas = {}
		for k,v in pairs(datas) do
			local yyhuodong = yyhuodongs[v.yyId]
			local leftTimes = yyhuodong.stamps[v.csvId] or 1
			local buyTimes = 1 - leftTimes
			buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", v.yyId, v.csvId, buyTimes)
			-- state标志, 详见GIFTSTATE, 初始化为空，只要在停留在界面时，状态由可购买变为已购买/已过期时，state才会赋值
			if v.state then -- state有值，表示为停在在此界面时，状态变为已购买/已过期，不显示倒计时，但仍要显示相关信息
				v.startTime = yyhuodong.valinfo[v.csvId].time
				if buyTimes > 0 then
					v.state = GIFTSTATE.BOUGHT
				end
				table.insert(tabDatas, v)
			else
				-- 第一层判断时间
				if yyhuodong.valinfo[v.csvId] and time.getTime() - yyhuodong.valinfo[v.csvId].time < v.cfg.duration*60 then
					-- 第二层，是否已购买
					if buyTimes == 0 then
						v.state = GIFTSTATE.CANBUY
						v.startTime = yyhuodong.valinfo[v.csvId].time
						table.insert(tabDatas, v)
					end
				end
			end

		end
		table.sort(tabDatas, function (a, b)  -- 为什么不在list中排序，因为list排序后，顺序改变，但序号没变，导致序号1的tab并没有加载在第一个
			if a.cfg.sort == b.cfg.sort then
				return a.csvId < b.csvId
			end
			return a.cfg.sort < b.cfg.sort
		end)
		self.tabDatas:update(tabDatas)
		self.showTab:notify()
	end)

	local posX, posY = self.rewardList:xy()
	-- 左侧切换页签
	self.showTab:addListener(function(val, oldval)       -- 监听Tab页变换
		if self.tabDatas:size() <= 0 then
			self.rightPanel:hide()
			return
		end
		self.tabDatas:atproxy(oldval).select = false     -- tab选中状态
		self.tabDatas:atproxy(val).select = true

		if self.tabDatas:atproxy(val) then
			self.currentInfo = self.tabDatas:atproxy(val)  -- 当前选中礼包信息
		end
		local margin = 11
		uiEasy.createItemsToList(self, self.rewardList, self.currentInfo.cfg.item, {margin = margin, onAfterBuild = function()
			self.rewardList:setItemAlignCenter()
		end, onNode = function (panel)
			-- list背景图片大小设置
			local size =  itertools.size(self.currentInfo.cfg.item)
			local width = margin*(size+1) + panel:width()*size
			local height = self.rewardListBg:height()
			self.rewardListBg:size(width, height)
		end})
		self.rightBg:texture(self.currentInfo.cfg.bgPath)
		self.countTimeBg:texture(self.currentInfo.cfg.countPath)
		self.countPanel:visible(self.currentInfo.state ~=  GIFTSTATE.BOUGHT)
		self:setCountdown(self.countTime, {info = self.currentInfo, tag = 9999999})
		if self.currentInfo.cfg.targetType1 == 1 then   -- 1 代表等级礼包
			self.lv:show()
			self.lv:text(self.currentInfo.cfg.targetArg1_1)
		else
			self.lv:hide()
		end

		self.btnBuy:setTouchEnabled(self.currentInfo.state ~= GIFTSTATE.BOUGHT)
		self.btnBuy:get("bgMask"):visible(self.currentInfo.state == GIFTSTATE.BOUGHT)
		self.btnBuy:get("imgTips"):texture(self.currentInfo.state == GIFTSTATE.BOUGHT and "activity/limit_buy_gift/txt_ysq.png" or "activity/limit_buy_gift/txt_ljqg.png")
		local rechargesCfg = csv.recharges
		for id,recharges in orderCsvPairs(rechargesCfg) do
			if id == self.currentInfo.cfg.rechargeID then
				self.price:text(string.format(gLanguageCsv.symbolMoney, recharges.rmbDisplay))
				break
			end
		end
	end)

	Dialog.onCreate(self, {blackType = 1})
end

function ActivityLimitBuyGiftView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
end

function ActivityLimitBuyGiftView:onTabClick( list, tab )
	self.showTab:set(tab)
end

-- @desc 检查是否出于激活时间内
function ActivityLimitBuyGiftView:checkCountTime( startTime, durationTime )
	local currentTime = time.getTime()
	-- 尚未激活
	if not startTime then
		return false
	end
	-- 激活时间未到
	if startTime > currentTime then
		return false
	end
	local count = durationTime*60 + startTime - currentTime
	if count <= 0 then
		return false
	end
	return count
end

-- @ 购买礼包
function ActivityLimitBuyGiftView:onBtnBuy()
	if self.currentInfo.state == GIFTSTATE.BOUGHT then
		-- 分两种 已购买，或者过期
	elseif self.currentInfo.state == GIFTSTATE.TIMEOUT then
		gGameUI:showTip(gLanguageCsv.giftOutOfDate)
	else
		gGameApp:payDirect(self, {rechargeId = self.currentInfo.cfg.rechargeID, yyID = self.currentInfo.yyId, csvID = self.currentInfo.csvId, name = self.currentInfo.cfg.name, buyTimes = 0}, self.clientBuyTimes)
			:serverCb(function()
				local cfg = self.datas[self.currentInfo.csvId].cfg
				gGameUI:showGainDisplay(cfg.item, {raw = false})
			end)
			:doit(function()
				-- 相关状态改变
				self.datas[self.currentInfo.csvId].state = GIFTSTATE.BOUGHT
				self.currentInfo.state = GIFTSTATE.BOUGHT
				self:unSchedule(9999999)
				self.countTime:text(gLanguageCsv.sellout)
				self.countPanel:hide()
				self.btnBuy:setTouchEnabled(false)
				self.btnBuy:get("bgMask"):show()
				self.btnBuy:get("imgTips"):texture("activity/limit_buy_gift/txt_ysq.png")
			end)
	end
end

-- 第一次加载再list加载完成后，再对右侧主界面定时器设定，保持同步
function ActivityLimitBuyGiftView:onAfterBuild()
	if self.tabDatas:size() <= 0 then
		return
	end
	self:setCountdown(self.countTime, {info = self.currentInfo, tag = 9999999})
end

-- @desc 设置倒计时
-- @params{info 倒计时信息, tag 定时器标签，cb 回调方法}
function ActivityLimitBuyGiftView.setCountdown(view, uiTime, params)
	view:enableSchedule()
	local countTime = ActivityLimitBuyGiftView:checkCountTime(params.info.startTime, params.info.cfg.duration)
	view:unSchedule(params.tag)
	if not countTime or params.info.state ~= GIFTSTATE.CANBUY then
		uiTime:text(time.getCutDown(0).str)
		if params.info.state == GIFTSTATE.BOUGHT then
			uiTime:text(gLanguageCsv.sellout)
		end
		if params.cb then
			params.cb()
		end
		return
	end
	view:schedule(function()
		countTime = params.info.cfg.duration*60 + params.info.startTime - time.getTime()
		uiTime:text(time.getCutDown(countTime).str)
		if countTime <= 0 then
			ActivityLimitBuyGiftView.setCountdown(view, uiTime, params)
		end
	end, 1, 0, params.tag)
end

return ActivityLimitBuyGiftView
