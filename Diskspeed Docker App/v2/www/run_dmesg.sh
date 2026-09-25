out=$(cat /var/log/syslog | grep blocks | grep $1 | grep logical)
echo "$out"
