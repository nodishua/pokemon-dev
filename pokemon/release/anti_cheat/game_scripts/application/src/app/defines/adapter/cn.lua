
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2017 TianJi Information Technology Inc.
--
local config = {}

-- 登录
config["login.json"] = {
	dockWithScreen = {
		{"leftPanel", "left", "up"},
		{"version", "right", nil, true},
	},
	set = {
		{"midPanel.server", "visible", false},
	},
}

-- 选服
config["login_server.json"] = {
	set = {
		{"leftItem", "visible", false},
		{"item", "visible", false},
		{"subList", "visible", false},
	},
}

-- 公告
config["login_placard.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
		{"topBg", "visible", false},
		{"titleItem", "visible", false},
		{"contentItem", "visible", false},
	},
	oneLinePos = {
		{"bottomPanel.btnKnow", {"bottomPanel.tip", "bottomPanel.icon"}, cc.p(5, 0), "right"},
	},
}

config["character_select_card.json"] = {
	set = {
		{"itemCard", "visible", false},
		{"itemSkill", "visible", false},
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
	},
}

-- 战斗主界面
config["battle_craft.json"] = {
	dockWithScreen = {
		{"selfInfo", "left", "up", false},
		{"enemyInfo", "right", "up", false},
		{"selfMp", "left", "down", false},
		{"enemyMp", "right", "down", false},
	},
}

-- 战斗失败界面
config["battle_end_fail.json"] = {
	set = {
		{"advanceBtn", "visible", false},
	},
}

-- 战斗剧情界面
config["battle_story_panel.json"] = {
	set = {
		{"selectItem", "visible", false},
	},
	dockWithScreen = {
		{"skipBtn", "right", "up", false},
	}
}

-- 战斗活动副本界面
config["battle_daily_activity.json"] = {
	dockWithScreen = {
		{"item1", "left", "up", true},
		{"item2", "left", "up", true},
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
		{"rightPanel.showList", "contentSize", {1100, 300}},
	},
}

-- 恭喜获得
config["common_gain_display.json"] = {
	set = {
		{"innerList", "visible", false},
		{"item", "visible", false},
	}
}

-- 来源获得途径
config["common_gain_way.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 物品详情
config["common_buy_info.json"] = {
	set = {
		{"content.sliderPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"priceItem", "visible", false},
		{"selectItem", "visible", false},
	},
}

-- 聚宝(点金)获得展示
config["common_gain_gold_display.json"] = {
	set = {
		{"panel1", "visible", false},
		{"panel10", "visible", false},
	},
}

-- 战斗剧情界面
config["common_guide.json"] = {
	dockWithScreen = {
		{"skipBtn", "right", "up", false},
	}
}

-- 通用规则
config["common_rule.json"] = {
	set = {
		{"title", "visible", false},
		{"awardItem", "visible", false},
		{"panelChip", "visible", false},
	},
}

-- 出现捕捉精灵提示
config["common_capture_tips.json"] = {
	dockWithScreen = {
		{"imgBG", "left", "up", false},
	},
}

-- 签到
config["sign_in.json"] = {
	set = {
		{"centerPanel.subList", "visible", false},
		{"itemBox", "visible", false},
		{"itemSmall", "visible", false},
		{"itemBig", "visible", false}
	},
}

-- 背包
config["bag.json"] = {
	dockWithScreen = {
		{"leftPanel", "left"},
		{"rightPanel", "right"},
	},
	set = {
		{"leftPanel.item", "visible", false},
		{"midPanel.subList", "visible", false},
		{"midPanel.item", "visible", false},
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
	},
}

-- 邮件
config["mail.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"btnItem", "visible", false},
		{"right", "visible", false},
	},
}

-- 好友
config["friend.json"] = {
	set = {
		{"rightPanel","visible",false},
		{"item1","visible",false},
		{"item2","visible",false},
		{"leftItem","visible",false},
	}
}

-- 排行榜
config["rank.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
		{"itemFight", "visible", false},
		{"itemCollect", "visible", false},
		{"itemUnion", "visible", false},
		{"itemGateStar", "visible", false},
		{"rightPanel.topPanelFight", "visible", false},
		{"rightPanel.topPanelCollect", "visible", false},
		{"rightPanel.topPanelCraft", "visible", false},
		{"rightPanel.topPanelUnion", "visible", false},
		{"rightPanel.topPanelGateStar", "visible", false},
		{"rightPanel.bottomPanelFight", "visible", false},
		{"rightPanel.bottomPanelCollect", "visible", false},
		{"rightPanel.bottomPanelCraft", "visible", false},
		{"rightPanel.bottomPanelUnion", "visible", false},
		{"rightPanel.bottomPanelGateStar", "visible", false},
	}
}

-- 聊天
config["chat.json"] = {
	set = {
		{"item", "visible", false},
		{"btn", "visible", false},
		{"topView", "visible", false},
		{"chatPanel.bottomPanel", "visible", false},
	},
}

-- 私聊
config["chat_privataly.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
		{"item", "visible", false},
	},
}

-- 表情
config["chat_emoji.json"] = {
	set = {
		{"dot", "visible", false},
		{"btnItem", "visible", false},
		{"pagePanel", "visible", false},
		{"pagePanel.subList", "visible", false},
		{"pagePanel.item", "visible", false},
	},
}

-- 任务
config["task.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
		{"itemBox", "visible", false},
		{"itemTask", "visible", false},
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
	},
}

-- 卡牌背包
config["card_bag.json"] = {
	set = {
		{"centerPanel.subList", "visible", false},
		{"centerPanel.cardItem", "visible", false},
		{"centerPanel.fragItem", "visible", false},
	},
}

-- 卡牌背包属性筛选
config["card_bag_filter.json"] = {
	set = {
		{"filterBtn.attrListPanel.item", "visible", false},
		{"filterBtn.attrListPanel.subList", "visible", false},
		{"filterBtn.rarityListPanel.item", "visible", false},
		{"filterBtn.rarityListPanel.subList", "visible", false},
	},
}

-- 通用布阵界面下边卡牌模块
config["common_battle_card_list.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 卡牌性格
config["card_character.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
	},
}

-- 卡牌升级
config["card_upgrade.json"] = {
	set = {
		{"item", "visible", false},
		{"slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
	},
}

-- 自定义努力值
config["card_effortvalue_custom.json"] = {
	set = {
		{"slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
	},
}

-- 卡牌努力值
config["card_effortvalue.json"] = {
	set = {
		{"item", "visible", false},
		{"itemAttr", "visible", false},
		{"itemTxt", "visible", false},
	},
}

-- 卡牌饰品
config["card_equip.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 卡牌饰品升星
config["card_equip_star.json"] = {
	set = {
		{"item", "visible", false},
	},
}
-- 卡牌饰品觉醒
config["card_equip_awake.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 卡牌饰品强化
config["card_equip_strengthen.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 卡牌升星
config["card_star_changefrags.json"] = {
	set = {
		{"barPanel.bar", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"item", "visible", false},
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
		{"bottomItem", "visible", false}
	},
}

-- 关卡
config["gate.json"] = {
	set = {
		{"item", "visible", false},
		{"level", "visible", false},
		{"box", "visible", false},
		{"speLevel", "visible", false},
	},
	dockWithScreen = {
		{"leftDown", "left", "down"},
		{"btnLeft", "left"},
		{"btnRight", "right"},
		{"rightDown", "right", "down"},
		{"rightTop", "right", "up"},
	},
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
	},
}

-- 章节详情
config["gate_section_detail.json"] = {
	set = {
		{"itemText", "visible", false},
		{"roleItem", "visible", false},
		{"starItem", "visible", false},
		{"iconItem", "visible", false},
		{"leftTop.btnSave", "visible", false},
	},
}

-- 章节宝箱
config["gate_section_box.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
	},
}

-- 运营活动主界面
config["activity.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
		{"rightPanel.topPanel.iconAll", "visible", false},
	}
}

-- 月卡特权
config["activity_month_card_privilege.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 直购礼包
config["activity_direct_buy_gift.json"] = {
	set = {
		{"item", "visible", false},
		{"item.subList", "visible", false},
		{"item.item", "visible", false},
	},
}

-- 道具折扣 (折扣礼包)
config["activity_item_buy.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
	},
}

-- 任务 (等级礼包)
config["activity_general_task.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 道具兑换 (限时兑换)
config["activity_item_exchange.json"] = {
	set = {
		{"item", "visible", false},
	},
}
-- 连续充值
config["activity_recharge_gift"] = {
	set = {
		{"itemBox", "visible", false},
		{"item", "visible", false},
	},
}

-- 补领体力
config["activity_regain_stamina.json"] = {
	set = {
		{"item", "visible", false},
	},
}

config["activity_server_open.json"] = {
	set = {
		{"item", "visible", false},
		{"itemDay", "visible", false},
	},
}

config["activity_server_open_get.json"] = {
	set = {
		{"item", "visible", false},
	},
}

config["activity_first_recharge.json"] = {
	set = {
		{"btnLeft", "visible", false},
		{"btnRight", "visible", false},
		{"dot0", "visible", false},
		{"dot1", "visible", false},
	},
}

config["activity_lucky_cat.json"] = {
	set = {
		{"item", "visible", false},
		{"numItem", "visible", false},
		{"txt4", "visible", false},
		{"txtVipTips", "visible", false},
		{"iconVipTips", "visible", false},
		{'dialogPanel.vip5', "visible", false},
	},
}

config["activity_gold_lucky_cat.json"] = {
	set = {
		{"item", "visible", false},
		{"numItem", "visible", false},
		{"txt4", "visible", false},
		{"txtVipTips", "visible", false},
		{"iconVipTips", "visible", false},
		{'dialogPanel.vip5', "visible", false},
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
	}
}

--进化链
config["card_evolution.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
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
	},
}
--精灵信息
config["card_info.json"] = {
	set = {
		{"itemNature", "visible", false},
		{"item", "visible", false},
		{"skillItem", "visible", false},
		{"rightPanel.skillPanel", "visible", false},
		{"rightPanel.attributePanel", "visible", false},
		{"starItem", "visible", false}
	},
}

-- 个人信息
config["personal_info.json"] = {
	set = {
		{"rightPanel.btnShare", "visible", false},
	},
	dockWithScreen = {
		{"leftPanel", "left"},
		{"rightPanel", "right"},
	},
}

--头像和头像框
config["personal_role_logo.json"] = {
	set = {
		{"itemLogo", "visible", false},
		{"itemFrame", "visible", false},
		{"leftItem", "visible", false},
	},
}

-- 个人形象
config["personal_figure.json"] = {
	set = {
		{"itemLogo", "visible", false},
		{"itemSkill", "visible", false},
		{"addPanel.itemAttr", "visible", false},
		{"addPanel.title1", "fontSize", 46},
		{"item", "visible", false},
	},
	oneLinePos = {
		{"addPanel.title", "addPanel.title1", cc.p(10, 0), "left"},
	},
}

--技能选择
config['personal_skill_choose.json'] = {
	set = {
		{'itemSkill', "visible", false},
		{'subList', "visible", false},
	},
}

--图鉴
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
		{"center.btnSpecial", "visible", false}
	},
}

config["handbook_attadd.json"] = {
	set = {
		{"panel.innerList", "visible", false},
		{"panel.item", "visible", false},
	},
}

config["handbook_skill.json"] = {
	set = {
		{"skillItem", "visible", false},
	},
}

config["handbook_from.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
	},
}

--图鉴突破
config["handbook_break.json"] = {
	set = {
		{"item", "visible", false},
		{"btnItem", "visible", false},
	},
}

--规则
config["rule.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--竞技场
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
}

--竞技场-排名奖励
config["arena_rank_reward.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--竞技场-积分奖励
config["arena_point_reward.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
	},
}

--竞技场-战斗记录
config["arena_combat_record.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--竞技场更换形象
config["arena_head_icon.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
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

--竞技场-排行榜
config["arena_rank.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--冒险本主界面
config["adventure.json"] = {
	set = {
		{"item", "visible", false},
		{"pvpItem", "visible", false},
	},
}

--日常副本界面
config["daily_activity.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--日常副本详情界面
config["daily_activity_gate_select.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--日常副本排行界面
config["daily_activity_rank.json"] = {
	set = {
		{"item", "visible", false},
	},
}

config["card_strengthen.json"] = {
	set = {
		{"item", "visible", false},
		{"btnItem", "visible", false},
		{"starItem", "visible", false},
		{"attrItem", "visible", false},
	},
	dockWithScreen = {
		{"cardPanel", "left"},
		{"right", "right"},
	},
}

config["card_attribute.json"] = {
	set = {
		{"innerList", "visible", false},
		{"trammelItem", "visible", false},
		{"medItem", "visible", false},
		{"attrItem", "visible", false},
	},
}

config["card_skill.json"] = {
	set = {
		{"item", "visible", false},
	},
}

config["card_advance.json"] = {
	set = {
		{"item", "visible", false},
	},
}

config["card_star.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 极限属性
config["card_star_skill.json"] = {
	set = {
		{"barPanel.bar", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"item", "visible", false},
		{"selectPanel", "visible", false},
		{"item", "visible", false},
		{"cardItem", "visible", false},
		{"selectPanel","visible", false},
		{"selectPanel.subList","visible", false},
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
		{"btnReady", "left"},
	},
	scaleWithWidth = {
		{"rightDown.btnOneKeySet.textNote", nil, 270},
	},
	oneLinePos = {
		{"rightDown.textNote", "rightDown.textNum", cc.p(10, 0), "left"},
	},
}

--卡牌羁绊
config["card_fetter.json"] = {
	set = {
		{"item", "visible", false},
		{"subItem", "visible", false},
	},
}

--天赋
config["talent.json"] = {
	set = {
		{"rightPanel.subList1", "visible", false},
		{"rightPanel.subList2", "visible", false},
		{"leftPanel.item", "visible", false},
	},
}

--称号簿
config["title_book.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
		{"leftPanel.title", "visible", false},
		{"itemAttr", "visible", false},
		{"itemCondition", "visible", false}
	},
}

--抽卡主界面
config["drawcard.json"] = {
	set = {
		{"btnItem", "visible", false},
		{"item", "visible", false},
		{"cardItem", "visible", false},
		{"selfChooseCurrentUp.icon","visible",false},
	},
	dockWithScreen = {
		{"list", "left"},
		{"perview", "right"},
		{"shop", "right"},
	}
}

--抽卡显示结果界面
config["drawcard_result.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
		{"effectItem", "visible", false},
	},
}

--抽卡预览界面
config["drawcard_preview.json"] = {
	set = {
		{"item", "visible", false},
		{"roleItem", "visible", false},
		{"innerList", "visible", false},
		{"textItem", "visible", false},
	},
}

--升级界面
config["common_upgrade_notice.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--无限塔界面
config["endless_tower.json"] = {
	set = {
		{"item", "visible", false},
		{"bgItem", "visible", false},
	},
	dockWithScreen = {
		{"leftDown", "left"},
		{"rightDown", "right"},
	},
}

--无限塔-关卡详情
config["endless_tower_gate_detail.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--无限塔-通关录像
config["endless_tower_battle_video.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--无限塔-排行榜
config["endless_tower_rank.json"] = {
	set = {
		{"item", "visible", false},
		{"achievementItem", "visible", false},
	},
}

--公会主界面
config["union_main.json"] = {
	set = {
		{"item", "visible", false},
	},
	dockWithScreen = {
		{"redpacket", "right"},
		{"leftUp", "left"},
	},
}

--公会大厅
config["union_lobby.json"] = {
	dockWithScreen = {
		{"leftPanel.list", "left"},
	},
}

--公会创建主界面
config["union_join.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--公会红包主界面
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
}

--公会修炼中心界面
config["union_skill.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"title1", "title2", cc.p(10, 0)},
	},
}

--公会训练中心界面
config["union_train.json"] = {
	set = {
		{"leftItem", "visible", false},
		{"myItem", "visible", false},
		{"otherItem", "visible", false},
		{"roleItem", "visible", false},
		{"otherPanel.empty", "visible", false},
	},
}

--公会选择精灵界面
config["union_select_sprite.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--公会选择图标界面
config["union_select_logo.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--公会副本界面
config["union_gate.json"] = {
	dockWithScreen = {
		{"leftPanel", "left"},
		{"right", "right"},
	},
}

--公会关卡进度界面
config["union_gate_progress.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--公会关卡排行界面
config["union_gate_rank.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--公会关卡奖励界面
config["union_gate_reward.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--公会红包信息界面
config["union_redpack_info.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--公会捐献界面
config["union_contribute_main.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--公会捐献界面
config["union_contribute.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--携带道具背包界面
config["held_item_bag.json"] = {
	set = {
		{"innweList", "visible", false},
		{"attrInnerList", "visible", false},
		{"item", "visible", false},
		{"item1", "visible", false},
		{"roleItem", "visible", false},
	},
}

--携带道具突破详情界面
config["held_item_info.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 携带道具突破强化界面
config["held_item_advance.json"] = {
	set = {
		{"leftPanel.attrSubList", "visible", false},
		{"strengthenPanel.itemSubList", "visible", false},
		{"strengthenPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
	},
}

-- 携带道具详情
config["common_helditem_detail.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"innerList", "visible", false},
	},
}
-- 携带道具选择强化界面
config["held_item_advance_select.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--训练家
config["trainer_attr_skills.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--训练家
config["trainer_attr.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--训练家
config["trainer_success.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--训练家
config["trainer_view.json"] = {
	set = {
		{"item", "visible", false},
		{"item2", "visible", false},
	},
	dockWithScreen = {
		{"btnLeft", "left"},
		{"btnRight", "right"},
	},
}

-- 精灵继承-精灵选择
config["card_property_swap_choose.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false}
	},
}

-- 设置界面声音控制界面
config["setting_voice.json"] = {
	set = {
		{"centerPanel.itemBgVoice.slider", "capInsets", {cc.rect(11, 0, 1, 20)}},
		{"centerPanel.itemBattleVoice.slider", "capInsets", {cc.rect(11, 0, 1, 20)}},
		{"centerPanel.item", "visible", false},
	},
}

-- 设置界面常规界面
config["setting_normal.json"] = {
	set = {
		{"centerPanel.item", "visible", false},
	},
}

config["card_property_swap_view.json"] = {
	oneLinePos = {
		{"title", "title1"},
	},
	set = {
		{"leftItem", "visible", false},
		{"centerCharacter", "visible", false},
		{"centerNvalue", "visible", false},
		{"centerEffortValue", "visible", false},
		{"centerFeelValue", "visible", false},
		{"centerEffortValue.itemAttr", "visible", false},
	},
}
--卡牌详情
config["common_card_detail.json"] = {
	set = {
		{"baseCardNode.attrItem", "visible", false},
	},
}

-- 在线奖励领取
config["online_gift_gain.json"] = {
	set = {
		{"item", "visible", false},
		{"rewardPanel", "visible", false},
		{"label", "visible", false},
	},
}

config["card_nature_attr.json"] = {
	set = {
		{"item", "visible", false},
		{"curFlag", "visible", false},
	},
}

config["handbook_fetter.json"] = {
	set = {
		{"item", "visible", false},
		{"roleItem", "visible", false},
	},
}

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
		-- {"panelDecompose", "left", nil, true},
		{"right", "right", nil, true},
		{"page", "right", nil, true},
	},
}

config["rebirth_select_role.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
	},
}

config["rebirth_select_card.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
	},
}
--好感度
config["card_feel.json"] = {
	set = {
		{"item", "visible", false},
		{"attrItem", "visible", false},
		{"pageItem", "visible", false},
	},
}

config["explore_view.json"] = {
	set = {
		{"componentPanel", "visible", false},
		{"bottomPanel.item", "visible", false},
		{"mask", "visible", false},
		{"flip1","visible", false},
		{"flip2","visible", false},
		{"flip3","visible", false},
		{"flip4","visible", false},
	},
	dockWithScreen = {
		{"upRightPanel", "right"},
		{"upLeftPanel", "left"},
		{"componentPanel", "left"},
	},
	scaleWithWidth = {
		{"upLeftPanel.btnFind.txt", nil, 160},
		{"upLeftPanel.btnShop.txt", nil, 160},
		{"upLeftPanel.btnDecompose.txt", nil, 160},
		{"upLeftPanel.btnRule.txt", nil, 160},
	}
}

config["explore_component_success_view.json"] = {
	set = {
		{"item", "visible", false},
	}
}

config["explore_detail_view.json"] = {
	set = {
		{"item1", "visible", false},
	}
}

config["explore_decompose_view.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
		{"item1", "visible", false},
	}
}

config["explore_draw_item_success.json"] = {
	set = {
		{"item", "visible", false},
	}
}

--神秘商店
config["mystery_shop.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
	},
}

--背包自动出售
config["shop_sell.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--多选1礼包
config["gift_choose.json"] = {
	set = {
		{"item", "visible", false},
		{"sliderPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
	},
}

--碎片合成
config["card_fragment_compose.json"] = {
	set = {
		{"barPanel.bar", "capInsets", {cc.rect(11, 0, 1, 0)}},
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
	}
}

--随机塔-排行榜
config["random_tower_rank.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--随机塔-积分奖励
config["random_tower_point_reward.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
	},
}
--随机塔-补给buff
config["random_tower_use_buff.json"] = {
	set = {
		{"item", "visible", false},
	},
}
--随机塔-随机事件
config["random_tower_select_event.json"] = {
	set = {
		{"item", "visible", false},
	},
}
--随机塔-查看加成
config["random_tower_look_buff.json"] = {
	set = {
		{"centerItem", "visible", false},
		{"buffItem", "visible", false},
		{"rightItem", "visible", false},
	},
}
--随机塔-事件奖励
config["random_tower_event_reward.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--随机塔-直达高层
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
	},
}

-- 限时PVP
config["craft_main.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 限时PVP布阵
config["craft_battle.json"] = {
	set = {
		{"item", "visible", false},
		{"imgStar", "visible", false},
		{"roleItem", "visible", false},
	},
}

-- 限时PVP 排行榜
config["craft_rank.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"rankPanel.rankItem", "visible", false},
		{"rewardPanel.rewardItem", "visible", false},
	},
	oneLinePos = {
		{"topPanel.title","topPanel.subTitle"}
	},
}

-- 限时PVP 押注
config["craft_bet.json"] = {
	set = {
		{"betPanel.betItem", "visible", false},
	},
}

-- 限时PVP我的赛程
config["craft_schedule.json"] = {
	set = {
		{"item", "visible", false},
		{"roleItem", "visible", false},
	},
	dockWithScreen = {
		{"btnMainSchedule", "left"},
		{"btnMyTeam", "left"},
		{"btns", "right"},
		{"topLeftPanel", "left"},
		{"leftDown","left"}
	},
}

-- 限时PVP参赛阵容（敌人）
config["craft_battle_enemy.json"] = {
	set = {
		{"imgStar", "visible", false},
	},
}

-- 元素挑战
config["clone_battle_city.json"] = {
	dockWithScreen = {
		{"btnRule", "right", nil, false},
		{"btnShowList", "right", nil, false},
	},
}


-- 元素挑战 主界面
config["clone_battle_spr_show.json"] = {
	set = {
		{"mainPanel.natureItem", "visible", false},
		{"mainPanel.showItem", "visible", false},
	},
}

-- 元素挑战 精灵展示界面
config["clone_battle_spr_show.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 元素挑战 房间界面
config["clone_battle_room.json"] = {
	set = {
		{"rightPanel.centerPanel.btnJoinItem", "visible", false},
		{"rightPanel.centerPanel.normalItem", "visible", false},
		{"rightPanel.centerPanel.mainItem", "visible", false},
	},
	dockWithScreen = {
		{"leftPanel", "left"},
		{"rightPanel", "right"},
	},
}

config["clone_battle_sprite.json"] = {
	set = {
		{"item", "visible", false},
	}
}

config["clone_battle_friend_invite.json"] = {
	set = {
		{"item", "visible", false},
	}
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
		{'shopPanel.item', "visible", false},
	},
	oneLinePos = {
		{"rewardPanel.txtNode","rewardPanel.endTime"},
		{"taskPanel.iconTitlePanel","taskPanel.iconTitle3",cc.p(5,30)},
	}
}

-- 显示通行证 购买界面
config["activity_passport_buy.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 显示通行证 主界面
config["activity_passport_buy_exp.json"] = {
	set = {
		{"item", "visible", false},
		{"itemList", "visible", false},
	},
}

-- 显示通行证 主界面
config["grow_guide.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"item2", "visible", false},
	},
}

-- 限时直购礼包
config["activity_limit_buy_gift.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
	}
}

-- 限时神兽
config["activity_limit_sprite.json"] = {
	set = {
		{"bottomPanel.item", "visible", false},
		{"rightPanel.rankItem", "visible", false},
		{"rightPanel.scoreItem", "visible", false},
	}
}

-- 新手活动
config["activity_new_player_welfare.json"] = {
	set = {
		{"item", "visible", false},
		{"iconItem", "visible", false},
	}
}

-- 七天登陆
config["activity_seven_day_login.json"] = {
	set = {
		{"item", "visible", false},
	}
}
-- 七天登陆(春节)
config["activity_spring_festival.json"] = {
	set = {
		{"item", "visible", false},
	}
}

-- 精灵投资
config["activity_weekly_card.json"] = {
	set = {
		{"item", "visible", false},
	}
}

-- 限时捕捉界面
config["capture_limit.json"] = {
	dockWithScreen = {
		{"leftDownPanel", "left", "down", false},
		{"rightDownPanel", "right", "down", false},
	},
	set = {
		{"panelSprite", "visible", false},
	}
}

--派遣主界面
config["dispatch_task.json"] = {
	set = {
		{"item", "visible", false},
		{"attrItem", "visible", false},
	},
}

--成就主界面
config["achievement_main.json"] = {
	set = {
		{"item", "visible", false},
		{"btn", "visible", false},
		{"infoItem", "visible", false},
	},
}

--充值大转盘
config["activity_recharge_wheel.json"] = {
	set = {
		{"showItem", "visible", false},
	},
}

-- 活跃夺宝
config["activity_liveness_wheel.json"] = {
	set = {
		{"taskItem", "visible", false},
		{"selected", "visible", false},
	},
}

-- 组队光环弹窗
config["card_embattle_attr_dialog.json"] = {
	set = {
		{"item", "visible", false},
		{"textItem1", "visible", false},
		{"subList", "visible", false},
		{"bottomItem", "visible", false},
		{"textItem2", "visible", false},
	},
}

-- 限时PVP小组赛主赛程界面
config["main_schedule.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 阵容推荐界面
config["battle_recommend.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 阵容详情界面
config["battle_detail.json"] = {
	set = {
		{"cardItem", "visible", false},
	},
}

-- 公会许愿主界面
config["union_frag_donate.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"donateTimes", "donateTimesNote", cc.p(10, 0), "right"},
		{"item.haveNote", "item.haveNum", cc.p(10, 0)},
	},
}
-- 许愿界面
config["union_frag_donate_wish.json"] = {
	set = {
		{"item", "visible", false},
	},
	oneLinePos = {
		{"textNumNote", "textNum", cc.p(10, 0), "left"},
	},
}
-- 记录界面
config["union_frag_donate_record.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 公会战斗布置界面
config["union_fight_assign.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"item2", "visible", false},
		{"innerList", "visible", false},
	},
}

-- 跨服石英大会主界面
config["cross_craft.json"] = {
	dockWithScreen = {
		{"leftBtn1", "left", "down"},
		{"leftBtn2", "left", "down"},
		{"rightBtn", "right", "down"},
	},
	set = {
		{"signupPanel.item", "visible", false},
		{"signupPanel.subList", "visible", false},
	}
}

-- 跨服石英大会布阵界面
config["cross_craft_embattle.json"] = {
	set = {
		{"up.special", "visible", false},
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
	}
}

-- 跨服石英大会主赛程
config["cross_craft_myschedule.json"] = {
	set = {
		{"item", "visible", false},
	},
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
	}
}

-- 跨服石英大会下注
config["cross_craft_bet.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"betPanel.betItem", "visible", false},
	},
}

-- 跨服石英大会排行奖励
config["cross_craft_rank.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"rankPanel.rankItem", "visible", false},
		{"rewardPanel.rewardItem", "visible", false},
	},
}

-- 符石镶嵌一键强化
config['gem_onekey_strengthen.json'] = {
	set = {
		{'sliderPanel.slider', "capInsets", {cc.rect(11, 0, 1, 1)}}
	}
}
--符石属性展示
config["gem_add_effect.json"] = {
	set = {
		{"item2", "visible", false},
		{"harm", "visible", false},
		{"effect", "visible", false},
		{"suitItem", "visible", false},
		{"noItem", "visible", false},
	},
}

--竞技场一键5次
config['arena_pass_reward.json'] = {
	set = {
		{'item', "visible", false},
	}
}

-- 世界Boss
config['activity_world_boss.json'] = {
	set = {
		{'centerPanel.skillItem', "visible", false},
	},
}

-- world_boss-排行榜
config['activity_world_boss_reward.json'] = {
	set = {
		{'leftPanel.tabItem', "visible", false},
		{'panel.rankItem', "visible", false},
	},
}

-- world_boss-排行榜
config['activity_world_boss_rank.json'] = {
	set = {
		{'leftPanel.tabItem', "visible", false},
		{'trainerPanel.rankItem', "visible", false},
		{'unionPanel.rankItem', "visible", false},
		{'rightPanel', "visible", false},
	},
}

-- 跨服竞技场主界面
config['cross_arena.json'] = {
	set = {
		{'serverPanel.subList', "visible", false},
		{'serverPanel.item', "visible", false},
	},
	dockWithScreen = {
		{"downPanel", "left", "down", false},
	}
}

-- 跨服竞技场挑战界面
config['cross_arena_enemy.json'] = {
	dockWithScreen = {
		{"rightDownPanel", "right", "down", false},
	}
}

--竞技场个人信息界面
config["cross_arena_personal_info.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--竞技场更换形象
config["cross_arena_head_icon.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
	},
}

-- cross_arena-段位奖励
config['cross_arena_stage_reward.json'] = {
	set = {
		{'rewardPanel.rankItem', "visible", false},
		{'rewardPanel1.rankItem', "visible", false},
		{'rewardPanel2.rankItem', "visible", false},
		{'rewardPanel3.rankItem', "visible", false},
		{'leftPanel.tabItem', "visible", false},
	},
}

-- cross_arena-排行榜
config['cross_arena_rank.json'] = {
	set = {
		{'rankPanel.rankItem', "visible", false},
	},
}

-- cross_arena-战斗回访
config['cross_arena_combat_record.json'] = {
	set = {
		{'myPanel.item', "visible", false},
		{'goodPanel.item', "visible", false},
		{'leftPanel.tabItem', "visible", false},
	},
}

-- cross_arena-战斗信息
config['cross_arena_record_info.json'] = {
	set = {
		{'item', "visible", false},
	},
}

-- cross_arena-个人信息
config['cross_arena_personal_info.json'] = {
	set = {
		{'item', "visible", false},
	},
}

-- 粽子背包
config["activity_zongzi_bag.json"] = {
	set = {
		{"right.sliderPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"item", "visible", false},
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

-- 钓鱼成功界面
config['fishing_result.json'] = {
	set = {
		{'fishItem.imgNew', "visible", false},
		{'score1', "visible", false},
		{'score2', "visible", false},
	},
}

-- 鱼类详情界面
config['common_fish_detail.json'] = {
	set = {
		{'baseNode.lockPanel', "visible", false},
	},
}

-- 钓鱼背包界面
config['fishing_bag.json'] = {
	set = {
		{'btn', "visible", false},
		{'center.item', "visible", false},
		{'rightBait', "visible", false},
		{'rightPartner', "visible", false},
	},
}

-- 钓鱼等级界面
config['fishing_level.json'] = {
	set = {
		{'left.item', "visible", false},
		{'right.now.attr.item', "visible", false},
		{'right.now.fish.item', "visible", false},
		{"left.item.bar", "capInsets", {cc.rect(11, 10, 1, 1)}},
	},
}

-- 钓鱼大赛排行榜界面
config['fishing_rank.json'] = {
	set = {
		{'right.rank.item', "visible", false},
		{'left.item', "visible", false},
		{'right.reward.server.item', "visible", false},
		{'right.reward.reward.item', "visible", false},
	},
}

-- 钓鱼捕捞界面
config['fishing_award.json'] = {
	set = {
		{"point.bar", "capInsets", {cc.rect(11, 10, 1, 1)}},
		{"point.barBg", "capInsets", {cc.rect(11, 10, 1, 1)}},
	},
}

--超进化主界面
config["card_mega.json"] = {
	dockWithScreen = {
		{"list", "left"},
		{"listBg", "left"},
		{"rightPanel", "right"},
		{"panel", "right"},
		{"btn", "right"},
		{"titlePanel", "right"},
	},
	set = {
		{'item', "visible", false},
		{'itemPanel.starItem', "visible", false},
		{'itemPanel.attrItem', "visible", false},
		{'rightPanel.item', "visible", false},
	},
}

--超进化精灵选择
config["card_mega_choose_card.json"] = {
	set = {
		{"item", "visible", false},
		{"innerList", "visible", false},
	},
}

--超进化中的转化
config["card_mega_debris.json"] = {
	set = {
		{"sliderPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"item", "visible", false},
	},
}

--精灵评论
config["card_comment.json"] = {
	set = {
		{'center.pageItem', "visible", false},
		{'right.item', "visible", false},
		{'right.item.bottom.btnLike.select', "visible", false},
		{'right.item.bottom.btnDislike.select', "visible", false},
		{'right.noComment', "visible", false},
	},
	dockWithScreen = {
		{"left", "left"},
		{"right", "right"},
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
}

-- 实时匹配排行榜
config["online_fight_rank.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"item", "visible", false},
	},
}

-- 实时匹配奖励
config["online_fight_reward.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"item", "visible", false},
	},
}

-- 实时匹配战斗记录
config["online_fight_record.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"tabItem", "visible", false},
		{"item1", "visible", false},
		{"item2", "visible", false},
	},
}

-- 实时匹配战斗记录详情
config["online_fight_record_info.json"] = {
	set = {
		{"item", "visible", false},
	},
}
--实时匹配
config["online_fight.json"] = {
	set = {
		{"mainPanel.rightPanel.unlimitedPanel.item", "visible", false},
	},
}

-- 实时匹配战斗记录
config["online_fight_limited_embattle.json"] = {
	dockWithScreen = {
		{"leftPanel", "left"},
		{"rightPanel", "right"},
	},
}

-- 实时匹配ban选界面
config["online_fight_ban_embattle.json"] = {
	dockWithScreen = {
		{"btnClose", "left", "up", true},
	},
}

-- 道馆主界面
config["gym_challenge.json"] = {
	dockWithScreen = {
		{"rightDownPanel", "right", "up", false},
		{"rightTopPanel", "right", "down",false},
		{"btnLog", "left", "down", false},
	},
}

config["gym_npc_info.json"] = {
	set = {
		{"imgBG.attrItem", "visible", false},
	},
}


config["gym_gate_detail.json"] = {
	set = {
		{"roleItem", "visible", false},
		{"iconItem", "visible", false},
	},
}
--徽章界面
config["gym_badge_awake.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
	},
}

config["gym_badge_choose_card.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
		{"cardItem", "visible", false},
	},
}

config["gym_badge_guard.json"] = {
	set = {
		{"item1", "visible", false},
		{"item", "visible", false},
		{"subList", "visible", false},
	},
}

config["gym_badge_talent.json"] = {
	set = {
		{"leftPanel.top.item", "visible", false},
		{"leftPanel.middle.item", "visible", false},
		{"rightPanel.top.item", "visible", false},
		{"rightPanel.bottom.costPanel.item", "visible", false},
	},
}
--幸运乐翻天
config["activity_flip_card.json"] = {
	set = {
		{"leftPanel.item", "visible",false},
		{"leftPanel.list2", "visible",false},
		{"rightPanel.itemTask", "visible", false},
		{"rightPanel.itemHX", "visible", false}
	}
}

config["activity_quality_exchange_fragment.json"] = {
	set = {
		{"sliderPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
	},
}

config["activity_quality_exchange_helditem_select.json"] = {
	set = {
		{"item", "visible", false}
	},
}

-- 训练家重聚主界面
config["reunion.json"] = {
	set = {
		{"leftPanel.item", "visible", false},
	},
}

-- 训练家重聚签到
config["reunion_sign.json"] = {
	set = {
		{"item", "visible", false},
		{"item.subList", "visible", false},
		{"item.item", "visible", false},
	},
}

config["reunion_bind.json"] = {
	set = {
		{"rightPanel.receiveBtn", "visible", false},
	},
}

-- 训练家重聚 好友邀请
config["reunion_invite.json"] = {
	set = {
		{"item", "visible", false},
		{"leftItem", "visible", false},
	},
}

config["gem_preview.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
		{"item2", "visible", false},
		{"item21", "visible", false},
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
	},
}

--活动Boss
config["double_11_lottery.json"] = {
	set = {
		{"leftItem", "visible", false},
		{"rightPanel1.list2", "visible", false},
		{"rightPanel1.item", "visible", false},
		{"rightPanel2.item", "visible", false},
	},
}

--双11商店
config["double11_shop.json"] = {
	set = {
		{"singlePanel.item", "visible", false},
		{"leftPanel.item", "visible", false},
		{"bagPanel.item", "visible", false},
	},
}

--礼券商店
config["coupon_shop.json"] = {
	set = {
		{"singlePanel.item", "visible", false},
		{"leftPanel", "visible", false},
	},
}

--夏日商店
config["summer_shop.json"] = {
	set = {
		{"singlePanel.item", "visible", false},
	},
}

-- 队伍预设
config["card_embattle_ready.json"] = {
	set = {
		{"item", "visible", false},
		{"item.node", "visible", false},
	},
}

--道馆日志
config["gym_log.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--道馆日志 详情
config["gym_battle_detail.json"] = {
	set = {
		{"item", "visible", false},
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
}


--精灵皮肤 详情
config["card_skin_reward.json"] = {
	set = {
		{"item", "visible", false},
		{"itemAttr", "visible", false},
	},
}

--堆雪人活动
config["activity_snowman.json"] = {
	set = {
		{"leftPanel.mainItem", "visible", false},
		{"leftPanel.subPanel.subItem", "visible", false},
	},
}
config["activity_snowman_reward.json"] = {
	set = {
		{"item", "visible", false},
		{"item1", "visible", false},
	},
}
--丢雪球排行榜
config["snow_ball_rank.json"] = {
	oneLinePos = {
		{"title.txt", "title.txt1"},
	},
	set = {
		{"right.rank.item", "visible", false},
	},
}

--丢雪球奖励
config["snow_ball_reward.json"] = {
	oneLinePos = {
		{"topPanel.txtNode", "topPanel.txtNode1"},
	},
	set = {
		{"rewardPanel1.rankItem", "visible", false},
		{"rewardPanel2.rankItem", "visible", false},
		{"leftPanel.tabItem", "visible", false},
	},
}


-- 跨服资源战预设结算界面
config["cross_mine.json"] = {
	set = {
		{"serverPanel.item", "visible", false},
		{"overPanel.item", "visible", false},
		{"overPanel.item.vip", "visible", false},
		{"overPanel.rightPanel.item", "visible", false},
	},
	dockWithScreen = {
		{"viewPanel", "left", nil, false},
		{"downPanel", "right", "down", false},
	},
	oneLinePos = {
		{"noServerPanel.img1", "noServerPanel.label", cc.p(5, 0)},
		{"noServerPanel.label", "noServerPanel.img2", cc.p(5, 0)},
	},
}

-- 跨服资源战街区
config["cross_mine_street.json"] = {
	set = {
		{"normalItem", "visible", false},
		{"npcItem", "visible", false},
		{"leftPanel.buffPanel.item", "visible", false},
	},
}

-- 跨服资源战服务器排行榜
config["cross_mine_server_rank.json"] = {
	set = {
		{"rankPanel.item", "visible", false},
	},
}

--跨服资源战排行榜
config["cross_mine_rank.json"] = {
	set = {
		{"item", "visible", false},
		{"leftPanel.tabItem", "visible", false},
	},
}

--跨服资源战祝福
config["cross_mine_wish.json"] = {
	set = {
		{"item1", "visible", false},
		{"item2", "visible", false},
		{"leftPanel.tabItem", "visible", false},
	},
}

--跨服资源战战报
config["cross_mine_combat_record.json"] = {
	set = {
		{"myPanel.item", "visible", false},
		{"goodPanel.item", "visible", false},
		{"leftPanel.tabItem", "visible", false},
	},
}

-- 跨服资源战boss界面
config["cross_mine_boss_challenge.json"] = {
	set = {
		{"buffItem", "visible", false},
		{"rewardItem", "visible", false},
		{"rankItem", "visible", false},
	},
}

-- 跨服资源战抢夺界面
config["cross_mine_lineup_adjust.json"] = {
	set = {
		{"panelBuff", "visible", false},
	},
}

-- 跨服资源战战报子信息界面
config["cross_mine_record_info.json"] = {
	set = {
		{"item", "visible", false},
	},
}

--精灵问答答题界面
config["union_answer_problem.json"] = {
	set = {
		{"panel1.item", "visible", false},
		{"panel2.item", "visible", false},
		{"panel3.item", "visible", false},
	},
}

--精灵问答答题界面
config["union_answer_rank.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"item", "visible", false},
	},
}

--精灵问答主界面
config["union_answer.json"] = {
	set = {
		{"topPanel.item", "visible", false},
	},
}

--翻拍集福直接面
config["activity_new_year_flip_card.json"] = {
	set = {
		{"leftPanel.list2", "visible", false},
		{"leftPanel.item", "visible", false},
		{"rightPanel.itemTask", "visible", false},
	},
}

--摩天高楼界面
config["sky_scraper_rank.json"] = {
	set = {
		{"right.rank.item", "visible", false},
	},
}

config["sky_scraper_reward.json"] = {
	set = {
		{"rightPanel.tabItem", "visible", false},
		{"rightPanel.centerItem", "visible", false},
	},
}

-- 每日小助手
config["daily_assistant.json"] = {
	set = {
		{"item", "visible", false},
		{"tabItem", "visible", false},
		{"selectSuitItem", "visible", false},
	},
}

-- 小助手公会捐献界面
config["daily_assistant_union_contribute.json"] = {
	set = {
		{"item", "visible", false},
	},
}
-- 小助手钓鱼场景选择界面
config["daily_assistant_fishing_select.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
	},
}

--玩法通行证等级购买
config["activity_game_passport_buy_level.json"] = {
	set = {
		{"barPanel.bar", "capInsets", {cc.rect(11, 0, 1, 0)}},
		{"item", "visible", false},
		{"subList", "visible", false},
	},
}

--玩法通行证等级
config["activity_game_passport.json"] = {
	set = {
		{"rewardItem", "visible", false},
	},
}

--玩法通行证购买
config["activity_game_passport_buy.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
	},
}

--登录通行证
config["activity_record_passport.json"] = {
	set = {
		{"rewardItem", "visible", false},
	},
}

-- 走格子
config['grid_walk.json'] = {
	set = {
		{'item', "visible", false},
		{'item.jump', "visible", false},
		{'item1', "visible", false},
		{'showDicePanel', "visible", false},
		{'touchPanel', "visible", false},
		{'tipPanel', "visible", false},
		{'rightPanel.diceInfo', "visible", false},
		{'treasuresPanel', "visible", false},
		{'itemPanel', "visible", false},
		{'mapPanel.mapTouchClose', "visible", false},
		{'mapPanel.eventInfo', "visible", false},
	},
	dockWithScreen = {
		{"rightPanel", "right", nil, false},
		{"leftPanel", "left", nil, false},
		{"LeftDownPanel", "left", "down", false},
	},
}

-- 任务
config['grid_walk_task.json'] = {
	set = {
		{'item', "visible", false},
		{'tabItem', "visible", false},
	},
}

-- 背包
config['grid_walk_bag.json'] = {
	set = {
		{'item', "visible", false},
		{'bgPanel.empty', "visible", false},
	},
	dockWithScreen = {
		{"bgPanel", "left", "down", false},
	},
}

-- 赛马排行榜
config["horse_race_rank.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 赛马排名奖励
config["horse_race_point_reward.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 赛马押注奖励
config["horse_race_bet.json"] = {
	set = {
		{"player", "visible", false},
	},
}
-- 赛马主界面
config["horse_race_main.json"] = {
	dockWithScreen = {
		{"leftPanel", "left", "down", true },
		{"rightPanel", "right", "down", true},
	},
	set = {
		{"player", "visible", false},
		{"ruleRankTitle", "visible", false},
		{"ruleRankItem", "visible", false},
	},
}
-- 赛马主界面
config["horse_race_match.json"] = {
	set = {
		{"name", "visible", false},
	},
}
-- 赛马回放
config["horse_race_record.json"] = {
	set = {
		{"rankPanel.recordItem", "visible", false},
		{"rankPanel.recordItem.horseItem", "visible", false},
	},
}

-- 勇者挑战排行榜
config["activity_brave_challenge_rank.json"] = {
	set = {
		{"content.rank.item", "visible", false},
	}
}
-- 勇者挑战勋章
config["activity_brave_challenge_badge.json"] = {
	set = {
		{"iconPanel", "visible", false},
		{"item", "visible", false},
	}
}
-- 勇者挑战选择勋章
config["activity_brave_challenge_select_badge.json"] = {
	set = {
		{"normal", "visible", false},
		{"rare", "visible", false},
		{"forever", "visible", false},
	}
}
-- 勇者挑战排行榜
config["activity_brave_challenge_rank_detail.json"] = {
	set = {
		{"baseNode.item", "visible", false},
	}
}
-- 勇者挑战成就
config["activity_brave_challenge_achievement.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"rankItem", "visible", false},
	}
}

-- 派遣活动
config["activity_dispatch_main.json"] = {
	set = {
		{"item", "visible", false},
	},
	dockWithScreen = {
		{"leftDownPanel", "left", "down"},
	},
}

-- 派遣活动 派遣精灵界面
config["activity_dispatch_sprite_select.json"] = {
	set = {
		{"leftPanel.subList", "visible", false},
		{"item", "visible", false},
		{"imgExtra", "visible", false},
		{"attrItem", "visible", false},
	},
}

-- 派遣活动 任务界面
config["activity_dispatch_task.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"rankItem", "visible", false},
	},
}

-- 尊享限定
config["activity_exclusive_limit.json"] = {
	set = {
		{"item","visible",false},
		{"iconItem","visible",false},
	},
}
-- z觉醒主界面
config["zawake.json"] = {
	dockWithScreen = {
		{"bgMap", "left", nil, true},
		{"leftPanel", "left", nil, true},
		{"rightPanel", "right", nil, true},
	},
}

-- z觉醒一键重置界面
config["zawake_reset.json"] = {
	set = {
		{"innerList", "visible", false},
		{"item", "visible", false},
	}
}

-- z觉醒觉醒之力界面
config["zawake_force.json"] = {
	set = {
		{"leftInnerList", "visible", false},
		{"leftItem", "visible", false},
		{"item", "visible", false},
	},
}

-- z觉醒精灵选择界面
config["zawake_choose_card.json"] = {
	set = {
		{"innerList", "visible", false},
		{"item", "visible", false},
		{"chooseItem", "visible", false},
	}
}

-- z觉醒阶段解锁条件界面
config["zawake_unlock_tips.json"] = {
	set = {
		{"item", "visible", false},
	}
}

-- z觉醒觉醒培养界面
config["zawake_stage.json"] = {
	set = {
		{"rightPanel.effectItem", "visible", false},
		{"rightPanel.effectInnerList", "visible", false},
		{"rightPanel.activateItem", "visible", false},
		{"rightPanel.costItem", "visible", false},
		{"rightPanel.effectPanel", "visible", false},
		{"rightPanel.skillPanel", "visible", false},
		{"rightPanel.activatePanel", "visible", false},
		{"rightPanel.costPanel", "visible", false},
	},
	oneLinePos = {
		{"rightPanel.effectPanel.titlePanel.title", "rightPanel.effectPanel.titlePanel.txt", cc.p(10, 0)},
	},
}

-- z觉醒觉醒成功界面
config["zawake_awake_success.json"] = {
	set = {
		{"innerList", "visible", false},
		{"item", "visible", false},
	}
}

-- z觉醒预览界面
config["zawake_preview.json"] = {
	set = {
		{"item", "visible", false},
	}
}

-- z觉醒碎片兑换界面
config["zawake_debris.json"] = {
	set = {
		{"barPanel.bar", "capInsets", {cc.rect(11, 0, 1, 1)}},
		{"item", "visible", false},
		{"priceItem", "visible", false},
	},
}
-- z觉醒碎片选择界面
config["zawake_choose_frag.json"] = {
	set = {
		{"innerList", "visible", false},
		{"item", "visible", false},
	},
}

-- 学习芯片
config["card_chip.json"] = {
	set = {
		{"panel.baseAttrPanel.item", "visible", false},
		{"panel.baseAttrPanel.subList", "visible", false},
		{"panel.suitAttrPanel.item", "visible", false},
	},
}

-- 学习芯片背包
config["chip_bag.json"] = {
	set = {
		{"left.posItem", "visible", false},
		{"left.item", "visible", false},
		{"left.subList", "visible", false},
		{"right.baseAttrPanel.item", "visible", false},
		{"right.baseAttrPanel.subList", "visible", false},
		{"right.suitAttrPanel.item", "visible", false},
		{"suitFilterPanel.panel.item", "visible", false},
		{"suitFilterPanel.panel.subList", "visible", false},
		{"attrFilterPanel.panel.item", "visible", false},
		{"attrFilterPanel.panel.subList", "visible", false},
	},
}

-- 学习芯片背包详情
config["chip_detail.json"] = {
	set = {
		{"panel.attrItem", "visible", false},
		{"panel.lineItem", "visible", false},
		{"panel.suitItem", "visible", false},
	},
}

-- 学习芯片背包详情
config["chip_select_sprite.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
	},
}

-- 学习芯片强化洗练
config["chip_advance.json"] = {
	set = {
		{"tabItem", "visible", false},
		{"leftPanel.attrPanel.attrItem", "visible", false},
		{"leftPanel.attrPanel.lineItem", "visible", false},
		{"advancePanel.attrItem", "visible", false},
		{"advancePanel.lineItem", "visible", false},
		{"strengthenPanel.item", "visible", false},
		{"strengthenPanel.subList", "visible", false},
		{"strengthenPanel.quickSelectPanel.item", "visible", false},
		{"panelRule", "visible", false},
	},
}

-- 学习芯片方案
config["chip_plan.json"] = {
	set = {
		{"left.posItem", "visible", false},
		{"left.item", "visible", false},
		{"left.subList", "visible", false},
		{"leftPlan.item", "visible", false},
		{"leftPlan.subList", "visible", false},
		{"right.baseAttrPanel.item", "visible", false},
		{"right.baseAttrPanel.subList", "visible", false},
		{"right.suitAttrPanel.item", "visible", false},
		{"suitFilterPanel.panel.item", "visible", false},
		{"suitFilterPanel.panel.subList", "visible", false},
		{"attrFilterPanel.panel.item", "visible", false},
		{"attrFilterPanel.panel.subList", "visible", false},
		{"planSuitFilterPanel.panel.item", "visible", false},
		{"planSuitFilterPanel.panel.subList", "visible", false},
	},
}

-- 芯片道具详情
config["chip_item_details.json"] = {
	set = {
		{"panel.sliderPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
	},
}


-- 狩猎地带线路界面
config["hunting_route.json"] = {
	set = {
		{"coverProPanel.prograssPanel.proPanel2", "visible", false},
		{"coverProPanel.prograssPanel.proPanel3", "visible", false},
		{"buffPanel.item", "visible", false},
	},
	dockWithScreen = {
		{"buffPanel", "left", "down", true },
		{"rightBottomPanel", "right", "down", true},
	},
}

-- 狩猎地带主界面
config["hunting.json"] = {
	dockWithScreen = {
		{"leftBottomPanel", "left", "down", true },
	},
}

-- 狩猎地带buff选择界面
config["hunting_select_buff.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 狩猎地带救援选择界面
config["hunting_supply.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 狩猎地带治疗复活界面
config["hunting_supply_detail.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 狩猎地带关卡信息界面
config["hunting_gate_detail.json"] = {
	set = {
		{"enemyPanel.item", "visible", false},
	},
}

-- 芯片通用展示详情界面
config["common_chip_details.json"] = {
	set = {
		{"baseNode.panel.attrPanel", "visible", false},
		{"baseNode.panel.linePanel", "visible", false},
		{"baseNode.panel.suitPanel", "visible", false},
	},
}

-- 芯片基础属性界面
config["chip_base_attr.json"] = {
	set = {
		{"item", "visible", false},
		{"item01", "visible", false},
		{"item02", "visible", false},
		{"item03", "visible", false},
	},
}

-- 芯片概率预览界面
config["chip_rate_preview.json"] = {
	set = {
		{"item", "visible", false},
		{"subTitle", "visible", false},
		{"listLine", "visible", false},
		{"listLine2", "visible", false},
	},
}

-- 芯片抽取结果
config["chip_result.json"] = {
	set = {
		{"item", "visible", false},
		{"subList", "visible", false},
	},
}

-- 芯片套装选择界面
config["chip_select_suit.json"] = {
	set = {
		{"item02", "visible", false},
		{"item01", "visible", false},
	},
}

-- 芯片套装属性展示
config["chip_suit_attr.json"] = {
	set = {
		{"item01", "visible", false},
	},
}


-- 芯片套装预览界面
config["chip_suit_preview.json"] = {
	set = {
		{"item", "visible", false},
		{"suit1", "visible", false},
		{"suitList2", "visible", false},
	},
}

-- 芯片套装预览界面
config["chip_draw.json"] = {
	dockWithScreen = {
		{"panelUpRight", "right", "up", false},
		{"panelMidRight", "right", nil, true},
	},
}

-- 学习芯片装备存在界面提示
config["chip_plan_equip_tip.json"] = {
	set = {
		{"item", "visible", false},
	},
}

-- 狩猎地带事件选择界面
config["hunting_select_event.json"] = {
	set = {
		{"item","visible",false},
	}
}

--
config["common_box_detail.json"] = {
	set = {
		{"content", "positionY", {868}},
		{"list", "positionY", {590}},
	}
}

config["activity_zongzi_select.json"] = {
	set = {
		{"item","visible",false},
		{"sliderPanel.slider", "capInsets", {cc.rect(11, 0, 1, 1)}},
	}
}

config["drawcard_property_choose.json"] = {
	set = {
		{"subList","visible",false},
		{"item","visible",false},
		{"icon","visible",false},
		{"subList2","visible",false},
	}
}

config["drawcard_property_detail.json"] = {
	set = {
		{"icon","visible",false},
		{"subList","visible",false},
	}
}

-- 夏日挑战
config["summer_challenge.json"] = {
	dockWithScreen = {
		{"leftPanel", "left", "down", true},
		{"rightTimePanel", "right", "up", true},
	},
}

--沙滩刨冰
config["beach_ice_view.json"] = {
	set = {
		{"demandPanel.item","visible",false},
	},
	dockWithScreen = {
		{"leftDownPanel", "left", "down", true},
		{"huodongTimePanel", "right", "up", true},
	},
}

config["beach_ice_check.json"] = {
	set = {
		{"item","visible",false},
	}
}

config["beach_ice_rank.json"] = {
	set = {
		{"right.rank.item","visible",false},
	}
}
--排球排行榜
config["volleyball_rank.json"] = {
	oneLinePos = {
		{"title.txt", "title.txt1"},
	},
	set = {
		{"right.rank.item", "visible", false},
	},
}

--排球奖励
config["volleyball_reward.json"] = {
	oneLinePos = {
		{"topPanel.txtNode", "topPanel.txtNode1"},
	},
	set = {
		{"rewardPanel1.rankItem", "visible", false},
		{"rewardPanel2.rankItem", "visible", false},
		{"leftPanel.tabItem", "visible", false},
	},
}

--排球主界面
config["volleyball_main.json"] = {
	dockWithScreen = {
		{"leftPanel", "left", "down", true},
		{"textTipTime", "right", "up", true},
	},
	set = {
		{"ruleItem", "visible", false},
	}
}

--排球玩法界面
config["volleyball_game.json"] = {
	dockWithScreen = {
		{"movePanel", "left", "down", true},
	},
}

--选择精灵
config["activity_brave_challenge_view_select_card.json"] = {
	set = {
		{"selectItem", "visible", false},
		{"starItem", "visible", false},
	}
}

-- 主界面
config["activity_brave_challenge_gate.json"] = {
	set = {
		{"itemGate", "visible", false},
		{"item01", "visible", false},
	}
}

--奖励
config["activity_brave_challenge_gain_achievement.json"] = {
	set = {
		{"item", "visible", false},
	}
}

-- 中秋奖励
config["activity_midautumn_task.json"] = {
	set = {
		{"rankItem", "visible", false},
		{"leftPanel.tabItem", "visible", false},
		{"infoItem", "visible", false},
	}
}
-- 中秋主界面
config["activity_midautumn_draw.json"] = {
	dockWithScreen = {
		{"leftPanel", "left", "down", true},
		{"rightPanel", "right", "down", true},
		{"endTime", "right", "up", true},
	},
}

-- 跨服工会战
config["cross_union_fight_record.json"] = {
	set = {
		{"leftPanel.tabItem", "visible", false},
		{"goodPanel.item", "visible", false},
	}
}

config["cross_union_fight_battle.json"] = {
	dockWithScreen = {
		{"procList", "left", nil, true},
	},
}

-- 定制礼包界面
config["activity_customize_gift.json"] = {
	set = {
		{"iconItem", "visible", false},
		{"panel", "visible", false},
	}
}

-- 定制礼包界面
config["activity_customize_gift_select.json"] = {
	set = {
		{"subList", "visible", false},
		{"iconItem", "visible", false},
		{"slotIcon", "visible", false},
	}
}


return config