classdef FilesUtil
	% Collection of commonly needed file-handling methods.
	
	methods(Static)
		function forceDelete(filename)
		% does what it says on the tin. No 'permission denied' nonsense.
		% This is only a gateway to a third party method.
			import lib.force_delete.*
			force_delete(filename);
		end
		
		function hideFile(filename)
		% Marks a file as 'Hidden' in a Windows file system.
			fileattrib(filename, '+h');
		end
		
		function filename = sanitizePath(filename, checkIfExists)
		% Makes sure the slashes are in the correct direction
			import util.FilesUtil
		
			filename = fullfile(filename);
			
			if (nargin < 2 || checkIfExists)
				FilesUtil.checkIfExists(filename);
			end
		end
		
		function fullpath = getFullPath(filename, checkIfExists)
		% Resolves a relative path to an absolute path.
		%
		% Examples:
		%
		% FILESUTIL.GETFULLPATH() returns the file path of the
		% caller
		%
		% FILESUTIL.GETFULLPATH(filename) Resolves file name to a full
		% path. Throws an error if the
		% file doesn't exists
		%
		% FILESUTIL.GETFULLPATH(filename, checkIfExists) Resolves file
		% name to a full path. If checkIfExists is set to true, checks if
		% file exists an throws an error if not.
			import util.TypesUtil
			import util.FilesUtil
			import lib.GetFullPath.*
			
			if nargin == 0
				out = dbstack('-completenames');
				fullpath = out(end).file;
				return;
			end
			
			if nargin < 2
				checkIfExists = true;
			else
				TypesUtil.mustBeLogical(checkIfExists);
			end
			
			fullpath = GetFullPath(char(filename));
			
			if checkIfExists
				FilesUtil.checkIfExists(filename);
			end
		end
		
		function checkIfExists(filename)
			%FIXME: this is a non-document function BUT it should work in
			%MATLAB's earlier versions.
			% For 2017b+, use isfile:
			% if ~isfile(filename)
			
			file = java.io.File(filename);
			if ~file.exists()
				error('resolvePath:CannotResolve', 'Does not exist or failed to resolve absolute path for %s.', filename);
			end
			
		end
		
		function parentPath = getParentDir(rootDir, checkIfExists)
		% Returns the parent folder of a file (or another folder).
			import util.TypesUtil
			import util.FilesUtil
		
			if nargin == 0
				rootDir = dbstack('-completenames');
				rootDir = rootDir(end).file;
				
				checkIfExists = false;
			end
			
			if nargin < 2
				checkIfExists = true;
			else
				TypesUtil.mustBeLogical(checkIfExists);
			end
		
			currentDir = java.io.File(FilesUtil.getFullPath(rootDir, checkIfExists));
			parentPath = char(currentDir.getParent());
		end
		
		function filename = getFileName(filepath, keepExtension)
		% Returns the file name from a file path.
			import util.FilesUtil
			[~, filename, ext] = fileparts(filepath);
			
			if nargin < 2 || keepExtension
				filename = [filename ext];
			end
		end
		
		function filename = removeExtension(filepath)
		% Removes the extension of a file path
			[dir, filename] = fileparts(filepath);
			filename = fullfile(dir, filename);
		end
		
		function writeTextFile(filepath, content, permission)
		% Simple routine to write a text file
			import util.TypesUtil
			
			if nargin < 3 || ~TypesUtil.isTxt(permission)
				permission = 'w';
			end
			
			fileID = fopen(filepath, permission);
			fprintf(fileID, '%s', content);
			fclose(fileID);
		end
		
		function shortenedPath = shortenPath(originalPath)
		% Returns a short version of a long path.
			import util.StringsUtil
			
			pathParts = StringsUtil.split(originalPath, {'/', '\'});
			
			if length(pathParts) < 4
				shortenedPath = originalPath;
				return;
			end
			
			shortenedPath = [pathParts{1}, filesep, '...', filesep, pathParts{end-1}, filesep, pathParts{end}];
		end
		
		function varargout = uiPutFile(varargin)
		% Open dialog box for saving files, same as MATLAB's original one,
		% but always return only one file path. If no file was selected,
		% returns an empty string
			import util.FilesUtil
			
			if nargout <= 1
				varargout{1} = FilesUtil.uiGetPutFile(false, varargin{:});
			elseif nargout == 2
				[varargout{1}, varargout{2}] = FilesUtil.uiGetPutFile(false, varargin{:});
			else
				error('FilesUtil:incorrectNumberOfOutputs', 'Too many output arguments.');
			end	
		end
		
		function varargout = uiGetFile(varargin)
		% Open file selection dialog box, same as MATLAB's original one,
		% but always return only one file path. If no file was selected,
		% returns an empty string
			import util.FilesUtil
			
			if nargout <= 1
				varargout{1} = FilesUtil.uiGetPutFile(true, varargin{:});
			elseif nargout == 2
				[varargout{1}, varargout{2}] = FilesUtil.uiGetPutFile(true, varargin{:});
			else
				error('FilesUtil:incorrectNumberOfOutputs', 'Too many output arguments.');
			end
		end
		
		function isCacheEnabled = cacheStatus(varargin)
		% Mirror to <a href="matlab:doc('util.LastDirHelper')">LastDirHelper</a>.<a href="matlab:doc('util.LastDirHelper/status')">status</a>.
			import util.LastDirHelper
			isCacheEnabled = util.LastDirHelper.status(varargin{:});
		end
		
		function varargout = uiGetPutFile(getFile, varargin)
		% Either puts or gets a file, depending of the getFile flag
			import util.TypesUtil
			import util.StringsUtil
			import util.LastDirHelper
			import util.CommonsUtil
			
			% arguments checking
			if nargout > 2
				error('FilesUtil:incorrectNumberOfOutputs', 'Too many output arguments.');
			end
			
			CommonsUtil.log('Waiting for user to select a file...\n');
			
			% filter default value
			if isempty(varargin)
				varargin = {'*.*'};
			end
			
			% add directory to filter
			filter = varargin{1};
			filter = StringsUtil.join(filter, ';');
			dir = fileparts(filter);
			if isempty(dir) % if directory is informed, uses cached value
				filter = fullfile(LastDirHelper.get(), filter);
			end
			varargin(1) = []; % removes filters from varargin. Those will be passed separately
			
			% switches between methods
			if getFile
				[filename, filepath] = uigetfile(filter, varargin{:});
			else
				[filename, filepath] = uiputfile(filter, varargin{:});
			end
			
			% if the user has canceled the selection, returns an empty string
			if ~TypesUtil.isTxt(filename) || ~TypesUtil.isTxt(filepath)
				filepath = '';
				filename = '';
				CommonsUtil.log('Action cancelled by user.\n');
			else % otherwise, caches the path that the user selected
				LastDirHelper.set(filepath);
				CommonsUtil.log('Selected "%s"\n', fullfile(filepath, filename));
			end
			
			% switches between output modes
			if nargout <= 1
				varargout{1} = fullfile(filepath, filename);
			else
				varargout{1} = filename;
				varargout{2} = filepath;
			end
		end
		
		function selpath = uiGetDir(varargin)
		% Open folder selection dialog box, same as MATLAB's original one,
		% but always return only one file path. If no file was selected,
		% returns an empty string
			import util.FilesUtil
			import util.TypesUtil
			import util.LastDirHelper
			import util.CommonsUtil
			
			CommonsUtil.log('Waiting for user to select a folder...\n');
			
			% prompts the user with a dialog box
			if isempty(LastDirHelper.get())
				selpath = uigetdir([], varargin{:});
			else
				selpath = uigetdir(LastDirHelper.get(), varargin{:});
			end
			
			% if the user has canceled the action, returns an empty string
			if ~TypesUtil.isTxt(selpath)
				selpath = '';
				CommonsUtil.log('Action cancelled by user.\n');
			else % otherwise, caches the path that the user selected
				LastDirHelper.set(selpath);
				CommonsUtil.log('Selected "%s"\n', selpath);
			end
		end
		
		function varargout = writeExcel(varargin)
		% Mirror to a Excel-writing function.
		% This is useful because MATLAB marked xlswrite as 'not-recommended'
		% as of R2019a, so that in the future everything can be easily
		% mirrored to a new function
			varargout{:} = xlswrite(varargin{:});
		end
		
		function varargout = readExcel(varargin)
		% Mirror to a Excel-reading function.
		% This is useful because MATLAB marked xlsread as 'not-recommended'
		% as of R2019a, so that in the future everything can be easily
		% mirrored to a new function
			varargout{:} = xlsread(varargin{:});
		end
		
		function varargout = readCsv(varargin)
		% Mirror to a Excel-reading function.
		% This is useful because MATLAB marked csvread as 'not-recommended'
		% as of R2019a, so that in the future everything can be easily
		% mirrored to a new function
			varargout{:} = csvread(varargin{:});
		end
		
		function binaryContent = readBinary(fileName)
		% Returns the binary content of a GDX file.
		% This is a low-level method, meaning it doesn't check much for errors.
		%
		% Examples
		% binaryContent = FilesUtil.readBinary(filePath)
		%
		% This would return the binary contents of the temporary output
		% file. That could be persisted somewhere else and then reused with
		% FilesUtil.writeBinary(binaryContent);
		
			% opens the file
			fid = fopen(fileName, 'r');
			
			% tries to read it
			try
				binaryContent = fread(fid);
				fclose(fid);
			catch
				% if it fails, closes anyway
				try
					fclose(fid);
				catch
				end
			end
		end
		
		function writeBinary(fileName, binaryData)
		% Provides a way of manually loading a GDX output file into the model.
		% 
		% Useful for when you already have a external GDX file but want to
		% use the reading methods of this class.
		%
		% This is a low-level method, meaning it doesn't check much for errors.
		%
		% Examples
		% FilesUtil.writeBinary(filePath, binaryContent)
		
			% tries to delete. If it fails, continues anyway
			try
				warning('off', 'MATLAB:DELETE:FileNotFound');
				util.FilesUtil.forceDelete(fileName)
				warning('on', 'MATLAB:DELETE:FileNotFound');
			catch
			end
			
			% tries to write to the file. If it fails, tries to close it
			% and rethrows exception.
			try
				fid = fopen(fileName, 'w');
				fwrite(fid, binaryData);
				fclose(fid);
			catch e
				try
					fclose(fid);
				catch
				end
				
				rethrow(e);
			end
		end
	end
	
end