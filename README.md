# Codex 获取 Claude Code Skills

让 Codex 能够发现和使用 Claude Code 的 skills，实现渐进式加载（progressive disclosure）机制。

## 项目概述

这个项目提供了一个枚举器系统，允许 Codex 在启动时自动发现 Claude Code skills，并根据任务需求按需加载对应的 skill 文件，避免一次性加载所有 skills 浪费上下文窗口。

## 核心功能

- **自动发现**: 扫描 `~/.claude/skills/` 目录下所有 Claude Code skills
- **元数据提取**: 从 SKILL.md 文件的 YAML frontmatter 中提取 name 和 description
- **渐进式加载**: 只在任务匹配时才加载完整的 SKILL.md 内容
- **JSON 输出**: 输出结构化的 JSON 列表，便于程序解析

## 项目结构

```
claude-skills-for-codex/
├── README.md                    # 项目说明文档
├── install.ps1                  # 一键安装脚本
└── skills/
    ├── SKILL.md                 # Claude Code Skill 定义
    └── scripts/
        └── list-skills.py       # Python 枚举脚本
```

## 快速开始

### 前置要求

- Windows 系统
- Python 已安装（`python --version` 可正常输出）
- pip 已安装
- Codex CLI 已安装

## Agent.md

- 将以下内容添加到 Agents.md中即可

```markdown
## Claude Code Skills Integration

You have access to Claude Code skills via an enumerator script.

### Boot Sequence
- At the start of each session, run `python $HOME\你的用户名\.codex\skills\claude-skills-enumerator\scripts\list-skills.py` to discover all available Claude Code skills.
- The script outputs a JSON array with each skill's name, description, and path.
- Remember this list in memory for the duration of the session.

### Using Skills
- When a user's task matches a skill's description, read that skill's full SKILL.md from the path field.
- Do NOT preload all SKILL.md files. Only load what you need (progressive disclosure).
- Follow the loaded skill's instructions to complete the task.
- If multiple skills match, pick the most relevant one and state which you are using.
- If no skill matches, proceed normally without loading any skill.

### Fallback
- If the script fails, inform the user and continue without skills.

```


### 安装步骤

**方式一：一键安装（推荐）**

```powershell
.\install.ps1
```

**方式二：手动安装**

1. **安装依赖**

   ```bash
   pip install python-frontmatter pyyaml
   ```
2. **复制文件到 Codex skills 目录**

   ```powershell
   New-Item -ItemType Directory -Force -Path "$HOME\.codex\skills\claude-skills-enumerator\scripts"
   Copy-Item "skills\SKILL.md" "$HOME\.codex\skills\claude-skills-enumerator\"
   Copy-Item "skills\scripts\list-skills.py" "$HOME\.codex\skills\claude-skills-enumerator\scripts\"
   ```
3. **配置 AGENTS.md**

   创建 `$HOME\.codex\AGENTS.md` 并添加以下内容：

   ```markdown
   ## Claude Code Skills Integration

   You have access to Claude Code skills via an enumerator script.

   ### Boot Sequence
   - At the start of each session, run `python $HOME\.codex\skills\claude-skills-enumerator\scripts\list-skills.py` to discover all available Claude Code skills.
   - The script outputs a JSON array with each skill's name, description, and path.
   - Remember this list in memory for the duration of the session.

   ### Using Skills
   - When a user's task matches a skill's description, read that skill's full SKILL.md from the path field.
   - Do NOT preload all SKILL.md files. Only load what you need (progressive disclosure).
   - Follow the loaded skill's instructions to complete the task.
   - If multiple skills match, pick the most relevant one and state which you are using.
   - If no skill matches, proceed normally without loading any skill.

   ### Fallback
   - If the script fails, inform the user and continue without skills.
   ```
4. **验证安装**

   ```bash
   python $HOME\.codex\skills\claude-skills-enumerator\scripts\list-skills.py
   ```

## 使用方法

### 在 Codex 中使用

启动 Codex 后，可以直接询问：

```
What skills are available?
```

Codex 会自动运行 `list-skills.py` 并列出所有可用的 Claude Code skills。

### 手动运行脚本

默认扫描（扫描 `~/.claude/skills`）：

```bash
python $HOME\.codex\skills\claude-skills-enumerator\scripts\list-skills.py
```

自定义目录：

```bash
python $HOME\.codex\skills\claude-skills-enumerator\scripts\list-skills.py C:\path\to\skills
```

环境变量方式：

```bash
SKILLS_DIR=C:\path\to\skills python list-skills.py
```

## 输出格式

```json
[
  {
    "name": "skill-name",
    "description": "What this skill does and when to use it",
    "path": "C:\\Users\\YourUsername\\.claude\\skills\\skill-name\\SKILL.md",
    "allowed-tools": ["Read", "Bash"]
  }
]
```

## 工作原理

1. **启动阶段**: Codex 读取 AGENTS.md，得知需要运行 `list-skills.py`
2. **扫描阶段**: 脚本扫描 `~/.claude/skills/` 下所有 SKILL.md 文件
3. **提取阶段**: 从 YAML frontmatter 中提取元数据（name, description, path）
4. **加载阶段**: Codex 将 JSON 列表保存在上下文中
5. **使用阶段**: 当任务匹配某个 skill 的 description 时，才读取完整的 SKILL.md
