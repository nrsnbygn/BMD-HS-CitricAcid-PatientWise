function run_nested_class_view_fusion(scoreFile)
%RUN_NESTED_CLASS_VIEW_FUSION Leakage-safe class-specific view weighting.
% Uses existing OOF CAP scores. For each outer fold, view x class weights
% are estimated ONLY from the other folds, then applied to held-out subjects.
% No final-fold labels are used to choose weights.
setup; cfg=config();
if nargin<1, scoreFile=fullfile(cfg.resultsDir,'raw_cap_only_scores.csv'); end
T=readtable(scoreFile,'TextType','string');

req=["SubjectID","Fold","TrueLabel","WavFile"];
assert(all(ismember(req,string(T.Properties.VariableNames))),'Missing required columns.');
scoreVars=string(T.Properties.VariableNames(startsWith(T.Properties.VariableNames,'Score_')));
assert(~isempty(scoreVars),'No Score_* columns found.');
classes=erase(scoreVars,'Score_'); K=numel(classes);
sid=normalize_id(T.SubjectID); wav=string(T.WavFile); view=parse_views(wav);
trueY=string(T.TrueLabel); fold=T.Fold;
views=["sit_Aor","sit_Mit","sit_Pul","sit_Tri","sup_Aor","sup_Mit","sup_Pul","sup_Tri"];
V=numel(views); S=T{:,cellstr(scoreVars)};

uF=unique(fold(:))'; predSub=strings(0,1); trueSub=strings(0,1); idSub=strings(0,1); foldSub=[];
weightRows=table();

for f=uF
 tr=fold~=f; te=fold==f;

 % Class-specific view reliability learned from OUTER-TRAINING folds only.
 W=zeros(V,K);
 for c=1:K
  for v=1:V
   z=tr & trueY==classes(c) & view==views(v);
   if any(z), W(v,c)=mean(S(z,c),'omitnan'); else, W(v,c)=0; end
  end
  % Conservative shrinkage toward equal weights to reduce small-sample overfit.
  m=mean(W(:,c),'omitnan');
  if ~isfinite(m) || m<=0, W(:,c)=1/V; else
   rel=max(W(:,c),eps)/m;
   alpha=0.5; rel=(1-alpha)*ones(V,1)+alpha*rel;
   W(:,c)=rel/sum(rel);
  end
 end

 % Save fold-specific learned weights for auditability.
 for c=1:K
  for v=1:V
   weightRows=[weightRows;table(f,classes(c),views(v),W(v,c), ...
    'VariableNames',{'Fold','Class','View','Weight'})]; %#ok<AGROW>
  end
 end

 % Fuse all segment scores within each subject, using class-specific view weights.
 ids=unique(sid(te),'stable');
 for q=1:numel(ids)
  z=te & sid==ids(q);
  F=zeros(1,K); den=zeros(1,K);
  idx=find(z);
  for ii=1:numel(idx)
   vi=find(views==view(idx(ii)),1);
   if isempty(vi), continue; end
   F=F + S(idx(ii),:).*W(vi,:);
   den=den + W(vi,:);
  end
  F=F./max(den,eps);
  [~,j]=max(F);
  yy=unique(trueY(z));
  assert(numel(yy)==1,'Multiple true labels for subject %s.',ids(q));
  idSub(end+1,1)=ids(q); trueSub(end+1,1)=yy; predSub(end+1,1)=classes(j); foldSub(end+1,1)=f; %#ok<AGROW>
 end
end

M=metrics6(trueSub,predSub,classes);
Summary=table(M.Accuracy,M.BalancedAccuracy,M.MacroPrecision,M.MacroRecall,M.MacroF1, ...
 'VariableNames',{'PatientAccuracy','PatientBalancedAccuracy','PatientMacroPrecision','PatientMacroRecall','PatientMacroF1'});
disp('NESTED CLASS-SPECIFIC VIEW FUSION (outer-training weights only)'); disp(Summary);
fprintf('Reference CAP soft 8-view BA: 0.47137; MacroF1: 0.41001.\n');

Pred=table(idSub,foldSub,trueSub,predSub,'VariableNames',{'SubjectID','Fold','TrueLabel','PredictedLabel'});
writetable(Pred,fullfile(cfg.resultsDir,'nested_class_view_fusion_predictions.csv'));
writetable(weightRows,fullfile(cfg.resultsDir,'nested_class_view_weights.csv'));
writetable(Summary,fullfile(cfg.resultsDir,'NESTED_CLASS_VIEW_FUSION_SUMMARY.csv'));
fprintf('Saved nested predictions, fold-specific weights, and summary in results/.\n');
end

function M=metrics6(y,p,classes)
C=confusionmat(categorical(y,classes),categorical(p,classes),'Order',categorical(classes,classes));
tp=diag(C); rec=tp./max(sum(C,2),1); prec=tp./max(sum(C,1)',1);
f1=2*prec.*rec./max(prec+rec,eps);
M.Accuracy=sum(tp)/sum(C,'all'); M.BalancedAccuracy=mean(rec);
M.MacroPrecision=mean(prec); M.MacroRecall=mean(rec); M.MacroF1=mean(f1);
end

function s=normalize_id(x)
s=string(x); s=regexprep(s,'^.*?([0-9]+)$','$1');
n=str2double(s); ok=~isnan(n); s(ok)=compose('%03d',n(ok));
end

function view=parse_views(wav)
wav=string(wav); view=strings(numel(wav),1);
for i=1:numel(wav)
 tok=regexp(erase(wav(i),'.wav'),'^[^_]+_[0-9]+_(sit|sup)_(Aor|Mit|Pul|Tri)$','tokens','once');
 assert(~isempty(tok),'Bad WAV name: %s',wav(i));
 view(i)=string(tok{1})+"_"+string(tok{2});
end
end
