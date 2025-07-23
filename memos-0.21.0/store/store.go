package store

import (
	"context"
	"sync"

	"github.com/usememos/memos/server/profile"
)

// Store provides database access to all raw objects.
type Store struct {
	Profile                 *profile.Profile
	driver                  Driver
	workspaceSettingCache   sync.Map // map[string]*WorkspaceSetting
	workspaceSettingV1Cache sync.Map // map[string]*storepb.WorkspaceSetting
	userCache               sync.Map // map[int]*User
	userSettingCache        sync.Map // map[string]*UserSetting
	idpCache                sync.Map // map[int]*IdentityProvider
}

// New creates a new instance of Store.
func New(driver Driver, profile *profile.Profile) *Store {
	return &Store{
		driver:  driver,
		Profile: profile,
	}
}

func (s *Store) MigrateManually(ctx context.Context) error {
	if err := s.MigrateWorkspaceSetting(ctx); err != nil {
		return err
	}
	return nil
}

func (s *Store) Vacuum(ctx context.Context) error {
	return s.driver.Vacuum(ctx)
}

func (s *Store) Close() error {
	return s.driver.Close()
}

func (s *Store) GetCurrentDBSize(ctx context.Context) (int64, error) {
	return s.driver.GetCurrentDBSize(ctx)
}
