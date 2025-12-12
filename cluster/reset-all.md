
# 클러스터 초기화 

클러스터의 데이터를 모두 날리고 초기화 한다

1. 데이터 클렌징

```bash
redis-cli

> flushall
```

2. 노드 리셋 

```bash
redis-cli

> cluster reset hard
```

3. 클러스터 생성

```bash
redis-cli --cluster create rm1:6379 rm2:6379 rm3:6379 rr1:6379 rr2:6379 rr3:6379 --cluster-replicas 1 -a redis
```


클라이언트 연결을 중단시키려면 redis.conf 설정에 bind 를 로컬로 돌려서 처리해주자

- 로컬 바인딩
```bash
redis-cli

> config set bind 127.0.0.1
```

- 복구
```bash
redis-cli

> config set bind 0.0.0.0
```
