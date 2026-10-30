# ⚡ 30 秒快速开始

## 🎯 我想...

### ...第一次运行这个 App

```bash
git clone https://github.com/YOUR_USERNAME/BassPractice.git
cd BassPractice
./scripts/install.sh
```

**就这么简单!** 脚本会自动处理所有事情。

---

### ...日常开发时快速重新构建

```bash
./scripts/quickstart.sh
```

---

### ...在真机上测试

```bash
./scripts/run.sh device
```

---

### ...清理所有缓存重新开始

```bash
./scripts/run.sh clean
./scripts/run.sh
```

---

### ...用 Xcode 图形界面

```bash
open BassPractice.xcodeproj
```

然后按 `Cmd+R` 运行。

---

## ❓ 遇到问题?

| 问题 | 解决 |
|------|------|
| Permission denied | `chmod +x scripts/*.sh` |
| xcodegen not found | `brew install xcodegen` |
| No simulator found | 打开 Xcode → Settings → Components → 下载 iOS 17+ Simulator |
| Build failed | `./scripts/run.sh clean` 然后重试 |

---

## 📚 更多帮助

- 详细教程: [SETUP_GUIDE.md](SETUP_GUIDE.md)
- 脚本说明: [scripts/README.md](scripts/README.md)
- 完整文档: [README.md](README.md)

---

**Happy Coding! 🎸**
