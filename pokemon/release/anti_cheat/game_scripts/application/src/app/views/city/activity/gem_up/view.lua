

local function createForeverAnim(x, y)
	return cc.RepeatForever:create(
		cc.Sequence:create(
			cc.MoveTo:create(1, cc.p(x, y + 30)),
			cc.MoveTo:create(1, cc.p(x, y - 30))
		)
	)
end

local ActivityView = require "app.views.city.activity.view"
local GemUpView = class("GemUpView", Dialog)

GemUpView.RESOURCE_FILENAME = "activity_gem.json"
GemUpView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["replacement"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("replacement")}
		},
	},
	["replacement.txt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.ORANGE}}
		},
	},
	["txt"] = "timeTxt",
	["time"] = {
		varname = "time",
		binds = {
			event = "effect",
			data = {outline={color=cc.c4b(139, 47, 28, 255), size = 2}}
		}
	},
	["resolvePanel"] = {
		varname = "resolvePanel",
		binds = {
			event = "click",
			method = bindHelper.self("resolveGem"),
		},

	},
	["imgBg"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("awardBrowse")}
		},
	},
	["extract1.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.BLUE}},
		}
	},
	["extract2.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.ORANGE}},
		}
	},
	["extract1"] = {
		varname = "drawOnePanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onDrawClick(1)
			end)}
		},
	},
	["extract2"] = {
		varname = "drawTenPanel",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.defer(function(view)
				view:onDrawClick(10)
			end)}
		},
	},
	["iconBg"] = "iconBg",
	["iconBg.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleShow")}
		},
	},
	["bg"] = "bg",
	["item1"] = "item1",
	["item2"] = "item2",
	["item3"] = "item3",
	["iconTxt1"] = "iconTxt1",
	["iconTxt2"] = "iconTxt2",
	["iconTxt3"] = "iconTxt3",
	["icon1"] = "icon1",
	["icon2"] = "icon2",
	["icon3"] = "icon3",
	["freePanel"] = "freePanel",
	["bgAnima"] = "bgAnima",
}

function GemUpView:onCreate(activityID)
	self.drawOnePanel:get("textFree"):visible(false)
	self.activityID = activityID
	local state = userDefault.getForeverLocalKey('gemUpReplacement', false)
	self.resolvePanel:get("icon"):visible(state)
	if matchLanguage({"en"}) then
		adapt.setTextAdaptWithSize(self.resolvePanel:get("title"),
		{size = cc.size(400, 120), vertical = "center", horizontal = "left", margin = 0, maxLine= 2})
	end
	self.whetherResolve = state and 1 or 0
	self.timeTxt:text(string.format("%02d:00", time.getRefreshHour()))
	self:initModel()
	--倒计时
	self:setCountdown(activityID)

	self.bg:visible(false)

	local animaBg = widget.addAnimation(self.bgAnima, "fushichouqu/fwxd.skel", "effect_loop", 10)
		:alignCenter(self.bgAnima:size())
		:scale(2)
	local animaHint = widget.addAnimation(self.bgAnima, "fushichouqu/fwxd_wz.skel", "effect_loop", 20)
		:alignCenter(self.bgAnima:size())
		:scale(2)
	--免费抽取
	idlereasy.when(gGameModel.daily_record:getIdler("limit_up_gem_free_count"), function(_, dailyRecord)
		if dailyRecord == 0 then
			self.freePanel:get("txt"):text(gLanguageCsv.freeCount)
			self.freePanel:get("time"):text(1 .. "/" .. 1)
		end
		self.freePanel:visible(dailyRecord == 0)
		self.drawOnePanel:get("icon"):visible(dailyRecord ~= 0)
		self.freePanel:get("icon"):visible(dailyRecord ~= 0)
		self.drawOnePanel:get("textFree"):visible(dailyRecord == 0)
		self.drawOnePanel:get("txt1"):visible(dailyRecord ~= 0)
		self.drawOnePanel:get("num"):visible(dailyRecord ~= 0)
	end)
	local yyhuodongData = csv.yunying.yyhuodong[activityID]
	--抽卡次数上限
	self.numUp = yyhuodongData.paramMap.drawLimit
	local clientParam = yyhuodongData.clientParam.up
	self.rmbDown = yyhuodongData.paramMap.RMB1
	self.rmbUp = yyhuodongData.paramMap.RMB10
	self.drawOnePanel:get("num"):text(self.rmbDown)
	adapt.oneLinePos(self.drawOnePanel:get("num"), self.drawOnePanel:get("icon"), cc.p(10, 0), "left")
	self.drawTenPanel:get("num"):text(self.rmbUp)
	adapt.oneLinePos(self.drawTenPanel:get("num"), self.drawTenPanel:get("icon"), cc.p(10, 0), "left")
	for i=1, 3 do
		if clientParam[i] then
			self["item" .. i]:get("gem"):texture(ui.GEM_SUIT_ICON[clientParam[i]])
			self["iconTxt" .. i]:text(gLanguageCsv['gemSuit' .. clientParam[i]])
		else
			self.item2:x(self.item2:x() + 260)
			self.iconTxt2:x(self.iconTxt2:x() + 260)
			self.item1:x(self.item1:x() + 180)
			self.iconTxt1:x(self.iconTxt1:x() + 180)
			self["item" .. i]:visible(false)
			self["iconTxt" .. i]:visible(false)
		end
		if csvSize(clientParam) == 2 then
			if i == 1 then
				self.item1:runAction(createForeverAnim(self.item1:x() + 180, self.item1:y()))
				widget.addAnimation(self.icon1, "fushichouqu/fwxd_hezi.skel", "effect_loop", 10)
					:xy(720, 375)
					:scale(2)
			elseif i == 2 then
				self.item2:runAction(createForeverAnim(self.item2:x() + 260, self.item1:y()))
				widget.addAnimation(self.icon2, "fushichouqu/fwxd_hezi.skel", "effect_loop", 10)
					:xy(790,375)
					:scale(2)
			end
		else
			self["item" .. i]:runAction(createForeverAnim(self["item" .. i]:x(), self.item1:y()))
			widget.addAnimation(self["icon" .. i], "fushichouqu/fwxd_hezi.skel", "effect_loop", 10)
				:xy(530,375)
				:scale(2)
		end
	end

	idlereasy.when(gGameModel.role:getIdler("rmb"), function()
		self:textColor()
	end)

	idlereasy.when(self.yyhuodongs, function(_, yyhuodongs)
		local num = 0
		if yyhuodongs[activityID] and yyhuodongs[activityID].info.draw_counter then
			num = yyhuodongs[activityID].info.draw_counter
		end
		self.iconBg:get("num"):text(num .. "/" .. self.numUp)
		adapt.oneLinePos(self.iconBg:get("num"), self.iconBg:get("btn"), cc.p(10, 0), "left")
	end)

	Dialog.onCreate(self, {blackType = 1})
end

function GemUpView:setCountdown(id)
	self:enableSchedule()
	local cfg = csv.yunying.yyhuodong[id]
	local countdown = 0
	local yyEndtime = gGameModel.role:read("yy_endtime")
	if yyEndtime[id] then
		countdown = yyEndtime[id] - time.getTime()
	end
	bind.extend(self, self.time, {
		class = 'cutdown_label',
		props = {
			time = countdown,
			endFunc = function()
				self.time:text(gLanguageCsv.activityOver)
			end,
		}
	})
end

function GemUpView:initModel()
	self.yyhuodongs = gGameModel.role:getIdler('yyhuodongs')
end

function GemUpView:replacement()
	gGameUI:stackUI("city.activity.gem_up.gem_replacement", nil, nil, self.activityID)
end

--蓝色及以下品质自动分解是否选中
function GemUpView:resolveGem()
	local state = userDefault.getForeverLocalKey('gemUpReplacement', false)
	userDefault.setForeverLocalKey('gemUpReplacement', not state)
	self.resolvePanel:get("icon"):visible(not state)
	self.whetherResolve = not state and 1 or 0
end

function GemUpView:awardBrowse()
	gGameUI:stackUI('city.card.gem.preview', nil, {blackLayer = true, clickClose = true}, self.activityID)
end

--抽卡
function GemUpView:drawRequest(rmbNum, cb)
	local dailyRecord = gGameModel.daily_record:read("limit_up_gem_free_count")
	local num = 0
	if self.yyhuodongs:read()[self.activityID] and self.yyhuodongs:read()[self.activityID].info.draw_counter then
		num = self.yyhuodongs:read()[self.activityID].info.draw_counter
	end
	local rmb = rmbNum == 1 and self.rmbDown or self.rmbUp
	if rmbNum == 10 or (dailyRecord == 1 and rmbNum == 1) then
		if rmbNum == 10 and self.numUp == num then
			gGameUI:showTip(gLanguageCsv.gemDrawLimit)
			return
		elseif rmbNum == 10 and (self.numUp - num <= 9 and self.numUp - num >= 1)  then
			gGameUI:showTip(string.format(gLanguageCsv.leftTimesNotEnough, 10))
			return
		elseif rmbNum == 1 and self.numUp == num then
			gGameUI:showTip(gLanguageCsv.gemDrawLimit)
			return
		end
		if gGameModel.role:read("rmb") < rmb then
			uiEasy.showDialog("rmb")
			return
		end
	end

	local free
	if rmbNum == 1 then
		free = dailyRecord == 0 and 'limit_up_gem_free1' or 'limit_up_gem_rmb1'
	else
		free = 'limit_up_gem_rmb10'
	end

	local function cb1()
		gGameApp:requestServerCustom("/game/yy/limit/gem/draw")
			:onErrCall(function(err)
				if gLanguageCsv[err.err] then
					gGameUI:showTip(gLanguageCsv[err.err])
				end
			end)
			:params(self.activityID, free, self.whetherResolve)
			:doit(function(tb)
				local data = {}
				for _, v in pairs(tb.view.items) do
					local t = {key = v[1], num = v[2]}
					if v[3] then
						t = {key = v[3], num = 1, decomposed = {key = v[1], num = v[2]}}
					end
					table.insert(data, t)
				end
				self:textColor()
				cb(random.shuffle(data))
			end)
	end
	if free == 'limit_up_gem_rmb10' or free ==  'limit_up_gem_rmb1' then
		dataEasy.sureUsingDiamonds(cb1, rmb)
	else
		cb1()
	end
end

function GemUpView:onDrawClick(rmbNum)
	local rmb = rmbNum == 1 and self.rmbDown or self.rmbUp
	self:drawRequest(rmbNum, function(data)
		gGameUI:stackUI('city.card.gem.result', nil, nil, data, 'rmb', rmbNum, rmb, 531, self:createHandler('drawRequest'), true)
	end)
end

function GemUpView:textColor()
	local color1, color2 = ui.COLORS.NORMAL.WHITE, ui.COLORS.RED
	if gGameModel.role:read("rmb") < self.rmbDown then
		self.drawOnePanel:get("num"):color(color2)
		self.drawTenPanel:get("num"):color(color2)
	elseif gGameModel.role:read("rmb") < self.rmbUp and gGameModel.role:read("rmb") >= self.rmbDown then
		self.drawOnePanel:get("num"):color(color1)
		self.drawTenPanel:get("num"):color(color2)
	elseif gGameModel.role:read("rmb") >= self.rmbUp then
		self.drawOnePanel:get("num"):color(color1)
		self.drawTenPanel:get("num"):color(color1)
	end
end

function GemUpView:onRuleShow()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function GemUpView:getRuleContext(view)
	local content = {90001, 90003}
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.gemUpExtract)
		end),
		c.noteText(unpack(content)),
	}
	return context
end

return GemUpView