--
-- ViewBase bind scroll 相关
--
local helper = require "easy.bind.helper"

-- @param event: 显隐
function bind.scrollBarEnabled(view, node, b)
	-- ccui.ScrollView.setScrollBarEnabled
	helper.bindData(view, node, b, node.setScrollBarEnabled)
end

