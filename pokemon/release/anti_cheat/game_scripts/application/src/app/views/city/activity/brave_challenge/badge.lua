-- @date:   2021-03-09
-- @desc:   勇者挑战---勋章加成

local BADGE_BELONG = {
    mine = 1, -- 我方勋章
    enemy = 2,  --敌方
}

local BADGE_TYPE = {
    normal  = 1,  --普通
    rare    = 2, -- 稀有勋章
    forever = 3, -- 永久勋章
}

local BADGE_DI = {
    "activity/brave_challenge/box_yztz_18.png",
    "activity/brave_challenge/box_yztz_17.png",
    "activity/brave_challenge/box_yztz_21.png",
}


local MAX_ROW = 8 -- 每行限时的最大勋章数

-- 初始化标题的item
local function initTileItem(list, node, k, v)
	node:size(1900, 100)
    node:get("list"):hide()
    node:get("noItem"):hide()
	node:get("title"):y(50):show()
	local title = node:get("title.txt")
	local bg = node:get("title.bg")
	if v.data == BADGE_TYPE.rare then
        title:text(gLanguageCsv.braveChallengeRareBadge)
        bg:texture("activity/brave_challenge/box_yztz_13.png")
        text.addEffect(title, {color = cc.c3b(253, 252, 159)})
        text.addEffect(title, {outline = {color = cc.c4b(244,144,15, 255),  size = 4}})
	else
        title:text(gLanguageCsv.braveChallengeNormalBadge)
        bg:texture("activity/brave_challenge/box_yztz_14.png")
        text.addEffect(title, {color = cc.c3b(255, 251, 232)})
	end
end
-- 无勋章
local function initNoItem(list, node, k, v)
    node:size(1900, 230)
    node:get("list"):hide()
    node:get("title"):hide()
	node:get("noItem"):y(115):show()
end

-- 初始化勋章列表的item
local function initSpriteItem(list, node, k, v)
    node:get("title"):hide()
    node:get("noItem"):hide()
	local spriteList = node:get("list"):y(0)
	local innerItem = list.spriteItem
	node:size(cc.size(1900, 230))
	bind.extend(list, spriteList, {
		class = "listview",
		props = {
			data = v,
			item = innerItem,
			onItem = function(innerList, cell, kk ,vv)
                local childs = cell:multiget("select","icon","bg")

                childs.bg:texture(BADGE_DI[vv.rarity])
                childs.icon:texture(vv.res)
                childs.select:visible(vv.select)
                bind.touch(innerList, cell, {methods = {ended = functools.partial(list.itemClick, innerList, cell, vv)}})
			end,
        },
    })
    node:get("list"):setItemAlignCenter()
end

local ViewBase = cc.load("mvc").ViewBase
local BraveChallengeBadgeView = class("BraveChallengeBadgeView",ViewBase)

BraveChallengeBadgeView.RESOURCE_FILENAME = "activity_brave_challenge_badge.json"

BraveChallengeBadgeView.RESOURCE_BINDING = {
    ["titile"] = "titile",
    ["noItem"] = "noItem",
    ["item"] = "item",
    ["tip"] = "tip",
    ["iconPanel"] = "spriteItem",
    ["imgBg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onClose"),
		}
    },
    ["list"] = {
        varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("showDatas"),
                item = bindHelper.self("item"),
                spriteItem = bindHelper.self("spriteItem"),
				itemAction = {isAction = true},
                onItem = function(list, node, k, v)
                    if v.type == "title" then
						initTileItem(list, node, k, v)
                    elseif v.type == "noItem" then
                        initNoItem(list, node, k, v)
                    else
						initSpriteItem(list, node, k, v)
					end
				end,
            },
            handlers = {
                itemClick = bindHelper.self("onItemClick"),
            },
        },
    },
}
BraveChallengeBadgeView.RESOURCE_STYLES = {
    blackLayer = true,
    clickClose = true,
}

function BraveChallengeBadgeView:onCreate(data, idx)
    self.showDatas = {}
    if idx == BADGE_BELONG.mine then
        self.titile:texture("activity/brave_challenge/txt_yztz_5.png")
    elseif idx == BADGE_BELONG.enemy then
        self.titile:texture("activity/brave_challenge/txt_yztz_4.png")
    end
    self.tip:text(gLanguageCsv.braveChallengeBadgeTip)
    self:initPanel(data)
end

function BraveChallengeBadgeView:initPanel(data)
    local badgeCfg = csv.brave_challenge.badge
    local showDatas = {[BADGE_TYPE.rare] = {}, [BADGE_TYPE.normal] = {}}
    for k, v in ipairs(data) do
        if badgeCfg[v] then
            local rarity = badgeCfg[v].rarity > BADGE_TYPE.rare and BADGE_TYPE.rare or badgeCfg[v].rarity

            table.insert(showDatas[rarity], {
                name = badgeCfg[v].name,
                desc = badgeCfg[v].desc,
                res = badgeCfg[v].iconResPath,
                rarity = badgeCfg[v].rarity,
                select = false,
            })
        end
    end
    local row = 1
    for k = itertools.size(showDatas), 1, -1 do
        local v = showDatas[k]
        if itertools.size(v) == 0 then
            self.showDatas[row] = {type = "title", data = k}
            row = row + 1
            self.showDatas[row] = {type = "noItem", data = k}
            row = row + 1
        else
            self.showDatas[row] = {type = "title", data = k}
            local count = 0
            table.sort(v, function(v1, v2) return v1.rarity > v2.rarity end)

            for kk, vv in ipairs((v)) do
                local x = math.ceil(kk / MAX_ROW)   -- 行
                local y = (kk - 1 ) % MAX_ROW + 1   -- 列
                self.showDatas[x + row] = self.showDatas[x + row ] or {}
                self.showDatas[x + row][y] = vv
                count = count + 1
            end

            row = math.ceil(count / MAX_ROW) + row + 1
        end
    end
end

function BraveChallengeBadgeView:onItemClick(list, innerList, node, v)
     if gGameUI.itemDetailView then
		gGameUI.itemDetailView:onClose()
	end
	local name = "city.activity.brave_challenge.badge_detail"
	local canvasDir = "vertical"
	local childsName = {"baseNode"}

	local view = tip.create(name, nil, {relativeNode = node, canvasDir = canvasDir, childsName = childsName, dir = "right"}, v)
	view:onNodeEvent("exit", functools.partial(gGameUI.unModal, gGameUI, view))
	gGameUI:doModal(view)
	gGameUI.itemDetailView = view
end


return BraveChallengeBadgeView