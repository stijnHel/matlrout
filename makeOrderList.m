function [Onr,L,d,O]=makeOrderList(bUsePDF)
%makeOrderList - Make list of orders
%       [Onr,L,d,O]=makeOrderList
%            Onr - order numbers
%            L - cell array with order name and "orderer"
%            d - directory structure array (full file information)
%            O - list of orders grouped by "orderer"
%                user and list of orders (index to previous data)

if nargin<1||isempty(bUsePDF)
	bUsePDF=true;
end

D='/mnt/samba/fmtc-share/financieel/Bestelbonnen/';
if bUsePDF
	d=sort([dir([D '*intern.ps']);dir([D '*intern.pdf'])],'datenum');
else
	d=dir([D '*intern.ps']);
end
L=cell(2,length(d));
Onr=zeros(1,length(d));
PJLsign=char([27 37 45 49 50 51 52 53 88 64 80 74 76 32 74 79 66]);
status('reading files',0)
for i=1:length(d)
	s='';
	sName='';
	[~,~,fext]=fileparts(d(i).name);
	fid=fopen([D d(i).name]);
	x=fread(fid,[1 Inf],'*char');
	fclose(fid);
	nr=sscanf(d(i).name,'%d',1);
	if ~isempty(nr)
		Onr(i)=nr;
	end
	if isempty(nr)
		s=d(i).name;
	elseif strcmpi(fext,'.pdf')&&strncmp(x,'%PDF',4)
		try
			X=readPDF([D d(i).name]);
			b=strncmpi(X.Pages{3}(1,:),d(i).name(1:4),4);
			if any(b)
				s=[X.Pages{3}{1,b}];
				sName=strtrim(s(5:end));
				Onr(i)=nr;
			end
		end
	elseif length(x)>17&&all(x(1:17)==PJLsign)
		s=x(1:1024);	%!!!!
		j=strfind(s,'@PJL SET HOSTLOGINNAME');
		if ~isempty(j)
			sName=s(j+25:j+30);
			b=sName=='"';
			if sum(b)==2
				j=find(b);
				sName=sName(j(1)+1:j(2)-1);
			end
		end
	else
		snr=num2str(nr);
		j=strfind(x,['(' snr ' ']);
		s='';
		for k=1:length(j)
			x1=x(j(k)+1:j(k)+200);
			m=find(x1==')');
			if ~isempty(m)
				x1=convEsc(x1(1:m(1)-1));
				if k==1
					if ~isempty(j)
						sName=x1(length(snr)+2:end);
					end
				end
			end
			s=char(s,x1);
		end
	end
	L{1,i}=s;
	L{2,i}=sName;
	status(i/length(d))
end
status
bOK=Onr>0&cellfun('length',L(2,:))>0;
iOK=find(bOK);
iNOK=find(~bOK);
[N,i]=sort(Onr(bOK));
Onr=[N Onr(iNOK)];
L=L(:,[iOK(i) iNOK]);
d=d([iOK(i) iNOK]);

Users=unique(L(2,:));
O=struct('user',Users,'orders',[]);
i=1;
while i<=length(Users)
	O(i).user=Users{i};
	O(i).orders=find(strcmpi(Users{i},L(2,:)));
	if i<length(Users)
		b=strcmpi(Users{i},Users(i+1:end));
		if any(b)
			Users(i+find(b))=[];
		end
	end
	i=i+1;
end
O=O(1:i-1);

function s=convEsc(s)
cDig=false(1,255);
cDig(abs('01234567'))=true;
while any(s=='\')
	i=find(s=='\',1);
	if length(s)-i>=3&&all(cDig(abs(s(i+1:i+3))))
		s=[s(1:i-1) char(sscanf(s(i+1:i+3),'%o')) s(i+4:end)];
	else
		s(i)=[];
	end
end
