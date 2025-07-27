#!/bin/bash

# 配置文件自动生成脚本
# 帮助用户快速配置基因组评估流程

echo "=== 基因组评估流程配置向导 ==="
echo "注意：基因组文件路径、工作目录、线程数和分块大小现在通过命令行参数指定"
echo "此配置向导仅用于设置软件路径"
echo

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.sh"

# 检查是否已存在配置文件
if [ -f "$CONFIG_FILE" ]; then
    echo "发现现有配置文件: $CONFIG_FILE"
    read -p "是否要备份现有配置并创建新配置？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "已备份现有配置文件"
    else
        echo "配置已取消"
        exit 0
    fi
fi

echo "开始配置向导..."
echo

echo
echo "=== 软件路径配置 ==="

# Perl路径
PERL_PATH=$(which perl 2>/dev/null)
if [ -n "$PERL_PATH" ]; then
    read -p "Perl路径 [默认: $PERL_PATH]: " USER_PERL
    if [ -n "$USER_PERL" ]; then
        PERL_PATH="$USER_PERL"
    fi
else
    read -p "请输入Perl解释器路径: " PERL_PATH
fi

# 常见的软件安装路径
echo
echo "正在搜索常见的软件安装路径..."

# 搜索LTR_FINDER_parallel
LTR_FINDER_PATHS=(
    "/opt/LTR_FINDER_parallel*/LTR_FINDER_parallel"
    "/usr/local/bin/LTR_FINDER_parallel"
    "$HOME/software/LTR_FINDER_parallel*/LTR_FINDER_parallel"
    "$HOME/bin/LTR_FINDER_parallel"
)

LTR_FINDER_PARALLEL=""
for path in "${LTR_FINDER_PATHS[@]}"; do
    if ls $path 1> /dev/null 2>&1; then
        LTR_FINDER_PARALLEL=$(ls $path | head -1)
        break
    fi
done

if [ -n "$LTR_FINDER_PARALLEL" ]; then
    echo "找到LTR_FINDER_parallel: $LTR_FINDER_PARALLEL"
    read -p "是否使用此路径？(y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入LTR_FINDER_parallel脚本路径: " LTR_FINDER_PARALLEL
    fi
else
    read -p "请输入LTR_FINDER_parallel脚本路径: " LTR_FINDER_PARALLEL
fi

# 搜索ltr_finder二进制文件
LTR_FINDER_BIN=$(which ltr_finder 2>/dev/null)
if [ -z "$LTR_FINDER_BIN" ]; then
    # 在conda环境中搜索
    if command -v conda >/dev/null 2>&1; then
        CONDA_ENVS=$(conda env list | grep -v "^#" | awk '{print $2}' | grep -v "^$")
        for env in $CONDA_ENVS; do
            if [ -f "$env/bin/ltr_finder" ]; then
                LTR_FINDER_BIN="$env/bin/ltr_finder"
                break
            fi
        done
    fi
fi

if [ -n "$LTR_FINDER_BIN" ]; then
    echo "找到ltr_finder: $LTR_FINDER_BIN"
    read -p "是否使用此路径？(y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入ltr_finder二进制文件路径: " LTR_FINDER_BIN
    fi
else
    read -p "请输入ltr_finder二进制文件路径: " LTR_FINDER_BIN
fi

# 类似地处理其他软件路径...
read -p "请输入LTR_HARVEST_parallel脚本路径: " LTR_HARVEST_PARALLEL
read -p "请输入LTR_HARVEST环境bin目录路径: " LTR_HARVEST_ENV_PATH

# 搜索LTR_retriever
LTR_RETRIEVER_BIN=$(which LTR_retriever 2>/dev/null)
if [ -z "$LTR_RETRIEVER_BIN" ]; then
    # 在conda环境中搜索
    if command -v conda >/dev/null 2>&1; then
        CONDA_ENVS=$(conda env list | grep -v "^#" | awk '{print $2}' | grep -v "^$")
        for env in $CONDA_ENVS; do
            if [ -f "$env/bin/LTR_retriever" ]; then
                LTR_RETRIEVER_BIN="$env/bin/LTR_retriever"
                LTR_RETRIEVER_ENV_PATH="$env/bin"
                break
            fi
        done
    fi
fi

if [ -n "$LTR_RETRIEVER_BIN" ]; then
    echo "找到LTR_retriever: $LTR_RETRIEVER_BIN"
    read -p "是否使用此路径？(y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        read -p "请输入LTR_retriever二进制文件路径: " LTR_RETRIEVER_BIN
        read -p "请输入LTR_retriever环境bin目录路径: " LTR_RETRIEVER_ENV_PATH
    fi
else
    read -p "请输入LTR_retriever二进制文件路径: " LTR_RETRIEVER_BIN
    read -p "请输入LTR_retriever环境bin目录路径: " LTR_RETRIEVER_ENV_PATH
fi

echo
echo "=== 生成配置文件 ==="

# 生成配置文件
cat > "$CONFIG_FILE" << EOF
#!/bin/bash

# 基因组评估流程配置文件
# 自动生成于: $(date)

# =============================================================================
# 基本设置
# =============================================================================

# 注意：基因组文件路径、工作目录、线程数和分块大小现在通过命令行参数指定
# 请使用以下参数运行脚本：
# -g GENOME_FILE    基因组文件路径（必需）
# -d WORK_DIR       工作目录（可选，默认当前目录）
# -t THREADS        线程数（可选，默认48）
# -s CHUNK_SIZE     分块大小（可选，默认5000000）

# =============================================================================
# 软件路径设置
# =============================================================================

# Perl解释器路径
export PERL_PATH="$PERL_PATH"

# LTR_FINDER_parallel脚本路径
export LTR_FINDER_PARALLEL="$LTR_FINDER_PARALLEL"

# ltr_finder二进制文件路径
export LTR_FINDER_BIN="$LTR_FINDER_BIN"

# LTR_HARVEST_parallel脚本路径
export LTR_HARVEST_PARALLEL="$LTR_HARVEST_PARALLEL"

# LTR_HARVEST_parallel环境路径
export LTR_HARVEST_ENV_PATH="$LTR_HARVEST_ENV_PATH"

# LTR_retriever二进制文件路径
export LTR_RETRIEVER_BIN="$LTR_RETRIEVER_BIN"

# LTR_retriever环境路径
export LTR_RETRIEVER_ENV_PATH="$LTR_RETRIEVER_ENV_PATH"

# =============================================================================
# 高级设置
# =============================================================================

# 内存限制（用于集群提交）
export MEMORY_LIMIT="100g"

# 是否启用详细输出
export VERBOSE=true

# 临时文件目录
export TEMP_DIR="/tmp"

# =============================================================================
# 验证配置函数
# =============================================================================

validate_config() {
    echo "验证配置设置..."
    
    local errors=0
    
    # 检查软件路径
    if [ ! -f "\$PERL_PATH" ]; then
        echo "警告：Perl解释器路径可能不正确: \$PERL_PATH"
    fi
    
    if [ ! -f "\$LTR_FINDER_PARALLEL" ]; then
        echo "错误：LTR_FINDER_parallel脚本不存在: \$LTR_FINDER_PARALLEL"
        errors=\$((errors + 1))
    fi
    
    if [ ! -f "\$LTR_FINDER_BIN" ]; then
        echo "错误：ltr_finder二进制文件不存在: \$LTR_FINDER_BIN"
        errors=\$((errors + 1))
    fi
    
    if [ ! -f "\$LTR_HARVEST_PARALLEL" ]; then
        echo "错误：LTR_HARVEST_parallel脚本不存在: \$LTR_HARVEST_PARALLEL"
        errors=\$((errors + 1))
    fi
    
    if [ ! -f "\$LTR_RETRIEVER_BIN" ]; then
        echo "错误：LTR_retriever二进制文件不存在: \$LTR_RETRIEVER_BIN"
        errors=\$((errors + 1))
    fi
    
    if [ \$errors -gt 0 ]; then
        echo "发现 \$errors 个配置错误，请检查并修正配置文件"
        return 1
    else
        echo "配置验证通过"
        return 0
    fi
}

# 显示当前配置
show_config() {
    echo "当前配置:"
    echo "  Perl路径: \$PERL_PATH"
    echo "  LTR_FINDER_parallel: \$LTR_FINDER_PARALLEL"
    echo "  LTR_FINDER二进制: \$LTR_FINDER_BIN"
    echo "  LTR_HARVEST_parallel: \$LTR_HARVEST_PARALLEL"
    echo "  LTR_retriever: \$LTR_RETRIEVER_BIN"
    echo "  注意：基因组文件、工作目录、线程数和分块大小通过命令行参数指定"
}
EOF

echo "✓ 配置文件已生成: $CONFIG_FILE"
echo

echo "=== 验证配置 ==="
source "$CONFIG_FILE"
if validate_config; then
    echo "✓ 配置验证通过！"
    echo
    echo "现在可以运行以下命令开始分析:"
    echo "  ./genome_evaluation_pipeline.sh"
    echo "或者使用示例脚本:"
    echo "  ./run_example.sh"
else
    echo "✗ 配置验证失败，请检查并修正配置文件"
    echo "配置文件位置: $CONFIG_FILE"
fi

echo
echo "配置完成！"