function build_raw_cap_mfcc(rawDir)
%BUILD_RAW_CAP_MFCC Build leakage-free-ready CAP and MFCC features from raw BMD-HS WAVs.
% Uses every complete non-overlapping 2-s segment. Trailing incomplete audio
% is discarded. CAP is computed on raw+A1+A2+A3+A4. MFCC is computed from
% each raw 2-s segment and summarized by coefficient mean+std across frames.
%
% Output: data/raw_cap_mfcc.mat with Xcap, Xmfcc, y, subjectID, wavFile,
% segmentInFile. No old features_2120 row ordering is used.

setup; cfg=config();
if nargin<1 || strlength(string(rawDir))==0
 rawDir="C:\Users\NursenaPC\Documents\MATLAB\BMD-HS-Dataset-main\BMD-HS-Dataset-main\train";
end
assert(isfolder(rawDir),'Raw folder not found: %s',rawDir);
assert(exist('mfcc','file')==2,'MATLAB mfcc() not found. Audio Toolbox is required.');

files=dir(fullfile(rawDir,'*.wav'));
assert(numel(files)==872,'Expected 872 WAV files; got %d.',numel(files));
[~,ord]=sort(lower(string({files.name}))); files=files(ord);

% Pre-count complete 2-s segments.
N=0;
for i=1:numel(files)
 ai=audioinfo(fullfile(files(i).folder,files(i).name));
 assert(ai.SampleRate==cfg.fs,'Expected 4 kHz: %s',files(i).name);
 N=N+floor(ai.TotalSamples/cfg.segmentSamples);
end
assert(N==8716,'Expected 8716 segments; got %d.',N);

Xcap=zeros(N,1920,'single'); % 384 CAP x 5 thesis components
% MATLAB mfcc default coefficient count can vary with options/releases.
% Determine dimension once from a real 2-s segment, then allocate.
[x0,fs0]=audioread(fullfile(files(1).folder,files(1).name));
if size(x0,2)>1, x0=mean(x0,2); end
M0=mfcc(double(x0(1:cfg.segmentSamples)),fs0);
d=size(M0,2);
Xmfcc=zeros(N,2*d,'single'); % per-coefficient frame mean + std

y=strings(N,1); subjectID=strings(N,1); wavFile=strings(N,1); segmentInFile=zeros(N,1);
k=0; t0=tic;
for i=1:numel(files)
 [x,fs]=audioread(fullfile(files(i).folder,files(i).name));
 if size(x,2)>1, x=mean(x,2); end
 segs=segment_recording(x,fs,cfg.segmentSeconds);
 stem=erase(string(files(i).name),".wav");
 tok=regexp(stem,'^([^_]+)_([0-9]+)_','tokens','once');
 assert(~isempty(tok),'Unexpected filename: %s',files(i).name);
 lab=string(tok{1}); sid=string(tok{2});
 for s=1:size(segs,1)
  k=k+1; z=double(segs(s,:)).';
  comps=dwt_components(z,cfg.wavelet);
  f=zeros(1,1920); q=0;
  for c=1:5
   h=citric_acid_pattern(comps{c});
   f(q+(1:384))=h; q=q+384;
  end
  Xcap(k,:)=single(f);
  M=mfcc(z,fs);
  assert(size(M,2)==d,'MFCC dimension changed unexpectedly.');
  Xmfcc(k,:)=single([mean(M,1,'omitnan'),std(M,0,1,'omitnan')]);
  y(k)=lab; subjectID(k)=sid; wavFile(k)=string(files(i).name); segmentInFile(k)=s;
 end
 if mod(i,50)==0 || i==numel(files)
  fprintf('Processed WAV %d/%d; segments %d/%d; elapsed %.1f min\n',i,numel(files),k,N,toc(t0)/60);
 end
end
assert(k==N);
y=categorical(y);
save(fullfile('data','raw_cap_mfcc.mat'),'Xcap','Xmfcc','y','subjectID','wavFile','segmentInFile','-v7.3');
fprintf('\nDONE: data\\raw_cap_mfcc.mat\nCAP dimensions: %d x %d\nMFCC dimensions: %d x %d\n',size(Xcap),size(Xmfcc));
end
