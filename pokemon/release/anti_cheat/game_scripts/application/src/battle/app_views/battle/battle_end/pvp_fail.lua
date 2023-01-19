-- @date:   2019-03-18
-- @desc:   竞技场回放结束界面

local BattleEndPvpFailView = class("BattleEndPvpFailView", cc.load("mvc").ViewBase)

BattleEndPvpFailView.RESOURCE_FILENAME = "battle_end_pvp_fail.json"
BattleEndPvpFailView.RESOURCE_BINDING = {
	["txt"] = {
		varname = "txt",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.DEFAULT}, italic=true}
		}
	},
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
	["quitPanel"] = "quitPanel",
	["quitPanel.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["quitPanel.quitBg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onQuitClick")},
		},
	},
	["imgBg"] = {
		varname = "imgBg",
		binds = {
			event = "click",
			method = bindHelper.self("onQuitClick"),
		},
	},
}

local GateFailStyle = {
	[game.GATE_TYPE.summerChallenge] = function(self)
		local y = self.quitPanel:y() + 200
		local x = self.quitPanel:x() - (self.quitPanel:x() - self.playBackPanel:x())/2
		self.quitPanel:y(y)
		self.quitPanel:x(x)
		self.playBackPanel:hide()
		self.txt:hide()
	end
}

-- 播放基本特效
function BattleEndPvpFailView:playEffect()
	local isFail = self.isFail
	-- 结算特效
	local pnode = self:getResourceNode()
	local x,y = pnode:get("title"):xy()
	widget.addAnimation(pnode, "level/zhandoujiangli.skel", isFail and "zhandoushibai" or "zhandoushengli", 100)
		:anchorPoint(cc.p(0.5,1.0))
		:xy(x,y + 300)
		:addPlay(isFail and "zhandoushibai_loop" or "zhandoushengli_loop")
end

function BattleEndPvpFailView:onCreate(sceneID, data, results)
	self.data = data
	self.results = results
	self.isFail = self.results.result ~= "win"
	if self.isFail then
		self.imgBg:texture("city/pvp/reward/bg_pvp_lose.png")
	else
		self.imgBg:texture("city/pvp/reward/bg_pvp_win.png")
	end

	if self.data.gateType == game.GATE_TYPE.gymLeader
      or self.data.gateType == game.GATE_TYPE.gym
	  or self.data.gateType == game.GATE_TYPE.crossGym then
		local pnode = self:getResourceNode()
		pnode:get("txt"):text(gLanguageCsv.gymLeaderBattleFail)
	end

	self:playEffect()
end

function BattleEndPvpFailView:initModes(modes)
	self.modes = modes

	if GateFailStyle[self.data.gateType] then
		GateFailStyle[self.data.gateType](self)
	end

	if self.modes.isRecord or 								--回放
		not self.isFail or 									--胜利
		self.data.gateType == game.GATE_TYPE.friendFight	--切磋
		then
		local y = self.quitPanel:y() + 200
		self.quitPanel:y(y)
		self.playBackPanel:y(y)
		self.txt:hide()
	end
end

function BattleEndPvpFailView:onPlayBackClick()
	battleEntrance.battleRecord(self.data, self.results):show()
end

function BattleEndPvpFailView:onQuitClick()
	gGameUI:switchUI("city.view")
end

return BattleEndPvpFailView