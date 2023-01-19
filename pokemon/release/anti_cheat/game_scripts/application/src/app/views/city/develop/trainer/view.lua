local TrainerView = class("TrainerView", cc.load("mvc").ViewBase)
local SKILL_STATE = {
	["NOT_OPEN"] = 0,
	["OPEN"] = 1
}
local ARROW_NOT_SHOW = {
	game.PRIVILEGE_TYPE.FirstRMBDrawCardHalf,
	game.PRIVILEGE_TYPE.BattleSkip,
	game.PRIVILEGE_TYPE.ExpItemCostFallRate,
	game.PRIVILEGE_TYPE.TrainerAttrSkills,
	game.PRIVILEGE_TYPE.GateSaoDangTimes,
	game.PRIVILEGE_TYPE.DrawItemFreeTimes,
	game.PRIVILEGE_TYPE.FirstRMBDrawItemHalf
}

local ADD_SHOW = {
	game.PRIVILEGE_TYPE.StaminaMax,
	game.PRIVILEGE_TYPE.StaminaBuyTimes,
	game.PRIVILEGE_TYPE.LianjinBuyTimes,
	game.PRIVILEGE_TYPE.DailyTaskExpRate,
	game.PRIVILEGE_TYPE.HuodongTypeGoldTimes,
	game.PRIVILEGE_TYPE.HuodongTypeExpTimes,
	game.PRIVILEGE_TYPE.ExpItemCostFallRate,
}

TrainerView.ADD_SHOW = ADD_SHOW

TrainerView.ARROW_NOT_SHOW = ARROW_NOT_SHOW
TrainerView.RESOURCE_FILENAME = "trainer_view.json"
TrainerView.RESOURCE_BINDING = {
	["item"] = "item",
	["topList"] = {
		varname = "topList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("topData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local panel = node:get("panel")
					panel:visible(v.isNil ~= true)
					if not v.originY then
						v.originY = panel:y()
					end
					local childs = panel:multiget("name", "left", "right", "icon", "subName", "iconMask", "btnBox", "lock", "btnUp", "lockPanel")
					childs.iconMask:hide()
					if v.isBig then
						panel:scale(1)
						panel:setCascadeOpacityEnabled(true)
						panel:setOpacity(255)
						panel:y(v.originY)
					else
						panel:scale(0.9)
						panel:setCascadeOpacityEnabled(true)
						panel:setOpacity(230)
						panel:y(v.originY - 30)
					end
					if not v.isNil then
						childs.name:text(v.cfg.name)
						adapt.oneLineCenter(childs.name, childs.left, childs.right, cc.p(20, 0))
						childs.icon:hide()
						local size = panel:size()
						-- 特效文件分两个1-6为第一个，7-12为第二个
						local skelName = v.id < 7 and "1_6" or "7_12"
						widget.addAnimationByKey(panel, "kapai/kapai"..skelName..".skel", "iconSpine", tostring(v.id).."_loop", 2)
							:xy(size.width/2, size.height/2 - 20)

						childs.subName:hide()
						if v.level then
							local boxCanOpen = v.level == v.id and not v.isGet
							childs.btnBox:visible(boxCanOpen)
							childs.btnBox:get("icon"):texture(v.isGet and "common/icon/icon_box1_open.png" or "common/icon/icon_box1.png")
							if panel:get("spine") then
								panel:get("spine"):removeFromParent()
							end
							if boxCanOpen then
								local effect = widget.addAnimationByKey(panel, "effect/jiedianjiangli.skel", "spine", "effect_loop", 3)
								effect:scale(0.5)
									:xy(panel:size().width - 80, 80)
							end
							uiEasy.addVibrateToNode(list,childs.btnBox,boxCanOpen, node:getName()..k.."vibrate")
							text.addEffect(childs.btnBox:get("txt"), {outline = {color = ui.COLORS.OUTLINE.WHITE}})
							if not v.unLock then
								cache.setShader(panel:get("iconSpine"), false, v.level < v.id and "hsl_gray" or "normal")

								panel:get("iconSpine"):setTimeScale(v.level < v.id and 0 or 1)
								childs.lock:visible(v.level < v.id)
							else
								itertools.invoke({childs.lock}, "hide")
								local spine = widget.addAnimation(childs.lockPanel, "xunlianshi1/xunblianshi1.skel", "jiesuo", 100)
									:xy(childs.lockPanel:size().width/2, childs.lockPanel:size().height/2)
							end
						end
					end
					if v.isUp == true and v.upShow then
						v.spine = widget.addAnimation(node, "xunlianshi1/xunblianshi1.skel", "jinjieup_loop", 100)
							:xy(300,290)
					else
						if v.spine then
							v.spine:removeSelf()
							v.spine = nil
						end
					end
					if v.isUp == true and v.upShow and v.upTouchEnabled then
						childs.btnUp:setTouchEnabled(true)
					else
						childs.btnUp:setTouchEnabled(false)
					end
					bind.touch(list, childs.btnUp, {methods = {
						ended = functools.partial(list.clickUp, v)
					}})
					bind.touch(list, childs.btnBox, {methods = {
						ended = functools.partial(list.clickBox, v)
					}})

				end,
				asyncPreload = 3,
				preloadCenter = bindHelper.self("topCenter"),
			},
			handlers = {
				clickUp = bindHelper.self("onItemUpClick"),
				clickBox = bindHelper.self("onItemBoxClick"),
			},
		},
	},
	["panel"] = "panel",
	["mask"] = "mask",
	["btnLeft"] = {
		varname = "btnLeft",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onLeftClick")}
			},
		},
	},
	["btnRight"] = {
		varname = "btnRight",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onRightClick")}
			},
		},
	},
	["btnAttr"] = {
		varname = "btnAttr",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onAttrClick")}
			},
		},
	},
	["btnAttr.txt"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}}
			},
		}
	},
	["btnNext.txt"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}}
			},
		}
	},
	["btnNext.txt1"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}}
			},
		}
	},
	["btnNext"] = {
		varname = "btnNext",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onAttrNextClick")}
			},
		},
	},
	["slider"] = {
		varname = "slider",
		binds = {
			event = "extend",
			class = "loadingbar",
			props = {
				data = bindHelper.self("barPoint"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		}
	},
	["sliderBg"] = "sliderBg",
	["exp"] = "exp",
	["txt"] = "txt",
	["totalExp"] = "totalExp",
	["centerTip.txt"] = "centerTxt",
	["centerTip.num"] = "centerNum",
	["centerTip.bg"] = "centerBg",
	["centerTip.arrow"] = "centerArrow",
	["txt1"] = "coinTxt",
	["num"] = "coinNum",
	["icon"] = "coinIcon",
	["btnDetail"] = {
		varname = "coinDetail",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onCoinDetail")}
			},
		},
	},
	["item2"] = "item2",
	["bottomList"] = {
		varname = "bottomList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("bottomData"),
				item = bindHelper.self("item2"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local cfg = csv.trainer.skills[v.id]
					local childs = node:multiget("icon", "name", "desc", "desc1", "lv", "btnUp", "flag")
					childs.name:text(cfg.name)
					childs.icon:texture(cfg.icon)
						:scale(2)
					childs.desc:text(cfg.desc1..":")
					childs.desc1:text(cfg.desc2)
					if matchLanguage({"cn", "tw", "kr"}) then
						adapt.oneLinePos(childs.desc, childs.desc1)
					elseif matchLanguage({"en"}) then
						adapt.oneLinePos(childs.desc, childs.desc1, cc.p(-5, 0))
						adapt.oneLinePos(childs.desc1, childs.desc, cc.p(0, 0), "right")
					end
					if v.level then
						childs.lv:text("Lv"..v.level.."/Lv"..cfg.levelMax)
						local state = v.state == SKILL_STATE.NOT_OPEN
						childs.flag:text(state and gLanguageCsv.notOpen or gLanguageCsv.levelMax)
						text.addEffect(childs.flag, {color = state and cc.c4b(179, 172, 152, 255) or cc.c4b(255, 111, 89, 255)})
						childs.btnUp:visible(not state and (v.level < cfg.levelMax))
						local nextLevel = math.min(v.level == 0 and 1 or v.level, cfg.levelMax)
						local value = cfg.nums[nextLevel]
						local isPercent = string.find(tostring(value), ".", 1, true) ~= nil
						if isPercent then
							value = value * 100
						end
						childs.desc1:text(string.format(cfg.desc2, value)..(isPercent and "%" or ""))
					end
					text.addEffect(childs.btnUp:get("txt"), {glow = {color = ui.COLORS.GLOW.WHITE}})
					bind.touch(list, childs.btnUp, {methods = {
						ended = functools.partial(list.clickCell, v)
					}})
				end,

				onAfterBuild = function (list)
					list:setTouchEnabled(#list.data > 3)
				end
			},
			handlers = {
				clickCell = bindHelper.self("onBottomItemClick"),
			},
		},
	},
}
function TrainerView:onCreate()
	self:initModel()
	gGameUI.topuiManager:createView("default", self, {onClose = self:createHandler("onClose")})
				:init({title = gLanguageCsv.training, subTitle = "Trainer"})
	local t = {}
	table.insert(t, {isNil = true})
	for i,v in orderCsvPairs(csv.trainer.trainer_level) do
		table.insert(t, {cfg = v, id = i, upShow = i ~= csvSize(csv.trainer.trainer_level)})
	end
	local jinjiedownEffect = widget.addAnimation(self.panel, "xunlianshi1/xunblianshi1.skel", "jinjiedown_loop", 100)
		:xy(self.panel:size().width/2, self.panel:size().height/2)
	--再加一个放置的空位
	self.barPoint = idler.new(0)
	table.insert(t, {isNil = true})
	self.topCenter = idler.new(self.trainerLevel:read() + 1)
	self.topData = idlers.newWithMap(t)
	self.bottomData = idlers.newWithMap({})
	local beginX
	local function scrollDirection(sender, eventType)
		if eventType == ccui.TouchEventType.began then
			beginX = sender:getTouchBeganPosition().x
		elseif eventType == ccui.TouchEventType.ended then
			local endX = sender:getTouchEndPosition().x
			local isScroll = math.abs(endX - beginX) > 5
			if isScroll then
				if endX > beginX then
					self.topCenter:set(self.topCenter:read() > 2 and self.topCenter:read() - 1 or 2)
				else
					self.topCenter:set(self.topCenter:read() <= self.topData:size() - 2 and self.topCenter:read() + 1 or self.topData:size() - 1)
				end
			end
		end
	end
	idlereasy.any({self.topCenter, self.trainerLevel}, function (_, index, level)
		local t = {}
		for i,v in ipairs(self.topData:atproxy(index).cfg.skills) do
			table.insert(t, {id = v, level = self.trainerSkills:read()[v] or 0, state = level + 1 >= index and SKILL_STATE.OPEN or SKILL_STATE.NOT_OPEN})
		end
		local lvLimit = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.TrainerAttrSkills)
		local lock = self.btnNext:get("lock")
		lock:visible(lvLimit == 0)
		self.btnNext:visible(csv.trainer.trainer_level[level].isShowNext == 1)
		jinjiedownEffect:visible(self.topData:atproxy(index).id <= level) 	-- 未解锁冒险通行证不发光
		self.bottomData:update(t)
	end)

	idlereasy.when(self.trainerSkills, function (_, skills)
		local t = {}
		for i,v in ipairs(self.topData:atproxy(self.topCenter:read()).cfg.skills) do
			self.bottomData:atproxy(i).level = skills[v] or 0
		end
	end)

	self.topCenter:addListener(function (val, oldval)
		self.topData:atproxy(oldval).upTouchEnabled = false
		self.topData:atproxy(val).upTouchEnabled = true
	end)
	self.oldLevel = 0
	idlereasy.any({self.topCenter, self.trainerLevel}, function (_, val, level)
		self.btnLeft:visible(val ~= 2)
		self.btnRight:visible(val ~= self.topData:size() - 1)
		self.topList:jumpToItem(val, cc.p(1, 0), cc.p(1, 0))
		for i,v in self.topData:pairs() do
			v:proxy().isBig = i == val
		end
		local key, value = csvNext(self.topData:atproxy(val).cfg.privilege)
		if not string.find(tostring(value), ".", 1, true) then
			self.centerNum:text((itertools.first(ADD_SHOW, key) ~= nil and "+" or "")..value)
		else
			self.centerNum:text((itertools.first(ADD_SHOW, key) ~= nil and key ~= game.PRIVILEGE_TYPE.ExpItemCostFallRate and "+" or "")..(value * 100).."%")
		end
		local str = ""
		if key == game.PRIVILEGE_TYPE.BattleSkip then
			local name = gLanguageCsv[game.SCENE_TYPE_STRING_TABLE[value]]
			str = string.format(gLanguageCsv["trainerPrivilege"..key], name)
		elseif key == game.PRIVILEGE_TYPE.GateSaoDangTimes or key == game.PRIVILEGE_TYPE.DrawItemFreeTimes then
			-- local addNum = math.max(dataEasy.getPrivilegeVal(key), value)
			str = string.format(gLanguageCsv["trainerPrivilege"..key], value)
		else
			str = gLanguageCsv["trainerPrivilege"..key]
		end
		self.centerTxt:text(str)
		local width = 0
		if key ~= 1 then
			width = width + self.centerNum:size().width
		end
		if itertools.first(ARROW_NOT_SHOW, key) then
			self.centerArrow:hide()
			if key == game.PRIVILEGE_TYPE.ExpItemCostFallRate then
				self.centerNum:show()
			else
				self.centerNum:hide()
			end
		else
			self.centerArrow:show()
			self.centerNum:show()
			width = width + self.centerArrow:getBoundingBox().width
		end
		width = width + self.centerTxt:size().width

		local size = self.centerBg:size()
		self.centerBg:size(width + 200, size.height)
		local x = self.centerBg:x()
		self.centerTxt:x(x - (width - 200)/2 - 20)
		adapt.oneLinePos(self.centerTxt, {self.centerNum, self.centerArrow})
		self.bottomList:jumpToLeft()
		if val == level + 1  then
			local maxLevel = csvSize(csv.trainer.trainer_level)
			local nextLevel = math.min(level + 1, maxLevel)
			local totalExp = csv.trainer.trainer_level[nextLevel].needExp
			if self.trainerLevelExp:read() >= totalExp or maxLevel == level then
				self.totalExp:hide()
			else
				self.totalExp:show()
			end
			itertools.invoke({self.sliderBg, self.slider, self.exp, self.txt}, "show")
		else
			itertools.invoke({self.sliderBg, self.slider, self.exp, self.totalExp, self.txt}, "hide")
		end
		adapt.oneLinePos(self.exp, self.totalExp)
	end)

	idlereasy.any({self.trainerLevel, self.trainerLevelExp, self.trainerGiftTimes}, function (_, level, currExp, times)
		local maxLevel = csvSize(csv.trainer.trainer_level)
		local nextLevel = math.min(level + 1, maxLevel)
		local totalExp = csv.trainer.trainer_level[nextLevel].needExp
		if level == maxLevel then
			self.barPoint:set(100)
			self.exp:text(gLanguageCsv.advanceMax)
			self.totalExp:hide()
		else
			if currExp >= totalExp then
				self.exp:text(gLanguageCsv.advanceAdd)
				self.totalExp:hide()
				self.barPoint:set(100)
				self.topCenter:set(level + 1)
			else
				self.barPoint:set(currExp / totalExp * 100)
				self.totalExp:show()
				self.exp:text(currExp)

				self.totalExp:text("/"..totalExp)
			end
		end
		for i,v in self.topData:pairs() do
			v:proxy().level = level
			if v:proxy().id == level then
				v:proxy().isUp = currExp >= totalExp
			else
				v:proxy().isUp = false
			end
			v:proxy().isGet = times > 0
		end
		if self.oldLevel ~= 0 then
			if self.topCenter:read() == level + 1 and self.oldLevel + 1 == level then
				--显示进度条。。
				itertools.invoke({self.sliderBg, self.slider, self.exp, self.txt}, "show")
			else
				itertools.invoke({self.sliderBg, self.slider, self.exp, self.totalExp, self.txt}, "hide")
			end
		end
		adapt.oneLinePos(self.exp, self.totalExp)
	end)
	self.mask:addTouchEventListener(function(sender, eventType)
		scrollDirection(sender, eventType)
	end)
	idlereasy.when(self.items, function (_, val)
		self.coinNum:text(val[453] or 0)
		adapt.oneLinePos(self.coinTxt, {self.coinNum, self.coinIcon, self.coinDetail}, cc.p(15, 0))
	end)
	local state = userDefault.getCurrDayKey("trainerBoxShow", false)
	local isFirst = userDefault.getForeverLocalKey("trainerFirstEnter", false)
	if not isFirst then
		performWithDelay(self, function ()
			gGameUI:stackUI("city.develop.trainer.success", nil, nil, 0, self:createHandler("topCenter"))
			userDefault.setForeverLocalKey("trainerFirstEnter", true)
		end, 0.01)
		return
	end
	if not state and self.trainerGiftTimes:read() == 0 then
		performWithDelay(self, function ()
			self:onItemBoxClick(nil, self.topData:atproxy(self.trainerLevel:read() + 1))
		end, 0.01)
	end
end

function TrainerView:initModel()
	self.trainerLevel = gGameModel.role:getIdler("trainer_level")
	self.trainerLevelExp = gGameModel.role:getIdler("trainer_level_exp")
	self.trainerSumExp = gGameModel.role:getIdler("trainer_sum_exp")
	self.trainerSkills = gGameModel.role:getIdler("trainer_skills")
	self.trainerAttrSkills = gGameModel.role:getIdler("trainer_attr_skills")
	self.items = gGameModel.role:getIdler("items")
	self.trainerGiftTimes = gGameModel.daily_record:getIdler("trainer_gift_times")
end

function TrainerView:onLeftClick()
	self.topCenter:modify(function (val)
		return true, val - 1
	end)
end

function TrainerView:onRightClick()
	self.topCenter:modify(function (val)
		return true, val + 1
	end)
end

function TrainerView:onBottomItemClick(list, v)
	gGameUI:stackUI("city.develop.trainer.skill_upgrade", nil, nil, v)
end

function TrainerView:onAttrNextClick()
	if dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.TrainerAttrSkills) == 0 then
		local level
		for i = 1, csvSize(csv.trainer.trainer_level) do
			local privilege, val = csvNext(csv.trainer.trainer_level[i].privilege)
			if privilege == game.PRIVILEGE_TYPE.TrainerAttrSkills then
				level = i
				break
			end
		end
		gGameUI:showTip(string.format(gLanguageCsv.trainerUnlockSkill, csv.trainer.trainer_level[level].name))
		return
	end
	gGameUI:stackUI("city.develop.trainer.attr_skills")
end

function TrainerView:onAttrClick()
	gGameUI:stackUI("city.develop.trainer.attr", nil, nil, self:createHandler("sendParams"))
end

function TrainerView:sendParams()
	return self.topData:atproxy(self.trainerLevel:read() + 1)
end

function TrainerView:onItemUpClick(list, v)
	self.oldLevel = v.level
	self.topData:atproxy(self.oldLevel + 1).unLock = false
	gGameApp:requestServer("/game/trainer/advance",function (tb)
		local newCenter = self.oldLevel + 2
		self.topData:atproxy(newCenter).unLock = true
		performWithDelay(self, function ()
			gGameUI:stackUI("city.develop.trainer.success", nil, nil, self.oldLevel, self:createHandler("topCenter"))
			self.topData:atproxy(newCenter).unLock = false
		end, 1)
	end)
end

function TrainerView:onItemBoxClick(list, v)
	local params = {
		data =  v.cfg.dailyAward,
		content = "",
		title = gLanguageCsv.dailyReward,
		state = self.trainerGiftTimes:read() > 0 and 0 or 1,
		btnText = self.trainerGiftTimes:read() == 0 and gLanguageCsv.spaceReceive or gLanguageCsv.received,
		clearFast = true,
		cb = function ()
			gGameApp:requestServer("/game/trainer/daily/award", function (tb)
				userDefault.setCurrDayKey("trainerBoxShow", true)
				gGameUI:showGainDisplay(tb)
			end)
		end
	}
	gGameUI:showBoxDetail(params)
end

function TrainerView:onCoinDetail()
    gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function TrainerView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(string.format(gLanguageCsv.brackets, gLanguageCsv.trainerCoin))
		end),
		c.noteText(66001, 66004),
	}
	return context
end

return TrainerView