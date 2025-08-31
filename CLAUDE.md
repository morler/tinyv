# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

tinyv 是一个简化的 V 语言编译器，作为研究项目用于探索简化和改进主 V 编译器的方法。项目采用 V 语言编写，遵循简单性和稳定性原则。

## 构建和运行

### 运行编译器
```bash
# 创建符号链接到 V modules
ln -s /path/to/code/tinyv/src/tinyv $HOME/.vmodules/tinyv

# 运行 tinyv 编译器
v run src/cmd/tinyv/tinyv.v --skip-builtin --skip-imports -d test/syntax.v
```

### 命令行选项
- `--debug` 或 `-d`: 启用调试模式
- `--verbose` 或 `-v`: 启用详细输出
- `--skip-genv`: 跳过 V 代码生成
- `--skip-builtin`: 跳过内置模块
- `--skip-imports`: 跳过导入处理
- `--no-parallel`: 禁用并行解析

### 测试
测试文件位于 `test/` 目录中：
- `test/syntax.v`: 主要语法测试文件
- `test/generic_*.v`: 泛型相关测试
- `test/string_interpolation.v`: 字符串插值测试
- 其他特定语法特性测试

## 架构概览

### 编译器阶段
1. **前端 (Frontend)**
   - Scanner (`src/tinyv/scanner/`): 词法分析
   - Parser (`src/tinyv/parser/`): 语法分析
   - AST Generation (`src/tinyv/ast/`): 抽象语法树生成

2. **中端 (Middle)**
   - Type Checking (`src/tinyv/types/`): 类型检查
   - AST → SSA IR (`src/tinyv/ir/ssa/`): 转换为 SSA 中间表示
   - Optimization passes: 优化过程

3. **后端 (Backend/Code Generation)**
   - V 代码生成 (`src/tinyv/gen/v/`): 从 AST 生成 V 代码用于测试
   - 计划支持 x64 机器代码生成

### 核心模块结构
- `src/cmd/tinyv/`: 命令行入口点
- `src/tinyv/pref/`: 编译器偏好设置和配置
- `src/tinyv/builder/`: 构建管理器，协调各个编译阶段
- `src/tinyv/token/`: 令牌定义和位置信息
- `src/tinyv/errors/`: 错误处理和报告
- `src/tinyv/util/`: 工具函数，包括工作池

### 关键设计特点
- 支持并行解析（可通过 `--no-parallel` 禁用）
- 模块化架构，各个编译阶段独立
- SSA（静态单赋值）中间表示用于优化
- 可选的 V 代码生成用于测试解析器正确性

### AST 结构
AST 使用 V 的联合类型（sum types）定义，主要类型包括：
- `Expr`: 表达式类型（包括 BasicLiteral、CallExpr、IfExpr 等）
- `Stmt`: 语句类型
- 支持完整的 V 语言语法构造

### 性能监控
编译器内置性能计时，报告各阶段耗时：
- Scan & Parse: 扫描和解析时间
- Type Check: 类型检查时间
- Gen (v): V 代码生成时间
- Total: 总时间

## 开发指南

### 调试模式
使用 `--debug` 或 `-d` 标志启用调试输出，将显示正在处理的 V 文件列表。

### 并行处理
默认启用并行文件解析以提高性能。如遇到并发问题，可使用 `--no-parallel` 禁用。

### SSA IR 参考文献
项目参考了多篇 SSA 构造的学术论文，详见 `src/tinyv/ir/ssa/references.md`。