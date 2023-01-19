--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind progress相关
--

local helper = require "easy.bind.helper"

-- percent
-- @param event: 进度值
function bind.percent(view, node, b)
	helper.bindData(view, node, b, node.setPercent)
end