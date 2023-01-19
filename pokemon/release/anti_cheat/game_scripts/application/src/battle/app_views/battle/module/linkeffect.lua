-- 连线特效管理
local LinkEffect = class('LinkEffect', battleModule.CBase)

local function alterLine(spr1, spr2, line, scaleX, isUpdate)
	local x1, y1, x2, y2
	if isUpdate then
		x1, y1 = spr1:x(), spr1:y()
		x2, y2 = spr2:x(), spr2:y()
	else
		x1, y1 = spr1:getSelfPos()
		x2, y2 = spr2:getSelfPos()
	end
	local effectPos1 = spr1.unitCfg.everyPos.hitPos
	local effectPos2 = spr2.unitCfg.everyPos.hitPos
	x1 = x1 + effectPos1.x
	y1 = y1 + effectPos1.y
	x2 = x2 + effectPos2.x
	y2 = y2 + effectPos2.y

	local len = math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))
	local box = line:getBoundingBox()
	local _scaleX = scaleX * (len / box.width)

	local p = {}
	p.x = x1 - x2
	p.y = y1 - y2
	local r = math.atan2(p.y, p.x)*180/math.pi

	line:scaleX(_scaleX):setRotation(-r)
end

function LinkEffect:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.lines = {}
	self.caster2Keys = {}
	self.isShow = true

	self.updateObjKey = nil
	self.updateObjSpr = nil
	self.lastx = 0
	self.lasty = 0
end

function LinkEffect:onUpdate(delta)
	if not (self.updateObjKey and self.isShow and self:checkObjMove()) then
		return
	end
	for key, data in pairs(self.lines) do
		local newKey, newSpr = self:tryGetCaster(data.casterKey)
		newKey = newKey or data.casterKey
		newSpr = newSpr or data.casterSpr
		if newKey == self.updateObjKey or data.holderKey == self.updateObjKey then
			alterLine(newSpr, data.holderSpr, data.line, data.scaleX, true)
		end
	end
end

function LinkEffect:checkObjMove()
	local x = self.updateObjSpr:x()
	local y = self.updateObjSpr:y()
	if x ~= self.lastx or y ~= self.lasty then
		self.lastx, self.lasty = x, y
		return true
	end
	return false
end

--{effectRes = "buff/lianjie/hero_yipeiertaer.skel";aniName =  "effect_lianjiexian_loop"; deep = 12; offsetPos = {'x'=0;'y'=0}}
function LinkEffect:onAddLinkEffect(holderKey, casterKey, cfg, buffId)
	local key = buffId
	if self.lines[key] then
		return
	end

	local effectRes = cfg.effectRes
	local aniName = cfg.aniName
	local offsetPos = cfg.offsetPos
	local deep = cfg.deep
	local scaleX = cfg.scaleX or 1

	local holderSpr = self:call('getSceneObj', holderKey)
	local casterSpr = self:call('getSceneObj', casterKey)

	offsetPos = offsetPos and cc.p(offsetPos.x, offsetPos.y) or cc.p(0, 0)
	if holderSpr.force == 2 then
		offsetPos = cc.p(-offsetPos.x, offsetPos.y)
	end
	local effectPos = holderSpr.unitCfg.everyPos.hitPos

	local newLine = newCSprite(effectRes)
	newLine:addTo(holderSpr, deep)
	newLine:setPosition(effectPos)
	newLine:play(aniName)
	newLine:setVisible(self.isShow)

	self.lines[key] = {
		line = newLine,
		holderKey = holderKey,
		casterKey = casterKey,
		holderSpr = holderSpr,
		casterSpr = casterSpr,
		scaleX = scaleX
	}

	self.caster2Keys[casterKey] = self.caster2Keys[casterKey] or {}
	local data = {
		key = holderKey,
		spr = holderSpr
	}
	if holderKey == casterKey then
		table.insert(self.caster2Keys[casterKey], 1, data)
	else
		table.insert(self.caster2Keys[casterKey], data)
	end

	local newKey, newSpr = self:tryGetCaster(casterKey)

	self:refreshByObj(newKey)
end

function LinkEffect:onDelLinkEffect(buffId)
	local key = buffId
	if not self.lines[key] then
		return
	end

	local tmpCasterKey = self.lines[key].casterKey
	if self.caster2Keys[tmpCasterKey] then
		for k, v in ipairs(self.caster2Keys[tmpCasterKey]) do
			if v.key == self.lines[key].holderKey then
				table.remove(self.caster2Keys[tmpCasterKey], k)
				break
			end
		end
	end

	local line = self.lines[key].line
	-- 回收时还原旋转 其它应用的地方没有旋转的初始化
	line:setRotation(0)
	removeCSprite(line)
	self.lines[key] = nil

	self:refreshByObj(self:tryGetCaster(tmpCasterKey))
end

function LinkEffect:onShowLinkEffect(isShow)
	if isShow == self.isShow then
		return
	end
	self.isShow = isShow
	for k, v in pairs(self.lines) do
		v.line:setVisible(isShow)
	end
end

function LinkEffect:onDoShiftPos(objKey)
	self:refreshByObj(objKey)
end

function LinkEffect:refreshByObj(objKey)
	for key, data in pairs(self.lines) do
		local newKey, newSpr = self:tryGetCaster(data.casterKey)
		newKey = newKey or data.casterKey
		newSpr = newSpr or data.casterSpr
		if newKey == objKey or data.holderKey == objKey then
			alterLine(newSpr, data.holderSpr, data.line, data.scaleX)
		end
	end
end

function LinkEffect:onUpdateLinkEffect(needUpdate, objKey)
	if needUpdate then
		self.updateObjSpr = self:call('getSceneObj', objKey)
		if self.updateObjSpr then
			self.updateObjKey = objKey
		end
	else
		self:refreshByObj(objKey)
		self.updateObjKey = nil
		self.updateObjSpr = nil
		self.lastx = 0
		self.lasty = 0
	end
end

function LinkEffect:tryGetCaster(objKey)
	local data = self.caster2Keys[objKey] and self.caster2Keys[objKey][1]
	if data then
		return data.key, data.spr
	end
end

return LinkEffect