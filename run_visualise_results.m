function run_visualise_results(snr)

% First, work out where we are
[files.root,~,~] = fileparts(mfilename('fullpath'));

inversions = {'IID','EBB','EBBcorr'};
simtype = {'mono','dual_uncorr','dual_corr'};

fprintf('Loading results for snr = %d dB\n',snr);

figure;
count = 0;
sub_order = [1 4 7 2 5 8 3 6 9];
for ii = 1:numel(inversions)
    for jj = 1:numel(simtype)
        
        files.results = fullfile(files.root,'proc',[simtype{jj} '_' num2str(snr) 'dB'], inversions{ii});
        files.BF = fullfile(files.results,'BF.mat');
        
        if ~exist(files.BF,'file')
            error('results file for %s reconstruction of %s missing!',inversions{ii},simtype{jj});
        else
            fprintf('%s -> %s\n',inversions{ii},simtype{jj});
            count = count + 1;
        end
        
        BF = load(files.BF,'inverse');
        F(ii,jj) = BF.inverse.MEG.F;
        
%         subplot(3,3,sub_order(count))
%         S = [];
%         S.ndips = 512;
%         S.cmap = 'gray';
%         go_view_glass(BF,S);
        title(sprintf('%s -> %s',inversions{ii},simtype{jj}));
        
    end
end

figure;
subplot(121);
x = categorical({'Mono','Dual Uncorr','Dual Corr'});
Ftemp = F(1,:) - F(2,:);
bar(x,Ftemp);
ylabel('Model Evidence: F(IID) - F(EBB)')
subplot(122);
Ftemp = F(3,:) - F(2,:);
bar(x,Ftemp);
ylabel('Model Evidence: F(EBBcorr) - F(EBB)')