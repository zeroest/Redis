
# Binary Install

## [[Doc] Install Redis from Source](https://redis.io/docs/latest/operate/oss_and_stack/install/archive/install-redis/install-redis-from-source/)


stable 버전 다운로드 
- [https://download.redis.io/redis-stable.tar.gz](https://download.redis.io/redis-stable.tar.gz)

releases 버전들 확인 가능 
- [https://download.redis.io/releases/](https://download.redis.io/releases/)

releases 버전별 패치내역 확인
- [https://github.com/redis/redis/releases](https://github.com/redis/redis/releases)

원하는 버전의 레디스 패키지 파일을 다운로드 하고, 다음 커맨드를 통해 레디스를 빌드한다.  
gcc 버전 4.6 이상이 필요하므로 gcc를 미리 설치하는것이 좋다.

gcc install 
```
yum install -y gcc 
```

redis install
```bash
wget https://download.redis.io/releases/redis-8.4.0.tar.gz

tar -xzvf redis-8.4.0.tar.gz

cd redis-8.4.0

make
```

```log
for dir in src; do /Library/Developer/CommandLineTools/usr/bin/make -C $dir all; done
    CC Makefile.dep

...
...
...

Hint: It's a good idea to run 'make test' ;)
```

make 완료 후 기본 디렉터리 내 bin 디렉터리에 실행 파일을 복사하기 위해 make install 커맨드를 프리픽스 지정과 함께 수행

```bash
make PREFIX=/path/to/prefix/redis install
```

```log
for dir in src; do /Library/Developer/CommandLineTools/usr/bin/make -C $dir install; done
    CC Makefile.dep
    CC release.o
    LINK redis-server
    INSTALL redis-sentinel
    LINK redis-cli
    LINK redis-benchmark
    INSTALL redis-check-rdb
    INSTALL redis-check-aof
/Library/Developer/CommandLineTools/usr/bin/make -C ../tests/modules
make[2]: Nothing to be done for `all'.

Hint: It's a good idea to run 'make test' ;)

    INSTALL redis-server
    INSTALL redis-benchmark
    INSTALL redis-cli
```

```bash
ls /path/to/prefix/redis/bin
```

```log
redis-benchmark redis-check-aof redis-check-rdb redis-cli       redis-sentinel  redis-server
```

다음 커맨드를 이용하여 레디스를 foreground 모드로 실행하여 테스트 해보자

```bash
./redis-server redis.conf
```

```log
48610:C 10 Dec 2025 16:14:11.897 * oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
48610:C 10 Dec 2025 16:14:11.897 * Redis version=8.4.0, bits=64, commit=00000000, modified=1, pid=48610, just started
48610:C 10 Dec 2025 16:14:11.897 # Warning: no config file specified, using the default config. In order to specify a config file use ./redis-server /path/to/redis.conf
48610:M 10 Dec 2025 16:14:11.898 * Increased maximum number of open files to 10032 (it was originally set to 256).
48610:M 10 Dec 2025 16:14:11.898 * monotonic clock: POSIX clock_gettime
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis Open Source
  .-`` .-```.  ```\/    _.,_ ''-._      8.4.0 (00000000/1) 64 bit
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 48610
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

48610:M 10 Dec 2025 16:14:11.899 # WARNING: The TCP backlog setting of 511 cannot be enforced because kern.ipc.somaxconn is set to the lower value of 128.
48610:M 10 Dec 2025 16:14:11.901 * Server initialized
48610:M 10 Dec 2025 16:14:11.902 * Ready to accept connections tcp

^C
48610:signal-handler (1765350924) Received SIGINT scheduling shutdown...
48610:M 10 Dec 2025 16:15:24.085 * User requested shutdown...
48610:M 10 Dec 2025 16:15:24.085 * Saving the final RDB snapshot before exiting.
48610:M 10 Dec 2025 16:15:24.086 * BGSAVE done, 0 keys saved, 0 keys skipped, 88 bytes written.
48610:M 10 Dec 2025 16:15:24.091 * DB saved on disk
48610:M 10 Dec 2025 16:15:24.091 # Redis is now ready to exit, bye bye...
```



