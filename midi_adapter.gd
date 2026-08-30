class_name MidiAdapter
extends RefCounted
## 将任意 MIDI 音符事件适配到 17 键自然音拇指琴（C4~E6，无黑键）。
## 流程：音域判定 → 先整段移调 → 超界折叠到边界 → 黑键吸附到最近自然音。
## 可选：对孤立单音旋律自动叠加和弦（≤3 键、两拇指可达）。

# 17 音自然音（低→高），与 kalimba.gd 的 NOTES 一致
const NOTES: Array = [
	"C4", "D4", "E4", "F4", "G4", "A4", "B4",
	"C5", "D5", "E5", "F5", "G5", "A5", "B5",
	"C6", "D6", "E6"
]
# 对应 MIDI 音号
const NAT_MIDI: Array = [
	60, 62, 64, 65, 67, 69, 71,
	72, 74, 76, 77, 79, 81, 83,
	84, 86, 88
]
const PLAY_MIN: int = 60   # C4
const PLAY_MAX: int = 88   # E6

## 分析音域，返回 {src_min, src_max, width, adaptible, translate, folded_count}
static func analyze(events: Array) -> Dictionary:
	var res := {
		"src_min": 0, "src_max": 0, "width": 0,
		"adaptible": true, "translate": 0, "folded_count": 0,
	}
	if events.is_empty():
		return res
	var lo: int = events[0]["midi"]
	var hi: int = events[0]["midi"]
	for ev in events:
		var m: int = ev["midi"]
		lo = min(lo, m)
		hi = max(hi, m)
	res["src_min"] = lo
	res["src_max"] = hi
	res["width"] = hi - lo

	# A) 密度加权中心：按时长加权求源中心，作为初始偏好（兼顾听感）
	var total_dur := 0.0
	var weighted_sum := 0.0
	for ev in events:
		var d: float = float(ev["dur"])
		total_dur += d
		weighted_sum += float(ev["midi"]) * d
	var src_center := (lo + hi) / 2.0
	if total_dur > 0.0:
		src_center = weighted_sum / total_dur
	var center := (PLAY_MIN + PLAY_MAX) / 2.0   # 琴几何中心 ≈ 74

	# 可行移调区间（t 在此区间内才能保证折叠后落在琴上），宽度 = 28 - width（天然 ≤ 28）
	var t_min := PLAY_MIN - lo
	var t_max := PLAY_MAX - hi

	# B) 折叠数前缀统计（高效，O(N + U)，U = 可行区间宽度）
	# 单个音 m 在满足  m+t < PLAY_MIN 或 m+t > PLAY_MAX 时折叠：
	#   折叠低端 t < PLAY_MIN-m ；折叠高端 t > PLAY_MAX-m
	# 用差分数组求每个整数 t 的折叠数。
	var u: int = maxi(0, t_max - t_min)
	var diff := PackedInt32Array()
	diff.resize(u + 2)   # 差分数组，索引 = t - t_min
	for ev in events:
		var m: int = ev["midi"]
		# 低端越界区间: t ∈ [t_min, PLAY_MIN-m-1]
		var lo_bnd := PLAY_MIN - m
		if lo_bnd - 1 >= t_min:
			var l := 0
			var r: int = mini(lo_bnd - 1, t_max) - t_min
			if r >= l:
				diff[l] += 1
				diff[r + 1] -= 1
		# 高端越界区间: t ∈ [PLAY_MAX-m+1, t_max]
		var hi_bnd := PLAY_MAX - m
		if hi_bnd + 1 <= t_max:
			var l: int = maxi(hi_bnd + 1, t_min) - t_min
			var r := u
			if l <= r:
				diff[l] += 1
				diff[r + 1] -= 1
	var fold_count := PackedInt32Array()
	fold_count.resize(u + 1)
	var acc := 0
	for k in range(u + 1):
		acc += diff[k]
		fold_count[k] = acc

	# C) 选折叠最少的 t；并列（折叠数相同）时取黑键投影总偏移最小者，再贴近加权中心
	var best_t := t_min
	var best_fold := 999999
	var best_black := 999999.0
	var best_center_d := 999999.0
	for k in range(u + 1):
		var t := t_min + k
		var f := int(fold_count[k])
		if f > best_fold:
			continue
		var blk := 0.0
		for ev in events:
			var m: int = ev["midi"] + t
			if m >= PLAY_MIN and m <= PLAY_MAX:
				# 范围外的音会被 clamp 到边界(60/88 均为自然音)，黑白键代价为 0
				if _nearest_natural(m) != m:
					blk += 1.0
		var cd: float = absf(float(t) - (center - src_center))
		if f < best_fold:
			best_fold = f; best_black = blk; best_center_d = cd; best_t = t
		elif blk < best_black - 0.001:
			best_black = blk; best_center_d = cd; best_t = t
		elif abs(blk - best_black) < 0.001 and cd < best_center_d:
			best_center_d = cd; best_t = t

	# D) 优先保留原调：原谱全部落在琴音域内、且 t=0 无折叠无黑键时，直接 t=0
	#    （不无谓改调性，忠实原谱最安全；只有折叠/黑键时才需要平移）
	if lo >= PLAY_MIN and hi <= PLAY_MAX:
		var zero_black := 0
		for ev in events:
			var m0: int = int(ev["midi"])
			if _nearest_natural(m0) != m0:
				zero_black += 1
		if zero_black == 0:
			res["translate"] = 0
			res["folded_count"] = 0
			res["adaptible"] = true
			return res

	res["translate"] = best_t
	res["folded_count"] = best_fold

	# 可演奏性：只要折叠后仍能落在琴上即可
	res["adaptible"] = true
	return res

## 执行适配。with_chord 现已弃用（不再自动加和弦）：
## 仅做 移调+折叠+黑键吸附，随后识别主旋律并限制任意时刻同时发声 ≤3。
## 返回 {events, translate, stats:{folded, black, poly_cut}}。
static func adapt(events: Array, with_chord: bool = true) -> Dictionary:
	var empty := {"events": [], "translate": 0, "stats": {"folded": 0, "black": 0, "poly_cut": 0}}
	if events.is_empty():
		return empty

	var ana := analyze(events)
	var t: int = ana["translate"]
	var folded := 0
	var black := 0

	# 移调 + 折叠 + 黑键吸附
	var out := []
	for ev in events:
		var m: int = ev["midi"] + t
		if m < PLAY_MIN or m > PLAY_MAX:
			folded += 1
			print("[midi_adapter] 折叠(移调越界): 源 %d 移调 %d 结果 %d -> 边界" % [int(ev["midi"]), t, m])
		m = int(clamp(m, PLAY_MIN, PLAY_MAX))   # 折叠到边界
		var snapped: int = _nearest_natural(m)
		if snapped != m:
			black += 1
			print("[midi_adapter] 黑键吸附: 折叠后 %d(%s) -> 自然音 %d(%s)" % [m, _tone_name(m), snapped, _tone_name(snapped)])
		out.append({
			"midi": snapped,
			"start": ev["start"],
			"dur": ev["dur"],
			"tone": _tone_name(snapped),
			"channel": int(ev.get("channel", 0)),
		})

	var limited: Dictionary = _limit_polyphony(out)
	return {
		"events": limited["events"],
		"translate": t,
		"stats": {
			"folded": folded,
			"black": black,
			"poly_cut": int(limited["stats"]["poly_cut"]),
		},
	}

## 识别主旋律 channel，并限制任意时刻同时发声 ≤3。
## 规则：按 start 时间窗口（≤50ms，与下落条多音判定一致）分组；
## 组内主旋律音符全部保留，其余非旋律音符裁剪至总复音 ≤3（优先保留离主旋律近的）。
## 主旋律判定：优先固定 channel 0；若 0 号音符占比低于 CH0_RATIO（0.20），
## 则回退为"音符最多的 channel"（自适应）。
## 返回 {events, stats}，stats.poly_cut 为因复音超限被裁剪的音符数。
## 挑选主旋律 channel：优先固定 0 号；若 0 号音符占比低于 0.20 则回退到音符最多的 channel。
static func pick_melody_channel(events: Array) -> int:
	if events.is_empty():
		return 0
	const CH0_RATIO := 0.20   # 0 号 channel 作为主旋律所需的最低占比
	var counts := {}
	for e in events:
		var c: int = e["channel"]
		counts[str(c)] = counts.get(str(c), 0) + 1
	if float(int(counts.get("0", 0))) / float(events.size()) >= CH0_RATIO:
		return 0
	var melody_ch := 0
	var max_c := 0
	for ck in counts.keys():
		if int(counts[ck]) > max_c:
			max_c = int(counts[ck])
			melody_ch = int(ck)
	return melody_ch

static func _limit_polyphony(events: Array) -> Dictionary:
	if events.is_empty():
		return {"events": [], "stats": {"poly_cut": 0}}
	# 1) 主旋律 channel（固定 0 号 + 占比回退）
	var melody_ch := pick_melody_channel(events)

	# 2) 按 start 排序
	events.sort_custom(func(a, b): return a["start"] < b["start"])

	# 3) 窗口分组并裁剪
	const WINDOW := 0.05
	var result: Array = []
	var poly_cut := 0
	var i := 0
	while i < events.size():
		var j := i
		while j + 1 < events.size() and events[j + 1]["start"] - events[i]["start"] <= WINDOW:
			j += 1
		var group: Array = events.slice(i, j + 1)
		var keep: Array = []
		var others: Array = []   # 非主旋律音符
		for e in group:
			if int(e["channel"]) == melody_ch:
				keep.append(e)
			else:
				others.append(e)
		# 若组内没有主旋律音符，把组内第一个视为旋律（避免整组被裁光）
		if keep.is_empty() and not others.is_empty():
			others.sort_custom(func(a, b): return a["start"] < b["start"])
			keep.append(others.pop_front())
		# 主旋律音符自身若 >3（极端），仅保前 3
		var keep_slots: Array = []
		var used_keys := {}   # 同键位去重：吸附后撞到同一键的音只保留一个
		for k in range(min(keep.size(), 3)):
			var e: Dictionary = keep[k]
			var key := int(e["midi"])
			if used_keys.has(str(key)):
				poly_cut += 1
				print("[midi_adapter] 同键去重: t=%.2f 键位 %d(%s) 已被占用，丢弃一个" % [float(events[i]["start"]), key, _tone_name(key)])
				continue
			used_keys[str(key)] = true
			keep_slots.append(e)
		# 其余非主旋律音符：还允许 3 - keep_slots.size() 个，优先保留频率（音高）最接近主旋律的
		var budget := 3 - keep_slots.size()
		if budget > 0:
			# 以组内已保主旋律的平均音高为基准，越近越保留
			var base := 0.0
			for kp in keep_slots:
				base += float(kp["midi"])
			if keep_slots.size() > 0:
				base /= keep_slots.size()
			others.sort_custom(func(a, b): return abs(float(a["midi"]) - base) < abs(float(b["midi"]) - base))
			for k in range(min(budget, others.size())):
				var oe: Dictionary = others[k]
				var okey := int(oe["midi"])
				if used_keys.has(str(okey)):
					poly_cut += 1
					print("[midi_adapter] 同键去重: t=%.2f 键位 %d(%s) 已被占用，丢弃一个" % [float(events[i]["start"]), okey, _tone_name(okey)])
					continue
				used_keys[str(okey)] = true
				keep_slots.append(oe)
			# 超出预算的非主旋律音符全部裁剪，记录数量
			var cut_cnt := maxi(0, others.size() - budget)
			poly_cut += cut_cnt
			if cut_cnt > 0:
				print("[midi_adapter] 复音裁剪: t=%.2f 组内%d音(旋律%d) 预算%d 裁剪%d个非旋律音" % [float(events[i]["start"]), group.size(), keep.size(), budget, cut_cnt])
		for e in keep_slots:
			result.append(e)
		i = j + 1

	return {"events": result, "stats": {"poly_cut": poly_cut}}

## 将单个 midi 音号吸附到最近的自然音
static func _nearest_natural(midi: int) -> int:
	var best: int = NAT_MIDI[0]
	var best_d := 99999
	for nm in NAT_MIDI:
		var d: int = abs(nm - midi)
		if d < best_d:
			best_d = d
			best = nm
	return best

static func _tone_name(midi: int) -> String:
	return MIDI_NAME_PC[midi % 12] + str(midi / 12 - 1)

const MIDI_NAME_PC: Array = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]