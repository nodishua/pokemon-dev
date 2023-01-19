--节日boss
local HARD_DEGREE = {
	S = 1,
	SS = 2,
	SSS = 3,
}
local LINE_NUM = 3
local ViewBase = cc.load("mvc").ViewBase
local ActivityBossView = class("ActivityBossView",ViewBase)

ActivityBossView.RESOURCE_FILENAME = "activity_boss.json"
ActivityBossView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["title"] = "title",
	["noBoss"] = "noBoss",
	["noBoss.noBossImg"] = "noBossImg",
	["btnRule"] = {
		varname = "rule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRule")},
		},
	},
	-------------------------------leftPanel---------------------------------
	["leftPanel"] = "leftPanel",
	["leftPanel.myChallengeTimesText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(58,31,47,255),  size = 3}}
		},
	},
	["leftPanel.item.ChallengeTimesText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(96,86,94,255),  size = 3}}
		},
	},
	["leftPanel.item.timeText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(96,86,94,255),  size = 3}}
		},
	},
	["leftPanel.myChallengeTimesNum"] = "myChallengeTimesNum",
	["leftPanel.item"] = "bossItem",
	["leftPanel.item.pos"] = "pos",
	["leftPanel.item.challenged"] = "challenged",
	["leftPanel.item.discover"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(96,86,94,255),  size = 3}}
		},
	},
	["leftPanel.item.discoverName"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(96,86,94,255),  size = 3}}
		},
	},
	["leftPanel.item.myBoss"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(241,62,86,255),  size = 3}}
		},
	},
	["leftPanel.bossList"] = {
		varname = "bossList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				-- padding = 10,
				data = bindHelper.self("bossDatas"),
				item = bindHelper.self("bossItem"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list:setRenderHint(0)
				end,
				onItem = function(list, node, k, v)
					node:get("bgK"):visible(v.isSel == true)
					node:get("new"):visible(false)
					node:get("myBoss"):visible(v.myBoss)
					node:get("challenged"):visible(v.myBoss == true and v.ownerWin == true)
					node:get("discoverName"):text(getServerArea(v.gameKey).." "..v.discoverName)
					node:get("ChallengeTimesNum"):text(v.remainTime.."/"..v.maxTimes)
					node:get("pos"):get("img"):xy(node:get("pos"):get("img"):x() + v.posX,node:get("pos"):get("img"):y() + v.posY)
					node:get("pos"):get("img"):scale(v.scale)
					adapt.oneLinePos(node:get("discoverName"), node:get("discover"), cc.p(5,0))
					if v.hardDegree == HARD_DEGREE.S then
						node:get("degreeImg"):texture("activity/activity_boss/icon_wsj_s.png")
					elseif v.hardDegree == HARD_DEGREE.SS then
						node:get("degreeImg"):texture("activity/activity_boss/icon_wsj_ss.png")
					elseif v.hardDegree == HARD_DEGREE.SSS then
						node:get("degreeImg"):texture("activity/activity_boss/icon_wsj_sss.png")
					end
					node:get("degreeImg"):x(node:get("degreeImg"):x()+v.hardDegree*10)
					--剩余时间
					bind.extend(list, node:get("timeNum"), {
						class = 'cutdown_label',
						props = {
							time = v.endTime - time.getTime(),
							endFunc = function()
							end,
						}
					})
					adapt.oneLinePos(node:get("ChallengeTimesNum"), node:get("ChallengeTimesText"), nil,"right")
					adapt.oneLinePos(node:get("timeNum"), node:get("timeText"), nil,"right")

					-- 立绘
					local unitId = csv.scene_conf[v.gateId]
					local unitCsv = csv.unit[unitId.boss[1].unitId]
					node:get("pos"):get("img"):texture(unitCsv.cardShow)
					bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, k, v)
					}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBossItemClick"),
			},
		},
	},
	["leftPanel.btnRefresh"] = {
		varname = "btnRefresh",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRefresh")},
		},
	},
	-------------------------------centerPanel--------------------------------
	["centerPanel"] = "centerPanel",
	["centerPanel.spine"] = "cardSpine",

	["centerPanel.bossAppearText"] = "bossAppearText",
	["centerPanel.escapeTip"] = "escapeTip",
	["centerPanel.escapeTime"] = "escapeTime",
	["centerPanel.escapeTip2"] = "escapeTip2",
	["centerPanel.discover"] = "discover",
	--------------------------------rightPanel--------------------------------
	["rightPanel"] = "rightPanel",

	["rightPanel.effect.textList"] = "effectText",
	["rightPanel.hasChallenged"] = "hasChallenged",
	["rightPanel.effect.titleBg.titleText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(54,0,0,255),  size = 3}}
		},
	},
	["rightPanel.enemy.titleText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(54,0,0,255),  size = 3}}
		},
	},
	["rightPanel.enemy.item"] = "enemyItem",
	["rightPanel.enemy.subList"] = "subList",
	["rightPanel.enemy.list"] = {
		varname = "enemyList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("enemyData"),
				topPadding = 20,
				columnSize = LINE_NUM,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("enemyItem"),
				-- preloadCenter = 5,
				onCell = function(list, node, k, v)
					--精灵头像
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.id,
							advance = v.advance,
							rarity = v.rarity,
							showAttribute = true,
							levelProps = {
								data = v.level,
							},
							isBoss = v.isBoss,
							onNode = function(panel)
								node:scale(0.9)
							end,
						}
					})
				end,
			}
		},
	},
	["rightPanel.drop.titleText"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(54,0,0,255),  size = 3}}
		},
	},
	["rightPanel.drop.item"] = "dropItem",
	["rightPanel.drop.list"] = {
		varname = "dropList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				-- padding = 10,
				data = bindHelper.self("dropDatas"),
				item = bindHelper.self("dropItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {key = v.key, num = v.num},
							onNode = function(panel)
								panel:scale(0.7)
							end,
						},
					})
				end,
			}
		},
	},
	["rightPanel.btnPlayer"] = {
		varname = "btnPlayer",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClearance")},
		},
	},
	["rightPanel.timesNum"] = "timesNum",
	["rightPanel.btnChallenge"]= {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChallenge")},
		},
	},
	["rightPanel.btnChallenge.text"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
}
function ActivityBossView:onCreate(activityId,data)
	self.data = self.data or data
	self.activityId = activityId
	self:initModel()
	-- 顶部UI
	self.topView = gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.huodongBoss, subTitle = "ACTIVITYBOSS"})
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local huodongID = yyCfg.huodongID
	self.huodongID = huodongID
	local yyData = self.yyhuodongs[activityId] or {}
	self.yyData = yyData
	self.yyCfg = yyCfg
	self.selIdx = idler.new(1)
	self.bossDatas = idlers.newWithMap({})
	self.dropDatas = idlers.newWithMap({})
	self.enemyData = idlers.newWithMap({})
	self.minTime = idler.new(0)
	self:initBossList(self.data)
	self.selIdx:addListener(function(val, oldval)
		if self.bossDatas:atproxy(oldval) then
			self.bossDatas:atproxy(oldval).isSel = false
		end
		if self.bossDatas:atproxy(val) then
			self.bossDatas:atproxy(val).isSel = true
			self:initRightPanel(val)
		end
	end)
	if self.count ~= 0 then
		local curIdx = math.min(self.count, self.selIdx:read())
		self.selIdx:set(curIdx, true)
	end

	-- --定时器
	self.minTime:addListener(function(val, oldval)
		self:enableSchedule():unSchedule(100)
		local countdown = self.minTime:read() - time.getTime()
		self:schedule(function()
			countdown = countdown - 1
			if countdown <= 0 then
				self:onRefresh()
				return false
			end
		end, 1, 1, 100)
	end)
	-- 战斗返回先显示上一次的值，即时请求刷新
	if self.challenge == true then
		self.challenge = false
		self:onRefresh(function()
			local idx = self.selIdx:read()
			if self.bossDatas:atproxy(idx) then
				self:initRightPanel(self.selIdx:read())
			end
		end)
	end
end

function ActivityBossView:initModel()
	self.yyhuodongs = gGameModel.role:read("yyhuodongs")
	self.id = gGameModel.role:read("id")
end

function ActivityBossView:initBossList(data)
	self.data = data
	self.count = #data.view.huodongboss
	self.noBoss:visible(true)
	self.leftPanel:visible(false)
	self.centerPanel:visible(false)
	self.rightPanel:visible(false)
	if #data.view.huodongboss > 0 then
		--BossList信息
		local bossDatas = {}
		for _, huodongboss in ipairs(data.view.huodongboss) do
			local bossCfg = csv.yunying.huodongboss[huodongboss.gate_id]
			local remainTime = 0
			local haveWinRole
			local winRoles = {}
			if not huodongboss.win_roles then
				remainTime = bossCfg.times
				haveWinRole = false
			else
				haveWinRole = true
				remainTime = bossCfg.times - #huodongboss.win_roles
				winRoles = huodongboss.win_roles
			end
			if huodongboss.owner.role_id == self.id and huodongboss.owner_win then
				table.insert(winRoles,{
					name = gGameModel.role:read("name"),
					level = gGameModel.role:read("level"),
					frame = gGameModel.role:read("frame"),
					logo = gGameModel.role:read("logo"),
					fight_point = gGameModel.role:read("top6_fighting_point"),
					game_key= gGameApp.serverInfo.key,
				})
			end
			local hasChallenge = false
			if #huodongboss.win_roles > 0 then
				for _, v in ipairs(huodongboss.win_roles) do
					if v.role_id == self.id then
						hasChallenge = true
					end
				end
			end
			if remainTime == 0 and huodongboss.owner.role_id ~= self.id then
				hasChallenge = true
			end
			--敌方阵容
			local function getCfgData(cfg, isBoss)
				local data = {}
				for _, v in ipairs(cfg) do
					local unitCfg = csv.unit[v.unitId]
					table.insert(data, {
						id = v.unitId,
						level = v.level,
						advance = v.advance,
						rarity = unitCfg.rarity,
						isBoss = isBoss,
					})
				end
				table.sort(data, function(a,b)
					return a.advance > b.advance
				end )
				return data
			end
			local unitId = csv.scene_conf[huodongboss.gate_id]
			local bossData = getCfgData(unitId.boss, true)
			local monsterDatas = getCfgData(unitId.monsters, false)
			local enemyData = arraytools.merge({bossData, monsterDatas})
			local new = time.getTime() - huodongboss.start_time < gCommonConfigCsv.huodongbossNewTimes * 60
			if hasChallenge == false then
				table.insert(bossDatas,{
					gateId = huodongboss.gate_id,
					uId = huodongboss.uid,
					startTime = huodongboss.start_time,
					endTime = huodongboss.start_time + bossCfg.timeLimit*60,
					maxTimes = bossCfg.times,
					remainTime = remainTime,
					hardDegree = bossCfg.hardDegree,
					posX = bossCfg.posX,
					posY = bossCfg.posY,
					scale = bossCfg.scale,
					myBoss = huodongboss.owner.role_id == self.id,
					discoverName = huodongboss.owner.name,
					haveWinRole = haveWinRole,
					winRoles = winRoles,
					ownerWin = huodongboss.owner_win,
					hasChallenge = hasChallenge,
					enemyData = enemyData,
					new = new,
					posX = bossCfg.posX,
					posY = bossCfg.posY,
					scale = bossCfg.scale,
					gameKey = huodongboss.owner.game_key
				})
			end
		end
		if #bossDatas <= 0 then
			self.bossDatas:update(bossDatas)
			return
		end
		self.noBoss:visible(false)
		self.leftPanel:visible(true)
		self.centerPanel:visible(true)
		self.rightPanel:visible(true)
		local endTime = bossDatas[1].endTime
		for i = 1,#bossDatas do
			endTime = math.min(endTime, bossDatas[i].endTime)
		end
		self.minTime:set(endTime)
		--排序逻辑
		table.sort(bossDatas, function(a, b)
			if a.myBoss ~= b.myBoss then
				return a.myBoss == true
			end
			if a.startTime ~= b.startTime then
				return a.startTime < b.startTime
			end
			if a.remainTime ~= b.remainTime then
				return a.remainTime > b.remainTime
			end
			return a.gateId > b.gateId
		end)
		dataEasy.tryCallFunc(self.bossList, "updatePreloadCenterIndex")
		self.bossDatas:update(bossDatas)
		local curIdx = math.min(self.count, self.selIdx:read())
		self.selIdx:set(curIdx, true)

		local myChallengeTimes = gGameModel.daily_record:read("huodong_boss_times")
		local dailyChallengeLimit =  csv.yunying.huodongboss_config[data.view.csv_id].dailyChallengeLimit
		self.myChallengeTimesNum:text(dailyChallengeLimit-myChallengeTimes.."/"..dailyChallengeLimit)
	end
end

function ActivityBossView:onRefresh(cb)
	gGameApp:requestServer("/game/yy/huodongboss/list", function(tb)
		self:initBossList(tb)
		if type(cb) == "function" then
			cb()
		end
	end,self.activityId,gCommonConfigCsv.huodongbossMaxNumber)
end

function ActivityBossView:onRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function ActivityBossView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.rules)
		end),
		c.noteText(151),
		c.noteText(107001, 107007),
	}
	return context
end

function ActivityBossView:onClearance()
	local data = {}
	if self.bossDatas:atproxy(self.selIdx:read()).haveWinRole then
		data = self.bossDatas:atproxy(self.selIdx:read()).winRoles
	end
	gGameUI:stackUI("city.activity.activity_boss.clearance", nil, nil, table.shallowcopy(data))
end

function ActivityBossView:onChallenge()
	local myChallengeTimes = gGameModel.daily_record:read("huodong_boss_times")
	local dailyChallengeLimit = csv.yunying.huodongboss_config[self.data.view.csv_id].dailyChallengeLimit
	local selIdx = self.selIdx:read()
	local bossData = self.bossDatas:atproxy(selIdx)
	if bossData.myBoss and bossData.ownerWin then
		gGameUI:showTip(gLanguageCsv.huoDongBossChallenged)
		return
	end
	if dailyChallengeLimit-myChallengeTimes == 0 and bossData.myBoss == false then
		gGameUI:showTip(gLanguageCsv.bossDailyChallengeLimit)
		return
	end
	local uId = bossData.uId
	self.challenge = true
	local fightCb = function(view, battleCards)
		gGameApp:requestServer("/game/yy/huodongboss/list", function(tb)
			self:initBossList(tb)
			for _, huodongboss in self.bossDatas:ipairs() do
				if uId == huodongboss:read().uId then
					local data = battleCards:read()
					local activityId = self.activityId
					battleEntrance.battleRequest("/game/yy/huodongboss/battle/start", data, uId, activityId)
						:onStartOK(function(data)
							data.activityID = activityId
							data.idx = uId
							if view then
								view:onClose(false)
								view = nil
							end
						end)
						:show()
					return
				end
			end
			view:onClose(false)
			gGameUI:showTip(gLanguageCsv.huoDongBossNotExist)
		end, self.activityId, gCommonConfigCsv.huodongbossMaxNumber)
	end
	gGameUI:stackUI("city.activity.activity_boss.embattle", nil, {full = true}, {
	-- gGameUI:stackUI("city.card.embattle.base", nil, {full = true}, {
		from = game.EMBATTLE_FROM_TABLE.huodongBoss,
		-- fromId = self.csvId,
		fightCb = fightCb,
	})
end

function ActivityBossView:initRightPanel(val)
	--BossSpine
	local unitId = csv.scene_conf[self.bossDatas:atproxy(val).gateId]
	local unitCfg = csv.unit[unitId.boss[1].unitId]
	self.bossAppearText:text(unitId.sceneName..gLanguageCsv.huodongBossAppear)
	beauty.textScroll({
		list = self.effectText, 
		strs = {str = "#C0xFFFCED#" .. unitId.desc, verticalSpace = 5} ,
		isRich = true,
		fontSize = 35,
	})

	if matchLanguage({"kr" ,"en"}) then
		self.rightPanel:get("effect.titleBg"):size(250,60)
		self.rightPanel:get("enemy.titleBg"):size(250,60)
		self.rightPanel:get("drop.titleBg"):size(250,60)
	end

	local size = self.cardSpine:size()
	self.cardSpine:removeAllChildren()
	local cardSprite = widget.addAnimation(self.cardSpine, unitCfg.unitRes, "standby_loop", 5)
		:xy(size.width/2, 100)
		:scale(unitCfg.scaleU*3)
	cardSprite:setSkin(unitCfg.skin)

	local enemyData = {}
	for _, v in ipairs(self.bossDatas:atproxy(val).enemyData) do
		table.insert(enemyData,{
			id = v.id,
			level = v.level,
			advance = v.advance,
			rarity = v.rarity,
		})
	end
	self.enemyData:update(enemyData)
	local dropDatas = {}
	for key,num in orderCsvPairs(unitId.dropIds) do
		table.insert(dropDatas,{
			key = key,
			num = num,
		})
	end
	self.dropDatas:update(dropDatas)
	self.discover:text(getServerArea(self.bossDatas:atproxy(val).gameKey).." "..self.bossDatas:atproxy(val).discoverName.." "..gLanguageCsv.huodongBossDiscover)
	--逃跑剩余时间
	local lastTime = self.bossDatas:atproxy(val).endTime
	bind.extend(self, self.escapeTime, {
		class = 'cutdown_label',
		props = {
			time =  lastTime - time.getTime(),
			callFunc = function()
				adapt.oneLinePos(self.escapeTip,{self.escapeTime,self.escapeTip2},{cc.p(5,0),cc.p(5,0)})
			end,
		}
	})
	if self.bossDatas:atproxy(val).myBoss and self.bossDatas:atproxy(val).ownerWin then
		self.hasChallenged:visible(true)
	else
		self.hasChallenged:visible(false)
	end
	--挑战次数
	self.timesNum:text(self.bossDatas:atproxy(val).remainTime.."/"..self.bossDatas:atproxy(val).maxTimes)
end

function ActivityBossView:onBossItemClick(list, k, v)
	self.selIdx:set(k)
end

return ActivityBossView