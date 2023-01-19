-- @date:   2018-09-25
-- @desc:   签到界面初步展示
-- @desc:   签到界面虚拟数据修正

local MONTH_GIFT_DAY = {7, 15, 28}
local BOX_STATE = {
	OPENED = 0,
	CAN_OPEN = 1,
	NOT_OPEN = 2,
}
local VIP_STATE = {
	NOT_GET = 0,
	CAN_GET = 1,
	GET = 2,
}

local LINE_NUM = 5

local function vipStateChange(csvID, isDouble, vipLevel)
	local vipDouble = csv.signin[csvID].vipDouble
	vipDouble = vipDouble ~= 9999 and vipDouble
	if isDouble == 1 and vipDouble then
		if vipLevel >= vipDouble then
			return VIP_STATE.CAN_GET
		else
			return VIP_STATE.NOT_GET
		end
	else
		return VIP_STATE.GET
	end
end

local SignInView = class("SignInView", Dialog)
SignInView.RESOURCE_FILENAME = "sign_in.json"
SignInView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["leftPanel.btnGet"] = {
		varname = "btnGet",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onGetClick")}
		}
	},
	["leftPanel.btnGet.txt"] = {
		varname = "btnGetTxt",
		binds = {
			{
				event = "effect",
				data = {glow={color=ui.COLORS.GLOW.WHITE}}
			},
		}
	},
	["rightPanel.btnDetail"] = {
		varname = "btnDetail",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDetailClick")}
		}
	},
	["rightPanel.btnAgain"] = {
		varname = "btnRetroactive",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRetroactiveClick")}
		}
	},
	["rightPanel.btnAgain.txt"] = {
		binds = {
			{
				event = "effect",
				data = {glow={color=ui.COLORS.GLOW.WHITE}}
			},
		}
	},
	["itemBig"] = "itemBig",
	["itemSmall"] = "itemSmall",
	["leftPanel.list"] = {
		varname = "tabList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				margin = 11,
				data = bindHelper.self("sumDatas"),
				item = bindHelper.self("itemBig"),
				onItem = function(list, node, k, v)
					local size = node:size()
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
							},
							onNode = function(node)
								node:xy(size.width/2, size.height/2)
							end,
						},
					})
					node:removeChildByName("signSpine")		-- 签到累积奖励可领取特效
					if v.state then
						local signSpine = widget.addAnimationByKey(node, "effect/wupinguang.skel", 'signSpine', "effect_loop", 99)
							:anchorPoint(cc.p(0.5,0.5))
							:xy(node:width()/2, node:height()/2)
					end
				end,
			},
		},
	},
	["itemBox"] = "itemBox",
	["centerPanel.bottomPanel.list"] = {
		varname = "boxList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("boxData"),
				item = bindHelper.self("itemBox"),
				onItem = function(list, node, k, v)
					local textName = node:get("num")
					textName:text(v.num)
					local btn = node:get("icon")
					local boxOpen = v.state == BOX_STATE.OPENED
					local boxCanOpen = v.state == BOX_STATE.CAN_OPEN
					node:get("bg"):texture(v.state ~= BOX_STATE.NOT_OPEN and "city/task/bg_huoyuedu1.png" or "city/task/bg_huoyuedu2.png")
					if boxOpen then
						btn:x(v.x - 12)
					end
					btn:texture("common/icon/icon_signin_box"..k..((boxOpen) and "_open.png" or ".png"))

					if boxCanOpen then
						local effect = widget.addAnimation(node, "effect/jiedianjiangli.skel", "effect_loop", btn:z() - 1)
						local size = btn:size()
						effect:scale(0.3)
							:x(btn:x() - size.width / 2 + 35)
							:y(btn:y() - 16)
						node.effectBox = effect
					elseif not boxCanOpen then
						if node.effectBox then
							node.effectBox:hide()
							node.effectBox:removeFromParent()
							node.effectBox = nil
						end
					end
					uiEasy.addVibrateToNode(list, btn, boxCanOpen, node:getName()..k.."vibrate")
					bind.touch(list, btn, {methods = {ended = functools.partial(list.clickBox, k, btn)}})
				end,
			},
			handlers = {
				clickBox = bindHelper.self("onBoxClick"),
			},
		},
	},
	["centerPanel.subList"] = "subList",
	["centerPanel.list"] = {
		varname = "listCenter",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("showdata"),
				columnSize = LINE_NUM,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("itemSmall"),
				preloadCenter = 5,
				currDay = bindHelper.self("currDay"),
				numDay = bindHelper.self("numDay"),
				itemAction = bindHelper.self("itemAction"),
				onCell = function(list, node, k, v)
					local t = list:getIdx(k)
					local vipDouble = csv.signin[t.k].vipDouble ~= 9999 and csv.signin[t.k].vipDouble
					local size = node:size()
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.id,
								num = v.num,
							},
							onNode = function(node)
								node:xy(size.width/2, size.height/2 + 25)
								bind.click(list, node, {method = functools.partial(list.itemClick, node, t, v)})
							end,
						},
					}
					bind.extend(list, node, binds)
					node:get("mask"):visible(v.signIn == true):z(10)
					node:get("vipPanel")
						:visible(vipDouble ~= false)
						:z(11)
					node:get("day"):text(string.format(gLanguageCsv.currDay, t.k))
					text.addEffect(node:get("day"), {outline = {color = ui.COLORS.OUTLINE.WHITE, size = 3}})
					local btnDouble = node:get("doublePanel"):z(11)
					if v.vipState and v.vipState ~= VIP_STATE.GET then
						node:get("mask", "check"):hide()
						btnDouble:visible(true)
					else
						node:get("mask", "check"):show()
						btnDouble:visible(false)
					end
					node:get("vipPanel","vip")
						:text(string.format(gLanguageCsv.vipDouble,vipDouble or 0))
					text.addEffect(node:get("vipPanel","vip"), {color = ui.COLORS.NORMAL.WHITE,shadow = {color = cc.c4b(193,38,44, 181), offset = cc.size(0,-2), size = 6}})
					bind.click(list, btnDouble, {method = functools.partial(list.vipDoubleClick, t, v)})
					node:removeChildByName("signSpine") 	-- 签到单个奖励特效
					if v.effect and not v.signIn then
						local signSpine = widget.addAnimationByKey(node, "effect/wupinguang.skel", 'signSpine', "effect_loop", 99)
							:anchorPoint(cc.p(0.5,0.5))
							:xy(node:width()/2, node:height()/2+25)
					end
				end,
				onAfterBuild = function (list)
					local currDay = list.currDay:read()
					local day
					if currDay ~= tonumber(time.getDate(time.getTime()).day) then
						day = list.numDay:read() + 1
					else
						day = list.numDay:read()
					end
					local totalLine = math.ceil(#list.data / LINE_NUM)
					local currLine = math.ceil(day / LINE_NUM)
					if currLine >= 2  then
						list:jumpToItem(currLine - 2, cc.p(0, 1), cc.p(0, 1))
					end

				end
				-- asyncPreload = 1,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
				vipDoubleClick = bindHelper.self("vipDoubleClick"),
			},
		},
	},
	["centerPanel.bottomPanel.bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("barPoint"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		}
	},
	["leftPanel.txtNum"] = "sumNum",
	["leftPanel.img"] = "img",
	["centerPanel.bottomPanel.txtNum"] = {
		binds = {
			{
				event = "text",
				idler = bindHelper.self("numDay"),
				method = function(val)
					return string.format(gLanguageCsv.day, val)
				end,
			}
		}
	},
	["rightPanel.freePanel"] = {
		varname = "freePanel",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("showFreePanel"),
			}
		}
	},
	["rightPanel.costPanel"] = {
		varname = "diamondPanel",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("showDiamondPanel"),
			}
		}
	},
	["rightPanel.freePanel.num"] = {
		binds = {
			{
				event = "text",
				idler = bindHelper.self("freeRetroactiveNum"),
			},
			{
				event = "effect",
				data = {color=ui.COLORS.NORMAL.DEFAULT},
			},
		},
	},
	["rightPanel.freePanel.txt"] = {
		binds = {
			event = "effect",
			data = {color=ui.COLORS.NORMAL.DEFAULT},
		},
	},
	["rightPanel.img"] = "imgRight",
}

-- auto 自动签到
function SignInView:onCreate(auto)
	self:initModel()
	local originX = self.itemBox:get("icon"):x()
	self.sumDatas = idlertable.new({})
	self.btnGetShow = idler.new(false)
	self.showFreePanel = idler.new(false)
	self.showDiamondPanel = idler.new(false)
	self.freeRetroactiveNum = idler.new(0)
	idlereasy.when(self.btnGetShow,function (obj,state)
		cache.setShader(self.btnGet, false, state and "normal" or "hsl_gray")
		if not state then
			text.deleteAllEffect(self.btnGetTxt)
			text.addEffect(self.btnGetTxt, {color = ui.COLORS.DISABLED.WHITE})
		else
			text.addEffect(self.btnGetTxt, {color = ui.COLORS.NORMAL.WHITE, glow={color=ui.COLORS.GLOW.WHITE}})
		end
		self.btnGet:setTouchEnabled(state)
	end)
	idlereasy.any({self.totalCount, self.totalCountGift},function (obj, val, giftVal)
		self.sumNum:text(val.."/"..csv.sighingift[giftVal[1]].day)
		self.img:width(self.sumNum:width()+20)
		self.btnGetShow:set(giftVal[2] == 1)
		local reward = {}
		for i,v in csvMapPairs(csv.sighingift[giftVal[1]].reward) do
			table.insert(reward,{id = i, num = v, state = false})
		end
		if giftVal[2] == 1 then 				-- 可领取时，添加可领取特效
			for i,v in ipairs(reward) do
				v.state = true
			end
		end
		self.sumDatas:set(reward)
	end)
	local year, month = time.getYearMonthDay(self.monthData:read(), true)
	local curDate = {}
	curDate.year = year
	curDate.month = month == 12 and 1 or month + 1
	curDate.day = 0
	local maxDay = os.date("%d", os.time(curDate))

	local data1 = {}
	for i = 1, maxDay do
		local row, col = mathEasy.getRowCol(i, LINE_NUM)
		local id, num = csvNext(csv.signin[i]["month"..month])
		data1[i] = {id = id, num = num, effect = false}
		local months = csv.signin[i].months 	-- 添加单个奖励特效判断
		for m,n in ipairs(months) do
			if n == m then
				data1[i].effect = true
			end
		end
	end
	-- -- self.showdata = idlertable.new(data1) -- 整体刷新
	self.showdata = idlers.newWithMap(data1) -- 单个刷新
	self.boxData = idlertable.new({})
	self.tagOrId, self.countOrId = csvNext(csv.signin[1000]["month"..month])
	if self.tagOrId == "card" then
		local unit = csv.unit[csv.cards[self.countOrId].unitID]
		self.imgRight:texture(unit.cardShow):scale(gCommonConfigCsv.signinCardRate/3 *2)
	else
		self.imgRight:texture(dataEasy.getIconResByKey(self.tagOrId))
			:scale(gCommonConfigCsv.signinItemRate/3 *2)
	end
	-- --累积签到
	local count = 0
	for i, v in ipairs(gCostCsv.sign_in_buy) do
		if v == 0 then
			count = count + 1
		else
			break
		end
	end
	self.freeTimes = idler.new(count)
	local progress = {30, 65, 100}
	self.barPoint = idler.new(0)
	idlereasy.when(self.numDay, function (obj, val)
		for i = 1, val do
			self.showdata:atproxy(i).signIn = true
		end
		self.barPoint:set(mathEasy.showProgress(progress, MONTH_GIFT_DAY, val))
	end)
	idlereasy.any({self.vipLevel, self.signInAwards, self.numDay, self.lastSignInAward}, function (obj, vip, awards, signInTimes, lastDouble)
		local currDay = self.currDay:read()
		if currDay == tonumber(time.getDate(time.getTime()).day) then
			if awards and awards[currDay] then
				for csvID, isDouble in pairs(awards[currDay]) do
					self.showdata:atproxy(csvID).vipState = vipStateChange(csvID, isDouble, vip)
				end
			end
		end
		return true
	end)

	idlereasy.when(self.costTimes, function (obj, val)
		self.freeTimes:set(count - val)
		self.freeRetroactiveNum:set(count - val)
		local childs = self.freePanel:multiget("txt", "num")
		adapt.oneLineCenterPos(cc.p(self.freePanel:size().width/2, childs.txt:y()), {childs.txt, childs.num}, cc.p(6, 0))
		self.showDiamondPanel:set(count - val <= 0)
		self.showFreePanel:set(count - val > 0)
		if 3 - val <= 0 then
			local num = math.min((val + 1), table.length(gCostCsv.sign_in_buy))
			childs = self.diamondPanel:multiget("txt", "icon")
			childs.txt:text(gLanguageCsv.cost .. ":" .. gCostCsv.sign_in_buy[num])
			adapt.oneLineCenterPos(cc.p(self.diamondPanel:size().width/2, childs.txt:y()), {childs.txt, childs.icon}, cc.p(6, 0))
		end
	end)
	idlereasy.when(self.monthGift,function (obj, val)
		local boxArr = {}
		for i = 1, 3 do
			local state = type(val[100+i]) == "number" and val[100+i] or BOX_STATE.NOT_OPEN
			table.insert(boxArr,{id = 100 + i, state = state, num = MONTH_GIFT_DAY[i], x = originX})
		end
		self.boxData:set(boxArr)
		return true
	end)

	Dialog.onCreate(self, {blackType = 1})

	-- 自动签到
	if self.currDay:read() < time.getNowDate().day then
		gGameApp:requestServer("/game/role/sign_in", function (tb)
			gGameUI:showGainDisplay(tb)
		end)
	else
		self.itemAction = {isAction = true}
	end
end

function SignInView:initModel()
	self.totalCount = gGameModel.role:getIdler("sign_in_count")
	self.totalCountGift = gGameModel.role:getIdler("sign_in_gift")
	self.monthGift = gGameModel.monthly_record:getIdler("sign_in_gift")
	self.monthData = gGameModel.monthly_record:getIdler("month")
	self.currDay = gGameModel.monthly_record:getIdler("last_sign_in_day")
	--当前签到次数
	self.numDay = gGameModel.monthly_record:getIdler("sign_in")
	self.costTimes = gGameModel.monthly_record:getIdler("sign_in_buy_times")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.createTime = gGameModel.role:getIdler("created_time")
	self.currPos = gGameModel.monthly_record:getIdler("last_sign_in_idx")
	self.signInAwards = gGameModel.monthly_record:getIdler("sign_in_awards")
end

function SignInView:onDetailClick()
	gGameUI:showItemDetail(self.imgRight, {key = self.tagOrId, num = self.countOrId})
end

function SignInView:onRetroactiveClick()
	idlereasy.do_(function(val, dayVal, timeSec, costTimes, totalCount)
		-- @desc totalDay-签到次数上限 totalCount-当前已签到总次数
		-- timeSec 角色创建时间转换为自然日0点
		local createDate = time.getDate(timeSec)
		createDate.hour = 0
		createDate.min = 0
		createDate.sec = 0
		local totalDay = math.floor((time.getTime() - time.getTimestamp(createDate))/86400) + 1
		if totalDay > totalCount then
			if val < dayVal then
				local num = math.min(costTimes + 1, table.length(gCostCsv.sign_in_buy))
				local needCost = gCostCsv.sign_in_buy[num]
				if needCost then
					if needCost > 0 and self.rmb:read() < needCost then
						uiEasy.showDialog("rmb")
					else
						local params = {
							cb = function ()
								gGameApp:requestServer("/game/role/sign_in/buy",function (tb)
									gGameUI:showGainDisplay(tb)
								end)
							end,
							isRich = true,
							btnType = 2,
							content = string.format(gLanguageCsv.retroactiveCommonBox, needCost),
							dialogParams = {clickClose = false},
							clearFast = true,
						}
						-- 补签消耗为0时，直接补签，不用弹出二次确认界面
						if needCost <= 0 then
							params.cb()
						else
							gGameUI:showDialog(params)
						end
					end
				end
			else
				gGameUI:showTip(gLanguageCsv.presentAtDutyEveryDay)
			end
		else
			gGameUI:showTip(gLanguageCsv.signInDayLessCreateDay)
		end
	end, self.numDay, self.currDay, self.createTime, self.costTimes, self.totalCount)
end

function SignInView:onBoxClick(list, index, box)
	if self.boxData:proxy()[index].state == BOX_STATE.CAN_OPEN then
		local showOver = {false}
		gGameApp:requestServerCustom("/game/role/sign_in/month/total_award")
			:params(index+100)
			:onResponse(function (tb)
				uiEasy.setBoxEffect(box, 0.5, function()
					showOver[1] = true
				end, 20, 10)
			end)
			:wait(showOver)
			:doit(function (tb)
				gGameUI:showGainDisplay(tb)
			end)
	else
		local month = tonumber(string.sub(tostring(self.monthData:read()),5))
		local params = {
			data = csv.signin[self.boxData:read()[index].id]["month"..month],
			content = string.format(gLanguageCsv.totalSignInCanGetBox, self.boxData:read()[index].num),
			state = self.boxData:proxy()[index].state == BOX_STATE.OPENED and 0 or 1
		}
		gGameUI:showBoxDetail(params)
	end
end

function SignInView:onGetClick()
	local val = self.totalCountGift:read()
	if val[2] == 1 then
		gGameApp:requestServer("/game/role/sign_in/total_award", function(tb)
			gGameUI:showGainDisplay(tb)
		end)
	end
end

function SignInView:onItemClick(list, node, t, v)
	idlereasy.do_(function(val, dayVal)
		if val + 1 == t.k and dayVal < tonumber(time.getNowDate().day) then
			gGameApp:requestServer("/game/role/sign_in", function (tb)
				gGameUI:showGainDisplay(tb)
			end)
		else
			gGameUI:showItemDetail(node, {key = v.id, num = v.num})
		end
	end, self.numDay, self.currDay)
end

function SignInView:vipDoubleClick(list,t,v)
	if self.showdata:atproxy(t.k).vipState == VIP_STATE.CAN_GET then
		if self.currDay:read() == tonumber(time.getDate(time.getTime()).day) and t.k == self.currPos:read() then
			gGameApp:requestServer("/game/role/sign_in",function (tb)
				gGameUI:showGainDisplay(tb)
			end)
		else
			gGameApp:requestServer("/game/role/sign_in/buy",function (tb)
				gGameUI:showGainDisplay(tb)
			end, t.k)
		end
	else
		gGameUI:showDialog({title = "", content = gLanguageCsv.vipNotEnough, btnType = 1})
	end
end

return SignInView