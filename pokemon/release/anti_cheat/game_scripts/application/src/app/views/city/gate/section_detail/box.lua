
--关卡宝箱
local GateSectionBoxView = class("GateSectionBoxView", Dialog)

GateSectionBoxView.RESOURCE_FILENAME = "gate_section_box.json"
GateSectionBoxView.RESOURCE_BINDING = {
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		}
	},
	["title.textGateName"] = "textGateName",
	["title.textChapter"] = "textChapter",
	["leftTop.textStarNum"] = {
		binds = {
			{
				event = "text",
				idler = bindHelper.self("starNum")
			},
			{
				event = "effect",
				data = {outline={color=ui.COLORS.OUTLINE.DEFAULT, size = 4}}
			},
		}
	},
	["btnGet.textNote"] = "sureBtnTitle",
	["btnGet"] = {
		varname = "sureBtn",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onSureBtn")}
		}
	},
	["item1"] = "item",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("awardDatas"),
				item = bindHelper.self("item"),
				dataOrderCmp = function (a, b)
					return dataEasy.sortItemCmp(a, b)
				end,
				onItem = function(list, node, k, v)
					local size = node:size()
					local binds = {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
							},
						},
					}
					bind.extend(list, node, binds)
				end,
				onAfterBuild = function(list)
					list:adaptTouchEnabled()
						:setItemAlignCenter()
				end,
			},
		},
	},
	["bar"] = {
		varname = "bar",
		binds = {
			event = "extend",
 			class = "loadingbar",
			props = {
				data = bindHelper.self("percent"),
				maskImg = "common/icon/mask_bar_red.png"
			},
		},
	},
	["item"] = "itemImg1",
}

function GateSectionBoxView:onCreate(sectionId)
	self:initModel()
	self.sectionId = sectionId
	local worldCsv = csv.world_map[sectionId]
	self.titleTxt = worldCsv.name

	local boxNum = 0
	local maxStar = 0
	for i,v in ipairs(worldCsv.starAwardConds) do
		if v > 0 then
			boxNum = boxNum + 1
			maxStar = v
		end
	end
	local gateStar = self.gateStar:read()
	local starNum = 0
	for k,v in ipairs(worldCsv.seq) do
		if gateStar[v] then
			starNum = starNum + gateStar[v].star
		end
	end
	self.titleCharpter = string.format(gLanguageCsv.getaSectionBoxTitle,tonumber(sectionId) % 100 - 10)

	self.textGateName:text(self.titleTxt)
	self.textChapter:text(self.titleCharpter)
	adapt.oneLinePos(self.textChapter, self.textGateName, cc.p(18, 0), "left")

	local boxStarMax = worldCsv.starAwardConds[itertools.size(worldCsv.starAwardConds)]
	self.selectIndex = idler.new(1)
	self.starNum = idler.new(starNum.."/"..maxStar)
	self.percent = idler.new(starNum/maxStar*100)
	for k,v in ipairs(worldCsv.starAwardConds) do
		if v > 0 then
			local itemImg = self.itemImg1:clone():tag(k):addTo(self.bar, 10, "item"..k):xy(self.bar:size().width*v/boxStarMax,100):show()
		 	itemImg:get("disableBg"):visible(starNum < v)
		 	itemImg:get("imgBG"):visible(starNum >= v)
		 	itemImg:get("disableStar"):visible(starNum < v)
		 	itemImg:get("imgStar"):visible(starNum >= v)
		 	itemImg:get("textNum"):text(v)
		 	text.addEffect(itemImg:get("textNum"), {outline={color=ui.COLORS.OUTLINE.DEFAULT, size = 4}})
		 	bind.touch(node, itemImg, {methods = {ended = function()
				self.selectIndex:set(k)
			end}})
		end
	end

	-- 可领取＞未达成＞已领取
	-- 默认选中可领取的最左选项；没有可领取的话就选择未达成的最左；全都是已领取的话就已领取的最左
	idlereasy.when(self.mapStar,function(_,mapStar)
		-- 0 未达成  1 可领取  2 已领取
		local sectionMap = mapStar[sectionId] and mapStar[sectionId].star_award or {}
		local minIdx, canReceiveIdx, notReachIdx
		for i,v in ipairs(worldCsv.starAwardConds) do
			if v > 0 then
				if not minIdx then
					minIdx = i
				end
				if sectionMap[i] == 1 and not canReceiveIdx then
					canReceiveIdx = i
				end
				if sectionMap[i] == 0 and not notReachIdx then
					notReachIdx = i
				end
				self.bar:get(i, "imgBlack"):visible(sectionMap[i] == 2)
				self.bar:get(i, "imgTick"):visible(sectionMap[i] == 2)
			end
		end
		self.selectIndex:set(canReceiveIdx or notReachIdx or minIdx)
	end)

	idlereasy.any({self.mapStar, self.selectIndex},function(_,mapStar, selectIndex)
		local sectionMap = mapStar[sectionId] and mapStar[sectionId].star_award or {}
		self.sureBtn:setTouchEnabled(sectionMap[selectIndex] == 1)
		cache.setShader(self.sureBtn, false,(sectionMap[selectIndex] == 1) and "normal" or "hsl_gray")
		self.sureBtnTitle:text((sectionMap[selectIndex] == 2) and gLanguageCsv.received or gLanguageCsv.spaceReceive)
		text.addEffect(self.sureBtnTitle, {GLOW={color=ui.COLORS.GLOW.WHITE}})
	end)

	self.awardDatas = idlertable.new()
	idlereasy.when(self.selectIndex,function(_,selectIndex)
		for i,v in ipairs(worldCsv.starAwardConds) do
			if v > 0 then
				self.bar:get(i, "imgSel"):visible(i==selectIndex)
			end
		end
		local awardDatas = {}
		local mapData = dataEasy.getCfgByKey(worldCsv.starAwardIDs[selectIndex]).specialArgsMap
		for k,v in csvMapPairs(mapData) do
		 	table.insert(awardDatas,{num = v, key = k})
		end

		self.awardDatas:set(awardDatas)
	end)

	Dialog.onCreate(self)
end

function GateSectionBoxView:initModel()
	self.gateStar = gGameModel.role:getIdler("gate_star") -- 星星数量
	self.mapStar = gGameModel.role:getIdler("map_star")--0，没有奖励 1，有奖励 2，已领取
	self.roleLv = gGameModel.role:getIdler("level")
end

function GateSectionBoxView:onSureBtn()
	gGameApp:requestServer("/game/role/map/star_award",function (tb)
		gGameUI:showGainDisplay(tb)
	end, self.sectionId, self.selectIndex)
end

return GateSectionBoxView
