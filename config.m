function cfg = config()
%CONFIG Central configuration for the leakage-free thesis reproduction.

cfg.randomSeed = 1;
cfg.fs = 4000;
cfg.segmentSeconds = 2;
cfg.segmentSamples = cfg.fs * cfg.segmentSeconds;
cfg.wavelet = 'db4';
cfg.dwtLevel = 5;
cfg.components = {'raw','A1','A2','A3','A4'};
cfg.numFolds = 10;
cfg.ncaFeatureCount = 256;

% KNN parameters explicitly stated in the thesis.
cfg.knn.NumNeighbors = 10;
cfg.knn.Distance = 'cityblock';
cfg.knn.DistanceWeight = 'inverse';

% The thesis reports Ensemble Subspace KNN but does not fully state these
% ensemble settings. They are explicit here for reproducibility and MUST NOT
% be described as thesis-specified unless the student's original code proves it.
cfg.ensemble.NumLearningCycles = 30;
cfg.ensemble.SubspaceDimensionRule = 'sqrt';

cfg.manifest = fullfile('data','manifest.csv');
cfg.cacheDir = fullfile('cache');
cfg.resultsDir = fullfile('results');
cfg.cacheFile = fullfile(cfg.cacheDir,'features.mat');
end
