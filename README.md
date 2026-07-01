# discourse-ai-moderator

用本地 LLM 自动审核新用户进入审核队列的待审帖/回复的 Discourse 插件。

监听 `:reviewable_created` 事件，取出帖子内容交给本地 OpenAI 兼容模型判断
**APPROVE / REJECT**，然后以系统用户身份自动放行或拒绝。模型拿不准或调用失败时，
默认留在队列里等人工处理（安全优先，不误放不误删）。

## 为什么做成插件

替代原先的外部 Python 审核 Bot。Bot 走公网轮询 `review.json`，链路长、频繁 502；
插件跑在 Discourse 容器内，无跨网络问题，且是**事件驱动**（帖子进队列即触发），
不是定时轮询。

| | 旧 Python Bot | 本插件 |
|---|---|---|
| 运行位置 | 外部脚本，跨网络 | Discourse 容器内 |
| 触发方式 | 30s 轮询队列 | 事件驱动（秒级） |
| 部署 | 额外 systemd 服务 | 随论坛，`git pull` + 重启 |
| 配置 | 脚本硬编码 | 后台 SiteSetting |
| 异步/重试 | 无 | Sidekiq 自带 |

## 工作流程

```
新用户发帖 → 进审核队列 → 触发 :reviewable_created 事件
                                    ↓
              插件监听 → 入 Sidekiq 队列（异步，不阻塞发帖）
                                    ↓
              Job: 取 payload(title+raw) → 调本地 LLM
                                    ↓
              APPROVE → reviewable.perform(system_user, :approve_post)
              REJECT  → reviewable.perform(system_user, :reject_post)
              拿不准/报错 → 按 ai_moderator_on_uncertain 策略处理（默认留队列）
```

只处理 `ReviewableQueuedPost`（新用户待审的帖子/回复），不动被举报的帖子
（`ReviewableFlaggedPost`）。

## 站点设置（Admin → 设置，搜索 `ai_moderator`）

| 设置 | 默认 | 说明 |
|------|------|------|
| `ai_moderator_enabled` | `false` | 总开关 |
| `ai_moderator_llm_url` | `http://172.17.0.1:19119/v1` | LLM API 基址（OpenAI 兼容） |
| `ai_moderator_llm_key` | *(空)* | Bearer API Key（secret） |
| `ai_moderator_llm_model` | `Qwen3.6-35B-...gguf` | 模型名 |
| `ai_moderator_request_timeout` | `90` | 单次调用超时（秒） |
| `ai_moderator_on_uncertain` | `hold` | 拿不准时：`hold` / `approve` / `reject` |
| `ai_moderator_max_content_chars` | `4000` | 发送给模型的正文最大字符数 |
| `ai_moderator_system_prompt` | *(见 settings.yml)* | 审核规则，模型须只回 APPROVE 或 REJECT |

## 配合的 Discourse 设置

审核队列由 Discourse 原生机制产生，与本插件配合的关键设置：

- `approve_post_count`：新用户前 N 条帖子/回复进审核队列
- `approve_new_topics_unless_allowed_groups`：哪些组的新主题免审

## 安装

```bash
cd /var/discourse/shared/standalone/plugins
git clone https://github.com/zhaimingyou/discourse-ai-moderator.git
```

在 `containers/app.yml` 的 `volumes:` 下加挂载：

```yaml
- volume:
    guest: /var/www/discourse/plugins/discourse-ai-moderator
    host: /var/discourse/shared/standalone/plugins/discourse-ai-moderator
```

然后 `./launcher rebuild app`（首次安装需要，用于编译前端资源与注册插件）。

## 更新

```bash
# 本地改代码 → push
git commit -am "..." && git push

# 服务器拉取 + 重启（纯后端改动无需 rebuild）
cd /var/discourse/shared/standalone/plugins/discourse-ai-moderator && git pull
docker exec app sv restart unicorn
```

> 若改动包含前端资源（JS/gjs/scss），需 `./launcher rebuild app` 重新编译。

## 许可

MIT
