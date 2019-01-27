# Cat LogView 读取

## Filter 拦截器集合

- CatFilter : 所有请求的入口

- PermissionFilter : 权限拦截器

- DomainFilter ? URL变更了

  - 是否存在domain参数
  - 并且通过LogEvent打印出UserIp等

- MVC

  - 请求流转控制器

  - com.dianping.cat.report.page.model.Handler.handleOutbound 具体的对应处理器

    - m_localServices

      - logview - LocalMessageService[name]

      - LocalMessageService

        - buildNewReport
          - 解析消息编号
            - elab-marketing-authentication-c0a804ef-427756-114
            - elab-marketing-authentication - 项目名
            - c0a804ef  - IP地址的解析码
            - 427756   -  小时数
            - 114  -  文件内的坐标数
            - segmentOffset : 116243 : 根据机器码做位运算得到的分段数
            - dataOffset : 44952  根据机器码 >> 24 得到的 数据偏移量
          - 获取到当前小时的文件数
            - "427758" -> "{cat=LocalBucket[\data\appdatas\cat\bucket\dump\20181019\14\cat-192.168.4.239.dat]}"

      - LocalBucketManager : 管理着一个Map  这个Map对应着消息编号中的小时数 ， 小时数对应的值就是LocalBucket

        - LocalBucket:  真正去获取桶里面的数据,也就是本地消息的方法
          - DataHelper : 真正存储数据的地方
          - IndexHelper : 存储数据的索引位置
            - 根据IP地址的解析码(c0a804ef)去获取到对应的偏移量
