-- @desc:   公会副本界面

require "battle.models.scene"
local unionTools = require "app.views.city.union.tools"
local UnionGateView = class("UnionGateView", cc.load("mvc").ViewBase)
UnionGateView.RESOURCE_FILENAME = "union_gate.json"
UnionGateView.RESOURCE_BINDING = {
	["right.ruleBtnPanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleBtn")}
		},
	},
	["right.ruleBtnPanel.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["right.rankBtnPanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRankBtn")}
		},
	},
	["right.rankBtnPanel.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["right.progressBtnPanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onProgressBtn")}
		},
	},
	["right.progressBtnPanel.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["right.rewardBtnPanel"] = {
		varname = "rewardBtnPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRewardBtn")}
		},
	},
	["right.rewardBtnPanel.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["leftPanel.item"] = "leftItem",
	["leftPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("gateDatas"),
				item = bindHelper.self("leftItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"icon",
						"imgSelect",
						"textOrder",
						"iconComplete",
						"iconLock",
						"imgLockBg"
					)
					childs.icon:texture(v.icon):visible(v.unlocked == 1)
					childs.imgSelect:visible(v.selectEffect == true)
					childs.textOrder:text(v.csvId)
					childs.iconComplete:visible(v.time > 0)
					childs.iconLock:visible(v.unlocked == 2)
					childs.imgLockBg:visible(v.unlocked == 2)
					node:setTouchEnabled(v.unlocked == 1)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k, v)}})
				end,
				asyncPreload = 6,
				preloadCenter = bindHelper.self("selectCsvId"),
			},
			handlers = {
				itemClick = bindHelper.self("onGateItemClick"),
			},
		},
	},
	["rewardItem"] = "rewardItem",
	["right.rightPanel.rewardList"] = {
		varname = "rewardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rewardDatas"),
				item = bindHelper.self("rewardItem"),
				onItem = function(list, node, k, v)
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
						},
					}
					bind.extend(list, node, binds)
				end,
			},
		},
	},
	["right.maskPanel"] = "maskPanel",
	["rankItem"] = "rankItem",
	["right.rightPanel.rankList"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankDatas"),
				item = bindHelper.self("rankItem"),
				-- dataOrderCmpGen = bindHelper.self("onSortRank", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"iconRank",
						"textRank1",
						"textRank2",
						"textName",
						"textDamage"
					)
					childs.textName:text(v.name)
					childs.textDamage:text(v.damage)
					uiEasy.setRankIcon(k, childs.iconRank, childs.textRank1, childs.textRank2)
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["centerPanel"] = "centerPanel",
	["centerPanel.textNum"] = {
		varname = "textNum",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}}
		}
	},
	["centerPanel.textNumNote"] = {
		varname = "textNumNote",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}}
		}
	},
	["centerPanel.btnFight"] = {
		varname = "btnFight",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnFight")}
		},
	},
	["centerPanel.btnThreeFight"] = {
		varname = "btnThreeFight",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnThreeFight")}
		},
	},
	["centerPanel.textDesc"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}}
		}
	},
	["centerPanel.textName"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}}
		}
	},
	["right.rightPanel.textRewardNote"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}}
		}
	},
	["right.empty"] = "empty",
	["right.rightPanel"] = "rightPanel",
	["right.rightPanel.listTitlePanel"] = "listTitlePanel",
	["right.rightPanel.textAttrNote"] = "textAttrNote",
	["right.rightPanel.textAttr"] = "textAttr",
	["right.rightPanel.textOpenTime"] = "textOpenTime",
}
UnionGateView.RESOURCE_STYLES = {
	full = true,
}

function UnionGateView:onCreate()
	gGameUI.topuiManager:createView("union", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.guild, subTitle = "CONSORTIA"})
	self:initModel()
	self.gateDatas = idlers.new()
	self.selectCsvId = idler.new(1)
	self.complete = idler.new(false) 	-- 是否已通关，默认false
	idlereasy.when(self.unionFuben, function(_, unionFuben)
		local tmpData = {}
		local selectCsvId = 1
		local hasLockData = false
		for k,v in orderCsvPairs(csv.union.union_fuben) do
			local csvScenes = csv.scene_conf[v.gateID]
			local gateData = unionFuben[k]
			if not gateData and not hasLockData then
				hasLockData = true
				table.insert(tmpData,{
					csvId = k,
					icon = csvScenes.icon,
					unlocked = 2,
					buff = 0,
					surplusHp = 0,
					maxHp = 0,
					damage = 0,
					time = 0,
				})
			elseif not itertools.isempty(gateData) then
				if k > selectCsvId then
					selectCsvId = k
				end
				table.insert(tmpData,{
					csvId = k,
					icon = csvScenes.icon,
					unlocked = 1,
					buff = gateData.buff,
					surplusHp = math.max(gateData.hpmax-gateData.damage, 0),
					maxHp = gateData.hpmax,
					damage = gateData.damage,
					time = gateData.time,
				})
			end
		end
		table.sort(tmpData, function(a,b)
			return a.csvId < b.csvId
		end)
		self.gateDatas:update(tmpData)
		self.selectCsvId:set(selectCsvId, true)
	end)
	self.rankDatas = idlertable.new({})
	self.rewardDatas = idlertable.new({})
	self.selectCsvId:addListener(function(val, oldval)
		local gateData = self.gateDatas:atproxy(val)
		local oldgateData = self.gateDatas:atproxy(oldval)
		if oldgateData then
			oldgateData.selectEffect = false
		end
		gateData.selectEffect = true
		local members = self.members:read()
		local rankDatas = {}
		local rankMembersData = self.unionFuben:read()[val]
		if rankMembersData then
			for k,v in pairs(rankMembersData.members or {}) do
				if members[k] then
					table.insert(rankDatas, {
						name = members[k].name,
						damage = math.max(v, 0)
					})
				end
			end
			table.sort(rankDatas, function(a, b)
				return a.damage > b.damage
			end)
			self.rankDatas:set(rankDatas)
		end

		self:setCenterPanel(gateData)
		self:setRightPanel(gateData)
	end)
	-- 副本挑战次数
	idlereasy.when(self.unionFbTimes, function(_, unionFbTimes)
		local unionFbSubTimes = math.max(3 - unionFbTimes, 0)
		self.textNum:text(unionFbSubTimes.."/3")
		local canBattle = unionFbSubTimes > 0 and unionTools.currentOpenFuben() == "open"
		uiEasy.setBtnShader(self.btnFight, self.btnFight:get("title"), canBattle and 1 or 2)
		uiEasy.setBtnShader(self.btnThreeFight, self.btnThreeFight:get("title"), canBattle and 1 or 2)
	end)
	idlereasy.when(self.unionFbAward, function(_, unionFuben)
		local effect = self.rewardBtnPanel:get("effect")
		local hasReward = dataEasy.haveUnionFubenReward()
		if not hasReward then
			if effect then
				effect:hide()
			end
		else
			local size = self.rewardBtnPanel:size()
			if not effect then
				effect = widget.addAnimationByKey(self.rewardBtnPanel, "union/huanghekelingqu.skel", "effect", "effect_loop", 5)
					:xy(size.width/2, size.height/2 + 12)
			else
				effect:show()
			end
		end
		uiEasy.addVibrateToNode(self, self.rewardBtnPanel, hasReward)
	end)

	idlereasy.any({self.roleLv, self.complete}, function(_, roleLv, complete)
		self.btnFight:visible(not complete)
		self.btnThreeFight:visible(not complete)
		if not complete then 	-- 已通关直接隐藏按钮，不用处理解锁逻辑
			local isUnlock = dataEasy.isUnlock(gUnlockCsv.uinonGateThreeTimes)
			self.btnThreeFight:visible(isUnlock)
			local pos = cc.p(170, 100)
			if not isUnlock then
				pos = cc.p(390, 100)
			end
			self.btnFight:xy(pos)
		end
	end)
end

function UnionGateView:initModel()
	local unionInfo = gGameModel.union
	--成员列表 key长度24 ID长度12
	self.members = unionInfo:getIdler("members")
	self.unionFuben = gGameModel.union_fuben:getIdler("states")
	--副本奖励
	self.unionFbAward = gGameModel.role:getIdler("union_fb_award")
	self.roleId = gGameModel.role:getIdler("id")
	local dailyRecord = gGameModel.daily_record
	-- 副本挑战次数
	self.unionFbTimes = dailyRecord:getIdler("union_fb_times")
	self.roleLv = gGameModel.role:getIdler("level")
end

function UnionGateView:setCenterPanel(gateData)
	local csvGate = csv.union.union_fuben[gateData.csvId]
	local csvMonster = gMonsterCsv[csvGate.gateID][1]
	local csvUnit
	for k,v in ipairs(csvMonster.monsters) do
		if v ~= 0 then
			csvUnit = csv.unit[v]
			break
		end
	end
	local csvScenes = csv.scene_conf[csvGate.gateID]
	local panel = self.centerPanel
	panel:get("textName"):text(csvGate.name)
	panel:get("iconAttr1"):texture(ui.ATTR_ICON[csvUnit.natureType])
	if csvUnit.natureType2 then
		panel:get("iconAttr2"):texture(ui.ATTR_ICON[csvUnit.natureType2])
	else
		panel:get("iconAttr2"):hide()
	end
	local pos = csvScenes.bg_boss_pos
	local x, y = panel:get("pos"):x() + pos.x, panel:get("pos"):y() + pos.y
	panel:get("icon"):texture(csvScenes.bg_boss):xy(x,y)
	panel:get("textDesc"):text(csvGate.desc)
	local percent = gateData.maxHp == 0 and 100 or gateData.surplusHp/gateData.maxHp*100
	panel:get("textHp"):visible(percent > 0)
	panel:get("bar"):visible(percent > 0)
	panel:get("hpBg"):visible(percent > 0)
	panel:get("textHpNote"):visible(percent > 0)
	panel:get("barBg"):visible(percent > 0)
	panel:get("bar"):percent(percent)

	local bossHp = mathEasy.getPreciseDecimal(percent, 2)
	bossHp = math.max(bossHp, 0.01)

	panel:get("textHp"):text(bossHp.."%")
	adapt.oneLineCenterPos(cc.p(400, panel:get("textHpNote"):y()), {panel:get("textHpNote"), panel:get("textHp")}, cc.p(-5, 0))
	if panel:get("textHpNote"):size().width + panel:get("textHp"):size().width > panel:get("hpBg"):size().width then
		panel:get("hpBg"):width(panel:get("textHpNote"):size().width + panel:get("textHp"):size().width)
	end
	--已通关
	local complete = gateData.surplusHp == 0 and gateData.maxHp > 0
	panel:get("iconComplete"):visible(complete)
	itertools.invoke({self.textNum, self.textNumNote}, complete and "hide" or "show")
	self.complete:set(complete)
end

function UnionGateView:setRightPanel(gateData)
	local csvGate = csv.union.union_fuben[gateData.csvId]
	local rewardDatas = {}
	local isFirstPass = true
	local passInfo = self.unionFbAward:read()[gateData.csvId]
	if passInfo and passInfo[1] ~= 0 then
		isFirstPass = false
	end
	local reward = isFirstPass and csvGate.firstAward or csvGate.repeatAward
	for k,v in csvMapPairs(reward) do
		table.insert(rewardDatas, {key=k,num=v})
	end
	self.rewardDatas:set(rewardDatas)

	local showAttrTxt = gateData.buff > 0 and unionTools.currentOpenFuben() == "open"
	self.textAttrNote:visible(showAttrTxt)
	self.textAttr:visible(showAttrTxt):text(gateData.buff.."%")
	-- adapt.oneLinePos(self.textAttrNote,self.textAttr)
	adapt.oneLineCenterPos(cc.p(500, 395), {self.textAttrNote, self.textAttr}, cc.p(6, 0))
	self.textOpenTime:visible(unionTools.currentOpenFuben() ~= "open")
	if unionTools.currentOpenFuben() == "weekError" then
		self.textOpenTime:text(gLanguageCsv.fubenClosedOnSunday)
	end
	local rewardNote = self.unionFbAward:read()[gateData.csvId] and gLanguageCsv.killReward or gLanguageCsv.firstPassAward
	self.rightPanel:get("textRewardNote"):text(rewardNote)
end

function UnionGateView:onGateItemClick(list, k, v)
	self.selectCsvId:set(v.csvId)
end

--挑战一次
function UnionGateView:onBtnFight()

	local fightCb = function(view)
		local csvGate = csv.union.union_fuben[self.selectCsvId:read()]
		local gateData = self.gateDatas:atproxy(self.selectCsvId:read())

		battleEntrance.battleRequest("/game/union/fuben/start", self.selectCsvId, csvGate.gateID)
			:onStartOK(function(data)
				view:onClose()
				data.damage = gateData.damage
				data.hpMax = gateData.maxHp
			end)
			:show()
	end

	gGameUI:stackUI("city.card.embattle.base", nil, {full = true}, {
		sceneType = game.SCENE_TYPE.unionFuben,
		from = game.EMBATTLE_FROM_TABLE.huodong,
		fromId = game.EMBATTLE_HOUDONG_ID.unionGate,
		fightCb = fightCb,
	})
end

--挑战3次
function UnionGateView:onBtnThreeFight()
	local selectCsvId = self.selectCsvId:read()
	local gateData = self.gateDatas:atproxy(selectCsvId)
	local members = self.members:read()
	local battleNum = self.unionFbTimes:read()
	local battleNumRemain = math.max(0,3-battleNum)
	local notBattled = (gateData.maxHp == 0)
	local remainHp = gateData.surplusHp
	local csvGate = csv.union.union_fuben[self.selectCsvId:read()]
	local sweepData = {}
	local function postThree()
		battleEntrance.battleRequest("/game/union/fuben/start", self.selectCsvId, csvGate.gateID)
			:onStartOK(function(data)
				data.damage = gateData.damage
				data.hpMax = gateData.maxHp
			end)
			:onResult(function(data, result)
				local view = result.serverData.view
				gateData = self.gateDatas:atproxy(selectCsvId)
				local maxHp = gateData.maxHp
				remainHp = gateData.surplusHp
				local supHp = math.max(view.damage, 0) / maxHp
				local percent = math.floor(supHp * 10000) / 100 .. "%"
				table.insert(sweepData, {items = view.drop, exp = percent})
				battleNumRemain = battleNumRemain - 1
				notBattled = false
				if (remainHp > 0 or notBattled) and battleNumRemain > 0 then
					postThree()
				else
					self:onSweepReward(sweepData)
					return false
				end
			end)
			:run()
	end
	if (remainHp > 0 or notBattled) and battleNumRemain > 0 then
		postThree()
	end
end
--三次挑战结算界面
function UnionGateView:onSweepReward(sweepData)
	if #sweepData < 1 then
		return
	end
	local oldCapture = gGameModel.capture:read("limit_sprites")
	gGameUI:stackUI("city.gate.sweep", nil, nil, {
		sweepData = sweepData,
		oldRoleLv = self.roleLv:read(),
		showType = 2,
		hasExtra = false,
		from = "union",
		title1 = gLanguageCsv.guild,
		title2 = gLanguageCsv.fubenChallenge,
		oldCapture = oldCapture,
	})
end
--规则
function UnionGateView:onRuleBtn()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function UnionGateView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title),
		c.noteText(112),
		c.noteText(44001, 44099),
		c.noteText(135),
	}

	for k, v in orderCsvPairs(csv.union.union_fuben_rank) do
		table.insert(context, c.clone(view.awardItem, function(item)
			local childs = item:multiget("text", "list")
			if v.range[2] - v.range[1] == 0 then
				childs.text:text(string.format(gLanguageCsv.rankSingle, v.range[1]))
			else
				childs.text:text(string.format(gLanguageCsv.rankMulti, v.range[1], v.range[2]))
			end
			uiEasy.createItemsToList(view, childs.list, v.award)
		end))
	end

	return context
end

--进度排行
function UnionGateView:onRankBtn()
	gGameApp:requestServer("/game/union/fuben/progress",function (tb)
		gGameUI:stackUI("city.union.gate.rank", nil, nil, tb.view)
	end)
end
--会员进度
function UnionGateView:onProgressBtn()
	gGameUI:stackUI("city.union.gate.progress", nil, nil, {needConsider = true})
end
--领取奖励
function UnionGateView:onRewardBtn()
	if not dataEasy.haveUnionFubenReward() then
		gGameUI:showTip(gLanguageCsv.noRewardAvailable)
		return
	end
	gGameUI:stackUI("city.union.gate.reward", nil, nil, self.unionFuben:read(), self:createHandler("onRewardCb"))
end
function UnionGateView:onRewardCb(tb)
	gGameUI:showGainDisplay(tb)
end
--排序
function UnionGateView:onSortRank(list)
	return function(a, b)
		return a.damage > b.damage
	end
end

--排行榜为空
function UnionGateView:onAfterBuild()
	local showEmpty = self.rankList:getChildrenCount() == 0
	self.empty:visible(showEmpty)
	self.listTitlePanel:visible(not showEmpty)
	self.maskPanel:visible(not showEmpty)
	uiEasy.setBottomMask(self.rankList, self.maskPanel)
end

return UnionGateView