local DrawCardTools = {}

function DrawCardTools.hasCard(items)
	local cards = {}
	local betterRarity = -1
	local cardTab = csv.cards
	local unitTab = csv.unit
	local targetData
	for i,v in ipairs(items) do
		if v.key == "card" then
			local unitID = cardTab[v.num.id].unitID
			local rarity = unitTab[unitID].rarity
			if rarity > betterRarity then
				betterRarity = rarity
				targetData = v
			end
		elseif DrawCardTools.is2choose1item(v[1]) then
			local cfg = dataEasy.getCfgByKey(v[1])
			local rnd = math.random(1, 2)
			if cfg.specialArgsMap['choose'..rnd].card then
				targetData = {num = {id = cfg.specialArgsMap['choose'..rnd].card.id}}
			end
		end
	end
	if targetData then
		table.insert(cards, targetData)
	end

	return #cards > 0, cards
end

function DrawCardTools.is2choose1item(id)
	if not id then
		return false
	end
	local cfg = dataEasy.getCfgByKey(id)
	if cfg and cfg.type == game.ITEM_TYPE_ENUM_TABLE.chooseGift and cfg.specialArgsMap and csvSize(cfg.specialArgsMap) == 2 then
		for k, v in csvMapPairs(cfg.specialArgsMap) do
			if not v.card then
				return false
			end
		end
		return true
	end
	return false
end

function DrawCardTools.addLight(self, params)
	local parent = params.parent
	local parentEffect = params.parentEffect
	local datas = params.datas
	local count = params.count
	local cloneItem = params.cloneItem
	local cardCsv = csv.cards
	local unitCsv = csv.unit
	for i=1,count do
		local data = datas[i]
		local isHero = data.key == "card"
		local node = cloneItem:clone()
		node:addTo(parent, 1000)
		node:show()
		local binds = {
			class = "icon_key",
			props = {
				data = {
					key = isHero and "card" or data[1],
					num = isHero and data.num.id or data[2],
				},
				effect = "drawcard",
			},
		}
		bind.extend(self, node, binds)
		local isSpeLight = false
		if isHero then
			local unitID = cardCsv[data.num.id].unitID
			isSpeLight = unitCsv[unitID].rarity >= 4
		end
		local guangquan = isSpeLight and "effect_gjguangquan_loop" or "effect_guangquan_loop"
		widget.addAnimationByKey(node, "effect/xianshichouka.skel", "guanquan", guangquan, 1000)
			:scale(2)
			:alignCenter(node:size())
		local action = cc.RepeatForever:create(cc.Sequence:create(
			cc.CallFunc:create(function()
				local posx, posy = parentEffect:getPosition()
				local boneName = "icon_move" .. i
				local sx, sy = parentEffect:getScaleX(), parentEffect:getScaleY()
				local bxy = parentEffect:getBonePosition(boneName)
				local rotation = parentEffect:getBoneRotation(boneName)
				local scaleX = parentEffect:getBoneScaleX(boneName)
				local scaleY = parentEffect:getBoneScaleY(boneName)
				node:rotate(rotation)
					:scaleX(scaleX)
					:scaleY(scaleY)
					:xy(bxy.x * sx + posx, bxy.y * sy + posy)
			end)
		))
		node:runAction(action)
	end
end

function DrawCardTools.addCardImg(cards, parent)
	local time = 0
	local sprite = parent:getChildByName("effect")
	for idx,dt in ipairs(cards) do
		time = (idx - 1) * 70 / 30
		local node = parent:getChildByName("showCard")
		performWithDelay(parent, function()
			local unitID = csv.cards[dt.num.id].unitID
			local cfg = csv.unit[unitID]
			if not node then
				node = ccui.ImageView:create(cfg.cardShow)
					:alignCenter(parent:size())
					:addTo(parent, 20, "showCard")
			else
				node:texture(cfg.cardShow)
			end
			node:setColor(cc.c3b(0, 0, 0))
			local action = cc.RepeatForever:create(cc.Sequence:create(
				cc.CallFunc:create(function()
					local posx, posy = sprite:getPosition()
					local boneName = "jingling_move1"
					local sx, sy = sprite:getScaleX(), sprite:getScaleY()
					local bxy = sprite:getBonePosition(boneName)
					local rotation = sprite:getBoneRotation(boneName)
					local scaleX = sprite:getBoneScaleX(boneName)
					local scaleY = sprite:getBoneScaleY(boneName)
					node:rotate(rotation)
						:scaleX(scaleX)
						:scaleY(scaleY)
						:xy(bxy.x * sx + posx, bxy.y * sy + posy)
				end)
			))
			node:runAction(action)
		end, time)
	end

	return time - 4 / 30
end

return DrawCardTools