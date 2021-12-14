% TWOWPWM  - C-S-function implementing a two way PWM valve
%
%  4 or 6 parameters :
%     1. PWM-period
%     2. time-offset (start of PWM-cycle)
%     3. time of opening valve
%     4. time of closing valve
%     5. area from feed to output
%     6. area from output to sump (or low pressure side)
%
%  if only 4 parameters supplied, three inputs are required :
%     1. PWM-duty cycle
%     2. area from feed to output
%     3. area from output to sump
%
%  otherwise only one input is available (and required)
