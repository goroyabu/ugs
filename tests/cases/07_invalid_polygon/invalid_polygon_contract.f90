program invalid_polygon_contract
  implicit none

  integer, parameter :: lseg = 10000
  integer(kind=4) :: seg(lseg)
  real :: x(2), y(2)
  integer :: ugelv, ugeix
  character(len=8) :: ugenm
  common /ugerrd/ ugelv, ugenm, ugeix
  save /ugerrd/

  x = [0.25, 0.75]
  y = [0.25, 0.75]

  call uginit('CLEAR', seg, lseg)
  if (ugelv /= 0 .or. ugeix /= 0 .or. ugenm /= '        ') then
    print *, 'UGINIT: expected clear UGS error state, got ', &
             ugelv, ' ', ugenm, ' ', ugeix
    stop 1
  end if

  call ugpfil(' ', x, y, 2, seg)

  if (ugelv /= 2) then
    print *, 'UGPFIL invalid polygon: expected level 2, got ', ugelv
    stop 1
  end if
  if (ugenm /= 'UGPFIL  ') then
    print *, 'UGPFIL invalid polygon: expected subroutine UGPFIL, got ', ugenm
    stop 1
  end if
  if (ugeix /= 1) then
    print *, 'UGPFIL invalid polygon: expected index 1, got ', ugeix
    stop 1
  end if

  print *, 'Invalid polygon error contract passed'
end program invalid_polygon_contract
