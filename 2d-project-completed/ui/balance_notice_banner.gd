extends Control

## 현재 밸런스 구간과 다음 키프레임까지 진행 게이지를 상시 표시합니다.

var _timeline_alert_remaining := 0.0
var _timeline_alert_message := ""
var _last_segment: Dictionary = {}


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	%PhaseProgressBar.max_value = 100.0
	%PhaseProgressBar.show_percentage = false
	update_display({})


func refresh_locale() -> void:
	if not is_node_ready():
		return
	update_display(_last_segment)


func _process(delta: float) -> void:
	if _timeline_alert_remaining > 0.0:
		_timeline_alert_remaining = maxf(_timeline_alert_remaining - delta, 0.0)


# 타임라인 이벤트 경고 문구를 잠시 우선 표시합니다.
func show_timeline_alert(message: String, duration: float = 4.0) -> void:
	_timeline_alert_message = message.strip_edges()
	_timeline_alert_remaining = maxf(duration, 0.1)


# 밸런스 구간 문구·게이지·구간 라벨을 갱신합니다.
func update_display(segment: Dictionary) -> void:
	_last_segment = segment
	_apply_segment_labels(segment)

	if _timeline_alert_remaining > 0.0 and not _timeline_alert_message.is_empty():
		%NoticeLabel.text = _timeline_alert_message
		return

	var active: BalancePhase = segment.get("active", BalancePhase.new())
	var intent := active.design_intent.strip_edges()
	var minute_int := int(active.minute)
	if intent.is_empty():
		%NoticeLabel.text = UiLocale.t(&"hud.balance_phase")
	elif minute_int <= 0:
		%NoticeLabel.text = intent
	else:
		%NoticeLabel.text = UiLocale.format_balance_notice(minute_int, intent)


# 아레나 모드의 웨이브 상태를 밸런스 배너 영역에 표시합니다.
func update_arena_display(notice: String, progress: float, segment_text: String) -> void:
	_last_segment = {}
	%PhaseProgressBar.value = clampf(progress, 0.0, 1.0) * 100.0
	%SegmentLabel.text = segment_text

	if _timeline_alert_remaining > 0.0 and not _timeline_alert_message.is_empty():
		%NoticeLabel.text = _timeline_alert_message
	else:
		%NoticeLabel.text = notice


func _apply_segment_labels(segment: Dictionary) -> void:
	var progress: float = segment.get("progress", 0.0)
	%PhaseProgressBar.value = progress * 100.0
	var elapsed_minutes: float = segment.get("elapsed_minutes", 0.0)
	if segment.get("is_final", false):
		%SegmentLabel.text = UiLocale.format_balance_segment_final(elapsed_minutes)
	else:
		var next_minute: float = segment.get("next_minute", 0.0)
		%SegmentLabel.text = UiLocale.format_balance_segment_progress(elapsed_minutes, next_minute)
