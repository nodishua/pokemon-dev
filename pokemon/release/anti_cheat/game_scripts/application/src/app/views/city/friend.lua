 -- @date:   2018-09-17
-- @desc:   1.好友界面
-- @desc:   2.关于idler使用的修正

local FRIEND_TYPE = {
	MY_FRIEND = 1,
	APPLY_FRIEND = 2,
	ADD_FRIEND = 3,
	BLACK_LIST = 4,
}
local PANEL_NAME = {
	"friendPanel",
	"applyPanel",
	"addPanel",
	"blackPanel"
}
local ATTR_VAL_TYPE = {
	"battle_fighting_point",
	"last_time",
	"level"
}

local SHOW_TEXT = {
	[1] = gLanguageCsv.whereMyFriend,
	[2] = gLanguageCsv.noOneApply,
	[4] = gLanguageCsv.blackListNull
}

local SHOW_REUNION = {
	UNSHOW = 0,
	SHOW_REUNION = 1,
	SHOW_SENIRO = 2,
}

local function friendDetailOnItemCallBack(list, node, k, v, tag)
	local currTime = time.getTime()
	local childs = node:multiget("name", "level", "state", "power", "txt2")
	childs.name:text(v.name)
	node:get("iconBg"):removeAllChildren()
	local myProps = {
		event = "extend",
		class = "role_logo",
		props = {
			logoId = v.logo,
			frameId = v.frame,
			level = false,
			vip = false,
			onNode = function(node)
				node:z(6)
			end,
		}
	}
	bind.extend(list, node:get("iconBg"), myProps)
	childs.power:text(v.battle_fighting_point)
	childs.level:text(v.level)
	if tag then
		node:get("bg"):visible(v.select ~= true)
		node:get("selected"):visible(v.select == true)
	end
	v.lastOnline = (currTime - v.last_time) / 60
	local t = time.getCutDown(currTime - v.last_time, nil, true)
	-- local binds = {
	-- 	class = "text_atlas",
	-- 	props = {
	-- 		data = v.battle_fighting_point,
	-- 		pathName = "zhanli",
	-- 		onNode = function(node)
	-- 			node:xy(childs.textStatic:size().width + childs.textStatic:x(), childs.textStatic:y())
	-- 				:z(10)
	-- 				:scale(0.8)
	-- 		end,
	-- 	},
	-- }
	-- bind.extend(list, node, binds)
	if v.lastOnline <= 10 then
		childs.state:text(gLanguageCsv.onLine)
			:setTextColor(cc.c4b(0, 170, 56, 255))
	else
		local text = t.head_date_str
		childs.state:text(gLanguageCsv.offLine..text)
			:setTextColor(cc.c4b(154, 151, 149, 255))
	end
	adapt.oneLinePos(childs.name,{childs.txt2}, cc.p(36,0),"left")
	adapt.oneLinePos(childs.txt2,{childs.level}, cc.p(2,0),"left")
end

local ViewBase = cc.load("mvc").ViewBase
local FriendView = class("FriendView", Dialog)

FriendView.RESOURCE_FILENAME = "friend.json"
FriendView.RESOURCE_BINDING = {
	["rightPanel"] = "rightPanel",
	["leftPanel.panel"] = "leftPanel",
	["leftPanel.panel.applyPanel"] = "applyPanel",
	["leftPanel.panel.addPanel"] = "addPanel",
	["leftPanel.panel.friendPanel"] = "friendPanel",
	["leftPanel.panel.blackPanel"] = "blackPanel",
	["rightPanel.figure"] = {
		binds = {
			event = "extend",
			class = "role_figure",
			props = {
				data = bindHelper.self("figureId"),
			},
		}
	},
	["item1"] = "item1",
	["item2"] = "item2",
	["leftPanel.panel.textFriend"] = {
		varname = "textFriend",
		binds = {
			event = "text",
			idler = bindHelper.self("friendsNum"),
			method = function(val)
				return string.format("%s %d/%d", gLanguageCsv.friendLimit, val, game.FRIEND_LIMIT)
			end,
		}
	},
	["leftPanel.panel.friendPanel.getNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("daily_record", "friend_stamina_gain"),
			method = function(val)
				return string.format("%s %d/%d", gLanguageCsv.staminaAlreadyGet, val, game.FRIEND_STAMINA_GET_TIMES)
			end,
		}
	},
	["leftPanel.panel.addPanel.searchPanel.nameInput"] = "nameInput",
	["leftPanel.panel.topPanel"] = {
		varname = "topPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				data = bindHelper.self("sortTabData"),
				width = 245,
				height = 80,
				btnWidth = 270,
				btnHeight = 80,
				btnType = 2,
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				showSelected = bindHelper.self("dropAttrTab"),
				onNode = function(node)
					node:xy(-1150, -522):z(20)
				end,
			},
		}
	},
	["leftPanel.panel.topPanel.btnSort"] = {
		varname = "btnSelectOrder",
		binds = {
			event = "click",
			method = bindHelper.self("onShowOrderClick"),
		}
	},
	["leftPanel.panel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["leftPanel.panel.applyPanel.btnRefuse"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAllRefuseClick")}
		}
	},
	["leftPanel.panel.applyPanel.btnRefuse.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["leftPanel.panel.applyPanel.btnAgree"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAllAcceptClick")}
		}
	},
	["leftPanel.panel.applyPanel.btnAgree.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["leftPanel.panel.addPanel.btnChange"] = {
		varname = "btnChange",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		}
	},
	["leftPanel.panel.addPanel.btnChange.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["leftPanel.panel.addPanel.btnAdd"] = {
		varname = "btnAllApply",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAllApplyClick")}
		}
	},
	["leftPanel.panel.addPanel.btnAdd.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["leftPanel.panel.friendPanel.btnGive"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSendClick")}
		}
	},
	["leftPanel.panel.friendPanel.btnGive.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["leftPanel.panel.friendPanel.btnGet"] = {
		varname = "btnGet",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGetClick")}
		}
	},
	["leftPanel.panel.friendPanel.btnGet.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		}
	},
	["rightPanel.btnDetail"] = {
		varname = "btnDetail",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDetailClick")}
		}
	},
	["rightPanel.btnDetail.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["rightPanel.btnDelete"] = {
		varname = "btnDelete",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDeleteClick")}
		}
	},
	["rightPanel.btnDelete.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["rightPanel.btnChat"] = {
		varname = "btnChat",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChatPrivateClick")}
		}
	},
	["rightPanel.btnChat.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["rightPanel.btnChallege"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChallengeClick")}
		}
	},
	["rightPanel.btnChallege.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["leftPanel.panel.applyPanel.list"] = {
		varname = "applyList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				dataOrderCmpGen = bindHelper.self("sortItem", true),
				data = bindHelper.self("showdata2"),
				item = bindHelper.self("item2"),
				asyncPreload = 5,
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("btnGet", "btnGive", "btnRefuse", "btnAgree", "selected", "reunionPanel")
					itertools.invoke({childs.btnGet, childs.btnGive, childs.selected}, "hide")
					itertools.invoke({childs.btnRefuse, childs.btnAgree}, "show")
					friendDetailOnItemCallBack(list, node, k, v)
					bind.touch(list, childs.btnRefuse, {methods = {ended = functools.partial(list.clickRefuse, k)}})
					bind.touch(list, childs.btnAgree, {methods = {ended = functools.partial(list.clickAccept, k)}})
					node:onClick(functools.partial(list.clickHead, k, v, "apply"))
					childs.reunionPanel:visible(v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW or false)
					if v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW then
						childs.reunionPanel:get("label"):text(gLanguageCsv['reunionType' .. v.reunionType])
					end
				end,
			},
			handlers = {
				clickRefuse = bindHelper.self("onItemApplyRefuseClick"),
				clickAccept = bindHelper.self("onItemApplyAcceptClick"),
				clickHead = bindHelper.self("onHeadClick"),
			},
		}
	},
	["leftPanel.panel.blackPanel.list"] = {
		varname = "blacklists",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				dataOrderCmpGen = bindHelper.self("sortItem", true),
				data = bindHelper.self("showdata4"),
				item = bindHelper.self("item1"),
				asyncPreload = 4,
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("btnAdd", "imgApply", "btnBlack", "reunionPanel")
					childs.btnAdd:hide()
					childs.imgApply:hide()
					childs.btnBlack:show()
					friendDetailOnItemCallBack(list, node, k, v)
					bind.touch(list, childs.btnBlack, {methods = {ended = functools.partial(list.removeBlack, k)}})
					childs.reunionPanel:visible(v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW or false)
					if v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW then
						childs.reunionPanel:get("label"):text(gLanguageCsv['reunionType'..v.reunionType])
					end
				end,
			},
			handlers = {
				removeBlack = bindHelper.self("onRemoveBlackClick"),
			},
		}
	},
	["leftPanel.panel.addPanel.list"] = {
		varname = "addList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showdata3"),
				item = bindHelper.self("item1"),
				asyncPreload = 4,
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("btnAdd", "imgApply", "btnBlack", "reunionPanel")
					childs.btnBlack:hide()
					childs.imgApply:visible(v.alreadyAdd == true)
					childs.btnAdd:visible(v.alreadyAdd ~= true)
					friendDetailOnItemCallBack(list, node, k, v)
					bind.touch(list, childs.btnAdd, {methods = {ended = functools.partial(list.clickAdd, k)}})
					node:onClick(functools.partial(list.clickHead, k, v, ""))
					childs.reunionPanel:visible(v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW or false)
					if v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW then
						childs.reunionPanel:get("label"):text(gLanguageCsv['reunionType'..v.reunionType])
					end
				end,
			},
			handlers = {
				clickAdd = bindHelper.self("onItemAddAddClick"),
				clickHead = bindHelper.self("onHeadClick"),
			},
		}
	},
	["leftPanel.panel.addPanel.searchPanel.btnDelete"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSearchDeleteClick")}
		}
	},

	["leftPanel.panel.friendPanel.list"] = {
		varname = "friendsList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				dataOrderCmpGen = bindHelper.self("sortItem", true),
				data = bindHelper.self("showdata1"),
				item = bindHelper.self("item2"),
				preloadCenter = bindHelper.self("myShowFriend"),
				asyncPreload = 5,
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, v)
					friendDetailOnItemCallBack(list, node, k, v, true)
					local childs = node:multiget("btnGet", "btnGive", "btnRefuse", "btnAgree", "selected", "reunionPanel")
					itertools.invoke({childs.btnRefuse, childs.btnAgree}, "hide")
					itertools.invoke({childs.btnGet, childs.btnGive}, "show")
					bind.touch(list, childs.btnGet, {methods = {ended = functools.partial(list.clickGet, k)}})
					bind.touch(list, childs.btnGive, {methods = {ended = functools.partial(list.clickGive, k)}})
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickFriend, k)}})
					childs.btnGet:visible(v.canGet == true)
					childs.btnGive:visible(v.hasGive ~= true)
					childs.reunionPanel:visible(v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW or false)
					if v.reunionType and v.reunionType ~= SHOW_REUNION.UNSHOW then
						childs.reunionPanel:get("label"):text(gLanguageCsv['reunionType'..v.reunionType])
					end
				end,
			},
			handlers = {
				clickGet = bindHelper.self("onItemFriendGetClick"),
				clickGive = bindHelper.self("onItemFriendGiveClick"),
				clickFriend = bindHelper.self("onItemFriendClick"),
			},
		}
	},
	["leftPanel.panel.addPanel.searchPanel.btnSearch"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSearchClick")}
		}
	},
	["leftPanel.panel.duckPanel"] = "duckPanel",
	["leftPanel.panel.duckPanel.txt"] = "iconText",
	["leftItem"] = "leftItem",
	["leftPanel.panel.leftList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnsAttr"),
				item = bindHelper.self("leftItem"),
				padding = 5,
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					if k < 3 then
						local showProps = {
							class = "red_hint",
							props = {
								state = v.select ~= true,
								specialTag = k == 1 and "friendStaminaRecv" or "friendReqs",
								onNode = function (node)
									node:xy(50, 255)
								end
							}
						}
						bind.extend(list, normal, showProps)
					end
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
						panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					else
						selected:hide()
						panel = normal:show()
						panel:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					end

					local maxHeight = panel:size().height - 40
					adapt.setAutoText(panel:get("txt"),v.name,maxHeight)

					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftButtonClick"),
			},
		}
	}
}

function FriendView:onCleanup()
	self._showType = self.leftButtonTab:read()
	self._myShowFriend = self.myShowFriend:read()
	self._dropAttrTab = self.dropAttrTab:read()
	self._btnSelectAscOrder = self.btnSelectAscOrder:read()
	self._data = self.datas[self._showType]
	ViewBase.onCleanup(self)
end

--1.我的好友 2.好友申请 3.添加好友
function FriendView:onCreate(showType, data)
	showType = self._showType or showType
	self:initModel()
	self.originX = self.leftPanel:x()
	self.nameInput:setPlaceHolderColor(ui.COLORS.DISABLED.WHITE)
	self.nameInput:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	self.figureId = idler.new()
	self.showdata1 = idlers.newWithMap({})
	self.showdata2 = idlers.newWithMap({})
	self.showdata3 = idlers.newWithMap({})
	self.showdata4 = idlers.newWithMap({})

	local leftButtonName = {
		{name = gLanguageCsv.myFriend, enter = false},
		{name = gLanguageCsv.friendApply,  enter = false},
		{name = gLanguageCsv.addFriend, enter = false},
		{name = gLanguageCsv.blackList, enter = false}
	}
	leftButtonName[showType].enter = true
	self.btnsAttr = idlers.newWithMap(leftButtonName)

	self.dropAttrTab = idler.new(self._dropAttrTab or 1)
	self.sortTabData = idlertable.new({
		gLanguageCsv.fighting,
		gLanguageCsv.lastOnline,
		gLanguageCsv.level,
	})

	self.datas = {}
	self.friendsNum = idler.new(itertools.size(self.myFriend:read()))
	self.resort = idler.new(false)


	self.searchState = idler.new(false)

	-- 是否选择升序
	self.btnSelectAscOrder = idler.new(self._btnSelectAscOrder or false)
	idlereasy.when(self.btnSelectAscOrder, function (obj, val)
		local childs = self.btnSelectOrder:multiget("txt", "img")
		childs.txt:text(val and gLanguageCsv.ascendingOrder or gLanguageCsv.descendingOrder)
		if val then
			childs.img:rotate(180)
		else
			childs.img:rotate(0)
		end
	end)
	self.myShowFriend = idler.new(0)
	self.leftButtonTab = idler.new(showType)
	self:composeData(showType, self._data or data)
	self.firstEnter = true
	self:changeTab(showType)
	self.leftButtonTab:addListener(function (val, oldval, idler)
		self.btnsAttr:atproxy(oldval).select = false
		self.btnsAttr:atproxy(val).select = true
		self.myShowFriend:set(0)
		if not self.btnsAttr:atproxy(val).enter then
			self:changeTab(val)
			self.btnsAttr:atproxy(val).enter = true
		else
			self:changeTagShow(val)
			if val ~= FRIEND_TYPE.ADD_FRIEND then
				self.resort:set(true, true)
			end
		end
	end)
	self.myShowFriend:addListener(function(val, oldval, idler)
		if oldval ~= 0 and self.showdata1:atproxy(oldval) then
			self.showdata1:atproxy(oldval).select = false
		end
		if val ~= 0 and self.showdata1:atproxy(val) then
			self.showdata1:atproxy(val).select = true
			local data = self.showdata1:atproxy(val)
			self.figureId:set(data.figure)
			self.rightPanel:show()
			self.leftPanel:x(self.originX - 395)
		else
			self.rightPanel:hide()
			self.leftPanel:x(self.originX)
		end
	end)

	local sortTriggers = idlereasyArgs.new(self, "dropAttrTab", "btnSelectAscOrder")
	idlereasy.any(sortTriggers, function(...)
		self.resort:set(true, true)
	end)
	idlerflow.if_(self.resort):do_(function(vars)
		if self.leftButtonTab:read() == FRIEND_TYPE.MY_FRIEND then
			dataEasy.tryCallFunc(self.friendsList, "filterSortItems", false)

		elseif self.leftButtonTab:read() == FRIEND_TYPE.APPLY_FRIEND then
			dataEasy.tryCallFunc(self.applyList, "filterSortItems", false)

		elseif self.leftButtonTab:read() == FRIEND_TYPE.BLACK_LIST then
			dataEasy.tryCallFunc(self.blacklists, "filterSortItems", false)
		end
		self:onResetRightPanel()
	end, sortTriggers)

	-- 界面恢复
	self.myShowFriend:set(self._myShowFriend or 0)
	Dialog.onCreate(self)
end

function FriendView:changeTagShow(showType)
	self.friendPanel:visible(showType == FRIEND_TYPE.MY_FRIEND)
	self.applyPanel:visible(showType == FRIEND_TYPE.APPLY_FRIEND)
	self.addPanel:visible(showType == FRIEND_TYPE.ADD_FRIEND)
	self.topPanel:visible(showType ~= FRIEND_TYPE.ADD_FRIEND)
	self.blackPanel:visible(showType == FRIEND_TYPE.BLACK_LIST)
	self.textFriend:visible(showType ~= FRIEND_TYPE.BLACK_LIST)
	self.rightPanel:hide()
	self.leftPanel:x(self.originX)
	idlereasy.do_(function (friends, applys, blacklist)
		local isShowDuck = (showType == 1 and #friends == 0) or (showType == 2 and #applys == 0) or (showType == 4 and #blacklist == 0)
		if showType ~= FRIEND_TYPE.ADD_FRIEND and isShowDuck then
			self.duckPanel:visible(isShowDuck)
			self.iconText:text(SHOW_TEXT[showType])
			itertools.invoke({self[PANEL_NAME[showType]],self.textFriend, self.topPanel}, "hide")
		else
			self.duckPanel:hide()
		end
	end, self.myFriend, self.friendApply, self.blackList)
end

function FriendView:getReunionType(roleID)
	local reunionStatue = SHOW_REUNION.UNSHOW
	if self.reunion and self.reunion.role_type == 1 and self.reunion.info and self.reunion.info.end_time - time.getTime() > 0
		and self.reunionBindRoleId and self.reunionBindRoleId == roleID then
		reunionStatue = SHOW_REUNION.SHOW_SENIRO
	elseif self.reunion and self.reunion.role_type == 2 and self.reunion.info and self.reunion.info.end_time - time.getTime() > 0
		and self.reunion.info.role_id == roleID then
		reunionStatue = SHOW_REUNION.SHOW_REUNION
	end
	return reunionStatue
end

function FriendView:composeData(showType, data)
	data = data or self.datas[showType]
	for idx, role in ipairs(data) do
		data[idx].reunionType = self:getReunionType(role.id)
	end
	if showType == FRIEND_TYPE.MY_FRIEND then
		idlereasy.do_(function (staminaGet, sendCount)
			self.showdata1:update(data)
			local getHash = arraytools.hash(staminaGet)
			local sendHash = arraytools.hash(sendCount)
			for idx, role in ipairs(data) do
				self.showdata1:atproxy(idx).canGet = getHash[role.id]
				data[idx].canGet = getHash[role.id]
				self.showdata1:atproxy(idx).hasGive = sendHash[role.id]
				data[idx].hasGive = sendHash[role.id]
			end
			self.datas[FRIEND_TYPE.MY_FRIEND] = data
			self.friendsNum:set(#data)
			self.resort:set(true, true)
		end, self.staminaGet, self.sendCount)
	elseif showType == FRIEND_TYPE.APPLY_FRIEND then
		self.datas[FRIEND_TYPE.APPLY_FRIEND] = data
		self.showdata2:update(data)
		self.resort:set(true, true)
	elseif showType == FRIEND_TYPE.ADD_FRIEND then
		self.datas[FRIEND_TYPE.ADD_FRIEND] = data
		local state = userDefault.getCurrDayKey("friendsAddState", {})
		for i, v in ipairs(data) do
			v.alreadyAdd = state[stringz.bintohex(v.id)] ~= nil and state[stringz.bintohex(v.id)]
		end
		self.showdata3:update(data)
	else
		self.datas[FRIEND_TYPE.BLACK_LIST] = data
		self.showdata4:update(data)
		self.resort:set(true, true)
	end
	self:changeTagShow(self.leftButtonTab:read())
end

function FriendView:initModel()
	self.myFriend = gGameModel.society:getIdler("friends")
	self.friendApply = gGameModel.society:getIdler("friend_reqs")
	self.staminaGet = gGameModel.society:getIdler("stamina_recv")
	self.staminaCount = gGameModel.daily_record:getIdler("friend_stamina_gain")
	self.sendCount = gGameModel.daily_record:getIdler("friend_stamina_send")
	self.id = gGameModel.role:getIdler("id")
	self.stamina = gGameModel.role:getIdler("stamina")
	self.blackList = gGameModel.society:getIdler("black_list")
	self.reunion = gGameModel.role:read("reunion")
	self.reunionBindRoleId = gGameModel.reunion_record:read("bind_role_db_id")
end

function FriendView:changeTab(showType)
	if showType == FRIEND_TYPE.MY_FRIEND then
		idlereasy.when(self.myFriend, function (obj, friends)
			if not self.firstEnter then
				self:sendProtocolCountDown(FRIEND_TYPE.MY_FRIEND, friends)
			end
			self.friendsNum:set(itertools.size(friends))
			self.firstEnter = false
		end):anonyOnly(self)
	elseif showType == FRIEND_TYPE.APPLY_FRIEND then
		idlereasy.when(self.friendApply, function (obj, val)
			if not self.firstEnter then
				self:sendProtocolCountDown(FRIEND_TYPE.APPLY_FRIEND, val)
			end
			self.firstEnter = false
		end):anonyOnly(self)
	elseif showType == FRIEND_TYPE.ADD_FRIEND then
		if not self.btnsAttr:atproxy(showType).enter then
			if not self.firstEnter then
				self:sendProtocolCountDown(FRIEND_TYPE.ADD_FRIEND, val)
			end
			self.btnsAttr:atproxy(showType).enter = true
		end
		self.firstEnter = false
	else
		idlereasy.when(self.blackList, function (obj, val)
			if not self.firstEnter then
				self:sendProtocolCountDown(FRIEND_TYPE.BLACK_LIST, val)
			end
			self.firstEnter = false
		end):anonyOnly(self)
	end

end

function FriendView:sendProtocolCountDown(showType, data, cb)
	cb = cb or function(typ, data) self:composeData(typ, data) end
	FriendView.sendProtocol(showType, data, cb)
end

function FriendView:onAllRefuseClick()
	idlereasy.do_(function (friendApplys)
		if #friendApplys ~= 0 then
			gGameApp:requestServer("/game/society/friend/reject",function (tb)
				self:composeData(FRIEND_TYPE.APPLY_FRIEND, {})
				gGameUI:showTip(gLanguageCsv.refuseFriendApply)
			end, nil, true)
		end
	end,self.friendApply)
end

function FriendView:onAllAcceptClick()
	idlereasy.do_(function (friends, friendApplys)
		if #friends == game.FRIEND_LIMIT then
			gGameUI:showTip(gLanguageCsv.friendMax)
		elseif #friendApplys == 0 then
			gGameUI:showTip(gLanguageCsv.currNoFriendApply)
		else
			gGameApp:requestServer("/game/society/friend/accept", function (tb)
				if tb.view and tb.view.refuseFlag then
					gGameUI:showTip(gLanguageCsv.addSuccessRefuseOther)
				else
					gGameUI:showTip(gLanguageCsv.addFriendSuccessful)
				end
			end, nil, true)
		end
	end,self.myFriend,self.friendApply)
end

function FriendView:onChangeClick()
	gGameApp:requestServer("/game/society/friend/list", function (tb)
		self.searchState:set(false)
		self:composeData(FRIEND_TYPE.ADD_FRIEND, tb.view.roles)
	end)
end

function FriendView:onAllApplyClick()
	idlereasy.do_(function (friends)
		if #friends == game.FRIEND_LIMIT then
			gGameUI:showTip(gLanguageCsv.addFriendLimit)
		else
			local roleIds = {}
			local alreadyFriend = {}
			for i = 1, self.showdata3:size() do
				local proxy = self.showdata3:atproxy(i)
				table.insert(roleIds, proxy.id)
				proxy.alreadyAdd = true
				alreadyFriend[stringz.bintohex(proxy.id)] = true
			end
			gGameApp:requestServer("/game/society/friend/askfor", function (tb)
				userDefault.setCurrDayKey("friendsAddState", alreadyFriend)
				gGameUI:showTip(gLanguageCsv.addFriendWait)
			end, roleIds)
		end
	end, self.myFriend)
end

function FriendView:onSendClick()
	idlereasy.do_(function (friends, sendCount)
		if #friends == #sendCount then
			gGameUI:showTip(gLanguageCsv.noFriendCanGive)
		else
			gGameApp:requestServer("/game/society/friend/stamina/send", function (tb)
				self:composeData(FRIEND_TYPE.MY_FRIEND)
				gGameUI:showTip(gLanguageCsv.staminaSendSucceful)
			end, nil, true)
		end
	end, self.myFriend, self.sendCount)
end

function FriendView:onGetClick()
	idlereasy.do_(function (friends, staminaCount, staminaGet, stamina)
		if #friends == staminaCount or #staminaGet == 0 then
			gGameUI:showTip(gLanguageCsv.noStaminaCanGet)
		elseif staminaCount == game.FRIEND_STAMINA_GET_TIMES then
			gGameUI:showTip(gLanguageCsv.friendStaminaRecvMax)
		elseif stamina < game.STAMINA_LIMIT then
			gGameApp:requestServer("/game/society/friend/stamina/recv", function (tb)
				self:composeData(FRIEND_TYPE.MY_FRIEND)
				gGameUI:showTip(gLanguageCsv.staminaGetSuccessful)
			end, nil, true)
		else
			gGameUI:showTip(gLanguageCsv.staminaToLimit)
		end
	end, self.myFriend, self.staminaCount, self.staminaGet, self.stamina)
end

function FriendView:onDetailClick()
	local role = self.showdata1:atproxy(self.myShowFriend)
	gGameApp:requestServer("/game/role_info", function (tb)
		gGameUI:stackUI("city.personal.other", nil, nil, tb.view)
	end, role.id)
end

function FriendView:onChatPrivateClick()
	local val = self.showdata1:atproxy(self.myShowFriend)
	local data = {
		isMine = false,
		role = {
			level = val.level,
			id = val.id,
			logo = val.logo,
			name = val.name,
			vip = val.vip_level,
			frame = val.frame,
		},
		time = val.last_time,
	}
	gGameUI:stackUI("city.chat.privataly", nil, nil, data)
end

function FriendView:onChallengeClick()
	local val = self.showdata1:atproxy(self.myShowFriend)
	gGameApp:requestServer("/game/society/friend/search", function (tb)
		local friends = tb.view.roles[1]
		if friends and friends.pvp_record_db_id then
			gGameUI:stackUI("city.card.embattle.base", nil, {full = true}, {
				fightCb = self:createHandler("startFighting", friends.pvp_record_db_id)
			})
		else
			gGameUI:showTip(gLanguageCsv.friendCannotFight)
		end
	end, val.id)
end

function FriendView:onResetRightPanel()
	self.myShowFriend:set(0)
end

function FriendView:onDeleteClick()
	local val = self.showdata1:atproxy(self.myShowFriend)
	gGameUI:showDialog{strs = {
		string.format(gLanguageCsv.removeSelectFriend1,val.name),
	}, isRich = true, cb = function ()
			gGameApp:requestServer("/game/society/friend/delete", function (tb)
				self:onResetRightPanel()
			end, val.id)
		end,
	btnType = 2}
end

function FriendView:onItemApplyRefuseClick(list, index, noTip)
	gGameApp:requestServer("/game/society/friend/reject", function (tb)
		table.remove(self.datas[FRIEND_TYPE.APPLY_FRIEND], index)
		if noTip ~= true then
			gGameUI:showTip(gLanguageCsv.refuseFriendApply)
		end
	end, self.showdata2:atproxy(index).id, false)
end

function FriendView:onItemApplyAcceptClick(list, index)
	idlereasy.do_(function (friends)
		if #friends == game.FRIEND_LIMIT then
			gGameUI:showTip(gLanguageCsv.friendMax)
		else
			gGameApp:requestServer("/game/society/friend/accept", function (tb)
				table.remove(self.datas[FRIEND_TYPE.APPLY_FRIEND], index)
				gGameUI:showTip(gLanguageCsv.addFriendSuccessful)
			end, self.showdata2:atproxy(index).id, false)
		end
	end, self.myFriend)
end

function FriendView:onItemAddAddClick(list, index)
	local id = self.showdata3:atproxy(index).id
	idlereasy.do_(function (friends)
		if #friends == game.FRIEND_LIMIT then
			gGameUI:showTip(gLanguageCsv.addFriendLimit)
		else
			gGameApp:requestServer("/game/society/friend/askfor", function (tb)
				userDefault.setCurrDayKey("friendsAddState", {[stringz.bintohex(id)] = true})
				self.showdata3:atproxy(index).alreadyAdd = true
				gGameUI:showTip(gLanguageCsv.addFriendWait)
			end, {id})
		end
	end, self.myFriend)
end

function FriendView:onItemFriendGetClick(list, index)
	local val = self.showdata1:atproxy(index)
	idlereasy.do_(function (staminaCount, stamina)
		if game.FRIEND_STAMINA_GET_TIMES == staminaCount then
			gGameUI:showTip(gLanguageCsv.friendStaminaRecvMax)
		elseif stamina < game.STAMINA_LIMIT then
			gGameApp:requestServer("/game/society/friend/stamina/recv", function (tb)
				gGameUI:showTip(gLanguageCsv.staminaGetSuccessful)
				self.datas[FRIEND_TYPE.MY_FRIEND][index].canGet = false
				val.canGet = false
			end, val.id)
		else
			gGameUI:showTip(gLanguageCsv.staminaToLimit)
		end
	end, self.staminaCount, self.stamina)
end

function FriendView:onRemoveBlackClick(list, index)
	gGameUI:showDialog({title = "",content = string.format(gLanguageCsv.removeSelectBlackListSuccess, self.showdata4:atproxy(index).name),isRich = true, cb = function()
		gGameApp:requestServer("/game/society/blacklist/remove", function (tb)
			gGameUI:showTip(gLanguageCsv.removeBlackListSuccess)
		end, self.showdata4:atproxy(index).id)
	end, btnType = 2})
end

function FriendView:onItemFriendGiveClick(list, index)
	local val = self.showdata1:atproxy(index)
	gGameApp:requestServer("/game/society/friend/stamina/send", function (tb)
		gGameUI:showTip(gLanguageCsv.staminaSendSucceful)
		self.datas[FRIEND_TYPE.MY_FRIEND][index].hasGive = true
		val.hasGive = true
	end, val.id)
end

function FriendView:onItemFriendClick(list, index)
	self.myShowFriend:set(index)
end

function FriendView:onShowOrderClick()
	self.btnSelectAscOrder:modify(function(val)
		return true, not val
	end)
end

function FriendView:onSearchClick()
	local name = self.nameInput:getStringValue()
	if name == nil or name == "" then
		gGameUI:showTip(gLanguageCsv.needNameOrUID)
	else
		gGameApp:requestServer("/game/society/friend/search", function (tb)
			self.searchState:set(true)
			local roles = table.deepcopy(tb.view.roles, true)
			for idx, role in ipairs(roles) do
				roles[idx].reunionType = self:getReunionType(role.id)
			end
			self.showdata3:update(roles)
		end, nil, tostring(name), nil, tonumber(name))
	end
end

function FriendView:onLeftButtonClick(list, index)
	self.leftButtonTab:set(index)
end

function FriendView:onSearchDeleteClick()
	self.showdata3:update(self.datas[3])
	self.nameInput:text("")
end

function FriendView.initFriendShowType()
	local myFriend = gGameModel.society:read("friends")
	local staminaGet = gGameModel.society:read("stamina_recv")
	local staminaCount = gGameModel.daily_record:read("friend_stamina_gain")
	local friendApply = gGameModel.society:read("friend_reqs")
	if itertools.size(staminaGet) > 0 and staminaCount < game.FRIEND_STAMINA_GET_TIMES then
		return FRIEND_TYPE.MY_FRIEND, myFriend
	end

	local friendApply = gGameModel.society:read("friend_reqs")
	local friendApplyCount = itertools.size(friendApply)
	local myFriendCount = itertools.size(myFriend)
	if myFriendCount < 10 and friendApplyCount > 0 then
		return FRIEND_TYPE.APPLY_FRIEND, friendApply

	elseif myFriendCount < 20 and friendApplyCount == 0 then
		return FRIEND_TYPE.ADD_FRIEND

	elseif myFriendCount > 40 then
		return FRIEND_TYPE.MY_FRIEND, myFriend
	else
		return FRIEND_TYPE.MY_FRIEND, myFriend
	end
end

function FriendView.sendProtocol(showType, data, cb)
	if showType ~= FRIEND_TYPE.ADD_FRIEND then
		if data and itertools.size(data) > 0 then
			return gGameApp:requestServer("/game/society/friend/search", function(tb)
				cb(showType, tb.view.roles)
			end, nil, nil, data)
		else
			cb(showType, {})
		end
	else
		return gGameApp:requestServer("/game/society/friend/list", function(tb)
			cb(showType, tb.view.roles)
		end)
	end
end

function FriendView:onSortMenusBtnClick(panel, node, k, v)
	self.dropAttrTab:set(k)
end

function FriendView:sortItem(list)
	local attrTab = self.dropAttrTab:read()
	local ascOrder = self.btnSelectAscOrder:read()
	return function(dataA, dataB)
		local attributeA = dataA[ATTR_VAL_TYPE[attrTab]]
		local attributeB = dataB[ATTR_VAL_TYPE[attrTab]]
		if attributeA ~= attributeB then
			if ascOrder then
				return attributeA < attributeB
			else
				return attributeA > attributeB
			end
		end
	end
end

function FriendView:onHeadClick(list, k, v, flag, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	gGameUI:stackUI("city.chat.personal_info", nil,
		{
			clickClose = true,
			dispatchNodes = list:parent(),
		},
		pos,
		{role = v},
		{
			speical = "rank",
			target = list.item:get("bg"),
			disableTouch = true,
			blackCb = function(view)
				if flag == "apply" then
					view:onClose()
					self:onItemApplyRefuseClick(nil, k, true)
				end
			end,
		}
	)
end

--battleCards 当前阵容
function FriendView:startFighting(recordId, view)
	-- -- 2.正常的开始战斗 跳过布阵
	battleEntrance.battleRequest("/game/society/friend/fight", gGameModel.role:getIdler("id"), recordId)
		:onStartOK(function(data)
			if view then
				view:onClose(false)
				view = nil
			end
		end)
		:show()
end

return FriendView

