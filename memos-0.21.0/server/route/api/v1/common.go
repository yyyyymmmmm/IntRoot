package v1

// RowStatus is the status for a row.
type RowStatus string

const (
	// Normal is the status for a normal row.
	Normal RowStatus = "NORMAL"
	// Archived is the status for an archived row.
	Archived RowStatus = "ARCHIVED"
)

func (r RowStatus) String() string {
	return string(r)
}
