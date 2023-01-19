local BattleCrossMineView = class("BattleCrossMineView", battleModule.CBase)

BattleCrossMineView.RESOURCE_FILENAME = "battle_cross_mine.json"
BattleCrossMineView.RESOURCE_BINDING = {
	["selfInfo"] = "selfInfo",
	["enemyInfo"] = "enemyInfo",
	["totalScore"] = "totalScore",
	["totalScore.score"] = "scoreNum",
}

function BattleCrossMineView:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.root = cache.createWidget(self.RESOURCE_FILENAME)
	bindUI(self, self.root, self.RESOURCE_BINDING)
	self.root:addTo(parent, 99):show()
	self:init()
end

function BattleCrossMineView:init()
	nodetools.invoke(self.selfInfo, {"result1", "result2", "result3"}, "hide")
	nodetools.invoke(self.enemyInfo, {"result1", "result2", "result3"}, "hide")

	-- 显示区服
	local t = self.parent.data
	self.leftHeadPnl = self.parent.UIWidgetLeft:get("infoPVP")
	self.rightHeadPnl = self.parent.UIWidgetRight:get("infoPVP")
	self.leftHeadPnl:get("level")
		:setFontSize(40)
		:anchorPoint(0,0.5)
		:x(self.leftHeadPnl:get("roleName"):x())
		:setString(getServerArea(t.role_key[1], true))
	self.leftHeadPnl:get("levelLv"):visible(false)
	self.rightHeadPnl:get("level")
		:setFontSize(40)
		:anchorPoint(1,0.5)
		:x(self.rightHeadPnl:get("roleName"):x())
		:setString(getServerArea(t.defence_role_key[1], true))
	self.rightHeadPnl:get("levellv"):visible(false)
	self:call('refreshInfoPvP')

	self.root:setVisible(false)
end

function BattleCrossMineView:onInitPvp()
	self:setTeamIcon("selfInfo",1)
	self:setTeamIcon("enemyInfo",2)
	self:setScore(0, 0)

	self.root:setVisible(true)
end

function BattleCrossMineView:setTeamIcon(panel,idx)
	local play = self.parent:getPlayModel()
	local roleOut = play.data.roleOut[idx]

	local function getMaxFightpouintSeat(roles)
		local seat, fp = next(roles), 0
		for k, v in pairs(roles) do
			if v.fightPoint > fp then
				seat = k
				fp = v.fightPoint
			end
		end
		return seat
	end

	for i = 1,3 do
		local seat = getMaxFightpouintSeat(roleOut[i])
		local cardData = roleOut[i][seat]
		local item = self[panel]:get("iconBase"..i)
		local props = {
			unitId = cardData.roleId,
			advance = cardData.advance,
			level = cardData.level,
			star = cardData.star,
			grayState = 0,
			rarity = csv.unit[cardData.roleId].rarity,
			-- flip = (idx == 2)
		}
		BattleCrossMineView.setIconByData(item,props)
	end
end

function BattleCrossMineView.setIconByData(iconPanel,cardData)
	if iconPanel.panel then
		iconPanel:removeAllChildren()
	end
	local panelSize = cc.size(198, 198)
	local panel = ccui.Layout:create()
		:size(198, 198)
		:scale(0.8)
		:addTo(iconPanel, 1, "_card_")
	local quality = dataEasy.getQuality(cardData.advance, false)
	local boxRes = ui.QUALITY_BOX[quality]
	local imgBG = ccui.ImageView:create(boxRes)
		:alignCenter(panelSize)
		:addTo(panel, 1, "imgBG")
	local imgFG = ccui.ImageView:create(string.format("common/icon/panel_icon_k%d.png", quality))
		:alignCenter(panelSize)
		:addTo(panel, 3, "imgFG")
	iconPanel.panel = panel
	local icon = ccui.ImageView:create(csv.unit[cardData.unitId].cardIcon)
	:alignCenter(panelSize)
	:scale(2)
	:addTo(panel, 2, "icon")
	local grayState = cardData.grayState == 2 and "hsl_gray" or "normal"
	cache.setShader(imgBG, false, grayState)
	cache.setShader(icon, false, grayState)
	-- 等级
	local levelPanel = ccui.Layout:create()
		:size(150, 60)
		:align(cc.p(0, 1))
		:addTo(panel)
		:xy(90, 35)
		:z(4)
	local labelLv = cc.Label:createWithTTF("Lv", ui.FONT_PATH, 24)
		:align(cc.p(1, 0), 75, 55)
		:addTo(levelPanel, 2, "txtLv")
	text.addEffect(labelLv, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
	local txtLvNum = cc.Label:createWithTTF("", ui.FONT_PATH, 30)
		:align(cc.p(1, 0), 90, 55)
		:addTo(levelPanel, 2, "txtLvNum")
		:show()
		:text(cardData.level)
	text.addEffect(txtLvNum, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
	adapt.oneLinePos(txtLvNum, labelLv, cc.p(5, 0), "right")
	-- 星级
	local size = panel:size()
	local starPanel = ccui.Layout:create()
		:size(size.width, 70)
		:align(cc.p(0, 0), 0, 0)
		:addTo(panel, 5, "star")
	if tonumber(cardData.star) then
		local interval = 12
		local starNum = cardData.star > 6 and 6 or cardData.star
		for i=1,starNum do
			local starIdx = cardData.star - 6
			local icon = "city/card/equip/icon_star.png"
			if i <= starIdx then
				icon = "common/icon/icon_star_z1.png"
			end
			ccui.ImageView:create(icon)
				:xy(99 - interval * (starNum + 1 - 2 * i), 20)
				:addTo(starPanel, 4, "star")
				:scale(0.75)
		end
	end
	-- 稀有度
	local rarityPanel = ccui.ImageView:create()
		:align(cc.p(0.5, 0.5), 36, 164)
		:addTo(panel, 14, "rarity")
		:scale(0.62)
	if not tonumber(cardData.rarity) then
		rarityPanel:hide()
	else
		rarityPanel:texture(ui.RARITY_ICON[cardData.rarity]):show()
		imgBG:texture(ui.QUALITY_BOX[cardData.rarity+2])
		imgFG:show():texture(string.format("common/icon/panel_icon_k%d.png", cardData.rarity+2)):show()
	end

	if cardData.flip then
		iconPanel:setFlippedX(true)
	end
end

function BattleCrossMineView:onShowSpec(isShow)
	self.root:setVisible(isShow)
end

function BattleCrossMineView:onChangeWave(leftNum, totalNum, preWin)
	self:setScore(leftNum, totalNum - leftNum)
	if preWin then
		self:setWinFlag(preWin, totalNum, true)
		self:setWinFlag(3-preWin, totalNum, false)
		self:setLoseGray(leftNum, totalNum, 3-preWin)
	end
end

function BattleCrossMineView:setScore(leftNum, rightNum)
	local richText = rich.createByStr(string.format(gLanguageCsv.crossMinePVPScore, leftNum, rightNum), 40)
		:anchorPoint(0.5,0.5)
		:xy(self.scoreNum:x(), self.scoreNum:y())
		:addTo(self.totalScore)
		:z(10)
	self.scoreNum:removeFromParent()
	self.scoreNum = richText
end

function BattleCrossMineView:setWinFlag(force, wave, isWin)
	local panel = force == 1 and self.selfInfo or self.enemyInfo
	local pic = panel:get("result"..wave)
	if isWin then
		pic:loadTexture("battle/cross_mine/logo_win.png")
	else
		pic:loadTexture("battle/cross_mine/logo_lose.png")
	end
	pic:show()

end

function BattleCrossMineView:setLoseGray(leftNum, totalNum, preLose)
	local panel = preLose == 1 and self.selfInfo or self.enemyInfo
	local item = panel:get("iconBase"..totalNum)
	if item.panel then
		local imgBg = item.panel:get("imgBG")
		local icon = item.panel:get("icon")
		local grayState = cc.c3b(128, 128, 128)
		imgBg:color(grayState)
		icon:color(grayState)
	end
end

function BattleCrossMineView:onClose()
	ViewBase.onClose(self)
end

return BattleCrossMineView