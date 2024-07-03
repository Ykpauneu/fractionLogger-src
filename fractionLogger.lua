function _()
    (""):ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()():ae()
end

local scriptName = "Fraction Logger"
local scriptNameShort = "FL"
local scriptAuthor = "Dan Capelli & Oleg Lombardi"
local scriptVersion = "v0.4.0-beta"
local scriptChangeLog = [[
Fraction Logger - v0.4.0-beta

- Äîáàâëåíà âîçìîæíîñòü âûãðóçêè offmembers'à íà ñàéò
- Èçìåíåíî îòîáðàæåíèå òàáëèöû ñîñòàâà îíëàéí
- Óáðàíà êíîïêà îáíîâèòü
- Íåáîëüøèå èñïðàâëåíèÿ
]]

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

local weakToken = ""
local fa_font = nil
local fa_glyph_ranges = imgui.ImGlyphRanges({fa.min_range, fa.max_range})
local mainColorHex = 0xFFFFFFFFF
local postCooldown = 0

local rankArray = {
    ["Police"] = {
        u8"Êàäåò",
        u8"Îôèöåð",
        u8"Ìë. Ñåðæàíò",
        u8"Ñåðæàíò",
        u8"Ïðàïîðùèê",
        u8"Ñò. Ïðàïîðùèê",
        u8"Ìë. Ëåéòåíàíò",
        u8"Ëåéòåíàíò",
        u8"Ñò. Ëåéòåíàíò",
        u8"Êàïèòàí",
        u8"Ìàéîð",
        u8"Ïîäïîëêîâíèê",
        u8"Ïîëêîâíèê",
        u8"Øåðèô"
    },
    ["Army SF"] = {
        u8"Þíãà",
        u8"Ìàòðîñ",
        u8"Ñò. Ìàòðîñ",
        u8"Ñòàðøèíà",
        u8"Ìë. Ìè÷ìàí",
        u8"Ìè÷ìàí",
        u8"Ñò. Ìè÷ìàí",
        u8"Ìë. Ëåéòåíàíò",
        u8"Ëåéòåíàíò",
        u8"Ñò. Ëåéòåíàíò",
        u8"Êàïèòàí-Ëåéòåíàíò",
        u8"Ñò. Ìàòðîñ",
        u8"Êîíòð-Àäìèðàë",
        u8"Âèöå-Àäìèðàë",
        u8"Àäìèðàë",
    },
    ["Army LV"] = {
        u8"Ðÿäîâîé",
        u8"Åôðåéòîð",
        u8"Ìë.ñåðæàíò",
        u8"Ñåðæàíò",
        u8"Ñò. Ñåðæàíò",
        u8"Ñòàðøèíà",
        u8"Ïðàïîðùèê",
        u8"Ìë. Ëåéòåíàíò",
        u8"Ëåéòåíàíò",
        u8"Ñò. Ëåéòåíàíò",
        u8"Êàïèòàí",
        u8"Ìàéîð",
        u8"Ïîäïîëêîâíèê",
        u8"Ïîëêîâíèê",
        u8"Ãåíåðàë",
    },
    ["FBI"] = {
        u8"Ñòàæ¸ð",
        u8"Äåæóðíûé",
        u8"Ìë. Àãåíò",
        u8"Àãåíò DEA",
        u8"Àãåíò CID",
        u8"Ãëàâà DEA",
        u8"Ãëàâà CID",
        u8"Èíñïåêòîð FBI",
        u8"Çàì. Äèðåêòîðà FBI",
        u8"Äèðåêòîð FBI",
    },
    ["Mayor"] = {
        u8"Ñåêðåòàðü",
        u8"Àäâîêàò",
        u8"Îõðàííèê",
        u8"Íà÷. Îõðàíû",
        u8"Íà÷. Ïðîôñîþçà",
        u8"Çàì. Ìýðà",
        u8"Ìýð",
    },
    ["Instructors"] = {
        u8"Ñòàæ¸ð",
        u8"Êîíñóëüòàíò"
    },
    ["News"] = {
        u8"Ñòàæåð",
        u8"Çâóêîîïåðàòîð",
        u8"Çâóêîðåæèññåð",
        u8"Ðåïîðò¸ð",
        u8"Âåäóùèé",
        u8"Ðåäàêòîð",
        u8"Ãëàâíûé Ðåäàêòîð",
        u8"Òåõíè÷åñêèé Äèðåêòîð",
        u8"Ïðîãðàììíûé Äèðåêòîð",
        u8"Ãåíåðàëüíûé Äèðåêòîð",
    }
}

local playerData = {
    name = u8"Íåò",
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
    ["/invite"] = "Ïðèíÿòèå",
    ["/iinvite"] = "Ïåðåâîä",
    ["/uninvite"] = "Óâîëüíåíèå",
    ["/giverank"] = "Èçìåíåíèå ðàíãà",
    ["/offuninvite"] = "Óâîëüíåíèå (îôôëàéí)",
    ["/offgiverank"] = "Èçìåíåíèå ðàíãà (îôôëàéí)"
}

local sampRpServersArray = {
    ["135.125.189.168"] = "Revolution",
    ["141.95.72.156"] = "Legacy",
    ["51.89.8.242"] = "Underground",
}

local headers = {
    ["Content-Type"] = "application/json",
    ["WeakToken"] = weakToken,
    ["Server"] = nil,
    ["Fraction"] = nil
}

local postUrl = {
    [true] = "https://srp-fl.online/post",
    [false] = "https://srp-fl.online/post_offmembers",
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

    sendLoggerMessage(string.format("{ffd700}%s {FFFFFF}óñïåøíî çàãðóæåí!", scriptName))
    sendLoggerMessage("Àêòèâàöèÿ ñêðèïòà: {ffd700}F3{FFFFFF} ({ffd700}/fl{FFFFFF}).")
    sendLoggerMessage(string.format("Àâòîðû: {A6A6A6}Dan_Capelli {FFFFFF}& {FFA500}Oleg_Lombardi{FFFFFF}."))
    sampRegisterChatCommand("fl", handleImguiMainState)
    autoUpdateScript(
        "https://github.com/Ykpauneu/Fraction-Logger/raw/main/update.json",
        "['..string.upper(thisScript().name)..']: ",
        "https://github.com/Ykpauneu/Fraction-Logger/raw/main/fractionLogger.luac"
    )
    local ip, _ = sampGetCurrentServerAddress()
    if not sampRpServersArray[ip] then
        thisScript():unload()
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
    if needToLogin and message:find("Äîáðî ïîæàëîâàòü íà Samp Role Play") then
        sendLoggerMessage("Ïðîèñõîäèò àâòîìàòè÷åñêàÿ àâòîðèçàöèÿ..")
        lua_thread.create(
            function ()
                wait(1500)
                sampSendChat("/stats")
            end
        )
    end

    if not needToLogin and message:find("Ôèëüòð ñáðîøåí") then
        return false
    end

    if not needToLogin and dataToPost ~= {} then
        if message:find(string.format("Âû ïîâûñèëè %s", dataToPost.target))
        or message:find(string.format("Âû ïîíèçèëè %s", dataToPost.target))
        or message:find(string.format("Âû ïðèíÿëè %s", dataToPost.target))
        or message:find(string.format("Âû âûãíàëè %s", dataToPost.target)) then
            lua_thread.create(function ()
                postData(dataToPost, true)
            end)
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
            sendLoggerMessage(string.format("Ââåäèòå: %s [id èãðîêà] [ïðè÷èíà]", command))
            return false
        end

        if reason == nil or isEmptyString(reason) then
            reason = "Íåò ïðè÷èíû"
        end

        if #reason > 25 then
            sendLoggerMessage(string.format("Ââåäèòå: %s [id èãðîêà] [ïðè÷èíà]", command))
            return false
        end

        local targetName = sampGetPlayerNickname(targetId)
        if targetName == nil then
            sendLoggerMessage(string.format("Ââåäèòå: %s [id èãðîêà] [ïðè÷èíà]", command))
            return false
        end
        updateToPostData(actionsArray[command], targetName, reason)
    end

    if command == "/giverank" then
        local targetId, rank, reason = commandText:match("(%d+)%s(%d+)%s(.*)")
        if targetId == nil or rank == nil then
            sendLoggerMessage(string.format("Ââåäèòå: %s [id èãðîêà] [ðàíã] [ïðè÷èíà*]", command))
            return false
        end

        if reason == nil or isEmptyString(reason) then
            reason = "Íåò ïðè÷èíû"
        end

        if #reason > 25 then
            sendLoggerMessage(string.format("Ââåäèòå: %s [id èãðîêà] [ðàíã] [ïðè÷èíà*]", command))
            return false
        end
        local targetName = sampGetPlayerNickname(targetId)
        if targetName == nil then
            sendLoggerMessage(string.format("Ââåäèòå: %s [id èãðîêà] [ïðè÷èíà*]", command))
            return false
        end
        updateToPostData(string.format("%s: %s", actionsArray[command], rank), targetName, reason)
    end

    if command == "/offgiverank" then
        local targetName, rank, reason = commandText:match("(%S+)%s(%d+)%s(.*)")
        local isFound = false
        if targetName == nil or rank == nil then
            sendLoggerMessage(string.format("Ââåäèòå: %s [èìÿ èãðîêà] [ðàíã] [ïðè÷èíà*]", command))
            return false
        end

        if reason == nil or isEmptyString(reason) then
            reason = "Íåò ïðè÷èíû"
        end

        if #reason > 25 then
            sendLoggerMessage(string.format("Ââåäèòå: %s [èìÿ èãðîêà] [ðàíã] [ïðè÷èíà*]", command))
            return false
        end
        if offMembersPool == {} then
            lua_thread.create(
                function ()
                    sendLoggerMessage("Ïîëó÷åíèå ñïèñêà ñîòðóäíèêîâ âî ôðàêöè..")
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
            sendLoggerMessage("Óêàçàííûé ñîòðóäíèê íå íàéäåí!")
            return false
        end
        updateToPostData(string.format("%s: %s", actionsArray[command], rank), targetName, reason)
    end

    if command == "/offuninvite" then
        local targetName, reason = commandText:match("(%S+)%s(.*)")
        local isFound = false
        if targetName == nil or rank == nil then
            sendLoggerMessage(string.format("Ââåäèòå: %s [èìÿ èãðîêà] [ïðè÷èíà]", command))
            return false
        end

        if reason == nil or isEmptyString(reason) then
            reason = "Íåò ïðè÷èíû"
        end

        if #reason > 25 then
            sendLoggerMessage(string.format("Ââåäèòå: %s [èìÿ èãðîêà] [ïðè÷èíà]", command))
            return false
        end
        if offMembersPool == {} then
            lua_thread.create(
                function ()
                    sendLoggerMessage("Ïîëó÷åíèå ñïèñêà ñîòðóäíèêîâ âî ôðàêöè..")
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
            sendLoggerMessage("Óêàçàííûé ñîòðóäíèê íå íàéäåí!")
            return false
        end
        updateToPostData(actionsArray[command], targetName, reason)
    end
end

function updateToPostData(action, target, reason)
    dataToPost.author = playerData.name
    dataToPost.action = u8(action)
    dataToPost.target = target
    dataToPost.reason = u8(reason)
    dataToPost.date = os.date("%d.%m.%Y %H:%M:%S")
end

function postData(data, isLog)
    headers["Server"] = u8(playerData.server)
    headers["Fraction"] = u8(playerData.fraction)
    if not isLog then
        local d = {}
        for k, v in pairs(data) do
            d[k] = {
                string.format("%s [%s]", rankArray[playerData.fractionType][tonumber(v[1])], v[1]),
                string.format(u8"%s ÷àñîâ", v[2]),
                v[3]
            }
        end
        data = d
    end

    response = requests.post(postUrl[isLog], {headers=headers, data=data})
    if response.status_code ~= 200 then
        sendLoggerMessage(string.format("Íå óäàëîñü ñîõðàíèòü ëîã äåéñòâèé! (%s)", response.status_code))
        return
    end
    sendLoggerMessage("Äàííûå îòïðàâëåíû..")
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
    imgui.Begin(string.format(fa.ICON_FA_ATLAS .. " %s", scriptName), imguiMainWindowState, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

    -- Êíîïêè (íà÷àëî)
    imgui.BeginChild("LeftChild", imgui.ImVec2(155, 109), true)
    if imgui.ButtonClickable(not needToLogin, fa.ICON_FA_USER_ALT .. u8" Ñîñòàâ îíëàéí", imgui.ImVec2(140, 20)) then
        isOnlineMode = true
        selectedMember = {}
        sampSendChat("/members 1")
    end
    if imgui.ButtonClickable(not needToLogin, fa.ICON_FA_USER_ALT_SLASH.. u8" Ñîñòàâ îôôëàéí", imgui.ImVec2(140, 20)) then
        isOnlineMode = false
        selectedMember = {}
        lua_thread.create(
            function ()
                sampSendChat("/offmfilter clear")
                wait(500)
                sampSendChat("/offmembers 1")
            end)

    end
    if imgui.ButtonClickable(not needToLogin and not isOnlineMode, fa.ICON_FA_CLOUD_UPLOAD_ALT .. u8" Âûãðóçèòü", imgui.ImVec2(140, 20)) then
        if offMembersPool == {} then
            lua_thread.create(
                function ()
                    sampSendChat("/offmfilter clear")
                    wait(500)
                    sampSendChat("/offmembers 1")
                end)
        end
        postData(offMembersPool, false)
    end

    if imgui.ButtonClickable(needToLogin, fa.ICON_FA_SIGN_IN_ALT .. u8" Âîéòè", imgui.ImVec2(140, 20)) then
        sampSendChat("/stats")
    end
    imgui.EndChild()
    -- Êíîïêè (êîíåö)

    -- Èíôîðìàöèÿ (íà÷àëî)
    imguiSetCursorPos(8, 140)
    imgui.BeginChild("LeftBottomChild", imgui.ImVec2(155, 65), true)
    imgui.TextColoredRGB(
        string.format(u8"{%0.6x}%s[%d]", playerData.color, playerData.name, playerData.id)
    )
    imgui.Text(u8(playerData.fraction))
    imgui.Text(u8(playerData.rank))
    imgui.EndChild()
    -- Èíôîðìàöèÿ (êîíåö)

    -- Îíëàéí (íà÷àëî)
    imguiSetCursorPos(170, 28)
    imgui.BeginChild("MainChild", imgui.ImVec2(622, 562), true)
    if isOnlineMode then
        imgui.Columns(3, "MainColumns", false)
        imgui.Text(fa.ICON_FA_ID_CARD .. u8" Íèêíåéì[ID]")
        imgui.NextColumn()
        imgui.Text(fa.ICON_FA_CHART_LINE .. u8" Ðàíã[*]")
        imgui.NextColumn()
        imgui.Text(fa.ICON_FA_BED .. " AFK/Sleep")
        for imguiMemberName, imguiMemberAttrs in pairs(membersPool) do
            imgui.NextColumn()
            if imgui.Selectable(string.format(u8"%s %s", imguiMemberName, imguiMemberAttrs[1]), false, imgui.SelectableFlags.SpanAllColumns) then
                selectedMember.name = imguiMemberName
                selectedMember.id = imguiMemberAttrs[1]
                selectedMember.rank = imguiMemberAttrs[2]
                selectedMember.afk = imguiMemberAttrs[3]
                sendLoggerMessage("Âûáðàí èãðîê: {6A5ACD}" .. selectedMember.name)
            end
            imgui.NextColumn()
            imgui.Text(u8(imguiMemberAttrs[2]))
            imgui.NextColumn()
            imgui.Text(imguiMemberAttrs[3])
            imgui.Separator()
        end
    end
    -- Îíëàéí (êîíåö)

    -- Îôôëàéí (íà÷àëî)
    if not isOnlineMode then
        imgui.Columns(4, "MainColumns", false)
        imgui.Text(fa.ICON_FA_ID_CARD .. u8" Íèêíåéì")
        imgui.NextColumn()
        imgui.Text(fa.ICON_FA_CHART_LINE .. u8" Ðàíã[*]")
        imgui.NextColumn()
        imgui.Text(fa.ICON_FA_CLOCK .. u8" Îíëàéí")
        imgui.NextColumn()
        imgui.Text(fa.ICON_FA_GLOBE .. u8" Ïîñëåäíèé âõîä")
        for imguiName, imguiAttr in pairs(offMembersPool) do
            imgui.NextColumn()
            if imgui.Selectable(imguiName, false, imgui.SelectableFlags.SpanAllColumns) then
                selectedMember.name = imguiName
                selectedMember.rank = imguiAttr[1]
                selectedMember.totalOnline = imguiAttr[2]
                selectedMember.lastOnline = imguiAttr[3]
                sendLoggerMessage("Âûáðàí èãðîê: {6A5ACD}" .. selectedMember.name)
            end
            imgui.NextColumn()
            imgui.Text(string.format("%s [%s]", rankArray[playerData.fractionType][tonumber(imguiAttr[1])], imguiAttr[1]))
            imgui.NextColumn()
            imgui.Text(string.format(u8"%s ÷àñîâ", imguiAttr[2]))
            imgui.NextColumn()
            imgui.Text(imguiAttr[3])
            imgui.Separator()
        end
    end
    imgui.Columns(1)
    imgui.EndChild()
    -- Îôôëàéí (êîíåö)

    -- Äåéñòâèÿ (íà÷àëî)
    imguiSetCursorPos(8, 208)
    imgui.BeginChild("ActionChild", imgui.ImVec2(155, 132), true)
    if imgui.ButtonClickable(selectedMember.name ~= nil, fa.ICON_FA_COPY .. u8" Êîïèðîâàòü íèê", imgui.ImVec2(140, 20)) then
        sendLoggerMessage(
            string.format("Íèê èãðîêà {6A5ACD}%s%s{FFFFFF} ñêîïèðîâàí â áóôåð îáìåíà", selectedMember.name, selectedMember.id)
        )
        setClipboardText(selectedMember.name)
    end

    if imgui.ButtonClickable(selectedMember.name ~= nil, fa.ICON_FA_CLONE .. u8" Êîïèðîâàòü RP-íèê", imgui.ImVec2(140, 20)) then
        sendLoggerMessage(
            string.format("RP-íèê èãðîêà {6A5ACD}%s%s{FFFFFF} ñêîïèðîâàí â áóôåð îáìåíà", selectedMember.name, selectedMember.id)
        )
        setClipboardText(selectedMember.name:gsub("_", " "))
    end

    createActionButton(fa.ICON_FA_PEN .. u8" Èçìåíèòü ðàíã", commandsArray.giverank[isOnlineMode], selectedMember.name ~= nil)
    createActionButton(fa.ICON_FA_USER_TIMES .. u8" Óâîëèòü", commandsArray.invite[isOnlineMode], selectedMember.name ~= nil)
    createActionButton(fa.ICON_FA_SMS .. u8" Îòïðàâèòü SMS", "t", selectedMember.name ~= nil and isOnlineMode)
    imgui.EndChild()
    -- Äåéñòâèÿ (êîíåö)

    -- Ìåòà (íà÷àëî)
    imguiSetCursorPos(8, 525)
    imgui.BeginChild("MetaInfo", imgui.ImVec2(155, 65), true)
    imgui.TextQuestion(string.format(u8"Âåðñèÿ: %s", scriptVersion), u8(scriptChangeLog))
    imgui.TextColoredRGB("{A6A6A6}Dan_Capelli")
    imgui.TextColoredRGB("{FFA500}Oleg_Lombardi")
    imgui.EndChild()
    -- Ìåòà (êîíåö)

    imgui.End()
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if id == 22 and title == "Ñòàòèñòèêà ïåðñîíàæà" and needToLogin then
        playerData.fraction = text:match("Îðãàíèçàöèÿ(.-)\n")
        playerData.rank = text:match("Ðàíã(.-)\n")
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

        if playerData.fraction ~= "Íåò" and isGovernmentFraction then
            sendLoggerMessage(string.format("Âû àâòîðèçîâàëèñü êàê {ffd700}%s {FFFFFF}({ffd700}%s{FFFFFF}){FFFFFF}!", playerData.rank, playerData.fraction))
            needToLogin = not needToLogin
        end

        if needToLogin or not isGovernmentFraction then
            sendLoggerMessage("Íå óäàëîñü àâòîðèçîâàòüñÿ!")
            return true
        end

        return false
    end

    if id == 22 and title == "Ñîñòàâ îíëàéí" and imguiMainWindowState.v then
        membersPool = {}
        for _, dialogText in pairs(split(text, "\n")) do
            if dialogText:find("(%[%d+])%s(%w+_%w+)(%A+%s%[%d+])") then
                local memberId, memberName, memberRank, memberAfk = dialogText:match("(%[%d+])%s(%w+_%w+)(%A+%s%[%d+])(.+)")

                membersPool[memberName] = {memberId, memberRank:gsub("\t", ""), memberAfk:gsub("\t", "")}
            end
        end
        return false
    end

    if id == 22 and title == "Ñîñòàâ îôôëàéí" and imguiMainWindowState.v then
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

function imgui.TextQuestion(label, description)
    imgui.Text(label)

    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
            imgui.PushTextWrapPos(600)
                imgui.TextUnformatted(description)
            imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

-- Ôóíêöèè ñòðîê

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

-- Àâòîîáíîâëåíèå ñêðèïòà

function autoUpdateScript(json_url, prefix, url)
    local dlstatus = require("moonloader").download_status
    local json = getWorkingDirectory() .. "\\"..thisScript().name.."-version.json"
    if doesFileExist(json) then os.remove(json) end
    downloadUrlToFile(json_url, json,
        function(id, status, p1, p2)
            if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                if doesFileExist(json) then
                    local f = io.open(json, "r")
                    if f then
                        local info = decodeJson(f:read("*a"))
                        updatelink = info.updateurl
                        updateversion = info.latest
                        f:close()
                        os.remove(json)
                        if updateversion ~= thisScript().version then
                            lua_thread.create(function(prefix)
                                local dlstatus = require("moonloader").download_status
                                sendLoggerMessage(string.format("Îáíàðóæåíî îáíîâëåíèå! Íîâàÿ âåðñèÿ: {ffd700}%s{FFFFFF}!", updateversion))
                                wait(250)
                                downloadUrlToFile(updatelink, thisScript().path,
                                    function(id3, status1, p13, p23)
                                        if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                                            sendLoggerMessage(string.format("Îáíîâëåíèå {ffd700}%s{FFFFFF} óñòàíîâëåíî!", updateversion))
                                            goupdatestatus = true
                                            lua_thread.create(function() wait(500) thisScript():reload() end)
                                        end
                                        if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                                            if goupdatestatus == nil then
                                                sendLoggerMessage("Íå óäàëîñü óñòàíîâèòü îáíîâëåíèå!")
                                                update = false
                                            end
                                        end
                                    end
                                )
                                end, prefix
                            )
                        else
                            update = false
                        end
                    end
                else
                    update = false
                end
            end
        end
    )
    while update ~= false do wait(100) end
end
