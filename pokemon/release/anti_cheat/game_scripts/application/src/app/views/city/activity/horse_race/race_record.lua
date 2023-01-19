-- @date:   2021-03-15
-- @desc:   赛马-比赛记录

local function getStrTime(historyTime)
	local timeTable = time.getCutDown(math.max(time.getTime() - historyTime, 0), nil, true)
	local strTime = timeTable.short_date_str
	strTime = strTime..gLanguageCsv.before
	return strTime
end

local HorseRaceRecordView = class("HorseRaceRecordView", Dialog)
HorseRaceRecordView.RESOURCE_FILENAME = "horse_race_record.json"
HorseRaceRecordView.RESOURCE_BINDING = {
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")},
		},
	},
    ["emptyPanel"] = "emptyPanel",
	["rankPanel"] = "rankPanel",
	["rankPanel.recordItem"] = "recordItem",
	["rankPanel.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("raceDatas"),
				item = bindHelper.self("recordItem"),
                dataOrderCmpGen = bindHelper.self("onSortRace", true),
				itemAction = {isAction = true},
				onItem = function(list, node, k, v)
					local childs = node:multiget(
						"txtDay",
						"txtTurn",
						"horseList",
						"horseItem",
						"btnGet",
						"txtNoReward",
						"btnReplay"
					)
                    childs.txtDay:text(string.format(gLanguageCsv.horseRaceRecordDay, v.day))
                    childs.txtTurn:text(string.format(gLanguageCsv.horseRaceRecordTurn, v.turn))
                    childs.txtNoReward:visible(v.rewardFlag < 0)
                    -- 箱子
                    local btnGet = childs.btnGet
                    local imgBox = btnGet:get("iconBox")
                    btnGet:visible(v.rewardFlag >= 0)
                    imgBox:texture("other/gain_gold/icon_box"..(v.rewardFlag < 1 and"_open5.png" or "5.png"))
                    bind.touch(list, btnGet, {methods = {ended = functools.partial(list.btnGet, k, v, node)}})
                    if v.rewardFlag == 1 then
						local effect = widget.addAnimation(btnGet, "effect/jiedianjiangli.skel", "effect_loop", imgBox:z() - 1)
						effect:scale(0.35)
							:x(imgBox:x())
							:y(imgBox:y() - 30)
                        btnGet.effectBox = effect
					elseif btnGet.effectBox then
						btnGet.effectBox:hide()
						btnGet.effectBox:removeFromParent()
						btnGet.effectBox = nil
					end
                    uiEasy.addVibrateToNode(list,imgBox,v.rewardFlag == 1,node:getName()..k.."vibrate")
					bind.touch(list, childs.btnReplay, {methods = {ended = functools.partial(list.playbackBtn, k, v)}})

                    local betIdx = v.betIdx
                    local players = v.players
                    bind.extend(list, childs.horseList, {
                        class = "listview",
                        props = {
                            data = players,
                            item = childs.horseItem,
                            onItem = function(list, node, k, v)
                                local childs = node:multiget(
                                    "betMark",
                                    "txtHorseRank"
                                )
                                local config = csv.cross.horse_race.horse_race_card[v.csv_id]
                                ccui.ImageView:create(csv.unit[config.unitID].cardIcon):addTo(node, 1, "img"):alignCenter(node:size()):scale(2)
                                ccui.ImageView:create("common/icon/panel_icon.png"):addTo(node, 0, "imgBg"):alignCenter(node:size())
                                childs.betMark:visible(v.idx == betIdx)
                                childs.txtHorseRank:text(string.format(gLanguageCsv.horseRaceRecordRank, v.result))
                            end
                        }
                    })
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				afterBuild = bindHelper.self("onAfterBuild"),
				playbackBtn = bindHelper.self("onPlaybackClick"),
				btnGet = bindHelper.self("onGetClick"),
			},
		},
	},
}

function HorseRaceRecordView:onCreate(activityId, getDataFunc)
    self:initModel()

    self.activityId = activityId
    self.emptyPanel:hide()
    local idlerData = getDataFunc()

    local beginDate = csv.yunying.yyhuodong[self.activityId].beginDate
    idlereasy.any({self.yyhuodongs, idlerData}, function(_, yyhuodongs, allData)
        local yyData = yyhuodongs[self.activityId]
        local betRewards = {}
        if yyData and yyData.horse_race and yyData.horse_race.bet_award then
            betRewards = yyData.horse_race.bet_award
        end
        local raceDatas = {}
        for date, __ in pairs(allData.view.history) do
            for turn, v in pairs(__) do
                local rewardStatus = {}
                if betRewards[date] and betRewards[date][turn] then
                    rewardStatus = betRewards[date][turn]
                end
                local playersData = {}
                for idx, player in ipairs(v) do
                    local data = {
                        idx = idx,
                        csv_id = player.csv_id,
                        result = player.result,
                    }
                    data.idx = idx
                    table.insert(playersData, data)
                end
                table.sort(playersData, function(a,b)
                    return a.result < b.result
                end)
                local oneRecord = {
                    date = date,
                    turn = turn,
                    day = math.floor((time.getNumTimestamp(date) - time.getNumTimestamp(beginDate)) / (24*3600)) + 1,
                    players = playersData,
                    betIdx = rewardStatus[1] and rewardStatus[1] + 1,
                    rank = rewardStatus[2],
                    rewardFlag = rewardStatus[3] or -2,
                }
                table.insert(raceDatas, oneRecord)
            end
        end
        self.raceDatas:update(raceDatas)
    end)

	Dialog.onCreate(self)
end

function HorseRaceRecordView:initModel()
    self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
    self.raceDatas = idlers.new()
end

function HorseRaceRecordView:onPlaybackClick(list, k, v)
    gGameApp:requestServer("/game/yy/horse/race/playback",function (tb)
        gGameUI:stackUI("city.activity.horse_race.match", nil, nil, self.activityId, {tb.view, v.betIdx})
    end, self.activityId, v.date, v.turn)
end


function HorseRaceRecordView:onGetClick(list, index, v, node)
	if v.rewardFlag == 1 then
        local box = node:get("btnGet"):get("iconBox")
		local showOver = {false}
		gGameApp:requestServerCustom("/game/yy/horse/race/bet/award")
			:params(self.activityId, v.date, v.turn)
			:onResponse(function (tb)
                self.raceDatas:atproxy(index).rewardFlag = 0
                uiEasy.addVibrateToNode(list,box,v.rewardFlag == 1,node:getName()..index.."vibrate")
				box:texture("other/gain_gold/icon_box_open5.png")
				uiEasy.setBoxEffect(box, 0.5, function()
					showOver[1] = true
				end, -15, 10)
			end)
			:wait(showOver)
            :doit(function (tb)
				gGameUI:showGainDisplay(tb)
			end)
    else
        local cfg = csv.yunying.horse_race_bet_award[1]
        local huodongID = csv.yunying.yyhuodong[self.activityId].huodongID
        for _, vv in csvPairs(csv.yunying.horse_race_bet_award) do
            if vv.huodongID == huodongID and vv.rank == v.rank then
                cfg = vv
                break
            end
        end
        gGameUI:showBoxDetail({
			data = cfg.award,
			content = "",
			state = 0
		})
	end
end


function HorseRaceRecordView:onAfterBuild()
    local showEmpty = self.list:getChildrenCount() == 0
    self.emptyPanel:visible(showEmpty)
    self.rankPanel:visible(not showEmpty)
end

function HorseRaceRecordView:onSortRace(list)
	return function(a,b)
        if a.date == b.date then
            return a.turn > b.turn
        else
            return a.date > b.date
        end
    end
end


return HorseRaceRecordView
