#!/bin/bash

# 基因组评估流程脚本
# 用于对新组装的基因组进行LTR转座子分析和LAI计算
# 作者：yongchao
# 日期：2025.7.27

# 显示帮助信息
show_help() {
    cat << EOF
基因组评估流程脚本

用法: $0 -g GENOME_FILE [选项]

必需参数:
  -g GENOME_FILE    基因组文件路径

可选参数:
  -d WORK_DIR       工作目录 (默认: 当前目录)
  -t THREADS        线程数 (默认: 48)
  -s CHUNK_SIZE     分块大小 (默认: 5000000)
  -c CONFIG_FILE    配置文件路径 (默认: ./config.sh)
  -h                显示此帮助信息

描述:
  此脚本用于对新组装的基因组进行LTR转座子分析和LAI计算。
  流程包括：
  1. 使用LTR_FINDER_parallel和LTR_HARVEST_parallel识别LTR转座子
  2. 使用LTR_retriever进行分析和LAI计算
  3. 生成分析报告和结果文件

示例:
  $0 -g genome.fa                           # 使用默认设置
  $0 -g genome.fa -d /path/to/workdir       # 指定工作目录
  $0 -g genome.fa -t 20 -s 1000000          # 指定线程数和分块大小
  $0 -g genome.fa -c custom.conf            # 使用自定义配置文件
  $0 -h                                     # 显示帮助信息

输出文件:
  - 基因组名.out.LAI: 完整LAI结果
  - format1.LAI: LAI摘要信息
  - 基因组名.LTRlib.fa: LTR转座子序列库
  - all.scn: 合并的LTR注释文件
  - genome_evaluation_*.log: 运行日志

EOF
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 默认参数设置
GENOME_FILE=""
WORK_DIR="$(pwd)"
THREADS=48
CHUNK_SIZE=5000000
CONFIG_FILE="$SCRIPT_DIR/config.sh"

# 解析命令行参数
while getopts "g:d:t:s:c:h" opt; do
    case $opt in
        g)
            GENOME_FILE="$OPTARG"
            ;;
        d)
            WORK_DIR="$OPTARG"
            ;;
        t)
            THREADS="$OPTARG"
            ;;
        s)
            CHUNK_SIZE="$OPTARG"
            ;;
        c)
            CONFIG_FILE="$OPTARG"
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            echo "错误：无效的选项 -$OPTARG" >&2
            echo "使用 -h 查看帮助信息"
            exit 1
            ;;
    esac
done

# 检查必需参数
if [ -z "$GENOME_FILE" ]; then
    echo "错误：必须指定基因组文件路径 (-g)" >&2
    echo "使用 -h 查看帮助信息"
    exit 1
fi

# 检查基因组文件是否存在
if [ ! -f "$GENOME_FILE" ]; then
    echo "错误：基因组文件不存在: $GENOME_FILE" >&2
    exit 1
fi

# 转换为绝对路径
GENOME_FILE="$(realpath "$GENOME_FILE")"
WORK_DIR="$(realpath "$WORK_DIR")"

# 检查配置文件路径是否为相对路径，如果是则转换为绝对路径
if [[ "$CONFIG_FILE" != /* ]]; then
    CONFIG_FILE="$SCRIPT_DIR/$CONFIG_FILE"
fi

# 加载配置文件
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "已加载配置文件: $CONFIG_FILE"
else
    echo "错误：配置文件不存在: $CONFIG_FILE"
    echo "请先创建并配置配置文件，或使用 -h 查看帮助信息"
    exit 1
fi

# 设置日志文件
LOG_FILE="$WORK_DIR/genome_evaluation_$(date +%Y%m%d_%H%M%S).log"

# 日志函数
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] ERROR: $message" | tee -a "$LOG_FILE" >&2
}

# 检查必要文件和目录
check_requirements() {
    log_message "检查运行环境..."
    
    # 验证配置
    if ! validate_config; then
        log_error "配置验证失败"
        exit 1
    fi
    
    # 创建工作目录
    if [ ! -d "$WORK_DIR" ]; then
        log_message "创建工作目录: $WORK_DIR"
        mkdir -p "$WORK_DIR"
        if [ $? -ne 0 ]; then
            log_error "无法创建工作目录: $WORK_DIR"
            exit 1
        fi
    fi
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    log_message "环境检查完成"
}

# 步骤1：运行LTR_FINDER_parallel和LTR_HARVEST_parallel
run_ltr_finding() {
    log_message "=== 步骤1：LTR转座子识别 ==="
    cd "$WORK_DIR"
    
    log_message "运行LTR_FINDER_parallel..."
    log_message "命令: $PERL_PATH $LTR_FINDER_PARALLEL -seq $GENOME_FILE -size $CHUNK_SIZE -finder $LTR_FINDER_BIN -threads $THREADS -harvest_out"
    
    "$PERL_PATH" "$LTR_FINDER_PARALLEL" \
        -seq "$GENOME_FILE" \
        -size "$CHUNK_SIZE" \
        -finder "$LTR_FINDER_BIN" \
        -threads "$THREADS" \
        -harvest_out 2>&1 | tee -a "$LOG_FILE"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        log_error "LTR_FINDER_parallel运行失败"
        exit 1
    fi
    
    log_message "运行LTR_HARVEST_parallel..."
    # 设置LTR_HARVEST_parallel环境变量
    export PATH="$LTR_HARVEST_ENV_PATH:$PATH"
    
    log_message "命令: $PERL_PATH $LTR_HARVEST_PARALLEL -seq $GENOME_FILE -size $CHUNK_SIZE -threads $THREADS"
    
    "$PERL_PATH" "$LTR_HARVEST_PARALLEL" \
        -seq "$GENOME_FILE" \
        -size "$CHUNK_SIZE" \
        -threads "$THREADS" 2>&1 | tee -a "$LOG_FILE"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        log_error "LTR_HARVEST_parallel运行失败"
        exit 1
    fi
    
    log_message "LTR转座子识别完成"
}

# 步骤2：合并结果并运行LTR_retriever
run_ltr_retriever() {
    log_message "=== 步骤2：LTR_retriever分析和LAI计算 ==="
    cd "$WORK_DIR"
    
    # 获取基因组文件名（不含路径）
    GENOME_NAME=$(basename "$GENOME_FILE")
    
    log_message "合并LTR_FINDER和LTR_HARVEST结果..."
    log_message "合并文件: ${GENOME_NAME}.finder.combine.scn + ${GENOME_NAME}.harvest.combine.scn -> all.scn"
    
    # 检查输入文件是否存在
    if [ ! -f "${GENOME_NAME}.finder.combine.scn" ]; then
        log_error "LTR_FINDER结果文件不存在: ${GENOME_NAME}.finder.combine.scn"
        exit 1
    fi
    
    if [ ! -f "${GENOME_NAME}.harvest.combine.scn" ]; then
        log_error "LTR_HARVEST结果文件不存在: ${GENOME_NAME}.harvest.combine.scn"
        exit 1
    fi
    
    cat "${GENOME_NAME}.finder.combine.scn" "${GENOME_NAME}.harvest.combine.scn" > all.scn
    
    if [ $? -ne 0 ]; then
        log_error "合并scn文件失败"
        exit 1
    fi
    
    log_message "运行LTR_retriever..."
    # 设置LTR_retriever环境变量
    export PATH="$LTR_RETRIEVER_ENV_PATH:$PATH"
    
    log_message "命令: $LTR_RETRIEVER_BIN -threads $THREADS -genome $GENOME_FILE -inharvest all.scn"
    
    "$LTR_RETRIEVER_BIN" \
        -threads "$THREADS" \
        -genome "$GENOME_FILE" \
        -inharvest all.scn 2>&1 | tee -a "$LOG_FILE"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        log_error "LTR_retriever运行失败"
        exit 1
    fi
    
    log_message "提取LAI信息..."
    if [ ! -f "${GENOME_NAME}.out.LAI" ]; then
        log_error "LAI结果文件不存在: ${GENOME_NAME}.out.LAI"
        exit 1
    fi
    
    head -2 "${GENOME_NAME}.out.LAI" > format1.LAI
    
    if [ $? -ne 0 ]; then
        log_error "提取LAI信息失败"
        exit 1
    fi
    
    log_message "LTR_retriever分析完成"
}

# 显示结果摘要
show_results() {
    log_message "=== 分析结果摘要 ==="
    cd "$WORK_DIR"
    
    GENOME_NAME=$(basename "$GENOME_FILE")
    
    if [ -f "format1.LAI" ]; then
        log_message "LAI结果:"
        cat format1.LAI | tee -a "$LOG_FILE"
    else
        log_error "LAI摘要文件不存在: format1.LAI"
    fi
    
    log_message ""
    log_message "输出文件位置: $WORK_DIR"
    log_message "主要输出文件:"
    
    # 检查并列出实际存在的文件
    local files_found=0
    
    if [ -f "${GENOME_NAME}.out.LAI" ]; then
        log_message "  ✓ ${GENOME_NAME}.out.LAI: 完整LAI结果"
        files_found=$((files_found + 1))
    else
        log_message "  ✗ ${GENOME_NAME}.out.LAI: 文件不存在"
    fi
    
    if [ -f "format1.LAI" ]; then
        log_message "  ✓ format1.LAI: LAI摘要信息"
        files_found=$((files_found + 1))
    else
        log_message "  ✗ format1.LAI: 文件不存在"
    fi
    
    if [ -f "${GENOME_NAME}.LTRlib.fa" ]; then
        log_message "  ✓ ${GENOME_NAME}.LTRlib.fa: LTR转座子序列库"
        files_found=$((files_found + 1))
    else
        log_message "  ✗ ${GENOME_NAME}.LTRlib.fa: 文件不存在"
    fi
    
    if [ -f "all.scn" ]; then
        log_message "  ✓ all.scn: 合并的LTR注释文件"
        files_found=$((files_found + 1))
    else
        log_message "  ✗ all.scn: 文件不存在"
    fi
    
    log_message "日志文件: $LOG_FILE"
    log_message "成功生成 $files_found 个输出文件"
}

# 主函数
main() {
    local start_time=$(date +%s)
    
    log_message "开始基因组评估流程..."
    log_message "运行参数:"
    log_message "  基因组文件: $GENOME_FILE"
    log_message "  工作目录: $WORK_DIR"
    log_message "  线程数: $THREADS"
    log_message "  分块大小: $CHUNK_SIZE"
    log_message "  日志文件: $LOG_FILE"
    log_message ""
    
    # 显示当前配置
    log_message "软件配置:"
    show_config | tee -a "$LOG_FILE"
    log_message ""
    
    check_requirements
    run_ltr_finding
    run_ltr_retriever
    show_results
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local hours=$((duration / 3600))
    local minutes=$(((duration % 3600) / 60))
    local seconds=$((duration % 60))
    
    log_message "基因组评估流程完成！"
    log_message "总耗时: ${hours}小时${minutes}分钟${seconds}秒"
}

# 运行主函数
main "$@"
