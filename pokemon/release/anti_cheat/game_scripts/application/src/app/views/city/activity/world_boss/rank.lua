-- @desc: 	world_boss-排行榜
-- @date:   2020-05-07

local WorldBossRankView = class("WorldBossRankView", Dialog)
WorldBossRankView.RESOURCE_FILENAME = "activity_world_boss_rank.json"
WorldBossRankView.RESOURCE_BINDING = {
	["leftPanel.tabItem"] = "tabItem",
	["leftPanel.tabList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("tabItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("selected")
					local panel
					if v.select then
						normal:hide()
						panel = selected:show()
					else
						selected:hide()
						panel = normal:show()
					end
					adapt.setAutoText(panel:get("txt"), v.name)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onTabClick"),
			},
		},
	},
	["trainerPanel"] = "trainerPanel",
	["trainerPanel.myRankPanel.txtName"] = "myName",
	["trainerPanel.rankItem"] = "trainerRankItem",
	["trainerPanel.list"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData1"),
				item = bindHelper.self("trainerRankItem"),
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("txtRank", "headPanel", "rankIcon", "txtName", "txtDamage", "txt", "level")
					bind.extend(list, childs.headPanel, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.role.logo,
							level = false,
							vip = false,
							frameId = v.role.frame,
							onNode = function(node)
								node:xy(104, 95)
									:z(6)
									:scale(0.9)
							end,
						}
					})
					childs.txtName:text(v.role.name)
					childs.level:text(v.role.level)
					text.addEffect(childs.txt, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					text.addEffect(childs.level, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					adapt.oneLineCenterPos(cc.p(385, 5), {childs.txt, childs.level}, cc.p(2, 0))
					childs.txtRank:visible(k > 3):text(k)
					childs.rankIcon:hide()
					if k <= 3 then
						childs.rankIcon:show()
							:texture("activity/world_boss/img_rank"..k..".png")
					end
					childs.txtDamage:text(v.boss_damage)
					bind.touch(list, node, {methods = {ended = functools.partial(list.clickCell, node, v)}})
				end,
				asyncPreload = 5,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
		{
			event = "touch",
			methods = {ended = bindHelper.self("btnrightClose")}
		},
	},
	["unionPanel"] = "unionPanel",
	["unionPanel.myRankPanel.txtName"] = "myUnionName",
	["unionPanel.myRankPanel.txtDamage"] = "myUnionDamage",
	["unionPanel.myRankPanel.txtRank"] = "myUnionRank",
	["unionPanel.rankItem"] = "unionRankItem",
	["unionPanel.list"] = {
		varname = "rankList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showData2"),
				item = bindHelper.self("unionRankItem"),
				itemAction = {isAction = true, alwaysShow = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("txtRank", "headPanel", "rankIcon", "txtName", "txtDamage", "icon", "txt", "level")
					childs.txtName:text(v.name)
					childs.level:text(v.level)
					text.addEffect(childs.txt, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					text.addEffect(childs.level, {outline = {color = ui.COLORS.OUTLINE.DEFAULT}})
					adapt.oneLineCenterPos(cc.p(385, 5), {childs.txt, childs.level}, cc.p(2, 0))
					childs.icon:texture(csv.union.union_logo[v.logo].icon)
					childs.txtRank:visible(k > 3):text(k)
					childs.rankIcon:hide()
					if k <= 3 then
						childs.rankIcon:show()
							:texture("activity/world_boss/img_rank"..k..".png")
					end
					-- 公会显示伤害总量
					childs.txtDamage:text(v.damage)
				end,
				asyncPreload = 5,
			},
		},
	},
	["noRankPanel"] = "noRankPanel",
	["rightPanel"] = "rightPanel",
	["rightPanel.title1.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(212, 86, 95, 255), size = 2}}
		}
	},
	["rightPanel.title2.txt"] = {
		binds = {
			event = "effect",
			data = {outline = {color = cc.c4b(212, 86, 95, 255), size = 2}}
		}
	},
}

function WorldBossRankView:onCreate(activityID, data)
	self.trainerPanel:hide()
	self.unionPanel:hide()
	self.noRankPanel:hide()
	self.rightPanel:get("list1"):setScrollBarEnabled(false)
	self.rightPanel:get("list2"):setScrollBarEnabled(false)

	self.showData1 = idlers.newWithMap(data.roleRank.ranks or {})
	self.showData2 = idlers.newWithMap(data.unionRank.ranks or {})
	self.panel = {
		{
			node = self.trainerPanel,
			data = data.roleRank,
		}, {
			node = self.unionPanel,
			data = data.unionRank,
		}
	}
	self.tabDatas = idlers.newWithMap({
		[1] = {name = gLanguageCsv.role},
		[2] = {name = gLanguageCsv.guild},
	})

	self.showTab = idler.new(1)
	self.showTab:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true
		self.rightPanel:hide()
		self.panel[oldval].node:hide()
		self.panel[val].node:show()
		local isempty = itertools.isempty(self.panel[val].data.ranks)
		self.noRankPanel:visible(isempty)
		-- 自己数据显示
		local panel = self.panel[val].node:get("myRankPanel")
		panel:visible(not isempty)
		local panelData = self.panel[val].data
		panel:get("txtRank"):text(panelData.selfRank == 0 and gLanguageCsv.notOnTheList or panelData.selfRank)
		panel:get("txtDamage"):text(panelData.selfDamage)
		self.myName:text(gGameModel.role:read("name"))
		if gGameModel.role:read("union_db_id") then
			self.myUnionName:text(gGameModel.union:read("name"))
		else
			self.myUnionName:text(gLanguageCsv.nonunion)
			self.myUnionDamage:hide()
			self.myUnionRank:hide()
		end
	end)
	Dialog.onCreate(self)
end

function WorldBossRankView:onTabClick(list, index)
	self.showTab:set(index)
end

function WorldBossRankView:onItemClick(list, node, v)
	self.rightPanel:show()
	local item = self.rightPanel:get("item")
	local function setCards(list, st, ed)
		list:removeAllChildren()
		for i = st, ed do
			local node = item:clone()
			list:pushBackCustomItem(node)
			local data = v.boss_battle_cards[i]
			if data then
				local cardCfg = csv.cards[data.card_id]
				local unitCfg = csv.unit[cardCfg.unitID]
				local unitId = dataEasy.getUnitId(data.card_id, data.skin_id)
				bind.extend(self, node, {
					class = "card_icon",
					props = {
						unitId = unitId,
						advance = data.advance,
						star = data.star,
						rarity = unitCfg.rarity,
						levelProps = {
							data = data.level,
						},
					}
				})
			else
				node:get("emptyPanel"):show()
			end
		end
	end
	setCards(self.rightPanel:get("list1"), 1, 3)
	setCards(self.rightPanel:get("list2"), 4, 6)
end

return WorldBossRankView