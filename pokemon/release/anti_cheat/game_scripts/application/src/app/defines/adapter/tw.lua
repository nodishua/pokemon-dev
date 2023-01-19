
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2021 TianJi Information Technology Inc.
--

-- 默认使用cn，这里只是因为shenhe有这个文件，需要覆盖他
local config = {}

-- 充值
config["recharge.json"] = {
	dockWithScreen = {
		{"privilegePanel.leftBtn", "left"},
		{"privilegePanel.rightBtn", "right"},
	},
	set = {
		{"rechargePanel.item", "visible", false},
		{"privilegePanel.panel", "visible", false},
		{"rechargePanel.item.extraInfo","fontSize","35"},
		{"rechargePanel.item.doublePanel.label","fontSize","30"},
	},

}


--日常副本详情界面
config["daily_activity_gate_select.json"] = {
	set = {
		{"item", "visible", false},
		{"left.doubleFlag.text","fontSize",27}
	},
}

--日常副本界面
config["daily_activity.json"] = {
	set = {
		{"item", "visible", false},
		{"item.doubleFlag.text","fontSize",27}
	},
}


config["cross_arena_info.json"] = {
	set = {
		{"sevenPanel.txt","fontSize","34"},
		{"sevenPanel.textTime","fontSize","34"},
		{"sevenPanel.textNode","fontSize","34"},
	},
}

-- 钓鱼界面
config['fishing.json'] = {
	set = {
		{'auto', "visible", false},
		{'activityTip', "visible", false},
		{'auto.btnOk', "visible", false},
		{'centerPanel', "visible", false},
		{'waitPanel', "visible", false},
		{'txtRank', "visible", false},
		{'txtRank.item', "visible", false},
		{'rightPanel.btnTake', "visible", false},
		{"rightPanel.imgTip", "visible", false},
		{"auto.tipOver", "visible", false},
		{"auto.tipOver1", "visible", false},
		{"recordPanel.txtRecord","fontSize",30}
	},
	dockWithScreen = {
		{"rightPanel", "right", "down", false},
		{"btnRules", "right", "up", false},
		{"leftPanel.btnLv", "left", "down", false},
		{"leftPanel.btnHandbook", "left", "down", false},
		{"leftPanel.btnShop", "left", "down", false},
		{"leftPanel.btnRank", "left", "down", false},
		{"activityTip", "right", nil, true},
		{"txtRank", "right", nil, true},
	}
}

config["online_fight_record_info.json"] = {
	set = {
		{"item", "visible", false},
		{"panel1.array.textNote1","fontSize",32},
		{"panel1.array.textNote2","fontSize",32},
		{"panel2.array.textNote1","fontSize",32},
		{"panel2.array.textNote2","fontSize",32},
	},
}

--活动Boss
config["activity_boss.json"] = {
	dockWithScreen = {
		{"leftPanel", "left"},
		{"btnRule", "left"},
		{"rightPanel", "right"},
	},
	set = {
		{"leftPanel.item", "visible", false},
		{"rightPanel.enemy.item", "visible", false},
		{"rightPanel.drop.item", "visible", false},
		{"leftPanel.ChallengeTip","fontSize",29}
	},
}


return config