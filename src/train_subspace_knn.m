function [mdl,costInfo] = train_subspace_knn(Xtrain,ytrain,cfg)
%TRAIN_SUBSPACE_KNN Random-subspace KNN with optional train-only cost matrix.
ytrain=categorical(ytrain); classes=categories(ytrain);
p=size(Xtrain,2);
switch lower(cfg.ensemble.SubspaceDimensionRule)
    case 'sqrt', nPred=max(1,min(p,round(sqrt(p))));
    otherwise, error('Unknown SubspaceDimensionRule.');
end
t=templateKNN('NumNeighbors',cfg.knn.NumNeighbors,'Distance',cfg.knn.Distance, ...
    'DistanceWeight',cfg.knn.DistanceWeight,'Standardize',false);

counts=countcats(ytrain);
costInfo=table(string(classes),counts,'VariableNames',{'Class','TrainCount'});
args={'Method','Subspace','Learners',t,'NumLearningCycles',cfg.ensemble.NumLearningCycles, ...
    'NPredToSample',nPred,'ClassNames',classes};

if isfield(cfg,'imbalance') && strcmpi(cfg.imbalance.method,'cost_sensitive')
    w=(sum(counts)./(numel(counts)*counts)).^cfg.imbalance.power;
    w=w/mean(w);
    C=repmat(w(:),1,numel(classes)); C(1:numel(classes)+1:end)=0;
    costInfo.ClassWeight=w;
    mdl=fitcensemble(Xtrain,ytrain,args{:},'Cost',C);
else
    costInfo.ClassWeight=ones(numel(classes),1);
    mdl=fitcensemble(Xtrain,ytrain,args{:});
end
end
