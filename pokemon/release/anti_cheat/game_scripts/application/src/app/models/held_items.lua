--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- HeldItems
--

local HeldItem = class("HeldItem", require("app.models.base"))

local HeldItems = class("HeldItems", require("app.models.bases"))

function HeldItems:newModel(t)
	return HeldItem.new(self.game):init(t)
end

return HeldItems