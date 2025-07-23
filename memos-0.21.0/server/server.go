package server

import (
	"context"
	"fmt"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"github.com/pkg/errors"

	"github.com/usememos/memos/plugin/telegram"
	"github.com/usememos/memos/server/integration"
	"github.com/usememos/memos/server/profile"
	apiv1 "github.com/usememos/memos/server/route/api/v1"
	apiv2 "github.com/usememos/memos/server/route/api/v2"
	"github.com/usememos/memos/server/route/frontend"
	versionchecker "github.com/usememos/memos/server/service/version_checker"
	"github.com/usememos/memos/store"
)

type Server struct {
	e *echo.Echo

	ID      string
	Secret  string
	Profile *profile.Profile
	Store   *store.Store

	// Asynchronous runners.
	telegramBot *telegram.Bot
}

func NewServer(ctx context.Context, profile *profile.Profile, store *store.Store) (*Server, error) {
	e := echo.New()
	e.Debug = true
	e.HideBanner = true
	e.HidePort = true

	s := &Server{
		e:       e,
		Store:   store,
		Profile: profile,

		// Asynchronous runners.
		telegramBot: telegram.NewBotWithHandler(integration.NewTelegramHandler(store)),
	}

	// Register CORS middleware.
	e.Use(CORSMiddleware(s.Profile.Origins))

	serverID, err := s.getSystemServerID(ctx)
	if err != nil {
		return nil, errors.Wrap(err, "failed to retrieve system server ID")
	}
	s.ID = serverID

	secret := "usememos"
	if profile.Mode == "prod" {
		secret, err = s.getSystemSecretSessionName(ctx)
		if err != nil {
			return nil, errors.Wrap(err, "failed to retrieve system secret session name")
		}
	}
	s.Secret = secret

	// Register healthz endpoint.
	e.GET("/healthz", func(c echo.Context) error {
		return c.String(http.StatusOK, "Service ready.")
	})

	// Only serve frontend when it's enabled.
	if profile.Frontend {
		frontendService := frontend.NewFrontendService(profile, store)
		frontendService.Serve(ctx, e)
	}

	// Register API v1 endpoints.
	rootGroup := e.Group("")
	apiV1Service := apiv1.NewAPIV1Service(s.Secret, profile, store, s.telegramBot)
	apiV1Service.Register(rootGroup)

	apiV2Service := apiv2.NewAPIV2Service(s.Secret, profile, store, s.Profile.Port+1)
	// Register gRPC gateway as api v2.
	if err := apiV2Service.RegisterGateway(ctx, e); err != nil {
		return nil, errors.Wrap(err, "failed to register gRPC gateway")
	}

	return s, nil
}

func (s *Server) Start(ctx context.Context) error {
	go versionchecker.NewVersionChecker(s.Store, s.Profile).Start(ctx)
	go s.telegramBot.Start(ctx)
	return s.e.Start(fmt.Sprintf("%s:%d", s.Profile.Addr, s.Profile.Port))
}

func (s *Server) Shutdown(ctx context.Context) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	// Shutdown echo server
	if err := s.e.Shutdown(ctx); err != nil {
		fmt.Printf("failed to shutdown server, error: %v\n", err)
	}

	// Close database connection
	if err := s.Store.Close(); err != nil {
		fmt.Printf("failed to close database, error: %v\n", err)
	}

	fmt.Printf("memos stopped properly\n")
}

func (s *Server) GetEcho() *echo.Echo {
	return s.e
}

func (s *Server) getSystemServerID(ctx context.Context) (string, error) {
	serverIDSetting, err := s.Store.GetWorkspaceSetting(ctx, &store.FindWorkspaceSetting{
		Name: apiv1.SystemSettingServerIDName.String(),
	})
	if err != nil {
		return "", err
	}
	if serverIDSetting == nil || serverIDSetting.Value == "" {
		serverIDSetting, err = s.Store.UpsertWorkspaceSetting(ctx, &store.WorkspaceSetting{
			Name:  apiv1.SystemSettingServerIDName.String(),
			Value: uuid.NewString(),
		})
		if err != nil {
			return "", err
		}
	}
	return serverIDSetting.Value, nil
}

func (s *Server) getSystemSecretSessionName(ctx context.Context) (string, error) {
	secretSessionNameValue, err := s.Store.GetWorkspaceSetting(ctx, &store.FindWorkspaceSetting{
		Name: apiv1.SystemSettingSecretSessionName.String(),
	})
	if err != nil {
		return "", err
	}
	if secretSessionNameValue == nil || secretSessionNameValue.Value == "" {
		secretSessionNameValue, err = s.Store.UpsertWorkspaceSetting(ctx, &store.WorkspaceSetting{
			Name:  apiv1.SystemSettingSecretSessionName.String(),
			Value: uuid.NewString(),
		})
		if err != nil {
			return "", err
		}
	}
	return secretSessionNameValue.Value, nil
}

func grpcRequestSkipper(c echo.Context) bool {
	return strings.HasPrefix(c.Request().URL.Path, "/memos.api.v2.")
}

func CORSMiddleware(origins []string) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			if grpcRequestSkipper(c) {
				return next(c)
			}

			r := c.Request()
			w := c.Response().Writer

			requestOrigin := r.Header.Get("Origin")
			if len(origins) == 0 {
				w.Header().Set("Access-Control-Allow-Origin", requestOrigin)
			} else {
				for _, origin := range origins {
					if origin == requestOrigin {
						w.Header().Set("Access-Control-Allow-Origin", origin)
						break
					}
				}
			}

			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			w.Header().Set("Access-Control-Allow-Credentials", "true")

			// If it's preflight request, return immediately.
			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return nil
			}
			return next(c)
		}
	}
}
