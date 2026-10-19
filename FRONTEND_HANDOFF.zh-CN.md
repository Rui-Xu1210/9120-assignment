# 前端组员本地运行说明

这份说明用于在前端组员自己的电脑上运行 PostgreSQL 数据库和 Python 后端，再由手机 App 通过本地 Wi-Fi 访问后端。无需购买服务器或把数据库装进手机。

## 先理解各部分

```text
手机 App  --HTTP/JSON-->  Python 后端（前端组员的电脑）  -->  PostgreSQL（同一台电脑）
```

- `sql_code_por.sql`：建立数据库表、主外键、触发器和视图。
- `Insert_dataset.sql`：插入疫苗、预防疾病和推荐接种年龄等基础数据。
- `app/`：Python 后端代码，提供前端可调用的功能。
- `.env`：本机数据库连接设置，包含个人密码，不能发到群聊或提交到 Git。
- `.env.example`：不含真实密码的配置模板，可以和项目代码一起分享。

## 需要交给前端组员的文件

把整个项目文件夹复制或分享给她，至少包含：

- `app/` 文件夹
- `requirements.txt`
- `.env.example`
- `sql_code_por.sql`
- `Insert_dataset.sql`
- `README.md`
- `FRONTEND_HANDOFF.zh-CN.md`

不要分享你的 `.env` 文件。它含有你电脑上的 PostgreSQL 密码；组员需要在自己的电脑上创建自己的 `.env`。

**建库时只运行 `sql_code_por.sql`，不要运行旧稿 `sql_code.sql`。**

## 在组员电脑上配置数据库

### 1. 安装 PostgreSQL

在组员电脑安装 PostgreSQL，并使用 pgAdmin 确认本机 PostgreSQL Server 正在运行。安装时设置的用户名和密码是她自己的本机凭证，不一定和你的相同。

### 2. 新建空数据库

在 pgAdmin 连接本地服务器，常见连接参数是：

```text
Host: localhost
Port: 5432
Username: postgres（以安装时设定为准）
```

右键 **Databases → Create → Database...**，数据库名称填写：

```text
9120assignment
```

数据库用户名及密码指 PostgreSQL 的登录账号，不是 pgAdmin 网站或电脑账号。

### 3. 在新库中建立表并插入基础数据

在 pgAdmin 左侧选择刚创建的 `9120assignment`，打开该数据库的 **Query Tool**，然后按顺序打开并执行：

1. `sql_code_por.sql`
2. `Insert_dataset.sql`

两个脚本都要在 `9120assignment` 的 Query Tool 中运行。不要在其他数据库（例如默认的 `postgres`）中运行。脚本是新数据库初始化用的；成功执行一次后不要重复执行，否则可能因为表或数据已存在而报错。

完成后，pgAdmin 的 `Schemas → public → Tables` 应能看到 `parent`、`child`、`vaccine`、`vaccine_record`、`vaccine_schedule`、`vaccine_reminder` 等表。初始数据包括疫苗目录；家长和孩子数据一开始为空，这是正常的。

## 在组员电脑上配置 Python 后端

### 1. 安装 Python

建议使用 Python 3.10 或更新版本。打开终端/命令行，进入项目文件夹。

### 2. 创建本机 `.env`

在项目根目录（与 `requirements.txt` 同一层）复制 `.env.example` 并将副本命名为 `.env`。然后编辑 `.env`，按她本机 PostgreSQL 的设置填写：

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=9120assignment
DB_USER=postgres
DB_PASSWORD=她在自己电脑安装 PostgreSQL 时设置的密码
```

如果她安装 PostgreSQL 时使用了不同的用户名、端口或数据库名，就把相应值改成她自己的设置。不要把密码加引号，也不要把 `.env` 分享或提交。

### 3. 安装项目依赖

macOS / Linux：

```bash
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
```

Windows PowerShell：

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
py -m pip install -r requirements.txt
```

### 4. 启动和检查后端

先确认 PostgreSQL 服务正在运行，再从项目根目录启动：

```bash
python -m uvicorn app.main:app --reload
```

在同一台电脑的浏览器打开：

```text
http://127.0.0.1:8000/docs
```

`/docs` 是交互式接口说明页。先打开 `GET /health` 并点 **Try it out → Execute**；若成功，会显示数据库名和连接状态。也可以测试 `GET /vaccines`，应返回基础疫苗数据。

停止后端时，在运行 Uvicorn 的终端按 `Ctrl+C`。

## 手机 App 如何在本地访问

`127.0.0.1` 或 `localhost` 在手机上指手机自己，不是组员的电脑。因此，手机实体机不能使用上面的本机地址访问电脑。

让手机和电脑连接到同一个 Wi-Fi，然后：

1. 取得电脑在 Wi-Fi 中的本地 IP 地址，例如 `192.168.1.23`。
2. 在电脑上用下面的命令启动后端，让同一网络中的设备可以访问：

   ```bash
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

3. 手机 App 将 API 基础地址设置成电脑的本地 IP，例如：

   ```text
   http://192.168.1.23:8000
   ```

   把示例 IP 换成组员电脑的实际 IP。不要把 `localhost` 放进手机 App 的 API 地址。

4. 如果手机仍无法连接，检查电脑防火墙是否允许 Python/Uvicorn 接收本地网络连接。部分校园 Wi-Fi 会隔离设备；这种情况下可尝试让电脑和手机连接同一个个人热点。

电脑必须保持开机、PostgreSQL 和 Python 后端必须保持运行，手机 App 才能访问数据。演示时只需在同一 Wi-Fi 下使用，不需要远程部署。不要为了手机连接而把 PostgreSQL 的 `5432` 端口开放给网络；手机只连接 Python 后端的 `8000` 端口。

## 前端主要调用流程

API 返回和接收 JSON。可先在电脑的 `/docs` 页面试接口，再将同样的请求接到手机界面：

1. `POST /parents`：创建家长，保存返回的 `parent_id`。
2. `POST /children`：创建孩子，提交 `name`、`date_of_birth` 和 `parent_id`。数据库触发器会按推荐接种计划建立该孩子的 schedules 和 reminders。
3. `GET /children/{child_id}`：查看孩子资料、接种历史和接种计划。
4. `PATCH /schedules/{schedule_id}`：更改某项计划的预约日期、机构或状态。
5. `POST /records`：录入孩子已完成的某剂疫苗。数据库触发器会把相应 schedule 和 reminder 标记为 completed。
6. `GET /records?child_id=C00001`：查看该孩子接种记录。
7. `GET /reminders?child_id=C00001`：查看该孩子提醒；可加入 `&status=pending` 过滤未完成提醒。
8. `GET /vaccines` 和 `GET /schedules/recommended`：取得疫苗和推荐剂次信息。疫苗 ID 由数据库产生，应先查询，不要在前端写死。

提醒目前是数据库记录，供 App 查询和显示；当前版本不发送手机推送、短信或邮件。后端也暂未加入登录认证，所以只用于课程演示和受控的本地网络，不要直接暴露到公共网络。

## 组内对齐事项

- 推荐所有组员在自己的电脑上统一创建数据库名 `9120assignment`，并使用这两个指定 SQL 脚本初始化。
- 每台电脑的 PostgreSQL 密码可能不同；每个人单独填写本机 `.env`。
- 你的电脑目前已有的项目表是在 `postgres` 数据库中；这是你本机现状。新组员按本说明创建 `9120assignment` 后，应在该数据库中运行两个脚本，不需要复制你的数据库密码或数据库文件。
- 如果手机前端是网页或 WebView，而不是原生网络请求，浏览器跨域策略可能还需要为开发地址配置 CORS；当前 Python 应用尚未配置 CORS。先确定前端技术栈后再设置允许的开发来源。
