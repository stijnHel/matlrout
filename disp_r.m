function out = disp_r(varargin)
% disp_r recursively print data structures or cell arrays
% formatted to the screen or to a file.
%
% disp_r(X), where X must be a structure or cell array, will print
% a formatted representation of X to the screen.
% disp_r(X, <switches>, <filename>)
% 
% possible switches are 
% 'c' - compact
% 'f' - file. 
% If the 'f' switch is specified so must a filename.
%
% eg:	disp_r(data, 'cf', 'C:\temp\file.txt')
% will output a compact form of the structure data to C:\temp\file.txt
% C:\temp\file.txt must not exist

global	struct_name print_to compact
print_to=1;	
	% Check that some data has been provided	
	if length(varargin) < 1
		error('disp_r requires some input - type help disp_r for more info')
	end

	% the structure to print should always be the first argument
	% in the variable length argument list
	structure = varargin{1};

	% It always has a name - assigned at beginning.
	struct_name = get_name(varargin{1});

	compact = 0;

	if length(varargin) ==1 
	% This is what happens in the most basic case
	% Only one argument, no switches or filename

		print_to = 1;				% Print to the screen

		disp_struct(structure, -1);				% Do print Run

		fprintf(print_to, '\nEND\n');					% Finished 


	% If there is more than one argument then either a filename
	% or some switches have been specified
	elseif length(varargin) > 1

		% The second argument must be options
		switches = char(varargin{2});		
		
		for t=1:length(switches)
			if switches(t) == 'c'
				compact = 1;
			elseif switches(t) == 'f'
				if length(varargin) < 3
					error('Must supply filename');
				else
					file_exist = exist(char(varargin{3}));
					if file_exist ~= 0
						error('File already exists')
					end
					print_to = fopen(char(varargin{3}), 'a+');
					% Open a file for the output
				end
			else 
				error('unrecognised switch');
			end
		end

		disp_struct(structure, -1);
		% Do run

		fprintf(print_to, '\nEND\n');
		% Finished Run

		if print_to ~= 1
			fclose(print_to);
		end

	end
	
	
function out = get_name(struct)
% Simple Function to return workspace variable names
% of multiple argument functions.
out = inputname(1);



% This is the main recursing loop.
function out = disp_struct(structure, num_indents)

global	struct_name print_to compact

% Three possiblilities on entering this function
% the input arguments could be a structure, a cell array or
% something else - an actual value (class char or double.)
% Deal with struct first
if isstruct(structure) 
   
   % Initialiser - first time round
	if num_indents == -1
		fprintf(print_to, '\nPrinting STRUCTURE %s\n', struct_name);
		num_indents = num_indents+1;
	end

	% Special case - multi element structure.
	% Print each element seperately

	if length(structure)>1
      for o=1:length(structure);
			fprintf(print_to, '\n');
			indent(num_indents);
			fprintf(print_to, 'element %d', o);
			% First recursive call here - num_indents updated reflects
			% Number of recursive calls
			disp_struct(structure(o), num_indents);
		end
	else

		% This is what happens when not the first call
		% and not a multi-element structure. 
		names = fieldnames(structure);

		% For each field of the structure
		% print its name and then its value
		for n=1:length(names);

			if compact == 0 | isstruct(structure)
				fprintf(print_to, '\n');
			end

			indent(num_indents);
			fprintf(print_to, '|---');
			fprintf(print_to, '>%s', char(names(n)));

			% Now the Value - Main recursive call - num_indents updated.
			disp_struct(getfield(structure, char(names(n))), num_indents+1);
		end
	end

% If the input structure is a cell, work through it like
% a multielement array - each call the type of input structure
% is checked in disp_struct anyway, so really no difference
elseif iscell(structure)

	for i = 1:length(structure)
		
		% Some extra informative text.
		fprintf(print_to, '\n\nPrinting CELL ARRAY Cell %d\n\n', i);
		disp_struct(structure{i}, num_indents);
	end 
else

	% Not cell or structure - a matlab 'array'
	% Function declared to handle and keep extra control
	% over output format.
	disp_arr(structure, num_indents);

end

% This is a function to correctly output formatted arrays.
% Its main function is to put arrays with lenght > 1 in 
% more than 1 dimension, onto a new line and then indent it
% to align with the current ouput.
function out = disp_arr(s, num_indents)

global	struct_name print_to compact

% Graphical suger only printed if no 'c' switch specified.
if compact == 0
	fprintf(print_to, '\n');
	indent(num_indents-1);
	fprintf(print_to, '|---');
	fprintf(print_to, 'Val');
else
	fprintf(print_to, ':	');
end

class_of_struct = class(s);

% Handle doubles and chars seperately
if class_of_struct(1:4) == 'doub'
	
	% Need to know size of struct to determine if its *really* 2d
	size_of_struct = size(s);

	for t = 1:size_of_struct(1);
		
		% This will happen if the data has more than length 1
		% in more than one dimension
		if size_of_struct(1) > 1
			fprintf(print_to, '\n');
			indent(num_indents);
		end

		for tt = 1:size_of_struct(2);
			fprintf(print_to, '	%d  ', s(t, tt));
		end
	end

% If its class char - just print
elseif class_of_struct(1:4) == 'char'
		fprintf(print_to, '	%s', s);
end

% Some more output formatting
if compact == 0
	fprintf(print_to, '\n');
end
indent(num_indents-1);
if compact == 0
	fprintf(print_to, '|');
end


% This is utility program to localise the
% indent size - only needs to be changed here.
function out = indent(n)

global	struct_name print_to

for i = 1:n
	fprintf(print_to, '    ');
end

% author: Colin Howarth <colinhowarth@bigfoot.com>


