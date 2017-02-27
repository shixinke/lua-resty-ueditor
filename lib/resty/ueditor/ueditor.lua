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

local function list_files(path, action)
    local path = path and path or ngx_var.document_root
    local fd = popen('ls --full-time '..path)
    local file_info = {dir = '', mtime = 0, files = {}, total = 0}
    for file in fd:lines() do
        local tmp = {}
        local first = substr(file, 1, 1)
        if first == '/' then
            file_info.dir = substr(file, 1, -1)
        elseif first == 'd' then
            local mtime = get_mtime(file)
            mtime = mtime or ''
            local path = get_path(file)
            tmp = {type = 'dir', mtime = mtime, path = path, dir = tmp.dir}
        elseif first == '-' then
            local mtime = get_mtime(file)
            mtime = mtime or ''
            local path = get_path(file)
            tmp = {type = 'file', mtime = mtime, path = path, dir = tmp.dir }
        elseif first == 't' then
            local total = regex.sub(file, 'total\\s+', '')
            file_info.total = tonumber(total)
        else

        end
        if tmp.type then
            file_info.files[#file_info.files+1] = tmp
        end
    end
    return file_info
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


function _M.new(self, options)
    local opt = options and options or {}
    self.configFile = opt.configFile
    self.config = self:get_config()
    return setmetatable(self, mt)
end

function _M.run(self, action)
    local result,relative_path, err
    if action == 'config' then
        result = self.config
    elseif action == 'uploadimage' or action == 'uploadscrawl' or action == 'uploadvideo' or action == 'uploadfile' then
        result, relative_path, err = upload(self.config, action)
    elseif action == 'listimage' then
        result = list_files(self.config.imageManagerListPath)
    elseif action == 'listfile' then
        result = list_files(self.config.fileManagerListPath)
    elseif action == 'catchimage' then

    else
        err = '请求地址出错'
    end
    return result, relative_path, err
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