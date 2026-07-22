class_name LevelConfig
extends Resource

enum MatchRule {
	MATCH_ANY,
	MATCH_COLOR,
	MATCH_SHAPE,
	MATCH_SIZE,
	MATCH_COUNT,
}

@export var match_rule: MatchRule = MatchRule.MATCH_ANY
