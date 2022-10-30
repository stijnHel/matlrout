function [e,ne,de,e2,gegs]=leesKLMALOGG(fName)
%leesKLMALOGG - Reads data from KLIMALOGG...pro
%     [e,ne,de]=leesKLMALOGG(fName)

t0 = 1721059;
if nargin==0
	fName = [];
end
if isempty(fName)
	fName = '0_history.dat';
	if ~exist(fName,'var')
		zetev('C:\Users\stijn.helsen\AppData\Roaming\KlimaLoggPro')
	end
end
fFull = fFullPath(fName);
fid = fopen(fFull);
X = fread(fid,[84,Inf],'*uint8');
fclose(fid);
t = double(typecast(reshape(X(1:8,:),[],1),'uint64'))/86400e6-t0;
X = double(reshape(typecast(reshape(X(9:end,:),[],1),'single'),[],length(t))');
e = [t,X(:,1:end-1)];
ne = cell(1,size(e,2));
de = cell(size(ne));
ne{1} = 't';		de{1} = 'days';
ne{2} = 'T_I';
ne{3} = 'RH_I';
de(2:2:end) = {'degC'};
de(3:2:end) = {'%'};
nExt = (length(ne)-3)/2;
ne(4:2:end) = cellstr(reshape(sprintf('T_%d',1:nExt),3,[])');
ne(5:2:end) = cellstr(reshape(sprintf('RH_%d',1:nExt),4,[])');
e2 = [];
gegs = struct('t',t);	% uncorrected t
if any(diff(t)<0)
	%warning('!!!')
	dtM = median(diff(t));
	ii = find(abs(diff(t))>2);
	i = 1;
	while i<length(ii)
		dt1 = t(ii(i)+1)-t(ii(i));
		dt2 = t(ii(i+1)+1)-t(ii(i+1));
		if dt1*dt2<0 && abs(dt1/dt2+1)<0.5
			ii1 = ii(i)+1;
	% 		ii2 = ii1+1;
	% 		while abs(t(ii2)-t(ii2-1))>dtM*3
	% 			ii2 = ii2+1;	%!!!!! check for end!!!!
	% 		end
			ii2 = ii(i+1);
			t1 = t(ii1:ii2)+(t(ii(i))+dtM-t(ii1));
			if false && t1(end)>t(ii2+1)
				t0 = t1(1);
				t1 = t0 + (t1-t0)/(t1(end)-t0)*(t(ii2+1)-dtM-t0);
			end
			e(ii1:ii2) = t1;
			i = i+2;
		else
			i = i+1;
		end
	end
end
