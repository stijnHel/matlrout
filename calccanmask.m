function [Mout,C]=calccanmask(ids,varargin)
% CALCCANMASK - Bepaalt mask en code voor filteren van CAN
%   [M,C]=calccanmask(ids)
%        ids numerieke waarden van te selecteren ids
%            of string met hexadecimale waarden
% uitbreiding :
%   [idsselect=]calccanmask(ids,M,C)
%                       of (ids,[M,C])
%        met ids struct-array (bijv. vanuit canmsgs)
%            of cell-array (ook bijv. vanuit canmsgs)
%         M en C mask en code (numerieke waarden)
%      dit geeft de boodschappen die "doorgelaten worden"

if isempty(ids)
	help calccanmask
	error('dit werkt niet zonder input')
end

if isstruct(ids)|iscell(ids)
	if nargin<2
		error('Bij dit gebruik van calccanmask zijn er minstens 2 inputs nodig')
	end
	if isstruct(ids)
		IDs=cat(1,ids.ID);
		sIDs=strvcat(ids.naam);
	else
		IDs=cat(1,ids{:,1});
		sIDs=strvcat(ids{:,2});
	end
	if nargin>2
		mask=varargin{1};
		code=varargin{2};
	else
		mask=varargin{1}(1);
		code=varargin{1}(2);
	end
	if ischar(mask)
		mask=sscanf(mask,'%x');
	end
	if ischar(code)
		code=sscanf(code,'%x');
	end
	i=find(bitand(IDs,mask)==code);
	if nargout
		Mout=IDs(i);
	elseif isempty(i)
		fprintf('Geen CAN-boodschappen geselecteerd.\n');
	else
		for j=i(:)'
			fprintf('0x%03x (%4d) - %s\n',IDs(j),IDs(j),deblank(sIDs(j,:)))
		end
	end
else
	if ischar(ids)
		ids=sscanf(ids,'%x');
		if nargin>1
			for i=1:nargin-1
				ids=[ids;sscanf(varargin{i},'%x')];
			end
		end
	end
	if max(ids)>2047
		extended=1;
		nbit=29;
	else
		nbit=11;
	end
	
	M=bitcmp(0,nbit);
	id1=ids(1);
	for i=2:length(ids)
		M=bitand(M,bitcmp(bitxor(ids(i),id1),nbit));
	end
	C=bitand(M,id1);
	if nargout
		Mout=M;
	else
		fprintf('mask : 0x%03x (%4d) - code : 0x%03x (%4d)\n',M,M,C,C);
	end
end
