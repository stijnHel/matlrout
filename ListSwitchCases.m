function X=ListSwitchCases(fName,varargin)
%ListCases - List cases in a switch statement
%    X=ListSwitchCases(fName,<var>)
%    X=ListSwitchCases(fName,<line1>,<line2>)

% !This might become something good, but currently very simple:
%   just any case statement is detected, counting on one statement per line
%      also no ... expected in case!
%   only (real) constants are allowed, no variables

F=cBufTextFile(fName);
L=fgetlN(F,100000);

if nargin<2
	bLineNr = true;
	line1 = 1;
	line2 = length(L);
elseif isnumeric(varargin{1})
	bLineNr = true;
	line1 = varargin{1};
	line2 = varargin{2};
else
	error('Not yet implemented!')
end

Cases=cell(1000,2);
nCases=0;
for lNr=line1:line2
	l=strtrim(L{lNr});
	if strncmp(l,'case',4)&&length(l)>5&&any(l(5)==[char(9) ' {'])
		i=5;
		i=SkipBlanks(l,i);
		bCase=true;
		caseCst=cell(1,0);
		if l(i)=='{'	% (possible) multiple cases
			i=SkipBlanks(l,i+1);
			bLoop=l(i)~='}';
			while bLoop
				if l(i)==''''
					[caseCst{1,end+1},i]=ReadString(l,i); %#ok<AGROW>
				else
					[caseCst{1,end+1},i,bErr]=ReadValue(l,i); %#ok<AGROW>
					if bErr
						bCase=false;
						break
					end
				end
				i=SkipBlanks(l,i);
				if i>length(l)
					bCase=false;
					warning('Unexpected end of line within {...}-construct?! (#%d "%s")'	...
						,lNr,l)
					bLoop=false;
				else
					if l(i)=='}'
						bLoop=false;
					elseif l(i)==','
						i=SkipBlanks(l,i+1);
						if i>length(l)
							bCase=false;
							warning('!!!??line broken in {...}-construct?! (#%d "%s")'	...
								,lNr,l)
						end
					else
						bCase=false;
						warning('Unexpected end of line within {...}-construct?! (#%d "%s")'	...
							,lNr,l)
						bLoop=false;
					end
				end
			end		% while in {...}
		elseif l(i)==''''	% string
			[caseCst,i]=ReadString(l,i);
		else	% numeric (or variable(!))
			[caseCst,i,bErr]=ReadValue(l,i);
			if bErr
				bCase=false;
			end
		end
		if bCase
			nCases=nCases+1;
			Cases{nCases}=caseCst;
			Cases{nCases,2}=strtrim(l(i:end));	% (!check if comment)
		end
	end
end

X=Cases(1:nCases,:);

	function [s,i]=ReadString(l,i)
		j=i+1;
		while l(j)~=''''||(j<length(l)&&all(l(j:j+1)==''''))
			j=j+1+(l(j)=='''');
		end
		s=l(i+1:j-1);
		i=j+1;
	end

	function [v,i,bErr]=ReadValue(l,i)
		[v,n,err,iNxt]=sscanf(l(i:end),'%g',1);
		bErr=n==0;
		if bErr
			warning('error in numeric case (#%d, "%s" - error: "%s")'	...
				,lNr,l,err)
		end
		i=i+iNxt-1;
	end

	function i=SkipBlanks(l,i)
		while i<=length(l)&&(l(i)==' '||l(i)==9)
			i=i+1;
		end
	end

end
