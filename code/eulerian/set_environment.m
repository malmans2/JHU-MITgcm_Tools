% matal, Mar. 2017

%=================================================
% SET ENVIRONMENT
%=================================================
                                                                                       
% Set global variables                                                                                                                    
run set_globalvars                                                                                                                        
run set_DefaultAxes                                                                                                                       
                                                                                                                                          
% Create logID                                                                                                              
if ~isempty(logname)                                                                                                                      
        if exist(logname, 'file') == 2                                                                                                    
                logID = fopen(logname,'a');                                                                                               
        else                                                                                                                              
                logID = fopen(logname,'w');                                                                                               
        end       
	fprintf(1,'\n-------------------------------------------------------'); 
	fprintf(1,'\n Welcome to the SciServer Ocean Modelling User Case!');
	fprintf(1,'\n-------------------------------------------------------\n');
else                                                                                                                                      
        logID = 1;                                                                                                                        
end                                                                        
fprintf(logID,'\n-------------------------------------------------------'); 
fprintf(logID,'\n Welcome to the SciServer Ocean Modelling User Case!');
fprintf(logID,'\n-------------------------------------------------------\n');

% Read NetCDF information                                                                                                                 
run info_NetCDF                                                                                                                           

% Read grid variables                                                                                                                     
grid = read_Grid;       

% Close logID
if ~isempty(logname)                                                                                                                      
        fclose(logID);                                                                                                                    
end      
