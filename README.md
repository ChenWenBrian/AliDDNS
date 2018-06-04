# AliDDNS 阿里动态域名脚本

提供阿里域名的动态域名更新、快速查询、以及更新本地DNS结果的轻量脚本

## 使用方法

1. 查询阿里域名的记录IP，当前DNS的记录IP以及查询端的公网IP

```shell
[root@SZV-VM ~]$ ./aliddns.sh home.mydomain.com
External IP: 218.37.12.42
Nslookup IP: 116.21.220.238 home.mydomain.com
AliDNS Record IP: 116.21.220.238 home.mydomain.com
```

1. 查询阿里域名的记录IP，当前DNS的记录IP以及查询端的公网IP，并将记录IP`添加`或`更新`或`删除`到指定的文件（如本地hosts）

```shell
#注：输出文件需已经创建，修改前会自动创建备份文件
#注：阿里云上记录的IP如果与DNS缓存的IP一致时，output.txt文件中的记录会删除
[root@SZV-VM ~]$ ./aliddns.sh home.mydomain.com output.txt
External IP: 218.37.12.42
Nslookup IP: 116.21.220.238 home.mydomain.com
AliDNS Record IP: 116.21.220.238 home.mydomain.com
output.txt.bak created
No record can be removed, skip
```

1. 轮询查询阿里域名的记录IP，，并将记录IP`添加`或`更新`或`删除`到指定的文件（如本地hosts）

```shell
#注：输出文件需已经创建，修改前会自动创建备份文件；
#注：阿里云上记录的IP如果与DNS缓存的IP一致时，hosts文件中的记录会删除
[root@SZV-VM ~]$ ./aliddns.sh home.mydomain.com /etc/hosts 30
External IP: 218.37.12.42
Nslookup IP: 116.21.220.238 home.mydomain.com
AliDNS Record IP: 116.21.220.238 home.mydomain.com
hosts.bak created
No record can be removed, skip
External IP: 218.37.12.42
Nslookup IP: 116.21.220.238 home.mydomain.com
AliDNS Record IP: 116.21.220.238 home.mydomain.com
hosts.bak is already created, skip bakup operation.
No record can be removed, skip
```

## 版本历史

2018-06-01 初始版本 V1

1. 通过阿里云的API，提供阿里云域名服务的单一域名记录的IP的快速查询，无DNS缓存等待时间限制；

2. 提供本地hosts文件的更新、删除功能；

3. 提供循环检查域名解析更新状态；
