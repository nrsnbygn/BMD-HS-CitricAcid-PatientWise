function H = citric_acid_pattern(x)
%CITRIC_ACID_PATTERN 384-D Citric Acid Pattern (CAP) descriptor.
% Implements the architecture documented in Fadile_Ozturk_Tez_V7:
% 81-sample sliding window -> 9x9 grid -> 12 directed graph edges ->
% two 6-edge blocks -> signum, upper-ternary and lower-ternary binary
% codes -> six 64-bin histograms (384 features).
%
% IMPORTANT: The edge coordinates below are transcribed from thesis Figure 6.
% Coordinates are (X,Y), with Y increasing upward in the figure. MATLAB's
% matrix row therefore uses row = 10-Y and column = X.

x = double(x(:));
H = zeros(1,384);
if numel(x) < 81
    return;
end
thr = std(x,0,'omitnan')/2;
if ~isfinite(thr), thr = 0; end

% Figure-6 directed edges, (sourceX,sourceY,targetX,targetY).
% Block 1: left/central molecular branch; Block 2: right/central branch.
E1 = [1 9 3 7; ...
      1 5 3 7; ...
      5 7 3 7; ...
      6 5 5 7; ...
      6 5 4 4; ...
      4 4 4 2];
E2 = [2 1 4 2; ...
      6 1 4 2; ...
      7 3 6 5; ...
      6 5 8 6; ...
      8 8 8 6; ...
      9 5 8 6];

% Histogram order: block1 sign/upper/lower, block2 sign/upper/lower.
h = zeros(6,64);
for i = 1:(numel(x)-80)
    % Thesis pseudocode: take 81 consecutive samples and reshape to 9x9.
    G = reshape(x(i:i+80),9,9);
    h(1,:) = add_code(h(1,:), code_edges(G,E1,thr,'sign'));
    h(2,:) = add_code(h(2,:), code_edges(G,E1,thr,'upper'));
    h(3,:) = add_code(h(3,:), code_edges(G,E1,thr,'lower'));
    h(4,:) = add_code(h(4,:), code_edges(G,E2,thr,'sign'));
    h(5,:) = add_code(h(5,:), code_edges(G,E2,thr,'upper'));
    h(6,:) = add_code(h(6,:), code_edges(G,E2,thr,'lower'));
end
H = reshape(h.',1,[]);
end

function histo = add_code(histo,code)
histo(code+1)=histo(code+1)+1;
end

function code = code_edges(G,E,thr,kind)
bits=zeros(1,6);
for q=1:6
    t=grid_value(G,E(q,1),E(q,2));
    r=grid_value(G,E(q,3),E(q,4));
    d=r-t;
    switch kind
        case 'sign'
            bits(q)=d>=0;
        case 'upper'
            bits(q)=d>thr;
        case 'lower'
            bits(q)=d<(-thr);
        otherwise
            error('Unknown CAP comparison kind.');
    end
end
% First edge is least-significant bit; 6 bits -> integer 0..63.
code=sum(bits .* (2.^(0:5)));
end

function v=grid_value(G,x,y)
% Figure uses Cartesian-like Y=1..9 bottom-to-top.
row=10-y; col=x;
v=G(row,col);
end
