# BMD-HS Citric Acid Pattern — Patient-wise evaluation

MATLAB reproduction of the method described in `Fadile_Öztürk_Tez_V7` with one methodological correction: **all evaluation is subject/patient-wise and all supervised preprocessing is fitted inside the training fold**.

## Thesis method reproduced

1. BMD-HS PCG recordings (4 kHz), split into non-overlapping 2 s segments.
2. Five-level `db4` DWT.
3. Feature extraction from **Raw + A1 + A2 + A3 + A4** (A5 and D1–D5 are not used, matching the thesis).
4. Per signal component: **384 Citric Acid Pattern (CAP) + 40 statistical features = 424 features**.
5. Five components -> **2120 features/segment**.
6. NCA feature selection -> top **256** features.
7. KNN-based Subspace Ensemble classification.
8. Ten-fold **subject-wise** cross-validation.

## Why this repository differs from the original thesis experiment

The thesis describes 10-fold CV after segmentation. For a defensible estimate of generalisation to unseen patients, this implementation never permits segments from the same subject in both train and test folds. NCA is also fitted only on the training subjects of each fold. Test labels are never used for feature selection, scaling, model fitting, or hyperparameter selection.

The signal-processing/feature method is intentionally kept close to the thesis; the validation protocol is corrected rather than redesigning the thesis.

## Scientific contribution test

The repository runs two pipelines on **exactly the same patient-wise folds**:

- `baseline`: DWT + statistical features only.
- `proposed`: DWT + Citric Acid Pattern + statistical features.

This directly tests whether the thesis's proposed CAP representation adds value under leakage-free evaluation. A contribution must be concluded from the measured results; the code does not assume that CAP will outperform the baseline.

## Requirements

MATLAB with Signal Processing Toolbox, Statistics and Machine Learning Toolbox, and Wavelet Toolbox.

## Dataset manifest

The BMD-HS audio data are not redistributed here. Create `data/manifest.csv` with one row per original recording:

```text
subject_id,label,file_path
P001,N,C:/BMD-HS/P001_recording01.wav
P001,N,C:/BMD-HS/P001_recording02.wav
P002,AS,C:/BMD-HS/P002_recording01.wav
```

`subject_id` is mandatory. It is the grouping variable that prevents patient leakage. `label` must be one of `N, AS, AR, MR, MS, MD`. `file_path` may be absolute or relative to the repository.

> Do not create a new subject ID for each segment or each recording. All recordings belonging to the same patient must have the same `subject_id`.

## Run

Open MATLAB in the repository root and run:

```matlab
setup;
run_all;
```

For a quick pipeline check before the full experiment:

```matlab
setup;
smoke_test;
```

## Outputs

`results/` contains fold assignments, per-fold metrics, aggregate metrics, predictions, selected NCA features, confusion matrices, and a leakage audit. The run stops with an error if a subject appears in both train and test within a fold.

## Important reproducibility note

The thesis specifies KNN `k=10`, Cityblock distance and distance weighting, while the reported winning classifier is Ensemble Subspace KNN. It does not fully specify every ensemble hyperparameter. This repository therefore records the executable ensemble settings in `config.m` rather than silently presenting them as thesis-specified parameters. Any change to those settings must be reported in the thesis/revision.

The thesis states that 256 features were selected after trying different feature counts, but does not fully specify a nested tuning protocol. To avoid leakage, the main reproduction fixes the feature count at 256 **a priori** from the thesis and fits NCA separately inside each training fold. It does not re-select 256 using the held-out test subjects.
