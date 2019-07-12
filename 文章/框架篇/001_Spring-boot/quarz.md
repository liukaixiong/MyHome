# Spring boot Quartz 

## 相关资料

构建Mysql表:[SQL脚本](https://github.com/quartz-scheduler/quartz/blob/master/quartz-core/src/main/resources/org/quartz/impl/jdbcjobstore/tables_mysql_innodb.sql)

**属性文件参考**:[**quartz.properties**](https://github.com/quartz-scheduler/quartz/blob/master/quartz-core/src/main/resources/org/quartz/quartz.properties)

## 搭建环境

该项目是基于SpringBoot环境搭建，请搭建之前可以将SQL脚本先在数据库中进行执行。

属性文件可以先去了解。

### Maven.xml

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-quartz</artifactId>
</dependency>
```

注意我这里的版本是SpringBoot版本:`2.1.0.RELEASE`

### application.yml

SpringBoot中`QuartzAutoConfiguration`-`QuartzProperties`会读取配置环境中的以spring.quartz开头的配置并以此构建Quartz上下文。

```yaml
spring:
	quartz:
    #相关属性配置
    properties:
      org:
        quartz:
          scheduler:
            instanceName: clusteredScheduler
            instanceId: AUTO
          jobStore:
            class: org.quartz.impl.jdbcjobstore.JobStoreTX
            driverDelegateClass: org.quartz.impl.jdbcjobstore.StdJDBCDelegate
            tablePrefix: CRAWLER_
            isClustered: true
            clusterCheckinInterval: 10000
            useProperties: false
          threadPool:
            class: org.quartz.simpl.SimpleThreadPool
            threadCount: 10
            threadPriority: 5
            threadsInheritContextClassLoaderOfInitializingThread: true
```

### 代码层面

#### 配置类

这里需要注意的是SpringBoot的自动化配置类:`QuartzAutoConfiguration` 中已经默认将Quartz的默认配置配好，而你只需要将项目中特定的参数加进去，而SchedulerFactoryBeanCustomizer就是为了给用户自己配置自己需要的参数而设定的。

```java
/**
 * Job调度配置
 *
 * @author ： liukx
 * @time ： 2019/5/21 - 9:44
 */
@Configuration
public class JobConfig implements SchedulerFactoryBeanCustomizer { 
    
    @Override
    public void customize(SchedulerFactoryBean schedulerFactoryBean) {
        // 让执行的job拥有上下文的环境
        schedulerFactoryBean.setApplicationContextSchedulerContextKey("applicationContext");
    }
}
```

#### 业务类

```java
import org.quartz.SchedulerException;

/**
 * 调度业务定义规则
 *
 * @author : liukx
 * @date : 2019/5/21 - 16:22
 */
public interface IQuartzService {

    /**
     * 添加一个任务
     *
     * @param jobName      job的名称
     * @param jobGroupName job的组名称
     * @param jobTime      时间表达式 (这是每隔多少秒为一次任务)
     * @param runCount     运行的次数 （<0:表示不限次数）
     */
    public void addJob(String jobName, String jobGroupName, int jobTime,
                       int runCount) throws Exception;

    /**
     * 增加一个job
     *
     * @param jobName      任务名称
     * @param jobGroupName 任务组名
     * @param jobTime      时间表达式 （如：0/5 * * * * ? ）
     */
    public void addJob(String jobName, String jobGroupName, String jobTime) throws Exception;

    /**
     * 修改一个job任务
     *
     * @param jobName      名称
     * @param jobGroupName 组名
     * @param jobTime      job的Corn时间
     */
    public void updateJob(String jobName, String jobGroupName, String jobTime) throws SchedulerException, Exception;


    /**
     * 删除一个Job任务
     *
     * @param jobName      名称
     * @param jobGroupName 组名称
     */
    public void deleteJob(String jobName, String jobGroupName) throws SchedulerException, Exception;

    /**
     * 暂停一个Job任务
     *
     * @param jobName      名称
     * @param jobGroupName 组名
     */
    public void pauseJob(String jobName, String jobGroupName) throws SchedulerException, Exception;


    /**
     * 恢复一个任务
     *
     * @param jobName      名称
     * @param jobGroupName 组名
     */
    public void resumeJob(String jobName, String jobGroupName) throws Exception;


    /**
     * 立即执行一个任务
     *
     * @param jobName      名称
     * @param jobGroupName 组名
     */
    public void runAJobNow(String jobName, String jobGroupName) throws Exception;

}
```

实现

```java
import com.elab.crawler.web.job.DefaultQuartzJobBean;
import com.elab.crawler.web.services.IQuartzService;
import com.elab.crawler.web.utils.JobUtils;
import org.quartz.Scheduler;
import org.quartz.SchedulerException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.util.Date;

/**
 * 调度任务实现类
 *
 * @author : liukx
 * @date : 2019/5/21 - 16:29
 */
@Service("quartzServiceImpl")
public class QuartzServiceImpl implements IQuartzService {

    private Logger logger = LoggerFactory.getLogger(QuartzServiceImpl.class);

    @Qualifier("Scheduler")
    @Autowired
    private Scheduler scheduler;

    @PostConstruct
    public void startScheduler() {
        try {
            scheduler.start();
            logger.info(" 调度器启动了 ...");
        } catch (SchedulerException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void addJob(String jobName, String jobGroupName, int jobTime, int runCount) throws Exception {
        logger.info(" 新增一个任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + ",jobTime=" + jobTime + "," +
                "runCount=" + runCount);
        Date date = JobUtils.addJob(scheduler, DefaultQuartzJobBean.class, jobName, jobGroupName, jobTime, runCount);
        logger.info(" job任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + " 执行完成 . " + date);
    }

    @Override
    public void addJob(String jobName, String jobGroupName, String jobTime) throws Exception {
        logger.info(" 新增一个任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + ",jobTime=" + jobTime);
        Date date = JobUtils.addJob(scheduler, DefaultQuartzJobBean.class, jobName, jobGroupName, jobTime);
        logger.info(" job任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + " 执行完成 . " + date);
    }

    /**
     * 修改 一个job的 时间表达式
     *
     * @param jobName
     * @param jobGroupName
     * @param jobTime
     */
    @Override
    public void updateJob(String jobName, String jobGroupName, String jobTime) throws Exception {
        logger.info(" 修改一个任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + ",jobTime=" + jobTime);
        Date date = JobUtils.updateJob(scheduler, jobName, jobGroupName, jobTime);
        logger.info(" job任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + " 执行完成 . ");
    }

    /**
     * 删除任务一个job
     *
     * @param jobName      任务名称
     * @param jobGroupName 任务组名
     */
    @Override
    public void deleteJob(String jobName, String jobGroupName) throws Exception {
        logger.info(" 删除一个任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + ",jobTime=");
        boolean result = JobUtils.deleteJob(scheduler, jobName, jobGroupName);
        logger.info(" job任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + " 执行完成." + result);
    }
    /**
     * 暂停一个job
     *
     * @param jobName
     * @param jobGroupName
     */
    @Override
    public void pauseJob(String jobName, String jobGroupName) throws Exception {
        logger.info(" 暂停一个任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + ",jobTime=");
        JobUtils.pauseJob(scheduler, jobName, jobGroupName);
        logger.info(" job任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + " 执行完成.");
    }

    /**
     * 恢复一个job
     *
     * @param jobName
     * @param jobGroupName
     */
    @Override
    public void resumeJob(String jobName, String jobGroupName) throws Exception {
        logger.info(" 恢复一个任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + ",jobTime=");
        JobUtils.resumeJob(scheduler, jobName, jobGroupName);
        logger.info(" 恢复一个任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + "执行完成");
    }

    /**
     * 立即执行一个job
     *
     * @param jobName
     * @param jobGroupName
     */
    @Override
    public void runAJobNow(String jobName, String jobGroupName) throws Exception {
        logger.info(" 立即执行一个任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + ",jobTime=");
        JobUtils.runAJobNow(scheduler, jobName, jobGroupName);
        logger.info(" 立即执行一个任务 jobName=" + jobName + ",jobGroupName" + jobGroupName + "完成 ...");

    }

}
```

#### 默认的执行器

这里是调度的时候被触发的执行类。

```java
import org.quartz.JobExecutionContext;
import org.quartz.JobExecutionException;
import org.quartz.TriggerKey;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.quartz.QuartzJobBean;

/**
 * 默认的Job执行器
 *
 * @author ： liukx
 * @time ： 2019/5/21 - 16:32
 */
public class DefaultQuartzJobBean extends QuartzJobBean {
    private Logger logger = LoggerFactory.getLogger(DefaultQuartzJobBean.class);

    @Override
    protected void executeInternal(JobExecutionContext jobExecutionContext) throws JobExecutionException {
        // 拿到Spring的上下文，可以自由的做业务处理
        ApplicationContext applicationContext = (ApplicationContext)
                    jobExecutionContext.getScheduler().getContext().get("applicationContext");
        TriggerKey key = jobExecutionContext.getTrigger().getKey();
        String group = key.getGroup();
        String name = key.getName();
        // 业务处理 ... 
        
        logger.info(" 执行中 ... " + group + "\t" + name);
    }
}
```

#### 具体操作job的工具类

```java
import org.quartz.*;
import org.quartz.impl.matchers.GroupMatcher;
import org.springframework.scheduling.quartz.QuartzJobBean;

import java.util.*;

/**
 * 调度任务工具类
 *
 * @author ： liukx
 * @time ： 2019/5/21 - 16:35
 */
public class JobUtils {

    /**
     * 增加一个job
     *
     * @param jobClass     任务实现类
     * @param jobName      任务名称
     * @param jobGroupName 任务组名
     * @param jobTime      时间表达式 (这是每隔多少秒为一次任务)
     * @param jobTimes     运行的次数 （<0:表示不限次数）
     */
    public static Date addJob(Scheduler scheduler, Class<? extends QuartzJobBean> jobClass, String jobName, String
            jobGroupName, int jobTime,
                              int jobTimes) throws Exception {
        // 任务名称和组构成任务key
        JobDetail jobDetail = JobBuilder.newJob(jobClass).withIdentity(jobName, jobGroupName)
                .build();
        // 使用simpleTrigger规则
        Trigger trigger = null;
        if (jobTimes < 0) {
            trigger = TriggerBuilder.newTrigger().withIdentity(jobName, jobGroupName)
                    .withSchedule(SimpleScheduleBuilder.repeatSecondlyForever(1).withIntervalInSeconds(jobTime))
                    .startNow().build();
        } else {
            trigger = TriggerBuilder
                    .newTrigger().withIdentity(jobName, jobGroupName).withSchedule(SimpleScheduleBuilder
                            .repeatSecondlyForever(1).withIntervalInSeconds(jobTime).withRepeatCount(jobTimes))
                    .startNow().build();
        }
        return scheduler.scheduleJob(jobDetail, trigger);
    }

    /**
     * 增加一个job
     *
     * @param jobClass     任务实现类
     * @param jobName      任务名称
     * @param jobGroupName 任务组名
     * @param jobTime      时间表达式 （如：0/5 * * * * ? ）
     */
    public static Date addJob(Scheduler scheduler, Class<? extends QuartzJobBean> jobClass, String jobName, String
            jobGroupName, String jobTime) throws Exception {
        // 创建jobDetail实例，绑定Job实现类
        // 指明job的名称，所在组的名称，以及绑定job类
        // 任务名称和组构成任务key
        JobDetail jobDetail = JobBuilder.newJob(jobClass).withIdentity(jobName, jobGroupName)
                .build();
        // 定义调度触发规则
        // 使用cornTrigger规则
        // 触发器key
        Trigger trigger = TriggerBuilder.newTrigger().withIdentity(jobName, jobGroupName)
                .startAt(DateBuilder.futureDate(1, DateBuilder.IntervalUnit.SECOND))
                .withSchedule(CronScheduleBuilder.cronSchedule(jobTime)).startNow().build();
        // 把作业和触发器注册到任务调度中
        return scheduler.scheduleJob(jobDetail, trigger);
    }

    /**
     * 修改 一个job的 时间表达式
     *
     * @param jobName
     * @param jobGroupName
     * @param jobTime
     */
    public static Date updateJob(Scheduler scheduler, String jobName, String jobGroupName, String jobTime) throws SchedulerException {
        TriggerKey triggerKey = TriggerKey.triggerKey(jobName, jobGroupName);
        CronTrigger trigger = (CronTrigger) scheduler.getTrigger(triggerKey);
        trigger = trigger.getTriggerBuilder().withIdentity(triggerKey)
                .withSchedule(CronScheduleBuilder.cronSchedule(jobTime)).build();
        // 重启触发器
        return scheduler.rescheduleJob(triggerKey, trigger);
    }

    /**
     * 删除任务一个job
     *
     * @param jobName      任务名称
     * @param jobGroupName 任务组名
     */

    public static boolean deleteJob(Scheduler scheduler, String jobName, String jobGroupName) throws SchedulerException {
        return scheduler.deleteJob(new JobKey(jobName, jobGroupName));
    }

    /**
     * 暂停一个job
     *
     * @param jobName
     * @param jobGroupName
     */
    public static void pauseJob(Scheduler scheduler, String jobName, String jobGroupName) throws Exception {
        JobKey jobKey = JobKey.jobKey(jobName, jobGroupName);
        scheduler.pauseJob(jobKey);
    }

    /**
     * 恢复一个job
     *
     * @param jobName
     * @param jobGroupName
     */
    public static void resumeJob(Scheduler scheduler, String jobName, String jobGroupName) throws Exception {
        JobKey jobKey = JobKey.jobKey(jobName, jobGroupName);
        scheduler.resumeJob(jobKey);
    }

    /**
     * 立即执行一个job
     *
     * @param jobName
     * @param jobGroupName
     */
    public static void runAJobNow(Scheduler scheduler, String jobName, String jobGroupName) throws Exception {
        JobKey jobKey = JobKey.jobKey(jobName, jobGroupName);
        scheduler.triggerJob(jobKey);
    }

    /**
     * 获取所有计划中的任务列表
     *
     * @return
     */
    public static List<Map<String, Object>> queryAllJob(Scheduler scheduler) {
        List<Map<String, Object>> jobList = null;
        try {
            GroupMatcher<JobKey> matcher = GroupMatcher.anyJobGroup();
            Set<JobKey> jobKeys = scheduler.getJobKeys(matcher);
            jobList = new ArrayList<Map<String, Object>>();
            for (JobKey jobKey : jobKeys) {
                List<? extends Trigger> triggers = scheduler.getTriggersOfJob(jobKey);
                for (Trigger trigger : triggers) {
                    Map<String, Object> map = new HashMap<>();
                    map.put("jobName", jobKey.getName());
                    map.put("jobGroupName", jobKey.getGroup());
                    map.put("description", "触发器:" + trigger.getKey());
                    Trigger.TriggerState triggerState = scheduler.getTriggerState(trigger.getKey());
                    map.put("jobStatus", triggerState.name());
                    if (trigger instanceof CronTrigger) {
                        CronTrigger cronTrigger = (CronTrigger) trigger;
                        String cronExpression = cronTrigger.getCronExpression();
                        map.put("jobTime", cronExpression);
                    }
                    jobList.add(map);
                }
            }
        } catch (SchedulerException e) {
            e.printStackTrace();
        }
        return jobList;
    }

    /**
     * 获取所有正在运行的job
     *
     * @return
     */
    public static List<Map<String, Object>> queryRunJob(Scheduler scheduler) {
        List<Map<String, Object>> jobList = null;
        try {
            List<JobExecutionContext> executingJobs = scheduler.getCurrentlyExecutingJobs();
            jobList = new ArrayList<Map<String, Object>>(executingJobs.size());
            for (JobExecutionContext executingJob : executingJobs) {
                Map<String, Object> map = new HashMap<String, Object>();
                JobDetail jobDetail = executingJob.getJobDetail();
                JobKey jobKey = jobDetail.getKey();
                Trigger trigger = executingJob.getTrigger();
                map.put("jobName", jobKey.getName());
                map.put("jobGroupName", jobKey.getGroup());
                map.put("description", "触发器:" + trigger.getKey());
                Trigger.TriggerState triggerState = scheduler.getTriggerState(trigger.getKey());
                map.put("jobStatus", triggerState.name());
                if (trigger instanceof CronTrigger) {
                    CronTrigger cronTrigger = (CronTrigger) trigger;
                    String cronExpression = cronTrigger.getCronExpression();
                    map.put("jobTime", cronExpression);
                }
                jobList.add(map);
            }
        } catch (SchedulerException e) {
            e.printStackTrace();
        }
        return jobList;
    }
}
```

## 总结

1. 整个SpringBoot的Quartz配置类都是围绕QuartzAutoConfiguration配置类来构建的。
2. 配置文件采用了`QuartzProperties`来替代，专门获取`spring.quartz`开头的配置属性。

### 关键元素

- Scheduler: 任务调度器
  - StdSchedulerFactory: 调度工厂，所有的属性配置获取定义的名称都有
- Trigger: 触发器
  - Simple : 简单的触发
  - CronTirgger : 表达式触发
  - DateIntervalTrigger: 间隔时间触发
  - NthIncludedDayTrigger : 
- Job : 任务



### 执行流程

StdSchedulerFactory:

- 通过instantiate方法开始实例化调度器
  - 构建一个QuartzScheduler调度器，这个调度器是一个线程，负责拉取需要触发的Trigger

QuartzSchedulerThread:

- run
  - 拉取即将执行的触发内容
  - 执行触发任务

JobStoreSupport : 

- 获取马上要fire的trigger列表
- 将trigger的状态有WAITING更新为ACQUARIED
- 将这个trigger信息insert进fired_triggers

主流程

1. 轮训拉取待触发的trigger。
2. 根据状态触发trigger。
3. 包装trigger，丢给工作线程。
4. 工作线程负责执行具体的任务

[原理参考](https://segmentfault.com/a/1190000015492260)