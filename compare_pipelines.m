function [F, R2, data] = compare_pipelines(snr)

[files.root,~,~] = fileparts(mfilename('fullpath'));

inversions = {'EBB','EBBcorr'};
simtype = {'dual_corr'};
pipeline = {'old','new'};

clear F
clear R2

for ii = 1:numel(pipeline)
    for jj = 1:numel(simtype)
        for kk = 1:numel(inversions)
            
            switch pipeline{ii}
                case 'old'
                    files.oldroot = 'D:\Documents\ebb_corr\paper_sims\DAiSS\replicator';
                    files.results = fullfile(files.oldroot,[simtype{jj} '_' num2str(snr) 'dB'],'4_tmodes',inversions{kk});
                case 'new'
                    files.results = fullfile(files.root,'proc',[simtype{jj} '_' num2str(snr) 'dB'], inversions{kk});
            end
            
            fprintf('%s -> %s -> %s\n',pipeline{ii},inversions{kk},simtype{jj});
            
            files.BF = fullfile(files.results,'BF.mat');
            BF = load(files.BF,'data','inverse');
            F.(pipeline{ii}).(inversions{kk}) = BF.inverse.MEG.F;
            try
            R2.(pipeline{ii}).(inversions{kk}) = BF.inverse.MEG.R2;
            catch
            end
        end
    end
    
%     feats.(pipeline{ii}) = BF.features.MEG;
    data.(pipeline{ii}) = BF.data;
    F.(pipeline{ii}).diff =  F.(pipeline{ii}).EBBcorr - F.(pipeline{ii}).EBB; 
end

figure
x = categorical(pipeline);
bar(x,[F.old.diff F.new.diff]);
ylabel('Change in model evidence')
grid on