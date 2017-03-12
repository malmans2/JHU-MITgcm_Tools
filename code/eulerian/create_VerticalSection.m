function [VERTSECS] = create_VerticalSection(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,plotmap,savemat,plotmean,savemovie)
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
%	plotmean:   0: don't plot the mean vertica sections
%		    1: plot the mean vertical sections
%		    'filename': save requested vertical sections to filename_Field.eps
%       savemovie:  Leave it empty if you don't want to save movies (loop over time). 
%                   If 'filename' is provided, filename_Field.mat will be saved
%
% OUTPUT:
%       VERTSECS: structure array containing vertical sections.
%                 e.g. VERTSECS.Temp.values
%			    	     bathy
%                                    dimensions
%                                    LON
%                                    LAT
%                                    DIST
%                                    TIME
%				     DEPTH
%                                    units
%                                    long_name
%

	% Set global variables 
        run set_globalvars

	% Check inputs
        checkFields        = infonc.vars.NAME;
        checkFields{end+1} = 'Sigma0';
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
        plotmapFLD   = 0;
        savefields   = [];
	interpC      = 1;
        [FIELDS] = read_Fields(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,plotmapFLD,savefields,interpC);

	% Read dimensions
	fieldname = Fields{1};
	lat       = FIELDS.(fieldname).('LAT');
	lon       = FIELDS.(fieldname).('LON');
	


	% Plot map
        if plotmap~=0
                % Plot grid
                save_figgrid = [];
                fig_reqtransect = plot_Grid(save_figgrid);

                % Plot requested section
                lWidth = 3;
                mSize  = 3;
		[~,x1]  = min(abs(Lonrange(1)-grid.xc));
		[~,x2]  = min(abs(Lonrange(end)-grid.xc));
		[~,y1]  = min(abs(Latrange(1)-grid.yc));
		[~,y2]  = min(abs(Latrange(end)-grid.yc));
		x1 = grid.xc(x1);
		x2 = grid.xc(x2);
		y1 = grid.yc(y1);
                y2 = grid.yc(y2);
                rt1 = plotm([y1 y2],[x1 x2],'m-o','Linewidth',lWidth,'Markersize',3);
                legend([rt1],'Requested Transect','Location','northwest')
                clear y1 y1 x1 x2

                if ischar(plotmap)
                        % Save figure
                        fprintf(logID,'\n Saving requested transect map to [%s.eps]:',plotmap);
                        tic
                        print(plotmap,'-depsc2','-r300');
                        fprintf(logID,' done in %f seconds\n',toc);
                end
        end

	% Create transect (if not zonal/vertical)
	if length(lat)>=2 & length(lon)>=2 
		if Lonrange(1) < Lonrange(end)
			x1 = min(lon); 
			x2 = max(lon);
		else
			x1 = max(lon);
			x2 = min(lon);
		end
		if Latrange(1) < Latrange(end)
                        y1 = min(lat);   
                        y2 = max(lat);
                else
                        y1 = max(lat);
                        y2 = min(lat);
                end

		% Create transect
		coefficients = polyfit([x1, x2], [y1, y2], 1);
        	a = coefficients (1);
        	b = coefficients (2);

		if length(lon) > length(lat)
			ilon = lon;
			ilat = sort(a*ilon +b); 
		else
			ilat = lat;
			ilon = sort((lat - b)/a);
		end

		% Interpolate
		fprintf(logID,'\n Interpolating to create transect:',fieldname);
		tic
		for f=1:length(Fields)
			fieldname = Fields{f};
			fprintf(logID,' [%s]',fieldname);
			tic
			depth     = FIELDS.(fieldname).('DEPTH');
			time      = FIELDS.(fieldname).('TIME');
			if length(depth)<2 & length(time)<2
				[LON,LAT]   = ndgrid(lon,lat);
				[iLON,iLAT] = ndgrid(ilon,ilat);
				FIELDS.(fieldname).('values') = interpn(LON,LAT,squeeze(FIELDS.(fieldname).('values')),iLON,iLAT);
				FIELDS.(fieldname).('values') = reshape(FIELDS.(fieldname).('values'),length(ilon),length(ilat),1,1);
			elseif length(depth)<2
				[LON,LAT,TIME]    = ndgrid(lon,lat,time);
                                [iLON,iLAT,iTIME] = ndgrid(ilon,ilat,time);
				FIELDS.(fieldname).('values') = interpn(LON,LAT,TIME,squeeze(FIELDS.(fieldname).('values')),iLON,iLAT,iTIME);
                                FIELDS.(fieldname).('values') = reshape(FIELDS.(fieldname).('values'),length(ilon),length(ilat),1,length(time));
			elseif length(time)<2
				[LON,LAT,DEPTH]    = ndgrid(lon,lat,depth);
                                [iLON,iLAT,iDEPTH] = ndgrid(ilon,ilat,depth);
				FIELDS.(fieldname).('values') = interpn(LON,LAT,DEPTH,squeeze(FIELDS.(fieldname).('values')),iLON,iLAT,iDEPTH);
                                FIELDS.(fieldname).('values') = reshape(FIELDS.(fieldname).('values'),length(ilon),length(ilat),length(depth),1);
			else
				[LON,LAT,DEPTH,TIME]     = ndgrid(lon,lat,depth,time);
                                [iLON,iLAT,iDEPTH,iTIME] = ndgrid(ilon,ilat,depth,time);
				FIELDS.(fieldname).('values') = interpn(LON,LAT,DEPTH,TIME,squeeze(FIELDS.(fieldname).('values')),iLON,iLAT,iDEPTH,iTIME);
                                FIELDS.(fieldname).('values') = reshape(FIELDS.(fieldname).('values'),length(ilon),length(ilat),length(depth),length(time));
			end 
			[LON,LAT]   = ndgrid(lon,lat);
			[iLON,iLAT] = ndgrid(ilon,ilat);
			FIELDS.(fieldname).('bathy') = interpn(LON,LAT,squeeze(FIELDS.(fieldname).('bathy')),iLON,iLAT);
			FIELDS.(fieldname).('LAT') = ilat;
			FIELDS.(fieldname).('LON') = ilon;
			
			% Pick transect points
                	[Lonrange,srt] = sort(Lonrange);
                	Latrange = Latrange(srt);

                	lonind = 1:length(ilon);
                	if Latrange(1)<Latrange(end)
                	        latind = 1:length(ilat);
                	else
                	        latind = length(ilat):-1:1;
                	end


                	for l = 1:length(ilon)
                        	thisstat = squeeze(FIELDS.(fieldname).('values')(lonind(l),latind(l),:,:));
				if ~isempty(depth)
                        		thisstat = reshape(thisstat,1,length(depth),length(time));
				else
					thisstat = reshape(thisstat,1,1,length(time));
				end
                        	VERTSECS.(fieldname).('values')(l,:,:) = thisstat;
                        	VERTSECS.(fieldname).('bathy')(l,:,:) = FIELDS.(fieldname).('bathy')(lonind(l),latind(l));
                	end
			if ~isempty(depth)
                		VERTSECS.(fieldname).('values')     = reshape(VERTSECS.(fieldname).('values'),length(ilon),length(depth),length(time));
			else
				VERTSECS.(fieldname).('values')     = reshape(VERTSECS.(fieldname).('values'),length(ilon),1,length(time));
			end
			VERTSECS.(fieldname).('LON')        = ilon;
                	VERTSECS.(fieldname).('LAT')        = ilat(latind);
                	VERTSECS.(fieldname).('DEPTH')      = depth;
                	VERTSECS.(fieldname).('TIME')       = time;
			VERTSECS.(fieldname).('dimensions') = {'DIST' 'DEPTH' 'TIME'};    
			VERTSECS.(fieldname).('units')      = FIELDS.(fieldname).('units');
			VERTSECS.(fieldname).('long_name')  = FIELDS.(fieldname).('long_name');
			LAT  = VERTSECS.(fieldname).('LAT');
			LON  = VERTSECS.(fieldname).('LON');
			VERTSECS.(fieldname).('DIST')       = deg2km(distance(LAT(1),LON(1),LAT,LON));
		end
		fprintf(logID,'\n Interpolation done in %f seconds\n',toc);
	elseif length(lat)<2 & length(lon)>=2
		fprintf(logID,'\n Meridional transect: interpolation is NOT needed\n');
		for f=1:length(Fields)
                        fieldname                           = Fields{f};
			VERTSECS.(fieldname)                = FIELDS.(fieldname);
			VERTSECS.(fieldname).('LAT')        = repmat(VERTSECS.(fieldname).('LAT'),size(VERTSECS.(fieldname).('LON')));
			VERTSECS.(fieldname).('dimensions') = {'DIST' 'DEPTH' 'TIME'};
			LAT  = VERTSECS.(fieldname).('LAT');
                        LON  = VERTSECS.(fieldname).('LON');
                        VERTSECS.(fieldname).('DIST')       = deg2km(distance(LAT(1),LON(1),LAT,LON));
			sz1 = length(VERTSECS.(fieldname).('DIST'));
			if ~isempty(VERTSECS.(fieldname).('DEPTH'))
				sz2 = length(VERTSECS.(fieldname).('DEPTH'));
			else
				sz2 = 1;
			end
			sz3 = length(VERTSECS.(fieldname).('TIME'));
			sz  = [sz1,sz2,sz3];
			VERTSECS.(fieldname).('values')     = reshape(VERTSECS.(fieldname).('values'),sz);
		end
	elseif length(lon)<2 & length(lat)>=2
		fprintf(logID,'\n Zonal transect: interpolation is NOT needed\n');
		for f=1:length(Fields)
			fieldname                           = Fields{f};
                        VERTSECS.(fieldname)                = FIELDS.(fieldname);
                        VERTSECS.(fieldname).('LON')        = repmat(VERTSECS.(fieldname).('LON'),size(VERTSECS.(fieldname).('LAT')));
			VERTSECS.(fieldname).('dimensions') = {'DIST' 'DEPTH' 'TIME'};
			LAT  = VERTSECS.(fieldname).('LAT');
                        LON  = VERTSECS.(fieldname).('LON');
                        VERTSECS.(fieldname).('DIST')       = deg2km(distance(LAT(1),LON(1),LAT,LON));
                        sz1 = length(VERTSECS.(fieldname).('DIST'));
			if ~isempty(VERTSECS.(fieldname).('DEPTH'))
                                sz2 = length(VERTSECS.(fieldname).('DEPTH'));
                        else
                                sz2 = 1;
                        end
			sz3 = length(VERTSECS.(fieldname).('TIME'));
			sz  = [sz1,sz2,sz3];
			VERTSECS.(fieldname).('values')     = reshape(VERTSECS.(fieldname).('values'),sz);
                end
	else
		fprintf(logID,'\n Station: interpolation is NOT needed\n');
		for f=1:length(Fields)
                        fieldname                           = Fields{f};
                        VERTSECS.(fieldname)                = FIELDS.(fieldname);
			VERTSECS.(fieldname).('dimensions') = {'DIST' 'DEPTH' 'TIME'};
			LAT  = VERTSECS.(fieldname).('LAT');
                        LON  = VERTSECS.(fieldname).('LON');
                        VERTSECS.(fieldname).('DIST')       = deg2km(distance(LAT(1),LON(1),LAT,LON));
			sz1 = length(VERTSECS.(fieldname).('DIST'));
                        if ~isempty(VERTSECS.(fieldname).('DEPTH'))
                                sz2 = length(VERTSECS.(fieldname).('DEPTH'));
                        else
                                sz2 = 1;
                        end
			sz3 = length(VERTSECS.(fieldname).('TIME'));
			sz  = [sz1,sz2,sz3];
			VERTSECS.(fieldname).('values')     = reshape(VERTSECS.(fieldname).('values'),sz);
                end
	end		
		
 	% Save vertical sections
        tic
        if ~isempty(savemat)
                sz = whos('VERTSECS');
                sz = sz.bytes * 1.e-9; % GB
                fprintf(logID,'\n Saving vertical sections to mat-file [%s.mat]',savemat);
                if round(sz)>=2
                        fprintf(logID,' using compression (v7.3)');
                        save(savemat,'VERTSECS','-v7.3')
                else
                        save(savemat,'VERTSECS')
                end
                % Timing
                fprintf(logID,': done in %f seconds\n',toc);
        end
	
	% Plot
	plot_VerticalSection(Fields,VERTSECS,plotmean,savemovie)
