cd /mnt/shuma/deploy/childlog
cat payment_server-stdout*|grep -E "161123"|grep "channel.* recharge ok" -o|sort|uniq|awk '
{chms[$2]+=$14; chms_acc[$2][$4]+=$14; sum+=$14; servs[$6]+=$14; servs_acc[$6][$4]+=$14; account[$4]=1;}
END {
print "----渠道 付费总数 付费人数----";
for(ch in chms)
{print ch, chms[ch], length(chms_acc[ch])};
print "----区服 付费总数 付费人数----";
for(s in servs)
{print s, servs[s], length(servs_acc[s])};
print "----汇总 付费总数 付费人数----";
print sum, length(account);}'

cd /mnt/shuma/deploy/childlog
cat payment_server-stdout*|grep "channel.* recharge ok"|sort|uniq|awk '
{
rmb=$20;
foreign=match($8, "mofang");
if (rmb>700) {
	csv["`9`"]=6;
	csv["`8`"]=30;
	csv["`7`"]=60;
	csv["`6`"]=98;
	csv["`5`"]=198;
	csv["`4`"]=328;
	csv["`3`"]=648;
	rmb=csv[$16];
}
if (foreign) {fdays[$3]+=rmb; fsum+=rmb;}
else {days[$3]+=rmb; sum+=rmb;}
} END {
print "----日期 付费总数----";
for(day in days)
{print day, "RMB", days[day], "USD", fdays[day]};
print "----付费总数----";
print "RMB", sum, "USD", fsum;
}'

cd /mnt/shuma/deploy/childlog
cat payment_server-stdout*|grep -E "I 16111[123]"|grep "channel.* recharge ok"|sort|uniq|awk '
function qqnum(i1)
{
	return strtonum(substr(i1, 9, length(i1)-9))
}
function cmp(i1, v1, i2, v2)
{
	return qqnum(i1) > qqnum(i2)
}

{
rmb=$20;
foreign=match($8, "mofang");
if (rmb>700) {
	csv["`9`"]=6;
	csv["`8`"]=30;
	csv["`7`"]=60;
	csv["`6`"]=98;
	csv["`5`"]=198;
	csv["`4`"]=328;
	csv["`3`"]=648;
	rmb=csv[$16];
}
if (foreign) {fdays[$3][$12]+=rmb; fsum+=rmb;}
else {days[$3][$12]+=rmb; sum+=rmb;}
} END {
print "----日期 付费总数----";
for(day in days) {
	PROCINFO["sorted_in"] = "cmp"
	for(serv in days[day])
	{print day, serv, "RMB", days[day][serv], "USD", fdays[day][serv]};
	print "--------"
}
print "----付费总数----";
print "RMB", sum, "USD", fsum;
}'

cd /mnt/shuma/deploy/childlog
cat payment_server-stdout*|grep "channel.* recharge ok"|sort|uniq|awk '
{accounts[$10]+=$20; sum+=$20}
END {
print "----账号 付费----";
for(acc in accounts)
{print acc, accounts[acc]};
print "----付费总数----";
print sum;}'

#
cd /mnt/shuma/deploy/childlog
cat login_server-stdout*|grep 161123|grep -E "\`.+_.+\` login confirm.*" -o|sort|uniq|awk '
{split($1, arr, "_"); chls[arr[1]]+=1; servs[$5]+=1; sum+=1}
END{
print "----渠道 登录账号----";
for(ch in chls)
{print ch, chls[ch]};
print "----区服 登录账号----";
for(s in servs)
{print s, servs[s]};
print "----汇总 登录账号----";
print sum}'

cd /mnt/shuma/deploy/childlog
cat *login_server-stdout*|grep -E "161123"|grep -E "\`.+_.+\` login in server.*" -o|sort|uniq|awk '
{split($1, arr, "_"); chls[arr[1]]+=1; servs[$6]+=1; sum+=1}
END{
print "----渠道 登录账号----";
for(ch in chls)
{print ch, chls[ch]};
print "----区服 登录账号----";
for(s in servs)
{print s, servs[s]};
print "----汇总 登录账号----";
print sum}'

cd /mnt/shuma/deploy/childlog
cat *login_server-stdout*|grep 161025|grep -E "\`.+_.+\` new account.*" -o|sort|uniq|awk '
{split($1, arr, "_"); chls[arr[1]]+=1; sum+=1}
END{
print "----渠道 新增账号----";
for(ch in chls)
{print ch, chls[ch]};
print "----汇总 新增账号----";
print sum}'

#
cd /mnt/shuma/deploy/childlog
cat *login_server-stdout*|grep "login in server"|awk '{
	daylogin[$3][$7] = 1;
	if ($7 in accs) {}
	else {
		accs[$7] = 1;
		daynew[$3] += 1;
	}
}
END {
for (day in daylogin) {
	print day, length(daylogin[day]), daynew[day]
}
}'