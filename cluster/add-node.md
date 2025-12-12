
# 노드 추가

노드 마스터 또는 복제본 추가는 모두 데이터가 저장되어 있지 않은 상태여야 한다  
비어있지 않은 노드를 추가하고자 할때 다음과 같은 에러가 발생한다  

```log
[ERR] Node 192. 168.0.77:6379 is not empty. Either the node already knows other nodes (check with CLUSTER NODES) or contains some key in database 0.
```

cf. 데이터 모두 삭제 flushall

```bash
redis-cli flushall
```

또한 추가하고자 하는 노드도 설정파일에 `cluster-enabled yes` 설정이 있어야 한다  

## 마스터 추가 

```bash
redis-cli --cluster add-node <추가할 노드 IP:PORT> <기존 노드 IP:PORT>
```

```bash
redis-cli -a redis --cluster add-node rr1:6379 rm3:6379
```

```log
>>> Adding node rr1:6379 to cluster rm3:6379
>>> Performing Cluster Check (using node rm3:6379)
M: c0633bb7f70ea797723a10c3a7b42844ada479e8 rm3:6379
   slots:[0-148],[5461-5511],[10923-16383] (5661 slots) master
S: e555b3ff50826cea2bbced34bc9cc2816350ac94 192.168.0.6:6379
   slots: (0 slots) slave
   replicates d527972515b60af3a50464f423459ac66420e4d6
M: d527972515b60af3a50464f423459ac66420e4d6 192.168.0.161:6379
   slots:[149-5460] (5312 slots) master
   1 additional replica(s)
S: c31e8130189075a6e705ed6e72fc0c7c66cc478f 192.168.0.182:6379
   slots: (0 slots) slave
   replicates 61a647c502097cd32a6dfd343da9eafc2e0018bb
M: 61a647c502097cd32a6dfd343da9eafc2e0018bb 192.168.0.13:6379
   slots:[5512-10922] (5411 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
>>> Getting functions from cluster
>>> Send FUNCTION LIST to rr1:6379 to verify there is no functions in it
>>> Send FUNCTION RESTORE to rr1:6379
>>> Send CLUSTER MEET to node rr1:6379 to make it join the cluster.
[OK] New node added correctly.
```

새로운 노드를 추가하기 전 기존 노드의 상태를 확인한 뒤 새로운 노드를 추가하는 것을 확인할 수 있다

```bash
redis-cli cluster nodes
```

```log
61a647c502097cd32a6dfd343da9eafc2e0018bb 192.168.0.13:6379@16379 master - 0 1765530632250 2 connected 5512-10922
c0633bb7f70ea797723a10c3a7b42844ada479e8 192.168.0.132:6379@16379 master - 0 1765530631745 7 connected 0-148 5461-5511 10923-16383
e555b3ff50826cea2bbced34bc9cc2816350ac94 192.168.0.6:6379@16379 slave d527972515b60af3a50464f423459ac66420e4d6 0 1765530632047 1 connected
c31e8130189075a6e705ed6e72fc0c7c66cc478f 192.168.0.182:6379@16379 slave 61a647c502097cd32a6dfd343da9eafc2e0018bb 0 1765530632000 2 connected
97792a7099fd08606016648755c98cda13c37e6a 192.168.0.162:6379@16379 myself,master - 0 0 0 connected
d527972515b60af3a50464f423459ac66420e4d6 192.168.0.161:6379@16379 master - 0 1765530631544 1 connected 149-5460
```

rr1 노드가 마스터 노드로서 클러스터에 추가된 것을 볼 수 있다  
하지만 해당 노드는 해시슬롯이 없기 때문에 데이터를 보유할 수 없으며, 데이터를 저장하려면 리샤딩 기능을 사용해 직접 해시슬롯을 할당하는 과정을 거쳐야 한다  

## 복제본 추가

```bash
redis-cli --cluster add-node <추가할 노드 IP:PORT> <기존 노드 IP:PORT> --cluster-slave [--cluster-master-id <기존 마스터 ID>]
```

--cluster-master-id 옵션을 이용해 복제본의 마스터가 될 노드를 지정해주면 신규로 추가하는 노드는 지정한 마스터에 복제본으로 연결된다  
만약 해당 옵션 없이 노드 추가시 임의의 마스터 복제본으로 연결된다  
만약 클러스터가 대칭적인 구조가 아닐 때에는 복제본이 적게 연결되어 있는 마스터를 파악해 그중 한 마스터의 복제본이 되도록 지정해 균형을 맞추게 된다  

```bash
redis-cli -a redis cluster nodes
```

```log
61a647c502097cd32a6dfd343da9eafc2e0018bb 192.168.0.13:6379@16379 master - 0 1765542499000 2 connected 5512-10922
e555b3ff50826cea2bbced34bc9cc2816350ac94 192.168.0.6:6379@16379 myself,slave d527972515b60af3a50464f423459ac66420e4d6 0 0 1 connected
d527972515b60af3a50464f423459ac66420e4d6 192.168.0.161:6379@16379 master - 0 1765542499571 1 connected 149-5460
c31e8130189075a6e705ed6e72fc0c7c66cc478f 192.168.0.182:6379@16379 slave 61a647c502097cd32a6dfd343da9eafc2e0018bb 0 1765542499169 2 connected
c0633bb7f70ea797723a10c3a7b42844ada479e8 192.168.0.132:6379@16379 master - 0 1765542499068 7 connected 0-148 5461-5511 10923-16383
```

- MASTER-1(rm1, 192.168.0.161) - REPLICA-2(rr2, 192.168.0.6)
- MASTER-2(rm2, 192.168.0.13 ) - REPLICA-3(rr3, 192.168.0.182)
- MASTER-3(rm3, 192.168.0.132)

위와 같은 상황에서 rr1 노드를 복제본 노드로 추가한다  
신규로 추가하는 노드는 복제본이 없는 rm3 의 마스터노드 복제본이 되도록 구성된다

```bash
redis-cli -a redis \
  --cluster add-node \
  rr1:6379 rm1:6379 \
  --cluster-slave
```

```log
>>> Adding node rr1:6379 to cluster rm1:6379
>>> Performing Cluster Check (using node rm1:6379)
M: d527972515b60af3a50464f423459ac66420e4d6 rm1:6379
   slots:[149-5460] (5312 slots) master
   1 additional replica(s)
S: c31e8130189075a6e705ed6e72fc0c7c66cc478f 192.168.0.182:6379
   slots: (0 slots) slave
   replicates 61a647c502097cd32a6dfd343da9eafc2e0018bb
S: e555b3ff50826cea2bbced34bc9cc2816350ac94 192.168.0.6:6379
   slots: (0 slots) slave
   replicates d527972515b60af3a50464f423459ac66420e4d6
M: c0633bb7f70ea797723a10c3a7b42844ada479e8 192.168.0.132:6379
   slots:[0-148],[5461-5511],[10923-16383] (5661 slots) master
M: 61a647c502097cd32a6dfd343da9eafc2e0018bb 192.168.0.13:6379
   slots:[5512-10922] (5411 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.
Automatically selected master 192.168.0.132:6379
>>> Send CLUSTER MEET to node rr1:6379 to make it join the cluster.
Waiting for the cluster to join

>>> Configure node as replica of 192.168.0.132:6379.
[OK] New node added correctly.
```

`Automatically selected master 192.168.0.132:6379` 문구를 통해 마스터가 될 노드를 자동으로 rm3 노드로 선택했음을 알 수 있다  

```bash
redis-cli -a redis cluster nodes
```

```log
61a647c502097cd32a6dfd343da9eafc2e0018bb 192.168.0.13:6379@16379 master - 0 1765543196815 2 connected 5512-10922
e555b3ff50826cea2bbced34bc9cc2816350ac94 192.168.0.6:6379@16379 myself,slave d527972515b60af3a50464f423459ac66420e4d6 0 0 1 connected
d527972515b60af3a50464f423459ac66420e4d6 192.168.0.161:6379@16379 master - 0 1765543196000 1 connected 149-5460
c31e8130189075a6e705ed6e72fc0c7c66cc478f 192.168.0.182:6379@16379 slave 61a647c502097cd32a6dfd343da9eafc2e0018bb 0 1765543196000 2 connected
97792a7099fd08606016648755c98cda13c37e6a 192.168.0.162:6379@16379 slave c0633bb7f70ea797723a10c3a7b42844ada479e8 0 1765543196514 7 connected
c0633bb7f70ea797723a10c3a7b42844ada479e8 192.168.0.132:6379@16379 master - 0 1765543196514 7 connected 0-148 5461-5511 10923-16383
```

- MASTER-1(rm1, 192.168.0.161) - REPLICA-2(rr2, 192.168.0.6)
- MASTER-2(rm2, 192.168.0.13 ) - REPLICA-3(rr3, 192.168.0.182)
- MASTER-3(rm3, 192.168.0.132) - REPLICA-1(rr1, 192.168.0.162)
