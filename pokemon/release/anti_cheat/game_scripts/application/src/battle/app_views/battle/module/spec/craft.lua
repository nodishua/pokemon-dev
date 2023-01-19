local currentTextParam = {
	scale = 1.1,
	-- fontsize1 = 33,
	-- fontsize2 = 22,
	pos1 = {x = -9+25,y = 0+25},
	pos2 = {x = 7+25,y = -2+25}
}

local backupTextParam = {
	scale = 1,
	-- fontsize1 = 30,
	-- fontsize2 = 20,
	pos1 = {x = -11+25,y = 1+25},
	pos2 = {x = 8+25,y = -2+25}
}

local rankIconPos = {
	{
		{x = 34,y = 332},
		{x = 34,y = 131},
		{x = 181,y = 131},
	},
	{
		{x = 966,y = 332},
		{x = 966,y = 131},
		{x = 819,y = 131},
	},
}

local CraftSpecView = class("CraftSpecView", battleModule.CBase)

CraftSpecView.RESOURCE_FILENAME = "battle_craft.json"
CraftSpecView.RESOURCE_BINDING = {
	["selfMp"] = "selfMp",
	["enemyMp"] = "enemyMp",
	["selfWin"] = "selfWin",
	["enemyWin"] = "enemyWin",
	["selfInfo"] = "selfInfo",
	["enemyInfo"] = "enemyInfo",
}

-- call by battleModule.CBase.new
function CraftSpecView:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.root = cache.createWidget(self.RESOURCE_FILENAME)
	bindUI(self, self.root, self.RESOURCE_BINDING)
	-- TODO: ?与BattleView其它module层级问题?
	self.root:addTo(parent, 99):show()
	self:init()
	self:initBar(self.selfMp:get("progress"), 1)
	self:initBar(self.enemyMp:get("progress"), -1)

	self.selfInfoProgress = self.selfInfo:get("progress")
	self.enemyInfoProgress = self.enemyInfo:get("progress")
	self:initProgressBar(self.selfInfo:get("progress"))
	self:initProgressBar(self.enemyInfo:get("progress"))

	-- self.parent.UIWidgetLeft:get("infoPVP"):setVisible(false)
	-- self.parent.UIWidgetRight:get("infoPVP"):setVisible(false)
end

function CraftSpecView:init()
	self.selfWin:hide()
	self.enemyWin:hide()
	self.myHpPercent = 100
	self.enemyHpPercent = 100
	self.myMpPercent = 0
	self.enemyMpPercent = 0
	local play = self.parent:getPlayModel()
	self.isFinal = play.isFinal
	if not self.isFinal then
		nodetools.invoke(self.selfInfo, {"firstIcon", "secondIcon", "thirdIcon", "iconBase1", "iconBase2"}, "hide")
		nodetools.invoke(self.enemyInfo, {"firstIcon", "secondIcon", "thirdIcon", "iconBase1", "iconBase2"}, "hide")
	else
		self.backUpIconData = {{},{}}
	end
	self.root:setVisible(false)
end

function CraftSpecView:setCurrent(panel, idx)
	local play = self.parent:getPlayModel()
	local firstRoleOut = play.firstRoleout[idx]
	local bigHead = csv.unit[firstRoleOut.roleId].cardIcon2
	panel:get("current"):loadTexture(bigHead)
end

function CraftSpecView:setSkillName(panel,idx)
	local play = self.parent:getPlayModel()
	local firstRoleOut = play.firstRoleout[idx]
	local bigSkillName = ""
	for k,v in pairs(firstRoleOut.skills) do
		local skillCfg = csv.skill[k]
		if skillCfg.skillType2 == battle.MainSkillType.BigSkill then
			bigSkillName = skillCfg.skillName
		end
	end
	panel:get("skillname"):setString(bigSkillName)
	adapt.setTextScaleWithWidth(panel:get("skillname"), nil, 220)
end

function CraftSpecView:onInitPvp()
	self:setCurrent(self.selfInfo, 1)
	self:setCurrent(self.enemyInfo, 2)

	self:setSkillName(self.selfMp, 1)
	self:setSkillName(self.enemyMp, 2)

	local iconKeyMap = {"secondIcon", "thirdIcon"}

	local function setBackUp(panel,idx)
		local play = self.parent:getPlayModel()
		local backUp = play.backUp[idx]
		for i = 1,2 do
			local cardData = backUp[i]
			local item = self[panel]:get("iconBase"..i)
			if cardData then
				self.backUpIconData[idx][i] = cardData
				local props = {
					unitId = self.backUpIconData[idx][i].roleId,
					advance = self.backUpIconData[idx][i].advance,
					grayState = 0,
					flip = (idx == 2)
				}
				CraftSpecView.setIconByData(item,props)
			else
				self[panel]:get(iconKeyMap[i]):hide()
			end
		end
	end
	if self.isFinal then
		setBackUp("selfInfo",1)
		setBackUp("enemyInfo",2)
	end
	local names = self.parent.data.names
	self.selfInfo:get("name"):setString(names[1])
	self.enemyInfo:get("name"):setString(names[2])
	self.root:setVisible(true)
end

local function setRankIcon(panel,rank,idx)
	local function set(panel, pos, param)
		panel:move(pos):scale(param.scale)
		panel:get("num"):xy(param.pos1)
		panel:get("txt"):xy(param.pos2)
	end

	local p = nodetools.multiget(panel, "firstIcon", "secondIcon", "thirdIcon")
	if rank == 2 then
		set(p.firstIcon, rankIconPos[idx][3], backupTextParam)
		set(p.secondIcon, rankIconPos[idx][1], currentTextParam)
		set(p.thirdIcon, rankIconPos[idx][2], backupTextParam)
	elseif rank == 3 then
		set(p.firstIcon, rankIconPos[idx][2], backupTextParam)
		set(p.secondIcon, rankIconPos[idx][3], backupTextParam)
		set(p.thirdIcon, rankIconPos[idx][1], currentTextParam)
	end
end

function CraftSpecView:onChangeWave(winForce)
	if not self.isFinal then
		return
	end

	local function setBackUp(panel,idx)
		local play = self.parent:getPlayModel()
		local backUps = play.backUp[idx]
		local losers = play.loserRoleOut[idx]
		local panel = self[panel]
		local count = 0
		for k,v in pairs(losers) do
			count = count + 1
		end
		if count == 1 then --第一个刚被抬下去
			self.backUpIconData[idx][1] = backUps[1]
			self.backUpIconData[idx][2] = losers[1]
			for i = 1,2 do
				local item = panel:get("iconBase"..i)
				local props = {
					unitId = self.backUpIconData[idx][i].roleId,
					advance = self.backUpIconData[idx][i].advance,
					grayState = i,
					flip = (idx == 2)
				}
				CraftSpecView.setIconByData(item,props)
			end
			setRankIcon(panel,2,idx)
		elseif count == 2 then --只剩最后一个了
			self.backUpIconData[idx][1] = losers[1]
			self.backUpIconData[idx][2] = losers[2]
			for i = 1,2 do
				local item = panel:get("iconBase"..i)
				local props = {
					unitId = self.backUpIconData[idx][i].roleId,
					advance = self.backUpIconData[idx][i].advance,
					grayState = 2,
					flip = (idx == 2)
				}
				CraftSpecView.setIconByData(item,props)
			end
			setRankIcon(panel,3,idx)
		end
	end
	if winForce == 1 then
		self:setCurrent(self.enemyInfo, 2)
		self:setSkillName(self.enemyMp, 2)
		setBackUp("enemyInfo",2)
	else
		self:setCurrent(self.selfInfo, 1)
		self:setSkillName(self.selfMp, 1)
		setBackUp("selfInfo",1)
	end
end

local showTime = 0.1
local function setHpBar(progress, value)
	transition.executeSequence(progress)
		:progressTo(showTime, value)
		:done()
end

local function setMpBar(panel,value)
	local progress = panel:get("progress")
	local fullPanel = panel:get("full")
	local width = progress:size().width
	transition.executeSequence(progress)
		:func(function()
			if progress.whenChange then
				progress.whenChange(showTime, value)
			end
		end)
		:delay(showTime)
		:func(function()
			progress:visible(value < 100)
			fullPanel:visible(value >= 100)
		end)
		:done()
end

function CraftSpecView:onChangeHpMp(ratioTb)
	local function safeSet(value,num)
		if num >= 0 then
			self[value] = math.floor(num * 100)
		end
	end

	if ratioTb.selfHpRatio and ratioTb.enemyHpRatio then
		if ratioTb.selfHpRatio == -1 and self.myHpPercent == 1 then
			self.myHpPercent = 0
		end
		--当精灵最后的血量为1%被击杀时切换精灵，会导致下面的式子判断永远为0，
		--无法进行血条的更新，上面的式子先设置当切换精灵时如果血量为1%改成0%
		--TODO:修改血条更新逻辑
        if math.abs(self.myHpPercent - ratioTb.selfHpRatio) > 1e-5 then
            safeSet("myHpPercent",ratioTb.selfHpRatio)
            setHpBar(self.selfInfoProgress, self.myHpPercent)
        end

		if ratioTb.enemyHpRatio == -1 and self.enemyHpPercent == 1 then
			self.enemyHpPercent = 0
		end

        if math.abs(self.enemyHpPercent - ratioTb.enemyHpRatio) > 1e-5 then
            safeSet("enemyHpPercent",ratioTb.enemyHpRatio)
	        setHpBar(self.enemyInfoProgress, self.enemyHpPercent)
        end
    end

	if ratioTb.selfMpRatio and ratioTb.enemyMpRatio then
		if ratioTb.selfMpRatio == -1 and self.myMpPercent == 1 then
			self.myMpPercent = 0
		end

        if math.abs(self.myMpPercent - ratioTb.selfMpRatio) > 1e-5 then
            safeSet("myMpPercent",ratioTb.selfMpRatio)
            setMpBar(self.selfMp,self.myMpPercent)
        end

		if ratioTb.enemyMpRatio == -1 and self.enemyMpPercent == 1 then
			self.enemyMpPercent = 0
		end

        if math.abs(self.enemyMpPercent - ratioTb.enemyMpRatio) > 1e-5 then
            safeSet("enemyMpPercent",ratioTb.enemyMpRatio)
	        setMpBar(self.enemyMp,self.enemyMpPercent)
        end
    end
end

--spec不继承viewBase 绑定不管用 需要手动进行设置
function CraftSpecView.setIconByData(iconPanel,cardData)
	if iconPanel.panel then
		iconPanel:removeAllChildren()
	end
	local panelSize = cc.size(198, 198)
	local panel = ccui.Layout:create()
		:size(198, 198)
		:scale(0.7)
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
	if cardData.flip then
		iconPanel:setFlippedX(true)
	end
end

function CraftSpecView:onShowSpec(isShow)
	self.root:setVisible(isShow)
end

function CraftSpecView:onClose()
	ViewBase.onClose(self)
end

function CraftSpecView:initProgressBar(bar)
	local sprite9 = bar:getVirtualRenderer()
	local imgPath = sprite9:getTexture():getPath()
	local size = bar:size()
	local rect = sprite9:getCapInsets()

	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(rect, imgPath)
	mask:setScale9Enabled(true)
	mask:size(size)

	-- 增加遮罩，防止九宫格在末端显示出框
	-- 将原本的loadingbar移入clip
	local x, y = bar:xy()
	local parent = bar:parent()
	bar:retain():removeSelf():xy(0, 0)
	local clip = cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.15)
		:size(size)
		:add(bar)
		:xy(x, y)
		:addTo(parent)
	bar:release()
end

function CraftSpecView:initBar(bar, scale)
	local imgPath = "battle/craft/bar_card_b.png"
	local size = bar:size()
	local rect = cc.rect(0, 0, size.width, size.height)
	local width = size.width
	local img = ccui.Scale9Sprite:create()
	img:initWithFile(rect, imgPath)
	img:setScale9Enabled(isScale9Enabled)
	img:size(size)
		:anchorPoint(0, 0)
		:setCapInsets(rect)
	-- 设置遮罩
	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(rect, imgPath)
	mask:setScale9Enabled(isScale9Enabled)
	mask:size(size)
		-- :scale(scale, 1)
		:anchorPoint(0, 0)
		:setCapInsets(rect)

	cc.ClippingNode:create(mask)
			:setAlphaThreshold(0.15)
			:anchorPoint(0, 0)
			:size(size)
			:add(img, 999, "img")
			:x(scale == 1 and 0 or width)
			:scale(scale, 1)
			:addTo(bar, 999, "clip")

	bar.whenChange = function(showTime, p)
		local x = width * (p/100 - 1)
        img:stopAllActions()
		local sequence = transition.executeSequence(img)
			:moveTo(showTime, x, 0)
			:done()
	end
end

return CraftSpecView