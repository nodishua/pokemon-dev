-- @date:   2020-07-28
-- @desc:   精灵评论界面

local STEP = 20
-- 记录评论数据刷新类型
local COMMENT_REFRESH_STATE = {
	SEND = 1,
	DEL = 2,
	OPEN = 3,
	REFRESH = 4,
}
-- 总评分
local changeState = {
	"common/icon/logo_arrow_green.png",	-- 上升
	"city/card/comment/logo_line.png",	-- 持平
	"common/icon/logo_arrow_red.png"	-- 下降
}


local ViewBase = cc.load("mvc").ViewBase
local CardCommentView = class("CardCommentView", ViewBase)

CardCommentView.RESOURCE_FILENAME = "card_comment.json"
CardCommentView.RESOURCE_BINDING = {
	["mask"] = "mask",
	["center"] = "center",
	["center.star"] = "star",
	["right.noComment"] = "noComment",
	["right.textInput"] = "textInput",
	["right.btnComment"] = "btnComment",
	["center.starDesc"] = "starDesc",
	["center.scoreBg.img"] = "scoreImg",
	["right.item.list"] = "textItemList",
	["right.item.bg"] = "textItemBg",
	["right.item.top"] = "textItemTop",
	["right.item.head"] = "textItemHead",
	["right.item.bottom.btnLike"] = "btnLike",
	["right.item.bottom.btnDislike"] = "btnDislike",
	["right.item"] = "commentItem",
	["right.list"] = {
		varname = "commentList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("commentData"),
				item = bindHelper.self("commentItem"),
				scrollState = bindHelper.self("scrollState"),
				preloadCenter = bindHelper.self("preloadCenter"),
				isEnd = bindHelper.self("isEnd"),
				asyncPreload = 5,
				disableOnScroll = true,
				itemAction = {isAction = true},
				onBeforeBuild = function(list)
					list.scrollState:set(false)
					list:setRenderHint(0)
				end,
				onAfterBuild = function(list)
					list.scrollState:set(true)
				end,
				onItem = function(list, node, k, v)
					if k == itertools.size(list.data) then
						list.isEnd:set(true)
					end
					local childs = node:multiget("head", "list", "top", "bottom", "bg")
					local headChilds = childs.head:multiget("head", "lv", "lv1")
					local topChilds = childs.top:multiget("name", "vip", "btnDel", "tag", "tag2")
					local bottomChilds = childs.bottom:multiget("btnMore", "time", "txtLike", "txtDislike", "btnLike", "btnDislike")

					-- 头像
					bind.extend(list, headChilds.head, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.logo,
							level = false,
							vip = false,
							frameId = v.frame,
							onNode = function(node)
								node:xy(104, 95)
									:z(6)
									:scale(0.9)
							end,
						}
					})

					-- 等级
					headChilds.lv1:text(v.level)
					adapt.oneLinePos(headChilds.lv, headChilds.lv1, cc.p(0, 0), "left")

					-- 名字
					topChilds.name:text(v.name)

					-- VIP
					-- if v.vip == false or v.vip <= 0 then
					-- 	topChilds.vip:hide()
					-- else
					-- 	topChilds.vip:texture(ui.VIP_ICON[v.vip]):show()
					-- end
					topChilds.vip:hide()
					adapt.oneLinePos(topChilds.name, topChilds.vip, cc.p(10, 0), "left")

					-- 左上角tag

					topChilds.tag:hide()
					topChilds.tag2:hide()
					topChilds.btnDel:hide()
					if v.key == "hot" then
						topChilds.tag:texture("city/card/comment/logo_hot_pl.png"):show()
						if gGameModel.role:read("id") == v.val.role_db_id then
							topChilds.tag2:texture("city/card/comment/logo_zi_pl.png"):show()
							topChilds.btnDel:show()
						end
					elseif v.key == "my" then
						topChilds.tag:texture("city/card/comment/logo_zi_pl.png"):show()
						topChilds.btnDel:show()
					end

					-- 评论内容
					local textList, height = beauty.textScroll({
						list = childs.list,
						strs = v.val.content,
						align = "left",
					})
					childs.list:setTouchEnabled(false)

					-- 查看更多
					local listHeight = textList:size().height

					local btnMoreNormal = bottomChilds.btnMore:get("normal")
					local btnMoreSelect = bottomChilds.btnMore:get("select")

					if v.listH < height then
						if listHeight > v.listH then
							btnMoreNormal:hide()
							btnMoreSelect:show()
						else
							btnMoreNormal:show()
							btnMoreSelect:hide()
						end
					else
						btnMoreNormal:hide()
						btnMoreSelect:hide()
					end

					local function closeFunc()
						node:height(v.nodeH + (height - v.listH))
						childs.bg:height(v.bgH + (height - v.listH))
						childs.bg:y(v.bgY + (height - v.listH))
						textList:height(height)
						childs.top:y(v.topY + (height - v.listH))
						childs.head:y(v.headY + (height - v.listH) )
						list:refreshView()

						btnMoreSelect:show()
						btnMoreNormal:hide()
					end
					-- 查看
					bind.click(node, btnMoreNormal, {method = function()
						closeFunc()
						v.switch = true
					end})

					if v.switch then
						closeFunc()
					end
					--收起
					bind.click(node, btnMoreSelect, {method = function()
						node:height(v.nodeH)
						childs.bg:height(v.bgH)
						childs.bg:y(v.bgY)
						textList:height(v.listH)
						childs.top:y(v.topY)
						childs.head:y(v.headY)
						list:refreshView()

						btnMoreNormal:show()
						btnMoreSelect:hide()
						v.switch = false
					end})

					-- 时间
					local tb = time.getDate(v.val.time)
					bottomChilds.time:text(tb.year.."-"..tb.month.."-"..tb.day.."  "..tb.hour..":"..tb.min)

					-- 踩赞数量
					bottomChilds.txtLike:text(v.val.like)
					bottomChilds.txtDislike:text(v.val.dislike)

					-- 删除按钮
					local pos = {
						listH = v.listH,
						nodeH = v.nodeH,
						bgH = v.bgH,
						bgY = v.bgY,
						topY = v.topY,
						headY = v.headY,
					}
					bind.touch(node, topChilds.btnDel, {methods = {ended = functools.partial(list.btnDelClick, node, childs, textList, pos, v)}})

					-- 头像点击
					if gGameModel.role:read("id") ~= v.val.role_db_id then
						bind.touch(node, headChilds.head, {methods = {ended = functools.partial(list.headClick, childs.head, k, v)}})
					end

					-- 点赞点踩
					bottomChilds.btnLike:get("select"):visible(v.like)
					bottomChilds.btnLike:get("normal"):visible(not v.like)
					bottomChilds.btnDislike:get("select"):visible(v.dislike)
					bottomChilds.btnDislike:get("normal"):visible(not v.dislike)

					-- 点赞取消赞按钮
					bind.touch(node, bottomChilds.btnLike, {methods = {ended = functools.partial(list.likeClick, k, v, v.like)}})
					-- 点踩取消踩按钮
					bind.touch(node, bottomChilds.btnDislike, {methods = {ended = functools.partial(list.dislikeClick, k, v, v.dislike)}})
				end,
			},
			handlers = {
				btnDelClick = bindHelper.self("onBtnDel"),
				headClick = bindHelper.self("onHeadClick"),
				likeClick = bindHelper.self("onLikeClick"),
				dislikeClick = bindHelper.self("onDislikeClick"),
			},
		},
	},
	["center.pageItem"] = "pageItem",
	["center.pageList"] = {
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
	["left.btnRank"] = {
		varname = "btnRank",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRank")}
		},
	},
	["left.btnRank.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["center.scoreBg.txt1"] = {
		varname = "scoreTxt1",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(251, 139, 101, 255)}},
		}
	},
	["center.scoreBg.txt2"] = {
		varname = "scoreTxt2",
		binds = {
			event = "effect",
			data = {outline = {color = ui.COLORS.OUTLINE.WHITE}},
		}
	},
	["center.scoreBg.txt3"] = {
		varname = "scoreTxt3",
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(251, 139, 101, 255)}},
		}
	},
}

function CardCommentView:onCreate(cardId, data, score)
	gGameUI.topuiManager:createView("title", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.comment, subTitle = "COMMENT"})
	self.cardId = cardId
	self.score = score
	self.data = data

	self.textItemListH = self.textItemList:size().height
	self.itemListH = self.commentItem:size().height
	self.textItemBgH = self.textItemBg:size().height
	self.textItemBgY = self.textItemBg:y()
	self.textItemTopY = self.textItemTop:y()
	self.textItemHeadY = self.textItemHead:y()

	self.commentItem:get("list"):setScrollBarEnabled(false)
	self.preloadCenter = idler.new(0)
	self.isEnd = idler.new(false)

	self:initModel()

	idlereasy.when(self.cardCommentCounter, function(_, cardCommentCounter)
		local t = {}
		for k,v in pairs(cardCommentCounter) do
			local cfg = csv.cards[k]
			if not t[cfg.cardMarkID] then
				t[cfg.cardMarkID] = 0
			end
			t[cfg.cardMarkID] = t[cfg.cardMarkID] + v
		end
		self.commentCounter = t
	end)

	-- 进化链数据
	self.evolutionDatas = idlers.new()
	-- 评论数据
	self.commentData = idlers.new()
	self.isCanDown = true
	self.scrollState = idler.new(true)
	self.commentState = COMMENT_REFRESH_STATE.OPEN

	self:commentListData()
	idlereasy.when(self.commentData,function(_, commentData)
		self.noComment:visible(not data.my[1] and not data.new[1] and not data.hot[1])
	end)

	-- 精灵
	self:initCard()
	-- 输入评论
	self:initComment()

	local container = self.commentList:getInnerContainer()
	self.commentList:onScroll(function(event)
		local y = container:getPositionY()
		if (event.name == "SCROLL_TO_TOP" or event.name == "SCROLL_TO_BOTTOM") and self.commentList.quickFor then
			self.commentList:quickFor()
			self.scrollState:set(true)
		else
			if y >= -10 and self.scrollState:read() and not self.isRequest then
				if self.isCanDown then
					self.isEnd:set(false)
					self.commentState = COMMENT_REFRESH_STATE.OPEN
					self:sendProtocol()

				elseif self.isEnd:read() then
					gGameUI:showTip(gLanguageCsv.noMoreComment)
				end
			end
		end
	end)
end

function CardCommentView:initData(serverData)
	if self.commentState == COMMENT_REFRESH_STATE.OPEN then
		self.isCanDown = #serverData.new == STEP
	end
	if self.commentState == COMMENT_REFRESH_STATE.REFRESH then
		self.data.new = {}
	end
	self.data.hot = serverData.hot
	self.data.my = serverData.my

	for i,v in ipairs(serverData.new) do
		table.insert(self.data.new, v)
	end
	for i,v in pairs(serverData.like) do
		self.data.like[i] = v
	end
	for i,v in pairs(serverData.dislike) do
		self.data.dislike[i] = v
	end
	for i,v in pairs(serverData.roles) do
		self.data.roles[i] = v
	end

	self:commentListData()
end

function CardCommentView:sendProtocol()
	if self.commentState == COMMENT_REFRESH_STATE.OPEN then
		self.isCanDown = false
	end
	self.isRequest = true
	local offset = #self.data.new
	local size = self.commentState == COMMENT_REFRESH_STATE.OPEN and STEP or 0
	if self.commentState == COMMENT_REFRESH_STATE.REFRESH then
		offset = 0
		size = #self.data.new
	end
	gGameApp:requestServer("/game/card/comment/list",function (tb)
		-- 延迟设置，防护滑动刷新多发请求
		performWithDelay(self, function()
			self.isRequest = false
		end, 0.1)
		self:initData(tb.view)
	end, self.cardId, offset, size)
end

-- 精灵
function CardCommentView:initCard()
	local cardId = self.cardId
	local childs = self.center:multiget(
		"cardIcon",
		"rare",
		"name",
		"iconAttr1",
		"iconAttr2"
	)

	local unitID = csv.cards[cardId].unitID
	local unitCsv = csv.unit[unitID]

	--进化链数据
	local unitCsv = csv.cards[self.cardId]
	local evolutionDatas = {}
	for id,v in orderCsvPairs(csv.cards) do
		if matchLanguage(v.languages) and v.cardMarkID == unitCsv.cardMarkID and v.canDevelop and gHandbookCsv[id].isOpen then
			table.insert(evolutionDatas, {
				existCards = existCards,
				selectDevelop = v.develop,
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
		if v.id == unitCsv.id then
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
			itertools.invoke(childs, "show")
			local unitCfg = csv.unit[evolutionDatas.cfg.unitID]
			local size = childs.cardIcon:size()
			childs.cardIcon:removeAllChildren()
			local cardSprite = widget.addAnimation(childs.cardIcon, unitCfg.unitRes, "standby_loop", 5)
				:xy(size.width/2, 0)
				:scale(unitCfg.scaleU*2.3)
			cardSprite:setSkin(unitCfg.skin)

			-- 名字
			childs.name:text(evolutionDatas.cfg.name)
			-- 品质
			childs.rare:texture(ui.RARITY_ICON[unitCfg.rarity])
			adapt.oneLineCenterPos(cc.p(290, childs.name:y()), {childs.rare, childs.name, childs.iconAttr1}, cc.p(15, 0))

			-- 属性
			childs.iconAttr1:texture(ui.ATTR_ICON[unitCfg.natureType])
			childs.iconAttr2:hide()
			if unitCfg.natureType2 then
				childs.iconAttr2:texture(ui.ATTR_ICON[unitCfg.natureType2]):show()
				adapt.oneLinePos(childs.iconAttr1, childs.iconAttr2, cc.p(15, 0), "left")
			end

			self.noComment:get("img1.txt"):text(string.format(gLanguageCsv.noComment, evolutionDatas.cfg.name))
			self.noComment:get("img1.txt"):size(457, 140)
			evolutionDatas.select = true
		else
			itertools.invoke(childs, "hide")
		end
	end)

	-- 切换精灵
	self:initPrivilegeListener()

	-- 评分
	self:initGrade()

end

-- 排行榜
function CardCommentView:onBtnRank()
	gGameApp:requestServer("/game/card/fight/rank",function(tb)
		gGameUI:stackUI("city.card.comment_rank", nil, nil, self.cardId, tb.view)
	end, self.cardId, 0, 20)
end

-- 切换精灵
function CardCommentView:initPrivilegeListener()
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

-- 评分
function CardCommentView:initGrade()

	self.scoreTxt2:text(mathEasy.getPreciseDecimal(self.score.score, 1))
	if self.score.score > self.score.last_score then
		self.scoreImg:texture(changeState[1])
	elseif self.score.score == self.score.last_score then
		self.scoreImg:texture(changeState[2])
	elseif self.score.score < self.score.last_score then
		self.scoreImg:texture(changeState[3])
	end
	adapt.oneLineCenter(self.scoreTxt2,self.scoreTxt1, self.scoreTxt3,cc.p(10, 0))
	adapt.oneLinePos(self.scoreTxt3, self.scoreImg, cc.p(5, -5))

	-- 星星
	local starState = {
		"common/icon/icon_star_d.png",	-- 置灰
		"common/icon/icon_star.png"		-- 点亮
	}
	local starDesc = {
		gLanguageCsv.oneStarGrade,	-- 求加强
		gLanguageCsv.twoStarGrade,	-- 不够给力
		gLanguageCsv.threeStarGrade,-- 勉强可用
		gLanguageCsv.fourStarGrade,	-- 很强力
		gLanguageCsv.fiveStarGrade,	-- 极力推荐
	}

	local Grade = self.score.my_score -- 服务器记录已评分数
	local markId = csv.cards[self.cardId].cardMarkID

	local activate = false
	for k,v in orderCsvPairs(csv.cards) do
		if v.cardMarkID == markId then
			if self.pokedex:read()[k] then
				activate = true
				break
			end
		end
	end

	for i = 1, 5 do
		-- 点亮星星
		local function starLighten(length)
			for j = 1, length do
				self.star:get("star"..j):texture(starState[2])
			end
		end
		-- 置灰星星
		local function starDarken(begin, length)
			for j = begin + 1, length do
				self.star:get("star"..j):texture(starState[1])
			end
		end

		-- 初始化点亮星星
		starLighten(Grade/2)
		self.starDesc:text(starDesc[Grade/2])

		bind.click(self, self.star:get("star"..i), {method = function()
			-- 是否激活图鉴
			if activate == false then
				gGameUI:showTip(gLanguageCsv.cardNotActivateCantGrade)
				return
			end

			-- 每日评分修改次数
			local times = 0
			for k,v in pairs(self.cardScoreCounter:read()) do
				if k == markId then
					times = v
				end
			end
			if times >= gCommonConfigCsv.cardScoreDailyChangeTimes then
				gGameUI:showTip(gLanguageCsv.tomorrowCanChangeGrade)
				return
			end

			-- 点击后星星变化
			starLighten(i)
			starDarken(i, 5)
			self.starDesc:text(starDesc[i])
			gGameUI:showDialog{
				strs = {
					string.format(gLanguageCsv.confirmWithCardScore, i*2)
				},
				cb = function()
					gGameApp:requestServer("/game/card/score/send", function(tb)
						gGameUI:showTip(gLanguageCsv.gradeComplete)
					end, self.cardId, i*2)
				end,
				closeCb = function()
					-- 关闭后星星变化
					starLighten(Grade/2)
					starDarken(Grade/2, 5)
					if Grade == 0 then
						self.starDesc:text(gLanguageCsv.noGrade)
					else
						self.starDesc:text(starDesc[Grade/2])
					end
				end,
				cancelCb = function()
					-- 关闭后星星变化
					starLighten(Grade/2)
					starDarken(Grade/2, 5)
					if Grade == 0 then
						self.starDesc:text(gLanguageCsv.noGrade)
					else
						self.starDesc:text(starDesc[Grade/2])
					end
				end,
				fontSize = 50,
				btnType = 2,
				clearFast = true,
			}
		end})
	end
end

-- 输入评论
function CardCommentView:initComment()
	local cardId = self.cardId
	blacklist:addListener(self.textInput, "*")
	self.textInput:setPlaceHolder(string.format(gLanguageCsv.pleaseCommentOn, gCommonConfigCsv.cardCommentWordCount))
	self.textInput:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	self.textInput:setMaxLengthEnabled(true)
	self.textInput:setMaxLength(gCommonConfigCsv.cardCommentWordCount)

	-- 发表评论
	bind.touch(self, self.btnComment, {methods = {ended = function()
		local isUnlock = dataEasy.isUnlock(gUnlockCsv.cardPostComment)
		local cfg = csv.unlock[gUnlockCsv.cardPostComment]
		if not isUnlock then
			gGameUI:showTip(string.format(gLanguageCsv.nowLevelCantComment, cfg.startLevel))
			return
		end

		-- 同一进化链可评论次数
		local markId = csv.cards[cardId].cardMarkID
		local times = self.commentCounter[markId] or 0
		if times >= gCommonConfigCsv.cardCommentDailyMarkSendTimes then
			gGameUI:showTip(string.format(gLanguageCsv.onedayCanCommentTimes, gCommonConfigCsv.cardCommentDailyMarkSendTimes))
			return
		end

		-- 可评论不同进化链次数
		if itertools.size(self.commentCounter) >= gCommonConfigCsv.cardCommentDailyMarkNum and not self.commentCounter[markId] then
			gGameUI:showTip(string.format(gLanguageCsv.onedayDifferentCanCommentTimes, gCommonConfigCsv.cardCommentDailyMarkNum))
			return
		end

		local input = self.textInput:getStringValue()
		if input == nil or input == "" then
			gGameUI:showTip(gLanguageCsv.canNotEmpty)
		else
			gGameApp:requestServer("/game/card/comment/send", function(tb)
				gGameUI:showTip(gLanguageCsv.commentIsSucceed)
				self.textInput:text("")
				self.commentState = COMMENT_REFRESH_STATE.SEND
				self:sendProtocol()
			end, cardId, input)
		end
	end}})
end

-- 评论数据
function CardCommentView:commentListData()
	local data = self.data
	local datas = {}
	local function getData(t, key)
		if t then
			for k,v in ipairs(t) do
				local val = data.roles[v.role_db_id]
				if val then
					local switch = false
					if self.commentData:at(#datas+1) then
						switch = self.commentData:at(#datas+1):read().switch
					end
					table.insert(datas, {
						key = key,
						val = v,
						level = val.level,
						logo = val.logo,
						frame = val.frame,
						vip = val.vip,
						name = val.name,
						game_key = val.game_key,
						like = data.like[v.id] ~= nil,
						dislike = data.dislike[v.id] ~= nil,
						listH = self.textItemListH,
						nodeH = self.itemListH,
						bgH = self.textItemBgH,
						bgY = self.textItemBgY,
						topY = self.textItemTopY,
						headY = self.textItemHeadY,
						switch = switch,
					})
				end
			end
		end
	end
	getData(data.hot, "hot")
	getData(data.my, "my")
	getData(data.new, "new")

	if self.commentState == COMMENT_REFRESH_STATE.SEND then
		-- 滑动跳到自己发言的位置
		self.preloadCenter:set(math.min(#data.hot + 1, #datas))
	else
		dataEasy.tryCallFunc(self.commentList, "updatePreloadCenterIndex")
	end
	self.commentData:update(datas)

	gGameUI:disableTouchDispatch(0.01)
end

-- 删除个人评论
function CardCommentView:onBtnDel(list, node, childs, textList, pos, v)
	gGameUI:showDialog{
		strs = {
			gLanguageCsv.confirmWithDeleteComment
		},
		cb = function()
			gGameApp:requestServer("/game/card/comment/del",function (tb)
				gGameUI:showTip(gLanguageCsv.commentIsDelete)
				self.commentState = COMMENT_REFRESH_STATE.DEL
				self:sendProtocol()
				node:height(pos.nodeH)
				childs.bg:height(pos.bgH)
				childs.bg:y(pos.bgY)
				textList:height(pos.listH)
				childs.top:y(pos.topY)
				childs.head:y(pos.headY)
				list:refreshView()
			end, v.val.id)
		end,
		fontSize = 50,
		btnType = 2,
		clearFast = true,
	}
end

-- 点击玩家头像
function CardCommentView:onHeadClick(list, node, k, v)
	local serverKey = userDefault.getForeverLocalKey("serverKey", nil, {rawKey = true})
	if serverKey ~= v.game_key then
		gGameUI:showTip(gLanguageCsv.disserentServerCantViewing)
		return
	end
	local x, y = node:xy()
	local pos = node:getParent():convertToWorldSpace(cc.p(x - 100, y))
	local data = {
		role = {
			vip = v.vip,
			name = v.name,
			logo = v.logo,
			frame = v.frame,
			level = v.level,
			id = v.val.role_db_id,
		},
	}
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, data)
end

function CardCommentView:updateLike(idx, typ)
	self.commentData:at(idx):modify(function(data)
		if typ == "revokeLike" and data.like then
			data.val.like = data.val.like - 1
			data.like = false
		elseif typ == "like" and not data.like then
			data.val.like = data.val.like + 1
			data.like = true
			if data.dislike then
				data.val.dislike = data.val.dislike - 1
				data.dislike = false
			end
		elseif typ == "revokeDislike" and data.dislike then
			data.val.dislike = data.val.dislike - 1
			data.dislike = false
		elseif typ == "dislike" and not data.dislike then
			data.val.dislike = data.val.dislike + 1
			data.dislike = true
			if data.like then
				data.val.like = data.val.like - 1
				data.like = false
			end
		end
	end, true)
end

function CardCommentView:refreshErr(v)
	self.commentState = COMMENT_REFRESH_STATE.REFRESH
	self:sendProtocol()
end

-- 点赞取消赞按钮
function CardCommentView:onLikeClick(list, k, v, btnLikeClicked)
	if btnLikeClicked then
		-- 取消赞按钮
		btnLikeClicked = false

		gGameApp:requestServerCustom("/game/card/comment/evaluate")
			:onErrClose(function()
				self:refreshErr(v)
			end)
			:params(v.val.id, "revokeLike")
			:doit()

		self:updateLike(k, "revokeLike")
	else
		-- 点赞按钮
		btnLikeClicked = true

		gGameApp:requestServerCustom("/game/card/comment/evaluate")
			:onErrClose(function()
				self:refreshErr(v)
			end)
			:params(v.val.id, "like")
			:doit()

		self:updateLike(k, "like")
	end
end

-- 点踩取消踩按钮
function CardCommentView:onDislikeClick(list, k, v, btnDislikeClicked)
	if btnDislikeClicked then
		-- 取消踩按钮
		btnDislikeClicked = false

		gGameApp:requestServerCustom("/game/card/comment/evaluate")
			:onErrClose(function()
				self:refreshErr(v)
			end)
			:params(v.val.id, "revokeDislike")
			:doit()

		self:updateLike(k, "revokeDislike")
	else
		-- 点踩按钮
		btnDislikeClicked = true

		gGameApp:requestServerCustom("/game/card/comment/evaluate")
			:onErrClose(function()
				self:refreshErr(v)
			end)
			:params(v.val.id, "dislike")
			:doit()

		self:updateLike(k, "dislike")
	end
end

function CardCommentView:initModel()
	self.myID = gGameModel.role:getIdler("id")
	-- 每日评论次数
	self.cardCommentCounter = gGameModel.daily_record:getIdler("card_comment_counter")
	-- 每日评分次数
	self.cardScoreCounter = gGameModel.daily_record:getIdler("card_score_counter")
	-- 卡牌
	self.pokedex = gGameModel.role:getIdler("pokedex")
end

return CardCommentView