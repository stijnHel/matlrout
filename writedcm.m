function writedcm(X,fnaam,sext1,sext2)
% WRITEDCM - Schrijft data naar DCM
%  writedcm(X,fnaam[,sext1,sext2]])
%     X - parameterblok (uit bijvoorbeeld leesdcm)
%     fnaam - naam van file waarnaar geschreven wordt
%     sext1,sext2 - als gegeven, wordt einde van naam vervangen van
%         sext1 naar sext2

if ~exist('sext1','var')
	sext1='';
end
if ~exist('sext2','var')
	sext2='';
end
fid=fopen(fnaam,'wt');
if fid<3
	error('kan file niet openen')
end
anderEinde=[];
for i=1:length(X)
	naam=X(i).naam;
	if length(naam)<length(sext1)
		anderEinde(end+1)=i;
		%fprintf('%s : ',naam);
		%warning('!!!naam kleinerdan te vervangen gedeelte')
	elseif ~strcmp(naam(end-length(sext1)+1:end),sext1)
		anderEinde(end+1)=i;
		%fprintf('%s : ',naam);
		%warning('!!!naam eindigt niet op te vervangen gedeelte!!!');
	else
		naam=[naam(1:end-length(sext1)) sext2];
	end
	switch X(i).type
	case '1D'
		fprintf(fid,'KENNLINIE  %s  %d\n',naam,size(X(i).value,1));
		SchrijfData(fid,X(i).value(:,1),'ST/X',nValsPerRij);
		SchrijfData(fid,X(i).value(:,1),'WERT',nValsPerRij);
		fprintf(fid,'END\n');
	case '2D'
		fprintf(fid,'KENNFELD  %s  %d %d\n',naam,fliplr(size(X(i).value)-1));
		SchrijfData(fid,X(i).value(1,2:end),'ST/X',nValsPerRij);
		for j=2:size(X(i).value,1)
			fprintf(fid,'\n');
			SchrijfData(fid,X(i).value(j,1),'ST/Y',1);
			SchrijfData(fid,X(i).value(j,2:end),'WERT',nValsPerRij);
		end
		fprintf(fid,'END\n');
	case 'lijst'
		fprintf(fid,'FESTWERTEBLOCK  %s  %d\n',naam,length(X(i).value));
		fprintf(fid,'   WERT  %g %g %g %g %g %g %g %g %g %g\n',X(i).value);
		if rem(size(X(i).value,2),10)
			fprintf(fid,'\n');
		end
		fprintf(fid,'END\n');
	case 'param'
		fprintf(fid,'FESTWERT  %s\n',naam);
		SchrijfData(fid,X(i).value,'WERT',nValsPerRij);
		fprintf(fid,'END\n');
	case 'vlag'
		fprintf(fid,'FESTWERT  %s\n',naam);
		if X(i).value
			fprintf(fid,'   WERT  true\n');
		else
			fprintf(fid,'   WERT  false\n);
		end
		fprintf(fid,'END\n');
	otherwise
		fclose(fid);
		error(sprintf('onbekend type (%s : %s)',naam,X(i).type))
	end
end
fclose(fid);
if ~isempty(anderEinde)
	fprintf('%d elementen werden niet weggeschreven vanwege ander einde van naam!!\n',length(anderEinde))
end

function [sTyp,nValsPerRij]=GetType(v,nValsPerRij)
% GetType - geeft type-string om getallen te geven
if any(v>floor(v))
	if max(v>=1)
		sTyp=' %g';
	else
		sTyp=' %e';
		nValsPerRij=min(nValsPerRij,5);
	end
else
	sTyp=' %d';
end
sTyp=repmat(sTyp,1,nValsPerRij);

function SchrijfData(fid,v,s,nValsPerRij)
[sTyp,nValsPerRij]=GetType(v,nValsPerRij);
fprintf(fid,['   ' s ' ' sTyp '\n'],v);
if rem(length(v),nValsPerRij)
	fprintf(fid,'\n');
end
