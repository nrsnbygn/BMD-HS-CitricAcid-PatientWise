function run_raw_cap_mfcc(featureFile)
%RUN_RAW_CAP_MFCC Compare CAP-only, MFCC-only and CAP+MFCC on identical patient folds.
% NCA, scaling and class costs are learned from TRAINING folds only.
setup; cfg=config();
if nargin<1, featureFile=fullfile('data','raw_cap_mfcc.mat'); end
assert(isfile(featureFile),'Missing %s. Run build_raw_cap_mfcc first.',featureFile);
S=load(featureFile);
Xcap=double(S.Xcap); Xmfcc=double(S.Xmfcc); y=categorical(S.y); subjectID=string(S.subjectID);
assert(size(Xcap,1)==8716 && size(Xmfcc,1)==8716,'Expected 8716 rows.');
assert(size(Xcap,1)==numel(y)&&numel(y)==numel(subjectID),'Row mismatch.');
assert(all(isfinite(Xcap(:)))&&all(isfinite(Xmfcc(:))),'Non-finite features found.');

foldId=make_subject_folds(subjectID,y,cfg.numFolds,cfg.randomSeed);
fprintf('\nRAW PATIENT-WISE EXPERIMENT\n');
fprintf('Same 8716 raw-derived segments and same patient folds for all pipelines.\n');
fprintf('Train-only NCA/scaling/cost-sensitive learning.\n');
cap=evaluate_patientwise(Xcap,y,subjectID,1:size(Xcap,2),'raw_cap_only',cfg,foldId);
mfccR=evaluate_patientwise(Xmfcc,y,subjectID,1:size(Xmfcc,2),'raw_mfcc_only',cfg,foldId);
Xboth=[Xcap Xmfcc];
both=evaluate_patientwise(Xboth,y,subjectID,1:size(Xboth,2),'raw_cap_mfcc',cfg,foldId);

save_outputs(cap,'raw_cap_only',cfg); save_outputs(mfccR,'raw_mfcc_only',cfg); save_outputs(both,'raw_cap_mfcc',cfg);
summary=[cap.overall;mfccR.overall;both.overall];
writetable(summary,fullfile(cfg.resultsDir,'RAW_CAP_MFCC_SUMMARY.csv'));
audit_patient_leakage(subjectID,foldId,cfg);
fprintf('\nFinished raw CAP/MFCC experiment.\n'); disp(summary);
end

function save_outputs(R,name,cfg)
writetable(R.foldMetrics,fullfile(cfg.resultsDir,[name '_fold_metrics.csv']));
writetable(R.predictions,fullfile(cfg.resultsDir,[name '_predictions.csv']));
writetable(R.perClass,fullfile(cfg.resultsDir,[name '_per_class.csv']));
writematrix(R.confusion,fullfile(cfg.resultsDir,[name '_confusion.csv']));
end
