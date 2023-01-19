-- @desc: 	activity-限时通行证

local ICONTIME = 5		-- 奖励展示icon自动切换时间,单位s
local TABTYPE = {		-- 左侧切换页签类型 1、奖励页 2、任务页
	REWARD = 1,
	TASK = 2,
	SHOP = 3,
}

local TAB_Panel = { 	-- panel类型 1、奖励panel 2、任务panel
	"rewardPanel",
	"taskPanel",
	"shopPanel"
}

local TASK_ICON = {		-- 每日/每周任务参数 1、每日任务 2、每周任务
	{name = gLanguageCsv.everyday, bgPath = "activity/passport/task/bg_day.png", cornerPath = "activity/passport/task/lab_day.png"},
	{name = gLanguageCsv.everyweek, bgPath = "activity/passport/task/bg_week.png", cornerpath = "activity/passport/task/lab_week.png"},
	{name = gLanguageCsv.everydayVip, bgPath = "activity/passport/task/panle_day.png", cornerpath = "activity/passport/task/logo_day.png"},
	{name = gLanguageCsv.everyweekVip, bgPath = "activity/passport/task/panle_week.png", cornerpath = "activity/passport/task/logo_week.png"},
}

local function setBtnState(btn, state)
	btn:setTouchEnabled(state)
	cache.setShader(btn, false, state and "normal" or "hsl_gray")
	if state then
		text.addEffect(btn:get("txtNode"), {glow={color=ui.COLORS.GLOW.WHITE}})
	else
		text.deleteAllEffect(btn:get("txtNode"))
		text.addEffect(btn:get("txtNode"), {color = ui.COLORS.DISABLED.WHITE})
	end
end

local ViewBase = cc.load("mvc").ViewBase
local ActivityPassportView = class("ActivityPassportView", ViewBase)

ActivityPassportView.RESOURCE_FILENAME = "activity_passport.json"
ActivityPassportView.RESOURCE_BINDING = {
	["tabItem"] = "tabItem",
	["tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				activityId = bindHelper.self("activityId"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					-- panel:get("txtNode"):text(v.name)
					local maxHeight = panel:getSize().height
					adapt.setAutoText(panel:get("txtNode"),v.name, maxHeight)
					local specialTag
					if k == TABTYPE.REWARD then
						specialTag = "passportReward"
					elseif k == TABTYPE.TASK then
						specialTag = "passportTask"
					end
					bind.extend(list, panel, {
						class = "red_hint",
						props = {
							state = v.select ~= true and v.red,
							specialTag = specialTag,
							listenData = {
								activityId = list.activityId,
							},
						},
					})
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["rewardPanel"] = "rewardPanel",
	["rewardPanel.lv"] = {
		varname = "rewardLv",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(123, 115, 118, 255),  size = 2}}
		}
	},
	["rewardPanel.icon"] = "rewardIcon",
	["rewardPanel.endTime"] = "rewardEndTime",
	["rewardPanel.textNode2"] = "txtNode2",
	["rewardPanel.name"] = {
		varname = "rewardName",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE,  size = 6}}
		}
	},
	["rewardPanel.exp"] = "rewardExp",
	["rewardPanel.expBar"] = "rewardExpBar",
	["rewardPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRule")}
		}
	},
	["rewardPanel.btnRule.txtNode"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT,  size = 2}} 	--
		}
	},
	["rewardPanel.target"] = "target",
	["rewardPanel.target.normalPanel"] = "targetNormalPanel",
	["rewardPanel.target.highPanel1"] = "targetHighPanel1",
	["rewardPanel.target.highPanel2"] = "targetHighPanel2",
	["rewardPanel.target.noClick"] = "targetNoClick",  -- 禁止点击层，当rewardScroll滑动时，禁止点击
	["rewardPanel.btnBuy"] = {
		varname = "btnBuy",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBuy")}
		}
	},
	["rewardPanel.btnBuyExp"] = {
		varname = "btnBuyExp",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBuyExp")}
		}
	},
	["rewardPanel.btnOneKeyGet"] = {
		varname = "btnOneKeyGet",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnOneKeyGet")}
		}
	},
	["iconItem"] = "iconItem",
	["rewardPanel.iconList"] = {
		varname = "iconList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("iconDatas"),
				item = bindHelper.self("iconItem"),
				onItem = function(list, node, k, v)
					local icon = node:get("icon")
					icon:texture(v)
				end,
			},
		},
	},
	["rewardPanel.iconPointPanel"] = "iconPointPanel",
	["pointItem"] = "pointItem",
	["rewardItem"] = "rewardItem",
	["rewardPanel.scroll"] = "rewardScroll",
	["rewardPanel.imgLvMax"] = "imgLvMax",
	["rewardPanel.highMask"] = "highMask",
	["rewardPanel.highLock"] = "highLock",
	["rewardPanel.txtHigh"] = "rewardTxtHigh",
	["rewardPanel.txtNormal"] = "rewardTxtNormal",
	["taskPanel"] = "taskPanel",
	["taskPanel.txtNote"] = "taskNote",
	["taskPanel.txtNote1"] = "taskNote1",
	["taskPanel.btnAllGet"] = {
		varname = "getBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				return view:onAllGetBtn()
			end)}
		},
	},
	["taskItem"] = "taskItem",
	["taskPanel.list"] = {
		varname = "taskList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("taskDatas"),
				dataOrderCmp = function (a, b)    -- 排序 可领取>未完成>已领取   每日>每周
					if a.sort ~= b.sort then
						return a.sort < b.sort
					elseif a.cfg.periodType ~= b.cfg.periodType then
						return a.cfg.periodType < b.cfg.periodType
					else
						return a.cfg.taskAttribute < b.cfg.taskAttribute
					end
				end,
				item = bindHelper.self("taskItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg", "cornerIcon", "cornerIcon1", "txtCorner", "txtCorner1", "txtTitle", "txtContent", "txtExp", "txtProgress", "btnGet", "btnGo", "imgGot")
					if v.buyHigh or v.cfg.taskAttribute == 3 then

						node:height(238)
						if v.cfg.taskAttribute == 3 then
							childs.cornerIcon1:hide()
							childs.txtCorner1:hide()
							childs.bg:texture(TASK_ICON[v.cfg.periodType].bgPath)
							childs.cornerIcon:texture(TASK_ICON[v.cfg.periodType].cornerPath)
							childs.txtCorner:text(TASK_ICON[v.cfg.periodType].name)
						else
							childs.cornerIcon:hide()
							childs.txtCorner:hide()
							childs.bg:texture(TASK_ICON[v.cfg.periodType + 2].bgPath)
							childs.cornerIcon1:texture(TASK_ICON[v.cfg.periodType + 2].cornerPath)
							childs.txtCorner1:text(TASK_ICON[v.cfg.periodType + 2].name)
						end
						adapt.setTextScaleWithWidth(childs.txtCorner, nil, 95)
						childs.txtTitle:text(v.cfg.title)
						childs.txtContent:text(v.cfg.desc)
						childs.txtExp:text(gLanguageCsv.passportExp.."+"..v.cfg.exp)
						text.addEffect(childs.txtExp, {outline={color=ui.COLORS.OUTLINE.WHITE}})
						childs.txtProgress:text(v.progress.."/"..v.cfg.taskParam)
							:visible(v.state == 0)
						childs.imgGot:visible(v.state == 2)
						childs.btnGet:visible(v.state == 1)
						childs.btnGo:hide()
						if v.state == 0 then
							if v.cfg.goToPanel then
								childs.btnGo:show()
							else
								childs.btnGo:hide()
								childs.txtProgress:y(node:height()/2)
							end
						end
						bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickCell, node, v)}})
						bind.touch(list, childs.btnGo, {methods = {ended = functools.partial(list.clickGoCell, v)}})
					else
						childs.bg:hide()
						childs.cornerIcon:hide()
						childs.cornerIcon1:hide()
						childs.txtCorner:hide()
						childs.txtTitle:hide()
						childs.txtContent:hide()
						childs.txtExp:hide()
						childs.txtProgress:hide()
						childs.btnGet:hide()
						childs.btnGo:hide()
						childs.imgGot:hide()
						childs.txtCorner1:hide()
						node:height(0)
					end
				end,
				asyncPreload = 5,
			},
			handlers = {
				clickCell = bindHelper.self("onGetClick"),
				clickGoCell = bindHelper.self("onGoClick"),
			},
		},
	},
	["shopPanel"] = "shopPanel",
	["shopPanel.item"] = "shopItem",
	["shopPanel.subList"] = "shopSubList",
	["shopPanel.list"] = {
		varname = "shoplist",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("shopDatas"),
				dataOrderCmp = function (a, b)
					return a.position < b.position
				end,
				item = bindHelper.self("shopSubList"),
				cell = bindHelper.self("shopItem"),
				columnSize = 5,
				sliderBg = bindHelper.self("slider"),
				asyncPreload = 15,
				onCell = function(list, node, k, v)
					local childs = node:multiget("name", "icon", "num", "btnBuy", "maskPanel", "textLimiteNote", "textLimiteNum")
					node:setTouchEnabled(true)
					childs.maskPanel:hide()
					childs.icon:hide()
					local name = uiEasy.setIconName(v.itemId, nil, {node = childs.name})
					adapt.setTextScaleWithWidth(childs.name, childs.name:text(), node:width() - 150)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.itemId,
							},
							simpleShow = true,
							onNode = function(node)
								node:setTouchEnabled(false)
								node:xy(childs.icon:xy())
									:scale(1.5)
									:z(3)
							end,
						},
					})
					childs.num:text("x".. v.num)
					local key, val = csvNext(v.cfg.costMap)
					local cost = dataEasy.getCfgByKey(key)
					childs.btnBuy:get("icon"):texture(dataEasy.getIconResByKey(key))
					childs.btnBuy:get("txt"):text(val)
					adapt.oneLineCenterPos(cc.p(180, 50), {childs.btnBuy:get("icon"), childs.btnBuy:get("txt")}, cc.p(5, 0))
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, list:getIdx(k), v)}})
					if v.itemNum == 0 then
						node:setTouchEnabled(false)
						childs.maskPanel:show()
					end
					local limitNum = v.cfg.limitTimes
					local leftNum = v.itemNum
					if limitNum > 0 then
						childs.textLimiteNum:text(leftNum .. "/" ..limitNum)
						local color = ui.COLORS.NORMAL.FRIEND_GREEN
							if leftNum == 0 then
								color = ui.COLORS.NORMAL.ALERT_ORANGE
							end
						text.addEffect(node:get("textLimiteNum"), {color = color})
					end
					childs.textLimiteNote:visible(limitNum > 0)
					childs.textLimiteNum:visible(limitNum > 0)
					adapt.oneLineCenterPos(cc.p(210, 150), {childs.textLimiteNote, childs.textLimiteNum}, cc.p(5, 0))
				end,
				-- onBeforeBuild = function(list)
				-- 	local listX, listY = list:xy()
				-- 	local listSize = list:size()
				-- 	local x, y = list.sliderBg:xy()
				-- 	local size = list.sliderBg:size()
				-- 	list:setScrollBarEnabled(true)
				-- 	list:setScrollBarColor(cc.c3b(241, 59, 84))
				-- 	list:setScrollBarOpacity(255)
				-- 	list:setScrollBarAutoHideEnabled(false)
				-- 	list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x, (listSize.height - size.height) / 2 + 5))
				-- 	list:setScrollBarWidth(size.width)
				-- 	list:refreshView()
				-- end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["taskPanel.iconTitle1"] = "taskIconTitle1",
	["taskPanel.iconTitlePanel"] = "iconTitlePanel",
	["taskPanel.iconTitlePanel.iconTitle2"] = "taskIconTitle2",
	["taskPanel.iconTitle3"] = "taskIconTitle3",
	["taskPanel.icon"] = "taskIcon",
	["taskPanel.lv"] = {
		varname = "taskLv",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(123, 115, 118, 255),  size = 2}}
		}
	},
	["taskPanel.txtNode"] = "taskExpLess",
	["taskPanel.expBar"] = "taskExpBar",
	["taskPanel.notMaxPanel"] = "taskNotMaxPanel",
	["taskPanel.notMaxPanel.imgLock"] = "taskImgLock",
	["taskPanel.notMaxPanel.taskMask"] = "taskMask",
	["taskPanel.notMaxPanel.normalList"] = "taskNormalList",
	["taskPanel.notMaxPanel.highList"] = "taskHighList",
	["taskPanel.notMaxPanel.txtHigh"] = "taskTxtHigh",
	["taskPanel.notMaxPanel.txtNormal"] = "taskTxtNormal",
	["taskPanel.imgMax"] = "taskImgMax",
}

function ActivityPassportView:onCreate(activityId)
	self.shopPanel:hide()
	gGameModel.currday_dispatch:getIdlerOrigin("passport"):set(true) -- 客户端记录今日是否打开过通行证界面，用于红点显示判断
	self.activityId = activityId
	self:initModel()
	self:initData()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	self.endDate = yyCfg.endDate

	-- 顶部UI
	self.topView = gGameUI.topuiManager:createView(self.exchangeShop == 1 and "passport" or "default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.passport, subTitle = "ORNAMENTS"})

	-- 左侧切换页签
	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.passport, red = true},
		[2] = {name = gLanguageCsv.task, red = true},
		[3] = self.exchangeShop == 1 and {name = gLanguageCsv.starSkillExchange, red = false} or nil,
	})
	self.showTab = idler.new(TABTYPE.REWARD)			 -- 初始停留在第一页
	self.showTab:addListener(function(val, oldval)       -- 监听Tab页变换
		self[TAB_Panel[oldval]]:visible(false)
		self[TAB_Panel[val]]:visible(true)
		self.tabDatas:atproxy(oldval).select = false     -- tab选中状态
		self.tabDatas:atproxy(val).select = true
	end)

	-- taskHighList位置 self.taskHighList:setItemAlignCenter(), 会改变list位置，idlereasy监听，反复改变位置，会导致位置偏移，需要每次改变前复原位置
	local taskHighListPosX, taskHighListPosY = self.taskHighList:xy()

	-- 通行证活动经验spine
	self.spineExp = widget.addAnimationByKey(self.taskPanel, "tongxingzheng/tongxingzheng.skel", 'spineExp', "effect2", 999)
		:xy(self.taskIcon:x(), self.taskIcon:y())
		:scale(2)
	self.spineExp:setTimeScale(0)

	-- passport数据监听

	self.clientBuyTimes = idler.new(true)
	idlereasy.any({self.passport, self.clientBuyTimes}, function(_, passport)
		local nextExpTotal = 0 -- 升至下一等级需要的经验总量（用于显示上的计算）
		local nexRewardData = {} -- 下一级奖励
		self.currentPassportLv = passport.level
		local isMaxLv = self.max == passport.level  -- 是否达到最大等级
		self.buyHigh = itertools.size(passport.buy) > 0 -- 是否购买高级通行证
		self.curRewardIdx = nil
		local maxReceivedIdx = 1 -- 最大已领的下标
		for k, v in ipairs(self.awardCfg) do
			local cfg = v.cfg -- 表原始数据，只读，不可修改
			local custom = v.custom -- 新增的自定义数据，可以修改
			if cfg.level <= passport.level then
				nextExpTotal = nextExpTotal + cfg.needExp
			end
			if cfg.level == passport.level + 1 then
				nexRewardData = v
			end
			-- 奖励状态发生变化
			local state = passport.normal_award[custom.csvId]
			if state and custom.normalAwardState ~= state then
				custom.normalAwardState = state
				if not self.isReset then  -- 第一次进入界面不修改
					self:modifyItem(k)
				end
			end
			local state = passport.elite_award[custom.csvId]
			if state and custom.eliteAwardState ~= state then
				custom.eliteAwardState = state
				if not self.isReset then  -- 第一次进入界面不修改
					self:modifyItem(k)
				end
			end

			-- 当前可领取最大奖励
			if not self.curRewardIdx then
				if not self.buyHigh then
					if custom.normalAwardState == 1 then
						self.curRewardIdx = k

					elseif custom.normalAwardState == 0 then
						maxReceivedIdx = k
					end
				else
					if custom.normalAwardState == 1 or custom.eliteAwardState == 1 then
						self.curRewardIdx = k

					elseif custom.normalAwardState == 0 and custom.eliteAwardState == 0 then
						maxReceivedIdx = k
					end
				end
			end
		end
		self.curRewardIdx = self.curRewardIdx or maxReceivedIdx
		self.rewardLv:text(passport.level)
		local name = self.buyHigh and self.recharge[2].name or self.recharge[1].name
		self.rewardName:text(name)
		self.rewardTxtNormal:text(self.recharge[1].name)
		self.rewardTxtHigh:text(self.recharge[2].name)
		local times = string.split(time.getActivityOpenDate(passport.yy_id),"-")
		self.rewardEndTime:text(times[2])
		local rewardExpNum = (passport.exp - nextExpTotal + self.awardCfg[passport.level].cfg.needExp).."/"..self.awardCfg[passport.level].cfg.needExp
		local taskExpLessNum = string.format(gLanguageCsv.leveUpLessExp, nextExpTotal-passport.exp)
		if isMaxLv then
			rewardExpNum, taskExpLessNum = gLanguageCsv.levelMax, gLanguageCsv.levelMax
		else
			uiEasy.createItemsToList(self, self.taskNormalList, nexRewardData.cfg.normalAward, {scale = 0.8})  --  改成非list
			-- self.taskHighList:xy(taskHighListPosX ,taskHighListPosY)
			uiEasy.createItemsToList(self, self.taskHighList, nexRewardData.cfg.eliteAward, {margin = 20, scale = 0.8,  onAfterBuild = function()
				self.taskHighList:setItemAlignCenter()
			end})
		end

		self.rewardExp:text(rewardExpNum)
		self.taskExpLess:text(taskExpLessNum)
		self.txtNode2:visible(passport.level ~= self.max)
		self.rewardExpBar:setPercent((passport.exp - nextExpTotal + self.awardCfg[passport.level].cfg.needExp)/self.awardCfg[passport.level].cfg.needExp*100)
		self.imgLvMax:visible(isMaxLv)
		self:updBuyTime(isMaxLv)
		self.highMask:visible(not self.buyHigh)
		self.highLock:visible(not self.buyHigh)

		-- 任务相关 begin
		local version = yyCfg.clientParam.version
		if version == 1 then
			self.taskIconTitle1:x(203 + 10)
			self.taskIconTitle3:x(570 - 25)
		else
			self.taskIconTitle2:x(465 - 116*(version - 1))
		end
		self.taskIcon:texture(self.buyHigh and "activity/passport/icon_better_2.png" or "activity/passport/icon_regular_2.png")
		self.rewardIcon:texture(self.buyHigh and "activity/passport/icon_better_2.png" or "activity/passport/icon_regular_2.png")
		self.taskIconTitle3:texture(self.buyHigh and "activity/passport/task/" .. "txt_ds.png" or "activity/passport/task/" .. "txt_mx.png")
		self.taskImgLock:visible(not self.buyHigh)
		self.taskMask:visible(not self.buyHigh)
		self.taskLv:text(passport.level)
		self.taskExpBar:setPercent((passport.exp - nextExpTotal + self.awardCfg[passport.level].cfg.needExp)/self.awardCfg[passport.level].cfg.needExp*100)
		self.taskImgMax:visible(isMaxLv)
		self.taskNotMaxPanel:visible(not isMaxLv)
		self.taskTxtNormal:text(self.recharge[1].name)
		self.taskTxtHigh:text(self.recharge[2].name)

		self:updTaskData(passport)
		self:updataShopDatas()
		self:updShowView()
	end)
	-- 第一次进入跳转至最大可领取奖励
	if self.isReset then
		self:resetScroll()
	end

	-- 右侧大节点展示相关 begin
	-- 定时循环播放奖励展示icon
	local iconDatas = string.split(yyCfg.clientParam.res, "|")
	local iconDatasMax = itertools.size(iconDatas)
	self.iconDatas = idlers.newWithMap(iconDatas)
	self:enableSchedule()
	self:schedule(function()
		local index = self.index:read()
		if index < iconDatasMax - 1 then
			index = index + 1
		else
			index = 0
		end
		self.index:set(index)
		self.iconList:jumpToItem(index, cc.p(0, 1), cc.p(0, 1))
	end, ICONTIME, ICONTIME, 1)

	-- 滑动list,让当前item自动居中对齐
	self.iconList:onScroll(function(event)
		local center = self.iconList:getIndex(self.iconList:getCenterItemInCurrentView())
		if event.name == "SCROLLING_ENDED" then
			self.iconList:jumpToItem(center, cc.p(0, 1), cc.p(0, 1))
			self.index:set(center)
		end
	end)

	-- 下发小圆点变换
	for i=1,iconDatasMax do
		-- 10 是两个原点之间的间距
		local posX = self.iconPointPanel:width()/2 -(iconDatasMax - 1)/2*(self.pointItem:width()+16) + (i-1)*(self.pointItem:width()+16)
		local posY = self.iconPointPanel:height()/2
		local point = self.pointItem:clone()
			:xy(posX, posY)
			:show()
			:addTo(self.iconPointPanel, 10, "point"..i)
	end

	idlereasy.when(self.index, function(_, index)
		for i=1,iconDatasMax do
			self.iconPointPanel:get("point"..i):setOpacity(255*0.4)
		end
		self.iconPointPanel:get("point"..(index+1)):setOpacity(255*0.7)
	end)
	adapt.oneLineCenterPos(cc.p(450, 900), {self.taskIconTitle1, self.iconTitlePanel, self.taskIconTitle3}, {cc.p(2, -self.iconTitlePanel:size().height/2), cc.p(2, self.iconTitlePanel:size().height/2)})
end

function ActivityPassportView:initModel()
	self.passport = gGameModel.role:getIdler("passport")
	--已购买的商品
	self.shop = self.passport:read().shop or {}
end

function ActivityPassportView:initData()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	-- 根据活动id获取当前活动id对应表内容
	self.awardCfg = {}  -- 奖励表
	for k,v in orderCsvPairs(csv.yunying.passport_award) do
		if v.huodongID == yyCfg.huodongID then
			table.insert(self.awardCfg, {cfg = v, custom = {csvId = k}}) -- cfg为表原始数据，custom为添加的自定义数据
		end
	end
	self.taskCfg = {}  -- 任务表
	local huodongID = yyCfg.paramMap.taskHuodongID
	self.startHideLevel = yyCfg.paramMap.startHideLevel	or 0	--隐藏奖励等级
	self.exchangeShop = yyCfg.paramMap.exchangeShop		--商店隐藏控制
	for k,v in orderCsvPairs(csv.yunying.passport_task) do
		if v.huodongID == huodongID then
			self.taskCfg[k] = v
		end
	end
	self.shopCfg = {}	--商店表
	for k,v in orderCsvPairs(csv.yunying.passport_shop) do
		if v.huodongID == yyCfg.huodongID then
			self.shopCfg[k] = v
		end
	end
	self.recharge = csv.yunying.passport_recharge  -- 充值表
	self.max = #self.awardCfg -- 奖励表最大长度
	self.taskDatas = idlers.newWithMap({})
	self.shopDatas = idlers.newWithMap({})
	self.currentPassportLv = self.passport:read().level     			-- 通行证当前等级
	self.buyHigh = itertools.size(self.passport:read().buy) > 0			-- 是否购买进阶通行证
	self.index = idler.new(0)     -- iconList 首项从0开展示
	self.isReset = true  -- 第一次进入通行证界面，重置reset界面信息
	if not self.clock then
		self.clock = 1	--小于特定等级的锁是否存在
	end
	self.items = gGameModel.role:getIdler("items")
end

function ActivityPassportView:updBuyTime(isMaxLv)
	self.btnBuy:visible(not self.buyHigh)
	-- 若客户端已买，但服务器未到账的，不显示购买通行证按钮
	for k,v in orderCsvPairs(csv.yunying.passport_recharge) do
		if v.type == 1 then
			local buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", self.activityId, k, 0)
			if buyTimes > 0 then
				self.btnBuy:hide()
			end
		end
	end
	self.btnBuyExp:hide()
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	if self.buyHigh and (not isMaxLv) then
		local dt = (gGameModel.role:read("yy_endtime")[self.activityId] or 0) - time.getTime()
		local buyExpShowDayFlag = yyCfg.clientParam.buyExpShowDay and yyCfg.clientParam.buyExpShowDay > 0 and dt <= yyCfg.clientParam.buyExpShowDay * 24 * 3600
		if yyCfg.paramMap.canBuyExp == 1 or buyExpShowDayFlag then
			self.btnBuyExp:show()
		end
	end
end

function ActivityPassportView:updTaskData(passport)
	local taskDatas = {}
	local canOneKeyReceive = false
	self.playDatas = 0 	--一键领取播放特效的note个数
	for k,v in pairs(self.taskCfg) do
		local judge = v.periodType == 1
		judge = judge or (v.periodType == 2 and v.weekParam == passport.week_num)
		judge = judge and (v.taskAttribute == 3 or self.buyHigh)
		if judge then
			local t = {
				cfg = v,
				csvId = k,
				progress = 0,	-- 初始进度为0
				state = 0,		-- 初始状态不可领取
				sort = 2,		-- 任务状态排序 可领取>未完成>已领取
				buyHigh = self.buyHigh,
			}

			local info = passport.task[k]
			if info then
				t.progress = info[1]
				t.state = info[2]
				if info[2] ~= 0 then
					t.sort = info[2] == 1 and 1 or 3
					if info[2] == 1 then
						canOneKeyReceive = true
						if self.playDatas < 5 then 	--控制一次播放的动画不超过5个
							self.playDatas = self.playDatas + 1
						end
					end
				end
			end
			table.insert(taskDatas, t)
		end
	end
	setBtnState(self.getBtn, canOneKeyReceive)
	self.taskDatas:update(taskDatas)
end

function ActivityPassportView:updataShopDatas()
	local shopDatas = {}
	for k, v in pairs(self.shopCfg) do
		local itemNum = self:getItemNum(k, v)
		local itemId, num = csvNext(v.items)
		local costType, costNum = csvNext(v.costMap)
		local t = {
			position = v.position,
			costType = costType,
			costNum = costNum,
			cfg = v,
			csvId = k,
			itemId = itemId,
			num = num,
			itemNum = itemNum or v.limitTimes
		}
		table.insert(shopDatas, t)
	end
	self.shopDatas:update(shopDatas)
end

function ActivityPassportView:updShowView()
	-- 任务相关 end
	if self.currentPassportLv > self.startHideLevel and self.clock == 1 then
		self:resetScroll()
		self.clock = 0
	end
	if not self.buyHigh then
		local richText = rich.createWithWidth(gLanguageCsv.passwordActivateNote, 38, nil, 1250)
			:addTo(self.taskNote, 10)
			:anchorPoint(cc.p(0, 0.5))
			:xy(-410, 10)
			:formatText()
	else
		self.taskNote:hide()
		local richText = rich.createWithWidth(gLanguageCsv.passwordTaskNote, 38, nil, 1250)
			:addTo(self.taskNote1, 10)
			:anchorPoint(cc.p(0, 0.5))
			:xy(-410, 5)
			:formatText()
	end
end

function ActivityPassportView:onTabClick( list, tab )
	self.rewardScroll:stopAutoScroll()
	self.taskList:stopAutoScroll()
	self.showTab:set(tab)
end

function ActivityPassportView:onBtnRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function ActivityPassportView:onBtnBuy()
	self.rewardScroll:stopAutoScroll()
	gGameUI:stackUI("city.activity.passport.buy", nil, nil, self.activityId, self:createHandler("onBtnBuyCb"))
end

function ActivityPassportView:onBtnBuyCb()
	self.clientBuyTimes:notify()
end

function ActivityPassportView:onBtnBuyExp()
	self.rewardScroll:stopAutoScroll()
	gGameUI:stackUI("city.activity.passport.buy_exp", nil, nil, self.activityId)
end

function ActivityPassportView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(116),
		c.noteText(63001, 63006),
	}
	return context
end

function ActivityPassportView:onBtnGetClick( v )
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId, v.custom.csvId)
end

function ActivityPassportView:onBtnOneKeyGet()
	local isHaveRewardGet = false
	local passport = self.passport:read()
	for _, state in pairs(passport.normal_award) do
		if state == 1 then
			isHaveRewardGet = true
			break
		end
	end
	for _, state in pairs(passport.elite_award) do
		if state == 1 then
			isHaveRewardGet = true
			break
		end
	end
	if not isHaveRewardGet then
		gGameUI:showTip(gLanguageCsv.noRewardGet)
		return
	end
	gGameApp:requestServer("/game/yy/passport/award/get_onekey", function(tb)
		gGameUI:showGainDisplay(tb)
		self:resetScroll()
	end, self.activityId)
end

function  ActivityPassportView:onGetClick(list, node, v)
	local showOver = {false}
	gGameApp:requestServerCustom("/game/yy/passport/task/get_exp")
		:params(self.activityId, v.csvId)
		:onResponse(function()
			-- 特效
			widget.addAnimationByKey(node, "tongxingzheng/tongxingzheng.skel", 'lingqu', "effect1", 999)
				:xy(node:width()/2, node:height()/2)
				:scale(2)
				:play("effect1")
				self.spineExp:setTimeScale(1)
				self.spineExp:play("effect2")
			performWithDelay(self, function()
				showOver[1] = true
			end, 26/30)
		end)
		:wait(showOver)
		:doit()
end

function  ActivityPassportView:onAllGetBtn()
	local showOver = {false}
	gGameApp:requestServerCustom("/game/yy/passport/task/get_exp")
		:params(self.activityId, -1)
		:onResponse(function()
			-- 特效
				local noteTable = self.taskList:getItems()
				for i = 1, self.playDatas do
					widget.addAnimationByKey(noteTable[i], "tongxingzheng/tongxingzheng.skel", 'lingqu', "effect1", 999)
					:xy(noteTable[i]:width()/2, noteTable[i]:height()/2)
					:scale(2)
					:play("effect1")
				end
				self.spineExp:setTimeScale(1)
				self.spineExp:play("effect2")
			performWithDelay(self, function()
				showOver[1] = true
			end, 26/30)
		end)
		:wait(showOver)
		:doit()
end

function ActivityPassportView:onGoClick(list, v)
	jumpEasy.jumpTo(v.cfg.goToPanel)
end

-- @desc 建立滚动层，装在奖励item
function ActivityPassportView:buildScroll()
	-- [[ 主要思路：创建固定数量item，加载对应信息，当左右滑动时，将队伍item移动至队首，并更新信息，支持多列同时移动]]
	self.rewardScroll:setScrollBarEnabled(false) -- 隐藏滚动条
	local itemWidth = self.rewardItem:width() -- item 宽度
	local size = self.rewardScroll:size()	-- rewardScroll显示区域大小
	local container = self.rewardScroll:getInnerContainer() -- rewardScroll实际滚动区域
	local innerWidth = 0
	local innerHeight = 0

	--	低于一定等级的时候只展示等级之内的奖励
	if self.currentPassportLv < self.startHideLevel then
		innerWidth, innerHeight = itemWidth * self.startHideLevel, size.height -- rewardScroll实际滚动区域宽高
	else
		innerWidth, innerHeight = itemWidth*self.max, size.height
	end
	container:size(innerWidth, innerHeight)
	self.itemCreateNum = math.ceil(size.width/itemWidth) + 5  -- 创建item总数，+5是为了提供一个缓冲区域，确保显示区域内，一定有item显示

	local col = self.itemCreateNum
	local itemLength = itemWidth * col -- 创建所有item的总宽度，用于item位置移动

	-- 这段代码主要逻辑是为了当前奖励至最大奖励的长度不足itemCreateNum时，向前补足长度，保证item创建总数为itemCreateNum个
	-- 这里只是读取左右item编号，与创建时须保持一致
	local min = self.curRewardIdx  -- 最左item id
	local max = self.curRewardIdx-1+self.itemCreateNum -- 理论最右item id
	if max > self.max then  -- 理论最右item id超过最大id后，最右item id等于最大id， 最左item id向前补足长度，保证item总数长度为itemCreateNum
		min = min - (max - self.max)
		max = self.max
	end

	local leftIdx = min%col == 0 and col or min%col -- 初始化最左侧item创建编号，计算逻辑即编号规则，编号与id是固定对应上的，用于位置计算
	local rightIdx = leftIdx - 1 == 0 and col or leftIdx - 1  --  初始化最右侧item创建编号
	local dir, idx  -- 方向，当前item编号
	self.percent = -1
	local function onMove()
		local percent = self.rewardScroll:getScrolledPercentHorizontal()
		if self.percent > percent then
			dir = "right"-- 手指滑动方向
			idx = rightIdx
			self.percent = percent
		elseif self.percent < percent then
			dir = "left"
			idx = leftIdx
			self.percent = percent
		end

		local lx = math.abs(container:x())  -- container位置绝对值，转换成item坐标，即为显示区域最左边item在rewardScroll中的坐标
		local rx = lx + size.width          -- container位置绝对值+显示区域宽度，转换成item坐标，即为显示区域最右边item在rewardScroll中的坐标
		local item = self.rewardScroll:getChildByName("reward" .. idx)

		local right = math.ceil(rx/itemWidth) -- 右侧奖励id，通过位置计算，计算规则依赖：从1级开始，逐级提升(不支持缺级，不从1开始)
		local count = self.currentPassportLv >= self.startHideLevel and self.max or self.startHideLevel
		for i = right, count do     	-- 读取实际需要显示
			if self.awardCfg[i].cfg.specialAward == 1 then
				if i ~= self.rigthRewardIndex then --判断奖励是否有变更，若有变更，刷新，无变更，不刷新
					self.rigthRewardIndex = i
					self:refreshTarget()
				end
				break
			end
		end

		--  刷新左右编号
		local function calculatelIdx(dir, num)
			local dt = num
			if dir ~= "left" then
				dt = col - num
			end
			leftIdx = (dt + leftIdx - 1) % col + 1
			rightIdx = (dt + rightIdx - 1) % col + 1
		end
		local function calculateRewardItem(num)
			for i=1,num do
				local itemIdx = dir == "left" and (idx + i - 1) % col or (idx - i + 1) % col
				itemIdx = itemIdx == 0 and col or itemIdx
				local cItem = self.rewardScroll:getChildByName("reward"..itemIdx)
				if cItem then
					if dir == "left" then
						cItem:x(cItem:x() + itemLength)
					else
						cItem:x(cItem:x() - itemLength)
					end
					self:modifyItem(cItem:x()/itemWidth+1)
				end
			end
		end

		if item then
			local x = item:x()
			if dir == "left" and lx > x + itemWidth then  -- lx > x + itemWidth 表示最左侧item已滑出显示区域，需要移动至右侧队尾
				local rightItem = self.rewardScroll:getChildByName("reward"..(rightIdx == 0 and col or rightIdx))  -- 临界值判断  -- 最大奖励item
				local rightLess = (innerWidth - rightItem:x())/itemWidth - 1  -- 右侧剩余可移动位置，最大奖励已加载后，左侧item不应再向右侧移动
				local num = math.min(math.ceil((lx - (x + itemWidth)) / itemWidth), rightLess) -- 需要移动的item数量
				calculatelIdx(dir, num)
				calculateRewardItem(num)
				idx = leftIdx
			elseif dir == "right" and rx < x then  -- rx < x 表示最右侧item已向右滑出显示区域，需要移动至左侧队尾
				local leftItem = self.rewardScroll:getChildByName("reward"..(leftIdx == 0 and col or leftIdx))  -- 临界值判断  -- 最小奖励item
				local leftLess = leftItem:x()/itemWidth  -- 左侧剩余可移动i位置，最小奖励已加载后，右侧item不应再向左侧移动
				local num = math.min(math.ceil(((x - itemWidth) - rx) / itemWidth), leftLess)
				calculatelIdx(dir, num)
				calculateRewardItem(num)
				idx = rightIdx
			end

			local itemSize = itemWidth * self.startHideLevel
			if self.currentPassportLv < self.startHideLevel then
				if dir == "left" and rx >= itemSize - 1 then	--减一是因为滑到底部之后不算滑动
					gGameUI:showTip(string.format(gLanguageCsv.upPasswordLevelToGet, self.startHideLevel))
				end
			end
		end
	end
	onMove()

	self.rewardScroll:onEvent(function(event)
		if event.name == "CONTAINER_MOVED" then
			onMove()
		elseif event.name == "SCROLLING_BEGAN" then
			self:refreshNoClick(true) -- 滑动开始，显示禁止点击层
		elseif event.name == "AUTOSCROLL_ENDED" then
			self:refreshNoClick(false) -- 自动滑动结束，隐藏禁止点击层
		elseif event.name == "SCROLLING_ENDED" then
			-- 这里不能隐藏禁止点击层，因为这之后，还有惯性自动滑动
		end
	end)
end

-- 创建奖励item
function ActivityPassportView:buildItem()
	local min = self.curRewardIdx  -- 最左item id
	local max = self.curRewardIdx-1+self.itemCreateNum -- 理论最右item id
	if max > self.max then  -- 理论最右item id超过最大id后，最右item id等于最大id， 最左item id向前补足长度，保证长度为itemCreateNum
		min = min - (max - self.max)
		max = self.max
	end

	for i = min,max do  -- 最大创建item不超过self.max,创建长度保证为itemCreateNum个
		self:addItem(i)
	end
end

-- 添加item
function ActivityPassportView:addItem(id)
	local rewardInfo = self.awardCfg[id]
	local item = self.rewardItem:clone()
	local idx = id%self.itemCreateNum == 0  and self.itemCreateNum or id%self.itemCreateNum
	local itemWidth = self.rewardItem:width() -- item 宽度
	local x = (id - 1) * itemWidth
	item:xy(x, 0)
	self:refreshRewardItem(item, id)
	self.rewardScroll:addChild(item, idx, "reward"..idx)
	item:show()
	return item
end

-- 修改item
function ActivityPassportView:modifyItem(id)
	for i=1,self.itemCreateNum do
		local item =  self.rewardScroll:getChildByName("reward"..i)
		local x = item:x()
		local modifyItemX = (id-1)*self.rewardItem:width()
		if x == modifyItemX then  -- 位置相同表示是信息完全相同的item，需要修改信息；一个item可能改变为不同等级信息，等级不相同，不能修改
			self:refreshRewardItem(item, id)
		end
	end
end

function ActivityPassportView:refreshRewardItem(item, id)
	local rewardInfo = self.awardCfg[id]
	local isSpecial = rewardInfo.cfg.specialAward == 1
	local childs = item:multiget("lv", "normalPanel", "highPanel1", "highPanel2", "topMask", "bottomMask", "btnGet", "noClick")
	childs.lv:text(rewardInfo.cfg.level)

	-- 普通奖励
	local normal = {}
	for k,v in csvMapPairs(rewardInfo.cfg.normalAward) do
		normal.key = k
		normal.num = v
		normal.state = rewardInfo.custom.normalAwardState
	end
	self:onBindIcon(self.rewardScroll, childs.normalPanel, normal, isSpecial)
	local high = {}
	for k,v in csvMapPairs(rewardInfo.cfg.eliteAward) do
		table.insert(high, {key = k, num = v, state = rewardInfo.custom.eliteAwardState})
	end
	-- 进阶奖励1
	self:onBindIcon(self.rewardScroll, childs.highPanel1, high[1], isSpecial)
	-- 进阶奖励2
	if high[2] then
		self:onBindIcon(self.rewardScroll, childs.highPanel2, high[2], isSpecial)
		childs.highPanel2:show()
	else
		childs.highPanel2:hide()
	end

	childs.btnGet:visible(rewardInfo.custom.normalAwardState == 1 or rewardInfo.custom.eliteAwardState == 1)  --判断是否有奖励可领取，分为普通奖励和进阶奖励，1可领取，0已领取
	bind.touch(self, childs.btnGet, {methods = {ended = function(view, node, event)
		self:onBtnGetClick(rewardInfo)
	end}})
	childs.topMask:visible(self.currentPassportLv < rewardInfo.cfg.level)
	childs.bottomMask:visible(self.currentPassportLv < rewardInfo.cfg.level or not self.buyHigh)

	bind.click(self, childs.noClick, {method = function()
		self:onRewardNoClick()
	end})
end

function ActivityPassportView:onRewardNoClick()
	self:refreshNoClick(false)
end

-- 绑定icon_key通用方法
function ActivityPassportView:onBindIcon(parent, node, data, isEffect)
	bind.extend(self, node, {
		class = "icon_key",
		props = {
			data = data,
			onNode = function (panel)
				panel:scale(0.9)
				local img = node:get("img")
				if img then
					img:visible(data.state == 0)
				else
					img = ccui.ImageView:create("common/icon/radio_selected.png")
					:addTo(node, 1000, "img")
					:xy(130, 130)
					:visible(data.state == 0)
				end
			end
		},
	})

	local sprite = node:getChildByName("wupinshanguang")
	if sprite then
		sprite:removeFromParent()
	end
	if isEffect then
		widget.addAnimationByKey(node, "wupinshanguang/saoguang.skel", "wupinshanguang", "effect_loop", 999)
			:xy(node:size().width/2, node:size().height/2)
			:scale(0.5)
	end
end

-- 跳转至当前最大可领取奖励位置
function ActivityPassportView:jumpScroll()
	local max = self.itemCreateNum
	local idx = self.curRewardIdx%max == 0 and max or self.curRewardIdx%max
	local item = self.rewardScroll:getChildByName("reward"..idx)
	if not item then
		return
	end
	local x = item:x()
	local size = self.rewardScroll:getInnerContainer():size()
	local scrollWidth = self.rewardScroll:size().width
	local percent = cc.clampf(x / (size.width - scrollWidth) * 100, 0, 100)
	self.rewardScroll:scrollToPercentHorizontal(percent, 0.01, false)
	self.percent = percent  -- 当前滚动层百分比，用于判断滚动方向
end

function ActivityPassportView:resetScroll()
	self.rewardScroll:removeAllChildren()
	self:buildScroll()
	self:buildItem()
	self:refreshNoClick(false)
	self:jumpScroll()
	self.isReset = false
end

-- @desc 右侧展示奖励刷新
function ActivityPassportView:refreshTarget()
	local targetRewardInfo = self.awardCfg[self.rigthRewardIndex]
	self.target:getChildByName("lv"):text(targetRewardInfo.cfg.level..gLanguageCsv.levelGet)
	if matchLanguage({"kr"}) then
        adapt.setTextAdaptWithSize(self.target:getChildByName("lv"), {size = cc.size(150,100)})
	elseif matchLanguage({"en"}) then
		self.target:getChildByName("lv"):text(gLanguageCsv.levelGet .. targetRewardInfo.cfg.level)
	end
	-- 普通奖励
	local normal = {}
	for k,v in csvMapPairs(targetRewardInfo.cfg.normalAward) do
		normal.key = k
		normal.num = v
		normal.state = targetRewardInfo.custom.normalAwardState
	end

	-- 进阶奖励
	local high = {}
	for k,v in csvMapPairs(targetRewardInfo.cfg.eliteAward) do
		table.insert(high, {key = k, num = v, state = targetRewardInfo.custom.eliteAwardState})
	end

	-- 普通奖励
	self:onBindIcon(self.rewardScroll, self.targetNormalPanel, normal, true)
	-- 进阶奖励1
	self:onBindIcon(self.rewardScroll, self.targetHighPanel1, high[1], true)
	-- 进阶奖励2
	if high[2] then
		self:onBindIcon(self.rewardScroll, self.targetHighPanel2, high[2], true)
		self.targetHighPanel2:show()
	else
		self.targetHighPanel2:hide()
	end
end

-- @desc 禁止点击方法，用于滑动中禁止icon点击
function ActivityPassportView:refreshNoClick(state)
	for i=1,self.itemCreateNum do
		local noClickPanel = self.rewardScroll:getChildByName("reward"..i):getChildByName("noClick")
		noClickPanel:visible(state)
	end
	self.targetNoClick:visible(state)
end

--获得商品剩余个数
function ActivityPassportView:getItemNum(k, v)
	local num = v.limitTimes
	for key, val in pairs(self.shop) do
		if key == k then
			num = v.limitTimes - val
			break
		end
	end
	return num
end

function ActivityPassportView:onItemClick(list, t, v)
	if v.itemNum <= 0 then
		return
	end

	local lastTime = time.getNumTimestamp(self.endDate) - time.getTime()
	local time1, time2 = math.modf(lastTime / (3600 * 24))
	local title = gLanguageCsv.goTobuy
	local str = gLanguageCsv.passwordBuyVipNote
	local coin, price = csvNext(v.cfg.costMap)
	local passportCoin = self.items:read()[coin] or 0
	local discount = 1
	if self.buyHigh then
		-- if passportCoin >= price then
		gGameUI:stackUI("common.buy_info", nil, nil, v.cfg.costMap, {id = v.itemId, num = v.num}, {maxNum = v.itemNum, discount = discount, contentType="num"}, self:createHandler("buyItemCallBack", v))
		-- else
		-- 	if coin == game.ITEM_TICKET.passportCoin then
		-- 		gGameUI:showTip(gLanguageCsv.noPasswordCoin)
		-- 	else
		-- 		gGameUI:showTip(gLanguageCsv.noPasswordVipCoin)
		-- 	end
		-- end
	else
		if coin == game.ITEM_TICKET.passportCoin then
			-- if passportCoin > price then
			gGameUI:stackUI("common.buy_info", nil, nil, v.cfg.costMap, {id = v.itemId, num = v.num}, {maxNum = v.itemNum, discount = discount, contentType="num"}, self:createHandler("buyItemCallBack", v))
			-- else
			-- 	gGameUI:showTip(gLanguageCsv.noPasswordCoin)
			-- end
		else
			local buyVip = function()
				gGameUI:stackUI("city.activity.passport.buy", nil, nil, self.activityId)
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
		end
	end
end

function ActivityPassportView:buyItemCallBack(v, num)
	gGameApp:requestServer("/game/yy/passport/shop/buy", function(tb)
		gGameUI:showGainDisplay({{v.itemId, v.num*num}}, {raw = false})
		-- self.itemsData:atproxy(t.k).leftNum = self.itemsData:atproxy(t.k).leftNum - 1
	end, self.activityId, v.csvId, num)
end

return ActivityPassportView