--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- Message
--

local Messages = class('Messages')

local channels = {'all', 'news','world', 'union', 'team', 'huodong', 'private', 'marquee'}
local MessageChannelType = {
	[game.MESSAGE_TYPE_DEFS.normal] = {'news'},
	[game.MESSAGE_TYPE_DEFS.unionJoinUp] = {'world', function(hasunion)
		if hasunion then
			return nil
		end
		return 'union'
	end},
	[game.MESSAGE_TYPE_DEFS.cloneInvite] = {'team'},
	[game.MESSAGE_TYPE_DEFS.roleUnion] = {'union'},
	[game.MESSAGE_TYPE_DEFS.unionPlay] = {'union'},
	[game.MESSAGE_TYPE_DEFS.breakEgg] = {'news'},
	[game.MESSAGE_TYPE_DEFS.worldChat]= {'world'},
	[game.MESSAGE_TYPE_DEFS.unionChat] = {'union'},
	[game.MESSAGE_TYPE_DEFS.roleChat] = {'private'},
	[game.MESSAGE_TYPE_DEFS.news] = {'news'},
	[game.MESSAGE_TYPE_DEFS.battleShare] = {'world'},
	[game.MESSAGE_TYPE_DEFS.worldCardShare] = {'world'},
	[game.MESSAGE_TYPE_DEFS.unionCardShare] = {'union'},
	[game.MESSAGE_TYPE_DEFS.worldCloneInvite] = {'world'},
	[game.MESSAGE_TYPE_DEFS.unionCloneInvite] = {'union'},
	[game.MESSAGE_TYPE_DEFS.friendCloneInvite] = {'private'},
	[game.MESSAGE_TYPE_DEFS.yyHuoDongRedPacketType] = {'world'},
	[game.MESSAGE_TYPE_DEFS.marqueeType] = {'marquee'},
	[game.MESSAGE_TYPE_DEFS.worldReunionInvite] = {'world'},
	[game.MESSAGE_TYPE_DEFS.recommendReunionInvite] = {'private'},
}

function Messages:ctor(game)
	self.game = game

	-- self.leastID = 0
	-- self.mostID = 0
	-- self.count = 0
	self.msgID = 0
	self._stash = {} -- stash passivity push msg id, is will be clean after sync

	local idlerMap = {}
	for _, channel in ipairs(channels) do
		idlerMap[channel] = idlereasy.new({}, channel)
	end
	self.__idlers = idlers.newWithMap(idlerMap, tostring(self))
end

-- internal usage
function Messages:getRawIdler_(channel)
	if channel == nil then
		return self.__idlers
	end
	local ret = self.__idlers:at(channel)
	assert(ret, "no such idler")
	return ret
end

-- external usage
function Messages:getIdler(channel)
	return idlereasy.assign(self:getRawIdler_(channel))
end

function Messages:read(channel)
	return self:getRawIdler_(channel):read()
end

function Messages:addMessage(tb)
	if self.game.society.__idlers == nil then -- if ClientError raise in GameLogin, it will be nil
		return
	end

	local black_list = self.game.society:getValue_('black_list')
	local blacks = arraytools.hash(black_list)

	local hasunion = self.game.role:getValue_('union_db_id') ~= nil
	local channelMsgs = {all={}}
	local dispatch2channel = function(msg)
		local addAll = (msg.type == game.MESSAGE_TYPE_DEFS.marqueeType)
		for _, channel in ipairs(MessageChannelType[msg.type]) do
			if type(channel) == 'function' then
				channel = channel(hasunion)
			end
			if channel then
				local curMsg = clone(msg)
				curMsg.channel = channel
				if channelMsgs[channel] == nil then
					channelMsgs[channel] = {curMsg}
				else
					table.insert(channelMsgs[channel], curMsg)
				end
				if not addAll then
					table.insert(channelMsgs.all, curMsg)
					addAll = true
				end
			end
		end
	end

	local roleid = self.game.role:getValue_('id')
	local mine = {
		id = roleid,
		name = self.game.role:getValue_('name'),
		logo = self.game.role:getValue_('logo'),
		frame = self.game.role:getValue_('frame'),
		title = self.game.role:getValue_('title_id'),
		level = self.game.role:getValue_('level'),
		vip = self.game.role:getValue_('vip_level'),
	}
	if tb.msgID then -- tb.msgID is nil, mean msgs is server push
		self.msgID = math.max(self.msgID, tb.msgID)
	end
	local push = tb.msgID == nil
	for _, tmsg in ipairs(tb.msgs) do
		local msg = {}
		local inBlack = false
		msg.id, msg.time, msg.msg, msg.type, msg.role, msg.args = unpack(tmsg)
		if not self._stash[msg.id] then
			if msg.role then
				inBlack = blacks[msg.role.id]
				if msg.role.id == roleid then
					msg.isMine = true
					-- 如果是自己，用最新的本地数据
					local vip_hide = self.game.role:getValue_('vip_hide')
					if vip_hide then
						mine.vip = 0
					end
					msg.role = mine
				else
					msg.isMine = false
				end
			end
			if not inBlack then
				dispatch2channel(msg)
			end
			if push then
				self._stash[msg.id] = true
			end
		end
	end
	if not push then
		self._stash = {}
	end

	for _, t in pairs(channelMsgs) do
		table.sort(t, function(a, b)
			return a.time < b.time
		end)
	end

	for channel, msgs in pairs(channelMsgs) do
		local idler = self.__idlers:at(channel)
		idler:modify(function(val)
			for _, msg in ipairs(msgs) do
				table.insert(val, msg)
			end
			-- clean cache
			local limit = channel == 'all' and 5 or 50 -- 单个channel限制50条上限, all 上限5
			for i = 1, #val-limit do
				table.remove(val, 1)
			end
		end, true)
	end
end

function Messages:resetChannel(channel)
	local idler = self.__idlers:at(channel)
	idler:set({})
end

function Messages:delRoleChatMsg(roleID)
	local idler = self.__idlers:at('private')
	local msgs = idler:read()
	local newMsgs = {}
	for _, msg in ipairs(msgs) do
		if msg.role.id == roleID then
		elseif msg.args and msg.args.id == roleID then
		else
			table.insert(newMsgs, msg)
		end
	end
	idler:set(newMsgs, true)
end

return Messages