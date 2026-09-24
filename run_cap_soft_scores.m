function run_cap_soft_scores(featureFile)
%RUN_CAP_SOFT_SCORES Refit CAP-only patient-wise models and save held-out class scores.
% Same folds, train-only NCA/scaling/cost-sensitive training as raw CAP experiment.
setup; cfg=config();
if nargin<1, featureFile=fullfile('data','raw_cap_mfcc.mat'); end
S=load(featureFile,'Xcap','y','subjectID','wavFile');
X=double(S.Xcap); y=categorical(S.y(:)); sid=string(S.subjectID(:)); wav=string(S.wavFile(:));
N=size(X,1); assert(N==8716 && numel(y)==N && numel(sid)==N,'Row mismatch.');
foldId=make_subject_folds(sid,y,cfg.numFolds,cfg.randomSeed);
classes=categories(y); K=numel(classes); scores=nan(N,K); pred=repmat(categorical(missing,classes),N,1);

fprintf('\nCAP SCORE REFIT: same patient folds; train-only NCA/scaling/cost.\n');
for k=1:cfg.numFolds
 te=foldId==k; tr=~te;
 assert(isempty(intersect(unique(sid(tr)),unique(sid(te)))),'Patient leakage.');
 Xtr=X(tr,:); Xte=X(te,:); ytr=y(tr);
 [idx,~]=nca_select_train_only(Xtr,ytr,min(cfg.ncaFeatureCount,size(Xtr,2)));
 mu=mean(Xtr(:,idx),1,'omitnan'); sd=std(Xtr(:,idx),0,1,'omitnan'); sd(~isfinite(sd)|sd==0)=1;
 A=(Xtr(:,idx)-mu)./sd; B=(Xte(:,idx)-mu)./sd; A(~isfinite(A))=0; B(~isfinite(B))=0;
 [mdl,~]=train_subspace_knn(A,ytr,cfg);
 [pk,sk]=predict(mdl,B); pred(te)=pk;
 mc=string(mdl.ClassNames);
 for j=1:K
  q=find(mc==string(classes{j}),1); assert(~isempty(q),'Missing score class.');
  scores(te,j)=sk(:,q);
 end
 fprintf('Fold %d/%d done.\n',k,cfg.numFolds);
end
assert(all(isfinite(scores(:))),'Non-finite scores.');
T=table((1:N)',sid,foldId,string(y),string(pred),wav,'VariableNames', ...
 {'RowNumber','SubjectID','Fold','TrueLabel','PredictedLabel','WavFile'});
for j=1:K, T.("Score_"+string(classes{j}))=scores(:,j); end
writetable(T,fullfile(cfg.resultsDir,'raw_cap_only_scores.csv'));
fprintf('DONE: results/raw_cap_only_scores.csv\n');

% Leakage-free soft 8-view fusion. View reliabilities learned from training rows only.
view=parse_views(wav); views=["sit_Aor","sit_Mit","sit_Pul","sit_Tri","sup_Aor","sup_Mit","sup_Pul","sup_Tri"];
out=table();
for f=1:cfg.numFolds
 tr=foldId~=f; te=foldId==f;
 W=zeros(K,numel(views));
 % Reliability from training OOF hard predictions; Laplace-smoothed class recall per view.
 for c=1:K
  for v=1:numel(views)
   z=tr & string(y)==string(classes{c}) & view==views(v);
   W(c,v)=(sum(string(pred(z))==string(classes{c}))+1)/(sum(z)+2);
  end
 end
 W=W./mean(W,2);
 subs=unique(sid(te));
 for s=1:numel(subs)
  zsub=te & sid==subs(s); u=unique(string(y(zsub))); assert(numel(u)==1);
  total=zeros(K,1);
  for v=1:numel(views)
   z=zsub & view==views(v);
   if any(z)
    sv=mean(scores(z,:),1);
    total=total + W(:,v).*sv(:);
   end
  end
  [~,m]=max(total);
  out=[out;table(f,subs(s),u,string(classes{m}),'VariableNames',{'Fold','SubjectID','TrueLabel','PredictedLabel'})]; %#ok<AGROW>
 end
end
M=compute_metrics(categorical(out.TrueLabel,classes),categorical(out.PredictedLabel,classes));
writetable(out,fullfile(cfg.resultsDir,'cap_soft_view_fusion_patient_predictions.csv'));
writetable(M.perClass,fullfile(cfg.resultsDir,'cap_soft_view_fusion_patient_per_class.csv'));
writematrix(M.confusion,fullfile(cfg.resultsDir,'cap_soft_view_fusion_patient_confusion.csv'));
R=table(M.accuracy,M.balancedAccuracy,M.macroPrecision,M.macroRecall,M.macroF1, ...
 'VariableNames',{'PatientAccuracy','PatientBalancedAccuracy','PatientMacroPrecision','PatientMacroRecall','PatientMacroF1'});
writetable(R,fullfile(cfg.resultsDir,'CAP_SOFT_VIEW_FUSION_SUMMARY.csv'));
fprintf('\nCAP SOFT 8-VIEW FUSION\n'); disp(R);
fprintf('Compare PatientBalancedAccuracy with hard learned-view baseline 0.45104.\n');
end

function view=parse_views(wav)
view=strings(numel(wav),1);
for i=1:numel(wav)
 tok=regexp(erase(wav(i),'.wav'),'^[^_]+_[0-9]+_(sit|sup)_(Aor|Mit|Pul|Tri)$','tokens','once');
 assert(~isempty(tok),'Bad WAV name: %s',wav(i));
 view(i)=string(tok{1})+"_"+string(tok{2});
end
end
