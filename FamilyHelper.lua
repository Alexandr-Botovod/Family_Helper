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

-------------------------------------------------- JSON SETTINGS -------------------------------------------------------
local settings = {}
local default_settings = {
    general = {
        version = thisScript().version,
    }
}

local message_color = 0x87CEEB
local message_color_hex = '{87CEEB}'
local script_tag = '[Family Helper]'

-------------------------------------------------- ������������ --------------------------------------------------------
local configDirectory = getWorkingDirectory():gsub('\\', '/') .. "/Family Helper"
local path_helper = getWorkingDirectory():gsub('\\', '/') .. "/FamilyHelper.lua"
local path_settings = configDirectory .. "/Settings.json"
function load_settings()
    if not doesDirectoryExist(configDirectory) then
        createDirectory(configDirectory)
    end
    if not doesFileExist(path_settings) then
        settings = default_settings
        print('[' .. script_tag .. '] ���� � ����������� �� ������, ��������� ����������� ���������!')
    else
        local file = io.open(path_settings, 'r')
        if file then
            local contents = file:read('*a')
            file:close()
            if #contents == 0 then
                settings = default_settings
                print('[' .. script_tag .. '] �� ������� ������� ���� � �����������, ��������� ����������� ���������!')
            else
                local result, loaded = pcall(decodeJson, contents)
                if result then
                    settings = loaded
                    print('[' .. script_tag .. '] ��������� ������� ���������!')
                    if settings.general.version ~= thisScript().version then
                        print('[' .. script_tag .. '] ����� ������, ����� ��������!')
                        settings = default_settings
                        save_settings()
                        reload_script = true
                        thisScript():reload()
                    else
                        print('[' .. script_tag .. '] ��������� ������� ���������!')
                    end
                else
                    print('[' .. script_tag ..
                    '] �� ������� ������� ���� � �����������, ��������� ����������� ���������!')
                end
            end
        else
            settings = default_settings
            print('[' .. script_tag .. '] �� ������� ������� ���� � �����������, ��������� ����������� ���������!')
        end
    end
end

function save_settings()
    local file, errstr = io.open(path_settings, 'w')
    if file then
        local result, encoded = pcall(encodeJson, settings)
        file:write(result and encoded or "")
        file:close()
        print('[' .. script_tag .. '] ��������� ���������!')
        return result
    else
        print('[' .. script_tag .. '] �� ������� ��������� ��������� �������, ������: ', errstr)
        return false
    end
end

load_settings()

function check_update()
    print(script_tag .. '  ������� �������� �� ������� ����������...')
    sampAddChatMessage(script_tag .. '  {ffffff}������� �������� �� ������� ����������...', message_color)
    local path = configDirectory .. "/Update_Info.json"
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
                        print(script_tag .. '  �������� ����������!')
                        sampAddChatMessage(script_tag .. '  {ffffff}�������� ����������!', message_color)
                        need_update_helper = true
                        updateUrl = uUrl
                        updateVer = uVer
                        updateInfoText = uText
                        UpdateWindow[0] = true
                    else
                        print(script_tag .. '  ���������� �� �����!')
                        sampAddChatMessage(script_tag .. '  {ffffff}���������� �� �����, � ��� ���������� ������!',
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
                        print(script_tag .. '  �������� ����������!')
                        sampAddChatMessage(script_tag .. '  {ffffff}�������� ����������!', message_color)
                        need_update_helper = true
                        updateUrl = uUrl
                        updateVer = uVer
                        updateInfoText = uText
                        UpdateWindow[0] = true
                    else
                        print(script_tag .. '  ���������� �� �����!')
                        sampAddChatMessage(script_tag .. '  {ffffff}���������� �� �����, � ��� ���������� ������!',
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
    print(script_tag .. '  ������� ���������� ����� � ' .. path)
    if isMonetLoader() then
        downloadToFile(url, path, function(type, pos, total_size)
            if type == "downloading" then
            elseif type == "finished" then
                if download_helper then
                    sampAddChatMessage(
                        script_tag .. '  {ffffff}�������� ����� ������ ������� ��������� �������! ������������..',
                        message_color)
                    reload_script = true
                    thisScript():unload()
                elseif type == "error" then
                    sampAddChatMessage(script_tag .. '  {ffffff}������ ��������: ' .. pos, message_color)
                end
            end
        end)
    end
end

-- ���������� ����������
local main_window = imgui.ImBool(false)
local commands = {}
local script_url = "https://raw.githubusercontent.com/username/repository/main/script.lua"
local settings_url = "https://raw.githubusercontent.com/username/repository/main/settings.json"
local script_path = thisScript().path
local script_version = "1.0.0" -- ������� ������ �������

-- ������� ��� ��������, �������� �� ������ ������
local function isNumber(str)
    return tonumber(str) ~= nil
end

-- ������� �������������� � ��������� ������
function checkForUpdate()
    local response = requests.get(settings_url)
    if response.status_code == 200 then
        local settings = json.decode(response.text)
        if settings and settings.version and settings.version ~= script_version then
            sampAddChatMessage("�������� ����������: " .. settings.version .. "! ������� ��������...", -1)
            local script_response = requests.get(script_url)
            if script_response.status_code == 200 then
                local file = io.open(script_path, "w")
                if file then
                    file:write(script_response.text)
                    file:close()
                    sampAddChatMessage("������ �������� �� ������ " .. settings.version .. "! ������������� ���.", -1)
                else
                    sampAddChatMessage("������ ��� ������ ������������ �������!", -1)
                end
            else
                sampAddChatMessage("������ �������� ������������ �������!", -1)
            end
        else
            sampAddChatMessage("� ��� ��� ����������� ��������� ������: " .. script_version, -1)
        end
    else
        sampAddChatMessage("������ �������� ����������!", -1)
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

-- �������, ����������� ��� �������� �������
function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("SAMP Lua Script v" .. script_version .. " ��������!", -1)

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
        { name = "update", description = "���������� �������", args = checkForUpdate }
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
        imgui.SetNextWindowSize(vec2(300, 200), imgui.Cond.FirstUseEver)
        imgui.Begin("Test Window", main_window)
        imgui.Text("������, ��� ���� ImGui!")
        if imgui.Button("�������") then
            main_window.v = false
        end
        imgui.End()
    end
end
