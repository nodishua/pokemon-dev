-- @date:   2020-7-7
-- @desc:   通用多选一物品界面

local ChooseDetailView = class("ChooseDetailView", Dialog)

ChooseDetailView.RESOURCE_FILENAME = "common_choose_detail.json"
ChooseDetailView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["icon"] = {
		varname = "icon",
		binds = {
			event = "extend",
			class = "icon_key",
			props = {
				data = bindHelper.self("data"),
				noListener = true,
				onNode = function(node)
					local size = node:size()
					node:alignCenter(size)
				end,
			},
		},
	},
	["textNum"] = "textNum",
	["textName"] = "textName",
	["subList"] = "subList",
	["text"] = "text",
	["textTip"] = "textTip",
	["awardItem"] = "awardItem",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("awardItem"),
				columnSize = 5,
				onCell = function(list, node, k, v)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
							onNode = function(node)
								bind.click(list, node, {method = functools.partial(list.itemClick, node, k, v)})
							end,
						}
					})
				end,
				onAfterBuild = function(list)
				end
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick"),
			},
		},
	},
}

function ChooseDetailView:onCreate(params)
	Dialog.onCreate(self)
	self.subList:setScrollBarEnabled(false)
	self.itemDatas = idlers.newWithMap({})
	self.data = {key = params.key, num = params.num}
	local itemDatas = {}
	local number = 0
	local cfg = dataEasy.getCfgByKey(params.key)
	local myNum = dataEasy.getNumByKey(params.key)
	for k,v in csvMapPairs (cfg.specialArgsMap) do
		number = number + 1
		if not v.card then
			for k2,v2 in csvMapPairs(v) do
				table.insert(itemDatas, {key = k2, num = v2,  isSel = false})
			end
		end

		if v.card then
			for k2,v2 in csvMapPairs(v.card) do
				table.insert(itemDatas, {key = "card", num = v2,  isSel = false})
			end
		end
	end
	table.sort(itemDatas, dataEasy.sortItemCmp)
	self.itemDatas:update(itemDatas)

	self.textName:text(cfg.name)
	self.textNum:text(gLanguageCsv.have..":"..myNum)
	
	--自动调节背景大小，一行list5个，根据物品数量调节
	local longTimes = math.floor(number/5)
	longTimes = longTimes > 3 and 3 or longTimes
	local length = math.floor(self.list:height()/4)
	local lengthBg = (4 - longTimes - 1)*length
	self.bg:height(self.bg:height() - lengthBg)
	self.list:height(self.list:height() - lengthBg)
	self.list:y(self.list:y() + lengthBg/2)
	self.text:y(self.text:y() - lengthBg/2)
	self.textTip:y(self.textTip:y() - lengthBg/2)
	self.icon:y(self.icon:y() - lengthBg/2)
	self.textNum:y(self.textNum:y() - lengthBg/2)
	self.textName:y(self.textName:y() - lengthBg/2)
end

function ChooseDetailView:onItemClick(list, panel, k, v)
	gGameUI:showItemDetail(panel, {key = v.key, num = v.num})
end

return ChooseDetailView