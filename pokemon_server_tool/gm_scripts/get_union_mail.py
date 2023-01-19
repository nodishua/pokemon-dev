#!/usr/bin/python
# -*- coding: utf-8 -*-
import sys
import datetime
import subprocess

def _cmd(dates, tag):
    files = []
    for d in dates:
        files.append("%s_*_game_server/"% tag + d + ".log")
    return "cat " + " ".join(files) + '|grep -E "union/sendMail"'

def execute(dates):
    c1 = _cmd(dates, "cn")
    c2 = _cmd(dates, "cn_qd")

    cwd = '/mnt/log'
    p1 = subprocess.Popen(c1, cwd=cwd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    p2 = subprocess.Popen(c2, cwd=cwd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    out1, err = p1.communicate()
    _pp(out1)
    out2, err = p2.communicate()
    _pp(out2)

def _pp(out):
    for line in out.split("\n"):
        temp = line.split("]", 1)
        tag = temp[0].strip()
        info = temp[-1].strip()
        try:
            serv_name = tag.split()[1].replace("[", "")
            infos = info.split()
            role_uid = infos[1]
            role_id = infos[2]
            content = infos[-1].replace('}', "").replace("'", "")
            content = content.decode("string-escape")
        except:
            continue
        ll = serv_name + "," + role_uid + "," + role_id + "," + content + "\n"
        print ll

if __name__ == "__main__":
    helpcmd = True if len(sys.argv) > 1 and sys.argv[1].strip() == '-h' else False
    if helpcmd:
        print '功能： 获取公会邮件'
        print '参数： datetime1 datetime2 datetime3, 默认不填则获取当天时间的'
        print '例子： 2020-03-05 2020-04-09 2020-04-17'
    else:
        if len(sys.argv) > 1:
            dates = sys.argv[1:]
        else:
            date = datetime.datetime.now().date()
            dates = ["%d-%02d-%02d"%(date.year, date.month, date.day), ]
        execute(dates)