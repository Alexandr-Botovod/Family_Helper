script_name("Family Helper")
script_description('This script is intended for families on the Arizona RP samp project.')
script_author("Wright Family")
script_version("0.0.0.2")

-------------------------------------------------- Библиотеки ----------------------------------------------------------
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
-------------------------------------------------- Переменные ---------------------------------------------------------------------
local main_window = imgui.new.bool()
local infoFam = imgui.new.bool(false)
local updateInformation = imgui.new.bool()
local UpdateWindow = imgui.new.bool()
local message_color = 0x87CEEB
local message_color_hex = '{87CEEB}'
local script_tag = '[Family Helper]'
local commands = {}
local sizeX, sizeY = getScreenResolution()
-- Глобальные переменные
debug = { [0] = false }
debug_messages = {} -- Хранение сообщений
-------------------------------------------------- Конфигурация --------------------------------------------------------
local configDirectory = getWorkingDirectory():gsub('\\', '/') .. "/Family Helper"
local path_helper = getWorkingDirectory():gsub('\\', '/') .. "/FamilyHelper.lua"
local path_settings = configDirectory .. "/Настройки.json"
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
    print(script_tag .. " Настройки загружены!")
end

function save_settings()
    local file, errstr = io.open(path_settings, 'w')
    if file then
        local result, encoded = pcall(encodeJson, settings)
        file:write(result and encoded or "")
        file:close()
        print(script_tag .. ' Настройки сохранены!')
        return result
    else
        print(script_tag .. ' Не удалось сохранить настройки хелпера, ошибка: ', errstr)
        return false
    end
end

load_settings()

local path_commands = configDirectory .. "/Команды.json"
-- Функция сохранения команд в JSON
local function saveCommands()
    local file = io.open(path_commands, 'w')
    if file then
        file:write(encodeJson(commands))
        file:close()
    else
        print("[Family Helper] Ошибка сохранения команд!")
    end
end

-- Функция загрузки команд из JSON
local function loadCommands()
    if doesFileExist(path_commands) then
        local file = io.open(path_commands, 'r')
        if file then
            local contents = file:read('*a')
            file:close()
            local success, data = pcall(decodeJson, contents)
            if success then
                commands = data
                print("[Family Helper] Команды загружены!")
            else
                print("[Family Helper] Ошибка загрузки команд!")
            end
        end
    else
        print("[Family Helper] Файл команд не найден, создаю новый.")
        saveCommands()
    end
end

-- Функция регистрации команды
function registerCommand(name, description, handler)
    commands[name] = { description = description }
    sampRegisterChatCommand(name, handler)
    saveCommands()
end

-- Функция отображения списка команд
function showCommands()
    print("[Family Helper] Доступные команды:")
    for name, data in pairs(commands) do
        print("/" .. name .. " - " .. data.description)
    end
end

-- Загрузка команд при старте
loadCommands()

function check_update()
    print(script_tag .. ' Начинаю проверку на наличие обновлений...')
    sampAddChatMessage(script_tag .. ' {ffffff}Начинаю проверку на наличие обновлений...', message_color)

    local path = configDirectory .. "/Обновления.json"
    os.remove(path)

    local url =
    'https://raw.githubusercontent.com/Alexandr-Botovod/Family_Helper/refs/heads/main/Family%20Helper/Обновления.json'

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

        print(script_tag .. " JSON-контент: ", content) -- Отладка

        local jsonData = decodeJson(content)
        if not jsonData then
            print(script_tag .. " Ошибка: Неверный формат JSON в файле " .. filePath)
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
        print(script_tag .. " Ошибка: updateInfo пустой или поврежден!")
        return
    end

    local uVer = updateInfo.current_version
    local uUrl = updateInfo.update_url
    local uText = updateInfo.update_info

    print(script_tag .. " Текущая установленная версия:", thisScript().version)
    print(script_tag .. " Текущая версия в облаке:", uVer)

    if thisScript().version ~= uVer then
        print(script_tag .. ' Доступно обновление!')
        sampAddChatMessage(script_tag .. ' {ffffff}Доступно обновление!', message_color)
        need_update_helper = true
        updateUrl = uUrl
        updateVer = uVer
        updateInfoText = uText
        UpdateWindow[0] = true
    else
        print(script_tag .. ' Обновление не нужно!')
        sampAddChatMessage(script_tag .. ' {ffffff}Обновление не нужно, у вас актуальная версия!', message_color)
    end
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
    print(script_tag .. ' Начинаю скачивание в ' .. path)
    downloadToFile(url, path, function(type, pos, total_size)
        if type == "finished" then
            print(script_tag .. ' Загрузка завершена! Перезагрузка...')
            reload_script = true
            thisScript():unload()
        elseif type == "error" then
            sampAddChatMessage(script_tag .. ' Ошибка загрузки: ' .. pos, message_color)
        end
    end)
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

function welcome_message()
    if not sampIsLocalPlayerSpawned() then
        sampAddChatMessage(script_tag .. '  {ffffff}Инициализация хелпера прошла успешно!', message_color)
        sampAddChatMessage(
            script_tag .. '  {ffffff}Для полной загрузки хелпера сначало заспавнитесь (войдите на сервер)', message_color)
        repeat wait(0) until sampIsLocalPlayerSpawned()
    end
    sampAddChatMessage(script_tag .. '  {ffffff}Загрузка хелпера прошла успешно!', message_color)
    show_cef_notify('info', script_tag, "Загрузка хелпера прошла успешно!", 3000)
    if hotkey_no_errors and settings.general.bind_mainmenu and settings.general.use_binds then
        sampAddChatMessage(
            script_tag .. '  {ffffff}Чтоб открыть меню хелпера нажмите ' ..
            message_color_hex ..
            getNameKeysFrom(settings.general.bind_mainmenu) ..
            ' {ffffff}или введите команду ' .. message_color_hex .. '/fh',
            message_color)
    else
        sampAddChatMessage(
            script_tag .. '  {ffffff}Чтоб открыть меню хелпера введите команду ' .. message_color_hex .. '/fh',
            message_color)
    end
end

function show_cef_notify(type, title, text, time)
    --[[
	1) type - тип уведомления ( 'info' / 'error' / 'success' / 'halloween' / '' )
	2) title - текст заголовка/названия уведомления ( указывайте текст )
	3) text - текст содержимого уведомления ( указывайте текст )
	4) time - время отображения уведомления в миллисекундах ( указывайте любое число ).
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
    local x_position = (window_width - text_width) * 0.5 -- Вычисляем центр по горизонтали

    imgui.SetCursorPosX(x_position)                      -- Устанавливаем позицию курсора
    imgui.Text(text)                                     -- Отображаем текст
end

imgui.OnFrame(
    function() return UpdateWindow[0] end,
    function(player)
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin(fa.CIRCLE_INFO .. u8 " Оповещение##need_update_helper", _,
            imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
        imgui.CenterText('У вас сейчас установлена версия хелпера ' .. (tostring(thisScript().version)) .. ".")
        imgui.CenterText('В базе данных найдена версия хелпера - ' .. (updateVer) .. ".")
        imgui.CenterText('Рекомендуется обновиться, дабы иметь весь актуальный функционал!')
        imgui.Separator()
        imgui.CenterText('Что нового в версии ' .. (updateVer) .. ':')
        imgui.Text(updateInfoText)
        imgui.Separator()
        if imgui.Button(fa.CIRCLE_XMARK .. ' Не обновлять ', imgui.ImVec2(250 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
            UpdateWindow[0] = false
        end
        imgui.SameLine()
        if imgui.Button(fa.DOWNLOAD .. ' Загрузить новую версию', imgui.ImVec2(250 * MONET_DPI_SCALE, 25 * MONET_DPI_SCALE)) then
            download_helper = true
            downloadFileFromUrlToPath(updateUrl, path_helper)
            UpdateWindow[0] = false
        end
        imgui.End()
    end
)

-- Обработчик событий SA-MP
function sampev.onServerMessage(color, text)
    if text:find("Пример текста") then
        sampAddChatMessage("Обнаружено сообщение: " .. text, -1)
    end
end

function sampev.onShowDialog(dialogid, style, title, button1, button2, text)
    if dialogid == 27085 then
        -- Ищем название семьи и ID семьи
        local familyName, familyId = text:match("Название семьи: {308EB0}(.-) %[fam id: (%d+)]{FFFFFF}")
        local familyReputation = text:match("Репутация семьи: {308EB0}(%d+) очк.{FFFFFF}")
        -- Извлекаем сумму из текста
        local familyMoney = text:match("Денег в бюджете семьи: {.-}$(%d[%d%.]*){.-}")

        -- Если сумма найдена, форматируем её
        if familyMoney then
            -- Убираем точки для корректной обработки числа
            familyMoney = familyMoney:gsub("%.", "")

            -- Добавляем разделители тысяч
            local familyBalance = familyMoney:reverse():gsub("(%d%d%d)", "%1,"):reverse()

            -- Убираем возможную лишнюю запятую в начале строки
            if familyBalance:sub(1, 1) == "," then
                familyBalance = familyBalance:sub(2)
            end

            -- Добавляем знак доллара в начало
            familyBalance = "$" .. familyBalance

            -- Если оба значения найдены
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

-- Функция для вызова debug
function debug_message(text)
    table.insert(debug_messages, "[DEBUG]: " .. text)
    debug[0] = true -- Открытие окна
end

-- imgui окно для debug
imgui.OnFrame(
    function() return debug[0] end,
    function()
        imgui.SetNextWindowSize(imgui.ImVec2(500, 300), imgui.Cond.FirstUseEver)
        imgui.Begin("Debug Console")

        -- Вывод всех сообщений
        for _, msg in ipairs(debug_messages) do
            imgui.Text(u8(msg))
        end

        -- Кнопка закрытия
        if imgui.Button(u8("Закрыть")) then
            debug[0] = false
        end

        imgui.End()
    end
)

imgui.OnFrame(
    function() return main_window[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        -- Устанавливаем размер окна
        imgui.SetNextWindowSize(imgui.ImVec2(840, 448), imgui.Cond.Always)
        -- Убираем стандартный заголовок
        local window_flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar

        imgui.SetNextWindowSize(imgui.ImVec2(840, 448), imgui.Cond.Always)
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.10, 0.10, 0.10, 1.00)) -- Непрозрачный фон (черно-серый цвет)
        imgui.Begin(u8 "Главное", main_window, window_flags)

        -- Кастомный заголовок
        imgui.SetCursorPos(imgui.ImVec2(5, 5)) -- Ставим кнопку слева
        if imgui.Button("X", imgui.ImVec2(25, 25)) then
            main_window[0] = false
        end

        imgui.SameLine()
        imgui.SetCursorPosX(40) -- Отодвигаем текст заголовка после крестика
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), u8 "Главное меню")

        -- Основное содержимое окна
        imgui.Spacing()
        imgui.Separator()

        -- Устанавливаем стиль
        local style = imgui.GetStyle()
        style.FrameRounding = 8.0               -- Скругление кнопок
        style.WindowRounding = 10.0             -- Скругление окна
        style.ItemSpacing = imgui.ImVec2(2, 2)  -- Расстояние между элементами
        style.FramePadding = imgui.ImVec2(8, 6) -- Внутренние отступы у кнопок

        -- Цвета для кнопок
        local buttonColorNormal = imgui.ImVec4(0.20, 0.45, 0.80, 1.00)
        local buttonColorHovered = imgui.ImVec4(0.314, 0.588, 0.968, 1.00)
        local buttonColorActive = imgui.ImVec4(0.15, 0.40, 0.75, 1.00)

        -- Разделение интерфейса: Боковая панель и основная область
        imgui.BeginChild("Sidebar", imgui.ImVec2(170, 0), true)

        -- Получаем размеры окна
        local windowWidth = imgui.GetWindowSize().x

        -- Получаем ширину текста
        local text = u8 "FamilyHelper"
        local textWidth = imgui.CalcTextSize(text).x

        -- Вычисляем позицию X для центрирования
        local textX = (windowWidth - textWidth) * 0.5

        -- Устанавливаем курсор в центр
        imgui.SetCursorPosX(textX)

        -- Заголовок боковой панели
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), text)
        imgui.Separator()
        imgui.Spacing()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5) -- Добавляем отступ между текстом и кнопками

        -- Боковые кнопки
        local buttons = {
            { "Информация о семье", "Выведена информация о семье", function()
                infoFam[0] = true
                main_window[0] = false
            end },
            { "Настройки", "Открыто окно настроек!", function() print('Бруксы пидарасы!') end },
            { "Команды", "Показать список команд!", function() print('Бруксы хуесосы!') end },
            { "Обновления", "Проверка на обновления!", function()
                updateInformation[0] = true; infoFam[0] = false; main_window[0] = false
            end },
            { "Функции", "Настройки функций!", function() print("Бруксы членососы!") end },
            { "О скрипте", "Информация о скрипте!", function() print("Бруксы ЧМОшники!") end }
        }

        for _, btn in ipairs(buttons) do
            if imgui.Button(u8(btn[1]), imgui.ImVec2(150, 30)) then
                if btn[3] then
                    btn[3]()                       -- Вызов функции, если она есть
                else
                    sampAddChatMessage(btn[2], -1) -- Иначе просто вывести сообщение
                end
            end
            imgui.GetStyle().Colors[imgui.Col.Button] = buttonColorNormal
            imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = buttonColorHovered
            imgui.GetStyle().Colors[imgui.Col.ButtonActive] = buttonColorActive
            imgui.Spacing()
        end

        imgui.EndChild()

        -- Разделение панелей
        imgui.SameLine()

        -- Основная область
        imgui.BeginChild("MainPanel", imgui.ImVec2(0, 0), true)
        --centerText(u8 "Здравствуй! Уважаемый пользователь данного скрипта")
        imgui.Text(u8 "Добро пожаловать в Family Helper!")
        imgui.Spacing()
        imgui.Text(u8
            "Ваш незаменимый помощник для управления семейными делами в мире Arizona RP!")
        imgui.Spacing()
        imgui.Text(u8 "Мы создали этот скрипт, чтобы вы могли сосредоточиться на важном, а не тратить время на рутину.")
        imgui.Spacing()
        imgui.Text(u8 "Благодаря удобным инструментам, управлять семейным бизнесом стало проще, чем когда-либо.")
        imgui.Spacing()
        imgui.Text(u8 "С помощью Family Helper вы сможете:")
        imgui.Spacing()
        imgui.Text(u8
            "- Управлять членами семьи: Просматривайте и редактируйте список участников,")
        imgui.Spacing()
        imgui.Text(u8 "следите за их активностью и статусом.")
        imgui.Spacing()
        imgui.Text(u8 "- Координировать действия: Отправляйте важные уведомления и задания,")
        imgui.Spacing()
        imgui.Text(u8 "обеспечивая слаженную работу.")
        imgui.Spacing()
        imgui.Text(u8 "- Мониторить финансы: Легко отслеживайте доходы и расходы семьи,")
        imgui.Spacing()
        imgui.Text(u8 "анализируйте финансовые потоки.")
        imgui.Spacing()
        imgui.Text(u8 "- Мгновенный доступ к информации: Всё, что нужно для управления семьей,")
        imgui.Spacing()
        imgui.Text(u8 "теперь под рукой.")
        imgui.Spacing()
        imgui.Text(u8
            "Family Helper — это простота, надежность и скорость. Используйте все возможности,")
        imgui.Spacing()
        imgui.Text(u8 "чтобы создать свою идеальную семью и достичь успеха в этом большом мире!")

        imgui.EndChild()
        imgui.End()
    end
)

imgui.OnFrame(
    function() return infoFam[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        -- Устанавливаем размер окна
        imgui.SetNextWindowSize(imgui.ImVec2(840, 448), imgui.Cond.Always)
        local window_flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.10, 0.10, 0.10, 1.00))

        imgui.Begin(u8 "Информация о семье", infoFam, window_flags)

        -- Кастомный заголовок
        imgui.SetCursorPos(imgui.ImVec2(5, 5)) -- Ставим кнопку слева
        if imgui.Button("X", imgui.ImVec2(25, 25)) then
            infoFam[0] = false
        end

        imgui.SameLine()
        imgui.SetCursorPosX(40) -- Отодвигаем текст заголовка после крестика
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), u8 "Главное меню")

        -- Основное содержимое окна
        imgui.Spacing()
        imgui.Separator()

        -- Устанавливаем стиль
        local style = imgui.GetStyle()
        style.FrameRounding = 8.0               -- Скругление кнопок
        style.WindowRounding = 10.0             -- Скругление окна
        style.ItemSpacing = imgui.ImVec2(2, 2)  -- Расстояние между элементами
        style.FramePadding = imgui.ImVec2(8, 6) -- Внутренние отступы у кнопок

        -- Цвета для кнопок
        local buttonColorNormal = imgui.ImVec4(0.20, 0.45, 0.80, 1.00)
        local buttonColorHovered = imgui.ImVec4(0.314, 0.588, 0.968, 1.00)
        local buttonColorActive = imgui.ImVec4(0.15, 0.40, 0.75, 1.00)

        -- Разделение интерфейса: Боковая панель и основная область
        imgui.BeginChild("Sidebar", imgui.ImVec2(170, 0), true)

        -- Получаем размеры окна
        local windowWidth = imgui.GetWindowSize().x

        -- Получаем ширину текста
        local text = u8 "FamilyHelper"
        local textWidth = imgui.CalcTextSize(text).x

        -- Вычисляем позицию X для центрирования
        local textX = (windowWidth - textWidth) * 0.5

        -- Устанавливаем курсор в центр
        imgui.SetCursorPosX(textX)

        -- Заголовок боковой панели
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), text)
        imgui.Separator()
        imgui.Spacing()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5) -- Добавляем отступ между текстом и кнопками

        -- Боковые кнопки
        local buttons = {
            { "Главная", "Стартовая информация", function()
                main_window[0] = true; infoFam[0] = false
            end },
            { "Настройки", "Открыто окно настроек!", function() print("Открыто окно настроек!") end },
            { "Команды", "Показать список команд!", function() print("Показать список команд!") end },
            { "Обновления", "Проверка на обновления!", function() print("Проверка на обновления!") end },
            { "Функции", "Настройки функций!", function() print("Настройки функций!") end },
            { "О скрипте", "Информация о скрипте!", function() print("Информация о скрипте!") end }
        }

        for _, btn in ipairs(buttons) do
            if imgui.Button(u8(btn[1]), imgui.ImVec2(150, 30)) then
                if btn[3] then
                    btn[3]()                       -- Вызов функции, если она есть
                else
                    sampAddChatMessage(btn[2], -1) -- Иначе просто вывести сообщение
                end
            end
            imgui.GetStyle().Colors[imgui.Col.Button] = buttonColorNormal
            imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = buttonColorHovered
            imgui.GetStyle().Colors[imgui.Col.ButtonActive] = buttonColorActive
            imgui.Spacing()
        end

        imgui.EndChild()

        -- Разделение панелей
        imgui.SameLine()

        -- Основная область
        imgui.BeginChild("infoFamPanel", imgui.ImVec2(0, 0), true)

        -- Отображение информации о семье
        imgui.Text(u8("Название семьи: " .. settings.fam.name))
        imgui.Spacing()
        imgui.Text(u8("Баланс: " .. settings.fam.balance))
        imgui.Spacing()
        imgui.Text(u8("Репутация: " .. settings.fam.reputation))

        if imgui.Button(u8("Обновить информацию"), imgui.ImVec2(200, 25)) then
            debug_message("Кнопка работает!")
        end

        imgui.EndChild()
    end
)

imgui.OnFrame(
    function() return updateInformation[0] end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.Always, imgui.ImVec2(0.5, 0.5))
        -- Устанавливаем размер окна
        imgui.SetNextWindowSize(imgui.ImVec2(840, 448), imgui.Cond.Always)
        local window_flags = imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar
        imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.10, 0.10, 0.10, 1.00))

        imgui.Begin(u8 "Информация о семье", updateInformation, window_flags)

        -- Кастомный заголовок
        imgui.SetCursorPos(imgui.ImVec2(5, 5)) -- Ставим кнопку слева
        if imgui.Button("X", imgui.ImVec2(25, 25)) then
            updateInformation[0] = false
        end

        imgui.SameLine()
        imgui.SetCursorPosX(40) -- Отодвигаем текст заголовка после крестика
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), u8 "Главное меню")

        -- Основное содержимое окна
        imgui.Spacing()
        imgui.Separator()

        -- Устанавливаем стиль
        local style = imgui.GetStyle()
        style.FrameRounding = 8.0               -- Скругление кнопок
        style.WindowRounding = 10.0             -- Скругление окна
        style.ItemSpacing = imgui.ImVec2(2, 2)  -- Расстояние между элементами
        style.FramePadding = imgui.ImVec2(8, 6) -- Внутренние отступы у кнопок

        -- Цвета для кнопок
        local buttonColorNormal = imgui.ImVec4(0.20, 0.45, 0.80, 1.00)
        local buttonColorHovered = imgui.ImVec4(0.314, 0.588, 0.968, 1.00)
        local buttonColorActive = imgui.ImVec4(0.15, 0.40, 0.75, 1.00)

        -- Разделение интерфейса: Боковая панель и основная область
        imgui.BeginChild("Sidebar", imgui.ImVec2(170, 0), true)

        -- Получаем размеры окна
        local windowWidth = imgui.GetWindowSize().x

        -- Получаем ширину текста
        local text = u8 "FamilyHelper"
        local textWidth = imgui.CalcTextSize(text).x

        -- Вычисляем позицию X для центрирования
        local textX = (windowWidth - textWidth) * 0.5

        -- Устанавливаем курсор в центр
        imgui.SetCursorPosX(textX)

        -- Заголовок боковой панели
        imgui.TextColored(imgui.ImVec4(1.00, 1.00, 1.00, 1.00), text)
        imgui.Separator()
        imgui.Spacing()
        imgui.SetCursorPosY(imgui.GetCursorPosY() + 5) -- Добавляем отступ между текстом и кнопками

        -- Боковые кнопки
        local buttons = {
            { "Главная", "Стартовая информация", function()
                main_window[0] = true; infoFam[0] = false
            end },
            { "Настройки", "Открыто окно настроек!", function() print("Открыто окно настроек!") end },
            { "Команды", "Показать список команд!", function() print("Показать список команд!") end },
            { "Обновления", "Проверка на обновления!", function() print("Проверка на обновления!") end },
            { "Функции", "Настройки функций!", function() print("Настройки функций!") end },
            { "О скрипте", "Информация о скрипте!", function() print("Информация о скрипте!") end }
        }

        for _, btn in ipairs(buttons) do
            if imgui.Button(u8(btn[1]), imgui.ImVec2(150, 30)) then
                if btn[3] then
                    btn[3]()                       -- Вызов функции, если она есть
                else
                    sampAddChatMessage(btn[2], -1) -- Иначе просто вывести сообщение
                end
            end
            imgui.GetStyle().Colors[imgui.Col.Button] = buttonColorNormal
            imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = buttonColorHovered
            imgui.GetStyle().Colors[imgui.Col.ButtonActive] = buttonColorActive
            imgui.Spacing()
        end

        imgui.EndChild()

        -- Разделение панелей
        imgui.SameLine()

        if imgui.SmallButton(u8 'Проверить обновления') then
            local result, check = pcall(check_update)
            if not result then
                sampAddChatMessage(
                    script_tag .. '  {ffffff}Произошла ошибка при попытке проверить наличие обновлений!',
                    message_color)
            end
        end

        print(updateInfo)
        if updateInfo then
            if imgui.BeginChild('##update', imgui.ImVec2(688 * MONET_DPI_SCALE, 372 * MONET_DPI_SCALE), true) then
                centerText(fa.STAR .. u8 'История обновлений')
                imgui.Separator()

                local indent = string.rep(" ", 115) -- Создает отступ из 10 пробелов
                -- Первый спойлер
                if imgui.CollapsingHeader(fa.TAG .. " " .. updateInfo.news[0].title .. indent .. updateInfo.news[0].date) then
                    local text = table.concat(updateInfo.news[0].text, "\n")
                    imgui.Text(text)
                end
                imgui.EndChild()
            end
        else
            centerText(fa.MONEY_CHECK_DOLLAR .. u8 ' Обновления')
            centerText(u8('Список обновлений не загружен!'))
            imgui.EndChild()
        end
        imgui.EndTabItem() -- Этот вызов должен быть один раз в конце
    end
)

function welcome_message()
    if not sampIsLocalPlayerSpawned() then
        sampAddChatMessage(script_tag .. '  {ffffff}Инициализация хелпера прошла успешно!', message_color)
        sampAddChatMessage(
            script_tag .. '  {ffffff}Для полной загрузки хелпера сначало заспавнитесь (войдите на сервер)', message_color)
        repeat wait(0) until sampIsLocalPlayerSpawned()
    end
    sampAddChatMessage(script_tag .. '  {ffffff}Загрузка хелпера прошла успешно!', message_color)
    show_cef_notify('info', script_tag, "Загрузка хелпера прошла успешно!", 3000)
    sampAddChatMessage(
        script_tag .. '  {ffffff}Чтоб открыть меню хелпера введите команду ' .. message_color_hex .. '/fh',
        message_color)
end

-- Функция, выполняемая при загрузке скрипта
function main()
    while not isSampAvailable() do
        wait(100)
    end
    welcome_message()

    -- Зарегистрировать команды только один раз
    registerCommand("commands", "Показать список доступных команд", showCommands)
    registerCommand("fh", "Открыть главное меню", function() main_window[0] = not main_window[0] end)

    -- Основной цикл с минимальной задержкой
    while true do
        wait(0)
    end
end
