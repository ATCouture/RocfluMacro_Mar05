










!*********************************************************************
!* Illinois Open Source License                                      *
!*                                                                   *
!* University of Illinois/NCSA                                       * 
!* Open Source License                                               *
!*                                                                   *
!* Copyright@2008, University of Illinois.  All rights reserved.     *
!*                                                                   *
!*  Developed by:                                                    *
!*                                                                   *
!*     Center for Simulation of Advanced Rockets                     *
!*                                                                   *
!*     University of Illinois                                        *
!*                                                                   *
!*     www.csar.uiuc.edu                                             *
!*                                                                   *
!* Permission is hereby granted, free of charge, to any person       *
!* obtaining a copy of this software and associated documentation    *
!* files (the "Software"), to deal with the Software without         *
!* restriction, including without limitation the rights to use,      *
!* copy, modify, merge, publish, distribute, sublicense, and/or      *
!* sell copies of the Software, and to permit persons to whom the    *
!* Software is furnished to do so, subject to the following          *
!* conditions:                                                       *
!*                                                                   *
!*                                                                   *
!* @ Redistributions of source code must retain the above copyright  * 
!*   notice, this list of conditions and the following disclaimers.  *
!*                                                                   * 
!* @ Redistributions in binary form must reproduce the above         *
!*   copyright notice, this list of conditions and the following     *
!*   disclaimers in the documentation and/or other materials         *
!*   provided with the distribution.                                 *
!*                                                                   *
!* @ Neither the names of the Center for Simulation of Advanced      *
!*   Rockets, the University of Illinois, nor the names of its       *
!*   contributors may be used to endorse or promote products derived * 
!*   from this Software without specific prior written permission.   *
!*                                                                   *
!* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,   *
!* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES   *
!* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND          *
!* NONINFRINGEMENT.  IN NO EVENT SHALL THE CONTRIBUTORS OR           *
!* COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER       * 
!* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   *
!* ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE    *
!* USE OR OTHER DEALINGS WITH THE SOFTWARE.                          *
!*********************************************************************
!* Please acknowledge The University of Illinois Center for          *
!* Simulation of Advanced Rockets in works and publications          *
!* resulting from this software or its derivatives.                  *
!*********************************************************************
! ******************************************************************************
!
! Purpose: Set explicit interfaces to subroutines and functions.
!
! Description: None
!
! Notes: None.
!
! ******************************************************************************
!
! $Id: ModInterfacesSpecies.F90,v 1.1.1.1 2015/01/23 22:57:50 tbanerjee Exp $
!
! Copyright: (c) 2002-2006 by the University of Illinois
!
! ******************************************************************************

MODULE ModInterfacesSpecies

  IMPLICIT NONE

  INTERFACE

! ==============================================================================
!   Common routines
! ==============================================================================

    SUBROUTINE SPEC_BuildVersionString(versionString)
      CHARACTER(*) :: versionString
    END SUBROUTINE SPEC_BuildVersionString

    FUNCTION SPEC_GetSpeciesIndex(global,pSpecInput,name)
      USE ModGlobal,    ONLY : t_global
      USE ModSpecies, ONLY: t_spec_input
      TYPE(t_global), POINTER :: global
      TYPE(t_spec_input), POINTER :: pSpecInput
      CHARACTER(*), INTENT(in) :: name
      INTEGER :: SPEC_GetSpeciesIndex
    END FUNCTION SPEC_GetSpeciesIndex

    SUBROUTINE SPEC_PrintUserInput(region)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region) :: region
    END SUBROUTINE SPEC_PrintUserInput

    SUBROUTINE SPEC_UpdateDependentVars(pRegion,icgBeg,icgEnd)
      USE ModDataStruct, ONLY : t_region
      INTEGER, INTENT(IN) :: icgBeg,icgEnd        
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_UpdateDependentVars

    SUBROUTINE SPEC_UserInput(regions)
      USE ModDataStruct, ONLY : t_region    
      TYPE(t_region), POINTER :: regions(:)
    END SUBROUTINE SPEC_UserInput

! ==============================================================================
!   Rocflu-specific routines
! ==============================================================================

    SUBROUTINE SPEC_EqEulCorr(pRegion,iSpec)
      USE ModDataStruct, ONLY : t_region
      INTEGER, INTENT(IN) :: iSpec
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_EqEulCorr

    SUBROUTINE SPEC_RFLU_AllocateMemory(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_AllocateMemory

    SUBROUTINE SPEC_RFLU_AllocateMemoryEEv(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_AllocateMemoryEEv

    SUBROUTINE SPEC_RFLU_AllocateMemorySol(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_AllocateMemorySol

    SUBROUTINE SPEC_RFLU_AllocateMemoryTStep(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_AllocateMemoryTStep

    SUBROUTINE SPEC_RFLU_AllocateMemoryVert(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_AllocateMemoryVert

    SUBROUTINE SPEC_RFLU_DeallocateMemory(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_DeallocateMemory

    SUBROUTINE SPEC_RFLU_DeallocateMemoryEEv(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_DeallocateMemoryEEv
    
    SUBROUTINE SPEC_RFLU_DeallocateMemorySol(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_DeallocateMemorySol

    SUBROUTINE SPEC_RFLU_DeallocateMemoryTStep(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_DeallocateMemoryTStep

    SUBROUTINE SPEC_RFLU_DeallocateMemoryVert(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_DeallocateMemoryVert

    SUBROUTINE SPEC_RFLU_EnforceBounds(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_EnforceBounds

    SUBROUTINE SPEC_RFLU_InitFlowHardCode(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_InitFlowHardCode

    SUBROUTINE SPEC_RFLU_InitFlowScratch(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_InitFlowScratch

    SUBROUTINE SPEC_RFLU_PrintFlowInfo(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_PrintFlowInfo

    SUBROUTINE SPEC_RFLU_ReadBcInputFile(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_ReadBcInputFile

    SUBROUTINE SPEC_RFLU_ReadBcFarfSection(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_ReadBcFarfSection

    SUBROUTINE SPEC_RFLU_ReadBcInflowSection(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_ReadBcInflowSection

    SUBROUTINE SPEC_RFLU_ReadBcInjectSection(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_ReadBcInjectSection

    SUBROUTINE SPEC_RFLU_ReadBcSectionDummy(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_ReadBcSectionDummy
    
    SUBROUTINE SPEC_RFLU_SetEEv(pRegion,iSpec)
      USE ModDataStruct, ONLY : t_region
      INTEGER, INTENT(IN) :: iSpec
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_SetEEv

    SUBROUTINE SPEC_RFLU_SetVarInfo(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_SetVarInfo

    SUBROUTINE SPEC_RFLU_SourceTerms_GL(pRegion)
      USE ModDataStruct, ONLY : t_region
      TYPE(t_region), POINTER :: pRegion
    END SUBROUTINE SPEC_RFLU_SourceTerms_GL

  END INTERFACE

END MODULE ModInterfacesSpecies

! ******************************************************************************
!
! RCS Revision history:
!
! $Log: ModInterfacesSpecies.F90,v $
! Revision 1.1.1.1  2015/01/23 22:57:50  tbanerjee
! merged rocflu micro and macro
!
! Revision 1.1.1.1  2014/07/15 14:31:37  brollin
! New Stable version
!
! Revision 1.3  2008/12/06 08:43:37  mtcampbe
! Updated license.
!
! Revision 1.2  2008/11/19 22:16:52  mtcampbe
! Added Illinois Open Source License/Copyright
!
! Revision 1.1  2007/04/09 18:49:10  haselbac
! Initial revision after split from RocfloMP
!
! Revision 1.1  2007/04/09 18:00:17  haselbac
! Initial revision after split from RocfloMP
!
! Revision 1.11  2006/03/26 20:21:55  haselbac
! Added if for new routine
!
! Revision 1.10  2005/11/27 01:50:27  haselbac
! Added IFs for EEv routines, removed IFs for {Read/Write}Flow routines
!
! Revision 1.9  2005/04/15 15:06:31  haselbac
! Removed and updated interfaces, cosmetics
!
! Revision 1.8  2005/03/31 16:53:39  haselbac
! Added interface for SPEC_RFLU_ReadBcSectionDummy
!
! Revision 1.7  2004/12/01 00:09:31  wasistho
! added BuildVersionString
!
! Revision 1.6  2004/11/14 19:45:06  haselbac
! Changed interface
!
! Revision 1.5  2004/11/02 02:28:55  haselbac
! Added interface for SPEC_RFLU_SetVarInfo
!
! Revision 1.4  2004/07/30 22:47:35  jferry
! Implemented Equilibrium Eulerian method for Rocflu
!
! Revision 1.3  2004/01/29 22:57:25  haselbac
! Added interfaces for new routines
!
! Revision 1.2  2003/11/25 21:03:12  haselbac
! Added interfaces for new routines
!
! Revision 1.1  2002/12/27 22:07:14  jblazek
! Splitted up RFLO_ModInterfaces and ModInterfaces.
!
! ******************************************************************************

