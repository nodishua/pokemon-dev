local CardDetailedAttributeView = class("CardDetailedAttributeView", Dialog)

CardDetailedAttributeView.RESOURCE_FILENAME = "card_detailed_attribute.json"
CardDetailedAttributeView.RESOURCE_BINDING = {
	["closeBtn"] = {
		binds = {
			event = "touch",
			methods = {ended = bindHelper.self("onClose")}
		},
	},
	["list"] = "list",
}


function CardDetailedAttributeView:onCreate()
	local attrDatas = {}
	for i=1,100 do
		if not csv.note[i] then break end
		local content = csv.note[i].fmt or ""
		local txt1,txt2,pos
		pos = string.find(content, "|") or 1
		txt1 = string.sub(content, 0, pos-1)
		txt2 = string.sub(content, pos+1, string.len(content))
		table.insert(attrDatas, {str = "#C0x5B545B##L10#"..txt1.."#L00#"..txt2})
	end

	beauty.textScroll({
		list = self.list,
		strs = attrDatas,
		isRich = true,
		margin = 21,
		align = "left",
	})

	Dialog.onCreate(self)
end


function CardDetailedAttributeView:onClose()
	Dialog.onClose(self)
end

return CardDetailedAttributeView