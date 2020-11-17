function run_sims(emptyD,location,snr)
%% Init

% First, work out where we are
[files.root,~,~] = fileparts(mfilename('fullpath'));

if ~exist(fullfile(files.root,'sims',location))
    mkdir(fullfile(files.root,'sims',location));
end

simtype = {'mono','dual_uncorr','dual_corr'};

%% Simulations
switch location
    case 'heschl'
        coords =   [52.3018  -24.7405    8.0343
            -51.8729  -24.4440   12.2991];
    case 'hippocampus'
        coords = [24.81 -11.3 -17.46
            -26.15 -10.73 -18.32];
end

count = 0;
matlabbatch = [];
for ii = 1:numel(simtype)
    jj = simtype{ii};
    count = count + 1;
    switch jj
        case 'mono'
            freqs=[20]; %% correlated
            dipmom=[10 10]; % single
            locs=coords(1,:);
        case {'dual_corr','dual_uncorr'}
            switch jj
                case 'dual_corr'
                    freqs=[20 20]; %% correlated
                case 'dual_uncorr'
                    freqs = [10 20]; %% uncorrelated
            end
            dipmom=[10 10;10 10]; % dual
            locs = coords;
    end
    simname = fullfile(files.root,'sims',location,[jj '_sim_' num2str(snr) 'dB_']);
    % Run the simulations
    matlabbatch{count}.spm.meeg.source.simulate.D = {emptyD};
    matlabbatch{count}.spm.meeg.source.simulate.val = 1;
    matlabbatch{count}.spm.meeg.source.simulate.prefix = simname;
    matlabbatch{count}.spm.meeg.source.simulate.whatconditions.all = 1;
    matlabbatch{count}.spm.meeg.source.simulate.isinversion.setsources.woi = [0 1000];
    matlabbatch{count}.spm.meeg.source.simulate.isinversion.setsources.isSin.foi=freqs;
    matlabbatch{count}.spm.meeg.source.simulate.isinversion.setsources.dipmom = dipmom;
    matlabbatch{count}.spm.meeg.source.simulate.isinversion.setsources.locs =locs;
    matlabbatch{count}.spm.meeg.source.simulate.isSNR.setSNR = snr;
    
end

[a b] = spm_jobman('run',matlabbatch);
cd(files.root);
go_close_non_spm_windows();
