-- @date 2020-8-31
-- @desc 训练家重聚 好友邀请

local FRIEND_TYPE = {
	MY_FRIEND = 1,
	RECOMMEND_FRIEND = 2,
}

local PANEL_NAME = {
	"friendPanel",
	'recommendPanel',
}

local TITLE_SHOW_TEXT = {
	[1] = gLanguageCsv.friend,
	[2] = gLanguageCsv.invite,
	[3] = gLanguageCsv.recommend
}

-- 为按钮设置倒计时
local function setBtnTime(self, btn, fmt, time)
	local scheduleName = btn:name()..btn:tag()
	self:enableSchedule():unSchedule(scheduleName)
	if time > 30 or time <= 0 then
		cache.setShader(btn, false, "normal")
		btn:get("txt"):text(gLanguageCsv.invite)
		btn:setTouchEnabled(true)
		return
	end
	local t = 0
	self:enableSchedule():schedule(function (dt)
		if t == 0 then
			cache.setShader(btn, false, "hsl_gray")
			btn:setTouchEnabled(false)
		end

		local str = string.format(fmt, math.floor(time - t))

		btn:get("txt"):text(str)
		t = t + dt

		if t > time then 		-- 计时结束
			cache.setShader(btn, false, "normal")
			btn:get("txt"):text(gLanguageCsv.invite)
			self:enableSchedule():unSchedule(scheduleName)
			btn:setTouchEnabled(true)
		end
	end, 1, 0, scheduleName)
end

local function friendDetailOnItemCallBack(list, node, k, v, tag)
	local currTime = time.getTime()
	local childs = node:multiget("name", "level", "power", "txt2")
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
	adapt.oneLinePos(childs.name,{childs.txt2}, cc.p(36,0),"left")
	adapt.oneLinePos(childs.txt2,{childs.level}, cc.p(2,0),"left")
end

local ReunionInviteView = class("ReunionInviteView", Dialog)

ReunionInviteView.RESOURCE_FILENAME = "reunion_invite.json"
ReunionInviteView.RESOURCE_BINDING = {
	["leftPanel.panel"] = "leftPanel",
	["leftPanel.panel.friendPanel"] = "friendPanel",
	["leftPanel.panel.recommendPanel"] = "recommendPanel",
	["item"] = "item",
	["leftPanel.panel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["leftPanel.panel.recommendPanel.btnChange"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		}
	},
	["leftPanel.panel.recommendPanel.list"] = {
		varname = "recommendlists",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showdata2"),
				item = bindHelper.self("item"),
				asyncPreload = 4,
				onItem = function(list, node, k, v)
					friendDetailOnItemCallBack(list, node, k, v)
					local childs = node:multiget("btnAdd")
					childs.btnAdd:tag(100+k)
					if v.inviteTime then
						local countDownTime = time.getTime() - v.inviteTime
						if countDownTime <= 30 and countDownTime > 0 then
							countDownTime = 30 - countDownTime
						end
						setBtnTime(list, childs.btnAdd, "(%s S)", countDownTime)
					end
					bind.touch(list, childs.btnAdd, {methods = {ended = functools.partial(list.inviteFriend, v, childs.btnAdd)}})
				end,
			},
			handlers = {
				inviteFriend = bindHelper.self("onInviteFriendClick"),
			},
		}
	},
	["leftPanel.panel.friendPanel.list"] = {
		varname = "friendsList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showdata1"),
				item = bindHelper.self("item"),
				asyncPreload = 4,
				onItem = function(list, node, k, v)
					friendDetailOnItemCallBack(list, node, k, v)
					local childs = node:multiget("btnAdd")
					childs.btnAdd:tag(200+k)
					if v.inviteTime then
						local countDownTime = time.getTime() - v.inviteTime
						if countDownTime > 0 and countDownTime <= 30 then
							countDownTime = 30 - countDownTime
						end
						setBtnTime(list, childs.btnAdd, "(%s S)", countDownTime)
					end
					bind.touch(list, childs.btnAdd, {methods = {ended = functools.partial(list.inviteFriend, v, childs.btnAdd)}})
				end,
			},
			handlers = {
				inviteFriend = bindHelper.self("onInviteFriendClick"),
			},
		}
	},
	["leftPanel.panel.title1"] = "topTitle1",
	["leftPanel.panel.title2"] = "topTitle2",
	["leftPanel.panel.duckPanel"] = "duckPanel",
	-- ["leftPanel.panel.duckPanel.txt"] = "iconText",
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

					local maxHeight = panel:size().height - 20
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

--1.好友 2.推荐
function ReunionInviteView:onCreate(showType, data)
	self:initModel()
	self.showdata1 = idlers.new()
	self.showdata2 = idlers.new()
	local leftButtonName = {
		{name = gLanguageCsv.reunionFriendBind, enter = false},
		{name = gLanguageCsv.reunionInviteBind,  enter = false}
	}
	leftButtonName[showType].enter = true
	self.btnsAttr = idlers.newWithMap(leftButtonName)
	self.dropAttrTab = idler.new(1)
	self.searchState = idler.new(false)
	self.leftButtonTab = idler.new(showType)
	self.datas = {}

	self.topTitle2:text(TITLE_SHOW_TEXT[3])
	self:composeData(showType, data)
	self.firstEnter = true
	self:changeTab(showType)
	self.leftButtonTab:addListener(function (val, oldval, idler)
		self.btnsAttr:atproxy(oldval).select = false
		self.btnsAttr:atproxy(val).select = true
		if not self.btnsAttr:atproxy(val).enter or val == FRIEND_TYPE.RECOMMEND_FRIEND then
			self:changeTab(val)
			self.btnsAttr:atproxy(val).enter = true
		else
			self:changeTagShow(val)
		end
		self.topTitle1:text(TITLE_SHOW_TEXT[val])
		adapt.oneLinePos(self.topTitle1, self.topTitle2, cc.p(0, 0))
	end)
	Dialog.onCreate(self)
end

function ReunionInviteView:changeTagShow(showType)
	self.friendPanel:visible(showType == FRIEND_TYPE.MY_FRIEND)
	self.recommendPanel:visible(showType == FRIEND_TYPE.RECOMMEND_FRIEND)
	idlereasy.do_(function (showdata1, showdata2)
		local isShowDuck = (showType == FRIEND_TYPE.MY_FRIEND and #showdata1 == 0) or (showType == FRIEND_TYPE.RECOMMEND_FRIEND and #showdata2 == 0)
		if isShowDuck then
			self.duckPanel:visible(isShowDuck)
		else
			self.duckPanel:hide()
		end
	end, self.showdata1, self.showdata2)
end

function ReunionInviteView:composeData(showType, data)
	data = data or self.datas[showType]
	for k, val in pairs(data) do
		if self.reunion:read().invite_time and self.reunion:read().invite_time[val.id] then
			val.inviteTime = self.reunion:read().invite_time[val.id]
		else
			val.inviteTime = nil
		end
	end
	if showType == FRIEND_TYPE.MY_FRIEND then
		self.showdata1:update(data)
	else
		self.showdata2:update(data)
		-- self.resort:set(true, true)
	end
	self.datas[showType] = data
	self:changeTagShow(self.leftButtonTab:read())
end

function ReunionInviteView:initModel()
	self.reunion = gGameModel.role:getIdler("reunion")
end

function ReunionInviteView:changeTab(showType)
	self:sendProtocolCountDown(showType)
end

function ReunionInviteView:sendProtocolCountDown(showType, cb)
	cb = cb or function(typ, data) self:composeData(typ, data) end
	ReunionInviteView.sendProtocol(showType, cb)
end

function ReunionInviteView:onChangeClick()
	self:sendProtocolCountDown(FRIEND_TYPE.RECOMMEND_FRIEND)
end

function ReunionInviteView:onLeftButtonClick(list, index)
	self.leftButtonTab:set(index)
end

function ReunionInviteView.sendProtocol(showType, cb)
	gGameApp:requestServer("/game/yy/reunion/bind/list", function(tb)
		cb(showType, tb.view.roles)
	end, showType)
end

function ReunionInviteView:sortItem(list)
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

-- 好友邀请
function ReunionInviteView:onInviteFriendClick(list, data, btn)
	local role = {
		id = data.id,
		level = data.level,
		logo = data.logo,
		name = data.name,
		vip = data.vip_level,
		frame = data.frame,
	}

	gGameApp:requestServer("/game/yy/reunion/bind/invite", function (tb)
		if tb.view.result then
			setBtnTime(list, btn, "(%s S)", 30)
		end
	end, "recommend", role)
end

return ReunionInviteView

