function [Xb,yb,info] = balance_training_only(X,y,cfg,foldNumber)
%BALANCE_TRAINING_ONLY Random undersampling of TRAINING rows only.
% Test/validation rows must never be passed to this function.

y=categorical(y(:)); X=double(X);
classes=categories(y);
before=countcats(y);
info=table(string(classes),before,'VariableNames',{'Class','Before'});

if ~isfield(cfg,'balance') || ~cfg.balance.enabled
    Xb=X; yb=y; info.After=before; return;
end
if ~strcmpi(cfg.balance.method,'random_undersample')
    error('Unsupported balance method: %s',cfg.balance.method);
end

target=min(before(before>0));
assert(~isempty(target) && target>0,'A training fold is missing a class.');
rng(cfg.balance.seed + foldNumber - 1,'twister');
keep=[];
for i=1:numel(classes)
    ids=find(y==classes{i});
    assert(numel(ids)>=target,'Unexpected class count.');
    ids=ids(randperm(numel(ids),target));
    keep=[keep;ids(:)]; %#ok<AGROW>
end
keep=keep(randperm(numel(keep)));
Xb=X(keep,:); yb=y(keep);
after=countcats(categorical(yb,classes));
info.After=after;
assert(numel(unique(keep))==numel(keep),'Duplicate training rows created.');
assert(all(after==target),'Training balancing failed.');
end
