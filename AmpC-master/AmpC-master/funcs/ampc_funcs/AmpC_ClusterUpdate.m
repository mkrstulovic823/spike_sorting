function clusters_out = AmpC_ClusterUpdate(s, g, clusters_in)
    %% Important things
    %;% max(s.templates) should be fixed, because s.templates should be
    %;% fixed. If it isn't, the programme is being run wrong - nothing should
    %;% EVER change s.templates. 
    
    %% Start
    if isempty(g)
        clear g;
    end
    if isempty(clusters_in)
        clear clusters_in;
    end
    
    if exist('g', 'var') > 0 && exist('clusters_in', 'var') > 0
        ls_IDs = sort(unique(s.clusters(:, end))); % NOTE DIFFERENCE HERE - need actively running programme (hence g) with cluster list to update (hence clusters_in) in order to justify looking only at last column
    else
        ls_IDs = sort(unique(s.clusters)); % If either variable is not passed, we ought to be thorough and check
    end
    
    if exist('clusters_in', 'var') == 0
    %% Condition 1: no previous 'clusters_in' variable, so names need to be made anew
        wbx = waitbar(0, 'Creating cluster list...');
        clusters_out(length(ls_IDs)).ID = [];
        for i = 1:length(ls_IDs)
            idx = i; % This is redundant, but allows easier comparison with condition 2 code - DO NOT MODIFY
            ID = ls_IDs(i); % This is from s.clusters'' last column
            clusters_out(idx).ID = ID;
            if ismember(int16(ID), s.templates)
                clusters_out(idx).name = num2str(ID);
            else
                clusters_out(idx).name = [num2str((ID)-max(s.templates)), 'm'];
            end
%             [~, ch] = max(range(squeeze(mean(s.rec(s.clusters(:, end) == ID, :, :), 1)), 2));
%             clusters_out(idx).chc = ch;
            tet = mode(s.tet(s.clusters(:,end) == ID));
            clusters_out(idx).chc = tet;
            waitbar(i/length(ls_IDs), wbx);
        end
        close(wbx);
        waitfor(msgbox('Cluster list created.', 'AmpB2_ClusterUpdate'));

    elseif any(~ismember(int16(ls_IDs), int16([clusters_in.ID])))
    %% Condition 2: there are IDs in 's.clusters' not represented in 'clusters_in', so 'clusters_in' needs to be supplemented
    %;% NB// The inverse, i.e. that there are IDs in 'clusters' no longer
    %;% in s.clusters, is to be expected - e.g. splitting 7 will give 8 and
    %;% 9, so 7 will no longer be in s.clusters. BEAR THIS IN MIND WHILE
    %;% MODIFYING THE ELSEIF CONDITION ABOVE. 

    try    
        new_IDs = ls_IDs(~ismember(uint32(ls_IDs), uint32([clusters_in.ID])));
    catch
        new_IDs = ls_IDs(~ismember((ls_IDs), [clusters_in.ID]));
    end
        initial_ls_length = length(clusters_in);
        clusters_out = clusters_in;
        for i = 1:length(new_IDs)
            ID = new_IDs(i);
            idx = initial_ls_length+i;
            clusters_out(idx).ID = ID;
            % MB changes to int32
            try
                clusters_out(idx).name = [num2str(int16(ID)-max(s.templates)), 'm'];
            catch
                clusters_out(idx).name = [num2str(ID-int32(max(s.templates))), 'm'];
            end
%             [~, ch] = max(range(squeeze(mean(s.rec(s.clusters(:, end) == ID, :, :), 1)), 2));
%             clusters_out(idx).chc = ch;
            tet = mode(s.tet(s.clusters(:,end) == ID));
            clusters_out(idx).chc = tet;
        end
        %%waitfor(msgbox('Cluster list updated.', 'AmpB2_ClusterUpdate'));
        
        %;% NB// This function has to remember old deleted clusters, rather
        %;% than just recalculating the list from s.clusters, because all
        %;% new names *manually* applied to clusters have to persist 
        %;% following each update. This is especially important for the 
        %;% history/undo functions. 
    else
    %% Condition 3: EVERY cluster in 's.clusters' is represented somewhere in 'clusters_in.ID'
        clusters_out = clusters_in;
        display('Cluster list already up to date.');
    end
    
    %% Changing displayed cluster names to reflect new cluster list
    if exist('g', 'var') && ismember('ui', fieldnames(g)) && ismember('ls_tmp', fieldnames(g.ui))
        all_IDs = [clusters_out.ID];
        all_names = {clusters_out.name};
        all_chcs = {clusters_out.chc};
        try
            valid_idxs = ismember(all_IDs, int32(g.s.clusters(:, end)));
        catch
            valid_idxs = ismember(all_IDs, uint32(g.s.clusters(:, end)));
        end
            all_IDs = all_IDs(valid_idxs);
            all_names = all_names(valid_idxs);
            all_chcs = all_chcs(valid_idxs);
            
            try
                tmp_idxs = ismember(all_IDs, int32(g.s.templates));
            catch
                tmp_idxs = ismember(all_IDs, uint32(g.s.templates));
            end
            
            tmp_names   = all_names(tmp_idxs);
            tmp_chcs    = all_chcs(tmp_idxs);
            
            new_names   = all_names(~tmp_idxs);
            new_chcs    = all_chcs(~tmp_idxs);
            
            tmp_disp = cellfun(@(c1, c2) [c1 ' (tet. ' num2str(c2) ')'], tmp_names, tmp_chcs, 'Uni', false);
            new_disp = cellfun(@(c1, c2) [c1 ' (tet. ' num2str(c2) ')'], new_names, new_chcs, 'Uni', false);
        set(g.ui.ls_tmp, 'String', tmp_disp);
        set(g.ui.ls_new, 'String', new_disp);
        if any(g.ui.ls_tmp.Value > length(g.ui.ls_tmp.String))
            set(g.ui.ls_tmp, 'Value', []);
        end
        if any(g.ui.ls_new.Value > length(g.ui.ls_new.String))
            set(g.ui.ls_new, 'Value', []);
        end
    end
end