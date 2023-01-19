
local PRICES = {
	gold = {
		[1] = gCommonConfigCsv.drawGemGoldCostPrice,
		[10] = gCommonConfigCsv.draw10GemGoldCostPrice
	},
	rmb = {
		[1] = gCommonConfigCsv.drawGemCostPrice,
		[10] = gCommonConfigCsv.draw10GemCostPrice
	}
}

local TICKETS = {
	gold = 530,
	rmb = 531
}

local ViewBase = cc.load('mvc').ViewBase
local GemDrawView = class('GemDrawView', ViewBase)
GemDrawView.RESOURCE_FILENAME = 'gem_draw.json'

GemDrawView.RESOURCE_BINDING = {
	['drawOnePanel'] = {
		varname = 'gold1',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('goldDrawOne')}
		}
	},
	['drawOnePanel.cutDownPanel.textTime'] = {
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
	['drawTenPanel'] = {
		varname = 'gold10',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('goldDrawTen')}
		}
	},
	['drawOnePanel2'] = {
		varname = 'rmb1',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('diamondDrawOne')}
		}
	},
	['drawOnePanel2.cutDownPanel.textTime'] = {
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
	['drawTenPanel2'] = {
		varname = 'rmb10',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('diamondDrawTen')}
		}
	},
	['autoDecompose'] = {
		varname = 'autoDecompose',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('clickAutoDecompose')}
		}
	},
	['drawCountPanel'] = 'drawCountPanel',
	['drawCountPanel.diamondRecord'] = 'diamondRecord',
	['drawCountPanel.goldRecord'] = 'goldRecord',
	['drawOnePanel.costInfo'] = 'gold1CostInfo',
	['drawTenPanel.costInfo'] = 'gold10CostInfo',
	['drawOnePanel2.costInfo'] = 'diamond1CostInfo',
	['drawTenPanel2.costInfo'] = 'diamond10CostInfo',
	['drawOnePanel.costInfo.textCost'] = 'gold1Cost',
	['drawTenPanel.costInfo.textCost'] = 'gold10Cost',
	['drawOnePanel2.costInfo.textCost'] = 'diamond1Cost',
	['drawOnePanel2.textFree'] = 'diamond1FreeTxt',
	['drawTenPanel2.costInfo.textCost'] = 'diamond10Cost',
	['drawOnePanel.textFree'] = 'gold1FreeTxt',
	['drawOnePanel.btnDraw'] = {
		binds = {
			event = "extend",
			class = "red_hint",
			props = {
				state = bindHelper.self("goldSign"),
				onNode = function(node)
					node:xy(430, 200)
				end,
			},
		},
	},
	['drawOnePanel.btnDraw.textNote'] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.BLUE}},
		}
	},
	['drawOnePanel2.btnDraw'] = {
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
	['drawOnePanel2.btnDraw.textNote'] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.BLUE}},
		}
	},
	['drawTenPanel.btnDraw.textNote'] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
		}
	},
	['drawTenPanel2.btnDraw.textNote'] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
		}
	},
	['typePanel.imgAdd'] = {
		varname = 'preview1',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('showPreview1')}
		}
	},
	['typePanel2.imgAdd'] = {
		varname = 'preview2',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('showPreview2')}
		}
	},
	['bg'] = 'bg',
	['txtAutoDecompose'] = {
		binds = {
			{
				event = 'effect',
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT, size = 4}}
			},
			{
				event = 'touch',
				scaletype = 0,
				methods = {ended = bindHelper.self('clickAutoDecompose')}
			}
		}
	},
	['btnRate'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('clickBtnRate')}
		}
	},
	['btnRate.txt'] = {
		binds = {
			event = 'effect',
			data = {outline = {color=ui.COLORS.NORMAL.WHITE, size=4}}
		}
	}
}
GemDrawView.RESOURCE_STYLES = {
	full = true,
}


function GemDrawView:showPreview1()
	gGameUI:stackUI('city.card.gem.preview', nil, {blackLayer = true, clickClose = true}, 'gold')
end

function GemDrawView:showPreview2()
	gGameUI:stackUI('city.card.gem.preview', nil, {blackLayer = true, clickClose = true}, 'diamond')
end

function GemDrawView:clickBtnRate()
	gGameUI:stackUI('city.card.gem.rate_preview', nil, {clickClose = true})
end

function GemDrawView:onCreate()
	-- 这两个加号按钮暂时不显示
	self.preview1:visible(false)
	self.preview2:visible(false)

	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.drawGemTitle, subTitle = "DRAW GEM"})

	widget.addAnimationByKey(self.bg, 'fushichouqu/ryl.skel', "effectBg", "effect_loop", -1)
		:alignCenter(self.bg:size())
	self.bg:scale(2)

	local state = userDefault.getForeverLocalKey('gemDrawAutoDecompose', false)
	self.autoDecompose:setSelectedState(state)
	self.useAutoDecompose = state and 1 or 0

	self:initModel()
	local goldTickets = idler.new(0)
	local rmbTickets = idler.new(0)
	self.goldSign = idler.new(true)
	self.rmbSign = idler.new(true)
	idlereasy.when(self.items, function(_, items)
		goldTickets:set(items[TICKETS.gold])
		rmbTickets:set(items[TICKETS.rmb])
	end)

	local nodeKeys = {'textNote', 'textCost', 'imgIcon'}
	local function tryUseTickets(node, costType, tickets, times, money)
		local childs = node:multiget(unpack(nodeKeys))
		local use = tickets >= times
		local enoughMoney = money >= PRICES[costType][times]
		childs.textCost:text(use and (tickets..'/'..times) or PRICES[costType][times])
		childs.imgIcon:texture(dataEasy.getIconResByKey(use and TICKETS[costType] or costType))
		adapt.oneLineCenterPos(cc.p(175, 35), {childs.textNote, childs.textCost, childs.imgIcon})
		childs.textCost:color((use or enoughMoney) and ui.COLORS.NORMAL.WHITE or ui.COLORS.NORMAL.RED)
	end
	idlereasy.any({goldTickets, self.gold}, function(_, tickets, gold)
		tickets = tickets or 0
		tryUseTickets(self.gold1CostInfo, 'gold', tickets, 1, gold)
		tryUseTickets(self.gold10CostInfo, 'gold', tickets, 10, gold)
	end)
	idlereasy.any({rmbTickets, self.rmb}, function(_, tickets, rmb)
		tickets = tickets or 0
		tryUseTickets(self.diamond1CostInfo, 'rmb', tickets, 1, rmb)
		tryUseTickets(self.diamond10CostInfo, 'rmb', tickets, 10, rmb)
	end)

	idlereasy.any({self.goldDrawCount, self.vip_level}, function(_, count, vip_level)
		local max = csv.vip[vip_level + 1].goldDrawGemCountLimit
		self.goldRecord:text(count..'/'..max)
		text.addEffect(self.goldRecord, {color = count < max and ui.COLORS.NORMAL.GREEN or ui.COLORS.NORMAL.RED})
	end)
	idlereasy.any({self.rmbDrawCount, self.vip_level}, function(_, count, vip_level)
		local max = csv.vip[vip_level + 1].rmbDrawGemCountLimit
		self.diamondRecord:text(count..'/'..max)
		text.addEffect(self.diamondRecord, {color = count < max and ui.COLORS.NORMAL.GREEN or ui.COLORS.NORMAL.RED})
	end)
	idlereasy.when(self.goldFreeCount, function(_, count)
		local free = count == 0
		self.gold1CostInfo:visible(not free)
		self.gold1FreeTxt:visible(free)
		self.gold1:get('cutDownPanel'):visible(not free)
		self.goldSign:set(free)
	end)
	idlereasy.when(self.rmbFreeCount, function(_, count)
		local free = count == 0
		self.diamond1CostInfo:visible(not free)
		self.diamond1FreeTxt:visible(free)
		self.rmb1:get('cutDownPanel'):visible(not free)
		self.rmbSign:set(free)
	end)

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
end

function GemDrawView:drawRequest(costType, drawTimes, cb)
	local vip_level = gGameModel.role:read('vip_level')
	local counts = {
		gold = self.goldDrawCount:read() or 0,
		rmb = self.rmbDrawCount:read() or 0
	}
	local limits = {
		gold = csv.vip[vip_level + 1].goldDrawGemCountLimit,
		rmb = csv.vip[vip_level + 1].rmbDrawGemCountLimit
	}

	local isFree = false
	local drawtype = costType..drawTimes
	if drawTimes == 1 then
		local freecounts = {
			gold = self.goldFreeCount:read() or 0,
			rmb = self.rmbFreeCount:read() or 0
		}
		if freecounts[costType] <= 0 then
			drawtype = costType == 'gold' and 'free_gold1' or 'free1'
			isFree = true
		end
	end

	if limits[costType] - counts[costType] <= 0 and not isFree then
		gGameUI:showTip(gLanguageCsv.gemDrawLimit)
		return
	end

	if dataEasy.getNumByKey(costType) < PRICES[costType][drawTimes]
		and not isFree
		and dataEasy.getNumByKey(TICKETS[costType]) < drawTimes
		then
		uiEasy.showDialog(costType)
		return
	end
    local ticketsCount = self.items:read()[TICKETS.rmb] or 0
	local function cb1()
		gGameApp:requestServer('/game/lottery/gem/draw', function(tb)
			local data = {}
			local view = tb.view.result or tb.view
			for _, v in pairs(view.items) do
				local t = {key = v[1], num = v[2]}
				if v[3] then
					t = {key = v[3], num = 1, decomposed = {key = v[1], num = v[2]}}
				end
				table.insert(data, t)
			end
			cb(random.shuffle(data))
			if drawtype == "rmb10" and ticketsCount < 10 then
				userDefault.setCurrDayKey("diamondGemDrawTips", 0)
			end
		end, drawtype, self.useAutoDecompose)
	end
	if (drawtype == "rmb10" and ticketsCount < 10) and userDefault.getCurrDayKey("diamondGemDrawTips", 1) == 1 and dataEasy.isUnlock("gemDrawTips") then
		local cost = PRICES[costType][drawTimes]
		gGameUI:showDialog{content = string.format(gLanguageCsv.draw10CardTips, cost), cb = cb1, btnType = 2, clearFast = true, isRich = true}
	elseif (drawtype == "rmb1" and ticketsCount == 0) or (drawtype == "rmb10" and ticketsCount < 10) then
		dataEasy.sureUsingDiamonds(cb1, PRICES[costType][drawTimes])
	else
		cb1()
	end
end

function GemDrawView:draw(costType, drawTimes)
	self:drawRequest(costType, drawTimes, function(data)
		gGameUI:stackUI('city.card.gem.result', nil, nil, data, costType, drawTimes, PRICES[costType][drawTimes], TICKETS[costType], self:createHandler('drawRequest'))
	end)
end

function GemDrawView:goldDrawOne()
	self:draw('gold', 1)
end

function GemDrawView:diamondDrawOne()
	self:draw('rmb', 1)
end

function GemDrawView:goldDrawTen()
	self:draw('gold', 10)
end

function GemDrawView:diamondDrawTen()
	self:draw('rmb', 10)
end

function GemDrawView:clickAutoDecompose()
	local state = userDefault.getForeverLocalKey('gemDrawAutoDecompose', false)
	userDefault.setForeverLocalKey('gemDrawAutoDecompose', not state)
	-- checkbox点击后自身的图标显示切换会在这个回调之后，要延后设置状态，否则显示会有问题
	performWithDelay(self.autoDecompose, function()
		self.autoDecompose:setSelectedState(not state)
	end, 0)
	self.useAutoDecompose = (not state) and 1 or 0
end

function GemDrawView:initModel()
	self.gold = gGameModel.role:getIdler('gold')
	self.rmb = gGameModel.role:getIdler('rmb')
	self.vip_level = gGameModel.role:getIdler('vip_level')
	local daily_record = gGameModel.daily_record
	self.goldDrawCount = daily_record:getIdler('draw_gem_gold')
	self.rmbDrawCount = daily_record:getIdler('draw_gem_rmb')
	self.goldFreeCount = daily_record:getIdler('gem_gold_dc1_free_count')
	self.rmbFreeCount = daily_record:getIdler('gem_rmb_dc1_free_count')
	self.items = gGameModel.role:getIdler('items')
end

return GemDrawView