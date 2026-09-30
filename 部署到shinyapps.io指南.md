# 部署到 Posit Connect Cloud（免费个人网页版）操作指南

## 前提

- **本地源码默认启用上传**（`DEMO_MODE_DEFAULT <- FALSE`）。
- `deploy.R` 部署时会分别暂存两个版本并精确翻转该标志：
  **演示版**（`DEMO_MODE=TRUE`：隐藏上传，仅两条内置演示路径）与
  **完整版**（`DEMO_MODE=FALSE`：文件上传已解封）。

## 一次性账号配置（只需做一次）

1. 打开 https://connect.posit.cloud/ 注册并登录（Posit 已将 shinyapps.io
   迁移到 Posit Connect Cloud）。
2. 在账号设置里创建一个 **API Token**（记下账号名）。
3. 在 RStudio 控制台执行（使用较新的 rsconnect，例如 1.11.0）：

```r
install.packages("rsconnect")
library(rsconnect)
rsconnect::connectApiUser(account = "你的账号名",
                          server = "connect.posit.cloud",
                          apiKey = "粘贴API Token")
```

## 部署（一次发布两个版本）

在 RStudio 中打开 `deploy.R`（与 `ABPM_calculator_integrated.R` 同目录），
把 `app_name_demo` / `app_name_full` 改成你想要的网址后缀，然后
**全选运行**。脚本会自动部署**两个版本**：

| 版本 | appName（可改） | 说明 |
|---|---|---|
| 演示版（无上传） | `abpm` | DEMO_MODE=TRUE：隐藏上传，仅两条内置演示路径 |
| 完整版（可上传） | `abpm-upload` | DEMO_MODE=FALSE：文件上传已解封 |

脚本会：

1. 按字节级方式把应用暂存到项目**上一级目录**的 `abpm_deploy_stage/demo/`
   与 `abpm_deploy_stage/full/`（只翻转 `DEMO_MODE_DEFAULT <- TRUE/FALSE`
   一行，其余字节与源码完全一致；暂存到纯 ASCII 目录是因为 rsconnect
   无法枚举路径含中文的文件夹）；
2. 若之前的暂存目录里有发布记录（appId），自动迁移过来，用于更新**同一个**
   已发布应用；若服务端内容已被删除（免费额度到期等），脚本会自动转为
   **全新部署**并继续；
3. 依次上传部署两个应用，完成后在控制台打印结果。发布后的访问网址请到
   Posit Connect Cloud 控制台的对应内容页查看（URL 形如
   `https://connect.posit.cloud/<账号名>/content/<appId>`）。

也可以手动执行等价命令（以完整版为例）：

```r
library(rsconnect)
rsconnect::deployApp(appDir = "abpm_deploy_stage/full", appName = "abpm-upload")
```

## 常见问题

- **依赖包**：rsconnect 会扫描 `library()` 声明并在服务器上自动从 CRAN
  安装（本应用全部是 CRAN 包，含 `rintrojs`、`readxl`、`zip`）。应用头部的
  `install.packages` 已加上 `interactive()` 保护，服务器上不会执行。
  `zip` 用于"导出所选内容"的 CSV 压缩包：服务器上没有系统 `zip` 命令，
  原来的 `utils::zip()` 会失败（Windows 本机也需要 Rtools 才有 zip.exe），
  现已改用自带 libzip 的 `zip` 包。
- **完整版的上传注意事项**：上传的数据只存在于当前会话内存中，不会被
  存储；**损坏 OLE2 的旧 .xls 在服务器上无法读取**（服务器没有
  Python/xlrd 回退，会提示明确报错；正常 .xls/.xlsx 与 CSV 均可）。
  公开页面上传请自行评估隐私与安全（如需仅限自己使用，可在
  Posit Connect Cloud 上把内容访问权限设置为仅本人）。
- **更新应用**：改完 `ABPM_calculator_integrated.R` 后重新运行 `deploy.R`
  即可同时覆盖两个版本（会沿用暂存目录中的 appId 记录更新同一应用）。
- **下架/删除**：Posit Connect Cloud 控制台 → 对应内容 → 暂停或删除。
