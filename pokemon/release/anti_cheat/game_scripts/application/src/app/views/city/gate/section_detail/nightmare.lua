local ViewBase = cc.load("mvc").ViewBase
local GateSectionNightmare = class("GateSectionNightmare", ViewBase)

local SWEEP_TIMES = {1, 10, 50}

local function setItemIsGet(node, isGet)
	if not isGet then return end
	local size = node:size()
	local sp = cc.Sprite:create("city/gate/logo_yhd.png")
				:addTo(node, 999)
				:xy(size.width / 2, size.height / 2)
end

GateSectionNightmare.RESOURCE_FILENAME = "gate_section_detail_nightmare.json"
GateSectionNightmare.RESOURCE_BINDING = {
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
	["iconItem"] = "iconItem",
	["leftDown.firstDrop.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("firstDropDatas"),
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
							onNode = function(node)
								setItemIsGet(node, v.isGet)
							end,
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
	["leftDown.starDrop.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("starDropDatas"),
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
							onNode = function(node)
								setItemIsGet(node, v.isGet)
							end,
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
}

function GateSectionNightmare:onCreate(gateId, pageId, fightCb)
	self:initModel()
	self.gateId = gateId
	self.pageId = pageId
	self.fightCb = fightCb

	self:initLeftDown()
	self:initRightDown()
end

function GateSectionNightmare:initModel()
	self.gate_star = gGameModel.role:getIdler("gate_star") -- 星星数量
	self.roleLv = gGameModel.role:getIdler("level")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.stamina = gGameModel.role:getIdler("stamina")
	self.buyHerogateTimes = gGameModel.daily_record:getIdler("buy_herogate_times")
	self.gateTimes = gGameModel.daily_record:getIdler("gate_times")
end

function GateSectionNightmare:initLeftDown()
	local sceneCsv = csv.scene_conf[self.gateId]
	local getState = 0			-- 0 表示已经领取

	idlereasy.when(self.gate_star,function(_,star)
		local starTb = star[self.gateId] or {}
		local firstDropDatas = {}
		for k,v in csvMapPairs(sceneCsv.winAward) do
			table.insert(firstDropDatas, {key = k, num = v, isGet = starTb.win_award == getState})
		end
		self.firstDropDatas = firstDropDatas
		local starDropDatas = {}
		for k,v in csvMapPairs(sceneCsv.star3Award) do
			table.insert(starDropDatas, {key = k, num = v, isGet = starTb.star3_award == getState})
		end
		self.starDropDatas = starDropDatas
	end)
end

function GateSectionNightmare:initRightDown()
	local sceneCsv = csv.scene_conf[self.gateId]

	self.powerNum = idler.new(sceneCsv.staminaCost)		-- 体力消耗

	local state = userDefault.getForeverLocalKey("skipBattle", false)
	self.selectSkip:get("selectSkip"):setSelectedState(state)
end

function GateSectionNightmare:onSelectSkip()
	local state = userDefault.getForeverLocalKey("skipBattle", false)
	self.selectSkip:get("selectSkip"):setSelectedState(not state)
	userDefault.setForeverLocalKey("skipBattle", not state)
end

function GateSectionNightmare:onChallengeClick()
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
			fightCb = self.fightCb,
			from = game.EMBATTLE_FROM_TABLE.huodong,
			fromId = game.EMBATTLE_HOUDONG_ID.nightmare,
			team = true,
		})
	end
end

function GateSectionNightmare:onAfterBuild()
	-- self.bottomPanel:get("listBg"):size(cc.size(42+310*self.list:getChildrenCount(), 344))
end

function GateSectionNightmare:setBtnFalse()
	cache.setShader(self.btnChallenge, false, "hsl_gray")
	self.btnChallenge:setTouchEnabled(false)
end

return GateSectionNightmare
