function f = statistical_features_40(x)
%STATISTICAL_FEATURES_40 Deterministic 40-D per-signal statistical descriptor.
%
% NOTE FOR THESIS REPRODUCTION:
% V7 states that 40 statistical features are extracted but the thesis text
% available to this repository does not enumerate all 40 formulas. Therefore
% this function intentionally DOES NOT invent a replacement set.
%
% For an exact thesis reproduction, replace the error below with the student's
% original 40-feature function, preserving its output order. Alternatively,
% use run_from_features.m with the student's already-extracted 2120-D matrix.
%
% This explicit stop is deliberate: silently substituting generic statistics
% would change the thesis method and invalidate a claimed reproduction.

x = double(x(:)); %#ok<NASGU>
error(['Exact 40 statistical-feature formulas are not fully specified in V7. ' ...
       'Use the student''s original feature extractor or run_from_features.m ' ...
       'with the original 2120-D feature matrix.']);
f=zeros(1,40); %#ok<UNRCH>
end
