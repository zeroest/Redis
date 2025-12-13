
# 마스터 복구 불가시 해시슬롯 재할당

7대 서버 모두 마스터로 운영하며 복제본이 없는 상태에서 마스터 서버 한대가 다운되었을때 복구가 불가하다면

## 1. cluster forget

```
redis-cli cluster forget <다운된 노드 ID>
```

## 2. cluster check

```bash
redis-cli -c -h <alive-node> -p 6379 cluster nodes
redis-cli -c -h <alive-node> -p 6379 cluster info
```

```log
cluster_state:ok
cluster_slots_assigned:15387 # 16384 개의 해시슬롯 커버되지 않은 상황
cluster_slots_ok:15387
cluster_slots_pfail:0
cluster_slots_fail:0
```

```bash
# 클러스터 점검
redis-cli --cluster check <alive-node>:6379
```

```log
rm1:6379 (1ed420e7...) -> 0 keys | 2564 slots | 0 slaves.
192.168.0.6:6379 (45be7b52...) -> 0 keys | 2564 slots | 0 slaves.
192.168.0.132:6379 (b2a05bc8...) -> 3 keys | 2565 slots | 0 slaves.
192.168.0.182:6379 (1078e9b4...) -> 0 keys | 2565 slots | 0 slaves.
192.168.0.13:6379 (d03c5fec...) -> 3 keys | 2564 slots | 0 slaves.
192.168.0.162:6379 (a5c7ed27...) -> 0 keys | 2565 slots | 0 slaves.
[OK] 6 keys in 6 masters.
0.00 keys per slot on average.
>>> Performing Cluster Check (using node rm1:6379)
M: 1ed420e75da4ea65a876390d35579965f7300a0f rm1:6379
   slots:[167-2730] (2564 slots) master
M: 45be7b523ba94357ab1a41724c2a1efadb5fc4d5 192.168.0.6:6379
   slots:[11089-13652] (2564 slots) master
M: b2a05bc8d615c6ffb894c01e6e676c1c6efe2178 192.168.0.132:6379
   slots:[5627-8191] (2565 slots) master
M: 1078e9b44e530c57a1d4fe83b2be76748a33ea94 192.168.0.182:6379
   slots:[13819-16383] (2565 slots) master
M: d03c5fecf98232eb4a098684371679e6b395febb 192.168.0.13:6379
   slots:[2897-5460] (2564 slots) master
M: a5c7ed27d0304496ee60c8e62141b51960d19528 192.168.0.162:6379
   slots:[8358-10922] (2565 slots) master
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[ERR] Not all 16384 slots are covered by nodes.
```

## 3. --cluster fix

```bash
redis-cli --cluster fix <alive-node>:6379
```

Redis 클러스터에서 열린 해시 슬롯(open slots)을 수정하여, 실패한 슬롯 마이그레이션(slot migration) 작업을 복구하거나, 슬롯 상태를 'importing' 또는 'migrating'에서 'stable'로 되돌려 클러스터의 일관성을 복구하는 데 사용됩니다. 이 명령은 수동 resharding 과정 중 문제가 발생했을 때, 열려있는 슬롯을 다시 원래 상태로 되돌리거나, 슬롯이 올바르게 할당되도록 돕습니다. 

- 이건 “비어있는 슬롯(커버 안 되는 슬롯)”을 현재 살아있는 마스터들에게 재할당해서 클러스터를 정상화합니다.
- 죽은 노드에 있던 키는 옮길 수 없으니(원본이 없음) 해당 슬롯의 기존 데이터는 복구되지 않습니다.

```bash
redis-cli -a redis --cluster fix rm1:6379
```

```log
rm1:6379 (1ed420e7...) -> 0 keys | 2564 slots | 0 slaves.
192.168.0.6:6379 (45be7b52...) -> 0 keys | 2564 slots | 0 slaves.
192.168.0.132:6379 (b2a05bc8...) -> 3 keys | 2565 slots | 0 slaves.
192.168.0.182:6379 (1078e9b4...) -> 0 keys | 2565 slots | 0 slaves.
192.168.0.13:6379 (d03c5fec...) -> 3 keys | 2564 slots | 0 slaves.
192.168.0.162:6379 (a5c7ed27...) -> 0 keys | 2565 slots | 0 slaves.
[OK] 6 keys in 6 masters.
0.00 keys per slot on average.
>>> Performing Cluster Check (using node rm1:6379)
M: 1ed420e75da4ea65a876390d35579965f7300a0f rm1:6379
   slots:[167-2730] (2564 slots) master
M: 45be7b523ba94357ab1a41724c2a1efadb5fc4d5 192.168.0.6:6379
   slots:[11089-13652] (2564 slots) master
M: b2a05bc8d615c6ffb894c01e6e676c1c6efe2178 192.168.0.132:6379
   slots:[5627-8191] (2565 slots) master
M: 1078e9b44e530c57a1d4fe83b2be76748a33ea94 192.168.0.182:6379
   slots:[13819-16383] (2565 slots) master
M: d03c5fecf98232eb4a098684371679e6b395febb 192.168.0.13:6379
   slots:[2897-5460] (2564 slots) master
M: a5c7ed27d0304496ee60c8e62141b51960d19528 192.168.0.162:6379
   slots:[8358-10922] (2565 slots) master
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[ERR] Not all 16384 slots are covered by nodes.

>>> Fixing slots coverage...
The following uncovered slots have no keys across the cluster:
[0-166],[2731-2896],[5461-5626],[8192-8357],[10923-11088],[13653-13818]
Fix these slots by covering with a random node? (type 'yes' to accept): yes

...

>>> Covering slot 11021 with 192.168.0.162:6379
>>> Covering slot 5553 with 192.168.0.162:6379
>>> Covering slot 2788 with 192.168.0.162:6379
>>> Covering slot 47 with 192.168.0.162:6379
>>> Covering slot 49 with 192.168.0.162:6379
>>> Covering slot 2895 with 192.168.0.162:6379
>>> Covering slot 8229 with 192.168.0.162:6379
>>> Covering slot 13715 with 192.168.0.162:6379
>>> Covering slot 34 with 192.168.0.162:6379
>>> Covering slot 13774 with 192.168.0.162:6379
>>> Covering slot 8215 with 192.168.0.162:6379

```

## 4. 균등하게 해시슬롯을 분배하려면 : rebalance

fix 로 우선 클러스터 해시슬롯을 모두 커버 하도록 정상화한 뒤 슬롯 6대에 균등하게 재분배

```bash
redis-cli --cluster rebalance <alive-node>:6379 --cluster-use-empty-masters
```

- --cluster-use-empty-masters: 사용되지 않는(empty) 마스터 노드에도 슬롯을 할당하여 재분배합니다. 
- --cluster-weight [Node ID]=[가중치]: 특정 노드에 가중치 설정 가능
  - redis-cli --cluster rebalance 127.0.0.1:7000 --cluster-weight 52f11541320cab2ef73954a2de65da19f10c6099=0.5 9614ae743975a6f7faa6c0326254d24f956f98ef=1.5


```bash
redis-cli -a redis --cluster rebalance rm3:6379 --cluster-use-empty-masters
```

```log
>>> Performing Cluster Check (using node rm3:6379)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Rebalancing across 6 nodes. Total weight = 6.00
Moving 167 slots from 192.168.0.6:6379 to rm3:6379
#######################################################################################################################################################################
Moving 167 slots from 192.168.0.6:6379 to 192.168.0.161:6379
#######################################################################################################################################################################
Moving 5 slots from 192.168.0.6:6379 to 192.168.0.182:6379
#####
Moving 104 slots from 192.168.0.13:6379 to 192.168.0.182:6379
########################################################################################################
Moving 57 slots from 192.168.0.162:6379 to 192.168.0.182:6379
#########################################################
```
