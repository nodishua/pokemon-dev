-- @desc 符石转换

local insert = table.insert
local sort = table.sort
local PAGEBTN_TEXTURES = {
	NORMAL = 'city/card/gem/btn_yq_b.png',
	SELECTED = 'city/card/gem/btn_yq_h.png'
}
local GemReplacementView = class('GemView', Dialog)
GemReplacementView.RESOURCE_FILENAME = 'activity_gem_up.json'
GemReplacementView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	['right.subList'] = 'subList',
	['right.item'] = 'item',
	['right.list'] = {
		varname = 'list',
		binds = {
			event = 'extend',
			class = 'tableview',
			props = {
				asyncPreload = 20,
				data = bindHelper.self('showData'),
				columnSize = 5,
				item = bindHelper.self('subList'),
				cell = bindHelper.self('item'),
				leftPadding = 10,
				topPadding = 15,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = 'icon_key',
						props = {
							noListener = true,
							data = {
								key = v.id,
								num = v.num,
								dbId = v.dbid
							},
							specialKey = {
								leftTopLv = v.level
							},
							onNode = function(node)
								if v.selectEffect then
									v.selectEffect:removeSelf()
									v.selectEffect:alignCenter(node:size())
									node:add(v.selectEffect, -1)
								end

								if v.gemNew then
									ccui.ImageView:create("other/gain_sprite/txt_new.png")
										:alignCenter(node:size())
										:addTo(node, 11, "isNew")
										:scale(0.8)
								end
								node:onTouch(functools.partial(list.itemClick, list, node, k, v))
							end
						},
					})
				end
			},
			handlers = {
				itemClick = bindHelper.self('onItemClick')
			}
		}
	},
	['right.pageBtn'] = 'pageBtn',
	['right.pageList'] = {
		varname = 'pageList',
		binds = {
			event = 'extend',
			class = 'listview',
			props = {
				data = bindHelper.self('pageBtns'),
				item = bindHelper.self('pageBtn'),
				onItem = function(list, node, k, v)
					local res = v.select and PAGEBTN_TEXTURES.SELECTED or PAGEBTN_TEXTURES.NORMAL
					node:get('bg'):texture(res)
					local color = v.select and ui.COLORS.WHITE or ui.COLORS.RED
					node:get('title'):setTextColor(color)
					node:get('title'):setString(gLanguageCsv['symbolRome'..k])
					node:get('bg'):setTouchEnabled(true)
					bind.touch(list, node:get('bg'), {methods = {ended = functools.partial(list.clickCell, k)}})
				end
			},
			handlers = {
				clickCell = bindHelper.self('pageBtnClick')
			}
		}
	},
	['right'] = 'right',
	['right.btnFilterPanel'] = 'btnFilterPanel',
	['right.btnFilterPanel.btnFilter'] = {
		varname = 'btnFilter',
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onFilter')}
		}
	},
	['right.btnFilterPanel.btnFilter.arrow'] = 'filterArrow',
	['right.btnFilterPanel.btnFilter.txt'] = {
		varname = 'filterTxt',
		binds = {
			{
				event = 'effect',
				data = {glow = {color = ui.COLORS.GLOW.WHITE}}
			}
		}
	},
	['right.noGemTip'] = 'noGemTip',
	['right.acquire.num'] = 'acquireNum',
	['right.acquire.bg'] = 'acquireBg',
	['right.acquire.btnAdd'] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('btnDecompose')}
		}
	},
	['left.icon1'] = 'centerBg',
	["left"] = "left",
	["left.btn"] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('btnClick')}
		}
	},
	["left.btn.txt"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		}
	},
	["left.hintBtn"] = {
		binds = {
			event = 'touch',
			methods = {ended = bindHelper.self('onRuleShow')}
		}
	},
	["left.numPan"] = "numPan",
	["left.animation"] = "animation",
	["left.clickPanel1"] = {
		varname = "gemSuit",
		binds = {
			event = 'click',
			method = bindHelper.self('btnTypeClick'),
		}
	},
	["left.clickPanel2"] = {
		varname = "gemSerialNum",
		binds = {
			event = 'click',
			method = bindHelper.self('btngemSerialNumClick'),
		}
	},
}

function GemReplacementView:onCreate(activityID)
	self.activityID = activityID
	self.gemType = 'blank'
	self.pageBtn:hide()
	local pos = self:getResourceNode():convertToNodeSpace(cc.p(100, 0))
	self.pageBtns = idlers.newWithMap({
		{}, {}, {}, {}, {}, {}
	})
	self.selectedPage = idler.new()
	self.selectedPage:addListener(function(val, oldval)
		if oldval then
			self.pageBtns:atproxy(oldval).select =  false
		end
		if val then
			self.pageBtns:atproxy(val).select = true
		end
	end)

	self.selectEffect = ccui.ImageView:create("common/box/box_selected.png")
		:alignCenter(self.item:size())
		:retain()
	self.gemUp = csv.yunying.yyhuodong[activityID].paramMap.exchangeTimes
	self.selectItem = idlertable.new({})
	self.showData = idlers.new({})
	self.filterType = 0
	self.selectItem:addListener(function(val, oldval)
		if next(val) then
			local data = self.showData:atproxy(val.k)
			data.selectEffect = self.selectEffect
			data.gemNew = false
		end
	end)

	self:initHeroSprite()
	self:updateShowData()
	self.right:get("title"):text(gLanguageCsv.gemSlogan)
	self.right:get("title"):x(self.pageList:x() + 10)
	if matchLanguage({"kr"}) then
		adapt.setTextAdaptWithSize(self.noGemTip:get("txt"), {size = cc.size(500,100)})
	end

	--钻石消耗数据组装
	local huodongID = csv.yunying.yyhuodong[activityID].huodongID
	self.gemConsumeRmb = {}
	for k,v in orderCsvPairs(csv.yunying.gem_exchange) do
		if v.huodongID == huodongID then
			self.gemConsumeRmb[v.quality] =  v.cost
		end
	end
	idlereasy.when(gGameModel.role:getIdler("rmb"), function(_, rmb)
		local rmbNum = self:consumeRmb()
		local colors = ui.COLORS.NORMAL.DEFAULT
		if rmb < rmbNum then
			colors = ui.COLORS.RED
		end
		self.numPan:get("num"):color(colors)
		adapt.oneLinePos(self.numPan:get("title"), {self.numPan:get("num"), self.numPan:get("icon")}, cc.p(10, 0), "left")
	end)

	Dialog.onCreate(self, {blackType = 2})
end

function GemReplacementView:updateShowData()
	self.selectItem:set({})
	dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
	local data = {}
	local level1gems = {}

	local gemDataFunc = function(dbid, gem_id, level, belongCarddbid, gemNew)
		local cfg = dataEasy.getCfgByKey(gem_id)
		local gemData = {
			id = gem_id,
			num = 1,
			suitNo = cfg.suitNo,
			suitID = cfg.suitID,
			level = level,
			quality = cfg.quality,
			dbid = dbid,
			gemNew = gemNew,
		}
		local selectSuitNo = self.selectedPage:read()
		if not belongCarddbid
			and (not selectSuitNo or (selectSuitNo == gemData.suitNo) or not gemData.suitNo)
			and (self.filterType == 0 or self.filterType == gemData.suitID or not gemData.suitID) then
			if level == 1 then
				if not level1gems[gem_id] then
					gemData.dbids = {dbid}
					level1gems[gem_id] = gemData
					insert(data, gemData)
				else
					insert(level1gems[gem_id].dbids, dbid)
					level1gems[gem_id].num = level1gems[gem_id].num + 1
				end
			else
				insert(data, gemData)
			end
		end
	end

	local gems = gGameModel.role:read('gems')
	for i, dbid in pairs(gems) do
		local gem = gGameModel.gems:find(dbid)
		local gem_id = gem:read('gem_id')
		local level = gem:read('level')
		local cfg = dataEasy.getCfgByKey(gem_id)
		local num = 0
		local gemNew = false
		if self.obtainDbid then
			for i,v in ipairs(self.obtainDbid) do
				if v == dbid then
					gemNew = true
				end
			end
		end

		local belongCarddbid = gem:read('card_db_id')
		if cfg.quality >= 4 and cfg.suitID then
			if csvSize(self.gemReplacement) == 0 then
				gemDataFunc(dbid, gem_id, level, belongCarddbid, gemNew)
			else
				for k,v in pairs(self.gemReplacement) do
					if v.dbid and v.dbid ~= dbid and v.quality == cfg.quality then
						if self.gemType == 'blank' then
							num = num + 1
						elseif (self.gemType == 'suitID' and v.suitID == cfg.suitID) or (self.gemType == 'suitNo' and v.suitNo == cfg.suitNo) then
							num = num + 1
						end
					end
				end
				if num == csvSize(self.gemReplacement) then
					gemDataFunc(dbid, gem_id, level, belongCarddbid, gemNew)
					num = 0
				end
			end
		end
	end
	sort(data, function(a, b)
		if a.quality ~= b.quality then
			return a.quality > b.quality
		end
		if a.suitID ~= b.suitID then
			if a.suitID and b.suitID then
				return a.suitID < b.suitID
			else
				return not b.suitID
			end
		end
		if a.suitNo ~= b.suitNo then
			if a.suitNo and b.suitNo then
				return a.suitNo < b.suitNo
			else
				return not b.suitNo
			end
		end
		return a.level > b.level
	end)
	self.showData:update(data)
	local str = gLanguageCsv.knapsackNoGem
	if self.gemType == 'suitID' then
		str = gLanguageCsv.identicalSuitIdGem
	elseif self.gemType == 'suitNo' then
		str = gLanguageCsv.identicalSuitNoGem
	end
	self.noGemTip:get("txt"):text(str)
	self.noGemTip:visible(#data == 0)

	local rmbNum, exchangeCounter = self:consumeRmb()
	self.numPan:get("num"):text(rmbNum)
	self.left:get("num"):text(exchangeCounter .. "/" .. self.gemUp)
	self.dissatisfy = exchangeCounter ~= self.gemUp
	adapt.oneLinePos(self.numPan:get("num"), self.numPan:get("icon"), cc.p(10, 0), "left")
end

-- 计算并显示钻石消耗
-- rmb:固定消耗 + 符石品质消耗
function GemReplacementView:consumeRmb()
	local data = gGameModel.role:read('yyhuodongs')[self.activityID]
	local costRmb = csv.yunying.yyhuodong[self.activityID].paramMap.cost
	local rmbNum, exchangeCounter = 0, 0
	if data and data.info.exchange_counter then
		local key = cc.clampf(data.info.exchange_counter+1, 1, csvSize(costRmb))
		rmbNum = costRmb[key]
		exchangeCounter = data.info.exchange_counter
	else
		rmbNum = costRmb[1]
	end
	if csvSize(self.gemReplacement) >= 1 then
		for k,v in pairs(self.gemReplacement) do
			rmbNum = rmbNum + self.gemConsumeRmb[csv.gem.gem[v.id].quality]
			break
		end
	end
	return rmbNum, exchangeCounter
end

--给转换符石添加拖拽
function GemReplacementView:initHeroSprite(id)
	self.gemSuit:get('icon'):hide()
	self.gemSerialNum:get('icon'):hide()

	self.gemReplacement = {}	--保存三个数据
	self.gemSlots = {}			--保存三个item
	for i=1, 3 do
		local item = self.left:get("item" .. i)
		item:get("bg"):hide()
		item:get("levelBg"):hide()
		item:get("lv"):hide()
		item:get("icon"):hide()
		self.gemSlots[i] = item
		self.gemSlots[i]:onTouch(function(event)
			if event.name == 'began' then
				self.touchBeganPos = self.gemSlots[i]:getTouchBeganPosition()
				if self.movePanel then
					self.movePanel:removeSelf()
					self.movePanel = nil
				end
			elseif event.name == "moved" and self.gemReplacement[i] then
				local deltaX = math.abs(event.x - self.touchBeganPos.x)
				local deltaY = math.abs(event.y - self.touchBeganPos.y)
				if not self.movePanel and (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
					self.gemSlots[i]:get("icon"):hide()
					self.gemSlots[i]:get("levelBg"):hide()
					self.gemSlots[i]:get("lv"):hide()
					self.movePanel = self:createMovePanel(self.gemReplacement[i])
				end
				if self.movePanel then
					local pos = self:convertToNodeSpace(event)
					self.movePanel:xy(pos.x, pos.y)
				end
			elseif event.name == "ended" or event.name == "cancelled" and self.gemReplacement[i] then
				for s=1, 3 do
					self.gemSlots[s]:get("bg"):visible(i == s)
				end
				if self.movePanel then
					local moveBox = self.movePanel:box()
					local pos = self:convertToWorldSpace(cc.p(moveBox.x, moveBox.y))
					pos = self.left:convertToNodeSpace(pos)
					moveBox.x, moveBox.y = pos.x, pos.y
					local slotIdx = self:checkRectInSlots(moveBox)
					if slotIdx then
						if not self.gemReplacement[slotIdx] then
							self.gemReplacement[slotIdx] = self.gemReplacement[i]
							self.gemSlots[slotIdx]:get("icon"):show()
							self.gemSlots[slotIdx]:get("levelBg"):show()
							self.gemSlots[slotIdx]:get("lv"):show()
							self.gemSlots[slotIdx]:get("icon"):texture(csv.gem.gem[self.gemReplacement[i].id].icon)
							self.gemSlots[slotIdx]:get("lv"):text("Lv" .. self.gemReplacement[i].level)
							self.gemSlots[slotIdx]:get("levelBg"):width(self.gemSlots[slotIdx]:get("lv"):width() + 20)
							self.gemSlots[slotIdx]:get("add"):hide()
							self.gemSlots[i]:get("add"):show()
							self.gemSlots[i]:get("icon"):hide()
							self.gemSlots[i]:get("levelBg"):hide()
							self.gemSlots[i]:get("lv"):hide()
							self.gemReplacement[i] = nil
						else
							self.gemReplacement[slotIdx], self.gemReplacement[i] = self.gemReplacement[i], self.gemReplacement[slotIdx]
							self.gemSlots[slotIdx]:get("icon"):texture(csv.gem.gem[self.gemReplacement[slotIdx].id].icon)
							self.gemSlots[i]:get("icon"):texture(csv.gem.gem[self.gemReplacement[i].id].icon)
							self.gemSlots[slotIdx]:get("lv"):text("Lv" .. self.gemReplacement[slotIdx].level)
							self.gemSlots[slotIdx]:get("levelBg"):width(self.gemSlots[slotIdx]:get("lv"):width() + 20)
							self.gemSlots[i]:get("lv"):text("Lv" .. self.gemReplacement[i].level)
							self.gemSlots[i]:get("levelBg"):width(self.gemSlots[i]:get("lv"):width() + 20)
							self.gemSlots[i]:get("icon"):show()
							self.gemSlots[i]:get("levelBg"):show()
							self.gemSlots[i]:get("lv"):show()
						end
					else
						self.gemSlots[i]:get("add"):show()
						self.gemSlots[i]:get("icon"):hide()
						self.gemSlots[i]:get("levelBg"):hide()
						self.gemSlots[i]:get("lv"):hide()
						self.gemReplacement[i] = nil
						self:updateShowData()
					end
					self.movePanel:removeSelf()
					self.movePanel = nil
				else
					if self.gemReplacement[i] then
						self:showDetails(self.gemReplacement[i].dbid, "left")
					end
				end
			end
		end)
	end
end

--锁定同类型(同套装)
function GemReplacementView:btnTypeClick()
	local gemSuitIcon = self.gemSuit:get("icon")
	local gemSerialNumIcon = self.gemSerialNum:get("icon")
	if self.gemType == 'suitID' then
		gemSuitIcon:hide()
		self.gemType = 'blank'
	elseif self.gemType == 'suitNo' then
		for i=1, 3 do
			self.gemReplacement[i] = nil
			self.gemSlots[i]:get("icon"):hide()
			self.gemSlots[i]:get("levelBg"):hide()
			self.gemSlots[i]:get("lv"):hide()
			self.gemSlots[i]:get("add"):show()
			gemSerialNumIcon:hide()
			gemSuitIcon:hide()
		end
		gemSuitIcon:show()
		gemSerialNumIcon:hide()
		self.gemType = 'suitID'
	else
		self:calculate("suitID", gLanguageCsv.gemType)
		gemSuitIcon:show()
		gemSerialNumIcon:hide()
		self.gemType = 'suitID'
	end
	self:updateShowData()
end

--锁定同编号
function GemReplacementView:btngemSerialNumClick()
	local gemSuitIcon = self.gemSuit:get("icon")
	local gemSerialNumIcon = self.gemSerialNum:get("icon")
	if self.gemType == 'suitNo' then
		gemSerialNumIcon:hide()
		self.gemType = 'blank'
	elseif self.gemType == 'suitID' then
		for i=1, 3 do
			self.gemReplacement[i] = nil
			self.gemSlots[i]:get("icon"):hide()
			self.gemSlots[i]:get("levelBg"):hide()
			self.gemSlots[i]:get("lv"):hide()
			self.gemSlots[i]:get("add"):show()
			gemSerialNumIcon:hide()
			gemSuitIcon:hide()
		end
		gemSerialNumIcon:show()
		gemSuitIcon:hide()
		self.gemType = 'suitNo'
	else
		self:calculate('suitNo', gLanguageCsv.gemNumber)
		gemSerialNumIcon:show()
		gemSuitIcon:hide()
		self.gemType = 'suitNo'
	end
	self:updateShowData()
end

function GemReplacementView:calculate(types, str)
	local gemData = {}
	if csvSize(self.gemReplacement) >= 2 then
		for k,v in pairs(self.gemReplacement) do
			if v[types] and not gemData[v[types]] then
				gemData[v[types]] = v[types]
			end
		end
		if csvSize(gemData) ~= 1 then
			for i=1, 3 do
				self.gemReplacement[i] = nil
				self.gemSlots[i]:get("icon"):hide()
				self.gemSlots[i]:get("levelBg"):hide()
				self.gemSlots[i]:get("lv"):hide()
				self.gemSlots[i]:get("add"):show()
			end
			gGameUI:showTip(str)
		end
	end
end

--置换
function GemReplacementView:btnClick()
	if not self.dissatisfy then
		gGameUI:showTip(gLanguageCsv.gemUpperLimit)
		return
	end
	if self.gemType == "suitID" then
		local suitNum = 0
		local suitID = 0
		local suitQuality = 0
		local suitNoTable = {}
		local isAll = true
		for k, v in pairs(self.gemReplacement) do
			suitID = v.suitID
			suitQuality = v.quality
			if itertools.include(suitNoTable, v.suitNo) then
				isAll = false
				break
			else
				table.insert(suitNoTable, v.suitNo)
			end
		end
		for k, v in csvMapPairs(csv.gem.suit) do
			if v.suitID == suitID and v.suitQuality == suitQuality then
				suitNum = math.max(suitNum, v.suitNum)
			end
		end
		if suitNum <= 3 and isAll and csvSize(self.gemReplacement) == 3 then
			gGameUI:showTip(gLanguageCsv.activityGemUpShowText)
			return
		end
	end
	if csvSize(self.gemReplacement) < 2 then
		gGameUI:showTip(gLanguageCsv.gemNum)
		return
	end
	local rmbNum = self:consumeRmb()
	if gGameModel.role:read("rmb") < rmbNum then
		uiEasy.showDialog("rmb")
		return
	end
	local data = {}
	for k,v in pairs(self.gemReplacement) do

		if v.id then
			table.insert(data, v.dbid)
		end
	end
	local str = csvSize(self.gemReplacement) == 2 and gLanguageCsv.gemHint or gLanguageCsv.gemUpNum
	gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = str, isRich = true, fontSize = 50, btnType = 2, cb = function ()
			gGameApp:requestServerCustom("/game/yy/gem/exchange")
				:params(self.activityID, data, self.gemType)
				:doit(function(tb)
					local effect = self.animation:getChildByName("effect")
					if effect then
						effect:xy(cc.p(600, 170))
						effect:show()
						effect:play("effect")
					else
						effect = widget.addAnimationByKey(self.animation, "effect/chongsheng.skel", "effect", "effect", 100)
							:xy(cc.p(600, 170))
							:scale(1.5)
					end
					performWithDelay(self, function ()
						for i=1, 3 do
							self.gemReplacement[i] = nil
							self.gemSlots[i]:get("icon"):hide()
							self.gemSlots[i]:get("levelBg"):hide()
							self.gemSlots[i]:get("lv"):hide()
							self.gemSlots[i]:get("add"):show()
						end
						self.obtainDbid = tb.view.result.gemdbIDs
						self:updateShowData()
						gGameUI:showGainDisplay(tb)
					end, 25/30)
				end)
		end})
end

function GemReplacementView:checkRectInSlots(moveBox)
	local distancemin = math.huge
	local getId
	-- 用box相交判定，相邻的box容易重复，找出最近的一个
	for k, v in pairs(self.gemSlots) do
		local box = v:box()
		if cc.rectIntersectsRect(box, moveBox) then
			local pos1 = cc.p(box.x + box.width / 2, box.y + box.height / 2)
			local pos2 = cc.p(moveBox.x + moveBox.width / 2, moveBox.y + moveBox.height / 2)
			local distance = cc.pGetDistance(pos1, pos2)
			if distance < distancemin then
				distancemin = distance
				getId = k
			end
		end
	end
	return getId
end

--选择符石的编号
function GemReplacementView:pageBtnClick(list, k)
	local old = self.selectedPage:read()
	if old == k then
		k = nil
	end
	self.selectedPage:set(k)
	self:updateShowData()
end

function GemReplacementView:getPercent()
	local container = self.list:getInnerContainer()
	local innerSize = container:size()
	local listSize = self.list:size()
	local x, y = container:xy()
	return 100 - math.abs(y) / (innerSize.height - listSize.height) * 100
end

function GemReplacementView:onItemClick(list, node, panel, k, v, event)
	if event.name == 'began' then
		self.touchBeganPos = panel:getTouchBeganPosition()
		self.list:setTouchEnabled(false)
		self.isClicked = true
	elseif event.name == 'moved' then
		local pos = event
		local deltaX = math.abs(pos.x - self.touchBeganPos.x)
		local deltaY = math.abs(pos.y - self.touchBeganPos.y)
		if deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD then
			if deltaX > deltaY * 0.7
				or (self:getPercent() < 0.1 and event.y < self.touchBeganPos.y)
				or (self:getPercent() > 99.9 and event.y > self.touchBeganPos.y) then
				if not self.movePanel then
					self.movePanel = self:createMovePanel(v)
				end
			end
			self.list:setTouchEnabled(true)
			self.isClicked = false
		end
		if self.movePanel then
			pos = self:convertToNodeSpace(pos)
			self.movePanel:xy(pos.x, pos.y)
		end

	elseif event.name == 'ended' or event.name == 'cancelled' then
		if not self.movePanel then
			local t = list:getIdx(k)
			t.data = v
			self.selectItem:set(t)
			self:showDetails(v.dbid, 'right')
		else
			local moveBox = self.movePanel:box()
			local pos = self:convertToWorldSpace(cc.p(moveBox.x, moveBox.y))
			pos = self.left:convertToNodeSpace(pos)
			moveBox.x, moveBox.y = pos.x, pos.y
			local slotIdx = self:checkRectInSlots(moveBox)
			if slotIdx and self.dissatisfy then
				self.gemReplacement[slotIdx] = {id = v.id, dbid = v.dbid, suitID = v.suitID, suitNo = v.suitNo, quality = v.quality, level = v.level}
				self.gemSlots[slotIdx]:get("icon"):show()
				self.gemSlots[slotIdx]:get("icon"):texture(csv.gem.gem[v.id].icon)
				self.gemSlots[slotIdx]:get("levelBg"):show()
				self.gemSlots[slotIdx]:get("lv"):show()
				self.gemSlots[slotIdx]:get("lv"):text("Lv" .. v.level)
				self.gemSlots[slotIdx]:get("levelBg"):width(self.gemSlots[slotIdx]:get("lv"):width() + 20)
				self.gemSlots[slotIdx]:get("add"):hide()
				self:updateShowData()
			end
			if self.movePanel then
				self.movePanel:removeSelf()
				self.movePanel = nil
				if not self.dissatisfy then
					gGameUI:showTip(gLanguageCsv.gemUpperLimit)
				end
			end
		end
	end
end

--创建移动的item
function GemReplacementView:createMovePanel(v)
	local item = self.item:clone():addTo(self, 100)
	bind.extend(self, item, {
		class = 'icon_key',
		props = {
			simpleShow = true,
			noListener = true,
			data = {
				key = v.id
			},
			specialKey = {
				leftTopLv = v.level
			},
		}
	})
	return item
end

--选择套装
function GemReplacementView:onFilter()
	self.filterArrow:setRotation(180)
	local size = self.btnFilterPanel:size()
	local pos = self.btnFilterPanel:convertToWorldSpace(cc.p(size.width, - 100))
	gGameUI:stackUI('city.card.gem.filter', nil, nil, pos, {'right', 'top'}, self:createHandler('setFilterType'), self.filterType)
end

function GemReplacementView:setFilterType(filterType)
	self.filterArrow:setRotation(0)
	if filterType then
		self.filterType = filterType
		self.filterTxt:text(gLanguageCsv['gemSuit'..filterType] or gLanguageCsv.typeFilter)
		self:updateShowData()
	end
end



--符石详情
function GemReplacementView:showDetails(dbId, align)
	local pos = self.left:get("bg"):convertToWorldSpaceAR(cc.p(0, 0))
	if align == 'left' then
		pos = self.noGemTip:convertToWorldSpaceAR(cc.p(0, 0))
	end
	self.details = gGameUI:stackUI('city.activity.gem_up.gem_details', nil, {dispatchNodes = {self.list, self.left}, clickClose = true}, {dbId = dbId, pos = pos, align = align, dissatisfy = self.dissatisfy}, self:createHandler("gemDetailsClick"))
end

function GemReplacementView:gemDetailsClick(dbid, align)
	if align == 'right' then
		if csvSize(self.gemReplacement) == 3 then
			gGameUI:showTip(gLanguageCsv.noPlace)
			return
		end
		local gem = gGameModel.gems:find(dbid)
		local id = gem:read('gem_id')
		local level = gem:read("level")
		local gemData = csv.gem.gem[id]
		for i=1, 3 do
			if not self.gemReplacement[i] then
				self.gemReplacement[i] = {id = id, dbid = dbid, suitID = gemData.suitID, suitNo = gemData.suitNo, quality = gemData.quality, level = level}
				self.gemSlots[i]:get("icon"):show()
				self.gemSlots[i]:get("icon"):texture(gemData.icon)
				self.gemSlots[i]:get("levelBg"):show()
				self.gemSlots[i]:get("lv"):show()
				self.gemSlots[i]:get("lv"):text("Lv" .. level)
				self.gemSlots[i]:get("levelBg"):width(self.gemSlots[i]:get("lv"):width() + 20)
				self.gemSlots[i]:get("add"):hide()
				break
			end
		end
	else
		local key
		for k,v in pairs(self.gemReplacement) do
			if v.dbid and v.dbid == dbid then
				key = k
			end
		end
		self.gemReplacement[key] = nil
		self.gemSlots[key]:get("icon"):hide()
		self.gemSlots[key]:get("levelBg"):hide()
		self.gemSlots[key]:get("lv"):hide()
		self.gemSlots[key]:get("add"):show()
	end

	self:updateShowData(true)
end

function GemReplacementView:onRuleShow()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1600})
end

function GemReplacementView:getRuleContext(view)
	local content = {91001, 91011}
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.gemReplacement)
		end),
		c.noteText(unpack(content)),
	}
	return context
end

function GemReplacementView:closeDetails()
	self.details:onClose()
end


function GemReplacementView:onCleanup()
	self.selectItem:destroy()
	Dialog.onCleanup(self)
end

return GemReplacementView
