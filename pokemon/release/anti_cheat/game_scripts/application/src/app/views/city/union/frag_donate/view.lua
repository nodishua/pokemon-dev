-- @date:   2020-02-28
-- @desc:   公会许愿界面
local function setFragName(childs, v)
	local fragCsv = csv.fragments[v.fragId]
	childs.fragName:text(fragCsv.name)
	text.addEffect(childs.fragName, {color = ui.COLORS.QUALITY[fragCsv.quality]})
end

local UnionFragDonateView = class("UnionFragDonateView", cc.load("mvc").ViewBase)
UnionFragDonateView.RESOURCE_FILENAME = "union_frag_donate.json"
UnionFragDonateView.RESOURCE_BINDING = {
	["item"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("fragDatas"),
				item = bindHelper.self("item"),
				asyncPreload = 5,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"logo",
						"vipIcon",
						"textName",
						"level",
						"fragIcon",
						"fragName",
						"haveNum",
						"bar",
						"textPercent",
						"btnDonate",
						"iconTxt",
						"textMe"
					)
					bind.extend(list, childs.logo, {
						event = "extend",
						class = "role_logo",
						props = {
							logoId = v.memberData.logo,
							frameId = v.memberData.frame,
							level = false,
							vip = false,
							onNode = function(node)
								node:scale(0.9)
							end,
						}
					})
					childs.vipIcon:texture(ui.VIP_ICON[v.memberData.vip]):visible(v.memberData.vip>0)
					childs.textName:text(v.memberData.name)
					adapt.oneLinePos(childs.textName, childs.vipIcon, cc.p(5, 0))
					childs.level:text(v.memberData.level)
					setFragName(childs, v)
					bind.extend(list, childs.fragIcon, {
						event = "extend",
						class = "icon_key",
						props = {
							data = {
								key = v.fragId,
							},
							onNode = function(node)
								node:scale(1)
							end,
						}
					})
					childs.haveNum:text(v.haveNum)
					childs.bar:percent(cc.clampf(v.current/v.totalmax*100, 0, 100))
					childs.textPercent:text(v.current.."/"..v.totalmax)
					childs.btnDonate:visible(2 == v.isMe and v.canDotane)
					childs.iconTxt:visible(2 == v.isMe and not v.canDotane)
					childs.textMe:visible(v.isMe == 1)
					uiEasy.setBtnShader(childs.btnDonate, childs.btnDonate:get("title"), v.haveNum > 0 and 1 or 2)
					bind.touch(list, childs.btnDonate, {methods = {ended = functools.partial(list.clickCell, k, v)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick"),
			},
		},
	},
	["btnWish"] = {
		varname = "btnWish",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnWish")}
		},
	},
	["btnWish.title"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["btnRecord"] = {
		varname = "btnRecord",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRecord")}
		},
	},
	["btnRecord.title"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["effectPanel"] = "effectPanel",
	["donateTimes"] = "donateTimes",
	["boxIcon"] = {
		varname = "boxIcon",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onAwardBtn")}
		},
	},
	["btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnRule")}
		},
	},
	["btnRule.title"] = {
		binds = {
			event = "effect",
			data = {glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["boxPercent"] = "boxPercent",
	["bar"] = "bar",
	["empty"] = "empty",
}
UnionFragDonateView.RESOURCE_STYLES = {
	full = true,
}


function UnionFragDonateView:onCreate()
	self:initModel()
	gGameUI.topuiManager:createView("union", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.guild, subTitle = "CONSORTIA"})

	--会员列表数据
	self.fragDatas = idlers.new({})
	idlereasy.any({self.fragDonate, self.members}, function(_, fragDonate, members)
		local fragDatas = {}
		for k,v in pairs(fragDonate) do
			if members[k] and v.frag_id then
				local myDonateTimes = itertools.count(v.history, self.id:read())
				table.insert(fragDatas,{
					roleId = k,
					memberData = members[k],
					haveNum = self.frags:read()[v.frag_id] or 0,
					fragId = v.frag_id,
					current = v.current,
					totalmax = v.totalmax,
					history = v.history,
					isMe = k == self.id:read() and 1 or 2,
					canDotane = myDonateTimes < gCommonConfigCsv.unionFragDonateSingleMaxTimes
				})
			end
		end
		self.empty:visible(itertools.size(fragDatas) == 0)
		table.sort(fragDatas, function(a,b)
			return a.isMe < b.isMe
		end)
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.fragDatas:update(fragDatas)
	end)
	widget.addAnimation(self.effectPanel, "effect/jiedianjiangli.skel", "effect_loop", 1, 0)
		:scale(0.5)
		:xy(100, 80)
	idlereasy.any({self.unionFragDonatePoint, self.unionFragDonateAwards}, function(_, unionFragDonatePoint, unionFragDonateAwards)
		local awardCsv = csv.union.union_frag_donate_award
		local targetNum
		-- self.boxIcon
		self.awardCsvId = 0
		self.isLastBox = false
		self.effectPanel:hide()
		for i=1,csvSize(awardCsv) do
			local v = awardCsv[i]
			self.award = v.award
			if not unionFragDonateAwards[i] then
				targetNum = v.point
				break
			end
			targetNum = v.point
			if unionFragDonateAwards[i] == 1 then
				self.effectPanel:show()
				self.awardCsvId = i
				break
			end
			self.isLastBox = i == csvSize(awardCsv)
		end
		self.targetNum = targetNum
		self.boxPercent:text(unionFragDonatePoint.."/"..targetNum)
		self.bar:percent(cc.clampf(unionFragDonatePoint/targetNum*100, 0, 100))
	end)

	idlereasy.when(self.unionFragDonateTimes, function(_, unionFragDonateTimes)
		-- unionFragDonateTimes
		-- unionFragDonateSingleMaxTimes
		local surplusNum = math.max(gCommonConfigCsv.unionFragDonateTimes - unionFragDonateTimes, 0)
		self.donateTimes:text(surplusNum.."/"..gCommonConfigCsv.unionFragDonateTimes)
	end)
end

function UnionFragDonateView:initModel()
	self.frags = gGameModel.role:getIdler("frags")
	self.id = gGameModel.role:getIdler("id")
	-- 公会碎片赠予热心人点数
	self.unionFragDonatePoint = gGameModel.role:getIdler("union_frag_donate_point")
	-- 公会碎片赠予热心人点数宝箱奖励 {csv_id: flag} (可领:1  已领: 0)
	self.unionFragDonateAwards = gGameModel.role:getIdler("union_frag_donate_awards")
	local unionInfo = gGameModel.union
	self.unionId = unionInfo:getIdler("id")
	self.unionLv = unionInfo:getIdler("level")
	--成员列表 key长度24 ID长度12
	self.members = unionInfo:getIdler("members")
	-- 公会碎片赠与 {Role.id : {frag_id: 碎片id, current: 当前已接受数量, totalmax: 最大数量, history: [role.id, role.id, ...]}}
	self.fragDonate = unionInfo:getIdler("frag_donate")
	local dailyRecord = gGameModel.daily_record
	-- 公会碎片赠予次数
	self.unionFragDonateTimes = dailyRecord:getIdler("union_frag_donate_times")
	-- 公会碎片赠予发起次数
	self.unionFragDonateStartTimes = dailyRecord:getIdler("union_frag_donate_start_times")
	-- 获赠记录
	self.unionFragDonateHistorys = gGameModel.role:getIdler("union_frag_donate_historys")
end
--许愿界面
function UnionFragDonateView:onBtnWish()
	if self.unionFragDonateStartTimes:read() >= 1 then
		gGameUI:showTip(gLanguageCsv.pleaseComeBackTomorrow)
		return
	end
	gGameUI:stackUI("city.union.frag_donate.wish")
end
--记录界面
function UnionFragDonateView:onBtnRecord()
	if itertools.size(self.unionFragDonateHistorys:read()) <= 0 then
		gGameUI:showTip(gLanguageCsv.notRecod)
		return
	end
	gGameUI:stackUI("city.union.frag_donate.record")
end
function UnionFragDonateView:onItemClick(list, k, v)
	if self.unionFragDonateTimes:read() >= gCommonConfigCsv.unionFragDonateTimes then
		gGameUI:showTip(gLanguageCsv.fragDonateTimesNotEnough)
		return
	end
	if v.haveNum <= 0 then
		gGameUI:showTip(gLanguageCsv.fragDonateFragNotEnough)
		return
	end
	local fragCsv = csv.fragments[v.fragId]
	local fragDonateCsv = csv.union.union_frag_donate[fragCsv.quality]
	local awardStr = string.format(gLanguageCsv.getEnthusiastsRanAndPoints, fragDonateCsv.point)
	for k,v in csvMapPairs(fragDonateCsv.award) do
		awardStr = string.format("%s%s#I%s-54-54#", awardStr, v, dataEasy.getIconResByKey(k))
	end

	local presenterFunc = function()
		gGameApp:requestServer("/game/union/frag/donate", function (tb)
			gGameUI:showTip(awardStr)
		end, v.roleId, v.fragId)
	end
	--@ 新加品质是S及以上的增加二级框
	local cfg = dataEasy.getCfgByKey(v.fragId)
	if cfg and cfg.quality >= 5 then
		gGameUI:showDialog{strs = {
			string.format(gLanguageCsv.presenterCard, cfg.name)
		}, isRich = true, cb = presenterFunc, btnType = 2}
	else
		presenterFunc()
	end


end
--领取奖励
function UnionFragDonateView:onAwardBtn()
	if self.awardCsvId ~= 0 then
		gGameApp:requestServer("/game/union/frag/donate/award", function (tb)
			gGameUI:showGainDisplay(tb)
		end, self.awardCsvId)
	else
		gGameUI:showBoxDetail({
			data = self.award,
			content = self.isLastBox and "" or string.format(gLanguageCsv.enthusiastsRanGetPoints, self.targetNum),
			state = self.isLastBox and 2 or 1
		})
	end
end

function UnionFragDonateView:onBtnRule()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {width = 1500})
end

function UnionFragDonateView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
		end),
		c.noteText(112),
		c.noteText(45001, 45010),
	}
	return context
end
return UnionFragDonateView