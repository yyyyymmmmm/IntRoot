package mysql

import (
	"context"
	"strings"

	"github.com/pkg/errors"

	storepb "github.com/usememos/memos/proto/gen/store"
	"github.com/usememos/memos/store"
)

func (d *DB) UpsertReaction(ctx context.Context, upsert *storepb.Reaction) (*storepb.Reaction, error) {
	fields := []string{"`creator_id`", "`content_id`", "`reaction_type`"}
	placeholder := []string{"?", "?", "?"}
	args := []interface{}{upsert.CreatorId, upsert.ContentId, upsert.ReactionType.String()}
	stmt := "INSERT INTO `reaction` (" + strings.Join(fields, ", ") + ") VALUES (" + strings.Join(placeholder, ", ") + ")"
	result, err := d.db.ExecContext(ctx, stmt, args...)
	if err != nil {
		return nil, err
	}

	rawID, err := result.LastInsertId()
	if err != nil {
		return nil, err
	}
	id := int32(rawID)
	reaction, err := d.GetReaction(ctx, &store.FindReaction{ID: &id})
	if err != nil {
		return nil, err
	}
	if reaction == nil {
		return nil, errors.Errorf("failed to create reaction")
	}
	return reaction, nil
}

func (d *DB) ListReactions(ctx context.Context, find *store.FindReaction) ([]*storepb.Reaction, error) {
	where, args := []string{"1 = 1"}, []interface{}{}
	if find.ID != nil {
		where, args = append(where, "`id` = ?"), append(args, *find.ID)
	}
	if find.CreatorID != nil {
		where, args = append(where, "`creator_id` = ?"), append(args, *find.CreatorID)
	}
	if find.ContentID != nil {
		where, args = append(where, "`content_id` = ?"), append(args, *find.ContentID)
	}

	rows, err := d.db.QueryContext(ctx, `
		SELECT
			id,
			UNIX_TIMESTAMP(created_ts) AS created_ts,
			creator_id,
			content_id,
			reaction_type
		FROM reaction
		WHERE `+strings.Join(where, " AND ")+`
		ORDER BY id ASC`,
		args...,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	list := []*storepb.Reaction{}
	for rows.Next() {
		reaction := &storepb.Reaction{}
		var reactionType string
		if err := rows.Scan(
			&reaction.Id,
			&reaction.CreatedTs,
			&reaction.CreatorId,
			&reaction.ContentId,
			&reactionType,
		); err != nil {
			return nil, err
		}
		reaction.ReactionType = storepb.Reaction_Type(storepb.Reaction_Type_value[reactionType])
		list = append(list, reaction)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return list, nil
}

func (d *DB) GetReaction(ctx context.Context, find *store.FindReaction) (*storepb.Reaction, error) {
	list, err := d.ListReactions(ctx, find)
	if err != nil {
		return nil, err
	}
	if len(list) == 0 {
		return nil, nil
	}

	reaction := list[0]
	return reaction, nil
}

func (d *DB) DeleteReaction(ctx context.Context, delete *store.DeleteReaction) error {
	_, err := d.db.ExecContext(ctx, "DELETE FROM `reaction` WHERE `id` = ?", delete.ID)
	return err
}
