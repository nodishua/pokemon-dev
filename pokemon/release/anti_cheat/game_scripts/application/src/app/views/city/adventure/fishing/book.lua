-- @date 2020-07-01
-- @desc 钓鱼图鉴

local FishingBookView = class('FishingBookView', Dialog)
FishingBookView.RESOURCE_FILENAME = 'fishing_book.json'

FishingBookView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["left.item"] = "item",
	["left.subList"] = "subList",
	["left.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas"),
				columnSize = 4,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				leftPadding = 10,
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "fish_icon",
						props = {
							data = {
								key = v.key,
							},
							onNode = function(node)
								node:align(cc.p(0.5, 0.5), 85, 85)
								if v.selectEffect then
									v.selectEffect:removeSelf()
									v.selectEffect:align(cc.p(0.5, 0.5), 90, 90)
									node:add(v.selectEffect, -1)
								end
							end,
						},
					})
					bind.click(list, node, {method = functools.partial(list.itemClick, v)})
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
	["right"] = "right",
}

function FishingBookView:onCreate(showTab)
	self:initModel()

	-- 选中标记创建
	self.selectEffect = ccui.ImageView:create("common/box/box_selected.png")
		:alignCenter(self.item:size())
		:retain()

	self.itemDatas = idlers.new({})
	self.selectItem = idler.new(1)

	idlereasy.when(self.fish, function(_, fish)
		local itemDatas = {}
		for k,v in csvPairs(csv.fishing.fish) do
			if v.bookId ~= 0 then
				itemDatas[k] = {
					key = k,
					name = v.name,
					point = v.point,
					needLv = v.needLv,
					desc = v.desc,
					rare = v.rare,
					bookId = v.bookId,
					counter = fish[k] and fish[k].counter or 0,
					bigCounter = fish[k] and fish[k].big_counter or 0,
					lenghtMax = fish[k] and fish[k].length_max or 0,
				}
			end
		end
		self.itemDatas:update(itemDatas)
	end)

	self.selectItem:addListener(function(val, oldval)
		local data = self.itemDatas:atproxy(val)
		if data then
			data.selectEffect = self.selectEffect
			self:resetShowPanel(data)
		end
	end)

	Dialog.onCreate(self)
end

function FishingBookView:resetShowPanel(data)
	-- 图标
	bind.extend(self, self.right, {
		class = "fish_icon",
		props = {
			data = {
				key = data.key,
			},
			onNode = function(node)
				node:align(cc.p(0.5, 0.5), self.right:get("icon"):x() - 20, self.right:get("icon"):y() - 15)
					:scale(1.4)
			end,
		},
	})
	-- 名字
	self.right:get("name"):text(data.name)
	-- 品质
	local quality = {gLanguageCsv.lowFish, gLanguageCsv.middleFish, gLanguageCsv.highFish}
	self.right:get("quality"):text(quality[data.rare])
	-- 积分
	self.right:get("point1"):text(data.point)
	adapt.oneLinePos(self.right:get("point"), self.right:get("point1"), cc.p(15, 0), "left")
	-- 等级
	self.right:get("level1"):text("Lv."..data.needLv)
	adapt.oneLinePos(self.right:get("level"), self.right:get("level1"), cc.p(20, 0), "left")
	-- 描述list
	beauty.textScroll({
		list = self.right:get("list"),
		strs = "#C0x5B545B#" .. data.desc,
		isRich = true,
	})
	-- 总次数
	self.right:get("totalNum"):text(string.format(gLanguageCsv.fishCounter, data.counter))
	-- 大鱼次数
	self.right:get("bigFishNum"):text(string.format(gLanguageCsv.bigFishCounter, data.bigCounter))
	-- 最大尺寸
	self.right:get("maxNum"):text(string.format(gLanguageCsv.fishLenghtMax, data.lenghtMax))
end

-- 点击item
function FishingBookView:onItemClick(list, v)
	-- 选择的item
	self.selectItem:set(v.key)
end

function FishingBookView:initModel()
	self.fish = gGameModel.fishing:getIdler("fish")
end

return FishingBookView