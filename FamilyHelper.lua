script_name("Family Helper")
script_description('This script is intended for families on the Arizona RP samp project.')
script_author("Wright Family")
script_version("0.0.0.2")

-------------------------------------------------- ���������� ----------------------------------------------------------
require('lib.moonloader')
local sampev = require 'lib.samp.events'
local imgui = require 'mimgui'
local encoding = require 'encoding'
local requests = require 'requests'
local fa = require 'fAwesome6_solid'
local json = require 'json'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
function isMonetLoader() return MONET_VERSION ~= nil end

-------------------------------------------------- JSON SETTINGS -------------------------------------------------------
local settings = {}
local default_settings = {
    general = {
        version = thisScript().version,
    },
    fam = {
        name = "Test",
        Id = "0",
        reputation = "0",
        balance = "0"
    }
}
-------------------------------------------------- ���������� ---------------------------------------------------------------------
local main_window = imgui.new.bool()
local infoFam = imgui.new.bool(false)
local updateInformation = imgui.new.bool()
local UpdateWindow = imgui.new.bool()
local message_color = 0x87CEEB
local message_color_hex = '{87CEEB}'
local script_tag = '[Family Helper]'
local commands = {}
local sizeX, sizeY = getScreenResolution()
-- ���������� ����������
debug = { [0] = false }
debug_messages = {} -- �������� ���������
-------------------------------------------------- ������������ --------------------------------------------------------
local configDirectory = getWorkingDirectory():gsub('\\', '/') .. "/Family Helper"
local path_helper = getWorkingDirectory():gsub('\\', '/') .. "/FamilyHelper.lua"
local path_settings = configDirectory .. "/���������.json"
function load_settings()
    local settings_file = io.open(path_settings, 'r')
    if settings_file then
        local contents = settings_file:read('*a')
        settings_file:close()
        if #contents > 0 then
            local success, data = pcall(decodeJson, contents)
            if success then
                settings = data
                if settings.general.version ~= thisScript().version then
                    settings = default_settings
                    save_settings()
                    reload_script = true
                    thisScript():reload()
                end
            else
                settings = default_settings
            end
        else
            settings = default_settings
        end
    else
        settings = default_settings
    end
    print(script_tag .. " ��������� ���������!")
end

function save_settings()
    local file, errstr = io.open(path_settings, 'w')
    if file then
        local result, encoded = pcall(encodeJson, settings)
        file:write(result and encoded or "")
        file:close()
        print(script_tag .. ' ��������� ���������!')
        return result
    else
        print(script_tag .. ' �� ������� ��������� ��������� �������, ������: ', errstr)
        return false
    end
end

load_settings()

local path_commands = configDirectory .. "/�������.json"
-- ������� ���������� ������ � JSON
local function saveCommands()
    local file = io.open(path_commands, 'w')
    if file then
        file:write(encodeJson(commands))
        file:close()
    else
        print("[Family Helper] ������ ���������� ������!")
    end
end

-- ������� �������� ������ �� JSON
local function loadCommands()
    if doesFileExist(path_commands) then
        local file = io.open(path_commands, 'r')
        if file then
            local contents = file:read('*a')
            file:close()
            local success, data = pcall(decodeJson, contents)
            if success then
                commands = data
                print("[Family Helper] ������� ���������!")
            else
                print("[Family Helper] ������ �������� ������!")
            end
        end
    else
        print("[Family Helper] ���� ������ �� ������, ������ �����.")
        saveCommands()
    end
end

-- ������� ����������� �������
function registerCommand(name, description, handler)
    commands[name] = { description = description }
    sampRegisterChatCommand(name, handler)
    saveCommands()
end

-- ������� ����������� ������ ������
function showCommands()
    print("[Family Helper] ��������� �������:")
    for name, data in pairs(commands) do
        print("/" .. name .. " - " .. data.description)
    end
end

-- �������� ������ ��� ������
loadCommands()

function check_update()
    print(script_tag .. ' ������� �������� �� ������� ����������...')
    sampAddChatMessage(script_tag .. ' {ffffff}������� �������� �� ������� ����������...', message_color)

    local path = configDirectory .. "/����������.json"
    os.remove(path)

    local url =
    'https://raw.githubusercontent.com/Alexandr-Botovod/Family_Helper/refs/heads/main/Family%20Helper/����������.json'

    function readJsonFile(filePath)
        if not doesFileExist(filePath) then
            print(script_tag .. " ������: ���� " .. filePath .. " �� ����������")
            return nil
        end

        local file, err = io.open(filePath, "r")
        if not file then
            print(script_tag .. " ������ ��� �������� ����� " .. filePath .. ": " .. err)
            return nil
        end

        local content = file:read("*a")
        file:close()

        print(script_tag .. " JSON-�������: ", content) -- �������

        local jsonData = decodeJson(content)
        if not jsonData then
            print(script_tag .. " ������: �������� ������ JSON � ����� " .. filePath)
            return nil
        end

        return jsonData
    end

    if isMonetLoader() then
        downloadToFile(url, path, function(type, pos, total_size)
            if type == "finished" then
                updateInfo = readJsonFile(path)
                if updateInfo then
                    processUpdateInfo(updateInfo)
                end
            end
        end)
    else
        downloadUrlToFile(url, path, function(id, status)
            if status == 6 then -- ENDDOWNLOADDATA
                updateInfo = readJsonFile(path)
                if updateInfo then
                    processUpdateInfo(updateInfo)
                end
            end
        end)
    end
end

function processUpdateInfo(updateInfo)
    if not updateInfo or not updateInfo.current_version then
        print(script_tag .. " ������: updateInfo ������ ��� ���������!")
        return
    end

    local uVer = updateInfo.current_version
    local uUrl = updateInfo.update_url
    local uText = updateInfo.update_info

    print(script_tag .. " ������� ������������� ������:", thisScript().version)
    print(script_tag .. " ������� ������ � ������:", uVer)

    if thisScript().version ~= uVer then
        print(script_tag .. ' �������� ����������!')
        sampAddChatMessage(script_tag .. ' {ffffff}�������� ����������!', message_color)
        need_update_helper = true
        updateUrl = uUrl
        updateVer = uVer
        updateInfoText = uText
        UpdateWindow[0] = true
    else
        print(script_tag .. ' ���������� �� �����!')
        sampAddChatMessage(script_tag .. ' {ffffff}���������� �� �����, � ��� ���������� ������!', message_color)
    end
end

function readJsonFile(filePath)
    if not doesFileExist(filePath) then
        print(script_tag .. " ������: ���� " .. filePath .. " �� ����������")
        return nil
    end

    local file, err = io.open(filePath, "r")
    if not file then
        print(script_tag .. " ������ ��� �������� ����� " .. filePath .. ": " .. err)
        return nil
    end

    local content = file:read("*a")
    file:close()

    local jsonData = decodeJson(content)
    if not jsonData then
        print(script_tag .. " ������: �������� ������ JSON � ����� " .. filePath)
        return nil
    end

    return jsonData
end

function downloadToFile(url, path, callback, progressInterval)
    callback = callback or function() end
    progressInterval = progressInterval or 0.1

    local effil = require("effil")
    local progressChannel = effil.channel(0)

    local runner = effil.thread(function(url, path)
        local http = require("socket.http")
        local ltn = require("ltn12")

        local r, c, h = http.request({
            method = "HEAD",
            url = url,
        })

        if c ~= 200 then
            return false, c
        end
        local total_size = h["content-length"]

        local f = io.open(path, "wb")
        if not f then
            return false, "failed to open file"
        end
        local success, res, status_code = pcall(http.request, {
            method = "GET",
            url = url,
            sink = function(chunk, err)
                local clock = os.clock()
                if chunk and not lastProgress or (clock - lastProgress) >= progressInterval then
                    progressChannel:push("downloading", f:seek("end"), total_size)
                    lastProgress = os.clock()
                elseif err then
                    progressChannel:push("error", err)
                end

                return ltn.sink.file(f)(chunk, err)
            end,
        })

        if not success then
            return false, res
        end

        if not res then
            return false, status_code
        end

        return true, total_size
    end)
    local thread = runner(url, path)

    local function checkStatus()
        local tstatus = thread:status()
        if tstatus == "failed" or tstatus == "completed" then
            local result, value = thread:get()

            if result then
                callback("finished", value)
            else
                callback("error", value)
            end

            return true
        end
    end

    lua_thread.create(function()
        if checkStatus() then
            return
        end

        while thread:status() == "running" do
            if progressChannel:size() > 0 then
                local type, pos, total_size = progressChannel:pop()
                callback(type, pos, total_size)
            end
            wait(0)
        end

        checkStatus()
    end)
end

function downloadFileFromUrlToPath(url, path)
    print(script_tag .. ' ������� ���������� � ' .. path)
    downloadToFile(url, path, function(type, pos, total_size)
        if type == "finished" then
            print(script_tag .. ' �������� ���������! ������������...')
            reload_script = true
            thisScript():unload()
        elseif type == "error" then
            sampAddChatMessage(script_tag .. ' ������ ��������: ' .. pos, message_color)
        end
    end)
end

-- ������� ��� ����������� ������ �� �������
function registerCommands(commandList)
    for _, cmd in ipairs(commandList) do
        commands[cmd.name] = cmd
        sampRegisterChatCommand(cmd.name, function(param)
            local args = {}
            for word in param:gmatch("%S+") do
                if isNumber(word) then
                    table.insert(args, tonumber(word))
                else
                    table.insert(args, word)
                end
            end
            cmd.args(table.unpack(args))
        end)
    end
end

function welcome_message()
    if not sampIsLocalPlayerSpawned() then
        sampAddChatMessage(script_tag .. '  {ffffff}������������� ������� ������ �������!', message_color)
        sampAddChatMessage(
            script_tag .. '  {ffffff}��� ������ �������� ������� ������� ������������ (������� �� ������)', message_color)
        repeat wait(0) until sampIsLocalPlayerSpawned()
    end
    sampAddChatMessage(script_tag .. '  {ffffff}�������� ������� ������ �������!', message_color)
    show_cef_notify('info', script_tag, "�������� ������� ������ �������!", 3000)
    if hotkey_no_errors and settings.general.bind_mainmenu and settings.general.use_binds then
        sampAddChatMessage(
            script_tag .. '  {ffffff}���� ������� ���� ������� ������� ' ..
            message_color_hex ..
            getNameKeysFrom(settings.general.bind_mainmenu) ..
            ' {ffffff}��� ������� ������� ' .. message_color_hex .. '/fh',
            message_color)
    else
        sampAddChatMessage(
            script_tag .. '  {ffffff}���� ������� ���� ������� ������� ������� ' .. message_color_hex .. '/fh',
            message_color)
    end
end

function show_cef_notify(type, title, text, time)
    --[[
	1) type - ��� ����������� ( 'info' / 'error' / 'success' / 'halloween' / '' )
	2) title - ����� ���������/�������� ����������� ( ���������� ����� )
	3) text - ����� ����������� ����������� ( ���������� ����� )
	4) time - ����� ����������� ����������� � ������������� ( ���������� ����� ����� ).
	]]
    local str = ('window.executeEvent(\'event.notify.initialize\', \'["%s", "%s", "%s", "%s"]\');'):format(type, title,
        text, time)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 17)
    raknetBitStreamWriteInt32(bs, 0)
    raknetBitStreamWriteInt32(bs, #str)
    raknetBitStreamWriteString(bs, str)
    raknetEmulPacketReceiveBitStream(220, bs)
    raknetDeleteBitStream(bs)
end

function centerText(text)
    local window_width = imgui.GetWindowWidth()
    local text_width = imgui.CalcTextSize(text).x
    local x_position = (window_width - text_width) * 0.5 -- ��������� ����� �� �����������

    imgui.SetCursorPosX(x_position)                      -- ������������� ������� �������
    imgui.Text(text)                                     -- ���������� �����
end

imgui.OnFrame(
    function() return UpdateWindow[0] end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(fa.CIRCLE_INFO .. u8 " ����������##need_update_helper", _,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        imgui.CenterText('� ��� ������ ����������� ������ ������� ' .. (tostring(thisScript().version)) .. ".")
        imgui.CenterText('� ���� ������ ������� ������ ������� - ' .. (updateVer) .. ".")
        imgui.CenterText('������������� ����������, ���� ����� ���� ���������� ����������!')
        imgui.Separator()
        imgui.CenterText('��� ������ � ������ ' .. (updateVer) .. ':')
        imgui.Text(updateInfoText)
        imgui.Separator()
        if imgui.Button(fa.CIRCLE_XMARK .. ' �� ��������� ', imgui.ImVec2(250 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
            UpdateWindow[0] = false
        end
        imgui.SameLine()
        if imgui.Button(fa.DOWNLOAD .. ' ��������� ����� ������', imgui.ImVec2(250 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
            download_helper = true
            downloadFileFromUrlToPath(updateUrl, path_helper)
            UpdateWindow[0] = false
        end
        imgui.End()
    end
)

-- ���������� ������� SA-MP
function sampev.onServerMessage(color, text)
    if text:find("������ ������") then
        sampAddChatMessage("���������� ���������: " .. text, -1)
    end
end

function sampev.onShowDialog(dialogid, style, title, button1, button2, text)
    if dialogid == 27085 then
        -- ���� �������� ����� � ID �����
        local familyName, familyId = text:match("�������� �����: {308EB0}(.-) %[fam id: (%d+)]{FFFFFF}")
        local familyReputation = text:match("��������� �����: {308EB0}(%d+) ���.{FFFFFF}")
        -- ��������� ����� �� ������
        local familyMoney = text:match("����� � ������� �����: {.-}$(%d[%d%.]*){.-}")

        -- ���� ����� �������, ����������� �
        if familyMoney then
            -- ������� ����� ��� ���������� ��������� �����
            familyMoney = familyMoney:gsub("%.", "")

            -- ��������� ����������� �����
            local familyBalance = familyMoney:reverse():gsub("(%d%d%d)", "%1,"):reverse()

            -- ������� ��������� ������ ������� � ������ ������
            if familyBalance:sub(1, 1) == "," then
                familyBalance = familyBalance:sub(2)
            end

            -- ��������� ���� ������� � ������
            familyBalance = "$" .. familyBalance

            -- ���� ��� �������� �������
            if familyName and familyId then
                settings.fam.name = familyName
                settings.fam.Id = familyId
                save_settings()
            end
            if familyReputation then
                settings.fam.reputation = familyReputation
                save_settings()
            end
            if familyBalance then
                settings.fam.balance = familyBalance
                save_settings()
            end
        end
    end
end

-- ������� ��� ������ debug
function debug_message(text)
    table.insert(debug_messages, "[DEBUG]: " .. text)
    debug[0] = true -- �������� ����
end

-- imgui ���� ��� debug
imgui.OnFrame(
    function() return debug[0] end,
    function()
        imgui.SetNextWindowSize(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver)
        imgui.Begin("Debug Console")

        -- ����� ���� ���������
        for _, msg in ipairs(debug_messages) do
            imgui.Text(u8(msg))
        end

        -- ������ ��������
        if imgui.Button(u8("�������")) then
            debug[0] = false
        end

        imgui.End()
    end
)

imgui.OnFrame(
    function() return main_window[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        -- ������������� ������ ����
        imgui.SetNextWindowSize(imgui.ImVec2(840, 448), imgui.Cond.Always)
        -- ������� ����������� ���������
        local window_flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar

        imgui.SetNextWindowSize(imgui.ImVec2(840, 448), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.10, 0.10, 0.10, 1.00)) -- ������������ ��� (�����-����� ����)
        imgui.Begin(u8 "�������", main_window, window_flags)

        -- ��������� ���������
        imgui.SetCursorPos(imgui.ImVec2(5, 5)) -- ������ ������ �����
        if imgui.Button("X", imgui.ImVec2(25, 25)) then
            main_window[0] = false
        end

        imgui.SameLine()
        imgui.SetCursorPosX(40) -- ���������� ����� ��������� ����� ��������
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), u8 "������� ����")

        -- �������� ���������� ����
        imgui.Spacing()
        imgui.Separator()

        -- ������������� �����
        local style = imgui.GetStyle()
        style.FrameRounding = 8.0               -- ���������� ������
        style.WindowRounding = 10.0             -- ���������� ����
        style.ItemSpacing = imgui.ImVec2(2, 2)  -- ���������� ����� ����������
        style.FramePadding = imgui.ImVec2(8, 6) -- ���������� ������� � ������

        -- ����� ��� ������
        local buttonColorNormal = imgui.ImVec4(0.20, 0.45, 0.80, 1.00)
        local buttonColorHovered = imgui.ImVec4(0.314, 0.588, 0.968, 1.00)
        local buttonColorActive = imgui.ImVec4(0.15, 0.40, 0.75, 1.00)

        -- ���������� ����������: ������� ������ � �������� �������
        imgui.BeginChild("Sidebar", imgui.ImVec2(170, 0), true)

        -- �������� ������� ����
        local windowWidth = imgui.GetWindowSize().x

        -- �������� ������ ������
        local text = u8 "FamilyHelper"
        local textWidth = imgui.CalcTextSize(text).x

        -- ��������� ������� X ��� �������������
        local textX = (windowWidth - textWidth) * 0.5

        -- ������������� ������ � �����
        imgui.SetCursorPosX(textX)

        -- ��������� ������� ������
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), text)
        imgui.Separator()
        imgui.Spacing()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5) -- ��������� ������ ����� ������� � ��������

        -- ������� ������
        local buttons = {
            { "���������� � �����", "�������� ���������� � �����", function()
                infoFam[0] = true
                main_window[0] = false
            end },
            { "���������", "������� ���� ��������!", function() print('������ ��������!') end },
            { "�������", "�������� ������ ������!", function() print('������ �������!') end },
            { "����������", "�������� �� ����������!", function()
                updateInformation[0] = true; infoFam[0] = false; main_window[0] = false
            end },
            { "�������", "��������� �������!", function() print("������ ���������!") end },
            { "� �������", "���������� � �������!", function() print("������ ��������!") end }
        }

        for _, btn in ipairs(buttons) do
            if imgui.Button(u8(btn[1]), imgui.ImVec2(150, 30)) then
                if btn[3] then
                    btn[3]()                       -- ����� �������, ���� ��� ����
                else
                    sampAddChatMessage(btn[2], -1) -- ����� ������ ������� ���������
                end
            end
            imgui.GetStyle().Colors[imgui.Col.Button] = buttonColorNormal
            imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = buttonColorHovered
            imgui.GetStyle().Colors[imgui.Col.ButtonActive] = buttonColorActive
            imgui.Spacing()
        end

        imgui.EndChild()

        -- ���������� �������
        imgui.SameLine()

        -- �������� �������
        imgui.BeginChild("MainPanel", imgui.ImVec2(0, 0), true)
        --centerText(u8 "����������! ��������� ������������ ������� �������")
        imgui.Text(u8 "����� ���������� � Family Helper!")
        imgui.Spacing()
        imgui.Text(u8
            "��� ����������� �������� ��� ���������� ��������� ������ � ���� Arizona RP!")
        imgui.Spacing()
        imgui.Text(u8 "�� ������� ���� ������, ����� �� ����� ��������������� �� ������, � �� ������� ����� �� ������.")
        imgui.Spacing()
        imgui.Text(u8 "��������� ������� ������������, ��������� �������� �������� ����� �����, ��� �����-����.")
        imgui.Spacing()
        imgui.Text(u8 "� ������� Family Helper �� �������:")
        imgui.Spacing()
        imgui.Text(u8
            "- ��������� ������� �����: �������������� � ������������ ������ ����������,")
        imgui.Spacing()
        imgui.Text(u8 "������� �� �� ����������� � ��������.")
        imgui.Spacing()
        imgui.Text(u8 "- �������������� ��������: ����������� ������ ����������� � �������,")
        imgui.Spacing()
        imgui.Text(u8 "����������� ��������� ������.")
        imgui.Spacing()
        imgui.Text(u8 "- ���������� �������: ����� ������������ ������ � ������� �����,")
        imgui.Spacing()
        imgui.Text(u8 "������������ ���������� ������.")
        imgui.Spacing()
        imgui.Text(u8 "- ���������� ������ � ����������: ��, ��� ����� ��� ���������� ������,")
        imgui.Spacing()
        imgui.Text(u8 "������ ��� �����.")
        imgui.Spacing()
        imgui.Text(u8
            "Family Helper � ��� ��������, ���������� � ��������. ����������� ��� �����������,")
        imgui.Spacing()
        imgui.Text(u8 "����� ������� ���� ��������� ����� � ������� ������ � ���� ������� ����!")

        imgui.EndChild()
        imgui.End()
    end
)

imgui.OnFrame(
    function() return infoFam[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        -- ������������� ������ ����
        imgui.SetNextWindowSize(imgui.ImVec2(840, 448), imgui.Cond.Always)
        local window_flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.10, 0.10, 0.10, 1.00))

        imgui.Begin(u8 "���������� � �����", infoFam, window_flags)

        -- ��������� ���������
        imgui.SetCursorPos(imgui.ImVec2(5, 5)) -- ������ ������ �����
        if imgui.Button("X", imgui.ImVec2(25, 25)) then
            infoFam[0] = false
        end

        imgui.SameLine()
        imgui.SetCursorPosX(40) -- ���������� ����� ��������� ����� ��������
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), u8 "������� ����")

        -- �������� ���������� ����
        imgui.Spacing()
        imgui.Separator()

        -- ������������� �����
        local style = imgui.GetStyle()
        style.FrameRounding = 8.0               -- ���������� ������
        style.WindowRounding = 10.0             -- ���������� ����
        style.ItemSpacing = imgui.ImVec2(2, 2)  -- ���������� ����� ����������
        style.FramePadding = imgui.ImVec2(8, 6) -- ���������� ������� � ������

        -- ����� ��� ������
        local buttonColorNormal = imgui.ImVec4(0.20, 0.45, 0.80, 1.00)
        local buttonColorHovered = imgui.ImVec4(0.314, 0.588, 0.968, 1.00)
        local buttonColorActive = imgui.ImVec4(0.15, 0.40, 0.75, 1.00)

        -- ���������� ����������: ������� ������ � �������� �������
        imgui.BeginChild("Sidebar", imgui.ImVec2(170, 0), true)

        -- �������� ������� ����
        local windowWidth = imgui.GetWindowSize().x

        -- �������� ������ ������
        local text = u8 "FamilyHelper"
        local textWidth = imgui.CalcTextSize(text).x

        -- ��������� ������� X ��� �������������
        local textX = (windowWidth - textWidth) * 0.5

        -- ������������� ������ � �����
        imgui.SetCursorPosX(textX)

        -- ��������� ������� ������
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), text)
        imgui.Separator()
        imgui.Spacing()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5) -- ��������� ������ ����� ������� � ��������

        -- ������� ������
        local buttons = {
            { "�������", "��������� ����������", function()
                main_window[0] = true; infoFam[0] = false
            end },
            { "���������", "������� ���� ��������!", function() print("������� ���� ��������!") end },
            { "�������", "�������� ������ ������!", function() print("�������� ������ ������!") end },
            { "����������", "�������� �� ����������!", function() print("�������� �� ����������!") end },
            { "�������", "��������� �������!", function() print("��������� �������!") end },
            { "� �������", "���������� � �������!", function() print("���������� � �������!") end }
        }

        for _, btn in ipairs(buttons) do
            if imgui.Button(u8(btn[1]), imgui.ImVec2(150, 30)) then
                if btn[3] then
                    btn[3]()                       -- ����� �������, ���� ��� ����
                else
                    sampAddChatMessage(btn[2], -1) -- ����� ������ ������� ���������
                end
            end
            imgui.GetStyle().Colors[imgui.Col.Button] = buttonColorNormal
            imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = buttonColorHovered
            imgui.GetStyle().Colors[imgui.Col.ButtonActive] = buttonColorActive
            imgui.Spacing()
        end

        imgui.EndChild()

        -- ���������� �������
        imgui.SameLine()

        -- �������� �������
        imgui.BeginChild("infoFamPanel", imgui.ImVec2(0, 0), true)

        -- ����������� ���������� � �����
        imgui.Text(u8("�������� �����: " .. settings.fam.name))
        imgui.Spacing()
        imgui.Text(u8("������: " .. settings.fam.balance))
        imgui.Spacing()
        imgui.Text(u8("���������: " .. settings.fam.reputation))

        if imgui.Button(u8("�������� ����������"), imgui.ImVec2(200, 25)) then
            debug_message("������ ��������!")
        end

        imgui.EndChild()
    end
)

imgui.OnFrame(
    function() return updateInformation[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        -- ������������� ������ ����
        imgui.SetNextWindowSize(imgui.ImVec2(840, 448), imgui.Cond.Always)
        local window_flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.10, 0.10, 0.10, 1.00))

        imgui.Begin(u8 "���������� � �����", updateInformation, window_flags)

        -- ��������� ���������
        imgui.SetCursorPos(imgui.ImVec2(5, 5)) -- ������ ������ �����
        if imgui.Button("X", imgui.ImVec2(25, 25)) then
            updateInformation[0] = false
        end

        imgui.SameLine()
        imgui.SetCursorPosX(40) -- ���������� ����� ��������� ����� ��������
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), u8 "������� ����")

        -- �������� ���������� ����
        imgui.Spacing()
        imgui.Separator()

        -- ������������� �����
        local style = imgui.GetStyle()
        style.FrameRounding = 8.0               -- ���������� ������
        style.WindowRounding = 10.0             -- ���������� ����
        style.ItemSpacing = imgui.ImVec2(2, 2)  -- ���������� ����� ����������
        style.FramePadding = imgui.ImVec2(8, 6) -- ���������� ������� � ������

        -- ����� ��� ������
        local buttonColorNormal = imgui.ImVec4(0.20, 0.45, 0.80, 1.00)
        local buttonColorHovered = imgui.ImVec4(0.314, 0.588, 0.968, 1.00)
        local buttonColorActive = imgui.ImVec4(0.15, 0.40, 0.75, 1.00)

        -- ���������� ����������: ������� ������ � �������� �������
        imgui.BeginChild("Sidebar", imgui.ImVec2(170, 0), true)

        -- �������� ������� ����
        local windowWidth = imgui.GetWindowSize().x

        -- �������� ������ ������
        local text = u8 "FamilyHelper"
        local textWidth = imgui.CalcTextSize(text).x

        -- ��������� ������� X ��� �������������
        local textX = (windowWidth - textWidth) * 0.5

        -- ������������� ������ � �����
        imgui.SetCursorPosX(textX)

        -- ��������� ������� ������
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), text)
        imgui.Separator()
        imgui.Spacing()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5) -- ��������� ������ ����� ������� � ��������

        -- ������� ������
        local buttons = {
            { "�������", "��������� ����������", function()
                main_window[0] = true; infoFam[0] = false
            end },
            { "���������", "������� ���� ��������!", function() print("������� ���� ��������!") end },
            { "�������", "�������� ������ ������!", function() print("�������� ������ ������!") end },
            { "����������", "�������� �� ����������!", function() print("�������� �� ����������!") end },
            { "�������", "��������� �������!", function() print("��������� �������!") end },
            { "� �������", "���������� � �������!", function() print("���������� � �������!") end }
        }

        for _, btn in ipairs(buttons) do
            if imgui.Button(u8(btn[1]), imgui.ImVec2(150, 30)) then
                if btn[3] then
                    btn[3]()                       -- ����� �������, ���� ��� ����
                else
                    sampAddChatMessage(btn[2], -1) -- ����� ������ ������� ���������
                end
            end
            imgui.GetStyle().Colors[imgui.Col.Button] = buttonColorNormal
            imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = buttonColorHovered
            imgui.GetStyle().Colors[imgui.Col.ButtonActive] = buttonColorActive
            imgui.Spacing()
        end

        imgui.EndChild()

        -- ���������� �������
        imgui.SameLine()

        if imgui.SmallButton(u8 '��������� ����������') then
            local result, check = pcall(check_update)
            if not result then
                sampAddChatMessage(
                    script_tag .. '  {ffffff}��������� ������ ��� ������� ��������� ������� ����������!',
                    message_color)
            end
        end

        print(updateInfo)
        if updateInfo then
            if imgui.BeginChild('##update', imgui.ImVec2(688 * MONET_DPI_SCALE, 372 * MONET_DPI_SCALE), true) then
                centerText(fa.STAR .. u8 '������� ����������')
                imgui.Separator()

                local indent = string.rep(" ", 115) -- ������� ������ �� 10 ��������
                -- ������ �������
                if imgui.CollapsingHeader(fa.TAG .. " " .. updateInfo.news[0].title .. indent .. updateInfo.news[0].date) then
                    local text = table.concat(updateInfo.news[0].text, "\n")
                    imgui.Text(text)
                end
                imgui.EndChild()
            end
        else
            centerText(fa.MONEY_CHECK_DOLLAR .. u8 ' ����������')
            centerText(u8('������ ���������� �� ��������!'))
            imgui.EndChild()
        end
        imgui.EndTabItem() -- ���� ����� ������ ���� ���� ��� � �����
    end
)

function welcome_message()
    if not sampIsLocalPlayerSpawned() then
        sampAddChatMessage(script_tag .. '  {ffffff}������������� ������� ������ �������!', message_color)
        sampAddChatMessage(
            script_tag .. '  {ffffff}��� ������ �������� ������� ������� ������������ (������� �� ������)', message_color)
        repeat wait(0) until sampIsLocalPlayerSpawned()
    end
    sampAddChatMessage(script_tag .. '  {ffffff}�������� ������� ������ �������!', message_color)
    show_cef_notify('info', script_tag, "�������� ������� ������ �������!", 3000)
    sampAddChatMessage(
        script_tag .. '  {ffffff}���� ������� ���� ������� ������� ������� ' .. message_color_hex .. '/fh',
        message_color)
end

-- �������, ����������� ��� �������� �������
function main()
    while not isSampAvailable() do
        wait(100)
    end
    welcome_message()

    -- ���������������� ������� ������ ���� ���
    registerCommand("commands", "�������� ������ ��������� ������", showCommands)
    registerCommand("fh", "������� ������� ����", function() main_window[0] = not main_window[0] end)

    -- �������� ���� � ����������� ���������
    while true do
        wait(0)
    end
end
