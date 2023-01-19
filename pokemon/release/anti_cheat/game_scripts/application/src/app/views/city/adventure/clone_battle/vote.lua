local ViewBase = cc.load("mvc").ViewBase
local CloneBattleVoteView = class("CloneBattleVoteView", Dialog)
--
CloneBattleVoteView.RESOURCE_FILENAME = "clone_battle_kick_note.json"
CloneBattleVoteView.RESOURCE_BINDING = {
	["closeBtn"] = {
		varname = "closeBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["leaveBtn"] = {
		varname = "leaveBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onLeaveBtn")},
		}
	},
	["stayBtn"] = {
		varname = "stayBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onStayBtn")},
		}
	},
	["txt1"] = "txt1",
	["txt2"] = "txt2",
	["txt3"] = "txt3",
	["txt4"] = "txt4",
	["name1"] = "name1",
	["name2"] = "name2",
	["name3"] = "name3",
	["name4"] = "name4",
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["content"] = "contentLabel",
}

function CloneBattleVoteView:onCreate(isFromInfo)
	self:initModel()
	-- self.cardDatas = idlers.new()--卡牌数据

	local isFromInfo = isFromInfo
	idlereasy.any({self.beasIdler.finishNum, self.beasIdler.places, self.beasIdler.voteRound}, function (_, finishNum, places, voteRound)
		if voteRound == "start" then
			local nameTab = {}
			local leaveNum = 0
			local stayNum = 0
			local isVote = 0
			local selfId = gGameModel.role:read("id")
			self.name = places[1].name
			-- local richText = rich.createWithWidth(string.format("#C0x5b545b#"..gLanguageCsv.cloneBattleKickText, self.name), 50, nil, 1250)
			-- 	:addTo(self.txt2, 10)
			-- 	:anchorPoint(cc.p(0.5, 0.5))
			-- 	:xy(0, 0)
			-- 	:formatText()
			-- adapt.oneLineCenterPos(cc.p(300, 130), {richText}, cc.p(0, 0))
			local defaultAlign = "center"
			local size = self.contentLabel:size()
			local list, height = beauty.textScroll({
				size = size,
				fontSize = 50,
				effect = {color=ui.COLORS.NORMAL.DEFAULT},
				strs = string.format("#C0x5b545b#"..gLanguageCsv.cloneBattleKickText, self.name),
				verticalSpace =10,
				isRich = true,
				margin = 20,
				align = defaultAlign,
			})
			local y = 0
			if height < size.height then
				y = -(size.height - height) / 2
			end
			list:addTo(self.contentLabel,10):y(y)

			for k, v in pairs(places) do
				if v.kick_leader ~= 0 then
					table.insert(nameTab, v.name)
					if v.kick_leader < 0 then
						stayNum = stayNum + 1
					else
						leaveNum = leaveNum + 1
					end
					if v.id == selfId then
						isVote = v.kick_leader
						-- cache.setShader(self.leaveBtn, false, "hsl_gray")
						-- cache.setShader(self.stayBtn, false, "hsl_gray")
						-- self.leaveBtn:get("gou"):show()
						-- self.stayBtn:get("gou"):show()
						-- adapt.oneLineCenterPos(cc.p(0, 0), {self.leaveBtn:get("gou"), self.leaveBtn:get("txt")}, cc.p(0, 0))
						-- adapt.oneLineCenterPos(cc.p(0, 0), {self.stayBtn:get("gou"), self.stayBtn:get("txt")}, cc.p(0, 0))
					end
				end
			end
			for k = 1, 4 do
				if nameTab[k] then
					self["name"..k]:text(nameTab[k])
					self["name"..k]:show()
				else
					self["name"..k]:hide()
				end
			end
			if isVote ~= 0 then
				cache.setShader(self.leaveBtn, false, "hsl_gray")
				cache.setShader(self.stayBtn, false, "hsl_gray")
				if isVote == 1 then
					self.leaveBtn:get("gou"):show()
				else
					self.stayBtn:get("gou"):show()
				end
				adapt.oneLineCenterPos(cc.p(140, 60), {self.leaveBtn:get("gou"), self.leaveBtn:get("txt")}, cc.p(0, 0))
				adapt.oneLineCenterPos(cc.p(140, 60), {self.stayBtn:get("gou"), self.stayBtn:get("txt")}, cc.p(0, 0))
				self.leaveBtn:setTouchEnabled(false)
				self.stayBtn:setTouchEnabled(false)
				self.txt3:text(string.format(gLanguageCsv.cloneBattleVote, leaveNum))
				self.txt3:show()
				self.txt4:text(string.format(gLanguageCsv.cloneBattleVote, stayNum))
				self.txt4:show()
			end
			isFromInfo = false
		else
			-- if voteRound ~= "start" then
			if isFromInfo == false then
				ViewBase.onClose(self)
				return
			end
			-- end
		end
	end)
	Dialog.onCreate(self)
end

function CloneBattleVoteView:initModel()
	-- 一些基础信息的ilder
	self.beasIdler = {
		date = gGameModel.clone_room:getIdler("date"),				-- 创建日期
		finishNum = gGameModel.clone_room:getIdler("finish_num"),	-- 目标完成人数
		monsters = gGameModel.clone_room:getIdler("monsters"),		-- 目标精灵表
		places = gGameModel.clone_room:getIdler("places"),			-- 房间成员信息
		voteRound = gGameModel.clone_room:getIdler("vote_round"),	-- 投票
	}
end

function CloneBattleVoteView:onLeaveBtn()
	local name = self.name
	gGameUI:showDialog({content = "#C0x5b545b#"..gLanguageCsv.cloneBattleKickVoteTipLeave, cb = function()
		gGameApp:requestServer("/game/clone/room/vote", function (tb)
			if tb.view.result == "win" then
				gGameUI:showTip(string.format(gLanguageCsv.cloneBattleKickVoteResultTipLeave, name))
				-- ViewBase.onClose(self)
			elseif tb.view.result == "fail" then
				gGameUI:showTip(string.format(gLanguageCsv.cloneBattleKickVoteResultTipStay, name))
				-- ViewBase.onClose(self)
			end
		end, 1)
	end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
end

function CloneBattleVoteView:onStayBtn()
	local name = self.name
	gGameUI:showDialog({content = "#C0x5b545b#"..gLanguageCsv.cloneBattleKickVoteTipStay, cb = function()
		gGameApp:requestServer("/game/clone/room/vote", function (tb)
			if tb.view.result == "win" then
				gGameUI:showTip(string.format(gLanguageCsv.cloneBattleKickVoteResultTipLeave, name))
				-- ViewBase.onClose(self)
			elseif tb.view.result == "fail" then
				gGameUI:showTip(string.format(gLanguageCsv.cloneBattleKickVoteResultTipStay, name))
				-- ViewBase.onClose(self)
			end
		end, -1)
		-- gGameUI:showTip(gLanguageCsv.cloneBattleKickVoteTipStay)
		-- ViewBase.onClose(self)
	end, btnType = 2, isRich = true, dialogParams = {clickClose = false}})
end

return CloneBattleVoteView
