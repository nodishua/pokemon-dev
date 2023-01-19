local TrainAttrSkills = class("TrainAttrSkills", Dialog)
local coin = 453
TrainAttrSkills.RESOURCE_FILENAME = "trainer_attr_skills.json"
TrainAttrSkills.RESOURCE_BINDING = {
	["item"] = "item",
	["item2"] = "item2",
	["panel"] = "panel",
	["slider"] = "slider",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("item"),
				sliderBg = bindHelper.self("slider"),
				item2 = bindHelper.self("item2"),
				panel = bindHelper.self("panel"),
				padding = 0,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local panel = node:get("panel")
					local childs = panel:multiget("dark", "light", "lock", "attrName", "percent", "lv", "num", "icon", "btnSub", "btnAdd", "txtPanel")
					childs.dark:visible(k % 2 == 0)
					childs.light:visible(k % 2 == 1)
					childs.attrName:text(v.cfg.name)
					childs.lock:visible(v.isLockLevel or v.isLockTotalLevel)
					adapt.oneLinePos(childs.attrName, childs.lock)
					if v.dummyLevel then
						local val = dataEasy.getAttrValueString(v.cfg.attrType1, v.cfg.attrValue)
						local num, numType = dataEasy.parsePercentStr(val)
						childs.percent:text("+" .. dataEasy.getPercentStr(num, numType, v.dummyLevel))
						local color = v.dummyLevel ~= v.originLevel and ui.COLORS.QUALITY[2] or ui.COLORS.NORMAL.DEFAULT
						text.addEffect(childs.percent, {color = color})
						if v.cfg.levelMax ~= -1 or (v.cfg.levelMax == -1 and v.dummyLevel >= 0) then
							childs.lv:text(v.cfg.levelMax == -1 and v.dummyLevel or v.dummyLevel.."/"..v.cfg.levelMax)
						end
						text.addEffect(childs.lv, {color = color})
						local costId, cost = csvNext(v.cfg.upCost)
						childs.num:text(cost)
						adapt.oneLinePos(childs.num, childs.icon)
					end
					if v.isLockLevel or v.isLockTotalLevel then
						--锁了朋友
						childs.txtPanel:show()
						childs.percent:hide()
						childs.lv:hide()
						cache.setShader(childs.btnSub, false, "hsl_gray")
						cache.setShader(childs.btnAdd, false, "hsl_gray")
						text.addEffect(childs.attrName, {color = cc.c4b(121,114,116,153)})
						text.addEffect(childs.num, {color = cc.c4b(121,114,116,153)})
						local cur = childs.txtPanel:multiget("txt1", "txt2", "txt3")
						if v.cfg.totalAttrLevel == 0 then
							--第二个
							cur.txt3:text(string.format(gLanguageCsv.levelUpgradeToTrainer, csv.trainer.trainer_level[v.cfg.trainerLevel].name))
							cur.txt3:show()
							itertools.invoke({cur.txt1, cur.txt2}, "hide")
						else
							cur.txt3:hide()
							cur.txt1:text("1."..string.format(gLanguageCsv.levelUpgradeToTrainer, csv.trainer.trainer_level[v.cfg.trainerLevel].name))
							text.addEffect(cur.txt1, {color = v.isLockLevel and ui.COLORS.NORMAL.RED or ui.COLORS.QUALITY[2]})
							cur.txt2:text("2."..string.format(gLanguageCsv.trainerSkillTotal, v.cfg.totalAttrLevel, v.totalLevel, v.cfg.totalAttrLevel))
							text.addEffect(cur.txt2, {color = v.isLockTotalLevel and ui.COLORS.NORMAL.RED or ui.COLORS.QUALITY[2]})
							itertools.invoke({cur.txt1, cur.txt2}, "show")
						end
					else
						childs.lv:show()
						cache.setShader(childs.btnSub, false, "normal")
						cache.setShader(childs.btnAdd, false, "normal")
						text.addEffect(childs.attrName, {color = ui.COLORS.NORMAL.DEFAULT})
						text.addEffect(childs.num, {color = ui.COLORS.NORMAL.DEFAULT})
						childs.txtPanel:hide()
						childs.percent:show()
					end
					childs.btnSub:onTouch(functools.partial(list.clickSub, node, k, v))
					childs.btnAdd:onTouch(functools.partial(list.clickAdd, node, k, v))
				end,
				onBeforeBuild = function(list)
					list:insertCustomItem(list.item2:clone(), 0)
					if list.sliderBg:visible() then
						list.sliderShow = true
						list.sliderBg:hide()
					end
					list:setScrollBarEnabled(false)

				end,
				onAfterBuild = function(list)
					if list.sliderShow then
						list.sliderBg:show()
						list.sliderShow = false
					end
					local listSize = list:size()
					local x, y = list.sliderBg:xy()
					local size = list.sliderBg:size()
					local pos = gGameUI:getConvertPos(list)
					list:setScrollBarEnabled(true)
					list:setScrollBarColor(cc.c3b(241, 59, 84))
					list:setScrollBarOpacity(255)
					list:setScrollBarAutoHideEnabled(false)
					list:setScrollBarPositionFromCorner(cc.p(pos.x + listSize.width - x, (listSize.height - size.height) / 2 + 5))
					list:setScrollBarWidth(size.width)
					list:refreshView()
				end,
				asyncPreload = 6,
			},
			handlers = {
				clickAdd = bindHelper.self("onItemAddClick"),
				clickSub = bindHelper.self("onItemSubClick"),
			},
		},
	},
	["txt5"] = "txt5",
	["num"] = "coinNum",
	["icon"] = "coinIcon",
	["btnSure"] = {
		varname = "btnSure",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onSureClick")}
			},
		},
	},
	["btnReset"] = {
		varname = "btnReset",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onResetClick")}
			},
		},
	},
	["btnClear"] = {
		varname = "btnClear",
		binds = {
			{
				event = "touch",
				methods = {ended = bindHelper.self("onClearClick")}
			},
		},
	},
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
}

function TrainAttrSkills:onCreate()
	self:initModel()
	local t = {}
	for i,v in orderCsvPairs(csv.trainer.attr_skills) do
		table.insert(t, {id = i, cfg = v, isLockLevel = false, isLockTotalLevel = false, originLevel = 0})
	end
	self.attrDatas = idlers.newWithMap(t)
	self.clear = idler.new(true)
	uiEasy.addTabListClipping(self.list, self.panel, {
		mask = "city/develop/train/bg_zz.png",
		rect = cc.rect(15, 133, 1, 1),
	})

	self.totalNum = dataEasy.getNumByKey(coin)
	self.listIndex = idlertable.new({})
	idlereasy.any({self.trainerLevel, self.trainerAttrSkills, self.clear}, function (_, level, skills)
		local totalLevel = 0
		for k,v in pairs(skills) do
			totalLevel = totalLevel + v
		end
		for i,v in self.attrDatas:pairs() do
			local proxy = v:proxy()
			proxy.originLevel = skills[proxy.id] or 0
			proxy.dummyLevel = skills[proxy.id] or 0
			proxy.isLockLevel = level < proxy.cfg.trainerLevel
			proxy.isLockTotalLevel = totalLevel < proxy.cfg.totalAttrLevel
			proxy.totalLevel = totalLevel
		end
		adapt.oneLinePos(self.coinIcon, self.btnReset)
	end)

	idlereasy.any({self.items, self.listIndex}, function (_, val, indexs)
		local total = 0
		for k,v in pairs(indexs) do
			local costId, cost = csvNext(csv.trainer.attr_skills[k].upCost)
			total = total + cost * v
		end
		local cost = val[coin] or 0
		cost = cost - total
		self.totalNum = cost
		self.coinNum:text(cost)
		adapt.oneLinePos(self.txt5, {self.coinNum, self.coinIcon})
	end)
	Dialog.onCreate(self)
end

function TrainAttrSkills:initModel()
	self.trainerLevel = gGameModel.role:getIdler("trainer_level")
	self.trainerAttrSkills = gGameModel.role:getIdler("trainer_attr_skills")
	self.items = gGameModel.role:getIdler("items")
	self.rmb = gGameModel.role:getIdler("rmb")
end

function TrainAttrSkills:onItemAddClick(list, node, k, v, event)
	if v.isLockLevel or v.isLockTotalLevel then
		if event.name == "ended" or event.name == "cancelled" then
			gGameUI:showTip(gLanguageCsv.noConditionNoGrade)
		end
		return
	end
	local proxy = self.attrDatas:atproxy(k)
	local costId, cost = csvNext(proxy.cfg.upCost)
	if event.name == "began" then
		local time = 0.3
		local speed = 0.6
		self.notMoved = true
		self.touchBeganPos = event
		self:enableSchedule():schedule(function (dt)
			if time <= 0 then
				speed = (speed <= 0.2) and 0.2 or (speed - 0.2)
				if proxy.dummyLevel == proxy.cfg.levelMax then
					gGameUI:showTip(gLanguageCsv.levelMax)
					return false
				end
				if self.totalNum < cost then
					gGameUI:showTip(gLanguageCsv.trainerCointNotEnough)
					return false
				end
				proxy.dummyLevel = proxy.dummyLevel + 1
				local diff = proxy.dummyLevel - proxy.originLevel
				self.listIndex:modify(function (val)
					if diff > 0 then
						val[proxy.id] = diff
					else
						val[proxy.id] = nil
					end
					return true, val
				end, true)
				self.notMoved = false
			end
			time = time - dt
		end, 0.1, 0, "levelAdd")
	elseif event.name == "moved" then
		local pos = event
		local deltaX = math.abs(pos.x - self.touchBeganPos.x)
		local deltaY = math.abs(pos.y - self.touchBeganPos.y)
		if deltaX >= ui.TOUCH_MOVE_CANCAE_THRESHOLD or deltaY >= ui.TOUCH_MOVE_CANCAE_THRESHOLD then
			self.notMoved = false
			self:unSchedule("levelAdd")
		end
	elseif event.name == "ended" or event.name == "cancelled" then
		self:unSchedule("levelAdd")
		if self.notMoved then
			if proxy.dummyLevel == proxy.cfg.levelMax then
				gGameUI:showTip(gLanguageCsv.levelMax)
				return
			end
			if self.totalNum < cost then
				gGameUI:showTip(gLanguageCsv.trainerCointNotEnough)
				return
			end
			proxy.dummyLevel = proxy.dummyLevel + 1
			local diff = proxy.dummyLevel - proxy.originLevel
			self.listIndex:modify(function (val)
				if diff > 0 then
					val[proxy.id] = diff
				else
					val[proxy.id] = nil
				end
				return true, val
			end, true)
		end
	end
end

function TrainAttrSkills:onItemSubClick(list, node, k, v, event)
	if v.isLockLevel or v.isLockTotalLevel then
		gGameUI:showTip(gLanguageCsv.noConditionNoGrade)
		return
	end
	local proxy = self.attrDatas:atproxy(k)
	if event.name == "began" then
		local time = 0.3
		local speed = 0.6
		self.notMoved = true
		self.touchBeganPos = event
		self:enableSchedule():schedule(function (dt)
			if time <= 0 then
				speed = (speed <= 0.2) and 0.2 or (speed - 0.2)
				if proxy.dummyLevel == proxy.originLevel then
					return false
				end
				proxy.dummyLevel = proxy.dummyLevel - 1
				local diff = proxy.dummyLevel - proxy.originLevel
				self.listIndex:modify(function (val)
					if diff > 0 then
						val[proxy.id] = diff
					else
						val[proxy.id] = nil
					end
					return true, val
				end, true)
				self.notMoved = false
			end
			time = time - dt
		end, 0.1, 0, "levelSub")
	elseif event.name == "moved" then
		local pos = event
		local deltaX = math.abs(pos.x - self.touchBeganPos.x)
		local deltaY = math.abs(pos.y - self.touchBeganPos.y)
		if deltaX >= ui.TOUCH_MOVE_CANCAE_THRESHOLD or deltaY >= ui.TOUCH_MOVE_CANCAE_THRESHOLD then
			self.notMoved = false
			self:unSchedule("levelSub")
		end
	elseif event.name == "ended" or event.name == "cancelled" then
		self:unSchedule("levelSub")
		if self.notMoved then
			if proxy.dummyLevel == proxy.originLevel then
				return
			end
			proxy.dummyLevel = proxy.dummyLevel - 1
			local diff = proxy.dummyLevel - proxy.originLevel
			self.listIndex:modify(function (val)
				if diff > 0 then
					val[proxy.id] = diff
				else
					val[proxy.id] = nil
				end
				return true, val
			end, true)
		end
	end
end

function TrainAttrSkills:onClearClick()
	self.clear:set(true, true)
	self.listIndex:set({})
end

function TrainAttrSkills:onResetClick()
	if itertools.size(self.trainerAttrSkills:read()) == 0 then
		gGameUI:showTip(gLanguageCsv.noAttrReset)
		return
	end
	local str = string.format(gLanguageCsv.traineraaResetNote, gCommonConfigCsv.trainerAttrSkillsResetRMB)
	local params = {
		content = str,
		cb = function()
			if self.rmb:read() < gCommonConfigCsv.trainerAttrSkillsResetRMB then
				uiEasy.showDialog("rmb")
				return
			end
			gGameApp:requestServer("/game/trainer/attr_skill/reset")
		end,
		btnType = 2,
		isRich = true,
		clearFast = true,
	}
	gGameUI:showDialog(params)

end

function TrainAttrSkills:onSureClick()
	if self.listIndex:size() == 0 then
		return
	end
	gGameApp:requestServer("/game/trainer/attr_skill/levelup",function (tb)
		gGameUI:showTip(gLanguageCsv.updateSuccessfully)
		self.totalNum = dataEasy.getNumByKey(coin)
		self.listIndex:set({})
	end, self.listIndex:read())
end

return TrainAttrSkills
