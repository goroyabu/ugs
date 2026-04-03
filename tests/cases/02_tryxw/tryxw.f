      PROGRAM TRYXW_SMOKE  ! Fortran smoke test using UGS XWINDOW driver

      INTEGER    LSEG
      PARAMETER (LSEG = 10000)
      INTEGER*4  SEG  ( LSEG )

      INTEGER*4  XTEXT (1000) , YTEXT (1000) , BTEXT (1000)

      INTEGER    NARGS , I
      LOGICAL    HOLD_WINDOW
      CHARACTER*32 ARG

      CHARACTER*32 STRING

      INCLUDE 'UGSYSTEM_UGERRCBK.FOR'

*     Check command-line arguments for '--hold'
      HOLD_WINDOW = .FALSE.
      NARGS = COMMAND_ARGUMENT_COUNT()
      DO 10 I = 1, NARGS
         CALL GET_COMMAND_ARGUMENT(I, ARG)
         IF (TRIM(ARG) .EQ. '--hold') HOLD_WINDOW = .TRUE.
10    CONTINUE

      CALL UGINIT ( 'CLEAR' , SEG , LSEG )

*     Open XWINDOW device (simplified, environment DISPLAY is used)
      CALL UGOPEN ( 'XWINDOW' , 1 )
      WRITE (*,*) 'UGOPEN done, UGELV/UGENM/UGEIX =',
     +            UGELV, UGENM, UGEIX
      CALL UGSLCT ( ' ' , 1 )

*     Font/text path (UGFONT/UGCTOL) is disabled in this smoke test
*     because font BLOCK DATA may not be linked on all toolchains.
*     CALL UGFONT ( 'SIMPLEX' )
*     CALL UGCTOL (
*    +  ' ' ,          ! OPTION
*    +   0.4 ,         ! X
*    +   0.5 ,         ! Y
*    +   'TEXT',       ! TEXT
*    +   '    ',       ! SEC TEXT
*    +   1000,         ! NSIZE
*    +   XTEXT,        ! X ARRAY
*    +   YTEXT,        ! Y ARRAY
*    +   NCOORD,       ! NUM COORDS
*    +   BTEXT         ! BLANKING
*    +   )

      IF (1.EQ.2) GOTO 66666

*     Basic colored cross-lines
      CALL UGLINE ( ' '    , 0.1 , 0.1 , 0 , SEG )
      CALL UGLINE ( 'RED'  , 0.9 , 0.9 , 1 , SEG )
      CALL UGLINE ( ' '    , 0.1 , 0.9 , 0 , SEG )
      CALL UGLINE ( 'GREEN', 0.9 , 0.1 , 1 , SEG )

*     Draw text-generated path (disabled as above)
*     CALL UGPLIN ( ' ' , XTEXT,YTEXT,NCOORD , BTEXT,-NCOORD, SEG )
*     CALL UGLINE ( ' ' , 0.35 , 0.4925 , 0 , SEG )
*     CALL UGLINE ( ' ' , 0.38 , 0.4925 , 1 , SEG )
*     CALL UGLINE ( ' ' , 0.35 , 0.5075 , 0 , SEG )
*     CALL UGLINE ( ' ' , 0.38 , 0.5075 , 1 , SEG )

*     CALL UGCTOL(' SIZE = .1 ',.65,.5,
*    +   'TEXT','    ',1000,XTEXT,YTEXT,NCOORD,BTEXT)
*     CALL UGPLIN ( ' ' , XTEXT,YTEXT,NCOORD , BTEXT,-NCOORD, SEG )
*     CALL UGLINE ( ' ' , 0.57 , 0.45 , 0 , SEG )
*     CALL UGLINE ( ' ' , 0.60 , 0.45 , 1 , SEG )
*     CALL UGLINE ( ' ' , 0.57 , 0.55 , 0 , SEG )
*     CALL UGLINE ( ' ' , 0.60 , 0.55 , 1 , SEG )

*     Flush segment to the device
      CALL UGWRIT ( ' ' , 0 , SEG )
      WRITE (*,*) 'UGWRIT done, UGELV/UGENM/UGEIX =',
     +            UGELV, UGENM, UGEIX

*     Optional hold for manual inspection (does not affect automated tests).
      IF (HOLD_WINDOW) THEN
         WRITE (*,*) 'Press ENTER to close window...'
         READ  (*,*)
      ENDIF

      CALL UGINIT ( 'CLEAR' , SEG , LSEG )

66666 CONTINUE

      CALL UGCLOS ( ' ' )

      STOP
      END
