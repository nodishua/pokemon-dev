local CardCharacterView = class("CardCharacterView", Dialog)

local function setTxtColor(txt, content)
	txt:setString(content)
	if content == 0.9 then
		text.addEffect(txt, {color=cc.c4b(241, 59, 84, 255)})
	elseif content == 1.1 then
		text.addEffect(txt, {color=cc.c4b(96, 196, 86, 255)})
	else
		text.addEffect(txt, {color=cc.c4b(91, 84, 91, 255)})
	end
end

CardCharacterView.RESOURCE_FILENAME = "card_character.json"
CardCharacterView.RESOURCE_BINDING = {
	["titleTxt"] = {
		binds = {
			event = "effect",
			data = {outline={color=ui.COLORS.OUTLINE.RED}}
		}
	},
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["item"] = "characterItem",
	["subList"] = "characterSubList",
	["imgMark"] = "imgMark",
	["list"] = {
		varname = "characterList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				data = bindHelper.self("characterData"),
				columnSize = 9,
				item = bindHelper.self("characterSubList"),
				cell = bindHelper.self("characterItem"),
				onCell = function(list, node, k, v)
					node:get("select"):visible(v.select == true)
					node:get("img"):visible(v.showCurr == true)
					local t = list:getIdx(k)
					if t.col % 2 ~= 0 then
						node:get("bg"):hide()
					end
					node:get("name"):setString(v.name or "")
					for i=1,5 do
						setTxtColor(node:get("txt" .. i), v["txt" .. i] or "")
					end
				end,
				asyncPreload = 27,
			},
		},
	},
}

function CardCharacterView:onCreate(id, currSelect)
	local title = {7,9,8,10,13}
	local characterData = {}
	local selectList = csv.cards[id].chaRecom
	for i,v in ipairs(csv.character) do
		local data = {}
		data.name = v.name
		data.showCurr = i == currSelect
		for a,b in ipairs(title) do
			if v.attrMap and v.attrMap[b] then
				local num = string.match(v.attrMap[b],"%d+")
				data["txt"..a] = num/100
			else
				data["txt"..a] = "-"
			end
		end
		for k,v in pairs(selectList) do
			if v == i then
				data.select = true
			end
		end
		table.insert(characterData, data)
	end
	for i=1,27 do
		if #characterData < 27 then
			table.insert(characterData, {})
		else
			break
		end
	end
	self.characterData = characterData

	Dialog.onCreate(self)
end

return CardCharacterView
