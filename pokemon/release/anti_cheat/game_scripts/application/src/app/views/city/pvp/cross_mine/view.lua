-- @date 2020-12-22
-- @desc 跨服资源战主界面

local ViewBase = cc.load("mvc").ViewBase
local CrossMineView = class("CrossMineView", ViewBase)

local RANKCOLOR = {
	[1] = {
		color = cc.c3b(255, 214, 50),
		outline = cc.c3b(225, 140, 18),
	},
	[2] = {
		color = cc.c3b(78, 197, 253),
		outline = cc.c3b(97, 143, 179),
	},
	[3] = {
		color = cc.c3b(255, 176, 137),
		outline = cc.c3b(214, 135, 103),
	}
}

local SCENE_TYPE = {
	showNoServer = 1,
	showServer = 2,
	showStreet = 3,
	showOver = 4,
}

CrossMineView.RESOURCE_FILENAME = "cross_mine.json"
CrossMineView.RESOURCE_BINDING = {
	["bgPanel"] = "bgPanel",
	["bgPanel.bgPanel1"] = "bgPanel1",
	["bgPanel.bgPanel1.car"] = "car",
	["bgPanel.bgPanel1.img3"] = "billBoard",
	["bgPanel.bgPanel1.img4"] = "grass",
	["viewPanel"] = "viewPanel",
	["noServerPanel"] = "noServerPanel",
	["noServerPanel.textNote"] = {
		varname = "noServerTextNote",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.BLACK}},
		},
	},
	["noServerPanel.textTime"] = {
		varname = "noTextTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.BLACK}},
		},
	},
	["noServerPanel.label"] = {
		varname = "noServerLabel",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.BLACK}},
		},
	},
	["serverPanel"] = "serverPanel",
	["serverPanel.textNote"] = {
		varname = "serverTextNote",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.BLACK}},
		},
	},
	["serverPanel.textTime"] = {
		varname = "textTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.BLACK}},
		},
	},
	["serverPanel.title"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(47, 43, 47)}},
		},
	},
	["serverPanel.item"] = "serverItem",
	["serverPanel.subList"] = "serverSubList",
	["serverPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("servers"),
				item = bindHelper.self("serverSubList"),
				cell = bindHelper.self("serverItem"),
				columnSize = 4,
				onCell = function(list, node, k, v)
					node:get("textServer"):text(string.format(gLanguageCsv.brackets, getServerArea(v, nil, true)))
				end,
			},
		},
	},
	["overPanel"] = "overPanel",
	["overPanel.pos1"] = "overPos1",
	["overPanel.pos2"] = "overPos2",
	["overPanel.pos3"] = "overPos3",
	["overPanel.item"] = "userItem",
	["overPanel.item.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(91, 84, 91)}},
		},
	},
	["overPanel.item.levelAndZone"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(91, 84, 91)}},
		},
	},
	["overPanel.rightPanel.item"] = "rightItem",
	["overPanel.rightPanel.listview"] = {
		varname = "overList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("serversData"),
				item = bindHelper.self("rightItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:get("no"):text(k)
					if k < 4 then
						text.addEffect(node:get("no"), {color = RANKCOLOR[k].color, outline = {color = RANKCOLOR[k].outline}})
					end
					node:get("zone"):text(string.format("%s %s",getServerArea(v.servKey, nil, true), getServerName(v.servKey, true)))
					node:get("score"):text(v.score)
					node:get("selfBg"):visible(isCurServerContainMerge(v.servKey))
				end,
			},
		},
	},
	-- 底部按钮
	["downPanel.blessing"] = {
		varname = "blessing",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBlessingClick")},
		},
	},
	["downPanel.blessing.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.rule"] = {
		varname = "rulePanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")},
		},
	},
	["downPanel.rule.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.defend"] = {
		varname = "defend",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDefendArrayClick")},
		},
	},
	["downPanel.defend.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.rank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankClick")},
		},
	},
	["downPanel.rank.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.record"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRecordClick")},
		},
	},
	["downPanel.record.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["downPanel.shop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShopClick")},
		},
	},
	["downPanel.shop.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
}

function CrossMineView:onCreate(params)
	local params = params or {}
	self.isShowBoss = params.isShowBoss or false
	self.isFirst = true
	gGameUI.topuiManager:createView("cross_mine", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.crossMine, subTitle = "ASSIGNTNENT", sign = true})
	self:initModel()
	self.overPos = {}
	table.insert(self.overPos, self.overPos1)
	table.insert(self.overPos, self.overPos2)
	table.insert(self.overPos, self.overPos3)

	self.subView = {}
	self.subViewFunc = {
		street = function(...)
			return gGameUI:createView("city.pvp.cross_mine.street", self.viewPanel):init(self, {streetShowType = self.streetShowType,
			isShowBoss = self.isShowBoss,
			downPanelPosX = self.downPanelPosX,
			blessingCallBack = self:createHandler("blessingCallBack")}, ...)
		end,
	}
	idlereasy.when(self.round, function(_, round)
		local showFirstBg = false
		local viewName = nil
		if round == "start" or round == "over" then
			self.noServerPanel:hide()
			self.serverPanel:hide()
			self.overPanel:hide()
			self.bgPanel1:hide()
			self.blessing:show()
			self.defend:show()
			viewName = "street"
			self:updateStartOrOverTime(round)
		elseif round == "closed" then
			local state = self:getCloseState()
			self.blessing:hide()
			self.defend:hide()
			self:initSquare(state)
			if state == "showResult" then
				self.noServerPanel:hide()
				self.serverPanel:hide()
				self.overPanel:show()
				performWithDelay(self, function()
					self:initOverPanel()
				end, 0)
			elseif state == "showService" then
				self.noServerPanel:hide()
				self.serverPanel:show()
				self.overPanel:hide()
				self:initServerPanel(true)
			else
				self.noServerPanel:show()
				self.serverPanel:hide()
				self.overPanel:hide()
				self:initServerPanel()
			end
		end
		self:showSubView(viewName)
	end)
end

function CrossMineView:initModel()
	self.round = gGameModel.cross_mine:getIdler("round")
	self.startDate = gGameModel.cross_mine:getIdler("date")
	self.serverPoints = gGameModel.cross_mine:getIdler("serverPoints")
	self.servers = idlers.newWithMap({})
	self.serversData = idlers.new()
	self.csvID = gGameModel.cross_mine:read("csvID")
	self.streetShowType = idler.new(self.saveShowStreet or 99)
	self.downPanelPosX = idler.new(self.saveDownPanelPosX or nil)
end

function CrossMineView:initOverPanel()
	local datas = {}
	for k, val in pairs(self.serverPoints:read()) do
		table.insert(datas, {servKey = k, score = val})
	end
	table.sort(datas, function (a, b)
		return a.score > b.score
	end)
	self.serversData:update(datas)
	-- 刷新最高3个人
	local rankTable = {}
	for k, val in pairs(gGameModel.cross_mine:read("top10")) do
		table.insert(rankTable, val)
	end
	table.sort(rankTable, function(a, b)
		return a.rank < b.rank
	end)
	for i=1, 3 do
		self.overPos[i]:removeAllChildren()
		local data = rankTable[i]
		if data then
			local item = self.userItem:clone():show()
			local size = item:size()
			item:get("name"):text(data.name)
			item:get("levelAndZone"):text(string.format("Lv.%d [%s]", data.level, getServerArea(data.game_key)))
			item:get("power"):text(data.fighting_point)
			text.addEffect(item:get("power"), {outline = {color = cc.c3b(91, 84, 91), size = 4}})
			if data.vip > 0 then
				item:get("vip"):texture(ui.VIP_ICON[data.vip]):show()
			end
			item:get("imgNo"):texture("city/pvp/cross_mine/txt_"..i..".png")
			item:get("imgNo"):y(i==1 and 281 or 273)
			item:get("imgDi"):scale(i==1 and 1.0 or 0.9)
			item:xy(0, 0)
			item:addTo(self.overPos[i])
			adapt.oneLineCenterPos(cc.p(size.width/2, item:get("imgPower"):y()), {item:get("imgPower"), item:get("power")}, cc.p(10, 0))
			adapt.oneLineCenterPos(cc.p(size.width/2, item:get("name"):y()), {item:get("name"), item:get("vip")}, cc.p(20, 0))

			-- 添加角色
			local cfg = gRoleFigureCsv[data.figure]
			widget.addAnimationByKey(item, cfg.crossMineResSpine, "spine", "standby_loop", 1)
				:xy(item:width()/2, i == 1 and 400 or 380)
				:scale(2)
				:play("standby_loop")

			if data.title > 0 then
				bind.extend(self, item, {
					event = "extend",
					class = "role_title",
					props = {
						data = data.title,
						onNode = function(node)
							node:xy(size.width / 2, size.height - (i == 1 and 100 or 160))
								:z(5)
						end
					}
				})
			end
		end
	end
end

function CrossMineView:initSquare(state)
	self.bgPanel1:show()
	if state == "showResult" then
		self.billBoard:hide()
		self.car:show()
		self.car:y(1765)
		self.grass:y(1765)
		self.bgPanel1:x(550)
	else
		self.billBoard:show()
		self.car:hide()
		self.car:y(1440)
		self.grass:y(1440)
		self.bgPanel1:x(1560)
	end
	widget.addAnimationByKey(self.bgPanel1:get("pqNode"), "crossmine/penquan.skel", "penquan", "effect_loop", 1)
		:xy(0, 0)
		:play("effect_loop")
end

function CrossMineView:initServerPanel(isShowServer)
	if self.date then
		local startDate = time.getNumTimestamp(self.date)
		local t1 = time.getDate(startDate)
		local strStartTime = string.formatex(gLanguageCsv.timeMonthDay, {month = t1.month, day = t1.day}) .. dataEasy.getTimeStrByKey("crossMine", "mineStart")

		local endTime = time.getNumTimestamp(self.date) + 2 * 24 * 60 * 60
		local t2 = time.getDate(endTime)
		local strEndTime = string.formatex(gLanguageCsv.timeMonthDay, {month = t2.month, day = t2.day}) .. dataEasy.getTimeStrByKey("crossMine", "mineEnd")

		local time1 = self.noTextTime
		local textNote = self.noServerTextNote
		if isShowServer then
			time1 = self.textTime
			textNote = self.serverTextNote
		end
		time1:text(strStartTime .."--" .. strEndTime)
		if matchLanguage({"en"}) then
			textNote:text(gLanguageCsv.crossCraftBattleCountdown)
			local function updateLeftTimeStr()
				local curTb = time.getNowDate()
				local curTime = time.getTimestamp(curTb)
				local startHour, startmin = dataEasy.getTimeStrByKey("crossMine", "mineStart", true)
				t1.hour = startHour
				t1.min = startmin
				t1.sec = 0
				local startTime = time.getTimestamp(t1)
				local delta = startTime - curTime
				if delta < 1 then
					return true
				end
				time1:text(time.getCutDown(delta).str)
				return false
			end
			self:enableSchedule():unSchedule(20210519)
			self:enableSchedule()
				:schedule(function(dt)
					updateLeftTimeStr()
				end, 1, 0, 20210519)
		end
		adapt.oneLinePos(textNote, time1, cc.p(40, 0))
	else
		self.noTextTime:hide()
		self.noServerTextNote:hide()
	end
end

function CrossMineView:getCloseState()
	local id = dataEasy.getCrossServiceData("crossmine")
	if id then
		local cfg = csv.cross.service[id]
		self.date = cfg.date
		local startTime = time.getNumTimestamp(cfg.date, 5) - 1 * 24 * 3600 -- 下一场比赛开始前一天
		local endTime = time.getNumTimestamp(cfg.date, dataEasy.getTimeStrByKey("crossMine", "mineStart", true))
		-- 到点服务器状态还没变的，继续显示匹配服 2 天开赛中
		if time.getTime() >= startTime and time.getTime() < endTime + 24 * 3600 then
			self.servers:update(getMergeServers(cfg.servers))
			self:countStates("closed", endTime - time.getTime())
			self.csvID = id
			return "showService"
		end
	end
	if self.serverPoints:read() and itertools.size(self.serverPoints:read()) > 0 then
		return "showResult"
	end
end

function CrossMineView:countStates(states, time)
	local round = self.round:read()
	if round ~= states then
		return
	end
	if self.isFirst then
		self.isFirst = false
		if time <= 0 then
			gGameApp:requestServer("/game/cross/mine/main", functools.handler(self, "countStates", states, 10))
			return
		end
	end
	if time < 0 then
		time = 10
	end
	performWithDelay(self, function()
		gGameApp:requestServer("/game/cross/mine/main", functools.handler(self, "countStates", states, 10))
	end, time)
end

function CrossMineView:showSubView(viewName, ...)
	if self.subView.name ~= viewName then
		if self.subView.view then
			self.subView.view:onClose()
		end
		if viewName == nil then
			self.subView = {}
		else
			self.subView = {
				name = viewName,
				view = self.subViewFunc[viewName](...)
			}
		end
	end
end

--祝福
function CrossMineView:onBlessingClick()
	gGameUI:stackUI("city.pvp.cross_mine.wish")
end

--规则
function CrossMineView:onRuleClick()
	if not self.rulePanel:get("ruleItem") then
		ccui.Layout:create():hide():addTo(self.rulePanel, 1, "ruleItem")
	end
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function CrossMineView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(154),
		c.noteText(113001, 113019),
		c.noteText(155),
		c.noteText(113020, 113039),
		c.noteText(156),
		c.noteText(113040, 113059),
		c.noteText(157),
		c.noteText(113080, 113099),
	}
	if self.round:read() == "closed" then
		table.insert(context, 2, gLanguageCsv.crossMineRoleRankCloseTips)
		return context
	end
	local role = gGameModel.cross_mine:read("role")
	if role and role.rank then
		local endH, endM = dataEasy.getTimeStrByKey("crossMine", "mineStart", true) -- 获取开始时间
		local myRank = role.rank
		table.insert(context, 2, string.format(gLanguageCsv.crossMineRoleRankTips, myRank))
		table.insert(context, 3, c.clone(view.awardItem, function(item)
			local version = csv.cross.service[self.csvID].version
			local childs = item:multiget("text", "list")
			childs.text:text("")
			local rank = 0
			for k, v in orderCsvPairs(csv.cross.mine.role_award) do
				if v.version == version then
					if myRank > rank and myRank <= v.rankMax then
						local award = v.dayAward
						-- 判断天数，最后一天显示
						local lastDayBeginTime = time.getNumTimestamp(self.startDate:read(), endH, endM) + 2 * 24 * 60 * 60
						if time.getTime() > lastDayBeginTime then
							award = v.endAward
						end
						uiEasy.createItemsToList(view, childs.list, award)
						break
					end
					rank = v.rankMax
				end
			end
		end))
	end
	return context
end

-- 布阵
function CrossMineView:onDefendArrayClick()
	if self.round:read() == "start" or self.round:read() == "over" then
		gGameUI:stackUI("city.pvp.cross_mine.embattle", nil, {full = true})
	else
		gGameUI:showTip(gLanguageCsv.crossMineNotStart)
	end
end

-- 排行榜
function CrossMineView:onRankClick()
	if self.round:read() == "start" or self.round:read() == "over"  or self:getCloseState() == "showResult" then
		gGameApp:requestServer("/game/cross/mine/rank", function (tb)
			local fightDatas = tb.view
			gGameApp:requestServer("/game/cross/mine/rank", function (tb)
				gGameUI:stackUI("city.pvp.cross_mine.rank", nil, nil,fightDatas, tb.view)
			end, "feed", 0, 11)
		end, "role",0, 11)
	else
		gGameUI:showTip(gLanguageCsv.crossArenaNoRank)
	end
end

-- 回放
function CrossMineView:onRecordClick()
	if self.round:read() == "start" or self.round:read() == "over"  or self:getCloseState() == "showResult" then
		gGameUI:stackUI("city.pvp.cross_mine.combat_record", nil, nil ,{blessingCb = self:createHandler("blessingCallBack")})
	else
		gGameUI:showTip(gLanguageCsv.crossMineNotStart)
	end
end

-- 商店
function CrossMineView:onShopClick()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fixshop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.CROSS_MINE_SHOP)
		end)
	end
end

function CrossMineView:updateStartOrOverTime(round)
	if round == "start" then
		local endTime = time.getNumTimestamp(time.getTodayStrInClock(0), dataEasy.getTimeStrByKey("crossMine", "mineEnd", true))
		local cutdown = endTime - time.getTime()
		self:countStates("start", cutdown)
	elseif round == "over" then
		local endTime =  time.getNumTimestamp(time.getTodayStrInClock(0), dataEasy.getTimeStrByKey("crossMine", "mineStart", true))
		local nowTime = time.getTime()
		if nowTime > time.getNumTimestamp(time.getTodayStrInClock(0), dataEasy.getTimeStrByKey("crossMine", "mineEnd", true)) then
			endTime = time.getNumTimestamp(time.getTodayStrInClock(0) + 1, dataEasy.getTimeStrByKey("crossMine", "mineStart", true))
		end
		local cutdown = endTime - nowTime
		self:countStates("over", cutdown)
	end
end

function CrossMineView:onCleanup()
	self.saveShowStreet = self.streetShowType:read()
	self.saveDownPanelPosX = self.downPanelPosX:read()
	ViewBase.onCleanup(self)
end

function CrossMineView:blessingCallBack(data, enemy, isRevenge)
	gGameUI:stackUI("city.pvp.cross_mine.lineup_adjust", nil, {full = true}, data, {fightCb = self:createHandler("startFighting", enemy, isRevenge), isRevenge = isRevenge})
end

--battleCards 当前阵容
function CrossMineView:startFighting(vData, isRevenge, view, battleCards)
	local role = gGameModel.cross_mine:read("role")
	local myRank = role.rank
	-- 防止schedule中有网络请求行为
	self:disableSchedule()
	local battleType = "rob"
	if isRevenge then
		battleType = "revenge"
	end
	battleEntrance.battleRequest("/game/cross/mine/battle/start", battleType, myRank, vData.rank,
			vData.roleID, vData.recordID)
		:onStartOK(function(data)
			if view then
				view:onCloseSelf()
				view = nil
			end
		end)
		:onResult(function(data, results)
			local waveReusult = clone(results.waveResult)
			if results.result == "win" then
				table.insert(waveReusult, 1)
			else
				table.insert(waveReusult, 2)
			end
			data.waveReusult = waveReusult
		end)
		:run()
		:show()
end

return CrossMineView