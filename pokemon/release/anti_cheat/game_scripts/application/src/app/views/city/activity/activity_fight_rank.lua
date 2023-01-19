-- @date: 2019-07-05 17:15:34
-- @desc:战力排行

local OUTLINE_COLORS = {
	[1] = cc.c4b(255, 163, 43, 255),
	[2] = cc.c4b(153, 204, 102, 255),
	[3] = cc.c4b(229, 112, 103, 255),
	[4] = cc.c4b(143, 153, 204, 255),
}

local function setListSlider(list)
	if list.sliderBg:visible() then
		local listX, listY = list:xy()
		local listSize = list:size()
		local x, y = list.sliderBg:xy()
		local size = list.sliderBg:size()
		list:setScrollBarEnabled(true)
		list:setScrollBarColor(cc.c3b(241, 59, 84))
		list:setScrollBarOpacity(255)
		list:setScrollBarAutoHideEnabled(false)
		list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x,(listSize.height - size.height) / 2 + 5))
		list:setScrollBarWidth(size.width)
		list:refreshView()
	else
		list:setScrollBarEnabled(false)
	end
end

local ActivityFightRankView = class("ActivityFightRankView", Dialog)
ActivityFightRankView.RESOURCE_FILENAME = "activity_fight_rank.json"
ActivityFightRankView.RESOURCE_BINDING = {
	["topPanel"] = "topPanel",
	["topPanel.time"] = "timeLabel",
	["topPanel.day"] = {
		varname = "dayLabel",
		binds = {
			event = "extend",
			class = "text_atlas",
			props = {
				data = bindHelper.self("dayStr"),
				pathName = "frhd",
				isEqualDist = false,
				align = "right",
				onNode = function(panel)
					if not panel.isFirstOver then
						panel:x(panel:x() + 185)
						panel:y(panel:y() + 85)
						panel.isFirstOver = true
					end
				end,
			},
		},
	},
	["topPanel.ruleBtn"] = {
		varname = "ruleBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		},
	},
	["closeBtn"] = {
		varname = "closeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["leftPanel.item"] = "tabItem",
	["leftPanel.fightPoint"] = "curFightPoint",
	["leftPanel.list"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					return a.id < b.id
				end,
				onItem = function(list, node, id, v)
					node:get("name"):text(v.name)
					node:get("selected"):visible(v.selected)
					node:get("line"):visible(not v.isLast)

					if v.selected then
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
					else
						text.deleteAllEffect(node:get("name"))
						text.addEffect(node:get("name"), {color = ui.COLORS.NORMAL.DEFAULT})
					end
					bind.click(list, node, {method = functools.partial(list.clickCell, id, v)})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		}
	},
	["centerPanel.mainPanel"] = "mainPanel",
	["centerPanel.mainPanel.fightAwardPanel"] = "fightAwardPanel",
	["centerPanel.mainPanel.fightAwardPanel.item"] = "itemFightAward",
	["centerPanel.mainPanel.fightAwardPanel.sliderBg"] = "fightAwardSliderBg",
	["centerPanel.mainPanel.fightAwardPanel.list"] = {
		varname = "fightAwardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("fightAward"),
				item = bindHelper.self("itemFightAward"),
				sliderBg = bindHelper.self("fightAwardSliderBg"),
				itemAction = {isAction = true, alwaysShow = true},
				onBeforeBuild = function(list)
					setListSlider(list)
				end,
				dataOrderCmp = function(a, b)
					return a.fightPointRequire > b.fightPointRequire
				end,
				onItem = function(list, node, k, v)
					local children = node:multiget("iconList", "bg", "fightPoint","fightText")
					children.fightPoint:text(v.fightPointRequire)
					text.addEffect(children.fightText, {
						outline = {color =  OUTLINE_COLORS[math.min(k,4)]},
					})
					text.addEffect(children.fightPoint, {
						outline = {color =  cc.c4b(255, 255, 64, 255)},
					})
					if k < 4 then
						children.bg:texture(string.format("activity/fight_rank/box_panel_no%d.png",k))
					else
						children.bg:texture("activity/fight_rank/box_panel_no4.png")
					end
					uiEasy.createItemsToList(list, children.iconList, v.award)
				end,
			},
		}
	},
	["centerPanel.mainPanel.rankAwardPanel"] = "rankAwardPanel",
	["centerPanel.mainPanel.rankAwardPanel.item"] = "itemRankAward",
	["centerPanel.mainPanel.rankAwardPanel.sliderBg"] = "rankAwardSliderBg",
	["centerPanel.mainPanel.rankAwardPanel.list"] = {
		varname = "rankAwardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankReward"),
				item = bindHelper.self("itemRankAward"),
				sliderBg = bindHelper.self("rankAwardSliderBg"),
				itemAction = {isAction = true, alwaysShow = true},
				onBeforeBuild = function(list)
					setListSlider(list)
				end,
				dataOrderCmp = function(a, b)
					return a.rank < b.rank
				end,
				onItem = function(list, node, k, v)
					local children = node:multiget("iconList", "bg", "iconPanel")
					if v.rank < 4 then
						children.iconPanel:get("rankIcon"):texture(string.format("activity/fight_rank/icon_no%d.png",v.rank))
						children.bg:texture(string.format("activity/fight_rank/box_panel_no%d.png",v.rank))
					else
						children.iconPanel:get("rankIcon"):hide()
						children.bg:texture("activity/fight_rank/box_panel_no4.png")
						bind.extend(list,children.iconPanel,{
							class = "text_atlas",
							props = {
								data = k,
								pathName = "frhd_num",
								isEqualDist = false,
								align = "center",
								onNode = function(panel)
									panel:x(panel:x() + 110)
									panel:y(panel:y() + 116)
								end,
							}
						})
					end

					uiEasy.createItemsToList(list, children.iconList, v.award)
				end,
			},
		}
	},
	["centerPanel.mainPanel.rankPanel"] = "rankPanel",
	["centerPanel.mainPanel.rankPanel.item"] = "itemRank",
	["centerPanel.mainPanel.rankPanel.sliderBg"] = "rankSliderBg",
	["centerPanel.mainPanel.rankPanel.list"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("fightRank"),
				item = bindHelper.self("itemRank"),
				sliderBg = bindHelper.self("rankSliderBg"),
				selfId = bindHelper.self("id"),
				rankIdler = bindHelper.self("rankIdler"),
				itemAction = {isAction = true, alwaysShow = true},
				-- backupCached = false,
				onBeforeBuild = function(list)
					setListSlider(list)
				end,
				dataOrderCmp = function(a, b)
					return a.fighting_point > b.fighting_point
				end,
				onItem = function(list, node, k, v)
					local children = node:multiget("iconPanel", "icon", "name", "vipIcon", "lv","level", "fightPoint","bg")
					local role = v.role
					children.name:text(role.name)
					children.level:text(role.level)
					if role.vip_level == 0 then
						children.vipIcon:hide()
					else
						children.vipIcon:texture(ui.VIP_ICON[role.vip_level])
					end
					children.fightPoint:text(v.fighting_point)

					bind.extend(list,children.icon,{
						class = "role_logo",
						props = {
							logoId = role.logo,
							frameId = role.frame,
							level = false,
							vip = false,
						},
					})

					adapt.oneLinePos(children.name,children.vipIcon,cc.p(10,0))

					if k < 4 then
						children.iconPanel:get("rankIcon"):texture(string.format("activity/fight_rank/icon_no%d.png",k))
						children.bg:texture(string.format("activity/fight_rank/box_panel_no%d.png",k))
					else
						children.iconPanel:get("rankIcon"):hide()
						children.bg:texture("activity/fight_rank/box_panel_no4.png")
						bind.extend(list,children.iconPanel,{
							class = "text_atlas",
							props = {
								data = k,
								pathName = "frhd_num",
								isEqualDist = false,
								align = "center",
								onNode = function(panel)
									panel:x(panel:x() + 110)
									panel:y(panel:y() + 116)
								end,
							}
						})
					end

					if list.selfId == v.role.id then
						list.rankIdler:set(k)
					end
				end,
			},
		}
	},
	["centerPanel.mainPanel.rankPanel.text1"] = "randHead",
	["centerPanel.mainPanel.rankPanel.richText"] = "richText",
	["centerPanel.mainPanel.rankPanel.di"] = "rankFirst",
	["centerPanel.mainPanel.rankPanel.rankNumber"] = "rankNumber",
	["centerPanel.mainPanel.rankPanel.ming"] = "rankLast",
	["centerPanel.spritePanel"] = "spritePanel",						-- 精灵页面
	["centerPanel.spritePanel.spritePanel"] = "cardArea",				-- 精灵立绘区域
	["centerPanel.spritePanel.spritePanel.cardShow"] = "cardShow",		-- 精灵立绘显示
	["centerPanel.spritePanel.sliderBg"] = "spriteSliderBg",
	["centerPanel.spritePanel.item"] = "spriteItem",
	["centerPanel.spritePanel.list"] = {
		varname = "spriteList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("skillData"),
				item = bindHelper.self("spriteItem"),
				sliderBg = bindHelper.self("spriteSliderBg"),
				itemAction = {isAction = true, alwaysShow = true},
				backupCached = false,
				onBeforeBuild = function(list)
					setListSlider(list)
				end,
				dataOrderCmp = function(a, b)
					-- 保证大招在最末尾
					if a.skillType2 == battle.MainSkillType.BigSkill then
						return false
					elseif b.skillType2 == battle.MainSkillType.BigSkill then
						return true
					end
				end,
				onItem = function(list, node, k, v)
					local children = node:multiget("icon", "name", "type", "note", "targetType","richList","bg")
					uiEasy.setSkillInfoToItems({
						name = children.name,
						icon = children.icon,
						type1 = children.type,
						type2 = children.note,
						target = children.targetType,
					}, v)

					local list, height = beauty.textScroll({
						list = children.richList,
						strs = "#C0x5B545B#" .. eval.doMixedFormula(v.describe,{skillLevel = 1,math = math}),
						isRich = true,
						fontSize = 40,
					})
					local diffHeight = height - list:size().height
					list:size(list:size().width, height)
					list:y(list:y() - diffHeight)
					children.bg:size(children.bg:size().width, children.bg:size().height + diffHeight)

					node:size(node:size().width, node:size().height + diffHeight)

					for k,child in pairs(children) do
						child:y(child:y() + diffHeight)
					end
				end,
			},
		}
	},
}

-- 初始化基本信息
function ActivityFightRankView:initInfo()
	self.cfg = csv.yunying.yyhuodong[self.activityId]
	local cardId = self.cfg.paramMap.card

	self.cardInfo = csv.cards[cardId]
	self.unitCsv = csv.unit[self.cardInfo.unitID]

	local skills = self.cardInfo.skillList
	local skillData = {}
	for _,skillId in pairs(skills) do
		table.insert(skillData,csv.skill[skillId])
	end
	self.skillData = skillData

	local size = self.cardArea:size()
	local cardShow = self.unitCsv.cardShow

	self.cardShow:texture(cardShow)
	local cSize = self.cardShow:size()
	local scale = math.min(size.width / cSize.width , size.height / cSize.height)
	self.cardShow:scale(scale)
end

function ActivityFightRankView:onCreate(activityId, data)
	self.activityId = activityId
	self.yyEndtime = gGameModel.role:read("yy_endtime")
	self.id = gGameModel.role:read("id")

	self.dayStr = idler.new("00")
	self:initInfo()
	-- self:updateRankData()	-- 初始化刷新一次排名
	if data then
		self.endTime = data.view.end_time
	end

	local viewDatas = {
		[1] = {id = 1,name = gLanguageCsv.rankAward,showRightIndex = true,view = self.rankAwardPanel},
		[2] = {id = 2,name = gLanguageCsv.fightAward,showRightIndex = true,view = self.fightAwardPanel},
		[3] = {id = 3,name = gLanguageCsv.fightRankItem,showRightIndex = true,view = self.rankPanel},
		[4] = {id = 4,name = gLanguageCsv.spriteShow,showRightIndex = false},
	}

	local fightrankaward = {}
	for k,v in orderCsvPairs(csv.yunying.fightrankaward) do
		if v.huodongID == self.cfg.huodongID then
			table.insert(fightrankaward,k,v)
		end
	end
	local fightpointaward = {}
	for k,v in orderCsvPairs(csv.yunying.fightpointaward) do
		if v.huodongID == self.cfg.huodongID then
			table.insert(fightpointaward,k,v)
		end
	end

	self.subViews = {}
	self.tabDatas = idlers.newWithMap(viewDatas)						-- 标签页
	self.rankReward = fightrankaward									-- 排名奖励
	self.fightAward = fightpointaward									-- 战力奖励
	self.fightRank = idlers.new()										-- 战力排名
	self.tabChooseId = idler.new(1)										-- 标签页选择
	self.rankIdler = idler.new()										-- 自身排名
	self.fightPoint = gGameModel.role:getIdler("top6_fighting_point")	-- 自身战力

	self:resetTimeLabel()

	idlereasy.when(self.fightPoint, function (_, fightPoint)
		self.curFightPoint:text(fightPoint)
	end)
	idlereasy.when(self.rankIdler, function (_, rank)
		local show = rank and true or false
		self.rankFirst:visible(show)
		self.rankLast:visible(show)

		if not show then
			self.rankNumber:text(gLanguageCsv.noRank)
			adapt.oneLinePos(self.randHead,self.rankNumber,cc.p(20,0))
		else
			self.rankNumber:text(rank)
			adapt.oneLinePos(self.randHead, {self.rankFirst, self.rankNumber, self.rankLast}, {cc.p(20,0), cc.p(0,0), cc.p(0,0)})
		end
	end)

	self.tabChooseId:addListener(function(val, oldval)
		if oldval then
			self.tabDatas:atproxy(oldval).selected = false
			if viewDatas[oldval].view then
				viewDatas[oldval].view:hide()
			end
		end

		if val then
			self.tabDatas:atproxy(val).selected = true
			local viewData = viewDatas[val]
			if viewData then
				if viewData.view then
					viewData.view:show()
				end
				local showRightIndex = viewData.showRightIndex
				self.spritePanel:visible(not showRightIndex)
				self.mainPanel:visible(showRightIndex)
			end
		end
	end)

	local textLabel = self.ruleBtn:get("text")
	text.addEffect(textLabel, {
		outline = {color =  cc.c4b(46, 168, 229, 255)},
	})

	local str = gLanguageCsv.fightRankBottomRichText
	local richtext = rich.createByStr(string.format(str, "#C0x5b545b#","#C0x0f9932#","#C0x5b545b#","#C0xff794c#","#C0x5b545b#"), 32)
	self.richText:add(richtext):text("")
	richtext:anchorPoint(0,0.5):xy(0,0)

	Dialog.onCreate(self, {blackType = 1})
end

-- 刷新排行榜信息
function ActivityFightRankView:updateRankData(cb)
	gGameApp:requestServer("/game/yy/fightrank/get", function(tb)
		self.fightRank:update(tb.view.rank)
		self.endTime = tb.view.end_time
		self:resetTimeLabel()

		if cb then
			cb()
		end
	end,self.activityId)
end

-- 点击函数
function ActivityFightRankView:onTabClick(list, id, data)
	if id == 3 then
		-- 排行榜要从服务器获取
		self:updateRankData(function ()
			self.tabChooseId:set(id)
		end)
	else
		self.tabChooseId:set(id)
	end
end

-- 重置活动名称、剩余时间等标题栏
function ActivityFightRankView:resetTimeLabel()
	-- do return end
	local uiTime = self.timeLabel				-- 时分秒控件
	local uiDay = self.dayLabel					-- 日控件

	text.addEffect(uiTime, {
		outline = {color =  cc.c4b(255, 129, 38, 255)},
	})
	-- 计算前一天 的 21点 30 分
	if not self.endTime then
		self.endTime = time.getNumTimestamp(self.cfg.endDate,21,30) - 24*60*60
	end

	local function setLabel()
		local countdown = self.endTime - time.getTime()
		if countdown <= 0 then
			uiTime:text(gLanguageCsv.activityOver)
			self.dayStr:set("00")
			return false
		end
		local dt = time.getCutDown(countdown)
		self.dayStr:set(tostring(dt.day))
		uiTime:text(string.format(gLanguageCsv.fightRankTimeFMT,dt.day,dt.hour,dt.min,dt.sec))
		return true
	end

	setLabel()

	local scheduleTag = 1-- 定时器tag
	-- 移除上次的刷新定时器
	self:enableSchedule():unSchedule(scheduleTag)
	self:schedule(function()
		if not setLabel() then
			return false
		end
	end, 1, 1, scheduleTag)-- 1秒钟刷新一次
end

-- 显示规则文本
function ActivityFightRankView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ActivityFightRankView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			-- item:get("text"):text(csv.note[106])
			item:get("text"):text(gLanguageCsv.fightRankRuleTitle)
		end),
		c.noteText(55001, 55005),
	}
	return context
end

return ActivityFightRankView