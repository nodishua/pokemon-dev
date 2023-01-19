--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- UI界面相关全局函数
--
local rectContainsPoint = cc.rectContainsPoint

local uiEasy = {}
globals.uiEasy = uiEasy


-- @desc 判断 point 是否在 obj 内
function uiEasy.isContainsWorldPoint(obj, point)
	if not obj or not point then
		return false
	end
	local rect = obj:box()
	local pos = obj:parent():convertToWorldSpace(cc.p(rect.x, rect.y))
	rect.x, rect.y = pos.x, pos.y
	if rectContainsPoint(rect, point) then
		return true
	end
end

-- @desc 通用设置(名字+x)和颜色
-- @param params {name, advance, space, [node], [noColor], width}
function uiEasy.setIconName(key, num, params)
	params = params or {}
	local quality = 1
	local name, numStr = "", ""
	local effect = nil
	if key == "card" then
		local advance = params.advance or 1
		local cardId = dataEasy.getCardIdAndStar(num)
		local cardCfg = csv.cards[cardId]
		quality, numStr = dataEasy.getQuality(advance, params.space)
		if params.name then
			if type(params.name) == "table" then
				name = gLanguageCsv[params.name[quality]]

			elseif params.name == "" then
				name = cardCfg.name
			else
				name = params.name
			end
		else
			name = cardCfg.name
		end
		name = name .. numStr

	elseif key == "explore" then
		local advance = params.advance or 1
		quality, numStr = dataEasy.getQuality(advance, params.space)
		local exploreCfg = csv.explorer.explorer[num]
		if params.name then
			if type(params.name) == "table" then
				name = gLanguageCsv[params.name[quality]]
			elseif params.name == "" then
				name = exploreCfg.name
			else
				name = params.name
			end
		else
			name = exploreCfg.name
		end
		name = name .. numStr

	elseif string.find(key, "star_skill_points_%d+") then
		-- 极限点
		local markId = tonumber(string.sub(key, string.find(key, "%d+")))
		name = csv.cards[markId].name .. gLanguageCsv.starSkill
	else
		local cfg = dataEasy.getCfgByKey(key)
		if not cfg then return end
		quality = cfg.quality
		name = cfg.name
		if dataEasy.isHeldItem(key) and params.advance and params.advance > 0 then
			name = name .. string.format("%s+%s", params.space and " " or "", params.advance)
		end
	end
	effect = {color=ui.COLORS.QUALITY_OUTLINE[quality]}
	if params.node then
		params.node:text(name)
		if not params.noColor then
			text.addEffect(params.node, effect)
		end
		if params.width then
			if params.node:width() > params.width then
				local anchor = params.node:anchorPoint()
				local nodeHeight = params.node:height()
				local nodeY = params.node:y()
				local offsetY = (1 - anchor.y) * nodeHeight
				params.node:anchorPoint(anchor.x, 1)
				params.node:y(nodeY + offsetY)
				adapt.setTextAdaptWithSize(params.node, {size = cc.size(params.width, nodeHeight*3), vertical = "top"})
			end
		end
	end
	return name, effect
end

-- @desc 获取卡牌品质颜色名
function uiEasy.getCardName(cardDbId)
	local card = gGameModel.cards:find(cardDbId)
	local cardId = card:read('card_id')
	local advance = card:read("advance")
	local quality, nameStr = dataEasy.getQuality(advance)
	local color = ui.QUALITY_OUTLINE_COLOR[quality]
	local name = csv.cards[cardId].name
	return string.format("%s%s%s", color, name, nameStr)
end

-- @desc 获取通用描述，fragment 要读取 combCount
function uiEasy.getIconDesc(key, num)
	local desc = ""
	local cfg = dataEasy.getCfgByKey(key)
	if dataEasy.isFragment(key) then
		desc = string.format(cfg.desc, cfg.combCount)
	else
		desc = cfg.desc
	end
	return desc
end

-- @param data: 自动识别配置数据 {key = num, __size = N} 或排序过的数据 {{key="card", num=1}, {key=11, num=1}, ...}
-- @param params: {scale, margin, onAfterBuild}
function uiEasy.createItemsToList(parent, list, data, params)
	params = params or {}
	local item = ccui.Layout:create()
		:size(0, 0)
		:hide()
	-- parent 是 listview 会有多余 margin 的显示
	-- item:hide():addTo(parent)
	item:retain()
	parent:onNodeEvent("exit", function()
		if item then
			item:release()
			item = nil
		end
	end)
	bind.extend(parent, list, {
		class = "listview",
		props = {
			data = dataEasy.getItemData(data),
			item = item,
			margin = params.margin,
			padding = params.padding,
			dataOrderCmp = params.sortFunc or dataEasy.sortItemCmp,
			onAfterBuild = params.onAfterBuild,
			itemAction = {isAction = false},
			onItem = function(list, node, k, v)
				bind.extend(list, node, {
					class = "icon_key",
					props = {
						data = v,
						grayState = v.grayState,
						isDouble = params.isDouble,
						onNode = function(panel)
							if params.scale then
								panel:scale(params.scale)
							end
							local bound = panel:box()
							panel:alignCenter(bound)
							node:size(bound)
							if params.onNode then
								params.onNode(panel, v)
							end
						end
					},
				})
			end,
		}
	})
	list:adaptTouchEnabled()
end

-- @desc 常用的一些提示框
-- @param params {onClose, titleName, content}
-- @param styles {dialog}
function uiEasy.showDialog(name, params, styles)
	params = params or {}
	local content = params.content
	local function tryOpenRecharge()
		-- 点金和购买体力，已经在充值界面上的，直接关闭其界面返回充值
		if not gGameUI:goBackInStackUI("city.recharge") then
			gGameUI:stackUI("city.recharge", nil, {full = true})
		end
	end

	-- 金币不足
	if name == "gold" then
		-- gGameUI:stackUI("common.gain_way", nil, nil, "gold")
		gGameUI:stackUI("common.gain_gold")
	-- 钻石不足
	elseif name == "rmb" then
		gGameUI:showDialog({title = gLanguageCsv.rmbNotEnough, content = content or gLanguageCsv.noDiamondGoBuy, cb = tryOpenRecharge, btnType = 2, clearFast = true}, styles)

	-- 购买已上限，提升vip
	elseif name == "vip" then
		local defaultContent = {string.format(gLanguageCsv.commonTodayMax, params.titleName), string.format(gLanguageCsv.commonVipIncrease, params.titleName)}
		gGameUI:showDialog({title = params.titleName, content = content or defaultContent, cb = tryOpenRecharge, btnType = 2, btnStr = gLanguageCsv.showVip, clearFast = true}, styles)
	else
		local cfg = dataEasy.getCfgByKey(name)
		if cfg then
			gGameUI:showTip(content or string.format(gLanguageCsv.coinNotEnough, cfg.name))
			-- gGameUI:showDialog({title = params.titleName, content = content or string.format(gLanguageCsv.coinNotEnough, name), btnType = 1}, styles)
		else
			printWarn("uiEasy.showDialog not have:", name)
		end
	end
end

-- @desc 点击根据指定返回下发 OneByOne
-- @param params: {nodeVisible, beforeBegan(pos), began(pos), moved(pos, dx, dy), ended(pos, dx, dy), afterEnded(pos, dx, dy)}
-- @return nil 为默认下发消息
function uiEasy.addTouchOneByOne(node, params)
	node:visible(params.nodeVisible or false)
	local listener = cc.EventListenerTouchOneByOne:create()
	local eventDispatcher = display.director:getEventDispatcher()
	local touchBeganPos = cc.p(0, 0)
	local function transferTouch(event)
		listener:setEnabled(false)
		eventDispatcher:dispatchEvent(event)
		listener:setEnabled(true)
	end
	local function onTouchBegan(touch, event)
		touchBeganPos = touch:getLocation()
		local flag = nil
		if params.beforeBegan then
			flag = params.beforeBegan(touchBeganPos)
		end
		if flag ~= false then
			transferTouch(event)
		end
		if params.began then
			params.began(touchBeganPos)
		end
		return true
	end
	local function onTouchMoved(touch, event)
		local pos = touch:getLocation()
		local dx = pos.x - touchBeganPos.x
		local dy = pos.y - touchBeganPos.y
		local flag = nil
		if params.moved then
			flag = params.moved(pos, dx, dy)
		end
		if flag ~= false then
			transferTouch(event)
		end
	end
	local function onTouchEnded(touch, event)
		local pos = touch:getLocation()
		local dx = pos.x - touchBeganPos.x
		local dy = pos.y - touchBeganPos.y
		local flag = nil
		if params.ended then
			flag = params.ended(pos, dx, dy)
		end
		if flag ~= false then
			transferTouch(event)
		end
		if params.afterEnded then
			params.afterEnded(pos, dx, dy)
		end
	end
	listener:setSwallowTouches(true)
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:registerScriptHandler(onTouchMoved, cc.Handler.EVENT_TOUCH_MOVED)
	listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_ENDED)
	listener:registerScriptHandler(onTouchEnded, cc.Handler.EVENT_TOUCH_CANCELLED)
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, node)
	return listener
end

-- @desc 添加 listview 左右箭头自动隐藏显示处理
function uiEasy.addListviewScroll(list, leftBtn, rightBtn, isJump)
	local isVerticality = list:getDirection() == ccui.ScrollViewDir.vertical
	local innerContainer = list:getInnerContainer()
	local function getPercent(isRight)
		local innerSize = innerContainer:getContentSize()
		local listSize = list:getContentSize()
		local x, y = innerContainer:getPosition()
		local startPos, length, d = x, innerSize.width, listSize.width
		if isVerticality then
			startPos, length, d = y, innerSize.height, listSize.height
		end
		local k = isRight and 1 or -1
		local endPos = math.abs(startPos) + k * d
		endPos = math.max(0, endPos)
		endPos = math.min(length, endPos)

		return endPos / (length - d) * 100
	end

	local function jump(isRight)
		local percent = getPercent(isRight)
		percent = math.max(0, percent)
		percent = math.min(100, percent)
		if percent == 0 then
			leftBtn:visible(false)
			rightBtn:visible(true)
		elseif percent == 100 then
			rightBtn:visible(false)
			leftBtn:visible(true)
		else
			leftBtn:visible(true)
			rightBtn:visible(true)
		end
		if isJump then
			if isVerticality then
				list:jumpToPercentVertical(percent)
			else
				list:jumpToPercentHorizontal(percent)
			end
		else
			if isVerticality then
				list:scrollToPercentVertical(percent, 0.2, false)
			else
				list:scrollToPercentHorizontal(percent, 0.2, false)
			end
		end
	end

	bind.touch(list, leftBtn, {methods = {ended = functools.partial(jump, false)}})
	bind.touch(list, rightBtn, {methods = {ended = functools.partial(jump, true)}})
end

-- @desc 添加 list 裁剪效果
function uiEasy.addTabListClipping(list, parent, params)
	params = params or {}
	local mask = params.mask or "common/box/mask_tab.png"
	list:retain()
	list:removeFromParent()
	local size = list:size()
	local rect = params.rect or cc.rect(59, 1, 1, 1)
	local maskS = ccui.Scale9Sprite:create()
	local offsetX = params.offsetX or 0
	local offsetY = params.offsetY or 0
	maskS:initWithFile(rect, mask)
	maskS:size(size)
		:anchorPoint(0, 0)
		:xy(list:x()+offsetX, list:y()+offsetY)
	cc.ClippingNode:create(maskS)
		:setAlphaThreshold(0.1)
		:add(list)
		:addTo(parent, list:z())
	list:release()
end

-- @desc 设置排名显示效果
function uiEasy.setRankIcon(k, rankImg, textRank1, textRank2)
	if k < 4 then
		rankImg:texture(ui.RANK_ICON[k])
		textRank1:hide()
		textRank2:hide()
	elseif k < 11 then
		rankImg:texture(ui.RANK_ICON[4])
		textRank1:text(k)
		textRank2:hide()
	else
		rankImg:hide()
		textRank1:hide()
		textRank2:text(k)
	end
end

-- @desc item 上是否显示 锁资源
-- @param key gUnlockCsv[feature] nil:表示功能暂时不开放，为加锁
-- @param params {justRemove, res, scale, pos, zOrder}
function uiEasy.updateUnlockRes(key, item, params)
	params = params or {}
	if params.justRemove then
		item:removeChildByName("_lock_res_")
		-- assign for add anonyOnly
		return idlereasy.assign(idler.new(true))
	end
	return dataEasy.getListenUnlock(key, function(isUnlock)
		item:removeChildByName("_lock_res_")
		if not isUnlock then
			local size = item:size()
			local defaultPos = cc.p(size.width * 0.5, size.height * 0.5)
			ccui.ImageView:create(params.res or "common/btn/btn_lock1.png")
				:xy(params.pos or defaultPos)
				:scale(params.scale or 1)
				:addTo(item, params.zOrder or 10, "_lock_res_")
		end
	end)
end

-- @desc 检查文本 不符合规则飘字返回false 符合返回true
-- @param params {name, cost, noBlackList}
-- @needSpecialChar 允许特殊字符true
function uiEasy.checkText(text, params,needSpecialChar)
	params = params or {}
	local noBlackList = params.noBlackList or false
	local specialChar = {"\"", "'", "\\", "/", "#"} -- 禁止名字中包含特殊字符
	if not needSpecialChar then
		for _,v in pairs(specialChar) do
			if string.find(text, v) then
				gGameUI:showTip(gLanguageCsv.noContainSpecailChar)
				return false
			end
		end
	end
	if text == "" then
		gGameUI:showTip(gLanguageCsv.canNotEmpty)
		return false
	end
	-- 不允许头尾空格
	if #text > 0 and (string.byte(text, 1) == 32 or string.byte(text, #text) == 32) then
		gGameUI:showTip(gLanguageCsv.hasSpaceBothEnds)
		return false
	end
	if params.name and text == params.name then
		gGameUI:showTip(gLanguageCsv.noChangeName)
		return false
	end
	if not noBlackList and blacklist.findBlacklist(text) then
		gGameUI:showTip(gLanguageCsv.inBlacklist)
		return false
	end
	if params.cost and params.cost > 0 and gGameModel.role:read("rmb") < params.cost then
		uiEasy.showDialog("rmb")
		return false
	end
	return true
end

-- @desc 设置按钮置灰
-- @param state 1正常状态 2置灰不可点击 3置灰可点击
function uiEasy.setBtnShader(btn, title, state)
	if state == 1 then
		if title then
			text.addEffect(title, {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
		end
		btn:setTouchEnabled(true)
		cache.setShader(btn, false, "normal")
	else
		if title then
			text.addEffect(title, {color = ui.COLORS.DISABLED.WHITE})
		end
		btn:setTouchEnabled(state == 3)
		cache.setShader(btn, false, "hsl_gray")
	end
end

-- @desc 设置领取奖励特效
function uiEasy.setBoxEffect(box, scale, cb, offsetX, offsetY)
	local size = box:size()
	local effect = box:get("effect")
	local scale = scale or 1
	local offsetX = offsetX or 0
	local offsetY = offsetY or 0
	if not effect then
		effect = widget.addAnimationByKey(box, "effect/kaixiangguang.skel", "effect", "effect", 10)
			:xy(size.width/2 + offsetX, size.height/2 + offsetY)
			:scale(scale)
		effect:setSpriteEventHandler(function(event, eventArgs)
			effect:hide()
			if cb then
				cb()
			end
		end, sp.EventType.ANIMATION_COMPLETE)
	else
		effect:show():play("effect")
	end
end

-- @desc 设置title特效
-- @desc 添加超进化特效
function uiEasy.setTitleEffect(parent, effectName, params)
	if params and params.mega then
		local anima = widget.addAnimation(parent, "chaojinhua/jiesuan2.skel", "effect", 25)
		anima:y(anima:y() + 450)
		performWithDelay(parent, function()
			anima:play("effect_loop")
		end, 1.1)
	else
		local effect = widget.addAnimationByKey(parent, "level/jiesuanshengli.skel", "effect", effectName, 20)
		local effectBg = widget.addAnimationByKey(parent, "level/jiesuanshengli.skel", "effectBg", "jiesuan_shenglitu", 10)
		effect:setSpriteEventHandler(function(event, eventArgs)
			effect:play(effectName.."_loop")
			effectBg:play("jiesuan_shenglitu_loop")
		end, sp.EventType.ANIMATION_COMPLETE)
	end
end

-- @desc 设置结算界面动画
-- @params {offx, time, delayTime}
function uiEasy.setExecuteSequence(nodes, params)
	if type(nodes) ~= "table" then nodes = {nodes} end
	local params = params or {}
	local offx = params.offx or -300
	local time = params.time or 1
	local delayTime = params.delayTime or 0

	local outx = 50
	local pow = cc.clampf(offx / (outx - offx), 0.1, 0.9)
	for _,node in ipairs(nodes) do
		node:hide()
		performWithDelay(node, function()
			node:show()
			local x, y = node:xy()
			local scaleX = node:scaleX()
			local scaleY = node:scaleY()
			node:x(x+offx):scaleX(0)
			transition.executeSequence(node)
				:easeBegin("EaseInOut")
					:moveTo(time/2, x+outx, y)
					:moveTo(time/2, x, y)
				:easeEnd()
				:done()
			transition.executeSequence(node)
				:scaleXTo(time*pow/2, scaleX)
				:scaleTo(time*(1-pow)/2, scaleX*1.25, scaleY*1.25)
				:scaleTo(time/2, scaleX, scaleY)
				:done()
		end, delayTime)
	end
end

function uiEasy.setPrivilegeRichText(privilegeType, parent, txt, pos, isBracket)
	local privilegeNum = dataEasy.getPrivilegeVal(privilegeType)
	if privilegeNum and privilegeNum ~= 0 then
		if string.find(tostring(privilegeNum), ".", 1, true) then
			privilegeNum = (privilegeNum * 100).."%"
		end
		local str
		if isBracket then
			str = "#C0x5B545B#("..string.format(gLanguageCsv.currentPrivilege, txt, tostring(privilegeNum)).."#C0x5B545B#)"
		else
			str = string.format(gLanguageCsv.currentPrivilege, txt, tostring(privilegeNum))
		end
		local richText = rich.createByStr(str, 40, nil, nil, cc.p(0, 0.5))
			:addTo(parent, 10, "privilege")
			:anchorPoint(cc.p(0, 0.5))
			:xy(pos)
			:formatText()
		return richText
	end
end

function uiEasy.setCardNum(panel, num, targetNum, quality, noColor)
	local size = panel:size()
	local label = panel:get("num")
	local label1 = panel:get("num1")
	local label2 = panel:get("num2")
	if not targetNum then
		if not num or num == 0 then
			num = ""
		end
		local outlineSize = ui.DEFAULT_OUTLINE_SIZE
		if type(num) ~= "number" then
			num = gLanguageCsv[num] or num
			outlineSize = 3
		end
		if not label then
			label = cc.Label:createWithTTF(num, ui.FONT_PATH, 36)
				:align(cc.p(1, 0), size.width - 30, 12)
				:addTo(panel, 10, "num")
			text.addEffect(label, {outline={color=ui.COLORS.QUALITY_OUTLINE[quality], size = outlineSize}})
		end
		label:show():text(mathEasy.getShortNumber(num))
		if label1 then
			itertools.invoke({label1, label2}, "hide")
		end
	else
		num = num or 0
		if not label1 then
			label1 = cc.Label:createWithTTF(0, ui.FONT_PATH, 36)
				:align(cc.p(1, 0), size.width - 20, 10)
				:addTo(panel, 10, "num1")
			text.addEffect(label1, {outline={color=ui.COLORS.QUALITY_OUTLINE[quality]}})

			label2 = cc.Label:createWithTTF(0, ui.FONT_PATH, 36)
				:align(cc.p(1, 0), size.width - 30, 10)
				:addTo(panel, 10, "num2")
			text.addEffect(label2, {outline={color=ui.COLORS.QUALITY_OUTLINE[quality]}})
		end
		label1:show():text("/" .. mathEasy.getShortNumber(targetNum))
		label2:show():text(mathEasy.getShortNumber(num))
		if not noColor then
			local color = (num >= targetNum) and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE
			text.addEffect(label2, {color = color})
		end
		adapt.oneLinePos(label1, label2, nil, "right")
		if label then
			label:hide()
		end
	end
end

function uiEasy.isOpenMystertShop()
	local curTime = time.getTime()
	local mysteryShopLastTime = gGameModel.mystery_shop:read("last_active_time")
	local cfg = csv.mystery_shop_config[1]
	local live = cfg.shop_exist_time
	local delta = mysteryShopLastTime + live - 1 - curTime

	return delta > 0, delta
end

function uiEasy.showMysteryShop()
	local isOpen = uiEasy.isOpenMystertShop()
	local roleLv = gGameModel.role:read("level")
	local mysteryTimes = gGameModel.daily_record:read("mystery_active_times")
	local cfg = csv.mystery_shop_config[1]
	local minLv = cfg.min_level
	local maxTime = cfg.daily_active_times
	-- 0:没出现 1:触发 但是没在主城出现 2:在主城出现
	local mysteryState = userDefault.getForeverLocalKey("mySteryState", 0)
	if roleLv >= minLv and mysteryTimes < maxTime and isOpen and mysteryState == 0 then
		userDefault.setForeverLocalKey("mySteryState", 1)
		gGameUI:stackUI("city.mystery_shop.show")

		return true
	end

	return false
end

--节日Boss
function uiEasy.showActivityBoss()
	local yyhuodongs = gGameModel.role:read("yyhuodongs")
	local yyOpen = gGameModel.role:read('yy_open')
	local huodongId
	for _, id in ipairs(yyOpen) do
		local cfg = csv.yunying.yyhuodong[id]
		if cfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.huoDongBoss then
			huodongId = id
			break
		end
	end
	if yyhuodongs[huodongId] and yyhuodongs[huodongId].info then
		local myBossTimes = yyhuodongs[huodongId].info.huodong_boss_count
		local oldBossTimes = userDefault.getForeverLocalKey("activityBossCount", 0)
		if myBossTimes and myBossTimes ~= oldBossTimes then
			userDefault.setForeverLocalKey("activityBossCount", myBossTimes)
			gGameUI:stackUI("city.activity.activity_boss.show")
			return true
		end
	end

	return false
end

-- 隐藏底部遮罩
function uiEasy.setBottomMask(list, maskPanel, typ)
	local container = list:getInnerContainer()
	local listWidth = list:size().width
	local isShow = true
	list:onScroll(function(event)
		if typ and typ == "x" then
			local x = container:getPositionX()
			local containerWidth = container:getContentSize().width
			isShow = (listWidth - containerWidth + 10) < x
		else
			local y = container:getPositionY()
			isShow = math.abs(y) > 10
		end
		maskPanel:get("mask"):visible(isShow)
	end)
end

-- 设置箱子抖动
function uiEasy.addVibrateToNode(view, node, state, tag)
	local steps = {
		{t1 = 0.1, t2 = 0.1, rotation = 7,},
		{t1 = 0.1, t2 = 0.1, rotation = -5,},
		{t1 = 0.1, t2 = 0.1, rotation = 3,},
		{t1 = 0.1, t2 = 0.1, rotation = -2,},
		{t1 = 0.1, t2 = 0.1, rotation = 1,},
	}

	tag = tag or node:getName().."toRotationScheduleTag"
	if state then
		view:enableSchedule():schedule(function (dt)
			if tolua.isnull(node) then
				view:enableSchedule():unSchedule(tag)
				return
			end
			local seq = transition.executeSequence(node)
			for _,t in pairs(steps) do
				seq:rotateTo(t.t1, t.rotation):delay(t.t2)
			end
			seq:rotateTo(0.1, 0):done()
		end, 2, nil, tag)
	else
		view:enableSchedule():unSchedule(tag)
	end
end

function uiEasy.shareBattleToChat(playRecordID, enemyName)
	local battleShareTimes = gGameModel.daily_record:read("battle_share_times")
	if battleShareTimes >= gCommonConfigCsv.shareTimesLimit then
		gGameUI:showTip(gLanguageCsv.shareTimesNotEnough)
		return
	end
	local leftTimes = gCommonConfigCsv.shareTimesLimit - battleShareTimes
	local params = {
		cb = function()
			gGameApp:requestServer("/game/battle/share", function(tb)
				gGameUI:showTip(gLanguageCsv.recordShareSuccess)
			end, playRecordID, enemyName, "arena")
		end,
		isRich = false,
		btnType = 2,
		content = string.format(gLanguageCsv.shareBattleNote, leftTimes .. "/" .. gCommonConfigCsv.shareTimesLimit),
	}
	gGameUI:showDialog(params)
end

-- 聊天框的点击链接跳转
function uiEasy.setUrlHandler(target, data)
	local args = data.args or {}
	target:setOpenUrlHandler(function(key)
		-- 公会红包
		if string.find(key, "redpack") then
			gGameApp:requestServer("/game/union/redpacket/info",function (tb)
				gGameUI:stackUI("city.union.redpack.view", nil, {full = true}, tb.view, 2)
			end)
			return
		end

		--道馆日志
		if string.find(key, "gymLog") then
			gGameUI:stackUI("city.adventure.gym_challenge.battle_detail", nil, nil, data)
			return
		end

		-- 老玩家绑定 邀请
		if string.find(key, "reunion") then
			if not data.isMine then
				--判断是否满足条件
				local roleLevel = gGameModel.role:read("level") or 0
				local fightingPoint = gGameModel.role:read("top6_fighting_point")
				local id = gGameModel.role:read("id")
				local reunion = gGameModel.role:read("reunion") or {}
				local nowTime = time.getTime()

				local function joinReunion()
					gGameApp:requestServer("/game/yy/reunion/bind/join", function (tb)
						--弹飘窗
						if tb.view.result then
							jumpEasy.jumpTo("reunion")
							gGameUI:showTip(gLanguageCsv.reunionBindDialogSuccess)
						end
					end, args.yyID, args.roleID, args.end_time)
				end
				gGameApp:requestServer("/game/yy/reunion/record/get", function(tb)
					local reunion_record = tb.view.reunion_record
					local reunionBindHistory = reunion_record.bind_history
					local reunionBindRoleId = reunion_record.bind_role_db_id

					if roleLevel < gCommonConfigCsv.seniorRoleLevel or fightingPoint < gCommonConfigCsv.seniorRoleFightingPoint or reunion.role_type ~= 0 then
						--你还不符合老玩家的条件要求
						gGameUI:showTip(gLanguageCsv.reunionWorldChatErr6)
					elseif reunion.info and reunion.info.end_time > nowTime then
						--当前已参与了该活动
						gGameUI:showTip(gLanguageCsv.reunionWorldChatErr4)
					elseif reunion.bind_cd and reunion.bind_cd > nowTime then
						--%d天%d小时%d分后才可再次参与该活动哦!
						local countDownTime = reunion.bind_cd - nowTime
						local time1 = time.getCutDown(countDownTime)
						local str = string.format(gLanguageCsv.reunionWorldChatErr3, time1.day, time1.hour, time1.min)
						gGameUI:showTip(str)
					elseif (not args.end_time or args.end_time < nowTime) or reunionBindRoleId then
						--失效
						gGameUI:showTip(gLanguageCsv.reunionWorldChatErr5)
					elseif not itertools.isempty(reunionBindHistory) and itertools.include(reunionBindHistory, id) then
						--你已经与该玩家绑定参与过该活动, 判断是否曾经和当前roleID绑定过
						gGameUI:showTip(gLanguageCsv.reunionWorldChatErr2)
					else
						gGameApp:requestServer("/game/role_info", function (tb)
							gGameUI:showDialog({
								content = string.format(gLanguageCsv.reunionBindDialogText, tb.view.name),
								isRich = true,
								cb = joinReunion,
								btnType = 2,
							})
						end, args.roleID)
					end
				end, args.roleID)
			else
				gGameUI:showTip(gLanguageCsv.reunionWorldChatErr1)
			end
			return
		end

		if not args[key] then
			printWarn("chat url 缺少对应 key(%s) 的数据", tostring(key))
			return
		end
		-- 玩家信息
		if string.find(key, "^role") then
			-- 自己不显示详情
			if args[key].id ~= gGameModel.role:read("id") then
				local x, y = target:xy()
				local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
				gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, {role = args[key]})
			end
			return
		end
		-- 精灵详情
		if string.find(key, "^card") then
			gGameApp:requestServerCustom("/game/card_info")
				:onErrCall(function()
					gGameUI:showTip(gLanguageCsv.cardDoesNotExist)
				end)
				:params(args[key])
				:doit(function(tb)
					gGameUI:stackUI("city.card.info", nil, nil, tb.view)
				end)
			return
		end

		-- 公会详情
		if string.find(key, "^union") then
			gGameApp:requestServer("/game/union/find", function (tb)
				gGameUI:stackUI("city.union.join.detail", nil, nil, nil, tb.view[1])
			end, args[key])
			return
		end

		-- 战报
		if string.find(key, "battleID") then
			local battleID = args[key]
			local url = "/game/pw/playrecord/get"
			if string.find(args.from, "crossArena") then
				url = "/game/cross/arena/playrecord/get"

			elseif string.find(args.from, "onlineFight") then
				url = "/game/cross/online/playrecord/get"
			elseif string.find(args.from, "crossMine") then
				url = "/game/cross/mine/playrecord/get"
			end
			gGameModel:playRecordBattle(battleID, args.crossKey, url, 2)
			return
		end

		-- 元素挑战 邀请
		if string.find(key, "nature_room_id") then
			local kickNum = gGameModel.role:read("clone_daily_be_kicked_num")
			if not data.isMine then
				if kickNum < 3 then
					gGameApp:requestServer("/game/clone/room/join", function (tb)
						gGameUI:goBackInStackUI("city.view")
						jumpEasy.jumpTo("cloneBattle")
					end, args.nature_room_id)
				else
					gGameUI:showTip(gLanguageCsv.beKickThreeTimesPleaseNext)
				end
			else
				gGameUI:showTip(gLanguageCsv.cloneInviteMyRoom)
			end
			return
		end

		--春节活动(抢红包)
		if string.find(key, "hd_redPacket_idx") then
			local yyOpen = gGameModel.role:read('yy_open')
			local openYdFlag = false
			for _,v in ipairs(yyOpen) do
				if args.yy_id == v then
					openYdFlag = true
				end
			end
			if not openYdFlag then
				gGameUI:showTip(gLanguageCsv.huodongNoOpen)
				return
			end
			local getredPacket = gGameModel.daily_record:read("huodong_redPacket_rob")
			local vipLevel = gGameModel.role:read("vip_level")
			local getVipNum = gVipCsv[vipLevel].huodongRedPacketRob
			if getredPacket == getVipNum then
				gGameUI:showTip(gLanguageCsv.redPacketRoleRobLimit)
				return
			end

			local interface = "/game/yy/red/packet/rob"
			if csv.yunying.yyhuodong[args.yy_id].type == game.YYHUODONG_TYPE_ENUM_TABLE.huodongCrossRedPacket then
				interface = "/game/yy/cross/red/packet/rob"
			end
			gGameApp:requestServerCustom(interface)
				:onErrCall(function(err)
					if gLanguageCsv[err.err] then
						gGameUI:showTip(gLanguageCsv[err.err])
					end
				end)
				:params(args.hd_redPacket_idx)
				:doit(function(data)
					gGameUI:stackUI("city.activity.chinese_new_year", nil, nil, args.yy_id, data.view.info, "world")
				end)
			return
		end

		printWarn("chat url 未知 key(%s) type(%s)", tostring(key), type(key))
	end)
end

local SKILL_TYPE_TEXT = {
	[0] = gLanguageCsv.normalSkill,
	[1] = gLanguageCsv.smallSkills,
	[2] = gLanguageCsv.uniqueSkill,
	[3] = gLanguageCsv.passiveSkill
}

-- items
	-- name
	-- type1
	-- type2
	-- icon
	-- target
function uiEasy.setSkillInfoToItems(items, skillCfgOrId)
	items = items or {}

	local skillCfg = skillCfgOrId
	if type(skillCfgOrId) == "number" then
		skillCfg = csv.skill[skillCfgOrId]
	end

	local natureType = skillCfg.skillNatureType
	local skillType = skillCfg.skillType
	local iconPath = "city/card/system/skill/icon_skill.png"
	local typePath = "city/card/system/skill/icon_skill_text.png"
	if skillType == battle.SkillType.NormalSkill then
		iconPath = ui.SKILL_ICON[natureType]
		typePath = ui.SKILL_TEXT_ICON[natureType]
	end

	if items.icon then
		items.icon:texture(iconPath)
	end
	if items.name then
		items.name:text(skillCfg.skillName)
	end
	if items.type1 then
		items.type1:texture(typePath)
	end
	if items.type2 then
		items.type2:text(SKILL_TYPE_TEXT[skillCfg.skillType2])
	end
	if items.target then
		items.target:text(skillCfg.targetTypeDesc)
		if items.name then
			local len = items.target:width() + items.name:width()
			local max = items.target:x() - items.name:x()
			if len > max then
				adapt.setTextAdaptWithSize(items.name, {size = cc.size(max - items.target:width(), items.name:height()*2), vertical = "center"})
			end
		end
	end
end

-- 获取星级技能描述
-- params{skillId, cardId, star, isZawake}
function uiEasy.getStarSkillDesc(params, typ)
	if not dataEasy.isUnlock(gUnlockCsv.starEffect) then
		return ""
	end
	local skillCsv = csv.skill[params.skillId]
	local cardCsv = csv.cards[params.cardId]
	local myStar = cardCsv and cardCsv.star or 0
	if params.star then
		myStar = params.star
	end
	local starStr = ""
	if skillCsv.starEffect and csvSize(skillCsv.starEffect) > 0 then
		local color = myStar >= skillCsv.starEffect[1] and "#C0x60c456#" or "#C0xB7B09E#"
		if typ == "handbook" then
			color = "#C0xB7B09E#"
		end
		local tmpStar = skillCsv.starEffect[1]
		for _,needStar in orderCsvPairs(skillCsv.starEffect) do
			if myStar >= needStar then
				tmpStar = needStar
			end
		end
		local desc = skillCsv.starEffectDesc
		if params.isZawake and skillCsv.zawakeEffect[2] == 1 then
			desc = skillCsv.zawakeEffectDesc
		end
		starStr = "\n\n" .. color .. string.format(gLanguageCsv.starUnlockSkillDesc,
			tmpStar, eval.doMixedFormula(desc, {skillLevel = params.skillLevel or 1,math = math},nil))
	end
	return starStr
end
-- 根据卡牌ID获取最大星级
function uiEasy.getMaxStar(cardId)
	local cards = gGameModel.role:read("cards")
	--背包里有的卡牌战力数据
	local star = csv.cards[cardId].star
	for i,v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardData = card:read("card_id", "star")
		if cardData.card_id == cardId and cardData.star > star then
			star = cardData.star
		end
	end
	return star
end

-- @desc 根据星数获得组装好的星级容器
-- @param params:{align, interval} align: "center", 默认居中, "left", "right"
function uiEasy.getStarPanel(star, params)
	params = params or {}
	local panel = ccui.Layout:create()
		:size(0, 0)
		:name("starPanel")

	local interval = params.interval or 0
	local num = star > 6 and 6 or star
	local width = 104
	local length = width * num + interval * (num - 1)
	local st = width/2 - length /2
	if params.align == "left" then
		st = width/2

	elseif params.align == "right" then
		st = width/2 - length
	end
	for i = 1, num do
		local res = (i > star - 6) and "common/icon/icon_star.png" or "common/icon/icon_star_z.png"
		ccui.ImageView:create(res)
			:xy(st + (i-1)*(width+interval), 0)
			:addTo(panel)
	end
	return panel
end

-- 通用橘红描边发光效果
function uiEasy.addTextEffect1(textNote)
	text.addEffect(textNote, {outline = {color=cc.c4b(255, 84, 0, 255), size=3}, glow = {color = cc.c4b(255, 71, 0, 255)}})
end

-- 尝试用editbox来处理ios13系统下textfield的输入bug
function uiEasy.useEditBox(textField, cb)
	if device.platform ~= "ios" and device.platform ~= "windows" then
		return
	end
	local parent = textField:parent()
	local pos = cc.p(textField:xy())
	local sp = cc.Scale9Sprite:create()
	local editBox = cc.EditBox:create(textField:getContentSize(), sp)
		:anchorPoint(textField:anchorPoint())
		:xy(pos)
		:addTo(parent, textField:z() + 1)
	-- editBox本身有问题，无法设置换行，字体大小恒等于初始化高度，只利用它来调用系统弹出框
	editBox:registerScriptEditBoxHandler(function(event)
		printInfo("# uiEasy.useEditBox handler event: " .. event)
		if event == 'began' then
			-- 使用设置坐标来控制界面在键盘键盘出现不偏移，没有相关接口，只能用这个取巧方法。
			editBox:setPosition(pos)
			editBox:setText(textField:getStringValue())
		end
		if event == 'changed' then
			textField:setText(editBox:getText())
		end
		if event == 'ended' then
			local text = editBox:getText()
			textField:setText(text)
			editBox:setText('')
			if cb then
				cb(text)
			end
		end
	end)
	textField.editBox = editBox
end

-- 队伍光环自动选最优的item显示
-- panel 固定结构:{attrBg{attr1{img, bg, bg2}, attr2{img, bg, bg2}}}
-- flag 标记，1为选择属性1，2为选择属性2
function uiEasy.setTeamBuffItem(panel, cardId, flag)
	local cardCfg = csv.cards[cardId]
	local unitCfg = csv.unit[cardCfg.unitID]
	panel:get("attrBg"):show()
	local attrPanel1 = panel:get("attrBg.attr1")
	local attrPanel2 = panel:get("attrBg.attr2")
	attrPanel1:get("img"):texture(ui.ATTR_ICON[unitCfg.natureType])
	attrPanel1:get("bg"):visible(flag == 1)
	attrPanel1:get("bg2"):visible(flag == 2)
	attrPanel1:y(flag == 1 and 45 or 42)
	attrPanel1:scale(flag == 1 and 1 or 0.9)
	attrPanel1:get("img"):scale(flag == 1 and 0.64 or 0.56)
	if unitCfg.natureType2 then
		attrPanel2:show()
		attrPanel2:get("img"):texture(ui.ATTR_ICON[unitCfg.natureType2])
		attrPanel2:get("bg"):visible(flag == 2)
		attrPanel2:get("bg2"):visible(flag == 1)
		attrPanel2:y(flag == 2 and 45 or 42)
		attrPanel2:scale(flag == 2 and 1 or 0.9)
		attrPanel2:get("img"):scale(flag == 2 and 0.64 or 0.56)
	else
		attrPanel2:hide()
	end
end

--精灵切换之后属性改变弹框提示
function uiEasy.showConfirmNature(cardId1, cardId2)
	local csvUnit = csv.unit
	local natureTable1 = {csvUnit[cardId1].natureType, csvUnit[cardId1].natureType2}
	local natureTable2 = {csvUnit[cardId2].natureType, csvUnit[cardId2].natureType2}
	for k = 1, 2 do
		local nature = natureTable1[k]
		if nature then
			if not itertools.include(natureTable2, nature) then
				local content = gLanguageCsv.changeNatureToChangeTeam
				gGameUI:showDialog({content = content, btnType = 1})
				break
			end
		end
	end
end

-- params: {node or targetPos}
function uiEasy.storageTo(params)
	local timeScale = params.timeScale or 1
	local targetPos = params.targetPos
	if not targetPos then
		targetPos = params.node:parent():convertToWorldSpace(cc.p(params.node:xy()))
	end
	local animationName = params.animationName or "answerGift"
	local panel = params.panel or gGameUI.scene

	local mask = ccui.Layout:create()
		:size(display.sizeInView)
		:addTo(panel, 111, animationName)
	mask:setBackGroundColorType(1)
	mask:setBackGroundColorOpacity(0)

	local img = cc.Sprite:create(params.img or "city/union/answer/daxingxing.png")
		:alignCenter(display.sizeInView)
		:addTo(mask)

	--粒子特效
	local plistFile = params.plistFile or "particle/xingxing.plist"
	local aniFile = params.aniFile or "particle/xingxing2.json"
	local particleNode = cc.ParticleSystemQuad:create(plistFile, aniFile)
	particleNode:addTo(mask)
		:scale(4)
		:alignCenter(display.sizeInView)


	local x, y = img:xy()
	local originP = cc.p(x, y) -- 起点
	local endP = targetPos -- 终点
	local controlP1 = cc.p(x + (targetPos.x - x)*2/3, y) -- 控制点1
	local controlP2 = cc.p(targetPos.x, y + (targetPos.y - y)*1/2) -- 控制点2
	local bezierPos = {controlP1, controlP2, endP}

	gGameUI:disableTouchDispatch(nil, false)
	local cb
	cb = img:onNodeEvent("exit", function()
		cb:remove()
		gGameUI:disableTouchDispatch(nil, true)
	end)
	-- 动作1动作2同时运行结束后，再执行动作3
	img:runAction(transition.sequence({
		cc.RotateTo:create(0.1/timeScale, 300),
		cc.EaseIn:create(cc.BezierTo:create(1/timeScale, bezierPos), 3),
		-- cc.DelayTime:create(0.1/scale),
		cc.CallFunc:create(function()
			img:removeSelf()
			widget.addAnimationByKey(mask, "union_answer/xingxing_guang.skel", "effect", "effect", 999)
				:xy(endP)
		end)
	}))
	particleNode:runAction(transition.sequence({
		cc.RotateTo:create(0.1/timeScale, 300),
		cc.EaseIn:create(cc.BezierTo:create(1/timeScale, bezierPos), 3),
	}))
	return mask
end

--[[function:光效数字增加
	object
	textNode:text控件
	start:起始数字
	over:结束数字
	tag:定时器目标参数
	scale:放大倍数
]]
function uiEasy.digitRollAction(textNode, start, over, scale, timeScale, hideText)
	if over <= start then return end
	scale = scale or 1.2

	local timeScale = timeScale or 1
	local curScale = textNode:scale()
	local step = math.modf((over - start)/10)
	step = step == 0 and 1 or step

	local stepAddScale = (scale - curScale)/40
	textNode:stopAllActions()
	schedule(textNode, function()
		if start >= over then
			textNode:stopAllActions()
			textNode:runAction(cc.EaseOut:create(cc.ScaleTo:create(0.5, 1), 0.5))
			textNode:text(over)
			hideText:hide()
			performWithDelay(textNode, function()
				textNode:disableEffect()
			end, 0.5)
		else
			curScale = math.min(curScale + stepAddScale, scale)
			textNode:text(start)
			textNode:scale(curScale)
			local size = textNode:size()
			start = start + step
		end
	end, 0.048 * 1/timeScale)
end

-- 扫光效果
-- @param node 父节点
-- @param params {speedTime = 1.0 , delayTime = 1.0, angle = 20, scaleX = 3.0}
-- speedTime 扫光移动时间，动画时间
-- delayTime 扫光后的间隔时间
-- angle 扫光的倾斜角度
-- scaleX 扫光宽度缩放
function uiEasy.sweepingEffect(node, params)
	local panel = node:getChildByName("_sweepPanel_")
	if panel then
		return
	end
	params = params or {}

	local nodeW = node:width()
	local nodeH = node:height()
	-- 动画时间
	local speedTime = params.speedTime or 1.0
	-- 扫光后的延时
	local delayTime = params.delayTime or 0.5
	-- 扫光倾斜角度
	local angle = params.angle or 20
	-- 扫光宽度缩放
	local scaleX = params.scaleX or 3.0
	local offx = math.tan(math.rad(angle)) * nodeH
	-- 扫光宽度和高度
	-- local panelWidth = params.width or 40
	local panelHeight = nodeH/math.cos(math.rad(angle))
	-- 动画坐标
	local startPosx = -100 - offx
	local endPosx = nodeW + 50

	local lightPath = "common/icon/img_light_2.png"
	local lightRect = cc.rect(20, 20, 1, 1)

	local mask = cc.utils:captureNodeSprite(node, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, 1.0, display.uiOrigin.x, 0)
	mask:retain()

	-- local scale = 0.5
	-- local sp = cc.utils:captureNodeSprite(node, cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565, scale, display.uiOrigin.x, 0)
	-- sp:setScale(1.0 / scale)
	-- sp:setAnchorPoint(0.5, 0.5)
	-- -- 毛玻璃效果, 高斯模糊
	-- cache.setShader(sp, false, "gaussian_blur"):setUniformVec3("iResolution", cc.Vertex3F(nodeW * scale, nodeH * scale, 0))
	-- sp:xy(display.center):addTo(node, 9999)

	-- local glassLight = cc.utils:captureNodeSprite(node, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888, scale, display.uiOrigin.x, 0)
	-- glassLight:setScale(1.0 / scale * 1.08)
	-- glassLight:setAnchorPoint(0.5, 0.5)
	-- glassLight:xy(node:width()/2, node:height()/2)
	-- glassLight:setBlendFunc({src = GL_SRC_ALPHA, dst = GL_ONE})
	-- sp:removeSelf()
	-- glassLight:addTo(node, -1, "_glassLight_")

	--添加一个layout
	panel = ccui.Layout:create()
		:anchorPoint(0, 0)
		:xy(0, 0)
		:size(node:width(), node:height())
		:addTo(node, 100, "_sweepPanel_")

	local ClippingPanel = ccui.Layout:create()
		:setClippingEnabled(true)
		:anchorPoint(0, 0)
		:xy(0, 0)
		:size(node:width(), node:height())

	local ClippingNode = cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.05)
		:xy(0, 0)
		:addChild(ClippingPanel, 1, "_ClippingPanel_")
		:addTo(panel, 1, "_ClippingNode_")

	-- 扫光
	local light = ccui.Scale9Sprite:create()
	light:initWithFile(lightRect, lightPath)
	light:setSkewX(angle)
	light:height(panelHeight)
	light:setBlendFunc({src = GL_DST_COLOR, dst = GL_ONE})
	light:anchorPoint(0, 0)
	light:xy(startPosx, 0)
	light:scaleX(scaleX)
	light:addTo(ClippingPanel, 1, "_light_")
	mask:release()
	startPosx = startPosx - light:width() * scaleX

	-- 扫光动画
	local function setSweepAction(node, startPos, endPos)
		node:xy(startPos[1], startPos[2])
		local animate = cc.Sequence:create(
			cc.MoveTo:create(speedTime, cc.p(endPos[1], endPos[2])),
			cc.CallFunc:create(function()
				node:xy(startPos[1], startPos[2])
			end),
			cc.DelayTime:create(delayTime))
		local action = cc.RepeatForever:create(animate)
		node:runAction(action)
	end
	setSweepAction(light, {startPosx, 0}, {endPosx, 0})
	-- 微弱呼吸
	local function setBreatheAction(node)
		local animate = cc.Sequence:create(
			cc.DelayTime:create(speedTime),
			cc.ScaleTo:create(delayTime/4.0, 1.05),
			cc.ScaleTo:create(delayTime/4.0, 0.95),
			cc.ScaleTo:create(delayTime/4.0, 1.01),
			cc.ScaleTo:create(delayTime/4.0, 1.0))
		local action = cc.RepeatForever:create(animate)
		node:runAction(action)
	end
	setBreatheAction(node)
	-- 图片外发光
	local function setImgOutlight(node)
		node:setOpacity(5)
		local animate = cc.Sequence:create(
			cc.FadeTo:create((speedTime + delayTime)/4, 50),
			cc.FadeTo:create((speedTime + delayTime)/4, 5),
			cc.FadeTo:create((speedTime + delayTime)/4, 50),
			cc.FadeTo:create((speedTime + delayTime)/4, 5))
		local action = cc.RepeatForever:create(animate)
		node:runAction(action)
	end
	--setImgOutlight(glassLight)
	-- 添加粒子效果
	--local function setParticle(node)
	--		local particle = CSprite.new("particle/spreadParticle.plist")
	--			:anchorPoint(0.5, 0.5)
	--			:xy(nodeW/2, 0)
	--			:addTo(node, 1, "_particle_")
	--		local particle2 = CSprite.new("particle/spreadParticle.plist")
	--			:anchorPoint(0.5, 0.5)
	--			:xy(nodeW/2, nodeH/2)
	--			:addTo(node, 1, "_particle2_")
	--end
	--setParticle(node)
end


