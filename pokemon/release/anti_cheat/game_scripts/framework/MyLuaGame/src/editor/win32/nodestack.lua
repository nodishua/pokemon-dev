--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- UI堆栈显示
--

local iupeditor = {}
local ui = {}

function iupeditor:initNodeStack()
	ui.tree = iup.tree{}
	ui.dlg = iup.dialog{ui.tree; title = "NodesStack", size = "QUARTERxTHIRD"}
end

local props = {
	{"type", function(node)
		return tolua.type(node)
	end},
	{"name", "getName", function(node, val)
		node:setName(val)
	end},
	{"tag", "getTag", function(node, val)
		node:setTag(val)
	end},
	{"z", "getLocalZOrder", function(node, val)
		node:setLocalZOrder(val)
	end},
	{"visible", function(node)
		return tostring(node:isVisible())
	end, function(node, val)
		node:setVisible(val == "true")
	end},
	{"xy", function(node)
		local x, y = node:getPosition()
		return string.format("%d, %d", x, y)
	end, function(node, val)
		local t = string.split(val, ",")
		local x, y = tonumber(t[1]), tonumber(t[2])
		node:setPosition(x, y)
	end},
	{"worldxy", function(node)
		-- local x, y = node:getPosition()
		-- local pos = cc.p(x, y)
		-- if node:getParent() then
		-- 	pos = node:getParent():convertToNodeSpace(pos)
		-- end
		local pos = node:convertToWorldSpace(cc.p(0, 0))
		return string.format("%d, %d", pos.x, pos.y)
	end},
	{"anchor", function(node)
		local pos = node:getAnchorPoint()
		return string.format("%.2f, %.2f", pos.x, pos.y)
	end, function(node, val)
		local t = string.split(val, ",")
		local x, y = tonumber(t[1]), tonumber(t[2])
		node:setAnchorPoint(x, y)
	end},
	{"scale", function(node)
		return string.format("%.2f, %.2f", node:getScaleX(), node:getScaleY())
	end, function(node, val)
		local t = string.split(val, ",")
		local x, y = tonumber(t[1]), tonumber(t[2])
		node:setScale(x, y)
	end},
	{"size", function(node)
		local size = node:getContentSize()
		return string.format("%d, %d", size.width, size.height)
	end},
	{"box", function(node)
		local box = node:getBoundingBox()
		return string.format("%d, %d, %d, %d", box.x, box.y, box.width, box.height)
	end},
	{"texture", function(node)
		local spr = node
		if node.getVirtualRenderer then
			spr = node:getVirtualRenderer()
		end
		if spr and spr.getTexture then
			return display.director:getTextureCache():getTextureFilePath(spr:getTexture())
		end
		return ""
	end},
	{"enabled", function(node)
		if node.isEnabled then
			return tostring(node:isEnabled())
		end
		return ""
	end, function(node, val)
		if node.setEnabled then
			node:setEnabled(val == "true")
		end
	end},
	{"touch", function(node)
		if node.isTouchEnabled then
			return tostring(node:isTouchEnabled())
		end
		return ""
	end, function(node, val)
		if node.setTouchEnabled then
			node:setTouchEnabled(val == "true")
		end
	end},
	{"swallow_touch", function(node)
		if node.isSwallowTouches then
			return tostring(node:isSwallowTouches())
		end
		return ""
	end, function(node, val)
		if node.setSwallowTouches then
			node:setSwallowTouches(val == "true")
		end
	end},
	{"propagate_touch", function(node)
		if node.isPropagateTouchEvents then
			return tostring(node:isPropagateTouchEvents())
		end
		return ""
	end, function(node, val)
		if node.setPropagateTouchEvents then
			node:setPropagateTouchEvents(val == "true")
		end
	end},
}

local function newRenamePopup(title, val, onChange)
	-- Creates rename dialog
	local ok     = iup.button{title = "OK",size="EIGHTH"}
	local cancel = iup.button{title = "Cancel",size="EIGHTH"}
	local text   = iup.text{value=val, border="YES",expand="YES"}
	local dlg_rename = iup.dialog{iup.vbox{text, iup.hbox{ok,cancel}};
		defaultenter = ok,
		defaultesc = cancel,
		title = title,
		size = "QUARTER",
		startfocus = text
	}

	-- Callback called when the rename operation is cancelled
	function cancel:action()
		return iup.CLOSE
	end

	-- Callback called when the rename operation is confirmed
	function ok:action()
		onChange(text.value)
		ui.infoDlg:hide()
		return iup.CLOSE
	end

	return dlg_rename
end

local function showInfoDlg()
	local dlg = ui.infoDlg
	local width = tonumber(string.split(ui.dlg.rastersize, 'x')[1])
	dlg:showxy(ui.dlg.x + width, ui.dlg.y)

	local width1 = tonumber(string.split(dlg.rastersize, 'x')[1])
	local screenWidth = tonumber(string.split(iup.GetGlobal("SCREENSIZE"), 'x')[1])
	if dlg.x + width1/2 > screenWidth then
		dlg:showxy(ui.dlg.x - width, ui.dlg.y)
	end
end

function iupeditor:showNodesStack(path, onClose, onSelected)
	local tree = ui.tree

	function tree:selection_cb(id)
		id = tonumber(id)
		if ui.infoDlg then
			ui.infoDlg:destroy()
			ui.infoDlg = nil
		end
		if id == 0 then return end
		local title = tree["title"..id]

		local box = {}
		local child = path[id]
		for _, t in pairs(props) do
			local k, v, onChange = t[1], t[2], t[3]
			local val
			if type(v) == "string" then
				if child[v] then
					val = child[v](child)
				end
			else
				val = v(child)
			end
			if val then
				local labelKey = iup.label{title=k, font="14", fgcolor="0 0 255", size="100x"}
				local labelVal = iup.label{title=val, wordwrap="YES"}
				if onChange then
					function labelVal:button_cb(button, pressed, x, y, status)
						if button == iup.BUTTON1 then -- left mouse button (button 1);
							local dlg_rename = newRenamePopup(k, val, functools.partial(onChange, child))
							dlg_rename:popup(iup.CENTER, iup.CENTER)
							iup.SetFocus(dlg_rename)
						end
					end
				end
				table.insert(box, labelKey)
				table.insert(box, labelVal)
			end
		end
		box.numdiv = 2
		-- box.homogeneouscol = "YES"
		box.gapcol = "0"
		-- box.expandchildren = "HORIZONTAL"

		local grid = iup.gridbox(box)
		local dlg = iup.dialog{grid; title = title, size = "300xTHIRD"}
		ui.infoDlg = dlg
		showInfoDlg()

		onSelected(id)
	end

	local dlg = ui.dlg
	-- dlg:showxy(iup.CENTER, iup.CENTER)
	dlg:show()

	function dlg:close_cb()
		iupeditor:hideNodesStack()
		onClose()
		return iup.IGNORE
	end

	function dlg:move_cb(x, y)
		if ui.infoDlg then
			showInfoDlg()
		end
	end

	local stack = {}
	for i = 1, #path - 1 do
		local child = path[i]
		local info = {}
		if child:getName() == "" then
			info.branchname = string.format("%2d %s tag:%d z:%d", i, tolua.type(child), child:getTag(), child:getLocalZOrder())
		else
			info.branchname = string.format("%2d %s tag:%d name:%s z:%d", i, tolua.type(child), child:getTag(), child:getName(), child:getLocalZOrder())
		end
		table.insert(stack, info)
	end
	stack.branchname = "Stack"

	while tonumber(tree.childcount0) > 0 do
		tree.delnode1 = "SELECTED"
	end
	tree:AddNodes(stack)
end

function iupeditor:hideNodesStack()
	if ui.infoDlg then
		ui.infoDlg:destroy()
		ui.infoDlg = nil
	end
	ui.dlg:hide()
	iup.LoopStep()
end

return iupeditor