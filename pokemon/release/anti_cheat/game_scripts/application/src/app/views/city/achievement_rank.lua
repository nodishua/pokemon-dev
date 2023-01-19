-- @date:   2019-12-18 15:54:25
-- @desc:   成就-排行榜

local function getLvByPoint(tab, maxLv, point)
	if point == 0 then
		return 0
	end
	local targetLv = 1
	local count = 0
	for lv,p in ipairs(tab) do
		count = count + 1
		if point < p then
			targetLv = lv - 1
			break
		end
		if maxLv == count then
			targetLv = maxLv
		end
	end
	
	return targetLv
end

local AchievementRankView = class("AchievementRankView", Dialog)
AchievementRankView.RESOURCE_FILENAME = "endless_tower_rank.json"
AchievementRankView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
	["achievementItem"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 6,
				data = bindHelper.self("rankDatas"),
				item = bindHelper.self("item"),
				achievementRank = bindHelper.self("rank"),
				onItem = function(list, node, k, v)
					local achievementRank = list.achievementRank:read()
					local childs = node:multiget(
						"rankImg",
						"logo",
						"textRank1",
						"textRank2",
						"roleName",
						"vip",
						"battle",
						"level",
						"textLv",
						"imgLvBg"
					)
					bind.extend(list, childs.logo, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.role.logo,
							frameId = v.role.frame,
							level = false,
							vip = false
						}
					})
					childs.imgLvBg:texture(gAchievementLevelCsv[0][v.achievementLv].icon)
					uiEasy.setRankIcon(v.index or k, childs.rankImg, childs.textRank1, childs.textRank2)
					childs.roleName:text(v.role.name)
					local vip = v.role.vip_level
					childs.vip:texture(ui.VIP_ICON[vip]):visible(vip > 0)
					childs.battle:text(v.achievement)
					childs.level:text(v.role.level)
					-- 成就等级
					childs.textLv:text(v.achievementLv)
					adapt.oneLinePos(childs.roleName, childs.vip, cc.p(15, 0))

					-- 点击自己不显示信息
					childs.logo:setTouchEnabled(achievementRank ~= k)
					childs.logo:onClick(functools.partial(list.clickCell, k, v))
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["rottomPanel"] = "rottomPanel",
	["fightNote"] = "fightNote",
	["gateNote"] = "gateNote",
}

function AchievementRankView:onCreate(rankDatas)
	local tab = {}
	local len = 0
	for lv,data in pairs(gAchievementLevelCsv[0]) do
		if lv > 0 then
			tab[lv] = data.point
			len = len + 1
		end
	end
	self:initModel()
	local pokedex = 0
	local index1 = 0
	for i=1,#rankDatas do
		local val = rankDatas[i]
		if i == 1 then
			pokedex = val.achievement
			index1 = i
			val.index = index1
		else
			if pokedex == val.achievement then
				val.index = index1
			else
				pokedex = val.achievement
				index1 = i
				val.index = i
			end
		end
		local curLv = getLvByPoint(tab, len, val.achievement)
		val.achievementLv = curLv
	end
	self.rankDatas = rankDatas

	self.fightNote:hide()
	self.gateNote:hide()

	local rankTxt = self.rank:read() == 0 and gLanguageCsv.notOnTheList or self.rank:read()
	self.rottomPanel:get("rank"):text(rankTxt)

	self.rottomPanel:get("roleName"):text(self.roleName:read())
	local num = 0
	for k,v in pairs(self.points:read()) do
		num = num + v
	end
	self.rottomPanel:get("battle"):text(num)
	local curLv = -1
	for i,v in ipairs(gAchievementLevelCsv[0]) do
		if v.point > num then
			curLv = i - 1
			break
		end
	end
	if curLv == -1 then
		-- 默认是从0开始的 所以要减去1
		curLv = itertools.size(gAchievementLevelCsv[0]) - 1
	end
	self.rottomPanel:get("gate"):text(curLv)

	Dialog.onCreate(self)
end

function AchievementRankView:initModel()
	self.roleName = gGameModel.role:getIdler("name")
	self.points = gGameModel.role:getIdler("achievement_points")
	self.rank = gGameModel.role:getIdler("achievement_rank")
end

function AchievementRankView:onItemClick(list, k, v, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x, y))
	gGameUI:stackUI("city.chat.personal_info", nil, nil, pos, {role = v.role}, {speical = "rank", target = list.item:get("bg")})
end

return AchievementRankView
