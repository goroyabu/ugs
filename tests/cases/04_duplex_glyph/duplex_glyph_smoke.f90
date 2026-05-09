program duplex_glyph_smoke
  implicit none

  integer, parameter :: nmax = 128
  real :: ax(nmax), ay(nmax), twox(nmax), twoy(nmax)
  integer :: an, twon
  integer*4 :: abits(5), twobits(5)

  abits = 0
  twobits = 0

  call ugfont('DUPLEX')
  call ugctol('FIXSIZE', 0.0, 0.0, 'A ', '  ', nmax, ax, ay, an, abits)
  call ugctol('FIXSIZE', 0.0, 0.0, '2 ', '  ', nmax, twox, twoy, twon, twobits)

  if (an <= 0 .or. twon <= 0) then
    print *, 'DUPLEX glyph lookup returned no strokes'
    stop 1
  end if

  if (an == twon) then
    if (same_prefix(ax, ay, twox, twoy, an)) then
      print *, 'DUPLEX A and 2 produced identical stroke coordinates'
      stop 1
    end if
  end if

  print *, 'DUPLEX glyph smoke passed'

contains
  logical function same_prefix(x1, y1, x2, y2, n)
    real, intent(in) :: x1(:), y1(:), x2(:), y2(:)
    integer, intent(in) :: n
    integer :: i

    same_prefix = .true.
    do i = 1, n
      if (abs(x1(i) - x2(i)) > 1.0e-6 .or. abs(y1(i) - y2(i)) > 1.0e-6) then
        same_prefix = .false.
        return
      end if
    end do
  end function same_prefix
end program duplex_glyph_smoke
