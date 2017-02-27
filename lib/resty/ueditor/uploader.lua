local upload = require "resty.upload"
local _M = {_VERSION = '0.01' }
local mt = {__index = _M }
local ngx_var = ngx.var
local gsub = string.gsub
local fopen = io.open

local chunk_size = 4096
local form = upload:new(chunk_size)
local os = os
local date = os.date
local execute = os.execute
local file
local file_type
local file_name

--获取文件扩展名
local function get_ext(res)
    local ext,file_type = 'file'
    if res == 'video/x-ms-asf' then
        ext = 'asf'
        file_type = 'video'
    elseif res == 'video/x-msvideo' then
        ext = 'avi'
        file_type = 'video'
    elseif res == 'application/octet-stream' then
        ext = 'bin'
    elseif res == 'image/bmp' then
        ext = 'bmp'
        file_type = 'image'
    elseif res == 'text/plain' then
        ext = 'txt'
    elseif res == 'application/x-x509-ca-cert' then
        ext = 'cer'
    elseif res == 'text/css' then
        ext = 'css'
    elseif res == 'application/x-msdownload' then
        ext = 'dll'
    elseif res == 'application/msword' then
        ext = 'doc'
    elseif res == 'application/x-dvi' then
        ext = 'dvi'
    elseif res == 'application/fractals' then
        ext = 'fif'
    elseif res == 'application/x-gzip' then
        ext = 'gz'
    elseif res == 'text/html' then
        ext = 'html'
    elseif res == 'image/x-icon' then
        ext = 'ico'
        file_type = 'image'
    elseif res == 'image/jpeg' then
        ext = 'jpe'
        file_type = 'image'
    elseif res == 'image/jpeg' then
        ext = 'jpg'
        file_type = 'image'
    elseif res == 'image/png' then
        ext = 'png'
        file_type = 'image'
    elseif res == 'application/x-javascript' then
        ext = 'js'
    elseif res == 'audio/x-mpegurl' then
        ext = 'm3u'
        file_type = 'audio'
    elseif res == 'audio/mid' then
        ext = 'mid'
        file_type = 'audio'
    elseif res == 'video/quicktime' then
        ext = 'mov'
        file_type = 'video'
    elseif res == 'video/x-sgi-movie' then
        ext = 'movie'
        file_type = 'video'
    elseif res == 'video/mpeg' then
        ext = 'mp3'
        file_type = 'video'
    elseif res == 'image/x-portable-bitmap' then
        ext = 'pbm'
        file_type='image'
    elseif res == 'application/pdf' then
        ext = 'pdf'
    elseif res == 'application/vnd.ms-powerpoint' then
        ext = 'ppt'
    elseif res == 'audio/x-pn-realaudio' then
        ext = 'ra'
        file_type = 'audio'
    elseif res == 'audio/mid' then
        ext = 'rmi'
        file_type = 'audio'
    elseif res == 'image/svg+xml' then
        ext = 'svg'
        file_type = 'image'
    elseif res == 'application/x-shockwave-flash' then
        ext = 'swf'
        file_type = 'video'
    elseif res == 'application/x-tar' then
        ext = 'tar'
    elseif res == 'application/x-compressed' then
        ext = 'tgz'
    elseif res == 'audio/x-wav' then
        ext = 'wav'
        file_type = 'audio'
    elseif res == 'application/vnd.ms-works' then
        ext = 'wps'
    elseif res == 'application/vnd.ms-excel' then
        ext = 'xls'
    elseif res == 'image/x-xpixmap' then
        ext = 'xpm'
        file_type = 'image'
    elseif res == 'application/zip' then
        ext = 'zip'
    end
    return ext, file_type
end

--判断某个值是否在数组中
local function in_array(v, tab)
    if type(tab) ~= 'table' then
        return nil, 'the variable tab is not table'
    end
    local i = false
    for _, val in ipairs(tab) do
        if val == v then
            i = true
            break
        end
    end
    return i
end

function _M.new(self, options)
    local opt = options and options or {}
    self.max_size = opt.max_size and tonumber(opt.max_size) or 2000000
    self.allow_exts = opt.allow_exts and opt.allow_exts or {'.jpg', '.png', '.gif', '.bmp' }
    self.type = opt.type and opt.type or 'images'
    self.save_path = opt.save_path and opt.save_path or ngx_var.document_root..'/uploads/'..self.type
    self.path_format = opt.path_format and opt.path_format or 'Y/m/d'
    self.file_type = 'image'
    return setmetatable(self, mt)
end

function _M.get_dir(self)
    local dir = self.save_path
    if self.path_format == 'Ymd' then
        dir = dir..'/'..date('%Y%m%d')
    elseif self.path_format == 'Y/m/d' then
        dir = dir..'/'..date('%Y')..'/'..date('%m')..'/'..date('%d')..'/'
    elseif self.path_format == 'Y/m' then
        dir = dir..'/'..date('%Y')..'/'..date('%m')..'/'
    end
    return dir
end

function _M.upload(self)
    while true do
        local typ, res, err = form:read()
        if typ == "header" then
            if res[1] ~= "Content-Disposition" then

                local file_id = ngx.md5('upload'..os.time())
                local extension
                extension = get_ext(res[2])

                if not extension then
                    return nil, nil, '未获取到文件后缀'
                end

                if not in_array('.'..extension, self.allow_exts) then
                    return nil, nil, '不支持这种文件格式'
                end

                local dir = self:get_dir()
                local fd, err = fopen(dir, 'r+')
                if fd == nil then
                    local status = execute('mkdir -p '..dir)
                    if status ~= true then
                        ngx.log(ngx.ERR, 'mkdir failed:'..dir)
                        return nil, nil, '创建目录失败'
                    end
                end
                file_name = dir..file_id.."."..extension
                if file_name then
                    file = io.open(file_name, "w+")
                    if not file then
                        return nil, nil, 'failed to open file'
                    end
                end
            end
        elseif typ == "body" then
            if type(tonumber(res)) == 'number' and tonumber(res) > self.max_size then
                return nil, nil, '文件超过规定大小'
            end
            if file then
                file:write(res)
            end
        elseif typ == "part_end" then
            if file then
                file:close()
                file = nil
            end
        elseif typ == "eof" then
            local relative_path = gsub(file_name, ngx_var.document_root, '')
            return file_name, relative_path
        else

        end
    end
end

return _M






