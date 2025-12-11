
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

## 서버 환결 설정

### Open files 확인

레디스의 기본 maxclients 설정값은 10000이다. 이는 레디스 프로세스에서 받아들일 수 있는 최대 클라이언트의 개수를 의미한다. 하지만 이 값은 레디스를 실행하는 서버 의 파일 디스크립터 수에 영향을 받는다. 레디스 프로세스 내부적으로 사용하기 위해 예약한 파일 디스크립터 수는 32개로, maxclients 값에 32를 더한 값보다 서버의 최 대 파일디스크립터 수가 작으면 레디스는 실행될 때 자동으로 그 수에 맞게 조정된다.

따라서 만약 레디스의 최대 클라이언트 수를 기본값인 10000으로 지정하고 싶으면 서버의 파일 디스크립터 수를 최소 10032 이상으로 지정해야 한다. 현재 서버의 파일 디스크립터 수는 다음 커맨드로 확인할 수 있다.

```bash
ulimit -a | grep open
```

```log
open files                          (-n) 1024
```

만약 위 커맨드로 확인한 open files의 값이 10032보다 작다면 /etc/security/limits.conf 파일에 다음과 같은 구문을 추가하자.

```bash
sudo vim /etc/security/limits.conf
```

```conf
* hard nofile 100000
* soft notile 100000
```

위 설정은 서버 재부팅시 반영되는 설정이고 현재 세션에서 바로 반영이 필요하다면 아래와 같이 커맨드를 실행한다

```bash
ulimit -n 10000
```

```bash
ulimit -a | grep open

# open files                          (-n) 10000
```

### THP 비활성화

리눅스는 메모리를 페이지 단위로 관리하며 기본 페이지는 4096바이트(4kb)로 고정돼 있다.
메모리 크기가 커질수록 페이지를 관리하는 테이블인 TLB의 크기도 커져, 메모리를 사용할 때 오버헤드가 발생하는 이슈로 인해 페이지를 크게 만든 뒤 자동으로 관리하는 THP(Transparent Huge Page) 기능이 도입됐다.

하지만 레디스와 같은 데이터베이스 어플리케이션에서는 오히려 이 기능을 사용할 때 퍼모먼스가 떨어지고 레이턴시가 올라가는 현상이 발생하기 때문에 레디스를 사용할땐 이 기능을 사용하지 않는 것을 추천한다.

다음 커맨드로 THP를 비활성화 할 수 있다.

```bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

위 커맨드는 일시적으로 hugepage를 비활성화하는 것이고, 영구적으로 이 기능을 비활 성화하고 싶다면 /etc/rc.local 파일에 다음 구문을 추가하자.

```bash
vim /etc/rc.local
```

```
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then 
  echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi
```

다음 커맨드를 수행하면 부팅 중 Ic.local 파일이 자동으로 실행되도록 설정할 수 있다.

```bash
chmod +x /etc/rc.d/rc.local
```

### vm.overcommit_memory=1

레디스는 디스크에 파일을 저장할 때 fork()를 이용해 백그라운드 프로세스를 만드는 데, 이때 COW(Copy on Wite) 라는 메커니즘이 동작한다. 
이 메커니즘에서는 부모 프로세 스와 자식 프로세스가 동일한 메모리 페이지를 공유하다가 레디스의 데이터가 변경될 때마다 메모리 페이지를 복사하기 때문에 데이터 변경이 많이 발생하면 메모리 사용 량이 빠르게 증가할 수 있다.

따라서 레디스 프로세스가 실행되는 도중 메모리를 순간적으로 초과해 할당해야 하는 상황이 발생할 수 있으며, 이를 위해 vm.overcommit_memory를 1로 설정하는 것이 좋다.

기본적으로 vm.overcommit_memory 값은 0으로 설정돼 있어, 필요한 메모리를 초과해 할당되는 것을 제한한다. 
그러나 레디스를 사용할 때에는 이 값을 조절해 메모리의 과도한 사용이나 잘못된 동작을 예방하고, 백그라운드에서 데이터를 저장하는 과정에서의 성능 저하나 오류를 방지할 수 있게 설정해야 한다.

/etc/sysctl.conf 파일에 vm.overcommit_memory=1 구문을 추가하면 영구적으로 해당 설정을 적용할 수 있으며, 재부팅 없이 바로 설정을 적용하려면 sysctl vm.overcommit_memory=1을 수행하자.

```bash
vim /etc/sysctl.conf

```

```bash
sysctl vm.overcommit_memory=1
```

### somaxconn과 syn_backlog 설정 변경

레디스의 설정 파일의 tcp-backlog 파라미터는 레디스 인스턴스가 클라이언트와 통신 할 때 사용하는 tcp backlog 큐의 크기를 지정한다. 
이때 redis.conf에서 지정한 tcp-backlog 값은 서버의 somaxconn socket max connection 과 syn_backlog 값보다 클 수 없다. 
기본 tcp-backlog 값은 511이므로, 서버 설정이 최소 이 값보다 크도록 설정해야 한다.

서버의 현재 설정값은 다음 커맨드로 확인할 수 있다.

```bash
sysctl -a | grep syn_backlog

# net.ipv4.tcp_max_syn_backlog = 128

sysctl -a | grep somaxconn

# net.core.somaxconn = 4096
```

/etc/sysctl.conf 파일에 다음 구문을 추가하면 영구적으로 해당 설정을 적용할 수 있다

```
net.ipv4.tcp_max_syn_backlog = 1024
# net.core.somaxconn = 1024
```

재부팅 없이 바로 설정을 적용하려면 다음 커맨드를 수행하자

```bash
sysctl net.ipv4.tcp_max_syn_backlog=1024
# sysctl net.core.somaxconn = 1024
```