-- @date 2020-8-31
-- @desc 训练家重聚 签到

-- 服务端对应状态 未达成 (不可领取)，可领取，已领取
local STATE_TYPE = {
	noReach = 0,
	canReceive = 1,
	received = 2,
}

-- 展示状态 可领取, 未达成 (不可领取)，已领取
local STATE_TYPE_SHOW = {
	canReceive = 0,
	noReach = 1,
	received = 2,
}

-- 主题分类(1每日签到;2相逢有时)
local STATE_TYPE_THEME =
{
	sign = 1,
	reunion = 2,
}

--奖励类型 1-重聚礼包 2-绑定奖励 3-任务奖励 4-积分奖励
local STATE_TYPE_GET =
{
	ReunionGift = 1,
	BindAward = 2,
	TaskAward = 3,
	PointAward = 4,
}

local ReunionSignView = class("ReunionSignView", cc.load("mvc").ViewBase)

ReunionSignView.RESOURCE_FILENAME = "reunion_sign.json"
ReunionSignView.RESOURCE_BINDING = {
	["topPanel.bg.title"] = {
		binds = {
			event = "effect",
			data = {
				outline = {color = cc.c4b(242, 122, 96, 255), size = 4},
				shadow = {color = cc.c4b(195, 109, 72, 255), offset = cc.size(0,-6), size = 6}
			},
		},
	},
	["topPanel.textPanel"] = "topTextPanel",
	["topPanel.textPanel.textBg"] = "toptextBg",
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					if a.state ~= b.state then
						return a.state < b.state
					end
					return a.csvId < b.csvId
				end,
				onItem = function(list, node, k, v)
					local cfg = v.cfg
					local childs = node:multiget("list", "receivebtn", "received", "noReceive", "title", "subList", "item")
					childs.title:text(string.format(gLanguageCsv.currDay, cfg.taskParam))
					childs.receivebtn:visible(v.state == STATE_TYPE_SHOW.canReceive)
					childs.received:visible(v.state == STATE_TYPE_SHOW.received)
					childs.noReceive:visible(v.state == STATE_TYPE_SHOW.noReach)
					bind.touch(list, childs.receivebtn, {methods = {ended = functools.partial(list.clickCell, k, v)}})

					childs.list:removeAllItems()
					childs.list:size(cc.size(376, 560))
					childs.list:setScrollBarEnabled(false)
					childs.list:setGravity(ccui.ListViewGravity.bottom)
					local subList = nil
					local idx = 0
					local len = csvSize(cfg.award)
					local dx = len == 1 and childs.item:size().width/2 or 0
					for _, itemData in ipairs(dataEasy.getItemData(cfg.award)) do
						local id = itemData.key
						local num = itemData.num
						idx = idx + 1
						if idx % 2 == 1 then
							subList = childs.subList:clone():show():tag(math.floor(idx/2 + 1))
							subList:setScrollBarEnabled(false)
							subList:setTouchEnabled(false)
							childs.list:pushBackCustomItem(subList)
						end
						local item = childs.item:clone():show()
						local size = item:size()
						bind.extend(list, item, {
							class = "icon_key",
							props = {
								data = {
									key = id,
									num = num,
								},
								onNode = function(node)
									node:xy(size.width/2 + dx, size.height/2)
										:scale(0.9)
								end,
							},
						})
						subList:pushBackCustomItem(item)
					end
					childs.list:adaptTouchEnabled()
						:setItemAlignCenter()
				end,
				asyncPreload = 4,
			},
			handlers = {
				clickCell = bindHelper.self("onReceiveClick"),
			},
		},
	},
}

function ReunionSignView:onCreate(yyID)
	self.yyID = yyID
	local cfg = csv.yunying.yyhuodong[yyID]

	self:initModel()

	local showText = string.format(gLanguageCsv.reunionSignText, self.reunion:read().info.days)
	local richText = rich.createByStr(showText,42)
		:anchorPoint(0, 0.5)
		:addTo(self.topTextPanel:get("label"))
		:formatText()
	self.toptextBg:width(richText:width()+20)

	self.datas = idlers.new()
	idlereasy.when(self.reunion, function(_, reunion)

		local stamps = reunion.stamps or {}
		local datas = {}
		for k, v in csvPairs(csv.yunying.reunion_task) do
			if v.huodongID == cfg.huodongID and v.themeType == STATE_TYPE_THEME.sign then

				local state = STATE_TYPE_SHOW.noReach
				if stamps[k] and stamps[k] == STATE_TYPE.canReceive then
					state = STATE_TYPE_SHOW.canReceive
				elseif stamps[k] and stamps[k] == STATE_TYPE.received then
					state = STATE_TYPE_SHOW.received
				end
				table.insert(datas, {csvId = k, cfg = v, state = state})
			end
		end
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.datas:update(datas)
	end)
end

function ReunionSignView:initModel()
	self.reunion = gGameModel.role:getIdler("reunion")
end

function ReunionSignView:onReceiveClick(list, k, v)
	if v.state == STATE_TYPE_SHOW.canReceive then
		if self.reunion:read().info.end_time - time.getTime() < 0 then
			gGameUI:showTip(gLanguageCsv.activityOver)
			return
		end
		gGameApp:requestServer("/game/yy/reunion/award/get", function(tb)
			gGameUI:showGainDisplay(tb)
		end, self.yyID, v.csvId, STATE_TYPE_GET.TaskAward)
	elseif v.state == STATE_TYPE_SHOW.noReach then
		gGameUI:showTip(gLanguageCsv.notReachedCannotGet)
	end
end

return ReunionSignView