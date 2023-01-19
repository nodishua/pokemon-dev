
local GET_TYPE = {
	GOTTEN = 0, 	--已领取
	CAN_GOTTEN = 1, --可领取
	CAN_NOT_GOTTEN = 2, --未完成
}
local pos = {
	[1] = {[1] = cc.p(200, 200)},
	[2] = {[1] = cc.p(200, 300), [2] = cc.p(200, 100)},
	[3] = {[1] = cc.p(200, 300), [2] = cc.p(100, 100), [3] = cc.p(300, 100)},
	[4] = {[1] = cc.p(100, 300), [2] = cc.p(300, 300), [3] = cc.p(100, 100), [4] = cc.p(300, 100)},
}

local cardShowInfo = {
	[393] = {--耿鬼
		scale = 2.5,
		rot = 0,
		pos = cc.p(554,846),
		dayFileName= "activity/new_player_welfare/num_3.png",
		nameFileName = "activity/new_player_welfare/txt_gg.png"
	},
	[771] = {--梦幻
		scale = 3,
		rot = 20,
		pos = cc.p(600,725),
		dayFileName = "activity/new_player_welfare/num_7.png",
		nameFileName = "activity/new_player_welfare/txt_mh.png"
	},
}
local ActivityNewPlayerWelfareDialog = class("ActivityNewPlayerWelfareDialog", Dialog)
ActivityNewPlayerWelfareDialog.RESOURCE_FILENAME = "activity_new_player_welfare.json"
ActivityNewPlayerWelfareDialog.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["textToday1"] = "textToday1",
	["textTodayNum"] = {
		varname = "textTodayNum",
		binds = {
			{
				event = "text",
				idler = bindHelper.self("daySum"),
			},{
				event = "effect",
				data = {shadow = {color = cc.c4b(242, 102, 64, 255), offset = cc.size(0,-4), size = 4}},
			},
		}
	},
	["textToday"] = {
		varname = "textToday",
		binds = {
			{
				event = "effect",
				data = {shadow = {color = cc.c4b(242, 102, 64, 255), offset = cc.size(0,-4), size = 4}},
			},
		}
	},
	["item"] = "item",
	["iconItem"] = "iconItem",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("itemsData"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					list.initItem(node, k, v)
				end,
				asyncPreload = 4,
			},
			handlers = {
				initItem = bindHelper.self("initItem"),
			},
		},
	},
	["imgRarity"] = "imgRarity",
	["imgAttr1"] = "imgAttr1",
	["imgAttr2"] = "imgAttr2",
	["imgSpriteShow"] = "imgSpriteShow",
	["ImageActivity.imgSptireName"] = "imgSptireName",
	["ImageActivity.imgTotalDay"] = "imgTotalDay"

}
function ActivityNewPlayerWelfareDialog:onCreate(activityId)
	Dialog.onCreate(self,{blackType = 1})
	self.activityId = activityId
	self:initModel()
	self:initUI()
	gGameModel.currday_dispatch:getIdlerOrigin("newPlayerWeffare"):set(true)
end
-- 初始化model
function ActivityNewPlayerWelfareDialog:initModel()
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.daySum = idler.new(0)
	self.loginwealData = {}
	self.itemsData = idlertable.new({})
	local yyCfg = csv.yunying.yyhuodong[self.activityId]
	local huodongID = yyCfg.huodongID

	for k, v in csvPairs(csv.yunying.loginweal) do
		if v.huodongID == huodongID then
			self.loginwealData[v.daySum] = {award =  v.award, id = k}
		end
	end
end
--初始化界面
function ActivityNewPlayerWelfareDialog:initUI()
	idlereasy.when(self.yyhuodongs,function(_, yyhuodong)
		local yydata = yyhuodong[self.activityId]
		local itemsData = {}
		for daySum, wealData in pairs(self.loginwealData) do
			if daySum > yydata.info.daysum then
				itemsData[daySum] = {award = wealData.award, id = wealData.id, getType = GET_TYPE.CAN_NOT_GOTTEN}
			else
				itemsData[daySum] = {award = wealData.award, id = wealData.id, getType = yydata.stamps[wealData.id]}
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.itemsData:set(itemsData)
		self.daySum:set(yydata.info.daysum)
	end)
	self:initLeftSprite()
	adapt.oneLinePos(self.textToday1, {self.textTodayNum, self.textToday} ,cc.p(5,0), "right")
end

--初始化左侧大奖
function ActivityNewPlayerWelfareDialog:initLeftSprite()
	local csvCfg = csv.yunying.yyhuodong[self.activityId]
	if self.daySum:read() <= 3 then
		self.showCardId = csvCfg.clientParam.cardId1
	else
		self.showCardId = csvCfg.clientParam.cardId2
	end

	local cardCsv = csv.cards[self.showCardId]
	local unitCsv = csv.unit[cardCsv.unitID]
	local rarity = unitCsv.rarity
	local name = unitCsv.name
	local attr1 = unitCsv.natureType
	local attr2 = unitCsv.natureType2

	-- 品质
	self.imgRarity:texture(ui.RARITY_ICON[rarity])
	-- 种类
	self.imgAttr1:texture(ui.ATTR_ICON[attr1])
	if attr2 == nil then
		self.imgAttr2:hide()
	else
		self.imgAttr2:texture(ui.ATTR_ICON[attr2]):show()
	end
	-- 立绘
	local cardShow = unitCsv.cardShow
	local info = cardShowInfo[self.showCardId]
	self.imgSpriteShow:texture(cardShow)
		:xy(info.pos.x + display.uiOrigin.x, info.pos.y)
		:scale(info.scale)
		:setRotation(info.rot)
	--其他
	self.imgTotalDay:texture(info.dayFileName)
	self.imgSptireName:texture(info.nameFileName)
end
--初始化list的item
function ActivityNewPlayerWelfareDialog:initItem(list, node, k, itemData)
	local childs = node:multiget("textDay", "btnGet", "textGotten","imgGift","iconPanel")
	-- 天数
	local dayNum = childs.textDay:setString(k)

	--奖励
	local awards = itemData.award
	local awardCount = itertools.size(awards)
	local k = 0
	childs.iconPanel:removeAllChildren()
	for award, num in pairs(awards) do
		k = k + 1
		local position = pos[awardCount][k]
		local cell = self.iconItem:clone()
		cell:addTo(childs.iconPanel)
		cell:show()
		cell:xy(position.x, position.y)
		local binds = {
			class = "icon_key",
			props = {
				data = {
					key = award,
					num = num,
				},
			},
		}
		bind.extend(self, cell, binds)
	end

	--按钮限时处理
	if itemData.getType == GET_TYPE.CAN_NOT_GOTTEN then
		-- 未达成
		childs.btnGet:get("textGet"):hide()
		childs.btnGet:get("textNotGet"):show()
		childs.btnGet:setEnabled(false)
		childs.btnGet:opacity(255*0.4)
		childs.imgGift:hide()
		childs.textGotten:hide()
		adapt.setTextScaleWithWidth(childs.btnGet:get("textNotGet"), childs.btnGet:get("textNotGet"):text(), 200)
	elseif itemData.getType == GET_TYPE.CAN_GOTTEN then
		-- 可领取
		childs.btnGet:get("textGet"):show()
		childs.btnGet:get("textNotGet"):hide()
		childs.btnGet:setEnabled(true)
		childs.btnGet:opacity(255)
		childs.imgGift:hide()
		childs.textGotten:hide()
		adapt.setTextScaleWithWidth(childs.btnGet:get("textGet"), childs.btnGet:get("textGet"):text(), 200)
	elseif itemData.getType == GET_TYPE.GOTTEN then
		--已领取
		childs.btnGet:hide()
		childs.textGotten:show()
		childs.imgGift:show()
	end

	bind.touch(self, childs.btnGet, {methods = { ended = functools.partial(self.sendGetAward, self, itemData.id)}})
end
-- 发送领取
function ActivityNewPlayerWelfareDialog:sendGetAward(id)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityId,id)
end

return ActivityNewPlayerWelfareDialog

