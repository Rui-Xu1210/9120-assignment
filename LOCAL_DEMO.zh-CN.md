# 当前本地演示

**最新原生交付**：见上一层 `APPLE_APP.zh-CN.md`。Mac 包是 `Little Steps.app`，iPhone 工程是 `apple/LittleSteps.xcodeproj`。原生编译/签名验证与 24 项 API/逻辑断言通过，但 Mac GUI 启动验证未通过，iOS 尚待完整 Xcode 编译签名及真机安装。下面的浏览器地址仅用于后端检查或旧网页预览。

## 已完成

- 仅创建 `9120assignment_demo`，没有修改其他数据库。
- 22 种疫苗、31 条推荐剂次已导入，30 项自动测试全部通过，包含真实 PostgreSQL 测试。
- 虚构家长 `Alex Demo`、儿童 `Emma Demo` 已保留，可直接预览。
- 已记录 Engerix B 第 1 剂；对应计划及提醒均为 completed。
- Bexsero 第 1 剂计划改为 2026-10-24，提醒同步为当天 09:30。

## 现在打开

- 电脑：`http://127.0.0.1:8000`
- 本次检测的局域网地址：`http://10.170.14.4:8000`
- API 文档：`http://127.0.0.1:8000/docs`

局域网 IP 可能随 Wi-Fi、VPN 或执行环境变化；这不是公网地址。电脑端访问该 IP 的 health 已通过，但尚未从你的真实手机验证。手机和运行 Python 的电脑必须在可互通的同一网络；若该地址不属于你电脑的 Wi-Fi，请使用运行脚本打印的当前地址，不要设置数据库端口转发。

## 旧网页录屏（已由原生流程取代）

1. 保持 PostgreSQL 和 Python 服务开启、电脑不休眠。
2. 手机 Safari / Chrome 打开局域网地址，可选添加到主屏幕。
3. 使用现有 Emma Demo 浏览，或 Family → Switch → + Add another parent 创建新的虚构家庭，演示从零录入。不要删除已有数据。
4. 按 `DEMO_SCRIPT.md` 演示添加家长、儿童、接种记录、查询提醒；可附带提醒时间和计划日期编辑。

## 下次启动

在应用目录使用装好依赖的 Python 执行 `python scripts/serve.py`。macOS 也可运行 `start.command`。当前数据库已经初始化，不要再次执行 setup-database / --create。

本地 `.env` 保留在电脑上，ZIP 不含密码；解压到其他位置需要从 `.env.example` 另行配置。不要分享 `.env`，不要在录屏中展示密码。所有家庭和接种示例仅为作业虚构数据，提醒不发送推送或短信。
