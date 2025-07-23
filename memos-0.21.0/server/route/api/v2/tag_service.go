package v2

import (
	"context"
	"fmt"
	"slices"
	"sort"

	"github.com/pkg/errors"
	"github.com/yourselfhosted/gomark/ast"
	"github.com/yourselfhosted/gomark/parser"
	"github.com/yourselfhosted/gomark/parser/tokenizer"
	"github.com/yourselfhosted/gomark/restore"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	apiv2pb "github.com/usememos/memos/proto/gen/api/v2"
	"github.com/usememos/memos/store"
)

func (s *APIV2Service) UpsertTag(ctx context.Context, request *apiv2pb.UpsertTagRequest) (*apiv2pb.UpsertTagResponse, error) {
	user, err := getCurrentUser(ctx, s.Store)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get user")
	}

	tag, err := s.Store.UpsertTag(ctx, &store.Tag{
		Name:      request.Name,
		CreatorID: user.ID,
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to upsert tag: %v", err)
	}

	t, err := s.convertTagFromStore(ctx, tag)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to convert tag: %v", err)
	}
	return &apiv2pb.UpsertTagResponse{
		Tag: t,
	}, nil
}

func (s *APIV2Service) BatchUpsertTag(ctx context.Context, request *apiv2pb.BatchUpsertTagRequest) (*apiv2pb.BatchUpsertTagResponse, error) {
	for _, r := range request.Requests {
		if _, err := s.UpsertTag(ctx, r); err != nil {
			return nil, status.Errorf(codes.Internal, "failed to batch upsert tags: %v", err)
		}
	}
	return &apiv2pb.BatchUpsertTagResponse{}, nil
}

func (s *APIV2Service) ListTags(ctx context.Context, request *apiv2pb.ListTagsRequest) (*apiv2pb.ListTagsResponse, error) {
	tagFind := &store.FindTag{}
	userID, err := ExtractUserIDFromName(request.User)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid user name: %v", err)
	}
	tagFind.CreatorID = userID
	tags, err := s.Store.ListTags(ctx, tagFind)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to list tags: %v", err)
	}

	response := &apiv2pb.ListTagsResponse{}
	for _, tag := range tags {
		t, err := s.convertTagFromStore(ctx, tag)
		if err != nil {
			return nil, status.Errorf(codes.Internal, "failed to convert tag: %v", err)
		}
		response.Tags = append(response.Tags, t)
	}
	return response, nil
}

func (s *APIV2Service) RenameTag(ctx context.Context, request *apiv2pb.RenameTagRequest) (*apiv2pb.RenameTagResponse, error) {
	userID, err := ExtractUserIDFromName(request.User)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid user name: %v", err)
	}
	user, err := s.Store.GetUser(ctx, &store.FindUser{
		ID: &userID,
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get user: %v", err)
	}
	if user == nil {
		return nil, status.Errorf(codes.NotFound, "user not found")
	}

	// Find all related memos.
	memos, err := s.Store.ListMemos(ctx, &store.FindMemo{
		CreatorID:     &user.ID,
		ContentSearch: []string{fmt.Sprintf("#%s", request.OldName)},
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to list memos: %v", err)
	}
	// Replace tag name in memo content.
	for _, memo := range memos {
		nodes, err := parser.Parse(tokenizer.Tokenize(memo.Content))
		if err != nil {
			return nil, status.Errorf(codes.Internal, "failed to parse memo: %v", err)
		}
		TraverseASTNodes(nodes, func(node ast.Node) {
			if tag, ok := node.(*ast.Tag); ok && tag.Content == request.OldName {
				tag.Content = request.NewName
			}
		})
		content := restore.Restore(nodes)
		if err := s.Store.UpdateMemo(ctx, &store.UpdateMemo{
			ID:      memo.ID,
			Content: &content,
		}); err != nil {
			return nil, status.Errorf(codes.Internal, "failed to update memo: %v", err)
		}
	}

	// Delete old tag and create new tag.
	if err := s.Store.DeleteTag(ctx, &store.DeleteTag{
		CreatorID: user.ID,
		Name:      request.OldName,
	}); err != nil {
		return nil, status.Errorf(codes.Internal, "failed to delete tag: %v", err)
	}
	tag, err := s.Store.UpsertTag(ctx, &store.Tag{
		CreatorID: user.ID,
		Name:      request.NewName,
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to upsert tag: %v", err)
	}

	tagMessage, err := s.convertTagFromStore(ctx, tag)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to convert tag: %v", err)
	}
	return &apiv2pb.RenameTagResponse{Tag: tagMessage}, nil
}

func (s *APIV2Service) DeleteTag(ctx context.Context, request *apiv2pb.DeleteTagRequest) (*apiv2pb.DeleteTagResponse, error) {
	userID, err := ExtractUserIDFromName(request.Tag.Creator)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid user name: %v", err)
	}
	user, err := s.Store.GetUser(ctx, &store.FindUser{
		ID: &userID,
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get user: %v", err)
	}
	if user == nil {
		return nil, status.Errorf(codes.NotFound, "user not found")
	}
	if err := s.Store.DeleteTag(ctx, &store.DeleteTag{
		Name:      request.Tag.Name,
		CreatorID: user.ID,
	}); err != nil {
		return nil, status.Errorf(codes.Internal, "failed to delete tag: %v", err)
	}

	return &apiv2pb.DeleteTagResponse{}, nil
}

func (s *APIV2Service) GetTagSuggestions(ctx context.Context, request *apiv2pb.GetTagSuggestionsRequest) (*apiv2pb.GetTagSuggestionsResponse, error) {
	userID, err := ExtractUserIDFromName(request.User)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid user name: %v", err)
	}
	user, err := s.Store.GetUser(ctx, &store.FindUser{
		ID: &userID,
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to get user: %v", err)
	}
	if user == nil {
		return nil, status.Errorf(codes.NotFound, "user not found")
	}
	normalRowStatus := store.Normal
	memoFind := &store.FindMemo{
		CreatorID:     &user.ID,
		ContentSearch: []string{"#"},
		RowStatus:     &normalRowStatus,
	}
	memos, err := s.Store.ListMemos(ctx, memoFind)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to list memos: %v", err)
	}

	tagList, err := s.Store.ListTags(ctx, &store.FindTag{
		CreatorID: user.ID,
	})
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to list tags: %v", err)
	}

	tagNameList := []string{}
	for _, tag := range tagList {
		tagNameList = append(tagNameList, tag.Name)
	}
	tagMapSet := make(map[string]bool)
	for _, memo := range memos {
		nodes, err := parser.Parse(tokenizer.Tokenize(memo.Content))
		if err != nil {
			return nil, errors.Wrap(err, "failed to parse memo content")
		}

		// Dynamically upsert tags from memo content.
		TraverseASTNodes(nodes, func(node ast.Node) {
			if tagNode, ok := node.(*ast.Tag); ok {
				tag := tagNode.Content
				if !slices.Contains(tagNameList, tag) {
					tagMapSet[tag] = true
				}
			}
		})
	}
	suggestions := []string{}
	for tag := range tagMapSet {
		suggestions = append(suggestions, tag)
	}
	sort.Strings(suggestions)

	return &apiv2pb.GetTagSuggestionsResponse{
		Tags: suggestions,
	}, nil
}

func (s *APIV2Service) convertTagFromStore(ctx context.Context, tag *store.Tag) (*apiv2pb.Tag, error) {
	user, err := s.Store.GetUser(ctx, &store.FindUser{
		ID: &tag.CreatorID,
	})
	if err != nil {
		return nil, errors.Wrap(err, "failed to get user")
	}
	return &apiv2pb.Tag{
		Name:    tag.Name,
		Creator: fmt.Sprintf("%s%d", UserNamePrefix, user.ID),
	}, nil
}

func TraverseASTNodes(nodes []ast.Node, fn func(ast.Node)) {
	for _, node := range nodes {
		fn(node)
		switch n := node.(type) {
		case *ast.Paragraph:
			TraverseASTNodes(n.Children, fn)
		case *ast.Heading:
			TraverseASTNodes(n.Children, fn)
		case *ast.Blockquote:
			TraverseASTNodes(n.Children, fn)
		case *ast.OrderedList:
			TraverseASTNodes(n.Children, fn)
		case *ast.UnorderedList:
			TraverseASTNodes(n.Children, fn)
		case *ast.TaskList:
			TraverseASTNodes(n.Children, fn)
		case *ast.Bold:
			TraverseASTNodes(n.Children, fn)
		}
	}
}
