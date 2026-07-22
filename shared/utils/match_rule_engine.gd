class_name MatchRuleEngine
extends RefCounted

## Motor genérico de coincidencia (GDD_MVP.md §4: "un motor, no un juego").
## Añadir un nuevo MatchRule (Fase 2+) es una rama nueva aquí, nunca una edición
## de las ramas existentes.

static func matches(balloon_color_id: StringName, config: LevelConfig) -> bool:
	match config.match_rule:
		LevelConfig.MatchRule.MATCH_ANY:
			return true
		LevelConfig.MatchRule.MATCH_COLOR:
			var balloon_config: BalloonLevelConfig = config as BalloonLevelConfig
			return balloon_config != null and balloon_color_id == balloon_config.target_color_id
		_:
			return false
