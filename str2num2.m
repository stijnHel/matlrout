function n=str2num2(s)
% STR2NUM2 - vervang-routine voor str2num om ook hexadecimale gegevens in te lezen.
%   n=str2num2(s)
%     Hier worden enkel gewone getallen omgezet.
% Remark:
%    str2num('true') ---> logical(1)
%        but str2num2('true') ---> []  !!

if ~isstr(s)
	error('String-input vereist')
end
s=deblank(s);
if isempty(s)
	error('Geen empty strings toegelaten')
end
cijfers=zeros(255,1);
cijfers(abs('0'):abs('9'))=ones(10,1);
cijfers(abs('.'))=1;
cijfers(abs('e'))=1;
cijfers(abs('+'))=1;
cijfers(abs('-'))=1;
while s(1)==' ';s(1)=[];end
if all(cijfers(abs(s)))
	n=sscanf(s,'%g');
else
	if s(length(s))=='h'
		s(length(s))=[];
	elseif (s(1)=='$')
		s(1)=[];
	end
	n=sscanf(s,'%x');
end
