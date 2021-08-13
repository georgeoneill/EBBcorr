function run_sims_hipp(emptyD,location,id)
%% Init

% First, work out where we are
files.root = 'D:\sims_256\hippo';
% files.root = fullfile(files.root,'sourcetest');

if ~exist(fullfile(files.root,'sims'))
    mkdir(fullfile(files.root,'sims'));
end

simtype = {'dual_uncorr'};

snr = -10;

%% Simulations

superbatch = [];
for zz = 1:size(location,1)
    
    x = location(zz,1);
    y = location(zz,2);
    z = location(zz,3);
    
    coords = [x y z;
        -x y z];
    
    
    count = 0;
    matlabbatch = [];
    
    for ii = 1:numel(simtype)
        jj = simtype{ii};
        count = 1;
        switch jj
            case 'mono'
                freqs=[20]; %% correlated
                dipmom=[10 5]; % single
                locs=coords(1,:);
            case {'dual_corr','dual_uncorr'}
                switch jj
                    case 'dual_corr'
                        freqs=[20 20]; %% correlated
                    case 'dual_uncorr'
                        freqs = [10 20]; %% uncorrelated
                end
                dipmom=[10 5;10 5]; % dual
                locs = coords;
        end
        simname = fullfile(files.root,'sims',[sprintf('%03d',id(zz)) '_' jj '_sim_' num2str(snr) 'dB_']);
        % Run the simulations
        matlabbatch{count}.spm.meeg.source.simulate.D = {fullfile(emptyD.path,emptyD.fname)};
        matlabbatch{count}.spm.meeg.source.simulate.val = 1;
        matlabbatch{count}.spm.meeg.source.simulate.prefix = simname;
        matlabbatch{count}.spm.meeg.source.simulate.whatconditions.all = 1;
        matlabbatch{count}.spm.meeg.source.simulate.isinversion.setsources.woi = [0 1000];
        matlabbatch{count}.spm.meeg.source.simulate.isinversion.setsources.isSin.foi=freqs;
        matlabbatch{count}.spm.meeg.source.simulate.isinversion.setsources.dipmom = dipmom;
        matlabbatch{count}.spm.meeg.source.simulate.isinversion.setsources.locs =locs;
        matlabbatch{count}.spm.meeg.source.simulate.isSNR.setSNR = snr;
                
    end
    superbatch{end+1} = matlabbatch;
end

parfor ii = 1:numel(superbatch);
    [a b] = spm_jobman('run',superbatch{ii});
end

% cd(files.root);
% cd('..')
[files.root,~,~] = fileparts(mfilename('fullpath'));
cd(files.root);
go_close_non_spm_windows();
