local BASE_TIME = 0.08
local ExplorerSuccessView = class("ExplorerSuccessView", cc.load("mvc").ViewBase)

ExplorerSuccessView.RESOURCE_FILENAME = "explore_success_view.json"
ExplorerSuccessView.RESOURCE_BINDING = {
	["bg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose")
		}
	},
	["item"] = "item",
	["leftTxt"] = "leftTxt",
	["rightTxt"] = "rightTxt",
	["arrow"] = "arrow",
	["topList"] = "topList",
	["bottomList"] = "bottomList",
	["txt"] = "txt",
	["pos"] = "pos",
	["bg1"] = "bg1",
}

function ExplorerSuccessView:playEffect(name)
	local pnode = self:getResourceNode()
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

function ExplorerSuccessView:onCreate(dbHandler)
	self.topList:setScrollBarEnabled(false)
	self.bottomList:setScrollBarEnabled(false)
	self.data = dbHandler()
	if string.find(self.data.cfg.res, "skel") then
		local spine = widget.addAnimationByKey(self.pos, self.data.cfg.res, "explorer", "effect_loop", 1011)
		spine:xy(100, 0)
			:scale(2)
	else
		local imgBG = ccui.ImageView:create(self.data.cfg.res)
			:alignCenter(self.pos:size())
			:addTo(self.pos, 1)
	end
	text.addEffect(self.rightTxt, { color = ui.COLORS.QUALITY[self.data.cfg.quality]})
	if self.data.advance == 1 then
		self.leftTxt:text(gLanguageCsv.notActivatedTip)
		self.rightTxt:text(self.data.cfg.name.." +1")
		self:playEffect("jihuo")
	else
		text.addEffect(self.leftTxt, {color = ui.COLORS.QUALITY[self.data.cfg.quality]})
		self:playEffect("shengji")
		self.leftTxt:text(self.data.cfg.name..string.format(" +%d", self.data.advance - 1))
		self.rightTxt:text(self.data.cfg.name..string.format(" +%d", self.data.advance))
	end
	adapt.oneLinePos(self.leftTxt, {self.arrow, self.rightTxt}, cc.p(10, 0))
	local skillLevel = math.max(1, self.data.advance)
	local mainStrs = {verticalSpace = 21}
	for k,v in pairs(self.data.cfg.effect) do
		local effect = csv.explorer.explorer_effect[v]
		local str
		if effect.skillID then
			local skillCsv = csv.skill[effect.skillID]
			local currStr = string.format(effect.effectDesc, eval.doMixedFormula(skillCsv.describe, {skillLevel = skillLevel,math = math}, nil))
			str = "#C0x5B545B#" .. currStr
		else
			if effect.attrType1 and effect.attrType2 and effect.attrType3 and effect.attrType4 and effect.attrType5 and effect.attrType6 then
				local attrNum = dataEasy.getAttrValueString(effect.attrType1, effect.attrNum1[skillLevel])
				str = string.format(effect.effectDesc, attrNum)
			else
				local params = {}
				for i = 1, 6 do
					if effect["attrType"..i] and effect["attrNum"..i] then
						local attrType = getLanguageAttr(effect["attrType"..i])
						local attrNum = dataEasy.getAttrValueString(effect["attrType"..i], effect["attrNum"..i][skillLevel])
						table.insert(params,attrType)
						table.insert(params,attrNum)
					end
				end
				str = string.format(effect.effectDesc, unpack(params))
			end
			
		end
		table.insert(mainStrs, {str = str})
	end
	--主要效果
	beauty.textScroll({
		list = self.topList,
		effect = {color= ui.COLORS.NORMAL.DEFAULT},
		strs = mainStrs,
		isRich = true,
		margin = 20,
		align = "left",
	})

	local index
	for i,v in ipairs(self.data.cfg.extraEffCod) do
		if v == self.data.advance then
			index = i
		end
	end
	if index then
		local effectId = self.data.cfg.extraEff[index]
		local effect = csv.explorer.explorer_effect[effectId]
		local strs = {}
		if effect.skillID then
			local skillCsv =csv.skill[effect.skillID]
			local str = "#C0x5B545B#" .. eval.doMixedFormula(skillCsv.describe, {skillLevel = skillLevel,math = math}, nil)
			table.insert(strs, {str = "#C0x5B545B#" .. str})
		else
			local params = {}
			for i = 1, 6 do
				if effect["attrType"..i] and effect["attrNum"..i] then
					local attrType = getLanguageAttr(effect["attrType"..i])
					local attrNum = dataEasy.getAttrValueString(effect["attrType"..i], effect["attrNum"..i][skillLevel])
					table.insert(params,attrType)
					table.insert(params,attrNum)
				end
			end
			local str = string.format(effect.effectDesc, unpack(params))
			table.insert(strs, {str = str})
		end
		beauty.textScroll({
			list = self.bottomList,
			effect = {color=ui.COLORS.NORMAL.DEFAULT},
			strs = strs,
			isRich = true,
			margin = 20,
			align = "left",
		})
	else
		-- 居中处理
		local topListSizeHeight = self.topList:height()
		local topListSizeHeightNew = math.min(self.topList:getInnerContainerSize().height, topListSizeHeight*2) -- list新大小，不超过原大小两倍时，设为innersize
		self.topList:height(topListSizeHeightNew)
		self.topList:y(self.bg1:y() - topListSizeHeightNew/2)
		-- 居中处理
		self.bottomList:removeAllChildren()
		self.txt:text("")

	end
	uiEasy.setExecuteSequence(self.pos)
	uiEasy.setExecuteSequence(self.leftTxt)
	uiEasy.setExecuteSequence(self.arrow, {delayTime = BASE_TIME})
	uiEasy.setExecuteSequence(self.rightTxt, {delayTime = BASE_TIME * 2})
	uiEasy.setExecuteSequence(self.topList, {delayTime = BASE_TIME * 3})
	uiEasy.setExecuteSequence(self.txt, {delayTime = BASE_TIME * 4})
	uiEasy.setExecuteSequence(self.bottomList, {delayTime = BASE_TIME * 5})

	-- gGameUI:disableTouchDispatch(1 + BASE_TIME * 5)
end

return ExplorerSuccessView
