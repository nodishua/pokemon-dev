-- @date 2020-3-5
-- @desc 跨服石英大会主界面

local NEED_CARDS = 12

local ViewBase = cc.load("mvc").ViewBase
local CrossCraftView = class("CrossCraftView", ViewBase)

CrossCraftView.RESOURCE_FILENAME = "cross_craft.json"
CrossCraftView.RESOURCE_BINDING = {
	["firstPanel"] = "firstPanel",
	["firstPanel.tipTime"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["signupPanel"] = "signupPanel",
	["signupPanel.bg"] = "bg",
	["signupPanel.title"] = "title",
	["signupPanel.item"] = "signupItem",
	["signupPanel.subList"] = "signupSubList",
	["signupPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("servers"),
				item = bindHelper.self("signupSubList"),
				cell = bindHelper.self("signupItem"),
				bg = bindHelper.self("bg"),
				title = bindHelper.self("title"),
				columnSize = 5,
				onCell = function(list, node, k, v)
					node:get("server"):text(string.format(gLanguageCsv.brackets, getServerArea(v, nil, true)))
					text.addEffect(node:get("server"), {outline = {color = cc.c4b(72, 74, 133, 255), size = 3}})
				end,
				onAfterBuild = function(list)
					local count = list:getChildrenCount()
					if count == 1 then
						for _, child in pairs(list:getChildren()) do
							child:setItemAlignCenter()
						end
						list:setItemAlignCenter()
					else
						local height = list.item:height()
						list:height(height*count)
						list.bg:height(128 + height*(count-1))
						list.title:y(486 + height*(count-1))
					end
				end
			},
		},
	},
	["signupPanel.btn"] = {
		varname = "signupBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSignupClick")}
		},
	},
	["signupPanel.btn.txt"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["signupPanel.signed.timeText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["signupPanel.signed"] = "signedPanel",
	["signupPanel.signed.time"] = {
		varname = "signedTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["signupPanel.tipTime"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["signupPanel.vipShow"] = {
		varname = "vipShow",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["countdownPanel"] = "countdownPanel",
	["countdownPanel.tip"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["countdownPanel.time"] = {
		varname = "otherTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["overPanel"] = "overPanel",
	["overPanel.top1"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onShowInfo(1)
			end),
		},
	},
	["overPanel.top2"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onShowInfo(2)
			end),
		},
	},
	["overPanel.top3"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onShowInfo(3)
			end),
		},
	},
	["overPanel.tip"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["leftBtn1"] = "leftBtn1",
	["leftBtn1.myTeam"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onMyTeamClick")}
		},
	},
	["leftBtn2"] = "leftBtn2",
	["leftBtn2.myTeam"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onMyTeamClick")}
		},
	},
	["leftBtn2.mySchedule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onMyScheduleClick")}
		},
	},
	["leftBtn2.mainSchedule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onMainScheduleClick")}
		},
	},
	["rightBtn"] = "rightBtn",
	["rightBtn.rule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")}
		},
	},
	["rightBtn.rule.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(97, 89, 89, 255), size = 3}},
		},
	},
	["rightBtn.rankReward"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankRewardClick")}
		},
	},
	["rightBtn.rankReward.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(97, 89, 89, 255), size = 3}},
		},
	},
	["rightBtn.record"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRecordClick")}
		},
	},
	["rightBtn.record.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(97, 89, 89, 255), size = 3}},
		},
	},
	["rightBtn.bet"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBetClick")}
		},
	},
	["rightBtn.bet.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(97, 89, 89, 255), size = 3}},
		},
	},
	["rightBtn.shop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShopClick")}
		},
	},
	["rightBtn.shop.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(97, 89, 89, 255), size = 3}},
		},
	},
	["bgPanel"] = "bgPanel",
}

function CrossCraftView:onCleanup()
	self._topuiState = self.topuiState:read()
	ViewBase.onCleanup(self)
end

function CrossCraftView:onCreate()
	self:initModel()
	self:enableSchedule()
	self.topuiState = idler.new(self._topuiState or 1) -- 1、首个界面，2、第二层界面，点返回回到上个界面
	self.subView = {}

	self.bgFirstEffect1 = widget.addAnimationByKey(self.bgPanel, "kuafushiying/sydhcb.skel", "effect1", "effect_loop", 1)
		:scale(2)
		:alignCenter(self.bgPanel:size())
	self.bgFirstEffect2 = widget.addAnimationByKey(self.bgPanel, "kuafushiying/sydhcb.skel", "effectCard1", "effect2_loop", 2)
		:scale(2)
		:xy(self.bgPanel:width()/2 - 200 + display.uiOrigin.x, self.bgPanel:height()/2)
	self.bgEffect = widget.addAnimationByKey(self.bgPanel, "kuafushiying/bj.skel", "effect2", "effect_loop", 1)
		:scale(2)
		:alignCenter(self.bgPanel:size())

	local panels = {self.firstPanel, self.signupPanel, self.overPanel, self.countdownPanel, self.leftBtn1, self.leftBtn2, self.signupBtn, self.signedPanel, self.vipShow}
	self.subViewFunc = {
		battleMessages = function(...)
			return gGameUI:createView("city.pvp.cross_craft.battle_messages", self:getResourceNode()):init(...):x(display.uiOrigin.x)
		end,
		mySchedule = function(...)
			return gGameUI:createView("city.pvp.cross_craft.myschedule", self:getResourceNode()):init(...):x(display.uiOrigin.x)
		end,
		mainSchedule = function(...)
			return gGameUI:createView("city.pvp.cross_craft.main_schedule_final", self:getResourceNode()):init(...):x(display.uiOrigin.x)
		end,
	}
	idlereasy.when(self.topuiState, function()
		self:resetTopuiView()
	end)
	idlereasy.any({self.round, self.signupDate, self.topuiState}, function(_, round, signupDate, topuiState)
		local signed = CrossCraftView.isSigned()
		for _, panel in ipairs(panels) do
			panel:hide()
		end

		local showFirstBg = false
		local viewName = nil
		if round == "closed" then
			local data = gGameModel.cross_craft:read("last_top8_plays")
			if itertools.isempty(data) then
				self.firstPanel:show()
				showFirstBg = true
			else
				self.overPanel:show()
				local champion = data.final.champion
				local third = data.final.third
				self.topData = {
					champion.result == "win" and champion.role1 or champion.role2,
					champion.result == "win" and champion.role2 or champion.role1,
					third.result == "win" and third.role1 or third.role2,
				}
				for i = 1, 3 do
					self:setTopInfo(i)
				end
			end

		elseif round == "signup" then
			showFirstBg = true
			self.signupPanel:show()
			if signed then
				self.signedPanel:show()
				self.leftBtn1:show()
				self:setCountdown(self.signedTime, CrossCraftView.getNextStateTime("prepare"), 1)
			else
				self.signupBtn:show()
				self.vipShow:show()
				self.vipShow:text(string.format(gLanguageCsv.vipSignupShow, csv.cross.craft.base[1].autoSignVIP))
			end

		else
			local info = gGameModel.cross_craft:read("info")
			local isout = info and info.isout
			local showMySchedule = false
			if signed then
				self.leftBtn2:show()
				if isout then
					-- 已淘汰的先显示主赛场
					showMySchedule = false
				else
					-- 已报名的首次进入显示我的赛程界面，左下角是主赛场按钮
					showMySchedule = true
				end
				if topuiState == 2 then
					showMySchedule = not showMySchedule
				end
				self.leftBtn2:get("mySchedule"):visible(not showMySchedule)
				self.leftBtn2:get("mainSchedule"):visible(showMySchedule)
			end
			if not showMySchedule then
				if round == "prepare" then
					-- 准备阶段 未报名显示倒计时
					self:setCountdown(self.otherTime, CrossCraftView.getNextStateTime("prepare"), 2)
					self.countdownPanel:show()

				elseif string.find(round, "^pre%d") or round == "halftime" or round == "prepare2" then
					viewName = "battleMessages"

				elseif string.find(round, "^top") then
					viewName = "mainSchedule"

				elseif string.find(round, "^final") then
					viewName = "mainSchedule"

				end
			else
				viewName = "mySchedule"
			end
		end
		self:showSubView(viewName)

		self.bgFirstEffect1:visible(showFirstBg)
		self.bgFirstEffect2:visible(showFirstBg)
		self.bgEffect:visible(not showFirstBg)
		self.rightBtn:get("bg"):visible(showFirstBg)
	end)

	local lastRequestTime = 0
	self:schedule(function()
		local round = self.round:read()
		if round == "closed" then
			return
		end
		local delta = CrossCraftView.getNextStateTime(nil, true)
		if delta <= 0 then
			-- 异常卡秒，连续请求间隔 10
			if time.getTime() - lastRequestTime > 10 then
				lastRequestTime = time.getTime()
				gGameApp:requestServer("/game/cross/craft/battle/main")
			end
		end
	end, 1, 0)
end

function CrossCraftView:initModel()
	self.round = gGameModel.cross_craft:getIdler("round")
	self.signupDate = gGameModel.role:getIdler("cross_craft_sign_up_date")
	self.cards = gGameModel.cross_craft:getIdler("cards")
	self.servers = getMergeServers(gGameModel.cross_craft:read("servers"))
	self.lastTop8 = gGameModel.cross_craft:getIdler("last_top8_plays")
end

function CrossCraftView:showSubView(viewName, ...)
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

function CrossCraftView:onSignupClick()
	-- 服务器数据存在异常，卡牌被分解掉的情况
	local isCardError = false
	for _, dbId in pairs(self.cards:read()) do
		local card = gGameModel.cards:find(dbId)
		if not card then
			isCardError = true
			break
		end
	end
	if isCardError or itertools.size(self.cards:read()) < NEED_CARDS then
		local cardEnough = false
		-- 上阵精灵需满足不重复12只
		local cards = gGameModel.role:read("cards")
		local newCards = {}
		if itertools.size(cards) >= NEED_CARDS then
			local oneKeyAllCards = {}
			for _, dbid in ipairs(cards) do
				local card = gGameModel.cards:find(dbid)
				local cardDatas = card:read("card_id","fighting_point")
				local cardCfg = csv.cards[cardDatas.card_id]
				local unitCfg = csv.unit[cardCfg.unitID]

				table.insert(oneKeyAllCards, {
					id = dbid,
					fighting_point = cardDatas.fighting_point,
					rarity = unitCfg.rarity,
				})
			end
			table.sort(oneKeyAllCards, function(a, b)
				if a.fighting_point ~= b.fighting_point then
					return a.fighting_point > b.fighting_point
				end
				return a.rarity > b.rarity
			end)
			local hash = {}
			local count = 0
			for _, data in ipairs(oneKeyAllCards) do
				local dbId = data.id
				local cardId = gGameModel.cards:find(dbId):read("card_id")
				local cfg = csv.cards[cardId]
				local cardMarkID = cfg.cardMarkID
				if not hash[cardMarkID] then
					hash[cardMarkID] = true
					table.insert(newCards, dbId)
					count = count + 1
				end
				if count >= NEED_CARDS then
					cardEnough = true
					break
				end
			end
		end
		if not cardEnough then
			gGameUI:showTip(gLanguageCsv.crossCraftNotSignup)
			return
		end
		local url = "/game/cross/craft/battle/deploy"
		local tipStr = gLanguageCsv.battleResetSuccess
		if not CrossCraftView.isSigned() then
			url = "/game/cross/craft/signup"
			tipStr = gLanguageCsv.signUpSuccess
		end
		gGameApp:requestServer(url, function(tb)
			gGameUI:stackUI("city.pvp.cross_craft.embattle", nil, {full = true})
			gGameUI:showTip(tipStr)
		end, newCards)
		return
	end

	if not CrossCraftView.isSigned() then
		gGameApp:requestServer("/game/cross/craft/signup", function()
			gGameUI:stackUI("city.pvp.cross_craft.embattle", nil, {full = true})
			gGameUI:showTip(gLanguageCsv.signUpSuccess)
		end, self.cards)
		return
	end
	gGameUI:stackUI("city.pvp.cross_craft.embattle", nil, {full = true})
end

function CrossCraftView:onMyTeamClick()
	local info = gGameModel.cross_craft:read("info")
	if info and info.isout then
		gGameUI:showTip(gLanguageCsv.isOutCantEnterEmbattle)
	else
		gGameUI:stackUI("city.pvp.cross_craft.embattle", nil, {full = true})
	end
end

function CrossCraftView:onMyScheduleClick()
	self.topuiState:modify(function(val)
		return true, 3 - val
	end)
end

function CrossCraftView:onMainScheduleClick()
	self.topuiState:modify(function(val)
		return true, 3 - val
	end)
end

function CrossCraftView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function CrossCraftView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(124),
		c.noteText(74001, 74100),
		c.noteText(125),
		c.noteText(75001, 75100),
		c.noteText(126),
		c.noteText(76001, 76100),
		c.noteText(127),
		c.noteText(77001, 77100),
		c.noteText(136),
		c.noteText(78001, 78100),
		c.noteText(137),
		c.noteText(79001, 79100),
	}
	return context
end

function CrossCraftView:onRankRewardClick()
	gGameApp:requestServer("/game/cross/craft/rank",function (tb)
		gGameUI:stackUI("city.pvp.cross_craft.rank", nil, nil, tb.view)
	end)
end

function CrossCraftView:onRecordClick()
	if self.round:read() ~= "over" and self.round:read() ~= "closed" and self.round:read() ~= "signup" then
		gGameUI:showTip(gLanguageCsv.craftRankGaming)
		return
	end
	if itertools.isempty(self.lastTop8:read()) then
		gGameUI:showTip(gLanguageCsv.crossCraftFirstPrepare)
		return
	end
	gGameUI:stackUI("city.pvp.cross_craft.main_schedule_final", nil, {full = true}, true)
end

function CrossCraftView:onBetClick()
	if self.round:read() == "closed" and itertools.isempty(self.lastTop8:read()) then
		gGameUI:showTip(gLanguageCsv.crossCraftFirstPrepare)
		return
	end
	-- 是否出预选结果
	local function checkPreResult()
		local round = self.round:read()
		if round == "closed" then
			return true
		end
		local currentIndex = 0
		local top64Index = 0
		for k, v in ipairs(game.CROSS_CRAFT_ROUNDS) do
			if v == round then
				currentIndex = k
			elseif v == "top64" then
				top64Index = k
			end
		end
		-- top64的时候出预选赛结果
		return currentIndex >= top64Index
	end

	gGameApp:requestServer("/game/cross/craft/bet/info",function (tb1)
		if checkPreResult() == false then
			gGameApp:requestServer("/game/rank",function (tb2)
				gGameUI:stackUI("city.pvp.cross_craft.bet", nil, {full = true}, {tb1.view, tb2.view})
			end, "fight", 0, 50)
		else
			gGameApp:requestServer("/game/cross/craft/pre/point/rank",function (tb2)
				-- 改版加了积分 导致第一次数据为空 所以请求改版前的数据代替显示
				if #tb2.view.rank > 0 then
					local data = {rank = {}}
					for k, v in ipairs(tb2.view.rank) do
						data.rank[k] = {role = clone(v)}
					end
					gGameUI:stackUI("city.pvp.cross_craft.bet", nil, {full = true}, {tb1.view, data})
				else
					gGameApp:requestServer("/game/rank",function (tb2)
						gGameUI:stackUI("city.pvp.cross_craft.bet", nil, {full = true}, {tb1.view, tb2.view})
					end, "fight", 0, 50)
				end
			end, 0, 50)
		end
	end)
end

function CrossCraftView:onShopClick()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fixshop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.CROSS_CRAFT_SHOP)
		end)
	end
end

function CrossCraftView:onShowInfo(from)
	if not self.topData or not self.topData[from] then
		return
	end
	gGameApp:requestServer("/game/cross/craft/battle/enemy/get", function(tb)
		gGameUI:stackUI("city.pvp.cross_craft.array_info", nil, nil, tb.view)
	end, self.topData[from].game_key, self.topData[from].role_db_id, self.topData[from].record_db_id)
end

function CrossCraftView:setTopInfo(i)
	local info = self.topData[i]
	local item = self.overPanel:get("top" .. i)
	local childs = item:get("down"):multiget("name", "level", "server", "fightPointText", "fightPoint", "vip")
	childs.name:text(info.name)
	if info.vip > 0 then
		childs.vip:texture(ui.VIP_ICON[info.vip]):show()
	else
		childs.vip:hide()
	end
	childs.level:text("Lv" .. info.level)
	childs.server:text(string.format(gLanguageCsv.brackets, getServerArea(info.game_key, true)))
	childs.fightPoint:text(info.display.fighting_point)
	adapt.oneLinePos(childs.name, childs.vip, cc.p(15, 0))
	adapt.oneLinePos(childs.level, childs.server, cc.p(15, 0))
	adapt.oneLinePos(childs.fightPointText, childs.fightPoint, cc.p(10, 0))

	item:removeChildByName("card")
	item:removeChildByName("figure")
	local unitCfg = dataEasy.getUnitCsv(info.display.top_card,info.display.skin_id)
	local figureCfg = gRoleFigureCsv[info.figure]
	local size = item:size()
	local cardSprite = widget.addAnimationByKey(item, unitCfg.unitRes, "card", "standby_loop", 3)
		:xy(size.width / 2 + 100, size.height / 4 + 50)
		:scale(unitCfg.scale * 1.6)
	cardSprite:setSkin(unitCfg.skin)

	if figureCfg.resSpine ~= "" then
		widget.addAnimationByKey(item, figureCfg.resSpine, "figure", "standby_loop1", 4)
			:xy(size.width / 2 - 100, size.height / 4 + 50)
	end

	if info.title > 0 then
		bind.extend(self, item, {
			event = "extend",
			class = "role_title",
			props = {
				data = info.title,
				onNode = function(node)
					node:xy(size.width/2, size.height + 20)
						:scale(1.3)
						:z(5)
				end
			}
		})
	end
end

-- 显示倒计时
function CrossCraftView:setCountdown(ui, dt, tag)
	self:unSchedule(tag)
	ui:text(time.getCutDown(dt).str)
	self:schedule(function()
		dt = dt - 1
		if dt < 0 then
			return false
		end
		ui:text(time.getCutDown(dt).str)
	end, 1, 1, tag)
end

function CrossCraftView:resetTopuiView()
	local state = self.topuiState:read()
	if self.topuiView then
		gGameUI.topuiManager:removeView(self.topuiView)
	end
	if state == 1 then
		self.topuiView = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
			:init({title = gLanguageCsv.crossCraft, subTitle = "CROSS - INDIGO PLATEAU CONFERENCE"})

	else
		self.topuiView = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onCloseSubView")})
			:init({title = gLanguageCsv.crossCraft, subTitle = "CROSS - INDIGO PLATEAU CONFERENCE"})
	end
end

function CrossCraftView:onCloseSubView()
	self.topuiState:set(1)
end

-- 是否已报名
function CrossCraftView.isSigned()
	local date = gGameModel.cross_craft:read("date")
	if date == 0 then
		return false
	end
	return date == gGameModel.role:read("cross_craft_sign_up_date")
end

-- 默认获得到下一个状态的剩余时间，或到指定 targetRound 结束时刻的剩余时间
function CrossCraftView.getNextStateTime(targetRound, realTime)
	local round = gGameModel.cross_craft:read("round")
	local data = game.CROSS_CRAFT_ROUND_STATE[round]
	if data and data.time then
		local dt = gGameModel.cross_craft:read("time") - time.getTime() + 1
		local hour, min = dataEasy.getTimeStrByKey("crossCraft", "signUpEnd", true)
		if round == "signup" then
			-- 固定时间第一天 18:50 变更状态到 prepare
			local date = gGameModel.cross_craft:read("date")
			if date ~= 0 then
				dt = time.getNumTimestamp(tonumber(date), hour, min)- time.getTime()
			end

		elseif round == "halftime" then
			-- 固定时间第二天 18:50 变更状态到 prepare2
			local date = gGameModel.cross_craft:read("date")
			if date ~= 0 then
				dt = time.getNumTimestamp(tonumber(date), hour, min) + 86400- time.getTime()
			end

		else
			dt = dt + data.time
		end
		if targetRound then
			local sumTime = nil
			for _, v in ipairs(game.CROSS_CRAFT_ROUNDS) do
				if v == round then
					sumTime = 0
				elseif sumTime then
					sumTime = sumTime + (game.CROSS_CRAFT_ROUND_STATE[v].time or 0)
				end
				if sumTime and v == targetRound then
					break
				end
			end
			dt = dt + sumTime
		end
		if dt >= 0 then
			return dt
		end
	end
	return realTime and 0 or 10
end

-- 获得阵容在第几场，返回0表示准备中，返回2表示当前round在第2场
function CrossCraftView.getArrayRoundIdx(round)
	if round == "closed" then
		return 5
	end
	if round == "prepare2" then
		return 0
	end
	local roundIdx = 0
	local lockPos = string.find(round, "_lock$")
	if lockPos then
		round = string.sub(round, 1, lockPos - 1)
	end
	-- 获得列下标
	if round == "top64" then
		roundIdx = 1

	elseif round == "top32" then
		roundIdx = 2

	elseif round == "top16" then
		roundIdx = 3

	elseif string.find(round, "%d$") then
		roundIdx = string.sub(round, #round, #round)
	end
	roundIdx = tonumber(roundIdx)
	return roundIdx
end

-- 获得第idx场的数据
function CrossCraftView.getRoundHistory(idx, round, history)
	local function isOK(flag)
		if string.find(round, "^pre%d") or round == "signup" or round == "prepare" or round == "halftime" or round == "prepare2" then
			local k = string.sub(round, 4, 4)
			if round == "signup" or round == "prepare" then
				k = 1

			elseif round == "halftime" or round == "prepare2" then
				k = 3
			end
			if flag == ("pre" .. k .. idx) then
				return true
			end
		end
		if string.find(round, "^final") or round == "closed" then
			if flag == ("final" .. idx) then
				return true
			end
		end
		if string.find(round, "^top") then
			if flag == "top64" and idx == 1 then
				return true
			end
			if flag == "top32" and idx == 2 then
				return true
			end
			if flag == "top16" and idx == 3 then
				return true
			end
		end
	end
	for _, data in ipairs(history) do
		if isOK(data.round) then
			return data
		end
	end
end

-- 设置第idx场的结果状态
function CrossCraftView.getArrayRoundResult(idx, round, history)
	local colIdx = CrossCraftView.getArrayRoundIdx(round)
	if idx > colIdx then
		return
	end
	if colIdx == idx then
		-- 锁定为战斗中
		if string.find(round, "_lock$") then
			return "inBattle"
		end
		return "inPrepare"
	end
	local data = CrossCraftView.getRoundHistory(idx, round, history)
	if not data then
		return "isOut"
	end
	return data.result
end

-- 设置第idx场的显示资源
function CrossCraftView.getArrayRoundRes(idx, round, history)
	local res = "txt_d" .. idx .. "c"
	if string.find(round, "^top") then
		if idx == 1 then
			res = "txt_32qs"

		elseif idx == 2 then
			res = "txt_16qs"

		elseif idx == 3 then
			res = "txt_8qs"
		else
			res = nil
		end

	elseif string.find(round, "^final") or round == "closed" then
		if idx == 1 then
			res = "txt_4qs"

		elseif idx == 2 then
			res = "txt_bjs"

		elseif idx == 3 then
			res = "txt_gjs"
			-- 角色数据有半决赛失败的，则显示为季军赛
			for _, data in ipairs(history) do
				if data.round == "final2" and data.result == "fail" then
					res = "txt_jjs0"
					break
				end
			end
		else
			res = nil
		end
	end
	if res then
		return "city/pvp/cross_craft/txt/" .. res .. ".png"
	end
end

return CrossCraftView