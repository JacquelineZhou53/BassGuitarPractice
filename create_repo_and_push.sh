#!/bin/bash

# BassPractice - 自动创建 GitHub 仓库并推送
# 需要 Personal Access Token

set -e

echo "=========================================="
echo "  🚀 自动创建 GitHub 仓库并推送"
echo "=========================================="
echo ""

# 检查 Token
TOKEN_FILE=~/.github_token

if [ -f "$TOKEN_FILE" ]; then
    echo "✅ 找到已保存的 Token"
    GITHUB_TOKEN=$(cat "$TOKEN_FILE")
else
    echo "⚠️  需要 GitHub Personal Access Token"
    echo ""
    echo "请按以下步骤获取:"
    echo "1. 访问: https://github.com/settings/tokens"
    echo "2. Generate new token (classic)"
    echo "3. Note: BassPractice"
    echo "4. Scopes: ✅ 勾选 repo (全选)"
    echo "5. 生成并复制 Token"
    echo ""
    read -p "请粘贴 Token (ghp_...): " GITHUB_TOKEN

    # 保存 Token
    echo "$GITHUB_TOKEN" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo "✅ Token 已保存"
fi

echo ""
echo "Step 1/3: 删除旧仓库(如果存在)..."

# 尝试删除旧仓库
REPO_NAME="BassGuitarPractice"
USERNAME="JacquelineZhou53"

curl -s -o /dev/null -w "%{http_code}" -X DELETE \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$USERNAME/$REPO_NAME"

echo "✅ 清理完成"

echo ""
echo "Step 2/3: 创建新仓库..."

# 创建新仓库
RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{
    "name": "'"$REPO_NAME"'",
    "description": "五弦贝斯 & 吉他练习助手 - iOS 应用",
    "private": false,
    "auto_init": false
  }' \
  "https://api.github.com/user/repos")

# 检查是否成功
if echo "$RESPONSE" | grep -q '"full_name"'; then
    echo "✅ 仓库创建成功: $USERNAME/$REPO_NAME"
else
    echo "❌ 仓库创建失败"
    echo "响应: $RESPONSE"
    exit 1
fi

echo ""
echo "Step 3/3: 推送代码..."

cd "/Users/coco_j/Documents/GameHacker/Bass Practice"

# 重置远程仓库
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/$USERNAME/$REPO_NAME.git

# 配置认证
git config credential.helper store
echo "https://$USERNAME:$GITHUB_TOKEN@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials

# 推送
git push -u origin main

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "  🎉 成功!"
    echo "=========================================="
    echo ""
    echo "仓库地址:"
    echo "https://github.com/$USERNAME/$REPO_NAME"
    echo ""
    echo "查看提交记录:"
    echo "https://github.com/$USERNAME/$REPO_NAME/commits/main"
    echo ""
else
    echo ""
    echo "❌ 推送失败"
    echo ""
    echo "请检查错误信息"
    exit 1
fi
