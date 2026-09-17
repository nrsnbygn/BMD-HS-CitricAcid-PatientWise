function run_all()
%RUN_ALL One-command entry point for the student.
setup;
smoke_test;
run_from_features(fullfile('data','features_2120.mat'));
end
