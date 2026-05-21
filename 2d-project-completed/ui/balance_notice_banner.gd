extends Control

## 현재 밸런스 구간과 다음 키프레임까지 진행 게이지를 상시 표시합니다.


func _ready() -> void:
	%PhaseProgressBar.max_value = 100.0
	%PhaseProgressBar.show_percentage = false
	update_display({})


# 밸런스 구간 문구·게이지·구간 라벨을 갱신합니다.
func update_display(segment: Dictionary) -> void:
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
