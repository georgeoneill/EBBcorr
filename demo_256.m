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

%% Load the Source space generated and get every source where X > 0

vert = D.inv{1}.mesh.tess_mni.vert;
id = find(vert(:,1) >=0 );
% Pick 256 of this bad boys (hey its a nice round number!)
vert_256 = vert(id(round(linspace(1,numel(id),256))),:);

complete = zeros(1,256);

for ii = 1:256
    load complete.mat
    if ~complete(ii)
        run_sims_256(D,vert_256(ii,:),ii);
        run_inversions_256(ii);
        complete(ii) = 1;
        save complete complete
    else
        disp(['skipping iteration ' sprintf('%03d',ii)]);
    end
end

%% Try and load results.

g = export(gifti('D:\Documents\GitHub\EBBcorr\cortex_8196+hippocampus.gii'));

% F = zeros(256,2);
% nL = zeros(255,2);
% rL = zeros(256,1);
% D = zeros(256,1);
% 
% for ii = 1:256
%    
%     
%     inversions = {'EBB','EBBcorr'};
%     simtype = 'dual_uncorr';
%     
%     disp(['loading iteration ' sprintf('%03d',ii)]);
%     
%     % First lets work out where we think the sources we simulated are
%     x = vert_256(ii,1);
%     y = vert_256(ii,2);
%     z = vert_256(ii,3);
%     
%     coords = [x y z;
%         -x y z];
%     
%     [idx, ~] = knnsearch(g.vertices,coords);
%     d = diff(g.vertices(idx,:));
%     D(ii) = norm(d);
%     
%     for jj = 1:2
%         
%         files.BF = fullfile('D:\sims_256\proc',[sprintf('%03d',ii) '_' simtype '_-10dB'],inversions{jj},'BF.mat');
%         BF = load(files.BF,'inverse');
%         
%         if jj == 1
%             
%            tmp = corrcoef(BF.inverse.MEG.L{idx(1)},BF.inverse.MEG.L{idx(2)});
%            rL(ii) = tmp(1,2);
%            nL(ii,:) = [norm(BF.inverse.MEG.L{idx(1)}) norm(BF.inverse.MEG.L{idx(2)})];
%            
%         end
%         
%         F(ii,jj) = BF.inverse.MEG.F;
%         
%     end
% end

%% work out which lobes simulations were, and which were hippocampal

g = export(gifti('D:\Documents\GitHub\EBBcorr\cortex_8196+hippocampus.gii'));
id = find(g.vertices(:,1) >=0 );
% Pick 256 of this bad boys (hey its a nice round number!)
id_256 = id(round(linspace(1,numel(id),256)));
vert_256 = g.vertices(id(round(linspace(1,numel(id),256))),:);


d_256 = vnorm(vert_256,2);
load lobe_parcels_8196.mat

[lobe_parcels{8197:length(g.vertices)}] = deal('hippocampus');

lobe_256 = {lobe_parcels{id_256}};

% special is/not hipp array
hid = find(contains(lobe_256,'hippocampus'));
ishipp = cell(numel(lobe_256),1);

[ishipp{:}] = deal('not hippocampus');
[ishipp{hid}] = deal('hippocampus');

load 256_results.mat

%% Try and get distance between nearest sensor and source

BF = load('D:\sims_256\proc\001_dual_corr_-10dB\EBB\BF.mat');

pos = BF.sources.pos;
chans = BF.data.MEG.sens.chanpos;

pos256 = pos(id_256,:);
[~,Dchan] = knnsearch(chans,pos256);

%% Plot

cmap = [220 220 220;
        26 73 136]./255;

% figure(100);clf
% G = gramm('x',D,'y',rL,'color',ishipp);
% G.geom_point();
% G.set_color_options('map',cmap)
% G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
% G.set_names('x','Source Separation / mm','y','Lead Field Correlation');
% G.no_legend()
% G.set_order_options('x',0,'color',0)
% G.draw();

Ft = F(:,2) - F(:,1);
figure(150);clf
G = gramm('x',rL,'y',Ft);
G.geom_point();
G.set_color_options('map',cmap(2,:))
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
G.set_names('x','Lead Field Correlation','y','?F (cEBB - EBB)');
% G.set_order_options('x',0,'color',0)
G.no_legend()
G.draw();
% set(gcf,'position',[389   257   803   607])

Ft = F(:,2) - F(:,1);
figure(200);clf
G = gramm('x',rL,'y',Ft,'color',ishipp);
G.geom_point();
G.set_color_options('map',cmap)
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
G.set_names('x','Lead Field Correlation','y','?F (cEBB - EBB)');
G.set_order_options('x',0,'color',0)
G.no_legend()
G.draw();
% set(gcf,'position',[389   257   803   607])


Ft = F(:,2) - F(:,1);
figure(250);clf
G = gramm('x',Dchan,'y',Ft);
G.geom_point();
G.set_color_options('map',cmap(2,:))
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
G.set_names('x','Distance from nearest sensor / mm','y','?F (cEBB - EBB)');
% G.set_order_options('x',0,'color',0)
G.no_legend()
G.draw();
% set(gcf,'position',[389   257   803   607])

Ft = F(:,2) - F(:,1);
figure(300);clf
G = gramm('x',Dchan,'y',Ft,'color',ishipp);
G.geom_point();
G.set_color_options('map',cmap)
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
G.set_names('x','Distance from nearest sensor / mm','y','?F (cEBB - EBB)');
G.set_order_options('x',0,'color',0)
G.no_legend()
G.draw();
% set(gcf,'position',[389   257   803   607])

% figure(300);clf
% G = gramm('x',D,'y',Ft,'color',ishipp);
% G.geom_point();
% G.set_color_options('map',cmap)
% G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
% G.set_names('x','Source Separation / mm','y','?F (cEBB - EBB)');
% G.set_order_options('x',0,'color',0)
% G.no_legend()
% G.draw();

figure(400);clf
G = gramm('x',mean(nL,2),'y',Ft,'color',ishipp);
G.geom_point();
G.set_color_options('map',cmap)
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
G.set_names('x','Lead Field Norm / fT','y','?F (cEBB - EBB)');
G.set_order_options('x',0,'color',0)
G.no_legend()
G.draw();