# brainfxxk

[English](README.md) | 中文

用 Dart 编写的 Brainfuck 解释器:**可复用库为核心 + CLI 前端**。

> ⚠️ 项目处于早期开发阶段,以下功能与用法为设计目标;已实现部分以代码为准。

## 特性

- **预解析 + 跳转表**:源码一次编译为指令列表,括号跳转 O(1) 查表,无现场扫描
- **解析期错误**:括号不匹配在任何指令执行前抛出,带行:列位置
- **动态纸带**:初始 30000 格,右移越界自动倍增扩容
- **可注入 IO**:`BrainfuckIO` 抽象,测试可用内存实现,CLI 接 stdin/stdout
- **REPL**:支持括号跨行输入(未闭合自动续行),纸带状态跨行保留

## 运行语义(BF 方言说明)

不同 Brainfuck 实现在细节上差异很大,本实现的选择:

| 维度 | 行为 |
|---|---|
| 单元格 | 8-bit(0–255),`+`/`-` 溢出回绕(255+1→0,0-1→255) |
| 纸带 | 右侧动态扩展;指针左移越界(< 0)抛 `BrainfuckRuntimeException` |
| EOF | `,` 读到 EOF 时抛 `BrainfuckRuntimeException` |
| 括号不匹配 | 解析期抛 `UnclosedBracketException` / `UnexpectedClosingBracketException` |

## 环境要求

- Dart SDK `^3.12.2`

```bash
dart pub get
```

## CLI 用法

```bash
# 执行文件
dart run bin/bf.dart examples/hello_world.bf

# 直接执行代码字符串
dart run bin/bf.dart -e '+++++[>+++++++++++++<-]>.'   # 输出 A

# 无参数进入 REPL
dart run bin/bf.dart
```

REPL 示例——括号可以跨行,未闭合时自动进入续行模式:

```
bf> >> [>><
... ]
bf> q
```

输入 `q`、`exit` 或 EOF(Ctrl-D)退出 REPL。运行期错误(含 `,` 读到 EOF)打印错误并结束会话。

也可以全局激活后直接使用 `bf` 命令:

```bash
dart pub global activate --source path .
bf examples/hello_world.bf
```

Exit code:0 成功 / 1 运行错误 / 64 用法错误 / 66 文件不存在或不可读。

## 库用法

```dart
import 'package:brainfxxk/brainfxxk.dart';

void main() {
  // 方式一:源码字符串直接构造并执行
  Interpreter.fromSource('+++++[>+++++++++++++<-]>.').run(); // 输出 A

  // 方式二:先解析为 Program,再执行;可检查纸带状态
  final program = parse('+++++[>+++++++++++++<-]>.');
  final interpreter = Interpreter();
  interpreter.run(program);
  print(interpreter.tape[1]); // 65
}
```

解析与执行分离,同一个 `Program` 可重复执行;向 `Interpreter` 传入同一个
`Tape` 可跨多次 `run()` 保留纸带状态(REPL 即基于此实现)。

错误处理:解析期抛 `UnclosedBracketException` / `UnexpectedClosingBracketException`
(带行:列);运行期抛 `BrainfuckRuntimeException`。

## 项目结构

```
brainfxxk-interpreter/
├── bin/
│   └── bf.dart               # CLI 入口:文件 / -e / REPL 三模式
├── lib/
│   ├── brainfxxk.dart        # 库入口,导出公共 API
│   └── src/
│       ├── instruction.dart  # 指令枚举 + Program(指令列表 + 跳转表)
│       ├── parse.dart        # 源码 → Program,括号匹配
│       ├── tape.dart         # 动态纸带,8-bit 回绕单元格
│       ├── interpreter.dart  # 执行引擎
│       ├── io.dart           # BrainfuckIO 抽象 + stdin/stdout 实现
│       ├── repl.dart         # REPL:括号缓冲、续行,q/exit/EOF 退出
│       └── exceptions.dart   # 解析/运行异常(带位置信息)
├── examples/
│   ├── hello_world.bf
│   ├── echo.bf
│   └── squares.bf
└── test/
    ├── instruction_test.dart
    ├── io_test.dart
    ├── parse_test.dart
    ├── tape_test.dart
    ├── interpreter_test.dart
    ├── repl_test.dart
    └── e2e/
        └── cli_e2e_test.dart # 跑 examples 比对预期输出
```

## 开发

```bash
dart analyze        # lint(very_good_analysis 严格规则)
dart format .       # 格式化
dart test           # 全部测试
dart test -n "名称" # 按名称跑单个测试
```
