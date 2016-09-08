class TourGmapSerializer < ActiveModel::Serializer
  attributes :id, :name, :location

  def location
    object.location.as_json(only: [:address], methods: [:lat_lng])
  end
end