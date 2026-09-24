function run_view_fusion_cap(featureFile)
%RUN_VIEW_FUSION_CAP Leakage-free learned 8-view fusion for CAP predictions.
% Learns class-specific reliability of each auscultation view (sit/sup x
% Aor/Mit/Pul/Tri) ONLY from training patients' out-of-fold segment predictions,
% then applies those weights to held-out patients. No test-label tuning.
setup; cfg=config();
if nargin<1, featureFile=fullfile('data','raw_cap_mfcc.mat'); end
S=load(featureFile,'y','subjectID','wavFile');
y=string(categorical(S.y)); sid=string(str2double(string(S.subjectID(:))));
wav=string(S.wavFile(:)); N=numel(y);
P=readtable(fullfile(cfg.resultsDir,'raw_cap_only_predictions.csv'),'TextType','string');
assert(height(P)==N,'Prediction row mismatch.');
rn=str2double(string(P.RowNumber)); [~,ord]=sort(rn);
pred=string(P.PredictedLabel(ord)); psid=string(str2double(string(P.SubjectID(ord))));
assert(all(psid==sid),'Subject mismatch.'); assert(all(string(P.TrueLabel(ord))==y),'Label mismatch.');

% Parse 8 views from WAV names.
view=strings(N,1);
for i=1:N
 tok=regexp(erase(wav(i),'.wav'),'^[^_]+_[0-9]+_(sit|sup)_(Aor|Mit|Pul|Tri)$','tokens','once');
 assert(~isempty(tok),'Bad WAV name: %s',wav(i)); view(i)=string(tok{1})+"_"+string(tok{2});
end
views=["sit_Aor","sit_Mit","sit_Pul","sit_Tri","sup_Aor","sup_Mit","sup_Pul","sup_Tri"];
cats=string(categories(categorical(y)));
foldId=make_subject_folds(sid,categorical(y),cfg.numFolds,cfg.randomSeed);
patRows=table();

for f=1:cfg.numFolds
 tr=foldId~=f; te=foldId==f;
 % Training-only class/view reliability: smoothed P(pred=c | true=c, view=v).
 W=zeros(numel(cats),numel(views));
 for c=1:numel(cats)
  for v=1:numel(views)
   z=tr & y==cats(c) & view==views(v);
   correct=sum(pred(z)==cats(c)); total=sum(z);
   W(c,v)=(correct+1)/(total+2); % Laplace smoothing
  end
 end
 % Normalize each class's view weights to mean 1.
 W=W./mean(W,2);

 testSubs=unique(sid(te));
 for s=1:numel(testSubs)
  q=testSubs(s); idx=te & sid==q; u=unique(y(idx)); assert(numel(u)==1);
  score=zeros(numel(cats),1);
  for c=1:numel(cats)
   for v=1:numel(views)
    zv=idx & view==views(v);
    % Each view contributes its fraction of segment votes for class c.
    if any(zv), score(c)=score(c)+W(c,v)*mean(pred(zv)==cats(c)); end
   end
  end
  [~,j]=max(score);
  patRows=[patRows;table(f,q,u,cats(j),'VariableNames',{'Fold','SubjectID','TrueLabel','PredictedLabel'})]; %#ok<AGROW>
 end
end

assert(height(patRows)==109 && numel(unique(patRows.SubjectID))==109,'Expected 109 unique patients.');
M=compute_metrics(categorical(patRows.TrueLabel,cats),categorical(patRows.PredictedLabel,cats));
writetable(patRows,fullfile(cfg.resultsDir,'cap_learned_view_fusion_patient_predictions.csv'));
writetable(M.perClass,fullfile(cfg.resultsDir,'cap_learned_view_fusion_patient_per_class.csv'));
writematrix(M.confusion,fullfile(cfg.resultsDir,'cap_learned_view_fusion_patient_confusion.csv'));
summary=table(M.accuracy,M.balancedAccuracy,M.macroPrecision,M.macroRecall,M.macroF1, ...
 'VariableNames',{'PatientAccuracy','PatientBalancedAccuracy','PatientMacroPrecision','PatientMacroRecall','PatientMacroF1'});
writetable(summary,fullfile(cfg.resultsDir,'CAP_LEARNED_VIEW_FUSION_SUMMARY.csv'));
fprintf('\nCAP LEARNED 8-VIEW FUSION (training-fold weights only)\n'); disp(summary);
fprintf('Baseline CAP majority-vote patient BA was 0.41506. Compare against that value.\n');
end
