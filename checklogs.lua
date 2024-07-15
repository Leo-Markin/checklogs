script_name("checklogs")
script_version("7")
script_author("Неадекват, ЧСВ, Оскорбление DIS, Слив инфы DIS, хейтер DIS, Слив состава (Выход запрещён), Разжигатель вражды между USAF и DIS, (СЛИТ), Расформировал DIS, Разрушитель иделогии DIS или просто Leo_Markin")
script_description("Проверяет ЧС SFA, реестр наказаний SFA, логи SFA")

require "lib.moonloader"
local encoding = require "encoding"
encoding.default = "CP1251"
u8 = encoding.UTF8
local json = require "json"
local effil = require 'effil'

function asyncHttpRequest(method, url, args, resolve, reject)
   local request_thread = effil.thread(function (method, url, args)
      local requests = require 'requests_script'
      local result, response = pcall(requests.request, method, url, args)
      if result then
         response.json, response.xml = nil, nil
         return true, response
      else
         return false, response
      end
   end)(method, url, args)
   if not resolve then resolve = function() end end
   if not reject then reject = function() end end
   lua_thread.create(function()
      local runner = request_thread
      while true do
         local status, err = runner:status()
         if not err then
            if status == 'completed' then
               local result, response = runner:get()
               if result then
                  resolve(response)
               else
                  reject(response)
               end
               return
            elseif status == 'canceled' then
               return reject(status)
            end
         else
            return reject(err)
         end
         wait(0)
      end
   end)
end

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    sampRegisterChatCommand("getbl", cmd_getbl)
    sampRegisterChatCommand("getpun", cmd_getpun)
    sampRegisterChatCommand("getrank", cmd_getrank)
    sampRegisterChatCommand("invite", cmd_invite)
    sampRegisterChatCommand("checkcontract", cmd_checkcontract)
    sampRegisterChatCommand("contracts", cmd_contracts)
    sampRegisterChatCommand("acccontract", cmd_acccontract)
    sampAddChatMessage(string.format("checklogs by Leo_Markin v7 loaded."), 0x00FA9A)
    wait(-1)
end

function cmd_getbl(arg)
    if #arg == 0 then
        sampAddChatMessage('Введите: /getbl [id / nick]', 0x00FA9A)
        return
    end
    local id = tonumber(arg)
    if id ~= nil then
        if sampIsPlayerConnected(id) then
            arg = sampGetPlayerNickname(id)
        else
            sampAddChatMessage('Игрок оффлайн!', 0x00FA9A)
            return
        end
    end
    sampAddChatMessage('Загрузка данных...', 0x00FA9A)
    asyncHttpRequest('GET', 'https://docs.google.com/spreadsheets/d/1yBkOkDHGgaYqZDW9hY-qG5C5Zr8S3VmEEoFFByazGZ0/gviz/tq', nil,
        function(response)
            local jsonData = json.decode(response.text:gmatch('google%.visualization%.Query.setResponse%((.+)%);')())
            local violators = {}
            for _, row in ipairs(jsonData.table.rows) do
                table.insert(violators, {
                    author = row.c[1] and row.c[1].v or nil,
                    violator = row.c[2] and row.c[2].v or nil,
                    reason = row.c[3] and row.c[3].v or nil,
                    date = row.c[4] and row.c[4].f or nil,
                    degree = row.c[5] and row.c[5].v or nil
                })
            end
            for i = #violators, 1, -1 do
                if violators[i].violator ~= nil then
                    if violators[i].violator:match("^%s*(.-)%s*$") == arg then
                        sampAddChatMessage("--------------------------------------------------------------------------------------------", 0x00FA9A)
                        sampAddChatMessage(string.format("{00FA9A}Ник:{ffffff} %s | {00FA9A}Внёс:{ffffff} %s | {00FA9A}Дата: {ffffff}%s", violators[i].violator, violators[i].author, violators[i].date), 0x00FA9A)
                        sampAddChatMessage(string.format("{00FA9A}Степень: {ffffff}%s | {00FA9A}Причина:{ffffff} %s", violators[i].degree, u8:decode(violators[i].reason)), 0x00FA9A)
                        sampAddChatMessage("--------------------------------------------------------------------------------------------", 0x00FA9A)
                        return
                    end
                end
            end
            sampAddChatMessage(string.format("{ffffff}%s {00FA9A}в чёрном списке не обнаружен!", arg), 0x00FA9A)
        end,
        function(err)
            print(err)
        end
    )
end

function cmd_getpun(arg)
    if #arg == 0 then
        sampAddChatMessage('Введите: /getpun [id / nick]', 0x00FA9A)
        return
    end
    local id = tonumber(arg)
    if id ~= nil then
        if sampIsPlayerConnected(id) then
            arg = sampGetPlayerNickname(id)
        else
            sampAddChatMessage('Игрок оффлайн!', 0x00FA9A)
            return
        end
    end
    sampAddChatMessage('Загрузка данных...', 0x00FA9A)
    asyncHttpRequest('GET', 'https://docs.google.com/spreadsheets/d/1qwloa7iVyTXneomQ1vazz8GZM9se08b2uyLNaerQLxA/gviz/tq', nil,
        function(response)
            local jsonData = json.decode(response.text:gmatch('google%.visualization%.Query.setResponse%((.+)%);')())
            local violators = {}
            for _, row in ipairs(jsonData.table.rows) do
                if row.c[1] ~= nil then
                    if u8:decode(row.c[1].v) ~= "Отказано" then
                        table.insert(violators, {
                            author = row.c[2] and row.c[2].v or nil,
                            violator = row.c[3] and row.c[3].v or nil,
                            reason = row.c[6] and row.c[6].v or nil,
                            sanction = row.c[7] and row.c[7].v or nil,
                            date = row.c[4] and row.c[4].f or nil,
                            description = row.c[9] and row.c[9].v or nil
                        })
                    end
                end
            end
            local flag = true
            for i = 1, #violators, 1 do
                if violators[i].violator ~= nil then
                    if violators[i].violator:match("^%s*(.-)%s*$") == arg then
                        if violators[i].description ~= nil then violators[i].description = u8:decode(violators[i].description)
                        else violators[i].description = "Отсутствует" end
                        sampAddChatMessage("--------------------------------------------------------------------------------------------", 0x00FA9A)
                        sampAddChatMessage(string.format("{00FA9A}Ник:{ffffff} %s | {00FA9A}Выдал:{ffffff} %s | {00FA9A}Дата: {ffffff}%s", violators[i].violator, violators[i].author, violators[i].date), 0x00FA9A)
                        sampAddChatMessage(string.format("{00FA9A}Санкция: {ffffff}%s | {00FA9A}Причина:{ffffff} %s | {00FA9A}Описание:{ffffff} %s", u8:decode(violators[i].sanction), u8:decode(violators[i].reason), violators[i].description), 0x00FA9A)
                        sampAddChatMessage("--------------------------------------------------------------------------------------------", 0x00FA9A)
                        flag = false
                    end
                end
            end
            if flag then sampAddChatMessage(string.format("{ffffff}%s {00FA9A}в реестре наказаний не обнаружен!", arg), 0x00FA9A) end
        end,
        function(err)
            print(err)
        end
    )
end

function cmd_getrank(args)
    if #args == 0 then
        sampAddChatMessage('Введите: /getrank [id / nick] (Количество записей max = 25)', 0x00FA9A)
        return
    end
    local params, i = {}, 1
    for arg in string.gmatch(args, "[^%s]+") do
        params[i] = arg
        i = i + 1
    end
    params[2] = tonumber(params[2])
    if params[2] == nil then params[2] = 5 end
    if params[2] > 25 then
        sampAddChatMessage('Максимум 25 записей', 0x00FA9A)
        return
    end
    local id = tonumber(params[1])
    if id ~= nil then
        if sampIsPlayerConnected(id) then
            params[1] = sampGetPlayerNickname(id)
        else
            sampAddChatMessage('Игрок оффлайн!', 0x00FA9A)
            return
        end
    end
    local body = "draw=8&columns%5B0%5D%5Bdata%5D=0&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=true&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=1&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=true&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=2&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=true&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B3%5D%5Bdata%5D=3&columns%5B3%5D%5Bname%5D=&columns%5B3%5D%5Bsearchable%5D=true&columns%5B3%5D%5Borderable%5D=true&columns%5B3%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B3%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B4%5D%5Bdata%5D=4&columns%5B4%5D%5Bname%5D=&columns%5B4%5D%5Bsearchable%5D=true&columns%5B4%5D%5Borderable%5D=true&columns%5B4%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B4%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B5%5D%5Bdata%5D=5&columns%5B5%5D%5Bname%5D=&columns%5B5%5D%5Bsearchable%5D=true&columns%5B5%5D%5Borderable%5D=true&columns%5B5%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B5%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B6%5D%5Bdata%5D=6&columns%5B6%5D%5Bname%5D=&columns%5B6%5D%5Bsearchable%5D=true&columns%5B6%5D%5Borderable%5D=true&columns%5B6%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B6%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B7%5D%5Bdata%5D=7&columns%5B7%5D%5Bname%5D=&columns%5B7%5D%5Bsearchable%5D=true&columns%5B7%5D%5Borderable%5D=true&columns%5B7%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B7%5D%5Bsearch%5D%5Bregex%5D=false&order%5B0%5D%5Bcolumn%5D=7&order%5B0%5D%5Bdir%5D=desc&start=0&length=25&search%5Bvalue%5D=" .. params[1] .. "&search%5Bregex%5D=false&fraction=3"
    local headers = {
        ["X-KL-Ajax-Request"] = "Ajax_Request",
        ["sec-ch-ua"] = '"Not/A)Brand";v="8", "Chromium";v="126", "Google Chrome";v="126"',
        ["sec-ch-ua-mobile"] = "?0",
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
        ["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8",
        ["Accept"] = "application/json, text/javascript, */*; q=0.01",
        ["Referer"] = "https://logs.evolve-rp.com/saint-louis",
        ["X-Requested-With"] = "XMLHttpRequest",
        ["sec-ch-ua-platform"] = '"Windows"',
        ["Content-Length"] = tostring(#body)
    }
    sampAddChatMessage('Загрузка данных...', 0x00FA9A)
    asyncHttpRequest('POST', 'https://logs.evolve-rp.com/saint-louis/journal', 
        {
            headers = headers,
            data = body
        },
        function(response)
            if response.status_code == 200 then
                local jsonData = json.decode(response.text)
                if #jsonData.data == 0 then
                    sampAddChatMessage(string.format("{ffffff}%s {00FA9A}в логах не обнаружен!", params[1]), 0x00FA9A)
                    return
                end
                if #jsonData.data < params[2] then params[2] = #jsonData.data end
                for i = params[2], 1, -1 do
                    local line = jsonData.data[i]
                    sampAddChatMessage("--------------------------------------------------------------------------------------------", 0x00FA9A)
                    sampAddChatMessage(string.format("{00FA9A}Иницитаор:{ffffff} %s | {00FA9A}Объект:{ffffff} %s | {00FA9A}Действие: {ffffff}%s", line[2], line[3], u8:decode(line[4])), 0x00FA9A)
                    sampAddChatMessage(string.format("{00FA9A}Старый ранг:{ffffff} %s | {00FA9A}Новый ранг:{ffffff} %s | {00FA9A}Причина: {ffffff}%s", u8:decode(line[5]), u8:decode(line[6]), u8:decode(line[7])), 0x00FA9A)
                    sampAddChatMessage(string.format("{00FA9A}Дата: {ffffff}%s", line[8]), 0x00FA9A)
                    sampAddChatMessage("--------------------------------------------------------------------------------------------", 0x00FA9A)
                end
            else sampAddChatMessage("Ошибка загрузки логов! Код: " .. response.status_code, 0x00FA9A) end
        end,
        function(err)
            print(err)
        end
    )
end

function cmd_invite(args)
    if #args == 0 then
        sampAddChatMessage('Введите: /invite [id] [1 - принять без проверки на ЧС]', 0x00FA9A)
        return
    end
    local params, i = {}, 1
    for arg in string.gmatch(args, "[^%s]+") do
        params[i] = arg
        i = i + 1
    end
    params[2] = tonumber(params[2])
    if params[2] == 1 then
        sampSendChat('/invite ' .. params[1])
        return
    end
    local id = tonumber(params[1])
    if id ~= nil then
        if sampIsPlayerConnected(id) then
            params[1] = sampGetPlayerNickname(id)
        else
            sampAddChatMessage('Игрок оффлайн!', 0x00FA9A)
            return
        end
    end
    sampAddChatMessage('Загрузка данных...', 0x00FA9A)
    asyncHttpRequest('GET', 'https://docs.google.com/spreadsheets/d/1yBkOkDHGgaYqZDW9hY-qG5C5Zr8S3VmEEoFFByazGZ0/gviz/tq', nil,
        function(response)
            local jsonData = json.decode(response.text:gmatch('google%.visualization%.Query.setResponse%((.+)%);')())
            local violators = {}
            for _, row in ipairs(jsonData.table.rows) do
                table.insert(violators, {
                    author = row.c[1] and row.c[1].v or nil,
                    violator = row.c[2] and row.c[2].v or nil,
                    reason = row.c[3] and row.c[3].v or nil,
                    date = row.c[4] and row.c[4].f or nil,
                    degree = row.c[5] and row.c[5].v or nil
                })
            end
            for i = #violators, 1, -1 do
                if violators[i].violator ~= nil then
                    if violators[i].violator:match("^%s*(.-)%s*$") == params[1] then
                        if violators[i].degree ~= 6 then
                            sampAddChatMessage("--------------------------------------------------------------------------------------------", 0x00FA9A)
                            sampAddChatMessage(string.format("{00FA9A}Ник:{ffffff} %s | {00FA9A}Внёс:{ffffff} %s | {00FA9A}Дата: {ffffff}%s", violators[i].violator, violators[i].author, violators[i].date), 0x00FA9A)
                            sampAddChatMessage(string.format("{00FA9A}Степень: {ffffff}%s | {00FA9A}Причина:{ffffff} %s", violators[i].degree, u8:decode(violators[i].reason)), 0x00FA9A)
                            sampAddChatMessage("--------------------------------------------------------------------------------------------", 0x00FA9A)
                            return
                        end
                    end
                end
            end
            sampSendChat("/invite " .. id)
        end,
        function(err)
            print(err)
        end
    )
end

function cmd_checkcontract(arg)
    if #arg == 0 then
        sampAddChatMessage('Введите: /checkcontract [id / nick]', 0x00FA9A)
        return
    end
    local id = tonumber(arg)
    if id ~= nil then
        if sampIsPlayerConnected(id) then
            arg = sampGetPlayerNickname(id)
        else
            sampAddChatMessage('Игрок оффлайн!', 0x00FA9A)
            return
        end
    end
    sampAddChatMessage('Загрузка данных...', 0x00FA9A)
    asyncHttpRequest('GET', 'https://script.google.com/macros/s/AKfycbxB7WwPsPpYHO5aPRdbrsrNuX2pZtS1s4GX8raft68PAX7BcKDee1GqVxUYCH2FrgiQ/exec?nickname=' .. arg, nil,
        function(response)
            local html = u8:decode(response.text)
            local data = html:gmatch('userHtml\\x22:\\x22(.-)\\x22')()
            sampAddChatMessage(data, 0x00FA9A)
        end,
        function(err)
            print(err)
        end
    )
end

function cmd_contracts()
    sampAddChatMessage('Загрузка данных...', 0x00FA9A)
    asyncHttpRequest('GET', 'https://script.google.com/macros/s/AKfycbxB7WwPsPpYHO5aPRdbrsrNuX2pZtS1s4GX8raft68PAX7BcKDee1GqVxUYCH2FrgiQ/exec', nil,
        function(response)
            local html = u8:decode(response.text)
            local data = html:gmatch('userHtml\\x22:\\x22(.-)\\x22')()
            local flag = true
            for nick in string.gmatch(data, '([^,]+)') do
                local id = sampGetPlayerIdByNickname(nick)
                if id ~= nil then
                   sampAddChatMessage(string.format("%s [%s]", nick, id), 0x00FA9A) 
                   flag = false
                end
            end
            if flag then sampAddChatMessage("Список пуст", 0x00FA9A) end
        end,
        function(err)
            print(err)
        end
    )
end

function cmd_acccontract(arg)
    if #arg == 0 then
        sampAddChatMessage('Введите: /acccontract [id / nick]', 0x00FA9A)
        return
    end
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local mynick = sampGetPlayerNickname(myid)
    local id = tonumber(arg)
    if id ~= nil then
        if sampIsPlayerConnected(id) then
            arg = sampGetPlayerNickname(id)
        else
            sampAddChatMessage('Игрок оффлайн!', 0x00FA9A)
            return
        end
    end
    sampAddChatMessage('Загрузка данных...', 0x00FA9A)
    asyncHttpRequest('GET', 'https://script.google.com/macros/s/AKfycbxB7WwPsPpYHO5aPRdbrsrNuX2pZtS1s4GX8raft68PAX7BcKDee1GqVxUYCH2FrgiQ/exec?nickname=' .. arg .. '&staff=' .. mynick, nil,
        function(response)
            local html = u8:decode(response.text)
            local data = html:gmatch('userHtml\\x22:\\x22(.-)\\x22')()
            sampAddChatMessage(data, 0x00FA9A)
        end,
        function(err)
            print(err)
        end
    )
end

function sampGetPlayerIdByNickname(nick)
    nick = tostring(nick)
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if nick == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1003 do
        if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
            return i
        end
    end
end