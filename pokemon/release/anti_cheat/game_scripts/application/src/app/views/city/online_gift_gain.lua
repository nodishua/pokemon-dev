-- @date: 2019-7-11 20:25:45
-- @desc: 在线礼包奖励领取
local function createSpine(parent, key, action, zOrder)
	return widget.addAnimationByKey(parent, "effect/jiesuanjiemian.skel", key, action, zOrder)
		:xy(parent:width()/2, parent:height()/2)
end

local OnlineGiftGainView = class("OnlineGiftGainView", cc.load("mvc").ViewBase)
OnlineGiftGainView.RESOURCE_FILENAME = "online_gift_gain.json"
OnlineGiftGainView.RESOURCE_BINDING = {
	["bg"] = "bg",
	["item"] = "item",
	["rewardPanel"] = "rewardPanel",
	["rewardPanel.list"] = "list",
	["label"] = "label",
}

function OnlineGiftGainView:onCreate(data)
	audio.playEffectWithWeekBGM("zaixianlibao.mp3")
	-- 领取特效
	local pnode = self:getResourceNode()
	widget.addAnimationByKey(pnode, "hupazaixianlibao/hupazaixianlibao.skel", 'hupazaixianlibao', "effect", 1)
		:anchorPoint(cc.p(0.5,0.5))
		:scale(2)
		:xy(pnode:width()/2, pnode:height()/2)

	performWithDelay(self, function()
		self.rewardPanel:setVisible(true)
		self.label:setVisible(true)

		self.data = dataEasy.mergeRawDate(data)
		self.intervalTime = 0.25

		self.list:setScrollBarEnabled(false)
		local listSize = self.list:size()
		local itemSize = self.item:size()
		local num = #self.data
		local margin = self.list:getItemsMargin()

		local x = self.list:x() + (listSize.width - itemSize.width * num - (num-1) * margin ) / 2
		local y = self.list:y()
		self.list:xy(x , y)

		self:showItem(1)
	end, 1)


	performWithDelay(self, function()
		self.bg:onClick(functools.partial(self.onClose, self))
	end, 2)
end

function OnlineGiftGainView:showItem(index)
	if index > #self.data then
		return
	end

	local item = self.item:clone()
	item:show()
	local data = self.data[index]
	local key = data.key
	local num = data.num
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
			},
			onNode = function(node)
				node:hide()
					:z(3)
				transition.executeSequence(node, true)
					:delay(0.5)
					:func(function()
						node:show()
					end)
					:done()
			end,
		},
	}
	local quality = 1
	if key ~= "card" then
		quality = dataEasy.getCfgByKey(key).quality
	end

	createSpine(item, "djhd","djhd"..quality, 4)
	createSpine(item, "djhd_hou","djhd_hou"..quality, 2)

	bind.extend(self, item, binds)
	self.list:pushBackCustomItem(item)
	transition.executeSequence(self.list, true)
		:delay(self.intervalTime)
		:func(function()
			self:showItem(index + 1)
		end)
		:done()
end

return OnlineGiftGainView