--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind texture 图片相关
--

local helper = require "easy.bind.helper"

-- texture
-- @param event: 贴图路径
function bind.texture(view, node, b)
	helper.bindData(view, node, b, node.loadTexture)
end