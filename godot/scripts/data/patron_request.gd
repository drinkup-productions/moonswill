class_name PatronRequest
extends RefCounted
## Design ref: docs/design.md §7.3

enum Kind { SPECIFIC, VAGUE, PROXY, WILDCARD }

const NOTE := {
	Kind.SPECIFIC: "exact mark, strict on side effects",
	Kind.VAGUE: "roughly, forgiving",
	Kind.PROXY: "someone else's mark",
	Kind.WILDCARD: "NO TARGET — bold and focused",
}

const LABEL := {
	Kind.SPECIFIC: "specific",
	Kind.VAGUE: "vague",
	Kind.PROXY: "proxy",
	Kind.WILDCARD: "wildcard",
}

var kind: Kind = Kind.SPECIFIC
var want: Dictionary = {}          # empty for WILDCARD
var strictness: float = 1.0
var line: String = ""
var note: String = ""


static func make(p_kind: Kind, p_line: String, p_want: Dictionary, p_strictness: float) -> PatronRequest:
	var r := PatronRequest.new()
	r.kind = p_kind
	r.line = p_line
	r.want = p_want
	r.strictness = p_strictness
	r.note = NOTE[p_kind]
	return r


func is_wildcard() -> bool:
	return kind == Kind.WILDCARD
