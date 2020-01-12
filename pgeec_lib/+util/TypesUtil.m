classdef TypesUtil
	% Collection of commonly needed type handling methods.
	
	properties(Constant, Access = public)
		% Generic empty type to be used to initialize variables
		empty = [];
		
		% Generic empty cell array to be used to initialize variables
		emptyCellArray = [{}];
	end
	
	methods(Access = public, Static)
		
		function numArray = charCell2Num(cellArray)
		% Converts a cell-array of chars to a numeric array

			numOfElements = numel(cellArray);
			if isrow(cellArray)
				numArray = zeros(1, numOfElements);
			else
				numArray = zeros(numOfElements, 1);
			end

			for i =  1:numOfElements
				numArray(i) = str2double(cellArray{i});
			end

		end
		
		function strCell = num2CharCell(numericArray)
		% Converts a numeric array to a cell-array of chars
			numOfElements = numel(numericArray);
			strCell = util.TypesUtil.emptyCellArray;

			if ~iscell(numericArray)
				for i = 1:numOfElements
					try
						if isrow(numericArray)
							strCell = [strCell, {num2str(numericArray(i))}];
						else
							strCell = [strCell; {num2str(numericArray(i))}];
						end
					catch
						if isrow(numericArray)
							strCell = [strCell, {''}];
						else
							strCell = [strCell; {''}];
						end
					end
				end
			else
				for i = 1:numOfElements
					try
						if isrow(numericArray)
							strCell = [strCell, {num2str(numericArray{i})}];
						else
							strCell = [strCell; {num2str(numericArray{i})}];
						end
					catch
						if isrow(numericArray)
							strCell = [strCell, {''}];
						else
							strCell = [strCell; {''}];
						end
					end
				end
			end
		end
		
		function mustBeLogical(a)
		% Checks if a variable type is Logical, throws an error if not.
			if ~islogical(a)
				error('Variable "%s" must be a logical value.', inputname(1));
			end
		end
		
		function mustBeTxt(a)
		% Checks if a variable type is textual, throws an error if not.
			if ~util.TypesUtil.isTxt(a)
				error('Variable "%s" must be a character array or string.', inputname(1));
			end
		end		
		
		function mustBeScalar(a)
		% Checks if a variable type is numeric and scalar, throws an error if not.
			if ~util.TypesUtil.isScalar(a)
				error('Variable "%s" must be a scalar.', inputname(1));
			end
		end
		
		function mustBeBetween(a, min, max)
		% Checks if a variable is whithin two values, throws an error if not.
			util.TypesUtil.mustBeScalar(a);
			util.TypesUtil.mustBeScalar(max);
			util.TypesUtil.mustBeScalar(min);
			
			if min > max
				error('Minimum (%g) should be smaller than maximum (%g).', min, max);
			end
			
			if a < min || max < a
				error('Variable "%s" must be between %g and %g.', inputname(1), min, max);
			end
		end
		
		function mustBeNotEmpty(a)
		% Checks if a variable is not empty, throws error if it is
			if isempty(a)
				error('Variable "%s" must not be empty.', inputname(1));
			end
		end
		
		function mustBeMultipleOf(a, b)
		% Checks if variable a is multiple of b, hrows error if not.
			if ~util.TypesUtil.isMultipleOf(a, b)
				error('Variable "%s" must be a multiple of %0.4g.', inputname(1), b);
			end
		end
		
		function result = isMultipleOf(a, b)
		% Checks if variable a is multiple of b
			result = rem(a, b) == 0;
		end
		
		function result = isScalar(a)
		% Checks if a variable type is numeric and scalar
			result = isscalar(a) && isnumeric(a);
		end
		
		function result = isTxt(a)
		% Checks if a variable type is textual.
			result = ischar(a) || isstring(a);
		end
		
		function mustBeCellArray(a)
		% Checks if a variable type is cell array, throws an error if not.	
			if ~iscell(a)
				error('Variable "%s" must be a cell array.', inputname(1));
			end
		end
		
		function isInstanceof = instanceof(object, clazz)
		% Determines if an object is instance of a class, inspired by Java's instanceof.
			import util.StringsUtil
		
			isInstanceof = false;
			
			classes = [{class(object)}; superclasses(object)];
			for i = 1:length(classes)
				if StringsUtil.endsWith(classes{i}, clazz)
					isInstanceof = true;
					return;
				end
			end
		end
	end
	
end