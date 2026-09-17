function run_from_features(featureFile)
%RUN_FROM_FEATURES Leakage-free evaluation of the thesis's 2120-D features.
%
% Required MAT variables:
%   X         [nSegments x 2120] thesis feature matrix
%   y         [nSegments x 1] labels: N AS AR MR MS MD
%   subjectID [nSegments x 1] original patient identifier
%
% Recommended reproduction path: use the student's ORIGINAL thesis feature
% matrix so no undocumented statistical formula or reshape convention is
% silently invented. This script corrects the validation protocol only.

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
assert(all(strlength(subjectID)>0),'Empty subjectID detected.');
assert(all(isfinite(X(:))),'X contains NaN/Inf. Fix the original feature matrix first.');

expected={'N','AS','AR','MR','MS','MD'};
actual=categories(removecats(y));
assert(all(ismember(actual,expected)),'Unexpected class label detected.');
assert(numel(actual)==6,'Expected all six thesis classes; found %d.',numel(actual));

nSubjects=numel(unique(subjectID));
fprintf('Loaded %d segments, %d features, %d unique subjects.\n',size(X,1),size(X,2),nSubjects);
if nSubjects~=109
    warning('Thesis reports 109 subjects; this file contains %d. Verify subjectID before using results.',nSubjects);
end

% Each subject should have one thesis class. If not, the single-label thesis
% representation cannot be grouped safely without explicit adjudication.
subs=unique(subjectID,'stable');
for i=1:numel(subs)
    yi=removecats(y(subjectID==subs(i)));
    if numel(categories(yi))~=1
        error('Subject %s has multiple thesis labels. Verify label/subject mapping.',subs(i));
    end
end

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

% Save subject-level fold/class table for auditability.
subLabel=strings(numel(subs),1); subFold=zeros(numel(subs),1); subSegments=zeros(numel(subs),1);
for i=1:numel(subs)
    z=subjectID==subs(i); yy=removecats(y(z)); cc=categories(yy);
    subLabel(i)=string(cc{1}); subFold(i)=unique(foldId(z)); subSegments(i)=sum(z);
end
writetable(table(subs,subLabel,subFold,subSegments,'VariableNames', ...
    {'SubjectID','Label','Fold','Segments'}),fullfile(cfg.resultsDir,'subject_level_folds.csv'));

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

audit_patient_leakage(subjectID,foldId,cfg);

fprintf('\nFinished. Read results/SUMMARY.csv first.\n');
disp(summary);
end
