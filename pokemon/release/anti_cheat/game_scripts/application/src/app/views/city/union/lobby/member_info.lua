-- @date:   2019-06-05
-- @desc:   公会提示弹窗

local UnionMemberInfoView = class("UnionMemberInfoView", cc.load("mvc").ViewBase)

UnionMemberInfoView.RESOURCE_FILENAME = "union_member_info.json"
UnionMemberInfoView.RESOURCE_BINDING = {
	["baseNode.btndetail"] = {
		varname = "btndetail",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtndetail")}
		},
	},
	["baseNode.btndetail.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["baseNode.btnFriend"] = {
		varname = "btnFriend",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnFriend")}
		},
	},
	["baseNode.btnFriend.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["baseNode.btnChat"] = {
		varname = "btnChat",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnChat")}
		},
	},
	["baseNode.btnChat.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["baseNode.btnKickOut"] = {
		varname = "btnKickOut",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnKickOut")}
		},
	},
	["baseNode.btnKickOut.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["baseNode.btnBossChange"] = {
		varname = "btnBossChange",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBossChange")}
		},
	},
	["baseNode.btnBossChange.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["baseNode.btnUpJob"] = {
		varname = "btnUpJob",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnUpJob")}
		},
	},
	["baseNode.btnUpJob.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["baseNode.btnDownJob"] = {
		varname = "btnDownJob",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnDownJob")}
		},
	},
	["baseNode.btnDownJob.textNote"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["baseNode.panelLogo"] = "panelLogo",
	["baseNode.textLevel"] = "textLevel",
	["baseNode.textName"] = "textName",
	["baseNode.iconVip"] = "iconVip",
	["baseNode.bg"] = "bg",
	["baseNode"] = "baseNode",
}
function UnionMemberInfoView:onCreate(params)
	self:initModel()
	self.memberData = params.memberData
	local memberData = params.memberData
	local myJob = params.myJob
	self.viceChairmanNum = params.viceChairmanNum
	self.viceChairmanMax = params.viceChairmanMax
	bind.extend(self, self.panelLogo, {
		event = "extend",
		class = "role_logo",
		props = {
			logoId = memberData.logo,
			frameId = memberData.frame,
			level = false,
			vip = false,
			onNode = function(node)
				node:scale(0.9)
			end,
		}
	})
	self.textLevel:text(memberData.level)
	self.textName:text(memberData.name)
	if memberData.vip > 0 then
		self.iconVip:texture(ui.VIP_ICON[memberData.vip]):show()
		adapt.oneLinePos(self.textName, self.iconVip, cc.p(15, 0))
	else
		self.iconVip:hide()
	end
	self.btnKickOut:visible(myJob < memberData.job)
	self.btnBossChange:visible(myJob == 1)
	self.btnUpJob:visible(myJob == 1 and memberData.job == 3)
	self.btnDownJob:visible(myJob == 1 and memberData.job == 2)
	if myJob == 3 then
		local size = self.bg:size()
		self.bg:size(size.width, size.height - 130)
	end
	local size = self.baseNode:size()
	local pos = params.pos
	local speical = params and params.speical
	if speical and speical == "rank" then
		local target = params.target
		local targetSize = target:size()
		local midLine = display.height / 2
		local upperPosY = pos.y
		-- true为上方，false为下方
		local sureYPos = upperPosY >= midLine
		local y
		if sureYPos then
			y = pos.y - size.height / 2 - targetSize.height / 2
		else
			y = pos.y + size.height / 2 + targetSize.height / 2
		end
		self.baseNode:xy(pos.x - 200, y)
	else
		local x = pos.x + size.width / 2 + 200
		local y = pos.y - size.height / 2
		local size = self.bg:size()
		y = math.max(size.height / 2, y)
		y = math.min(y, display.height - size.height / 2)
		self.baseNode:xy(x, y)
	end
	-- Dialog.onCreate(self, {noBlackLayer = true, clickClose = true})
end

function UnionMemberInfoView:initModel()
	self.myFriend = gGameModel.society:getIdler("friends")
	self.createTime = gGameModel.union:read("created_time")
end
--查看详情
function UnionMemberInfoView:onBtndetail()
	gGameApp:requestServer("/game/role_info", function (tb)
		gGameUI:stackUI("city.personal.other", nil, nil, tb.view)
	end, self.memberData.id)
end
--添加好友
function UnionMemberInfoView:onBtnFriend()
	idlereasy.do_(function (friends)
		local isFriend = false
		if friends and #friends > 0 then
			for i, v in ipairs(friends) do
				if v.id == self.memberData.id then
					isFriend = true
					break
				end
			end
		end
		if isFriend then
			gGameUI:showTip(gLanguageCsv.friendAlready)
		else
			gGameApp:requestServer("/game/society/friend/askfor",function (tb)
				gGameUI:showTip(gLanguageCsv.addFriendWait)
			end, {self.memberData.id})

		end
	end, self.myFriend)
end
--聊天
function UnionMemberInfoView:onBtnChat()
	local memberData = {}
	memberData.role = self.memberData
	gGameUI:stackUI("city.chat.privataly", nil, nil, memberData)
end
--踢出
function UnionMemberInfoView:onBtnKickOut()
	gGameUI:stackUI("city.union.lobby.prompt", nil, nil, {
		content = "#C0x5B545B#" .. string.format(gLanguageCsv.unionKickMember, self.memberData.name),
		requestParams = {self.memberData.id},
		typ = "kick",
		cb = self:createHandler("kickCb")
	})
end
function UnionMemberInfoView:kickCb()
	gGameUI:showTip(gLanguageCsv.pleaseLeave)
	self:onClose()
end
--会长转让
function UnionMemberInfoView:onBtnBossChange()
	local curTime = time.getTime()
	if curTime - self.createTime <= 24 * 3600 then
		gGameUI:showTip(gLanguageCsv.cantChangeBoss)
		return
	end
	local job = self.memberData.job == 2 and gLanguageCsv.viceChairman or gLanguageCsv.normalMember
	gGameUI:stackUI("city.union.lobby.prompt", nil, nil, {
		content = dataEasy.getTextScrollStrs(string.format(gLanguageCsv.unionChangeChairman, self.memberData.name, job)),
		needConsider = true,
		requestParams = {self.memberData.id},
		typ = "swap",
		cb = self:createHandler("bossChangeCb")
	})
end
function UnionMemberInfoView:bossChangeCb()
	gGameUI:showTip(gLanguageCsv.transferred)
	self:onClose()
end
--升职
function UnionMemberInfoView:onBtnUpJob()
	if self.viceChairmanNum >= self.viceChairmanMax then
		gGameUI:showTip(gLanguageCsv.unionViceChairmanMax)
		return
	end
	gGameUI:stackUI("city.union.lobby.prompt", nil, nil, {
		content = string.format(gLanguageCsv.unionPromoteMember, self.memberData.name),
		numTip = string.format(gLanguageCsv.currentNumberVicePresidents, self.viceChairmanNum, self.viceChairmanMax),
		requestParams = {self.memberData.id},
		typ = "promote",
		cb = self:createHandler("upJobCb")
	})
end
function UnionMemberInfoView:upJobCb()
	gGameUI:showTip(gLanguageCsv.promoted)
	self:onClose()
end
--降职
function UnionMemberInfoView:onBtnDownJob()
	gGameUI:stackUI("city.union.lobby.prompt", nil, nil, {
		content = string.format(gLanguageCsv.unionDemoteMember, self.memberData.name),
		requestParams = {self.memberData.id},
		typ = "demote",
		cb = self:createHandler("downJobCb")
	})
end
function UnionMemberInfoView:downJobCb()
		gGameUI:showTip(gLanguageCsv.demoted)
		self:onClose()
end
return UnionMemberInfoView