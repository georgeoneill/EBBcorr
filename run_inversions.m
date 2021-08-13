function run_inversions(location,snr,varargin)
%% Init

% First, work out where we are
[files.root,~,~] = fileparts(mfilename('fullpath'));
% files.root = fullfile(files.root,'sourcetest');

if ~exist(fullfile(files.root,'proc',location))
    mkdir(fullfile(files.root,'proc',location));
end

% inversions = {'EBB_uncorr','EBB_corr_uncorr_on',...
%     'EBB_corr_uncorr_both','EBB_corr_on','EBB_corr_both'};
inversions = {'EBB_corr','EBB_corr_only'};
% inversions = {'EBB_corr_on','EBB_corr_off','EBB_corr_both'};
% inversions = {'champ'};
% 

% inversions = {'EBB_uncorr','EBB_corr_uncorr_on','EBB_corr_uncorr_off',...
%     'EBB_corr_uncorr_both'};
simtype = {'mono','dual_uncorr','dual_corr'};
% simtype = {'dual_corr'};


%% Source analysis part one, housekeeping.
for ii = 1:numel(simtype)
    
    files.D       = fullfile(files.root,'sims',location,[simtype{ii} '_sim_' num2str(snr) 'dB_001.mat']);
    %     files.simroot = 'D:\Documents\ebb_corr\paper_sims';
    %     files.D       = fullfile(files.simroot,[simtype{ii} '_sim_' num2str(snr) 'dB_002.mat']);
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
        matlabbatch{3}.spm.tools.beamforming.features.plugin.tdcov.taper = 'hanning';
%         matlabbatch{3}.spm.tools.beamforming.features.plugin.cov.foi = [1 48];
        matlabbatch{3}.spm.tools.beamforming.features.regularisation.manual.lambda = 0;
        matlabbatch{3}.spm.tools.beamforming.features.bootstrap = false;
        
        [a b] = spm_jobman('run',matlabbatch);
        
    else
        disp('skipping foward solution and covariance generation')
%         % Generate covariace matrix
%         matlabbatch{1}.spm.tools.beamforming.features.BF = {files.BF};
%         matlabbatch{1}.spm.tools.beamforming.features.whatconditions.all = 1;
%         matlabbatch{1}.spm.tools.beamforming.features.woi = [3000 4000; 0 1000];
%         matlabbatch{1}.spm.tools.beamforming.features.modality = {'MEG'};
%         matlabbatch{1}.spm.tools.beamforming.features.fuse = 'no';
%         %         matlabbatch{1}.spm.tools.beamforming.features.plugin.tdcov.foi = [1 48];
%         %         matlabbatch{1}.spm.tools.beamforming.features.plugin.tdcov.ntmodes = [16];
%         %         matlabbatch{1}.spm.tools.beamforming.features.plugin.tdcov.taper = 'hanning';
%         %         matlabbatch{1}.spm.tools.beamforming.features.plugin.cov.foi = [1 48];
%         %         matlabbatch{3}.spm.tools.beamforming.features.plugin.tdcov.ntmodes = [4];
%         %         matlabbatch{1}.spm.tools.beamforming.features.plugin.cov.taper = 'hanning';
%         matlabbatch{1}.spm.tools.beamforming.features.plugin.vbfa.nl = 5;
%         matlabbatch{1}.spm.tools.beamforming.features.plugin.vbfa.nem = 50;
%         matlabbatch{1}.spm.tools.beamforming.features.regularisation.manual.lambda = 0;
%         matlabbatch{1}.spm.tools.beamforming.features.bootstrap = false;
%         
%                 [a b] = spm_jobman('run',matlabbatch);
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
        
        % If LCMV use different covariance generation methods
        
        matlabbatch = [];
        
        % Copy prepped BF file into new folder
        matlabbatch{1}.spm.tools.beamforming.copy.BF = {fullfile(files.results,'..','BF.mat')};
        matlabbatch{1}.spm.tools.beamforming.copy.dir = {files.results};
        matlabbatch{1}.spm.tools.beamforming.copy.steps = 'all';
        
        % Empirical Bayesian source reconstuction
        matlabbatch{2}.spm.tools.beamforming.inverse.BF = {files.BF};
        switch inversions{jj}
            case 'LCMV'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.lcmv.orient = true;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.lcmv.keeplf = false;
            case 'champ'
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.champagne.nem = 100;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.champagne.vcs = 2;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.champagne.nupd = 0;
            otherwise
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.keeplf = false;
                matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.iid = false;
                switch inversions{jj}
                    case 'EBB_uncorr'
                        matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = false;
                    case 'EBB_corr'
                        matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = true;
                    case 'EBB_corr_only'
                        matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.onlycorr = true;
                    case 'EBB_corr_HB'
                        matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.corr = true;
%                         matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.diags = 'both';
                        files.pairs = {'D:\Documents\ebb_corr\meshes_w_hippo\pairs_hipp_body_cortex.mat'};
%                         matlabbatch{2}.spm.tools.beamforming.inverse.plugin.ebb.pairs = files.pairs;
                end
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
cd(files.root);
% cd('..')
go_close_non_spm_windows();
