function tex2txt(fsource,fdest,txtfor)
%TEX2TXT  - TeX format to txt
%  to remove non-paragraph EOL's and replace some special (La)Tex items to
%  standard text.

if ~exist('txtfor','var')||isempty(txtfor)
	txtfor='DOS';
end

fid=fopen(fsource);
if fid<3
	error('Can''t open the file')
end

x=fread(fid,[1 1e7],'*char');
fclose(fid);

iCR=find(x==13);
iLF=find(x==10);

if isequal(iCR+1,iLF)
	x(iCR)='';
elseif isempty(iCR)
	if isempty(iLF)
		error('Text with not a signal linefeed or carriage return is no right input for this function')
	end
	%OK
elseif isempty(iLF)
	x(iCR)=char(10);
	iLF=iCR;
else
	if iCR(end)==length(x)
		iCR(end)=[];
	end
	i=find(x(iCR+1)==10);
	x(i)='';
	x(x==13)=char(10);
end

x(x==9)=' ';
x=strrep(x,'``','"');
x=strrep(x,'''''','"');

x(end+1)=char(0);	% sentinel
i=1;
iLFlast=0;
typeLine=0;
while i<length(x)
	binc_i=true;
	if x(i)==' '
		if x(i+1)==10
			x(i)='';
			if i>1
				i=i-1;
			end
			binc_i=false;
		elseif x(i+1)==' '
			if i<2||x(i-1)~='.'
				x(i)='';
				binc_i=false;
			end
		end
	elseif x(i)==10
		if x(i+1)~=10
			j=i+1;
			while x(j)==' '
				j=j+1;
			end
			if x(j)==10	% line with only blanks
				x(i+1:j-1)='';
				iLFlast=i;
				typeLine=1;	% empty
			elseif typeLine<10&&x(j)~='\'
				x(i)=' ';
			else
				iLFlast=i;
				i=j;
				if strcmp(x(j:min(end,j+3)),'\end')	...
						||strcmp(x(j:min(end,j+5)),'\begin')	...
						||strcmp(x(j:min(end,j+7)),'\section')	...
						||strcmp(x(j:min(end,j+4)),'\subs')
					typeLine=10;
				else
					typeLine=2;
				end
				binc_i=false;
			end
		else
			iLFlast=i;
		end
	end
	if binc_i
		i=i+1;
	end
end

x=x(1:end-1);	% verwijderen van sentinel
		
switch lower(txtfor)
	case 'dos'
		x=strrep(x,char(10),char([13 10]));
	case 'unix'
		% no change
	case 'mac'
		x(x==10)=char(13);
	%otherwise no change (unix)
end

fid=fopen(fdest,'w');
if fid<3
	error('Can''t open destination file for writing')
end
fwrite(fid,x);
fclose(fid);
