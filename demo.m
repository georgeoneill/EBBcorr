clearvars
close all
clc

% Uncomment the lines below to initialise SPM + DAiSS correctly
% addpath /path/to/spm12
% spm('defaults','eeg')
% spm_jobman('initcfg');

emptyD = '001.mat';

%% Generate an empty dataset to base simulated data on

load('ctf_sensors.mat');

S = [];
S.fs = 1200;
S.ntrials = 10;
S.triallength = 7; % in seconds plz
S.prestim  = 2; % how much is prestim? in this case this makes the time range is -0.5 to 1.5.
S.meg.sensors = sensors;
S.meg.fiducials = fiducials;
S.filename = emptyD;

D = go_eeg_touch(S);

% Add the custom cortical mesh

S = [];
S.D = D;
S.cortex = fullfile(pwd,'cortex_8196+hippocampus.gii');
D = go_add_mni_cortex(S);

%% Generate the simulations and perform the source reconstruction

% warning: runing this requires about 2 GB of free disk space and takes
% about 15 mins to process everything.
for snr = -40:5:0
    clc
    fprintf("running simulations and inversions for snr = %d\n",snr)
    run_inversions('heschl',snr,'inversiononly');
    run_inversions('hippbody',snr,'inversiononly');
    run_inversions('hippocampus',snr,'inverseonly');
end


% load('D:\Documents\GitHub\EBBcorr\sourcetest\proc\heschl\dual_corr_-20dB\EBB_uncorr\BF.mat','inverse');
% Fu = inverse.MEG.F;
% load('D:\Documents\GitHub\EBBcorr\sourcetest\proc\heschl\dual_corr_-20dB\EBB_corr_uncorr_on\BF.mat','inverse');
% Fc = inverse.MEG.F;
% 
% dF = Fc - Fu

error('fin')
%% Load the results

simtype = {'mono','dual_uncorr','dual_corr'};
location = 'hippocampus';
snr = -40:5:0;

inversions = {'EBB_uncorr','EBB_corr'};

files.root = 'D:\Documents\GitHub\EBBcorr\proc';

% load(fullfile(files.root,'results.mat'));
%
% F = simresults.(location).(simtype).F;
% R2 = simresults.(location).(simtype).F;

for kk = 1:numel(simtype)
    count = 0;
    for ii = 1:numel(snr)
        for jj = 1:numel(inversions)
            
            count = count + 1;
            disp(count)
            
            files.BF = fullfile(files.root,location,...
                [simtype{kk} '_' num2str(snr(ii)) 'dB'],inversions{jj},'BF.mat');
            
            load(files.BF,'inverse')
            
            F(ii,jj) = inverse.MEG.F;
            try
                R2(ii,jj) = inverse.MEG.R2;
            catch
                R2(ii,jj) = NaN;
            end
        end
    end
    
    if exist(fullfile(files.root,'results.mat'))
        load(fullfile(files.root,'results.mat'));
    end
    simresults.(location).(simtype{kk}).F = F;
    simresults.(location).(simtype{kk}).R2 = F;
    simresults.(location).(simtype{kk}).snr = snr;
    simresults.(location).(simtype{kk}).inversions = inversions;
    save(fullfile(files.root,'results.mat'),'simresults');
end
%% Plot some stuff.
cmap = [26 73 136;
    205 3 3;
    202 141 4;
    77 155 1]./255;

% go_close_non_spm_windows
% for ii = 1:4

f = F(:,2:end) - F(:,1);

figure(2)
clf; hold on
for ii = 1:4
    plot(snr,f(:,ii),'linewidth',2,'color',cmap(ii,:));
end

grid on

% end

figure(10)
hold on
cmap2 = [0 0 0; cmap];
for ii = 1:5
    plot(snr,R2(:,ii),'linewidth',2,'color',[cmap2(ii,:)]);
end
ylim([95 100])

%% See if we can use Gramm to plot...?

simtype = 'dual_uncorr';
location = 'hippocampus';
snr = -50:5:0;

inversions = {'EBB_uncorr','EBB_corr_uncorr_on',...
    'EBB_corr_uncorr_both','EBB_corr_on','EBB_corr_both'};

files.root = 'D:\Documents\GitHub\EBBcorr\proc';

load(fullfile(files.root,'results.mat'));

F = simresults.(location).(simtype).F;
% R2 = simresults.(location).(simtype).R2;


f = F(:,2:end) - F(:,1);

cmap = [26 73 136;
    205 3 3;
    202 141 4;
    77 155 1]./255;

invs = cell(1,44);
[invs{1:11}] = deal('Corr (On Diags) +  Uncorr');%,'Hipp only'},22,1);
[invs{12:22}] = deal('Corr (On + Off Diags) + Uncorr');%,'Hipp only'},22,1);
[invs{23:33}] = deal('Corr (On Diags)');%,'Hipp only'},22,1);
[invs{34:44}] = deal('Corr (On + Off Diags)');%,'Hipp only'},22,1);

X = repmat(snr,1,4)';
figure(100);clf
clear g
g(1,1) = gramm('x',X(:),'y',f(:),'color',invs);
g(1,1).stat_summary('geom',{'bar','black_errorbar'})
g(1,1).set_names('x','SNR / dB','y','?F (Correlated Model - EBB)','color','Correlated Model');
g(1,1).set_title([simtype '/' location]);
g(1,1).axe_property('Xgrid','on','ygrid','on','plotboxaspectratio',[2 1 1],'fontsize',12,'ylim',[-20 20]);
%     g(1,1).set_color_options('hue_range',[-90 50],'chroma',100,'lightness',50);
g(1,1).set_color_options('map',cmap);
g(1,1).set_order_options('x',0,'color',0)
% g.no_legend();
g.draw();
set(gcf,'position',[ 404   301   996   557])