## ADDED Requirements

### Requirement: MetricsLogger buffers session results in memory
`MetricsLogger` (autoload) SHALL append a finished minigame session's data to an in-memory buffer via a
public method that accepts the already-shipped typed `MinigameResult` object. It SHALL NOT write to disk
as part of this call.

#### Scenario: Recording a session appends to the in-memory buffer without disk I/O
- **WHEN** a minigame session finishes and its `MinigameResult` is passed to `MetricsLogger`'s recording
  method
- **THEN** the entry is appended to an in-memory buffer and no file write occurs during that call

### Requirement: Flush only at safe points
`MetricsLogger` SHALL append its buffered entries to the local telemetry file only when a minigame session
finishes, or when the engine notifies `NOTIFICATION_APPLICATION_PAUSED` / `NOTIFICATION_WM_CLOSE_REQUEST`.
It SHALL NOT write to disk on any other event (e.g. once per tap).

#### Scenario: Flush happens on session end
- **WHEN** a minigame session finishes
- **THEN** the buffered entries (including the one just recorded) are appended to the telemetry file

#### Scenario: Flush happens before the app backgrounds or closes
- **WHEN** the engine emits `NOTIFICATION_APPLICATION_PAUSED` or `NOTIFICATION_WM_CLOSE_REQUEST`
- **THEN** any buffered-but-unflushed entries are appended to the telemetry file before the notification
  handler returns

### Requirement: Telemetry writes are atomic and independent of SaveManager
`MetricsLogger` SHALL write its telemetry file (`user://metrics_log.json`) using the same atomic
write-then-rename discipline `SaveManager` uses for save data, but through its own independent I/O code
path — never by calling into `SaveManager`.

#### Scenario: Telemetry file is written atomically
- **WHEN** `MetricsLogger` flushes its buffer to disk
- **THEN** it writes to a temporary file and renames it into place, never leaving a partially-written
  `metrics_log.json`

#### Scenario: MetricsLogger never calls SaveManager
- **WHEN** the codebase is searched for calls from `MetricsLogger.gd` into `SaveManager`
- **THEN** no such call exists

### Requirement: A flush failure never crashes or blocks the session
If writing the telemetry file fails for any reason (disk full, permission denied, or any other I/O error),
`MetricsLogger` SHALL log a `push_warning`, discard the pending buffer for that flush, and return normally.
It SHALL NOT throw, retry synchronously, or block the caller.

#### Scenario: A write failure is swallowed silently from the child's perspective
- **WHEN** the telemetry file write fails during a flush
- **THEN** a `push_warning` is logged, the buffered entries for that flush are discarded, and gameplay
  continues completely unaffected

### Requirement: No remote transmission
`MetricsLogger` SHALL perform local file I/O only. It SHALL NOT open any network connection or transmit
any data off-device.

#### Scenario: No network code path exists
- **WHEN** `MetricsLogger.gd` is inspected for networking APIs (`HTTPRequest`, `WebSocketPeer`, etc.)
- **THEN** none are present
