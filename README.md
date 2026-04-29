# MATLAB DTMF Decoder Using Digital Filters

A MATLAB implementation of a DTMF signal decoder 
using digital bandpass filters developed as part of 
EEE 147 coursework at the University of the 
Philippines Diliman.

## Overview
Unlike FFT-based decoders, this implementation uses 
custom-designed digital bandpass filters centered at 
each DTMF frequency. This approach more closely 
mirrors real-world hardware telephone decoders.

## How It Works

### Step 1 — Filter Design
- Designs 7 bandpass filters, one per DTMF frequency
- Uses pole-zero placement for frequency selectivity
- Poles placed at target frequency for resonance
- Zeros placed at all other DTMF frequencies to 
  reject interference
- Pole radius r = 0.98 for ~30 Hz bandwidth

### Step 2 — Signal Processing
- Segments input signal into 100 ms windows
- Applies all 7 bandpass filters per segment
- Full-wave rectification of filtered output
- Moving average smoothing filter (10 ms window)
- Measures signal strength per frequency band

### Step 3 — Decoding
- Identifies two strongest frequency components
- Matches one low (697-941 Hz) and one high 
  (1209-1477 Hz) frequency
- Maps frequency pair to DTMF keypad digit
- Duplicate detection to avoid repeated outputs

## DTMF Frequency Groups

| Group | Frequencies (Hz) |
|-------|-----------------|
| Low   | 697, 770, 852, 941 |
| High  | 1209, 1336, 1477 |

## Key Differences from FFT Decoder

| Feature | FFT Decoder | Filter Decoder |
|---------|-------------|----------------|
| Method | Frequency domain | Time domain |
| Approach | Global analysis | Per-sample filtering |
| Hardware analog | Software only | Mirrors real circuits |
| Selectivity | FFT bins | Pole-zero placement |

## How to Use
```matlab
% Decode from .wav file
y = DTMF_decoder_using_filter('input.wav');
disp(y);
```

## Technologies Used
- **Language:** MATLAB
- **Concepts:** Digital Filter Design, Pole-Zero 
  Placement, Bandpass Filtering, Signal Segmentation,
  Full-Wave Rectification, DTMF Decoding
- **Sampling Rate:** 8000 Hz

## Course
EEE 147 — Electronics Engineering  
University of the Philippines Diliman

## Status
Completed — University Machine Problem
