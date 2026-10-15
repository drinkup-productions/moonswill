class_name PatronRequest
extends RefCounted
## Design ref: docs/design.md §7.3

enum Kind { SPECIFIC, VAGUE, PROXY, WILDCARD }

var kind: Kind = Kind.SPECIFIC
var want: Dictionary = {}          # empty for WILDCARD
var strictness: float = 1.0
var line: String = ""
var note: String = ""


static func make(kind: Kind, line: String, want: Dictionary, strictness: float) -> PatronRequest:
	var r := PatronRequest.new()
	r.kind = kind
	r.line = line
	r.want = want
	r.strictness = strictness
	r.note = NOTE[kind]
	return r


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