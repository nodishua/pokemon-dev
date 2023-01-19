-- @date 2021-01-29
-- @desc 日常小助手钓鱼场景选择界面

local FishingSelectView = class('FishingSelectView', Dialog)
FishingSelectView.RESOURCE_FILENAME = 'daily_assistant_fishing_select.json'

FishingSelectView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas"),
				columnSize = 2,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					local childs = node:multiget("imgSelect", "pos", "maskPanel", "title")
					childs.imgSelect:visible(v.selected)
					childs.title:text(v.name)
					local isShowMask = v.myLv < v.needLv or v.lock == 0
					childs.maskPanel:visible(isShowMask)
					childs.pos:removeAllChildren()
					local mask1 = ccui.Scale9Sprite:create()
					mask1:initWithFile(cc.rect(50, 50, 1, 1), "city/adventure/fishing/mask_dy_bgpre.png")
					mask1:size(cc.size(770, 410))
					local clippingNode = cc.ClippingNode:create(mask1)
						:setAlphaThreshold(0.1)
						:addTo(childs.pos, 1, "clippingNode")
					widget.addAnimationByKey(clippingNode, v.res, 'diaoyuBg', "effect_loop", 1)
						:scale(0.6)
					bind.click(list, node, {method = functools.partial(list.itemClick, k, v)})
				end,
				onAfterBuild = function (list)
					list:setItemAlignCenter()
				end
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["btnBag"] = {
		varname = "btnBag",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnBagClick")}
		},
	},
}

function FishingSelectView:onCreate()
	Dialog.onCreate(self)
	self:initModel()

	local btnDatas = {}
	for k, v in csvPairs(csv.fishing.scene) do
		if v.type == 1 then
			btnDatas[k] = {
				csvId = k,
				name = v.name,
				res = v.res,
				-- type = v.type,
				needLv = v.needLv,
				-- priview = v.priview,
				lock = v.lock,
				myLv = self.fishLevel:read(),
				selected = false,
				sort = 0,
			}
		end
	end
	-- print_r(btnDatas)
	self.itemDatas = idlers.newWithMap(btnDatas)
	self.selectScene = idler.new((self.fishingSelectScene:read() == 0 or self.fishingSelectScene:read() == 999) and 1 or self.fishingSelectScene:read())

	self.selectScene:addListener(function(val, oldval)
		if val == nil then return end
		if oldval and self.itemDatas:atproxy(oldval) then
			self.itemDatas:atproxy(oldval).selected = false
		end
		self.itemDatas:atproxy(val).selected = true
		-- 发选择场景消息
		gGameApp:requestServer("/game/fishing/prepare", function(tb)
			end, "scene", val)
	end)
end


-- 场景遮罩图片
function FishingSelectView:initBgMask()
	self.mask1 = ccui.Scale9Sprite:create()
	self.mask1:initWithFile(cc.rect(50, 50, 1, 1), "city/adventure/fishing/mask_dy_bgpre.png")
	self.mask1:size(cc.size(1858, 888))
	local clippingNode = cc.ClippingNode:create(self.mask1)
		:setAlphaThreshold(0.1)
		:addTo(self.scenePanel:get("pos"), 1, "clippingNode")
end

-- 点击item
function FishingSelectView:onItemClick(list, k, v)
	-- 判断是否解锁场景
	if v.lock == 0 then
		gGameUI:showTip(gLanguageCsv.pleaseWaitOpen)
		return
	end
	if v.myLv < v.needLv then
		gGameUI:showTip(string.format(gLanguageCsv.fishingLvNotEnoughEnterScene, v.needLv))
		return
	end
	self.selectScene:set(v.csvId)
end

-- 钓鱼背包
function FishingSelectView:onBtnBagClick()
	gGameUI:stackUI("city.adventure.fishing.bag", nil, nil, 1, self.selectScene:read())
end

function FishingSelectView:initModel()
	self.fishingSelectScene = gGameModel.fishing:getIdler("select_scene")
	self.fishLevel = gGameModel.fishing:getIdler("level")
	-- self.partner = gGameModel.fishing:getIdler("partner")
	-- self.items = gGameModel.role:getIdler("items")
	-- self.selectRod = gGameModel.fishing:getIdler("select_rod")
	-- self.selectBait = gGameModel.fishing:getIdler("select_bait")
	-- self.selectPartner = gGameModel.fishing:getIdler("select_partner")
	-- self.pokedex = gGameModel.role:getIdler("pokedex")--卡牌
	-- self.rmb = gGameModel.role:getIdler("rmb")
	-- self.gold = gGameModel.role:getIdler("gold")
	-- self.isAuto = gGameModel.fishing:getIdler("is_auto")
end

return FishingSelectView