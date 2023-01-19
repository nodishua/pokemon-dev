-- @date 2020-8-31
-- @desc 训练家重聚 相逢有时绑定界面

-- 未领取 (不可领取)，可领取，已领取
local STATE_TYPE = {
	noReach = 0,
	canReceive = 1,
	received = 2,
}


-- 回归玩家-1，老玩家-2
local STATE_ROLE_TYPE = {
	reunion = 1,
	senior = 2,
}

-- 礼包类型(1重聚礼包;2相逢有时)
local STATE_TYPE_GIFT =
{
	gift = 1,
	reunion = 2,
}

--奖励类型 1-重聚礼包 2-绑定奖励 3-任务奖励 4-积分奖励
local STATE_TYPE_GET =
{
	ReunionGift = 1,
	BindAward = 2,
	TaskAward = 3,
	PointAward = 4,
}

local ReunionBindView = class("ReunionBindView", cc.load("mvc").ViewBase)

ReunionBindView.RESOURCE_FILENAME = "reunion_bind.json"
ReunionBindView.RESOURCE_BINDING = {
	["topPanel.bg.reunion"] = "topPanelReunion",
	["topPanel.bg.reunion.title_0"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(255, 217, 121, 255), size = 3},
			},
		},
	},
	["topPanel.bg.reunion.title"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(162, 60, 17, 255), size = 5},
				shadow = {color = cc.c4b(255, 220, 23, 255), offset = cc.size(0,-3), size = 2}
			},
		},
	},
	["topPanel.bg.senior"] = "topPanelSenior",
	["topPanel.bg.senior.title"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(162, 60, 17, 255), size = 5},
				shadow = {color = cc.c4b(255, 220, 23, 255), offset = cc.size(0,-3), size = 2}
			},
		},
	},
	["topPanel.btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRule")},
		}
	},
	["rightPanel.selfPanel"] = "selfPanel",
	["rightPanel.bindPanel"] = "bindPanel",
	["rightPanel.selfPanel.nameBg"] = "selfNameBg",
	["rightPanel.selfPanel.nameBg.name"] = {
		varname = "selfName",
		binds = {
			event = "effect",
			data = {
				outline = {color = ui.COLORS.NORMAL.WHITE, size = 2},
			},
		},
	},
	["rightPanel.bindPanel.nameBg"] = "bindNameBg",
	["rightPanel.bindPanel.nameBg.name"] = {
		varname = "bindName",
		binds = {
			event = "effect",
			data = {
				outline = {color = ui.COLORS.NORMAL.WHITE, size = 2},
			},
		},
	},
	["rightPanel.selfPanel.headBg"] = "selfHeadBg",
	["rightPanel.bindPanel.headBg"] = "bindHeadBg",
	["rightPanel.list"] = "list",
	["rightPanel.labelList"] = "rightPanelLabelList",
	["rightPanel.invitePanel"] = "invitePanel",
	["rightPanel.invitePanel.worldBtn"] = "worldBtn",
	["rightPanel.invitePanel.recommendBtn"] = {
		varname = "recommendBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRecommendBtnClick")}
		},
	},
	["rightPanel.goPanel"] = {
		varname = "goPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGoTaskClick")}
		},
	},
	["rightPanel.receiveBtn"] = {
		varname = "receiveBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onReceiveClick")}
		},
	},
	["rightPanel.receiveBtn.label"] = "receiveBtnLabel",
}

function ReunionBindView:onCreate(yyID, params)
	self.yyID = yyID
	local cfg = csv.yunying.yyhuodong[yyID]
	self.goPanelClick = params.goPanelClick
	local bindInfo = params.bindInfo

	self:initModel()
	self.role_type = self.reunion:read().role_type

	bind.touch(self, self.worldBtn, {methods = {ended = functools.partial(self.onWorldInvite, self, "worldBtn")}})

	for k, v in csvPairs(csv.yunying.reunion_gift) do
		if v.huodongID == cfg.huodongID and v.type == STATE_TYPE_GIFT.reunion and v.target == self.role_type then
			self.csvID = k
			uiEasy.createItemsToList(self, self.list, v.item)
		end
	end

	self.topPanelReunion:visible(STATE_ROLE_TYPE.reunion == self.role_type)
	self.topPanelSenior:visible(STATE_ROLE_TYPE.senior == self.role_type)

	self:createHead(self.selfPanel:get("headBg"), self.figure)
	self.selfName:text(self.roleName)
	self.selfNameBg:visible(true)
	self.selfPanel:get("noPlayer"):visible(false)

	self.OtherRoleID:addListener(function(val, oldval)
		if val == oldval then return end
		if val ~= "" then
			self:onGetInfo(val, function(tb)
				local info = tb.view
				--刷新下方人物
				self:showBindInfo(info)
			end)
		else
			--为空，头像显示问号，昵称隐藏
			self.bindPanel:get("noPlayer"):visible(true)
			self.bindNameBg:visible(false)
		end
	end)

	idlereasy.any({self.reunion, self.reunionBindRoleId}, function(_, reunion, reunionBindRoleId)
		--回归玩家
		if self.role_type == STATE_ROLE_TYPE.reunion then
			if reunionBindRoleId then
				self:setOtherRoleID(reunionBindRoleId)
				self.receiveBtn:visible(true)
				self.invitePanel:visible(false)
				text.deleteAllEffect(self.receiveBtnLabel)
			else
				self.receiveBtn:visible(false)
				self.invitePanel:visible(true)
				if reunion.world_invite_time then
					local countDownTime = time.getTime() - reunion.world_invite_time
					countDownTime = countDownTime > 0 and countDownTime or 30
					countDownTime = countDownTime < 30 and (30 - countDownTime) or 0
					self:setBtnTime("(%s S)", countDownTime)
				end
			end
			if reunion.gift.bind and reunion.gift.bind[1] == self.csvID and reunion.gift.bind[2] == STATE_TYPE.received then
				self.goPanel:visible(true)
			end
		end
		if not reunion.gift then
			cache.setShader(self.receiveBtn, false, "hsl_gray")
			self.receiveBtnLabel:text(gLanguageCsv.notReach)
			self.receiveBtn:setTouchEnabled(false)
		elseif reunion.gift.bind and reunion.gift.bind[1] == self.csvID and reunion.gift.bind[2] == STATE_TYPE.canReceive then
			cache.setShader(self.receiveBtn, false, "normal")
			self.receiveBtnLabel:text(gLanguageCsv.spaceReceive)
			text.addEffect(self.receiveBtnLabel, {glow = {color = ui.COLORS.GLOW.WHITE}})
			self.receiveBtn:setTouchEnabled(true)
		elseif reunion.gift.bind and reunion.gift.bind[1] == self.csvID and reunion.gift.bind[2] == STATE_TYPE.received then
			cache.setShader(self.receiveBtn, false, "hsl_gray")
			self.receiveBtnLabel:text(gLanguageCsv.received)
			self.receiveBtn:setTouchEnabled(false)
		end
	end)
	-- self.OtherRoleID:set("")
	self.bindPanel:get("noPlayer"):visible(true)
	self.bindNameBg:visible(false)
	self:showBindInfo(bindInfo)
	local reunion = self.reunion:read()
	if self.role_type == STATE_ROLE_TYPE.reunion then
		local showText = gLanguageCsv.reunionBindTextByReunion
		self:createRichText(showText)
		gGameModel.forever_dispatch:getIdlerOrigin("reunionBindPlayer"):set(reunion.info.yyID) -- 设置是否查看过
	else
		self.receiveBtn:visible(true)
 	end
end

function ReunionBindView:showBindInfo(info)
	if not info then return end
	self.bindPanel:get("noPlayer"):visible(false)
	self.bindNameBg:visible(true)
	self.bindName:text(info.name)

	self:createHead(self.bindPanel:get("headBg"), info.figure)
	--老玩家创建描述richText
	if STATE_ROLE_TYPE.senior == self.role_type then
		local showText = string.format(gLanguageCsv.reunionBindTextBySenior,info.name)
		self:createRichText(showText)
	end
	self.bindHeadBg:get("headBtn"):onClick(functools.partial(self.onBindHeadBtnClick, self, info))
end

function ReunionBindView:initModel(bindInfo)
	self.reunion = gGameModel.role:getIdler("reunion")
	self.reunionBindRoleId = gGameModel.reunion_record:getIdler("bind_role_db_id")
	self.figure = gGameModel.role:read("figure")
	self.roleName = gGameModel.role:read("name")
	self.datas = idlers.new()
	self.OtherRoleID = idler.new(bindInfo and bindInfo.id or "")
	self.goPanel:visible(false)
	self.invitePanel:visible(false)
end

function ReunionBindView:createRichText(showText)
	self.rightPanelLabelList:removeAllItems()
	beauty.textScroll({
		list = self.rightPanelLabelList,
		strs = showText,
		isRich = true,
		verticalSpace = 10,
		fontSize = 42,
	})
end

function ReunionBindView:createHead(node, figure)
	local parent = node:get("panel")
	parent:removeAllChildren()
	local cfg = gRoleFigureCsv[figure]
	local x, y = parent:width()/2, 0
	local sp = cc.Sprite:create(cfg.res)
		:anchorPoint(0.5, 0.5)
		:xy(x, y)
		:scale(0.8)
		:addTo(parent, 2, "Icon")
end

function ReunionBindView:setOtherRoleID(roleID)
	self.OtherRoleID:set(roleID)
end

function ReunionBindView:onReceiveClick()
	if self.reunion:read().info.end_time - time.getTime() < 0 then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end
	gGameApp:requestServer("/game/yy/reunion/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
		if self.role_type == STATE_ROLE_TYPE.reunion then
			self.goPanel:visible(true)
		end
	end, self.yyID, self.csvID, STATE_TYPE_GET.BindAward)
end

function ReunionBindView:onGoTaskClick()
	if self.goPanelClick then
		self.goPanelClick:set(1)
	end
end

function ReunionBindView:onGetInfo(roleID, cb)
	gGameApp:requestServer("/game/role_info", function (tb)
		if cb then
			cb(tb)
		end
	end, roleID)
end

-- 规则按钮
function ReunionBindView:onRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function ReunionBindView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.reunionRule)
		end),
		c.noteText(148),
		c.noteText(101001, 101020),
	}
	return context
end

-- 世界邀请
function ReunionBindView:onWorldInvite(btnStr)
	gGameApp:requestServer("/game/yy/reunion/bind/invite", function (tb)
		if tb.view.result then
			self:setBtnTime("(%s S)", 30)
		end
	end, "world")
end

--推荐邀请
function ReunionBindView:onRecommendBtnClick()
	local cb = function(showType, data)
		gGameUI:stackUI("city.activity.reunion.invite", nil, nil, showType, data)
	end
	local inviteView = require("app.views.city.activity.reunion.invite")
	inviteView.sendProtocol(1, cb)
end

--玩家信息
function ReunionBindView:onBindHeadBtnClick(info, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	pos.x = pos.x + 250
	pos.y = pos.y + 400
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, {role = info})
end

-- 为按钮设置倒计时
function ReunionBindView:setBtnTime(fmt, time)
	local t = 0
	local btn = self.worldBtn
	local scheduleName = btn:name()
	self:enableSchedule():unSchedule(scheduleName)
	if time > 30 or time <= 0 then
		cache.setShader(btn, false, "normal")
		btn:get("label"):text(gLanguageCsv.worldInvitation)
		btn:setTouchEnabled(true)
		return
	end
	self:enableSchedule():schedule(function (dt)
		if t == 0 then
			cache.setShader(btn, false, "hsl_gray")
			btn:setTouchEnabled(false)
		end

		local str = string.format(fmt, math.floor(time - t))
		btn:get("label"):text(str)
		t = t + dt

		if t > time then 		-- 计时结束
			cache.setShader(btn, false, "normal")
			btn:get("label"):text(gLanguageCsv.worldInvitation)
			self:enableSchedule():unSchedule(scheduleName)
			btn:setTouchEnabled(true)
		end
	end, 1, 0, scheduleName)
end

return ReunionBindView