
--端午粽子活动主界面
local ActivityView = require "app.views.city.activity.view"

local itemAnima = {"shicai_move_2", "shicai_move_3", "shicai_move_1"}
local iconAnima = {"shicai_move_6", "shicai_move_5", "shicai_move_4"}

local ViewBase = cc.load("mvc").ViewBase
local DuanWuView = class("DuanWuView", ViewBase)

DuanWuView.RESOURCE_FILENAME = "activity_duanwu.json"
DuanWuView.RESOURCE_BINDING = {
	["panel"] = "panel",
	["panel.achievement"] = {
		varname = "achievement",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("achievementFunc")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "zongZiAward",
					listenData = {
						activityId = bindHelper.self("activityID"),
					},
				}
			}
		}
	},
	["panel.rule"] = {
		varname = "rule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("ruleFunc")}
		},
	},
	["panel.use"] = {
		varname = "use",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("zongZiUse")}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "zongziUnused",
					activityId = bindHelper.self("activityID"),
					onNode = function(node)
						node:xy(100, 105)
					end,
				}
			}
		}
	},
	["panel.btn"] = {
		varname = "zongZiBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("btnClick")}
		},
	},
	["panel.make"] = {
		varname = "speedUse",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("speedUseClick")}
		},
	},
	["panel.timeTxt"] = {
		varname = "timeTxt",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.DEFAULT}}
		},
	},
	["panel.time"] = {
		varname = "time",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.NORMAL.DEFAULT}}
		},
	},
	["panel.hintTxt"] = "hintTxt",
	["panel.plate"] = "plate",
	["panel.icon1"] = "icon1",
	["panel.icon2"] = "icon2",
	["panel.icon3"] = "icon3",
	["panel.item1"] = "item1",
	["panel.item2"] = "item2",
	["panel.item3"] = "item3",
	["panel.panel"] = "animaPanel",
}

DuanWuView.RESOURCE_STYLES = {
	full = true,
}


function DuanWuView:onCreate(activityID)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.duanWuheadline, subTitle = "ACTIVITY"})

	self.animaBg = widget.addAnimation(self.panel, "duanwuzongzi/dwj_bzz.skel", "effect_loop", 1)
		:alignCenter(self.panel:size())
		:scale(2)

	local zongziTab = {}
	self.zongziDataId = {}
	local huodongID = csv.yunying.yyhuodong[activityID].huodongID
	for i,v in orderCsvPairs(csv.yunying.bao_zongzi_recipe) do
		if v.huodongID == huodongID then
			local itemZ, _ = csvNext(v.mainItem)
			local itemF, _ = csvNext(v.minorItem)
			local item, _ = csvNext(v.compoundItem)
			if not zongziTab[itemZ] then
				zongziTab[itemZ] = {}
			end
			if not self.zongziDataId[itemZ] then
				self.zongziDataId[itemZ] = {}
			end
			self.zongziDataId[itemZ][itemF] = i
			zongziTab[itemZ][itemF] = item
		end
	end

	self.activityID = activityID
	self.zongziData = {}

	local stapleData = {6352, 6353, 6354}
	local nonStapleData = {6355, 6356, 6357}
	for i=1, 3 do
		text.addEffect(self["item" .. i]:get("itemTxt"), {outline={color=cc.c4b(129, 75, 36, 255)}})
		text.addEffect(self["icon" .. i]:get("iconTxt"), {outline={color=cc.c4b(129, 75, 36, 255)}})
	end
	text.addEffect(self.achievement:get("txt"), {outline={color=cc.c4b(129, 75, 36, 255)}})
	text.addEffect(self.rule:get("txt"), {outline={color=cc.c4b(129, 75, 36, 255)}})
	text.addEffect(self.use:get("txt"), {outline={color=cc.c4b(129, 75, 36, 255)}})
	text.addEffect(self.speedUse:get("txt"), {outline={color=cc.c4b(129, 75, 36, 255)}})
	text.addEffect(self.hintTxt, {outline={color=cc.c4b(129, 75, 36, 255)}})

	self.timeOver = true
	self:timeUpdata(activityID)
	-- ActivityView.setCountdown(self, activityID, self.timeTxt, self.time)
	self.timeTxt:x(self.time:x() - self.time:width() - 25)

	self.plate:get("icon"):visible(false)
	self.plate:get("item"):visible(false)

	local textRed = cc.c4b(255, 79, 100, 255)
	idlereasy.when(gGameModel.role:getIdler("items"), function(_, items)
		for i=1, 3 do
			local str1, str2 = string.format(gLanguageCsv.possessIngredient, 0), string.format(gLanguageCsv.possessIngredient, 0)
			local color1, color2 = textRed, textRed
			local info1, info2 = false, false
			if items[stapleData[i]] then
				str1 = string.format(gLanguageCsv.possessIngredient, items[stapleData[i]])
				color1 = ui.COLORS.NORMAL.WHITE
				info1 = true
			end
			self["icon" .. i]:get("iconTxt"):text(str1)
			self["icon" .. i]:get("iconTxt"):color(color1)
			self["icon" .. i]:get("icon"):visible(info1)

			if items[nonStapleData[i]] then
				str2 = string.format(gLanguageCsv.possessIngredient, items[nonStapleData[i]])
				color2 = ui.COLORS.NORMAL.WHITE
				info2 = true
			end
			self["item" .. i]:get("itemTxt"):text(str2)
			self["item" .. i]:get("itemTxt"):color(color2)
			self["item" .. i]:get("item"):visible(info2)
		end
	end)
	self.hintTxt:text(gLanguageCsv.clickAddZongzi)
	self.itemPostion1 = {}
	self.itemPostion2 = {}
	self.itemAnimaData = {}

	for i=1, 3 do
		self.itemPostion1[i] = {x = self["icon" .. i]:get("icon"):x(), y = self["icon" .. i]:get("icon"):y()}
		self.itemPostion2[i] = {x = self["item" .. i]:get("item"):x(), y = self["item" .. i]:get("item"):y()}
		self["icon" .. i]:onClick(function()
			if not self.timeOver then
				gGameUI:showTip(gLanguageCsv.activityOver)
				return
			end
			local itemsData = gGameModel.role:read("items")
			if itemsData[stapleData[i]] then
				self.zongziData[1] = stapleData[i]
				self.plate:get("icon"):visible(false)
			else
				gGameUI:showTip(string.format(gLanguageCsv.noItems, csv.items[stapleData[i]].name))
			end
			local info = false
			if self.zongziData[1] then
				self.plate:get("icon"):texture(csv.items[self.zongziData[1]].icon)
				if self.itemAnimaData[2] then
					self.itemAnimaData[2]:removeFromParent()
					self.itemAnimaData[2] = nil
				end
				self.itemAnimaData[2] = self:animaFunc(self["icon" .. i]:get("icon"), "xian_move_1", self.zongziData[1])
				info = true
				if self.zongziData[2] then
					local id = zongziTab[self.zongziData[1]][self.zongziData[2]]
					self.hintTxt:text(string.format(gLanguageCsv.obtainZongZi, csv.items[id].name))
				end
			end
		end)
		self["item" .. i]:onClick(function()
			if not self.timeOver then
				gGameUI:showTip(gLanguageCsv.activityOver)
				return
			end
			local itemsData = gGameModel.role:read("items")
			if itemsData[nonStapleData[i]] then
				self.zongziData[2] = nonStapleData[i]
				self.plate:get("item"):visible(false)
			else
				gGameUI:showTip(string.format(gLanguageCsv.noItems, csv.items[nonStapleData[i]].name))
			end
			local info = false
			if self.zongziData[2] then
				if self.itemAnimaData[1] then
					self.itemAnimaData[1]:removeFromParent()
					self.itemAnimaData[1] = nil
				end
				self.itemAnimaData[1] = self:animaFunc(self["item" .. i]:get("item"), "xian_move_2", self.zongziData[2])
				self.plate:get("item"):texture(csv.items[self.zongziData[2]].icon)
				info = true
				if self.zongziData[1] then
					local id = zongziTab[self.zongziData[1]][self.zongziData[2]]
					self.hintTxt:text(string.format(gLanguageCsv.obtainZongZi, csv.items[id].name))
				end
			end
		end)
	end
end

function DuanWuView:timeUpdata(id)
	self:enableSchedule():unSchedule(1)
	local cfg = csv.yunying.yyhuodong[id]
	local extraStr = ""
	if cfg.countType == 0 then
		extraStr = gLanguageCsv.activityDaily
	end
	local countdown = 0
	local yyEndtime = gGameModel.role:read("yy_endtime")
	if yyEndtime[id] then
		countdown = yyEndtime[id] - time.getTime()
	end
	local function setLabel()
		if countdown <= 0 then
			self.timeOver = false
			self.timeTxt:text(gLanguageCsv.activityOver)
			self.time:text("")
		else
			self.timeTxt:text(gLanguageCsv.activityLeftTime)
			self.time:text(time.getCutDown(countdown).str .. extraStr)
		end
	end
	setLabel()
	self:schedule(function()
		countdown = countdown - 1
		setLabel()
		if countdown <= 0 then
			return false
		end
	end, 1, 1, 1)
end

--成就
function DuanWuView:achievementFunc()
	if not self.timeOver then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end
	gGameUI:stackUI("city.activity.duan_wu_festival.proficiency_award", nil, nil, self.activityID)
end

--粽子使用
function DuanWuView:zongZiUse()
	if not self.timeOver then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end
	gGameUI:stackUI("city.activity.duan_wu_festival.zongzi_select", nil, nil, self.activityID)
end


function DuanWuView:animaFunc(node, name, id)
	local ndoes = node:clone():show()
	ndoes:addTo(self.animaPanel, 10)
	if id then
		ndoes:texture(csv.items[id].icon)
	end
	local action = cc.RepeatForever:create(cc.Sequence:create(
		cc.CallFunc:create(function()
			local posx, posy = self.animaBg:getPosition()
			local sx, sy = self.animaBg:getScaleX(), self.animaBg:getScaleY()
			local bxy = self.animaBg:getBonePosition(name)
			local rotation = self.animaBg:getBoneRotation(name)
			local scaleX = self.animaBg:getBoneScaleX(name)
			local scaleY = self.animaBg:getBoneScaleY(name)
			ndoes:rotate(-rotation)
				:scaleX(scaleX)
				:scaleY(scaleY)
				:xy(cc.p(bxy.x * sx + posx, bxy.y * sy + posy))
		end)
	))
	ndoes:runAction(action)
	if self.animaData then
		table.insert(self.animaData, ndoes)
	end
	return ndoes
end

--制作
function DuanWuView:btnClick(selfct, datas)
	if not self.timeOver then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end
	local data = {}
	self.animaData = {}
	if selfct ~= "speedMake" then
		if csvSize(self.zongziData) ~= 2 then
			gGameUI:showTip(gLanguageCsv.zongZiFabrication)
			return
		end
		self.hintTxt:visible(false)
		local csvId = self.zongziDataId[self.zongziData[1]][self.zongziData[2]]
		data[csvId] = 1
		self.animaBg:play("effect_solo_hou")
		self.anima = widget.addAnimation(self.animaPanel, "duanwuzongzi/dwj_bzz.skel", "effect_solo_qian", 3)
			:alignCenter(self.animaPanel:size())
			:scale(2)
	else
		self.hintTxt:visible(false)
		data = datas
		self.animaBg:play("kuaisu_effect")
		performWithDelay(self, function()
			for i=1, 3 do
				self["item" .. i]:get("item"):runAction(cc.Sequence:create(
						cc.MoveTo:create(0.5, cc.p(self["item"..i]:get("item"):x(), self["item"..i]:get("item"):y() + 750)),
						cc.MoveTo:create(0.6, cc.p(self["item"..i]:get("item"):x(), self["item"..i]:get("item"):y() - 50))
					))
				self["icon" .. i]:get("icon"):runAction(cc.Sequence:create(
						cc.MoveTo:create(0.5, cc.p(self["icon" .. i]:get("icon"):x(), self["icon" .. i]:get("icon"):y() + 750)),
						cc.MoveTo:create(0.6, cc.p(self["icon" .. i]:get("icon"):x(), self["icon" .. i]:get("icon"):y() - 50))
					))
			end
			performWithDelay(self, function()
				local anima1, anima2
				for i=1, 3 do
					self:animaFunc(self["item" .. i]:get("item"), itemAnima[i])
					self:animaFunc(self["icon" .. i]:get("icon"), iconAnima[i])
					self["item" .. i]:visible(false)
					self["icon" .. i]:visible(false)
				end
			end, 0.9)
		end, 0.8)
	end
	self.zongZiBtn:visible(false)
	gGameUI:goBackInStackUI("city.activity.duan_wu_festival.view")
	local showOver = {false}
	gGameApp:requestServerCustom("/game/yy/bao/zongzi")
		:params(self.activityID, data)
		:onResponse(function (tb)
			performWithDelay(self, function()
				showOver[1] = true
				self.zongziData = {}
				self.hintTxt:text(gLanguageCsv.clickAddZongzi)
				self.animaBg:play("effect_loop")
				self.hintTxt:visible(true)
				if self.anima then
					self.anima:removeFromParent()
					self.anima = nil
					if self.itemAnimaData[1] then
						self.itemAnimaData[1]:removeFromParent()
					end
					if self.itemAnimaData[2] then
						self.itemAnimaData[2]:removeFromParent()
					end
					self.itemAnimaData = {}
				
				else
					for i=1, 3 do
						self["item" .. i]:visible(true)
						self["item" .. i]:get("item"):xy(cc.p(self.itemPostion2[i].x, self.itemPostion2[i].y))
						self["icon" .. i]:visible(true)
						self["icon" .. i]:get("icon"):xy(cc.p(self.itemPostion1[i].x, self.itemPostion1[i].y))
					end
				end
				for i,node in pairs(self.animaData) do
					if node then
						node:removeFromParent()
					end
				end
				self.zongZiBtn:visible(true)
			end, 3.7)
		end)
		:wait(showOver)
		:doit(function (tb)
			gGameUI:showGainDisplay(tb)
		end)
end

--快速制作
function DuanWuView:speedUseClick()
	if not self.timeOver then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end
	self.plate:get("icon"):visible(false)
	self.plate:get("item"):visible(false)
	if self.itemAnimaData[1] then
		self.itemAnimaData[1]:removeFromParent()
		self.itemAnimaData[1] = nil
	end
	if self.itemAnimaData[2] then
		self.itemAnimaData[2]:removeFromParent()
		self.itemAnimaData[2] = nil
	end
	self.hintTxt:text(gLanguageCsv.clickAddZongzi)
	self.zongziData = {}
	gGameUI:stackUI("city.activity.duan_wu_festival.speed_fabrication", nil, nil, self.activityID, self:createHandler("btnClick"))
end

function DuanWuView:ruleFunc()
	if not self.timeOver then
		gGameUI:showTip(gLanguageCsv.activityOver)
		return
	end
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1300})
end

function DuanWuView:getRuleContext(view)
	local content = {92001, 92005}
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.duanWuheadline)
		end),
		c.noteText(unpack(content)),
	}
	return context
end

return DuanWuView
