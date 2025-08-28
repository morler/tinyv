# TinyV 修复任务清单

基于 `issues.md` 中发现的编译问题，以下是具体的修复任务清单。

## 高优先级任务（阻止编译）

### 1. 修复 token.Pos 类型可见性问题 ✅ **已完成**

**文件**: `src/tinyv/token/position.v`
**位置**: 第11行
**任务**: 将私有类型改为公共类型

**修改前**:
```v
type Pos = int
```

**修改后**:
```v
pub type Pos = int
```

**影响范围**: 修复此问题解决了以下文件中的所有相关编译错误：
- `src/tinyv/ast/ast.v` (多处使用) ✅
- `src/tinyv/parser/parser.v` (2处使用) ✅
- `src/tinyv/types/checker.v` (1处使用) ✅
- `src/tinyv/types/object.v` (1处使用) ✅
- `src/tinyv/types/scope.v` (2处使用) ✅

**验证结果**: 编译检查通过，所有编译错误已解决，仅剩下2个警告。

## 中优先级任务（未来将成为错误）

### 2. 修复常量组语法问题

**文件**: `src/tinyv/types/universe.v`
**位置**: 第10行
**任务**: 修复即将弃用的常量组语法

**修复命令**:
```bash
v fmt -w src/tinyv/types/universe.v
```

**说明**: 这将自动修复 `const () groups` 语法问题

## 低优先级任务（警告修复）

### 3. 修复 map 访问安全性警告

**文件**: `src/tinyv/types/checker.v`
**位置**: 第1292行
**任务**: 为访问包含指针的map值添加安全检查

**当前代码**:
```v
c.env.methods[method_owner_type.name()] << &obj
```

**建议修复**:
```v
c.env.methods[method_owner_type.name()] or { [] } << &obj
```

或使用 unsafe 块:
```v
unsafe {
    c.env.methods[method_owner_type.name()] << &obj
}
```

## 验证任务

### 4. 编译验证

完成上述修复后，使用以下命令验证修复效果：

**基本编译检查**:
```bash
v -check src/cmd/tinyv/tinyv.v
```

**完整编译测试**:
```bash
cd /d/Code/MyProject/V/tinyv
v run src/cmd/tinyv/tinyv.v --skip-builtin --skip-imports -d test/syntax.v
```

## 任务执行顺序

1. **首先**: 修复 token.Pos 类型可见性问题（任务1）
2. **其次**: 修复常量组语法问题（任务2）
3. **最后**: 修复 map 访问安全性警告（任务3）
4. **验证**: 执行编译验证（任务4）

## 预期结果

完成所有任务后，项目应该能够：
- 无错误编译通过
- 消除所有编译警告
- 正常运行 tinyv 编译器命令

## 注意事项

- 确保在修改前创建备份
- 修改后立即进行编译测试
- 如果发现其他问题，及时更新此文档