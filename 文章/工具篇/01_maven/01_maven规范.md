### 统一maven的jar包版本号

1. 开发阶段使用SNAPSHOT后缀版本

   ```txe
   mvn -DnewVersion=1.0.0-SNAPSHOT -DgenerateBackupPoms=false versions:set
   ```

2. 生产发布使用RELEASE

   ```tex
   mvn -DnewVersion=1.0.0-RELEASE -DgenerateBackupPoms=false versions:set
   ```

3. 新版本迭代只修改顶层POM中的版本

