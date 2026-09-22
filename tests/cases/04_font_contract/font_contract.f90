program font_contract
  use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
  implicit none

  integer, parameter :: nmax = 512
  real, parameter :: tolerance_factor = 16.0
  real :: simplex_x(nmax), simplex_y(nmax)
  real :: duplex_x(nmax), duplex_y(nmax)
  real :: extended_x(nmax), extended_y(nmax)
  real :: query_x(nmax), query_y(nmax)
  integer(kind=4) :: simplex_bits((nmax + 31) / 32)
  integer(kind=4) :: duplex_bits((nmax + 31) / 32)
  integer(kind=4) :: extended_bits((nmax + 31) / 32)
  integer(kind=4) :: query_bits((nmax + 31) / 32)
  integer :: simplex_count, duplex_count, extended_count, query_count
  integer :: ugelv, ugeix
  character(len=8) :: ugenm
  common /ugerrd/ ugelv, ugenm, ugeix
  save /ugerrd/

  simplex_bits = 0
  duplex_bits = 0
  extended_bits = 0
  query_bits = 0

  call ugfont('SIMPLEX')
  call require_clear_error('UGFONT SIMPLEX')
  call ugctol('SIZE=0.1,FIXSIZE', 0.2, 0.3, 'A', ' ', nmax, &
              simplex_x, simplex_y, simplex_count, simplex_bits)
  call require_clear_error('UGCTOL SIMPLEX A')
  call require_strokes('SIMPLEX A', simplex_x, simplex_y, simplex_count)

  call ugfont('DUPLEX')
  call require_clear_error('UGFONT DUPLEX')
  call ugctol('SIZE=0.1,FIXSIZE', 0.2, 0.3, 'A', ' ', nmax, &
              duplex_x, duplex_y, duplex_count, duplex_bits)
  call require_clear_error('UGCTOL DUPLEX A')
  call require_strokes('DUPLEX A', duplex_x, duplex_y, duplex_count)
  call require_distinct('SIMPLEX and DUPLEX A', &
                        simplex_x, simplex_y, simplex_count, &
                        duplex_x, duplex_y, duplex_count)

  call ugctol('SIZE=0.1,FIXSIZE', 0.2, 0.3, 'A', 'G', nmax, &
              extended_x, extended_y, extended_count, extended_bits)
  call require_clear_error('UGCTOL DUPLEX Greek alpha')
  call require_strokes('DUPLEX Greek alpha', &
                       extended_x, extended_y, extended_count)
  call require_distinct('Roman A and Greek alpha', &
                        duplex_x, duplex_y, duplex_count, &
                        extended_x, extended_y, extended_count)

  call ugctol('SIZE=0.1,FIXSIZE,LAST', 0.2, 0.3, 'AB', '  ', nmax, &
              query_x, query_y, query_count, query_bits)
  call require_clear_error('UGCTOL LAST')
  call require_query('UGCTOL LAST', query_count, query_x, query_y, &
                     0.3, 0.3, 1.0)

  call ugctol('SIZE=0.1,FIXSIZE,NEXT', 0.2, 0.3, 'AB', '  ', nmax, &
              query_x, query_y, query_count, query_bits)
  call require_clear_error('UGCTOL NEXT')
  call require_query('UGCTOL NEXT', query_count, query_x, query_y, &
                     0.4, 0.3, 1.0)

  call ugctol('SIZE=0.1,FIXSIZE', 0.2, 0.3, 'A', ' ', 1, &
              query_x, query_y, query_count, query_bits)
  call require_error('UGCTOL insufficient capacity', 2, 'UGCTOL  ', 2)

  print *, 'Font and text layout contract passed'

contains

  subroutine require_clear_error(phase)
    character(len=*), intent(in) :: phase

    if (ugelv /= 0 .or. ugeix /= 0 .or. ugenm /= '        ') then
      print *, trim(phase), ': expected clear UGS error state, got ', &
               ugelv, ' ', ugenm, ' ', ugeix
      stop 1
    end if
  end subroutine require_clear_error

  subroutine require_error(phase, expected_level, expected_name, expected_index)
    character(len=*), intent(in) :: phase, expected_name
    integer, intent(in) :: expected_level, expected_index

    if (ugelv /= expected_level .or. ugenm /= expected_name .or. &
        ugeix /= expected_index) then
      print *, trim(phase), ': expected ', expected_level, ' ', &
               expected_name, ' ', expected_index, ', got ', &
               ugelv, ' ', ugenm, ' ', ugeix
      stop 1
    end if
  end subroutine require_error

  subroutine require_strokes(label, x, y, count)
    character(len=*), intent(in) :: label
    real, intent(in) :: x(:), y(:)
    integer, intent(in) :: count
    integer :: index

    if (count <= 0 .or. count > size(x) .or. count > size(y)) then
      print *, trim(label), ': expected a valid nonempty stroke count, got ', count
      stop 1
    end if

    do index = 1, count
      if (.not. ieee_is_finite(x(index)) .or. &
          .not. ieee_is_finite(y(index))) then
        print *, trim(label), ': non-finite coordinate at index ', index
        stop 1
      end if
    end do
  end subroutine require_strokes

  subroutine require_distinct(label, x1, y1, count1, x2, y2, count2)
    character(len=*), intent(in) :: label
    real, intent(in) :: x1(:), y1(:), x2(:), y2(:)
    integer, intent(in) :: count1, count2
    integer :: index

    if (count1 /= count2) return

    do index = 1, count1
      if (abs(x1(index) - x2(index)) > scaled_tolerance(x1(index)) .or. &
          abs(y1(index) - y2(index)) > scaled_tolerance(y1(index))) return
    end do

    print *, trim(label), ': expected distinct stroke geometry'
    stop 1
  end subroutine require_distinct

  subroutine require_query(phase, count, x, y, expected_x, expected_y, &
                           expected_scale)
    character(len=*), intent(in) :: phase
    integer, intent(in) :: count
    real, intent(in) :: x(:), y(:)
    real, intent(in) :: expected_x, expected_y, expected_scale

    if (count /= 0) then
      print *, trim(phase), ': expected no generated strokes, got ', count
      stop 1
    end if
    call require_close(trim(phase) // ' X', x(1), expected_x)
    call require_close(trim(phase) // ' Y', y(1), expected_y)
    call require_close(trim(phase) // ' scale', x(2), expected_scale)
  end subroutine require_query

  subroutine require_close(field, actual, expected)
    character(len=*), intent(in) :: field
    real, intent(in) :: actual, expected

    if (.not. ieee_is_finite(actual) .or. &
        abs(actual - expected) > scaled_tolerance(expected)) then
      print *, trim(field), ': expected ', expected, ', got ', actual
      stop 1
    end if
  end subroutine require_close

  real function scaled_tolerance(expected)
    real, intent(in) :: expected

    scaled_tolerance = tolerance_factor * epsilon(expected) * &
                       max(1.0, abs(expected))
  end function scaled_tolerance

end program font_contract
