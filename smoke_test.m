function smoke_test()
%SMOKE_TEST Fast structural test; does not reproduce thesis performance.
setup; cfg=config(); rng(cfg.randomSeed);
K=6; nSubjects=30; segPerSubject=4; p=24;
subjectID=repelem("P"+compose('%03d',(1:nSubjects)'),segPerSubject)';
y=repelem(categorical(repmat({'N','AS','AR','MR','MS','MD'},1,ceil(nSubjects/K))),segPerSubject)';
y=y(1:numel(subjectID));
X=randn(numel(y),p);
foldId=make_subject_folds(subjectID,y,5,cfg.randomSeed);
for k=1:5
    assert(isempty(intersect(unique(subjectID(foldId==k)),unique(subjectID(foldId~=k)))));
end
fprintf('SMOKE TEST PASSED: subject-wise fold construction has zero patient overlap.\n');
end
