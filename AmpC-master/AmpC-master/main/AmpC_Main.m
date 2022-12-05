%% Main program
function g = AmpC_Main(amp, clusters, s)
    g.ncd = 4; 
    g.chcom = 1; 
    g.chfin = size(s.rec, 2); 
%     g.chpin = @(ch,pin)(floor((ch-1)/4)*4+pin);
    g.chpin = @(ch,pin)pin;
    
    g.amp = amp;
    g.clusters = clusters;
    g.s = s;
    
    g.amp_start_time = ...
        sprintf('%04.f-%02.f-%02.f_%02.f-%02.f-%02.f', clock);
    g.save_name = ['spike_clusters_amp_' g.amp_start_time '.npy'];
    
    g.colours = 'rgbcmyk';
    
    % Amplitude space figure
    g.AmpSpace.fig = figure(1);
    figsize(g.AmpSpace.fig, [0.5, 0, 0.5, 1]);
    clf;
    
    % Waveform display figure
    g.Waveform.fig = figure(2);
    figsize(g.Waveform.fig, [0.25, 0.25, 0.25, 0.75]);
    clf; 

    g.Waveform.bg_mean = uibuttongroup;
    uicontrol('Parent',       g.Waveform.bg_mean, ...
              'Style',        'radiobutton', ...
              'String',       'Mean waveform', ...
              'Position',     [10, 10, 100, 30]);
    uicontrol('Parent',       g.Waveform.bg_mean, ...
              'Style',        'radiobutton', ...
              'String',       'All waveforms', ...
              'Position',     [120, 10, 100, 30]);
  
    set(g.Waveform.bg_mean, 'SelectionChangedFcn', @cb_AmpC_Disp);
    
    g.Waveform.eq_ylims = uicontrol(...
        'Parent',   g.Waveform.fig, ...
        'Style',    'checkbox', ...
        'String',   'Equal scale', ...
        'Position', [250, 10, 100, 30], ...
        'Callback', @cb_AmpC_Disp);
    
    
    %%%
    start_wh = 0.19;
    end_wh = 0.925;
    col_height = end_wh-start_wh;
    w_wh = col_height/(1.4*g.ncd-0.4);
    w_gr = 0.4*w_wh;
    start_l = start_wh-w_gr/2;
    end_l = end_wh+w_gr/2;
    height_l = end_l-start_l;
    
    val_prefix = cell(0);
    val_prefix{1} = 'A'; % Add any further values here
    val_prefix{2} = 'Vt';
    
    n = 0;
    n_vals = length(val_prefix);
    
    
    
    for i_val = 1:n_vals
        for pin = 1:4
            n = n+1;
            val_name = [val_prefix{i_val}, num2str(pin)];
            val_name = val_name(~isspace(val_name));
            g.Waveform.tog(n) = uicontrol(...
                'Style',    'checkbox', ...
                'Units',    'normalized', ...
                'String',   val_name, ...
                'Tag',      val_name, ...
                'Position', [0.9, ...
                    start_l + midstripe(height_l, g.ncd, g.ncd+1-pin) + ...
                        (midstripe(w_wh*[-0.5,0.5],n_vals,n_vals+1-i_val)), ...
                    0.1, 0.02]);
        end
    end
    
    %%%
    
    for i = 1:length(g.Waveform.tog)
        set(g.Waveform.tog(i), ...
            'Callback',     @cb_tog);
        if contains(g.Waveform.tog(i).Tag, 'A')
            set(g.Waveform.tog(i), ...
                'Value',        1);
        elseif contains(g.Waveform.tog(i).Tag, 'Vt')
            set(g.Waveform.tog(i), ...
                'Value',        0);
        end
    end
    
    
    % Interspike histogram figure
    g.ISI.fig = figure(3);
    figsize(g.ISI.fig, [0, 0.5, 0.25, 0.5]);
    clf;
    
    txt_maxint = uicontrol(...
        'Style',        'text', ...
        'String',       'Maximum interval (ms)', ...
        'Parent',       g.ISI.fig, ...
        'Position',     [10 10 140 20]);
    edit_maxint = uicontrol(...
        'Style',        'edit', ...
        'Units',        'pixels', ...
        'Tag',          'maxint', ...
        'Parent',       g.ISI.fig, ...
        'Position',     [150 10 30 20], ...
        'Callback',     @cb_ISI);
    g.ISI.maxint =      500; 
    set(edit_maxint, ...
        'String',       num2str(g.ISI.maxint));
    
    txt_binwidth = uicontrol(...
        'Style',        'text', ...
        'String',       'Bin width (ms)', ...
        'Parent',       g.ISI.fig, ...
        'Position',     [200 10 80 20]);
    edit_binwidth = uicontrol(...
        'Style',        'edit', ...
        'Units',        'pixels', ...
        'Tag',          'binwidth', ...
        'Parent',       g.ISI.fig, ...
        'Position',     [280 10 30 20], ...
        'Callback',     @cb_ISI);
    g.ISI.binwidth =    10; 
    set(edit_binwidth, ...
        'String',       num2str(g.ISI.binwidth));
    
    g.ISI.toggle = uicontrol(...
        'Style',        'checkbox', ...
        'String',       'Toggle on/off',...
        'Parent',       g.ISI.fig, ...
        'Position',     [330 10 100 30],...
        'Value',        1, ...
        'Callback',     @cb_AmpC_Disp);
    
    g.dispIDs = [];
    
    % Choose amplitude space to use
    space_names = fieldnames(g.amp);
    [opt_measure] = listdlg('ListString', space_names, 'SelectionMode', 'single');
    g.s.amp = g.amp.(space_names{opt_measure});
    
    
    % Update clusters (and relevant g elements)
    g.clusters = AmpC_ClusterUpdate(g.s, g, g.clusters);
    
    % Interaction window
    g.ui.fig = figure(10); 
    figsize(g.ui.fig, [0, 0, 0.25, 0.5]);
    clf;
    
    g.ui.ls_tmp    = uicontrol('Style', 'listbox', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.05, 0.4, 0.25, 0.5], 'Max', 100, 'Callback', @fill_inbox);
    g.ui.ls_new    = uicontrol('Style', 'listbox', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.35, 0.4, 0.25, 0.5], 'Max', 100, 'Callback', @fill_inbox);
        all_IDs = [g.clusters.ID];
        all_names = {g.clusters.name};
        all_chcs = {g.clusters.chc};
        try
            valid_idxs = ismember((all_IDs), g.s.clusters(:, end));
        catch
            valid_idxs = ismember(int16(all_IDs), g.s.clusters(:, end));
        end
            all_IDs = all_IDs(valid_idxs);
            all_names = all_names(valid_idxs);
            all_chcs = all_chcs(valid_idxs);
        tmp_idxs = ismember(int16(all_IDs), g.s.templates);
            tmp_names   = all_names(tmp_idxs);
            tmp_chcs    = all_chcs(tmp_idxs);
            
            new_names   = all_names(~tmp_idxs);
            new_chcs    = all_chcs(~tmp_idxs);
            
            tmp_disp = cellfun(@(c1, c2) [c1 ' (tet ' num2str(c2) ')'], tmp_names, tmp_chcs, 'UniformOutput', false);
            new_disp = cellfun(@(c1, c2) [c1 ' (tet ' num2str(c2) ')'], new_names, new_chcs, 'UniformOutput', false);
        set(g.ui.ls_tmp, 'String', tmp_disp, 'Value', []);
        set(g.ui.ls_new, 'String', new_disp, 'Value', []);
    
    btn.split   = uicontrol('Style', 'pushbutton', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.65, 0.8, 0.13, 0.1],   'String', 'Split...');
    btn.merge   = uicontrol('Style', 'pushbutton', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.8, 0.8, 0.13, 0.1],    'String', 'Merge...');
    btn.denoise = uicontrol('Style', 'pushbutton', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.65, 0.68, 0.28, 0.1],  'String', 'Magically reduce noise...');
    btn.undo    = uicontrol('Style', 'pushbutton', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.65, 0.56, 0.28, 0.1],  'String', 'Undo...');
    btn.save    = uicontrol('Style', 'pushbutton', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.65, 0.4, 0.13, 0.1],   'String', 'Save...');
    btn.exit    = uicontrol('Style', 'pushbutton', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.8, 0.4, 0.13, 0.1],    'String', 'Exit...');
        btn_names = fieldnames(btn);
        for i = 1:length(btn_names)
            btn.(btn_names{i}).Tag = btn_names{i};
            set(btn.(btn_names{i}), 'Callback', @fill_inbox);
        end
    
    g.ui.inbox     = uicontrol('Style', 'edit', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.05, 0.25, 0.88, 0.05], 'HorizontalAlignment', 'left');
        set(g.ui.inbox, 'KeyPressFcn', @check_inbox);
    g.ui.msg       = uicontrol('Style', 'text', 'Parent', g.ui.fig, 'Units', 'normalized', 'Position', [0.05, 0.15, 0.88, 0.05], 'String', 'No new messages', 'HorizontalAlignment', 'left');
    
    
    guidata(g.ui.fig, g);
    
    function check_inbox(~, evt)
        if strcmp(evt.Key, 'return')
            pause(0.1);
            input2cmd;
        end
    end

    function fill_inbox(src, ~)
        cmd = src.Tag;
        cmd_vars = {};
        clear l;
        if ~isempty(g.ui.ls_tmp.String)
            l = g.ui.ls_tmp;
            cmd_vars = [cmd_vars, cellfun(@(C) C{1}, regexpi(l.String(l.Value), '[A-Z0-9]*', 'match'), 'UniformOutput', 0)'];
        end
        if ~isempty(g.ui.ls_new.String)
            l = g.ui.ls_new;
            cmd_vars = [cmd_vars, cellfun(@(C) C{1}, regexpi(l.String(l.Value), '[A-Z0-9]*', 'match'), 'UniformOutput', 0)'];
        end
        set(g.ui.inbox, 'String', strjoin([cmd, cmd_vars]));
        pause(0.1);
        input2cmd;
    end
    
    % Input conversion to command + vars
    function input2cmd
        input_txt = g.ui.inbox.String;
        [g.cmd, g.cmd_vars] = cmd_listen(input_txt);
        if ~isempty(g.cmd{1})
            switch g.cmd{1}
                
                
                case {'select'}
                    [IDs, msg] = ID_check();
                    if ~isempty(IDs)
                        g.dispIDs = IDs;
                        g = AmpC_Disp(g);
                    end
                    g.ui.msg.String = msg;
                    
                    
                    
                case {'split'}
                    [IDs, msg] = ID_check(1);
                    if ~isempty(IDs)
                        g.dispIDs = IDs;
                        [g]  = AmpC_Split(g);
                    end
                    g.ui.msg.String = msg;
                    
                    
                    
                    
                case {'merge'}
                    [IDs, msg] = ID_check(2);
                    if ~isempty(IDs)
                        g.dispIDs = IDs;
                        [g] = AmpC_Merge(g);
                    end
                    g.ui.msg.String = msg;
                    
                    
                    
                case {'undo'}
                    g.ui.inbox.String = g.cmd{1};
                    [g] = AmpC_Undo(g);
                    
                    
                    
                    
                    
                case {'denoise'}
                    [IDs, msg] = ID_check(1);
                    if ~isempty(IDs)
                        g.dispIDs = IDs;
                        [g]  = AmpC_Denoise(g);
                    end
                    g.ui.msg.String = msg;
                    
                    
                case {'save'}
                    g.ui.inbox.String = g.cmd{1};
                    g = AmpC_Save(g);
                    
                    
                    
                    
                
                case {'exit'}
                    % Placeholder
                    g.ui.inbox.String = g.cmd{1};
                    g = AmpC_Exit(g);
                    
                    
                    
                    
                otherwise
                    g.ui.msg = ('Can''t do that yet!');
            end
        end
        % Command interpreter (NB// nested within input2cmd)
        function [cmd, cmd_vars] = cmd_listen(input_txt)
            list_cmds = {
                'select';
                'exit';
                'split';
                'undo';
                'merge';
                'save';
                'denoise'
                };
            input_words = regexp(input_txt, '\w*', 'match');
            cmd = list_cmds(ismember(list_cmds, input_words));
            if length(cmd)>1
                cmd = {};
            elseif isempty(cmd)
                cmd = {'select'};
            end

            cmd_vars = input_words(~ismember(input_words, list_cmds));
        end
        % Check validity of requested cluster IDs (NB// nested within input2cmd)
        function [out, msg] = ID_check(n_IDs)
            g.cmd_vars = unique(g.cmd_vars);
            out = [];
            msg = [];
            if isempty(g.cmd_vars)
                msg = 'No cluster name(s)/ID(s) found in input.';
            elseif exist('n_IDs', 'var') && length(g.cmd_vars) ~= n_IDs
                msg = 'Wrong number of clusters for requested function..';
%                 disp(n_IDs)
            else
                [La, Lb] = ismember(g.cmd_vars, {g.clusters.name});
                if sum(La) == length(g.cmd_vars)
                    out = Lb;
                else
                    testIDs = str2double(g.cmd_vars);
                    [La, Lb] = ismember(testIDs, [g.clusters.ID]);
                    if sum(La) == length(testIDs)
                        out = Lb;
                    else
                        msg = '>=1 cluster name(s)/ID(s) entered was/were invalid.';
                    end
                end
            end
            if ~isempty(out)
                out = [g.clusters(out).ID];
                if sum(ismember(double(out), double(g.s.clusters(:, end))))~=length(out)
                    out = [];
                    msg = '>=1 clusters referred to in input have been deleted (by split/merge/undo operations).';
                end
            end
        end
    end

    function cb_ISI(src, ~)
        if ismember(src.Tag, {'maxint', 'binwidth'})
            ISI.val_name = src.Tag;
        end
        if ~isempty(str2double(src.String))
            g.ISI.(ISI.val_name) = str2double(src.String);
        else
            set(src, 'String', '');
        end
        g = AmpC_Disp(g);
    end

    function cb_tog(src, ~)
        if contains(src.Tag, 'Vt')
            switch src.Value
                case 0
                    src.UserData = [];
                case 1
                    pin_s = cell2mat(regexp(src.Tag, '[0-9]*', 'match'));
                    [~, loc] = ismember(get(g.Waveform.fig.Children, 'Type'), {'uipanel'});
                    wavax_h = get(g.Waveform.fig.Children(find(loc)), 'Children');
                    h_idx = find(contains({wavax_h.Tag}, pin_s), 1);
                    wavax_s = wavax_h(h_idx);
                    original_title = wavax_s.Title.String;
                    title(wavax_s, 'Select time point');
                    point = round(ginput(1));
                    src.UserData = point(1);
                    title(wavax_s, original_title);
                    plot(wavax_s, ...
                        [src.UserData, src.UserData], ...
                        [wavax_s.YLim(1), wavax_s.YLim(2)], ...
                        'LineStyle', ':');
            end
        end
        g = AmpC_Disp(g);
    end

    function cb_AmpC_Disp(~, ~)
        g = AmpC_Disp(g);
    end
    
    
end

%% AmpC_Disp
function [g] = AmpC_Disp(g)
    wait_box = waitbar(1, 'Displaying...');
    set(wait_box, 'WindowStyle', 'modal');
    dispIDs = g.dispIDs;
    if ismember('c', fieldnames(g))
        g = rmfield(g, 'c');
    end
    ch_store = [];
    
    for i = 1:length(dispIDs)
        c(i).ID = dispIDs(i);
        c(i).name = g.clusters([g.clusters.ID] == c(i).ID).name;
        c(i).chc = g.clusters((ismember([g.clusters.ID], uint32(c(i).ID)))).chc; % chc: Channel at centre
        [La, Lb] = ismember(c(i).chc, ch_store);
        if La
            c(i).plot_set = Lb;
        else
            ch_store = [ch_store, c(i).chc];
            c(i).plot_set = length(ch_store);
        end
        c(i).idxs = find(g.s.clusters(:, end) == c(i).ID);
        c(i).times = (g.s.stamps(c(i).idxs));
        c(i).val = struct;
        for ii = 1:length(g.Waveform.tog)
            tag = g.Waveform.tog(ii).Tag;
            val_type = regexp(tag, '[a-zA-Z]*', 'match'); % Gets all alphabet strings from tag (should only be one) as cell array
            val_type = val_type{1}; % Keeps only the string contained in the first (and only) cell
            pin = regexp(tag, '[0-9]*', 'match'); % Gets all strings of numbers from tag (should only be one)
            pin = str2double(pin{1}); % Keeps only the number contained in the first (and only) cell, converted to double
            if g.Waveform.tog(ii).Value == 1 % If box is checked
                switch val_type
                    case {'A'} % OK to have one enclosing set of curly braces, even though checking a string
                        c(i).val.(['A' num2str(pin)]) = ...
                            g.s.amp(c(i).idxs, g.chpin(c(i).chc, pin));
                    case {'Vt'}
                        c(i).val.(['Vt' num2str(pin)]) = ...
                            g.s.rec(c(i).idxs, g.chpin(c(i).chc, pin), g.Waveform.tog(ii).UserData);
                        Vt_on{pin} = g.Waveform.tog(ii).UserData;
                end
            else
                switch val_type
                    case {'Vt'}
                        Vt_on{pin} = [];
                end
            end
        end
        if exist('panel_title', 'var') == 0
            panel_title = [g.colours(i) ': ' num2str(c(i).name) ' (' num2str(length(c(i).times)) ' points)'];
        else
            panel_title = [panel_title ', ' g.colours(i) ': ' (c(i).name) ' (' num2str(length(c(i).times)) ' points)'];
        end
    end
    n_plot_types = nchoosek(length(fieldnames([c(1).val])), 2);
    splot_n = 4;
    splot_m = max([splot_n*ceil(n_plot_types*length(ch_store)/splot_n), 16])/splot_n;
    
    [panel_A, panel_B, ~] = ui_AmpSpace(g.AmpSpace.fig, splot_m, splot_n); % assign third output to 'scroll1' if necessary
    
    for i_plot = 1:(n_plot_types*length(ch_store))
        ampax(i_plot) = subplot(splot_m, splot_n, i_plot);
        cla;
        hold on;
    end
    set(ampax, 'Parent', panel_B);
    set(panel_A, 'Title', panel_title);
    
    for i_ID = 1:length(dispIDs)
        i_plot = (c(i_ID).plot_set-1)*n_plot_types;
        val_names = fieldnames([c(i_ID).val]);
        for i_val1 = 1:length(val_names)
            X = c(i_ID).val.(val_names{i_val1});
            xlab = val_names{i_val1};
            for i_val2 = (i_val1+1):length(val_names)
                Y = c(i_ID).val.(val_names{i_val2});
                ylab = val_names{i_val2};
                i_plot = i_plot+1;
                scatter(ampax(i_plot), X, Y, 1, g.colours(i_ID));
                xlabel(ampax(i_plot), xlab);
                ylabel(ampax(i_plot), ylab);
                ampax(i_plot).Tag = [val_names{i_val1}, ' ', val_names{i_val2}];
                clear Y ylab;
            end
            clear X xlab;
        end
        clear i_plot val_names;
    end
    
    figure(g.Waveform.fig);
    [~, loc] = ismember(get(g.Waveform.fig.Children, 'Type'), {'uipanel'});
    delete(g.Waveform.fig.Children(find(loc)));
    panel_wav = uipanel('Parent', g.Waveform.fig, 'Units', 'normalized', ...
        'Position', [0 0.1 0.9 0.9]);
    

    clear wavax;
    X = 1:size(g.s.rec, 3);
    for i = 1:length(dispIDs)
%         c(i).wave = g.s.rec(c(i).idxs, :, :);
%         c(i).mean_wave = squeeze(mean(c(i).wave, 1));
        switch contains(g.Waveform.bg_mean.SelectedObject.String, 'mean', 'IgnoreCase', true)
            case true
                for pin = 1:g.ncd
                    ch = g.chpin(c(i).chc, pin);
                    wavax(i, pin) = subplot(g.ncd, length(ch_store), mod(c(i).plot_set-1, length(ch_store))+1+(length(ch_store)*(pin-1))); hold on;
                    set(wavax(i, pin), 'XLim', [X(1), X(end)]);
                    Y = mean(squeeze(g.s.rec(c(i).idxs, ch, :)), 1);
                    pl = line(X, Y);
                    set(pl, 'Color', [colsp(g.colours(i)), 1]);
                    set(wavax(i, pin), 'Tag', ['Pin ' num2str(pin)]);
                    title(wavax(i, pin), ['Channel ' num2str(ch)]);
                end
                
%                 wavax = subplot(1,1,1); hold on;
%                 Y_full{i} = c(i).mean_wave-(ndgrid(1:size(c(i).mean_wave, 1), 1:size(c(i).mean_wave, 2))*v_spacing);
%                 for ch = 1:size(c(i).mean_wave, 1)
%                     Y = Y_full{i}(ch, :);
%                     if c(i).chc == (ch)
%                         wav(ch) = plot(wavax, X, Y, 'Color', [colsp(g.colours(i)), 1]);
%                     else
%                         wav(ch) = plot(wavax, X, Y, 'Color', [colsp(g.colours(i)), 1]);
%                     end
%                     text(X(1)-h_spacing, Y(1), num2str(ch));
%                 end
            case false
                %MB changing here
                for pin = 1:g.ncd
                    ch = g.chpin(c(i).chc, pin);
                    wavax(i, pin) = subplot(g.ncd, length(ch_store), mod(c(i).plot_set-1, length(ch_store))+1+(length(ch_store)*(pin-1))); hold on;
                    set(wavax(i, pin), 'XLim', [X(1), X(end)]);
                    set(wavax(i, pin), 'Tag', ['Pin ' num2str(pin)]);
                    Y = squeeze(g.s.rec(c(i).idxs, ch, :));
%                     Y2 = [Y'; NaN(1, size(Y,   1))];
%                     X2 = repmat(X', 1, size(Y2, 2)); X2(end+1, :) = NaN;
                    
% tic
                    yhy = double(reshape(Y,prod(size(Y)),1));
                    try
                        if size(Y,2) == 1
                            Y = Y';
                            disp('ha!')
                        end
                        yxy = reshape(repmat(1:31,size(Y,1),1),prod(size(Y)),1);
                    catch
                        eroras = 1;
                    end
%                     plotss = hist3([x', y']);
                    [nnn,ccc] = hist3([yxy, yhy],double([31,round(max(Y(:))-min(Y(:)))]));
                    imagesc(nnn.^0.5')
                    set(gca,'YDir','normal')
%                     toc
%                     [Y2, X2] = YX_quickplot(Y');
%                     pl = line(X2(:), Y2(:));
%                     set(pl, 'Color', [colsp(g.colours(i)), 0.2]);
%                     for x = X
%                         test_x = x*ones(1, length(Y));
%                         wav(pin, x) = scatter(wavax(i, pin), test_x, Y(x, :), 1, g.colours(i));
%                     end
                end
% % % % % % % % % % % % % %                 for pin = 1:g.ncd
% % % % % % % % % % % % % %                     ch = g.chpin(c(i).chc, pin);
% % % % % % % % % % % % % %                     wavax(i, pin) = subplot(g.ncd, length(ch_store), mod(c(i).plot_set-1, length(ch_store))+1+(length(ch_store)*(pin-1))); hold on;
% % % % % % % % % % % % % %                     set(wavax(i, pin), 'XLim', [X(1), X(end)]);
% % % % % % % % % % % % % %                     set(wavax(i, pin), 'Tag', ['Pin ' num2str(pin)]);
% % % % % % % % % % % % % %                     Y = squeeze(g.s.rec(c(i).idxs, ch, :));
% % % % % % % % % % % % % % %                     Y2 = [Y'; NaN(1, size(Y, 1))];
% % % % % % % % % % % % % % %                     X2 = repmat(X', 1, size(Y2, 2)); X2(end+1, :) = NaN;
% % % % % % % % % % % % % %                     [Y2, X2] = YX_quickplot(Y');
% % % % % % % % % % % % % %                     pl = line(X2(:), Y2(:));
% % % % % % % % % % % % % %                     set(pl, 'Color', [colsp(g.colours(i)), 0.2]);
% % % % % % % % % % % % % % %                     for x = X
% % % % % % % % % % % % % % %                         test_x = x*ones(1, length(Y));
% % % % % % % % % % % % % % %                         wav(pin, x) = scatter(wavax(i, pin), test_x, Y(x, :), 1, g.colours(i));
% % % % % % % % % % % % % % %                     end
% % % % % % % % % % % % % %                 end
        end
        set(wavax, 'Parent', panel_wav);
        for pin = 1:g.ncd
            if exist('Vt_on', 'var') && ~isempty(Vt_on{pin})
                plot(wavax(i, pin), ...
                    [Vt_on{pin}, Vt_on{pin}], ...
                    [wavax(i, pin).YLim(1), wavax(i, pin).YLim(2)], ...
                    'LineStyle', ':');
            end
        end
    end
    if g.Waveform.eq_ylims.Value
        ylims = cell2mat(get(wavax, 'YLim'));
        y1 = min(ylims(:,1));
        y2 = max(ylims(:,2));
        set(wavax, 'YLim', [y1, y2]);
    end
    
    figure(g.ISI.fig);
    
    for i = 1:length(dispIDs)
        if g.ISI.toggle.Value == 1
            [counts, edges] = ISI_hist(double(c(i).times), g.ISI.maxint, g.ISI.binwidth);
        else
            [counts, edges] = ISI_hist([], g.ISI.maxint, g.ISI.binwidth);
        end
        ISIax = subplot(length(dispIDs), 1, i);
        hist_h(i) = histogram('BinCounts', counts, 'BinEdges', edges, 'FaceColor', g.colours(i), 'EdgeColor', 'none');
      %  title([g.colours(i), ': Cluster ' (c(i).name)]);
        title([g.colours(i), ': Cluster ' (c(i).name) '   with ' num2str(sum(counts(edges>-2 & edges < 2))) ' violations']);
    end
    

    
    [~, ls_tmp_idxs] = ismember({c.name}, cellfun(@(C) C{1}, regexpi(g.ui.ls_tmp.String, '[A-Z0-9]*', 'match'), 'UniformOutput', false));
    ls_tmp_idxs = ls_tmp_idxs(ls_tmp_idxs>0);
    [~, ls_new_idxs] = ismember({c.name}, cellfun(@(C) C{1}, regexpi(g.ui.ls_new.String, '[A-Z0-9]*', 'match'), 'UniformOutput', false));
    ls_new_idxs = ls_new_idxs(ls_new_idxs>0);
    
    g.ui.ls_tmp.Value = ls_tmp_idxs;
    g.ui.ls_new.Value = ls_new_idxs;
    
    
    
    g.c = c;
    guidata(g.ui.fig, g);
    
    close(wait_box);
    
    % Populate fig.AmpSpace
    function [panel_A, panel_B, scroll1] = ui_AmpSpace(fig_h, splot_m, splot_n)
        figure(fig_h); 
        clf(fig_h);

        panel_A = uipanel('Parent', fig_h);
        set(panel_A, 'Position', [0, 0, 0.95, 1]);

        panel_B = uipanel('Parent', panel_A);

        scroll1 = uicontrol('Parent', fig_h,...
            'Style', 'slider', ...
            'Units', 'normalized', ...
            'Position', [0.96, 0, 0.03, 1], ...
            'Value', 1, ...
            'Callback', {@cb_scroll1, panel_B});

        panel_plots_height = max([(splot_m/splot_n), 1]);
        set(panel_B, 'Position', [0, 1-panel_plots_height, 1, panel_plots_height]);

        function cb_scroll1(src, ~, panel)
            val = get(src, 'Value');
            posn = get(panel, 'Position');
            dim_l = 0;
            dim_w = 1;
            dim_h = posn(4);
            dim_b = 0-val*(dim_h-1); 
            set(panel, 'Position', [dim_l,dim_b,dim_w,dim_h]);
        end
        
    end
    
    % ISI histogram function
    function [counts, edges] = ISI_hist(tc, maxInt, binwidth)
        if nargin <3
            binwidth = 10;
        end


        %MB changed. don't need too many spikes here..
%         tc = tc(1:min(length(tc),5e3));
        
        tc_mod =tc/g.s.sett.oe_sample_rate*1e3; % Convert to ms
        n_spk = length(tc_mod);
        
        try
            int = zeros(n_spk, n_spk-1);
        catch ME
            warning('Requested array too big.');
            tc = [];
            tc_mod =tc/g.s.sett.oe_sample_rate*1e3; % Convert to ms
            n_spk = length(tc_mod);
            int = zeros(n_spk, n_spk-1);
        end

        for jj = 1:n_spk-1
            int(:, jj) = tc_mod-circshift(tc_mod, jj);
        end

        edges = linspace(-maxInt, maxInt, maxInt*2/binwidth+1);
        if isempty(tc_mod)
            counts = zeros(1, length(edges)-1);
        else
            counts = histcounts(int, edges);
        end
    end
    
    
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AmpC_Denoise
function [g]  = AmpC_Denoise(g)
    v_spacing = 200;
    dispIDs = g.dispIDs;
    % MB Hijacking the function - replaced to filtering spikes with at
    % least one point away from the mean by at least 'sigme' standard
    % deviations
    
%     [g] = AmpC_Disp(g);
    
%     figure(g.Waveform.fig);
    
    wfs = single(g.s.rec(g.c.idxs,:,:));
    
    indosikai = [];
        sigme = 4; % how many sigmas from the mean?

        for itt = 1:size(wfs,2)
            
            wfs1 = squeeze(wfs(:,itt,:));
            
            avg_w = (mean(wfs1));
            std_w = (std(wfs1));
            
            for iq = 1:31 % for each timestamp in the waveform
                [indes, rks] = find(wfs1(:,iq)>(avg_w(iq)+sigme*std_w(iq)) | wfs1(:,iq)<(avg_w(iq)-sigme*std_w(iq)));
                indosikai = [indosikai; indes];
            end            
            
        end
    indosikais = sort(unique(indosikai)); %only noise spikes
    %MB changing here
    if isempty(indosikai)
        disp('NO NOISE SPIKES FOUND!')
        indosikais = 1;
    end
    a=1:size(wfs,1);
    b=a(~ismember(a,indosikais)); %only good spikes
    
    %MB changing here - will reduce the undo facility every 100 cuts
    if mod(size(g.s.clusters,2),100)==0
        g.s.clusters(:,1:3)=g.s.clusters(:,end-2:end);
        g.s.clusters=g.s.clusters(:,1:3);
    end
    
%     
%      in_cut = inpolygon(double(X_data), double(Y_data), cut(:, 1), cut(:, 2));
%     
    largest_ID = max([g.clusters.ID]);
    newID1 = largest_ID+1;
    newID2 = largest_ID+2;
    
    g.s.clusters(:, end+1) = g.s.clusters(:, end);
    
    g.s.clusters(g.c(1).idxs(b), end) = newID1;
    g.s.clusters(g.c(1).idxs(indosikais), end) = newID2;
    
    g.clusters = AmpC_ClusterUpdate(g.s, g, g.clusters);
    
    oldID = g.dispIDs;
    
    g.dispIDs = [newID1, newID2];
    g = AmpC_Disp(g);
    
    guidata(g.ui.fig, g);
    
   
    

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% AmpC_Split
function [g]  = AmpC_Split(g)
    if length(g.dispIDs) ~= 1
        error('Can only split one cluster at a time. Bad arguments from main program.');
    end
    
%     g = AmpC_Disp(g);
    
    g.ui.msg.String = 'Select plot to use...';
    figure(g.AmpSpace.fig);
    
    flagValidClick = false;
    while flagValidClick == false
        w = waitforbuttonpress;
        switch w
            case 0
                flagValidClick = true;
            case 1
                errordlg('Click on the axes!');
        end
    end
    
    ax = gca;
    
    val_type = regexp(ax.Tag, '\w*', 'match');
    X_data = g.c(1).val.(val_type{1});
    Y_data = g.c(1).val.(val_type{2});
    
    fig_AmpSplit = figure(11);
    figsize(fig_AmpSplit, [0.3, 0.2, 0.3, 0.6]);
    clf;
    scatter(X_data, Y_data, 1, g.colours(1));
    title('Select region, then press ENTER key when done.');
    cut = getline(gca, 'closed');
    close(fig_AmpSplit);
    
    in_cut = inpolygon(double(X_data), double(Y_data), cut(:, 1), cut(:, 2));
    
    largest_ID = max([g.clusters.ID]);
    newID1 = largest_ID+1;
    newID2 = largest_ID+2;
    
    g.s.clusters(:, end+1) = g.s.clusters(:, end);
    
    g.s.clusters(g.c(1).idxs(in_cut), end) = newID1;
    g.s.clusters(g.c(1).idxs(~in_cut), end) = newID2;
    
    g.clusters = AmpC_ClusterUpdate(g.s, g, g.clusters);
    
    oldID = g.dispIDs;
    
    g.dispIDs = [newID1, newID2];
    g = AmpC_Disp(g);
    
    guidata(g.ui.fig, g);
end

%% AmpC_Merge
function [g] = AmpC_Merge(g)
    if length(g.dispIDs) ~= 2
        error('Can only merge two clusters at a time; bad arguments from main program.');
    end

    g = AmpC_Disp(g);
    waitfor(msgbox('Displaying both clusters to be merged. Press OK to continue.'));

    largest_ID = max([g.clusters.ID]);
    newID1 = largest_ID+1;

    g.s.clusters(:, end+1) = g.s.clusters(:, end);

    g.s.clusters(g.c(1).idxs, end) = newID1;
    g.s.clusters(g.c(2).idxs, end) = newID1;

    g.clusters = AmpC_ClusterUpdate(g.s, g, g.clusters);

    oldIDs = g.dispIDs;

    g.dispIDs = newID1;
    g = AmpC_Disp(g);
    
    guidata(g.ui.fig, g);
end

%% AmpC_Undo
function [g] = AmpC_Undo(g)
    if size(g.s.clusters, 2) > 1
        wbx = waitbar(0, 'Loading history...');
        for col = 1:size(g.s.clusters, 2)
            created{col, 1} = '';
            deleted{col, 1} = '';
            ls_IDs{col} = sort(unique(g.s.clusters(:,col)));
            if col > 1
                cr_IDs = ls_IDs{col}(~ismember(ls_IDs{col}, ls_IDs{col-1}))';
                [~, cr_idxs] = ismember(cr_IDs, [g.clusters.ID]);
                cr_names = {g.clusters(cr_idxs).name};
                for ii = 1:length(cr_names)
                    if isempty(created{col, 1})
                        created{col, 1} = cr_names{ii};
                    else
                        created{col, 1} = [created{col, 1}, ', ', cr_names{ii}];
                    end
                end
                
                del_IDs = ls_IDs{col-1}(~ismember(ls_IDs{col-1}, ls_IDs{col}))';
                [~, del_idxs] = ismember(del_IDs, [g.clusters.ID]);
                del_idxs = del_idxs(del_idxs > 0);
                del_names = {g.clusters(del_idxs).name};
                for ii = 1:length(del_names)
                    if isempty(deleted{col, 1})
                        deleted{col, 1} = del_names{ii};
                    else
                        deleted{col, 1} = [deleted{col, 1}, ', ', del_names{ii}];
                    end
                end
            end
            n_round{col, 1} = ['Version ' num2str(col)];
            waitbar(col/size(g.s.clusters, 2), wbx);
        end
        close(wbx);
        colnames = {'Created', 'Deleted'};
        diaryAmp = table(created, deleted, 'VariableNames', colnames, 'RowNames', n_round);
    else
        diaryAmp = table();
    end
    

    switch isempty(diaryAmp)
        case 0
            % Construct UITABLE
            fig_AmpUndo = figure;
            diaryAmp_gui = uitable(...
                'Parent',       fig_AmpUndo, ...
                'Units',        'normalized',...
                'Position',     [0.05, 0.5, 0.9, 0.45]);
            diaryAmp_gui.Data = table2cell(diaryAmp);
            diaryAmp_gui.RowName = diaryAmp.Properties.RowNames;
            diaryAmp_gui.ColumnName = diaryAmp.Properties.VariableNames;
            popup_vselect = uicontrol(...
                'Style',        'popupmenu', ...
                'Units',        'normalized', ...
                'Position',     [0.25, 0.2, 0.25, 0.05], ...
                'String',       diaryAmp.Properties.RowNames, ...
                'Value',        size(g.s.clusters, 2));
            btn_ok = uicontrol(...
                'Style',        'pushbutton', ...
                'Units',        'normalized', ...
                'Position',     [0.6, 0.2, 0.15, 0.05], ...
                'Callback',     @cb_vers_ok, ...
                'String',       'OK');
            waitfor(fig_AmpUndo);
        case 1
            waitfor(msgbox('No changes have been made to original cluster/template assignments.'));
    end
    
    function cb_vers_ok(src, ~)
        v = popup_vselect.Value;
        switch v
            case size(g.s.clusters, 2)
                waitfor(msgbox(['Round ' num2str(v) ' clusters selected: no changes made.']));
            otherwise
                g.s.clusters = g.s.clusters(:, 1:v);
                g.clusters = AmpC_ClusterUpdate(g.s, g, g.clusters);
                waitfor(msgbox(['Round ' num2str(v) ' clusters restored.']));
        end
        guidata(g.ui.fig, g);
        close(src.Parent);
    end
end

%% AmpC_Save
function g = AmpC_Save(g)
    final = zeros(length(g.s.stamps), 1);

    try
        new_idxs = ~ismember(g.s.clusters(:, end), uint32(g.s.templates));
    catch
        new_idxs = ~ismember(g.s.clusters(:, end), (g.s.templates));
    end
    final(new_idxs) = g.s.clusters(new_idxs, end);

    ls_new_IDs = sort(unique(final(final>0)));

    for ii = 1:length(ls_new_IDs)
        ID = ls_new_IDs(ii);
        idxs = find(final == ID);
        name = g.clusters([g.clusters.ID] == ID).name;
        name_strings = regexpi(name, '[A-Z]*', 'match');
        name_numbers = regexp(name, '[0-9]*', 'match');

        if length(name_strings) == 1 && length(name_numbers) == 1 && isequal(name, cell2mat([name_numbers, 'm']))
            final(idxs) = str2double(name_numbers{1});
        else
            final(idxs) = 0;
        end

    end
    
    g = attempt_save(g, final);

    g.final = final; 
    guidata(g.ui.fig, g);
    
    
    function g = attempt_save(g, final)
        if ~any(final)
            waitfor(errordlg('No curated clusters were found with the required naming scheme (number followed by letter ''m'').'));
            g.save_cancel = 0;
        else
            [filename, target_folder] = uiputfile('*.npy', 'Save...', [g.save_name]); 
            if ~(isequal(filename,0) || isequal(target_folder,0))
                g.save_name = filename;
            	writeNPY(final, fullfile(target_folder, g.save_name));
                ampsave.s_clusters = g.s.clusters;
                ampsave.cluster_list = g.clusters; % Ignore the warning here - variable saved below, but referred to by name as string, hence not detected
                save(['amp_' g.save_name '.mat'], '-v7.3', 'ampsave');
                waitfor(msgbox(['Saved ' g.save_name ' to ' target_folder]));
%                 writeNPY(g.s.clusters, ['amp_full_' g.amp_start_time '.npy']);
                g.save_cancel = 0;
            else
                g.save_cancel = 1;
            end
        end
    end
end

%% AmpC_Exit
function g = AmpC_Exit(g)
    save_answer = questdlg('Save before exit?', 'Exit', 'Save and exit', 'Exit without saving', 'Cancel', 'Cancel');
    switch save_answer
        case 'Save and exit'
            g = AmpC_Save(g);
            if isequal(0, g.save_cancel)
                openfigs = findobj(groot, 'Type', 'Figure');
                close(setdiff(openfigs, g.ui.fig));
            end
        case 'Exit without saving'
            openfigs = findobj(groot, 'Type', 'Figure');
            close(setdiff(openfigs, g.ui.fig));
    end
    guidata(g.ui.fig, g);
end