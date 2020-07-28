## 程序使用

### 同步和异步执行方式

```java
RedissonClient client = Redisson.create(config);
RAtomicLong longObject = client.getAtomicLong('myLong');
// 同步执行方式
longObject.compareAndSet(3, 401);
// 异步执行方式
RFuture<Boolean> result = longObject.compareAndSetAsync(3, 401);

RedissonReactiveClient client = Redisson.createReactive(config);
RAtomicLongReactive longObject = client.getAtomicLong('myLong');

// 异步流执行方式
Mono<Boolean> result = longObject.compareAndSet(3, 401);
RedissonRxClient client = Redisson.createRx(config);
RAtomicLongRx longObject= client.getAtomicLong("myLong");
// RxJava2方式
Flowable<Boolean result = longObject.compareAndSet(3, 401);
```

