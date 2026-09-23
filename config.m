function cfg = config()
%CONFIG Central configuration for leakage-free thesis reproduction.
cfg.randomSeed=1; cfg.fs=4000; cfg.segmentSeconds=2; cfg.segmentSamples=8000;
cfg.wavelet='db4'; cfg.dwtLevel=5; cfg.components={'raw','A1','A2','A3','A4'};
cfg.numFolds=10; cfg.ncaFeatureCount=256;
cfg.knn.NumNeighbors=10; cfg.knn.Distance='cityblock'; cfg.knn.DistanceWeight='inverse';
cfg.ensemble.NumLearningCycles=30; cfg.ensemble.SubspaceDimensionRule='sqrt';

% Cost-sensitive experiment: no rows are removed. The cost matrix is
% estimated ONLY from each training fold using inverse class frequency.
cfg.imbalance.method='cost_sensitive';
cfg.imbalance.power=1.0;

cfg.manifest=fullfile('data','manifest.csv');
cfg.cacheDir=fullfile('cache'); cfg.resultsDir=fullfile('results');
cfg.cacheFile=fullfile(cfg.cacheDir,'features.mat');
end
