local fishingTools = require "app.views.city.adventure.fishing.tools"
local ViewBase = cc.load("mvc").ViewBase
local FishingAwardView = class('FishingAwardView',ViewBase)
FishingAwardView.RESOURCE_FILENAME = 'fishing_award.json'


FishingAwardView.RESOURCE_BINDING = {
	["point"] = "point",
	["award"] = "award",
	["list"] = "list",
	["fishList"] = "fishList",
	["fishItem"] = "fishItem",
}

function FishingAwardView:onCreate(data, scene, oldLv)
	self:initSkel()
	self:initModel()

	self.list:setScrollBarEnabled(false)
	self.fishList:setScrollBarEnabled(false)

	-- 等级积分
	local point = 0
	if scene == game.FISHING_GAME then
		for k,v in pairs(data.fish) do
			local cfg = csv.fishing.fish
			point = point + (cfg[k].point * v)
		end
	end
	self.point:get("txt2"):text(data.win + data.fail)
	self.point:get("txt4"):text(data.win)
	self.point:get("txt6"):text(data.fail)
	self.point:get("txt8"):text(point)
	adapt.oneLinePos(self.point:get("txt1"),{
		self.point:get("txt2"),
		self.point:get("txt3"),
		self.point:get("txt4"),
		self.point:get("txt5"),
		self.point:get("txt6"),
		self.point:get("txt7"),
		self.point:get("txt8"),
		self.point:get("txt9")}, cc.p(5, 0), "left")

	idlereasy.any({self.fishLevel, self.fishCounter, self.targetCounter}, function(_, fishLevel,fishCounter,targetCounter)
		self.point:get("lv"):text(string.format(gLanguageCsv.fishingLv, fishLevel))

		local nowExp, nextExp = fishingTools.getExp(fishLevel, fishCounter, targetCounter)
		if fishLevel == table.length(csv.fishing.level) then
			self.point:get("num1"):text("Max")
			self.point:get("num2"):hide()
			self.point:get("bar"):setPercent(100)
		else
			self.point:get("num1"):text(nowExp)
			self.point:get("num2"):text("/"..nextExp)
			self.point:get("bar"):setPercent(cc.clampf(100*(nowExp/nextExp), 0, 100))
		end
		adapt.oneLinePos(self.point:get("lv"), self.point:get("barBg"), cc.p(15, 0), "left")
		adapt.oneLinePos(self.point:get("lv"), self.point:get("bar"), cc.p(15, 0), "left")
		adapt.oneLinePos(self.point:get("bar"), self.point:get("num1"), cc.p(15, 0), "left")
		adapt.oneLinePos(self.point:get("num1"), self.point:get("num2"), cc.p(0, 0), "left")
	end)

	self.point:removeFromParent()
	self.list:pushBackCustomItem(self.point)

	-- 鱼
	local fishList
	local i = 1
	for k,v in pairs(data.fish) do
		if i%6 == 1 then
			fishList = self.fishList:clone()
			fishList:show()
			self.list:pushBackCustomItem(fishList)
		end
		local fishItem = self.fishItem:clone():show()

		bind.extend(self, fishItem, {
			class = "fish_icon",
			props = {
				data = {
					key = k,
					num = v,
				},
				onNode = function(node)
					node:xy(10, 10)
				end,
				onNodeClick = true,
			},
		})

		fishList:pushBackCustomItem(fishItem)
		i = i + 1
	end

	-- 奖励note
	self.award:removeFromParent()
	self.list:pushBackCustomItem(self.award)

	-- 奖励
	local awardList
	local awardCfg = {}

	for k,v in pairs(data.award) do
		if k == "cards" then
			for j,val in pairs(data.award.cards) do
				table.insert(awardCfg, {
					key = "id",
					val = val.id,
				})
			end
		elseif k ~= "cards" and k ~= "carddbIDs" and k ~= "card2mailL" then
			table.insert(awardCfg, {
				key = k,
				val = v,
			})
		end
	end

	i = 1
	for k,v in pairs(awardCfg) do
		if i%6 == 1 then
			awardList = self.fishList:clone()
			awardList:show()
			self.list:pushBackCustomItem(awardList)
		end
		local awardItem = self.fishItem:clone():show()

		if v.key == "id" then
			local unitID = csv.cards[v.val].unitID
			local star = csv.cards[v.val].star
			local rarity = csv.unit[unitID].rarity
			bind.extend(self, awardItem, {
				class = "card_icon",
				props = {
					unitId = unitID,
					rarity = rarity,
					star = star,
					onNodeClick = function(node)
						self:onitemClick(node, v.val)
					end
				},
			})
		else
			bind.extend(self, awardItem, {
				class = "icon_key",
				props = {
					data = {
						key = v.key,
						num = v.val,
					}
				},
			})
		end

		awardList:pushBackCustomItem(awardItem)
		i = i + 1
	end

	if self.fishLevel:read() > oldLv then
		gGameUI:stackUI("city.adventure.fishing.upgrade")
	end
end

-- spine
function FishingAwardView:initSkel()
	-- 恭喜获得特效
	local pnode = self:getResourceNode()
	widget.addAnimationByKey(pnode, "effect/gongxihuode.skel", 'gongxihuode', "effect", 10)
		:anchorPoint(cc.p(0.5,0.5))
		:xy(pnode:width()/2, pnode:height() - 300)
		:addPlay("effect_loop")
end

function FishingAwardView:initModel()
	self.fishLevel = gGameModel.fishing:getIdler("level")
	self.fishCounter = gGameModel.fishing:getIdler("fish_counter")
	self.targetCounter = gGameModel.fishing:getIdler("target_counter")
end

-- 精灵详情
function FishingAwardView:onitemClick(node, id)
	gGameUI:showItemDetail(node, {key = "card", num = id})
end

return FishingAwardView