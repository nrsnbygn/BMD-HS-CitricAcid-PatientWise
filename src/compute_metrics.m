function M = compute_metrics(yTrue,yPred)
%COMPUTE_METRICS Overall accuracy, balanced accuracy and macro metrics.
yTrue=categorical(yTrue); yPred=categorical(yPred,categories(yTrue));
classes=categories(yTrue);
C=confusionmat(yTrue,yPred,'Order',categorical(classes,classes));
K=numel(classes);
prec=nan(K,1); rec=nan(K,1); spec=nan(K,1); f1=nan(K,1);
for i=1:K
    TP=C(i,i); FN=sum(C(i,:))-TP; FP=sum(C(:,i))-TP;
    TN=sum(C(:))-TP-FN-FP;
    prec(i)=safe(TP,TP+FP);
    rec(i)=safe(TP,TP+FN);
    spec(i)=safe(TN,TN+FP);
    f1(i)=safe(2*prec(i)*rec(i),prec(i)+rec(i));
end
M.accuracy=sum(diag(C))/sum(C(:));
M.balancedAccuracy=mean(rec,'omitnan');
M.macroPrecision=mean(prec,'omitnan');
M.macroRecall=mean(rec,'omitnan');
M.macroF1=mean(f1,'omitnan');
M.classes=classes; M.confusion=C;
M.perClass=table(string(classes),prec,rec,spec,f1,'VariableNames', ...
    {'Class','Precision','Recall','Specificity','F1'});
end
function z=safe(a,b)
if b==0, z=NaN; else, z=a/b; end
end
