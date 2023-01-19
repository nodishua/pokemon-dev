local CrossUnionMainView = require "app.views.city.union.cross_unionfight.view"
local CrossUnionFightTools = require "app.views.city.union.cross_unionfight.tools"
local TAG = 50



local FightMessageView = class("FightMessageView", cc.load("mvc").ViewBase)
FightMessageView.RESOURCE_FILENAME = "cross_union_fight.json"
FightMessageView.RESOURCE_BINDING = {
	['leftPanel'] = "leftPanel",
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				betType = bindHelper.self("betType"),
				item = bindHelper.self("tabItem"),
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
						panel:get("txt2"):text(v.subName)
					end
					adapt.setTextScaleWithWidth(panel:get("txt"), v.name, 300)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabItemClick"),
			},
		},
	},
	["centerPanel"] = "centerPanel",
	["centerPanel.duckPanel"] = "duckPanel",
	["centerPanel.slider"] = "slider",
	["centerPanel.item"] = "item",
	['centerPanel.list'] = "fightList",
	['centerPanel.competition'] = "competition",
	["centerPanel.item.panel.left.team"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(139, 119, 84, 255), size = 3}},
		},
	},
	["centerPanel.item.panel.right.team"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(139, 119, 84, 255), size = 3}},
		},
	},
	["centerPanel.item.panel.left.lv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(91, 84, 91, 255), size = 3}},
		},
	},
	["centerPanel.item.panel.right.lv"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(91, 84, 91, 255), size = 3}},
		},
	},
	["centerPanel.item.panel.left.level"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(91, 84, 91, 255), size = 3}},
		},
	},
	["centerPanel.item.panel.right.level"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(91, 84, 91, 255), size = 4}},
		},
	},
	["centerPanel.404Panel"] = "404Panel",
	["centerPanel.upItem"] = "upItem",
	["centerPanel.unionZB"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("unionBattlefieldReport")}
		},
	},
	["centerPanel.roleZB"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("roleBattlefieldReport")}
		},
	},
	["centerPanel.unionZB.choose"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("unionChoose")
		},
	},
	["centerPanel.roleZB.choose"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("roleChoose")
		},
	},
	["integral"] = "integral",
	["integral.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("unionInfoView")}
		},
	},
	["unionInfo"] = {
		varname = "unionInfo",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("closeUnionInfoView")},
			scaletype = 0
		},
	},
	["bg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("closeUnionInfoView")},
			scaletype = 0
		},
	},

}


function FightMessageView:pushItemInitialize(v, isActioner, status, await)
	self.fightList:show()
	local item = self.item:clone():show()
	item.itemSign = v.itemSign
	item.roundTime = v.roundTime
	item.roundTimeSign = v.roundTimeSign

	if isActioner then
		self.fightList:insertCustomItem(item, 0)
		CrossUnionFightTools.onInitItem(self.fightList, item, v, self, status)
		local container = self.fightList:getInnerContainer()
		container:setPositionY(self.listY)
	else
		self.fightList:pushBackCustomItem(item)
		CrossUnionFightTools.onInitItem(self.fightList, item, v, self, status)
		if self.await or await then
			if item and item.roundTime == "roundCountDown" and not item.roundTimeSign then
				item.roundTimeSign = true
				item:get("round.time"):hide()
				item:get("round.over"):hide()
				local str1 = item:get("round.round"):getString()
				local str2 = gLanguageCsv.stateFighting .. gLanguageCsv.ltaskRunning .. ".."
				item:get("round.round"):text(str1 .. str2)
			end
		end
	end
end


function FightMessageView:onCreate(model)
	self:initModel(model)
	self:enableSchedule()
	self:survivalNumber()
	self.fightList:removeAllChildren()
	--左侧标签栏
	local tabDatas ={
		[1] = {name = gLanguageCsv.sixMankindConstruction, subName = "Preliminary",  select = false},
		[2] = {name = gLanguageCsv.fourMankindConstruction, subName = "Consumable", select = false},
		[3] = {name = gLanguageCsv.oneMankindConstruction, subName = "Material", select = false},
	}

	self.tabDatas = idlers.newWithMap(tabDatas)
	self.betType = idler.new(1)
	self.betType:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
	end)

	--全部/公会/自己(筛选战报)
	self.unionChoose = idler.new(false)
	self.roleChoose = idler.new(false)

	idlereasy.when(self.status, function(_, status)
		if status == "preStart" or status == "topStart" then
			self:updataBattleReport(1)
		elseif status == "preBattle" or status == "topBattle" then
			if not self.listY then
				self.fightList:removeAllChildren()
			end
		end
		local str = CrossUnionFightTools.getNowMatch(status) == 1 and gLanguageCsv.preliminary or gLanguageCsv.finalMatch
		self.competition:text(str)
	end)

	--分组/当前轮次/公会成员战报/自己战报
	idlereasy.any({self.unionChoose, self.roleChoose, self.betType}, function()
		local unionChoose = self.unionChoose:read()
		local roleChoose = self.roleChoose:read()
		local betType = self.betType:read()
		self:closeUnionInfoView()
		if not self.firstTime then return end
		-- 战报回放
		if not self.gameData or not self.gameData[betType] then
			return
		end
		local gameData = self.gameData[betType]
		self:operationbattleDataView(unionChoose, roleChoose, gameData, self.finish)
	end)
	
end


function FightMessageView:operationbattleDataView(unionChoose, roleChoose, gameData, finish, action)
	self.fightList:setScrollBarEnabled(false)
	self.duckPanel:hide()
	self:unSchedule(TAG)
	self:enableAsyncload()

	local status = self.status:read()
	local roleRound = self.model.battleRound
	local addItemNum = 0
	local satisfy = false
	local condition = self.condition
	local roundIdx = 0
	local sign = false	--在战场/公会/自己筛选时某轮次可能没有战报
	--第一轮默认是1，但是表现上做第一轮倒计时，不过放第一轮战报，以此类推
	local battleData = {}
	local saveRound = 0
	self.fightList:jumpToPercentVertical(0)
	if roleRound > 1 then
		for i, data in ipairs(gameData) do
			--数据自己自己计算，但是变现时根绝倒计时显示战报(insertIdx上次播放战报的轮次，做累加)
			if roleRound > data.round or finish then
				satisfy = CrossUnionFightTools.comparison({unionChoose, roleChoose}, data, self.unionId, self.roleId)
				--选择(自己/公会)战报时过滤掉其他战报
				if satisfy then
					sign = true
					if roundIdx ~= data.round then
						roundIdx = data.round
						addItemNum = addItemNum + 1
						table.insert(battleData, {roundTime = true, numRoundBattle = true, round = data.round})
					end
					table.insert(battleData, data)
					addItemNum = addItemNum + 1
				end
			else
				if saveRound <= data.round then
					saveRound =  data.round
				end
			end
		end
	end
	local asyncLoad = function()
		for i, v in ipairs(battleData) do
			self:pushItemInitialize(v, false, status)
			coroutine.yield()
		end
	end

	local finishView = function()
		--记录上一次战报轮次
		if roleRound > 1 then
			self.insertIdx = roleRound - 1
		end

		local awaitBattle = false
		if addItemNum == 0 or (roleRound - 1 > saveRound and addItemNum > 0) then
			awaitBattle = true
		end

		--是否胜利/自己淘汰/公会淘汰
		if sign or roleRound == 1 then
			if finish then
				local str = self.unionAlive > 0 and gLanguageCsv.crossUnionUnionBattleSucceed or gLanguageCsv.crossUnionUnionBattleFailure
				self:pushItemInitialize({time = true, itemUp = true, title = str}, false, status)
			else
				if self.unionAlive <= 0 then
					self:pushItemInitialize({time = true, itemUp = true, title = gLanguageCsv.crossUnionUnionBattleFailure, itemSign = true}, false, status)
				elseif condition then
					self:pushItemInitialize({time = true, itemUp = true, title = gLanguageCsv.crossUnionBattleFailure, itemSign = true}, false, status)
				else
					local labelround = roleRound <= 1 and 1 or roleRound
					self:pushItemInitialize({anima = true, itemSign = true}, false, status)
					self:pushItemInitialize({round = labelround, roundTime = "roundCountDown", itemSign = true}, false, status, awaitBattle)
				end
			end
		end

		if self.fightList:getChildrenCount() == 0 then
			if not finish then
				self:pushItemInitialize({anima = true, itemSign = true}, false, status)
				self:pushItemInitialize({round = 1, roundTime = "roundCountDown", itemSign = true}, false, status, awaitBattle)
			else
				self.slider:hide()
				self.fightList:setScrollBarEnabled(false)
				self.duckPanel:show()
				self.duckPanel:get("txt"):text(gLanguageCsv.battleReportNotData)
			end
		else
			self.duckPanel:hide()
		end
	end

	self.fightList:removeAllChildren()
	finishView()
	self:enableAsyncload()
		:asyncFor(asyncLoad, nil, 4)

end


--如果是手动操作就清空list从新push做筛选处理，如果是根据倒计时做累加处理
function FightMessageView:battleDataView(unionChoose, roleChoose, gameData, finish, action)
	self.duckPanel:hide()
	self:enableAsyncload()
	--战报没有给到但是结算没有结束时
	local battleAwait = false
	if self.await then
		for i = 1, 3 do
			local item = self.fightList:getItem(i)
			if item and item.roundTime == "roundCountDown" and not item.roundTimeSign then
				item.roundTimeSign = true
				item:get("round.time"):hide()
				item:get("round.over"):hide()
				local str1 = item:get("round.round"):getString()
				local str2 = gLanguageCsv.stateFighting .. gLanguageCsv.ltaskRunning .. ".."
				item:get("round.round"):text(str1 .. str2)
				battleAwait = true
			end
		end
	end

	if battleAwait then return end
	local status = self.status:read()
	local roleRound = self.model.battleRound
	local addItemNum = 0
	local satisfy = false
	local condition = self.condition
	local roundIdx = 0
	local sign = false	--在战场/公会/自己筛选时某轮次可能没有战报
	--第一轮默认是1，但是表现上做第一轮倒计时，不过放第一轮战报，以此类推
	if roleRound > 1 then
		for i, data in ipairs(gameData) do
			--数据自己自己计算，但是变现时根绝倒计时显示战报(insertIdx上次播放战报的轮次，做累加)
			if roleRound > data.round and data.round > self.insertIdx then
				satisfy = CrossUnionFightTools.comparison({unionChoose, roleChoose}, data, self.unionId, self.roleId)

				--选择(自己/公会)战报时过滤掉其他战报
				if satisfy then
					sign = true
					self:pushItemInitialize(data, action, status)
					addItemNum = addItemNum + 1
					if roundIdx < data.round then
						roundIdx = data.round
					end
				end
			end
		end
		--记录上一次战报轮次
		self.insertIdx = roleRound - 1
	end

	--只播到第一轮次时加上轮次标签
	if addItemNum > 0 then
		self:pushItemInitialize({roundTime = true, numRoundBattle = true, round = roundIdx}, action, status)
		addItemNum = addItemNum + 1
	end

	--是否胜利/自己淘汰/公会淘汰
	if sign or roleRound == 1 then
		self:unSchedule(TAG)
		if finish then
			local str = self.unionAlive > 0 and gLanguageCsv.crossUnionUnionBattleSucceed or gLanguageCsv.crossUnionUnionBattleFailure
			self:pushItemInitialize({time = true, itemUp = true, title = str}, action, status)
			addItemNum = addItemNum + 1
		else

			if self.unionAlive <= 0 then
				self:pushItemInitialize({time = true, itemUp = true, title = gLanguageCsv.crossUnionUnionBattleFailure, itemSign = true}, action, status)
				addItemNum = addItemNum + 1
			elseif condition then
				self:pushItemInitialize({time = true, itemUp = true, title = gLanguageCsv.crossUnionBattleFailure, itemSign = true}, action, status)
				addItemNum = addItemNum + 1
			else
				local itemAciton = false
				if action and roleRound ~= 1 then
					itemAciton = true
				end
				self:pushItemInitialize({round = roleRound, roundTime = "roundCountDown", itemSign = true}, true, status)
				self:pushItemInitialize({anima = true, itemSign = true}, true, status)
				addItemNum = addItemNum + 2
			end
		end
	end

	--第一轮次只做倒计时展示，从第二轮次开始做表现(累加)，删除上一次特效
	if addItemNum > 0 and roleRound > 1 and action and self.fightList:getChildrenCount() > 0 then
		self.fightList:scrollToPercentVertical(0, 2, true)
		performWithDelay(self, function()
			local itemHeight = 0
			for i = 1, 3 do
				if self.fightList:getItem(addItemNum) and self.fightList:getItem(addItemNum).itemSign then
					self.fightList:removeItem(addItemNum)
				end
			end
		end, 1)
	end


	if self.fightList:getChildrenCount() == 0 then
		if not finish then
			self:pushItemInitialize({anima = true, itemSign = true}, false, status)
			self:pushItemInitialize({round = 1, roundTime = "roundCountDown", itemSign = true}, false, status)
		else
			self.slider:hide()
			self.fightList:setScrollBarEnabled(false)
			self.duckPanel:show()
			self.duckPanel:get("txt"):text(gLanguageCsv.battleReportNotData)
		end
	else
		self.duckPanel:hide()
	end
end

function FightMessageView:initModel(model)
	self.model = model

	self.unionClassifyData = gGameModel.cross_union_fight:read("pre_battle_groups")	--匹配到的公会
	self.top_battle_groups = gGameModel.cross_union_fight:read("top_battle_groups") --决赛匹配到的公会
	self.status = gGameModel.cross_union_fight:getIdler("status")
	self.round = idler.new("time")
	self.unionId = gGameModel.role:read("union_db_id")
	self.roles = gGameModel.cross_union_fight:getIdler("roles")
	self.roleId = gGameModel.role:read("id")
	self.roleLv = gGameModel.role:getIdler("level")
	self.unionPoint = 0
	self.unionAll = self.model.unionAll
	self.unionAlive = self.unionAll
	self.deleteItem = {}
	self.insertIdx = 0 -- 记录上次塞进list的轮次
	self.delectBattleId = {}
	self.firstTime = false
end

function FightMessageView:onTabItemClick(list, index, v)
	self.betType:set(index)
end

--公会战报
function FightMessageView:unionBattlefieldReport()
	self.unionChoose:set(not self.unionChoose:read())
	self.roleChoose:set(false)
end

--自己战报
function FightMessageView:roleBattlefieldReport()
	self.unionChoose:set(false)
	self.roleChoose:set(not self.roleChoose:read())
end


function FightMessageView:updataBattleReport(id, finish, gameData, await, model)
	if id == 1 then
		--倒计时
		local status = self.status:read()
		self:pushItemInitialize({time = true, itemUp = false}, false, status)
		self:pushItemInitialize({time = true, itemUp = true, roundTime = "countDown"}, false, status)

		self:survivalNumber()
	else
		self.model = model
		local container = self.fightList:getInnerContainer()
		self.gameData = table.deepcopy(gameData)
		self.listY = container:getPositionY()
		for i= 1, 3 do
			table.sort(self.gameData[i], function(a, b)
				return a.round > b.round
			end)
		end

		self.await = await
		self.model.await = await
		self.finish = finish
		local unionChoose = self.unionChoose:read()
		local roleChoose = self.roleChoose:read()
		local betType = self.betType:read()
		--如果第一次进来战斗轮次数据比较多久走预加载

		if self.model.battleRound > 3 and not self.firstTime then
			local gameDatas = self.gameData[betType]
			self:operationbattleDataView(unionChoose, roleChoose, gameDatas, self.finish)
			self.firstTime = true
			return
		end
		self.firstTime = true
		self:survivalNumber(unionChoose, roleChoose)
		if self.gameData and self.gameData[betType] then
			self:battleDataView(unionChoose, roleChoose, self.gameData[betType], finish, true)
		end
	end
end

--实时刷新存活人数
function FightMessageView:survivalNumber()
	self.model:getUnionInfo(false, self.model.squad)
	if not itertools.isempty(self.model.unionState[self.unionId]) then
		self.unionAlive, self.unionPoint = self.model.unionState[self.unionId][1], self.model.unionState[self.unionId][2]
	end
	self.condition = self.model.condition
	self.integral:get("num"):text(self.unionAlive .. "/")
	self.integral:get("numAll"):text(self.unionAll)
	adapt.oneLinePos(self.integral:get("titile1"), {self.integral:get("num"), self.integral:get("numAll")})
	self.integral:get("integral"):text(self.unionPoint)
	adapt.oneLinePos(self.integral:get("titile2"), self.integral:get("integral"))
end

function FightMessageView:closeUnionInfoView()
	self.unionInfo:hide()
end

--查看公会的积分和存活信息
function FightMessageView:unionInfoView()
	if not self.model:notRequireBattle() or self.unionInfo:isVisible() then
		return
	end
	self.unionInfo:show()
	local progress = CrossUnionFightTools.getNowMatch(self.status:read())
	local battleData 
	if progress == 1 then
		battleData = self.unionClassifyData[self.model.squad]
	else
		battleData = self.top_battle_groups
	end
	for i = 1, 4 do 
		if battleData and battleData[i] then
			local unionDbid = battleData[i].union_db_id
			local point, alive = 0, battleData[i].signs_count
			if not itertools.isempty(self.model.unionState[unionDbid]) then
				self.unionAlive, self.unionPoint = self.model.unionState[unionDbid][1], self.model.unionState[unionDbid][2]
				if self.model.unionState[unionDbid][1] then
					alive = self.model.unionState[unionDbid][1]
				end
				if self.model.unionState[unionDbid][2] then
					point = self.model.unionState[unionDbid][2]
				end
			end
			local item = self.unionInfo:get("union" .. i):show()
			item:get("name"):text(battleData[i].union_name)
			adapt.setTextScaleWithWidth(item:get("name"), nil, 300)
			item:get("alive"):text(alive .. "/")
			item:get("aliveAll"):text(battleData[i].signs_count)
			adapt.oneLinePos(item:get("alive"), item:get("aliveAll"))
			item:get("point"):text(point)
		end
	end
end


--战斗接入
function FightMessageView:battleReport(list, node, v)
	local interface = "/game/cross/union/fight/playrecord/get"
	gGameModel:playRecordBattle(v.play_id, v.cross_key, interface, 0, nil)
end


return FightMessageView