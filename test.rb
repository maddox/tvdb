#!/usr/bin/env ruby
#
#  Created by Jon Maddox on 2007-08-16.
#  Copyright (c) 2007. All rights reserved.

require 'tvdb'

tvdb = Tvdb.new
results = tvdb.search("Heroes")

series = results.first


