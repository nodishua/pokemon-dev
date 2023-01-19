--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
-- ViewBase bind text文本相关
--

local helper = require "easy.bind.helper"

-- text
-- @param event: 文本
function bind.text(view, node, b)
	-- ccui.Button.setTitleText
	helper.bindData(view, node, b, node.setString or node.setTitleText)
end

-- effect
-- @param event: 字体颜色，描边
function bind.effect(view, node, b)
	helper.bindData(view, node, b, text.addEffect)
end

-- visible
-- @param event: 显隐
function bind.visible(view, node, b)
	helper.bindData(view, node, b, node.setVisible)
end

-- font
-- @param event: 字号
function bind.font(view, node, b)
	helper.bindData(view, node, b, node.setFontSize)
end
