function summary = evaluate_patientwise(X,y,subjectID,featureIdx,pipelineName,cfg,foldId)
%EVALUATE_PATIENTWISE Patient-grouped CV; train-only NCA, scaling and balancing.

X=double(X(:,featureIdx)); y=categorical(y(:)); subjectID=string(subjectID(:));
N=size(X,1);
if nargin<7 || isempty(foldId)
    foldId=make_subject_folds(subjectID,y,cfg.numFolds,cfg.randomSeed);
end
pred=repmat(categorical(missing,categories(y)),N,1);
rows=[]; selected=cell(cfg.numFolds,1);

for k=1:cfg.numFolds
    te=foldId==k; tr=~te;
    overlap=intersect(unique(subjectID(tr)),unique(subjectID(te)));
    assert(isempty(overlap),'Patient leakage in fold %d.',k);

    Xtr=X(tr,:); Xte=X(te,:); ytr=y(tr);
    nKeep=min(cfg.ncaFeatureCount,size(Xtr,2));
    [localIdx,weights]=nca_select_train_only(Xtr,ytr,nKeep);
    selected{k}=featureIdx(localIdx);

    % Train-only scaling.
    mu=mean(Xtr(:,localIdx),1,'omitnan');
    sd=std(Xtr(:,localIdx),0,1,'omitnan'); sd(~isfinite(sd)|sd==0)=1;
    A=(Xtr(:,localIdx)-mu)./sd; B=(Xte(:,localIdx)-mu)./sd;
    A(~isfinite(A))=0; B(~isfinite(B))=0;

    % IMPORTANT: balance training rows only. Test patients are untouched.
    [Afit,yfit,balanceInfo]=balance_training_only(A,ytr,cfg,k);
    mdl=train_subspace_knn(Afit,yfit,cfg);
    pred(te)=predict(mdl,B);

    m=compute_metrics(y(te),pred(te));
    rows=[rows; table(k,sum(tr),sum(te),numel(unique(subjectID(tr))), ...
        numel(unique(subjectID(te))),size(Afit,1),m.accuracy,m.balancedAccuracy,m.macroF1, ...
        'VariableNames',{'Fold','NTrain','NTest','TrainSubjects','TestSubjects', ...
        'NTrainAfterBalance','Accuracy','BalancedAccuracy','MacroF1'})]; %#ok<AGROW>
    save(fullfile(cfg.resultsDir,sprintf('%s_fold%02d_nca.mat',pipelineName,k)), ...
        'localIdx','weights','mu','sd','balanceInfo');
end

allM=compute_metrics(y,pred);
summary.foldMetrics=rows;
summary.predictions=table((1:N)',subjectID,foldId,string(y),string(pred), ...
    'VariableNames',{'Row','SubjectID','Fold','TrueLabel','PredictedLabel'});
summary.overall=table(string(pipelineName),allM.accuracy,allM.balancedAccuracy, ...
    allM.macroPrecision,allM.macroRecall,allM.macroF1, ...
    'VariableNames',{'Pipeline','Accuracy','BalancedAccuracy','MacroPrecision','MacroRecall','MacroF1'});
summary.perClass=allM.perClass; summary.confusion=allM.confusion;
summary.classes=allM.classes; summary.selectedOriginalFeatureIndices=selected;
end
