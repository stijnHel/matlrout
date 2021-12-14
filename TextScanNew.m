function A=TextScanNew(fname,delim)
%TextScanNew - textscan function - alternative for textscan / importdata
%   A=TextScanNew(fname[,delim])
%        if delim has a length > 1, one of them is chosen

bCommaCheck = true;

fid=fopen(fname);
if fid<3
	error('Can''t open the file')
end
x=fread(fid,[1 Inf],'*char');
fclose(3);

if nargin<2||length(delim)~=1
	if nargin>1&&length(delim)>1
		posDelim=delim;
	else
		posDelim=';;,';posDelim(1)=char(9);
	end
	nDelim=zeros(1,length(posDelim));
	for i=1:length(nDelim)
		nDelim(i)=sum(x==posDelim(i));
	end
	[nMax,i]=max(nDelim);
	if nMax==0
		error('No delimiter found')
	end
	delim=posDelim(i);
end
bDelim=x==delim;
bCR=x==10|x==13;
bCR1=~bCR(1:end-1)&bCR(2:end);	% end of line
bCR1(end+1)=~bCR1(end)&bCR(end);
if bCommaCheck&&delim~=','&&sum(x==',')	% is ',' decimal separator?
	if sum(x=='.')==0	% definitely...
		x(x==',')='.';
		fprintf(''','' replaced by ''.''!\n')
	end
end
nDelim=zeros(1,length(bDelim));
nDelim(1)=bDelim(1);
for i=2:length(nDelim)
	if bCR1(i)
		nDelim(i)=0;
	else
		nDelim(i)=nDelim(i-1)+bDelim(i);
	end
end
nCell=nDelim(bCR1(2:end))+1;
maxCell=max(nCell);
Ctext=cell(sum(bCR1),maxCell+1);
data=nan(size(Ctext));
iLine=1;
iCell=1;
i0=1;
for i=1:length(x)
	if bDelim(i)||bCR1(i)
		x1=x(i0:i-1);
		Ctext{iLine,iCell}=x1;
		%data(iLine,iCell)=str2double(x1);	% too slow
		[xn,nx,xerr]=sscanf(x1,'%g',1);
		if nx==1&&isempty(xerr)
			data(iLine,iCell)=xn;
		end
		if bCR1(i)
			% bDelim and bCR1 can be true
			% bCR1 has priority
			iCell=1;
			iLine=iLine+1;
		else
			iCell=iCell+1;
			i0=i+1;
		end
	elseif bCR(i)
		i0=i+1;
	end
end
bDataOK=~isnan(data);

nOK=sum(bDataOK,2);
u_nOK=unique(nOK);
nVals=u_nOK;
for i=1:length(u_nOK)
	bNormal=nOK>=u_nOK(i);
	bNumData=all(bDataOK(bNormal,:));
	nVals(i)=sum(bNormal)*sum(bNumData);
end
[~,iMax]=max(nVals);
normNnan=u_nOK(iMax);
%normNnan=median(nOK);
bNormal=nOK>=normNnan;

if any(bNormal)
	bNumData=all(bDataOK(bNormal,:));
	iNumData=find(bNumData);
	iNormal=find(bNormal)';
	iHead=find(~bNormal)';
else
	iNumData=[];
	iNormal=[];
	iHead=[];
end

if ~isempty(iNormal)
	bHcol=nCell(iHead)==nCell(iNormal(1));
	hData=Ctext(iHead(bHcol),:);
else
	hData={};
	iHead=[];
end
numData=data(iNormal,iNumData);


A=struct('text',x,'Ctext',{Ctext},'data',data	...
	,'iNormal',iNormal,'iHead',iHead,'iNumData',iNumData	...
	,'numData',numData,'nCell',nCell	...
	,'hData',{hData}	...
	,'delim',delim);
