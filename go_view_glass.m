function go_view_glass(BF, S)
% Diplays glass brain plot of DAISS output results
% Copyright (C) 2020 Wellcome Trust Centre for Neuroimaging

% George O'Neill
% $Id: bf_view_glass.m 7846 2020-05-05 14:33:24Z george $

%--------------------------------------------------------------------------
if nargin < 2
    error('Two input arguments are required');
end

% if BF is a path rather than stucture, import
if isa(BF,'string')
    BF = bf_load(BF);
end

if ~isfield(BF.sources, 'pos')
    error('Source space snafu, email george!')
end

S.ndips = min(S.ndips,length(BF.sources.pos));
if iscell(S.cmap); S.cmap = cell2mat(S.cmap); end

pos = ft_warp_apply(BF.data.transforms.toMNI, BF.sources.pos);

X = BF.output.image.val;
[~, id] = sort(X,'descend');
id = id(1:S.ndips);

spm_mip(X(id),pos(id,:),6);
colormap(S.cmap);

axis image
set(gcf,'color','w');

