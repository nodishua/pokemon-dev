#!/usr/bin/python
# -*- coding: utf-8 -*-

import re
import os

invalid_cards = set()
invalid_cards_pattern = '|'.join(invalid_cards)
invalid_frags = set()
invalid_frags_pattern = '|'.join(invalid_frags)

invalid_draw_cards = set()
invalid_draw_cards_pattern = '|'.join(invalid_draw_cards)
invalid_draw_frags = set()
invalid_draw_frags_pattern = '|'.join(invalid_draw_frags)

def draw_items_lib_cardWeightMap(value):
	if invalid_draw_cards:
		# <{id=\d+};\d+>;
		pattern = "<{id=(%s)};\d+>;" % invalid_draw_cards_pattern
		value = re.sub(pattern, '', value)
		# ;*<{id=\d+};\d+>
		pattern = ";*<{id=(%s)};\d+>" % invalid_draw_cards_pattern
		value = re.sub(pattern, '', value)
	return value

def draw_items_lib_weightList(value):
	if invalid_draw_frags:
		# <\d+;\d+;\d+>;
		pattern = "<(%s);\d+;\d+>;" % invalid_draw_frags_pattern
		value = re.sub(pattern, '', value)
		# ;*<\d+;\d+;\d+>
		pattern = ";*<(%s);\d+;\d+>" % invalid_draw_frags_pattern
		value = re.sub(pattern, '', value)
	return value

def shop_itemWeightMap(value):
	if invalid_frags:
		# \d+=\d+;
		pattern = "(%s)=\d+;" % invalid_frags_pattern
		value = re.sub(pattern, '', value)
		# ;*\d+=\d+
		pattern = ";*(%s)=\d+" % invalid_frags_pattern
		value = re.sub(pattern, '', value)
	return value

def draw_preview_card(value):
	if invalid_draw_cards:
		if value[0] != '<' or value[-1] != '>':
			raise Exception('must start with < and end with >')
		value = value[1:-1]
		items = value.split(';')
		items = [x for x in items if x not in invalid_draw_cards]
		value = "<%s>" % ';'.join(items)
	return value

def draw_preview_item(value):
	if invalid_draw_frags:
		if value[0] != '<' or value[-1] != '>':
			raise Exception('must start with < and end with >')
		value = value[1:-1]
		items = value.split(';')
		items = [x for x in items if x not in invalid_draw_frags]
		value = "<%s>" % ';'.join(items)
	return value

# key == cardID
def role_logo_current_row_invalid(key, value, default):
	if not value:
		value = default
	if not value:
		return False
	return value in invalid_cards

# key == cards
def card_battle_recommend_current_row_invalid(key, value, default):
	if not value:
		value = default
	if not value:
		return False
	if value[0] != '<' or value[-1] != '>':
		raise Exception('must start with < and end with >')
	value = value[1:-1]
	items = value.split(';')
	for item in items:
		if item in invalid_cards:
			return True
	return False

# key == cardID
def pokedex_current_row_invalid(key, value, default):
	if not value:
		value = default
	if not value:
		return False
	return value in invalid_cards

# key == cardID
def clone_monster_current_row_invalid(key, value, default):
	if not value:
		value = default
	if not value:
		return False
	return value in invalid_cards

# key == itemID
def stable_drops_current_row_invalid(key, value, default):
	if not value:
		value = default
	if not value:
		return False
	return value in invalid_frags

def item_specialArgsMap(value):
	if invalid_cards:
		# cards
		# choose\d+={card={id=\d+}};
		pattern = "choose\d+={card={id=(%s)}};" % invalid_cards_pattern
		value = re.sub(pattern, '', value)
		# ;*choose\d+={card={id=\d+}}
		pattern = ";*choose\d+={card={id=(%s)}}" % invalid_cards_pattern
		value = re.sub(pattern, '', value)

	if invalid_frags:
		# frags
		# choose\d+={\d+=\d+};
		pattern = "choose\d+={(%s)=\d+};" % invalid_frags_pattern
		value = re.sub(pattern, '', value)
		# ;*choose\d+={\d+=\d+}
		pattern = ";*choose\d+={(%s)=\d+}" % invalid_frags_pattern
		value = re.sub(pattern, '', value)
	return value

def random_drops_itemMap(value):
	if invalid_frags:
		v = value[1:-1].split(';')
		v = [x.strip() for x in v]
		v = filter(lambda x: x.split('=')[0] not in invalid_frags, v)
		value = '{%s}' % ';'.join(v)
	return value

filter_rules = {
	'draw_items_lib': {
		'cardWeightMap': draw_items_lib_cardWeightMap,
		'weightList': draw_items_lib_weightList,
	},
	'frag_shop': {
		'itemWeightMap': shop_itemWeightMap,
	},
	'mystery_shop': {
		'itemWeightMap': shop_itemWeightMap,
	},
	'equip_shop': {
		'itemWeightMap': shop_itemWeightMap,
	},
	'fix_shop': {
		'itemWeightMap': shop_itemWeightMap,
	},
	'union/union_shop': {
		'itemWeightMap': shop_itemWeightMap,
	},
	'random_tower/shop': {
		'itemWeightMap': shop_itemWeightMap,
	},
	'fishing/shop': {
		'itemWeightMap': shop_itemWeightMap,
	},
	'explorer/explorer_shop': {
		'itemWeightMap': shop_itemWeightMap,
	},
	'draw_preview': {
		'card': draw_preview_card,
		'item': draw_preview_item,
	},
	'items': {
		'specialArgsMap': item_specialArgsMap,
	},
	'random_drops': {
		'itemMap': random_drops_itemMap,
	},
	'scene_conf': {
		'dropIds': random_drops_itemMap,
	}
}

current_row_invalid_rules = {
	'role_logo': ('cardID', role_logo_current_row_invalid),
	'card_battle_recommend': ('cards', card_battle_recommend_current_row_invalid),
	# 'pokedex': ('cardID', pokedex_current_row_invalid), # 图鉴不再处理
	'clone/monster': ('cardID', clone_monster_current_row_invalid),
	'stable_drops': ('itemID', stable_drops_current_row_invalid),
}

related_files = set(['%s.csv' % x for x in filter_rules.keys() + current_row_invalid_rules.keys()])

def getCurrentRowInvalidKeyFunc(filename):
	if filename not in current_row_invalid_rules:
		return None, None
	return current_row_invalid_rules[filename]

def filterValue(filename, key, value):
	if not value:
		return value
	if filename not in filter_rules:
		return value
	if key not in filter_rules[filename]:
		return value
	return filter_rules[filename][key](value)

def setInvalidCards(cards):
	global invalid_cards, invalid_cards_pattern
	invalid_cards = set(cards)
	invalid_draw_cards = invalid_cards
	invalid_cards_pattern = '|'.join(invalid_cards)

def setInvalidFrags(frags):
	global invalid_frags, invalid_frags_pattern
	invalid_frags = set(frags)
	invalid_draw_frags = invalid_frags
	invalid_frags_pattern = '|'.join(invalid_frags)

def setInvalidDrawCards(cards):
	global invalid_draw_cards, invalid_draw_cards_pattern
	invalid_draw_cards = invalid_cards | set(cards)
	invalid_draw_cards_pattern = '|'.join(invalid_draw_cards)

def setInvalidDrawFrags(frags):
	global invalid_draw_frags, invalid_draw_frags_pattern
	invalid_draw_frags = invalid_frags | set(frags)
	invalid_draw_frags_pattern = '|'.join(invalid_draw_frags)

def appendRelatedFiles(fileList, root):
	paths = [os.path.relpath(path, root) for path in fileList]
	for name in related_files:
		if name not in paths:
			paths.append(name)
	paths = [os.path.join(root, path) for path in paths]
	return paths

if __name__ == "__main__":
	invalid_cards = [str(x) for x in [1, 21, 52,]]
	invalid_cards_pattern = '|'.join(invalid_cards)
	value = "<<{id=1};100>;<{id=11};100>;<{id=21};100>;<{id=52};100>>"
	print draw_items_lib_cardWeightMap(value)

	invalid_frags = [str(x) for x in [20261, 20391]]
	invalid_frags_pattern = '|'.join(invalid_frags)
	value = "<<11;100;1>;<20261;100;1>;<20391;100;1>;<14;100;1>;<3006;100;1>>"
	print draw_items_lib_weightList(value)
	value = "<<11;100;1>;<20261;100;1>;<20391;100;1>>"
	print draw_items_lib_weightList(value)

	value = "{20261=100;20331=100;20391=100}"
	print shop_itemWeightMap(value)
	value = "{20261=100;20391=100}"
	print shop_itemWeightMap(value)
	value = "{20261=100}"
	print shop_itemWeightMap(value)
	value = "{20331=100}"
	print shop_itemWeightMap(value)

	value = "<101;1071;11;52;1171;121;1221;1231;52>"
	print draw_preview_card(value)

	value = "{choose1={21221=50};choose2={20391=50};choose3={21241=50};choose4={20721=50};choose5={20731=50};choose6={20391=50}}"
	print item_specialArgsMap(value)

	value = "{choose1={card={id=52}};choose2={card={id=1971}};choose3={card={id=52}}}"
	print item_specialArgsMap(value)
