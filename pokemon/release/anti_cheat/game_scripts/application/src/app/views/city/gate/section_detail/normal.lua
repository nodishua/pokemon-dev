local ViewBase = cc.load("mvc").ViewBase
local GateSectionNormal = class("GateSectionNormal", ViewBase)

local SWEEP_TIMES = {1, 10, 50}

GateSectionNormal.RESOURCE_FILENAME = "gate_section_detail_normal.json"
GateSectionNormal.RESOURCE_BINDING = {
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
	["rightDown"] = "rightDown",
	["leftDown"] = "leftDown",
}

function GateSectionNormal:onCreate(gateId, pageId, fightCb)
	self:initModel()
	self.gateId = gateId
	self.pageId = pageId
	self.fightCb = fightCb


	self:initLeftDown()
	self:initRightDown()
end

function GateSectionNormal:initModel()
	self.gate_star = gGameModel.role:getIdler("gate_star") -- 星星数量
	self.roleLv = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.stamina = gGameModel.role:getIdler("stamina")
	self.buyHerogateTimes = gGameModel.daily_record:getIdler("buy_herogate_times")
	self.gateTimes = gGameModel.daily_record:getIdler("gate_times")
end

function GateSectionNormal:initLeftDown()
	local sceneCsv = csv.scene_conf[self.gateId]
	local dropDatas = {}
	for k,v in csvMapPairs(sceneCsv.dropIds) do
		table.insert(dropDatas, {key = k, num = v})
	end
	self.dropDatas = dropDatas
end

function GateSectionNormal:initRightDown()
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

	self.locked = idler.new(0)
	idlereasy.any({self.vipLevel}, function(_, vipLevel)
		local sweepNum = gVipCsv[vipLevel].saodangCountOpen		--vip扫荡次数
		local privilegeSweepTimes = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.GateSaoDangTimes)--特权扫荡次数
		local state = 0
		if privilegeSweepTimes < SWEEP_TIMES[2] and sweepNum < SWEEP_TIMES[2] then
			state = 2
		elseif privilegeSweepTimes < SWEEP_TIMES[3] and sweepNum < SWEEP_TIMES[3] then
			state = 3
		end
		self.locked:set(state)
	end)

	dataEasy.fixSaoDangLocalKey("sweepSelected", SWEEP_TIMES)
	self.sweepSelected = userDefault.getForeverLocalKey("sweepSelected", 1)
	self.mopUpNum = SWEEP_TIMES[self.sweepSelected]

	self.powerNum = idler.new(sceneCsv.staminaCost)		-- 体力消耗

	local state = userDefault.getForeverLocalKey("skipBattle", false)
	self.selectSkip:get("selectSkip"):setSelectedState(state)
end

function GateSectionNormal:checkSweep()
	local staminaCost = csv.scene_conf[self.gateId].staminaCost
	local curStamina = dataEasy.getStamina()
	if curStamina < staminaCost then
		gGameUI:stackUI("common.gain_stamina")
		return false
	end
	self.curMopUpNum = math.min(self.mopUpNum, math.floor(curStamina / staminaCost))	-- 本次可扫荡最大次数

	return true
end

function GateSectionNormal:onSweepBtn()
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

function GateSectionNormal:onSelectSkip()
	local state = userDefault.getForeverLocalKey("skipBattle", false)
	self.selectSkip:get("selectSkip"):setSelectedState(not state)
	userDefault.setForeverLocalKey("skipBattle", not state)
end

function GateSectionNormal:onChallengeClick()
	local staminaCost = csv.scene_conf[self.gateId].staminaCost
	if dataEasy.getStamina() < staminaCost then
		-- gGameUI:showTip(gLanguageCsv.gateStaminaNotEnough)
		gGameUI:stackUI("common.gain_stamina")
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

function GateSectionNormal:onSortMenusBtnClick(panel, node, k, v)
	local state = dataEasy.getSaoDangState(SWEEP_TIMES[k])
	if not state.canSaoDang then
		gGameUI:showTip(state.tip)
		return
	end
	self.mopUpNum = SWEEP_TIMES[k]
	userDefault.setForeverLocalKey("sweepSelected", k)
end

function GateSectionNormal:onAfterBuild()
	-- self.bottomPanel:get("listBg"):size(cc.size(42+310*self.list:getChildrenCount(), 344))
end

function GateSectionNormal:setBtnFalse()
	cache.setShader(self.btnChallenge, false, "hsl_gray")
	self.btnChallenge:setTouchEnabled(false)
end

return GateSectionNormal
