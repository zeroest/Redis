
# Failover

## 커맨드 사용 페일오버 (수동 페일오버)

페일오버 시키고자 하는 마스터에 1개 이상의 복제본이 연결되어 있어야 한다  
페일오버를 발생시킬 복제본 노드에서 cluster failover 커맨드를 실행하면 페일오버를 발생시킬 수 있다  

- MASTER-1 - REPLICA-1 (cluster failover)
- MASTER-2 - REPLICA-2
- MASTER-3 - REPLICA-3

REPLICA-1 에서 아래 커맨드를 실행 한다

레플리케이션 상태를 확인한다  

```bash
redis-cli -c

> INFO REPLICATION
```

```log
127.0.0.1:6379> INFO REPLICATION
# Replication
role:slave
master_host:192.168.0.161
master_port:6379
master_link_status:up
master_last_io_seconds_ago:8
master_sync_in_progress:0
slave_read_repl_offset:4760
slave_repl_offset:4760
replica_full_sync_buffer_size:0
replica_full_sync_buffer_peak:0
master_current_sync_attempts:1
master_total_sync_attempts:1
master_link_up_since_seconds:3395
total_disconnect_time_sec:0
slave_priority:100
slave_read_only:1
replica_announced:1
connected_slaves:0
master_failover_state:no-failover
master_replid:2b3d1a5c9c4d97f8788a93384d529a9bad4a123a
master_replid2:0000000000000000000000000000000000000000
master_repl_offset:4760
second_repl_offset:-1
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:15
repl_backlog_histlen:4746
```

failover 실행

```bash
redis-cli -c

> CLUSTER FAILOVER
```

```log
OK
```

failover 이후 다시 INFO REPLICATION 커맨드를 이용하여 상태를 확인한다  

```bash
redis-cli -c

> INFO REPLICATION
```

```log
# Replication
role:master
connected_slaves:1
slave0:ip=192.168.0.161,port=6379,state=online,offset=5180,lag=0
master_failover_state:no-failover
master_replid:7e7cf9c5525c508599d0e782c660d360dd060b5f
master_replid2:2b3d1a5c9c4d97f8788a93384d529a9bad4a123a
master_repl_offset:5180
second_repl_offset:5167
repl_backlog_active:1
repl_backlog_size:1048576
repl_backlog_first_byte_offset:15
repl_backlog_histlen:5166
```

수동 페일오버가 진행되는 동안 기존 마스터에 연결된 클라이언트는 잠시 블락된다  
페일오버를 시작하기 전 복제 딜레이를 기다린 뒤, 마스터의 복제 오프셋을 복제본이 따라잡는 작업이 완료되면 페일오버를 시작한다  
페일오버가 완료되면 클러스터의 정보를 변경하고, 모든 작업이 완료되면 클라이언트는 새로운 마스터로 리디렉션된다  

## 마스터 중단을 통한 페일오버 (자동 페일오버)

직접 마스터 노드에 장애를 발생시킨 뒤 페일오버가 잘 발생하는지 확인  
마스터의 상태가 정상이 아닐 경우 다른 노드에서 이를 인지할 수 있는지 확인  

다음과 같이 레디스 프로세스를 shutdown  

```bash
redis-cli -a redis -h <master-host> -p <master-port> shutdown
```

cluster-node-timeout 시간 동안 마스터에서 응답이 오지 않으면 마스터의 상태가 정상적이지 않다고 판단해 페일오버를 트리거 한다  
기본값 15,000 ms = 15 seconds

```bash
redis-cli -a redis cluster nodes
```

```log
dbb0922066607414a84dc5cd9835f073033c11bb 192.168.0.182:6379@16379 slave 314a87796f7365f49bc9bf5f04edfbd5cb339d0b 0 1765372569760 2 connected
1a26d03a8f9ee8026e32abc1092e25bf4a63d2da 192.168.0.6:6379@16379 master,fail - 1765372477043 1765372475529 7 disconnected
dcb44aa080e04845c1e0c8d7fd256fb9bda623bf 192.168.0.162:6379@16379 slave 1fdb4f59f79d071fb2730e7b7bbf34b926d048d1 0 1765372569256 3 connected
1fdb4f59f79d071fb2730e7b7bbf34b926d048d1 192.168.0.132:6379@16379 master - 0 1765372570062 3 connected 10923-16383
ea005587a13b7b50cbc498da976abcf7e44b1a2d 192.168.0.161:6379@16379 myself,master - 0 0 8 connected 0-5460
314a87796f7365f49bc9bf5f04edfbd5cb339d0b 192.168.0.13:6379@16379 master - 0 1765372569558 2 connected 5461-10922
```
