function [HEATBDG] = compute_HeatBudget(Time,deltaT,Depthrange,Latrange,Lonrange,plotmap,savemat);

	%
	% ==================================
	% AUTHOR: Mattia Almansi
	% EMAIL: mattia.almansi@jhu.edu
	% ==================================
	%
	% Compute variables for heat budget evaluation
	%
	% INPUT:
	%	Time:       if deltaT~=0, it defines the timerange.
	%		    It must be a cell array (with 2 elements if deltaT~=0). 
	%		    Format: 'dd-mmm-yyyy HH'
	%		    e.g. Time = {'01-Sep-2007 12' ...}
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
        %       FIELDS: structure array containing budget terms.
        %               e.g. SLTBDG.tendH
        %                           adv_hConvH
        %                           adv_vConvH
        %                           dif_vConvH
        %                           kpp_vConvH
        %                           forcH


	% Set global variables
	run set_globalvars

	% Need to read from the surface
	oldDepthrange = Depthrange;
	Depthrange(Depthrange==min(Depthrange)) = 0;

	% Averaged fields
	Fields     = {'TFLUX' 'oceQsw_AVG' 'ADVr_TH' 'ADVx_TH' 'ADVy_TH' 'DFrI_TH' 'KPPg_TH'};
	av_plotmap = [0];
	av_savemat = [];
	av_interpC = [0];
	[AVG] = read_Fields(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,av_plotmap,av_savemat,av_interpC);

	% Snapshots
	Fields     = {'Eta' 'Temp'};
	ss_plotmap = [0];
	ss_savemat = [];
        ss_interpC = [0];
	Loninds    = find(grid.xc>=AVG.TFLUX.LON(1) & grid.xc<=AVG.TFLUX.LON(end));
	Latinds    = find(grid.yc>=AVG.TFLUX.LAT(1) & grid.yc<=AVG.TFLUX.LAT(end));
	Depthinds  = find(abs(grid.RC)>=AVG.ADVx_TH.DEPTH(1) & abs(grid.RC)<=AVG.ADVx_TH.DEPTH(end));
	Lonrange   = grid.xc([Loninds(1)   Loninds(end)]);
	Latrange   = grid.yc([Latinds(1)   Latinds(end)]);
	Depthrange = abs(grid.RC([Depthinds(1) Depthinds(end)]));
	if deltaT==infonc.deltaT
		Time{1} = datestr(datenum(Time{1},'dd-mmm-yyyy HH')-infonc.deltaT,'dd-mmm-yyyy HH');
		[SS1] = read_Fields(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,plotmap,ss_savemat,ss_interpC); 
		[SS2] = [SS1];
		for fld=1:length(Fields)
			thisField = Fields{fld};
			SS1.(thisField).values(:,:,:,end) = [];
			SS1.(thisField).TIME(:,:,:,end)   = [];
			SS2.(thisField).values(:,:,:,1) = [];
                	SS2.(thisField).TIME(:,:,:,1)   = [];
		end
	else
		Time1      = cellstr(datestr(datenum(Time,'dd-mmm-yyyy HH')-infonc.deltaT,'dd-mmm-yyyy HH'));
		Time2      = Time;
		[SS1] = read_Fields(Fields,Time1,deltaT,Depthrange,Latrange,Lonrange,plotmap,savemat,interpC);
		[SS2] = read_Fields(Fields,Time2,deltaT,Depthrange,Latrange,Lonrange,ss_plotmap,ss_savemat,ss_interpC);
	end

	fprintf(logID,'\n Computing heat budget terms:');
	tic
	% Time + Parameters
	TIME = AVG.TFLUX.TIME;
	dt   = infonc.deltaT*60*60*24;
	rho0 = infonc.rho0;

	% Grid
	XC    = grid.xc(Loninds);
	YC    = grid.yc(Latinds);
	RC    = grid.RC(Depthinds);
	RF    = grid.RF([Depthinds;Depthinds(end)+1]);
	Depth = grid.Depth(Loninds,Latinds);
	RAC   = grid.rA(Loninds,Latinds);
	DRF   = grid.drF(Depthinds);
	hFacC = grid.HFacC(Loninds,Latinds,Depthinds);
	mskC  = hFacC; mskC(mskC==0)=NaN; mskC(mskC>0)=1;
	xLevs = length(Loninds);
	yLevs = length(Latinds);
	zLevs = length(Depthinds);

	% Make 3D fields
	Depth3D     = repmat(Depth,[1 1 zLevs]);
	RAC3D       = repmat(RAC,[1 1 zLevs]);
	DRF3D       = repmat(reshape(DRF,[1 1 zLevs]),[xLevs yLevs 1]);

	% Initialize fields
	oldind = min(find(abs(RC)>=min(oldDepthrange)));
	sltbdgFields = {'tendH' 'adv_hConvH' 'adv_vConvH' 'dif_vConvH' 'kpp_vConvH' 'forcH'};
	for fld = 1:length(sltbdgFields)
		thisField = sltbdgFields{fld};
		HEATBDG.(thisField) = [];
	end
	HEATBDG.('README') = 'Budget is closed if tendH=adv_hConvH+adv_vConvH+dif_vConvH+kpp_vConvH+forcH';
	HEATBDG.dimensions = ['LON' 'LAT' 'DEPTH' 'TIME'];
        HEATBDG.LON        = XC;
        HEATBDG.LAT        = YC;
        HEATBDG.TIME       = TIME;
        HEATBDG.DEPTH      = abs(RC(oldind:end-1));
        HEATBDG.units      = 'psu/s';
        HEATBDG.mask       = hFacC;
        HEATBDG.bathy      = Depth;
	
	% Compute budget terms
	for tt = 1:length(TIME)
		% SNAPSHOTS
		ETAN_SNAP  = cat(4,SS1.Eta.values(:,:,:,tt),SS2.Eta.values(:,:,:,tt));
		THETA_SNAP = cat(4,SS1.Temp.values(:,:,:,tt),SS2.Temp.values(:,:,:,tt));

		% AVERAGES
		TFLUX   = AVG.TFLUX.values(:,:,:,tt);
		ADVr_TH = AVG.ADVr_TH.values(:,:,:,tt);
		ADVx_TH = AVG.ADVx_TH.values(:,:,:,tt);
		ADVy_TH = AVG.ADVy_TH.values(:,:,:,tt);
		DFrI_TH = AVG.DFrI_TH.values(:,:,:,tt);
		oceQsw  = AVG.oceQsw_AVG.values(:,:,:,tt);
		KPPg_TH = AVG.KPPg_TH.values(:,:,:,tt);

		% Make 3D ETA
		ETAN_SNAP3D = repmat(ETAN_SNAP,[1 1 zLevs 1]);
	
		% Compute useful fields
		CellVol = RAC3D .* DRF3D .* hFacC;
		dzMat   = DRF3D .* hFacC;

		% total tendency
		HC_snap = 0*THETA_SNAP;
		for jj=1:2
        		HC_snap (:,:,:,jj) = THETA_SNAP(:,:,:,jj).*...
        				     (1+ETAN_SNAP3D(:,:,:,jj)./Depth3D);
		end
		tendS = (HC_snap(:,:,:,2)-HC_snap(:,:,:,1))/dt;

		% total tendency
		HC_snap = 0*THETA_SNAP;
		for jj=1:2
        		HC_snap(:,:,:,jj) = THETA_SNAP(:,:,:,jj).*...
        				    (1+ETAN_SNAP3D(:,:,:,jj)./Depth3D);
		end
		tendH = (HC_snap(:,:,:,2)-HC_snap(:,:,:,1))/dt;
		
		% horizontal divergence  
		adv_hConvH = -((ADVx_TH(2:end,:,:)-ADVx_TH(1:end-1,:,:))./CellVol +...
               		       (ADVy_TH(:,2:end,:)-ADVy_TH(:,1:end-1,:))./CellVol);

		% vertical divergences
		adv_vConvH = 0*tendH;
		dif_vConvH = 0*tendH;
		kpp_vConvH = 0*tendH;
		for nz = 1:zLevs,
			if nz < zLevs
        			nzp1 = nz+1;
        			adv_vConvH(:,:,nz) = squeeze(ADVr_TH(:,:,nzp1)*...
                        			     double(nz~=zLevs)-ADVr_TH(:,:,nz));
        			dif_vConvH(:,:,nz) = squeeze(DFrI_TH(:,:,nzp1)*...
                        			     double(nz~=zLevs)-DFrI_TH(:,:,nz));...
        			kpp_vConvH(:,:,nz) = squeeze(KPPg_TH(:,:,nzp1)*...
                        			     double(nz~=zLevs)-KPPg_TH(:,:,nz));
			else % can't estimate the last layer
                                adv_vConvH(:,:,nz) = NaN;
                                dif_vConvH(:,:,nz) = NaN;
                                kpp_vConvH(:,:,nz) = NaN;
                        end

		end
		adv_vConvH = adv_vConvH./CellVol;
		dif_vConvH = dif_vConvH./CellVol;
		kpp_vConvH = kpp_vConvH./CellVol;

		% surface heat flux (shortwave penetrates the top 200m
		% constants
		rho0c_p = infonc.rho0*infonc.c_p;
		R       = 0.62;
		zeta1   = 0.6;
		zeta2   = 20;
		q1      = (R  )*exp(1/zeta1*RF(1:end-1))+...
		          (1-R)*exp(1/zeta2*RF(1:end-1));
		q2      = (R  )*exp(1/zeta1*RF(2:end))+... 
          		  (1-R)*exp(1/zeta2*RF(2:end));
		
		% correction for the 200m cutoff
		zCut             = find(RC<-200,1)+1; % Add +1 otherwise layer 20 is wrong
		q1(zCut:zLevs)   = 0;
		q2(zCut-1:zLevs) = 0;

		% compute vertically penetrating flux
		forcH = 0*tendH;
		for nz=1:zLevs
        		if nz==1 
                		forcH(:,:,nz) = TFLUX(:,:,1) -...
                                		(1-(q1(nz)-q2(nz)))*oceQsw;
        		else
                		nzp1=min([nz+1,zLevs]);
                		forcH(:,:,nz) = forcH(:,:,nz) + ...
                                		((mskC(:,:,nz)==1).*q1(nz) -...
                                 		(mskC(:,:,nzp1)==1).*q2(nz)).*oceQsw;
        		end
		end
		forcH = mskC.*forcH./(rho0c_p*dzMat); 

		% fill outputs
		HEATBDG.tendH(:,:,:,tt)      = tendH(:,:,oldind:end-1);
		HEATBDG.adv_hConvH(:,:,:,tt) = adv_hConvH(:,:,oldind:end-1);
		HEATBDG.adv_vConvH(:,:,:,tt) = adv_vConvH(:,:,oldind:end-1);
		HEATBDG.dif_vConvH(:,:,:,tt) = dif_vConvH(:,:,oldind:end-1);
		HEATBDG.kpp_vConvH(:,:,:,tt) = kpp_vConvH(:,:,oldind:end-1);
		HEATBDG.forcH(:,:,:,tt)      = forcH(:,:,oldind:end-1);
	end
	fprintf(logID,' done in %f seconds\n',toc);

	% Save fields
	tic
	if ~isempty(savemat)
		sz = whos('HEATBDG');
		sz = sz.bytes * 1.e-9; % GB
		fprintf(logID,'\n Saving salt budget terms to mat-file [%s.mat]',savemat);
		if round(sz)>=2
			fprintf(logID,' using compression (v7.3)');
			save(savemat,'HEATBDG','-v7.3')
		else
			save(savemat,'HEATBDG')
		end
		% Timing
        	fprintf(logID,': done in %f seconds\n',toc);
	end
