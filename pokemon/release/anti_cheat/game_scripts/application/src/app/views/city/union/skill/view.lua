-- @date:   2019-06-10
-- @desc:   公会修炼中心

local function setCostTxt(childs, myCoin, needCoin)
	childs.cost:text(needCoin)
	local coinColor = (myCoin >= needCoin) and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.RED
	text.addEffect(childs.cost, {color = coinColor})
	adapt.oneLinePos(childs.cost, childs.costNote, cc.p(8,0), "right")
	adapt.oneLinePos(childs.cost, childs.costIcon, cc.p(18,0))
end

local function createRichTxt(str, parent)
	parent:removeAllChildren()
	return rich.createByStr(str, 40)
			:anchorPoint(0, 0.5)
			:addTo(parent, 6)
end

local UnionSkillView = class("UnionSkillView", Dialog)

UnionSkillView.RESOURCE_FILENAME = "union_skill.json"
UnionSkillView.RESOURCE_BINDING = {
	["btnClose"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "item",
	["subList"] = "subList",
	["list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("skillDatas"),
				columnSize = 3,
				margin = 0,
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				itemAction = {isAction = true},
				onCell = function(list, node, k, v)
					node:get("name"):text(v.name)
					node:get("select"):visible(v.select == true)
					node:get("level"):text("Lv"..v.level):visible(v.unlocked == 1)
					text.addEffect(node:get("level"), {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
					node:get("mask"):visible(v.unlocked == 2)
					node:get("icon"):texture(v.icon)
					bind.touch(list, node, {methods = {ended = functools.partial(list.itemClick, list:getIdx(k), v)}})
				end,
				asyncPreload = 12,
				onAfterBuild = function(list)
					list.afterBuild()
				end,
			},
			handlers = {
				itemClick = bindHelper.self("onFrameItemClick"),
				afterBuild = bindHelper.self("onAfterBuild"),
			},
		},
	},
	["rightPanel.btnPractice"] = {
		varname = "btnPractice",
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onBtnPractice")}
		},
	},
	["rightPanel"] = "rightPanel",
	["maskPanel"] = "maskPanel"
}

function UnionSkillView:onCreate(params)
	self:initModel()
	self.selectSkill = idler.new(1)
	self.skillDatas = idlers.new()
	idlereasy.when(self.unionSkills, function(_, unionSkills)
		local tmpData = {}
		for k,v in csvPairs(csv.union.union_skill) do
			local unlocked = unionSkills[k] and 1 or 2
			if self.unionLevel:read() < v.needGuildLv then
				unlocked = 2
			end
			table.insert(tmpData,{
				id = k,
				unlocked = unlocked,
				name = v.name,
				icon = v.icon,
				level = unionSkills[k] or 0,
				sort = v.sort,
			})
		end
		table.sort(tmpData,function(a,b)
			if a.sort == b.sort then
				return a.id < b.id
			end
			return a.sort < b.sort
		end)
		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.skillDatas:update(tmpData)
		self.selectSkill:set(self.selectSkill:read(), true)
	end)
	idlereasy.any({self.coin3, self.selectSkill}, function(_, coin3, selectSkill)
		self:setRightPanel(selectSkill, coin3)
	end)
	self.selectSkill:addListener(function(val, oldval, idler)
		if self.skillDatas:atproxy(oldval) then
			self.skillDatas:atproxy(oldval).select = false
		end
		self.skillDatas:atproxy(val).select = true
	end)
	self.playAnimation = idler.new(2)
	idlereasy.when(self.playAnimation, function (_, playAnimation)
		local effectPanel = self.rightPanel:get("effectPanel")
		effectPanel:removeAllChildren()
		if playAnimation == 1 then
			local size = effectPanel:getContentSize()
			widget.addAnimationByKey(effectPanel, "effect/jineng.skel", nil, "effect", 555)
				:xy(size.width/2, size.height/2)
				:scale(1.4)
		end
	end)
	Dialog.onCreate(self)
end

function UnionSkillView:initModel()
	self.unionSkills = gGameModel.role:getIdler("union_skills")
	local unionInfo = gGameModel.union
	--公会当前等级
	self.unionLevel = unionInfo:getIdler("level")
	self.coin3 = gGameModel.role:getIdler("coin3")
end

function UnionSkillView:onBtnPractice()
	if self.lackCoin3 == true then
		gGameUI:showTip(gLanguageCsv.cuildCurrencyNotEnough)
		return
	end

	gGameApp:requestServer("/game/union/skill",function()
		self.playAnimation:set(1, true)
		audio.playEffectWithWeekBGM("square.mp3")
	end, self.skillDatas:atproxy(self.selectSkill:read()).id)
end

function UnionSkillView:onFrameItemClick(list, t, v)
	self.selectSkill:set(t.k)
end

function UnionSkillView:setRightPanel(skinId, myCoin)
	local childs = self.rightPanel:multiget(
		"title",
		"pos",
		"icon",
		"level",
		"mask",
		"levelOld",
		"levelNew",
		"addOld",
		"addNew",
		"limit",
		"cost",
		"costNote",
		"costIcon",
		"condition",
		"coin",
		"coinBg",
		"coinIcon",
		"btnPractice",
		"limitNote"
	)
	childs.coin:text(myCoin)
	local bgX = myCoin < 100000 and 264 or (90 + childs.coin:size().width)*1.33
	childs.coinIcon:x(childs.coinBg:x() - bgX*0.75 + 20)
	childs.coinBg:size(bgX, 80)

	local skillData = self.skillDatas:atproxy(skinId)
	--技能经验表
	local csvSkillLevel = gUnionSkillCsv[skinId]
	local csvSkill = csv.union.union_skill[skinId]
	childs.level:text("Lv"..skillData.level):visible(skillData.unlocked == 1)
	text.addEffect(childs.level, {outline={color=ui.COLORS.OUTLINE.DEFAULT}})
	--公会经验表
	local csvUnionLevel = csv.union.union_level
	--公会最大等级
	local unionMaxLevel = csvSize(csvUnionLevel)
	--当前公会等级 限制的技能等级
	local limitLevel = csvUnionLevel[self.unionLevel:read()].skillLvMax
	--技能满级了
	local isLevelMax = skillData.level >= csvUnionLevel[unionMaxLevel].skillLvMax
	local nextLevel = isLevelMax and skillData.level or skillData.level + 1
	childs.title:text(skillData.name)
	childs.icon:texture(skillData.icon)
	childs.mask:visible(skillData.unlocked == 2)

	childs.levelOld:text(skillData.level)
	childs.levelNew:text(nextLevel)
	childs.addOld:text(dataEasy.getAttrValueString(csvSkill.attrType,csvSkillLevel[skillData.level].attrValue))
	childs.addNew:text(dataEasy.getAttrValueString(csvSkill.attrType, csvSkillLevel[nextLevel].attrValue))

	local needCoin = csvSkillLevel[skillData.level].cost.coin3
	--公会币不足
	self.lackCoin3 = myCoin < needCoin
	--达到限制等级 公会等级提高才能升级
	local limitReached = skillData.level >= limitLevel
	local limitLevelStr = ""
	if not isLevelMax then
		limitLevelStr = "  "..gLanguageCsv.unionSkillLimitTip
	end
	childs.limit:text(limitLevel..limitLevelStr)
	nodetools.invoke(self.rightPanel, {"levelNew", "addNew", "addArrow", "levelArrow"}, isLevelMax and "hide" or "show")
	local notTouch = skillData.unlocked == 2 or isLevelMax or limitReached
	uiEasy.setBtnShader(childs.btnPractice, childs.btnPractice:get("title"), notTouch and 2 or 1)

	setCostTxt(childs, myCoin, needCoin)
	self:setUnlockTxt(childs, skinId)
end
--设置解锁条件文本
function UnionSkillView:setUnlockTxt(childs, skinId)
	local skillData = self.skillDatas:atproxy(skinId)
	local csvSkill = csv.union.union_skill[skillData.id]
	local typ = csvSkill.attrNatureType
	local titleTxt = (typ == 0) and gLanguageCsv.allSprite or string.format(gLanguageCsv.someSprite, gLanguageCsv[game.NATURE_TABLE[typ]])
	createRichTxt(string.format(gLanguageCsv.toProvideAddition,titleTxt, getLanguageAttr(csvSkill.attrType)), childs.pos)

	local condition = ""
	if csvSkill.needGuildLv > 0 then
		condition = string.format(gLanguageCsv.guildReachLevelUnlock,csvSkill.needGuildLv)
	end
	if csvSkill.preSkill[1] ~= nil and (self.skillDatas:atproxy(csvSkill.preSkill[1]).level < csvSkill.preSkill[2]) then
		condition = string.format(gLanguageCsv.skillReachedLevelUnlock,self.skillDatas:atproxy(csvSkill.preSkill[1]).name, csvSkill.preSkill[2])
	end
	childs.condition:text(condition)
		:visible(skillData.unlocked == 2)
		:x(childs.limitNote:x())
end
function UnionSkillView:onAfterBuild()
	uiEasy.setBottomMask(self.list, self.maskPanel)
end

return UnionSkillView