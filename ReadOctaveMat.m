function [D,Dc]=ReadOctaveMat(fn)
%ReadOctaveMat - Reads Octave mat-file
%      D=ReadOctaveMat(fn)

fid=fopen(fn);
if fid<3
	fid=fopen(zetev([],fn));
	if fid<3
		error('Can''t open the file')
	end
end

lHead=fgetl(fid);
if ~strncmp(lHead,'# Created by Octave',19)
	fclose(fid);
	error('File in wrong format')
end
Dc=cell(3,1000);
nD=0;
while ~feof(fid)
	l=fgetl(fid);
	if ~ischar(l)
		break
	end
	if isempty(l)
		continue
	end
	if length(l)<3
		fprintf('    "%s"\n',l)
		warning('READOCTMAT:ShortStart','Too short line? ("%s") - reading stopped',l)
		break
	end
	if l(1)=='#'
		name='';
		typ='';
		rows=[];
		cols=[];
		ndims=[];
		elements=[];
		len=[];
		bMatrix=[];
		bComplex=[];
		while true
			l=strtrim(l(2:end));
			i=find(l==':',1);
			if isempty(i)
				fclose(fid);
				error('Error while reading')
			end
			tp=l(1:i-1);
			info=strtrim(l(i+1:end));
			switch tp
				case 'name'
					name=info;
				case 'type'
					bComplex=strncmp(info,'complex ',8);
					if bComplex
						info=info(9:end);
					end
					typ=info;
					if strcmp(info,'scalar')
						break
					elseif strcmp(info,'matrix')
						bMatrix=true;
					end
				case 'rows'
					rows=str2double(info);
				case 'columns'
					cols=str2double(info);
					if bMatrix
						break
					end
				case 'ndims'
					ndims=str2double(info);
					break
				case 'elements'
					elements=str2double(info);
					if elements==0
						break;	% if string, no length is given if no elements
					end
				case 'length'
					len=str2double(info);
					break;	% (!)if string
				otherwise
					warning('READOCTMAT:UnknownInfo','Unknown info for variable (%s)',tp)
			end
			l=fgetl(fid);
		end		% while
		switch typ
			case 'scalar'
				l=fgetl(fid);
				if bComplex
					Ddata=[1 1i]*sscanf(l,'(%g,%g');
				else
					Ddata=str2double(l);
				end
			case 'matrix'
				if isempty(ndims)
					dims=[cols rows];
				else
					l=fgetl(fid);
					dims=sscanf(l,'%d')';
					if length(dims)~=ndims
						warning('READOCTMAT:UnknownType','%s - wrong dims?',name)
					end
				end
				if bComplex
					Ddata=[1 1i]*fscanf(fid,' (%g,%g)',[2 prod(dims)]);
					%for i=1:rows
					%	l=fgetl(fid);
					%end
				else
					N=prod(dims);
					Ddata=fscanf(fid,'%g',[1 N]);
					if length(Ddata)<N
						i=length(Ddata);
						l=fgetl(fid);
						Ddata(1,N)=0;
						while i<N&&strncmp(l,'NA',2)
							l=strrep(l,'NA','NaN');
							d=sscanf(l,'%g',[1 N]);
							Ddata(i+1:i+length(d))=d;
							i=i+length(d);
							if i<N
								d=fscanf(fid,'%g',[1 N-i]);
								Ddata(i+1:i+length(d))=d;
								i=i+length(d);
							end
						end
						if i<N
							warning('READOCTMAT:EarlyStop','Early stop!?',name)
						end
					end
				end
				Ddata=reshape(Ddata,dims);
				if length(dims)<3
					Ddata=Ddata.';
				%else
				%	Ddata=permute(reshape(Ddata,dims),[2 1 3:length(dims)]);
				end
			case 'sq_string'
				if isempty(len)
					len=0;
				end
				Ddata=char(zeros(elements,len));
				for i=1:elements
					l=fgetl(fid);
					Ddata(i,:)=l;	% ????OK
				end
			otherwise
				warning('READOCTMAT:UnknownType','Unknown type for variable (%s)',tp)
		end
		nD=nD+1;
		Dc{1,nD}=name;
		Dc{2,nD}=typ;
		Dc{3,nD}=Ddata;
	else
		fprintf('    "%s"\n',l)
		warning('READOCTMAT:WrongStart','Normal line? ("%s") - reading stopped',l)
	end
end
fclose(fid);
Dc=Dc(:,1:nD);
D=struct(Dc{[1 3],:});
