local ViewBase = cc.load("mvc").ViewBase
local GateSectionHard = class("GateSectionHard", Dialog)

local SWEEP_TIMES = {1, 3}

GateSectionHard.RESOURCE_FILENAME = "gate_section_detail_hard.json"
GateSectionHard.RESOURCE_BINDING = {
	["rightDown.btnChallenge.textNote"] = {
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["rightDown.btnSweep.textNote"] = {
		varname = "sweepBtnTitle",
		binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}}
		}
	},
	["rightDown.textCostNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("powerNum")
		}
	},
	["rightDown.textLeftTime"] = "timesNum",
	["rightDown.textKh"] = "textKh",
	["rightDown.textLeftTimeNote"] = "timesNote1",
	["rightDown.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onTimesBtnClick")}
		},
	},
	["iconItem"] = "iconItem",
	["leftDown.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("dropDatas"),
				item = bindHelper.self("iconItem"),
				dataOrderCmp = dataEasy.sortItemCmp,
				onItem = function(list, node, k, v)
					local size = node:size()
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
				asyncPreload = 6,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["rightDown.btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChallengeClick")}
		},
	},
	["rightDown.selectSkip"] = {
		varname = "selectSkip",
		binds = {
			event = "click",
			method = bindHelper.self("onSelectSkip")
		},
	},
	["rightDown.btnSweep"] = {
		varname = "sweepBtn",
		binds = {
			event = "click",
			method = bindHelper.self("onSweepBtn")
		},
	},
	["rightDown.sortPanel"] = {
		varname = "sortPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("sortDatas"),
				expandUp = true,
				locked = bindHelper.self("locked"),
				showSelected = bindHelper.self("sweepSelected"),
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				onNode = function(node)
					node:xy(-1120, -487):z(18)
				end,
			},
		}
	},
}

function GateSectionHard:onCreate(gateId, pageId, fightCb)
	self:initModel()
	self.gateId = gateId
	self.pageId = pageId
	self.fightCb = fightCb


	self:initLeftDown()
	self:initRightDown()
end
function GateSectionHard:initLeftDown()
	local sceneCsv = csv.scene_conf[self.gateId]
	local dropDatas = {}
	for k,v in csvMapPairs(sceneCsv.dropIds) do
		table.insert(dropDatas, {key = k, num = v})
	end
	self.dropDatas = dropDatas
end

function GateSectionHard:initRightDown()
	local sceneCsv = csv.scene_conf[self.gateId]
	local sweepTimes = SWEEP_TIMES
	local waySelectDatas = {}
	for i=1,#sweepTimes do
		table.insert(waySelectDatas, string.format(gLanguageCsv.sweepManyTimes, sweepTimes[i]))
	end
	self.sortDatas = idlertable.new(waySelectDatas)

	idlereasy.when(self.gate_star,function(_,star)
		local starNum = star[self.gateId] and self.gate_star:read()[self.gateId].star or 0
		local maxStar = 3
		local sweepOpen = starNum >= maxStar
		self.sweepBtn:setTouchEnabled(sweepOpen)
		self.sweepBtn:visible(sweepOpen)
		-- cache.setShader(self.sweepBtn, false, sweepOpen and "normal" or "hsl_gray")
		self.sortPanel:visible(sweepOpen)
	end)
	--困难难度扫荡暂时没有加锁需求
	self.locked = idler.new(0)
	-- idlereasy.any({self.vipLevel}, function(_, vipLevel)
	-- 	local sweepNum = gVipCsv[vipLevel].saodangCountOpen
	-- 	self.locked:set(sweepNum < 50 and 3 or 0)
	-- end)

	self.sweepSelected = userDefault.getForeverLocalKey("sweepSelectedHard", 1)
	self.mopUpNum = SWEEP_TIMES[self.sweepSelected]

	self.powerNum = idler.new(sceneCsv.staminaCost)		-- 体力消耗

	local state = userDefault.getForeverLocalKey("skipBattle", false)
	self.selectSkip:get("selectSkip"):setSelectedState(state)

	idlereasy.when(self.gateTimes, function(_, gateTimes)
		-- 剩余挑战次数
		local surplusTimes = sceneCsv.dayChallengeMax - (gateTimes[self.gateId] or 0)
		-- 最大挑战次数
		local maxTimes = sceneCsv.dayChallengeMax
		-- 今天的重置次数
		local buyHerogateTimes = self.buyHerogateTimes:read()[self.gateId] or 0
		local state, paramMaps, count = dataEasy.isDoubleHuodong("heroGateTimes")
		if state then
			for i, paramMap in pairs(paramMaps) do
				local addTimes = paramMap["count"]
				if addTimes and addTimes > 0 then
					if  buyHerogateTimes == 0 then
						surplusTimes = surplusTimes + addTimes
					end
					maxTimes = maxTimes + addTimes
				end
			end
		end
		self.surplusTimes = surplusTimes
		self.timesNum:text(math.max(surplusTimes, 0).."/"..maxTimes)
		adapt.oneLinePos(self.timesNum, self.textKh, nil, "left")
	end)
end

function GateSectionHard:initModel()
	self.gate_star = gGameModel.role:getIdler("gate_star") -- 星星数量
	self.roleLv = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.stamina = gGameModel.role:getIdler("stamina")
	self.buyHerogateTimes = gGameModel.daily_record:getIdler("buy_herogate_times")
	self.gateTimes = gGameModel.daily_record:getIdler("gate_times")
end

function GateSectionHard:onTimesBtnClick()
	local buyTimeMax = gVipCsv[gGameModel.role:read("vip_level")].buyHeroGateTimes
	local buyHerogateTimes = self.buyHerogateTimes:read()
	if (buyHerogateTimes[self.gateId] or 0) >= buyTimeMax then
		gGameUI:showTip(gLanguageCsv.herogateBuyMax)
		return
	end
	if self.surplusTimes > 0 then
		gGameUI:showTip(gLanguageCsv.haveChallengeTimesUnused)
		return
	end

	local roleRmb = gCostCsv.herogate_buy_cost[(buyHerogateTimes[self.gateId] or 0) + 1]
	if gGameModel.role:read("rmb") < roleRmb then
		uiEasy.showDialog("rmb")
		return
	end

	local strs = {
		"#C0x5b545b#"..string.format(gLanguageCsv.resetNumberEliteLevels1,gCostCsv.herogate_buy_cost[(buyHerogateTimes[self.gateId] or 0) + 1]),
		"#C0x5b545b#"..string.format(gLanguageCsv.resetNumberEliteLevels2,buyHerogateTimes[self.gateId] or 0,buyTimeMax)
	}
	gGameUI:showDialog({content = strs, cb = function()
		gGameApp:requestServer("/game/role/hero_gate/buy",function()
			gGameUI:showTip(gLanguageCsv.resetSuccess)
		end,self.gateId)
	end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
end

function GateSectionHard:checkSweep()
	local staminaCost = csv.scene_conf[self.gateId].staminaCost
	local curStamina = dataEasy.getStamina()
	if curStamina < staminaCost then
		gGameUI:stackUI("common.gain_stamina")
		return false
	end
	self.curMopUpNum = math.min(self.mopUpNum, math.floor(curStamina / staminaCost))	-- 本次可扫荡最大次数
	if self.surplusTimes <= 0 then
		self:onTimesBtnClick()
		return false
	end

	return true
end

function GateSectionHard:onSweepBtn()
	if not self:checkSweep() then
		return
	end
	local oldCapture = gGameModel.capture:read("limit_sprites")
	local roleLv = self.roleLv:read()
	gGameApp:requestServer("/game/saodang",function (tb)
		local items = tb.view.result
		table.insert(items, {exp=0, items=tb.view.extra, isExtra=true})
		gGameUI:stackUI("city.gate.sweep", nil, nil, {
			sweepData = items,
			oldRoleLv = roleLv,
			cb = self:createHandler("onSweepBtn"),
			checkCb = self:createHandler("checkSweep"),
			hasExtra = true,
			from = "gate",
			oldCapture = oldCapture,
			isDouble = dataEasy.isGateIdDoubleDrop(self.gateId),
			gateId = self.gateId,
			catchup = tb.view.catchup
		})
	end,self.gateId,self.curMopUpNum)
end

function GateSectionHard:onSelectSkip()
	local state = userDefault.getForeverLocalKey("skipBattle", false)
	self.selectSkip:get("selectSkip"):setSelectedState(not state)
	userDefault.setForeverLocalKey("skipBattle", not state)
end

function GateSectionHard:onChallengeClick()
	local staminaCost = csv.scene_conf[self.gateId].staminaCost
	if dataEasy.getStamina() < staminaCost then
		-- gGameUI:showTip(gLanguageCsv.gateStaminaNotEnough)
		gGameUI:stackUI("common.gain_stamina")
		return
	end
	if self.surplusTimes <= 0 then
		gGameUI:showTip(gLanguageCsv.timesLimitEatGreenBlock)
		return
	end
	local state = userDefault.getForeverLocalKey("skipBattle", false)
	if state then
		self.fightCb()
	else
		gGameUI:stackUI("city.card.embattle.base", nil, {full = true}, {
			fightCb = self.fightCb
		})
	end
end

function GateSectionHard:onSortMenusBtnClick(panel, node, k, v)
	self.mopUpNum = SWEEP_TIMES[k]
	userDefault.setForeverLocalKey("sweepSelectedHard", k)
end

function GateSectionHard:onAfterBuild()
	-- self.bottomPanel:get("listBg"):size(cc.size(42+310*self.list:getChildrenCount(), 344))
end

function GateSectionHard:setBtnFalse()
	cache.setShader(self.btnChallenge, false, "hsl_gray")
	self.btnChallenge:setTouchEnabled(false)
end

return GateSectionHard
