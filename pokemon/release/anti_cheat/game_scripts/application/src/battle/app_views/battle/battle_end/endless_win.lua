--
--  战斗胜利界面 -- 无尽塔界面
--

local BattleEndlessWinView = class("BattleEndlessWinView", cc.load("mvc").ViewBase)

BattleEndlessWinView.RESOURCE_FILENAME = "battle_end_endless_win.json"
BattleEndlessWinView.RESOURCE_BINDING = {
	["backBtn.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["againBtn.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["dungeonsBtn.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.WHITE}}
		}
	},
	["backBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBackBtnClick")}
		},
	},
	["againBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAgainBtnClick")}
		},
	},
	["dungeonsBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDungeonsBtnClick")}
		},
	},
	["awardsList"] = "awardsList",
	["cardItem.card"] = "awardsItem",
	["di"] = "di",
	["guan"] = "guan",
	["gateNum"] = "gateNum",
}

function BattleEndlessWinView:playEndEffect()
	local pnode = self:getResourceNode()
	-- 结算特效
	local textEffect = widget.addAnimation(pnode, "level/newzhandoushengli.skel", "effect", 100)
	textEffect:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:get("title"):getPosition())
		:addPlay("effect_loop")
end

-- results: 放数据的
function BattleEndlessWinView:onCreate(sceneID, data, results)
	audio.playEffectWithWeekBGM("gate_win.mp3")
	self.data = data
	self.results = results

	local pnode = self:getResourceNode()
	local btnTextTb = {
		backBtn = "back2City",
		againBtn = "nextGate",
		dungeonsBtn = "dungeonList",
	}
	for btnName, str in pairs(btnTextTb) do
		pnode:get(btnName .. ".text"):text(gLanguageCsv[str])
	end

	results = results or {}
	local serverData = results.serverData or {}
	local preData = data.preData or {}
	local roleInfo = preData.roleInfo or {}
	local cardsInfo = preData.cardsInfo or {}
	local dropInfo = serverData.view.drop or {}

	self.gateIdx = results.gateIdx or 1

	self:playEndEffect()

	-- 当前关卡文字
	pnode:get("curGate"):text(gLanguageCsv.curEndlessGateIdx  .. " :")
	-- 当前关卡数字
	pnode:get("gateNum"):text(self.gateIdx)

	-- 奖励文字 getAwards
	pnode:get("awardsText"):text(gLanguageCsv.getAwards  .. " :")

	local isDouble = dataEasy.isGateIdDoubleDrop(sceneID)
	if data.preData.isFirst then
		isDouble = false -- 首通不双倍
	end
	-- 普通掉落
	if next(dropInfo) ~= nil then
		local tmpData = {}
		for k,v in csvMapPairs(dropInfo) do
			table.insert(tmpData, {key = k, num = v, isDouble = isDouble})
		end
		self:showItem(1, tmpData)
	end
	adapt.oneLinePos(self.di, {self.gateNum,self.guan}, {cc.p(5,0),cc.p(5,0)})
end

function BattleEndlessWinView:showItem(index, data)
	local item = self.awardsItem:clone()
	item:show()
	local key = data[index].key
	local num = data[index].num
	local isDouble = data[index].isDouble
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
			},
			isDouble = isDouble,
			onNode = function(node)
				local x,y = node:xy()
				node:xy(x, y+3)
				node:hide()
					:z(2)
				transition.executeSequence(node, true)
					:delay(0.5)
					:func(function()
						node:show()
					end)
					:done()
			end,
		},
	}
	bind.extend(self, item, binds)
	self.awardsList:setItemsMargin(25)
	self.awardsList:pushBackCustomItem(item)
	self.awardsList:setScrollBarEnabled(false)
	transition.executeSequence(self.awardsList, true)
		:delay(0.25)
		:func(function()
			if index < csvSize(data) then
				self:showItem(index + 1, data)
			end
		end)
		:done()
end

-- 返回主城
function BattleEndlessWinView:onBackBtnClick()
	gGameUI:cleanStash()
	gGameUI:switchUI("city.view")
end

-- 下一关
function BattleEndlessWinView:onAgainBtnClick()
	local maxSize = csvSize(csv.endless_tower_scene)
	local nextIdx = self.gateIdx + 1
	if self.gateIdx >= maxSize then
		self:onDungeonsBtnClick()
		gGameUI:showTip(gLanguageCsv.allCheckpointscleared)
	else
		local rootView = gGameUI:switchUI("city.view")
		gGameUI:sendMessage("nextGate", nextIdx)
	end
end

-- 返回关卡列表
function BattleEndlessWinView:onDungeonsBtnClick()
	gGameUI:switchUI("city.view")
end

return BattleEndlessWinView

