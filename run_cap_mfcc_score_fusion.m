function run_cap_mfcc_score_fusion(featureFile)
%RUN_CAP_MFCC_SCORE_FUSION Leakage-safe late fusion of CAP and MFCC.
% CAP scores are reused from the saved OOF file. MFCC is refit with the same
% patient folds and train-only NCA/scaling/cost-sensitive classifier.
% Fusion weight is selected INSIDE each outer-training partition using only
% OOF predictions from the other folds; held-out fold labels never tune it.
setup; cfg=config();
if nargin<1, featureFile=fullfile('data','raw_cap_mfcc.mat'); end
S=load(featureFile,'Xmfcc','y','subjectID','wavFile');
X=double(S.Xmfcc); y=categorical(S.y(:)); sid=string(S.subjectID(:)); wav=string(S.wavFile(:));
N=size(X,1); classes=categories(y); K=numel(classes);
foldId=make_subject_folds(sid,y,cfg.numFolds,cfg.randomSeed);

capFile=fullfile(cfg.resultsDir,'raw_cap_only_scores.csv');
assert(isfile(capFile),'Run run_cap_soft_scores first.');
C=readtable(capFile,'TextType','string');
assert(height(C)==N,'CAP score row mismatch.');
assert(all(string(C.SubjectID)==sid) && all(C.Fold==foldId) && all(string(C.TrueLabel)==string(y)), ...
 'CAP score alignment mismatch.');
capScores=zeros(N,K);
for j=1:K
 vn="Score_"+string(classes{j}); assert(ismember(vn,string(C.Properties.VariableNames)),'Missing %s',vn);
 capScores(:,j)=C{:,char(vn)};
end

mfccScores=nan(N,K); mfccPred=repmat(categorical(missing,classes),N,1);
fprintf('\nMFCC SCORE REFIT: same patient folds; train-only NCA/scaling/cost.\n');
for k=1:cfg.numFolds
 te=foldId==k; tr=~te; Xtr=X(tr,:); Xte=X(te,:); ytr=y(tr);
 assert(isempty(intersect(unique(sid(tr)),unique(sid(te)))),'Patient leakage.');
 [idx,~]=nca_select_train_only(Xtr,ytr,min(cfg.ncaFeatureCount,size(Xtr,2)));
 mu=mean(Xtr(:,idx),1,'omitnan'); sd=std(Xtr(:,idx),0,1,'omitnan'); sd(~isfinite(sd)|sd==0)=1;
 A=(Xtr(:,idx)-mu)./sd; B=(Xte(:,idx)-mu)./sd; A(~isfinite(A))=0; B(~isfinite(B))=0;
 [mdl,~]=train_subspace_knn(A,ytr,cfg); [pk,sk]=predict(mdl,B); mfccPred(te)=pk;
 mc=string(mdl.ClassNames);
 for j=1:K
  q=find(mc==string(classes{j}),1); assert(~isempty(q),'Missing score class.');
  mfccScores(te,j)=sk(:,q);
 end
 fprintf('MFCC fold %d/%d done.\n',k,cfg.numFolds);
end
assert(all(isfinite(mfccScores(:))),'Non-finite MFCC scores.');

% Normalize classifier score rows before cross-model fusion.
A=normrows(capScores); B=normrows(mfccScores);
alphas=0:0.1:1; out=table(); weightLog=table();
view=parse_views(wav);

for f=1:cfg.numFolds
 tr=foldId~=f; te=foldId==f;
 % Select CAP weight using only subjects outside the held-out outer fold.
 ba=zeros(numel(alphas),1);
 for a=1:numel(alphas)
  F=alphas(a)*A(tr,:)+(1-alphas(a))*B(tr,:);
  [~,m]=max(F,[],2); pp=string(classes(m));
  [ts,ps]=subject_soft_vote(sid(tr),string(y(tr)),view(tr),F,pp,classes);
  M=compute_metrics(categorical(ts,classes),categorical(ps,classes));
  ba(a)=M.balancedAccuracy;
 end
 best=max(ba); cand=find(abs(ba-best)<1e-12);
 [~,q]=min(abs(alphas(cand)-0.5)); ia=cand(q); alpha=alphas(ia);
 weightLog=[weightLog;table(f,alpha,best,'VariableNames',{'Fold','CAPWeight','TrainingBalancedAccuracy'})]; %#ok<AGROW>

 F=alpha*A(te,:)+(1-alpha)*B(te,:);
 [~,m]=max(F,[],2); pp=string(classes(m));
 [ts,ps,ids]=subject_soft_vote(sid(te),string(y(te)),view(te),F,pp,classes);
 out=[out;table(repmat(f,numel(ids),1),ids,ts,ps,'VariableNames',{'Fold','SubjectID','TrueLabel','PredictedLabel'})]; %#ok<AGROW>
 fprintf('Fusion fold %d/%d: training-selected CAP weight %.1f\n',f,cfg.numFolds,alpha);
end

M=compute_metrics(categorical(out.TrueLabel,classes),categorical(out.PredictedLabel,classes));
R=table(M.accuracy,M.balancedAccuracy,M.macroPrecision,M.macroRecall,M.macroF1, ...
 'VariableNames',{'PatientAccuracy','PatientBalancedAccuracy','PatientMacroPrecision','PatientMacroRecall','PatientMacroF1'});
writetable(R,fullfile(cfg.resultsDir,'CAP_MFCC_SCORE_FUSION_SUMMARY.csv'));
writetable(out,fullfile(cfg.resultsDir,'cap_mfcc_score_fusion_patient_predictions.csv'));
writetable(weightLog,fullfile(cfg.resultsDir,'cap_mfcc_score_fusion_weights.csv'));
fprintf('\nCAP + MFCC NESTED SCORE FUSION\n'); disp(R);
fprintf('Reference CAP soft 8-view BA: 0.47137; MacroF1: 0.41001.\n');
end

function X=normrows(X)
X=max(X,0); d=sum(X,2); d(~isfinite(d)|d<=0)=1; X=X./d;
end

function [trueS,predS,ids]=subject_soft_vote(sid,y,view,F,~,classes)
ids=unique(sid,'stable'); trueS=strings(numel(ids),1); predS=strings(numel(ids),1);
for s=1:numel(ids)
 z=sid==ids(s); u=unique(y(z)); assert(numel(u)==1); trueS(s)=u;
 total=zeros(1,numel(classes)); vv=unique(view(z));
 for k=1:numel(vv), total=total+mean(F(z & view==vv(k),:),1); end
 [~,m]=max(total); predS(s)=string(classes{m});
end
end

function view=parse_views(wav)
view=strings(numel(wav),1);
for i=1:numel(wav)
 tok=regexp(erase(wav(i),'.wav'),'^[^_]+_[0-9]+_(sit|sup)_(Aor|Mit|Pul|Tri)$','tokens','once');
 assert(~isempty(tok),'Bad WAV name: %s',wav(i)); view(i)=string(tok{1})+"_"+string(tok{2});
end
end
