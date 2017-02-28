Name
====

lua-resty-ueditor - 一个针对ueditor(百度开源的html在线编辑器，一般用于网站文章编辑)的lua库

Table of Contents
=================

* [Name](#name)
* [状态](#status)
* [描述](#description)
* [使用说明](#synopsis)
* [方法](#methods)
    * [new](#new)
    * [run](#connect)
* [TODO](#todo)
* [Author](#author)


状态
======

该库目前处于测试状态

描述
===========

基于openresty(ngx-lua)的ueditor操作库

使用说明
========

1、前端页面配置

主要是ueditor的前端js库中的配置(ueditor.config.js)，其中一个比较重要的是指定后端服务地址 serverUrl

我这里指定serverUrl为/ueditor/upload(根据自己的项目实际情况修改)

2、nginx配置

添加一个location用来处理ueditor服务
    
    #根据自己项目实际需要修改
    lua_package_path '/data/program/github/lua-resty-ueditor/lib/?.lua;;';
    
    server {
        listen 8000;
        #根据自己项目实际需要修改
        set $root '/data/program/github/lua-resty-ueditor';
        #根据自己项目实际需要修改
        root $root/examples/public;
    
        location /ueditor/upload {
            default_type application/json;
            content_by_lua_file $root/examples/ueditor.lua;
        }
    }

3、ueditor服务

```
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
```

具体用法请参照examples下面的例子(注:上传目录要有可读写权限)

[返回主菜单](#table-of-contents)

主要方法
=======

[返回主菜单](#table-of-contents)

new
---
`syntax: editor = ueditor:new(options)`

创建ueditor对象

参数 `options` 有以下键:

* `configFile`

    ueditor的配置文件(config.json)所在位置(默认在项目根目录下lib/resty/ueditor/config.json中).

[返回主菜单](#table-of-contents)

run
-------
`syntax: result, err = editor:run(action, options)`

ueditor各种操作的聚合(如上传图片，列出文件等)

参数action表示操作名，有以下取值

* `config`

    获取ueditor配置信息.
* `uploadimage`

    上传图片
 
* `uploadfile`

    上传文件
        
* `uploadvideo`

    上传视频
    
* 'uploadscrawl' 
    
    上传截图
            
* `listimage`

    浏览图片列表
    
* `listfile`

    浏览文件列表    
                
参数 `options` 有以下键:

* `start`

    图片(或文件)列表的起始值.
* `size`

    图片(或文件)列表的每页显示数


TODO
====

* 支持远程抓图.

[返回主菜单](#table-of-contents)

Author
======

shixinke (诗心客) <ishixinke@qq.com>

[返回主菜单](#table-of-contents)

