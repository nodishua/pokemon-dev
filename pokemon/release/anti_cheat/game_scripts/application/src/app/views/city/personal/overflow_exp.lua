
-- @desc: 经验溢出(父目录是自己信息界面)
local OverflowExpView = class("OverflowExpView", Dialog)

OverflowExpView.RESOURCE_FILENAME = "personal_overflow_experience.json"
OverflowExpView.RESOURCE_BINDING = {
	["up.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tableDat"),
				item = bindHelper.self("item"),
				itemAction = {isAction = true},
				dataOrderCmp = function(a, b)
					local overFlowA, overFlowB = false, false
					if a.sum_exp and a.sum_exp[a.k] then
						local countA = a.limit - a.sum_exp[a.k]
						if countA == 0 then
							overFlowA = true

						end
					end
					if b.sum_exp and b.sum_exp[b.k] then
						local countB = b.limit - b.sum_exp[b.k]
						if countB == 0 then
							overFlowB = true

						end
					end
					if overFlowA then
						return false
					elseif overFlowB then
						return true
					else
						return a.sort < b.sort
					end
				end,

				onItem = function(list, node, k, v)
					local childs = node:multiget("expNumber", "icon", "dhNumber", "dh", "dhBtn", "list")
					childs.expNumber:text(v.needExp)
					childs.icon:hide()
					uiEasy.createItemsToList(list, childs.list, v.award)
					local btnShader = false
					--# 条件不足置灰
					local statFunc = function()
						childs.dhNumber:setTextColor(ui.COLORS.NORMAL.DEFAULT)
						uiEasy.setBtnShader(childs.dhBtn, childs.dhBtn:get("textNote"), 2)
					end
					--# v.limit等0代表无限兑换，不等0是有具体次数
					if v.limit == 0 then
						childs.dhNumber:visible(false)
						childs.dh:visible(false)
						childs.dhBtn:y(122)
					else
						--# 某些道具已经兑换过
						if v.sum_exp and v.sum_exp[k] then
							local count = v.limit - v.sum_exp[k]
							count = count < 0 and 0 or count
							childs.dhNumber:text(count.."/"..v.limit)
							if count == 0 then
								statFunc()
								btnShader = true
							end
						else
							childs.dhNumber:text(v.limit.."/"..v.limit)
						end
						childs.dh:x(childs.dhNumber:x() - childs.dhNumber:width()- 10)
					end
					if v.role_exp:read() < v.needExp and not btnShader then
						statFunc()
					end
					bind.touch(list, childs.dhBtn, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
				asyncPreload = 4,
			},
			handlers = {
				clickCell = bindHelper.self("btnClick")
			},
		},
	},
	["centre"] = "centre",
	["centre.title3"] = {
		binds = {
			event = "text",
			idler = bindHelper.model("role", "overflow_exp"),
		},
	},
}

function OverflowExpView:onCreate()
	self:initModel()
	self.item:visible(false)
	self.list:setScrollBarEnabled(false)
	local dateTab = self:filtrateData()
	self.tableDat = idlers.newWithMap(dateTab)
	adapt.oneLineCenterPos(cc.p(540, 31), {self.centre:get("title"), self.centre:get("icon"), self.centre:get("title4"), self.centre:get("title2"), self.centre:get("icon2"), self.centre:get("title5"), self.centre:get("title3")}, cc.p(6, 0))
	Dialog.onCreate(self)
end

function OverflowExpView:filtrateData()
	local tabShow = {}
	for i,v in ipairs(csv.overflow_exp_exchange) do
		table.insert(tabShow, {needExp = v.needExp, limit = v.limit, sort = v.sort, award = v.award, sum_exp = self.sum_exp:read(), role_exp = self.role_exp, k = i})
	end
	return tabShow
end

function OverflowExpView:initModel()
	--# sum_exp已购买次数，role_exp溢出经验

	self.sum_exp = gGameModel.role:getIdler("overflow_exp_exchanges")
	self.role_exp = gGameModel.role:getIdler("overflow_exp")
end
function OverflowExpView:btnClick(list, k, v)
	local key, num = csvNext(v.award)
	local count = v.limit
	if v.sum_exp and v.sum_exp[k] then
		count = v.limit - v.sum_exp[k]
		count = count < 0 and 0 or count
	end
	local maxNum = count ~= 0 and count or nil
	self.csvId = k
	self.award = v.award
	gGameUI:stackUI("common.buy_info", nil, nil, {overflow_exp = v.needExp}, {id = key, num = num}, {maxNum = maxNum, contentType = "num"}, self:createHandler("updateDate"))
end

function OverflowExpView:updateDate(num)
	gGameApp:requestServer("/game/role/overflow_exp_exchange", function(tb)
		local dataFunc = function()
			local dataShow = self:filtrateData()
			dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
			self.tableDat:update(dataShow)
		end
		gGameUI:showGainDisplay(tb.view, {raw = true, dataFunc()})
	end, self.csvId, num)
end

return OverflowExpView
