EnablePrimaryMouseButtonEvents(true)

local primarySleep = 100       -- 基础延迟时间（ms）
local randomSleepRange = 50    -- 随机延迟
local triggerButton = 5        -- 触发按键
local lockKey = "scrolllock"   -- 开关键
local blockG5 = false  -- G5输入阻断标记

function Click()
    PressAndReleaseMouseButton(1)
    OutputLogMessage("[ACTION] 左键单击已执行\n")
end

function CustomSleep()
    local randomDelay = math.random(0, randomSleepRange)
    local totalSleep = primarySleep + randomDelay
    Sleep(totalSleep)
    OutputLogMessage(string.format("[DELAY] 延迟时间：%dms\n", totalSleep))
end

function OnEvent(event, arg)
    if event == "MOUSE_BUTTON_PRESSED" and arg == 4 then
        PressAndReleaseKey("scrolllock")
        OutputLogMessage("[G4] Scroll Lock状态已切换\n")
        return
    end
    if event == "MOUSE_BUTTON_PRESSED" and arg == triggerButton then
        if blockG5 then
            OutputLogMessage("[阻断] 连点执行中，忽略G5输入\n")
            return
        end
        
        local isLockEnabled = IsKeyLockOn(lockKey)
        OutputLogMessage(string.format(
            "[EVENT] 按键%d按下 | %s状态：%s\n",
            arg,
            lockKey,
            isLockEnabled and "开启" or "关闭"
        ))
        
        if isLockEnabled then
            blockG5 = true 
            Click()
            CustomSleep()
            Click()
            CustomSleep()
            Click()
            CustomSleep()
            blockG5 = false  -- 执行完毕解除阻断，注LGHUB环境的lua不支持循环
            PressAndReleaseKey("scrolllock")
            CustomSleep()
            PressAndReleaseKey("scrolllock")
            
        end
    end
end