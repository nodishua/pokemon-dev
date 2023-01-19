-- @date:   2018-10-16
-- @desc:   战斗关卡主界面

local MAP_TYPE = {
	normal = 1,
	hero = 2,
	nightmare = 3,
}

local CHAPTER_NUM = {
	[MAP_TYPE.normal] = 10,
	[MAP_TYPE.hero] = 110,
	[MAP_TYPE.nightmare] = 210,
}

local BGICON = {
	"city/gate/bg_cj1.png",
	"city/gate/bg_cj_kn1.png",
	"city/gate/bg_cj_em1.png",
}

local BGICON2 = {
	"city/gate/bg_cj2.png",
	"city/gate/bg_cj_kn2.png",
	"city/gate/bg_cj_em2.png",
}

-- 使用完了重置

local function canShowEffect(battleId, gateId, starAdd, starNum)
	return battleId and battleId == gateId and starAdd > 0 and starNum == starAdd
end

--第一章 第一个关卡并且未通关
local function canPlayAction(v, idx, k, starNum)
	if v.isFirstEnter and idx == 1 and k == 1 and starNum <= 0 then
		userDefault.setForeverLocalKey("isEnterLevelFirst", {[v.levelType] = false})
		return true
	elseif v.isFirstEnter then
		userDefault.setForeverLocalKey("isEnterLevelFirst", {[v.levelType] = false}) --换了设备
	end
	return false
end

-- 添加抖动处理
local function addVibrateToNode(view, node, state, k, gateId)
	local tag = k and view:getName()..k.."vibrate"..gateId or view:getName().."toRotationScheduleTag"..gateId
	uiEasy.addVibrateToNode(view, node, state, tag)
end

-- 计算出所有的点并且加的关卡上
local function getAllPassPoints(node, info, off)
	local function getPosintes(startPoint, endedPoint)
		local pointes = {}
		table.insert(pointes, {x = startPoint.x, y = startPoint.y})

		local offx = math.abs(endedPoint.x - startPoint.x)
		local offy = math.abs(endedPoint.y - startPoint.y)
		local off = math.max(offx, offy)
		local num = math.max(0, math.floor(off / 45) - 1)
		for i=1, num do
			local vecX = endedPoint.x >= startPoint.x and 1 or -1
			local vecY = endedPoint.y >= startPoint.y and 1 or -1
			local disx = offx / (num + 1)
			local x = startPoint.x + i * disx * vecX + math.random(0, 8)
			local disy = offy / (num + 1)
			local y = startPoint.y + i * disy * vecY + math.random(0, 8)
			table.insert(pointes, {x = x, y = y})
		end
		return pointes
	end

	local pathPointes = {}
	for i=2, itertools.size(info.frontWay) do
		local sp = info.frontWay[i - 1]
		local ep = info.frontWay[i]
		local pt = getPosintes({x = sp[1], y = sp[2]}, {x = ep[1], y = ep[2]})
		for _,pos in ipairs(pt) do
			local point = cc.Sprite:create("city/gate/logo_path.png")
			point:visible(false)
			point:xy(pos.x + off, pos.y)
			node:addChild(point, 9, "point")
			table.insert(pathPointes, point)
		end
	end
	return pathPointes
end

local function playStarAni(item, starNum, starAdd, mapInfo)
	for i=1, starNum - starAdd do
		item:get("imgStar"..i):get("star"):visible(true)
	end

	local starAddTime = 0.3
	for i = starNum - starAdd, starNum - 1 do -- 增加的星星 用spine
		local spineName = mapInfo.starSpineName
		local pos = mapInfo.starSpinePos(i)

		item:get("imgStar"..(i + 1)):get("star"):visible(false)

		-- 给不同的星星加递增得延时，以实现星星逐个出现
		performWithDelay(item, function()
			local starSpine = widget.addAnimationByKey(item, spineName, "star"..(i + 1), "effect_star"..(i + 1), 11)
			starSpine:xy(pos)
		end, 0.3 + starAddTime * i)
	end
end

-- 对高级关卡按钮的详细设置
local function setItemLevelName(item, icon, sceneName, bossNodeRes)
	local levelName = item:get("levelName")
	local textLvNum = item:get("textLvNum")
	local imgMask = item:get("imgMask")
	local color = cc.c4b(255, 252, 237, 255)
	levelName:text(sceneName)
	levelName:visible(true)
	textLvNum:visible(true)

	text.addEffect(levelName, {outline={color = color, size = 4}})
	text.addEffect(textLvNum, {outline={color = color, size = 4}})
	-- adapt.oneLinePos(textLvNum, levelName, cc.p(5,0))
	adapt.oneLineCenterPos(cc.p(160, 310), {textLvNum, levelName}, cc.p(5, 0))

	if bossNodeRes then
		item:get("imgBG"):loadTexture(bossNodeRes)
	end

	-- 为精灵图标设置遮罩
	local sp = cc.Sprite:create(icon):scale(1.6)
	local mask = ccui.Scale9Sprite:create("city/gate/kunnanzhezhao.png"):scale(2)
	local clip = cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.1)
		:xy(item:get("imgIcon"):xy())
		:add(sp)
		:addTo(item, 4, "clipping")
	sp:xy(0,0)
end

-- 设置噩梦关卡按钮
local function setNightmareLevelItem(item, info, node, isPlayAction, allPointTime, isBossNode)
	local effectName = isBossNode and "effect2" or "effect"
	if isPlayAction then
		local delayTime = 1.6
		-- 需要先隐藏 再延时出现
		item:get("levelName"):visible(false)
		item:get("textLvNum"):visible(false)

		performWithDelay(item, function()
			widget.addAnimationByKey(item, "level/emengjiedian.skel", "iconBG", effectName, 1)
				:xy(160, 25)
				:addPlay(effectName.."_loop")
			widget.addAnimationByKey(item, "level/emengjiedian.skel", "starSpine", "effect_stardi", 10):xy(160, 25)
		end, 0.3 + allPointTime)

		performWithDelay(item, function()
			setItemLevelName(item, info.icon, info.sceneName)
		end, delayTime + allPointTime)

		return delayTime
	else
		-- 噩梦副本的item 背景是常隐藏的 用loop特效替换之 注意层级
		widget.addAnimationByKey(item, "level/emengjiedian.skel", "iconBG", effectName.."_loop", 1):xy(160, 25)
		setItemLevelName(item, info.icon, info.sceneName)
		return 0
	end
end

-- 设置困难关卡按钮
local function setSpeChapterLevelItem(item, info, node, isPlayAction, allPointTime, isBossNode)
	if isPlayAction then
		local delayTime = 1.6
		-- 需要先隐藏 再延时出现
		item:get("imgBG"):visible(false)
		item:get("levelName"):visible(false)
		item:get("textLvNum"):visible(false)

		performWithDelay(item, function()
			widget.addAnimationByKey(item, "level/kunnanjiedian.skel", "iconBG", isBossNode and "effect2" or "effect", 1)
				:xy(160, 25)
			widget.addAnimationByKey(item, "level/kunnanjiedian.skel", "starSpine", "effect_stardi", 10)
				:xy(160, 25)
		end, 0.3 + allPointTime)

		performWithDelay(item, function()
			setItemLevelName(item, info.icon, info.sceneName, isBossNode and "city/gate/boss.png" or nil)
		end, delayTime + allPointTime)

		return delayTime
	else
		setItemLevelName(item, info.icon, info.sceneName, isBossNode and "city/gate/boss.png" or nil)
		return 0
	end
end

-- 设置普通关卡按钮
local function setNormalLevelItem(item, info, node, isPlayAction, allPointTime, isBossNode)
	if isPlayAction then
		local actionName = "effect_1"
		local delayTime = 1.8 + 0.3

		item:get("imgtextBG"):visible(false)
		item:get("imgIcon"):visible(false)
		item:get("imgLvIcon"):visible(false)
		item:get("spePanel"):visible(false)

		if info.icon then
			actionName = isBossNode and "effect_3" or "effect_2"
			item:get("spePanel"):get("imgIcon"):texture(info.icon)
			item:size(cc.size(170, 315))
			item:anchorPoint(0.5, 0.3)
			performWithDelay(node, function()
				item:get("spePanel"):visible(true)
			end, delayTime + allPointTime)
		end
		performWithDelay(item, function()
			widget.addAnimationByKey(item, "level/anniu1.skel", "downSpine", actionName, 1)
				:xy(85, 105)
			widget.addAnimationByKey(item, "level/anniu1.skel", "starSpine", "effect_stardi", 10)
				:xy(85, 105)
		end, 0.3 + allPointTime)

		return delayTime
	else
		local path = "city/gate/icon_node_white.png"
		local bgPath = "city/gate/icon_node_boss.png"

		if info.icon then
			path = "city/gate/icon_node_red.png"
			item:get("spePanel"):visible(true)
			item:get("imgIcon"):visible(false)
			item:get("spePanel"):get("imgIcon"):texture(info.icon)
			item:size(cc.size(170, 315))
			item:anchorPoint(0.5, 0.3)
			if isBossNode then
				bgPath = "city/gate/icon_node_big_boss.png"
			end
		end
		item:get("spePanel"):get("imgTopBG"):texture(bgPath)
		item:get("imgLvIcon"):visible(true)
		item:get("imgLvIcon"):texture(path)

		return 0
	end
end

local ITEM_SET_INFO = {
	[MAP_TYPE.normal] = {
		getItem = function(self) return self.levelItem end,			-- 每个小关卡的item
		starSpineName = "level/anniu1.skel",						-- 星星的特效spine
		starSpinePos = function (i) return cc.p(85 + i, 103) end,	-- 星星的特效位置
		setItemFunc = setNormalLevelItem,							-- 针对Item的设置函数
		selIconPos = function (icon)								-- item上头的标记位置
			if icon then
				return cc.p(85, 140)
			else
				return cc.p(85, 20)
			end
		end,
	},
	[MAP_TYPE.hero] = {
		getItem = function(self) return self.speItem end,
		starSpineName = "level/kunnanjiedian.skel",
		starSpinePos = function (i) return cc.p(160 + i, 26) end,
		setItemFunc = setSpeChapterLevelItem,
		selIconPos = function ()
			return cc.p(160, 160)
		end,
	},
	[MAP_TYPE.nightmare] = {
		getItem = function(self) return self.emItem end,
		starSpineName = "level/emengjiedian.skel",
		starSpinePos = function (i) return cc.p(160 + i, 26) end,
		setItemFunc = setNightmareLevelItem,
		selIconPos = function ()
			return cc.p(160, 160)
		end,
	},
}

local ViewBase = cc.load("mvc").ViewBase
local GateView = class("GateView", ViewBase)

GateView.RESOURCE_FILENAME = "gate.json"
GateView.RESOURCE_BINDING = {
	["imgBG"] = {
		varname = "imgBG",
		binds = {
			event = "texture",
			idler = bindHelper.self("mapType"),
			method = function(mapType)
				return BGICON[mapType] or ""
			end
		},
	},
	["imgBG2"] = {
		varname = "imgBG2",
		binds = {
			event = "texture",
			idler = bindHelper.self("mapType"),
			method = function(mapType)
				return BGICON2[mapType] or ""
			end
		},
	},
	["mask"] = "mask",
	["box"] = "box",
	["leftDown.btnMainLine"] = {
		varname = "btnJuQing",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeJuQing")}
		},
	},
	["leftDown.btnMainLine.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ATROVIRENS}}
		},
	},
	["leftDown.btnDiffect"] = {
		varname = "btnKunNan",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onChangeKunNan")}
			},
			{
				event = "visible",
				idler = bindHelper.self("heroGateListen")
			},
		},
	},
	["leftDown.btnDiffect.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.PURPLE}}
		},
	},
	["leftDown.btnNightmare"] = {
		varname = "btnNightmare",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onChangeNightmare")}
			},
			{
				event = "visible",
				idler = bindHelper.self("nightGateListen"),
			},
		},
	},
	["leftDown.btnNightmare.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}}
		},
	},
	["btnRight"] = {
		varname = "btnRight",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onMoveRight")}
		},
	},
	["btnLeft"] = {
		varname = "btnLeft",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onMoveLeft")}
		},
	},
	["rightDown"] = {
		varname = "rightDown",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onEnterStarBox")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag  ="levelRightDownGift",
					listenData = {
						chapterId = bindHelper.self("chapterId"),
					},
					onNode = function(panel)
						panel:xy(250, 250)
					end,
				}
			},
		},
	},
	["rightDown.textStarNum"] = {
		varname = "textStarNum",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 4}},
		},
	},
	["rightTop.imgSaveBG"] = {
		varname = "imgSaveBG",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onSaveLevel")},
			},
			{
				event = "visible",
				idler = bindHelper.self("quickSweep"),
			},
		}
	},
	["rightTop.imgSaveBG.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},

	["rightTop.imgCaptureBG"] = {
		varname = "limitCapture",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onClickResidentCapture")},
			},
			{
				event = "visible",
				idler = bindHelper.self("captureListen")
			},
		}
	},
	["rightTop.imgCaptureBG.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},

	--世界等级
	["levelInfo"] = "levelInfo",
	["levelInfo.textNoteNum1"] = {
		varname = "textNoteNum1",
		binds = {
			event = "text",
			idler =  bindHelper.self("worldLevel"),
		}
	},
	["levelInfo.textNoteNum2"] = {
		varname = "textNoteNum2",
		binds = {
			event = "text",
			idler = bindHelper.self("roleLevel")
		}
	},
	["levelInfo.textNote4"] = "textNote4",
	["levelInfo.textNoteNum4"] = "textNoteNum4",


	["emLevel"] = "emItem",
	["speLevel"] = "speItem",
	["item"] = "item",
	["level"] = "levelItem",
	["pageView"] = {
		varname = "pageView",
		binds = {
			event = "extend",
			class = "pageview",
			props = {
				data = bindHelper.self("levelDatas"),
				item = bindHelper.self("item"),
				onItem =function(list, node, k, v)
					node:name("page" .. v.pageId)
					list.initItem(list, node, k, v)
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				clickGateItem = bindHelper.self("onClickGateItem"),
				initItem =  bindHelper.self("onInitPage"),
				clickBox = bindHelper.self("onClickBox"),
				captureClick = bindHelper.self("onClickCapture")
			},
		},
	},
	["cloud1"] = "cloud1",
	["cloud2"] = "cloud2",
	["cloud3"] = "cloud3",
	["cloud4"] = "cloud4",
	["cloud5"] = "cloud5",
	["cloud6"] = "cloud6",
	["sun"] = "sun",
	["capture"] = "capture",
}

function GateView:getCsvIByChapterId(idx)
	if not self.chaterIdtab then
		self.chaterIdtab = {}
		for i,v in orderCsvPairs(csv.world_map) do
			if v.chapterType then
				if not self.chaterIdtab[v.chapterType] then
					self.chaterIdtab[v.chapterType] = {}
				end
				table.insert(self.chaterIdtab[v.chapterType], i)
			end
		end
		for k,v in pairs(self.chaterIdtab) do
			table.sort(v)
		end
	end

	return self.chaterIdtab[self.mapType:read()][idx]
end

local function getCurTypeChapterCount(_type)
	local world_mapCsv = csv.world_map
	local maxCount = 0
	for i,v in orderCsvPairs(world_mapCsv) do
		if v.chapterType == _type then
			maxCount = maxCount + 1
		end
	end
	return maxCount
end

-- _type 章节类型
-- chapterId 章节ID
-- gateId 关卡ID
function GateView:onCreate(gateId)
	-- 1、屏幕大小适配 参数设置
	local width = self.item:size().width
	self.off = (display.sizeInView.width - width) / 2
	self.item:size(display.sizeInView)
	self.item:get("topView"):size(display.sizeInView)
	self.mask:size(display.sizeInView):anchorPoint(cc.p(0, 0)):x(0)
	self.pageView:size(display.sizeInView):x(0)
	for k,child in pairs(self.item:getChildren()) do
		child:anchorPoint(cc.p(0.5, 0.5))
		child:xy(display.sizeInView.width / 2, display.sizeInView.height / 2)
	end

	self.heroGateListen = dataEasy.getListenUnlock(gUnlockCsv.heroGate)
	self.captureListen = dataEasy.getListenUnlock(gUnlockCsv.limitCapture)
	self.nightGateListen = dataEasy.getListenUnlock(gUnlockCsv.nightmareGate)
	self.worldLevelInfoListen = dataEasy.getListenUnlock(gUnlockCsv.worldLevel)   --世界等级显示
	self.quickSweep = dataEasy.getListenUnlock(gUnlockCsv.quickSweep)
	-- 2、数据初始化
	-- gateId_starNum    starNum是增量
	self.battleData = userDefault.getForeverLocalKey("gateAddStarNum", {})

	--世界等级显示
	adapt.oneLinePos(self.levelInfo:get("textNote1"), self.textNoteNum1, cc.p(5, 0))
	adapt.oneLinePos(self.levelInfo:get("textNote2"), self.textNoteNum2, cc.p(5, 0))
	adapt.oneLinePos(self.levelInfo:get("textNote3"), self.levelInfo:get("textNoteE3"), cc.p(5, 0))
	adapt.oneLinePos(self.levelInfo:get("textNote4"), self.textNoteNum4, cc.p(5, 0))
	userDefault.setForeverLocalKey("gateAddStarNum")
	local _type, chapterId = 1, 0
	gateId = tonumber(gateId) or tonumber(self.battleData.gateId) or 0
	local csvData = csv.scene_conf
	local world_mapCsv = csv.world_map
	if gateId and gateId ~= 0 then
		if gateId % 100 == 0 then
			_type, chapterId = dataEasy.getChapterInfoByGateID(gateId)
			gateId = 0
		else
			local sceneConfCfg = csvData[gateId]
			local worldMapCfg = world_mapCsv[sceneConfCfg.ownerId]
			_type = worldMapCfg.chapterType
			chapterId = sceneConfCfg.ownerId - CHAPTER_NUM[_type] or 0
		end
	end
	_type = self._mapType or _type
	chapterId = self._curPageIdx or chapterId

	-- chapterId = chapterId or 0
	if tonumber(gateId) and gateId ~= 0
		and (not self.battleData.gateId or tonumber(self.battleData.gateId) == 0)
		and not gGameUI.guideManager:isInGuiding() then
		performWithDelay(self, function()
			gGameUI:stackUI("city.gate.section_detail.view", nil, nil, gateId, chapterId)
		end, 1/60)
	end

	-- 3、相关idler获取
	self:initModel(_type, gateId, chapterId)
	-- 4、云层初始位置保存
	self.cloudInitPos = {}
	for i=1,6 do
		table.insert(self.cloudInitPos, {x = self['cloud'..i]:x(), y = self['cloud'..i]:y()})
	end
	self.sunInitPos = {x = self.sun:x(), y = self.sun:y()}

	-- 5、头部栏设置
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")}):init()

	-- 6、idler绑定
	local mapTypeBtn = {self.btnJuQing, self.btnKunNan, self.btnNightmare}
	idlereasy.any({self.mapOpen, self.mapType , self.level,self.gateOpen}, function(_, mapOpen, mapType, level, gateOpen)
		self.chapterOpen = {}
		for i,v in ipairs(mapOpen) do
			local chapterType = world_mapCsv[v].chapterType
			self.chapterOpen[chapterType] = self.chapterOpen[chapterType] or {}
			table.insert(self.chapterOpen[chapterType], v)
		end
		for i,v in ipairs(self.chapterOpen) do
			table.sort(v)
		end
		for i,v in ipairs(mapTypeBtn) do
			v:setTouchEnabled(not (i == mapType))
			v:get("selected"):visible(i == mapType)
			-- v:setBright(not (i == mapType))
		end
		self:refreshData(mapType)
		self:cloudAnimation(mapType)	-- 云层动画
	end)

	--世界等级显示
	idlereasy.any({self.mapType, self.worldLevelInfoListen,self.level}, function(_, mapType, worldLevelUnlock,selfLevel)
		-- self.textNote4:text(str) --世界等级显示
		local exp = dataEasy.getWorldLevelExpAdd(mapType)
		if not exp then
			self.levelInfo:hide()

		elseif mapType == MAP_TYPE.normal and worldLevelUnlock then
			self.levelInfo:show()
			self.textNote4:text(gLanguageCsv.nomalExpAddtext)
			self.textNoteNum4:text(exp)
			if matchLanguage({"en"}) then
				-- en 的默认翻译和glanguageCsv翻译不一致，会导致之前自适应的代码失效
				adapt.oneLinePos(self.textNote4, self.textNoteNum4, cc.p(5, 0))
			end
		elseif mapType == MAP_TYPE.hero and worldLevelUnlock then
			self.levelInfo:show()
			self.textNote4:text(gLanguageCsv.heroExpAddtext)
			self.textNoteNum4:text(exp)
			if matchLanguage({"en"}) then
				-- en 的默认翻译和glanguageCsv翻译不一致，会导致之前自适应的代码失效
				adapt.oneLinePos(self.textNote4, self.textNoteNum4, cc.p(5, 0))
			end
		else
			self.levelInfo:hide()
		end
	end)

	idlereasy.any({self.chapterId, self.mapStar}, function(_, chapterId, mapStar)
		local hasReward = false
		if mapStar and mapStar[chapterId] and mapStar[chapterId].star_award and
			itertools.first(mapStar[chapterId].star_award, 1) ~= nil then
			hasReward = true
		end

		if hasReward then
			widget.addAnimationByKey(self.rightDown, "effect/guanqiabaoxiang.skel", "rewardEffect", "effect_loop", 2)
				:xy(110, 135)
		else
			self.rightDown:removeChildByName("rewardEffect")
		end
	end)

	self.pageView:setTouchEnabled(false)
	idlereasy.when(self.pageIdler, function(_, privilegeIndex)
		local maxLen = self.levelDatas:size()								-- 当前难度可以到达的章节数量
		local maxCount = getCurTypeChapterCount(self.mapType:read())		-- 当前难度所有章节数量
		privilegeIndex = cc.clampf(tonumber(privilegeIndex), 1, tonumber(maxLen))

		self.btnLeft:visible(privilegeIndex > 1)
		self.btnLeft:setTouchEnabled(privilegeIndex > 1)

		self.btnRight:visible(privilegeIndex < maxCount)
		self.btnRight:setTouchEnabled(privilegeIndex < maxCount)

		cache.setShader(self.btnLeft, false, privilegeIndex > 1 and "normal" or "hsl_gray")
		cache.setShader(self.btnRight, false, privilegeIndex < maxLen and "normal" or "hsl_gray")

		local chapterData = self.levelDatas:atproxy(privilegeIndex)
		local selId
		if privilegeIndex == maxLen then
			local lastIdx = itertools.size(chapterData.seq)
			selId = chapterData.seq[lastIdx]
		elseif self.selGateIdx.chapterId == privilegeIndex then
			selId = self.selGateIdx.gateId ~= 0 and self.selGateIdx.gateId or chapterData.seq[1]
		else
			selId = chapterData.seq[1]
		end
		self.levelDatas:atproxy(privilegeIndex).selGateId = selId
		self.levelDatas:atproxy(privilegeIndex).isShow = true
		self.pageView:setCurrentPageIndex(privilegeIndex - 1)
		-- 更新标题
		local chapterId = chapterData.chapterId
		self.chapterId:set(chapterId)
		local chapterString = string.format(gLanguageCsv.levelChapterId, privilegeIndex)..csv.world_map[chapterId].name
		if matchLanguage({"en"}) then
			chapterString = string.format(gLanguageCsv.levelChapterId, privilegeIndex).." "..csv.world_map[chapterId].name
		end
		gGameUI.topuiManager:updateTitle(chapterString)
		-- 刷新星星数量
		self:onRefreshStarNum()
	end)

	-- 左右滑动
	uiEasy.addTouchOneByOne(self.mask, {ended = function(pos, dx, dy)
		if dx > 100 and math.abs(dx) > math.abs(dy) then
			self:onMoveLeft()
		elseif dx < -100 and math.abs(dx) > math.abs(dy) then
			self:onMoveRight()
		end
	end})

	--红点控制
	self:setRedHint()

	local state, paramMaps, count = dataEasy.isDoubleHuodong("gateDrop")
	if state then
		for i, paramMap in pairs(paramMaps) do
			local startId = paramMap["start"]
			local typeId = dataEasy.getChapterInfoByGateID(startId)
			if typeId == 1 then 		-- 普通
				self.btnJuQing:get("flagImg"):show()
			elseif typeId == 2 then 	-- 困难
				self.btnKunNan:get("flagImg"):show()
			elseif typeId == 3 then 	-- 噩梦
				self.btnNightmare:get("flagImg"):show()
			end
		end
	end
	local state, paramMaps, count = dataEasy.isDoubleHuodong("heroGateTimes")
	if state then
		for i, paramMap in pairs(paramMaps) do
			local addTimes = paramMap["count"]
			if addTimes and addTimes > 0 then 	-- 困难
				self.btnKunNan:get("heroGateTimesBg"):show()
			end
		end
	end

	-- 观察修正，剧情背景花屏，尝试对半切成2张图显示
	-- self.normalBg1 = ccui.ImageView:create("city/gate/bg_cj1_1.png")
	-- 	:anchorPoint(1, 0)
	-- 	:xy(display.sizeInView.width/2, 0)
	-- 	:z(self.imgBG:z())
	-- 	:scale(2)
	-- 	:addTo(self:getResourceNode())
	-- self.normalBg2 = ccui.ImageView:create("city/gate/bg_cj1_2.png")
	-- 	:anchorPoint(0, 0)
	-- 	:xy(display.sizeInView.width/2, 0)
	-- 	:z(self.imgBG:z())
	-- 	:scale(2)
	-- 	:addTo(self:getResourceNode())
	-- idlereasy.when(self.mapType, function(_, mapType)
	-- 	self.imgBG:visible(mapType ~= 1)
	-- 	self.normalBg1:visible(mapType == 1)
	-- 	self.normalBg2:visible(mapType == 1)
	-- end)
end

-- 允许无参数的 selEffect初始化
function GateView:setSelEffect(item, pos)
	if not self.selEffect then
		self.selEffect = CSprite.new("level/xuanguan.skel")
		self.selEffect:play("effect_loop")
		self.selEffect:visible(false)
		self.selEffect:retain()
	end

	if item and pos and self.selEffect then
		self.selEffect:removeFromParent()
		self.selEffect:addTo(item, 100, "selEffect")
		self.selEffect:xy(pos)
		self.selEffect:retain()
		return self.selEffect
	end
end

function GateView:initModel(typ, gateId, chapterId)
	-- self.worldOpen = gGameModel.role:getIdler("world_open") -- 开放的世界地图列表
	self.mapOpen = gGameModel.role:getIdler("map_open") -- 开放的章节地图列表 -- 现在吧key当成是chapterId
	self.gateOpen = gGameModel.role:getIdler("gate_open") -- 开放的关卡列表
	self.gateStar = gGameModel.role:getIdler("gate_star") -- 星星数量
	self.level = gGameModel.role:getIdler("level") -- 等级
	self.mapStar = gGameModel.role:getIdler("map_star")
	self.captOpen = gGameModel.capture:getIdler("gate_sprites")
	self.limitDatas = gGameModel.capture:getIdler("limit_sprites")
	self.worldLevel = gGameModel.global_record:getIdler("world_level")--世界等级
	self.roleLevel = gGameModel.role:getIdler("level")		--自身等级

	self.levelDatas = idlers.newWithMap({})							-- 关卡细节信息
	self.mapType = idler.new(typ)							-- 1:剧情 2:困难 默认选中剧情
	self.selGateIdx = {gateId = gateId, chapterId = chapterId}		-- 当前关卡信息
	self.curPageIdx = chapterId
	self.pageIdler = idler.new(self.curPageIdx)						-- 当前属于 第几章 与实际章节ID意义不同
	self.chapterId = idler.new(0)
	self.captureShow = idler.new(false)
end

function GateView:setRedHint()
	bind.extend(self, self.btnRight, {
		class = "red_hint",
		props = {
			specialTag = "levelRightBtnGift",
			listenData = {
				chapterId = bindHelper.self("chapterId"),
				mapType = bindHelper.self("mapType"),
			},
			onNode = function (panel)
				panel:xy(panel:x() - 66, panel:y() - 5)
			end
		},
	})
	bind.extend(self, self.btnLeft, {
		class = "red_hint",
		props = {
			specialTag = "levelLeftBtnGift",
			listenData = {
				chapterId = bindHelper.self("chapterId"),
				mapType = bindHelper.self("mapType"),
			},
			onNode = function (panel)
				panel:xy(panel:x() - 66, panel:y() - 5)
			end
		},
	})
	bind.extend(self, self.btnJuQing, {
		class = "red_hint",
		props = {
			specialTag = "levelBtnJuQingGift",
			listenData = {
				chapterId = bindHelper.self("chapterId"),
				mapType = bindHelper.self("mapType"),
			},
			onNode = function (panel)
				panel:x(panel:x() - 30)
				panel:y(panel:y() - 30)
			end
		},
	})
	bind.extend(self, self.btnKunNan, {
		class = "red_hint",
		props = {
			specialTag = "levelBtnKunNanGift",
			listenData = {
				chapterId = bindHelper.self("chapterId"),
				mapType = bindHelper.self("mapType"),
			},
			onNode = function (panel)
				panel:x(panel:x() - 30)
				panel:y(panel:y() - 30)
			end
		},
	})
	bind.extend(self, self.btnNightmare, {
		class = "red_hint",
		props = {
			specialTag = "levelBtnNightMareGift",
			listenData = {
				chapterId = bindHelper.self("chapterId"),
				mapType = bindHelper.self("mapType"),
			},
			onNode = function (panel)
				panel:x(panel:x() - 30)
				panel:y(panel:y() - 30)
			end
		},
	})

	bind.extend(self, self.limitCapture, {
		class = "red_hint",
		props = {
			showType = "new",
			specialTag = "limitCapture",
			listenData = {
				captureShow = bindHelper.self("captureShow"),
			},
			onNode = function (panel)
				panel:scale(0.5)
				panel:xy(self.limitCapture:size().width, self.limitCapture:size().height-12)
			end
		},
	})
end

function GateView:refreshData(_type)
	local data = userDefault.getForeverLocalKey("isEnterLevelFirst", {})
	local isFirstEnter = data[_type] ~= false
	local world_mapCsv = csv.world_map
	local levelDatas = {}
	local allGateStar = self.gateStar:read()
	for pageId, cId in ipairs(self.chapterOpen[_type] or {}) do
		local chapterInfo = world_mapCsv[cId]
		local baseMap = chapterInfo.baseMap
		if not chapterInfo.isWorldEnter
			and chapterInfo.chapterType == self.mapType:read()
			and self.level:read() >= chapterInfo.openLevel then
			local isShow = false
			if self.selGateIdx.chapterId ~= 0 then
				isShow = self.selGateIdx.chapterId == pageId
			end
			local seq = table.deepcopy(world_mapCsv[cId].seq, true)
			local starInfo = {}
			local isCompleted = true 	--当前章节是否通关
			for _, gateId in ipairs(seq) do
				starInfo[gateId] = allGateStar[gateId]
				local star = 0
				if allGateStar[gateId] then
					star = allGateStar[gateId].star or 0
				end
				if star == 0 then
					isCompleted = false
				end
			end
			local params = {
				baseMap = baseMap,
				pageId = pageId,
				chapterId = cId,
				seq = seq,
				isShow = isShow,
				selGateId = self.selGateIdx.gateId,
				starInfo = starInfo,
				isFirstEnter = isFirstEnter,
				levelType = _type,
				battleData = self.battleData,
				showSelectedIcon = true,
				isCompleted = isCompleted
			}
			table.insert(levelDatas, params)
		end
	end
	table.sort(levelDatas, function(a, b)
		return a.pageId < b.pageId
	end)

	if #levelDatas <= 0 then
		return
	end

	local count = #levelDatas
	local isResetPageIdler = false
	if self.curPageIdx == 0 then
		levelDatas[count].isShow = true
		self.curPageIdx = count
		isResetPageIdler = true
	end
	local t = self.gateOpen:read()
	local seqData = levelDatas[count].seq
	for i = #seqData, 1, -1 do
		local gateId = seqData[i]
		local nightmarePass = false
		if _type == MAP_TYPE.nightmare then
			local nextGateId = seqData[i - 1]
			if i == 1 then
				nightmarePass = true -- 固定开启
			elseif itertools.include(t, nextGateId) and allGateStar[gateId] then
				nightmarePass = true -- 固定开启
			end
		end

		if itertools.include(t, gateId) or nightmarePass then
			if self.selGateIdx.gateId == 0 then
				levelDatas[count].selGateId = gateId
				levelDatas[count].pageId = count
			end
			break
		end
		table.remove(seqData)
	end
	-- 战斗回来开放下一章节
	local nextChapterIdx = math.min(self.curPageIdx + 1, count)
	if self:isNeedPlayAction(nextChapterIdx, levelDatas) then
		-- 需要播放动画后移动到的目标页签
		self.nextPageIdx = nextChapterIdx
		levelDatas[nextChapterIdx].isPlayAnimation = true
	end
	self.levelDatas:update(levelDatas)
	if isResetPageIdler then
		self.pageIdler:set(count, true)		-- 直接进入可进入的最后一章
	else
		self.pageIdler:notify()
	end
end

-- nextChapterIdx 下章节pageOID
function GateView:isNeedPlayAction(nextChapterIdx, data)
	local seqData = data[nextChapterIdx].seq
	if nextChapterIdx > 1 and #seqData == 1 and (not self.gateStar:read()[seqData[1]]) then
		-- 上一章的最后一个关卡id等于战斗过的id 并且战斗之前是0星
		local lastChapterSeq = data[nextChapterIdx - 1].seq
		local fightGateId = lastChapterSeq[#lastChapterSeq]
		local gateStar = self.gateStar:read()
		local curStar = gateStar[fightGateId] and gateStar[fightGateId].star
		if fightGateId == tonumber(self.battleData.gateId) and
			(curStar - (tonumber(self.battleData.starAdd) or 0)) == 0 then
			return true
		end
	end

	return false
end

function GateView:onInitPage(pageview, list, node, k, v)
	if not v.isShow then
		return
	end
	local csvData = csv.scene_conf
	local curMapType = self.mapType:read()
	local curMapInfo = ITEM_SET_INFO[curMapType] or ITEM_SET_INFO[MAP_TYPE.hero]
	local tmp = curMapInfo.getItem(self)
	if self.nextPageIdx then
		node:get("topView"):visible(true)
	else
		node:get("topView"):visible(false)
	end
	local battleId = tonumber(v.battleData.gateId)
	local isShowEffect = false -- 下一个关卡是否要播放动画
	local csvSeq = csv.world_map[v.chapterId].seq
	local allNum = csvSize(csvSeq)
	local boxIdx = 0				-- box序号
	for idx, gateId in ipairs(v.seq) do
		local itemName = "gate" .. idx
		local item = node:get(itemName)
		local info = csvData[gateId]
		if not item then
			item = tmp:clone()
			node:addChild(item, 10, itemName)
			item:visible(true)
			bind.touch(list, item, {methods = {ended = functools.partial(list.clickGateItem, k, v, gateId)}})

			item:xy(info.pos.x + self.off, info.pos.y)
			node:get("imgBG"):texture(v.baseMap)

			local isPlayAction = isShowEffect or v.isPlayAnimation				-- 本次需要播放动画

			local starInfo = v.starInfo[gateId] or {}
			local starNum = starInfo.star or 0
			local starAdd = (battleId == gateId) and tonumber(v.battleData.starAdd) or 0

			isShowEffect = canShowEffect(battleId, gateId, starAdd, starNum)

			isPlayAction = canPlayAction(v, idx, k, starNum) or isPlayAction

			-- 播放路点相关
			local pathPointes = getAllPassPoints(node, info, self.off)
			for i,point in ipairs(pathPointes) do
				performWithDelay(node, function()
					point:visible(true)
				end, isPlayAction and (0.3 + i * 0.2) or 0)
			end

			-- 播放宝箱相关
			local function playBoxAni(pos, boxName, state)
				local box = self.box:clone()
					:xy(pos)
					:name(boxName)
					:visible(false)
					:addTo(node, 100)

				-- -1表示未达成 1表示可领取 0表示已领
				if state == 0 then
					box:get("imgBox"):texture("common/icon/icon_open_bx.png")
				end
				bind.touch(list, box, {methods = {ended = functools.partial(list.clickBox, gateId, info.chestAward, idx)}})
				addVibrateToNode(list, box, state == 1, idx, gateId)

				return box
			end
			if info.awardPos and starNum > 0 then
				boxIdx = boxIdx + 1
				local awardBox = playBoxAni(cc.p(info.awardPos.x + self.off, info.awardPos.y), "box" .. boxIdx, starInfo.chest)

				performWithDelay(node, function()
					awardBox:visible(true)
				end, isPlayAction and gCommonConfigCsv.levelBoxDelayTime or 0)
			end

			-- 播放星星相关
			if isPlayAction then
				-- 关掉静态的星星图片
				for i=1, 3 do
					item:get("imgStar"..i):visible(false)
				end
			end
			playStarAni(item, starNum, starAdd, curMapInfo)

			-- 播放item相关
			local allPointTime = 0.3 + 0.2 * #pathPointes		-- 路点所花时间
			local setItemFunc = curMapInfo.setItemFunc								-- 设置Item所调用的函数

			-- 其余延时时间
			local delayTime = setItemFunc(item, info, node, isPlayAction, allPointTime, idx == allNum)

			-- 播放标记点相关
			local function setSelEffect()
				local selIconPos = curMapInfo.selIconPos(info.icon)
				if not info.icon then
					item:get("spePanel"):visible(false)
				end
				if v.selGateId == gateId then
					local effect = item:getChildByName("selEffect") or self:setSelEffect(item, selIconPos)
					effect:visible(true)
				end
				if curMapType == MAP_TYPE.normal and not info.icon then
					item:get("imgIcon"):visible(true)
				end
				v.showSelectedIcon = true
				item:get("textLvNum"):text(v.pageId .. "-" .. idx)
				item:setTouchEnabled(true)
				if self.nextPageIdx and tonumber(self.battleData.gateId) == gateId then
					performWithDelay(item, function()
						self.levelDatas:atproxy(self.nextPageIdx).isShow = true
						self.pageIdler:modify(function(val)
							val = cc.clampf(val + 1, 1, self.levelDatas:size())
							return true, val
						end)
						node:get("topView"):visible(false)
						self.nextPageIdx = nil
					end, 0.5)
				end
			end
			if delayTime == 0 then
				setSelEffect()
			else
				performWithDelay(node, setSelEffect, delayTime + allPointTime)
			end
			if starNum > 0 then
				local cfgID = gGateCaptureCsv[gateId]
				--捕捉入口精灵
				if cfgID then
					dataEasy.getListenUnlock(gUnlockCsv.gateCapture, function(isUnlock)
						if isUnlock and self.captOpen and not self.captOpen:read()[cfgID] then
							node:removeChildByName("captureEnter" .. gateId)
							local cfg = csv.capture.sprite[cfgID]
							local unitCfg = csv.unit[csv.cards[cfg.cardID].unitID]
							local captureItem = self.capture:clone()
								:visible(true)
								:xy(cfg.gatePos.x + self.off, cfg.gatePos.y)
								:addTo(node, 100, "captureEnter" .. gateId)
							captureItem:get("imgIcon"):texture(unitCfg.iconSimple)
							bind.touch(list, captureItem, {methods = {ended = functools.partial(list.captureClick, cfgID, cfg, captureItem)}})
						end
					end):anonyOnly(list, "onInitPage"..k)
				end
			end
		elseif v.showSelectedIcon and v.selGateId == gateId then
			local effect = item:getChildByName("selEffect")
			if not effect then
				local selIconPos = curMapInfo.selIconPos(info.icon)
				effect = self:setSelEffect(item, selIconPos)
			end
			effect:visible(true)
		end
	end
end

function GateView:onClickCapture(list, k, v, node)
	local parms = {captureData = v, captureID = k, node = node}
	gGameUI:stackUI("city.capture.capture_entrace", nil, nil, parms)
end

function GateView:onRefreshStarNum()
	local starTab = self.gateStar:read()
	local allNum = 0
	local hasNum = 0
	local seq = csv.world_map[self.levelDatas:atproxy(self.pageIdler:read()).chapterId].seq
	for _,v in ipairs(seq) do
		local starInfo = starTab[v] or {}
	 	hasNum = hasNum + (starInfo.star or 0)
	 	allNum = allNum + 3
	end
	self.textStarNum:text(hasNum.."/"..allNum)
end

function GateView:onChangeJuQing(node, event)
	self.curPageIdx = 0
	self.mapType:set(MAP_TYPE.normal)
end

function GateView:onChangeKunNan(node, event)
	self.curPageIdx = 0
	self.mapType:set(MAP_TYPE.hero)
end

function GateView:onChangeNightmare(node, event)
	self.curPageIdx = 0
	self.mapType:set(MAP_TYPE.nightmare)
end

-- 判断查询的章节 是否开启了前置条件 没开则检查是否需要开启前置条件
function GateView:checkPreGateIsPass(curChapterCsvId, isTips)
	-- 检查章节 开启条件
	local preChapterId = gNightmareForCsv[curChapterCsvId]
	if preChapterId then
		local preMapCsv = csv.world_map[preChapterId]
		if not itertools.include(self.chapterOpen[preMapCsv.chapterType], preChapterId) then
			local fmt = {
				[MAP_TYPE.normal] = gLanguageCsv.pleasePassGateNormal,
				[MAP_TYPE.hero] = gLanguageCsv.pleasePassGateDifficult,
				[MAP_TYPE.nightmare] = gLanguageCsv.pleasePassGateNightMare,
			}
			if isTips then
				gGameUI:showTip(string.format(fmt[preMapCsv.chapterType], preChapterId - CHAPTER_NUM[preMapCsv.chapterType]))
			end
			return false
		end
	else
		local curMapType = self.mapType:read()
		return curMapType ~= MAP_TYPE.nightmare
	end

	return true
end

function GateView:checkChapterOpen(chapterId)
	local chapterCsvId = self:getCsvIByChapterId(chapterId)
		--关卡存在判断
	if not chapterCsvId then
		return false
	end
	--等级判断
	local mapCsv = csv.world_map[chapterCsvId]
	local openLv = mapCsv.openLevel
	if self.level:read() < openLv then
		gGameUI:showTip(string.format(gLanguageCsv.levelUnLock, openLv))
		return false
	end

	-- 检查前置关卡是否开启
	if not self:checkPreGateIsPass(chapterCsvId, true) then
		return false
	end

	-- 当前章节通关判断
	local isCompleted = self.levelDatas:atproxy(math.max(1, chapterId - 1)).isCompleted
	-- local isCompleted = self.levelDatas:atproxy(self.curPageIdx).isCompleted
	if isCompleted == false then
		gGameUI:showTip(gLanguageCsv.pleasePassCurPage)
		return false
	end
	-- 普通关卡通关条件判断
	if chapterId > #self.chapterOpen[1] then
		gGameUI:showTip(gLanguageCsv.pleasePassNormalCurPage)
		return false
	end
	return true
end
function GateView:onMoveRight(node, event)
	self.pageIdler:modify(function(old)
		local targetIdx = old + 1
		if self:checkChapterOpen(targetIdx) then
			return true, targetIdx
		else
			return false
		end
	end)
end

function GateView:onMoveLeft(node, event)
	self.pageIdler:modify(function(val)
		local targetIdx = val - 1
		val = cc.clampf(targetIdx, 1, self.levelDatas:size())
		return true, val
	end)
end

function GateView:onAfterBuild(list)
	list:setCurPageIndex(self.curPageIdx - 1)
	local chapterInfo = self.levelDatas:atproxy(self.curPageIdx)
	local gateId = chapterInfo.selGateId
	local chapterId = chapterInfo.chapterId
	local chapterString = string.format(gLanguageCsv.levelChapterId, self.curPageIdx)..csv.world_map[chapterId].name
	if matchLanguage({"en"}) then
		chapterString = string.format(gLanguageCsv.levelChapterId, self.curPageIdx).." "..csv.world_map[chapterId].name
	end
	gGameUI.topuiManager:updateTitle(chapterString)
end

function GateView:onClickGateItem(node, idx, data, gateId, pageview, layout)
	self.levelDatas:atproxy(idx).selGateId = gateId
	self.selGateIdx.gateId = gateId
	gGameUI:stackUI("city.gate.section_detail.view", nil, nil, gateId, data.pageId)
end

function GateView:onEnterStarBox()
	gGameUI:stackUI("city.gate.section_detail.box", nil, nil, self.levelDatas:atproxy(self.pageIdler:read()).chapterId)
end

-- -1表示未达成 1表示可领取 0表示已领
function GateView:onClickBox(node, gateId, rewards, k, pageView, btn, event)
	local state = self.gateStar:read()[gateId].chest
	if state == -1 then
		return
	end
	if state == 1 then
		local showOver = {false}
		gGameApp:requestServerCustom("/game/role/gate/award")
			:params(gateId, "chest")
			:onResponse(function()
				btn:get("imgBox"):texture("common/icon/icon_open_bx.png")
				uiEasy.setBoxEffect(btn, 1, function()
					showOver[1] = true
				end)
				addVibrateToNode(node, btn, false, k, gateId)
			end)
			:wait(showOver)
			:doit(function(tb)
				gGameUI:showGainDisplay(tb)
			end)
		return
	end

	gGameUI:showBoxDetail({
		data = rewards,
		content = "",
		state = state,
		btnText = gLanguageCsv.received,
	})
end

function GateView:onSaveLevel(node, event)
	-- 二期功能
	gGameUI:stackUI("city.gate.quick_like", nil, nil, nil)
end

--捕捉玩法常驻按钮点击回调
function GateView:onClickResidentCapture(node, event)
	gGameUI:stackUI("city.capture.capture_limit", nil, nil, self:createHandler("removeNewRedHint"))
end

function GateView:removeNewRedHint(flag)
	self.captureShow:set(flag)
end

function GateView:onCleanup()
	if self.selEffect then
		self.selEffect:release()
		self.selEffect = nil
	end
	self._mapType = self.mapType:read()
	self._curPageIdx = self.pageIdler:read()
	ViewBase.onCleanup(self)
end

function GateView:cloudAnimation(mapType)
	local pnode = self:getResourceNode()
	local cloudTime = 37/30

	local cloudType = "jq"
	if mapType == MAP_TYPE.hero then
		cloudType = "kn"
	elseif mapType == MAP_TYPE.nightmare then
		cloudType = "em"
	end
	self.sun:visible(cloudType == "em")

	for i=1,6 do
		self['cloud'..i]:texture("city/gate/img_cloud"..i.."_"..cloudType..".png")
		self['cloud'..i]:xy(self.cloudInitPos[i].x, self.cloudInitPos[i].y)
	end
	self.sun:xy(self.sunInitPos.x, self.sunInitPos.y)
	self.cloud3:z(2)
	self.cloud4:z(2)


	transition.executeSequence(self.cloud1, true)
		:moveTo(cloudTime, (pnode:width()- display.maxWidth)/2, display.height)
		:done()
	transition.executeSequence(self.cloud2, true)
		:moveTo(cloudTime, pnode:width()/2 + display.maxWidth/2, display.height)
		:done()
	transition.executeSequence(self.cloud3, true)
		:moveTo(cloudTime, pnode:width()/2 + display.maxWidth/2, 0)
		:done()
	transition.executeSequence(self.cloud4, true)
		:moveTo(cloudTime, (pnode:width()- display.maxWidth)/2, 0)
		:done()
	transition.executeSequence(self.cloud5, true)
		:moveTo(cloudTime, (pnode:width()- display.maxWidth)/2, display.height)
		:done()
	transition.executeSequence(self.cloud6, true)
		:moveTo(cloudTime, pnode:width()/2 + display.maxWidth/2, display.height)
		:done()

	if mapType == MAP_TYPE.nightmare then
		transition.executeSequence(self.sun, true)
			:moveTo(cloudTime, pnode:width()/2, display.height-20)
			:done()
	end
end

return GateView