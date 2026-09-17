function run_from_features(featureFile)
%RUN_FROM_FEATURES Leakage-free evaluation of the thesis's 2120-D features.
%
% Required MAT variables:
%   X         [nSegments x 2120] thesis feature matrix
%   y         [nSegments x 1] labels: N AS AR MR MS MD
%   subjectID [nSegments x 1] original patient identifier
%
% This is the recommended reproduction path because V7 specifies the 2120-D
% feature layout but does not list every one of the 40 statistical formulas
% or the 12 graph-edge coordinates numerically. Using the student's original
% feature extractor avoids silently inventing missing method details.

setup;
cfg=config();
if nargin<1, featureFile=fullfile('data','features_2120.mat'); end
assert(isfile(featureFile),'Missing %s',featureFile);
S=load(featureFile);
req={'X','y','subjectID'};
for i=1:numel(req), assert(isfield(S,req{i}),'MAT file needs variable %s.',req{i}); end
X=double(S.X); y=categorical(S.y); subjectID=string(S.subjectID);
assert(size(X,1)==numel(y) && numel(y)==numel(subjectID),'Row counts disagree.');
assert(size(X,2)==2120,'Expected exactly 2120 thesis features; got %d.',size(X,2));
assert(numel(unique(subjectID))>1,'subjectID is invalid.');

allowed=categorical({'N','AS','AR','MR','MS','MD'});
assert(all(ismember(categories(removecats(y)),categories(allowed))),'Unexpected class label.');

% Feature layout per thesis: five components x [384 CAP, 40 statistics].
capIdx=[]; statIdx=[];
for b=0:4
    base=b*424;
    capIdx=[capIdx, base+(1:384)]; %#ok<AGROW>
    statIdx=[statIdx, base+(385:424)]; %#ok<AGROW>
end
assert(numel(capIdx)==1920 && numel(statIdx)==200);

foldId=make_subject_folds(subjectID,y,cfg.numFolds,cfg.randomSeed);
writetable(table((1:numel(y))',subjectID,string(y),foldId, ...
    'VariableNames',{'Row','SubjectID','Label','Fold'}), ...
    fullfile(cfg.resultsDir,'patientwise_fold_assignment.csv'));

fprintf('\n=== BASELINE: statistical features only (%d raw features) ===\n',numel(statIdx));
baseline=evaluate_patientwise(X,y,subjectID,statIdx,'baseline_stats',cfg,foldId);

fprintf('\n=== PROPOSED: CAP + statistical features (%d raw features) ===\n',size(X,2));
proposed=evaluate_patientwise(X,y,subjectID,1:size(X,2),'proposed_cap_stats',cfg,foldId);

writetable(baseline.foldMetrics,fullfile(cfg.resultsDir,'baseline_fold_metrics.csv'));
writetable(proposed.foldMetrics,fullfile(cfg.resultsDir,'proposed_fold_metrics.csv'));
writetable(baseline.predictions,fullfile(cfg.resultsDir,'baseline_predictions.csv'));
writetable(proposed.predictions,fullfile(cfg.resultsDir,'proposed_predictions.csv'));
writetable(baseline.perClass,fullfile(cfg.resultsDir,'baseline_per_class.csv'));
writetable(proposed.perClass,fullfile(cfg.resultsDir,'proposed_per_class.csv'));
summary=[baseline.overall; proposed.overall];
writetable(summary,fullfile(cfg.resultsDir,'SUMMARY.csv'));
writematrix(baseline.confusion,fullfile(cfg.resultsDir,'baseline_confusion.csv'));
writematrix(proposed.confusion,fullfile(cfg.resultsDir,'proposed_confusion.csv'));

% Explicit leakage audit.
audit_patient_leakage(subjectID,foldId,cfg);

fprintf('\nFinished. Read results/SUMMARY.csv first.\n');
disp(summary);
end
