# BMD-HS Citric Acid Pattern — Patient-wise evaluation

MATLAB reproduction of the method described in `Fadile_Öztürk_Tez_V7`, with evaluation corrected to prevent data leakage: **all evaluation is subject/patient-wise and all supervised preprocessing is fitted inside the training fold**.

## Thesis method preserved

1. BMD-HS PCG recordings (4 kHz), non-overlapping 2 s segments.
2. Five-level `db4` DWT.
3. Features from **Raw + A1 + A2 + A3 + A4**.
4. Per component: **384 Citric Acid Pattern + 40 statistical = 424 features**.
5. Five components = **2120 features/segment**.
6. NCA -> top **256**, fitted separately inside each training fold.
7. KNN-based Subspace Ensemble classification.
8. Ten-fold **subject-wise** cross-validation.

## Citric Acid Pattern verification

`src/citric_acid_pattern.m` implements the V7 architecture: 81-sample sliding window -> 9x9 grid -> 12 directed edges from thesis Figure 6 -> two 6-edge blocks -> signum/upper/lower codes -> six 64-bin histograms = 384 features. Threshold is `std(signal)/2`.

For the final experiment the student's **original 2120-D thesis feature matrix is preferred**, because V7 does not enumerate all 40 statistical formulas and the original matrix also preserves the exact feature-generation conventions used in the thesis.

## Leakage safeguards

- one patient can belong to only one outer fold;
- NCA is trained only on training patients;
- scaling mean/SD are learned only from training patients;
- held-out patients are never used to choose 256 features or model settings;
- execution checks patient IDs and single-label consistency;
- `LEAKAGE_AUDIT.csv` must report `OverlapSubjects=0` for every fold.

## Scientific contribution / ablation test

Three pipelines use **exactly the same patient-wise folds**:

- `baseline_stats`: statistical features only;
- `cap_only`: Citric Acid Pattern only;
- `proposed_cap_stats`: thesis Citric Acid Pattern + statistical features.

This design tests the incremental contribution of CAP without changing the thesis's central method. Performance is not assumed in advance; the measured patient-independent results determine whether CAP contributes.

## Input

Create `data/features_2120.mat` from the student's original thesis features:

```matlab
X          % nSegments x 2120
y          % N / AS / AR / MR / MS / MD
subjectID  % original patient ID for every segment
save('data/features_2120.mat','X','y','subjectID','-v7.3')
```

All recordings and all 2 s segments from one patient must have the same `subjectID`.

## Run

```matlab
setup
smoke_test
run_all
```

`smoke_test` checks CAP dimensionality, zero subject overlap, train-only NCA and classifier execution before the full experiment.

## Outputs

`results/` contains `SUMMARY.csv`, `LEAKAGE_AUDIT.csv`, patient/segment fold assignments, per-fold metrics, predictions, per-class metrics, confusion matrices and fold-specific NCA files. Report Accuracy together with Balanced Accuracy and Macro-F1.

## MATLAB requirements

Signal Processing Toolbox, Wavelet Toolbox, Statistics and Machine Learning Toolbox. MATLAB R2022b or newer recommended.

## Reproducibility notes

V7 specifies KNN `k=10`, Cityblock distance and distance weighting but does not fully specify every Ensemble Subspace KNN hyperparameter. Executable ensemble settings are explicit in `config.m` and must not be described as thesis-specified unless confirmed from the student's original code.

V7 reports 256 NCA-selected features after trying different counts. This leakage-free reproduction treats 256 as a fixed thesis setting and fits NCA independently in each training fold; it never re-selects the feature count using held-out patients.
