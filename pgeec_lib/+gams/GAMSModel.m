classdef GAMSModel < handle
	%GAMSMODEL Class that contains a collection of methods to communicate with GAMS software: pass dynamic parameters, run models, read results of simulations, etc.
	%
	% This class gives the user the ability to dynamically pass variables
	% in MATLAB format to a GAMS model file, execute the said model (.gms
	% file) and also retrieve data in MATLAB format -- as well as raw GAMS
	% format if needed. It can handle multi-dimensional sets and
	% parameters, indexed or non-indexed.
	%
	% DISCLAIMER: This class serves only as a GAMS<-->MATLAB
	% data-exchange facilitator and not a modeling tool. Thus, there's
	% no support for equation creation and the actual mathematical model
	% still needs to be created using GAMS code.
	%
	% Intended usage workflow:
	%
	% 1) Write a GAMS model declaring all the variables that will be
	% loaded dynamically through MATLAB.
	%
	% 2) Include the following line in your GAMS model:
	%
	% $if exist loader.gms $include loader.gms
	%
	% the name 'loader.gms' can be changed using model.<a href="matlab:doc('gams.GAMSModel/setVarLoaderPath')">setVarLoaderPath</a>('my_custom_path');
	% 
	% This is the line that will actually dinamically load all variable
	% data into the model, so make sure that all needed variables are
	% declared BEFORE this line.
	%
	% 3) In MATLAB, instantiate an GAMSModel object passing the path/name
	% to your model file
	% model = <a href="matlab:doc('gams.GAMSModel/GAMSModel')">GAMSModel</a>('my_model.gms');
	%
	% 4) Add all the dynamic variables using the methods of the class*
	%
	%    model.<a href="matlab:doc('gams.GAMSModel/addSet')">addSet</a>('hour_of_day', 1:24);
	%    model.<a href="matlab:doc('gams.GAMSModel/addScalar')">addScalar</a>('fuel_cost', 1.7);
	%    model.<a href="matlab:doc('gams.GAMSModel/addParameter')">addParameter</a>('hired_demands', {'peak' 20; 'off-peak' 25}, 'peak_names');
	%
	% *GAMS doesn't allow Tables to be loaded dynamically, however the user
	% can change the definition to a 2D parameter with the same functionality.
	% I.e.:
	%    Table car_rental_prices(torque, design) / ... /;
	% is equivalent to
	%    Parameter car_rental_prices(torque, design) / ... /;
	%
	%
	% 5) Run the model
	% model.<a href="matlab:doc('gams.GAMSModel/run')">run</a>();
	% if any error happens, use model.getExecutionLog()
	%
	% 6) Read the results. Any Scalar, Set, Parameter or Table defined in
	% GAMS code will be available for reading.
	%
	%    model.<a href="matlab:doc('gams.GAMSModel/read')">read</a>('my_variable');
	%    model.<a href="matlab:doc('gams.GAMSModel/getResult')">getResult</a>('my_variable|my_equation');
	
	properties(Constant, Access = private)
		TYPE_PARAMETER = 'parameter'; % String argument that defines the type of a variable = Parameter.
		TYPE_SET       = 'set';       % String argument that defines the type of a variable = Set.
		TYPE_VARIABLE  = 'variable';  % String argument that defines the type of a variable = variable.
	end
	
	properties(Constant, Access = public)
		STATUS_OK =  0;  % code for when the environment is up and ready for simulation.
		ERR_RGDX  = -1; % error code for missing rgdx MEX file.
		ERR_WGDX  = -2; % error code for missing wgdx MEX file.
		ERR_CMD   = -3; % error code when GAMSModel is unabled to use 'gams' command.
	end
	
	properties(Access = public)
		DEV        {util.TypesUtil.mustBeLogical(DEV)}        = false; % flag indicating whether or not to execute it in development/debug mode.
		KEEP_FILES {util.TypesUtil.mustBeLogical(KEEP_FILES)} = false; % flag indicating whether or not to keep the temporary files after the execution ends.
		WARNINGS   {util.TypesUtil.mustBeLogical(WARNINGS)}   = true;  % flag indicating whether or not to throw warnings.		
	end
	
	properties(Access = private)
		modelPath     {util.TypesUtil.mustBeTxt(modelPath)}     = ''; % path to the actual .gms model file
		
		varLoaderPath {util.TypesUtil.mustBeTxt(varLoaderPath)} = ''; % path to the .gdx input file
		gdxDumpPath   {util.TypesUtil.mustBeTxt(gdxDumpPath)}   = ''; % path to the .gms dump output file, since this file holds all the GAMS output, it cannot be delete until this object is deleted. For that reason, we generate a different name using the default 'inputData' filename and the current system time.
		tmpOutputPath {util.TypesUtil.mustBeTxt(tmpOutputPath)} = ''; % path to the .gdx dump output file, since this file holds all the GAMS output, it cannot be delete until this object is deleted. For that reason, we generate a different name using the .gms model filename and the current system time.
		
		variableBuffer {util.TypesUtil.mustBeCellArray(variableBuffer)} = [{}]; % structs containing data about the variables that are to be passed to GAMS solver.
		
		isReadyForExecution {util.TypesUtil.mustBeLogical(isReadyForExecution)} = false; % whether or not the model has all the data to be run
		isReadyForNonIndxd  {util.TypesUtil.mustBeLogical(isReadyForNonIndxd)}  = false; % whether or not the model has already dumped the indexed data and is ready to dump the non-indexed data
		isReadyForExport    {util.TypesUtil.mustBeLogical(isReadyForExport)}    = false; % whether or not the model has already been executed and is ready to export data.
		
		lstContent {util.TypesUtil.mustBeTxt(lstContent)} = 'No report available.'; % contents of the GAMS report file
	end
	
	methods(Access = public)
		
		% VV CONSTRUCTOR AND DESTRUCTOR
		function this = GAMSModel(modelPath, DEV, varLoaderPath, tmpOutputPath, gdxDumpPath)
		%GAMSMODEL Class constructor that accepts four parameters: modelPath (required), DEV (optional, default = false), varLoaderPath (optional), tmpOutputPath (optional) and gdxDumpPath (optional)
		%
		% model = GAMSMODEL(modelPath) creates a GAMSMODEL object pointing
		% to modelPath and using 'loader.gms' as the default
		% variable-loader file. The line to include in GAMS code AFTER the
		% declaration of all dynamic variables is:
		% $if exist loader.gms $include loader.gms
		% *NOTE: the $if statement should not be preceded by blanks.
		%
		% model = GAMSMODEL(modelPath, DEV) the same as the previous, but
		% if DEV=true, the model is executed in debug mode, generating
		% a lot of log messages about each step of the execution.
		%
		% model = GAMSMODEL(modelPath, DEV, varLoaderPath) creates a GAMSMODEL
		% object pointing to modelPath and using varLoaderPath as the
		% variable-loader file. See GAMSMODEL(modelPath).
		%
		% model = GAMSMODEL(modelPath, DEV, varLoaderPath, tmpOutputPath)
		% the same as before but using a user-defined temporary OUTPUT
		% variable-exchange .gdx file, the file that MATLAB actually reads
		% after GAMS has finished processing. Changing this is useful when
		% running multiple models under the same dir.
		%
		% model = GAMSMODEL(modelPath, DEV, varLoaderPath, tmpOutputPath, gdxDumpPath)
		% the same as before but using a user-defined temporary INPUT
		% variable-exchange .gdx file, the file that GAMS actually reads
		% when importing dynamic data to its workspace. Changing this is
		% useful when running multiple models under the same dir.
			import util.CommonsUtil
			import util.TypesUtil
			import util.FilesUtil
			import gams.GAMSModel

			if (nargin >= 2)
				TypesUtil.mustBeLogical(DEV);
				this.DEV = DEV;
			end
			
			% tests if GAMS is correctly installed
			[status, msg] = GAMSModel.checkGams();
			if status ~= GAMSModel.STATUS_OK && this.WARNINGS
				CommonsUtil.log('GAMS enviroment validation failed. Proceed with caution.');
				warning('GAMSModel:environmentError', msg);
			end
			
			if this.DEV
				CommonsUtil.log('Instantiating new GAMSModel object @ "%s".\n', FilesUtil.getParentDir(modelPath, false));
			end
		
			% main path
			this.setModelPath(modelPath);
			
			% var loader path
			if (nargin < 3)
				this.setVarLoaderPath('loader.gms');
			else
				this.setVarLoaderPath(varLoaderPath);
			end
			
			% temporary output path
			if (nargin < 4)
				outputPath = ['~output_' CommonsUtil.getTimestamp(true) '.gdx'];
				this.setTmpOutputPath(outputPath);
			else
				this.setTmpOutputPath(tmpOutputPath);
			end
			
			% dump path / input data
			if (nargin < 5)
				dumpPath = ['~input_' CommonsUtil.getTimestamp(true)];
				dumpPath = [dumpPath '.gdx'];
				this.setGdxDumpPath(dumpPath);
			else
				this.setGdxDumpPath(gdxDumpPath);
			end
			
			% log initialization result
			if this.DEV
				CommonsUtil.log(' : Model:    %s\n', this.getModelPath());
				CommonsUtil.log(' : Loader:   %s\n', this.getVarLoaderPath());
				CommonsUtil.log(' : Tmp out:  %s\n', this.getTmpOutputPath());
				CommonsUtil.log(' : Tmp dump: %s\n', this.getGdxDumpPath());
			end
			this.setIsReadyForExecution(true);
		end
		
		function delete(this)
		% Class destructor that provides shut-down gracefully capability
			import util.*
			
			if this.DEV
				CommonsUtil.log('Destroying unused GAMSModel object... ');
			end
			
			if ~this.KEEP_FILES
				this.removeTempFiles();
			end
			
			if this.DEV
				CommonsUtil.log('Done!\n');
			end
		end
		% ^^ CONSTRUCTOR AND DESTRUCTOR
		
		% VV GETTERS AND SETTERS FOR CLASS ATTRIBUTES
		function modelPath = getModelPath(this)
		% Returns the path to the .gms file that this handle represents.
		% This class is only meant to serve as a data-exchange facilitator
		% with GAMS, not a modeling tool. Therefore, the actual
		% mathematical model still needs to be created using GAMS code.
			modelPath = this.modelPath;
		end
		
		function varLoaderPath = getVarLoaderPath(this)
		% Returns the path to the GDX file loader.
		%
		% This file should be included in the model file as follows:
		% $if exist loader.gms $include loader.gms
			varLoaderPath = this.varLoaderPath;
		end
		
		function this = setVarLoaderPath(this, varLoaderPath)
		% Sets the path of the variable loader file, file that must be manually included by the user into the model. This is optional and usually of little concern to the end-user.
			import util.FilesUtil
		
			if ~strcmp(this.getVarLoaderPath(), varLoaderPath)
				this.setIsReadyForExport(false);
% 				this.varLoaderPath = strrep([FilesUtil.getParentDir(this.getModelPath()), filesep, varLoaderPath], '\', '/');
				this.varLoaderPath = FilesUtil.sanitizePath(varLoaderPath, false);
			end
		end
		
		function gdxDumpPath = getGdxDumpPath(this)
		% Returns the path of the temporary GDX dump file used by MATLAB to communicate with GAMS. This is optional and usually of little concern to the end-user.
			gdxDumpPath = this.gdxDumpPath;
		end
		
		function this = setGdxDumpPath(this, gdxDumpPath)
		% Sets the path/filename of the GDX temporary dump file used by MATLAB to communicate with GAMS. This is optional and usually of little concern to the end-user.
			import util.FilesUtil
		
			if ~strcmp(this.getGdxDumpPath(), gdxDumpPath)
				this.setIsReadyForExport(false);
% 				this.gdxDumpPath = strrep([FilesUtil.getParentDir(this.getModelPath()), filesep, gdxDumpPath], '\', '/');
				this.gdxDumpPath = FilesUtil.sanitizePath(gdxDumpPath, false);
			end
		end
		
		function tmpOutputPath = getTmpOutputPath(this)
		% Returns the path of the file used by GAMS to communicate with MATLAB. This is optional and usually of little concern to the end-user.
			tmpOutputPath = this.tmpOutputPath;
		end
		
		function this = setTmpOutputPath(this, tmpOutputPath)
		% Sets the path/filename of the GDX temporary dump file used by GAMS to communicate with MATLAB. This is optional and usually of little concern to the end-user.
			import util.FilesUtil
		
				if ~strcmp(this.tmpOutputPath(), tmpOutputPath)
				this.setIsReadyForExport(false);
				this.tmpOutputPath = FilesUtil.sanitizePath(tmpOutputPath, false);
% 				this.tmpOutputPath = strrep([FilesUtil.getParentDir(this.getModelPath()), filesep, tmpOutputPath], '\', '/');
			end
		end
		
		function isReadyForExport = getIsReadyForExport(this)
		%GETISREADYFOREXPORT Returns a flag indicating whether or not the model is ready to output data.
		%
		% If the user changes the variable buffer or changes any of the
		% file paths needed, they need to call GAMSModel.run() afterwards
		% to update the model, otherwise any tries to retrieve results from
		% the model will throw an error. This is made to prevent
		% inconsistencies within the model. Result will become available
		% again once a call to GAMSMODEL.run() is made.
			isReadyForExport = this.isReadyForExport;
		end
		
		function isReadyForExecution = getIsReadyForExecution(this)
		%GETISREADYFOREXECUTION Returns a flag indicating whether or not the model is ready to be run (as of right now: always true)
			isReadyForExecution = this.isReadyForExecution;
		end
		
		function variableBuffer = getBufferedVariables(this)
		%GETBUFFEREDVARIABLES Returns the list of variables currently stored in the variable pool.
		%
		% This consists of low-level structs constructed by GAMSModel and
		% meant to be passed to GAMS API.
		% NOTE: The structs are NOT updated after a call to
		% GAMSMODEL.run(), so the user shouldn't trust it to reflect the
		% exact same way that GAMS is seeing the variables. For debug, use
		% GAMSMODEL.getDumpedVariable('variableName') or
		% GAMSMODEL.getResult('variableName')
			variableBuffer = this.variableBuffer;
		end
		% ^^ GETTERS AND SETTERS FOR CLASS ATTRIBUTES
		
		
		% VV GETTERS AND SETTERS FOR GAMS VARIABLES
		function this = addSet(this, name, declaration, varargin)
		%ADDSET Adds a new Set to the buffer.
		%
		% --ONE-DIMENSIONAL SETS--
		%
		% model.ADDSET('my_set', value) if value is a 1D double array, creates a one-dimensional Set named 'my_set'.
		%
		% - If value is a 1D double array, an indexed Set will be created
		% using these values. E.g.:
		% model.ADDSET('my_set', [1 2 3])
		%
		% - If value is a 1D cell array of strings, an non-indexed Set will
		% be created using these texts. E.g.:
		% model.ADDSET('my_set', {'topeka', 'new-york'})
		%
		%
		% --MULTI-DIMENSIONAL SETS--
		%
		% model.ADDSET('my_set', value) if value is a n-D double array, creates a n-dimensional Set named 'my_set'.
		% 
		% - If 'my_set' is dependent of other sets, value should contain
		% only elements that are present on the Domain Set. GAMSModel will
		% not perfom domain-check until the model is run. E.g.:
		% model.ADDSET('my_set', [1 2 3; 4 5 6])
		%
		% - The following statement would throw an error, since a set can
		% only be defined with strings if it has a Domain Set:
		% model.ADDSET('favourite_colours', {'john', 'green';
		%						             'mary', 'red';
		%						             'lucas','blue'})
		%
		% The correct way to add a multi-dimensional set is
		% 1) add the first Domain Set to the buffer as 1D Set:
		% model.ADDSET('people', {'john', 'mary', 'lucas'})
		
		% 2) add the second Domain Set to the buffer as 2D Set:
		% model.ADDSET('colours', {'green', 'red', 'blue'})
		% 
		% 3) create the desired Set declaring with Set-dependency
		% model.ADDSET('favourite_colours', {'john', 'green';
		%						             'mary', 'red';
		%						             'lucas','blue'}, 'people', 'colours')
		%
		% This method also supports the m*n notation with numerical sets:
		% model.ADDSET('period_of_day', {'morning', 'afternoon', 'period_of_day'};
		% model.ADDSET('t', 1:24);
		% model.ADDSET('hour_of_day', {'1*12', 'morning';
		%							   '13*18', 'afternoon';
		%							   '19*24', 'evening', 't', 'period_of_day'};
			import util.*
		
			arguments = varargin;
			this.addNewVariablePreamble(name, declaration, varargin);
			
			% sets name and type of the variable.
			variableStruct.name = name;
			variableStruct.type = this.TYPE_SET;
			
			% domain sets lookup
			domainSets = this.getBufferedVariableByName(arguments);
			if isstruct(domainSets)
				domainSets = {domainSets};
			end
			
			% processes the declaration array
			
			% multi-dimensional Set with text indexes and Domain Sets
			if iscell(declaration) && ~isempty(arguments)
				if this.DEV
					CommonsUtil.log(' detected type: cell && has domain\n');
				end
				
				if isrow(declaration)
					declaration = declaration';
				end
				
				valueSize = size(declaration);
				
				if length(valueSize) > 2
					error('3D+ variables are not supported.');
				end
				
				% processes the m*n notation
				processedDeclaration = this.processShorthandNotation(declaration);
				[rowCount, colCount] = size(processedDeclaration);
				
				if colCount ~= length(domainSets)
					error('Wrong argument count. The number of Domain Sets should match the number of data columns');
				end
				
				variableStruct.val = zeros(rowCount, colCount);
				variableStruct     = this.injectUels(variableStruct, domainSets);
				
				for i = 1:rowCount
					for j = 1:colCount
						variableStruct.val(i, j) = this.getBufferedLabelNumber(domainSets{j}, num2str(processedDeclaration{i, j}), true);
					end
				end
				
			% multi-dimensional set with numerical values and defined Domain Sets
			elseif isnumeric(declaration) && ~isempty(arguments)
				if this.DEV
					CommonsUtil.log(' detected type: numeric && has domain\n');
				end
				
				if isrow(declaration)
					declaration = declaration';
				end
				variableStruct.val = declaration;
				variableStruct = this.injectUels(variableStruct, domainSets);
				
			% 1D Set with numerical indexes and no Domain Sets
			elseif isnumeric(declaration) && isempty(arguments)
				if this.DEV
					CommonsUtil.log(' detected type: numeric && no domain\n');
				end
				
				if isrow(declaration)
					declaration = declaration';
				end
				
				variableStruct.val  = declaration;
				variableStruct.uels = TypesUtil.num2CharCell(declaration');
				
			% 1D set with text indexes and no Domain Sets
			elseif iscell(declaration) && isempty(arguments)
				if this.DEV
					CommonsUtil.log(' detected type: cell && no domain\n');
				end
				
				if iscolumn(declaration)
					declaration = declaration';
				elseif ~isrow(declaration)
					error('Multi-dimensional labeled Sets need their respective Domain Sets. Try GAMSModel.addSet(''name'', {values}, ''domainSet1'', ''domainSet2''...)');
				end
				
				processedDeclaration = this.processShorthandNotation(declaration);
				
				variableStruct.val  = (1:length(processedDeclaration))';
				variableStruct.uels = processedDeclaration;
				if iscolumn(variableStruct.uels)
					variableStruct.uels = variableStruct.uels';
				end
			elseif TypesUtil.isTxt(declaration)
				if this.DEV
					CommonsUtil.log(' detected type: text\n');
				end
				
				variableStruct.uels = this.processShorthandNotation({declaration})';
				variableStruct.val  = (1:length(variableStruct.uels))';
			else
				error('Invalid input.');
			end
			
			this.appendToBuffer(variableStruct);
		end
				
		function this = addScalar(this, name, declaration)
		%ADDSCALAR Adds a new Scalar to the buffer.
		%
		% Syntax
		% model.ADDSCALAR(name, declaration) adds a new Scalar to the buffer
		% with value=declaration, which must be an numeric scalar.
		%
		% If a variable with the same name already exists, throws an error.
			import util.*
			
			this.addNewVariablePreamble(name, declaration, {});
			TypesUtil.mustBeScalar(declaration);
			
			variableStruct.name = name;
			variableStruct.type = this.TYPE_PARAMETER;
			variableStruct.val  = declaration;
			this.appendToBuffer(variableStruct);
		end
		
		function this = addParameter(this, name, declaration, varargin)
		%ADDPARAMETER Adds a new Parameter to the buffer.
		%
		% Syntax
		% ADDPARAMETER(name, declaration, domainSet1, domainSet2...)
		% creates a new parameter defined over specified Domain Sets.
		%
		% The syntax used to define declaration defines the behavior of the
		% method. It can be a cell-array (primarily) or a numeric matrix.
		% In any case, the last column is reserved for the element-values
		% of the Parameter, while the other columns define the 'address' of
		% the value (in relation to the Domain Sets). All the Domain Sets
		% must already have been buffered.
		%
		% Examples:
		%
		% - Using a cell array to define the rental cost of different cars:
		%
		% model.ADDPARAMETER('rental_cost', {'4WD', 'SUV',  100; ...
		%									 '4WD', 'Hatch', 50; ...
		%									 '2WD', 'SUV',   75; ...
		%									 '2WD', 'Hatch', 35}, 'torque', 'design');
		% the first argument is the name of the variable: 'rental_cost'
		% the second argument is the cell array, each column specifies the address over the Domain Set, the last column is reserved for the actual value of the element.
		% the rest of the arguments (varying) are the names of the Domain Sets over which the Parameter will be defined, there must be one for each column*.
		%
		% - *Using the shorthand notation to define the cost o eletrical
		% power load over 24 hours
		%
		% model.ADDPARAMETER('demand', [15.7, 15.2, 16.1, 16.1, ... 12.0, ... 15.8], 'time');
		%
		% in this case, suppose 'time' is a already-buffered set of 24
		% elements. If the user passes an array of also 24 elements, then
		% the values will be added in sequence, the first element of the
		% array will be considered the first hour of the day and so on,
		% until the 24th element.
		% When you use this shorthand notation a warning will be thrown.
		% Warnings can be disabled clearing the flag WARNINGS of the class:
		% model.WARNINGS = false;
			import util.*
		
			arguments		= varargin;
			domainSets		= this.addNewVariablePreamble(name, declaration, arguments);
			ommittedDomains = false; % if the user is using the short-hand mode, with no set definition, resulting in a sequential write.
			
			% checks if any of the Domain Sets are actually Sets
			for i = 1:length(domainSets)
				if ~strcmp(domainSets{i}.type, this.TYPE_SET)
					error(['"' domainSets{i}.name '" is not a valid Domain Set.']);
				end
			end
			
			% if it's a row-array of doubles, transposes it to a column array.
			if isrow(declaration) && isnumeric(declaration)
				declaration = declaration';
			end
			
			declaration  = this.processShorthandNotation(declaration);
			[rows, cols]  = size(declaration);
			
			% check if only numeric/text data was used, If last column
			% is numeric And if only non-array types are used.
			if iscell(declaration)
				for i = 1:rows
					for j = 1:cols
						A = j == cols;
						B = TypesUtil.isTxt(declaration{i, end});
						C = isscalar(declaration{i, end});
						D = isnumeric(declaration{i, end});
						isError = (A && B) || (~B && ~C) || (B && D) || (C && ~D);
						if isError
							error(['Invalid input at row=' num2str(i) ', col=' num2str(j) '.']);
						end
					end
				end
			elseif ~isnumeric(declaration)
				error('Input must be either an array of doubles/cells or a scalar value');
			end
				
				
			% Scalars are pretty easy to handle
			if TypesUtil.isScalar(declaration)
				if this.WARNINGS && ~isempty(domainSets)
					warning('Ignoring extra arguments because the input is a scalar.');
				end
				TypesUtil.mustBeScalar(declaration);
				
				variableStruct.name = name;
				variableStruct.type = this.TYPE_PARAMETER;
				variableStruct.val  = declaration;
				this.appendToBuffer(variableStruct);
				return;
				
				
			% if is an array (numeric or cell), it MUST have a domain.
			elseif isempty(domainSets)
				error('Not enough input arguments. Domain Sets missing.');
				
				
			% if the declaration was made with no domain labels specified,
			% this will add them automatically and in sequence, making it
			% a 2 row array.
			elseif cols == 1 && length(domainSets) == 1				
				ommittedDomains = true;
				
				if ~isrow(domainSets{1}.val) && ~iscolumn(domainSets{1}.val)
					error('Domain Set label omission is only supported if the Domain Set is one-dimensional, which "%s" isn''t', domainSets{1}.name);
				elseif rows ~= length(domainSets{1}.val)
					dif = rows - length(domainSets{1}.val);
					if dif > 0
						msg = 'Exceeding';
					else
						msg = 'Missing';
					end
					error('Input "%s" has %d elements but Domain Set "%s" has %d. %s %d.', name, rows, domainSets{1}.name, length(domainSets{1}.val), msg, dif);
				end
				
				if this.WARNINGS
					warning(['Domain labels not specified, but since "' name '" and "' domainSets{1}.name '" are the same length values will be added sequentially.'])
				end
				
				if iscell(declaration)
					declaration = [cell(rows, 1), declaration];
					for i = 1:rows
						declaration{i, 1} = this.getBufferedLabelNumber(domainSets{1}, domainSets{1}.uels{i}, true);
					end
				else
					declaration = [zeros(rows, 1), declaration];
					for i = 1:rows
						declaration(i, 1) = this.getBufferedLabelNumber(domainSets{1}, domainSets{1}.uels{i}, true);
					end
				end
			end
			
			[rows, cols]  = size(declaration);
			if cols-1 ~= length(domainSets)
				message = ['Wrong argument count. The number of Domain Sets (' num2str(length(domainSets)) ') '];
				message = [message  'should match the number of data columns (' num2str(max(0, cols-1)) ').'];
				error(message);
			end
			
			translatedVals = zeros(rows, cols);
			
			% val processing
			%{
			% organizes the values the user entered with matrices/cell
			% arrays into a form that GAMS understands
			%
			% cell arrays and numeric arrays have different access-syntaxes
			% in MATLAB (thank you, MathWorks)
			%}
			if iscell(declaration) % cell array handling
				if isempty(domainSets) % no domain set defined
					for i = 1:rows
						for j = 1:cols
							if TypesUtil.isTxt(declaration{i, j})
								error('Only numeric indices allowed for ommited Domain Sets declaration.');
							end
							translatedVals(i, j) = declaration{i, j};
						end
					end

					if this.WARNINGS && ~ommittedDomains
						warning('Domain check cannot be performed in ommited Domain Set declaration');
					end
				else % domain set defined
					conversion = false;
					for i = 1:rows
						for j = 1:cols
							if j == cols % here we dont need to use num2str since the last column will have been validated.
								translatedVals(i, j) = declaration{i, j};
							else
								if isnumeric(declaration{i, j})
									declaration{i, j} = num2str(declaration{i, j});
									conversion = true;
								end
								
								translatedVals(i, j) = this.getBufferedLabelNumber(domainSets{j}, declaration{i, j}, true);
							end
						end
					end
					if this.WARNINGS && conversion
						warning('Some numerical values were converted to string during domain checking.');
					end
				end
			else % handles numeric arrays
				for i = 1:rows
					for j = 1:cols
						translatedVals(i, j) = declaration(i, j);
					end
				end

				if this.WARNINGS && ~ommittedDomains
					warning('Domain checking is not performed in numeric Domain Set declaration');
				end
			end
			
			variableStruct.name = name;
			variableStruct.type = this.TYPE_PARAMETER;
% 			variableStruct.form = 'sparse';
			variableStruct      = this.injectUels(variableStruct, domainSets);
			variableStruct.val  = translatedVals;

			this.appendToBuffer(variableStruct);
		end
		
		function [value, labeled] = read(this, variableName, domainSet)
		%READ Returns the MATLAB-formatted value of GAMS variable.
		%
		% value = model.READ(variableName) returns the numerical value of the
		% variable, be it a scalar or an M-dimensional array.
		%
		% [value, labeled] = model.READ(variableName) returns the numerical value
		% of the variable and also the labeled values.
		%
		% _ = model.READ(variableName, domainSet) returns the value of the
		% variable for each point of the domainSet, use this when the
		% Parameter is sparse (when a position in an array has value =
		% zero, GAMS removes it).
			import util.*
			
			if nargin >= 3
				[value, labeled] = this.lookup(domainSet, variableName, 0);
				return;
			end
			
			variableStruct = this.readVariablePreamble(variableName);
			
% 			if variableStruct.dim ~= length(varargin)
% 				error('%d Domain Set(s) informed but "%s" has %d dimension(s). They must match.', length(varargin), variableName, variableStruct.dim);
% 			end

			value    = variableStruct.val(:, end);
			valsSize = size(variableStruct.val);
			
% 			valsSize
% 			variableStruct.uels{1}
			
			labeled = cell(valsSize(1), valsSize(2));
			
			for i = 1:valsSize(1)
				for j = 1:valsSize(2)
					if (j == valsSize(2)) && ...
							(strcmp(variableStruct.type, this.TYPE_PARAMETER) || ...
							 strcmp(variableStruct.type, this.TYPE_VARIABLE)) ...
						 || ~TypesUtil.isScalar(variableStruct.val(i, j)) || variableStruct.val(i, j) <= 0
% 						CommonsUtil.log('%2.4f   |   ', vals(i, j));
						labeled{i, j} = variableStruct.val(i, j);
					else
% 						CommonsUtil.log('%d   |   ', vals(i, j));
						labeled{i, j} = variableStruct.uels{j}{variableStruct.val(i, j)};
					end
				end
			end
		end
		% ^^ GETTERS AND SETTERS FOR GAMS VARIABLES
		
		% VV PUBLIC UTILITIES
		function setLabels = getLabels(this, setName)
		%GETLABELS A vector containing all labels (UELs) of the specified set
			import util.*
		
			TypesUtil.mustBeTxt(setName);
			if ~this.getIsReadyForExport()
				error('Model is not ready to export. Call GAMSModel.run() first.');
			end
			
			gdx_struct.name = setName;
			% By using "compress", "uels{1}" does not print out the whole list of uels
			% but only the uels from the set.
			gdx_struct.compress = true;
			struct    = rgdx(this.getTmpOutputPath(), gdx_struct);
			
			switch numel(struct.uels)
				case 0
					setLabels = {};
				case 1
					setLabels = struct.uels{1};
				otherwise
					setLabels = struct.uels;
			end
		end
		
		function uelNumber = getLabelNumber(this, setName, label)
		%GETLABELNUMBER Returns the UEL number of a given UEL/label
			import util.*
		
			TypesUtil.mustBeTxt(label);
			
			struct = this.getResult(setName);
			alluels = struct.uels{1};

			% The following line finds the number of the label in the list
			% that was generated before
			uelNumber = find(strcmp(alluels(:), label));
		end
		
		function uelNumber = getBufferedLabelNumber(this, set, label, throwNotFoundError)
		%GETBUFFEREDLABELNUMBER Returns the UEL number for a given label. The set must already be in buffer or can be passed directly to the method.
		% model.GETBUFFEREDLABELNUMBER(set, label) returns the label number
		% of label. If set is a struct containing a 'uels' field, then this
		% set will be searched.
		%
		% model.GETBUFFEREDLABELNUMBER(set, label, throwNotFoundError) if
		% throwNotFoundError is set to true, then the method will throw an
		% error if the label is not found.
			import util.*
			
			if nargin < 4
				throwNotFoundError = true;
			else
				TypesUtil.mustBeLogical(throwNotFoundError);
			end
			if ~isfield(set, 'uels')
				if isstruct(set) && isfield(set, 'name')
					error(['Variable "' set.name '" doesn''t have a UEL list.']);
				elseif isstruct(set)
					error('Variable doesn''t have a UEL list.');
				end
				
				TypesUtil.mustBeTxt(set);
				TypesUtil.mustBeTxt(label);
				
				struct = this.getBufferedVariableByName(set, true);
				if ~isfield(struct, 'uels')
					error(['Variable "' set '" doesn''t have a UEL list.']);
				end
			else
				struct = set;
			end
			
% 			alluels = struct.uels{1};
%			NOTE: should we surround 1D UELs array with a cell just do to
%			be consistent with rgdx results?
			alluels = struct.uels;

			% The following line finds the number of the label in the list that was
			% generated before
			uelNumber = find(strcmp(alluels(:), label));
			
			if isempty(uelNumber) && throwNotFoundError
				error(['Unable to find "' label '" on Set "' struct.name '"']);
			end
		end
		
		function lstContent = getExecutionLog(this)
		%GETEXECUTIONLOG Returns a string containing a report of the compilation and execution of the model.
		
% 			if ~this.getIsReadyForExport()
% 				error('Model isn''t ready for export. Use GAMSModel.run() first.');
% 			else
% 				lstContent = this.getLstContent();
% 			end

			lstContent = this.getLstContent();
		end
		
		function timeElapsed = removeTempFiles(this, deleteTmpOutput)
		%REMOVETEMPFILES Removes the temporary files used to communicate with GAMS.
		% model.REMOVETEMPFILES() Removes the temporary files used to
		% communicate with GAMS. After this, is impossible to read any more variables.
		%
		%  model.REMOVETEMPFILES(deleteTmpOutput) if deleteTmpOutput is set
		%  to FALSE, removes all the temporary files EXCEPT the one used to
		%  retrieve variables, so that model.<a href="matlab:doc('gams.GAMSModel/read')">read()</a> is still available.
			import util.*
		
			timeElapsed = tic();
			
			if this.DEV
				CommonsUtil.log('Removing temporary files... ');
			end
			
			if nargin < 2
				deleteTmpOutput = true;
			else
				TypesUtil.mustBeLogical(deleteTmpOutput);
			end
			
			% Set a couple of warnings to temporarily issue errors (exceptions)
			s = warning('error', 'MATLAB:DELETE:Permission');
			warning('off', 'MATLAB:DELETE:FileNotFound');
			
			errorOccurred = false;
			try
				FilesUtil.forceDelete(this.getGdxDumpPath());
			catch
				errorOccurred = true;
% 				CommonsUtil.log([' *error while deleting files: ' getReport(e, 'basic') '*']);
			end
			try
				FilesUtil.forceDelete(this.getVarLoaderPath());
			catch
				errorOccurred = true;
% 				CommonsUtil.log([' *error while deleting files: ' getReport(e, 'basic') '*']);
			end
			try
				FilesUtil.forceDelete(this.getLstPath());
			catch
				errorOccurred = true;
% 				CommonsUtil.log([' *error while deleting files: ' getReport(e, 'basic') '*']);
			end
			
			try
				if deleteTmpOutput
					FilesUtil.forceDelete(this.getTmpOutputPath());
					this.setIsReadyForExport(false);
				else
					FilesUtil.hideFile(this.getTmpOutputPath());
				end
			catch
				errorOccurred = true;
% 				CommonsUtil.log([' *error while deleting files: ' getReport(e, 'basic') '*']);
			end
			
			if errorOccurred && this.DEV
				CommonsUtil.log('*error while deleting one or more files* ');
			end
			
			% Restore the warnings back to their previous state
			warning('on', 'MATLAB:DELETE:FileNotFound');
			warning(s);
			
			timeElapsed = toc(timeElapsed);
			if this.DEV
				CommonsUtil.log('Done! %5.0f ms\n', timeElapsed*1000);
			end
		end
		
		function [value, labeled] = lookup(this, search, lookup, fill)
		% Perfoms something similar to a left-join of search and lookup.
		% In techinal terms: transforms A(Z) and B(Z) in A(B), where A and Z are Sets and B is a Parameter
		%
        % Syntax:
        %
		% values = model.LOOKUP(search, lookup) searches for values of
		% "search" over the "lookup" labels. When a match is found, returns
		% the value of "lookup".
        % If, for a given position, no match is found, NaN will be returned
        % at that position.
        % 
        % [values, labeled] = model.LOOKUP(search, lookup) the same as
        % before, but returns also the complete tuples to "labeled". This
        % is particular useful if lookup is a set, when there're no values,
        % only textual labels
		%
        % _ = model.LOOKUP(search, lookup, fill) the same as before, but
        % instead of filling not-founds with NaN, fills it with the numeric
        % value "fill"
        %
        % LOOKUP always uses the value-column of search (aka the last
        % column) and the first column of lookup to form matches. This
        % doesn't matter if both variables are 1D, but in case they're
        % multi-dimensional this can cause unexpected behavior unless you
        % know what you're doing.
        % 
		% # There's a detailed example on the tests folder #
			import util.*
		
			if nargin < 4
				fill = NaN;
			end
		
			[~, search] = this.read(search);
			[~, lookup] = this.read(lookup);
			
			labeled		= search;
			
			[labeledRowCount, ~] = size(search);
			[lookupRowCount,  ~] = size(lookup);
			
			labeled(:, end) = cell(labeledRowCount, 1);
			
			if TypesUtil.isScalar(fill)
				value = ones(length(search), 1)*fill;
			else
				value = nan(length(search), 1);
			end
			
			for i = 1:labeledRowCount
				for j = 1:lookupRowCount
					try % try catch because the equality below can throw errors.
						if strcmp(num2str(search{i, end}), num2str(lookup{j, 1}))
							labeled{i, end} = lookup{j, end};
							
							if TypesUtil.isScalar(lookup{j, end})
								value(i) = lookup{j, end};
							end
						end
					catch
						continue;
					end
% 					mappedValues{i, end} = lookup{j, end};
				end
			end
		end
		
		function elapsedTime = exportExecutionReport(this, filePath)
		% Exports the execution log to a txt file
		%
		% Examples:
		%
		% model.EXPORTEXECUTIONREPORT(filePath) exports the execution
		% report into filePath
		%
		% model.EXPORTEXECUTIONREPORT() open a dialog for dir selection
		%
		% timeElapsed = model.EXPORTEXECUTIONREPORT(_) returns the time
		% elapsed to perform the dump
			import util.CommonsUtil
			import util.FilesUtil
			import util.TypesUtil
			
			elapsedTime = 0;
			if nargin < 2
				if this.DEV
					CommonsUtil.log('Waiting for user input... ');
				end
				
				[fileName, filePath] = uiputfile(['GAMS_report_', CommonsUtil.getTimestamp(true) , '.txt']);
				if ~TypesUtil.isTxt(fileName) || ~TypesUtil.isTxt(filePath)
					if this.DEV
						CommonsUtil.log('Canceled\n');
					end
					
					return;
				end
				
				filePath = fullfile(filePath, fileName);
				
				if this.DEV
					CommonsUtil.log(' <%s>\n', filePath);
				end
			end
			
			elapsedTime = tic();
			
			if this.DEV
				CommonsUtil.log('Exporting execution log... ');
			end
			
			try
				FilesUtil.writeTextFile(filePath, this.getExecutionLog());
				
				elapsedTime = toc(elapsedTime);
				if this.DEV
					CommonsUtil.log('Done! %5.0f ms\n', elapsedTime*1000);
				end
			catch e				
				elapsedTime = toc(elapsedTime);
				if this.DEV
					CommonsUtil.log('Fail. %5.0f ms\n', elapsedTime*1000);
				end
				
				rethrow(e);
			end
		end
		
		function totalTime = exportModelData(this, dir, newGdxDumpPath, newModelPath)
		% Creates the files with all the variables that were added to the model.
		% 
		% This way, is possible to run the model externally with no help
		% from this class. Very helpful for debugging
		%
		% Examples:
		% model.exportModelData(); exports the loader.gms file and the
		% temporary output file (_timestamp_.gdx) after prompting the user
		% with a path selection window.
		%
		% model.exportModelData(dir); same as before, but places the
		% files in dir
			import util.FilesUtil
			import util.LastDirHelper
			import util.CommonsUtil
			import util.TypesUtil
			
			totalTime = tic();
			TypesUtil.mustBeTxt(dir);
			CommonsUtil.log('Exporting model data to "%s"...\n', dir);
			
			% the var loader path cannot be changed because it's hard coded
			% in the GAMS model file
			if nargin < 3
				newGdxDumpPath = 'data.gdx';
			end
			if nargin < 4
				newModelPath = 'main.gms';
			end
			newVarLoaderPath = FilesUtil.getFileName(this.getVarLoaderPath());
			
			newGdxDumpPath = fullfile(dir, newGdxDumpPath);
			newVarLoaderPath = fullfile(dir, newVarLoaderPath);
			newModelPath = fullfile(dir, newModelPath);
			
			% Exports the GDX data file
			this.flushVariables(newGdxDumpPath);
			
			% Export the var loader file
			this.writeVarLoaderFile(newVarLoaderPath, newGdxDumpPath);
			
			% Export the main GMS file
			copyfile(this.getModelPath(), newModelPath);
			
			totalTime = toc(totalTime);
		end
		% ^^ PUBLIC UTILITIES
		
		% VV PUBLIC CONTROL INTERFACE
		function totalTime = run(this)
		%RUN Executes the model with the given variables.
		%
		% The execution process consists of
		% 1) Flushing the buffer to a <a href="matlab:doc('gams.GAMSModel/getTmpOutputPath')">temporary file</a>.
		% 2) Programatically writing the GXD <a href="matlab:doc('gams.GAMSModel/getTmpOutputPath')">data loader file</a>
		% 3) Making a system call (equivalent to cmd): gams "modelName.gms" gdx="tmpOutputPath.gdx"
		% 4) If KEEP_FILES flag is cleared, remove temporary files.
		%
		% After the process is over, all the variables from GAMS workspace
		% will be available in the data-exchange results file and will be
		% available for reading. IF, however, you <a href="matlab:doc('gams.GAMSModel/removeTempFiles')">clear the temporary files</a>
		% the model won't be able to read variables anymore.
			import util.CommonsUtil
			import util.TypesUtil
			
			% checks if model is ready for execution before anything
			if ~this.getIsReadyForExecution()
				error('Model is not ready for execution. Please finish setting it up.');
			end
			
			% initializes the clock tic() and the totalTime accumulator
			runTime = tic();
			totalTime = 0;
			
			% initializes the execution report in case things go south
			% during the execution
			this.setLstContent('Unable to retrieve report.');
			
			% while the model is running it becomes unavailable for export
			this.setIsReadyForExport(false);
			
			try
				if (this.DEV)
					CommonsUtil.log('-- Starting execution...\n');
				end

				% passes all the registered variables to the .gdx file
				totalTime = totalTime + this.flushVariables();
				
				% writes the $gdxin load statements
				totalTime = totalTime + this.writeVarLoaderFile();

				if (this.DEV)
					CommonsUtil.log('Making system call to GAMS and running the model...\n');
% 					CommonsUtil.log('Passing "%s" to GAMS solver and running... ', FilesUtil.shortenPath(this.getModelPath()));
% 					CommonsUtil.log('Passing "%s" to GAMS solver and running... {\n', FilesUtil.shortenPath(this.getModelPath()));
				end

				% builds the command line instruction
% 				command = ['cd "' FilesUtil.getParentDir(this.getModelPath) '" && '];
				command = '';
				command = [command 'gams "' strrep(this.modelPath, '/', '\') '" gdx="' this.getTmpOutputPath() '"'];
				
				if (this.DEV)
					CommonsUtil.log('Issuing [%s]...\n', command)
				end
				
                % performs a system call
                [status, cmdout] = system(command);
				
				% checks if execution went ok
				%
				% FIXME: some statuses don't mean that the execution failed,
				% some are just warnings a good example of that is
				% status=112
				% https://www.gams.com/latest/docs/UG_GAMSReturnCodes.html
				%
				% TODO: map the statuses to the actual messages
				%
				% TODO: try to read the report file and tell the user why
				% the error occurred
				if (status ~= 0)
					runTime = toc(runTime);
					totalTime = totalTime + runTime;
					
					% retrieves the execution report (.lst file)
					totalTime = totalTime + this.importExecutionLog();
					
					if (this.DEV)
						CommonsUtil.log('Failed. %5.0f ms \n', runTime*1000);
						CommonsUtil.log('-- Aborted %5.0f ms\n\n', totalTime*1000);
					end
					
					% redirects the execution to the CATCH statement
					error(['Error executing "', this.getModelPath(), '" (<a href="matlab:web(''https://www.gams.com/latest/docs/apis/python/classgams_1_1workspace_1_1GamsExitCode.html'', ''-browser'')">status=', num2str(status), '</a>).', newline, cmdout, newline, 'See "', this.getLstPath(), '" for details or use <a href="matlab:helpPopup(''gams.GAMSModel.getExecutionLog'')">GAMSModel.getExecutionLog()</a>']);
				end

				% if everything went fine, logs the run time
				runTime = toc(runTime);
				totalTime = totalTime + runTime;
				if (this.DEV)
					CommonsUtil.log('Done! %5.0f ms\n', runTime*1000);
				end

				% retrieves the execution report (.lst file)
				totalTime = totalTime + this.importExecutionLog();

				% removes temporary files excepted results
				if ~this.KEEP_FILES
					totalTime = totalTime + this.removeTempFiles(false);
				end
				
				% logs the end of execution
				if (this.DEV)
					CommonsUtil.log('-- Execution finished. Total time elapsed %5.0f ms\n', totalTime*1000);
				end

				% the model is now ready for export
				this.setIsReadyForExport(true);
			catch e
				if ~TypesUtil.isScalar(runTime)
					toc(runTime);
				end
				if (this.DEV)
					CommonsUtil.log('\n');
				end
				rethrow(e)
			end
		end
		
		function this = clearBuffer(this, varargin)
		%CLEARBUFFER Removes variables from the buffer.
		%
		% model.CLEARBUFFER() clears entire buffer.
		%
		% model.CLEARBUFFER(variable1, variable2...) removes variables 1, 2 and so on from the pool.
			import util.*
		
			if isempty(varargin)
				this.setBufferedVariables([{}]);
				return;
			end
			
			for i = 1:length(varargin)
				variableName = varargin{i};
				TypesUtil.mustBeTxt(variableName);

				variableList = this.getBufferedVariables();
				newList    = [{}];
				for j = 1:length(variableList)
					if ~strcmp(variableList{j}.name, variableName)
						newList = [newList; variableList{j}];
					end
				end
				
				this.setBufferedVariables(newList);
			end
		end
		% ^^ PUBLIC CONTROL INTERFACE
		
		% VV PUBLIC HELPER METHODS
		%{
		   functions created as internal helper methods AND are useful to
		   the end-user.
		%}
		function result = getBufferedVariableByName(this, variableName, throwNotFoundError)
		%GETBUFFEREDVARIABLEBYNAME Returns the buffered data of variables in the exact same structure that will be forwarded to the GAMS API.
		%
		% model.GETBUFFEREDVARIABLEBYNAME(variableName) Searches for
		% variableName on the pool. If nothing is found, throws an error.
		% If variableName is a list of chars, returns a list of results.
		% Throws an error when unable to find any of the names on the list.
		%
		% model.GETBUFFEREDVARIABLEBYNAME(variableName, false) Searches for
		% variableName on the pool. If nothing is found, returns an empty
		% struct.
		% Ignores when unable to find any of the names on the list. If no
		% variable is found, returns an empty struct.
		% If only one register is found, returns a single struct, if more
		% than one are found, returns and cell array of structs.
			import util.*
		
			if util.TypesUtil.isTxt(variableName)
				variableName = {variableName};
			elseif ~iscell(variableName)
				error('Argument must be char, string or a cell-array with the name(s) of the variable(s) to be retrieved.');
			end
			if exist('throwNotFoundError', 'var')
				TypesUtil.mustBeLogical(throwNotFoundError);
			else
				throwNotFoundError = true;
			end
			function variable = find(search, buffer)
				variable = {};
				for j = 1:length(buffer)
					if strcmp(buffer{j}.name, search)
						variable = buffer{j};
						return;
					end
				end
			end
			
			result = {};
			paramList = this.getBufferedVariables();
			for i = 1:length(variableName)
				temp = find(variableName{i}, paramList);
				
				if ~isempty(temp) && i == 1
					result = temp;
				elseif ~isempty(temp)
					result = {result; temp};
				elseif throwNotFoundError
					error(['Parameter "' variableName{i} '" not found.']);
				end
			end
		end
		
		function variable = getResult(this, names)
		%GETRESULT Returns the raw data of a GAMS variable.
		%
		% model.GETRESULT(variableName) returns the data of variableName
		% after the GAMS model has been run, not necessarily a variable
		% that has been put in buffer, i.e. variableName can be ANY
		% variable that has been declared inside the GAMS file model.
		%
		% Throws error if <a href="matlab:doc('gams.GAMSModel/run')">GAMSModel.run()</a> hasn't been called.
		%
		% The return object is a low-level struct field (See <a href="https://www.gams.com/latest/docs/T_GDXMRW.html">GAMS - GDXMRW</a>).
			import util.*
		
			if ~this.getIsReadyForExport()
				error('Model is not ready to export. Call GAMSModel.run() first.');
			end
			
			if isempty(names)
				error('Name cannot be empty.');
			elseif ~iscell(names)
				if ~TypesUtil.isTxt(names)
					error('Input must be either a char array or a cell array of chars');
				end
				names = {names};
			end
			
			for i = 1:length(names)
				try
					if this.DEV
						CommonsUtil.log(['Trying to read as non-indexed variable "', names{i}, '"... ']);
					end

					if i == 1
						variable = rgdx(this.getTmpOutputPath(), struct('name', names{i}));
					else
						variable = [{variable}; {rgdx(this.getTmpOutputPath(), struct('name', names{i}))}];
					end

					if this.DEV
						CommonsUtil.log('Done!\n');
					end
				catch e
					if this.DEV
						CommonsUtil.log('Fail!\n');
					end
					rethrow(e);
				end
			end
		end
		% ^^ PUBLIC HELPER METHODS
	end
	
	methods(Access = private)
		% VV GETTERS AND SETTERS FOR CLASS ATTRIBUTES
		function this = setIsReadyForExecution(this, isReadyForExecution)
		%SETISREADYFOREXECUTION Marks the model as ready or not-ready for execution
			this.isReadyForExecution = isReadyForExecution;
		end
		
		function this = setIsReadyForExport(this, isReadyForExport)
		%SETISREADYFOREXPORT Marks the model as ready or not-ready for execution
			this.isReadyForExport = isReadyForExport;
		end
		
		function this = setModelPath(this, modelPath)
		%SETMODELPATH Sets the path to file containg the actual GAMS code.
			import util.FilesUtil
			
			if ~strcmp(this.getModelPath(), modelPath)
				this.setIsReadyForExport(false);
				this.modelPath = FilesUtil.sanitizePath(modelPath, true);
			end
		end
		
		function this = setBufferedVariables(this, variableBuffer)
		%SETBUFFEREDVARIABLES Sets the variable-list buffer all at once. Normally only useful when clearing the buffer.
			this.setIsReadyForExport(false);
			
			% guarantees the buffer is always a list, and not a struct.
			if isstruct(variableBuffer)
				variableBuffer = {variableBuffer};
			end
			
			if isrow(variableBuffer)
				variableBuffer = variableBuffer';
			elseif ~iscolumn(variableBuffer)
				error('Variable buffer must be a 1D cell array.');
			end
			
			this.variableBuffer = variableBuffer;
		end
		
		function lstPath = getLstPath(this)
		%GETLSTPATH Returns the path of the GAMS report file, used for debugging.
			import util.StringsUtil
		
			if StringsUtil.endsWith(this.getModelPath(), '.gms')
				lstPath = strrep(this.getModelPath(), '.gms', '.lst');
			else
				lstPath = [this.getModelPath(), '.lst'];
			end
		end
		
		function this = setLstContent(this, lstContent)
		%SETLSTCONTENT Sets the value of the lstContent attribute, class-variable used as buffer of the .lst file generated by GAMS.
			this.lstContent = lstContent;
		end
		
		function lstContent = getLstContent(this)
		%GETLSTCONTENT Returns the last report file generated by GAMS + GAMSModel.run().
			lstContent = this.lstContent;
		end
		% ^^ GETTERS AND SETTERS FOR CLASS ATTRIBUTES
		
		% VV INTERNAL HELPER METHODS		
		function structuredVariable = readVariablePreamble(this, variableName)
		%READVARIABLEPREAMBLE Rountine executed before a variable is readed.
		%
		% Checks if the domain sets informed are ok and throws an error if
		% not.
		% -If this the API is set to DEV mode, also prints a log
		% message.
			import util.*
		
% 			this.setIsReadyForExport(true); debug
			
			TypesUtil.mustBeTxt(variableName);
			if ~this.getIsReadyForExport()
				error('Model is not ready to export. Call GAMSModel.run() first.');
			end
			
			if this.DEV
				CommonsUtil.log('Reading variable "%s".\n', variableName);
			end
			
			structuredVariable = this.getResult(variableName);
		end
		
		function structuredDomainSets = addNewVariablePreamble(this, name, declaration, domainSets)
		%ADDNEWVARIABLEPREAMBLE Rountine executed before a new variable is buffered.
		%
		% - Checks if the domain sets informed are ok and throws an error if
		% not.
		% - Checks if the new variable name is unique and unsets the
		% isReadyForExport flag.
		% - If this the API is set to DEV mode, also
		% prints a log message.
			import util.*
			
			TypesUtil.mustBeTxt(name);
			
			if ~isempty(this.getBufferedVariableByName(name, false))
				error('Variable already defined. Use GAMSModel.clearBuffer(variableName).');
			end
			
			if length(size(declaration)) > 2
				error('3D+ declarations are not currently supported, planify your input.');
			end
			
			[rows, cols] = size(declaration);
			if rows < 1 || cols < 1
				error('Empty declaration is not allowed');
			elseif rows > 1 && cols > 1 && isempty(domainSets)
				error('Not input arguments. Multi-dimensional variables require one Domain Set for each column.');
			end
			
			if this.DEV
				CommonsUtil.log('Adding variable "%s', name);
				if ~isempty(domainSets)
					for i = 1:length(domainSets)
						TypesUtil.mustBeTxt(domainSets{i});
						if i ~= 1
							CommonsUtil.log(', ');
						else
							CommonsUtil.log('(');
						end
						CommonsUtil.log('%s', domainSets{i});
					end
					CommonsUtil.log(')');
				end
				CommonsUtil.log('".\n');
			end
			
			structuredDomainSets = this.getBufferedVariableByName(domainSets, true);
			if isstruct(structuredDomainSets)
				structuredDomainSets = {structuredDomainSets};
			end
			
			% If it has been modified, it means it's not ready for export.
			this.setIsReadyForExport(false);
		end
		
		function this = appendToBuffer(this, variableStruct)
		%APPENDTOBUFFER Apends a new variable to the buffer, ensuring that it has a name and that the buffer is kept as a column cell-array.
			import util.*
			
			if ~isfield(variableStruct, 'name')
				error('Struct doesn''t have a "name" field.');
			end
			
			this.setBufferedVariables([this.getBufferedVariables(); {variableStruct}]);
		end
		
		function param = injectUels(~, param, uelSets)
		%INJECTUELS Inserts a list of values as the UELs of a parameter, useful when defining multi-dimensional sets.
			import util.*
			
			if isstruct(uelSets)
				uelSets = {uelSets};
			end
			param.uels = [];
			for k = 1:length(uelSets)
				if ~isfield(uelSets{k}, 'uels')
					if ~isfield(uelSets{k}, 'val')
						error(['Error building set "' param.name '". Domain set "' uelSets{k}.name '" has no values nor UELs']);
					end
					uelSets{k}.uels = TypesUtil.num2CharCell(uelSets{k}.val');
				end

				if k == 1
					param.uels = uelSets{k}.uels;
				else
					param.uels = {param.uels, uelSets{k}.uels};
				end
			end
		end
		
		% 		function processedDeclaration = processShorthandNotation(~, declaration, mustBeCellArray)
		function processedDeclaration = processShorthandNotation(~, declaration)
		%PROCESSSHORTHANDNOTATION
			import util.*
			
			if ~iscell(declaration)
				processedDeclaration = declaration;
				return;
			end
		
% 			if nargin < 3
% 				TypesUtil.mustBeCellArray(declaration);
% 			else
% 				 TypesUtil.mustBeLogical(mustBeCellArray)
% 				 if mustBeCellArray
% 					 TypesUtil.mustBeCellArray(declaration);
% 				 end
% 			end
			
			[rowCount, colCount] = size(declaration);
			
			% processing of n*m notation
			processedDeclaration = [];
			for i = 1:rowCount
				field = declaration{i, 1};

				% if the field uses the 'm*n' syntax:
				if TypesUtil.isTxt(field) && ~isempty(regexp(field, '^[0-9]+*[0-9]+$', 'once'))
					init = field(1:strfind(field, '*')-1);
					init = str2double(init);

					final = field(1+strfind(field, '*'):end);
					final = str2double(final);

					if final <= init
						error('Final index must be greater than initial index.');
					end

					for k = init:final
						tuple = [{}];
						tuple = [tuple, num2str(k)];
						for j = 2:colCount
							tuple = [tuple, declaration{i, j}];
						end

						processedDeclaration = [processedDeclaration; tuple];
					end
				% if it doesn't use it:
				else
					processedDeclaration = [processedDeclaration; declaration(i, :)];
				end
			end
		end
		% ^^ INTERNAL HELPER METHODS
		
		
		% VV RUN SUPPORT
		% We adopted a pattern where all functions called by the .run()
		% method are to be timed so the user can evaluate the model
		% execution time.
		function timeElapsed = flushVariables(this, dumpPath)
		% Flushes the variable buffer data to a temporary data-exchange file.
		%
		% Since the GAMS API overwrites the exchange file every time it's
		% called, we need to flush the data all at once. A problem with
		% this is that the API doesn't accept lists of variables. The API
		% syntax is: wgdx(file_name, struct1, struct2...).
		% Therefore, we need build a string containing the data of all the
		% variables that we want to flush and then use <a href="matlab:doc('eval')">eval</a> function.
			import util.*
		
			timeElapsed = tic();
			if ~this.getIsReadyForExecution()
				error('Model is not ready for execution. Please finish setting it up.');
			end			
			if (this.DEV)
% 				CommonsUtil.log('Flushing variables to "%s"... ', FilesUtil.shortenPath(this.getGdxDumpPath()));
				CommonsUtil.log('Flushing variables... ');
			end
			if nargin < 2
				dumpPath = this.getGdxDumpPath();
			end
			
			% Query will look like wgdx('dump.gdx', variableList{1}, variableList{2}...);
			%FIXME: we could use a list and do wgdx(list{:}) instead of
			%using eval(). Faster, cleaner and WAY safer.
			queryStr = 'wgdx(dumpPath';
			
			variableList = this.getBufferedVariables();
			for i = 1:length(variableList)
				queryStr = [queryStr ', variableList{' num2str(i) '}'];
			end
			
			queryStr = [queryStr ');'];
			eval(queryStr);
			
			timeElapsed = toc(timeElapsed);
			if (this.DEV)
				CommonsUtil.log('Done! %5.0f ms\n', timeElapsed*1000);
			end
		end
				
		% TODO: consider using $loadDC
		function timeElapsed = writeVarLoaderFile(this, varLoaderPath, gdxDumpPath)
		%WRITEVARLOADERFILE Programatically creates the variable-loading GAMS file.
		%
		% When loading dynamic variables, the user needs to include a file
		% that will load all the variables they want to dynamically load.
		% This method creates that file. It will load all the variables
		% that were flushed to the temporary file into GAMS workspace.
		% The only line the user needs to add to their model is:
		% $if exist loader.gms $include loader.gms
			import util.FilesUtil
			import util.CommonsUtil
		
			timeElapsed = tic();
			
			if ~this.getIsReadyForExecution()
				error('Model is not ready for execution. Please finish setting it up.');
			end
			if (this.DEV)
				CommonsUtil.log('Creating GMS loader file: "%s"... ', FilesUtil.shortenPath(this.getVarLoaderPath()));
			end
			if nargin < 2
				varLoaderPath = this.getVarLoaderPath();
			end
			if nargin < 3
				gdxDumpPath = this.getGdxDumpPath();
			end
			
			%initialization
			varLoaderPath = FilesUtil.removeExtension(varLoaderPath);
			varLoaderPath = [varLoaderPath '.gms'];
			
			fid = fopen(varLoaderPath, 'w');
			if (fid == -1)
				toc(timeElapsed);
				error(['Unable to create file "', this.getVarLoaderPath(), '"']);
			end
			
			%header
			header = sprintf('$gdxin "%s"\n', gdxDumpPath);
			fprintf(fid, "%s", header);
			
			%content
			variableList = this.getBufferedVariables;
			for i = 1:length(variableList)
				fprintf(fid, ['$load ', variableList{i}.name, newline]);
			end
			
			% footer
			fprintf(fid, '$gdxin');
			
			if fclose(fid) ~= 0 && this.DEV
				CommonsUtil.log('*unable to close file* ');
			end
			
			timeElapsed = toc(timeElapsed);
			if (this.DEV)
				CommonsUtil.log('Done! %5.0f ms\n', timeElapsed*1000);
			end
		end
		
		function timeElapsed = importExecutionLog(this)
		%IMPORTEXECUTIONLOG reads the execution log and stores it in memory.
			import util.*
			
			timeElapsed = tic();
		
			if (this.DEV)
				CommonsUtil.log('Obtaining execution log... ');
			end
		
			try
				this.setLstContent(fileread(this.getLstPath()));
				
				if (this.DEV)
					CommonsUtil.log('Done!');
				end
			catch e
				CommonsUtil.log(['Failed to acquire report. ', getReport(e, 'basic', 'hyperlinks', 'off')]);
			end
			
			timeElapsed = toc(timeElapsed);
			if this.DEV
				CommonsUtil.log(' %5.0f ms\n', timeElapsed*1000);
			end
		end
		% ^^ RUN SUPPORT
	end
	
	methods(Access = public, Static)
		function mustBeGAMSModelObject(object)
		%MUSTBEGAMSMODELOBJECT Checks if a variable is instance of GAMSModel (allows null). Throws error if not.
		
			if ~util.TypesUtil.instanceof(object, 'GAMSModel') && ~isempty(object)
				error(['Variable "', inputname(1), '" must be GAMSModel instance.']);
			end
		end
		
		function [code, message] = checkGams()
			import gams.GAMSModel
			import util.CommonsUtil
			
			code = GAMSModel.STATUS_OK;
			message = 'GAMS is ready for simulation.';
			
			if exist('wgdx', 'file') ~= 3
				code = GAMSModel.ERR_WGDX;
				message = 'wgdx MEX-file not found. Add GAMS to MATLAB''s path.';
				return;
			end
			
			if exist('rgdx', 'file') ~= 3
				code = GAMSModel.ERR_RGDX;
				message = 'rgdx MEX-file not found. Add GAMS to MATLAB''s path.';
				return;
			end
			
			[status, cmdout] = system('gams');
			if status ~= 0
				code = GAMSModel.ERR_CMD;
				message = 'gams communication failed. Check Windows PATH';
				CommonsUtil.log('Failure to issue command "gams".\n');
				CommonsUtil.log('Message: [%s]\n', cmdout);
				return;
			end
		end
	end
end