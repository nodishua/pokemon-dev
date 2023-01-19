-- @date 2020-07-29
-- @desc 精灵评论排行榜

local TAB_LIST = {
	"fightingRankList",
	"commentRankList",
}

-- 记录数据刷新类型
local RANK_REFRESH_STATE = {
	TAB = 1,
	SCROLL = 2
}

-- 每次获取的数据条数
local STEP = 20

local CommentRankView = class('CommentRankView', Dialog)
CommentRankView.RESOURCE_FILENAME = 'card_comment_rank.json'

CommentRankView.RESOURCE_BINDING = {
	["right.fightingRank"] = "fightingRank",
	["right.fightingRank.left"] = "fightingRankLeft",
	["right.commentRank"] = "commentRank",
	["right.commentRank.left.mask"] = "mask",
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["left.item"] = "btnItem",
	["left.list"] = {
		varname = "btnList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("btnDatas"),
				item = bindHelper.self("btnItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					selected:visible(v.selected)
					normal:visible(not v.selected)
					normal:get("txt"):text(v.txt)
					selected:get("txt"):text(v.txt)
					local maxHeight = normal:getSize().height - 40
					adapt.setAutoText(normal:get("txt"),v.name,maxHeight)
					adapt.setAutoText(selected:get("txt"), v.name, maxHeight)
					normal:get("txt"):getVirtualRenderer():setLineSpacing(-10)
					selected:get("txt"):getVirtualRenderer():setLineSpacing(-10)

					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onSelectClick"),
			},
		},
	},
	["right.fightingRank.right.item"] = "fightingRankItem", -- 精灵战力榜
	["right.fightingRank.right.list"] = {
		varname = "fightingRankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData1"),
				item = bindHelper.self("fightingRankItem"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"rank",
						"txtRank",
						"head",
						"name",
						"vip",
						"lv",
						"lv1",
						"fighting",
						"card"
					)
					--排名
					if k <= 3 then
						childs.rank:show()
						childs.txtRank:hide()
						if k == 1 then
							childs.rank:texture("city/rank/icon_jp.png")
						elseif k == 2 then
							childs.rank:texture("city/rank/icon_yp.png")
						else
							childs.rank:texture("city/rank/icon_tp.png")
						end
					else
						childs.rank:hide()
						childs.txtRank:show()
						childs.txtRank:text(k)
					end
					-- 头像
					bind.extend(list, childs.head, {
						class = "role_logo",
						props = {
							onNode = function(node)
								node:scale(0.8)
							end,
							logoId = v.role.logo,
							frameId = v.role.frame,
							level = false,
							vip = false,
						},
					})
					childs.name:text(v.role.name)
					childs.lv1:text(v.role.level)
					adapt.oneLinePos(childs.lv, childs.lv1, cc.p(5,0))
					--vip
					if v.role.vip == false or v.role.vip <= 0 then
						childs.vip:hide()
					else
						childs.vip:texture("common/icon/vip/icon_vip"..v.role.vip..".png")
					end
					childs.fighting:text(v.card.fighting_point)
					adapt.oneLinePos(childs.name,childs.vip,cc.p(5,0))
					--精灵
					local unitID = dataEasy.getUnitId(v.card.card_id, v.card.skin_id)
					local unitCsv = csv.unit[unitID]

					bind.extend(list, childs.card, {
						class = "card_icon",
						props = {
							unitId = unitID,
							rarity = unitCsv.rarity,
							star = v.card.star,
							advance = v.card.advance,
							levelProps = {
								data = v.card.level,
							},
							onNode = function(node)
								node:scale(0.8)
								node:xy(10, 10)
							end,
						}
					})
					-- 头像点击
					if gGameModel.role:read("id") ~= v.role.id then
						bind.touch(list, childs.head, {methods = {ended = functools.partial(list.headClick, childs.head, k, v)}})
						--点击精灵头像
						bind.touch(list, childs.card, {methods = {ended = functools.partial(list.clickCell, k, v)}})
					end
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onClickItem"),
				headClick = bindHelper.self("onHeadClick"),
			},
		},
	},
	["right.commentRank.right.item"] = "commentRankItem", -- 精灵评分榜
	["right.commentRank.right.list"] = {
		varname = "commentRankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData2"),
				item = bindHelper.self("commentRankItem"),
				scrollState = bindHelper.self("scrollState"),
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"rank",
						"txtRank",
						"card",
						"name",
						"score",
						"iconAttr1",
						"iconAttr2",
						"imgCompare"
					)
					if k <= 3 then
						childs.rank:show()
						childs.txtRank:hide()
						if k == 1 then
							childs.rank:texture("city/rank/icon_jp.png")
						elseif k == 2 then
							childs.rank:texture("city/rank/icon_yp.png")
						else
							childs.rank:texture("city/rank/icon_tp.png")
						end
					else
						childs.rank:hide()
						childs.txtRank:show()
						childs.txtRank:text(k)
					end
					local unitId = {}
					for key,val in csvPairs(csv.cards) do
						if matchLanguage(val.languages) and val.cardMarkID == v.mark_id then
							if csv.unit[val.unitID] then
								table.insert(unitId,val.unitID)
							end
						end
					end
					local unitCsv = csv.unit[math.max(unpack(unitId))]
					local cardid = unitCsv.cardID
					local rarity = unitCsv.rarity
					bind.extend(list, childs.card, {
						class = "card_icon",
						props = {
							cardId = cardid,
							rarity = rarity,
							onNode = function(node)
								node:scale(0.8)
								node:xy(0, 0)
							end,
						}
					})
					childs.name:text(unitCsv.name)
					-- 属性
					childs.iconAttr1:texture(ui.ATTR_ICON[unitCsv.natureType])
					childs.iconAttr2:hide()
					if unitCsv.natureType2 then
						childs.iconAttr2:texture(ui.ATTR_ICON[unitCsv.natureType2]):show()
					end
					--评分
					childs.score:text(mathEasy.getPreciseDecimal(v.score, 1))
					--排名
					if v.rank == v.last_rank then
						childs.imgCompare:texture("city/card/comment/logo_line.png")
					elseif v.rank >= v.last_rank then
						childs.imgCompare:texture("common/icon/logo_arrow_red.png")
					else
						childs.imgCompare:texture("common/icon/logo_arrow_green.png")
					end
				end,
			},
		},
	},
	["right.commentRank.left.pageItem"] = "pageItem",
	["right.commentRank.left.pageList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("evolutionDatas"),
				item = bindHelper.self("pageItem"),
				onItem = function(list, node, k, v)
					node:get("normal"):visible(v.select ~= true)
					node:get("select"):visible(v.select == true)
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
	["right.fightingRank.left.cardName"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(230, 122, 35, 255)}},
		}
	},
	["right.commentRank.left.cardName"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(230, 122, 35, 255)}},
		}
	},
	["right.commentRank.left.scoreBg.txt1"] = {
		varname = "scoreTxt1",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(230, 122, 35, 255)}},
		}
	},
	["right.commentRank.left.scoreBg.txt2"] = {
		varname = "scoreTxt2",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["right.commentRank.left.scoreBg.txt3"] = {
		varname = "scoreTxt3",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(230, 122, 35, 255)}},
		}
	},
}

function CommentRankView:onCreate(cardId, fightData)
	self.cardId = cardId
	self.myrank = fightData.rank
	self.fightData = fightData.ranks
	self:initModel()

	-- 暂时修改，只看前三
	if self.fightData then
		if table.maxn(self.fightData) > 3 then
			local limit3 = {}
			for i = 1, 3 do
				limit3[i] = self.fightData[i]
			end
			self.fightData = limit3
		end
	end

	self.fightingRankList:setScrollBarEnabled(false)
	self.commentRankList:setScrollBarEnabled(false)
	self.commentRank:get("left"):hide()

	self.isFightCanDown = true
	self.isScoreCanDown = true
	self.scrollState = idler.new(true)
	self.datas = {}
	local originData = self.fightData
	for i = 1, #TAB_LIST do
		self.datas[i] = i == 1 and originData or {}
		self["showData"..i] = idlers.newWithMap(self.datas[i])
	end

	-- 左侧页签按钮数据
	self.btnDatas = idlers.new(btnDatas)
	-- 左侧页签按钮点击
	self.showTab = idler.new((self.fightData and self.fightData[1]) and 1 or 2)
	-- 进化链数据
	self.evolutionDatas = idlers.new({})
	-- 评分榜数据
	self.scoreData = idlers.new({})
	self.rankState = RANK_REFRESH_STATE.SCROLL

	-- 左侧页签按钮
	local btnDatas = {
		{txt = gLanguageCsv.cardFightingRank, selected = false, type = "fight"},
		{txt = gLanguageCsv.cardCommentRank, selected = false, type = "score"},
	}
	self.btnDatas:update(btnDatas)

	-- 左侧页签按钮点击
	self.showTab:addListener(function(val, oldval, idler)
		self.btnDatas:atproxy(oldval).selected = false
		self.btnDatas:atproxy(val).selected = true

		-- 精灵战力榜
		self.fightingRank:visible(val == 1)
		-- 精灵评分榜
		self.commentRank:visible(val == 2)
		self.rankState = RANK_REFRESH_STATE.TAB
		if self.btnDatas:atproxy(val).type and #self.datas[val] == 0 then
			self:sendProtocol(self.btnDatas:atproxy(val).type, 0, val, self[TAB_LIST[val]])
		end

		for i, v in ipairs(TAB_LIST) do
			if i == val then
				self[v]:jumpToItem(0, cc.p(0, 1), cc.p(0, 1))
			end
		end
	end)

	-- 界面信息
	if self.fightData and self.fightData[1] then
		self:showFightingPanel()
	end

	for i, v in ipairs(TAB_LIST) do
		local container = self[v]:getInnerContainer()
		self[v]:onScroll(function(event)
			local y = container:getPositionY()
			if y >= -10 and self.scrollState:read() and not self.isRequest and self.btnDatas:atproxy(i).type then
				if (self.isFightCanDown and self.btnDatas:atproxy(i).type == "fight") or (self.isScoreCanDown and self.btnDatas:atproxy(i).type == "score")then
					self.rankState = RANK_REFRESH_STATE.SCROLL
					self:sendProtocol(self.btnDatas:atproxy(i).type,#self.datas[i],i,self[v])
				else
					gGameUI:showTip(gLanguageCsv.noMoreComment)
				end
			end
		end)
	end

	Dialog.onCreate(self)
end

function CommentRankView:initModel()
	self.roleName = gGameModel.role:read("name")
	self.level = gGameModel.role:read("level")
	self.vipLevel = gGameModel.role:read("vip_level")
	self.roleId = gGameModel.role:read("id")
	self.cards = gGameModel.role:read("cards")
end

-- 点击排行榜页签
function CommentRankView:onSelectClick(list, index)
	if not self.fightData or not self.fightData[1] then
		gGameUI:showTip(gLanguageCsv.cantViewFightingRank)
	else
		self.showTab:set(index)
	end
end

function CommentRankView:initData(serverData, offset, index, list, type)
	if self.rankState == RANK_REFRESH_STATE.SCROLL then
		if type == "fight" and #serverData < STEP then
			self.isFightCanDown = false
		elseif type == "score" and #serverData < STEP then
			self.isScoreCanDown = false
		end
	end

	if offset == 0 then
		self.datas[index] = serverData
	else
		for i,v in ipairs(serverData) do
			table.insert(self.datas[index],v)
		end
	end

	self["showData"..index]:update(self.datas[index])
	gGameUI:disableTouchDispatch(0.01)
	local diff = self.showTab:read() == 1 and 3 or 4
	list:jumpToItem(offset - diff, cc.p(0, 1), cc.p(0, 1))
end

function CommentRankView:sendProtocol(type, offset, index, list)
	self.isRequest = true
	local max = 200 -- 排行榜上限
	if type == "fight" then
		-- gGameApp:requestServer("/game/card/fight/rank",function (tb)
		-- 	-- 延迟设置，防护滑动刷新多发请求
		-- 	performWithDelay(self, function()
		-- 		self.isRequest = false
		-- 	end, 0.1)
		-- 	self:initData(tb.view.ranks, offset, index, list, type)
		-- end, self.cardId, offset, offset + STEP > max and max - offset or STEP)

	elseif type == "score" then
		gGameApp:requestServer("/game/card/score/rank",function (tb)
			if offset == 0 then
				self.scoreOne = tb.view.ranks[1]
				self:showCommentPanel()
			end
			-- 延迟设置，防护滑动刷新多发请求
			performWithDelay(self, function()
				self.isRequest = false
			end, 0.1)
			self:initData(tb.view.ranks, offset, index, list, type)
		end, offset, offset + STEP > max and max - offset or STEP)
	end
end

-- 精灵战力榜
function CommentRankView:showFightingPanel()
	self.fightOne = self.fightData[1]
	-- local unitID = csv.cards[self.fightOne.card.card_id].unitID
	local unitCfg = dataEasy.getUnitCsv(self.fightOne.card.card_id,self.fightOne.card.skin_id)

	-- 左侧面板
	local lChilds = self.fightingRank:get("left"):multiget("cardName", "cardIcon", "roleName", "lv", "lv1", "fighting", "fighting1")
	-- 名字
	lChilds.cardName:text(unitCfg.name)
	lChilds.roleName:text(self.fightOne.role.name)
	lChilds.lv1:text(self.fightOne.role.level)
	adapt.oneLineCenterPos(cc.p(370,170),{lChilds.roleName,lChilds.lv, lChilds.lv1}, cc.p(10,0))
	lChilds.fighting1:text(self.fightOne.card.fighting_point)
	adapt.oneLinePos(lChilds.fighting,lChilds.fighting1)
	-- 人物精灵spine
	local parent = lChilds.cardIcon
	local size = parent:size()
	local figureCfg = gRoleFigureCsv[self.fightOne.role.figure]
	local cardSprite = widget.addAnimationByKey(parent, unitCfg.unitRes, "card", "standby_loop", -1)
		:xy(size.width / 2 + 80, 0)
		:scale(unitCfg.scale * 1.3)
	cardSprite:setSkin(unitCfg.skin)


	widget.addAnimationByKey(parent, figureCfg.resSpine, "figure", "standby_loop1", 3)
		:xy(size.width / 2 - 100, 0)
		:scale(figureCfg.scale)
	if gGameModel.role:read("id") ~= self.fightOne.role.id then
		bind.touch(self, parent, {methods = {ended = function()
			self:onHeadClick(nil, parent, nil, self.fightOne)
		end}})
	end
	bind.extend(self, parent, {
		event = "extend",
		class = "role_title",
		props = {
			data = self.fightOne.role.title,
			onNode = function(panel)
				panel:xy(size.width / 2, size.height - 50)
				panel:scale(1.2)
				panel:z(3)
			end,
		},
	})

	-- 右侧面板个人信息
	local rChilds = self.fightingRank:get("right.myRank"):multiget("txtRank", "rank", "head", "name", "vip", "lv", "lv1", "fighting", "card")
	-- 头像
	bind.extend(self, rChilds.head, {
		class = "role_logo",
		props = {
			onNode = function(node)
				node:scale(0.8)
			end,
			logoId = gGameModel.role:read("logo"),
			frameId = gGameModel.role:read("frame"),
			level = false,
			vip = false,
		},
	})

	-- 名字
	rChilds.name:text(self.roleName)
	--自己排名
	if self.myrank > 0 then
		rChilds.txtRank:text(self.myrank)
		if self.myrank <= 3 then
			rChilds.rank:show()
			rChilds.txtRank:hide()
			if self.myrank == 1 then
				rChilds.rank:texture("city/rank/icon_jp.png")
			elseif self.myrank == 2 then
				rChilds.rank:texture("city/rank/icon_yp.png")
			else
				rChilds.rank:texture("city/rank/icon_tp.png")
			end
		else
			rChilds.rank:hide()
			rChilds.txtRank:show()
			rChilds.txtRank:text(self.myrank)
			text.addEffect(rChilds.txtRank, {color = cc.c4b(91, 84,  91,255)})
			rChilds.txtRank:setFontSize(60)

		end
	else
		rChilds.rank:hide()
	end


	-- 遍历自己的精灵
	local maxFighting = 0
	local cardDatas
	for k,dbid in pairs(self.cards) do
		local card = gGameModel.cards:find(dbid)
		if csv.cards[self.cardId].cardMarkID == csv.cards[card:read("card_id")].cardMarkID and card:read("fighting_point") > maxFighting then
			cardDatas = card:read("card_id", "skin_id", "fighting_point", "level", "star", "advance")
			maxFighting = cardDatas.fighting_point
		end
	end
	if maxFighting == 0 then
		rChilds.fighting:text(gLanguageCsv.commentFightingRankTip)
	else
		rChilds.fighting:text(maxFighting)
		local unitId = dataEasy.getUnitId(cardDatas.card_id,cardDatas.skin_id)
		local unitCsv = csv.unit[unitId]
		bind.extend(self, rChilds.card, {
			class = "card_icon",
			props = {
				unitId = unitId,
				rarity = unitCsv.rarity,
				star = cardDatas.star,
				advance = cardDatas.advance,
				levelProps = {
					data = cardDatas.level,
				},
				onNode = function(node)
					node:scale(0.8)
					node:xy(10, 10)
				end,
			}
		})
	end

	-- VIP
	if self.vipLevel == false or self.vipLevel <= 0 then
		rChilds.vip:hide()
	else
		rChilds.vip:texture(ui.VIP_ICON[self.vipLevel]):show()
	end
	-- 等级
	rChilds.lv1:text(self.level)
	adapt.oneLinePos(rChilds.name, rChilds.vip, cc.p(3, 0), "left")
	adapt.oneLinePos(rChilds.lv, rChilds.lv1, cc.p(0, 0), "left")
end

-- 精灵评分榜
function CommentRankView:showCommentPanel()
	self.commentRank:get("left"):show()
	local unitID = csv.cards[self.scoreOne.mark_id].unitID
	local unitCfg = csv.unit[unitID]

	-- 左侧面板
	local childs = self.commentRank:get("left"):multiget("cardIcon", "rare", "name", "iconAttr1", "iconAttr2", "scoreBg")
	self.scoreTxt2:text(mathEasy.getPreciseDecimal(self.scoreOne.score, 1))

	--排名
	if self.scoreOne.rank == self.scoreOne.last_rank then
		childs.scoreBg:get("img"):texture("city/card/comment/logo_line.png")
	elseif self.scoreOne.rank >= self.scoreOne.last_rank then
		childs.scoreBg:get("img"):texture("common/icon/logo_arrow_red.png")
	else
		childs.scoreBg:get("img"):texture("common/icon/logo_arrow_green.png")
	end
	adapt.oneLineCenter(self.scoreTxt2,self.scoreTxt1, self.scoreTxt3, cc.p(10, 0))
	adapt.oneLinePos(self.scoreTxt3, childs.scoreBg:get("img"), cc.p(5, -5))

	-- 进化链数据
	local cardCsv = csv.cards[self.scoreOne.mark_id]
	local evolutionDatas = {}
	for id,v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) and v.cardMarkID == cardCsv.cardMarkID and v.canDevelop then
			table.insert(evolutionDatas, {
				cfg = v,
				id = id
			})
		end
	end
	table.sort(evolutionDatas,function(a,b)
		return a.id < b.id
	end)
	self.evolutionDatas:update(evolutionDatas)

	local selectEvolution = 0
	for i,v in ipairs(evolutionDatas) do
		if v.id == cardCsv.id then
			selectEvolution = i
		end
	end
	self.selectEvolution = idler.new(selectEvolution)
	self.selectEvolution:addListener(function(val, oldval)
		local evolutionDatas = self.evolutionDatas:atproxy(val)
		local oldEvolutionDatas = self.evolutionDatas:atproxy(oldval)
		if oldEvolutionDatas then
			oldEvolutionDatas.select = false
		end
		if evolutionDatas then
			local unitCsv = csv.unit[evolutionDatas.cfg.unitID]
			local size = childs.cardIcon:size()
			childs.cardIcon:removeAllChildren()
			local cardSprite = widget.addAnimation(childs.cardIcon, unitCsv.unitRes, "standby_loop", 5)
				:xy(size.width/2, 0)
				:scale(unitCsv.scaleU*2.3)
			cardSprite:setSkin(unitCsv.skin)
			-- 品质
			childs.rare:texture(ui.RARITY_ICON[unitCfg.rarity])
			-- 名字
			childs.name:text(evolutionDatas.cfg.name)
			-- 属性
			childs.iconAttr1:texture(ui.ATTR_ICON[unitCfg.natureType])
			childs.iconAttr2:hide()
			if unitCfg.natureType2 then
				childs.iconAttr2:texture(ui.ATTR_ICON[unitCfg.natureType2]):show()
			end
			adapt.oneLineCenterPos(cc.p(380, childs.name:y()), {childs.rare, childs.name, childs.iconAttr1, childs.iconAttr2}, cc.p(15, 0))

			evolutionDatas.select = true
		end
	end)

	-- 切换精灵
	self:initPrivilegeListener()
end

-- 切换精灵
function CommentRankView:initPrivilegeListener()
	uiEasy.addTouchOneByOne(self.mask, {ended = function(pos, dx, dy)
		if math.abs(dx) > 100 and math.abs(dx) > math.abs(dy) then
			local dir = dx > 0 and -1 or 1
			self.selectEvolution:modify(function(val)
				val = cc.clampf(val + dir, 1, self.evolutionDatas:size())
				return true, val
			end)
		end
	end})
end

-- 点击玩家头像
function CommentRankView:onHeadClick(list, node, k, v)
	local x, y = node:xy()
	local pos = node:getParent():convertToWorldSpace(cc.p(x - 100, y))
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, v)
end

--点击精灵头像信息
function CommentRankView:onClickItem(list, k, v)
	if v.cardId == -1 then
		return
	end
	gGameApp:requestServer("/game/card_info", function (tb)
		gGameUI:stackUI("city.card.info", nil, nil, tb.view)
	end, v.card.id)
end

return CommentRankView