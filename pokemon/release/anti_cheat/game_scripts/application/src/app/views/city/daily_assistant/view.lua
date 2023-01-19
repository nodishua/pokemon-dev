-- @date 2021-01-21
-- @desc 日常小助手主界面

--类型(1=奖励领取 2=抽卡 3=战斗报名 4=快速冒险 5=公会事宜)
local TAB_TYPE = {
	REWARD = 1,
	DRAWCARD = 2,
	SIGNUP = 3,
	ADVENTURE = 4,
	UNION = 5,
}

local RED_HINTS = {
	[1] = {
		specialTag = "dailyAssistantReward",
	},
	[2] = {
		specialTag = "dailyAssistantDrawCard",
	},
	[3] = {
		specialTag = "dailyAssistantSignup",
	},
	[4] = {
		specialTag = "dailyAssistantAdventure",
	},
	[5] = {
		specialTag = "dailyAssistantUnion",
	},
}
-- 选择文本
local SELECT_TXT = {
	["gem"] = gLanguageCsv.dailyAssistantGemSelectedTxt,
	["catch"] = gLanguageCsv.dailyAssistantJumpCatch,
	["endlessTower"] = gLanguageCsv.dailyAssistantEndlessTip,
}

-- 页签名(1=奖励领取 2=抽卡 3=战斗报名 4=快速冒险 5=公会事宜)
local TAB_TYPE_NAME = {
	[1] = gLanguageCsv.reward,
	[2] = gLanguageCsv.drawCard,
	[3] = gLanguageCsv.battleSignUp,
	[4] = gLanguageCsv.quickAdventure,
	[5] = gLanguageCsv.unionMatters,
}

-- 报名状态(1=可报名，2=已报名，3=不可报名)
local STATE_SIGN_UP = {
	canSignUp = 1,
	hadSignUp = 2,
	cantSignUp = 3,
}

local ONE_KEY_NAME = {
	[1] = gLanguageCsv.getAwardAll, --	一键领取
	[2] = gLanguageCsv.oneClickCardDraw, --	一键抽卡
	[3] = gLanguageCsv.oneClickRegistration, --	一键报名
	[4] = gLanguageCsv.oneClickDoing, --	一键进行
	[5] = gLanguageCsv.oneClickCompletion, --	一键完成
}

local CHIPUPLIMIT = gCommonConfigCsv.chipUpLimit

local function getItemAwards(val, datas, specialKey)
	for k, v in pairs(val) do
		if type(v) == "table" then
			getItemAwards(v, datas, specialKey)
		elseif specialKey == nil or k == specialKey then
			datas[k] = (datas[k] or 0) + v
		end
	end
end

local function initUnionGatePanel(list, panel, title, k, v)
	panel:show()
	local childs = panel:multiget("gate", "txt1", "txt", "btnReward", "errTxt")
	childs.btnReward:hide()
	childs.txt:hide()
	childs.txt1:hide()
	childs.errTxt:hide()
	childs.gate:hide()
	if v.hasReward then
		childs.btnReward:show()
		text.addEffect(childs.btnReward:get("text"), {outline={color=ui.COLORS.NORMAL.WHITE}})
	end
	if v.errTxt then
		childs.errTxt:show()
		childs.errTxt:text(v.errTxt)
	else
		if v.txt or v.txt1 then
			if v.txt == nil then v.txt = "" end
			if v.txt1 == nil then v.txt1 = "" end
			childs.txt:show()
			childs.txt1:show()
			local txt = childs.txt
			local txt1 = childs.txt1
			txt:text(v.txt)
			txt1:text(v.txt1)
			adapt.oneLinePos(txt, txt1, cc.p(10, 0))
			if v.leftTimes and v.leftTimes == 0 then
				text.addEffect(txt1, {color=cc.c3b(251, 96, 35)})
			end
		end
		childs.gate:show()
		local gateInfo = childs.gate:multiget("icon", "imgSelect", "textOrder", "textHp")
		gateInfo.icon:texture(v.data.icon)
		gateInfo.imgSelect:visible(v.data.selectEffect == true)
		gateInfo.textOrder:text(v.data.csvId)
		local percent = v.data.maxHp == 0 and 100 or mathEasy.getPreciseDecimal(v.data.surplusHp/v.data.maxHp*100, 2)
		gateInfo.textHp:text(string.format("%s:%s%%", gLanguageCsv.leftHP, percent))
		text.addEffect(gateInfo.textHp, {outline={color=ui.COLORS.NORMAL.DEFAULT}})
	end
end

local function initUnionRedpacketPanel(list, panel, title, k, v)
	panel:show()
	local childs = panel:multiget("redpackPanel", "txt", "finshImg")
	childs.redpackPanel:show()
	childs.txt:hide()
	childs.finshImg:hide()
	if v.finish then
		childs.finshImg:show()
	end
	if v.txt then
		childs.redpackPanel:hide()
		childs.finshImg:hide()
		childs.txt:show()
		childs.txt:text(v.txt)
		if title:width() + childs.txt:width()/2 > childs.txt:x() - title:x() then
			adapt.oneLinePos(title, childs.txt, cc.p(20, 0))
		end
	end
end

local function initChipPanel(list, panel, suitItem, k, v)
	panel:show()
	local childs = panel:multiget("txtPanel", "panelSelectSuit", "finshImg", "txt")
	local suitPanel = childs.panelSelectSuit:get("suitPanel")
	if v.txt or v.txt1 then
		childs.txtPanel:show()
		local txt = childs.txtPanel:get("txt")
		local txt1 = childs.txtPanel:get("txt1")
		txt:text(v.txt or "")
		txt1:text(v.txt1 or "")
		adapt.oneLineCenterPos(cc.p(childs.txtPanel:width()/2, childs.txtPanel:height()/2), {txt, txt1}, cc.p(20, 0))
		if v.leftTimes and v.leftTimes == 0 then
			text.addEffect(txt1, {color=cc.c3b(251, 96, 35)})
		end
	end
	childs.txt:visible(table.length(v.chip) == 0)
	childs.panelSelectSuit:visible(table.length(v.chip) > 0)
	if table.length(v.chip) > 0 then
		for i=1, CHIPUPLIMIT do
			local item = suitPanel:get("item0"..i)
			if not item then
				item = suitItem:clone():show()
					:xy(90*(i-1), 0)
					:addTo(suitPanel, 1, "item0"..i)
			end

			local imgIcon = item:get("imgIcon")
			local sign = v.chip[i] ~= nil
			imgIcon:visible(sign)

			if sign then
				local _, cfg = next(gChipSuitCsv[v.chip[i]][6])
				local str = string.gsub(cfg.suitIcon, '0.png', '2.png')
				imgIcon:texture(str)
			end
		end
	end
	childs.finshImg:visible(v.finish)
end

local function initNormalPanel(list, panel, title, k, v)
	panel:show()
	local childs = panel:multiget("selectPanel", "txtPanel", "stateText", "stateImg", "btn", "list", "finshImg")
	childs.selectPanel:hide()
	childs.txtPanel:hide()
	childs.stateText:hide()
	childs.stateImg:hide()
	childs.finshImg:hide()
	childs.btn:hide()
	childs.list:hide()
	if v.btnName then
		childs.btn:show()
		childs.btn:get("txtNode"):text(v.btnName)
	end
	if v.reward then
		childs.list:show()
		uiEasy.createItemsToList(list, childs.list, v.reward, {scale = 0.9})
	end
	if v.txt or v.txt1 then
		childs.txtPanel:show()
		local txt = childs.txtPanel:get("txt")
		local txt1 = childs.txtPanel:get("txt1")
		txt:text(v.txt or "")
		txt1:text(v.txt1 or "")
		local height = childs.txtPanel:height()/2
		-- 特殊处理，选项在中间时，需要整体居中
		if v.selected and v.selectedType == "center" then
			height = childs.txtPanel:height()/2 + 41
		end
		adapt.oneLineCenterPos(cc.p(childs.txtPanel:width()/2, height), {txt, txt1}, cc.p(20, 0))
		if v.leftTimes and v.leftTimes == 0 then
			text.addEffect(txt1, {color=cc.c3b(251, 96, 35)})
		end
	end
	if v.rich then
		childs.txtPanel:show()
		local txt = childs.txtPanel:get("txt")
		local txt1 = childs.txtPanel:get("txt1")
		txt:text("")
		txt1:text("")
		txt:removeAllChildren()
		local rich = rich.createByStr(v.rich, 40)
		rich:addTo(txt)
		rich:anchorPoint(0.5, 0.5)
		rich:xy(0, 0)
	end
	if v.state then
		if v.state == STATE_SIGN_UP.canSignUp then
			childs.stateText:show()
			childs.stateText:text(gLanguageCsv.canSignup)
			text.addEffect(childs.stateText, {color=cc.c3b(96, 196, 86)})
		elseif v.state == STATE_SIGN_UP.hadSignUp then
			childs.stateImg:show()
		elseif v.state == STATE_SIGN_UP.cantSignUp then
			childs.stateText:show()
			childs.stateText:text(gLanguageCsv.cantSignup)
			text.addEffect(childs.stateText, {color=cc.c3b(127, 127, 127)})
		end
	end
	if v.selected then
		childs.selectPanel:show()
		local sPanel = childs.selectPanel:get("sPanel")
		sPanel:get("select"):visible(v.selected == 1)
		local txt = childs.selectPanel:get("txt")
		txt:text(SELECT_TXT[v.feature])
		if txt:width() > childs.btn:width() then
			adapt.oneLinePos(txt, sPanel, cc.p(5, 0), "right")
		else
			adapt.oneLineCenterPos(cc.p(childs.selectPanel:width()/2, childs.selectPanel:height()/2 + 7), {sPanel, txt}, cc.p(5, 0))
		end
		if v.selectedType and v.selectedType == "center" then
			local centerX = panel:width()/2 - childs.selectPanel:x() + 40
			adapt.oneLineCenterPos(cc.p(centerX, childs.selectPanel:height()/2 + 32), {txt, sPanel}, cc.p(5, 0))
		end
	end
	if v.finish then
		childs.finshImg:show()
	end
end

local unionTools = require "app.views.city.union.tools"
local dailyAssistantTools = require "app.views.city.daily_assistant.tools"
local ViewBase = cc.load("mvc").ViewBase
local DailyAssistantView = class("DailyAssistantView", ViewBase)
DailyAssistantView.RESOURCE_FILENAME = "daily_assistant.json"
DailyAssistantView.RESOURCE_BINDING = {
	["tabItem"] = "tabItem",
	["rightPanel.btnOneClick"] = {
		varname = "btnOneClick",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onBtnOneClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = bindHelper.self("oneClickShowRedHint"),
					onNode = function(panel)
						panel:xy(340, 130)
					end,
				}
			}
		},
	},
	["rightPanel.bg"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("rightBgPath"),
		},
	},
	["rightPanel.activePanel"] = {
		varname = "activePanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnShowActiveNoteClick")}
		},
	},
	["rightPanel.activePanel.txtNode"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(176, 89, 41, 255), size = 3}}
		}
	},
	["tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("selected", "normal")
					childs.selected:visible(v.selected)
					childs.normal:visible(not v.selected)
					childs.selected:get("txtNode"):text(v.name)
					childs.normal:get("txtNode"):text(v.name)
					node:onClick(functools.partial(list.clickCell, k, v))

					if RED_HINTS[k] then
						local props = RED_HINTS[k]
						props.state = not v.selected
						bind.extend(list, node, {
							class = "red_hint",
							props = props,
						})
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["selectSuitItem"] = "selectSuitItem",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showDatas"),
				item = bindHelper.self("item"),
				suitItem = bindHelper.self("selectSuitItem"),
				dataOrderCmp = function(a, b)
					return a.sortID < b.sortID
				end,
				asyncPreload = 5,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("title", "activeImg", "unionGatePanel", "normalPanel", "unionRedpacketPanel", "chipPanel")
					text.addEffect(childs.title, {outline={color=ui.COLORS.NORMAL.WHITE, size=5}})
					childs.title:text(v.name)
					local titleWidth = childs.title:width()
					local maxLen = 480
					if titleWidth > maxLen then
						adapt.setTextScaleWithWidth(childs.title, nil, maxLen)
					end

					childs.activeImg:hide()
					if v.active then
						childs.activeImg:show()
						adapt.oneLinePos(childs.title, childs.activeImg, cc.p(-5, 0))
					end

					childs.normalPanel:hide()
					childs.unionGatePanel:hide()
					childs.unionRedpacketPanel:hide()
					childs.chipPanel:hide()
					if v.type == TAB_TYPE.UNION and v.feature == "unionFuben" then
						initUnionGatePanel(list, childs.unionGatePanel, childs.title, k, v)
					elseif v.type == TAB_TYPE.REWARD and v.feature == "unionRedpacket" then
						initUnionRedpacketPanel(list, childs.unionRedpacketPanel, childs.title, k, v)
					elseif v.type == TAB_TYPE.DRAWCARD and v.feature == "chip" then
						initChipPanel(list, childs.chipPanel, list.suitItem, k, v)
					else
						initNormalPanel(list, childs.normalPanel, childs.title, k, v)
					end

					bind.touch(list, childs.normalPanel:get("btn"), {methods = {ended = functools.partial(list.clickCell, k, v)}})
					bind.touch(list, childs.unionGatePanel:get("btnReward"), {methods = {ended = functools.partial(list.unionGateCell, k, v)}})
					childs.normalPanel:get("selectPanel.sPanel"):onClick(functools.partial(list.selectCell, k, v))
					childs.normalPanel:get("selectPanel.txt"):onClick(functools.partial(list.selectCell, k, v))
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBtnClick"),
				selectCell = bindHelper.self("onSelectClick"),
				unionGateCell = bindHelper.self("onUnionRewardBtnClick")
			},
		},
	},
}

function DailyAssistantView:onCreate()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.dailyAssistant, subTitle = "DAILY ASSISTANT"})

	self:initModel()

	self.tabSelected:addListener(function(val, oldval)
		if val == nil then return end
		if oldval then
			self.tabDatas:atproxy(oldval).selected = false
		end
		self.tabDatas:atproxy(val).selected = true
		self.btnOneClick:get("txtNode"):text(ONE_KEY_NAME[val])
		self:setRightBgPath(val)
		self:updateShowDatas(val)
		self.errorTips = nil
	end)

	-- 默认显示页签类型
	local firstTabType = 5
	local allTabs = {}
	self.allDatas = {}
	for k, val in pairs(gDailyAssistantCsv) do
		local cfg = val.cfg
		if allTabs[cfg.type] == nil then
			allTabs[cfg.type] = {selected = false, name = TAB_TYPE_NAME[cfg.type], type = cfg.type}
			firstTabType = math.min(firstTabType, cfg.type)
		end
		if self.allDatas[cfg.type] == nil then
			self.allDatas[cfg.type] = {}
		end

		if cfg.inUnlock == 0 or dataEasy.isShow(k) then
			self.allDatas[cfg.type][k] = {csvId = val.csvId, sortID = cfg.sortID, name = cfg.name, type = cfg.type, feature = cfg.features}
		end
	end
	self.tabDatas:update(allTabs)
	self.tabSelected:set(firstTabType)

	idlereasy.when(self.dailyAssistant, function(_, dailyAssistant)
		if dailyAssistant == nil then return end
		-- 公会捐献选择csvID, 许愿碎片，冒险之路是否自动重置 默认自动重置，钓鱼大赛是否跳过捕鱼 默认他跳过
		if self.showDatas:atproxy("unionContrib")
			or self.showDatas:atproxy("unionFragDonate")
			or self.showDatas:atproxy("catch")
			or self.showDatas:atproxy("endlessTower") then
			self:updateShowDatas(self.tabSelected:read())
		end
	end)

	-- 冒险之路
	idlereasy.any({self.curChallengeId, self.resetCount, self.maxGateId}, function(_, curChallengeId, resetCount, maxGateId)
		local selGateIdx
		if curChallengeId == 0 then
			selGateIdx = 1
		else
			local idx = 0
			for i,v in orderCsvPairs(csv.endless_tower_scene) do
				idx = idx + 1
				if curChallengeId > 0 and i == curChallengeId then
					selGateIdx = idx
					break
				end
			end
			-- 最大关卡了
			if not selGateIdx then
				selGateIdx = idx
			end
		end
		self.curGateIdx = selGateIdx
		if self.showDatas:atproxy("endlessTower") then
			self:updateShowDatas(self.tabSelected:read())
		end
	end)

	-- 公会副本奖励,公会副本次数
	idlereasy.any({self.unionFubenPassed, self.unionFbTimes, self.unionFbAward}, function(_, unionFubenPassed, unionFbTimes, unionFbAward)
		if self.showDatas:atproxy("unionFuben") then
			self:updateShowDatas(self.tabSelected:read())
		end
	end)

	if dailyAssistantTools.getUnionFubenIsOpen() then
		idlereasy.when(self.unionFuben, function(_, unionFuben)
			if unionFuben == nil then return end
			local data = {}
			self.selectCsvId = 1
			for k,v in orderCsvPairs(csv.union.union_fuben) do
				local csvScenes = csv.scene_conf[v.gateID]
				local gateData = unionFuben[k]
				if not itertools.isempty(gateData) then
					if k > self.selectCsvId then
						self.selectCsvId = k
					end
					table.insert(data, {
						csvId = k,
						icon = csvScenes.icon,
						buff = gateData.buff,
						surplusHp = math.max(gateData.hpmax-gateData.damage, 0),
						maxHp = gateData.hpmax,
						damage = gateData.damage,
						time = gateData.time,
					})
				end
			end
			self.unionFubenData:update(data)
		end)
	end

	-- 钓鱼
	idlereasy.any({self.fishingSelectScene, self.selectBait, self.selectRod, self.items}, function(_, fishingSelectScene, selectBait, selectRod, items)
		if self.showDatas:atproxy("catch") then
			self:updateShowDatas(self.tabSelected:read())
		end
	end)

	-- 公会每日礼包领取次数, 聚宝
	idlereasy.when(self.lianjinTimes, function(_, lianjinTimes)
		if self.showDatas:atproxy("gainGold") then
			self:updateShowDatas(self.tabSelected:read())
		end
	end)

	self.btnOnekeyState:addListener(function(val, oldval)
		if val == nil then return end
		local grayState = val.leftFinished > 0 and "normal" or "hsl_gray"
		cache.setShader(self.btnOneClick, false, grayState)
		self.btnOneClick:setTouchEnabled(val.leftFinished > 0)
	end)
end

function DailyAssistantView:initModel()
	self.dailyAssistant = gGameModel.role:getIdler("daily_assistant")
	self.rmb = gGameModel.role:getIdler("rmb")
	-- self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
	self.level = gGameModel.role:getIdler("level")
	self.vip = gGameModel.role:getIdler("vip_level")
	self.unionFbAward = gGameModel.role:getIdler("union_fb_award")
	self.unionFubenPassed = gGameModel.role:getIdler("union_fuben_passed")
	self.unionId = gGameModel.role:getIdler("union_db_id")
	self.crossFishingRound = gGameModel.role:getIdler("cross_fishing_round") -- 钓鱼大赛是否开启

	self.unionLevel = gGameModel.role:getIdler("union_level")
	-- 当前挑战的关卡id
	self.curChallengeId = gGameModel.role:getIdler("endless_tower_current")
	-- 已挑战的最大关卡id
	self.maxGateId = gGameModel.role:getIdler("endless_tower_max_gate")
	local dailyRecord = gGameModel.daily_record
	 -- 重置次数
	self.resetCount = dailyRecord:getIdler("endless_tower_reset_times")
	 -- 点金次数
	self.lianjinTimes = dailyRecord:getIdler("lianjin_times")
	self.lianjinFreeTimes = gGameModel.daily_record:getIdler("lianjin_free_times")
	 -- 随机加速次数
	self.unionTrainingSpeedup = dailyRecord:getIdler("union_training_speedup")
	-- 公会副本次数
	self.unionFbTimes = dailyRecord:getIdler("union_fb_times")
	-- 公会每日礼包领取次数
	self.dailyGiftTimes = dailyRecord:getIdler("union_daily_gift_times")

	if dailyAssistantTools.getUnionFubenIsOpen() then
		-- 公会副本状态
		self.unionFuben = gGameModel.union_fuben:getIdler("states")
	end

	self.fishingSelectScene = gGameModel.fishing:getIdler("select_scene")
	self.autoFishing = gGameModel.fishing:getIdler("is_auto")
	-- 捕鱼
	-- self.fishLevel = gGameModel.fishing:getIdler("level")
	self.selectRod = gGameModel.fishing:getIdler("select_rod")
	self.selectBait = gGameModel.fishing:getIdler("select_bait")

	self.tabDatas = idlers.new()
	self.showDatas = idlers.new()
	self.tabSelected = idler.new()
	self.btnOnekeyState = idlertable.new()
	self.unionFubenData = idlers.new()
	self.rightBgPath = idler.new("city/daily_assistant/img_assistant_1.png")
	-- 冒险之路当前关卡
	self.curGateIdx = 1
	self.oneClickShowRedHint = idler.new(false)
	self.errorTips = nil
end

-- 界面显示部分逻辑处理
local UPDATE_SHOW_FUN = {
	unionDailyGift = function (view, val, featuresLeftTimes, activeTxt)
		-- 公会每日礼包 显示奖励
		if view.unionId:read() and view.unionLevel:read() then
			local lock, lockText = dailyAssistantTools.getUnionLockAndText(val.feature)
			if lock then
				val.txt = lockText
				val.finishFlag = true
			else
				val.reward = csv.union.union_level[view.unionLevel:read()].dailyGift
				val.finish = view.dailyGiftTimes:read() > 0
				val.finishFlag = val.finish
			end
		else
			val.txt = gLanguageCsv.nonunion
			val.finishFlag = true
		end
	end,
	unionRedpacket = function (view, val, featuresLeftTimes, activeTxt)
		-- 公会每日红包 特殊页签
		if not (view.unionId:read() and view.unionLevel:read()) then
			val.txt = gLanguageCsv.nonunion
			val.finishFlag = true
		else
			local lock, lockText = dailyAssistantTools.getUnionLockAndText(val.feature)
			if lock then
				val.txt = lockText
				val.finishFlag = true
			else
				val.finish = not gGameModel.role:read("union_sys_packet_can_rob")
				val.finishFlag = val.finish
			end
		end
	end,
	trainer = function (view, val, featuresLeftTimes, activeTxt)
		-- 冒险执照每日奖励 显示奖励
		val.finish = gGameModel.daily_record:read("trainer_gift_times") > 0
		val.finishFlag = val.finish
		local trainerLevel = gGameModel.role:read("trainer_level")
		val.reward = csv.trainer.trainer_level[trainerLevel].dailyAward
	end,
	gainGold = function (view, val, featuresLeftTimes, activeTxt)
		-- 聚宝
		local str, leftTimes = dailyAssistantTools.getGainGoldTimes(view.lianjinTimes:read(), view.lianjinFreeTimes:read())
		val.rich = str
		val.finish = leftTimes == 0
		val.finishFlag = val.finish
		val.leftTimes = leftTimes
		val.active = dataEasy.isDoubleHuodong("buyGold")
		if val.active then
			local str, isReunion = dailyAssistantTools.getActiveText("buyGold")
			if str then
				str = string.format("%s: %s", gDailyAssistantCsv[val.feature].cfg.name, str)
				if isReunion then
					str = string.format("%s、%s", str, gLanguageCsv.reunion)
				end
				table.insert(activeTxt, str)
			end
		end
	end,
	drawCardRmb = function (view, val)
		-- 钻石抽卡 显示次数
		local diamondCount = gGameModel.daily_record:read("dc1_free_count") -- 钻石免费抽
		local isFree = diamondCount < 1
		val.txt = gLanguageCsv.dailyAssistantFreeDrawCard
		local leftTimes = isFree and 1 or 0
		val.txt1 = string.format("%s/1", leftTimes)
		val.finish = leftTimes == 0
		val.finishFlag = val.finish
		val.leftTimes = leftTimes
	end,
	drawCardGold = function (view, val)
		-- 金币抽卡 显示次数
		local privilegeTimes = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.FreeGoldDrawCardTimes)
		local goldCount = gGameModel.daily_record:read("gold1_free_count") -- 金币免费抽
		local trainerGoldCount = gGameModel.daily_record:read("draw_card_gold1_trainer")  --训练家特权次数
		val.txt = gLanguageCsv.dailyAssistantFreeDrawCard
		local allTimes = gCommonConfigCsv.drawGoldFreeLimit + privilegeTimes
		local leftTimes = allTimes - goldCount - trainerGoldCount
		val.txt1 = string.format("%s/%s", leftTimes, allTimes)
		val.finish = leftTimes == 0
		val.finishFlag = val.finish
		val.leftTimes = leftTimes
	end,
	drawEquip = function (view, val)
		-- 饰品抽卡 显示次数
		local equipCount = gGameModel.daily_record:read("eq_dc1_free_counter") -- 饰品免费单抽次数
		local isFree = equipCount < 1
		val.txt = gLanguageCsv.dailyAssistantFreeDrawCard
		local leftTimes = isFree and 1 or 0
		val.txt1 = string.format("%s/1", leftTimes)
		val.finish = leftTimes == 0
		val.finishFlag = val.finish
		val.leftTimes = leftTimes
	end,
	explorer = function (view, val)
		-- 探险器
		local times = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.DrawItemFreeTimes)
		local freeCount = gGameModel.daily_record:read("item_dc1_free_counter")
		val.txt = gLanguageCsv.dailyAssistantFreeDrawCardItem
		local leftTimes = math.max(times + 1 - freeCount, 0)
		val.txt1 = string.format("%s/%s", leftTimes, times + 1)
		val.finish = leftTimes == 0
		val.finishFlag = val.finish
		val.leftTimes = leftTimes
	end,
	gem = function (view, val)
		-- 符石抽取 显示次数，若等级不够则显示unlock对应开放等级
		local goldFreeCount = gGameModel.daily_record:read('gem_gold_dc1_free_count')
		local rmbFreeCount = gGameModel.daily_record:read('gem_rmb_dc1_free_count')
		local leftTimes = math.max(2 - goldFreeCount - rmbFreeCount, 0)
		val.txt = gLanguageCsv.dailyAssistantFreeGem
		val.txt1 = string.format("%s/2", leftTimes)
		val.finish = leftTimes == 0
		val.finishFlag = val.finish
		if leftTimes > 0 then
			val.selected = userDefault.getForeverLocalKey('gemDrawAutoDecompose', false) and 1 or 0
			val.selectedType = "center"
		end
		val.leftTimes = leftTimes
	end,
	chip = function (view, val)
		-- 芯片抽取 显示次数，若等级不够则显示unlock对应开放等级
		local itemFreeCount = gGameModel.daily_record:read('chip_item_dc1_free_count')
		local rmbFreeCount = gGameModel.daily_record:read('chip_rmb_dc1_free_count')
		local leftTimes = math.max(2 - itemFreeCount - rmbFreeCount, 0)
		val.txt = gLanguageCsv.dailyAssistantFreeGem
		val.txt1 = string.format("%s/2", leftTimes)
		val.finish = leftTimes == 0
		val.finishFlag = val.finish
		val.leftTimes = leftTimes

		local chip = {}
		local temp = userDefault.getForeverLocalKey("selectUpSuitID", {})
		for index = 1, CHIPUPLIMIT do
			if temp[index] ~= 0 then
				table.insert(chip, temp[index])
			end
		end
		val.chip = chip
	end,
	craft = function (view, val)
		-- 石英大会 显示开放时间，若等级不够则显示unlock对应开放等级，状态
		local state, day = dataEasy.judgeServerOpen("craft")
		if not state and day then
			val.txt = string.format(gLanguageCsv.unlockServerOpen, day)
		else
			val.state = dailyAssistantTools.getCraftState()
			val.txt = gLanguageCsv.dailyAssistantCraftText
		end
	end,
	unionFight = function (view, val)
		-- 公会战 显示开放时间，若等级不够则显示unlock对应开放等级，状态
		if not (view.unionId:read() and view.unionLevel:read()) then
			val.txt = gLanguageCsv.nonunion
		else
			local lock, lockText = dailyAssistantTools.getUnionLockAndText(val.feature)
			if lock then
				val.txt = lockText
			else
				val.state = dailyAssistantTools.getUnionFightState()
				val.txt = gLanguageCsv.dailyAssistantUnionFighttText
			end
		end
	end,
	crossCraft = function (view, val)
		-- 跨服石英大会 显示开放时间，若等级不够则显示unlock对应开放等级，状态
		local state, day = dataEasy.judgeServerOpen("crossCraft")
		if not state and day then
			val.txt = string.format(gLanguageCsv.unlockServerOpen, day)
		else
			val.state = dailyAssistantTools.getCrossCraftState()
			val.txt = gLanguageCsv.dailyAssistantCrossCraftText
		end
	end,
	activityGate = function (view, val, featuresLeftTimes, activeTxt)
		local leftTimes, allTimes, DoubleActivityTxt, isDoubleActivity, haveReunion = dailyAssistantTools.getActivityGateInfo()
		val.txt = gLanguageCsv.dailyAssistantLeftTimes
		val.txt1 = string.format("%s/%s", leftTimes, allTimes)
		if leftTimes == 0 then
			-- leftFinished = leftFinished - 1
			val.finishFlag = true
		end
		val.leftTimes = leftTimes
		-- 判断特殊活动是否开启，日常运营奖励双倍或次数增加的活动是否开启
		local isOpen, cfg = dataEasy.isShowDailyActivityIcon()
		val.active = isOpen or isDoubleActivity
		if val.active then
			local str = ""
			local function insertTxt(txt)
				if string.len(str) > 0 then
					str = str .. gLanguageCsv.symbolComma
				end
				str = str .. txt
			end
			for k, txt in ipairs(DoubleActivityTxt) do
				insertTxt(txt)
			end
			if isOpen then
				insertTxt(cfg.name)
			end
			if haveReunion then
				insertTxt(gLanguageCsv.reunion)
			end
			if string.len(str) > 0 then
				str = string.format("%s: %s", gDailyAssistantCsv[val.feature].cfg.name, str)
				table.insert(activeTxt, str)
			end
		end
		featuresLeftTimes[val.feature] = leftTimes
	end,
	endlessTower = function (view, val, featuresLeftTimes, activeTxt)
		-- 冒险之路 文本次数，单独勾选框，按钮
		local str, leftTimes, max = dailyAssistantTools.getEndlessLeftTimes()
		val.btnName = str
		val.selected = view.dailyAssistant:read().endless_buy_reset
		-- 不勾选自动重置，若当前不在最大关卡则能继续一键进行
		local isMaxGateId = view.curChallengeId:read() >= view.maxGateId:read()
		if isMaxGateId and (val.selected == 0 or leftTimes == 0) then
			val.finishFlag = true
		end
		-- 获取冒险之路当前关卡
		val.rich = string.format(gLanguageCsv.dailyAssistantEndlessGate, view.curGateIdx)
		val.active = dataEasy.isDoubleHuodong("endlessSaodang")
		if val.active then
			local str, isReunion = dailyAssistantTools.getActiveText("endlessSaodang")
			if str then
				str = string.format("%s: %s", gDailyAssistantCsv[val.feature].cfg.name, str)
				if isReunion then
					str = string.format("%s、%s", str, gLanguageCsv.reunion)
				end
				table.insert(activeTxt, str)
			end
		end
		featuresLeftTimes[val.feature] = isMaxGateId and leftTimes or leftTimes + 1
	end,
	catch = function (view, val, featuresLeftTimes, activeTxt)
		-- 钓鱼 需要判断钓鱼是否开放
		if not dataEasy.isUnlock("fishing") then
			val.txt = dataEasy.getUnlockTip("fishing")
			val.finishFlag = true
		else
			val.selected = view.dailyAssistant:read().fishing_skip
			local str, leftTimes, minBait = dailyAssistantTools.getFishingText()
			val.rich = str
			val.btnName = gLanguageCsv.adjustment
			if minBait == 0 then
				val.finishFlag = true
			end
			val.active = view.crossFishingRound:read() == "start"
			if val.active then
				local str = string.format("%s: %s", gDailyAssistantCsv[val.feature].cfg.name, gLanguageCsv.FishingCompetition)
				table.insert(activeTxt, str)
			end
			featuresLeftTimes[val.feature] = leftTimes
		end
	end,
	unionContrib = function (view, val, featuresLeftTimes)
		-- 公会捐献 文本次数，按钮
		local lock, lockText = dailyAssistantTools.getUnionLockAndText(val.feature)
		if lock then
			val.txt = lockText
		else
			val.btnName = gLanguageCsv.replacementMethod
			local rich, leftTimes = dailyAssistantTools.getUnionContribText()
			val.rich = rich
			featuresLeftTimes[val.feature] = leftTimes
		end
	end,
	unionFragDonate = function (view, val, featuresLeftTimes)
		-- 公会许愿 ，文本对应碎片，按钮
		local lock, lockText = dailyAssistantTools.getUnionLockAndText(val.feature)
		if lock then
			val.txt = lockText
		else
			val.btnName = gLanguageCsv.spaceExchange2
			local rich, leftTimes = dailyAssistantTools.getUnionFragDonateText()
			val.rich = rich
			featuresLeftTimes[val.feature] = leftTimes
		end
	end,
	unionTrainingSpeedup = function (view, val, featuresLeftTimes)
		-- 为好友加速 文本次数
		local islock, lockText = dailyAssistantTools.getUnionLockAndText(val.feature)
		if islock then
			val.txt = lockText
		else
			local leftTimes = math.max(6 - view.unionTrainingSpeedup:read(), 0)
			val.txt = gLanguageCsv.dailyAssistantSpeedTimes
			val.txt1 = string.format("%s/6", leftTimes)
			val.leftTimes = leftTimes
			featuresLeftTimes[val.feature] = leftTimes
		end
	end,
	unionFuben = function (view, val, featuresLeftTimes)
		-- 公会副本 特殊页签, 判断周日
		local islock, lockText = dailyAssistantTools.getUnionLockAndText(val.feature)
		if islock then
			val.errTxt = lockText
		else
			if unionTools.currentOpenFuben() == "weekError" then
				val.errTxt = gLanguageCsv.fubenClosedOnSunday
			elseif unionTools.currentOpenFuben() ~= "open" then
				val.errTxt = gLanguageCsv.unionFubenNoOpen
			else
				val.txt = gLanguageCsv.changeTimes .. ":"
				local str, leftTimes = dailyAssistantTools.getUnionFubenTimes()
				val.txt1 = str
				if view.selectCsvId then
					val.data = view.unionFubenData:atproxy(view.selectCsvId)
				end
				val.leftTimes = leftTimes
				featuresLeftTimes[val.feature] = leftTimes
			end
			val.hasReward = dataEasy.haveUnionFubenReward()
		end
	end,
}

local FINISH_FLAG_FUN = {
	[TAB_TYPE.SIGNUP] = function(val, featuresLeftTimes)
		return val.state == nil or val.state == STATE_SIGN_UP.hadSignUp or val.state == STATE_SIGN_UP.cantSignUp
	end,
	[TAB_TYPE.UNION] = function(val, featuresLeftTimes)
		return not featuresLeftTimes[val.feature] or featuresLeftTimes[val.feature] == 0
	end,
}

function DailyAssistantView:updateShowDatas(showType)
	-- print("updateShowDatas:",showType, TAB_TYPE_NAME[showType])
	local datas = table.deepcopy(self.allDatas[showType], true)
	local leftFinished = itertools.size(datas)
	local featuresLeftTimes = {}
	local activeTxt = {}
	for k, val in pairs(datas) do
		if gDailyAssistantCsv[val.feature].cfg.inUnlock == 1 and not dataEasy.isUnlock(val.feature) then
			val.txt = dataEasy.getUnlockTip(val.feature)
			leftFinished = leftFinished - 1
		else
			UPDATE_SHOW_FUN[val.feature](self, val, featuresLeftTimes, activeTxt)
			if FINISH_FLAG_FUN[showType] and FINISH_FLAG_FUN[showType](val, featuresLeftTimes) then
				val.finishFlag = true
			end
			if val.finishFlag then
				leftFinished = leftFinished - 1
			end
		end
		val.finishFlag = nil
	end
	self.activePanel:visible(not itertools.isempty(activeTxt))
	self.btnOnekeyState:set({showType = showType, leftFinished = leftFinished, featuresLeftTimes = featuresLeftTimes, activeTxt = activeTxt})
	self.oneClickShowRedHint:set(leftFinished > 0)
	self.showDatas:update(datas)
end

function DailyAssistantView:onTabClick(list, k, v)
	if k == TAB_TYPE.UNION and not (self.unionId:read() and self.unionLevel:read()) then
		gGameUI:showTip(gLanguageCsv.nonunion)
		return
	end
	self.tabSelected:set(k)
end

function DailyAssistantView:onBtnClick(list, k, v)
	if v.feature == "endlessTower" then
		--手动重置 冒险之路
		local max = gVipCsv[self.vip:read()].endlessTowerResetTimes
		if max - self.resetCount:read() <= 0 then
			gGameUI:showTip(gLanguageCsv.resetTimesNotEnough)
			return
		end
		if self.curGateIdx == 1 then
			gGameUI:showTip(gLanguageCsv.cannotResetGate)
			return
		end
		local count = math.min(self.resetCount:read()+1, table.length(gCostCsv.endless_tower_reset_times_cost))
		local cost = gCostCsv.endless_tower_reset_times_cost[count]
		local params = {
			cb = function()
				if cost > 0 and self.rmb:read() < cost then
					uiEasy.showDialog("rmb")
					return
				end
				gGameApp:requestServer("/game/endless/reset")
				self.errorTips = nil
			end,
			isRich = cost ~= 0,
			btnType = 2,
			content = cost == 0 and gLanguageCsv.resetGate or string.format(gLanguageCsv.endlessTowerResetCost, cost),
			clearFast = true
		}
		gGameUI:showDialog(params)
	elseif v.feature == "catch" then
		-- 调整 钓鱼 判断当前是否在自动钓鱼
		if self.autoFishing:read() then
			gGameUI:showTip(gLanguageCsv.dailyAssistantAutoFishingTips)
			return
		end
		gGameUI:stackUI("city.daily_assistant.fishing_select")
	elseif v.feature == "unionContrib" then
		-- 更换方式 工会捐献
		local function callBack(val, cb)
			self:setInfo(cb, v.csvId, val)
		end
		gGameUI:stackUI("city.daily_assistant.union_contribute", nil, nil, {callBack = callBack})
	elseif v.feature == "unionFragDonate" then
		-- 更换 工会许愿
		local function callBack(val, cb)
			self:setInfo(cb, v.csvId, val)
		end
		gGameUI:stackUI("city.union.frag_donate.wish", nil, nil, {isDailySelected = true, callBack = callBack})
	end
end

-- 自动购买重置
function DailyAssistantView:onSelectClick(list, k, v)
	local selected
	local function todo(t)
		self:setInfo(nil, v.csvId, t)
	end
	if v.feature == "catch" then
		selected = self.dailyAssistant:read().fishing_skip or 1
		if selected == 1 then
			gGameUI:showDialog({
				content = gLanguageCsv.dailyAssistantFishTip,
				cb = function()
					todo(0)
				end,
				btnType = 2,
				clearFast = true,
			})
		else
			todo(selected == 1 and 0 or 1)
		end
	elseif v.feature == "endlessTower" then
		selected = self.dailyAssistant:read().endless_buy_reset or 0
		todo(selected == 1 and 0 or 1)
	elseif v.feature == "gem" then
		local state = userDefault.getForeverLocalKey('gemDrawAutoDecompose', false)
		userDefault.setForeverLocalKey('gemDrawAutoDecompose', not state)
		self.showDatas:atproxy("gem").selected = not state and 1 or 0
	end
end

-- 公会副本领取奖励
function DailyAssistantView:onUnionRewardBtnClick(list, k ,v)
	if not dataEasy.haveUnionFubenReward() then
		gGameUI:showTip(gLanguageCsv.noRewardAvailable)
		return
	end
	gGameUI:stackUI("city.union.gate.reward", nil, nil, self.unionFuben:read(), self:createHandler("onRewardCb"))
end

function DailyAssistantView:onRewardCb(tb, cb)
	local params = nil
	if cb then
		params = {cb = cb}
	end
	gGameUI:showGainDisplay(tb, params)
end

function DailyAssistantView:setRightBgPath(selectType)
	self.rightBgPath:set(string.format("city/daily_assistant/img_assistant_%s.png", selectType))
end

-- 按钮类设置消息
function DailyAssistantView:setInfo(cb, csvID, value, itemType)
	gGameApp:requestServer("/game/daily/assistant/set", function(tb)
		if tb.ret then
			for k, val in pairs(gDailyAssistantCsv) do
				if val.csvId == csvID then
					local name
					if k == "unionContrib" then
						local id = self.dailyAssistant:read().union_contrib or 1
						name = gLanguageCsv[csv.union.contrib[id].title]
					elseif k == "unionFragDonate" then
						name = dailyAssistantTools.getCardFragmentsName(self.dailyAssistant:read().union_frag_donate_card_id)
					end
					if name then
						gGameUI:showTip(string.format(gLanguageCsv.dailyAssistantChangeSuccess, name))
					end
					break
				end
			end
			self.errorTips = nil
		end
		if cb then
			cb()
		end
	end, csvID, value, itemType)
end

-- 数据返回组装
local drawCardAwardFun = {
	drawCardRmb = function (val, datas)
		-- 201
		datas["carddbIDs"] = val[1].carddbIDs
	end,
	drawCardGold = function (val, datas)
		-- 202
		for key, v in pairs(val) do
			local k1 = v.items[1][1]
			datas[k1] = (datas[k1] or 0) + v.items[1][2]
		end
	end,
	drawEquip = function (val, datas)
		-- 203
		local k1 = val[1].items[1][1]
		datas[k1] = (datas[k1] or 0) + val[1].items[1][2]
	end,
	explorer = function (val, datas)
		-- 204
		local k1 = val[1][1][1][1]
		datas[k1] = (datas[k1] or 0) + val[1][1][1][2]
	end,
	gem = function (val, datas)
		-- 205
		for k, v in pairs(val) do
			for key, v1 in pairs(v["items"]) do
				local k1 = v1[1]
				datas[k1] = (datas[k1] or 0) + v1[2]
			end
		end
	end,
	chip = function (val, datas)
		-- 206
		for k, v in pairs(val) do
			if v["chipdbIDs"] then
				if datas["chipdbIDs"] == nil then datas["chipdbIDs"] = {} end
				table.insert(datas["chipdbIDs"], v["chipdbIDs"][1])
			elseif v["items"] then
				for key, v1 in pairs(v["items"]) do
					local k1 = v1[1]
					datas[k1] = (datas[k1] or 0) + v1[2]
				end
			end
		end
	end,
	-- 101
	unionDailyGift = getItemAwards,
	-- 102
	unionRedpacket = getItemAwards,
	-- 103
	trainer = getItemAwards,
	-- 104
	gainGold = function (val, datas)
		getItemAwards(val, datas, "gold")
	end,
}

local function splic(str, name)
	if str == "" then
		str = string.format("[ %s ]", name)
	else
		str = string.format("%s%s [ %s ]", str, gLanguageCsv.symbolComma, name)
	end
	return str
end

function DailyAssistantView:sendOnekey(filterKeys, award, flags)
	local tabType = self.tabSelected:read()
	local featuresLeftTimes = self.btnOnekeyState:read().featuresLeftTimes
	if itertools.isempty(filterKeys) then
		filterKeys = nil
	end
	gGameApp:requestServer("/game/daily/assistant/onekey", function(tb)
		self:updateShowDatas(tabType)
		local data = tb.view
		local str = ""
		if tabType == TAB_TYPE.SIGNUP then
			local errorStr = ""
			for k, val in pairs(data) do
				for k1, val1 in pairs(self.allDatas[tabType]) do
					if val1.csvId == k then
						if val == 1 then -- 成功
							str = splic(str, val1.name)
							break
						elseif type(val) == "table" and val.errorID then -- 失败
							errorStr = splic(errorStr, val1.name)
							break
						end
					end
				end
			end
			-- 战斗报名
			if str ~= "" or errorStr ~= "" then
				if str ~= "" then
					str = string.format("%s %s", str, gLanguageCsv.signUpSuccess)
				end
				if errorStr ~= "" then
					if str ~= "" then
						str = str .. ","
					end
					str = string.format("%s %s %s", str, errorStr, gLanguageCsv.signUpFailed)
				end
				gGameUI:showTip(str)
			end
			return
		else
			for k, val in pairs(data) do
				for k1, val1 in pairs(self.allDatas[tabType]) do
					if val1.csvId == k then
						if type(val) == "table" and val.errorID then -- 失败
							str = gLanguageCsv[val.errorID] or val.errorID
							data[k] = nil
							break
						end
					end
				end
			end
		end

		if tabType == TAB_TYPE.REWARD or tabType == TAB_TYPE.DRAWCARD then
			-- 奖励领取, 抽卡
			if not itertools.isempty(data) then
				local datas = {}
				local dailyAssistantCsv = csv.daily_assistant
				for k, val in pairs(data) do
					local feature = dailyAssistantCsv[k].features
					drawCardAwardFun[feature](val, datas)
				end
				self:onRewardCb(datas)
			end
			if str ~= "" then
				gGameUI:showTip(str)
			end

		elseif tabType == TAB_TYPE.ADVENTURE or tabType == TAB_TYPE.UNION then
			-- 快速冒险, 工会事宜
			self:showSweepView(featuresLeftTimes, data, award)
		end
	end, tabType, filterKeys, flags)
end

function DailyAssistantView:sendRequestServerOnekey(award)
	local tabType = self.tabSelected:read()
	local btnOnekeyState = self.btnOnekeyState:read()
	local nowTabTypeAllFeatures = table.deepcopy(self.allDatas[tabType], true)
	-- 冒险之路是否消耗钻石扫荡标识
	local flags = {}
	-- 需要忽略的csvId，暂时没有需要用到的地方，字段先保留
	local filterKeys = {}
	local showDialogDatas = {}

	local function showDialog(data, isContinue)
		gGameUI:showDialog({
			content = data.content,
			cb = function()
				if not data.okInput or data.okInput() then
					isContinue()
				end
			end,
			cancelCb = function()
				if not data.cancelInput or data.cancelInput() then
					isContinue()
				end
			end,
			btnType = 2,
			clearFast = true,
			isRich = data.isRich or false,
		})
	end

	local function isContinue()
		if itertools.isempty(showDialogDatas) then
			self:sendOnekey(filterKeys, award, flags)
		else
			local data = table.deepcopy(showDialogDatas[1])
			table.remove(showDialogDatas, 1)
			showDialog(data, isContinue)
		end
	end

	-- 点击一键进行确认，flags为相关模块携带参数，需要跳过的模块插入filterKeys中
	for feature, val in pairs(nowTabTypeAllFeatures) do
		local csvId = gDailyAssistantCsv[feature].csvId
		if feature == "endlessTower" then
			flags[csvId] = 0
			local isSelected = self.dailyAssistant:read().endless_buy_reset
			local max = gVipCsv[self.vip:read()].endlessTowerResetTimes
			local resetCount = self.resetCount:read()
			-- 判断当前次数是否有消耗钻石的次数
			if isSelected == 1 and max > 1 and resetCount < 2 then
				-- 判断是否消耗钻石扫荡
				local allCost = 0
				for i = resetCount+1, max do
					local count = math.min(i, table.length(gCostCsv.endless_tower_reset_times_cost))
					local cost = gCostCsv.endless_tower_reset_times_cost[count]
					allCost = allCost + cost
				end
				local str = string.format(gLanguageCsv.dailyAssistantEndlessTip1, allCost)
				table.insert(showDialogDatas, {
					content = str,
					isRich = true,
					okInput = function()
						-- 判断钻石够不够
						if allCost > 0 and self.rmb:read() < allCost then
							uiEasy.showDialog("rmb")
							return false
						else
							flags[csvId] = 1
							return true
						end
					end
				})
			end
		elseif feature == "catch" then
			if self.autoFishing:read() then
				table.insert(filterKeys, csvId)
			end
		elseif feature == "gem" then
			flags[csvId] = userDefault.getForeverLocalKey('gemDrawAutoDecompose', false) and 1 or 0
		elseif feature == "chip" then
			local selectUpSuitIDTab = userDefault.getForeverLocalKey("selectUpSuitID", {})
			local temp = {}
			for k, id in ipairs(selectUpSuitIDTab) do
				if id ~= 0 then
					table.insert(temp, id)
				end
			end
			flags[csvId] = temp
		end
	end
	isContinue()
end

local featuresFunTab = {
	catch = function (feature, changeTimes, viewDatas, sweepData, notes)
		if changeTimes > 0 and viewDatas then
			local award = {}
			award["fish"] = viewDatas.fish
			table.insert(sweepData, {
				exp = viewDatas.win,
				items = award,
				dailyDatas = {feature = feature, win = viewDatas.win, fail = viewDatas.fail}
			})
			table.insert(sweepData, {textDatas = {content = gLanguageCsv.textReward}})
			table.insert(sweepData, {noTitle = true, items = viewDatas.award})
			return false
		end
		return true
	end,
	activityGate = function (feature, changeTimes, viewDatas, sweepData, notes)
		if viewDatas and not itertools.isempty(viewDatas) then
			table.insert(sweepData, {exp = changeTimes, items = viewDatas, dailyDatas = {feature = feature}})
			return false
		end
		return true
	end,
	endlessTower = function (feature, changeTimes, viewDatas, sweepData, notes)
		if viewDatas and not itertools.isempty(viewDatas) then
			table.insert(sweepData, {exp = changeTimes, items = viewDatas, dailyDatas = {feature = feature}})
			return false
		end
		return true
	end,
	unionContrib = function (feature, changeTimes, viewDatas, sweepData, notes)
		local award = {}
		if changeTimes > 0 and viewDatas then
			for k1, v1 in pairs(viewDatas) do
				for k2, v2 in pairs(v1) do
					award[k2] = (award[k2] or 0) + v2
				end
			end
			table.insert(sweepData, {exp = changeTimes, items = award, dailyDatas = {feature = feature}})
			return false
		end
		return true
	end,
	unionFragDonate = function (feature, changeTimes, viewDatas, sweepData, notes)
		local cardId = gGameModel.role:read("daily_assistant").union_frag_donate_card_id
		if changeTimes > 0 and cardId then
			for _, card in gGameModel.cards:pairs() do
				local id = card:read("card_id")
				if cardId == id then
					local cardCsv = csv.cards[id]
					local name = cardCsv.name .. gLanguageCsv.fragment
					table.insert(notes, string.format(gLanguageCsv.wishSuccess, name))
					return false, true
				end
			end
			return false
		end
		return true
	end,
	unionTrainingSpeedup = function (feature, changeTimes, viewDatas, sweepData, notes)
		local award = {}
		if changeTimes > 0 then
			award["gold"] = gCommonConfigCsv.unionTrainingSpeedUpGold * changeTimes
			table.insert(sweepData, {exp = changeTimes, items = award, dailyDatas = {feature = feature}})
			return false
		end
		return true
	end,
}

-- 显示一键扫荡奖励弹窗
function DailyAssistantView:showSweepView(featuresLeftTimes, view, award)
	local tabType = self.tabSelected:read()
	local btnOnekeyState = self.btnOnekeyState:read()
	local nowTabTypeAllFeatures = table.deepcopy(self.allDatas[tabType], true)
	local sweepData = {}
	local feature = "unionFuben"
	local notes = {}
	local beizhuFeatures = {}
	-- 公会许愿成功标识
	local unionFragDonateIsSuccess = false

	for feature, val in pairs(nowTabTypeAllFeatures) do
		local csvId = val.csvId
		local viewDatas = view[csvId]
		local oldTimes = featuresLeftTimes[feature] or 0
		local nowTimes = btnOnekeyState.featuresLeftTimes[feature] or 0
		local changeTimes = oldTimes - nowTimes
		if featuresFunTab[feature] then
			local needBeizhu, isSuccess = featuresFunTab[feature](feature, changeTimes, viewDatas, sweepData, notes)
			unionFragDonateIsSuccess = isSuccess
			if needBeizhu and nowTimes > 0 then
				table.insert(beizhuFeatures, feature)
			end
		end
	end
	-- 公会副本奖励特殊处理
	if award then
		for k, val in pairs(award) do
			feature = "unionFuben"
			table.insert(sweepData, {exp = val.exp , items = val.items, dailyDatas = {feature = feature}})
			if val.bossKilled then
				local content = "#Pfont/youmi1.ttf##C0xFF5B545B#" .. gLanguageCsv.crossMineBossHasKilled
				local params = {isRich = true}
				table.insert(sweepData, {textDatas = {content = content, params = params}})
			end
		end
	end

	-- 扫荡备注最后添加
	-- 有奖励的时候弹窗，没有奖励备注以飘字形式展示
	if not itertools.isempty(beizhuFeatures) then
		local content = ""
		for k, v in pairs(beizhuFeatures) do
			content = string.format("%s[ %s ] ", content, gDailyAssistantCsv[v].cfg.name)
			if k ~= #beizhuFeatures then
				content = content .. gLanguageCsv.symbolComma
			end
		end
		content = content .. gLanguageCsv.dailyAssistantCantTodo
		if itertools.isempty(sweepData) then
			if unionFragDonateIsSuccess then
				content = string.format("%s,%s",gLanguageCsv.wishSuccess1, content)
			end
			gGameUI:showTip(content)
			if itertools.isempty(view) then
				self.errorTips = content
			end
			return
		else
			table.insert(notes, "#C0xFF5B545B#" .. content)
		end
	end
	if not itertools.isempty(notes) then
		table.insert(sweepData, {
			textDatas = {content = notes, params = {isRich = true, align = "left", fontSize = 40}},
			dailyDatas = {hasTitle = gLanguageCsv.mopUpNotes}
		})
	end
	if itertools.isempty(sweepData) then
		return
	end
	local oldCapture = gGameModel.capture:read("limit_sprites")
	gGameUI:stackUI("city.gate.sweep", nil, nil, {
		sweepData = sweepData,
		oldRoleLv = self.level:read(),
		showType = 2,
		hasExtra = false,
		from = "dailyAssistant",
		title1 = gLanguageCsv.oneKey,
		title2 = gLanguageCsv.mopUp1,
		oldCapture = oldCapture,
	})
end

-- 一键操作
function DailyAssistantView:onBtnOneClick()
	if self.errorTips then
		gGameUI:showTip(self.errorTips)
		return
	end
	local featuresLeftTimes = self.btnOnekeyState:read().featuresLeftTimes
	if self.tabSelected:read() == TAB_TYPE.UNION and featuresLeftTimes["unionFuben"] then
		self:onBtnThreeFight()
	else
		self:sendRequestServerOnekey()
	end
end

-- 公会战挑战3次
function DailyAssistantView:onBtnThreeFight()
	local selectCsvId = self.selectCsvId
	local gateData = self.unionFubenData:atproxy(self.selectCsvId)
	local battleNum = self.unionFbTimes:read()
	local battleNumRemain = math.max(0, 3 - battleNum)
	local notBattled = (gateData.maxHp == 0)
	local remainHp = gateData.surplusHp
	local csvGate = csv.union.union_fuben[selectCsvId]
	local sweepData = {}
	local count = 0
	local function postThree()
		gateData = self.unionFubenData:atproxy(selectCsvId)
		if remainHp == 0 then
			selectCsvId = self.selectCsvId
			csvGate = csv.union.union_fuben[selectCsvId]
		end
		count = count + 1
		battleEntrance.battleRequest("/game/union/fuben/start", selectCsvId, csvGate.gateID)
			:onStartOK(function(data)
				data.damage = gateData.damage
				data.hpMax = gateData.maxHp
			end)
			:onResult(function(data, result)
				local view = result.serverData.view
				gateData = self.unionFubenData:atproxy(selectCsvId)
				local maxHp = gateData.maxHp
				remainHp = gateData.surplusHp
				local supHp = math.max(view.damage, 0) / maxHp
				local percent = math.floor(supHp * 10000) / 100 .. "%"
				local bossKilled = false
				if remainHp == 0 then
					bossKilled = true
				end
				table.insert(sweepData, {items = view.drop, exp = percent, bossKilled = bossKilled})
				battleNumRemain = battleNumRemain - 1
				notBattled = false
				if battleNumRemain > 0 then
					postThree()
				else
					if #sweepData >= 1 then
						self:sendRequestServerOnekey(sweepData)
					end
					return false
				end
			end)
			:run()
	end
	if battleNumRemain > 0 then
		postThree()
	else
		self:sendRequestServerOnekey()
	end
end

function DailyAssistantView:onBtnShowActiveNoteClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function DailyAssistantView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(string.format(gLanguageCsv.dailyAssistantActiveTxt, TAB_TYPE_NAME[self.tabSelected:read()]))
		end),
	}
	for k, txt in pairs(self.btnOnekeyState:read().activeTxt) do
		table.insert(context, txt)
	end
	return context
end


return DailyAssistantView