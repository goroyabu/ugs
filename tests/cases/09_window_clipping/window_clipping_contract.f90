program window_clipping_contract
  implicit none

  integer, parameter :: lseg = 10000
  integer(kind=4) :: seg(lseg)
  real :: xsize, ysize, affinity
  real :: viewport(2, 2), window(2, 2)
  integer :: ugelv, ugeix
  character(len=8) :: ugenm
  common /ugerrd/ ugelv, ugenm, ugeix
  save /ugerrd/

  call uginit('CLEAR', seg, lseg)
  call require_clear_error('UGINIT')

  call ugline(' ', 2.0, 2.0, 0, seg)
  call require_clear_error('UGLINE inside start')
  call ugline(' ', 8.0, 8.0, 1, seg)
  call require_clear_error('UGLINE inside end')

  call ugline(' ', -5.0, 5.0, 0, seg)
  call require_clear_error('UGLINE crossing start')
  call ugline(' ', 15.0, 5.0, 1, seg)
  call require_clear_error('UGLINE crossing end')

  call ugline(' ', -5.0, -5.0, 0, seg)
  call require_clear_error('UGLINE outside start')
  call ugline(' ', -1.0, -1.0, 1, seg)
  call require_clear_error('UGLINE outside end')

  call ugopen('POSTSCR,DDNAME=window-clipping-output.ps,' // &
              'XMIN=150,XMAX=3150,YMIN=150,YMAX=2400,' // &
              'RUCMX=118.11024,RUCMY=118.11024', 42)
  call require_clear_error('UGOPEN')

  xsize = 1.0
  ysize = 1.0
  affinity = 1.0
  call ugdspc('PUT', xsize, ysize, affinity)
  call require_clear_error('UGDSPC PUT')

  viewport(1, 1) = 0.20
  viewport(2, 1) = 0.20
  viewport(1, 2) = 0.80
  viewport(2, 2) = 0.80
  window(1, 1) = 0.0
  window(2, 1) = 0.0
  window(1, 2) = 10.0
  window(2, 2) = 10.0
  call ugwdow('PUT', viewport, window)
  call require_clear_error('UGWDOW PUT after segment construction')

  call ugwrit(' ', 1, seg)
  call require_clear_error('UGWRIT mapped segment')

  call ugclos(' ')
  call require_clear_error('UGCLOS')

  print *, 'Window mapping and clipping contract passed'

contains

  subroutine require_clear_error(phase)
    character(len=*), intent(in) :: phase

    if (ugelv /= 0 .or. ugeix /= 0 .or. ugenm /= '        ') then
      print *, trim(phase), ': expected clear UGS error state, got ', &
               ugelv, ' ', ugenm, ' ', ugeix
      stop 1
    end if
  end subroutine require_clear_error

end program window_clipping_contract
