function run_from_features(featureFile)
%RUN_FROM_FEATURES Leakage-free, patient-wise balanced evaluation.
setup; cfg=config();
if nargin<1, featureFile=fullfile('data','features_2120.mat'); end
assert(isfile(featureFile),'Missing %s',featureFile);
S=load(featureFile); req={'X','y','subjectID'};
for i=1:numel(req), assert(isfield(S,req{i}),'MAT file needs variable %s.',req{i}); end
X=double(S.X); y=categorical(S.y); subjectID=string(S.subjectID);
assert(size(X,1)==numel(y) && numel(y)==numel(subjectID),'Row counts disagree.');
assert(size(X,2)==2120,'Expected 2120 features; got %d.',size(X,2));
assert(all(strlength(subjectID)>0) && all(isfinite(X(:))),'Invalid X or subjectID.');
expected={'N','AS','AR','MR','MS','MD'}; actual=categories(removecats(y));
assert(all(ismember(actual,expected)) && numel(actual)==6,'Expected six thesis classes.');

subs=unique(subjectID,'stable');
for i=1:numel(subs)
    yi=removecats(y(subjectID==subs(i)));
    if numel(categories(yi))~=1, error('Subject %s has multiple thesis labels.',subs(i)); end
end
fprintf('Loaded %d segments, %d features, %d subjects.\n',size(X,1),size(X,2),numel(subs));

capIdx=[]; statIdx=[];
for b=0:4
    base=b*424; capIdx=[capIdx,base+(1:384)]; statIdx=[statIdx,base+(385:424)]; %#ok<AGROW>
end

foldId=make_subject_folds(subjectID,y,cfg.numFolds,cfg.randomSeed);
writetable(table((1:numel(y))',subjectID,string(y),foldId,'VariableNames', ...
    {'Row','SubjectID','Label','Fold'}),fullfile(cfg.resultsDir,'patientwise_fold_assignment.csv'));

fprintf('\nTRAIN-ONLY BALANCING: %s\n',cfg.balance.method);
fprintf('Held-out patients remain at their natural class distribution.\n');
baseline=evaluate_patientwise(X,y,subjectID,statIdx,'balanced_baseline_stats',cfg,foldId);
caponly=evaluate_patientwise(X,y,subjectID,capIdx,'balanced_cap_only',cfg,foldId);
proposed=evaluate_patientwise(X,y,subjectID,1:size(X,2),'balanced_proposed_cap_stats',cfg,foldId);

save_outputs(baseline,'balanced_baseline',cfg);
save_outputs(caponly,'balanced_cap_only',cfg);
save_outputs(proposed,'balanced_proposed',cfg);
summary=[baseline.overall;caponly.overall;proposed.overall];
writetable(summary,fullfile(cfg.resultsDir,'BALANCED_SUMMARY.csv'));
audit_patient_leakage(subjectID,foldId,cfg);
fprintf('\nFinished. Send the entire results folder.\n'); disp(summary);
end

function save_outputs(R,name,cfg)
writetable(R.foldMetrics,fullfile(cfg.resultsDir,[name '_fold_metrics.csv']));
writetable(R.predictions,fullfile(cfg.resultsDir,[name '_predictions.csv']));
writetable(R.perClass,fullfile(cfg.resultsDir,[name '_per_class.csv']));
writematrix(R.confusion,fullfile(cfg.resultsDir,[name '_confusion.csv']));
end
