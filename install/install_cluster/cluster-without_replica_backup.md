
# 복제본 없이 캐시용도 레디스 클러스터 생성

**⚠️복제본 없이 클러스터 운영시 마스터 다운으로 인한 클러스터 다운을 신경써야한다**  
클러스터 다운시 모든 해시슬롯에 접근 불가  

cluster-require-full-coverage 를 no로 설정해도 살아있는 노드가 과반수가 되지 않으면 클러스터가 다운된다  
(반 이상의 노드가 다운되면 클러스터는 다운된다.)

ex) 6대 마스터 운영시 2대 다운까지 버티고 3대 다운시 클러스터 다운  
ex) 7대 마스터 운영시 4대 다운시 클러스터 다운

```bash
redis-cli -a redis cluster info
```

```log
cluster_state:fail
```

살아있는 노드들에 다운된 서버를 클러스터에서 제외시키는 forget 명령을 실행해서 클러스터 사이즈를 줄여 다운된 노드를 과반 이하로 줄이는 방법도 존재한다  

## 마스터 노드 다운시 클러스터 유지

ref) [[redisgate] Redis CLUSTER-REQUIRE-FULL-COVERAGE](https://redisgate.jp/redis/cluster/cluster-require-full-coverage.php)

복제본 없이 클러스터를 운영하기 때문에 마스터 노드 다운시 영향도 최소화를 위해 cluster는 유지하도록 한다 

```conf
cluster-require-full-coverage no
```

## 백업기능 비활성화 

캐시 용도로 레디스를 사용하기 위해 백업 기능을 모두 비활성화 처리한다  

Redis에서 RDB와 AOF를 모두 끄려면 redis.conf 파일에서 save "" 설정으로 RDB 스냅샷을 비활성화하고, appendonly no로 AOF 로깅을 끄도록 한다  
이는 Redis 서버를 재시작할 때 변경 사항을 적용하며, 데이터를 디스크에 영구 저장하지 않기 때문에 서버 다운 시 데이터 유실이 발생하므로 주의해야 한다  

```conf
# RDB 비활성화
save ""

# AOF 비활성화
appendonly no
```

## 클러스터 생성시 복제본 설정

클러스터 생성시 복제본을 두지 않기 위해 --cluster-replicas 옵션을 0으로 주어 생성한다  

```bash
redis-cli --cluster create rm1:6379 rm2:6379 rm3:6379 rr1:6379 rr2:6379 rr3:6379 --cluster-replicas 0 -a redis
```

```log
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 2730
Master[1] -> Slots 2731 - 5460
Master[2] -> Slots 5461 - 8191
Master[3] -> Slots 8192 - 10922
Master[4] -> Slots 10923 - 13652
Master[5] -> Slots 13653 - 16383
M: 1ed420e75da4ea65a876390d35579965f7300a0f rm1:6379
   slots:[0-2730] (2731 slots) master
M: d03c5fecf98232eb4a098684371679e6b395febb rm2:6379
   slots:[2731-5460] (2730 slots) master
M: b2a05bc8d615c6ffb894c01e6e676c1c6efe2178 rm3:6379
   slots:[5461-8191] (2731 slots) master
M: a5c7ed27d0304496ee60c8e62141b51960d19528 rr1:6379
   slots:[8192-10922] (2731 slots) master
M: 45be7b523ba94357ab1a41724c2a1efadb5fc4d5 rr2:6379
   slots:[10923-13652] (2730 slots) master
M: 1078e9b44e530c57a1d4fe83b2be76748a33ea94 rr3:6379
   slots:[13653-16383] (2731 slots) master
Can I set the above configuration? (type 'yes' to accept): yes
>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join
..
>>> Performing Cluster Check (using node rm1:6379)
M: 1ed420e75da4ea65a876390d35579965f7300a0f rm1:6379
   slots:[0-2730] (2731 slots) master
M: 45be7b523ba94357ab1a41724c2a1efadb5fc4d5 192.168.0.6:6379
   slots:[10923-13652] (2730 slots) master
M: b2a05bc8d615c6ffb894c01e6e676c1c6efe2178 192.168.0.132:6379
   slots:[5461-8191] (2731 slots) master
M: 1078e9b44e530c57a1d4fe83b2be76748a33ea94 192.168.0.182:6379
   slots:[13653-16383] (2731 slots) master
M: d03c5fecf98232eb4a098684371679e6b395febb 192.168.0.13:6379
   slots:[2731-5460] (2730 slots) master
M: a5c7ed27d0304496ee60c8e62141b51960d19528 192.168.0.162:6379
   slots:[8192-10922] (2731 slots) master
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.

```

```bash
redis-cli cluster nodes
```

```log
45be7b523ba94357ab1a41724c2a1efadb5fc4d5 192.168.0.6:6379@16379 master - 0 1765552772031 5 connected 10923-13652
1ed420e75da4ea65a876390d35579965f7300a0f 192.168.0.161:6379@16379 myself,master - 0 0 1 connected 0-2730
b2a05bc8d615c6ffb894c01e6e676c1c6efe2178 192.168.0.132:6379@16379 master - 0 1765552772533 3 connected 5461-8191
1078e9b44e530c57a1d4fe83b2be76748a33ea94 192.168.0.182:6379@16379 master - 0 1765552772000 6 connected 13653-16383
d03c5fecf98232eb4a098684371679e6b395febb 192.168.0.13:6379@16379 master - 0 1765552772000 2 connected 2731-5460
a5c7ed27d0304496ee60c8e62141b51960d19528 192.168.0.162:6379@16379 master - 0 1765552772031 4 connected 8192-10922
```
