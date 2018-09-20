# ribbon负载均衡

## 1. 类组成

| Bean Type                  | Bean Name                 | Class Name                       |
| -------------------------- | ------------------------- | -------------------------------- |
| `IClientConfig`            | `ribbonClientConfig`      | `DefaultClientConfigImpl`        |
| `IRule`                    | `ribbonRule`              | `ZoneAvoidanceRule`              |
| `IPing`                    | `ribbonPing`              | `DummyPing`                      |
| `ServerList<Server>`       | `ribbonServerList`        | `ConfigurationBasedServerList`   |
| `ServerListFilter<Server>` | `ribbonServerListFilter`  | `ZonePreferenceServerListFilter` |
| `ILoadBalancer`            | `ribbonLoadBalancer`      | `ZoneAwareLoadBalancer`          |
| `ServerListUpdater`        | `ribbonServerListUpdater` | `PollingServerListUpdater`       |



