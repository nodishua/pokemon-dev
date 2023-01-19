-- @date:   2021-03-08
-- @desc:   勇者挑战
local BCAdapt = require("app.views.city.activity.brave_challenge.adapt")

local ViewBase = cc.load("mvc").ViewBase
local BraveChallengeGateView = class("BraveChallengeGateView",ViewBase)

local ACTION_TIME = 0.5
local START_TIME  = 1

local GATE_COLOR = {
	ui.COLORS.NORMAL.WHITE,
	ui.COLORS.NORMAL.DEFAULT,
	ui.COLORS.NORMAL.GRAY,
}

BraveChallengeGateView.RESOURCE_FILENAME = "activity_brave_challenge_gate.json"
BraveChallengeGateView.RESOURCE_BINDING = {
	["itemGate"] = "itemGate",
	["itemGate.imgAward.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}}
		}
	},
	["panelTop.enemyText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(91, 84, 91, 255), size = 4}}
		}
	},
	["item01"] = "item01",
	["panelLeft.listGate"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("gateDatas"),
				item = bindHelper.self("itemGate"),
				asyncPreload = 10,
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgDi01","imgDi02","imgDi03","txtInfo","imgAward")
					childs.imgDi01:visible(v.sign == 1)
					childs.imgDi02:visible(v.sign == 2)
					childs.imgDi03:visible(v.sign == 3)
					text.addEffect(childs.txtInfo, {color = GATE_COLOR[v.sign]})
					childs.txtInfo:text(v.name)
					childs.imgAward:texture(v.firstPass and "activity/brave_challenge/icon_yztz_box1.png" or "activity/brave_challenge/icon_yztz_box2.png")
					childs.imgAward:get("txt"):text(v.firstPass and gLanguageCsv.bcGateTip04 or gLanguageCsv.bcGateTip03)
					childs.imgAward:visible(v.sign >= 2)
					if not v.firstPass then
						bind.touch(list, childs.imgAward, {methods = {ended = functools.partial(list.showAward, k, v)}})
					end
				end,
				preloadCenter = bindHelper.self("floorID"),
			},
			handlers = {
				showAward = bindHelper.self("onShowAward"),
			},
		}
	},

	["panelTop.listEnemyLineUp"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("enemyDatas"),
				item = bindHelper.self("item01"),
				asyncPreload = 10,
				onItem = function(list, node, k ,v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							rarity = v.rarity,
							advance = v.advance,
							isBoss = v.isBoss,
							showAttribute = true,
							levelProps = {
								data = v.level,
							},
							onNode = function(panel)
								local x, y = panel:xy()
								panel:scale(0.8)
								node:scale(v.isBoss and 1 or 0.9)
							end,
						}
					})
				end,
				asyncPreload = 6,
			}
	 	}
	},
	["panelTop.listInfoLineUp"] = "listInfoLineUp",
	["panelTop.btnBadge"] = {
		varname = "btnBadge",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBadge")},
		},
	},
	["panelDown.btnReady"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnReady")},
		}
	},
	["panelDown.btnReady.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}}
		}
	},
	["panelDown.btnQuit"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnQuit")},
		}
	},
	["panelDown.btnQuit.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}}
		}
	},
	["panelTop.btnBadge.txtBadge02"] = {
		binds = {
			event = "effect",
			data = {outline = {color =cc.c4b(244, 144, 15, 255), size = 4}}
		}
	},
	["panelTop.btnBadge.txtRareBadgeNum"] = {
		binds ={
			{
				event = "text",
				idler = bindHelper.self("rateBadge"),
			},
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
			}

		},
	},
	["panelTop.btnBadge.txtGenBadgeNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("genBadge"),
		}
	},
	["panelTop"] = "panelTop",
	["panelLeft"] = "panelLeft",
	["panelDown"] = "panelDown",
}

function BraveChallengeGateView:onCreate(params)
	self:initModel()

	self.parent = params.parent
	self.gateDatas = idlertable.new({})
	self.enemyDatas = idlertable.new({})
	self.genBadge = idler.new(0)
	self.rateBadge = idler.new(0)
	self.floorID = 1
	self.floorDatas = {}
	self.sign = false
	self.badgeSign = true
	self.startGenBader = 0
	self.startRateBader = 0

	self.lastCards = clone(self.gameInfo:read().cards)
	self.diffCardHash = {}
	self:initFloor()
	idlereasy.when(self.gameInfo, function(_, val)
		-- statu的状态刷新可能延后gameInfo
		-- 界面关闭的时候game数据没有移除，只能通过判断0来
		if val.floorID == 0 or val.monsterID == 0 then
			return
		end
		self.floorID = self.floorDatas[val.floorID] or 1
		self:getFloorConfig(self.floorID)
		self:initMonsterEmbattle(val.monsterID)
		self:initMonsterInfo(val.floorID,val.monsterID)

		if val.new_badges and table.nums(val.new_badges) > 0 then
			self:showSelectBadge(val.new_badges)
		end

		self:setCardSprite(val.deployments)

		self:getDiffCardhash(val.cards)
	end)

	idlereasy.when(self.badges, function (_, badges)
		self:getNumByType(badges)
	end)

	self:runStartAction()
end

-- 初始化信息
function BraveChallengeGateView:initModel()
	self.id = gGameModel.brave_challenge:getIdler("yyID")
	self.status = gGameModel.brave_challenge:getIdler("status")
	self.gameInfo = gGameModel.brave_challenge:getIdler("game")
	self.badges = gGameModel.brave_challenge:getIdler("badges")
	self.floors = gGameModel.brave_challenge:getIdler("floors")
	self.passTimes = gGameModel.brave_challenge:getIdler("pass_times")
end

-- 不在活动时间，进入该界面自动返回
function BraveChallengeGateView:judgeGameIsOver()
	-- local endTime = self.parent:getEndTime()
	if self.parent.comingSoon then
		performWithDelay(self, function()
			self.parent:onClose()
		end, 1/60)
	end
end

function BraveChallengeGateView:initFloor()
	self.floorDatas = {}
	local csvInfo =self.parent:getBaseInfo()
	for index, data in csvPairs(csvInfo.gateSeq) do
		self.floorDatas[data] = index
	end
end

-- 进场函数
function BraveChallengeGateView:runStartAction()
	local dx, dy = self.panelDown:xy()
	local lx, ly = self.panelLeft:xy()
	local tx, ty = self.panelTop:xy()

	self.panelDown:xy(dx, dy - 300)
	self.panelLeft:xy(lx - 650, ly)
	self.panelTop:xy(tx, ty + 400)
	self.parent:showCardPanel(false)
	performWithDelay(self, function ()
		self.panelDown:runAction(cc.EaseOut:create(cc.MoveTo:create(ACTION_TIME, cc.p(dx,dy)), ACTION_TIME))
		self.panelLeft:runAction(cc.EaseOut:create(cc.MoveTo:create(ACTION_TIME, cc.p(lx,ly)), ACTION_TIME))

		self.panelTop:runAction(cc.Sequence:create(
				cc.EaseOut:create(cc.MoveTo:create(ACTION_TIME, cc.p(tx,ty)), ACTION_TIME),
				cc.CallFunc:create(function()
					self.parent:showCardPanel(true)
					self:openAchievementView()

					self:judgeGameIsOver()
				end),
			nil))
		self.parent:setType(3)
	end, 1/60)
end

function BraveChallengeGateView:getDiffCardhash(cards)
	self.diffCardHash  = {}
	for id , data in pairs(cards) do
		if not self.lastCards[id] then
			self.diffCardHash[id] = true
		end
	end
	self.lastCards = clone(cards)
end

-- 出场函数
function BraveChallengeGateView:runEndAction()
	self.parent:showCardPanel(false)
	local dx, dy = self.panelDown:xy()
	local lx, ly = self.panelLeft:xy()
	local tx, ty = self.panelTop:xy()
	self.panelDown:runAction(cc.EaseOut:create(cc.MoveTo:create(ACTION_TIME, cc.p(dx,dy - 300)), ACTION_TIME))
	self.panelLeft:runAction(cc.EaseOut:create(cc.MoveTo:create(ACTION_TIME, cc.p(lx - 650,ly)), ACTION_TIME))
	self.panelTop:runAction(cc.EaseOut:create(cc.MoveTo:create(ACTION_TIME, cc.p(tx,ty + 400)), ACTION_TIME))
end


-- 获取关卡信息
function BraveChallengeGateView:getFloorConfig(curFloor)

	local csvInfo =self.parent:getBaseInfo()
	local csvFloor = csv.brave_challenge.floor
	local tempGateData= {}
	local floorData = self.floors:read()
	for index, data in csvPairs(csvInfo.gateSeq) do
		local curFloorInfo = csvFloor[data]
		local info = {
			id = index,
			firstAward = curFloorInfo.firstAward,
			monsterDesc = curFloorInfo.monsterDesc,
			name = curFloorInfo.name,
			desc = curFloorInfo.desc,
			floor = curFloorInfo.floor,
			sign = index > curFloor and 3 or (index == curFloor and 2 or 1),
			firstPass = floorData[curFloorInfo.floor] == 1
		}
		table.insert(tempGateData, info)
	end
	self.gateDatas:set(tempGateData)
end

-- 设置怪物信息
function BraveChallengeGateView:initMonsterEmbattle(monsterID)
	local csvMonster = csv.brave_challenge.monster[monsterID]
	local csvCards = csv.brave_challenge.cards

	local tempMonsterDatas = {}
	for index, data in csvPairs(csvMonster.cards) do
		local csvCard = csvCards[data]
		if csvCard then
			local unitID = csv.cards[csvCard.cardID].unitID
			local csvUnit  =  csv.unit[unitID]

			local item = {
				cardId = csvCard.cardID,
				unitId = unitID,
				level = csvCard.level,
				star = csvCard.star,
				advance = csvCard.advance,
				rarity = csvUnit.rarity,
				attr1 = csvUnit.natureType,
				attr2 = csvUnit.natureType2,
				isBoss = false,
			}

			for index, id in csvPairs(csvMonster.boss) do
				if id == data then
					item.isBoss = true
				end
			end

			table.insert(tempMonsterDatas, item)
		end
	end

	table.sort(tempMonsterDatas, function(v1, v2)
		if v1.isBoss ~= v2.isBoss then
			return v1.isBoss
		end
		return v1.advance > v2.advance
	end)

	self.enemyDatas:set(tempMonsterDatas)
end

-- 打开通关界面
function BraveChallengeGateView:openAchievementView()
	local info = self.gameInfo:read()
	if info.pass then
		local base = self.parent:getBaseInfo()
		local itemData = {}
		local got = self.passTimes:read() == 1
		itemData[base.achievementID] = 1

		if base.achievementID == 0 then
			local lastGate = base.gateSeq[table.nums(base.gateSeq)]
			itemData = csv.brave_challenge.floor[lastGate].extraAward
			got = true
		end

		gGameUI:stackUI("city.activity.brave_challenge.gain_achievement", nil, nil, { itemData = itemData,
		sendQuit = self:createHandler("sendQuit"), got = got, lastAnimation = base.lastAnimation})
	end
end

function BraveChallengeGateView:initMonsterInfo(floorID,monsterID)
	local csvFloor = csv.brave_challenge.floor[floorID]
	local csvMonster = csv.brave_challenge.monster[monsterID]
	beauty.textScroll({
		list = self.listInfoLineUp,
		strs = string.format(gLanguageCsv.bcGateTip01, csvMonster.desc == "" and csvFloor.desc or csvMonster.desc),
		isRich = true,
	})
end


function BraveChallengeGateView:playBadgeEffect(badges)
	if self.badgeSign then
		self.startGenBader = badges[1] or 0
		self.startRateBader = badges[2] or 0
		self.badgeSign = false

		self.effectGen = widget.addAnimationByKey(self, "effect/xunzhangxuanze.skel", "effectGen", "", 100)
		self.effectGen :xy(1270, 635)
		self.effectGen :scale(2)

		self.effectRate = widget.addAnimationByKey(self, "effect/xunzhangxuanze.skel", "effectRate", "", 100)
        self.effectRate:xy(1270, 700)
        self.effectRate:scale(2)
	else
		local gen = badges[1] or 0
		if self.startGenBader ~= gen then
			self.effectGen:play("effect_hou")
			self.startGenBader = gen
		end
		local rate = badges[2] or 0
		if self.startRateBader ~= rate then
			self.effectRate:play("effect_hou")
			self.startRateBader = rate
		end
	end
end

-- 设置徽章
function BraveChallengeGateView:getNumByType(badges)
	local csvBadge = csv.brave_challenge.badge
	local rarityTable = {}
	for tp, childBadges in pairs(badges) do
		for index, badge in pairs(childBadges) do
			local info = csvBadge[badge]
			if rarityTable[info.rarity] == nil then
				rarityTable[info.rarity] = 1
			else
				rarityTable[info.rarity] = rarityTable[info.rarity] + 1
			end
		end
	end

	-- 增加特效层，初始化的时候
	self:playBadgeEffect(rarityTable)

	self.genBadge:set(rarityTable[1] or 0)
	self.rateBadge:set(rarityTable[2] or 0)

end

-- 展示精灵
function BraveChallengeGateView:setCardSprite(csvDatas)
	local csvCards = csv.brave_challenge.cards
	local CardDatas = {}
	for index, csvID in ipairs(csvDatas) do
		local csvCard = csvCards[csvID]
		if csvCard then
			local unitID = csv.cards[csvCard.cardID].unitID
			CardDatas[#CardDatas + 1] = {
				csvID = csvID,
				unit_id = unitID,
			}
		end
	end
	self.sign = #CardDatas == 0
	self.parent:showCardsDeployments(CardDatas)
end

--打开选择徽章数据(从游戏返回界面重建的时候打开界面不生效，延时处理)
function BraveChallengeGateView:showSelectBadge(badges)
	performWithDelay(self, function ()
		gGameUI:stackUI("city.activity.brave_challenge.select_badge", nil, nil, badges)
	end, 1/60)
end



-- 展示奖励
-- firstAward 奖励数据
function BraveChallengeGateView:onShowAward(list, k ,v)
	if itertools.size(v.firstAward) ~= 0 then
		local str = gLanguageCsv.braveChallengeFirstBox
		gGameUI:showBoxDetail({
			data = v.firstAward,
			content = str,
			state = 1
		})
	end
end


-- 点击查看徽章详情
function BraveChallengeGateView:onBtnBadge()
	local tempBadges = {}
	for tp, childBadges in pairs(self.badges:read()) do
		for index, badge in pairs(childBadges) do
			table.insert(tempBadges, badge)
		end
	end

	gGameUI:stackUI("city.activity.brave_challenge.badge", nil, nil, tempBadges, 1)
end


-- 准备
function BraveChallengeGateView:onBtnReady()
	gGameUI:disableTouchDispatch(nil, false)

	local func = function()
		gGameUI:stackUI("city.activity.brave_challenge.embattle",nil,{full = true},
			{fightCb = self:createHandler("startFighting"), newCards = self.diffCardHash})
		self.parent:resetPanelPos()
		gGameUI:disableTouchDispatch(nil, true)
	end

	if self.sign then
		func()
	else
		self.parent:runCardAction()
		self:runAction(cc.Sequence:create(
				cc.DelayTime:create(START_TIME),
				cc.CallFunc:create(func),
			nil))
	end

end

-- 战斗
function BraveChallengeGateView:startFighting(view, battleCards)

	self.parent:startFighting(view, battleCards)

end


function BraveChallengeGateView:sendQuit(isOver)
	gGameApp:requestServer(BCAdapt.url("quit"),function (tb)
		self.parent:onClose()
		if not isOver then
			gGameUI:showDialog({
				strs= {gLanguageCsv.bcGateTip05},
				btnType = 1,
				dialogParams = {clickClose = false},
			})
		end
	end,self.id:read())
end

--放弃
function BraveChallengeGateView:onBtnQuit()
	gGameUI:showDialog({
			strs= {gLanguageCsv.bcGateTip02},
			cb = function()
				self:sendQuit(false)
			end,
			btnType = 2,
			dialogParams = {clickClose = false},
		})
end


return BraveChallengeGateView