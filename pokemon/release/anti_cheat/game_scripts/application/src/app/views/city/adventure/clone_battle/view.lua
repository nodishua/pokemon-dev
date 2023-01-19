-- @date:   2019-10-16
-- @desc:   克隆战(元素挑战)元素选取界面

local ViewBase = cc.load("mvc").ViewBase
local CloneBattleCityView = class("CloneBattleCityView", ViewBase)

CloneBattleCityView.RESOURCE_FILENAME = "clone_battle_city.json"
CloneBattleCityView.RESOURCE_BINDING = {
	["text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleShow")},
		}
	},
	["btnRule.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}, glow = {color = ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["btnShowList"] = {
		varname = "btnShowList",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("showSprList")},
		}
	},
	["btnShowList.text"] = {
		varname = "txtBtnShowList",
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}, glow = {color = ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["mainPanel"] = {
		varname = "mainPanel",
		binds = {
			event = "click",
			method = bindHelper.self("onSpaceClick"),
		},
	},
	["mainPanel.natureItem"] = "natureItem",
	["mainPanel.natureItem.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["mainPanel.showItem"] = "showItem",
	["mainPanel.showItem.btnRoom"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onCreateRoom")}
		},
	},
	["mainPanel.showItem.btnJoin"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onFastJoin")}
		},
	},
	["mainPanel.showItem.btnRoom.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["mainPanel.showItem.btnJoin.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["mainPanel.showItem.spr1.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["mainPanel.showItem.spr2.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["mainPanel.showItem.spr3.text"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.DEFAULT}},
		}
	},
	["cdPanel.textNote"] = "timeNote",
	["cdPanel.textTime"] = "textCd",
	["allPanel"] = "allPanel",
	["kickBg"] = "kickBg",
	["txt"] = "kickTxt",
}

local FMT1 = "effect2_%s_loop"
local FMT2 = "effect_%s_loop"

function CloneBattleCityView:onCreate(data, baseView)
	self.data = data
	self.curItemIdx = nil
	self.baseView = baseView
	--被踢之后显示
	self.kickNum = gGameModel.role:read("clone_daily_be_kicked_num")
	local beKickedNum = userDefault.getForeverLocalKey("cloneBattleBeKickedNum", 0)
	userDefault.setForeverLocalKey("cloneBattleBeKickedNum", self.kickNum, {new = true})
	if self.data.beKicked and self.kickNum < gCommonConfigCsv.cloneDailyBeKickedMax and self.kickNum > beKickedNum then
		gGameUI:showDialog({title = "", content = string.format("#C0x5b545b#"..gLanguageCsv.cloneBattleRecord8, gCommonConfigCsv.cloneDailyBeKickedMax - self.kickNum), btnType = 1, isRich = true})
	end
	self.pokedex = gGameModel.role:getIdler("pokedex")
	self.txtBtnShowList:getVirtualRenderer():setLineSpacing(-15)
	self.txtBtnShowList:y(self.txtBtnShowList:y() + 10)

	idlereasy.when(self.pokedex, function(_, pokedex)
		local tb = {}
		for cardId, time in pairs(pokedex) do
			local cardCsv = csv.cards[cardId]
			tb[cardCsv.cardMarkID] = true
		end
		self.pokedexMarks = tb
	end)

	local natureMap = {}
	for idx, tb in pairs(data.nature) do
		local t = {}
		for i, id in pairs(tb[2]) do
			local cardId = csv.clone.monster[id].cardID
			local csvCards = csv.cards[cardId]
			local unitId = csvCards.unitID
			local markId = csvCards.cardMarkID				-- 系列ID
			local config = csv.unit[unitId] or csv.unit[1]	-- 配表
			local inBox = self.pokedexMarks[markId]			-- 是否已获取

			t[i] = {
				cardId = cardId,
				unitId = unitId,
				markId = markId,
				config = config,
				inBox = inBox,
			}
		end
		natureMap[idx] = {
			natureId = tb[1],
			spriteTb = t,
		}
	end
	self.natureMap = natureMap


	self:initNatureItem()
	self:initCountDown()
	self:showKickTip()
end

function CloneBattleCityView:showKickTip()
	if self.kickNum and self.kickNum >= gCommonConfigCsv.cloneDailyBeKickedMax then
		local blackLayer = ccui.Layout:create()
		blackLayer:size(display.sizeInView)
		blackLayer:xy(display.board_left, 0)
		blackLayer:addTo(self.allPanel, 1, "__black_layer__")
		blackLayer:setBackGroundColorType(1)
		blackLayer:setBackGroundColor(cc.c3b(91, 84, 91))
		blackLayer:setBackGroundColorOpacity(0)
		blackLayer:setBackGroundColorOpacity(204)
		self.allPanel:show()
		self.kickBg:show()
		self.kickTxt:text(gLanguageCsv.cloneBattleRecord9)
	else
		self.allPanel:hide()
		self.kickBg:hide()
		self.kickTxt:hide()
	end
end

-- 点击空白处
function CloneBattleCityView:onSpaceClick()
	local showItem = self.showItem
	showItem:hide()
	self.curItemIdx = nil
	if self.aniTb then			-- 修改上一个的动画为普通动画
		self.aniTb.ani:play(string.format(FMT2, self.aniTb.natureId))
		self.aniTb = nil
		self.baseView:playBgAni(nil)
	end
end

-- 点击房间按钮
function CloneBattleCityView:onItemClick(node, k, v)
	local showItem = self.showItem
	local size = node:size()
	showItem:retain()
	showItem:removeFromParent()
	node:add(showItem, 999)
	showItem:xy(size.width / 2, size.height / 2 - 50)
	showItem:show()

	local children = showItem:multiget("spr1", "spr2", "spr3")

	local count = 0
	for i = 1, 3 do
		local tb = v.spriteTb[i]
		local item = children["spr"..i]
		item:visible(tb and true or false)
		if tb then
			local imgItem = item:get("img")
			imgItem:texture(tb.config.iconSimple)

			local shaderString = tb.inBox and "normal" or "hsl_gray"
			if tb.inBox then count = count + 1 end
			cache.setShader(imgItem, false, shaderString)
			cache.setShader(item, false, shaderString)

			local textItem = item:get("text")
			textItem:text(tb.config.name)
		end
	end

	self.curItemCount = count
	self.curItemIdx = k

	if self.aniTb then			-- 修改上一个的动画为普通动画
		self.aniTb.ani:play(string.format(FMT2, self.aniTb.natureId))
	end
	self.aniTb = node.aniTb
	-- 将当前item动画改为 选中动画
	self.aniTb.ani:play(string.format(FMT1, self.aniTb.natureId))
	self.baseView:playBgAni(self.aniTb.natureId)
end

-- 创建房间按钮
function CloneBattleCityView:onCreateRoom()
	if not self.curItemCount or self.curItemCount <= 0 then
		gGameUI:showTip(gLanguageCsv.noNature)
		return
	end
	gGameApp:requestServer("/game/clone/room/create", function (tb)
		self.baseView:refreshView()
	end, self.natureMap[self.curItemIdx].natureId)
end

-- 快速加入按钮
function CloneBattleCityView:onFastJoin()
	if not self.curItemCount or self.curItemCount <= 0 then
		gGameUI:showTip(gLanguageCsv.noNature)
		return
	end
	gGameApp:requestServer("/game/clone/room/join/fast", function (tb)
		self.baseView:refreshView()
	end, self.natureMap[self.curItemIdx].natureId)
end

-- item的位置由客户端写死
local ITEM_POS = {
	[1] = cc.p(680,770),-- 左上
	[2] = cc.p(1890,780),-- 右上
	[3] = cc.p(520,355),-- 左下
	[4] = cc.p(2080,365),-- 右下
	[5] = cc.p(1280,610),-- 中间
}
function CloneBattleCityView:initNatureItem()
	local count = #ITEM_POS
	for i, pos in pairs(ITEM_POS) do
		local item = self.natureItem:clone()
		self.mainPanel:add(item, count - i)
		item:xy(pos)

		local natureTb = self.natureMap[i]
		if natureTb then
			local natureId = natureTb.natureId
			local size = item:size()
			local res = csv.clone.nature[natureTb.natureId].spine
			local scaleNum = i <= 2 and 1.74 or 2
			local ani = widget.addAnimation(item, res, string.format(FMT2, natureId), 1)
				:scale(scaleNum)
				:xy(size.width / 2, 10)
			item.aniTb = {
				ani = ani,
				natureId = natureId,
			}

			local textItem = item:get("text")
			textItem:text(gLanguageCsv[game.NATURE_TABLE[natureId]]..gLanguageCsv.talentElement)
			text.addEffect(textItem, {color = ui.COLORS.ATTR[natureId]})

			bind.touch(self, item, {methods = {ended = functools.partial(self.onItemClick, self, item, i, natureTb)}})
		else
			-- 没有这个元素 这里往往是 第五个元素的处理
			item:hide()
		end
	end
end

-- 显示今日精灵列表
function CloneBattleCityView:showSprList()
	local posX, posY = self.btnShowList:xy()
	gGameUI:stackUI("city.adventure.clone_battle.spr_list", nil, nil, self.natureMap, posX, posY)
end

-- 规则按钮
function CloneBattleCityView:onRuleShow()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function CloneBattleCityView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.cloneBattleRuleTitle)
		end),
		c.noteText(111),
		c.noteText(62001, 62010),
	}
	return context
end

function CloneBattleCityView:initCountDown( )
	local textTime = self.textCd
	local today = time.getTodayStrInClock(12)
	local endStamp = time.getNumTimestamp(today, 12) + 24 * 3600
	local function setLabel()
		local remainTime = time.getCutDown(endStamp - time.getTime())
		textTime:text(remainTime.str)
		adapt.oneLinePos(self.timeNote, textTime, cc.p(5,0))
		if endStamp - time.getTime() <= 0 then
			self.baseView:refresh()
			today = time.getTodayStrInClock(12)
		end
		return true
	end
	self:enableSchedule()
	self:schedule(function(dt)
		if not setLabel() then
			return false
		end
	end, 1, 0, 1)
end

return CloneBattleCityView







