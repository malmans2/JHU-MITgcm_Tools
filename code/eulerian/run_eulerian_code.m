% Run the eulerian code
%
% matal, Feb. 2017


% Skip if option is 0
if option == 0
	return
end

% Create logfile 
if ~isempty(logname)                                                                                                                      
        if exist(logname, 'file') == 2                                                                                                    
                logID = fopen(logname,'a');                                                                                               
        else                                                                                                                              
                logID = fopen(logname,'w');                                                                                               
        end                                                                                                                               
else                                                                                                                                      
        logID = 1;                                                                                                                        
end      

% ==================================================
% RUN FUNCTION
% ==================================================
fprintf(logID,'\n\n===========================================');                                                                         
fprintf(logID,'\nStart: %s\n',char(datetime('now')));
fprintf(logID,'\nOption %d: ',option);

switch option
	case 1
		fprintf(logID,'PLOT GRID + BATHYMETRY\n',option);
		[figgrid] = plot_Grid(savefig);
	case 2
		fprintf(logID,'READ FIELDS\n',option);
		[FIELDS] = read_Fields(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,...
				       plotmap,savemat,interpC);
	case 3
		fprintf(logID,'CREATE VERTICAL SECTION\n',option);
		[VERTSECS] = create_VerticalSection(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,...
                                                    plotmap,savemat,plotmean,savemovie);
	case 4
		fprintf(logID,'COMPUTE ORTHOGONAL/TANGENTIAL VELOCITIES\n',option);
		[VSVEL] = compute_VSVelocities(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,...
					       plotmap,savemat,plotmean,savemovie);	
	case 5
		fprintf(logID,'COMPUTE TRANSPORT THROUGH A SECTION\n',option);
		[TRANSPORT] = compute_Transport(Temprange,Srange,Sigma0range,Time,deltaT,Depthrange,Latrange,...
					       Lonrange,plotmap,savemat,plottransp);
	case 6
		fprintf(logID,'CREATE HORIZONTAL SECTION\n',option);
                [HORSECS] = create_HorizontalSection(Fields,Time,deltaT,Depth,Latrange,Lonrange,...
                                                    plotmap,savemat,plotmean,savemovie);
	otherwise
		error('Error. \nOption [%d] not available',option)
end

fprintf(logID,'\nAll done: %s\n',char(datetime('now')));
fprintf(logID,'===========================================\n\n');

% Close log file
if ~isempty(logname)
        fclose(logID);
end

