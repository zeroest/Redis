
# Redis Config

## PATH setup

```
vim ~/.bashrc

export PATH=$PATH:/home/ubuntu/redis/bin
```

## maxmemroy

```
maxmemory 768mb
maxmemory-policy allkeys-lru
```

Redis의 maxmemory 설정 최적의 값은 전체 RAM의 40~70% 정도가 일반적이지만, 시스템 여유 메모리를 20% 이상 남겨두고 설정하며, 실제 환경에 맞게 maxmemory-policy (e.g., allkeys-lru, volatile-lru)를 함께 설정하는 것이 핵심입니다. 메모리 단편화(fragmentation)와 운영체제 및 Redis 자체의 메모리 사용을 고려하여, 실제 사용량보다 약간 낮게 설정하고, Eviction(삭제) 정책을 활용해 메모리를 관리하는 것이 중요합니다. 

maxmemory 설정 권장 사항
- 보수적 접근 (Conservative): 전체 RAM의 약 40~50% 정도를 maxmemory로 설정하고, 시스템 여유분으로 20% 이상을 남겨둡니다.
- 최대치 접근 (Aggressive): 캐시 효율을 극대화하려면 70~80%까지 설정하기도 하지만, 메모리 단편화로 인해 실제보다 더 많은 메모리가 필요할 수 있어 주의해야 합니다.
- 핵심: 시스템 메모리(RAM) 전체를 Redis에 할당하지 않고, 운영체제 및 Redis 자체의 오버헤드(메모리 단편화 등)를 위해 충분한 여유 공간을 남겨두는 것이 안정적입니다. 

maxmemory-policy 설정
- allkeys-lru (가장 일반적): 메모리가 가득 찼을 때 가장 최근에 사용되지 않은(LRU) 키부터 삭제합니다. 캐시 시나리오에 적합합니다.
- volatile-lru: TTL(만료 시간)이 설정된 키 중에서 LRU 키를 삭제합니다.
- allkeys-lfu
- volatile-lfu
- allkeys-random 또는 volatile-random: 무작위로 키를 삭제합니다.
- noeviction: 메모리가 가득 차면 쓰기(Write) 명령을 거부합니다 (데이터 손실 방지). 
- volatile-ttl

최적의 적용 방법
- 모니터링: redis-cli의 INFO memory 명령이나 모니터링 도구로 실제 메모리 사용량, 단편화율, Eviction 발생률을 지속적으로 확인합니다.
- 조정: 사용 패턴에 따라 maxmemory와 maxmemory-policy를 반복적으로 조정하며 최적의 조합을 찾습니다.
- 팁: 메모리 단편화가 심하다면, Redis 재시작, 복제본(replica) 재설정, 또는 메모리 압축(compression) 기능(6GB 이상 Redis에서 고려) 등을 통해 관리할 수 있습니다. 
