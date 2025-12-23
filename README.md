# AutoClicker_for_G102
罗技G102鼠标专属自动点击脚本（基于Logitech G HUB Lua API开发），适配Windows系统，支持自定义触发按键、随机点击间隔，核心适配罗技驱动单线程运行特性。

## 🚨 核心环境限制（必看）
**罗技G HUB（LGHUB）Lua运行环境为纯单线程架构**，这是本脚本设计的核心约束：
1. 不支持多线程/异步操作，所有逻辑（包括延迟、点击）均在单线程中执行；
2. 休眠（Sleep）期间会完全阻塞脚本进程，无法响应其他按键/事件；
3. 无法使用 `for/while` 等循环语句实现多次点击（线程阻塞会导致驱动无响应），只能通过重复调用函数的方式实现；
4. 脚本执行期间，鼠标其他自定义按键的响应会延迟，直至当前逻辑执行完毕。

## 📄 代码文件详解（AutoClicker_for_G102.lua）
### 1. 文件定位
该文件是罗技G HUB驱动的专属Lua脚本，需放置在罗技驱动的脚本目录（默认路径：`C:\Users\[你的用户名]\AppData\Local\Logitech Gaming Software\Scripts`），仅支持罗技G102（及兼容罗技Lua API的鼠标）。

### 2. 核心功能
通过鼠标自定义按键（G5）触发自动左键点击，结合固定+随机延迟模拟人工点击节奏，支持ScrollLock键全局开关控制，避免误触。

### 3. 关键变量定义（可自定义）
| 变量名              | 类型   | 默认值 | 功能说明                                                                 |
|---------------------|--------|--------|--------------------------------------------------------------------------|
| `primarySleep`      | 数值   | 100    | 基础点击间隔（毫秒），单线程下该延迟会阻塞脚本，需合理设置避免驱动卡死     |
| `randomSleepRange`  | 数值   | 50     | 随机延迟范围（0~50ms），与基础延迟叠加，降低点击机械性                     |
| `triggerButton`     | 数值   | 5      | 触发按键（5=G5键，4=G4键，罗技鼠标侧键编号，可根据鼠标型号调整）          |
| `lockKey`           | 字符串 | "scrolllock" | 功能开关按键（ScrollLock），开启时才能触发自动点击，全局生效         |
| `blockG5`           | 布尔   | false  | G5键阻断标记（单线程下防止重复触发，避免多次执行点击逻辑）                |

### 4. 核心函数逻辑（适配单线程特性）
#### (1) `Click()` - 单次点击执行函数
```lua
function Click()
    PressMouseButton(1) -- 按下左键
    Sleep(10) -- 短延迟（单线程阻塞，模拟人工按下时长）
    ReleaseMouseButton(1) -- 释放左键
    OutputLogMessage("[ACTION] 左键单击已执行\n") -- 日志输出（罗技驱动控制台可见）
end
```
- 单线程下需添加10ms短延迟，避免点击被驱动判定为“无效操作”；
- 日志输出仅在罗技G HUB的“脚本控制台”中可见，用于调试。

#### (2) `CustomSleep()` - 随机延迟函数（适配单线程）
```lua
function CustomSleep()
    local randomSleep = math.random(0, randomSleepRange) -- 生成随机偏移
    local totalSleep = primarySleep + randomSleep -- 总延迟=基础+随机
    Sleep(totalSleep) -- 单线程休眠，期间脚本无响应
    OutputLogMessage("[DELAY] 延迟时间：" .. totalSleep .. "ms\n")
end
```
- 单线程下 `Sleep()` 是唯一延迟方式，无替代方案；
- 随机值避免固定间隔被判定为“自动脚本”，但需控制总延迟（建议≤200ms，否则驱动卡顿）。

#### (3) `OnEvent()` - 核心事件回调（单线程入口）
罗技G HUB的Lua脚本唯一事件入口，所有按键/鼠标事件均在此处理（单线程串行执行）：
```lua
function OnEvent(event, arg)
    -- 事件1：G4键切换ScrollLock开关状态（全局控制）
    if event == "MOUSE_BUTTON_PRESSED" and arg == 4 then
        PressKey(lockKey)
        ReleaseKey(lockKey)
        OutputLogMessage("[G4] Scroll Lock状态已切换\n")
    end

    -- 事件2：G5键触发自动点击（单线程串行执行）
    if event == "MOUSE_BUTTON_PRESSED" and arg == triggerButton then
        if blockG5 then return end -- 阻断重复触发（单线程防重入）
        if IsKeyLockOn(lockKey) then
            blockG5 = true -- 开启阻断
            -- 单线程下无法用循环，只能重复调用函数实现3次点击
            Click()
            CustomSleep()
            Click()
            CustomSleep()
            Click()
            blockG5 = false -- 关闭阻断
            -- 点击结束后重置ScrollLock（避免持续触发）
            PressKey(lockKey)
            ReleaseKey(lockKey)
        end
    end
end
```
- 单线程防重入：通过 `blockG5` 标记避免G5键在点击过程中被重复触发；
- 无循环设计：因单线程循环+休眠会导致驱动无响应，故直接重复调用 `Click()` 实现多次点击；
- 全局开关：通过ScrollLock键控制功能启用，避免误触G5键触发点击。

### 5. 运行与使用说明
#### 前置条件
1. 安装罗技G HUB驱动（[官方下载](https://www.logitechg.com/zh-cn/innovation/g-hub.html)）；
2. 确保鼠标为罗技G102（或兼容罗技Lua API的型号，如G304、G502）；
3. 将脚本文件放入罗技驱动脚本目录，在G HUB中启用该脚本。

#### 操作步骤
1. 按下鼠标G4键：切换ScrollLock状态（开启=功能可用，关闭=功能禁用）；
2. 开启ScrollLock后，按下G5键：触发3次自动左键点击（间隔100~150ms随机）；
3. 点击结束后，脚本自动关闭ScrollLock（防止后续误触）；
4. 如需停止脚本：直接在G HUB中禁用脚本，或按下ScrollLock键关闭开关。

## ⚠️ 注意事项（单线程相关）
1. 单线程限制：点击执行期间，鼠标其他按键（如G4、左键/右键）会延迟响应，直至点击逻辑完成；
2. 延迟上限：`primarySleep + randomSleepRange` 建议≤200ms，否则单线程休眠过久会导致罗技驱动卡顿/无响应；
3. 无中断机制：单线程下一旦触发点击，无法中途终止，需等待逻辑执行完毕；
4. 兼容性：仅支持罗技G HUB驱动，不支持其他鼠标驱动（如雷柏、达尔优），且仅在Windows系统可用；
5. 防检测：本脚本仅用于技术研究，严禁用于游戏/平台违规操作，随机延迟仅为模拟人工，无法规避专业反作弊检测。

## 📄 许可证
本脚本基于MIT协议开源，可自由修改、分发，但需保留本说明中的单线程环境限制提示，且不得用于商业作弊场景。
```

### 关键优化点（适配GitHub发布）
1. **单线程重点突出**：将罗技单线程特性作为独立章节，明确标注“核心环境限制”，让使用者第一时间了解约束；
2. **结构化解析**：用表格+代码块+分步说明，替代纯文本，符合GitHub文档阅读习惯；
3. **实用性补充**：增加脚本存放路径、驱动下载链接、自定义变量说明，降低使用门槛；
4. **风险提示**：强化单线程导致的卡顿/无响应问题，给出延迟上限建议；
5. **合规声明**：补充许可证和违规使用警示，符合开源仓库规范。
