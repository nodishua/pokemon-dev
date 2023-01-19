local FishingResultView = class('FishingResultView', cc.load("mvc").ViewBase)
FishingResultView.RESOURCE_FILENAME = 'fishing_result.json'

FishingResultView.RESOURCE_BINDING = {
	["fishItem"] = "fishItem",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					if v.id ~= nil then
						local unitID = csv.cards[v.id].unitID
						local star = csv.cards[v.id].star
						local rarity = csv.unit[unitID].rarity
						bind.extend(list, node, {
							class = "card_icon",
							props = {
								unitId = unitID,
								rarity = rarity,
								star = star,
							},
							bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, node, k, v)}})
						})
					else
						bind.extend(list, node, {
							class = "icon_key",
							props = {
								data = {
									key = v.key,
									num = v.num,
								}
							},
						})
					end
				end,
				onAfterBuild = function(list)
					list:setItemAlignCenter()
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onitemClick"),
			},
		},
	},
	["fishItem.iconPos"] = "iconPos",
	["fishItem.imgTipPos"] = "imgTipPos",
	["fishItem.imgNew"] = "imgNew",
	["fishItem.list"] = "descList",
	["fishItem.name"] = {
		varname = "fishName",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["fishItem.length"] = {
		varname = "length",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["fishItem.numLength"] = {
		varname = "numLength",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["score"] = {
		varname = "score",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["score1"] = {
		varname = "score1",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["score2"] = {
		varname = "score2",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.DEFAULT}},
		},
	},
	["pos"] = "skelPos",
}

function FishingResultView:onCreate(id, num, data, max, scene, oldPoint)
	self:initSkel()
	performWithDelay(self,function()
		self.skel:play("effect_loop")
	end,0.8)

	self.datas = idlers.newWithMap({})

	-- 鱼的参数
	local cfg = csv.fishing.fish[id]
	if cfg.showType == "pic" then
		ccui.ImageView:create(cfg.res)
			:xy(self.iconPos:xy())
			:scale(cfg.scale)
			:addTo(self.fishItem, 1, "icon")
	elseif cfg.showType == "spine" then
		widget.addAnimationByKey(self.fishItem, cfg.res, 'fish', "standby_loop", 1)
			:anchorPoint(cc.p(0.5, 0))
			:xy(self.iconPos:x(), self.iconPos:y() - 150)
			:scale(cfg.scale)
	end

	self.fishName:text(cfg.name)
	self.numLength:text(num.."cm")
	adapt.oneLinePos(self.length, self.numLength, cc.p(3, 0), "left")
	if num == 0 then
		itertools.invoke({self.length, self.numLength}, "hide")
	end

	if num > max then
		self.imgNew:show()
	end

	local rarity = ccui.ImageView:create(ui.RARITY_ICON[cfg.rare])
		:xy(self.imgTipPos:xy())
		:scale(1)
		:addTo(self.fishItem, 2, "rarity")

	beauty.textScroll({
		list = self.descList,
		strs = {str = cfg.desc, fontPath = "font/youmi1.ttf"},
		effect = {color = cc.c4b(255, 252, 237, 255)},
		align = "center",
	})

	if scene == game.FISHING_GAME then
		itertools.invoke({self.score1, self.score2}, "show")
		local newPoint = gGameModel.fishing:read("point")
		local point = newPoint - oldPoint
		self.score2:text(point)
		adapt.oneLinePos(self.score1, self.score2, cc.p(3, 0), "left")
		adapt.oneLinePos(self.score1, self.score, cc.p(10, 0), "right")
	end

	-- 奖励
	local datas = {}
	if data.cards ~= nil then
		table.insert(datas, data.cards[1])
	else
		for k,v in csvMapPairs(data) do
			local t = {}
			t.key = k
			t.num = v
			table.insert(datas, t)
		end
	end
	self.datas:update(datas)

end

-- 精灵详情
function FishingResultView:onitemClick(list, node, idx, val)
	gGameUI:showItemDetail(node, {key = "card", num = val.id})
end

-- spine
function FishingResultView:initSkel()
	self.skel = widget.addAnimationByKey(self.skelPos, "diaoyuchenggong/diaoyuchenggong.skel", 'diaoyu', "effect", 1)
	:scale(2)
end

return FishingResultView