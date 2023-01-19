-- @date:   2019-06-10
-- @desc:   公会红包主界面
local REDPACKTYPE = {
	gold = gLanguageCsv.goldRedPack,
	rmb = gLanguageCsv.diamondRedPack,
	coin3 = gLanguageCsv.unionCoinRedPack,
}

-- DISPOSABLE:一次性
-- PERMANENT:循环
-- EVERYDAY:每天一次
local REDPACKETTYPE = {
	DISPOSABLE = 1,
	PERMANENT = 2,
	EVERYDAY = 3,
}

local STATESHOW = {
	[3] = gLanguageCsv.send,
	[4] = gLanguageCsv.get,
}

local PACKETTYPE = {
	PLAYER = 0,
	SYSTEM = 1,
}

local function sort(a, b)
	local redPacketTab = csv.union.red_packet
	local infoa = redPacketTab[a.csv_id].sortVal
	local infob = redPacketTab[b.csv_id].sortVal
	if infoa ~= infob then
		return infoa > infob
	end
	if a.csv_id ~= b.csv_id then
		return a.csv_id < b.csv_id
	end
	if a.idx and b.idx and a.idx ~= b.idx then
		return a.idx < b.idx
	end
	return false
end

local function setEffect(parent, actionName, cb)
	parent:removeAllChildren()
	parent:show()
	local size = parent:size()
	local effect = widget.addAnimationByKey(parent, "union/hongbao.skel", actionName, actionName, 2)
		:xy(size.width/2 + 2, size.height/2 + 50)
	effect:setSpriteEventHandler(function(event, eventArgs)
		parent:hide()
		cb()
	end, sp.EventType.ANIMATION_COMPLETE)
end

local function onInititem(listview, node, k, v)
	local pageIdx = v.pageIdx
	node:get("title.textTitle2"):visible(pageIdx == 2)
	node:get("info2"):visible(pageIdx == 2)
	node:get("textSchedule"):visible(pageIdx == 3)
	node:get("textScheduleBg"):visible(pageIdx == 3)
	node:get("title.textTitle1"):text(v.text)
	if v.showType == 2 then
		node:get("imgBg"):texture("city/union/redpack/img_hb1_h.png")
		node:get("info1.imgBg"):texture("city/union/redpack/box_d_h.png")
		node:get("info2.imgBg"):texture("city/union/redpack/box_d_h.png")
		node:get("leftTime.imgBg"):texture("common/box/box_d4.png")
		node:get("textScheduleBg"):texture("common/box/box_d4.png")
	end
	local text = STATESHOW[pageIdx]
	node:get("imgReceived"):hide()
	if not text then
		local leftNum = v.total_count - v.used_count
		local isInclude = itertools.include(v.members or {}, listview.id():read())
		text = gLanguageCsv.grab
		if isInclude or leftNum == 0 then
			text = gLanguageCsv.show
		end
		if isInclude and pageIdx == 2 then
			node:get("imgReceived"):show()
		end
	end
	node:get("textState"):text(text)
	node:get("info1.textNum"):text(v.total_val)
	local path = dataEasy.getIconResByKey(v.key)
	node:get("info1.imgIcon"):texture(path)
	node:get("leftTime"):visible(pageIdx == 2)
	local nowTime = time.getTime()
	if pageIdx == 2 then
		node:get("info1"):y(325)
		node:get("title.textTitle1"):y(30)
		node:get("title.textTitle2"):text(string.format(gLanguageCsv.redpackSender, v.role_name))
		node:get("info2.textLeftNum"):text(v.total_count - v.used_count)
		node:get("info2.textAllNum"):text("/" .. v.total_count)
		local tag = listview:enableSchedule():schedule(function()
			if itertools.size(listview.playerDatas()[2]) < 1 or v.delta <= 0 then
				listview.tipPanel():hide()
				return false
			end
			local timeTab = time.getCutDown(v.delta)
			node:get("leftTime.textLeftTime"):text(timeTab.str)
		end, 0.5, 0, "schedulePage2Node"..v.idx)
		table.insert(listview.schedulePage2NodeTags(), tag)

	elseif pageIdx == 3 then
		node:get("info1"):y(290)
		local curTime = v.delta
		local timeTab= time.getCutDown(curTime)
		node:get("textSchedule"):text(timeTab.str)
		local tag = listview:enableSchedule():schedule(function()
			if itertools.size(listview.playerDatas()[3]) < 1 or v.delta <= 0 then
				listview.tipPanel():hide()
				return false
			end
			local timeTab = time.getCutDown(v.delta)
			node:get("textSchedule"):text(timeTab.str)
		end, 0.5, 0, "scheduleNode"..v.idx)
		table.insert(listview.scheduleNodeTags(), tag)

	elseif pageIdx == 4 then
		node:get("info1"):y(290)
	end
end

local RedPackView = class("RedPackView", cc.load("mvc").ViewBase)

RedPackView.RESOURCE_FILENAME = "union_redpack.json"
RedPackView.RESOURCE_BINDING = {
	["btnRule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleClick")},
		},
	},
	["btnItem"] = "btnItem",
	["leftList"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftBtns"),
				item = bindHelper.self("btnItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:setName("tab" .. list:getIdx(k))
					local btnSel = node:get("btnSelect")
					local btnClick = node:get("btnClick")
					btnSel:visible(v.isSel)
					btnClick:visible(not v.isSel)
					btnSel:get("textNote"):text(v.text1)
					btnClick:get("textNote1"):text(v.text1)
					btnClick:get("textNote2"):text(v.text2)
					if v.redHint then
						list.state = v.isSel ~= true
						bind.extend(list, btnClick, v.redHint)
					end
					bind.touch(list, node:get("btnClick"), {methods = {
						ended = functools.partial(list.clickCell, k, v)
					}})
					adapt.setTextScaleWithWidth(btnSel:get("textNote"), nil, 250)
					adapt.setTextScaleWithWidth(btnClick:get("textNote1"), nil, 250)
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onButtonClick"),
			},
		},
	},
	["effectPanel"] = "effectPanel",
	["404panel"] = "tipPanel",
	["404panel.textTip"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("tips"),
		},
	},
	["item"] = "item",
	["list1"] = {
		varname = "list1",
		binds = {
			{
				event = "extend",
				class = "listview",
				props = {
					data = bindHelper.self("dailyDatas"),
					item = bindHelper.self("item"),
					margin = bindHelper.self("list1Margin"),
					onItem = function(list, node, k, v)
						node:setName("item" .. list:getIdx(k))
						local path = dataEasy.getIconResByKey(v.key)
						node:get("imgIcon"):texture(path)
						node:get("textTitle"):text(v.text)
						node:get("info1.textNum"):text(v.total_val)
						local leftNum = v.total_count - v.used_count
						node:get("info2.textLeftNum"):text(leftNum)
						node:get("info2.textAllNum"):text("/" .. v.total_count)
						node:get("info3.textNum"):text(v.top_role_name or gLanguageCsv.noOneRob)
						local color = ui.COLORS.NORMAL.ALERT_ORANGE
						if leftNum > 0 then
							color = ui.COLORS.NORMAL.FRIEND_GREEN
						end
						local isInclude = itertools.include(v.members or {}, list.id():read())
						node:get("imgReceived"):visible(isInclude)
						text.addEffect(node:get("info2.textLeftNum"), {color = color})
						bind.touch(list, node, {methods = {
							ended = functools.partial(list.clickCell, k, v)
						}})
						adapt.oneLinePos(node:get("info1.textNote"), node:get("info1.textNum"), cc.p(10,0))
						adapt.oneLinePos(node:get("info2.textNote"), node:get("info2.textLeftNum"),cc.p(10,0))
						adapt.oneLinePos(node:get("info2.textLeftNum"), node:get("info2.textAllNum"),cc.p(0,0))
						adapt.oneLinePos(node:get("info3.textNote"), node:get("info3.textNum"),cc.p(10,0))
					end,
				},
				handlers = {
					clickCell = bindHelper.self("onItemClick"),
					id = bindHelper.self("id"),
				},
			},
			{
				event = "visible",
				idler = bindHelper.self("isDailyPage")
			},
		},
	},
	["textTimesNote"] = "textTimesNote",
	["textTimesNum"] = "textTimesNum",
	["textTimesMax"] = "textTimesMax",
	["item1"] = "item1",
	["innweList"] = "innweList",
	["list2"] = {
		varname = "list2",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("isDailyPage"),
				method = function(val)
					return not val
				end,
			},
			{
				event = "extend",
				class = "tableview",
				props = {
					data = bindHelper.self("redPackDatas"),
					item = bindHelper.self("innweList"),
					cell = bindHelper.self("item1"),
					columnSize = 3,
					asyncPreload = 6,
					xMargin = bindHelper.self("innweListMargin"),
					backupCached = false,
					itemAction = {isAction = true},
					onCell = function(list, node, k, v)
						onInititem(list, node, k, v)
						bind.touch(list, node, {methods = {
							ended = functools.partial(list.onClickCell, k, v)
						}})
					end,
				},
				handlers = {
					onClickCell = bindHelper.self("onClickCell"),
					id = bindHelper.self("id"),
					playerDatas = bindHelper.self("playerDatas"),
					tipPanel = bindHelper.self("tipPanel"),
					schedulePage2NodeTags = bindHelper.self("schedulePage2NodeTags"),
					scheduleNodeTags = bindHelper.self("scheduleNodeTags"),
				},
			},
		},
	},
}

function RedPackView:onCreate(redPackets, pageIdx)
	-- 适配问题	begin
	local list1ShowNum = 3 		-- list1显示区域item数量
	local innweListShowNum = 3 	-- innweList显示区域item数量
	adapt.centerWithScreen("left", "right", nil, {
		{self.list1, "width"},
		{self.list2, "width"},
		{self.innweList, "width"},
		{self.list1, "pos", "left"},
		{self.list2, "pos", "left"},
	})

	self.list1Margin = (self.list1:width() - self.item:width()*list1ShowNum)/2
	self.innweListMargin = (self.innweList:width() - self.item1:width()*innweListShowNum)/2
	-- 适配问题 end

	pageIdx = pageIdx or 1
	self.redPackets = redPackets
	self:initModel()
	gGameUI.topuiManager:createView("union", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.guild, subTitle = "CONSORTIA"})

	local leftBtns = {
		{text1 = gLanguageCsv.dailyRedPack, text2 = "Everyday", isSel = false,
			redHint = {
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					specialTag = "unionSystemRedPacket",
					onNode = function (node)
						node:xy(366, 150)
							:z(10)
					end
				}
			}},
		{text1 = gLanguageCsv.membersRedPack, text2 = "Members", isSel = false,
			redHint = {
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					specialTag = "unionMemberRedPacket",
					onNode = function (node)
						node:xy(366, 150)
							:z(10)
					end
				}
			}},
		{text1 = gLanguageCsv.sendRedPack, text2 = "Give", isSel = false,
			redHint = {
				class = "red_hint",
				props = {
					state = bindHelper.self("state"),
					specialTag = "unionSendedRedPacket",
					onNode = function (node)
						node:xy(366, 150)
							:z(10)
					end
				}
			}},
		{text1 = gLanguageCsv.getRedPack, text2 = "Acquire", isSel = false},
	}
	leftBtns[pageIdx].isSel = true
	self.isResetDatas = true
	self.scheduleNodeTags = {}
	self.schedulePage2NodeTags = {}
	self.scheduleTags = {}
	self.schedulePage2Tags = {}
	self.leftBtns = idlers.newWithMap(leftBtns)
	self.lastPageIdx = idler.new(pageIdx)
	local dailyDatas = {}
	local unionInfo = csv.union.union_level[self.unionLv:read()]
	local redPacketTab = csv.union.red_packet
	for k,v in pairs(redPackets or {}) do
		if v.packet_flag == PACKETTYPE.SYSTEM then
			local packetType = v.packet_type
			local key, _ = csvNext(unionInfo["dailyPacket" .. (packetType + 1)])
			v.key = key
			v.text = REDPACKTYPE[key]
			table.insert(dailyDatas, v)
		end
	end
	table.sort(dailyDatas, function(a, b)
		return a.packet_type < b.packet_type
	end)
	self.dailyDatas = idlertable.new(dailyDatas)
	self.redPackDatas = idlers.newWithMap({})
	self.isDailyPage = idler.new(pageIdx == 1)
	self.tips = idler.new("")
	idlereasy.when(self.lastPageIdx, function(idler, lastPageIdx)
		local oldval = idler:read() or lastPageIdx
		self.leftBtns:atproxy(oldval).isSel = false
		self.leftBtns:atproxy(lastPageIdx).isSel = true
		if lastPageIdx ~= 1 then
			self.list2:jumpToTop()
			self:unNodeSchedule()
			if self.isResetDatas then
				self:refreshDatas()
			end
			self.redPackDatas:update(self.playerDatas[self.lastPageIdx:read()])
		end
		if lastPageIdx == 3 then
			gGameModel.currday_dispatch:getIdlerOrigin("sendedRedPacket"):set(true)
		end
		local size = self.redPackDatas:size()
		self.tipPanel:visible(size < 1 and lastPageIdx ~= 1)
		local str = lastPageIdx == 3 and gLanguageCsv.sendRedPackTip or gLanguageCsv.notHasRedPack
		self.tips:set(str)

		return true, lastPageIdx
	end)
	idlereasy.when(self.unionRedpackets, function(_, unionRedpackets)
		self:refreshDatas(unionRedpackets)
	end)
	idlereasy.when(self.redPackDatas, function(_, redPackDatas)
		local idx = self.lastPageIdx:read()
		self.tipPanel:visible(idx ~= 1 and itertools.size(redPackDatas) <= 0)
	end)
	--抢红包数量
	idlereasy.any({self.redPacketRobCount, self.lastPageIdx}, function(_, redPacketRobCount, lastPageIdx)
		itertools.invoke({self.textTimesNum, self.textTimesMax, self.textTimesNote}, lastPageIdx == 2 and "show" or "hide")
		local maxNum = gCommonConfigCsv.unionRobRedpacketDailyLimit
		local subTimes = cc.clampf(maxNum - redPacketRobCount, 0, maxNum)
		self.textTimesNum:text(subTimes)
		self.textTimesMax:text("/"..maxNum)
		local color = ui.COLORS.NORMAL.FRIEND_GREEN
		if subTimes <= 0 then
			color = ui.COLORS.NORMAL.ALERT_ORANGE
		end
		text.addEffect(self.textTimesNum, {color = color})
		adapt.oneLinePos(self.textTimesNote,{self.textTimesNum, self.textTimesMax})
	end)
end

function RedPackView:initModel()
	local unionInfo = gGameModel.union
	self.unionLv = unionInfo:getIdler("level")
	self.id = gGameModel.role:getIdler("id")
	self.unionRedpackets = gGameModel.role:getIdler("union_redpackets")
	self.unionRedpacketTimes = gGameModel.role:getIdler("union_redpacket_times")
	local dailyRecord = gGameModel.daily_record
	self.redPacketDaily = dailyRecord:getIdler("redPacket_daily")
	-- 今日已抢红包数量 不包括系统红包
	self.redPacketRobCount = dailyRecord:getIdler("redPacket_rob_count")
end

function RedPackView:isUseRedPacket(csvId)
	local redPacketTab = csv.union.red_packet
	local info = redPacketTab[csvId]
	if info.type == REDPACKETTYPE.PERMANENT then
		return true
	end
	local sendInfo = self.unionRedpacketTimes:read()
	if info.type == REDPACKETTYPE.DISPOSABLE then
		if sendInfo[csvId] then
			return false
		end

		return true
	end

	if info.type == REDPACKETTYPE.EVERYDAY then
		local result = itertools.include(self.redPacketDaily:read(), csvId)

		return not result
	end
end

function RedPackView:refreshDatas(info2)
	local curPageIdx = self.lastPageIdx:read()
	if curPageIdx ~= 1 then
		self:unNodeSchedule()
	end
	info2 = info2 or self.unionRedpackets:read()
	local redPacketTab = csv.union.red_packet
	self.playerDatas = {[2] = {}, [3] = {}, [4] = {}}
	local count = 0
	for k,v in pairs(self.redPackets or {}) do
		if v.packet_flag == PACKETTYPE.PLAYER then
			local date = redPacketTab[v.csv_id].date
			local delta = (v.created_time or 0) + date * 24 * 3600 - time.getTime()
			if delta > 0 then
				count = count + 1
				local info = redPacketTab[v.csv_id]
				local key, _ = csvNext(info.totalVal)
				table.insert(self.playerDatas[2], {
					id = v.id,
					csv_id = v.csv_id,
					key = key,
					text = info.name,
					showType = info.showType,
					total_val = v.total_val,
					used_count = v.used_count,
					total_count = info.totalCount,
					delta = delta,
					idx = count,
					used_val = v.used_val,
					members = v.members,
					pageIdx = 2,
					role_name = v.role_name
				})
			end
		end
	end

	count = 0
	for k,v in pairs(info2) do
		local csvId = v[1]
		local data = redPacketTab[csvId]
		local delta = v[2] + data.date * 24 * 3600 - time.getTime()
		if delta > 0 then
			local key, val = csvNext(data.totalVal)
			count = count + 1
			table.insert(self.playerDatas[3], {
				id = data.id,
				csv_id = csvId,
				key = key,
				text = data.name,
				total_val = val,
				used_count = data.used_count,
				total_count = data.totalCount,
				delta = delta,
				idx = count, -- 用于更新界面移除用
				serIdx = k, -- 用于请求用
				members = data.members,
				pageIdx = 3,
				showType = data.showType,
			})
		end
	end

	for k, v in orderCsvPairs(csv.union.red_packet) do
		if self:isUseRedPacket(k) then
			local key, val = csvNext(v.totalVal)
			table.insert(self.playerDatas[4], {
				csv_id = k,
				id = v.id,
				key = key,
				text = v.name,
				total_val = val,
				used_count = v.used_count,
				total_count = v.totalCount,
				members = v.members,
				pageIdx = 4,
				goto = v.goto,
				tipText = v.tipText,
				showType = v.showType,
			})
		end
	end

	for k,v in pairs(self.playerDatas) do
		table.sort(v, function(a, b)
			if k == 2 then
				local lefta = a.total_count - a.used_count
				local leftb = b.total_count - b.used_count
				if lefta ~= 0 and leftb ~= 0 then
					local includea = itertools.include(a.members, self.id:read())
					local includeb = itertools.include(b.members, self.id:read())
					if includea ~= includeb then
						return includeb == true
					else
						return sort(a, b)
					end
				elseif lefta == 0 and leftb == 0 then
					return sort(a, b)
				else
					return leftb == 0
				end

			else
				return sort(a, b)
			end
		end)
	end
	-- 更新数据之后 定时器也都刷一遍
	self:createSchedule()
	if curPageIdx ~= 1 then
		self.redPackDatas:update(self.playerDatas[curPageIdx])
	end
	self.isResetDatas = false
end

function RedPackView:unNodeSchedule()
	for idx,tag in ipairs(self.scheduleNodeTags) do
		self:unSchedule(tag)
	end
	self.scheduleNodeTags = {}
	for idx,tag in ipairs(self.schedulePage2NodeTags) do
		self:unSchedule(tag)
	end
	self.schedulePage2NodeTags = {}
end

function RedPackView:createSchedule()
	for k,v in ipairs(self.scheduleTags) do
		self:unSchedule(v)
	end
	for i,v in ipairs(self.schedulePage2Tags) do
		self:unSchedule(v)
	end
	local curTime = time.getTime()
	for i,v in ipairs(self.playerDatas[2]) do
		local t = v.delta
		local tag = self:enableSchedule():schedule(function()
			t = t - 1
			if t <= 0 then
				self.playerDatas[2][i] = nil
				dataEasy.tryCallFunc(self.list2, "updatePreloadCenterIndex")
				self.redPackDatas:update(self.playerDatas[2])
				return false
			end
			if not self.playerDatas[2][i] then
				return false
			end
			self.playerDatas[2][i].delta = t
		end, 1, 0, "schedulePage2"..v.idx)
		table.insert(self.schedulePage2Tags, tag)
	end
	for i,v in ipairs(self.playerDatas[3]) do
		local t = v.delta
		local tag = self:enableSchedule():schedule(function()
			t = t - 1
			if t <= 0 then
				self.playerDatas[3][i] = nil
				dataEasy.tryCallFunc(self.list2, "updatePreloadCenterIndex")
				self.redPackDatas:update(self.playerDatas[3])
				return false
			end
			if not self.playerDatas[3][i] then
				return false
			end
			self.playerDatas[3][i].delta = t
		end, 1, 0, "schedule"..v.idx)
		table.insert(self.scheduleTags, tag)
	end
end

function RedPackView:onButtonClick(listview, k, v)
	dataEasy.tryCallFunc(self.list2, "setItemAction", {isAction = true})
	self.isDailyPage:set(k == 1)
	self.lastPageIdx:set(k)
end

function RedPackView:onItemClick(listview, k, v)
	if dataEasy.notUseUnionBuild() or not dataEasy.canSystemRedPacket() then
		gGameUI:showTip(gLanguageCsv.cannotUseBuilding)
		return
	end
	if not itertools.include(v.members, self.id:read()) and (v.total_count - v.used_count) ~= 0 then
		gGameApp:requestServer("/game/union/redpacket/rob",function (tb)
			tb.view[v.id].key = v.key
			tb.view[v.id].text = v.text
			self.dailyDatas:modify(function(oldval)
				oldval[k] = tb.view[v.id]
				return true, oldval
			end, true)
			setEffect(self.effectPanel, "da", function()
				gGameUI:showGainDisplay(tb.award)
			end)
		end, v.id)
	else
		gGameApp:requestServer("/game/union/redpacket/detail",function (tb)
			gGameUI:stackUI("city.union.redpack.detail", nil, nil, v, tb.view)
		end, v.id)
	end
end

function RedPackView:onClickCell(listview, k, v)
	local curIdx = self.lastPageIdx:read()
	if curIdx == 2 or curIdx == 3 then
		if dataEasy.notUseUnionBuild() then
			gGameUI:showTip(gLanguageCsv.cannotUseBuilding)
			return
		end
	end
	if curIdx == 2 then
		if itertools.include(v.members, self.id:read()) or (v.total_count - v.used_count) == 0 then
			gGameApp:requestServer("/game/union/redpacket/detail",function (tb)
				gGameUI:stackUI("city.union.redpack.detail", nil, nil, v, tb.view)
			end, v.id)
		else
			if self.redPacketRobCount:read() >= gCommonConfigCsv.unionRobRedpacketDailyLimit then
				gGameUI:showTip(gLanguageCsv.yourHandIsTooFast)
				return
			end
			gGameApp:requestServer("/game/union/redpacket/rob",function (tb)
				tb.view[v.id].key = v.key
				tb.view[v.id].text = v.text
				tb.view[v.id].showType = v.showType
				tb.view[v.id].idx = v.idx
				tb.view[v.id].delta = v.delta
				tb.view[v.id].pageIdx = 2
				for k,v in ipairs(self.schedulePage2NodeTags) do
					self:unSchedule(v)
				end
				-- 更新本地数据 然后在单个是刷新
				local t = listview:getIdx(k)
				self.playerDatas[self.lastPageIdx:read()][t.k] = tb.view[v.id]
				for k,v in pairs(tb.view[v.id]) do
					self.redPackDatas:atproxy(t.k)[k] = v
				end
				-- self.redPackDatas:update(self.playerDatas[self.lastPageIdx:read()])
				local effectName = v.showType == 2 and "huang" or "hong"
				setEffect(self.effectPanel, effectName, function()
					gGameUI:showGainDisplay(tb.award)
				end)
			end, v.id)
		end

	elseif curIdx == 3 then
		gGameUI:stackUI("city.union.redpack.send", nil, nil, k, v, self:createHandler("updateRedPacketDatas"))

	elseif curIdx == 4 then -- jump
		if v.goto then
			local func = function()
				jumpEasy.jumpTo(v.goto)
			end
			if v.goto == "recharge" then
				gGameUI:showDialog({content = gLanguageCsv.needRechargeMore, cb = func, btnType = 2, clearFast = true})
			else
				func()
			end
		else
			gGameUI:showTip(v.tipText)
		end
	end
end

function RedPackView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function RedPackView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.unionRedPacketRule)
		end),
		c.noteText(104),
		c.noteText(1001, 1010),
		c.noteText(105),
		c.noteText(1011, 1020),
	}
	return context
end

function RedPackView:updateRedPacketDatas(datas)
	self.redPackets = datas
	self.isResetDatas = true
	gGameUI:showTip(gLanguageCsv.redPacketSendSuccess)
end

return RedPackView