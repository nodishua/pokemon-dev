--
-- @desc 通用设置道具项
--
local helper = require "easy.bind.helper"
local HeldItemTools = require "app.views.city.card.helditem.tools"
local ChipTools = require "app.views.city.card.chip.tools"

local iconByKey = class("iconByKey", cc.load("mvc").ViewBase)

iconByKey.defaultProps = {
	-- {key, num, targetNum, noColor, dbId} or idlertable
	-- 特殊已有写法 key="card"时, 为小写的 dbid
	-- key: 物品id "gold" "coin1" 或 "card"(卡牌), star_skill_points_%d 极限点
	-- num: 物品数量 没有角标可以不传 或 cardId 或 map{id, star}
	-- targetNum: 数量需求显示 num/targetNum
	-- noColor: hasNum/targetNum 这种样式的时候 hasNum是否需要变色（有时候并不是消耗的意思 不需要变色）
	data = nil,
	-- {lv, leftTopLv, maxStr, locked, showDress} or idlertable 携带道具专用
	-- lv leftTopLv 道具等级显示
	-- maxStar 精灵碎片判断最大星级，满星则显示满星标识
	specialKey = nil,
	grayState = 0, -- 0：不置灰，1：蒙版效果，2：置灰效果 3、仅仅icon蒙版效果
	isExtra = false,
	-- drawcard，gain 分别表示在抽卡，恭喜获得
	effect = nil,
	-- 表示道具没有点击详情
	noListener = nil,
	-- 去掉边框等显示，只显示中心内容
	simpleShow = nil,
	onNode = nil,
	-- 双倍 角标
	isDouble = nil,
}

function iconByKey:initExtend()
	if self.panel then
		self.panel:removeFromParent()
	end
	local panel = ccui.Layout:create()
		:alignCenter(self:size())
		:addTo(self, 1, "_icon_")
	self.panel = panel
	panel:setAnchorPoint(cc.p(0.5, 0.5))

	self.__type = nil
	self.__data = nil

	helper.callOrWhen(self.data, function(data)
		local panel = self.panel
		if data.key == "card" then
			local cardId, star = dataEasy.getCardIdAndStar(data.num)
			local cardCfg = csv.cards[cardId]
			local unitCfg = csv.unit[cardCfg.unitID]

			if not self.__data then
				self.__data = {cardId = idler.new(), star = idler.new(), rarity = idler.new()}
			end
			self.__data.cardId:set(cardId)
			self.__data.star:set(star)
			self.__data.rarity:set(unitCfg.rarity)
			if self.__type ~= "card" then
				self.__type = "card"
				panel:removeAllChildren()
				bind.extend(self, panel, {
					class = "card_icon",
					props = {
						cardId = self.__data.cardId,
						star = self.__data.star,
						rarity = self.__data.rarity,
						grayState = self.grayState,
						onNode = function(node)
							local bound = node:box()
							node:alignCenter(bound)
							panel:size(bound)
						end
					}
				})
			end
			self:setEffect(cardCfg)
		else
			local cfg, num, id, path
			self.isSpecialKey = false
			if string.find(data.key, "star_skill_points_%d+") then
				local markId = tonumber(string.sub(data.key, string.find(data.key, "%d+")))
				self.isSpecialKey = true
				local cardCfg = csv.cards[markId]
				if not cardCfg then
					return
				end
				cfg = dataEasy.getCfgByKey(cardCfg.fragID)
				num = data.num
				path = "city/card/system/extremity_property/icon_jxd.png"
			else
				cfg = dataEasy.getCfgByKey(data.key)
				num = data.num
				id = dataEasy.stringMapingID(data.key)
				path = dataEasy.getIconResByKey(id)
			end
			if not cfg then
				return
			end

			local quality = cfg.quality
			local boxRes = ui.QUALITY_BOX[quality]
			if self.__type ~= "item" then
				self.__type = "item"
				panel:removeAllChildren()
				local box = ccui.ImageView:create(boxRes)
				local size  = box:size()
				box:alignCenter(size)
					:addTo(panel, 1, "box")

				panel:size(size)
				-- self:setBackGroundColorType(1)
				-- self:setBackGroundColor(cc.c3b(200, 0, 0))
				-- self:setBackGroundColorOpacity(100)

				ccui.ImageView:create()
					:alignCenter(size)
					:scale(2)
					:addTo(panel, 2, "icon")

				ccui.ImageView:create()
					:alignCenter(size)
					:addTo(panel, 4, "imgFG")
			end
			panel:get("box"):texture(boxRes)
			panel:get("icon"):texture(path):scale(2):z(2)
			panel:get("imgFG"):texture(string.format("common/icon/panel_icon_k%d.png", quality))
			local grayState = self.grayState == 1 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)
			panel:get("box"):color(grayState)
			panel:get("icon"):color(grayState)
			local grayState = self.grayState == 2 and "hsl_gray" or "normal"
			cache.setShader(panel:get("box"), false, grayState)
			if self.grayState == 3 then
				grayState = "gray"
			end
			cache.setShader(panel:get("icon"), false, grayState)

			self:setNum(num, data.targetNum, quality, data.noColor)
			self:setLogo(id, cfg, num)
			self:setEffect(cfg)
			self:setItemState(data)
			self:setSpecialKey(data)

			if self.simpleShow then
				panel:get("box"):hide()
				panel:get("imgFG"):hide()
				if dataEasy.isChipItem(data.key) then
					panel:get("fragBg"):hide()
				end
			else
				panel:get("box"):show()
				panel:get("imgFG"):show()
			end

			if dev.SHOW_MAX_STAR then
				-- test 碎片显示当前精灵拥有最高星级
				panel:removeChildByName("_maxStar_")
				if dataEasy.isFragmentCard(id) then
					local markId = csv.cards[cfg.combID].cardMarkID
					local cards = gGameModel.role:read("cards")
					if cards then
						local maxStar = 0
						for i,v in ipairs(cards) do
							local card = gGameModel.cards:find(v)
							if card then
								local cardId = card:read("card_id")
								local cardCfg = csv.cards[cardId]
								if cardCfg.cardMarkID == markId then
									maxStar = math.max(maxStar, card:read("star"))
								end
							end
						end
						if maxStar > 0 then
							local maxStar = label.create(maxStar .. "星", {
								color = ui.COLORS.NORMAL.DEFAULT,
								fontSize = 30,
								fontPath = "font/youmi1.ttf",
								effect = {outline = {color=ui.COLORS.NORMAL.WHITE, size = 3}},
							})
							maxStar:addTo(panel, 111, "_maxStar_")
								:alignCenter(panel:size())
								:opacity(200)
						end
					end
				end
			end

			if dataEasy.isFragmentCard(id) then
				if csv.fragments[id] and matchLanguage(csv.fragments[id].languages) == false then
					errorInWindows("配置可获取到卡牌碎片 %s, 但 csv.fragments (%s) 未开放", id, LOCAL_LANGUAGE)
				end
			end
		end
		panel:setTouchEnabled(true)
		if not self.isSpecialKey and not self.noListener then
			bind.click(self, panel, {method = function()
				local params = {key = data.key, num = data.num, dbId = data.dbId}
				gGameUI:showItemDetail(panel, params)
			end})
		else
			-- 把前面的点击相应覆盖掉
			bind.click(self, panel, {method = function()
			end})
		end
	end)
	helper.callOrWhen(self.isExtra, function(isExtra)
		if isExtra then
			ccui.ImageView:create("common/txt/txt_ew.png")
				:align(cc.p(0.5, 0.5), 50, self.panel:box().height - 32)
				:addTo(panel, 5, "isExtra")
		else
			panel:removeChildByName("isExtra")
		end
	end)
	helper.callOrWhen(self.isDouble, function(isDouble)
		if isDouble then
			local size = panel:size()
			ccui.ImageView:create("common/icon/icon_sb.png")
				:align(cc.p(1, 1), size.width, size.height)
				:addTo(panel, 5, "isDouble")
		else
			panel:removeChildByName("isDouble")
		end
	end)
	if self.onNode then
		self.onNode(panel)
	end
	return self
end

-- @desc 设置通用道具数量
function iconByKey:setNum(num, targetNum, quality, noColor)
	local panel = self.panel
	local size = panel:size()
	local label = panel:get("num")
	local label1 = panel:get("num1")
	local label2 = panel:get("num2")
	if not targetNum then
		if not num or num == 0 then
			num = ""
		end
		local fontSize = 36
		if type(num) ~= "number" then
			num = gLanguageCsv[num] or num
			fontSize = 30
		end
		if not label then
			label = cc.Label:createWithTTF(num, ui.FONT_PATH, fontSize)
				:align(cc.p(1, 0), size.width - 30, 14)
				:addTo(panel, 10, "num")
			text.addEffect(label, {outline={color=ui.COLORS.QUALITY_OUTLINE[quality]}})
		end
		label:show():text(mathEasy.getShortNumber(num))
		if label1 then
			itertools.invoke({label1, label2}, "hide")
		end
	else
		num = num or 0
		if not label1 then
			label1 = ccui.Text:create(0, ui.FONT_PATH, 36)
				:align(cc.p(1, 0), size.width - 30, 14)
				:addTo(panel, 10, "num1")

			label2 = ccui.Text:create(0, ui.FONT_PATH, 36)
				:align(cc.p(1, 0), size.width - 40, 14)
				:addTo(panel, 10, "num2")
		end
		local fontSize = 36
		local outlineSize = 4
		local label2Color
		label1:show():text("/" .. mathEasy.getShortNumber(targetNum)):setFontSize(fontSize)
		label2:show():text(mathEasy.getShortNumber(num)):setFontSize(fontSize)
		text.addEffect(label1, {outline={color=ui.COLORS.QUALITY_OUTLINE[quality],size=outlineSize}})
		text.addEffect(label2, {outline={color=ui.COLORS.QUALITY_OUTLINE[quality],size=outlineSize}})

		-- 超框简单修正处理
		local dw = (label1:width() +  label2:width()) - 150
		if dw > 0 then
			fontSize = math.max(math.ceil(36 - dw/5), 26)
			outlineSize = 6
		end

		if not noColor then
			label2Color = (num >= targetNum) and ui.COLORS.NORMAL.ALERT_GREEN or ui.COLORS.NORMAL.ALERT_YELLOW
		end
		label1:setFontSize(fontSize)
		label2:setFontSize(fontSize)
		text.addEffect(label1, {outline={color=ui.COLORS.QUALITY_OUTLINE[quality],size=outlineSize}})
		text.addEffect(label2, {color=label2Color, outline={color=ui.COLORS.QUALITY_OUTLINE[quality],size=outlineSize}})

		-- 字体错位修正
		text.deleteAllEffect(label1)
		text.deleteAllEffect(label2)
		text.addEffect(label1, {outline={color=ui.COLORS.QUALITY_OUTLINE[quality],size=outlineSize}})
		text.addEffect(label2, {color=label2Color, outline={color=ui.COLORS.QUALITY_OUTLINE[quality],size=outlineSize}})

		adapt.oneLinePos(label1, label2, nil, "right")

		if label then
			label:hide()
		end
	end
end

-- @desc 设置通用道具角标
function iconByKey:setLogo(id, cfg, num)
	local panel = self.panel
	panel:removeChildByName("clipper")
	panel:removeChildByName("fragBg")
	panel:removeChildByName("fragFg")
	panel:removeChildByName("logoRes")
	if self.isSpecialKey then
		return
	end
	local size = panel:size()
	if dataEasy.isFragment(id) then
		self.__type = nil
		local fragBg = ccui.ImageView:create("common/icon/ico_sp.png")
			:align(cc.p(0.5, 0.5), size.width / 2, size.height / 2)
			:addTo(panel, 2, "fragBg")
		local fragFg = ccui.ImageView:create("common/icon/ico_sp1.png")
			:align(cc.p(0.5, 0.5), size.width / 2, size.height / 2)
			:addTo(panel, 4, "fragFg")

		local icon = self.panel:get("icon")
		-- icon:setRotation(-45)
		icon:retain()
		icon:removeFromParent()
		icon:xy(0, 0)
		local stencil = cc.Sprite:create("common/icon/ico_spzz.png")
		local clip = cc.ClippingNode:create()
			:setStencil(stencil)
			:setInverted(false)
			:setAlphaThreshold(0.05)
			:xy(cc.p(size.width / 2, size.height / 2))
			:add(icon, 1)
			:addTo(panel, 3, "clipper")
		icon:release()

		local grayState = self.grayState == 1 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)
		fragBg:color(grayState)
		fragFg:color(grayState)
		local grayState = self.grayState == 2 and "hsl_gray" or "normal"
		cache.setShader(fragBg, false, grayState)
		cache.setShader(fragFg, false, grayState)
		if csv.fragments[id].type ~= 1 then
			if num and num >= csv.fragments[id].combCount then
				local fragBg = ccui.ImageView:create("common/icon/txt_khc.png")
					:align(cc.p(0.5, 0.5), size.width / 2, size.height / 2 + 82)
					:addTo(panel, 10, "fragFg")
			end
		end

	elseif dataEasy.isZawakeFragment(id) and cfg.type == 5 then
		local fragBg = ccui.ImageView:create("common/icon/icon_zjx_02.png")
			:align(cc.p(0.5, 0.5), size.width / 2, size.height / 2)
			:scale(2)
			:addTo(panel, 2, "fragBg")
		local fragFg = ccui.ImageView:create("common/icon/icon_zjx_01.png")
			:align(cc.p(0.5, 0.5), size.width / 2, size.height / 2)
			:scale(2)
			:addTo(panel, 4, "fragFg")
		self.panel:get("icon")
			:scale(1.36)
			:z(3)
		local grayState = self.grayState == 1 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)
		fragBg:color(grayState)
		fragFg:color(grayState)
		local grayState = self.grayState == 2 and "hsl_gray" or "normal"
		cache.setShader(fragBg, false, grayState)
		cache.setShader(fragFg, false, grayState)

	elseif dataEasy.isChipItem(id) then
		local fragBg = ccui.ImageView:create(string.format("city/card/chip/icon_d_%d.png", cfg.quality))
			:align(cc.p(0.5, 0.5), size.width / 2, size.height / 2)
			:rotate(60 * (cfg.pos - 1))
			:addTo(panel, 2, "fragBg")
		local icon = self.panel:get("icon")
			:scale(1)
			:z(3)
		local grayState = self.grayState == 1 and cc.c3b(128, 128, 128) or cc.c3b(255, 255, 255)
		fragBg:color(grayState)
		local grayState = self.grayState == 2 and "hsl_gray" or "normal"
		cache.setShader(fragBg, false, grayState)
	end

	if cfg.specialArgsMap and cfg.specialArgsMap.logoRes then
		ccui.ImageView:create(cfg.specialArgsMap.logoRes)
			:align(cc.p(1, 1), size.width, size.height)
			:addTo(panel, 5, "logoRes")
	end
end

-- @desc 设置通用道具特效
function iconByKey:setEffect(cfg)
	local panel = self.panel
	panel:removeChildByName("effect")
	if self.isSpecialKey then
		return
	end
	local size = panel:size()
	helper.callOrWhen(self.effect, function(effect)
		local panel = self.panel
		panel:removeChildByName("effect")
		if effect and cfg.effect[effect] then
			widget.addAnimationByKey(panel, "effect/huanraoguang.skel", "effect", cfg.effect[effect], 5)
				:xy(size.width/2, size.height/2)
		else
			local sprite = panel:getChildByName("effect")
			if sprite then
				sprite:removeFromParent()
			end
		end
	end)
end

function iconByKey:setItemState(data)
	local panel = self.panel
	panel:removeChildByName("isDress")
	panel:removeChildByName("isExclusive")
	panel:removeChildByName("defaultLv")
	panel:removeChildByName('gemLevelBg')
	panel:removeChildByName('gemLevel')
	panel:removeChildByName('maxStarBg')
	panel:removeChildByName('maxStarText')
	panel:removeChildByName('locked')
	panel:removeChildByName('cardHead')
	panel:removeChildByName('cardHeadDi')
	if self.isSpecialKey then
		return
	end
	local size = panel:box()
	local size = panel:box()
	if dataEasy.isHeldItem(data.key) then
		local isDress, isExclusive = HeldItemTools.isExclusive({csvId = data.key, dbId = data.dbId})
		if isDress then
			ccui.ImageView:create("city/card/helditem/bag/icon_cd.png")
				:align(cc.p(0.5, 0.5), 30, size.height - 40)
				:addTo(panel, 5, "isDress")
		end
		if isExclusive then
			ccui.ImageView:create("common/icon/txt_zs.png")
				:align(cc.p(0.5, 0.5), size.width / 2, size.height - 32)
				:addTo(panel, 5, "isExclusive")
		end

	elseif dataEasy.isChipItem(data.key) then
		local isDress = ChipTools.isDress(data.dbId)
		if isDress and self.specialKey.showDress then
			ccui.ImageView:create("city/card/helditem/bag/icon_cd.png")
				:align(cc.p(0.5, 0.5), 30, size.height - 40)
				:addTo(panel, 5, "isDress")
		end
	end

	helper.callOrWhen(self.specialKey, function(specialKey)
		-- local panel = self.panel
		-- local size = panel:size()
		panel:removeChildByName("defaultLv")
		if specialKey.lv then
			local lv = cc.Label:createWithTTF("Lv." .. specialKey.lv, ui.FONT_PATH, 26)
				:align(cc.p(0, 0.5), 16, 65)
				:addTo(panel, 6, "defaultLv")
			text.addEffect(lv, {outline={color=ui.COLORS.NORMAL.DEFAULT}})
		end
		-- panel:removeChildByName('gemLevelBg')
		panel:removeChildByName('gemLevel')
		if specialKey.leftTopLv then
			local level = cc.Label:createWithTTF('Lv'..specialKey.leftTopLv, ui.FONT_PATH, 30)
				:align(cc.p(0, 1), size.height*0.06 + 10, size.height*0.95 - 10)
				:addTo(panel, 101, 'gemLevel')
			text.addEffect(level, {color=ui.COLORS.NORMAL.WHITE,outline={color=ui.COLORS.NORMAL.DEFAULT}})
			-- text.addEffect(level, {outline={color=ui.COLORS.NORMAL.DEFAULT}})
			-- local txtSize = level:size()
			-- local lvBg = ccui.Scale9Sprite:create()
			-- lvBg:initWithFile(cc.rect(29, 0, 1, 40), 'city/card/gem/box_djd1.png')
			-- lvBg:align(cc.p(0, 1), size.width * 0.1, size.height * 0.9)
			-- 	:addTo(panel, 100, 'gemLevelBg')
			-- 	:width(txtSize.width + 20)
		end
		panel:removeChildByName('maxStarBg')
		panel:removeChildByName('maxStarText')
		if specialKey.maxStar and dataEasy.isFragment(data.key) then
			local cardCsv = csv.cards[csv.fragments[data.key].combID]
			if cardCsv and dataEasy.getCardMaxStar(cardCsv.cardMarkID) == 12 then
				local label = cc.Label:createWithTTF(gLanguageCsv.maxStar, "font/youmi1.ttf", 40)
					:align(cc.p(0.5, 0.5), size.width * 0.11, size.height * 0.80 + 5)
					:scale(0.7)
					:addTo(panel, 101, 'maxStarText')
				text.addEffect(label, {color = cc.c4b(245, 144, 73, 255)})
				local txtSize = label:size()
				local maxStarBg = ccui.Scale9Sprite:create()
				maxStarBg:initWithFile(cc.rect(60, 0, 1, 1), 'city/shop/logo_shop_sp.png')
				maxStarBg:align(cc.p(0.5, 0.5), size.width * 0.11, size.height * 0.80)
					:addTo(panel, 100, 'maxStarBg')
					:scale(-0.7, 0.7)
				local bgWidth = math.min(txtSize.width + 35, 160)
				maxStarBg:width(bgWidth)
				label:scale(bgWidth/(txtSize.width + 35)*0.7)
			end
		end
		panel:removeChildByName("locked")
		if specialKey.locked then
			ccui.ImageView:create("city/card/chip/icon_lock.png")
				:addTo(panel, 10, "locked")
				:anchorPoint(1, 1)
				:xy(size.width-5, size.height-10)
		end

		panel:removeChildByName("cardHeadDi")
		panel:removeChildByName("cardHead")
		if specialKey.unitId then
			local bottomImg = ccui.ImageView:create("activity/world_boss/bg_tx.png")
				:scale(0.3)
				:anchorPoint(cc.p(0.5, 0.5))
				:opacity(150)
				:xy(size.width*0.8,size.height*0.2)
				:addTo(panel, 100, "cardHeadDi")

			local mask = cc.Sprite:create("activity/world_boss/bg_tx.png")
				:alignCenter(size)

			local logoClipping = cc.ClippingNode:create(mask)
				:setAlphaThreshold(0.1)
				:size(size)
				:anchorPoint(cc.p(0.5, 0.5))
				:xy(size.width*0.8,size.height*0.2)
				:scale(0.6)
				:addTo(panel, 100, "cardHead")

			local logo = ccui.ImageView:create(csv.unit[specialKey.unitId].cardIcon)
				:alignCenter(size)
				:addTo(logoClipping, 1, "logo")
				end
	end)
end

function iconByKey:setSpecialKey(data)
	local panel = self.panel
	panel:removeChildByName("starSkillPoints")
	local size = panel:box()
	if string.find(data.key, "star_skill_points_%d+") then
		panel:get("icon"):scale(1.8)
		local markId = tonumber(string.sub(data.key, string.find(data.key, "%d+")))
		local cardCfg = csv.cards[markId]
		local path = csv.unit[cardCfg.unitID].iconSimple
		ccui.ImageView:create(path)
			:addTo(panel, 3, "starSkillPoints")
			:alignCenter(size)
			:z(3)
			:scale(1.8)
	end
end

return iconByKey