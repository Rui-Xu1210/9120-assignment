# Little Steps 疫苗记录应用

现在的主要交付是基于原 SQL 和 Python API 的 **SwiftUI 原生 iPhone / Mac App**，不是网页包装。原 Downloads 文件夹未被修改。请先读上一层目录的 `APPLE_APP.zh-CN.md`：其中有 Mac 包、Xcode 工程、iPhone 安装和原生录屏步骤，以及尚未完成的真机验证说明。下文保留数据库与旧网页预览的配置资料，不代表网页就是最终 App。

## 当前交付状态

- 前端、Python API 适配、SQL 初始化脚本、增量迁移和录屏操作稿已完成。
- 已按授权仅创建并初始化 `9120assignment_demo`，导入 22 种疫苗、31 条推荐剂次，未修改其他数据库。
- **30 项自动测试全部通过**，包含 2 项真实 PostgreSQL 联调测试及目标数据库保护测试。临时测试 schema 已清理。
- 已通过端口 8000 的真实浏览器流程录入虚构家长 `Alex Demo`、儿童 `Emma Demo` 和 1 条接种记录，确认计划与提醒自动完成、提醒编辑、计划日期同步保留时间、刷新后持久化；并直接查询 PostgreSQL 核实。
- 先前 390 × 844 和 320 × 740 的手机布局检查使用 UI 测试夹具，与本次真实数据库联调证据分开。真实手机连接与录屏仍需在你的手机上完成。
- 本地 `.env` 已填写，密码不包含在 ZIP 中。当前数据库已经初始化，**不要再次运行初始化**；直接启动应用。见 `LOCAL_DEMO.zh-CN.md`。

## 页面和功能

| 页面 | 功能 | API |
|---|---|---|
| Welcome / Family | 添加家长、儿童、切换家庭和儿童 | POST /parents、POST /children、GET /parents、GET /children |
| Schedule | 按推荐年龄分组、隐藏已全部完成月份、查看剂次 | GET /schedules、GET /schedules/recommended |
| Dose detail | 输入接种日期与接种机构；完成对应计划和提醒 | POST /records |
| History | 查看实际接种记录 | GET /records |
| Reminders | 查询待处理/完成/全部提醒；编辑日期和时间 | GET /reminders、PATCH /reminders/{id} |
| Planned date | 调整计划日期并同步对应提醒 | PATCH /schedules/{id} |
| Catalogue | 搜索疫苗名称与疾病 | GET /vaccines |

家长只有 name，儿童只有 name、date_of_birth、parent_id；未擅自新增电话、地址、性别等数据库没有的字段。没有虚构登录功能。前端所有剂次和疫苗 ID 都来自 API。

## 1 配置 PostgreSQL

打开同目录 `.env`（隐藏文件）并填写本机账号：

```env
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=9120assignment_demo
DB_USER=postgres
DB_PASSWORD=你的本机数据库密码
APP_PORT=8000
```

密码无需发到聊天，不要提交或分享 `.env`。建议只在自己的电脑使用独立的演示数据库。

## 2 初始化数据库

Terminal 中进入本目录，执行：

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python scripts/setup_db.py --create
```

或在 Finder 中运行 `setup-database.command`。如系统阻止打开，使用 Terminal 执行脚本；不要关闭系统安全保护。

脚本与 Python 应用只允许 `DB_NAME=9120assignment_demo`，配置其他库名会拒绝执行。脚本使用填写的账号连接本机 PostgreSQL，在不存在时创建该库，随后在**空数据库**中依次运行：

1. `schema.sql`，等同于原始 `sql_code`；
2. `seed.sql`，等同于原始 `Insert_dataset.sql`；
3. `migrations/001_mobile.sql`，新增日期同步触发器。

建表、导入、迁移在同一事务中完成。若 public 已有任何表，脚本会拒绝初始化，绝不 DROP 现有数据库或表。若账号无 CREATE DATABASE 权限，请自己用 pgAdmin 新建空数据库，再运行不带 `--create` 的命令。

**仅当 `9120assignment_demo` 已按原 SQL 搭好、但尚未安装移动端迁移时**，不要再运行初始化，只执行：

```bash
python scripts/setup_db.py --migrate-only
```

请先确认该数据库就是本项目，且你允许添加日期同步触发器。

## 3 启动应用

```bash
source .venv/bin/activate
python scripts/serve.py
```

也可运行 `start.command`。终端会输出电脑与手机地址。

- 电脑预览：`http://127.0.0.1:8000`
- API 文档：`http://127.0.0.1:8000/docs`
- 连接检查：`http://127.0.0.1:8000/health`
- 手机上使用终端打印的 **Phone (same Wi-Fi)** 地址，不要使用 localhost。

前端和 API 由同一 FastAPI 进程提供，不需要 Node 开发服务器或手动配置 CORS。数据库密码不会发送给浏览器。

## 4 旧网页预览（仅作备用，不是原生 App）

1. 手机和电脑连同一可信 Wi-Fi / 热点；校园网络可能隔离设备。
2. 保持电脑不休眠，PostgreSQL 和 Python 服务都保持运行。
3. 手机浏览器打开电脑局域网 IP 的 8000 端口；若失败，检查是否允许 Python 接收局域网连接。
4. iPhone Safari：共享 → 添加到主屏幕；如有“作为网页 App 打开”则启用。
5. Android Chrome：菜单 → 添加到主屏幕。HTTP 环境下是否作为独立窗口安装因设备/浏览器而异，普通主屏幕快捷方式也足够完成录屏。
6. 上述只是旧网页快捷方式，不满足原生安装要求。原生 iPhone 版应通过 `apple/LittleSteps.xcodeproj` 在 Xcode 中签名安装；需要你自己的 Apple Account，不能用上述步骤代替。

这是在线局域网网页应用，不支持离线数据和推送通知。PostgreSQL 端口不要暴露给手机或互联网。

## 5 测试

```bash
python -m pip install -r requirements-dev.txt
python -m pytest -q
# .env 配置成功后：
RUN_DB_TESTS=1 python -m pytest tests/test_postgres.py -v
```

数据库测试在目标数据库内建立 UUID 命名的独立 schema，加载原 SQL 和样例数据，验证真正的触发器流程，最后只清理该测试 schema。需要账号拥有 CREATE SCHEMA 权限。测试不改 public 中已有数据。

## 对原 Python 项目的修改

- 继续使用原有 Python/FastAPI/psycopg 结构和 API 路径。
- 增加 `/` 和 `/static` 提供手机前端。
- 修改 `GET /schedules/recommended`，附加明确的年月/天数，避免将 PostgreSQL 月份 interval 误当作固定天数。
- `PATCH /reminders/{id}` 保留 reminder_status，增加可选 reminder_date。
- `PATCH /schedules/{id}` 仍可改日期/机构；现在拒绝直接改完成状态，要求通过实际接种记录完成，防止计划/记录/提醒相互矛盾。
- 修复 `GET /children/{id}` 中重复 parent_id 参与 USING JOIN 可能造成的列歧义。
- 增加空白姓名、未来接种日期、出生前接种/计划日期校验；记录重复保持原有 409 响应。
- 记录已完成的剂次不允许将提醒重新改为 pending。
- 数据库连接错误使用通用信息，避免在网页中泄漏凭据。
- `.env` 从项目根目录固定加载，避免从不同目录启动时读错。
- 原 schema 和 seed 文件逐字保留；仅以额外 migration 实现计划日期 → 待处理提醒日期同步，保留时间。

## 数据与界面边界

参考图只显示 App Store 页面和部分 App 预览；本实现使用其可见的 iOS 分组列表、年龄区间、Dose 标签、儿童切换和剂次详情结构，而非完整原 App 的像素级复刻。未展示页面采用一致的延伸风格。

原 seed 同时包含多种替代品牌，原触发器会为全部品牌创建计划。为严格保留作业数据库，本实现不擅自删数据或改为临床接种方案，而在页面中标注 sample coursework plan 和可能的品牌替代关系。**不能把列表当作真实儿童必须接受的全部疫苗清单。**

仅使用虚构家长、儿童与接种数据；应用没有登录和访问控制，同网络可访问地址的人可查看和添加数据。请只在封闭的课堂演示环境中使用。
