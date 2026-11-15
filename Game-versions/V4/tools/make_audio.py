#!/usr/bin/env python3
"""Genera la música y los efectos nuevos de 2Mars V4 por síntesis (numpy). Material original:
no usa muestras, grabaciones ni modelos de IA. Uso:  python3 tools/make_audio.py SALIDA
Luego convertir la música a OGG:  ffmpeg -i x.wav -c:a libvorbis -q:a 4 x.ogg"""
import sys, wave
import numpy as np
SR = 32000
OUT = sys.argv[1] if len(sys.argv) > 1 else "."
rng = np.random.default_rng(7)

def note(n):  # número MIDI -> Hz
    return 440.0 * 2 ** ((n - 69) / 12)

def env(length, a=0.01, d=0.1, s=0.6, r=0.2):
    n = int(length * SR); t = np.arange(n) / SR
    e = np.ones(n) * s
    e[t < a] = t[t < a] / a
    m = (t >= a) & (t < a + d)
    e[m] = 1 - (1 - s) * (t[m] - a) / d
    rel = int(r * SR)
    if rel > 0 and rel < n: e[-rel:] *= np.linspace(1, 0, rel)
    return e

def osc(freq, length, kind="tri", detune=0.0):
    t = np.arange(int(length * SR)) / SR
    ph = freq * t
    if kind == "sin": w = np.sin(2 * np.pi * ph)
    elif kind == "tri": w = 2 * np.abs(2 * (ph % 1) - 1) - 1
    elif kind == "saw": w = sum(np.sin(2 * np.pi * ph * k) / k for k in range(1, 9)) * 0.6
    else: w = sum(np.sin(2 * np.pi * ph * k) / k for k in (1, 3, 5, 7)) * 0.8
    if detune: w = 0.5 * w + 0.5 * osc(freq * (1 + detune), length, kind)
    return w

def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR); y = np.empty_like(x); acc = 0.0
    for i in range(len(x)):
        acc = (1 - a) * x[i] + a * acc; y[i] = acc
    return y

def add(buf, sig, at, gain=1.0):  # mezcla circular: las colas vuelven al inicio (bucle limpio)
    i = int(at * SR) % len(buf); n = len(sig)
    idx = (i + np.arange(n)) % len(buf)
    np.add.at(buf, idx, sig * gain)

def echo(buf, delay, fb=0.35, taps=3):
    out = buf.copy(); d = int(delay * SR)
    for k in range(1, taps + 1): out += np.roll(buf, d * k) * (fb ** k)
    return out

def save(name, x, peak=0.7):
    x = x / max(1e-9, np.max(np.abs(x))) * peak
    with wave.open(f"{OUT}/{name}.wav", "wb") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((x * 32767).astype(np.int16).tobytes())

def perc(kind, length=0.12):
    n = int(length * SR); t = np.arange(n) / SR
    if kind == "kick": return np.sin(2 * np.pi * (48 * t + 60 * (1 - np.exp(-t * 30)) / 30)) * np.exp(-t * 16)
    if kind == "tick": return rng.standard_normal(n) * np.exp(-t * 90) * 0.5
    return lowpass(rng.standard_normal(n), 5000) * np.exp(-t * 28) * 0.5  # shaker

def track(bpm, bars, chords, bass_pat, arp_pat, lead, drums, pad_kind="saw", bright=1400):
    beat = 60.0 / bpm; total = bars * 4 * beat
    buf = np.zeros(int(total * SR))
    for bar in range(bars):
        t0 = bar * 4 * beat; chord = chords[bar % len(chords)]
        for n_ in chord:  # colchón
            add(buf, lowpass(osc(note(n_), 4 * beat + 0.4, pad_kind, 0.004), bright) * env(4 * beat + 0.4, 0.5, 0.4, 0.8, 0.9), t0, 0.09)
        for step, deg in enumerate(bass_pat):  # bajo
            if deg is None: continue
            add(buf, lowpass(osc(note(chord[0] - 12 + deg), beat * 0.9, "sqr"), 420) * env(beat * 0.9, 0.01, 0.12, 0.55, 0.12), t0 + step * beat * 4 / len(bass_pat), 0.2)
        for step, idx in enumerate(arp_pat):  # arpegio
            if idx is None: continue
            n_ = chord[idx % len(chord)] + 12 * (idx // len(chord))
            add(buf, osc(note(n_ + 12), beat * 0.5, "tri") * env(beat * 0.5, 0.005, 0.1, 0.25, 0.25), t0 + step * beat * 4 / len(arp_pat), 0.11)
        for when, n_, dur in lead[bar % len(lead)]:  # melodía (dos frases: A y variación B)
            add(buf, lowpass(osc(note(n_), dur * beat + 0.2, "tri", 0.003), 2600) * env(dur * beat + 0.2, 0.02, 0.15, 0.6, 0.25), t0 + when * beat, 0.17)
        for when, kind, g in drums:
            add(buf, perc(kind), t0 + when * beat, g)
    return echo(buf, beat * 0.75, 0.3, 3)

# --- Base: menú y taller (re mayor, 84 pulsos por minuto, tranquila)
D, Bm, G, A = [62, 66, 69], [59, 62, 66], [55, 59, 62], [57, 61, 64]
lead_base = [[(0, 78, 1.5), (2, 81, 1), (3, 78, 1)], [(0, 76, 2), (2.5, 74, 1.5)], [(0, 74, 1), (1, 76, 1), (2, 79, 2)], [(0, 81, 3)],
             [(0, 78, 1), (1, 81, 1), (2, 83, 1.5)], [(0, 81, 2), (2.5, 78, 1.5)], [(0, 79, 1.5), (2, 76, 1), (3, 74, 1)], [(0, 74, 3)]]
save("music_base", track(84, 16, [D, D, Bm, Bm, G, G, A, A], [0, None, 7, None], [0, 1, 2, 3, 2, 1, 2, 3], lead_base, [(1, "shaker", 0.05), (3, "shaker", 0.05)], "saw", 1300), 0.62)
# --- Exploración (la dórico, 96 ppm, pulso de conducción)
Am, C, Dm, Em = [57, 60, 64], [60, 64, 67], [62, 65, 69], [64, 67, 71]
lead_ex = [[(0, 76, 1), (1.5, 72, 1), (3, 74, 1)], [], [(0, 72, 1), (1, 74, 1), (2, 76, 2)], [(2, 79, 1.5)], [(0, 81, 1.5), (2, 79, 1), (3, 76, 1)], [], [(0, 74, 1), (1, 72, 1), (2, 69, 2)], [(1, 72, 1), (2, 76, 1.5)]]
save("music_explore", track(96, 16, [Am, Am, C, C, Dm, Dm, Em, Am], [0, 0, 7, 0, 0, 7, 0, 5], [0, 2, 1, 2, 3, 2, 1, 2], lead_ex,
     [(0, "kick", 0.3), (2, "kick", 0.22), (1, "shaker", 0.07), (3, "shaker", 0.07), (1.5, "tick", 0.05), (3.5, "tick", 0.05)], "tri", 1700), 0.6)
# --- Tensión (mi menor, 112 ppm, ostinato)
Em2, Cm, Bm2, Dm2 = [52, 55, 59], [48, 52, 55], [47, 50, 54], [50, 53, 57]
lead_t = [[(0, 71, 0.5), (1, 71, 0.5), (2, 74, 1)], [(0, 71, 0.5), (1, 71, 0.5), (2, 76, 1)], [(0, 72, 2), (2, 71, 2)], [(0, 67, 3)]]
save("music_tension", track(112, 8, [Em2, Em2, Cm, Cm, Bm2, Bm2, Dm2, Em2], [0, 0, 0, 0, 0, 0, 7, 0], [0, 1, 2, 1, 0, 1, 2, 4], lead_t,
     [(0, "kick", 0.34), (1, "kick", 0.2), (2, "kick", 0.34), (3, "kick", 0.2), (0.5, "tick", 0.08), (1.5, "tick", 0.08), (2.5, "tick", 0.08), (3.5, "tick", 0.08)], "sqr", 1100), 0.58)
# --- Resolución (do mayor, 92 ppm: la tensión se resuelve en el informe)
Cmaj, Fmaj, Gmaj, Am2 = [60, 64, 67], [53, 57, 60], [55, 59, 62], [57, 60, 64]
lead_r = [[(0, 79, 1), (1, 76, 1), (2, 79, 2)], [(0, 81, 2), (2, 77, 2)], [(0, 79, 1), (1, 83, 1), (2, 86, 2)], [(0, 84, 3)]]
save("music_resolve", track(92, 8, [Cmaj, Fmaj, Gmaj, Cmaj, Am2, Fmaj, Gmaj, Cmaj], [0, None, 7, None], [0, 1, 2, 3, 4, 3, 2, 1], lead_r, [(1, "shaker", 0.05), (3, "shaker", 0.05)], "saw", 1500), 0.62)

# --- Efectos diferenciados
def blip(freqs, dur, kind="tri", gap=0.0, decay=18.0):
    parts = []
    for f in freqs:
        t = np.arange(int(dur * SR)) / SR
        parts.append(osc(f, dur, kind) * np.exp(-t * decay))
        if gap: parts.append(np.zeros(int(gap * SR)))
    return np.concatenate(parts)
save("hover", blip([note(88)], 0.045, "sin", 0, 70), 0.28)
save("click", blip([note(76)], 0.07, "tri", 0, 45), 0.5)
save("select", blip([note(76), note(83)], 0.07, "tri", 0.0, 26), 0.55)
t = np.arange(int(0.22 * SR)) / SR
clunk = lowpass(rng.standard_normal(len(t)), 900) * np.exp(-t * 38) * 0.9 + np.sin(2 * np.pi * 150 * t) * np.exp(-t * 26) * 0.6
save("attach", np.concatenate([clunk, blip([note(72), note(79)], 0.06, "tri", 0, 30)]), 0.6)
save("detach", np.concatenate([blip([note(74), note(67)], 0.06, "tri", 0, 30), clunk * 0.6]), 0.5)
save("error", blip([note(46), note(45)], 0.12, "sqr", 0.03, 14), 0.5)
save("discover", echo(blip([note(n_) for n_ in (76, 81, 85, 88)], 0.09, "sin", 0, 12), 0.09, 0.4, 2), 0.6)
fan = np.zeros(int(1.1 * SR))
for i, chord in enumerate([(72, 76, 79), (74, 77, 81), (76, 79, 84)]):
    for n_ in chord: add(fan, osc(note(n_), 0.5, "tri", 0.003) * env(0.5, 0.01, 0.1, 0.6, 0.3), i * 0.16, 0.3)
save("reward", echo(fan, 0.12, 0.3, 2), 0.62)
print("audio listo")
