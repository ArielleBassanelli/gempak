	SUBROUTINE SNDLSI ( nlun, lun, dattim, levout, pres, temp, dwpt,
     +			    iemlflg, rrhbrk, bseinv, iret )
C************************************************************************
C* SNDLSI								*
C*									*
C* This routine computes the lid strength index.			*
C*									*
C* SNDLSI ( NLUN, LUN, DATTIM, LEVOUT, PRES, TEMP, DWPT, IEMLFLG,	*
C*	    RRHBRK, BSEINV, IRET )					*
C*									*
C* Input parameters:							*
C*	NLUN		INTEGER		Number of file numbers		*
C*	LUN (NLUN)	INTEGER		File numbers			*
C*	DATTIM		CHAR*		Date/time			*
C*	LEVOUT		INTEGER		Number of levels		*
C*	PRES (LEVOUT)	INTEGER		Pressure			*
C*	TEMP (LEVOUT)	INTEGER		Temperature			*
C*	DWPT (LEVOUT)	INTEGER		Dew point			*
C*	IEMLFLG		INTEGER		Elevated mixed layer flag	*
C*	RRHBRK		INTEGER		Relative humidity break		*
C*	BSEINV		INTEGER		Height of base inversion	*
C*									*
C* Output parameters:							*
C*	IRET		INTEGER		Return code			*
C*					  0 = normal			*
C**									*
C* Log:									*
C* S. Jacobs/SSAI	 4/92						*
C* J. Whistler/SSAI	 4/93		Cleaned up header		*
C************************************************************************
	INCLUDE		'GEMPRM.PRM'
C*
	CHARACTER*(*)	dattim
	INTEGER		lun(*)
	INTEGER		pres(*), temp(*), dwpt(*), rrhbrk, bseinv
C*
	REAL		thwavg(10), thwpbl(10)
C*
	INTEGER		lavmax(10), pbltop, ptop, pbase, plmt
C------------------------------------------------------------------------
	iret = 0
C
C*	Initialize the critical values for lid determination (found by
C*	Graziano 1985) his values decreased by a few tenths of a degree
C*	to cover real to integer conversions.
C
	bcycrit = 0.5
	IF  ( dattim(8:9) .eq. '12' )  THEN
	    xlidcrit = 2.4
	    edgcrit = 0.9
	ELSE
	    xlidcrit = 1.5
	    edgcrit = 0.9
	END IF
C
C*	Is station outside of map requested and does it go high enough?
C
	IF  ( pres(1) .lt. 500 .or. pres(levout) .gt. 300 )  RETURN
C
C*	If data is from 12Z, check if a surface layer inversion exists.
C*	If so destroy it via surface heating and mixing. The data from
C*	00Z already has all of the surface heating it's going to get.
C
	IF  ( dattim(8:9) .eq. '12' )  CALL SNDHTR ( pres, temp, dwpt )
C
C*	Calculate the best mean THW in the PBL.
C*	Find the maximum 50mb-thick mean THW in the designated PBL.
C*	Determine top of the PBL.
C
	pbltop = pres(1) - ( 10 * 10 )
	IF  ( pbltop .lt. rrhbrk )  pbltop = rrhbrk
C
C*	Calculate the mean THW in the lowest 50mb layer.
C
	thwtot = 0.
	icount = 0
	ptop  = pres(1) - 50
	pbase = pres(1)
	ip  = pbase
	it  = temp(1)
	itd = dwpt(1)
	j = 1
	k = 1
	DO  WHILE ( ip .ge. ptop)
	    CALL SNDTWB ( ip, it, itd, 1, thwpbl(k), iplcl)
	    thwtot = thwtot + thwpbl(k)
	    icount = icount + 1
C
C*	    Next level up.
C
	    ip = ip - 10.
	    flag = 0
	    DO  WHILE (j .le. levout-1 .and. flag .eq. 0)
		IF  ( ip .gt. pres(j+1) )  THEN
C
C*		    Interpolating.
C
		    p     = FLOAT ( pres(j) )
		    pp    = FLOAT ( ip )
		    ppp   = FLOAT ( pres(j+1) )
		    ratio = ( ALOG(pp) - ALOG(p) ) /
     +				( ALOG(ppp) - ALOG(p) )
		    it  = INT ( FLOAT(temp(j)) + ratio *
     +				FLOAT( temp(j+1) - temp(j) ) )
		    itd = INT ( FLOAT(dwpt(j)) + ratio *
     +				FLOAT( dwpt(j+1) - dwpt(j) ) )
		    flag = 1
		ELSE IF  ( INT(p2) .eq. INT(pres(j+1)) )  THEN
		    j = j + 1
		    it  = temp(j)
		    itd = dwpt(j)
		    flag = 1
		ELSE
		    j = j + 1
		END IF
	    END DO
	    k = k + 1
	END DO
	l = 1
	thwavg(l) = thwtot / FLOAT(icount)
	lavmax(l) = pbase
C
C*	Now calculate mean THW in each 50mb layer every 10mb's up to
C*	PBLTOP by dropping off base value and adding top value.
C
	pbase = pbase - 10
	l = l + 1
	m = 1
	DO  WHILE  ( ip .ge. pbltop .and. k .le. 10 )
	    CALL SNDTWB ( ip, it, itd, 1, thwpbl(k), iplcl )
	    thwtot = thwtot - thwpbl(m) + thwpbl(k)
	    thwavg(l) = thwtot / FLOAT ( icount )
	    lavmax(l) = pbase
C
C*	    Next level up:
C
	    pbase = pbase - 10
	    ip = ip - 10
	    flag = 0
	    DO  WHILE ( j .le. levout-1 .and. flag .eq. 0 )
		IF  ( ip .gt. pres(j+1) )  THEN
C
C*		    Interpolating.
C
		    p     = FLOAT ( pres(j) )
		    pp    = FLOAT ( ip )
		    ppp   = FLOAT ( pres(j+1) )
		    ratio = ( ALOG(pp) - ALOG(p) ) /
     +			    ( ALOG(ppp) - ALOG(p) )
		    it  = INT ( FLOAT(temp(j)) + ratio *
     +				FLOAT( temp(j+1) - temp(j) ) )
		    itd = INT ( FLOAT(dwpt(j)) + ratio *
     +				FLOAT( dwpt(j+1) - dwpt(j) ) )
		    flag = 1
		ELSE IF  ( ip .eq. pres(j+1) )  THEN
		    j = j + 1
		    it  = temp(j)
		    itd = dwpt(j)
		    flag = 1
		ELSE
		    j = j + 1
		END IF
	    END DO
	    k = k + 1
	    l = l + 1
	    m = m + 1
	END DO
	icount = l - 1
C
C*	Find maximum value, and save the maximum's array index in L.
C
	k = 1
	l = 1
	DO  WHILE ( k .le. icount )
	    IF  ( thwavg(k) .gt. thwavg(l) )  l = k
	    k = k + 1
	END DO
C
C*	Find the maximum THSW (TL5MAX) from the RRHBRK up to 500 mb.
C*	Get above or at RRHBRK.
C
	plmt = rrhbrk
	IF  ( plmt .lt. 500 )  plmt = 500
	j = 1
	DO  WHILE ( pres(j) .gt. plmt )
	    j = j + 1
	END DO
C
C*	Calculate THW at first level.
C
	IF  ( pres(j) .eq. plmt )  THEN
	    CALL SNDTWB ( pres(j), temp(j), temp(j), 3, thw, iplcl)
	    tl5max = thw
	    ll5max = plmt
	ELSE
	    p     = FLOAT ( pres(j-1) )
	    pp    = FLOAT ( plmt )
	    ppp   = FLOAT ( pres(j) )
	    ratio = ( ALOG(pp) - ALOG(p) ) /
     +		    ( ALOG(ppp) - ALOG(p) )
	    it = INT ( FLOAT(temp(j-1)) + ratio *
     +			FLOAT( temp(j) - temp(j-1) ) )
	    CALL SNDTWB ( plmt, it, it, 3, thw, iplcl)
	    tl5max = thw
	    ll5max = plmt
	END IF
C
C*	Find max THWS up to 500mb.
C
	DO  WHILE ( pres(j) .gt. 500 )
	    CALL SNDTWB ( pres(j), temp(j), temp(j), 3, thw, iplcl )
	    IF  ( thw .ge. tl5max )  THEN
		tl5max = thw
		ll5max = pres(j)
	    END IF
	    j = j + 1
	END DO
C
C*	Calculate THWS at 500mb.
C
	IF  ( pres(j) .eq. 500 )  THEN
	    CALL SNDTWB ( 500, temp(j), temp(j), 3, thw, iplcl )
	    thws5 = thw
	    j = j + 1
	ELSE
C
C*	    Interpolating.
C
	    p     = FLOAT ( pres(j-1) )
	    pp    = 500.
	    ppp   = FLOAT ( pres(j) )
	    ratio = ( ALOG(pp) - ALOG(p) ) /
     +		    ( ALOG(ppp) - ALOG(p) )
	    it = INT ( FLOAT(temp(j-1)) + ratio *
     +			FLOAT( temp(j)-temp(j-1) ) )
	    CALL SNDTWB ( 500, it, it, 3, thw, iplcl )
	    thws5 = thw
	END IF
C
	IF  ( thws5 .gt. tl5max )  THEN
	    tl5max = thws5
	    ll5max = 500
	END IF
C
C*	Calculation of the mean THSW (T53AVG) from 500-300 mb.
C
	t53avg = thws5
	icount = 1
	DO  WHILE ( pres(j) .gt. 300 )
	    CALL SNDTWB ( pres(j), temp(j), temp(j), 3, thw, iplcl )
	    t53avg = t53avg + thw
	    icount = icount + 1
	    j = j + 1
	END DO
	IF  ( pres(j) .eq. 300 )  THEN
	    CALL SNDTWB ( 300, temp(j), temp(j), 3, thw, iplcl )
	    t53avg = t53avg + thw
	    icount = icount + 1
	ELSE
C
C*	    Interpolating.
C
	    p     = FLOAT ( pres(j-1) )
	    pp    = 300.
	    ppp   = FLOAT ( pres(j) )
	    ratio = ( ALOG(pp) - ALOG(p) ) /
     +		    ( ALOG(ppp) - ALOG(p) )
	    it = INT ( FLOAT(temp(j-1)) + ratio *
     +			FLOAT( temp(j) - temp(j-1) ) )
	    CALL SNDTWB ( 300, it, it, 3, thw, iplcl )
	    t53avg = t53avg + thw
	    icount = icount + 1
	END IF
	t53avg = t53avg / FLOAT(icount)
C
C*	Determine if a lid exists and calculate the Lid Strength Index.
C
C*	If the following coding is not true a lid does not
C*	exist at the station for one of the following two reasons:
c*	1) the relative humidity discontinuity, if any, may have
C*	occurred at too high a level (above 400mb) in the atmosphere
c*	or;
c*	2) there was either no thermal inversion above the r.h.
c*	discontinuity or the thermal inversion was at or above
c*	500 mb.
C
	IF  ( bseinv .gt. 400 )  THEN
	    bouyc = thws5  - thwavg(l)
	    alid  = tl5max - thwavg(l)
C
C*	If the lid term is negative set it to 0 because this term
c*	plays no part in the bouyancy of the parcels.
C
	    IF  ( alid .lt. 0. )  alid = 0.
C
C*	The following delineates between lids and inversions
c*	caused by other processes.
C*	1) if EMLFLG .GT. 1, the layers above the BSEINV do not meet
C*	the criteria for a lid.
C*	2) if a lid exists, the pbl is most probabily latently
C*	unstable. BCY < BCYCRIT is used because of accuracy limits
C*	in data.
C*	3) for a lid to exist the lid term has to be large enough
c*	to meet Graziano's criteria.
C
	    IF  ( bouyc .lt. bcycrit .and. alid .ge. xlidcrit )  THEN
		IF  ( iemlflg .le. 1 )  THEN
C*		    There is a lid.
		ELSE
C*		    No lid.
		END IF
	    ELSE IF  ( bouyc .lt. bcycrit .and.
     +		       alid .ge. edgcrit )  THEN
		IF  ( iemlflg .le. 1 )  THEN
C*		    Station is at the edge of a lid.
		ELSE
C*		    No lid.
		END IF
	    ELSE
C*		No lid at the station.
	    END IF
	ELSE
C*	    No lid.
	    alid = 0.
	    bouyc = thws5 - thwavg(l)
	END IF
C
C*	And now the moment has come!
C
	xlsi = alid + bouyc
C
C*	Store important quantities for later output and analysis, while
C*	converting to Celcius:
C
	twavpbl = PR_TMKC ( thwavg(l) )
	levmsl  = lavmax(l)
	twsml5  = PR_TMKC ( tl5max )
	levml5  = ll5max
	tws500  = PR_TMKC ( thws5 )
	tws53av = PR_TMKC ( t53avg )
C
C*	Write the output
C
	DO  i = 1, nlun
	    WRITE ( lun(i), 1000 ) xlsi, alid, bouyc,
     +				   tws500, tws53av, twavpbl, twsml5
	END DO
1000	FORMAT ( /, ' Lid Strength Index : ',F10.2, /,
     +           '     Lid Term       : ',F10.2, /,
     +           '     Buoyancy Term  : ',F10.2, /, /,
     +           ' Wet-bulb Pot Temp at 500 mb                     : ',
     +                  F10.2,' C', /,
     +           ' Average Wet-bulb Pot Temp from 500-300 mb       : ',
     +                  F10.2,' C', /,
     +           ' Max 50 mb thick mean Wet-bulb Pot Temp in PBL   : ',
     +                  F10.2,' C', /,
     +           ' Max Wet-bulb Pot Temp from RH dicont. to 500 mb : ',
     +                  F10.2,' C' )
C*
	RETURN
	END
