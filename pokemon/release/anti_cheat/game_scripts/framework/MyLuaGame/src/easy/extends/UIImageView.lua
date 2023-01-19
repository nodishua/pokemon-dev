--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ccui.ImageView原生类的扩展
--

local ImageView = ccui.ImageView
local ImageViewCls = getmetatable(ImageView)
local NodeCls = getmetatable(cc.Node)

local getContentSize = NodeCls.getContentSize
local loadTexture = ImageViewCls.loadTexture
local create = ImageViewCls.create
local tolua_isnull = tolua.isnull

-- const std::string& texture,TextureResType texType
function ImageView:texture(...)
	self:loadTexture(...)
	return self
	-- 有些参数不合理，传入参数为nil
	-- local filename = ...
	-- if filename then
	-- 	self:loadTexture(...)
	-- else
	-- 	return self:getVirtualRenderer():getResourceName()
	-- end
	-- return self
end

-- -- test for async load
-- function ImageView:loadTexture(path)
-- 	-- return ImageView.loadTexture(self, path, texType)
-- 	self.loadingPath = path
-- 	cache.getTextureAsync(path, function(tex)
-- 		if not tolua_isnull(self) and path == self.loadingPath then
-- 			loadTexture(self, path)
-- 			self.loadingPath = nil
-- 		end
-- 	end)
-- end

-- function ImageView:create(path)
-- 	local self = create(ImageView, "")
-- 	self:loadTexture(path)
-- 	return self
-- end

-- function ImageView:getContentSize()
-- 	-- print('before load', self, dumps(getContentSize(self)), self.loadingPath)
-- 	if self.loadingPath then
-- 		cache.getTexture(self.loadingPath)
-- 		loadTexture(self, self.loadingPath)
-- 		-- print('after load', self, self.loadingPath, dumps(getContentSize(self)))
-- 		self.loadingPath = nil
-- 	end
-- 	return getContentSize(self)
-- end
