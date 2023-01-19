# 支付Server流程

1. 启动时判定数据库中哪些订单未充值进游戏
1. 各家SDK支付回调，解析回调数据
	- 如果出错，在log中记录原始数据
1. 解析客户端回传数据
	- 如果出错，先用SDK回调数据修复
	- 无法修复的，在log中记录原始数据
1. 组装PayOrder数据字段
	- 统一各家SDK回调数据参数
	- 原生订单号加前缀，防止各家订单有冲突
1. 重复通知判定
	- 去重需要再yield之前，不然无法保障原子性
	- 如果之前是支付失败的，当前成功，可以不受重复影响
1. 支付失败的，在PayOrder中保留原始数据
1. 创建新的PayOrder数据（rpc调用）
	- result支付失败，记录即可
	- ClientData不合法，无法获取正确的roleID和rechargeID，只能运营处理
	- bad_flag = (result != 'ok') or (not ClientData.isValid())
	- Order重复处理，判断数据库记录result和recharge_flag
		1. True or True
			可能只是重复通知，中间服务器可能重启了
		1. False or True
			不可能
		1. True or False
			收到订单但未给钻石(可能cdata不对)，由服务器重启时入队列
		2. False or False
			上次通知是支付失败
	- 其他异常，在log中记录原始数据
1. 支付成功且数据库PayOrder成功创建的，model入队列等待充值

# 支付Queue流程

1. 启动时由Server塞入PayOrder未充值数据

	