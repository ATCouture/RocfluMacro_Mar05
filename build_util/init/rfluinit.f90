










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
! Purpose: Driver routine for rfluinit. 
!
! Description: None.
!
! Input: 
!   caseString  String with casename
!   verbLevel   Verbosity level
!
! Output: None.
!
! Notes: None.
!
! ******************************************************************************
!
! $Id: rfluinit.F90,v 1.4 2015/08/12 19:41:43 brollin Exp $
!
! Copyright: (c) 2004-2005 by the University of Illinois
!
! ******************************************************************************

SUBROUTINE rfluinit(caseString,verbLevel)

  USE ModError
  USE ModDataTypes
  USE ModParameters  
  USE ModGlobal, ONLY: t_global
  USE ModDataStruct, ONLY: t_level,t_region
  USE ModMPI
  
  USE RFLU_ModAllocateMemory
  USE RFLU_ModAxisymmetry, ONLY: RFLU_AXI_ScaleGeometry
  USE RFLU_ModBoundLists
  USE RFLU_ModBoundXvUtils 
  USE RFLU_ModNSCBC, ONLY: RFLU_NSCBC_DecideHaveNSCBC
  USE RFLU_ModCellMapping
  USE RFLU_ModDeallocateMemory
  USE RFLU_ModDimensions
  USE RFLU_ModFaceList
  USE RFLU_ModGeometry
  USE RFLU_ModHouMahesh, ONLY: RFLU_HM_ConvCvD2ND
  USE RFLU_ModGridSpeedUtils
  USE RFLU_ModMovingFrame
  USE RFLU_ModReadBcInputFile
  USE RFLU_ModReadWriteAuxVars
  USE RFLU_ModReadWriteBcDataFile
  USE RFLU_ModReadWriteFlow
  USE RFLU_ModReadWriteGrid
  USE RFLU_ModReadWriteGridSpeeds
  USE RFLU_ModRegionMapping
  USE RFLU_ModRenumberings


  USE ModInterfaces, ONLY: RFLU_AllocMemSolWrapper, & 
                           RFLU_BuildDataStruct, &   
                           RFLU_ComputeGridSpacingCyldet, &
                           RFLU_ComputeGridSpacingShktb, &
                           RFLU_CreateGrid, & 
                           RFLU_DeallocMemSolWrapper, & 
                           RFLU_DestroyGrid, &
                           RFLU_GetUserInput, &
                           RFLU_InitAuxVars, &
                           RFLU_InitGlobal, &
                           RFLU_InitBcDataHardCode, & 
                           RFLU_InitFlowHardCodeLimWrapper, &  
                           RFLU_InitFlowHardCodeWrapper, & 
                           RFLU_InitFlowScratchWrapper, &
                           RFLU_InitFlowSerialWrapper, & 
                           RFLU_PrintFlowInfoWrapper, & 
                           RFLU_PrintGridInfo, & 
                           RFLU_PrintHeader, & 
                           RFLU_PrintWarnInfo, &
                           RFLU_RandomInit, &
                           RFLU_ReadRestartInfo, & 
                           RFLU_SetDependentVars, &
                           RFLU_SetModuleType, &  
                           RFLU_SetRestartTimeFlag, &
                           RFLU_SetVarInfoWrapper, & 
                           RFLU_WriteVersionString, &
                           ScaleRotateVector
                           


  IMPLICIT NONE


! ******************************************************************************
! Definitions and declarations
! ******************************************************************************

! ==============================================================================
! Arguments
! ==============================================================================

  CHARACTER(*) :: caseString
  INTEGER, INTENT(IN) :: verbLevel

! ==============================================================================
! Locals
! ==============================================================================

  CHARACTER(CHRLEN) :: casename
  INTEGER :: errorFlag,iLev,iReg,iRegLow,iRegUpp
  TYPE(t_region), POINTER :: pRegion,pRegionSerial
  TYPE(t_global), POINTER :: global
  TYPE(t_level), POINTER :: levels(:)

! ******************************************************************************
! Initialize global data
! ******************************************************************************  
  
  ALLOCATE(global,STAT=errorFlag)
  IF ( errorFlag /= ERR_NONE ) THEN 
    WRITE(STDERR,'(A,1X,A)') SOLVER_NAME,'ERROR - Pointer allocation failed.'
    STOP
  END IF ! errorFlag 

  casename = caseString(1:LEN(caseString))
  
  CALL RFLU_InitGlobal(casename,verbLevel,MPI_COMM_WORLD,global)

  CALL RegisterFunction(global,'rfluinit', & 
                        "../../utilities/init/rfluinit.F90")

  CALL RFLU_SetModuleType(global,MODULE_TYPE_INIT)


! ******************************************************************************
! Print header and write version string
! ******************************************************************************

  IF ( global%myProcid == MASTERPROC ) THEN
    CALL RFLU_WriteVersionString(global)     
    IF ( global%verbLevel /= VERBOSE_NONE ) THEN
      CALL RFLU_PrintHeader(global)
    END IF ! global%verbLevel
  END IF ! global%myProcid

! ******************************************************************************
! Read mapping file, impose serial mapping, and build basic data structure
! ******************************************************************************

  CALL RFLU_ReadRegionMappingFile(global,MAPFILE_READMODE_PEEK,global%myProcId)
  CALL RFLU_SetRegionMappingSerial(global)  
  CALL RFLU_CreateRegionMapping(global,MAPTYPE_REG)
  CALL RFLU_ImposeRegionMappingSerial(global)

  CALL RFLU_BuildDataStruct(global,levels) 
  CALL RFLU_ApplyRegionMapping(global,levels)
  CALL RFLU_DestroyRegionMapping(global,MAPTYPE_REG)  


! Subbu - Need to read random seed after reading from input file
! Therefore reading has been pushed below 
! ******************************************************************************
! Initialize random number generator. NOTE needed in order to write sensible 
! data when writing Rocpart solution files. 
! ******************************************************************************

!  CALL RFLU_RandomInit(levels(1)%regions)

! ******************************************************************************
! Read input file and restart info. NOTE need restart info for GENX runs to 
! determine whether have a restart. 
! ******************************************************************************

  CALL RFLU_GetUserInput(levels(1)%regions,.TRUE.) 
  CALL RFLU_ReadRestartInfo(global)
  CALL RFLU_SetRestartTimeFlag(global)

! Subbu - Read random seed after reading from input file
! ******************************************************************************
! Initialize random number generator. NOTE needed in order to write sensible 
! data when writing Rocpart solution files. 
! ******************************************************************************

  CALL RFLU_RandomInit(levels(1)%regions)

! ******************************************************************************
! Initialize solutions
! ******************************************************************************

  IF ( global%nRegions == 1 ) THEN 
    iRegLow = 0
    iRegUpp = 0
  ELSE 
    iRegLow = 1
    iRegUpp = global%nRegions
  END IF ! global%nRegions


! ==============================================================================
! Creating and init particle velocity and acceleration
! ==============================================================================

  IF ( global%mvFrameFlag .EQV. .TRUE. ) THEN
    DO iReg = iRegLow,iRegUpp
      pRegion => levels(1)%regions(iReg)

      CALL RFLU_MVF_CreatePatchVelAccel(pRegion)
      CALL RFLU_MVF_InitPatchVelAccel(pRegion)
    END DO ! iReg
  END IF ! global%mvFrameFlag

! ==============================================================================
! Initialize Eulerian solution fields
! ==============================================================================

  SELECT CASE ( global%initFlowFlag ) 
    
! ------------------------------------------------------------------------------
!   Initialize from scratch
! ------------------------------------------------------------------------------

    CASE ( INITFLOW_FROMSCRATCH )
      DO iReg = iRegLow,iRegUpp
        pRegion => levels(1)%regions(iReg)

        CALL RFLU_ReadDimensions(pRegion)                          
        CALL RFLU_CreateGrid(pRegion)

        IF ( pRegion%grid%nPatches > 0 ) THEN        
          CALL RFLU_ReadBCInputFileWrapper(pRegion)    
        END IF ! pRegion%grid%nPatches                   

        IF ( RFLU_NSCBC_DecideHaveNSCBC(pRegion) .EQV. .TRUE. ) THEN
          CALL RFLU_ReadGridWrapper(pRegion)

          CALL RFLU_CreateCellMapping(pRegion)
          CALL RFLU_ReadLoc2GlobCellMapping(pRegion)
          CALL RFLU_BuildGlob2LocCellMapping(pRegion)         

          CALL RFLU_CreateBVertexLists(pRegion)
          CALL RFLU_BuildBVertexLists(pRegion)

          CALL RFLU_CreateFaceList(pRegion)
          CALL RFLU_BuildFaceList(pRegion)
          CALL RFLU_RenumberBFaceLists(pRegion)

          CALL RFLU_CreateGeometry(pRegion)
          CALL RFLU_BuildGeometry(pRegion)
        END IF ! RFLU_NSCBC_DecideHaveNSCBC

        CALL RFLU_AllocMemSolWrapper(pRegion)  
        CALL RFLU_SetVarInfoWrapper(pRegion) 

        CALL RFLU_InitFlowScratchWrapper(pRegion)

        IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
          CALL RFLU_InitAuxVars(pRegion)
        END IF ! solverType

        IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
          CALL RFLU_HM_ConvCvD2ND(pRegion)
        END IF ! solverType

        CALL RFLU_SetDependentVars(pRegion,1,pRegion%grid%nCellsTot)

! Initializing boundary array would need solution in domain to be initialized first
        IF ( RFLU_NSCBC_DecideHaveNSCBC(pRegion) .EQV. .TRUE. ) THEN
          CALL RFLU_BXV_CreateVarsCv(pRegion)
          CALL RFLU_BXV_CreateVarsDv(pRegion)
          CALL RFLU_BXV_InitVars(pRegion)
          CALL RFLU_BXV_WriteVarsWrapper(pRegion)
          CALL RFLU_BXV_DestroyVarsCv(pRegion)
          CALL RFLU_BXV_DestroyVarsDv(pRegion)
        END IF ! RFLU_NSCBC_DecideHaveNSCBC

! Modify flow field for moving reference frame attached to moving particle
        IF ( global%mvFrameFlag .EQV. .TRUE. ) THEN
          CALL RFLU_MVF_ModifyFlowField(pRegion)
        END IF ! global%mvFrameFlag

        IF ( global%verbLevel > VERBOSE_NONE ) THEN   
          CALL RFLU_PrintFlowInfoWrapper(pRegion)    
        END IF ! global%verbLevel       

        CALL RFLU_WriteFlowWrapper(pRegion)

        IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
          CALL RFLU_WriteAuxVarsWrapper(pRegion)
        END IF ! solverType

        IF ( RFLU_NSCBC_DecideHaveNSCBC(pRegion) .EQV. .TRUE. ) THEN
          CALL RFLU_DestroyFaceList(pRegion)
          CALL RFLU_DestroyBVertexLists(pRegion)    
          CALL RFLU_DestroyCellMapping(pRegion)
          CALL RFLU_DestroyGeometry(pRegion)  
        END IF ! RFLU_NSCBC_DecideHaveNSCBC

        CALL RFLU_DeallocMemSolWrapper(pRegion)
        CALL RFLU_DestroyGrid(pRegion)
      END DO ! iReg  

! ------------------------------------------------------------------------------
!   Initialize parallel run by reading solution from serial file.
! ------------------------------------------------------------------------------
  
    CASE ( INITFLOW_FROMFILE ) 
      IF ( global%nRegions > 1 ) THEN 
        pRegionSerial => levels(1)%regions(0)

! ----- Read serial solution ---------------------------------------------------

        CALL RFLU_ReadDimensions(pRegionSerial)               
        CALL RFLU_CreateGrid(pRegionSerial)

        IF ( pRegionSerial%grid%nPatches > 0 ) THEN        
          CALL RFLU_ReadBCInputFileWrapper(pRegionSerial)    
        END IF ! pRegionSerial%grid%nPatches         

        CALL RFLU_AllocMemSolWrapper(pRegionSerial)  
        CALL RFLU_SetVarInfoWrapper(pRegionSerial)     

        CALL RFLU_ReadFlowWrapper(pRegionSerial)

        IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
          CALL RFLU_ReadAuxVarsWrapper(pRegionSerial)
        END IF ! solverType

! ----- Loop over regions and initialize ---------------------------------------

        DO iReg = 1,global%nRegions
          pRegion => levels(1)%regions(iReg)

          CALL RFLU_ReadDimensionsWrapper(pRegion)               
          CALL RFLU_CreateGrid(pRegion)

          IF ( pRegion%grid%nPatches > 0 ) THEN        
            CALL RFLU_ReadBCInputFileWrapper(pRegion)    
          END IF ! pRegion%grid%nPatches         

          CALL RFLU_AllocMemSolWrapper(pRegion)  
          CALL RFLU_SetVarInfoWrapper(pRegion)

          CALL RFLU_RNMB_CreatePC2SCMap(pRegion)    
          CALL RFLU_RNMB_CreatePV2SVMap(pRegion)
          CALL RFLU_RNMB_CreatePBF2SBFMap(pRegion)

          CALL RFLU_RNMB_ReadPxx2SxxMaps(pRegion)

          CALL RFLU_RNMB_DestroyPV2SVMap(pRegion)
          CALL RFLU_RNMB_DestroyPBF2SBFMap(pRegion)        

          CALL RFLU_InitFlowSerialWrapper(pRegion,pRegionSerial)

! Modify flow field for moving reference frame attached to moving particle
          IF ( global%mvFrameFlag .EQV. .TRUE. ) THEN
            CALL RFLU_MVF_ModifyFlowField(pRegion)
          END IF ! global%mvFrameFlag

          IF ( global%verbLevel > VERBOSE_NONE ) THEN   
            CALL RFLU_PrintFlowInfoWrapper(pRegion)    
          END IF ! global%verbLevel  

          CALL RFLU_WriteFlowWrapper(pRegion)

          IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
            CALL RFLU_WriteAuxVarsWrapper(pRegion)
          END IF ! solverType

          CALL RFLU_RNMB_DestroyPC2SCMap(pRegion)               
          CALL RFLU_DeallocMemSolWrapper(pRegion) 
          CALL RFLU_DestroyGrid(pRegion) 
        END DO ! iReg

! ----- Deallocate memory ------------------------------------------------------

        CALL RFLU_DeallocMemSolWrapper(pRegionSerial) 
        CALL RFLU_DestroyGrid(pRegionSerial)    
      END IF ! global%nRegions

! ------------------------------------------------------------------------------
!   Initialize from hardcode
! ------------------------------------------------------------------------------

    CASE ( INITFLOW_FROMHARDCODE ) 
      DO iReg = iRegLow,iRegUpp
        pRegion => levels(1)%regions(iReg)

        CALL RFLU_ReadDimensions(pRegion)               
        CALL RFLU_CreateGrid(pRegion)

        IF ( pRegion%grid%nPatches > 0 ) THEN        
          CALL RFLU_ReadBCInputFileWrapper(pRegion)    
        END IF ! pRegion%grid%nPatches       


        CALL RFLU_ReadGridWrapper(pRegion)

        IF ( global%verbLevel > VERBOSE_LOW ) THEN 
          CALL RFLU_PrintGridInfo(pRegion)
        END IF ! global%verbLevel 


        CALL RFLU_CreateCellMapping(pRegion)
        CALL RFLU_ReadLoc2GlobCellMapping(pRegion)
        CALL RFLU_BuildGlob2LocCellMapping(pRegion)         

        CALL RFLU_CreateBVertexLists(pRegion)
        CALL RFLU_BuildBVertexLists(pRegion)

        CALL RFLU_CreateFaceList(pRegion)
        CALL RFLU_BuildFaceList(pRegion)
        CALL RFLU_RenumberBFaceLists(pRegion)

        CALL RFLU_CreateGeometry(pRegion)    
        CALL RFLU_BuildGeometry(pRegion)   

        CALL RFLU_AllocMemSolWrapper(pRegion)  
        CALL RFLU_SetVarInfoWrapper(pRegion) 
        
        CALL RFLU_InitFlowHardCodeWrapper(pRegion)

        IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
          CALL RFLU_HM_ConvCvD2ND(pRegion)
        END IF ! solverType

        IF ( RFLU_DecideReadWriteBcDataFile(pRegion) .EQV. .TRUE. ) THEN
          CALL RFLU_InitBcDataHardCode(pRegion)      
        END IF ! RFLU_DecideReadWriteBcDataFile      

        CALL RFLU_SetDependentVars(pRegion,1,pRegion%grid%nCellsTot)

        IF ( RFLU_NSCBC_DecideHaveNSCBC(pRegion) .EQV. .TRUE. ) THEN
          CALL RFLU_BXV_CreateVarsCv(pRegion)
          CALL RFLU_BXV_CreateVarsDv(pRegion)
          CALL RFLU_BXV_InitVars(pRegion)
          CALL RFLU_BXV_WriteVarsWrapper(pRegion)
          CALL RFLU_BXV_DestroyVarsCv(pRegion)
          CALL RFLU_BXV_DestroyVarsDv(pRegion)
        END IF ! RFLU_NSCBC_DecideHaveNSCBC

! Modify flow field for moving reference frame attached to moving particle
        IF ( global%mvFrameFlag .EQV. .TRUE. ) THEN
          CALL RFLU_MVF_ModifyFlowField(pRegion)
        END IF ! global%mvFrameFlag

        IF ( global%verbLevel > VERBOSE_NONE ) THEN   
          CALL RFLU_PrintFlowInfoWrapper(pRegion)    
        END IF ! global%verbLevel       

        CALL RFLU_WriteFlowWrapper(pRegion)       

        IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
          CALL RFLU_WriteAuxVarsWrapper(pRegion)
        END IF ! solverType

        IF ( RFLU_DecideReadWriteBcDataFile(pRegion) .EQV. .TRUE. ) THEN
          CALL RFLU_WriteBcDataFile(pRegion)
        END IF ! RFLU_DecideReadWriteBcDataFile

        CALL RFLU_DestroyGeometry(pRegion)  
        CALL RFLU_DestroyFaceList(pRegion)
        CALL RFLU_DestroyBVertexLists(pRegion)    
        CALL RFLU_DestroyCellMapping(pRegion)
        CALL RFLU_DeallocMemSolWrapper(pRegion)
        CALL RFLU_DestroyGrid(pRegion)                                  
      END DO ! iReg   

! ------------------------------------------------------------------------------
!   Initialize parallel run from combo using serial solution
! ------------------------------------------------------------------------------
  
    CASE ( INITFLOW_FROMCOMBO_SERIAL ) 
      IF ( global%nRegions > 1 ) THEN 
        pRegionSerial => levels(1)%regions(0)

! ----- Read serial solution ---------------------------------------------------

        CALL RFLU_ReadDimensions(pRegionSerial)               
        CALL RFLU_CreateGrid(pRegionSerial)

        IF ( pRegionSerial%grid%nPatches > 0 ) THEN        
          CALL RFLU_ReadBCInputFileWrapper(pRegionSerial)    
        END IF ! pRegionSerial%grid%nPatches         

        CALL RFLU_AllocMemSolWrapper(pRegionSerial)  
        CALL RFLU_SetVarInfoWrapper(pRegionSerial)     

        CALL RFLU_ReadFlowWrapper(pRegionSerial)

        IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
          CALL RFLU_ReadAuxVarsWrapper(pRegionSerial)
        END IF ! solverType

! ----- Loop over regions and initialize ---------------------------------------

        DO iReg = 1,global%nRegions
          pRegion => levels(1)%regions(iReg)

          CALL RFLU_ReadDimensionsWrapper(pRegion)               
          CALL RFLU_CreateGrid(pRegion)

          IF ( pRegion%grid%nPatches > 0 ) THEN        
            CALL RFLU_ReadBCInputFileWrapper(pRegion)    
          END IF ! pRegion%grid%nPatches         

          CALL RFLU_ReadGridWrapper(pRegion)

          IF ( global%verbLevel > VERBOSE_LOW ) THEN 
            CALL RFLU_PrintGridInfo(pRegion)
          END IF ! global%verbLevel 

          CALL RFLU_AllocMemSolWrapper(pRegion)  
          CALL RFLU_SetVarInfoWrapper(pRegion)

          CALL RFLU_RNMB_CreatePC2SCMap(pRegion)    
          CALL RFLU_RNMB_CreatePV2SVMap(pRegion)
          CALL RFLU_RNMB_CreatePBF2SBFMap(pRegion)

          CALL RFLU_RNMB_ReadPxx2SxxMaps(pRegion)

          CALL RFLU_RNMB_DestroyPV2SVMap(pRegion)
          CALL RFLU_RNMB_DestroyPBF2SBFMap(pRegion)        

          CALL RFLU_InitFlowSerialWrapper(pRegion,pRegionSerial)
          
          CALL RFLU_CreateCellMapping(pRegion)
          CALL RFLU_ReadLoc2GlobCellMapping(pRegion)
          CALL RFLU_BuildGlob2LocCellMapping(pRegion)         

          CALL RFLU_CreateBVertexLists(pRegion)
          CALL RFLU_BuildBVertexLists(pRegion)

          CALL RFLU_CreateFaceList(pRegion)
          CALL RFLU_BuildFaceList(pRegion)
          CALL RFLU_RenumberBFaceLists(pRegion)

          CALL RFLU_CreateGeometry(pRegion)    
          CALL RFLU_BuildGeometry(pRegion)
                  
          CALL RFLU_InitFlowHardCodeLimWrapper(pRegion)

! Modify flow field for moving reference frame attached to moving particle
          IF ( global%mvFrameFlag .EQV. .TRUE. ) THEN
            CALL RFLU_MVF_ModifyFlowField(pRegion)
          END IF ! global%mvFrameFlag

          CALL RFLU_DestroyGeometry(pRegion)  
          CALL RFLU_DestroyFaceList(pRegion)
          CALL RFLU_DestroyBVertexLists(pRegion)    
          CALL RFLU_DestroyCellMapping(pRegion)

          IF ( global%verbLevel > VERBOSE_NONE ) THEN   
            CALL RFLU_PrintFlowInfoWrapper(pRegion)    
          END IF ! global%verbLevel  

          CALL RFLU_WriteFlowWrapper(pRegion)

          IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
            CALL RFLU_WriteAuxVarsWrapper(pRegion)
          END IF ! solverType

          CALL RFLU_RNMB_DestroyPC2SCMap(pRegion)               
          CALL RFLU_DeallocMemSolWrapper(pRegion) 
          CALL RFLU_DestroyGrid(pRegion) 
        END DO ! iReg

! ----- Deallocate memory ------------------------------------------------------

        CALL RFLU_DeallocMemSolWrapper(pRegionSerial) 
        CALL RFLU_DestroyGrid(pRegionSerial)    
      END IF ! global%nRegions

! ------------------------------------------------------------------------------
!   Initialize parallel run from combo using parallel solution
! ------------------------------------------------------------------------------
  
    CASE ( INITFLOW_FROMCOMBO_PARALLEL ) 

! --- Loop over regions and initialize -----------------------------------------

      DO iReg = 1,global%nRegions
        pRegion => levels(1)%regions(iReg)

        CALL RFLU_ReadDimensionsWrapper(pRegion)               
        CALL RFLU_CreateGrid(pRegion)

        IF ( pRegion%grid%nPatches > 0 ) THEN        
          CALL RFLU_ReadBCInputFileWrapper(pRegion)    
        END IF ! pRegion%grid%nPatches         

        CALL RFLU_ReadGridWrapper(pRegion)

        IF ( global%verbLevel > VERBOSE_LOW ) THEN 
          CALL RFLU_PrintGridInfo(pRegion)
        END IF ! global%verbLevel 

        CALL RFLU_AllocMemSolWrapper(pRegion)  
        CALL RFLU_SetVarInfoWrapper(pRegion)

        CALL RFLU_ReadFlowWrapper(pRegion)

        IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
          CALL RFLU_ReadAuxVarsWrapper(pRegion)
        END IF ! solverType

        CALL RFLU_CreateCellMapping(pRegion)
        CALL RFLU_ReadLoc2GlobCellMapping(pRegion)
        CALL RFLU_BuildGlob2LocCellMapping(pRegion)         

        CALL RFLU_CreateBVertexLists(pRegion)
        CALL RFLU_BuildBVertexLists(pRegion)

        CALL RFLU_CreateFaceList(pRegion)
        CALL RFLU_BuildFaceList(pRegion)
        CALL RFLU_RenumberBFaceLists(pRegion)

        CALL RFLU_CreateGeometry(pRegion)    
        CALL RFLU_BuildGeometry(pRegion)

        CALL RFLU_InitFlowHardCodeLimWrapper(pRegion)

! Modify flow field for moving reference frame attached to moving particle
        IF ( global%mvFrameFlag .EQV. .TRUE. ) THEN
          CALL RFLU_MVF_ModifyFlowField(pRegion)
        END IF ! global%mvFrameFlag

        CALL RFLU_DestroyGeometry(pRegion)  
        CALL RFLU_DestroyFaceList(pRegion)
        CALL RFLU_DestroyBVertexLists(pRegion)    
        CALL RFLU_DestroyCellMapping(pRegion)

        IF ( global%verbLevel > VERBOSE_NONE ) THEN   
          CALL RFLU_PrintFlowInfoWrapper(pRegion)    
        END IF ! global%verbLevel  

        CALL RFLU_WriteFlowWrapper(pRegion)
      
        IF ( global%solverType == SOLV_IMPLICIT_HM ) THEN
          CALL RFLU_WriteAuxVarsWrapper(pRegion)
        END IF ! solverType

        CALL RFLU_DeallocMemSolWrapper(pRegion) 
        CALL RFLU_DestroyGrid(pRegion) 
      END DO ! iReg    

! ------------------------------------------------------------------------------
!   Default
! ------------------------------------------------------------------------------
  
    CASE DEFAULT 
      CALL ErrorStop(global,ERR_REACHED_DEFAULT,838)
  END SELECT ! global%initFlowFlag  

! ==============================================================================
! Writing and destroying particle velocity and acceleration
! ==============================================================================

  IF ( global%mvFrameFlag .EQV. .TRUE. ) THEN
    pRegion => levels(1)%regions(iRegLow)

    IF ( pRegion%global%myProcid == MASTERPROC ) THEN
      CALL RFLU_MVF_WritePatchVelAccel(pRegion)
    END IF ! pRegion%global%myProcid

    DO iReg = iRegLow,iRegUpp
      pRegion => levels(1)%regions(iReg)

      CALL RFLU_MVF_DestroyPatchVelAccel(pRegion)
    END DO ! iReg
  END IF ! global%mvFrameFlag


! ******************************************************************************
! Write grid speed files. NOTE separated from above because need number of 
! faces, which is not always known above.
! ******************************************************************************

  DO iReg = iRegLow,iRegUpp
    pRegion => levels(1)%regions(iReg)

    IF ( RFLU_DecideNeedGridSpeeds(pRegion) .EQV. .TRUE. ) THEN 
      CALL RFLU_ReadDimensions(pRegion)                          
      CALL RFLU_CreateGrid(pRegion)

      IF ( pRegion%grid%nPatches > 0 ) THEN        
        CALL RFLU_ReadBCInputFileWrapper(pRegion)    
      END IF ! pRegion%grid%nPatches                   


      CALL RFLU_ReadGridWrapper(pRegion)


      CALL RFLU_CreateCellMapping(pRegion)
      CALL RFLU_ReadLoc2GlobCellMapping(pRegion)
      CALL RFLU_BuildGlob2LocCellMapping(pRegion)         

      CALL RFLU_CreateBVertexLists(pRegion)
      CALL RFLU_BuildBVertexLists(pRegion)

      CALL RFLU_CreateFaceList(pRegion)
      CALL RFLU_BuildFaceList(pRegion)
      CALL RFLU_RenumberBFaceLists(pRegion)

      CALL RFLU_AllocateMemoryGSpeeds(pRegion)
      CALL RFLU_WriteGridSpeedsWrapper(pRegion)

      CALL RFLU_DeallocateMemoryGSpeeds(pRegion) 

      CALL RFLU_DestroyFaceList(pRegion)
      CALL RFLU_DestroyBVertexLists(pRegion)    
      CALL RFLU_DestroyCellMapping(pRegion) 
      CALL RFLU_DestroyGrid(pRegion)  

    END IF ! RFLU_DecideNeedGridSpeeds 
  END DO ! iReg  

! ******************************************************************************
! Print info about warnings
! ******************************************************************************
 
  CALL RFLU_PrintWarnInfo(global)
                              
! ******************************************************************************
! End
! ******************************************************************************

  CALL DeregisterFunction(global)

END SUBROUTINE rfluinit

! ******************************************************************************
!
! RCS Revision history:
!
! $Log: rfluinit.F90,v $
! Revision 1.4  2015/08/12 19:41:43  brollin
! Updating module declaration in rfluinit.F90
!
! Revision 1.3  2015/07/27 04:45:42  brollin
! 1) Corrected bug in RFLUCONV where global%gridFormat was used instead of global%gridSrcFormat
! 2) Implemented new subroutine for shock tube problems (Shktb)
!
! Revision 1.2  2015/07/23 23:11:19  brollin
! 1) The pressure coefficient of the  collision model has been changed back to its original form
! 2) New options in the format of the grid and solutions have been added. Now the user can choose the endianness, and convert from one to the over in rfluconv.
! 3) The solutions are now stored in folders named by timestamp or iteration number.
! 4) The address enty in the hashtable has been changed to an integer(8) for cases when the grid becomes very large.
! 5) RFLU_WritePM can now compute PM2 on the fly for the Macroscale problem
!
! Revision 1.1.1.1  2015/01/23 22:57:50  tbanerjee
! merged rocflu micro and macro
!
! Revision 1.2  2014/07/21 16:44:23  subbu
! Added capability to initialize lagrangian particles from ASCII file
! via subroutine PLAG_RFLU_InitSolutionFile
!
! Revision 1.1.1.1  2014/05/05 21:47:47  tmish
! Initial checkin for rocflu macro.
!
! Revision 1.7  2010/03/15 00:31:10  mparmar
! Added support for auxiliary data in all init options
!
! Revision 1.6  2008/12/06 08:43:55  mtcampbe
! Updated license.
!
! Revision 1.5  2008/11/19 22:17:09  mtcampbe
! Added Illinois Open Source License/Copyright
!
! Revision 1.4  2008/05/29 01:35:31  mparmar
! Added initialization capabiity to implement step change in particle velocity
!
! Revision 1.3  2007/11/28 23:05:42  mparmar
! Added initialization of aux vars and non-dimensionalization of cv
!
! Revision 1.2  2007/06/18 18:13:43  mparmar
! Added initialization of moving reference frame data
!
! Revision 1.1  2007/04/09 18:55:41  haselbac
! Initial revision after split from RocfloMP
!
! Revision 1.19  2007/03/27 01:31:45  haselbac
! Remove superfluous USE PLAG_ModParameters statement (bad check-in)
!
! Revision 1.18  2007/03/27 00:46:14  haselbac
! Adapted to changes in RFLU_SetDimensions call
!
! Revision 1.17  2007/03/27 00:23:23  haselbac
! PLAG init completely revamped to speed up 1d cases substantially
!
! Revision 1.16  2007/03/20 17:35:16  fnajjar
! Modified USE call to streamline with new module PLAG_ModDimensions
!
! Revision 1.15  2007/03/15 22:00:58  haselbac
! Adapted to changes in PLAG init for serial runs
!
! Revision 1.14  2006/08/19 15:41:13  mparmar
! Added calls to create, init, write, and destroy patch arrays
!
! Revision 1.13  2006/05/05 18:23:47  haselbac
! Changed PLAG init so do not need serial region anymore
!
! Revision 1.12  2006/02/06 23:55:55  haselbac
! Added comm argument to RFLU_InitGlobal
!
! Revision 1.11  2005/11/10 02:44:45  haselbac
! Added support for variable properties
!
! Revision 1.10  2005/09/23 19:00:45  haselbac
! Bug fix: When init PLAG, did not know about bc
!
! Revision 1.9  2005/09/13 21:37:30  haselbac
! Added new init option
!
! Revision 1.8  2005/05/18 22:23:59  fnajjar
! Added capability of init particles
!
! Revision 1.7  2005/05/05 18:38:39  haselbac
! Removed MPI calls after bug in Rocin/out fixed
!
! Revision 1.6  2005/05/04 03:37:50  haselbac
! Commented out COM_set_verbose call
!
! Revision 1.5  2005/05/04 03:35:58  haselbac
! Added init and finalize MPI when running within GENX
!
! Revision 1.4  2005/05/03 03:10:06  haselbac
! Converted to C++ reading of command-line
!
! Revision 1.3  2005/04/22 15:20:24  haselbac
! Fixed bug in combo init: grid and geom was missing; added grid info calls
!
! Revision 1.2  2005/04/18 20:33:27  haselbac
! Removed USE RFLU_ModCommLists
!
! Revision 1.1  2005/04/15 15:08:15  haselbac
! Initial revision
!
! ******************************************************************************

