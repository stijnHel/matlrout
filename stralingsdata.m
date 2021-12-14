% STRALINGSDATA - object met data ivm thermische straling
classdef stralingsdata
	properties
		% fysische constanten (uit poly-technisch zakboekje)
		c0=299792458;	% lichtsnelheid [m/s]
		h=0.66260693e-33;	% constante van Planck [J.s]
		k=13.806505e-24;	% constante van Boltzmann [J/K]
		b=2.8977685e-3;	% verschuivingsconstante van Wien
		c1=0.374183e-15;% eerste stralingsconstante (2.pi.h.c^2) [W.m2]
		c2=14.38786e-3;	% tweede stralingsconstante (h.c/k) [K.m]
		sSB=56.70373e-9;	% Stefan Boltzmann constante [W/(K4.m2)]
		
		l
	end		% properties

	methods
		function c=stralingsdata(l)
			if ~exist('l','var')||length(l)<10
				l=exp(log(100e-9):log(1.01):log(1));
			end
			c.l=l;
		end
		function l_wien=WienGolflengte(c,Tc)
			%stralingsdata/WienGolflengte - Calculates wavelength of maximum radiation
			%     l_wien=c.WienGolflengte(Tc)
			Tk=Tc+273.15;
			l_wien=c.b/Tk;
		end
		function l_wien=WienGolflengteK(c,Tk)
			%stralingsdata/WienGolflengteK - Calculates wavelength of maximum radiation
			%     l_wien=c.WienGolflengteK(Tk)
			l_wien=c.b/Tk;
		end
		
		function [P,L]=Straling(c,Tc,L)
			%stralingsdata/Straling - Calculates thermal radiation
			%    [P,L]=c.Straling(Tc,L)
			Tk=Tc+273.15;
			if nargin>2
				[P,L]=StralingK(c,Tk,L);
			else
				[P,L]=StralingK(c,Tk);
			end
		end
		function [P,L]=StralingK(c,Tk,L)
			%    [P,L]=c.StralingK(Tk,L) - straling
			if nargin>2
				if ~isequal(size(Tk),size(L))
					if isscalar(Tk)||isscalar(L)
						% OK
					elseif isvector(Tk)&&isvector(L)
						if size(Tk,1)==1
							if size(L,2)==1
								Tk=Tk(ones(1,size(L,1)),:);
								L=L(:,ones(1,size(Tk,2)));
							else
								error('Mismatch in row-vector length?!')
							end
						elseif size(Tk,2)==1
							if size(L,1)==1
								Tk=Tk(:,ones(1,size(L,2)));
								L=L(ones(1,size(Tk,1)),:);
							else
								error('Mismatch in column-vector length?!')
							end
						else
							error('Mismatch in sizes!')
						end
					else
						error('Mismatch in sizes!')
					end
				end
				P=(2*c.h*c.c0^2) ./ L.^5 ./ (exp(c.c2./(L.*Tk))-1);
			else
				P=c.sSB*Tk.^4;
				L=4e-6*pi*Tk.^5;
			end
		end		% StralingK
		
		function plot(c,l)
			%plot - function kept from earlier - but not active(=working)
			if nargin<2||isempty(l)
				l=c.l;
			end
			c.M=c.sSB*Tk.^4;
			c.Mlmax=4e-6*pi*Tk.^5;
			
			if exist('bPlot','var')&&bPlot
				nfigure
				plot(Tc,[c.Ml_l0;c.Ml_l1;c.Ml_l2;c.Ml_l3;c.Ml_l4;c.Ml_l5])
				grid
				title 'thermal radiation, function of T'
				ll=[l0 l1 l2 l3 l4 l5];
				cLeg=cell(1,length(ll));
				for i=1:length(ll)
					if ll(i)<1e-4
						cLeg{i}='{\mu}m';
						ll(i)=ll(i)*1e6;
					elseif ll(i)<0.1
						cLeg{i}='mm';
						ll(i)=ll(i)*1e3;
					else
						cLeg{i}='m';
					end
					cLeg{i}=[num2str(ll(i)) ' ' cLeg{i}];
				end
				legend(cLeg)
				%legend '0.6 {\mu}m' '1 {\mu}m' '2 {\mu}m' '5 {\mu}m' '8 {\mu}m' '14 {\mu}m'
				set(gca,'yscale','log')
				Tc1=(Tc(1:end-1)+Tc(2:end))/2;
				dT=diff(Tc);
				MM=[c.Ml_l0;c.Ml_l1;c.Ml_l2;c.Ml_l3;c.Ml_l4;c.Ml_l5];
				dM=diff(MM')';
				MM2=(MM(:,1:end-1)+MM(:,2:end))/2;
				nfigure
				%plot(Tc1,dM./dT(ones(1,size(dM,1)),:));grid
				plot(Tc1,dM./MM2./dT(ones(1,size(dM,1)),:));grid
				%semilogy(Tc1,dM./MM2./dT(ones(1,size(dM,1)),:));grid
				title 'relative change of radiation for different wavelengths'
				xlabel 'T [^oC]'
				ylabel '[W/(W ^oC)]'
				legend(cLeg)
				%savefig(4,'relchrad',[12 8])
			end
		end		% plot
	end		% methods
end