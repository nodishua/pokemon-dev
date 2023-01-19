-- @date:   2019-03-08
-- @desc:   竞技场结算奖励

local BattleEndPvpRewardView = class("BattleEndPvpRewardView", cc.load("mvc").ViewBase)

BattleEndPvpRewardView.RESOURCE_FILENAME = "battle_end_pvp_reward.json"
BattleEndPvpRewardView.RESOURCE_BINDING = {
	["item"] = "item",
	["title"] = "title",
	["imgBg"] = {
		varname = "imgBg",
		binds = {
			event = "click",
			method = bindHelper.self("onCloseClick"),
		},
	},
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("listData"),
				item = bindHelper.self("item"),
				onItem = function(list, node, k, v)
					local children = node:multiget("imgCardBack", "awardPanel")
					list.initItem(node, k)
					bind.touch(list, children.imgCardBack, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 3,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
				initItem = bindHelper.self("initItem"),
			},
		},
	},
	["item.imgCardBack"] = "imgCardBack",
	["item.awardPanel.imgCard"] = "imgCard",
	["textContinue"] = "textContinue",
}

-- 播放基本特效
function BattleEndPvpRewardView:playEffect()
	-- 结算特效
	local pnode = self:getResourceNode()
	self.selEffect = CSprite.new("level/zhandoujiangli.skel")
	self.selEffect:addTo(pnode, 100)
	self.selEffect:setAnchorPoint(cc.p(0.5,1.0))
	local x,y = self.title:xy()
	self.selEffect:xy(x,y + 300)
	self.selEffect:visible(true)
	if self.isBattleWin then
		self.selEffect:play("zhandoujiangli")
		self.selEffect:addPlay("zhandoujiangli_loop")
	else
		self.selEffect:play("zhandoujiangli2")
		self.selEffect:addPlay("zhandoujiangli2_loop")
	end
	self.selEffect:retain()
end

function BattleEndPvpRewardView:onCreate(results)
	local serverDataView = results.serverData.view 		-- 服务器数据
	local endResult = serverDataView.result 			-- 胜利与否
	self.awardTb = serverDataView.award 				-- 真实奖励
	self.showItemTb = serverDataView.show 				-- 陪衬奖励

	self.isBattleWin = (endResult == "win")
	self.imgCard:hide()
	if self.isBattleWin then
		self.imgCardBack:texture("city/pvp/reward/img_kapai01@.png")
		self.imgCard:texture("city/pvp/reward/img_kapai02@.png")
		self.imgBg:texture("city/pvp/reward/bg_pvp_win.png")
	else
		self.imgCardBack:texture("city/pvp/reward/img_kapai_defeat01@.png")
		self.imgCard:texture("city/pvp/reward/img_kapai_defeat02@.png")
		self.imgBg:texture("city/pvp/reward/bg_pvp_lose.png")
	end
	self:playEffect()

	self.listData = {
		{key = 1},
		{key = 2},
		{key = 3},
	}
end

-- 设置是否可以跳转到下一界面了
function BattleEndPvpRewardView:setCanJump()
	self.canJump = self.canJump or 0 		-- 没有翻牌的话 禁止跳转 必须先翻牌
	self.canJump = self.canJump + 1
	if self.canJump >= 3 then
		self.textContinue:text(gLanguageCsv.click2Continue)
	end
end

-- item注册
function BattleEndPvpRewardView:initItem(list, item, k)
	self.items = self.items or {}
	self.items[k] = item
end

-- 点击函数
function BattleEndPvpRewardView:onItemClick(list, k, v)
	if self.clickClose then return end
	self.clickClose = true

	local itemIdx = 1
	for idx, item in pairs(self.items) do
		if idx ~= k then
			local idx = itemIdx
			itemIdx = itemIdx + 1
			performWithDelay(item, function()
				self:showEffectOnItem(list, item, self.showItemTb[idx], false)
			end, 1)
		else
			self:showEffectOnItem(list, item, self.awardTb, true)
		end
	end
end

-- 显示翻牌特效
function BattleEndPvpRewardView:showEffectOnItem(list, item, award, isSelected)
	local key, num = next(award)
	local children = item:multiget("imgCardBack", "awardPanel")
	local awardChildren = children.awardPanel:multiget("imgCard", "itemPanel", "awardName", "selectBox")
	children.imgCardBack:setTouchEnabled(false)

	bind.extend(list, awardChildren.itemPanel, {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num or 0,
			},
			onNode = function(panel)
				panel:setTouchEnabled(false)
			end,
		},
	})
	awardChildren.awardName:text(dataEasy.getCfgByKey(key).name)
	awardChildren.awardName:hide()
    local label = beauty.singleTextLimitWord(dataEasy.getCfgByKey(key).name, {fontSize = awardChildren.awardName:getFontSize()}, {width = 350})
    	:anchorPoint(0.5, 0.5)
   		:xy(awardChildren.awardName:xy())
    	:addTo(children.awardPanel, awardChildren.awardName:z())
    	:color(cc.c3b(255, 255, 255))
	text.addEffect(label, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
	children.imgCardBack:scale(2)
	children.awardPanel:scale(0, 1)

	transition.executeSequence(children.imgCardBack)
		:func(function ()
			if isSelected then
				-- 播放翻牌特效
				local nX,nY = item:xy()
				local lX,lY = list:xy()

				-- 放到最上层防止被覆盖
				widget.addAnimation(list:parent(), "level/zhandoujiangli.skel", self.isBattleWin and "fanpai" or "fanpai2", 1)
					:anchorPoint(cc.p(0,0))
					:xy(nX + lX, nY + lY)
				-- 计算特效的位置
				audio.playEffectWithWeekBGM("flop.mp3")
			else
				awardChildren.imgCard:show()
			end
		end)
		:delay(isSelected and 0.6 or 0)
		:func(function ()
			awardChildren.itemPanel:show()
		end)
		:scaleTo(0.2, 0, 2)
		:func(function ()
			transition.executeSequence(children.awardPanel)
				:scaleTo(0.2, 1, 1)
				:done()
		end)
		:delay(0.5)
		:func(function ()
			self:setCanJump()
		end)
		:done()
end

function BattleEndPvpRewardView:onCloseClick()
	if not self.canJump or self.canJump < 3 then
		return
	end

	local showEndView = self.showEndView
	self:onClose()

	-- 胜负结果对于导向的界面不同
	showEndView()
end

return BattleEndPvpRewardView