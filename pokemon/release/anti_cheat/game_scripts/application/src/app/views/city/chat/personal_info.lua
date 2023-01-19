local ViewBase = cc.load("mvc").ViewBase
local ChatPersonalInfoView = class("ChatPersonalInfoView", ViewBase)

ChatPersonalInfoView.RESOURCE_FILENAME = "chat_personal_info.json"
ChatPersonalInfoView.RESOURCE_BINDING = {
	["baseNode"] = "baseNode",
	["baseNode.bg"] = "bg",
	["baseNode.iconBg"] = {
		varname = "iconBg",
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = bindHelper.self("logoId"),
				frameId = bindHelper.self("frameId"),
				level = false,
				vip = false,
				onNode = function(node)
					node:y(80)
				end,
			}
		}
	},
	["touchPanel"] = {
		varname = "touchPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		}
	},
	["baseNode.name"] = "nodeName",
	["baseNode.btnDetail"] = {
		varname = "btnDetail",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShowInfo")},
		},
	},
	["baseNode.btnDetail.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		},
	},
	["baseNode.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAddFirend")},
		},
	},
	["baseNode.btnAdd.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		},
	},
	["baseNode.btnBlack"] = {
		varname = "btnBlack",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDefriend")},
		},
	},
	["baseNode.btnBlack.txt"] = {
		varname = "defriend",
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		},
	},
	["baseNode.btnChat"] = {
		varname = "btnChat",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPrivateChat")},
		},
	},
	["baseNode.btnKick"] = {
		varname = "btnKick",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnKick")},
		},
	},
	["baseNode.btnChat.textNote"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}}
		},
	},
	["baseNode.level"] = "level",
	["baseNode.vip"] = "vip",
	["baseNode.txt"] = "txt",
}
-- @params 参数 speical
-- @params.params新加参数带边这在私聊中调用这个通用方法，私聊功能改成删除玩家所有聊天记录
-- @params.state状态，flase代表是从主城进来有聊天记录，true是会有没有聊天记录但是可能打算聊天(一般通过加好友等页签进入该界面)
function ChatPersonalInfoView:onCreate(pos, personData, params)
	params = params or {}
	if params.disableTouch then
		self.touchPanel:setTouchEnabled(false)
	end
	self.params = params.params
	self.state = params.state
	self.cb = params.cb
	self.blackCb = params.blackCb
	if self.params then
		self.btnChat:get("txt"):text(gLanguageCsv.delete)
	end

	self.personData = personData
	self:initModel()
	self.vipLv = personData.role.vip or personData.role.vip_level or 0 	-- 外部没有传入VIP等级默认当VIP0处理,隐藏VIP图标
	self.nodeName:text(personData.role.name)
	self.logoId = personData.role.logo
	-- 线上脏数据 role.frame 不存在存到服务器上了
	self.frameId = personData.role.frame or 1
	self.level:text(personData.role.level)
	if self.vipLv == 0 then
		self.vip:hide()
	else
		self.vip:texture(ui.VIP_ICON[self.vipLv])
		adapt.oneLinePos(self.nodeName, self.vip)
	end

	if params.isKickNum and params.isKickNum ~= 0 and dataEasy.isUnlock(gUnlockCsv.cloneBattleKick) then
		self.places = gGameModel.clone_room:getIdler("places")-- 房间成员信息
		self.voteRound = gGameModel.clone_room:getIdler("vote_round")	-- 投票
		local length = (533 - self.bg:height())/2
		self.bg:height(533)
		self.iconBg:y(self.iconBg:y() + length)
		self.level:y(self.level:y() + length)
		self.nodeName:y(self.nodeName:y() + length)
		self.btnDetail:y(self.btnDetail:y() + length + 20)
		self.btnAdd:y(self.btnAdd:y() + length + 20)
		self.btnBlack:y(self.btnBlack:y() + length + 20)
		self.btnChat:y(self.btnChat:y() + length + 20)
		self.txt:y(self.txt:y() + length)
		self.vip:y(self.vip:y() + length)
		self.btnKick:show()
		self.btnKick:y(self.btnKick:y() + length + 20)
		idlereasy.when(self.places, function(_, places)
			self.isLeader = params.isLeader
			local data = places[params.isKickNum]
			if not data then
				ViewBase.onClose(self)
				return
			end
			self.id = data.id
			self.canKick = false
			self.name = data.name
			local challengeOver = 0
			for k, v in pairs(places) do
				if v.play >= 3 then
					challengeOver = challengeOver + 1
				end
			end
			local times = data.time
			local playTimes = data.play
			if self.isLeader then
				if time.getTime() - times > gCommonConfigCsv.cloneCanKickTime*60 and playTimes <= 0 and challengeOver >= gCommonConfigCsv.cloneCanKickFinishNum then
					self.canKick = true
				end
			else
				if playTimes <= 0 and time.getTime() - times > gCommonConfigCsv.cloneCanKickTime*60 and challengeOver >= gCommonConfigCsv.cloneCanKickFinishNum then
					self.canKick = true
				end
			end
			if self.canKick then
				cache.setShader(self.btnKick, false, "normal")
			else
				cache.setShader(self.btnKick, false, "hsl_gray")
				text.addEffect(self.btnKick:get("txt"), {color = ui.COLORS.GLOW.WHITE})
			end
		end)
	else
		self.btnKick:hide()
	end

	local size = self.baseNode:size()
	local speical = params.speical
	if speical and speical == "rank" then
		local targetSize = params.target:size()
		local upperPosY = pos.y
		-- true为上方，false为下方
		local sureYPos = upperPosY >= (display.height / 2)
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
		local size = self.baseNode:size()
		y = math.max(size.height / 2, y)
		y = math.min(y, display.height - size.height / 2)
		self.baseNode:xy(x, y)
	end
end

function ChatPersonalInfoView:initModel()
	self.myFriend = gGameModel.society:getIdler("friends")
	self.blackList = gGameModel.society:getIdler("black_list")
	self.friendMessage = gGameModel.messages:getIdler('private')
	-- self.places = gGameModel.clone_room:getIdler("places")-- 房间成员信息
	-- self.voteRound = gGameModel.clone_room:getIdler("vote_round")	-- 投票

	self.isBlack = false
	idlereasy.when(self.blackList, function (_, blackList)
		local isBlack = itertools.include(blackList, self.personData.role.id)
		self.defriend:text(isBlack and gLanguageCsv.unBlackList or gLanguageCsv.spaceBlackList)
		self.isBlack = isBlack
	end)
end

function ChatPersonalInfoView:onDefriend(node, event)
	local url = self.isBlack and "/game/society/blacklist/remove" or "/game/society/blacklist/add"
	local tip = self.isBlack and gLanguageCsv.removeBlackListSuccess or gLanguageCsv.addBlackListSuccess
	gGameApp:requestServer(url, function (tb)
		gGameUI:showTip(tip)
		if self.blackCb then
			self.blackCb(self)
		end
	end, self.personData.role.id)
end

function ChatPersonalInfoView:onShowInfo(node, event)
	gGameApp:requestServer("/game/role_info", function (tb)
		gGameUI:stackUI("city.personal.other", nil, nil, tb.view)
	end, self.personData.role.id)
end

function ChatPersonalInfoView:onAddFirend(node, event)
	idlereasy.do_(function (friends)
		local isFriend = itertools.include(friends, self.personData.role.id)
		if isFriend then
			gGameUI:showTip(gLanguageCsv.friendAlready)
		else
			gGameApp:requestServer("/game/society/friend/askfor",function (tb)
				gGameUI:showTip(gLanguageCsv.addFriendWait)
			end, {self.personData.role.id})

		end
	end, self.myFriend)
end

--@ self.params为ture时清除聊天
--@ 先执行回调不然交互以后数据清理监听报错
function ChatPersonalInfoView:onPrivateChat()
	if self.params then
		local id = self.personData.role.id
		local info = false
		for k,v in ipairs(self.friendMessage:read()) do
			if v.args and v.args.id == id then
				info = true
			end
		end
		gGameApp:requestServer("/game/chat/del", function(tb)
			gGameModel.messages:delRoleChatMsg(id)
			local friendMessage = gGameModel.messages:read('private')
			local cb = self.cb
			local state = self.state
			ViewBase.onClose(self)
			if cb then
				if itertools.isempty(friendMessage) then
					cb(false, info)
				elseif state then
					cb(true, info)
				end
			end
		end, id)
	else
		gGameUI:stackUI("city.chat.privataly", nil, nil, self.personData)
	end

end

function ChatPersonalInfoView:onBtnKick()
	-- if self.voteRound:read() ~= "start" or self.isLeader then
		if self.canKick and self.isLeader then
			if self.places:read()[1].play > 0 then
				local strs = string.format("#C0x5b545b#"..gLanguageCsv.cloneBattleKickTip3, self.name)
				gGameUI:showDialog({content = strs, cb = function()
					gGameApp:requestServer("/game/clone/room/kick", nil, self.id)
					gGameUI:showTip(string.format(gLanguageCsv.cloneBattleKickTip4, self.name))
					ViewBase.onClose(self)
				end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
			else
				gGameUI:showTip(gLanguageCsv.cloneBattleKickTip2)
			end
		elseif self.canKick then
			if self.voteRound:read() == "start" then
				gGameUI:showTip(gLanguageCsv.cloneBattleKickVoteTip)
				return
			end
			local selfId = gGameModel.role:read("id")
			for k, v in ipairs(self.places:read()) do
				if v.id == selfId then
					if v.play >= gCommonConfigCsv.cloneCanKickFinishNum then
						gGameApp:requestServer("/game/clone/room/vote", nil, 1)
						ViewBase.onClose(self)
						gGameUI:stackUI("city.adventure.clone_battle.vote", nil, {clickClose = true}, true)
						-- gGameUI:stackUI("city.adventure.clone_battle.vote", nil, {clickClose = true})
					else
						gGameUI:showTip(gLanguageCsv.cloneBattleKickTipThreeTimes)
					end
					break
				end
			end
			-- gGameApp:requestServer("/game/clone/room/vote", nil, 1)
			-- ViewBase.onClose(self)
			-- gGameUI:stackUI("city.adventure.clone_battle.vote", nil, {clickClose = true})
		else
			gGameUI:showTip(gLanguageCsv.cloneBattleKickTip1)
		end
	-- else
	-- 	gGameUI:showTip(gLanguageCsv.cloneBattleKickVoteTip)
	-- end
end

return ChatPersonalInfoView