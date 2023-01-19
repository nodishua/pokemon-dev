local ViewBase = cc.load("mvc").ViewBase
local INPUT_LIMIT = 50
local CHANNELS = {
	news = {name = gLanguageCsv.system, icon = "city/chat/box_xtd.png"}, --系统
	world = {name = gLanguageCsv.world, icon = "city/chat/box_sjd.png"}, --世界
	union = {name = gLanguageCsv.guild, icon = "city/chat/box_ghd.png"}, --公会
	team = {name = gLanguageCsv.formTeam, icon = "city/chat/box_zdd.png"}, --组队
	huodong = {name = gLanguageCsv.activity, icon = "city/chat/box_hdd.png"}, --活动
	private = {name = gLanguageCsv.privateChat, icon = "city/chat/box_zdd.png"}, --私聊
}

local function setCommonContent(list, node, k, data)
	local useName = data.isMine and "mine" or "other"
	local panel = node:get(useName):visible(true)
	local panely = panel:y()
	local childs = panel:multiget("txtName", "txtFlag", "vip", "imgEmoji", "imgTextBG", "imgFlagBG", "rolePanel", "title")
	childs.txtFlag:text(CHANNELS[data.channel].name)
	if data.role then
		childs.txtName:text(data.role.name)
		if data.role.vip > 0 then
			childs.vip:texture(ui.VIP_ICON[data.role.vip]):show()
		else
			childs.vip:hide()
		end
		bind.extend(list, childs.rolePanel, {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = data.role.logo,
				frameId = data.role.frame,
				level = data.role.level,
				vip = false,
				onNodeClick = function(event)
					functools.partial(list.itemClick, k, data, node)(event)
				end,
			}
		})
		if data.role.title and data.role.title > 0 then
			bind.extend(list, childs.title, {
				event = "extend",
				class = "role_title",
				props = {
					data = data.role.title,
					onNode = function (node)
						childs.title:size(node:size())
						node:alignCenter(childs.title:size())
					end
				},
			})
		else
			childs.title:hide()
		end

		if data.isMine then
			adapt.oneLinePos(childs.txtFlag, {childs.vip, childs.txtName, childs.title}, {cc.p(30, 0), cc.p(10, 0)}, "right")
		else
			adapt.oneLinePos(childs.txtFlag, {childs.vip, childs.title, childs.txtName}, {cc.p(30, 0), cc.p(10, 0)}, "left")
		end
	end

	return panel, panely
end

local ChatView = class("ChatView", ViewBase)
ChatView.RESOURCE_FILENAME = "chat.json"
ChatView.RESOURCE_BINDING = {
	["chatPanel"] = "chatPanel",
	["topView"] = "topView",
	["chatPanel.bottomPanel.textInput"] = "textInput",
	["chatPanel.bottomPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("bottomShow")
		},
	},
	["chatPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["chatPanel.closePanel"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["chatPanel.bottomPanel.btnSend"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSendClick")},
		},
	},
	["chatPanel.bottomPanel.btnSend.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["chatPanel.bottomPanel.btnPicture"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPictureClick")},
		},
	},
	["btn"] = "btn",
	["chatPanel.btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnsInfo"),
				item = bindHelper.self("btn"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					local maxHeight = panel:size().height - 20
					adapt.setAutoText(panel:get("txt"), v.name, maxHeight)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, k)}})
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onChangePage"),
			},
		},
	},
	["item"] = "item",
	["chatPanel.list"] = {
		varname = "contentList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("contents"),
				item = bindHelper.self("item"),
				isRefresh = bindHelper.self("isRefresh"),
				onItem = function(list, node, k, v)
					list.initItem(node, k, v)
				end,
				-- backupCached = true,
				asyncPreload = 9,
				preloadBottom = true,
				onAfterBuild = function (list)
					idlereasy.if_(list.isRefresh, function (_, val)
						list:jumpToBottom()
					end):anonyOnly(list)
				end
			},
			handlers = {
				itemClick = bindHelper.self("onShowInfo"),
				initItem = bindHelper.self("onInitItem")
			},
		},
	},
}

function ChatView:onInitItem(list, node, k, v)
	local size = node:size()
	local diffy = 0
	local panel
	local childs = node:multiget("mine", "system", "other", "txtTime", "imgTime")
	local panely
	itertools.invoke({childs.mine, childs.system, childs.other}, "hide")
	--这个位置是我非常非常认真的拿像素量的。轻易莫动
	--富文本
	if itertools.first(game.MESSAGE_SHOW_TYPE[v.type], 1) then
		panel = childs.system:visible(true)
		panel:removeChildByName("_text_")
		panely = panel:y()
		local childs = panel:multiget("imgTextBG", "txtFlag", "txtContent", "imgFlagBG", "imgTextBG")
		childs.txtFlag:text(CHANNELS[v.channel].name)
		childs.imgFlagBG:texture(CHANNELS[v.channel].icon)
		childs.txtContent:removeAllChildren()
		local richText = rich.createWithWidth(v.msg, 40, nil, 800, nil, cc.p(0, 0))
		richText:anchorPoint(0, 1)
			:xy(10, 40)
			:addTo(childs.txtContent, 2)
			:name("_text_")
		childs.imgTextBG:size(richText:size().width+80, richText:size().height + 50)
		node:size(node:size().width, richText:size().height + 56)
		diffy = panel:size().height - richText:size().height - 66
		uiEasy.setUrlHandler(richText, v)
	--普通人物聊天
	elseif itertools.first(game.MESSAGE_SHOW_TYPE[v.type], 2) then
		panel, panely = setCommonContent(list, node, k, v)
		panel:removeChildByName("_text_")
		local xDiff = v.isMine and -30 or 0
		local childs = panel:multiget("txtName", "txtFlag", "vip", "imgEmoji", "imgTextBG", "imgFlagBG", "rolePanel", "title")
		local emojiKey = string.match(v.msg, "%[(%w+)%]")
		local height = 0
		childs.imgFlagBG:texture(CHANNELS[v.channel].icon)
		childs.imgEmoji:visible(gEmojiCsv[emojiKey] ~= nil)
		if gEmojiCsv[emojiKey] then
			childs.imgEmoji:texture(gEmojiCsv[emojiKey].resource)
			height = childs.imgEmoji:size().height
			local emojiSize = childs.imgEmoji:getBoundingBox()
			childs.imgTextBG:size(emojiSize.width + 40, emojiSize.height + 20)
			childs.imgEmoji:y(childs.imgTextBG:y() - childs.imgTextBG:height()/2)
			node:size(node:size().width, emojiSize.height + 136)
			diffy = panel:size().height - emojiSize.height - 146
		else
			local txtContent = panel:get("txtContent")
			local x,y = txtContent:xy()
			local label = cc.Label:createWithTTF(v.msg, ui.FONT_PATH, 40)
			label:anchorPoint(v.isMine and 1 or 0, 1)
				:xy(x, y + 5)
				:addTo(panel, 5)
				:name("_text_")
			label:setMaxLineWidth(550)
			label:setTextColor(ui.COLORS.NORMAL.DEFAULT)
			height = label:size().height
			local size = label:size()
			childs.imgTextBG:size(cc.size(size.width + 105, height + 60)) -- scale == 3
			node:size(node:size().width, height + 178)
			diffy = panel:size().height - height - 178
		end
		panel:x(panel:x() + xDiff)

	-- 战报分享 精灵分享
	elseif itertools.first(game.MESSAGE_SHOW_TYPE[v.type], 4) then
		panel, panely = setCommonContent(list, node, k, v)
		panel:removeChildByName("_text_")
		local childs = panel:multiget("txtContent", "imgTextBG", "imgEmoji")
		childs.imgEmoji:visible(false)
		local x, y = childs.imgTextBG:xy()
		local offx = v.isMine and -25 or 57
		local richText = rich.createWithWidth(v.msg, 40, nil, 550, nil, cc.p(0, 0))
		richText:anchorPoint(v.isMine and 1 or 0, 1)
			:xy(x + offx, y - 25)
			:addTo(panel, 3, "_text_")
		childs.imgTextBG:size(richText:size().width + 80, richText:size().height + 50)
		node:size(node:size().width, richText:size().height + 178)
		diffy = panel:size().height - richText:size().height - 178
		uiEasy.setUrlHandler(richText, v)
	end
	if v.showTime == true then
		childs.txtTime:text(self:timestampToStr(v.time))
		childs.imgTime:width(childs.txtTime:width()/2 + 20)
		childs.imgTime:y(node:height() + 58)
		childs.txtTime:y(node:height() + 58)
		node:size(node:size().width, node:size().height + 116)
	else
		childs.txtTime:hide()
		childs.imgTime:hide()
		node:size(node:size().width, node:size().height)
	end
	panel:y(panely - diffy)
end

function ChatView:playAction(isOpen, time, callback)
	if not self.chatPanelPosX then
		local dx = adapt.dockWithScreen(nil, "left", "up")

		self.chatPanelPosX = self.chatPanel:x() - 114 + dx
		self.chatPanel:x(self.chatPanelPosX)
	end

	local posx = isOpen and self.chatPanelPosX + self.chatPanel:size().width or self.chatPanelPosX
	time = time or 0.3
	self.isPlayAction = true
	transition.executeSequence(self.chatPanel, true)
		:func(function()
			self.topView:visible(true)
		end)
		:moveTo(time, posx)
		:func(function()
			self.isPlayAction = false
			self.topView:visible(false)
			if not isOpen then
				ViewBase.onClose(self)
			end
			if callback then
				callback()
			end
		end)
		:done()
end

-- 用来重新整理显示数据 当服务器数据发生变化的时候
function ChatView:initModel()
	self.id = gGameModel.role:getIdler("id")
	self.unionId = gGameModel.role:getIdler("union_db_id")
	self.chatMsgIdler = {
		gGameModel.messages:getIdler('news'),
		gGameModel.messages:getIdler('world'),
		gGameModel.messages:getIdler('union'),
		gGameModel.messages:getIdler('team'),
		--gGameModel.messages:getIdler('huodong'),
	}
end

function ChatView:onCreate(idx)
	idx = idx or 2
	self:initModel()
	blacklist:addListener(self.textInput, "*", function (text)
		self.textInput:text(string.utf8limit(text, INPUT_LIMIT, true))
	end)
	self.bottomShow = idler.new(true)
	self.textInput:setPlaceHolderColor(ui.COLORS.DISABLED.WHITE)
	self.textInput:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	-- self.btnToBottomShow = idler.new(false)
	-- self.isLockList = false -- 是否锁定屏幕不移动
	-- local container = self.contentList:getInnerContainer()
	-- local height = self.contentList:size().height
	-- self.contentList:onScroll(function(event)
	-- 	local y = container:getPositionY()
	-- 	self.isLockList = math.abs(y) > 250
	-- 	self.btnToBottomShow:set(math.abs(y) > 250)
	-- end)
	self.btnsInfo = {
		{name = gLanguageCsv.system, tag = "news", showBottom = false, text = gLanguageCsv.currChannelNotTalk},
		{name = gLanguageCsv.world, tag = "world", showBottom = true},
		{name = gLanguageCsv.guild, tag = "union", showBottom = false, text = gLanguageCsv.notGuildNotUse},
		-- {name = gLanguageCsv.privateChat, tag = "role", showBottom = true},
		-- {name = gLanguageCsv.formTeam, tag = "team", showBottom = false, text = gLanguageCsv.currChannelNotTalk},
		--{name = gLanguageCsv.activity, tag = "huodong", showBottom = false},
	}
	idx = idx > #self.btnsInfo and 2 or idx
	self.btnsInfo = idlers.newWithMap(self.btnsInfo)
	idlereasy.when(self.unionId, function (_, id)
		if id then
			--有公会
			self.btnsInfo:atproxy(3).showBottom = true
		else
			self.btnsInfo:atproxy(3).showBottom = false
		end
	end)
	local originY = self.contentList:y()
	local originSize = self.contentList:size()
	self.contents = idlers.newWithMap({})
	self.showTab = idler.new(idx)
	self.isRefresh = idler.new(false)
	self.showTab:addListener(function(val, oldval, idler)
		self.btnsInfo:atproxy(oldval).select = false
		self.btnsInfo:atproxy(val).select = true
		self.bottomShow:set(self.btnsInfo:atproxy(val).showBottom)
		if self.btnsInfo:atproxy(val).showBottom then
			self.contentList:y(originY + 130)
			self.contentList:size(originSize.width, originSize.height - 130)
		else
			self.contentList:y(originY)
			self.contentList:size(originSize.width, originSize.height)
		end
		-- self.isLockList = false
		self.firstEnter = true
		idlereasy.when(self.chatMsgIdler[val], function (obj, messages)
			if val == self.showTab:read() then
				dataEasy.tryCallFunc(self.contentList, "updatePreloadCenterIndex")
				for k, v in ipairs(messages) do
					if k == 1 then
						messages[k].showTime = true
					elseif v.time - messages[k - 1].time > 5 * 60 or messages[k - 1].time - v.time > 0 then
						messages[k].showTime = true
					else
						messages[k].showTime = false
					end
				end
				self.contentList:refreshView()
				local percent = self.contentList:getScrolledPercentVertical()
				self.contents:update(messages)
				if not self.firstEnter then
					self.contentList:enableAsyncload()
					self.isRefresh:set(true)
					self.contentList:quickFor("sync")
					if percent > 99 then
						self.contentList:jumpToBottom()
					end
				end
			end
		end):anonyOnly(self, "chat"..self.btnsInfo:atproxy(val).tag)
		self.firstEnter = false
	end)

	self:playAction(true)
end

-- -- 进入选择表情界面
function ChatView:onPictureClick(node, event)
	if not self.isPlayAction then
		local channel = self.btnsInfo:atproxy(self.showTab).tag
		gGameUI:stackUI("city.chat.emoji", nil, nil, nil, channel, self.contentList)
	end
end

function ChatView:onShowInfo(list, k, v, target)
	if not v.isMine then
		local x, y = target:xy()
		local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
		gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, v)
	end
end

function ChatView:onChangePage(list, index)
	self.showTab:set(index)
end

function ChatView:onSendClick(node, event)
	if not dataEasy.isUnlock(gUnlockCsv.worldChat) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.worldChat))
		return
	end
	local input = self.textInput:getStringValue()
	if input == nil or input == "" then
		gGameUI:showTip(gLanguageCsv.canNotEmpty)
	else
		gGameApp:requestServer("/game/chat",function (tb)
			self.contentList:jumpToBottom()
			self.textInput:text("")
		end, input, self.btnsInfo:atproxy(self.showTab:read()).tag)
	end
end

function ChatView:onClose()
	self:playAction(false)
end

--时间戳转换成时间函数
function ChatView:timestampToStr(stamp)
	local tTime = time.getDate(stamp)
	local hourAndMin = string.format("%02d:%02d",tTime.hour, tTime.min)
	if time.getTime()  - stamp > 7 * 24 * 3600 then--显示日期
		local monthAndDay = string.formatex(gLanguageCsv.timeMonthDay, {month = tTime.month, day = tTime.day})
		return monthAndDay .. " " .. hourAndMin
	elseif tTime.day ~= time.getDate(time.getTime()).day then--显示周几
		local wday = tTime.wday == 1 and 7 or tTime.wday - 1
		return gLanguageCsv["weekday"..wday] .. " " .. hourAndMin
	else--只显示时间
		return hourAndMin
	end
end

return ChatView