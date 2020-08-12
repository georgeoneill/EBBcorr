function D = go_eeg_touch(S)
% Prototype tool for generating M/EEG datasets with template/user specified
% anatomical and sensor layouts, with empty data arrays in preperation for
% simulations.
% FORMAT D = spm_eeg_touch(S)
%   S               - input structure
% FILE OPTIONS
%   S.filename      - path + filename of target MEEG object (REQUIRED)
%   S.modality      - modality choice ('meg'|'eeg'|'opm')
%                                                   - Default 'meg'
% STRUCTURAL OPTIONS
%   S.sMRI          - Structural MRI                - Default: 1 (template)
%   S.meshres       - cortical mesh density (1,2,3) - Default: 2
%   S.voltype       - conductive model type         - Default: ?
% DATA OPTIONS
%   S.fs            - sampling frequency (Hz)       - Default: 1200
%   S.ntrials       - number of trials              - Default: 1
%   S.duration      - length of trial (s)           - Default: 0
%   S.prestim       - trial prestimulation (s)      - Default: 0
% MODALITY SPECIFIC OPTIONS
%   S.meg.sensors   - sesnors struct from D.sensors     (REQUIRED)
%   S.meg.fiducials - sesnors struct from D.fiducials   (REQUIRED)
% Output:
%   D               - MEEG object (also written to disk)
%__________________________________________________________________________
% Copyright (C) 2020 Wellcome Centre for Human Neuroimaging

% George O'Neill
% $Id$

spm('FnBanner', mfilename);

%-Set default values
%--------------------------------------------------------------------------
if ~isfield(S,'filename');  error('please supply a path to save to!');  end
if ~isfield(S,'modality');      S.modality = 'meg';                     end
if ~isfield(S,'sMRI');          S.sMRI = 1;                             end
if ~isfield(S,'meshres');       S.meshres = 2;                          end
if ~isfield(S,'fs');            S.fs = 1200;                            end
if ~isfield(S,'ntrials');       S.ntrials = 1;                          end
if ~isfield(S,'duration');      S.duration = 0;                         end
if ~isfield(S,'prestim');       S.prestim = 0;                          end

%-The room where it happens
%--------------------------------------------------------------------------
switch lower(S.modality)
    case 'meg'
        
        % Quick modality specific options;
        if ~isfield(S,'voltype');      S.voltype = 'Single Shell';      end
        if ~isfield(S.(S.modality),'sensors')
                          error('please supply sensor struture');       end
        if ~isfield(S.(S.modality),'fiducials')
                          error('please supply sensor struture');       end
        
        
        [a b] = fileparts(S.filename);
        
        if exist(fullfile(a, [b '.mat'])); delete(fullfile(a, [b '.mat'])); end
        if exist(fullfile(a, [b '.dat'])); delete(fullfile(a, [b '.dat'])); end
        
        nsamples = S.fs*S.triallength;
        
        D = meeg(numel(S.(S.modality).sensors.label),nsamples,S.ntrials);
        D = D.fsample(S.fs);
        D = D.timeonset(-S.prestim);
        D = D.fname(b);
        D = D.path(a);
        D = D.sensors('MEG',S.(S.modality).sensors);
        D = D.fiducials(S.(S.modality).fiducials);
        
        for ii = 1:numel(S.(S.modality).sensors.chantype)
            D = D.chanlabels(ii,S.(S.modality).sensors.label{ii});
            D = D.chantype(ii,upper(S.(S.modality).sensors.chantype{ii}));
            D = D.units(ii,upper(S.(S.modality).sensors.chanunit{ii}));
        end
                
        D = blank(D); % Generates the .dat file.
        
        % sMRI = fullfile(spm('dir'),'canonical','single_subj_T1.nii');
        % Anatomical preprocessing, generates boundary meshes and fiducials
        D = spm_eeg_inv_mesh_ui(D,1,S.sMRI,S.meshres);
        
        % Coregister the mofo
        meegfid = D.fiducials;
        selection = spm_match_str(meegfid.fid.label, {'nas','lpa','rpa'});
        meegfid.fid.pnt = meegfid.fid.pnt(selection, :);
        meegfid.fid.label = meegfid.fid.label(selection);
        
        mrifid = [];
        mrifid.pnt = D.inv{1}.mesh.fid.pnt;
        mrifid.fid.pnt = [];
        mrifid.fid.label = meegfid.fid.label;
        selection = spm_match_str(D.inv{1}.mesh.fid.fid.label, {'nas','FIL_CTF_L','FIL_CTF_R'});
        mrifid.fid.pnt = D.inv{1}.mesh.fid.fid.pnt(selection, :);

        D = spm_eeg_inv_datareg_ui(D, 1, meegfid, mrifid, 0);
        
        % Generate the conductive model.
        D.inv{1}.forward.voltype = S.voltype;
        D = spm_eeg_inv_forward(D);
        spm_eeg_inv_checkforward(D,1,1);
                
    otherwise
        error('modality %s is currently unsupported!',S.modality);
end

save(D);