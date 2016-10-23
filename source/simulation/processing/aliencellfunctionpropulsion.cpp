#include "aliencellfunctionpropulsion.h"
#include "../entities/aliencell.h"
#include "../entities/aliencellcluster.h"
#include "../physics/physics.h"

#include "../../global/simulationsettings.h"

#include <QtCore/qmath.h>


AlienCellFunctionPropulsion::AlienCellFunctionPropulsion(AlienGrid*& grid)
    : AlienCellFunction(grid)
{
}

AlienCellFunctionPropulsion::AlienCellFunctionPropulsion (quint8* cellFunctionData, AlienGrid*& grid)
    : AlienCellFunction(grid)
{

}

AlienCellFunctionPropulsion::AlienCellFunctionPropulsion (QDataStream& stream, AlienGrid*& grid)
    : AlienCellFunction(grid)
{

}


void AlienCellFunctionPropulsion::execute (AlienToken* token, AlienCell* cell, AlienCell* previousCell, AlienEnergy*& newParticle, bool& decompose)
{
    AlienCellCluster* cluster(cell->getCluster());
    quint8 cmd = token->memory[static_cast<int>(PROP::IN)]%7;
    qreal angle = convertDataToAngle(token->memory[static_cast<int>(PROP::IN_ANGLE)]);
    qreal power = convertDataToThrustPower(token->memory[static_cast<int>(PROP::IN_POWER)]);

    if( cmd == static_cast<int>(PROP_IN::DO_NOTHING) ) {
        token->memory[static_cast<int>(PROP::OUT)] = static_cast<int>(PROP_OUT::SUCCESS);
        return;
    }

    //calc old kinetic energy
    qreal eKinOld(Physics::kineticEnergy(cluster->getMass(), cluster->getVel(), cluster->getAngularMass(), cluster->getAngularVel()));

    //calc old tangential velocity
    QVector3D cellRelPos(cluster->calcPosition(cell)-cluster->getPosition());
    QVector3D tangVel(Physics::tangentialVelocity(cellRelPos, cluster->getVel(), cluster->getAngularVel()));

    //calc impulse angle
    QVector3D impulse(0.0, 0.0, 0.0);
    if( cmd == static_cast<int>(PROP_IN::BY_ANGLE) ) {
        qreal thrustAngle = (Physics::angleOfVector(-cell->getRelPos() + previousCell->getRelPos())+cluster->getAngle()+ angle)*degToRad;
        impulse = QVector3D(qSin(thrustAngle), -qCos(thrustAngle), 0.0)*power;
    }
    if( cmd == static_cast<int>(PROP_IN::FROM_CENTER) ) {
        impulse = cellRelPos.normalized()*power;
    }
    if( cmd == static_cast<int>(PROP_IN::TOWARD_CENTER) ) {
        impulse = -cellRelPos.normalized()*power;
    }

    QVector3D rAPp = cellRelPos;
//    space->correctDistance(rAPp);
    rAPp = Physics::rotateQuarterCounterClockwise(rAPp);
    if( cmd == static_cast<int>(PROP_IN::ROTATION_CLOCKWISE) ) {
        impulse = -rAPp.normalized()*power;
    }
    if( cmd == static_cast<int>(PROP_IN::ROTATION_COUNTERCLOCKWISE) ) {
        impulse = rAPp.normalized()*power;
    }
    if( cmd == static_cast<int>(PROP_IN::DAMP_ROTATION) ) {
        if( cluster->getAngularVel() > 0.00 )
            impulse = rAPp.normalized()*power;
        if( cluster->getAngularVel() < 0.00 )
            impulse = -rAPp.normalized()*power;
    }

    //calc impact of impulse to cell structure
    QVector3D newVel;
    qreal newAngularVel;
    Physics::applyImpulse(impulse, rAPp, cluster->getMass(), cluster->getVel(), cluster->getAngularMass(), cluster->getAngularVel(), newVel, newAngularVel);

    //only for damping: prove if its too much
    if( cmd == static_cast<int>(PROP_IN::DAMP_ROTATION) ) {
        if( (cluster->getAngularVel() > 0.0 && newAngularVel < 0.0)
                || (cluster->getAngularVel() < 0.0 && newAngularVel > 0.0) ) {
            newVel = cluster->getVel();
            newAngularVel = cluster->getAngularVel();

            //update return value
            token->memory[static_cast<int>(PROP::OUT)] = static_cast<int>(PROP_OUT::SUCCESS_DAMPING_FINISHED);
            return;
        }
    }

    //calc new kinetic energy
    qreal eKinNew(Physics::kineticEnergy(cluster->getMass(), newVel, cluster->getAngularMass(), newAngularVel));
    qreal energyDiff((eKinNew-eKinOld)/simulationParameters.INTERNAL_TO_KINETIC_ENERGY);

    //has token enough energy?
    if( token->energy >= (energyDiff + qAbs(energyDiff) + simulationParameters.MIN_TOKEN_ENERGY + ALIEN_PRECISION) ) {

        //create energy particle with difference energy
        newParticle = new AlienEnergy(qAbs(energyDiff),
                                      cluster->calcPosition(cell, _grid)-impulse.normalized(),
                                      tangVel-impulse.normalized()/4.0,
                                      _grid);

        //update velocities
        cluster->setVel(newVel);
        cluster->setAngularVel(newAngularVel);
        token->energy = token->energy - (energyDiff+qAbs(energyDiff));

        //update return value
        token->memory[static_cast<int>(PROP::OUT)] = static_cast<int>(PROP_OUT::SUCCESS);
    }
    else {

        //update return value
        token->memory[static_cast<int>(PROP::OUT)] = static_cast<int>(PROP_OUT::ERROR_NO_ENERGY);
    }
}

QString AlienCellFunctionPropulsion::getCellFunctionName () const
{
    return "PROPULSION";
}

qreal AlienCellFunctionPropulsion::convertDataToThrustPower (quint8 b)
{
    return 1/10000.0*((qreal)b+10.0);
}

