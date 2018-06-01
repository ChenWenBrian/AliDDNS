#!/bin/sh

aliddns_ak="PUT-YOUR-ALIYUM-ACESS-KEY-HERE"
aliddns_sk="PUT-YOUR-ALIYUN-SECURITY-KEY-HERE"
aliddns_dns="223.6.6.6"
aliddns_ttl="600"

aliddns_curl="curl -s whatismyip.akamai.com"

aliddns_domain=$1
host_file=$2
check_inteval=$3  #sleep time, 30s 2m 1h 1d


get_external_ip(){
    echo -n "`$aliddns_curl`"
}

get_nslookup_ip(){
    echo -n "`nslookup $aliddns_domain $aliddns_dns | awk '/^Address/ {print $NF}'| tail -n1`"
}

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
    nslookup_ip=`get_nslookup_ip`
    echo "External IP: `get_external_ip`"
    echo "Nslookup IP: $nslookup_ip $aliddns_domain"
    #echo `query_record`
    record_ip=`query_record | get_record_value`
    echo "AliDNS Record IP: $record_ip $aliddns_domain"

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

if [ -z $check_inteval ]
then
    exec_check
else
    while [ 1 ]
    do
        exec_check
        sleep $check_inteval
    done
fi
