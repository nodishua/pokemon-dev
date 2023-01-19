
--
-- 查看选中角色的属性面板, 显示在屏幕中央, 只能在非自动战斗状态下, 释放技能间隙点击精灵来查看
--


local ViewBase = cc.load("mvc").ViewBase
local BattlePauseView = class("BattlePauseView", ViewBase)

local setScale = function(view, node)
	node:scale(0.95)
end

local resumeScale = function(view, node)
	node:scale(1)
end

BattlePauseView.RESOURCE_FILENAME = "battle_pause.json"
BattlePauseView.RESOURCE_BINDING = {
	["text2"] = "text2",
	["setBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSetBtnClick")}
		},
	},
	["backBtn"] = {
		binds = {
			event = "touch",
			methods = {
				began = setScale,
				ended = bindHelper.self("onBackBtnClick"),
				cancelled = resumeScale,
			}
		},
	},
	["restartBtn"] = {
		binds = {
			event = "touch",
			methods = {
				began = setScale,
				ended = bindHelper.self("onRestartBtnClick"),
				cancelled = resumeScale,
			}
		},
	},
	["continueBtn"] = {
		binds = {
			event = "touch",
			methods = {
				began = setScale,
				ended = bindHelper.self("onClose"),
				cancelled = resumeScale,
			}
		},
	},
	["setBtn.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["backBtn.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["restartBtn.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["continueBtn.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
}

local btnTb = {
	["setBtn"] = "battleSet",
	["backBtn"] = "battleBack",
	["restartBtn"] = "battleRestart",
	["continueBtn"] = "battleContinue",
}

function BattlePauseView:onCreate(battleView)
	display.director:pause()
	self.text2:ignoreContentAdaptWithSize(false)
	self.text2:setContentSize(cc.size(410,200))
    self.text2:setTextVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
    self.text2:setTextHorizontalAlignment(cc.TEXT_ALIGNMENT_LEFT)
    self.text2:getVirtualRenderer():setLineSpacing(-8)

	self.battleView = battleView
	local pnode = self:getResourceNode()

	for btnName, str in pairs(btnTb) do
		local textWgt = pnode:get(btnName .. ".text")
		textWgt:setString(gLanguageCsv[str])
		text.addEffect(textWgt, {outline={color=ui.COLORS.NORMAL.WHITE, size=4}})	-- #fffced
	end
	pnode:get("setBtn"):setVisible(false)		-- 隐藏掉设置按钮 暂时没用

	if not battle.PauseNoShowStarConditionsGateType[battleView.gateType] then
		-- 普通暂停界面 显示星级
		local conditionTb = self.battleView:getPlayModel():getStarConditions()
		if not conditionTb then
			-- performWithDelay(self, handler(self, "onClose"), 0)
			return
		end
		self.conditionTb = conditionTb
		-- 设置条件文字
		for i=1, 3 do
			local idx, needNum = conditionTb[i][1], conditionTb[i][2]
			local textNode = pnode:get("text" .. i)
			textNode:setString(string.format(gLanguageCsv["starCondition" .. idx], needNum))
			-- 默认绿色的字
			text.addEffect(textNode, {color=ui.COLORS.NORMAL.LIGHT_GREEN})
			-- 设置数量  (当前/需求量)
			local countNode = pnode:get("count" .. i)
			countNode:setString(string.format("(%s/%s)", 0, needNum))
			text.addEffect(countNode, {color=ui.COLORS.NORMAL.LIGHT_GREEN})
		end
	else
		-- 无尽塔暂停界面 隐藏星级相关的信息 并使按钮上移
		for i = 1,3 do
			pnode:get("text" .. i):hide()
			pnode:get("count" .. i):hide()
			pnode:get("star" .. i):hide()
		end

		for btnName, str in pairs(btnTb) do
			local btn = pnode:get(btnName)
			local x,y = btn:xy()
			btn:xy(x,y+300)
		end
	end

	self:showPanel()
end

-- 显示界面, 给外部用的
function BattlePauseView:showPanel()
	if not self.conditionTb then return end

	local pnode = self:getResourceNode()
	-- 获取条件达成的状态记录
	local _, tb = self.battleView:getPlayModel():getGateStar()
	-- 设置条件文字
	for i=1, 3 do
		local cond = tb[i][1]
		local num = tb[i][2]  or 0
		local needNum = self.conditionTb[i][2]
		-- 设置数量  (当前/需求量)
		local countNode = pnode:get("count" .. i)
		countNode:setString(string.format("(%s/%s)", num, needNum))
		if not cond then
			local textNode = pnode:get("text" .. i)
			text.addEffect(textNode, {color=cc.c4b(236, 183, 42, 255)})		-- 某种黄色 #ECB72A
			text.addEffect(countNode, {color=cc.c4b(236, 183, 42, 255)})
		end
		pnode:get("star" .. i .. ".achieve"):setVisible(cond)
	end
end

function BattlePauseView:onSetBtnClick()
end

function BattlePauseView:onClose()
	display.director:resume()			-- 暂停页面退出或跳转时不能忘记恢复暂停!!!
	audio.resumeAllSounds()
	ViewBase.onClose(self)
end

function BattlePauseView:onBackBtnClick()
	audio.stopAllSounds()
	display.director:resume()
	gGameUI:switchUI("city.view")
end

local ClientCanReseedRandom = {
	[game.GATE_TYPE.normal] = true,
	[game.GATE_TYPE.endlessTower] = false, -- anti server
	[game.GATE_TYPE.randomTower] = true,
	[game.GATE_TYPE.dailyGold] = true,
	[game.GATE_TYPE.dailyExp] = true,
	[game.GATE_TYPE.fragment] = true,
	[game.GATE_TYPE.simpleActivity] = true,
	[game.GATE_TYPE.gift] = true,
	[game.GATE_TYPE.unionFuben] = true,
	[game.GATE_TYPE.gym] = true,
	[game.GATE_TYPE.huoDongBoss] = true,
	[game.GATE_TYPE.braveChallenge] = false, -- anti server
	[game.GATE_TYPE.summerChallenge] = false, -- anti server
	[game.GATE_TYPE.hunting] = true,
}

function BattlePauseView:onRestartBtnClick()
	display.director:resume()
	display.director:getScheduler():setTimeScale(1)
	local data = self.battleView.data
	local entrance = self.battleView.entrance

	assert(data and entrance, "data and entrance was nil !")

	if data.play_record_id and data.cross_key and data.record_url then
		gGameModel:playRecordBattle(data.play_record_id, data.cross_key, data.record_url, 0)
		return
	end

	if self.battleView.modes.isRecord then
		battleEntrance.battleRecord(data, {}):show()
	else
		-- 针对普通副本开放，后期服务器不参与计算和校验的可以客户端自己随机
		-- 还要考虑玩家恶性刷，用最低成本获取通关好处的可能
		if data.randSeed then
			if ClientCanReseedRandom[data.gateType] then
				data.randSeed = math.random(1, 99999999)
				local title = string.format("\n\n\t\tbattle reseed - gate=%s, new_seed=%s, scene=%s\n\n", data.gateType, data.randSeed, data.sceneID)
				printInfo(title)
				log.battle(title)

				gGameUI:switchUI("battle.loading", data, data.sceneID, nil, entrance)

			else
				-- same as BattleEndlessFailView:playRecord
				entrance:restart()
			end
		end
	end
end

return BattlePauseView

