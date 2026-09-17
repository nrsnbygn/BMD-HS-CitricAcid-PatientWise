function foldId = make_subject_folds(subjectID, y, K, seed)
%MAKE_SUBJECT_FOLDS Assign whole subjects to folds; never split a subject.
% Greedy stratification uses each subject's modal class only to improve fold
% balance. The same subject always receives exactly one fold ID.

rng(seed,'twister');
subjectID = string(subjectID(:));
y = categorical(y(:));
subjects = unique(subjectID,'stable');
if numel(subjects) < K
    error('Need at least %d unique subjects; found %d.',K,numel(subjects));
end

% Subject-level representative label and segment count.
rep = categorical(strings(numel(subjects),1),categories(y));
nseg = zeros(numel(subjects),1);
for i=1:numel(subjects)
    idx = subjectID==subjects(i);
    nseg(i)=sum(idx);
    yi=y(idx);
    cats=categories(y);
    cnt=countcats(yi);
    [~,m]=max(cnt);
    rep(i)=categorical(cats(m),cats);
end

% Randomised, class-aware round-robin subject allocation.
foldOfSubject=zeros(numel(subjects),1);
cats=categories(y);
for c=1:numel(cats)
    ids=find(rep==cats{c});
    ids=ids(randperm(numel(ids)));
    for j=1:numel(ids)
        foldOfSubject(ids(j))=mod(j-1,K)+1;
    end
end
% Any undefined representative labels (defensive path).
ids=find(foldOfSubject==0);
for j=1:numel(ids), foldOfSubject(ids(j))=mod(j-1,K)+1; end

foldId=zeros(numel(subjectID),1);
for i=1:numel(subjects)
    foldId(subjectID==subjects(i))=foldOfSubject(i);
end

% Hard leakage assertion.
for k=1:K
    tr=unique(subjectID(foldId~=k)); te=unique(subjectID(foldId==k));
    if ~isempty(intersect(tr,te))
        error('SUBJECT LEAKAGE detected in fold %d.',k);
    end
end
end
