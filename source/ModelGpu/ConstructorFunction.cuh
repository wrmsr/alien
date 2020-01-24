#pragma once
#include "ModelBasic/ElementaryTypes.h"

#include "HashMap.cuh"
#include "Math.cuh"
#include "QuantityConverter.cuh"
#include "SimulationData.cuh"
#include "Tagger.cuh"
#include "DEBUG_cluster.cuh"

class ConstructorFunction
{
public:
    __inline__ __device__ void init_blockCall(Cluster* cluster, SimulationData* data);
    __inline__ __device__ void processing_blockCall(Token* token);

private:
    struct ClusterComponent
    {
        enum Type
        {
            Constructor = 0,
            ConstructionSite = 1
        };
    };
    struct Angles
    {
        float constructor;
        float constructionSite;
    };
    struct AngularMasses
    {
        float constructor;
        float constructionSite;
    };
    struct RotationMatrices
    {
        float constructor[2][2];
        float constructionSite[2][2];
    };
    struct EnergyForNewEntities
    {
        bool energyAvailable;
        float cell;
        float token;
    };

    __inline__ __device__ void checkMaxRadius(bool& result);
    __inline__ __device__ bool checkDistance(float distance);
    __inline__ __device__ Cell* getFirstCellOfConstructionSite();

    __inline__ __device__ void mutation();

    __inline__ __device__ void continueConstruction(Cell* firstCellOfConstructionSite);
    __inline__ __device__ void startNewConstruction();

    __inline__ __device__ void
    continueConstructionWithRotationOnly(Cell* constructionCell, Angles const& anglesToRotate, float desiredAngle);

    __inline__ __device__ void continueConstructionWithRotationAndCreation(
        Cell* constructionCell,
        Angles const& anglesToRotate,
        float desiredAngle);

    __inline__ __device__ void tagConstructionSite(Cell* baseCell, Cell* firstCellOfConstructionSite);

    __inline__ __device__ void calcMaxAngles(Cell* constructionCell, Angles& result);
    __inline__ __device__ void calcAngularMasses(Cluster* cluster, Cell* constructionCell, AngularMasses& result);
    __inline__ __device__ RotationMatrices calcRotationMatrices(Angles const& angles);

    __inline__ __device__ float calcFreeAngle(Cell* cell);
    __inline__ __device__ Angles
    calcAnglesToRotate(AngularMasses const& angularMasses, float desiredAngleBetweenConstructurAndConstructionSite);
    __inline__ __device__ bool restrictAngles(Angles& angles, Angles const& minAngles);

    __inline__ __device__ void calcAngularMassAfterTransformationAndAddingCell(
        float2 const& relPosOfNewCell,
        float2 const& centerOfRotation,
        RotationMatrices const& rotationMatrices,
        float2 const& displacementOfConstructionSite,
        float& result);
    __inline__ __device__ void calcAngularMassAfterTransformation(
        float2 const& centerOfRotation,
        RotationMatrices const& rotationMatrices,
        float& result);
    __inline__ __device__ void calcAngularMassAfterAddingCell(float2 const& relPosOfNewCell, float& result);
    __inline__ __device__ EnergyForNewEntities adaptEnergies(float energyLoss);


    __inline__ __device__ void transformClusterComponents(
        float2 const& centerOfRotation,
        RotationMatrices const& rotationMatrices,
        float2 const& displacementForConstructionSite);
    __inline__ __device__ void adaptRelPositions();
    __inline__ __device__ void completeCellAbsPosAndVel();

    __inline__ __device__ float2 getTransformedCellRelPos(
        Cell* cell,
        float2 const& centerOfRotation,
        RotationMatrices const& matrices,
        float2 const& displacementForConstructionSite);

    struct CellAndNewAbsPos
    {
        Cell* cell;
        float2 newAbsPos;
    };
    __inline__ __device__ void isObstaclePresent_onlyRotation(
        bool ignoreOwnCluster,
        float2 const& centerOfRotation,
        RotationMatrices const& rotationMatrices,
        bool& result);
    __inline__ __device__ void isObstaclePresent_rotationAndCreation(
        bool ignoreOwnCluster,
        float2 const& relPosOfNewCell,
        float2 const& centerOfRotation,
        RotationMatrices const& rotationMatrices,
        float2 const& displacementOfConstructionSite,
        bool& result);
    __inline__ __device__ void isObstaclePresent_firstCreation(
        bool ignoreOwnCluster,
        float2 const& relPosOfNewCell,
        bool& result);
    __inline__ __device__ bool isObstaclePresent_helper(
        bool ignoreOwnCluster,
        Cell* cell,
        float2 const& absPos,
        HashMap<int2, CellAndNewAbsPos>& tempMap);

    __inline__ __device__ void
    constructNewCell(float2 const& relPosOfNewCell, float const energyOfNewCell, Cell*& result);
    __inline__ __device__ void constructNewToken(
        Cell* cellOfNewToken,
        Cell* sourceCellOfNewToken,
        float energyOfNewToken,
        bool duplicate,
        Token*& result);

    __inline__ __device__ void addCellToCluster(Cell* newCell, Cell** newCellPointers);
    __inline__ __device__ void addTokenToCluster(Token* token, Token** newTokenPointers);

    __inline__ __device__ void separateConstructionWhenFinished(Cell* newCell);

    __inline__ __device__ void connectNewCell(Cell* newCell, Cell* cellOfConstructionSite);
    __inline__ __device__ void removeConnection(Cell* cell1, Cell* cell2);
    enum class AdaptMaxConnections
    {
        No,
        Yes
    };
    __inline__ __device__ AdaptMaxConnections isAdaptMaxConnections(Token* token);
    __inline__ __device__ bool isConnectable(int numConnections, int maxConnections, AdaptMaxConnections adaptMaxConnections);
    __inline__ __device__ void establishConnection(Cell* cell1, Cell* cell2, AdaptMaxConnections adaptMaxConnections);

    __inline__ __device__ Enums::ConstrIn::Type getCommand(Token* token) const;
    __inline__ __device__ Enums::ConstrInOption::Type getOption(Token* token) const;

private:
    __inline__ __device__ Cell*& check(Cell*& entity, int p);
    __inline__ __device__ Cell* check(Cell*&& entity);
    __inline__ __device__ Cell**& check(Cell**& entity);
    __inline__ __device__ Cell** check(Cell**&& entity);
    __inline__ __device__ Cluster* check(Cluster* entity);
    __inline__ __device__ Token*& check(Token*& entity);
    __inline__ __device__ Token**& check(Token**& entity);
    __inline__ __device__ Token** check(Token**&& entity);
    __inline__ __device__ int check(int index, int arraySize);

    SimulationData* _data;
    Token* _token;
    Cluster* _cluster;
    PartitionData _cellBlock;

    struct DynamicMemory
    {
        Cell** cellPointerArray1;
        Cell** cellPointerArray2;
        HashMap<int2, CellAndNewAbsPos> cellPosMap;
    };
    DynamicMemory _dynamicMemory;
};

/************************************************************************/
/* Implementation                                                       */
/************************************************************************/

__inline__ __device__ void ConstructorFunction::processing_blockCall(Token* token)
{
    _token = token;

    auto const command = getCommand(token);
    if (Enums::ConstrIn::DO_NOTHING == command) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::SUCCESS;
        __syncthreads();
        return;
    }

    __shared__ bool isRadiusTooLarge;
    checkMaxRadius(isRadiusTooLarge);
    __syncthreads();

    if (!isRadiusTooLarge) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_MAX_RADIUS;
        __syncthreads();
        return;
    }

    //TODO: short energy check for optimization

    __shared__ Cell* firstCellOfConstructionSite;
    if (0 == threadIdx.x) {
        firstCellOfConstructionSite = getFirstCellOfConstructionSite();
    }
    __syncthreads();

    __shared__ Cell** cellPointerArray1;
    __shared__ Cell** cellPointerArray2;
    if (0 == threadIdx.x) {
        cellPointerArray1 = _data->dynamicMemory.getArray<Cell*>(_cluster->numCellPointers);
        cellPointerArray2 = _data->dynamicMemory.getArray<Cell*>(_cluster->numCellPointers);
    }
    _dynamicMemory.cellPosMap.init_blockCall(_cluster->numCellPointers * 2, _data->dynamicMemory);
    __syncthreads();

    _dynamicMemory.cellPointerArray1 = cellPointerArray1;
    _dynamicMemory.cellPointerArray2 = cellPointerArray2;
    __syncthreads();

    mutation();
    __syncthreads();

    if (firstCellOfConstructionSite) {
        auto const distance = QuantityConverter::convertDataToDistance(_token->memory[Enums::Constr::IN_DIST]);
        if (!checkDistance(distance)) {
            _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_DIST;
            __syncthreads();
            return;
        }
        continueConstruction(firstCellOfConstructionSite);

    } else {
        startNewConstruction();

    }
    __syncthreads();
}

__inline__ __device__ void ConstructorFunction::init_blockCall(Cluster* cluster, SimulationData* data)
{
    _data = data;
    _cluster = cluster;
    _cellBlock = calcPartition(_cluster->numCellPointers, threadIdx.x, blockDim.x);
}


__inline__ __device__ void ConstructorFunction::checkMaxRadius(bool& result)
{
    __shared__ float maxRadius;
    if (0 == threadIdx.x) {
        result = true;
        maxRadius = _data->cellMap.getMaxRadius();
    }
    __syncthreads();
    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        if (Math::length(cell->relPos) >= maxRadius - FP_PRECISION) {
            result = false;
            return;
        }
    }
}

__inline__ __device__ bool ConstructorFunction::checkDistance(float distance)
{
    return cudaSimulationParameters.cellMinDistance < distance && distance < cudaSimulationParameters.cellMaxDistance;
}

__inline__ __device__ Cell* ConstructorFunction::getFirstCellOfConstructionSite()
{
    Cell* result = nullptr;
    auto const& cell = _token->cell;
    for (int i = 0; i < cell->numConnections; ++i) {
        auto const& connectingCell = cell->connections[i];
        if (connectingCell->tokenBlocked) {
            result = connectingCell;
        }
    }
    return result;
}

__inline__ __device__ void ConstructorFunction::mutation()
{
    if (0 == threadIdx.x) {
        if (_data->numberGen.random() < cudaSimulationParameters.cellFunctionConstructorPropertyMutationProb) {
            _token->memory[Enums::Constr::IN_OPTION] = _data->numberGen.random(255);
        }
        if (_data->numberGen.random() < cudaSimulationParameters.cellFunctionConstructorStructureMutationProb) {
            _token->memory[Enums::Constr::INOUT_ANGLE] = _data->numberGen.random(255);
        }
        if (_data->numberGen.random() < cudaSimulationParameters.cellFunctionConstructorStructureMutationProb) {
            _token->memory[Enums::Constr::IN_DIST] = _data->numberGen.random(255);
        }
        if (_data->numberGen.random() < cudaSimulationParameters.cellFunctionConstructorPropertyMutationProb) {
            _token->memory[Enums::Constr::IN_CELL_MAX_CONNECTIONS] = _data->numberGen.random(255);
        }
        if (_data->numberGen.random() < cudaSimulationParameters.cellFunctionConstructorPropertyMutationProb) {
            _token->memory[Enums::Constr::IN_CELL_BRANCH_NO] = _data->numberGen.random(255);
        }
        if (_data->numberGen.random() < cudaSimulationParameters.cellFunctionConstructorPropertyMutationProb) {
            _token->memory[Enums::Constr::IN_CELL_METADATA] = _data->numberGen.random(255);
        }
        if (_data->numberGen.random() < cudaSimulationParameters.cellFunctionConstructorPropertyMutationProb) {
            _token->memory[Enums::Constr::IN_CELL_FUNCTION] = _data->numberGen.random(255);
        }
    }
    auto const memoryPartition = calcPartition(MAX_CELL_STATIC_BYTES + MAX_CELL_MUTABLE_BYTES + 2, threadIdx.x, blockDim.x);
    for (auto index = memoryPartition.startIndex; index <= memoryPartition.endIndex; ++index) {
        if (_data->numberGen.random() < cudaSimulationParameters.cellFunctionConstructorDataMutationProb) {
            _token->memory[Enums::Constr::IN_CELL_FUNCTION_DATA + index] = _data->numberGen.random(255);
        }
    }
}

__inline__ __device__ void ConstructorFunction::continueConstruction(Cell* firstCellOfConstructionSite)
{
    auto const& cell = _token->cell;
    tagConstructionSite(cell, firstCellOfConstructionSite);
    __syncthreads();

    if (ClusterComponent::ConstructionSite == cell->tag) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_CONNECTION;
        return;
    }

    __shared__ Angles maxAngles;
    calcMaxAngles(firstCellOfConstructionSite, maxAngles);
    __syncthreads();

    __shared__ AngularMasses angularMasses;
    calcAngularMasses(_cluster, firstCellOfConstructionSite, angularMasses);
    __syncthreads();

    __shared__ float desiredAngleBetweenConstructurAndConstructionSite;
    __shared__ Angles anglesToRotate;
    __shared__ bool isAngleRestricted;
    if (0 == threadIdx.x) {
        desiredAngleBetweenConstructurAndConstructionSite =
            QuantityConverter::convertDataToAngle(_token->memory[Enums::Constr::INOUT_ANGLE]);
        anglesToRotate = calcAnglesToRotate(angularMasses, desiredAngleBetweenConstructurAndConstructionSite);
        isAngleRestricted = restrictAngles(anglesToRotate, maxAngles);
    }
    __syncthreads();

    if (isAngleRestricted) {

        if (abs(anglesToRotate.constructor) < 1.0f && abs(anglesToRotate.constructionSite) < 1.0f) {
            _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_DIST;
            return;
        }

        //angle discretization correction
        if (0 == threadIdx.x) {
            anglesToRotate.constructor =
                QuantityConverter::convertDataToAngle(QuantityConverter::convertAngleToData(anglesToRotate.constructor));
            anglesToRotate.constructionSite = QuantityConverter::convertDataToAngle(
                QuantityConverter::convertAngleToData(anglesToRotate.constructionSite));
        }
        __syncthreads();

        continueConstructionWithRotationOnly(
            firstCellOfConstructionSite,
            anglesToRotate,
            desiredAngleBetweenConstructurAndConstructionSite);
    }
    else {
        continueConstructionWithRotationAndCreation(
            firstCellOfConstructionSite,
            anglesToRotate,
            desiredAngleBetweenConstructurAndConstructionSite);
    }
    __syncthreads();
}

__inline__ __device__ void ConstructorFunction::startNewConstruction()
{
    auto const& cell = _token->cell;
    auto const adaptMaxConnections = isAdaptMaxConnections(_token);

    if (!isConnectable(cell->numConnections, cell->maxConnections, adaptMaxConnections)) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_CONNECTION;
        return;
    }

    __shared__ float2 relPosOfNewCell;
    __shared__ Enums::ConstrIn::Type command;
    __shared__ Enums::ConstrInOption::Type option;
    if (0 == threadIdx.x) {
        auto const freeAngle = calcFreeAngle(cell);
        auto const newCellAngle =
            QuantityConverter::convertDataToAngle(_token->memory[Enums::Constr::INOUT_ANGLE]) + freeAngle;

        command = getCommand(_token);
        option = getOption(_token);
        bool const separation = Enums::ConstrInOption::FINISH_WITH_SEP == option
            || Enums::ConstrInOption::FINISH_WITH_SEP_RED == option
            || Enums::ConstrInOption::FINISH_WITH_TOKEN_SEP_RED == option;

        auto const distance = QuantityConverter::convertDataToDistance(_token->memory[Enums::Constr::IN_DIST]);
        auto const relPosOfNewCellDelta =
            Math::unitVectorOfAngle(newCellAngle) * cudaSimulationParameters.cellFunctionConstructorOffspringCellDistance;
        relPosOfNewCell = separation
            ? cell->relPos + relPosOfNewCellDelta + Math::unitVectorOfAngle(newCellAngle) * distance
            : cell->relPos + relPosOfNewCellDelta;

    }
    __syncthreads();

    if (Enums::ConstrIn::SAFE == command || Enums::ConstrIn::UNSAFE == command) {
        auto ignoreOwnCluster = (Enums::ConstrIn::UNSAFE == command);
        __shared__ bool isObstaclePresent;
        isObstaclePresent_firstCreation(ignoreOwnCluster, relPosOfNewCell, isObstaclePresent);
        __syncthreads();

        if (isObstaclePresent) {
            _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_OBSTACLE;
            return;
        }
    }

    __shared__ float kineticEnergyBeforeConstruction;
    if (0 == threadIdx.x) {
        kineticEnergyBeforeConstruction =
            Physics::kineticEnergy(_cluster->numCellPointers, _cluster->vel, _cluster->angularMass, _cluster->angularVel);
    }
    __syncthreads();

    __shared__ float angularMassAfterConstruction;
    calcAngularMassAfterAddingCell(relPosOfNewCell, angularMassAfterConstruction);
    __syncthreads();

    __shared__ float2 velocityAfterConstruction;
    __shared__ float angularVelAfterConstruction;
    __shared__ EnergyForNewEntities energyForNewEntities;
    if (0 == threadIdx.x) {
        auto const mass = static_cast<float>(_cluster->numCellPointers);
        velocityAfterConstruction = Physics::transformVelocity(mass, mass + 1, _cluster->vel);
        angularVelAfterConstruction =
            Physics::transformAngularVelocity(_cluster->angularMass, angularMassAfterConstruction, _cluster->angularVel);
        auto const kineticEnergyAfterConstruction = Physics::kineticEnergy(
            mass + 1, velocityAfterConstruction, angularMassAfterConstruction, angularVelAfterConstruction);
        auto const kineticEnergyDiff = kineticEnergyAfterConstruction - kineticEnergyBeforeConstruction;

        energyForNewEntities = adaptEnergies(kineticEnergyDiff);
    }
    __syncthreads();

    if (!energyForNewEntities.energyAvailable) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_NO_ENERGY;
        return;
    }

    __shared__ Cell* newCell;
    constructNewCell(relPosOfNewCell, energyForNewEntities.cell, newCell);
    __syncthreads();

    __shared__ Cell** newCellPointers;
    if (0 == threadIdx.x) {
        newCellPointers = _data->entities.cellPointers.getNewSubarray(_cluster->numCellPointers + 1);
    }
    __syncthreads();

    addCellToCluster(newCell, newCellPointers);
    __syncthreads();

    _cellBlock = calcPartition(_cluster->numCellPointers, threadIdx.x, blockDim.x);

    if (0 == threadIdx.x) {
        establishConnection(newCell, cell, adaptMaxConnections);
    }
    __syncthreads();

    adaptRelPositions();
    __syncthreads();

    __shared__ bool createEmptyToken;
    __shared__ bool createDuplicateToken;
    if (0 == threadIdx.x) {
        _cluster->vel = velocityAfterConstruction;
        _cluster->angularVel = angularVelAfterConstruction;
        _cluster->angularMass = angularMassAfterConstruction;
        separateConstructionWhenFinished(newCell);
        createEmptyToken = Enums::ConstrInOption::CREATE_EMPTY_TOKEN == option
            || Enums::ConstrInOption::FINISH_WITH_TOKEN_SEP_RED == option;
        createDuplicateToken = Enums::ConstrInOption::CREATE_DUP_TOKEN == option;
    }
    __syncthreads();

    completeCellAbsPosAndVel();
    __syncthreads();

    if (createEmptyToken || createDuplicateToken) {
        
        __shared__ Token* newToken;
        constructNewToken(newCell, cell, energyForNewEntities.token, createDuplicateToken, newToken);
        __syncthreads();
            
        __shared__ Token** newTokenPointers;
        if (0 == threadIdx.x) {
            newTokenPointers = _data->entities.tokenPointers.getNewSubarray(_cluster->numTokenPointers + 1);
        }
        __syncthreads();

        addTokenToCluster(newToken, newTokenPointers);
        __syncthreads();
    }

    if (0 == threadIdx.x) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::SUCCESS;
        _token->memory[Enums::Constr::INOUT_ANGLE] = 0;
    }
}

__inline__ __device__ void ConstructorFunction::continueConstructionWithRotationOnly(
    Cell* firstCellOfConstructionSite,
    Angles const& anglesToRotate,
    float desiredAngle)
{
    __shared__ RotationMatrices rotationMatrices;
    __shared__ float kineticEnergyBeforeRotation;
    if (0 == threadIdx.x) {
        kineticEnergyBeforeRotation =
            Physics::kineticEnergy(_cluster->numCellPointers, _cluster->vel, _cluster->angularMass, _cluster->angularVel);
        rotationMatrices = calcRotationMatrices(anglesToRotate);
    }
    __syncthreads();

    __shared__ float angularMassAfterRotation;
    calcAngularMassAfterTransformation(firstCellOfConstructionSite->relPos, rotationMatrices, angularMassAfterRotation);
    __syncthreads();

    __shared__ float angularVelAfterRotation;
    __shared__ float kineticEnergyDiff;
    if (0 == threadIdx.x) {
        angularVelAfterRotation =
            Physics::transformAngularVelocity(_cluster->angularMass, angularMassAfterRotation, _cluster->angularVel);
        auto const kineticEnergyAfterRotation = Physics::kineticEnergy(
            _cluster->numCellPointers, _cluster->vel, angularMassAfterRotation, angularVelAfterRotation);

        kineticEnergyDiff = kineticEnergyAfterRotation - kineticEnergyBeforeRotation;
    }
    __syncthreads();

    if (_token->getEnergy() <= cudaSimulationParameters.cellFunctionConstructorOffspringCellEnergy
            + cudaSimulationParameters.tokenMinEnergy + kineticEnergyDiff) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_NO_ENERGY;
        __syncthreads();
        return;
    }

    auto const command = getCommand(_token);
    if (Enums::ConstrIn::SAFE == command || Enums::ConstrIn::UNSAFE == command) {
        auto const ignoreOwnCluster = (Enums::ConstrIn::UNSAFE == command);
        
        __shared__ bool result;
        isObstaclePresent_onlyRotation(
            ignoreOwnCluster, firstCellOfConstructionSite->relPos, rotationMatrices, result);
        __syncthreads();

        if (result) {
            _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_OBSTACLE;
            __syncthreads();
            return;
        }
    }

    transformClusterComponents(firstCellOfConstructionSite->relPos, rotationMatrices, { 0, 0 });
    __syncthreads();

    adaptRelPositions();
    __syncthreads();

    if (0 == threadIdx.x) {
        _cluster->angularVel = angularVelAfterRotation;
        _cluster->angularMass = angularMassAfterRotation;

        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::SUCCESS_ROT;
        _token->memory[Enums::Constr::INOUT_ANGLE] = QuantityConverter::convertAngleToData(
            desiredAngle - (anglesToRotate.constructionSite - anglesToRotate.constructor));
    }
    __syncthreads();

    completeCellAbsPosAndVel();
    __syncthreads();
}

__inline__ __device__ void ConstructorFunction::continueConstructionWithRotationAndCreation(
    Cell* firstCellOfConstructionSite,
    Angles const& anglesToRotate,
    float desiredAngle)
{
    auto const& cell = _token->cell;

    auto const adaptMaxConnections = isAdaptMaxConnections(_token);
    if (1 == _token->getMaxConnectionsForConstructor()) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_CONNECTION;
        __syncthreads();
        return;
    }

    __shared__ float2 relPosOfNewCell;
    __shared__ float2 centerOfRotation;
    __shared__ RotationMatrices rotationMatrices;
    __shared__ float2 displacementForConstructionSite;
    __shared__ Enums::ConstrInOption::Type option;
    __shared__ Enums::ConstrIn::Type command;
    if (0 == threadIdx.x) {
        auto const distance = QuantityConverter::convertDataToDistance(_token->memory[Enums::Constr::IN_DIST]);

        relPosOfNewCell = firstCellOfConstructionSite->relPos;
        centerOfRotation = firstCellOfConstructionSite->relPos;
        rotationMatrices = calcRotationMatrices(anglesToRotate);

        auto const cellRelPos_transformed = getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, { 0, 0 });
 
        displacementForConstructionSite =
            Math::normalized(firstCellOfConstructionSite->relPos - cellRelPos_transformed) * distance;
        option = getOption(_token);
        if (Enums::ConstrInOption::FINISH_WITH_SEP == option || Enums::ConstrInOption::FINISH_WITH_SEP_RED == option
            || Enums::ConstrInOption::FINISH_WITH_TOKEN_SEP_RED == option) {

            relPosOfNewCell = relPosOfNewCell + displacementForConstructionSite;
            displacementForConstructionSite = displacementForConstructionSite * 2;
        }
        command = getCommand(_token);
    }
    __syncthreads();

    if (Enums::ConstrIn::SAFE == command || Enums::ConstrIn::UNSAFE == command) {
        
        auto const ignoreOwnCluster = (Enums::ConstrIn::UNSAFE == command);
        
        __shared__ bool result;
        isObstaclePresent_rotationAndCreation(
            ignoreOwnCluster,
            relPosOfNewCell,
            centerOfRotation,
            rotationMatrices,
            displacementForConstructionSite,
            result);
        __syncthreads();

        if (result) {
            _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_OBSTACLE;
            __syncthreads();
            return;
        }
    }

    __shared__ float kineticEnergyBeforeConstruction;
    if (0 == threadIdx.x) {
        kineticEnergyBeforeConstruction = Physics::kineticEnergy(
            _cluster->numCellPointers, _cluster->vel, _cluster->angularMass, _cluster->angularVel);
    }
    __syncthreads();

    __shared__ float angularMassAfterConstruction;
    calcAngularMassAfterTransformationAndAddingCell(
        relPosOfNewCell,
        centerOfRotation,
        rotationMatrices,
        displacementForConstructionSite,
        angularMassAfterConstruction);
    __syncthreads();

    __shared__ float2 velocityAfterConstruction;
    __shared__ float angularVelAfterConstruction;
    __shared__ EnergyForNewEntities energyForNewEntities;
    if (0 == threadIdx.x) {
        auto const mass = static_cast<float>(_cluster->numCellPointers);
        velocityAfterConstruction = Physics::transformVelocity(mass, mass + 1, _cluster->vel);
        angularVelAfterConstruction =
            Physics::transformAngularVelocity(_cluster->angularMass, angularMassAfterConstruction, _cluster->angularVel);
        auto const kineticEnergyAfterRotation = Physics::kineticEnergy(
            mass + 1, velocityAfterConstruction, angularMassAfterConstruction, angularVelAfterConstruction);
        auto const kineticEnergyDiff = kineticEnergyAfterRotation - kineticEnergyBeforeConstruction;
        energyForNewEntities = adaptEnergies(kineticEnergyDiff);
    }
    __syncthreads();

    if (!energyForNewEntities.energyAvailable) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::ERROR_NO_ENERGY;
        __syncthreads();
        return;
    }

    transformClusterComponents(centerOfRotation, rotationMatrices, displacementForConstructionSite);

    __shared__ Cell* newCell;
    constructNewCell(relPosOfNewCell, energyForNewEntities.cell, newCell);
    __syncthreads();

    __shared__ Cell** newCellPointers;
    if (0 == threadIdx.x) {
        newCellPointers = _data->entities.cellPointers.getNewSubarray(_cluster->numCellPointers + 1);
    }
    __syncthreads();

    addCellToCluster(newCell, newCellPointers);
    __syncthreads();

    connectNewCell(newCell, firstCellOfConstructionSite);
    __syncthreads();

    _cellBlock = calcPartition(_cluster->numCellPointers, threadIdx.x, blockDim.x);

    adaptRelPositions();
    __syncthreads();

    __shared__ bool createEmptyToken;
    __shared__ bool createDuplicateToken;
    if (0 == threadIdx.x) {
        _cluster->vel = velocityAfterConstruction;
        _cluster->angularVel = angularVelAfterConstruction;
        _cluster->angularMass = angularMassAfterConstruction;

        firstCellOfConstructionSite->tokenBlocked = false;  //disable token blocking on construction side
        separateConstructionWhenFinished(newCell);

        createEmptyToken = Enums::ConstrInOption::CREATE_EMPTY_TOKEN == option
            || Enums::ConstrInOption::FINISH_WITH_TOKEN_SEP_RED == option;
        createDuplicateToken = Enums::ConstrInOption::CREATE_DUP_TOKEN == option;
    }
    __syncthreads();

    completeCellAbsPosAndVel();
    __syncthreads();

    if (createEmptyToken || createDuplicateToken) {
        __shared__ Token* newToken;
        constructNewToken(newCell, cell, energyForNewEntities.token, createDuplicateToken, newToken);
        __syncthreads();

        __shared__ Token** newTokenPointers;
        if (0 == threadIdx.x) {
            newTokenPointers = _data->entities.tokenPointers.getNewSubarray(_cluster->numTokenPointers + 1);
        }
        __syncthreads();

        addTokenToCluster(newToken, newTokenPointers);
        __syncthreads();
    }

    if (0 == threadIdx.x) {
        _token->memory[Enums::Constr::OUT] = Enums::ConstrOut::SUCCESS;
        _token->memory[Enums::Constr::INOUT_ANGLE] = 0;
    }
}

__inline__ __device__ auto ConstructorFunction::adaptEnergies(float energyLoss) -> EnergyForNewEntities
{
    EnergyForNewEntities result;
    result.energyAvailable = true;
    result.token = 0.0f;
    result.cell = cudaSimulationParameters.cellFunctionConstructorOffspringCellEnergy;

    auto const& cell = _token->cell;
    auto const option = getOption(_token);

    if (Enums::ConstrInOption::CREATE_EMPTY_TOKEN == option || Enums::ConstrInOption::CREATE_DUP_TOKEN == option
        || Enums::ConstrInOption::FINISH_WITH_TOKEN_SEP_RED == option) {
        result.token = cudaSimulationParameters.cellFunctionConstructorOffspringTokenEnergy;
    }

    if (_token->getEnergy() <= cudaSimulationParameters.cellFunctionConstructorOffspringCellEnergy + result.token + energyLoss
            + cudaSimulationParameters.tokenMinEnergy) {
        result.energyAvailable = false;
        return result;
    }

    _token->changeEnergy(-(cudaSimulationParameters.cellFunctionConstructorOffspringCellEnergy + result.token + energyLoss));
    if (Enums::ConstrInOption::CREATE_EMPTY_TOKEN == option || Enums::ConstrInOption::CREATE_DUP_TOKEN == option
        || Enums::ConstrInOption::FINISH_WITH_TOKEN_SEP_RED == option) {
        auto const averageEnergy = (cell->getEnergy() + result.cell) / 2;
        cell->setEnergy(averageEnergy);
        result.cell = averageEnergy;
    }

    return result;
}

__inline__ __device__ void ConstructorFunction::tagConstructionSite(Cell* baseCell, Cell* firstCellOfConstructionSite)
{
    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto& cell = _cluster->cellPointers[cellIndex];
        cell->tag = ClusterComponent::Constructor;
    }
    __syncthreads();

    __shared__ Tagger::DynamicMemory tagMemory;
    if (0 == threadIdx.x) {
        tagMemory = { _dynamicMemory.cellPointerArray1, _dynamicMemory.cellPointerArray2 };
        firstCellOfConstructionSite->tag = ClusterComponent::ConstructionSite;
    }
    __syncthreads();
    Tagger::tagComponent_blockCall(_cluster, firstCellOfConstructionSite, baseCell, ClusterComponent::ConstructionSite, ClusterComponent::Constructor, tagMemory);
}

__inline__ __device__ void ConstructorFunction::calcMaxAngles(Cell* constructionCell, Angles& result)
{
    if (0 == threadIdx.x) {
        result = { 360.0f, 360.0f };
    }
    __syncthreads();
    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto const r = Math::length(cell->relPos - constructionCell->relPos);

        if (cudaSimulationParameters.cellMaxDistance < 2 * r) {
            auto a = abs(2.0 * asinf(cudaSimulationParameters.cellMaxDistance / (2.0 * r)) * RAD_TO_DEG);
            if (ClusterComponent::Constructor == cell->tag) {
                result.constructor = min(result.constructor, a);
            }
            if (ClusterComponent::ConstructionSite == cell->tag) {
                result.constructionSite = min(result.constructionSite, a);
            }
        }
    }
}

__inline__ __device__ void ConstructorFunction::calcAngularMasses(Cluster* cluster, Cell* firstCellOfConstructionSite, AngularMasses& result)
{
    if (0 == threadIdx.x) {
        result = { 0, 0 };
    }
    __syncthreads();

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = cluster->cellPointers[cellIndex];
        auto const angularMassElement = Math::lengthSquared(cell->relPos - firstCellOfConstructionSite->relPos);
        if (ClusterComponent::Constructor == cell->tag) {
            atomicAdd_block(&result.constructor, angularMassElement);
        }
        if (ClusterComponent::ConstructionSite == cell->tag) {
            atomicAdd_block(&result.constructionSite, angularMassElement);
        }
    }
}

__inline__ __device__ auto ConstructorFunction::calcRotationMatrices(Angles const& angles) -> RotationMatrices
{
    RotationMatrices result;
    Math::rotationMatrix(angles.constructionSite, result.constructionSite);
    Math::rotationMatrix(angles.constructor, result.constructor);
    return result;
}

__inline__ __device__ float ConstructorFunction::calcFreeAngle(Cell* cell)
{
    auto const numConnections = cell->numConnections;
    float angles[MAX_CELL_BONDS];
    for (int i = 0; i < numConnections; ++i) {
        auto const displacement = cell->connections[i]->relPos - cell->relPos;
        auto const angleToAdd = Math::angleOfVector(displacement);
        auto indexToAdd = 0;
        for (; indexToAdd < i; ++indexToAdd) {
            if (angles[indexToAdd] > angleToAdd) {
                break;
            }
        }
        for (int j = indexToAdd; j < numConnections - 1; ++j) {
            angles[j + 1] = angles[j];
        }
        angles[indexToAdd] = angleToAdd;
    }

    auto largestAnglesDiff = 0.0f;
    auto result = 0.0f;
    for (int i = 0; i < numConnections; ++i) {
        auto angleDiff = angles[(i + 1) % numConnections] - angles[i];
        if (angleDiff <= 0.0f) {
            angleDiff += 360.0f;
        }
        if (angleDiff > 360.0f) {
            angleDiff -= 360.0f;
        }
        if (angleDiff > largestAnglesDiff) {
            largestAnglesDiff = angleDiff;
            result = angles[i] + angleDiff / 2;
        }
    }

    return result;
}

__inline__ __device__ auto ConstructorFunction::calcAnglesToRotate(
    AngularMasses const& angularMasses,
    float desiredAngleBetweenConstructurAndConstructionSite) -> Angles
{
    Angles result;
    auto const sumAngularMasses = angularMasses.constructor + angularMasses.constructionSite;
    result.constructionSite =
        angularMasses.constructor * desiredAngleBetweenConstructurAndConstructionSite / sumAngularMasses;
    result.constructor =
        -angularMasses.constructionSite * desiredAngleBetweenConstructurAndConstructionSite / sumAngularMasses;

    return result;
}

__inline__ __device__ bool ConstructorFunction::restrictAngles(Angles& angles, Angles const& maxAngles)
{
    auto result = false;
    if (abs(angles.constructionSite) > maxAngles.constructionSite) {
        result = true;
        if (angles.constructionSite >= 0.0) {
            angles.constructionSite = abs(maxAngles.constructionSite);
        }
        if (angles.constructionSite < 0.0) {
            angles.constructionSite = -abs(maxAngles.constructionSite);
        }
    }
    if (abs(angles.constructor) > maxAngles.constructor) {
        result = true;
        if (angles.constructor >= 0.0) {
            angles.constructor = abs(maxAngles.constructor);
        }
        if (angles.constructor < 0.0) {
            angles.constructor = -abs(maxAngles.constructor);
        }
    }
    return result;
}

__inline__ __device__ void ConstructorFunction::calcAngularMassAfterTransformationAndAddingCell(
    float2 const& relPosOfNewCell,
    float2 const& centerOfRotation,
    RotationMatrices const& rotationMatrices,
    float2 const& displacementOfConstructionSite,
    float& result)
{
    __shared__ float2 center;
    if (0 == threadIdx.x) {
        center = relPosOfNewCell;
    }
    __syncthreads();

    for (auto cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto cellRelPosTransformed =
            getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, displacementOfConstructionSite);
        atomicAdd_block(&center.x, cellRelPosTransformed.x);
        atomicAdd_block(&center.y, cellRelPosTransformed.y);
    }
    __syncthreads();

    if (0 == threadIdx.x) {
        center = center / (_cluster->numCellPointers + 1);
        result = Math::lengthSquared(relPosOfNewCell - center);
    }
    __syncthreads();

    for (auto cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto cellRelPosTransformed =
            getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, displacementOfConstructionSite);
        atomicAdd_block(&result, Math::lengthSquared(cellRelPosTransformed - center));
    }
    __syncthreads();
}

__inline__ __device__ void ConstructorFunction::calcAngularMassAfterTransformation(
    float2 const& centerOfRotation,
    RotationMatrices const& rotationMatrices,
    float& result)
{
    __shared__ float2 center;
    if (0 == threadIdx.x) {
        center = { 0,0 };
    }
    __syncthreads();

    for (auto cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto cellRelPosTransformed =
            getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, { 0,0 });
        atomicAdd_block(&center.x, cellRelPosTransformed.x);
        atomicAdd_block(&center.y, cellRelPosTransformed.y);
    }
    __syncthreads();

    if (0 == threadIdx.x) {
        center = center / _cluster->numCellPointers;
        result = 0;
    }
    __syncthreads();

    for (auto cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto cellRelPosTransformed =
            getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, { 0,0 });
        atomicAdd_block(&result, Math::lengthSquared(cellRelPosTransformed - center));
    }
    __syncthreads();
}

__inline__ __device__ void
ConstructorFunction::calcAngularMassAfterAddingCell(float2 const& relPosOfNewCell, float& result)
{
    __shared__ float2 center;
    if (0 == threadIdx.x) {
        center = relPosOfNewCell;
    }
    __syncthreads();

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        atomicAdd_block(&center.x, cell->relPos.x);
        atomicAdd_block(&center.y, cell->relPos.y);
    }
    __syncthreads();

    if (0 == threadIdx.x) {
        center = center / (_cluster->numCellPointers + 1);
        result = Math::lengthSquared(relPosOfNewCell - center);
    }
    __syncthreads();

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        atomicAdd_block(&result, Math::lengthSquared(cell->relPos - center));
    }
    __syncthreads();
}

__inline__ __device__ void ConstructorFunction::transformClusterComponents(
    float2 const& centerOfRotation,
    RotationMatrices const& rotationMatrices,
    float2 const& displacementForConstructionSite)
{
    float rotMatrix[2][2];
    Math::rotationMatrix(_cluster->angle, rotMatrix);
    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex;  ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        cell->relPos =
            getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, displacementForConstructionSite);
        cell->absPos = Math::applyMatrix(cell->relPos, rotMatrix) + _cluster->pos;
    }
}

__inline__ __device__ void ConstructorFunction::adaptRelPositions()
{
    __shared__ float2 newCenter;
    if (0 == threadIdx.x) {
        newCenter = {0, 0};
    }
    __syncthreads();

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        atomicAdd_block(&newCenter.x, cell->relPos.x);
        atomicAdd_block(&newCenter.y, cell->relPos.y);
    }
    __syncthreads();

    if (0 == threadIdx.x) {
        newCenter = newCenter / _cluster->numCellPointers;
    }
    __syncthreads();

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        cell->relPos = cell->relPos - newCenter;
    }
}

__inline__ __device__ void ConstructorFunction::completeCellAbsPosAndVel()
{
    Math::Matrix rotationMatrix;
    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto& cell = _cluster->cellPointers[cellIndex];
        Math::rotationMatrix(_cluster->angle, rotationMatrix);
        cell->absPos = Math::applyMatrix(cell->relPos, rotationMatrix) + _cluster->pos;

        auto r = cell->absPos - _cluster->pos;
        cell->vel = Physics::tangentialVelocity(r, _cluster->vel, _cluster->angularVel);
    }
}

__inline__ __device__ float2 ConstructorFunction::getTransformedCellRelPos(
    Cell* cell,
    float2 const& centerOfRotation,
    RotationMatrices const& matrices,
    float2 const& displacementForConstructionSite)
{
    if (ClusterComponent::Constructor == cell->tag) {
        return Math::applyMatrix(cell->relPos - centerOfRotation, matrices.constructor) + centerOfRotation;
    }
    if (ClusterComponent::ConstructionSite == cell->tag) {
        return Math::applyMatrix(cell->relPos - centerOfRotation, matrices.constructionSite) + centerOfRotation
            + displacementForConstructionSite;
    }
    return cell->relPos;
}

__inline__ __device__ void ConstructorFunction::isObstaclePresent_onlyRotation(
    bool ignoreOwnCluster,
    float2 const& centerOfRotation,
    RotationMatrices const& rotationMatrices,
    bool& result)
{
    __shared__ HashMap<int2, CellAndNewAbsPos> tempCellMap;
    if (0 == threadIdx.x) {
        tempCellMap = _dynamicMemory.cellPosMap;
    }
    __syncthreads();

    tempCellMap.reset_blockCall();
    __syncthreads();

    __shared__ float2 newCenter;
    if (0 == threadIdx.x) {
        newCenter = { 0, 0 };
        result = false;
    }
    __syncthreads();

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto relPos = getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, {0, 0});
        atomicAdd_block(&newCenter.x, relPos.x);
        atomicAdd_block(&newCenter.y, relPos.y);
    }
    __syncthreads();

    __shared__ Math::Matrix clusterMatrix;
    if (0 == threadIdx.x) {
        newCenter = newCenter / _cluster->numCellPointers;
        Math::rotationMatrix(_cluster->angle, clusterMatrix);
    }
    __syncthreads();

    if (!ignoreOwnCluster) {
        for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
            auto const& cell = _cluster->cellPointers[cellIndex];
            auto relPos =
                getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, { 0,0 });
            relPos = relPos - newCenter;
            auto const absPos = _cluster->pos + Math::applyMatrix(relPos, clusterMatrix);
            tempCellMap.insertOrAssign(toInt2(absPos), CellAndNewAbsPos{ cell, absPos });
        }
    }
    __syncthreads();

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto relPos = getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, {0, 0});
        relPos = relPos - newCenter;
        auto const absPos = _cluster->pos + Math::applyMatrix(relPos, clusterMatrix);
        if (isObstaclePresent_helper(ignoreOwnCluster, cell, absPos, tempCellMap)) {
            result = true;
            break;
        }
    }
}

__inline__ __device__ void ConstructorFunction::isObstaclePresent_rotationAndCreation(
    bool ignoreOwnCluster,
    float2 const& relPosOfNewCell,
    float2 const& centerOfRotation,
    RotationMatrices const& rotationMatrices,
    float2 const& displacementOfConstructionSite,
    bool& result)
{

    __shared__ HashMap<int2, CellAndNewAbsPos> tempCellMap;
    if (0 == threadIdx.x) {
        tempCellMap = _dynamicMemory.cellPosMap;
    }
    __syncthreads();

    tempCellMap.reset_blockCall();
    __syncthreads();

    __shared__ float2 newCenter;
    if (0 == threadIdx.x) {
        newCenter = relPosOfNewCell;
        result = false;
    }
    __syncthreads();

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto relPos =
            getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, displacementOfConstructionSite);
        atomicAdd_block(&newCenter.x, relPos.x);
        atomicAdd_block(&newCenter.y, relPos.y);
    }
    __syncthreads();

    __shared__ Math::Matrix clusterMatrix;
    if (0 == threadIdx.x) {
        newCenter = newCenter / (_cluster->numCellPointers + 1);
        Math::rotationMatrix(_cluster->angle, clusterMatrix);
    }
    __syncthreads();

    if (!ignoreOwnCluster) {
        for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
            auto const& cell = _cluster->cellPointers[cellIndex];
            auto relPos =
                getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, displacementOfConstructionSite);
            relPos = relPos - newCenter;
            auto const absPos = _cluster->pos + Math::applyMatrix(relPos, clusterMatrix);
            tempCellMap.insertOrAssign(toInt2(absPos), CellAndNewAbsPos{ cell, absPos });
        }
    }
    __syncthreads();

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto relPos =
            getTransformedCellRelPos(cell, centerOfRotation, rotationMatrices, displacementOfConstructionSite);
        relPos = relPos - newCenter;
        auto const absPos = _cluster->pos + Math::applyMatrix(relPos, clusterMatrix);
        if (isObstaclePresent_helper(ignoreOwnCluster, cell, absPos, tempCellMap)) { 
            result = true;
            break;
        }
    }
}

__inline__ __device__ void ConstructorFunction::isObstaclePresent_firstCreation(
    bool ignoreOwnCluster,
    float2 const& relPosOfNewCell,
    bool& result)
{
    __shared__ HashMap<int2, CellAndNewAbsPos> tempCellMap;
    if (0 == threadIdx.x) {
        tempCellMap = _dynamicMemory.cellPosMap;
    }
    __syncthreads();

    tempCellMap.reset_blockCall();
    __syncthreads();

    __shared__ float2 newCenter;
    if (0 == threadIdx.x) {
        newCenter = relPosOfNewCell;
        result = false;
    }
    __syncthreads();

    for (auto cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        atomicAdd_block(&newCenter.x, cell->relPos.x);
        atomicAdd_block(&newCenter.y, cell->relPos.y);
    }
    __syncthreads();

    __shared__ Math::Matrix clusterMatrix;
    if (0 == threadIdx.x) {
        newCenter = newCenter / (_cluster->numCellPointers + 1);
        Math::rotationMatrix(_cluster->angle, clusterMatrix);
    }
    __syncthreads();

    if (!ignoreOwnCluster) {
        for (auto cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
            auto const& cell = _cluster->cellPointers[cellIndex];
            auto const relPos = cell->relPos - newCenter;
            auto const absPos = _cluster->pos + Math::applyMatrix(relPos, clusterMatrix);
            tempCellMap.insertOrAssign(toInt2(absPos), CellAndNewAbsPos{ cell, absPos });
        }
    }
    __syncthreads();

    for (auto cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        auto const relPos = cell->relPos - newCenter;
        auto const absPos = _cluster->pos + Math::applyMatrix(relPos, clusterMatrix);
        if (isObstaclePresent_helper(ignoreOwnCluster, cell, absPos, tempCellMap)) {
            result = true;
            break;
        }
    }
    __syncthreads();

    //check obstacle for cell to be constructed
    if (0 == threadIdx.x) {
        auto const absPosForNewCell = _cluster->pos + Math::applyMatrix(relPosOfNewCell - newCenter, clusterMatrix);
        if (isObstaclePresent_helper(ignoreOwnCluster, nullptr, absPosForNewCell, tempCellMap)) {
            result = true;
        }
    }
}

__inline__ __device__ bool ConstructorFunction::isObstaclePresent_helper(
    bool ignoreOwnCluster,
    Cell* cell,
    float2 const& absPos,
    HashMap<int2, CellAndNewAbsPos>& tempMap)
{
    auto const map = _data->cellMap;
    for (int dx = -1; dx <= 1; ++dx) {
        for (int dy = -1; dy <= 1; ++dy) {
            float2 const lookupPos = {absPos.x + dx, absPos.y + dy};
            if (auto otherCell = map.get(lookupPos)) {
                if (_cluster != otherCell->cluster) {
                    if (map.mapDistance(otherCell->absPos, absPos) < cudaSimulationParameters.cellMinDistance) {
                        return true;
                    }

                    //check also connected cells
                    if (otherCell->tryLock()) {
                        __threadfence();
                        for (int i = 0; i < otherCell->numConnections; ++i) {
                            auto const connectedOtherCell = otherCell->connections[i];
                            if (map.mapDistance(connectedOtherCell->absPos, absPos)
                                < cudaSimulationParameters.cellMinDistance) {
                                __threadfence();
                                otherCell->releaseLock();
                                return true;
                            }
                        }
                        __threadfence();
                        otherCell->releaseLock();
                    }
                }
            }
            if (!ignoreOwnCluster) {
                auto const lookupPosInt = toInt2(lookupPos);
                if (tempMap.contains(lookupPosInt)) {
                    auto otherCellAndNewPos = tempMap.at(lookupPosInt);

                    if (cell != otherCellAndNewPos.cell) {
                        if (map.mapDistance(otherCellAndNewPos.newAbsPos, absPos)
                            < cudaSimulationParameters.cellMinDistance) {
                            return true;
                        }
                    }
                }
            }
        }
    }
    return false;
}

__inline__ __device__ void
ConstructorFunction::constructNewCell(float2 const& relPosOfNewCell, float const energyOfNewCell, Cell*& result)
{
    __shared__ int offset;
    if (0 == threadIdx.x) {
        EntityFactory factory;
        factory.init(_data);
        result = factory.createCell(_cluster);
        result->setEnergy(energyOfNewCell);
        result->relPos = relPosOfNewCell;
        float rotMatrix[2][2];
        Math::rotationMatrix(_cluster->angle, rotMatrix);
        result->absPos = Math::applyMatrix(result->relPos, rotMatrix) + _cluster->pos;
        result->maxConnections = _token->getMaxConnectionsForConstructor();
        result->numConnections = 0;
        result->branchNumber =
            static_cast<unsigned char>(_token->memory[Enums::Constr::IN_CELL_BRANCH_NO]) % cudaSimulationParameters.cellMaxTokenBranchNumber;
        result->tokenBlocked = true;
        result->setCellFunctionType(_token->memory[Enums::Constr::IN_CELL_FUNCTION]);
        result->numStaticBytes = static_cast<unsigned char>(_token->memory[Enums::Constr::IN_CELL_FUNCTION_DATA])
            % (MAX_CELL_STATIC_BYTES + 1);
        offset = result->numStaticBytes + 1;
        result->numMutableBytes = static_cast<unsigned char>(_token->memory[(Enums::Constr::IN_CELL_FUNCTION_DATA + offset) % MAX_TOKEN_MEM_SIZE])
            % (MAX_CELL_MUTABLE_BYTES + 1);
        result->metadata.color = _token->memory[Enums::Constr::IN_CELL_METADATA];
    }
    __syncthreads();

    auto const staticDataBlock = calcPartition(result->numStaticBytes, threadIdx.x, blockDim.x);
    for (int i = staticDataBlock.startIndex; i <= staticDataBlock.endIndex; ++i) {
        result->staticData[i] = _token->memory[(Enums::Constr::IN_CELL_FUNCTION_DATA + i + 1) % MAX_TOKEN_MEM_SIZE];
    }
    auto const mutableDataBlock = calcPartition(result->numMutableBytes, threadIdx.x, blockDim.x);
    for (int i = mutableDataBlock.startIndex; i <= mutableDataBlock.endIndex; ++i) {
        result->mutableData[i] = _token->memory[(Enums::Constr::IN_CELL_FUNCTION_DATA + offset + i + 1) % MAX_TOKEN_MEM_SIZE];
    }
}

__inline__ __device__ void ConstructorFunction::constructNewToken(
    Cell* cellOfNewToken,
    Cell* sourceCellOfNewToken,
    float energyOfNewToken,
    bool duplicate,
    Token*& result)
{
    if (0 == threadIdx.x) {
        EntityFactory factory;
        factory.init(_data);

        result = factory.createToken(cellOfNewToken, sourceCellOfNewToken);
        result->setEnergy(energyOfNewToken);
    }
    __syncthreads();

    auto const threadBlock = calcPartition(MAX_TOKEN_MEM_SIZE, threadIdx.x, blockDim.x);
    if (duplicate) {
        for (int i = max(1, threadBlock.startIndex); i <= threadBlock.endIndex;
             ++i) {  //do not copy branchnumber (at address 0)
            result->memory[i] = _token->memory[i];
        }
    } else {
        for (int i = max(1, threadBlock.startIndex); i <= threadBlock.endIndex;
             ++i) {  //do not copy branchnumber (at address 0)
            result->memory[i] = 0;
        }
    }
}

__inline__ __device__ void
ConstructorFunction::addCellToCluster(Cell* newCell, Cell** newCellPointers)
{
    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        newCellPointers[cellIndex] = _cluster->cellPointers[cellIndex];
    }
    __syncthreads();

    if (0 == threadIdx.x) {
        newCellPointers[_cluster->numCellPointers] = newCell;
        _cluster->cellPointers = newCellPointers;
        ++_cluster->numCellPointers;
    }
}

__inline__ __device__ void
ConstructorFunction::addTokenToCluster(Token* token, Token** newTokenPointers)
{
    auto const tokenBlock = calcPartition(_cluster->numTokenPointers, threadIdx.x, blockDim.x);
    for (int i = tokenBlock.startIndex; i <= tokenBlock.endIndex; ++i) {
        newTokenPointers[i] = _cluster->tokenPointers[i];
    }
    __syncthreads();

    if (0 == threadIdx.x) {
        newTokenPointers[_cluster->numTokenPointers] = token;
        _cluster->tokenPointers = newTokenPointers;
        ++_cluster->numTokenPointers;
    }
}

__inline__ __device__ void ConstructorFunction::separateConstructionWhenFinished(Cell* newCell)
{
    auto const& cell = _token->cell;
    auto const option = getOption(_token);

    if (Enums::ConstrInOption::FINISH_NO_SEP == option || Enums::ConstrInOption::FINISH_WITH_SEP == option
        || Enums::ConstrInOption::FINISH_WITH_SEP_RED == option
        || Enums::ConstrInOption::FINISH_WITH_TOKEN_SEP_RED == option) {
        newCell->tokenBlocked = false;
    }

    if (Enums::ConstrInOption::FINISH_WITH_SEP == option || Enums::ConstrInOption::FINISH_WITH_SEP_RED == option
        || Enums::ConstrInOption::FINISH_WITH_TOKEN_SEP_RED == option) {
        atomicExch(&_cluster->decompositionRequired, 1);
        removeConnection(newCell, cell);
    }
    if (Enums::ConstrInOption::FINISH_WITH_SEP_RED == option
        || Enums::ConstrInOption::FINISH_WITH_TOKEN_SEP_RED == option) {
        --newCell->maxConnections;
        --cell->maxConnections;
    }
}

__inline__ __device__ void ConstructorFunction::connectNewCell(
    Cell* newCell,
    Cell* cellOfConstructionSite)
{
    __shared__ AdaptMaxConnections adaptMaxConnections;
    __shared__ int blockLock;
    if (0 == threadIdx.x) {
        Cell* cellOfConstructor = _token->cell;

        adaptMaxConnections = isAdaptMaxConnections(_token);

        removeConnection(cellOfConstructionSite, cellOfConstructor);
        establishConnection(newCell, cellOfConstructionSite, adaptMaxConnections);
        establishConnection(newCell, cellOfConstructor, adaptMaxConnections);
        blockLock = 0;
    }
    __syncthreads();

    if (newCell->numConnections >= cudaSimulationParameters.cellMaxBonds) {
        return;
    }

    for (int cellIndex = _cellBlock.startIndex; cellIndex <= _cellBlock.endIndex; ++cellIndex) {
        auto const& cell = _cluster->cellPointers[cellIndex];
        if (ClusterComponent::ConstructionSite != cell->tag) {
            continue;
        }
        if (cell == cellOfConstructionSite) {
            continue;
        }
        if (_data->cellMap.mapDistance(cell->absPos, newCell->absPos) >= cudaSimulationParameters.cellMaxDistance) {
            continue;
        }

        while (1 == atomicExch_block(&blockLock, 1)) {}
        __threadfence_block();

        if (isConnectable(cell->numConnections, cell->maxConnections, adaptMaxConnections)
            && isConnectable(newCell->numConnections, newCell->maxConnections, adaptMaxConnections)) {
            establishConnection(cell, newCell, adaptMaxConnections);
        }

        __threadfence_block();
        atomicExch(&blockLock, 0);
    }
}

__inline__ __device__ void ConstructorFunction::removeConnection(Cell* cell1, Cell* cell2)
{
    cell1->getLock();
    cell2->getLock();
    __threadfence();

    auto remove = [&](Cell* cell, Cell* connectionToRemove) {
        bool connectionFound = false;
        for (int i = 0; i < cell->numConnections; ++i) {
            auto& connectingCell = cell->connections[i];
            if (!connectionFound) {
                if (connectingCell == connectionToRemove) {
                    connectionFound = true;
                }
            } else {
                cell->connections[i - 1] = connectingCell;
            }
        }
        --cell->numConnections;
    };

    remove(cell1, cell2);
    remove(cell2, cell1);

    __threadfence();
    cell1->releaseLock();
    cell2->releaseLock();
}

__inline__ __device__ auto ConstructorFunction::isAdaptMaxConnections(Token* token) -> AdaptMaxConnections
{
    return 0 == token->getMaxConnectionsForConstructor() ? AdaptMaxConnections::Yes : AdaptMaxConnections::No;
}

__inline__ __device__ bool
ConstructorFunction::isConnectable(int numConnections, int maxConnections, AdaptMaxConnections adaptMaxConnections)
{
    if (AdaptMaxConnections::Yes == adaptMaxConnections) {
        if (numConnections >= cudaSimulationParameters.cellMaxBonds) {
            return false;
        }
    }
    if (AdaptMaxConnections::No == adaptMaxConnections) {
        if (numConnections >= maxConnections) {
            return false;
        }
    }
    return true;
}

__inline__ __device__ void
ConstructorFunction::establishConnection(Cell* cell1, Cell* cell2, AdaptMaxConnections adaptMaxConnections)
{
    cell1->getLock();
    cell2->getLock();
    __threadfence();

    cell1->connections[cell1->numConnections++] = cell2;
    cell2->connections[cell2->numConnections++] = cell1;

    if (adaptMaxConnections == AdaptMaxConnections::Yes) {
        cell1->maxConnections = cell1->numConnections;
        cell2->maxConnections = cell2->numConnections;
    }

    __threadfence();
    cell1->releaseLock();
    cell2->releaseLock();
}

__inline__ __device__ Enums::ConstrIn::Type ConstructorFunction::getCommand(Token * token) const
{
    return static_cast<Enums::ConstrIn::Type>(
        static_cast<unsigned char>(token->memory[Enums::Constr::IN]) % Enums::ConstrIn::_COUNTER);
}

__inline__ __device__ Enums::ConstrInOption::Type ConstructorFunction::getOption(Token * token) const
{
    return static_cast<Enums::ConstrInOption::Type>(
        static_cast<unsigned char>(token->memory[Enums::Constr::IN_OPTION]) % Enums::ConstrInOption::_COUNTER);
}

__inline__ __device__ Cell*& ConstructorFunction::check(Cell *& entity, int p)
{
    if (!DEBUG_cluster::checkPointer(entity, _data->entities.cells)) {
        printf("check(Cell*&) failed: %llu, parameter: %d\n", (uintptr_t)(entity), p);
        while (true) {}
    }
    return entity;
}

__inline__ __device__ Cell * ConstructorFunction::check(Cell *&& entity)
{
    if (!DEBUG_cluster::checkPointer(entity, _data->entities.cells)) {
        printf("check(Cell*&&) failed\n");
        while (true) {}
    }
    return entity;
}

__inline__ __device__ Cell**& ConstructorFunction::check(Cell **& entity)
{
    if (!DEBUG_cluster::checkPointer(entity, _data->entities.cellPointers)) {
        printf("check(Cell**&) failed\n");
        while (true) {}
    }
    return entity;
}

__inline__ __device__ Cell ** ConstructorFunction::check(Cell **&& entity)
{
    if (!DEBUG_cluster::checkPointer(entity, _data->entities.cellPointers)) {
        printf("check(Cell**&&) failed\n");
        while (true) {}
    }
    return entity;
}

__inline__ __device__ Cluster * ConstructorFunction::check(Cluster * entity)
{
    if (!DEBUG_cluster::checkPointer(entity, _data->entities.clusters)) {
        printf("check(Cluster*) failed\n");
        while (true) {}
    }
    return entity;
}

__inline__ __device__ Token*& ConstructorFunction::check(Token *& entity)
{
    if (!DEBUG_cluster::checkPointer(entity, _data->entities.tokens)) {
        printf("check(Token*&) failed\n");
        while (true) {}
    }
    return entity;
}

__inline__ __device__ Token**& ConstructorFunction::check(Token **& entity)
{
    if (!DEBUG_cluster::checkPointer(entity, _data->entities.tokenPointers)) {
        printf("check(Token**&) failed\n");
        while (true) {}
    }
    return entity;
}

__inline__ __device__ Token ** ConstructorFunction::check(Token **&& entity)
{
    if (!DEBUG_cluster::checkPointer(entity, _data->entities.tokenPointers)) {
        printf("check(Token**&&) failed\n");
        while (true) {}
    }
    return entity;
}

__inline__ __device__ int ConstructorFunction::check(int index, int arraySize)
{
    if (index < 0 || index > arraySize - 1) {
        printf("Wrong array index. index: %d, size: %d\n", index, arraySize);
        while (true) {}
    }
    return index;
}