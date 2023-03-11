function [e,ne,de,e2,gegs]=leesKLIMALOGG(fName)
%leesKLIMALOGG - Reads data from KLIMALOGG...pro
%     [e,ne,de]=leesKLIMALOGG(fName)

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
% it happens now and then that the time suddenly changes to a wrong date
% (with often the right time).  It can be a time in the past, or in the
% future, days/months/years further.
% The following tries to correct the times (it assumes that the data is
% added chronological, so no shuffling of the data is done.
% It's done very simple, and doesn't work for 100%!
% Apparently some wrong order of data occurs (like around 2023-03-02
% 02:00).
if any(diff(t)<0)
	%warning('!!!')
	ii = find(abs(diff(t))>2);	% all steps (positive and negative)
	i = 1;
	cnt = 0;
	while i<length(ii)	% these are in fact two loops in one:
						%      - loop through all jumps
						%      - after a loop, with a maximum number of
						%        loops, do everything again.
						% This is done because successive jumps to a wrong
						% dateoccur, with a wrong date in between.
		dt1 = t(ii(i)+1)-t(ii(i));
		dt2 = t(ii(i+1)+1)-t(ii(i+1));
		if dt1*dt2<0 && abs(dt1/dt2+1)<0.5
			ii1 = ii(i)+1;
			ii2 = ii(i+1);
			dtM = median(diff(t(max(1,ii1-20):min(end,ii1+20))));
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
		if i>=length(ii) && cnt<4
			i = 1;
			ii = find(diff(t)>0.05 | diff(t)<-0.01);
			cnt = cnt+1;
			t = e(:,1);
		end
	end
end
