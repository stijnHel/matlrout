%HEATdata - Numerical data related to heat transport
classdef HEATdata
	% class with data and functions related to heat transport
	%    D=HEATdata;	% creates the object
	%    P=NatConv(D,Tw,Tl,soort) % calculates specific natural convection power
	%    P=ForcedConv(D,Tw,Tl,v,soort) % calculates specific forced convection power
	%    P=Radiation(D,T[,lambda]) % calculates radiation power
	properties (SetAccess = public)
		c0=299792458;	% lichtsnelheid [m/s]
		h=0.662618e-33;	% constante van Planck [J.s]
		k=13.8066e-24;	% constante van Boltzmann [J/K]
		c1=0.374183e-15;% eerste stralingsconstante (2.pi.h.c^2) [W.m2]
		c2=14.38786e-3;	% tweede stralingsconstante (h.c/k) [K.m]
		sSB=56.7032e-9;	% Stefan Boltzmann constante [W/(K4.m2)]
		cLmax=3e-3;		% constant of Wien [K.m]
		cMmax=4e-6*pi;	% constant of Wien [W/m3.K^5]
		% (polytechnisch zakboekje (42e editie), G1)
		cNatConvVert=2.6;	% verticaal vlak, natuurlijke convectie
		cNatConvVertKl=[3.5 0.09]; % zelfde, klein T-verschil
		cNatConvHorVlak=3.3;
		cNatConvHorPijp=[1.11,0.233 0.3];
		cForConvGladTraag=[5.6 4.0];
		cForConvRuwTraag=[6.2 4.2];
		cForConvGladSnel=[7.12 0.78];
		cForConvRuwSnel=[7.53 0.78];
		cForConvPijp=[4.7 0.0035 0.61 0.39];
		matKar;
	end
	methods
		function c=HEATdata
			MKAR={
				'water',	0.6	998	4180;
				'ijzer',	79	7900	460;
				'koper',	390	8900	390;
				'xxx',	0.15	500	2100;
				'lucht',	0.024	1.29	1;
				'aluminium',	220	2700	880;
				'glas',	0.93	2600	830;
				'AISI1095st',51.9,7870,461
				};
			c.matKar=struct('name',MKAR(:,1),'k',MKAR(:,2),'rho',MKAR(:,3)	...
				,'c',MKAR(:,4));
		end		% HEATdata - constructor
		function P=NatConv(D,Tw,Tl,soort)
			%HEATdata/NatConv - Calculate national convetion heat transfer
			%         P=NatConv(D,Tw,Tl,soort)
			%             soort: 'vertikaal' / 'horizontaal'
			%                if not given - average vertical/horizontal
			dTa=abs(Tw-Tl);
			if ~exist('soort','var')||isempty(soort)
				if dTa>=15
					aHor=D.cNatConvVert*dTa.^0.25;
				else
					aHor=D.cNatConvVertKl(1)+D.cNatConvVertKl(2)*dTa;
				end
				aVer=D.cNatConvHorVlak*dTa.^0.25;
				alpha=(aHor+aVer)/2;
			elseif isnumeric(soort)
				d=soort;
				alpha=D.cNatConvHorPijp(1)*dTa.^D.cNatConvHorPijp(2)/d^D.cNatConvHorPijp(3);
			else
				switch soort
					case 'verticaal'
						if dTa>=15
							alpha=D.cNatConvVert*dTa.^0.25;
						else
							alpha=D.cNatConvVertKl(1)+D.cNatConvVertKl(2)*dTa;
						end
					case 'horizontaal'
						alpha=D.cNatConvHorVlak*dTa.^0.25;
					otherwise
						error('unknown type')
				end
			end
			P=(Tw-Tl)*alpha;
		end		% NatConv
		function P=ForcedConv(D,Tw,Tl,v,soort)
			%HEATdata/ForcedConv - Calculate forced convection heat transfer
			%    P=ForcedConv(D,Tw,Tl,v,soort)
			%           Tw   : temperature wall ([K] or [degC])
			%           Tl   :  (same as Tw)
			%           v    : velocity [
			%           soort: 'glad' / 'ruw'
			%     since only temperature difference is used, K and degC can
			%     be used without problem, as long as units are the same
			if isnumeric(soort)
				D=soort;
				alpha=(D.cForConvPijp(1)+D.cForConvPijp(2)*dT)*v^D.cForConvPijp(3)/D^D.cForConvPijp(4);
			else
				switch soort
					case 'glad'
						if v<=5
							f=D.cForConvGladTraag;
						else
							f=D.cForConvGladSnel;
						end
						alpha=f(1)+f(2)*v;
					case 'ruw'
						if v<=5
							f=D.cForConvRuwTraag;
						else
							f=D.cForConvRuwSnel;
						end
						alpha=f(1)*v^f(2);
				end
			end
			P=(Tw-Tl)*alpha;
		end		% ForcedConv
		function P=Radiation(D,T,lambda)
			%HEATdata/Radiation - Calculate radiation (density) at T,lambda
			%    P=Radiation(D,T) --> total radiation
			%    P=Radiation(D,T,lambda) --> radiation density
			if nargin==2
				P=D.sSB*T.^4;
			elseif isequal(size(lambda),[1 2])
				error('not implemented!')
			else
				P=D.c1*lambda.^-5./(exp(D.c2./(lambda*T))-1);
			end
		end		% Radiation
		function [lambda,M]=PeakWavelength(D,T)
			%HEATdata/PeakWavelength - Calculate peak wavelength (Wien law)
			%    [lambda,M]=PeakWavelength(D,T)
			lambda=D.cLmax/T;
			if nargout>1
				M=D.cMmax*T.^5;
			end
		end
	end		% methods
end
