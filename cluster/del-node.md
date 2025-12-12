
# 노드 제거

```bash
redis-cli --cluster del-node <기존 노드 IP:PORT> <삭제할 노드 IP>
```

제거하려는 노드가 마스터, 복제본 노드인지 상관 없이 모든 노드를 같은 방식으로 삭제할 수 있지만, 마스터 노드의 경우 제거하기 전에 노드에 저장된 데이터가 없는 상태여야 한다.  
즉 할당된 해시슬롯이 하나도 없도록 해시슬롯을 모두 리샤딩하는 작업이 선행되어야 한다  
혹은 수동으로 페일오버를 진행한 뒤 노드의 역할을 복제본으로 만든 뒤 클러스터에서 제거할 수도 있다

해시슬롯 존재시 아래와 같이 오류 발생 

```
>>> Removing node c0633bb7f70ea797723a10c3a7b42844ada479e8 from cluster rm3:6379
[ERR] Node rm3:6379 is not empty! Reshard data away and try again.
```

아래는 rm3 의 slave rr1 노드 제거  
이때 CLUSTER FORGET을 클러스터에, CLUSTER RESET SOFT를 제거된 노드에 수행했다는 내용 존재  

```bash
redis-cli -a redis --cluster del-node rm3:6379 2852d7d909af7c163e5d5644174359de2513da37
```

```log
>>> Removing node 2852d7d909af7c163e5d5644174359de2513da37 from cluster rm3:6379
>>> Sending CLUSTER FORGET messages to the cluster...
>>> Sending CLUSTER RESET SOFT to the deleted node.
```

```bash
redis-cli cluster nodes
```

```log
e555b3ff50826cea2bbced34bc9cc2816350ac94 192.168.0.6:6379@16379 slave d527972515b60af3a50464f423459ac66420e4d6 0 1765530270000 1 connected
d527972515b60af3a50464f423459ac66420e4d6 192.168.0.161:6379@16379 master - 0 1765530270000 1 connected 149-5460
c31e8130189075a6e705ed6e72fc0c7c66cc478f 192.168.0.182:6379@16379 slave 61a647c502097cd32a6dfd343da9eafc2e0018bb 0 1765530270519 2 connected
61a647c502097cd32a6dfd343da9eafc2e0018bb 192.168.0.13:6379@16379 master - 0 1765530269514 2 connected 5512-10922
c0633bb7f70ea797723a10c3a7b42844ada479e8 192.168.0.132:6379@16379 myself,master - 0 0 7 connected 0-148 5461-5511 10923-16383
```

## CLUSTER FORGET

제거될 노드에서 클러스터 구성 데이터를 지우는것 뿐만 아니라  
클러스터 내 다른 노드들에게도 해당 노드를 지우라는 커맨드를 함께 보내야 한다  
그렇지 않다면 클러스터 내부의 다른 노드는 여전히 해당 노드의 ID와 주소를 기억하고 있게된다  

CLUSTER FORGET \<node-id\> 커맨드를 수신한 노드는 노드 테이블에서 제거할 노드의 정보를 지운뒤,  
60초 동안은 이 노드 ID를 가지고 있는 노드와 신규로 연결되지 않도록 설정한다  

클러스터 구성에서 노드들은 가십 프로토콜을 이용해 통신하기 때문에 신규 클러스터 노드를 자동으로 감지해 새로운 노드로 추가할 수 있다  
따라서 60초 동안 제거한 노드의 ID가 다시 추가되는 것을 차단하지 않으면 다른 노드에 의해 제거된 노드를 다시 클러스터에 추가할 가능성이 존재한다  

## CLUSTER RESET 

클러스터 리셋 커맨드는 제거될 노드에서 수행된다  
리셋에는 두 가지 옵션이 존재하며, 옵션이 지정되지 않으면 기본 값은 SOFT다  

```bash
redis-cli 
> CLUSTER RESET [SOFT/HARD]
```

### 리셋 과정

HARD RESET 과정은 1에서 5번 과정이 모두 수행
SOFT RESET 과정은 1에서 3번까지의 과정만 수행

1. 클러스터 구성에서 복제본 역할을 했었다면 노드는 마스터로 전환되고, 노드가 가지고 있던 모든 데이터셋은 삭제된다. 노드가 마스터이고 저장된 키가 있다면 리셋 작업이 중단된다
2. 노드가 해시슬롯을 가지고 있었다면 모든 슬롯이 해제되며, 만약 페일오버가 진행되는 과정이었다면 페일오버에 대한 진행 상태도 초기화된다
3. 클러스터 구성 내의 다른 노드 데이터가 초기화된다. 기존에 클러스터 버스를 통해 연결됐던 노드를 더 이상 인식할 수 없다
4. currentEpoch, configEpoch, lastvoteEpoch 값이 0으로 초기화된다
5. 노드의 ID가 새로운 임의 ID로 변경된다

CLUSTER RESET은 앞선 예제에서처럼 cluster del-node 수행 중에 자동으로 실행될 수 있지만,  
사용자가 특정 클러스터 노드를 다른 역하로 재사용하고자 할 때 노드에 직접 커맨드를 수행할 수도 있다  
