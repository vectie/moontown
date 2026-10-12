# Cross-book claim comparison

State: pending_review

Operator-labelled topic, context, value and book identity. Groups match topic and context exactly; values compare as exact text. different_values is a candidate difference, not an inferred contradiction. same_value is textual agreement, not verified truth. Different contexts remain separate; single_book lacks a cross-book comparison. Quotes are checked against captured UTF-8 bytes and sources are hashed; no source ownership, semantic entailment, freshness or Book acceptance is asserted. No source or Book is changed.

Claim table: sha256:ebff4742799ea2083be9df1554aac4125c3dded3831f0ddfce58a8ab0c6dc16f (509 bytes)

## Group 1: different_values

- Topic: "launch month"
- Context: "October 2026 plan"

### Claim "sales\-launch"

- Book label: "sales"
- Value: "November"
- Source: "sales\.txt"
- Exact quote: "Launch: November"

### Claim "engineering\-launch"

- Book label: "engineering"
- Value: "December"
- Source: "engineering\.txt"
- Exact quote: "Launch: December"

## Group 2: single_book

- Topic: "launch month"
- Context: "September 2026 plan"

### Claim "sales\-previous"

- Book label: "sales"
- Value: "November"
- Source: "sales\.txt"
- Exact quote: "Prior September launch: November"

## Group 3: same_value

- Topic: "region"
- Context: "October 2026 plan"

### Claim "sales\-region"

- Book label: "sales"
- Value: "水"
- Source: "sales\.txt"
- Exact quote: "Region: 水"

### Claim "engineering\-region"

- Book label: "engineering"
- Value: "水"
- Source: "engineering\.txt"
- Exact quote: "Region: 水"

## Captured source identities

- "sales\.txt": sha256:f227b06808b00191113830f765f9554ea501fefcfc4e444886ff805535c6ec53 (100 bytes)
- "engineering\.txt": sha256:c39d5cca746d58cd71a00c182ff709a26e3348a0804b6478d4664948d8375f75 (73 bytes)
