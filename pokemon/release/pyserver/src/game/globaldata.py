#!/usr/bin/python
# -*- coding: utf-8 -*-
'''
Copyright (c) 2014 YouMi Information Technology Inc.
'''

import datetime
from collections import namedtuple

import framework

# !!!
# 21点存在刷新和结算奖励，服务器维护不能在21点!!
# !!!

# 内部服务密码
# binascii.hexlify(os.urandom(16))
GameServInternalPassword = 'huanxi2394fd79a1ad32ff2e2db603da'

# AppNotify服务密码
AppNotifyInternalPassword = '4huasndf234234ksdfsjfdsidb78845'

# 升级跳过版本号
SkipUpdateAppVersion = '255.6.20'

# SDK账号密码
SDKAccountPasswordMD5 = 'tianjiacchusadnfei234980j0837fsd' # youmiaccpwd

# 每个服的开服日期，由`Server.__init__`时设置
GameServOpenDatetime = None

# ServerDailyRecord版本号
ServerDailyRecordVersion = 2

# 最大session数量
SessionMaxCapacity = 10000

# 账号登陆后，未进入相应服务器的
SessionCleanNoLoadTimerSecs = 1 * 60 # 与login_server SessionCleanZombieTimerSecs对应

# 长久没有交互的玩家，可能是僵尸
SessionCleanZombieTimerSecs = 30 * 60

# 竞技场商店每日刷新时间点
# 远征商店每日刷新时间点
ShopRefreshTime = datetime.time(hour=21)

# 钓鱼商店刷新时间点，由`Server.__init__`时设置
FishingShopRefreshTime = None

# db query int max
INF = 9999999

# 刷新时间段数组 当前为9点 12点 18点 21点刷新，从小到大排列
ShopRefreshPeriods = [9, 12, 18, 21]

# 派遣任务 5点 18点 刷新
DispatchTaskRefreshPeriods = [5, 18]

# 日常数据刷新时间点，由`Server.__init__`时设置
DailyRecordRefreshTime = None

# 月签到累计奖励配置 (csvID, day)
MonthSignGiftDays = [(101, 7), (102, 15), (103, 28)]

# 公会系统红包刷新时间点
UnionRedPacketRefreshTime = datetime.time(hour=19)

# VIP等级总数，由`Server.__init__`时设置
# 外部读取vip最大等级方法: globaldata.VIPLevelMax
VIPLevelMax = None

# 体力数值服务器上限
StaminaLimitMax = 3000

# 体力恢复时间
StaminaRecoverTimerSecs = 5 * 60

# 抽装备RMB消耗
DrawEquipCostPrice = 80
Draw10EquipCostPrice = 680

# 最大保存邮件数
MailBoxMax = 60

# 最大已读邮件数
ReadMailBoxMax = 10

# 竞技场结算奖励时间点
PVPAwardRefreshTime = datetime.time(hour=21)

# 竞技场结算奖励邮件CSV ID
PVPAwardMailID = 3

# 竞技场挑战次数道具ID
PVPBattleItemID = 517

# 竞技场皮肤展示ID起始
PVPSkinIDStart = 100000

# 试炼塔 假的活动ID 用于存放布阵阵容
RandomTowerHuodongID = -1

# 噩梦 假的活动ID 用于存放布阵阵容
NightmareHuodongID = -2

# 公会副本 假的活动ID 用于存放布阵阵容
UnionFubenHuodongID = -3

# 世界boss 假的活动ID 用于存放布阵阵容
WorldBossHuodongID = -4

# 无限之塔 假的活动ID 用于存放布阵阵容
EndlessTowerHuodongID = -5

# 跨服资源战 假的活动ID 用于存放布阵阵容
CrossMineBossHuodongID = -6

# 试炼塔结算奖励邮件CSV ID
RandomTowerAwardMailID = 28

# 试炼塔积分奖励补发邮件CSV ID
RandomTowerPointAwardMailID = 76

# 万能碎片ID
AllCanItemID = 502

# 世界boss角色排名结算奖励邮件ID
WorldBossRoleAwardMailID = 24

# 世界boss公会排名结算奖励邮件ID
WorldBossUnionAwardMailID = 25

# 世界boss公会结算全服奖励邮件ID
WorldBossServerAwardMailID = 26

# 世界boss当日免费挑战次数
WorldBossFreeCount = 3

# 系统赠送充值（用于赠送VIP）
FreeVIPRechargeID = -1
# 测试用
TestOrderID = "testrecharge"
# QQ防错补齐
QQOrderID = "_qq_recharge"

# 机器人ID起始
RobotIDStart = 1000000000

# 全局邮件RoleID
GlobalMailRoleID = None

# 服务器记录数据库刷新间隔
ServRecordDBRefreshTimerSecs = 10 * 60

# 公会列表排序内存刷新间隔
UnionListReSortTimerSecs = 5 * 60

# 玩家最多申请公会数
RoleJoinUnionPendingMax = 3

# 公会历史最大条数
UnionHistoryMax = 100

# 公会申请记录最长保留时间
UnionJoinDiscardTime = datetime.timedelta(hours=12).total_seconds()

# 公会会长最长连续不上线时间
ChairmanNoLoginMaxTime = datetime.timedelta(days=5).total_seconds()

# 公会会长候选者最长连续不上线时间
CandidateNoLoginMaxTime = datetime.timedelta(days=3).total_seconds()

# 公会副本通关邮件CSV ID
UnionFubenAwardMailID = 20

# 公会副本快速通关邮件CSV ID
UnionFubenQuickAwardMailID = 21

# 公会副本每日挑战次数
UnionFubenMaxTime = 3

# 公会副本每日开放时间
UnionFubenDailyTimeRange = (datetime.time(hour=9, minute=30), datetime.time(hour=23, minute=30))

# 公会副本周期重置WeekDay
UnionFubenResetWeakDay = (1, 3, 5)

# 公会副本周期奖励WeekDay
UnionFubenAwardWeakDay = (2, 4, 6)

# 公会副本奖励时间点
UnionFubenAwardTime = datetime.time(hour=23, minute=30)

# 公会副本伤害排行奖励邮件CSV ID
UnionFubenRankAwardMailID = 36

# 公会副本额外奖励邮件CSV ID
UnionFubenRandomAwardMailID = 37

# 公会会长给会员发的邮件CSV ID
UnionChairManToMemberMailID = 27

# 公会玩家红包维持时间
UnionRedPacketCDTime = datetime.timedelta(days=1).total_seconds()

# 公会成员数据刷新间隔(秒)
UnionMemberRefreshTime = 60

# 公会碎片赠予邮件
UnionFragDonateMailID = 108

# 消息历史
ChatMessageMax = 100

# 卡牌重置钻石消耗
CardResetRMBCost = 100

# 好友(申请)列表上限
FriendsMax = 60

# 好友体力赠送
FriendSendStamina = 3

# 好友体力每日赠送次数上限
FriendSendStaminaTimesMax = 100

# 好友体力每日领取次数上限
FriendRecvStaminaTimesMax = 20

# 申请好友列表一页数量
FriendListMax = 10

# 一次购买技能点数
SkillPointBuy = 20

# 全目标奖励邮件CSV ID
YYHuoDongTargetsAwardMailID = 29

# 战力排行奖励邮件CSV ID
YYHuoDongFightRankLevelAwardMailID = 30
YYHuoDongFightRankPointAwardMailID = 31

# 限时宝箱排名奖励邮件CSV ID
YYHuoDongLimitBoxRankAwardMailID = 33
YYHuoDongLimitBoxRankPointAwardMailID = 34

# 限时宝箱排名显示数量
YYHuoDongLimitBoxRankCount = 30

# 招财猫最大广播缓存记录
YYHuoDongLuckyCatMessageMax = 10

# 充值大转盘最大广播缓存记录
YYHuoDongRechargeWheelMessageMax = 20

# 双十一活动抽奖邮件
YYHuoDongDouble11LotteryMailID = 77

# 公会扭蛋火神兽上限
UnionLuckyEggMax = 6

# 公会训练所加速与被加速上限
UnionTrainingSpeedUpMax = 6

# 元素挑战每日刷新时间点，中午12点
CloneRefreshTime = datetime.time(hour=12)

# 元素挑战日完成次数
ClonePlayMaxTimes = 3

# 元素挑战完成奖励人数
CloneRoomFinished = 3

# 元素挑战完成奖励邮件
CloneRoomFinishedAwardMailID = 35

# 元素挑战被提出房间
CloneRoomBeKickedMailID = 72

# 元素挑战通知成员投票
CloneRoomNotifyVoteMailID = 73

# 元素挑战房主被警告
CloneRoomLeaderWaringMailID = 74

# 元素挑战新房主
CloneRoomNewLeaderMailID = 75

# 元素挑战挑战胜利宝箱
CloneDrawBoxRMBCost = 50

# 元素挑战房间邀请发送间隔
CloneInviteCDTime = 30 # s


# 拳皇争霸每天报名时间
CraftSignUpDailyTimeRange = (datetime.time(hour=10), datetime.time(hour=19, minute=50))

# 拳皇争霸每天自动报名时间
CraftAutoSignUpDailyTime = datetime.time(hour=19)

# 拳皇争霸开始战斗时间
CraftBattleDailyTime = datetime.time(hour=20)

# 拳皇争霸准备时间
CraftBattlePreReadyTimeDelta = datetime.timedelta(seconds=3 * 60)
CraftBattleFinalReadyTimeDelta = datetime.timedelta(seconds=4 * 60)

# 拳皇争霸战斗播报最大条目
CraftBattleMessageMax = 100

# 拳皇争霸下注额度
CraftBetNormalGold = 60000
CraftBetAdvanceGold = 200000

# 拳皇争霸胜利奖励邮件CSV ID
CraftRoundAwardMailID = 38

# 拳皇争霸排名奖励邮件CSV ID
CraftRankAwardMailID = 39

# 数码争霸下注冠军奖励邮件CSV ID
CraftBetWinAwardMailID = 40

# 数码争霸下注八强邮件CSV ID
CraftBetTop8AwardMailID = 41

# 数码争霸下注失败邮件CSV ID
CraftBetTop8FailMailID = 42

# 头衔获得邮件CSV ID
TitleGetMailID = 43

# 头衔连续获得邮件CSV ID
TitleGetAgainMailID = 44

# 2048游戏结算邮件
YY2048GameMailID = 53

# 拳皇争霸流程
# key: (idx, next)
CraftRoundStateInfo = namedtuple('CraftResultInfo', ('idx', 'next'))
CraftRoundStateMap = {
	'closed': CraftRoundStateInfo(-3, 'signup'),
	'signup': CraftRoundStateInfo(-2, 'prepare'),
	'prepare': CraftRoundStateInfo(-1, 'prepare_ok'),
	'prepare_ok': CraftRoundStateInfo(0, 'pre1'),

	'pre1': CraftRoundStateInfo(1, 'pre1_lock'),
	'pre1_lock': CraftRoundStateInfo(1, 'pre2'),
	'pre2': CraftRoundStateInfo(2, 'pre2_lock'),
	'pre2_lock': CraftRoundStateInfo(2, 'pre3'),
	'pre3': CraftRoundStateInfo(3, 'pre3_lock'),
	'pre3_lock': CraftRoundStateInfo(3, 'pre4'),
	'pre4': CraftRoundStateInfo(4, 'pre4_lock'),
	'pre4_lock': CraftRoundStateInfo(4, 'pre5'),
	'pre5': CraftRoundStateInfo(5, 'pre5_lock'),
	'pre5_lock': CraftRoundStateInfo(5, 'pre6'),
	'pre6': CraftRoundStateInfo(6, 'pre6_lock'),
	'pre6_lock': CraftRoundStateInfo(6, 'pre7'),
	'pre7': CraftRoundStateInfo(7, 'pre7_lock'),
	'pre7_lock': CraftRoundStateInfo(7, 'pre8'),
	'pre8': CraftRoundStateInfo(8, 'pre8_lock'),
	'pre8_lock': CraftRoundStateInfo(8, 'pre9'),
	'pre9': CraftRoundStateInfo(9, 'pre9_lock'),
	'pre9_lock': CraftRoundStateInfo(9, 'pre10'),
	'pre10': CraftRoundStateInfo(10, 'pre10_lock'),
	'pre10_lock': CraftRoundStateInfo(10, 'final1'),
	'final1': CraftRoundStateInfo(11, 'final1_lock'),
	'final1_lock': CraftRoundStateInfo(11, 'final2'),
	'final2': CraftRoundStateInfo(12, 'final2_lock'),
	'final2_lock': CraftRoundStateInfo(12, 'final3'),
	'final3': CraftRoundStateInfo(13, 'final3_lock'),
	'final3_lock': CraftRoundStateInfo(13, 'over'),

	'over': CraftRoundStateInfo(14, 'closed'),
}

# 公会战
# 公会战报名时间
UnionFightSignUpTimeRange = (datetime.time(hour=9, minute=30), datetime.time(hour=20, minute=50))

# 公会战自动报名时间
UnionFightAutoSignUpTime = datetime.time(hour=20, minute=30)

# 公会战开始战斗时间
UnionFightStartTime = datetime.time(hour=21, minute=0)

# 公会战周六开赛时间
UnionFightStart6Time = datetime.time(hour=20, minute=59)

# 公会战发奖励时间
UnionFightAwardTime = datetime.time(hour=21, minute=30)

# 公会战下注额度
UnionFightBetNormalGold = 100000
UnionFightBetAdvanceGold = 300000

#公会战预算赛报名奖励邮件ID
UnionFightPreAwardMailID = 45

#公会战决赛报名奖励邮件ID
UnionFightFinalAwardMailID = 46

#公会战胜利奖励邮件ID
UnionFightWinAwardMailID = 47

#公会战公会排名奖励邮件ID
UnionFightRankAwardMailID = 48

# 公会战下注冠军奖励邮件CSV ID
UnionFightBetWinAwardMailID = 49

# 公会战下注决赛邮件CSV ID
UnionFightBetTop8AwardMailID = 50

# 公会战下注失败邮件CSV ID
UnionFightBetTop8FailMailID = 51

# 升级装备的5、6号位 1exp=50gold
EquipExpToGold = 50

# 跨服石英大会战斗奖励邮件CSV ID
CrossCraftRoundAwardMailID = 54

# 跨服石英大会排名奖励邮件CSV ID
CrossCraftRankAwardMailID = 55

# 跨服石英大会预选赛全部押注成功奖励邮件CSV ID
CrossCraftPreBetAllWinMailID = 56

# 跨服石英大会预选赛部分押注成功奖励邮件CSV ID
CrossCraftPreBetWinMailID = 57

# 跨服石英大会预选赛未押注成功返还奖励邮件CSV ID
CrossCraftPreBetFailMailID = 58

# 跨服石英大会四强赛全部押注成功奖励邮件CSV ID
CrossCraftTop4BetAllWinMailID = 59

# 跨服石英大会四强赛部分押注成功奖励邮件CSV ID
CrossCraftTop4BetWinMailID = 60

# 跨服石英大会四强赛未押注成功返还奖励邮件CSV ID
CrossCraftTop4BetFailMailID = 61

# 跨服石英大会冠军押注成功奖励邮件CSV ID
CrossCraftChampionBetWinMailID = 62

# 跨服石英大会冠军押注失败奖励邮件CSV ID
CrossCraftChampionBetFailMailID = 63

# 跨服竞技场7日奖励邮件CSV ID
CrossArena7DayAwardMailID = 64

# 跨服竞技场最终奖励邮件CSV ID
CrossArenaFinishAwardMailID = 65

# 钓鱼大赛排名奖励邮件 CSV ID
CrossFishingRankAwardMailID = 66

# 钓鱼大赛自动钓鱼奖励补发邮件 CSV ID
CrossFishingAutoAwardMailID = 67

# 道馆本服荣誉馆主奖励邮件 CSV ID
GymLeaderAwardMailID = 68

# 跨服道馆荣誉馆主奖励邮件 CSV ID
CrossGymLeaderAwardMailID = 69

# 跨服道馆馆员奖励邮件 CSV ID
CrossGymGeneralAwardMailID = 70

# 道馆副本通关奖励补发邮件 CSV ID
GymPassAwardMailID = 71

# 公会问答个人排名奖励
UnionQARoleRankAwardMailID = 82

# 公会问答公会排名奖励
UnionQAUnionRankAwardMailID = 83

# 跨服公会战初赛排行奖励
CrossUnionFightPreRankAwardMailID = 84

# 跨服公会战决赛赛排行奖励
CrossUnionFightTopRankAwardMailID = 85

# 跨服公会战初赛竞猜奖励
CrossUnionFightPreBetAwardMailID = 86

# 跨服公会战决赛赛竞猜奖励
CrossUnionFightTopBetAwardMailID = 87

# 跨服公会战初赛竞猜失败奖励
CrossUnionFightPreBetAwardFailMailID = 88

# 跨服公会战决赛赛竞猜失败奖励
CrossUnionFightTopBetAwardFailMailID = 89

#普通月卡补领邮件类型ID
CommonMonthCardMailID = 102

#至尊月卡补领邮件类型ID
SuperMonthCardMailID = 103

#通知邮件
NoticeMail = 1

#个体值洗炼最大次数
NValueRecastCountMax = 6

# 精灵背包满时获得卡牌的邮件CSV ID
StashCardMailID = 101

# 运营活动奖励补发邮件CSV ID
YYHuodongMailID = 104

# 同意入会申请的邮件CSV ID
UnionAccpetJoinMailID = 105

# 训练师道具ID
TrainerItemID = 453

# 主城精灵刷新时间段数组 当前为9点 12点 18点 21点刷新，从小到大排列
CitySpriteRefreshPeriods = [9, 12, 18, 21]

# 主城精灵谜拟Q type
CitySpriteMiniQType = 1000

# 商店刷新 进货券
ShopRefreshItem = 522

# 实名注册奖励邮件
IdentityAwardMailID = 109

# 石英银币转换成金币邮件类型ID
CraftCoinTransType = 121

# 跨服石英银币转换成金币邮件类型ID
CrossCraftCoinTransType = 122

# 实时对战周结算有奖励邮件类型ID
CrossOnlineFightWeeklyAwardMailID = 110

# 实时对战周结算无奖励邮件类型ID
CrossOnlineFightWeeklyNoAwardMailID = 111

# 实时对战赛季结算邮件类型ID
CrossOnlineFightFinalAwardMailID = 112

# 重聚活动绑定邀请冷却时间
ReunionInviteCDTime = 30

# 重聚活动绑定冷却通知邮件
ReunionBindCDNoticeMailID = 123

# 跨服资源战日排行奖励邮件 CSV ID
CrossMineDayRankAwardMailID = 78

# 跨服资源战总排行奖励邮件 CSV ID
CrossMineAllRankAwardMailID = 79

# 跨服资源战服务器总排行奖励邮件 CSV ID
CrossMineServRankAwardMailID = 80

# 跨服资源战 Boss 排行奖励邮件 CSV ID
CrossMineBossRankAwardMailID = 81

# 普通勇者的玩法id
NormalBraveChallengePlayID = 0

# 跨服周年庆副本排行榜key
CrossBraveChallengeRanking = "bravechallengeranking"

# 普通勇者挑战副本排行榜key
CrossNormalBraveChallengeRanking = "normalbravechallengeranking"

# 跨服赛跑排行榜Key
CrossHorseRaceRanking = "horseraceranking"

# 跨服沙滩刨冰排行榜key
CrossShavedIceRanking = "shavediceranking"

# 沙滩排球排行榜Key
CrossVolleyballlRanking = "volleyballranking"

if framework.__language__ == "en":
	# 公会战
	UnionFightSignUpTimeRange = (datetime.time(hour=11, minute=30), datetime.time(hour=22, minute=50))
	UnionFightAutoSignUpTime = datetime.time(hour=22, minute=30)
	UnionFightStartTime = datetime.time(hour=23, minute=0)
	UnionFightStart6Time = datetime.time(hour=22, minute=59)
	UnionFightAwardTime = datetime.time(hour=23, minute=30)

	# 石英
	CraftSignUpDailyTimeRange = (datetime.time(hour=13), datetime.time(hour=21, minute=50))
	CraftAutoSignUpDailyTime = datetime.time(hour=21)
	CraftBattleDailyTime = datetime.time(hour=22)
