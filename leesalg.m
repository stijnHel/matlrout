function [varargout]=leesalg(varargin)
% LEESALG  - Leest een meting in met automatische selectie van routine.
%  [...]=leesalg(...);
%       inputs en outputs worden doorgegeven aan de "leesroutine".

global LEESALGsort

if isempty(LEESALGsort)
	LEESALGsort=false;
end
if strncmpi(varargin{1},'sort',4)
	LEESALGsort=~LEESALGsort;
	if LEESALGsort
		fprintf('Sortering van kanalen is aangezet.\n');
	else
		fprintf('Sortering van kanalen is uitgezet.\n');
	end
	return
end

[rout,ext,gevonden,fnaam]=beprout(varargin{1});
switch gevonden
	case 0
		error('File is "niet te vinden".')
	case 1
		% gevonden
	case 2
		error('File niet in zetev-directory (wel in working directory)')
	otherwise
		
end
varargout=cell(1,nargout);
if isempty(rout)
	if ~isempty(ext)
		if strcmp(deblank(ext(1,:)),'dos')
			if strcmp(deblank(ext(2,:)),'notepad')
				fprintf('Gebruik een tekst editor voor deze file.\n');
			else
				fprintf('Ongekende dos-applicatie\n');
			end
		elseif strcmp(deblank(ext(1,:)),'matlab')
			if size(ext,1)>1
				fprintf('Gebruik binnen matlab "%s" om deze file in te lezen.\n',ext(2,:));
			else
				fprintf('Deze file is rechtstreeks te gebruiken binnen matlab\n');
			end
		else
			error('beprout geeft een andere output dan verwacht.')
		end
	else
		fprintf('Ik vind geen goede routine om deze file in te lezen.\n');
	end
	return
end
if ischar(rout)
	if nargout
		eval(sprintf('[varargout{:}]=%s(fnaam,varargin{2:end});',rout));
	else
		eval(sprintf('%s(fnaam,varargin{2:end});',rout));
	end
else
	varargout=cell(1,max(1,nargout));
	[varargout{:}]=rout(fnaam,varargin{2:end});
end

if LEESALGsort&&nargout>1
	[~,i]=sortrows(varargout{2}(2:end,:));
	varargout{1}=varargout{1}(:,[1;i+1]);
	for j=2:min(3,nargout)
		varargout{j}=varargout{j}([1;i+1],:);
	end
end
