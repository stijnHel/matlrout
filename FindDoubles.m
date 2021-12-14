function D=FindDoubles(varargin)
%FindDoubles - Find doubles in a list
%   This function is made for finding files with the same names, with
%   possibly the same or different contents.
%   The original goal was to use the result of dirrecurs function, using
%   the bReadContents and bHashContents options, but the type of the data
%   to compare is free (uses isequal).
%
%   D=FindDoubles(d);	% using dirrecurs data
%   D=FindDoubles('dir-path');
%   D=FindDoubles({<stringList>},{contents});

if ischar(varargin{1})
	dr=dirrecurs(varargin{1},'-bread','-bhash');
	Strings={dr.name};
	Data={dr.contents};
elseif iscell(varargin{1})
	Strings=varargin{1};
	if nargin>1
		Data=varargin{2};
	else
		Data=cell(size(Strings));	% only strings (not the most optimal way...)
	end
	if ~iscell(Data)
		error('Using list expects a data-list (as cell-vector)!')
	end
elseif isstruct(varargin{1})
	dr=varargin{1};
	Strings={dr.name};
	Data={dr.contents};
else
	error('Wrong input!')
end

if length(Strings)~=length(Data)
	error('Not matching string-list and data-list!')
end

B=false(1,length(Strings));	% processed
BeqName=B;
BeqData=B;
IlinkName=zeros(1,length(Strings));
IlinkData=IlinkName;
NequalName=IlinkName;
NequalData=IlinkName;
for i=1:length(Strings)-1
	if ~B(i)	% not yet processed
		BB=strcmp(Strings{i},Strings(i+1:end));
		if any(BB)
			ii=i+find(BB);
			%IlinkName(i)=i;
			IlinkName(ii)=i;
			NequalName(i)=length(ii);
			B(ii)=true;
			BeqName(i)=true;
			BeqName(ii)=true;
			% look for groups of equal data
			k=i;
			while ~isempty(ii)
				BB=false(1,length(ii));
				for j=1:length(ii)
					BB(j)=isequal(Data{k},Data{ii(j)});
				end
				if any(BB)
					jj=ii(BB);
					%IlinkData(k)=k;
					IlinkData(jj)=k;
					NequalData(k)=length(jj);
					ii(BB)=[];
					BeqData(k)=k;
					BeqData(jj)=k;
				end
				if ~isempty(ii)
					k=ii(1);
					ii(1)=[];
				end
			end		% while ~isempty(ii)
		end		% if any(BB)
	end		% if ~B(i)
end		% for i

D=var2struct(BeqName,BeqData,IlinkName,IlinkData,NequalName,NequalData);
