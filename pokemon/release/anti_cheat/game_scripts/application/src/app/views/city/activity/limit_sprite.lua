-- @date: 2019-10-30 17:15:34
-- @desc:限时神兽

local LIST_TYPE = {
	RANK = 1,
	AWARD = 2,
}

local BAGMAXLEFTTIMES = {
	[1] = 0,
	[10] = 9,
}

local function setRankIcon(rankItem, rank, rankEnd)
	if rank <= 3 and not (rankEnd and rankEnd ~= rank) then
		rankItem:get("text"):hide()
		rankItem:get("img"):texture(ui.RANK_ICON[rank])
	else
		rankItem:get("img"):hide()
		if not rankEnd or rank == rankEnd then
			rankItem:get("text"):text(rank)
		else
			rankItem:get("text"):hide()
			rankItem:get("text1"):text(rank.."~"..rankEnd):show()
			-- rankItem:get("text2"):text(rankEnd):show()
		end
	end
end

local ActivityLimitSpriteView = class("ActivityLimitSpriteView", Dialog)
ActivityLimitSpriteView.RESOURCE_FILENAME = "activity_limit_sprite.json"
ActivityLimitSpriteView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["leftPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowRule")}
		},
	},
	["leftPanel.btnRight"] = {
		varname = "btnRight",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRightClick")}
		},
	},
	["leftPanel.btnLeft"] = {
		varname = "btnLeft",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLeftClick")}
		},
	},
	["leftPanel.btnHandBook"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onHandBookClick")}
		},
	},
	["leftPanel.drawOnePanel.btn"] = {
		binds = {
			{
					event = "touch",
					methods = {ended = bindHelper.self("onDrawOneClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "limitSpritesHasFreeDrawCard",
					listenData = {
						activityId = bindHelper.self("activityId"),
					},
					onNode = function(node)
						node:xy(459, 192)
					end,
				}
			}
		}
	},
	["leftPanel.drawOnePanel.btn.textFree"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isFree")
		}
	},
	["leftPanel.drawOnePanel.btn.costInfo"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isFree"),
			method = function(val)
				return not val
			end,
		}
	},
	["leftPanel.drawOnePanel.btn.costInfo.textNote"] = "costTextNote1",
	["leftPanel.drawOnePanel.btn.costInfo.textCost"] = "costOne",
	["leftPanel.drawOnePanel.btn.costInfo.img"] = "imgOne",
	["leftPanel.drawOnePanel.btn.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.BLUE}},
		}
	},
	["leftPanel.drawTenPanel.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDrawTenClick")}
		}
	},
	["leftPanel.drawTenPanel.textBg"] = "tenTextBg",
	["leftPanel.drawTenPanel.textBg.text"] = "tenText",
	["leftPanel.drawTenPanel.btn.costInfo.textNote"] = "costTextNote2",
	["leftPanel.drawTenPanel.btn.costInfo.textCost"] = "costTen",
	["leftPanel.drawTenPanel.btn.costInfo.img"] = "imgTen",
	["leftPanel.drawTenPanel.btn.textNote"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
			}
		}
	},
	["leftPanel.spritePanel"] = "spritePanel",
	["rightPanel.btnAward"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowAwardList")}
		},
	},
	["rightPanel.btnRefresh"] = {
		varname = "btnRefresh",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRankClick")}
		}
	},
	["rightPanel.timeTextNote"] = {
		varname = "timeTextNote",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["rightPanel.timeText"] = {
		varname = "timeText",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["rightPanel.btnRank"] = {
		varname = "btnRank",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRankClick")}
		}
	},
	["rightPanel.btnScore"] = {
		varname = "btnScore",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnAwardClick")}
		}
	},
	["rightPanel.myrank"] = "myrank",
	["rightPanel.rankItem"] = "rankItem",
	["rightPanel.rankList"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankData"),
				item = bindHelper.self("rankItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, rank, v)
					local children = node:multiget("rank", "score", "logo", "lv", "level", "name")
					local scorePath = string.format("activity/limit_sprite/rank_bg_%s.png", rank > 3 and 4 or rank)
					setRankIcon(children.rank, rank)
					children.score:texture(scorePath)
					children.score:get("text"):text(string.format(gLanguageCsv.limitBoxFmt, v.box_point))
					local role = v.role
					children.level:text(role.level)
					-- children.name:text(role.name .. role.name)
					adapt.setTextScaleWithWidth(children.name, role.name, 340)

					local clickFunc = function(event)
						local pos = cc.p(event.x - 200, event.y - 50)
						gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, {role = role})
					end

					if role.id == gGameModel.role:read("id") then
						clickFunc = nil
					end

					bind.extend(list, children.logo, {
						class = "role_logo",
						props = {
							logoId = role.logo,
							frameId = role.frame,
							level = false,
							vip = false,
							onNodeClick = clickFunc,
						},
					})
					adapt.oneLinePos(children.logo, {children.lv, children.level, children.name}, {cc.p(26, 0), cc.p(5, 0), cc.p(38, 0)})
				end,
			},
		}
	},
	["rightPanel.scoreItem"] = "scoreItem",
	["rightPanel.awardList"] = {
		varname = "awardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("awardData"),
				item = bindHelper.self("scoreItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local rank = v.rankStart + 1
					local children = node:multiget("rank", "score", "list")
					setRankIcon(children.rank, rank, v.rankEnd)

					local scorePath = string.format("activity/limit_sprite/score_bg_%s.png", rank > 3 and 4 or rank)
					children.score:texture(scorePath)
					children.score:get("text"):text(v.point)
					children.list:setGravity(ccui.ListViewGravity.centerVertical)
					local scale = csvSize(v.award) > 4 and 0.55 or 0.6
					uiEasy.createItemsToList(list, children.list, v.award, {scale = scale})
				end,
			},
		}
	},
	["rightPanel.textBg"] = "textTip",
	["bottomPanel.bar"] = "scoreBar",
	["bottomPanel.item"] = "boxItem",
	["bottomPanel.list"] = {
		varname = "boxList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("boxData"),
				item = bindHelper.self("boxItem"),
				onItem = function(list, node, k, v)
					local state = v.state-- 1 可领 0 已领 nil 不可领取
					local strOpen = "activity/limit_sprite/box_%s_open.png"
					local strNormal = "activity/limit_sprite/box_%s.png"
					local effectName = "spine"
					local resPath = string.format(state == 0 and strOpen or strNormal, v.iconId)
					local img = node:get("boxImg")
					img:texture(resPath)
					uiEasy.addVibrateToNode(list, img, state == 1, "imgBox"..k)
					if state == 1 then
						local effect = widget.addAnimationByKey(node, "effect/jiedianjiangli.skel", effectName, "effect_loop", 3)
							:scale(0.5)
							:xy(node:size().width / 2, node:size().height / 2)

						bind.extend(list, node:get("redArea"), {
							class = "red_hint",
							props = {
								specialTag = "boxRedHint"..time.getTime(),
								state = state == 1,
								onNode = function(node)
									node:xy(180, 230)
								end,
							}
						})
					else
						node:removeChildByName(effectName)
						node:get("redArea"):removeAllChildren()
					end
					node:get("textBg.text"):text(string.format(gLanguageCsv.limitBoxFmt, v.point))
					bind.touch(list, img, {methods = {ended = functools.partial(list.clickCell, v.id, state, v.award, v.point)}})

				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBoxClick"),
			},
		}
	},
	["aniLayer"] = "aniLayer",
}
function ActivityLimitSpriteView:onCreate(activityId, data, closeCb)
	self.closeCb = closeCb
	self.listPosX, self.listPosY = self.awardList:xy()
	self.listSize = self.awardList:size()
	bind.click(self, self.aniLayer, {method = functools.partial(self.onCardSprClick, self)})
	self.aniLayer:hide()

	self.activityId = idler.new(activityId)											-- 活动ID号
	self:resetTimeLabel()
	self:initModel()
	self:initData(data)

	self:initAwardData()
	self:initBoxInfo()
	self:initSelfInfo()


	Dialog.onCreate(self, {blackType = 1})
end

function ActivityLimitSpriteView:initData(data)
	self:resetRankInfo(data.rank)
end

function ActivityLimitSpriteView:initModel()
	self.cardDatas = gGameModel.role:getIdler("cards")						-- 卡牌
	self.cardCapacity = gGameModel.role:getIdler("card_capacity")			-- 背包容量
	self.rmb = gGameModel.role:getIdler("rmb")								-- 钻石数量
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")

	local dailyRecord = gGameModel.daily_record
	self.diamondFreeCount = dailyRecord:getIdler("limit_box_free_counter")	-- 钻石免费抽卡总次数(每日)

	self.isFree = idler.new(false)											-- 单抽是否免费
	self.curListType = idler.new(LIST_TYPE.RANK)							-- 当前排行榜显示的信息内容
	self.rankData = idlertable.new({})										-- 排名信息
	self.awardData = {}														-- 排名奖励信息(静态)
	self.spriteId = idler.new(0)											-- 目标精灵的ID
	self.curDevelopId = idler.new(0)										-- 当前所选择的精灵的阶段
	self.boxData = idlertable.new({})										-- 下方宝箱栏信息
	self.sprState = idler.new(0)											-- 精灵动画的显示状态 0-初始,1-动画中
	self.checkCardCapacity = idler.new(0)									-- 是否检验背包已满
	idlereasy.when(self.activityId, function(_, activityId)
		local csvCfg = csv.yunying.yyhuodong[activityId]
		local paramMap = csvCfg.paramMap
		local one = paramMap.RMB1 or 100
		local ten = paramMap.RMB10 or one * 10
		local rmb = self.rmb:read()
		self.checkCardCapacity:set(paramMap.CheckCardCapacity)
		self.cfg = csvCfg
		self.oneCost = one
		self.costOne:text(one)
		adapt.oneLinePos(self.costTextNote1, {self.costOne, self.imgOne}, cc.p(10,0))

		self.tenCost = ten
		self.costTen:text(ten)
		adapt.oneLinePos(self.costTextNote2, {self.costTen, self.imgTen}, cc.p(10,0))

		self.spriteId:set(csvCfg.clientParam.cardId)
		self.btnRefresh:show()

		local tipHight = self.textTip:size().height
		local hasTip = paramMap.Qualify ~= 0
		if hasTip then
			local date = self.cfg.beginDate
			local d = time.getDate(game.SERVER_OPENTIME)
			d.hour = 0
			d.min = 0
			d.sec = 0
			local delta = time.getNumTimestamp(date) - time.getTimestamp(d)
			local oneday = 24 * 60 * 60
			local serverOpendDays = math.floor(delta / oneday)
			-- 活动开始的开服天数大于配置时间才有约束
			if serverOpendDays > paramMap.QualifyServerOpenDays then
				local cfg = nil
				for _, v in orderCsvPairs(csv.yunying.limitboxqualify) do
					if v.serverOpenDays > serverOpendDays then
						break
					end
					cfg = v
				end
				if cfg and (cfg.fightPointLimit > 0 or cfg.vipLimit > 0) then
					self.textTip:show()
					local qualifyTime = paramMap.QualifyTime
					local day = math.floor(qualifyTime/(24 * 60)) + 1
					local beginHour, beginMin = time.getHourAndMin(csvCfg.beginTime, true)
					local hour = math.floor((qualifyTime + beginHour*60 + beginMin)%(24 * 60)/60)
					local min = qualifyTime%60
					self.richText = rich.createWithWidth(string.format(gLanguageCsv.limitTip, day, string.format("%d:%d", hour, min), cfg.vipLimit, mathEasy.getShortNumber(cfg.fightPointLimit, 1)), 31, nil, 850)
					self.richText:addTo(self.textTip)
						:anchorPoint(0, 0.5)
						:xy(10, self.textTip:size().height / 2)
					self.awardList:xy(self.listPosX, self.listPosY - tipHight)
					self.awardList:size(self.listSize.width, self.listSize.height + tipHight)
					self.rankList:xy(self.listPosX, self.listPosY)
					self.rankList:size(self.listSize.width, self.listSize.height)
					self.myrank:y(self.listPosY)
				else
					hasTip = false
				end
			end
		end

		if not hasTip then
			self.awardList:xy(self.listPosX, self.listPosY - tipHight)
			self.awardList:size(self.listSize.width, self.listSize.height + tipHight)
			self.textTip:hide()
		end
	end)
	idlereasy.any({self.diamondFreeCount, self.rmb, self.activityId}, function(_, diamondFreeCount, rmb, activityId)
		self.isFree:set(self.getHuodongEndTime > time.getTime() and diamondFreeCount < 1)

		if not (self.oneCost and self.tenCost) then return end
		text.addEffect(self.costOne, {color = rmb < self.oneCost and ui.COLORS.NORMAL.RED or cc.c4b(255, 230, 97, 255)})		-- 不足则显示红色
		text.addEffect(self.costTen, {color = rmb < self.tenCost and ui.COLORS.NORMAL.RED or cc.c4b(255, 230, 97, 255)})		-- 不足则显示红色
	end)

	local function setBtn(btn, isCur, list)
		local path = isCur and "activity/limit_sprite/btn_1.png" or "activity/limit_sprite/btn_2.png"
		local color = isCur and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED
		btn:setTouchEnabled(not isCur)
		btn:texture(path)
		text.addEffect(btn:get("text"), {color = color})
		list:visible(isCur)
	end

	idlereasy.when(self.curListType, function(_, curType)
		setBtn(self.btnRank, curType == LIST_TYPE.RANK, self.rankList)
		setBtn(self.btnScore, curType == LIST_TYPE.AWARD, self.awardList)
		self.myrank:visible(curType == LIST_TYPE.RANK)

		local size = curType == LIST_TYPE.RANK and cc.size(664, 51) or cc.size(821, 51)
		local pos = curType == LIST_TYPE.RANK and cc.p(512, 132) or cc.p(440, 132)
		self.textTip:size(size)
		self.textTip:xy(pos)
		if self.richText then
			local x = curType == LIST_TYPE.RANK and 10 or 90
			self.richText:x(x)
		end
		self.btnRefresh:visible(curType == LIST_TYPE.RANK)
	end)

	idlereasy.when(self.spriteId, function(_, cardId)
		local cardCsv = csv.cards[cardId]
		local unitCsv = csv.unit[cardCsv.unitID]
		local markId = cardCsv.cardMarkID
		self.markTb = {}
		local curId = 1
		for developId, data in pairs(gCardsCsv[markId]) do
			local cParam = self.cfg.clientParam
			for branch, cfg in pairs(data) do
				table.insert(self.markTb, cfg)
				if cfg.id == cardId then
					curId = #self.markTb
					local str = string.format(gLanguageCsv.limitTenText, cfg.name)
					local cParam = self.cfg.clientParam
					if cParam and cParam.key then
						local key = cParam.key
						str = gLanguageCsv[key]
						if string.find(str, "%ps") then
							str = string.format(str, cfg.name)
						end
						self.tenTextBg:show()
						self.tenText:text(str)
						local size1 = self.tenText:size()
						local size2 = self.tenTextBg:size()
						local dt = 40
						self.tenTextBg:size(cc.size(size1.width + dt, size2.height))
						self.tenText:x(size1.width / 2 + dt / 2)
					else
						self.tenTextBg:hide()
					end
				end
				--限时神兽双重形态特殊处理，如果有更多的形态需要做特殊处理
				if cParam.unitId then
					table.insert(self.markTb, {innateSkillID = csv.unit[cParam.unitId].skillList[3], unitID = cParam.unitId, id = cardId})
				end
			end
		end
		self.curDevelopId:set(curId)
	end)

	idlereasy.when(self.curDevelopId, function(_, curId)
		local markTb = self.markTb
		local cardCsv = markTb[curId]
		local skillCsv = csv.skill[cardCsv.innateSkillID]
		local skillName = skillCsv.spineAction
		local unitCsv = csv.unit[cardCsv.unitID]
		local children = self.spritePanel:multiget("rarity", "name", "nature1", "nature2", "sprite")
		children.name:text(cardCsv.name)
		children.rarity:texture(ui.RARITY_ICON[unitCsv.rarity])
		children.nature1:texture(ui.ATTR_ICON[unitCsv.natureType])
		children.nature2:visible(unitCsv.natureType2 and true or false)
		if unitCsv.natureType2 then
			children.nature2:texture(ui.ATTR_ICON[unitCsv.natureType2])
		end
		children.sprite:removeAllChildren()
		local spr = widget.addAnimation(children.sprite, unitCsv.unitRes, battle.SpriteActionTable.standby, 100)
			:scale(unitCsv.scale * 1.3)
			:x(children.sprite:size().width / 2)
		spr:setSkin(unitCsv.skin)
		adapt.oneLineCenterPos(cc.p(620,980), {children.rarity, children.name, children.nature1, children.nature2}, cc.p(30, 0))

		local len = table.length(markTb)
		self.btnLeft:visible(curId > 1)
		self.btnRight:visible(curId < len)
		if curId > 1 then
			self.btnLeft:get("text1"):text(string.format(gLanguageCsv.limitSpriteBtnText, markTb[curId - 1].develop))
		end
		if curId < len then
			self.btnRight:get("text1"):text(string.format(gLanguageCsv.limitSpriteBtnText, curId + 1))
		end
		self.btnLeft:get("text2"):text(markTb[math.max(curId - 1, 1)].name)
		self.btnRight:get("text2"):text(markTb[math.min(curId + 1, len)].name)

		bind.touch(self, children.sprite,  {methods = {ended = functools.partial(self.onCardSprClick, self)}})

		local events = {}
		local function addEventInsert(eventId)
			if not eventId then return end
			local eventTb = csv.effect_event[eventId]
			if not eventTb then return end
			if eventTb.effectRes then
				events[eventId] = {
					res = eventTb.effectRes,
					args = eventTb.effectArgs,
				}
			end
			if eventTb.otherEventIDs then
				for _, id in csvPairs(eventTb.otherEventIDs) do
					addEventInsert(gEffectByEventCsv[id])
				end
			end
		end

		for _, processId in csvPairs(skillCsv.skillProcess) do
			local process = csv.skill_process[processId]
			addEventInsert(process.effectEventID)
		end

		local args = {
			res = unitCsv.unitRes,
			skin = unitCsv.skin,
			aniName = skillName,
			scale = unitCsv.scale,
			offsetPos = cc.p(skillCsv.posC.x, skillCsv.posC.y), -- 这个是用于战斗内精灵技能时本身行动相对位置的一个偏移，不应用于限时精灵大招动画配置
			events = events,
			sound = skillCsv.sound,
			scaleArgs = skillCsv.cameraNear == 0 and skillCsv.scaleArgs or skillCsv.cameraNear_scaleArgs
		}
		if self.cfg.clientParam.unitId then
			args.scale = 2.3
		end
		self.aniArgs = args
	end)

	idlereasy.when(self.sprState, function(_, state)
		local isPlayOver = false
		local playOver = function()
			if isPlayOver then return end
			isPlayOver = true -- 防止重复触发
			self.aniLayer:removeAllChildren()
			self.aniLayer:hide()
			self.spritePanel:show()
			if self.musicHandle then
				audio.stopSound(self.musicHandle)
			end
		end

		if state == 1 then
			self.spritePanel:hide()
			self:playAni(playOver)
			self.aniLayer:show()
		else
			playOver()
			self.aniLayer:hide()
			self.spritePanel:show()
		end
	end)
end

function ActivityLimitSpriteView:playAni(playOver)
	local args = self.aniArgs
	local pos = cc.p( display.center.x, display.center.y)
	local cardSprite = widget.addAnimation(self.aniLayer, args.res, args.aniName, 100)
		:scale(args.scale * (args.scaleArgs.scale or 1))
		:xy(pos)
	cardSprite:setSkin(args.skin)
	cardSprite:setSpriteEventHandler(function(event, eventArgs)
		performWithDelay(self, playOver, 0)
	end, sp.EventType.ANIMATION_COMPLETE)

	for id, data in pairs(args.events) do
		local args = data.args
		local pos = cc.p(args.offsetX or 0, args.offsetY or 0)
		if args.screenPos then
			if args.screenPos == 0 then
				pos = cc.pAdd(pos, display.center)
			elseif args.screenPos == 1 then
				local x, y = cardSprite:getPosition()
				local effectPos = cc.p(x, y)
				pos = cc.pAdd(pos, effectPos)
			end
		end
		local zorder = args.zorder or 0
		if args.addTolayer == 1 then
			zorder = 100 + zorder
		end
		local spr = widget.addAnimationByKey(self.aniLayer, data.res, "bgEffect" .. id, args.aniName, zorder):xy(pos)
		spr:scale(3 * args.scale or 0)
	end

	if args.sound then
		self.musicHandle = audio.playEffectWithWeekBGM(args.sound.res, args.sound.loop > 0)
	end
end

-- 初始化宝箱数据信息
function ActivityLimitSpriteView:initBoxInfo()
	local tb = {}
	local maxScore = 0
	local huodongID = self.cfg.huodongID
	for id, cfg in orderCsvPairs(csv.yunying.limitboxpointaward) do
		if cfg.huodongID == huodongID then
			maxScore = math.max(cfg.pointRequire, maxScore)
			table.insert(tb, {
				id = id,
				iconId = cfg.boxIcon,
				award = cfg.award,
				point = cfg.pointRequire,
				state = nil,
			})
		end
	end
	table.sort(tb, function (a, b)
		return a.point > b.point
	end)
	local boxCount = #tb
	local boxWidth = self.boxItem:size().width
	local listWidth = self.boxList:size().width
	local margin = (listWidth / boxCount) - boxWidth
	self.boxList:setItemsMargin(margin)
	self.boxData:set(tb)
	self.boxCount = boxCount
	self.maxScore = maxScore

	self.scoreBar:setPercent(0)
end

-- 宝箱点击函数
function ActivityLimitSpriteView:onBoxClick(list, id, state, award, score)
	local activityId = self.activityId:read()
	if state == 1 then
		gGameApp:requestServer("/game/yy/limit/box/point", function (tb)
			gGameUI:showGainDisplay(tb.view)
		end, activityId, id)
		return
	end

	local str = state == nil and string.format(gLanguageCsv.limitBoxGet, score) or ""
	gGameUI:showBoxDetail({
		data = award,
		content = str,
		state = state or 1,-- 此处 1表示已领 0 表示未领
	})
end

-- 重置宝箱进度条 idx 当前已经到达第几个宝箱
function ActivityLimitSpriteView:resetBoxBar(idx)
	local boxData = self.boxData:read()
	local boxCount = self.boxCount
	local scoreItem = 1 / self.boxCount 		-- 每个宝箱之间平均多少进度
	local scoreCur = 0
	scoreCur = scoreCur + scoreItem * idx

	if idx == 0 then 		-- 表示进度条应该是空的 还没有到达宝箱的进度
		local percent = self.boxPoint / boxData[boxCount].point
		scoreCur = scoreCur + percent * scoreItem
	elseif idx == self.boxCount then 		-- 表示进度条应该是满的 所有宝箱都领取了
		scoreCur = 1
	else
		local s1, s2 = boxData[boxCount - idx + 1].point, boxData[boxCount - idx].point
		local scoreLen = s2 - s1 		--阶段积分进度的长度
		local percent = (self.boxPoint - s1) / scoreLen
		scoreCur = scoreCur + percent * scoreItem
	end

	self.scoreBar:setPercent(scoreCur * 100)
end

-- 重置剩余时间等
-- @params showDay 是否显示天数 1 显示 2 不显示：天数转化成小时显示
function ActivityLimitSpriteView:resetTimeLabel()
	local activityId = self.activityId:read()
	-- 没有 text 表示在页面内显示
	-- cn 活动结束时间是 周一5点； kr 活动结束时间点会出现 周日 23:59:59
	-- 抽卡结束时间活动开始的第三天的21:30
	local yyCfg = csv.yunying.yyhuodong[activityId]
	local getHuodongEndTime = time.getNumTimestamp(yyCfg.beginDate,21,30) + 2*24*60*60
	self.getHuodongEndTime = getHuodongEndTime

	local timeT = getHuodongEndTime - time.getTime()
	local text = self.timeText
	local showDay = 1 -- 默认显示天数
	local function setLabel()
		timeT = getHuodongEndTime - time.getTime()
		if timeT <= 0 then
			text:text(gLanguageCsv.activityOver)
			adapt.oneLinePos(self.timeTextNote, self.timeText, cc.p(10,0))
			return false
		end
		local str = ""
		if showDay == 2 then
			str = time.getCutDown(timeT).clock_str
		else
			str = time.getCutDown(timeT).str
		end
		text:text(str)
		if self.timeTextNote then
			adapt.oneLinePos(self.timeTextNote, self.timeText, cc.p(10,0))
		end
		return true
	end

	setLabel()
	if timeT > 0 then
		local scheduleTag = 100-- 定时器tag
		-- 移除上次的刷新定时器
		self:enableSchedule():unSchedule(scheduleTag)
		self:schedule(function()
			if not setLabel() then
				-- 活动结束时获得最新数据刷新界面
				self:onBtnRankClick()
				return false
			end
		end, 1, 1, scheduleTag)-- 1秒钟刷新一次
	end
end

-- 刷新排名信息 缓存信息
function ActivityLimitSpriteView:resetRankInfo(rankData)
	local tb = clone(rankData)
	local count = #rankData
	local maxCount = 30
	if count > maxCount then 			-- 策划要求不能超过30个
		for i = maxCount + 1, count do
			tb[i] = nil
		end
	end
	self.rankData:set(tb)
end

function ActivityLimitSpriteView:onCardSprClick()
	local curState = self.sprState:read()
	if curState == 1 then
		self.sprState:set(0)
	else
		self.sprState:set(1)
	end
end

-------------------------------右侧列表相关---------------------------------------
-- 积分排名按钮
function ActivityLimitSpriteView:onBtnRankClick()
	gGameApp:requestServer("/game/yy/limit/box/get", function (tb)
		self:resetRankInfo(tb.view.rank)
		self.curListType:set(LIST_TYPE.RANK)
	end, self.activityId:read())
end

-- 积分奖励按钮
function ActivityLimitSpriteView:onBtnAwardClick()
	self.curListType:set(LIST_TYPE.AWARD)
end

-- 读取配表获取奖励列表
function ActivityLimitSpriteView:initAwardData()
	local huodongID = self.cfg.huodongID
	local tb = {}
	local rankStart = 0
	for id, cfg in csvPairs(csv.yunying.limitboxrankaward) do
		if cfg.huodongID == huodongID then
			table.insert(tb, {
				point = cfg.pointLeast,
				award = cfg.award,
				rankStart = rankStart,
				rankEnd = cfg.rank,
				desc = desc,
			})
			rankStart = cfg.rank
		end
	end
	table.sort(tb, function (a, b)
		return a.point > b.point
	end)
	self.awardData = tb
end

-- 初始化自己的信息
function ActivityLimitSpriteView:initSelfInfo()
	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local activityId = self.activityId:read()
		local data = yyhuodongs[activityId]
		local children = self.myrank:multiget("rank", "score", "name")
		local boxPoint = data.box_point or 0
		self.boxPoint = boxPoint
		children.rank:text(data.info.rank or gLanguageCsv.craftNoRank)
		children.score:text(boxPoint)
		children.name:text(gGameModel.role:read("name"))
		local stamps = data.stamps or {}
		local boxCount = self.boxCount or 0
		local maxIdx = 0
		for i = 1, boxCount do
			local curData = self.boxData:proxy()[boxCount - i + 1]
			local state = stamps[curData.id]
			curData.state = state
			if state then
				maxIdx = math.max(maxIdx, i)
			end
		end
		self:resetBoxBar(maxIdx)
	end)
end

-------------------------------中间精灵相关---------------------------------------
-- 图鉴按钮
function ActivityLimitSpriteView:onHandBookClick()
	local curId = self.curDevelopId:read()
	jumpEasy.jumpTo("handbook", {cardId = self.markTb[curId].id})
end

-- 右箭头点击
function ActivityLimitSpriteView:onRightClick()
	local len = table.length(self.markTb)
	local curId = self.curDevelopId:read()
	self.curDevelopId:set(math.min(curId + 1, len))
end

-- 左箭头点击
function ActivityLimitSpriteView:onLeftClick()
	local curId = self.curDevelopId:read()
	self.curDevelopId:set(math.max(curId - 1, 1))
end
-------------------------------下方抽卡相关---------------------------------------
-- 检测是否可以抽卡
function ActivityLimitSpriteView:isEnoughToDraw(cost, times)
	local isFree = self.isFree:read()
	if times > 1 then
		isFree = false
	end
	if not isFree and self.rmb:read() < cost then
		-- 钻石不足
		uiEasy.showDialog("rmb")
		return false
	end

	local bagFull = self.cardCapacity:read() - itertools.size(self.cardDatas:read()) <= BAGMAXLEFTTIMES[times]
	if bagFull and  csv.yunying.yyhuodong[self.activityId:read()].showTips and self.checkCardCapacity:read() == 1 then
		-- 背包已满
		gGameUI:showDialog{content = gLanguageCsv.cardBagHaveBeenFullDraw, cb = function()
			gGameUI:stackUI("city.card.bag", nil, {full = true})
		end, btnType = 2, clearFast = true}
		return false
	end

	return true
end

-- 单抽
function ActivityLimitSpriteView:onDrawOneClick()
	if not self:isEnoughToDraw(self.oneCost, 1) then
		return
	end

	local isFree = self.isFree:read()
	local yyId = self.activityId:read()
	local str = isFree and "limit_box_free1" or "limit_box_rmb1"

	local function cb()
		gGameApp:requestServer("/game/yy/limit/box/draw", function(tb)
			self:resetRankInfo(tb.view.rank)
			audio.pauseMusic()
			audio.playEffectWithWeekBGM("drawcard_one.mp3")
			local ret, spe, isFull = dataEasy.getRawTable(tb)
			local items = dataEasy.getItems(ret, spe)
			local params = {
				items = items,
				drawType = "limit_sprite",
				times = 1,
				isFree = isFree,
				yyId = yyId,
				checkCardCapacity = self.checkCardCapacity:read(),
			}
			gGameUI:stackUI("city.drawcard.result", nil, nil, params)
		end, yyId, str)
	end
	if isFree then
		cb()
	else
		dataEasy.sureUsingDiamonds(cb, self.oneCost)
	end
end

-- 十连
function ActivityLimitSpriteView:onDrawTenClick()
	if not self:isEnoughToDraw(self.tenCost, 10) then
		return
	end

	dataEasy.sureUsingDiamonds(function ()
		local yyId = self.activityId:read()
		gGameApp:requestServer("/game/yy/limit/box/draw", function(tb)
			self:resetRankInfo(tb.view.rank)
			audio.pauseMusic()
			audio.playEffectWithWeekBGM("drawcard_ten.mp3")
			local ret, spe, isFull = dataEasy.getRawTable(tb)
			local items = dataEasy.getItems(ret, spe)
			local params = {
				items = items,
				drawType = "limit_sprite",
				times = 10,
				isFree = false,
				yyId = yyId,
				cb = function(tb)
					self:resetRankInfo(tb.view.rank)
				end,
			}
			gGameUI:stackUI("city.drawcard.result", nil, nil, params)
		end, yyId, "limit_box_rmb10")
	end, self.tenCost)
end
-----------------------------------杂项-------------------------------------------
-- 限时奖励预览
function ActivityLimitSpriteView:onShowAwardList()
	gGameUI:stackUI("city.drawcard.preview", nil, {blackLayer = true, clickClose = true}, "limit_sprite", self.activityId:read())
end

-- 显示规则文本
function ActivityLimitSpriteView:onShowRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ActivityLimitSpriteView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.limitSpriteRuleTitle)
		end),
		c.noteText(117),
		c.noteText(64001, 64005),
		c.noteText(118),
		c.noteText(65001, 65004),
	}
	return context
end

function ActivityLimitSpriteView:onClose()
	local closeCb = self.closeCb
	Dialog.onClose(self)
	closeCb()
end

return ActivityLimitSpriteView
