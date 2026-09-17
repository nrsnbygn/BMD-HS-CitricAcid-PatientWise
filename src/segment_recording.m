function segments = segment_recording(x, fs, segmentSeconds)
%SEGMENT_RECORDING Non-overlapping fixed-length segmentation.
% Incomplete trailing samples are discarded, matching the thesis description.

x = double(x);
if size(x,2) > 1
    x = mean(x,2); % deterministic mono conversion if needed
end
x = x(:);
L = round(fs * segmentSeconds);
n = floor(numel(x)/L);
if n < 1
    segments = zeros(0,L);
    return;
end
x = x(1:n*L);
segments = reshape(x,L,n).';
end
