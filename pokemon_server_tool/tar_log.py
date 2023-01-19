import os
import datetime

from concurrent.futures import ThreadPoolExecutor
executor = ThreadPoolExecutor(max_workers=6)

one_day = datetime.timedelta(days=1)
current_date = datetime.datetime.now().date()

base_path = "/mnt/log"
target_path = "/mnt2/log"
retains = []
for i in xrange(7):
	date = current_date - i*one_day
	retains.append("%d-%02d-%02d.log"%(date.year, date.month, date.day))

print "retains: "
print retains
print "-------------start----------------"


def task(serv_log_dir_name):

	execs = []
	serv_log_name_path = os.path.join(base_path, serv_log_dir_name)
	if os.path.exists(serv_log_name_path):
		for _, _, files in os.walk(serv_log_name_path):
			for f in files:
				if f not in retains:
					execs.append(f)

	print "%s need tar files %d"% (serv_log_dir_name, len(execs))

	if execs:
		fs = " ".join(execs)
		target_tar_name = "%s/%s.zip"% (target_path, serv_log_dir_name)

		cmd = "cd %s && zip -q %s "% (serv_log_name_path, target_tar_name) + fs

		if os.system(cmd) != 0:
			print "--err: %s"% cmd
		else:
			cmd = "cd %s && rm "% serv_log_name_path + fs
			if os.system(cmd) != 0:
				print "--err: %s"% cmd

	print "%s end over"% serv_log_dir_name


if __name__ == "__main__":
	futures = []
	# cn
	for serv_id in range(1, 200):
		futures.append(executor.submit(task, "cn_%02d_game_server"% serv_id))
	# cn_qd
	for serv_id in range(1, 700):
		futures.append(executor.submit(task, "cn_qd_%02d_game_server" % serv_id))
	# login
	futures.append(executor.submit(task, "login_server"))

	executor.shutdown(True)

	# crash log
	import subprocess
	crash_platform_cmd = "cd /mnt/crash_platform && python tar_file.py tar"
	dev_null = open(os.devnull, "w")
	subprocess.Popen(crash_platform_cmd, shell=True, stdout=dev_null, stderr=dev_null)

	print "---------------over-----------------"
