#!/bin/bash
set -e

# 获取脚本所在的目录
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$DIR/.." && pwd )"

# 构建产物输出目录
DIST_DIR="$PROJECT_DIR/dist"
APP_NAME="SpotlightProgress"
APP_DIR="$DIST_DIR/$APP_NAME.app"

echo "======================= 开始构建 macOS 原生 App ======================="

# 1. 清理并创建 dist 目录结构
echo "-> 准备目录结构..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 2. 编译 Swift SPM 项目 (Release 模式)
echo "-> 编译 Swift 项目..."
cd "$PROJECT_DIR"
swift build -c release

# 找到编译生成的可执行文件路径
# macOS 的二进制产物通常在 .build/release/SpotlightProgress
BINARY_PATH=".build/release/SpotlightProgress"
if [ ! -f "$BINARY_PATH" ]; then
    # 尝试在 debug 目录查找
    BINARY_PATH=".build/debug/SpotlightProgress"
    if [ ! -f "$BINARY_PATH" ]; then
        echo "❌ 错误: 未能找到编译出的二进制文件！"
        exit 1
    fi
    echo "⚠️ 警告: 未找到 Release 编译结果，将使用 Debug 编译产物。"
fi

# 复制二进制文件
echo "-> 部署二进制文件..."
cp "$BINARY_PATH" "$APP_DIR/Contents/MacOS/$APP_NAME"
chmod +x "$APP_DIR/Contents/MacOS/$APP_NAME"

# 3. 部署 Info.plist 和后台 Python 脚本
echo "-> 部署资源与配置..."
cp "$PROJECT_DIR/src/macos/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$PROJECT_DIR/src/IosIndexingProgress.py" "$APP_DIR/Contents/Resources/IosIndexingProgress.py"

# 4. 生成 AppIcon.icns (如果提供了 PNG 图片)
PNG_ICON="/Users/shawnrain/.gemini/antigravity/brain/e6e871a5-693e-4b5a-96c4-14ce96a923bc/app_icon_base_1781679347786.png"
if [ -f "$PNG_ICON" ]; then
    echo "-> 正在由 PNG 生成 macOS 矢量图标 .icns..."
    ICONSET_DIR="$DIST_DIR/AppIcon.iconset"
    rm -rf "$ICONSET_DIR"
    mkdir -p "$ICONSET_DIR"
    
    # 缩放到各种标准的 macOS 尺寸
    sips -s format png -z 16 16     "$PNG_ICON" --out "$ICONSET_DIR/icon_16x16.png"
    sips -s format png -z 32 32     "$PNG_ICON" --out "$ICONSET_DIR/icon_16x16@2x.png"
    sips -s format png -z 32 32     "$PNG_ICON" --out "$ICONSET_DIR/icon_32x32.png"
    sips -s format png -z 64 64     "$PNG_ICON" --out "$ICONSET_DIR/icon_32x32@2x.png"
    sips -s format png -z 128 128   "$PNG_ICON" --out "$ICONSET_DIR/icon_128x128.png"
    sips -s format png -z 256 256   "$PNG_ICON" --out "$ICONSET_DIR/icon_128x128@2x.png"
    sips -s format png -z 256 256   "$PNG_ICON" --out "$ICONSET_DIR/icon_256x256.png"
    sips -s format png -z 512 512   "$PNG_ICON" --out "$ICONSET_DIR/icon_256x256@2x.png"
    sips -s format png -z 512 512   "$PNG_ICON" --out "$ICONSET_DIR/icon_512x512.png"
    sips -s format png -z 1024 1024 "$PNG_ICON" --out "$ICONSET_DIR/icon_512x512@2x.png"
    
    # 使用 iconutil 编译成 .icns 资源
    iconutil -c icns "$ICONSET_DIR" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
    rm -rf "$ICONSET_DIR"
    echo "-> 图标生成成功！"
else
    echo "⚠️ 提示: 未能定位默认的 png 图标，应用将使用缺省图标。"
fi

echo "======================= 🎉 macOS 原生 App 构建完成！ ======================="
echo "最终 App 路径: $APP_DIR"
echo "您可以直接在 Finder 中双击打开或将其拖入 '应用程序 (Applications)' 文件夹中。"
