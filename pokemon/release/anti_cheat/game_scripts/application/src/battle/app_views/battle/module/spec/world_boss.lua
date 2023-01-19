-- @desc 世界boss副本的显示界面

local _format = string.format

local BattleWorldBossView = class("BattleWorldBossView", battleModule.CBase)

BattleWorldBossView.RESOURCE_FILENAME = "battle_world_boss.json"
BattleWorldBossView.RESOURCE_BINDING = {
	["bossLifePanel.award"] = "award",
	["bossLifePanel"] = "bossLifePanel",
}

-- call by battleModule.CBase.new
function BattleWorldBossView:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.root = cache.createWidget(self.RESOURCE_FILENAME)
	bindUI(self, self.root, self.RESOURCE_BINDING)
	-- self.root:addTo(parent.gameLayer):y(self.root:y() -150):show()
	self.root:addTo(parent,999):show()
	self:init()
end

function BattleWorldBossView:init()
	-- self.item2:hide()
	self.bossLifePanel:hide()
	self.sceneID = self.parent.sceneID
	
	self.bossLifePanel:show()
	self.awardLevel = -1

	-- 左侧的道具收集量显示
	-- local dropCfg = csv.huodong_drop[self.sceneID]
	-- if dropCfg then
	-- 	self.dropCfg = dropCfg
	-- 	-- 先显示百分比掉落的: 默认经验本金钱本就只有一种道具,多种道具的话,配置成礼包吧
	-- 	for key, _ in csvMapPairs(dropCfg.perDrop or {}) do
	-- 		local res = dataEasy.getIconResByKey(key)
	-- 		if res then
	-- 			self.item1Res = res
	-- 			self.item1:get("icon"):texture(res)
	-- 			self.item1:show()
	-- 			break
	-- 		end
	-- 	end
	-- 	-- 宝箱: 放节点掉落中的非百分比掉落里面的道具
	-- 	if not itertools.isempty(dropCfg.node) then
	-- 		self.item2:show()
	-- 	end
	-- end
end

function BattleWorldBossView:onNewBattleRound(args)
	-- 回合数设置
	local csvConfig = csv.scene_conf[self.parent.sceneID]
	local curRound = math.max(math.min(args.curRound, csvConfig.roundLimit), 0)
	self.bossLifePanel:get("round.round"):setString(_format(gLanguageCsv.theRound, curRound,csvConfig.roundLimit))
end

-- 初始化boss的血条
function BattleWorldBossView:onInitBossLife(infoArgs)
	local name = infoArgs.name
	local headIconRes = infoArgs.headIconRes	-- 头像
	local firstAward = infoArgs.damageAward[1]

	self.damageAward = infoArgs.damageAward

	if name then
		self.bossLifePanel:get("name"):text(name)
	end

	if headIconRes then
		self.bossLifePanel:get("headIcon"):texture(headIconRes)
	end

	local bar1 = self.bossLifePanel:get("bar1")
	local bar2 = self.bossLifePanel:get("bar2")

	-- local txt1 = self.bossLifePanel:get("hp")
	-- txt1:outlineColor(254, 253, 236, 1)
	text.addEffect(self.bossLifePanel:get("hp"),{
		outline = 
		{
			color = cc.c4b(254, 253, 236, 255)
		}
	})
	text.addEffect(self.bossLifePanel:get("hpMax"),{
		outline = 
		{
			color = cc.c4b(209, 128, 0, 255)
		}
	})
	self.fullWidth = bar2:width()
	-- bar2:loadTexture("city/adventure/goldbaby/bar_hxt.png")
	-- 	:setOpacity(200)
	-- 	:width(0)
		-- :anchorPoint(0,0.5)
		-- :x(bar2:x() - self.fullWidth/2)

	bar1:show()
	bar2:show()

	-- self.award
	self.awardEffect = widget.addAnimation(self.award, "worldboss/bossbaoxiang.skel", "effect", 100)
	self.awardEffect:anchorPoint(cc.p(0.5,0.5))
		:xy(cc.p(self.award:width()/2,self.award:height()/2))
		-- :addPlay("effect_loop")

	self:onRefreshBossHp(0,0,firstAward.damage,0)
	self:onRefreshBossAward(firstAward.boxRes,0)
end

-- 刷新boss进度条
function BattleWorldBossView:onRefreshBossHp(hp,damage,limit,level)
	if self.awardLevel > level then return end

	local showTime = 0.8
	local per = hp * 100
	local width = hp * self.fullWidth
	local bar1 = self.bossLifePanel:get("bar1")
	local bar2 = self.bossLifePanel:get("bar2")

	local txt1 = self.bossLifePanel:get("hp")
	local txt2 = self.bossLifePanel:get("hpMax")
	
	bar1:stopAllActions()
	-- 目标进度小于当前进度
	if self.awardLevel < level then
		self.awardLevel = level
		local nextLevel = self.awardLevel + 1
		txt2:setString("/" .. limit)
		bar1:setPercent(0)
		if self.damageAward[nextLevel] then
			self.award:loadTexture(self.damageAward[nextLevel].boxRes)
			self.awardEffect:stopAllActions()
			self.awardEffect:play("effect")
		end
	end
	txt1:setString(math.floor(damage))
	if math.abs(bar2:width() - width) < 1e-2 and math.abs(bar1:getPercent() - per) < 1e-2 then
		return
	end
	bar2:width(width)
	local sequence = transition.executeSequence(bar1)
		:progressTo(showTime, per)
	sequence:done()
end

function BattleWorldBossView:onRefreshBossAward(awardRes,level)
	if not level or not awardRes or (level and level == 0) then return end
	self.award:loadTexture(awardRes)
end

function BattleWorldBossView:onShowSpec(isShow)
	self.root:setVisible(isShow)
end

function BattleWorldBossView:onClose()
	ViewBase.onClose(self)
end


-- 坐标调整
-- local function updateBuffIconPos(sprite)
-- 	local scale = 1
-- 	local lineLimit = 13
-- 	local buffIconIdx = sprite.firstIdx
-- 	local box = sprite:getBoundingBox()
-- 	local offX = (buffIconIdx-1)%lineLimit*(box.width + 15)*scale
-- 	local offY = math.floor((buffIconIdx-1)/lineLimit)*box.height*scale
-- 	local newPos = cc.p(offX, offY)
-- 	sprite:setPosition(newPos)
-- 	-- sprite:getAni():scale(scale)

-- 	if sprite.overlayCountLabel then
-- 		sprite.overlayCountLabel:setPosition(cc.pAdd(newPos, cc.p(box.width*0.8, -4)))
-- 			-- :scale(scale)
-- 	end
-- end

-- function BattleWorldBossView:refreshBuffIcons(t)
-- 	local order = {}
-- 	for id, spr in pairs(t.buffEffectsMap) do
-- 		if spr:isVisible() then
-- 			table.insert(order, spr)
-- 		end
-- 	end
-- 	table.sort(order, function(a, b)
-- 		return a.firstIdx < b.firstIdx
-- 	end)
-- 	for i, spr in ipairs(order) do
-- 		spr.firstIdx = i
-- 	end
-- 	t.buffLastIndex = table.length(order)

-- 	--重排列下图标位置
-- 	for id, spr in pairs(t.buffEffectsMap) do
-- 		updateBuffIconPos(spr)
-- 	end
-- end

-- BuffIcon 会优先执行 这边只要映射就可以了
function BattleWorldBossView:onShowBuffIcon(unit, iconResPath, cfgId, overlayCount)
	if unit.model.isBoss then
		local t = gRootViewProxy:call("getRecord",unit,true)
		if not t.initByBoss then
			local buffStartPos = cc.p(580,-50)
			local scale = 0.8
			local buffNodeWorldPos = self.bossLifePanel:convertToWorldSpace(buffStartPos)
			t.shadowNode:unscheduleUpdate()
			t.buffGroupNode:xy(buffNodeWorldPos)
			t.buffOverlayNode:xy(buffNodeWorldPos)

			t.buffGroupNode:scale(scale)
			t.buffOverlayNode:scale(scale)

			t.lineLimit = 13
			
			t.buffGroupNode:setVisible(true)
			local prevVisible = nil
			t.shadowNode:scheduleUpdate(function()
				local visible = t.visible and self.root:visible()
				if prevVisible ~= visible then
					prevVisible = visible
					t.buffGroupNode:setVisible(visible)
					t.buffOverlayNode:setVisible(visible)
				end
			end)
			t.initByBoss = true
		end

		local sprite = t.buffEffectsMap[cfgId]
		if sprite == nil then return end

		-- sprite:getAni():scale(0.8)

		-- if sprite.overlayCountLabel then
		-- 	sprite.overlayCountLabel:scale(0.8)
		-- end

		-- self:refreshBuffIcons(t)
	end
end

-- function BattleWorldBossView:onDelBuffIcon(unit, cfgId)
-- 	if unit.model.isBoss then
-- 		local t = gRootViewProxy:call("getRecord",unit,true)
-- 		if t == nil then return end
		
-- 		-- self:refreshBuffIcons(t)
-- 	end
-- end


return BattleWorldBossView