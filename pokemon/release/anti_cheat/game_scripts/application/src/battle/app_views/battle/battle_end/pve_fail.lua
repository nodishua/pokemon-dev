--
--  战斗失败界面 -- 通用的界面
--

local BattleEndFailView = class("BattleEndFailView", cc.load("mvc").ViewBase)
local BTN_TEXT_GLOW = {
	binds = {
		event = "effect",
		data = {glow = {color = ui.COLORS.GLOW.WHITE}},
	}
}
local BTN_TEXT_OUTLINE = {
	binds = {
		event = "effect",
		data = {outline = {color=ui.COLORS.NORMAL.WHITE}},
	}
}

BattleEndFailView.RESOURCE_FILENAME = "battle_end_pve_fail.json"
BattleEndFailView.RESOURCE_BINDING = {
	["eggBtn.text"] = BTN_TEXT_OUTLINE,
	["promoteBtn.text"] = BTN_TEXT_OUTLINE,
	["strengthBtn.text"] = BTN_TEXT_OUTLINE,
	["backBtn.text"] = BTN_TEXT_GLOW,
	["againBtn.text"] = BTN_TEXT_GLOW,
	["dungeonsBtn.text"] = BTN_TEXT_GLOW,
	["reStartBtn.text"] = BTN_TEXT_GLOW,
	["backCityBtn.text"] = BTN_TEXT_GLOW,
	["eggBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEggBtnClick")}
		},
	},
	["promoteBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPromoteBtnClick")}
		},
	},
	["strengthBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStrengthBtnClick")}
		},
	},
	["backBtn"] = {
		varname = "backBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBackBtnClick")}
		},
	},
	["againBtn"] = {
		varname = "againBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAgainBtnClick")}
		},
	},
	["dungeonsBtn"] = {
		varname = "dungeonsBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDungeonsBtnClick")}
		},
	},
	["reStartBtn"] = {
		varname = "reStartBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReStartBtnClick")}
		},
	},
	["backCityBtn"] = {
		varname = "backCityBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBackCityBtnClick")}
		},
	},
	["bkg"] = {
		varname = "bkg",
		binds = {
			event = "click",
			method = bindHelper.self("onBgClick"),
		},
	},
	["exitText"] = "exitText",
	["roundNums"] = {
		varname = "roundNums",
		binds = {
			event = "extend",
			class = "text_atlas",
			props = {
				data = bindHelper.self("rounds"),
				pathName = "frhd_num",
				isEqualDist = false,
				align = "center",
			}
		}
	}
}

function BattleEndFailView:playEndEffect()
	local pnode = self:getResourceNode()
	-- 结算特效
	local textEffect = CSprite.new("level/jiesuanshengli.skel")		-- 文字部分特效
	textEffect:addTo(pnode, 100)
	textEffect:setAnchorPoint(cc.p(0.5,1.0))
	textEffect:setPosition(pnode:get("title"):getPosition())
	textEffect:visible(true)
	-- 播放结算特效
	textEffect:play("jiesuan_shibaizi")
	textEffect:addPlay("jiesuan_shibaizi_loop")
	textEffect:retain()

	local bgEffect = CSprite.new("level/jiesuanshengli.skel")		-- 底部特效
	bgEffect:addTo(pnode, 99)
	bgEffect:setAnchorPoint(cc.p(0.5,1.0))
	bgEffect:setPosition(pnode:get("title"):getPosition())
	bgEffect:visible(true)
	-- 播放结算特效
	bgEffect:play("jiesuan_shibaitu")
	bgEffect:addPlay("jiesuan_shibaitu_loop")
	bgEffect:retain()
end

function BattleEndFailView:initMode(mode)
	mode = mode or 1
	local VIEW_MODE = {
		[1] = {-- 三按钮模式
			self.backBtn,
			self.againBtn,
			self.dungeonsBtn,
		},
		[2] = {-- 双按钮模式
			self.reStartBtn,
			self.backCityBtn,
		},
		[3] = {-- 点击背景退出
			self.bkg,
			self.exitText,
		}
	}
	for _, btn in pairs(VIEW_MODE[mode]) do
		btn:show()
	end
	self.bkg:setTouchEnabled(mode == 3)
end

-- results: 放数据的
function BattleEndFailView:onCreate(battleView, results, mode)
	audio.playEffectWithWeekBGM("battle_false.mp3")

	self.battleView = battleView
	self.sceneID = battleView.sceneID
	self.data = battleView.data
	self.results = results
	self:initMode(mode)

	if self.data.gateType == game.GATE_TYPE.braveChallenge then
		-- 回合
		self:getResourceNode():get("round"):text(gLanguageCsv.round .. " :"):show()
		self.rounds = results.round
		self.roundNums:show()
	end
	self:playEndEffect()
end

-- 重开
function BattleEndFailView:playRecord()
	-- 目前只有普通关卡用到
	-- 想要有请求的写法参考 BattleEndlessFailView:playRecord
	local data = self.data
	local entrance = self.battleView.entrance

	if data.gateType == game.GATE_TYPE.normal then
		entrance:restart()
		-- battleEntrance.battleRequest("/game/start_gate", data.sceneID):show()
	end
end

-- 返回城镇
function BattleEndFailView:backToCity()
	gGameUI:cleanStash()
	gGameUI:switchUI("city.view")
end
-- 返回列表
function BattleEndFailView:backToList()
	gGameUI:switchUI("city.view")
end

-- click	抽卡
function BattleEndFailView:onEggBtnClick()
	gGameUI:switchUI("city.view")
	gGameUI:stackUI("city.drawcard.view")
end

-- click	精灵提升
function BattleEndFailView:onPromoteBtnClick()
	gGameUI:cleanStash()
	gGameUI:switchUI("city.view")
	jumpEasy.jumpTo("strengthen")
end

-- click	饰品强化
function BattleEndFailView:onStrengthBtnClick()
	gGameUI:cleanStash()
	gGameUI:switchUI("city.view")
	jumpEasy.jumpTo("strengthen")
end

---------------------------模式一--------------------------------
-- 返回主城
function BattleEndFailView:onBackBtnClick()
	self:backToCity()
end
-- 再战一次
function BattleEndFailView:onAgainBtnClick()
	self:playRecord()
end
-- 关卡列表
function BattleEndFailView:onDungeonsBtnClick()
	self:backToList()
end
---------------------------模式二--------------------------------
-- 重开
function BattleEndFailView:onReStartBtnClick()
	self:playRecord()
end
-- 返回
function BattleEndFailView:onBackCityBtnClick()
	self:backToList()
end
---------------------------模式三--------------------------------
-- 点击背景
function BattleEndFailView:onBgClick()
	self:backToList()
end

return BattleEndFailView

