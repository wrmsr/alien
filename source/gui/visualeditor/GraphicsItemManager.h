#ifndef GRAPHICSITEMMANAGER_H
#define GRAPHICSITEMMANAGER_H

#include "gui/Definitions.h"
#include "Model/Definitions.h"

#include "GraphicsItemConfig.h"

class GraphicsItemManager
	: public QObject
{
	Q_OBJECT
public:
	GraphicsItemManager(QObject* parent = nullptr) : QObject(parent) {}
	virtual ~GraphicsItemManager() = default;

	virtual void init(QGraphicsScene* scene, ViewportInterface* viewport);

	virtual void activate(IntVector2D size);
	virtual void update(DataDescription const &desc);

private:
	template<typename IdType, typename ItemType, typename DescriptionType>
	void updateItems(vector<TrackerElement<DescriptionType>> const &desc, map<IdType, ItemType*>& itemsByIds
		, map<IdType, ItemType*>& newItemsByIds);
		
	QGraphicsScene* _scene = nullptr;
	ViewportInterface* _viewport = nullptr;
	GraphicsItemConfig _config;

	map<uint64_t, CellGraphicsItem*> _cellsByIds;
	map<uint64_t, ParticleGraphicsItem*> _particlesByIds;
	map<unordered_set<uint64_t>, CellConnectionGraphicsItem*> _connectionsByIds;
};

#endif // GRAPHICSITEMMANAGER_H
