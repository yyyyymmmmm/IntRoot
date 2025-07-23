package postgres

import (
	"context"
	"strings"

	storepb "github.com/usememos/memos/proto/gen/store"
	"github.com/usememos/memos/store"
)

func (d *DB) CreateWebhook(ctx context.Context, create *storepb.Webhook) (*storepb.Webhook, error) {
	fields := []string{"name", "url", "creator_id"}
	args := []any{create.Name, create.Url, create.CreatorId}
	stmt := "INSERT INTO webhook (" + strings.Join(fields, ", ") + ") VALUES (" + placeholders(len(args)) + ") RETURNING id, created_ts, updated_ts, row_status"
	var rowStatus string
	if err := d.db.QueryRowContext(ctx, stmt, args...).Scan(
		&create.Id,
		&create.CreatedTs,
		&create.UpdatedTs,
		&rowStatus,
	); err != nil {
		return nil, err
	}

	create.RowStatus = storepb.RowStatus(storepb.RowStatus_value[rowStatus])
	webhook := create
	return webhook, nil
}

func (d *DB) ListWebhooks(ctx context.Context, find *store.FindWebhook) ([]*storepb.Webhook, error) {
	where, args := []string{"1 = 1"}, []any{}
	if find.ID != nil {
		where, args = append(where, "id = "+placeholder(len(args)+1)), append(args, *find.ID)
	}
	if find.CreatorID != nil {
		where, args = append(where, "creator_id = "+placeholder(len(args)+1)), append(args, *find.CreatorID)
	}

	rows, err := d.db.QueryContext(ctx, `
		SELECT
			id,
			created_ts,
			updated_ts,
			row_status,
			creator_id,
			name,
			url
		FROM webhook
		WHERE `+strings.Join(where, " AND ")+`
		ORDER BY id DESC`,
		args...,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	list := []*storepb.Webhook{}
	for rows.Next() {
		webhook := &storepb.Webhook{}
		var rowStatus string
		if err := rows.Scan(
			&webhook.Id,
			&webhook.CreatedTs,
			&webhook.UpdatedTs,
			&rowStatus,
			&webhook.CreatorId,
			&webhook.Name,
			&webhook.Url,
		); err != nil {
			return nil, err
		}
		webhook.RowStatus = storepb.RowStatus(storepb.RowStatus_value[rowStatus])
		list = append(list, webhook)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return list, nil
}

func (d *DB) UpdateWebhook(ctx context.Context, update *store.UpdateWebhook) (*storepb.Webhook, error) {
	set, args := []string{}, []any{}
	if update.RowStatus != nil {
		set, args = append(set, "row_status = "+placeholder(len(args)+1)), append(args, update.RowStatus.String())
	}
	if update.Name != nil {
		set, args = append(set, "name = "+placeholder(len(args)+1)), append(args, *update.Name)
	}
	if update.URL != nil {
		set, args = append(set, "url = "+placeholder(len(args)+1)), append(args, *update.URL)
	}

	stmt := "UPDATE webhook SET " + strings.Join(set, ", ") + " WHERE id = " + placeholder(len(args)+1) + " RETURNING id, created_ts, updated_ts, row_status, creator_id, name, url"
	args = append(args, update.ID)
	webhook := &storepb.Webhook{}
	var rowStatus string
	if err := d.db.QueryRowContext(ctx, stmt, args...).Scan(
		&webhook.Id,
		&webhook.CreatedTs,
		&webhook.UpdatedTs,
		&rowStatus,
		&webhook.CreatorId,
		&webhook.Name,
		&webhook.Url,
	); err != nil {
		return nil, err
	}
	webhook.RowStatus = storepb.RowStatus(storepb.RowStatus_value[rowStatus])
	return webhook, nil
}

func (d *DB) DeleteWebhook(ctx context.Context, delete *store.DeleteWebhook) error {
	_, err := d.db.ExecContext(ctx, "DELETE FROM webhook WHERE id = $1", delete.ID)
	return err
}
