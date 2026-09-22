program algorithm_linkage_contract
  use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
  implicit none

  real :: reference_point(3), view_direction(3), horizontal_direction(3)
  real :: upward_direction(3), transformation(31)
  integer :: ugelv, ugeix
  character(len=8) :: ugenm
  character(len=32) :: mode
  common /ugerrd/ ugelv, ugenm, ugeix
  save /ugerrd/

  reference_point = (/ 0.0, 0.0, 2.0 /)
  view_direction = (/ 0.0, 0.0, -1.0 /)
  horizontal_direction = (/ 1.0, 0.0, 0.0 /)
  upward_direction = (/ 0.0, 1.0, 0.0 /)
  transformation = 0.0
  ugelv = 0
  ugenm = '        '
  ugeix = 0

  call ugtran('PARALLEL', reference_point, view_direction, &
              horizontal_direction, upward_direction, 1.0, 1.0, &
              transformation)
  if (ugelv /= 0 .or. ugeix /= 0 .or. ugenm /= '        ') then
    print *, 'UGTRAN reported an unexpected error: ', ugelv, ugenm, ugeix
    stop 1
  end if
  if (.not. all(ieee_is_finite(transformation))) then
    print *, 'UGTRAN produced a non-finite transformation'
    stop 1
  end if
  if (all(transformation == 0.0)) then
    print *, 'UGTRAN did not populate the transformation'
    stop 1
  end if

  mode = ''
  if (command_argument_count() > 0) call get_command_argument(1, mode)
  if (trim(mode) == '--exercise-generators') then
    call reference_algorithm_generators(transformation)
  end if

  print *, 'Algorithm linkage contract passed'

contains

  subroutine reference_algorithm_generators(active_transformation)
    real, intent(in) :: active_transformation(31)
    real :: surface(3, 3), workspace(100)
    external :: line_callback, text_callback, polygon_callback

    surface = 0.0
    workspace = 0.0
    call ugqctr(' ', line_callback, text_callback, surface, 3, 3, &
                0.0, 1.0, 2)
    call ugmesh(' ', line_callback, surface, 3, 3, &
                active_transformation, workspace, size(workspace))
    call ug2dhg(' ', line_callback, surface, 3, 3, &
                active_transformation, workspace, size(workspace))
    call ug2dhp(' ', polygon_callback, surface, 3, 3, &
                active_transformation)
  end subroutine reference_algorithm_generators

end program algorithm_linkage_contract

subroutine line_callback(x, y, blanking)
  implicit none
  real, intent(in) :: x, y
  integer, intent(in) :: blanking
end subroutine line_callback

subroutine text_callback(x, y, value, flag)
  implicit none
  real, intent(in) :: x, y, value
  integer, intent(in) :: flag
end subroutine text_callback

subroutine polygon_callback(x, y, count, blanking)
  implicit none
  real, intent(in) :: x(*), y(*)
  integer, intent(in) :: count, blanking
end subroutine polygon_callback
