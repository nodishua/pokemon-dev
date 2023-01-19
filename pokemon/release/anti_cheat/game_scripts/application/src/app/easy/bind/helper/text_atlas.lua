--
-- @Data 2019-2-26 16:10:37
-- @desc textAtlas辅助类
--

local textAtlasHelper = {}

-- 默认的图片配置
-- @rect 每个字的宽度 type{val=width}
-- @changeText 需要被转换的字符串
local _defaultImage = {
	-- 一般客户端使用
	card_lv = {
		width = 45,
		height = 60,
		rect = {['1'] = 29},
	},
	zhanli = {
		width = 58,
		height = 64,
		rect = {['1'] = 32},
	},
	craft = {
		width = 57,
		height = 86,
		rect = {['1'] = 36,
				['0']=47, ['2']=47, ['3']=47, ['4']=47, ['5']=47, ['6']=47, ['7']=47, ['8']=47, ['9']=47},
		changeText = '-',
	},
	cross_craft = {
		width = 54,
		height = 79,
		rect = {['1'] = 44, ['<'] = 40},
		changeText = '-',
	},
	-- 一般战斗内使用
	bj = {
		width = 48,
		height = 61,
		rect = {['1'] = 30,
				['0']=44, ['2']=44, ['3']=44, ['4']=44, ['5']=44, ['6']=44, ['7']=44, ['8']=44, ['9']=44},
		changeText = '-',
	},
	kz = {
		width = 30,
		height = 43,
		rect = {['1'] = 23, ['<'] = 28, [';'] = 17, ['='] = 17, [':'] = 15,
				['0']=26, ['2']=26, ['3']=26, ['4']=26, ['5']=26, ['6']=26, ['7']=26, ['8']=26, ['9']=26},
		changeText = '.(x)',
	},
	nqjl = {
		width = 17,
		height = 19,
		rect = {['1'] = 11,
				['0']=13, ['2']=13, ['3']=13, ['4']=13, ['5']=13, ['6']=13, ['7']=13, ['8']=13, ['9']=13},
		changeText = '+',
	},
	ptsh = {
		width = 36,
		height = 45,
		rect = {['1'] = 25,
				['0']=32, ['2']=32, ['3']=32, ['4']=32, ['5']=32, ['6']=32, ['7']=32, ['8']=32, ['9']=32},
		changeText = '-',
	},
	round = {
		width = 26,
		height = 28,
		rect = {['1'] = 16},
	},
	zlsz = {
		width = 36,
		height = 45,
		rect = {['1'] = 25,
				['0']=32, ['2']=32, ['3']=32, ['4']=32, ['5']=32, ['6']=32, ['7']=32, ['8']=32, ['9']=32},
		changeText = '+',
	},
	zsh = {
		width = 48,
		height = 61,
		rect = {['1'] = 33,
				['0']=44, ['2']=44, ['3']=44, ['4']=44, ['5']=44, ['6']=44, ['7']=44, ['8']=44, ['9']=44},
	},
	zzl = {
		width = 48,
		height = 61,
		rect = {['1'] = 18,
				['0']=44, ['2']=44, ['3']=44, ['4']=44, ['5']=44, ['6']=44, ['7']=44, ['8']=44, ['9']=44},
	},
	boss = {
		width = 32,
		height = 39,
		rect = {['1'] = 18, ['x']=26,
				['0']=24, ['2']=24, ['3']=24, ['4']=24, ['5']=24, ['6']=24, ['7']=24, ['8']=24, ['9']=24},
		changeText = 'x',
	},
	lv_big = {
		width = 98,
		height = 125,
		rect = {['1'] = 68,
				['0']=82, ['2']=82, ['3']=82, ['4']=82, ['5']=82, ['6']=82, ['7']=82, ['8']=82, ['9']=82},
	},
	frhd = {
		width = 132,
		height = 165,
		rect = {['1'] = 75},
	},
	frhd_num = {
		width = 83,
		height = 78,
		rect = {['1'] = 65},
	},
	online_fight_battle_cutdown = {
		width = 59,
		height = 91,
		rect = {['0']=59,
				['1']=59, ['2']=59, ['3']=59, ['4']=59, ['5']=59, ['6']=59, ['7']=59, ['8']=59, ['9']=59},
	},
}


function textAtlasHelper.findFileInfoByPathName(pathName)
	if not pathName then
		return
	end
	return clone(_defaultImage[pathName])
end

return textAtlasHelper