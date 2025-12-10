
# Cluster install

[[redisgate] Redis CLUSTER Start](https://redisgate.kr/redis/cluster/cluster_start.php)

[[redisgate] Redis CLUSTER Redis-cli 사용법](https://redisgate.kr/redis/cluster/redis-cli-cluster.php)

[[redisgate] Redis DATABASES Parameter](https://redisgate.kr/redis/configuration/param_databases.php)

Ubuntu Server 24.04 LTS (HVM),EBS General Purpose (SSD) Volume Type. x 6

- MASTER-1 - REPLICA-1
- MASTER-2 - REPLICA-2
- MASTER-3 - REPLICA-3

## Install Redis

```bash
sudo apt update
sudo apt install build-essential

wget https://download.redis.io/releases/redis-8.4.0.tar.gz

tar xvzf redis-8.4.0.tar.gz

cd redis-8.4.0

make

# make CC=gcc

make PREFIX=/home/ubuntu/redis install
```

## Configuration

### Path

```
vim ~/.bashrc

export PATH=$PATH:/home/ubuntu/redis/bin
```

### redis.conf

클러스터에 필요한 파라미터: 아래 파라미터들은 redis.conf 파일에 있고, 디폴트로 주석으로 되어 있다.
- cluster-enabled yes : yes로 하면 cluster mode로 시작한다. no로 하면 standalone mode로 시작한다.
- cluster-config-file nodes.conf : 이 파일은 클러스터의 상태를 기록하는 바이너리 파일이다. 클러스터의 상태가 변경될때 마다 상태를 기록한다.
- cluster-node-timeout 3000 : 레디스 노드가 다운되었는지 판단하는 시간이다. 단위는 millisecond이다.
- port open : 방화벽(firewall)을 사용하고 있다면 기본 포트에 10000을 더한 클러스터 버스 포트도 열려있어야 한다.  예를 들어 기본 포트로 7000번을 사용한다면 17000번 포트도 같이 열어야 한다.

appendonly 는 클러스터와 직접적인 연관이 있는 파라미터는 아니지만, 다운되었던 마스터 노드 재 시작시 appendonly 파일에 가장 최근까지 데이터가 있으므로, 클러스터 운영시에는 yes로 설정하는 것을 권장한다. working directory도 설정해 줄 것을 권장한다.
- port 7000
- cluster-enabled yes
- cluster-config-file nodes.conf
- cluster-node-timeout 3000
- appendonly yes
- dir /path/to/dir/

```bash
mkdir ~/redis/dir
mkdir ~/redis/log
mkdir ~/redis/pid
mkdir ~/redis/script

cp ~/redis-8.4.0/redis.conf ~/redis/redis.conf

vim ~/redis/redis.conf
```

```conf
bind 0.0.0.0
port 6379

protected-mode yes
requirepass redis
masterauth redis

cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 3000

appendonly yes

dir /home/ubuntu/redis/dir

pidfile /home/ubuntu/redis/pid/redis.pid
logfile /home/ubuntu/redis/log/redis.log

daemonize yes

```

### Initialize

cluster-enabled yes 설정 후 레디스를 클러스터 모드로 각기 다른 서버 6대에 레디스를 실행

입력한 순서대로 3개의 노드는 마스터, 나머지 노드는 복제본이 되도록 구성될 것이라는 정보를 확인할 수 있음  
각 마스터별로 어떤 해시슬롯을 할당받게 되는지, 각 마스터 노드에 어떤 복제본이 복제되는지 등의 정보를 알 수 있다  

redis/script/init-server.sh
```bash
#!/bin/bash

redis-server /home/ubuntu/redis/redis.conf

```

```log
9231:C 10 Dec 2025 11:28:34.647 # WARNING: Changing databases number from 16 to 1 since we are in cluster mode
9231:C 10 Dec 2025 11:28:34.647 # WARNING Memory overcommit must be enabled! Without it, a background save or replication may fail under low memory condition. Being disabled, it can also cause failures without low memory condition, see https://github.com/jemalloc/jemalloc/issues/1328. To fix this issue add 'vm.overcommit_memory = 1' to /etc/sysctl.conf and then reboot or run the command 'sysctl vm.overcommit_memory=1' for this to take effect.
9231:C 10 Dec 2025 11:28:34.647 # WARNING Your system is configured to use the 'xen' clocksource which might lead to degraded performance. Check the result of the [slow-clocksource] system check: run 'redis-server --check-system' to check if the system's clocksource isn't degrading performance.
9231:C 10 Dec 2025 11:28:34.647 * oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
9231:C 10 Dec 2025 11:28:34.647 * Redis version=8.4.0, bits=64, commit=00000000, modified=1, pid=9231, just started
9231:C 10 Dec 2025 11:28:34.647 * Configuration loaded
9231:M 10 Dec 2025 11:28:34.648 * Increased maximum number of open files to 10032 (it was originally set to 1024).
9231:M 10 Dec 2025 11:28:34.648 * monotonic clock: POSIX clock_gettime
                _._                                                  
           _.-``__ ''-._                                             
      _.-``    `.  `_.  ''-._           Redis Open Source            
  .-`` .-```.  ```\/    _.,_ ''-._      8.4.0 (00000000/1) 64 bit
 (    '      ,       .-`  | `,    )     Running in cluster mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 9231
  `-._    `-._  `-./  _.-'    _.-'                                   
 |`-._`-._    `-.__.-'    _.-'_.-'|                                  
 |    `-._`-._        _.-'_.-'    |           https://redis.io       
  `-._    `-._`-.__.-'_.-'    _.-'                                   
 |`-._`-._    `-.__.-'    _.-'_.-'|                                  
 |    `-._`-._        _.-'_.-'    |                                  
  `-._    `-._`-.__.-'_.-'    _.-'                                   
      `-._    `-.__.-'    _.-'                                       
          `-._        _.-'                                           
              `-.__.-'                                               

9231:M 10 Dec 2025 11:28:34.650 * No cluster configuration found, I'm dbb0922066607414a84dc5cd9835f073033c11bb
9231:M 10 Dec 2025 11:28:34.655 * Server initialized
9231:M 10 Dec 2025 11:28:34.655 * BGSAVE done, 0 keys saved, 0 keys skipped, 107 bytes written.
9231:M 10 Dec 2025 11:28:34.658 * Creating AOF base file appendonly.aof.1.base.rdb on server start
9231:M 10 Dec 2025 11:28:34.662 * Creating AOF incr file appendonly.aof.1.incr.aof on server start
9231:M 10 Dec 2025 11:28:34.662 * Ready to accept connections tcp
```

### Create Cluster

클러스터 생성은 클러스터 노드중 한대의 서버에서 실행하면 된다  

redis/script/cluster-create.sh
```
#!/bin/bash

redis-cli --cluster create rm1:6379 rm2:6379 rm3:6379 rr1:6379 rr2:6379 rr3:6379 --cluster-replicas 1 -a redis
```

```log
Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
>>> Performing hash slots allocation on 6 nodes...
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica rr2:6379 to rm1:6379
Adding replica rr3:6379 to rm2:6379
Adding replica rr1:6379 to rm3:6379
M: ea005587a13b7b50cbc498da976abcf7e44b1a2d rm1:6379
   slots:[0-5460] (5461 slots) master
M: 314a87796f7365f49bc9bf5f04edfbd5cb339d0b rm2:6379
   slots:[5461-10922] (5462 slots) master
M: 1fdb4f59f79d071fb2730e7b7bbf34b926d048d1 rm3:6379
   slots:[10923-16383] (5461 slots) master
S: dcb44aa080e04845c1e0c8d7fd256fb9bda623bf rr1:6379
   replicates 1fdb4f59f79d071fb2730e7b7bbf34b926d048d1
S: 1a26d03a8f9ee8026e32abc1092e25bf4a63d2da rr2:6379
   replicates ea005587a13b7b50cbc498da976abcf7e44b1a2d
S: dbb0922066607414a84dc5cd9835f073033c11bb rr3:6379
   replicates 314a87796f7365f49bc9bf5f04edfbd5cb339d0b
Can I set the above configuration? (type 'yes' to accept): yes

>>> Nodes configuration updated
>>> Assign a different config epoch to each node
>>> Sending CLUSTER MEET messages to join the cluster
Waiting for the cluster to join

>>> Performing Cluster Check (using node rm1:6379)
M: ea005587a13b7b50cbc498da976abcf7e44b1a2d rm1:6379
   slots:[0-5460] (5461 slots) master
   1 additional replica(s)
S: dbb0922066607414a84dc5cd9835f073033c11bb 192.168.0.182:6379
   slots: (0 slots) slave
   replicates 314a87796f7365f49bc9bf5f04edfbd5cb339d0b
S: 1a26d03a8f9ee8026e32abc1092e25bf4a63d2da 192.168.0.6:6379
   slots: (0 slots) slave
   replicates ea005587a13b7b50cbc498da976abcf7e44b1a2d
S: dcb44aa080e04845c1e0c8d7fd256fb9bda623bf 192.168.0.162:6379
   slots: (0 slots) slave
   replicates 1fdb4f59f79d071fb2730e7b7bbf34b926d048d1
M: 1fdb4f59f79d071fb2730e7b7bbf34b926d048d1 192.168.0.132:6379
   slots:[10923-16383] (5461 slots) master
   1 additional replica(s)
M: 314a87796f7365f49bc9bf5f04edfbd5cb339d0b 192.168.0.13:6379
   slots:[5461-10922] (5462 slots) master
   1 additional replica(s)
[OK] All nodes agree about slots configuration.
>>> Check for open slots...
>>> Check slots coverage...
[OK] All 16384 slots covered.

```

### Cluster Nodes

클러스터 상태 확인  

redis/script/cluster-nodes.sh
```bash
#!/bin/bash

redis-cli -a redis cluster nodes
```

\<id\> \<ip:port@cport\> \<flags\> \<master\> \<ping-sent\> \<pong-recv\> \<config-epoch\> \<link-state\> \<slot\> \<slot\> ... \<slot\>

| 필드명 | 설명  |
| --- | --- |
| id  | 노드가 생성될 때 자동으로 만들어지는 랜덤 스트링의 클러스터 ID 값이다. 노드에 한 번 할당된 ID는 바뀌지 않는다. |
| ip:port@cport | 노드가 실행되는 ip와 port 그리고 클러스터 버스 포트 값이다. 클러스터 포트 주소는 레디스 포트에 10000을 더한 값으로 자동으로 설정된다. |
| flags | 노드의 상태를 나타낸다. flag에는 다음과 같은 상태 값이 플래그로 표시될 수 있다.<br>• myself: redis-cli를 이용해 접근한 노드<br>• master: 마스터 노드<br>• slave: 복제본 노드<br>• fail?: 노드가 PFAIL 상태임을 의미(노드에 정상 접근을 할 수 없다는 것을 확인해 다른 노드에 확인을 하기 시작하는 상태)<br>• fail: 노드가 FAIL 상태임을 의미(과반수 이상의 노드가 해당 노드에 접근할 수 없다는 것을 인지한 뒤 PFAIL 상태로 FAIL 상태로 변경)<br>• handshake: 새로운 노드를 인지하고 핸드셰이킹을 하는 단계<br>• nofailover: 복제본 노드가 페일오버를 시도하지 않을 것임을 의미<br>• noaddr: 해당 노드의 주소를 모른다는 것을 의미<br>• noflags |
| master | 복제본 노드일 경우 마스터 노드의 ID, 마스터 노드일 경우 '-' 문자가 표시된다. |
| ping-sent | 보류 중인 PING이 없다면 0, 있다면 마지막 PING이 전송된 유닉스 타임을 표시한다. |
| pong-sent | 마지막 PONG이 수신된 유닉스 타임을 표시한다. |
| config-epoch | 현재 노드의 구성 에포크. 페일오버가 발생할 때마다 에포크는 증가하며, 구성 충돌이 있을 때 에포크가 높은 노드의 구성으로 변경된다. |
| link-state | 클러스터 버스에 사용되는 링크의 상태를 의미한다(connected/disconnected). |
| slot | 노드가 갖고 있는 해시슬롯의 범위를 표시한다. |

```log
dbb0922066607414a84dc5cd9835f073033c11bb 192.168.0.182:6379@16379 slave 314a87796f7365f49bc9bf5f04edfbd5cb339d0b 0 1765370055582 2 connected
1a26d03a8f9ee8026e32abc1092e25bf4a63d2da 192.168.0.6:6379@16379 slave ea005587a13b7b50cbc498da976abcf7e44b1a2d 0 1765370055583 1 connected
dcb44aa080e04845c1e0c8d7fd256fb9bda623bf 192.168.0.162:6379@16379 slave 1fdb4f59f79d071fb2730e7b7bbf34b926d048d1 0 1765370056084 3 connected
1fdb4f59f79d071fb2730e7b7bbf34b926d048d1 192.168.0.132:6379@16379 master - 0 1765370055582 3 connected 10923-16383
ea005587a13b7b50cbc498da976abcf7e44b1a2d 192.168.0.161:6379@16379 myself,master - 0 0 1 connected 0-5460
314a87796f7365f49bc9bf5f04edfbd5cb339d0b 192.168.0.13:6379@16379 master - 0 1765370055000 2 connected 5461-10922
```

### redis-cli connection

redis-cli -c -h \<ip\> -p \<port\> -a \<password\>

-c 옵션을 사용해 클러스터 모드로 사용할 수 있고, 이 경우 리디렉션 기능이 제공  

redis/script/redis-cli.sh
```bash
#!/bin/bash

redis-cli -c -a redis
```

