-- @date 2020-7-21
-- @desc: 超进化选择精灵界面

local ViewBase = cc.load("mvc").ViewBase
local MegaChooseCardView = class("MegaChooseCardView", Dialog)

MegaChooseCardView.RESOURCE_FILENAME = "card_mega_choose_card.json"
MegaChooseCardView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["innerList"] = "innerList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				columnSize = 3,
				asyncPreload = 12,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					bind.extend(list, node:get("head"), {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							star = v.star,
							rarity = v.rarity,
							levelProps = {
								data = v.level,
							},
						}
					})
					if ui.CARD_USING_TXTS[v.battleType] then
						node:get("txt"):text(gLanguageCsv[ui.CARD_USING_TXTS[v.battleType]]):show()
						node:get("imgTick"):visible(false)
						node:get("imgMask"):visible(true)
					else
						node:get("txt"):hide()
						node:get("imgTick"):visible(v.isSel)
						node:get("imgMask"):visible(v.isSel)
					end
					node:get("textName"):text(csv.cards[v.id].name)
					node:get("textFightPoint"):text(v.fight)
					-- 只在本体选择卡牌时使用，没满足最高级状态不能超进化
					uiEasy.addTextEffect1(node:get("txt"))
					node:get("imgLock"):visible(v.lock)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, list:getIdx(k), v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onCellClick"),
			},
		},
	},
	["down"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowDown")
		},
	},
	["down.textNum"] = "textNum",
	["down.textNote"] = "textNote",
	["down.btnOk"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSure")}
		},
	},
	["tipPanel"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("showTip"),
		},
	},
	["tipPanel.textTip"] = "textTip",
}

-- data.key == "main" 主界面跳转过来的 {key, cardId, megaIndex, cardDbid, subCardData} chooseIdx nil本体 idx消耗卡牌位置
-- data.key == "card" {key, csvId, selectId}
function MegaChooseCardView:onCreate(data, cb)
	self.data = data
	self.cb = cb
	-- self.cardData = {}	--保存返回的卡牌数据(暂时只用在多,选看配置)
	self.cardDatas = idlers.new({})
	self.showTip = idler.new(false)
	local needNum = 1
	local limitStar = true
	if data.key == "main" then
		limitStar = false
		if data.chooseIdx then
			local cfg = csv.card_mega[data.megaIndex]
			needNum = cfg.costCards.num or 1
		end
	end
	self.needNum = idler.new(needNum)
	self.chooseNum = 0
	idlereasy.when(gGameModel.role:getIdler("cards"), function(_, cards)
		local cardMegaData = {}
		local hash = dataEasy.inUsingCardsHash()
		for k, dbid in ipairs(cards) do
			local cards = gGameModel.cards:find(dbid)
			local cardDatas = cards:read("card_id", "skin_id", "level", "star", "advance", "name", "fighting_point", "locked")
			local cardCsv = csv.cards[cardDatas.card_id]
			local unitID = cardCsv.unitID
			local unitCsv = csv.unit[unitID]
			local skinUnitID = dataEasy.getUnitId(cardDatas.card_id, cardDatas.skin_id)
			local rarity, cardMarkID = unitCsv.rarity, cardCsv.cardMarkID
			local isOK = false
			local isSel = false
			local battleType = hash[dbid]
			local locked = cardDatas.locked
			local cardType = 0
			if data.key == "main" then
				local cfg = csv.card_mega[data.megaIndex]
				if data.chooseIdx then
					if (cardCsv.cardMarkID == cfg.costCards.markID and cardDatas.star >= cfg.costCards.star)
						or (rarity == cfg.costCards.rarity and cardDatas.star >= cfg.costCards.star) then
						isOK = true
					end
					if data.subCardData[dbid] then
						isSel = true
					end
					-- 主体的不显示
					if dbid == data.cardDbid then
						isOK = false
					end
				else
					-- 主体精灵锁定和队伍中也可以进行超进化
					battleType = nil
					locked = false
					if cfg.card[1] == cardDatas.card_id and cfg.card[2] <= cardDatas.star then
						isOK = true
					end
					if dbid == data.cardDbid then
						isSel = true
					end
					-- 副卡的不显示
					if data.subCardData[dbid] then
						isOK = false
					end
				end
			else
				local cfg = csv.card_mega_convert[data.csvId]
				if cardCsv.cardType ~= 2 then
					for i = 1, math.huge do
						local data = cfg["needCards" .. i]
						if not data or csvSize(data) <= 0 then
							break
						end
						if rarity == data[1] and (data[2] == -1 or unitCsv.natureType == data[2] or unitCsv.natureType2 == data[2]) then
							isOK = true
							break
						end
					end
				else
					cardType = 1
				end
				if dbid == data.selectId then
					isSel = true
				end
				for _, cardId in csvPairs(cfg.needSpecialCards) do
					if cardId == cardDatas.card_id then
						isOK = true
						break
					end
				end
			end
			-- 超进化过或高于基础星级的不显示
			if limitStar and (cardCsv.megaIndex > 0 or cardDatas.star > cardCsv.star) then
				isOK = false
			end
			if isOK then
				table.insert(cardMegaData, {
					dbid = dbid,
					id = cardDatas.card_id,
					unitId = skinUnitID,
					fight = cardDatas.fighting_point,
					name = cardDatas.name,
					level = cardDatas.level,
					star = cardDatas.star,
					advance = cardDatas.advance,
					rarity = rarity,
					isSel = isSel,		--选中的卡牌做标记
					battleType = battleType,
					lock = locked,
					mega = cardCsv.megaIndex > 0,			--超进化也可以转化，这里记录当做提示
					cardType = cardType,
				})
			end
		end
		table.sort(cardMegaData, function(a, b)
			local hasTxtA = ui.CARD_USING_TXTS[a.battleType] ~= nil
			local hasTxtB = ui.CARD_USING_TXTS[b.battleType] ~= nil
			if hasTxtA ~= hasTxtB then
				return hasTxtB
			end
			if a.cardType ~= b.cardType then
				return a.cardType > b.cardType
			end
			if a.id ~= b.id then
				return a.id < b.id
			end
			return a.fight < b.fight
		end)
		self.cardDatas:update(cardMegaData)
		self.textTip:text(gLanguageCsv.spriteNotNum)
		self.showTip:set(#cardMegaData == 0)
		self.needNum:notify()
	end)

	idlereasy.when(self.needNum, function(_, num)
		local chooseNum = 0
		for _, v in self.cardDatas:ipairs() do
			if v:read().isSel then
				chooseNum = chooseNum +1
			end
		end
		self.chooseNum = chooseNum
		self.textNum:text(chooseNum .. "/" .. num)
	end)

	Dialog.onCreate(self, {clickClose = true})
end

function MegaChooseCardView:onChangeData(idx, v)
	self.cardDatas:atproxy(idx).lock = gGameModel.cards:find(v.dbid):read("locked")
end

--单选和多选都是通过配置控制的
--目前多选只在主界面超进化的精灵材料中用到
function MegaChooseCardView:onCellClick(list, t, v)
	--卡牌是否上锁
	if v.lock then
		gGameUI:showDialog({
			cb = function()
				gGameUI:stackUI("city.card.strengthen", nil, {full = true}, 1, v.dbid, self:createHandler("onChangeData", t.k, v))
			end,
			btnType = 2,
			content = string.format(gLanguageCsv.gotoUnLock, gLanguageCsv.change),
			clearFast = true,
		})
		return true
	end

	if ui.CARD_USING_TXTS[v.battleType] then
		gGameUI:showTip(gLanguageCsv[ui.CARD_USING_TXTS[v.battleType]])
		return
	end
	local isSel = self.cardDatas:atproxy(t.k).isSel
	local function cb()
		if not isSel and self.chooseNum >= self.needNum:read() then
			for _, v in self.cardDatas:pairs() do
				if v:proxy().isSel then
					v:proxy().isSel = false
					break
				end
			end
		end
		self.cardDatas:atproxy(t.k).isSel = not isSel
		self.needNum:notify()
	end
	if not isSel and (self.data.key ~= "main" or self.data.chooseIdx) then
		-- 等级、 突破、 星级任意一项或者多项的等级大于初始等级
		local str
		local cardCfg = csv.cards[v.id]
		if v.mega then
			str = gLanguageCsv.megaOk

		elseif v.star > cardCfg.star then
			str = gLanguageCsv.selectCardMaterialsMega

		elseif v.level > 1 or v.advance > 1 then
			str = gLanguageCsv.selectCardMaterialsMega
		end
		if str then
			gGameUI:showDialog({title = gLanguageCsv.spaceTips, content = str, isRich = true, fontSize = 50, btnType = 2, cb = cb})
			return
		end
	end
	cb()
end

--多选暂时用在超进化主界面的材料卡牌上，根据配置来处理
function MegaChooseCardView:onSure()
	local t = {}
	for _, v in self.cardDatas:ipairs() do
		if v:read().isSel then
			t[v:read().dbid] = true
		end
	end
	if self.data.key == "main" then
		if self.data.chooseIdx then
			self.data.subCardData = t
		else
			self.data.cardDbid = next(t)
		end
	else
		self.data.selectId = next(t)
	end
	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return MegaChooseCardView