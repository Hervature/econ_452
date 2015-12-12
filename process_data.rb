#!/usr/bin/env ruby

require 'active_record'
require 'sqlite3'
require 'logger'
require 'csv'

ActiveRecord::Base.logger = Logger.new('debug.log')
configuration = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(configuration['development'])

class Game < ActiveRecord::Base
end

@teams = [
  "Anaheim Ducks",
  "Arizona Coyotes",
  "Boston Bruins",
  "Buffalo Sabres",
  "Calgary Flames",
  "Carolina Hurricanes",
  "Chicago Blackhawks",
  "Colorado Avalanche",
  "Columbus Blue Jackets",
  "Dallas Stars",
  "Detroit Red Wings",
  "Edmonton Oilers",
  "Florida Panthers",
  "Los Angeles Kings",
  "Minnesota Wild",
  "Montreal Canadiens",
  "Nashville Predators",
  "New Jersey Devils",
  "New York Islanders",
  "New York Rangers",
  "Ottawa Senators",
  "Philadelphia Flyers",
  "Pittsburgh Penguins",
  "San Jose Sharks",
  "StLouis Blues",
  "Tampa Bay Lightning",
  "Toronto Maple Leafs",
  "Vancouver Canucks",
  "Washington Capitals",
  "Winnipeg Jets",
]

# Time zone difference between team. Indices match the team array
# 0 Pacific, 1 Mountain, 2 Central, 3 Eastern
@timezones = [0, 1, 3, 3, 1, 3, 2, 1, 3, 2, 3, 1, 3, 0, 2, 3, 2, 3, 3, 3, 3, 3, 3, 0, 2, 3, 3, 0, 3, 2]

# Travel distances (miles) between teams. Indices match the team array
# miles to km conversion 1.60934
@distances = [
  [0, 349, 2984, 2545, 1572, 2535, 2012, 1012, 2240, 1424, 2280, 1757, 2703, 30, 1925, 2851, 2003, 2767, 2820, 2779, 2789, 2714, 349, 2426, 370, 1823, 2517, 2519, 1309, 2677, 2070],
  [349, 0, 2702, 2253, 1543, 2219, 1807, 822, 1925, 1084, 2040, 1729, 2365, 368, 1736, 2629, 1687, 2450, 2496, 2463, 2567, 2399, 2110, 705, 1507, 2178, 2268, 1581, 2361, 1968],
  [2984, 2702, 0, 459, 2586, 718, 987, 1975, 778, 1771, 709, 2622, 1484, 2993, 1345, 320, 1103, 228, 223, 214, 455, 316, 576, 3140, 1195, 1358, 552, 3173, 443, 1849],
  [2545, 2253, 459, 0, 2138, 710, 529, 1535, 329, 1376, 257, 2174, 1370, 2553, 936, 400, 710, 390, 428, 401, 337, 410, 220, 2899, 746, 1244, 100, 2724, 464, 1401],
  [1572, 1543, 2586, 2138, 0, 2454, 1598, 1096, 1955, 1966, 1881, 190, 3016, 1582, 1201, 2452, 2127, 2380, 2419, 2391, 2389, 2363, 2060, 1549, 1819, 2831, 2119, 605, 2303, 825],
  [2535, 2219, 718, 710, 2454, 0, 856, 1671, 507, 1186, 718, 2490, 790, 2545, 1253, 857, 533, 484, 522, 495, 826, 410, 498, 2802, 820, 664, 808, 3047, 278, 1718],
  [2012, 1807, 987, 529, 1598, 856, 0, 864, 357, 931, 284, 1637, 1362, 2021, 400, 855, 473, 784, 823, 795, 793, 766, 494, 2167, 300, 1176, 523, 2188, 707, 864],
  [1012, 822, 1975, 1535, 1096, 1671, 864, 0, 1261, 880, 1271, 1279, 2048, 1021, 916, 1842, 1159, 1772, 1810, 1783, 1780, 1755, 1452, 1034, 851, 1863, 1510, 1469, 1695, 1128],
  [2240, 1925, 778, 329, 1955, 507, 357, 1261, 0, 1047, 202, 1992, 1166, 2251, 754, 720, 381, 529, 568, 541, 658, 476, 188, 2489, 418, 1027, 430, 2554, 424, 1219],
  [1424, 1084, 1771, 1376, 1966, 1186, 931, 880, 1047, 0, 1199, 2151, 1345, 1442, 944, 1761, 668, 1544, 1583, 1556, 1699, 1467, 1227, 1692, 631, 1159, 1429, 2340, 1342, 1298],
  [2280, 2040, 709, 257, 1881, 718, 284, 1271, 202, 1199, 0, 1920, 1368, 2290, 682, 577, 536, 607, 646, 618, 517, 590, 287, 2437, 533, 1182, 245, 2470, 530, 1147],
  [1757, 1729, 2622, 2174, 190, 2490, 1637, 1279, 1992, 2151, 1920, 0, 3042, 1767, 1241, 2492, 2453, 2421, 2459, 2432, 2429, 2403, 2101, 1734, 1844, 2856, 2160, 722, 2344, 840],
  [2703, 2365, 1484, 1370, 3016, 790, 1362, 2048, 1166, 1345, 1368, 3042, 0, 2722, 1761, 1624, 893, 1251, 1288, 1261, 1592, 1167, 1159, 3059, 1200, 252, 1469, 3432, 1035, 2270],
  [30, 368, 2993, 2553, 1582, 2545, 2021, 1021, 2251, 1442, 2290, 1767, 2722, 0, 1934, 2860, 2011, 2775, 2828, 2787, 2797, 2722, 2435, 343, 1832, 2535, 2528, 1282, 2686, 2078],
  [1925, 1736, 1345, 936, 1201, 1253, 400, 916, 754, 944, 682, 1241, 1761, 1934, 0, 1254, 876, 1182, 1221, 1193, 1191, 1165, 862, 2081, 563, 1579, 922, 1806, 1105, 467],
  [2851, 2629, 320, 400, 2452, 857, 855, 1842, 720, 1761, 577, 2492, 1624, 2860, 1254, 0, 1110, 372, 393, 377, 137, 463, 610, 3006, 1122, 1506, 341, 3040, 591, 1717],
  [2003, 1687, 1103, 710, 2127, 533, 473, 1159, 381, 668, 536, 2453, 893, 2011, 876, 1110, 0, 877, 916, 889, 1034, 800, 562, 2269, 309, 705, 764, 2541, 675, 1379],
  [2767, 2450, 228, 390, 2380, 484, 784, 1772, 529, 1544, 607, 2421, 1251, 2775, 1182, 372, 877, 0, 40, 13, 430, 91, 360, 2936, 943, 1133, 482, 2969, 218, 1646],
  [2820, 2496, 223, 428, 2419, 522, 823, 1810, 568, 1583, 646, 2459, 1288, 2828, 1221, 393, 916, 40, 0, 28, 469, 127, 406, 2945, 989, 1169, 521, 3008, 255, 1685],
  [2779, 2463, 214, 401, 2391, 495, 795, 1783, 541, 1556, 618, 2432, 1261, 2787, 1193, 377, 889, 13, 28, 0, 441, 102, 373, 2948, 956, 1144, 494, 2980, 229, 1657],
  [2789, 2567, 455, 337, 2389, 826, 793, 1780, 658, 1699, 517, 2429, 1592, 2797, 1191, 137, 1034, 430, 469, 441, 0, 451, 547, 2944, 1060, 1467, 279, 2978, 566, 1655],
  [2714, 2399, 316, 410, 2363, 410, 766, 1755, 476, 1467, 590, 2403, 1167, 2722, 1165, 463, 800, 91, 127, 102, 451, 0, 309, 2919, 892, 1049, 503, 2952, 134, 1629],
  [2426, 2110, 576, 220, 2060, 498, 494, 1452, 188, 1227, 287, 2101, 1159, 2435, 862, 610, 562, 360, 406, 373, 547, 309, 0, 2616, 603, 1032, 318, 2649, 250, 1326],
  [370, 705, 3140, 2699, 1549, 2802, 2167, 1034, 2489, 1692, 2437, 1734, 3059, 343, 2081, 3006, 2269, 2936, 2945, 2948, 2944, 2919, 2616, 0, 2094, 2872, 2676, 985, 2861, 2044],
  [1823, 1507, 1195, 746, 1819, 820, 300, 851, 418, 631, 533, 1844, 1200, 1832, 563, 1122, 309, 943, 989, 956, 1060, 892, 603, 2094, 0, 1012, 762, 2232, 840, 1071],
  [2517, 1358, 1244, 2831, 664, 1176, 1863, 1027, 1159, 1182, 2856, 252, 2535, 1579, 1506, 705, 1133, 1169, 1144, 1467, 1049, 2178, 1032, 2872, 1012, 0, 1343, 3245, 909, 2084],
  [2519, 2268, 552, 100, 2119, 808, 523, 1510, 430, 1429, 245, 2160, 1469, 2528, 922, 341, 764, 482, 521, 494, 279, 503, 318, 2676, 762, 1343, 0, 2707, 562, 1384],
  [1309, 1581, 3173, 2724, 605, 3047, 2188, 1469, 2554, 2340, 2470, 722, 3432, 1282, 1806, 3040, 2541, 2969, 3008, 2980, 2978, 2952, 2649, 985, 2232, 3245, 2707, 0, 2894, 1441],
  [2677, 2361, 443, 464, 2303, 278, 707, 1695, 424, 1342, 530, 2344, 1035, 2686, 1105, 591, 675, 218, 255, 229, 566, 134, 250, 2861, 840, 909, 562, 2894, 0, 1568],
  [2070, 1948, 1849, 1401, 825, 1718, 864, 1128, 1219, 1298, 1147, 840, 2270, 2078, 467, 1717, 1379, 1646, 1685, 1657, 1655, 1629, 1326, 2044, 1071, 2084, 1384, 1441, 1568, 0]
]

#[year, preseason, playoffs]
@season_data = [
  [2006, 4, 19],
  [2007, 3, 9],
  [2008, 1, 8],
  [2009, 3, 13],
  [2010, 1, 13],
  [2011, 5, 11],
  [2012, 3, 9],
  [2013, 1, 30],
  [2014, 1, 15],
  [2015, 6, 13]
]

(2006..2015).each do |year|
  (1..30).each do |team|

    @games = Game.all.where("season = ? and (home_id = ? or away_id = ?)", year, team, team).order(:date)
    @previous_game = nil

    @games.each_with_index do |game, i|

      # Create home travel data
      if game.home_id == team then
        #first game since they are rested
        if i == 0 then
          game.home_days_since_last_travel = 50
          game.home_last_travel_length_km = 0
          game.home_timezone_change = 0
          game.home_last_travel_direction = 0
        else
          game.home_days_since_last_travel = game.date.mjd - @previous_game.date.mjd
          game.home_last_travel_length_km = @distances[@previous_game.home_id-1][game.home_id-1]*1.60934
          game.home_timezone_change = (@timezones[game.home_id-1] - @timezones[@previous_game.home_id-1]).abs
          game.home_last_travel_direction = @timezones[game.home_id-1] - @timezones[@previous_game.home_id-1] <= 0
        end
      end

      # Create away travel data
      if game.away_id == team then
        #first game since they are rested
        if i == 0 then
          game.away_days_since_last_travel = 50
          game.away_last_travel_length_km = @distances[game.home_id-1][game.away_id-1]
          game.away_timezone_change = (@timezones[game.home_id-1] - @timezones[game.away_id-1]).abs
          game.away_last_travel_direction = @timezones[game.home_id-1] - @timezones[game.away_id-1] <= 0
          game.away_roadtrip_length_km = game.away_last_travel_length_km
          game.away_roadtrip_length_days = game.away_days_since_last_travel
          game.away_roadtrip_length_games = 1
        else
          game.away_days_since_last_travel = game.date.mjd - @previous_game.date.mjd
          game.away_last_travel_length_km = @distances[@previous_game.home_id-1][game.home_id-1]*1.60934
          game.away_timezone_change = (@timezones[game.home_id-1] - @timezones[@previous_game.home_id-1]).abs
          game.away_last_travel_direction = @timezones[game.home_id-1] - @timezones[@previous_game.home_id-1] <= 0

          # Roadtrip data
          # Last game was at home
          if game.away_id == @previous_game.home_id then
            game.away_roadtrip_length_km = game.away_last_travel_length_km
            game.away_roadtrip_length_days = game.away_days_since_last_travel
            game.away_roadtrip_length_games = 1
          else
            game.away_roadtrip_length_km = game.away_last_travel_length_km + @previous_game.away_roadtrip_length_km
            game.away_roadtrip_length_days = game.away_days_since_last_travel + @previous_game.away_roadtrip_length_days
            game.away_roadtrip_length_games = @previous_game.away_roadtrip_length_games + 1
          end
        end
      end

      @playoff_game = false
      @preseason_game = false
      @date = game.date

      # Preseason data only available after 2009
      if @date.strftime('%Y').to_i == @season_data[year - 2006][0] && (@date.strftime('%m').to_i > 4 || (@date.strftime('%m').to_i == 4 && @date.strftime('%d').to_i > @season_data[year - 2006][2])) then
        @playoff_game = true
      elsif @date.strftime('%Y').to_i == (@season_data[year - 2006][0]-1) && year > 2009 && (@date.strftime('%m').to_i < 10 || (@date.strftime('%m').to_i == 10 && @date.strftime('%d').to_i < @season_data[year - 2006][1])) then
        @preseason_game = true
      end

      game.playoff_game = @playoff_game
      game.preseason_game = @preseason_game

      game.save
      @previous_game = game
    end

  end
end
