-- @date:   2019-03-08
-- @desc:   竞技场结算奖励

local BattleEndPvpRewardView = class("BattleEndPvpRewardView", cc.load("mvc").ViewBase)

BattleEndPvpRewardView.RESOURCE_FILENAME = "battle_end_reward.json"
BattleEndPvpRewardView.RESOURCE_BINDING = {
	["title"] = "title",
	["blackBg"] = {
		varname = "blackBg",
		binds = {
			event = "click",
			method = bindHelper.self("onCloseClick"),
		},
	},
	["awardsList"] = "awardsList",
	["textContinue"] = "textContinue",
	["tipText"] = "tipText",
	["awardItem"] = "awardItem",
}

-- 播放基本特效
function BattleEndPvpRewardView:playEffect()
	-- 结算特效
	local pnode = self:getResourceNode()
	self.selEffect = CSprite.new("level/zhandoujiangli.skel")
	self.selEffect:addTo(pnode, 100)
	self.selEffect:setAnchorPoint(cc.p(0.5,1.0))
	local x,y = self.title:xy()
	self.selEffect:xy(x,y)
	self.selEffect:visible(true)

	self.selEffect:play(self.isFail and "zhandoujiangli2" or "zhandoujiangli")
	self.selEffect:addPlay(self.isFail and "zhandoujiangli2_loop" or "zhandoujiangli_loop")
	-- if self.isBattleWin then
	-- 	self.selEffect:play("zhandoujiangli")
	-- 	self.selEffect:addPlay("zhandoujiangli_loop")
	-- else
	-- 	self.selEffect:play("zhandoujiangli2")
	-- 	self.selEffect:addPlay("zhandoujiangli2_loop")
	-- end
end

function BattleEndPvpRewardView:onCreate(showEndView,results)
	local serverData = results.serverData.view 		-- 服务器数据

	results.showReward = false

	self.showEndView = showEndView
	self.isFail = results.result ~= "win"
	self:playEffect()


	-- self.awardsList:setItemsMargin(25)
	self.awardsList:setScrollBarEnabled(false)
	if next(serverData.award) ~= nil then
		local tmpData = {}
		for k,v in pairs(serverData.award) do
			table.insert(tmpData, {key = k, num = v})
		end

		local num = #tmpData
		if num <= 5 then
			local x = self.awardsList:x() + (self.awardsList:width() - self.awardItem:width() * num) / 2
			self.awardsList:x(x)
		end
		self:showItem(1, tmpData)
	end

	self.textContinue:text(gLanguageCsv.click2Continue)
	rich.createByStr(string.format(gLanguageCsv.canReciveAwardTime,results.awardRemainTime),44)
		:anchorPoint(0.5,0.5)
		:xy(self.tipText:x(),self.tipText:y())
		:addTo(self:getResourceNode())
		:z(10)

	if results.from == "ban_embattle" then
		ccui.ImageView:create("battle/scene/bg_dzjjc.png")
			:scale(2)
			:xy(display.sizeInView.width/2, display.sizeInView.height/2)
			:addTo(self:getResourceNode(), 0)
	end
end

function BattleEndPvpRewardView:showItem(index, data)
	local item = self.awardItem:clone()
	item:show()
	local size = item:size()
	local key = data[index].key
	local num = data[index].num
	local cfg = dataEasy.getCfgByKey(key)
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
			},
			effect = "gain",
			onNode = function(node)
				node:xy(size.width/2, size.height/2 + 20)
				node:hide()
					:z(2)
				transition.executeSequence(node, true)
					:delay(0.5)
					:func(function()
						node:show()
					end)
					:done()
			end,
		},
	}

	local name, effect = uiEasy.setIconName(key, num)
	beauty.singleTextLimitWord(name, {fontSize = 40}, {width =  240})
		:xy(size.width/2, 20)
		:addTo(item, 10)
	-- item:get("name"):text(cfg.name)
	bind.extend(self, item, binds)
	self.awardsList:pushBackCustomItem(item)
	transition.executeSequence(self.awardsList, true)
		:delay(0.25)
		:func(function()
			if index < csvSize(data) then
				self:showItem(index + 1, data)
			else
				self.awardsList:adaptTouchEnabled()
			end
		end)
		:done()
end

function BattleEndPvpRewardView:onCloseClick()
	local showEndView = self.showEndView
	self:onClose()

	-- 胜负结果对于导向的界面不同
	showEndView()
end

return BattleEndPvpRewardView