
# Memos API 文档

## 目录

- [介绍](#介绍)
- [基础信息](#基础信息)
- [认证](#认证)
  - [API v1 认证](#api-v1-认证)
  - [API v2 认证](#api-v2-认证)
- [用户管理](#用户管理)
  - [API v1 用户管理](#api-v1-用户管理)
  - [API v2 用户管理](#api-v2-用户管理)
- [备忘录管理](#备忘录管理)
  - [API v1 备忘录](#api-v1-备忘录)
  - [API v2 备忘录](#api-v2-备忘录)
- [资源管理](#资源管理)
  - [API v1 资源](#api-v1-资源)
  - [API v2 资源](#api-v2-资源)
- [系统与工作区设置](#系统与工作区设置)
  - [API v1 系统设置](#api-v1-系统设置)
  - [API v2 工作区设置](#api-v2-工作区设置)
- [身份提供商](#身份提供商)
- [标签管理](#标签管理)
- [链接服务](#链接服务)
- [错误处理](#错误处理)
- [数据模型](#数据模型)
- [状态码](#状态码)

## 介绍

Memos 是一个开源的、轻量级的笔记服务，专注于隐私保护。本文档详细介绍了 Memos 的 API 接口，包括端点、请求参数、响应格式以及使用示例。

Memos 提供了两个主要的 API 版本：
- **API v1**: 传统的 REST 风格 API
- **API v2**: 基于 gRPC 的 API，同时提供 HTTP/JSON 网关

API v2 是较新的版本，提供了更多功能和更好的性能，但 API v1 仍然完全支持并广泛使用。

## 基础信息

### 服务端点

- **API v1 基础 URL**: `/api/v1`
- **API v2 基础 URL**: `/api/v2`
- **健康检查**: `/healthz` (返回 "Service ready.")

### 通用请求头

- **Content-Type**: `application/json`
- **Authorization**: `Bearer {token}` (认证后获取的 JWT 令牌)

### 速率限制

API v1 实现了速率限制：
- 30次请求/分钟
- 突发上限100次
- 超过限制将返回 HTTP 429 状态码

## 认证

### API v1 认证

#### 登录

**端点**: `POST /api/v1/auth/signin`

**描述**: 使用用户名和密码登录

**请求体**:
```json
{
  "username": "用户名",
  "password": "密码",
  "remember": true  // 是否永久保存登录状态
}
```

**响应**:
```json
{
  "id": 1,
  "username": "用户名",
  "role": "HOST", // 可能的值: "HOST", "ADMIN", "USER"
  "email": "user@example.com",
  "nickname": "昵称",
  "avatarUrl": "https://example.com/avatar.png",
  "createdTs": 1640995200000,
  "updatedTs": 1640995200000,
  "rowStatus": "NORMAL" // 可能的值: "NORMAL", "ARCHIVED"
}
```

**错误响应**:
- `400 Bad Request`: 请求格式错误
- `401 Unauthorized`: 用户名或密码错误，或密码登录已禁用
- `403 Forbidden`: 用户已被归档

#### SSO 登录

**端点**: `POST /api/v1/auth/signin/sso`

**描述**: 使用第三方身份提供商登录

**请求体**:
```json
{
  "identityProviderId": 1,
  "code": "授权码",
  "redirectUri": "https://your-app.com/callback"
}
```

**响应**: 与标准登录响应相同

**错误响应**:
- `400 Bad Request`: 请求格式错误
- `401 Unauthorized`: 授权失败或标识符不匹配过滤器
- `403 Forbidden`: 用户已被归档
- `404 Not Found`: 未找到身份提供商
- `500 Internal Server Error`: 交换令牌或获取用户信息失败

#### 注册

**端点**: `POST /api/v1/auth/signup`

**描述**: 创建新用户账号

**请求体**:
```json
{
  "username": "用户名",
  "password": "密码"
}
```

**响应**: 与登录响应相同

**错误响应**:
- `400 Bad Request`: 请求格式错误或用户名已存在
- `401 Unauthorized`: 禁止注册

#### 登出

**端点**: `POST /api/v1/auth/signout`

**描述**: 终止当前会话

**请求体**: 空

**响应**: HTTP 200 和空响应体

### API v2 认证

#### 获取认证状态

**端点**: `POST /api/v2/auth/status`

**描述**: 获取当前用户的认证状态

**请求体**: 空

**响应**:
```json
{
  "user": {
    "name": "users/1",
    "username": "用户名",
    "role": "HOST",
    "email": "user@example.com",
    "nickname": "昵称",
    "avatarUrl": "https://example.com/avatar.png"
  }
}
```

#### 登录

**端点**: `POST /api/v2/auth/signin`

**描述**: 使用用户名和密码登录

**查询参数**:
- `username`: 用户名
- `password`: 密码
- `neverExpire`: 是否永久有效(布尔值)

**响应**:
```json
{
  "user": {
    "name": "users/1",
    "username": "用户名",
    "role": "HOST",
    "email": "user@example.com",
    "nickname": "昵称",
    "avatarUrl": "https://example.com/avatar.png"
  }
}
```

#### SSO 登录

**端点**: `POST /api/v2/auth/signin/sso`

**描述**: 使用第三方身份提供商登录

**查询参数**:
- `idpId`: 身份提供商 ID
- `code`: 授权码
- `redirectUri`: 重定向 URI

**响应**: 与 v2 标准登录响应相同

#### 注册

**端点**: `POST /api/v2/auth/signup`

**描述**: 创建新用户账号

**查询参数**:
- `username`: 用户名
- `password`: 密码

**响应**: 与 v2 登录响应相同

#### 登出

**端点**: `POST /api/v2/auth/signout`

**描述**: 终止当前会话

**响应**: 空响应体

## 用户管理

### API v1 用户管理

#### 获取用户列表

**端点**: `GET /api/v1/user`

**描述**: 获取所有用户的列表

**权限要求**: HOST 或 ADMIN 角色

**响应**:
```json
[
  {
    "id": 1,
    "username": "admin",
    "role": "HOST",
    "email": "admin@example.com",
    "nickname": "管理员",
    "avatarUrl": "https://example.com/avatar.png",
    "createdTs": 1640995200000,
    "updatedTs": 1640995200000,
    "rowStatus": "NORMAL"
  },
  {
    "id": 2,
    "username": "user1",
    "role": "USER",
    "email": "user1@example.com",
    "nickname": "用户1",
    "avatarUrl": "https://example.com/avatar2.png",
    "createdTs": 1641095200000,
    "updatedTs": 1641095200000,
    "rowStatus": "NORMAL"
  }
]
```

#### 创建用户

**端点**: `POST /api/v1/user`

**描述**: 创建新用户

**权限要求**: HOST 角色

**请求体**:
```json
{
  "username": "newuser",
  "role": "USER",  // "HOST", "ADMIN", "USER"
  "email": "newuser@example.com",
  "nickname": "新用户",
  "password": "password123"
}
```

**响应**:
```json
{
  "id": 3,
  "username": "newuser",
  "role": "USER",
  "email": "newuser@example.com",
  "nickname": "新用户",
  "avatarUrl": "",
  "createdTs": 1642095200000,
  "updatedTs": 1642095200000,
  "rowStatus": "NORMAL"
}
```

**错误响应**:
- `400 Bad Request`: 请求格式错误或用户名已存在
- `401 Unauthorized`: 未经授权
- `403 Forbidden`: 权限不足

#### 获取当前用户

**端点**: `GET /api/v1/user/me`

**描述**: 获取当前已认证用户的信息

**响应**:
```json
{
  "id": 1,
  "username": "admin",
  "role": "HOST",
  "email": "admin@example.com",
  "nickname": "管理员",
  "avatarUrl": "https://example.com/avatar.png",
  "createdTs": 1640995200000,
  "updatedTs": 1640995200000,
  "rowStatus": "NORMAL"
}
```

#### 通过用户名获取用户

**端点**: `GET /api/v1/user/name/:username`

**描述**: 通过用户名查找用户

**路径参数**:
- `username`: 用户名

**响应**:
```json
{
  "id": 2,
  "username": "user1",
  "role": "USER",
  "email": "user1@example.com",
  "nickname": "用户1",
  "avatarUrl": "https://example.com/avatar2.png",
  "createdTs": 1641095200000,
  "updatedTs": 1641095200000,
  "rowStatus": "NORMAL"
}
```

#### 通过 ID 获取用户

**端点**: `GET /api/v1/user/:id`

**描述**: 通过 ID 查找用户

**路径参数**:
- `id`: 用户 ID

**响应**: 与通过用户名获取用户的响应相同

#### 更新用户

**端点**: `PATCH /api/v1/user/:id`

**描述**: 更新用户信息

**权限要求**: 
- 用户只能更新自己的信息
- HOST 和 ADMIN 可以更新其他用户

**路径参数**:
- `id`: 用户 ID

**请求体**:
```json
{
  "rowStatus": "NORMAL",  // "NORMAL", "ARCHIVED"
  "username": "updatedname",
  "email": "updated@example.com",
  "nickname": "更新的昵称",
  "password": "newpassword",
  "avatarUrl": "https://example.com/new-avatar.png"
}
```

**响应**:
```json
{
  "id": 2,
  "username": "updatedname",
  "role": "USER",
  "email": "updated@example.com",
  "nickname": "更新的昵称",
  "avatarUrl": "https://example.com/new-avatar.png",
  "createdTs": 1641095200000,
  "updatedTs": 1643095200000,
  "rowStatus": "NORMAL"
}
```

#### 删除用户

**端点**: `DELETE /api/v1/user/:id`

**描述**: 删除用户

**权限要求**: HOST 角色

**路径参数**:
- `id`: 用户 ID

**响应**: HTTP 200 和 `true`

### API v2 用户管理

#### 获取用户列表

**端点**: `GET /api/v2/users`

**描述**: 分页获取用户列表

**查询参数**:
- `pageSize`: 每页大小，默认为 10
- `pageToken`: 分页标记，从上一次请求的响应获取

**响应**:
```json
{
  "users": [
    {
      "name": "users/1",
      "username": "admin",
      "role": "HOST",
      "email": "admin@example.com",
      "nickname": "管理员",
      "avatarUrl": "https://example.com/avatar.png",
      "rowStatus": "NORMAL",
      "createTime": "2022-01-01T00:00:00Z",
      "updateTime": "2022-01-01T00:00:00Z"
    },
    {
      "name": "users/2",
      "username": "user1",
      "role": "USER",
      "email": "user1@example.com",
      "nickname": "用户1",
      "avatarUrl": "https://example.com/avatar2.png",
      "rowStatus": "NORMAL",
      "createTime": "2022-01-02T00:00:00Z",
      "updateTime": "2022-01-02T00:00:00Z"
    }
  ],
  "nextPageToken": "next-page-token"
}
```

#### 搜索用户

**端点**: `GET /api/v2/users:search`

**描述**: 通过过滤条件搜索用户

**查询参数**:
- `filter`: 过滤条件，例如 `username == "admin"`

**响应**:
```json
{
  "users": [
    {
      "name": "users/1",
      "username": "admin",
      "role": "HOST",
      "email": "admin@example.com",
      "nickname": "管理员",
      "avatarUrl": "https://example.com/avatar.png",
      "rowStatus": "NORMAL",
      "createTime": "2022-01-01T00:00:00Z",
      "updateTime": "2022-01-01T00:00:00Z"
    }
  ]
}
```

#### 获取用户

**端点**: `GET /api/v2/{name=users/*}`

**描述**: 获取单个用户信息

**路径参数**:
- `name`: 用户资源名称，格式为 `users/{id}`

**响应**:
```json
{
  "user": {
    "name": "users/1",
    "username": "admin",
    "role": "HOST",
    "email": "admin@example.com",
    "nickname": "管理员",
    "avatarUrl": "https://example.com/avatar.png",
    "rowStatus": "NORMAL",
    "createTime": "2022-01-01T00:00:00Z",
    "updateTime": "2022-01-01T00:00:00Z"
  }
}
```

#### 创建用户

**端点**: `POST /api/v2/users`

**描述**: 创建新用户

**权限要求**: HOST 角色

**请求体**:
```json
{
  "user": {
    "username": "newuser",
    "role": "USER",
    "email": "newuser@example.com",
    "nickname": "新用户",
    "password": "password123"
  }
}
```

**响应**:
```json
{
  "user": {
    "name": "users/3",
    "username": "newuser",
    "role": "USER",
    "email": "newuser@example.com",
    "nickname": "新用户",
    "avatarUrl": "",
    "rowStatus": "NORMAL",
    "createTime": "2022-01-10T00:00:00Z",
    "updateTime": "2022-01-10T00:00:00Z"
  }
}
```

#### 更新用户

**端点**: `PATCH /api/v2/{user.name=users/*}`

**描述**: 更新用户信息

**路径参数**:
- `user.name`: 用户资源名称，格式为 `users/{id}`

**请求体**:
```json
{
  "user": {
    "name": "users/2",
    "email": "updated@example.com",
    "nickname": "更新的昵称",
    "avatarUrl": "https://example.com/new-avatar.png"
  },
  "updateMask": "email,nickname,avatarUrl"
}
```

**响应**:
```json
{
  "user": {
    "name": "users/2",
    "username": "user1",
    "role": "USER",
    "email": "updated@example.com",
    "nickname": "更新的昵称",
    "avatarUrl": "https://example.com/new-avatar.png",
    "rowStatus": "NORMAL",
    "createTime": "2022-01-02T00:00:00Z",
    "updateTime": "2022-01-15T00:00:00Z"
  }
}
```

#### 删除用户

**端点**: `DELETE /api/v2/{name=users/*}`

**描述**: 删除用户

**权限要求**: HOST 角色

**路径参数**:
- `name`: 用户资源名称，格式为 `users/{id}`

**响应**: 空响应体

#### 获取用户设置

**端点**: `GET /api/v2/{name=users/*}/setting`

**描述**: 获取用户设置

**路径参数**:
- `name`: 用户资源名称，格式为 `users/{id}`

**响应**:
```json
{
  "setting": {
    "name": "users/1/setting",
    "locale": "zh-CN",
    "appearance": "dark",
    "memoVisibility": "PRIVATE"
  }
}
```

#### 更新用户设置

**端点**: `PATCH /api/v2/{setting.name=users/*/setting}`

**描述**: 更新用户设置

**路径参数**:
- `setting.name`: 用户设置资源名称，格式为 `users/{id}/setting`

**请求体**:
```json
{
  "setting": {
    "name": "users/1/setting",
    "locale": "en",
    "appearance": "system"
  },
  "updateMask": "locale,appearance"
}
```

**响应**:
```json
{
  "setting": {
    "name": "users/1/setting",
    "locale": "en",
    "appearance": "system",
    "memoVisibility": "PRIVATE"
  }
}
```

## 备忘录管理

### API v1 备忘录

#### 获取备忘录列表

**端点**: `GET /api/v1/memo`

**描述**: 根据过滤条件获取备忘录列表

**查询参数**:
- `creatorId`: 创建者 ID
- `creatorUsername`: 创建者用户名
- `rowStatus`: 行状态 ("NORMAL", "ARCHIVED")
- `pinned`: 是否置顶 (布尔值)
- `tag`: 标签 (不需要添加 #)
- `content`: 内容搜索
- `limit`: 限制数量
- `offset`: 偏移量

**响应**:
```json
[
  {
    "id": 1,
    "rowStatus": "NORMAL",
    "createdTs": 1640995200000,
    "updatedTs": 1640995200000,
    "creatorId": 1,
    "content": "这是一条备忘录 #tag1",
    "visibility": "PUBLIC",
    "pinned": true,
    "resourceList": [
      {
        "id": 1,
        "filename": "image.png",
        "externalLink": "",
        "type": "image/png",
        "size": 1024
      }
    ],
    "relationList": []
  },
  {
    "id": 2,
    "rowStatus": "NORMAL",
    "createdTs": 1641095200000,
    "updatedTs": 1641095200000,
    "creatorId": 1,
    "content": "这是另一条备忘录 #tag2",
    "visibility": "PRIVATE",
    "pinned": false,
    "resourceList": [],
    "relationList": []
  }
]
```

#### 创建备忘录

**端点**: `POST /api/v1/memo`

**描述**: 创建新的备忘录

**请求体**:
```json
{
  "content": "这是新备忘录的内容 #tag",
  "visibility": "PUBLIC",  // "PUBLIC", "PROTECTED", "PRIVATE"
  "resourceIdList": [1],
  "relationList": [
    {
      "relatedMemoId": 1,
      "type": "REFERENCE"  // "REFERENCE", "COMMENT"
    }
  ]
}
```

**响应**: 创建的备忘录对象

**错误响应**:
- `400 Bad Request`: 请求格式错误或内容过长(超过 1MB)
- `401 Unauthorized`: 未认证
- `404 Not Found`: 引用的资源或备忘录不存在

#### 获取所有备忘录

**端点**: `GET /api/v1/memo/all`

**描述**: 获取所有备忘录(仅限 HOST 和 ADMIN)

**响应**: 备忘录对象数组

#### 获取备忘录统计

**端点**: `GET /api/v1/memo/stats`

**描述**: 获取备忘录统计信息

**响应**:
```json
{
  "todayCount": 5,
  "totalCount": 100,
  "creatorCount": 3
}
```

#### 获取单个备忘录

**端点**: `GET /api/v1/memo/:memoId`

**描述**: 通过 ID 获取备忘录

**路径参数**:
- `memoId`: 备忘录 ID

**响应**: 单个备忘录对象

**错误响应**:
- `400 Bad Request`: ID 格式错误
- `403 Forbidden`: 无权访问私有或受保护的备忘录
- `404 Not Found`: 备忘录不存在

#### 更新备忘录

**端点**: `PATCH /api/v1/memo/:memoId`

**描述**: 更新备忘录

**路径参数**:
- `memoId`: 备忘录 ID

**请求体**:
```json
{
  "content": "更新后的内容 #tag",
  "visibility": "PROTECTED",
  "resourceIdList": [1, 2],
  "relationList": [
    {
      "relatedMemoId": 2,
      "type": "REFERENCE"
    }
  ]
}
```

**响应**: 更新后的备忘录对象

**错误响应**:
- `400 Bad Request`: 请求格式错误
- `401 Unauthorized`: 未认证
- `403 Forbidden`: 无权更新
- `404 Not Found`: 备忘录不存在

#### 删除备忘录

**端点**: `DELETE /api/v1/memo/:memoId`

**描述**: 删除备忘录

**路径参数**:
- `memoId`: 备忘录 ID

**响应**: HTTP 200 和 `true`

**错误响应**:
- `400 Bad Request`: ID 格式错误
- `401 Unauthorized`: 未认证
- `404 Not Found`: 备忘录不存在

### API v2 备忘录

#### 创建备忘录

**端点**: `POST /api/v2/memos`

**描述**: 创建新的备忘录

**请求体**:
```json
{
  "creator": "users/1",
  "content": "这是通过 API v2 创建的备忘录 #tag",
  "visibility": "PUBLIC",
  "resources": [
    {
      "name": "resources/1"
    }
  ]
}
```

**响应**:
```json
{
  "memo": {
    "name": "memos/1",
    "uid": "unique-id",
    "rowStatus": "NORMAL",
    "creator": "users/1",
    "createTime": "2022-01-01T00:00:00Z",
    "updateTime": "2022-01-01T00:00:00Z",
    "displayTime": "2022-01-01T00:00:00Z",
    "content": "这是通过 API v2 创建的备忘录 #tag",
    "visibility": "PUBLIC",
    "pinned": false,
    "resources": [
      {
        "name": "resources/1",
        "filename": "image.png",
        "externalLink": "",
        "type": "image/png",
        "size": 1024
      }
    ]
  }
}
```

#### 获取备忘录列表

**端点**: `GET /api/v2/memos`

**描述**: 分页获取备忘录列表

**查询参数**:
- `pageSize`: 每页大小
- `pageToken`: 分页标记
- `filter`: 过滤条件，例如 `creator == users/1 && visibilities == ["PUBLIC", "PROTECTED"]`

**响应**:
```json
{
  "memos": [
    {
      "name": "memos/1",
      "uid": "unique-id-1",
      "rowStatus": "NORMAL",
      "creator": "users/1",
      "createTime": "2022-01-01T00:00:00Z",
      "updateTime": "2022-01-01T00:00:00Z",
      "displayTime": "2022-01-01T00:00:00Z",
      "content": "备忘录内容 1 #tag",
      "visibility": "PUBLIC",
      "pinned": true
    },
    {
      "name": "memos/2",
      "uid": "unique-id-2",
      "rowStatus": "NORMAL",
      "creator": "users/1",
      "createTime": "2022-01-02T00:00:00Z",
      "updateTime": "2022-01-02T00:00:00Z",
      "displayTime": "2022-01-02T00:00:00Z",
      "content": "备忘录内容 2 #tag",
      "visibility": "PROTECTED",
      "pinned": false
    }
  ],
  "nextPageToken": "next-page-token"
}
```

#### 搜索备忘录

**端点**: `GET /api/v2/memos:search`

**描述**: 通过过滤条件搜索备忘录

**查询参数**:
- `filter`: 过滤条件，例如 `content ~ "搜索词" && creator == users/1`

**响应**:
```json
{
  "memos": [
    {
      "name": "memos/1",
      "uid": "unique-id-1",
      "rowStatus": "NORMAL",
      "creator": "users/1",
      "createTime": "2022-01-01T00:00:00Z",
      "updateTime": "2022-01-01T00:00:00Z",
      "displayTime": "2022-01-01T00:00:00Z",
      "content": "包含搜索词的备忘录 #tag",
      "visibility": "PUBLIC",
      "pinned": true
    }
  ]
}
```

#### 获取单个备忘录

**端点**: `GET /api/v2/{name=memos/*}`

**描述**: 获取单个备忘录

**路径参数**:
- `name`: 备忘录资源名称，格式为 `memos/{id}`

**响应**:
```json
{
  "memo": {
    "name": "memos/1",
    "uid": "unique-id-1",
    "rowStatus": "NORMAL",
    "creator": "users/1",
    "createTime": "2022-01-01T00:00:00Z",
    "updateTime": "2022-01-01T00:00:00Z",
    "displayTime": "2022-01-01T00:00:00Z",
    "content": "备忘录内容 #tag",
    "visibility": "PUBLIC",
    "pinned": true,
    "resources": [
      {
        "name": "resources/1",
        "filename": "image.png",
        "externalLink": "",
        "type": "image/png",
        "size": 1024
      }
    ]
  }
}
```

#### 更新备忘录

**端点**: `PATCH /api/v2/{memo.name=memos/*}`

**描述**: 更新备忘录

**路径参数**:
- `memo.name`: 备忘录资源名称，格式为 `memos/{id}`

**请求体**:
```json
{
  "memo": {
    "name": "memos/1",
    "content": "更新后的内容 #newtag",
    "visibility": "PROTECTED",
    "pinned": true
  },
  "updateMask": "content,visibility,pinned"
}
```

**响应**:
```json
{
  "memo": {
    "name": "memos/1",
    "uid": "unique-id-1",
    "rowStatus": "NORMAL",
    "creator": "users/1",
    "createTime": "2022-01-01T00:00:00Z",
    "updateTime": "2022-01-15T00:00:00Z",
    "displayTime": "2022-01-01T00:00:00Z",
    "content": "更新后的内容 #newtag",
    "visibility": "PROTECTED",
    "pinned": true
  }
}
```

#### 删除备忘录

**端点**: `DELETE /api/v2/{name=memos/*}`

**描述**: 删除备忘录

**路径参数**:
- `name`: 备忘录资源名称，格式为 `memos/{id}`

**响应**: 空响应体

#### 导出备忘录

**端点**: `POST /api/v2/memos:export`

**描述**: 导出备忘录

**请求体**:
```json
{
  "filter": "creator == users/1",
  "exportType": "MARKDOWN",  // "MARKDOWN", "JSON", "CSV", "HTML"
  "includeResources": true
}
```

**响应**:
```json
{
  "content": "导出的内容",
  "resourceList": [
    {
      "name": "resources/1",
      "filename": "image.png",
      "data": "base64编码的文件内容",
      "type": "image/png",
      "size": 1024
    }
  ]
}
```

#### 设置备忘录资源

**端点**: `POST /api/v2/{name=memos/*}/resources`

**描述**: 设置备忘录关联的资源

**路径参数**:
- `name`: 备忘录资源名称，格式为 `memos/{id}`

**请求体**:
```json
{
  "resources": [
    {
      "name": "resources/1"
    },
    {
      "name": "resources/2"
    }
  ]
}
```

**响应**:
```json
{
  "resources": [
    {
      "name": "resources/1",
      "filename": "image1.png",
      "externalLink": "",
      "type": "image/png",
      "size": 1024
    },
    {
      "name": "resources/2",
      "filename": "image2.png",
      "externalLink": "",
      "type": "image/png",
      "size": 2048
    }
  ]
}
```

#### 获取备忘录资源

**端点**: `GET /api/v2/{name=memos/*}/resources`

**描述**: 获取备忘录关联的资源

**路径参数**:
- `name`: 备忘录资源名称，格式为 `memos/{id}`

**响应**:
```json
{
  "resources": [
    {
      "name": "resources/1",
      "filename": "image1.png",
      "externalLink": "",
      "type": "image/png",
      "size": 1024
    },
    {
      "name": "resources/2",
      "filename": "image2.png",
      "externalLink": "",
      "type": "image/png",
      "size": 2048
    }
  ]
}
```

#### 设置备忘录关系

**端点**: `POST /api/v2/{name=memos/*}/relations`

**描述**: 设置备忘录与其他备忘录的关系

**路径参数**:
- `name`: 备忘录资源名称，格式为 `memos/{id}`

**请求体**:
```json
{
  "relations": [
    {
      "relatedMemo": "memos/2",
      "type": "REFERENCE"  // "REFERENCE", "COMMENT"
    }
  ]
}
```

**响应**:
```json
{
  "relations": [
    {
      "memo": "memos/1",
      "relatedMemo": "memos/2",
      "type": "REFERENCE",
      "createTime": "2022-01-15T00:00:00Z"
    }
  ]
}
```

#### 获取备忘录关系

**端点**: `GET /api/v2/{name=memos/*}/relations`

**描述**: 获取备忘录与其他备忘录的关系

**路径参数**:
- `name`: 备忘录资源名称，格式为 `memos/{id}`

**响应**:
```json
{
  "relations": [
    {
      "memo": "memos/1",
      "relatedMemo": "memos/2",
      "type": "REFERENCE",
      "createTime": "2022-01-15T00:00:00Z"
    }
  ]
}
```

## 资源管理

### API v1 资源

#### 获取资源列表

**端点**: `GET /api/v1/resource`

**描述**: 获取资源列表

**查询参数**:
- `creatorId`: 创建者 ID
- `filename`: 文件名

**响应**:
```json
[
  {
    "id": 1,
    "creatorId": 1,
    "createdTs": 1640995200000,
    "updatedTs": 1640995200000,
    "filename": "image.png",
    "externalLink": "",
    "type": "image/png",
    "size": 1024
  },
  {
    "id": 2,
    "creatorId": 1,
    "createdTs": 1641095200000,
    "updatedTs": 1641095200000,
    "filename": "document.pdf",
    "externalLink": "",
    "type": "application/pdf",
    "size": 10240
  }
]
```

#### 创建资源

**端点**: `POST /api/v1/resource`

**描述**: 创建资源记录

**请求体**:
```json
{
  "filename": "external-image.jpg",
  "externalLink": "https://example.com/image.jpg",
  "type": "image/jpeg"
}
```

**响应**: 创建的资源对象

#### 上传资源

**端点**: `POST /api/v1/resource/blob`

**描述**: 上传文件资源

**请求头**:
- `Content-Type`: `multipart/form-data`

**表单字段**:
- `file`: 文件

**响应**: 创建的资源对象

**错误响应