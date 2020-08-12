function run_sims_and_inversions(emptyD,snr)
%% Init

% First, work out where we are
[files.root,~,~] = fileparts(mfilename('fullpath'));

if ~exist(fullfile(files.root,'sims'))
    mkdir(fullfile(files.root,'sims'));
end

if ~exist(fullfile(files.root,'sims'))
    mkdir(fullfile(files.root,'sims'));
end

inversions = {'EBB','EBBcorr','IID'};
simtype = {'mono','dual_uncorr','dual_corr'};

%% Simulations
locations =   [52.3018  -24.7405    8.0343
  -51.8729  -24.4440   12.2991];

count = 0;
matlabbatch = [];
for ii = 1:numel(simtype)
    jj = simtype{ii};
    count = count + 1;
    switch jj
        case 'mono'
            freqs=[20]; %% correlated
            dipmom=[10 10]; % single
            locs=locations(1,:);
        case {'dual_corr','dual_uncorr'}
            switch jj
                case 'dual_corr'
                    freqs=[20 20]; %% correlated
                case 'dual_uncorr'
                    freqs = [10 20]; %% uncorrelated
            end
            dipmom=[10 10;10 10]; % dual
            locs = locations;
    end
    simname = fullfile(files.root,'sims',[jj '_sim_' num2str(snr) 'dB_']);
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
go_close_non_spm_windows();

%% Source analysis part one, housekeeping.
for ii = 1:numel(simtype)
    
    files.D       = fullfile(files.root,'sims',[simtype{ii} '_sim_' num2str(snr) 'dB_001.mat']);
    files.results = fullfile(files.root,'proc',[simtype{ii} '_' num2str(snr) 'dB']);
    files.BF      = fullfile(files.results,'BF.mat');
    
    if ~exist(files.results)
        mkdir(files.results);
    end
    
    matlabbatch = [];
    
    % Imports data into DAiSS ecosystem
    matlabbatch{1}.spm.tools.beamforming.data.dir = {[files.results]};
    matlabbatch{1}.spm.tools.beamforming.data.D(1) = {files.D};
    matlabbatch{1}.spm.tools.beamforming.data.val = 1;
    matlabbatch{1}.spm.tools.beamforming.data.gradsource = 'inv';
    matlabbatch{1}.spm.tools.beamforming.data.space = 'MNI-aligned';
    matlabbatch{1}.spm.tools.beamforming.data.overwrite = 1;
    
    % % Source space setup / forward solution
    matlabbatch{2}.spm.tools.beamforming.sources.BF(1) = {files.BF};
    matlabbatch{2}.spm.tools.beamforming.sources.reduce_rank = [2 3];
    matlabbatch{2}.spm.tools.beamforming.sources.keep3d = 1;
    matlabbatch{2}.spm.tools.beamforming.sources.plugin.mesh.orient = 'original';
    matlabbatch{2}.spm.tools.beamforming.sources.plugin.mesh.fdownsample = 1;
    matlabbatch{2}.spm.tools.beamforming.sources.plugin.mesh.symmetric = 'no';
    matlabbatch{2}.spm.tools.beamforming.sources.plugin.mesh.flip = false;
    matlabbatch{2}.spm.tools.beamforming.sources.visualise = 1;
    
    % Generate covariace matrix
    matlabbatch{3}.spm.tools.beamforming.features.BF = {files.BF};
    matlabbatch{3}.spm.tools.beamforming.features.whatconditions.all = 1;
    matlabbatch{3}.spm.tools.beamforming.features.woi = [-Inf Inf];
    matlabbatch{3}.spm.tools.beamforming.features.modality = {'MEG'};
    matlabbatch{3}.spm.tools.beamforming.features.fuse = 'no';
    matlabbatch{3}.spm.tools.beamforming.features.plugin.tdcov.foi = [1 48];
    matlabbatch{3}.spm.tools.beamforming.features.plugin.tdcov.ntmodes = [4];
    matlabbatch{3}.spm.tools.beamforming.features.plugin.tdcov.taper = 'none';
    matlabbatch{3}.spm.tools.beamforming.features.regularisation.manual.lambda = 0;
    matlabbatch{3}.spm.tools.beamforming.features.bootstrap = false;
    
    [a b] = spm_jobman('run',matlabbatch);
    
end

%% Source analysis part two, source recon and power estimation

for ii = 1:numel(simtype)
    for jj = 1:numel(inversions)
        
        files.results = fullfile(files.root,'proc',[simtype{ii} '_' num2str(snr) 'dB'],inversions{jj});
        files.BF      = fullfile(files.results,'BF.mat');
        
        if ~exist(files.results)
            mkdir(files.results)
        else
            delete(fullfile(files.results,'*'))
        end
        
        matlabbatch = [];
        
        % Copy prepped BF file into new folder
        matlabbatch{1}.spm.tools.beamforming.copy.BF = {fullfile(files.results,'..','BF.mat')};
        matlabbatch{1}.spm.tools.beamforming.copy.dir = {files.results};
        matlabbatch{1}.spm.tools.beamforming.copy.steps = 'all';
        
        % Empirical Bayesian source reconstuction
        matlabbatch{2}.spm.tools.beamforming.inverse.BF = {files.BF};
        matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.keeplf = false;
        switch inversions{jj}
            case 'EBB'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = false;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.iid = false;
            case 'EBBcorr'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = true;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.iid = false;
            case 'IID'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = false;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.iid = true;
        end
        
        % Source power estimation
        matlabbatch{3}.spm.tools.beamforming.output.BF(1) = {files.BF};
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.whatconditions.all = 1;
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.sametrials = true;
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.woi = [0 1000];
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.foi = [8 22];
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.contrast = 1;
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.logpower = false;
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.result = 'singleimage';
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.scale = 0;
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.powermethod = 'trace';
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.modality = 'MEG';
        
        [a b] = spm_jobman('run',matlabbatch);
    end
end
