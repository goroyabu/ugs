program extended_text_contract
  implicit none

  integer, parameter :: lseg = 20000
  integer, parameter :: nmax = 4096
  integer(kind=4) :: segment(lseg)
  integer(kind=4) :: blanking_bits((nmax + 31) / 32)
  real :: x(nmax), y(nmax)
  integer :: coordinate_count
  integer :: ugelv, ugeix
  character(len=8) :: ugenm
  character(len=32) :: mode
  character(len=64) :: output_file
  common /ugerrd/ ugelv, ugenm, ugeix
  save /ugerrd/

  if (command_argument_count() /= 2) then
    print *, 'usage: extended_text_contract MODE OUTPUT_FILE'
    stop 1
  end if
  call get_command_argument(1, mode)
  call get_command_argument(2, output_file)

  select case (trim(mode))
  case ('UGXTXT')
    call uginit('CLEAR', segment, lseg)
    call require_clear_error('UGXTXT UGINIT')
    call ugfont('DUPLEX')
    call require_clear_error('UGXTXT UGFONT')
    call ugxtxt('SIZE=0.1,FIXSIZE', 0.2, 0.3, 'AB', ' L', segment)
    call require_clear_error('UGXTXT text construction')
  case ('UGCTOL+UGPLIN')
    blanking_bits = 0
    call uginit('CLEAR', segment, lseg)
    call require_clear_error('UGCTOL UGINIT')
    call ugfont('DUPLEX')
    call require_clear_error('UGCTOL UGFONT')
    call ugctol('SIZE=0.1,FIXSIZE', 0.2, 0.3, 'AB', ' L', nmax, &
                x, y, coordinate_count, blanking_bits)
    call require_clear_error('UGCTOL text conversion')
    if (coordinate_count <= 0) then
      print *, 'UGCTOL text conversion: expected visible stroke coordinates'
      stop 1
    end if
    call ugplin(' ', x, y, coordinate_count, blanking_bits, &
                -coordinate_count, segment)
    call require_clear_error('UGPLIN text construction')
  case default
    print *, 'unknown extended text mode: ', trim(mode)
    stop 1
  end select

  call write_segment(trim(output_file), 51, segment, trim(mode))

  print *, trim(mode), ' extended text drawing contract passed'

contains

  subroutine write_segment(output_file, device_id, graphic_segment, phase)
    character(len=*), intent(in) :: output_file, phase
    integer, intent(in) :: device_id
    integer(kind=4), intent(in) :: graphic_segment(:)

    call ugopen('POSTSCR,DDNAME=' // trim(output_file) // &
                ',XMIN=150,XMAX=3150,YMIN=150,YMAX=2400,' // &
                'RUCMX=118.11024,RUCMY=118.11024', device_id)
    call require_clear_error(trim(phase) // ' UGOPEN')
    call ugslct(' ', device_id)
    call require_clear_error(trim(phase) // ' UGSLCT')
    call ugwrit(' ', 0, graphic_segment)
    call require_clear_error(trim(phase) // ' UGWRIT')
    call ugclos(' ')
    call require_clear_error(trim(phase) // ' UGCLOS')
  end subroutine write_segment

  subroutine require_clear_error(phase)
    character(len=*), intent(in) :: phase

    if (ugelv /= 0 .or. ugeix /= 0 .or. ugenm /= '        ') then
      print *, trim(phase), ': expected clear UGS error state, got ', &
               ugelv, ' ', ugenm, ' ', ugeix
      stop 1
    end if
  end subroutine require_clear_error

end program extended_text_contract
