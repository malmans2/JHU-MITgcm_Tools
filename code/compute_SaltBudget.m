function [SLTBDG] = compute_SaltBudget(Time,deltaT,Depthrange,Latrange,Lonrange,plotmap,savemat);
	
	%
        % ==================================
        % AUTHOR: Mattia Almansi
        % EMAIL: mattia.almansi@jhu.edu
        % ==================================
        %
        % Compute variables for salt budget evaluation
        %
        % INPUT:
        %       Time:       if deltaT~=0, it defines the timerange.
        %                   It must be a cell array (with 2 elements if deltaT~=0). 
        %                   Format: 'dd-mmm-yyyy HH'
        %                   e.g. Time = {'01-Sep-2007 12' ...}
        %       Depthrange: provide depth range in meters.
        %                   It must be an array with 1 or 2 elements.
        %                   e.g. Depthrange = [0 700]
        %       Latrange:   provide latitude range in degN.
        %                   It must be an array with 1 or 2 elements.
        %                   e.g. Latrange = [69 72]
        %       Latrange:   provide longitude range in degE.
        %                   It must be an array with 1 or 2 elements.
        %                   e.g. Lonrange = [-22 -13]
        %       plotmap:    0: don't plot a map with the requested area
        %                   1: plot a map with the requested area
        %                   'filename': save map with the requested area to filename.eps
        %       savemat:    Leave it empty if you don't want to save the output.
        %                   If 'filename' is provided, filename.mat will be saved
	% OUTPUT:
	%	FIELDS: structure array containing budget terms.
	%		e.g. SLTBDG.tendS
	%    			    adv_hConvS
	%		            adv_vConvS
	%			    dif_vConvS
	%                           kpp_vConvS
	%                           forcS


	% Set global variables
	run set_globalvars

	% Need to read from the surface
	oldDepthrange = Depthrange;
	Depthrange(Depthrange==min(Depthrange)) = 0;

	% Averaged fields
	Fields     = {'SFLUX' 'ADVr_SLT' 'ADVx_SLT' 'ADVy_SLT' 'DFrI_SLT' 'oceSPtnd' 'KPPg_SLT'};
	av_plotmap = [0];
	av_savemat = [];
	av_interpC = [0];
	[AVG] = read_Fields(Fields,Time,deltaT,Depthrange,Latrange,Lonrange,av_plotmap,av_savemat,av_interpC);

	% Snapshots
	Fields     = {'Eta' 'S'};
	ss_plotmap = [0];
	ss_savemat = [];
        ss_interpC = [0];
	Loninds    = find(grid.xc>=AVG.SFLUX.LON(1) & grid.xc<=AVG.SFLUX.LON(end));
	Latinds    = find(grid.yc>=AVG.SFLUX.LAT(1) & grid.yc<=AVG.SFLUX.LAT(end));
	Depthinds  = find(abs(grid.RC)>=AVG.ADVx_SLT.DEPTH(1) & abs(grid.RC)<=AVG.ADVx_SLT.DEPTH(end));
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

	fprintf(logID,'\n Computing salt budget terms:');
	tic
	% Time + Parameters
	TIME = AVG.SFLUX.TIME;
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
	sltbdgFields = {'tendS' 'adv_hConvS' 'adv_vConvS' 'dif_vConvS' 'kpp_vConvS' 'forcS'};
	for fld = 1:length(sltbdgFields)
		thisField = sltbdgFields{fld};
		SLTBDG.(thisField) = [];
	end
	SLTBDG.('README') = 'Budget is closed if tendS=adv_hConvS+adv_vConvS+dif_vConvS+kpp_vConvS+forcS';
	SLTBDG.dimensions = ['LON' 'LAT' 'DEPTH' 'TIME'];
        SLTBDG.LON        = XC;
        SLTBDG.LAT        = YC;
        SLTBDG.TIME       = TIME;
        SLTBDG.DEPTH      = abs(RC(oldind:end-1));
        SLTBDG.units      = 'psu/s';
        SLTBDG.mask       = hFacC;
        SLTBDG.bathy      = Depth;

	% Compute budget terms
	for tt = 1:length(TIME)
		% SNAPSHOTS
		ETAN_SNAP = cat(4,SS1.Eta.values(:,:,:,tt),SS2.Eta.values(:,:,:,tt));
		SALT_SNAP = cat(4,SS1.S.values(:,:,:,tt),SS2.S.values(:,:,:,tt));

		% AVERAGES
		SFLUX    = AVG.SFLUX.values(:,:,:,tt);
		ADVr_SLT = AVG.ADVr_SLT.values(:,:,:,tt);
		ADVx_SLT = AVG.ADVx_SLT.values(:,:,:,tt);
		ADVy_SLT = AVG.ADVy_SLT.values(:,:,:,tt);
		DFrI_SLT = AVG.DFrI_SLT.values(:,:,:,tt);
		oceSPtnd = AVG.oceSPtnd.values(:,:,:,tt);
		KPPg_SLT = AVG.KPPg_SLT.values(:,:,:,tt);

		% Make 3D ETA
		ETAN_SNAP3D = repmat(ETAN_SNAP,[1 1 zLevs 1]);
	
		% Compute useful fields
		CellVol = RAC3D .* DRF3D .* hFacC;
		dzMat   = DRF3D .* hFacC;

			% total tendency
		HC_snap = 0*SALT_SNAP;
		for jj=1:2
        		HC_snap (:,:,:,jj) = SALT_SNAP(:,:,:,jj).*...
        				     (1+ETAN_SNAP3D(:,:,:,jj)./Depth3D);
		end
		tendS = (HC_snap(:,:,:,2)-HC_snap(:,:,:,1))/dt;

		% horizontal divergence  
		adv_hConvS = -((ADVx_SLT(2:end,:,:)-ADVx_SLT(1:end-1,:,:))./CellVol +...
         		       (ADVy_SLT(:,2:end,:)-ADVy_SLT(:,1:end-1,:))./CellVol);

		% vertical divergences
		adv_vConvS = 0*tendS;
		dif_vConvS = 0*tendS;
		kpp_vConvS = 0*tendS;
		for nz = 1:zLevs,
			if nz<zLevs
        			nzp1 = nz+1;
        			adv_vConvS(:,:,nz) = squeeze(ADVr_SLT(:,:,nzp1)*...
                			             double(nz~=zLevs)-ADVr_SLT(:,:,nz));
        			dif_vConvS(:,:,nz) = squeeze(DFrI_SLT(:,:,nzp1)*...
        		        	             double(nz~=zLevs)-DFrI_SLT(:,:,nz));...
        			kpp_vConvS(:,:,nz) = squeeze(KPPg_SLT(:,:,nzp1)*...
                			             double(nz~=zLevs)-KPPg_SLT(:,:,nz));
			else % can't estimate the last layer
				adv_vConvS(:,:,nz) = NaN;
				dif_vConvS(:,:,nz) = NaN;
				kpp_vConvS(:,:,nz) = NaN;
			end
		end
		adv_vConvS = adv_vConvS./CellVol;
		dif_vConvS = dif_vConvS./CellVol;
		kpp_vConvS = kpp_vConvS./CellVol;

		% surface salt flux (salt plume penetrate vertically!)
		forcS = 0*tendS;
		for nz=1:zLevs
        		if nz==1
                		forcS(:,:,nz)=SFLUX/rho0;
        		end
        		forcS(:,:,nz)=forcS(:,:,nz)+oceSPtnd(:,:,nz)/rho0;
		end
		forcS = forcS./(dzMat);

		% fill outputs
		SLTBDG.tendS(:,:,:,tt)      = tendS(:,:,oldind:end-1);
		SLTBDG.adv_hConvS(:,:,:,tt) = adv_hConvS(:,:,oldind:end-1);
		SLTBDG.adv_vConvS(:,:,:,tt) = adv_vConvS(:,:,oldind:end-1);
		SLTBDG.dif_vConvS(:,:,:,tt) = dif_vConvS(:,:,oldind:end-1);
		SLTBDG.kpp_vConvS(:,:,:,tt) = kpp_vConvS(:,:,oldind:end-1);
		SLTBDG.forcS(:,:,:,tt)      = forcS(:,:,oldind:end-1);
	end
	fprintf(logID,' done in %f seconds\n',toc);

	% Save fields
	tic
	if ~isempty(savemat)
		sz = whos('SLTBDG');
		sz = sz.bytes * 1.e-9; % GB
		fprintf(logID,'\n Saving salt budget terms to mat-file [%s.mat]',savemat);
		if round(sz)>=2
			fprintf(logID,' using compression (v7.3)');
			save(savemat,'SLTBDG','-v7.3')
		else
			save(savemat,'SLTBDG')
		end
		% Timing
        	fprintf(logID,': done in %f seconds\n',toc);
	end
