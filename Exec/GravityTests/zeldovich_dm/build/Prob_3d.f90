

subroutine amrex_probinit (init, name, namlen, problo, probhi) bind(c)

    use amrex_fort_module, only : rt => amrex_real
    use probdata_module
    use comoving_module
    use eos_module, only : gamma_const
    use network   , only : network_init
    implicit none

    integer init, namlen
    integer name(namlen)
    real(rt) problo(3), probhi(3)

    integer untin, i

    namelist /fortin/ r_c, rho_c, comoving_OmB, comoving_OmM, comoving_OmL, &
                      comoving_h, max_num_part

!
!   Build "probin" filename -- the name of file containing fortin namelist.
!
    integer maxlen
    parameter (maxlen=256)
    character probin*(maxlen)

    call network_init()

    if (namlen .gt. maxlen) then
        write(6,*) 'probin file name too long'
        stop
    end if

    do i = 1, namlen
        probin(i:i) = char(name(i))
    end do

!   set namelist defaults

    rho_c = 1
    r_c   = 0.1

!   Read namelists
    untin = 9
    open(untin, file=probin(1:namlen), form='formatted', status='old')
    read(untin, fortin)
    close(unit=untin)

end

! ::: -----------------------------------------------------------
! ::: This routine is called at problem setup time and is used to
! ::: initialize data on each grid.
! :::
! ::: NOTE: all arrays have one cell of ghost zones surrounding
! :::       the grid interior. Values in these cells need not be
! :::       set here.
! :::
! ::: INPUTS/OUTPUTS:
! :::
! ::: level    => amr level of grid
! ::: time     => time at which to init data
! ::: lo, hi   => index limits of grid interior (cell centered)
! ::: nstate   => number of state components. You should know
! :::             this already!
! ::: state   <=  Scalar array
! ::: delta    => cell size
! ::: xlo, xhi => physical locations of lower left and upper
! :::             right hand corner of grid (does not include
! :::             ghost region).
! ::: -----------------------------------------------------------
      subroutine fort_initdata(level,time,lo,hi, &
                               ns, state   ,s_l1,s_l2,s_l3,s_h1,s_h2,s_h3, &
                               nd, diag_eos,d_l1,d_l2,d_l3,d_h1,d_h2,d_h3, &
                               delta,xlo,xhi)  &
                               bind(C, name="fort_initdata")

      use amrex_fort_module, only : rt => amrex_real
      use probdata_module
      use meth_params_module, only : NVAR, URHO, UMX, UMY, UMZ, UEDEN, UEINT, &
                                   UFS, UTEMP

      implicit none

      integer level, nscal
      integer lo(3), hi(3)
      integer state_l1, state_l2, state_l3, state_h1, state_h2, state_h3
      real(rt) xlo(3), xhi(3), time, delta(3)
      real(rt) state(state_l1:state_h1, state_l2:state_h2, &
                           state_l3:state_h3, NVAR)

      integer i, j, k

      rho_c = 1
      r_c   = 0.1

      do k = lo(3), hi(3)
        do j = lo(2), hi(2)
            do i = lo(1), hi(1)
                state(i,j,k,URHO) = 0.00000001d0
                state(i,j,k,UMX:UMZ) = 0.0d0

                state(i,j,k,UEINT) = 10.d0
                state(i,j,k,UEDEN) = state(i,j,k,UEINT) &
                                     + 0.5d0 / state(i,j,k,URHO) &
                                     * ( state(i,j,k,UMX)**2 &
                                         + state(i,j,k,UMY)**2 &
                                         + state(i,j,k,UMZ)**2 )
                state(i,j,k,UFS) = 1.d0 * state(i,j,k,URHO)
                state(i,j,k,UFS+1) = 0.d0 * state(i,j,k,URHO)
                state(i,j,k,UTEMP) = 0.d0
            enddo
        enddo
      enddo

      end subroutine fort_initdata
