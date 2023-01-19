local ExploreDecomposeView = class("ExploreDecomposeView", Dialog)

local FONT_COLOR = {
	cc.c4b(153,153,153,255),
	cc.c4b(92,153,112,255),
	cc.c4b(61,138,153,255),
	cc.c4b(139,92,153,255),
	cc.c4b(229,153,0,255),

}
local function upgradeFloatingWord(panel, str, notNeed)
	local x, y = panel:xy()
	local advanceNum = cc.Label:createWithTTF(str, "font/youmi1.ttf", 40)
		:align(cc.p(0.5, 0.5), panel:size().width/2, panel:size().height/2 + 30)
		:addTo(panel, 11)
	text.addEffect(advanceNum, {color=cc.c4b(0, 255, 0,255), outline={color=cc.c4b(44,44,44,255), size=3}})
	transition.executeSequence(advanceNum)
		:moveBy(0.4, 0, 30)
		:fadeOut(0.1)
		:func(function ()
			advanceNum:removeSelf()
		end)
		:done()
	if not notNeed then
		if not panel.lvUpEffect then
			panel.lvUpEffect = widget.addAnimation(panel, "effect/jineng.skel", "effect", 10)
				:xy(90, 85)
				:scale(1.2)
		else
			panel.lvUpEffect:play("effect")
		end
		audio.playEffectWithWeekBGM("circle.mp3")
	end
end
ExploreDecomposeView.RESOURCE_FILENAME = "explore_decompose_view.json"
ExploreDecomposeView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["btnDecompose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDecompose")}
		}
	},
	["btnShop"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onShop")}
		}
	},
	["btnShop.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		},
	},
	["btnDecompose.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["item"] = "item",
	["subList"] = "subList",
	["leftList"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("subassemblys"),
				-- columnSize = bindHelper.self("midColumnSize"),
				dataOrderCmp = function (a, b)
					if a.cfg.sortType ~= b.cfg.sortType then
						return a.cfg.sortType > b.cfg.sortType
					end
					if a.cfg.sortValue ~= b.cfg.sortValue then
						return a.cfg.sortValue > b.cfg.sortValue
					end
					if a.cfg.quality ~= b.cfg.quality then
						return a.cfg.quality < b.cfg.quality
					end
					return a.id < b.id
				end,
				columnSize = 4,
				isRefresh = bindHelper.self("isRefresh"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local data = idlertable.new({
						key = v.id,
						num = v.num,
						targetNum = v.selected and v.targetNum,
					})
					list:enableSchedule()
					local function onIncreaseNum(step)
						local targetNum = data:proxy().targetNum or 0
						targetNum = cc.clampf(targetNum + step, 0, data:proxy().num)
						data:proxy().targetNum = targetNum ~= 0 and targetNum or nil

						v.targetNum = targetNum
						v.isRefresh:notify()
						if (targetNum + step) < 0 or (targetNum + step) > data:proxy().num then
							list:unSchedule("numChange")
						end
					end
					local touchBeganPos
					local function onChangeNum(panel, node, event, step, showTip)
						local targetNum = v.targetNum
						if touchBeganPos == nil then
							touchBeganPos = event
						end
						if event.name == "click" then
							list:unScheduleAll()
							if touchBeganPos and (targetNum < v.num or step < 0) then
								onIncreaseNum(step)
								upgradeFloatingWord(panel, showTip)
							end
							touchBeganPos = nil

						elseif event.name == "began" then
							if touchBeganPos then
								list:schedule(function(delta)
									if targetNum <= v.num then
										onIncreaseNum(step)
										upgradeFloatingWord(panel, showTip)
									end
								end, 0.1, 0, "numChange")
							end

						elseif event.name == "moved" then
							if touchBeganPos then
								local dx = math.abs(event.x - touchBeganPos.x)
								local dy = math.abs(event.y - touchBeganPos.y)
								if dx >= ui.TOUCH_MOVE_CANCAE_THRESHOLD or dy >= ui.TOUCH_MOVE_CANCAE_THRESHOLD then
									touchBeganPos = false
									list:unSchedule("numChange")
								end
							end

						elseif event.name == "ended" or event.name == "cancelled" then
							touchBeganPos = nil
							list:unSchedule("numChange")
						end
					end
					bind.extend(list, node, {
						class = "explore_icon",
						props = {
							data = data,
							longtouch = true,
							showReduce = true,
							onNode = function(panel)
								bind.touch(list, panel, {longtouch = 0.5, method = function(view, node, event)
									onChangeNum(panel, node, event, 1, "+1")
								end})
								bind.touch(list, panel:get("reduceIcon"), {longtouch = 0.5, method = function(view, node, event)
									onChangeNum(panel, node, event, -1, "-1")
								end})
							end,
						},
					})
				end,
			},
		},
	},
	["item1"] = "item1",
	["bottomList"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("bottomData"),
				item = bindHelper.self("item1"),
				padding = 25,
				margin = 15,
				onItem = function(list, node, k, v)
					local childs = node:multiget("bg", "name", "selected")
					childs.bg:texture(v.icon)
					childs.name:text(v.name)
					childs.selected:visible(v.selected == true)
					childs.bg:setTouchEnabled(true)
					text.addEffect(childs.name, {color = FONT_COLOR[v.quality]})
					bind.touch(list, childs.bg, {methods = {
						ended = functools.partial(list.clickCell, k, v.quality)
					}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onColorClick"),
			},
		},
	},
	["duckPanel"] = "duckPanel",
	["duckPanel.txt"] = "txtDuckPanel",
	["gainPanel.num"] = "decomposeTxt",
	["havePanel.num"] = "haveTxt",
	["gainPanel.txt"] = "gainTxt",
	["gainPanel.icon"] = "gainIcon",
	["havePanel"] = "havePanel",
	["rightIcon"] = "rightIcon"
}

function ExploreDecomposeView:onCreate(dbHandler)
	self:initModel()
	adapt.setTextAdaptWithSize(self.txtDuckPanel, {size = cc.size(300, 200), vertical = "center", horizontal = "center"})
	self.isRefresh = idler.new(false)
	self.components = dbHandler()
	self.subassemblys = idlers.newWithMap({})
	self.bottomData = idlers.newWithMap({
		-- {name = gLanguageCsv.whiteText, icon = "city/develop/explore/tag_1.png", quality = 1},
		{name = gLanguageCsv.greenText, icon = "city/develop/explore/tag_2.png", quality = 2},
		{name = gLanguageCsv.blueText, icon = "city/develop/explore/tag_3.png", quality = 3},
		{name = gLanguageCsv.purpleText, icon = "city/develop/explore/tag_4.png", quality = 4},
		{name = gLanguageCsv.orangeText, icon = "city/develop/explore/tag_5.png", quality = 5},
	})
	idlereasy.when(self.components, function (_, val)
		local t = {}
		for i,v in ipairs(val) do
			if v.count ~= 0 then
				local id = csv.explorer.component[v.id].itemID
				table.insert(t, {id = id, num = v.count, targetNum = 0, cfg = csv.items[id], isRefresh = self.isRefresh})
			end
		end
		dataEasy.tryCallFunc(self.leftList, "updatePreloadCenterIndex")
		self.subassemblys:update(t)
		self.duckPanel:visible(#t == 0)
	end)
	self.decomposeNum = idler.new(0)

	idlereasy.when(self.decomposeNum, function (_, val)
		self.decomposeTxt:text(val)
		adapt.oneLinePos(self.gainTxt, {self.decomposeTxt, self.gainIcon},cc.p(15, 0), "left")
	end)

	idlereasy.when(self.isRefresh, function ()
		local total = 0
		local newT = {}
		for i, v in self.subassemblys:ipairs() do
			if self.subassemblys:atproxy(i).targetNum and self.subassemblys:atproxy(i).targetNum > 0 then
				local key, num = csvNext(self.subassemblys:atproxy(i).cfg.specialArgsMap)
				total = total + num * self.subassemblys:atproxy(i).targetNum
			end
		end
		self.decomposeNum:set(total)
	end)
	idlereasy.when(self.coin4, function (_, val)
		self.haveTxt:text(val)
	end)

	-- 分解特效
	self.fenjie = widget.addAnimationByKey(self.rightIcon, "fenjie/xitelongdefaming.skel", 'fenjie', "act", 999)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(self.rightIcon:width()/2, 0)
	self.fenjie:setTimeScale(0)

	Dialog.onCreate(self)
end

function ExploreDecomposeView:initModel()
	self.items = gGameModel.role:getIdler("items")
	self.coin4 = gGameModel.role:getIdler("coin4")
end

function ExploreDecomposeView:onColorClick(list, k, quality)
	self.bottomData:atproxy(k).selected = not self.bottomData:atproxy(k).selected
	for i, v in self.subassemblys:ipairs() do
		if v:proxy().cfg.quality == quality then
			self.subassemblys:atproxy(i).selected = self.bottomData:atproxy(k).selected
			self.subassemblys:atproxy(i).targetNum = self.subassemblys:atproxy(i).selected and self.subassemblys:atproxy(i).num or 0
		end
	end
	local total = 0
	for i, v in self.subassemblys:ipairs() do
		if self.subassemblys:atproxy(i).targetNum and self.subassemblys:atproxy(i).targetNum > 0 then
			local key, num = csvNext(self.subassemblys:atproxy(i).cfg.specialArgsMap)
			total = total + num * self.subassemblys:atproxy(i).targetNum
		end
	end
	self.decomposeNum:set(total)
end

function ExploreDecomposeView:onDecompose()
	if self.decomposeNum:read() == 0 then
		gGameUI:showTip(gLanguageCsv.noChooseComponent)
		return
	end
	local t = {}
	local haveHigh = false
	for i, v in self.subassemblys:ipairs() do
		if self.subassemblys:atproxy(i).targetNum and self.subassemblys:atproxy(i).targetNum > 0 then
			t[self.subassemblys:atproxy(i).id] = self.subassemblys:atproxy(i).targetNum
			if self.subassemblys:atproxy(i).cfg.quality >= 4 and not haveHigh then
				haveHigh = true
			end
		end
	end

	if haveHigh then
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = gLanguageCsv.selectedHighQualityComponent, isRich = true, btnType = 2, cb = function ()
			self:onDecomposeRequest(t)
		end})
	else
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = string.format(gLanguageCsv.deComposeComponent, dataEasy.getIconResByKey("coin4"), self.decomposeNum:read()), isRich = true, btnType = 2, cb = function ()
			self:onDecomposeRequest(t)
		end})
	end
end

-- @desc 先播特效，再执行协议结果
function ExploreDecomposeView:onDecomposeRequest(param)
    local showOver = {false}
	gGameApp:requestServerCustom("/game/explorer/component/decompose")
		:params(param)
		:onResponse(function ()
			self.fenjie:setTimeScale(1)
			self.fenjie:play("act")
			audio.playEffectWithWeekBGM("tanxianqifj.mp3")
			performWithDelay(self, function ()
				showOver[1] = true
			end, 84/30)
		end)
		:wait(showOver)
		:doit(function (tb)
			gGameUI:showGainDisplay({{"coin4", self.decomposeNum:read()}}, {raw = false})
			self.decomposeNum:set(0)
		end)
end

function ExploreDecomposeView:onShop()
	if not gGameUI:goBackInStackUI("city.shop") then
		gGameApp:requestServer("/game/explorer/shop/get", function()
			gGameUI:stackUI("city.shop", nil, {full = true}, game.SHOP_INIT.EXPLORER_SHOP)
		end)
	end
end

return ExploreDecomposeView
