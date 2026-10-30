#!/bin/bash

# BassPractice - 推送到 GitHub 脚本
# 使用 Personal Access Token 认证

echo "=========================================="
echo "  🚀 推送 BassPractice 到 GitHub"
echo "=========================================="
echo ""

# 检查是否已有 Token
TOKEN_FILE=~/.github_token

if [ -f "$TOKEN_FILE" ]; then
    echo "✅ 找到已保存的 Token"
    GITHUB_TOKEN=$(cat "$TOKEN_FILE")
else
    echo "⚠️  需要 GitHub Personal Access Token"
    echo ""
    echo "请按以下步骤获取 Token:"
    echo "1. 访问: https://github.com/settings/tokens"
    echo "2. Generate new token (classic)"
    echo "3. Note: BassPractice Mac"
    echo "4. Scopes: 勾选 repo (全选)"
    echo "5. 生成并复制 Token"
    echo ""
    read -p "请粘贴你的 Token: " GITHUB_TOKEN
    
    # 询问是否保存 Token
    read -p "是否保存 Token 以便下次使用? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$GITHUB_TOKEN" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        echo "✅ Token 已保存到 ~/.github_token"
    fi
fi

echo ""
echo "开始推送..."
echo ""

# 使用 Token 推送
cd "/Users/coco_j/Documents/GameHacker/Bass Practice"

# 设置认证信息
git config credential.helper store

# 推送(会自动使用保存的 Token)
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "  🎉 推送成功!"
    echo "=========================================="
    echo ""
    echo "访问你的仓库:"
    echo "https://github.com/JacquelineZhou53/BassGuitarPractice"
    echo ""
else
    echo ""
    echo "❌ 推送失败"
    echo ""
    echo "可能的原因:"
    echo "1. Token 无效或过期"
    echo "2. 仓库不存在(请先在 GitHub 上创建)"
    echo "3. 网络连接问题"
    echo ""
    echo "请检查错误信息并重试"
fi
