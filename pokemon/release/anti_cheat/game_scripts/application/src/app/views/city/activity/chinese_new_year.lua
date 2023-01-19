--# 春节活动
--# 1首先判断是否有红包可以抢(世界入口进入)
--# 2拿数据排序
--# 3点击红包(刷新数据)
--# 4发红包(世界发信息，刷新数据)
--# 5对于点开的红包进行展示
--# 6手动刷新

local STATUS = {
	IDLE = 1, --# 已抢完
	MOVE = 2, --# 世界进入抢红包
}

local ChineseNewYearDialog = class("ChineseNewYearDialog", Dialog)

ChineseNewYearDialog.RESOURCE_FILENAME = "activity_chinese_new_year.json"
ChineseNewYearDialog.RESOURCE_BINDING = {
	["close"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["init"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("initDate")}
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if itertools.size(a.members) == itertools.size(b.members) and itertools.size(a.members) == a.total_count then
						return a.created_time > b.created_time
					elseif itertools.size(a.members) == a.total_count then
						return false
					elseif itertools.size(b.members) == b.total_count then
						return true
					else
						local existPackerA = false
						local existPackerB = false
						if a.members[a.roleId] then
							existPackerA = true
						end
						if b.members[b.roleId] then
							existPackerB = true
						end
						if existPackerA and existPackerB then
							return a.created_time > b.created_time
						elseif existPackerA then
							return false
						elseif existPackerB then
							return true
						else
							if itertools.size(a.members) == itertools.size(b.members) then
								return a.created_time > b.created_time
							else
								return itertools.size(a.members) < itertools.size(b.members)
							end
						end
					end
				end,
				itemSize = 50,
				asyncPreload = 5,
				backupCached = false,
				onItem = function(list, node, k, v)
					node:get("item"):get("anima"):removeAllChildren()
					node:get("item"):get("anima"):alignCenter(node:get("item"):size())
					node:get("item"):get("txt"):text(v.message)
					node:get("item"):get("icon"):get("name"):text(v.role_name)
					if v.game_key then
						node:get("item"):get("icon"):get("name1"):text(string.format(gLanguageCsv.brackets, getServerArea(v.game_key, true)))
					else
						node:get("item"):get("icon"):get("name1"):hide()
						node:get("item"):get("icon"):get("name"):y(60)
					end
					node:get("item"):get("open"):get("text"):text(itertools.size(v.members)..'/'..v.total_count)
					local animaFunc = function(node)
						widget.addAnimation(node:get("item"):get("anima"), "chunjiehongbao/chunjiehongbao.skel", "effect_dailingqu_loop", 5)
							:alignCenter(node:size())
							:scale(2)
					end
					local dataInitFun = function()
						node:get("item"):get("shade"):visible(true)
						node:get("item"):get("get"):visible(true)
						node:get("item"):get("opendown"):visible(false)
						node:get("item"):get("iconBg"):visible(true)
						node:get("item"):get("icon"):get("name"):text(gLanguageCsv.clickinfo)
						node:get("item"):get("icon"):get("name"):y(60)
						node:get("item"):get("icon"):get("name1"):hide()
						node:get("item"):get("open"):texture("activity/chinese_new_year/hb_cs_yl.png")
						node:get("item"):get("open"):get("text"):alignCenter(node:get("item"):get("open"):size())
						node:get("item"):get("bg"):texture("activity/chinese_new_year/hb_bg2yl.png")
					end

					if itertools.size(v.members) == v.total_count then
						dataInitFun()
						node:get("item"):get("get"):get("text"):text(gLanguageCsv.robcomplete)
						node:get("item"):get("get"):get("text"):setTextColor(ui.COLORS.NORMAL.GREEN)
						node:get("item"):get("open"):get("text"):setTextColor(ui.COLORS.NORMAL.WARM_YELLOW)
					elseif v.members[v.roleId] then
						dataInitFun()
					else
						node:get("item"):get("open"):texture("activity/chinese_new_year/hb_cs.png")
						node:get("item"):get("bg"):texture("activity/chinese_new_year/hb_bg1.png")
						node:get("item"):get("open"):get("text"):setTextColor(ui.COLORS.NORMAL.GREEN)
						animaFunc(node)
					end
					bind.touch(list, node:get("item"), {methods = {ended = functools.partial(list.clickCell, k, v)}})--, scaletype = 0
				end,
			},
			handlers = {
				clickCell = bindHelper.self("getPackage"),
			},
		},
	},
	["btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("sendRedPackage")}
		},
	},
	["init.text"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.CLARET, size = 2}}
		}
	},
	["btn.txt"] = "btnName",
	["number1"] = "number1",
	["number2"] = "number2",
	["bg.bg"] = "bg",
	["anima"] = "anima",
	["shade"] = "shade",
	["text1"] = "text1",
	["text2"] = 'text2',
	["time"] = "time",
	["text"] = "text",
}

function ChineseNewYearDialog:initModel()
	self.sendredPacket = gGameModel.daily_record:getIdler("huodong_redPacket_send")
	self.getredPacket = gGameModel.daily_record:getIdler("huodong_redPacket_rob")
	if self.yyCfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.huodongCrossRedPacket then
		self.sendredPacket = gGameModel.daily_record:getIdler("huodong_cross_redPacket_send")
		self.getredPacket = gGameModel.daily_record:getIdler("huodong_cross_redPacket_rob")
	end
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.roleId = gGameModel.role:getIdler("id")
	self.tabDatas = idlers.newWithMap({})
end

--# get获取红包 send发送红包
--# dateTab为ture,str为ture是世界进来
--# dateTab为ture,str为false是主城进来
function ChineseNewYearDialog:onCreate(id, dateTab, str)
	self.id = id
	self.dateTab = dateTab
	self.str = str
	local yyCfg = csv.yunying.yyhuodong[self.id]
	self.yyCfg = yyCfg
	self:initModel()
	self.textPosX = self.text1:x()
	self.numberPosX = self.number1:x()
	self.btnName:text(gLanguageCsv.sendRedPack)
	idlereasy.any({self.sendredPacket, self.getredPacket}, function(_, sendNum, getNum)
		self.getVipNum = gVipCsv[self.vipLevel:read()].huodongRedPacketRob
		self.sendVipNum = gVipCsv[self.vipLevel:read()].huodongRedPacketSend
		local sendnumber = self.sendVipNum - sendNum
		local getnumber = self.getVipNum - getNum
		self.number1:text(sendnumber..'/'..self.sendVipNum)
		self.number2:text(getnumber..'/'..self.getVipNum)
		local sendpacketLen = self.number2:x() - self.number2:width()
		self.text2:x(sendpacketLen)
		self.text1:x(self.textPosX - self.number1:width()/2)
		self.number1:x(self.numberPosX - self.number1:width()/2)
		if self.sendVipNum == sendNum then
			self.number1:setTextColor(ui.COLORS.NORMAL.WARM_YELLOW)
		end
		if self.getVipNum == getNum then
			self.number2:setTextColor(ui.COLORS.NORMAL.WARM_YELLOW)
		end
	end)

	self.animaBg = widget.addAnimation(self.anima, "chunjiehongbao/chunjiehongbao.skel", "effect_loop", 5)
		:alignCenter(self.anima:size())
		:scale(2)

	if dateTab and not str then
		if dateTab[1] then
			self.tabDatas:update(dateTab)
		else
			self.bg:visible(true)
		end
	else
		self:initDate()
	end

	local hour, min = time.getHourAndMin(yyCfg.endTime)
	local endTime = time.getNumTimestamp(yyCfg.endDate,hour,min)
	local function setLabel()
		local remainTime = time.getCutDown(endTime - time.getTime())
		self.time:text(remainTime.str)
		if endTime - (time.getTime()) <= 0 then
			self.time:visible(false)
			self.text:visible(false)
			self:onClose()
			return false
		end
		return true
	end
	self:enableSchedule()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, 2)

	Dialog.onCreate(self)
end

--清除掉从外部传进来的数据从新从服务器拿新数据
function ChineseNewYearDialog:externalDate()
	self.dateTab = nil
	self.shade:visible(false)
	self.anima:get("anima"):removeAllChildren()
	self:initDate()
end

--# 刷新数据
function ChineseNewYearDialog:initDate()
	if self.dateTab and self.dateTab["role_id"] and not self.str then
		self.dateTab = nil
	end
	local interface = "/game/yy/red/packet/list"
	if self.yyCfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.huodongCrossRedPacket then
		interface = "/game/yy/cross/red/packet/list"
	end
	gGameApp:requestServer(interface, function(data)
		if itertools.size(data.view.packets) >= 1 then
			for k,v in pairs(data.view.packets) do
				v.roleId = self.roleId:read()
			end
			self.tabDatas:update(clone(data.view.packets))
		end
		self.bg:visible(itertools.size(data.view.packets) < 1)
		if self.dateTab and self.str then
			--让代码刷新一下
			self.shade:visible(true)
			performWithDelay(self, function()
				self:resultInfo(self.dateTab, STATUS.MOVE)
			end, 0.6)
			return
		end
	end)
end

function ChineseNewYearDialog:resultInfo(param, flag)
	local paramtab = {}
	local dataFinish
	local playFlag = false
	local award
	local dateFunc = function(infoData)
		--# 之所以不用false判断是应为世界过来不用再发协议，正常抢过就不做动画了
		if not flag or (flag and flag ~= 1) then
			self.shade:visible(true)
			widget.addAnimation(self.anima:get("anima"), "chunjiehongbao/chunjiehongbao.skel", "effect", 2)
				:alignCenter(self.anima:size())
				:scale(2)
			playFlag = true
		end
		--# 对运气王处理
		local addDateFunc = function(data)
			local luck = 0
			local lickId
			if itertools.size(data.members) == data.total_count then
				for k,v in csvMapPairs(data.members) do
					if luck < v.val then
						luck = v.val
						lickId = v.id
					end
				end
				for k,v in csvMapPairs(data.members) do
					v.lickId = lickId
				end
			end
			return data
		end

		dataFinish = addDateFunc(infoData)
		paramtab = clone(dataFinish)
		--playFlag为ture是可以抢false只能根据条件进行浏览
		if playFlag then
			for k,v in csvMapPairs(paramtab.members) do
				if self.roleId:read() == v.id then
					award = v.val
				end
			end
			performWithDelay(self, function()
				gGameUI:showGainDisplay({rmb = award}, {raw = false, cb = function()
					gGameUI:stackUI("city.activity.red_packet_info", nil, nil, paramtab, self:createHandler("externalDate"))
				end})
			end, 1.6)
		else
			local packetLength = false
			local vipPacketCount, packetLen, oneself = false, false, false
			if self.getredPacket:read() == self.getVipNum then
				vipPacketCount = true
			end
			if itertools.size(paramtab.members) == paramtab.total_count then
				packetLen = true
				packetLength = true
			end
			if not packetLength then
				for k,v in csvMapPairs(paramtab.members) do
					if self.roleId:read() == v.id then
						oneself = true
					end
				end
			end
			if vipPacketCount then
				gGameUI:showTip(gLanguageCsv.redPacketRoleRobLimit)
			elseif packetLen then
				gGameUI:showTip(gLanguageCsv.redPacketNoRemain)
			elseif oneself then
				gGameUI:showTip(gLanguageCsv.redPacketAlreadyRob)
			end
			if itertools.size(paramtab.members) == paramtab.total_count or oneself then
				gGameUI:stackUI("city.activity.red_packet_info", nil, nil, paramtab)
			end
		end
	end
	--# flag：1从主城进来正常抢如果已经抢过也不做协议切不播放特效直接显示，2世界传过来的数据不就不需要发协议了，
	if flag then
		dateFunc(param)
	else
		local interface = "/game/yy/red/packet/rob"
		if self.yyCfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.huodongCrossRedPacket then
			interface = "/game/yy/cross/red/packet/rob"
		end
		gGameApp:requestServer(interface, function(data)
			dateFunc(data.view.info)
		end, param.idx)
	end
end

--# 打开
function ChineseNewYearDialog:getPackage(list, k, v)
	local data = false
	if self.getredPacket:read() == self.getVipNum then
		data = true
	end
	if itertools.size(v.members) >= 1 then
		for k,v in csvMapPairs(v.members) do
			if self.roleId:read() == v.id then
				data = true
			end
		end
	end
	if itertools.size(v.members) == v.total_count then
		data = true
	end
	if not data then
		self:resultInfo(v)
	else
		self:resultInfo(v, STATUS.IDLE)
	end
end

--# 发送
function ChineseNewYearDialog:sendRedPackage()
	--# 发红包后需要刷新数据并广播消息
	gGameUI:stackUI("city.activity.buy_festival_info", nil, nil, self.id, self:createHandler("initDate"))
end

return ChineseNewYearDialog


