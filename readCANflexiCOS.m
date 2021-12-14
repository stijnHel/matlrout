function D=readCANflexiCOS(fn)
%readCANflexiCOS - Read CAN-recoder file made by flexiCOS
%    D=readCANflexiCOS(fn)

fid=fopen(fn,'rt');
if fid<3
	fid=fopen(zetev([],fn),'rt');
	if fid<3
		error('Can''t open file')
	end
end

s=fgetl(fid);
if ~strcmp(s(4:end),'RecorderG4')
	warning('CANflexiCOS:start','Different start of CAN-log? "%s"',s)
end
H=cell(0,2);
s=fgetl(fid);
while ~strncmp(s,'BeginData',9)
	i9=find(s==9);
	if isempty(i9)
		continue	%?error?
	end
	H{end+1,1}=s(1:i9(1)-1);
	H{end,2}=s(i9(1)+1:end);
	s=fgetl(fid);
end
s=fgetl(fid);
i9=[0 find(s==9) length(s)+1];
Nchan=length(i9)-1;
C=cell(1,Nchan);
for i=1:Nchan
	C{i}=s(i9(i)+1:i9(i+1)-1);
end
s=fgetl(fid);
X=zeros(1000,13);
iX=0;
nError=0;
C={C{1},[C{2} ' ' C{3}],C{4:end}};
while ~strncmp(s,'EndData',7)
	i9=[find(s==9) length(s)+1];
	if Nchan~=length(i9)
		if nError==0
			warning('CANflexiCOS:wrongData','Wrong number of data?')
		end
		nError=nError+1;
		continue	%?error?
	end
	iX=iX+1;
	if iX>size(X,1)
		X(end+1000,1)=0;
	end
	X(iX,1)=str2double(s(1:i9(1)-1));
	d=sscanf(s(i9(1)+1:i9(2)-1),'%d/%d/%d %d:%d:%d');
	X(iX,2)=datenum(d(3),d(2),d(1),d(4),d(5),d(6));
	X(iX,3)=str2double(s(i9(2)+1:i9(3)-1));
	for i=4:min(Nchan,13)
		X(iX,i)=sscanf(s(i9(i)+1:i9(i+1)-1),'%x');
	end
	s=fgetl(fid);
end
fclose(fid);
D=struct('H',{H},'C',{C},'X',X(1:iX,:));
