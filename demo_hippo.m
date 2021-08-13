clearvars
close all
clc

% Uncomment the lines below to initialise SPM + DAiSS correctly
% addpath /path/to/spm12
% spm('defaults','eeg')
% spm_jobman('initcfg');

emptyD = '001.mat';
D = spm_eeg_load(emptyD);

%% Load the Source space generated and get every source in one hippocampus
g = D.inv{1}.mesh.tess_mni;

klust = spm_mesh_clusters(g.face,ones(length(g.vert),1));

id = find(klust==4);
vert = g.vert;
vert_h = vert(id,:);

%% Simulate uncorrelated pairs in every hippcampal homolog pair

complete = zeros(1,length(id));
steps = arange(1,8,length(id));

for ii = 1:length(steps)
    load complete_hipp.mat
    
    % Get which steps we are going to batch
    if ii == length(steps)
        runs = steps(ii);
    else
        runs = steps(ii):(steps(ii+1)-1);
    end
    
    % filter out the ones which are complete
    bads = zeros(length(runs),1);
    for jj = 1:length(runs)
        if complete(runs(jj))
            disp(['skipping iteration ' sprintf('%03d',runs(jj))]);
            bads(jj) = 1;
        end
    end
    
    runs(bads==1) = [];
    
    if ~isempty(runs)
        run_sims_hipp(D,vert_h(runs,:),runs);
        complete(runs) = 1;
    end
    save complete_hipp complete
    
end

%% Invert the solutions 

complete = zeros(1,length(id));
steps = arange(1,8,length(id));

for ii = 1:length(steps)
    load complete_hipp.mat
    
    % Get which steps we are going to batch
    if ii == length(steps)
        runs = steps(ii);
    else
        runs = steps(ii):(steps(ii+1)-1);
    end
    
    % filter out the ones which are complete
    bads = zeros(length(runs),1);
    for jj = 1:length(runs)
        if complete(runs(jj))
            disp(['skipping iteration ' sprintf('%03d',runs(jj))]);
            bads(jj) = 1;
        end
    end
    
    runs(bads==1) = [];
    
    if ~isempty(runs)
        run_inversions_hipp(runs);
        complete(runs) = 1;
    end
    save complete_hipp complete
    
end
%% Try and load results.

g = export(gifti('cortex_8196+hippocampus.gii'),'patch');

F = zeros(163,2);
nL = zeros(163,2);
rL = zeros(163,1);
D = zeros(163,1);

for ii = 1:163


    inversions = {'EBB','EBBcorr'};
    simtype = 'dual_uncorr';

    disp(['loading iteration ' sprintf('%03d',ii)]);

    % First lets work out where we think the sources we simulated are
    x = vert_h(ii,1);
    y = vert_h(ii,2);
    z = vert_h(ii,3);

    coords = [x y z;
        -x y z];

    [idx, ~] = knnsearch(g.vertices,coords);
    d = diff(g.vertices(idx,:));
    D(ii) = norm(d);

    for jj = 1:2

        files.BF = fullfile('D:\sims_256\hippo\proc',[sprintf('%03d',ii) '_' simtype '_-10dB'],inversions{jj},'BF.mat');
        BF = load(files.BF,'inverse');

        if jj == 1

           tmp = corrcoef(BF.inverse.MEG.L{idx(1)},BF.inverse.MEG.L{idx(2)});
           rL(ii) = tmp(1,2);
           nL(ii,:) = [norm(BF.inverse.MEG.L{idx(1)}) norm(BF.inverse.MEG.L{idx(2)})];

        end

        F(ii,jj) = BF.inverse.MEG.F;

    end
end

% %% work out which lobes simulations were, and which were hippocampal
% 
% g = export(gifti('D:\Documents\GitHub\EBBcorr\cortex_8196+hippocampus.gii'));
% id = find(g.vertices(:,1) >=0 );
% % Pick 256 of this bad boys (hey its a nice round number!)
% id_256 = id(round(linspace(1,numel(id),256)));
% vert_256 = g.vertices(id(round(linspace(1,numel(id),256))),:);
% 
% 
% d_256 = vnorm(vert_256,2);
% load lobe_parcels_8196.mat
% 
% [lobe_parcels{8197:length(g.vertices)}] = deal('hippocampus');
% 
% lobe_256 = {lobe_parcels{id_256}};
% 
% % special is/not hipp array
% hid = find(contains(lobe_256,'hippocampus'));
% ishipp = cell(numel(lobe_256),1);
% 
% [ishipp{:}] = deal('not hippocampus');
% [ishipp{hid}] = deal('hippocampus');
% 
% load 256_results.mat

%% Try and get distance between nearest sensor and source

BF = load('D:\sims_256\proc\001_dual_corr_-10dB\EBB\BF.mat');

pos = BF.sources.pos;
chans = BF.data.MEG.sens.chanpos;

pos256 = pos(id_256,:);
[~,Dchan] = knnsearch(chans,pos256);

%% Quick load and combine results from cortex and append hippocampal results

c = load('256_results.mat');
h = load('hipp_results.mat');

rL = c.rL(1:246,:);
rL = cat(1,rL,h.rL);

D = c.D(1:246,:);
D = cat(1,D,h.D);

F = c.F(1:246,:);
F = cat(1,F,h.F);

nL = c.nL(1:246,:);
nL = cat(1,nL,h.nL);

Ft = F(:,2) - F(:,1);

ishipp = cell(numel(Ft),1);
[ishipp{1:246}] = deal('not hippocampus');
[ishipp{247:numel(Ft)}] = deal('hippocampus');
    
%% Plot

cmap = [175 175 175;
    26 73 136]./255;

figure(100);clf
G = gramm('x',D,'y',rL,'color',ishipp);
G.geom_point();
G.set_color_options('map',cmap)
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
G.set_names('x','Source Separation / mm','y','Lead Field Correlation');
G.no_legend()
G.set_order_options('x',0,'color',0)
G.draw();

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
% G.stat_glm();
G.set_color_options('map',cmap)
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
G.set_names('x','Lead Field Correlation','y','?F (cEBB - EBB)');
G.set_order_options('x',0,'color',0)
G.no_legend()
G.draw();
% set(gcf,'position',[389   257   803   607])

% 
% Ft = F(:,2) - F(:,1);
% figure(250);clf
% G = gramm('x',Dchan,'y',Ft);
% G.geom_point();
% G.set_color_options('map',cmap(2,:))
% G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
% G.set_names('x','Distance from nearest sensor / mm','y','?F (cEBB - EBB)');
% % G.set_order_options('x',0,'color',0)
% G.no_legend()
% G.draw();
% set(gcf,'position',[389   257   803   607])

% Ft = F(:,2) - F(:,1);
% figure(300);clf
% G = gramm('x',Dchan,'y',Ft,'color',ishipp);
% G.geom_point();
% G.set_color_options('map',cmap)
% G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
% G.set_names('x','Distance from nearest sensor / mm','y','?F (cEBB - EBB)');
% G.set_order_options('x',0,'color',0)
% G.no_legend()
% G.draw();
% set(gcf,'position',[389   257   803   607])

figure(300);clf
G = gramm('x',D,'y',Ft,'color',ishipp);
G.geom_point();
G.set_color_options('map',cmap)
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
G.set_names('x','Source Separation / mm','y','?F (cEBB - EBB)');
G.set_order_options('x',0,'color',0)
G.no_legend()
G.draw();

figure(400);clf
G = gramm('x',mean(nL,2),'y',Ft,'color',ishipp);
G.geom_point();
% G.stat_glm();
G.set_color_options('map',cmap)
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12);
G.set_names('x','Lead Field Norm / fT','y','?F (cEBB - EBB)');
G.set_order_options('x',0,'color',0)
G.no_legend()
G.draw();

%% Try and plot where the dangerzones are on the hippocampus.

g = export(gifti('cortex_8196+hippocampus.gii'),'patch');

MS = spm_mesh_split(g);
HS(1) = MS(3);
HS(2) = MS(4);

hippMesh = spm_mesh_join(HS);



F_all = zeros(size(hippMesh.vertices,1),1);

for ii = 1:163

    x = hippMesh.vertices(ii,1);
    y = hippMesh.vertices(ii,2);
    z = hippMesh.vertices(ii,3);

    coords = [-x y z];

    [idx, ~] = knnsearch(hippMesh.vertices,coords);
    
    F_all([ii idx]) = h.F(ii,2)-h.F(ii,1);
%     F_all([ii idx]) = h.rL(ii);
    
end

% F_smooth = spm_mesh_smooth(hippMesh,double(F_all>0),0.5);
% F_smooth = F_all>0

F_face = mean(F_all(hippMesh.faces),2);

figure(400);clf
p = patch(hippMesh);
set(p,'FaceColor','flat','FaceVertexCData',double(F_face>0),'FaceLighting','phong');

set(gcf,'color','w')
colormap(flipud([228,26,28
    55,126,184]./255))
view([180 25])
% colorbar

axis equal
axis off
caxis([-0.2 1.2])

bads = find(hippMesh.vertices(:,2)>-15);

% 
% figure
% 
% meh = zeros(length(hippMesh.vertices),1);
% meh(bads) = 1;
% meh_faces = mean(meh(hippMesh.faces),2);
% 
% figure(400);clf
% p = patch(hippMesh);
% set(p,'FaceColor','flat','FaceVertexCData',double(meh_faces>0.3),'FaceLighting','phong');
% 
% set(gcf,'color','w')
% colormap(flipud(rdbu11))
% colorbar
% 
% axis equal
% axis off
% caxis([-0.2 1.2])

% save bads_hipp bads

%% Try and plot the radialness of a source;

o = [0.0060 5.6698e-04 0.0534]; 

g = export(gifti(D.inv{1}.mesh.tess_ctx),'patch');
id = find(g.vertices(:,1) >=0 );
% Pick 256 of this bad boys (hey its a nice round number!)
vert_256 = g.vertices(id(round(linspace(1,numel(id),256))),:);
vert_cortex = vert_256(1:246,:);

nrmls = spm_mesh_normals(g);
nrmls_256 = nrmls(id(round(linspace(1,numel(id),256))),:);
nrmls_cortex = nrmls_256(1:246,:);

klust = spm_mesh_clusters(g.faces,ones(length(g.vertices),1));
idhipp = find(klust==4);

vert_hipp = g.vertices(idhipp,:);
nrmls_hipp = nrmls(idhipp,:);


vert_all = cat(1,vert_cortex,vert_hipp);
vert_all = vert_all./vnorm(vert_all,2);

nrmls_all = cat(1,nrmls_cortex,nrmls_hipp);

ang = acosd(dot(vert_all',nrmls_all'))';

ida = find(ang>90);
ang(ida) = -ang(ida) + 180;

figure(500);clf
G = gramm('x',ang,'y',Ft,'color',ishipp);
G.geom_point();
G.set_color_options('map',cmap)
G.axe_property('plotboxaspectratio',[1 1 1],'Xgrid','on','ygrid','on','fontsize',12,'xlim',[-10 100],'xtick',[0 45 90],'xticklabels',{'radial','meh','tangential'});
G.set_names('x','Dipole radialness','y','?F (cEBB - EBB)');
G.set_order_options('x',0,'color',0)
G.no_legend()
G.draw();