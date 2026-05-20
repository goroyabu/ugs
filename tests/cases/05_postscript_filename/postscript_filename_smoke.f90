program postscript_filename_smoke
  implicit none

  integer, parameter :: lseg = 10000
  integer*4 :: seg(lseg)
  character(len=*), parameter :: output_file = 'postscript-output.ps'
  character(len=256) :: first_line
  integer :: unit, ios
  integer(kind=8) :: file_size
  logical :: exists

  call uginit('CLEAR', seg, lseg)
  call ugopen('POSTSCR,DDNAME=' // output_file, 1)
  call ugslct(' ', 1)

  call ugline(' ', 0.1, 0.1, 0, seg)
  call ugline(' ', 0.9, 0.9, 1, seg)
  call ugline(' ', 0.1, 0.9, 0, seg)
  call ugline(' ', 0.9, 0.1, 1, seg)
  call ugwrit(' ', 0, seg)
  call ugclos(' ')

  inquire(file=output_file, exist=exists, size=file_size)
  if (.not. exists) then
    print *, 'PostScript output file was not created: ', output_file
    stop 1
  end if

  if (file_size <= 0) then
    print *, 'PostScript output file is empty: ', output_file
    stop 1
  end if

  open(newunit=unit, file=output_file, status='old', action='read', iostat=ios)
  if (ios /= 0) then
    print *, 'Could not open PostScript output file: ', output_file
    stop 1
  end if

  read(unit, '(A)', iostat=ios) first_line
  close(unit)
  if (ios /= 0 .or. index(first_line, '%!PS-Adobe-') /= 1) then
    print *, 'Unexpected PostScript header: ', trim(first_line)
    stop 1
  end if

  print *, 'PostScript filename smoke passed'
end program postscript_filename_smoke
