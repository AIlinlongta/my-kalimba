class_name MidiParser
extends RefCounted
## 标准 MIDI 文件解析器（SMF 格式 0/1）。
## 将 .mid 二进制解析为按时间排序的琴键音符列表。

# 解析结果元素: { "midi": int, "channel": int, "start": float, "dur": float }

## 读取 MIDI 文件保存的曲名（meta 0xFF 0x03，UTF-8）。无曲名返回空串。
static func read_title(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var bytes := f.get_buffer(f.get_length())
	f.close()
	if bytes.size() < 14 or _peek_str(bytes, 0, 4) != "MThd":
		return ""
	var pos := 8
	pos += 2  # format
	var ntrks := _be16(bytes, pos); pos += 2
	pos += 2  # division
	var title := ""
	for _t in ntrks:
		if _peek_str(bytes, pos, 4) != "MTrk":
			return title
		var trk_len := _be32(bytes, pos + 4)
		var trk_end := pos + 8 + trk_len
		pos += 8
		var running := -1
		while pos < trk_end:
			var vl := _varlen(bytes, pos)
			var delta: int = vl[0]
			var vl_next: int = vl[1]
			pos = vl_next
			var status := int(bytes[pos])
			if status & 0x80 != 0:
				running = status
				pos += 1
			status = running
			var kind := status & 0xF0
			if kind == 0x90 or kind == 0x80:
				pos += 2
			elif kind == 0xC0 or kind == 0xD0:
				pos += 1
			elif kind == 0xA0 or kind == 0xB0 or kind == 0xE0:
				pos += 2
			else:
				if status == 0xFF:
					var mtype := int(bytes[pos]); pos += 1
					var mlen := _varlen(bytes, pos)
					var mlen_size: int = mlen[0]
					var mdata: int = mlen[1]
					pos = mdata + mlen_size
					if mtype == 0x03:
						if mdata + mlen_size <= bytes.size():
							title = bytes.slice(mdata, mdata + mlen_size).get_string_from_utf8()
				elif status == 0xF0 or status == 0xF7:
					var slen := _varlen(bytes, pos)
					var slen_size: int = slen[0]
					var slen_next: int = slen[1]
					pos = slen_next + slen_size
				else:
					pos += 1
		if not title.is_empty():
			break
	return title

## 读取源 MIDI 的首个 Tempo 事件 BPM；文件无 Tempo 或解析失败时返回 -1.0（由调用方决定兜底）。
static func read_tempo(path: String) -> float:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return -1.0
	var bytes := f.get_buffer(f.get_length())
	f.close()
	if bytes.size() < 14 or _peek_str(bytes, 0, 4) != "MThd":
		return -1.0
	var pos := 8
	pos += 2  # format
	var ntrks := _be16(bytes, pos); pos += 2
	pos += 2  # division
	for _t in ntrks:
		if _peek_str(bytes, pos, 4) != "MTrk":
			return -1.0
		var trk_len := _be32(bytes, pos + 4)
		var trk_end := pos + 8 + trk_len
		pos += 8
		var running := -1
		while pos < trk_end:
			var vl := _varlen(bytes, pos)
			var _delta: int = vl[0]
			var vl_next: int = vl[1]
			pos = vl_next
			var status := int(bytes[pos])
			if status & 0x80 != 0:
				running = status
				pos += 1
			status = running
			var kind := status & 0xF0
			if kind == 0x90 or kind == 0x80:
				pos += 2
			elif kind == 0xC0 or kind == 0xD0:
				pos += 1
			elif kind == 0xA0 or kind == 0xB0 or kind == 0xE0:
				pos += 2
			else:
				if status == 0xFF:
					var mtype := int(bytes[pos]); pos += 1
					var mlen := _varlen(bytes, pos)
					var mlen_size: int = mlen[0]
					var mdata: int = mlen[1]
					pos = mdata + mlen_size
					if mtype == 0x51 and mlen_size == 3 and mdata + 3 <= bytes.size():
						var micros := (_be16(bytes, mdata) << 8) | int(bytes[mdata + 2])
						return 60000000.0 / micros
				elif status == 0xF0 or status == 0xF7:
					var slen := _varlen(bytes, pos)
					var slen_size: int = slen[0]
					var slen_next: int = slen[1]
					pos = slen_next + slen_size
				else:
					pos += 1
	return -1.0

## 解析 MIDI 文件路径，返回音符数组。bpm 若 >0 则覆盖文件拍速。
static func parse_file(path: String, bpm_override: float = -1.0) -> Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("无法打开 MIDI 文件: " + path)
		return []
	var bytes := f.get_buffer(f.get_length())
	f.close()
	if bytes.size() < 14:
		push_error("MIDI 文件过短: " + path)
		return []

	var pos := 0
	# MThd
	if _peek_str(bytes, pos, 4) != "MThd":
		push_error("非标准 MIDI 文件: " + path)
		return []
	pos += 8  # 跳过 "MThd" + 长度字段
	var format := _be16(bytes, pos); pos += 2
	var ntrks := _be16(bytes, pos); pos += 2
	var division := _be16(bytes, pos); pos += 2
	if division & 0x8000 != 0:
		push_error("不支持 SMPTE 时间码 MIDI: " + path)
		return []

	var bpm := 100.0   # 兜底 BPM（仅在文件无 Tempo 事件时生效）
	if bpm_override > 0.0:
		bpm = bpm_override

	var notes: Array = []  # 每元素 [on_tick(int), off_tick(int), midi(int), channel(int)]
	var open_notes := {}   # (channel*256+midi) -> abs_tick

	for _t in ntrks:
		# MTrk
		if _peek_str(bytes, pos, 4) != "MTrk":
			push_error("MIDI 轨道头异常: " + path)
			return []
		var trk_len := _be32(bytes, pos + 4)
		var trk_end := pos + 8 + trk_len
		pos += 8
		var abs_tick := 0
		var running := -1
		while pos < trk_end:
			var vl := _varlen(bytes, pos)
			var delta: int = vl[0]
			var vl_next: int = vl[1]
			pos = vl_next
			abs_tick += delta
			var status := int(bytes[pos])
			if status & 0x80 != 0:
				running = status
				pos += 1
			status = running
			var kind := status & 0xF0
			if kind == 0x90 or kind == 0x80:
				if pos + 1 >= bytes.size():
					break
				var mnote := int(bytes[pos])
				var mvel := int(bytes[pos + 1])
				var mchan := running & 0x0F   # channel 存于状态字节低 4 位
				var nkey := mchan * 256 + mnote
				pos += 2
				if kind == 0x80 or mvel == 0:
					if open_notes.has(nkey):
						notes.append([open_notes[nkey], abs_tick, mnote, mchan])
						open_notes.erase(nkey)
				else:
					if open_notes.has(nkey):
						# 同音高重复触发（未先 off）：视为隐式 off+tap，避免丢音
						notes.append([open_notes[nkey], abs_tick, mnote, mchan])
					open_notes[nkey] = abs_tick
			elif kind == 0xC0 or kind == 0xD0:
				pos += 1
			elif kind == 0xA0 or kind == 0xB0 or kind == 0xE0:
				pos += 2
			else:
				# 0xF0/0xF1/0xF2/0xF3/0xF6/0xF7/0xF8...
				if status == 0xFF:
					var mtype := int(bytes[pos]); pos += 1
					var mlen := _varlen(bytes, pos)
					var mlen_size: int = mlen[0]
					var mdata: int = mlen[1]
					pos = mdata + mlen_size
					if mtype == 0x51 and mlen_size == 3 and bpm_override <= 0.0:
						var micros := (_be16(bytes, mdata) << 8) | int(bytes[mdata + 2])
						bpm = 60000000.0 / micros
				elif status == 0xF0 or status == 0xF7:
					var slen := _varlen(bytes, pos)
					var slen_size: int = slen[0]
					var slen_next: int = slen[1]
					pos = slen_next + slen_size
				else:
					pos += 1  # realtime 0xF8-0xFF 单字节

	var ticks_per_sec := float(division) * (bpm / 60.0)
	if ticks_per_sec <= 0.0:
		ticks_per_sec = 1.0
	var result: Array = []
	for nt in notes:
		result.append({
			"midi": nt[2],
			"channel": nt[3],
			"start": float(nt[0]) / ticks_per_sec,
			"dur": max(0.0, float(nt[1] - nt[0]) / ticks_per_sec),
		})
	# 按开始时间排序
	result.sort_custom(func(a, b): return a["start"] < b["start"])
	return result

static func _be16(b: PackedByteArray, p: int) -> int:
	return (int(b[p]) << 8) | int(b[p + 1])

static func _be32(b: PackedByteArray, p: int) -> int:
	return (int(b[p]) << 24) | (int(b[p + 1]) << 16) | (int(b[p + 2]) << 8) | int(b[p + 3])

## 从位置 p 读取可变长度整数，返回 [value, next_pos]
static func _varlen(b: PackedByteArray, p: int) -> Array:
	var value := 0
	var c := 0
	while c < 4:
		var byte_val := int(b[p + c])
		value = (value << 7) | (byte_val & 0x7F)
		c += 1
		if byte_val & 0x80 == 0:
			break
	return [value, p + c]

## 读取 p 处长度为 n 的 ASCII 字符串
static func _peek_str(b: PackedByteArray, p: int, n: int) -> String:
	var s := ""
	for i in range(n):
		s += char(b[p + i])
	return s