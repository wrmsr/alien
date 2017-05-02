#ifndef ENERGYPARTICLEMAP_H
#define ENERGYPARTICLEMAP_H

#include "model/Definitions.h"

class EnergyParticleMap
	: public QObject
{
	Q_OBJECT
public:
	EnergyParticleMap(QObject* parent = nullptr) : QObject(parent) {}
	virtual ~EnergyParticleMap() {}

	virtual void init(SpaceMetric* topo, MapCompartment* compartment) = 0;
	virtual void clear() = 0;
	
	virtual void removeParticleIfPresent(QVector3D pos, EnergyParticle* energy) = 0;
	virtual void setParticle(QVector3D pos, EnergyParticle* energy) = 0;
	virtual EnergyParticle* getParticle(QVector3D pos) const = 0;
	inline EnergyParticle* getParticleFast(IntVector2D const& pos) const;

	virtual void serializePrimitives(QDataStream& stream) const = 0;
	virtual void deserializePrimitives(QDataStream& stream, QMap<quint64, EnergyParticle*> const& oldIdEnergyMap) = 0;

protected:
	EnergyParticle*** _energyGrid = nullptr;
};

EnergyParticle * EnergyParticleMap::getParticleFast(IntVector2D const& intPos) const
{
	return _energyGrid[intPos.x][intPos.y];
}

#endif //ENERGYPARTICLEMAP_H