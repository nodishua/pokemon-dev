# coding:utf8
"""
合服配置
注意：有些文件是需要修改的
1. mergeserver/run_merge配置
2. mergeserver/defines配置(提供了脚本)
3. mergeserver/run_merge选定合服后运行的服务器
4. 修改/fabfile/fabfile的ServerIDMap
5. 将服务器配置到fabfile_merge文件，将新增合服信息增加到fabfile_merge.ServerIDMap
6. 生成storage,pvp配置, release/new_container.py
7. 生成game_defines配置, server_tool/fabfile/new_game_defines.py
8. 运行game_defines.py文件，得到login服务的登录配置文件


运行合服
-u 输出到stdout,不缓冲
例：  python -u run_merge.py gamemerge.cn_qd.10|tee gamemerge.cn_qd.10.log
"""

from datetime import datetime
from handler import run

MergeServs = {
	# 'gamemerge.cn.1': ['game.cn.1', 'game.cn.2', 'game.cn.3', 'game.cn.4', 'game.cn.5'],
	# 'gamemerge.dev.1': ['game.dev.2', 'game.dev.6'],
	# 20210519
	# 'gamemerge.cn_qd.1': ['game.cn_qd.30', 'game.cn_qd.31', 'game.cn_qd.32', 'game.cn_qd.33', 'game.cn_qd.34'], # tc-pokemon-cn_qd-12
	# 'gamemerge.cn_qd.2': ['game.cn_qd.35', 'game.cn_qd.36', 'game.cn_qd.37', 'game.cn_qd.38', 'game.cn_qd.39'], # tc-pokemon-cn_qd-08
	# 'gamemerge.cn_qd.3': ['game.cn_qd.40', 'game.cn_qd.41', 'game.cn_qd.42', 'game.cn_qd.43', 'game.cn_qd.44'], # tc-pokemon-cn_qd-09
	# 'gamemerge.cn_qd.4': ['game.cn_qd.45', 'game.cn_qd.46', 'game.cn_qd.47', 'game.cn_qd.48', 'game.cn_qd.49'], # tc-pokemon-cn_qd-10

	# 20210602
	# 'gamemerge.cn_qd.5': ['game.cn_qd.50', 'game.cn_qd.51', 'game.cn_qd.52', 'game.cn_qd.53', 'game.cn_qd.54'], # tc-pokemon-cn_qd-13
	# 'gamemerge.cn_qd.6': ['game.cn_qd.55', 'game.cn_qd.56', 'game.cn_qd.57', 'game.cn_qd.58', 'game.cn_qd.59'], # tc-pokemon-cn_qd-14
	# 'gamemerge.cn_qd.7': ['game.cn_qd.60', 'game.cn_qd.61', 'game.cn_qd.62', 'game.cn_qd.63', 'game.cn_qd.64'], # tc-pokemon-cn_qd-06
	# 'gamemerge.cn_qd.8': ['game.cn_qd.65', 'game.cn_qd.66', 'game.cn_qd.67', 'game.cn_qd.68', 'game.cn_qd.69'], # tc-pokemon-cn_qd-07
	# 'gamemerge.cn_qd.9': ['game.cn_qd.70', 'game.cn_qd.71', 'game.cn_qd.72', 'game.cn_qd.73', 'game.cn_qd.74'], # tc-pokemon-cn_qd-11
	# 'gamemerge.cn_qd.10': ['game.cn_qd.75', 'game.cn_qd.76', 'game.cn_qd.77', 'game.cn_qd.78', 'game.cn_qd.79'], # tc-pokemon-cn_qd-15

	# 'gamemerge.kr.1': ['game.kr.10', 'game.kr.11', 'game.kr.12'], # tc-pokemon-kr-02
	# 'gamemerge.kr.2': ['game.kr.13', 'game.kr.14', 'game.kr.15'], # tc-pokemon-kr-03
	# 'gamemerge.kr.3': ['game.kr.16', 'game.kr.17', 'game.kr.18'], # tc-pokemon-kr-04
	# 'gamemerge.kr.4': ['game.kr.19', 'game.kr.20', 'game.kr.21'], # tc-pokemon-kr-05
	# 'gamemerge.kr.5': ['game.kr.22', 'game.kr.23', 'game.kr.24'], # tc-pokemon-kr-06

	# 20210616
	# 'gamemerge.kr.6': ['game.kr.25', 'game.kr.26', 'game.kr.27'],  # tc-pokemon-kr-05
	# 'gamemerge.kr.7': ['game.kr.28', 'game.kr.29', 'game.kr.30'],  # tc-pokemon-kr-06
	# 'gamemerge.kr.8': ['game.kr.31', 'game.kr.32', 'game.kr.33'],  # tc-pokemon-kr-07
	# 'gamemerge.kr.9': ['game.kr.34', 'game.kr.35', 'game.kr.36'],  # tc-pokemon-kr-08
	# 'gamemerge.kr.10': ['game.kr.37', 'game.kr.38', 'game.kr.39'],  # tc-pokemon-kr-09
	# 'gamemerge.kr.11': ['game.kr.40', 'game.kr.41', 'game.kr.42'],  # tc-pokemon-kr-10
	# 'gamemerge.kr.12': ['game.kr.43', 'game.kr.44', 'game.kr.45'],  # tc-pokemon-kr-11
	# 'gamemerge.kr.13': ['game.kr.46', 'game.kr.47', 'game.kr.48'],  # tc-pokemon-kr-12
	# 20210623
	# 'gamemerge.cn_qd.11': ['game.cn_qd.80', 'game.cn_qd.81', 'game.cn_qd.82', 'game.cn_qd.83', 'game.cn_qd.84'],  # tc-pokemon-cn_qd-13
	# 'gamemerge.cn_qd.12': ['game.cn_qd.85', 'game.cn_qd.86', 'game.cn_qd.87', 'game.cn_qd.88', 'game.cn_qd.89'],  # tc-pokemon-cn_qd-14
	# 'gamemerge.cn_qd.13': ['game.cn_qd.90', 'game.cn_qd.91', 'game.cn_qd.92', 'game.cn_qd.93', 'game.cn_qd.94'],  # tc-pokemon-cn_qd-15
	# 'gamemerge.cn_qd.14': ['game.cn_qd.95', 'game.cn_qd.96', 'game.cn_qd.97', 'game.cn_qd.98', 'game.cn_qd.99'],  # tc-pokemon-cn_qd-16
	# 'gamemerge.cn_qd.15': ['game.cn_qd.100', 'game.cn_qd.101', 'game.cn_qd.102', 'game.cn_qd.103', 'game.cn_qd.104'],  # tc-pokemon-cn_qd-17
	# 'gamemerge.cn_qd.16': ['game.cn_qd.105', 'game.cn_qd.106', 'game.cn_qd.107', 'game.cn_qd.108', 'game.cn_qd.109'],  # tc-pokemon-cn_qd-18
	# 'gamemerge.cn_qd.17': ['game.cn_qd.110', 'game.cn_qd.111', 'game.cn_qd.112', 'game.cn_qd.113', 'game.cn_qd.114'],  # tc-pokemon-cn_qd-19
	# 'gamemerge.cn_qd.18': ['game.cn_qd.115', 'game.cn_qd.116', 'game.cn_qd.117', 'game.cn_qd.118', 'game.cn_qd.119'],  # tc-pokemon-cn_qd-20
	# 'gamemerge.cn_qd.19': ['game.cn_qd.120', 'game.cn_qd.121', 'game.cn_qd.122', 'game.cn_qd.123', 'game.cn_qd.124'],  # tc-pokemon-cn_qd-21
	# 'gamemerge.cn_qd.20': ['game.cn_qd.125', 'game.cn_qd.126', 'game.cn_qd.127', 'game.cn_qd.128', 'game.cn_qd.129'],  # tc-pokemon-cn_qd-22

	# 20210707
	# 'gamemerge.cn_qd.21': ['game.cn_qd.130', 'game.cn_qd.131', 'game.cn_qd.132', 'game.cn_qd.133', 'game.cn_qd.134'],  # tc-pokemon-cn_qd-23
	# 'gamemerge.cn_qd.22': ['game.cn_qd.135', 'game.cn_qd.136', 'game.cn_qd.137', 'game.cn_qd.138', 'game.cn_qd.139'],  # tc-pokemon-cn_qd-24
	# 'gamemerge.cn_qd.23': ['game.cn_qd.140', 'game.cn_qd.141', 'game.cn_qd.142', 'game.cn_qd.143', 'game.cn_qd.144'],  # tc-pokemon-cn_qd-25
	# 'gamemerge.cn_qd.24': ['game.cn_qd.145', 'game.cn_qd.146', 'game.cn_qd.147', 'game.cn_qd.148', 'game.cn_qd.149'],  # tc-pokemon-cn_qd-26
	# 'gamemerge.cn_qd.25': ['game.cn_qd.150', 'game.cn_qd.151', 'game.cn_qd.152', 'game.cn_qd.153', 'game.cn_qd.154'],  # tc-pokemon-cn_qd-27
	# 'gamemerge.cn_qd.26': ['game.cn_qd.155', 'game.cn_qd.156', 'game.cn_qd.157', 'game.cn_qd.158', 'game.cn_qd.159'],  # tc-pokemon-cn_qd-28
	# 'gamemerge.cn_qd.27': ['game.cn_qd.160', 'game.cn_qd.161', 'game.cn_qd.162', 'game.cn_qd.163', 'game.cn_qd.164'],  # tc-pokemon-cn_qd-29
	# 'gamemerge.cn_qd.28': ['game.cn_qd.165', 'game.cn_qd.166', 'game.cn_qd.167', 'game.cn_qd.168', 'game.cn_qd.169'],  # tc-pokemon-cn_qd-30
	# 'gamemerge.cn_qd.29': ['game.cn_qd.170', 'game.cn_qd.171', 'game.cn_qd.172', 'game.cn_qd.173', 'game.cn_qd.174'],  # tc-pokemon-cn_qd-31
	# 'gamemerge.cn_qd.30': ['game.cn_qd.175', 'game.cn_qd.176', 'game.cn_qd.177', 'game.cn_qd.178', 'game.cn_qd.179'],  # tc-pokemon-cn_qd-32

	# 20210714
	# 'gamemerge.cn_qd.31': ['game.cn_qd.2', 'game.cn_qd.3'],                                                       # tc-pokemon-cn_qd-02
	# 'gamemerge.cn_qd.32': ['game.cn_qd.4', 'game.cn_qd.5', 'game.cn_qd.6', 'game.cn_qd.7'],                       # tc-pokemon-cn_qd-03
	# 'gamemerge.cn_qd.33': ['game.cn_qd.8', 'game.cn_qd.9', 'game.cn_qd.10'],                                      # tc-pokemon-cn_qd-04
	# 'gamemerge.cn_qd.34': ['game.cn_qd.11', 'game.cn_qd.12', 'game.cn_qd.13', 'game.cn_qd.14'],                   # tc-pokemon-cn_qd-05
	# 'gamemerge.cn_qd.35': ['game.cn_qd.15', 'game.cn_qd.16', 'game.cn_qd.17', 'game.cn_qd.18', 'game.cn_qd.19'],  # tc-pokemon-cn_qd-06
	# 'gamemerge.cn_qd.36': ['game.cn_qd.20', 'game.cn_qd.21', 'game.cn_qd.22', 'game.cn_qd.23', 'game.cn_qd.24'],  # tc-pokemon-cn_qd-07
	# 'gamemerge.cn_qd.37': ['game.cn_qd.25', 'game.cn_qd.26', 'game.cn_qd.27', 'game.cn_qd.28', 'game.cn_qd.29'],  # tc-pokemon-cn_qd-08

	# 20210721
	# 'gamemerge.cn_qd.38': ['game.cn_qd.180', 'game.cn_qd.181', 'game.cn_qd.182', 'game.cn_qd.183', 'game.cn_qd.184'], # tc-pokemon-cn_qd-30
	# 'gamemerge.cn_qd.39': ['game.cn_qd.185', 'game.cn_qd.186', 'game.cn_qd.187', 'game.cn_qd.188', 'game.cn_qd.189'], # tc-pokemon-cn_qd-31
	# 'gamemerge.cn_qd.40': ['game.cn_qd.190', 'game.cn_qd.191', 'game.cn_qd.192', 'game.cn_qd.193', 'game.cn_qd.194'], # tc-pokemon-cn_qd-32
	# 'gamemerge.cn_qd.41': ['game.cn_qd.195', 'game.cn_qd.196', 'game.cn_qd.197', 'game.cn_qd.198', 'game.cn_qd.199'], # tc-pokemon-cn_qd-33
	# 'gamemerge.cn_qd.42': ['game.cn_qd.200', 'game.cn_qd.201', 'game.cn_qd.202', 'game.cn_qd.203', 'game.cn_qd.204'], # tc-pokemon-cn_qd-34
	# 'gamemerge.cn_qd.43': ['game.cn_qd.205', 'game.cn_qd.206', 'game.cn_qd.207', 'game.cn_qd.208', 'game.cn_qd.209'], # tc-pokemon-cn_qd-35
	# 'gamemerge.cn_qd.44': ['game.cn_qd.210', 'game.cn_qd.211', 'game.cn_qd.212', 'game.cn_qd.213', 'game.cn_qd.214'], # tc-pokemon-cn_qd-36
	# 'gamemerge.cn_qd.45': ['game.cn_qd.215', 'game.cn_qd.216', 'game.cn_qd.217', 'game.cn_qd.218', 'game.cn_qd.219'], # tc-pokemon-cn_qd-37
	# 'gamemerge.cn_qd.46': ['game.cn_qd.220', 'game.cn_qd.221', 'game.cn_qd.222', 'game.cn_qd.223', 'game.cn_qd.224'], # tc-pokemon-cn_qd-38
	# 'gamemerge.cn_qd.47': ['game.cn_qd.225', 'game.cn_qd.226', 'game.cn_qd.227', 'game.cn_qd.228', 'game.cn_qd.229'], # tc-pokemon-cn_qd-39

	# 20210728
	# 'gamemerge.cn_qd.48': ['game.cn_qd.230', 'game.cn_qd.231', 'game.cn_qd.232', 'game.cn_qd.233', 'game.cn_qd.234'], # tc-pokemon-cn_qd-02
	# 'gamemerge.cn_qd.49': ['game.cn_qd.235', 'game.cn_qd.236', 'game.cn_qd.237', 'game.cn_qd.238', 'game.cn_qd.239'], # tc-pokemon-cn_qd-03
	# 'gamemerge.cn_qd.50': ['game.cn_qd.240', 'game.cn_qd.241', 'game.cn_qd.242', 'game.cn_qd.243', 'game.cn_qd.244'], # tc-pokemon-cn_qd-04
	# 'gamemerge.cn_qd.51': ['game.cn_qd.245', 'game.cn_qd.246', 'game.cn_qd.247', 'game.cn_qd.248', 'game.cn_qd.249'], # tc-pokemon-cn_qd-05
	# 'gamemerge.cn_qd.52': ['game.cn_qd.250', 'game.cn_qd.251', 'game.cn_qd.252', 'game.cn_qd.253', 'game.cn_qd.254'], # tc-pokemon-cn_qd-06
	# 'gamemerge.cn_qd.53': ['game.cn_qd.255', 'game.cn_qd.256', 'game.cn_qd.257', 'game.cn_qd.258', 'game.cn_qd.259'], # tc-pokemon-cn_qd-07
	# 'gamemerge.cn_qd.54': ['game.cn_qd.260', 'game.cn_qd.261', 'game.cn_qd.262', 'game.cn_qd.263', 'game.cn_qd.264'], # tc-pokemon-cn_qd-08
	# 'gamemerge.cn_qd.55': ['game.cn_qd.265', 'game.cn_qd.266', 'game.cn_qd.267', 'game.cn_qd.268', 'game.cn_qd.269'], # tc-pokemon-cn_qd-09
	# 'gamemerge.cn_qd.56': ['game.cn_qd.270', 'game.cn_qd.271', 'game.cn_qd.272', 'game.cn_qd.273', 'game.cn_qd.274'], # tc-pokemon-cn_qd-10
	# 'gamemerge.cn_qd.57': ['game.cn_qd.275', 'game.cn_qd.276', 'game.cn_qd.277', 'game.cn_qd.278', 'game.cn_qd.279'], # tc-pokemon-cn_qd-11

	# 20210811
	# 'gamemerge.cn_qd.58': ['game.cn_qd.280', 'game.cn_qd.281', 'game.cn_qd.282', 'game.cn_qd.283', 'game.cn_qd.284'], # tc-pokemon-cn_qd-43
	# 'gamemerge.cn_qd.59': ['game.cn_qd.285', 'game.cn_qd.286', 'game.cn_qd.287', 'game.cn_qd.288', 'game.cn_qd.289'], # tc-pokemon-cn_qd-44
	# 'gamemerge.cn_qd.60': ['game.cn_qd.290', 'game.cn_qd.291', 'game.cn_qd.292', 'game.cn_qd.293', 'game.cn_qd.294'], # tc-pokemon-cn_qd-45
	# 'gamemerge.cn_qd.61': ['game.cn_qd.295', 'game.cn_qd.296', 'game.cn_qd.297', 'game.cn_qd.298', 'game.cn_qd.299'], # tc-pokemon-cn_qd-46
	# 'gamemerge.cn_qd.62': ['game.cn_qd.300', 'game.cn_qd.301', 'game.cn_qd.302', 'game.cn_qd.303', 'game.cn_qd.304'], # tc-pokemon-cn_qd-47
	# 'gamemerge.cn_qd.63': ['game.cn_qd.305', 'game.cn_qd.306', 'game.cn_qd.307', 'game.cn_qd.308', 'game.cn_qd.309'], # tc-pokemon-cn_qd-48
	# 'gamemerge.cn_qd.64': ['game.cn_qd.310', 'game.cn_qd.311', 'game.cn_qd.312', 'game.cn_qd.313', 'game.cn_qd.314'], # tc-pokemon-cn_qd-49
	# 'gamemerge.cn_qd.65': ['game.cn_qd.315', 'game.cn_qd.316', 'game.cn_qd.317', 'game.cn_qd.318', 'game.cn_qd.319'], # tc-pokemon-cn_qd-50
	# 'gamemerge.cn_qd.66': ['game.cn_qd.320', 'game.cn_qd.321', 'game.cn_qd.322', 'game.cn_qd.323', 'game.cn_qd.324'], # tc-pokemon-cn_qd-51
	# 'gamemerge.cn_qd.67': ['game.cn_qd.325', 'game.cn_qd.326', 'game.cn_qd.327', 'game.cn_qd.328', 'game.cn_qd.329'], # tc-pokemon-cn_qd-52

	# 20210818
	# 'gamemerge.cn_qd.68': ['game.cn_qd.330', 'game.cn_qd.331', 'game.cn_qd.332', 'game.cn_qd.333', 'game.cn_qd.334'], # tc-pokemon-cn_qd-43
	# 'gamemerge.cn_qd.69': ['game.cn_qd.335', 'game.cn_qd.336', 'game.cn_qd.337', 'game.cn_qd.338', 'game.cn_qd.339'], # tc-pokemon-cn_qd-44
	# 'gamemerge.cn_qd.70': ['game.cn_qd.340', 'game.cn_qd.341', 'game.cn_qd.342', 'game.cn_qd.343', 'game.cn_qd.344'], # tc-pokemon-cn_qd-45
	# 'gamemerge.cn_qd.71': ['game.cn_qd.345', 'game.cn_qd.346', 'game.cn_qd.347', 'game.cn_qd.348', 'game.cn_qd.349'], # tc-pokemon-cn_qd-46
	# 'gamemerge.cn_qd.72': ['game.cn_qd.350', 'game.cn_qd.351', 'game.cn_qd.352', 'game.cn_qd.353', 'game.cn_qd.354'], # tc-pokemon-cn_qd-47
	# 'gamemerge.cn_qd.73': ['game.cn_qd.355', 'game.cn_qd.356', 'game.cn_qd.357', 'game.cn_qd.358', 'game.cn_qd.359'], # tc-pokemon-cn_qd-48
	# 'gamemerge.cn_qd.74': ['game.cn_qd.360', 'game.cn_qd.361', 'game.cn_qd.362', 'game.cn_qd.363', 'game.cn_qd.364'], # tc-pokemon-cn_qd-49
	# 'gamemerge.cn_qd.75': ['game.cn_qd.365', 'game.cn_qd.366', 'game.cn_qd.367', 'game.cn_qd.368', 'game.cn_qd.369'], # tc-pokemon-cn_qd-50
	# 'gamemerge.cn_qd.76': ['game.cn_qd.370', 'game.cn_qd.371', 'game.cn_qd.372', 'game.cn_qd.373', 'game.cn_qd.374'], # tc-pokemon-cn_qd-51
	# 'gamemerge.cn_qd.77': ['game.cn_qd.375', 'game.cn_qd.376', 'game.cn_qd.377', 'game.cn_qd.378', 'game.cn_qd.379'], # tc-pokemon-cn_qd-52

	# 20210825
	# 'gamemerge.cn_qd.78': ['game.cn_qd.380', 'game.cn_qd.381', 'game.cn_qd.382', 'game.cn_qd.383', 'game.cn_qd.384'], # tc-pokemon-cn_qd-33
	# 'gamemerge.cn_qd.79': ['game.cn_qd.385', 'game.cn_qd.386', 'game.cn_qd.387', 'game.cn_qd.388', 'game.cn_qd.389'], # tc-pokemon-cn_qd-34
	# 'gamemerge.cn_qd.80': ['game.cn_qd.390', 'game.cn_qd.391', 'game.cn_qd.392', 'game.cn_qd.393', 'game.cn_qd.394'], # tc-pokemon-cn_qd-35
	# 'gamemerge.cn_qd.81': ['game.cn_qd.395', 'game.cn_qd.396', 'game.cn_qd.397', 'game.cn_qd.398', 'game.cn_qd.399'], # tc-pokemon-cn_qd-36
	# 'gamemerge.cn_qd.82': ['game.cn_qd.400', 'game.cn_qd.401', 'game.cn_qd.402', 'game.cn_qd.403', 'game.cn_qd.404'], # tc-pokemon-cn_qd-37
	# 'gamemerge.cn_qd.83': ['game.cn_qd.405', 'game.cn_qd.406', 'game.cn_qd.407', 'game.cn_qd.408', 'game.cn_qd.409'], # tc-pokemon-cn_qd-38
	# 'gamemerge.cn_qd.84': ['game.cn_qd.410', 'game.cn_qd.411', 'game.cn_qd.412', 'game.cn_qd.413', 'game.cn_qd.414'], # tc-pokemon-cn_qd-39
	# 'gamemerge.cn_qd.85': ['game.cn_qd.415', 'game.cn_qd.416', 'game.cn_qd.417', 'game.cn_qd.418', 'game.cn_qd.419'], # tc-pokemon-cn_qd-40
	# 'gamemerge.cn_qd.86': ['game.cn_qd.420', 'game.cn_qd.421', 'game.cn_qd.422', 'game.cn_qd.423', 'game.cn_qd.424'], # tc-pokemon-cn_qd-41
	# 'gamemerge.cn_qd.87': ['game.cn_qd.425', 'game.cn_qd.426', 'game.cn_qd.427', 'game.cn_qd.428', 'game.cn_qd.429'], # tc-pokemon-cn_qd-42

	# 20210901
	# 'gamemerge.cn_qd.88':['game.cn_qd.430', 'game.cn_qd.431', 'game.cn_qd.432', 'game.cn_qd.433', 'game.cn_qd.434'],
	# 'gamemerge.cn_qd.89':['game.cn_qd.435', 'game.cn_qd.436', 'game.cn_qd.437', 'game.cn_qd.438', 'game.cn_qd.439'],
	# 'gamemerge.cn_qd.90':['game.cn_qd.440', 'game.cn_qd.441', 'game.cn_qd.442', 'game.cn_qd.443', 'game.cn_qd.444'],
	# 'gamemerge.cn_qd.91':['game.cn_qd.445', 'game.cn_qd.446', 'game.cn_qd.447', 'game.cn_qd.448', 'game.cn_qd.449'],
	# 'gamemerge.cn_qd.92':['game.cn_qd.450', 'game.cn_qd.451', 'game.cn_qd.452', 'game.cn_qd.453', 'game.cn_qd.454'],
	# 'gamemerge.cn_qd.93':['game.cn_qd.455', 'game.cn_qd.456', 'game.cn_qd.457', 'game.cn_qd.458', 'game.cn_qd.459'],
	# 'gamemerge.cn_qd.94':['game.cn_qd.460', 'game.cn_qd.461', 'game.cn_qd.462', 'game.cn_qd.463', 'game.cn_qd.464'],
	# 'gamemerge.cn_qd.95':['game.cn_qd.465', 'game.cn_qd.466', 'game.cn_qd.467', 'game.cn_qd.468', 'game.cn_qd.469'],
	# 'gamemerge.cn_qd.96':['game.cn_qd.470', 'game.cn_qd.471', 'game.cn_qd.472', 'game.cn_qd.473', 'game.cn_qd.474'],
	# 'gamemerge.cn_qd.97':['game.cn_qd.475', 'game.cn_qd.476', 'game.cn_qd.477', 'game.cn_qd.478', 'game.cn_qd.479'],

	# 20210908
	# 'gamemerge.cn_qd.98': ['game.cn_qd.480', 'game.cn_qd.481', 'game.cn_qd.482', 'game.cn_qd.483', 'game.cn_qd.484'],
	# 'gamemerge.cn_qd.99': ['game.cn_qd.485', 'game.cn_qd.486', 'game.cn_qd.487', 'game.cn_qd.488', 'game.cn_qd.489'],
	# 'gamemerge.cn_qd.100': ['game.cn_qd.490', 'game.cn_qd.491', 'game.cn_qd.492', 'game.cn_qd.493', 'game.cn_qd.494'],
	# 'gamemerge.cn_qd.101': ['game.cn_qd.495', 'game.cn_qd.496', 'game.cn_qd.497', 'game.cn_qd.498', 'game.cn_qd.499'],
	# 'gamemerge.cn_qd.102': ['game.cn_qd.500', 'game.cn_qd.501', 'game.cn_qd.502', 'game.cn_qd.503', 'game.cn_qd.504'],
	# 'gamemerge.cn_qd.103': ['game.cn_qd.505', 'game.cn_qd.506', 'game.cn_qd.507', 'game.cn_qd.508', 'game.cn_qd.509'],
	# 'gamemerge.cn_qd.104': ['game.cn_qd.510', 'game.cn_qd.511', 'game.cn_qd.512', 'game.cn_qd.513', 'game.cn_qd.514'],
	# 'gamemerge.cn_qd.105': ['game.cn_qd.515', 'game.cn_qd.516', 'game.cn_qd.517', 'game.cn_qd.518', 'game.cn_qd.519'],
	# 'gamemerge.cn_qd.106': ['game.cn_qd.520', 'game.cn_qd.521', 'game.cn_qd.522', 'game.cn_qd.523', 'game.cn_qd.524'],
	# 'gamemerge.cn_qd.107': ['game.cn_qd.525', 'game.cn_qd.526', 'game.cn_qd.527', 'game.cn_qd.528', 'game.cn_qd.529'],

	# 20210915
	# "gamemerge.kr.14": ['game.kr.2', 'game.kr.4'],
	# "gamemerge.kr.15": ['game.kr.5', 'game.kr.6'],
	# "gamemerge.kr.16": ['game.kr.7', 'game.kr.8', 'game.kr.9'],

	# 20211013
	'gamemerge.tw.1': ['game.tw.1', 'game.tw.2', 'game.tw.3'],
	'gamemerge.tw.2': ['game.tw.4', 'game.tw.5', 'game.tw.6'],
	'gamemerge.tw.3': ['game.tw.7', 'game.tw.8', 'game.tw.9'],
	'gamemerge.tw.4': ['game.tw.10', 'game.tw.11', 'game.tw.12'],
	'gamemerge.tw.5': ['game.tw.13', 'game.tw.14', 'game.tw.15'],
}

def main():
	import sys
	dest = sys.argv[1]
	if len(dest.split('.')) != 3 or 'game' not in dest:
		print("err: please check your input")
		return
	if dest not in MergeServs:
		print('err: %s not in MergeServs config' % dest)
		return

	print(dest)
	keys = MergeServs[dest]
	start_time = datetime.now()
	run(dest, keys)
	end_time = datetime.now()
	print('DONE: %ss' % str((end_time - start_time).seconds))


if __name__ == '__main__':
	main()

