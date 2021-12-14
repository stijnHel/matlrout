function [varargout]=plotmat(S,kols,x,varargin)
%STRUCT/PLOTMAT - plot gegevens uit matrix
%    plotmat(S,kols,x...)
%      see plotmat
%        S : struct met minstens
%                   meting of e : zoals "e-matrix"
%                   naam of ne : zoals "ne"-matrix
%                evt dim of de : zoals "de"-matrix

if ~exist('kols','var');kols=[];end
if ~exist('x','var');x=[];end
varargout=cell(1,nargout);

if ~isstruct(S)
	if isstruct(x)
		x=timevec(x,S,isfield(x,'t0')&&~isempty(x.t0));
		[varargout{:}]=plotmat(S,kols,x,varargin{:});
	else
		error('Wrong use of this function')
	end
	return
elseif isfield(S,'e')
	meetveld='e';
elseif isfield(S,'meting')
	meetveld='meting';
elseif isfield(S,'X')&&isfield(S,'Y')
	[varargout{:}]=plotmat(S.Y,kols,S.X,varargin{:});
	return
elseif isfield(S,'signals')	% Simulink output
	if (nargin<3||isempty(x))&&isfield(S,'time')
		x=S.time;
	end
	X=[S.signals.values];
	nX=CombineSimSignals(S,'-bOnlyStateNames');
	dX=[];
	if isfield(S.signals,'unit')	% (normally not supplied)
		dX={S.signals.unit};
		if ~all(cellfun(@ischar,dX))
			dX=[];
		end
	end
	[varargout{:}]=plotmat(X,kols,x,nX,dX,varargin{:});
	return
elseif isfield(S,'channel')&&isfield(S,'properties')	% TDMS-channel group
	X=[S.channel.data];
	nX={S.channel.name};
	[varargout{:}]=plotmat(X,kols,x,nX,varargin{:});
	return
elseif length(intersect(fieldnames(S),{'group','properties','version'}))==3
	% leesTDMS-struct-output
	if length(S.group)>1
		warning('Only the first group is plotted!')
	end
	X=[S.group(1).channel.data];
	nX={S.group(1).channel.name};
	[varargout{:}]=plotmat(X,kols,x,nX,varargin{:});
	return
elseif isfield(S,'Data')&&isfield(S,'Time')	% (?)converted TimeSeries to struct
	[varargout{:}]=plotmat(S.Data,kols,S.Time,varargin{:});
	return
else
	error('no measurement matrix found!')
end
if isfield(S,'naam')
	naamveld='naam';
elseif isfield(S,'ne')
	naamveld='ne';
else
	error('no signal names found!')
end

%error 'not working!!!!'

[meetveld,naamveld,dimveld]=metingvelden(S);
e_nKan=zeros(length(e),1);
it=isfield(e,'t');
idt=isfield(e,'dt');
ne=cell(length(e),1);
[ne{:}]=subsref(e,substruct('.',naamveld));
se=zeros(length(e),2);
for i=1:length(e)
	se(i,:)=size(subsref(e,substruct('()',{i},'.',meetveld)));
end
[varargout{:}]=plotmat(e,kols,x,ne,de,varargin{:});
