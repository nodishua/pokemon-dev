
local RebirthTools = require "app.views.city.card.rebirth.tools"
local GemDecomposeView = class("GemDecomposeView", Dialog)

local FONT_COLOR = ui.COLORS.QUALITY

local isDbidSave = {}
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
			panel.lvUpEffect = widget.addAnimation(panel, "effect/gonghuixunlian.skel", "fangguang", 10)
				:xy(100, 5)
				:scale(1)
		else
			panel.lvUpEffect:play("fangguang")
		end
		audio.playEffectWithWeekBGM("circle.mp3")
	end
end
GemDecomposeView.RESOURCE_FILENAME = "gem_resolve.json"
GemDecomposeView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["acquire2.btn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDecompose")}
		}
	},
	["acquire2.btn.txt"] = {
		binds = {
			event = 'text',
			data = gLanguageCsv.decomposeText
		}
	},
	["item"] = "item",
	["lineList"] = "lineList",
	["list"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("subassemblys"),
				dataOrderCmp = function (a, b)
					if a.cfg.quality ~= b.cfg.quality then
						return a.cfg.quality < b.cfg.quality
					end
					if a.level ~= b.level then
						return a.level < b.level
					end
					return a.id < b.id
				end,
				columnSize = 4,
				isRefresh = bindHelper.self("isRefresh"),
				item = bindHelper.self("lineList"),
				cell = bindHelper.self("item"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local data = idlertable.new({
						key = v.id,
						num = v.num,
						targetNum = v.selected and v.targetNum,
					})
					list:enableSchedule()
					local addInfo = true
					local function onIncreaseNum(step)
						local targetNum = data:proxy().targetNum or 0
						targetNum = cc.clampf(targetNum + step, 0, data:proxy().num)
						data:proxy().targetNum = targetNum ~= 0 and targetNum or nil
						if step > 0 then
							if data:proxy().num > targetNum then
								table.insert(isDbidSave, v.dbids[targetNum])
								addInfo = true
							elseif data:proxy().num == targetNum and addInfo then
								local id = v.dbids and v.dbids[targetNum] or v.dbid
								local info = true
								for k1, v1 in pairs(isDbidSave) do
									if id == v1 then
										info = false
									end
								end
								if info then
									table.insert(isDbidSave, id)
								end
								addInfo = false
							end
						else
							for i1,v1 in pairs(isDbidSave) do
								if v.level ~= 1 then
									if v1 == v.dbid then
										table.remove(isDbidSave, i1)
									end
								else
									if v1 == v.dbids[targetNum+1] then
										table.remove(isDbidSave, i1)
									end
								end
							end
							addInfo = true
						end
						v.targetNum = targetNum
						v.isRefresh:notify()
						if (targetNum + step) < 0 or (targetNum + step) > data:proxy().num then
							list:unSchedule("numChange")
						end
					end
					local touchBeganPos
					local function onChangeNum(panel, node, event, step, showTip)
						local targetNum = v.targetNum
						targetNum = step < 0 and targetNum - 1 or targetNum
						if touchBeganPos == nil then
							touchBeganPos = event
						end
						if event.name == "click" then
							list:unScheduleAll()
							if touchBeganPos and targetNum < v.num then
								onIncreaseNum(step)
								upgradeFloatingWord(panel, showTip)
							end
							touchBeganPos = nil

						elseif event.name == "began" then
							if touchBeganPos then
								list:schedule(function(delta)
									if targetNum < v.num then
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
							gemIconShow = true,
							longtouch = true,
							showReduce = true,
							specialKey = {
								leftTopLv = v.level
							},
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
	["acquire.rule"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleShow")}
		},
	},
	["jumpShop"] = {
		varname = "jumpShop",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRebirthBtn")}
		},
	},
	["duckPanel"] = "duckPanel",
	["acquire2.rmbPanel"] = "rmbPanel",
	["acquire2.rmbPanel.num"] = "decomposeTxt",
	["acquire.num"] = "haveTxt",
	["acquire2.rmbPanel.title"] = "gainTxt",
	["acquire2.rmbPanel.icon"] = "gainIcon",
	["acquire"] = "havePanel",
	["mask"] = "mask",
	["icon"] = "icon",
}

function GemDecomposeView:onCreate()
	self.isRefresh = idler.new(false)
	self.item1:visible(false)
	self.bottomData = idlers.newWithMap({
		-- {name = gLanguageCsv.whiteText, icon = "city/develop/explore/tag_1.png", quality = 1},
		{name = gLanguageCsv.greenText, icon = "city/develop/explore/tag_2.png", quality = 2},
		{name = gLanguageCsv.blueText, icon = "city/develop/explore/tag_3.png", quality = 3},
		{name = gLanguageCsv.purpleText, icon = "city/develop/explore/tag_4.png", quality = 4},
		{name = gLanguageCsv.orangeText, icon = "city/develop/explore/tag_5.png", quality = 5},
	})
	self.subassemblys = idlers.newWithMap({})
	self.decomposeNum = idler.new(0)
	self.decomposeDbid = idler.new(0)
	idlereasy.when(gGameModel.role:getIdler("gems"), function (_, gems)
		local data = {}
		isDbidSave = {}
		self.qualityData = {}
		local level1gems = {}
		for i, dbid in pairs(gems) do
			local gem = gGameModel.gems:find(dbid)
			if gem:read("exist_flag") then
				local gem_id = gem:read('gem_id')
				local level = gem:read('level')
				local belongCarddbid = gem:read('card_db_id')
				local gemData = {
					id = gem_id,
					num = 1,
					cfg = dataEasy.getCfgByKey(gem_id),
					level = level,
					dbid = dbid,
					targetNum = 0,
					quality = csv.gem.gem[gem_id].quality
				}
				if not belongCarddbid then
					if level == 1 then
						if not level1gems[gem_id] then
							gemData.dbids = {dbid}
							level1gems[gem_id] = gemData
							table.insert(data, gemData)
						else
							table.insert(level1gems[gem_id].dbids, dbid)
							level1gems[gem_id].num = level1gems[gem_id].num + 1
						end
					else
						table.insert(data, gemData)
					end
				end
			end
		end

		for k, v in pairs(data) do
			data[k].isRefresh = self.isRefresh
			local quality = csv.gem.gem[v.id].quality
			if not self.qualityData[quality] then
				self.qualityData[quality] = {}
			end
			if v.num == 1 then
				table.insert(self.qualityData[quality], v.dbid)
			else
				for i,v1 in ipairs(v.dbids) do
					table.insert(self.qualityData[quality], v1)
				end
			end
		end

		self.subassemblys:update(data)
		self.duckPanel:visible(#data == 0)
		self.mask:visible(not #data == 0)
		self.decomposeNum:set(0)
		self.decomposeDbid:set(0)
		self.quality = 2
	end)

	-- 分解特效
	self.fenjie = widget.addAnimation(self.icon, "fushichouqu/fuwenfenjie.skel", "effect_loop", 99)
		:alignCenter(self.icon:size())

	--分解获得的钻石
	idlereasy.when(self.decomposeDbid, function (_, val)
		self.decomposeTxt:text(val)
		adapt.oneLinePos(self.gainTxt, {self.decomposeTxt, self.gainIcon})
	end)

	--选择要分解的符石
	idlereasy.when(self.isRefresh, function ()
		local total = 0
		local newT = {}
		for i, v in self.subassemblys:ipairs() do
			if self.subassemblys:atproxy(i).targetNum and self.subassemblys:atproxy(i).targetNum > 0 then
				local key, num = csvNext(self.subassemblys:atproxy(i).cfg.decomposeReturn)
				total = total + num * self.subassemblys:atproxy(i).targetNum
			end
		end
		self.decomposeNum:set(total)
		self:refreshTextUpdata()
		self:qualityNumCalculate()
	end)

	self:gemQuintessence()

	Dialog.onCreate(self)
end

function GemDecomposeView:gemQuintessence()
	--已有精髓
	local items = gGameModel.role:read("items")
	local num = items[529] or 0
	self.haveTxt:text(num)
	local width = self.haveTxt:width() + 50
	width = math.max(width, 187)
	self.havePanel:get("bg"):width(width)
	self.havePanel:get("rule"):x(self.havePanel:get("bg"):x() + width + 50)
	self.haveTxt:x(self.havePanel:get("bg"):x() + width / 2)
end

function GemDecomposeView:onRuleShow()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1000})
end

function GemDecomposeView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.gemResolve)
		end),
		c.noteText(unpack({84001, 84005})),
	}
	return context
end

--重生入口
function GemDecomposeView:onRebirthBtn()
	if not gGameUI:goBackInStackUI("city.card.rebirth.view") then
		gGameUI:stackUI("city.card.rebirth.view", nil, nil, 4)
	end
end

--选择品质
function GemDecomposeView:onColorClick(list, k, quality)
	self.bottomData:atproxy(k).selected = not self.bottomData:atproxy(k).selected
	local qualityBtn = self.bottomData:atproxy(k).selected
	for i, v in self.subassemblys:ipairs() do
		if v:proxy().cfg.quality == quality then
			self.subassemblys:atproxy(i).selected = self.bottomData:atproxy(k).selected
			self.subassemblys:atproxy(i).targetNum = self.subassemblys:atproxy(i).selected and self.subassemblys:atproxy(i).num or 0
		end
	end

	local gemTab = {}
	for k1,dbid in ipairs(isDbidSave) do
		local gemId = gGameModel.gems:find(dbid):read('gem_id')
		local gemQuality = csv.gem.gem[gemId].quality
		if quality == gemQuality then
			table.insert(gemTab, dbid)
		end
	end
	for _, v1 in ipairs(gemTab) do
		for k2, v2 in ipairs(isDbidSave) do
			if v1 == v2 then
				table.remove(isDbidSave, k2)
			end
		end
	end
	local str = true
	if self.qualityData[quality] then
		for k1,v in pairs(self.qualityData[quality]) do
			if self.bottomData:atproxy(k).selected then
				table.insert(isDbidSave, v)
				str = false
			end
		end
	end
	self:qualityNumCalculate()
	if str and qualityBtn then
		gGameUI:showTip(gLanguageCsv.gemnotQuality)
		self.bottomData:atproxy(k).selected = false
		return
	end

	local total = 0
	local rmbInfo = true
	for i, v in self.subassemblys:ipairs() do
		if self.subassemblys:atproxy(i).targetNum and self.subassemblys:atproxy(i).targetNum > 0 then
			local key, num = csvNext(self.subassemblys:atproxy(i).cfg.decomposeReturn)
			total = total + num * self.subassemblys:atproxy(i).targetNum
		end
	end
	self.decomposeNum:set(total)
	self:refreshTextUpdata(qualityBtn)
end

--选择的品质，按最大的
function GemDecomposeView:qualityNumCalculate()
	local qualitys = 2
	for _, dbids in pairs(isDbidSave) do
		local ids = gGameModel.gems:find(dbids):read('gem_id')
		if qualitys < csv.gem.gem[ids].quality then
			qualitys = csv.gem.gem[ids].quality
		end
	end
	self.quality = qualitys
end

--分解消耗钻石
function GemDecomposeView:refreshTextUpdata(info)
	local returnNum, id
	local rmbNum = 0
	if #isDbidSave == 0 or self.decomposeNum:read() == 0 then
		isDbidSave = {}
		self.quality = 0
		for i=1,6 do
			if self.bottomData:atproxy(i) then
				self.bottomData:atproxy(i).selected = false
			end
		end
		if info then
			gGameUI:showTip(gLanguageCsv.gemnotQuality)
			return false
		end
	else
		for k,dbid in pairs(isDbidSave) do
			local id = gGameModel.gems:find(dbid):read('gem_id')
			local strengthCostSeq = csv.gem.gem[id].strengthCostSeq
			local decomposeReturn = csv.gem.gem[id].decomposeReturn
			local level = gGameModel.gems:find(dbid):read('level')
			if level > 1 then
				for levelKey, data in orderCsvPairs(csv.gem.cost) do
					if levelKey < level then
						rmbNum = rmbNum + data['costItemMap'..strengthCostSeq][529]
					end
				end
				rmbNum = gCommonConfigCsv.gemRebirthRetrunProportion * rmbNum + decomposeReturn[529]
			else
				rmbNum = rmbNum + decomposeReturn[529]
			end
		end
	end
	self.decomposeDbid:set(rmbNum)
end

function GemDecomposeView:onDecompose()
	local rmb = gGameModel.role:read("rmb")
	if self.decomposeNum:read() == 0 then
		gGameUI:showTip(gLanguageCsv.noChooseComponent)
		return
	end

	if self.quality >= 4 then
		gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = gLanguageCsv.resolve, isRich = true, btnType = 2, cb = function ()
			self:onDecomposeRequest()
		end})
	else
		self:onDecomposeRequest()
	end
end

-- @desc 先播特效，再执行协议结果
function GemDecomposeView:onDecomposeRequest()
	local showOver = {false}
	gGameApp:requestServerCustom("/game/gem/decompose")
		:params(isDbidSave)
		:onResponse(function (tb)
			self.fenjie:play("effect")
			performWithDelay(self, function ()
				showOver[1] = true
				gGameUI:showGainDisplay({{csvNext(tb.view)}}, {raw = false, cb = function( ... )
					self:gemQuintessence()
					upgradeFloatingWord(self.haveTxt, "+"..tb.view[529], true)
					self.jumpShop:setEnabled(true)
					for i=1,6 do
						if self.bottomData:atproxy(i) then
							self.bottomData:atproxy(i).selected = false
						end
					end
				end})
				self.fenjie:play("effect_loop")
			end, 1.6)
		end)
		:wait(showOver)
		:doit(function (tb)
			self.fenjie:play("effect_loop")
		end)
end

function GemDecomposeView:onCleanup()
	isDbidSave = {}
	Dialog.onCleanup(self)
end

return GemDecomposeView
