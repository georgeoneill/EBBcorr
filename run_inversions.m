function run_inversions(location,snr,varargin)
%% Init

% First, work out where we are
[files.root,~,~] = fileparts(mfilename('fullpath'));


if ~exist(fullfile(files.root,'proc',location))
    mkdir(fullfile(files.root,'proc',location));
end

% inversions = {'EBB_uncorr','EBB_corr_uncorr_on','EBB_corr_uncorr_off',...
%     'EBB_corr_uncorr_both','EBB_corr_on','EBB_corr_off','EBB_corr_both'};

inversions = {'EBB_corr_on','EBB_corr_off','EBB_corr_both'};
simtype = {'mono','dual_uncorr','dual_corr'};


%% Source analysis part one, housekeeping.
for ii = 1:numel(simtype)
    
    files.D       = fullfile(files.root,'sims',location,[simtype{ii} '_sim_' num2str(snr) 'dB_001.mat']);
    files.results = fullfile(files.root,'proc',location,[simtype{ii} '_' num2str(snr) 'dB']);
    files.BF      = fullfile(files.results,'BF.mat');
    
    if ~exist(files.results)
        mkdir(files.results);
    end
    
    matlabbatch = [];
    
    if nargin < 3
    
%     % Imports data into DAiSS ecosystem
    matlabbatch{1}.spm.tools.beamforming.data.dir = {[files.results]};
    matlabbatch{1}.spm.tools.beamforming.data.D(1) = {files.D};
    matlabbatch{1}.spm.tools.beamforming.data.val = 1;
    matlabbatch{1}.spm.tools.beamforming.data.gradsource = 'inv';
    matlabbatch{1}.spm.tools.beamforming.data.space = 'MNI-aligned';
    matlabbatch{1}.spm.tools.beamforming.data.overwrite = 1;
%     
%     % % Source space setup / forward solution
    matlabbatch{2}.spm.tools.beamforming.sources.BF(1) = {files.BF};
    matlabbatch{2}.spm.tools.beamforming.sources.reduce_rank = [2 3];
    matlabbatch{2}.spm.tools.beamforming.sources.keep3d = 1;
    matlabbatch{2}.spm.tools.beamforming.sources.plugin.mesh.orient = 'original';
    matlabbatch{2}.spm.tools.beamforming.sources.plugin.mesh.fdownsample = 1;
    matlabbatch{2}.spm.tools.beamforming.sources.plugin.mesh.symmetric = 'no';
    matlabbatch{2}.spm.tools.beamforming.sources.plugin.mesh.flip = false;
    matlabbatch{2}.spm.tools.beamforming.sources.visualise = 0;
    
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
    
    else
        disp('skipping foward solution and covariance generation')
    end
    
end

%% Source analysis part two, source recon and power estimation

for ii = 1:numel(simtype)
    for jj = 1:numel(inversions)
        
        files.results = fullfile(files.root,'proc',location,[simtype{ii} '_' num2str(snr) 'dB'],inversions{jj});
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
        matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.iid = false;
        switch inversions{jj}
            case 'EBB_uncorr'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = false;
            case 'EBB_corr_uncorr_on'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = true;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.diags = 'on';
            case 'EBB_corr_uncorr_off'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = true;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.diags = 'off';
            case 'EBB_corr_uncorr_both'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = true;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.diags = 'both';
            case 'EBB_corr_on'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.onlycorr = true;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.diags = 'on';
            case 'EBB_corr_off'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.onlycorr = true;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.diags = 'off';
            case 'EBB_corr_both'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.onlycorr = true;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.diags = 'both';
            case 'IID'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = false;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.iid = true;
        end
        
        % Source power estimation
        matlabbatch{3}.spm.tools.beamforming.output.BF(1) = {files.BF};
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.whatconditions.all = 1;
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.sametrials = true;
        matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.woi = [100 1100];
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
cd(files.root);
go_close_non_spm_windows();
