function pt=FindCrossingLines(L1,L2,ver)
%FindCrossingLines - Find crossing of lines using piecewise linear interpolation
%           pt=FindCrossingLines(L1,L2)
%  The first found crossing point is returned, giving [] in case nothing
%    is found.
%  This is just a simple point-by-point searching routine, not created for
%    fast search!  It's made quickly to find what I wanted to find (on
%    short lines).
%  A start is made for faster code (in case of longer lines) - which could
%  give more points on line 2, but all on the same section of line 1.

if nargin<3
	ver=1;
end
lim=1e-12;

if ver==2
	Q12=L2(2:end,1)-L2(1:end-1,1);
	Q22=L2(2:end,2)-L2(1:end-1,2);
end

for i=1:size(L1,1)-1
	if ver==1
		for j=1:size(L2,1)-1
			Q=[L1(i)-L1(i+1) L2(j+1)-L2(j);L1(i,2)-L1(i+1,2) L2(j+1,2)-L2(j,2)];
			if det(Q)==0
				% no crossing is found (previous or next point will detect...)
			else
				R=[L1(i)-L2(j);L1(i,2)-L2(j,2)];
				rs=Q\R;
				if all(rs>=0&rs<1)	% !!!last points
					pt=(1-rs(1))*L1(i,:)+rs(1)*L1(i+1,:);
					return	% only the first crossing(!)
				end
			end		% not parallel lines
		end		% for j (run through L2)
	else
		Q11=L1(i)-L1(i+1);
		Q21=L1(i,2)-L1(i+1,2);
		R1=L1(i)-L2(1:end-1,1);
		R2=L1(i,2)-L2(1:end-1,2);
		D=Q11*Q22-Q21*Q12;
		B=abs(D)>lim;
		R=inf(size(B));
		S=R;
		R(B)=(Q22(B).*R1(B)-Q12(B).*R2(B))./D(B);
		S(B)=(Q11.*R2(B)-Q21*R1(B))./D(B);
		B=R>=0&R<=1&S>=0&S<=1;
		if any(B)
			j=find(B);
			pt=bsxfun(@times,1-R(j),L1(i,:))+bsxfun(@times,R(j),L1(i+1,:));
			return
		end
	end
end		% for i (run through L1)
pt=[];
