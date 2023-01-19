#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

from framework import str2num_t
from framework.log import logger
from framework.csv import csv, ErrDefs, ConstDefs
from framework.object import ObjectBase
from game import ServerError, ClientError
from game.object import ZawakeDefs, ZawakeUnlockDefs, FragmentDefs, SceneDefs
from game.object.game.calculator import zeros
from game.object.game.gain import ObjectCostAux, ObjectGainAux

import copy
from math import ceil


# Z觉醒

class ObjectZawake(ObjectBase):
    StageMap = {}  # {(zawakeUnlockID, stage): cfg}
    LevelMap = {}  # {(zawakeID, stage, level): cfg}
    ZawakeMap = {}  # {zawakeID: markID}
    ZawakeCardMap = {}  # {zawakeID: [csvID]}
    MarkIDMap = {}  # {markID: [zawakeID]}
    BonusLevels = []  # [(exp, cfg)]
    BonusMaxLevel = 0

    @classmethod
    def classinit(cls):
        # 阶段解锁配置
        cls.StageMap = {}
        for csvID in csv.zawake.stages:
            cfg = csv.zawake.stages[csvID]
            cls.StageMap[(cfg.zawakeID, cfg.awakeSeqID)] = cfg

        # 等级配置
        cls.LevelMap = {}
        for csvID in csv.zawake.levels:
            cfg = csv.zawake.levels[csvID]
            cls.LevelMap[(cfg.zawakeID, cfg.awakeSeqID, cfg.level)] = cfg

        # z觉醒和卡牌相关
        cls.ZawakeMap = {}
        cls.ZawakeCardMap = {}
        cls.MarkIDMap = {}
        for csvID in csv.cards:
            cfg = csv.cards[csvID]
            if cfg.zawakeID != 0:
                cls.ZawakeMap[cfg.zawakeID] = cfg.cardMarkID
                cls.ZawakeCardMap.setdefault(cfg.zawakeID, []).append(cfg.id)
                cls.MarkIDMap.setdefault(cfg.cardMarkID, []).append(cfg.zawakeID)

        # z觉醒之力配置
        cls.BonusMaxLevel = max(csv.zawake.bonus.keys())
        exp = 0
        cls.BonusLevels = []
        for i in range(1, cls.BonusMaxLevel):
            # csvID代表等级，不能断
            cfg = csv.zawake.bonus[i]
            exp += cfg.exp
            cls.BonusLevels.append((exp, cfg))

    def init(self):
        self._maxAttrMap = {}  # {(markID, zawakeID): {attr: maxValue}}  和阶段的解锁、等级效果的生效相关。如果相关的属性发生变动，则需要重新计算。

        self._cardAttrAddition = {}  # {(type): (const, percent)}
        self._natureCardAttrAddition = {}  # {(nature): (const, percent)}
        self._markIDCardAttrAddition = {}  # {(markID): (const, percent)}
        self._sceneCardAttrAddition = {}  # {(markID, scene): (const, percent)}

        # 缓存已激活的加成csvID
        self._levelsBuff = set()
        self._bonusBuff = set()
        # 缓存有z觉醒技能变化的zawakeID
        self._skillsBuff = set()
        return ObjectBase.init(self)

    def set(self):
        self._zawake = self.game.role.zawake
        self._zawake_skills = self.game.role.zawake_skills
        self._zfrags = self.game.role.zfrags
        return ObjectBase.set(self)


    def strength(self, zawakeID, stage, level):
        '''
        将id为zawakeID的进度的stage阶段的等级+1
        '''
        record = self._zawake.setdefault(zawakeID, {})
        markID = self.ZawakeMap[zawakeID]
        if self.StageMap[(zawakeID, stage)].isOpen != 1:
            raise ClientError('stage closed')
        if level > ZawakeDefs.LevelMax:
            raise ClientError('stage already max level')
        elif level != record.get(stage, 0) + 1:
            raise ClientError('level error')

        # 检查阶段是否解锁 zawake/stage.csv
        cfg = self.StageMap[(zawakeID, stage)]
        for i in xrange(1, 99):
            attr = 'unlockType%d' % i
            if attr not in cfg or not cfg[attr]:
                break

            # 找到属性判断的markID
            if cfg[attr] == -1:  # 自身养成
                reqMarkID = markID
                reqZawakeID = zawakeID
            else:  # 以cfg[attr]的属性进行判断
                reqZawakeID = cfg[attr]
                reqMarkID = self.ZawakeMap[reqZawakeID]

            if not self.reqCheck(cfg['unlockLimit%d'%i], markID=reqMarkID, zawakeID=reqZawakeID):
                raise ClientError('stage locked')

        # 检查等级是否解锁
        if level > 1:
            if record.get(stage, 0) != level - 1:
                raise ClientError('level locked')
        else:
            if stage > 1 and record.get(stage - 1, 0) != ZawakeDefs.LevelMax:
                raise ClientError('level locked')

        # zawake/level.csv
        cfg = self.LevelMap[(zawakeID, stage, level)]

        # 消耗
        cost = ObjectCostAux(self.game, cfg.costItemMap)
        if not cost.isEnough():
            raise ClientError("zawake strength cost not enough")
        cost.cost(src='zawake_strength_cost')

        # 觉醒
        record[stage] = level

    def reset(self, zawakeID, auto=False):
        '''
        重置一条z觉醒进度。如果auto是false，是手动重置。否则，是自动重置，由超进化等事件触发。
        '''
        if zawakeID not in self._zawake:
            return None
        if not auto:
            cost = ObjectCostAux(self.game, {'rmb': ConstDefs.zawakeResetOneKeyCost})
            if not cost.isEnough():
                raise ClientError("zawake reset cost not enough")
            cost.cost(src='zawake_reset_cost')

        logger.info('role %s reset zawakeID=%d progress=%s' % (self.game.role.uid, zawakeID, str(self._zawake[zawakeID])))
        totalCost = {}

        for stage, maxLvl in self._zawake[zawakeID].iteritems():
            for level in xrange(1, maxLvl+1):
                for k, v in self.LevelMap[(zawakeID, stage, level)].costItemMap.iteritems():
                    totalCost[k] = totalCost.get(k, 0) + v
        del self._zawake[zawakeID]

        for card in self.game.cards.getCardsByZawakeID(zawakeID):
            card.zawake_skills = []

        totalReturn = {}
        ratio = ConstDefs.zawakeResetAutoRatio if auto else ConstDefs.zawakeResetOneKeyRatio
        for k,v in totalCost.iteritems():
            totalReturn[k] = int(ceil(v*ratio))
        return ObjectGainAux(self.game, totalReturn) if totalReturn else None

    def exchangeFrag(self, csvID, fragID, num):
        '''
        碎片兑换
        '''
        cfgConvert = csv.zawake.exchange[csvID]
        fragQuality, unitNature = FragmentDefs.getFragAttr(csv, fragID)
        costFragNum = 0

        # 特殊碎片
        for fID, fragNum in cfgConvert.needSpecialFrags:
            if fID == fragID:
                costFragNum = fragNum
                break
        if not costFragNum:
            # 条件筛选
            for quality, nature, fragNum in cfgConvert.needFrags:
                if fragQuality == quality and (nature in unitNature or nature == -1):
                    costFragNum = fragNum
                    break
        if not costFragNum:
            raise ClientError('fragID error')

        # 消耗
        costAux = ObjectCostAux(self.game, cfgConvert.costItemFrag)
        costAux += ObjectCostAux(self.game, {fragID: costFragNum})
        costAux *= num
        if not costAux.isEnough():
            raise ClientError(ErrDefs.costNotEnough)
        costAux.cost(src='zawake_convert_frag')
        return ObjectGainAux(self.game, {csvID: num})

    def exchangeCard(self, csvID, cfg):
        '''
        精灵兑换
        '''
        cfgConvert = csv.zawake.exchange[csvID]
        flag = cfgConvert.needSpecialCards and cfg.markID in cfgConvert.needSpecialCards
        if not flag:
            for rarity, nature in cfgConvert.needCards:
                # 稀有度
                if cfg.rarity != rarity:
                    continue
                # 自然属性
                if nature == -1 or nature in (cfg.natureType, cfg.natureType2):
                    flag = True
                    break
        if not flag:
            raise ClientError('zawake card error')

        # 消耗
        cost = ObjectCostAux(self.game, cfgConvert.costItemCard)
        cost.setCostCards([cfg])
        if not cost.isEnough():
            raise ClientError(ErrDefs.costNotEnough)
        cost.cost(src='zawake_convert_card')
        return ObjectGainAux(self.game, {csvID: cfgConvert.cardConvertNum})


    @staticmethod
    def calcAddition(cfg, const=None, percent=None):
        if const is None:
            const = zeros()
        if percent is None:
            percent = zeros()
        for i in xrange(1, 99):
            attr = 'attrType%d' % i
            if attr not in cfg or not cfg[attr]:
                break
            attr = cfg[attr]
            num = str2num_t(cfg['attrNum%d'%i])
            const[attr] += num[0]
            percent[attr] += num[1]
        return const, percent

    def getAttrsAddition(self, card, scene=SceneDefs.City):
        '''
        获得card卡牌的加成
        '''
        if not self._maxAttrMap:
            self._initEffectAttrAddition()

        markID = card.markID
        nature = card.natureType
        const = zeros()
        percent = zeros()
        additions = [
            (self._natureCardAttrAddition, nature),
            (self._markIDCardAttrAddition, markID),
            (self._cardAttrAddition, ZawakeDefs.CardsAll),
            (self._sceneCardAttrAddition, (markID, SceneDefs.City)),
        ]

        if scene != SceneDefs.City and (markID, scene) in self._sceneCardAttrAddition:
            additions.append((self._sceneCardAttrAddition, (markID, scene)))

        for v, typ in additions:
            addition = v.get(typ, None)
            if addition:
                const += addition[0]
                percent += addition[1]
        return const, percent

    def calcSceneAddition(self, cfg, markID):
        '''
        场景加成
        '''
        const, percent = zeros(), zeros()
        for attr, attrNum in cfg.extraAttrs.iteritems():
            num = str2num_t(attrNum)
            const[attr] += num[0]
            percent[attr] += num[1]

        flag = False
        for scene in cfg.extraScene:
            c, p = self._sceneCardAttrAddition.setdefault((markID, scene), (zeros(), zeros()))
            c += const
            p += percent
            if scene == SceneDefs.City:
                flag = True

        return flag

    def _initEffectAttrAddition(self):
        '''
        计算每一类的加成（自然、markID等）然后记录在缓存中。计算生效的技能。
        '''
        self._cardAttrAddition = {}  # {(type): (const, percent)}
        self._natureCardAttrAddition = {}  # {(nature): (const, percent)}
        self._markIDCardAttrAddition = {}  # {(markID): (const, percent)}
        self._sceneCardAttrAddition = {} # {(markID, scene): (const, percent)}

        self._levelsBuff = set()
        self._bonusBuff = set()
        self._skillsBuff = set()
        self._sceneBuff = set()
        self._zawake_skills.clear()
        for zawakeID in self._zawake:
            markID = self.ZawakeMap[zawakeID]
            for card in self.game.cards.getCardsByZawakeID(zawakeID):
                card.zawake_skills = []

        # bonus加成
        expSum = sum([self.LevelMap[(zawakeID, stage, level)].exp for zawakeID, stage, level in self.iterateStageLevel()])
        for exp, cfg in self.BonusLevels:
            if expSum < exp:
                break
            self.dynamicAdd(cfg)
            self._bonusBuff.add(cfg.id)

        # levels加成
        added = set()  # {(markID, stage, level)} 判断替换的特殊处理
        for zawakeID, stage, level in self.iterateStageLevel():
            markID = self.ZawakeMap[zawakeID]
            cfg = self.LevelMap[(zawakeID, stage, level)]

            # 普通属性加成无激活条件
            # 如果相同的markID，stage，和level有多个zawakeID的加成，最大的zawakeID以外的只加自身属性
            if (markID, stage, level) not in added:
                self.dynamicAdd(cfg, markID)
                added.add((markID, stage, level))
            else:
                self.dynamicAdd(cfg, markID, markIDOnly=True)
            self._levelsBuff.add(cfg.id)

            if cfg.extraAttrs and self.reqCheck(cfg.activeReq, markID, zawakeID):
                flag = self.calcSceneAddition(cfg, markID)
                if flag:  # 有主城加成的才加缓存记录
                     self._sceneBuff.add(cfg.id)

            if cfg.skillID and self.reqCheck(cfg.activeReq, markID, zawakeID):
                self._zawake_skills.setdefault(zawakeID, []).append(cfg.skillID)
                for card_id in self.ZawakeCardMap[zawakeID]:
                    for card in self.game.cards.getCardsByCsvID(card_id):
                        card.zawake_skills.append(cfg.skillID)
                self._skillsBuff.add(zawakeID)

    def dynamicAdd(self, cfg, markID=None, markIDOnly=False):
        '''
        把n个attrAddType遍历，每个符合的都加上相应的属性
        '''
		# cfg: level/bonus, bonus无attrAddType, 默认全体加成
        attrAddType = getattr(cfg, "attrAddType", ZawakeDefs.CardsAll)
        if attrAddType == ZawakeDefs.MarkID: # 自身系列卡牌
            if not markID:  # 这里必须有markID
                raise ServerError('bad use of zawake dynamic add')
            const, percent = self._markIDCardAttrAddition.setdefault(markID, (zeros(), zeros()))
            self.calcAddition(cfg, const=const, percent=percent)
        elif not markIDOnly:  # 其他属性也加
            if attrAddType == ZawakeDefs.CardNatureType: # 指定自然属性
                if not cfg['natureType']:
                    raise ServerError('zawake csv %d natureType error', cfg.id)

                const, percent = self._natureCardAttrAddition.setdefault(cfg['natureType'], (zeros(), zeros()))
            elif attrAddType == ZawakeDefs.CardsAll:
                const, percent = self._cardAttrAddition.setdefault(ZawakeDefs.CardsAll, (zeros(), zeros()))
            elif attrAddType == 0:  # 不加成
                pass
            self.calcAddition(cfg, const=const, percent=percent)

    def iterateStageLevel(self):
        '''
        遍历已培养的zawake的生成器
        '''
        for zawakeID in sorted(self._zawake.keys(), reverse=True):  # zawakeID会从大到小遍历
            v = self._zawake[zawakeID]
            for stage, maxLvl in v.iteritems():
                for level in xrange(1, maxLvl+1):
                    yield zawakeID, stage, level

    def reqCheck(self, reqMap, markID, zawakeID):
        '''
        检查reqMap里面的要求是否符合
        '''
        self.calcMaxAttr(markID, zawakeID)
        for reqKey, num in reqMap.iteritems():
            if self._maxAttrMap[(markID, zawakeID)][reqKey] < num:
                return False
        return True

    def calcMaxAttr(self, markID, zawakeID):
        '''
        如果_maxAttrMap里面没有markID，计算这个markID下每个精灵、每个属性的最高值。
        '''
        if (markID, zawakeID) in self._maxAttrMap:
            return

        cards = self.game.cards.getCardsByZawakeID(zawakeID)
        self._maxAttrMap[(markID, zawakeID)] = {
            ZawakeUnlockDefs.NValueSum: max([sum(card.nvalue.values()) for card in cards]+[0]),
            ZawakeUnlockDefs.Feel: self.game.role.card_feels.get(markID, {}).get('level', 0),
            ZawakeUnlockDefs.EquipStarSum: max([sum([v['star']+v['ability'] for v in card.equips.values()]) for card in cards]+[0]),
            ZawakeUnlockDefs.EquipAwakeSum: max([sum([v['awake'] for v in card.equips.values()]) for card in cards]+[0]),
            ZawakeUnlockDefs.EquipSignetAdvanceSum: max([sum([v['signet_advance'] for v in card.equips.values()]) for card in cards]+[0]),
            ZawakeUnlockDefs.Star: max([card.star for card in cards]+[0]),
            ZawakeUnlockDefs.Advance: max([card.advance for card in cards]+[0]),
            ZawakeUnlockDefs.Effort: max([card.effort_advance for card in cards]+[0]),
            ZawakeUnlockDefs.ZawakeStage: max([stage * 100 + level for stage,level in self._zawake.get(zawakeID, {}).iteritems() if level > 0]+[0]),  # 2阶段 等级8 => 208
            ZawakeUnlockDefs.GemQuality: max([self.game.gems.getCardGemQualitySum(card.id) for card in cards] + [0]),
        }

    def getAffectedCards(self, cfg, battleOnly):
        if cfg.attrAddType == ZawakeDefs.MarkID:
            markID = self.ZawakeMap[cfg.zawakeID]
            markIDCards = self.game.cards.getCardsByMarkID(markID)
            affectedCards = set(markIDCards)
        elif cfg.attrAddType == ZawakeDefs.CardNatureType:
            natureCards = self.game.cards.getCardsByNature(cfg.natureType)
            affectedCards = set(natureCards)
        elif cfg.attrAddType == ZawakeDefs.CardsAll:
            if battleOnly:
                battleCards = self.game.role.battle_cards
                battleCards = self.game.cards.getCards(battleCards)
                affectedCards = set(battleCards)
            else:
                allCards = self.game.cards.getAllCards()
                affectedCards = set(allCards)
        return affectedCards

    def onAttrChange(self, battleOnly=True):
        '''
        在相关的数值发生变化时，更新相关精灵。如果加成范围是全部精灵，只更新主城精灵。
        '''
        oldLevelBuff = self._levelsBuff.copy()
        oldBonusBuff = self._bonusBuff.copy()
        oldSkillsBuff = self._skillsBuff.copy()
        oldSceneBuff = self._sceneBuff.copy()
        self._maxAttrMap = {}
        self._initEffectAttrAddition()
        affectedCards = set()

        for zawakeID in (self._skillsBuff ^ oldSkillsBuff):
            skillCards = self.ZawakeCardMap[zawakeID]
            skillCards = self.game.cards.getCardsByCsvID(skillCards)
            affectedCards |= set(skillCards)

        for csvID in (self._sceneBuff ^ oldSceneBuff):
            cfg = csv.zawake.levels[csvID]
            cards = self.game.cards.getCardsByCsvID(self.ZawakeCardMap[cfg.zawakeID])
            affectedCards |= set(cards)

        for csvID in (self._levelsBuff ^ oldLevelBuff):
            cfg = csv.zawake.levels[csvID]
            affectedCards |= self.getAffectedCards(cfg, battleOnly)

        for csvID in (self._bonusBuff ^ oldBonusBuff):
            cfg = csv.zawake.bonus[csvID]
            affectedCards |= set(self.game.cards.getCards(self.game.role.battle_cards))

        for card in affectedCards:
            card.calcZawakeAttrsAddition(card, self, SceneDefs.City)
            card.onUpdateAttrs()

    def getPassiveSkills(self, cardID):
        card = self.game.cards.getCard(cardID)
        zawakeID = csv.cards[card.card_id].zawakeID
        return {skillID:1 for skillID in self._zawake_skills.get(zawakeID, [])}

    def addZFrags(self, fragsD):
        for fragID, count in fragsD.iteritems():
            if count <= 0:
                raise ServerError('frag %d %d cheat' % (fragID, count))
            if not ZawakeDefs.isZFragID(fragID):
                continue

        for fragID, count in fragsD.iteritems():
            if not ZawakeDefs.isZFragID(fragID):
                continue
            cfg = csv.zawake.zawake_fragments[fragID]
            old = self._zfrags.get(fragID, 0)
            self._zfrags[fragID] = min(old + count, cfg.stackMax)
        return True

    def costZFrags(self, fragsD):
        for fragID, count in fragsD.iteritems():
            if not ZawakeDefs.isZFragID(fragID):
                continue
            if count <= 0:
                raise ServerError('frag %d %d cheat' % (fragID, count))
            if self._zfrags.get(fragID, 0) < count:
                return False

        for fragID, count in fragsD.iteritems():
            if not ZawakeDefs.isZFragID(fragID):
                continue
            self._zfrags[fragID] -= count
            if self._zfrags[fragID] <= 0:
                self._zfrags.pop(fragID)
        return True

    def isZFragEnough(self, fragsD):
        for fragID, count in fragsD.iteritems():
            if count <= 0:
                raise ServerError('frag %d %d cheat' % (fragID, count))
            if ZawakeDefs.isZFragID(fragID):
                if self._zfrags.get(fragID, 0) < count:
                    return False
        return True
