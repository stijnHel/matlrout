function D = ReadGITlog(varargin)
%ReadGITlog - Read log of git repository
%      D = ReadGITlog(...)
%          options: gitDir: directory of git repository
%          S: string of git-log

gitDir = [];
[S] = [];
nSpaceRem = 4;
if nargin
	setoptions({'gitDir','S','nSpaceRem'},varargin{:})
end

if isempty(S)
	if ~isempty(gitDir)
		curDir = pwd;
		cd(gitDir)
	end
	[b,S] = dos('git log');
	if b
		warning('Error in git? (%d)',b)
	end
	if ~isempty(gitDir)
		cd(curDir)
	end
end

MONTHS = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

iiLF = [0,find(S==newline),length(S)+1];

D = struct('t',NaN,'ID',cell(1,round(length(iiLF)/6))	...
	,'author',[], 'comment',[],'tZone',0	...
	,'merge',[]	...
	);
nD = 0;
iL = 1;
while iL<length(iiLF)
	l = S(iiLF(iL)+1:iiLF(iL+1)-1);
	iL = iL+1;
	[w,~,~,i] = sscanf(l,'%s',1);
	if ~isempty(w)
		if strcmp(w,'commit')
			nD = nD+1;
			D(nD).ID = uint8(sscanf(l(i+1:end),'%02x',[1 100]));	% normally length 20
			while true
				l = S(iiLF(iL)+1:iiLF(iL+1)-1);
				iL = iL+1;
				[w,~,~,i] = sscanf(l,'%s',1);
				switch w
					case 'Author:'
						D(nD).author = l(i+1:end);
					case 'Date:'
						sDate = strtrim(l(i+1:end));
						sMon = sDate(5:7);
						nT = sscanf(sDate(9:end),'%d %d:%d:%d %d %d',[1,6]);
						if length(nT)<6
							warning('Unexpected date format?! (#%d: "%s")',iL-1,l)
						else
							iMon = find(strcmp(sMon,MONTHS));
							if isempty(iMon)
								warning('Unknown month?! (#%d: "%s")',iL-1,l)
							else
								D(nD).tZone = nT(6)/100;
								t = datenum([nT(5),iMon,nT([1 2 3 4])]);
								D(nD).t = t;
							end
						end
					case 'Merge:'
						D(nD).merge = l(i+1:end);
					otherwise
						comment = {};
						while iL<length(iiLF) && ~strcmp(S(min(end,iiLF(iL+1)+(1:6))),'commit')
							l = S(iiLF(iL)+1:iiLF(iL+1)-1);
							if length(l)>2
								if all(l(1:min(nSpaceRem,length(l)))==' ')
									l(1:min(nSpaceRem,length(l))) = [];
								end
								comment{1,end+1} = deblank(l); %#ok<AGROW>
							end
							iL = iL+1;
						end
						if isscalar(comment)
							comment = comment{1};
						else
							[comment{2,:}] = deal(newline);
							comment = [comment{1:end-1}];
						end
						D(nD).comment = comment;
						break
				end
			end
		else
			warning('Unexpected data?! (#%d: "%s")',iL-1,l)
		end
	end
end		% while iL
D = D(nD:-1:1);	% log is sorted newest --> oldest
	% D is ordered chronologically (oldest first)
