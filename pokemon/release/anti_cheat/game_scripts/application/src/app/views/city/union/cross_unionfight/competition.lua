--主赛场/没资格玩家赛场
local CrossUnionFightTools = require "app.views.city.union.cross_unionfight.tools"
local CrossUnionMainView = require "app.views.city.union.cross_unionfight.view"
local CrossUnionModel = require "app.views.city.union.cross_unionfight.model"

local TAG = 30
local ITEM_POS = {
	{950,550},
	{640,1000},
	{1370,1000},
	{2130,1000},
}
local ViewBase = cc.load("mvc").ViewBase
local CompetitionView = class("CompetitionView", ViewBase)
CompetitionView.RESOURCE_FILENAME = "cross_union_competition.json"
CompetitionView.RESOURCE_BINDING = {
	["title"] = "title",
	['titleTime'] = "titleTime",
	["unionPanel"] = "unionPanel",
	['state'] = "state",
	['time'] = "time",
	['item'] = "item",
	['iconBg'] = "iconBg",
	['list'] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.isSel then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					node:get("textNote"):text(v.str)
					node:get("textNote"):color(v.isSel and ui.COLORS.NORMAL.WHITE or cc.c4b(241, 61, 86, 255))
					node:get("role"):visible(v.role)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onChangePromotionPage"),
			},
		},
	},
	["center"] = "center",
	["playback"] = {
		varname = "playback",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("playbackView")}
		},
	},
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
	["battlefield"] = {
		varname = "battlefield",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("battlefieldView")}
		},
	},
	["bg"] = "bg",

}


function CompetitionView:onCreate(model, battleData, rankData)
	self:initModel(model)
	self.battleData = battleData or {}
	if battleData then
		self.topuiView = gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
			:init({title = gLanguageCsv.ministryHouseBattle, subTitle = "Building war"})
		self.bg:show()
		self.unionRankData = rankData
		self:qualificationView(rankData.last_ranks, rankData.last_ranks[5])
	else
		self.bg:hide()
		self:qualificationView(self.unionClassifyData, self.top_battle_groups)
	end
	self:enableSchedule()
	self:savePositionView()

	self:unSchedule(TAG)
	idlereasy.when(self.status, function(_, status)
		self.center:get("round"):hide()
		self:onUpdateStatus(status)
	end)
end

function CompetitionView:onUpdateStatus(status)
	self.battle:hide()
	self.battlefield:hide()
	self.center:hide()
	-- 没有资格玩家，在主赛程等待初赛倒计时
	if status == "preStart" or status == "preBattle" then
		--初赛都没有资格
		self:groupView(false, true)
		self:startView(status)

	elseif status == "preOver" then
		if self.model.finish then
			self:groupView(true, true)
			self:preOverAwardView()
		else
			self:groupView(false, true)
			self:startView(status)
		end
	elseif status == "preAward" then
		self:groupView(true, true)
		self:preOverAwardView()

	elseif status == "topPrepare" then
		--周日的决赛准备阶段
		self.list:hide()
		self:groupView()
		self:topPrepareView()

	elseif status == "topStart" or status == "topBattle" then
		self.list:hide()
		self:groupView()
		self:startView(status)

	elseif status == "topOver" then
		self.list:hide()
		self:groupView(false, true)
		self:startView(status)

		if self.unionRankData and self.model.finish then
			self.battle:show()
			if self.qualification[1] then
				self:preliminaryView()
			else
				self.battlefield:hide()
			end
			self:closedView()
		end

	elseif status == "closed" then
		self:unSchedule(TAG)
		self:groupView(true, true)
		if self.unionRankData then
			self.battle:show()
			if self.battleStage == CrossUnionModel.MatchStage.Final then
				self:finalView()
			else
				self:preliminaryView()
			end
			if not self.qualification[1] then
				self.battlefield:hide()
			end
			self:closedView()
		end
	end
end

function CompetitionView:savePositionView()
	self.iconBgPosX = self.iconBg:x()
	self.iconBgPosY = self.iconBg:y()
	self.itemPostion = {}
	for i = 1, 4 do
		if not self.itemPostion[i] then
			self.itemPostion[i] = {self.unionPanel:get("panel" .. i):x(), self.unionPanel:get("panel" .. i):y()}
		end
	end
end

function CompetitionView:closedView()
	self.center:hide()
	self:preOverAwardView()
	self.titleTime:hide()
end

--上期回顾数据是由排行榜筛选的
function CompetitionView:qualificationView(preRankData, topRankData)

	--初赛资格
	for i,v in ipairs(preRankData or {}) do
		if i <= 4 then
			for j, vv in ipairs(v) do
				if vv.union_db_id == self.unionId then
					self.qualification[1] = true
					self.group = i
					break
				end
			end
		end
		if self.qualification[1] then
			break
		end
	end
	--决赛资格
	for i,v in ipairs(topRankData or {}) do
		if v.union_db_id == self.unionId then
			self.qualification[2] = true
			break
		end
	end
end


function CompetitionView:initModel(model)
	self.model = model

	self.status = gGameModel.cross_union_fight:getIdler("status")
	self.unionClassifyData = gGameModel.cross_union_fight:read("pre_battle_groups") or {}	--匹配到的公会
	self.top_battle_groups = gGameModel.cross_union_fight:read("top_battle_groups") or {} --决赛匹配到的公会
	self.unions = gGameModel.cross_union_fight:read("unions")
	self.unionId = gGameModel.union:read("id")
	self.roleId = gGameModel.role:read("id")
	self.roles = gGameModel.cross_union_fight:read("roles")
	self.listData = idlers.newWithMap({})
	if not itertools.isempty(self.competitionViewData) then
		self.groupIdx = idler.new(self.competitionViewData.group)
		self.battleStage = self.competitionViewData.type --CrossUnionModel.MatchStage.Preliminary	--默认是初赛
	else
		self.groupIdx = idler.new(1)
		self.battleStage = CrossUnionModel.MatchStage.Preliminary	--默认是初赛
	end
	self.qualification = {false, false}
end


--倒计时状态
function CompetitionView:startView(status)
	self:unSchedule(TAG)
	self.titleTime:hide()
	self.center:show()
	self.center:get("timeTitle"):hide()
	self.center:get("title"):hide()
	if status == "preStart" or status == "topStart" then
		self.center:get("title"):show()
	elseif status == "preBattle" or status == "topBattle" or status == "preOver" or status == "topOver" then
		self.center:get("round"):show()
		local str = string.format(gLanguageCsv.roundBattle, self.model.battleRound)
		if self.model.await then
			str = str .. gLanguageCsv.ltaskRunning .. ".."
		end
		self.center:get("round.round"):text(str)
	end

	self.center:get("time"):show()
	text.addEffect(self.center:get("time"), {outline={color=ui.COLORS.NORMAL.DEFAULT, size = 4}})

	local tagname = gLanguageCsv.finalStage
	if status == "preStart" or status == "preBattle" or status == "preOver" then
		tagname = gLanguageCsv.preliminaryContest
	end
	self.title:text(tagname)

	local countTime = gCommonConfigCsv["crossUnionFight"]
	if status == "preStart" or status == "preBattle" or status == "preOver" or status == "topStart" or status == "topBattle" or status == "topOver" then
		local delta
		self:schedule(function()
			local status = self.status:read()
			if status == "preStart" or status == "topStart" then
				delta = CrossUnionMainView:countDown(status, true)
			else
				delta = self.model.countDown
				if delta == 0 then
					if self.model.finish and (status == "preOver" or status == "topOver")  then
						gGameApp:requestServer("/game/cross/union/fight/rank", function (tb)
							self.unionRankData = tb.view
							self:preOverAwardView()
							self:setUnionInfo()
							self:unSchedule(TAG)
						end)
						return
					else
						self.model:calculationUnionPoint(self.groupIdx:read(), function(unionData)
							if unionData then
								self:setUnionInfo()
								local str = string.format(gLanguageCsv.roundBattle, self.model.battleRound)
								if self.model.await then
									str = str .. gLanguageCsv.ltaskRunning .. ".."
								end
								self.center:get("round.round"):text(str)
							end
						end, self)
					end
				end
			end
			if delta <= 0 then
				delta = 0
			end
			self.center:get("time"):text(time.getCutDown(delta).min_sec_clock)
		end, 1, 0, TAG)
	end
end



--东西南北四组
function CompetitionView:groupView(sign, finish)
	if finish then
		local listDatas1 = {}
		for i = 1, 4 do
			listDatas1[i] = {str = gLanguageCsv["buildOrganization" .. i], isSel = false, role = i == self.group}
		end

		self.listData:update(listDatas1)
		local group = 1
		if self.group and self.group <= 4 then
			group = self.group
		end
		if not itertools.isempty(self.competitionViewData) then
			group = self.competitionViewData.group
		end
		self.groupIdx = idler.new(group)
		self.idxGroup = group
		self.groupIdx:addListener(function(val, old)
			self.idxGroup = val
			if self.listData:atproxy(old) then
				self.listData:atproxy(old).isSel= false
			end
			if self.listData:atproxy(val) then
				self.listData:atproxy(val).isSel= true
			end
		end)
	end
	local start = self.status:read()
	if sign then
		performWithDelay(self, function()
			gGameApp:requestServer("/game/cross/union/fight/rank", function (tb)
				self.unionRankData = tb.view
				self:setUnionInfo()
			end)
		end, 0)
	elseif start == "topStart" or start == "preStart" then
		self:setUnionInfo()
	else

		self.model:calculationUnionPoint(1, function(unionData)
			self:setUnionInfo()
		end, self)
	end
end

function CompetitionView:preOverAwardView()
	self:unSchedule(TAG)
	self.titleTime:show()
	self.playback:show()
	if not itertools.isempty(self.competitionViewData) then
		local str = self.competitionViewData.type == 2 and gLanguageCsv.finalMatch .. gLanguageCsv.effortAdvance or gLanguageCsv.preliminaryContest
		self.title:text(str)
	else
		self.title:text(gLanguageCsv.preliminaryContest)
	end
	adapt.oneLinePos(self.title, self.playback, cc.p(10, 0))
	self.titleTime:text(gLanguageCsv.finalTime)
	self.center:hide()
end

function CompetitionView:topPrepareView()
	self.title:text(gLanguageCsv.finalStage)
	self.titleTime:hide()
	self.playback:hide()
	self.center:show()
	self.center:get("bg"):hide()
	self.center:get("title"):text(gLanguageCsv.battleChampion)
	self.center:get("time"):hide()
	self.center:get("timeTitle"):show()
	self.center:get("timeTitle"):text(gLanguageCsv.finalStageTime)
	text.addEffect(self.center:get("timeTitle"), {outline={color=ui.COLORS.NORMAL.DEFAULT, size = 4}})
end

--上期回顾(决赛)
function CompetitionView:finalView()
	self.battleStage = CrossUnionModel.MatchStage.Final
	self.final:get('btn'):texture("common/btn/btn_normal.png")
	self.preliminary:get('btn'):texture("common/btn/btn_recharge.png")
	self.final:get('name'):setColor(ui.COLORS.NORMAL.WHITE)
	self.preliminary:get('name'):setColor(cc.c3b(241,61,86))
	self.title:text(gLanguageCsv.finalMatch .. gLanguageCsv.effortAdvance)
	adapt.oneLinePos(self.title, self.playback, cc.p(10, 0))
	self.list:hide()		--决赛只有一个分组
	self:setUnionInfo()	--切换公会信息
	if self.qualification and self.qualification[2] then
		self.battlefield:show()
	else
		self.battlefield:hide()
	end
end

--上期回顾(初赛)
function CompetitionView:preliminaryView()
	self.battleStage = CrossUnionModel.MatchStage.Preliminary
	self.preliminary:get('btn'):texture("common/btn/btn_normal.png")
	self.final:get('btn'):texture("common/btn/btn_recharge.png")
	self.preliminary:get('name'):setColor(ui.COLORS.NORMAL.WHITE)
	self.final:get('name'):setColor(cc.c3b(241,61,86))
	self.title:text(gLanguageCsv.preliminaryContest)
	adapt.oneLinePos(self.title, self.playback, cc.p(10, 0))
	self.list:show()
	self:setUnionInfo()
	if self.qualification and self.qualification[1] then
		self.battlefield:show()
	else
		self.battlefield:hide()
	end
end

--我的赛场
function CompetitionView:battlefieldView()
	self.list:show()
	local data = {}
	local groupIdx = self.groupIdx:read() --分组
	self.competitionViewData = {type = self.battleStage, group = groupIdx}
	if self.battleStage == CrossUnionModel.MatchStage.Preliminary then
		for i, v in ipairs(self.battleData) do
			if i == groupIdx then
				data = clone(v)
			end
		end
	else
		data = clone(self.battleData[5])
	end
	gGameUI:stackUI("city.union.cross_unionfight.fight_playback", nil, nil, self.model, self.battleStage, data)
end


function CompetitionView:setUnionInfo()
	local pageIdx = self.groupIdx:read()
	local updataUnion = function(unionData, unionRank)
		self.iconBg:show()
		self.iconBg:scale(0.8)
		local dataUnion
		--服务器跑完战报后客户端根据自己模拟情况判断是否展示小组获胜者
		local status = self.status:read()
		local uiWhetherOver = false
		if not self.model.finish and self.model:notRequireBattle() then
			dataUnion = unionData
			uiWhetherOver = true
		else
			dataUnion = itertools.size(unionRank) == 0 and unionData or unionRank
		end

		dataUnion = dataUnion or {}
		for i = 1, 4 do
			local v = dataUnion[i]
			if self.unionPanel:get("noUnionIcon" .. i) then
				self.unionPanel:get("noUnionIcon" .. i):removeSelf()
			end
			if v then
				--胜利公会
				local rankOne = false
				local item = self.unionPanel:get("panel" .. i):show()
				item:scale(0.9)
				item:get("layer.name"):text(v.union_name)
				adapt.setTextScaleWithWidth(item:get("layer.name"), nil, 270)
				item:get("layer.server"):text(string.format(gLanguageCsv.brackets, getServerArea(v.server_key, nil)))
				item:get("layer.icon"):texture(csv.union.union_logo[v.union_logo].icon)
				local name = self.unions[v.union_db_id].chairman_name == "" and v.union_name or self.unions[v.union_db_id].chairman_name
				item:get("layer.unionName"):text(name)

				local point, alive
				if uiWhetherOver then
					if self.model.unionState and self.model.unionState[v.union_db_id] then
						if self.model.unionState[v.union_db_id][1] then 
							alive = self.model.unionState[v.union_db_id][1]
						end
						if self.model.unionState[v.union_db_id][2] then 
							point = self.model.unionState[v.union_db_id][2]
						end
					end
					if not alive then alive = v.signs_count end
					if not point then point = 0 end
				elseif itertools.size(unionRank) > 0 then
					point, alive = v.point, v.alive_count
				else
					point, alive = 0, v.signs_count
				end
				
				item:get("layer.num"):text(alive.."/".. v.signs_count)
				item:get("layer.pointNum"):text(point)
				local x, y = item:get("layer.name"):x(), item:get("layer.point"):y()
				local aliveY = item:get("layer.title"):y()
				adapt.oneLineCenterPos(cc.p(x, aliveY), {item:get("layer.title"), item:get("layer.num")})
				adapt.oneLineCenterPos(cc.p(x, y), {item:get("layer.point"), item:get("layer.pointNum")})
				
				--获取会长的dbid做显示处理(union_base第二期以后可以删除s)
				local dbid
				if self.unions[v.union_db_id] and self.unions[v.union_db_id].union_base and self.unions[v.union_db_id].union_base.chairman_db_id then
					dbid = self.unions[v.union_db_id].union_base.chairman_db_id
				elseif self.unions[v.union_db_id] and self.unions[v.union_db_id].chairman_db_id then
					dbid = self.unions[v.union_db_id].chairman_db_id
				end
				
				local cardId = 1
				local figure = self.unions[v.union_db_id].chairman_figure == 0 and 1 or self.unions[v.union_db_id].chairman_figure
				if dbid and self.roles[dbid] then
					cardId = self.roles[dbid].display_card
				end

				local figureLen = 0
				if not uiWhetherOver and itertools.size(unionRank) > 0 then
					if i == 1 then item:get("win"):show() end
					item:get("bg"):scaleX(i == 1 and 1 or -1)
					item:get("layer.anima"):x(i == 1 and 436 or -165)
					item:get("layer"):x(i == 1 and 138 or 177)
					item:xy(ITEM_POS[i][1], ITEM_POS[i][2])
				else

					if i == 1 then item:get("win"):hide() end
					item:get("bg"):scaleX(i % 2 == 1 and 1 or -1)
					item:get("layer"):x(i % 2 == 1 and 138 or 177)
					item:get("layer.anima"):x(i % 2 and 436 or -165)
					item:xy(self.itemPostion[i][1], self.itemPostion[i][2])
					figureLen = i % 2 == 1 and 0 or -600
				end

				local figureCfg = gRoleFigureCsv[figure]
				local size = item:get("layer.anima"):size()
				item:get("layer.anima"):removeAllChildren()
				--角色
				local roleAnima
				if figureCfg.resSpine ~= "" then
					roleAnima = widget.addAnimationByKey(item:get("layer.anima"), figureCfg.resSpine, "figure", "standby_loop1", 4)
						:xy(size.width / 2 + figureLen, size.height / 4 - 150)
						:scale(0.8)
				end

				if roleAnima then
					item:get("layer.unionName"):x(item:get("layer.anima"):x()+figureLen)
					item:get("layer.bg"):x(item:get("layer.anima"):x()+figureLen)
				end
				--称号
				if self.unions[v.union_db_id].chairman_title ~= -1 then
					bind.extend(self, item:get("layer.anima"), {
						event = "extend",
						class = "role_title",
						props = {
							data = self.unions[v.union_db_id].chairman_title,
							onNode = function(panel)
								panel:xy(size.width/2 + figureLen, size.height + 80)
								panel:scale(0.9)
								panel:z(6)
							end,
						},
					})
				end
			else		
				self.unionPanel:get("panel" .. i):hide()
				local item = self.unionPanel:get("noUnionData"):clone():show()
				self.unionPanel:add(item, 10, "noUnionIcon" .. i)
				if not uiWhetherOver and itertools.size(unionRank) > 0 then
					item:xy(ITEM_POS[i][1], ITEM_POS[i][2])
				else
					item:xy(self.itemPostion[i][1], self.itemPostion[i][2])
				end
			end
		end

		local x, y = self.iconBgPosX, self.iconBgPosY
		if not uiWhetherOver and itertools.size(unionRank) > 0 then
			x = x + 280
			y = y - 130
		end
		self.iconBg:xy(x, y)
	end

	local status = self.status:read()
	local satisfy = false
	if (status == "topOver" and self.battleStage == CrossUnionModel.MatchStage.Preliminary and self.model.finish) or (status == "closed" and self.battleStage == CrossUnionModel.MatchStage.Preliminary) then
		satisfy = true
	end
	if CrossUnionFightTools.getNowMatch(status) == 1 or satisfy then
		self.iconBg:texture("city/union/cross_unionfight/img_cs_bw.png")
		local unionRankOne = {}
		if self.unionRankData and self.unionRankData.last_ranks and self.unionRankData.last_ranks[pageIdx] then
			unionRankOne = self.unionRankData.last_ranks[pageIdx]
		end
		updataUnion(self.unionClassifyData[pageIdx], unionRankOne)
	else

		self.iconBg:texture("city/union/cross_unionfight/img_js_bw.png")
		local unionRankOne = {}
		if status == "closed" or  (status == "topOver" and self.model.finish) then
			if self.unionRankData and self.unionRankData.last_ranks[5] then
				unionRankOne = self.unionRankData.last_ranks[5]
			end
		end
		updataUnion(self.top_battle_groups, unionRankOne)
	end
end

function CompetitionView:onChangePromotionPage(list, pageIdx)
	if pageIdx == self.idxGroup then
		return
	end

	self.groupIdx:set(pageIdx)
	--如果第一次获取排行榜的交互数据还没有给到又快速点击就在获取一次

	if not self.unionRankData and self.model:notRequireRank() then
		gGameApp:requestServer("/game/cross/union/fight/rank", function (tb)
			self.unionRankData = tb.view
			self.model:calculationUnionPoint(pageIdx, function(unionData)
				self:setUnionInfo()
			end, self)
		end)
	else
		self.model:calculationUnionPoint(pageIdx, function(unionData)
			self:setUnionInfo()
		end, self)
	end
end

--战报回放
function CompetitionView:playbackView()
	self.competitionViewData = {type = self.battleStage, group = self.groupIdx:read()}
	local type = CrossUnionFightTools.getNowMatch(self.status:read()) == 2 and 5 or self.groupIdx:read() -- 5 是决赛，
	if itertools.isempty(CrossUnionMainView.lastBattle) then
		gGameApp:requestServer("/game/cross/union/fight/last/battle",function (tb)
			CrossUnionMainView.lastBattle = tb.view
			gGameUI:stackUI("city.union.cross_unionfight.record",nil, {full = false}, tb.view ,type, self.unionId)
		end)
	else
		gGameUI:stackUI("city.union.cross_unionfight.record",nil, {full = false}, CrossUnionMainView.lastBattle ,type, self.unionId)
	end
end

function CompetitionView:onClose()
	self.competitionViewData = {}
	ViewBase.onClose(self)
end

return CompetitionView