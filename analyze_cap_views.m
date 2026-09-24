function analyze_cap_views(scoreFile)
%ANALYZE_CAP_VIEWS Training-safe descriptive view analysis from OOF CAP scores.
% Reports per-view/per-class recall and mean true-class score using ONLY
% already held-out predictions. This is analysis, not test-set tuning.
setup; cfg=config();
if nargin<1, scoreFile=fullfile(cfg.resultsDir,'raw_cap_only_scores.csv'); end
T=readtable(scoreFile,'TextType','string');
req=["SubjectID","Fold","TrueLabel","PredictedLabel","WavFile"];
assert(all(ismember(req,string(T.Properties.VariableNames))),'Missing required columns.');
scoreVars=string(T.Properties.VariableNames(startsWith(T.Properties.VariableNames,'Score_')));
assert(~isempty(scoreVars),'No Score_* columns found.');
classes=erase(scoreVars,'Score_'); K=numel(classes);
view=parse_views(T.WavFile);
views=["sit_Aor","sit_Mit","sit_Pul","sit_Tri","sup_Aor","sup_Mit","sup_Pul","sup_Tri"];

R=table();
for c=1:K
 for v=1:numel(views)
  z=string(T.TrueLabel)==classes(c) & view==views(v);
  n=sum(z);
  hardRecall=mean(string(T.PredictedLabel(z))==classes(c));
  sc=T{z,char(scoreVars(c))};
  meanTrueScore=mean(sc,'omitnan');
  R=[R;table(classes(c),views(v),n,hardRecall,meanTrueScore, ...
   'VariableNames',{'Class','View','NSegments','HardRecall','MeanTrueClassScore'})]; %#ok<AGROW>
 end
end
writetable(R,fullfile(cfg.resultsDir,'CAP_VIEW_CLASS_ANALYSIS.csv'));

% Rank views within each class for interpretation only.
Ranked=table();
for c=1:K
 A=R(R.Class==classes(c),:);
 A=sortrows(A,{'MeanTrueClassScore','HardRecall'},{'descend','descend'});
 A.Rank=(1:height(A))';
 Ranked=[Ranked;A]; %#ok<AGROW>
end
writetable(Ranked,fullfile(cfg.resultsDir,'CAP_VIEW_CLASS_RANKED.csv'));

% Overall view summary, macro-averaged over classes.
O=table();
for v=1:numel(views)
 A=R(R.View==views(v),:);
 O=[O;table(views(v),mean(A.HardRecall,'omitnan'),mean(A.MeanTrueClassScore,'omitnan'), ...
  'VariableNames',{'View','MacroHardRecall','MacroMeanTrueClassScore'})]; %#ok<AGROW>
end
O=sortrows(O,'MacroMeanTrueClassScore','descend');
writetable(O,fullfile(cfg.resultsDir,'CAP_VIEW_OVERALL.csv'));

fprintf('\nCAP VIEW ANALYSIS -- OOF predictions only\n');
disp(O);
fprintf('\nBest view per class by mean true-class score:\n');
for c=1:K
 A=Ranked(Ranked.Class==classes(c) & Ranked.Rank==1,:);
 fprintf('%s -> %s | score %.4f | recall %.4f\n',classes(c),A.View,A.MeanTrueClassScore,A.HardRecall);
end
fprintf('\nSaved: CAP_VIEW_CLASS_ANALYSIS.csv, CAP_VIEW_CLASS_RANKED.csv, CAP_VIEW_OVERALL.csv\n');
fprintf('Important: use this as descriptive evidence; do not tune final weights on these held-out labels.\n');
end

function view=parse_views(wav)
wav=string(wav); view=strings(numel(wav),1);
for i=1:numel(wav)
 tok=regexp(erase(wav(i),'.wav'),'^[^_]+_[0-9]+_(sit|sup)_(Aor|Mit|Pul|Tri)$','tokens','once');
 assert(~isempty(tok),'Bad WAV name: %s',wav(i));
 view(i)=string(tok{1})+"_"+string(tok{2});
end
end
