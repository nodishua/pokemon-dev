local BASE_TIME = 0.08
local ExploreComponentSuccessView = class("ExploreComponentSuccessView", cc.load("mvc").ViewBase)

ExploreComponentSuccessView.RESOURCE_FILENAME = "explore_component_success_view.json"
ExploreComponentSuccessView.RESOURCE_BINDING = {
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose")
		}
	},
	["item"] = "item",
	["topList"] = {
		varname = "listview",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("topData"),
				item = bindHelper.self("item"),
				-- dataOrderCmp = function (a, b)
				-- 	return a.attrType < b.attrType
				-- end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("name", "left", "right", "arrow")
					childs.name:text(getLanguageAttr(v.attrType))
					childs.left:text(v.left)
					childs.right:text("+"..v.right)
					local baseDelay = BASE_TIME * (5 + k)
					uiEasy.setExecuteSequence({childs.name, childs.note}, {delayTime = baseDelay})
					uiEasy.setExecuteSequence(childs.left, {delayTime = baseDelay + BASE_TIME})
					uiEasy.setExecuteSequence(childs.arrow, {delayTime = baseDelay + BASE_TIME * 2})
					uiEasy.setExecuteSequence(childs.right, {delayTime = baseDelay + BASE_TIME * 3})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onColorClick"),
			},
		},
	},
	["leftPanel"] = "leftPanel",
	["rightPanel"] = "rightPanel",
	["leftTxt"] = "leftTxt",
	["rightTxt"] = "rightTxt",
	["arrow"] = "arrow",
	["leftName"] = "leftName",
	["rightName"] = "rightName",
}

function ExploreComponentSuccessView:playEffect(name)
	local pnode = self:getResourceNode()
	-- 结算特效
	local x,y = pnode:get("title"):getPosition()
	local textEffect = widget.addAnimationByKey(pnode, "level/jiesuanshengli.skel", "effect", string.format("xjiesuan_%szi", name), 100)
		:setAnchorPoint(cc.p(0.5,0.5))
		:xy(x,y)
	textEffect:addPlay(string.format("xjiesuan_%szi_loop", name))
	textEffect:retain()

	local bgEffect = CSprite.new("level/jiesuanshengli.skel")		-- 底部特效
	bgEffect:addTo(pnode, 99)
	bgEffect:setAnchorPoint(cc.p(0.5,0.5))
	bgEffect:setPosition(pnode:get("title"):getPosition())
	bgEffect:visible(true)
	-- 播放结算特效
	bgEffect:play("jiesuan_shenglitu")
	bgEffect:addPlay("jiesuan_shenglitu_loop")
	bgEffect:retain()
end

function ExploreComponentSuccessView:onCreate(data)
	local cfg = csv.explorer.component[data.id]
	uiEasy.setIconName(cfg.itemID, nil, {node = self.leftName})
	uiEasy.setIconName(cfg.itemID, nil, {node = self.rightName})
	if data.level == 1 then
		self:playEffect("jihuo")
		self:showPanel(data.id, 0, self.leftPanel)
		self:showPanel(data.id, 1, self.rightPanel)
		self.leftTxt:text(gLanguageCsv.notActivatedTip)
		self.rightTxt:text("Lv1")
		local t = {}
		for i = 1, 10 do
			if cfg["attrNumType"..i] and cfg["attrNumType"..i] ~= 0 then
				table.insert(t, {
					attrType = cfg["attrNumType"..i],
					left = "+".. dataEasy.getAttrValueString(cfg["attrNumType"..i], 0),
					right = dataEasy.getAttrValueString(cfg["attrNumType"..i], cfg["attrNum"..i][1]),
				})
			else
				break
			end
		end
		table.sort(t, function(a,b)
			return a.attrType < b.attrType
		end)
		self.topData = idlertable.new(t)
	else
		self:playEffect("shengji")
		self:showPanel(data.id, data.level - 1, self.leftPanel)
		self:showPanel(data.id, data.level, self.rightPanel)
		self.leftTxt:text("Lv"..data.level - 1)
		self.rightTxt:text("Lv"..data.level)
		local t = {}
		for i = 1, 10 do
			if cfg["attrNumType"..i] and cfg["attrNumType"..i] ~= 0 then
				table.insert(t, {
					attrType = cfg["attrNumType"..i],
					left = dataEasy.getAttrValueString(cfg["attrNumType"..i], cfg["attrNum"..i][data.level - 1]),
					right = dataEasy.getAttrValueString(cfg["attrNumType"..i], cfg["attrNum"..i][data.level]),
				})
			else
				break
			end
		end
		table.sort(t, function(a,b)
			return a.attrType < b.attrType
		end)
		self.topData = idlertable.new(t)
	end

	uiEasy.setExecuteSequence(self.leftPanel, {delayTime = BASE_TIME})
	uiEasy.setExecuteSequence(self.leftName, {delayTime = BASE_TIME * 2})
	uiEasy.setExecuteSequence(self.leftTxt, {delayTime = BASE_TIME * 3})
	uiEasy.setExecuteSequence(self.arrow, {delayTime = BASE_TIME * 2})
	uiEasy.setExecuteSequence(self.rightPanel, {delayTime = BASE_TIME * 4})
	uiEasy.setExecuteSequence(self.rightName, {delayTime = BASE_TIME * 5})
	uiEasy.setExecuteSequence(self.rightTxt, {delayTime = BASE_TIME * 6})

	-- gGameUI:disableTouchDispatch(1 + BASE_TIME * 18)
end

function ExploreComponentSuccessView:showPanel(id, level, itemPos)
	local cfg = csv.explorer.component[id]
	local itemCfg = csv.items[cfg.itemID]
	local boxRes = string.format("city/card/helditem/panel_icon_%d.png", itemCfg.quality)
	local size = itemPos:size()
	local imgBG = itemPos:get("bg")
	if not imgBG then
		imgBG = ccui.ImageView:create()
			:alignCenter(size)
			:addTo(itemPos, 1, "bg")
	end
	imgBG:texture(boxRes)
	local icon = itemPos:get("icon")
	if not icon then
		icon = ccui.ImageView:create()
			:alignCenter(size)
			:scale(2)
			:addTo(itemPos, 2, "icon")
	end
	local iconMask = itemPos:get("iconMask")
	if iconMask then
		iconMask:visible(level == 0)
		iconMask:texture(itemCfg.icon)
			:scale(2)
	end
	icon:texture(itemCfg.icon)
	itemPos:scale(1.2)
end

function ExploreComponentSuccessView:onColorClick(list, k, v)
	self.bottomData:atproxy(k).selected = not self.bottomData:atproxy(k).selected
	-- if self.bottomData:atproxy(k).selected then
	for i, v in self.data:ipairs() do
		if v:proxy().cfg.quality == k then
			self.data:atproxy(i).selected = self.bottomData:atproxy(k).selected
			-- if not self.data:atproxy(i).targetNum then
				self.data:atproxy(i).targetNum = self.data:atproxy(i).num
			-- end
		end
	end
end

function ExploreComponentSuccessView:onDecompose()
	local t = {}
	for i, v in self.data:ipairs() do
		if self.data:atproxy(i).targetNum and self.data:atproxy(i).targetNum > 0 then
			t[self.data:atproxy(i).id] = self.data:atproxy(i).targetNum
		end
	end

	gGameApp:requestServer("/game/explorer/component/decompose",function (tb)
		self.decomposeNum:set(0)
	end, t)
end

return ExploreComponentSuccessView
