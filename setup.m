function setup()
%SETUP Add repository source folders and create working directories.
root = fileparts(mfilename('fullpath'));
addpath(root);
addpath(fullfile(root,'src'));
addpath(fullfile(root,'tests'));

cfg = config();
if ~exist(cfg.cacheDir,'dir'), mkdir(cfg.cacheDir); end
if ~exist(cfg.resultsDir,'dir'), mkdir(cfg.resultsDir); end

fprintf('BMD-HS CAP patient-wise pipeline ready.\n');
fprintf('MATLAB: %s\n', version);
fprintf('Manifest expected at: %s\n', cfg.manifest);
end
