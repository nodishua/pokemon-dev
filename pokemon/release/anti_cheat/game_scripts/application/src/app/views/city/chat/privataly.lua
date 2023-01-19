local INPUT_LIMIT = 50
local ChatPrivatalyView = class("ChatPrivatalyView", Dialog)
local ViewBase = cc.load("mvc").ViewBase
--时间戳转换成时间函数
local function timestampToStr(stamp)
	local tTime = time.getDate(stamp)
	local hourAndMin = string.format("%02d:%02d",tTime.hour, tTime.min)
	if time.getTime()  - stamp > 7 * 24 * 3600 then--显示日期
		local monthAndDay = string.formatex(gLanguageCsv.timeMonthDay, {month = tTime.month, day = tTime.day})
		return monthAndDay .. " " .. hourAndMin
	elseif tTime.day ~= time.getDate(time.getTime()).day then--显示周几
		-- tTime.wday  周日1 周一2
		local wday = tTime.wday == 1 and 7 or tTime.wday - 1
		return gLanguageCsv["weekday"..wday] .. " " .. hourAndMin
	else--只显示时间
		return hourAndMin
	end
end


ChatPrivatalyView.RESOURCE_FILENAME = "chat_privataly.json"
ChatPrivatalyView.RESOURCE_BINDING = {
	["tipsText"] = "tipsText",
	["tipsBg"] = "tipsBg",
	["bottomPanel.textInput"] = "textInput",
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["bottomPanel.btnSend"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSendClick")},
		},
	},
	["bottomPanel.btnSend.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["bottomPanel.btnPicture"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPicClick")},
		},
	},
	["leftPanel.item"] = "leftItem",
	["leftPanel.sliderBg"] = "sliderBg",
	["leftPanel.list"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("personInfo"),
				item = bindHelper.self("leftItem"),
				barBg = bindHelper.self("sliderBg"),
				margin = -20,
				asyncPreload = 6,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("selected", "name", "level", "lv", "btnDelete", "icon", "itemNode")
					childs.itemNode:setEnabled(not v.select)
					childs.selected:visible(v.select == true)
					childs.icon:visible(v.select == true)
					if v.select == true then
						itertools.invoke({childs.name, childs.level ,childs.lv}, "setTextColor", ui.COLORS.NORMAL.WHITE)
					else
						itertools.invoke({childs.name, childs.level ,childs.lv}, "setTextColor", ui.COLORS.NORMAL.DEFAULT)
					end
					adapt.oneLinePos(childs.lv, childs.level, cc.p(5, 0), "left")
					childs.level:text(v.role.level)
					childs.name:text(v.role.name)
					bind.extend(list, childs.itemNode, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.role.logo,
							frameId = v.role.frame or 1,
							level = false,
							vip = false,
							onNode = function(node)
								node:x(110)
									:scale(0.8)
									:z(6)
							end,
						}
					})
					childs.icon:onTouch(functools.partial(list.iconClick, k, v))
					childs.itemNode:onTouch(functools.partial(list.itemClick, k, v))
					-- childs.btnDelete:onClick(functools.partial(list.delClick, k))
				end,
				onBeforeBuild = function(list)
					local listX, listY = list:xy()
					local listSize = list:size()
					local x, y = list.barBg:xy()
					local size = list.barBg:size()
					list:setScrollBarEnabled(true)
					list:setScrollBarColor(cc.c3b(241, 59, 84))
					list:setScrollBarOpacity(255)
					list:setScrollBarWidth(13)
					list:setScrollBarAutoHideEnabled(false)
					list:setScrollBarPositionFromCorner(cc.p(size.width+1, (listSize.height - size.height) / 2 + 10))
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onChangePerson"),
				delClick = bindHelper.self("onDeletePerson"),
				iconClick = bindHelper.self("playerInfo"),
			},
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "rightList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("chatContents"),
				item = bindHelper.self("item"),
				asyncPreload = 5,
				margin = -10,
				preloadBottom = true,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					-- print("----",k,v)
					local panelName = v.isMine and "mine" or "other"
					itertools.invoke({node:get("mine"), node:get("other")}, "hide")
					local panel = node:get(panelName):visible(true)
					local panely = panel:y()
					local childs = panel:multiget("imgEmoji", "imgTextBG", "txtContent")
					bind.extend(list, panel, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.role.logo,
							frameId = v.role.frame,
							level = false,
							vip = false,
							onNode = function(node)
								node:xy(v.isMine and 1210 or 100, 90)
									:scale(0.8)
							end,
						}
					})
					local emojiKey = string.match(v.msg,"%[(%w+)%]")
					local height = 0
					local size = node:size()
					local diffy
					childs.imgEmoji:visible(gEmojiCsv[emojiKey] ~= nil)
					if gEmojiCsv[emojiKey] then
						childs.imgEmoji:texture(gEmojiCsv[emojiKey].resource)
						height = childs.imgEmoji:size().height
						local emojiSize = childs.imgEmoji:getBoundingBox()
						childs.imgTextBG:size(emojiSize.width + 40, emojiSize.height + 20)
						node:size(node:size().width, emojiSize.height + 86)
						diffy = panel:size().height - emojiSize.height - 86
					else
						if itertools.first(game.MESSAGE_SHOW_TYPE[v.type], 4) and true then
							-- 富文本展示
							panel:removeChildByName("richtext")
							local x, y = childs.txtContent:xy()
							local offx = v.isMine and -25 or 57
							local richText = rich.createWithWidth(v.msg, 40, nil, 550, nil, cc.p(0, 0))
							richText:anchorPoint(v.isMine and 1 or 0, 1)
								:xy(x, y + 5)
								:addTo(panel, 5, "richtext")
							childs.imgTextBG:size(richText:size().width + 80, richText:size().height + 50)
							node:size(node:size().width, richText:size().height + 178)
							diffy = panel:size().height - richText:size().height - 178
							uiEasy.setUrlHandler(richText, v)
						else
							local txtContent = panel:get("txtContent")
							local x,y = txtContent:xy()
							local label = cc.Label:createWithTTF(v.msg, ui.FONT_PATH, 40)
							label:anchorPoint(v.isMine and 1 or 0, 1)
								:xy(x, y + 5)
								:addTo(panel, 5)
							label:setMaxLineWidth(700)
							label:setTextColor(ui.COLORS.NORMAL.DEFAULT)
							height = label:size().height
							local size = label:size()
							childs.imgTextBG:size(cc.size(size.width + 105, height + 60)) -- scale == 3
							node:size(node:size().width, height + 134)
							diffy = panel:size().height - height - 134
						end
					end
					if v.showTime == true then
						node:get("txtTime"):text(timestampToStr(v.time))
						node:get("imgTime"):width(node:get("txtTime"):width()/2 + 20)
						node:get("imgTime"):y(node:height() + 58)
						node:get("txtTime"):y(node:height() + 58)
						node:size(node:size().width, node:size().height + 116)
					else
						node:get("txtTime"):hide()
						node:get("imgTime"):hide()
						node:size(node:size().width, node:size().height)
					end
					panel:y(panely - diffy)
				end,
				backupCached = false,
			},
			handlers = {
				itemClick = bindHelper.self("onShowInfoClick"),
			},
		},
	},
	["leftPanel"] = "leftPanel",
}

function ChatPrivatalyView:uiInit()
	self.textInput:setPlaceHolderColor(ui.COLORS.DISABLED.WHITE)
	self.textInput:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	blacklist:addListener(self.textInput,"*", function (text)
		self.textInput:text(string.utf8limit(text, INPUT_LIMIT, true))
	end)
	uiEasy.addTabListClipping(self.leftList, self.leftPanel, {offsetX = 14})
	self.tipsText:text(gLanguageCsv.preventFraudChatTips)
	if dataEasy.isUnlock(gUnlockCsv.preventFraud) then
		self.rightList:height(735)
		self.tipsText:show()
		self.tipsBg:show()
	else
		self.rightList:height(812)
		self.tipsText:hide()
		self.tipsBg:hide()
	end
end

function ChatPrivatalyView:initModel()
	self.myFriend = gGameModel.society:getIdler("friends")
	self.friendMessage = gGameModel.messages:getIdler('private')
	self.id = gGameModel.role:getIdler("id")
	self.logo = gGameModel.role:getIdler("logo")
	self.delectData = idler.new(true)
end

function ChatPrivatalyView:onCreate(personData)
	self:uiInit()
	self:initModel()
	local msgs = self.friendMessage:read()
	local lastIdx = itertools.size(msgs)
	if lastIdx ~= 0 then
		local lastId = msgs[lastIdx].id
		gGameModel.forever_dispatch:getIdlerOrigin("chatPrivatalyLastId"):set(lastId)
	end

	self.curSelIdx = 1
	self.curSelId = 0
	self.state = personData and true or false
	self.personData = personData
	self.personId = personData and personData.role.id
	self.changeInfo = false
	self.chatContents = idlertable.new({})		-- 记录当前显示的聊天对象的聊天内容
	self.personInfo = idlers.newWithMap({})		-- 所有聊天对象的个人信息、头像框等
	idlereasy.any({self.friendMessage, self.delectData}, function(obj,friendMessage)
		local friend = {}
		if not itertools.isempty(friendMessage) then
			for idx, message in ipairs(friendMessage) do
				local newMsg = table.deepcopy(message, true)
				local id = nil
				if message.isMine then
					if not newMsg.args then
						newMsg.args = {id = self.id:read(), logo = self.logo:read()}
					end
					id = newMsg.args.id
				else
					id = newMsg.role.id
				end
				friend[id] = friend[id] or {}
				table.insert(friend[id], newMsg)
				if message.args and id == self.personId then
					self.changeInfo = true
				end
			end
		end

		local messages = {}
		local isHave = false
		for k, v in pairs(friend) do
			-- 使用最新最后一条的显示
			local n = #v
			local detail = v[n].isMine and v[n].args or v[n].role
			if self.personData and k == self.personData.role.id then
				isHave = true
				self.curSelId = self.personData.role.id
				detail.name = self.personData.role.name
				detail.id = self.personData.role.id
				if itertools.isempty(friendMessage) then
					detail = self.personData.role
				end
			end
			table.insert(messages, {id = k, role = detail, content = v})
		end

		table.sort(messages, function (messageA, messageB)
			if self.personData then
				if messageA.role.id == self.personData.role.id then
					return true
				elseif messageB.role.id == self.personData.role.id then
					return false
				end
			end
			-- 聊天索引id
			local contentA = messageA.content
			local contentB = messageB.content
			return contentA[#contentA].id >= contentB[#contentB].id
		end)

		if not isHave and self.personData then
			table.insert(messages, 1, {id = self.personData.role.id, role = self.personData.role, content = {}})
			isHave = true
		end
		self.isShowDelBtn = idler.new(false)
		self.isShowDelBtn:addListener(function(val, oldval, idler)
			if not self.delBtn then
				return
			end
			self.delBtn:visible(val)
			if not val then
				self.delBtn = nil
			end
		end)

		local curIdlers = idlers.newWithMap(messages)
		for i, v in self.personInfo:ipairs() do
			self.personInfo:remove(i)
		end
		for i, v in curIdlers:ipairs() do
			self.personInfo:add(i, v)
		end
		if self.curSelId == 0 then
			self.curSelId = messages[1].id
			self.curSelIdx = 1
		else
			for i, v in ipairs(messages) do
				if v.id == self.curSelId then
					self.curSelIdx = i
				end
			end
		end
		self.curSelIdx = math.min(self.curSelIdx, #messages)
		for k1, v1 in ipairs(messages) do
			for k2, v2 in ipairs(v1.content) do
				if k2 == 1 then
					messages[k1].content[k2].showTime = true
				elseif v2.time - messages[k1].content[k2 - 1].time > 5 * 60 or messages[k1].content[k2 -1].time - v2.time > 0 then
					messages[k1].content[k2].showTime = true
				else
					messages[k1].content[k2].showTime = false
				end
			end
		end
		if not itertools.isempty(friendMessage) then
			self.chatContents:set(messages[self.curSelIdx].content)
			self.personInfo:atproxy(self.curSelIdx).select = true
		end
	end)
	local posterCd = gCommonConfigCsv.antiFraudPosterAppearsCD * 60 * 60
	local posterTime = userDefault.getForeverLocalKey("chatPosterTime", 0)
	if time.getTime() > posterCd + posterTime and dataEasy.isUnlock(gUnlockCsv.preventFraud) then
		gGameUI:stackUI("city.chat.poster")
		userDefault.setForeverLocalKey("chatPosterTime", time.getTime())
	end
	Dialog.onCreate(self)
end



function ChatPrivatalyView:onShowInfoClick(list, k, v, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, v)
end

-- 这边需要服务器数据的支持
function ChatPrivatalyView:onDeletePerson(list, k)
	-- self.personInfo:remove(k)
end

--角色详情
function ChatPrivatalyView:playerInfo(list, k, v, event)
	if event.name == "ended" then
		local target = event.target
		local x, y = target:xy()
		local pos = target:getParent():convertToWorldSpace(cc.p(x-450, y+200))
		-- @data,state参数：data=true,state=true 当前聊天是有记录，删除当前聊天依然存在别的聊天记录
		-- @data=true,state=false 当前聊天是没有记录，删除当前聊天依然存在别的聊天记录
		-- @data=false,state=true 当前聊天是有记录，删除当前聊天不存在别的聊天记录
		-- @data=false,state=false 当前聊天是没有记录，删除当前聊天不存在别的聊天记录
		-- @self.state判断进来时是否传入数据
		gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, v, {params = true, state = self.state, cb = function(data, state)
			if data then
				if not state or self.changeInfo then
					self.personData = nil
					self.delectData:set(false)
					self.state = false
				end
			elseif not state then
				Dialog.onClose(self)
			elseif state and self.state then
				if self.changeInfo then
					Dialog.onClose(self)
				end
			elseif state and not self.state then
				Dialog.onClose(self)
			end
		end})
	end
end

local beganPos, endPos
function ChatPrivatalyView:onChangePerson(list, k, v, event)
	local sender = event.target
	if event.name == "began" then
		beganPos = sender:getTouchBeganPosition()
		if flag then node:scale(2) end
	elseif event.name == "ended" then
		endPos = sender:getTouchEndPosition()
		local dis = endPos.x - beganPos.x
		if dis < 0 and -dis > 150 then
			self.isShowDelBtn:set(false)
			self.delBtn = sender:get("btnDelete")
			self.isShowDelBtn:set(true)
		else
			self.isShowDelBtn:set(false)
			if k == self.curSelIdx then
				return
			end
			self.personInfo:atproxy(self.curSelIdx).select = false
			self.personInfo:atproxy(k).select = true
			self.curSelIdx = k
			self.curSelId = v.role.id
			dataEasy.tryCallFunc(self.rightList, "setItemAction", {isAction = true})
			self.chatContents:set(v.content)
			self.rightList:jumpToBottom()
		end
	end
end

function ChatPrivatalyView:onPicClick(node, event)
	local baseInfo = self.personInfo:atproxy(self.curSelIdx).role
	local role = {
		id = baseInfo.id,
		level = baseInfo.level,
		logo = baseInfo.logo,
		name = baseInfo.name,
		vip = baseInfo.vip,
		frame = baseInfo.frame,
	}
	gGameUI:stackUI("city.chat.emoji", nil, nil, role, "role", self.rightList)
end

function ChatPrivatalyView:onSendClick(node, event)
	if not dataEasy.isUnlock(gUnlockCsv.roleChat) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.roleChat))
		return
	end
	local baseInfo = self.personInfo:atproxy(self.curSelIdx).role
	local role = {
		id = baseInfo.id,
		level = baseInfo.level,
		logo = baseInfo.logo,
		name = baseInfo.name,
		vip = baseInfo.vip,
		frame = baseInfo.frame,
	}
	if self.textInput:text() and self.textInput:text() ~= "" then
		gGameApp:requestServer("/game/chat", function (tb)
			self.textInput:text("")
			self.rightList:jumpToBottom()
		end, self.textInput:text(), "role", role)
	else
		gGameUI:showTip(gLanguageCsv.canNotEmpty)
	end
end

return ChatPrivatalyView