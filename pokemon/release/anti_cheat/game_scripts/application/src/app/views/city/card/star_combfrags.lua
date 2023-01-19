
local function setIcon(list, node, key, num)
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
			},
		},
	}
	bind.extend(list, node, binds)
end
local TXT_TAB = {
	[1] = {txt = gLanguageCsv.change, spaceTxt = gLanguageCsv.spaceChange, success = gLanguageCsv.advanceSuccess},
	[2] = {txt = gLanguageCsv.comb, spaceTxt = gLanguageCsv.spaceComb, success = gLanguageCsv.combSuccess}
}

local ViewBase = cc.load("mvc").ViewBase
local fragmentComposeView = class("fragmentComposeView", Dialog)

fragmentComposeView.RESOURCE_FILENAME = "card_fragment_compose.json"
fragmentComposeView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["titleTxt"] = "title",
	["cardPanel"] = "cardPanel",
	["cardPanel.card1"] = "card1",
	["cardPanel.card2"] = "card2",
	["cardPanel.textName1"] = "textName1",
	["cardPanel.textName2"] = "textName2",
	["barPanel"] = "barPanel",
	["barPanel.myFrags"] = "myFrags",
	["barPanel.needFrags"] = "needFrags",
	["barPanel.bar"] = "slider",
	["barPanel.subBtn"] = {
		varname = "subBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, -1)
			end),
		},
	},
	["barPanel.addBtn"] = {
		varname = "addBtn",
		binds = {
			event = "touch",
			longtouch = true,
			method = bindHelper.defer(function(view, node, event)
				return view:onChangeNum(node, event, 1)
			end),
		},
	},
	["combTipPos"] = "combTipPos",
	["note"] = "needNumNote",
	["changeBtn"] = {
		varname = "changeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeClick")}
		}
	},
	["changeBtn.title"] = {
		varname = "btnTxt",
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
}
function fragmentComposeView:onCreate(selectDbId)
	self.selectDbId = selectDbId
	self:enableSchedule()

	self.selectNum = idler.new(0)
	local csvFragment = csv.fragments[self.selectDbId]
	idlereasy.when(self.selectNum, function(_, selectNum)
		local changeId, targetId = self.selectDbId, csvFragment.combID
		self.fragsId = targetId
		local changeCfg = dataEasy.getCfgByKey(changeId)
		local targetCfg = dataEasy.getCfgByKey(targetId)
		local changeNum = dataEasy.getNumByKey(changeId)
		self.targetNum = math.modf(selectNum/csvFragment.combCount)
		--可转换的最大数量
		self.canMaxNum = math.modf(changeNum/csvFragment.combCount)

		--设置滑动条
		if not self.slider:isHighlighted() then
			local num = math.ceil(selectNum/self.canMaxNum*100)
			self.slider:setPercent(num)
		end
		--卡牌合成数量提示
		local fragCsv = csv.fragments[targetId]
		--设置滑动条上边的显示数量
		self.needFrags:text("/"..self.canMaxNum)
		self.myFrags:text(selectNum)
		adapt.oneLineCenterPos(cc.p(self.barPanel:size().width/2, self.myFrags:y()), {self.myFrags, self.needFrags})
		self.textName1:text(changeCfg.name)
		self.textName2:text(targetCfg.name)
		text.addEffect(self.textName1, {color = ui.COLORS.QUALITY[changeCfg.quality]})
		text.addEffect(self.textName2, {color = ui.COLORS.QUALITY[targetCfg.quality]})
		--加减按钮
		uiEasy.setBtnShader(self.addBtn, nil, selectNum < self.canMaxNum and 1 or 2)
		uiEasy.setBtnShader(self.subBtn, nil, selectNum > 0 and 1 or 2)
		setIcon(self, self.card1, changeId, changeNum)
		setIcon(self, self.card2, targetId, selectNum)
		local name = ""
		if csvFragment.type == 4 then
			name = csv.held_item.items[targetId].name
		elseif csvFragment.type == 3 then
			name = csv.items[targetId].name
		end
		self.needNumNote:removeAllChildren()
		local fontSize = matchLanguage({"kr"}) and 30 or 34
		rich.createByStr(string.format(gLanguageCsv.fragmentComposeText, csvFragment.combCount, ui.QUALITYCOLOR[changeCfg.quality]..csvFragment.name, 1, ui.QUALITYCOLOR[targetCfg.quality]..name), fontSize, nil, nil)
			:addTo(self.needNumNote, 10)
			:anchorPoint(cc.p(0.5, 0.5))
			:xy(0,0)
			:formatText()
	end)

	self.slider:setPercent(0)
	self.slider:addEventListener(function(sender,eventType)
		self:unScheduleAll()
		local percent = sender:getPercent()
		local num = cc.clampf(math.ceil(self.canMaxNum * percent * 0.01), 0, self.canMaxNum)
		self.selectNum:set(num)
	end)
	Dialog.onCreate(self)
end

function fragmentComposeView:onChangeClick()
	if self.selectNum:read() == 0 then
		gGameUI:showTip(gLanguageCsv.pleaseSelectFragmentCombText)
		return
	end
	gGameApp:requestServer("/game/role/frag/comb/item",function (tb)
		ViewBase.onClose(self)
		gGameUI:showGainDisplay(tb)
	end, self.selectDbId, self.selectNum:read())
end

function fragmentComposeView:onChangeNum(node, event, step)
	if event.name == "click" then
		self:unScheduleAll()
		self:onIncreaseNum(step)

	elseif event.name == "began" then
		self:schedule(function()
			self:onIncreaseNum(step)
		end, 0.05, 0, 100)

	elseif event.name == "ended" or event.name == "cancelled" then
		self:unScheduleAll()
	end
end

function fragmentComposeView:onIncreaseNum(step)
	self.selectNum:modify(function(selectNum)
		return true, cc.clampf(selectNum + step, 0, self.canMaxNum)
	end)
end

return fragmentComposeView
