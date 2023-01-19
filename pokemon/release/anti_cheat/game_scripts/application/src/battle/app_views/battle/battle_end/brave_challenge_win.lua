--
--  战斗胜利界面 -- 通用的界面
--

local BraveChallengeWinView = class("BraveChallengeWinView", cc.load("mvc").ViewBase)

BraveChallengeWinView.RESOURCE_FILENAME = "battle_end_brave_challenge_win.json"
BraveChallengeWinView.RESOURCE_BINDING = {
	["awardsList"] = "awardsList",
	["awardsItem"] = "awardsItem",
	["bkg"] = {
		binds = {
			event = "click",
			method = bindHelper.self("onQuitClick"),
		},
	},
	["roundNums"] = {
		binds = {
			event = "extend",
			class = "text_atlas",
			props = {
				data = bindHelper.self("roundNums"),
				pathName = "frhd_num",
				isEqualDist = false,
				align = "center",
			}
		}
	}
}

function BraveChallengeWinView:playEndEffect()
	local pnode = self:getResourceNode()
	-- 结算特效
	local textEffect = CSprite.new("level/jiesuanshengli.skel")		-- 文字部分特效
	textEffect:addTo(pnode, 100)
	textEffect:setAnchorPoint(cc.p(0.5,1.0))
	textEffect:setPosition(pnode:get("title"):getPosition())
	textEffect:visible(true)
	-- 播放结算特效
	textEffect:play("jiesuan_shenglizi")
	textEffect:addPlay("jiesuan_shenglizi_loop")
	textEffect:retain()

	local bgEffect = CSprite.new("level/jiesuanshengli.skel")		-- 底部特效
	bgEffect:addTo(pnode, 99)
	bgEffect:setAnchorPoint(cc.p(0.5,1.0))
	bgEffect:setPosition(pnode:get("title"):getPosition())
	bgEffect:visible(true)
	-- 播放结算特效
	bgEffect:play("jiesuan_shenglitu")
	bgEffect:addPlay("jiesuan_shenglitu_loop")
	bgEffect:retain()
end

-- results: 放数据的
function BraveChallengeWinView:onCreate(sceneID, data, results)
	audio.playEffectWithWeekBGM("gate_win.mp3")
	self.data = data
	self.results = results
	self.sceneID = sceneID
	local pnode = self:getResourceNode()

	local preData = data.preData or {}
	local roleInfo = preData.roleInfo or {}
	local cardsInfo = preData.cardsInfo or {}
	local dropInfo = results.serverData.view.drop or {}
	local awardInfo = results.serverData.view.award or {}
	local floorID = self.data.floorID
	local firstAwards = csv.brave_challenge.floor[floorID].firstAward
	local isFirstPass = results.serverData.view.first_pass
	local showItemInfo = {}
	for k,v in pairs(dropInfo) do
		showItemInfo[k] = v
	end
	for k,v in pairs(awardInfo) do
		if not showItemInfo[k] then
			showItemInfo[k] = v
		else
			showItemInfo[k] = showItemInfo[k] + v
		end
	end
	local sceneCfg = csv.scene_conf[sceneID]

	-- 回合
	if results.round then
		pnode:get("round"):text(gLanguageCsv.round .. " :")
		self.roundNums = results.round
	else
		pnode:get("round"):visible(false)
	end


	-- 结算特效
	self:playEndEffect()

	-- 奖励文字 getAwards
	local awardsText = pnode:get("awardsText")
	awardsText:text(gLanguageCsv.getAwards  .. " :")
	local tmpData = {}
	for k,v in pairs(showItemInfo) do
		local insertPos = battleEasy.ifElse(isFirstPass, 1, table.length(tmpData) + 1)
		table.insert(tmpData, insertPos, {key = k, num = v, isFirst = isFirstPass})
	end
	if next(tmpData) then
		self:showItem(1, tmpData)
	else
		local x, y = awardsText:xy()
		awardsText:xy(x + 325, y)
		awardsText:text(gLanguageCsv.passAwardsAlreadyToplimit)
		self.awardsList:hide()
	end
end

function BraveChallengeWinView:showItem(index, data)
	local function addResToItem(node, res)
		local size = node:size()
		local sp = cc.Sprite:create(res)
		:addTo(node, 999)
		:anchorPoint(1, 1)
		:xy(size.width, size.height)
	end

	local item = self.awardsItem:clone()
	item:show()
	local key = data[index].key
	local num = data[index].num
	local binds = {
		class = "icon_key",
		props = {
			data = {
				key = key,
				num = num,
			},
			isDouble = dataEasy.isGateIdDoubleDrop(self.sceneID),
			onNode = function(node)
				local x,y = node:xy()
				node:xy(x, y+3)
				node:hide()
					:z(2)
				transition.executeSequence(node, true)
					:delay(0.5)
					:func(function()
						node:show()
					end)
					:done()
				if data[index].isFirst then
					addResToItem(node, "city/adventure/endless_tower/icon_st.png")
				end
			end,
		},
	}
	bind.extend(self, item, binds)
	self.awardsList:setItemsMargin(25)
	self.awardsList:pushBackCustomItem(item)
	self.awardsList:setScrollBarEnabled(false)
	transition.executeSequence(self.awardsList)
		:delay(0.1)
		:func(function()
			if index < table.length(data) then
				self:showItem(index + 1, data)
			end
		end)
		:done()
end

function BraveChallengeWinView:onQuitClick()
	gGameUI:switchUI("city.view")
end

return BraveChallengeWinView