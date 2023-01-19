-- @Date:   2019-05-27
-- @Desc:
local ActivityView = require "app.views.city.activity.view"
local redHintHelper = require "app.easy.bind.helper.red_hint"
local PLACARD_FLAG = -1
-- 新增类似活动(只是替换资源),如果以后类似比较多可以弄成表
local activityTexture = {
	vacation = {
		iconBtn = "activity/server_open/summer_vacation/btn_sqqtl_2x2.png",
		iconTop = "activity/server_open/summer_vacation/banner_sqqtl_2.png",
		iconBg = "activity/server_open/summer_vacation/img_sqqtl_1.png",
		boxBg = "activity/server_open/summer_vacation/box_sqqtl_1.png",
		boxIcon = "activity/server_open/summer_vacation/icon_sqqtl_1.png",
		bg = "activity/server_open/summer_vacation/img_sqqtl_2.png",
		boxIconBg = "activity/server_open/summer_vacation/img_sqqtl_3.png",
		hintBg = "activity/server_open/summer_vacation/img_wenzidi.png"
	},
	national = {
		iconTop = "activity/server_open/national_mid_autumnl/banner_khsd_1.png",
		iconBg = "activity/server_open/national_mid_autumnl/img_khsd_1.png",
		boxBg = "activity/server_open/national_mid_autumnl/box_khsd_1.png",
		boxIcon = "activity/server_open/national_mid_autumnl/icon_khsd_1.png",
		boxIconBg = "activity/server_open/summer_vacation/img_sqqtl_3.png",
		hintBg = "activity/server_open/summer_vacation/img_wenzidi.png"
	},
}

local ServerOpenView = class("ServerOpenView", Dialog)
ServerOpenView.RESOURCE_FILENAME = "activity_server_open.json"
ServerOpenView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["itemDay"] = "dayItem",
	["topPanel"] = "topPanel",
	["topPanel.list"] = {
		varname = "topList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("dayData"),
				item = bindHelper.self("dayItem"),
				-- itemAction = {isAction = true},
				onItem = function(list, node, index, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel, txt
					if v.selected then
						normal:hide()
						panel = selected:show()
						txt = panel:get("txt")
						text.addEffect(txt, {color = v.isLock == true and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.WHITE})

						for i,data in pairs(activityTexture) do
							if v.clientType == i then
								selected:loadTextureNormal(data.iconBtn)
							end
						end
					else
						selected:hide()
						panel = normal:show()
						txt = panel:get("txt")
						text.addEffect(txt, {color = v.isLock == true and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED})
					end
					node:get("lock"):visible(v.isLock == true)
					panel:setOpacity(v.isLock == true and 150 or 255)
					txt:text(v.cfg.themeName)
					if not v.isLock then
						list.state = v.selected ~= true
						local props = {
							class = "red_hint",
							props = {
								specialTag = "serverOpenDay",
								state = bindHelper.self("state"),
								listenData = {
									originData = bindHelper.parent("originData"),
									id = bindHelper.parent("id"),
								},
								func = function (t)
									if t.originData and t.id then
										return redHintHelper.serverOpenDay(t, index)
									end
									return false
								end,
							}
						}
						bind.extend(list, node, props)
					end

					bind.click(list, panel, {method = functools.partial(list.clickCell, index, v)})
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				clickCell = bindHelper.self("onDayClick"),
			},
		},
	},
	["topPanel.time"] = {
		varname = "time",
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(255,238,204,255)}, color = cc.c4b(107,179,114,255)}
			},
		}
	},
	["topPanel.txt"] = {
		varname = "timeLabel",
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(255,238,204,255)}, color = cc.c4b(166,141,116,255)}
			},
		}
	},
	["item"] = "item",
	["leftPanel"] = "leftPanel",
	["leftPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabData"),
				item = bindHelper.self("item"),
				margin = -10,
				itemAction = {isAction = true},
				onItem = function(list, node, index, v)
					local childs = node:multiget("selected", "name")
					childs.selected:visible(v.selected == true)
					childs.name:text(v[1].cfg.tabName)
					if v.selected then
						text.addEffect(childs.name, {color = ui.COLORS.NORMAL.WHITE})
					else
						text.addEffect(childs.name, {color = ui.COLORS.NORMAL.DEFAULT})
					end
					adapt.setTextScaleWithWidth(childs.name, nil, 340)
					list.state = v.selected ~= true
					local props = {
						class = "red_hint",
						props = {
							specialTag = "serverOpenCurrDay",
							state = bindHelper.self("state"),
							listenData = {
								originData = bindHelper.parent("originData"),
								day = bindHelper.parent("showTab"),
								id = bindHelper.parent("id"),
								index = index,
							},
						}
					}
					bind.extend(list, node, props)
					bind.click(list, node, {method = functools.partial(list.clickCell, index, v)})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["leftPanel.icon"] = "leftPanelIcon",
	["leftPanel.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowPlacard")}
		}
	},
	["box"] = "box",
	["title"] = "title",
}

function ServerOpenView:onCreate(activityId)
	self.clientType = csv.yunying.yyhuodong[activityId].clientParam.type
	for i,v in pairs(activityTexture) do
		if self.clientType == i then
			self.topPanel:get("imgLeft"):texture(v.iconTop)
			self.topPanel:get("imgLeft"):y(self.topPanel:get("imgLeft"):y() + 15)
			self.box:texture(v.boxBg)
			self.title:texture(v.iconBg)
			local parent = self:getResourceNode()
			if v.bg then
				local spr = CSprite.new(v.bg)
				for i=1, 4 do
					parent:get("bg" .. i):hide()
				end
				spr:addTo(parent, 0)
				spr:scale(2)
				spr:setAnchorPoint(cc.p(0.5,0.5))
				spr:alignCenter(parent:size())
			end
			self.leftPanelIcon:texture(v.boxIcon)
			local boxBg = CSprite.new(v.boxIconBg)
			boxBg:addTo(self.leftPanel, 0)
			boxBg:setAnchorPoint(cc.p(0.5,0.5))
			boxBg:xy(self.leftPanelIcon:x(), self.leftPanelIcon:y())
			self.leftPanelIcon:y(self.leftPanelIcon:y() + 20)
			local hintBg = CSprite.new(v.hintBg)
			hintBg:addTo(self.leftPanel, 1)
			hintBg:xy(self.leftPanelIcon:x(), self.leftPanelIcon:y() - self.leftPanelIcon:width()/2 - 40)

			local btnContent1 = cc.Label:createWithTTF(gLanguageCsv.allTargetAward, "font/youmi1.ttf", matchLanguage({"kr"}) and 30 or 26)
			btnContent1:addTo(hintBg, 1)
			btnContent1:setAnchorPoint(cc.p(0.5,0.5))

			local btnContent2 = cc.Label:createWithTTF(gLanguageCsv.summerGift, ui.FONT_PATH, matchLanguage({"kr","en"}) and 30 or 40)
			btnContent2:addTo(hintBg, 1)
			btnContent2:setAnchorPoint(cc.p(0.5,0.5))

			if self.clientType == "national" then
				self.topPanel:get("imgLeft"):xy(self.topPanel:get("imgLeft"):x() + 2, self.topPanel:get("imgLeft"):y() + 8)
				self.title:scale(1)
				self.title:xy(self.title:x() - 45, self.title:y() + 10)
				btnContent1:text(gLanguageCsv.exclusiveReward)
				btnContent2:text(gLanguageCsv.carnivalGift)
				btnContent1:setPosition(-hintBg:width()/2 - 80, hintBg:y() - 35)
				adapt.oneLinePos(btnContent1, btnContent2, cc.p(2, 7))
			else
				self.title:scale(2)
				self.title:xy(self.title:x() + 20, self.title:y() - 17)
				btnContent1:setPosition(-hintBg:width()/2 - 80, hintBg:y() - 45)
				adapt.oneLinePos(btnContent1, btnContent2, cc.p(2, 7))
			end
			text.addEffect(btnContent2, {color = cc.c3b(255, 230, 65), outline = {color = cc.c3b(236, 82, 113)}})
		end
	end

	self.dayItem:hide()
	self.id = idler.new(activityId)
	self.serverOpenItemBuy = gGameModel.currday_dispatch:getIdlerOrigin("serverOpenItemBuy")
	ActivityView.setCountdown(self, activityId, self.timeLabel, self.time, {labelChangeCb = function()
		adapt.oneLinePos(self.timeLabel, self.time, cc.p(15, 0))
	end, tag = 2})
	local itemBuy = game.TARGET_TYPE.ItemBuy
	local cfg = csv.yunying.yyhuodong[activityId]
	local t = {}
	local dayData = {}
	for i, v in orderCsvPairs(csv.yunying.serveropen) do
		if v.huodongID  == cfg.huodongID then
			t[v.themeType] = t[v.themeType] or {}
			dayData[v.themeType] = {cfg = v, clientType = self.clientType}
			t[v.themeType][v.tabIndex] = t[v.themeType][v.tabIndex] or {}
			table.insert(t[v.themeType][v.tabIndex], {id = i, cfg = v})
		end
	end
	self.data = t
	self.originData = idlertable.new(t)
	local date, startTime = time.getActivityOpenDate(activityId)
	local countdown = time.getTime() - startTime
	local day = tonumber(math.max(time.getCutDown(countdown).day, 0))
	self.currDay = idler.new(day)
	local maxIndex = itertools.size(dayData) - 1
	day = day > maxIndex and maxIndex or day
	self.showTab = idler.new(day)
	for i = 0, day do
		dayData[i].isLock = false
	end
	for i = day + 1, maxIndex do
		dayData[i].isLock = true
	end
	self.dayData = idlers.newWithMap(dayData)
	self.tabIndex = idler.new(0)
	self.showTab:addListener(function(val, oldval)
		self.dayData:atproxy(oldval).selected = false
		self.dayData:atproxy(val).selected = true
		local data = clone(t[val])
		local currIndex = self.tabIndex:read()
		if currIndex == -1 then
			for i,v in pairs(data) do
				v.selected = false
			end
		else
			for i,v in pairs(data) do
				v.selected = currIndex == i
			end
		end
		if not self.tabData then
			self.tabData = idlers.newWithMap(data)
		else
			self.tabData:update(data)
		end

		-- 限时折扣点开后，不再显示红点
		if data[currIndex] then -- 当选中常驻奖励时，currIndex为-1，不选中任何tab，data中也不会有对应数据
			if data[currIndex][1].cfg.taskType == itemBuy then
				local id = data[currIndex][1].id
				self.serverOpenItemBuy:modify(function(serverOpenItemBuy)
					serverOpenItemBuy[id] = true
				end, true)
			end
		end
	end)
	self.subViews = {}
	local otherView = 0
	local viewConfig = {
		[PLACARD_FLAG] = {
			viewName = "city.activity.server_open.placard",
		},
		[itemBuy] = {
			viewName = "city.activity.server_open.discount",
		},
		[otherView] = {
			viewName = "city.activity.server_open.get",
		},
	}
	self.tabIndex:addListener(function(val, oldval)
		if oldval ~= PLACARD_FLAG then
			if self.tabData:at(oldval) then
				self.tabData:atproxy(oldval).selected = false
			end
		end
		for _, v in pairs(self.subViews) do
			v:hide()
		end

		local viewFlag = PLACARD_FLAG
		if val ~= PLACARD_FLAG then
			local isDiscount = self.tabData:atproxy(val)[1].cfg.taskType == itemBuy
			self.tabData:atproxy(val).selected = true
			if isDiscount then
				viewFlag = itemBuy
				-- 限时折扣点开后，不再显示红点
				local id = self.tabData:atproxy(val)[1].id
				self.serverOpenItemBuy:modify(function(serverOpenItemBuy)
					serverOpenItemBuy[id] = true
				end, true)
			else
				viewFlag = otherView
			end
		end
		if not self.subViews[viewFlag] then
			self.subViews[viewFlag] = gGameUI:createView(viewConfig[viewFlag].viewName, self:getResourceNode())
				:init(activityId, t, self:createHandler("sendParams"))
				:x(display.uiOrigin.x)
		else
			self.subViews[viewFlag]:show()
		end
	end)

	self:countDown(startTime)

	--鼠年嘉年华特殊处理 TODO 特殊在继承view里处理
	if self.clientType == "springFestival" then
		viewConfig[PLACARD_FLAG].viewName = "city.activity.server_open.placard_spring_festival"
		text.addEffect(self.timeLabel, {outline={color=ui.COLORS.WHITE, size = 3}, color = ui.COLORS.NORMAL.RED})
		text.addEffect(self.time, {outline={color=ui.COLORS.NORMAL.RED}, color = ui.COLORS.WHITE})
	end
	--五一嘉年华特殊处理
	--暑假七天乐(vacation),只是在五一嘉年华上更改资源，内容不变
	if self.clientType == "mayDay" or self.clientType == "vacation" then
		viewConfig[PLACARD_FLAG].viewName = "city.activity.server_open.placard_may_day"
		local labColor = ui.COLORS.NORMAL.RED
		if self.clientType == "vacation" then
			labColor = cc.c3b(0, 151, 242)
		end
		text.addEffect(self.timeLabel, {outline={color=ui.COLORS.WHITE, size = 3}, color = labColor})
		text.addEffect(self.time, {outline={color = labColor}, color = ui.COLORS.WHITE})
	end

	if self.clientType == "national" then
		viewConfig[PLACARD_FLAG].viewName = "city.activity.server_open.placard_national_mid_autumn"
		text.addEffect(self.timeLabel, {outline = {color = ui.COLORS.WHITE, size = 5}, color = cc.c3b(208, 98, 15)})
		text.addEffect(self.time, {outline = {color = cc.c3b(241, 187, 70)}, color = ui.COLORS.WHITE})
	end

	if self.clientType == "doubleYearsDay" then
		viewConfig[PLACARD_FLAG].viewName = "city.activity.server_open.placard_double_years_day"
		text.addEffect(self.timeLabel, {outline = {color = ui.COLORS.WHITE, size = 4}, color = cc.c3b(59, 183, 132)})
		text.addEffect(self.time, {outline = {color = cc.c3b(59, 183, 132)}, color = ui.COLORS.WHITE})
		text.addEffect(self.leftPanel:get("iconBg.text2"), {outline = {color = cc.c3b(236, 82, 113), size = 4}})
	end

	if self.clientType == "anniversary" then
		viewConfig[PLACARD_FLAG].viewName = "city.activity.server_open.placard_anniversary"
		text.addEffect(self.timeLabel, {outline = {color = cc.c3b(199, 40, 19), size = 4}, color = cc.c3b(245, 239, 217)})
		text.addEffect(self.time, {outline = {color = cc.c3b(77, 94, 67), size = 4}, color = cc.c3b(165, 247, 57)})
		text.addEffect(self.leftPanel:get("iconBg.text2"), {outline = {color = cc.c3b(236, 82, 113), size = 4}})
	end

	Dialog.onCreate(self, {blackType = 1})

end

function ServerOpenView:sendParams()
	return self.currDay, self.showTab, self.tabIndex
end

function ServerOpenView:onTabClick(list, index, data)
	self.tabIndex:set(index, true)
end

function ServerOpenView:onDayClick(list, index, data)
	local tabIndex = self.tabIndex:read()
	if not self.data[index][tabIndex] then
		self.tabIndex:set(0, true)
	end
	self.showTab:set(index, true)
end

function ServerOpenView:onShowPlacard()
	self.tabIndex:set(PLACARD_FLAG, true)
end

function ServerOpenView:countDown(startTime)
	self:unSchedule(1)
	local countdown = time.getTime() - startTime
	self:schedule(function()
		countdown = countdown - 1
		if countdown <= 0 then
			return false
		else
			local day = tonumber(time.getCutDown(countdown).day)
			self.currDay:set(day)
			day = day > self.dayData:size() - 1 and self.dayData:size() - 1 or day
			for i = 0, day do
				if self.dayData:atproxy(i).isLock ~= false then
					self.dayData:atproxy(i).isLock = false
				end
			end
		end
	end, 1, 1, 1)
end

function ServerOpenView:onAfterBuild()
	self.topList:jumpToItem(self.showTab:read(), cc.p(1, 0), cc.p(1, 0))
end

return ServerOpenView