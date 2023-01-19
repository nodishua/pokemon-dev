-- @date:   2019-03-15
-- @desc:   竞技场结束界面

local BattleEndPvpWinView = class("BattleEndPvpWinView", cc.load("mvc").ViewBase)
BattleEndPvpWinView.RESOURCE_FILENAME = "battle_end_pvp_win.json"
BattleEndPvpWinView.RESOURCE_BINDING = {
	["imgBestBg.bestName"] = {
		varname = "bestName",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.RED}, italic=true}
		}
	},
	["playBackPanel"] = "playBackPanel",
	["playBackPanel.playBackBg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlayBackBtnClick")},
		},
	},
	["playBackPanel.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["sharePanel"] = "sharePanel",
	["sharePanel.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["sharePanel.shareBg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShareBtnClick")},
		},
	},
	["imgBg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onCloseClick"),
		},
	},
	["imgRankBg"] = "imgRankPanel",
	["imgRankBg.bg"] = "imgRankBg",
	["imgNewRecord"] = "newRecord",
	["imgBestCard"] = "bestCard",
	["imgRankBg.rank"] = {
		varname = "rank",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.RED}, italic=true}
		}
	},
	["imgRankBg.rankUp"] = {
		varname = "rankUp",
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(235, 99, 54, 255), size = 4}}
		}
	},
	["imgRankBg.imgUp"] = "imgUp",
}

-- 播放基本特效
function BattleEndPvpWinView:playEffect()
	-- 结算特效
	local pnode = self:getResourceNode()
	widget.addAnimationByKey(pnode, "level/zhandoujiangli.skel", "selEffect", "zhandoushengli", 100)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:get("title"):xy())
		:addPlay("zhandoushengli_loop")
end

-- 播放全场最佳
function BattleEndPvpWinView:plsyBestEffect()
	-- 结算特效
	local pnode = self:getResourceNode()
	 widget.addAnimationByKey(pnode, "level/zhandoujiangli.skel", "selEffect2", "quanchangzuijia", 2)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(self.bestCard:xy())
		:addPlay("quanchangzuijia_loop")
end

function BattleEndPvpWinView:onCreate(sceneID, data, results)
	audio.playEffectWithWeekBGM("pvp_win.mp3")
	self.data = data
	self.results = results
	-- TODO: 看战报没有serverData，换UI了，策划漏了，找庞康庭

	local roleOut = data.roleOut
	local pId = results.mvpPosId

	-- 在跨服竞技场胜利时 判断mvp在友方阵营第几阵容中, 获取该阵容
	if results.mvpCardIn then
		roleOut = data.roleOut[1][results.mvpCardIn]
	end

	-- TODO: 临时修改
	-- http://172.81.227.66:1104/crashinfo?ident=%5Bstring%22src%2Fbattle.app_views.battle.battle_end.pvp_win%22%5Dattempttoindexanilvalue&type=1
	if roleOut[pId] == nil and pId > 6 then
		pId = pId - 6
	end

	self.bestCardId = roleOut[pId].roleId
	local selectDbId = roleOut[pId].cardId
	local card = gGameModel.cards:find(selectDbId)
	local bestCardName
	if card then
		bestCardName = card:read("name")
	end
	if not card or not bestCardName or bestCardName == "" then
		local bestCardID = csv.unit[self.bestCardId].cardID
		bestCardName = csv.cards[bestCardID].name
	end

	if results.recordType and results.recordType == "jf" then
		self.imgRankBg:loadTexture("battle/end/win/img_jifen_bg.png")
	end

	self:playEffect()

	-- 全场最佳的icon和名字通过输出最高的卡牌id获得
	self:cardPosCorrect()
	self.bestName:text(bestCardName)
	self:bestCardScale()

	self:plsyBestEffect()

	local serverDataView = results.serverData.view
	-- topMove为上升的记录，当大于0的时候表示最高记录
	local topMove = serverDataView.top_move or 0
	local curRank = serverDataView.rank
	local preRank = curRank and curRank + serverDataView.rank_move
	self.newRecord:visible(topMove > 0)
	if results.flag == "crossArena" then
		local predata = dataEasy.getCrossArenaStageByRank(preRank)
		local curdata = dataEasy.getCrossArenaStageByRank(curRank)
		local prestr = predata.stageName .. " " .. predata.rank
		local curstr = curdata.stageName .. " " .. curdata.rank
		self.rank:text(prestr)
		self.rankUp:text(curstr)
		self.rankUp:setRotationSkewX(12)
		adapt.oneLineCenterPos(cc.p(550, 80), {self.rank, self.imgUp, self.rankUp}, cc.p(40, 0))
		self.newRecord:y(900)
		-- 自适应背景底大小
		local x = self.rank:x() - self.rank:anchorPoint().x * self.rank:width()
		local width = self.rankUp:x() + (1 - self.rankUp:anchorPoint().x) * self.rankUp:width() - x
		local headLength = 240
		self.imgRankBg:x(x - headLength):width(width + headLength)

		self.crossData = table.deepcopy(gGameModel.cross_arena:read("record").history, true)
		table.sort(self.crossData, function(a, b)
			return a.time > b.time
		end)
	elseif results.flag == "onlineFight" then
		if self.results.serverData.view.pattern == 1 then
			self.crossData = table.deepcopy(gGameModel.cross_online_fight:read("unlimited_history"), true)
		else
			self.crossData = table.deepcopy(gGameModel.cross_online_fight:read("limited_history"), true)
		end

		table.sort(self.crossData, function(a, b)
			return a.time > b.time
		end)

		self.rank:text(curRank)
		self.rankUp:text(serverDataView.rank_move)
		adapt.oneLineCenterPos(cc.p(400, 80), {self.rank, self.imgUp, self.rankUp}, cc.p(20, 0))
	elseif results.flag == "gymLeader" then
		local posx, posy = self.imgRankPanel:x(), self.imgRankPanel:y()
		self.newRecord:loadTexture("city/pvp/reward/panle_gx.png")
		:scale(1)
		:visible(true)
		:xy(posx, posy)
		local richStr = results.gymMember and gLanguageCsv.gymMemberBattleWin or string.format(gLanguageCsv.gymLeaderBattleWin,results.gymName)
		local fontSize = matchLanguage({"kr","en"}) and 65 or 80
		rich.createByStr(richStr,fontSize)
		:anchorPoint(0.5,0.5)
		:xy(posx, posy+22)
		:addTo(self.newRecord:parent())
		:z(10)
		self.imgRankPanel:hide()
		self.sharePanel:hide()
	elseif results.flag == "crossMine" then
		local posx, posy = self.imgRankPanel:x(), self.imgRankPanel:y()
		self.imgRankPanel:xy(posx, posy+150)
		if serverDataView.speed then
			local newSpeed = string.format(gLanguageCsv.crossMinePVPSpeed, serverDataView.speed)
			rich.createByStr(newSpeed,50)
				:anchorPoint(0,0.5)
				:xy(posx-290, posy+50)
				:addTo(self.imgRankPanel:parent())
				:z(10)
		end
		if serverDataView.robNum then
			local rarityPanel = ccui.ImageView:create()
				:anchorPoint(0.5, 0.5)
				:xy(posx-200, posy-50)
				:addTo(self.imgRankPanel:parent())
				:texture("city/pvp/cross_mine/icon_kfzy.png"):show()
			local robNum = string.format(gLanguageCsv.crossMinePVPRob, serverDataView.robNum)
			rich.createByStr(robNum,60)
				:anchorPoint(0,0.5)
				:xy(posx-120, posy-50)
				:addTo(self.imgRankPanel:parent())
				:z(10)
		end
		self.rank:text(curRank)
		self.rankUp:text(serverDataView.rank_move)
		self.crossData = table.deepcopy(gGameModel.cross_mine:read("record").history, true)
	else
		self.rank:text(curRank)
		self.rankUp:text(serverDataView.rank_move)
		adapt.oneLineCenterPos(cc.p(400, 80), {self.rank, self.imgUp, self.rankUp}, cc.p(20, 0))
	end
end

function BattleEndPvpWinView:onPlayBackBtnClick()
	if self.results.flag == "onlineFight" then
		local data = self.data
		if not self.data.play_record_id or not self.data.cross_key then
			local crossData
			if self.results.serverData.view.pattern == 1 then
				crossData = table.deepcopy(gGameModel.cross_online_fight:read("unlimited_history"), true)
			else
				crossData = table.deepcopy(gGameModel.cross_online_fight:read("limited_history"), true)
			end
			table.sort(crossData, function(a, b)
				return a.time > b.time
			end)
			data = crossData[1]
		end
		gGameModel:playRecordBattle(data.play_record_id, data.cross_key, "/game/cross/online/playrecord/get", 0)
		return
	end
	battleEntrance.battleRecord(self.data, self.results):show()
end

-- TODO 分享到聊天界面
function BattleEndPvpWinView:onShareBtnClick()
	local shareKey,reqKey = "",""
	local data = self.data
	if self.results.flag == "crossArena" then
		shareKey = "cross_arena_battle_share_times"
		reqKey = "crossArena"
		data = self.crossData[1]
	elseif self.results.flag == "onlineFight" then
		shareKey = "cross_online_fight_share_times"
		reqKey = "onlineFight"
		data = self.crossData[1]
		data.enemy_name = data.enemy.name
	elseif self.results.flag == "crossMine" then
		shareKey = "cross_mine_share_times"
		reqKey = "crossMine"
		data = self.crossData[1]
	end

	if shareKey ~= "" and reqKey ~= "" then
		local battleShareTimes = gGameModel.daily_record:getIdler(shareKey):read()
		if battleShareTimes >= gCommonConfigCsv.shareTimesLimit then
			gGameUI:showTip(gLanguageCsv.shareTimesNotEnough)
			return
		end
		local leftTimes = gCommonConfigCsv.shareTimesLimit - battleShareTimes
		local params = {
			cb = function()
				gGameApp:requestServer("/game/battle/share", function(tb)
					gGameUI:showTip(gLanguageCsv.recordShareSuccess)
				end, data.play_record_id, data.enemy_name, reqKey, data.cross_key)
			end,
			isRich = false,
			btnType = 2,
			content = string.format(gLanguageCsv.shareBattleNote, leftTimes .. "/" .. gCommonConfigCsv.shareTimesLimit),
		}
		gGameUI:showDialog(params)
	else
		local data = self.data
		uiEasy.shareBattleToChat(data.battleID, data.names[2])
	end
end

function BattleEndPvpWinView:onCloseClick()
	if self.results.backCity == true then
		gGameUI:switchUI("city.view")
	elseif self.results.flag == "crossArena" then
		local showEndView = self.showEndView
		self:onClose()
		showEndView()
	else
		gGameUI:switchUI("city.view")
	end
end

-- 最佳卡牌位置修正
function BattleEndPvpWinView:cardPosCorrect()
	local originX, originY = self.bestCard:getPosition()
	local cardShowPosC = csv.unit[self.bestCardId].cardShowPosC
	local curX, curY = originX+cardShowPosC.x, originY+cardShowPosC.y
	self.bestCard:setPosition(curX, curY)
end

function BattleEndPvpWinView:bestCardScale()
	local cardShow = csv.unit[self.bestCardId].cardShow
	local cardShowScale = csv.unit[self.bestCardId].cardShowScale
	local pvpCardShowScale = gCommonConfigCsv.pvpCardShowScale

	local scale = cardShowScale*pvpCardShowScale
	self.bestCard:scale(scale)
	self.bestCard:texture(cardShow)
end

return BattleEndPvpWinView

