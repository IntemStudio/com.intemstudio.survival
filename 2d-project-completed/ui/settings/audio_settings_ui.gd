extends VBoxContainer

## 일시정지 설정 — Master·BGM·SFX 볼륨 슬라이더.

@onready var _master_slider: HSlider = $MasterVolumeRow/MasterVolumeSlider
@onready var _bgm_slider: HSlider = $BgmVolumeRow/BgmVolumeSlider
@onready var _sfx_slider: HSlider = $SfxVolumeRow/SfxVolumeSlider
@onready var _master_label: Label = $MasterVolumeRow/MasterVolumeLabel
@onready var _bgm_label: Label = $BgmVolumeRow/BgmVolumeLabel
@onready var _sfx_label: Label = $SfxVolumeRow/SfxVolumeLabel
@onready var _audio_title: Label = get_node_or_null("../AudioSettingsTitle") as Label
@onready var _master_name: Label = get_node_or_null("MasterVolumeRow/MasterVolumeName") as Label
@onready var _bgm_name: Label = get_node_or_null("BgmVolumeRow/BgmVolumeName") as Label
@onready var _sfx_name: Label = get_node_or_null("SfxVolumeRow/SfxVolumeName") as Label

var _syncing := false


func _ready() -> void:
	add_to_group(UiLocale.GROUP_REFRESH)
	_setup_slider(_master_slider)
	_setup_slider(_bgm_slider)
	_setup_slider(_sfx_slider)
	_master_slider.value_changed.connect(_on_volume_changed)
	_bgm_slider.value_changed.connect(_on_volume_changed)
	_sfx_slider.value_changed.connect(_on_volume_changed)
	sync_from_audio()
	refresh_locale()


func refresh_locale() -> void:
	if _audio_title:
		_audio_title.text = UiLocale.t(&"settings.audio")
	if _master_name:
		_master_name.text = UiLocale.t(&"settings.master")
	if _bgm_name:
		_bgm_name.text = UiLocale.t(&"settings.bgm")
	if _sfx_name:
		_sfx_name.text = UiLocale.t(&"settings.sfx")
	_update_labels()


# 현재 버스·저장 볼륨으로 슬라이더를 맞춥니다.
func sync_from_audio() -> void:
	_syncing = true
	var state := AudioSettings.read_current()
	_master_slider.set_value_no_signal(state[AudioSettings.KEY_MASTER] * 100.0)
	_bgm_slider.set_value_no_signal(state[AudioSettings.KEY_BGM] * 100.0)
	_sfx_slider.set_value_no_signal(state[AudioSettings.KEY_SFX] * 100.0)
	_update_labels()
	_syncing = false


func _setup_slider(slider: HSlider) -> void:
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0


func _on_volume_changed(_value: float) -> void:
	if _syncing:
		return
	_update_labels()
	AudioSettings.apply(
		_master_slider.value / 100.0,
		_bgm_slider.value / 100.0,
		_sfx_slider.value / 100.0
	)


func _update_labels() -> void:
	_master_label.text = AudioSettings.percent_label(_master_slider.value / 100.0)
	_bgm_label.text = AudioSettings.percent_label(_bgm_slider.value / 100.0)
	_sfx_label.text = AudioSettings.percent_label(_sfx_slider.value / 100.0)
