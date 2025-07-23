# memos API
A privacy-first, lightweight note-taking service.

## Version: 1.0

**Contact information:**  
API Support  
https://github.com/orgs/usememos/discussions  

**License:** [MIT License](https://github.com/usememos/memos/blob/main/LICENSE)

[Find out more about Memos.](https://usememos.com/)

---
### /api/v1/auth/signin

#### POST
##### Summary

Sign-in to memos.

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Sign-in object | Yes | [github_com_usememos_memos_api_v1.SignIn](#github_com_usememos_memos_api_v1signin) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | User information | [store.User](#storeuser) |
| 400 | Malformatted signin request |  |
| 401 | Password login is deactivated \| Incorrect login credentials, please try again |  |
| 403 | User has been archived with username %s |  |
| 500 | Failed to find system setting \| Failed to unmarshal system setting \| Incorrect login credentials, please try again \| Failed to generate tokens \| Failed to create activity |  |

### /api/v1/auth/signin/sso

#### POST
##### Summary

Sign-in to memos using SSO.

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | SSO sign-in object | Yes | [github_com_usememos_memos_api_v1.SSOSignIn](#github_com_usememos_memos_api_v1ssosignin) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | User information | [store.User](#storeuser) |
| 400 | Malformatted signin request |  |
| 401 | Access denied, identifier does not match the filter. |  |
| 403 | User has been archived with username {username} |  |
| 404 | Identity provider not found |  |
| 500 | Failed to find identity provider \| Failed to create identity provider instance \| Failed to exchange token \| Failed to get user info \| Failed to compile identifier filter \| Incorrect login credentials, please try again \| Failed to generate random password \| Failed to generate password hash \| Failed to create user \| Failed to generate tokens \| Failed to create activity |  |

### /api/v1/auth/signout

#### POST
##### Summary

Sign-out from memos.

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Sign-out success | boolean |

### /api/v1/auth/signup

#### POST
##### Summary

Sign-up to memos.

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Sign-up object | Yes | [github_com_usememos_memos_api_v1.SignUp](#github_com_usememos_memos_api_v1signup) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | User information | [store.User](#storeuser) |
| 400 | Malformatted signup request \| Failed to find users |  |
| 401 | signup is disabled |  |
| 403 | Forbidden |  |
| 404 | Not found |  |
| 500 | Failed to find system setting \| Failed to unmarshal system setting allow signup \| Failed to generate password hash \| Failed to create user \| Failed to generate tokens \| Failed to create activity |  |

---
### /api/v1/idp

#### GET
##### Summary

Get a list of identity providers

##### Description

*clientSecret is only available for host user

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | List of available identity providers | [ [api_v1.IdentityProvider](#api_v1identityprovider) ] |
| 500 | Failed to find identity provider list \| Failed to find user |  |

#### POST
##### Summary

Create Identity Provider

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Identity provider information | Yes | [api_v1.CreateIdentityProviderRequest](#api_v1createidentityproviderrequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Identity provider information | [store.IdentityProvider](#storeidentityprovider) |
| 400 | Malformatted post identity provider request |  |
| 401 | Missing user in session \| Unauthorized |  |
| 500 | Failed to find user \| Failed to create identity provider |  |

### /api/v1/idp/{idpId}

#### DELETE
##### Summary

Delete an identity provider by ID

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| idpId | path | Identity Provider ID | Yes | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Identity Provider deleted | boolean |
| 400 | ID is not a number: %s \| Malformatted patch identity provider request |  |
| 401 | Missing user in session \| Unauthorized |  |
| 500 | Failed to find user \| Failed to patch identity provider |  |

#### GET
##### Summary

Get an identity provider by ID

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| idpId | path | Identity provider ID | Yes | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Requested identity provider | [store.IdentityProvider](#storeidentityprovider) |
| 400 | ID is not a number: %s |  |
| 401 | Missing user in session \| Unauthorized |  |
| 404 | Identity provider not found |  |
| 500 | Failed to find identity provider list \| Failed to find user |  |

#### PATCH
##### Summary

Update an identity provider by ID

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| idpId | path | Identity Provider ID | Yes | integer |
| body | body | Patched identity provider information | Yes | [api_v1.UpdateIdentityProviderRequest](#api_v1updateidentityproviderrequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Patched identity provider | [store.IdentityProvider](#storeidentityprovider) |
| 400 | ID is not a number: %s \| Malformatted patch identity provider request |  |
| 401 | Missing user in session \| Unauthorized |  |
| 500 | Failed to find user \| Failed to patch identity provider |  |

---
### /api/v1/memo

#### GET
##### Summary

Get a list of memos matching optional filters

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| creatorId | query | Creator ID | No | integer |
| creatorUsername | query | Creator username | No | string |
| rowStatus | query | Row status | No | string |
| pinned | query | Pinned | No | boolean |
| tag | query | Search for tag. Do not append # | No | string |
| content | query | Search for content | No | string |
| limit | query | Limit | No | integer |
| offset | query | Offset | No | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Memo list | [ [store.Memo](#storememo) ] |
| 400 | Missing user to find memo |  |
| 500 | Failed to get memo display with updated ts setting value \| Failed to fetch memo list \| Failed to compose memo response |  |

#### POST
##### Summary

Create a memo

##### Description

Visibility can be PUBLIC, PROTECTED or PRIVATE
*You should omit fields to use their default values

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Request object. | Yes | [github_com_usememos_memos_api_v1.CreateMemoRequest](#github_com_usememos_memos_api_v1creatememorequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Stored memo | [store.Memo](#storememo) |
| 400 | Malformatted post memo request \| Content size overflow, up to 1MB |  |
| 401 | Missing user in session |  |
| 404 | User not found \| Memo not found: %d |  |
| 500 | Failed to find user setting \| Failed to unmarshal user setting value \| Failed to find system setting \| Failed to unmarshal system setting \| Failed to find user \| Failed to create memo \| Failed to create activity \| Failed to upsert memo resource \| Failed to upsert memo relation \| Failed to compose memo \| Failed to compose memo response |  |

### /api/v1/memo/{memoId}

#### DELETE
##### Summary

Delete memo by ID

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| memoId | path | Memo ID to delete | Yes | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Memo deleted | boolean |
| 400 | ID is not a number: %s |  |
| 401 | Missing user in session \| Unauthorized |  |
| 404 | Memo not found: %d |  |
| 500 | Failed to find memo \| Failed to delete memo ID: %v |  |

#### GET
##### Summary

Get memo by ID

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| memoId | path | Memo ID | Yes | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Memo list | [ [store.Memo](#storememo) ] |
| 400 | ID is not a number: %s |  |
| 401 | Missing user in session |  |
| 403 | this memo is private only \| this memo is protected, missing user in session |  |
| 404 | Memo not found: %d |  |
| 500 | Failed to find memo by ID: %v \| Failed to compose memo response |  |

#### PATCH
##### Summary

Update a memo

##### Description

Visibility can be PUBLIC, PROTECTED or PRIVATE
*You should omit fields to use their default values

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| memoId | path | ID of memo to update | Yes | integer |
| body | body | Patched object. | Yes | [github_com_usememos_memos_api_v1.PatchMemoRequest](#github_com_usememos_memos_api_v1patchmemorequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Stored memo | [store.Memo](#storememo) |
| 400 | ID is not a number: %s \| Malformatted patch memo request \| Content size overflow, up to 1MB |  |
| 401 | Missing user in session \| Unauthorized |  |
| 404 | Memo not found: %d |  |
| 500 | Failed to find memo \| Failed to patch memo \| Failed to upsert memo resource \| Failed to delete memo resource \| Failed to compose memo response |  |

### /api/v1/memo/all

#### GET
##### Summary

Get a list of public memos matching optional filters

##### Description

This should also list protected memos if the user is logged in
Authentication is optional

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| limit | query | Limit | No | integer |
| offset | query | Offset | No | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Memo list | [ [store.Memo](#storememo) ] |
| 500 | Failed to get memo display with updated ts setting value \| Failed to fetch all memo list \| Failed to compose memo response |  |

### /api/v1/memo/stats

#### GET
##### Summary

Get memo stats by creator ID or username

##### Description

Used to generate the heatmap

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| creatorId | query | Creator ID | No | integer |
| creatorUsername | query | Creator username | No | string |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Memo createdTs list | [ integer ] |
| 400 | Missing user id to find memo |  |
| 500 | Failed to get memo display with updated ts setting value \| Failed to find memo list \| Failed to compose memo response |  |

---
### /api/v1/memo/{memoId}/organizer

#### POST
##### Summary

Organize memo (pin/unpin)

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| memoId | path | ID of memo to organize | Yes | integer |
| body | body | Memo organizer object | Yes | [github_com_usememos_memos_api_v1.UpsertMemoOrganizerRequest](#github_com_usememos_memos_api_v1upsertmemoorganizerrequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Memo information | [store.Memo](#storememo) |
| 400 | ID is not a number: %s \| Malformatted post memo organizer request |  |
| 401 | Missing user in session \| Unauthorized |  |
| 404 | Memo not found: %v |  |
| 500 | Failed to find memo \| Failed to upsert memo organizer \| Failed to find memo by ID: %v \| Failed to compose memo response |  |

---
### /api/v1/memo/{memoId}/relation

#### GET
##### Summary

Get a list of Memo Relations

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| memoId | path | ID of memo to find relations | Yes | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Memo relation information list | [ [store.MemoRelation](#storememorelation) ] |
| 400 | ID is not a number: %s |  |
| 500 | Failed to list memo relations |  |

#### POST
##### Summary

Create Memo Relation

##### Description

Create a relation between two memos

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| memoId | path | ID of memo to relate | Yes | integer |
| body | body | Memo relation object | Yes | [github_com_usememos_memos_api_v1.UpsertMemoRelationRequest](#github_com_usememos_memos_api_v1upsertmemorelationrequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Memo relation information | [store.MemoRelation](#storememorelation) |
| 400 | ID is not a number: %s \| Malformatted post memo relation request |  |
| 500 | Failed to upsert memo relation |  |

### /api/v1/memo/{memoId}/relation/{relatedMemoId}/type/{relationType}

#### DELETE
##### Summary

Delete a Memo Relation

##### Description

Removes a relation between two memos

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| memoId | path | ID of memo to find relations | Yes | integer |
| relatedMemoId | path | ID of memo to remove relation to | Yes | integer |
| relationType | path | Type of relation to remove | Yes | string |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Memo relation deleted | boolean |
| 400 | Memo ID is not a number: %s \| Related memo ID is not a number: %s |  |
| 500 | Failed to delete memo relation |  |

---
### /api/v1/ping

#### GET
##### Summary

Ping the system

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | If succeed to ping the system | boolean |

### /api/v1/status

#### GET
##### Summary

Get system GetSystemStatus

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | System GetSystemStatus | [api_v1.SystemStatus](#api_v1systemstatus) |
| 401 | Missing user in session \| Unauthorized |  |
| 500 | Failed to find host user \| Failed to find system setting list \| Failed to unmarshal system setting customized profile value |  |

### /api/v1/system/vacuum

#### POST
##### Summary

Vacuum the database

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Database vacuumed | boolean |
| 401 | Missing user in session \| Unauthorized |  |
| 500 | Failed to find user \| Failed to ExecVacuum database |  |

---
### /api/v1/resource

#### GET
##### Summary

Get a list of resources

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| limit | query | Limit | No | integer |
| offset | query | Offset | No | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Resource list | [ [store.Resource](#storeresource) ] |
| 401 | Missing user in session |  |
| 500 | Failed to fetch resource list |  |

#### POST
##### Summary

Create resource

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Request object. | Yes | [api_v1.CreateResourceRequest](#api_v1createresourcerequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Created resource | [store.Resource](#storeresource) |
| 400 | Malformatted post resource request \| Invalid external link \| Invalid external link scheme \| Failed to request %s \| Failed to read %s \| Failed to read mime from %s |  |
| 401 | Missing user in session |  |
| 500 | Failed to save resource \| Failed to create resource \| Failed to create activity |  |

### /api/v1/resource/{resourceId}

#### DELETE
##### Summary

Delete a resource

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| resourceId | path | Resource ID | Yes | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Resource deleted | boolean |
| 400 | ID is not a number: %s |  |
| 401 | Missing user in session |  |
| 404 | Resource not found: %d |  |
| 500 | Failed to find resource \| Failed to delete resource |  |

#### PATCH
##### Summary

Update a resource

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| resourceId | path | Resource ID | Yes | integer |
| patch | body | Patch resource request | Yes | [api_v1.UpdateResourceRequest](#api_v1updateresourcerequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Updated resource | [store.Resource](#storeresource) |
| 400 | ID is not a number: %s \| Malformatted patch resource request |  |
| 401 | Missing user in session \| Unauthorized |  |
| 404 | Resource not found: %d |  |
| 500 | Failed to find resource \| Failed to patch resource |  |

### /api/v1/resource/blob

#### POST
##### Summary

Upload resource

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| file | formData | File to upload | Yes | file |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Created resource | [store.Resource](#storeresource) |
| 400 | Upload file not found \| File size exceeds allowed limit of %d MiB \| Failed to parse upload data |  |
| 401 | Missing user in session |  |
| 500 | Failed to get uploading file \| Failed to open file \| Failed to save resource \| Failed to create resource \| Failed to create activity |  |

---
### /api/v1/storage

#### GET
##### Summary

Get a list of storages

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | List of storages | [ [store.Storage](#storestorage) ] |
| 401 | Missing user in session \| Unauthorized |  |
| 500 | Failed to find user \| Failed to convert storage |  |

#### POST
##### Summary

Create storage

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Request object. | Yes | [github_com_usememos_memos_api_v1.CreateStorageRequest](#github_com_usememos_memos_api_v1createstoragerequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Created storage | [store.Storage](#storestorage) |
| 400 | Malformatted post storage request |  |
| 401 | Missing user in session |  |
| 500 | Failed to find user \| Failed to create storage \| Failed to convert storage |  |

### /api/v1/storage/{storageId}

#### DELETE
##### Summary

Delete a storage

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| storageId | path | Storage ID | Yes | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Storage deleted | boolean |
| 400 | ID is not a number: %s \| Storage service %d is using |  |
| 401 | Missing user in session \| Unauthorized |  |
| 500 | Failed to find user \| Failed to find storage \| Failed to unmarshal storage service id \| Failed to delete storage |  |

#### PATCH
##### Summary

Update a storage

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| storageId | path | Storage ID | Yes | integer |
| patch | body | Patch request | Yes | [github_com_usememos_memos_api_v1.UpdateStorageRequest](#github_com_usememos_memos_api_v1updatestoragerequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Updated resource | [store.Storage](#storestorage) |
| 400 | ID is not a number: %s \| Malformatted patch storage request \| Malformatted post storage request |  |
| 401 | Missing user in session \| Unauthorized |  |
| 500 | Failed to find user \| Failed to patch storage \| Failed to convert storage |  |

---
### /api/v1/system/setting

#### GET
##### Summary

Get a list of system settings

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | System setting list | [ [api_v1.SystemSetting](#api_v1systemsetting) ] |
| 401 | Missing user in session \| Unauthorized |  |
| 500 | Failed to find user \| Failed to find system setting list |  |

#### POST
##### Summary

Create system setting

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Request object. | Yes | [api_v1.UpsertSystemSettingRequest](#api_v1upsertsystemsettingrequest) |

##### Responses

| Code | Description |
| ---- | ----------- |
| 400 | Malformatted post system setting request \| invalid system setting |
| 401 | Missing user in session \| Unauthorized |
| 403 | Cannot disable passwords if no SSO identity provider is configured. |
| 500 | Failed to find user \| Failed to upsert system setting |

---
### /api/v1/tag

#### GET
##### Summary

Get a list of tags

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Tag list | [ string ] |
| 400 | Missing user id to find tag |  |
| 500 | Failed to find tag list |  |

#### POST
##### Summary

Create a tag

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Request object. | Yes | [github_com_usememos_memos_api_v1.UpsertTagRequest](#github_com_usememos_memos_api_v1upserttagrequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Created tag name | string |
| 400 | Malformatted post tag request \| Tag name shouldn't be empty |  |
| 401 | Missing user in session |  |
| 500 | Failed to upsert tag \| Failed to create activity |  |

### /api/v1/tag/delete

#### POST
##### Summary

Delete a tag

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Request object. | Yes | [github_com_usememos_memos_api_v1.DeleteTagRequest](#github_com_usememos_memos_api_v1deletetagrequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Tag deleted | boolean |
| 400 | Malformatted post tag request \| Tag name shouldn't be empty |  |
| 401 | Missing user in session |  |
| 500 | Failed to delete tag name: %v |  |

### /api/v1/tag/suggestion

#### GET
##### Summary

Get a list of tags suggested from other memos contents

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Tag list | [ string ] |
| 400 | Missing user session |  |
| 500 | Failed to find memo list \| Failed to find tag list |  |

---
### /api/v1/user

#### GET
##### Summary

Get a list of users

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | User list | [ [store.User](#storeuser) ] |
| 500 | Failed to fetch user list |  |

#### POST
##### Summary

Create a user

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| body | body | Request object | Yes | [api_v1.CreateUserRequest](#api_v1createuserrequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Created user | [store.User](#storeuser) |
| 400 | Malformatted post user request \| Invalid user create format |  |
| 401 | Missing auth session \| Unauthorized to create user |  |
| 403 | Could not create host user |  |
| 500 | Failed to find user by id \| Failed to generate password hash \| Failed to create user \| Failed to create activity |  |

### /api/v1/user/{id}

#### DELETE
##### Summary

Delete a user

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| id | path | User ID | Yes | string |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | User deleted | boolean |
| 400 | ID is not a number: %s \| Current session user not found with ID: %d |  |
| 401 | Missing user in session |  |
| 403 | Unauthorized to delete user |  |
| 500 | Failed to find user \| Failed to delete user |  |

#### GET
##### Summary

Get user by id

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| id | path | User ID | Yes | integer |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Requested user | [store.User](#storeuser) |
| 400 | Malformatted user id |  |
| 404 | User not found |  |
| 500 | Failed to find user |  |

#### PATCH
##### Summary

Update a user

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| id | path | User ID | Yes | string |
| patch | body | Patch request | Yes | [api_v1.UpdateUserRequest](#api_v1updateuserrequest) |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Updated user | [store.User](#storeuser) |
| 400 | ID is not a number: %s \| Current session user not found with ID: %d \| Malformatted patch user request \| Invalid update user request |  |
| 401 | Missing user in session |  |
| 403 | Unauthorized to update user |  |
| 500 | Failed to find user \| Failed to generate password hash \| Failed to patch user \| Failed to find userSettingList |  |

### /api/v1/user/me

#### GET
##### Summary

Get current user

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Current user | [store.User](#storeuser) |
| 401 | Missing auth session |  |
| 500 | Failed to find user \| Failed to find userSettingList |  |

### /api/v1/user/name/{username}

#### GET
##### Summary

Get user by username

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| username | path | Username | Yes | string |

##### Responses

| Code | Description | Schema |
| ---- | ----------- | ------ |
| 200 | Requested user | [store.User](#storeuser) |
| 404 | User not found |  |
| 500 | Failed to find user |  |

---
### /o/get/GetImage

#### GET
##### Summary

Get GetImage from URL

##### Parameters

| Name | Located in | Description | Required | Schema |
| ---- | ---------- | ----------- | -------- | ------ |
| url | query | Image url | Yes | string |

##### Responses

| Code | Description |
| ---- | ----------- |
| 200 | Image |
| 400 | Missing GetImage url \| Wrong url \| Failed to get GetImage url: %s |
| 500 | Failed to write GetImage blob |

---
### Models

#### api_v1.CreateIdentityProviderRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [api_v1.IdentityProviderConfig](#api_v1identityproviderconfig) |  | No |
| identifierFilter | string |  | No |
| name | string |  | No |
| type | [api_v1.IdentityProviderType](#api_v1identityprovidertype) |  | No |

#### api_v1.CreateMemoRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| content | string |  | No |
| createdTs | integer |  | No |
| relationList | [ [api_v1.UpsertMemoRelationRequest](#api_v1upsertmemorelationrequest) ] |  | No |
| resourceIdList | [ integer ] | Related fields | No |
| visibility | [api_v1.Visibility](#api_v1visibility) | Domain specific fields | No |

#### api_v1.CreateResourceRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| externalLink | string |  | No |
| filename | string |  | No |
| type | string |  | No |

#### api_v1.CreateStorageRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [api_v1.StorageConfig](#api_v1storageconfig) |  | No |
| name | string |  | No |
| type | [api_v1.StorageType](#api_v1storagetype) |  | No |

#### api_v1.CreateUserRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| email | string |  | No |
| nickname | string |  | No |
| password | string |  | No |
| role | [api_v1.Role](#api_v1role) |  | No |
| username | string |  | No |

#### api_v1.CustomizedProfile

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| appearance | string | Appearance is the server default appearance. | No |
| description | string | Description is the server description. | No |
| locale | string | Locale is the server default locale. | No |
| logoUrl | string | LogoURL is the url of logo image. | No |
| name | string | Name is the server name, default is `memos` | No |

#### api_v1.DeleteTagRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| name | string |  | No |

#### api_v1.FieldMapping

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| displayName | string |  | No |
| email | string |  | No |
| identifier | string |  | No |

#### api_v1.IdentityProvider

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [api_v1.IdentityProviderConfig](#api_v1identityproviderconfig) |  | No |
| id | integer |  | No |
| identifierFilter | string |  | No |
| name | string |  | No |
| type | [api_v1.IdentityProviderType](#api_v1identityprovidertype) |  | No |

#### api_v1.IdentityProviderConfig

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| oauth2Config | [api_v1.IdentityProviderOAuth2Config](#api_v1identityprovideroauth2config) |  | No |

#### api_v1.IdentityProviderOAuth2Config

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| authUrl | string |  | No |
| clientId | string |  | No |
| clientSecret | string |  | No |
| fieldMapping | [api_v1.FieldMapping](#api_v1fieldmapping) |  | No |
| scopes | [ string ] |  | No |
| tokenUrl | string |  | No |
| userInfoUrl | string |  | No |

#### api_v1.IdentityProviderType

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| api_v1.IdentityProviderType | string |  |  |

#### api_v1.MemoRelationType

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| api_v1.MemoRelationType | string |  |  |

#### api_v1.PatchMemoRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| content | string | Domain specific fields | No |
| createdTs | integer | Standard fields | No |
| relationList | [ [api_v1.UpsertMemoRelationRequest](#api_v1upsertmemorelationrequest) ] |  | No |
| resourceIdList | [ integer ] | Related fields | No |
| rowStatus | [api_v1.RowStatus](#api_v1rowstatus) |  | No |
| updatedTs | integer |  | No |
| visibility | [api_v1.Visibility](#api_v1visibility) |  | No |

#### api_v1.Role

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| api_v1.Role | string |  |  |

#### api_v1.RowStatus

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| api_v1.RowStatus | string |  |  |

#### api_v1.SSOSignIn

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| code | string |  | No |
| identityProviderId | integer |  | No |
| redirectUri | string |  | No |

#### api_v1.SignIn

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| password | string |  | No |
| remember | boolean |  | No |
| username | string |  | No |

#### api_v1.SignUp

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| password | string |  | No |
| username | string |  | No |

#### api_v1.StorageConfig

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| s3Config | [api_v1.StorageS3Config](#api_v1storages3config) |  | No |

#### api_v1.StorageS3Config

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| accessKey | string |  | No |
| bucket | string |  | No |
| endPoint | string |  | No |
| path | string |  | No |
| presign | boolean |  | No |
| region | string |  | No |
| secretKey | string |  | No |
| urlPrefix | string |  | No |
| urlSuffix | string |  | No |

#### api_v1.StorageType

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| api_v1.StorageType | string |  |  |

#### api_v1.SystemSetting

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| description | string |  | No |
| name | [api_v1.SystemSettingName](#api_v1systemsettingname) |  | No |
| value | string | Value is a JSON string with basic value. | No |

#### api_v1.SystemSettingName

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| api_v1.SystemSettingName | string |  |  |

#### api_v1.SystemStatus

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| additionalScript | string | Additional script. | No |
| additionalStyle | string | Additional style. | No |
| allowSignUp | boolean | System settings Allow sign up. | No |
| customizedProfile | [api_v1.CustomizedProfile](#api_v1customizedprofile) | Customized server profile, including server name and external url. | No |
| dbSize | integer |  | No |
| disablePasswordLogin | boolean | Disable password login. | No |
| disablePublicMemos | boolean | Disable public memos. | No |
| host | [api_v1.User](#api_v1user) |  | No |
| localStoragePath | string | Local storage path. | No |
| maxUploadSizeMiB | integer | Max upload size. | No |
| memoDisplayWithUpdatedTs | boolean | Memo display with updated timestamp. | No |
| profile | [profile.Profile](#profileprofile) |  | No |
| storageServiceId | integer | Storage service ID. | No |

#### api_v1.UpdateIdentityProviderRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [api_v1.IdentityProviderConfig](#api_v1identityproviderconfig) |  | No |
| identifierFilter | string |  | No |
| name | string |  | No |
| type | [api_v1.IdentityProviderType](#api_v1identityprovidertype) |  | No |

#### api_v1.UpdateResourceRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| filename | string |  | No |

#### api_v1.UpdateStorageRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [api_v1.StorageConfig](#api_v1storageconfig) |  | No |
| name | string |  | No |
| type | [api_v1.StorageType](#api_v1storagetype) |  | No |

#### api_v1.UpdateUserRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| avatarUrl | string |  | No |
| email | string |  | No |
| nickname | string |  | No |
| password | string |  | No |
| rowStatus | [api_v1.RowStatus](#api_v1rowstatus) |  | No |
| username | string |  | No |

#### api_v1.UpsertMemoOrganizerRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| pinned | boolean |  | No |

#### api_v1.UpsertMemoRelationRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| relatedMemoId | integer |  | No |
| type | [api_v1.MemoRelationType](#api_v1memorelationtype) |  | No |

#### api_v1.UpsertSystemSettingRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| description | string |  | No |
| name | [api_v1.SystemSettingName](#api_v1systemsettingname) |  | No |
| value | string |  | No |

#### api_v1.UpsertTagRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| name | string |  | No |

#### api_v1.User

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| avatarUrl | string |  | No |
| createdTs | integer |  | No |
| email | string |  | No |
| id | integer |  | No |
| nickname | string |  | No |
| role | [api_v1.Role](#api_v1role) |  | No |
| rowStatus | [api_v1.RowStatus](#api_v1rowstatus) | Standard fields | No |
| updatedTs | integer |  | No |
| username | string | Domain specific fields | No |

#### api_v1.Visibility

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| api_v1.Visibility | string |  |  |

#### github_com_usememos_memos_api_v1.CreateIdentityProviderRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [github_com_usememos_memos_api_v1.IdentityProviderConfig](#github_com_usememos_memos_api_v1identityproviderconfig) |  | No |
| identifierFilter | string |  | No |
| name | string |  | No |
| type | [github_com_usememos_memos_api_v1.IdentityProviderType](#github_com_usememos_memos_api_v1identityprovidertype) |  | No |

#### github_com_usememos_memos_api_v1.CreateMemoRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| content | string |  | No |
| createdTs | integer |  | No |
| relationList | [ [github_com_usememos_memos_api_v1.UpsertMemoRelationRequest](#github_com_usememos_memos_api_v1upsertmemorelationrequest) ] |  | No |
| resourceIdList | [ integer ] | Related fields | No |
| visibility | [github_com_usememos_memos_api_v1.Visibility](#github_com_usememos_memos_api_v1visibility) | Domain specific fields | No |

#### github_com_usememos_memos_api_v1.CreateResourceRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| externalLink | string |  | No |
| filename | string |  | No |
| type | string |  | No |

#### github_com_usememos_memos_api_v1.CreateStorageRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [github_com_usememos_memos_api_v1.StorageConfig](#github_com_usememos_memos_api_v1storageconfig) |  | No |
| name | string |  | No |
| type | [github_com_usememos_memos_api_v1.StorageType](#github_com_usememos_memos_api_v1storagetype) |  | No |

#### github_com_usememos_memos_api_v1.CreateUserRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| email | string |  | No |
| nickname | string |  | No |
| password | string |  | No |
| role | [github_com_usememos_memos_api_v1.Role](#github_com_usememos_memos_api_v1role) |  | No |
| username | string |  | No |

#### github_com_usememos_memos_api_v1.CustomizedProfile

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| appearance | string | Appearance is the server default appearance. | No |
| description | string | Description is the server description. | No |
| locale | string | Locale is the server default locale. | No |
| logoUrl | string | LogoURL is the url of logo image. | No |
| name | string | Name is the server name, default is `memos` | No |

#### github_com_usememos_memos_api_v1.DeleteTagRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| name | string |  | No |

#### github_com_usememos_memos_api_v1.FieldMapping

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| displayName | string |  | No |
| email | string |  | No |
| identifier | string |  | No |

#### github_com_usememos_memos_api_v1.IdentityProvider

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [github_com_usememos_memos_api_v1.IdentityProviderConfig](#github_com_usememos_memos_api_v1identityproviderconfig) |  | No |
| id | integer |  | No |
| identifierFilter | string |  | No |
| name | string |  | No |
| type | [github_com_usememos_memos_api_v1.IdentityProviderType](#github_com_usememos_memos_api_v1identityprovidertype) |  | No |

#### github_com_usememos_memos_api_v1.IdentityProviderConfig

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| oauth2Config | [github_com_usememos_memos_api_v1.IdentityProviderOAuth2Config](#github_com_usememos_memos_api_v1identityprovideroauth2config) |  | No |

#### github_com_usememos_memos_api_v1.IdentityProviderOAuth2Config

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| authUrl | string |  | No |
| clientId | string |  | No |
| clientSecret | string |  | No |
| fieldMapping | [github_com_usememos_memos_api_v1.FieldMapping](#github_com_usememos_memos_api_v1fieldmapping) |  | No |
| scopes | [ string ] |  | No |
| tokenUrl | string |  | No |
| userInfoUrl | string |  | No |

#### github_com_usememos_memos_api_v1.IdentityProviderType

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| github_com_usememos_memos_api_v1.IdentityProviderType | string |  |  |

#### github_com_usememos_memos_api_v1.MemoRelationType

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| github_com_usememos_memos_api_v1.MemoRelationType | string |  |  |

#### github_com_usememos_memos_api_v1.PatchMemoRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| content | string | Domain specific fields | No |
| createdTs | integer | Standard fields | No |
| relationList | [ [github_com_usememos_memos_api_v1.UpsertMemoRelationRequest](#github_com_usememos_memos_api_v1upsertmemorelationrequest) ] |  | No |
| resourceIdList | [ integer ] | Related fields | No |
| rowStatus | [github_com_usememos_memos_api_v1.RowStatus](#github_com_usememos_memos_api_v1rowstatus) |  | No |
| updatedTs | integer |  | No |
| visibility | [github_com_usememos_memos_api_v1.Visibility](#github_com_usememos_memos_api_v1visibility) |  | No |

#### github_com_usememos_memos_api_v1.Role

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| github_com_usememos_memos_api_v1.Role | string |  |  |

#### github_com_usememos_memos_api_v1.RowStatus

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| github_com_usememos_memos_api_v1.RowStatus | string |  |  |

#### github_com_usememos_memos_api_v1.SSOSignIn

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| code | string |  | No |
| identityProviderId | integer |  | No |
| redirectUri | string |  | No |

#### github_com_usememos_memos_api_v1.SignIn

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| password | string |  | No |
| remember | boolean |  | No |
| username | string |  | No |

#### github_com_usememos_memos_api_v1.SignUp

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| password | string |  | No |
| username | string |  | No |

#### github_com_usememos_memos_api_v1.StorageConfig

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| s3Config | [github_com_usememos_memos_api_v1.StorageS3Config](#github_com_usememos_memos_api_v1storages3config) |  | No |

#### github_com_usememos_memos_api_v1.StorageS3Config

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| accessKey | string |  | No |
| bucket | string |  | No |
| endPoint | string |  | No |
| path | string |  | No |
| presign | boolean |  | No |
| region | string |  | No |
| secretKey | string |  | No |
| urlPrefix | string |  | No |
| urlSuffix | string |  | No |

#### github_com_usememos_memos_api_v1.StorageType

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| github_com_usememos_memos_api_v1.StorageType | string |  |  |

#### github_com_usememos_memos_api_v1.SystemSetting

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| description | string |  | No |
| name | [github_com_usememos_memos_api_v1.SystemSettingName](#github_com_usememos_memos_api_v1systemsettingname) |  | No |
| value | string | Value is a JSON string with basic value. | No |

#### github_com_usememos_memos_api_v1.SystemSettingName

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| github_com_usememos_memos_api_v1.SystemSettingName | string |  |  |

#### github_com_usememos_memos_api_v1.SystemStatus

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| additionalScript | string | Additional script. | No |
| additionalStyle | string | Additional style. | No |
| allowSignUp | boolean | System settings Allow sign up. | No |
| customizedProfile | [github_com_usememos_memos_api_v1.CustomizedProfile](#github_com_usememos_memos_api_v1customizedprofile) | Customized server profile, including server name and external url. | No |
| dbSize | integer |  | No |
| disablePasswordLogin | boolean | Disable password login. | No |
| disablePublicMemos | boolean | Disable public memos. | No |
| host | [github_com_usememos_memos_api_v1.User](#github_com_usememos_memos_api_v1user) |  | No |
| localStoragePath | string | Local storage path. | No |
| maxUploadSizeMiB | integer | Max upload size. | No |
| memoDisplayWithUpdatedTs | boolean | Memo display with updated timestamp. | No |
| profile | [profile.Profile](#profileprofile) |  | No |
| storageServiceId | integer | Storage service ID. | No |

#### github_com_usememos_memos_api_v1.UpdateIdentityProviderRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [github_com_usememos_memos_api_v1.IdentityProviderConfig](#github_com_usememos_memos_api_v1identityproviderconfig) |  | No |
| identifierFilter | string |  | No |
| name | string |  | No |
| type | [github_com_usememos_memos_api_v1.IdentityProviderType](#github_com_usememos_memos_api_v1identityprovidertype) |  | No |

#### github_com_usememos_memos_api_v1.UpdateResourceRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| filename | string |  | No |

#### github_com_usememos_memos_api_v1.UpdateStorageRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [github_com_usememos_memos_api_v1.StorageConfig](#github_com_usememos_memos_api_v1storageconfig) |  | No |
| name | string |  | No |
| type | [github_com_usememos_memos_api_v1.StorageType](#github_com_usememos_memos_api_v1storagetype) |  | No |

#### github_com_usememos_memos_api_v1.UpdateUserRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| avatarUrl | string |  | No |
| email | string |  | No |
| nickname | string |  | No |
| password | string |  | No |
| rowStatus | [github_com_usememos_memos_api_v1.RowStatus](#github_com_usememos_memos_api_v1rowstatus) |  | No |
| username | string |  | No |

#### github_com_usememos_memos_api_v1.UpsertMemoOrganizerRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| pinned | boolean |  | No |

#### github_com_usememos_memos_api_v1.UpsertMemoRelationRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| relatedMemoId | integer |  | No |
| type | [github_com_usememos_memos_api_v1.MemoRelationType](#github_com_usememos_memos_api_v1memorelationtype) |  | No |

#### github_com_usememos_memos_api_v1.UpsertSystemSettingRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| description | string |  | No |
| name | [github_com_usememos_memos_api_v1.SystemSettingName](#github_com_usememos_memos_api_v1systemsettingname) |  | No |
| value | string |  | No |

#### github_com_usememos_memos_api_v1.UpsertTagRequest

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| name | string |  | No |

#### github_com_usememos_memos_api_v1.User

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| avatarUrl | string |  | No |
| createdTs | integer |  | No |
| email | string |  | No |
| id | integer |  | No |
| nickname | string |  | No |
| role | [github_com_usememos_memos_api_v1.Role](#github_com_usememos_memos_api_v1role) |  | No |
| rowStatus | [github_com_usememos_memos_api_v1.RowStatus](#github_com_usememos_memos_api_v1rowstatus) | Standard fields | No |
| updatedTs | integer |  | No |
| username | string | Domain specific fields | No |

#### github_com_usememos_memos_api_v1.Visibility

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| github_com_usememos_memos_api_v1.Visibility | string |  |  |

#### profile.Profile

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| mode | string | Mode can be "prod" or "dev" or "demo" | No |
| version | string | Version is the current version of server | No |

#### store.FieldMapping

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| displayName | string |  | No |
| email | string |  | No |
| identifier | string |  | No |

#### store.IdentityProvider

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | [store.IdentityProviderConfig](#storeidentityproviderconfig) |  | No |
| id | integer |  | No |
| identifierFilter | string |  | No |
| name | string |  | No |
| type | [store.IdentityProviderType](#storeidentityprovidertype) |  | No |

#### store.IdentityProviderConfig

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| oauth2Config | [store.IdentityProviderOAuth2Config](#storeidentityprovideroauth2config) |  | No |

#### store.IdentityProviderOAuth2Config

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| authUrl | string |  | No |
| clientId | string |  | No |
| clientSecret | string |  | No |
| fieldMapping | [store.FieldMapping](#storefieldmapping) |  | No |
| scopes | [ string ] |  | No |
| tokenUrl | string |  | No |
| userInfoUrl | string |  | No |

#### store.IdentityProviderType

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| store.IdentityProviderType | string |  |  |

#### store.Memo

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| content | string | Domain specific fields | No |
| createdTs | integer |  | No |
| creatorID | integer |  | No |
| id | integer |  | No |
| parentID | integer |  | No |
| pinned | boolean | Composed fields | No |
| resourceName | string |  | No |
| rowStatus | [store.RowStatus](#storerowstatus) | Standard fields | No |
| updatedTs | integer |  | No |
| visibility | [store.Visibility](#storevisibility) |  | No |

#### store.MemoRelation

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| memoID | integer |  | No |
| relatedMemoID | integer |  | No |
| type | [store.MemoRelationType](#storememorelationtype) |  | No |

#### store.MemoRelationType

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| store.MemoRelationType | string |  |  |

#### store.Resource

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| blob | [ integer ] |  | No |
| createdTs | integer |  | No |
| creatorID | integer | Standard fields | No |
| externalLink | string |  | No |
| filename | string | Domain specific fields | No |
| id | integer |  | No |
| internalPath | string |  | No |
| memoID | integer |  | No |
| resourceName | string |  | No |
| size | integer |  | No |
| type | string |  | No |
| updatedTs | integer |  | No |

#### store.Role

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| store.Role | string |  |  |

#### store.RowStatus

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| store.RowStatus | string |  |  |

#### store.Storage

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| config | string |  | No |
| id | integer |  | No |
| name | string |  | No |
| type | string |  | No |

#### store.User

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| avatarURL | string |  | No |
| createdTs | integer |  | No |
| email | string |  | No |
| id | integer |  | No |
| nickname | string |  | No |
| passwordHash | string |  | No |
| role | [store.Role](#storerole) |  | No |
| rowStatus | [store.RowStatus](#storerowstatus) | Standard fields | No |
| updatedTs | integer |  | No |
| username | string | Domain specific fields | No |

#### store.Visibility

| Name | Type | Description | Required |
| ---- | ---- | ----------- | -------- |
| store.Visibility | string |  |  |
