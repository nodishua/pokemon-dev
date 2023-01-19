-- @date:   2019-4-3
-- @desc:   图鉴产出

local STATE = {
	UNLOCK = 1,
	JUMP = 2,
	NORMAL = 3,
}
local SHOP_UNLOCK_KEY = game.SHOP_UNLOCK_KEY

local TITLES = require("app.views.common.gain_way").WAY_TITLE

local ViewBase = cc.load("mvc").ViewBase
local HandbookGainWayView = class("HandbookGainWayView", ViewBase)

HandbookGainWayView.RESOURCE_FILENAME = "handbook_from.json"
HandbookGainWayView.RESOURCE_BINDING = {
	["panel.head"] = {
		binds = {
			event = "extend",
			class = "card_icon",
			props = {
				cardId = bindHelper.self("cardIdIdler"),
				onNode = function(panel)
				end,
			},
		}
	},
	["item"] = "item",
	["panel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("gainWayDatas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, v)
					if not v.text1 then
						local arr = string.split(v.target, "-")
						local str = gLanguageCsv[arr[1]]
						local ts = TITLES[arr[1]] or {}
						local secTitle = ts[tonumber(arr[2]) or arr[2]] or ""
						local gateId = tonumber(arr[1])
						if gateId then
							local _type, chapterId, id, str = dataEasy.getChapterInfoByGateID(gateId)
							-- 特殊关卡配置 列入20000
							if chapterId == 0 then
								if _type == 1 then
									secTitle = string.format("%s%s", gLanguageCsv.gateStory, gLanguageCsv.gate)
								else
									secTitle = string.format("%s%s", gLanguageCsv.gateDifficult, gLanguageCsv.gate)
								end
							else
								secTitle = csv.scene_conf[tonumber(arr[1])].sceneName .. " " .. chapterId .. "-" .. id
							end
						elseif arr[1] == "activity" then -- 根据活动id索引活动名
							secTitle = ""
						end
						node:get("textNote1"):text(str)
						node:get("textInfo"):text(secTitle)
						adapt.oneLinePos(node:get("textNote1"), node:get("textInfo"), cc.p(15, 0), "left")
						local btnJump = node:get("btnJump")
						local btnText = btnJump:get("textNote")
						btnJump:visible(v.state == STATE.JUMP)
						if v.state ~= STATE.JUMP then
							return
						end

						local isUnlock = jumpEasy.isJumpUnlock(v.target, false)
						if arr[1] == "shop" then
							local shopId = tonumber(arr[2]) or 1
							if SHOP_UNLOCK_KEY[shopId].mustHaveUion == true and gGameModel.role:read("union_db_id") == nil then
								isUnlock = false
							end
						end
						local color = isUnlock and cc.c4b(255, 252, 237, 255) or ui.COLORS.DISABLED.WHITE
						local state = isUnlock and "normal" or "hsl_gray"
						local textStr = isUnlock and gLanguageCsv.leaveFor or gLanguageCsv.notOpen

						cache.setShader(btnJump, false, state)
						text.deleteAllEffect(btnText)
						text.addEffect(btnText, {color = color})
						btnText:text(textStr)

						btnJump:setTouchEnabled(isUnlock)
						if isUnlock then
							bind.touch(list, btnJump, {methods = {ended = functools.partial(list.clickItem, v)}})
						end
					else
						node:get("textNote1"):text(v.text1)
						node:get("textInfo"):text(v.text2)
						adapt.oneLinePos(node:get("textNote1"), node:get("textInfo"), cc.p(15, 0), "left")
						bind.touch(list, node:get("btnJump"), {methods = {ended = functools.partial(list.clickItem, v)}})
					end
				end,
			},
			handlers = {
				clickItem = bindHelper.self("onClick"),
			},
		},
	},
	["item1"] = "item1",
	["panel.upList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("cardAttrs"),
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					local path = ui.ATTR_ICON[v]
					node:get("imgIcon"):texture(path)
				end,
			},
		},
	},
	["panel.textName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("textName"),
		},
	},
	["panel.tip"] = "tip",
	["panel.imgBG"] = "imgBG",
	["panel.tip.textNode"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("tipText")
		},
	},
}

function HandbookGainWayView:onCreate(params)
	self.cardIdIdler = params.selCardId()
	self:initModel()
	self.isShowTip = idler.new(true)
	self.gainWayDatas = idlers.newWithMap({})
	self.textName = idler.new("")
	self.cardAttrs = idlers.newWithMap({})
	self.tipText = idler.new("")
	self.list:y(self.list:y() - 20)

	local maxRoleLv = table.length(gRoleLevelCsv)
	local sectionCsv = {}
	for k,v in csvPairs(csv.world_map) do
		local data = {}
	 	if v.chapterType and v.openLevel <= maxRoleLv then
	 		if not sectionCsv[v.chapterType] then
	 			sectionCsv[v.chapterType] = {}
	 		end
	 		data.sortIndex = k
	 		table.insert(sectionCsv[v.chapterType], data)
	 	end
	end
	for k,v in pairs(sectionCsv) do
		table.sort(v,function(a,b)
			return a.sortIndex < b.sortIndex
		end)
	end

	idlereasy.when(self.cardIdIdler, function(_, cardId)
		local cardInfo = csv.cards[cardId]
		local unitInfo = csv.unit[cardInfo.unitID]
		self.rarity = unitInfo.rarity

		local gainWayDatas = {}
		if cardInfo.megaIndex <= 0 then
			local fragmentsInfo = csv.fragments[cardInfo.fragID]
			for i=1,math.huge do
				local produceGate = fragmentsInfo["produceGate"..i]
				if not produceGate or produceGate == "" then
					break
				end
				local gateId = tonumber(produceGate)
				local canShow = true
				if gateId then
					local _type, chapterId, id, str = dataEasy.getChapterInfoByGateID(gateId)
					local gateCsv = sectionCsv[_type][chapterId]
					canShow = (gateCsv ~= nil)
				end
				if string.find(produceGate, "^shop-") then
					local shopId = tonumber(string.sub(produceGate, 6)) or 1
					local unlockKey = SHOP_UNLOCK_KEY[shopId].unlockKey
					if unlockKey and not dataEasy.isUnlock(unlockKey) then
						canShow = false
					end
					-- 多语言筛选后的商店中没有该内容道具
					if not gShopGainMap[cardInfo.fragID] then
						canShow = false
					end
				end
				-- 抽卡预览里没有的不显示
				if string.find(produceGate, "^drawCard-") then
					if not gDrawPreviewMap[cardInfo.fragID] then
						canShow = false
					end
				end
				if canShow then
					table.insert(gainWayDatas, {target = produceGate, state = STATE.JUMP})
				end
			end
			self.tipText:set(fragmentsInfo.produceDesc)
		else
			table.insert(gainWayDatas, {text1 = gLanguageCsv.megaTitle, text2 = gLanguageCsv.megaHouse, cardId = cardId, target = 'cardMega-'..cardId})
		end

		local isShowTip = #gainWayDatas == 0
		self.isShowTip:set(isShowTip)
		self.gainWayDatas:update(gainWayDatas)

		local natureAttr = {}
		table.insert(natureAttr, unitInfo["natureType"])
		if unitInfo["natureType2"] then
			table.insert(natureAttr, unitInfo["natureType2"])
		end
		self.cardAttrs:update(natureAttr)
		self.textName:set(cardInfo.name or "")
	end)
	idlereasy.when(self.isShowTip, function(_, isShowTip)
		self.tip:visible(isShowTip)
		self.imgBG:visible(isShowTip)
	end)
end

function HandbookGainWayView:initModel()
	self.gateOpen = gGameModel.role:getIdler("gate_open") -- 开放的关卡列表
	self.cards = gGameModel.role:getIdler("pokedex")--卡牌
end

function HandbookGainWayView:onClick(node, v)
	jumpEasy.jumpTo(v.target)
end

return HandbookGainWayView


