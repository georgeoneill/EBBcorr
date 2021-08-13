clearvars
close all
clc

% addpath /path/to/spm12
spm('defaults','eeg')
spm_jobman('initcfg');

emptyD = '001.mat';
snr = -10;

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

%% Generate the simulations and perform the source reconstruction

% warning: runing this requires about 2 GB of free disk space and takes
% about 15 mins to process everything.
run_sims_and_inversions(emptyD,snr);
cd  'D:\Documents\GitHub\EBBcorr'
%% Visualise the results

run_visualise_results(snr);