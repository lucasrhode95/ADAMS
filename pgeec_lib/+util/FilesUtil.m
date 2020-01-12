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
			import util.*
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
			
			fullpath = GetFullPath(filename);
			
			if checkIfExists
				file = java.io.File(filename);
				if ~file.exists()
					error('resolvePath:CannotResolve', 'Does not exist or failed to resolve absolute path for %s.', filename);
				end
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
		
		function fileName = getFileName(filePath, checkIfExists)
		% Returns the file name from a file path.
			import util.FilesUtil
			import util.TypesUtil
		
			if nargin < 2
				checkIfExists = true;
			else
				TypesUtil.mustBeLogical(checkIfExists);
			end
			
			file = java.io.File(FilesUtil.getFullPath(filePath, checkIfExists));
			fileName = char(file.getName());
		end
		
		function shortenedPath = shortenPath (originalPath)
		% Returns a short version of a long path.
			import util.StringsUtil
			
			pathParts = StringsUtil.split(originalPath, {'/', '\'});
			
			if length(pathParts) < 4
				shortenedPath = originalPath;
				return;
			end
			
			shortenedPath = [pathParts{1}, filesep, '...', filesep, pathParts{end-1}, filesep, pathParts{end}];
		end
		
		function bufferPath = getSetUiBufferPath(bufferPath)
		% Getter/setter of the persistent buffer file path. This allows the program to remember the last opened directory even after MATLAB has been closed.
			persistent persistentBufferPath;
			
			if nargin
				persistentBufferPath = bufferPath;
			elseif isempty(persistentBufferPath)
				bufferPath = false;
			else
				bufferPath = persistentBufferPath;
			end
		end
		
		function isBufferOn = getSetUiBuffer(isBufferOn)
		% Getter/setter to turn On or Off the UIGet/UISet buffer
			persistent persistentIsBufferOn;
			
			if nargin
				persistentIsBufferOn = isBufferOn;
			elseif isempty(persistentIsBufferOn)
				isBufferOn = false;
			else
				isBufferOn = persistentIsBufferOn;
			end
		end
		
		function saveLastDir(lastDir)
		% Saves the last used dir path to a file
		% 
		% By saving the last path to a file, it allows us to retrieve the
		% last used dir even after MATLAB has been closed and reopened.
		
			% if the buffer is enabled and has a path available, saves it on disk.
			if ~isempty(util.FilesUtil.getSetUiBufferPath()) && util.FilesUtil.getSetUiBuffer()
				try
					fid = fopen(util.FilesUtil.getSetUiBufferPath(), 'w');
					fprintf(fid, '%s', lastDir);
					fclose(fid);
				catch
					try fclose(fid); catch ; end
				end
			end
		end
		
		function lastDir = getLastDirFromCache()
		% Reads the last used dir path from a file
		%
		% If there is no cache path available, returns an empty variable.
		
			if ~isempty(util.FilesUtil.getSetUiBufferPath()) && util.FilesUtil.getSetUiBuffer()
				try
					lastDir = fileread(util.FilesUtil.getSetUiBufferPath());
				catch
					lastDir = '';
				end
			else
				lastDir = '';
			end
		end
		
		function lastDir = getSetLastDir(lastDir)
		% Persistent variable that holds the last dir, so that the uiPut/uiGet methods have some memory
		%
		% To reset this, one can simply pass an empty value to it
		% To fully disable this functionality, use util.FilesUtil.getSetUiBuffer(false)
			
			% if the cache functionality is disabled, does nothing
			if ~util.FilesUtil.getSetUiBuffer()
				lastDir = '';
				return;
			end
		
			persistent persistentLastDir;
			
			% if the function is being used to SET the value: saves and return.
			if nargin
				persistentLastDir = lastDir;
				util.FilesUtil.saveLastDir(lastDir);
				return;
			end
			
			% if the last used dir is already in memory, returns it. Tries
			% to read from cache otherwise
			if ~isempty(persistentLastDir)
				lastDir = persistentLastDir;
				return;
			else
				persistentLastDir = util.FilesUtil.getLastDirFromCache();
				lastDir = persistentLastDir;
			end
		end
		
		function filePath = uiPutFile(varargin)
		% Open dialog box for saving files, same as MATLAB's original one,
		% but always return only one file path. If no file was selected,
		% returns an empty string
			import util.TypesUtil
			import util.FilesUtil
			
			if isempty(util.FilesUtil.getSetLastDir())
				[fileName, filePath] = uiputfile(varargin{:});
			else
				if isempty(varargin)
					[fileName, filePath] = uiputfile(util.FilesUtil.getSetLastDir());
				else
					filter = [util.FilesUtil.getSetLastDir(), filesep, varargin{1}];
					varargin(1) = [];
					[fileName, filePath] = uiputfile(filter, varargin{:});
				end
			end
			
			if ~TypesUtil.isTxt(fileName) || ~TypesUtil.isTxt(filePath)
				filePath = '';
				return
			else
				util.FilesUtil.getSetLastDir(filePath);
			end
			
			% TODO: Check if the ", filesep," concatenation is really
			% necessary. This is adding double backslashes because I
			% THINK will provide better OS compatibility.
			%
			% makes sure the path is absolute
			filePath = FilesUtil.getFullPath([filePath, filesep, fileName], false);
		end
		
		function filePath = uiGetFile(varargin)
		% Open file selection dialog box, same as MATLAB's original one,
		% but always return only one file path. If no file was selected,
		% returns an empty string
			import util.*
			
			if isempty(util.FilesUtil.getSetLastDir())
				[fileName, filePath] = uigetfile(varargin{:});
			else
				if isempty(varargin)
					[fileName, filePath] = uigetfile(util.FilesUtil.getSetLastDir());
				else
					% handles the case where theres a list of filters
					filterList = varargin{1};
					if iscell(filterList)
						filter     = filterList{1};
						for i = 2:length(filterList)
							filter = [filter, ';', filterList{i}];
						end

						filter = fullfile(util.FilesUtil.getSetLastDir(), filter);
					else
						filter = fullfile(util.FilesUtil.getSetLastDir(), filterList);
					end
					
					varargin(1) = [];

					[fileName, filePath] = uigetfile(filter, varargin{:});
				end
			end
			
			if ~TypesUtil.isTxt(fileName) || ~TypesUtil.isTxt(filePath)
				filePath = '';
				return
			else
				util.FilesUtil.getSetLastDir(filePath);
			end
			
			% TODO: Check if the ", filesep," concatenation is really
			% necessary. This is adding double backslashes because I
			% THINK will provide better OS compatibility.
			%
			% makes sure the path is absolute
			filePath = FilesUtil.getFullPath(fullfile(filePath, fileName), false);
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