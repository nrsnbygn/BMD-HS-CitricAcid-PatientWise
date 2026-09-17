function audit_patient_leakage(subjectID,foldId,cfg)
%AUDIT_PATIENT_LEAKAGE Prove no subject overlaps train/test in any fold.
subjectID=string(subjectID(:));
K=max(foldId);
Fold=(1:K)'; TrainSubjects=zeros(K,1); TestSubjects=zeros(K,1); OverlapSubjects=zeros(K,1);
for k=1:K
    tr=unique(subjectID(foldId~=k)); te=unique(subjectID(foldId==k));
    TrainSubjects(k)=numel(tr); TestSubjects(k)=numel(te);
    OverlapSubjects(k)=numel(intersect(tr,te));
end
T=table(Fold,TrainSubjects,TestSubjects,OverlapSubjects);
writetable(T,fullfile(cfg.resultsDir,'LEAKAGE_AUDIT.csv'));
assert(all(OverlapSubjects==0),'Leakage audit failed.');
end
