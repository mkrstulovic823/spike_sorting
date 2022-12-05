% AmpC_Setup
%% Notes
% 04-Sep: rewriting to only fetch limited range of channels.  
%`19-02-21 IF USING CLEANNER UNCOMMENT AT 49
%% Manual settings - TYPE THESE IN AS NECESSARY

sett.chunk_size = 1e6;
sett.oe_sample_rate = 3e4; % Specify in Hz
sett.pos_sample_rate = 50; % Specify in Hz

sett.pre_stamp_ms   = 0.2; % Specify - number of milliseconds to look at before timestamp
sett.post_stamp_ms  = 1-sett.pre_stamp_ms; % Specify - number of milliseconds to look at after timestamp

%% Automatic "settings" - CHECK THESE EACH TIME
NPY_channel_map = readNPY('channel_map.npy');
n_channels = numel(NPY_channel_map);
%{
^ Note that the above should match your pre-processed waveform data file's 
dimensions. If there is any reason it wouldn't match the contents of 
channel_map.npy, change this manually. 
%}

sett.ch_range = 1:n_channels; 
%{
^ Should cover all valid "channels". For tetrodes, channels 1-4 correspond 
to tetrode 1, 2-8 to tetrode 2, etc.
%}

sett.datafile_name_string = 'spikes_recorded_concatenated.bin'; 
%{
^ Will search for above string to find file with pre-processed waveform 
data, using ls(). Can use '*' as wildcard for ls(). 
%}

sett.trial_folder = cd; 
%{ 
^ MATLAB's current directory should be the folder that contains the 
binary file with the spike waveforms, e.g. *ap_AP_medsub.bin. If you don't 
want to manually navigate to this folder each time, change the above 
to a given path -- code below will change current directory based on what 
you type above. 
%}

%% NPY file
% (Will still search for saved history)
NPY_spike_clusters_filename = 'spike_clusters.npy'; % Specify - can use NPY files produced by Amp during previous cutting sessions

%% Variables for analysis
cd(sett.trial_folder);

%%% Look for a "cleaned" cluster list (not always necessary)

% if exist('cleaner', 'dir') > 0 
if false
    autosort_results_folder = fullfile(sett.trial_folder, 'cleaner');
    clc;
    warning('Using ''cleaned up'' versions of clusters in...');
    for i = 5:-1:1
        disp(i);
        pause(0.01);
    end
else
    autosort_results_folder = sett.trial_folder;
end

%%% Search for waveform data using specified string, check if valid
datafile_name = ls(sett.datafile_name_string);
switch size(datafile_name, 1)
    case 0
        error('Couldn''t find ephys data file with appropriate name.'); 
    case 1
        disp('Found ephys data file.');
    otherwise
        error('Too many possible ephys data files.');
end
        
datafile = fullfile(sett.trial_folder,datafile_name);
Hd = designfilt('bandpassiir','FilterOrder',4,'HalfPowerFrequency1',500,'HalfPowerFrequency2',6000,'SampleRate',30000);
if Hd.SampleRate ~= sett.oe_sample_rate
    error('Check filter - correct programmed sample rates and frequencies before re-running.');
end

%% Get spike timestamps, templates
g = [];

% Note: These are made by Kilosort for use by Phy. 
disp('Reading spike timestamps and templates from NPY files...');
npy_spike_times = readNPY(fullfile(autosort_results_folder, 'spike_times.npy'));
npy_spike_templates = int16(readNPY(fullfile(autosort_results_folder, 'spike_templates.npy')));

s.stamps = (npy_spike_times); 
%%% ^ Timestamps for all spikes (regardless of cluster)
s.templates = (npy_spike_templates); 
%%% ^ Same length as s.stamps -- each spike's template assignation
disp('Timestamps and templates read from NPY files.');

%% Load save files (full cut history) OR npy files (previous final version)
disp('Searching for saves...');
flag_load_default = true; % Initial value - switch case 1 can falsify this
ampsave_name = ls('amp_*.mat'); % Search folder for Amp save files
switch size(ampsave_name, 1)
    case 1 % One Amp save file found
        msgbox(...
            ['Select save file to load on next screen. ',...
            '(If you don''t want to do this, press Cancel ',...
            'instead of selecting a file.)'],...
            'Save file detected!');
        fname = uigetfile('amp_*.mat');
        if fname == 0
            disp('No save file selected.');
        else
            load(fname, 'ampsave');
            s.clusters = int16(ampsave.s_clusters);
            clusters = (ampsave.cluster_list);
            if isa(clusters(1).ID,'double')
                for ui = 1:length(clusters)
                    clusters(ui).ID = int16(clusters(ui).ID);
                end
            end 
            disp('Loaded save file.');
            flag_load_default = false; % Only way to change initial cond.
        end
    case 0 % Amp save file not found
        disp('No save file detected.');
    otherwise % Too many possible Amp save files in folder
        disp('Too many possible save files detected.');
end

if flag_load_default == true % Default if no save used
    s.clusters = readNPY(...
        fullfile(autosort_results_folder, NPY_spike_clusters_filename)); 
    clusters = [];
end

%% Size check on loaded save vs. templates
assert(isequal(size(s.clusters, 1), numel(s.templates)), ... 
    ['Something is wrong with the specified clusters'' and ', ...
    'templates'' NPY files: size mismatch detected.']);
%%% ^ Both have to be equal to number of spikes

%% Account for old save method
if isequal(size(s.clusters), size(s.templates)) && ...
        ~isequaln(s.clusters, s.templates) 
    modded_inds = s.clusters(:, end) ~= 0;
    s.clusters(modded_inds, end) = s.clusters(modded_inds, end) + max(s.templates);
    s.clusters(~modded_inds, end) = s.templates(~modded_inds);
end

%% Find appropriate tetrode for each template/cluster
% MB this bit finds where is the max of the WF located for each template
disp('Finding best tetrode for each template...');
npy_templates = readNPY('templates.npy');
tmpIDs_1i = unique(s.templates) + 1; % Need +1 : MATLAB 1-indexing 
best_chs_1i = NaN(size(tmpIDs_1i)); best_chs_1i = best_chs_1i(:)';
channel_map_1i = NPY_channel_map + 1;
for i =1:length(tmpIDs_1i)
    tmpID = tmpIDs_1i(i); 
    tmp_wav = squeeze(npy_templates(tmpID,:,:));
    mxs = -1*tmp_wav(41,:); % Stamp should be at negative peak, at 41
    [~, i_best_ch] = max(mxs);
    ch_best = channel_map_1i(i_best_ch);
    best_chs_1i(tmpIDs_1i(i)) = ch_best; 
end
clear ch_best; % Prevents accidentally using the individual number later

%% Waveform file reading
tic;
int_type = 'int16';
test_num = zeros(1, int_type);
fll_test = whos('test_num');
n_bytes = fll_test.bytes;

w0 = cell2mat(get_wdw(0, sett.pre_stamp_ms, sett.post_stamp_ms, ...
    sett.oe_sample_rate));
wdw_width = length(w0);
w1_offset = w0(1);
fpos_all = ((s.stamps+w1_offset-1)*2*n_channels)';
len = length(fpos_all);

% MB loading only best tetrode to conserve RAM
s.rec = zeros(len, 4, wdw_width, 'int16'); 
s.tet = zeros(len, 1, 'int16');
fib2 = fopen(datafile);
for i = 1:len
    fpos = fpos_all(i);
    fseek(fib2, fpos, 'bof');
    try
        dat = fread(fib2, [n_channels, wdw_width], '*int16');
        ch = best_chs_1i(s.templates(i)+1);
        % Get tetrode pins to load, based on best channel
        ch_range = (floor((ch-1)/4)*4+1) ...
                  :(floor((ch-1)/4)*4+4);
        
        %get range here. take care of min max
        s.rec(i, :, :) = dat(ch_range, :);
        s.tet(i) = inv_tetch(ch);
    catch ME
        Beeper(3,1);
        if len - i > 10 % MB need to stop this fussing..
            keyboard;
        end
    end
    loadperc(i, len, 100);
end
fclose all;
Beeper(2,2);

%% Save settings structure to s, with additions
s.sett = sett;

%% Make all possible options for space in which to cut
disp('Calculating all space values for spikes...')

amp.max = max(s.rec, [], 3);
disp('Calculated maximum spike values (mode: ''max'').');
toc;
amp.min = min(s.rec, [], 3);
disp('Calculated minimum spike values (mode: ''min'').');
toc;
amp.abs = max(abs(cat(3, amp.max, amp.min)), [], 3);
disp('Calculated largest absolute values (mode: ''abs'').'); 
toc;
amp.range = amp.max-amp.min;
disp('Calculated ranges of spike values (mode: ''range'').');
toc;

%% Update list of cluster IDs and best tetrodes
clusters = AmpC_ClusterUpdate(s, g, clusters);
%% Clear all unnecessary variables
clearvars -except amp clusters s copy;