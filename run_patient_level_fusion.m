function run_patient_level_fusion(featureFile)
%RUN_PATIENT_LEVEL_FUSION Aggregate held-out segment predictions to subjects.
% Uses ONLY out-of-fold predictions already produced by run_raw_cap_mfcc.
% No retraining and no leakage. Majority vote is performed first within each
% WAV recording, then across the 8 recording votes of each subject.
setup; cfg=config();
if nargin<1, featureFile=fullfile('data','raw_cap_mfcc.mat'); end
assert(isfile(featureFile),'Missing %s.',featureFile);
S=load(featureFile,'y','subjectID','wavFile','segmentInFile');
trueSeg=string(categorical(S.y)); sid=norm_id(S.subjectID); wav=string(S.wavFile(:));
assert(numel(sid)==8716 && numel(wav)==8716,'Expected 8716 rows.');

pipes=["raw_cap_only","raw_mfcc_only","raw_cap_mfcc"];
allSummary=table();
for p=1:numel(pipes)
 name=pipes(p);
 predFile=fullfile(cfg.resultsDir,name+"_predictions.csv");
 assert(isfile(predFile),'Missing %s. Run run_raw_cap_mfcc first.',predFile);
 P=readtable(predFile,'TextType','string');
 assert(height(P)==numel(sid),'Prediction row mismatch for %s.',name);
 predSeg=string(P.PredictedLabel);
 assert(all(string(P.SubjectID)==sid),'Subject row mismatch for %s.',name);
 assert(all(string(P.TrueLabel)==trueSeg),'True-label row mismatch for %s.',name);

 % Recording-level majority vote (deterministic tie break by global category order).
 cats=string(categories(categorical(trueSeg)));
 [G,wavNames]=findgroups(wav);
 nRec=max(G); recPred=strings(nRec,1); recTrue=strings(nRec,1); recSub=strings(nRec,1);
 for g=1:nRec
  idx=G==g; recPred(g)=majority_vote(predSeg(idx),cats);
  u=unique(trueSeg(idx)); assert(numel(u)==1,'Multiple true labels in WAV %s.',wavNames(g)); recTrue(g)=u;
  us=unique(sid(idx)); assert(numel(us)==1,'Multiple subjects in WAV %s.',wavNames(g)); recSub(g)=us;
 end
 recM=compute_metrics(categorical(recTrue,cats),categorical(recPred,cats));
 recT=table(wavNames,recSub,recTrue,recPred,'VariableNames',{'WavFile','SubjectID','TrueLabel','PredictedLabel'});
 writetable(recT,fullfile(cfg.resultsDir,name+"_recording_predictions.csv"));
 writematrix(recM.confusion,fullfile(cfg.resultsDir,name+"_recording_confusion.csv"));

 % Patient-level majority vote across recording votes.
 [H,subNames]=findgroups(recSub); nSub=max(H);
 patPred=strings(nSub,1); patTrue=strings(nSub,1); nRecordings=zeros(nSub,1);
 for h=1:nSub
  idx=H==h; nRecordings(h)=sum(idx); patPred(h)=majority_vote(recPred(idx),cats);
  u=unique(recTrue(idx)); assert(numel(u)==1,'Multiple true labels for subject %s.',subNames(h)); patTrue(h)=u;
 end
 assert(nSub==109,'Expected 109 subjects; got %d.',nSub);
 patM=compute_metrics(categorical(patTrue,cats),categorical(patPred,cats));
 patT=table(subNames,nRecordings,patTrue,patPred,'VariableNames',{'SubjectID','NRecordings','TrueLabel','PredictedLabel'});
 writetable(patT,fullfile(cfg.resultsDir,name+"_patient_predictions.csv"));
 writetable(patM.perClass,fullfile(cfg.resultsDir,name+"_patient_per_class.csv"));
 writematrix(patM.confusion,fullfile(cfg.resultsDir,name+"_patient_confusion.csv"));

 one=table(name,recM.accuracy,recM.balancedAccuracy,recM.macroF1, ...
  patM.accuracy,patM.balancedAccuracy,patM.macroPrecision,patM.macroRecall,patM.macroF1, ...
  'VariableNames',{'Pipeline','RecordingAccuracy','RecordingBalancedAccuracy','RecordingMacroF1', ...
  'PatientAccuracy','PatientBalancedAccuracy','PatientMacroPrecision','PatientMacroRecall','PatientMacroF1'});
 allSummary=[allSummary;one]; %#ok<AGROW>
end
writetable(allSummary,fullfile(cfg.resultsDir,'PATIENT_LEVEL_FUSION_SUMMARY.csv'));
fprintf('\nPATIENT-LEVEL FUSION (OOF majority vote)\n'); disp(allSummary);
fprintf('All patient predictions come only from held-out folds; no patient leakage introduced.\n');
end

function out=majority_vote(labels,cats)
labels=string(labels(:)); counts=zeros(numel(cats),1);
for i=1:numel(cats), counts(i)=sum(labels==cats(i)); end
[~,j]=max(counts); out=cats(j);
end
