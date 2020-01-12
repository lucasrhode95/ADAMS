%% force_delete
%
% force_delete(filename)
%
% does what it says on the tin. No 'permission denied' nonsense.
%

function force_delete(filename)
   
    fID = find_fID_for(filename);              % find all file IDs for meta file, might be open for reading and writing so may have more than one file ID
    if all(fID ~= -1)
        pmax = length(fID);
        for p = 1:pmax
            fclose(fID(p));                % close all file IDs relating to the meta file, the meta file can now be deleted
        end
    end
    delete(filename);
 
end

function [fID] = find_fID_for(filename)   
    %
    % [fID] = find_fID_for(filename)
    %
    % gives vector of all active file IDs for filename
    % returns -1 if there are no active file IDs
    
	% MOD BY LUCAS RHODE (2019)
	if isempty(filename)
		error('Empty file name.');
	end
	
    if strcmp(filename(end),filesep)        % remove backslash from end of filename (if present)
        filename = filename(1:end-1);
    end
    
    fIDs = fopen('all');        % get all open file IDs
    nmax = length(fIDs);
    
    found = false;
    m = 0;
    for n=1:nmax                        % for each file ID
        filename_comp = fopen(fIDs(n));        % get coresponding filename
        if strcmp(filename_comp,filename)      % if this is the filename we are looking for
            found = true;                           % mark as found
            m=m+1;                                  
            index(m) = n;               %#ok<AGROW> % keep record of the current index
        end
    end
    
    if found
        fID = fIDs(index);      % if found parse back file IDs
    else
        fID = -1;           % if not found parse back -1
    end
end