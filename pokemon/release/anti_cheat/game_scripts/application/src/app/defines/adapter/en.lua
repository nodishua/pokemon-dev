
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
local config = {}


-- 显示通行证 主界面
config["grow_guide.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"item2", "visible", false},
		{"rightTop.rewardPanel.textTitle", "fontSize", 36},
	},
	scaleWithWidth = {
		{"title.textTitle", nil, 300},
	},
}

-- 元素挑战
config["clone_battle_city.json"] = {
	dockWithScreen = {
		{"btnRule", "right", nil, false},
		{"btnShowList", "right", nil, false},
	},
	set = {
		{"btnShowList.text", "fontSize", 40},
	},
}

-- 元素挑战 房间界面
config["clone_battle_room.json"] = {
	set = {
		{"rightPanel.centerPanel.btnJoinItem", "visible", false},
		{"rightPanel.centerPanel.normalItem", "visible", false},
		{"rightPanel.centerPanel.mainItem", "visible", false},
		{"rightPanel.bottomPanel.btnRobot.text", "fontSize", 36},
	},
	dockWithScreen = {
		{"leftPanel", "left"},
		{"rightPanel", "right"},
	},
}

config["clone_battle_friend_invite.json"] = {
	set = {
		{"item", "visible", false},
		{"empty.text", "fontSize", 46},
	}
}

config["gate_section_detail_normal.json"] = {
	set = {
		{"rightDown.selectSkip.textJumpNote", "fontSize", 38},
	},
	scaleWithWidth = {
		{"rightDown.btnChallenge.textNote", nil, 180},
    },
}

config["gate_section_detail_hard.json"] = {
	set = {
		{"rightDown.selectSkip.textJumpNote", "fontSize", 38},
	},
	scaleWithWidth = {
		{"rightDown.btnChallenge.textNote", nil, 180},
    },
}

config["gate_section_detail_nightmare.json"] = {
	scaleWithWidth = {
		{"rightDown.btnChallenge.textNote", nil, 180},
    },
}

-- 扫荡
config["gate_sweep.json"] = {
	set = {
		{"itemTitle", "visible", false},
		{"item1", "visible", false},
		{"innerList", "visible", false},
		{"item", "visible", false},
		{"successItem", "visible", false},
		{"bottomItem", "visible", false},
	},
	scaleWithWidth = {
		{"btnAgain.textNote", nil, 240},
    },
}

-- 竞技场
config["arena.json"] = {
	set = {
		{"item", "visible", false},
		{"ruleRankItem", "visible", false},
	},
	dockWithScreen = {
		{"leftDown", "left"},
		{"rightDown", "right"},
		{"top.leftUp", "left"},
		{"top.rightUp", "right"},
	},
	oneLinePos = {
		{"top.leftUp.textNoteFight", "top.leftUp.textFightPoint", cc.p(10,0)},
		{"top.leftUp.textNoteRank", "top.leftUp.textRank", cc.p(10,0)},
	},
}

-- 竞技场-战斗记录
config["arena_combat_record.json"] = {
	set = {
		{"item", "visible", false},
		{"item.textFightPoint", "positionX", {370}}
	},
	oneLinePos = {
		{"title.textTitle1", "title.textTitle2", cc.p(10,0)},
	},
}

config["card_embattle.json"] = {
	set = {
		{"spritePanel", "visible", false},
		{"useDefaultBattle", "visible", false},
		{"rightDown.btnSaveReady", "visible", false},
		{"btnReady", "visible", false},
	},
	dockWithScreen = {
		{"dailyGateTipsPos", "right"},
	},
	scaleWithWidth = {
		{"rightDown.btnOneKeySet.textNote", nil, 270},
	},
	oneLinePos = {
		{"rightDown.textNote", "rightDown.textNum", cc.p(50, 0), "left"},
		{"rightDown.textNum", "rightDown.textNote", cc.p(10, 0), "right"},
		{"useDefaultBattle.text", "useDefaultBattle.checkBox", cc.p(270, 0), "right"},
		{"useDefaultBattle.checkBox", "useDefaultBattle.text", cc.p(5, 0), "left"},
	},
}

config["card_attribute.json"] = {
	set = {
		{"innerList", "visible", false},
		{"trammelItem", "visible", false},
		{"medItem", "visible", false},
		{"attrItem", "visible", false},
		{"center.top.btnInfo", "positionX", {880}},
		{"trammelItem.textNote", "fontSize", 34},
	},
	oneLinePos = {
		{"center.center.imgIconLife", "center.center.textLiftNote", cc.p(5, 0)},
		{"center.center.imgIconAttack", "center.center.textAttackNote", cc.p(5, 0)},
		{"center.center.imgSpeAttack", "center.center.textSpeAttackNote", cc.p(5, 0)},
		{"center.center.imgIconSpeed", "center.center.textSpeedNote", cc.p(5, 0)},
		{"center.center.imgIconDef", "center.center.textDefNote", cc.p(5, 0)},
		{"center.center.imgIconSpeDef", "center.center.textSpeDefNote", cc.p(5, 0)},
		{"center.center.textLiftNote", "center.center.textLifeNum", cc.p(5, 0)},
		{"center.center.textAttackNote", "center.center.textAttackNum", cc.p(5, 0)},
		{"center.center.textSpeAttackNote", "center.center.textSpeAttackNum", cc.p(5, 0)},
		{"center.center.textSpeedNote", "center.center.textSpeedVal", cc.p(5, 0)},
		{"center.center.textDefNote", "center.center.textDefNum", cc.p(5, 0)},
		{"center.center.textSpeDefNote", "center.center.textSpeDefNum", cc.p(5, 0)},
		{"center.top.textSexNote", "center.top.textSexVal", cc.p(5, 0)},
		{"center.top.textNatureNote", "center.top.textNature", cc.p(5, 0)},
		{"center.top.textTypeNote", "center.top.textTypeNum", cc.p(5, 0)},
	},
}

config["card_skill.json"] = {
	set = {
		{"item", "visible", false},
		{"panel.textNote", "fontSize", 36},
		{"panel.textNum", "fontSize", 46},
		{"panel.textFlag", "fontSize", 36},
	},
	oneLinePos = {
		{"panel.btnAdd", "panel.fastUpgradePanel", cc.p(15, 0), "left"},
	}
}

-- 卡牌努力值
config["card_effortvalue.json"] = {
	set = {
		{"item", "visible", false},
		{"itemAttr", "visible", false},
		{"itemTxt", "visible", false},
		{"item.currentNum", "positionX", {280}},
		{"itemTxt.num", "positionX", {185}},
	},
	scaleWithWidth = {
		{"panel.leftPanel.btn.txt", nil, 110},
		{"panel.rightPanel.btn.txt", nil, 80},
	},
	oneLinePos = {
		{"selectPanel.attrTitle", "selectPanel.btnAttr", cc.p(10, 0), "right"},
	}
}

-- 卡牌核心特性
config["card_ability_strengthen.json"] = {
	oneLinePos = {
		{"panel.textNote", "panel.textNum", cc.p(65, -2), "left"},
		{"panel.textNum", "panel.iconMax", cc.p(60, 0), "left"},
		{"panel.textNum", "panel.iconArrow", cc.p(60, 0), "left"},
		{"panel.iconArrow", "panel.textNextNum", cc.p(20, 0), "left"},
	},
}

config["card_nature_attr.json"] = {
	set = {
		{"item", "visible", false},
		{"curFlag", "visible", false},
	},
	oneLinePos = {
		{"textNote3", "imgIcon", cc.p(15, 0), "left"},
	},
	scaleWithWidth = {
		{"topList.item.textNote", nil, 100},
		{"topList.item1.textNote", nil, 100},
		{"topList.item2.textNote", nil, 100},
		{"topList.item3.textNote", nil, 100},
		{"topList.item4.textNote", nil, 100},
		{"topList.item5.textNote", nil, 100},
		{"topList.item6.textNote", nil, 100},
		{"topList.item7.textNote", nil, 100},
		{"topList.item8.textNote", nil, 100},
		{"topList.item9.textNote", nil, 100},
		{"topList.item10.textNote", nil, 100},
		{"topList.item11.textNote", nil, 100},
		{"topList.item12.textNote", nil, 100},
		{"topList.item13.textNote", nil, 100},
		{"topList.item14.textNote", nil, 100},
		{"topList.item15.textNote", nil, 100},
		{"topList.item16.textNote", nil, 100},
		{"topList.item17.textNote", nil, 100},
		{"rightList.item.textNote", nil, 100},
		{"rightList.item1.textNote", nil, 100},
		{"rightList.item2.textNote", nil, 100},
		{"rightList.item3.textNote", nil, 100},
		{"rightList.item4.textNote", nil, 100},
		{"rightList.item5.textNote", nil, 100},
		{"rightList.item6.textNote", nil, 100},
		{"rightList.item7.textNote", nil, 100},
		{"rightList.item8.textNote", nil, 100},
		{"rightList.item9.textNote", nil, 100},
		{"rightList.item10.textNote", nil, 100},
		{"rightList.item11.textNote", nil, 100},
		{"rightList.item12.textNote", nil, 100},
		{"rightList.item13.textNote", nil, 100},
		{"rightList.item14.textNote", nil, 100},
		{"rightList.item15.textNote", nil, 100},
		{"rightList.item16.textNote", nil, 100},
		{"rightList.item17.textNote", nil, 100},
	},
}

config["rebirth_select_role.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
	},
	oneLinePos = {
		{"title.textNote1", "title.textNote2", cc.p(15, 0), "left"},
		{"down.textNote", "down.textNum", cc.p(10, 0), "left"},
		{"item.textNote", "item.textFightPoint", cc.p(5, 0)},
	},
}

config["rebirth_select_card.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
	},
	oneLinePos = {
		{"title.textNote1", "title.textNote2", cc.p(15, 0), "left"},
	}
}

-- 交换
config["card_property_swap_view.json"] = {
	set = {
		{"leftItem", "visible", false},
		{"centerCharacter", "visible", false},
		{"centerNvalue", "visible", false},
		{"centerEffortValue", "visible", false},
		{"centerFeelValue", "visible", false},
		{"centerEffortValue.itemAttr", "visible", false},
		{"txt", "scale", 0.9},
		{"centerEffortValue.rightPanel", "positionX", {1310}},
		{"centerCharacter.leftPanel.name", "anchorPoint", {0, 0.5}},
		{"centerCharacter.rightPanel.name", "anchorPoint", {0, 0.5}},
	},
	oneLinePos = {
		{"title", "title1", cc.p(5, 0), "left"},
		{"centerCharacter.leftPanel.character", "centerCharacter.leftPanel.name", cc.p(5, 0), "left"},
		{"centerCharacter.rightPanel.character", "centerCharacter.rightPanel.name", cc.p(5, 0), "left"},
		{"centerEffortValue.leftPanel.txt1", "centerEffortValue.leftPanel.num1", cc.p(15, 0), "left"},
		{"centerEffortValue.itemAttr.name", "centerEffortValue.itemAttr.barBg", cc.p(60, 0), "left"},
		{"centerEffortValue.itemAttr.name", "centerEffortValue.itemAttr.bar", cc.p(60, 0), "left"},
		{"centerEffortValue.itemAttr.barBg", "centerEffortValue.itemAttr.num", cc.p(15, 0), "left"},
		{"centerCharacter.leftPanel.special.name1", "centerCharacter.leftPanel.special.num1", cc.p(40, 0), "left"},
		{"centerCharacter.leftPanel.special.num1", "centerCharacter.leftPanel.special.green", cc.p(40, 0), "left"},
		{"centerCharacter.leftPanel.special.name2", "centerCharacter.leftPanel.special.num2", cc.p(40, 0), "left"},
		{"centerCharacter.leftPanel.special.num2", "centerCharacter.leftPanel.special.red", cc.p(40, 0), "left"},
		{"centerCharacter.rightPanel.special.name1", "centerCharacter.rightPanel.special.num1", cc.p(40, 0), "left"},
		{"centerCharacter.rightPanel.special.num1", "centerCharacter.rightPanel.special.green", cc.p(40, 0), "left"},
		{"centerCharacter.rightPanel.special.name2", "centerCharacter.rightPanel.special.num2", cc.p(40, 0), "left"},
		{"centerCharacter.rightPanel.special.num2", "centerCharacter.rightPanel.special.red", cc.p(40, 0), "left"},
	},
	scaleWithWidth = {
		{"centerNvalue.leftPanel.txt", nil, 290},
		{"centerNvalue.rightPanel.txt", nil, 290},
		{"centerCharacter.leftPanel.name", nil, 125},
		{"centerCharacter.rightPanel.name", nil, 125},
	},
}

-- 训练家
config["trainer_view.json"] = {
	set = {
		{"item", "visible", false},
		{"item2", "visible", false},
		{"item2.desc", "fontSize", 36},
		{"item2.desc1", "fontSize", 36},
		{"item2.flag", "fontSize", 46},
	},
	dockWithScreen = {
		{"btnLeft", "left"},
		{"btnRight", "right"},
	},
	scaleWithWidth = {
		{"item2.desc1", nil, 30},
	},
	oneLinePos = {
		{"sliderBg", "txt", cc.p(20, -10), "right"},
		{"item2.lv", "item2.btnUp", cc.p(130, -15), "left"},
		{"item2.lv", "item2.flag", cc.p(170, -10), "left"},
		{"item2.desc", "item2.desc1", cc.p(10, 0), "left"},
	},
}

-- 成就主界面
config["achievement_main.json"] = {
	set = {
		{"item", "visible", false},
		{"btn", "visible", false},
		{"infoItem", "visible", false},
		{"rightAll.btnRank.textNote", "fontSize", 42},
	},
}

-- 设置主界面
config["setting.json"] = {
	set = {
		{"voiceBtn.text", "anchorPointX", 0.35},
	}
}

-- 设置界面常规界面
config["setting_normal.json"] = {
	set = {
		{"centerPanel.item", "visible", false},
	},
	scaleWithWidth = {
		{"centerPanel.bottomPanel.btnFeedback.text", nil, 240},
	}
}

-- 主城
config["city.json"] = {
	dockWithScreen = {
		{"leftTopPanel", "left", "up", false},
		{"leftPanel", "left", nil, true},
		{"leftBottomPanel", "left", "down", false},
		{"rightPanel", "right", "up", false},
		{"growGuide", "right", nil, true},
		{"activityTip", "right", nil, true},
		{"rightBottomPanel", "right", "down", true},
		{"centerBottomPanel", nil, "bottom", false},
		{"developPanel", nil, "bottom", false},
	},
	set = {
		{"item", "visible", false},
		{"rightPanel.onlineGiftPanel", "visible", false},
		{"growGuide.textNote2", "fontSize", 28},
		{"rightPanel.showList", "contentSize", {1100, 300}},
	},
	oneLinePos = {
		{"leftTopPanel.power", "leftTopPanel.powerNum", cc.p(25, 0), "left"},
		{"leftTopPanel.powerNum", "leftTopPanel.power", cc.p(0, 0), "right"},
	},
}

--公会修炼中心界面
config["union_skill.json"] = {
	set = {
		{"item", "visible", false},
		{"item.name", "fontSize", 30}
	},
	oneLinePos = {
		{"title1", "title2", cc.p(10, 0)},
	},
}

-- 公会红包主界面
config["union_redpack.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"btnItem", "visible", false},
		{"innweList", "visible", false},
	},
	dockWithScreen = {
		{"leftList", "left"},
		{"btnRule", "right", nil, true},
		{"textTimesNote", "right", nil, true},
		{"textTimesNum", "right", nil, true},
		{"textTimesMax", "right", nil, true},
	},
	scaleWithWidth = {
		{"item1.title.textTitle1", nil, 280},
		{"item1.title.textTitle2", nil, 280},
	}
}

-- 公会发红包界面
config["union_send_redpack.json"] = {
	set = {
		{"btnSend.textNote", "fontSize", 42},
	},
}

-- 公会大厅
config["union_lobby.json"] = {
	dockWithScreen = {
		{"leftPanel.list", "left"},
	},
	oneLinePos = {
		{"applyPanel.stateNote", "applyPanel.state", cc.p(10, 0)},
		{"informationPanel.unionNameNote","informationPanel.unionName"},
		{"informationPanel.chairmanNameNote","informationPanel.chairmanName"},
		{"informationPanel.unionExpNote","informationPanel.unionExp"},
		{"informationPanel.unionIdNote","informationPanel.unionId"},
		{"informationPanel.unionNumNote","informationPanel.unionNum"},
	},
	scaleWithWidth = {
		{"informationPanel.disbandBtn.title", nil, 220},
		{"informationPanel.changeBtn.title", nil, 220},
		{"informationPanel.emailBtn.title", nil, 220},
		{"informationPanel.quitBtn.title", nil, 220},
		{"applyPanel.recruitBtn.title", nil, 220},
		{"applyPanel.refuseBtn.title", nil, 220},
	}
}

-- 公会捐献界面
config["union_contribute_main.json"] = {
	set = {
		{"item", "visible", false},
		{"left.textUnionExp", "fontSize", 36},
	},
	oneLinePos = {
		{"title.textNote1", "title.textNote2", cc.p(15, 0), "left"},
		{"left.textCountNote", "left.textCount", cc.p(0, 0), "left"},
	},
	scaleWithWidth = {
		{"top.textWeekAll", nil, 160},
	}
}

-- 天赋
config["talent.json"] = {
	set = {
		{"rightPanel.subList1", "visible", false},
		{"rightPanel.subList2", "visible", false},
		{"leftPanel.item", "visible", false},
		{"leftPanel.item.normal.subTxt", "visible", false},
		{"leftPanel.item.normal.txt", "positionY", 76},
	},
	oneLinePos = {
		{"rightPanel.txt", "rightPanel.num", cc.p(20, 0), "left"},
	},
	scaleWithWidth = {
		{"rightPanel.btnReset.title", nil, 250},
	}
}


-- 初始选择精灵界面
config["character_select_card.json"] = {
	oneLinePos = {
		{"leftPanel.attrPanel.textSumText", "leftPanel.attrPanel.textSum", cc.p(10, 0)},
		{"leftPanel.attrPanel.hp.textNote", "leftPanel.attrPanel.hp.textNum", cc.p(10, 0)},
		{"leftPanel.attrPanel.speed.textNote", "leftPanel.attrPanel.speed.textNum", cc.p(10, 0)},
		{"leftPanel.attrPanel.attack.textNote", "leftPanel.attrPanel.attack.textNum", cc.p(10, 0)},
		{"leftPanel.attrPanel.phyFang.textNote", "leftPanel.attrPanel.phyFang.textNum", cc.p(10, 0)},
		{"leftPanel.attrPanel.special.textNote", "leftPanel.attrPanel.special.textNum", cc.p(10, 0)},
		{"leftPanel.attrPanel.speFang.textNote", "leftPanel.attrPanel.speFang.textNum", cc.p(10, 0)},
		{"rightPanel.leftUpPanel.name1", "rightPanel.leftUpPanel.txt", cc.p(10, 0)},
		{"topPanel.title", "topPanel.subTitle", cc.p(10, 0)},
	},
	scaleWithWidth = {
		{"itemSkill.txt", nil, 30},
	},
}

-- 个人信息
config["personal_info.json"] = {
	set = {
		{"rightPanel.btnShare", "visible", false},
	},
	oneLinePos = {
		{"rightPanel.icon1", "rightPanel.name8", cc.p(10, 0), "left"},
		{"rightPanel.name8", "rightPanel.collect", nil, "left"},
		{"rightPanel.collect", "rightPanel.icon2", cc.p(150, 0), "left"},
		{"rightPanel.icon2", "rightPanel.name9", cc.p(10, 0), "left"},
		{"rightPanel.name9", "rightPanel.unlock", nil, "left"},
		{"rightPanel.name7", "rightPanel.barBg", cc.p(10, 0)},
		{"rightPanel.name7", "rightPanel.bar", cc.p(10, 0)},
		{"rightPanel.barBg", "rightPanel.btnExp", cc.p(20, 0)},
		{"rightPanel.name1", "rightPanel.name", cc.p(10, 0)},
		{"rightPanel.name4", "rightPanel.uid", cc.p(-10, 0)},
		{"rightPanel.name5", "rightPanel.level", cc.p(10, 0)},
		{"rightPanel.name6", "rightPanel.power", cc.p(30, 0)},
	},
	dockWithScreen = {
		{"leftPanel", "left"},
		{"rightPanel", "right"},
	},
}

-- 个人信息
config["personal_other.json"] = {
	set = {
		{"rightPanel.upPanel.levelPanel.txtContent", "positionX", {165}},
		{"rightPanel.upPanel.powerPanel.txtContent", "positionX", {165}},
		{"rightPanel.upPanel.titlePanel.txt", "anchorPoint", {1, 0.5}},
		{"rightPanel.upPanel.titlePanel.txt", "positionX", {130}},
	},
	oneLinePos = {
		{"title", "title1", cc.p(10, 0), "left"},
		{"rightPanel.centerPanel.collectPanel.icon", {"rightPanel.centerPanel.collectPanel.txt", "rightPanel.centerPanel.collectPanel.txtContent"}, cc.p(10, 0), "left"},
	},
}

-- 个人形象
config["personal_figure.json"] = {
	set = {
		{"itemLogo", "visible", false},
		{"itemSkill", "visible", false},
		{"addPanel.itemAttr", "visible", false},
		{"btnAdd.txt", "fontSize", 46},
		{"addPanel.title1", "fontSize", 44},
		{"addPanel.itemAttr.txt", "fontSize", 38},
	},
	oneLinePos = {
		{"title", "title1", cc.p(5, 0), "left"},
		{"addPanel.title", "addPanel.title1", cc.p(10, 0), "left"},
	},
}

-- 无尽之路排行榜
config["endless_tower_rank.json"] = {
	set = {
		{"item", "visible", false},
		{"achievementItem", "visible", false},
	},
	oneLinePos = {
		{"title1", "title2", cc.p(5, 0), "left"},
	},
	scaleWithWidth = {
		{"textPoint", nil, 300},
		{"textLv", nil, 300},
	},
}

-- 个人技能选择
config["personal_skill_choose.json"] = {
	set = {
		{'itemSkill', "visible", false},
		{'subList', "visible", false},
		{'conditionList', "contentSize", {580, 92}},
		{"conditionList", "positionY", {375}},
		{"btnSave", "positionY", {300}},
		{"btnRemove", "positionY", {300}},
	},
	oneLinePos = {
		{"title", "title1", cc.p(5, 0), "left"},
	},
}

-- 称号簿
config["title_book.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
		{"leftPanel.title", "visible", false},
		{"itemAttr", "visible", false},
		{"itemCondition", "visible", false}
	},
	oneLinePos = {
		{"rightPanel.name1", "rightPanel.title", cc.p(15, 0), "left"},
	},
	scaleWithWidth = {
		{"leftPanel.tip", nil, 200},
	}
}

-- 好友
config["friend.json"] = {
	set = {
		{"rightPanel", "visible", false},
		{"item1", "visible", false},
		{"item2", "visible", false},
		{"leftItem", "visible", false},
		{"leftPanel.panel.friendPanel.getNum", "positionX", 800},
	},
	oneLinePos = {
		{"item2.txt", "item2.power", cc.p(5, 0)},
		{"item1.txt", "item1.power", cc.p(5, 0)},
	},
	scaleWithWidth = {
		{"leftPanel.panel.topPanel.btnSort.txt", nil, 110},
	}
}

-- 精灵信息
config["card_info.json"] = {
	set = {
		{"itemNature", "visible", false},
		{"item", "visible", false},
		{"skillItem", "visible", false},
		{"rightPanel.skillPanel", "visible", false},
		{"rightPanel.attributePanel", "visible", false},
		{"starItem", "visible", false}
	},
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(5, 0)},
		{"itemNature.name", "itemNature.num", cc.p(100, 0)},
	},
}

-- 卡牌详情
config["common_card_detail.json"] = {
	set = {
		{"baseCardNode.attrItem", "visible", false},
		{"baseCardNode.attrItem.bar", "contentSize", {425, 20}},
		{"baseCardNode.attrItem.barBg", "contentSize", {425, 20}},
		{"baseCardNode.attrItem.bar", "positionX", {420}},
		{"baseCardNode.attrItem.barBg", "positionX", {420}},
	},
	oneLinePos = {
		{"baseCardNode.raceNote", "baseCardNode.raceNum", cc.p(15, 0), "left"},
	},
}


-- 卡牌升星界面
config["card_star.json"] = {
	set = {
		{"item", "visible", false},
		{"selectPanel.btnCombine.textNote","fontSize",30},
		{"selectPanel.btnFrags.textNote","fontSize",30},
	},
	oneLinePos = {
		{"selectPanel.textNote", "selectPanel.textNum", cc.p(0, 0), "left"},
		{"panel.textItemNote", "panel.btnChange", cc.p(0, 0), "left"},
	},
}

-- 卡牌升星
config["card_star_changefrags.json"] = {
	set = {
		{"barPanel.bar", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"item", "visible", false},
	},
	oneLinePos = {
		{"note", "textNeedNum", cc.p(0, 0), "left"},
	},
	scaleWithWidth = {
		{"item.title", nil, 70},
	}
}

-- 公会训练中心界面
config["union_train.json"] = {
	set = {
		{"leftItem", "visible", false},
		{"myItem", "visible", false},
		{"otherItem", "visible", false},
		{"roleItem", "visible", false},
		{"otherPanel.empty", "visible", false},
	},
	scaleWithWidth = {
		{"otherItem.exp", nil, 360},
		{"myItem.panelChange.exp", nil, 370},
	},
	oneLinePos = {
		{"title1", "title2"},
	},
}

-- 图鉴
config["handbook.json"] = {
	dockWithScreen = {
		{"left", "left"},
		{"pageList", "right"},
	},
	set = {
		{"attrItem", "visible", false},
		{"btnItem", "visible", false},
		{"item", "visible", false},
		{"item1", "visible", false},
		{"attrTmp", "visible", false},
		{"center.btnSpecial", "visible", false},
		{"center.btnDetail", "positionY", 370},
	},
	oneLinePos = {
		{"left.textAllAttr", "left.btnShowAttrAdd", cc.p(15, 0), "left"},
		{"center.attrPanel.textSumText", "center.attrPanel.textSum", cc.p(15, 0), "left"},
		{"center.attrPanel.speed.textNote", "center.attrPanel.speed.textNum", cc.p(15, 0), "left"},
		{"center.attrPanel.attack.textNote", "center.attrPanel.attack.textNum", cc.p(25, 0), "left"},
		{"center.attrPanel.phyFang.textNote", "center.attrPanel.phyFang.textNum", cc.p(45, 0), "left"},
		{"center.attrPanel.special.textNote", "center.attrPanel.special.textNum", cc.p(15, 0), "left"},
		{"center.attrPanel.speFang.textNote", "center.attrPanel.speFang.textNum", cc.p(15, 0), "left"},
		{"center.textHandBookAdd", "attrItem.imgIcon", cc.p(-260, 0), "left"},
		{"center.textStarAdd", "center.starAttr", cc.p(15, 0), "left"},
		{"center.starAttr", "center.starList", cc.p(115, 0), "left"},
		{"center.textSpriteNote", {"center.textHeightNote", "center.textHeightNum"}, cc.p(10, 0), "left"},
		{"center.textHeightNum", "center.textWeightNote", cc.p(5, 0), "left"},
		{"center.textWeightNote", "center.textWeightNum", cc.p(5, 0), "left"},
	},
}

-- 图鉴培养加成
config["handbook_detail.json"] = {
	oneLinePos = {
		{"textTitle1", "textTitle2", cc.p(5, 0)},
		{"rightPanel.textNote1", "rightPanel.btnDetail", cc.p(15, 0)},
		{"rightPanel.addPanel.textAddNote", "rightPanel.addPanel.imgAttr", cc.p(15, 0)},
		{"rightPanel.nextAddPanel.textAddNote", "rightPanel.nextAddPanel.imgAttr", cc.p(15, 0)},
	},
}

config["handbook_attadd.json"] = {
	set = {
		{"panel.innerList", "visible", false},
		{"panel.item", "visible", false},
		{"panel.item.textName", "fontSize", 30},
		{"panel.item.textNum", "fontSize", 30},
	},
}

config["handbook_fetter.json"] = {
	set = {
		{"item", "visible", false},
		{"roleItem", "visible", false},
		{"item.textTip", "positionX", 380},
	},
}

-- 好感度
config["card_feel.json"] = {
	set = {
		{"item", "visible", false},
		{"attrItem", "visible", false},
		{"pageItem", "visible", false},
		{"rightPanel.attrNote", "positionX", {0}},
		{"rightPanel.textTip", "fontSize", 30},
		{"leftPanel.btnSelectItem", "positionY", {280}},
		{"attrItem.icon", "positionY", {30}},
		{"attrItem.txtName", "positionY", {30}},
		{"attrItem.txtNum", "positionY", {30}},
		{"attrItem", "contentSize", {400, 60}},
		{"rightPanel.attrSubList", "contentSize", {800, 60}},
		{"rightPanel.attrList", "contentSize", {800, 210}},
		{"rightPanel.textTip", "anchorPoint", {0, 0.5}},
		{"rightPanel.textTip", "position", {0, 960}},
	},
	oneLinePos = {
		{"textTitle1", "textTitle2", cc.p(15, 0), "left"},
		-- {"rightPanel.attrNote", "rightPanel.textTip", cc.p(5,0), "left"},
		-- {"rightPanel.textTip", "rightPanel.attrNote", cc.p(-325, 20), "right"},
		{"leftPanel.lvBg", "leftPanel.feelNote", cc.p(5, 0), "left"},
	},
	scaleWithWidth = {
		{"leftPanel.btnLvUp.textTitle", nil, 200},
		{"leftPanel.btnLvUpEasy.textTitle", nil, 200},
	},
}

-- 天赋重置
config["talent_reset.json"] = {
	oneLinePos = {
		{"icon", "txt1", cc.p(-110, 0), "right"},
		{"txt1", "icon", cc.p(10, 0), "left"},
		{"icon", "num", cc.p(10, 0), "left"},
	},
}
-- 聚宝(点金)
config["common_gain_gold.json"] = {
	set = {
		{"numPanel.bg", "contentSize", {400, 168}},
		{"numPanel.doublePanel.text1","fontSize",35},
		{"numPanel.doublePanel.text2","fontSize",35},
		{"numPanel.doublePanel.text3","fontSize",35},
	},
	oneLinePos = {
		{"numPanel.info", "numPanel.num1", cc.p(10, 0), "left"},
		{"numPanel.num1", "numPanel.info", cc.p(5, 0), "right"},
	},
}

-- 商店
config["shop.json"] = {
	dockWithScreen = {
		{"leftPanel", "left"},
	},
	set = {
		{"leftPanel.item", "visible", false},
		{"leftPanel.itemParent", "visible", false},
		{"leftPanel.itemChild", "visible", false},
		{"item", "visible", false},
		{"rightPanel.subList", "visible", false},
		{"item.item1.discount.imgBg", "scale", 1.2},
		{"item.item1.discount.textNote", "fontSize", 34},
	},
}

-- 神秘商店
config["mystery_shop.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
		{"item.textName", "fontSize", 36},
		{"item.flag.imgBg", "scale", 1.2},
		{"item.flag.textVal", "fontSize", 34},
	},
}

-- 显示通行证 主界面
config["activity_passport.json"] = {
	set = {
		{"tabItem", "visible", false},
		{"rewardItem", "visible", false},
		{"iconItem", "visible", false},
		{"taskItem", "visible", false},
		{"taskPanel", "visible", false},
		{"pointItem", "visible", false},
		{"taskPanel.btnAllGet", "positionY", {15}},
		{"rewardPanel.target.lv", "positionY", {750}},
		{"taskItem.txtExp", "positionX", 870},
		{"taskItem.txtTitle", "fontSize", 46},
		{"taskItem.txtCorner1", "fontSize", 32},
		{"taskPanel.iconTitle3", "scale", 1.6},
		{"taskItem.txtExp", "positionY", {80}},
	},
	oneLinePos = {
		{"rewardPanel.txtNode","rewardPanel.endTime"},
		{"taskPanel.iconTitlePanel","taskPanel.iconTitle3",cc.p(5,30)},
	}
}

-- 抽卡主界面
config["drawcard.json"] = {
	set = {
		{"btnItem", "visible", false},
		{"item", "visible", false},
		{"cardItem", "visible", false},
		{"equipTip.imgBg", "width", 620},
		{"limitPanel.single.info.img1", "positionX", 200},
	},
	dockWithScreen = {
		{"list", "left"},
		{"perview", "right"},
		{"shop", "right"},
	},
	oneLinePos = {
		{"equipTip.textNote", "equipTip.imgIcon", cc.p(45, 0), "left"},
		{"equipTip.imgIcon", "equipTip.textNote", cc.p(5, 0), "right"},
		{"cutDownPanel.imgIcon", {"cutDownPanel.textNote", "cutDownPanel.textTime"}, cc.p(5, 0), "left"},
		{"limitPanel.single.info.img1", "limitPanel.single.info.img2", cc.p(10, 0)}
	},
	oneLineCenterPos = {
		{cc.p(215, 42), {"diamondUpCutDownPanel.textNote", "diamondUpCutDownPanel.textTime"}, cc.p(5, 0)}
	},
}

config["card_common_success.json"] = {
	oneLinePos = {
		{"item.note", "item.txt1", cc.p(120, 0), "left"},
		{"item.txt1", {"item.iconArrow", "item.txt2"}, cc.p(15, 0), "left"},
	},
}

-- 竞技场碾压
config["arena_pass_reward.json"] = {
	set = {
		{"item.textReward", "anchorPoint", {0.5, 0.5}},
		{"item.textReward", "positionX", 260/2},
	},
	oneLinePos = {
		{"item.textScore", "item.score", cc.p(5, 0)},
	},
}

-- 卡牌饰品强化
config["card_equip_strengthen.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"panel.strengthenPanel.txt4", "panel.strengthenPanel.txt3", cc.p(220, 0), "right"},
		{"panel.strengthenPanel.txt3", "panel.strengthenPanel.txt4", cc.p(8, 0), "left"},
		{"panel.strengthenPanel.txt3", "panel.strengthenPanel.txt1", cc.p(-155, 0), "right"},
		{"panel.strengthenPanel.txt1", "panel.strengthenPanel.txt2", cc.p(8, 0), "left"},
		{"panel.strengthenPanel.txt3", "panel.strengthenPanel.txt5", cc.p(-150, 0), "right"},
		{"panel.strengthenPanel.txt5", "panel.strengthenPanel.txt6", cc.p(8, 0), "left"},
	},
	scaleWithWidth  = {
		{"panel.strengthenPanel.btnFast.textNote" ,nil, 200},
		{"panel.strengthenPanel.btnOne.textNote" ,nil, 200},
		{"panel.strengthenPanel.btnStrengthen.textNote" ,nil, 200},
	},
}

-- 限时直购礼包
config["activity_limit_buy_gift.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
		{"rightPanel.lv", "positionX", 680},
		{"rightPanel.countPanel.countTimeBg", "contentSize", {550, 66}},
		{"rightPanel.countPanel.countTimeNode", "fontSize", 42},
		{"rightPanel.countPanel.countTime", "fontSize", 52},
	},
	oneLinePos = {
		{"rightPanel.countPanel.countTimeNode", "rightPanel.countPanel.countTime", cc.p(5, 0), "left"},
	},
	scaleWithWidth  = {
		{"leftPanel.item.btn.name" ,nil, 210},
	},
}

-- 携带道具升级
config["held_item_common_success.json"] = {
	oneLinePos = {
		{"item.note", "item.txt1", cc.p(100, 0)},
	},
	set = {
		{"item.txt1","fontSize",40},
		{"item.txt2","fontSize",40},
		{"item.note","fontSize",38}
	}

}

-- 充值返利
config["activity_once_recharge_award.json"] = {
	oneLinePos = {
		{"btnRules", "time", cc.p(100, 0),"right"},
	},

}

-- 世界boss界面
config["activity_world_boss.json"] = {
	set = {
		{'centerPanel.skillItem', "visible", false},
		{"centerPanel.title", "contentSize", {520,44}},
		{"centerPanel.title", "positionX", 570},
		{"centerPanel.title.txt2", "anchorPoint", {0,0.5}},
		{"centerPanel.nameBg.name", "fontSize", 47},
		{"rightPanel.timesPanel.timesLabel", "positionX", 130},
	},
	oneLinePos = {
		{"centerPanel.title.txt", "centerPanel.title.txt1", cc.p(2, 0)},
		{"centerPanel.title.txt1", "centerPanel.title.txt2", cc.p(2, 0)},
	},
}

config["battle_end_world_boss_win.json"] = {
	set = {
		{"title", "positionY", {1200}},
	}
}

-- 活跃夺宝
config["activity_liveness_wheel.json"] = {
	set = {
		{"taskItem", "visible", false},
		{"selected", "visible", false},
		-- {"tips", "positionX", {800}},
		{"taskPanel.taskTips", "fontSize", 34},
		{"timeTitle", "fontSize", 38},
		{"time", "fontSize", 38},
	},
	oneLinePos = {
		{"timeTitle", "time"},
		{"btnSkip", "tips", cc.p(10, 0)},
	},
}

-- 充值
config["recharge.json"] = {
	dockWithScreen = {
		{"privilegePanel.leftBtn", "left"},
		{"privilegePanel.rightBtn", "right"},
	},
	set = {
		{"rechargePanel.item", "visible", false},
		{"privilegePanel.panel", "visible", false},
		{"rechargePanel.item.doublePanel.label", "contentSize", {90, 93}},
		{"rechargePanel.item.doublePanel.label", "fontSize", 28},
	},
	oneLineCenter = {
		{"privilegePanel.panel.oldIcon", "privilegePanel.panel.textNode", "privilegePanel.panel.oldPrice", cc.p(5, 0)},
		{"privilegePanel.panel.icon", "privilegePanel.panel.textNode2", "privilegePanel.panel.price", cc.p(5, 0)},
	},
	oneLinePos = {
		{"topPanel.maxPanel.label", "topPanel.maxPanel.vipIcon", cc.p(0, 0)},
	},
}

-- 等级基金
config["activity_level_fund.json"] = {
	-- set = {
	-- 	-- {"buyBtn", "positionX", 2300},
	-- 	-- {"diamondNum", "positionX", 2300},
	-- },
	oneLinePos = {
		{"bg", "buyBtn", cc.p(-280, -20)},
		{"buyBtn", "diamondNum", cc.p(-200, 0)},
		{"diamondNum", "diamondIcon", cc.p(5, 4)},
	},
}

-- 新手活动
config["activity_new_player_welfare.json"] = {
	set = {
		{"item", "visible", false},
		{"iconItem", "visible", false},
		{"ImageActivity.imgSptireName", "position", {625, 120}},
		{"ImageActivity.imgTotalDay", "positionX", 520},
	},
	scaleWithWidth  = {
		{"item.textGotten" ,nil, 200},
	},
}
-- 充值大转盘
config["activity_recharge_wheel.json"] = {
	scaleWithWidth  = {
		{"recordPanel.btnJumpToRecharge.txtNode" ,nil, 220},
	},
}

-- 道具折扣
config["activity_item_buy.json"] = {
	set = {
		{"item.logoDesc", "fontSize", 28},
		{"item.mask.label", "fontSize", 33},
		{"item.logo", "scale", 1.1},
		{"item.mask.img", "contentSize", {360, 80}},
	},
}

--月卡
config["activity_month_card.json"] = {
	set = {
		{"panel1.list", "anchorPoint", {0.5, 0}},
		{"panel2.list", "anchorPoint", {0.5, 0}},
		{"panel1.list", "positionX", 392},
		{"panel2.list", "positionX", 392},
		{"panel1.list", "scale", 0.75},
		{"panel2.list", "scale", 0.75},
	},
	oneLinePos = {
		{"panel1.item4.label", "panel1.item4.num", nil,"left"},
		{"panel1.item2.label1", "panel1.item2.label2", nil,"left"},
		{"panel1.label", "panel1.num", nil,"left"},
		{"panel1.textHas", "panel1.num", nil,"textHasNum"},
		{"panel2.item4.label", "panel2.item4.num", nil,"left"},
		{"panel2.item2.label1", "panel2.item2.label2", nil,"left"},
		{"panel2.label", "panel2.num", nil,"left"},
		{"panel2.textHas", "panel2.num", nil,"textHasNum"},
	},
}

-- 月卡特权
config["activity_month_card_privilege.json"] = {
	set = {
		{"item", "visible", false},
		{"list","anchorPoint", {0.1, 0}},
	},
}

--派遣主界面
config["dispatch_task.json"] = {
	set = {
		{"item", "visible", false},
		{"attrItem", "visible", false},
	},
	oneLinePos = {
		{"bottomPanel.taskTimeNote","bottomPanel.taskTime", cc.p(10,0), "left"},
	},
}

--派遣精灵界面
config["dispatch_task_sprite_select.json"] = {
	scaleWithWidth = {
		{"rightPanel.title", nil, 300},
	},
	set = {
		{"rightPanel.title", "positionX", 525},
		{"rightPanel.condition1", "fontSize", 36},
		{"rightPanel.condition2", "fontSize", 36},
		{"rightPanel.extraCondition1", "fontSize", 36},
		{"rightPanel.extraCondition2", "fontSize", 36},
	},
}

-- 限时PVP
config["craft_main.json"] = {
	set = {
		{"item", "visible", false},
		{"special.imgIconBg","contentSize", {260, 58}},
		{"special.textNote","fontSize",30}
	},
	oneLinePos = {
		{"top1.down.textFightPointNote","top1.down.textFightPoint", cc.p(10,0), "left"},
		{"top2.down.textFightPointNote","top2.down.textFightPoint", cc.p(10,0), "left"},
		{"top3.down.textFightPointNote","top3.down.textFightPoint", cc.p(10,0), "left"},
	},
}

-- 幸运推币
config["activity_gold_lucky_cat.json"] = {
	set = {
		{"item", "visible", false},
		{"numItem", "visible", false},
		{"txt4", "visible", false},
		{"txtVipTips", "visible", false},
		{"iconVipTips", "visible", false},
		{'dialogPanel.vip5', "visible", false},
		{"txt4", "contentSize", {340, 114}},
	}
}

-- 招财猫
config["activity_lucky_cat.json"] = {
	set = {
		{"item", "visible", false},
		{"numItem", "visible", false},
		{"txt4", "visible", false},
		{"txtVipTips", "visible", false},
		{"iconVipTips", "visible", false},
		{'dialogPanel.vip5', "visible", false},
		{'dialogPanel.descNormal', "fontSize", 36},
		{'dialogPanel.descVip10', "fontSize", 36},
		{"txt", "fontSize", 38},
	}
}

-- 随机塔-积分奖励
config["random_tower_point_reward.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
	},
	oneLinePos = {
		{"down.textTodayNote", "down.textScore", cc.p(5, 0), "left"},
		{"down.textTodayNote", "down.textNote", cc.p(300, 0), "left"},
		{"down.textAwardNote", "down.list", cc.p(5, 0), "left"},
	}
}

-- 限时PVP我的赛程
config["craft_schedule.json"] = {
	set = {
		{"item", "visible", false},
		{"roleItem", "visible", false},
		{"item.btnReplay", "contentSize", {200, 80}},
		{"item.btnReplay.textNote", "positionX", 100},
		{"topLeftPanel.textNote2", "positionX", 750},
	},
	dockWithScreen = {
		{"btnMainSchedule", "left"},
		{"btnMyTeam", "left"},
		{"btns", "right"},
		{"topLeftPanel", "left"},
		{"leftDown","left"}
	},
	oneLinePos = {
		{"item.textNoteLeft", "item.textFightPointL", cc.p(10,0)},
		{"item.textNoteRight", "item.textFightPointR", cc.p(10,0)},
	}
}

-- 卡牌性格
config["card_character.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
		{"panel1.txt2", "scale", 0.65},
		{"panel1.txt3", "scale", 0.65},
		{"panel1.txt4", "scale", 0.65},
		{"panel1.txt5", "scale", 0.65},
		{"panel1.txt6", "scale", 0.65},

		{"panel2.txt2", "scale", 0.65},
		{"panel2.txt3", "scale", 0.65},
		{"panel2.txt4", "scale", 0.65},
		{"panel2.txt5", "scale", 0.65},
		{"panel2.txt6", "scale", 0.65},

		{"panel3.txt2", "scale", 0.65},
		{"panel3.txt3", "scale", 0.65},
		{"panel3.txt4", "scale", 0.65},
		{"panel3.txt5", "scale", 0.65},
		{"panel3.txt6", "scale", 0.65},

		{"panel1.txt4", "positionX", 388},
		{"panel2.txt4", "positionX", 388},
		{"panel3.txt4", "positionX", 388},
		{"item.name", "positionX", 85},
		{"item.img", "positionX", 645},
	},
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(15, 0), "left"},
		{"commentPanel.txt4", "commentPanel.txt3", cc.p(160, 0), "right"},
		{"commentPanel.txt3", "commentPanel.txt2", cc.p(10, 0), "right"},
		{"commentPanel.txt2", "commentPanel.txt1", cc.p(35, 0), "right"},
		{"commentPanel.txt3", "commentPanel.txt4", cc.p(35, 0), "left"},
		{"commentPanel.txt4", "commentPanel.txt5", cc.p(10, 0), "left"},
		{"commentPanel.txt5", "commentPanel.txt6", cc.p(35, 0), "left"},
		{"commentPanel.txt6", "commentPanel.txt7", cc.p(10, 0), "left"},
		{"commentPanel.img2", "commentPanel.txt8", cc.p(-10, 0), "right"},
		{"commentPanel.txt8", "commentPanel.img2", cc.p(35, 0), "left"},
		{"commentPanel.img2", "commentPanel.txt9", cc.p(10, 0), "left"},
		{"commentPanel.txt8", "commentPanel.img1", cc.p(10, 0), "right"},
	},
	scaleWithWidth = {
		{"item.name", nil, 80},
	},
}

-- 阵容推荐界面
config["card_battle_recommend.json"] = {
	set = {
		{"item.recommendPanel.textRecommend", "visible", false},
	},
	oneLinePos = {
		{"title", "title1", cc.p(15, 0), "left"},
	},
}

-- 多选1礼包
config["gift_choose.json"] = {
	set = {
		{"item", "visible", false},
		{"sliderPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"title.textNote", "positionX", {160}},
	},
	oneLinePos = {
		{"title.textNote", "title.textNote2", cc.p(5, 0), "left"},
	},
}

--抽卡预览界面
config["drawcard_preview.json"] = {
	set = {
		{"item", "visible", false},
		{"roleItem", "visible", false},
		{"innerList", "visible", false},
		{"textItem", "visible", false},
		{"textItem.textName", "fontSize", 40},
		{"textItem.textVal", "fontSize", 40},
	},
}

--公会选择精灵界面
config["union_select_sprite.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title1", "title2", cc.p(15, 0), "left"},
		{"textNumNote", "textNum"}
	},
}

--寻宝
config["explore_draw_item_view.json"] = {
	set = {
		{"onePanel.costPanel.bg", "contentSize", {485, 80}},
		{"onePanel.costPanel.bg", "positionX", 318},
		{"topRightPanel.txt1", "fontSize", 36},
		{"topRightPanel.txt", "positionX", 60},
	},
}

-- 资源找回界面
config["activity_resource_retrieve.json"] = {
	set = {
		{"item.textType", "fontSize", 36},
		{"item.textState", "anchorPoint", {0, 0.5}},
		{"item.textState", "positionX", {25}},
		{"item.img3", "anchorPoint", {0, 0.5}},
		{"item.img3", "positionX", {15}},
	},
}

-- 公会主界面
config["union_main.json"] = {
	set = {
		{"item", "visible", false},
		-- {"scrollBuilding.dailygift.lock.imgBg", "contentSize", {72,232}},
		{"scrollBuilding.dailygift.imgTextBG", "contentSize", {72,260}},
		{"scrollBuilding.dailygift.textNote", "positionY", {223}},
		{"scrollBuilding.training.imgTextBG", "contentSize", {72,295}},
		{"scrollBuilding.training.textNote", "positionY", {585}},
		-- {"scrollBuilding.unionfight.lock.imgBg", "contentSize", {360,60}},
		-- {"scrollBuilding.unionFuli.lock.imgBg", "contentSize", {360,60}},
		-- {"scrollBuilding.fragdonate.lock.imgBg", "contentSize", {360,60}},
		-- {"scrollBuilding.unionShop.lock.imgBg", "contentSize", {360,60}},
		-- {"scrollBuilding.unionNoName3.lock.imgBg", "contentSize", {360,60}},
		{"scrollBuilding.dailygift.imgTextBGMask", "contentSize", {72, 320}},
		{"scrollBuilding.training.imgTextBGMask", "contentSize", {72, 320}},
		{"scrollBuilding.unionskill.imgTextBGMask", "contentSize", {72, 320}},
		{"scrollBuilding.fuben.imgTextBGMask", "contentSize", {72, 320}},
		{"scrollBuilding.unionfight.imgTextBGMask", "contentSize", {72, 320}},
		{"scrollBuilding.unionFuli.imgTextBGMask", "contentSize", {72, 320}},
		{"scrollBuilding.unionNoName3.imgTextBGMask", "contentSize", {72, 320}},
		{"scrollBuilding.fragdonate.imgTextBGMask", "contentSize", {72, 320}},
		{"scrollBuilding.unionAnswer.imgTextBGMask", "contentSize", {72, 320}},
		{"scrollBuilding.unionfight.imgTextBGMask", "positionY", 222},
		{"scrollBuilding.dailygift.imgTextBGMask", "positionY", 191},
		{"scrollBuilding.training.imgTextBGMask", "positionY", 573},
		{"scrollBuilding.unionskill.imgTextBGMask", "positionY", 442},
		{"scrollBuilding.fuben.imgTextBGMask", "positionY", 213},
		{"scrollBuilding.fragdonate.imgTextBGMask", "positionY", 315},
		{"scrollBuilding.unionAnswer.imgTextBGMask", "positionY", 143},
	},
	dockWithScreen = {
		{"redpacket", "right"},
		{"leftUp", "left"},
	},
}

-- 公会申请条件界面
config["union_current_state.json"] = {
	set = {
		{"needRequest.textNote", "fontSize", 36},
		{"refuse.textNote", "fontSize", 36},
		{"free.textNote", "fontSize", 36},
	},
}

-- 修改昵称
config["card_changename.json"] = {
	set = {
		{"nameField", "contentSize", {500,45}},
	},
}

-- 端午活动
config["activity_duanwu_fabrication.json"] = {
	set = {
		{"item.name", "fontSize", {34}},
	},
}

-- 新手选择角色
config["character_select_figure.json"] = {
	set = {
		{"topPanel.subTitle", "visible", false},
	},
}

-- 直购礼包
config["activity_direct_buy_gift.json"] = {
	set = {
		{"item", "visible", false},
		{"item.subList", "visible", false},
		{"item.item", "visible", false},
		{"item.mask.img", "contentSize", {350,80}},
	},
}

-- prompt_box
config["common_prompt_box.json"] = {
	set = {
		{"content", "contentSize", {850,460}},
	},
}

-- 道具详情
config["common_item_detail.json"] = {
	set = {
		{"baseNode.name", "fontSize", 44},
	},
}

-- 活动推送海报界面
config["activity_poster.json"] = {
	oneLinePos = {
		{"leftPanel.checkBox", "leftPanel.title", cc.p(10, 0), "left"},
	},
}

-- 限时折扣
config["activity_server_open_discount.json"] = {
	set = {
		{"item.name", "fontSize", 35},
		{"newPrice.num", "fontSize", 45},
	},
	oneLinePos = {
		{"oldPrice.icon", "oldPrice.textNode", cc.p(15, 10), "right"},
		{"newPrice.icon", "newPrice.textNode_1", cc.p(15, 10), "right"},
		{"newPrice", "txt", cc.p(80, 5), "left"},
	},
}

-- 精灵投资
config["activity_weekly_card.json"] = {
	set = {
		{"item", "visible", false},
		{"text1", "fontSize", 50},
		{"textCountDown", "fontSize", 50},
	},
	-- oneLinePos = {
	-- 	{"textTitle", {"text1", "textCountDown"}, cc.p(0, 0), "left"},
	-- },
}

-- 限时神兽
config["activity_limit_sprite.json"] = {
	set = {
		{"bottomPanel.item", "visible", false},
		{"rightPanel.rankItem", "visible", false},
		{"rightPanel.scoreItem", "visible", false},
		{"leftPanel.drawTenPanel.textBg", "positionX", 205},
		{"rightPanel.timeTextNote","positionY",1050},
		{"rightPanel.timeTextNote","positionX",235},
		{"rightPanel.timeText","positionY",1050},
		{"rightPanel.timeText","positionX",523},
		{"leftPanel.drawTenPanel.textBg.text","fontSize",28},
		{"leftPanel.drawOnePanel.textBg.text","fontSize",28},
		{"bottomPanel.text","fontSize",22},
		{"bottomPanel.text","scale",1.5},
	}
}



-- 春节红包领取详情
config["activity_chinese_new_year.json"] = {
	oneLinePos = {
		-- {"text", "time", cc.p(-20, 0), "right"},
		{"text", "time", cc.p(5, 0), "left"},
	},
}

-- 春节红包领取详情
config["activity_get_particulars.json"] = {
	oneLinePos = {
		{"name", "txt", cc.p(-20, 0), "right"},
		{"txt", "name", cc.p(5, 0), "left"},
	},
}

-- 扭蛋机
config["activity_lucky_egg.json"] = {
	set = {
		{"mainPanel.drawOnePanel.oneBg.text", "fontSize", 28},
	},
}

-- 竞技场-积分奖励
config["arena_point_reward.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
	},
	oneLinePos = {
		{"title.textTitle1", "title.textTitle2", cc.p(15, 0), "left"},
		{"down.textTodayNote", "down.textScore"},
	}
}

-- 公会关卡排行界面
config["union_gate_rank.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title1", "title2", cc.p(15, 0), "left"},
	},
}

-- 邮件
config["mail.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"btnItem", "visible", false},
		{"right", "visible", false},
		{"left.noMailPanel.textNote", "fontSize", 46},
		{"right.textTitle","fontSize",45}
	},
}

-- 春节发红包弹框
config["common_send_text.json"] = {
	oneLinePos = {
		{"texe2", "num2", cc.p(15, 0), "left"},
		{"texe3", {"num3", "currency"}, cc.p(15, 0), "left"},
	},
}

-- 元素挑战 精灵展示界面
config["clone_battle_spr_show.json"] = {
	set = {
		{"item", "visible", false},
		{"item.text", "fontSize", 34},
	},
}

-- 极限属性
config["card_star_skill.json"] = {
	set = {
		{"barPanel.bar", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"item", "visible", false},
		{"selectPanel", "visible", false},
		{"cardItem", "visible", false},
		{"selectPanel","visible", false},
		{"selectPanel.subList","visible", false},
		{"item", "contentSize", {300, 102}},
		{"item.btn", "contentSize", {300, 102}},
		{"item.btn", "positionX", {150}},
		{"item.title", "positionX", {150}},
		{"item.title", "fontSize", 35},
		{"textTips", "anchorPoint", {0, 0.5}},
		{"cardPanel2.btnFrags", "contentSize", {280, 102}},
		{"cardPanel2.btnFrags.textNote", "positionX", {140}},
		{"selectPanel.btnCombine", "contentSize", {200, 102}},
		{"selectPanel.btnCombine.textNote", "positionX", {100}},
	},
	oneLinePos = {
		{"btnList", "textTips", cc.p(0, -40)},
		{"selectPanel.textNote", "selectPanel.textNum", cc.p(10, 0)},
		{"selectPanel.btnCombine", "selectPanel.btnFrags", cc.p(0, 0)},
	},
	scaleWithWidth = {
		{"cardPanel2.btnFrags.textNote", nil, 240},
		{"selectPanel.btnCombine.textNote", nil, 160},
		{"selectPanel.btnFrags.textNote", nil, 200},
	},
}

-- 随机塔-随机事件
config["random_tower_select_event.json"] = {
	set = {
		{"item", "visible", false},
		{"textTitle", "anchorPoint", {0.5,0.5}},
	},
}

-- 连续充值
config["activity_recharge_gift.json"] = {
	set = {
		{"itemBox", "visible", false},
		{"item", "visible", false},
		{"txtBg", "contentSize", {1100, 84}}
	},
	oneLinePos = {
		{"txtBg1", "rmb", cc.p(10, 0), "left"},
		{"txtBg2", "box", cc.p(-40, 0), "left"},
		{"box", "txtBg2", cc.p(8, 0), "right"},
	},
}

config["activity_fight_rank.json"] = {
	set = {
		{"centerPanel.mainPanel.fightAwardPanel.item", "visible", false},
		{"centerPanel.mainPanel.rankAwardPanel.item", "visible", false},
		{"centerPanel.mainPanel.rankPanel.item", "visible", false},
		{"centerPanel.spritePanel.item","visible",false},
		{"leftPanel.item", "visible", false},
		{"centerPanel.mainPanel.fightAwardPanel","visible",false},
		{"centerPanel.mainPanel.rankAwardPanel","visible",false},
		{"centerPanel.mainPanel.rankPanel","visible",false},
		{"topPanel.ruleBtn", "positionX", 1250},
	}
}

-- 选服
config["login_server.json"] = {
	set = {
		{"leftItem", "visible", false},
		{"item", "visible", false},
		{"subList", "visible", false},
	},
	oneLinePos = {
		{"hideTip", "hideIcon", cc.p(40, 0), "right"},
		{"hideIcon", "hideTip", cc.p(5, 0), "left"},
	},
}

-- 战斗主界面
config["battle.json"] = {
	dockWithScreen = {
		{"topLeftPanel", "left", "up", false},
		{"topRightPanel", "right", "up", false},
		{"midPanel.widgetPanel.speedRank", "right", nil, true},
		{"midPanel.widgetPanel.wavePanel", "left", "up", false},
		{"midPanel.skip", "left", nil, true}, -- 特殊处理 skip
		{"bottomLeftPanel", "left", "down", false},
		{"bottomRightPanel", "right", "down", false},
	},
	set = {
		{"midPanel.widgetPanel.topinfo.weather", "visible", false},
		{"midPanel.widgetPanel.weatherInfo", "visible", false},
		{"bottomRightPanel.skillInfo", "visible", false},
		{"bottomLeftPanel.mainSkillPass.imgClose.text", "fontSize", 25},
		{"bottomLeftPanel.mainSkillPass.imgClose.text", "width", 100},
	},
}

-- 显示通行证 购买界面
config["activity_passport_buy.json"] = {
	set = {
		{"item", "visible", false},
		{"item.txtDiscount", "fontSize", 40},
	},
}

config["union_fight_fighting_list.json"] = {
	set = {
		{"itemBattle.baseNode.rightEmpty.text", "fontSize", 34},
		{"itemBattle.baseNode.leftEmpty.text", "fontSize", 34},
	},
}

config["union_fight_fighting_list_dialog.json"] = {
	set = {
		{"itemBattle.baseNode.rightEmpty.text", "fontSize", 34},
		{"itemBattle.baseNode.leftEmpty.text", "fontSize", 34},
	},
}

config["union_combat_star.json"] = {
	set = {
		{"text", "fontSize", 50},
	},
}

-- 公会战斗布置界面
config["union_fight_assign.json"] = {
	set = {
		{"item", "visible", false},
		{"item.info.textFightPoint", "scale", 0.9},
		{"item.info.textFightNote", "scale", 0.9},
		{"item1", "visible", false},
		{"item2", "visible", false},
		{"innerList", "visible", false},
		{"timeInfo.textTimeNote", "fontSize", 40},
	},
	oneLinePos = {
		{"item.info.textFightNote", "item.info.textFightPoint", cc.p(10,0)},
	},
}

--精灵评论排行榜
config["card_comment_rank.json"] = {
	set = {
		{'left.item', "visible", false},
		{'right.commentRank.left.pageItem', "visible", false},
		{'right.commentRank.right.item', "visible", false},
		{'right.fightingRank.right.item', "visible", false},
	},
	oneLinePos = {
		{"title.txt", "title.txt1", cc.p(10,0)},
		{"right.commentRank.right.item.imgCompare", "right.commentRank.right.item.txtCompare", cc.p(20,0), "right"},
		{"right.commentRank.left.scoreBg.txt3", "right.commentRank.left.scoreBg.img", cc.p(20,0)},
	},
}

--符石属性展示
config["gem_add_effect.json"] = {
	set = {
		{"item2", "visible", false},
		{"harm", "visible", false},
		{"effect", "visible", false},
		{"suitItem", "visible", false},
		{"noItem", "visible", false},
		{"suitItem", "contentSize", {650, 228}},
		{"suitPanel.suitList", "contentSize", {1950, 228}},
		{"list", "contentSize", {1950, 1103}},
	},
	oneLinePos = {
		{"effect.name", "effect.num", cc.p(100, 0)},
		{"suitItem.num", "suitItem.txt1", cc.p(50, 0)},
		{"suitItem.num", "suitItem.txt2", cc.p(50, 0)},
	},
}

-- 符石共鸣效果界面
config["gem_resonance.json"] = {
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(5, 0),"left"},
	},
	set = {
		{"title1", "anchorPoint", {0.4, 0.5}},
		{"title2","fontSize",35},
		{"icon1.txt","fontSize",35},
		{"icon2.txt","fontSize",35},
		{"icon3.txt","fontSize",35},
		{"icon4.txt","fontSize",35},
		{"icon5.txt","fontSize",35},
	},
}

-- 符石强化界面
config["gem_strengthen.json"] = {
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(5, 0)},
	},
}

-- 符石抽取界面
config["gem_draw.json"] = {
	oneLinePos = {
		{"autoDecompose", "txtAutoDecompose", cc.p(0, 0),"left"},
		{"drawOnePanel.cutDownPanel.textNote", "drawOnePanel.cutDownPanel.imgIcon", cc.p(10, 0), "right"},
		{"drawOnePanel2.cutDownPanel.textNote", "drawOnePanel2.cutDownPanel.imgIcon", cc.p(10, 0), "right"},
	},
	set = {
		{"txtAutoDecompose","fontSize",30},
		{"drawOnePanel.cutDownPanel.textNote","fontSize",30},
		{"drawOnePanel2.cutDownPanel.textNote","fontSize",30}
	}
}

-- 符石品质指数
config["gem_index.json"] = {
	set = {
		{"counTxt1", "scale", 0.8},
		{"counTxt2", "scale", 0.8},
		{"list", "contentSize", {755, 662}},
	},
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(5, 0)},
	},
}

-- 限时符石详情
config["gem_preview.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"item2", "visible", false},
		{"item21", "visible", false},
		{"item21.textName", "fontSize", 38},
		{"item21.textName", "textVal", 38},
	},
}

config["gem_select_sprite.json"] = {
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(0, 0),"left"},
	}
}

-- 符石分解
config["gem_resolve.json"] = {
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(5, 0),"left"},
		{"jumpShop.textNote1", "jumpShop.textNote2", cc.p(10, 0),"left"},
	},
	set = {
		{"jumpShop.textNote1","fontSize",40},
		{"jumpShop.textNote2","fontSize",40},
	}
}

config["gem.json"] = {
	set = {
		{"left.btnDraw","positionX",120},
		{"left.btnDecompose","positionX",120},
	}
}

config["gem_filter.json"] = {
	set = {
		{"item.name","fontSize",25}
	}
}

--快速扫荡
config["gate_quick.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"panel.listPanel", "visible", false},
		{"panel.listPanel.item", "visible", false},
		{"panel1.panelNormal.listPanel", "visible", false},
		{"panel1.panelNormal.listPanel.item1", "visible", false},
		{"item", "visible", false},
		{"panel1.btnBuy1.txt", "anchorPoint", {0.5, 0.5}},
		{"panel1.btnBuy1.txt", "positionX", {160}},
		{"panel1.btnBuy1.txt", "fontSize", 40},
	},
}

-- 跨服竞技场布阵界面
config["cross_arena_embattle.json"] = {
	set = {
		{"battlePanel1.imgDuiwu.textNote","fontSize",25},
		{"battlePanel2.imgDuiwu.textNote","fontSize",25},
	},
	oneLinePos = {
		{"battlePanel1.fightNote.textFightNote", "battlePanel1.fightNote.textFightPoint", cc.p(5, 0)},
		{"battlePanel2.fightNote.textFightNote", "battlePanel2.fightNote.textFightPoint", cc.p(5, 0)},
	},
}

-- cross_arena-战斗回访
config['cross_arena_combat_record.json'] = {
	set = {
		{'myPanel.item', "visible", false},
		{'goodPanel.item', "visible", false},
		{'leftPanel.tabItem', "visible", false},
	},
	oneLinePos = {
		{"title.textTitle1","title.textTitle2",cc.p(10,0),"left"}

	}
}

-- cross_arena-段位奖励
config['cross_arena_stage_reward.json'] = {
	set = {
		{'rewardPanel.rankItem', "visible", false},
		{'rewardPanel1.rankItem', "visible", false},
		{'rewardPanel2.rankItem', "visible", false},
		{'rewardPanel3.rankItem', "visible", false},
		{'leftPanel.tabItem', "visible", false},
	},oneLinePos = {
		{"topPanel.txtNode", "topPanel.txtNode1", cc.p(5, 0)},
		},
}

-- 精灵背包
config['card_bag.json'] = {
	scaleWithWidth = {
		{"panelBtn.btn1.textNote", nil, 140},
		{"panelBtn.btn2.textNote", nil, 140},
		{"panelBtn.btn3.textNote", nil, 140},
	},
}

-- 探险执照升级界面
config["trainer_skill_upgrade.json"] = {
	oneLinePos = {
		{"txt1", "curr", cc.p(10, 0)},
		{"txt2", "next", cc.p(10, 0)},
	},
}

-- 探险执照属性界面
config["trainer_attr.json"] = {
	scaleWithWidth = {
		{"name", nil, 50},
	},
}

-- 活动道具转换
config["activity_item_exchange.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"item.checkPanel.ignoreHint", "item.checkPanel.checkBox", cc.p(5, 0), "right"},
	},
	scaleWithWidth = {
		-- {"rightPanel.topPanel.iconAll.txt", nil, 50},
		{"item.exchangebtn.label", nil, 230},
	},
}

-- 石英大会主赛程
config["main_schedule_eight.json"] = {
	scaleWithWidth = {
		{"pageBtns.btnChampion.textNote", nil, 200},
	},
}

-- 饰品快速强化
config["card_equip_fast_strengthen.json"] = {
	set = {
		{"top.bg", "positionX", {670}},
		{"top.subBtn", "positionX", {520}},
		{"top.addBtn", "positionX", {823}},
		{"top.nameMax", "positionX", {670}},
	},
	oneLinePos = {
		{"materialNote", "title", cc.p(10, 0), "left"},
	},
	scaleWithWidth = {
		{"title", nil, 1000},
	},
}

-- 图鉴突破
config["handbook_break.json"] = {
	set = {
		{"item", "visible", false},
		{"btnItem", "visible", false},
		{"item.btnBreak", "contentSize", {260, 122}},
		{"item.btnBreak.textNote", "positionX", {130}},
	},
	oneLinePos = {
		{"panel.title.textNote1", "panel.title.textNote2", cc.p(10, 0), "left"},
	},
	scaleWithWidth = {
		{"item.btnBreak.textNote", nil, 230},
	},
}

-- 携带道具显示
config["held_item_bag.json"] = {
	set = {
		{"innweList", "visible", false},
		{"attrInnerList", "visible", false},
		{"item", "visible", false},
		{"item1", "visible", false},
		{"roleItem", "visible", false},
	},
	oneLinePos = {
		{"right.center.textHoldEffect", "right.center.btnInfo", cc.p(10, 0), "left"},
	},
}

-- 携带升星界面
config["held_item_advance.json"] = {
	set = {
		{"leftPanel.attrSubList", "visible", false},
		{"strengthenPanel.itemSubList", "visible", false},
		{"strengthenPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
	},
	oneLinePos = {
		{"advancePanel.attrNote", "advancePanel.btnInfo", cc.p(10, 0), "left"},
	},
	scaleWithWidth = {
		{"advancePanel.btnAdvance.title", nil, 230},
	},
}

-- 携带升星选择精灵界面
config["held_item_advance_select.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"textNote", "textNum", cc.p(10, 0), "left"},
	},
}
-- 石英大会玩家信息
config["craft_battle_enemy.json"] = {
	set = {
		{"imgStar", "visible", false},
		{"finalPanel.championPanel.bg", "scale", 0.8},
		{"finalPanel.finalFourPanel.bg", "scale", 0.8},
	},
	oneLinePos = {
		{"topPanel.txtNode", "topPanel.txtNode2", cc.p(10, 0), "left"},
		{"rolePanel.txtNodeRecord", "rolePanel.txtRecord", cc.p(10, 0), "left"},
	},
	scaleWithWidth = {
		{"finalPanel.championPanel.txtNode", nil, 100},
		{"finalPanel.semifinalsPanel.txtNode", nil, 100},
		{"finalPanel.finalFourPanel.txtNode", nil, 100},
	},
}

-- 限时PVP布阵
config["craft_battle.json"] = {
	set = {
		{"item", "visible", false},
		{"imgStar", "visible", false},
		{"roleItem", "visible", false},
		{"up.spe.textTitle","fontSize",25}
	},
	oneLinePos = {
		{"down.textNum", "down.textNote1", cc.p(10, 0), "right"},
	},
	scaleWithWidth = {
		{"down.btnOneKeySet.textNote", nil, 300},
	},
}

--随机塔-补给buff
config["random_tower_use_buff.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title.textTitle1", "title.textTitle2", cc.p(5, 0), "left"},
		{"textNote", "textNum", cc.p(5, 0)},
	},
}

-- 石英大会玩家信息
config["random_tower_rank.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title.textTitle1", "title.textTitle2", cc.p(10, 0), "left"},
	},
}

-- 玩家经验溢出
config["personal_overflow_experience.json"] = {
	oneLinePos = {
		{"up.title1", "up.title2", cc.p(10, 0), "left"},
	},
}

-- 竞技场排行榜
config["arena_rank.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title.textTitle1", "title.textTitle2", cc.p(10, 0), "left"},
	},
}

-- 执照提升
config["trainer_attr_skills.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(10, 0), "left"},
		{"txt5", {"num", "icon", "btnReset"}, cc.p(10, 0), "left"},
	},
	scaleWithWidth = {
		{"item.panel.attrName", nil, 35},
	},
}

-- 个体值
config["card_nvalue.json"] = {
	set = {
		{"panel.down.textNote", "positionY", 300},
	},
}

--竞技场个人信息界面
config["arena_personal_info.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title.textTitle1", "title.textTitle2"},
		{"top.textNameNote", "top.textName"},
		{"top.textRankNote", "top.textRank"},
		{"top.textFightPointNote", "top.textFightPoint"},
		{"top.textUnionNote", "top.textUnion"},
	},
}

--日常副本排行界面
config["daily_activity_rank.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title.textTitle1", "title.textTitle2"},
	},
}

-- 探险器重铸界面
config["explore_decompose_view.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
		{"item1", "visible", false},
	},
	oneLinePos = {
		{"title", "title1"},
	},
}

-- 限时PVP 押注
config["craft_bet.json"] = {
	set = {
		{"betPanel.betItem", "visible", false},
	},
	oneLinePos = {
		{"topPanel.txtNode", "topPanel.txtNode2", cc.p(10, 0)},
	},
}

--公会关卡进度界面
config["union_gate_progress.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title1", "title2", cc.p(10, 0)},
	},
}

-- 运营活动主界面
config["activity.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
		{"rightPanel.topPanel.iconAll", "visible", false},
		{"rightPanel.topPanel.name", "fontSize", 85},
	},
	scaleWithWidth = {
		{"rightPanel.topPanel.iconAll.txt", nil, 230},
	},
}

-- 公会许愿主界面
config["union_frag_donate.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"item.haveNote", "item.haveNum", cc.p(10, 0)},
	},
}

-- 公会许简介界面
config["union_info.json"] = {
	oneLinePos = {
		{"title.textNote1", "title.textNote2", cc.p(10, 0)},
	},
}

-- 一键突破界面
config["card_advance_onekey.json"] = {
	 oneLinePos = {
		{"titleTxt1", "titleTxt2", nil,"left"},
     },
}

-- 神秘商店
config["mystery_shop_show.json"] = {
	set = {
	   {"imgTip", "scale", 2.5},
	},
}

-- 天赋
config["talent_detail.json"] = {
	 scaleWithWidth = {
		{"upgradePanel.btnUpgrade.title", nil, 300},
     },
}

-- 精灵属性
config["card_attrdetail.json"] = {
	set = {
		{"list.centerPanel.attrPanel1.item", "contentSize", {415, 42}},
		{"list.centerPanel.attrPanel1.innerList", "contentSize", {830, 42}},
		{"list.centerPanel.attrPanel1.item.txt1", "positionY", {21}},
		{"list.centerPanel.attrPanel1.item.txt2", "positionY", {21}},
		{"list.centerPanel.attrPanel1.item.txt1", "fontSize", 36},
		{"list.centerPanel.attrPanel1.item.txt2", "fontSize", 36},
	},
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(10, 0), "left"},
	},
}

-- 卡牌升级
config["card_upgrade.json"] = {
	set = {
		{"item", "visible", false},
		{"slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
	},
	oneLinePos = {
		{"titleTxt1", "titleTxt2", cc.p(10, 0), "left"},
	},
}

-- 购买体力
config["common_gain_stamina.json"] = {
	oneLinePos = {
		{"content.leftTimesInfo", "content.leftTimes1", cc.p(120, 0), "left"},
		{"content.leftTimes1", "content.leftTimesInfo", cc.p(10, 0), "right"},
	},
}

-- 获得途径
config["common_gain_way.json"] = {
	set = {
		{"item.title", "fontSize", 52},
	},
}

-- 极限点兑换精灵选择
config["zawake_choose_frag.json"] = {
	set = {
		{"tipPanel.imgTextBg", "scaleX", 1.5},
		{"innerList", "visible", false},
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title.textNote1", "title.textNote2", cc.p(10, 0)},
	},
}

-- 精灵好感度交换
config["card_property_swap_choose.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false}
	},
	oneLinePos = {
		{"title","title1",cc.p(5,0),"left"}
	}
}

-- 精灵分解
config["rebirth_main.json"] = {
	set = {
		{"item", "visible", false},
		{"btnItem", "visible", false},
		{"innerList", "visible", false},
		{"starItem", "visible", false},
		{"attrItem", "visible", false},
	},
	dockWithScreen = {
		{"left.panelGem", "left", nil, true},
		{"left.panelChip", "left", nil, true},
		{"right", "right", nil, true},
		{"page", "right", nil, true},
	},
	oneLinePos = {
		{"left.panelDecompose.jumpShop.textNote1","left.panelDecompose.jumpShop.textNote2",cc.p(0,3),"left"}
	},
}

-- 公会布阵
config["union_embattle.json"] = {
	set = {
		{"btnOneKeySet.textNote","fontSize",40}
	}
}

-- 公会对战详情
config["union_fight_battle_review.json"] = {
	oneLinePos = {
		{"itemBattle.baseNode.rightPanel.team","itemBattle.baseNode.rightPanel.hpText",cc.p(100,0),"left"},
		{"itemBattle.baseNode.leftPanel.team","itemBattle.baseNode.leftPanel.hpText",cc.p(100,0),"left"}
	},
}

-- 符石详情
config["gem_details.json"] = {
	set = {
		{"panel.title", "anchorPoint",{0.3, 0.5}},

	},
	oneLinePos = {
		{"panel.quile","panel.quality",cc.p(10,0),"left"}
	}
}


-- 精灵投资
config["activity_weekly_card.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"textCountDown","text1",cc.p(-300,5),"right"},
	}
}

-- 限时PVP参赛阵容（敌人）
config["craft_battle_enemy.json"] = {
	set = {
		{"imgStar", "visible", false},
		{"finalPanel.substitutePanel.txtNode","fontSize",25},
		{"finalPanel.championPanel.txtNode","fontSize",25},
		{"finalPanel.semifinalsPanel.txtNode","fontSize",25},
		{"finalPanel.finalFourPanel.txtNode","fontSize",25}
	},
	oneLinePos = {
		{"rolePanel.txtNodeRecord","rolePanel.txtRecord",cc.p(10,0),"left"},
		{"topPanel.txtNode","topPanel.txtNode2",cc.p(5,0),"left"}
	}
}

-- 限时PVP 排行榜
config["craft_rank.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"rankPanel.rankItem", "visible", false},
		{"rewardPanel.rewardItem", "visible", false},
	},
	oneLinePos = {
		{"topPanel.title","topPanel.subTitle",cc.p(5,0),"left"}
	},
}

-- 跨服石英大会排行奖励
config["cross_craft_rank.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"rankPanel.rankItem", "visible", false},
		{"rewardPanel.rewardItem", "visible", false},
		{"rewardPanel.txtNode1", "positionX", {250}},
	},
	oneLinePos = {
		{"topPanel.txtNode","topPanel.txtNode1",cc.p(5,0),"left"},
	}


}

-- 跨服石英大会查看阵容详情
config["cross_craft_array_info.json"] = {
	set = {
		{"prePanel.group", "visible", false},
		{"prePanel.group.item", "visible", false},
		{"finalPanel.group", "visible", false},
		{"finalPanel.group.item", "visible", false},
		{"finalPanel.backup.item", "visible", false},
		{"finalPanel.backup.txt","fontSize",25},
		{"finalPanel.group.state","fontSize",25},
	},
	oneLinePos = {
		{"topPanel.title1","topPanel.title2",cc.p(5,0),"left"},
		{"rolePanel.txt","rolePanel.record",cc.p(10,0),"left"},
	}
}

-- 跨服石英大会布阵界面
config["cross_craft_embattle.json"] = {
	set = {
		{"up.special", "visible", false},
		{"down.btnOneKey.txt","fontSize",40},
		{"up.groupItem.state", "scale", 0.1},
	},
	oneLinePos = {
		{"prepare.title","prepare.round",cc.p(5,0),"left"},
	}
}

-- 跨服石英大会下注
config["cross_craft_bet.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"betPanel.betItem", "visible", false},
	},
}

config["cross_craft_myschedule.json"] = {
	set = {
		{"item", "visible", false},
		{"item.time.textTime", "fontSize", 75},
	}
}

-- 跨服石英大会主赛程
config["cross_craft_mainschedule.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
	},
	dockWithScreen = {
		{"leftDown", "left", "down"},
		{"btnMySchedule", "right", "down"},
	},
	oneLinePos = {
		{"view1.title.imgTitle1","view1.title.imgTitle2",cc.p(5,0),"left"},
		{"view1.title.imgTitle2","view1.title.imgTitle3",cc.p(5,0),"left"},
	}
}

-- 符石详情
config["common_details.json"] = {
	set = {
		{"baseNode.title", "anchorPoint",{0.3, 0.5}},
	},
	oneLinePos = {
		{"baseNode.quile","baseNode.quality",cc.p(10,0),"left"}
	}
}

-- 刨冰排行榜
config["beach_ice_rank.json"] = {
	oneLinePos = {
		{"title.txt","title.txt1",cc.p(5,0),"left"},
	},
	scaleWithWidth  = {
		{"right.noRank.img3.txt" ,nil, 550},
	},
	set = {
		{"right.rank.item","visible",false},
	}
}


--排球奖励
config["volleyball_reward.json"] = {
	oneLinePos = {
		{"topPanel.txtNode","topPanel.txtNode1",cc.p(5,0),"left"},
	},
	set = {
		{"rewardPanel1.rankItem", "visible", false},
		{"rewardPanel2.rankItem", "visible", false},
		{"leftPanel.tabItem", "visible", false},
	},
	scaleWithWidth  = {
		{"leftPanel.tabItem.selected.txt" ,nil, 235},
	},
}

-- 排球游戏界面
config["volleyball_game.json"] = {
	set = {
		{"scoreboard.enemy.txt", "fontSize", 50},
	}
}

--充值返钻
config["activity_once_recharge_award.json"] = {
	set = {
		{"rechargeItem1.txtTitleNode", "fontSize",28},
		{"rechargeItem2.txtTitleNode", "fontSize",28},
		{"rechargeItem3.txtTitleNode", "fontSize",28},
		{"rechargeItem4.txtTitleNode", "fontSize",30},
		{"rechargeItem5.txtTitleNode", "fontSize",30},
		{"rechargeItem6.txtTitleNode", "fontSize",30},
		{"rechargeItem7.txtTitleNode", "fontSize",30},
		{"rechargeItem1.txtDescNode", "fontSize",30},
		{"rechargeItem2.txtDescNode", "fontSize",30},
		{"rechargeItem3.txtDescNode", "fontSize",30},
		{"rechargeItem1.txtDescNode", "positionX",{54}},
		{"rechargeItem2.txtDescNode", "positionX",{54}},
		{"time","positionX",{1630}},
		{"time","fontSize",40}
	}
}

config["activity_server_open_may_day.json"] = {
	set = {
		{"topPanel.time","fontSize",45}
	}
}

--沙滩刨冰
config["beach_ice_view.json"] = {
	set = {
		{"demandPanel.item","visible",false},
		{"huodongTimePanel","positionX",{2130}}
	},
	dockWithScreen = {
		{"leftDownPanel", "left", "down", true},
		{"huodongTimePanel", "right", "up", true},
	},
}

--限定符石
config["activity_gem_up.json"] = {
	set = {
		{"titleTxt1", "anchorPoint",{0.3, 0.5}},
		{"right.title","fontSize",35},
		{"left.clickPanel1.txt","fontSize",30},
		{"left.clickPanel2.txt","fontSize",25},
	},
	oneLinePos = {
		{"titleTxt1","titleTxt2",cc.p(5,0),"left"},
		{"left.hint","left.hintBtn",cc.p(5,0),"left"},
	},
}

-- 符石详情
config["common_gem_details.json"] = {
	set = {
		{"baseNode.title", "anchorPoint",{0.3, 0.5}},
	},
	oneLinePos = {
		{"baseNode.quile","baseNode.quality",cc.p(10,0),"left"},
	}
}

-- 限定符石抽取
config["activity_gem.json"] = {
	set = {
		{"timeBg","anchorPoint",{-0.5,1}},
		{"time","anchorPoint",{-0.6,1}},
		{"btnClose","anchorPoint",{-2.5,0.7}},
	}
}

-- 跨服竞技场挑战界面
config['cross_arena_enemy.json'] = {
	set = {
		{"enemyPanel.btnChallenge.textNote","fontSize",30},
	},
	dockWithScreen = {
		{"rightDownPanel", "right", "down", false},
	},
	oneLinePos = {
		{"noteBg","textNoteTime",cc.p(10,0),"left"},
	}
}

config["cross_arena_info.json"] = {
	set = {
		{"sevenPanel.txt","anchorPoint",{0.28,0.5}},
	},
	oneLinePos = {
		{"sevenPanel.txt","sevenPanel.textTime",cc.p(10,0),"left"},
	}
}

-- cross_arena-段位奖励
config['cross_arena_stage_reward.json'] = {
	set = {
		{'rewardPanel.rankItem', "visible", false},
		{'rewardPanel1.rankItem', "visible", false},
		{'rewardPanel2.rankItem', "visible", false},
		{'rewardPanel3.rankItem', "visible", false},
		{'leftPanel.tabItem', "visible", false},
		{"rewardPanel.txt","fontSize",35},
		{"rewardPanel2.txt","fontSize",35},
		{"rewardPanel3.txt","fontSize",35},
	},
	oneLinePos = {
		{"topPanel.txtNode","topPanel.txtNode1",cc.p(10,0),"left"},
	}
}

-- cross_arena-个人信息
config['cross_arena_personal_info.json'] = {
	set = {
		{'item', "visible", false},
		{'baseNode.down1.imgOrangeBg.textNote',"fontSize",32},
		{'baseNode.down1.imgOrangeBg.textNote',"anchorPoint",{0.28,0.45}},
		{'baseNode.down2.imgOrangeBg.textNote',"anchorPoint",{0.28,0.45}},
		{'baseNode.down2.imgOrangeBg.textNote',"fontSize",32},
	},
	oneLinePos = {
		{"baseNode.top.textRankNote","baseNode.top.textRank",cc.p(10,0),"left"},
	}
}


-- 跨服竞技场主界面
config['cross_arena.json'] = {
	set = {
		{'serverPanel.subList', "visible", false},
		{'serverPanel.item', "visible", false},
		{'downPanel.defend.name','fontSize',28},
	},
	dockWithScreen = {
		{"downPanel", "left", "down", false},
	}
}

-- 聊天
config["chat.json"] = {
	set = {
		{"item", "visible", false},
		{"btn", "visible", false},
		{"topView", "visible", false},
		{"chatPanel.bottomPanel", "visible", false},
		{"item.system.txtFlag","fontSize",35}
	},
}

-- 钓鱼场景选择界面
config['fishing_main.json'] = {
	dockWithScreen = {
		{"left", "left"},
		{"right.scenePanel.list", "left"},
		{"right.scenePanel.txt", "left"},
		{"right.underLeft", "left"},
		{"right.underRight", "right"},
		{"right.fishingGameTag", "right"},
	},
	set = {
		{'right.underLeft.btnRank', "visible", false},
		{'right.tip', "visible", false},
		{'right.fishingGameTag', "visible", false},
		{'right.underRight.tip', "visible", false},
		{'right.underRight.numTip', "visible", false},
		{"btn", "visible", false},
		{"right.time", "visible", false},
		{"right.underRight.numTip","positionX",100},
		{"right.underRight.tip","positionX",100},
	},
	oneLinePos = {
		{"right.underRight.time","right.underRight.times",cc.p(10,0),"left"},
	}
}

-- 钓鱼背包界面
config['fishing_bag.json'] = {
	set = {
		{'btn', "visible", false},
		{'center.item', "visible", false},
		{'rightBait', "visible", false},
		{'rightPartner', "visible", false},
	},
	oneLinePos = {
		{"title.txt","title.txt1",cc.p(10,0),"left"},
	}
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
		{"rightPanel.imgTip.tip","fontSize",25},
		{"auto.fish.txt1","fontSize",40},
		{"auto.fish.txt2","fontSize",43},
		{"auto.fish.txt3","fontSize",40},
		{"auto.fish.txt4","fontSize",43},
		{"auto.fish.txt5","fontSize",40},
		{"auto.fish.txt6","fontSize",43},
		{"auto.fish.txt7","fontSize",40},
		{"partner.bg.txt","fontSize",30},
		{"auto.txt","anchorPoint",{0.8,0.5}},
		{"auto.tipOver","anchorPoint",{0.485,0.5}},
		{"activityTip.txt","fontSize",29},
		{"txtRank.rank","anchorPoint",{0.2,0.5}},
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
	},
	oneLinePos = {
		{"centerPanel.tipPanel.txtKeep", {"centerPanel.tipPanel.imgFish", "centerPanel.tipPanel.txtAnd","centerPanel.tipPanel.imgFishHook","centerPanel.tipPanel.txtEnd"}, cc.p(5, 0), "left"},
	},
}

-- 钓鱼大赛排行榜界面
config['fishing_rank.json'] = {
	set = {
		{'right.rank.item', "visible", false},
		{'left.item', "visible", false},
		{'right.reward.server.item', "visible", false},
		{'right.reward.reward.item', "visible", false},
		{'right.reward.server.txt',"anchorPoint",{0.30,0.45}},
		{'right.reward.reward.txt',"anchorPoint",{0.28,0.45}},
	},
	oneLinePos = {
		{"title.txt","title.txt1",cc.p(5,0),"left"},
	}
}

config["fishing_auto.json"] = {
	set = {
		{"fish.txt1","fontSize",40},
		{"fish.txt2","fontSize",43},
		{"fish.txt3","fontSize",40},
		{"fish.txt4","fontSize",43},
		{"fish.txt5","fontSize",40},
		{"fish.txt6","fontSize",43},
		{"fish.txt7","fontSize",40},
		{"tipMain","anchorPoint",{0.485,0.5}}
	}
}

--超进化精灵选择
config["card_mega_choose_card.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
	},
	oneLinePos = {
		{"title.textNote1","title.textNote2",cc.p(5,0),"left"},
		{"down.textNote","down.textNum",cc.p(5,0),"left"},
	},
}

--超进化中的转化
config["card_mega_debris.json"] = {
	set = {
		{"sliderPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"item", "visible", false},
		{"timesPanel.tip","fontSize",35},
	},
}

--进化链
config["card_evolution.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"branchPanel.btnBranch.title","fontSize",40},

	},
	oneLinePos = {
		{"title","title1",cc.p(5,0),"left"},
	},
}

--进化链选择分支
config["card_evolution_branch.json"] = {
	set = {
		{"item1", "visible", false},
		{"item2", "visible", false},
		{"line12", "visible", false},
		{"line122", "visible", false},
		{"line133", "visible", false},
		{"line13", "visible", false},
		{"btnPanel1.btnBranch.title","fontSize",35},
		{"btnPanel.btnBranch.title","fontSize",35},
		{"txt","anchorPoint",{0.3,0.5}},
	},
	oneLinePos = {
		{"title","title1",cc.p(5,0),"left"},
	},
}

config["card_mega_fragment_select.json"] = {
	oneLinePos = {
		{"title.textNote1","title.textNote2",cc.p(5,0),"left"},
	},
}

--以太直通车
config["random_tower_jump.json"] = {
	set = {
		{"panel1", "visible", false},
		{"panel1.item", "visible", false},
		{"panel2", "visible", false},
		{"panel2.item", "visible", false},
		{"panel3", "visible", false},
		{"panel3.item", "visible", false},
		{"panel4", "visible", false},
		{"panel4.item", "visible", false},
		{"panel2.item.btn1.textNote","fontSize",38},
		{"panel2.item.btn2.textNote","fontSize",38},
		{"panel3.btnRandom.textNote","fontSize",38},
	},
	oneLinePos = {
		{"title.textTitle1", "title.textTitle2", cc.p(5, 0)},
	},
}

-- 试练-随机塔
config["random_tower.json"] = {
	set = {
		{"item", "visible", false},
		{"panel", "visible", false},
	},
	dockWithScreen = {
		{"leftBottomPanel", "left", "down", false},
		{"rightBottomPanel", "right", "down", false},
	},
	oneLinePos = {
		{"leftBottomPanel.floorTitle", "leftBottomPanel.floor", cc.p(5, 0)},
		{"leftBottomPanel.floor", "leftBottomPanel.roomTitle", cc.p(10, 0)},
		{"leftBottomPanel.roomTitle", "leftBottomPanel.room", cc.p(5, 0)},
	},
}

--幸运乐翻天
config["activity_flip_card.json"] = {
	set = {
		{"leftPanel.item", "visible",false},
		{"leftPanel.list2", "visible",false},
		{"rightPanel.itemTask", "visible", false},
		{"rightPanel.itemHX", "visible", false}
	},
	oneLinePos = {
		{"rightPanel.itemTask.text1","rightPanel.itemTask.textNum1",cc.p(5,0)},
	}

}

--实时匹配
config["online_fight.json"] = {
	set = {
		{"mainPanel.rightPanel.unlimitedPanel.item", "visible", false},
		{"mainPanel.rankPointPanel.txt1","positionX", 15},
		{"mainPanel.rankPointPanel.txt2","positionX", 15},
	},
}

-- 实时匹配排行榜
config["online_fight_rank.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"item", "visible", false},
		{"leftPanel.tabItem.selected.txt","fontSize",30},
		{"leftPanel.tabItem.normal.txt","fontSize",28},
	},
	oneLinePos = {
		{"topPanel.txtNode","topPanel.txtNode1",cc.p(5,0)},
	},
}

-- 实时匹配战斗记录
config["online_fight_record.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"tabItem", "visible", false},
		{"item1", "visible", false},
		{"item2", "visible", false},
		{"tabItem.name","fontSize",30}
	},
	oneLinePos = {
		{"topPanel.txtNode","topPanel.txtNode1",cc.p(5,0)},
	},
}

-- 活跃夺宝
config["activity_liveness_wheel.json"] = {
	set = {
		{"taskItem", "visible", false},
		{"selected", "visible", false},
		{"wheelPanel.lessNums","position",{620, 363}}
	},
	oneLinePos = {
		{"btnSkip","tips",cc.p(30,0)},
	},
}

-- 关卡
config["gate.json"] = {
	set = {
		{"item", "visible", false},
		{"level", "visible", false},
		{"box", "visible", false},
		{"speLevel", "visible", false},
		{"levelInfo.textNoteNum4","positionX",100},
	},
	dockWithScreen = {
		{"leftDown", "left", "down"},
		{"btnLeft", "left"},
		{"btnRight", "right"},
		{"rightDown", "right", "down"},
		{"rightTop", "right", "up"},
	},
}

-- 道馆主界面
config["gym_challenge.json"] = {
	dockWithScreen = {
		{"rightDownPanel", "right", "up", false},
		{"rightTopPanel", "right", "down",false},
		{"btnLog", "left", "down", false},
	},
	set = {
		{"rightDownPanel.btnCross.textNote","fontSize",35},
		{"rightTopPanel.textNote2","fontSize",35},
		{"rightTopPanel.textTimes","fontSize",35},
		{"rightTopPanel.textNote1","fontSize",35},
		{"rightTopPanel.textTime","fontSize",35},
		{"rightTopPanel.textTimes","anchorPoint",{0.5,0.5}}
	},
	oneLinePos = {
		{"rightTopPanel.textNote2","rightTopPanel.textTimes",cc.p(60,0),"left"},
		{"rightTopPanel.textTimes","rightTopPanel.btnAdd",cc.p(50,0),"left"},
	}
}

config["gym_gate_detail.json"] = {
	set = {
		{"roleItem", "visible", false},
		{"iconItem", "visible", false},
		{"infoPanel.btnChallenge.textNote","fontSize",40}
	},
	oneLinePos = {
		{"infoPanel.textNote1","infoPanel.text1",cc.p(10,0),"left"},
		{"infoPanel.textNote2","infoPanel.text2",cc.p(10,0),"left"},
		{"infoPanel.textNote3","infoPanel.text3",cc.p(10,0),"left"},
		{"infoPanel.textNote4","infoPanel.text4",cc.p(10,0),"left"},
	}
}

config["gym_npc_info.json"] = {
	set = {
		{"imgBG.attrItem", "visible", false},
	},
	oneLinePos = {
		{"title.textTitle1","title.textTitle2",cc.p(10,0),"left"},
	}
}

config["gym_buf_detail.json"] = {
	set = {
		{"textDesc","fontSize",35},
		{"lockPanel.textNote2","anchorPoint",{0,1}},
		{"lockPanel.textNote3","anchorPoint",{0,1}},
		{"lockPanel.textLevel","anchorPoint",{0,1}},
	},
	oneLinePos = {
		{"lockPanel.textNote3","lockPanel.textLevel",cc.p(20,0),"left"},
	}
}

config["gym_master_info.json"] = {
	oneLinePos = {
		{"title.textTitle1","title.textTitle2",cc.p(0,0),"left"},
	}
}

config["gym_badge.json"] = {
	set = {
		{"gymBtn.text","fontSize",35},
	},

}

config["gym_badge_talent.json"] = {
	set = {
		{"leftPanel.top.item", "visible", false},
		{"leftPanel.middle.item", "visible", false},
		{"rightPanel.top.item", "visible", false},
		{"rightPanel.bottom.costPanel.item", "visible", false},
	},
	oneLinePos = {
		{"leftPanel.bottomPanel.title", "leftPanel.bottomPanel.title1", cc.p(30,0), "left"},
	}
}

--徽章界面
config["gym_badge_awake.json"] = {
	set = {
		{"rightPanel.btnPanel.txt", "fontSize", 35},
		{"rightPanel.topPanel.title", "anchorPoint", {0.28,0.5}},
		{"rightPanel.topPanel.title1", "anchorPoint", {0.3,0.5}},
	},
	oneLinePos = {
		{"title", "title1",cc.p(5,0), "left"},
	}
}

config["gym_badge_choose_card.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
		{"cardItem", "visible", false},
		{"useBtn.txt", "fontSize", 40},
	},
	oneLinePos = {
		{"title","title1",cc.p(5,0),"left"},
	}
}

--道馆日志 详情
config["gym_battle_detail.json"] = {
	set = {
		{"item", "visible", false},
		{"left.textNote1","fontSize",35},
		{"left.textNote2","fontSize",35},
		{"right.textNote1","fontSize",35},
		{"right.textNote2","fontSize",35},
	},
	oneLinePos = {
		{"left.imgBg.textNote","left.imgBg.textZl",cc.p(20,0),"left"},
		{"right.imgBg.textNote","right.imgBg.textZl",cc.p(20,0),"left"},
		{"title.textTitle1","title.textTitle2",cc.p(10,0),"left"}
	}

}

-- 卡牌饰品觉醒
config["card_equip_awake.json"] = {
	set = {
		{"item", "visible", false},
		{"panel.btnAwakeAbility.txt","fontSize",35},
		{"item.name","fontSize",35},
		{"item.left","fontSize",35},
		{"item.right","fontSize",35},
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
		{"rightPanel.btnChallenge.text", "anchorPoint",{0.3,0.4}},
		{"rightPanel.hasChallenged","anchorPoint",{0.2,0.5}},
		{"rightPanel.hasChallenged","fontSize",35},
		{"rightPanel.btnPlayer.btnPlayerText","anchorPoint",{0.2,0.5}},
		{"centerPanel.escapeTip","anchorPoint",{0.7,0.5}},
	},
	oneLinePos = {
		{"leftPanel.myChallengeTimesText", "leftPanel.myChallengeTimesNum", cc.p(5, 0)},
		{"centerPanel.escapeTip", "centerPanel.escapeTime", cc.p(5, 0)},
		{"centerPanel.escapeTime", "centerPanel.escapeTip2", cc.p(5, 0)},
	},
}


--活动Boss
config["activity_boss_clearance.json"] = {
	oneLinePos = {
		{"title.textNote", "title.textNote2", cc.p(5, 0)},
	},
}

--精灵皮肤 详情
config["card_skin.json"] = {
	set = {
		{"panelCell", "visible", false},
		{"itemAttr", "visible", false},
		{"starItem", "visible", false},
		{"attrItem", "visible", false},
		{"item", "visible", false},
	},
	oneLinePos = {
		{"panelRight.panelNature.title1", "panelRight.panelNature.txtBuffObj", cc.p(5, 0)},
	},
}

config["card_skin_reward.json"] = {
	oneLinePos = {
		{"panelNature.title1", "panelNature.txtBuffObj", cc.p(5, 0)},
	},

}

return config