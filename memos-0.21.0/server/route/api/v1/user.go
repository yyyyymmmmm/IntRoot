package v1

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/labstack/echo/v4"
	"github.com/pkg/errors"
	"golang.org/x/crypto/bcrypt"

	"github.com/usememos/memos/internal/util"
	"github.com/usememos/memos/store"
)

// Role is the type of a role.
type Role string

const (
	// RoleHost is the HOST role.
	RoleHost Role = "HOST"
	// RoleAdmin is the ADMIN role.
	RoleAdmin Role = "ADMIN"
	// RoleUser is the USER role.
	RoleUser Role = "USER"
)

func (role Role) String() string {
	return string(role)
}

type User struct {
	ID int32 `json:"id"`

	// Standard fields
	RowStatus RowStatus `json:"rowStatus"`
	CreatedTs int64     `json:"createdTs"`
	UpdatedTs int64     `json:"updatedTs"`

	// Domain specific fields
	Username     string `json:"username"`
	Role         Role   `json:"role"`
	Email        string `json:"email"`
	Nickname     string `json:"nickname"`
	PasswordHash string `json:"-"`
	AvatarURL    string `json:"avatarUrl"`
}

type CreateUserRequest struct {
	Username string `json:"username"`
	Role     Role   `json:"role"`
	Email    string `json:"email"`
	Nickname string `json:"nickname"`
	Password string `json:"password"`
}

type UpdateUserRequest struct {
	RowStatus *RowStatus `json:"rowStatus"`
	Username  *string    `json:"username"`
	Email     *string    `json:"email"`
	Nickname  *string    `json:"nickname"`
	Password  *string    `json:"password"`
	AvatarURL *string    `json:"avatarUrl"`
}

func (s *APIV1Service) registerUserRoutes(g *echo.Group) {
	g.GET("/user", s.GetUserList)
	g.POST("/user", s.CreateUser)
	g.GET("/user/me", s.GetCurrentUser)
	// NOTE: This should be moved to /api/v2/user/:username
	g.GET("/user/name/:username", s.GetUserByUsername)
	g.GET("/user/:id", s.GetUserByID)
	g.PATCH("/user/:id", s.UpdateUser)
	g.DELETE("/user/:id", s.DeleteUser)
}

// GetUserList godoc
//
//	@Summary	Get a list of users
//	@Tags		user
//	@Produce	json
//	@Success	200	{object}	[]store.User	"User list"
//	@Failure	500	{object}	nil				"Failed to fetch user list"
//	@Router		/api/v1/user [GET]
func (s *APIV1Service) GetUserList(c echo.Context) error {
	ctx := c.Request().Context()
	userID, ok := c.Get(userIDContextKey).(int32)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, "Missing auth session")
	}
	currentUser, err := s.Store.GetUser(ctx, &store.FindUser{
		ID: &userID,
	})
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find user by id").SetInternal(err)
	}
	if currentUser == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Missing auth session")
	}
	if currentUser.Role != store.RoleHost && currentUser.Role != store.RoleAdmin {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized to list users")
	}

	list, err := s.Store.ListUsers(ctx, &store.FindUser{})
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to fetch user list").SetInternal(err)
	}

	userMessageList := make([]*User, 0, len(list))
	for _, user := range list {
		userMessage := convertUserFromStore(user)
		// data desensitize
		userMessage.Email = ""
		userMessageList = append(userMessageList, userMessage)
	}
	return c.JSON(http.StatusOK, userMessageList)
}

// CreateUser godoc
//
//	@Summary	Create a user
//	@Tags		user
//	@Accept		json
//	@Produce	json
//	@Param		body	body		CreateUserRequest	true	"Request object"
//	@Success	200		{object}	store.User			"Created user"
//	@Failure	400		{object}	nil					"Malformatted post user request | Invalid user create format"
//	@Failure	401		{object}	nil					"Missing auth session | Unauthorized to create user"
//	@Failure	403		{object}	nil					"Could not create host user"
//	@Failure	500		{object}	nil					"Failed to find user by id | Failed to generate password hash | Failed to create user | Failed to create activity"
//	@Router		/api/v1/user [POST]
func (s *APIV1Service) CreateUser(c echo.Context) error {
	ctx := c.Request().Context()
	userID, ok := c.Get(userIDContextKey).(int32)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, "Missing auth session")
	}
	currentUser, err := s.Store.GetUser(ctx, &store.FindUser{
		ID: &userID,
	})
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find user by id").SetInternal(err)
	}
	if currentUser == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Missing auth session")
	}
	if currentUser.Role != store.RoleHost {
		return echo.NewHTTPError(http.StatusUnauthorized, "Unauthorized to create user")
	}

	userCreate := &CreateUserRequest{}
	if err := json.NewDecoder(c.Request().Body).Decode(userCreate); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Malformatted post user request").SetInternal(err)
	}
	if err := userCreate.Validate(); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid user create format").SetInternal(err)
	}
	if !util.UIDMatcher.MatchString(strings.ToLower(userCreate.Username)) {
		return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Invalid username %s", userCreate.Username)).SetInternal(err)
	}
	// Disallow host user to be created.
	if userCreate.Role == RoleHost {
		return echo.NewHTTPError(http.StatusForbidden, "Could not create host user")
	}

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(userCreate.Password), bcrypt.DefaultCost)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate password hash").SetInternal(err)
	}

	user, err := s.Store.CreateUser(ctx, &store.User{
		Username:     userCreate.Username,
		Role:         store.Role(userCreate.Role),
		Email:        userCreate.Email,
		Nickname:     userCreate.Nickname,
		PasswordHash: string(passwordHash),
	})
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create user").SetInternal(err)
	}

	userMessage := convertUserFromStore(user)
	return c.JSON(http.StatusOK, userMessage)
}

// GetCurrentUser godoc
//
//	@Summary	Get current user
//	@Tags		user
//	@Produce	json
//	@Success	200	{object}	store.User	"Current user"
//	@Failure	401	{object}	nil			"Missing auth session"
//	@Failure	500	{object}	nil			"Failed to find user | Failed to find userSettingList"
//	@Router		/api/v1/user/me [GET]
func (s *APIV1Service) GetCurrentUser(c echo.Context) error {
	ctx := c.Request().Context()
	userID, ok := c.Get(userIDContextKey).(int32)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, "Missing auth session")
	}

	user, err := s.Store.GetUser(ctx, &store.FindUser{ID: &userID})
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find user").SetInternal(err)
	}
	if user == nil {
		return echo.NewHTTPError(http.StatusUnauthorized, "Missing auth session")
	}

	userMessage := convertUserFromStore(user)
	return c.JSON(http.StatusOK, userMessage)
}

// GetUserByUsername godoc
//
//	@Summary	Get user by username
//	@Tags		user
//	@Produce	json
//	@Param		username	path		string		true	"Username"
//	@Success	200			{object}	store.User	"Requested user"
//	@Failure	404			{object}	nil			"User not found"
//	@Failure	500			{object}	nil			"Failed to find user"
//	@Router		/api/v1/user/name/{username} [GET]
func (s *APIV1Service) GetUserByUsername(c echo.Context) error {
	ctx := c.Request().Context()
	username := c.Param("username")
	user, err := s.Store.GetUser(ctx, &store.FindUser{Username: &username})
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find user").SetInternal(err)
	}
	if user == nil {
		return echo.NewHTTPError(http.StatusNotFound, "User not found")
	}

	userMessage := convertUserFromStore(user)
	// data desensitize
	userMessage.Email = ""
	return c.JSON(http.StatusOK, userMessage)
}

// GetUserByID godoc
//
//	@Summary	Get user by id
//	@Tags		user
//	@Produce	json
//	@Param		id	path		int			true	"User ID"
//	@Success	200	{object}	store.User	"Requested user"
//	@Failure	400	{object}	nil			"Malformatted user id"
//	@Failure	404	{object}	nil			"User not found"
//	@Failure	500	{object}	nil			"Failed to find user"
//	@Router		/api/v1/user/{id} [GET]
func (s *APIV1Service) GetUserByID(c echo.Context) error {
	ctx := c.Request().Context()
	id, err := util.ConvertStringToInt32(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Malformatted user id").SetInternal(err)
	}

	user, err := s.Store.GetUser(ctx, &store.FindUser{ID: &id})
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find user").SetInternal(err)
	}
	if user == nil {
		return echo.NewHTTPError(http.StatusNotFound, "User not found")
	}

	userMessage := convertUserFromStore(user)
	userID, ok := c.Get(userIDContextKey).(int32)
	if !ok || userID != user.ID {
		// Data desensitize.
		userMessage.Email = ""
	}

	return c.JSON(http.StatusOK, userMessage)
}

// DeleteUser godoc
//
//	@Summary	Delete a user
//	@Tags		user
//	@Produce	json
//	@Param		id	path		string	true	"User ID"
//	@Success	200	{boolean}	true	"User deleted"
//	@Failure	400	{object}	nil		"ID is not a number: %s | Current session user not found with ID: %d"
//	@Failure	401	{object}	nil		"Missing user in session"
//	@Failure	403	{object}	nil		"Unauthorized to delete user"
//	@Failure	500	{object}	nil		"Failed to find user | Failed to delete user"
//	@Router		/api/v1/user/{id} [DELETE]
func (s *APIV1Service) DeleteUser(c echo.Context) error {
	ctx := c.Request().Context()
	currentUserID, ok := c.Get(userIDContextKey).(int32)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, "Missing user in session")
	}
	currentUser, err := s.Store.GetUser(ctx, &store.FindUser{
		ID: &currentUserID,
	})
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find user").SetInternal(err)
	}
	if currentUser == nil {
		return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Current session user not found with ID: %d", currentUserID)).SetInternal(err)
	} else if currentUser.Role != store.RoleHost {
		return echo.NewHTTPError(http.StatusForbidden, "Unauthorized to delete user").SetInternal(err)
	}

	userID, err := util.ConvertStringToInt32(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("ID is not a number: %s", c.Param("id"))).SetInternal(err)
	}
	if currentUserID == userID {
		return echo.NewHTTPError(http.StatusBadRequest, "Cannot delete current user")
	}

	if err := s.Store.DeleteUser(ctx, &store.DeleteUser{
		ID: userID,
	}); err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to delete user").SetInternal(err)
	}
	return c.JSON(http.StatusOK, true)
}

// UpdateUser godoc
//
//	@Summary	Update a user
//	@Tags		user
//	@Produce	json
//	@Param		id		path		string				true	"User ID"
//	@Param		patch	body		UpdateUserRequest	true	"Patch request"
//	@Success	200		{object}	store.User			"Updated user"
//	@Failure	400		{object}	nil					"ID is not a number: %s | Current session user not found with ID: %d | Malformatted patch user request | Invalid update user request"
//	@Failure	401		{object}	nil					"Missing user in session"
//	@Failure	403		{object}	nil					"Unauthorized to update user"
//	@Failure	500		{object}	nil					"Failed to find user | Failed to generate password hash | Failed to patch user | Failed to find userSettingList"
//	@Router		/api/v1/user/{id} [PATCH]
func (s *APIV1Service) UpdateUser(c echo.Context) error {
	ctx := c.Request().Context()
	userID, err := util.ConvertStringToInt32(c.Param("id"))
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("ID is not a number: %s", c.Param("id"))).SetInternal(err)
	}

	currentUserID, ok := c.Get(userIDContextKey).(int32)
	if !ok {
		return echo.NewHTTPError(http.StatusUnauthorized, "Missing user in session")
	}
	currentUser, err := s.Store.GetUser(ctx, &store.FindUser{ID: &currentUserID})
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find user").SetInternal(err)
	}
	if currentUser == nil {
		return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Current session user not found with ID: %d", currentUserID)).SetInternal(err)
	} else if currentUser.Role != store.RoleHost && currentUserID != userID {
		return echo.NewHTTPError(http.StatusForbidden, "Unauthorized to update user").SetInternal(err)
	}

	request := &UpdateUserRequest{}
	if err := json.NewDecoder(c.Request().Body).Decode(request); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Malformatted patch user request").SetInternal(err)
	}
	if err := request.Validate(); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid update user request").SetInternal(err)
	}

	currentTs := time.Now().Unix()
	userUpdate := &store.UpdateUser{
		ID:        userID,
		UpdatedTs: &currentTs,
	}
	if request.RowStatus != nil {
		rowStatus := store.RowStatus(request.RowStatus.String())
		userUpdate.RowStatus = &rowStatus
		if rowStatus == store.Archived && currentUserID == userID {
			return echo.NewHTTPError(http.StatusBadRequest, "Cannot archive current user")
		}
	}
	if request.Username != nil {
		if !util.UIDMatcher.MatchString(strings.ToLower(*request.Username)) {
			return echo.NewHTTPError(http.StatusBadRequest, fmt.Sprintf("Invalid username %s", *request.Username)).SetInternal(err)
		}
		userUpdate.Username = request.Username
	}
	if request.Email != nil {
		userUpdate.Email = request.Email
	}
	if request.Nickname != nil {
		userUpdate.Nickname = request.Nickname
	}
	if request.Password != nil {
		passwordHash, err := bcrypt.GenerateFromPassword([]byte(*request.Password), bcrypt.DefaultCost)
		if err != nil {
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to generate password hash").SetInternal(err)
		}

		passwordHashStr := string(passwordHash)
		userUpdate.PasswordHash = &passwordHashStr
	}
	if request.AvatarURL != nil {
		userUpdate.AvatarURL = request.AvatarURL
	}

	user, err := s.Store.UpdateUser(ctx, userUpdate)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to patch user").SetInternal(err)
	}

	userMessage := convertUserFromStore(user)
	return c.JSON(http.StatusOK, userMessage)
}

func (create CreateUserRequest) Validate() error {
	if len(create.Username) < 3 {
		return errors.New("username is too short, minimum length is 3")
	}
	if len(create.Username) > 32 {
		return errors.New("username is too long, maximum length is 32")
	}
	if len(create.Password) < 3 {
		return errors.New("password is too short, minimum length is 3")
	}
	if len(create.Password) > 512 {
		return errors.New("password is too long, maximum length is 512")
	}
	if len(create.Nickname) > 64 {
		return errors.New("nickname is too long, maximum length is 64")
	}
	if create.Email != "" {
		if len(create.Email) > 256 {
			return errors.New("email is too long, maximum length is 256")
		}
		if !util.ValidateEmail(create.Email) {
			return errors.New("invalid email format")
		}
	}

	return nil
}

func (update UpdateUserRequest) Validate() error {
	if update.Username != nil && len(*update.Username) < 3 {
		return errors.New("username is too short, minimum length is 3")
	}
	if update.Username != nil && len(*update.Username) > 32 {
		return errors.New("username is too long, maximum length is 32")
	}
	if update.Password != nil && len(*update.Password) < 3 {
		return errors.New("password is too short, minimum length is 3")
	}
	if update.Password != nil && len(*update.Password) > 512 {
		return errors.New("password is too long, maximum length is 512")
	}
	if update.Nickname != nil && len(*update.Nickname) > 64 {
		return errors.New("nickname is too long, maximum length is 64")
	}
	if update.AvatarURL != nil {
		if len(*update.AvatarURL) > 2<<20 {
			return errors.New("avatar is too large, maximum is 2MB")
		}
	}
	if update.Email != nil && *update.Email != "" {
		if len(*update.Email) > 256 {
			return errors.New("email is too long, maximum length is 256")
		}
		if !util.ValidateEmail(*update.Email) {
			return errors.New("invalid email format")
		}
	}

	return nil
}

func convertUserFromStore(user *store.User) *User {
	return &User{
		ID:           user.ID,
		RowStatus:    RowStatus(user.RowStatus),
		CreatedTs:    user.CreatedTs,
		UpdatedTs:    user.UpdatedTs,
		Username:     user.Username,
		Role:         Role(user.Role),
		Email:        user.Email,
		Nickname:     user.Nickname,
		PasswordHash: user.PasswordHash,
		AvatarURL:    user.AvatarURL,
	}
}
