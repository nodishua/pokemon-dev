
local GymMasterInfoView =  class("GymMasterInfoView", Dialog)

GymMasterInfoView.RESOURCE_FILENAME = "gym_master_info.json"
GymMasterInfoView.RESOURCE_BINDING = {
    ["imgBG"] = "bg",
    ["imgBG.down.list"] = {
        varname = "battleArrayList",
        binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("battleData"),
				item = bindHelper.self("item"),
                margin = 65,
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							star = v.star,
							levelProps = {
								data = v.level,
							},
							onNode = function(node)
                                node:scale(1.2)
                                node:xy(-10,-30)
							end,
						}
					})
				end,
			},
		},
    },
    ["top.head"] =  {
		varname = "headImg",
		binds = {
			event = "extend",
			class = "role_logo",
			props = {
				logoId = bindHelper.self("logoId"),
                frameId = bindHelper.self("frameId"),
                level = false,
				vip = false,
				onNode = function(node)
					node:scale(1.1)
				end,
			}
		},

	},
    ["top.textName"] = "textName",
	["top.textFightPoint"] = "textFightPoint",
	["top.textUnionNote"] = "textUnionNote",
	["top.textUnion"] = "textUnion",
	["top.textNoteServer"] = "textNoteServer",
    ["top.textServer"] = "textServer",
	["top.imgVipInfo"] = "imgVipInfo",
    ["top.textLevel1"] = {
		varname = "textLevel1",
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c3b(91,84,91), size = 4}}
			},
		},
	},
    ["top.textLevel2"] = {
		varname = "textLevel2",
		binds = {
			{
				event = "effect",
				data = {outline = {color = cc.c3b(91,84,91), size = 4}}
			},
			{
				event = "text",
				idler = bindHelper.self("levelId"),
			},
		},
	},
    ["top.btnTake"] = {
		varname = "btnChat",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onPrivateChat")},
		},
    },
    ["top.btnTake.textNote"] = {
        binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
    },

    ["top.btnChallenge.textNote"] = {
        binds = {
			event = "effect",
			data = {glow={color=ui.COLORS.GLOW.WHITE}},
		},
	},
	["top.btnChallenge"] = {
		varname = "btnChallenge",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onChallenge")},
		},
	},

    ["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
}

function GymMasterInfoView:onCreate(masterData, id, isCross, unlocked, pos)
    self.masterData = masterData
    self.friendMessage = gGameModel.messages:getIdler('private')
    self.textName:text(masterData.role_name)
    self.logoId = idler.new(masterData.role_logo)
    self.frameId = idler.new(masterData.role_frame)
	self.levelId = idler.new(masterData.role_level)
	if masterData.role_vip == 0 then
		self.imgVipInfo:hide()
	else
		self.imgVipInfo:texture("common/icon/vip/icon_vip"..masterData.role_vip..".png")
	end
	self.isCross = isCross
	self.unlocked = unlocked
	self.id = id
	self.pos = pos
	if isCross == true then
		self.textUnionNote:hide()
		self.textUnion:hide()
		self.textNoteServer:show()
		self.textServer:text(getServerArea(masterData.game_key, true))
		self.textServer:show()
		self.btnChat:hide()
		self.btnChallenge:y(self.btnChat:y())
	else
		self.textUnionNote:show()
		self.textUnion:text(masterData.union_name)
		self.textUnion:show()
		self.textNoteServer:hide()
		self.textServer:hide()
	end
	local a = gGameModel.role:read("gym_record_db_id")
	local b = self.masterData.id
	if self.masterData.id == gGameModel.role:read("gym_record_db_id")  then
		self.btnChallenge:hide()
		self.btnChat:hide()
	end
	if not unlocked then
		uiEasy.setBtnShader(self.btnChallenge, self.btnChallenge:get("textNote"), 2)
	end

	adapt.oneLinePos(self.textLevel1, self.textLevel2,cc.p(-5,0))
	adapt.oneLinePos(self.textName, self.imgVipInfo,cc.p(10,0))

	self:initSprites(masterData)
    Dialog.onCreate(self)
end

function GymMasterInfoView:initSprites(masterData)
	self.item = ccui.Layout:create():size(180, 180)
		:show()
		:setTouchEnabled(false)
		:retain()
		:scale(0.8)
	local t = {}
	local fighting = 0
	local cardAttrs = {}
	if self.isCross then
		cardAttrs = masterData.cross_card_attrs
	else
		cardAttrs = masterData.card_attrs
	end
	for i, v in pairs(cardAttrs) do
		local cardCsv = csv.cards[v.card_id == 0 and 11 or v.card_id]
		local unitCsv = csv.unit[cardCsv.unitID]
		local unitId = dataEasy.getUnitId(v.card_id, v.skin_id)
		table.insert(t, {
			cardId = v.card_id == 0 and 11 or v.card_id,
			advance = v.advance,
			unitId = unitId,
			star = v.star,
			level = v.level,
			rarity = unitCsv.rarity,
			id = v.id,
		})
		fighting = fighting + v.fighting_point
	end
	if #t < 6 then
		local num = #t
		for i=num + 1, 6 do
			table.insert(t, {
				unitId = -1,
			})
		end
	end
	self.battleData = idlertable.new(t)
	self.textFightPoint:text(fighting)
end

function GymMasterInfoView:onPrivateChat()
	local data = {
		isMine = false,
		role = {
			level = self.masterData.role_level,
			id = self.masterData.role_id,
			logo = self.masterData.role_logo,
			name = self.masterData.role_name,
			vip = self.masterData.role_vip,
			frame = self.masterData.role_frame,
		},
	}
	gGameUI:stackUI("city.chat.privataly", nil, nil, data)
end

function GymMasterInfoView:onChallenge( )
	if self:getChallengeState() == false then
		gGameUI:showTip(gLanguageCsv.gymTimeOut)
		return
	end
	if self.isCross then
		local endTime = gGameModel.role:read("gym_datas").cross_gym_pw_last_time + gCommonConfigCsv.gymPwCD
		if time.getTime() < endTime then
			gGameUI:showTip(gLanguageCsv.gymInCd)
			return
		end
	else
		local endTime = gGameModel.role:read("gym_datas").gym_pw_last_time + gCommonConfigCsv.gymPwCD
		if time.getTime() < endTime then
			gGameUI:showTip(gLanguageCsv.gymInCd)
			return
		end
	end
	if not self.unlocked then
		if self.isCross then
			gGameUI:showTip(gLanguageCsv.gymCrossTips1)
		else
			gGameUI:showTip(gLanguageCsv.gymTips1)
		end
		return
	end

	local natureLimit = csv.gym.gym[self.id].limitAttribute
	if #dataEasy.getNatureSprite(natureLimit) == 0 then
		gGameUI:showTip(gLanguageCsv.gymNoSptire1)
		return
	end

	local id = self.id
	local pos = self.pos
	local masterData = self.masterData
	local isCross = self.isCross
	--玩家
	local fightCb = function(view, battleCards)
		local endStamp = time.getNumTimestamp(gGameModel.gym:read("date"), 21, 45) + 6 * 24 * 3600
		if time.getTime() >= endStamp then
			gGameUI:showTip(gLanguageCsv.gymTimeOut)
			return
		end

		local data = battleCards:read()
		if not isCross then
			battleEntrance.battleRequest("/game/gym/leader/battle/start", data, id, masterData.id)
				:onStartOK(function(data)
					view:onClose(false)
				end)
				:run()
				:show()
		else
			battleEntrance.battleRequest("/game/cross/gym/battle/start", data, id, pos, masterData.game_key, masterData.id)
				:onStartOK(function(data)
					view:onClose(false)
				end)
				:run()
				:show()
		end
	end
	gGameUI:stackUI("city.adventure.gym_challenge.embattle1", nil, {full = true}, {
		fightCb = fightCb,
		limitInfo = csv.gym.gym[self.id].limitAttribute,
		from = game.EMBATTLE_FROM_TABLE.onekey,
	})
	self:onClose()
end

-- 检测是否在可挑战时段内
function GymMasterInfoView:getChallengeState()
	if gGameModel.gym:read("round") == "closed" then
		return false
	end
	local endStamp = time.getNumTimestamp(gGameModel.gym:read("date"), 21, 45) + 6 * 24 * 3600
	return time.getTime() < endStamp
end

return GymMasterInfoView