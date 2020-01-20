classdef LastDirHelper
	% Class that helps to persist the last directory used by UIFile.
	%
	% When an app asks the user to pick a file from the hard drive, MATLAB
	% doesn't remember the last location used. This class helps <a href="matlab:doc('util.FilesUtil')">FilesUtil</a>
	% to work around this issue.
	%
	%
	%
	%	INFO: this class makes use of persistent variables. However, there
	% are some situations and built-in functions that can inadvertently
	% reset persisted variables and that - I assure you - can drive you
	% crazy.
	%	To avoid that, this class locks itself everytime you use its
	% functions so that, even if you use clear or those scumbag built-in
	% functions try to reset this class, we won't lose the persisted data.
	%	Usually this will have NO impact on your life, but IF you need to
	% unlock those variables, you can simply use LastDirHelper.unlock()
	% and LastDirHelper.lock() to manually lock it back
	%	Btw, a simpler approach would be to just add the path of this file
	% MATLAB's path, but that is not very elegant IMO
	
	properties(Constant, Access = public)
		% If no cache file path is provided, this value will be used to store the last path selected by the user
		DEFAULT_CACHE_FILE = fullfile(tempdir, 'last_dir_cache.tmp');
		
		% Whether or not the cache is activated by default
		DEFAULT_STATUS = false;
	end
	
	methods(Static, Access = public)
		function lastDir = get(pwdIfEmpty)
		% Returns the last directory selected.
		%
		% Returns and empty char array unless pwdIfEmpty flag is set, then is
		% returns the current matlab path.
			import util.LastDirHelper
		
			lastDir = LastDirHelper.getSetLastDir();
			
			% if empty, returns pwd()
			if isempty(lastDir) && (nargin >= 1) && (pwdIfEmpty)
				lastDir = pwd();
			end
		end
		
		function lastDir = set(lastDir)
		% Sets the last directory selected
			import util.LastDirHelper
			lastDir = LastDirHelper.getSetLastDir(lastDir);
		end
		
		function isCacheOn = status(isCacheOn)
		% Getter/setter to turn On or Off the UIGet/UISet cache
			import util.CommonsUtil
			import util.LastDirHelper
			
			LastDirHelper.lock();
			persistent persistentIsCacheOn
			
			if nargin
				persistentIsCacheOn = isCacheOn;
				if isCacheOn
					CommonsUtil.log('UICache activated!\n');
				else
					CommonsUtil.log('UICache deactivated!\n');
				end
				return;
			elseif isempty(persistentIsCacheOn)
				persistentIsCacheOn = LastDirHelper.DEFAULT_STATUS;
			end
			
			
			isCacheOn = persistentIsCacheOn;
		end
		
		function cachePath = location(cachePath)
		% gets/sets the location of the cache
			import util.LastDirHelper
			import util.CommonsUtil
			
			LastDirHelper.lock();
			persistent persistentCachePath
			
			% if there's an argument, it's treated as a SET action
			if nargin
				persistentCachePath = cachePath;
			% if no argument and persistent variable is empty, uses default
			% value
			elseif isempty(persistentCachePath)
				persistentCachePath = LastDirHelper.DEFAULT_CACHE_FILE;
				CommonsUtil.log('No cache path selected, using default location "%s"\n', persistentCachePath);
			end
			
			% in any case, returns the persisted value			
			cachePath = persistentCachePath;
		end
		
		function lock()
		% Locks the persisted variables (used for caching)
			mlock();
		end
		
		function unlock()
		% Unlocks the persisted variables (used for caching)
			munlock();
		end
		
	end
	
	methods(Static, Access = private)
		function lastDir = getSetLastDir(lastDir)
		% Persistent variable that holds the last dir, so that the uiPut/uiGet methods have some memory
		%
		% To reset this, one can simply pass an empty value to it
		% To fully disable this functionality, use LastDirHelper.status(false)
			import util.LastDirHelper
			import util.TypesUtil

			% if caching is disabled, does nothing
			if ~LastDirHelper.status()
				util.CommonsUtil.log('Cache is disabled, ignoring cache request\n');
				lastDir = '';
				return;
			end

			LastDirHelper.lock();
			persistent persistentLastDir

			% if the function is being used to SET the value: saves and return.
			if nargin
				TypesUtil.mustBeTxt(lastDir);
				persistentLastDir = lastDir;
				LastDirHelper.writeCacheFile(lastDir);
				return;
			end

			% if the last used dir is already in memory, returns it. Tries
			% to read from cache otherwise
			if ~isempty(persistentLastDir)
				lastDir = persistentLastDir;
				return;
			else
				persistentLastDir = LastDirHelper.readCacheFile();
				lastDir = persistentLastDir;
			end
		end
		
		function writeCacheFile(lastDir)
		% Saves the last used dir path to a file
		% 
		% By saving the last path to a file, it allows us to retrieve the
		% last used dir even after MATLAB has been closed and reopened.
			import util.LastDirHelper
			import util.FilesUtil
			import util.CommonsUtil
			
			cacheFile = LastDirHelper.location();
			
			% persists location
			FilesUtil.writeTextFile(cacheFile, lastDir);
			CommonsUtil.log('New location cached: "%s".\n', lastDir);
		end
		
		function lastDir = readCacheFile()
		% Reads the last used dir path from a file
		%
		% If there is no cache path available, returns an empty string.
			import util.FilesUtil
			import util.CommonsUtil
			import util.LastDirHelper
			
			fallback_dir = '';
			
			% checks if cache file exists
			try
				FilesUtil.checkIfExists(LastDirHelper.location())
			catch
				CommonsUtil.log('Cache file not found @ "%s".\n', LastDirHelper.location());
				lastDir = fallback_dir;
				return;
			end
				
			try
				lastDir = fileread(LastDirHelper.location());
			catch e
				getReport(e);
				CommontsUtil.log('Unable to read cache file "%s"\n', LastDirHelper.location());
				lastDir = fallback_dir;
			end
		end
	end
end