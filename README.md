# 基因组评估流程脚本

这是一个用于对新组装的基因组进行LTR转座子分析和LAI（LTR Assembly Index）计算的自动化流程脚本。

## 功能概述

该流程包含以下主要步骤：

1. **LTR转座子识别**：使用LTR_FINDER_parallel和LTR_HARVEST_parallel识别基因组中的LTR转座子
2. **LTR分析和LAI计算**：使用LTR_retriever进行后续分析并计算LAI指数
3. **结果整理**：生成标准化的输出文件和分析报告

## 文件结构

```
基因组评估/
├── genome_evaluation_pipeline.sh  # 主执行脚本
├── config.sh                     # 配置文件
└── README.md                     # 使用说明（本文件）
```

## 使用方法

### 1. 环境配置

首次使用前，需要配置软件路径：

```bash
# 方法1：使用配置向导（推荐）
bash setup_config.sh

# 方法2：手动编辑配置文件
vim config.sh
```

**必须修改的配置项：**

- `GENOME_FILE`: 基因组文件的绝对路径
- `WORK_DIR`: 工作目录路径
- `PERL_PATH`: Perl解释器路径
- `LTR_FINDER_PARALLEL`: LTR_FINDER_parallel脚本路径
- `LTR_FINDER_BIN`: ltr_finder二进制文件路径
- `LTR_HARVEST_PARALLEL`: LTR_HARVEST_parallel脚本路径
- `LTR_RETRIEVER_BIN`: LTR_retriever二进制文件路径
- 相关环境路径变量

**可选修改的配置项：**

- `THREADS`: 线程数（默认20）
- `CHUNK_SIZE`: 分块大小（默认5000000）

### 2. 运行脚本

```bash
# 基本用法（必须指定基因组文件）
bash genome_evaluation_pipeline.sh -g /path/to/genome.fa

# 完整参数示例
bash genome_evaluation_pipeline.sh -g /path/to/genome.fa -d /path/to/workdir -t 48 -s 5000000

# 查看帮助信息
bash genome_evaluation_pipeline.sh -h

# 或使用示例脚本（交互式配置）
bash run_example.sh
```

### 3. 命令行参数说明

- `-g GENOME_FILE`: 基因组文件路径（必需）
- `-d WORK_DIR`: 工作目录（可选，默认当前目录）
- `-t THREADS`: 线程数（可选，默认48）
- `-s CHUNK_SIZE`: 分块大小（可选，默认5000000）
- `-c CONFIG_FILE`: 配置文件路径（可选，默认./config.sh）
- `-h`: 显示帮助信息

### 3. 查看结果

脚本运行完成后，会在工作目录中生成以下文件：

- `基因组名.out.LAI`: 完整的LAI分析结果
- `format1.LAI`: LAI摘要信息（前两行）
- `基因组名.LTRlib.fa`: LTR转座子序列库
- `all.scn`: 合并的LTR注释文件
- `genome_evaluation_YYYYMMDD_HHMMSS.log`: 详细的运行日志

## 软件依赖

运行此脚本需要以下软件：

1. **Perl**: 用于运行各种Perl脚本
2. **LTR_FINDER_parallel**: LTR转座子识别工具
3. **LTR_HARVEST_parallel**: 另一个LTR转座子识别工具
4. **LTR_retriever**: LTR转座子分析和LAI计算工具

## 原始脚本对比

### 原始脚本的问题：
- 硬编码的路径，难以在不同环境中使用
- 缺乏错误处理和日志记录
- 没有配置验证
- 代码结构不清晰

### 重写脚本的改进：
- **模块化设计**: 将配置和执行逻辑分离
- **完善的错误处理**: 每个步骤都有错误检查和处理
- **详细的日志记录**: 所有操作都会记录到日志文件
- **配置验证**: 运行前检查所有必需的文件和路径
- **进度跟踪**: 显示执行进度和耗时统计
- **结果验证**: 检查输出文件是否正确生成

## 配置示例

以下是一个完整的 `config.sh` 配置示例：

```bash
# 软件路径设置
export PERL_PATH="/usr/bin/perl"
export LTR_FINDER_PARALLEL="/opt/LTR_FINDER_parallel/LTR_FINDER_parallel"
export LTR_FINDER_BIN="/opt/LTR_FINDER_parallel/bin/ltr_finder"
export LTR_HARVEST_PARALLEL="/opt/LTR_HARVEST_parallel/LTR_HARVEST_parallel"
export LTR_RETRIEVER_BIN="/opt/LTR_retriever/LTR_retriever"
```

注意：基因组文件路径、工作目录、线程数和分块大小现在通过命令行参数指定，不再在配置文件中设置。

## 故障排除

### 常见问题：

1. **配置验证失败**
   - 检查所有路径是否正确
   - 确保文件具有执行权限
   - 验证基因组文件是否存在

2. **软件运行失败**
   - 检查软件依赖是否正确安装
   - 查看日志文件中的详细错误信息
   - 确保有足够的磁盘空间和内存

3. **权限问题**
   - 确保对工作目录有写权限
   - 检查软件的执行权限

### 查看日志：

```bash
# 查看最新的日志文件
tail -f /path/to/workdir/genome_evaluation_*.log

# 搜索错误信息
grep "ERROR" /path/to/workdir/genome_evaluation_*.log
```

## 性能优化建议

1. **线程数设置**: 根据服务器CPU核心数调整THREADS参数
2. **内存使用**: 大基因组可能需要更多内存，建议至少100GB
3. **磁盘空间**: 确保有足够的临时存储空间
4. **网络存储**: 避免在网络存储上运行，使用本地SSD可提高性能


---

**注意**: 请在运行脚本前仔细检查配置文件，确保所有路径都正确设置。错误的配置可能导致分析失败或产生不正确的结果。
