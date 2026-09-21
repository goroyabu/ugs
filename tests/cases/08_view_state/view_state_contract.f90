program view_state_contract
  use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
  implicit none

  real, parameter :: tolerance_factor = 16.0
  real :: xsize, ysize, affinity
  real :: viewport(2, 2), window(2, 2)
  real :: actual_viewport(2, 2), actual_window(2, 2)
  integer :: ugelv, ugeix
  character(len=8) :: ugenm
  common /ugerrd/ ugelv, ugenm, ugeix
  save /ugerrd/

  call ugopen('POSTSCR,DDNAME=view-state-output.ps,' // &
              'XMIN=150,XMAX=3150,YMIN=150,YMAX=2400,' // &
              'RUCMX=118.11024,RUCMY=118.11024', 41)
  call require_clear_error('UGOPEN')

  xsize = 2.0
  ysize = 1.0
  affinity = 0.375
  call ugdspc('PUT', xsize, ysize, affinity)
  call require_clear_error('UGDSPC PUT')

  xsize = 0.0
  ysize = 0.0
  affinity = 0.0
  call ugdspc('GET', xsize, ysize, affinity)
  call require_clear_error('UGDSPC GET')
  call require_close('UGDSPC XSIZE', xsize, 2.0)
  call require_close('UGDSPC YSIZE', ysize, 1.0)
  call require_close('UGDSPC AFFINITY', affinity, 0.375)

  viewport(1, 1) = 0.25
  viewport(2, 1) = 0.20
  viewport(1, 2) = 1.75
  viewport(2, 2) = 0.80
  window(1, 1) = -10.0
  window(2, 1) = 100.0
  window(1, 2) = 30.0
  window(2, 2) = 140.0
  call ugwdow('PUT', viewport, window)
  call require_clear_error('UGWDOW PUT')

  actual_viewport = 0.0
  actual_window = 0.0
  call ugwdow('GET', actual_viewport, actual_window)
  call require_clear_error('UGWDOW GET')
  call require_matrix('UGWDOW viewport', actual_viewport, viewport)
  call require_matrix('UGWDOW window', actual_window, window)

  call ugclos(' ')
  call require_clear_error('UGCLOS')

  print *, 'Drawing-space and window state contract passed'

contains

  subroutine require_close(field, actual, expected)
    character(len=*), intent(in) :: field
    real, intent(in) :: actual, expected

    if (.not. ieee_is_finite(actual) .or. &
        abs(actual - expected) > scaled_tolerance(expected)) then
      print *, trim(field), ': expected ', expected, ', got ', actual
      stop 1
    end if
  end subroutine require_close

  subroutine require_matrix(field, actual, expected)
    character(len=*), intent(in) :: field
    real, intent(in) :: actual(2, 2), expected(2, 2)
    integer :: axis, bound

    do bound = 1, 2
      do axis = 1, 2
        if (.not. ieee_is_finite(actual(axis, bound)) .or. &
            abs(actual(axis, bound) - expected(axis, bound)) > &
            scaled_tolerance(expected(axis, bound))) then
          print *, trim(field), ' axis ', axis, ' bound ', bound, &
                   ': expected ', expected(axis, bound), ', got ', &
                   actual(axis, bound)
          stop 1
        end if
      end do
    end do
  end subroutine require_matrix

  real function scaled_tolerance(expected)
    real, intent(in) :: expected

    scaled_tolerance = tolerance_factor * epsilon(expected) * &
                       max(1.0, abs(expected))
  end function scaled_tolerance

  subroutine require_clear_error(phase)
    character(len=*), intent(in) :: phase

    if (ugelv /= 0 .or. ugeix /= 0 .or. ugenm /= '        ') then
      print *, trim(phase), ': expected clear UGS error state, got ', &
               ugelv, ' ', ugenm, ' ', ugeix
      stop 1
    end if
  end subroutine require_clear_error

end program view_state_contract
