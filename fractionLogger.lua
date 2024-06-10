function _()
    (""):ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()
end

local scriptName = "Fraction Logger"
local scriptNameShort = "FL"
local scriptAuthor = "Dan Capelli & Oleg Lombardi"
local scriptVersion = "v0.2.0-beta"

script_name(scriptName)
script_author(scriptAuthor)
script_version(scriptVersion)

require "lib.moonloader"
local sampev = require "lib.samp.events"
local imgui = require "lib.imgui"
local encoding = require "encoding"
local requests = require "requests"
requests.http_socket, requests.https_socket = http, http
encoding.default = "CP1251"
local u8 = encoding.UTF8
local fa = require "fAwesome5"

local weakToken = ".EUBT38+,Q~^H.M}E_KmNQ=E9yep}~wv_eot*Jtc#R5%@QKN0LnN+1}Pi7s?eaKLxeub5)"
local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({fa.min_range, fa.max_range})
local mainColorHex = 0xFFFFFFFFF

local rankArray = {
    ["Police"] = {
        u8"Кадет",
        u8"Офицер",
        u8"Мл. Сержант",
        u8"Сержант",
        u8"Прапорщик",
        u8"Ст. Прапорщик",
        u8"Мл. Лейтенант",
        u8"Лейтенант",
        u8"Ст. Лейтенант",
        u8"Капитан",
        u8"Майор",
        u8"Подполковник",
        u8"Полковник",
        u8"Шериф"
    },
    ["Army SF"] = {
        u8"Юнга",
        u8"Матрос",
        u8"Ст. Матрос",
        u8"Старшина",
        u8"Мл. Мичман",
        u8"Мичман",
        u8"Ст. Мичман",
        u8"Мл. Лейтенант",
        u8"Лейтенант",
        u8"Ст. Лейтенант",
        u8"Капитан-Лейтенант",
        u8"Ст. Матрос",
        u8"Контр-Адмирал",
        u8"Вице-Адмирал",
        u8"Адмирал",
    },
    ["Army LV"] = {
        u8"Рядовой",
        u8"Ефрейтор",
        u8"Мл.сержант",
        u8"Сержант",
        u8"Ст. Сержант",
        u8"Старшина",
        u8"Прапорщик",
        u8"Мл. Лейтенант",
        u8"Лейтенант",
        u8"Ст. Лейтенант",
        u8"Капитан",
        u8"Майор",
        u8"Подполковник",
        u8"Полковник",
        u8"Генерал",
    },
    ["FBI"] = {
        u8"Стажёр",
        u8"Дежурный",
        u8"Мл. Агент",
        u8"Агент DEA",
        u8"Агент CID",
        u8"Глава DEA",
        u8"Глава CID",
        u8"Инспектор FBI",
        u8"Зам. Директора FBI",
        u8"Директор FBI",
    },
    ["Mayor"] = {
        u8"Секретарь",
        u8"Адвокат",
        u8"Охранник",
        u8"Нач. Охраны",
        u8"Нач. Профсоюза",
        u8"Зам. Мэра",
        u8"Мэр",
    },
    ["Instructors"] = {
        u8"Стажёр",
        u8"Консультант"
    },
    ["News"] = {
        u8"Стажер",
        u8"Звукооператор",
        u8"Звукорежиссер",
        u8"Репортёр",
        u8"Ведущий",
        u8"Редактор",
        u8"Главный Редактор",
        u8"Технический Директор",
        u8"Программный Директор",
        u8"Генеральный Директор",
    }
}
local playerData = {
    name = u8"Нет",
    id = -1,
    color = nil,
    fraction = u8" ",
    fractionType = nil,
    rank = u8" ",
    server = nil,
}
local membersPool = {}
local offMembersPool = {}
local selectedMember = {
    name = nil,
    id = "",
    rank = nil,
    afk = nil,
    totalOnline = nil,
    lastOnline = nil
}
local commandsArray = {
    giverank = {
        [true] = "giverank",
        [false] = "offgiverank"
    },
    invite = {
        [true] = "uninvite",
        [false] = "offuninvite"
    },
}

local actionsArray = {
    ["/invite"] = "Принятие",
    ["/iinvite"] = "Перевод",
    ["/uninvite"] = "Увольнение",
    ["/giverank"] = "Изменение ранга",
    ["/offuninvite"] = "Увольнение (оффлайн)",
    ["/offgiverank"] = "Изменение ранга (оффлайн)"
}

local sampRpServersArray = {
    ["135.125.189.168"] = "Revolution",
    ["141.95.72.156"] = "Legacy",
    ["51.89.8.242"] = "Underground",
}
local headers = {
    ["Content-Type"] = "application/json",
    ["WeakToken"] = weakToken
}
local dataToPost = {}

local imguiMainWindowState = imgui.ImBool(false)
local isOnlineMode = false
local needToLogin = true


function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then
        return
    end
    while not isSampAvailable() do
        wait(100)
    end
    sampAddChatMessage(string.format("{ffd700}%s | {FFFFFF}%s успешно загружен!", scriptNameShort, scriptName), mainColorHex)
    sampAddChatMessage(string.format("{ffd700}%s | {FFFFFF}Версия: {ffd700}%s{FFFFFF}!", scriptNameShort, scriptVersion), mainColorHex)
    sampAddChatMessage(string.format("{ffd700}%s | {FFFFFF}Авторы: {ffd700}%s{FFFFFF}!", scriptNameShort, scriptAuthor), mainColorHex)
    sendLoggerMessage("Активация скрипта: {ffd700}F3{FFFFFF} ({ffd700}/fl{FFFFFF}).")
    sampRegisterChatCommand("fl", handleImguiMainState)

    local ip, _ = sampGetCurrentServerAddress()
    if not sampRpServersArray[ip] then
        script:unload()
    end
    playerData.server = sampRpServersArray[ip]

    while true do
        wait(0)
        local _, playerId = sampGetPlayerIdByCharHandle(PLAYER_PED)
        playerData.id = playerId
        playerData.name = sampGetPlayerNickname(playerId)
        playerData.color = bit.band(sampGetPlayerColor(playerData.id), 0xffffff)

        imgui.Process = imguiMainWindowState.v
        if isKeyJustPressed(VK_F3) then
            handleImguiMainState()
        end
    end
end

function sendLoggerMessage(message)
    return sampAddChatMessage(string.format("{ffd700}%s | {FFFFFF}%s", scriptNameShort, message), mainColorHex)
end

function handleImguiMainState()
    imguiMainWindowState.v = not imguiMainWindowState.v
end

function sampev.onServerMessage(color, message)
    if needToLogin and message:find("Добро пожаловать на Samp Role Play") then
        sendLoggerMessage("Происходит автоматическая авторизация..")
        lua_thread.create(
            function ()
                wait(1500)
                sampSendChat("/stats")
            end
        )
    end

    if not needToLogin and message:find("Фильтр сброшен") then
        return false
    end

    if not needToLogin and dataToPost ~= {} then
        if message:find(string.format("Вы повысили %s", dataToPost.target))
        or message:find(string.format("Вы понизили %s", dataToPost.target))
        or message:find(string.format("Вы приняли %s", dataToPost.target))
        or message:find(string.format("Вы выгнали %s", dataToPost.target)) then
            lua_thread.create(postData)
        end
    end
end

function sampev.onSendCommand(commandText)
    if needToLogin then
        return commandText
    end

    local command = commandText:match("(%S+)")
    if command == "/invite" or command == "/iinvite" or command == "/uninvite" then
        local targetId, reason = commandText:match("(%d+)%s(.*)")
        if targetId == nil then
            sendLoggerMessage(string.format("Введите: %s [id игрока] [причина]", command))
            return false
        end

        if reason == nil or isEmptyString(reason) then
            reason = "Нет причины"
        end

        if #reason > 25 then
            sendLoggerMessage(string.format("Введите: %s [id игрока] [причина]", command))
            return false
        end

        local targetName = sampGetPlayerNickname(targetId)
        if targetName == nil then
            sendLoggerMessage(string.format("Введите: %s [id игрока] [причина]", command))
            return false
        end
        updateToPostData(actionsArray[command], targetName, reason)
    end

    if command == "/giverank" then
        local targetId, rank, reason = commandText:match("(%d+)%s(%d+)%s(.*)")
        if targetId == nil or rank == nil then
            sendLoggerMessage(string.format("Введите: %s [id игрока] [ранг] [причина*]", command))
            return false
        end

        if reason == nil or isEmptyString(reason) then
            reason = "Нет причины"
        end

        if #reason > 25 then
            sendLoggerMessage(string.format("Введите: %s [id игрока] [ранг] [причина*]", command))
            return false
        end
        local targetName = sampGetPlayerNickname(targetId)
        if targetName == nil then
            sendLoggerMessage(string.format("Введите: %s [id игрока] [причина*]", command))
            return false
        end
        updateToPostData(string.format("%s: %s", actionsArray[command], rank), targetName, reason)
    end

    if command == "/offgiverank" then
        local targetName, rank, reason = commandText:match("(%S+)%s(%d+)%s(.*)")
        local isFound = false
        if targetName == nil or rank == nil then
            sendLoggerMessage(string.format("Введите: %s [имя игрока] [ранг] [причина*]", command))
            return false
        end

        if reason == nil or isEmptyString(reason) then
            reason = "Нет причины"
        end

        if #reason > 25 then
            sendLoggerMessage(string.format("Введите: %s [имя игрока] [ранг] [причина*]", command))
            return false
        end
        if offMembersPool == {} then
            lua_thread.create(
                function ()
                    sendLoggerMessage("Получение списка сотрудников во фракци..")
                    sampSendChat("/offmfilter clear")
                    wait(500)
                    sampSendChat("/offmembers 1")
                end)
        end
        for key, _ in pairs(offMembersPool) do
            if targetName == key then
                isFound = true
                break
            end
        end
        if not isFound then
            sendLoggerMessage("Указанный сотрудник не найден!")
            return false
        end
        updateToPostData(string.format("%s: %s", actionsArray[command], rank), targetName, reason)
    end

    if command == "/offuninvite" then
        local targetName, reason = commandText:match("(%S+)%s(.*)")
        local isFound = false
        if targetName == nil or rank == nil then
            sendLoggerMessage(string.format("Введите: %s [имя игрока] [причина]", command))
            return false
        end

        if reason == nil or isEmptyString(reason) then
            reason = "Нет причины"
        end

        if #reason > 25 then
            sendLoggerMessage(string.format("Введите: %s [имя игрока] [причина]", command))
            return false
        end
        if offMembersPool == {} then
            lua_thread.create(
                function ()
                    sendLoggerMessage("Получение списка сотрудников во фракци..")
                    sampSendChat("/offmfilter clear")
                    wait(500)
                    sampSendChat("/offmembers 1")
                end)
        end
        for key, _ in pairs(offMembersPool) do
            if targetName == key then
                isFound = true
                break
            end
        end
        if not isFound then
            sendLoggerMessage("Указанный сотрудник не найден!")
            return false
        end
        updateToPostData(actionsArray[command], targetName, reason)
    end
end

function updateToPostData(action, target, reason)
    dataToPost.server = u8(playerData.server)
    dataToPost.fraction = u8(playerData.fraction)
    dataToPost.author = playerData.name
    dataToPost.action = u8(action)
    dataToPost.target = target
    dataToPost.reason = u8(reason)
    dataToPost.date = os.date("%d.%m.%Y %H:%M:%S")
end

function postData()
    response = requests.post("http://srp-fl.online/post", {headers=headers, data=dataToPost})
    if response.status_code ~= 200 then
        sendLoggerMessage("Не удалось сохранить лог действий!")
        return
    end
    sendLoggerMessage("Данные отправлены..")
    dataToPost = {}
end

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF("moonloader/resource/fonts/fa-solid-900.ttf", 13.0, font_config, fa_glyph_ranges)
    end
end

function imgui.OnDrawFrame()
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw / 2, sh / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(800, 600), imgui.Cond.FirstUseEver)
    imgui.Begin(string.format(fa.ICON_FA_ATLAS .. " %s (%s)", scriptName, scriptVersion), imguiMainWindowState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

    -- Кнопки (начало)
    imgui.BeginChild("LeftChild", imgui.ImVec2(155, 109), true)
    if imgui.ButtonClickable(not needToLogin, fa.ICON_FA_USER_ALT .. u8" Состав онлайн", imgui.ImVec2(140, 20)) then
        isOnlineMode = true
        selectedMember = {}
        sampSendChat("/members 1")
    end
    if imgui.ButtonClickable(not needToLogin, fa.ICON_FA_USER_ALT_SLASH.. u8" Состав оффлайн", imgui.ImVec2(140, 20)) then
        isOnlineMode = false
        selectedMember = {}
        lua_thread.create(
            function ()
                sampSendChat("/offmfilter clear")
                wait(500)
                sampSendChat("/offmembers 1")
            end)

    end
    if imgui.ButtonClickable(not needToLogin, fa.ICON_FA_SYNC .. u8" Обновить", imgui.ImVec2(140, 20)) then
        selectedMember = {}
        if isOnlineMode then
            sampSendChat("/members 1")
        else
            lua_thread.create(
                function ()
                    sampSendChat("/offmfilter clear")
                    wait(500)
                    sampSendChat("/offmembers 1")
                end)
        end
    end
    if imgui.ButtonClickable(needToLogin, fa.ICON_FA_SIGN_IN_ALT .. u8" Войти", imgui.ImVec2(140, 20)) then
        sampSendChat("/stats")
    end
    imgui.EndChild()
    -- Кнопки (конец)

    -- Информация (начало)
    imguiSetCursorPos(8, 140)
    imgui.BeginChild("LeftBottomChild", imgui.ImVec2(155, 65), true)
    imgui.TextColoredRGB(
        string.format(u8"{%0.6x}%s[%d]", playerData.color, playerData.name, playerData.id)
    )
    imguiSetCursorPos(-6, 25)
    imgui.Text("\t" .. u8(playerData.fraction))
    imguiSetCursorPos(-6, 40)
    imgui.Text("\t" .. u8(playerData.rank))
    imgui.EndChild()
    -- Информация (конец)

    -- Онлайн (начало)
    imguiSetCursorPos(170, 28)
    imgui.BeginChild("MainChild", imgui.ImVec2(622, 562), true)
    if isOnlineMode then
        imgui.Columns(3, "MainColumns", false)
        imgui.Text(fa.ICON_FA_ID_CARD .. u8" Никнейм[ID]")
        imgui.NextColumn()
        imgui.Text("\t" .. fa.ICON_FA_CHART_LINE .. u8" Ранг[*]")
        imgui.NextColumn()
        imgui.Text("\t" .. fa.ICON_FA_BED .. " AFK/Sleep")
        for imguiMemberName, imguiMemberAttrs in pairs(membersPool) do
            imgui.NextColumn()
            if imgui.Selectable(string.format(u8"%s %s", imguiMemberName, imguiMemberAttrs[1]), false, imgui.SelectableFlags.SpanAllColumns) then
                selectedMember.name = imguiMemberName
                selectedMember.id = imguiMemberAttrs[1]
                selectedMember.rank = imguiMemberAttrs[2]
                selectedMember.afk = imguiMemberAttrs[3]
                sendLoggerMessage("Выбран игрок: {6A5ACD}" .. selectedMember.name)
            end
            imgui.NextColumn()
            imgui.Text(u8(imguiMemberAttrs[2]))
            imgui.NextColumn()
            imgui.Text(imguiMemberAttrs[3])
            imgui.Separator()
        end
    end
    -- Онлайн (конец)

    -- Оффлайн (начало)
    if not isOnlineMode then
        imgui.Columns(4, "MainColumns", false)
        imgui.Text(fa.ICON_FA_ID_CARD .. u8" Никнейм")
        imgui.NextColumn()
        imgui.Text(fa.ICON_FA_CHART_LINE .. u8" Ранг[*]")
        imgui.NextColumn()
        imgui.Text(fa.ICON_FA_CLOCK .. u8" Онлайн")
        imgui.NextColumn()
        imgui.Text(fa.ICON_FA_GLOBE .. u8" Последний вход")
        for imguiName, imguiAttr in pairs(offMembersPool) do
            imgui.NextColumn()
            if imgui.Selectable(imguiName, false, imgui.SelectableFlags.SpanAllColumns) then
                selectedMember.name = imguiName
                selectedMember.rank = imguiAttr[1]
                selectedMember.totalOnline = imguiAttr[2]
                selectedMember.lastOnline = imguiAttr[3]
                sendLoggerMessage("Выбран игрок: {6A5ACD}" .. selectedMember.name)
            end
            imgui.NextColumn()
            imgui.Text(string.format("%s [%s]", rankArray[playerData.fractionType][tonumber(imguiAttr[1])], imguiAttr[1]))
            imgui.NextColumn()
            imgui.Text(string.format(u8"%s часов", imguiAttr[2]))
            imgui.NextColumn()
            imgui.Text(imguiAttr[3])
            imgui.Separator()
        end
    end
    imgui.Columns(1)
    imgui.EndChild()
    -- Оффлайн (конец)

    -- Действия (начало)
    imguiSetCursorPos(8, 208)
    imgui.BeginChild("ActionChild", imgui.ImVec2(155, 132), true)
    if imgui.ButtonClickable(selectedMember.name ~= nil, fa.ICON_FA_COPY .. u8" Копировать ник", imgui.ImVec2(140, 20)) then
        sendLoggerMessage(
            string.format("Ник игрока {6A5ACD}%s%s{FFFFFF} скопирован в буфер обмена", selectedMember.name, selectedMember.id)
        )
        setClipboardText(selectedMember.name)
    end

    if imgui.ButtonClickable(selectedMember.name ~= nil, fa.ICON_FA_CLONE .. u8" Копировать RP-ник", imgui.ImVec2(140, 20)) then
        sendLoggerMessage(
            string.format("RP-ник игрока {6A5ACD}%s%s{FFFFFF} скопирован в буфер обмена", selectedMember.name, selectedMember.id)
        )
        setClipboardText(selectedMember.name:gsub("_", " "))
    end

    createActionButton(fa.ICON_FA_PEN .. u8" Изменить ранг", commandsArray.giverank[isOnlineMode], selectedMember.name ~= nil)
    createActionButton(fa.ICON_FA_USER_TIMES .. u8" Уволить", commandsArray.invite[isOnlineMode], selectedMember.name ~= nil)
    createActionButton(fa.ICON_FA_SMS .. u8" Отправить SMS", "t", selectedMember.name ~= nil and isOnlineMode)
    imgui.EndChild()
    -- Действия (конец)

    imgui.End()
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if id == 22 and title == "Статистика персонажа" and needToLogin then
        playerData.fraction = text:match("Организация(.-)\n")
        playerData.rank = text:match("Ранг(.-)\n")
        playerData.fraction = playerData.fraction:gsub("\t", "")
        playerData.rank = playerData.rank:gsub("\t", "")
        local isGovernmentFraction = false

        if playerData.fraction:find("Army SF") or playerData.fraction:find("FBI") or playerData.fraction:find("Army LV") or playerData.fraction:find("Mayor") then
            isGovernmentFraction = true
            playerData.fractionType = playerData.fraction
        end
        if playerData.fraction:find("Police") then
            isGovernmentFraction = true
            playerData.fractionType = "Police"
        end
        if playerData.fraction:find("News") then
            isGovernmentFraction = true
            playerData.fractionType = "News"
        end
        if playerData.fraction ~= "Нет" and isGovernmentFraction then
            sendLoggerMessage(string.format("Вы авторизовались как {ffd700}%s {FFFFFF}({ffd700}%s{FFFFFF}){FFFFFF}!", playerData.rank, playerData.fraction))
        else
            sendLoggerMessage("Не удалось авторизоваться!")

        needToLogin = not needToLogin

        end
        return false
    end

    if id == 22 and title == "Состав онлайн" and imguiMainWindowState.v then
        membersPool = {}
        for _, dialogText in pairs(split(text, "\n")) do
            if dialogText:find("(%[%d+])%s(%w+_%w+)(%A+%s%[%d+])") then
                local memberId, memberName, memberRank, memberAfk = dialogText:match("(%[%d+])%s(%w+_%w+)(%A+%s%[%d+])(.+)")

                membersPool[memberName] = {memberId, memberRank, memberAfk}
            end
        end
        return false
    end

    if id == 22 and title == "Состав оффлайн" and imguiMainWindowState.v then
        offMembersPool = {}
        for _, dialogText in pairs(split(text, "\n")) do
            if dialogText:find("(%w+_%w+)") then
                local memberName = dialogText:match("(%w+_%w+)")
                local memberRank = dialogText:match("%s(%d+)%s")
                local memberLastOnline = dialogText:match("(%d+.%d+.%d+%s%d+.%d+.%d+)")
                local memberTotalOnline = dialogText:match("(%d+%s.%s%d+)")

                offMembersPool[memberName] = {memberRank, memberTotalOnline, memberLastOnline}
            end
        end
        return false
    end
end

-- Imgui stuff..

function setImguiStyle()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 2.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 2.0
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
    colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
    colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end
setImguiStyle()

function createActionButton(label, command, condition)
    local param
    if imgui.ButtonClickable(condition, label, imgui.ImVec2(140, 20)) then
        sampSetChatInputEnabled(true)
        if isOnlineMode then
            param = selectedMember.id:gsub("%[(%d+)%]", "%1")
        else
            param = selectedMember.name
        end
        sampSetChatInputText(string.format("/%s %s ", command, param))
    end
end

function imgui.ButtonClickable(clickable, ...)
    if clickable then
        return imgui.Button(...)

    else
        local r, g, b, a = imgui.ImColor(imgui.GetStyle().Colors[imgui.Col.Button]):GetFloat4()
        imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(r, g, b, a/2) )
        imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(r, g, b, a/2))
        imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(r, g, b, a/2))
        imgui.PushStyleColor(imgui.Col.Text, imgui.GetStyle().Colors[imgui.Col.TextDisabled])
            imgui.Button(...)
        imgui.PopStyleColor()
        imgui.PopStyleColor()
        imgui.PopStyleColor()
        imgui.PopStyleColor()
    end
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == "SSSSSS" then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == "string" and tonumber(color, 16) or color
        if type(color) ~= "number" then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch("[^\r\n]+") do
            local text, colors_, m = {}, {}, 1
            w = w:gsub("{(......)}", "{%1FF}")
            while w:find("{........}") do
                local n, k = w:find("{........}")
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end

    render_text(text)
end

function imguiSetCursorPos(x, y)
    imgui.SetCursorPosX(x)
    imgui.SetCursorPosY(y)
end

-- Функции строк

function split(str, delim, plain)
    local tokens, pos, plain = {}, 1, not (plain == false)
    repeat
        local npos, epos = string.find(str, delim, pos, plain)
        table.insert(tokens, string.sub(str, pos, npos and npos - 1))
        pos = epos and epos + 1
    until not pos
    return tokens
end

function isEmptyString(str)
    return str:gsub("%s", "") == ""
end
