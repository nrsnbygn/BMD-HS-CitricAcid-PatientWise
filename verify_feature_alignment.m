function R = verify_feature_alignment(featureFile, rawDir)
%VERIFY_FEATURE_ALIGNMENT Check whether features_2120 rows can be aligned to raw BMD-HS segments.
% This does not assume filename order is feature-row order. It tests subject/label
% run structure against several deterministic recording orders and reports only
% an exact match as PASS.
%
% Usage:
%   R = verify_feature_alignment;
%
% Required MAT variables: X, y, subjectID.

if nargin < 1 || strlength(string(featureFile))==0
    featureFile = fullfile('data','features_2120.mat');
end
if nargin < 2 || strlength(string(rawDir))==0
    rawDir = "C:\Users\NursenaPC\Documents\MATLAB\BMD-HS-Dataset-main\BMD-HS-Dataset-main\train";
end

assert(isfile(featureFile),'Feature file not found: %s',featureFile);
assert(isfolder(rawDir),'Raw-data folder not found: %s',rawDir);
S=load(featureFile);
assert(isfield(S,'X')&&isfield(S,'y')&&isfield(S,'subjectID'), ...
    'MAT must contain X, y and subjectID.');
nFeat=size(S.X,1);
featSub=string(S.subjectID(:));
featLab=string(S.y(:));
assert(numel(featSub)==nFeat && numel(featLab)==nFeat,'Feature row counts disagree.');

files=dir(fullfile(rawDir,'*.wav'));
assert(numel(files)==872,'Expected 872 WAV files; got %d.',numel(files));
n=numel(files);
name=strings(n,1); sub=strings(n,1); lab=strings(n,1);
pos=strings(n,1); site=strings(n,1); nseg=zeros(n,1);
for i=1:n
    name(i)=string(files(i).name);
    stem=erase(name(i),".wav");
    tok=regexp(stem,'^([^_]+)_([0-9]+)_(sit|sup)_(Aor|Mit|Pul|Tri)$','tokens','once');
    if isempty(tok), error('Unexpected filename: %s',name(i)); end
    lab(i)=string(tok{1}); sub(i)=string(tok{2}); pos(i)=string(tok{3}); site(i)=string(tok{4});
    ai=audioinfo(fullfile(files(i).folder,files(i).name));
    assert(ai.SampleRate==4000,'Unexpected Fs in %s',name(i));
    nseg(i)=floor(ai.TotalSamples/(2*ai.SampleRate));
end
assert(sum(nseg)==nFeat,'Raw complete segments=%d but feature rows=%d.',sum(nseg),nFeat);

% Candidate recording orders. We accept only an exact subject+label row match.
posOrder = containers.Map({'sit','sup'},{1,2});
siteOrder = containers.Map({'Aor','Mit','Pul','Tri'},{1,2,3,4});
pnum=zeros(n,1); snum=zeros(n,1); subjNum=str2double(sub);
for i=1:n, pnum(i)=posOrder(char(pos(i))); snum(i)=siteOrder(char(site(i))); end

candidates=cell(0,2);
[~,o1]=sort(lower(name)); candidates(end+1,:)={'filename_lexicographic',o1};
[~,o2]=sortrows([subjNum,pnum,snum],[1 2 3]); candidates(end+1,:)={'subject_position_site',o2};
[~,o3]=sortrows([subjNum,snum,pnum],[1 2 3]); candidates(end+1,:)={'subject_site_position',o3};

rows={}; bestMismatch=inf; bestName="";
for c=1:size(candidates,1)
    ord=candidates{c,2};
    rawSub=strings(nFeat,1); rawLab=strings(nFeat,1); rawFile=strings(nFeat,1); rawSeg=zeros(nFeat,1);
    k=0;
    for j=1:numel(ord)
        ii=ord(j);
        for s=1:nseg(ii)
            k=k+1; rawSub(k)=sub(ii); rawLab(k)=lab(ii); rawFile(k)=name(ii); rawSeg(k)=s;
        end
    end
    sameSub = normalize_id(rawSub)==normalize_id(featSub);
    sameLab = upper(rawLab)==upper(featLab);
    mismatch=sum(~(sameSub & sameLab));
    rows(end+1,:)={string(candidates{c,1}),mismatch}; %#ok<AGROW>
    if mismatch<bestMismatch
        bestMismatch=mismatch; bestName=string(candidates{c,1});
        bestFile=rawFile; bestSeg=rawSeg; bestRawSub=rawSub; bestRawLab=rawLab; %#ok<NASGU>
    end
end

R=cell2table(rows,'VariableNames',{'CandidateOrder','SubjectLabelMismatches'});
disp(R);
fprintf('\nBest candidate: %s; mismatched rows: %d / %d\n',bestName,bestMismatch,nFeat);

if bestMismatch==0
    rowNumber=(1:nFeat)';
    segmentMap=table(rowNumber,bestFile,bestSeg,bestRawSub,bestRawLab, ...
        'VariableNames',{'RowNumber','WavFile','SegmentInFile','SubjectID','Label'});
    writetable(segmentMap,fullfile('data','segment_row_map.csv'));
    save(fullfile('data','segment_row_map.mat'),'segmentMap','bestName');
    fprintf('PASS: exact subject+label alignment found.\n');
    fprintf('Saved data\\segment_row_map.csv and data\\segment_row_map.mat\n');
    fprintf('NOTE: this proves row-level subject/label compatibility, not waveform-to-feature identity.\n');
else
    fprintf('NO PASS: do not concatenate MFCC with the 2120-D matrix yet.\n');
    fprintf('We need the original feature-generation row manifest or code to establish exact row identity.\n');
end
end

function z=normalize_id(x)
x=string(x);
v=str2double(x);
z=x;
ok=~isnan(v);
z(ok)=string(v(ok));
end
