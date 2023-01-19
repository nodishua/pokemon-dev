--公会战排名界面
local ViewBase = cc.load("mvc").ViewBase
local UnionRankView = class("UnionRankView", Dialog)

local unionRankTexture = "city/union/union_fight/part3/btn_1.png"
local oneSelfTexture = "city/union/union_fight/part3/btn_2.png"
local textureTab = {"city/union/union_fight/part3/icon_1.png", "city/union/union_fight/part3/icon_2.png", "city/union/union_fight/part3/icon_3.png"}

UnionRankView.RESOURCE_FILENAME = "union_rank.json"
UnionRankView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["leftitem"] = "leftitem",
	["leftLsit"] = {
		varname = "leftList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDate"),
				item = bindHelper.self("leftitem"),
				asyncPreload = 5,
				onItem = function(list, node, k, v)
					if v.select then
						node:get("btn"):visible(true)
						node:get("btn"):get("title"):text(v.text)
						text.addEffect(node:get("btn"):get("title"), {outline={color=(cc.c4b(59, 51, 59, 255))}})
					else
						node:get("btn"):visible(false)
					end
					node:get("name"):text(v.text)
					node:get("name"):setOpacity(178)
					text.addEffect(node:get("name"), {outline={color=(cc.c4b(255, 252, 237, 255)), size = 2}})
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("clickBtn"),
			},
		},
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rankDate"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true, alwaysShow = true},
				asyncPreload = 5,
				onItem = function(list, node, k, v)
					if k <= 3 then
						node:get("rank"):texture(textureTab[k])
						node:get("randNum"):hide()
					else
						node:get("rank"):hide()
						node:get("randNum"):text(k)
						text.addEffect(node:get("randNum"), {outline={color=(cc.c4b(48, 31, 3, 255))}})
					end
					node:get("name"):text(v.name)
					node:get("zdl"):text(v.point)
					local bgOpacity = k % 2 == 0 and 153 or 77
					node:get("bg"):setOpacity(bgOpacity)
					if not v.isUnion then
						local props = {
							event = "extend",
							class = "role_logo",
							props = {
								logoId = v.logo,
								level = false,
								vip = false,
								frameId = v.frame,
								onNode = function(node)
									node:xy(50, 50)
										:z(6)
										:scale(0.8)
								end,
							}
						}
						node:get("icon"):get("iconbg"):hide()
						node:get("icon"):get("iconbg2"):hide()
						bind.extend(list, node:get("icon"):get("icon"), props)
						node:get("icon"):get("iconbg"):hide()
					else
						node:get("icon"):get("iconbg"):show()
						node:get("icon"):get("icon"):removeAllChildren()
						node:get("icon"):get("iconbg"):texture(csv.union.union_logo[v.logo].icon)
						node:get("icon"):get("iconbg"):setScale(1.8)
						node:get("icon"):get("iconbg2"):setScale(0.47)
						node:get("icon"):get("iconbg2"):setOpacity(178)
					end
					node:get("icon"):get("level"):text(v.level)
					local positionX = node:get("icon"):get("level"):x()
					local width = node:get("icon"):get("level"):width()
					node:get("icon"):get("level"):x(positionX - width/2)
					node:get("icon"):get("txt"):x(node:get("icon"):get("txt"):x() - width/2)
					text.addEffect(node:get("icon"):get("txt"), {outline={color=(cc.c4b(108, 82, 49, 255))}})
					text.addEffect(node:get("icon"):get("level"), {outline={color=(cc.c4b(108, 82, 49, 255))}})
					node:get("icon"):setTouchEnabled(false)
				end,
			},
		},
	},
	["down"] = "down",
	["up.icon1"] = {
		varname = "icon1",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("unionRankFunc")}
		},
	},
	["up.icon2"] = {
		varname = "icon2",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("oneSelfFunc")}
		},
	},
	["up.icon3"] = "icon3",
	["up.icon3.name"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(255, 243, 224, 255)}}
			},
		}
	},
	["up.icon2.name"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(255, 243, 224, 255)}}
			},
		}
	},
	["up.icon1.name"] = {
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c4b(188, 125, 74, 255)}}
			},
		}
	},
	["bg404"] = "bg404",
	["bg2"] = "bg2",
}

function UnionRankView:onCreate( ... )
	self.item:visible(false)
	self.leftitem:visible(false)
	self.bg404:visible(false)
	self.bg2:visible(false)
	self.down:visible(false)
	self:initModel()
	self:updatePenal()

	self.paging:addListener(function(val, oldval, idler)
		self.leftDate:atproxy(oldval).select = false
		self.leftDate:atproxy(val).select = true
	end)

	Dialog.onCreate(self)
end

function UnionRankView:updatePenal()
	--# 数据太大分开拿
	--# 8总数据，然后从2开始,2是第-轮,3是第二轮...
	gGameApp:requestServer("/game/union/fight/rank", function(data)
		for k,v in csvMapPairs(data.view) do
			self.unionDateTab[k] = v.union_rank
			self.oneSelfDateTab[k] = v.role_rank
			self.oneSelfUnion[k] = v.my_union_rank
			self.oneSelf[k] = v.my_rank
		end
		self.unionDateTab[8] = self.unionDateTab[8] or {}
		for _, v in pairs(self.unionDateTab[8]) do
			v.isUnion = true
		end
		self.rankDate:update(self.unionDateTab[8])
		local size = itertools.size(self.unionDateTab[8])
		self:executeDate(self.oneSelfUnion, size, true)

		self.bg404:visible(itertools.size(self.unionDateTab[8]) == 0)
		self.bg2:visible(itertools.size(self.unionDateTab[8]) == 0)
		self.down:visible(itertools.size(self.unionDateTab[8]) ~= 0)

	end)
end

function UnionRankView:initModel( ... )
	self.rankDate = idlers.new({})
	self.rank = 2							--# 刚进来默认是公会排名
	self.paging = idler.new(1) 				--# 左边切页默认第一个
	self.unionDateTab = {}					--# 公会数据总数
	self.oneSelfDateTab = {}				--# 个人数据总数据
	self.oneSelfUnion = {}					--# 公会中的个人
	self.oneSelf = {}						--# 个人中的个人
	self.name = gGameModel.role:read("name")
	self.unName = gGameModel.union:read("name")
	self.icon3:hide()

	self.leftDate = idlers.newWithMap({
		{text = gLanguageCsv.allRank, id = 1},
		{text = gLanguageCsv.firstRound, id = 2},
		{text = gLanguageCsv.theSecondRound, id = 3},
		{text = gLanguageCsv.thridRound, id =4},
		{text = gLanguageCsv.theFourthRoundOf, id = 5},
		{text = gLanguageCsv.BattleLine, id = 6},
	})
end

--刚进来默认显示的数据
function UnionRankView:executeDate(date, size, info)
	local pagings = self.paging:read()
	local star = pagings
	if pagings == 1 then
		star = 8
	end
	if not date[star][1] or date[star][1] > size or size == 0 or date[star][1] == 0 then
		self.down:get("wsb"):text(gLanguageCsv.noRank)
	else
		self.down:get("wsb"):text(date[star][1])
	end
	local name = info and self.unName or self.name
	self.down:get("name"):text(name)
	self.down:get("zdl"):text(date[star][2])
end

--# 公会排名
function UnionRankView:unionRankFunc( ... )
	self.rank = 2
	local pagings = self.paging:read()
	self.icon3:hide()
	self.icon1:setOpacity(255)
	self.icon2:texture(oneSelfTexture)
	self:outlinePanel(self.icon1, self.icon2)
	pagings = pagings == 1 and 8 or pagings
	local date = self.unionDateTab[pagings] or {}
	for _, v in pairs(date) do
		v.isUnion = true
	end
	self.rankDate:update(date)
	local size = itertools.size(date)
	self:executeDate(self.oneSelfUnion, size, true)
	self.bg404:visible(itertools.size(date) == 0)
	self.bg2:visible(itertools.size(date) == 0)
	self.down:visible(itertools.size(date) ~= 0)
end
--# 个人排名
function UnionRankView:oneSelfFunc( ... )
	self.rank = 1
	local pagings = self.paging:read()
	self.icon3:show()
	self.icon1:setOpacity(0)
	self.icon2:texture(unionRankTexture)
	self:outlinePanel(self.icon2, nil)
	pagings = pagings == 1 and 8 or pagings
	local date = self.oneSelfDateTab[pagings] or {}
	self.rankDate:update(date)
	local size = itertools.size(date)
	self:executeDate(self.oneSelf, size, false)
	self.bg404:visible(itertools.size(date) == 0)
	self.bg2:visible(itertools.size(date) == 0)
	self.down:visible(itertools.size(date) ~= 0)
end
function UnionRankView:outlinePanel(item1, item2)
	if item1 then
		item1:get("name"):setTextColor(cc.c4b(253, 247, 229, 255))
		text.addEffect(item1:get("name"), {outline={color=cc.c4b(188, 125, 74, 255)}})
	end
	if item2 then
		item2:get("name"):setTextColor(cc.c4b(202, 130, 84, 255))
		text.addEffect(item2:get("name"), {outline={color=cc.c4b(255, 243, 224, 255)}})
	end
end

--切页
function UnionRankView:clickBtn(list, k, v)
	if v.id ~= self.paging:read() then
		self.paging:set(v.id)
		if self.rank == 1 then
			self:oneSelfFunc()
		else
			self:unionRankFunc()
		end
	end
end

return UnionRankView