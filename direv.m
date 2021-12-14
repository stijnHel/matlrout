function dOut=direv(varargin)
% direv.m - Leest event directory.
%    direv[(<dir-arguments>)]
%  or
%    d=direv[(<dir-arguments>)]
%  dir-arguments : (all arguments are optional)
%     first argument is a string that is added to the event-directoryname
%        e.g. : direv *.xml - gives all xml-files
%     next arguments :
%         'sortd','sort-d' --- sorts for date (increasing or decreasing)
%         'sortn','sort-n' --- sorts for names (no case dependency)
%         'sort'           --- short for short-d (newest files on top)
%         'top[<n>]'  ('top','top5',...) : gives only the top
%         'last[<n>]' ('last','last5',...) : gives only the last files
%         'dir'            --- only gives directories
%         'file'           --- only gives files
%        only without output arguments:
%         'time' or 'date' --- give time
%         'size' --- gives size
%      arguments are evaluated one by one, so that if top comes first, and
%      than sort, the top of the list (unsorted) is taken, and than sorted.
if nargin&&~isempty(varargin{1})
	f=zetev([],varargin{1});
else
	f=zetev;
end
if ~ischar(f)
	warning('current directory is set for the event-directory!')
	zetev(pwd)
	f=zetev;
end
d=dir(f);
while ~isempty(d)&&d(1).name(1)=='.'
	d(1)=[];
end
bTime=false;
bSize=false;
nr_offset=0;
if nargin>1
	for iArg=2:nargin
		arg=lower(varargin{iArg});
		if strncmp(arg,'sort',4)
			sdir=1;
			if length(arg)==4
				a='d';	% default sort per date (reversed)
				sdir=-1;
			elseif length(arg)==5
				a=arg(5);
			else
				if arg(5)~='-'
					error('unexpected argument (%s)',arg)
				end
				sdir=-1;
				a=arg(6);
			end
			switch a
				case 'd'
					[~,i]=sort(cat(1,d.datenum));
				case 'n'
					N=lower({d.name});
					[~,i]=sort(N);
				otherwise
					error('unknown sorting type')
			end
			if sdir<0
				i=i(end:-1:1);
			end
			d=d(i);
		elseif strncmp(arg,'top',3)
			if length(arg)>3
				n=str2double(arg(4:end));
				if length(n)~=1
					error('unexpected argument (%s)',arg)
				end
			else
				n=10;
			end
			d=d(1:min(end,n));
		elseif strncmp(arg,'last',4)
			if length(arg)>4
				n=str2double(arg(5:end));
				if length(n)~=1
					error('unexpected argument (%s)',arg)
				end
			else
				n=10;
			end
			nr_offset=max(0,length(d)-n);
			d=d(1+nr_offset:end);
		elseif strcmp(arg,'time') || strcmp(arg,'date')
			bTime=true;
		elseif strcmpi(arg,'size') || strcmpi(arg,'bytes')
			bSize=true;
		elseif strcmp(arg,'dir')
			d=d(cat(1,d.isdir)==1);
		elseif strcmp(arg,'file')
			d=d(cat(1,d.isdir)==0);
		else
			error('unknown argument (%s)',arg)
		end
	end
end
if nargout
	dOut=d;
elseif isempty(d)
	fprintf('No files found\n')
else
	if bTime||bSize
		lName=cellfun('length',{d.name});
		sTyp2=['%-' num2str(max(lName)) 's'];
	else
		sTyp2='%s';
	end
	sTyp=['%' num2str(1+floor(log10(nr_offset+length(d)))) 'd : ' sTyp2];
	for i=1:length(d)
		fprintf(sTyp,i+nr_offset,d(i).name);
		if d(i).isdir
			fprintf(' <DIR>');
		else
			if bTime
				fprintf(' %s',d(i).date)
			end
			if bSize
				fprintf(' #%d',d(i).bytes)
			end
		end
		fprintf('\n')
	end
end
