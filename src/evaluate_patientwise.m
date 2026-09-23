function summary = evaluate_patientwise(X,y,subjectID,featureIdx,pipelineName,cfg,foldId)
%EVALUATE_PATIENTWISE Patient-grouped CV; train-only NCA, scaling and cost.
X=double(X(:,featureIdx)); y=categorical(y(:)); subjectID=string(subjectID(:)); N=size(X,1);
if nargin<7||isempty(foldId), foldId=make_subject_folds(subjectID,y,cfg.numFolds,cfg.randomSeed); end
pred=repmat(categorical(missing,categories(y)),N,1); rows=[]; selected=cell(cfg.numFolds,1);
for k=1:cfg.numFolds
 te=foldId==k; tr=~te;
 assert(isempty(intersect(unique(subjectID(tr)),unique(subjectID(te)))),'Patient leakage in fold %d.',k);
 Xtr=X(tr,:); Xte=X(te,:); ytr=y(tr);
 nKeep=min(cfg.ncaFeatureCount,size(Xtr,2));
 [localIdx,weights]=nca_select_train_only(Xtr,ytr,nKeep); selected{k}=featureIdx(localIdx);
 mu=mean(Xtr(:,localIdx),1,'omitnan'); sd=std(Xtr(:,localIdx),0,1,'omitnan'); sd(~isfinite(sd)|sd==0)=1;
 A=(Xtr(:,localIdx)-mu)./sd; B=(Xte(:,localIdx)-mu)./sd; A(~isfinite(A))=0; B(~isfinite(B))=0;
 [mdl,costInfo]=train_subspace_knn(A,ytr,cfg); pred(te)=predict(mdl,B);
 m=compute_metrics(y(te),pred(te));
 rows=[rows;table(k,sum(tr),sum(te),numel(unique(subjectID(tr))),numel(unique(subjectID(te))), ...
  m.accuracy,m.balancedAccuracy,m.macroF1,'VariableNames', ...
  {'Fold','NTrain','NTest','TrainSubjects','TestSubjects','Accuracy','BalancedAccuracy','MacroF1'})]; %#ok<AGROW>
 save(fullfile(cfg.resultsDir,sprintf('%s_fold%02d_nca.mat',pipelineName,k)), ...
  'localIdx','weights','mu','sd','costInfo');
end
allM=compute_metrics(y,pred); summary.foldMetrics=rows;
rowNumber=(1:N)'; trueLabel=string(y); predictedLabel=string(pred);
summary.predictions=table(rowNumber,subjectID,foldId,trueLabel,predictedLabel, ...
 'VariableNames',{'RowNumber','SubjectID','Fold','TrueLabel','PredictedLabel'});
summary.overall=table(string(pipelineName),allM.accuracy,allM.balancedAccuracy, ...
 allM.macroPrecision,allM.macroRecall,allM.macroF1, ...
 'VariableNames',{'Pipeline','Accuracy','BalancedAccuracy','MacroPrecision','MacroRecall','MacroF1'});
summary.perClass=allM.perClass; summary.confusion=allM.confusion; summary.classes=allM.classes;
summary.selectedOriginalFeatureIndices=selected;
end
