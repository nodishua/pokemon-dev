-- @desc 月卡特权显示

local ActivityMonthCardPrivilegeView = class("ActivityMonthCardPrivilegeView", Dialog)

ActivityMonthCardPrivilegeView.RESOURCE_FILENAME = "activity_month_card_privilege.json"
ActivityMonthCardPrivilegeView.RESOURCE_BINDING = {
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("datas"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget("desc", "value")
					local size = node:size()
					local desc = string.format("%d.%s", k, v.str)
					local value = ""
					if v.typ == "normal" then
						value = v.val
					elseif v.typ == "percent" then
						value = v.val*100 .. "%"
					end
					childs.desc:text(desc)
					childs.value:text(value)
					adapt.oneLinePos(childs.desc, childs.value, cc.p(0, 0), "left")
				end,
			},
		},
	},
	["card1"] = "card1",
	["card2"] = "card2",
}

function ActivityMonthCardPrivilegeView:onCreate(params)
	local data = {
		{name = "lianjinRate", str = gLanguageCsv.monthCardPrivilege1, typ = "percent"},
		{name = "staminaExtraMax", str = gLanguageCsv.monthCardPrivilege2, typ = "normal"},
		{name = "skillPointExtraMax", str = gLanguageCsv.monthCardPrivilege3, typ = "normal"},
		{name = "pwNoCD", str = gLanguageCsv.monthCardPrivilege4},
		{name = "lianjinFreeTimes", str = gLanguageCsv.monthCardPrivilege5, typ = "normal"},
		{name = "staminaBuyFreeTimes", str = gLanguageCsv.monthCardPrivilege6, typ = "normal"},

		{name = "lianJinUpstart", str = gLanguageCsv.monthCardPrivilege7},
		{name = "huodongFragTimes", str = gLanguageCsv.monthCardPrivilege8, typ = "normal"},
		{name = "huodongFragDropRate", str = gLanguageCsv.monthCardPrivilege9, typ = "percent"},
		{name = "huodongGiftTimes", str = gLanguageCsv.monthCardPrivilege10, typ = "normal"},
		{name = "huodongGiftDropRate", str = gLanguageCsv.monthCardPrivilege11, typ = "percent"},
		{name = "fragShopRefreshLimit", str = gLanguageCsv.monthCardPrivilege12, typ = "normal"},
		{name = "mysteryShopDiscount", str = gLanguageCsv.monthCardPrivilege13, typ = "percent"},
		{name = "fixShopDiscount", str = gLanguageCsv.monthCardPrivilege14, typ = "percent"},

		{name = "huodongGoldTimes", str = gLanguageCsv.monthCardPrivilege15, typ = "percent"},
		{name = "huodongGoldDropRate", str = gLanguageCsv.monthCardPrivilege16, typ = "percent"},
		{name = "huodongExpTimes", str = gLanguageCsv.monthCardPrivilege17, typ = "percent"},
		{name = "huodongExpDropRate", str = gLanguageCsv.monthCardPrivilege18, typ = "percent"},
	}
	local id = params.privilegeId
	local activityId = params.activityId
	local cfg = csv.month_card_privilege[id]
	local list = self.list
	local size = list:size()
	list:setScrollBarEnabled(false)
	local idx = 0
	self.datas = {}

	local yyCfg = csv.yunying.yyhuodong[activityId]
	local titleId = yyCfg.paramMap.title
	if titleId then
		local val = gTitleCsv[titleId].title
		table.insert(self.datas, {str = gLanguageCsv.monthCardPrivilege19, val = val, typ = "normal"})
	end

	for i, v in ipairs(data) do
		local val = cfg[v.name]
		if val then
			v.val = val
			table.insert(self.datas, v)
		end
	end

	self.card1:visible(id == 1)
	self.card2:visible(id == 2)

	Dialog.onCreate(self)
end

return ActivityMonthCardPrivilegeView