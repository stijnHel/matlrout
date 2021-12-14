function [P,P2]=getshape(c,i,j,nr)
% CSWF/GETSHAPE - Geeft een shape (van een font of van een DefineShape)
%    [P,P2]=getshape(c) : geeft alle shapes
%    [P,P2]=getshape(c,{shapes})
%    [P,P2]=getshape(c,i,j,nr)

if nargin==2&iscell(i)
	shapes=i;
else
	if nargin==1
		k=[zoektags(c,2);zoektags(c,22);zoektags(c,32)];	% shapes
		k2=[zoektags(c,10);zoektags(c,48)];
		if nargout==0
			fprintf('Om een shape te geven moet deze functie minstens twee inputs krijgen (c,index)\n');
			if ~isempty(k)
				fprintf('Ik geef alvast de mogelijke shapes :\n');
				fprintf('frame %3d  ,  tagNr %3d\n',k');
			end
			if ~isempty(k2)
				if isempty(k)
					fprintf('Er zijn geen shapes, maar er zijn wel de volgende fonts :\n');
				else
					fprintf('en de volgende fonts :\n');
				end
				fprintf('frame %3d  ,  tagNr %3d\n',k2');
			end
		else
			P=[k ones(size(k,1),1);k2 zeros(size(k2,1),1)];
		end
		return
	elseif nargin==2|isempty(j)
		if length(i)==1
			k=[zoektags(c,2);zoektags(c,22);zoektags(c,32)];
			if i>size(k,1)
				error('Hoger nummer van shape dan beschikbaar');
			end
			j=k(i,2);
			i=k(i,1);
		else
			j=i(2);
			i=i(1);
		end
	end
	t=c.frames{i}(j).tagData;
	if isfield(t,'shape')	% shape
		shapes=t.shape;
	elseif isfield(t,'edges1')	% morphShape
		if nargout>1
			P2=getshape(c,t.edges2);
		end
		shapes=t.edges1;
	elseif exist('nr')&~isempty(nr)	% font (1 karakter)
		shapes=t.shapes{nr};
	else	% font (alle karakters)
		P=cell(1,length(t.shapes));
		for k=1:length(t.shapes)
			P{k}=getshape(c,i,j,k);
		end
		return
	end
end

dP=[0 0];
if isstruct(shapes)
	for k=1:length(shapes);
		s=shapes(k).shapes;
		if isfield(s,'delta')
			dP=[dP;reshape(s.delta,2,length(s.delta)/2)'];
		elseif isfield(s,'moveDelta');
			dP=[dP;nan nan;s.moveDelta];
		elseif isfield(s,'deltaX');
			dP(end+1,:)=[s.deltaX 0];
		elseif isfield(s,'deltaY');
			dP(end+1,:)=[0 s.deltaY];
		else
%			disp(s)
%			warning('xxx');
		end;
	end
else
	for k=1:length(shapes);
		s=shapes{k};
		if isfield(s,'delta')
			dP=[dP;reshape(s.delta,2,length(s.delta)/2)'];
		elseif isfield(s,'moveDelta');
			dP=[dP;nan nan;s.moveDelta];
		elseif isfield(s,'deltaX');
			dP(end+1,:)=[s.deltaX 0];
		elseif isfield(s,'deltaY');
			dP(end+1,:)=[0 s.deltaY];
		else;
%			disp(s)
%			warning('xxx');
		end;
	end
end
P=[];
while ~isempty(dP)
	while isnan(dP(1,1))
		dP(1,:)=[];
	end
	i=find(isnan(dP(:,1)));
	if isempty(i)
		i=size(dP,1)+1;
	else
		i=i(1);
	end
	P=[P;cumsum(dP(1:i-1,:));nan nan];
	dP(1:min(i,size(dP,1)),:)=[];
end

