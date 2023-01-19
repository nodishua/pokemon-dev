-- @date:   2020-12-24
-- @desc:   跨服资源站-战斗记录

local function getStrTime(historyTime)
	local timeTable = time.getCutDown(math.max(time.getTime() - historyTime, 0), nil, true)
	local strTime = timeTable.head_date_str
	strTime = strTime..gLanguageCsv.before
	return strTime
end

local CrossMineCombatRecordView = class("CrossMineCombatRecordView", Dialog)
CrossMineCombatRecordView.RESOURCE_FILENAME = "cross_mine_combat_record.json"
CrossMineCombatRecordView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["leftPanel"] = "leftPanel",
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
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
					end
					panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					adapt.setAutoText(panel:get("txt"), v.name, 240)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["myPanel"] = "myPanel",
	["myPanel.item"] = "item",
	["myPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("combatDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function (a, b)
					return a.time > b.time
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBG","head","textName","btnReplay","btnShare","imgFlag","textTime","imgDownOrUp","imgGold",
						"textLv","textLvNote","sever","bgDefend","bgAttack","btnChallenge","textNoChange","textGlodNum","textRankUp")

					childs.btnChallenge:visible(false)
					childs.textGlodNum:text(v.coin13)
					childs.textRankUp:text(math.abs(v.move))
					childs.textLv:text(v.enemy_level)
					childs.textName:text(v.enemy_name)
					childs.textTime:text(getStrTime(v.time))

					childs.sever:text(string.format(gLanguageCsv.brackets, getServerArea(v.enemy_game_key, true)))

					adapt.oneLineCenterPos(cc.p(1000, 60), {childs.imgGold, childs.textGlodNum}, cc.p(6, 0))
					adapt.oneLinePos(childs.textLvNote, {childs.textLv, childs.sever}, {cc.p(0, 0),cc.p(5, 5)})
					adapt.setTextScaleWithWidth(childs.textName, nil, 280)
					adapt.setTextScaleWithWidth(childs.textTime, nil, 500)
					if matchLanguage({"en"}) then
						childs.textTime:x(childs.textTime:x() + 80)
					end
					if v.result == "win" then
						childs.imgDownOrUp:texture("common/icon/logo_arrow_green.png")
						text.addEffect(childs.textRankUp, {color=cc.c3b(73, 185, 115)})
						childs.imgFlag:texture("city/pvp/craft/icon_win.png")
						childs.imgBG:texture("city/pvp/cross_arena/panel_win.png")
					else
						childs.imgDownOrUp:texture("common/icon/logo_arrow_red.png")
						text.addEffect(childs.textRankUp, {color=cc.c3b(224, 96, 114)})
						childs.textRankUp:color(cc.c3b(224, 96, 114))
						childs.imgFlag:texture("city/pvp/craft/icon_lose.png")
						childs.imgBG:texture("city/pvp/cross_arena/panel_lose.png")
						if v.battle_mode == 2 then
							childs.btnChallenge:visible(true)
						end
					end
					bind.extend(list, childs.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.enemy_logo,
							frameId = v.enemy_frame,
							level = false,
							vip = false,
						}
					})

					local function showNoChangeText(isRevenge)
						childs.textNoChange:show()
						text.addEffect(childs.textNoChange, {outline = {color= cc.c4b(255, 91, 39,255)}})
						childs.textRankUp:hide()
						childs.imgDownOrUp:hide()
						childs.textNoChange:text(isRevenge and gLanguageCsv.crossMineRankNoChangeByRevenge or gLanguageCsv.crossMineRankNoChange)
					end
					if v.flag and v.flag == "revenge" then
						showNoChangeText(true)
					else
						if v.move == 0 then
							showNoChangeText()
						else
							childs.textNoChange:hide()
							adapt.oneLineCenterPos(cc.p(1000, 135), {childs.textRankUp, childs.imgDownOrUp}, cc.p(6, 0))
						end
					end

					if v.battle_mode == 1 then
						childs.bgAttack:show()
						childs.bgDefend:hide()
					else
						childs.bgAttack:hide()
						childs.bgDefend:show()
					end
					bind.touch(list, childs.btnReplay, {methods = {ended = functools.partial(list.playbackBtn, k, v)}})
					bind.touch(list, childs.btnShare, {methods = {ended = functools.partial(list.shareBtn, k, v)}})
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell,k, v)}})
					bind.touch(list, childs.btnChallenge, {methods = {ended = functools.partial(list.challengeBtn, k, v)}})

					text.addEffect(childs.btnReplay:get("textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
					text.addEffect(childs.btnShare:get("textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
					text.addEffect(childs.btnChallenge:get("textNote"), {outline = {color=ui.COLORS.OUTLINE.WHITE}})
				end,
				onAfterBuild = function(list)
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				playbackBtn = bindHelper.self("onPlaybackClick"),
				challengeBtn = bindHelper.self("onChallengeClick"),
				shareBtn = bindHelper.self("onShareClick"),
				clickCell = bindHelper.self("oninfoClick"),
			},
		},
	},
	["goodPanel"] = "goodPanel",
	["goodPanel.item"] = "item1",
	["goodPanel.list"] = {
		varname = "list1",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("bestData"),
				item = bindHelper.self("item1"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"head1",
						"textName",
						"textName1",
						"btnReplay",
						"head2",
						"txtTop",
						"txtTop1",
						"txtFight",
						"txtFight1",
						"textServe",
						"textServe1",
						"txtLvNode",
						"txtLvNode1",
						"txtLv",
						"txtLv1",
						"imgFlag",
						"imgFlag1",
						"imgBG"
					)
					childs.textName:text(v.name )
					childs.textName1:text(v.defence_name)
					bind.extend(list, childs.head1, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							frameId = v.frame,
							level = false,
							vip = false,
						}
					})
					bind.extend(list, childs.head2, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.defence_logo,
							frameId = v.defence_frame,
							level = false,
							vip = false,
						}
					})

					if v.result == "win" then
						childs.imgBG:texture("city/pvp/cross_arena/list_bg_1.png")
						childs.imgFlag:texture("city/pvp/craft/icon_win.png")
						childs.imgFlag1:texture("city/pvp/craft/icon_lose.png")
					else
						childs.imgBG:texture("city/pvp/cross_arena/list_bg_2.png")
						childs.imgFlag1:texture("city/pvp/craft/icon_win.png")
						childs.imgFlag:texture("city/pvp/craft/icon_lose.png")
					end

					childs.txtTop:text(string.format(gLanguageCsv.crossMinePVPRank,v.rank))
					childs.txtTop1:text(string.format(gLanguageCsv.crossMinePVPRank,v.defence_rank))
					childs.txtFight:text(string.format(gLanguageCsv.crossMinePVPFight,v.fighting_point))
					childs.txtFight1:text(string.format(gLanguageCsv.crossMinePVPFight,v.defence_fighting_point))
					childs.textServe:text(string.format(gLanguageCsv.brackets, getServerArea(v.role_key[1])))
					childs.textServe1:text(string.format(gLanguageCsv.brackets, getServerArea(v.defence_role_key[1])))
					childs.txtLv:text(v.level)
					childs.txtLv1:text(v.defence_level)
					text.addEffect(childs.txtLv, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					text.addEffect(childs.txtLv1, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					text.addEffect(childs.txtLvNode, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					text.addEffect(childs.txtLvNode1, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					adapt.oneLinePos(childs.textName,childs.textServe, cc.p(5, 0))
					adapt.oneLinePos(childs.textName1,childs.textServe1, cc.p(5, 0))

					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					bind.touch(list, childs.btnReplay, {methods = {ended = functools.partial(list.playbackBtn, k, v)}})
				end,
				onAfterBuild = function(list)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("oninfoClick"),
				playbackBtn = bindHelper.self("onPlaybackClick"),
			},
		},
	},
	["emptyPanel"] = "emptyPanel",
	["emptyPanel.emptyTxt"] = "emptyTxt",
}

function CrossMineCombatRecordView:onCreate(params)
	self.blessingCb = params.blessingCb
	self:initModel()
	self.emptyPanel:hide()
	self.myPanel:hide()
	self.goodPanel:hide()
	self.combatDatas = self.record:read().history
	self.bestData = self.bestRecord:read()

	self.showTab = idler.new(1)

	self.panel = {
		{
			node = self.myPanel,
			data = self.combatDatas,
			txtNode = gLanguageCsv.noBattleRecord
		},
		{
			node = self.goodPanel,
			data = self.bestData,
			txtNode = gLanguageCsv.noBestRecord
		},
	}

	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.myBattle, fontSize = 50},
		[2] = {name = gLanguageCsv.bestBattle, fontSize = 50},
	})

	if self.tmp == 2 then
		self.showTab:set(2)
	end
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self.panel[oldval].node:hide()
		self.panel[val].node:show()
		local isempty = itertools.isempty(self.panel[val].data)
		self.emptyPanel:visible(isempty)
		self.emptyTxt:text(self.panel[val].txtNode)
	end)

	Dialog.onCreate(self)
end

function CrossMineCombatRecordView:initModel()
	self.role = gGameModel.cross_mine:getIdler("role")
	self.round = gGameModel.cross_mine:getIdler("round")
	self.record = gGameModel.cross_mine:getIdler("record")
	self.bestRecord = gGameModel.cross_mine:getIdler("topBattleHistory")

	local dailyRecord = gGameModel.daily_record
	-- 已经复仇次数
	self.revengeTimes = dailyRecord:getIdler("cross_mine_revenge_times")
	-- 报仇购买次数
	self.revengeBuyTimes = dailyRecord:getIdler("cross_mine_revenge_buy_times")

	if not self.tmp then
		self.tmp = 0
	end
end

function CrossMineCombatRecordView:onPlaybackClick(list, k, v)
	local interface = "/game/cross/mine/playrecord/get"
	gGameModel:playRecordBattle(v.play_record_id, v.cross_key, interface, 0, nil)
end

function CrossMineCombatRecordView:oninfoClick(list, k, v)
	local interface = "/game/cross/mine/playrecord/get"
	local personalInfo = gGameModel:playRecordDeployInfo(v.play_record_id, v.cross_key, interface,
		function(personalInfo)
			gGameUI:stackUI("city.pvp.cross_mine.record_info", nil, {clickClose = true, blackLayer = true}, personalInfo)
		end
	)
end

function CrossMineCombatRecordView:onTabClick(list, index)
	self.showTab:set(index)
	self.tmp = index
end

function CrossMineCombatRecordView:onShareClick(list, k, v)
	local battleShareTimes = gGameModel.daily_record:read("cross_mine_share_times")
	if battleShareTimes >= gCommonConfigCsv.shareTimesLimit then
		gGameUI:showTip(gLanguageCsv.shareTimesNotEnough)
		return
	end
	local leftTimes = gCommonConfigCsv.shareTimesLimit - battleShareTimes
	local params = {
		cb = function()
			gGameApp:requestServer("/game/battle/share", function(tb)
				gGameUI:showTip(gLanguageCsv.recordShareSuccess)
			end, v.play_record_id, v.enemy_name, "crossMine", v.cross_key)
		end,
		isRich = false,
		btnType = 2,
		content = string.format(gLanguageCsv.shareBattleNote, leftTimes .. "/" .. gCommonConfigCsv.shareTimesLimit),
	}
	gGameUI:showDialog(params)
end

function CrossMineCombatRecordView:onChallengeClick(list, k ,v)
	if self.round:read() == "start" then
		gGameApp:requestServer("/game/cross/mine/role/info", function(tb)
			local data = tb.view
			local revenged =  data.role_be_revenged[self.role:read().role_db_id] or {}

			if revenged.time and #revenged.time > 0 and revenged.time[#revenged.time] + 5*60 > time.getTime() then
				-- 被挑战5分钟内不允许被挑战
				gGameUI:showTip(string.format(gLanguageCsv.crossMineProtected, data.role_name))
				return
			end

			-- 单人复仇上限
			local beRevengedMax = csv.cross.mine.base[1].beRevengedLimitByRole
			local count = revenged.count or 0

			if count >= beRevengedMax then
				gGameUI:showTip(string.format(gLanguageCsv.crossMineRevengedTimesMax, data.role_name))
				return
			end

			local enemy = {
				roleID = v.enemy_role_id,
				recordID = v.enemy_record_id,
				rank = data.rank
			}

			local function revenge()
				self.blessingCb(data, enemy, true)
			end
			if self:getLeftRevengeTimes() > 0 then
				revenge()
			else
				self:buyRevengeTimes(revenge)
			end
		end, v.enemy_record_id, v.enemy_game_key, v.enemy_rank,"revenge")
	elseif self.round:read() == "over" then
		gGameUI:showTip(gLanguageCsv.crossMineCantRevenged)
	else
		gGameUI:showTip(gLanguageCsv.crossMineNotStart)
	end
end

-- 获取剩余复仇次数
function CrossMineCombatRecordView:getLeftRevengeTimes()
	local revengeFreeTimes = csv.cross.mine.base[1].revengeFreeTimes
	local canRevengedTimes = revengeFreeTimes + self.revengeBuyTimes:read() - self.revengeTimes:read()
	canRevengedTimes = math.max(canRevengedTimes, 0)
	return canRevengedTimes
end

-- 购买复仇次数
function CrossMineCombatRecordView:buyRevengeTimes(callBack)
	local times = math.min(itertools.size(gCostCsv.cross_mine_revenge_buy_cost), self.revengeBuyTimes:read()+1)
	local curCost = gCostCsv.cross_mine_revenge_buy_cost[times]
	local params = {
		cb = function()
			gGameApp:requestServer("/cross/mine/times/buy", function()
				if callBack then
					callBack()
				end
			end, "revenge")
		end,
		isRich = true,
		btnType = 2,
		content = string.format(gLanguageCsv.richCostDiamond, curCost) .. gLanguageCsv.pvpRevengeBuyTimes,
		dialogParams = {clickClose = false},
	}
	gGameUI:showDialog(params)
end

return CrossMineCombatRecordView