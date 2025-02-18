script_name("Family Helper")
script_description('This script is intended for families on the Arizona RP samp project.')
script_author("Wright Family")
script_version("0.0.0.1")

-------------------------------------------------- ���������� ----------------------------------------------------------
require('lib.moonloader')
local sampev = require 'lib.samp.events'
local imgui = require 'imgui'
local encoding = require 'encoding'
local requests = require 'requests'
local json = require 'json'
encoding.default = 'CP1251'
local u8 = encoding.UTF8
function isMonetLoader() return MONET_VERSION ~= nil end

-------------------------------------------------- JSON SETTINGS -------------------------------------------------------
local settings = {}
local default_settings = {
    general = {
        version = thisScript().version,
    }
}
-------------------------------------------------- ���������� ---------------------------------------------------------------------
local main_window = imgui.ImBool(false) -- ������� ���������� ���������� ����
local UpdateWindow = imgui.new.bool()
local message_color = 0x87CEEB
local message_color_hex = '{87CEEB}'
local script_tag = '[Family Helper]'
local download_helper = false
local commands = {}
-------------------------------------------------- ������������ --------------------------------------------------------
local configDirectory = getWorkingDirectory():gsub('\\', '/') .. "/Family Helper"
local path_helper = getWorkingDirectory():gsub('\\', '/') .. "/FamilyHelper.lua"
local path_settings = configDirectory .. "/���������.json"
function load_settings()
    if not doesDirectoryExist(configDirectory) then
        createDirectory(configDirectory)
    end
    if not doesFileExist(path_settings) then
        settings = default_settings
        print(script_tag .. ' ���� � ����������� �� ������, ��������� ����������� ���������!')
    else
        local file = io.open(path_settings, 'r')
        if file then
            local contents = file:read('*a')
            file:close()
            if #contents == 0 then
                settings = default_settings
                print(script_tag .. ' �� ������� ������� ���� � �����������, ��������� ����������� ���������!')
            else
                local result, loaded = pcall(decodeJson, contents)
                if result then
                    settings = loaded
                    print(script_tag .. ' ��������� ������� ���������!')
                    if settings.general.version ~= thisScript().version then
                        print(script_tag .. ' ����� ������, ����� ��������!')
                        settings = default_settings
                        save_settings()
                        reload_script = true
                        thisScript():reload()
                    else
                        print(script_tag .. ' ��������� ������� ���������!')
                    end
                else
                    print(script_tag .. ' �� ������� ������� ���� � �����������, ��������� ����������� ���������!')
                end
            end
        else
            settings = default_settings
            print(script_tag .. ' �� ������� ������� ���� � �����������, ��������� ����������� ���������!')
        end
    end
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

function check_update()
    print(script_tag .. ' ������� �������� �� ������� ����������...')
    sampAddChatMessage(script_tag .. ' {ffffff}������� �������� �� ������� ����������...', message_color)
    local path = configDirectory .. "/����������.json"
    os.remove(path)
    local url =
    'https://raw.githubusercontent.com/Alexandr-Botovod/Prison_Helper/refs/heads/main/PrisonHelper/Update_info.json'
    if isMonetLoader() then
        downloadToFile(url, path, function(type, pos, total_size)
            if type == "finished" then
                local updateInfo = readJsonFile(path)
                if updateInfo then
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
                        sampAddChatMessage(script_tag .. ' {ffffff}���������� �� �����, � ��� ���������� ������!',
                            message_color)
                    end
                end
            end
        end)
    else
        downloadUrlToFile(url, path, function(id, status)
            if status == 6 then -- ENDDOWNLOADDATA
                updateInfo = readJsonFile(path)
                if updateInfo then
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
                        print(script_tag .. '   ���������� �� �����!')
                        sampAddChatMessage(script_tag .. ' {ffffff}���������� �� �����, � ��� ���������� ������!',
                            message_color)
                    end
                end
            end
        end)
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
    print(script_tag .. '   ������� ���������� ����� � ' .. path)
    if isMonetLoader() then
        downloadToFile(url, path, function(type, pos, total_size)
            if type == "downloading" then
            elseif type == "finished" then
                if download_helper then
                    sampAddChatMessage(
                        script_tag .. '   {ffffff}�������� ����� ������ ������� ��������� �������! ������������..',
                        message_color)
                    reload_script = true
                    thisScript():unload()
                elseif type == "error" then
                    sampAddChatMessage(script_tag .. '   {ffffff}������ ��������: ' .. pos, message_color)
                end
            end
        end)
    end
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

imgui.OnFrame(
    function() return UpdateWindow[0] end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(fa.CIRCLE_INFO .. u8 " ����������##need_update_helper", _,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        imgui.CenterText(u8 '� ��� ������ ����������� ������ ������� ' .. u8(tostring(thisScript().version)) .. ".")
        imgui.CenterText(u8 '� ���� ������ ������� ������ ������� - ' .. u8(updateVer) .. ".")
        imgui.CenterText(u8 '������������� ����������, ���� ����� ���� ���������� ����������!')
        imgui.Separator()
        imgui.CenterText(u8('��� ������ � ������ ') .. u8(updateVer) .. ':')
        imgui.Text(updateInfoText)
        imgui.Separator()
        if imgui.Button(fa.CIRCLE_XMARK .. u8 ' �� ��������� ', imgui.ImVec2(250 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
            UpdateWindow[0] = false
        end
        imgui.SameLine()
        if imgui.Button(fa.DOWNLOAD .. u8 ' ��������� ����� ������', imgui.ImVec2(250 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
            download_helper = true
            downloadFileFromUrlToPath(updateUrl, path_helper)
            UpdateWindow[0] = false
        end
        imgui.End()
    end
)

-- �������, ����������� ��� �������� �������
function main()
    while not isSampAvailable() do wait(100) end
    welcome_message()

    -- ����������� ������
    registerCommands({
        { name = "test", description = "��������� ������� ����", args = toggleMainWindow },
        {
            name = "hello",
            description = "�����������",
            args = function(name)
                sampAddChatMessage("������, " .. (name or "�����") .. "!", -1)
            end
        },
        { name = "update", description = "���������� �������", args = check_update },
    })

    -- �������� ����
    while true do
        wait(0)
        imgui.Process = main_window.v
    end
end

-- ������� ��������� ������
function toggleMainWindow()
    main_window.v = not main_window.v
end

-- ���������� ������� SA-MP
function sampev.onServerMessage(color, text)
    if text:find("������ ������") then
        sampAddChatMessage("���������� ���������: " .. text, -1)
    end
end

-- ��������� � �������������� imgui
imgui.OnDrawFrame = function()
    if main_window.v then
        imgui.SetNextWindowSize(imgui.ImVec2(300, 200), imgui.Cond.FirstUseEver)
        imgui.Begin(u8 "Test Window", main_window)
        imgui.Text(u8 "������, ��� ���� ImGui!")
        if imgui.Button(u8 "�������") then
            main_window.v = false
        end
        imgui.End()
    end
end
