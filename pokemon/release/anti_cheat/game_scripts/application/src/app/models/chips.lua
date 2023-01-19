--
-- Copyright (c) 2014 YouMi Information Technology Inc.
-- Copyright (c) 2016 TianJi Information Technology Inc.
--
-- Gem
--

local Chip = class("Chip", require("app.models.base"))

local Chips = class("Chips", require("app.models.bases"))

function Chips:newModel(t)
	return Chip.new(self.game):init(t)
end

return Chips