-- @date:   2020-06-02
-- @desc:   钓鱼预研界面

local ViewBase = cc.load("mvc").ViewBase
local FishingView = class("FishingView", ViewBase)

-- 记录当前动画类型
local SKEL_STATE = {
	INSIDE = 1,
	OUTSIDE = 2,
}

-- 记录关闭点击
local CLOSE_STATE = {
	SHOWTIP = 1,
	CLOSE = 2,
}

-- 记录自动钓鱼状态
local AUTO_STATE = {
	BEGAN = 1,
	END = 2,
}

FishingView.RESOURCE_FILENAME = "fishing.json"
FishingView.RESOURCE_BINDING = {
	["partner"] = "partner",
	["auto"] = "auto",
	["activityTip"] = "activityTip",
	["txtRank"] = "txtRank",
	["timer"] = "timer",
	["timer.txt2"] = {
		varname = "gameEndTimerTxt",
		binds = {
			event = "text",
			idler = bindHelper.self("gameTimer"),
			method = function(val)
				local tab = time.getCutDown(val)
				return tab.short_clock_str
			end,
		},
	},
	["auto.time"] = "txtRefreshTime",
	["auto.time1"] = {
		varname = "refreshTime",
		binds = {
			event = "text",
			idler = bindHelper.self("deltaTime"),
			method = function(val)
				local tab = time.getCutDown(val)
				return tab.min_sec_clock
			end,
		},
	},
	["auto.fish"] = "autoFish",
	["auto.fish.item"] = "fishItem",
	["auto.fish.list"] = {
		varname = "fishList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("autoFishCfg"),
				item = bindHelper.self("fishItem"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						event = "extend",
						class = "fish_icon",
						props = {
							data = {
								key = k,
								num = v,
							},
							onNode = function(node)
								node:xy(10, 10)
							end,
							onNodeClick = true,
						},
					})
				end,
			},
		},
	},
	["auto.award.item"] = "awardItem",
	["auto.award.list"] = {
		varname = "awardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("autoAwardCfg"),
				item = bindHelper.self("awardItem"),
				onItem = function(list, node, k, v)
					if v.key == "id" then
						local unitID = csv.cards[v.val].unitID
						local star = csv.cards[v.val].star
						local rarity = csv.unit[unitID].rarity
						bind.extend(list, node, {
							class = "card_icon",
							props = {
								unitId = unitID,
								rarity = rarity,
								star = star,
							},
						})
						bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, k, v)}})
					else
						bind.extend(list, node, {
							class = "icon_key",
							props = {
								data = {
									key = v.key,
									num = v.val,
								}
							},
						})
					end
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onitemClick"),
			},
		},
	},
	["partner.partnerPos"] = "partnerPos",
	["centerPanel"] = "centerPanel",
	["recordPanel"] = "recordPanel",
	["recordPanel.item"] = "item",
	["recordPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("fishingRecord"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						event = "extend",
						class = "fish_icon",
						props = {
							data = {
								key = k,
								num = v,
							},
							onNode = function(panel)
								panel:scale(0.8)
							end,
							onNodeClick = true,
						},
					})
				end,
			},
		},
	},
	["txtRank.item"] = "rankItem",   --  排行列表
	["txtRank.list"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("ranksData"),
				item = bindHelper.self("rankItem"),
				padding = 10,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("rank", "name", "score")
					childs.rank:text(k)
					childs.name:text(v.name)
					childs.score:text(v.point)
				end,
				asyncPreload = 10,
			},
		},
	},
	["leftPanel"] = "leftPanel",
	["leftPanel.btnTools"] = {
		varname = "btnTools",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnTools")}
		},
	},
	["leftPanel.btnLv"] = {
		varname = "btnLv",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnLv")}
		},
	},
	["leftPanel.btnHandbook"] = {
		varname = "btnHandbook",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnHandbook")}
		},
	},
	["leftPanel.btnShop"] = {
		varname = "btnShop",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnShop")}
		},
	},
	["leftPanel.btnRank"] = {
		varname = "btnRank",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRank")}
		},
	},
	["leftPanel.itemBait"] = {
		varname = "itemBait",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBait")}
		},
	},
	["leftPanel.itemRod"] = {
		varname = "itemRod",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRod")}
		},
	},
	["btnRules"] = {
		varname = "btnRules",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		},
	},
	["waitPanel"] = "waitPanel",
	["centerPanel.barPanel.bar"] = "scoreBar",
	["centerPanel.fishingPanel"] = "fishingPanel",
	["centerPanel.fishingPanel.fish"] = "fish",
	["centerPanel.fishingPanel.bg"] = "fishBg",
	["centerPanel.fishingPanel.line"] = "line",
	["centerPanel.fishingPanel.fishhook"] = "fishhook",
	["rightPanel.imgTip"] = "imgTip",
	["rightPanel.timesPanel"] = "timesPanel",
	["rightPanel.btnThrow"] = "btnThrow",
	["rightPanel.btnTake"] = "btnTake",
	["rightPanel.btnThrow.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE, size = 5}},
		},
	},
	["rightPanel.btnTake.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE, size = 5}},
		},
	},
	["leftPanel.btnLv.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["leftPanel.btnHandbook.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["leftPanel.btnShop.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["leftPanel.btnRank.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["leftPanel.btnTools.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["recordPanel.txtRecord"] = {
		varname = "txtRecord",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 3}},
		},
	},
	["rightPanel.timesPanel.surplus"] = {
		varname = "surplus",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["rightPanel.timesPanel.time"] = {
		varname = "time",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["rightPanel.timesPanel.times"] = {
		varname = "times",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["centerPanel.tipPanel.txtKeep"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["centerPanel.tipPanel.txtAnd"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["centerPanel.tipPanel.txtEnd"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["timer.txt1"] = {
		varname = "gameEndTimer",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
}

function FishingView:onCreate(idx, rank, cb)
	self.cb = cb
	local sceneCfg = csv.fishing.scene[idx]
	self.titleBack = gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = sceneCfg.name, subTitle = sceneCfg.titleEn})

	-- 初始化当前动画类型
	self.skelState = SKEL_STATE.INSIDE
	-- 初始化自动钓鱼类型
	self.autoType = AUTO_STATE.END
	-- spine
	self:initSkel(idx)
	self:initModel()
	-- 自动钓鱼鱼数据
	self.autoFishCfg = idlertable.new({})
	-- 自动钓鱼奖励数据
	self.autoAwardCfg = idlers.newWithMap({})
	-- 退出键状态
	self.exitType = idler.new("normal")
	-- 钓鱼大赛期间记录普通场景抛竿按钮提示次数
	self.onThrowBtn = idler.new(0)
	-- 钓鱼大赛期间记录普通场景自动钓鱼按钮提示次数
	self.onAutoBtn = idler.new(0)
	-- 钓鱼大赛排行榜
	self.ranksData = idlers.newWithMap({})
	-- 自动钓鱼上钩倒计时
	self.deltaTime = idler.new(0)
	-- 钓鱼大赛开启倒计时
	self.gameTimer = idler.new(0)

	if matchLanguage({"en"}) then
		adapt.setAutoText(self.txtRecord, nil, 120)
	else
		self.txtRecord:getVirtualRenderer():setLineSpacing(-7)
	end
	self.btnRank:visible(idx == game.FISHING_GAME)
	self.txtRank:visible(idx == game.FISHING_GAME)
	self.rankList:setTouchEnabled(false)
	self.fishingGameSkel:visible(idx == game.FISHING_GAME)
	self.dasaixiaoren1:visible(idx == game.FISHING_GAME)
	self.dasaixiaoren2:visible(idx == game.FISHING_GAME)
	text.addEffect(self.gameEndTimerTxt, {outline = {color = ui.COLORS.OUTLINE.WHITE}})

	local rankData = {}
	if rank then
		for i,v in ipairs(rank.ranks) do
			if i <= 3 and v then
				table.insert(rankData, v)
			end
		end
	end
	self.ranksData:update(rankData)

	if idx == game.FISHING_GAME then
		self:fishingGameTimer()
	end

	local old = self.fishLevel:read()

	-- 今日记录
	idlereasy.any({self.fishLevel, self.fishingRecord, self.fishingCounter, self.selectRod, self.selectBait, self.selectPartner, self.items, self.crossFishingRound},
		function(_,fishLevel,fishingRecord,fishingCounter,selectRod,selectBait,selectPartner,items,crossFishingRound)
		-- 钓鱼大赛crossFishingRound = start为开始   = closed 为未开始
		self.timer:visible(idx == game.FISHING_GAME and crossFishingRound == "start")
		adapt.oneLineCenterPos(cc.p(260, self.gameEndTimer:y()), {self.gameEndTimer, self.gameEndTimerTxt})
		if idx ~= game.FISHING_GAME then
			self:initActivityTip(crossFishingRound)
		end

		self.idx = idx
		self.nowTimes = gCommonConfigCsv.fishingDailyTimes - fishingCounter
		self.times:text(self.nowTimes)
		adapt.oneLineCenterPos(cc.p(140, self.times:y()), {self.surplus, self.times, self.time}, cc.p(10, 0))

		local levelCfg = csv.fishing.level[fishLevel]

		-- 当前鱼饵图标
		local baitCfg = csv.fishing.bait[selectBait]
		if selectBait and baitCfg then
			self.baitCount = items[baitCfg.itemId]
			self.map = itertools.map(baitCfg.scene, function(_, v) return v, true end)
			if self.map[self.idx] then
				bind.extend(self, self.itemBait, {
					class = "fishtools_icon",
					props = {
						data = {
							key = baitCfg.itemId,
							typ = 2,
							lock = items[baitCfg.itemId],
						},
						onNode = function(node)
							node:xy(-4, -4)
								:scale(0.8)
								:z(3)
						end,
						num = true,
					},
				})
			end
		end

		-- 当前鱼竿图标
		local rodCfg = csv.fishing.rod[selectRod]
		if selectRod and rodCfg then
			bind.extend(self, self.itemRod, {
				class = "fishtools_icon",
				props = {
					data = {
						key = rodCfg.itemId,
						typ = 1,
					},
					onNode = function(node)
						node:xy(-4, -4)
							:scale(0.8)
							:z(3)
					end,
				},
			})
			self.diaoyuActionSkel:setSkin(rodCfg.res)
		end

		-- 当前伙伴图标
		self.partnerPos:get("partner"):visible(selectPartner ~= 0)
		if selectPartner ~= 0 then
			local partnerCfg = csv.fishing.partner[selectPartner]
			local unitCfg = csv.unit[partnerCfg.unitId]
			self.partnerPos:removeAllChildren()
			local partner = widget.addAnimationByKey(self.partnerPos, unitCfg.unitRes, 'partner', "standby_loop", 1)
				:scale(-(partnerCfg.scale), partnerCfg.scale)
			self.partner:xy(self.diaoyuActionSkel:x() + 230, self.diaoyuActionSkel:y() + 100)
			bind.touch(self, self.partner, {methods = {ended = function()
				if self.nowTimes <= 0 then
					gGameUI:showTip(gLanguageCsv.fishNoTimes)
				elseif selectBait == nil or baitCfg == nil or self.map[self.idx] ~= true then
					gGameUI:showTip(gLanguageCsv.noBait)
				elseif selectRod == nil or rodCfg == nil then
					gGameUI:showTip(gLanguageCsv.noRod)
				elseif selectBait and baitCfg then
					if items[baitCfg.itemId] == nil then
						gGameUI:showTip(gLanguageCsv.noBaitCount)
					else
						self:onPartnerClick(crossFishingRound)
					end
				else
					self:onPartnerClick(crossFishingRound)
				end
			end}})
		end

		local function dialogShow()
			local show = 0
			self:enableSchedule()
			self:schedule(function()
				if show == 0 then
					self.partner:get("bg"):hide()
					show = 1
				elseif show == 1 then
					self.partner:get("bg"):show()
					show = 0
				end
			end, 5, 0, 7)
		end
		-- 钓鱼大赛自动钓鱼unlock
		if self.idx == game.FISHING_GAME then
			if self.isAuto and self.isAuto:read() == true then
				self.partner:setTouchEnabled(false)
				dialogShow()
			else
				local isUnlock = dataEasy.isUnlock(gUnlockCsv.gameAutoFish)
				self.partner:get("bg"):visible(isUnlock)
				self.partner:setTouchEnabled(isUnlock)
				if isUnlock == true then
					dialogShow()
				end
			end
		else
			if self.isAuto and self.isAuto:read() == true then
				self.partner:setTouchEnabled(false)
				dialogShow()
			else
				local isUnlock = dataEasy.isUnlock(gUnlockCsv.autoFish)
				self.partner:get("bg"):visible(isUnlock)
				self.partner:setTouchEnabled(isUnlock)
				if isUnlock == true then
					dialogShow()
				end
			end
		end

		-- 抛竿按钮
		local function onThrowClick()
			if crossFishingRound == "start" and self.onThrowBtn:read() == 0 and self.idx ~= game.FISHING_GAME then
				gGameUI:showDialog{
					strs = {
						gLanguageCsv.fishGameStartIsFishing
					},
					cb = function()
						self.onThrowBtn:set(1)
						self:onThrow(rodCfg.extraSpeed, rodCfg.lowerSpeed, rodCfg.extraZone, rodCfg.lowerWait, baitCfg.lowerRandom, baitCfg.lowerWait, levelCfg.timeDown, levelCfg.fasterSpeed)
					end,
					fontSize = 40,
					btnType = 2,
					clearFast = true,
				}
			else
				if crossFishingRound == "closed" and self.idx == game.FISHING_GAME then
					gGameUI:showTip(gLanguageCsv.theContestIsOverCantFishing)
				else
					self:onThrow(rodCfg.extraSpeed, rodCfg.lowerSpeed, rodCfg.extraZone, rodCfg.lowerWait, baitCfg.lowerRandom, baitCfg.lowerWait, levelCfg.timeDown, levelCfg.fasterSpeed)
				end
			end
		end

		bind.touch(self, self.btnThrow, {methods = {ended = function()
			if self.nowTimes <= 0 then
				gGameUI:showTip(gLanguageCsv.fishNoTimes)
			elseif selectBait == nil or baitCfg == nil or self.map[self.idx] ~= true then
				gGameUI:showTip(gLanguageCsv.noBait)
			elseif selectRod == nil or rodCfg == nil then
				gGameUI:showTip(gLanguageCsv.noRod)
			elseif selectBait and baitCfg then
				if items[baitCfg.itemId] == nil then
					gGameUI:showTip(gLanguageCsv.noBaitCount)
				else
					onThrowClick()
				end
			else
				onThrowClick()
			end
		end}})

		-- 钓鱼大赛结束自动钓鱼自动隐藏
		local function autoStop()
			self:enableSchedule():unSchedule(6000)
			self:enableSchedule():unSchedule(7000)
			self.auto:hide()
			self.btnThrow:show()
			self.autoFishCfg:set({})
			self.autoType = AUTO_STATE.END
			local isUnlock = dataEasy.isUnlock(gUnlockCsv.autoFish)
			self.partner:setTouchEnabled(isUnlock)
			if self.fishLevel:read() > old then
				gGameUI:stackUI("city.adventure.fishing.upgrade")
			end
			gGameUI:showDialog{
				strs = {
					gLanguageCsv.fishingGameIsOverAutoIsStop
				},
				fontSize = 40,
				btnType = 1,
				clearFast = true,
			}
		end

		if crossFishingRound == "closed" and self.autoType == AUTO_STATE.BEGAN and self.idx == game.FISHING_GAME then
			autoStop()
		end
	end)

	if self.isAuto then
		if self.isAuto:read() == true then
			self:autoFishing()
		end
	end

	-- 鱼的参数
	local fishTabs = {}
	for k,v in csvPairs(csv.fishing.fish) do
		fishTabs[k] = {
			csvId = k,
			speed = v.speed,
			escape = v.escape,
			randMove = v.randMove,
			competitionSpeed = v.competitionSpeed,
			competitionEscape = v.competitionEscape,
			competitionRandMove = v.competitionRandMove,
			time = v.time,
			deadTime = v.deadTime
		}
	end
	self.fishTabs = idlers.new(fishTabs)
	self.fishTabs:update(fishTabs)

	self.btnTake:addTouchEventListener(function(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			-- 按住收线按钮
			self:onTake()
		elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
			-- 松开收线按钮
			self:loosen()
		end
	end)
end

function FishingView:initModel()
	self.fishLevel = gGameModel.fishing:getIdler("level")
	self.fishingRecord = gGameModel.daily_record:getIdler('fishing_record')
	self.fishingCounter = gGameModel.daily_record:getIdler('fishing_counter')
	self.selectRod = gGameModel.fishing:getIdler("select_rod")
	self.selectBait = gGameModel.fishing:getIdler("select_bait")
	self.selectPartner = gGameModel.fishing:getIdler("select_partner")
	self.items = gGameModel.role:getIdler("items")
	self.fishModel = gGameModel.fishing:getIdler("fish")
	self.isAuto = gGameModel.fishing:getIdler("is_auto")
	self.autoStopped = gGameModel.fishing:getIdler("auto_stopped")
	self.autoAward = gGameModel.fishing:getIdler("auto_award")
	self.autoWinCounter = gGameModel.fishing:getIdler("auto_win_counter")
	self.autoFailCounter = gGameModel.fishing:getIdler("auto_fail_counter")
	self.crossFishingRound = gGameModel.role:getIdler("cross_fishing_round")
	self.autoStartTime = gGameModel.fishing:getIdler("auto_start_time")
end

-- spine
function FishingView:initSkel(idx)
	local pNode = self:getResourceNode()
	local cfg = csv.fishing.scene[idx]
	widget.addAnimationByKey(pNode, cfg.res, 'diaoyuBg', "effect_loop", 2)
		:xy(display.sizeInView.width / 2, display.sizeInView.height / 2 - 20)
		:scale(2)

	self.diaoyuActionSkel = widget.addAnimationByKey(pNode, "diaoyu/diaoyu.skel", 'diaoyu', "daiji_loop", 3)
	self.diaoyuActionSkel:anchorPoint(cc.p(0.5,0.5))
		:xy(display.sizeInView.width / 2 + cfg.characterPos[1], display.sizeInView.height / 2 + cfg.characterPos[2])
		:scale(2)
	self.diaoyuActionSkel:setSkin("rod_0")

	self.waitPanel:xy(self.diaoyuActionSkel:x() + 20, self.diaoyuActionSkel:y() + 365)

	widget.addAnimationByKey(self.partnerPos, "koudai_miaowazhongzi/hero_miaowazhongzi.skel", 'partner', "standby_loop", 1)
		:scaleX(-1)

	self.fishingGameSkel = widget.addAnimationByKey(pNode, "fishing/diaoyudasai.skel", 'diaoyudasai', "effect_loop", 3)
	self.fishingGameSkel:anchorPoint(cc.p(0.5,0.5))
		:xy(display.sizeInView.width / 2 - 720, display.sizeInView.height / 2 + 220)
		:scale(2)

	self.dasaixiaoren1 = widget.addAnimationByKey(pNode, "fishing/dasaixiaoren1.skel", 'dasaixiaoren1', "effect_loop", 2)
	self.dasaixiaoren1:anchorPoint(cc.p(0.5,0.5))
		:xy(display.sizeInView.width / 2 + 800, display.sizeInView.height / 2 + 60)

	self.dasaixiaoren2 = widget.addAnimationByKey(pNode, "fishing/dasaixiaoren2.skel", 'dasaixiaoren2', "effect_loop", 2)
	self.dasaixiaoren2:anchorPoint(cc.p(0.5,0.5))
		:xy(display.sizeInView.width / 2 + 600, display.sizeInView.height / 2 - 20)
end

-- 点击抛竿按钮                额外速度  降低逃跑速度 扩大鱼钩范围 降低等待时间 降低鱼浮动范围	降低等待时间 减少等待时间	钓鱼进度速度提升
function FishingView:onThrow(extraSpeed, lowerSpeed, extraZone, lowerWait, lowerRandom, lowerWait2, timeDown, fasterSpeed)
	self.partner:setTouchEnabled(false)
	itertools.invoke({self.btnThrow, self.timesPanel, self.btnRules, self.recordPanel, self.leftPanel, self.activityTip}, "hide")
	self.diaoyuActionSkel:play("effect_paoxian")
	self.exitType = CLOSE_STATE.SHOWTIP

	gGameApp:requestServer("/game/fishing/once/start", function(tb)
		self.fishTab = self.fishTabs:atproxy(tb.view.fish)
		local rwait = math.random(self.fishTab.time[1], self.fishTab.time[2])

		local fishhookExtraSize = extraZone == 0 and extraZone or extraZone - 1																					--鱼钩大小加成
		local moveLower = lowerRandom																															--鱼移动减少范围
		local basicsUpVal = (self.idx == game.FISHING_GAME and self.fishTab.competitionSpeed ~= 0) and self.fishTab.competitionSpeed or self.fishTab.speed		--进度条基础涨值
		local basicsDownVal = (self.idx == game.FISHING_GAME and self.fishTab.competitionEscape ~= 0) and self.fishTab.competitionEscape or self.fishTab.escape	--进度条基础降值
		local addUpVal = extraSpeed	+ fasterSpeed																												--进度条涨值加成
		local addDownVal = lowerSpeed																															--进度条降值加成(数值不能超过基础速度)
		local lowerWait = math.ceil(rwait * (1 - (lowerWait + lowerWait2 + timeDown)))																			--降低咬钩等待时间

		self.fishhook:height(self.fishhook:height() + self.fishhook:height() * fishhookExtraSize)
		local wait = math.max(rwait - lowerWait, gCommonConfigCsv.fishingLowestWaitTimes)
		performWithDelay(self.diaoyuActionSkel,function()
			self.waitPanel:show()
			self.diaoyuActionSkel:play("dengdai_loop")
			performWithDelay(self,function()
				gGameApp:requestServer("/game/fishing/once/doing", function(tb)
					self.partner:setTouchEnabled(false)
					self.titleBack:hide()
					self.waitPanel:hide()
					self.diaoyuActionSkel:play("shougan2_loop")
					self.exitType = CLOSE_STATE.CLOSE
					itertools.invoke({self.btnTake, self.centerPanel, self.imgTip, self.timesPanel}, "show")
					self.fish:y(self.fishBg:height()/2) --鱼和鱼钩初始在中间
					self.fishhook:y(self.fishBg:height()/2)
					self.scoreBar:setPercent(100/3) --进度条初始在1/3
					self:angling(basicsUpVal, basicsDownVal, addUpVal, addDownVal)
					self:fishMove(moveLower, self.fishTab.deadTime)
					self:loosen()
					self:lineChange()
				end, tb.view.fish)
			end,wait)
		end,3)
	end)
end

function FishingView:angling(basicsUpVal, basicsDownVal, addUpVal, addDownVal)
	local time = 0
	local addUp = (basicsUpVal + basicsUpVal*addUpVal)/20
	local addDown = (basicsDownVal - basicsDownVal*addDownVal)/20
	local upVal = addUp --进度条涨值
	local downVal = addDown --进度条降值

	self:enableSchedule()
	self:schedule(function()
		local box = self.fishhook:getBoundingBox()
		local posx, posy = self.fish:xy()
		self.barVal = self.scoreBar:getPercent()

		-- 判断鱼是否在鱼钩内
		if cc.rectContainsPoint(box, cc.p(posx, posy)) then
			time = 0
			if self.skelState == SKEL_STATE.OUTSIDE then
				self.diaoyuActionSkel:play("shougan2_loop")
				self.skelState = SKEL_STATE.INSIDE
			end
			self.scoreBar:setPercent(self.barVal + upVal)
			if self.barVal >= 100 then
				self:finish(true)
			end
		else
			if self.skelState == SKEL_STATE.INSIDE then
				self.diaoyuActionSkel:play("shougan_loop")
				self.skelState = SKEL_STATE.OUTSIDE
			end
			self.scoreBar:setPercent(self.barVal - downVal)
			if self.barVal <= 0 then
				time = time + 0.05
				if time >= 1 then --当进度条到达底部，持续1秒后，钓鱼失败，鱼儿溜走
					self:finish()
				end
			end
		end
	end, 0.05, 0, 1)
end

-- 钓鱼开始鱼开始移动
function FishingView:fishMove(lower, deadTime)
	self:enableSchedule()
	local lowerRandom = lower --百分比减少鱼的上下走动范围
	local fishBgY = self.fishBg:height() --减去背景图多余位置
	local fishingPanelY = self.fishingPanel:height()
	local fishY = self.fish:height()/2
	local minY = 0 + fishY
	local maxY = fishBgY - fishY - 130
	local randmove = {self.fishTab.randMove[1], self.fishTab.randMove[2]}

	if self.idx == game.FISHING_GAME and self.fishTab.competitionRandMove[1] then
		randmove = {self.fishTab.competitionRandMove[1], self.fishTab.competitionRandMove[2]}
	end

	local time = 1 + 1			--每次移动计时时间
	local deadTimes = deadTime 	--鱼每次移动之后的等待计时时间
	local dead = 0				--参数为0时不停顿
	self:schedule(function()
		local percent = math.random(randmove[1], randmove[2])
		local ry1 = (fishBgY*(percent/100)) - ((fishBgY*(percent/100))*lowerRandom)
		local a = math.random(0, 1)
		if a == 1 then
			ry1 = -ry1
		end

		local ry2 = self.fish:y() + ry1

		-- 判断鱼是否在可移动的最大和最小位置
		if ry2 >= maxY then
			ry2 = maxY
		elseif ry2 <= minY then
			ry2 = minY
		end

		local ry3 = ry2
		-- 移动时
		if dead == 0 then
			ry3 = ry2
			time = time - 1
			if time <= 0 then
				dead = 1
				deadTimes = deadTime
			end
		end

		-- 等待时
		if dead == 1 then
			ry3 = self.fish:y()
			deadTimes = deadTimes - 1
			if deadTimes <= 0 then
				dead = 0
				time = 1 + 1
			end
		end

		transition.executeParallel(self.fish, true):moveTo(1, self.fish:x(), ry3)
	end, 1, 0, 2)
end

-- 按住收线按钮
function FishingView:onTake()
	self:enableSchedule():unSchedule(4)
	local fishBgY = self.fishBg:height()/2
	local fishhookY = self.fishhook:height()/2
	local fishingPanelY = self.fishBg:y() + (fishBgY - fishhookY - 40)

	local sp = 25 --鱼钩上升速度
	self:schedule(function()
		local y = self.fishhook:y() + sp

		-- 判断鱼钩是否到达可升高的最高位置
		if self.fishhook:y() >= fishingPanelY then
			y = fishingPanelY
		-- 判断鱼钩下一步是否超过可升高的最高位置
		elseif self.fishhook:y() + sp > fishingPanelY and self.fishhook:y() < fishingPanelY then
			y = (self.fishhook:y() + sp) - ((self.fishhook:y() + sp) - fishingPanelY)
		end

		transition.executeParallel(self.fishhook):moveTo(0.05, self.fishhook:x(), y, true)
	end, 0.05, 0, 3)
end

-- 松开收线按钮
function FishingView:loosen()
	self:enableSchedule():unSchedule(3)
	local fishBgY = self.fishBg:height()/2
	local fishhookY = self.fishhook:height()/2
	local fishingPanelY = self.fishBg:y() - (fishBgY - fishhookY - 40)

	local time = 0  -- 计时器
	local sp = -5	-- 鱼钩下降初始速度
	local sp1 = -25	-- 鱼钩下降最大速度
	self:schedule(function()
		-- 0.5s后鱼钩开始匀速加速到最大速度
		time = time + 0.05
		if time >= 0.6 then
			if sp > sp1 then
				sp = sp - 1.5
			end
		end
		local y = self.fishhook:y() + sp

		-- 判断鱼钩是否到达可下落的最小位置
		if self.fishhook:y() <= fishingPanelY then
			y = fishingPanelY
		-- 判断鱼钩下一步是否超过可下落的最小位置
		elseif self.fishhook:y() + sp < fishingPanelY and self.fishhook:y() > fishingPanelY then
			y = (self.fishhook:y() + sp) - ((self.fishhook:y() + sp) - fishingPanelY)
		end

		transition.executeParallel(self.fishhook):moveTo(0.05, self.fishhook:x(), y, true)
	end, 0.05, 0, 4)
end

-- 钓鱼线
function FishingView:lineChange()
	self:schedule(function()
		local fishBgY = self.fishBg:height()/2
		local hookY = self.fishhook:y()
		self.line:height((fishBgY - 120) + (fishBgY - hookY) < 67 and 67 or (fishBgY - 120) + (fishBgY - hookY))
	end, 0.01, 0, 5)
end

function FishingView:finish(result)
	self:enableSchedule():unScheduleAll()
	self.diaoyuActionSkel:play("daiji_loop")
	self.fishhook:height(220)
	if self.idx == game.FISHING_GAME then
		local isUnlock = dataEasy.isUnlock(gUnlockCsv.gameAutoFish)
		self.partner:setTouchEnabled(isUnlock)
		self:fishingGameTimer()
	else
		local isUnlock = dataEasy.isUnlock(gUnlockCsv.autoFish)
		self.partner:setTouchEnabled(isUnlock)
	end
	itertools.invoke({self.centerPanel, self.btnTake, self.imgTip}, "hide")
	itertools.invoke({self.btnThrow, self.timesPanel, self.btnRules, self.recordPanel, self.leftPanel, self.titleBack}, "show")

	local resultEnd = "fail"
	if result then
		resultEnd = "win"
	end
	local csvId = self.fishTab.csvId
	local fish = self.fishModel:read()
	local max = fish[csvId] and fish[csvId].length_max or 0
	local old = self.fishLevel:read()
	local point = gGameModel.fishing:read("point")
	local showOver = {false}
	gGameApp:requestServerCustom("/game/fishing/once/end")
		:params(csvId, resultEnd)
		:onResponse(function (tb)
			if resultEnd == "win" and self.idx == game.FISHING_GAME then
				local rankData = {}
				if tb.view then
					if tb.view.top3 then
						for i,v in ipairs(tb.view.top3) do
							table.insert(rankData, v)
						end
						self.ranksData:update(rankData)
					end
				end
			end
			showOver[1] = true
		end)
		:wait(showOver)
		:doit(function(tb)
			if result then
				-- 升级特效
				if self.fishLevel:read() > old then
					gGameUI:stackUI("city.adventure.fishing.upgrade", nil, nil, self:createHandler("fishSprite", tb.view, csvId, max, point))
				else
					self:fishSprite(tb.view, csvId, max, point)
				end
			else
				gGameUI:showTip(gLanguageCsv.fishLose)
			end
		end)
end

function FishingView:fishSprite(cfg, csvId, max, point)
	if cfg.award.carddbIDs then
		local data, isFull, isHaveTip = dataEasy.mergeRawDate(cfg.award)
		-- 获得精灵
		gGameUI:stackUI("common.gain_sprite", {
			cb = self:createHandler("fishResult", csvId, cfg.length, cfg.award, max, point),
		}, {full = true}, data[1])
	else
		self:fishResult(csvId, cfg.length, cfg.award, max, point)
	end
end

function FishingView:fishResult(id, length, award, max, point)
	gGameUI:stackUI("city.adventure.fishing.result", nil, {clickClose = true}, id, length, award, max, self.idx, point)
end

-- 等级
function FishingView:onBtnLv()
	gGameUI:stackUI("city.adventure.fishing.level")
end

-- 图鉴
function FishingView:onBtnHandbook()
	gGameUI:stackUI("city.adventure.fishing.book")
end

-- 商店
function FishingView:onBtnShop()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/fishing/shop/get", function(tb)
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.FISHING_SHOP)
		end)
	end
end

-- 钓鱼大赛排行榜
function FishingView:onBtnRank()
	gGameApp:requestServer("/game/cross/fishing/rank",function (tb)
		gGameUI:stackUI("city.adventure.fishing.rank", nil, nil, tb.view)
	end)
end

-- 渔具
function FishingView:onBtnTools()
	gGameUI:stackUI("city.adventure.fishing.bag", nil, nil, 1, self.idx)
end

-- 鱼饵
function FishingView:onBtnBait()
	gGameUI:stackUI("city.adventure.fishing.bag", nil, nil, 2, self.idx)
end

-- 鱼竿
function FishingView:onBtnRod()
	gGameUI:stackUI("city.adventure.fishing.bag", nil, nil, 1, self.idx)
end

-- 伙伴
function FishingView:onPartnerClick(data)
	local str = {
		"#C0x5B545B#"..gLanguageCsv.isAutoFishing,
		"#C0x999999#"..gLanguageCsv.autoFishCanLose
	}
	local isrich = true
	-- 钓鱼大赛期间特殊显示
	if data == "start" and self.onAutoBtn:read() == 0 and self.idx ~= game.FISHING_GAME then
		str = {
			gLanguageCsv.fishGameStartIsAutoFishing
		}
		isrich = false
	elseif data == "closed" and self.idx == game.FISHING_GAME then
		gGameUI:showTip(gLanguageCsv.theContestIsOverCantFishing)
		return
	end
	gGameUI:showDialog{
		strs = str,
		cb = function()
			self.onAutoBtn:set(1)
			self:autoFishing("click")
		end,
		isRich = isrich,
		fontSize = 40,
		btnType = 2,
		clearFast = true,
	}
end

function FishingView:autoFishing(typ)
	self.autoType = AUTO_STATE.BEGAN
	self.auto:show()
	self.btnThrow:hide()
	self.auto:get("txt"):text(gLanguageCsv.canBackToCity)
	local old = self.fishLevel:read()
	self:enableSchedule()

	if typ == "click" then
		self.partner:setTouchEnabled(false)
		gGameApp:requestServer("/game/fishing/auto/start")
	else
		gGameApp:requestServer("/game/fishing/main",function (tb)
			if self.idx == game.FISHING_GAME then
				local rankData = {}
				if tb.view then
					if tb.view.top3 then
						for i,v in ipairs(tb.view.top3) do
							table.insert(rankData, v)
						end
						self.ranksData:update(rankData)
					end
				end
			end
		end)
	end

	local deTime = 0
	idlereasy.when(self.autoStartTime, function(_, autoStartTime)
		local nowTimestamp = time.getTimestamp(time.getNowDate())
		local timer = gCommonConfigCsv.fishingAutoDuration + 1
		self.delta = timer - ((nowTimestamp - autoStartTime) % timer)
		local t = time.getCutDown(timer - ((nowTimestamp - autoStartTime) % timer))
		deTime = t.min * 60 + t.sec

		self:schedule(function()
			local now = time.getTimestamp(time.getNowDate())
			self.delta = self.delta - 1
			if self.delta < 0 then
				if self.nowTimes == 0 then
					self.txtRefreshTime:hide()
					self.refreshTime:hide()
				end
				self.delta = timer - ((now - autoStartTime) % timer)
			end
			self.deltaTime:set(self.delta)
		end, 1, 0, 7000)
	end)

	self.txtRefreshTime:text(gLanguageCsv.nextFishing)
	adapt.oneLinePos(self.txtRefreshTime, self.refreshTime, cc.p(0, 0), "left")

	local function refreshMain()
		local timer = gCommonConfigCsv.fishingAutoDuration + 1
		self:schedule(function()-- 需要刷新main接口才能得到鱼的新数据
			gGameApp:requestServer("/game/fishing/main",function (tb)
				if self.idx == game.FISHING_GAME then
					local rankData = {}
					if tb.view then
						if tb.view.top3 then
							for i,v in ipairs(tb.view.top3) do
								table.insert(rankData, v)
							end
							self.ranksData:update(rankData)
						end
					end
				end
			end)
		end, timer, 0, 6000)
	end

	if typ == "click" then
		refreshMain()
	else
		performWithDelay(self,function()
			refreshMain()
		end, deTime - 1)
	end

	idlereasy.any({self.autoStopped, self.autoAward, self.autoWinCounter, self.autoFailCounter}, function(_, autoStopped,autoAward,autoWinCounter,autoFailCounter)
		local autoAwardCfg = {}

		self.auto:get("btnOk"):visible(autoStopped == true)
		self.auto:get("btnStop"):visible(autoStopped == false)
		self.auto:get("tipView"):visible(autoStopped == false)
		self.txtRefreshTime:visible(autoStopped == false)
		self.refreshTime:visible(autoStopped == false)
		self.auto:get("tipOver"):visible((autoStopped == true and self.nowTimes == 0) or (autoStopped == true and self.baitCount and self.nowTimes > 0))
		self.auto:get("tipOver1"):visible(autoStopped == true and not self.baitCount and self.nowTimes > 0)
		self.autoFish:get("txt2"):text(autoWinCounter + autoFailCounter)
		self.autoFish:get("txt4"):text(autoWinCounter)
		self.autoFish:get("txt6"):text(autoFailCounter)
		adapt.oneLinePos(self.autoFish:get("txt1"), {self.autoFish:get("txt2"), self.autoFish:get("txt3"), self.autoFish:get("txt4"), self.autoFish:get("txt5"), self.autoFish:get("txt6"), self.autoFish:get("txt7")}, cc.p(5, 0), "left")

		if autoAward.fish then
			self.autoFishCfg:set(autoAward.fish)
		end
		if autoAward.type1 then
			for k,v in pairs(autoAward.type1) do
				table.insert(autoAwardCfg, {
					key = k,
					val = v,
				})
			end
		end
		if autoAward.type2 then
			for k,v in pairs(autoAward.type2) do
				table.insert(autoAwardCfg, {
					key = k,
					val = v,
				})
			end
		end
		if autoAward.cards then
			for k,v in pairs(autoAward.cards) do
				table.insert(autoAwardCfg, {
					key = "id",
					val = v.id,
				})
			end
		end
		self.autoAwardCfg:update(autoAwardCfg)
	end)

	local function click()
		self:enableSchedule():unSchedule(6000)
		self:enableSchedule():unSchedule(7000)
		self.autoType = AUTO_STATE.END
		self.auto:hide()
		self.btnThrow:show()
		self.autoFishCfg:set({})
		local isUnlock = dataEasy.isUnlock(gUnlockCsv.autoFish)
		self.partner:setTouchEnabled(isUnlock)
		if self.fishLevel:read() > old then
			gGameUI:stackUI("city.adventure.fishing.upgrade")
		end
	end

	bind.touch(self, self.auto:get("btnOk"), {methods = {ended = function()
		gGameApp:requestServer("/game/fishing/auto/end", click)
	end}})
	bind.touch(self, self.auto:get("btnStop"), {methods = {ended = function()
		gGameApp:requestServer("/game/fishing/auto/end", click)
	end}})
end

-- 显示规则文本
function FishingView:onShowRule()
	local rule = self:createHandler("getRuleContext")
	if self.idx == game.FISHING_GAME then
		rule = self:createHandler("getGameRuleContext")
	end
	gGameUI:stackUI("common.rule", nil, nil, rule, {width = 1800})
end

-- 钓鱼规则
function FishingView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.angling)
		end),
		c.noteText(93001, 94000),
	}
	return context
end

-- 钓鱼大赛规则
function FishingView:getGameRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.FishingCompetition)
		end),
		c.noteText(94001, 95000),
	}
	return context
end

-- 钓鱼大赛开始提示框
function FishingView:initActivityTip(data)
	if data == nil or data == "closed" then
		self.activityTip:hide()
		self.activityTip:removeChildByName("gojt")
		return
	end

	widget.addAnimationByKey(self.activityTip, "huodongtixing/huodongtixing.skel", "gojt", "effect_loop", 1)
		:alignCenter(self.activityTip:size())

	bind.touch(self, self.activityTip, {methods = {ended = function()
		gGameApp:requestServer("/game/fishing/main", function(tb)
			if self.isAuto:read() == true then
				gGameUI:showTip(gLanguageCsv.switchSenceNeedStopAutoFishing)
			else
				if data == "closed" then
					self.activityTip:hide()
					self.activityTip:removeChildByName("gojt")
					gGameUI:showDialog{
						strs = {
							"#C0x5B545B#"..gLanguageCsv.theContestIsOver
						},
						fontSize = 50,
						btnType = 1,
						clearFast = true,
					}
					return
				else
					gGameApp:requestServer("/game/cross/fishing/rank",function (tb)
						self:getParent().showTab:set(game.FISHING_GAME)
						ViewBase.onClose(self)
						gGameApp:requestServer("/game/fishing/prepare", nil, "scene", game.FISHING_GAME)
						gGameUI:stackUI("city.adventure.fishing.view", nil, {full = true}, game.FISHING_GAME, tb.view)
					end)
				end
			end
		end)
	end}})

	self.activityTip:show()
end

-- 钓鱼大赛倒计时
function FishingView:fishingGameTimer()
	-- 钓鱼大赛固定每天的23点刷新结束
	local timer = 23*3600
	local currTime = time.getNowDate()
	local currSec = currTime.hour * 3600 + currTime.min*60 + currTime.sec
	local delta = timer - currSec + 2
	self:enableSchedule()
	self:schedule(function()
		delta = delta - 1
		if delta <= 0 then
			self.timer:hide()
		end
		self.gameTimer:set(delta)
	end, 1, 0, 8000)
end

-- 精灵详情
function FishingView:onitemClick(list, node, idx, id)
	gGameUI:showItemDetail(node, {key = "card", num = id.val})
end

function FishingView:onClose()
	if self.exitType == CLOSE_STATE.SHOWTIP then
		gGameUI:showDialog{
			strs = {
				"#C0x5B545B#"..gLanguageCsv.stopFishingAndExit
			},
			cb = function()
				self:addCallbackOnExit(self.cb)
				ViewBase.onClose(self)
			end,
			isRich = true,
			fontSize = 50,
			btnType = 2,
			clearFast = true,
		}
	else
		self:addCallbackOnExit(self.cb)
		ViewBase.onClose(self)
	end
end

return FishingView