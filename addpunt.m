function [varargout] = addpunt(f, p, bDifMarkCols, bSameMarkerColor)
% ADDPUNT - Voegt punten toe aan lijnen
%     addpunt(f, p, bDifMarkCols)
%         f           : figure
%         p           : marker list
%         bDifMarkCols: if true (default false) use other marker if same
%             colour and axes ----- this is in development
%         bSameMarkerColor: Same marker for the different colours
%
%  other functionality:
%    default settings (only for current figure!)
%        addpunt('setDifCol'[,<true/false>]) (if no true/false ==> toggle)
%                to set default behaviour for bDifMarkCols
%        addpunt('setSameCol'[,<true/false>])
%                to set default behaviour for bSameMarkerColor
%    b = addpunt('getState'[,f])
%        returns "addpunt-state": true ==> points are drawn

if ~exist('f','var');f=[];end
if ~exist('p','var');p=[];end
if ~exist('bDifMarkCols','var');bDifMarkCols=[];end
if ~exist('bSameMarkerColor','var');bSameMarkerColor=[];end

if ischar(f)
	if nargin<2||isempty(p)
		p = -1;
	end
	if startsWith(f,'setdifcol','IgnoreCase',true)
		if p<0
			p = getappdata(gcf,'ADDP_difMarkCols');
			if isempty(p)
				p = true;
				fprintf('default bDifMarkCols set to true.\n')
			else
				p = ~p;
				fprintf('default bDifMarkCols toggled to ')
				if p
					fprintf('true\n')
				else
					fprintf('false\n')
				end
			end
		end
		setappdata(gcf,'ADDP_difMarkCols',p);
	elseif startsWith(f,'setSameCol','IgnoreCase',true)
		if p<0
			p = getappdata(gcf,'ADDP_sameMarkerCol');
			if isempty(p)
				p = true;
				fprintf('default bSameMarkerColor set to true.\n')
			else
				p = ~p;
				fprintf('default bSameMarkerColor toggled to ')
				if p
					fprintf('true\n')
				else
					fprintf('false\n')
				end
			end
		end
		setappdata(gcf,'ADDP_sameMarkerCol',p);
	elseif startsWith(f,'getState','IgnoreCase',true)
		if nargin<2 || isempty(p)
			f = p;
		else
			f = gcf;
		end
		[l,Bmarker] = GetLines(f);
		varargout = {all(Bmarker),Bmarker,l};
	else
		error('What did you mean?')
	end
	return
end

if isempty(f)
	f=gcf;
end
if length(f)==1
	if strcmp(get(f,'type'),'figure')
		%figure(f)
	end
end

if isempty(p)
	ls=get(gca,'LineStyleOrder');
	p=ls;
	if size(ls,1)==1
		p='x|+|o|*|square|diamond|v|^|>|<|pentagram|hexagram|.';
	end
end
if size(p,1)==1
	i=find(['|' p '|']=='|');
	if isempty(i)
		error('Geen "|" in p gevonden.')
	end
	q=zeros(length(i)-1,max(diff(i)));
	di=diff(i)-1;
	for j=1:length(i)-1
		q(j,1:di(j))=p(i(j):i(j+1)-2);
	end
	p=char(q);
end

if isempty(bDifMarkCols) && isappdata(f(1),'ADDP_difMarkCols')
	bDifMarkCols = getappdata(f(1),'ADDP_difMarkCols');
end
if isempty(bSameMarkerColor) && isappdata(f(1),'ADDP_sameMarkerCol')
	bSameMarkerColor = getappdata(f(1),'ADDP_sameMarkerCol');
end

if isempty(bDifMarkCols)
	bDifMarkCols = false;
end
if isempty(bSameMarkerColor)
	bSameMarkerColor = false;
end

if bDifMarkCols
	% this makes it more complex than original (consistent over axes, but
	% not consistent colour/marker match within axes)
	ax = GetNormalAxes(f);
	LINK = SetMarkers(ax(1),p, [], bSameMarkerColor);
	for i=2:length(ax)
		LINK = SetMarkers(ax(i),p, LINK, bSameMarkerColor);
	end
	return
end

collijst=get(ancestor(f(1),'figure'),'DefaultAxesColorOrder');
[l,Bmarker] = GetLines(f);
for i=1:length(l)
	if ~Bmarker(i)
		pt=[];
		c=get(l(i),'Color');
		if ~isempty(collijst)
			pt=find((c(1)==collijst(:,1))&(c(2)==collijst(:,2))&(c(3)==collijst(:,3)));
		end
		if isempty(pt)
			pt=size(collijst,1)+1;
			collijst=[collijst;c]; %#ok<AGROW>
		end
		pt=rem(pt-1,size(p,1))+1;
		set(l(i),'Marker',deblank(p(pt,:)));
	end
end

function [l,BhasMarker] = GetLines(f)
l = [findobj(f,'Type','line');findobj(f,'Type','Stair')]';
BhasMarker = false(size(l));
for i=1:length(l)
	BhasMarker(i) = ~strcmp(get(l(i),'Marker'),'none');
end

function [L,M] = SetMarkers(ax,p,L,bSameMarkerColor)
% currently for 1 axes!

if ischar(p)
	nMarker = size(p,1);
else
	nMarker = length(p);
end

l = get(ax,'children');
l = l(end:-1:1);
if nargin<3||isempty(L)
	L = zeros(length(l),4);
	n = 0;
	bReuse = false;
else
	n = size(L,1);
	bReuse = true;
end
BL = false(size(L,1),size(L,2)-3);	% for "reuse L" - not yet OK!!!!
B = false(1,length(l));
M = [double(l),zeros(length(l),1)];
for i=1:length(l)
	if any(strcmp(get(l(i),'Type'),{'line','stair'}))
		B(i) = true;
		c = get(l(i),'Color');
		if n==0
			n = n+1;
			L(n,1:3) = c;
			L(n,4) = 1;
			M(i,2) = 1;
			BL(n,1) = true;
		else
			B1= all(L(1:n,1:3)==c,2);
			if any(B1)
				if bReuse
					j = 1;
					while j<=size(BL,2)&&BL(B1,j)
						j=j+1;
					end
					if j>size(BL,2) || L(B1,3+j)==0
						L(B1,3+j) = rem(L(B1,2+j),nMarker)+1;
					end
					BL(B1,j) = true;
					j = 3+j;
				else
					j = 4;
					while j<=size(L,2)&&L(B1,j)
						j=j+1;
					end
					L(B1,j) = L(B1,j-1)+1;
				end
				M(i,2) = L(B1,j);
			else
				n = n+1;
				L(n,1:3) = c;
				if bSameMarkerColor
					L(n,4) = 1;
				else
					L(n,4) = rem(n-1, nMarker)+1;	%!!!!!!!!not OK if nMarkers == nColours!!!!
				end
				M(i,2) = L(n,4);
				BL(n,1) = true;
			end
		end
		if ischar(p)
			set(l(i),'Marker',deblank(p(M(i,2),:)))
		else
			set(l(i),'Marker',p{M(i,2)})
		end
	end		% right type
end		% for i
L = L(1:n,:);
M = M(B,:);
