function [FIELDS] = read_Fields(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,plotmap,savemat,interpC)
%
% ==================================
% AUTHOR: Mattia Almansi
% EMAIL: mattia.almansi@jhu.edu
% ==================================
%
% Read and store MITgcm output.
% Global variables are called by run set_globalvars
%
% INPUT:
%	Fields:	    cell array containing fields' names
%		    e.g. Fields = {'Temp' 'S' 'U' ...}
%	deltaT:     0 if Time defines every single time.
%		    Otherwise, set the timestep in days.
%		    e.g. deltaT = 0 or deltaT = 0.25 (6h)
%	Time:       if deltaT~=0, it defines the timerange.
%		    It must be a cell array (with 2 elements if deltaT~=0). 
%		    Format: 'dd-mmm-yyyy HH'
%		    e.g. Time = {'01-Sep-2007' ...}
%       Depthrange: provide depth range in meters.
%		    It must be an array with 1 or 2 elements.
%		    e.g. Depthrange = [0 700]
%       Latrange:   provide latitude range in degN.
%		    It must be an array with 1 or 2 elements.
%	    	    e.g. Latrange = [69 72]
%       Latrange:   provide longitude range in degE.
%                   It must be an array with 1 or 2 elements.
%                   e.g. Lonrange = [-22 -13]
%       plotmap:    0: don't plot a map with the requested area
%		    1: plot a map with the requested area
%		    'filename': save map with the requested area to filename.eps
%       savemat:    Leave it empty if you don't want to save the output.
%		    If 'filename' is provided, filename.mat will be saved
%	interpC:    0: do NOT interpolate fields 
%                   1: interpolate fields onto the C grid
%
% OUTPUT:
%	FIELDS: structure array containing requested fields.
%		e.g. FIELDS.Temp.values
%    				 dimensions
%		           	 LON
%				 LAT
%                                DEPTH
%                                TIME
%                                units
%                                long_name
%                                mask
%                                bathy 
	
	% Set global variables and start timing
        tic
        run set_globalvars

	% Check inputs
	checkFields        = infonc.vars.NAME;
	checkFields{end+1} = 'Sigma0';
	checkFields{end+1} = 'N2';
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
	elseif length(Depthrange) > 2 | isempty(Depthrange)
                error('Error.\nDepthrange must contain 1 or 2 elements',1)
	elseif length(Latrange) > 2 | isempty(Latrange) 
		error('Error.\nLatrange must contain 1 or 2 elements',1)
	elseif length(Lonrange) > 2 | isempty(Lonrange)
                error('Error.\nLonrange must contain 1 or 2 elements',1)
	elseif ~ischar(plotmap) & all(plotmap~=[0 1])
		error('Error.\nplotmap must be 0(No) or 1(Yes). Otherwise, provide a string to save the figure',1)
	elseif ~isempty(savemat) & ~ischar(savemat) 
		error('Error.\nLeave savemat empty if you do not want to save outputs. Otherwise, provide a string',1)
	elseif all(interpC~=[0 1])
		error('Error.\ninterpC must be 0(No) or 1(Yes).',1)
	end


	if any(ismember(Fields,infonc.vars.CROPPED))
		cropped = 1;
		if ~all(ismember(Fields,infonc.vars.CROPPED))
			error('Error.\nRead cropped files separately',1)
		end
	else
		cropped = 0;
	end
	% Find interpolated coordinates
        [~,ind1]  = min(abs(min(Latrange)-grid.yc));
        [~,ind2]  = min(abs(max(Latrange)-grid.yc));
        interpLat = grid.yc(ind1:ind2);
        [~,ind1]  = min(abs(min(Lonrange)-grid.xc));
        [~,ind2]  = min(abs(max(Lonrange)-grid.xc));
        interpLon = grid.xc(ind1:ind2);
        clear ind1 ind2
		
	% Plot map
	if plotmap~=0 
		% Plot grid
		savefig = [];
		fig_reqarea = plot_Grid(savefig);
	
		lWidth = 3;
		mSize  = 3;
		ra1 = plotm([interpLat(1)   interpLat(1)  ],[interpLon(1)   interpLon(end)],'m-o','Linewidth',lWidth,'MarkerSize',mSize);
		ra2 = plotm([interpLat(end) interpLat(end)],[interpLon(1)   interpLon(end)],'m-o','Linewidth',lWidth,'MarkerSize',mSize);
		ra3 = plotm([interpLat(1)   interpLat(end)],[interpLon(1)   interpLon(1)  ],'m-o','Linewidth',lWidth,'MarkerSize',mSize);
		ra4 = plotm([interpLat(1)   interpLat(end)],[interpLon(end) interpLon(end)],'m-o','Linewidth',lWidth,'MarkerSize',mSize);
		legend([ra1],'Requested Area','Location','northwest')
		clear rLon rLat

		if ischar(plotmap)
			% Save figure
                	fprintf(logID,'\n Saving requested area map to [%s.eps]:',plotmap);
                	tic
                	print(plotmap,'-depsc2','-r300');
                	fprintf(logID,' done in %f seconds\n',toc);
		end

	end

	fprintf(logID,'\n Reading MITgcm outputs:');

	% Create time vector and find corresponding repository
	if deltaT > 0
		Times = [datenum(Time(1),'dd-mm-yyyy HH'):deltaT:datenum(Time(end),'dd-mm-yyyy HH')];
		if isempty(Times)
			error('Error.\nWrong time range',1);
		end
	else
		Times = datenum(Time,'dd-mm-yyyy HH');
	end

	if ~cropped
		startd = 1;
		for t = 1:length(Times)
			for d = startd:length(infonc.dirs.NAME)
				if Times(t)>= infonc.dirs.FIRSTDAY{d} & Times(t)<= infonc.dirs.LASTDAY{d}
					Dirs{t} = infonc.dirs.NAME{d};
					startd = d;
					break
				end
			end
		end
	else
		startd = 1;
                for t = 1:length(Times)
                        for d = startd:length(infonc.dirs.NAME)
                                if Times(t)>= infonc.dirs.FIRSTDAYcropped{d} & Times(t)<= infonc.dirs.LASTDAYcropped{d}
                                        Dirs{t} = infonc.dirs.NAME{d};
                                        startd = d;
                                        break
                                end
                        end
                end
	end
	clear t d startd

	% First loop is over fields
	for f = 1:length(Fields)
		fieldname  = Fields{f};
		fprintf(logID,'\n     Progress of [%s]:',fieldname);
		% Exception Sigma0 and N2
		if strcmp(Fields{f},'Sigma0')
			fieldname = 'Temp';
		elseif strcmp(Fields{f},'N2')
			fieldname = 'Temp';
		end		
		fieldind   = find(strcmp(fieldname,infonc.vars.NAME));
		fielddir   = infonc.vars.DIRECTORY{fieldind};
		fieldclass = infonc.vars.CLASS{fieldind};

		% Initialize progress
                perc = 0:10:100;
		
		% Second loop is over time
		findt1 = 0;
		for t = 1:length(Times)
			time = Times(t);
			if t==1 | ~strcmp(Dirs{t},Dirs{t-1}) | findt1==1
				ncpath = [infonc.mainpath Dirs{t} fielddir];
				ncdir  = dir([ncpath fieldclass '.*.nc']);
				ncpath = [ncpath ncdir.name];
				T      = ncread(ncpath,'T')./(60*60*24) + infonc.reftime; % matlab format
				if t==1
					fieldinfo = ncinfo(ncpath,fieldname);
					fielddims = fieldinfo.Dimensions;
					Dims = [];
					for d = 1:length(fielddims)
						switch fielddims(d).Name
							case {'T'}
							case {'Zmd000001' 'Zd000001'}
								Dims.('Z') = [];
							case {'Zmd000216'}
								inds  = ncread(ncpath,'diag_levels'); 
								Dims.('Z') = abs(grid.Z(inds));
							case {'Zld000216'}
								inds  = ncread(ncpath,'diag_levels');
                                                                Dims.('Z') = abs(grid.Zl(inds));
							case {'X'}
								inds = ncread(ncpath,fielddims(d).Name);
								Dims.('X') =  grid.xc(inds);
								mskX = 0;
							case {'Xp1'}
								inds = ncread(ncpath,fielddims(d).Name);
								Dims.('X') =  grid.xg(inds);
								mskX = 1;
							case {'Y'}
								inds = ncread(ncpath,fielddims(d).Name);
								Dims.('Y') =  grid.yc(inds);
								mskY = 0;
							case {'Yp1'}
								inds = ncread(ncpath,fielddims(d).Name);
								Dims.('Y') =  grid.yg(inds);
								mskY = 1;
							case {'Z' 'Zl'}
								Dims.('Z') =  abs(ncread(ncpath,fielddims(d).Name));
							otherwise
								fielddims(d).Name
						end
					end

					% Find indexes of the closest gridpoints
					if interpC
						[minLon,~] = max(find(Dims.X<=min(interpLon)));
						[maxLon,~] = min(find(Dims.X>=max(interpLon)));
						[minLat,~] = max(find(Dims.Y<=min(interpLat)));
                                        	[maxLat,~] = min(find(Dims.Y>=max(interpLat)));
						if minLon==maxLon
							if minLon~=1
								minLon = minLon - 1;
							end
							if maxLon~=length(Dims.X)
								maxLon = maxLon + 1;
							end
						end
						if minLat==maxLat
							if minLat~=1
                                                                minLat = minLat - 1;
                                                        end
                                                        if maxLat~=length(Dims.Y)
                                                                maxLat = maxLat + 1;
                                                        end
                                                end
					else
						[~,minLon] = min(abs(min(Lonrange) - Dims.X));
						[~,maxLon] = min(abs(max(Lonrange) - Dims.X));
						[~,minLat] = min(abs(min(Latrange) - Dims.Y));
                                                [~,maxLat] = min(abs(max(Latrange) - Dims.Y));
					end
					Xind = [minLon : maxLon];
					Yind = [minLat : maxLat];
                        		if any(strcmp('Z',fieldnames(Dims)))
                                		if ~isempty(Dims.Z)
							% Find indexes of the closest depth
							[~,minDpt] = min(abs(Dims.Z-min(Depthrange)));
                                        		[~,maxDpt] = min(abs(Dims.Z-max(Depthrange)));
							Zind  = [minDpt : maxDpt];
							Zmask = Zind;
                                		else
                                        		Zind = 1;
							Zmask = Zind;
                                		end
                        		else
                                		Zind  = [];
						Zmask = 1;
                        		end
					if isempty(Xind)
                                		error('Error.\nLongitude range not available',datestr(time))
					elseif isempty(Yind)
						error('Error.\nLatitude range not available',datestr(time))
					elseif isempty(Zind) & any(strcmp('Z',fieldnames(Dims)))
						error('Error.\nDepth range not available',datestr(time))
                        		end

					% Find bathy and mask
					Xbathy = Xind;
					Ybathy = Yind;
					Xbathy(Xbathy>size(grid.Depth,1)) = [];
					Ybathy(Ybathy>size(grid.Depth,2)) = [];
					bathy = grid.Depth(Xbathy,Ybathy);
					if mskX==0 & mskY==0
                                		msk  = grid.HFacC(Xind,Yind,Zmask);
                        		elseif mskX==1 & mskY==0
                                		msk  = grid.HFacW(Xind,Yind,Zmask);
                        		elseif mskX==0 & mskY==1
                                		msk  = grid.HFacS(Xind,Yind,Zmask);
					else
						msk = grid.HFacC(Xind,Yind,Zmask);
                        		end

					

					% Initialize field
					if ~isempty(Zind)
						field = nan(length(Xind),length(Yind),length(Zind),length(Times));
					else
						field = nan(length(Xind),length(Yind),1,length(Times));
					end

				end

				% Find time first index
				Tind1  = find(T==Times(t));
				t1 = t;
				if isempty(Tind1)
                                        error('Error.\nDay [%s] not available',datestr(Times(t1)));
                                end
			end
			
			% Find time last index
			if t~=length(Times) & find(T==Times(t+1)) == find(T==Times(t))+1 & strcmp(Dirs{t},Dirs{t+1})
				findt1 = 0;
				continue
			else
				Tind2 = find(T==Times(t));
				t2 = t;
				if isempty(Tind2)
                                	error('Error.\nDay [%s] not available',datestr(Times(t2)));
				end
				findt1 = 1;
			end
			
			% Read NetCDF
			if ~isempty(Zind)
				start = [Xind(1) Yind(1) Zind(1) Tind1];
				count = [Xind(end)-Xind(1)+1 Yind(end)-Yind(1)+1 Zind(end)-Zind(1)+1 Tind2-Tind1+1];
				if strcmp(Fields{f},'Sigma0')
                        		Temptmp            = ncread(ncpath,'Temp',start,count);
					Stmp               = ncread(ncpath,'S',start,count);
					field(:,:,:,t1:t2) = densjmd95(Stmp,Temptmp,zeros(size(Temptmp))) - 1000;
				elseif strcmp(Fields{f},'N2')
					if length(Zind)<2
						error('Error. \nN2 needs at least 2 depths',1);
					end
					% Use teos10
					Temptmp  = ncread(ncpath,'Temp',start,count);
                                        Stmp     = ncread(ncpath,'S',start,count);
					rhoNil   = 1027; % kg/m3
					g        = 9.8156; % m/s2
					p        = Dims.Z(Zind)*g*rhoNil * 1.e-4; % dbar
					N2tmp    = nan(size(Temptmp));
					LONStmp  = Dims.X(Xind); 
					LATStmp  = Dims.Y(Yind);
					Depthtmp = Dims.Z(Zind);
					for this4=1:size(N2tmp,4)
						for this2=1:size(N2tmp,2) 
							thisT             = squeeze(Temptmp(:,this2,:,this4));
							thisS             = squeeze(Stmp(:,this2,:,this4));
							[SA, in_ocean]    = gsw_SA_from_SP(thisS',p,LONStmp,LATStmp(this2));
							CT                = gsw_CT_from_pt(SA,thisT');
							[fieldtmp, p_mid] = gsw_Nsquared(SA,CT,p,LATStmp(this2));
							[LonOld,DepthOld] = ndgrid(LONStmp,(Depthtmp(1:end-1)+Depthtmp(2:end))/2);
							[LonNew,DepthNew] = ndgrid(LONStmp,Depthtmp);
							if length(LonNew)<2
								fieldtmp          = interpn(DepthOld,fieldtmp',DepthNew);
							else
								fieldtmp          = interpn(LonOld,DepthOld,fieldtmp',LonNew,DepthNew);
							end
							N2tmp(:,this2,:,this4) = fieldtmp;
						end
						field(:,:,:,t1:t2) = N2tmp;
					end
                		else
					field(:,:,:,t1:t2) = ncread(ncpath,fieldname,start,count);
				end
			else
				start = [Xind(1) Yind(1) Tind1];
                                count = [Xind(end)-Xind(1)+1 Yind(end)-Yind(1)+1 Tind2-Tind1+1];
				if strcmp(Fields{f},'Sigma0')
                                        Temptmp            = ncread(ncpath,'Temp',start,count);
                                        Stmp               = ncread(ncpath,'S',start,count);
                                        field(:,:,1,t1:t2) = densjmd95(Stmp,Temptmp,zeros(size(Temptmp))) - 1000;
				elseif strcmp(Fields{f},'N2')
					error('Error. \nN2 needs at least 2 depths',1);
				else
                                	field(:,:,1,t1:t2) = ncread(ncpath,fieldname,start,count);
				end
			end

			% Show progress
                        thisperc = ceil(t*10/length(Times))*10;
                        if any(thisperc==perc)
                                fprintf(logID,'  [%d]',thisperc);
                                perc(perc==thisperc) = [];
                        end
		end % time
		if interpC
                	mskrep = repmat(msk,1,1,1,size(field,4));
			field(mskrep==0) = NaN;
               	end

		% Interpolation
		lon   = Dims.X(Xind);
		lat   = Dims.Y(Yind);
		if any(strcmp('Z',fieldnames(Dims))) & ~isempty(Dims.Z)
			depth = Dims.Z(Zind);
		else
			depth = [];
		end
		time  = Times;

		[LON,LAT,DEPTH,TIME]     = ndgrid(lon,lat,depth,time);
		[iLON,iLAT,iDEPTH,iTIME] = ndgrid(interpLon,interpLat,depth,time);
		
		if interpC
			fprintf(logID,'\n     Interpolating [%s] to C grid',Fields{f});
			if length(depth)<2 & length(time)<2
				[LON,LAT]   = ndgrid(lon,lat);
				[iLON,iLAT] = ndgrid(interpLon,interpLat);
				field       = interpn(LON,LAT,squeeze(field),iLON,iLAT);
				field       = reshape(field,size(field,1),size(field,2),1,1);
			elseif length(depth)<2
				[LON,LAT,TIME]    = ndgrid(lon,lat,time);
                                [iLON,iLAT,iTIME] = ndgrid(interpLon,interpLat,time);
                                field             = interpn(LON,LAT,TIME,squeeze(field),iLON,iLAT,iTIME);
				field             = reshape(field,size(field,1),size(field,2),1,size(field,3));
			elseif length(time)<2
				[LON,LAT,DEPTH]    = ndgrid(lon,lat,depth);
                                [iLON,iLAT,iDEPTH] = ndgrid(interpLon,interpLat,depth);
				field              = interpn(LON,LAT,DEPTH,squeeze(field),iLON,iLAT,iDEPTH);
				field              = reshape(field,size(field,1),size(field,2),size(field,3),1);
			else
				[LON,LAT,DEPTH,TIME]     = ndgrid(lon,lat,depth,time);
                                [iLON,iLAT,iDEPTH,iTIME] = ndgrid(interpLon,interpLat,depth,time);
                                field                    = interpn(LON,LAT,DEPTH,TIME,squeeze(field),iLON,iLAT,iDEPTH,iTIME);
                                field                    = reshape(field,size(field,1),size(field,2),size(field,3),size(field,4));
			end
			[LON,LAT]   = ndgrid(lon,lat);
			[iLON,iLAT] = ndgrid(interpLon,interpLat);
			bathy       = interpn(LON,LAT,squeeze(bathy),iLON,iLAT);	
			lon = interpLon;
			lat = interpLat;
			mskX = 0;
			mskY = 0;
		end
		
		% Fill info
		if strcmp(Fields{f},'Sigma0')
			fieldname = 'Sigma0';
		elseif strcmp(Fields{f},'N2')
			fieldname = 'N2';
		end
		FIELDS.(fieldname).('values')        = field;
		FIELDS.(fieldname).('dimensions')    = {'LON' 'LAT' 'DEPTH' 'TIME'};
		FIELDS.(fieldname).('LON')           = lon;
		FIELDS.(fieldname).('LAT')           = lat;
		FIELDS.(fieldname).('DEPTH')         = depth;
		FIELDS.(fieldname).('TIME')          = time;
		try
			FIELDS.(fieldname).('units') = ncreadatt(ncpath,fieldname,'units');
		catch
			if strcmp(Fields{f},'Sigma0')
				FIELDS.(fieldname).('units') = 'kg/m^3';
			elseif strcmp(Fields{f},'N2')
				FIELDS.(fieldname).('units') = '1/s^2';
			else
				FIELDS.(fieldname).('units') = infonc.vars.UNITS{fieldind};
			end
		end
		try
                        FIELDS.(fieldname).('long_name') = ncreadatt(ncpath,fieldname,'long_name');
                catch
			if strcmp(Fields{f},'Sigma0')
                                FIELDS.(fieldname).('long_name') = 'potential density anomaly';
			elseif strcmp(Fields{f},'N2')
				FIELDS.(fieldname).('long_name') = 'Brunt-Vaisala Frequency';
                        else
                        	FIELDS.(fieldname).('long_name') = infonc.vars.DESCRIPTION{fieldind};
			end
                end
		if ~interpC 
			FIELDS.(fieldname).('mask')  = msk;
			FIELDS.(fieldname).('bathy') = interpn(grid.xc,grid.yc,grid.Depth,Dims.X(Xind),Dims.Y(Yind));
		else
			FIELDS.(fieldname).('bathy') = bathy;
		end
		% Reshape dimensions
		FIELDS.(fieldname).('LON')   = reshape(FIELDS.(fieldname).('LON'),length(FIELDS.(fieldname).('LON')),1);
		FIELDS.(fieldname).('LAT')   = reshape(FIELDS.(fieldname).('LAT'),length(FIELDS.(fieldname).('LAT')),1);
		if ~isempty(FIELDS.(fieldname).('DEPTH'))
			FIELDS.(fieldname).('DEPTH') = reshape(FIELDS.(fieldname).('DEPTH'),length(FIELDS.(fieldname).('DEPTH')),1);
		end
		FIELDS.(fieldname).('TIME')  = reshape(FIELDS.(fieldname).('TIME'),length(FIELDS.(fieldname).('TIME')),1);
	end % fields	
	% Timing
	if interpC
		fprintf(logID,'\n MITgcm outputs read and interpolated in %f seconds\n',toc);
	else
		fprintf(logID,'\n MITgcm outputs read in %f seconds\n',toc);
	end

	% Save fields
	tic
	if ~isempty(savemat)
		sz = whos('FIELDS');
		sz = sz.bytes * 1.e-9; % GB
		fprintf(logID,'\n Saving variables to mat-file [%s.mat]',savemat);
		if round(sz)>=2
			fprintf(logID,' using compression (v7.3)');
			save(savemat,'FIELDS','-v7.3')
		else
			save(savemat,'FIELDS')
		end
		% Timing
        	fprintf(logID,': done in %f seconds\n',toc);
	end
