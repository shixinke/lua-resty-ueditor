local cjson = require 'cjson.safe'
local ueditor = require 'resty.ueditor.ueditor'
local args = ngx.req.get_uri_args()
local action = args and args.action or nil
local editor = ueditor:new({configFile = ngx.var.root..'/lib/resty/ueditor/config.json'})
local result, err = editor:run(action)
if err then
    ngx.log(ngx.ERR, err)
end
if action == 'config' then
    ngx.say(cjson.encode(result))
elseif action == 'uploadimage' or action == 'uploadscrawl' or action == 'uploadvideo' or action == 'uploadfile' then
    ngx.say(cjson.encode(result))
elseif action == 'listimage' or action == 'listfile' then
    ngx.say(cjson.encode(result))
else
    ngx.say(cjson.encode({state = 'FAILED', msg = '非法操作'}))
end