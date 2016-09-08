namespace :geocoder do
  desc 'Matches tour geolocation with proper country and city'
  task :match_tours => :environment do
    p "Loading tours..."

    Tour.all.each do |tour|
      loc    = tour.location
      coords = "#{loc.latitude.to_s},#{loc.longitude}"

      p "Matching tour ##{tour.id} with coords #{coords}"
      res    = get_country_and_city_by(coords)

      country = Country.where(name: res.country).try(:first)

      if country
        p "Found country! #{res.country}"
        loc.persisted_country = country
        loc.save
      end

      city = City.where(name: res.city).try(:first)

      if city
        p "Found city! #{res.city}"
        loc.persisted_city = city
        loc.save
      end

    end
  end
end

def get_country_and_city_by(coords)
  Geokit::Geocoders::GoogleGeocoder.reverse_geocode(coords)
end
