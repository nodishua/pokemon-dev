--
-- @desc 跑马灯通用项
--
local helper = require "easy.bind.helper"
local marquee = class("marquee", cc.load("mvc").ViewBase)

-- 目前跑马灯固定大小，后续需要适应不同界面不同大小，可在参数里拓展
marquee.defaultProps = {

}

-- 已播放消息列表
local marqueeMessagesAlready = {}
-- 重组优先度table 根据key可直接获取
local SORT = {}
-- 重组有效时长 根据key可直接获取
local WAITTIME = {}
for k,v in csvPairs(csv.marquee) do
	SORT[v.key] = v.sortValue
	WAITTIME[v.key] = v.waitTime
end

function marquee:initExtend()
	self:initMode()

	-- 清除所有子节点
	self:removeAllChildren()

	-- 背景
	local bg = ccui.ImageView:create("city/marquee/bg_1.png")
		:alignCenter(self:size())
		:addTo(self, 1, "bg")

	-- 喇叭
	local voice = ccui.ImageView:create("city/marquee/icon_lb.png")
		:anchorPoint(0, 0.5)
		:xy((self:width() - bg:width())/2 + 40, self:height()/2)
		:addTo(self, 2, "voice")

	-- list
	local list = ccui.ListView:create()
		:size(1100, 50)
		:anchorPoint(0, 0.5)
		:xy((self:width() - bg:width())/2 + 110, self:height()/2)
		:addTo(self, 3, "list")
	list:setScrollBarEnabled(false)
	list:setOpacity(0)

	-- item
	local item = ccui.Layout:create()
		:size(list:size())
		:anchorPoint(0, 1)
		:addTo(list, 1)
	self.item = item

	-- 跑马灯是否在播放中
	self.isPlay = false

	-- 监听跑马灯消息
	helper.callOrWhen(self.marquee, function(data)
		-- 当前消息列表
		self.marqueeMessages = {}
		-- 当前跑马灯信息序号
		self.index = 0

		-- 每次跑马灯信息变化后，需要对跑马灯信息进行更新
		-- 第一步 排序
		table.sort(data, function (a, b)
			-- 优先度排序
			if SORT[a.args.key] ~= SORT[b.args.key] then
				return SORT[a.args.key] > SORT[b.args.key]
			end
			-- 时间排序
			if a.time == b.time then
				return false
			end
			return a.time > b.time
		end)

		-- 第二步 筛选，剔除已经播过的、正在播放的、时间过期的，最多保存gCommonConfigCsv.marqueeMax数量条
		for id,msg in ipairs(data) do
			-- 检查是否已经播过
			local isAlreadyPlay = false
			for k,v in ipairs(marqueeMessagesAlready) do
				if v.id == msg.id then
					isAlreadyPlay = true
				end
			end

			-- 检查当前信息是否正在播放，播放中不加入播放列表（因为正在播放的信息暂未加入已播放列表）
			local isPlay = self.curMessage and msg.id == self.curMessage.id or false

			-- 检查是否超出最大数量，未超出加入播放列表，超出加入已播放列表
			if not isAlreadyPlay and not isPlay then
				-- 检查是否在有效期内
				local isInTime =  (time.getTime() - msg.time) < WAITTIME[msg.args.key]*60
				if itertools.size(self.marqueeMessages) <= gCommonConfigCsv.marqueeMax and isInTime then
					table.insert(self.marqueeMessages, msg)
				else
					table.insert(marqueeMessagesAlready, msg)
				end
			end
		end

		-- 播放跑马灯，需要判断跑马灯是否在播放中，不在,直接播放，在,刷新播放列表(上面已刷新，不需要操作)
		if not self.isPlay then
			self:play()
		end
	end)

	return self
end

function marquee:initMode()
	self.marquee =  gGameModel.messages:getIdler("marquee")
end

-- @desc 播放跑马灯
function marquee:play()
	-- 获取将要播放的跑马灯信息
	local curMessage = self:getNextMessage()
	-- 如果存在，进入跑马灯播放流程，如果不存在，当前无跑马灯信息或跑马灯信息已播放完，隐藏跑马灯
	if curMessage then
		-- 检测该消息是否已播放/处于有效期，过期跳过播放
		local isInTime =  (time.getTime() - curMessage.time) < WAITTIME[curMessage.args.key]*60
		if isInTime then
			-- 显示跑马灯
			self:show()

			-- 创建跑马灯信息
			self.item:removeAllChildren()
			local richText = rich.createByStr(curMessage.msg, 40)
			richText:anchorPoint(0, 0)
				:xy(1100, 0)
				:addTo(self.item, 999)
			richText:formatText()

			-- 保存当前播放跑马灯信息
			self.curMessage = curMessage

			-- 滚动跑马灯信息
			self.isPlay = true
			local v = 160
			local pos1 = math.min(self.item:width() - richText:width(), 0)
			local pos2 = -richText:width()
			local t1 = (richText:x() - pos1)/v
			local t2 = 3
			local t3 = (pos1-pos2)/v
			transition.executeSequence(richText, true)
				:moveTo(t1, pos1)
				:delay(t2)
				:moveTo(t3, pos2)
				:func(function ()
					-- 当前跑马灯播放结束
					self:addToAlready(curMessage)
					self.curMessage = nil
					self:play()
				end)
				:done()
		else
			self:addToAlready(curMessage)
			self:play()
		end
	else
		self.isPlay = false
		self:hide()
	end
end

-- @desc 获取将要播放的跑马灯信息
function marquee:getNextMessage()
	self.index = self.index + 1
	local curMessage = self.marqueeMessages[self.index]
	if curMessage then
		return curMessage
	end

	return false
end

-- @desc 将已播放完成的跑马灯信息加入到已播放列表
function marquee:addToAlready(msg)
	local isExist = false
	for k,v in pairs(marqueeMessagesAlready) do
		if v.id == msg.id then
			isExist = true
		end
	end

	if not isExist then
		table.insert(marqueeMessagesAlready, msg)
	end
end

return marquee