program postscript_lifecycle_contract
  implicit none

  integer, parameter :: lseg = 10000
  integer, parameter :: device_id = 37
  integer(kind=4) :: seg(lseg)
  integer :: iary(16)
  real :: xary(16)
  character(len=32) :: info
  integer :: ugelv, ugeix
  character(len=8) :: ugenm
  common /ugerrd/ ugelv, ugenm, ugeix
  save /ugerrd/

  call query_open_devices(0, 0, 'before open')
  call query_active_device(0, 'before open')

  call uginit('CLEAR', seg, lseg)
  call require_clear_error('UGINIT')

  call ugopen('POSTSCR,DDNAME=lifecycle-output.ps', device_id)
  call require_clear_error('UGOPEN')

  call query_open_devices(1, device_id, 'after open')
  call query_active_device(device_id, 'after open')

  info = ''
  iary = 0
  xary = 0.0
  call uginfo('DEVTYPE', info, iary, xary)
  call require_clear_error('UGINFO DEVTYPE')
  if (info(1:8) /= 'POSTSCR ') then
    print *, 'UGINFO DEVTYPE after open: expected POSTSCR, got ', info(1:8)
    stop 1
  end if

  info = ''
  iary = 0
  xary = 0.0
  call uginfo('ILEVEL', info, iary, xary)
  call require_clear_error('UGINFO ILEVEL')
  if (iary(1) /= 1) then
    print *, 'UGINFO ILEVEL after open: expected 1, got ', iary(1)
    stop 1
  end if

  call ugclos(' ')
  call require_clear_error('UGCLOS')

  call query_open_devices(0, 0, 'after close')
  call query_active_device(0, 'after close')

  print *, 'POSTSCR lifecycle contract passed'

contains

  subroutine query_open_devices(expected_count, expected_id, phase)
    integer, intent(in) :: expected_count, expected_id
    character(len=*), intent(in) :: phase

    info = ''
    iary = 0
    xary = 0.0
    call uginfo('OPENDEV', info, iary, xary)
    call require_clear_error('UGINFO OPENDEV ' // phase)
    if (iary(1) /= expected_count) then
      print *, 'UGINFO OPENDEV ', phase, ': expected count ', expected_count, &
               ', got ', iary(1)
      stop 1
    end if
    if (expected_count > 0 .and. iary(2) /= expected_id) then
      print *, 'UGINFO OPENDEV ', phase, ': expected id ', expected_id, &
               ', got ', iary(2)
      stop 1
    end if
  end subroutine query_open_devices

  subroutine query_active_device(expected_id, phase)
    integer, intent(in) :: expected_id
    character(len=*), intent(in) :: phase

    info = ''
    iary = 0
    xary = 0.0
    call uginfo('ACTDEV', info, iary, xary)
    call require_clear_error('UGINFO ACTDEV ' // phase)
    if (iary(1) /= expected_id) then
      print *, 'UGINFO ACTDEV ', phase, ': expected id ', expected_id, &
               ', got ', iary(1)
      stop 1
    end if
  end subroutine query_active_device

  subroutine require_clear_error(phase)
    character(len=*), intent(in) :: phase

    if (ugelv /= 0 .or. ugeix /= 0 .or. ugenm /= '        ') then
      print *, trim(phase), ': expected clear UGS error state, got ', &
               ugelv, ' ', ugenm, ' ', ugeix
      stop 1
    end if
  end subroutine require_clear_error

end program postscript_lifecycle_contract
