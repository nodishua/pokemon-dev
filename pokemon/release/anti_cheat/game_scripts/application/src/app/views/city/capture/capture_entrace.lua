

local SPRITE_BALL_ID = {
	normal = 523,
	hero = 524,
	nightmare = 525,
}

local CaptureView = class("CaptureView", Dialog)

CaptureView.RESOURCE_FILENAME = "common_capture_popup.json"
CaptureView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["spritXq"] = {
		varname = "captureBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("captureMenuBtn")}
		},
	},
	["returnBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["confirm"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCaptureBtnClick")}
		},
	},
	["spritXq.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["titleName"] = "titleName",
	["titleName.name"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["icon.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["animain"] = "animain",
	["txtTimeNumber"] = "txtTimeNumber",
	["txtTimeNumber.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 2}}
		}
	},
	["txtTimeNumber.txtNumber"] = {
		varname = "txtNumber",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE, size = 2}}
		}
	},
	["txtTimeNumber.txt2"] = {
		varname = "txt2",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["txtTimeNumber.txtTime"] = {
		varname = "txtTime",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.NORMAL.WHITE}}
		}
	},
	["attrTmp"] = "attrTmp",
	["upList"] = {
		varname = "upList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("cardAttrs"),
				item = bindHelper.self("attrTmp"),
				onItem = function(list, node, k, v)
					local path = ui.ATTR_ICON[v]
					node:get("imgIcon"):texture(path)
				end,
			},
		},
	},
}

function CaptureView:initModel()
	self.cards = gGameModel.role:read("cards")
	self.cardCapacity = gGameModel.role:read("card_capacity")
	self.captureNumber = gGameModel.role:getIdler("items")
	self.gold = gGameModel.role:getIdler("gold")
	self.level = gGameModel.role:getIdler("level")
	self.limitSprites = gGameModel.capture:getIdler("limit_sprites")
end

function CaptureView:onCreate(parms)
	--tab是传过来的sprit中的信息，gateId：如果是关卡就传关卡id如果是限时
	--就传限时信息
	self.item = parms.node
	self.tabId = parms.captureID		-- 捕捉ID
	self.captureData = parms.captureData-- 展示的精灵数据
	self.limitData = parms.limitData 	-- 限时捕捉数据
	self:initModel()
	self.cardAttrs = idlertable.new({})
	local cardId = parms.captureData.cardID
	local unitCsv = csv.unit[csv.cards[cardId].unitID]

	--捕捉入口进有时间标签，战斗入口进没有
	if self.limitData then
		self.txtTimeNumber:show()
		--捕捉次数
		idlereasy.when(self.limitSprites, function(_, limitSprites)
			for k, v in pairs(limitSprites) do
				if self.tabId == k - 1  then
					self.totalTimes = csv.capture.sprite[self.limitData.csv_id].totalTimes
					self.txtNumber:text((self.totalTimes - v.total_times).."/"..self.totalTimes)
					self.limitData = v
				end
			end
		end)

		local function setLabel()
			--剩余时间
			local endTime = self.limitData.find_time + csv.capture.sprite[self.limitData.csv_id].time
			local remainTime = time.getCutDown(endTime - time.getTime())
			self.txtTime:text(remainTime.str)
			self.txt2:x(self.txtTime:x() - self.txtTime:size().width -10)
			if endTime - time.getTime() <= 0 then
				self:onClose()
				return false
			end
			return true
		end
		self:enableSchedule()
		self:schedule(function(dt)
			return setLabel()
		end, 1, 0)
	else
		self.txtTimeNumber:hide()
	end

	local animaScale = unitCsv.scale * gCommonConfigCsv.captureSprite
	local cardSprite = widget.addAnimation(self.animain, unitCsv.unitRes, "standby_loop", 5)
		:alignCenter(self.animain:size())
		:scale(animaScale)
	cardSprite:setSkin(unitCsv.skin)
	self.animain:y(self.animain:y()-180)

	local natureAttr = {}

	table.insert(natureAttr, unitCsv["natureType"])
	if unitCsv["natureType2"] then
		table.insert(natureAttr, unitCsv["natureType2"])
	end
	self.cardAttrs:set(natureAttr)

	self.titleName:get("name"):text(csv.cards[cardId].name)
	self.titleName:get("iconLeft"):texture(ui.RARITY_ICON[unitCsv.rarity])
	Dialog.onCreate(self)
end

-- --精灵详情
function CaptureView:captureMenuBtn()
	local parms = {cardId = self.captureData.cardID}
	gGameUI:stackUI("city.handbook.view", nil, nil, parms)
end

function CaptureView:onCaptureBtnClick()
	self:initModel()
	--捕捉精灵次数用尽
	if self.captureData.type == 2 and self.totalTimes == self.limitData.total_times then
		gGameUI:showTip(gLanguageCsv.captureSceneTimesNotEnough)
		return
	end
	-- 背包容量限定
	if self.cardCapacity - itertools.size(self.cards) <= 0 then
		gGameUI:showDialog{content = gLanguageCsv.cardBagHaveBeenFullDraw, cb = function()
			gGameUI:stackUI("city.card.bag", nil, {full = true})
		end, btnType = 2, clearFast = true}
		return
	end

	local data = 0
	for i,v in pairs(SPRITE_BALL_ID) do
		if not self.captureNumber:read()[SPRITE_BALL_ID[i]] or self.captureNumber:read()[SPRITE_BALL_ID[i]] <= 0 then
			data = data + 1
		end
	end
	if data == 3 then
		gGameUI:showTip(gLanguageCsv.captureBallNotEnough)
		--购买框
		local gold = csv.items[SPRITE_BALL_ID.normal].specialArgsMap.buy_gold
		local maxBuyNum = 100
			gGameUI:stackUI("common.buy_info", nil, nil,
				{gold = gold},
				{id = SPRITE_BALL_ID.normal},
				{maxNum = maxBuyNum, contentType = "num"},
				self:createHandler("showBuyInfo")
			)
		return
	end
	-- --self.gateId关卡id
	gGameApp:requestServer("/game/capture/enter", function(tb)
		gGameUI:stackUI("city.capture.capture_sprite", nil, nil,
			self.captureData,
			self.tabId,
			self:createHandler("captureReturnBtnView"))
	end, self.captureData.type, self.tabId)
end

function CaptureView:showBuyInfo(data)
	--等级是否满足购买道具
	if csv.items[SPRITE_BALL_ID.normal].specialArgsMap.buy_level > self.level:read() then
		gGameUI:showTip(gLanguageCsv.buyItemLevelLimit)
		return
	else
		gGameApp:requestServer("/game/ball/buy_item", function(tb)
			gGameUI:showTip(gLanguageCsv.hasBuy)
		end, SPRITE_BALL_ID.normal, data)
	end
end

function CaptureView:captureReturnBtnView(data)
	if self.item and not data then
		self.item:removeFromParent()
	end
	self:onCloseFast()
end

return CaptureView


