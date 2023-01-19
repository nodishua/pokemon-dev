-- @date 2020-12-23
-- @desc 跨服资源战主街区

local ViewBase = cc.load("mvc").ViewBase
local StreetView = class("StreetView", ViewBase)

local SHOW_STREET = {
	NORMAL = 1,
	TOP10 = 2,
}

local ITEM_WIDTH = {
	[1] = 520,
	[2] = 692,
}

-- 移动上下左右离边界值的间距 [1]左右，[2]上下
local WIDTH_HEIGHT_MAX_LEFT_OVER = {
	[1] = {150, 150},
	[2] = {50, 20},
}
--[[
	yMax: 400,
	[1]走动随机距离x,y
	[2]转身站立时间随机值
	[3]人物走动速度m/s
]]
local SELF_MOVE_RANDOM = {
	[1] = {
		x = {1600, 2000},
		y = {30, 200},
	},
	[2] = {1.0, 3.0},
	[3] = {200, 200},
}

local STREET_BG_RES = {
	START = "city/pvp/cross_mine/bg/img_jz_bg1.png",
	END = "city/pvp/cross_mine/bg/img_jz_bg2.png",
	NORMAL = {
		[1] = "city/pvp/cross_mine/bg/img_ptjz_bg1.png",
		[2] = "city/pvp/cross_mine/bg/img_ptjz_bg2.png",
	},
	TOP10 = "city/pvp/cross_mine/bg/img_gjjz_bg.png",
}

local function setBuffCountdown(view, countdown, uiTime, params)
	local tag = params.tag or 1
	view:enableSchedule():unSchedule(tag)

	countdown = math.max(countdown, 0)
	if countdown == 0 then return end

	bind.extend(view, uiTime, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = tag,
			strFunc = function(t)
				return t.str
			end,
			callFunc = function()
			end,
			endFunc = function()
				local endTime = params.cfg.buffTime*60 + params.info.time
				local countdown = endTime - time.getTime()
				if countdown > 0 then
					performWithDelay(view, function()
						setBuffCountdown(view, countdown, uiTime, params)
					end, 1)
				else
					view:enableSchedule():unSchedule(tag)
				end
			end
		}
	})
end

StreetView.RESOURCE_FILENAME = "cross_mine_street.json"
StreetView.RESOURCE_BINDING = {
	["bgPanel"] = "bgPanel",
	["bgPanel.normalPanel"] = "normalPanel",
	["bgPanel.normalPanel.bgPanel"] = "normalBgPanel",
	["bgPanel.normalPanel.downPanel"] = "bgDownPanel",
	["bgPanel.normalPanel.downPanel.bossItem"] = "bossItem",
	["bgPanel.normalPanel.downPanel.bossItem.timePanel.time"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(47, 43, 47), size = 4}},
		},
	},
	["bgPanel.normalPanel.downPanel.bossItem.btnChallenge"] = {
		varname = "btnBossChallenge",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBossChallenge")}
		},
	},
	["bgPanel.normalPanel.listView"] = {
		varname = "normalList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showDatas"),
				item = bindHelper.self("normalItem"),
				itemAction = {isAction = false},
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:get("panel"):multiget("infoPanel", "empty", "btnBidding", "imgSelf", "no", "noBg")
					bind.touch(list, childs.btnBidding, {methods = {ended = functools.partial(list.blessingClick, k, v)}})
					bind.touch(list, node:get("touchPanel"), {methods = {ended = functools.partial(list.clickCell, k, v)}})
					local bgRes = ""
					if v.rank > 10 then
						node:width(ITEM_WIDTH[1])
						childs.noBg:show()
						childs.no:show()
						childs.no:text(v.rank)
						text.addEffect(childs.no, {outline = {color = cc.c3b(47, 43, 47)}})
						local len = itertools.size(csv.cross.mine.building[11].res)
						bgRes = csv.cross.mine.building[11].res[(v.rank-10)%len+1]
					else
						node:width(ITEM_WIDTH[2])
						bgRes = csv.cross.mine.building[v.rank].res[1]
						childs.noBg:show()
						childs.no:hide()
						childs.noBg:texture("city/pvp/cross_mine/icon_kfzy_ph"..v.rank..".png")
					end
					childs.btnBidding:visible(not v.isSelf)
					childs.imgSelf:visible(v.isSelf)
					node:get("touchPanel"):width(node:width())
					node:get("touchPanel"):x(node:width()/2)
					node:get("panel"):x(node:width()/2)
					node:get("bgPanel"):x(node:width()/2)
					local goldPanel = node:get("goldPanel")
					goldPanel:x(node:width()/2)
					goldPanel:hide()
					node:get("bgPanel"):removeAllChildren()
					local img = ccui.ImageView:create(bgRes)
						:anchorPoint(0.5, 0)
						:xy(node:get("bgPanel"):width()/2, 0)
						:addTo(node:get("bgPanel"))
						:scale(2)

					if v.empty then
						childs.btnBidding:hide()
						childs.imgSelf:hide()
						childs.infoPanel:hide()
						childs.empty:show()
					else
						childs.infoPanel:show()
						childs.empty:hide()
						childs.infoPanel:get("name"):text(cfg.name)
						childs.infoPanel:get("score"):text(cfg.fighting_point)
						childs.infoPanel:get("zone"):text(string.format("[%s]",getServerArea(cfg.game_key)))
						adapt.oneLineCenterPos(cc.p(childs.infoPanel:width()/2, childs.infoPanel:get("score"):y()), {childs.infoPanel:get("imgPower"), childs.infoPanel:get("score")}, cc.p(6, 0))
					end
					if v.goldAction then
						goldPanel:show()
						local gold = goldPanel:get("gold")
						gold:text("+"..mathEasy.getPreciseDecimal(cfg.speed), 1)
						text.addEffect(gold, {outline = {color = cc.c3b(47, 43, 47)}})
						gold:xy(30, -25)
						gold:opacity(255)
						gold:runAction(cc.Spawn:create(
							cc.MoveTo:create(2.33, cc.p(30, 55)),
							cc.Sequence:create(
								cc.DelayTime:create(2.0),
								cc.FadeOut:create(0.33))
							))
						goldPanel:runAction(cc.Sequence:create(
							cc.ScaleTo:create(0.1, 1.2),
							cc.ScaleTo:create(0.1, 0.95),
							cc.ScaleTo:create(0.1, 1.0)))
						-- 飘金币动画
						local spine = widget.addAnimationByKey(goldPanel, "crossmine/jinbi.skel", "spine", "effect_loop", 1)
						spine:xy(-20, 0)
						spine:play("effect_loop")
						spine:runAction(cc.Sequence:create(
							cc.MoveTo:create(2.33, cc.p(-20, 80))))
						spine:setSpriteEventHandler(function(event, eventArgs)
							goldPanel:hide()
						end, sp.EventType.ANIMATION_COMPLETE)
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onInfoClick"),
				blessingClick = bindHelper.self("onBlessingClick"),
			},
		},
	},
	["bgPanel.squarePanel"] = "squarePanel",
	["bgPanel.squarePanel.bgPanel"] = "squareBg",
	["bgPanel.squarePanel.bgPanel.btnBlessing"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBlessingWishClick")}
		},
	},
	["normalItem"] = "normalItem",
	["downPanel"] = "downPanel",
	["npcItem"] = "npcItem",
	["npcItem.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(47, 43, 47)}},
		},
	},
	["downPanel.restLabel"] = {
		varname = "restLabel",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(54, 50, 54), size = 3}},
		},
	},
	["downPanel.startPanel"] = "startPanel",
	["downPanel.startPanel.btnRefresh"] = {
		varname = "btnRefresh",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRefresh")}
		},
	},
	["downPanel.startPanel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnBiddingAdd")}
		},
	},
	["downPanel.startPanel.biddingLabel"] = {
		varname = "biddingLabel",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(54, 50, 54)}},
		},
	},
	["downPanel.startPanel.findLabel"] = {
		varname = "findLabel",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(54, 50, 54)}},
		},
	},
	["downPanel.startPanel.biddingCount"] = {
		varname = "biddingCount",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(54, 50, 54)}},
		},
	},
	["downPanel.startPanel.findCount"] = {
		varname = "findCount",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c3b(54, 50, 54)}},
		},
	},
	["downPanel.startPanel.icon"] = "startPanelIcon",
	["leftPanel"] = "leftPanel",
	["leftPanel.btnServerRank"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onServerRank")}
		},
	},
	["leftPanel.btnServerRank.label"] = {
		binds = {
			event = 'effect',
			data = {outline = {color = cc.c3b(47, 43, 47)}}
		}
	},
	["leftPanel.btnChange"] = {
		varname = "btnChange",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onChange")}
			},
		},
	},
	["leftPanel.btnChange.img"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("btnChangeImg")
		}
	},
	["leftPanel.btnChange.bossTip"] = {
		varname = "bossTip",
		binds = {
			event = "visible",
			idler = bindHelper.self("showBossRedHint")
		}
	},
	["leftPanel.arrowPanel"] = "arrowPanel",
	["leftPanel.buffPanel"] = "buffPanel",
	["leftPanel.buffPanel.item"] = "buffItem",
	["leftPanel.buffPanel.listView"] = {
		varname = "buffListView",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("buffDatas"),
				item = bindHelper.self("buffItem"),
				itemAction = {isAction = false},
				onItem = function(list, node, k, v)
					local img = node:get("img")
					local time = node:get("time")
					img:texture(v.cfg.buffIcon)
					text.addEffect(time, {outline = {color = cc.c3b(52, 5, 11)}})
					bind.touch(list, node, {methods = {ended = functools.partial(list.buffClickCell, k, v)}})
					setBuffCountdown(list, v.time, time, {tag = v.info.csv_id, info = v.info, cfg = v.cfg})
				end,
			},
			handlers = {
				buffClickCell = bindHelper.self("onBuffClick"),
			},
		}
	},
}

function StreetView:onCreate(parent, params)
	self.isShowBoss = params.isShowBoss
	self.streetShowType = params.streetShowType
	if self.isShowBoss then
		self.streetShowType:set(SHOW_STREET.NORMAL)
	end
	self.downPanelPosX = params.downPanelPosX
	self.blessingCallBack = params.blessingCallBack
	self.parent = parent
	self:initModel()
	self:initStreet()
	self:initSquare()
	self:initEventTimes()
	self:initNpc()

	idlereasy.when(self.round, function(_, round)
		self.restLabel:visible(round == "over")
		self.startPanel:visible(round == "start")
		if matchLanguage({"en"}) and round == "over" then
			self:updateOverLabel()
		end
	end)

	self.showStreet:addListener(function(val, oldval)
		if val == nil or (val ~= SHOW_STREET.NORMAL and val ~= SHOW_STREET.TOP10) then return end
		if #self.bgListTable == 2 then
			local bgRes = STREET_BG_RES.TOP10
			if val == SHOW_STREET.NORMAL then
				local width = self:newBg(STREET_BG_RES.NORMAL[1], "bg")
				bgRes = STREET_BG_RES.NORMAL[2]
			end
			for i=1, 5 do
				local width = self:newBg(bgRes, "bg"..i)
			end
		else
			if val == SHOW_STREET.TOP10 and #self.bgListTable == 8 then
				self.bgListTable[2]:hide()
				table.remove(self.bgListTable, 2)
			elseif val == SHOW_STREET.NORMAL then
				local bg = self.normalBgPanel:get("bg")
				if bg then
					bg:show()
					table.insert(self.bgListTable, 2, bg)
				else
					local width = self:newBg(STREET_BG_RES.NORMAL[1], "bg", 2)
				end
			end
			for i=1, 5 do
				local bg = self.normalBgPanel:get("bg"..i)
				bg:texture(val == SHOW_STREET.TOP10 and STREET_BG_RES.TOP10 or STREET_BG_RES.NORMAL[2])
			end
		end
		local ListWidth = val == SHOW_STREET.NORMAL and 11*ITEM_WIDTH[1] or 10*ITEM_WIDTH[2]
		local PanelWidth = self.stratWidth + self.endWidth + ListWidth
		local befortImg = nil
		-- -- 背景拼接
		for k, img in ipairs(self.bgListTable) do
			if befortImg then
				adapt.oneLinePos(befortImg, img)
			end
			befortImg = img
		end
		self.normalPanel:width(PanelWidth)
		self.normalList:width(ListWidth)
		self.bgDownPanel:width(PanelWidth)

		self:updateShowDatas(val)
		self.bgPanel:refreshView()

		self.downPanelAnctionPosX = (ITEM_WIDTH[val] + self.stratWidth + self.squarePanel:width() - self.bgPanel:width())*(-1)

		-- boss切换
		self.updateBoss:set(self.updateBoss:read() == 1 and 0 or 1)

		self:refreshListPos(PanelWidth)
		self.streetShowType:set(val)
	end)

	idlereasy.any({self.top10, self.enemies}, function (_, top10, enemies)
		self:updateShowDatas(self.showStreet:read())
	end)

	idlereasy.any({self.refreshTimes, self.robTimes, self.robBuyTimes}, function (_, refreshTimes, robTimes, robBuyTimes)
		local sortTable = {}
		table.insert(sortTable, self.btnRefresh)
		-- 搜寻次数
		local findTxt = gLanguageCsv.free
		local findColor = cc.c3b(118, 204, 54)
		local freshCost = math.min(refreshTimes+1, itertools.size(gCostCsv.cross_mine_enemy_fresh_cost))
		if gCostCsv.cross_mine_enemy_fresh_cost[freshCost] > 0 then
			findTxt = gCostCsv.cross_mine_enemy_fresh_cost[freshCost]
			findColor = cc.c3b(253, 211, 13)
			self.startPanelIcon:show()
			table.insert(sortTable, self.startPanelIcon)
		else
			self.startPanelIcon:hide()
		end
		self.findCount:text(findTxt)
		self.findCount:color(findColor)
		table.insert(sortTable, self.findCount)
		table.insert(sortTable, self.findLabel)
		-- 竞标次数
		local maxFree = csv.cross.mine.base[1].robFreeTimes
		local canBidding = maxFree + robBuyTimes - robTimes
		canBidding = math.max(canBidding, 0)
		self.leftTimes = canBidding
		local biddingTxt = string.format("%d/%d", canBidding, maxFree)
		local biddingColor = cc.c3b(118, 204, 54)
		if canBidding == 0 then
			biddingColor = cc.c3b(255, 252, 237)
			self.btnAdd:show()
			table.insert(sortTable, self.btnAdd)
		else
			self.btnAdd:hide()
		end
		self.biddingCount:text(biddingTxt)
		self.biddingCount:color(biddingColor)
		table.insert(sortTable, self.biddingCount)
		table.insert(sortTable, self.biddingLabel)
		local node = nil
		for _, val in ipairs(sortTable) do
			if node then
				adapt.oneLinePos(node, val, cc.p(20, 0), "right")
			end
			node = val
		end
	end)

	idlereasy.any({self.boss, self.updateBoss}, function (_, boss, updateBoss)
		-- boss是否可以多个 暂时只取第一个
		self.showBossRedHint:set(false)
		local bossDatas = {}
		for id, info in pairs(boss) do
			table.insert(bossDatas, {bossID = id, info = info})
		end
		table.sort(bossDatas, function(a, b)
			return a.info.open_time >  b.info.open_time
		end)
		self.showBoss = 0
		self.arrowPanel:hide()
		self.bossItem:hide()
		if #bossDatas == 0 then
			return
		end
		local cfg = csv.cross.mine.boss[bossDatas[1].info.csv_id]
		local endTime = cfg.duration*60 + bossDatas[1].info.open_time

		local countDownTime = endTime - time.getTime()
		if countDownTime <= 0 then
			return
		end
		local function showBoss()
			self.bossItem:show()
			self.bossItem:get("bgPanel"):removeAllChildren()
			self:updateBossSpine(bossDatas[1].info.figure_id)
			self:setBossCountdown(countDownTime, self.bossItem:get("timePanel.time"))
		end
		-- boss击杀判断
		if bossDatas[1].info.kill_role then
			if self.showStreet:read() ~= SHOW_STREET.TOP10 then
				showBoss()
			end
			return
		end
		if self.showStreet:read() == SHOW_STREET.TOP10 then
			self.showBossRedHint:set(true)
			return
		end
		self.showBoss = 1
		local container = self.bgPanel:getInnerContainer()
		self.arrowPanel:visible(container:x() < self.bossArrowPosX)
		showBoss()
	end)

	idlereasy.when(self.killBoss, function (_, killBoss)
		-- buff
		local datas = {}
		for bossID, info in pairs(killBoss) do
			local cfg = csv.cross.mine.boss[info.csv_id]
			local endTime = cfg.buffTime*60 + info.time
			local countTime = endTime - time.getTime()
			if countTime > 0 then
				table.insert(datas, {bossID = bossID, info = info, cfg = cfg, time = countTime})
			end
		end
		self.buffDatas:update(datas)
	end)
	self.showStreet:set((self.streetShowType:read() == SHOW_STREET.NORMAL or self.streetShowType:read() == SHOW_STREET.TOP10) and self.streetShowType:read() or (self.role:read().rank > 10 and SHOW_STREET.NORMAL or SHOW_STREET.TOP10))
	self:setChangeLabel()
end

function StreetView:initModel()
	self.round = gGameModel.cross_mine:getIdler("round")
	self.role = gGameModel.cross_mine:getIdler("role")
	self.top10 = gGameModel.cross_mine:getIdler("top10")
	self.enemies = gGameModel.cross_mine:getIdler("enemies")
	self.boss = gGameModel.cross_mine:getIdler("boss")
	self.killBoss = gGameModel.cross_mine:getIdler("killBoss")
	self.npc = gGameModel.cross_mine:getIdler("npc")

	local dailyRecord = gGameModel.daily_record
	-- 跨服矿战换一批次数
	self.refreshTimes = dailyRecord:getIdler("cross_mine_enemy_refresh_times")
	-- 已抢夺次数
	self.robTimes = dailyRecord:getIdler("cross_mine_rob_times")
	-- 抢夺购买次数
	self.robBuyTimes = dailyRecord:getIdler("cross_mine_rob_buy_times")

	self.showDatas = idlers.new()
	self.buffDatas = idlers.new()
	-- 是否存在boss，切在高级区
	self.showBossRedHint = idler.new(false)
	-- 街区显示
	self.btnChangeImg = idler.new("")
	self.showStreet = idler.new(self.streetShowType:read())
	self.updateBoss = idler.new(1)
	-- 自己当前显示的排名位置
	self.showRank = 1
	-- boss显示标识 1 显示 0 不显示
	self.showBoss = 0
	-- downPanel动画x基准点
	self.downPanelAnctionPosX = 0
	-- downPanel动画标识
	self.downPanelIsAction = false
	-- NPC移动容器
	self.npcMoveTable = {}
	-- 剩余可挑战次数
	self.leftTimes = 0
end

function StreetView:initStreet()
	self.bgPanel:setScrollBarEnabled(false)
	self.bgPanel:width(display.sizeInViewRect.width)
	local pos = self.parent:convertToWorldSpace(cc.p(display.sizeInViewRect.width, self.downPanel:y()))
	local x = pos.x
	if self.downPanelPosX:read() then
		x = self.downPanelPosX:read()
	end
	self.downPanel:x(x)
	self.downPanelPosX:set(x)
	self.normalList:setTouchEnabled(false)
	-- 对切换街区按钮做刘海屏适配
	self.btnChange:x(display.notchSceenDiffX + self.btnChange:width()/2)

	-- 初始话boss坐标
	local bossPosX = 1300
	self.bossArrowPosX =  (bossPosX + self.squarePanel:width() + self.bossItem:width()/2)*(-1)
	self.bossItem:x(bossPosX)
	self.bossItem:z(500 - self.bossItem:y())

	local container = self.bgPanel:getInnerContainer()
	self.bgPanel:onScroll(function(event)
		if event.name == "CONTAINER_MOVED" then
			self:downPanelAction(container:x() < self.downPanelAnctionPosX)
			if self.showBoss > 0 then
				self.arrowPanel:visible(container:x() < self.bossArrowPosX)
			end
		end
	end)

	self.bgListTable = {}
	-- 创建背景
	self.stratWidth = self:newBg(STREET_BG_RES.START, "start")
	self.normalList:x(self.stratWidth)
	self.endWidth = self:newBg(STREET_BG_RES.END, "end")

	-- 箭头动画
	local actionPosX = {20, 50}
	self.arrowPanel:x(actionPosX[2])
	local arrowY = self.arrowPanel:y()
	local animate = cc.Sequence:create(
		cc.MoveTo:create(0.3, cc.p(actionPosX[1], arrowY)),
		cc.MoveTo:create(0.3, cc.p(actionPosX[2], arrowY)),
		cc.MoveTo:create(0.3, cc.p(actionPosX[1], arrowY)),
		cc.MoveTo:create(0.3, cc.p(actionPosX[2], arrowY)),
		cc.DelayTime:create(2))
	local action = cc.RepeatForever:create(animate)
	self.arrowPanel:runAction(action)

	-- bossTip动画
	local animate1 = cc.Sequence:create(
		cc.ScaleTo:create(0.2, 1.2, 0.95),
		cc.ScaleTo:create(0.2, 0.95, 1.15),
		cc.ScaleTo:create(0.15, 1.1, 0.97),
		cc.ScaleTo:create(0.15, 0.97, 1.05),
		cc.ScaleTo:create(0.1, 1.0, 1.0),
		cc.DelayTime:create(1.5))
	local action1 = cc.RepeatForever:create(animate1)
	self.bossTip:runAction(action1)

	-- 创建自己角色
	self.ownItem = self.npcItem:clone():show()
		:name("self")
		:addTo(self.bgDownPanel)
	self:createNpcSpine(self.ownItem, self.role:read().figure)
	self.ownItem:get("name"):text(gGameModel.role:read("name"))
	table.insert(self.npcMoveTable, self.ownItem)
end

function StreetView:initSquare()
	widget.addAnimationByKey(self.squareBg:get("pqNode"), "crossmine/penquan.skel", "penquan", "effect_loop", 1)
		:xy(0, 0)
end

-- 初始化定时请求事件以及定时器
function StreetView:initEventTimes()
	local function getUpdateEventTime()
		local timeDatas = {}
		for k, v in orderCsvPairs(csv.cross.mine.event_times) do
			local date = gGameModel.cross_mine:read("date")
			date = date + v.day - 1
			local temp = time.getNumTimestamp(date, time.getHourAndMin(v.time, true))
			if temp - time.getTime() > 0 then
				table.insert(timeDatas, temp)
			end
		end
		if #timeDatas > 0 then
			table.sort(timeDatas, function(a, b)
				return a < b
			end)
			local time = timeDatas[1] - time.getTime()
			performWithDelay(self, function()
				gGameApp:requestServer("/game/cross/mine/main")
				getUpdateEventTime()
			end, time)
		end
	end
	getUpdateEventTime()
	-- 定时器
	self:updateNpcZ(1/60)
	self:updateNewData(60)
end

function StreetView:updateBossSpine(figure_id)
	local spineRes = csv.cross.mine.boss_figure[figure_id].bossRes
	local effectName = csv.cross.mine.boss_figure[figure_id].effectName
	local panel = self.bossItem:get("bgPanel")
	local boss = widget.addAnimation(panel, spineRes, effectName, 1)
		:x(panel:width()/2)
		:scale(2.0)
		:play(effectName)
end

function StreetView:createNpcSpine(node, figureOrRes)
	local spineRes = figureOrRes
	if type(figureOrRes) == "number" then
		local cfg = gRoleFigureCsv[figureOrRes]
		spineRes = cfg.crossMineResSpine
	end
	local npc = widget.addAnimationByKey(node, spineRes, "spine", "standby_loop", 1)
		:x(node:width()/2)
		:scale(2)
	return npc
end

function StreetView:initNpc()
	for npcID, npcDate in pairs(self.npc:read()) do
		local npc = self.npcItem:clone():show()
			:name(npcDate.id)
			:addTo(self.bgDownPanel)
		local res = csv.cross.mine.npc[npcDate.csv_id].res
		self:createNpcSpine(npc, res)
		npc:get("name"):text("")
		npc.data = {npcID = npcID, id = npcDate.id, csv_id = npcDate.csv_id, open_time = npcDate.open_time}
		self:updateNpc(npc)
		table.insert(self.npcMoveTable, npc)
	end
end

function StreetView:updateNewData(dt)
	if self.round:read() == "closed" then
		return
	end
	performWithDelay(self, function()
		gGameApp:requestServer("/game/cross/mine/main", function(tb)
			if tb.ret == true then
				self:updateNewData(dt)
				-- 刷新数据，飘金币
					self:updateShowDatas(self.showStreet:read(), true)
				end
			end)
	end, dt)
end

function StreetView:updateNpcZ(dt)
	if self.round:read() == "closed" then
		return
	end
	performWithDelay(self, function()
		-- 若存在走动NPC，需要根据y坐标刷新z层级
		for k, npc in pairs(self.npcMoveTable) do
			if npc.posZ == nil then
				npc.posZ = npc:z()
			end
			local z = npc.posZ
			local nowZ = 500 - npc:y()
			if z ~= nowZ then
				npc.posZ = nowZ
				npc:z(nowZ)
			end
		end
		self:updateNpcZ(dt)
	end, dt)
end

function StreetView:newBg(res, name, index)
	local img = ccui.ImageView:create(res)
		:anchorPoint(0, 0)
		:xy(0, 0)
		:scale(2)
		:addTo(self.normalBgPanel, 1, name)
	if name == "start" or name == "end" then
		table.insert(self.bgListTable, img)
	else
		local pos = index or #self.bgListTable
		table.insert(self.bgListTable, pos, img)
	end
	return img:width()*2
end

function StreetView:downPanelAction(isOpen)
	if self.downPanelIsAction == true then return end
	local showScaleX = isOpen and 1 or 0
	if self.downPanel:scaleX() == showScaleX then return end
	self.downPanelIsAction = true
	self.downPanel:runAction(cc.Sequence:create(
		cc.ScaleTo:create(0.1, (isOpen and 1 or 0), 1),
		cc.CallFunc:create(function()
			self.downPanelIsAction = false
		end)
	))
end

function StreetView:updateShowDatas(showStreet, goldAction)
	self.showRank = 1
	local dates = {}
	local showAllDatas = self.top10:read() or {}
	if showStreet == SHOW_STREET.NORMAL then
		showAllDatas = self.enemies:read() or {}
	end

	local selfID = self.role:read().role_db_id
	for k, info in pairs(showAllDatas) do
		local isSelf = false
		if showStreet == SHOW_STREET.TOP10 and selfID == info.role_db_id then
			isSelf = true
		end
		table.insert(dates, {cfg = info, rank = info.rank, isSelf = isSelf})
	end
	local maxLen = 10
	if showStreet == SHOW_STREET.NORMAL then
		local info = self.role:read()
		if info.rank > 10 then
			table.insert(dates, {cfg = info, rank = info.rank, isSelf = true})
		end
		maxLen = 11
	end
	table.sort(dates, function(a, b)
		return a.rank < b.rank
	end)
	if #dates < maxLen then
		local basRank = #dates == 0 and 10 or dates[#dates].rank
		for i=1 , (maxLen-#dates) do
			table.insert(dates, {cfg = {}, rank = basRank + i, isSelf = false, empty = true})
		end
	end
	for k, val in pairs(dates) do
		if val.isSelf == true then
			self.showRank = k
			break
		end
	end
	if goldAction then
		for k, val in pairs(dates) do
			if not val.empty and self.showDatas:atproxy(k) then
				local old = self.showDatas:atproxy(k).cfg
				local now = val.cfg
				if (old.coin13_origin and old.coin13_origin + old.coin13_diff ~= now.coin13_origin + now.coin13_diff) or not old.coin13_origin then
					val.goldAction = true
				end
			end
		end
	end
	self.showDatas:update(dates)
end

-- 刷新自己位置
function StreetView:refreshListPos(PanelWidth)
	PanelWidth = PanelWidth or self.normalList:width() + self.stratWidth + self.endWidth
	local AllWidth = PanelWidth + self.squarePanel:width() - self.bgPanel:width()
	local startPosX = self.squarePanel:width()
	local percent = startPosX/AllWidth*100
	if not self.isShowBoss and self.showRank > 2 then
		startPosX = ITEM_WIDTH[self.showStreet:read()]*(self.showRank-3) + self.stratWidth + self.squarePanel:width()
		startPosX = math.min(startPosX ,AllWidth)
		percent = startPosX/AllWidth*100
	end
	self.bgPanel:jumpToPercentHorizontal(percent)
	-- 人物走出来
	self:updateMyRole(startPosX - self.squarePanel:width() - 150)
end

-- 玩家详情
function StreetView:onInfoClick(list, k, v)
	if v.empty then return end
	gGameApp:requestServer("/game/cross/mine/role/info", function(tb)
		gGameUI:stackUI("city.pvp.cross_mine.personal_info", nil, {clickClose = true, blackLayer = true}, tb.view)
	end,v.cfg.record_db_id, v.cfg.game_key, v.cfg.rank)
end

-- 竞标
function StreetView:onBlessingClick(list, k, v)
	if self.round:read() == "over" then
		gGameUI:showTip(gLanguageCsv.crossMineTruce)
		return
	end
	gGameApp:requestServer("/game/cross/mine/role/info", function(tb)
		local data = tb.view

		local endHour, endmin = dataEasy.getTimeStrByKey("crossMine", "mineEnd", true)
		local endTime = time.getNumTimestamp(gGameModel.cross_mine:read("date"), endHour, endmin) + 2 * 24 * 3600
		if endTime - time.getTime() > gCommonConfigCsv.crossMineDisablenBattleProtectBeforeOver * 60 then
			if data.role_be_roded.time and #data.role_be_roded.time > 0 and data.role_be_roded.time[#data.role_be_roded.time] + 5*60 > time.getTime() then
				-- 被挑战5分钟内不允许被挑战
				gGameUI:showTip(string.format(gLanguageCsv.crossMineProtected, data.role_name))
				return
			end
		end
		local enemy = {
			roleID = v.cfg.role_db_id,
			recordID = v.cfg.record_db_id,
			rank = data.rank
		}
		local func = function()
			self.blessingCallBack(data, enemy)
		end
		if self.leftTimes > 0 then
			func()
		else
			self:btnBiddingAdd(func)
		end
	end, v.cfg.record_db_id, v.cfg.game_key, v.cfg.rank, "rob")
end

-- buff详情
function StreetView:onBuffClick(list, k, v)
	local rect = list:box()
	local pos = list:parent():convertToWorldSpace(cc.p(rect.x, rect.y))
	local params = {data = v.cfg, pos = {pos.x + k*self.buffItem:width(), pos.y + 200}}
	gGameUI:createView("city.pvp.cross_mine.buff_info", self.parent):init(params)
end

-- 服务器排行
function StreetView:onServerRank()
	gGameApp:requestServer("/game/cross/mine/main", function()
		gGameUI:createView("city.pvp.cross_mine.server_rank", self.parent):init()
	end)
end

-- 高低街区切换
function StreetView:onChange()
	-- 场景切换spine
	self:zhuanChangAction()
	local showStreet = self.showStreet:read() == SHOW_STREET.NORMAL and SHOW_STREET.TOP10 or SHOW_STREET.NORMAL
	self.showStreet:set(showStreet)
	self:setChangeLabel()
end

-- 刷新
function StreetView:onRefresh()
	local function callFunc()
		gGameApp:requestServer("/game/cross/mine/main", function()
			self:zhuanChangAction()
			self:updateShowDatas(self.showStreet:read())
			self:refreshListPos()
		end, true)
	end
	local fresh_cost = math.min(self.refreshTimes:read()+1, itertools.size(gCostCsv.cross_mine_enemy_fresh_cost))
	if gCostCsv.cross_mine_enemy_fresh_cost[fresh_cost] > 0 then
		local params = {
			cb = callFunc,
			isRich = true,
			btnType = 2,
			content = string.format(gLanguageCsv.crossMineCost, gCostCsv.cross_mine_enemy_fresh_cost[fresh_cost]),
			dialogParams = {clickClose = false},
		}
		gGameUI:showDialog(params)
	else
		callFunc()
	end
end

-- 挑战boss
function StreetView:onBossChallenge()
	local bossDatas = {}
	local boss = self.boss:read()
	for id, info in pairs(boss) do
		table.insert(bossDatas, {bossID = id, info = info})
	end
	table.sort(bossDatas, function(a, b)
		return a.info.open_time >  b.info.open_time
	end)
	gGameUI:stackUI("city.pvp.cross_mine.boss_challenge", nil, {clickClose = true, blackLayer = true}, bossDatas[1].bossID)
end

-- 购买抢夺次数
function StreetView:btnBiddingAdd(callBack)
	local times = math.min(itertools.size(gCostCsv.cross_mine_rob_buy_cost), self.robBuyTimes:read()+1)
	local curCost = gCostCsv.cross_mine_rob_buy_cost[times]
	local params = {
		cb = function()
			gGameApp:requestServer("/cross/mine/times/buy", function()
				if type(callBack) == "function" then
					callBack()
				end
			end, "rob")
		end,
		isRich = true,
		btnType = 2,
		content = string.format(gLanguageCsv.richCostDiamond, curCost) .. gLanguageCsv.pvpBiddingBuyTimes,
		dialogParams = {clickClose = false},
	}
	gGameUI:showDialog(params)
end

-- 商区刷新
function StreetView:setChangeLabel()
	local showStreet = self.showStreet:read()
	self.btnChangeImg:set(showStreet == SHOW_STREET.NORMAL and "city/pvp/cross_mine/icon_gj_kfsyj.png" or "city/pvp/cross_mine/icon_pt_kfsyj.png")
end

-- 刷新自己角色人物位置
function StreetView:updateMyRole(startPosX)
	self.ownItem:stopAllActions()
	self.ownItem:xy(startPosX, 100)
	local endPosX, time, leftOrRight = self:getEndPos({startPosX, 100}, true)
	self.selfMoveState = "walk"
	self:NpcMove(self.ownItem, endPosX, time, leftOrRight, function ()
		self:selfRandomWalk()
	end)
end

-- NPC人物刷新
function StreetView:updateNpc(npc)
	local startPosX = math.random(100, self.bgDownPanel:width() - 100)
	local startPosY = math.random(50, self.bgDownPanel:height() - 50)
	npc:xy(startPosX, startPosY)
	local endPosX, time, leftOrRight = self:getEndPos({startPosX, startPosY}, false, npc)
	npc.moveState = "walk"
	self:NpcMove(npc, endPosX, time, leftOrRight, function ()
		self:npcRandomWalk(npc)
	end)
end

function StreetView:NpcMove(node, pos, time, leftOrRight, cb)
	node:get("spine"):play("run_loop")
	if leftOrRight == 0 then
		node:get("spine"):scaleX(-2)
	else
		node:get("spine"):scaleX(2)
	end
	node:runAction(cc.Sequence:create(
		cc.MoveTo:create(time, cc.p(pos[1], pos[2])),
		cc.CallFunc:create(function()
			if cb then
				cb()
			end
		end)))
end

function StreetView:NpcStop(node, time, cb)
	node:get("spine"):play("standby_loop")
	node:runAction(cc.Sequence:create(
		cc.DelayTime:create(time),
		cc.CallFunc:create(function()
			if cb then
				cb()
			end
		end)))
end

function StreetView:getEndPos(startPos, start, npc)
	local x = startPos[1] or 0
	local y = startPos[2] or 0
	local randomXMin = SELF_MOVE_RANDOM[1].x[1]
	local randomXMax = SELF_MOVE_RANDOM[1].x[2]
	local randomYMin = SELF_MOVE_RANDOM[1].y[1]
	local randomYMax = SELF_MOVE_RANDOM[1].y[2]
	if npc then
		randomXMin = csv.cross.mine.npc[npc.data.csv_id].moveIntervalX[1]
		randomXMax = csv.cross.mine.npc[npc.data.csv_id].moveIntervalX[2]
		randomYMin = csv.cross.mine.npc[npc.data.csv_id].moveIntervalY[1]
		randomYMax = csv.cross.mine.npc[npc.data.csv_id].moveIntervalY[2]
	end
	local moveLenX = math.random(randomXMin, randomXMax)
	local moveLenY = math.random(randomYMin, randomYMax)
	local randomLeftOrRight = math.random(0, 1) -- 0 左，1 右
	local randomDownOrUp = math.random(0, 1) -- 0 下，1 上
	if start then
		randomLeftOrRight = 1
	else
		if (x - moveLenX) < WIDTH_HEIGHT_MAX_LEFT_OVER[1][1] then
			randomLeftOrRight = 1
		elseif (x + moveLenX) > (self.bgDownPanel:width() - WIDTH_HEIGHT_MAX_LEFT_OVER[1][2]) then
			randomLeftOrRight = 0
		end
	end
	x = randomLeftOrRight == 0 and (x - moveLenX) or (x + moveLenX)

	if (y - moveLenY) < WIDTH_HEIGHT_MAX_LEFT_OVER[2][2] then
		randomDownOrUp = 1
	elseif (y + moveLenY) > (self.bgDownPanel:height() - WIDTH_HEIGHT_MAX_LEFT_OVER[2][1]) then
		randomDownOrUp = 0
	end
	y = randomDownOrUp == 0 and (y - moveLenY) or (y + moveLenY)

	local randomSpeedMin = SELF_MOVE_RANDOM[3][1]
	local randomSpeedMax = SELF_MOVE_RANDOM[3][2]
	if npc then
		randomSpeedMin = csv.cross.mine.npc[npc.data.csv_id].moveSpeed[1]
		randomSpeedMax = csv.cross.mine.npc[npc.data.csv_id].moveSpeed[2]
	end
	local time = math.abs(startPos[1]-x) / math.random(randomSpeedMin, randomSpeedMax)
	return {x, y}, time, randomLeftOrRight
end

function StreetView:selfRandomWalk()
	self.selfMoveState = self.selfMoveState == "walk" and "stop" or "walk"
	if self.selfMoveState == "walk" then
		local endPosX, time, leftOrRight = self:getEndPos({self.ownItem:x(), self.ownItem:y()})
		self:NpcMove(self.ownItem, endPosX, time, leftOrRight, function ()
			self:selfRandomWalk()
		end)
	else
		self:NpcStop(self.ownItem, math.random(SELF_MOVE_RANDOM[2][1], SELF_MOVE_RANDOM[2][2]), function ()
			self:selfRandomWalk()
		end)
	end
end

function StreetView:npcRandomWalk(npc)
	npc.moveState = npc.moveState == "walk" and "stop" or "walk"
	if npc.moveState == "walk" then
		local endPosX, time, leftOrRight = self:getEndPos({npc:x(), npc:y()}, false, npc)
		self:NpcMove(npc, endPosX, time, leftOrRight, function ()
			self:npcRandomWalk(npc)
		end)
	else
		self:NpcStop(npc, math.random(SELF_MOVE_RANDOM[2][1], SELF_MOVE_RANDOM[2][2]), function ()
			self:npcRandomWalk(npc)
		end)
	end
end

function StreetView:setBossCountdown(countdown, uiTime)
	self:enableSchedule():unSchedule(88)
	countdown = math.max(countdown, 0)
	if countdown == 0 then
		self.updateBoss:set(self.updateBoss:read() == 1 and 0 or 1)
		return
	end
	bind.extend(self, uiTime, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			tag = 88,
			strFunc = function(t)
				return t.str
			end,
			callFunc = function()
			end,
			endFunc = function()
				self.updateBoss:set(self.updateBoss:read() == 1 and 0 or 1)
			end
		}
	})
end

function StreetView:zhuanChangAction(cb)
	local spine = widget.addAnimationByKey(self.parent, "crossmine/shangdianjie_zhuanchang.skel", "zhuanchang", "effect", 999)
	spine:xy(display.sizeInViewRect.width/2, display.sizeInViewRect.height/2)
	spine:play("effect")
	spine:scale(2.0)
	spine:setSpriteEventHandler(function(event, eventArgs)
		if cb then
			cb()
		end
	end, sp.EventType.ANIMATION_COMPLETE)
end

--祝福
function StreetView:onBlessingWishClick()
	gGameUI:stackUI("city.pvp.cross_mine.wish")
end

function StreetView:updateOverLabel()
	local function updateLeftTimeStr()
		local curTb = time.getNowDate()
		local curTime = time.getTimestamp(curTb)
		local startHour, startmin = dataEasy.getTimeStrByKey("crossMine", "mineStart", true)
		local endHour, endmin = dataEasy.getTimeStrByKey("crossMine", "mineEnd", true)
		if curTb.hour > endHour or (curTb.hour == endHour and curTb.min > endmin) then
			curTb.day = curTb.day + 1
		end
		curTb.hour = startHour
		curTb.min = startmin
		curTb.sec = 0
		local startTime = time.getTimestamp(curTb)
		local delta = startTime - curTime
		if delta < 1 then
			return true
		end
		self.restLabel:text(string.format("%s%s", gLanguageCsv.crossMineOverStr, time.getCutDown(delta).str))
		return false
	end
	self:enableSchedule():unSchedule(20210519)
	self:enableSchedule()
		:schedule(function(dt)
			updateLeftTimeStr()
		end, 1, 0, 20210519)
end
return StreetView