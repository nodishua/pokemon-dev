

local TYPE = {
	--星级
	STAR = 1,
	--觉醒
	AWAKE = 2
}
local LINE_NUM = 50
local LINE_HIGHT = 50
local FIVE = 5
local function setName(data, textNode)
	local cfg = csv.equips[data.equip_id]
	local baseName
	if data.awake ~= 0  then
		baseName = cfg.name1..gLanguageCsv["symbolRome"..data.awake]
	else
		baseName = cfg.name0
	end
	local currQuality, currNumStr = dataEasy.getQuality(data.advance)
	textNode:text(baseName..currNumStr)
	text.addEffect(textNode,{color = currQuality == 1 and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.QUALITY[currQuality]})
end

local signetInfo = class("signetInfo", Dialog)
signetInfo.RESOURCE_FILENAME = "card_equip_signet_info.json"
signetInfo.RESOURCE_BINDING = {
    ["baseNode"] = "baseNode",
    ["item"] = "item",
    ["baseNode.tip"] = "tip",
    ["baseNode.name"] = "name",
    ["baseNode.degree"] = "degree",
    ["baseNode.list"] = {
        varname = "list",
        binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("advanceDatas"),
				item = bindHelper.self("item"),
				-- padding = 10,
                onItem = function(list, node, k, v)
                    local childs = node:multiget("text1","condition","detail")
					local isActive = v.signetAdvance >= v.advance
                    childs.text1:text(gLanguageCsv.signetInfoBeiDong .. k)
                    childs.condition:text("("..v.condition..")")
                    local t1,t2 = math.modf(#v.attrDetail/LINE_NUM)
                    t1 = t2 == 0 and t1 or t1 + 1
                    childs.detail:height(LINE_HIGHT * t1)
                    node:height(node:height() + LINE_HIGHT * (t1 - 2) )
                    childs.text1:y(childs.text1:y() + LINE_HIGHT * (t1 - 2) )
                    childs.condition:y(childs.condition:y() + LINE_HIGHT * (t1 - 2) )
                    childs.detail:y(childs.detail:y() + LINE_HIGHT * (t1 - 2) / 2)
                    childs.detail:text(v.attrDetail)
                    adapt.oneLinePos(childs.text1, childs.condition, cc.p(10,0))
                    if isActive and not v.visible then
                        childs.detail:color(cc.c3b(91,84,91))
                        childs.condition:visible(false)
                    end
                end,
			},
		},
    },
    ["baseNode.icon"] = {
        varname =  "equip",
        binds = {
			event = "extend",
	        class = "equip_icon",
	        props = {
	            data = bindHelper.self("leftData"),
	            onNode = function(panel)
                    local childs = panel:multiget("star", "txtLv", "txtLvNum", "imgArrow")
                    childs.imgArrow:visible(false)
	            end,
	        }
        }
    },

}

function signetInfo:onCreate(leftData)
    self.item:hide()
    self.list:size(840,972)
    self.leftData = leftData
    local cfg = csv.equips[leftData.equip_id]
    setName(self.leftData, self.name)
    local t = {}
    self.tip:text(gLanguageCsv.signetInfoTip)
    for k=1,cfg.signetAdvanceMax do
        for i,v in csvPairs(csv.base_attribute.equip_signet_advance) do
            if leftData.signet_advance == cfg.signetAdvanceMax then
                if v.advanceIndex == cfg.advanceIndex and v.advanceLevel == leftData.signet_advance - 1 then
                    self.degree:text(v.advanceName.. " " .. FIVE .. gLanguageCsv.signetLevel)
                end
            else
                if v.advanceIndex == cfg.advanceIndex and v.advanceLevel == leftData.signet_advance then
                    self.degree:text(v.advanceName.." "..(leftData.signet - leftData.signet_advance * FIVE) .. " " .. gLanguageCsv.signetLevel)
                end
            end

            if v.advanceIndex == cfg.advanceIndex and v.advanceLevel == k then
                local limitTip
                local detail = {}
                for j=1,math.huge do
                    local signetAttr = v["attrType"..j]
                    if not signetAttr or signetAttr == 0 then
                        break
                    end
                    local attrTypeStr = game.ATTRDEF_TABLE[signetAttr]
                    local str = "attr".. string.caption(attrTypeStr)
                    table.insert(detail,{
                        name = gLanguageCsv[str],
                        num = dataEasy.getAttrValueString(signetAttr, v["attrNum"..j])
                    })
                end
                local strAttr = ""
                for i=1,#detail do
                    strAttr = strAttr..detail[i].name.."+"..detail[i].num.."  "
                end
                local visible = false
                --需要2星
                local limitTip
                if v.advanceLimitType == TYPE.STAR then
                    limitTip = string.format(gLanguageCsv.needEquipStar, v.advanceLimitNum)
                    if leftData.star < v.advanceLimitNum then
                        visible = true
                    end
                elseif v.advanceLimitType == TYPE.AWAKE then
                    limitTip = gLanguageCsv.needEquipAwake..gLanguageCsv["symbolRome"..v.advanceLimitNum]
                    if leftData.awake < v.advanceLimitNum then
                        visible = true
                    end
                end
                local scene = ""
                for k,val in csvMapPairs(v.sceneType) do
                    local num = val
                    local text = game.SCENE_TYPE_STRING_TABLE[num]
                    scene = scene..gLanguageCsv[text]
                    if k < table.getn(v.sceneType) then
                        scene = scene .. gLanguageCsv.signetAnd
                    end
                end

                table.insert(t, {
                    advance = k,
                    condition = limitTip,
                    attrDetail = string.format(gLanguageCsv.signetInfoIn,scene) ..strAttr,
                    signetAdvance = leftData.signet_advance,
                    visible = visible
                })
            end
        end
    end

    self.advanceDatas = t
    self.list:xy(20,50)
    self.list:size(750,570)


    Dialog.onCreate(self, {noBlackLayer = true,clickClose = true})


end

return signetInfo