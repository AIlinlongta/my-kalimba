extends Control

# ==================== 配置区 ====================

# 17音卡林巴音阶（从低音到高音排列）
const NOTES: Array = [
	"C4", "D4", "E4", "F4", "G4", "A4", "B4",
	"C5", "D5", "E5", "F5", "G5", "A5", "B5",
	"C6", "D6", "E6"
]

# 音频路径
## 练习/演示可选速度倍率（150% / 125% / 100% / 75% / 50% / 25%）
const SPEED_OPTIONS: Array = [1.5, 1.25, 1.0, 0.75, 0.5, 0.25]

## 音色白名单：目录名 -> 显示名。_bak 等备份目录自动排除。
const _TIMBRES := {
	"kalimba": "卡林巴0",
	"kalimba1": "卡林巴1",
	"piano": "钢琴0",
	"trumpet": "小号",
}

var _audio_path: String = "res://audio/kalimba1/kalimba1_"   # 当前音色目录前缀，默认卡林巴1
var _current_timbre: String = "kalimba1"  # 当前音色: "kalimba"/"kalimba1"/"piano"（默认卡林巴1）

# ---------- 颜色 ----------
const KEY_COLOR_NORMAL: Color = Color(1.0, 0.98, 0.92)    # 奶白色
const KEY_COLOR_ACCENT: Color = Color(0.52, 0.78, 0.96)   # 蓝色（C/E/G）
const KEY_COLOR_PRESSED: Color = Color(0.58, 0.52, 0.44)  # 按下变暗
const KEY_BORDER_COLOR: Color = Color(0.50, 0.38, 0.22)   # 浅棕边框
const KEY_BEAM_COLOR: Color = Color(0.72, 0.60, 0.42)     # 顶部横梁木色
const KEY_DOT_COLOR: Color = Color(0.35, 0.25, 0.14)      # 螺丝孔

# ---------- 布局 ----------
const KEY_GAP: float = 3.0
const KEY_WIDTH_MIN: float = 32.0
const KEY_HEIGHT_MAX_RATIO: float = 0.72   # 基本模式最长键占屏高比例
const KEY_TOP_MARGIN_RATIO_BASE: float = 0.0   # 基本模式顶部留白（键贴顶）
const LABEL_GAP: float = 10.0              # 标签与键底间距
const BEAM_HEIGHT_RATIO: float = 0.055     # 横梁高度占屏高

# 雁形高度系数（视觉 0-16 左→右，中心 8 = 1.0 最长）
# 严格对称 + 严格等差：每步减 0.065，最左/最右 = 1.00 - 8*0.065 = 0.48
const GOOSE_HEIGHT_RATIO: Array = [
	0.480, 0.545, 0.610, 0.675, 0.740, 0.805, 0.870, 0.935, 1.000,
	0.935, 0.870, 0.805, 0.740, 0.675, 0.610, 0.545, 0.480
]

# 视觉位置 (L→R) → NOTES 数组下标（拇指琴交叉排列）
const VISUAL_TO_NOTES_IDX: Array = [
	15, 13, 11, 9, 7, 5, 3, 1, 0, 2, 4, 6, 8, 10, 12, 14, 16
]

# 简谱映射（每个音符 → 简谱文字）
const JIANPU_MAP: Dictionary = {
	"C4": "1\u0323", "D4": "2\u0323", "E4": "3\u0323", "F4": "4\u0323",
	"G4": "5\u0323", "A4": "6\u0323", "B4": "7\u0323",
	"C5": "1", "D5": "2", "E5": "3", "F5": "4", "G5": "5", "A5": "6", "B5": "7",
	"C6": "1\u0307", "D6": "2\u0307", "E6": "3\u0307",
}

# ---------- 按钮 ----------
const BTN_COLOR: Color = Color(0.22, 0.22, 0.26)
const BTN_COLOR_HOVER: Color = Color(0.32, 0.32, 0.38)
const BTN_COLOR_PRESSED: Color = Color(0.14, 0.14, 0.18)
const BTN_COLOR_DISABLED: Color = Color(0.38, 0.38, 0.42)
const BTN_TEXT_COLOR: Color = Color(1, 1, 1)
const BTN_TEXT_DISABLED_COLOR: Color = Color(0.65, 0.65, 0.68)
const BTN_SIZE: Vector2 = Vector2(112, 52)
const BTN_GAP: float = 12.0
const BTN_BOTTOM_MARGIN: float = 28.0

# 切换按钮（半圆形）
const TOGGLE_BTN_SIZE: Vector2 = Vector2(80, 40)

# 键长调节
const LENGTH_STEP: float = 0.08
const LENGTH_MIN: float = 0.55    # 最短限制
const LENGTH_MAX: float = 1.35    # 最长限制

# 触摸
const KEY_EXTRA_TOUCH: int = 20

# ---------- 乐谱 / 练习模式 ----------
const SCORE_BTN_SIZE: Vector2 = Vector2(96, 48)
const SCORE_BTN_BOTTOM_MARGIN: float = 28.0
const SIDEBAR_WIDTH_RATIO: float = 0.34     # 侧边栏占屏宽比例
const SIDEBAR_COLOR: Color = Color(0.16, 0.16, 0.20)
const SIDEBAR_HEAD_COLOR: Color = Color(0.22, 0.22, 0.27)

# 练习指引区 / 下落槽（「上槽下键、判定线带点」一体式布局）
const GUIDE_HEIGHT_RATIO: float = 0.4    # 下落槽（=/琴键起始边界）占屏高比例
const LAND_LINE_COLOR: Color = Color(1, 1, 1, 0.30)   # 判定线
const SLOT_COLOR: Color = Color(0.055, 0.055, 0.085, 0.82)   # 每列下落槽底色
const BAR_GREEN: Color = Color(0.30, 0.92, 0.40)
const BAR_RED: Color = Color(0.95, 0.30, 0.32)
const BAR_BLUE: Color = Color(0.35, 0.60, 1.00)   # 非主旋律且单独启动
const HIT_FLASH_COLOR: Color = Color(0.30, 0.60, 1.00)   # 敲击瞬间键体蓝色高亮
const BAR_HEIGHT: float = 9.0
const LEAD_TIME: float = 2.5   # 横杠从顶到底基础引导时间(秒)
const BAR_SPEED_MULT: float = 1.4   # 独立下落速度倍速（>1 加快下落；节奏不变）
const HIT_SNAP: float = 0.05   # 同拍判定时间窗(秒)
const MIDI_DIR: String = "user://midi"       # 用户可写乐谱目录
const MIDI_DIR_BUNDLED: String = "res://midi" # 打包内置乐谱（首次运行拷贝到 user://midi）
const MAX_NAME_LEN: int = 40   # 曲名最大展示字符数，超长从后往前保留末尾
# MIDI 音符号 -> 17 音琴键（本项目 MIDI 由工具生成，范围 C4-E6）
const MIDI_C4: int = 60
const MIDI_NAME_PC: Array = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

# ==================== 数据区 ====================

var _preloaded_samples: Dictionary = {}
var _keys: Array = []                       # 每个元素是 Panel（琴键主体，StyleBoxFlat 负责圆角/阴影/边框）
var _key_labels: Array = []                 # 每个键内的 Label（Panel 的子节点，位于键的下半部分）
var _beam: ColorRect                    # 顶部横梁
var _key_note_map: Dictionary = {}
var _note_key_map: Dictionary = {}
var _touch_key_map: Dictionary = {}
var _audio_players: Dictionary = {}
var _key_player_map: Dictionary = {}  # 每个按键当前使用的播放器实例
var _layout_built: bool = false

# 力度相关
var _key_press_times: Dictionary = {}  # 记录每个琴键的按下时间戳
var _active_tweens: Dictionary = {}    # 记录每个琴键正在运行的 Tween
const MIN_PRESS_DURATION: float = 0.02   # 最短按下时间（秒）- 快速敲击
const MAX_PRESS_DURATION: float = 0.50   # 最长按下时间（秒）- 慢速按住
const MIN_VOLUME_SCALE: float = 0.3     # 弱力度音量倍数
const MAX_VOLUME_SCALE: float = 1.5     # 强力度音量倍数
const BASE_VOLUME_DB: float = 0.0       # 基础音量 dB

var _label_mode: int = 0                # 0 = 音名  1 = 简谱
var _length_factor: float = 1.0

var _btn_timbre: Button       # 音色切换按钮
var _btn_toggle: Button
var _btn_plus: Button
var _btn_minus: Button
var _btn_show_hide: Button
var _popup: Panel             # 音色选择弹出菜单
var _popup_items: Array = []  # 菜单项按钮

var _buttons_visible: bool = true

# ---------- 乐谱 / 练习状态 ----------
var _btn_score: Button
var _btn_import: Button
var _btn_back_base: Button
var _btn_restart: Button       # 练习/演示「重新开始」按钮
var _btn_speed: Button         # 练习/演示「速度」按钮
var _speed_mult: float = 1.0   # 播放速度倍率（默认 100%），跨进出练习保留
var _speed_popup: Panel        # 速度选择弹层
var _speed_popup_items: Array = []
var _sidebar: Panel
var _sidebar_scroll: ScrollContainer
var _sidebar_content: VBoxContainer
var _tab_import: Button
var _tab_record: Button
var _sidebar_open: bool = false
var _score_buttons: Array = []   # 每个乐谱的按钮组引用：[[name, path, btn_practice, btn_demo, name_lbl, name_clip, btn_del], ...]
var _toast_label: Label
var _toast_timer: Timer
var _import_dialog: FileDialog
var _delete_dialog: ConfirmationDialog
var _pending_delete_path: String = ""
var _pending_delete_name: String = ""

var _guide_area: ColorRect        # 练习指引区
var _guide_label: Label           # 顶部标题/模式
var _key_slots: Array = []        # 每列下落槽（ColorRect）
var _land_line: ColorRect         # 贯穿判定线
var _land_dots: Array = []        # 判定线上的圆点
var _bars: Array = []             # 下落横杠（ColorRect）
var _bar_meta: Array = []         # 与 bars 对应：[note, start_sec, key_ref, hit_done, is_melody]
var _practice_active: bool = false
var _practice_mode: String = ""   # "" = 未进入, "practice" = 练习, "demo" = 演示
var _current_midi: Array = []     # 当前乐谱音符 [{midi,start,dur}]
var _current_path: String = ""
var _play_musical_sec: float = 0.0   # 乐谱音乐的当前时刻
var _midi_note_map: Dictionary = {}  # midi音号 -> note名

# ==================== 生命周期 ====================

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_preload_all_audio()
	_build_audio_player_pool()
	_build_midi_note_map()
	_try_build_layout()
	set_process(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_try_build_layout()
		if _practice_active:
			_reflow_practice_overlay()

## 分辨率变化时同步下落槽/判定线/圆点/横杠起始位置
func _reflow_practice_overlay() -> void:
	if not _practice_active:
		return
	var land_y := _column_top()
	if _guide_label and is_instance_valid(_guide_label):
		_guide_label.size = Vector2(size.x, 40)
	for i in range(_keys.size()):
		var key: Panel = _keys[i]
		if i < _key_slots.size() and is_instance_valid(_key_slots[i]):
			_key_slots[i].position = Vector2(key.position.x, 0)
			_key_slots[i].size = Vector2(key.size.x, land_y)
	if _land_line and is_instance_valid(_land_line):
		_land_line.size.x = size.x
		_land_line.position.y = land_y - 2.0

# ==================== 音频 / 播放器 ====================

func _preload_all_audio() -> void:
	_preloaded_samples.clear()
	for note in NOTES:
		var stream: AudioStream = load(_audio_path + note + ".wav")
		if stream:
			_preloaded_samples[note] = stream
		else:
			push_error("音频加载失败: " + note)
	print("音色 %s 预加载完成: %d/%d" % [_current_timbre, _preloaded_samples.size(), NOTES.size()])

func _build_audio_player_pool() -> void:
	_audio_players.clear()
	for child in get_children():
		if child is AudioStreamPlayer:
			child.queue_free()

	for note in NOTES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Master"
		player.volume_db = 0.0
		player.stream = _preloaded_samples.get(note)
		add_child(player)
		_audio_players[note] = player

# ---------- MIDI 音号 -> 17 音琴键映射 ----------

func _midi_to_note_name(midi: int) -> String:
	var pc: String = MIDI_NAME_PC[midi % 12]
	var octave: int = midi / 12 - 1
	return "%s%d" % [pc, octave]

func _build_midi_note_map() -> void:
	_midi_note_map.clear()
	for note in NOTES:
		var m := _note_to_midi(note)
		_midi_note_map[m] = note

func _note_to_midi(note: String) -> int:
	# 形如 "C4","C#5"——本项目音名不含升号(17音为自然音)，直接解析字母+数字
	var letter: String = note.substr(0, 1)
	var oct: int = int(note.substr(1, note.length() - 1))
	var pc: int = MIDI_NAME_PC.find(letter)
	return (oct + 1) * 12 + pc

## 将 MIDI 音号映射到最近的一个 17 音琴键名
func _midi_to_keynote(midi: int) -> String:
	if _midi_note_map.has(midi):
		return _midi_note_map[midi]
	# 精确无对应(如 # 音)，找最近的琴键
	var best_note := NOTES[0]
	var best_diff := 99999
	for note in NOTES:
		var d: int = abs(_note_to_midi(note) - midi)
		if d < best_diff:
			best_diff = d
			best_note = note
	return best_note

# ==================== 布局 ====================

func _try_build_layout() -> void:
	if not _layout_built:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		_build_beam()
		_build_key_layout()
		_build_buttons()
		_layout_built = true
	else:
		_reflow_beam()
		_reflow_key_layout()
		_reflow_buttons()

func _compute_key_width() -> float:
	var n: int = NOTES.size()
	var avail: float = size.x - (n - 1) * KEY_GAP
	return max(KEY_WIDTH_MIN, avail / n)

# 是否处于练习/演示模式（用于决定琴键顶部位置）
func _is_practice_mode() -> bool:
	return _practice_active

# 琴键顶部 Y：基本模式贴屏幕顶部附近；练习模式让出上 1/3 给下落槽与判定线
func _column_top() -> float:
	return size.y * GUIDE_HEIGHT_RATIO

func _key_top_y() -> float:
	if _is_practice_mode():
		return _column_top()
	return size.y * KEY_TOP_MARGIN_RATIO_BASE

# 琴键主体可用高度，按长度系数缩放
func _key_max_h() -> float:
	if _is_practice_mode():
		var avail := size.y - _column_top()   # 槽下方可用高度（2/3屏高）
		var h: float = avail * 0.90 * _length_factor
		# 自动钳制：无论 factor 多大，最长键底部不越界（留 2% 屏高安全边距）
		return min(h, avail - size.y * 0.02)
	return size.y * KEY_HEIGHT_MAX_RATIO * _length_factor

# 下次进入/退出练习模式时重建键位置（沿用已有键，仅重排）
func _apply_key_top() -> void:
	if _layout_built:
		_reflow_key_layout()
		_reflow_beam()
		if _practice_active:
			_reflow_practice_overlay()

func _is_accent(note: String) -> bool:
	return note.begins_with("C") or note.begins_with("E") or note.begins_with("G")

# 参考图风格：视觉位置上的蓝色提示键（4 个）
const ACCENT_VISUAL_POS: Array = [2, 4, 8, 14]

func _is_accent_pos(visual_idx: int) -> bool:
	return ACCENT_VISUAL_POS.has(visual_idx)

func _label_text(note: String) -> String:
	if _label_mode == 1:
		return JIANPU_MAP.get(note, note)
	return note

# ---------- 顶部横梁 ----------

func _build_beam() -> void:
	_beam = ColorRect.new()
	_beam.name = "Beam"
	_beam.color = KEY_BEAM_COLOR
	_beam.z_index = 10
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = KEY_BEAM_COLOR
	sb.border_color = Color(0.42, 0.32, 0.18)
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	_beam.add_theme_stylebox_override("panel", sb)
	add_child(_beam)
	_reflow_beam()

func _reflow_beam() -> void:
	if not _beam:
		return
	var beam_h: float = max(16.0, size.y * BEAM_HEIGHT_RATIO)
	var key_w: float = _compute_key_width()
	var n: int = NOTES.size()
	var content_w: float = n * key_w + (n - 1) * KEY_GAP
	var start_x: float = (size.x - content_w) * 0.5
	var top_y: float = _key_top_y()
	_beam.position = Vector2(start_x - 8.0, top_y)
	_beam.size = Vector2(content_w + 16.0, beam_h)

# ---------- 17 个琴键 ----------

func _build_key_layout() -> void:
	var key_w: float = _compute_key_width()
	var n: int = NOTES.size()
	var content_w: float = n * key_w + (n - 1) * KEY_GAP
	var offset_x: float = (size.x - content_w) * 0.5
	var max_h: float = _key_max_h()
	var top_y: float = _key_top_y()

	for vi in range(n):
		var ni: int = VISUAL_TO_NOTES_IDX[vi]
		var note: String = NOTES[ni]
		var h: float = max_h * GOOSE_HEIGHT_RATIO[vi]

		# 注意：必须用 Panel（不能用 ColorRect），ColorRect 不绘制 StyleBoxFlat 圆角/阴影
		var key: Panel = Panel.new()
		key.name = "Key_%s" % note
		var base: Color = KEY_COLOR_ACCENT if _is_accent_pos(vi) else KEY_COLOR_NORMAL
		key.position = Vector2(offset_x + vi * (key_w + KEY_GAP), top_y)
		key.size = Vector2(key_w, h)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		key.z_index = 5
		add_child(key)

		# 样式：底部完全半圆 + 两侧直边（真实拇指琴弹片造型）
		var bottom_r: int = int(max(10.0, key_w * 0.5))   # 宽度一半 → 底部整圆
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = base
		style.border_color = KEY_BORDER_COLOR
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 0
		style.border_width_bottom = 1
		style.corner_radius_bottom_left = bottom_r
		style.corner_radius_bottom_right = bottom_r
		# 柔和立体阴影（右下偏移，像光从左上打来）
		style.shadow_color = Color(0, 0, 0, 0.28)
		style.shadow_size = 5
		style.shadow_offset = Vector2(0, 3)
		key.add_theme_stylebox_override("panel", style)

		# 螺丝孔（左右两颗小钉，更像真实拇指琴）
		var dot_sz: float = max(3.5, key_w * 0.12)
		for side_x_off in [key_w * 0.25, key_w * 0.75]:
			var dot: ColorRect = ColorRect.new()
			dot.color = KEY_DOT_COLOR
			dot.size = Vector2(dot_sz, dot_sz)
			dot.position = Vector2(side_x_off - dot_sz * 0.5, max(3.0, key_w * 0.10))
			key.add_child(dot)

		# 标注（位于琴键内部的下半部分，不贴底缘）
		var lbl: Label = Label.new()
		lbl.text = _label_text(note)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_color_override("font_color", Color(0.15, 0.10, 0.05))
		lbl.add_theme_font_size_override("font_size", int(max(11, key_w * 0.40)))
		# 锚定 FULL_RECT 后，把 label 挤在键身下半段，距离底部再缩进 22% 键宽，避免贴边像在键外
		lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lbl.offset_top = int(key_w * 0.55)
		lbl.offset_bottom = int(-max(6.0, key_w * 0.22))
		key.add_child(lbl)

		key.set_meta("base_color", base)
		key.set_meta("visual_idx", vi)

		_keys.append(key)
		_key_labels.append(lbl)
		_key_note_map[key] = note
		_note_key_map[note] = key

func _reflow_key_layout() -> void:
	var key_w: float = _compute_key_width()
	var n: int = NOTES.size()
	var content_w: float = n * key_w + (n - 1) * KEY_GAP
	var offset_x: float = (size.x - content_w) * 0.5
	var max_h: float = _key_max_h()
	var top_y: float = _key_top_y()

	for vi in range(n):
		var key: Panel = _keys[vi]
		var h: float = max_h * GOOSE_HEIGHT_RATIO[vi]
		key.position = Vector2(offset_x + vi * (key_w + KEY_GAP), top_y)
		key.size = Vector2(key_w, h)

		# 更新样式圆角（随宽度变化）：底部整半圆 + 阴影
		var bottom_r: int = int(max(10.0, key_w * 0.5))
		var style: StyleBoxFlat = key.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.corner_radius_bottom_left = bottom_r
			style.corner_radius_bottom_right = bottom_r
			style.shadow_size = 5
			style.shadow_offset = Vector2(0, 3)

		# 更新螺丝孔位置（key 的前两个子节点：dot0, dot1）
		var dot_sz: float = max(3.5, key_w * 0.12)
		var dot_y: float = max(3.0, key_w * 0.10)
		var dxs: Array = [key_w * 0.25, key_w * 0.75]
		for di in range(min(2, key.get_child_count())):
			var dot: ColorRect = key.get_child(di)
			if dot is ColorRect:
				dot.size = Vector2(dot_sz, dot_sz)
				dot.position = Vector2(dxs[di] - dot_sz * 0.5, dot_y)

		# 更新标注：挤在键下半段，字号、底部缩进
		var lbl: Label = _key_labels[vi]
		if lbl:
			lbl.add_theme_font_size_override("font_size", int(max(11, key_w * 0.40)))
			lbl.offset_top = int(key_w * 0.55)
			lbl.offset_bottom = int(-max(6.0, key_w * 0.22))

# ==================== 控制按钮 ====================

func _mk_btn_style(c: Color) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = c
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.corner_radius_bottom_left = 10
	s.corner_radius_bottom_right = 10
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.08, 0.08, 0.10)
	return s

func _make_button(text: String) -> Button:
	return _make_custom_button(text, BTN_SIZE)

func _make_small_button(text: String) -> Button:
	return _make_custom_button(text, SCORE_BTN_SIZE)

func _make_custom_button(text: String, btn_size: Vector2) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = btn_size
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.z_index = 20

	btn.add_theme_stylebox_override("normal", _mk_btn_style(BTN_COLOR))
	btn.add_theme_stylebox_override("hover", _mk_btn_style(BTN_COLOR_HOVER))
	btn.add_theme_stylebox_override("pressed", _mk_btn_style(BTN_COLOR_PRESSED))
	btn.add_theme_stylebox_override("disabled", _mk_btn_style(BTN_COLOR_DISABLED))

	btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
	btn.add_theme_color_override("font_hover_color", BTN_TEXT_COLOR)
	btn.add_theme_color_override("font_pressed_color", BTN_TEXT_COLOR)
	btn.add_theme_color_override("font_disabled_color", BTN_TEXT_DISABLED_COLOR)
	btn.add_theme_font_size_override("font_size", 18)
	add_child(btn)
	return btn

func _mk_semicircle_style(c: Color) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = c
	var r: int = int(TOGGLE_BTN_SIZE.y)   # 上半部完全圆角 = 半圆
	s.corner_radius_top_left = r
	s.corner_radius_top_right = r
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.08, 0.08, 0.10)
	return s

func _build_semicircle_button() -> Button:
	var btn: Button = Button.new()
	btn.text = "▼"
	btn.custom_minimum_size = TOGGLE_BTN_SIZE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.z_index = 20

	btn.add_theme_stylebox_override("normal", _mk_semicircle_style(BTN_COLOR))
	btn.add_theme_stylebox_override("hover", _mk_semicircle_style(BTN_COLOR_HOVER))
	btn.add_theme_stylebox_override("pressed", _mk_semicircle_style(BTN_COLOR_PRESSED))
	btn.add_theme_stylebox_override("disabled", _mk_semicircle_style(BTN_COLOR_DISABLED))

	btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
	btn.add_theme_color_override("font_hover_color", BTN_TEXT_COLOR)
	btn.add_theme_color_override("font_pressed_color", BTN_TEXT_COLOR)
	btn.add_theme_color_override("font_disabled_color", BTN_TEXT_DISABLED_COLOR)
	btn.add_theme_font_size_override("font_size", 16)
	add_child(btn)
	return btn

func _build_buttons() -> void:
	_btn_timbre = _make_button("音色:" + _TIMBRES[_current_timbre])
	_btn_toggle = _make_button("切换标注")
	_btn_plus = _make_button("+")
	_btn_minus = _make_button("-")
	_btn_timbre.pressed.connect(_on_timbre_button_pressed)
	_btn_toggle.pressed.connect(_on_toggle_label)
	_btn_plus.pressed.connect(_on_plus)
	_btn_minus.pressed.connect(_on_minus)

	_build_popup_menu()

	_btn_show_hide = _build_semicircle_button()
	_btn_show_hide.pressed.connect(_on_toggle_buttons)

	# 左下角「乐谱」按钮
	_btn_score = _make_small_button("乐谱")
	_btn_score.pressed.connect(_on_score_button_pressed)
	_btn_score.visible = true

	# 「导入」按钮（紧挨乐谱右侧，用于从系统文件选择器导入 MIDI）
	_btn_import = _make_small_button("导入")
	_btn_import.pressed.connect(_on_import_button_pressed)
	_btn_import.visible = true

	# 「返回基本模式」按钮（紧挨导入右侧，仅练习/演示时显示）
	_btn_back_base = _make_small_button("返回基本模式")
	_btn_back_base.pressed.connect(_on_back_base_pressed)
	_btn_back_base.visible = false

	# 「重新开始」按钮（返回基本模式右侧，仅练习/演示时显示，从头播放当前曲）
	_btn_restart = _make_small_button("重启")
	_btn_restart.pressed.connect(_on_restart_pressed)
	_btn_restart.visible = false

	# 「速度」按钮（重新开始右侧，仅练习/演示时显示，选择 100/75/50/25%）
	_btn_speed = _make_small_button("速度:%d%%" % int(round(_speed_mult * 100.0)))
	_btn_speed.pressed.connect(_on_speed_button_pressed)
	_btn_speed.visible = false
	_build_speed_menu()

	_update_btn_enabled()
	_reflow_buttons()

func _reflow_buttons() -> void:
	if not _btn_timbre:
		return

	# 切换按钮始终定位在底部中央
	var toggle_x: float = (size.x - TOGGLE_BTN_SIZE.x) * 0.5
	var toggle_y: float = size.y - TOGGLE_BTN_SIZE.y
	_btn_show_hide.position = Vector2(toggle_x, toggle_y)

	# 按可见性调整所有按钮位置
	var y: float = size.y - BTN_SIZE.y - BTN_BOTTOM_MARGIN
	var total_w: float = BTN_SIZE.x * 4 + BTN_GAP * 3
	var start_x: float = size.x - total_w - 24.0
	_btn_timbre.position = Vector2(start_x, y)
	_btn_toggle.position = Vector2(start_x + BTN_SIZE.x + BTN_GAP, y)
	_btn_plus.position = Vector2(start_x + (BTN_SIZE.x + BTN_GAP) * 2, y)
	_btn_minus.position = Vector2(start_x + (BTN_SIZE.x + BTN_GAP) * 3, y)

	# 所有按钮可见性统一由 _apply_button_visibility() 管理（半圆 + 练习模式两开关组合）
	_apply_button_visibility()

	# 左下角按钮按实际宽度顺排（乐谱 → 导入 → 返回基本模式 → 重启 → 速度）
	# 用 size + 间距逐一定位，避免固定步进导致长文本按钮重叠
	var left_x: float = 20.0
	if _btn_score:
		_btn_score.position = Vector2(left_x, size.y - SCORE_BTN_SIZE.y - SCORE_BTN_BOTTOM_MARGIN)
		left_x += _btn_score.size.x + 8.0
	if _btn_import:
		_btn_import.position = Vector2(left_x, size.y - SCORE_BTN_SIZE.y - SCORE_BTN_BOTTOM_MARGIN)
		left_x += _btn_import.size.x + 8.0
	if _btn_back_base:
		_btn_back_base.position = Vector2(left_x, size.y - SCORE_BTN_SIZE.y - SCORE_BTN_BOTTOM_MARGIN)
		left_x += _btn_back_base.size.x + 8.0
	if _btn_restart:
		_btn_restart.position = Vector2(left_x, size.y - SCORE_BTN_SIZE.y - SCORE_BTN_BOTTOM_MARGIN)
		left_x += _btn_restart.size.x + 8.0
	if _btn_speed:
		_btn_speed.position = Vector2(left_x, size.y - SCORE_BTN_SIZE.y - SCORE_BTN_BOTTOM_MARGIN)
		left_x += _btn_speed.size.x + 8.0

	_reflow_popup()
	_reflow_speed_popup()

func _update_btn_enabled() -> void:
	if _btn_plus:
		_btn_plus.disabled = (_length_factor >= LENGTH_MAX - 0.0001)
	if _btn_minus:
		_btn_minus.disabled = (_length_factor <= LENGTH_MIN + 0.0001)

func _on_toggle_label() -> void:
	_label_mode = 1 - _label_mode
	for i in range(_keys.size()):
		var note: String = _key_note_map.get(_keys[i], "")
		var lbl: Label = _key_labels[i]
		if lbl and note != "":
			lbl.text = _label_text(note)

func _on_plus() -> void:
	_length_factor = min(LENGTH_MAX, _length_factor + LENGTH_STEP)
	_reflow_key_layout()
	_update_btn_enabled()

func _on_minus() -> void:
	_length_factor = max(LENGTH_MIN, _length_factor - LENGTH_STEP)
	_reflow_key_layout()
	_update_btn_enabled()

func _on_toggle_buttons() -> void:
	_buttons_visible = not _buttons_visible
	if _buttons_visible:
		_btn_show_hide.text = "▼"
	else:
		_btn_show_hide.text = "▲"
	_apply_button_visibility()
	_hide_popup()

# ---------- 弹出菜单 ----------

func _build_popup_menu() -> void:
	_popup = Panel.new()
	_popup.name = "TimbrePopup"
	_popup.z_index = 30
	var popup_style: StyleBoxFlat = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.18, 0.18, 0.22)
	popup_style.border_color = Color(0.08, 0.08, 0.10)
	popup_style.border_width_left = 1
	popup_style.border_width_right = 1
	popup_style.border_width_top = 1
	popup_style.border_width_bottom = 1
	popup_style.corner_radius_bottom_left = 8
	popup_style.corner_radius_bottom_right = 8
	_popup.add_theme_stylebox_override("panel", popup_style)

	# 音色选项：扫描 res://audio/ 子目录，只采纳白名单音色，自动排除 _bak 备份目录
	var timbres: Array = []
	var dir := DirAccess.open("res://audio")
	if dir:
		dir.list_dir_begin()
		var dname := dir.get_next()
		while dname != "":
			if dir.current_is_dir() and not dname.begins_with(".") and _TIMBRES.has(dname):
				timbres.append([dname, _TIMBRES[dname]])
			dname = dir.get_next()
		dir.list_dir_end()
	# 按白名单顺序稳定排列：卡林巴0 → 卡林巴1 → 钢琴0 → 小号
	var order: Array = ["kalimba", "kalimba1", "piano", "trumpet"]
	timbres.sort_custom(func(a, b): return order.find(a[0]) < order.find(b[0]))

	var item_h: float = 44.0
	for i in range(timbres.size()):
		var key: String = timbres[i][0]
		var label: String = timbres[i][1]

		var btn: Button = Button.new()
		btn.text = label
		btn.custom_minimum_size = Vector2(BTN_SIZE.x, item_h)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.z_index = 31
		btn.add_theme_stylebox_override("normal", _mk_btn_style(BTN_COLOR))
		btn.add_theme_stylebox_override("hover", _mk_btn_style(BTN_COLOR_HOVER))
		btn.add_theme_stylebox_override("pressed", _mk_btn_style(BTN_COLOR_PRESSED))
		btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
		btn.add_theme_color_override("font_hover_color", BTN_TEXT_COLOR)
		btn.add_theme_color_override("font_pressed_color", BTN_TEXT_COLOR)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_popup_item_selected.bind(key))
		_popup.add_child(btn)
		_popup_items.append(btn)

	# 初始隐藏
	_popup.visible = false
	add_child(_popup)

func _reflow_popup() -> void:
	if not _popup:
		return
	var item_h: float = 44.0
	var n: int = len(_popup_items)
	var popup_w: float = BTN_SIZE.x
	var popup_h: float = n * item_h
	var btn_rect: Rect2 = Rect2(_btn_timbre.position, _btn_timbre.size)
	var x: float = btn_rect.position.x
	var y: float = btn_rect.position.y - popup_h
	if y < 0:
		y = btn_rect.position.y + btn_rect.size.y
	_popup.position = Vector2(x, y)
	_popup.size = Vector2(popup_w, popup_h)

	for i in range(_popup_items.size()):
		var item: Button = _popup_items[i]
		item.position = Vector2(0, i * item_h)
		item.size = Vector2(popup_w, item_h)

func _show_popup() -> void:
	if not _popup:
		return
	_reflow_popup()
	_popup.visible = true

func _hide_popup() -> void:
	if _popup:
		_popup.visible = false

func _on_timbre_button_pressed() -> void:
	if not _buttons_visible:
		return
	if _popup and _popup.visible:
		_hide_popup()
	else:
		_show_popup()

func _on_popup_item_selected(timbre_key: String) -> void:
	_set_timbre(timbre_key)
	_hide_popup()

func _set_timbre(timbre_key: String) -> void:
	_current_timbre = timbre_key
	_audio_path = "res://audio/%s/%s_" % [timbre_key, timbre_key]
	_btn_timbre.text = "音色:" + _TIMBRES[timbre_key]

	# 重新加载音频
	_preload_all_audio()
	_build_audio_player_pool()

	# 清除按下时间记录
	_key_press_times.clear()
	_touch_key_map.clear()

	# 停止所有正在运行的 Tween
	var tweens: Array = _active_tweens.values()
	for tween in tweens:
		tween.kill()
	_active_tweens.clear()

	# 清理所有活动的播放器实例
	var active_players: Array = _key_player_map.values()
	for p in active_players:
		if is_instance_valid(p):
			p.stop()
			p.queue_free()
	_key_player_map.clear()

	print("已切换音色: %s" % timbre_key)

# ==================== 乐谱侧边栏 ====================

## 「导入」按钮：弹出系统文件选择器选 MIDI，适配后写入 user://midi/
func _on_import_button_pressed() -> void:
	_hide_popup()
	# 用 FileDialog 节点：Android 上 use_native_dialog=true 自动走系统选择器(SAF)，
	# 兼容桌面与真机。比 DisplayServer.file_dialog_show 的可移植性更好。
	if _import_dialog == null:
		_import_dialog = FileDialog.new()
		_import_dialog.title = "选择 MIDI 文件"
		_import_dialog.size = Vector2i(560, 480)
		_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_import_dialog.use_native_dialog = true
		_import_dialog.add_filter("*.mid", "MIDI 文件")
		_import_dialog.file_selected.connect(_on_import_file_selected)
		add_child(_import_dialog)
	_import_dialog.popup_centered()

func _on_import_file_selected(path: String) -> void:
	_on_import_dialog_callback(true, PackedStringArray([path]), 0)

## 系统文件选择器回调（selected, paths, filter）
func _on_import_dialog_callback(selected: bool, paths: PackedStringArray, _filter_index: int) -> void:
	if not selected or paths.is_empty():
		return
	_import_midi_file(paths[0])

## 核心导入流程：解析 → 校验 → 适配 → 写盘 → 刷新列表
func _import_midi_file(src_path: String) -> void:
	_ensure_midi_dir()
	print("[import] src_path=[%s]" % src_path)
	var events: Array = MidiParser.parse_file(src_path)
	print("[import] events=%d" % events.size())
	if events.is_empty():
		# 区分「文件打不开」与「内容不是可解析 MIDI」，避免静默失败
		if not FileAccess.file_exists(src_path) and not src_path.begins_with("content://"):
			_show_toast("无法读取文件（真机需重新选择或授予访问）。路径: " + src_path)
		else:
			_show_toast("无法解析 MIDI：文件为空或格式不支持")
		return
	var ana: Dictionary = MidiAdapter.analyze(events)
	var adapted_dict: Dictionary = MidiAdapter.adapt(events, true)
	var adapted: Array = adapted_dict["events"]
	if adapted.is_empty():
		_show_toast("适配后音符为空，导入失败")
		return
	# 曲名来源：源中保存的曲名优先，否则用文件名兜底（A2）。
	# 再做「从后往前保留20字符」截断，避免 SAF 产生的超长名字。
	var friendly_name: String = _select_import_name(src_path)
	print("[import] friendly_name=[%s]" % friendly_name)
	# 生成不重复的目标文件名
	var base_name: String = friendly_name + "_适配"
	if _score_exist(base_name + ".mid"):
		var i := 1
		while _score_exist(base_name + "_%d.mid" % i):
			i += 1
		base_name = base_name + "_%d" % i
	var dst_path := MIDI_DIR + "/" + base_name + ".mid"
	var original_name: String = friendly_name   # 曲名：解码后的可读文件名
	var src_bpm: float = MidiParser.read_tempo(src_path)
	if src_bpm <= 0.0:
		src_bpm = 100.0   # 源文件无 Tempo 时兜底，与解析层一致
	print("[import] src_bpm=%s" % ("%.2f" % src_bpm))
	if not MidiWriter.write_file(dst_path, adapted, src_bpm, original_name):
		print("[import] 写入失败 dst=[%s] friendly=[%s]" % [dst_path, friendly_name])
		_show_toast("MIDI 写入失败\n曲名: \"%s\"\n目录: %s" % [friendly_name, MIDI_DIR])
		return
	print("导入成功: %s（原音域 %d~%d，折叠 %d）" % [dst_path, ana["src_min"], ana["src_max"], ana["folded_count"]])
	var st: Dictionary = adapted_dict["stats"]
	print("[导入统计] 源 %d 音 -> 适配 %d 音 | 折叠 %d | 黑键吸附 %d | 复音裁剪 %d" % [
		events.size(), adapted.size(), st.get("folded", 0), st.get("black", 0), st.get("poly_cut", 0)])
	_show_import_summary(friendly_name, events.size(), adapted.size(), st, ana)
	# 刷新侧边栏列表
	if _sidebar_open:
		_build_score_list()

## 导入成功后的统计小结对话框
func _show_import_summary(title: String, src_count: int, dst_count: int, st: Dictionary, ana: Dictionary) -> void:
	var msg := "[%s]\n导入完成\n\n" % title
	msg += "原音符数: %d\n适配后音符数: %d\n\n" % [src_count, dst_count]
	msg += "-- 音域信息 --\n"
	msg += "原音域跨度: %d~%d（宽 %d 键）\n" % [int(ana.get("src_min", 0)), int(ana.get("src_max", 0)), int(ana.get("width", 0))]
	msg += "整段移调: %d 键\n\n" % int(ana.get("translate", 0))
	msg += "-- 处理统计 --\n"
	var folded: int = int(st.get("folded", 0))
	var black: int = int(st.get("black", 0))
	var cut: int = int(st.get("poly_cut", 0))
	msg += "折叠(移调越界): %d 个\n" % folded
	msg += "黑键吸附: %d 个\n" % black
	msg += "复音裁剪(>3键/同键去重): %d 个\n" % cut
	if folded == 0 and black == 0 and cut == 0:
		msg += "\n无需调整，直接适配成功。"
	var dialog := AcceptDialog.new()
	dialog.title = "导入小结"
	dialog.dialog_text = msg
	dialog.ok_button_text = "确定"
	add_child(dialog)
	dialog.popup_centered(Vector2i(420, 0))

## 选定导入后使用的曲名：
## 优先用源 MIDI 保存的曲名；无曲名时回退 A2（取最短文件名段）。
## 返回前做「从后往前保留 MAX_NAME_LEN 字符」的截断，避免超长名。
func _select_import_name(src_path: String) -> String:
	var title: String = MidiParser.read_title(src_path).strip_edges()
	var base: String = title if not title.is_empty() else _extract_import_name(src_path)
	return _keep_tail(base, MAX_NAME_LEN)

## 从后往前截断：超过 max_len 字符时，改为「…」+ 尾部(max_len-1)个字符，
## 使总字符数严格为 max_len，且保留尾部内容（会话确认——省略号开头、尾部保留）。
func _keep_tail(s: String, max_len: int) -> String:
	if s.length() <= max_len:
		return s
	return "…" + s.substr(s.length() - (max_len - 1), max_len - 1)

## 从 SAF content:// URI 或普通路径中提取可读文件名。
## 对 content:// 优先取最后一段并做 URI decode；否则退化为 get_file()。
func _extract_import_name(src_path: String) -> String:
	var p := src_path
	p = p.strip_edges()
	var raw: String
	if p.begins_with("content://"):
		var seg := p.get_slice("/", p.count("/"))   # 最后一段
		# 去掉 query 部分（若有）
		var q := seg.find("?")
		if q != -1:
			seg = seg.substr(0, q)
		raw = _uri_decode(seg).get_basename()
	else:
		# 普通文件路径：去掉扩展名
		raw = p.get_file().get_basename()
	return _sanitize_filename(raw)

## 清洗成安全文件名：去除路径分隔符、非法控制字符，保证非空。
func _sanitize_filename(s: String) -> String:
	var out := ""
	for ch in s:
		var c: int = ch.unicode_at(0)
		if c == 47 or c == 92:       # '/' 或 '\' 换成下划线
			out += "_"
		elif c >= 32:                # 丢弃控制字符/换行
			out += ch
	if out.is_empty():
		out = "untitled"            # 兜底非空
	return out

## 简易 URI percent-decode（ASCII）。对 %XX 按字节解码；遇到非法 % 原样保留。
func _uri_decode(s: String) -> String:
	var out := []
	var i := 0
	while i < s.length():
		var c: int = s.unicode_at(i)
		if c == 37 and i + 2 < s.length():   # '%'
			var a: int = s.unicode_at(i + 1)
			var b: int = s.unicode_at(i + 2)
			var vh := -1
			var vl := -1
			if a >= 48 and a <= 57: vh = a - 48
			elif a >= 65 and a <= 70: vh = a - 55
			elif a >= 97 and a <= 102: vh = a - 87
			if b >= 48 and b <= 57: vl = b - 48
			elif b >= 65 and b <= 70: vl = b - 55
			elif b >= 97 and b <= 102: vl = b - 87
			if vh >= 0 and vl >= 0:
				out.append(vh * 16 + vl)
				i += 3
				continue
		out.append(c)
		i += 1
	var bytes := PackedByteArray()
	for b in out:
		bytes.append(b & 0xFF)
	return bytes.get_string_from_utf8()

func _score_exist(fname: String) -> bool:
	return FileAccess.file_exists(MIDI_DIR + "/" + fname)

## 极简提示（右下角短暂 Label）
func _show_toast(text: String) -> void:
	if _toast_label == null:
		_toast_label = Label.new()
		_toast_label.add_theme_font_size_override("font_size", 16)
		_toast_label.add_theme_color_override("font_color", Color.WHITE)
		_toast_label.z_index = 100
		add_child(_toast_label)
	_toast_label.text = text
	_toast_label.position = Vector2(size.x - 300, size.y - 60)
	_toast_label.visible = true
	# 取消旧的定时器
	if _toast_timer:
		_toast_timer.queue_free()
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 2.5
	_toast_timer.timeout.connect(func():
		if is_instance_valid(_toast_label):
			_toast_label.visible = false)
	add_child(_toast_timer)
	_toast_timer.start()

func _on_back_base_pressed() -> void:
	if _practice_active:
		_exit_practice()
	# 可见性由 _exit_practice 内部统一刷新，无需在此重复调用

func _on_restart_pressed() -> void:
	if not _practice_active:
		return
	_enter_practice(_practice_mode)   # 重新从头播放当前练习/演示

## 横杠下落引导时间：被独立下落倍速 BAR_SPEED_MULT 加速（节奏不变）
func _practice_lead() -> float:
	return LEAD_TIME / BAR_SPEED_MULT

# ---------- 速度选择菜单（照抄音色菜单的 Panel 弹层模式） ----------
func _build_speed_menu() -> void:
	_speed_popup = Panel.new()
	_speed_popup.name = "SpeedPopup"
	_speed_popup.z_index = 30
	var popup_style: StyleBoxFlat = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.18, 0.18, 0.22)
	popup_style.border_color = Color(0.08, 0.08, 0.10)
	popup_style.border_width_left = 1
	popup_style.border_width_right = 1
	popup_style.border_width_top = 1
	popup_style.border_width_bottom = 1
	popup_style.corner_radius_bottom_left = 8
	popup_style.corner_radius_bottom_right = 8
	_speed_popup.add_theme_stylebox_override("panel", popup_style)

	var item_h: float = 44.0
	for v in SPEED_OPTIONS:
		var btn: Button = Button.new()
		btn.text = "%d%%" % int(round(v * 100.0))
		btn.custom_minimum_size = Vector2(BTN_SIZE.x, item_h)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.z_index = 31
		btn.add_theme_stylebox_override("normal", _mk_btn_style(BTN_COLOR))
		btn.add_theme_stylebox_override("hover", _mk_btn_style(BTN_COLOR_HOVER))
		btn.add_theme_stylebox_override("pressed", _mk_btn_style(BTN_COLOR_PRESSED))
		btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
		btn.add_theme_color_override("font_hover_color", BTN_TEXT_COLOR)
		btn.add_theme_color_override("font_pressed_color", BTN_TEXT_COLOR)
		btn.add_theme_font_size_override("font_size", 16)
		btn.pressed.connect(_on_speed_item_selected.bind(v))
		_speed_popup.add_child(btn)
		_speed_popup_items.append(btn)

	_speed_popup.visible = false
	add_child(_speed_popup)

func _reflow_speed_popup() -> void:
	if not _btn_speed or not _speed_popup:
		return
	var item_h: float = 44.0
	var n: int = len(_speed_popup_items)
	var popup_w: float = BTN_SIZE.x
	var popup_h: float = n * item_h
	var btn_rect: Rect2 = Rect2(_btn_speed.position, _btn_speed.size)
	var x: float = btn_rect.position.x
	var y: float = btn_rect.position.y - popup_h
	if y < 0:
		y = btn_rect.position.y + btn_rect.size.y
	_speed_popup.position = Vector2(x, y)
	_speed_popup.size = Vector2(popup_w, popup_h)

	for i in range(_speed_popup_items.size()):
		var item: Button = _speed_popup_items[i]
		item.position = Vector2(0, i * item_h)
		item.size = Vector2(popup_w, item_h)

func _on_speed_button_pressed() -> void:
	if not _practice_active:
		return
	if _speed_popup.visible:
		_speed_popup.visible = false
	else:
		_reflow_speed_popup()
		_speed_popup.visible = true

func _on_speed_item_selected(v: float) -> void:
	_speed_mult = v
	_btn_speed.text = "速度:%d%%" % int(round(v * 100.0))
	_speed_popup.visible = false

## 统一管理所有按钮可见性：
##  最终可见 = 半圆总开关 _buttons_visible AND 各按钮的练习模式条件。
## 半圆(_on_toggle_buttons) 与 练习切换(_enter/_exit_practice) 都只改各自开关后调用本函数，
## 两者互不改写对方的状态，故互不干扰。所有按钮缺失时也安全跳过。
func _apply_button_visibility() -> void:
	var show := _buttons_visible
	if _btn_timbre:
		_btn_timbre.visible = show
	if _btn_toggle:
		_btn_toggle.visible = show
	if _btn_plus:
		_btn_plus.visible = show
	if _btn_minus:
		_btn_minus.visible = show
	if _btn_score:
		_btn_score.visible = show and not _practice_active
	if _btn_import:
		_btn_import.visible = show and not _practice_active
	if _btn_back_base:
		_btn_back_base.visible = show and _practice_active
	if _btn_restart:
		_btn_restart.visible = show and _practice_active
	if _btn_speed:
		_btn_speed.visible = show and _practice_active

func _on_score_button_pressed() -> void:
	_hide_popup()
	_toggle_sidebar()

func _toggle_sidebar() -> void:
	if _sidebar_open and _sidebar and _sidebar.visible:
		_close_sidebar()
		return
	if _practice_active:
		_exit_practice()
	if _sidebar == null:
		_build_sidebar()
	_build_score_list()
	_sidebar_open = true
	_sidebar.visible = true
	_sidebar.show()
	_set_sidebar_vars()
	_animate_sidebar()

func _animate_sidebar() -> void:
	# 从左侧滑出
	var target_x: float = 0.0
	var target_w: float = size.x * SIDEBAR_WIDTH_RATIO
	_sidebar.position = Vector2(-target_w, 0)
	_sidebar.size = Vector2(target_w, size.y)
	var tw: Tween = create_tween()
	tw.tween_property(_sidebar, "position:x", target_x, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _close_sidebar() -> void:
	if _sidebar == null:
		_sidebar_open = false
		return
	var tw: Tween = create_tween()
	tw.tween_property(_sidebar, "position:x", -_sidebar.size.x, 0.20)
	tw.tween_callback(func(): _sidebar.visible = false)
	_sidebar_open = false

func _build_sidebar() -> void:
	_sidebar = Panel.new()
	_sidebar.name = "ScoreSidebar"
	_sidebar.z_index = 40
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = SIDEBAR_COLOR
	st.border_color = Color(0.08, 0.08, 0.10)
	st.border_width_right = 2
	_sidebar.add_theme_stylebox_override("panel", st)
	_sidebar.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_sidebar)

	# 两页：导入乐谱 / 录音乐谱（顶部页签）
	var head_h := 64.0
	var head: Panel = Panel.new()
	head.name = "SidebarHead"
	head.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	head.size.y = head_h
	head.add_theme_stylebox_override("panel", _solid_style(SIDEBAR_HEAD_COLOR))
	_sidebar.add_child(head)

	_tab_import = _make_sidebar_tab("导入乐谱", true)
	_tab_record = _make_sidebar_tab("录音乐谱", false)
	_tab_import.pressed.connect(_select_sidebar_tab.bind(0))
	_tab_record.pressed.connect(_select_sidebar_tab.bind(1))
	head.add_child(_tab_import)
	head.add_child(_tab_record)

	# 两个页面
	_sidebar_scroll = ScrollContainer.new()
	_sidebar_scroll.name = "SidebarScroll"
	_sidebar_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sidebar.add_child(_sidebar_scroll)

	_sidebar_content = VBoxContainer.new()
	_sidebar_content.name = "SidebarContent"
	_sidebar_content.add_theme_constant_override("separation", 10)
	_sidebar_scroll.add_child(_sidebar_content)

	# 录音乐谱占位页
	var record_placeholder := Label.new()
	record_placeholder.name = "RecordPage"
	record_placeholder.text = "录音乐谱\n\n（本功能后续开发）"
	record_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	record_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	record_placeholder.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	record_placeholder.add_theme_font_size_override("font_size", 18)
	record_placeholder.set_meta("page", 1)
	_sidebar.add_child(record_placeholder)

	_select_sidebar_tab(0)
	_sidebar.visible = false

func _make_sidebar_tab(text: String, selected: bool) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.flat = true
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	btn.add_theme_font_size_override("font_size", 17)
	return btn

func _select_sidebar_tab(idx: int) -> void:
	if _sidebar == null:
		return
	_tab_import.modulate = Color(1, 1, 1, 0.55) if idx != 0 else Color.WHITE
	_tab_record.modulate = Color(1, 1, 1, 0.55) if idx != 1 else Color.WHITE
	# 内容区（导入列表）仅当 idx==0 显示
	_sidebar_scroll.visible = (idx == 0)
	for child in _sidebar.get_children():
		if child == _sidebar_scroll or child == _sidebar.get_child(0):
			continue
		if child.has_meta("page"):
			child.visible = (int(child.get_meta("page")) == idx)

func _set_sidebar_vars() -> void:
	if _sidebar == null:
		return
	var w := size.x * SIDEBAR_WIDTH_RATIO
	_sidebar.size = Vector2(w, size.y)
	# 页头布局
	var head: Control = _sidebar.get_child(0)
	head.size = Vector2(w, 64.0)
	var tab_w := w * 0.5
	_tab_import.position = Vector2(0, 0)
	_tab_import.size = Vector2(tab_w, 64.0)
	_tab_record.position = Vector2(tab_w, 0)
	_tab_record.size = Vector2(tab_w, 64.0)
	# 滚动区
	_sidebar_scroll.position = Vector2(10, 74.0)
	_sidebar_scroll.size = Vector2(w - 20.0, size.y - 74.0)
	_sidebar_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 录音乐谱占位
	for child in _sidebar.get_children():
		if child.has_meta("page"):
			child.position = Vector2(0, 64.0)
			child.size = Vector2(w, size.y - 64.0)

func _solid_style(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	return s

## 确保 user://midi 存在，并把打包内置 MIDI 拷贝进去（首次运行/有新增时）
func _ensure_midi_dir() -> void:
	DirAccess.make_dir_recursive_absolute(MIDI_DIR)
	var bundled := DirAccess.open(MIDI_DIR_BUNDLED)
	if bundled == null:
		return
	bundled.list_dir_begin()
	var fname := bundled.get_next()
	while fname != "":
		if not bundled.current_is_dir() and fname.to_lower().ends_with(".mid"):
			var src := MIDI_DIR_BUNDLED + "/" + fname
			var dst := MIDI_DIR + "/" + fname
			# 仅在 user 目录没有时才拷贝，不覆盖用户自己放的乐谱
			if not FileAccess.file_exists(dst):
				DirAccess.copy_absolute(src, dst)
		fname = bundled.get_next()
	bundled.list_dir_end()

## 扫描用户乐谱目录下的 .mid 文件，列出乐谱
func _build_score_list() -> void:
	_ensure_midi_dir()
	if _sidebar_content == null:
		return
	# 清空
	for c in _sidebar_content.get_children():
		c.queue_free()
	_score_buttons.clear()

	var dir := DirAccess.open(MIDI_DIR)
	if dir == null:
		_add_empty_scores()
		return
	dir.list_dir_begin()
	var files: Array = []
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.to_lower().ends_with(".mid"):
			files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	files.sort()

	if files.is_empty():
		_add_empty_scores()
		return

	for idx in range(files.size()):
		var f: String = files[idx]
		var path: String = MIDI_DIR + "/" + f
		# 优先用 MIDI 保存的曲名；无曲名时回退为纯文件名（get_file 不含路径）
		var name: String = MidiParser.read_title(path)
		if name.is_empty():
			name = f.get_file()
		print("[list] file=[%s] read_title=[%s] -> name=[%s]" % [f, MidiParser.read_title(path), name])
		_add_score_row(name, path)
	_setup_score_marquees()

func _add_empty_scores() -> void:
	var lbl := Label.new()
	lbl.text = "暂无导入的乐谱\n请通过导入功能添加"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_sidebar_content.add_child(lbl)

func _add_score_row(name: String, path: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# 用裁剪容器包住曲名 label，超宽时可作跑马灯横向滚动
	var name_clip := Control.new()
	name_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# 限定宽度，使 Label 的最小尺寸不会撑破 HBox；从而触发裁剪/跑马灯
	name_clip.custom_minimum_size = Vector2(140, 32)
	name_clip.clip_contents = true

	var name_lbl := Label.new()
	name_lbl.text = name
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 让 label 填满父 clip Control（否则普通 Control 不会给子节点布局）
	name_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 关键：Label 在父裁剪容器内裁剪显示（Godot 4 新属性，兼容旧场景）
	name_lbl.clip_text = true
	# 超长时单行省略（兜底），即使跑马灯不触发也不溢出
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# 单行显示，避免换行撑高
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_clip.add_child(name_lbl)

	var btn_prac := _make_row_button("练习")
	var btn_demo := _make_row_button("演示")
	var btn_del := _make_row_button("删")
	btn_del.custom_minimum_size = Vector2(40, 34)
	btn_del.add_theme_color_override("font_color", Color(0.95, 0.4, 0.4))
	btn_prac.pressed.connect(_start_by_path.bind(name, path, "practice"))
	btn_demo.pressed.connect(_start_by_path.bind(name, path, "demo"))
	btn_del.pressed.connect(_confirm_delete_score.bind(name, path))
	row.add_child(name_clip)
	# 删除按钮放在最左（紧贴曲名），并与右侧操作区空一格，防误删
	row.add_child(btn_del)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(12, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)
	row.add_child(btn_prac)
	row.add_child(btn_demo)
	_sidebar_content.add_child(row)
	_score_buttons.append([name, path, btn_prac, btn_demo, name_lbl, name_clip, btn_del])

## 等一帧布局完成后：超宽的曲名 label 设自动跑马灯
func _setup_score_marquees() -> void:
	_update_score_marquees.call_deferred()

func _update_score_marquees() -> void:
	for entry in _score_buttons:
		var lbl: Label = entry[4]
		var clip: Control = entry[5]
		if not is_instance_valid(lbl) or not is_instance_valid(clip):
			continue
		# 计算文本宽度
		var font: Font = lbl.get_theme_font("font")
		var fs: int = lbl.get_theme_font_size("font_size")
		var text_w: float = font.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var clip_w: float = clip.size.x
		if clip_w <= 0 or text_w <= clip_w:
			lbl.position = Vector2(0, 0)   # 不超宽，归位
			continue
		# 跑马灯：从 0 滚到 -(text_w - clip_w)，再回来，循环
		lbl.position = Vector2(0, 0)
		var range_w: float = text_w - clip_w + 12.0
		var tw: Tween = create_tween()
		tw.set_loops()
		tw.tween_property(lbl, "position:x", 0.0, 2.0)
		tw.tween_property(lbl, "position:x", -range_w, 3.0 + range_w * 0.03)
		tw.tween_property(lbl, "position:x", -range_w, 1.0)
		tw.tween_property(lbl, "position:x", 0.0, 3.0 + range_w * 0.03)
		tw.tween_property(lbl, "position:x", 0.0, 1.0)

func _make_row_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(56, 34)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.add_theme_stylebox_override("normal", _mkr_style(BTN_COLOR))
	btn.add_theme_stylebox_override("hover", _mkr_style(BTN_COLOR_HOVER))
	btn.add_theme_stylebox_override("pressed", _mkr_style(BTN_COLOR_PRESSED))
	btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
	btn.add_theme_color_override("font_pressed_color", BTN_TEXT_COLOR)
	btn.add_theme_font_size_override("font_size", 14)
	return btn

## 弹出删除确认框（只删用户数据里的这一份 MIDI 文件）
func _confirm_delete_score(name: String, path: String) -> void:
	_pending_delete_path = path
	_pending_delete_name = name
	if _delete_dialog == null:
		_delete_dialog = ConfirmationDialog.new()
		_delete_dialog.title = "删除乐谱"
		_delete_dialog.ok_button_text = "删除"
		_delete_dialog.cancel_button_text = "取消"
		_delete_dialog.confirmed.connect(_do_delete_score)
		add_child(_delete_dialog)
	_delete_dialog.dialog_text = "确定删除「%s」吗？\n此操作不可恢复。" % name
	_delete_dialog.popup_centered(Vector2i(380, 0))

## 确认后执行删除并重建乐谱列表
func _do_delete_score() -> void:
	var path: String = _pending_delete_path
	var name: String = _pending_delete_name
	_pending_delete_path = ""
	_pending_delete_name = ""
	if path.is_empty():
		return
	var err := DirAccess.remove_absolute(path)
	if err != OK:
		print("[删除] 失败 path=[%s] err=%s" % [path, err])
	else:
		print("[删除] 已删除 [%s] path=[%s]" % [name, path])
	# 重建列表（内部已刷新空态 + 跑马灯）
	_build_score_list()

func _mkr_style(c: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.border_color = Color(0.08, 0.08, 0.10)
	s.border_width_left = 1
	s.border_width_right = 1
	s.border_width_top = 1
	s.border_width_bottom = 1
	return s

# ==================== 练习指引区 / 下落横杠 ====================

func _start_by_path(name: String, path: String, mode: String) -> void:
	_current_path = path
	var midi_notes: Array = MidiParser.parse_file(path)
	if midi_notes.is_empty():
		print("乐谱解析为空: " + path)
		return
	_current_midi = midi_notes.duplicate()
	_close_sidebar()
	_enter_practice(mode)

func _enter_practice(mode: String) -> void:
	_exit_practice_mode_content()
	_practice_mode = mode
	_practice_active = true
	_demo_played_flag.clear()
	# 先让琴键/横梁排到练习位置（1/3 边界），保证槽与横杠拿到正确坐标
	_apply_key_top()
	_mark_practice_notes()
	_build_guide_area()

	# 启动时钟
	_play_musical_sec = -_practice_lead()
	set_process(true)
	_apply_button_visibility()

func _exit_practice() -> void:
	_exit_practice_mode_content()
	_practice_active = false
	_practice_mode = ""
	set_process(false)
	# 恢复基本模式键位（贴屏幕顶部附近）
	_apply_key_top()
	_apply_button_visibility()

func _exit_practice_mode_content() -> void:
	# 移除标题、下落槽、判定线、圆点与横杠
	if _guide_label and is_instance_valid(_guide_label):
		_guide_label.queue_free()
	_guide_label = null
	if _guide_area and is_instance_valid(_guide_area):
		_guide_area.queue_free()
	_guide_area = null
	for s in _key_slots:
		if is_instance_valid(s):
			s.queue_free()
	_key_slots.clear()
	if _land_line and is_instance_valid(_land_line):
		_land_line.queue_free()
	_land_line = null
	_land_dots.clear()
	for b in _bars:
		if is_instance_valid(b):
			b.queue_free()
	_bars.clear()
	_bar_meta.clear()
	# 恢复所有琴键颜色
	for key in _keys:
		var base: Color = key.get_meta("base_color", KEY_COLOR_NORMAL)
		var style := key.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			style.bg_color = base
	# 停止自动演奏播放器
	if _auto_players.size() > 0:
		for p in _auto_players:
			if is_instance_valid(p):
				p.stop()
				p.queue_free()
		_auto_players.clear()

var _auto_players: Array = []             # 演示模式自动播放器
var _practice_note_keys: Array = []       # [[note_key, midi, start_sec, is_melody], ...]
var _demo_played_flag: Dictionary = {}    # 演示已触发的音符标记
var _key_flashes: Dictionary = {}         # 琴键 -> 进行中的蓝色闪现 Tween

func _mark_practice_notes() -> void:
	_practice_note_keys.clear()
	var melody_ch := MidiAdapter.pick_melody_channel(_current_midi)
	for ev in _current_midi:
		var is_melody: bool = int(ev.get("channel", 0)) == melody_ch
		_practice_note_keys.append([_midi_to_keynote(ev["midi"]), ev["midi"], ev["start"], is_melody])

func _build_guide_area() -> void:
	_guide_area = null  # 不再用整块半透明遮罩，改用每列下落槽
	var land_y: float = _column_top()   # 判定线 / 琴键起始边界

	# 顶部标题（独立浮层，不被槽遮挡）
	_guide_label = Label.new()
	_guide_label.z_index = 18
	_guide_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_guide_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
	_guide_label.add_theme_font_size_override("font_size", 22)
	_guide_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_guide_label.add_theme_constant_override("outline_size", 6)
	_guide_label.position = Vector2(0, 6)
	_guide_label.size = Vector2(size.x, 40)
	var mode_txt := "演示中" if _practice_mode == "demo" else "练习中"
	_guide_label.text = mode_txt + "：" + _current_path.get_file().get_basename()
	add_child(_guide_label)

	# 每列下落槽（盖在琴键上方空白处，上 1/3）
	_key_slots.clear()
	for key in _keys:
		var slot := ColorRect.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.z_index = 14
		slot.color = SLOT_COLOR
		slot.position = Vector2(key.position.x, 0)
		slot.size = Vector2(key.size.x, land_y)
		add_child(slot)
		_key_slots.append(slot)

	# 贯穿判定线（置于琴键起始边界）
	_land_line = ColorRect.new()
	_land_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_land_line.z_index = 14
	_land_line.color = LAND_LINE_COLOR
	_land_line.position = Vector2(0, land_y - 2.0)
	_land_line.size = Vector2(size.x, 3.0)
	add_child(_land_line)
	_land_dots.clear()

	# 根据乐谱创建横杠（每根属于所在列的槽）
	_create_all_bars()

func _create_all_bars() -> void:
	for i in range(_practice_note_keys.size()):
		var entry: Array = _practice_note_keys[i]
		var note: String = entry[0]
		var start_sec: float = entry[2]
		var is_melody: bool = entry[3]
		var key: Panel = _note_key_map.get(note, null)
		var bar := ColorRect.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.z_index = 17
		bar.color = BAR_GREEN
		bar.size = Vector2(0, BAR_HEIGHT)
		bar.visible = false
		add_child(bar)
		_bars.append(bar)
		# [note, start_sec, key_ref, hit_done, is_melody]
		_bar_meta.append([note, start_sec, key, false, is_melody])

# 在 _process 中更新横杠下落与自动演奏

func _process(delta: float) -> void:
	if not _practice_active:
		return
	_play_musical_sec += delta * _speed_mult

	var land_y := _column_top()   # 判定线位置（槽底 = 琴键顶）
	var lead := _practice_lead()

	_update_bar_colors()

	for i in range(_bars.size()):
		var bar: ColorRect = _bars[i]
		if not is_instance_valid(bar):
			continue
		var meta: Array = _bar_meta[i]
		var start_sec: float = meta[1]
		var key: Panel = meta[2]
		var hit_done: bool = meta[3]

		# 相对位置：槽顶时 rel=0，落到判定线(敲击)时 rel=1
		var rel := (_play_musical_sec - (start_sec - lead)) / lead
		# 到达判定线的瞬间：蓝色高亮所在琴键一次
		if not hit_done and rel >= 1.0 and key is Panel:
			_flash_key_blue(key)
			meta[3] = true
		bar.visible = rel >= 0.0
		if bar.visible:
			# 横杠宽度随所在列、水平位置随琴键（随 resize 变化）
			var bw: float = key.size.x * 0.8 if key is Panel else 26.0
			var center_x: float = size.x * 0.5
			if key is Panel:
				center_x = key.position.x + key.size.x * 0.5
			bar.size.x = bw
			bar.position.x = center_x - bw * 0.5
			var y_off: float = rel * land_y - BAR_HEIGHT * 0.5
			var alpha: float = 1.0
			if rel > 1.0:
				# 敲击后继续下落越过琴键顶淡出
				alpha = clamp(1.0 - (rel - 1.0) / 0.5, 0.0, 1.0)
				y_off = land_y + (rel - 1.0) * 30.0
			bar.position.y = y_off
			bar.modulate.a = alpha
		else:
			bar.modulate.a = 1.0

	# 自动演奏
	if _practice_mode == "demo":
		_auto_play()

## 依据敲击时刻分桶 + 主旋律标记着色：
## 主旋律恒绿；非主旋律若与别音符同刻(>=2) → 红，单独启动 → 蓝
func _update_bar_colors() -> void:
	var buckets: Dictionary = {}
	for i in range(_bars.size()):
		var bar: ColorRect = _bars[i]
		if not is_instance_valid(bar):
			continue
		var s: float = _bar_meta[i][1]
		var bucket: float = round(s / HIT_SNAP) * HIT_SNAP
		if not buckets.has(bucket):
			buckets[bucket] = []
		buckets[bucket].append(i)
	for k in buckets:
		var idxs: Array = buckets[k]
		var multi: bool = idxs.size() >= 2
		for bi in idxs:
			var bar: ColorRect = _bars[bi]
			if not is_instance_valid(bar):
				continue
			var is_melody: bool = _bar_meta[bi][4]
			if is_melody:
				bar.color = BAR_GREEN
			elif multi:
				bar.color = BAR_RED
			else:
				bar.color = BAR_BLUE

## 琴键到达敲击时机的瞬间蓝色高亮，随后还原
func _flash_key_blue(key: Panel) -> void:
	if not is_instance_valid(key):
		return
	if _key_flashes.has(key):
		var old: Tween = _key_flashes[key]
		old.kill()
	var base: Color = key.get_meta("base_color", KEY_COLOR_NORMAL)
	var tw := create_tween()
	_key_flashes[key] = tw
	tw.tween_property(key.get_theme_stylebox("panel"), "bg_color", HIT_FLASH_COLOR, 0.06)
	tw.tween_property(key.get_theme_stylebox("panel"), "bg_color", base, 0.30)
	tw.chain().tween_callback(func(): _key_flashes.erase(key))

# 演示自动演奏：驱动琴键模拟敲击
func _auto_play() -> void:
	for i in range(_practice_note_keys.size()):
		var ev: Array = _practice_note_keys[i]
		var note: String = ev[0]
		var start_sec: float = ev[2]
		if _demo_played_flag.get(i, false):
			continue
		if _play_musical_sec >= start_sec:
			var key: Panel = _note_key_map.get(note, null)
			if key:
				_demo_key_press(key)
			_demo_played_flag[i] = true

func _demo_key_press(key: Panel) -> void:
	var note: String = _key_note_map.get(key, "")
	if note == "":
		return
	var player := AudioStreamPlayer.new()
	player.stream = _preloaded_samples.get(note)
	player.bus = "Master"
	player.volume_db = BASE_VOLUME_DB + linear2db(0.9)
	add_child(player)
	_auto_players.append(player)
	player.play()
	# 键色高亮由 _process 的蓝色闪现负责；此处仅延时释放播放器
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(func():
		if is_instance_valid(player):
			player.stop()
			_auto_players.erase(player)
			player.queue_free()
	)

# ==================== 输入处理 ====================

func _input(event: InputEvent) -> void:
	# 侧边栏打开时：点击侧边栏以外任意区域则收起（不触发琴键）
	if _sidebar_open and _sidebar and _sidebar.visible:
		var is_press: bool = false
		if event is InputEventScreenTouch:
			is_press = event.pressed
		elif event is InputEventMouseButton:
			is_press = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		if is_press:
			var sb_rect: Rect2 = _sidebar.get_global_rect()
			# 侧边栏滑出过程中位置为负，get_global_rect 会正确反映当前矩形
			if not sb_rect.has_point(event.position):
				_close_sidebar()
				return

	# 点击弹出菜单外部时关闭
	if _popup and _popup.visible:
		if event is InputEventScreenTouch and event.pressed:
			var local: Vector2 = event.position
			var popup_rect: Rect2 = Rect2(_popup.position, _popup.size)
			if not popup_rect.has_point(local):
				_hide_popup()
			return  # 点击弹出菜单或菜单外都不触发琴键
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var local: Vector2 = event.position
			var popup_rect: Rect2 = Rect2(_popup.position, _popup.size)
			if not popup_rect.has_point(local):
				_hide_popup()
			return  # 点击弹出菜单或菜单外都不触发琴键

	if event is InputEventScreenTouch:
		var tid: int = event.index
		if event.pressed:
			var hit: Panel = _hit_test(event.position)
			if hit:
				_touch_key_map[tid] = hit
				_press_key(hit)
		else:
			if _touch_key_map.has(tid):
				var k: Panel = _touch_key_map[tid]
				_release_key(k)
				_touch_key_map.erase(tid)
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var hit: Panel = _hit_test(event.position)
		if event.pressed and hit:
			_touch_key_map[-1] = hit
			_press_key(hit)
		elif not event.pressed and _touch_key_map.has(-1):
			_release_key(_touch_key_map[-1])
			_touch_key_map.erase(-1)

	elif event is InputEventScreenDrag:
		var tid: int = event.index
		var hit: Panel = _hit_test(event.position)
		var cur: Panel = _touch_key_map.get(tid, null)
		if hit != cur:
			if cur:
				_release_key(cur)
			if hit:
				_touch_key_map[tid] = hit
				_press_key(hit)
			else:
				_touch_key_map.erase(tid)

func _hit_test(gp: Vector2) -> Panel:
	for key in _keys:
		var p: Panel = key
		var r: Rect2 = Rect2(
			p.global_position - Vector2(KEY_EXTRA_TOUCH, KEY_EXTRA_TOUCH),
			p.size + Vector2(KEY_EXTRA_TOUCH * 2, KEY_EXTRA_TOUCH * 2)
		)
		if r.has_point(gp):
			return p
	return null

# ==================== 按下 / 释放 / 发声 ====================

func _press_key(key: Panel) -> void:
	var note: String = _key_note_map.get(key, "")
	if note == "":
		return
	var style: StyleBoxFlat = key.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.bg_color = KEY_COLOR_PRESSED

	# 记录按下时间戳
	_key_press_times[key] = Time.get_ticks_msec() / 1000.0

	# 停止该按键的正在运行的 Tween
	if _active_tweens.has(key):
		var old_tween: Tween = _active_tweens[key]
		old_tween.kill()
		_active_tweens.erase(key)

	# 清理旧的播放器实例（如果存在）
	if _key_player_map.has(key):
		var old_player: AudioStreamPlayer = _key_player_map[key]
		if is_instance_valid(old_player):
			old_player.stop()
			old_player.queue_free()
		_key_player_map.erase(key)

	# 创建新的播放器实例
	var new_player: AudioStreamPlayer = AudioStreamPlayer.new()
	new_player.stream = _preloaded_samples.get(note)
	add_child(new_player)
	_key_player_map[key] = new_player

	# 播放新音符
	_play_note_on_player(new_player, 1.0)

func _release_key(key: Panel) -> void:
	var base: Color = key.get_meta("base_color", KEY_COLOR_NORMAL)
	var style: StyleBoxFlat = key.get_theme_stylebox("panel") as StyleBoxFlat
	if style:
		style.bg_color = base

	var note: String = _key_note_map.get(key, "")
	if note == "":
		return

	# 计算按下时长
	var press_time: float = _key_press_times.get(key, Time.get_ticks_msec() / 1000.0)
	var release_time: float = Time.get_ticks_msec() / 1000.0
	var duration: float = release_time - press_time
	_key_press_times.erase(key)

	# 映射到力度值 (0.0 ~ 1.0)
	# 快速按下(短时长) = 强力度；慢速按住(长时长) = 弱力度
	var normalized: float = clamp((MAX_PRESS_DURATION - duration) / (MAX_PRESS_DURATION - MIN_PRESS_DURATION), 0.0, 1.0)

	# 映射到音量倍数
	var volume_scale: float = MIN_VOLUME_SCALE + normalized * (MAX_VOLUME_SCALE - MIN_VOLUME_SCALE)

	# 计算目标音量 (dB)
	var target_db: float = BASE_VOLUME_DB + linear2db(volume_scale)

	# 获取按下时创建的新播放器
	var player: AudioStreamPlayer = _key_player_map.get(key, null)
	if player == null:
		return

	# 如果力度弱，衰减音量并在短时间后停止
	var tween: Tween = create_tween()
	if normalized < 0.5:
		# 弱力度: 快速衰减音量
		var duration_ms: float = duration * 1000.0
		var fade_time: float = max(50.0, duration_ms * 0.3)
		player.volume_db = target_db
		tween.tween_property(player, "volume_db", -80.0, fade_time / 1000.0)
	else:
		# 强力度: 保持较高音量
		player.volume_db = target_db
		# 自然衰减
		var fade_time: float = 0.8
		tween.tween_property(player, "volume_db", -80.0, fade_time)

	# 衰减结束后清理播放器
	tween.finished.connect(func():
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	)
	_active_tweens[key] = tween

	# 清除按键到播放器的映射
	_key_player_map.erase(key)

func linear2db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

func _play_note_on_player(player: AudioStreamPlayer, volume_scale: float = 1.0) -> void:
	# 设置初始音量
	var volume_db: float = BASE_VOLUME_DB + linear2db(volume_scale)
	player.volume_db = volume_db
	player.play(0.0)
