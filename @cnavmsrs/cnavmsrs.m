classdef cnavmsrs < handle
	%cnavmsrs - Class handling "navigation through measurements"
	%
	% This class creates a figure.  All interactive handling (except ...)
	% is done within this class.
	% "Except" - keypress handling that's not processed by this class is
	% forwarded to navfig-functionality.
	
	properties
		fnaam
		funcnaam
		ne
		fig
		ax
		hL
		kols
		kanx
		opties
		nr
		nFiles
	end
	
	methods
		function c=cnavmsrs(fnaam,varargin)
			%CNAVMSRS/CNARMSRS - Measurement-navigator-constructor
			%  c=cnavmsrs(fnaam[,funcnaam,<options>])
			%    A window with plots of a read measurement is generated.
			%    'fnaam' gives the information about which files to be read:
			%       structure-array : structure with field 'fnaam'
			%       cell-array : names of files
			%       string : filename will be made by :
			%           sprintf(fnaam,<nr>)
			%           default start of <nr> is one, but can be given changed with
			%             options.
			%       array : to run through an array
			%    The following things can be done by keypresses while the
			%    created figure is the active window:
			%       ' ', 'n' : next measurement file
			%       'p' : previous measurement file
			%       'c' : copy figure to another figure (successive copies)
			%             will copy to the same figure
			%       'C' : stops copying to the figure (so that next copy will create a
			%             new figure)
			%       'L' : creates a legend for the copied figure (will not work
			%             correctly when different lines are plot on axes (of the same
			%             file)
			%       'D' : delete the last set of copied lines
			%     All measurement file should have the same structure (same number of
			%     channels, same order of channels, the length can vary)
			%
			%   The plot is made by using plotmat.  To this function inputs can be
			%   given by using options to this function:
			%       cnavmsrs(fname,funcname,'kols',<kols>,'kanx',<kanx>)
			%   Other options to this function are :
			%      'fnr' : starting number
			%      'minNrFiles' : standard 1
			%
			%  see also cnavmsrs/navmsrs
			
			if ~exist('fnaam','var')||isempty(fnaam)
				error('Minstens een input vereist!!')
			end
			
			opties=struct('kols',[],'kanx',1,'ne',[],'fnr',1,'minNrFiles',1	...
				,'evdir',[],'postNavFcn',[],'bWrap',true,'bVarSignames',false	...
				,'readOptions',{{}});
			if isnumeric(fnaam)||istable(fnaam)
				opties.kanx=-1;
			end
			
			if isempty(varargin)||isempty(varargin{1})
				if isnumeric(fnaam)||(iscell(fnaam)&&isnumeric(fnaam{1}))
					funcnaam=[];
				else
					funcnaam='leesalg';
				end
			else
				funcnaam=varargin{1};
			end
			additopt={'msrs','cfunc','hfunc','plotOptions','transpose'};
			for i=2:2:length(varargin)
				if isfield(opties,varargin{i})	...
						||any(strcmp(varargin{i},additopt))
					opties.(varargin{i})=varargin{i+1};
				else
					warning('CNAVMSRS:unknownOption','Option "%s" unknown!!!',varargin{i})
				end
			end
			
			fnr=opties.fnr;
			if isstruct(fnaam)
				if isfield(fnaam,'fname')	% was it a fault or is this used?
					f1=fnaam(fnr).fname;
					nFiles=length(fnaam);
				elseif isfield(fnaam,'name')
					f1=fnaam(fnr).name;
					nFiles=length(fnaam);
				elseif isfield(fnaam,'data')&&isfield(fnaam,'idx')
					f1='1';
					nFiles=length(fnaam.idx)-1;
					funcnaam=[];
					if min(size(fnaam.data))==1&&size(fnaam.data,1)==1
						fnaam.data=fnaam.data';
					end
				elseif isscalar(fnaam) % take numeric fields
					fn=fieldnames(fnaam);
					Bts = structfun(@(x) isa(x,'timeseries'), fnaam);
					if all(Bts)
						C=cell(1,sum(Bts));
						for i=1:length(fn)
							C{i}=fnaam.(fn{i});
						end
						cTS=cTSlist([C{:}]);
						nFiles=cTS.length();
						f1='1';
						opties.bVarSignames=true;
						fnaam=cTS.IDX();
						funcnaam=@(f) cTS.get(f);
					else
						B=structfun(@length,fnaam)>5&structfun(@isnumeric,fnaam);
						C=cell(1,sum(B));
						iC=0;
						for i=1:length(fn)
							if B(i)
								iC=iC+1;
								C{iC}=fnaam.(fn{i});
							end
						end
						if ~any(B)
							error('No numeric data found in structure')
						end
						fnaam=C;
						f1='1';
						nFiles=length(C);
						funcnaam=[];
						opties.ne=fn(B)';
					end
				else
					error('Unknown structure type')
				end
			elseif ischar(fnaam)
				if size(fnaam,1)==1&&any(fnaam=='%')
					f1=sprintf(fnaam,fnr);
					if isfield(opties,'msrs')
						nFiles=length(opties.msrs);
					else
						nFiles=100;	%???!!!!
					end
				else	% ???
					f1=deblank(fnaam(fnr,:));
					nFiles=size(fnaam,1);
				end
			elseif iscell(fnaam)
				if isfield(opties,'transpose')&&opties.transpose
					for i=1:length(fnaam)
						fnaam{i}=fnaam{i}';
					end
				end
				if ischar(fnaam{1})
					f1=fnaam{fnr};
				else
					f1='1';
				end
				nFiles=length(fnaam);
			elseif isnumeric(fnaam)
				f1='1';
				nFiles=size(fnaam,2);
				funcnaam=[];
			elseif istable(fnaam)
				f1 = '1';
				funcnaam=[];
				opties.ne = fnaam.Properties.VariableNames;
				Bok = false;
				for i=1:length(opties.ne)
					Bok(i) = isnumeric(fnaam.(opties.ne{i}));
				end
				opties.ne = opties.ne(Bok);
				nFiles=sum(Bok);
			elseif isa(fnaam,'timeseries')
				% 	nFiles=length(fnaam);
				% 	f1='1';
				% 	opties.ne={fnaam.Name};
				% 	opties.kanx=fnaam(1).Time;
				% 	funcnaam=[];
				cTS=cTSlist(fnaam);
				nFiles=cTS.length();
				f1='1';
				opties.bVarSignames=true;
				fnaam=cTS.IDX();
				funcnaam=@(f) cTS.get(f);
			elseif isa(fnaam,'cTSlist')
				cTS=fnaam;
				nFiles=cTS.length();
				f1='1';
				opties.bVarSignames=true;
				fnaam=cTS.IDX();
				funcnaam=@(f) cTS.get(f);
			else
				error('Something wrong???')
			end
			if nFiles==1
				warning('CNAVMSRS:oneFile','maar 1 file?')
			end
			ne=opties.ne;
			if isnumeric(fnaam)
				if size(fnaam,3)>1
					e=squeeze(fnaam(:,1,:));
				elseif size(fnaam,1)==1&&ismatrix(fnaam)
					e=fnaam(:);
				else		% data is given in one array
					e=fnaam(:,1);
					if isnumeric(opties.kanx)
						if isscalar(opties.kanx)&&opties.kanx>0&&rem(opties.kanx,1)==0
							opties.kanx=fnaam(:,opties.kanx);
						end
					elseif ischar(opties.kanx)&&~isempty(opties.kanx)
						ix=FindString(ne,opties.kanx);
						if isscalar(ix)
							opties.kanx=fnaam(:,ix);
						elseif length(ix)>1
							printstr(ne(ix))
							error('Can''t select one channel for X')
						else
							error('Can''t find any channel for X matching the requested criterion')
						end
					end		% kanx-options
				end		% data is given in one array
				if ~isempty(ne)
					if ischar(ne)
						ne=deblank(ne(1,:));
					else
						ne=ne{1};
					end
				end
			elseif istable(fnaam)
				e = fnaam.(ne{1});
			elseif isempty(funcnaam)
				if iscell(fnaam)
					e=fnaam{1};
				elseif min(size(fnaam.idx))==1
					e=fnaam.data(fnaam.idx(1):fnaam.idx(2),:);
				else
					e=fnaam.data(fnaam.idx(1,1):fnaam.idx(1,2),:);
				end
			elseif ischar(funcnaam)
				eval(['[e,ne]=' funcnaam '(''' f1 ''');']);
				opties.ne=ne;
			elseif isa(funcnaam,'function_handle')
				[e,ne]=feval(funcnaam,f1);
				opties.ne=ne;
			else
				error('Verkeerde input voor de functie-input')
			end
			if isfield(opties,'plotOptions')&&~isempty(opties.plotOptions)
				plotOptions=opties.plotOptions;
			else
				plotOptions={};
			end
			if length(ne)==size(e,2)
				nePlot=ne;
			else
				nePlot=[];
			end
			[hAx,hL,~,kols,kanx]=plotmat(e,opties.kols,opties.kanx,nePlot,[],plotOptions{:});
			fNr=get(hAx(1),'Parent');
			if isscalar(opties.kanx)&&(opties.kanx<0||opties.kanx>floor(opties.kanx))
				kanx=-abs(opties.kanx);
			elseif length(opties.kanx)==size(e,1)	% (kanx is converted to 1 by plotmat)
				kanx=[];	% don't redraw
			end
			c.fnaam = fnaam;
			c.funcnaam = funcnaam;
			c.ne = opties.ne;
			c.fig = fNr;
			c.ax = hAx;
			c.hL = hL;
			c.kols = kols;
			c.kanx = kanx;
			c.opties = opties;
			c.nr = 0;
			c.nFiles = nFiles;
			set(gcf,'UserData',c,'KeyPressFcn',@(~,~) c.navmsrs(),'Name',f1)
			c.navmsrs(fnr)	% to set everything the same as normal
			if nargout==0
				clear c		% is this possible?
			end
		end
		
		function f = GetFig(c)
			%cnavmsrs/GetFig - Gives figure handle
			%    f=c.GetFig()
			f = c.fig;
		end		% GetFig
		
		function nr=GetNr(c)
			%cnavmsrs/GetNr - Gives the number of current measurement
			%    nr = c.GetNr()
			
			nr = c.nr;
		end		% GetNr
		
		function SetPostNavFcn(c,fcn)
			%cnavmsrs/SetPostNavFcn - Set post-navigate-function
			%    c.SetPostNavFcn(fcn)
			
			c.opties.postNavFcn=fcn;
		end		% SetPostNavFcn
		
		% destructor?
	end		% methods
	
	methods		% methods defined externally
		out=navmsrs(c,varargin)
		del(c,nr)
	end		% externally defined methods
	
end		% classdef
