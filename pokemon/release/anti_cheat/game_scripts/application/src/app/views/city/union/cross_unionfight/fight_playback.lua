local CrossUnionMainView = require "app.views.city.union.cross_unionfight.view"
local CrossUnionFightTools = require "app.views.city.union.cross_unionfight.tools"
local CrossUnionModel = require "app.views.city.union.cross_unionfight.model"

local FightPlaybackView = class("FightPlaybackView", cc.load("mvc").ViewBase)
FightPlaybackView.RESOURCE_FILENAME = "cross_union_fight.json"
FightPlaybackView.RESOURCE_BINDING = {
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
	["bg"] = "bg",

}


function FightPlaybackView:pushItemInitialize(v, start)
	local item = self.item:clone():show()
	self.fightList:pushBackCustomItem(item)
	CrossUnionFightTools.onInitItem(self.fightList, item, v, self, start, true)
end


function FightPlaybackView:onCreate(model, stage, battleData)
	self.topuiView = gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.ministryHouseBattle, subTitle = "Building war"})

	self:initModel(model)

	for i,v in ipairs(battleData) do
		table.sort(battleData[i], function(a, b)
			return a.round > b.round
		end)
	end
	self.battleData = battleData
	self.bg:show()
	self.integral:hide()
	self:enableSchedule()

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
	local status = self.status:read()
	local str = stage ~= CrossUnionModel.MatchStage.Preliminary and gLanguageCsv.finalMatch or gLanguageCsv.preliminary
	self.competition:text(str)
	--分组/当前轮次/公会成员战报/自己战报
	local refreshTimes = 0
	idlereasy.any({self.unionChoose, self.roleChoose, self.betType}, function()
		refreshTimes = refreshTimes + 1
	
		performWithDelay(self, function()
			local unionChoose = self.unionChoose:read()
			local roleChoose = self.roleChoose:read()
			local betType = self.betType:read()
			if refreshTimes > 0 then
				refreshTimes = 0
				self.fightList:removeAllChildren()
				self.duckPanel:hide()
				local start = self.status:read()
				local satisfy = false
				local roundIdx = 0
				local battlecount = 0
				--第一轮战报显示倒计时时间
				self.fightList:jumpToPercentVertical(0)
				local asyncLoad = function()
					for i, data in ipairs(self.battleData[betType] or {}) do
						--只展示倒计时结束的轮次战报(当前倒计时战报不显示)
						satisfy = CrossUnionFightTools.comparison({unionChoose, roleChoose}, data, self.unionId, self.roleId)
						--选择(自己/公会)战报时过滤掉其他战报
						if satisfy then
							--add轮次标签
							battlecount = battlecount + 1
							if roundIdx ~= data.round then
								roundIdx = data.round
								self:pushItemInitialize({roundTime = true, numRoundBattle = true, round = data.round}, start)
							end
							self:pushItemInitialize(data, start)
							coroutine.yield()
						end
					end
				end
				self:enableAsyncload()
					:asyncFor(asyncLoad, function()
						if battlecount == 0 then
							self.duckPanel:show()
							self.duckPanel:get("txt"):text(gLanguageCsv.battleReportNotData)
							self.fightList:setScrollBarEnabled(false)
							self.slider:hide()
						else
							self.duckPanel:hide()
						end
					end, 4)
			end
		end, 0)
	end)
end

function FightPlaybackView:initModel(model)
	self.model = model

	self.status = gGameModel.cross_union_fight:getIdler("status")
	self.unionId = gGameModel.role:read("union_db_id")
	self.roles = gGameModel.cross_union_fight:getIdler("roles")
	self.roleId = gGameModel.role:read("id")
	self.roleLv = gGameModel.role:getIdler("level")
	self.unionPoint = 0
	self.unionAll = self.model.unionAll
	self.unionAlive = self.unionAll
end

function FightPlaybackView:onTabItemClick(list, index, v)
	self.betType:set(index)
end

--公会战报（切换）
function FightPlaybackView:unionBattlefieldReport()
	self.unionChoose:set(not self.unionChoose:read())
	self.roleChoose:set(false)
end

--自己战报(切换)
function FightPlaybackView:roleBattlefieldReport()
	self.unionChoose:set(false)
	self.roleChoose:set(not self.roleChoose:read())
end

--战报接入
function FightPlaybackView:battleReport(list, node, v)
	local interface = "/game/cross/union/fight/playrecord/get"
	gGameModel:playRecordBattle(v.play_id, v.cross_key, interface, 0, nil)
end


return FightPlaybackView