#!/usr/bin/env ruby
#
#  Created by Jon Maddox on 2007-08-16.
#  Copyright (c) 2007. All rights reserved.

require 'tvdb'

tvdb = Tvdb.new
office_id = tvdb.find_series_id_by_name("law & order: Criminal Intent")
puts office_id
office = tvdb.find_series_by_id(office_id)

puts office.inspect
# scrubs.retrieve_banners
# puts scrubs.banners.inspect