-- @date:   2019-05-10
-- @desc:   抽卡界面

local DRAWEQUIPTIMES = 10
local MAXLEFTCOUNTS = 9
local TYPE_DEFINE = {
	diamond = "diamond",	--钻石抽卡
	gold = "gold",			--金币抽卡
	equip = "equip",		--饰品抽卡
	limit = "limit",		--限时抽卡（旧魂匣）
	diamond_up = "diamond_up",	--限时轮换钻石抽卡
	self_choose = "self_choose",		--自选抽卡
}
local AWARD_COUNT = {
	normal = 10,
	hero = 30,
	nightmare = 0,
}

local stateTab = {
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

local drawCardTools = require "app.views.city.drawcard.tools"

local DrawCardView = class("DrawCardView", cc.load("mvc").ViewBase)
DrawCardView.RESOURCE_FILENAME = "drawcard.json"
DrawCardView.RESOURCE_BINDING = {
	["item"] = "item",
	["effectView"] = {
		varname = "effectView",
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowEffect"),
		},
	},
	["topView"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("canClick"),
			method = function(val)
				return not val
			end,
		},
	},
	["imgBG"] = {
		varname = "imgBG",
		binds = {
			event = "texture",
			idler = bindHelper.self("curType"),
			method = function(val)
				local path = "city/drawcard/img_ck@.jpg"
				if val == TYPE_DEFINE.gold then
					path = "city/drawcard/img_ck_jb@.jpg"
				elseif val == TYPE_DEFINE.limit then
					path = "city/drawcard/img_xsck.jpg"
				elseif val == TYPE_DEFINE.diamond_up then
					path = "city/drawcard/img_xdck.jpg"
				elseif val == TYPE_DEFINE.self_choose then
					path = "city/drawcard/img_bg_zxck.jpg"
				end
				return path
			end,
		},
	},
	["btnItem"] = "btnItem",
	["cardItem"] = "cardItem",
	["list"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("btnItem"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					node:name(v.key)
					local path = "city/drawcard/draw/"
					local btnPath = v.isSel and path.."btn_xz.png" or path.."btn_ckyq.png"
					local imgBtn = node:get("imgbtn")
					imgBtn:texture(btnPath)
					local titlePath = v.isSel and path..v.titlePath[2] or path..v.titlePath[1]
					local imgTitle = node:get("imgTitle")
					imgTitle:texture(titlePath)

					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					node:setTouchEnabled(not v.isSel)
					if v.isSel then
						imgBtn:x(246) --偏移10个像素 图片有透明处13个像素
					else
						imgBtn:x(225)
					end
					if v.redHint then
						list.state = v.isSel ~= true
						bind.extend(list, node, v.redHint)
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onBtnClick"),
			},
		},
	},
	["typePanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("curType"),
			method = function(val)
				local result = false
				if val == TYPE_DEFINE.diamond or val == TYPE_DEFINE.diamond_up  or val == TYPE_DEFINE.self_choose then
					result = true
				end

				return result
			end,
		},
	},
	["perview"] = {
		varname = "perview",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPerviewClick")}
		}
	},
	["drawOnePanel"] = {
		varname = "drawOnePanel",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onDrawOneClick")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					state = true,
					listenData = {
						curType = bindHelper.self("curType"),
					},
					specialTag = "drawcardOnece",
					onNode = function (node)
						node:xy(410, 250)
							:z(10)
					end
				}
			},
		}
	},
	["drawOnePanel.textFree"] = {
		varname = "txtFree",
		binds = {
			event = "visible",
			idler = bindHelper.self("isFree")
		}
	},
	["drawOnePanel.textNote"] = {
		varname = "drawLeftText",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("curType"),
				method = function(val)

					return val == TYPE_DEFINE.equip
				end,
			},
			{
				event = "text",
				idler = bindHelper.self("leftDrawTimes")
			},
		}
	},
	["drawOnePanel.costInfo"] = {
		varname = "costInfo",
		binds = {
			event = "visible",
			idler = bindHelper.self("isCost"),
			method = function(val)
				return val
			end,
		}
	},
	["drawOnePanel.costInfo.textNote"] = "costTextNote1",
	["drawOnePanel.costInfo.textCost"] = {
		varname = "costOne",
		binds = {
			event = "text",
			idler = bindHelper.self("drawOnceCost")
		}
	},
	["drawOnePanel.costInfo.imgIcon"] = {
		varname = "imgOne",
		binds = {
			event = "texture",
			idler = bindHelper.self("oneIconPath"),
		}
	},
	["drawOnePanel.btnDrawOne.textNote"] = {
		varname = "oneDrawText",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.BLUE}},
		}
	},
	["drawOnePanel.privilegePanel"] = "privilegePanel",
	["drawTenPanel"] = {
		varname = "drawTenPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDrawTenClick")}
		}
	},
	["drawTenPanel.costInfo.textNote"] = "costTextNote2",
	["drawTenPanel.costInfo.imgIcon"] = {
		varname = "imgTen",
		binds = {
			event = "texture",
			idler = bindHelper.self("tenIconPath"),
		},
	},
	["drawTenPanel.btnDrawTen.textNote"] = {
		varname = "tenDrawText",
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
			},
			{
				event = "text",
				idler = bindHelper.self("btnText"),
			},
		}
	},
	["drawTenPanel.costInfo.textCost"] = {
		varname = "costTen",
		binds = {
			event = "text",
			idler = bindHelper.self("drawTenCost"),
		}
	},
	-- ["limitTime"] = {
	-- 	binds = {
	-- 		event = "visible",
	--     	idler = bindHelper.self("isLimitDraw"),
	--     }
	-- },
	["cutDownPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isCutDown"),
		},
	},
	["diamondUpCutDownPanel"] = {
		varname = "diamondUpCutDownPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("curType"),
			method = function(val)
				return val == TYPE_DEFINE.diamond_up
			end,
		},
	},

	["diamondUpCardPanel"] = {
		varname = "diamondUpCardPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("curType"),
			method = function(val)
				return val == TYPE_DEFINE.diamond_up or val == TYPE_DEFINE.self_choose
			end,
		},
	},
	["imgDiamondUpTips"] = {
		varname = "imgDiamondUpTips",
		binds = {
			event = "visible",
			idler = bindHelper.self("curType"),
			method = function(val)
				return val == TYPE_DEFINE.diamond_up
			end,
		},
	},

	["diamondUpCutDownPanel.textTime"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("time"),
			method = function(val)
				if val == 0 then
					return ""
				end
				return time.getCutDown(val).min_sec_clock
			end,
		},
	},

	["cutDownPanel.textTime"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("time"),
			method = function(val)
				if val == 0 then
					return ""
				end
				return time.getCutDown(val).min_sec_clock
			end,
		},
	},
	["freePanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isFree"),
		},
	},
	["freePanel.textTime"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("freeTimes"),
		},
	},
	["freePanel.textNote"] = "freeTxt",
	["equipTip"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("curType"),
			method = function(val)
				return val == TYPE_DEFINE.equip
			end,
		},
	},
	["equipTip.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["shop"] = {
		varname = "shop",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("curType"),
				method = function(val)
					return val == TYPE_DEFINE.equip
				end,
			},
			{
				event = "touch",
				methods = {ended = bindHelper.self("onShopClick")}
			},
		},
	},
	["goldLeftTimes"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("curType"),
			method = function(val)
				return val == TYPE_DEFINE.gold
			end,
		},
	},
	["goldLeftTimes.textNote"] = {
		varname = "goldTextNote",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["goldLeftTimes.textLeftNum"] = {
		varname = "goldLeftTimes",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["goldLeftTimes.textAllNum"] = {
		varname = "goldAllTimes",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["limitPanel"] = {
		varname = "limitPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("curType"),
			method = function(val)
				return val == TYPE_DEFINE.limit
			end,
		},
	},
	["limitPanel.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["limitPanel.textNote"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["equipPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("curType"),
			method = function(val)
				return val == TYPE_DEFINE.equip
			end,
		},
	},
	["downPanel"] = "downPanel",
	["downPanel.item1.bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("livenessPoint1"),
			},
		}
	},
	["downPanel.item2.bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("livenessPoint2"),
			},
		}
	},
	["downPanel.item3.bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("livenessPoint3"),
			},
		}
	},
	["downPanel.item1.number"] = "numberAll",
	["downPanel.item2.number"] = "number2",
	["downPanel.item3.number"] = "number3",
	["downPanel.item4.number"] = "number4",
	["downPanel.item2"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onAwardClick(1)
			end)
		},
	},
	["downPanel.item3"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onAwardClick(2)
			end)
		},
	},
	["downPanel.item4"] = {
		binds = {
			event = "click",
			method = bindHelper.defer(function(view)
				return view:onAwardClick(3)
			end)
		},
	},
	["marqueePanel"] = {
		varname = "marqueePanel",
		binds = {
			event = "extend",
			class = "marquee",
		},
	},
	["switchBtn"] = {
		varname = "switchBtn",
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("curType"),
				method = function(val)
					return val == TYPE_DEFINE.self_choose
				end,
			},
			{
				event = "touch",
				methods = {ended = bindHelper.self("onSwitchClick")}
			},

		},
	},
	["selfChooseTip"] = {
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("curType"),
				method = function(val)
					return val == TYPE_DEFINE.self_choose
				end,
			},
		}
	},
	["selfChooseCurrentUp"] = {
		binds = {
			{
				event = "visible",
				idler = bindHelper.self("curType"),
				method = function(val)
					return val == TYPE_DEFINE.self_choose
				end,
			},
		}
	},
	["selfChooseCurrentUp.icon"] = "chooseUpIcon",
	["selfChooseCurrentUp.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("selfChooseCurrentUpData"),
				item = bindHelper.self("chooseUpIcon"),
				itemAction = {isAction = true},
				onItem = function(list,node,k,v)
					node:texture(ui.ATTR_ICON[v])
				end,
			},
		},
	},
	["selfChooseCurrentUp.label1"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(241, 62, 87, 255), size = 4}}
		}
	},
	["selfChooseCurrentUp.label2"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(241, 62, 87, 255), size = 4}}
		}
	}
}

-- tabName 到指定页签，不存在选择第一个 "diamond", "gold", "equip", "limit", "diamondup"
function DrawCardView:onCreate(tabName)
	self.isShowEffect = idler.new(false)
	self.diamondUpId = idler.new(false)
	self.limitId = idler.new(false)
	self:initModel()

	local diamondData = {
		key = "diamond",
		txt = gLanguageCsv.diamondDraw,
		type = TYPE_DEFINE.diamond,
		isSel = false,
		titlePath = { "txt_zsck.png", "txt_zsck1.png"},
		redHint = {
			class = "red_hint",
			props = {
				state = bindHelper.self("state"),
				specialTag = "drawcardDiamondFree",
				onNode = function (node)
					node:xy(380, 160)
						:z(10)
				end
			}
		},
		weight = 3,
	}
	local goldData = {
		key = "gold",
		txt = gLanguageCsv.goldDraw,
		type = TYPE_DEFINE.gold,
		isSel = false,
		titlePath = { "txt_jbck.png", "txt_jbck1.png"},
		redHint = {
			class = "red_hint",
			props = {
				state = bindHelper.self("state"),
				specialTag = "drawcardGoldFree",
				onNode = function (node)
					node:xy(380, 160)
						:z(10)
				end
			}
		},
		weight = 2,
	}
	local equipData = {
		key = "equip",
		txt = gLanguageCsv.drawEquip, type = TYPE_DEFINE.equip, isSel = false,
		titlePath = { "txt_spck.png", "txt_spck1.png"},
		redHint = {
			class = "red_hint",
			props = {
				state = bindHelper.self("state"),
				specialTag = "drawcardEquipFree",
				onNode = function (node)
					node:xy(380, 160)
						:z(10)
				end
			}
		},
		weight = 1,
	}
	local limitData = {
		key = "limit",
		txt = gLanguageCsv.drawLimit, type = TYPE_DEFINE.limit, isSel = false,
		titlePath = { "txt_xsss.png", "txt_xsss1.png"},
		weight = 6,
	}
	local diamondUpData = {
		key = "diamondup",
		txt = gLanguageCsv.diamondUpDrawCard, type = TYPE_DEFINE.diamond_up, isSel = false,
		titlePath = { "txt_xdck.png", "txt_xdck1.png"},
		weight = 4,
	}
	local selfChooseUpData = {
		key = "self_choose",
		txt = gLanguageCsv.diamondUpDrawCard, type = TYPE_DEFINE.self_choose, isSel = false,
		titlePath = {"txt_zxck.png","txt_zxck1.png"},
		weight = 5,

	}
	local function tabSort(tabDatas)
		table.sort(tabDatas,function(a, b)
			return a.weight > b.weight
		end)
		for k,v in ipairs(tabDatas) do
			if v.key == "diamond" then
				self.rmblocation = k
			elseif v.key == "limit" then
				self.limitIdHJ = k
			elseif v.key == "diamondup" then
				self.limitlocation = k
			elseif v.key == "self_choose" then
				self.selfChooseLocation = k
			end
		end
	end

	local tabDatas = {diamondData, goldData}
	tabSort(tabDatas)

	if self.diamondUpId:read() then
		table.insert(tabDatas, diamondUpData)
		tabSort(tabDatas)
	end

	if self.limitId:read() then
		table.insert(tabDatas, limitData)
		tabSort(tabDatas)
	end

	dataEasy.getListenUnlock(gUnlockCsv.groupDrawCardUp, function (isUnlock)
		if not isUnlock then
			return
		end
		table.insert(tabDatas, selfChooseUpData)
		tabSort(tabDatas)
		if self.tabDatas then
			self.tabDatas:update(tabDatas)
		end
	end)

	dataEasy.getListenUnlock(gUnlockCsv.drawEquip, function(isUnlock)
		if not isUnlock then
			return
		end
		table.insert(tabDatas, equipData)
		if self.tabDatas then
			self.tabDatas:update(tabDatas)
		end
	end)

	local idx
	if tabName then
		for i,v in ipairs(tabDatas) do
			if v.key == tabName then
				idx = i
				break
			end
		end
	end
	idx = idx or 1
	tabDatas[idx].isSel = true

	self.tabDatas = idlers.newWithMap(tabDatas) 		-- 左侧标签栏数据
	self.perIdx = idx 									-- 上一个页面id
	self.curType = idler.new(tabDatas[idx].type)		-- 当前页面类型
	self.canClick = idler.new(true)						-- 是否禁止点击
	self.isHalf = false 								-- 半价标志
	self.isLimitDraw = idler.new(false)					-- 是否限时抽卡
	self.isCost = idler.new(false)						-- 是否付费抽卡
	self.isFree = idler.new(false)						-- 是否免费抽卡
	self.isCutDown = idler.new(false)					-- 倒计时时间
	self.freeTimes = idler.new("")						-- 剩余免费次数
	self.tenIconPath = idler.new("")					-- 十连icon
	self.oneIconPath = idler.new("")					-- 单抽icon
	self.btnText = idler.new("")						-- 按钮文字
	self.drawOnceCost = idler.new(0)					-- 单抽消耗数字
	self.drawTenCost = idler.new(0)						-- 十连消耗数字
	self.leftDrawTimes = idler.new("")					-- 剩余N次抽卡得精灵的文字
	self.time = idler.new(0)
	self.selfChooseCurrentUpData = idlers.new()          -- 自选抽卡当前属性数据

	--时间到时移除活动
	local removeUnSchduleFunc = function(ids)
		local tabDataInit = {}
		for k,v in orderCsvPairs(clone(tabDatas)) do
			if k ~= ids then
				v.isSel = false
				table.insert(tabDataInit, v)
			end
		end
		tabDatas = clone(tabDataInit)
		self.rmblocation = self.rmblocation - 1
		tabDataInit[1].isSel = true
		self.perIdx = 1
		self.tabDatas:update(tabDataInit)
		self.downPanel:visible(false)
		self.curType:set(tabDataInit[self.perIdx].type)
		self:initAward()
	end

	idlereasy.any({self.limitId, self.diamondUpId}, function(_, limitId, diamondUpId)
		self.diamondDataId = diamondUpId
		self.limitDataId = limitId
		if self.limitIdHJ and not limitId then
			removeUnSchduleFunc(self.limitIdHJ)
			self.limitIdHJ = nil
			self.limitInitiative = true
		end
		if not diamondUpId then
			if self.limitIdHJ and self.limitlocation == 2 then
				removeUnSchduleFunc(self.limitlocation)
				self.limitlocation = nil
			elseif not self.limitIdHJ and self.limitlocation == 1 then
				removeUnSchduleFunc(self.limitlocation)
				self.limitlocation = nil
			elseif self.limitInitiative and self.limitlocation == 2 then
				removeUnSchduleFunc(1)
				self.limitlocation = nil
			end
		end
	end)

	idlereasy.any({self.curType,
		self.goldCount,
		self.diamondCount,
		self.allCount,
		self.halfDiamondCount,
		self.trainerGoldCount,
		self.equipCount,
		self.drawEquipCount,
		self.items,
		self.lastDrawTime,
		self.selfChooseNum,
	}, self:createHandler("initPageItem"))

	idlereasy.when(self.selfChooseNum, function(_, chooseNum)
		local data = {}
		local chooseupData = {}
		local function makeSelectPositive(num)
			return num == 0 and 1 or num
		end
		for k,v in csvMapPairs(csv.draw_card_up_group) do
			if  k == makeSelectPositive(chooseNum) then
				data = v.attrs
				break
			end
		end
		self.selfChooseCurrentUpData:update(data)
	end)

	idlereasy.any({self.rmb, self.gold}, self:createHandler("refreshCostText"))

	idlereasy.when(self.isCutDown, function(_, isCutDown)
		local cutTime = gCommonConfigCsv.drawGoldFreeRefreshDuration - (time.getTime() - self.lastDrawTime:read())
		if isCutDown and cutTime > 0 then
			self.time:set(cutTime)

		-- elseif self.curType:read() == TYPE_DEFINE.gold then
			-- self.time:set(0)
			-- local isFree = self.goldCount:read() < gCommonConfigCsv.drawGoldFreeLimit and cutTime <= 0
			-- self.isFree:set(isFree)
			-- self.isCost:set(not isFree)
			-- bind.extend(self, self.drawOnePanel, {
			-- 	class = "red_hint",
			-- 	props = {
			-- 		state = isFree,
			-- 		onNode = function (node)
			-- 			node:xy(410, 250)
			-- 				:z(10)
			-- 		end
			-- 	}
			-- })
		end
	end)

	idlereasy.when(self.equipAllCount, function(_, equipAllCount)
		local times = equipAllCount % DRAWEQUIPTIMES
		times = times == 0 and DRAWEQUIPTIMES or DRAWEQUIPTIMES - times
		local str = string.format(gLanguageCsv.drawLeftTime, times)
		if times == 1 then
			str = gLanguageCsv.curDrawHaveSprite
		end
		self.leftDrawTimes:set(str)
	end)

	idlereasy.any({self.vip, self.dcGoldCount}, function(_, vip, dcGoldCount)
		local allNum = gVipCsv[vip].goldDrawCardCountLimit
		self.goldAllTimes:text("/" .. allNum)
		local leftNum = allNum - (dcGoldCount or 0)
		self.goldLeftTimes:text(leftNum)
		local color = ui.COLORS.NORMAL.LIGHT_GREEN
		if leftNum <= 0 then
			color = ui.COLORS.NORMAL.ALERT_ORANGE
		end
		text.addEffect(self.goldLeftTimes, {color = color})
		adapt.oneLineCenterPos(cc.p(270, 40), {self.goldTextNote, self.goldLeftTimes, self.goldAllTimes}, cc.p(6, 0))
	end)

	self:enableSchedule():schedule(function (dt)
		if not self.isCutDown:read() then
			return
		end
		self.time:modify(function(oldval)
			local curval = oldval - 1
			if curval <= 0 then
				self.isCutDown:set(false)
				local isFree = self.goldCount:read() < gCommonConfigCsv.drawGoldFreeLimit
				self.isFree:set(isFree)
				self.isCost:set(not isFree)
				bind.extend(self, self.drawOnePanel, {
					class = "red_hint",
					props = {
						state = isFree,
						onNode = function (node)
							node:xy(410, 250)
								:z(10)
						end
					}
				})
			end
			return true, curval
		end)
	end, 1, 0)
	self.siteStateTab, self.diamondAwardTab, self.limitAwardTab = {}, {}, {}
	self.awardIdTabel = {}
	for k,v in orderCsvPairs(csv.draw_count) do
		if v.drawType == 2 then
			self.diamondAwardTab[k] = v
		elseif v.drawType == 1 then
			self.limitAwardTab[k] = v
		end
	end
	for i=1, 3 do
		self["livenessPoint"..i] = idler.new(0)
		self.siteStateTab[i] = 2
	end
	self:initAward()
end

function DrawCardView:initModel()
	self.vip = gGameModel.role:getIdler("vip_level")
	self.cardDatas = gGameModel.role:getIdler("cards")--卡牌
	self.cardCapacity = gGameModel.role:getIdler("card_capacity")--背包容量
	local dailyRecord = gGameModel.daily_record
	self.diamondCount = dailyRecord:getIdler("dc1_free_count") -- 钻石免费抽
	self.goldCount = dailyRecord:getIdler("gold1_free_count") -- 金币免费抽
	self.dcGoldCount = dailyRecord:getIdler("dc_gold_count") -- 金币抽卡次数
	self.allCount = dailyRecord:getIdler("draw_card") -- 总抽卡次数
	self.lastDrawTime = dailyRecord:getIdler("gold1_free_last_time") -- 免费金币抽取的时间
	self.halfDiamondCount = dailyRecord:getIdler("draw_card_rmb1_half") --半价
	self.trainerGoldCount = dailyRecord:getIdler("draw_card_gold1_trainer") --训练家特权次数
	self.equipCount = dailyRecord:getIdler("eq_dc1_free_counter") -- 装备免费单抽次数
	self.drawEquipCount = dailyRecord:getIdler("draw_equip") -- 抽装备次数
	local lotteryRecord = gGameModel.lottery_record

	self.selfChooseNum = lotteryRecord:getIdler("draw_card_up_choose")  -- 自选抽卡
	self.selfChooseTimes = lotteryRecord:getIdler("draw_card_up_change_times")
	self.selfChooseUp1Counters = lotteryRecord:getIdler("draw_card_up1_counters")
	self.selfChooseUp10Counters = lotteryRecord:getIdler("draw_card_up10_counters")

	self.diamondAllCount = lotteryRecord:getIdler("dc1_counter") -- 钻石单抽计数
	self.diamondAllCountTen = lotteryRecord:getIdler("dc10_counter") -- 钻石十连抽计数
	self.equipAllCount = lotteryRecord:getIdler("eq_dc1_counter") -- 饰品单抽计数
	self.yyhuodongCounters = lotteryRecord:getIdler("yyhuodong_counters") -- 活动抽卡计数
	self.rmb = gGameModel.role:getIdler("rmb")
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
	self.getDiamondAwardState = gGameModel.role:getIdler("draw_sum_box") --钻石宝箱领取状态(1可领取，2已领取)
	local yyOpen = gGameModel.role:read("yy_open")
	for i,v in ipairs(yyOpen) do
		if csv.yunying.yyhuodong[v].type == game.YYHUODONG_TYPE_ENUM_TABLE.timeLimitDraw then
			self.limitId:set(v)
		elseif csv.yunying.yyhuodong[v].type == game.YYHUODONG_TYPE_ENUM_TABLE.timeLimitUpDraw then
			self.diamondUpId:set(v)
		end
	end
end

-- 初始化页面相关的显示内容
function DrawCardView:initPageItem(_, curType, goldCount, diamondCount, allCount, half, trainerCount, equipCount, drawEquipCount)
	self:resetChildFuncs(curType)
	self.isHalf = false
	self.privilegePanel:hide()
	-- self.drawLeftText:hide()
	self.btnText:set(string.format(gLanguageCsv.drawTimes, 10))
	-- adapt.setTextScaleWithWidth(self.tenDrawText,self.tenDrawText:text(), self.drawTenPanel:width() - 70)
	self:initPageItemFunc(curType, goldCount, diamondCount, allCount, half, trainerCount, equipCount, drawEquipCount)

	-- 切换页签的时候也需要是刷新
	self:refreshCostText()
	-- idler 赋值，适配要延迟一帧
	performWithDelay(self, function()
		adapt.oneLineCenterPos(cc.p(172, 35), {self.costTextNote1, self.costOne, self.imgOne}, cc.p(6, 0))
		adapt.oneLineCenterPos(cc.p(172, 35), {self.costTextNote2, self.costTen, self.imgTen}, cc.p(6, 0))
		adapt.oneLinePos(self.costOne, self.imgOne, cc.p(6, 3), "left")
		adapt.oneLinePos(self.costTen, self.imgTen, cc.p(6, 3), "left")
		local childs = self.privilegePanel:multiget("line", "textNote", "imgIcon", "textCost", "textDiscount")
		adapt.oneLineCenterPos(cc.p(172, 35), {childs.textNote, childs.textCost, childs.textDiscount, childs.imgIcon}, cc.p(6, 0))
		adapt.oneLinePos(childs.textNote, childs.line, cc.p(6, 0), "left")
	end, 0)
end

-- 余额是否足够的判断
function DrawCardView:isEnoughToDraw(isTen)
	return self:isEnoughToDrawFunc(isTen)
end

-- 刷新按钮文字颜色等
function DrawCardView:refreshCostText()
	local oneCostColor, tenCostColor = ui.COLORS.NORMAL.RED, ui.COLORS.NORMAL.RED
	if self:isEnoughToDraw(true) then
		oneCostColor = ui.COLORS.NORMAL.WHITE
		tenCostColor = ui.COLORS.NORMAL.WHITE
	elseif self:isEnoughToDraw(false) then
		oneCostColor = ui.COLORS.NORMAL.WHITE
	end

	text.addEffect(self.costOne, {color=oneCostColor})
	text.addEffect(self.costTen, {color=tenCostColor})
end

function DrawCardView:initCardData(data, target, idx, ids)
	local iconPath = data["res" .. idx]
	local card = csv.cards[data["card" .. idx]]
	local unit = csv.unit[card.unitID]
	if not iconPath then
		iconPath = unit.cardShow
	end
	target:get("imgIcon"):texture(iconPath)
	target:get("imgIcon"):alignCenter(target:size())
	local x, y = target:get("imgIcon"):xy()
	local resPos = data["resPos" .. idx]
	target:get("imgIcon"):xy(x + resPos.x, y + resPos.y)
	target:get("imgIcon"):scale(data["resScale" .. idx])
	target:get("info.img2"):texture(data["posRes" .. idx])
	target:get("name.imgName"):texture(data["titleRes".. idx])
	local ratityPath = ui.RARITY_ICON[unit.rarity]
	target:get("name.imgIcon"):texture(ratityPath)
	adapt.oneLinePos(target:get("name.imgName"), target:get("name.imgIcon"), cc.p(6, 0), "right")
	table.insert(ids, data["card" .. idx])
	bind.touch(self, target:get("info.btnJump"), {methods = {ended = function()
		self:onjumpToHandBook(data["card" .. idx])
	end}})
end

-- 页面切换
function DrawCardView:onBtnClick(list, idx, data)
	self.tabDatas:atproxy(self.perIdx).isSel = false
	self.tabDatas:atproxy(idx).isSel = true
	self.perIdx = idx
	self.curType:set(data.type)
	self:initAward()
end

-- 单抽按钮
function DrawCardView:onDrawOneClick()
	local onceEnough = self:isEnoughToDraw(false)
	if not onceEnough and not self.isFree:read() then
		if self.curType:read() == TYPE_DEFINE.gold then
			uiEasy.showDialog("gold")
		else
			uiEasy.showDialog("rmb")
		end
		return
	end
	local curType = self.curType:read()
	if (curType == TYPE_DEFINE.diamond or curType == TYPE_DEFINE.limit or curType == TYPE_DEFINE.diamond_up or curType == TYPE_DEFINE.self_choose) and itertools.size(self.cardDatas:read()) >= self.cardCapacity:read() then
		gGameUI:showDialog{content = gLanguageCsv.cardBagHaveBeenFullDraw, cb = function()
			gGameUI:stackUI("city.card.bag", nil, {full = true})
		end, btnType = 2, clearFast = true}
		return
	end

	if not self.isFree:read() and curType == "gold" then
		local allNum = gVipCsv[self.vip:read()].goldDrawCardCountLimit
		local leftNum = allNum - (self.dcGoldCount:read() or 0)
		if leftNum < 1 then
			gGameUI:showTip(string.format(gLanguageCsv.leftTimesNotEnough, 1))
			return
		end
	end

	self:drawOneClickFunc()
end

-- 十连按钮
function DrawCardView:onDrawTenClick()
	local tenEnough = self:isEnoughToDraw(true)
	local curType = self.curType:read()
	if not tenEnough then
		if curType == "gold" then
			uiEasy.showDialog("gold")
		else
			uiEasy.showDialog("rmb")
		end
		return
	end
	if curType == TYPE_DEFINE.gold then
		local allNum = gVipCsv[self.vip:read()].goldDrawCardCountLimit
		local leftNum = allNum - (self.dcGoldCount:read() or 0)
		if leftNum < 10 then
			gGameUI:showTip(string.format(gLanguageCsv.leftTimesNotEnough, 10))
			return
		end
	end
	if (curType == TYPE_DEFINE.diamond or curType == TYPE_DEFINE.limit or curType == TYPE_DEFINE.diamond_up or curType == TYPE_DEFINE.self_choose) and self.cardCapacity:read() - itertools.size(self.cardDatas:read()) <= MAXLEFTCOUNTS then
		gGameUI:showDialog{content = gLanguageCsv.cardBagHaveBeenFullDraw, cb = function()
			gGameUI:stackUI("city.card.bag", nil, {full = true})
		end, btnType = 2, clearFast = true}
		return
	end

	self:drawTenClickFunc()
end

-- 商店按钮
function DrawCardView:onShopClick()
	jumpEasy.jumpTo("shop", 8)
end

function DrawCardView:addEffectInRect(resPath)
	local parent = self.imgBG
	parent:removeChildByName("effectBg")
	local efcBg = widget.addAnimationByKey(parent, resPath, "effectBg", "effect_loop", 999)
		:alignCenter(parent:size())
	return efcBg
end

-- 奖励预览
function DrawCardView:onPerviewClick()
	gGameUI:stackUI("city.drawcard.preview", nil, {blackLayer = true, clickClose = true}, self.curType:read())
end

function DrawCardView:onjumpToHandBook(cardId)
	gGameUI:stackUI("city.handbook.view", nil, {full = true}, {cardId = cardId})
end

function DrawCardView:onSwitchClick()
	gGameUI:stackUI("city.drawcard.select_property",nil, {blackLayer = true, clickClose = true}, self.selfChooseNum:read() or 1)
end

local DrawCardChildView = {
	[TYPE_DEFINE.diamond] = require "app.views.city.drawcard.diamond",
	[TYPE_DEFINE.gold] = require "app.views.city.drawcard.gold",
	[TYPE_DEFINE.equip] = require "app.views.city.drawcard.equip",
	[TYPE_DEFINE.limit] = require "app.views.city.drawcard.limit",
	[TYPE_DEFINE.diamond_up] = require "app.views.city.drawcard.diamond_up",
	[TYPE_DEFINE.self_choose] = require "app.views.city.drawcard.self_choose",
}

function DrawCardView:resetTopUIView(curType)
	if self.topView then
		gGameUI.topuiManager:removeView(self.topView)
		self.topView = nil
	end

	local tb = {
		[TYPE_DEFINE.diamond] = "rmb_card",
		[TYPE_DEFINE.gold] = "default",
		[TYPE_DEFINE.equip] = "equip_card",
		[TYPE_DEFINE.limit] = "limit_card",
		[TYPE_DEFINE.diamond_up] = "diamond_up_card",
		[TYPE_DEFINE.self_choose] = "diamond_up_card",
	}
	self.topView = gGameUI.topuiManager:createView(curType and tb[curType] or "default", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.drawCard, subTitle = "DRAW CARD"})
end

function DrawCardView:resetChildFuncs(curType)
	if self.lastCurType == curType then
		return
	end
	self.lastCurType = curType

	local tb = DrawCardChildView[curType]
 	for str, func in pairs(tb) do
		self[str] = func
	end

	self:resetTopUIView(curType)
	self.imgBG:removeAllChildren()
end

function DrawCardView:onAwardClick(idx)
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

--# 累计宝箱 self.diamondUpId 限定抽卡 self.rmblocation 钻石抽卡
function DrawCardView:initAward()
	local perIdx
	if self:judgeLimitOrSelfChooseDrawCard() then
		perIdx = 1
	elseif self.perIdx == self.rmblocation and dataEasy.isUnlock(gUnlockCsv.drawSumBox) then
		perIdx = 2
	end

	self.downPanel:visible(false)
	if perIdx then
		--初始化数据
		self.awardIdTabel = {}
		self.siteStateTab = {2, 2, 2}
		local diamondXS, getAwardState
		local limitNumber10, limitNumber1
		self.awardTab = {}
		local awardStateTab = {}
		local awardK, remainder = 0, 0
		local data, content, state
		--# 1限时 2钻石 stamps(1可领取，2已领取)
		local limitNumber = 0
		if perIdx == 1 then
			self.awardTab = self.limitAwardTab
			getAwardState = self.getDiamondAwardState:read()[1] or {}
			limitNumber = self:caculateLimitNum()
		elseif perIdx == 2 then
			self.awardTab = self.diamondAwardTab
			getAwardState = self.getDiamondAwardState:read()[2] or {}
			limitNumber10 = self.diamondAllCountTen:read() * 10
			limitNumber1 = self.diamondAllCount:read()
			limitNumber = limitNumber1 + limitNumber10
		end
		getAwardState = getAwardState or {}
		--# 根据宝箱信息初始话宝箱,i+1是可领取宝箱从item2开始的(有疑问可以看工程)
		--# stateTab是宝箱对应的纹理
		--# self.livenessPoint是进度条
		--# state是宝箱状态1是可领取，0是已领取切大于limitNumber也是可领取
		--# siteStateTab用来保存当前按下的宝箱的位置及信息,0已领取1可领取2未完成
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
				item:get("state"):texture(site == 3 and stateTab[6] or stateTab[1])
				self.siteStateTab[site] = 0

			elseif getAwardState[id] == 1 or number <= limitNumber then
				item:get("state"):texture(site == 3 and stateTab[5] or stateTab[2])
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
				item:get("state"):texture(site == 3 and stateTab[4] or stateTab[3])
			end
		end

		if csvSize(self.awardTab) >= 3 then
			local count = 0
			local maxId
			local showFirstId = nil
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
end

-- 判断是否是限定抽卡或者是自选属性抽卡，共用奖励界面
function DrawCardView:judgeLimitOrSelfChooseDrawCard()
	if (self.selfChooseLocation
		and self.perIdx == self.selfChooseLocation
		and dataEasy.isUnlock(gUnlockCsv.groupDrawCardUp))
		or
		(self.diamondUpId:read()
		and self.perIdx == self.limitlocation
		and dataEasy.isUnlock(gUnlockCsv.timeLimitUpDrawSumBox)) then
		return true
	else
		return false
	end
end

-- 计算限定抽卡和自选抽卡积分数
function DrawCardView:caculateLimitNum()
	local sum = self.yyhuodongCounters:read()[game.YYHUODONG_TYPE_ENUM_TABLE.timeLimitUpDraw] or 0
	local chooseUp1CountersTable = self.selfChooseUp1Counters:read()
	local chooseUp10CountersTable = self.selfChooseUp10Counters:read()
	local up1Num = 0
	local up10Num = 0
	if chooseUp1CountersTable then
		for k,v in pairs(chooseUp1CountersTable) do
			up1Num = up1Num + v
		end
	end
	if chooseUp10CountersTable then
		for k,v in pairs(chooseUp10CountersTable) do
			up10Num = up10Num + v
		end
	end
	sum = up1Num + 10 * up10Num + sum
	return sum
end

----------------------------等待子页面重写-----------------------------

-- 刷新页面信息显示
function DrawCardView:initPageItemFunc(curType, goldCount, diamondCount, allCount, half, trainerCount, equipCount, drawEquipCount)
end

-- 判断金币、钻石是否足够抽卡
function DrawCardView:isEnoughToDrawFunc(isTen)
end

-- 单抽
function DrawCardView:drawOneClickFunc()
end

-- 十连
function DrawCardView:drawTenClickFunc()
end

return DrawCardView
