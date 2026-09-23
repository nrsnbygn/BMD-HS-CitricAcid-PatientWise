function cfg = config()
%CONFIG Central configuration for leakage-free thesis reproduction.

cfg.randomSeed = 1;
cfg.fs = 4000;
cfg.segmentSeconds = 2;
cfg.segmentSamples = cfg.fs * cfg.segmentSeconds;
cfg.wavelet = 'db4';
cfg.dwtLevel = 5;
cfg.components = {'raw','A1','A2','A3','A4'};
cfg.numFolds = 10;
cfg.ncaFeatureCount = 256;

cfg.knn.NumNeighbors = 10;
cfg.knn.Distance = 'cityblock';
cfg.knn.DistanceWeight = 'inverse';

cfg.ensemble.NumLearningCycles = 30;
cfg.ensemble.SubspaceDimensionRule = 'sqrt';

% Class imbalance experiment. Balancing is applied ONLY to the training rows
% after patient-wise splitting and NCA selection. Held-out patients retain
% their natural class distribution.
cfg.balance.enabled = true;
cfg.balance.method = 'random_undersample';
cfg.balance.seed = 1;

cfg.manifest = fullfile('data','manifest.csv');
cfg.cacheDir = fullfile('cache');
cfg.resultsDir = fullfile('results');
cfg.cacheFile = fullfile(cfg.cacheDir,'features.mat');
end
