-- @date:   2019-10-29 11:23:00
-- @desc:   成长向导

local STATE = {
	lock = 1,
	doing = 2,
	get = 3,
}

local ITEMTYPE = {
	reward = 1,
	task = 2
}

local GrowGuideView = class("GrowGuideView", Dialog)

GrowGuideView.RESOURCE_FILENAME = "grow_guide.json"
GrowGuideView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["rightTop"] = "rightTop",
	["rightBall"] = "rightBall",
	["rightCenter"] = "rightCenter",
	["rightCenter.imgTitleBg"] = "rightCenterTitleBg",
	["rightCenter.textNote"] = "rightCenterTextNote",
	["rightDown"] = "rightDown",
	["item"] = "item",
	["list"] = {
		varname = "mainlist",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("item"),
				enterLv = bindHelper.self("enterLv"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local size = cc.size(1040, 216)
					local bgPath = "common/box/box_pop_panel4.png"
					if v.isSel then
						bgPath = "common/box/box_select.png"
						size = cc.size(1062, 240)
					end
					node:get("imgBg"):texture(bgPath)
					node:get("imgBg"):size(size)
					node:get("imgIcon"):texture(v.cfg.icon)
					node:get("textName"):text(v.cfg.name)
					node:get("textNote"):text(v.cfg.desc)
					node:removeChildByName("effect")
					node:removeChildByName("effect2")
					local typePath = "city/grow_guide/logo_gn.png"
					local txt = gLanguageCsv.textReward
					if v.cfg.type == ITEMTYPE.task then
						typePath = "city/grow_guide/logo_jl.png"
						txt = gLanguageCsv.task
					end
					node:get("type.imgtype"):texture(typePath)
					node:get("type.textType"):text(txt)
					node:get("type.imgtype"):width(node:get("type.textType"):width() + 43)
					node:get("lock"):visible(v.state == STATE.lock)
					node:get("doing"):hide()
					node:get("imgGet"):visible(false)
					local cfg = csv.unlock[gUnlockCsv[v.cfg.feature]]
					if v.state == STATE.lock then
						local roleLevel = gGameModel.role:read("level") or 0
						if roleLevel >= cfg.startLevel then
							if v.serverDay then
								node:get("lock.textState"):text(string.format(gLanguageCsv.unlockServerOpen, v.serverDay))
							else
								local _type, chapterId, gateId, title = dataEasy.getChapterInfoByGateID(cfg.startGate)
								local string = string.format(gLanguageCsv.needUnlockGate, title, chapterId, gateId)
								node:get("lock.textState"):text(string)
							end
						else
							node:get("lock.textState"):text(string.format(gLanguageCsv.arrivalLevelOpen, cfg.startLevel))
						end
					end
					local jiesuoEffect
					if v.state ~= STATE.lock and cfg.startLevel >= list.enterLv:read() + 1 and not v.skel then -- v.skel用于判断是否播放过激活特效，如果播放过，就不再创建，jiesuoEffect存在，但不播放，无法监听播放完成，无法执行回调
						jiesuoEffect = widget.addAnimationByKey(node, "effect/hongjiesuo.skel", "effect", "effect", 2)
							:xy(size.width - 120, size.height / 2)
						v.skel = true
					end
					local size = node:size()
					local effect2 = widget.addAnimationByKey(node, "effect/kelingqu.skel", "effect2", "effect_loop", 2)
						:xy(size.width - 170, size.height / 2)
						:hide()
					local function cb()
						node:get("doing"):visible(v.state == STATE.doing)
						if v.state == STATE.get then
							performWithDelay(node, function()
								node:removeChildByName("effect")
								effect2:show()
							end, 1/60)
						end
					end
					if jiesuoEffect then 	-- 如果有激活特效需要播放，监听激活特效是否播放完成后，再显示相关信息
						jiesuoEffect:setSpriteEventHandler(function(event, eventArgs)
							cb()
						end, sp.EventType.ANIMATION_COMPLETE)
					else
						cb()
					end
					bind.touch(list, node, {methods = {
						ended = functools.partial(list.clickCell, k, v)
					}})
				end,
				asyncPreload = 5,
				preloadCenter = bindHelper.self("interIdx"),
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["rightTop.rewardPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowReward"),
		},
	},
	["item2"] = "item2",
	["rightTop.rewardPanel.list"] = {
		varname = "itemList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightItems"),
				item = bindHelper.self("item2"),
				onItem = function(list, node, k, v)
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v,
							},
							onNode = function(panel)
								panel:scale(0.8)
							end,
						},
					}
					bind.extend(list, node, binds)
				end,
			},
		},
	},
	["item1"] = "item1",
	["rightDown.list"] = {
		varname = "rewardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightReward"),
				item = bindHelper.self("item1"),
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
	["btnGet"] = {
		varname = "btnGet",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGetReward")}
		},
	},
	["rightTop.goto.textNote1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 8}}
		},
	},
	["rightTop.goto.textNote2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 8}}
		},
	},
	["rightTop.goto"] = {
		varname = "gotoPanel",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onJump")}
			},
			{
				event = "visible",
				idler = bindHelper.self("needJump"),
			},
		},
	},
	["rightTop.imgTitleBg"] = "rightTopTitleBg",
	["rightTop.textNote"] = {
		varname = "rightTopTextNote",
		binds = {
			event = "text",
			idler = bindHelper.self("textTitle"),
		},
	},
	["rightDown.imgTitleBg"] = "rightDownTitleBg",
	["rightDown.textNote"] = {
		varname = "rightDownTextNote",
		binds = {
			event = "text",
			idler = bindHelper.self("rewardTitle"),
		},
	},
}

function GrowGuideView:onCreate(idx)
	idx = idx or 1
	self:initModel()
	self.textTitle = idler.new("")
	self.rewardTitle = idler.new("")
	self.needJump = idler.new(false)
	self.interIdx = idler.new(idx)
	self.enterLv = idler.new(userDefault.getForeverLocalKey("entreGrowGuideLv", 0))
	idlereasy.when(self.level, function(_, level)
		userDefault.setForeverLocalKey("entreGrowGuideLv", self.level:read())
	end)
	local mask1 = ccui.Scale9Sprite:create()
	mask1:initWithFile(cc.rect(50, 50, 1, 1), "city/grow_guide/mask_czxd_ball.png")
	mask1:size(cc.size(1120, 1120))
	local logoClipping1 = cc.ClippingNode:create(mask1)
		:setAlphaThreshold(0.1)
		:alignCenter(self.rightBall:size())
		:addTo(self.rightBall)
	ccui.ImageView:create("common/bg/bg_icon@.png")
		:scale(1.8)
		:xy(360, -430)
		:setRotation(-34.72)
		:setOpacity(46)
		:addTo(logoClipping1)


	self.rightItems = idlers.newWithMap({})
	self.rightReward = idlers.newWithMap({})
	self.isShowReward = idler.new(false)
	self.selIdx = idler.new(idx)
	self.itemDatas = idlers.newWithMap({})
	local firstGrowGuide = true -- 第一次刷新列表，第二次开始，enterLv改为上次存储level

	local growGuideListen = {self.growGuide}
	for _, v in ipairs(gGrowGuideCsv) do
		table.insert(growGuideListen, dataEasy.getListenUnlock(v.feature))
	end
	idlereasy.any(growGuideListen, function(_, growGuide, ...)
		local unlocks = {...}
		if not firstGrowGuide then
			self.enterLv:set(userDefault.getForeverLocalKey("entreGrowGuideLv", 0))
		else
			firstGrowGuide = false
		end
		local itemDatas = {}
		self.count = 0
		local unlockOrder = 0
		for _, v in ipairs(gGrowGuideCsv) do
			local csvId = v.id
			unlockOrder = unlockOrder + 1
			if not growGuide[csvId] or growGuide[csvId][1] ~= 0 then
				self.count = self.count + 1
				local data = {}
				data.cfg = v
				data.csvId = csvId
				-- data.isSel = count == selIdx
				local state = STATE.doing
				if growGuide[csvId] and growGuide[csvId][1] == 1 then
					state = STATE.get
				elseif not unlocks[unlockOrder] then
					state = STATE.lock
				end
				-- 石英大会需要判断开服时间
				if v.feature == "craft" and state ~= STATE.lock then
					local state1, day = dataEasy.judgeServerOpen("craft")
					if not state1 and day then
						state = STATE.lock
						data.serverDay = day
					end
				end
				data.state = state
				table.insert(itemDatas, data)
			end
		end
		table.sort(itemDatas, function(a, b)
			local csvTab = csv.unlock
			local cfgA = csvTab[gUnlockCsv[a.cfg.feature]]
			local unLockLvA = cfgA.startLevel
			local cfgB = csvTab[gUnlockCsv[b.cfg.feature]]
			local unLockLvB = cfgB.startLevel
			if unLockLvA ~= unLockLvB then
				return unLockLvA < unLockLvB
			end
			return a.csvId < b.csvId
		end)
		dataEasy.tryCallFunc(self.mainlist, "updatePreloadCenterIndex")
		self.itemDatas:update(itemDatas)
		if self.count ~= 0 then
			local curIdx = math.min(self.count, self.selIdx:read())
			self.selIdx:set(curIdx, true)
		end
	end)
	self.selIdx:addListener(function(val, oldval)
		if self.itemDatas:atproxy(oldval) then
			self.itemDatas:atproxy(oldval).isSel = false
		end
		self.itemDatas:atproxy(val).isSel = true
		self:initRightPanel(val)
	end)
	local size = self.gotoPanel:size()
	widget.addAnimationByKey(self.gotoPanel, "effect/jiantou.skel", "efc1", "effect_loop", 6)
		:xy(size.width / 2 - 60, size.height / 2)

	Dialog.onCreate(self)
end

function GrowGuideView:initModel()
	--  {csv_id: (flag, count)} flag=1可领取, flag=0已领取
	-- count 就是对应的任务计数，如果是奖励的话，count就为0
	self.growGuide = gGameModel.role:getIdler("grow_guide")
	self.level = gGameModel.role:getIdler("level")
end

function GrowGuideView:initRightPanel(val)
	local data = self.itemDatas:atproxy(val)
	self.needJump:set(data.state ~= STATE.lock and data.cfg.goto ~= nil)
	self.textTitle:set(data.cfg.name)
	self.rightTopTextNote:text(data.cfg.name)
	local clippingNode = self.rightTop:getChildByName("clippingNode")
	if not clippingNode then
		-- clippingNode
		local mask = ccui.Scale9Sprite:create()
		mask:initWithFile(cc.rect(50, 50, 1, 1), "city/grow_guide/mask_czxd1.png")
		mask:size(cc.size(1058, 488))
		clippingNode = cc.ClippingNode:create(mask)
			:setAlphaThreshold(0.1)
			:alignCenter(self.rightTop:size())
			:addTo(self.rightTop, 2, "clippingNode")
	end
	clippingNode:removeChildByName("logo")
	ccui.ImageView:create(data.cfg.res)
		:scale(2)
		:addTo(clippingNode, 1, "logo")

	self.rightItems:update(data.cfg.items)
	self.isShowReward:set(itertools.size(data.cfg.items) > 0)
	local reward = {}
	for k,v in csvMapPairs(data.cfg.award) do
		local t = {}
		t.key = k
		t.num = v
		table.insert(reward, t)
	end
	self.rightReward:update(reward)
	self.rightCenter:hide()
	local y = 360
	local rewardTitle = gLanguageCsv.unLockReward
	if data.cfg.type == ITEMTYPE.task then
		rewardTitle = gLanguageCsv.taskReward
		local count = (self.growGuide:read()[data.csvId] or {})[2] or 0
		local str = string.format(data.cfg.taskDesc .. "(%s/%s)", count,data.cfg.taskParam)
		self.rightCenter:get("textContent"):text(str)
		self.rightCenter:show()
		y = 290
	end
	self.rewardTitle:set(rewardTitle)
	self.rightDown:y(y)
	local shader = data.state == STATE.get and "normal" or "hsl_gray"
	cache.setShader(self.btnGet, false, shader)
	self.rightTopTitleBg:width(self.rightTopTextNote:width() / self.rightTopTitleBg:scale() + 60)
	self.rightCenterTitleBg:width(self.rightCenterTextNote:width() / self.rightCenterTitleBg:scale() + 60)
	self.rightDownTitleBg:width(self.rightDownTextNote:width() / self.rightDownTitleBg:scale() + 60)
end

function GrowGuideView:onGetReward()
	local data = self.itemDatas:atproxy(self.selIdx:read())
	if data.state ~= STATE.get then
		return
	end
	gGameApp:requestServer("/game/role/growguide/award/get", function(tb)
		if self.count == 0 then
			gGameUI:showGainDisplay(tb, {cb = function ()
				self:onClose()
			end})
		else
			gGameUI:showGainDisplay(tb)
		end
	end, data.csvId)
end

function GrowGuideView:onJump()
	local data = self.itemDatas:atproxy(self.selIdx:read())
	jumpEasy.jumpTo(data.cfg.goto)
end

function GrowGuideView:onItemClick(list, k, v)
	self.selIdx:set(k)
end

return GrowGuideView