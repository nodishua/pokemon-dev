
local CrossUnionFightTools = require "app.views.city.union.cross_unionfight.tools"
local CrossUnionModel = require "app.views.city.union.cross_unionfight.model"

--跨服公会战主界面
local ViewBase = cc.load("mvc").ViewBase
local CrossUnionView = class("CrossUnionView", ViewBase)

CrossUnionView.RESOURCE_FILENAME = "cross_union.json"
CrossUnionView.RESOURCE_BINDING = {
	["integralRank"] = {
		varname = "integralRank",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("unionIntegral")}
		},
	},
	["embattle"] = {
		varname = "embattle",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("battlefieldZRView")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "crossUnionFight",
					onNode = function (node)
						node:xy(340, 140)
					end
				}
			}
		},
	},
	["rightBtn"] = "rightBtn",
	["rightBtn.rule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("rule")}
		},
	},
	["rightBtn.rule.name"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color=ui.COLORS.NORMAL.WHITE, size=3}}
			},
		}
	},
	["rightBtn.rankReward"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("rankReward")}
		},
	},
	["rightBtn.rankReward.name"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color=ui.COLORS.NORMAL.WHITE, size=3}}
			},
		}
	},
	["rightBtn.record"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("combatRecord")}
		},
	},
	["rightBtn.record.name"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color=ui.COLORS.NORMAL.WHITE, size=3}}
			},
		}
	},
	["rightBtn.guessing"] = {
		varname = "guessing",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("guessingView")}
		},
	},
	["rightBtn.guessing.name"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color=ui.COLORS.NORMAL.WHITE, size=3}}
			},
		}
	},
	["rightBtn.combat"] = {
		varname = "battlegroundNode",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("combatDistribution")}
		},
	},
	["rightBtn.combat.name"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color=ui.COLORS.NORMAL.WHITE, size=3}}
			},
		}
	},
	["combat"] = "combat",
	["combat.battlefield"] = {
		varname = "mainBattlefield",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("battlefield")}
		},
	},
	["combat.battlefieldZR"] = {
		varname = "battlefieldZR",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("battlefieldZRView")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "crossUnionFight",
					onNode = function (node)
						node:xy(340, 140)
					end
				}
			}
		},
	},
	["titlePanel"] = "titlePanel",
	["prepare"] = "prepare",
	["prepare.itemIcon"] = "itemIcon",
	["prepare.item"] = "item",
	["prepare.list"] = {
		varname = "prepareList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("quickDatas"),
				dataName = bindHelper.self("leftListName"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "list", "itemIcon")
					childs.name:text(list.dataName[k])
					childs.list:removeAllChildren()
					childs.itemIcon:hide()
					childs.list:setScrollBarEnabled(false)
					for i = 1, 4 do
						local item = childs.itemIcon:clone():show()
						childs.list:pushBackCustomItem(item)
						if v[i] then
							item:get("name"):text(v[i].union_name)
							adapt.setTextScaleWithWidth(item:get("name"), nil, 300)
							item:get("icon"):texture(csv.union.union_logo[v[i].union_logo].icon)
							item:get("title"):text(string.format(gLanguageCsv.brackets, getServerArea(v[i].server_key, nil)))
							item:get("num"):text(v[i].signs_count)
							adapt.oneLinePos(item:get("number"), item:get("num"))
						else
							item:get("icon"):hide()
							item:get("name"):hide()
							item:get("title"):hide()
							item:get("number"):hide()
							item:get("num"):hide()
							item:get("noBg"):show()
							item:get("no"):show()
						end
					end
				end,
			},
		}
	},
	["areaClothing"] = "areaClothing",
	["areaClothing.bg"] = "bg",
	["areaClothing.title1"] = "title1",
	["areaClothing.title2"] = "title2",
	["areaClothing.item"] = "arenaItem",
	["areaClothing.subList"] = "subList",
	["areaClothing.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("servers"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("arenaItem"),
				bg = bindHelper.self("bg"),
				title1 = bindHelper.self("title1"),
				title2 = bindHelper.self("title2"),
				columnSize = 4,
				onCell = function(list, node, k, v)
					node:get("server"):text(string.format(gLanguageCsv.brackets, getServerArea(v, nil)))
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
						local dy = height/2*(count-1)
						list:y(127 - dy)
						list.bg:height(122 + dy*2)
						list.title1:y(290 + dy)
						list.title2:y(55 - dy)
					end
				end
			},
		},
	},
	["panel.name"] = "name",
	["gameOver"] = "gameOver",
	["battle"] = "battle",
	["battle.final"] = {
		varname = "final",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("finalView")}
		},
	},
	["battle.preliminary"] = {
		varname = "preliminary",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("preliminaryView")}
		},
	},
	["bg"] = {
		varname = "viewBg",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("closeUnionInfo")},
			scaletype = 0,
		},
	},
	["mask"] = 'mask',
}


function CrossUnionView:onCreate(cb)
	self.cb = cb
	self.isFirst = true
	self.mainBattle = {}
	self.subView = {}

	self.topuiView = gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.ministryHouseBattle, subTitle = "Building war"})


	self.rankData = nil
	self:initModel()
	self:enableSchedule()
	local timeData = time.getNowDate()
	local wday = timeData.wday - 1
	self:unSchedule(10)
	self:unSchedule(20)

	self.combat:hide()
	idlereasy.when(self.status, function(_, status)
		self:onUpdateStatus(status)
	end)

	local lastRequestTime = 0
	--倒计时结束或战报结束自动请求战报
	idlereasy.when(self.automatic, function(_, automatic)
		if automatic == 2 then
			-- 时间到请求main
			if time.getTime() - lastRequestTime > 10 then
				lastRequestTime = time.getTime()
				gGameApp:requestServer("/game/cross/union/fight/main")
			end
		end
	end)
	self.isFirst = false

	self:schedule(function()
		local status = self.status:read()
		if status == "closed" then
			return
		end
		local delta = CrossUnionFightTools.getNextStateTime(status, self.time)
		if delta <= 0 then
			-- 时间到请求main
			if time.getTime() - lastRequestTime > 10 then
				lastRequestTime = time.getTime()
				gGameApp:requestServer("/game/cross/union/fight/main")
			end
		end
	end, 1, 1, 100)

end

function CrossUnionView:onUpdateStatus(status)
	self.saveStat = status
	if status ~= "closed" then
		self:unionClassifyDataView(status)
	end
	if status == "prePrepare" then
		self.model.finish = true
		self.prepare:hide()
		self:preparation()
		self:addAnimationView(true)
	elseif status == "preStart" then
		--比赛阶段(初赛)
		self.model.finish = true
		self:hideUselessUiView()
		self:countDownView(status)
		local roundView = "competition"
		if self.roles[self.roleId] then
			self.combat:show()
			roundView = "fight_messages"
		end

		self.roleView = roundView
		self:combatStage(roundView)

	elseif status == "preBattle" then
		--判断有没有资格参加初赛和决赛
		if self.roles[self.roleId] then
			self.model.distribute = CrossUnionFightTools.getDistribute(self.roles, self.roleId,1)
			self.roleView = "fight_messages"
			self.combat:show()
			self:timeFlow()
		else
			self.combat:hide()
			self.simulation = true
			self:timeFlow()
			self.roleView = "competition"
			self:combatStage("competition", true)
		end

	elseif status == "preOver" then
		if self:preOverView(status) then
			return
		end
		--状态发生变化不重新走流程，如果查看战报回来从新刷新
		if self.examineBattle ~= status and self.schdulelabel then
			--客户端播放战报时服务器跑完暂时不刷新
			return
		end

		if self.roles[self.roleId] then
			self.model.distribute = CrossUnionFightTools.getDistribute(self.roles, self.roleId,1)
			self.combat:show()
			self.roleView = "fight_messages"
		else
			self.combat:hide()
			self.simulation = true
			self.roleView = "competition"
		end
		self:timeFlow()

	elseif status == "preAward" then
		self:removeBattleView()
		self.model.finish = true
		self.combat:visible(self.roles[self.roleId] and true or false)
		self.roleView = "competition"
		self:combatStage("competition", not self.roles[self.roleId])

	elseif status == "topPrepare" then
		self.model.finish = true
		self.roleView = "competition"
		local whetherQualified = self:whetherQualified()
		if whetherQualified then
			self.combat:show()
		end
		self:combatStage("competition", not whetherQualified)

	elseif status == "topStart" then
		self.model.finish = true
		self:countDownView(status)
		self.roleView = "competition"
		local sign = false
		if self:whetherQualified() then
			self.roleView = "fight_messages"
			self.combat:show()
		else
			sign = true
			self.combat:hide()
		end
		self:combatStage(self.roleView, sign)

	elseif status == "topBattle" then
		--决赛是否有资格
		if self:whetherQualified() then
			self.model.distribute = CrossUnionFightTools.getDistribute(self.roles, self.roleId,2)
			self.roleView = "fight_messages"
			self.combat:show()
		else
			self.simulation = true
			self.roleView = "competition"
		end
		self:timeFlow()

	elseif status == "topOver" then
		if self.model.finish then
			self:gameoverView()
			return
		end

		--状态发生变化不重新走流程，如果查看战报回来从新刷新
		if self.examineBattle ~= status and self.schdulelabel then
			--客户端播放战报时服务器跑完暂时不刷新
			return
		end

		if self:whetherQualified() then
			self.model.distribute = CrossUnionFightTools.getDistribute(self.roles, self.roleId,2)
			self.combat:show()
			self.roleView = "fight_messages"
		else
			self.simulation = true
			self.topOverSign = true
			self.roleView = "competition"
		end
		self:timeFlow()

	elseif status == "closed" or status == "start" then
		--赛季结束:
		-- 1:结束界面展示三天
		self.battlegroundNode:hide()
		if CrossUnionFightTools.whetherCloseShowUI(self.csv_id) then
			self:gameoverView()
		else
			-- 2：新赛季开始状态
			local id = dataEasy.getCrossServiceData("crossunionfight")
			if id then
				local cfg = csv.cross.service[id]
				local tiem = time.getNumTimestamp(cfg.date, time.getRefreshHour())
				if tonumber(cfg.date) == tonumber(time.getTodayStrInClock()) then
					self:serviceArea(id)
				else
					self:notOpenView(cfg)
				end
			else
				-- 3：赛季未开始
				self:notOpenView()
			end
			self:addAnimationView()
		end
	end
end

function CrossUnionView:hideUselessUiView()
	self.integralRank:hide()
	self.embattle:hide()
	self.prepareList:show()
	self.viewBg:show()
	self.mask:hide()
	if self:getResourceNode():get("bgNode") then
		self:getResourceNode():get("bgNode"):removeSelf()
	end
end

function CrossUnionView:preOverView(status)
	if self.model.finish and status == "preOver" then
		self.roleView = "competition"
		self:combatStage("competition", not self.roles[self.roleId])
		return true
	end
	return false
end


--模拟倒计时
function CrossUnionView:countDownView(status)
	local tag = 33
	self:schedule(function()
		local delta = self:countDown(status)
		if delta <= 0 then
			self:unSchedule(tag)
			self.automatic:set(2, true)
			return
		end
	end, 1, 0, tag)
end


function CrossUnionView:addAnimationView(pause)
	self.viewBg:hide()
	self.rightBtn:hide()
	local anima = widget.addAnimation(self:getResourceNode(), 'cross_union/cbqd.skel', "effect_loop", 1)
		:scale(2)
		:xy(display.sizeInView.width/2, display.sizeInView.height/2)

	if pause then
		local size = display.sizeInView
		local scale = 0.5
		anima:pause()

		local sp = cc.utils:captureNodeSprite(self:getResourceNode(), cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565, scale, 0, 0)
			:scale(2)
			:setAnchorPoint(0.5, 0.5)

		-- 毛玻璃效果, 高斯模糊
		cache.setShader(sp, false, "gaussian_blur"):setUniformVec3("iResolution", cc.Vertex3F(size.width, size.height, 0))

		sp:xy(display.sizeInView.width/2, display.sizeInView.height/2):addTo(self:getResourceNode(), 1, "bgNode")
		self.mask:show()
		anima:removeSelf()
	end
	self.rightBtn:show()
end

function CrossUnionView:unionClassifyDataView(status)
	local site = nil	--自己公会所在场地
	local unionAll = 0
	if CrossUnionFightTools.getNowMatch(status) == 2 then
		for i,v in ipairs(self.top_battle_groups or {}) do
			if v.union_db_id == self.unionId then
				unionAll = v.signs_count
				break
			end
		end
	else
		for i,v in ipairs(self.unionClassifyData or {}) do
			for j, vv in ipairs(v) do
				if vv.union_db_id == self.unionId then
					unionAll = vv.signs_count
					site = i
					break
				end
			end
		end
	end
	self.groupingData = {site = site, unionAll = unionAll}
	self.model.unionAll = unionAll
end

--决赛是否有资格
function CrossUnionView:whetherQualified()
	local certification = false
	if self.roles[self.roleId] then
		for i,v in ipairs(self.top_battle_groups) do
			if v.union_db_id == self.unionId then
				certification = true
				break
			end
		end
	end
	return certification
end


function CrossUnionView:initModel()
	if not self.model then
		self.model = CrossUnionModel.new()
	end
	self.unionClassifyData = gGameModel.cross_union_fight:read("pre_battle_groups")	--匹配到的公会
	self.top_battle_groups = gGameModel.cross_union_fight:read("top_battle_groups") --决赛匹配到的公会
	self.model.unionClassifyData = self.unionClassifyData
	self.model.top_battle_groups = self.top_battle_groups
	self.model:differentUnion()
	self.roles = gGameModel.cross_union_fight:read("roles")
	self.csv_id = gGameModel.cross_union_fight:read("csv_id")	--开赛配置id
	self.time = gGameModel.cross_union_fight:read("date")	--开赛时间
	self.status = gGameModel.cross_union_fight:getIdler("status")
	self.examineBattle = self.status:read()
	self.model.status = self.examineBattle
	self.unions = gGameModel.cross_union_fight:read("unions")
	self.unionId = gGameModel.union:read("id")
	self.roleId = gGameModel.role:read("id")
	self.model.unionId = self.unionId
	self.model.roleId = self.roleId
	self.quickDatas = idlertable.new({})
	self.localUnionData = idlertable.new({})
	self.servers = idlers.newWithMap({})	--匹配到的区服
	self.battleId = 1
	self.leftListName = {}	--页签
	self.groupingData = {} --自己公会所在分组数据
	self.saveUnionData = {} --实时计算公会状态
	self.automatic = idler.new(1)

	self.battleRound = 0	--服务器战报的最大轮次
	self.gameModel = {}
	self.localModel = {}
	for i = 1, 3 do
		self.localModel[i] = {currentFrameId = 0 , endFrameId = 0, status = "",}
		self.gameModel[i] = {}
	end
	self.viewSchdule = false --界面是否完成
	self.model.battleRound = 1
end

--未开赛(周一到周四)
function CrossUnionView:notOpenView(cfg)
	self.gameOver:hide()
	self.titlePanel:show()
	self.integralRank:show()
	self.titlePanel:get("title"):text(gLanguageCsv.unionfightComing)
	self.titlePanel:get("starTime"):text(gLanguageCsv.openingTime)
	self.titlePanel:get("time"):hide()
	self.titlePanel:get("starTime"):hide()

	if cfg and cfg.date then
		local startTime = time.getNumTimestamp(tonumber(cfg.date), time.getRefreshHour())
		local timeTab = time.getDate(startTime)
		self.titlePanel:get("time"):text(string.format("%s.%s.%s", timeTab.year, timeTab.month, timeTab.day))
		self.titlePanel:get("time"):show()
		self.titlePanel:get("starTime"):show()
	end

	local color = cc.c4b(95, 73, 55, 255)
	text.addEffect(self.titlePanel:get("starTime"), {outline={color=color, size=6}})
	text.addEffect(self.titlePanel:get("time"), {outline={color=color, size=6}})
	text.addEffect(self.titlePanel:get("title"), {outline={color=color, size=6}})
	local posX = self.titlePanel:get("title"):x()
	local posY = self.titlePanel:get("starTime"):y()
	self.battlegroundNode:hide()
	adapt.oneLineCenterPos(cc.p(posX, posY), {self.titlePanel:get("starTime"), self.titlePanel:get("time")}, cc.p(20, 0))

	self:removeBattleView()
end

function CrossUnionView:removeBattleView()
	if self.mainBattle.view then
		self.mainBattle.view:removeSelf()
		self.mainBattle = {}
	end
	if self.subView.view then
		self.subView.view:removeSelf()
		self.subView = {}
	end
end

--公会积分
function CrossUnionView:unionIntegral()
	if self.unionPoint then
		gGameUI:stackUI("city.union.cross_unionfight.score", nil, nil, self.unionPoint)
	else
		gGameApp:requestServer("/game/cross/union/fight/point/rank", function (tb)
			self.unionPoint = tb.view
			gGameUI:stackUI("city.union.cross_unionfight.score", nil, nil, tb.view)
		end, 1, 50)
	end
end

--规则
function CrossUnionView:rule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1326})
end

function CrossUnionView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rule)
		end),
		c.noteText(125501, 125599),
	}
	local pre = 0
	local top = 0
	for k, v in orderCsvPairs(csv.cross.union_fight.rank_award) do
		if v.type == 1 and pre == 0 then
			pre = 1
			table.insert(context,"#L10##C0xF76B45#"..gLanguageCsv.preliminary)
		elseif v.type == 2 and top == 0 then
			top = 2
			table.insert(context,"#L10##C0xF76B45#"..gLanguageCsv.finalMatch)
		end
		table.insert(context, c.clone(view.awardItem, function(item)
			local childs = item:multiget("text", "list")
			childs.text:text(string.format(gLanguageCsv.rankSingle, v.rank))
			uiEasy.createItemsToList(view, childs.list, v.award)
		end))
	end
	return context
end

--排行榜
function CrossUnionView:rankReward()
	self:requestRankData(function(rankData)
		gGameUI:stackUI("city.union.cross_unionfight.rank", nil, nil, rankData, self.model)
	end)
end

--上期回顾
function CrossUnionView:combatRecord()
	if self.saveStat == "closed" or (self.model.finish and self.saveStat == "topOver") then
		if self.battleData then
			if itertools.isempty(self.battleData) then
				gGameUI:showTip(gLanguageCsv.crossUnionUnionNoBattle)
				return
			else
				self.combat:hide()
				self:requestRankData(function(rankData)
					gGameUI:stackUI("city.union.cross_unionfight.competition", nil, nil, self.model, self.battleData, rankData)
				end)
				return
			end
		end

		gGameApp:requestServer("/game/cross/union/fight/last/battle",function (tb)
			self.battleData = tb.view
			if itertools.isempty(tb.view) then
				gGameUI:showTip(gLanguageCsv.crossUnionUnionNoBattle)
				return
			else
				self.combat:hide()
				self:requestRankData(function(rankData)
					gGameUI:stackUI("city.union.cross_unionfight.competition", nil, nil, self.model, self.battleData, rankData)
				end)

			end
		end)
	else
		gGameUI:showTip(gLanguageCsv.crossUnionUnionNoCheck)
	end
end

--竞猜
function CrossUnionView:guessingView()
	local type = CrossUnionFightTools.getNowMatch(self.saveStat)
	if (self.saveStat == "closed" and not CrossUnionFightTools.whetherCloseShowUI(self.csv_id)) or self.saveStat == "start" then
		gGameUI:showTip(gLanguageCsv.unionCrossCraftNotBet)
	else
		if self.betData then
			self:requestRankData(function(rankData)
				gGameUI:stackUI("city.union.cross_unionfight.bet", nil, {full = true}, self.betData, rankData)
			end)
		else
			gGameApp:requestServer("/game/cross/union/fight/bet/info", function (tb)
				self.betData = tb.view
				self:requestRankData(function(rankData)
					gGameUI:stackUI("city.union.cross_unionfight.bet", nil, {full = true}, tb.view, rankData)
				end)
			end, type)
		end
	end
end


--战场分布
function CrossUnionView:combatDistribution()
	if (self.saveStat == "closed" and not CrossUnionFightTools.whetherCloseShowUI(self.csv_id)) then
		gGameUI:showTip(gLanguageCsv.crossUnionOver)
		return
	end
	gGameApp:requestServer("/game/cross/union/fight/deploy/roles", function(tb)
		self.distributeData = tb.view
		local group = self.groupingData.site or 5
		local roles =  gGameModel.cross_union_fight:read("roles")
		local dataTransform = function(role)
			local data = {}
			for i, v in pairs(role) do
				data[v.role_db_id] = data[v.role_db_id] and data[v.role_db_id] or {}
				data[v.role_db_id].troop_card_state = {}
				for key, val in pairs(v.card_state or {}) do
					for kk, vv in pairs(val or {}) do
						data[v.role_db_id].troop_card_state[kk] = vv
					end
				end
				--data[v.role_db_id].troop_card_state = v.card_state
				data[v.role_db_id].troop = v.cur_troop
			end
			return data
		end
		if self.saveStat == "preAward" or self.saveStat == "closed" or (self.model.finish and self.saveStat == "preOver") or (self.model.finish and self.saveStat == "topOver") then
			-- 此时数据可从main数据中获得
			if roles then
				-- set localUnionData
				local dt = dataTransform(table.deepcopy(roles))
				self.localUnionData:set(dt, true)
				local _,_,data = self:getDistributionInfo(tb)
				if not data then
					gGameUI:showTip(gLanguageCsv.crossUnionFightNoDistributed)
				else
					gGameUI:stackUI("city.union.cross_unionfight.distributed", nil, {full = true}, self:createHandler("getDistributionInfo"))
				end
			end
		else
			local _,_,data = self:getDistributionInfo(tb)
			if not data then
				gGameUI:showTip(gLanguageCsv.crossUnionFightNoDistributed)
			else
				gGameUI:stackUI("city.union.cross_unionfight.distributed", nil, {full = true}, self:createHandler("getDistributionInfo"))
			end
		end
	end, CrossUnionFightTools.getNowMatch(self.saveStat),self.unionId)
end

function CrossUnionView:getDistributionInfo()
	local type = CrossUnionFightTools.getNowMatch(self.saveStat)
	local battle = {"pre_deploy_roles", "top_deploy_roles"}
	local unions = gGameModel.cross_union_fight:read("unions")
	local data = self.distributeData and self.distributeData[battle[type]]
	return self.localUnionData, self.unionId, self.distributeData.deploy_roles, type
end


--主赛场
function CrossUnionView:battlefield()
	local viewName = self.roleView == "fight_messages" and "competition" or "fight_messages"
	local name = self.roleView == "fight_messages" and gLanguageCsv.roleBattlefield or  gLanguageCsv.mainBattlefield
	local sign = true
	if viewName == "fight_messages" then
		local idx, preliminaryState = self.model:battleground(self.unionClassifyData, self.unionId, self.saveStat)
		if idx and preliminaryState then
			gGameApp:requestServer("/game/cross/union/fight/last/battle", function(tb)
				self.model:setLastBattle(tb.view)
				gGameUI:stackUI("city.union.cross_unionfight.fight_playback", nil, nil, self.model, CrossUnionModel.MatchStage.Preliminary, self.model:getLastBattle(idx) or {})
			end)
			sign = false
		else
			self:showSubView(viewName)
		end
	else
		self:showMainBattleView(viewName)
	end
	if sign then
		self.roleView = viewName
		self.mainBattlefield:get("name"):text(name)
	end
end

--上期回顾(决赛)
function CrossUnionView:finalView()
	self.final:get('btn'):texture("common/btn/btn_normal.png")
	self.preliminary:get('btn'):texture("common/btn/btn_recharge.png")
end

--上期回顾(初赛)
function CrossUnionView:preliminaryView()
	self.preliminary:get('btn'):texture("common/btn/btn_normal.png")
	self.final:get('btn'):texture("common/btn/btn_recharge.png")
end

--战场阵容
function CrossUnionView:battlefieldZRView()
	local type = CrossUnionFightTools.getNowMatch(self.saveStat)
	gGameModel.forever_dispatch:getIdlerOrigin("crossUnionFightTime"):set(tonumber(time.getTodayStr()))
	local myData, sign = {}, 1
	for i, v in pairs(self.roles) do
		if i == self.roleId then
			myData = v
			break
		end
	end
	if not itertools.isempty(myData) then
		sign = myData.projects[type]
		userDefault.getForeverLocalKey("crossUnionFightEmbattle", false)
		gGameUI:stackUI("city.union.cross_unionfight.embattle", nil, {full = true}, {type = type, sign = sign})
	else
		gGameUI:showTip(gLanguageCsv.unionFightNotInFinal)
	end
end

--赛季开放当周周四匹配的区服展示
function CrossUnionView:serviceArea(id)
	self.battlegroundNode:hide()
	self.areaClothing:show()
	self.integralRank:show()
	text.addEffect(self.title1, {outline={color=cc.c4b(95, 73, 55, 255), size=6}})
	text.addEffect(self.title2, {outline={color=cc.c4b(95, 73, 55, 255), size=6}})
	local cfg = csv.cross.service[id]
	self.servers:update(getMergeServers(cfg.servers))
end

--赛季开放当周周5确定竞标团
function CrossUnionView:preparation()
	self.prepare:show()
	self.prepareList:show()
	self.integralRank:hide()
	self.areaClothing:hide()
	self.titlePanel:hide()
	self.combat:hide()
	self.prepare:get("title"):show()
	self.prepare:get("title"):text(gLanguageCsv.crossUnionFightPrepare)

	text.addEffect(self.prepare:get("title"), {outline={color=ui.COLORS.NORMAL.DEFAULT, size = 4}})

	for i = 1, 4 do
		self.leftListName[i] = gLanguageCsv["buildOrganization" .. i] .. gLanguageCsv.organization
	end
	self.quickDatas:set(self.unionClassifyData)

	if not self.roles[self.roleId] then
		self.battlegroundNode:hide()
		self.embattle:hide()
	else
		self.battlegroundNode:show()
		self.embattle:show()
	end
end

--比赛阶段(晚上8:50)
function CrossUnionView:combatStage(viewName, qualification)
	self.integralRank:hide()
	self.titlePanel:hide()
	self.prepare:hide()
	if qualification then
		self.battlegroundNode:hide()
		self.combat:hide()
	end

	if viewName == "fight_messages" and (not self.subView.view) then
		self:showSubView(viewName)
		self.mainBattlefield:get("name"):text(gLanguageCsv.mainBattlefield)

	elseif viewName == "competition" and (not self.mainBattle.view) then
		self.mainBattlefield:get("name"):text(gLanguageCsv.roleBattlefield)
		self:showMainBattleView(viewName)
	end
end

-- 我的赛场
function CrossUnionView:showSubView(viewName, ...)
	if viewName then
		if self.mainBattle.view then
			self.mainBattle.view:removeSelf()
			self.mainBattle = {}
		end

		if self.subView.view then
			self.subView.view:show()
		else
			self.subView = {
				name = "fight_messages",
				view = gGameUI:createView("city.union.cross_unionfight.fight_messages", self:getResourceNode()):init(self.model):x(display.uiOrigin.x)
			}
		end
	end
end

--主赛场
function CrossUnionView:showMainBattleView(viewName, ...)
	if viewName then
		local status = self.saveStat
		local sign = false
		--如果在over状态客户端还没有模拟玩就继续显示模拟战报状态
		if not self.model.finish and (status == "preOver" or status == "topOver") then
			sign = true
		end
		if sign or itertools.include({"preBattle", "preStart", "topBattle", "topStart"}, status) then
			if self.subView.view then
				self.subView.view:closeUnionInfoView()
				self.subView.view:hide()
			end
		else
			if self.subView.view then
				self.subView.view:removeSelf()
				self.subView = {}
			end
		end

		if not self.mainBattle.view then
			self.mainBattle = {
				name = viewName,
				view = gGameUI:createView("city.union.cross_unionfight.competition", self:getResourceNode()):init(self.model):x(display.uiOrigin.x)
			}
		end
	end
end


function CrossUnionView:closeUnionInfo()
	if self.subView.view then
		self.subView.view:closeUnionInfoView()
	end
end

--对战倒计时
function CrossUnionView:countDown(condition)
	if condition == "preStart" or condition == "topStart" then
		local t = time.getTimeTable()
		t.hour, t.min, t.sec = 21, 0, 0
		local countDown = 0
		local presentTime = time.getNowDate()
		countDown = time.getTimestamp(t) - time.getTimestamp(presentTime)
		if countDown <= 0 then
			countDown = 0
		end
		return countDown
	end
end


function CrossUnionView:requestBattle(isHas)
	local group = self.groupingData.site or 5
	if (self.saveStat == "preOver" or self.saveStat == "preBattle") and not self.roles[self.roleId] then
		group = 1
	end
	local squad = group == 5 and 1 or group
	self.model.squad = squad
	--同时对三组请求战报
	local tab = {}
	for i=1, 3 do
		tab[i] = self.localModel[i].endFrameId + 1
	end
	local round = 0
	performWithDelay(self, function()
		gGameApp:requestServer("/game/cross/union/fight/battle/result", function (tb)
			if tb.view.status then
				if self.saveStat ~= tb.view.status then
					self.automatic:set(2, true)
				end
			end
			for i = 1, 3 do
				local gameModel = tb.view.results[i]
				if gameModel and #gameModel > 0 then
					if gameModel[#gameModel].round > self.battleRound then
						self.battleRound = gameModel[#gameModel].round
						round = i
					end
					self.localModel[i].endFrameId = #gameModel + self.localModel[i].endFrameId
					if self.saveStat == "topOver" or self.saveStat == "preOver" then
						self.localModel[i].currentFrameId = self.localModel[i].endFrameId
					end
					for _, v in ipairs(gameModel) do
						table.insert(self.gameModel[i], v)
						table.insert(self.model.saveBattleData[squad], v)
					end
				end
			end
			if round > 0 then
				self.battleId = round
			end

			--先走请求在有界面显示
			if isHas then
				self:interfaceShow()
			end
			--现有请求在右倒计时
			self.schdulelabel = true
		end, group, tab)
	end, 0)
end

--对战流
function CrossUnionView:timeFlow()
	if not self.simulation then
		self.mainBattlefield:get("name"):text(gLanguageCsv.mainBattlefield)
	end

	local tag = 10
	self:unSchedule(tag)
	self.finish = false

	self.schdulelabel = false
	self:requestBattle(true)
	local tt = 33
	self:schedule(function(dt)
		if self.schdulelabel then
			if self.localModel[self.battleId].currentFrameId >= self.localModel[self.battleId].endFrameId and CrossUnionFightTools.battleStateView(true, self.saveStat) then
				self:unSchedule(tag)
				self.finish = true
				return
			end
			--异常
			if self.localModel[self.battleId].currentFrameId >= self.localModel[self.battleId].endFrameId and CrossUnionFightTools.battleStateView(nil, self.saveStat) then
				tt = tt - 1
				if tt <= 0 then
					tt = 33
					self:requestBattle()
				end
			else
				self.localModel[self.battleId].currentFrameId = self.localModel[self.battleId].currentFrameId + 1
			end
			--提前6个走请求
			if self.localModel[self.battleId].currentFrameId == self.localModel[self.battleId].endFrameId  - 6 then
				self:requestBattle()
			end
		end
	end, 0.33, 1, tag)
end

--退出重进自动计算播放几轮战报
function CrossUnionView:voluntarilyView()
	local countTime = gCommonConfigCsv["crossUnionBattleReportTime"]
	local t = time.getTimeTable()
	t.hour, t.min, t.sec = 21, 0, 0
	local presentTime = time.getNowDate()
	local countDown = time.getTimestamp(presentTime) - time.getTimestamp(t)
	local voluntarily = math.floor(countDown/countTime)
	voluntarily = voluntarily <= 0 and 1 or voluntarily
	return voluntarily
end


--界面显示
function CrossUnionView:interfaceShow()
	local tag = 20
	local countTime = gCommonConfigCsv["crossUnionBattleReportTime"]
	local tt = countTime
	local downCountFunc = function(await)
		if not self.simulation then
			if self.subView.view then
				self.subView.view:updataBattleReport(2, self.viewSchdule, self.gameModel, await, self.model)
			else
				self.subView = {
					name = "fight_messages",
					view = gGameUI:createView("city.union.cross_unionfight.fight_messages", self:getResourceNode()):init(self.model):x(display.uiOrigin.x)
				}
				self.subView.view:updataBattleReport(2, self.viewSchdule, self.gameModel, await, self.model)
			end
		end
		self:cardState()
	end

	local voluntarily = self:voluntarilyView()
	--服务器状态是否结束
	local condition = function(isHas)
		local stats = self.saveStat
		--战斗过程中如果是preAward(九点半)状态直接结束,如果是preOver状态(服务器跑完战报)客户单根据播放战报速度自己模拟
		if isHas then
			return stats == "preAward"
		end
		if stats == "preOver" or stats == "preAward" or stats == "topOver" then
			return true
		end
		return false
	end

	self:unSchedule(tag)
	--战斗结束(战报已播完)
	if condition(true) then
		self.model.battleRound = self.battleRound
		self.model.finish = true
		self.viewSchdule = true
		self:combatStage(self.roleView, self.topOverSign)
		downCountFunc()
	elseif condition() and voluntarily >= self.battleRound then
		self.model.battleRound = self.battleRound
		self.model.finish = true
		self.viewSchdule = true
		if self:preOverView(self.saveStat) then
			return
		end

		if self.saveStat == "topOver" then
			self:gameoverView()
			return
		end
		self:combatStage(self.roleView, self.topOverSign)
		downCountFunc()

	else

		--表现上至少比服务器给的轮次少一轮(当前轮次不确定是否结束，故不展示)
		local uiBattleRound = self.battleRound <= 1 and 1 or self.battleRound
		if not self.finish then
			uiBattleRound = self.battleRound <= 1 and 1 or self.battleRound - 1
		end

		self.model.battleRound = voluntarily >= uiBattleRound  and uiBattleRound or voluntarily
		self:combatStage(self.roleView, self.topOverSign)
		downCountFunc(self.battleRound == 0)
		self:schedule(function(dt)
			tt = tt - 1
			if self.finish then
				uiBattleRound = self.battleRound <= 1 and 1 or self.battleRound
			else
				uiBattleRound = self.battleRound <= 1 and 1 or self.battleRound - 1
			end
			self.model.countDown = tt
			if tt <= 0 then
				tt = countTime
				if uiBattleRound >= self.model.battleRound then
					if self.finish and uiBattleRound == self.model.battleRound and condition() then
						self.model.battleRound = self.model.battleRound + 1
						self.viewSchdule = true
						self.model.finish = true
						downCountFunc()
					else
						self.model.battleRound = self.model.battleRound + 1
						downCountFunc()
					end

				elseif self.finish then
					self:unSchedule(tag)
					self:overView()
					return
				else
					downCountFunc(true)
				end
			end
		end, 1, 1, tag)
	end
end

--over阶段模拟完轮次自动跳转
function CrossUnionView:overView()
	if self.saveStat == "topOver" then
		self:gameoverView()
	elseif self.saveStat == "preOver" then
		self:combatStage("competition", not self.roles[self.roleId])
	end
end


--计算当前轮次时自己公会玩家状态
function CrossUnionView:cardState()
	local round = self.model.battleRound -1
	self.saveUnionData = CrossUnionFightTools.unionMembersState(self.gameModel, self.unionId, self.saveUnionData, round)
	self.localUnionData:set(self.saveUnionData, true)
end

function CrossUnionView:gameoverView()
	display.director:setProjection(cc.DIRECTOR_PROJECTION_3D)
	self:requestRankData(function(rankData)
		self:removeBattleView()

		self.viewBg:show()
		self.viewBg:texture("city/union/cross_unionfight/img_bwdzz_js.png")
		self.battlegroundNode:show()
		self.gameOver:show()
		self.rightBtn:show()
		self.integralRank:show()
		self.combat:hide()

		local rotateY = {20, -12, 18, 13}
		local scale = {1.2, 1.05, 0.9, 0.8}
		local posY = {883, 684, 550, 410}
		for i, v in ipairs(rankData.last_ranks[5]) do
			self.gameOver:get("panel" .. i):get("name"):text(v.union_name)
			adapt.setTextScaleWithWidth(self.gameOver:get("panel" .. i):get("name"), nil, 300)
			self.gameOver:get("panel" .. i):get("server"):text(string.format(gLanguageCsv.brackets, getServerArea(v.server_key, nil)))
			self.gameOver:get("panel" .. i):get("icon"):texture(csv.union.union_logo[v.union_logo].icon)
			self.gameOver:get("panel" .. i):setRotation3D({y = rotateY[i] or 0})
			self.gameOver:get("panel" .. i):scale(scale[i] or 1)
			if posY[i] then
				self.gameOver:get("panel" .. i):y(posY[i])
			end
		end

		local id = dataEasy.getCrossServiceData("crossunionfight")
		if id then
			local cfg = csv.cross.service[id]
			local startTime = time.getNumTimestamp(cfg.date, time.getRefreshHour())
			local timeTab = time.getDate(startTime)			
			self.gameOver:get("time"):text(string.format("%s.%s.%s", timeTab.year, timeTab.month, timeTab.day))
			self.gameOver:get("timeTitle"):text(gLanguageCsv.crossUnionNextIssue)
			self.gameOver:get("time"):show()
			self.gameOver:get("timeTitle"):show()
			local posX = self.gameOver:get("title"):x()
			local posY = self.gameOver:get("time"):y()
			adapt.oneLineCenterPos(cc.p(posX, posY), {self.gameOver:get("timeTitle"), self.gameOver:get("time")}, cc.p(5, 0))
		else
			self.gameOver:get("time"):hide()
			self.gameOver:get("timeTitle"):hide()
		end

		self.gameOver:get("title"):text(gLanguageCsv.gameOverTitle)
	end)
end

function CrossUnionView:requestRankData(cb)
	if self.rankData then
		return cb(self.rankData)
	end
	if self.isFirst then
		self:hide()
	end
	gGameUI:disableTouchDispatch(0.01)
	-- 延迟一帧请求，界面恢复当前帧请求会有 onSwitchUI but requesting from
	performWithDelay(self, function()
		gGameApp:requestServer("/game/cross/union/fight/rank", function(tb)
			self:show()
			self.rankData = tb.view
			cb(self.rankData)
		end)
	end, 0)
end

function CrossUnionView:onCleanup()
	display.director:setProjection(cc.DIRECTOR_PROJECTION_2D)
	self:removeBattleView()

	ViewBase.onCleanup(self)
end

function CrossUnionView:onClose()
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return CrossUnionView

