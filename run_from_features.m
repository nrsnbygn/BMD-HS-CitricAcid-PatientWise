function run_from_features(featureFile)
%RUN_FROM_FEATURES Leakage-free evaluation of the thesis's 2120-D features.
% Required MAT variables: X [n x 2120], y, subjectID.

setup; cfg=config();
if nargin<1, featureFile=fullfile('data','features_2120.mat'); end
assert(isfile(featureFile),'Missing %s',featureFile);
S=load(featureFile); req={'X','y','subjectID'};
for i=1:numel(req), assert(isfield(S,req{i}),'MAT file needs variable %s.',req{i}); end
X=double(S.X); y=categorical(S.y); subjectID=string(S.subjectID);
assert(size(X,1)==numel(y) && numel(y)==numel(subjectID),'Row counts disagree.');
assert(size(X,2)==2120,'Expected exactly 2120 thesis features; got %d.',size(X,2));
assert(all(strlength(subjectID)>0),'Empty subjectID detected.');
assert(all(isfinite(X(:))),'X contains NaN/Inf. Fix the original feature matrix first.');
expected={'N','AS','AR','MR','MS','MD'}; actual=categories(removecats(y));
assert(all(ismember(actual,expected)) && numel(actual)==6,'Expected exactly the six thesis classes N/AS/AR/MR/MS/MD.');

nSubjects=numel(unique(subjectID));
fprintf('Loaded %d segments, %d features, %d unique subjects.\n',size(X,1),size(X,2),nSubjects);
if nSubjects~=109, warning('Thesis reports 109 subjects; found %d. Verify subjectID.',nSubjects); end
subs=unique(subjectID,'stable');
for i=1:numel(subs)
    yi=removecats(y(subjectID==subs(i)));
    if numel(categories(yi))~=1, error('Subject %s has multiple thesis labels.',subs(i)); end
end

% Five components x [384 CAP, 40 statistics].
capIdx=[]; statIdx=[];
for b=0:4
    base=b*424; capIdx=[capIdx,base+(1:384)]; statIdx=[statIdx,base+(385:424)]; %#ok<AGROW>
end
assert(numel(capIdx)==1920 && numel(statIdx)==200);

foldId=make_subject_folds(subjectID,y,cfg.numFolds,cfg.randomSeed);
writetable(table((1:numel(y))',subjectID,string(y),foldId,'VariableNames', ...
    {'Row','SubjectID','Label','Fold'}),fullfile(cfg.resultsDir,'patientwise_fold_assignment.csv'));
subLabel=strings(numel(subs),1); subFold=zeros(numel(subs),1); subSegments=zeros(numel(subs),1);
for i=1:numel(subs)
    z=subjectID==subs(i); yy=removecats(y(z)); cc=categories(yy);
    subLabel(i)=string(cc{1}); subFold(i)=unique(foldId(z)); subSegments(i)=sum(z);
end
writetable(table(subs,subLabel,subFold,subSegments,'VariableNames',{'SubjectID','Label','Fold','Segments'}), ...
    fullfile(cfg.resultsDir,'subject_level_folds.csv'));

% All three experiments use exactly the same held-out patients.
fprintf('\n=== BASELINE: statistics only (%d features) ===\n',numel(statIdx));
baseline=evaluate_patientwise(X,y,subjectID,statIdx,'baseline_stats',cfg,foldId);
fprintf('\n=== ABLATION: CAP only (%d features) ===\n',numel(capIdx));
caponly=evaluate_patientwise(X,y,subjectID,capIdx,'cap_only',cfg,foldId);
fprintf('\n=== PROPOSED THESIS METHOD: CAP + statistics (%d features) ===\n',size(X,2));
proposed=evaluate_patientwise(X,y,subjectID,1:size(X,2),'proposed_cap_stats',cfg,foldId);

save_outputs(baseline,'baseline',cfg); save_outputs(caponly,'cap_only',cfg); save_outputs(proposed,'proposed',cfg);
summary=[baseline.overall;caponly.overall;proposed.overall];
writetable(summary,fullfile(cfg.resultsDir,'SUMMARY.csv'));
audit_patient_leakage(subjectID,foldId,cfg);
fprintf('\nFinished. Read results/SUMMARY.csv and LEAKAGE_AUDIT.csv first.\n'); disp(summary);
end

function save_outputs(R,name,cfg)
writetable(R.foldMetrics,fullfile(cfg.resultsDir,[name '_fold_metrics.csv']));
writetable(R.predictions,fullfile(cfg.resultsDir,[name '_predictions.csv']));
writetable(R.perClass,fullfile(cfg.resultsDir,[name '_per_class.csv']));
writematrix(R.confusion,fullfile(cfg.resultsDir,[name '_confusion.csv']));
end
