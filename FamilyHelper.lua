script_name("Family Helper")
script_description('This script is intended for families on the Arizona RP samp project.')
script_author("Wright Family")
script_version("0.0.0.1")

-------------------------------------------------- Библиотеки ----------------------------------------------------------
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

-------------------------------------------------- Конфигурация --------------------------------------------------------
local configDirectory = getWorkingDirectory():gsub('\\', '/') .. "/Family Helper"
local path_helper = getWorkingDirectory():gsub('\\', '/') .. "/FamilyHelper.lua"
local path_settings = configDirectory .. "/Settings.json"
function load_settings()
    if not doesDirectoryExist(configDirectory) then
        createDirectory(configDirectory)
    end
    if not doesFileExist(path_settings) then
        settings = default_settings
        print('[' .. script_tag .. '] Файл с настройками не найден, использую стандартные настройки!')
    else
        local file = io.open(path_settings, 'r')
        if file then
            local contents = file:read('*a')
            file:close()
            if #contents == 0 then
                settings = default_settings
                print('[' .. script_tag .. '] Не удалось открыть файл с настройками, использую стандартные настройки!')
            else
                local result, loaded = pcall(decodeJson, contents)
                if result then
                    settings = loaded
                    print('[' .. script_tag .. '] Настройки успешно загружены!')
                    if settings.general.version ~= thisScript().version then
                        print('[' .. script_tag .. '] Новая версия, сброс настроек!')
                        settings = default_settings
                        save_settings()
                        reload_script = true
                        thisScript():reload()
                    else
                        print('[' .. script_tag .. '] Настройки успешно загружены!')
                    end
                else
                    print('[' .. script_tag ..
                    '] Не удалось открыть файл с настройками, использую стандартные настройки!')
                end
            end
        else
            settings = default_settings
            print('[' .. script_tag .. '] Не удалось открыть файл с настройками, использую стандартные настройки!')
        end
    end
end

function save_settings()
    local file, errstr = io.open(path_settings, 'w')
    if file then
        local result, encoded = pcall(encodeJson, settings)
        file:write(result and encoded or "")
        file:close()
        print('[' .. script_tag .. '] Настройки сохранены!')
        return result
    else
        print('[' .. script_tag .. '] Не удалось сохранить настройки хелпера, ошибка: ', errstr)
        return false
    end
end

load_settings()

function check_update()
    print(script_tag .. '  Начинаю проверку на наличие обновлений...')
    sampAddChatMessage(script_tag .. '  {ffffff}Начинаю проверку на наличие обновлений...', message_color)
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
                    print(script_tag .. " Текущая установленная версия:", thisScript().version)
                    print(script_tag .. " Текущая версия в облаке:", uVer)
                    if thisScript().version ~= uVer then
                        print(script_tag .. '  Доступно обновление!')
                        sampAddChatMessage(script_tag .. '  {ffffff}Доступно обновление!', message_color)
                        need_update_helper = true
                        updateUrl = uUrl
                        updateVer = uVer
                        updateInfoText = uText
                        UpdateWindow[0] = true
                    else
                        print(script_tag .. '  Обновление не нужно!')
                        sampAddChatMessage(script_tag .. '  {ffffff}Обновление не нужно, у вас актуальная версия!',
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
                    print(script_tag .. " Текущая установленная версия:", thisScript().version)
                    print(script_tag .. " Текущая версия в облаке:", uVer)
                    if thisScript().version ~= uVer then
                        print(script_tag .. '  Доступно обновление!')
                        sampAddChatMessage(script_tag .. '  {ffffff}Доступно обновление!', message_color)
                        need_update_helper = true
                        updateUrl = uUrl
                        updateVer = uVer
                        updateInfoText = uText
                        UpdateWindow[0] = true
                    else
                        print(script_tag .. '  Обновление не нужно!')
                        sampAddChatMessage(script_tag .. '  {ffffff}Обновление не нужно, у вас актуальная версия!',
                            message_color)
                    end
                end
            end
        end)
    end
    function readJsonFile(filePath)
        if not doesFileExist(filePath) then
            print(script_tag .. " Ошибка: Файл " .. filePath .. " не существует")
            return nil
        end

        local file, err = io.open(filePath, "r")
        if not file then
            print(script_tag .. " Ошибка при открытии файла " .. filePath .. ": " .. err)
            return nil
        end

        local content = file:read("*a")
        file:close()

        local jsonData = decodeJson(content)
        if not jsonData then
            print(script_tag .. " Ошибка: Неверный формат JSON в файле " .. filePath)
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
    print(script_tag .. '  Начинаю скачивание файла в ' .. path)
    if isMonetLoader() then
        downloadToFile(url, path, function(type, pos, total_size)
            if type == "downloading" then
            elseif type == "finished" then
                if download_helper then
                    sampAddChatMessage(
                        script_tag .. '  {ffffff}Загрузка новой версии хелпера завершена успешно! Перезагрузка..',
                        message_color)
                    reload_script = true
                    thisScript():unload()
                elseif type == "error" then
                    sampAddChatMessage(script_tag .. '  {ffffff}Ошибка загрузки: ' .. pos, message_color)
                end
            end
        end)
    end
end

-- Глобальные переменные
local main_window = imgui.ImBool(false)
local commands = {}
local script_url = "https://raw.githubusercontent.com/username/repository/main/script.lua"
local settings_url = "https://raw.githubusercontent.com/username/repository/main/settings.json"
local script_path = thisScript().path
local script_version = "1.0.0" -- Текущая версия скрипта

-- Функция для проверки, является ли строка числом
local function isNumber(str)
    return tonumber(str) ~= nil
end

-- Функция автообновления с проверкой версии
function checkForUpdate()
    local response = requests.get(settings_url)
    if response.status_code == 200 then
        local settings = json.decode(response.text)
        if settings and settings.version and settings.version ~= script_version then
            sampAddChatMessage("Доступно обновление: " .. settings.version .. "! Начинаю загрузку...", -1)
            local script_response = requests.get(script_url)
            if script_response.status_code == 200 then
                local file = io.open(script_path, "w")
                if file then
                    file:write(script_response.text)
                    file:close()
                    sampAddChatMessage("Скрипт обновлен до версии " .. settings.version .. "! Перезапустите его.", -1)
                else
                    sampAddChatMessage("Ошибка при записи обновленного скрипта!", -1)
                end
            else
                sampAddChatMessage("Ошибка загрузки обновленного скрипта!", -1)
            end
        else
            sampAddChatMessage("У вас уже установлена последняя версия: " .. script_version, -1)
        end
    else
        sampAddChatMessage("Ошибка проверки обновлений!", -1)
    end
end

-- Функция для регистрации команд из массива
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

-- Функция, выполняемая при загрузке скрипта
function main()
    while not isSampAvailable() do wait(100) end
    sampAddChatMessage("SAMP Lua Script v" .. script_version .. " загружен!", -1)

    -- Регистрация команд
    registerCommands({
        { name = "test", description = "Открывает главное окно", args = toggleMainWindow },
        {
            name = "hello",
            description = "Приветствие",
            args = function(name)
                sampAddChatMessage("Привет, " .. (name or "гость") .. "!", -1)
            end
        },
        { name = "update", description = "Обновление скрипта", args = checkForUpdate }
    })

    -- Основной цикл
    while true do
        wait(0)
        imgui.Process = main_window.v
    end
end

-- Функция обработки команд
function toggleMainWindow()
    main_window.v = not main_window.v
end

-- Обработчик событий SA-MP
function sampev.onServerMessage(color, text)
    if text:find("Пример текста") then
        sampAddChatMessage("Обнаружено сообщение: " .. text, -1)
    end
end

-- Интерфейс с использованием imgui
imgui.OnDrawFrame = function()
    if main_window.v then
        imgui.SetNextWindowSize(vec2(300, 200), imgui.Cond.FirstUseEver)
        imgui.Begin("Test Window", main_window)
        imgui.Text("Привет, это окно ImGui!")
        if imgui.Button("Закрыть") then
            main_window.v = false
        end
        imgui.End()
    end
end
