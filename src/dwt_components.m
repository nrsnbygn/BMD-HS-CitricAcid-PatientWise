function comps = dwt_components(x, waveletName)
%DWT_COMPONENTS Return thesis components: raw, A1, A2, A3, A4.
% Each approximation is reconstructed to the original signal length so the
% same feature extractor can be applied to every component.

x = double(x(:).');
[c,l] = wavedec(x,5,waveletName);
comps = cell(1,5);
comps{1} = x;
for lev = 1:4
    comps{lev+1} = wrcoef('a',c,l,waveletName,lev);
    comps{lev+1} = comps{lev+1}(:).';
end
end
