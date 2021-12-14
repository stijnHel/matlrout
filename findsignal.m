function [I,k]=findsignal(e,e1,di,kol,kol1)
%findsignal - find identical parts of in long measurement
%     [I,k]=findsignal(e,e1[,di,kol,kol1])
%            e is supposed to be a large array, from which column 1 is time
%            e1 is supposed to be a small array with the same number of columns
%            di : steps of indices to check (if it's known that only
%                 multiples of indices are possible)
%            kol, kol1 : if not the default indices have to be tested (2:end)
%      time (column1 one) is not regarded
%   The indices are searched where e(I:...,2:end)==e1(:,2:end).
%   If no index found, <k> gives the largest equal part beginning from the
%   start.

if ~exist('di','var')||isempty(di)
	di=1;
end
if ~exist('kol','var')||isempty(kol)
	kol=2:size(e,2);
    if isempty(kol)
        kol=1;
    end
end
if ~exist('kol1','var')||isempty(kol1)
	kol1=kol;
end


I=0:di:length(e)-length(e1);
k=0;
ne1=size(e1,1);
while k<ne1
	k=k+1;
	I=I(all(e(I+k,kol)==e1(k(ones(1,length(I))),kol1),2));
	if isempty(I)
		k=k-1;
		break
	elseif length(I)==1
		if k==ne1
			break
		else
			if all(all(e(I+k+1:I+ne1,kol)==e1(k+1:end,kol1)))
				k=ne1;
			else
				i=find(~all(e(I+k+1:I+ne1,kol)==e1(k+1:end,kol1),2),1,'first');
				I=[];
				k=k+i-1;
			end
			break;
		end
	end
end
