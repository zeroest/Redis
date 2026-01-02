
# ClusterClientOptions

```
client.setOptions(ClusterClientOptions.builder()
                       .autoReconnect(true)
                       .topologyRefreshOptions(topologyRefreshOptions)
                       .build());
```

- autoReconnect: default: true
  - 클러스터 노드와의 연결이 끊어진 경우 자동으로 재연결을 시도할지 여부를 설정한다.

# ClusterTopologyRefreshOptions

```
ClusterTopologyRefreshOptions topologyRefreshOptions = ClusterTopologyRefreshOptions.builder()
                .enablePeriodicRefresh(refreshPeriod(10, TimeUnit.MINUTES))
                .enableAllAdaptiveRefreshTriggers()
                .build();
```

https://redis.github.io/lettuce/advanced-usage/#cluster-specific-options

Lettuce RedisCluster를 사용할 경우 클러스터 토폴로지 정보를 주기적으로 가져와 업데이트 해야 한다.
노드가 추가/삭제/다운으로 인한 역할 변경(master -> replica) 등 클러스터 토폴로지 정보가 변경되었을 경우 최신 정보로 업데이트 해야 한다.
그렇지 않을 경우 서비스 전면 장애가 발생할 수 있다.

- dynamicRefreshSources: (default: true)
  - 새로고침시 발견된 모든 노드로부터 클러스터 토폴로지 정보를 얻어올 수 있다. false로 설정하면 초기 seed 노드에서만 클러스터 토폴로지 정보를 얻어온다.
- enablePeriodicRefresh: (default: false)
  - 주기적으로 클러스터 토폴로지 새로고침 활성화, 비활성화에 대한 설정이다. 활성화시 백그라운드에서 주기적으로 토폴로지 정보를 새로고침하여 얻어온다. 해당 주기를 설정하면 refreshPeriod 속성에 설정되어 정해진 주기로 동작하게 된다.
- enableAllAdaptiveRefreshTriggers: default: none,
  - 기본값으로는 사용하지 않음이다. 해당 설정은 선택적으로 적응형 토폴로지 새로고침 트리거를 활성화할지의 여부다. 말이 어려우니 자세히 풀어보면 해당 값을 설정할 경우 RefreshTrigger에 정의된 모든 enum으로 설정된 모든 refresh 이벤트에 대해 토폴로지 갱신을 실행한다. 예를 들어 MOVED, ACK 등 이벤트가 발생할마다 토폴로지를 갱신하는건데, 이벤트가 많이 발생하는 경우에는 성능적으로 이슈가 발생할 수도 있다.
- adaptiveRefreshTriggersTimeout: default: 30s
  - enableAllAdaptiveRefreshTriggers 설정의 타임아웃을 설정하는 것이다. 타임아웃 내 트리거는 무시되고, 첫 번째로 활성화된 트리거만이 토폴로지 새로고침을 유발하게 된다.


```
List<String> nodes = Collections.singletonList(redisProperties.getClusterEndPoint());
            RedisClusterConfiguration configuration = new RedisClusterConfiguration(nodes);

            // topology refresh option
            ClusterTopologyRefreshOptions topologyRefreshOptions = ClusterTopologyRefreshOptions.builder()
                .dynamicRefreshSources(true) 
                .enablePeriodicRefresh(Duration.ofSeconds(60)) 
                .enableAllAdaptiveRefreshTriggers()
                .adaptiveRefreshTriggersTimeout(Duration.ofSeconds(30))
                .build();

            // clusterClientOptions
            ClusterClientOptions clientOptions = ClusterClientOptions.builder()
                .autoReconnect(true)
                .topologyRefreshOptions(topologyRefreshOptions)
                .build();

            LettuceClientConfiguration clientConfig = LettuceClientConfiguration
                .builder()
                .clientOptions(clientOptions)
                .readFrom(ReadFrom.REPLICA_PREFERRED)
                .build();

            return new LettuceConnectionFactory(configuration, clientConfig);
```
