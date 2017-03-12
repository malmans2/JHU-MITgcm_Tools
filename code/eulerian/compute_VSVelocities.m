function [VSVEL] = create_VSVelocities(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,plotmap,savemat,plotmean,savemovie)
%
% ==================================
% AUTHOR: Mattia Almansi
% EMAIL: mattia.almansi@jhu.edu
% ==================================
%
% Read MITgcm outputs and create a vertical section.
% Global variables are called by run set_globalvars
%
% INPUT:
%       Fields:     cell array containing fields' names
%                   e.g. Fields = {'Temp' 'S' 'U' ...}
%       deltaT:     0 if Time defines every single time.
%                   Otherwise, set the timestep in days.
%                   e.g. deltaT = 0 or deltaT = 0.25 (6h)
%       Time:       if deltaT~=0, it defines the timerange.
%                   It must be a cell array (with 2 elements if deltaT~=0). 
%                   Format: 'dd-mmm-yyyy HH'
%                   e.g. Time = {'01-Sep-2007' ...}
%       Depthrange: provide depth range in meters.
%                   It must be an array with 1 or 2 elements.
%                   e.g. Depthrange = [0 700]
%       Latrange:   provide transect's latitude range in degN.
%                   It must be an array with 1 or 2 elements.
%                   e.g. Latrange = [69 72]
%       Latrange:   provide transect's longitude range in degE.
%                   It must be an array with 1 or 2 elements.
%                   e.g. Lonrange = [-22 -13]
%       plotmap:    0: don't plot a map with the requested area
%                   1: plot a map with the requested area
%                   'filename': save map with the requested area to filename.eps
%       savemat:    Leave it empty if you don't want to save the output.
%                   If 'filename' is provided, filename.mat will be saved
%	plotmean:   0: don't plot the mean vertical sections
%		    1: plot the mean vertical sections
%		    'filename': save requested vertical sections to filename_Field.eps
%       savemovie:  Leave it empty if you don't want to save movies (loop over time). 
%                   If 'filename' is provided, filename_Field.mat will be saved
%
% OUTPUT:
%       VSVEL: structure array containing velocities.
%                 e.g. VERTSECS.OrtVel.values
%			    	       bathy
%                                      dimensions
%                                      LON
%                                      LAT
%                                      DIST
%                                      TIME
%				       DEPTH
%                                      units
%                                      long_name
%

	% Set global variables 
        run set_globalvars

	% Check inputs
        checkFields        = {'OrtVel' 'TanVel'};
        if ~iscell(Fields) | isempty(Fields)
                error('Error.\nFields must be a cell array with at least one element',1)
        elseif ~all(ismember(Fields,checkFields))
                error('Error.\nField [%s] not available',Fields{min(find(~ismember(Fields,checkFields)==1))})
        elseif ~iscell(Time) | isempty(Time)
                error('Error.\nTime must be a cell array with at least one element',1)
        elseif deltaT~=0 & length(Time)~=2
                error('Error.\nIf deltaT is not 0, Time defines the timerange and its size must be 2',1)
        elseif rem(deltaT,infonc.deltaT)~=0
                error('Error.\ndeltaT must be a multiple of [%1.2f]',infonc.deltaT)
	elseif length(Latrange) > 2 | isempty(Latrange)
                error('Error.\nLatrange must contain 1 or 2 elements',1)
        elseif length(Lonrange) > 2 | isempty(Lonrange)
                error('Error.\nLonrange must contain 1 or 2 elements',1)        
        elseif length(Depthrange) > 2 | isempty(Depthrange)
                error('Error.\nDepthrange must contain 1 or 2 elements',1)
	elseif ~ischar(plotmap) & all(plotmap~=[0 1])
                error('Error.\nplotmap must be 0(No) or 1(Yes). Otherwise, provide a string to save the figure',1)
        elseif ~isempty(savemat) & ~ischar(savemat)
                error('Error.\nLeave savemat empty if you do not want to save outputs. Otherwise, provide a string',1)
	elseif isempty(plotmean) | (~ischar(plotmean) & all(plotmean~=[0 1]))
                error('Error.\nplotmean must be 0(No) or 1(Yes). Otherwise, provide a string to save the figure',1)
        elseif ~isempty(savemovie) & ~ischar(savemovie)
                error('Error.\nLeave savemovie empty if you do not want to save the movie. Otherwise, provide a string',1)
	end


	% Read fields
	FieldsVS    = {'U' 'V'};
        savematVS   = [];
	plotmeanVS  = [0];
	savemovieVS = [];
	[VERTSECS]  = create_VerticalSection(FieldsVS,Time,deltaT,Depthrange,Latrange,Lonrange,...
                                                    plotmap,savematVS,plotmeanVS,savemovieVS);

	% Read dimensions
	fieldname = FieldsVS{1};
	LON   = VERTSECS.(fieldname).('LON');
	LAT   = VERTSECS.(fieldname).('LAT');
	DIST  = VERTSECS.(fieldname).('DIST');
	DEPTH = VERTSECS.(fieldname).('DEPTH');
	TIME  = VERTSECS.(fieldname).('TIME');

	% Create orthogonal/tangential velocities
	fprintf(logID,'\n Creating velocities through the transect:');
	tic
	if length(DIST)<2
		error('Error.\nThis is a station, not a transect',1)
	elseif LAT(1) == LAT(end)
		% Zonal transect
		if any(strcmp('OrtVel',Fields))
			VSVEL.('OrtVel') = VERTSECS.('V');
		end
		if any(strcmp('TanVel',Fields))
			VSVEL.('TanVel') = VERTSECS.('U');
		end
		clear VERTSECS
	elseif LON(1) == LON(end)
		% Meridional transect
		if any(strcmp('OrtVel',Fields))
                	VSVEL.('OrtVel') = VERTSECS.('U');
		end
		if any(strcmp('TanVel',Fields))
                	VSVEL.('TanVel') = VERTSECS.('V');
		end
		clear VERTSECS
	else
		VelMag = sqrt(VERTSECS.('U').values.^2 + VERTSECS.('V').values.^2);
		ang = atan2d(VERTSECS.('V').values,VERTSECS.('U').values);
		ang(ang<0)=360+ang(ang<0);
		azi = azimuth(LAT(1),LON(1),LAT(end),LON(end)) - 90;
		ang = ang + azi;	
		if any(strcmp('OrtVel',Fields))
			VSVEL.('OrtVel')        = VERTSECS.('U');
                        VSVEL.('OrtVel').values = VelMag .* sind(ang);
                end
                if any(strcmp('TanVel',Fields))
			VSVEL.('TanVel')        = VERTSECS.('U');
                        VSVEL.('TanVel').values = VelMag .* cosd(ang);
                end
                clear VERTSECS
	end	
	
	if any(strcmp('OrtVel',Fields))
		VSVEL.('OrtVel').('long_name') = 'Velocity orthogonal to the section'; 
	end
	if any(strcmp('TanVel',Fields))
		VSVEL.('TanVel').('long_name') = 'Velocity tangential to the section';
	end
	fprintf(logID,' done in %f seconds\n',toc);
	
	% Save velocities
        tic
        if ~isempty(savemat)
                sz = whos('VSVEL');
                sz = sz.bytes * 1.e-9; % GB
                fprintf(logID,'\n Saving velocities to mat-file [%s.mat]',savemat);
                if round(sz)>=2
                        fprintf(logID,' using compression (v7.3)');
                        save(savemat,'VSVEL','-v7.3')
                else
                        save(savemat,'VSVEL')
                end
                % Timing
                fprintf(logID,': done in %f seconds\n',toc);
        end

        % Plot velocities
	plot_VerticalSection(Fields,VSVEL,plotmean,savemovie)


