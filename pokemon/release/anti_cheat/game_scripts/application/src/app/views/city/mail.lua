--策划建议
local MailView = class("MailView", Dialog)
local TEXT_LIMIT = 100 * 2
local INPUT_LIMIT = 150 * 2

local function createLabel(parent, str, align)
	parent:removeAllChildren()
	beauty.singleTextLimitWord(str, {
		color = ui.COLORS.NORMAL.DEFAULT,
		fontSize = 50,
		fontPath = "font/youmi1.ttf",
	}, {
		width =  450,
		align = align
	})
		:addTo(parent, 10, "label")
end
MailView.RESOURCE_FILENAME = "mail.json"
MailView.RESOURCE_BINDING = {
	["left"] = "left",
	["left.noMailPanel"] = "noMailPanel",
	["left.title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["btnItem"] = "btnItem",
	["left.btnList"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("topPageBtns"),
				item = bindHelper.self("btnItem"),
				onItem = function(list, node, k, v)
					-- local childs = node:multiget("bg", "text")
					local btn = node:get("btn")
					local show = v.canReadNum > 0 and v.isRed ~= false
					local props = {
						class = "red_hint",
						props = {
							-- showType = "num",
							-- num = v.canReadNum,
							state = v.canReadNum > 0 and v.isRed ~= false,
							onNode = function (panel)
								panel:xy(190,110)
							end
						}
					}
					bind.extend(list, btn, props)
					local textNote = btn:get("textNote")
					textNote:text(v.name)
					btn:setTouchEnabled(not v.isSelected)
					btn:setBright(not v.isSelected)
					bind.touch(list, btn, {methods = {ended = functools.partial(list.itemClick, k)}})
					if v.isSelected then
						text.addEffect(textNote, {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}})
					else
						text.deleteEffect(textNote, {"outline"})
						text.addEffect(textNote, {color = ui.COLORS.NORMAL.RED})
					end
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onListPage"),
			},
		},
	},
	["left.maskPanel"] = "maskPanel",
	["item"] = "item",
	["left.list"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("pageDatas"),
				item = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortDatas", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("imgBG", "textTitle", "textSender", "textTime",
						"imgSel", "imgIcon")
					createLabel(childs.textTitle, v.subject, "left")
					childs.textSender:text(v.sender)
					local t = time.getDate(v.time)
					childs.textTime:text(table.concat({t.year, t.month, t.day}, "."))
					childs.imgSel:visible(v.isSelected)
					childs.imgBG:visible(not v.isSelected)
					if not v.isRead then
						if v.hasattach then
							childs.imgIcon:texture("city/mail/icon_post0.png")
						else
							childs.imgIcon:texture("city/mail/icon_post.png")
						end
					else
						if (v.attachs and itertools.size(v.attachs) > 0) or v.hasattach then
							childs.imgIcon:texture("city/mail/icon_post_open0.png")
						else
							childs.imgIcon:texture("city/mail/icon_post_open.png")
						end
					end
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, list:getIdx(v.db_id), v)}})
				end,
				--asyncPreload = 5,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["left.btnDelete"] = {
		varname = "deleteAll",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDeleteAllMail")},
		},
	},
	["left.btnDelete.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["left.btnGetAll"] = {
		varname = "getAll",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGetAllMail")},
		},
	},
	["left.textNum1"] = "textNum1",
	["left.textNum2"] = "textNum2",
	["left.textName"] = "textName",
	["left.btnGetAll.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["left.btnDetail"] = {
		varname = "btnDetail",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnDetail")},
		},
	},
	["right"] = "rightPanel",
	["right.textTitle"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("rightTitle")
		},
	},
	["right.textSortList"] = "textSortList",
	["right.textLongList"] = "textLongList",
	["right.textTimeNote"] = "textTimeNote",
	["right.textSender"] = {
		varname = "textSender",
		binds = {
			event = "text",
			idler = bindHelper.self("textSenderName")
		},
	},
	["right.textTime"] = {
		varname = "timeText",
		binds = {
			event = "text",
			idler = bindHelper.self("textTime")
		},
	},
	["right.btnGet"] = {
		varname = "getReward",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGetReward")},
		},
	},
	["right.btnGet.textNote"] = {
		varname = "getTextNote",
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
}

function MailView:initModel()
	self.mailboxIdler = gGameModel.role:getIdler("mailbox")
	self.readMailboxIdler = gGameModel.role:getIdler("read_mailbox")
	self.myFriend = gGameModel.society:getIdler("friends")
	self.count = gGameModel.daily_record:getIdler("union_mail_send_count")
	self.cardCapacity = gGameModel.role:getIdler("card_capacity")--背包容量
	self.cardDatas = gGameModel.role:getIdler("cards")--卡牌
	self.roleLv = gGameModel.role:getIdler("level")
end

function MailView:initData(mailbox, readMailbox, judgeState)
	self.curPage = self.curPage or 1
	self.datas = {} -- 全部页签数据
	for i = 1, 2 do
		self.datas[i] = {}
		self.topPageBtns:atproxy(i).canReadNum = 0
	end
	local t = {}
	local showTab = 2 --默认显示page
	local haveNew = false
	for i, v in ipairs(mailbox) do
		local data = self.topPageBtns:atproxy(csv.mail[v.type].tab)
		data.canReadNum = data.canReadNum + 1
		haveNew = true
		showTab = math.min(showTab, csv.mail[v.type].tab)
		v.isRead = false
		v.isSelected = false
		table.insert(t, v)
	end
	for i, v in ipairs(readMailbox) do
		v.isRead = true
		v.isSelected = false
		if not haveNew then
			showTab = math.min(showTab, csv.mail[v.type].tab)
		end
		table.insert(t, v)
	end
	table.sort(t, function(a, b)
		if a.isRead == b.isRead then
			return a.time > b.time
		elseif a.isRead and not b.isRead then
			return false
		elseif b.isRead and not a.isRead then
			return true
		end
	end)
	for i, v in ipairs(t) do
		self.datas[csv.mail[v.type].tab] = self.datas[csv.mail[v.type].tab] or {}
		table.insert(self.datas[csv.mail[v.type].tab], v)
	end
	self.originCurrPageData = clone(self.datas[self.curPage])
	if self.firstEnter then
		if not self.showPage then
			self.showPage = idler.new(showTab)
		else
			self.showPage:set(showTab)
		end
		self.firstEnter = false
	end

	if not self.pageDatas then
		self.pageDatas = idlers.new()
		self.pageDatas:update(self:composeData())
	else
		if judgeState then
			if #self.originCurrPageData < #self.datas[self.curPage] then
				local newMap = itertools.map(itertools.ivalues(self.originCurrPageData),function (k, v)
					return v.id or v.db_id, true
				end)
				local t = {}
				for i, v in ipairs(self.datas[self.curPage]) do
					if newMap[v.id or v.db_id] ~= true then
						table.insert(t, v)
					end
				end
				table.sort(t, function (a, b)
					return a.time < b.time
				end)
				for i, v in ipairs(t) do
					table.insert(self.originCurrPageData, 1, v)
				end
			elseif #self.originCurrPageData > #self.datas[self.curPage] or self.isOneKey then
				self.isOneKey = false
				self.originCurrPageData = clone(self.datas[self.curPage])
			end

			self.pageDatas:update(self:composeData())
		end
		if self.currReadMailId:read() and self.currReadMailId:read() ~= 0 then
			for i, v in ipairs(self.originCurrPageData) do
				if (self.currReadMailId:read() == v.id) or (self.currReadMailId:read() == v.db_id) then
					self.selectedItem = v.index
					self.pageDatas:atproxy(v.id or v.db_id).isSelected = true
				else
					if self.pageDatas:at(v.id or v.db_id) and self.pageDatas:atproxy(v.id or v.db_id) then
						self.pageDatas:atproxy(v.id or v.db_id).isSelected = false
					end
				end
			end
		end
		-- self.pageDatas:update(self.datas[self.curPage])
	end

	self.isShowTip:set(self.pageDatas:size() == 0)
end


function MailView:onCreate()
	self:initModel()
	self.unReadState1 = false
	self.originData = {}
	self.originCurrPageData = {}
	self.firstEnter = true
	self.isShowTip = idler.new(false)
	self.isShowRight = idler.new(false) -- 1：visible 2：unvisible
	self:showMaxMailTip()
	self.isShowRight:addListener(function(val, oldval, idler)
		if val then -- visible
			local x = self.rightPanel:x() - 18
			local w = self.rightPanel:size().width
			local lw = self.left:size().width
			self.left:x(x - (w + lw) / 2)
		else
			self.left:x(display.sizeInView.width / 2)
		end
		self.rightPanel:visible(val)
	end)
	self.currReadMailId = idler.new(0)
	-- 构造模拟数据
	self.tabDatas = {
		{name = gLanguageCsv.recieveMail, isSelected = true},
		{name = gLanguageCsv.sendMail, isSelected = false}
	}
	self.tabDatas = idlers.newWithMap(self.tabDatas)
	local firDatas = {}
	self.firDatas = idlertable.new({})
	self.sortDatas = idlertable.new({""})
	-- idler 监听触发
	self.showTab = idler.new(1)
	self.showTab:addListener(function(val, oldval, idler)
		self.tabDatas:atproxy(oldval).isSelected = false
		self.tabDatas:atproxy(val).isSelected = true
		self.isShowRight:set(false)
		if val == 2 then
			if self.myFriend:read() and itertools.size(self.myFriend:read()) ~= 0 then
				idlereasy.when(self.myFriend, function (obj, val)
					gGameApp:requestServer("/game/society/friend/search", function (tb)
						firDatas[1] = tb.view.roles
						local tmpSortTabData = {}
						for k, v in pairs(firDatas[1]) do
							table.insert(tmpSortTabData, clone(v).name)
						end
						self.selFirId = firDatas[1][1].id
						self.firDatas:set(tmpSortTabData)
						self.sortDatas:set(tmpSortTabData)
					end, nil, nil, val)
				end):anonyOnly(self)
			end
		end
	end)

	self.topPageBtns = {
		{name = gLanguageCsv.nofication, isSelected = false, canReadNum = 0},
		{name = gLanguageCsv.system, isSelected = false, canReadNum = 0}
	}
	self.topPageBtns = idlers.newWithMap(self.topPageBtns)
	local function stateChange(mailbox, readMailbox)
		--非常诡异的做法的原因就是，我阅读一封邮件，竟然要进入这个方法两次。而我只需要在进入第二次的时候去刷新数据。
		if self.unReadState1 then
			self:initData(mailbox, readMailbox, false)
			self.unReadState1 = false
		else
			self:initData(mailbox, readMailbox, true)
		end
	end

	idlereasy.any({self.mailboxIdler, self.readMailboxIdler}, function (_, mailbox, readMailbox)
		stateChange(mailbox, readMailbox)
		local num1 = itertools.size(mailbox) + itertools.size(readMailbox)
		local num2 = game.MAIL_LIMIT
		self.textNum1:text(num1)
		self.textNum2:text("/" .. num2)
		self.textName:text(gLanguageCsv.mailUpperLimit)
		text.addEffect(self.textNum1, {color = num1 - num2 >= -5 and ui.COLORS.NORMAL.ALERT_ORANGE or ui.COLORS.NORMAL.DEFAULT})
		adapt.oneLinePos(self.textName, {self.textNum1, self.textNum2}, cc.p(2, 0), "left")
	end)
	self.btnGetShow = idler.new(true)
	self.showPage:addListener(function(val, oldval, idler)
		self.topPageBtns:atproxy(oldval).isSelected = false
		self.topPageBtns:atproxy(oldval).isRed = true
		self.topPageBtns:atproxy(val).isSelected = true
		self.topPageBtns:atproxy(val).isRed = false
		self.originCurrPageData = clone(self.datas[val])
		if self.selectedItem and self.pageDatas:at(self.currReadMailId:read()) then
			self.pageDatas:atproxy(self.currReadMailId:read()).isSelected = false
		end

		self.pageDatas:update(self:composeData())
		self.currReadMailId:set(0)
		self.selectedItem = nil
		self.curPage = val
		self.isShowTip:set(self.pageDatas:size() == 0)
	end)
	self.isOpen = false
	self.selFirIdx = idler.new(1)

	self.selFirIdx:addListener(function(val, oldval, idler)
		if self.firDatas:proxy()[val] then
			self.selFirId = self.firDatas:proxy()[val].id
		end
	end)
	self.btnText = idler.new("")
	local btnTexts = {gLanguageCsv.sendFriend, gLanguageCsv.guildMember}
	self.sendType = idler.new(1) -- 1:firend 2:union
	self.sendType:addListener(function(val, oldval, idler)
		if val == 2 then
			gGameUI:showTip(gLanguageCsv.needJoinGuild)
			return
		end
		self.btnText:set(btnTexts[val])
		self.selFirIdx:set(1)
		if firDatas[val] and #firDatas[val] > 0 then
			local tmpSortTabData = {}
			for k, v in pairs(firDatas[val]) do
				table.insert(tmpSortTabData, clone(v).name)
			end
			self.firDatas:set(tmpSortTabData)
			self.sortDatas:set(tmpSortTabData)
		end
	end)
	self.canGetCardNum = idler.new(0)
	self.rightTitle = idler.new("")
	self.textSenderName = idler.new("")
	self.textTime = idler.new("")
	self.textMailContent = idler.new("")
	self.getTextNote:text(gLanguageCsv.getAccessory)
	idlereasy.when(self.btnGetShow, function (obj, state)
		cache.setShader(self.getReward, false, state and "normal" or "hsl_gray")
		self.getTextNote:text(state and gLanguageCsv.getAccessory or gLanguageCsv.received)
		self.getReward:setTouchEnabled(state)
	end)

	local originY = self.timeText:y()

	idlereasy.any({self.isShowTip, self.showPage}, function(_, isShowTip, showPage)
		self.noMailPanel:visible(isShowTip)
		self.getAll:visible(not isShowTip and showPage == 2)
		self.deleteAll:visible(not isShowTip)
	end)

	-- 升级
	self.params = {}
	self.roleLv:addListener(function(curval, oldval)
		if curval == oldval then
			return
		end
		self.params.cb = function ()
			gGameUI:stackUI("common.upgrade_notice", nil, nil, oldval)
		end
	end, true)

	Dialog.onCreate(self)
end

function MailView:composeData()
	local t = {}
	for i,v in ipairs(self.originCurrPageData) do
		t[v.db_id or v.id] = v
		v.index = i
	end
	return t
end

function MailView:onSaveMail(node, event)
	if event.name == "unselected" then

	elseif event.name == "selected" then

	end
end

-- 切换收信页签
function MailView:onListPage(list, index)
	dataEasy.tryCallFunc(self.leftList, "setItemAction", {isAction = true})
	self.showPage:modify(function(val)
		return true, index or val
	end)
	self.isShowRight:set(false)
end

-- 切换写信和收信
function MailView:onChangePage(list, index)
	self.showTab:set(index)
end

function MailView:showRightPage(index, data, tbData)
	self.rightTitle:set(tbData.subject)
	self.textSenderName:set(tbData.sender)
	local t = time.getDate(tbData.time)
	self.textTime:set(table.concat({t.year,t.month,t.day}, "."))
	local rightList = self.rightPanel:get("list")
	local textList
	if itertools.isempty(tbData.attachs) then
		gGameApp:requestServer("/game/role/mail/read", function()
			self.unReadState1 = true
		end, data.db_id or data.id)
		nodetools.invoke(self.rightPanel, {"list", "textOther", "btnGet", "imgLine2"}, "hide")
		textList = self.textLongList
		self.textSortList:visible(false)
		self.textLongList:visible(true)
		self.textTimeNote:y(55)
		self.timeText:y(55)
	else
		nodetools.invoke(self.rightPanel, {"list", "textOther", "btnGet", "imgLine2"}, "show")
		rightList:removeAllChildren()
		local newT = {}
		for k,v in pairs(tbData.attachs) do
			if string.sub(tostring(k), 1, 4) == "type" then
				for key,value in pairs(v) do
					newT[key] = value
				end
			else
				newT[k] = v
			end
		end
		uiEasy.createItemsToList(self, rightList, newT, {scale = 0.8})
		textList = self.textSortList
		self.textSortList:visible(true)
		self.textLongList:visible(false)
		self.textTimeNote:y(200)
		self.timeText:y(200)
	end
	beauty.textScroll({
		list = textList,
		isRich = true,
		strs =  "#C0x5B545B#"..tbData.content,
	})
	adapt.oneLinePos(self.textTimeNote, self.timeText, cc.p(0, 0), "left")
	if tbData.attachs and (tbData.attachs.card or tbData.attachs.cards) then
		self.canGetCardNum:set(tbData.attachs.card and 1 or #tbData.attachs.cards)
	else
		self.canGetCardNum:set(0)
	end
end

function MailView:onItemClick(list, index, data)
	self.unReadState1 = false
	local currId = self.currReadMailId:read()
	if currId and currId ~= 0 and self.pageDatas:atproxy(currId) then
		self.pageDatas:atproxy(currId).isSelected = false
	end
	self.pageDatas:atproxy(data.id or data.db_id).isSelected = true
	self.selectedItem = index
	self.currReadMailId:set(data.db_id or data.id)
	self.btnGetShow:set(not self.pageDatas:atproxy(data.id or data.db_id).isRead)
	local isFind = false
	for i,v in ipairs(self.readMailboxIdler:read()) do
		if self.currReadMailId:read() == (v.id or v.db_id) then
			isFind = v
			break
		end
	end
	if isFind then
		self.isShowRight:set(true)
		self:showRightPage(index, data, isFind)
	else
		gGameApp:requestServer("/game/role/mail/get", function (tb)
			self.isShowRight:set(true)
			self:showRightPage(index, data, tb.view)
		end, data.db_id or data.id)
	end
end

function MailView:onDeleteAllMail(node, event)
	self.firstEnter = true
	self.unReadState1 = false
	idlereasy.do_(function (val)
		if #val > 0 then
			gGameApp:requestServer("/game/role/mail/delete",function (tb)
				self.isShowRight:set(false)
			end)
		end
	end,self.readMailboxIdler)
end

function MailView:onGetAllMail(node, event)
	local haveCanRead = false
	local rewards = {}
	for k, v in self.pageDatas:pairs() do
		local mailInfo = v:proxy()
		if not mailInfo.isRead then --reward{id:num}
			haveCanRead = true
			break
		end
	end
	if haveCanRead then
		gGameApp:requestServer("/game/role/mail/read/all", function (tb)
			self.btnGetShow:set(false)
			self.isOneKey = true
			self:showGainDisplayThenLevel(tb)
		end)
	else
		gGameUI:showTip(gLanguageCsv.noMail)
	end
end

function MailView:onGetReward(node, event)
	local selItemIdx = self.selectedItem
	local isRead = self.pageDatas:atproxy(self.currReadMailId:read()).isRead
	if isRead then
		gGameUI:showTip(gLanguageCsv.noMail)
		return
	end
	if self.canGetCardNum:read() > 0 then
		local canReturn = false
		idlereasy.do_(function (cards, cardCapacity)
			if #cards + self.canGetCardNum:read() > cardCapacity then
				gGameUI:showTip(gLanguageCsv.cardBagHaveBeenFull)
				canReturn = true
			end
		end, self.cardDatas, self.cardCapacity)
		if canReturn then
			return
		end
	end
	self.unReadState1 = true
	self.datas[self.curPage][selItemIdx].isRead = true --涉及切换也签之后的数据赋值所以数据源也需要呗改变
	self.btnGetShow:set(false)
	self.originCurrPageData[selItemIdx].isRead = true
	gGameApp:requestServer("/game/role/mail/read", function (tb)
		self:showGainDisplayThenLevel(tb)
	end, self.currReadMailId:read())
end

function MailView:onSortDatas(list)
	return function(a, b)
		return a.index < b.index
	end
end

function MailView:showGainDisplayThenLevel(data, params)
	if params then
		arraytools.merge_inplace(self.params, params)
	end
	gGameUI:showGainDisplay(data, self.params)
end
function MailView:onAfterBuild()
	uiEasy.setBottomMask(self.leftList, self.maskPanel)
end

function MailView:onBtnDetail()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function MailView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.mailRule)
		end),
		c.noteText(125401, 125402),
	}
	return context
end

function MailView:showMaxMailTip()
	local unlock = dataEasy.isUnlock(gUnlockCsv.mailInfo)
	self.btnDetail:visible(unlock)
	if unlock
		and itertools.size(self.mailboxIdler:read()) + itertools.size(self.readMailboxIdler:read()) >= game.MAIL_LIMIT  then
		local curTime = time.getTime()
		local key = "mailInfoDate"
		local gapTime = gCommonConfigCsv.messageIsFull * 24 * 60 * 60
		local userDefaultData = userDefault.getForeverLocalKey(key, 0, {})
		if (curTime - userDefaultData) > gapTime then
			gGameUI:showTip(gLanguageCsv.messageIsFull)
			userDefault.setForeverLocalKey(key, curTime)
		end
	end
end

return MailView