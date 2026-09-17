# BMD-HS Citric Acid Pattern — Patient-wise evaluation

MATLAB reproduction of the method described in `Fadile_Öztürk_Tez_V7` with the evaluation corrected to prevent data leakage: **all evaluation is subject/patient-wise and all supervised preprocessing is fitted inside the training fold**.

## Thesis method preserved

1. BMD-HS PCG recordings (4 kHz), split into non-overlapping 2 s segments.
2. Five-level `db4` DWT.
3. Feature extraction from **Raw + A1 + A2 + A3 + A4** (A5 and D1-D5 are not used, matching V7).
4. Per signal component: **384 Citric Acid Pattern (CAP) + 40 statistical features = 424 features**.
5. Five components -> **2120 features/segment**.
6. NCA -> top **256** features, fitted separately inside every training fold.
7. KNN-based Subspace Ensemble classification.
8. Ten-fold **subject-wise** cross-validation.

## Citric Acid Pattern verification

`src/citric_acid_pattern.m` implements the CAP architecture documented in V7: an 81-sample sliding window is reshaped to 9x9; the 12 directed edges shown in thesis Figure 6 are divided into two 6-edge blocks; signum, upper-threshold and lower-threshold binary codes generate six 64-bin histograms = 384 features. The threshold is `std(signal)/2` as stated in V7.

The graph coordinates were transcribed from Figure 6 and are kept explicitly in the source so they can be audited.

## Why this repository differs from the original thesis experiment

The signal-processing and feature architecture are retained. The validation protocol is corrected:

- no patient can occur in both train and test in a fold;
- NCA is fitted on training subjects only;
- scaling parameters are estimated on training subjects only;
- the held-out fold is not used to choose the feature count or model settings;
- a leakage audit is written for every run.

## Scientific contribution test

Two pipelines are evaluated on **exactly the same patient-wise folds**:

- `baseline_stats`: thesis statistical features only;
- `proposed_cap_stats`: thesis Citric Acid Pattern + statistical features.

This tests whether CAP adds predictive information under the same leakage-free evaluation. The repository does not assume that the proposed method wins; the measured results determine that conclusion.

## Recommended exact-reproduction route

V7 states that 40 statistical features are used, but the available thesis text does not enumerate all 40 formulas. Therefore this repository deliberately does **not** invent substitute statistics. For the final thesis experiment, use the student's original 2120-D feature matrix:

```matlab
X          % nSegments x 2120
y          % N / AS / AR / MR / MS / MD
subjectID  % original patient ID for every segment
save('data/features_2120.mat','X','y','subjectID','-v7.3')
```

Then run:

```matlab
setup
smoke_test
run_all
```

`subjectID` is mandatory. All recordings and all 2 s segments belonging to one patient must carry the same patient ID. Never assign a new patient ID per recording or per segment.

## Outputs

`results/` contains `SUMMARY.csv`, fold metrics, predictions, confusion matrices, NCA selections, patient-wise fold assignment and `LEAKAGE_AUDIT.csv`. Every `OverlapSubjects` value must be 0.

## MATLAB requirements

Signal Processing Toolbox, Wavelet Toolbox, Statistics and Machine Learning Toolbox. MATLAB R2022b or newer is recommended.

## Reproducibility notes

V7 specifies KNN `k=10`, Cityblock distance and distance weighting, but does not fully specify every Ensemble Subspace KNN hyperparameter. The executable settings are therefore stated explicitly in `config.m`; they must not be described as thesis-specified unless confirmed from the student's original MATLAB code.

V7 reports 256 NCA-selected features after trying different feature counts. The main leakage-free reproduction treats 256 as a fixed, pre-specified thesis setting and fits NCA only within each training fold; it does not tune the feature count on held-out patients.
