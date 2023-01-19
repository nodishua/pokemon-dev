
local PRICES = {
	item = {
		[1] = gCommonConfigCsv.drawChipItemCostPrice,
		[10] = gCommonConfigCsv.draw10ChipItemCostPrice
	},
	rmb = {
		[1] = gCommonConfigCsv.drawChipCostPrice,
		[10] = gCommonConfigCsv.draw10ChipCostPrice
	}
}

local CHIPUPLIMIT = gCommonConfigCsv.chipUpLimit

local TICKETS = {
	item = 538,
	rmb = 537
}

local STATETAB = {
	"city/drawcard/draw/icon_jfbx_dk.png",
	"city/drawcard/draw/icon_jfbx.png",
	"city/drawcard/draw/icon_jfbx1.png",
	"city/drawcard/draw/icon_jfbx2.png",
	"city/drawcard/draw/icon_jfbx3.png",
	"city/drawcard/draw/icon_jfbx3_dk.png",
}
local bgTextTab = {
	"city/drawcard/draw/box_wdd.png",
	"city/drawcard/draw/box_ydd.png",
}

local ViewBase = cc.load('mvc').ViewBase
local ChipDrawView = class('ChipDrawView', ViewBase)
ChipDrawView.RESOURCE_FILENAME = 'chip_draw.json'

ChipDrawView.RESOURCE_BINDING = {
	['panelDownLeft.drawOnePanel'] = {
		varname = 'item1',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.defer(function(view)
				return view:draw('item', 1)
			end)}
		}
	},
	['panelDownLeft.drawOnePanel.cutDownPanel.textTime'] = {
		binds = {
			event = "text",
			idler = bindHelper.self("time"),
			method = function(val)
				if val == 0 then
					return ""
				end
				return time.getCutDown(val).clock_str
			end,
		},
	},

	["selectSuitItem"] = "selectSuitItem",
	['panelDownLeft.drawTenPanel'] = {
		varname = 'item10',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.defer(function(view)
				return view:draw('item', 10)
			end)}
		}
	},
	['panelDownLeft.drawOnePanel.costInfo'] = 'item1CostInfo',
	['panelDownLeft.drawTenPanel.costInfo'] = 'item10CostInfo',
	['panelDownLeft.drawOnePanel.costInfo.textCost'] = 'item1Cost',
	['panelDownLeft.drawTenPanel.costInfo.textCost'] = 'item10Cost',

	['panelDownLeft.drawTenPanel.btnDraw.textNote'] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
		}
	},

	['panelDownLeft.drawOnePanel.textFree'] = 'item1FreeTxt',
	['panelDownLeft.drawOnePanel.btnDraw'] = {
		binds = {
			event = "extend",
			class = "red_hint",
			props = {
				state = bindHelper.self("itemSign"),
				onNode = function(node)
					node:xy(430, 200)
				end,
			},
		},
	},
	['panelDownLeft.drawOnePanel.btnDraw.textNote'] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.BLUE}},
		}
	},

	['panelDownLeft.typePanel.imgAdd'] = {
		varname = 'preview1',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('showPreview1')}
		}
	},

	['panelDownRight.drawOnePanel2'] = {
		varname = 'rmb1',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.defer(function(view)
				return view:draw('rmb', 1)
			end)}
		}
	},
	['panelDownRight.drawOnePanel2.cutDownPanel.textTime'] = {
		binds = {
			event = "text",
			idler = bindHelper.self("time"),
			method = function(val)
				if val == 0 then
					return ""
				end
				return time.getCutDown(val).clock_str
			end,
		},
	},
	['panelDownRight.drawTenPanel2'] = {
		varname = 'rmb10',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.defer(function(view)
				return view:draw('rmb', 10)
			end)}
		}
	},

	['panelUpRight.drawCountPanel'] = 'drawCountPanel',
	['panelUpRight.drawCountPanel.diamondRecord'] = 'diamondRecord',
	['panelUpRight.drawCountPanel.goldRecord'] = 'itemRecord',

	['panelDownRight.drawOnePanel2.costInfo'] = 'diamond1CostInfo',
	['panelDownRight.drawTenPanel2.costInfo'] = 'diamond10CostInfo',

	['panelDownRight.drawOnePanel2.costInfo.textCost'] = 'diamond1Cost',
	['panelDownRight.drawOnePanel2.textFree'] = 'diamond1FreeTxt',
	['panelDownRight.drawTenPanel2.costInfo.textCost'] = 'diamond10Cost',

	['panelDownRight.drawOnePanel2.btnDraw'] = {
		binds = {
			event = "extend",
			class = "red_hint",
			props = {
				state = bindHelper.self("rmbSign"),
				onNode = function(node)
					node:xy(430, 200)
				end,
			},
		},
	},
	['panelDownRight.drawOnePanel2.btnDraw.textNote'] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.BLUE}},
		}
	},

	['panelDownRight.drawTenPanel2.btnDraw.textNote'] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
		}
	},

	['panelDownRight.typePanel2.imgAdd'] = {
		varname = 'preview2',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('showPreview2')}
		}
	},
	['bg'] = 'bg',

	['panelMidRight.btnRate'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('clickBtnRate')}
		}
	},
	['panelMidRight.btnRate.txt'] = {
		binds = {
			event = 'effect',
			data = {outline = {color=ui.COLORS.NORMAL.WHITE, size=4}}
		}
	},
	["panelUpRight.panelSelectSuit"] = {
		varname = "panelSelectSuit",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self('onBtnSelectSuit')}
		}
	},
	["panelUpRight.txtTip"] = "txtTip",
	["panelMidRight.downPanel"] = "downPanel",
	["panelMidRight.downPanel.item1.bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("livenessPoint1"),
			},
		}
	},
	["panelMidRight.downPanel.item2.bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("livenessPoint2"),
			},
		}
	},
	["panelMidRight.downPanel.item3.bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("livenessPoint3"),
			},
		}
	},
	["panelMidRight.downPanel.item1.number"] = "numberAll",
	["panelMidRight.downPanel.item2.number"] = "number2",
	["panelMidRight.downPanel.item3.number"] = "number3",
	["panelMidRight.downPanel.item4.number"] = "number4",
	["panelMidRight.downPanel.item2"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onAwardClick(1)
			end)
		},
	},
	["panelMidRight.downPanel.item3"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onAwardClick(2)
			end)
		},
	},
	["panelMidRight.downPanel.item4"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onAwardClick(3)
			end)
		},
	},
}
ChipDrawView.RESOURCE_STYLES = {
	full = true,
}



function ChipDrawView:clickBtnRate()
	gGameUI:stackUI('city.card.chip.rate_preview')
end

function ChipDrawView:onCreate()
	-- 这两个加号按钮暂时不显示
	self.preview1:visible(false)
	self.preview2:visible(false)
	-- self.downPanel:visible(false)

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.chipTitle, subTitle = "CHIP"})

	widget.addAnimationByKey(self.bg, 'chip/xdck.skel', "effectBg", "effect_loop", -1)
		:alignCenter(self.bg:size())
	self.bg:scale(2)

	self:initModel()
	local itemTickets  = idler.new(0)
	local rmbTickets   = idler.new(0)
	self.itemSign      = idler.new(true)
	self.rmbSign       = idler.new(true)
	self.selectUpSuitID = {}
	self:initSelectSuitUI()

	-- 检测抽奖卷的显示问题
	idlereasy.when(self.items, function(_, items)
		itemTickets:set(items[TICKETS.item])
		rmbTickets:set(items[TICKETS.rmb])
	end)

	local function tryUseTickets(node, costType, tickets, times, money)
		local childs = node:multiget('textNote', 'textCost', 'imgIcon')
		local use = tickets >= times
		local enoughMoney = money >= PRICES[costType][times]
		childs.textCost:text(use and (tickets..'/'..times) or PRICES[costType][times])
		childs.imgIcon:texture(dataEasy.getIconResByKey(use and TICKETS[costType] or costType))
		adapt.oneLineCenterPos(cc.p(175, 35), {childs.textNote, childs.textCost, childs.imgIcon})
		childs.textCost:color((use or enoughMoney) and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED)
	end

	local function itemUserTickets(node, costType, tickets, times, money)
		local childs = node:multiget('textNote', 'textCost', 'imgIcon')

		local enoughMoney = tickets >= PRICES[costType][times]
		childs.textCost:text(tickets..'/'.. PRICES[costType][times])
		childs.imgIcon:texture(dataEasy.getIconResByKey(TICKETS[costType]))
		adapt.oneLineCenterPos(cc.p(175, 35), {childs.textNote, childs.textCost, childs.imgIcon})
		childs.textCost:color(enoughMoney and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED)
	end


	-- 道具抽取
	idlereasy.any({itemTickets}, function(_, tickets, item)
		tickets = tickets or 0
		itemUserTickets(self.item1CostInfo,"item", tickets, 1, item)
		itemUserTickets(self.item10CostInfo,"item", tickets, 10, item)
	end)

	-- 砖石抽取显示
	idlereasy.any({rmbTickets, self.rmb}, function(_, tickets, rmb)
		tickets = tickets or 0
		tryUseTickets(self.diamond1CostInfo, 'rmb', tickets, 1, rmb)
		tryUseTickets(self.diamond10CostInfo, 'rmb', tickets, 10, rmb)
	end)

	--抽取次数显示
	idlereasy.any({self.itemDrawCount, self.vip_level}, function(_, count, vip_level)
		local max = gVipCsv[vip_level].itemDrawChipCountLimit
		self.itemRecord:text(count..'/'..max)
		text.addEffect(self.itemRecord, {color = count < max and ui.COLORS.NORMAL.GREEN or ui.COLORS.NORMAL.RED})
	end)

	idlereasy.any({self.rmbDrawCount, self.vip_level}, function(_, count, vip_level)
		local max = gVipCsv[vip_level].rmbDrawChipCountLimit
		self.diamondRecord:text(count..'/'..max)
		text.addEffect(self.diamondRecord, {color = count < max and ui.COLORS.NORMAL.GREEN or ui.COLORS.NORMAL.RED})
	end)

	-- 免费次数时界面显示
	idlereasy.when(self.itemFreeCount, function(_, count)
		local free = count == 0
		self.item1CostInfo:visible(not free)
		self.item1FreeTxt:visible(free)
		self.item1:get('cutDownPanel'):visible(not free)
		self.itemSign:set(free)
	end)

	idlereasy.when(self.rmbFreeCount, function(_, count)
		local free = count == 0
		self.diamond1CostInfo:visible(not free)
		self.diamond1FreeTxt:visible(free)
		self.rmb1:get('cutDownPanel'):visible(not free)
		self.rmbSign:set(free)
	end)

	-- 获取时间，免费倒计时显示
	local getDeltaTime = function()
		local curtime = time.getTime()
		local refresTime = time.getNumTimestamp(tonumber(time.getTodayStr()), time.getRefreshHour())
		if refresTime < curtime then
			refresTime = refresTime + 3600 * 24
		end
		return refresTime - curtime
	end
	local t = getDeltaTime()
	self.time = idler.new(t)
	self:enableSchedule():schedule(function (dt)
		self.time:modify(function(oldval)
			local curval = oldval - 1
			if curval < 0 then
				curval = getDeltaTime()
			end
			return true, curval
		end)
	end, 1, 0)

	self.siteStateTab, self.ChipAwardTab  =  {}, {}
	self.awardIdTabel = {}
	for k,v in orderCsvPairs(csv.draw_count) do
		if v.drawType == 6 then
			self.ChipAwardTab[k] = v
		end
	end

	for i=1, 3 do
		self["livenessPoint"..i] = idler.new(0)
		self.siteStateTab[i] = 2
	end
	self:initAward()

	self.txtTip:text(gLanguageCsv.chipDrawSuitUp01)
end

--# 累计宝箱 self.diamondUpId 限定抽卡 self.rmblocation 钻石抽卡
function ChipDrawView:initAward()
	local perIdx

	self.awardIdTabel = {}
	self.siteStateTab = {2, 2, 2}
	local diamondXS, getAwardState
	local limitNumber10, limitNumber1
	self.awardTab = {}
	local awardStateTab = {}
	local awardK, remainder = 0, 0
	local data, content, state

	local limitNumber = 0
	self.awardTab = self.ChipAwardTab
	getAwardState = self.getDiamondAwardState:read()[6] or {}
	limitNumber10 = self.chipAllCountTen:read() * 10
	limitNumber1  = self.chipAllCount:read()
	limitNumber   = limitNumber1 + limitNumber10

	getAwardState = getAwardState or {}
-- 		--# 根据宝箱信息初始话宝箱,i+1是可领取宝箱从item2开始的(有疑问可以看工程)
-- 		--# stateTab是宝箱对应的纹理
-- 		--# self.livenessPoint是进度条
-- 		--# state是宝箱状态1是可领取，0是已领取切大于limitNumber也是可领取
-- 		--# siteStateTab用来保存当前按下的宝箱的位置及信息,0已领取1可领取2未完成
	local nodeStateFunc = function(site, id, preCount)
		local number = csv.draw_count[id] and csv.draw_count[id].count
		if not number then return end
		self.awardIdTabel[site] = id
		local item = self.downPanel:get("item" .. (site + 1))
		item:get("number"):text(number - preCount)
		item:get("result"):visible(false)
		self["livenessPoint"..site]:set(100)
		item:get("bg"):texture(bgTextTab[2])
		item:get("number"):setTextColor(ui.COLORS.GLOW.YELLOW)
		if item:get("effect") then
			item:get("effect"):hide()
		end
		if getAwardState[id] == 0 then
			item:get("state"):texture(site == 3 and STATETAB[6] or STATETAB[1])
			self.siteStateTab[site] = 0

		elseif getAwardState[id] == 1 or number <= limitNumber then
			item:get("state"):texture(site == 3 and STATETAB[5] or STATETAB[2])
			self.siteStateTab[site] = 1
			if not item:get("effect") then
				widget.addAnimationByKey(item, "effect/jiedianjiangli.skel", "effect", "effect_loop", 0)
					:xy(100, 30)
					:scale(0.7)
			end
			item:get("effect"):show()

		else
			local shangci = csv.draw_count[id-1] and csv.draw_count[id-1].count or 0
			local spaceLen = csv.draw_count[id].count - shangci
			self["livenessPoint"..site]:set(not limitNumber and 0 or (limitNumber-shangci)/spaceLen*100)
			item:get("number"):setTextColor(ui.COLORS.NORMAL.WHITE)
			item:get("bg"):texture(bgTextTab[1])
			item:get("state"):texture(site == 3 and STATETAB[4] or STATETAB[3])
		end
	end

	if table.nums(self.awardTab) >= 3 then
		local count = 0
		local maxId
		local showFirstId = nil
		-- 奖励遍历有个排序问题，这个地方有坑，使用orderCsvPairs 转换排序
		for k, v in orderCsvPairs(self.awardTab) do
			count = count + 1
			maxId = k
			-- 每3组进行显示，还未领奖的

			if getAwardState[k] ~= 0 then
				local firstId = k - (count - 1) % 3
				if self.awardTab[firstId + 2] then
					showFirstId = firstId
				end
				break
			end
		end
		if not showFirstId then
			showFirstId = maxId - count % 3 - 2
		end

		local preCount = 0
		if self.awardTab[showFirstId - 1] then
			preCount = self.awardTab[showFirstId - 1].count
		end
		-- 奖励预览显示减掉相应值

		self.preCount = preCount
		nodeStateFunc(1, showFirstId, preCount)
		nodeStateFunc(2, showFirstId + 1, preCount)
		nodeStateFunc(3, showFirstId + 2, preCount)
		self.downPanel:get("item1"):get("number"):text(limitNumber - preCount)
		self.downPanel:visible(true)
	end

end

function ChipDrawView:onAwardClick(idx)
	local id = self.awardIdTabel[idx]
	if self.siteStateTab[idx] == 1 then
		gGameApp:requestServer("/game/draw/sum/box/get", function(cb)
			gGameUI:showGainDisplay(csv.draw_count[id].award, {raw = false, cb = function()
				self.downPanel:get("item"..(idx+1)):get("result"):visible(false)
				self:initAward()
			end})
		end, id)
		return
	end

	gGameUI:showBoxDetail({
		data = csv.draw_count[id].award,
		content = string.format(gLanguageCsv.accumulatedAward, csv.draw_count[id].count - (self.preCount or 0)),
		state = self.siteStateTab[idx] == 2 and 1 or 0,
	})
end

function ChipDrawView:drawRequest(costType, drawTimes, cb)
	local vip_level = gGameModel.role:read('vip_level')

	-- 抽取次数
	local counts = {
		item = self.itemDrawCount:read() or 0,
		rmb = self.rmbDrawCount:read() or 0
	}

	-- 抽取上上限
	local limits = {
		item = gVipCsv[vip_level].itemDrawChipCountLimit,
		rmb = gVipCsv[vip_level].rmbDrawChipCountLimit
	}

	-- 当单抽的时候，首先花费单抽次数
	local isFree = false
	local drawtype = costType..drawTimes
	if drawTimes == 1 then
		local freecounts = {
			item = self.itemFreeCount:read() or 0,
			rmb = self.rmbFreeCount:read() or 0
		}
		if freecounts[costType] <= 0 then
			drawtype = costType == 'item' and 'free_item1' or 'free1'
			isFree = true
		end
	end

	-- 抽取次数为0
	if limits[costType] - counts[costType] < drawTimes and not isFree then
		gGameUI:showTip(gLanguageCsv.chipDrawLimit)
		return
	end

	if costType == "item" and dataEasy.getNumByKey(TICKETS[costType]) < PRICES[costType][drawTimes]and not isFree then
		gGameUI:showTip(gLanguageCsv.inadequateProps)
		return
	end
	-- 花费不足
	if dataEasy.getNumByKey(costType) < PRICES[costType][drawTimes] and not isFree
		and dataEasy.getNumByKey(TICKETS[costType]) < drawTimes  then
		uiEasy.showDialog(costType)
		return
	end

	-- 读取抽奖卷数量
    local ticketsCount = self.items:read()[TICKETS.rmb] or 0

	local function cb1()
		gGameApp:requestServer('/game/lottery/chip/draw', function(tb)

			local data = dataEasy.mergeRawDate(tb)
			self:initAward()
			cb(random.shuffle(data))
			if drawtype == "rmb10" and ticketsCount < 10 then
				userDefault.setCurrDayKey("diamondChipDrawTips", 0)
			end
		end, drawtype, self.selectUpSuitID)
	end

	if (drawtype == "rmb10" and ticketsCount < 10) and userDefault.getCurrDayKey("diamondChipDrawTips", 1) == 1 and dataEasy.isUnlock("ChipDrawTips") then
		local cost = PRICES[costType][drawTimes]
		gGameUI:showDialog{content = string.format(gLanguageCsv.draw10CardTips, cost), cb = cb1, btnType = 2, clearFast = true, isRich = true}
	elseif (drawtype == "rmb1" and ticketsCount == 0) or (drawtype == "rmb10" and ticketsCount < 10) then
		dataEasy.sureUsingDiamonds(cb1, PRICES[costType][drawTimes])
	else
		cb1()
	end
end

function ChipDrawView:draw(costType, drawTimes)
	self:drawRequest(costType, drawTimes, function(data)

		gGameUI:stackUI('city.card.chip.result', nil, nil, data, costType, drawTimes, PRICES[costType][drawTimes], TICKETS[costType], self:createHandler('drawRequest'))
	end)
end


function ChipDrawView:initSelectSuitUI()
	self.selectUpSuitID = {}
	local temp = userDefault.getForeverLocalKey("selectUpSuitID", {})

	for index = 1, CHIPUPLIMIT do
		if temp[index] ~= 0 then
			table.insert(self.selectUpSuitID, temp[index])
		end
	end

	for index =CHIPUPLIMIT, 1, -1 do
		local item = self.panelSelectSuit:get("item0"..index)
		if not item then
			item = self.selectSuitItem:clone()
				:xy(600 - 140*(CHIPUPLIMIT+ 1 - index), 0)
				:addTo(self.panelSelectSuit, 1, "item0"..index)
		end

		local childs = item:multiget("imgIcon","imgAdd")

		local sign = self.selectUpSuitID[index] == nil
		childs.imgAdd:visible(sign)
		childs.imgIcon:visible(not sign)

		if not sign then
			local _, cfg = next(gChipSuitCsv[self.selectUpSuitID[index]][6])
			local str = string.gsub(cfg.suitIcon, '0.png', '2.png')
			childs.imgIcon:texture(str)
		end
	end

	local img = self.panelSelectSuit:get("img01")
	img:x(520-CHIPUPLIMIT*140)
end

function ChipDrawView:onBtnSelectSuit()
	gGameUI:stackUI('city.card.chip.select_suit', nil, nil, {callBack = self:createHandler("initSelectSuitUI")})
end


function ChipDrawView:initModel()
	self.rmb       = gGameModel.role:getIdler('rmb')
	self.vip_level = gGameModel.role:getIdler('vip_level')

	local daily_record = gGameModel.daily_record
	self.itemDrawCount = daily_record:getIdler('draw_chip_item')
	self.rmbDrawCount  = daily_record:getIdler('draw_chip_rmb')
	self.itemFreeCount = daily_record:getIdler('chip_item_dc1_free_count')
	self.rmbFreeCount  = daily_record:getIdler('chip_rmb_dc1_free_count')

	self.items                = gGameModel.role:getIdler('items')
	self.chipAllCount         = gGameModel.lottery_record:getIdler("chip_rmb_dc1_counter") -- 钻石单抽计数
	self.chipAllCountTen      = gGameModel.lottery_record:getIdler("chip_rmb_dc10_counter") -- 钻石十连抽计数
	self.getDiamondAwardState = gGameModel.role:getIdler("draw_sum_box")
end

return ChipDrawView