function [idx, weights] = nca_select_train_only(Xtrain, ytrain, nKeep)
%NCA_SELECT_TRAIN_ONLY Supervised feature selection using training data only.
% IMPORTANT: Never call this function with test rows included.

Xtrain = double(Xtrain);
ytrain = categorical(ytrain);
% Standardisation is learned on train only for numerical stability.
mu = mean(Xtrain,1,'omitnan');
sigma = std(Xtrain,0,1,'omitnan');
sigma(~isfinite(sigma) | sigma==0)=1;
Xs=(Xtrain-mu)./sigma;
Xs(~isfinite(Xs))=0;

mdl = fscnca(Xs,ytrain,'Verbose',0);
weights = mdl.FeatureWeights(:);
[~,order]=sort(weights,'descend');
nKeep=min(nKeep,numel(order));
idx=order(1:nKeep);
end
