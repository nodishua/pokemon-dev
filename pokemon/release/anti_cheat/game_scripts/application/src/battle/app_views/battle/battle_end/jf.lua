-- @date:   2019-03-18
-- @desc:   竞技场回放结束界面

local BattleEndJFView = class("BattleEndJFView", cc.load("mvc").ViewBase)

BattleEndJFView.RESOURCE_FILENAME = "battle_end_jf.json"
BattleEndJFView.RESOURCE_BINDING = {
	["playBackPanel"] = "playBackPanel",
	["playBackPanel.playBackBg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPlayBackClick")},
		},
	},
	["playBackPanel.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["exitPanel"] = "exitPanel",
	["exitPanel.exitBg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onQuitClick")},
		},
	},
	["exitPanel.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["imgBg"] = {
		varname = "imgBg",
		binds = {
			event = "click",
			method = bindHelper.self("onQuitClick"),
		},
	},
	["imgRankBg"] = "imgRankRoot",
	["imgRankBg.rankUp"] = "changeNum",
	["imgRankBg.rank"] = "myNum",
	["imgRankBg.imgUp"] = "upIcon",
	["imgRankBg.bg"] = "rankBg",
	["imgRankBg.tip"] = "numTipType",
}

-- 播放基本特效
function BattleEndJFView:playEffect()
	local isFail = self.isFail
	-- 结算特效
	local pnode = self:getResourceNode()
	local x,y = pnode:get("title"):xy()
	widget.addAnimation(pnode, "level/zhandoujiangli.skel", isFail and "zhandoushibai" or "zhandoushengli", 100)
		:anchorPoint(cc.p(0.5,1.0))
		:xy(x,y)
		:addPlay(isFail and "zhandoushibai_loop" or "zhandoushengli_loop")
end

function BattleEndJFView:onCreate(sceneID, data, results, cb)
	self.cb = cb
	self.data = data
	self.results = results
	self.isFail = self.results.result ~= "win"
	if self.isFail then
		self.imgBg:texture("city/pvp/reward/bg_pvp_lose.png")
		-- self.upIcon:texture("common/icon/logo_arrow_red.png")
		self.rankBg:texture("battle/online_fight/img_lose_bg.png")
		text.addEffect(self.numTipType,{italic = {},outline={color=cc.c4b(97, 117, 156,255)}})
	else
		self.imgBg:texture("city/pvp/reward/bg_pvp_win.png")
		-- self.upIcon:texture("common/icon/logo_arrow_green.png")
		self.rankBg:texture("battle/online_fight/img_win_bg.png")
		text.addEffect(self.numTipType,{italic = {},outline={color=cc.c4b(235, 99, 54,255)}})
	end

	if self.results.fromRecord then
		self.imgRankRoot:visible(false)
		self.playBackPanel:y(self.playBackPanel:y() + 70)
		self.exitPanel:y(self.exitPanel:y() + 70)
	else
		local serverDataView = results.serverData.view
		self.changeNum:visible(true)
		self.upIcon:visible(true)
		if serverDataView.rank_move >= 0 then
			self.upIcon:texture("common/icon/logo_arrow_green.png")
		else
			self.upIcon:texture("common/icon/logo_arrow_red.png")
		end
		self.myNum:text(serverDataView.rank)
		self.changeNum:text(math.abs(serverDataView.rank_move))
	end

	-- text.addEffect(self.numTipType,{italic = {}})

	self:playEffect()

	if results.from == "ban_embattle" then
		ccui.ImageView:create("battle/scene/bg_dzjjc.png")
			:scale(2)
			:xy(display.sizeInView.width/2, display.sizeInView.height/2)
			:addTo(self:getResourceNode(), 0)
	end
end

-- function BattleEndJFView:initModes(modes)
-- 	self.modes = modes
-- 	if self.modes.isRecord or 								--回放
-- 		not self.isFail or 									--胜利
-- 		self.data.gateType == game.GATE_TYPE.friendFight	--切磋
-- 		then
-- 		local y = self.exitPanel:y() + 200
-- 		self.exitPanel:y(y)
-- 		self.playBackPanel:y(y)
-- 		self.txt:hide()
-- 	end
-- end

function BattleEndJFView:onPlayBackClick()
	if self.results.from == "ban_embattle" then
		gGameUI:showTip(gLanguageCsv.noPlayBack)
		return
	end

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
end

function BattleEndJFView:onQuitClick()
	if self.cb then
		self:addCallbackOnExit(self.cb)
		self:onClose()
	else
		gGameUI:switchUI("city.view")
	end
end

return BattleEndJFView