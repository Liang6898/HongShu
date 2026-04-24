# HongShu 二次开发 · 代码规范标准

> 所有 Agent 必须遵守的编码规范
> 任何与本文档冲突的代码，以本文档为准

---

## 一、Git 工作流

### 1.1 分支命名
```
main          ← 稳定版本（每个 Day 结束后合并）
day1-env      ← Day 1 开发分支
day2-user     ← Day 2 开发分支
...
bugfix/xxx    ← Bug 修复分支
```

### 1.2 Commit 格式
```
[DayX] 简短描述

详细说明（可选）
- 改了什么
- 为什么改
```

示例：
```
[Day2] 用户体系科研标签化

- 新增 profile_tag 字段到 wb_user 表
- WebAuthController.register() 支持 profileTag 参数
- 登录返回结果包含 profileTag 字段
```

### 1.3 Commit 前必须
```
1. git status  → 确保没有未保存的修改
2. git pull   → 拉最新 main
3. mvn compile -DskipTests  → 确保编译通过
4. git add + commit + push
```

---

## 二、Java 代码规范

### 2.1 命名规范
```
类名：UpperCamelCase      → WebNoteController
方法名：lowerCamelCase   → getUserInfo
变量名：lowerCamelCase   → profileTag
常量：UPPER_SNAKE_CASE   → MAX_UPLOAD_SIZE
包名：全小写             → com.hongshu.web.controller
```

### 2.2 Controller 规范
```java
// ✅ 正确示例
@RestController
@RequestMapping("/web/note")
public class WebNoteController {

    @PostMapping("/publish")
    public Result<?> publish(@RequestBody NoteDTO dto,
                            @RequestHeader(value = "Authorization", required = false) String token) {
        // 1. 参数校验
        if (dto.getContent() == null || dto.getContent().trim().isEmpty()) {
            return Result.error("内容不能为空");
        }
        if (dto.getContent().length() > 500) {
            return Result.error("内容不能超过500字");
        }

        // 2. 业务逻辑
        // ...

        // 3. 返回结果
        return Result.ok(note);
    }
}

// ❌ 错误示例
@PostMapping("/publish")
public Result publish(HashMap map) {  // 不用 Map/HashMap，用 DTO
    if (map.get("content") == "") return null;  // 不能返回 null
}
```

### 2.3 DTO 规范
```java
// 每个接口请求都有独立的 DTO
public class NotePublishDTO {
    private String content;      // 必填
    private String contentTag;  // 必填，有默认值
    private List<String> images;  // 可选

    // ✅ 每个字段都要有校验注解
    @NotBlank(message = "内容不能为空")
    @Size(max = 500, message = "内容不能超过500字")
    private String content;
}
```

### 2.4 Service 层规范
```java
// ✅ 正确：事务注解在 Service 层，不在 Controller 层
@Service
public class WebNoteServiceImpl {

    @Transactional
    public Note publish(NotePublishDTO dto, Long userId) {
        // 保存帖子
        // 更新用户发帖数
        // 发送事件（如果需要）
    }
}
```

### 2.5 不要做的事
- ❌ 不要在 Controller 里直接操作数据库（用 Service）
- ❌ 不要返回 `null`（统一返回 `Result.error()`）
- ❌ 不要吞异常（`catch(Exception e){}` 要打日志）
- ❌ 不要硬编码 Magic Number（用常量）
- ❌ 不要删除他人代码（只做注释或新增）

---

## 三、数据库规范

### 3.1 字段命名
```
用下划线命名：profile_tag, content_tag
不用驼峰：profileTag, contentTag
```

### 3.2 改动数据库的规范
```sql
-- ✅ 正确：新增字段都要加 COMMENT
ALTER TABLE wb_user ADD COLUMN profile_tag VARCHAR(50) DEFAULT NULL COMMENT '一级科研标签';

-- ✅ 新增索引
ALTER TABLE wb_note ADD INDEX idx_content_tag(content_tag);

-- ❌ 错误：直接修改已有字段类型（可能导致数据丢失）
-- ALTER TABLE wb_user MODIFY COLUMN nickname VARCHAR(100);  -- 除非确认不影响数据
```

### 3.3 SQL 改动后
1. 先在测试环境验证
2. 记录所有 ALTER 语句到 `docs/SQL-CHANGES.md`
3. commit 时带上 SQL 变更说明

---

## 四、API 规范

### 4.1 统一响应格式
```java
// ✅ 成功
return Result.ok(data);

// ✅ 错误
return Result.error("用户名或密码错误");

// ❌ 不要
return null;
return new Result(500, "error");
```

### 4.2 HTTP 状态码使用
```
200 OK          ← 正常成功
400 Bad Request ← 参数错误
401 Unauthorized ← 未登录
403 Forbidden   ← 无权限
404 Not Found   ← 资源不存在
500 Server Error ← 系统错误
```

### 4.3 接口前缀
```
用户端：/web/...
Admin端：/admin/...
认证端：/web/auth/...
```

---

## 五、日志规范

### 5.1 日志级别
```
DEBUG  ← 开发调试用，上线前删除
INFO   ← 重要业务流程
WARN  ← 潜在问题，不影响功能
ERROR  ← 错误，必须处理
```

### 5.2 日志格式
```java
// ✅ 正确
log.info("用户注册成功: phone={}, profileTag={}", phone, profileTag);
log.error("发帖失败: userId={}, error={}", userId, e.getMessage(), e);

// ❌ 错误
log.info("ok");  // 太笼统
log.error(e);    // 没有上下文
```

---

## 六、测试规范

### 6.1 测试命名
```java
@Test
public void testRegister_withProfileTag_success() { }

@Test
public void testRegister_withoutProfileTag_shouldFail() { }
```

### 6.2 测试原则
- 测试的是**行为**，不是实现细节
- 一个测试只测一件事
- 测试之间不能有依赖（独立的）

---

## 七、防踩坑

### 7.1 Spring Boot 常见坑
```java
// ❌ 循环依赖
// A 依赖 B，B 依赖 A → 用 @Lazy 或重构

// ❌ 事务不生效
@Transactional
public void method() {
    privateMethod();  // private 方法不在事务里！
}

// ✅ 正确
@Transactional
public void method() {
    anotherPublicMethod();
}
```

### 7.2 MyBatis-Plus 常见坑
```java
// ❌ 分页插件没配置
// → 确保 PaginationInterceptor 已配置

// ✅ 分页查询
IPage<Note> page = new Page<>(current, size);
noteMapper.selectPage(page, queryWrapper);

// ❌ 泛型丢失
LambdaQueryWrapper<?>  // 不要用 ?
// → LambdaQueryWrapper<Note>
```

### 7.3 RESTful 坑
```java
// ❌ 用 GET 做有副作用的操作
// GET /note/publish   ← 不要！

// ✅ 正确
POST /note/publish     ← 创建
GET  /note/list        ← 查询
PUT  /note/{id}        ← 更新
DELETE /note/{id}      ← 删除
```

---

## 八、文档规范

### 8.1 每个 Day 结束必须输出
```
docs/GATE-DayX.md      ← 门控记录
docs/TEST-REPORT-DayX.md ← 测试报告
docs/SQL-CHANGES.md    ← SQL 变更记录（如有）
docs/BUG-LOG.md        ← Bug 记录
```

### 8.2 代码注释
```java
// ✅ 重要业务逻辑必须注释
// 用户注册时，必须先校验 profileTag 是否在允许的15个标签范围内
if (!ALLOWED_TAGS.contains(profileTag)) {
    return Result.error("无效的科研标签");
}

// ❌ 不要注释显而易见的事
// i++  // i自增  ← 不要！

// ❌ 不要留空的注释块
// TODO
// FIXME
```
