function run_inversions(id)
%% Init

% First, work out where we are
files.root = 'D:\sims_256';

if ~exist(fullfile(files.root,'proc'))
    mkdir(fullfile(files.root,'proc'));
end

inversions = {'EBB','EBBcorr'};
simtype = {'mono','dual_uncorr','dual_corr'};

snr = -10;

%% Source analysis part one, housekeeping.
superbatch = [];
for ii = 1:numel(simtype)

    files.D       = fullfile(files.root,'sims',[sprintf('%03d',id) '_' simtype{ii} '_sim_' num2str(snr) 'dB_001.mat']);
    %     files.simroot = 'D:\Documents\ebb_corr\paper_sims';
    %     files.D       = fullfile(files.simroot,[simtype{ii} '_sim_' num2str(snr) 'dB_002.mat']);
    files.results = fullfile(files.root,'proc',[sprintf('%03d',id) '_' simtype{ii} '_' num2str(snr) 'dB']);
    files.BF      = fullfile(files.results,'BF.mat');

    if ~exist(files.results)
        mkdir(files.results);
    end

    matlabbatch = [];


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
    matlabbatch{3}.spm.tools.beamforming.features.plugin.tdcov.taper = 'hanning';
    %         matlabbatch{3}.spm.tools.beamforming.features.plugin.cov.foi = [1 48];
    matlabbatch{3}.spm.tools.beamforming.features.regularisation.manual.lambda = 0;
    matlabbatch{3}.spm.tools.beamforming.features.bootstrap = false;

    superbatch{end+1} = matlabbatch;

end

parfor ii = 1:numel(superbatch)
    [a b] = spm_jobman('run',superbatch{ii});
end

%% Source analysis part two, source recon and power estimation

superbatch = [];
for ii = 1:numel(simtype)
    for jj = 1:numel(inversions)
        
        files.results = fullfile(files.root,'proc',[sprintf('%03d',id) '_' simtype{ii} '_' num2str(snr) 'dB'],inversions{jj});
        files.BF      = fullfile(files.results,'BF.mat');
        
        if ~exist(files.results)
            mkdir(files.results)
        else
            delete(fullfile(files.results,'*'))
        end
        
        % If LCMV use different covariance generation methods
        
        matlabbatch = [];
        
        % Copy prepped BF file into new folder
        matlabbatch{1}.spm.tools.beamforming.copy.BF = {fullfile(files.results,'..','BF.mat')};
        matlabbatch{1}.spm.tools.beamforming.copy.dir = {files.results};
        matlabbatch{1}.spm.tools.beamforming.copy.steps = 'all';
        
        % Empirical Bayesian source reconstuction
        matlabbatch{2}.spm.tools.beamforming.inverse.BF = {files.BF};
        switch inversions{jj}
            case 'EBB'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = false;
            case 'EBBcorr'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = true;
        end
        matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.keeplf = false;

        % Source power estimation
%         matlabbatch{3}.spm.tools.beamforming.output.BF(1) = {files.BF};
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.whatconditions.all = 1;
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.sametrials = true;
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.woi = [0 1000];
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.foi = [8 22];
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.contrast = 1;
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.logpower = false;
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.result = 'singleimage';
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.scale = 1;
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.powermethod = 'trace';
%         matlabbatch{3}.spm.tools.beamforming.output.plugin.image_power.modality = 'MEG';
        
        superbatch{end+1} = matlabbatch;
    end
end

parfor ii = 1:numel(superbatch)
    [a b] = spm_jobman('run',superbatch{ii});
end

[files.root,~,~] = fileparts(mfilename('fullpath'));
cd(files.root);

go_close_non_spm_windows();
