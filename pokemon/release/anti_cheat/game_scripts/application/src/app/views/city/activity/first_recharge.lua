-- @Date:   2019-05-30
-- @Desc:
-- @Last Modified time: 2019-06-12

local YY_TYPE = game.YYHUODONG_TYPE_ENUM_TABLE
local STATE_TYPE = {
	canReceive = 1,
	noReach = 0,
	received = 2,
}

local ActivityFirstRecharge = class("ActivityFirstRecharge", Dialog)
ActivityFirstRecharge.RESOURCE_FILENAME = "activity_first_recharge.json"
ActivityFirstRecharge.RESOURCE_BINDING = {
	["page1"] = "page1",
	["page2"] = "page2",
	["pageview"] = "pageview",
	["btnLeft"] = "btnLeft",
	["btnRight"] = "btnRight",
	["page1.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["page2.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["page1.buyBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuy")}
		},
	},
	["page2.buyBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBuy")}
		},
	},
	["dot0"] = "dot0",
	["dot1"] = "dot1",
	["btnLeft"] = {
		varname = "btnLeft",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onIndex")}
		},
	},
	["btnRight"] = {
		varname = "btnRight",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onIndex")}
		},
	},
	["page1.mask"] = "mask1",
	["page2.mask"] = "mask2"
}

function ActivityFirstRecharge:onCreate()
	gGameModel.currday_dispatch:getIdlerOrigin("firstRecharge"):set(true)
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

	local yyhuodongs = self.yyhuodongs:read()
	local activityIDs = {}
	for _, id in ipairs(gGameModel.role:read('yy_open')) do
		local huodong = yyhuodongs[id] or {}
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.independent == 1 and cfg.type == YY_TYPE.firstRecharge and huodong.flag ~= 2 then
			table.insert(activityIDs, {id = id, state = huodong.flag, sortWeight = cfg.sortWeight})
		end
	end
	table.sort(activityIDs, function(a, b)
		if a.sortWeight ~= b.sortWeight then
			return a.sortWeight < b.sortWeight
		end
		return a.id < b.id
	end)
	self.page1:retain()
	self.page1:removeFromParent()
	self.page2:retain()
	self.page2:removeFromParent()
	self.activityIDs = activityIDs
	self.isInserPage = false
	self.pages = {}
	self.listPos = {
		{x = self.page1:get("list"):x(), y = self.page1:get("list"):y()},
		{x = self.page2:get("list"):x(), y = self.page2:get("list"):y()}
	}
	self.states = {
		idler.new(STATE_TYPE.noReach),
		idler.new(STATE_TYPE.noReach)
	}
	local sizes = {
		[3] = cc.size(610, 215),
		[4] = cc.size(808, 215),
		[5] = cc.size(910, 195)
	}
	idlereasy.when(self.yyhuodongs, function (_, val)
		for i,v in ipairs(self.activityIDs) do
			local cfg = csv.yunying.yyhuodong[v.id]
			local page = self["page"..cfg.clientParam.page]
			if v.state ~= 2 then
				if not self.isInserPage then
					self.pageview:addPage(page)
					self.pages[i] = page
				end
				page:get("placard"):texture(cfg.clientParam.resBg)
				local list = page:get("list")
				local num = csvSize(cfg.paramMap.award)
				page:get("bg"):size(sizes[num])
				if num == 4 then
					list:x(self.listPos[cfg.clientParam.page].x)
				elseif num == 3 then
					list:x(self.listPos[cfg.clientParam.page].x + 100)
				elseif num == 5 then
					list:xy(self.listPos[cfg.clientParam.page].x - 50, self.listPos[cfg.clientParam.page].y - 12)
				end
				local btn = page:get("buyBtn")
				local label = btn:get("label")
				uiEasy.createItemsToList(self, list, cfg.paramMap.award, {scale = num == 5 and 0.9 or 1})
				if not val[v.id] then
					self.states[i]:set(STATE_TYPE.noReach)
					label:text(gLanguageCsv.goToRecharge)
					cache.setShader(btn, false, "normal")
					text.addEffect(label, {glow = {color = ui.COLORS.GLOW.WHITE}})
					btn:setTouchEnabled(true)
				elseif val[v.id].flag == 1 then
					self.states[i]:set(STATE_TYPE.canReceive)
					label:text(gLanguageCsv.spaceReceive)
					cache.setShader(btn, false, "normal")
					text.addEffect(label, {glow = {color = ui.COLORS.GLOW.WHITE}})
					btn:setTouchEnabled(true)
				elseif val[v.id].flag == 2 then
					self.states[i]:set(STATE_TYPE.received)
					label:text(gLanguageCsv.received)
					text.deleteAllEffect(label)
					cache.setShader(btn, false, "hsl_gray")
					btn:setTouchEnabled(false)
				end
				adapt.setTextScaleWithWidth(label, nil, btn:width() - 80)
				page:show()
			else
				page:hide()
			end
		end
		self.isInserPage = true
	end)
	self.curPage = idler.new(0)
	local container = self.pageview:getInnerContainer()
	local width = container:size().width
	local totalPage = #self.pageview:getPages()
	self.isEnter = false
	self.pageview:onScroll(function(event)
		local x = container:getPositionX()
		local xPos = {}
		itertools.invoke({self.mask1, self.mask2}, "show")
		if event.name == "AUTOSCROLL_ENDED" then
			for i=1,totalPage do
				local baseX = -width * (i-1)
				if math.abs(x - baseX) <= 5 then
					self.isEnter = true
					itertools.invoke({self.mask1, self.mask2}, "hide")
					if self.curPage:read() ~= self.pageview:getCurPageIndex() then
						self.curPage:set(self.pageview:getCurPageIndex())
					end
					return
				end
			end
		end
		if self.isEnter or event.name == "AUTOSCROLL_BEGAN" then
			self.isEnter = false
			itertools.invoke({self.mask1, self.mask2}, "hide")
		end
	end)
	self.curPage:addListener(function (val, oldval, _)
		if totalPage > 1 then
			local oldDot = self["dot"..oldval]
			local newDot = self["dot"..val]
			itertools.invoke({oldDot, oldval == val and self.dot1 or newDot}, "show")
			oldDot:texture("common/icon/logo_normal_fy.png")
			newDot:texture("common/icon/logo_highlight_fy.png")

		end
		self.btnRight:visible(val < totalPage - 1)
		self.btnLeft:visible(val > 0)
		self.pageview:scrollToPage(val)
	end)
	Dialog.onCreate(self, {blackType = 1})
end

function ActivityFirstRecharge:onIndex()
	self.curPage:set(self.curPage:read() == 0 and 1 or 0)
end

function ActivityFirstRecharge:onBuy()
	local index
	local id

	if itertools.size(self.pages) > 1 then
		index = self.pageview:getCurPageIndex() + 1
	else
		index = next(self.pages)
	end

	if self.states[index]:read() == STATE_TYPE.noReach then
		gGameUI:stackUI("city.recharge", nil, {full = true})

	elseif self.states[index]:read() == STATE_TYPE.canReceive then
		gGameApp:requestServer("/game/yy/award/get", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.activityIDs[index].id)
	end
end

return ActivityFirstRecharge