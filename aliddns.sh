#!/bin/sh

#put your aliyun ALIYUN-ACESS-KEY key here.
aliddns_ak="LTAIEjaPZMM4hUh9"
#put your aliyun ALIYUN-SECURITY-KEY key here.
aliddns_sk="YD62jSVBXdyS0wk4yAyHM5xg1NBEbO"
#the DNS server you want to compare, default is 223.6.6.6
#you may set empty string if you want to use your default dns server
aliddns_dns="223.6.6.6"
#TTL you want to set your DNS parse record, minimal value is 600
aliddns_ttl="600"
#method to get your external IP
aliddns_curl="curl -s whatismyip.akamai.com"

#input arguments definitions
aliddns_domain=$1
host_file=$2
check_interval=$3  #sleep time, 30s 2m 1h 1d


if [ -z "$aliddns_ak" ] || [ -z "$aliddns_sk" ]
then
    echo ERROR: Your Aliyun Access-Key or Security-Key is not found. Please recheck the variables 1>&2
    exit 1 # terminate and indicate error
fi

urlencode() {
    # urlencode <string>
    out=""
    while read -n1 c
    do
        case $c in
            [a-zA-Z0-9._-]) out="$out$c" ;;
            *) out="$out`printf '%%%02X' "'$c"`" ;;
        esac
    done
    echo -n $out
}

enc() {
    echo -n "$1" | urlencode
}

send_request() {
    local args="AccessKeyId=$aliddns_ak&Action=$1&Format=json&$2&Version=2015-01-09"
    local hash=$(echo -n "GET&%2F&$(enc "$args")" | openssl dgst -sha1 -hmac "$aliddns_sk&" -binary | openssl base64)
    curl -s "http://alidns.aliyuncs.com/?$args&Signature=$(enc "$hash")"
}

get_record_value() {
    grep -Eo '"Value":"[0-9\.]+"' | cut -d':' -f2 | tr -d '"'
}

query_record() {
    timestamp=`date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ"`
    send_request "DescribeSubDomainRecords" "SignatureMethod=HMAC-SHA1&SignatureNonce=$timestamp&SignatureVersion=1.0&SubDomain=$aliddns_domain&Timestamp=$timestamp"
}

remove_hosts() {
    if grep -q "$aliddns_domain" "$host_file"; then
        sed -i "/$aliddns_domain/d" $host_file
        echo "Remove record: $aliddns_domain"
    else
        echo "No record can be removed, skip"
    fi
}

update_hosts() {
    if grep -q "$aliddns_domain" "$host_file"; then
        echo "Update record: $record_ip $aliddns_domain"
        sed -i "/$aliddns_domain/c $record_ip $aliddns_domain" $host_file
    else
        echo "Add record: $record_ip $aliddns_domain"
        echo "$record_ip $aliddns_domain" >> $host_file
    fi
}


exec_check(){
    nslookup_ip=`nslookup $aliddns_domain $aliddns_dns | awk '/^Address/ {print $NF}'| tail -n1`
    if [ -z "$1" ]
    then
        echo "External IP:  `$aliddns_curl`"
        echo "Nslookup DNS: ${aliddns_dns:-default}#53"
        echo ""
    fi
    echo "Domain:       $aliddns_domain"
    echo "Nslookup IP:  $nslookup_ip"
    #echo `query_record`
    record_ip=`query_record | get_record_value`
    echo "Aliyun   IP:  $record_ip"

    if [ -n "$host_file" ] && [ -f $host_file ]
    then
        if [ -f "$host_file.bak" ]
        then
            echo "$host_file.bak is already created, skip bakup operation."
        else
            cp $host_file "$host_file.bak"
            echo "$host_file.bak created"
        fi

        if [ -n "$record_ip" ] && [ "$record_ip" != "$nslookup_ip" ]
        then
            update_hosts
        else
            remove_hosts
        fi
    fi
}

exec_check
while [ -n "$check_interval" ]
do
    exec_check "NO-EXTERNAL-IP"
    sleep $check_interval
done
