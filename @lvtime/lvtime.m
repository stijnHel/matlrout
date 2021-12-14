function c=lvtime(varargin)
%lvtime/lvtime - contructor for lvtime class (LabView Timestamp)
%   c=lvtime ---> for "now"
%   c=lvtime(c0) ---> copies
%   c=lvtime([1x6] double) ---> from matlab time vector (see clock)
%   c=lvtime([1x1] double) ---> from matlab time stamp
%   c=lvtime([1x4] double)
%     or c=lvtime([1x4] uint32)
%     or c=length([1x16] double)
%     or c=lvtime([1x16] uint8)  ---> from lv-measurement
%     c=lvtime([1x4],1) --> reverses the input (BE/LE-problem)
%   c=lvtime([],fid) ---> reads lv-time from file
%   c=lvtime(year,month,day[,hr,min,sec]);	% specified date
%
%!! there is a problem with differences between UTC time and local time
%   labView writes UTC time, and therefore UTC time is supposed.  Using
%   pc-time all within matlab gives wrong dates!

% lvtime is often used in tdms-files, which are (by default) written in
% little endian type, while other binary formats are by default in big
% endian.  That's the reason for the need for reversal of the uint32.

tin=[];
if nargin==0
	t=now;
elseif nargin==1||~isempty(varargin{1})
	tin=varargin{1};
	if nargin>=3&&isnumeric(varargin{1})
		t=datenum(varargin{:});
		tin=[];
	elseif isa(tin,'lvtime')
		c=tin;
		return
	elseif isa(tin,'uint32')||isa(tin,'uint8')	...
			||(min(size(tin))==1&&(length(tin)==4||length(tin)==16))	...
			||size(tin,1)==4||size(tin,1)==16
		bReverseOrder=nargin>1&&varargin{2};
		if min(size(tin))>1
			if bReverseOrder
				tin=tin(end:-1:1,:);
			end
			if isa(tin,'uint8')
				tin=reshape([16777216 65536 256 1]*reshape(double(tin),4,[]),4,[]);
			end
			c=lvtime(uint32(tin(:,1)),false);
			c(1,size(tin,2))=c;
			for i=2:length(c)
				c(i).t=tin(:,i)';
			end
			return
		elseif length(tin)>16
			if rem(length(tin),16)
				error('Wrong number of inputs!')
			end
			tin=reshape(tin,16,[])';
		elseif size(tin,2)==1&&size(tin,1)>1
			tin=tin';
		end
		tin=double(tin);
		if size(tin,2)==4
			if bReverseOrder
				tin=tin(:,[4 3 2 1]);
			end
			if any(tin>floor(tin))	%?
				tin(:,1)=round(tin(:,1)*2^64);
				tin(:,2)=round(tin(:,2)*2^32);
				if any(tin(1:2)>=2^32)
					error('Wrong input')
				end
			end
		elseif size(tin,2)==16
			if bReverseOrder
				tin=tin(:,16:-1:1);
			end
			tin=reshape([16777216 65536 256 1]*reshape(tin',4,[]),4,[])';
		else
			error('Wrong input')
		end
	%elseif length(tin)==1
	elseif all(tin(:)>600000&tin(:)<800000)
		t=tin;
		tin=[];
	elseif all(tin(:)>2e9&tin(:)<4.29e9)
		t=tin/86400+datenum(1904,1,1);
		tin=[];
	elseif isequal(size(tin),[1 6])
		t=datenum(tin);
		tin=[];
	elseif isnumeric(tin)&&size(tin,2)==4
		%
	else
		error('impossible input')
	end
elseif nargin==2
	% read byte by byte to prevent problems of different byte orderings
	tin=fread(varargin{2},[4 4],'uint8');
	if numel(tin)<16
		error('Couldn''t read the data from file')
	end
	tin=[16777216 65536 256 1]*tin;
end

if isempty(tin)
	t=(t-datenum(1904,1,1))*3600*24;
	tin=[zeros(numel(t),1) floor(t(:)) (t(:)-floor(t(:)))*2^32 zeros(numel(t),1)];
	for i=1:size(tin,1)
		if tin(i,2)>=2^32	% >=Feb 6, 2040 (7:28:16)
			tin(i,1)=floor(tin(i,2)/2^32);
			tin(i,2)=rem(tin(i,2),2^32);
		end
	end
	tin(:,4)=(tin(:,3)-floor(tin(:,3)))*2^32;
	tin(:,3)=floor(tin(:,3));
end
C=struct('t',tin(1,:));
c=class(C,'lvtime');
if size(tin,1)>1
	c(1,size(tin,1))=c;
	for i=2:size(tin,1)
		c(i)=lvtime(tin(i,:));
	end
end
