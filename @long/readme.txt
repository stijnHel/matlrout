----------------------    LONG CLASS NOTES (1.0)   ---------------------

-'Long' class is an user defined class designed to work with numbers in a much bigger domain.

- A long object is constructed as follows:

                             ^   double        
   long =   double    ·    10
           \__  __/             \__  __/
              \/                   \/ 
        long.decimales       long.potencia

  so the domain is: 

 
	          ^ 1e308            ^ 1e308
	[-1e308·10        ,-1e308·10         ]


- This class as been created to avoid the next problem (working with fuzzy systems)

  
      We have a set of small numbers (but non zero) E  0<i<M+1. Treated as zero by Matlab
                                                     i 
      And other set of double classed numbers  	y
						 i

      When you try to the following average:


      M
     ---    y  · E
     \       i    i
     /     _________  the result is NaN despite of being a good ranged double.
     ---       E
     i=1	i	                           

- With long objects this can be solved.
		 
 
INSTALL NOTES:
 
 -It's recommended to read the next tip in Matlab help: "MATLAB Classes and Objects". 
 
 -Put the @long folder in a folder of the Matlab path. But don't add its contents directly to the path. 
 
 -Long objects are crated with the constructor 'long.m'.

 -Some methods are included, overloading some operators and common functions. Speacially usefull is: 'double'.

 -Array notation is permitted.


Crated by:

               Ignacio del Valle Alles (ignacio_del_valle_alles@scientist.com)

                     $Revision: 1.0 $  $Date: 2003/03/26 10:29:20 $







