
# ACL

레디스 버전 6부터 유저를 생성하고 유저별로 권한을 제어할 수 있는 ACL 기능 도입

**⚠️ ACL 설정 명령어 실행시 모든 서버에 같이 실행해야한다, 서버별로 유저설정이 가능, 즉 모든 서버에 같은 ACL 설정을 적용하고 싶다면 모든 서버에 적용 및 ACL SAVE 하도록 한다**

## Config

ACL 규칙은 파일로 관리할 수 있다. 기본적으로는 일반 설정 파일인 redis.conf에 저장되며, ACL 파일을 따로 관리해 유저 정보만 저장하는 것도 가능하다.

redis.conf 파일 내 aclfile 로 acl 적용하고자 하는 설정 파일을 설정한다

**aclfile 경로에 파일을 미리 만들지 않고 서버 실행시 오류 발생과 함께 서버가 뜨지 않는다**

```bash
mkdir /home/ubuntu/redis/acl
touch /home/ubuntu/redis/acl/users.acl
```

```conf
aclfile /home/ubuntu/redis/acl/users.acl
```

아래와 같이 acl 파일에 사용자 설정을 반영해주면 된다  

**protected-mode yes 설정시 default user 의 비밀번호를 requirepass 와 같이 설정해주자**  

```bash
vim /home/ubuntu/redis/acl/users.acl

user default on >redis ~* +@all
user admin on >admin ~* &* +@all 
user hello on >world ~SERVICE:A:* &* +@all -@dangerous
```

ACL 파일을 사용하지 않을 때에는 CONFIG REWRITE 커맨드를 이용해 레디스의 모든 설정값과 ACL 룰을 한 번에 redis.conf에 저장할 수 있다.
다만 ACL 파일을 따로 관리할 경우 ACL LOAD나 ACL SAVE 커맨드를 이용해 유저 데이터를 레디스로 로드하거나 저장하는 것이 가능해지기 때문에 운영 측면에서 조금 더 유용하게 사용할 수 있다. ACL 파일을 따로 사용한다고 지정해뒀을 때 CONFIG REWRITE 커맨드를 사용하면 ACL 정보는 저장되지 않는다는 점에 유의해야 한다.

## 왜 “requirepass redis”를 넣었는데도 “default user 비밀번호 없음”이 나오나?

Redis 6+에서 ACL이 켜진 상태(aclfile 사용)면, 보안 판단 기준이 사실상 ACL의 default user 쪽으로 갑니다.  

지금 설정이:
- protected-mode yes
- requirepass redis
- aclfile 활성 + acl 파일은 비어있음

이면, 실제로는 default user가 여전히 “nopass” 상태  
즉, requirepass만으로 default user 패스워드가 확실히 설정되지 않은 상태  

### 방법 A) default 유저에 ACL로 비밀번호를 “명시적으로” 설정 (추천)

```bash
redis-cli -h 127.0.0.1 -p 6379 ACL SETUSER default on >redis ~* +@all
redis-cli -h 127.0.0.1 -p 6379 ACL SAVE
```

- >redis : 비밀번호 설정
- ~* +@all : 모든 키/커맨드 허용(운영 정책에 맞게 제한 가능)
- ACL SAVE : aclfile에 저장 (비어있던 파일이 채워짐)

### 방법 B) acl 파일에 user default 를 직접 설정 (가장 명시적)

```users.acl
user default on >redis ~* +@all
```

## Create user

```
            ⎾ 이름              ⎾ 비밀번호                  ⎾ 접근가능한pub/sub채널
ACL SETUSER username    on     >password    ~cached:*    &*    +@all -@dangerous
            ⎺⎺⎺⎺⎺⎺⎺⎺    ⎺⎺      ⎺⎺⎺⎺⎺⎺⎺⎺     ⎺⎺⎺⎺⎺⎺⎺⎺     ⎺     ⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺⎺
                       ⎿ 활성 상태            ⎿ 접근가능한키        ⎿ 실행가능한커맨드
```

username 이라는 이름을 가진 활성 상태의 유저를 생성
- 패스워드: password
- 접근가능키: cached: prefix 로 시작하는 키들에 접근 가능
- 접근가능pub/sub채널: * 로 모든 채널에 접근 가능
- 실행가능커맨드: 위험한 커맨드 제외한 전체 커맨드를 사용할 수 있는 권한

```bash
redis-cli 

127.0.0.1:6379> ACL SETUSER hello on >world ~SERVICE:A:* &* +@all -@dangerous
OK
```

레디스에서 ACL 규칙은 항상 왼쪽에서 오른쪽으로 적용되기 때문에 권한을 적용하는 순서가 중요하다.

### 유저 상태 제어

유저의 활성 상태는 on과 off로 제어할 수 있다. on일 경우 해당 유저로의 접근을 허용 함을 의미한다. on이라는 구문 없이 유저를 생성하면 기본으로 off 상태의 유저가 만 들어지기 때문에 생성 구문에 on을 명시하거나 acl setuser 〈username〉 on 구문을 추 후에 사용해 on 상태로 변경해야 한다.  
활성 상태였던 유저의 상태를 off로 변경한다면 더 이상 이 유저로 접근할 수 없지만, 이미 접속해 있는 유저의 연결은 여전히 유지된다.

### 패스워드 

>패스워드 키워드로 패스워드를 지정할 수 있다. 패스워드는 1개 이상 지정할 수 있으며, <패스워드 키워드를 사용하면 지정한 패스워드를 삭제할 수 있다. 기본적으로 패스워드를 지정하지 않으면 유저에 접근할 수 없으나, nopass 권한을 부여하면 유저에는 패스워드 없이 접근할 수 있다. 또한 유저에 nopass 권한을 부여하면 기존 유저에 설정돼 있는 모든 패스워드도 모두 삭제된다.  

유저에 resetpass 권한을 부여하면 유저에 저장된 모든 패스워드가 삭제되며, 이때 nopass 상태도 없어진다. 즉 유저에 대해 resetpass 키워드를 사용하면 추가로 다른 패스워드나 nopass 권한을 부여하기 전까지는 그 유저에 접근할 수 없게 된다.

ACL을 이용해 패스워드를 저장하면 내부적으로 SHA256 방식으로 암호화 돼 저장되기 때문에 유저의 정보를 확인하고자 해도 패스워드 정보를 바로 조회할 수 없다.

난수 생성가능 

```bash
redis-cli

acl genpass
```

### 커맨드 권한 제어 

ACL 기능을 이용해 유저가 사용할 수 있는 커맨드를 제어할 수 있다  

+@all 혹은 allcommands 키워드는 모든 커맨드의 수행 권한을 부여한다는 것을 의미하며, -@all 혹은 nocommands는 아무런 커맨드를 수행할 수 없다는 것을 뜻한다. 커맨드 권한에 대한 언급 없이 유저를 만들면 -@all 권한의 유저가 생성된다.

특정 카테고리의 권한을 추가하려면 +ocategory〉, 제외하려면 -0〈category〉를 사용할 수 있으며, 개별 커맨드의 권한을 추가, 제외하려면 0없이 바로 +<command>나
-〈command》를 사용하면 된다.

```
ACL SETUSER user1 +@all -@admin +bgsave +slowlog|get
```

ACL 룰은 왼쪽부터 오른쪽으로 순서대로 적용된다. 따라서 앞서 나온 커맨드를 실행 시키면 user1에 모든 커맨드의 수행 권한을 부여한 뒤, admin 카테고리의 커맨드 수행 권한은 제외시킨다. 그 뒤 bgsave 커맨드와 Slowlog 커맨드 중 get이라는 서브 커맨드에 대한 수행 권한만 추가로 다시 부여하게 된다.

ACL CAT 커맨드를 이용하면 레디스에 미리 정의돼 있는 카테고리의 커맨드 list를 확 인할 수 있다.

```
ACL CAT
```

각 카테고리에 포함된 상세 커맨드를 확인하려면 ACL CAT <카테고리명>으로 확인할 수 있다.

```
ACL CAT <카테고리명>
```

#### 중요 커맨드

**dangerous**

위험할 수 있는 커맨드가 포함 돼 있다. 레디스 구성을 변경하는 커맨드, 혹은 한 번 수행하면 오래 수행할 수 있는 가능성이 있어 장애를 발생시킬 수 있는 커맨드, 혹은 운영자가 아니면 사용하지 않아 도 되는 커맨드가 포함돼 있다

구성 변경 커맨드
1. replconf
2. replicaof
3. migrate
4. failover

장애 유발 커맨드
5. sort
6. flushdb
7. flushall
8. keys

운영 커맨드
- shutdown
- monitor
- acl|log, acl|deluser, acl|list, acl|setuser
- bgsave, bgrewriteaof
- info
- config|get, config|set, config|rewrite, config|resetstat
- debug
- cluster|addslots, cluster|forget, cluster|failover 
- latency|graph, latency|doctor, latency|reset, latency|history 
- client|list, client|kill, client|pause 
- module|loadex, module|list, module|unload

**admin**

admin 카테고리는 dangerous 카테고리에서 장애 유발 커맨드를 제외한 커맨드가 들 어 있다. keys 혹은 Sort, flushall과 같은 커맨드는 구성을 변경하거나 운영과 관련 된 커맨드는 아니고, 잘 모르고 사용했을 때 장애를 유발할 수 있는 커맨드이기 때문 에 상황에 따라 개발자가 사용할 수 있도록 제공해줄 경우가 필요할 수 있다. 예를 들 어 개발 용도의 레디스 인스턴스를 제공할 때는 위와 같은 커맨드를 사용할 수 있도록
admin 카테고리만 제외시킨 권한을 전달해줄 수 있을 것이다.

**fast**

O(1)로 수행되는 커맨드를 모아 놓은 카테고리다. get, Spop, hset 등의 커맨드가 포함 돼 있다.

**slow**

fast 카테고리에 속하지 않은 커맨드가 들어 있으며 scan, set, setbit, sunion 등의 커 맨드를 포함한다.

**keyspace**

키와 관련된 커맨드가 포함된 카테고리다. Scan, keys를 포함해 rename, type, expire, exists 등 키의 이름을 변경하거나 키의 종류를 파악하거나, 키의 TTL 값을 확인하거 나 혹은 키가 있는지 확인하는 등의 커맨드를 포함한다.

**read**

데이터를 읽어오는 커맨드가 포함된 카테고리다. 각 자료 구조별 읽기 전용으로 키를 읽어오는 커맨드를 포함한다. get, hget,xtrange 등이 있다

**write**

메모리에 데이터를 쓰는 커맨드가 포함된 카테고리다. set, Iset, setbit, hmset 등을 포함한다. 키의 만료 시간 등의 메타데이터를 변경하는 expire, pexpire와 같은 커맨드 도 포함한다.

### 키 접근 제어

유저가 접근할 수 있는 키도 제어할 수 있다. 레디스에서는 프리픽스를 사용해 키를 생성하는 것이 일반적이며, 프리픽스 규칙을 미리 정해뒀다면 특정한 프리픽스를 가 지고 있는 키에만 접근할 수 있도록 제어할 수 있다.

레디스 버전 7부터는 키에 대한 읽기, 쓰기 권한을 나눠서 부여할 수도 있다.
`%R~<pattern〉` 커맨드는 키에 대한 읽기 권한을, `%W~〈pattern〉` 커맨드는 키에 대한 쓰기 권한을 부여함을 의미한다. `%RW~〈pateern>`으로 읽기, 쓰기 권한을 모두 부여할 수 있으나, 이는 앞서 소개한`~<pattern>`과 동일함을 의미한다

loguser라는 유저에게 log: 프리픽스에 대한 모든 접근 권한을 부여하고 싶지만, mail: 이나 sms:에 대해서는 읽기 접근 권한만 부여하고 싶다면 다음과 같이 수행할 수 있다.

```
ACL SETUSER loguser ~log:* %R~mail:* %R~sms:*

COPY mail:1 log:mail:1
```

resetkeys 커맨드를 사용하면 유저가 가지고 있는 키에 대한 접근 권한이 모두 초기화 된다.

### 셀렉터

셀렉터(selector)는 버전 7에서 새로 추가된 개념으로, 좀 더 유연한 ACL 규칙을 위해 도입됐다  

```
ACL SETUSER loguser ~log:* %R~mail:* %R~sms:*
```

loguser는 mail:* 프리픽스 키에 대한 메타데이터도 가지고 올 수 있다. 예를 들어 mail:1 키에 대한 만료 시간이 얼마나 남았는지 등의 정보도 확인할 수 있다  
하지만 loguser라는 유저는 mail:* 프리픽스 커맨드에 대해 다른 읽기 커맨드가 아닌 오직 GET 커맨드만 사용하도록 강제하고 싶을 수 있다.  
이럴 경우 사용할 수 있는 것이 바로 셀렉터다.

```
ACL SETUSER loguser resetkeys ~log:* (+GET ~mail:*)
```

위의 규칙에서 괄호 안에 정의된 것이 바로 셀렉터다. 위 명령어는 loguser에 정의된 모든 키를 리셋하고(resetkeys) log:에 대한 모든 접근 권한을 부여한 뒤, mail: 에 대해서 는 get만 가능하도록 설정한 것을 의미한다.

### pub/sub 채널 접근 제어

`&<pattern〉` 키워드로 pub/sub 채널에 접근할 수 있는 권한을 제어할 수 있다. all channels 또는 &* 키워드로는 전체 pub/sub 채널에 접근할 수 있는 권한이 부여되며, resetchannels 권한은 어떤 채널에도 발행 또는 구독할 수 없음을 의미한다. 유저를 생성하면 기본으로 resetchanels 권한을 부여받는다

### 유저 초기화  

reset 커맨드를 이용해 유저에 대한 모든 권한을 회수하고 기본 상태로 변경할 수 있다. reset 커맨드를 사용하면 resetpass, resetkeys, resetchannels, off, -@all 상태로 변경돼 ACL SETUSER를 한 직후와 동일해진다

## Get user

```bash
redis-cli acl list

127.0.0.1:6379> acl list

1) "user default on sanitize-payload #34fb46c847bb9df96e5205a39d382f648a6e8dce1e014cd85b4ca6a88d88ed03 ~* &* +@all"
2) "user hello on sanitize-payload #486ea46224d1bb4fb680f34f7c9ad96a8f24ec88be73ea8e5a6c65260e9cb8a7 ~SERVICE:A:* &* +@all -@dangerous"
```

```bash
redis-cli 

127.0.0.1:6379> ACL GETUSER hello
 1) "flags"
 2) 1) "on"
    2) "sanitize-payload"
 3) "passwords"
 4) 1) "486ea46224d1bb4fb680f34f7c9ad96a8f24ec88be73ea8e5a6c65260e9cb8a7"
 5) "commands"
 6) "+@all -@dangerous"
 7) "keys"
 8) "~SERVICE:A:*"
 9) "channels"
10) "&*"
11) "selectors"
12) (empty array)

```

## Update user

hello 유저에게 SERVICE:B: 로 시작하는 프리픽스를 가진 키에도 접근할 수 있는 권한을 부여하고 싶다면 다음과 같이 ACL SETUSER 를 한번 더 수행한다  

```bash
redis-cli

127.0.0.1:6379> ACL SETUSER hello ~SERVICE:B:*
OK
```

```bash
redis-cli

127.0.0.1:6379> ACL GETUSER hello
 1) "flags"
 2) 1) "on"
    2) "sanitize-payload"
 3) "passwords"
 4) 1) "486ea46224d1bb4fb680f34f7c9ad96a8f24ec88be73ea8e5a6c65260e9cb8a7"
 5) "commands"
 6) "+@all -@dangerous"
 7) "keys"
 8) "~SERVICE:A:* ~SERVICE:B:*"
 9) "channels"
10) "&*"
11) "selectors"
12) (empty array)
```

## Delete user

```bash
redis-cli 

127.0.0.1:6379> ACL DELUSER hello
(integer) 1
```

```bash
redis-cli

127.0.0.1:6379> ACL GETUSER hello
(nil)
```



## Command Categories

[[doc] Command categories](https://redis.io/docs/latest/operate/oss_and_stack/management/security/acl/#command-categories)


The following is a list of command categories and their meanings:

- admin - Administrative commands. Normal applications will never need to use these. Includes REPLICAOF, CONFIG, DEBUG, SAVE, MONITOR, ACL, SHUTDOWN, etc.
- bitmap - Data type: all bitmap related commands.
- blocking - Potentially blocking the connection until released by another command.
- connection - Commands affecting the connection or other connections. This includes AUTH, SELECT, COMMAND, CLIENT, ECHO, PING, etc.
- dangerous - Potentially dangerous commands (each should be considered with care for various reasons). This includes FLUSHALL, MIGRATE, RESTORE, SORT, KEYS, CLIENT, DEBUG, INFO, CONFIG, SAVE, REPLICAOF, etc.
- fast - Fast O(1) commands. May loop on the number of arguments, but not the number of elements in the key.
- geo - Data type: all geospatial index related commands.
- hash - Data type: all hash related commands.
- hyperloglog - Data type: all hyperloglog related commands.
- keyspace - Writing or reading from keys, databases, or their metadata in a type agnostic way. Includes DEL, RESTORE, DUMP, RENAME, EXISTS, DBSIZE, KEYS, SCAN, EXPIRE, TTL, FLUSHALL, etc. Commands that may modify the keyspace, key, or metadata will also have the write category. Commands that only read the keyspace, key, or metadata will have the read category.
- list - Data type: all list related commands.
- pubsub - all pubsub related commands.
- read - Reading from keys (values or metadata). Note that commands that don't interact with keys, will not have either read or write.
- scripting - Scripting related.
- set - Data type: all set related commands.
- sortedset - Data type: all sorted set related commands.
- slow - All commands that are not fast.
- stream - Data type: all stream related commands.
- string - Data type: all string related commands.
- transaction - WATCH / MULTI / EXEC related commands.
- write - Writing to keys (values or metadata). Note that commands that don't interact with keys, will not have either read or write.

[[doc] Redis 8 introduces the following data structure and processing engine ACL categories.](https://redis.io/docs/latest/operate/oss_and_stack/stack-with-enterprise/release-notes/redisce/redisos-8.0-release-notes/#redis-8-introduces-the-following-data-structure-and-processing-engine-acl-categories)

- search - All search related commands. Only ACL users with access to a superset of the key prefixes defined during index creation can create, modify, or read the index. For example, a user with the key ACL pattern h:* can create an index with keys prefixed by h:* or h:p*, but not keys prefixed by h*, k:*, or k*, because these prefixes may involve keys to which the user does not have access. 1
- json - Data type: all JSON related commands. 1
- timeseries - Data type: all time series related commands. 1
- bloom - Data type: all Bloom filter related commands. 1
- cuckoo - Data type: all Cuckoo filter related commands. 1
- topk - Data type: all top-k related commands. 1
- cms - Data type: count-min sketch related commands. 1
- tdigest - Data type: all t-digest related commands. 1

