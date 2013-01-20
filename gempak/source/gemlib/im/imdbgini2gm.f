	SUBROUTINE IM_DBGINI2GM  ( imgfil, ignhdr, rnvblk, iret )
C************************************************************************
C* IM_DBGINI2GM								*
C*									*
C* This subroutine reads the header information from a AWIPS II GINI 	*
C* image and sets the navigation					*
C*									*
C* IM_DBGINI2GM  ( IMGFIL, IGNHDR, RNVBLK, IRET )			*
C*									*
C* Input parameters:							*
C*	IMGFIL		CHAR*		Image file name			*
C*									*
C* Output parameters:							*
C*	IGNHDR (135)	INTEGER		GINI header array		*
C*	RNVBLK (LLNNAV) REAL            Navigation block		*
C*	IRET		INTEGER		Return code			*
C*					  0 = normal return		*
C*					 -2 = Error opening/reading file*
C*					 -3 = Invalid image file format	*
C*					 -4 = Invalid image file header	*
C*					 -5 = Invalid image navigation	*
C**									*
C* Log:									*
C* m.gamazaychikov/CWS		08/09	Created				*
C************************************************************************
	INCLUDE		'GEMPRM.PRM'
	INCLUDE		'IMGDEF.CMN'
C*
	CHARACTER*(*)	imgfil
	INTEGER		ignhdr (*)
	REAL		rnvblk (*)	
C*
	CHARACTER	proj*3
C
C* new stuff
C
        CHARACTER       dbhst*50, qtype*11, src*21, dbtag*15,
     +                  physelm*64, sectorid*64, sattime*12,
     +                  prmlist(10)*64, sathdr*1024, hdrlist(14)*60,
     +                  sat*20, channel*60, ttemp(2)*10, resolution*10
        DATA            src   /'GINI'/
        DATA            qtype /'satHdr'/
C------------------------------------------------------------------------
	iret = 0
	sign = 1.
	dangl1 = 90.
	imradf = 0
        nocc = 1

C
C*      Get the name of AWIPS IIdatabase host from prefs table
C
        CALL ST_NULL ( 'A2DB_HOST_NAME', dbtag, lens, ier )
        dbhst = ' '
        CALL CTB_PFSTR ( dbtag, dbhst, ier )
        CALL ST_UCLC ( dbhst, dbhst, ier )
        IF ( ier .ne. 0 ) THEN
           iret = -6
           RETURN
        END IF
        sathdr=" "
        resolution = " "
        cmbunt = " "
        cmcalb = " "
        CALL ST_NULL ( resolution, resolution, lenq, ier )
        CALL ST_NULL ( qtype, qtype, lenq, ier )
        CALL ST_NULL ( src, src, lenq, ier )
        CALL ST_NULL ( dbhst, dbhst, ldbhst, ier )
C
C*	Process the imgfil, and split the content into strings
C*      corresponding to columns in AWIPS II database table:
C*       - physelm 	- physical element
C*       - sectorid 	- sector ID
C*       - sattime 	- the time stamp of the image 
C
        CALL ST_NOCC ( imgfil, '|', nocc, ibar, ier)
        IF ( ier .eq. 0 ) THEN
           src = "GINI"
           nexp = 10
           CALL ST_CLSL (imgfil, '|', ' ', nexp, prmlist, nprm, ier)
           CALL ST_NULL ( prmlist(1), physelm, lenq, ier )
           CALL ST_NULL ( prmlist(2), sectorid, lenq, ier )
           CALL ST_NULL ( prmlist(3), sattime, lenq, ier )
        ELSE
           nexp = 10
           CALL ST_CLSL (imgfil, '/', ' ', nexp, prmlist, nprm, ier)
           CALL ST_NULL ( prmlist(2), physelm, lenq, ier )
           CALL ST_NULL ( prmlist(3), sectorid, lenq, ier )
           CALL ST_LSTR ( prmlist(4), lsttim, ier)
           nexp = 2
           CALL ST_CLSL ( prmlist(4)(:lsttim), '_', ' ',
     +                    nexp, ttemp, nt, ier )
           CALL ST_LSTR ( ttemp(1), ildate, ier )
           CALL ST_LSTR ( ttemp(2), iltime, ier )
           sattime = ttemp(1)(3:ildate) // '/' // ttemp(2)(:iltime)
           CALL ST_NULL ( sattime, sattime, lenq, ier )
        END IF

	CALL DB_GSATHDR  ( dbhst, qtype, src, physelm, sectorid, 
     +                     resolution, sattime, sathdr, lsathdr, ier )
        nexp = 14
        CALL ST_CLSL (sathdr(:lsathdr), ';', ' ', nexp, 
     +                hdrlist, nprm, ier)
	IF  ( ier .ne. 0 )  THEN
	    iret = -1
	    RETURN
	END IF
C
C*      Set the satellite number.
C*
C*	   Value       Sat
C*      -----------------------
C*           9       METEOSAT
C*          10       GOES-7
C*          11       GOES-8
C*          12       GOES-9
C*          13       GOES-10
C*          14       GOES-11
C*          15       GOES-12	
C*          16       GOES-13	
C
        sat = hdrlist(12)
        IF ( INDEX(sat,'METEOSAT') .gt. 0 ) THEN
             imsorc = 56
          ELSE IF ( INDEX(sat,'GOES-7') .gt. 0 ) THEN
	    imsorc = 32
          ELSE IF ( INDEX(sat,'GOES-8') .gt. 0 ) THEN
	    imsorc = 70
          ELSE IF ( INDEX(sat,'GOES-9') .gt. 0 ) THEN
	    imsorc = 72
          ELSE IF ( INDEX(sat,'GOES-10') .gt. 0 ) THEN
	    imsorc = 74
          ELSE IF ( INDEX(sat,'GOES-11') .gt. 0 ) THEN
	    imsorc = 76
          ELSE IF ( INDEX(sat,'GOES-12') .gt. 0 ) THEN
	    imsorc = 78
          ELSE IF ( INDEX(sat,'GOES-13') .gt. 0 ) THEN
	    imsorc = 180
	  ELSE
	    iret = -4
	    RETURN
	END IF	
C
C*	Set the channel number.
C*
C*	   Value      Channel
C*      --------------------------
C*          1       VIS
C*          2       3.9 micron (IR)
C*          3       6.7 micron (WV)
C*          4       11  micron (IR)
C*          5       12  micron (IR)
C*          6       derived #1	
C*          7       derived #2	
C*          8       derived #3	
C*          9       derived #4	
C
C*	  The following are new GOES Sounder images
C*          micron 14.06 = channel 43
C*          micron 11.03 = channel 48
C*          micron 7.43 = channel 50
C*          micron 7.02 = channel 51
C*          micron 6.51 = channel 52
C*          micron 4.45 = channel 55
C*          micron 3.98 = channel 57
C*          micron vis = channel 59
C
        CALL ST_UCLC( hdrlist(13), channel, ier ) 
        IF ( INDEX(channel,'vis') .gt. 0 ) THEN
	    imtype = 1
          ELSE IF ( INDEX(channel,'3.9') .gt. 0 ) THEN
	    imtype = 2
          ELSE IF ( INDEX(channel,'6.7') .gt. 0 ) THEN
	    imtype = 4 
          ELSE IF ( INDEX(channel,'11') .gt. 0 ) THEN
	    imtype = 8 
          ELSE IF ( INDEX(channel,'12') .gt. 0 ) THEN
	    imtype = 16 
          ELSE IF ( INDEX(channel,'14.06') .gt. 0 ) THEN
	    imtype = 43 
          ELSE IF ( INDEX(channel,'11.03') .gt. 0 ) THEN
	    imtype = 48 
          ELSE IF ( INDEX(channel,'7.43') .gt. 0 ) THEN
	    imtype = 50 
          ELSE IF ( INDEX(channel,'7.02') .gt. 0 ) THEN
	    imtype = 51 
          ELSE IF ( INDEX(channel,'6.51') .gt. 0 ) THEN
	    imtype = 52
          ELSE IF ( INDEX(channel,'4.45') .gt. 0 ) THEN
	    imtype = 55 
          ELSE IF ( INDEX(channel,'3.98') .gt. 0 ) THEN
	    imtype = 57 
          ELSE IF ( INDEX(channel,'micron vis') .gt. 0 ) THEN
	    imtype = 59 
	  ELSE
	    iret = -4
	    RETURN
	END IF
C
C*	Adjust the source and channel for some image types to conform
C*	to AREA file numbering.
C
C*	GOES-7
C
        IF ( INDEX(sat,'GOES-7') .gt. 0 .and. 
     +       INDEX(channel,'VIS') .lt. 0 ) THEN
            imsorc = 33
            IF ( INDEX(channel,'6.7') .gt. 0 ) imtype = 512
            IF ( INDEX(channel,'11')  .gt. 0 ) imtype = 128
C
C*	Meteosat
C
          ELSE IF ( INDEX(sat,'METEOSAT') .gt. 0 .and. 
     +             INDEX(channel,'VIS') .lt. 0 ) THEN
            IF ( INDEX(channel,'6.7') .gt. 0 ) imtype = 512
            IF ( INDEX(channel,'11')  .gt. 0 ) imtype = 128
        END IF
C
C*	Get the date and time.
C
        CALL ST_LSTR(hdrlist(14), lsttim, ier)
        nexp = 2
        CALL ST_CLSL (hdrlist(14)(:lsttim), '/', ' ',nexp,ttemp,nt,ier)
        CALL ST_NUMB(ttemp(1), imdate, ier)
        CALL ST_NUMB(ttemp(2), imtime, ier)
C
C*	Image size.  Set subset area to full image
C
	imdpth = 1
	imleft = 1
	imtop  = 1
        CALL ST_NUMB(hdrlist(2), imnpix, ier)
        CALL ST_NUMB(hdrlist(3), imnlin, ier)
	imrght = imnpix
	imbot  = imnlin
	rmxysc = 1.
C
C*	Determine data length
C
	imldat = imnlin * ( imnpix * imdpth )
C
C*	Verify that image scanning mode is left to right, top to bottom
C
        iscmod = 0
	IF ( iscmod .ne. 0 ) THEN
	    iret = -4
	    RETURN
	END IF
C
C*	Map projection type.
C*
C*       Value   Projection
C*     ---------------------
C*         1       Mercator
C*         3       Lambert
C*         5       Stereographic
C
        CALL ST_NUMB(hdrlist(1), imapty, ier)
	IF ( imapty .eq. 1 ) THEN
	    proj = 'MER'
	ELSE IF ( imapty .eq. 3 ) THEN
	    proj = 'LCC'
	ELSE IF ( imapty .eq. 5 ) THEN
	    proj = 'STR'
	ELSE
	    iret = -4
	    RETURN
	END IF
C
C*	Get navigation items used in all projections.
C*
C*	Get lat/lon of lower left point.
C
        CALL ST_NUMB(hdrlist(4), lat1, ier)
	rlat1 =	( lat1 / 10000. ) * DTR
C
        CALL ST_NUMB(hdrlist(6), lon1, ier)
	rlon1 =	( lon1 / 10000. ) * DTR
C
C*	std - lat at which cone or cylinder intersects earth.
C
        CALL ST_NUMB(hdrlist(8), latin, ier)
	std = latin / 10000.
C	
C*	Get items specific to each projection.
C
	IF ( proj .eq. 'LCC' .or. proj .eq. 'STR' ) THEN
C
C*	    Lov - orientation of the grid (center longitude).
C
            CALL ST_NUMB(hdrlist(9), lov, ier)
	    clon = lov / 10000.
	    CALL PRNLON ( 1, clon, ier )
	    cntlon = clon * DTR   
C
C*	    tdx and tdy direction grid increments.
C
            CALL ST_CRNM(hdrlist(10), tdx, ier)
            CALL ST_CRNM(hdrlist(11), tdy, ier)
C
C*	    Projection center flag (NP=0, SP=1). 
C*     //TODO - find out about the ipole!!!
C
            ipole = 0
	    IF ( ipole .eq. 1 ) THEN
		sign   = - 1.  
		dangl1 = - 90.
	    END IF
	ELSE 	    
C
            CALL ST_NUMB(hdrlist(5), lat2, ier)
	    rlat2 = ( lat2 / 10000. ) * DTR
            CALL ST_NUMB(hdrlist(7), lon2, ier)
C
C*	    Check for lon2 bug. Sign of lon2 was wrong in sample image
C
	    IF ( rlon1 .lt. 0 .and. lon2 .gt. 0 ) lon2 = - lon2
	    rlon2 =	( lon2 / 10000. ) * DTR
	END IF
C
C*	***************************
C*	*** Polar Stereographic ***
C*	***************************
C
	IF ( proj .eq. 'STR' ) THEN
C
C*	    Linear coordinates of lower left point. (1+sin 90) is
C*	    excluded.
C
	    x1 =   RADIUS * TAN ( PI4TH - sign * rlat1 / 2. ) *
     +	           SIN ( rlon1 - cntlon )
	    y1 = (-RADIUS) * TAN ( PI4TH - sign * rlat1 / 2. ) *
     +	           COS ( rlon1 - cntlon ) * sign
C
C*	    Compute grid spacing on the pole plane. (1+sin 90) is
C*	    also excluded.
C
	    dx = tdx / ( 1. + SIN ( PI / 3. ) )
	    dy = tdy / ( 1. + SIN ( PI / 3. ) )
C
C*	    Compute the linear coordinates of the upper right point.
C*	    Assumes left to right, top to bottom image scanning.
C
	    x2 = x1 + ( imnpix - 1 ) * dx
	    y2 = y1 + ( imnlin - 1 ) * dy * sign
C
C*	    Set lat/lon of upper right point and projection angles.
C
	    dlat2  = sign * ( HALFPI - 2. * ATAN2 ( SQRT ( ( x2 * x2 ) 
     +		     + ( y2 * y2 ) ), RADIUS ) ) * RTD
	    y2     = (-sign) * y2
	    dlon2  = ( cntlon + ATAN2 ( x2, y2 ) ) * RTD
	    CALL PRNLON ( 1, dlon2, ier ) 
C
C*          Set lat/lon of lower left point.
C
            dlat1 = lat1 / 10000.
            dlon1 = lon1 / 10000.
C
C*	    Set projection angles. Angle1 is set to be 90 or -90.
C
	    dangl2 = clon
	    dangl3 = 0.
C
	ELSE IF ( proj .eq. 'LCC' ) THEN
C
C*	    *************************
C*	    *** Lambert Conformal ***
C*	    *************************
C
C*	    Compute the constant of the tangent cone. 
C
	    psi    = HALFPI - ( ABS ( std ) * DTR )
	    ccone  = COS ( psi )
	    rearth = RADIUS / ccone
C
C*	    Compute the linear coordinate for the lower left grid point.
C*	    The auxiliary function is excluded. 
C
	    x1 =   rearth * ( TAN ( ( HALFPI - sign * rlat1 ) / 2. ) ** 
     +		   ccone ) * SIN ( ccone * ( rlon1 - cntlon ) )
	    y1 = (-rearth) * ( TAN ( ( HALFPI - sign * rlat1 ) / 2. ) ** 
     +		   ccone ) * COS ( ccone * ( rlon1 - cntlon ) ) * sign
C
C*	    Recompute grid spacing. Alpha is the constant term in the 
C*	    map scale factor.
C
	    alpha = SIN ( psi ) / ( TAN ( psi / 2. ) ** ccone ) 
	    dx    = tdx / alpha
	    dy    = tdy / alpha
C
C*	    Compute the linear coordinates for the upper right grid 
C*	    point.  Assumes left to right, top to bottom image scanning.
C
	    x2 = x1 + ( imnpix - 1 ) * dx
	    y2 = y1 + ( imnlin - 1 ) * dy * sign
C
C*	    Compute the lat/lon coordinates of the upper right point.
C
	    rlat2 = sign * ( HALFPI - 2. * ATAN ( ( SQRT ( ( x2 * x2 ) +
     +		    ( y2 * y2 ) ) / rearth ) ** ( 1. / ccone ) ) ) 
	    dlat2 = rlat2 * RTD
	    y2    = (-sign) * y2
	    rlon2 = cntlon + ATAN2 ( x2, y2 ) * ( 1. / ccone )
C
	    dlon2 = rlon2 * RTD
	    CALL PRNLON ( 1, dlon2, ier ) 
C
C*          Set the lat/lon coordinates of the lower left point.
C
            dlat1 = lat1 / 10000.
            dlon1 = lon1 / 10000.
C
C*	    Set projection angles.
C
	    dangl1 = std
	    dangl2 = clon 
	    dangl3 = dangl1
C
	ELSE IF ( proj .eq. 'MER' ) THEN
C
C*	    ****************
C*	    *** Mercator ***
C*	    ****************
C
C*	    Compute lat/lon of lower left and upper right points.
C*	    Make sure that the longitudes are between -180 and +180.
C
	    IF ( rlat1 .gt. rlat2 ) THEN
		temp  = rlat1 * RTD
		dlat1 = rlat2 * RTD
		dlat2 = temp
C
		temp  = rlon1 * RTD
		dlon1 = rlon2 * RTD
		dlon2 = temp
	    ELSE
		dlat1 = rlat1 * RTD
		dlat2 = rlat2 * RTD
		dlon1 = rlon1 * RTD
		dlon2 = rlon2 * RTD    
	    END IF 

	    CALL PRNLON ( 1, dlon1, ier )
	    CALL PRNLON ( 1, dlon2, ier )
C
C*	    Set projection angles.
C
	    dangl1 = 0.
	    dangl2 = 0.
	    dangl3 = 0.
	END IF
C
C*	Set navigation block.
C
	CALL GR_MNAV  ( proj, imnpix, imnlin, dlat1, dlon1, dlat2,
     +			dlon2, dangl1, dangl2, dangl3, .true.,
     +			rnvblk, ier )
C
C*	Set the map projection.
C
	CALL GSMPRJ ( proj, dangl1, dangl2, dangl3,
     +		      dlat1, dlon1, dlat2, dlon2, ier )
C*
	IF ( ier .ne. 0 ) iret = -5
C
	RETURN
	END