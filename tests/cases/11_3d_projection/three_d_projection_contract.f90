program three_d_projection_contract
  use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
  implicit none

  integer, parameter :: lseg = 10000
  real, parameter :: tolerance_factor = 16.0
  integer(kind=4) :: segment(lseg), blanking_bits(1)
  real :: viewport(2, 2), world_volume(3, 2)
  real :: object_volume(3, 2), eye_point(3), up_direction(3)
  real :: x(3), y(3), z(3)
  integer :: ugelv, ugeix
  character(len=8) :: ugenm
  common /ugerrd/ ugelv, ugenm, ugeix
  save /ugerrd/

  viewport(1, 1) = 0.2
  viewport(2, 1) = 0.2
  viewport(1, 2) = 0.8
  viewport(2, 2) = 0.8
  world_volume(:, 1) = (/ -2.0, -2.0, -2.0 /)
  world_volume(:, 2) = (/  2.0,  2.0,  2.0 /)
  object_volume(:, 1) = (/ -0.5, -0.5, -0.5 /)
  object_volume(:, 2) = (/  0.5,  0.5,  0.5 /)
  eye_point = (/ 0.0, 0.0, 1.5 /)
  up_direction = (/ 0.0, 1.0, 0.0 /)

  x = (/ -0.4,  0.4,  0.4 /)
  y = (/ -0.4, -0.4,  0.4 /)
  z = (/ -0.4,  0.4, -0.4 /)
  blanking_bits = 1

  call check_state_and_lifecycle
  call write_projection('three-d-parallel.ps', 72, 0.0, 'parallel')
  call write_projection('three-d-point.ps', 73, 0.01, 'point')

  print *, 'Three-dimensional view and projection contract passed'

contains

  subroutine check_state_and_lifecycle
    real :: actual_viewport(2, 2), actual_world(3, 2)
    real :: actual_object(3, 2), actual_eye(3), actual_up(3)
    real :: expected_default_object(3, 2), expected_default_eye(3)
    real :: expected_default_up(3), projection_flag

    call open_device('three-d-state.ps', 71, 'state')
    call set_drawing_space('state')

    call ug3wrd('PUT', viewport, world_volume)
    call require_clear_error('state UG3WRD PUT')
    actual_viewport = 0.0
    actual_world = 0.0
    call ug3wrd('GET', actual_viewport, actual_world)
    call require_clear_error('state UG3WRD GET')
    call require_matrix('UG3WRD viewport', actual_viewport, viewport)
    call require_matrix('UG3WRD world volume', actual_world, world_volume)

    projection_flag = 0.0
    call ug3trn('PUT', object_volume, eye_point, up_direction, projection_flag)
    call require_clear_error('state UG3TRN PUT')
    actual_object = 0.0
    actual_eye = 0.0
    actual_up = 0.0
    projection_flag = -1.0
    call ug3trn('GET', actual_object, actual_eye, actual_up, projection_flag)
    call require_clear_error('state UG3TRN GET')
    call require_matrix('UG3TRN object volume', actual_object, object_volume)
    call require_vector('UG3TRN eye point', actual_eye, eye_point)
    call require_vector('UG3TRN up direction', actual_up, up_direction)
    call require_close('UG3TRN projection flag', projection_flag, 0.0)

    call ugpict('CLEAR', 0)
    call require_clear_error('state UGPICT CLEAR')

    actual_viewport = 0.0
    actual_world = 0.0
    call ug3wrd('GET', actual_viewport, actual_world)
    call require_clear_error('state UG3WRD GET after clear')
    call require_matrix('UG3WRD viewport after clear', actual_viewport, viewport)
    call require_matrix('UG3WRD world volume after clear', actual_world, world_volume)

    expected_default_object(:, 1) = (/ -0.2, -0.2, -0.2 /)
    expected_default_object(:, 2) = (/  0.2,  0.2,  0.2 /)
    expected_default_eye = (/ 0.0, 0.0, 1.0 /)
    expected_default_up = (/ 0.0, 1.0, 0.0 /)
    actual_object = 0.0
    actual_eye = 0.0
    actual_up = 0.0
    projection_flag = -1.0
    call ug3trn('GET', actual_object, actual_eye, actual_up, projection_flag)
    call require_clear_error('state UG3TRN GET after clear')
    call require_matrix('UG3TRN default object volume', actual_object, &
                        expected_default_object)
    call require_vector('UG3TRN default eye point', actual_eye, &
                        expected_default_eye)
    call require_vector('UG3TRN default up direction', actual_up, &
                        expected_default_up)
    call require_close('UG3TRN default projection flag', projection_flag, 0.01)

    call ugclos(' ')
    call require_clear_error('state UGCLOS')
  end subroutine check_state_and_lifecycle

  subroutine write_projection(output_file, device_id, projection_flag, label)
    character(len=*), intent(in) :: output_file, label
    integer, intent(in) :: device_id
    real, intent(in) :: projection_flag
    real :: selected_projection

    call uginit('CLEAR', segment, lseg)
    call require_clear_error(trim(label) // ' UGINIT')
    call ug3pln(' ', x, y, z, 3, blanking_bits, 1, segment)
    call require_clear_error(trim(label) // ' UG3PLN')

    call open_device(output_file, device_id, label)
    call set_drawing_space(label)
    call ug3wrd('PUT', viewport, world_volume)
    call require_clear_error(trim(label) // ' UG3WRD PUT')
    selected_projection = projection_flag
    call ug3trn('PUT', object_volume, eye_point, up_direction, &
                selected_projection)
    call require_clear_error(trim(label) // ' UG3TRN PUT')
    call ugwrit(' ', device_id, segment)
    call require_clear_error(trim(label) // ' UGWRIT')
    call ugclos(' ')
    call require_clear_error(trim(label) // ' UGCLOS')
  end subroutine write_projection

  subroutine open_device(output_file, device_id, label)
    character(len=*), intent(in) :: output_file, label
    integer, intent(in) :: device_id

    call ugopen('POSTSCR,DDNAME=' // trim(output_file) // &
                ',XMIN=150,XMAX=3150,YMIN=150,YMAX=2400,' // &
                'RUCMX=118.11024,RUCMY=118.11024', device_id)
    call require_clear_error(trim(label) // ' UGOPEN')
  end subroutine open_device

  subroutine set_drawing_space(label)
    character(len=*), intent(in) :: label
    real :: xsize, ysize, affinity

    xsize = 1.0
    ysize = 1.0
    affinity = 1.0
    call ugdspc('PUT', xsize, ysize, affinity)
    call require_clear_error(trim(label) // ' UGDSPC PUT')
  end subroutine set_drawing_space

  subroutine require_close(field, actual, expected)
    character(len=*), intent(in) :: field
    real, intent(in) :: actual, expected

    if (.not. ieee_is_finite(actual) .or. &
        abs(actual - expected) > scaled_tolerance(expected)) then
      print *, trim(field), ': expected ', expected, ', got ', actual
      stop 1
    end if
  end subroutine require_close

  subroutine require_vector(field, actual, expected)
    character(len=*), intent(in) :: field
    real, intent(in) :: actual(:), expected(:)
    integer :: index
    character(len=32) :: element

    do index = 1, size(expected)
      write(element, '(" element ", I0)') index
      call require_close(trim(field) // trim(element), actual(index), &
                         expected(index))
    end do
  end subroutine require_vector

  subroutine require_matrix(field, actual, expected)
    character(len=*), intent(in) :: field
    real, intent(in) :: actual(:, :), expected(:, :)
    integer :: axis, bound
    character(len=48) :: element

    do bound = 1, size(expected, 2)
      do axis = 1, size(expected, 1)
        write(element, '(" element (", I0, ",", I0, ")")') axis, bound
        call require_close(trim(field) // trim(element), actual(axis, bound), &
                           expected(axis, bound))
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

end program three_d_projection_contract
