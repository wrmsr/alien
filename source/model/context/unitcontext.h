#ifndef SIMULATIONUNITCONTEXT_H
#define SIMULATIONUNITCONTEXT_H

#include <QList>
#include <QSize>

#include "model/Definitions.h"

class UnitContext
	: public QObject
{
	Q_OBJECT
public:
	UnitContext(QObject* parent) : QObject(parent) {}
	virtual ~UnitContext() {}
	
	virtual void init(SpaceMetric* metric, CellMap* cellMap, EnergyParticleMap* energyMap, MapCompartment* mapCompartment, SymbolTable* symbolTable
		, SimulationParameters* parameters) = 0;

	virtual void lock() = 0;
	virtual void unlock() = 0;

    virtual SpaceMetric* getTopology () const = 0;
	virtual CellMap* getCellMap() const = 0;
	virtual EnergyParticleMap* getEnergyParticleMap() const = 0;
	virtual MapCompartment* getMapCompartment() const = 0;
	virtual SymbolTable* getSymbolTable() const = 0;
	virtual SimulationParameters* getSimulationParameters() const = 0;

	virtual QList<CellCluster*>& getClustersRef() = 0;
    virtual QList<EnergyParticle*>& getEnergyParticlesRef () = 0;
};

#endif // SIMULATIONUNITCONTEXT_H
