namespace :tournative do
  task :migrate => :environment do
    # page = 1
    # loop do
    #   p "From Tournative: Page #{page}"
    #   uri = URI("https://www.tournative.com/api/v2/experiences/search.json?search[query]=&page=#{page}")
    #   req = Net::HTTP::Get.new(uri)
    #   req['Authorization'] = "TourNativeAPI 2c8b2e1a50b7ba93ce80afcfe400b4af"
    #   http = Net::HTTP.new(uri.host, uri.port)
    #   http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    #   http.use_ssl = true

    #   response = http.start { |http| http.request(req) }
    #   tours = JSON.parse(response.body).try(:[], 'experiences')
    #   break unless tours.present?

    #   p "Importing #{tours.size} tours"
    #   print "Successfully: "
    #   tours.each do |tour_json|
    #     next unless import_tours.include?(tour_json['id'])
    #     import_tour(tour_json['id'])
    #     print "#{tour_json['id']} "
    #   end
    #   page += 1
    # end
    tour_id = ENV['tour_id']
    if tour_id.present?
      import_tour tour_id
    else
      import_tours.each do |tour_id|
      p "Importing tour #{tour_id}"
      import_tour tour_id
     end
   end
  end
end

def import_tour(tour_id)
  return if TourImport.exists?(service_id: TourImport::TOUR_NATIVE, service_tour_id: tour_id)

  uri = URI("https://www.tournative.com/api/v2/experiences/#{tour_id}")
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "TourNativeAPI 2c8b2e1a50b7ba93ce80afcfe400b4af"
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  # begin
    response = http.start { |http| http.request(req) }
    tour_json = JSON.parse(response.body)['experience']
    user_json = tour_json['guide']['guide_basic']
    location_json = tour_json['location']['location']

    user = User.import_from_external(user_json, 'tournative')
    location = Location.import_from_external(location_json)
    Tour.import_from_external(tour_id, tour_json, user, location) if user.present?
  # rescue => e
  #   p "Cannot import tour##{tour_id}: #{e.message}"
  # end
end


def import_tours
  [825, 826, 839, 841, 842, 845, 846, 900, 903, 906, 911, 982, 983, 1067, 1069, 1107, 1129, 1125, 354, 366, 383, 384, 414, 715, 122, 1257, 1165, 1167, 1058, 1059, 1533, 1534, 1536, 1537, 1538, 1556, 1560, 1561, 1609, 1634, 1635, 1636, 1625, 1626, 1627, 192, 193, 654, 838, 1134, 1156, 1175, 1615, 1616, 1617, 417, 806, 1000, 1029, 1037, 1089, 1096, 1161, 1202, 1225, 1230, 1301, 1335, 1349, 1618, 6, 8, 16, 24, 45, 93, 123, 124, 125, 159, 299, 466, 491, 499, 548, 673, 679, 680, 694, 709, 728, 729, 734, 736, 737, 741, 745, 779, 803, 1031, 1032, 1270, 1272, 1273, 1274, 1277, 1278, 1615 ,1616, 1617]
end
