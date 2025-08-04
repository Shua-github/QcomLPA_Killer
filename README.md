# QcomLPA-Killer

干掉高通基带内置的LPA!

## 依赖
> 带有高通基带的安卓手机
> 支持`KernelSU`模块
> 原厂系统(可选,非原厂不保证可用性)

## 安装

### 获取
> [释放](https://github.com/Shua-github/QcomLPA_Killer/releases)

### 刷入
> `ksud module install <zip_path>`

## 提示
> 出现问题反馈时请带上`/data/adb/kill_qcom_lpa/`下的`log.txt`文件
> 本项目针对`KernelSU`进行开发,不保证`Magisk`可用
> **释放**仅支持`arm64`的设备,不支持的设备请自行编译
> `Windows`平台推荐使用`wsl2`进行构建