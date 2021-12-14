function [D,Dinfo,Hinfo]=ReadHDFdata(file,spec)
%ReadHDFdata - Read data from hdf-file based on a find spec
%      Uses FindHierField to find data in the h5info
%
%  [D,Dinfo,Hinfo]=ReadHDFdata(file,spec)
%        file can be a filename or a H5-info struct
%            this struct is the third output argument.
%        spec can be a string (an '*' is allowed at the end)
%            or field-search input for FindHierField
%        D: cell-vector of data (currently)
%        Dinfo: meta-data of the data
%        Hinfo: H5-info, to be used for later calls (is a bit faster)
%
%   See also FindHierField

if ischar(spec)
	if any(spec=='*')
		i=find(spec=='*');
		if ~isscalar(i)||i<length(spec)
			error('Sorry, only simple wildcard can be used ("abc*")')
		end
		spec={@(s1,s2) strncmpi(s1,s2,length(spec)-1),'Name',spec};
	end
end
if ischar(file)	...
		|| (isstruct(file)&&isfield(file,'datenum'))	...
		|| (isnumeric(file)&&isscalar(file))
	Hinfo=h5info(fFullPath(file));
else
	Hinfo=file;
end
file=Hinfo.Filename;

Dinfo=FindHierField(Hinfo,[],spec);
if iscell(Dinfo)
	for i=1:length(Dinfo)
		Dinfo{i}=num2cell(Dinfo{i});
	end
	Dinfo=[Dinfo{:}];
else
	Dinfo=num2cell(Dinfo);
end
D=cell(1,length(Dinfo));	% for now, a cell-array....
for i=1:length(Dinfo)
	ref=Dinfo{i}.refToOrig;
% 	if length(ref)~=5
% 		error('Sorry - currently no deep search in a hierarchy is implemented!')
% 	end
	Hr=subsref(Hinfo,ref(1:end-2));
	%p=['/' Hinfo.Groups(ref(3).subs{:}).Name '/' Dinfo{i}.Name];
	%p=[Hinfo.Groups(ref(3).subs{:}).Name '/' Dinfo{i}.Name];
	p=[Hr.Name '/' Dinfo{i}.Name];
	D{i}=h5read(file,p);
end
