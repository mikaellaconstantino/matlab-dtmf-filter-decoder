name = "givename_surname";
student_number = "123456789";
section = "thu";

%% DTMF Decoder
% Note: You are not allowed to modify the input and output variable(s).
% You may add 'helper' functions in this section but the checker will only
% call DTMF_decoder_using_filter

function y = DTMF_decoder_using_filter(signal)
% DTMF_decoder_using_filter - Decodes DTMF signals using digital filters
% Input: signal - the DTMF signal to decode 
% Output: y - row vector of decoded key numbers/characters

% Constants
fs = 8000; % Sampling frequency as per instructions
r = 0.98;  % Pole radius for ~30 Hz bandwidth to ensure selectivity (73 Hz min separation)
N = 80;    % Smoothing filter order (10 ms at 8000 Hz, balances smoothness for 50-100 ms tones)
plot_response = true; % Set to false to disable plotting for checker

% Load and validate signal
if ischar(signal)
    [input_signal, fs_actual] = audioread(signal);
    % Ensure 8000 Hz sampling rate
    if fs_actual ~= fs
        input_signal = resample(input_signal, fs, fs_actual);
    end
else
    input_signal = signal;
end

% Convert to mono if stereo
if size(input_signal, 2) > 1
    input_signal = mean(input_signal, 2);
end

% DTMF frequency table
low_freqs = [697, 770, 852, 941];   % Low frequency group
high_freqs = [1209, 1336, 1477];    % High frequency group
all_freqs = [low_freqs, high_freqs];

% Key mapping based on DTMF table
key_map = ['1', '2', '3';
           '4', '5', '6';
           '7', '8', '9';
           '*', '0', '#'];

%% Step 1: Design Bandpass Filters
% Design 7 bandpass filters centered at DTMF frequencies with zeros at others
filters = design_bandpass_filters(all_freqs, fs, r);

% Plot frequency responses for verification
if plot_response
    figure;
    hold on;
    colors = lines(7);
    for i = 1:7
        [h, w] = freqz(filters{i}{1}, filters{i}{2}, 1024, fs);
        f = w;
        plot(f, 20*log10(abs(h)), 'Color', colors(i,:), 'LineWidth', 2);
    end
    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
    title('DTMF Bandpass Filter Responses');
    grid on;
    legend('697 Hz', '770 Hz', '852 Hz', '941 Hz', '1209 Hz', '1336 Hz', '1477 Hz');
    xlim([0, 2000]);
    
end

%% Step 2 & 3: Process signal and decode
y = process_and_decode(input_signal, filters, key_map, fs, N);
end

function filters = design_bandpass_filters(freqs, fs, r)
% Design 7 bandpass filters centered at DTMF frequencies
% r: Pole radius controls bandwidth (~30 Hz for r=0.98)
% Zeros placed at other DTMF frequencies for selectivity
filters = cell(1, 7);

for i = 1:7
    fc = freqs(i);  % Center frequency
    wc = 2 * pi * fc / fs; % Normalized center frequency
    
    % Complex conjugate poles at center frequency
    poles = r * exp(1j * [wc, -wc]);
    
    % Zeros at DC, Nyquist, and other DTMF frequencies
    other_freqs = freqs;
    other_freqs(i) = []; % Exclude current frequency
    zeros = [1, -1]; % DC and Nyquist
    for f = other_freqs
        w = 2 * pi * f / fs;
        zeros = [zeros, exp(1j * w), exp(-1j * w)];
    end
    
    % Convert to transfer function
    num = poly(zeros);
    den = poly([poles, conj(poles)]);
    
    % Normalize gain at center frequency
    [h_norm, w] = freqz(num, den, 1024, fs);
    [~, max_idx] = max(abs(h_norm));
    gain = 1 / abs(h_norm(max_idx));
    num = num * gain;
    
    filters{i} = {num, den};
end
end

function y = process_and_decode(input_signal, filters, key_map, fs, N)
% Process signal in segments and decode DTMF tones
segment_length = round(0.1 * fs); % 100 ms segments, typical DTMF tone duration
hop_length = round(0.05 * fs);    % 50 ms overlap to capture transitions

num_segments = floor((length(input_signal) - segment_length) / hop_length) + 1;
y = [];

for seg = 1:num_segments
    % Extract segment
    start_idx = (seg - 1) * hop_length + 1;
    end_idx = min(start_idx + segment_length - 1, length(input_signal));
    segment = input_signal(start_idx:end_idx);
    
    % Apply filters and measure strengths
    filter_strengths = apply_filters_and_measure(segment, filters, N);
    
    % Decode the segment
    key = decode_segment(filter_strengths, key_map);
    
    % Add to results if valid and not duplicate
    if ~isempty(key)
        if isempty(y) || y(end) ~= key
            y = [y, key];
        end
    end
end
end

function strengths = apply_filters_and_measure(segment, filters, N)
% Apply 7 bandpass filters and measure output strengths
% Smoothing filter: H(z) = (1/N) * (1 - z^-N) / (1 - z^-1)
% Larger N increases smoothness but introduces delay
strengths = zeros(1, 7);

for i = 1:7
    % Apply bandpass filter
    filtered = filter(filters{i}{1}, filters{i}{2}, segment);
    
    % Full-wave rectification
    rectified = abs(filtered);
    
    % Smoothing filter (moving average)
    N_effective = min(N, length(rectified)); % Handle short segments
    smoothed = filter(ones(1, N_effective)/N_effective, 1, rectified);
    strengths(i) = mean(smoothed(N_effective:end));
end
end

function key = decode_segment(strengths, key_map)
% Decode a single segment based on filter strengths
key = [];

% Find two strongest components
[sorted_strengths, sorted_indices] = sort(strengths, 'descend');

% Adaptive threshold and minimum strength for noise rejection
threshold = 0.15 * max(sorted_strengths);
min_strength = 0.01; % Minimum strength to reject noise (adjust based on signal)

if sorted_strengths(1) > threshold && sorted_strengths(2) > threshold && sorted_strengths(1) > min_strength
    % Separate low and high frequency indices
    freq_indices = sorted_indices(1:2);
    low_idx = -1;
    high_idx = -1;
    
    for idx = freq_indices
        if idx <= 4
            low_idx = idx;  % Low frequency group (1-4)
        else
            high_idx = idx - 4;  % High frequency group (5-7 -> 1-3)
        end
    end
    
    % Decode if we have both components
    if low_idx > 0 && high_idx > 0
        key = key_map(low_idx, high_idx);
    end
end
end

%% Checker
% do not edit this part
signal = "input.wav";
y_student = DTMF_decoder_using_filter(signal);
y_answer = 0; %line for checker
score = 0;
if(y_answer == y_answer)
    score = 100;
end