      SUBROUTINE PK_SECT0(KFILDO,IPACK,ND5,IS0,NS0,L3264B,
     1                    NEW,LOCN,IPOS,IEDITION,LOCN0_9,
     2                    IPOS0_9,IER,ISEVERE,*)
C
C        MARCH   2000   LAWRENCE   GSC/TDL   ORIGINAL CODING
C        JANUARY 2001   GLAHN      COMMENTS; ADDED TEST FOR SIZE
C                                  OF IS0( )
C        JANUARY 2001   GLAHN/LAWRENCE INITIALIZED IS0(1) AND IS0(8)
C        MARCH 2001     LAWRENCE   CHANGED HOW THIS ROUTINE PACKS 
C                                  THE NUMERIC EQUIVALENT OF THE
C                                  STRING "GRIB".
C
C        PURPOSE
C            PACKS SECTION 0, THE INDICATOR SECTION, OF A GRIB2
C            MESSAGE. SECTION 0 CONTAINS INFORMATION PERTAINING
C            TO THE SIZE OF THE MESSAGE AND THE EDITION OF
C            THE GRIB STANDARDS TO BE FOLLOWED IN THE PACKING
C            PROCESS.
C
C            IF THIS IS A NEW GRIB2 MESSAGE, THEN THE CONTENTS OF
C            IS0( ) ARE PACKED INTO THE MESSAGE. IF THIS IS A
C            PRODUCT THAT IS GETTING APPENDED ONTO A PREEXISTING
C            MESSAGE, THEN SECTION 0 IS NOT PACKED AGAIN. INSTEAD,
C            THE END OF MESSAGE INDICATOR OF THE PREVIOUSLY PACKED
C            PRODUCT IS OVERWRITTEN, AND THE SIZE OF THE GRIB2
C            MESSAGE (AS STATED BY OCTETS 9-16 OF SECTION 0 OF
C            THE PREVIOUS PACKED PRODUCT) IS ZEROED OUT. THE TOTAL
C            SIZE OF THE GRIB2 MESSAGE IS RECALCULATED IN ANOTHER
C            ROUTINE EVERY TIME NEW PRODUCT IS PACKED ONTO THE MESSAGE.
C
C        DATA SET USE
C           KFILDO - UNIT NUMBER FOR OUTPUT (PRINT) FILE. (OUTPUT)
C
C        VARIABLES
C              KFILDO = UNIT NUMBER FOR OUTPUT (PRINT) FILE. (INPUT)
C            IPACK(J) = THE ARRAY THAT HOLDS THE ACTUAL PACKED MESSAGE
C                       (J=1,ND5). (INPUT/OUTPUT)
C                 ND5 = THE SIZE OF THE ARRAY IPACK( ). (INPUT)
C              IS0(J) = CONTAINS THE INDICATOR DATA THAT
C                       WILL BE PACKED INTO IPACK( ) (J=1,NS0).
C                       (INPUT)
C                 NS0 = SIZE OF IS0( ). (INPUT)
C              L3264B = THE INTEGER WORD LENGTH IN BITS OF THE MACHINE
C                       BEING USED. VALUES OF 32 AND 64 ARE
C                       ACCOMMODATED. (INPUT)
C                 NEW = WHEN NEW = 1, THIS IS A NEW PRODUCT. WHEN
C                       NEW = 0, THIS IS ANOTHER GRID TO PUT INTO
C                       THE SAME PRODUCT.  (INPUT)
C                LOCN = THE WORD POSITION TO PLACE THE NEXT VALUE.
C                       (INPUT/OUTPUT)
C                IPOS = THE BIT POSITION IN LOCN TO START PLACING
C                       THE NEXT VALUE. (INPUT/OUTPUT)
C            IEDITION = THE EDITION NUMBER OF THE GRIB2 ENCODER USED.
C                       (INPUT) 
C             LOCN0_9 = CONTAINS THE WORD POSITION IN IPACK TO
C                       PACK THE TOTAL LENGTH OF THE PACKED GRIB2
C                       MESSAGE ONCE THIS VALUE CAN BE DETERMINED,
C                       I.E. WHEN THE MESSAGE HAS BEEN COMPLETELY
C                       PACKED.  (OUTPUT)
C             IPOS0_9 = CONTAINS THE BIT POSITION IN WORD LOCN0_9 OF
C                       IPACK TO PACK THE TOTAL LENGTH OF THE PACKED
C                       GRIB2 MESSAGE ONCE THIS VALUE CAN BE
C                       DETERMINED, I.E. WHEN THE MESSAGE HAS BEEN
C                       COMPLETELY PACKED. (OUTPUT)
C                 IER = RETURN STATUS CODE. (OUTPUT)
C                          0 = GOOD RETURN.
C                        1-4 = FATAL ERROR CODES RETURNED FROM PKBG.
C                       1002 = IS0( ) HAS NOT BEEN DIMENSIONED LARGE
C                              ENOUGH.
C             ISEVERE = THE SEVERITY LEVEL OF THE ERROR.  THE ONLY
C                       VALUE RETUNED IS:
C                       2 = A FATAL ERROR  (OUTPUT)
C                   * = ALTERNATE ERROR RETURN. (OUTPUT)
C
C             LOCAL VARIABLES
C               IGRIB = CONTAINS THE HEXADECIMAL REPRESENTATION
C                       OF THE STRING "GRIB" AS IT WOULD APPEAR
C                       WHEN THE STRING IS EQUIVALENCED TO
C                       AN INTEGER*4 VARIABLE ON A "BIG ENDIAN"
C                       PLATFORM.
C              IGRIB1 = CONTAINS THE VALUE OF IGRIB IF A 64-BIT MACHINE
C                       IS BEING USED.
C               IZERO = CONTAINS THE VALUE '0'.  THIS IS USED IN THE
C                       CODE SIMPLY TO EMPHASIZE THAT A CERTAIN 
C                       GROUP OF OCTETS IN THE MESSAGE ARE BEING 
C                       ZEROED OUT.
C                   N = L3264B = THE INTEGER WORD LENGTH IN BITS OF
C                       THE MACHINE BEING USED. VALUES OF 32 AND
C                       64 ARE ACCOMMODATED.
C             MINSIZE = THE MINIMUM SIZE FOR IS0( ).  IS0(7) IS
C                       FILLED IN PK_SECT0, AND IS0(9) IS FILLED IN
C                       PK_GRIB.  THIS ONLY APPLIES WHEN THIS IS 
C                       A "NEW" MESSAGE.      
C
C        NON SYSTEM SUBROUTINES CALLED
C           PKBG
C
      PARAMETER(MINSIZE=9)
C
      DIMENSION IPACK(ND5),IS0(NS0)
C
      DATA IGRIB/'47524942'X/
      DATA IZERO/0/
C
      N=L3264B
      IER=0
C
C        ALL ERRORS GENERATED BY THIS ROUTINE ARE FATAL.
      ISEVERE=2
C
      IF(NEW.EQ.1)THEN
C
C           CHECK MINIMUM SIZE OF IS0( ).
C
         IF(NS0.LT.MINSIZE)THEN
C              IS0(7) FILLED IN PK_SECT0, AND IS0(9) FILLED IN
C              PK_GRIB.         
            IER=1002
            GO TO 900
         ENDIF
C
C           THIS IS THE FIRST GRID TO BE PACKED.
C           LOCN = WORD POSITION IN IPACK( ) TO START PACKING.
C           PKBG UPDATES IT.
         LOCN=1
C
C           IPOS = BIT POSITION IN IPACK(LOCN) TO START PUTTING VALUE.
C           PKBG UPDATES IT.
         IPOS=1
C
C           IPACK IS ZEROED IF THIS IS THE FIRST GRID TO BE PACKED
C
         DO K=1,ND5
            IPACK(K)=0
         ENDDO
C
C           PACK THE WORD "GRIB".
C           ACCOMMODATE A 64-BIT WORD, IF NEED BE, BY
C           MOVING THE 4 CHARACTERS TO THE RIGHT HALF OF THE WORD FOR
C           PACKING.
         IGRIB1=IGRIB
         IF(L3264B.EQ.64)IGRIB1=ISHFT(IGRIB,-32)
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IGRIB1,32,N,IER,*900)
         IS0(1)=IGRIB
C
C           SKIP OVER BYTES 5-6, WHICH ARE RESERVED
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IZERO,16,N,IER,*900)
         IS0(5)=0
         IS0(6)=0
C
C           PACK THE DISCIPLINE - MASTER TABLE NUMBER
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS0(7),8,N,IER,*900)
C
C           PACK GRIB EDITION NUMBER.
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IEDITION,8,N,IER,*900)
         IS0(8)=IEDITION
C
C           BYTES 9-16 MUST BE FILLED IN LATER WITH THE GRIB RECORD
C           LENGTH IN BYTES; LOCN0_9 AND IPOS0_9 HOLD THE LOCATION, AND
C           THE BELOW STATEMENTS HOLD THE PLACE.
         LOCN0_9=LOCN
         IPOS0_9=IPOS
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IZERO,32,N,IER,*900)
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IZERO,32,N,IER,*900)
C
C           NOTE THAT ONLY A 32-BIT SIZE IS SUPPORTED, WHICH
C           ACCOMMODATES OVER 4 GIGABYTES.
         DO K=9,NS0
            IS0(K)=0
         ENDDO
C
      ELSE
C
C           WHEN THIS IS AN ADDITION TO THE PRODUCT, LOCN AND 
C           IPOS HAVE VALUES ON ENTRY THAT REPRESENT THE 7777
C           END OF MESSAGE.  THIS 7777 SHOULD BE OVERWRITTEN.
C           DO IT BY WRITING A ZERO, THEN SETTING LOCN = LOCN-1.
C           ALSO NEED TO ZERO OUT THE PRODUCT SIZE, SO THAT IT CAN BE
C           FILLED IN AT THE END.
C
         LOCN=LOCN-1
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IZERO,32,N,IER,*900)
         LOCN=LOCN-1
         CALL PKBG(KFILDO,IPACK,ND5,LOCN0_9,IPOS0_9,IZERO,32,N,IER,*900)
         LOCN0_9=LOCN0_9-1
      ENDIF
C
 900  IF(IER.NE.0)RETURN 1
C
      RETURN
      END