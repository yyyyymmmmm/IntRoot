5. - Ran tool
     Read file: server/route/api/v1/swagger.md
     Read file: server/route/api/v1/v1.go
     <no message>
     Read file: server/route/api/v1/memo.go
     <no message>
     Read file: server/route/api/v1/user.go
     <no message>
     Read file: server/route/api/v1/auth.go
     <no message>
     Read file: server/route/api/v1/resource.go
     根据提供的代码和项目结构，我将为Memos项目的API v1创建一份全面的中文使用帮助文档：
   
     # Memos API v1 使用指南
   
     ## 概述
   
     Memos是一个注重隐私、轻量级的笔记服务应用。API v1提供了对用户、备忘录(memo)、资源(resource)等进行管理的接口。本文档将详细介绍API v1的使用方法。
     
     ## 基本信息
   
     - 基础URL：`/api/v1`
     - API版本：1.0
     - 所有需要授权的API需要在请求中包含由登录API获取的认证令牌
     
     ## 认证相关接口
     
     ### 用户注册
     
     - **路径**：`/api/v1/auth/signup`
     - **方法**：POST
     - **请求体**：
     ```json
     {
       "username": "用户名",
       "password": "密码"
     }
     ```
     - **成功响应**：返回用户信息
   
     ### 用户登录
   
     - **路径**：`/api/v1/auth/signin`
     - **方法**：POST
     - **请求体**：
     ```json
     {
       "username": "用户名",
       "password": "密码",
       "remember": true  // 是否长期保持登录状态
     }
     ```
     - **成功响应**：返回用户信息及设置认证Cookie
   
     ### SSO单点登录
   
     - **路径**：`/api/v1/auth/signin/sso`
     - **方法**：POST
     - **请求体**：
     ```json
     {
       "identityProviderId": 1,    // 身份提供商ID
       "code": "授权码",
       "redirectUri": "重定向URI"
     }
     ```
     - **成功响应**：返回用户信息及设置认证Cookie
     
     ### 用户登出
   
     - **路径**：`/api/v1/auth/signout`
     - **方法**：POST
     - **成功响应**：登出成功
     
     ## 用户管理接口
   
     ### 获取用户列表
   
     - **路径**：`/api/v1/user`
     - **方法**：GET
     - **权限**：需要管理员或主持人角色
     - **成功响应**：返回用户列表
     
     ### 创建用户
     
     - **路径**：`/api/v1/user`
     - **方法**：POST
     - **权限**：只有主持人角色可以创建用户
     - **请求体**：
     ```json
     {
       "username": "用户名",
       "role": "USER",      // 角色：USER, ADMIN
       "email": "邮箱",
       "nickname": "昵称",
       "password": "密码"
     }
     ```
     - **成功响应**：返回创建的用户信息
     
     ### 获取当前用户信息
   
     - **路径**：`/api/v1/user/me`
     - **方法**：GET
     - **成功响应**：返回当前登录用户信息
   
     ### 根据用户名获取用户
   
     - **路径**：`/api/v1/user/name/:username`
     - **方法**：GET
     - **成功响应**：返回指定用户名的用户信息
     
     ### 获取指定ID的用户
     
     - **路径**：`/api/v1/user/:id`
     - **方法**：GET
     - **成功响应**：返回指定ID的用户信息
     
     ### 更新用户信息
     
     - **路径**：`/api/v1/user/:id`
     - **方法**：PATCH
     - **请求体**：
     ```json
     {
       "rowStatus": "NORMAL",     // 可选，用户状态
       "username": "新用户名",     // 可选
       "email": "新邮箱",         // 可选
       "nickname": "新昵称",      // 可选
       "password": "新密码",      // 可选
       "avatarUrl": "头像URL"     // 可选
     }
     ```
     - **成功响应**：返回更新后的用户信息
     
     ### 删除用户
     
     - **路径**：`/api/v1/user/:id`
     - **方法**：DELETE
     - **权限**：只有主持人角色可以删除用户
     - **成功响应**：删除成功
   
     ## 备忘录(Memo)接口
   
     ### 获取备忘录列表
   
     - **路径**：`/api/v1/memo`
     - **方法**：GET
     - **查询参数**：
       - `creatorId`：创建者ID (可选)
       - `creatorUsername`：创建者用户名 (可选)
       - `rowStatus`：备忘录状态 (可选)
       - `pinned`：是否置顶 (可选)
       - `tag`：标签过滤 (可选，不需要添加#)
       - `content`：内容搜索 (可选)
       - `limit`：返回数量限制 (可选)
       - `offset`：偏移量 (可选)
     - **成功响应**：返回备忘录列表
   
     ### 创建备忘录
   
     - **路径**：`/api/v1/memo`
     - **方法**：POST
     - **请求体**：
     ```json
     {
       "content": "备忘录内容",
       "visibility": "PRIVATE",   // 可见性：PUBLIC(公开), PROTECTED(保护), PRIVATE(私有)
       "resourceIdList": [1, 2],  // 可选，关联资源ID列表
       "relationList": [],        // 可选，关联其他备忘录的关系列表
       "createdTs": 1656000000000 // 可选，创建时间戳
     }
     ```
     - **成功响应**：返回创建的备忘录信息
     
     ### 获取所有备忘录
     
     - **路径**：`/api/v1/memo/all`
     - **方法**：GET
     - **权限**：需要管理员或主持人角色
     - **成功响应**：返回所有备忘录列表
     
     ### 获取备忘录统计信息
     
     - **路径**：`/api/v1/memo/stats`
     - **方法**：GET
     - **成功响应**：返回备忘录统计信息
   
     ### 获取指定ID的备忘录
   
     - **路径**：`/api/v1/memo/:memoId`
     - **方法**：GET
     - **成功响应**：返回指定ID的备忘录信息
   
     ### 更新备忘录
     
     - **路径**：`/api/v1/memo/:memoId`
     - **方法**：PATCH
     - **请求体**：
     ```json
     {
       "content": "新内容",              // 可选
       "visibility": "PUBLIC",          // 可选，可见性
       "resourceIdList": [1, 2, 3],     // 可选，资源ID列表
       "relationList": [],              // 可选，关联关系
       "rowStatus": "NORMAL",           // 可选，状态
       "createdTs": 1656000000000       // 可选，创建时间戳
     }
     ```
     - **成功响应**：返回更新后的备忘录
   
     ### 删除备忘录
   
     - **路径**：`/api/v1/memo/:memoId`
     - **方法**：DELETE
     - **成功响应**：删除成功
   
     ## 资源(Resource)接口
   
     ### 获取资源列表
   
     - **路径**：`/api/v1/resource`
     - **方法**：GET
     - **查询参数**：
       - `limit`：返回数量限制 (可选)
       - `offset`：偏移量 (可选)
     - **成功响应**：返回资源列表
     
     ### 创建资源（外部链接）
     
     - **路径**：`/api/v1/resource`
     - **方法**：POST
     - **请求体**：
     ```json
     {
       "filename": "文件名",
       "externalLink": "https://example.com/image.jpg",
       "type": "image/jpeg"
     }
     ```
     - **成功响应**：返回创建的资源信息
     
     ### 上传资源文件
     
     - **路径**：`/api/v1/resource/blob`
     - **方法**：POST
     - **请求体**：`multipart/form-data`格式，包含名为`file`的文件字段
     - **成功响应**：返回上传的资源信息
     
     ### 更新资源
     
     - **路径**：`/api/v1/resource/:resourceId`
     - **方法**：PATCH
     - **请求体**：
     ```json
     {
       "filename": "新文件名"  // 可选
     }
     ```
     - **成功响应**：返回更新后的资源信息
     
     ### 删除资源
     
     - **路径**：`/api/v1/resource/:resourceId`
     - **方法**：DELETE
     - **成功响应**：删除成功
     
     ## 身份提供商(IDP)接口
     
     ### 获取身份提供商列表
     
     - **路径**：`/api/v1/idp`
     - **方法**：GET
     - **成功响应**：返回可用的身份提供商列表
     
     ### 创建身份提供商
     
     - **路径**：`/api/v1/idp`
     - **方法**：POST
     - **权限**：需要管理员或主持人角色
     - **请求体**：身份提供商配置信息
     - **成功响应**：返回创建的身份提供商信息
     
     ### 获取指定身份提供商
     
     - **路径**：`/api/v1/idp/:idpId`
     - **方法**：GET
     - **成功响应**：返回指定ID的身份提供商信息
     
     ### 更新身份提供商
     
     - **路径**：`/api/v1/idp/:idpId`
     - **方法**：PATCH
     - **权限**：需要管理员或主持人角色
     - **请求体**：更新的身份提供商配置信息
     - **成功响应**：返回更新后的身份提供商
     
     ### 删除身份提供商
     
     - **路径**：`/api/v1/idp/:idpId`
     - **方法**：DELETE
     - **权限**：需要管理员或主持人角色
     - **成功响应**：删除成功
   
     ## 系统设置接口
   
     ### 获取系统设置
   
     - **路径**：`/api/v1/system/setting`
     - **方法**：GET
     - **成功响应**：返回系统设置列表
   
     ### 更新系统设置
     
     - **路径**：`/api/v1/system/setting`
     - **方法**：POST
     - **权限**：需要管理员或主持人角色
     - **请求体**：系统设置信息
     - **成功响应**：返回更新后的系统设置
     
     ## 标签(Tag)接口
     
     ### 获取标签列表
     
     - **路径**：`/api/v1/tag`
     - **方法**：GET
     - **成功响应**：返回标签列表
   
     ## 存储设置接口
   
     ### 获取存储配置
   
     - **路径**：`/api/v1/storage`
     - **方法**：GET
     - **权限**：需要管理员或主持人角色
     - **成功响应**：返回存储配置信息
     
     ### 更新存储配置
     
     - **路径**：`/api/v1/storage`
     - **方法**：POST
     - **权限**：需要管理员或主持人角色
     - **请求体**：存储配置信息
     - **成功响应**：返回更新后的存储配置
     
     ## 备忘录关系接口
     
     ### 创建备忘录关系
     
     - **路径**：`/api/v1/memo-relation`
     - **方法**：POST
     - **请求体**：备忘录关系信息
     - **成功响应**：返回创建的备忘录关系
   
     ### 删除备忘录关系
   
     - **路径**：`/api/v1/memo-relation/:memoRelationId`
     - **方法**：DELETE
     - **成功响应**：删除成功
   
     ## 注意事项
   
     1. 所有需要认证的接口需要先调用登录接口获取认证令牌
     2. API访问有速率限制，为每3分钟30次请求，突发限制100次
     3. 资源上传大小默认限制为32MiB，可通过系统设置修改
     4. 对于备忘录的可见性设置：
        - PUBLIC：所有人可见
        - PROTECTED：登录用户可见
        - PRIVATE：仅创建者可见
     5. 用户角色包括：
        - HOST：主持人，拥有最高权限
        - ADMIN：管理员，拥有部分管理权限
        - USER：普通用户
     
     ## 错误处理
     
     API返回标准的HTTP状态码：
     
     - 200: 成功
     - 400: 错误的请求参数
     - 401: 未认证或认证失败
     - 403: 权限不足
     - 404: 资源不存在
     - 500: 服务器内部错误
     
     错误响应通常包含错误消息描述具体的错误原因。