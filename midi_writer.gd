class_name MidiWriter
extends RefCounted
## 将音符事件数组写为标准 MIDI 文件（SMF Format 0）。
## 事件: { "midi": int 音号, "start": float 秒, "dur": float 秒, "channel": int 通道(缺省0) }

const _NOTE_OFF := 0x80
const _NOTE_ON := 0x90
const _TRACK_END := 0xFF

## 写入 SMF 到 path。返回是否成功。bpm 覆盖默认拍速，title 会写入曲名 meta(0xFF 0x03)。
## 保留每个音符的 channel（写进状态字节低 4 位），以便后续解析还原多音轨信息。
static func write_file(path: String, events: Array, bpm: float = 90.0, title: String = "") -> bool:
	var division := 480
	var ticks_per_beat := division
	var beats_per_sec := bpm / 60.0
	# 秒 -> tick
	var sec_to_tick := int(ticks_per_beat * beats_per_sec)

	var track := PackedByteArray()
	# 按事件建立 on/off 列表 (tick, midi, vel, channel)
	var on_events := []   # [tick, midi, vel, channel]
	var off_events := []  # [tick, midi, channel]
	var end_tick := 0
	for ev in events:
		var start_tick := int(ev["start"] * sec_to_tick)
		var dur_tick := int(max(0.001, ev["dur"]) * sec_to_tick)
		var off_tick := start_tick + dur_tick
		var ch := int(ev.get("channel", 0)) & 0x0F
		on_events.append([start_tick, int(ev["midi"]), 100, ch])
		off_events.append([off_tick, int(ev["midi"]), ch])
		if off_tick > end_tick:
			end_tick = off_tick

	# 合并成一个由 tick 排队的动作列表
	var actions := []
	for o in on_events:
		actions.append([o[0], "on", o[1], o[2], o[3]])
	for o in off_events:
		actions.append([o[0], "off", o[1], 0, o[2]])
	actions.sort_custom(func(a, b):
		if a[0] == b[0]:
			return a[1] == "off" and b[1] == "on"
		return a[0] < b[0])

	var last_tick := 0
	var running_status := -1
	for act in actions:
		var tick: int = act[0]
		var kind: String = act[1]
		var midi: int = act[2]
		var vel: int = act[3]
		var chan: int = act[4] & 0x0F
		# delta
		var dt: int = max(0, tick - last_tick)
		last_tick = tick
		_append_var_len(track, dt)
		var status: int = (_NOTE_OFF if kind == "off" else _NOTE_ON) | chan
		if vel == 0 and kind == "on":
			status = _NOTE_OFF | chan
			vel = 64
		if status != running_status:
			track.append(status)
			running_status = status
		track.append(midi & 0x7F)
		track.append(vel & 0x7F)

	# 结尾
	_append_var_len(track, max(0, end_tick - last_tick))
	track.append(0xFF)
	track.append(0x2F)
	track.append(0x00)

	# 组装 MThd + MTrk
	var ntrks := 1
	var header := PackedByteArray()
	header.append_array("MThd".to_ascii_buffer())
	header.append_array(_be32(6))
	header.append_array(_be16(0))       # format 0
	header.append_array(_be16(ntrks))
	header.append_array(_be16(division))

	var trk := PackedByteArray()
	# 曲名 meta 0xFF 0x03（放在最前）
	if not title.is_empty():
		var tb := title.to_utf8_buffer()
		_append_var_len(trk, 0)
		trk.append(0xFF); trk.append(0x03); trk.append(tb.size())
		trk.append_array(tb)
	# 拍速 meta 0x51 与调号 0x58（1=C）前置在首个 delta 0
	_append_var_len(trk, 0)
	trk.append(0xFF); trk.append(0x58); trk.append(4)
	trk.append(0); trk.append(0); trk.append(0); trk.append(0)  # 1=C, 4/4
	var micros := int(60000000.0 / bpm)
	_append_var_len(trk, 0)
	trk.append(0xFF); trk.append(0x51); trk.append(3)
	trk.append((micros >> 16) & 0xFF)
	trk.append((micros >> 8) & 0xFF)
	trk.append(micros & 0xFF)
	trk.append_array(track)

	var track_header := PackedByteArray()
	track_header.append_array("MTrk".to_ascii_buffer())
	track_header.append_array(_be32(trk.size()))

	var out := PackedByteArray()
	out.append_array(header)
	out.append_array(track_header)
	out.append_array(trk)

	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("无法写入 MIDI: " + path)
		return false
	f.store_buffer(out)
	f.close()
	return true

static func _append_var_len(buf: PackedByteArray, value: int) -> void:
	var v: int = max(0, value)
	var stack := []
	stack.push_back(v & 0x7F)
	v >>= 7
	while v > 0:
		stack.push_back((v & 0x7F) | 0x80)
		v >>= 7
	while stack.size() > 0:
		buf.append(stack.pop_back())

static func _be16(v: int) -> PackedByteArray:
	return PackedByteArray([(v >> 8) & 0xFF, v & 0xFF])

static func _be32(v: int) -> PackedByteArray:
	return PackedByteArray([(v >> 24) & 0xFF, (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF])