extends Control

## 현재 밸런스 구간과 다음 키프레임까지 진행 게이지를 상시 표시합니다.

var _timeline_alert_remaining := 0.0
var _timeline_alert_message := ""


func _ready() -> void:
	%PhaseProgressBar.max_value = 100.0
	%PhaseProgressBar.show_percentage = false
	update_display({})


func _process(delta: float) -> void:
	if _timeline_alert_remaining > 0.0:
		_timeline_alert_remaining = maxf(_timeline_alert_remaining - delta, 0.0)


# 타임라인 이벤트 경고 문구를 잠시 우선 표시합니다.
func show_timeline_alert(message: String, duration: float = 4.0) -> void:
	_timeline_alert_message = message.strip_edges()
	_timeline_alert_remaining = maxf(duration, 0.1)


# 밸런스 구간 문구·게이지·구간 라벨을 갱신합니다.
func update_display(segment: Dictionary) -> void:
	if _timeline_alert_remaining > 0.0 and not _timeline_alert_message.is_empty():
		%NoticeLabel.text = _timeline_alert_message
		var progress: float = segment.get("progress", 0.0)
		%PhaseProgressBar.value = progress * 100.0
		var elapsed_minutes: float = segment.get("elapsed_minutes", 0.0)
		if segment.get("is_final", false):
			%SegmentLabel.text = "%.0f분 · 최종 구간" % elapsed_minutes
		else:
			var next_minute: float = segment.get("next_minute", 0.0)
			%SegmentLabel.text = "%.1f / %.0f분" % [elapsed_minutes, next_minute]
		return

	var active: BalancePhase = segment.get("active", BalancePhase.new())
	var intent := active.design_intent.strip_edges()
	var minute_int := int(active.minute)
	if intent.is_empty():
		%NoticeLabel.text = "밸런스 구간"
	elif minute_int <= 0:
		%NoticeLabel.text = intent
	else:
		%NoticeLabel.text = "%d분 · %s" % [minute_int, intent]

	var progress: float = segment.get("progress", 0.0)
	%PhaseProgressBar.value = progress * 100.0

	var elapsed_minutes: float = segment.get("elapsed_minutes", 0.0)
	if segment.get("is_final", false):
		%SegmentLabel.text = "%.0f분 · 최종 구간" % elapsed_minutes
	else:
		var next_minute: float = segment.get("next_minute", 0.0)
		%SegmentLabel.text = "%.1f / %.0f분" % [elapsed_minutes, next_minute]
