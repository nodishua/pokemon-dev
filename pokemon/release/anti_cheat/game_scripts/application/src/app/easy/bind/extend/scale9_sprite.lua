--
-- scale9Sprite
--

local scale9Sprite = class("scale9Sprite", cc.load("mvc").ViewBase)

scale9Sprite.defaultProps = {
	tileImg = 'common/login_bg_dw.png',
	maskImg = 'common/login_mask.png',
}

function scale9Sprite:initExtend()
	local size = self:getContentSize()
	local rect = self:getCapInsets()
	local tile = cc.Sprite:create(self.tileImg)
	tile:getTexture():setTexParameters(gl.LINEAR, gl.LINEAR, gl.REPEAT, gl.REPEAT)
	tile:setTextureRect(cc.rect(0, 0, size.width, size.height))
	tile:alignCenter(size)
	local mask = ccui.Scale9Sprite:create()
	mask:initWithFile(rect, self.maskImg)
	mask:size(size)
		:alignCenter(size)
	cc.ClippingNode:create(mask)
		:setAlphaThreshold(0.01)
		:size(size)
		:alignCenter(size)
		:add(tile)
		:addTo(self)
	return self
end

return scale9Sprite