function T = audit_raw_dataset(rawDir)
%AUDIT_RAW_DATASET Verify BMD-HS WAV files before MFCC extraction.
% Usage:
%   T = audit_raw_dataset("C:\\Users\\NursenaPC\\Documents\\MATLAB\\BMD-HS-Dataset-main\\BMD-HS-Dataset-main\\train");

if nargin < 1
    rawDir = "C:\Users\NursenaPC\Documents\MATLAB\BMD-HS-Dataset-main\BMD-HS-Dataset-main\train";
end
rawDir = string(rawDir);
assert(isfolder(rawDir), 'Raw-data folder not found: %s', rawDir);

files = dir(fullfile(rawDir,'*.wav'));
assert(~isempty(files), 'No WAV files found in %s', rawDir);

% Deterministic order: sort by filename. This audit does NOT yet assume that
% this is the same row order as features_2120.mat.
[~,ord] = sort(lower(string({files.name})));
files = files(ord);

n = numel(files);
fileName = strings(n,1);
subjectID = strings(n,1);
label = strings(n,1);
sampleRate = zeros(n,1);
numSamples = zeros(n,1);
durationSec = zeros(n,1);
num2sSegments = zeros(n,1);

for i = 1:n
    fileName(i) = string(files(i).name);
    info = audioinfo(fullfile(files(i).folder,files(i).name));
    sampleRate(i) = info.SampleRate;
    numSamples(i) = info.TotalSamples;
    durationSec(i) = info.Duration;

    % Number of complete, non-overlapping 2-s windows at the native Fs.
    segN = round(2*info.SampleRate);
    num2sSegments(i) = floor(info.TotalSamples/segN);

    stem = erase(fileName(i), ".wav");
    tok = regexp(stem,'^([^_]+)_([0-9]+)_','tokens','once');
    if isempty(tok)
        error('Unexpected filename format: %s',fileName(i));
    end
    label(i) = string(tok{1});
    subjectID(i) = string(tok{2});
end

T = table(fileName,subjectID,label,sampleRate,numSamples,durationSec,num2sSegments);
writetable(T,'raw_dataset_audit.csv');

fprintf('\nBMD-HS RAW DATA AUDIT\n');
fprintf('WAV files              : %d\n',n);
fprintf('Unique subjects         : %d\n',numel(unique(subjectID)));
fprintf('Sample rates            : %s Hz\n',mat2str(unique(sampleRate)'));
fprintf('Complete 2-s segments   : %d\n',sum(num2sSegments));
fprintf('Min/max duration        : %.3f / %.3f s\n',min(durationSec),max(durationSec));
fprintf('Recordings != 10 windows: %d\n',sum(num2sSegments~=10));

if n==872 && numel(unique(subjectID))==109 && all(sampleRate==4000) && sum(num2sSegments)==8716
    fprintf('\nPASS: 872 WAV, 109 subjects, 4 kHz and 8716 complete 2-s segments match the thesis data.\n');
else
    fprintf('\nCHECK NEEDED: one or more expected counts differ. Do not extract MFCC yet.\n');
end

bad = T(T.num2sSegments~=10,:);
if ~isempty(bad)
    fprintf('\nRecordings with a non-10 segment count:\n');
    disp(bad(:,{'fileName','subjectID','label','durationSec','num2sSegments'}));
end
end
