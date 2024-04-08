local M = {}

function M.get_conf()
    local conf = {}

    local l_configpath = vim.fn.expand('%:p:h')
    local l_configfile = l_configpath .. '/.hsftp'
    local l_foundconfig = ''
    if vim.fn.filereadable(l_configfile) == 1 then
        l_foundconfig = l_configfile
    else
        while vim.fn.filereadable(l_configfile) == 0 do
            local slashindex = string.find(l_configpath, '/', -1)
            if slashindex ~= nil then
                l_configpath = string.sub(l_configpath, 1, slashindex)
                l_configfile = l_configpath .. '.hsftp'
                l_configpath = string.sub(l_configpath, 1, slashindex - 1)
                if vim.fn.filereadable(l_configfile) == 1 then
                    l_foundconfig = l_configfile
                    break
                end
                if slashindex == 0 and vim.fn.filereadable(l_configfile) == 0 then
                    break
                end
            else
                break
            end
        end
    end

    if #l_foundconfig > 0 then
        local options = vim.fn.readfile(l_foundconfig)
        for _, option in ipairs(options) do
            local vname = option:gsub('^%s*(.-)%s*$', '%1')
            local vvalue = vim.fn.escape(option:sub(string.find(option, ' ') + 1), "%#!")
            conf[vname] = vvalue
        end

        conf['local'] = vim.fn.fnamemodify(l_foundconfig, ':h:p') .. '/'
        conf['localpath'] = vim.fn.expand('%:p')
        conf['remotepath'] = conf['remote'] .. conf['localpath']:sub(#conf['local'] + 1)
    end

    return conf
end

function M.download_file()
    local conf = M.get_conf()

    if vim.fn.has_key(conf, 'host') == 1 then
        local action = string.format('get %s %s', conf['remotepath'], conf['localpath'])
        local cmd = string.format(
            'expect -c "set timeout 5; spawn sftp -P %s %s@%s; expect \"*assword:\"; send %s\\r; expect \"sftp>\"; send \"%s\\r\"; expect -re \"100%%\"; send \"exit\\r\";"',
            conf['port'], conf['user'], conf['host'], conf['pass'], action)

        if conf['confirm_download'] == '1' then
            local choice = vim.fn.confirm('Download file?', "&Yes\n&No", 2)
            if choice ~= 1 then
                print('Canceled.')
                return
            end
        end

        vim.fn.system(string.format('!%s', cmd))
    else
        print('Could not find .hsftp config file')
    end
end

function M.upload_file()
    local conf = M.get_conf()

    if vim.fn.has_key(conf, 'host') == 1 then
        local action = string.format('put %s %s', conf['localpath'], conf['remotepath'])
        local cmd = string.format(
            'expect -c "set timeout 5; spawn sftp -P %s %s@%s; expect \"*assword:\"; send %s\\r; expect \"sftp>\"; send \"%s\\r\"; expect -re \"100%%\"; send \"exit\\r\";"',
            conf['port'], conf['user'], conf['host'], conf['pass'], action)

        if conf['confirm_upload'] == '1' then
            local choice = vim.fn.confirm('Upload file?', "&Yes\n&No", 2)
            if choice ~= 1 then
                print('Canceled.')
                return
            end
        end

        vim.fn.system(string.format('!%s', cmd))
    else
        print('Could not find .hsftp config file')
    end
end

function M.upload_folder()
    local conf = M.get_conf()

    local action = "send pwd\\r;"
    if vim.fn.has_key(conf, 'host') == 1 then
        for _, file in ipairs(vim.fn.split(vim.fn.glob('%:p:h/*'), '\n')) do
            conf['localpath'] = file
            conf['remotepath'] = conf['remote'] .. conf['localpath']:sub(#conf['local'] + 1)

            if conf['confirm_upload'] == '1' then
                local choice = vim.fn.confirm('Upload file?', "&Yes\n&No", 2)
                if choice ~= 1 then
                    print('Canceled.')
                    return
                end
            end
            action = action ..
                string.format('expect \"sftp>\"; send \"put %s %s\\r\";', conf['localpath'], conf['remotepath'])
        end

        local cmd = string.format(
            'expect -c "set timeout 5; spawn sftp -P %s %s@%s; expect \"*assword:\"; send %s\\r; %s expect -re \"100%%\"; send \"exit\\r\";"',
            conf['port'], conf['user'], conf['host'], conf['pass'], action)

        vim.fn.system(string.format('!%s', cmd))
    else
        print('Could not find .hsftp config file')
    end
end

vim.cmd([[command! Hdownload lua require('sftpnvim').download_file()]])
vim.cmd([[command! Hupload lua require('sftpnvim').upload_file()]])
vim.cmd([[command! Hupdir lua require('sftpnvim').upload_folder()]])

vim.api.nvim_set_keymap('n', '<leader>hsd', ':Hdownload<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>hsu', ':Hupload<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<leader>hsf', ':Hupdir<CR>', { noremap = true })

return M
