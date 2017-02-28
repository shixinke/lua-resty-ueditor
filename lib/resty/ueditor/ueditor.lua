local _M = {
    _VERSION = '0.01'
}

local mt = {__index = _M }
local uploader = require 'resty.ueditor.uploader'
local cjson = require 'cjson.safe'
local pcall = pcall
local fopen = io.open
local popen = io.popen
local regex = ngx.re
local substr = string.sub
local ngx_var = ngx.var
local strlen = string.len
local str_replace = string.gsub


local function get_mtime(file)
    local mat = regex.match(file, '[0-9]{4}-[0-9]{2}-[0-9]{2}\\s+[0-9]{2}:[0-9]{2}:[0-9]{2}', 'isjo')
    if mat then
        return mat[0]
    end
end

local function get_path(file)
    local tab = {}
    local iterator, err
    iterator, err = regex.gmatch(file..' ', '([^\\s]+)\\s+', 'ijso')
    if not iterator then
        tab = {file}
        return tab, err
    end
    local m, err = iterator()
    if not m then
        tab = {file}
        return tab, err
    end
    while m do
        tab[#tab+1] = m[1]
        m = iterator()
    end

    return tab[#tab]
end


local function upload(config, action)
    local conf = {}
    if action == 'uploadimage' then
        conf = {
            max_size = config['imageMaxSize'],
            allow_exts = config['imageAllowFiles'],
            type = 'images'
        }
    elseif action == 'uploadscrawl' then
        conf = {
            max_size = config['scrawlMaxSize'],
            allow_exts = config['scrawlAllowFiles'],
            type = 'images'
        }
    elseif action == 'uploadvideo' then
        conf = {
            max_size = config['videoMaxSize'],
            allow_exts = config['videoAllowFiles'],
            type = 'video'
        }
    elseif action == 'uploadfile' then
        conf = {
            max_size = config['fileMaxSize'],
            allow_exts = config['fileAllowFiles'],
            type = 'files'
        }
    end
    local loader = uploader:new(conf)
    return loader:upload()
end

local function get_url(path)
    local root = ngx_var.document_root
    local root_len = strlen(root)
    if substr(path, 1, root_len) ~= root then
        return path
    else
        return substr(path, root_len+1)
    end

end

local function list_files(path, start, size)
    local path = path
    local start = start and tonumber(start) or 1
    if start < 1 then
        start = 1
    end
    local size = size and tonumber(size) or 20
    local endsize = start + size
    local dir = ''
    local files = {}
    local info = {state = 'SUCCESS', list = {}, start = start, total = 0}
    local root = ngx_var.document_root
    local root_len = strlen(root)

    if path and substr(path, -1, -1) == '/' then
        path = substr(path, 1, -2)
    end
    if path == nil or path == '' then
        path = root
    elseif substr(path, 1, root_len) ~= root then
        if substr(path, 1, 1) == '/' then
            path = root..path
        else
            path = root..'/'..path
        end
    else
        path = path
    end

    local fd = popen('ls -R --full-time '..path)

    for file in fd:lines() do
        local first = substr(file, 1, 1)
        if first == '/' then
            dir = substr(file, 1, -2)
        elseif first == 'd' then

        elseif first == '-' then
            local mtime = get_mtime(file)
            mtime = mtime or ''
            local basename = get_path(file)
            files[#files+1] = {url = get_url(dir..'/'..basename), mtime = mtime}
            info.total = info.total +1
        elseif first == 't' then

        else

        end
    end

    for i in ipairs(files) do
        if i>= start and i<=endsize then
            info.list[#info.list+1] = files[i]
        end
    end
    return info
end
local function is_empty_table(tab)
    if type(tab) ~= 'table' then
        return true, 'is not a table'
    end
    for _, v in pairs(tab) do
        if v then
            return false
        end
    end
    return true
end



function _M.new(self, options)
    local opt = options and options or {}
    self.configFile = opt.configFile
    local config = self:get_config()
    self.config = config and config or {}
    return setmetatable(self, mt)
end

function _M.run(self, action, options)
    local options = options and options or {}
    local result,err
    if action == 'config' then
        result = self.config
    elseif action == 'uploadimage' or action == 'uploadscrawl' or action == 'uploadvideo' or action == 'uploadfile' then
        local file_info
        file_info, err = upload(self.config, action)
        result = {state = 'FAILED',  url = '', title = '', original = '', type='', size= 0}
        if file_info then
            result.state = 'SUCCESS'
            result.url = file_info.url
            result.title = file_info.basename
            result.type = file_info.file_type
            result.size = file_info.filesize
        end
    elseif action == 'listimage' then
        local start = options.start and tonumber(options.start) or 1
        local size = options.size and tonumber(options.size) or 20
        result = list_files(self.config.imageManagerListPath, start, size)

    elseif action == 'listfile' then
        local start = options.start and tonumber(options.start) or 1
        local size = options.size and tonumber(options.size) or 20
        result = list_files(self.config.fileManagerListPath, start, size)
    elseif action == 'catchimage' then

    else
        err = '请求地址出错'
    end
    return result, err
end

function _M.get_config(self)
    local err
    local config = {}
    if is_empty_table(self.config) then
        if self.configFile == nil then
            return nil, 'the config file is nil'
        end
        local fd,err = fopen(self.configFile, 'r')
        if fd == nil then
            return config, err
        end
        local conf = fd:read('*all')
        if conf then
            local ret
            ret, config = pcall(cjson.decode, conf)
            if ret then
                if type(config) == 'table' then
                    self.config = config
                else
                    err = 'the config file is not a valid json file'
                end
            else
                err = 'the config file is not a valid json file'
            end
        else
            err = 'read the config file failed'
        end
    end
    return self.config, err
end


function _M.catch_image()

end


return _M