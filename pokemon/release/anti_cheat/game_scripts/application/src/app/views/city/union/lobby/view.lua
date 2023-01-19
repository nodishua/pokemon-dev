-- @date:   2019-06-05
-- @desc:   公会大厅界面

local BTN_STATE = {
	GET = 0,
	GO = 1,
	NONE = 2,
	GOT = 3
}
local JOB = {
	CHAIRMAN = 1,
	VICE_CHAIRMAN = 2,
	MEMBER = 3
}
local JOB_TXT = {
	gLanguageCsv.chairman,
	gLanguageCsv.viceChairman,
	gLanguageCsv.member
}
local JOIN_TYPE_TXT = {
	[0] = gLanguageCsv.needApply,
	[1] = gLanguageCsv.freeEntry,
	[2] = gLanguageCsv.noMoreRecruiting
}
local JOIN_TYPE_COLOR = {
	[0] = ui.COLORS.NORMAL.DEFAULT,
	[1] = ui.COLORS.NORMAL.FRIEND_GREEN,
	[2] = ui.COLORS.NORMAL.RED
}

--判断职位
local function JudgmentJob(id, jobList)
	if jobList["chairman"] == id then
		return JOB.CHAIRMAN
	end
	if jobList["viceChairmans"][id] then
		return JOB.VICE_CHAIRMAN
	end
	return JOB.MEMBER
end
--返回公会信息文本 type
-- 1，name1加入公会
-- 2，name1退出公会
-- 3，name1被name2踢出公会
-- 4，name1晋升为副会长
-- 5，name1降级为会员
-- 6，name2转让会长给name1
-- 7，name1被选拔为新任会长
-- 8，name2批准name1加入公会
local function setRecordTxt(v)
	local txt = csv.union.history[v.type].fmt
	if v.type == 3 then
		return string.format(txt, v.name1, v.name2)
	elseif v.type == 6 or v.type == 8 then
		return string.format(txt, v.name2, v.name1)
	else
		return string.format(txt, v.name1)
	end
end
--返回在线时间
local function onlineTxt(lasttime)
	local valTime = math.max(time.getTime() - lasttime, 0)
	local tmpTime = time.getCutDown(valTime, nil, true)
	if tmpTime.day <= 0 and tmpTime.hour <= 0 and tmpTime.min <= 10 then
		return ''
	end
	return tmpTime.head_date_str..gLanguageCsv.before
end
--设置在线时间
local function setOnlineTxt(txtNode, lasttime)
	if onlineTxt(lasttime) == "" then
		txtNode:text(gLanguageCsv.currentlyOnline)
		text.addEffect(txtNode, {color = ui.COLORS.NORMAL.FRIEND_GREEN})
	else
		txtNode:text(onlineTxt(lasttime))
		text.addEffect(txtNode, {color = ui.COLORS.NORMAL.GRAY})
	end
end
--设置item
local function setItem(list, childs, v)
	bind.extend(list, childs.logo, {
		event = "extend",
		class = "role_logo",
		props = {
			logoId = v.logo,
			frameId = v.frame,
			level = false,
			vip = false,
			onNode = function(node)
				node:scale(0.9)
			end,
		}
	})
	childs.vipIcon:texture(ui.VIP_ICON[v.vip]):visible(v.vip>0)
	childs.textName:text(v.name)
	adapt.oneLinePos(childs.textName, childs.vipIcon, cc.p(5, 0))
	childs.level:text(v.level)
	childs.fighting:text(v.fighting_point)
	local lasttime = v.lasttime or v.time
	setOnlineTxt(childs.onlineTime, lasttime)
end

local UnionLobbyView = class("UnionLobbyView", cc.load("mvc").ViewBase)
UnionLobbyView.RESOURCE_FILENAME = "union_lobby.json"
UnionLobbyView.RESOURCE_BINDING = {
	["leftPanel.item"] = "leftItem",
	["leftPanel.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("leftDatas"),
				item = bindHelper.self("leftItem"),
				itemAction = {isAction = true},
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
						panel:get("subTxt"):text(v.subName)
						if v.redHint then
							local props = v.redHint
							bind.extend(list, panel, {
								class = "red_hint",
								props = props,
							})
						end
					end
					panel:get("txt"):text(v.name)
					adapt.setTextScaleWithWidth(panel:get("txt"), nil, 330)
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {methods = {ended = functools.partial(list.clickCell, k)}})
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onLeftItemClick"),
			},
		},
	},
	["informationItem"] = "informationItem",
	["informationPanel.list"] = {
		varname = "memberList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("memberDatas"),
				item = bindHelper.self("informationItem"),
				dataOrderCmpGen = bindHelper.self("onSortMembers", true),
				roleId = bindHelper.self("roleId"),
				asyncPreload = 5,
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local roleId = list.roleId:read()
					local childs = node:multiget(
						"logo",
						"vipIcon",
						"textName",
						"job",
						"level",
						"fighting",
						"contribution",
						"onlineTime"
					)
					setItem(list, childs, v)
					childs.contribution:text(v.contrib)
					childs.job:text(JOB_TXT[v.job])
					node:setTouchEnabled(roleId~=v.id)
					node:onClick(functools.partial(list.clickCell, k, v))
				end,
			},
			handlers = {
				clickCell = bindHelper.self("onShowInfoClick"),
			},
		},
	},
	["applyItem"] = "applyItem",
	["applyPanel.list"] = {
		varname = "applyList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("joinNotes"),
				item = bindHelper.self("applyItem"),
				myJob = bindHelper.self("myJob"),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local myJob = list.myJob:read()
					local childs = node:multiget(
						"logo",
						"vipIcon",
						"textName",
						"level",
						"fighting",
						"applyTime",
						"onlineTime",
						"noBtn",
						"yesBtn"
					)
					setItem(list, childs, v)
					local applyTxt = onlineTxt(v.time)
					if applyTxt == "" then
						applyTxt = gLanguageCsv.justNow
					end
					childs.applyTime:text(applyTxt)

					childs.noBtn:visible(myJob ~= JOB.MEMBER)
					childs.yesBtn:visible(myJob ~= JOB.MEMBER)
					bind.touch(list, childs.noBtn, {methods = {ended = functools.partial(list.refuseClick, k, v)}})
					bind.touch(list, childs.yesBtn, {methods = {ended = functools.partial(list.acceptClick, k, v)}})
					-- bind.touch(list, node, {methods = {ended = functools.partial(list.detailClick, k, v)}})
					node:onClick(functools.partial(list.detailClick, k, v))
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				refuseClick = bindHelper.self("onRefuseBtn"),
				acceptClick = bindHelper.self("onAcceptBtn"),
				detailClick = bindHelper.self("onBtnDetail"),
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["informationPanel"] = "informationPanel",
	["recordList"] = "recordList",
	["applyPanel"] = "applyPanel",
	["recordTitleItem"] = "recordTitleItem",
	["recordItem"] = "recordItem",
	["informationPanel.logoPanel"] = {
		varname = "selectLogoBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSelectLogo")}
		},
	},
	["informationPanel.btnChangeName"] = {
		varname = "btnChangeName",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnChangeName")}
		},
	},
	["informationPanel.disbandBtn"] = {
		varname = "disbandBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onDisbandBtn")}
		},
	},
	["informationPanel.changeBtn"] = {
		varname = "changeNoticeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeNoticeBtn")}
		},
	},
	["informationPanel.changeBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["informationPanel.emailBtn"] = {
		varname = "emailBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onEmailBtn")}
		},
	},
	["informationPanel.emailBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["informationPanel.emailBtn.imgLock"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("mailUnlock"),
			method = function(val)
				return not val
			end,
		},
	},
	["informationPanel.quitBtn"] = {
		varname = "quitBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onQuitBtn")}
		},
	},
	["informationPanel.btnRule"] = {
		varname = "btnRule",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRuleBtn")}
		},
	},
	["informationPanel.quitBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["informationPanel.unionName"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionName"),
		},
	},
	["informationPanel.chairmanName"] = "chairmanName",
	["informationPanel.unionId"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("uid"),
		},
	},
	["informationPanel.logoPanel.logo"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("logo"),
			method = function(logo)
				return csv.union.union_logo[logo].icon
			end
		},
	},
	["informationPanel.pos1"] = "pos1",
	["informationPanel.pos2"] = "pos2",
	["informationPanel.pos3"] = "pos3",
	["informationPanel.unionNum"] = "unionNum",
	["informationPanel.unionMaxNum"] = "unionMaxNum",
	["informationPanel.unionExp"] = "unionExp",
	["informationPanel.unionLevel"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("unionLevel"),
		},
	},
	["applyPanel.changeBtn"] = {
		varname = "changeStateBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChangeStateBtn")}
		},
	},
	["applyPanel.recruitBtn"] = {
		varname = "recruitBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRecruitBtn")}
		},
	},
	["applyPanel.recruitBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["applyPanel.refuseBtn"] = {
		varname = "refuseBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onRefuseAllBtn")}
		},
	},
	["applyPanel.refuseBtn.title"] = {
		binds = {
			event = "effect",
			data = {color = ui.COLORS.NORMAL.WHITE, glow = {color = ui.COLORS.GLOW.WHITE}},
		},
	},
	["applyPanel.state"] = "state"
}

function UnionLobbyView:onCreate()
	local adaptWidth1 = self.informationItem:multiget("bg")
	local adaptWidth2 = self.informationPanel:multiget("list", "listTitlePanel.bg")
	local adaptLeft1 = self.informationItem:multiget("logo", "textName", "levelNote", "level", "vipIcon", "job")
	local adaptLeft2 = self.informationPanel:multiget("list", "listTitlePanel.member", "listTitlePanel.job", "logoPanel", "unionLevelNote", "unionLevel",
		"unionNameNote", "unionName", "chairmanNameNote", "chairmanName", "unionExpNote", "unionExp", "btnChangeName", "unionIdNote", "unionId", "unionNumNote", "unionNum", "unionMaxNum")
	local adaptRight1 = self.informationItem:multiget("contribution", "onlineTime")
	local adaptRight2 = self.informationPanel:multiget("listTitlePanel.contribution", "listTitlePanel.onlineTime", "disbandBtn", "changeBtn", "emailBtn", "quitBtn", "pos1", "pos2", "pos3")
	adapt.centerWithScreen("left", "right", nil, {
		{self.informationItem, "width"},
		{adaptWidth1, "width"},
		{adaptWidth2, "width"},
		{adaptLeft1, "pos", "left"},
		{adaptLeft2, "pos", "left"},
		{adaptRight1, "pos", "right"},
		{adaptRight2, "pos", "right"},
	})
	self.pos1:setTouchEnabled(false)
	self.pos2:setTouchEnabled(false)
	self.pos3:setTouchEnabled(false)

	self:initModel()
	gGameUI.topuiManager:createView("union", self, {onClose = self:createHandler("onClose")})
		:init({title = gLanguageCsv.guild, subTitle = "CONSORTIA"})

	self.leftDatas = {
		{name = gLanguageCsv.unionInformation, subName = "Information"},
		{name = gLanguageCsv.unionRecod, subName = "Record"},
		{name = gLanguageCsv.applyList, subName = "Apply", redHint = {
			specialTag = "unionLobby",
		}}}
	self.leftDatas = idlers.newWithMap(self.leftDatas)
	self.recordList:setScrollBarEnabled(false)
	self.showTab = idler.new(1)
	self.showTab:addListener(function(val, oldval, idler)
		self:setTabPanel(val, oldval)
	end)

	self.jobList = {}
	self.myJob = idler.new()
	--会员列表数据
	self.memberDatas = idlertable.new()
	idlereasy.any({self.chairmanId, self.viceChairmans, self.members}, function(_, chairmanId, viceChairmans, members)
		local jobList = {}
		jobList["chairman"] = chairmanId
		local tmpViceChairmans = {}
		for k,v in ipairs(viceChairmans) do
			tmpViceChairmans[v] = true
		end
		jobList["viceChairmans"] = tmpViceChairmans
		self.jobList = jobList
		self.myJob:set(JudgmentJob(self.roleId:read(), jobList))

		--会员数量
		self.unionNum:text(itertools.size(members))
		adapt.oneLinePos(self.unionNum, self.unionMaxNum)
		local chairmanId = jobList["chairman"]
		self.chairmanName:text(members[chairmanId].name)
		local memberDatas = {}
		for k,v in pairs(members) do
			v.job = JudgmentJob(v.id, jobList)
			table.insert(memberDatas,v)
		end
		dataEasy.tryCallFunc(self.memberList, "updatePreloadCenterIndex")
		self.memberDatas:set(memberDatas, true)
	end)
	idlereasy.when(self.myJob, function(_, myJob)
		self:setFunctions(myJob)
	end)
	idlereasy.any({self.unionLevel, self.unionContrib}, function(_, unionLevel, unionContrib)
		local csvUnionLevel = csv.union.union_level
		--会员最大数量
		self.unionMaxNum:text("/"..csvUnionLevel[unionLevel].memberMax)
		--副会长最大数量
		self.viceChairmanMax = csvUnionLevel[unionLevel].viceChairmanMax
		--当前公会经验经验
		local nowExp = unionContrib
		for i=1,unionLevel -1 do
			nowExp = nowExp - csvUnionLevel[i].levelUpContrib
		end
		self.unionExp:text(nowExp.."/"..csvUnionLevel[unionLevel].levelUpContrib)
	end)
	--设置招募状态 joinType 0需要申请，1自由加入，2不再招募
	idlereasy.any({self.joinLevel, self.joinType}, function(_, joinLevel, joinType)
		local txt = JOIN_TYPE_TXT[joinType]
		if joinType ~= 2 then
			txt = txt..(joinLevel==0 and gLanguageCsv.noLimit or string.format(gLanguageCsv.levelLimit, joinLevel))
		end
		self.state:text(txt)
		text.addEffect(self.state, {color = JOIN_TYPE_COLOR[joinType]})
		adapt.oneLinePos(self.state, self.changeStateBtn, cc.p(15, 0))
	end)
	--公会记录
	idlereasy.when(self.history, function(_, history)
		local agoDate = {}
		self.recordList:removeAllChildren()
		for i,v in ipairs(history) do
			local date = time.getDate(v.time)
			if not (next(agoDate) ~= nil and date.month == agoDate.month and date.day == agoDate.day) then
				agoDate.month = date.month
				agoDate.day = date.day
				local titleItem = self.recordTitleItem:clone():show()
				titleItem:get("month"):text(date.month)
				titleItem:get("day"):text(date.day)
				adapt.oneLinePos(titleItem:get("month"), {titleItem:get("monthNote"),titleItem:get("day"),titleItem:get("dayNote")}, cc.p(15, 0))
				self.recordList:pushBackCustomItem(titleItem)
			end
			local recordItem = self.recordItem:clone():show()
			local richText = rich.createWithWidth("#C0x5B545B#" .. setRecordTxt(v), 40, nil, 1680)
			richText:setAnchorPoint(cc.p(0, 0.5))
			recordItem:get("time"):text(string.format("%02d:%02d",date.hour, date.min))
			recordItem:get("pos"):add(richText, 3)
			self.recordList:pushBackCustomItem(recordItem)
		end
		self.recordList:jumpToBottom()
	end)

	self.mailUnlock = idler.new(dataEasy.isUnlock("unionMail"))
	idlereasy.when(self.roleLv, function()
		self.mailUnlock:set(dataEasy.isUnlock("unionMail"))
	end)
end

function UnionLobbyView:initModel()
	self.roleLv = gGameModel.role:getIdler("level")
	local unionInfo = gGameModel.union
	self.unionId = unionInfo:getIdler("id")
	self.history = unionInfo:getIdler("history")
	--申请列表
	self.joinNotes = unionInfo:getIdler("join_notes")
	self.uid = unionInfo:getIdler("uid")
	self.logo = unionInfo:getIdler("logo")
	--会长ID 长度12
	self.chairmanId = unionInfo:getIdler("chairman_db_id")
	--副会长ID 长度12
	self.viceChairmans = unionInfo:getIdler("vice_chairmans")
	--申请限制等级
	self.joinLevel = unionInfo:getIdler("join_level")
	--申请状态
	self.joinType = unionInfo:getIdler("join_type")
	--公会当前等级
	self.unionLevel = unionInfo:getIdler("level")
	--公会总经验
	self.unionContrib = unionInfo:getIdler("contrib")
	--成员列表 key长度24 ID长度12
	self.members = unionInfo:getIdler("members")
	self.unionName = unionInfo:getIdler("name")
	self.roleId = gGameModel.role:getIdler("id")
	--已发送邮件次数
	self.sendMailTimes = unionInfo:getIdler("send_mail_times")
	--已发送招募次数
	self.joinupInviteIimes = unionInfo:getIdler("joinup_invite_times")
end
function UnionLobbyView:setTabPanel(val, oldval)
	self.leftDatas:atproxy(oldval).select = false
	self.leftDatas:atproxy(val).select = true
	self.informationPanel:visible(val == 1)
	self.recordList:visible(val == 2)
	self.applyPanel:visible(val == 3)
end
--设置权利
function UnionLobbyView:setFunctions(myJob)
	--解散公会
	self.disbandBtn:visible(myJob == JOB.CHAIRMAN)
	--修改公告
	local changeNoticeBtnX = myJob == JOB.CHAIRMAN and self.pos2:x() or self.pos1:x()
	self.changeNoticeBtn:visible(myJob ~= JOB.MEMBER):x(changeNoticeBtnX)
	--修改名字
	self.btnChangeName:visible(myJob == JOB.CHAIRMAN)
	--群发邮件
	local emailBtnX = myJob == JOB.CHAIRMAN and self.pos3:x() or self.pos2:x()
	self.emailBtn:visible(myJob ~= JOB.MEMBER):x(emailBtnX)
	--退会
	self.quitBtn:visible(myJob ~= JOB.CHAIRMAN)
	--修改招募状态
	self.changeStateBtn:visible(myJob ~= JOB.MEMBER)
	--发布招募信息
	self.recruitBtn:visible(myJob ~= JOB.MEMBER)
	--全部拒绝加入
	self.refuseBtn:visible(myJob ~= JOB.MEMBER)
	self.selectLogoBtn:setEnabled(myJob ~= JOB.MEMBER)
end
--选择图标
function UnionLobbyView:onSelectLogo()
	gGameUI:stackUI("city.union.lobby.select_logo", nil, nil, {id = self.logo:read()})
end
--显示会员信息
function UnionLobbyView:onShowInfoClick(list, index, v, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x - 300, y))
	gGameUI:stackUI("city.union.lobby.member_info", nil, {clickClose = true, dispatchNodes = list}, {
		memberData = v,
		myJob = self.myJob:read(),
		viceChairmanNum = itertools.size(self.jobList["viceChairmans"]),
		viceChairmanMax = self.viceChairmanMax,
		pos = pos,
		target = list.item:get("logo")
	})
end
--公会改名
function UnionLobbyView:onBtnChangeName()
	gGameUI:stackUI("city.card.changename", nil, nil, {
		typ = "union",
		name = self.unionName:read(),
		cost = gCommonConfigCsv.unionRenameRMBCost,
		titleTxt = gLanguageCsv.unionChangeName
	})
end
--解散公会
function UnionLobbyView:onDisbandBtn()
	if itertools.size(self.members:read()) > 1 then
		gGameUI:showTip(gLanguageCsv.canDissolvedOnlyOnePerson)
		return
	end

	--跨服公会战开启并入选的公会，赛季期间不可解散
	local status = gGameModel.role:read("cross_union_fight_status")
	if status and status ~= "closed" then
		gGameUI:showTip(gLanguageCsv.crossUnionNotDissolveUnion)
		return
	end

	gGameUI:stackUI("city.union.lobby.prompt", nil, nil, {
		content = "#C0x5B545B#" .. gLanguageCsv.confirmDissolutionGuild,
		needConsider = true,
		typ = "destroy",
		cb = self:createHandler("disbandCb")
	})
end
function UnionLobbyView:disbandCb()
	self:onBackBtnClick()
end
--修改公告
function UnionLobbyView:onChangeNoticeBtn()
	gGameUI:stackUI("city.union.lobby.change_notice")
end
--群发邮件
function UnionLobbyView:onEmailBtn()
	if not self.mailUnlock:read() then
		local startLevel = csv.unlock[gUnlockCsv.unionMail].startLevel
		gGameUI:showTip(string.format(gLanguageCsv.unionMailUnlockLv, startLevel))
		return
	end
	local sendMailTimes = self.sendMailTimes:read() or 0
	if sendMailTimes >= 2 then
		gGameUI:showTip(gLanguageCsv.noMailTime)
		return
	end
	gGameUI:stackUI("city.union.lobby.group_email", nil, nil, sendMailTimes)
end

--退出公会
function UnionLobbyView:onQuitBtn()
	local str = gLanguageCsv.confirmWithdrawalFromTheGuild
	if dataEasy.isUnionBuildProtectionTime() then
		-- 保护天数
		local protectionTime = gCommonConfigCsv.newbieUnionQuitProtectDays
		str = string.format(gLanguageCsv.newWithdrawalFromTheGuild, protectionTime * 24)
	end
	gGameUI:stackUI("city.union.lobby.prompt", nil, nil, {
		content = "#C0x5B545B#" .. str,
		typ = "quit",
		cb = self:createHandler("onBackBtnClick")
	})
end

--规则
function UnionLobbyView:onRuleBtn()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"))
end

function UnionLobbyView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.clone(view.title),
		c.noteText(142),
		c.noteText(11001,11099),
	}
	return context
end

-- 返回主城
function UnionLobbyView:onBackBtnClick()
	gGameUI:cleanStash()
	gGameUI:switchUI("city.view")
end

--修改申请状态
function UnionLobbyView:onChangeStateBtn()
	gGameUI:stackUI("city.union.lobby.current_state")
end
--发布招募
function UnionLobbyView:onRecruitBtn()
	if self.joinType:read() == 2 then
		gGameUI:showTip(gLanguageCsv.noMoreRecruiting)
		return
	end
	local joinupInviteIimes = self.joinupInviteIimes:read() or 0
	if joinupInviteIimes >= 2 then
		gGameUI:showTip(gLanguageCsv.noRecruitTime)
		return
	end
	gGameUI:stackUI("city.union.lobby.prompt", nil, nil, {
		content = "#C0x5B545B#" .. gLanguageCsv.publishingRecruitmentInformation,
		numTip = string.format(gLanguageCsv.sendableToday, 2-joinupInviteIimes, 2),
		typ = "joinup",
		cb = self:createHandler("recruitCb")
	})
end
function UnionLobbyView:recruitCb()
	gGameUI:showTip(gLanguageCsv.releaseSuccessful)
end
--全部拒绝
function UnionLobbyView:onRefuseAllBtn()
	if itertools.size(self.joinNotes:read()) < 1 then
		gGameUI:showTip(gLanguageCsv.currentlyNoApplication)
		return
	end
	gGameApp:requestServer("/game/union/join/refuse/all",function (tb)
		gGameUI:showTip(gLanguageCsv.allRejected)
	end)
end
--同意加入
function UnionLobbyView:onAcceptBtn(list, index, v)
	gGameApp:requestServer("/game/union/join/accept",function (tb)
		gGameUI:showTip(gLanguageCsv.agreed)
	end, v.id)
end
--拒绝加入
function UnionLobbyView:onRefuseBtn(list, index, v)
	gGameApp:requestServer("/game/union/join/refuse",function (tb)
		gGameUI:showTip(gLanguageCsv.rejected)
	end, v.id)
end
--查看详情
function UnionLobbyView:onBtnDetail(list, index, v, event)
	local target = event.target
	local x, y = target:xy()
	local pos = target:getParent():convertToWorldSpace(cc.p(x - 900, y))
	v.job = 3
	gGameUI:stackUI("city.union.lobby.member_info", nil, {clickClose = true, dispatchNodes = list}, {
		memberData = v,
		myJob = 3,
		viceChairmanNum = itertools.size(self.jobList["viceChairmans"]),
		viceChairmanMax = self.viceChairmanMax,
		pos = pos,
		target = list.item:get("logo")
	})
end
--tab点击
function UnionLobbyView:onLeftItemClick(list, index)
	self.showTab:set(index)
end
--会员排序
function UnionLobbyView:onSortMembers(list)
	return function(a, b)
		if a.job ~= b.job then
			return a.job < b.job
		end
		return a.contrib > b.contrib
	end
end
--申请列表为空
function UnionLobbyView:onAfterBuild()
	self.applyPanel:get("empty"):visible(self.applyList:getChildrenCount() == 0)
end
return UnionLobbyView