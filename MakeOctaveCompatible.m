function MakeOctaveCompatible(dName,bRecursive)
%MakeOctaveCompatible - make an M-file compatble to Octave
%    MakeOctaveCompatible(dName[,bRecursive)
%    MakeOctaveCompatible(fName)
%
%  currently - add '%' in ...-terminated lines
%
% Warning: Files are overwritten!!!!

if ischar(dName)
	dType=exist(dName,'file');
	if dType==2
		TestAndChange(dName)
	elseif dType==7
		if nargin<2||isempty(bRecursive)
			bRecursive=false;
		end
		d=dir(fullfile(dName,'*.m'));
		for i=1:length(d)
			if ~d(i).isdir
				TestAndChange(fullfile(dName,d(i).name))
			end
		end
		if bRecursive
			d=dir(dName);
			for i=1:length(d)
				if d(i).name(1)~='.'&&d(i).isdir
					MakeOctaveCompatible(fullfile(dName,d(i).name));
				end
			end
		end
	else
		error('Unknown input (or not found file/directory!')
	end
else
	error('Wrong input')
end

function TestAndChange(fName)
cFile=cBufTextFile(fName);
L=cFile.fgetlN(100000);
iL=0;
bChanged=false;
while iL<length(L)
	iL=iL+1;
	l=L{iL};
	if iL>=length(L)
		L=[L,cFile.fgetlN(100000)];
	end
	nl=length(l);
	l=deblank(l);	% Contents can change without "remarking"
	bSimpChange=nl~=length(l);
	if bSimpChange&&~isempty(l)
		fprintf('%s: #%d "%s" (%d)\n',fName,iL,l,length(l)-nl)
		L{iL}=l;
	end
	i=1;
	bChanged1=false;
	while i<length(l)
		if l(i)=='%'
			break
		elseif l(i)==''''
			i=i+1;
			while i<length(l)
				if l(i)==''''
					i=i+1;
					if l(i)~=''''
						break;
					end
				end
				i=i+1;
			end
		elseif l(i)=='.'&&i+2<length(l)&&l(i+1)=='.'&&l(i+2)=='.'
			i=i+3;	% ending with "more than ..."
			while i<=length(l)
				if l(i)~=' '&&l(i)~=9
					if l(i)~='%'
						bChanged1=true;
						l=[l(1:i-1) '% ' l(i:end)];
					end
					break
				end
				i=i+1;
			end
			break
		else
			i=i+1;
		end
	end		% while i<length(l)
	if bChanged1
		bChanged=true;
		L{iL}=l;
	end
end		% while still lines to handle

if bChanged
	fprintf('"%s" is changed!\n',fName)
	while isempty(L{end})
		L(end)=[];
	end
	fid=fopen(fName,'wt');
	fprintf(fid,'%s\n',L{:});
	fclose(fid);
end
