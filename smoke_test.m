function smoke_test()
%SMOKE_TEST Fast structural test of the leakage-free pipeline.
setup; cfg=config(); rng(cfg.randomSeed);

% 1) CAP must always return exactly 384 finite features.
h=citric_acid_pattern(randn(400,1));
assert(isequal(size(h),[1 384]),'CAP must return 1x384 features.');
assert(all(isfinite(h)),'CAP returned non-finite values.');

% 2) Whole subjects must remain in exactly one fold.
classes={'N','AS','AR','MR','MS','MD'};
nSubjects=30; segPerSubject=4; p=24;
subjectID=repelem("P"+compose('%03d',(1:nSubjects)'),segPerSubject)';
subjectClass=repmat(classes,1,ceil(nSubjects/numel(classes)));
subjectClass=subjectClass(1:nSubjects);
y=categorical(repelem(subjectClass,segPerSubject)');
X=randn(numel(y),p);
foldId=make_subject_folds(subjectID,y,5,cfg.randomSeed);
for k=1:5
    assert(isempty(intersect(unique(subjectID(foldId==k)),unique(subjectID(foldId~=k))), ...
        'Patient overlap detected in smoke test.');
end

% 3) NCA must be fitted on training rows only and return requested count.
tr=foldId~=1; te=foldId==1;
[idx,~]=nca_select_train_only(X(tr,:),y(tr),8);
assert(numel(idx)==8 && all(idx>=1 & idx<=p),'NCA selection failed.');

% 4) Train-only scaling + thesis classifier must produce one prediction/test row.
mu=mean(X(tr,idx),1); sd=std(X(tr,idx),0,1); sd(sd==0)=1;
A=(X(tr,idx)-mu)./sd; B=(X(te,idx)-mu)./sd;
cfg.ensemble.NumLearningCycles=5;
mdl=train_subspace_knn(A,y(tr),cfg);
yp=predict(mdl,B);
assert(numel(yp)==sum(te),'Classifier prediction count mismatch.');

fprintf('SMOKE TEST PASSED: CAP=384, patient overlap=0, train-only NCA and classifier operational.\n');
end
