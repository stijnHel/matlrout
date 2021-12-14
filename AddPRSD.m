function AddPRSD(bWithData)
%AddPRSD  - Add PRSD-toolbox to path
%    AddPRSD
%    AddPRSD(bWithData)	 - directory with testdata (currently default true)

if nargin==0
	bWithData=true;
end
addpath /mnt/samba/fmtc-share/toolboxes/matlab/PRSD_Studio/prsd_toolbox/ -end
if bWithData
	addpath /mnt/samba/fmtc-share/toolboxes/matlab/PRSD_Studio/data/ -end
end
