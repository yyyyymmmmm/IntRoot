package teststore

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"

	storepb "github.com/usememos/memos/proto/gen/store"
	"github.com/usememos/memos/store"
)

func TestWorkspaceSettingV1Store(t *testing.T) {
	ctx := context.Background()
	ts := NewTestingStore(ctx, t)
	workspaceSetting, err := ts.UpsertWorkspaceSettingV1(ctx, &storepb.WorkspaceSetting{
		Key: storepb.WorkspaceSettingKey_WORKSPACE_SETTING_GENERAL,
		Value: &storepb.WorkspaceSetting_General{
			General: &storepb.WorkspaceGeneralSetting{
				DisallowSignup: true,
			},
		},
	})
	require.NoError(t, err)
	list, err := ts.ListWorkspaceSettingsV1(ctx, &store.FindWorkspaceSettingV1{})
	require.NoError(t, err)
	require.Equal(t, 1, len(list))
	require.Equal(t, workspaceSetting, list[0])
	ts.Close()
}
