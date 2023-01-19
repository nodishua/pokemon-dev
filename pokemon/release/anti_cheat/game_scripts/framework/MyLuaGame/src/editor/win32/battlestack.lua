--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- UI堆栈显示
--

local iupeditor = {}
local ui = {}

function iupeditor:initBattleStack()
	ui.tree = iup.tree{}
	ui.tree2 = iup.tree{}
	ui.box = iup.hbox{ui.tree, ui.tree2}
	ui.dlg = iup.dialog{ui.box, title = "BattleStack", size = "THIRDxHALF"}
end

local argFunc = function(obj,args)
    if type(args) == "string" then return obj[args] end
    local lastArgName = ""
    local ref
    for _,argName in ipairs(args) do
        if ref then
            ref = ref[argName]
        else
            ref = obj[argName]
        end
        assertInWindows(ref, "cfgId: %s %s is nil?! last: %s",obj.cfgId,argName,lastArgName)
        lastArgName = argName
    end
    return ref
end

local getConfigStr = function(config,index)
    for str,v in pairs(config) do
        if v == index then
            return str
        end
    end
end

local props = {
	{"hp", function(obj)
		return table.concat({obj:hp(),obj:hpMax()}, ",")
	end},
	{"mp1", function(obj)
		return table.concat({obj:mp1(),obj:mp1Max()}, ",")
	end},
    {"totalDamage", function(obj)
        local ret = {
			branchname = "damage[Normal/Valid/OverFlow]",
			state = "COLLAPSED",
		}
		for k, v in pairs(battle.DamageFrom) do
            local values = obj.totalDamage[v]
			table.insert(ret, string.format("%s: %s/%s/%s", k, values:get(battle.ValueType.Normal),values:get(battle.ValueType.Valid),values:get(battle.ValueType.OverFlow)))
		end
		return ret
	end},
	{"totalResumeHp", function(obj)
        local ret = {
			branchname = "resumeHp[Normal/Valid/OverFlow]",
			state = "COLLAPSED",
		}
		for k, v in pairs(battle.ResumeHpFrom) do
            local values = obj.totalResumeHp[v]
			table.insert(ret, string.format("%s: %s/%s/%s", k, values:get(battle.ValueType.Normal),values:get(battle.ValueType.Valid),values:get(battle.ValueType.OverFlow)))
		end
		return ret
    end},
	{"attrs", function(obj)
		local ret = {
			branchname = "attrs",
			state = "COLLAPSED",
		}
		local normalAttrs = {}
		local specPriority = {"speed", "damage", "specialDamage", "defence", "specialDefence"}
		for k, v in ipairs(specPriority) do
			table.insert(ret, string.format("%s: %s", v, obj[v](obj)))
		end

		for k, v in pairs(ObjectAttrs.AttrsTable) do
			if not specPriority[k] then table.insert(normalAttrs, k) end
		end
		table.sort(normalAttrs, function(a, b)
			return a < b
		end)
		for _, v in ipairs(normalAttrs) do
			table.insert(ret, string.format("%s: %s", v, obj[v](obj)))
		end
		return ret
	end},
    {"buffs", function(obj)
		local ret = {
			branchname = "buffs",
			state = "COLLAPSED",
		}
		local has_icon = {
			branchname = "has_icon",
			state="COLLAPSED"
		}
		local no_icon = {
			branchname = "no_icon",
			state="COLLAPSED"
		}
        local show = {
            casterId = {"caster","id"},
            holderId = {"holder","id"},
            easyEffectFunc = {"csvCfg","easyEffectFunc"},
            buffValue = "buffValue",
            lifeRound = "lifeRound",
            startRound = "startRound",
            lifeRoundType = {"csvCfg","lifeRoundType"},
            overlayType = "overlayType",
            overlayCount = "overlayCount",
        }
        if obj.buffs then
            for _,buff in obj:iterBuffs() do
				local _ret = {branchname = string.format("id: %s,cfgId: %s,effect: %s",buff.id,buff.cfgId,buff.csvCfg.easyEffectFunc),state = 'COLLAPSED'}
				if string.len(buff.csvCfg.iconResPath) > 2 then
					table.insert(has_icon,_ret)
				else
					table.insert(no_icon,_ret)
				end
			    for k,v in pairs(show) do
                    table.insert(_ret, string.format("%s: %s", k, argFunc(buff,v)))
                end
		    end
			table.insert(ret, has_icon)
			table.insert(ret, no_icon)
        end
		return ret
	end},
	{"skills", function(obj)
		local ret = {
			branchname = "skills",
			state = "COLLAPSED",
		}
		if obj.skills then
			for _,skill in obj:iterSkills() do
				table.insert(ret, string.format("activeSkillId: %s", skill.id))
			end
		end
		if obj.passiveSkills then
			for _, skill in pairs(obj.passiveSkills) do
				table.insert(ret, string.format("passiveSkillId: %s", skill.id))
			end
		end
		return ret
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

local curBattleRound
local prevAction
function iupeditor:showBattleStack(view, onClose, onSelected)
	local tree1 = ui.tree
	local tree2 = ui.tree2
	local scene = view._model.scene

	local function selection_cb(tree, id)
		id = tonumber(id)
		onSelected(id)
	end
	tree1.selection_cb = selection_cb
	tree2.selection_cb = selection_cb

	local dlg = ui.dlg
	-- dlg:showxy(iup.CENTER, iup.CENTER)
	dlg:show()

	function dlg:close_cb()
        curBattleRound = nil -- 清除缓存回合数

		if gGameUI.uiRoot == view then
			view:stopAction(prevAction)
		end

		iupeditor:hideBattleStack()
		onClose()
		return iup.IGNORE
	end

	function dlg:move_cb(x, y)
		if ui.infoDlg then
			showInfoDlg()
		end
	end

	local function show()
		if curBattleRound == scene.play.curBattleRound then
			return
		end
		curBattleRound = scene.play.curBattleRound
		while tree1.childcount0 and tonumber(tree1.childcount0) > 0 do
			tree1.delnode1 = "SELECTED"
		end
		while tree2.childcount0 and tonumber(tree2.childcount0) > 0 do
			tree2.delnode1 = "SELECTED"
		end

		local stack1, stack2 = {}, {}
		local function storeObjInfo(i, obj, objType)
			if not obj or obj.type ~= objType then return end
			local info = {}
			info.branchname = string.format("%2d %s", i, tj.type(obj))
			info.state = 'EXPANDED'
			if obj then
				info.branchname = string.format("%2d %s unit %s card %s", i, tj.type(obj), obj.unitID, obj.cardID)
				for k, prop in ipairs(props) do
					local v = prop[2](obj)
					if type(v) == "table" then
						info[k] = v
					else
						info[k] = string.format("%s: %s",prop[1], v)
					end
				end
			end
			if i <= 6 then
				table.insert(stack1, info)
			else
				table.insert(stack2, info)
			end
		end
		for i = 1, 12 do
			local obj = scene:getObjectBySeat(i)
			storeObjInfo(i, obj, battle.ObjectType.Normal)

			local exObj = scene:getObjectBySeat(i, battle.ObjectType.SummonFollow)
			storeObjInfo(i, exObj, battle.ObjectType.SummonFollow)
		end
		stack1.branchname = "force1"
		tree1:AddNodes(stack1)
		stack2.branchname = "force2"
		tree2:AddNodes(stack2)
	end
	show()
	prevAction = schedule(view, show, 5)
end

function iupeditor:hideBattleStack()
	if ui.infoDlg then
		ui.infoDlg:destroy()
		ui.infoDlg = nil
	end
	ui.dlg:hide()
	iup.LoopStep()
end

local lnconv = require 'net.lnconv'
local sock
function iupeditor:showBattleStackOutside(view)
	local scene = view._model.scene

	if sock == nil then
		sock = socket.tcp()
		-- sock:settimeout(0) -- 非阻塞
		sock:setoption('keepalive', true)
		sock:setoption('tcp-nodelay', true)
		sock:connect('127.0.0.1', 1337)
	end

	local function show()
		if curBattleRound == scene.play.curBattleRound then
			return
		end
		curBattleRound = scene.play.curBattleRound

		local stack1, stack2 = {}, {}
		for i = 1, 12 do
			local obj = scene:getObjectBySeat(i)
			local info = {}
			info.branchname = string.format("%2d %s", i, tj.type(obj))
			info.state = 'EXPANDED'
			if obj then
				info.branchname = string.format("%2d %s unit %s card %s", i, tj.type(obj), obj.unitID, obj.cardID)
				for k, prop in ipairs(props) do
					local v = prop[2](obj)
					if type(v) == "table" then
						-- info[k] = v
						local vv = {}
						for k2, v2 in pairs(v) do
							if type(v2) == "string" and v2:find(":") then
								local p = v2:find(":")
								v2 = {k = v2:sub(1, p-1), v = v2:sub(p+1)}
							end
							vv[k2] = v2
						end
						info[k] = vv
					else
						-- info[k] = string.format("%s: %s",prop[1], v)
						info[k] = {k = prop[1], v = v}
					end
				end
			end
			if i <= 6 then
				table.insert(stack1, info)
			else
				table.insert(stack2, info)
			end
		end
		local jdata = json.encode({
			force1 = stack1,
			force2 = stack2,
		})
		print_r(stack1)
		local data = "tj" .. lnconv.lton_s(#jdata, 4) .. jdata
		print(sock:send(data))
	end

	view:stopAction(prevAction)
	show()
	prevAction = schedule(view, show, 1)
end

return iupeditor