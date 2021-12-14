function X=J1939can(X)
%J1939can - Analyse CAN-log based on J1939 protocol (basic!)
%      X=J1939can(X)
%            X-structure is extended with new fields
%See also ReadCANLOG

ID=X.ID;
PRIOR=bitand(floor(ID/2^26),7);
EXTDP=bitand(floor(ID/2^25),1);
DATAP=bitand(floor(ID/2^24),1);
PDUF=bitand(floor(ID/2^16),255);
PDUS=bitand(floor(ID/2^ 8),255);
%PGN=bitand(floor(ID/256),16777215);	% combination of DATAP,EXTDP,PDUF,PSUS
PGN=bitand(floor(ID/256),65535);	% combination of DATAP,EXTDP,PDUF,PSUS
SRC=bitand(ID,255);

X.PRIOR=PRIOR;
X.EXTDP=EXTDP;
X.DATAP=DATAP;
X.PDUF=PDUF;
X.PDUS=PDUS;
X.PGN=PGN;
X.SRC=SRC;
